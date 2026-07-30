package com.manaloom.xmage;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import mage.abilities.Modes;
import mage.cards.decks.DeckCardLists;
import mage.constants.MatchTimeLimit;
import mage.constants.MultiplayerAttackOption;
import mage.constants.PlayerAction;
import mage.constants.RangeOfInfluence;
import mage.constants.TableState;
import mage.game.match.MatchOptions;
import mage.interfaces.MageClient;
import mage.interfaces.callback.ClientCallback;
import mage.interfaces.callback.ClientCallbackMethod;
import mage.players.PlayableObjectStats;
import mage.players.PlayableObjectsList;
import mage.players.PlayerType;
import mage.remote.Connection;
import mage.remote.Session;
import mage.remote.SessionImpl;
import mage.utils.MageVersion;
import mage.view.AbilityPickerView;
import mage.view.CardView;
import mage.view.CardsView;
import mage.view.GameClientMessage;
import mage.view.GameEndView;
import mage.view.GameTypeView;
import mage.view.GameView;
import mage.view.PlayerView;
import mage.view.TableClientMessage;
import mage.view.TableView;
import org.jsoup.Jsoup;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * Bounded transient transport for interactive XMage sessions.
 *
 * PostgreSQL remains the product truth. This registry deliberately keeps only
 * the live Session objects that cannot be serialized safely. Every externally
 * visible prompt uses the opaque IDs produced by HumanVsAiSpikeHarness.
 */
final class InteractiveBattleRegistry {
    static final String RUNTIME_SCHEMA = "interactive_battle_runtime_v1";
    static final String REQUEST_SCHEMA = "interactive_battle_request_v1";
    static final String PROMPT_SCHEMA = "interactive_battle_prompt_v1";
    static final String PRIVATE_STATE_SCHEMA =
            "interactive_battle_private_state_v1";
    static final String ACTION_SCHEMA = "interactive_battle_action_v1";

    private static final String GAME_TYPE =
            "Freeform Commander Free For All";
    private static final String DECK_TYPE =
            "Variant Magic - Freeform Commander";
    private static final long TERMINAL_RETENTION_MS =
            TimeUnit.MINUTES.toMillis(10);
    private static final long CONCEDE_GRACE_MS =
            TimeUnit.SECONDS.toMillis(10);
    private static final int MAX_ACTION_HISTORY = 256;
    private static final Gson GSON = new Gson();

    private final String host;
    private final int port;
    private final int maximumActive;
    private final Map<String, RuntimeSession> sessions =
            new LinkedHashMap<>();
    private final ExecutorService executor;

    InteractiveBattleRegistry(
            String host,
            int port,
            int maximumActive
    ) {
        if (maximumActive < 1 || maximumActive > 32) {
            throw new IllegalArgumentException(
                    "interactive maximumActive must be between 1 and 32"
            );
        }
        this.host = host;
        this.port = port;
        this.maximumActive = maximumActive;
        this.executor = Executors.newFixedThreadPool(
                maximumActive,
                task -> {
                    Thread thread = new Thread(
                            task,
                            "xmage-interactive-session"
                    );
                    thread.setDaemon(true);
                    return thread;
                }
        );
    }

    synchronized Map<String, Object> create(JsonObject request) {
        sweep();
        SessionRequest parsed = SessionRequest.parse(request);
        RuntimeSession correlated = findByRequestId(parsed.requestId);
        if (correlated != null) {
            if (!correlated.request.requestHash.equals(parsed.requestHash)) {
                throw new ConflictException("request_id_conflict");
            }
            return correlated.snapshot();
        }
        if (activeCount() >= maximumActive) {
            throw new CapacityException();
        }
        String runtimeId = runtimeId();
        RuntimeSession session = new RuntimeSession(
                runtimeId,
                parsed,
                host,
                port
        );
        sessions.put(runtimeId, session);
        executor.submit(session);
        return session.snapshot();
    }

    synchronized Map<String, Object> read(String runtimeId) {
        sweep();
        RuntimeSession session = require(runtimeId);
        return session.snapshot();
    }

    synchronized Map<String, Object> respond(
            String runtimeId,
            JsonObject request
    ) {
        sweep();
        return require(runtimeId).respond(request);
    }

    synchronized Map<String, Object> concede(
            String runtimeId,
            JsonObject request
    ) {
        sweep();
        return require(runtimeId).concede(request);
    }

    synchronized Map<String, Object> metrics() {
        sweep();
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("schema_version", RUNTIME_SCHEMA);
        result.put("maximum_active", maximumActive);
        result.put("active", activeCount());
        result.put("retained", sessions.size());
        result.put("runtime_mode", "interactive");
        result.put("batch_simulation_available", false);
        return result;
    }

    synchronized void close() {
        for (RuntimeSession session : sessions.values()) {
            session.shutdown();
        }
        executor.shutdownNow();
    }

    private RuntimeSession require(String runtimeId) {
        if (!isRuntimeId(runtimeId)) {
            throw new NotFoundException();
        }
        RuntimeSession session = sessions.get(runtimeId);
        if (session == null) {
            throw new NotFoundException();
        }
        return session;
    }

    private RuntimeSession findByRequestId(String requestId) {
        for (RuntimeSession session : sessions.values()) {
            if (session.request.requestId.equals(requestId)) {
                return session;
            }
        }
        return null;
    }

    private int activeCount() {
        int result = 0;
        for (RuntimeSession session : sessions.values()) {
            if (!session.isTerminal()) {
                result++;
            }
        }
        return result;
    }

    private void sweep() {
        long now = System.currentTimeMillis();
        List<String> expired = new ArrayList<>();
        for (Map.Entry<String, RuntimeSession> entry : sessions.entrySet()) {
            if (entry.getValue().removableAt(now)) {
                expired.add(entry.getKey());
            }
        }
        for (String runtimeId : expired) {
            RuntimeSession removed = sessions.remove(runtimeId);
            if (removed != null) {
                removed.shutdown();
            }
        }
    }

    static boolean isRuntimeId(String value) {
        return value != null
                && value.matches("^ibsrt_[A-Za-z0-9_-]{16,96}$");
    }

    static final class NotFoundException extends RuntimeException {
    }

    static final class CapacityException extends RuntimeException {
    }

    static final class ConflictException extends RuntimeException {
        final String code;

        ConflictException(String code) {
            super(code);
            this.code = code;
        }
    }

