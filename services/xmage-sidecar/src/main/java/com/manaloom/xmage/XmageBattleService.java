package com.manaloom.xmage;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import mage.cards.decks.DeckCardInfo;
import mage.cards.decks.DeckCardLists;
import mage.cards.repository.CardInfo;
import mage.cards.repository.CardRepository;
import mage.cards.repository.CardScanner;
import mage.constants.MatchTimeLimit;
import mage.constants.MultiplayerAttackOption;
import mage.constants.RangeOfInfluence;
import mage.constants.TableState;
import mage.game.match.MatchOptions;
import mage.players.PlayerType;
import mage.remote.Connection;
import mage.remote.Session;
import mage.remote.SessionImpl;
import mage.view.GameTypeView;
import mage.view.GameView;
import mage.view.PlayerView;
import mage.view.TableView;

import java.time.Instant;
import java.text.Normalizer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.locks.ReentrantLock;

final class XmageBattleService {
    private static final String GAME_TYPE = "Freeform Commander Free For All";
    private static final String DECK_TYPE = "Variant Magic - Freeform Commander";
    private static final ReentrantLock SIMULATION_LOCK = new ReentrantLock();
    private static volatile boolean cardDatabaseReady;
    private static volatile Set<String> availableCardNames = Collections.emptySet();
    private static volatile Map<String, String> uniqueCardAliases = Collections.emptyMap();

    private final String host;
    private final int port;

    XmageBattleService(String host, int port) {
        this.host = host;
        this.port = port;
    }

    void warmUp() {
        ensureCardDatabase();
    }

    int catalogSize() {
        ensureCardDatabase();
        return availableCardNames.size();
    }

    Map<String, Object> simulate(JsonObject request) throws Exception {
        SIMULATION_LOCK.lockInterruptibly();
        try {
            ensureCardDatabase();
            return simulateLocked(request);
        } finally {
            SIMULATION_LOCK.unlock();
        }
    }

    Map<String, Object> coverage(JsonObject request) {
        ensureCardDatabase();
        DeckInput deckA = DeckInput.parse(requireObject(request, "deck_a"), "deck_a");
        DeckInput deckB = DeckInput.parse(requireObject(request, "deck_b"), "deck_b");
        List<Map<String, Object>> unsupported = new ArrayList<>();
        List<Map<String, Object>> decks = new ArrayList<>();
        decks.add(deckA.coverage("deck_a", unsupported));
        decks.add(deckB.coverage("deck_b", unsupported));

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("status", unsupported.isEmpty() ? "ready" : "unsupported");
        result.put("engine", "xmage");
        result.put("engine_version", SidecarMain.XMAGE_VERSION);
        result.put("engine_commit", SidecarMain.XMAGE_COMMIT);
        result.put("ready", unsupported.isEmpty());
        result.put("decks", decks);
        result.put("unsupported_cards", unsupported);
        return result;
    }

