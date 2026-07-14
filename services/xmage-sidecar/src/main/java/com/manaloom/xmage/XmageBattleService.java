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
import mage.util.RandomUtil;
import mage.view.GameTypeView;
import mage.view.GameView;
import mage.view.PlayerView;
import mage.view.TableView;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
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
        long seed = longValue(request, "seed", System.currentTimeMillis());
        long timeoutMs = clamp(longValue(request, "timeout_ms", 120000L), 1000L, 900000L);
        String requestId = stringValue(request, "request_id", UUID.randomUUID().toString());
        RandomUtil.setSeed(seed);

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
            while (true) {
                Optional<TableView> current = session.getTable(roomId, tableId);
                TableState state = current.map(TableView::getTableState).orElse(null);
                if (!watching && state == TableState.DUELING && current.isPresent()
                        && !current.get().getGames().isEmpty()) {
                    session.watchGame(current.get().getGames().get(0));
                    watching = true;
                }
                if (state == TableState.FINISHED || client.isGameOver()) {
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
                    requestId,
                    seed,
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
            String requestId,
            long seed,
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
        PlayerView winner = winner(finalView);
        if (finalView != null && finalView.getTotalErrorsCount() > 0) {
            throw new IllegalStateException(
                    "XMage completed with " + finalView.getTotalErrorsCount() + " engine errors"
            );
        }
        String winnerKey = winner == null ? null : winner.getName();
        DeckInput winnerDeck = "deck_a".equals(winnerKey) ? deckA : "deck_b".equals(winnerKey) ? deckB : null;

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("type", "battle");
        result.put("status", "completed");
        result.put("request_id", requestId);
        result.put("engine", "xmage");
        result.put("engine_version", SidecarMain.XMAGE_VERSION);
        result.put("engine_commit", SidecarMain.XMAGE_COMMIT);
        result.put("seed", seed);
        result.put("started_at", Instant.ofEpochMilli(System.currentTimeMillis() - durationMs).toString());
        result.put("duration_ms", durationMs);
        result.put("turns", finalView == null ? 0 : finalView.getTurn());
        result.put("winner", winnerDeck == null ? null : winnerDeck.name);
        result.put("winner_deck_key", winnerKey);
        result.put("winner_deck_id", winnerDeck == null ? null : winnerDeck.id);
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
            cardDatabaseReady = true;
        }
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
                if (resolved != null && !resolved.getName().equals(name)) {
                    resolved = null;
                }
            }
            if (resolved == null) {
                resolved = CardRepository.instance.findPreferredCoreExpansionCard(name, setCode);
            }
            return resolved;
        }

        boolean isAvailable() {
            return availableCardNames.contains(name)
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