    private static final class RuntimeSession
            implements Runnable, MageClient {
        private static final MageVersion VERSION =
                new MageVersion(MageClient.class);

        private final Object lock = new Object();
        private final String runtimeId;
        private final SessionRequest request;
        private final String host;
        private final int port;
        private final HumanVsAiSpikeHarness.PromptRegistry promptRegistry;
        private final List<GameView> views = new ArrayList<>();
        private final Map<String, ActionReceipt> actions =
                new LinkedHashMap<>();
        private final long createdAtMillis = System.currentTimeMillis();

        private volatile Session remoteSession;
        private volatile UUID roomId;
        private volatile UUID tableId;
        private volatile UUID gameId;
        private volatile UUID playerId;
        private volatile GameView lastView;
        private volatile long lastViewFingerprint;
        private volatile long lastStateVersion;
        private volatile boolean hasViewFingerprint;
        private volatile boolean gameStarted;
        private volatile boolean gameOver;
        private volatile boolean won;
        private volatile boolean shutdown;
        private volatile String status = "starting";
        private volatile String terminalReason;
        private volatile String errorCode;
        private volatile long terminalAtMillis;
        private volatile long lastActivityMillis = createdAtMillis;
        private volatile ActivePrompt activePrompt;
        private volatile String requestedTerminalStatus;
        private volatile String requestedTerminalReason;
        private volatile Map<String, Object> publicReplay;

        RuntimeSession(
                String runtimeId,
                SessionRequest request,
                String host,
                int port
        ) {
            this.runtimeId = runtimeId;
            this.request = request;
            this.host = host;
            this.port = port;
            this.promptRegistry =
                    new HumanVsAiSpikeHarness.PromptRegistry(promptSecret());
        }

        @Override
        public void run() {
            Session session = new SessionImpl(this);
            remoteSession = session;
            try {
                connect(session);
                startMatch(session);
                waitForTerminal(session);
            } catch (Throwable error) {
                error.printStackTrace(System.err);
                fail(
                        "engine_error",
                        "interactive_runtime_failed",
                        error.getClass().getSimpleName()
                );
            } finally {
                cleanup(session);
            }
        }

        private void connect(Session session) throws Exception {
            Connection connection = new Connection();
            connection.setUsername(
                    XmageBattleService.connectionUsername(request.requestId)
            );
            connection.setHost(host);
            connection.setPort(port);
            connection.setProxyType(Connection.ProxyType.NONE);
            boolean accepted = session.connectStart(connection);
            long deadline = System.currentTimeMillis() + 5_000L;
            while (accepted
                    && (!session.isConnected()
                    || !Boolean.TRUE.equals(session.isServerReady()))
                    && System.currentTimeMillis() < deadline) {
                Thread.sleep(25L);
            }
            if (!accepted
                    || !session.isConnected()
                    || !Boolean.TRUE.equals(session.isServerReady())) {
                throw new IllegalStateException(
                        "XMage interactive connection is not ready"
                );
            }
        }

        private void startMatch(Session session) {
            roomId = session.getMainRoomId();
            GameTypeView gameType = session.getGameTypes().stream()
                    .filter(type -> GAME_TYPE.equals(type.getName()))
                    .findFirst()
                    .orElseThrow(() -> new IllegalStateException(
                            "XMage game type unavailable: " + GAME_TYPE
                    ));
            if (!Arrays.asList(session.getDeckTypes()).contains(DECK_TYPE)) {
                throw new IllegalStateException(
                        "XMage deck type unavailable: " + DECK_TYPE
                );
            }
            MatchOptions options = HumanVsAiSpikeHarness.matchOptions(
                    "ManaLoom interactive " + request.requestId,
                    gameType.getName()
            );
            options.setDeckType(DECK_TYPE);
            options.setLimited(false);
            options.setAttackOption(MultiplayerAttackOption.MULTIPLE);
            options.setRange(RangeOfInfluence.ALL);
            options.setWinsNeeded(1);
            options.setMatchTimeLimit(MatchTimeLimit.MIN__15);

            TableView table = session.createTable(roomId, options);
            if (table == null || table.getTableId() == null) {
                throw new IllegalStateException(
                        "XMage did not create interactive table"
                );
            }
            tableId = table.getTableId();
            HumanVsAiSpikeHarness.joinSeats(
                    session,
                    roomId,
                    tableId,
                    request.deckA.toDeck("deck_a"),
                    request.deckB.toDeck("deck_b")
            );
            if (!session.startMatch(roomId, tableId)) {
                throw new IllegalStateException(
                        "XMage did not start interactive match"
                );
            }
            synchronized (lock) {
                if (!"waiting_for_action".equals(status)) {
                    status = "running";
                }
                lastActivityMillis = System.currentTimeMillis();
                lock.notifyAll();
            }
        }

        private void waitForTerminal(Session session) throws Exception {
            while (!shutdown && !isTerminal()) {
                long now = System.currentTimeMillis();
                if (gameOver) {
                    String completedStatus =
                            requestedTerminalStatus == null
                                    ? (maxTurn() > request.maxTurns
                                    ? "censored"
                                    : "completed")
                                    : requestedTerminalStatus;
                    String reason =
                            requestedTerminalReason == null
                                    ? "engine_game_over"
                                    : requestedTerminalReason;
                    complete(completedStatus, reason);
                    break;
                }
                if (now - createdAtMillis >= request.ttlSeconds * 1000L) {
                    requestConcede(
                            session,
                            "expired",
                            "interactive_session_ttl_expired"
                    );
                } else {
                    ActivePrompt prompt = activePrompt;
                    if (prompt != null
                            && now >= prompt.deadlineAtMillis) {
                        requestConcede(
                                session,
                                "abandoned",
                                "interactive_prompt_deadline_expired"
                        );
                    }
                }
                if (requestedTerminalStatus != null
                        && now - lastActivityMillis >= CONCEDE_GRACE_MS
                        && !gameOver) {
                    fail(
                            "timeout",
                            "interactive_concede_unconfirmed",
                            "concede_game_over_timeout"
                    );
                    break;
                }
                Optional<TableView> table =
                        roomId == null || tableId == null
                                ? Optional.empty()
                                : session.getTable(roomId, tableId);
                if (table.isPresent()
                        && table.get().getTableState() == TableState.FINISHED
                        && gameStarted) {
                    gameOver = true;
                    continue;
                }
                synchronized (lock) {
                    lock.wait(50L);
                }
            }
        }

        Map<String, Object> respond(JsonObject input) {
            requireActionSchema(input);
            String actionId = requiredString(input, "action_id", 128);
            String fingerprint = sha256(GSON.toJson(input));
            synchronized (lock) {
                ActionReceipt receipt = actions.get(actionId);
                if (receipt != null) {
                    if (!receipt.fingerprint.equals(fingerprint)) {
                        throw new ConflictException(
                                "action_idempotency_conflict"
                        );
                    }
                    return snapshot();
                }
                if (isTerminal()) {
                    throw new ConflictException("session_terminal");
                }
                ActivePrompt envelope = activePrompt;
                if (envelope == null
                        || !"waiting_for_action".equals(status)) {
                    throw new ConflictException("action_stale");
                }
                long stateVersion = requiredLong(
                        input,
                        "state_version",
                        1,
                        20_000_000
                );
                String promptId = requiredString(input, "prompt_id", 80);
                if (stateVersion != envelope.prompt.stateVersion
                        || !promptId.equals(envelope.prompt.promptId)) {
                    throw new ConflictException("action_stale");
                }

                Dispatch response = resolve(envelope, input);
                activePrompt = null;
                status = "running";
                lastActivityMillis = System.currentTimeMillis();
                boolean accepted = response.dispatch(requireSession());
                if (!accepted) {
                    fail(
                            "engine_error",
                            "interactive_action_rejected_by_xmage",
                            "xmage_response_rejected"
                    );
                    throw new ConflictException("action_rejected");
                }
                putReceipt(actionId, fingerprint);
                lock.notifyAll();
                return snapshot();
            }
        }

        Map<String, Object> concede(JsonObject input) {
            requireActionSchema(input);
            String actionId = requiredString(input, "action_id", 128);
            String fingerprint = sha256(GSON.toJson(input));
            synchronized (lock) {
                ActionReceipt receipt = actions.get(actionId);
                if (receipt != null) {
                    if (!receipt.fingerprint.equals(fingerprint)) {
                        throw new ConflictException(
                                "action_idempotency_conflict"
                        );
                    }
                    return snapshot();
                }
                if (isTerminal()) {
                    putReceipt(actionId, fingerprint);
                    return snapshot();
                }
                requestConcede(
                        requireSession(),
                        "conceded",
                        "user_conceded"
                );
                putReceipt(actionId, fingerprint);
                long deadline =
                        System.currentTimeMillis() + CONCEDE_GRACE_MS;
                while (!isTerminal()
                        && System.currentTimeMillis() < deadline) {
                    try {
                        lock.wait(50L);
                    } catch (InterruptedException error) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
                if (!isTerminal() && gameOver) {
                    complete("conceded", "user_conceded");
                }
                return snapshot();
            }
        }

        Map<String, Object> snapshot() {
            synchronized (lock) {
                Map<String, Object> result = new LinkedHashMap<>();
                result.put("interactive_schema_version", RUNTIME_SCHEMA);
                result.put("runtime_session_id", runtimeId);
                result.put("request_id", request.requestId);
                result.put("request_hash", request.requestHash);
                result.put("status", status);
                result.put("terminal", isTerminal());
                result.put("state_version", stateVersion());
                result.put("private_state", privateState());
                result.put(
                        "prompt",
                        activePrompt == null
                                ? null
                                : activePrompt.payload
                );
                result.put(
                        "last_activity_at",
                        Instant.ofEpochMilli(lastActivityMillis).toString()
                );
                result.put("terminal_reason", terminalReason);
                result.put("error_code", errorCode);
                if (publicReplay != null) {
                    result.put("public_replay", publicReplay);
                }
                return result;
            }
        }

        private Dispatch resolve(
                ActivePrompt envelope,
                JsonObject input
        ) {
            String responseKind = requiredString(
                    input,
                    "response_kind",
                    32
            );
            if ("delegate".equals(responseKind)) {
                if (!input.has("delegate")
                        || !input.get("delegate").isJsonPrimitive()
                        || !input.get("delegate").getAsBoolean()) {
                    throw new ConflictException("action_shape_invalid");
                }
                if (envelope.prompt.inputMode
                        == HumanVsAiSpikeHarness.InputMode.INTEGER) {
                    HumanVsAiSpikeHarness.ResolvedResponse response =
                            promptRegistry.resolveInteger(
                                    envelope.prompt.promptId,
                                    envelope.prompt.stateVersion,
                                    envelope.prompt.minimum
                            );
                    return session -> response.dispatch(session);
                }
                if (envelope.prompt.inputMode
                        == HumanVsAiSpikeHarness.InputMode.MULTI_AMOUNT) {
                    HumanVsAiSpikeHarness.ResolvedResponse response =
                            promptRegistry.resolveMinimumMultiAmount(
                                    envelope.prompt.promptId,
                                    envelope.prompt.stateVersion
                            );
                    return session -> response.dispatch(session);
                }
                String optionId = envelope.safeOptionId();
                if (envelope.typed) {
                    HumanVsAiSpikeHarness.ResolvedResponse response =
                            promptRegistry.resolveResponse(
                                    envelope.prompt.promptId,
                                    envelope.prompt.stateVersion,
                                    optionId
                            );
                    return session -> response.dispatch(session);
                }
                Object response = promptRegistry.resolve(
                        envelope.prompt.promptId,
                        envelope.prompt.stateVersion,
                        optionId
                );
                return legacyDispatch(
                        envelope.prompt.gameId,
                        response
                );
            }
            if ("option".equals(responseKind)) {
                String optionId = requiredString(
                        input,
                        "option_id",
                        80
                );
                if (envelope.typed) {
                    HumanVsAiSpikeHarness.ResolvedResponse response =
                            promptRegistry.resolveResponse(
                                    envelope.prompt.promptId,
                                    envelope.prompt.stateVersion,
                                    optionId
                            );
                    return session -> response.dispatch(session);
                }
                Object response = promptRegistry.resolve(
                        envelope.prompt.promptId,
                        envelope.prompt.stateVersion,
                        optionId
                );
                return legacyDispatch(
                        envelope.prompt.gameId,
                        response
                );
            }
            if ("integer".equals(responseKind)) {
                if (!input.has("integer_value")
                        || !input.get("integer_value").isJsonPrimitive()) {
                    throw new ConflictException("action_shape_invalid");
                }
                int value = input.get("integer_value").getAsInt();
                HumanVsAiSpikeHarness.ResolvedResponse response =
                        promptRegistry.resolveInteger(
                                envelope.prompt.promptId,
                                envelope.prompt.stateVersion,
                                value
                        );
                return session -> response.dispatch(session);
            }
            if ("multiAmount".equals(responseKind)) {
                JsonArray rawValues =
                        input.has("multi_amount_values")
                                && input.get("multi_amount_values").isJsonArray()
                                ? input.getAsJsonArray("multi_amount_values")
                                : null;
                if (rawValues == null || rawValues.size() == 0) {
                    throw new ConflictException("action_shape_invalid");
                }
                List<Integer> values = new ArrayList<>();
                for (JsonElement raw : rawValues) {
                    values.add(raw.getAsInt());
                }
                HumanVsAiSpikeHarness.ResolvedResponse response =
                        promptRegistry.resolveMultiAmount(
                                envelope.prompt.promptId,
                                envelope.prompt.stateVersion,
                                values
                        );
                return session -> response.dispatch(session);
            }
            throw new ConflictException("action_shape_invalid");
        }

        private Dispatch legacyDispatch(UUID targetGameId, Object response) {
            if (response instanceof Boolean) {
                return session -> session.sendPlayerBoolean(
                        targetGameId,
                        (Boolean) response
                );
            }
            if (response instanceof UUID) {
                return session -> session.sendPlayerUUID(
                        targetGameId,
                        (UUID) response
                );
            }
            throw new ConflictException("action_response_not_allowlisted");
        }

        private void requestConcede(
                Session session,
                String terminalStatus,
                String reason
        ) {
            synchronized (lock) {
                if (isTerminal() || requestedTerminalStatus != null) {
                    return;
                }
                requestedTerminalStatus = terminalStatus;
                requestedTerminalReason = reason;
                activePrompt = null;
                status = "running";
                lastActivityMillis = System.currentTimeMillis();
                if (gameId == null
                        || !session.sendPlayerAction(
                        PlayerAction.CONCEDE,
                        gameId,
                        null
                )) {
                    fail(
                            "engine_error",
                            "interactive_concede_rejected",
                            "concede_rejected"
                    );
                }
                lock.notifyAll();
            }
        }

        private void complete(String terminalStatus, String reason) {
            synchronized (lock) {
                if (isTerminal()) {
                    return;
                }
                status = terminalStatus;
                terminalReason = reason;
                activePrompt = null;
                lastActivityMillis = System.currentTimeMillis();
                terminalAtMillis = lastActivityMillis;
                publicReplay = buildPublicReplay();
                lock.notifyAll();
            }
        }

        private void fail(
                String terminalStatus,
                String reason,
                String code
        ) {
            synchronized (lock) {
                if (isTerminal()) {
                    return;
                }
                status = terminalStatus;
                terminalReason = reason;
                errorCode = bounded(code, 120);
                activePrompt = null;
                lastActivityMillis = System.currentTimeMillis();
                terminalAtMillis = lastActivityMillis;
                lock.notifyAll();
            }
        }

        private Map<String, Object> buildPublicReplay() {
            List<GameView> copiedViews;
            synchronized (views) {
                copiedViews = new ArrayList<>(views);
            }
            if (copiedViews.isEmpty() && lastView != null) {
                copiedViews.add(lastView);
            }
            List<Map<String, Object>> snapshots =
                    ReplayNormalizer.snapshots(copiedViews);
            List<Map<String, Object>> events =
                    ReplayNormalizer.events(
                            Collections.<Map<String, Object>>emptyList(),
                            snapshots
                    );
            GameView finalView =
                    copiedViews.isEmpty()
                            ? null
                            : copiedViews.get(copiedViews.size() - 1);
            PlayerView winner = winner(finalView);
            String winnerKey =
                    winner == null ? null : winner.getName();
            XmageBattleService.DeckInput winnerDeck =
                    "deck_a".equals(winnerKey)
                            ? request.deckA
                            : "deck_b".equals(winnerKey)
                            ? request.deckB
                            : null;

            Map<String, Object> replay = new LinkedHashMap<>();
            replay.put("type", "interactive_coach");
            replay.put("status", status);
            replay.put("engine", "xmage");
            replay.put("engine_version", SidecarMain.XMAGE_VERSION);
            replay.put("engine_commit", SidecarMain.XMAGE_COMMIT);
            replay.put(
                    "engine_patch_commit",
                    SidecarMain.XMAGE_PATCH_COMMIT
            );
            replay.put("request_schema_version", REQUEST_SCHEMA);
            replay.put("request_hash", request.requestHash);
            replay.put("request_id", request.requestId);
            replay.put("turns", finalView == null ? 0 : finalView.getTurn());
            replay.put("winner", winnerDeck == null ? null : winnerDeck.name);
            replay.put("winner_deck_key", winnerKey);
            replay.put(
                    "winner_deck_id",
                    winnerDeck == null ? null : winnerDeck.id
            );
            replay.put("game_log", events);
            replay.put("events", events);
            replay.put("visual_snapshots", snapshots);
            replay.put(
                    "final_state",
                    snapshots.isEmpty()
                            ? null
                            : snapshots.get(snapshots.size() - 1)
            );
            replay.put("decision_trace", new ArrayList<>());
            Map<String, Object> metrics = new LinkedHashMap<>();
            metrics.put("event_count", events.size());
            metrics.put("snapshot_count", snapshots.size());
            metrics.put("interactive", true);
            metrics.put("human_won", won);
            replay.put("metrics", metrics);
            Map<String, Object> learning = new LinkedHashMap<>();
            learning.put(
                    "schema_version",
                    "external_battle_learning_v1"
            );
            learning.put("named_draw_identity_available", false);
            learning.put("visible_stack_activity_available", true);
            learning.put("visible_battlefield_entries_available", true);
            learning.put("combat_activity_available", true);
            learning.put("ai_decision_rationale_available", false);
            learning.put(
                    "event_stream_completeness",
                    "best_effort_visible_state_lower_bound"
            );
            learning.put("absence_proves_nonuse", false);
            learning.put("strategy_or_swap_proof", false);
            replay.put("learning_contract", learning);
            return replay;
        }

        private Map<String, Object> privateState() {
            GameView view = lastView;
            Map<String, Object> state = new LinkedHashMap<>();
            state.put("schema_version", PRIVATE_STATE_SCHEMA);
            if (view == null) {
                state.put("turn", 0);
                state.put("phase", null);
                state.put("step", null);
                state.put("active_player", null);
                state.put("priority_player", null);
                state.put("players", new ArrayList<>());
                state.put("stack", new ArrayList<>());
                state.put("combat", new ArrayList<>());
                state.put("own_hand", new ArrayList<>());
                return state;
            }
            List<Map<String, Object>> snapshots =
                    ReplayNormalizer.snapshots(
                            Collections.singletonList(view)
                    );
            if (!snapshots.isEmpty()) {
                state.putAll(snapshots.get(0));
            }
            CardsView hand = view.getMyHand();
            state.put(
                    "own_hand",
                    hand == null
                            ? new ArrayList<>()
                            : ReplayNormalizer.cards(hand.values())
            );
            PlayerView mine = view.getMyPlayer();
            state.put(
                    "own_player",
                    mine == null ? null : mine.getName()
            );
            state.put("priority_time_seconds", view.getPriorityTime());
            return state;
        }

        private void openPrompt(ClientCallback callback) {
            synchronized (lock) {
                if (activePrompt != null) {
                    throw new IllegalStateException(
                            "another interactive prompt is active"
                    );
                }
                PromptBuild build;
                switch (callback.getMethod()) {
                    case GAME_ASK:
                        build = questionPrompt(callback);
                        break;
                    case GAME_SELECT:
                        build = selectPrompt(callback);
                        break;
                    case GAME_TARGET:
                        build = targetPrompt(callback);
                        break;
                    case GAME_CHOOSE_ABILITY:
                    case GAME_CHOOSE_PILE:
                    case GAME_CHOOSE_CHOICE:
                    case GAME_PLAY_MANA:
                    case GAME_PLAY_XMANA:
                    case GAME_GET_AMOUNT:
                    case GAME_GET_MULTI_AMOUNT:
                        build = typedPrompt(callback);
                        break;
                    default:
                        throw new IllegalArgumentException(
                                "decision callback is not allowlisted"
                        );
                }
                long deadline =
                        System.currentTimeMillis()
                                + request.promptTimeoutSeconds * 1000L;
                Map<String, Object> payload = promptPayload(
                        build.prompt,
                        build.descriptors,
                        build.message,
                        deadline
                );
                activePrompt = new ActivePrompt(
                        build.prompt,
                        build.typed,
                        payload,
                        deadline,
                        build.descriptors
                );
                lastStateVersion = Math.max(
                        lastStateVersion,
                        build.prompt.stateVersion
                );
                status = "waiting_for_action";
                lastActivityMillis = System.currentTimeMillis();
                lock.notifyAll();
            }
        }

        private PromptBuild questionPrompt(ClientCallback callback) {
            GameClientMessage message = requirePayload(
                    callback,
                    GameClientMessage.class
            );
            List<Object> raw = Arrays.<Object>asList(
                    Boolean.TRUE,
                    Boolean.FALSE
            );
            HumanVsAiSpikeHarness.Prompt prompt = promptRegistry.open(
                    callback,
                    message.getMessage(),
                    message.getOptions(),
                    raw
            );
            List<OptionDescriptor> options = new ArrayList<>();
            if (prompt.kind
                    == HumanVsAiSpikeHarness.PromptKind.MULLIGAN) {
                options.add(new OptionDescriptor(
                        "Fazer mulligan",
                        "mulligan",
                        null
                ));
                options.add(new OptionDescriptor(
                        "Manter esta mão",
                        "keep",
                        null
                ));
            } else {
                options.add(new OptionDescriptor("Sim", "choice", null));
                options.add(new OptionDescriptor("Não", "choice", null));
            }
            return new PromptBuild(
                    prompt,
                    false,
                    message.getMessage(),
                    options
            );
        }

        private PromptBuild selectPrompt(ClientCallback callback) {
            GameClientMessage message = requirePayload(
                    callback,
                    GameClientMessage.class
            );
            List<Object> raw = new ArrayList<>();
            List<OptionDescriptor> options = new ArrayList<>();
            GameView view = message.getGameView();
            PlayableObjectsList playable =
                    view == null ? null : view.getCanPlayObjects();
            if (playable != null && playable.getObjects() != null) {
                List<UUID> ids = new ArrayList<>(
                        playable.getObjects().keySet()
                );
                ids.sort(Comparator.comparing(UUID::toString));
                for (UUID id : ids) {
                    PlayableObjectStats stats =
                            playable.getObjects().get(id);
                    raw.add(id);
                    options.add(new OptionDescriptor(
                            playableLabel(view, id, stats),
                            "card",
                            cardDescriptor(view, id)
                    ));
                }
            }
            if (!message.isFlag() || raw.isEmpty()) {
                raw.add(Boolean.FALSE);
                options.add(new OptionDescriptor(
                        "Passar prioridade",
                        "delegate",
                        null
                ));
            }
            HumanVsAiSpikeHarness.Prompt prompt = promptRegistry.open(
                    callback,
                    message.getMessage(),
                    message.getOptions(),
                    raw
            );
            return new PromptBuild(
                    prompt,
                    false,
                    message.getMessage(),
                    options
            );
        }

        private PromptBuild targetPrompt(ClientCallback callback) {
            GameClientMessage message = requirePayload(
                    callback,
                    GameClientMessage.class
            );
            List<UUID> ids = new ArrayList<>();
            if (message.getTargets() != null) {
                ids.addAll(message.getTargets());
            }
            if (ids.isEmpty() && message.getCardsView1() != null) {
                ids.addAll(message.getCardsView1().keySet());
            }
            ids.sort(Comparator.comparing(UUID::toString));
            List<Object> raw = new ArrayList<>();
            List<OptionDescriptor> options = new ArrayList<>();
            for (UUID id : ids) {
                raw.add(id);
                Map<String, Object> card = cardDescriptor(
                        message.getGameView(),
                        id
                );
                options.add(new OptionDescriptor(
                        card == null
                                ? "Alvo legal"
                                : String.valueOf(card.get("name")),
                        "target",
                        card
                ));
            }
            if (!message.isFlag()) {
                raw.add(Boolean.FALSE);
                options.add(new OptionDescriptor(
                        "Cancelar seleção",
                        "cancel",
                        null
                ));
            }
            if (raw.isEmpty()) {
                throw new IllegalArgumentException(
                        "required target prompt has no target"
                );
            }
            HumanVsAiSpikeHarness.Prompt prompt = promptRegistry.open(
                    callback,
                    message.getMessage(),
                    message.getOptions(),
                    raw
            );
            return new PromptBuild(
                    prompt,
                    false,
                    message.getMessage(),
                    options
            );
        }

        private PromptBuild typedPrompt(ClientCallback callback) {
            HumanVsAiSpikeHarness.Prompt prompt =
                    promptRegistry.open(callback);
            List<OptionDescriptor> options =
                    typedDescriptors(callback, prompt);
            String message = callbackMessage(callback);
            return new PromptBuild(prompt, true, message, options);
        }

        private List<OptionDescriptor> typedDescriptors(
                ClientCallback callback,
                HumanVsAiSpikeHarness.Prompt prompt
        ) {
            List<OptionDescriptor> result = new ArrayList<>();
            switch (callback.getMethod()) {
                case GAME_CHOOSE_ABILITY:
                    AbilityPickerView picker = requirePayload(
                            callback,
                            AbilityPickerView.class
                    );
                    for (Map.Entry<UUID, String> entry
                            : picker.getChoices().entrySet()) {
                        result.add(new OptionDescriptor(
                                boundedText(entry.getValue(), 160),
                                Modes.CHOOSE_OPTION_CANCEL_ID.equals(
                                        entry.getKey()
                                ) ? "cancel" : "choice",
                                null
                        ));
                    }
                    if (result.size() < prompt.optionIds.size()) {
                        result.add(new OptionDescriptor(
                                "Cancelar",
                                "cancel",
                                null
                        ));
                    }
                    break;
                case GAME_CHOOSE_PILE:
                    result.add(new OptionDescriptor(
                            "Escolher pilha 1",
                            "choice",
                            null
                    ));
                    result.add(new OptionDescriptor(
                            "Escolher pilha 2",
                            "choice",
                            null
                    ));
                    break;
                case GAME_CHOOSE_CHOICE:
                    GameClientMessage choiceMessage = requirePayload(
                            callback,
                            GameClientMessage.class
                    );
                    List<String> values = new ArrayList<>();
                    if (choiceMessage.getChoice().isKeyChoice()) {
                        values.addAll(
                                choiceMessage
                                        .getChoice()
                                        .getKeyChoices()
                                        .keySet()
                        );
                    } else {
                        values.addAll(
                                choiceMessage.getChoice().getChoices()
                        );
                    }
                    for (String value : values) {
                        result.add(new OptionDescriptor(
                                boundedText(value, 160),
                                "choice",
                                null
                        ));
                    }
                    if (choiceMessage.getChoice().isSpecialEnabled()) {
                        for (String value : values) {
                            result.add(new OptionDescriptor(
                                    "Especial: " + boundedText(value, 140),
                                    "choice",
                                    null
                            ));
                        }
                    }
                    if (!choiceMessage.getChoice().isRequired()) {
                        result.add(new OptionDescriptor(
                                "Cancelar",
                                "cancel",
                                null
                        ));
                    }
                    break;
                case GAME_PLAY_XMANA:
                    result.add(new OptionDescriptor(
                            "Confirmar mana X",
                            "choice",
                            null
                    ));
                    result.add(new OptionDescriptor(
                            "Cancelar mana X",
                            "cancel",
                            null
                    ));
                    break;
                default:
                    break;
            }
            while (result.size() < prompt.optionIds.size()) {
                int position = result.size() + 1;
                result.add(new OptionDescriptor(
                        position == prompt.optionIds.size()
                                ? "Escolha segura do motor"
                                : "Opção legal " + position,
                        position == prompt.optionIds.size()
                                ? "delegate"
                                : "choice",
                        null
                ));
            }
            if (result.size() > prompt.optionIds.size()) {
                return new ArrayList<>(
                        result.subList(0, prompt.optionIds.size())
                );
            }
            return result;
        }

        private Map<String, Object> promptPayload(
                HumanVsAiSpikeHarness.Prompt prompt,
                List<OptionDescriptor> descriptors,
                String message,
                long deadlineMillis
        ) {
            if (descriptors.size() != prompt.optionIds.size()) {
                throw new IllegalStateException(
                        "prompt descriptors do not match opaque options"
                );
            }
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("schema_version", PROMPT_SCHEMA);
            result.put("id", prompt.promptId);
            result.put("state_version", prompt.stateVersion);
            result.put("kind", snake(prompt.kind.name()));
            result.put("input_mode", snake(prompt.inputMode.name()));
            result.put("title", promptTitle(prompt.kind));
            result.put("message", boundedText(message, 1000));
            result.put(
                    "deadline_at",
                    Instant.ofEpochMilli(deadlineMillis).toString()
            );
            List<Map<String, Object>> options = new ArrayList<>();
            for (int index = 0; index < prompt.optionIds.size(); index++) {
                OptionDescriptor descriptor = descriptors.get(index);
                Map<String, Object> option = new LinkedHashMap<>();
                option.put("id", prompt.optionIds.get(index));
                option.put("label", descriptor.label);
                option.put("role", descriptor.role);
                if (descriptor.card != null) {
                    option.put("card", descriptor.card);
                }
                options.add(option);
            }
            result.put("options", options);
            if (prompt.inputMode
                    == HumanVsAiSpikeHarness.InputMode.INTEGER) {
                result.put("minimum", prompt.minimum);
                result.put("maximum", prompt.maximum);
            }
            if (prompt.inputMode
                    == HumanVsAiSpikeHarness.InputMode.MULTI_AMOUNT) {
                result.put(
                        "multi_amount_count",
                        prompt.multiAmountCount
                );
            }
            return result;
        }

        private void recordView(GameView view) {
            if (view == null) {
                return;
            }
            synchronized (lock) {
                lastView = view;
                long fingerprint = ReplayNormalizer.fingerprint(view);
                if (!hasViewFingerprint
                        || fingerprint != lastViewFingerprint) {
                    lastViewFingerprint = fingerprint;
                    hasViewFingerprint = true;
                    synchronized (views) {
                        views.add(view);
                    }
                }
                lastActivityMillis = System.currentTimeMillis();
                lock.notifyAll();
            }
        }

        @Override
        public void onCallback(ClientCallback callback) {
            try {
                callback.decompressData();
                recordCallbackView(callback);
                switch (callback.getMethod()) {
                    case START_GAME:
                        TableClientMessage start =
                                (TableClientMessage) callback.getData();
                        gameId = start.getGameId();
                        playerId = start.getPlayerId();
                        gameStarted = true;
                        requireSession().joinGame(gameId);
                        break;
                    case GAME_INIT:
                        gameId = callback.getObjectId();
                        gameStarted = true;
                        if (callback.getData() instanceof GameView) {
                            PlayerView mine =
                                    ((GameView) callback.getData())
                                            .getMyPlayer();
                            if (mine != null) {
                                playerId = mine.getPlayerId();
                            }
                        }
                        break;
                    case GAME_ASK:
                    case GAME_SELECT:
                    case GAME_TARGET:
                    case GAME_CHOOSE_ABILITY:
                    case GAME_CHOOSE_PILE:
                    case GAME_CHOOSE_CHOICE:
                    case GAME_PLAY_MANA:
                    case GAME_PLAY_XMANA:
                    case GAME_GET_AMOUNT:
                    case GAME_GET_MULTI_AMOUNT:
                        openPrompt(callback);
                        break;
                    case END_GAME_INFO:
                        won = ((GameEndView) callback.getData()).hasWon();
                        break;
                    case GAME_OVER:
                        synchronized (lock) {
                            gameOver = true;
                            lastActivityMillis =
                                    System.currentTimeMillis();
                            lock.notifyAll();
                        }
                        break;
                    case GAME_ERROR:
                        fail(
                                "engine_error",
                                "xmage_game_error",
                                "game_error"
                        );
                        break;
                    default:
                        if (HumanVsAiSpikeHarness.DECISION_CALLBACKS.contains(
                                callback.getMethod()
                        )) {
                            throw new IllegalArgumentException(
                                    "decision callback is not handled: "
                                            + callback.getMethod()
                            );
                        }
                        break;
                }
            } catch (Throwable error) {
                fail(
                        "engine_error",
                        "interactive_callback_failed",
                        error.getClass().getSimpleName()
                );
            }
        }

        private void recordCallbackView(ClientCallback callback) {
            Object payload = callback.getData();
            if (payload instanceof GameView) {
                recordView((GameView) payload);
            } else if (payload instanceof GameClientMessage) {
                recordView(
                        ((GameClientMessage) payload).getGameView()
                );
            } else if (payload instanceof AbilityPickerView) {
                recordView(
                        ((AbilityPickerView) payload).getGameView()
                );
            }
        }

        @Override
        public MageVersion getVersion() {
            return VERSION;
        }

        @Override
        public void connected(String message) {
            if (message != null && !message.trim().isEmpty()) {
                System.err.println(
                        "XMage interactive connected: "
                                + boundedText(message, 300)
                );
            }
        }

        @Override
        public void disconnected(
                boolean askToReconnect,
                boolean keepMySessionActive
        ) {
            // SessionImpl may emit a disconnected callback while it replaces
            // its bootstrap connection. That callback is not a runtime loss.
            if (!shutdown && gameStarted && !isTerminal()) {
                fail(
                        "engine_error",
                        "interactive_runtime_disconnected",
                        "runtime_disconnected"
                );
            }
        }

        @Override
        public void showMessage(String message) {
            if (message != null && !message.trim().isEmpty()) {
                System.err.println(
                        "XMage interactive message: "
                                + boundedText(message, 500)
                );
            }
        }

        @Override
        public void showError(String message) {
            if (message != null && !message.trim().isEmpty()) {
                System.err.println(
                        "XMage interactive error: "
                                + boundedText(message, 500)
                );
            }
            fail(
                    "engine_error",
                    "interactive_client_error",
                    "client_error"
            );
        }

        @Override
        public void onNewConnection() {
        }

        boolean isTerminal() {
            return "completed".equals(status)
                    || "censored".equals(status)
                    || "conceded".equals(status)
                    || "expired".equals(status)
                    || "timeout".equals(status)
                    || "abandoned".equals(status)
                    || "engine_error".equals(status);
        }

        boolean removableAt(long now) {
            return isTerminal()
                    && terminalAtMillis > 0L
                    && now - terminalAtMillis >= TERMINAL_RETENTION_MS;
        }

        void shutdown() {
            shutdown = true;
            synchronized (lock) {
                lock.notifyAll();
            }
            Session session = remoteSession;
            if (session != null) {
                cleanup(session);
            }
        }

        private void cleanup(Session session) {
            UUID currentRoom = roomId;
            UUID currentTable = tableId;
            if (currentRoom != null && currentTable != null) {
                try {
                    session.removeTable(currentRoom, currentTable);
                } catch (Throwable ignored) {
                }
            }
            try {
                session.connectStop(false, false);
            } catch (Throwable ignored) {
            }
        }

        private Session requireSession() {
            Session session = remoteSession;
            if (session == null) {
                throw new IllegalStateException(
                        "interactive remote session is unavailable"
                );
            }
            return session;
        }

        private long stateVersion() {
            ActivePrompt prompt = activePrompt;
            if (prompt != null) {
                return prompt.prompt.stateVersion;
            }
            return Math.max(
                    lastStateVersion,
                    Math.max(
                            0L,
                            lastView == null ? 0L : lastView.getTurn()
                    )
            );
        }

        private int maxTurn() {
            GameView view = lastView;
            return view == null ? 0 : view.getTurn();
        }

        private void putReceipt(String actionId, String fingerprint) {
            if (actions.size() >= MAX_ACTION_HISTORY) {
                String first = actions.keySet().iterator().next();
                actions.remove(first);
            }
            actions.put(actionId, new ActionReceipt(fingerprint));
        }

        private static PlayerView winner(GameView view) {
            if (view == null) {
                return null;
            }
            PlayerView result = null;
            for (PlayerView player : view.getPlayers()) {
                if (!player.hasLeft() && player.getLife() > 0) {
                    if (result != null) {
                        return null;
                    }
                    result = player;
                }
            }
            return result;
        }
    }

    private interface Dispatch {
        boolean dispatch(Session session);
    }

    private static final class ActivePrompt {
        final HumanVsAiSpikeHarness.Prompt prompt;
        final boolean typed;
        final Map<String, Object> payload;
        final long deadlineAtMillis;
        final List<OptionDescriptor> descriptors;

        ActivePrompt(
                HumanVsAiSpikeHarness.Prompt prompt,
                boolean typed,
                Map<String, Object> payload,
                long deadlineAtMillis,
                List<OptionDescriptor> descriptors
        ) {
            this.prompt = prompt;
            this.typed = typed;
            this.payload = payload;
            this.deadlineAtMillis = deadlineAtMillis;
            this.descriptors = Collections.unmodifiableList(
                    new ArrayList<>(descriptors)
            );
        }

        String safeOptionId() {
            String[] roles = {"delegate", "keep", "cancel"};
            for (String role : roles) {
                for (int index = 0; index < descriptors.size(); index++) {
                    if (role.equals(descriptors.get(index).role)) {
                        return prompt.optionIds.get(index);
                    }
                }
            }
            if (!prompt.optionIds.isEmpty()) {
                return prompt.optionIds.get(0);
            }
            throw new ConflictException("prompt_has_no_safe_response");
        }
    }

    private static final class PromptBuild {
        final HumanVsAiSpikeHarness.Prompt prompt;
        final boolean typed;
        final String message;
        final List<OptionDescriptor> descriptors;

        PromptBuild(
                HumanVsAiSpikeHarness.Prompt prompt,
                boolean typed,
                String message,
                List<OptionDescriptor> descriptors
        ) {
            this.prompt = prompt;
            this.typed = typed;
            this.message = message;
            this.descriptors = descriptors;
        }
    }

    private static final class OptionDescriptor {
        final String label;
        final String role;
        final Map<String, Object> card;

        OptionDescriptor(
                String label,
                String role,
                Map<String, Object> card
        ) {
            this.label = bounded(label, 160);
            this.role = role;
            this.card = card;
        }
    }

    private static final class ActionReceipt {
        final String fingerprint;

        ActionReceipt(String fingerprint) {
            this.fingerprint = fingerprint;
        }
    }

    private static final class SessionRequest {
        final String requestId;
        final String requestHash;
        final int ttlSeconds;
        final int promptTimeoutSeconds;
        final int maxTurns;
        final XmageBattleService.DeckInput deckA;
        final XmageBattleService.DeckInput deckB;

        SessionRequest(
                String requestId,
                String requestHash,
                int ttlSeconds,
                int promptTimeoutSeconds,
                int maxTurns,
                XmageBattleService.DeckInput deckA,
                XmageBattleService.DeckInput deckB
        ) {
            this.requestId = requestId;
            this.requestHash = requestHash;
            this.ttlSeconds = ttlSeconds;
            this.promptTimeoutSeconds = promptTimeoutSeconds;
            this.maxTurns = maxTurns;
            this.deckA = deckA;
            this.deckB = deckB;
        }

        static SessionRequest parse(JsonObject input) {
            if (!REQUEST_SCHEMA.equals(
                    requiredString(input, "schema_version", 64)
            )) {
                throw new IllegalArgumentException(
                        "interactive schema_version is invalid"
                );
            }
            String requestId = requiredString(
                    input,
                    "request_id",
                    80
            );
            if (!requestId.matches("^[A-Za-z0-9_-]{1,80}$")) {
                throw new IllegalArgumentException(
                        "interactive request_id is invalid"
                );
            }
            String requestHash = requiredString(
                    input,
                    "request_hash",
                    64
            ).toLowerCase();
            if (!requestHash.matches("^[0-9a-f]{64}$")) {
                throw new IllegalArgumentException(
                        "interactive request_hash is invalid"
                );
            }
            if (!"xmage".equals(
                    requiredString(input, "expected_engine", 32)
            )
                    || !SidecarMain.XMAGE_VERSION.equals(
                    requiredString(
                            input,
                            "expected_engine_version",
                            64
                    )
            )
                    || !SidecarMain.XMAGE_COMMIT.equals(
                    requiredString(
                            input,
                            "expected_engine_commit",
                            64
                    )
            )) {
                throw new IllegalArgumentException(
                        "interactive engine identity is invalid"
                );
            }
            int ttlSeconds = (int) requiredLong(
                    input,
                    "ttl_seconds",
                    60,
                    7200
            );
            int promptTimeoutSeconds = (int) requiredLong(
                    input,
                    "prompt_timeout_seconds",
                    15,
                    300
            );
            int maxTurns = (int) requiredLong(
                    input,
                    "max_turns",
                    1,
                    100
            );
            XmageBattleService.DeckInput deckA =
                    XmageBattleService.DeckInput.parse(
                            XmageBattleService.requireObject(
                                    input,
                                    "deck_a"
                            ),
                            "deck_a"
                    );
            XmageBattleService.DeckInput deckB =
                    XmageBattleService.DeckInput.parse(
                            XmageBattleService.requireObject(
                                    input,
                                    "deck_b"
                            ),
                            "deck_b"
                    );
            JsonObject hashes = XmageBattleService.requireObject(
                    input,
                    "deck_hashes"
            );
            if (!SidecarMain.DECK_HASH_SCHEMA.equals(
                    requiredString(hashes, "schema_version", 64)
            )) {
                throw new IllegalArgumentException(
                        "interactive deck hash schema is invalid"
                );
            }
            String deckAHash = requiredString(
                    hashes,
                    "deck_a",
                    64
            );
            String deckBHash = requiredString(
                    hashes,
                    "deck_b",
                    64
            );
            if (!deckAHash.matches("^[0-9a-f]{64}$")
                    || !deckBHash.matches("^[0-9a-f]{64}$")) {
                throw new IllegalArgumentException(
                        "interactive deck hash is invalid"
                );
            }
            if (!deckAHash.equals(
                    XmageBattleService.canonicalDeckHash(deckA)
            )
                    || !deckBHash.equals(
                    XmageBattleService.canonicalDeckHash(deckB)
            )) {
                throw new IllegalArgumentException(
                        "interactive deck hash does not match deck payload"
                );
            }
            return new SessionRequest(
                    requestId,
                    requestHash,
                    ttlSeconds,
                    promptTimeoutSeconds,
                    maxTurns,
                    deckA,
                    deckB
            );
        }
    }

    private static List<OptionDescriptor> genericDescriptors(int count) {
        List<OptionDescriptor> result = new ArrayList<>();
        for (int index = 0; index < count; index++) {
            result.add(new OptionDescriptor(
                    "Opção legal " + (index + 1),
                    "choice",
                    null
            ));
        }
        return result;
    }

    private static String callbackMessage(ClientCallback callback) {
        Object payload = callback.getData();
        if (payload instanceof GameClientMessage) {
            return ((GameClientMessage) payload).getMessage();
        }
        if (payload instanceof AbilityPickerView) {
            return ((AbilityPickerView) payload).getMessage();
        }
        return callback.getMethod().name();
    }

    private static String playableLabel(
            GameView view,
            UUID id,
            PlayableObjectStats stats
    ) {
        Map<String, Object> card = cardDescriptor(view, id);
        String name =
                card == null
                        ? "Ação legal"
                        : String.valueOf(card.get("name"));
        List<String> abilities =
                stats == null
                        ? Collections.emptyList()
                        : stats.getPlayableAbilityNames();
        if (abilities == null || abilities.isEmpty()) {
            return bounded(name, 160);
        }
        return bounded(
                name + " — " + abilities.get(0),
                160
        );
    }

    private static Map<String, Object> cardDescriptor(
            GameView view,
            UUID id
    ) {
        CardView card = findCard(view, id);
        if (card == null) {
            return null;
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("name", bounded(card.getName(), 160));
        if (card.getExpansionSetCode() != null
                && !card.getExpansionSetCode().trim().isEmpty()) {
            result.put(
                    "set_code",
                    bounded(card.getExpansionSetCode(), 16)
            );
        }
        if (card.getCardNumber() != null
                && !card.getCardNumber().trim().isEmpty()) {
            result.put(
                    "collector_number",
                    bounded(card.getCardNumber(), 32)
            );
        }
        return result;
    }

    private static CardView findCard(GameView view, UUID id) {
        if (view == null || id == null) {
            return null;
        }
        List<CardsView> zones = new ArrayList<>();
        zones.add(view.getMyHand());
        zones.add(view.getStack());
        PlayerView mine = view.getMyPlayer();
        if (mine != null) {
            zones.add(mine.getGraveyard());
            zones.add(mine.getExile());
            CardsView battlefield = new CardsView();
            battlefield.putAll(mine.getBattlefield());
            zones.add(battlefield);
        }
        for (CardsView zone : zones) {
            if (zone != null && zone.get(id) != null) {
                return zone.get(id);
            }
        }
        return null;
    }

    private static String promptTitle(
            HumanVsAiSpikeHarness.PromptKind kind
    ) {
        switch (kind) {
            case MULLIGAN:
                return "Mão inicial";
            case MAIN_ACTION:
                return "Sua prioridade";
            case TARGET:
                return "Escolha um alvo";
            case COMBAT:
                return "Decisão de combate";
            case ABILITY:
                return "Escolha uma habilidade";
            case PILE:
                return "Escolha uma pilha";
            case CHOICE:
                return "Faça uma escolha";
            case MANA:
                return "Produza mana";
            case X_MANA:
                return "Defina o mana X";
            case AMOUNT:
                return "Escolha uma quantidade";
            case MULTI_AMOUNT:
                return "Distribua as quantidades";
            default:
                return "Sua decisão";
        }
    }

    private static void requireActionSchema(JsonObject input) {
        if (!ACTION_SCHEMA.equals(
                requiredString(input, "schema_version", 64)
        )) {
            throw new IllegalArgumentException(
                    "interactive action schema is invalid"
            );
        }
    }

    private static <T> T requirePayload(
            ClientCallback callback,
            Class<T> type
    ) {
        Object payload = callback.getData();
        if (!type.isInstance(payload)) {
            throw new IllegalArgumentException(
                    "callback payload must be " + type.getSimpleName()
            );
        }
        return type.cast(payload);
    }

    private static String requiredString(
            JsonObject input,
            String key,
            int maximum
    ) {
        if (input == null
                || !input.has(key)
                || input.get(key).isJsonNull()
                || !input.get(key).isJsonPrimitive()
                || !input.get(key).getAsJsonPrimitive().isString()) {
            throw new IllegalArgumentException(key + " is required");
        }
        String value = input.get(key).getAsString().trim();
        if (value.isEmpty() || value.length() > maximum) {
            throw new IllegalArgumentException(key + " is invalid");
        }
        return value;
    }

    private static long requiredLong(
            JsonObject input,
            String key,
            long minimum,
            long maximum
    ) {
        if (input == null
                || !input.has(key)
                || input.get(key).isJsonNull()
                || !input.get(key).isJsonPrimitive()
                || !input.get(key).getAsJsonPrimitive().isNumber()) {
            throw new IllegalArgumentException(key + " is required");
        }
        long value = input.get(key).getAsLong();
        if (value < minimum || value > maximum) {
            throw new IllegalArgumentException(key + " is invalid");
        }
        return value;
    }

    private static String runtimeId() {
        return "ibsrt_" + UUID.randomUUID().toString().replace("-", "");
    }

    private static byte[] promptSecret() {
        try {
            return MessageDigest.getInstance("SHA-256").digest(
                    UUID.randomUUID()
                            .toString()
                            .getBytes(StandardCharsets.UTF_8)
            );
        } catch (Exception error) {
            throw new IllegalStateException(
                    "SHA-256 is unavailable",
                    error
            );
        }
    }

    private static String sha256(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(
                    value.getBytes(StandardCharsets.UTF_8)
            );
            StringBuilder result = new StringBuilder();
            for (byte entry : digest) {
                result.append(String.format("%02x", entry & 0xff));
            }
            return result.toString();
        } catch (Exception error) {
            throw new IllegalStateException(
                    "SHA-256 is unavailable",
                    error
            );
        }
    }

    private static String boundedText(String value, int maximum) {
        String plain = Jsoup.parse(
                value == null ? "" : value
        ).text().trim();
        if (plain.isEmpty()) {
            return "Escolha uma opção legal.";
        }
        return bounded(plain, maximum);
    }

    private static String bounded(String value, int maximum) {
        String safe = value == null ? "" : value.trim();
        return safe.length() <= maximum
                ? safe
                : safe.substring(0, maximum);
    }

    private static String snake(String value) {
        return value.toLowerCase(java.util.Locale.ROOT);
    }
}
