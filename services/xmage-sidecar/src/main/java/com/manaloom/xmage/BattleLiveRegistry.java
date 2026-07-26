package com.manaloom.xmage;

import com.google.gson.Gson;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Bounded, process-local source for the read-only Battle Live polling API.
 *
 * <p>The registry is deliberately not a game-control channel. It receives only
 * the already public spectator snapshots produced by {@link ReplayNormalizer}
 * and visible replay events. A backend restart or sidecar restart is recovered
 * from the durable replay rather than pretending this in-memory buffer is
 * durable.</p>
 */
final class BattleLiveRegistry {
    static final String SCHEMA = "external_battle_live_source_v1";
    static final int DEFAULT_MAX_STREAMS = 64;
    static final int DEFAULT_MAX_RECORDS = 20000;
    static final long DEFAULT_RETENTION_MS = 15L * 60L * 1000L;

    private static final Gson GSON = new Gson();

    private final ConcurrentHashMap<String, StreamState> streams = new ConcurrentHashMap<>();
    private final int maxStreams;
    private final int maxRecords;
    private final long retentionMs;

    BattleLiveRegistry() {
        this(DEFAULT_MAX_STREAMS, DEFAULT_MAX_RECORDS, DEFAULT_RETENTION_MS);
    }

    BattleLiveRegistry(int maxStreams, int maxRecords, long retentionMs) {
        if (maxStreams < 1 || maxRecords < 1 || retentionMs < 1000L) {
            throw new IllegalArgumentException("Battle Live bounds must be positive");
        }
        this.maxStreams = maxStreams;
        this.maxRecords = maxRecords;
        this.retentionMs = retentionMs;
    }

    void begin(String requestId) {
        requireRequestId(requestId);
        cleanup();
        streams.compute(requestId, (ignored, existing) -> {
            if (existing != null && !existing.terminal) {
                return existing;
            }
            return new StreamState(requestId, maxRecords);
        });
        evictOldestIfNeeded();
    }

    void publish(
            String requestId,
            List<Map<String, Object>> snapshots,
            List<Map<String, Object>> events
    ) {
        requireRequestId(requestId);
        StreamState state = streams.get(requestId);
        if (state == null || state.terminal) {
            return;
        }
        state.publish(snapshots, events);
    }

    void finish(String requestId, String status, String reason) {
        if (!isRequestId(requestId)) {
            return;
        }
        StreamState state = streams.get(requestId);
        if (state != null) {
            state.finish(status, reason);
        }
    }

    Map<String, Object> read(String requestId) {
        return read(requestId, -1, maxRecords);
    }

    Map<String, Object> read(String requestId, int afterSequence, int limit) {
        requireRequestId(requestId);
        if (afterSequence < -1 || limit < 1 || limit > 500) {
            throw new IllegalArgumentException("Battle Live page bounds are invalid");
        }
        cleanup();
        StreamState state = streams.get(requestId);
        return state == null ? null : state.snapshot(afterSequence, limit);
    }