    Map<String, Object> cardCoverage(JsonObject request) {
        ensureCardDatabase();
        JsonArray rows = request.has("cards") && request.get("cards").isJsonArray()
                ? request.getAsJsonArray("cards") : null;
        if (rows == null || rows.size() == 0) {
            throw new IllegalArgumentException("cards is required");
        }
        List<Map<String, Object>> unsupported = new ArrayList<>();
        int supported = 0;
        int index = 0;
        for (JsonElement row : rows) {
            JsonObject cardRow = row.getAsJsonObject();
            CardInput card = CardInput.parse(cardRow);
            if (!card.isAvailable()) {
                Map<String, Object> missing = card.unsupported(null);
                missing.put("input_index", index);
                if (cardRow.has("card_id") && !cardRow.get("card_id").isJsonNull()) {
                    missing.put("card_id", cardRow.get("card_id").getAsString());
                }
                unsupported.add(missing);
            } else {
                supported++;
            }
            index++;
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("status", unsupported.isEmpty() ? "ready" : "unsupported");
        result.put("engine", "xmage");
        result.put("engine_version", SidecarMain.XMAGE_VERSION);
        result.put("engine_commit", SidecarMain.XMAGE_COMMIT);
        result.put("total", rows.size());
        result.put("supported", supported);
        result.put("unsupported", unsupported.size());
        result.put("unsupported_cards", unsupported);
        return result;
    }

    private Map<String, Object> simulateLocked(JsonObject request) throws Exception {
        DeckInput deckA = DeckInput.parse(requireObject(request, "deck_a"), "deck_a");
        DeckInput deckB = DeckInput.parse(requireObject(request, "deck_b"), "deck_b");
        BattleRequestContract contract = BattleRequestContract.parse(request, deckA, deckB);
        long timeoutMs = contract.timeoutMs;
        String requestId = contract.requestId;
        TrackingMageClient client = new TrackingMageClient();
        Session session = new SessionImpl(client);
        UUID roomId = null;
        UUID tableId = null;
        long startedAt = System.currentTimeMillis();
        boolean timedOut = false;

        try {
            Connection connection = connection(requestId);
            session.connectStart(connection);
            client.setSession(session);
            if (!session.isConnected() || !session.isServerReady()) {
                throw new IllegalStateException("XMage server connection is not ready");
            }
            roomId = session.getMainRoomId();

            GameTypeView gameType = session.getGameTypes().stream()
                    .filter(type -> GAME_TYPE.equals(type.getName()))
                    .findFirst()
                    .orElseThrow(() -> new IllegalStateException("XMage game type is unavailable: " + GAME_TYPE));
            if (!Arrays.asList(session.getDeckTypes()).contains(DECK_TYPE)) {
                throw new IllegalStateException("XMage deck type is unavailable: " + DECK_TYPE);
            }

            MatchOptions options = matchOptions(requestId, gameType);
            TableView table = session.createTable(roomId, options);
            tableId = table.getTableId();
            if (!session.joinTable(roomId, tableId, "deck_a", PlayerType.COMPUTER_MAD, 5,
                    deckA.toDeck("deck_a"), "")) {
                throw new IllegalArgumentException("XMage rejected deck_a");
            }
            if (!session.joinTable(roomId, tableId, "deck_b", PlayerType.COMPUTER_MAD, 5,
                    deckB.toDeck("deck_b"), "")) {
                throw new IllegalArgumentException("XMage rejected deck_b");
            }
            if (!session.startMatch(roomId, tableId)) {
                throw new IllegalStateException("XMage did not start the match");
            }

            boolean watching = false;
            boolean gameObserved = false;
            while (true) {
                Optional<TableView> current = session.getTable(roomId, tableId);
                TableState state = current.map(TableView::getTableState).orElse(null);
                if (!watching && state == TableState.DUELING && current.isPresent()
                        && !current.get().getGames().isEmpty()) {
                    session.watchGame(current.get().getGames().get(0));
                    watching = true;
                }
                GameView lastView = client.getLastView();
                if (lastView != null && lastView.getTurn() > 0) {
                    gameObserved = true;
                }
                if (shouldFinishBattle(
                        client.isGameOver(),
                        state == TableState.FINISHED,
                        gameObserved
                )) {
                    break;
                }
                if (System.currentTimeMillis() - startedAt >= timeoutMs) {
                    timedOut = true;
                    break;
                }
                Thread.sleep(100L);
            }

            if (timedOut) {
                throw new TimeoutException("XMage battle exceeded " + timeoutMs + " ms");
            }
            Thread.sleep(250L);
            return result(
                    contract,
                    deckA,
                    deckB,
                    client,
                    System.currentTimeMillis() - startedAt
            );
        } finally {
            if (!timedOut) {
                if (roomId != null && tableId != null) {
                    try {
                        session.removeTable(roomId, tableId);
                    } catch (Throwable ignored) {
                    }
                }
                try {
                    session.connectStop(false, false);
                } catch (Throwable ignored) {
                }
            }
        }
    }

    private Map<String, Object> result(
            BattleRequestContract contract,
            DeckInput deckA,
            DeckInput deckB,
            TrackingMageClient client,
            long durationMs
    ) {
        List<GameView> views = client.copyViews();
        if (views.isEmpty() && client.getLastView() != null) {
            views.add(client.getLastView());
        }
        List<Map<String, Object>> snapshots = ReplayNormalizer.snapshots(views);
        List<Map<String, Object>> events = ReplayNormalizer.events(client.copyMessages(), snapshots);
        GameView finalView = views.isEmpty() ? null : views.get(views.size() - 1);
        requireCompletedBattleEvidence(
                finalView == null ? 0 : finalView.getTurn(),
                views.size(),
                snapshots.size()
        );
        PlayerView winner = winner(finalView);
        if (finalView != null && finalView.getTotalErrorsCount() > 0) {
            throw new IllegalStateException(
                    "XMage completed with " + finalView.getTotalErrorsCount() + " engine errors"
            );
        }
        String winnerKey = winner == null ? null : winner.getName();
        DeckInput winnerDeck = "deck_a".equals(winnerKey) ? deckA : "deck_b".equals(winnerKey) ? deckB : null;
        int turns = finalView == null ? 0 : finalView.getTurn();
        String status = turns > contract.maxTurns ? "censored" : "completed";
        boolean publishWinner = winnerEligibleForComparison(status);

        Map<String, Object> result = new LinkedHashMap<>();
        result.putAll(contract.metadata(status, turns));
        result.put("type", "battle");
        result.put("status", status);
        result.put("engine", "xmage");
        result.put("engine_version", SidecarMain.XMAGE_VERSION);
        result.put("engine_commit", SidecarMain.XMAGE_COMMIT);
        result.put("started_at", Instant.ofEpochMilli(System.currentTimeMillis() - durationMs).toString());
        result.put("duration_ms", durationMs);
        result.put("turns", turns);
        result.put("winner", winnerDeck == null || !publishWinner ? null : winnerDeck.name);
        result.put("winner_deck_key", publishWinner ? winnerKey : null);
        result.put("winner_deck_id", winnerDeck == null || !publishWinner ? null : winnerDeck.id);
        result.put("game_log", events);
        result.put("events", events);
        result.put("visual_snapshots", snapshots);
        result.put("final_state", snapshots.isEmpty() ? null : snapshots.get(snapshots.size() - 1));
        result.put("unsupported_cards", new ArrayList<>());
        result.put("decision_trace", new ArrayList<>());

        Map<String, Object> learningContract = new LinkedHashMap<>();
        learningContract.put("schema_version", "external_battle_learning_v1");
        learningContract.put("named_draw_identity_available", false);
        learningContract.put("visible_stack_activity_available", true);
        learningContract.put("visible_battlefield_entries_available", true);
        learningContract.put("combat_activity_available", true);
        learningContract.put("ai_decision_rationale_available", false);
        learningContract.put("seed_semantics", SidecarMain.SEED_SEMANTICS);
        learningContract.put("deterministic", false);
        learningContract.put("event_stream_completeness", "best_effort_visible_state_lower_bound");
        learningContract.put("absence_proves_nonuse", false);
        learningContract.put("strategy_or_swap_proof", false);
        result.put("learning_contract", learningContract);

        Map<String, Object> metrics = new LinkedHashMap<>();
        metrics.put("event_count", events.size());
        metrics.put("snapshot_count", snapshots.size());
        metrics.put("total_errors", finalView == null ? null : finalView.getTotalErrorsCount());
        metrics.put("total_effects", finalView == null ? null : finalView.getTotalEffectsCount());
        metrics.put("game_cycle", finalView == null ? null : finalView.getGameCycle());
        metrics.put("semantic_event_count", countEvents(events, null));
        metrics.put("visible_spells_cast", countEvents(events, "stack_entry", "spell"));
        metrics.put("visible_abilities_activated", countEvents(events, "stack_entry", "ability"));
        metrics.put("visible_battlefield_entries", countEvents(events, "battlefield_entry"));
        metrics.put("attackers_declared", countEvents(events, "attacker_declared"));
        metrics.put("decision_trace_count", 0);
        result.put("metrics", metrics);
        return result;
    }

    static void requireCompletedBattleEvidence(int turns, int viewCount, int snapshotCount) {
        if (turns <= 0 || viewCount <= 0 || snapshotCount <= 0) {
            throw new IllegalStateException(
                    "XMage ended without an observed completed game "
                            + "(turns=" + turns
                            + ", views=" + viewCount
                            + ", snapshots=" + snapshotCount + ")"
            );
        }
    }

    static boolean shouldFinishBattle(boolean gameOver, boolean tableFinished, boolean gameViewObserved) {
        return gameViewObserved && (gameOver || tableFinished);
    }

    static boolean winnerEligibleForComparison(String status) {
        return "completed".equals(status);
    }

    private int countEvents(List<Map<String, Object>> events, String action) {
        int count = 0;
        for (Map<String, Object> event : events) {
            String eventAction = String.valueOf(event.get("action"));
            if (action == null) {
                if (ReplayNormalizer.isSemanticAction(eventAction)) {
                    count++;
                }
            } else if (action.equals(eventAction)) {
                count++;
            }
        }
        return count;
    }

    private int countEvents(List<Map<String, Object>> events, String action, String stackObjectKind) {
        int count = 0;
        for (Map<String, Object> event : events) {
            if (action.equals(event.get("action")) && stackObjectKind.equals(event.get("stack_object_kind"))) {
                count++;
            }
        }
        return count;
    }

    private PlayerView winner(GameView view) {
        if (view == null) {
            return null;
        }
        PlayerView candidate = null;
        for (PlayerView player : view.getPlayers()) {
            if (!player.hasLeft() && player.getLife() > 0) {
                if (candidate != null) {
                    return null;
                }
                candidate = player;
            }
        }
        return candidate;
    }

    private Connection connection(String requestId) {
        Connection connection = new Connection();
        connection.setUsername(connectionUsername(requestId));
        connection.setHost(host);
        connection.setPort(port);
        connection.setProxyType(Connection.ProxyType.NONE);
        return connection;
    }

    static String connectionUsername(String requestId) {
        String sanitized = requestId == null ? "" : requestId.replaceAll("[^A-Za-z0-9]", "");
        if (sanitized.isEmpty()) {
            sanitized = "request";
        }
        return "ml_" + sanitized.substring(0, Math.min(8, sanitized.length()));
    }

    private MatchOptions matchOptions(String requestId, GameTypeView gameType) {
        MatchOptions options = new MatchOptions("ManaLoom " + requestId, gameType.getName(), true);
        options.getPlayerTypes().add(PlayerType.COMPUTER_MAD);
        options.getPlayerTypes().add(PlayerType.COMPUTER_MAD);
        options.setDeckType(DECK_TYPE);
        options.setLimited(false);
        options.setAttackOption(MultiplayerAttackOption.MULTIPLE);
        options.setRange(RangeOfInfluence.ALL);
        options.setWinsNeeded(1);
        options.setMatchTimeLimit(MatchTimeLimit.MIN__15);
        return options;
    }

    private static synchronized void ensureCardDatabase() {
        if (!cardDatabaseReady) {
            CardScanner.scan();
            Set<String> names = new HashSet<>(CardRepository.instance.getNames());
            if (names.isEmpty()) {
                throw new IllegalStateException("XMage card catalog is empty after scan");
            }
            availableCardNames = Collections.unmodifiableSet(names);
            uniqueCardAliases = Collections.unmodifiableMap(buildUniqueCardAliases(names));
            cardDatabaseReady = true;
        }
    }

    static String identityAliasKey(String value) {
        String decomposed = Normalizer.normalize(value == null ? "" : value, Normalizer.Form.NFD);
        return decomposed
                .replace("\ua789", "")
                .replaceAll("\\p{M}+", "")
                .trim()
                .toLowerCase(java.util.Locale.ROOT);
    }

    static Map<String, String> buildUniqueCardAliases(Set<String> names) {
        Map<String, String> aliases = new LinkedHashMap<>();
        Set<String> ambiguous = new HashSet<>();
        for (String name : names) {
            String key = identityAliasKey(name);
            if (key.isEmpty() || ambiguous.contains(key)) {
                continue;
            }
            String previous = aliases.putIfAbsent(key, name);
            if (previous != null && !previous.equals(name)) {
                aliases.remove(key);
                ambiguous.add(key);
            }
        }
        return aliases;
    }

    private static JsonObject requireObject(JsonObject input, String key) {
        if (!input.has(key) || !input.get(key).isJsonObject()) {
            throw new IllegalArgumentException(key + " is required");
        }
        return input.getAsJsonObject(key);
    }

    private static String stringValue(JsonObject input, String key, String fallback) {
        JsonElement value = input.get(key);
        return value == null || value.isJsonNull() ? fallback : value.getAsString();
    }

    private static long longValue(JsonObject input, String key, long fallback) {
        JsonElement value = input.get(key);
        return value == null || value.isJsonNull() ? fallback : value.getAsLong();
    }

    private static long clamp(long value, long minimum, long maximum) {
        return Math.max(minimum, Math.min(maximum, value));
    }

    Map<String, Object> requestMetadata(JsonObject request, String status) {
        DeckInput deckA = DeckInput.parse(requireObject(request, "deck_a"), "deck_a");
        DeckInput deckB = DeckInput.parse(requireObject(request, "deck_b"), "deck_b");
        return BattleRequestContract.parse(request, deckA, deckB).metadata(status, null);
    }

    private static final class BattleRequestContract {
        final String requestId;
        final long seed;
        final long timeoutMs;
        final int maxTurns;
        final List<String> focusCards;
        final String forceFocusAccessMode;
        final boolean sameLane;
        final boolean naturalSample;
        final Map<String, Object> deckHashes;
        final String requestHash;
        final boolean legacyCompatibility;

        private BattleRequestContract(
                String requestId,
                long seed,
                long timeoutMs,
                int maxTurns,
                List<String> focusCards,
                String forceFocusAccessMode,
                boolean sameLane,
                boolean naturalSample,
                Map<String, Object> deckHashes,
                String requestHash,
                boolean legacyCompatibility
        ) {
            this.requestId = requestId;
            this.seed = seed;
            this.timeoutMs = timeoutMs;
            this.maxTurns = maxTurns;
            this.focusCards = focusCards;
            this.forceFocusAccessMode = forceFocusAccessMode;
            this.sameLane = sameLane;
            this.naturalSample = naturalSample;
            this.deckHashes = deckHashes;
            this.requestHash = requestHash;
            this.legacyCompatibility = legacyCompatibility;
        }

        static BattleRequestContract parse(JsonObject request, DeckInput deckA, DeckInput deckB) {
            boolean strict = request.has("request_schema_version")
                    && !request.get("request_schema_version").isJsonNull();
            if (strict && !SidecarMain.REQUEST_SCHEMA.equals(request.get("request_schema_version").getAsString())) {
                throw new IllegalArgumentException("unsupported request_schema_version");
            }
            String requestId = stringValue(request, "request_id", UUID.randomUUID().toString());
            if (strict && !requestId.matches("[A-Za-z0-9_-]{1,80}")) {
                throw new IllegalArgumentException("request_id must use 1-80 safe characters");
            }
            if (!strict) {
                requestId = safeRequestId(requestId);
            }
            long seed = strictLong(request, "seed", System.currentTimeMillis(), Long.MIN_VALUE, Long.MAX_VALUE);
            long timeoutMs = strictLong(request, "timeout_ms", 120000L, 1000L, 900000L);
            int maxTurns = (int) strictLong(request, "max_turns", 30L, 1L, 100L);
            List<String> focusCards = stringList(request, "focus_cards", 20, 300);
            String forceMode = stringValue(request, "force_focus_access_mode", "none").toLowerCase(java.util.Locale.ROOT);
            if (!"none".equals(forceMode)) {
                throw new IllegalArgumentException("XMage does not support forced card access");
            }
            boolean sameLane = strictBoolean(request, "same_lane", false);
            boolean naturalSample = strictBoolean(request, "natural_sample", true);

            Map<String, Object> deckHashes = new LinkedHashMap<>();
            deckHashes.put("schema_version", SidecarMain.DECK_HASH_SCHEMA);
            deckHashes.put("algorithm", "sha256");
            deckHashes.put("deck_a", canonicalDeckHash(deckA));
            deckHashes.put("deck_b", canonicalDeckHash(deckB));
            BattleRequestContract provisional = new BattleRequestContract(
                    requestId,
                    seed,
                    timeoutMs,
                    maxTurns,
                    Collections.unmodifiableList(new ArrayList<>(focusCards)),
                    forceMode,
                    sameLane,
                    naturalSample,
                    Collections.unmodifiableMap(deckHashes),
                    "",
                    !strict
            );
            String requestHash = canonicalRequestHash(provisional, deckA.id, deckB.id);
            BattleRequestContract contract = new BattleRequestContract(
                    requestId,
                    seed,
                    timeoutMs,
                    maxTurns,
                    provisional.focusCards,
                    forceMode,
                    sameLane,
                    naturalSample,
                    provisional.deckHashes,
                    requestHash,
                    !strict
            );
            if (strict) {
                requireExact(request, "expected_engine", "xmage");
                requireExact(request, "expected_engine_version", SidecarMain.XMAGE_VERSION);
                requireExact(request, "expected_engine_commit", SidecarMain.XMAGE_COMMIT);
                requireExact(request, "ai_profile", SidecarMain.AI_PROFILE);
                JsonObject suppliedHashes = requireObject(request, "deck_hashes");
                requireExact(suppliedHashes, "schema_version", SidecarMain.DECK_HASH_SCHEMA);
                requireExact(suppliedHashes, "algorithm", "sha256");
                requireExact(suppliedHashes, "deck_a", String.valueOf(deckHashes.get("deck_a")));
                requireExact(suppliedHashes, "deck_b", String.valueOf(deckHashes.get("deck_b")));
                requireExact(request, "request_hash", requestHash);
            }
            return contract;
        }

        Map<String, Object> metadata(String status, Integer turns) {
            boolean timedOut = "timeout".equals(status);
            boolean censored = timedOut || "censored".equals(status);
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("request_id", requestId);
            result.put("seed", seed);
            result.put("timeout_ms", timeoutMs);
            result.put("max_turns", maxTurns);
            result.put("request_hash", requestHash);
            result.put("deck_hashes", deckHashes);
            result.put("ai_profile", SidecarMain.AI_PROFILE);
            result.put("fallback_allowed", "coverage_incomplete".equals(status));
            result.put("fallback_reason", "none");
            result.put("fallback_eligibility_reason", "coverage_incomplete".equals(status)
                    ? "coverage_incomplete_eligible"
                    : timedOut
                    ? "operational_timeout_not_eligible"
                    : "failed".equals(status)
                    ? "operational_failure_not_eligible"
                    : "none");

            Map<String, Object> controls = new LinkedHashMap<>();
            controls.put("max_turns", control(maxTurns, "post_completion_right_censoring", "engine_enforced", false));
            controls.put("focus_cards", control(focusCards, "positive_evidence_observation_only", null, null));
            controls.put("force_focus_access_mode", control(forceFocusAccessMode, "none_only_non_none_rejected", null, null));
            controls.put("same_lane", control(sameLane, "comparison_metadata_only", null, null));
            controls.put("natural_sample", control(naturalSample, "sample_provenance_metadata", null, null));
            Map<String, Object> requestContract = new LinkedHashMap<>();
            requestContract.put("schema_version", SidecarMain.REQUEST_SCHEMA);
            requestContract.put("legacy_compatibility", legacyCompatibility);
            requestContract.put("controls", controls);
            result.put("request_contract", requestContract);

            Map<String, Object> outcome = new LinkedHashMap<>();
            outcome.put("status", status);
            outcome.put("timed_out", timedOut);
            outcome.put("censored", censored);
            outcome.put("censor_reason", timedOut
                    ? "wall_clock_timeout"
                    : "censored".equals(status) ? "max_turns_exceeded" : null);
            outcome.put("timeout_ms", timeoutMs);
            if (turns != null) {
                outcome.put("turns", turns);
            }
            result.put("execution_outcome", outcome);
            return result;
        }

        private static Map<String, Object> control(
                Object value,
                String semantics,
                String extraKey,
                Object extraValue
        ) {
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("value", value);
            result.put("semantics", semantics);
            if (extraKey != null) {
                result.put(extraKey, extraValue);
            }
            return result;
        }

        private static String canonicalDeckHash(DeckInput deck) {
            List<String> records = new ArrayList<>();
            for (CardInput card : deck.cards) {
                records.add(String.join("|",
                        card.commander ? "1" : "0",
                        Integer.toString(card.quantity),
                        base64Field(card.name),
                        base64Field(card.setCode),
                        base64Field(card.number)
                ));
            }
            Collections.sort(records);
            return sha256(SidecarMain.DECK_HASH_SCHEMA + "\n" + String.join("\n", records) + "\n");
        }

        private static String canonicalRequestHash(BattleRequestContract contract, String deckAId, String deckBId) {
            List<String> encodedFocus = new ArrayList<>();
            for (String card : contract.focusCards) {
                encodedFocus.add(base64Field(card));
            }
            String material = String.join("\n",
                    SidecarMain.REQUEST_SCHEMA,
                    "request_id=" + base64Field(contract.requestId),
                    "seed=" + contract.seed,
                    "timeout_ms=" + contract.timeoutMs,
                    "max_turns=" + contract.maxTurns,
                    "focus_cards=" + String.join(",", encodedFocus),
                    "force_focus_access_mode=" + contract.forceFocusAccessMode,
                    "same_lane=" + (contract.sameLane ? "1" : "0"),
                    "natural_sample=" + (contract.naturalSample ? "1" : "0"),
                    "deck_a_id=" + base64Field(deckAId),
                    "deck_b_id=" + base64Field(deckBId),
                    "deck_a_hash=" + contract.deckHashes.get("deck_a"),
                    "deck_b_hash=" + contract.deckHashes.get("deck_b"),
                    "engine=xmage",
                    "engine_version=" + base64Field(SidecarMain.XMAGE_VERSION),
                    "engine_commit=" + SidecarMain.XMAGE_COMMIT,
                    "ai_profile=" + base64Field(SidecarMain.AI_PROFILE)
            );
            return sha256(material + "\n");
        }

        private static String base64Field(String value) {
            return Base64.getUrlEncoder().withoutPadding().encodeToString(value.getBytes(StandardCharsets.UTF_8));
        }

        private static String sha256(String value) {
            try {
                byte[] digest = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
                StringBuilder result = new StringBuilder(digest.length * 2);
                for (byte item : digest) {
                    result.append(String.format("%02x", item & 0xff));
                }
                return result.toString();
            } catch (java.security.NoSuchAlgorithmException error) {
                throw new IllegalStateException("SHA-256 is unavailable", error);
            }
        }

        private static void requireExact(JsonObject input, String key, String expected) {
            if (!input.has(key) || input.get(key).isJsonNull() || !expected.equals(input.get(key).getAsString())) {
                throw new IllegalArgumentException(key + " does not match the running XMage identity/request");
            }
        }

        private static long strictLong(JsonObject input, String key, long fallback, long minimum, long maximum) {
            if (!input.has(key) || input.get(key).isJsonNull()) {
                return fallback;
            }
            JsonElement value = input.get(key);
            if (!value.isJsonPrimitive() || !value.getAsJsonPrimitive().isNumber()) {
                throw new IllegalArgumentException(key + " must be an integer");
            }
            long result;
            try {
                result = value.getAsLong();
            } catch (NumberFormatException error) {
                throw new IllegalArgumentException(key + " must be an integer", error);
            }
            if (result < minimum || result > maximum) {
                throw new IllegalArgumentException(key + " is outside the supported range");
            }
            return result;
        }

        private static boolean strictBoolean(JsonObject input, String key, boolean fallback) {
            if (!input.has(key) || input.get(key).isJsonNull()) {
                return fallback;
            }
            JsonElement value = input.get(key);
            if (!value.isJsonPrimitive() || !value.getAsJsonPrimitive().isBoolean()) {
                throw new IllegalArgumentException(key + " must be a boolean");
            }
            return value.getAsBoolean();
        }

        private static List<String> stringList(JsonObject input, String key, int maxItems, int maxLength) {
            if (!input.has(key) || input.get(key).isJsonNull()) {
                return new ArrayList<>();
            }
            if (!input.get(key).isJsonArray() || input.getAsJsonArray(key).size() > maxItems) {
                throw new IllegalArgumentException(key + " must be a bounded list");
            }
            List<String> result = new ArrayList<>();
            for (JsonElement value : input.getAsJsonArray(key)) {
                if (!value.isJsonPrimitive() || !value.getAsJsonPrimitive().isString()) {
                    throw new IllegalArgumentException(key + " must contain strings");
                }
                String item = value.getAsString().trim();
                if (item.length() > maxLength) {
                    throw new IllegalArgumentException(key + " contains an oversized value");
                }
                if (!item.isEmpty()) {
                    result.add(item);
                }
            }
            return result;
        }

        private static String safeRequestId(String value) {
            String sanitized = value.replaceAll("[^A-Za-z0-9_-]", "");
            if (sanitized.isEmpty()) {
                return UUID.randomUUID().toString();
            }
            return sanitized.substring(0, Math.min(80, sanitized.length()));
        }
    }

    private static final class DeckInput {
        final String id;
        final String name;
        final List<CardInput> cards;

        DeckInput(String id, String name, List<CardInput> cards) {
            this.id = id;
            this.name = name;
            this.cards = cards;
        }

        static DeckInput parse(JsonObject input, String key) {
            String id = stringValue(input, "id", key);
            String name = stringValue(input, "name", key);
            JsonArray cardRows = input.has("cards") && input.get("cards").isJsonArray()
                    ? input.getAsJsonArray("cards") : null;
            if (cardRows == null || cardRows.size() == 0) {
                throw new IllegalArgumentException(key + ".cards is required");
            }

            List<CardInput> cards = new ArrayList<>();
            int total = 0;
            int commanders = 0;
            for (JsonElement row : cardRows) {
                CardInput card = CardInput.parse(row.getAsJsonObject());
                cards.add(card);
                total += card.quantity;
                if (card.commander) {
                    commanders += card.quantity;
                }
            }
            if (total != 100) {
                throw new IllegalArgumentException(key + " must contain exactly 100 cards, got " + total);
            }
            if (commanders != 1) {
                throw new IllegalArgumentException(key + " must contain exactly one commander, got " + commanders);
            }
            return new DeckInput(id, name, cards);
        }

        DeckCardLists toDeck(String deckKey) {
            DeckCardLists deck = new DeckCardLists();
            deck.setName(name);
            List<Map<String, Object>> missing = unresolvedCards(deckKey);
            if (!missing.isEmpty()) {
                throw new UnsupportedCardsException(missing);
            }
            for (CardInput card : cards) {
                CardInfo resolved = card.resolve();
                for (int index = 0; index < card.quantity; index++) {
                    DeckCardInfo info = new DeckCardInfo(
                            resolved.getName(),
                            resolved.getCardNumber(),
                            resolved.getSetCode()
                    );
                    if (card.commander) {
                        deck.getSideboard().add(info);
                    } else {
                        deck.getCards().add(info);
                    }
                }
            }
            return deck;
        }

        Map<String, Object> coverage(String deckKey, List<Map<String, Object>> allUnsupported) {
            List<Map<String, Object>> unsupported = unresolvedCards(deckKey);
            allUnsupported.addAll(unsupported);
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("deck_key", deckKey);
            result.put("deck_id", id);
            result.put("deck_name", name);
            result.put("ready", unsupported.isEmpty());
            result.put("unsupported_cards", unsupported);
            return result;
        }

        private List<Map<String, Object>> unresolvedCards(String deckKey) {
            List<Map<String, Object>> missing = new ArrayList<>();
            for (CardInput card : cards) {
                if (card.resolve() == null) {
                    missing.add(card.unsupported(deckKey));
                }
            }
            return missing;
        }
    }

    private static final class CardInput {
        final String name;
        final String setCode;
        final String number;
        final int quantity;
        final boolean commander;

        CardInput(String name, String setCode, String number, int quantity, boolean commander) {
            this.name = name;
            this.setCode = setCode;
            this.number = number;
            this.quantity = quantity;
            this.commander = commander;
        }

        static CardInput parse(JsonObject input) {
            String name = stringValue(input, "name", "").trim();
            if (name.isEmpty()) {
                throw new IllegalArgumentException("card.name is required");
            }
            return new CardInput(
                    name,
                    stringValue(input, "set_code", "").trim(),
                    stringValue(input, "collector_number", "").trim(),
                    (int) clamp(longValue(input, "quantity", 1), 1, 99),
                    input.has("is_commander") && input.get("is_commander").getAsBoolean()
            );
        }

        CardInfo resolve() {
            CardInfo resolved = null;
            if (!setCode.isEmpty() && !number.isEmpty()) {
                resolved = CardRepository.instance.findCard(setCode, number, true);
                if (resolved != null && !sameResolvedIdentity(resolved.getName())) {
                    resolved = null;
                }
            }
            if (resolved == null) {
                resolved = CardRepository.instance.findPreferredCoreExpansionCard(name, setCode);
            }
            if (resolved == null) {
                String alias = uniqueCardAliases.get(identityAliasKey(name));
                if (alias != null) {
                    resolved = CardRepository.instance.findPreferredCoreExpansionCard(alias, setCode);
                }
            }
            return resolved;
        }

        private boolean sameResolvedIdentity(String resolvedName) {
            if (resolvedName.equals(name)) {
                return true;
            }
            String alias = uniqueCardAliases.get(identityAliasKey(name));
            return resolvedName.equals(alias);
        }

        boolean isAvailable() {
            return availableCardNames.contains(name)
                    || uniqueCardAliases.containsKey(identityAliasKey(name))
                    || (name.contains(" // ") && resolve() != null);
        }

        Map<String, Object> unsupported(String deckKey) {
            Map<String, Object> result = new LinkedHashMap<>();
            if (deckKey != null) {
                result.put("deck_key", deckKey);
            }
            result.put("name", name);
            result.put("set_code", setCode);
            result.put("collector_number", number);
            result.put("quantity", quantity);
            result.put("is_commander", commander);
            return result;
        }
    }

    static final class UnsupportedCardsException extends IllegalArgumentException {
        private final List<Map<String, Object>> unsupportedCards;

        UnsupportedCardsException(List<Map<String, Object>> unsupportedCards) {
            super("XMage could not resolve " + unsupportedCards.size() + " card entries");
            this.unsupportedCards = new ArrayList<>(unsupportedCards);
        }

        List<Map<String, Object>> getUnsupportedCards() {
            return new ArrayList<>(unsupportedCards);
        }
    }
}