    Map<String, Object> metrics() {
        cleanup();
        int recordCount = 0;
        int truncatedStreams = 0;
        for (StreamState state : streams.values()) {
            recordCount += state.recordCount();
            if (state.isSourceTruncated()) {
                truncatedStreams++;
            }
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("schema_version", SCHEMA);
        result.put("stream_count", streams.size());
        result.put("record_count", recordCount);
        result.put("truncated_stream_count", truncatedStreams);
        result.put("max_streams", maxStreams);
        result.put("max_records_per_stream", maxRecords);
        result.put("retention_ms", retentionMs);
        return result;
    }

    private void cleanup() {
        long cutoff = System.currentTimeMillis() - retentionMs;
        streams.entrySet().removeIf(entry -> entry.getValue().updatedAtMs < cutoff);
    }

    private void evictOldestIfNeeded() {
        while (streams.size() > maxStreams) {
            Map.Entry<String, StreamState> oldest = null;
            for (Map.Entry<String, StreamState> entry : streams.entrySet()) {
                if (oldest == null || entry.getValue().updatedAtMs < oldest.getValue().updatedAtMs) {
                    oldest = entry;
                }
            }
            if (oldest == null || !streams.remove(oldest.getKey(), oldest.getValue())) {
                return;
            }
        }
    }

    static boolean isRequestId(String value) {
        return value != null && value.matches("[A-Za-z0-9_-]{1,80}");
    }

    static void requireRequestId(String value) {
        if (!isRequestId(value)) {
            throw new IllegalArgumentException("request_id must use 1-80 safe characters");
        }
    }

    private static final class StreamState {
        private final String requestId;
        private final int maxRecords;
        private final List<Map<String, Object>> records = new ArrayList<>();
        private final Set<String> snapshotFingerprints = new HashSet<>();
        private final Map<String, Integer> publishedEventOccurrences = new HashMap<>();
        private final long createdAtMs = System.currentTimeMillis();

        private long updatedAtMs = createdAtMs;
        private int nextSequence;
        private boolean terminal;
        private boolean sourceTruncated;
        private String status = "running";
        private String terminalReason;

        StreamState(String requestId, int maxRecords) {
            this.requestId = requestId;
            this.maxRecords = maxRecords;
        }

        synchronized void publish(
                List<Map<String, Object>> snapshots,
                List<Map<String, Object>> events
        ) {
            if (terminal) {
                return;
            }
            for (Map<String, Object> snapshot : snapshots) {
                String fingerprint = GSON.toJson(snapshot);
                if (snapshotFingerprints.add(fingerprint)) {
                    append("snapshot", snapshot);
                }
            }

            Map<String, Integer> seenOccurrences = new HashMap<>();
            for (Map<String, Object> event : events) {
                Map<String, Object> stable = new LinkedHashMap<>(event);
                stable.remove("index");
                String fingerprint = GSON.toJson(stable);
                int occurrence = seenOccurrences.getOrDefault(fingerprint, 0) + 1;
                seenOccurrences.put(fingerprint, occurrence);
                int alreadyPublished = publishedEventOccurrences.getOrDefault(fingerprint, 0);
                if (occurrence > alreadyPublished) {
                    append("event", event);
                    publishedEventOccurrences.put(fingerprint, occurrence);
                }
            }
            updatedAtMs = System.currentTimeMillis();
        }

        synchronized void finish(String nextStatus, String reason) {
            if (!isTerminalStatus(nextStatus)) {
                throw new IllegalArgumentException("Battle Live terminal status is invalid");
            }
            status = nextStatus;
            terminalReason = safeReason(reason);
            terminal = true;
            updatedAtMs = System.currentTimeMillis();
        }

        synchronized Map<String, Object> snapshot(int afterSequence, int limit) {
            List<Map<String, Object>> available = new ArrayList<>();
            for (Map<String, Object> record : records) {
                Object rawSequence = record.get("sequence");
                if (rawSequence instanceof Number
                        && ((Number) rawSequence).intValue() > afterSequence) {
                    available.add(record);
                }
            }
            int selectedCount = Math.min(limit, available.size());
            List<Map<String, Object>> selected = available.subList(0, selectedCount);
            int nextAfter = afterSequence;
            if (!selected.isEmpty()) {
                nextAfter = ((Number) selected.get(selected.size() - 1).get("sequence")).intValue();
            }
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("live_schema_version", SCHEMA);
            result.put("request_id", requestId);
            result.put("status", status);
            result.put("terminal", terminal);
            result.put("source_truncated", sourceTruncated);
            result.put("records", deepCopyRecords(selected));
            result.put("page_record_count", selected.size());
            result.put("record_count", records.size());
            result.put("after_sequence", afterSequence);
            result.put("next_after_sequence", nextAfter);
            result.put("has_more", available.size() > selected.size());
            result.put("created_at", Instant.ofEpochMilli(createdAtMs).toString());
            result.put("updated_at", Instant.ofEpochMilli(updatedAtMs).toString());
            if (terminalReason != null) {
                result.put("terminal_reason", terminalReason);
            }
            return result;
        }

        synchronized int recordCount() {
            return records.size();
        }

        synchronized boolean isSourceTruncated() {
            return sourceTruncated;
        }

        private void append(String kind, Map<String, Object> payload) {
            if (records.size() >= maxRecords) {
                sourceTruncated = true;
                return;
            }
            int sequence = nextSequence++;
            Map<String, Object> record = new LinkedHashMap<>();
            record.put("sequence", sequence);
            record.put("record_id", requestId + ":" + kind.charAt(0) + ":" + sequence);
            record.put("kind", kind);
            record.put(
                    kind,
                    "snapshot".equals(kind) ? publicSnapshot(payload) : publicEvent(payload)
            );
            records.add(record);
        }

        @SuppressWarnings("unchecked")
        private static Map<String, Object> publicSnapshot(Map<String, Object> source) {
            Map<String, Object> result = new LinkedHashMap<>();
            copyScalars(
                    source,
                    result,
                    "index",
                    "turn",
                    "phase",
                    "step",
                    "action",
                    "active_player",
                    "priority_player",
                    "final"
            );

            List<Map<String, Object>> players = new ArrayList<>();
            Object rawPlayers = source.get("players");
            if (rawPlayers instanceof List) {
                for (Object rawPlayer : ((List<?>) rawPlayers).subList(
                        0,
                        Math.min(8, ((List<?>) rawPlayers).size())
                )) {
                    if (!(rawPlayer instanceof Map)) {
                        continue;
                    }
                    Map<String, Object> player = (Map<String, Object>) rawPlayer;
                    Map<String, Object> publicPlayer = new LinkedHashMap<>();
                    copyScalars(
                            player,
                            publicPlayer,
                            "deck_key",
                            "name",
                            "life",
                            "mana",
                            "mana_available",
                            "hand_size",
                            "hand_count",
                            "library_size",
                            "library_count",
                            "graveyard_size",
                            "exile_size",
                            "command_size",
                            "lands",
                            "has_left"
                    );
                    putCollectionSize(player, publicPlayer, "battlefield", "battlefield_count");
                    putCollectionSize(player, publicPlayer, "graveyard", "graveyard_size");
                    putCollectionSize(player, publicPlayer, "exile", "exile_size");
                    putCollectionSize(player, publicPlayer, "command", "command_size");
                    players.add(publicPlayer);
                }
            }
            result.put("players", players);
            result.put("stack", publicCards(source.get("stack"), 64));

            List<Map<String, Object>> combat = new ArrayList<>();
            Object rawCombat = source.get("combat");
            if (rawCombat instanceof List) {
                List<?> groups = (List<?>) rawCombat;
                for (Object rawGroup : groups.subList(0, Math.min(32, groups.size()))) {
                    if (!(rawGroup instanceof Map)) {
                        continue;
                    }
                    Map<String, Object> group = (Map<String, Object>) rawGroup;
                    Map<String, Object> publicGroup = new LinkedHashMap<>();
                    copyScalars(
                            group,
                            publicGroup,
                            "defender_id",
                            "defender_name",
                            "defender_side",
                            "blocked"
                    );
                    publicGroup.put("attackers", publicCards(group.get("attackers"), 64));
                    publicGroup.put("blockers", publicCards(group.get("blockers"), 64));
                    combat.add(publicGroup);
                }
            }
            result.put("combat", combat);
            return result;
        }

        private static Map<String, Object> publicEvent(Map<String, Object> source) {
            Map<String, Object> result = new LinkedHashMap<>();
            copyScalars(
                    source,
                    result,
                    "index",
                    "live_event_index",
                    "event_id",
                    "event_type",
                    "type",
                    "action",
                    "turn",
                    "phase",
                    "step",
                    "active_player",
                    "priority_player",
                    "actor",
                    "actor_side",
                    "subject_deck_key",
                    "target_side",
                    "player",
                    "severity",
                    "amount",
                    "damage",
                    "life_after",
                    "from",
                    "to",
                    "from_zone",
                    "to_zone",
                    "card_name",
                    "source_card_name",
                    "stack_object_kind",
                    "defender_name",
                    "learning_grade",
                    "message",
                    "publicly_visible",
                    "visibility",
                    "tapped"
            );
            return result;
        }

        @SuppressWarnings("unchecked")
        private static List<Map<String, Object>> publicCards(Object source, int maximum) {
            if (!(source instanceof List)) {
                return new ArrayList<>();
            }
            List<Map<String, Object>> result = new ArrayList<>();
            List<?> rows = (List<?>) source;
            for (Object raw : rows.subList(0, Math.min(maximum, rows.size()))) {
                if (!(raw instanceof Map)) {
                    continue;
                }
                Map<String, Object> card = (Map<String, Object>) raw;
                Map<String, Object> publicCard = new LinkedHashMap<>();
                copyScalars(
                        card,
                        publicCard,
                        "id",
                        "object_id",
                        "name",
                        "card_name",
                        "object_type",
                        "controller_name",
                        "controller_side",
                        "ability_type",
                        "power",
                        "toughness",
                        "damage",
                        "tapped"
                );
                result.add(publicCard);
            }
            return result;
        }

        private static void putCollectionSize(
                Map<String, Object> source,
                Map<String, Object> target,
                String collectionKey,
                String sizeKey
        ) {
            if (target.containsKey(sizeKey)) {
                return;
            }
            Object collection = source.get(collectionKey);
            if (collection instanceof List) {
                target.put(sizeKey, ((List<?>) collection).size());
            }
        }

        private static void copyScalars(
                Map<String, Object> source,
                Map<String, Object> target,
                String... keys
        ) {
            for (String key : keys) {
                Object value = source.get(key);
                if (value instanceof String) {
                    String text = (String) value;
                    target.put(
                            key,
                            text.substring(0, Math.min(2048, text.length()))
                    );
                } else if (value instanceof Number
                        || value instanceof Boolean
                        || value == null && source.containsKey(key)) {
                    target.put(key, value);
                }
            }
        }

        private static boolean isTerminalStatus(String value) {
            return "completed".equals(value)
                    || "censored".equals(value)
                    || "timeout".equals(value)
                    || "coverage_error".equals(value)
                    || "engine_error".equals(value)
                    || "cancelled".equals(value)
                    || "interrupted".equals(value);
        }

        private static String safeReason(String value) {
            if (value == null || value.trim().isEmpty()) {
                return null;
            }
            String normalized = value.trim().toLowerCase().replaceAll("[^a-z0-9_:-]", "_");
            return normalized.substring(0, Math.min(128, normalized.length()));
        }

        @SuppressWarnings("unchecked")
        private static List<Map<String, Object>> deepCopyRecords(
                List<Map<String, Object>> source
        ) {
            List<Map<String, Object>> result = new ArrayList<>();
            for (Map<String, Object> record : source) {
                Map<String, Object> copy = new LinkedHashMap<>(record);
                Object event = copy.get("event");
                if (event instanceof Map) {
                    copy.put("event", new LinkedHashMap<>((Map<String, Object>) event));
                }
                Object snapshot = copy.get("snapshot");
                if (snapshot instanceof Map) {
                    copy.put("snapshot", new LinkedHashMap<>((Map<String, Object>) snapshot));
                }
                result.add(Collections.unmodifiableMap(copy));
            }
            return Collections.unmodifiableList(result);
        }
    }
}
