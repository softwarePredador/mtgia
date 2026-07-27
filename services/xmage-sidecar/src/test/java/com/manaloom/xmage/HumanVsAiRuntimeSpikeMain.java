package com.manaloom.xmage;

import com.google.gson.Gson;
import mage.cards.decks.DeckCardInfo;
import mage.cards.decks.DeckCardLists;
import mage.cards.repository.CardInfo;
import mage.cards.repository.CardRepository;
import mage.cards.repository.CardScanner;
import mage.constants.MatchTimeLimit;
import mage.constants.MultiplayerAttackOption;
import mage.constants.PlayerAction;
import mage.constants.RangeOfInfluence;
import mage.constants.TableState;
import mage.game.match.MatchOptions;
import mage.interfaces.MageClient;
import mage.interfaces.callback.ClientCallback;
import mage.interfaces.callback.ClientCallbackMethod;
import mage.remote.Connection;
import mage.remote.Session;
import mage.remote.SessionImpl;
import mage.utils.MageVersion;
import mage.view.AbilityPickerView;
import mage.view.GameClientMessage;
import mage.view.GameEndView;
import mage.view.GameTypeView;
import mage.view.GameView;
import mage.view.PlayerView;
import mage.view.SimpleCardView;
import mage.view.SimpleCardsView;
import mage.view.TableClientMessage;
import mage.view.TableView;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * BL7 test-only runtime probe. This class is intentionally kept under
 * src/test and is not reachable from the sidecar HTTP surface.
 */
public final class HumanVsAiRuntimeSpikeMain {
    private static final String GAME_TYPE =
            "Freeform Commander Free For All";
    private static final String DECK_TYPE =
            "Variant Magic - Freeform Commander";
    private static final long DEFAULT_TIMEOUT_MS = 180_000L;
    private static final long DEFAULT_IDLE_TIMEOUT_MS = 20_000L;
    private static final long TERMINATION_GRACE_MS = 10_000L;

    private HumanVsAiRuntimeSpikeMain() {
    }

    public static void main(String[] arguments) throws Exception {
        RuntimeConfig config = RuntimeConfig.parse(arguments);
        RuntimeProbe probe = new RuntimeProbe(config);
        Map<String, Object> result = probe.run();
        String json = new Gson().toJson(result);
        System.out.println("BL7_RUNTIME_RESULT=" + json);
        System.out.println(
                "BL7_RUNTIME_HUMAN_MATCH_COMPLETED="
                        + result.get("completed_human_match")
        );
        System.out.println(
                "BL7_RUNTIME_HIDDEN_INFORMATION_LEAK="
                        + result.get("hidden_information_leak")
        );
        System.out.println(
                "BL7_RUNTIME_DEADLOCKS=" + result.get("deadlocks")
        );
        System.out.println(
                "BL7_RUNTIME_SPIKE_STATUS=" + result.get("runtime_status")
        );
        if (!"PASS".equals(result.get("runtime_status"))) {
            System.exit(1);
        }
        System.exit(0);
    }

    private static final class RuntimeProbe {
        private final RuntimeConfig config;
        private final RuntimeMageClient client;

        RuntimeProbe(RuntimeConfig config) {
            this.config = config;
            this.client = new RuntimeMageClient();
        }

        Map<String, Object> run() {
            long startedAt = System.currentTimeMillis();
            long matchStartedAt = 0L;
            Session session = new SessionImpl(client);
            UUID roomId = null;
            UUID tableId = null;
            boolean hardTimeout = false;
            boolean idleTimeout = false;
            boolean concedeAttempted = false;
            boolean concedeAccepted = false;
            long gameStartRequestedAt = 0L;

            try {
                Connection connection = new Connection();
                connection.setUsername(config.username);
                connection.setHost(config.host);
                connection.setPort(config.port);
                connection.setProxyType(Connection.ProxyType.NONE);
                client.setSession(session);
                boolean connectAccepted = session.connectStart(connection);
                long connectionDeadline = System.currentTimeMillis() + 2_000L;
                while (connectAccepted
                        && (!session.isConnected()
                        || !Boolean.TRUE.equals(session.isServerReady()))
                        && System.currentTimeMillis() < connectionDeadline) {
                    Thread.sleep(25L);
                }
                if (!session.isConnected()
                        || !Boolean.TRUE.equals(session.isServerReady())) {
                    throw new IllegalStateException(
                            "XMage server connection is not ready"
                                    + "; connectAccepted=" + connectAccepted
                                    + "; lastError="
                                    + String.valueOf(session.getLastError())
                    );
                }

                roomId = session.getMainRoomId();
                GameTypeView gameType = session.getGameTypes().stream()
                        .filter(type -> GAME_TYPE.equals(type.getName()))
                        .findFirst()
                        .orElseThrow(() -> new IllegalStateException(
                                "XMage game type is unavailable: " + GAME_TYPE
                        ));
                if (!Arrays.asList(session.getDeckTypes()).contains(DECK_TYPE)) {
                    throw new IllegalStateException(
                            "XMage deck type is unavailable: " + DECK_TYPE
                    );
                }

                CardScanner.scan();
                DeckCardLists humanDeck;
                DeckCardLists aiDeck;
                try {
                    humanDeck = deck(
                            "BL7 Isamaru passive",
                            "Isamaru, Hound of Konda",
                            "Plains"
                    );
                    aiDeck = deck(
                            "BL7 Krenko pressure",
                            "Krenko, Mob Boss",
                            "Mountain"
                    );
                } finally {
                    CardRepository.instance.closeDB(false);
                }

                MatchOptions options = HumanVsAiSpikeHarness.matchOptions(
                        "BL7 runtime " + config.runId,
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
                            "XMage did not create the runtime table"
                    );
                }
                tableId = table.getTableId();
                HumanVsAiSpikeHarness.joinSeats(
                        session,
                        roomId,
                        tableId,
                        humanDeck,
                        aiDeck
                );
                if (!session.startMatch(roomId, tableId)) {
                    throw new IllegalStateException(
                            "XMage did not start the runtime match"
                    );
                }
                gameStartRequestedAt = System.currentTimeMillis();

                while (!client.isGameOver() && client.getFatalError() == null) {
                    long now = System.currentTimeMillis();
                    if (matchStartedAt == 0L && client.hasStarted()) {
                        matchStartedAt = now;
                    }
                    if (matchStartedAt > 0L
                            && now - matchStartedAt >= config.timeoutMs) {
                        hardTimeout = true;
                        break;
                    }
                    if (matchStartedAt == 0L
                            && now - gameStartRequestedAt >= 30_000L) {
                        idleTimeout = true;
                        break;
                    }
                    if (client.hasStarted()
                            && client.idleMillis() >= config.idleTimeoutMs) {
                        idleTimeout = true;
                        break;
                    }
                    Optional<TableView> current =
                            session.getTable(roomId, tableId);
                    if (current.isPresent()
                            && current.get().getTableState()
                            == TableState.FINISHED
                            && client.hasStarted()) {
                        client.markTableFinished();
                    }
                    Thread.sleep(25L);
                }

                if (!client.isGameOver()) {
                    concedeAttempted = client.getGameId() != null;
                    if (concedeAttempted) {
                        concedeAccepted = session.sendPlayerAction(
                                PlayerAction.CONCEDE,
                                client.getGameId(),
                                null
                        );
                    }
                    long graceDeadline =
                            System.currentTimeMillis() + TERMINATION_GRACE_MS;
                    while (!client.isGameOver()
                            && System.currentTimeMillis() < graceDeadline) {
                        Thread.sleep(25L);
                    }
                }
            } catch (Throwable error) {
                client.fail(error);
            } finally {
                try {
                    session.connectStop(false, false);
                } catch (Throwable ignored) {
                    // The isolated process is terminal after this report.
                }
            }

            return client.report(
                    config,
                    System.currentTimeMillis() - startedAt,
                    matchStartedAt == 0L
                            ? 0L
                            : System.currentTimeMillis() - matchStartedAt,
                    hardTimeout,
                    idleTimeout,
                    concedeAttempted,
                    concedeAccepted,
                    roomId,
                    tableId
            );
        }

        private static DeckCardLists deck(
                String name,
                String commanderName,
                String basicLandName
        ) {
            CardInfo commander = requireCard(commanderName);
            CardInfo basicLand = requireCard(basicLandName);
            DeckCardLists deck = new DeckCardLists();
            deck.setName(name);
            deck.getSideboard().add(deckCard(commander, 1));
            deck.getCards().add(deckCard(basicLand, 99));
            return deck;
        }

        private static CardInfo requireCard(String name) {
            CardInfo card = CardRepository.instance.findCard(name);
            if (card == null) {
                throw new IllegalStateException(
                        "XMage card is unavailable: " + name
                );
            }
            return card;
        }

        private static DeckCardInfo deckCard(CardInfo card, int amount) {
            return new DeckCardInfo(
                    card.getName(),
                    card.getCardNumber(),
                    card.getSetCode(),
                    amount
            );
        }
    }

    private static final class RuntimeMageClient implements MageClient {
        private static final MageVersion VERSION =
                new MageVersion(MageClient.class);
        private static final Set<ClientCallbackMethod> VIEW_CALLBACKS =
                Collections.unmodifiableSet(new LinkedHashSet<>(
                        Arrays.asList(
                                ClientCallbackMethod.GAME_INIT,
                                ClientCallbackMethod.GAME_UPDATE,
                                ClientCallbackMethod.GAME_UPDATE_AND_INFORM,
                                ClientCallbackMethod.GAME_INFORM_PERSONAL,
                                ClientCallbackMethod.GAME_ASK,
                                ClientCallbackMethod.GAME_SELECT,
                                ClientCallbackMethod.GAME_TARGET,
                                ClientCallbackMethod.GAME_CHOOSE_PILE,
                                ClientCallbackMethod.GAME_CHOOSE_CHOICE,
                                ClientCallbackMethod.GAME_PLAY_MANA,
                                ClientCallbackMethod.GAME_PLAY_XMANA,
                                ClientCallbackMethod.GAME_GET_AMOUNT,
                                ClientCallbackMethod.GAME_GET_MULTI_AMOUNT,
                                ClientCallbackMethod.GAME_OVER
                        )
                ));

        private final HumanVsAiSpikeHarness.PromptRegistry promptRegistry;
        private final Map<ClientCallbackMethod, Integer> callbackCounts =
                new EnumMap<>(ClientCallbackMethod.class);
        private final Map<HumanVsAiSpikeHarness.PromptKind, Integer>
                promptCounts =
                new EnumMap<>(HumanVsAiSpikeHarness.PromptKind.class);
        private final List<Long> responseLatenciesMicros = new ArrayList<>();
        private volatile Session session;
        private volatile UUID gameId;
        private volatile UUID playerId;
        private volatile boolean started;
        private volatile boolean gameOver;
        private volatile boolean tableFinished;
        private volatile boolean won;
        private volatile String fatalError;
        private volatile String serverNotice;
        private volatile long lastCallbackAt = System.currentTimeMillis();
        private int decisionCallbacks;
        private int acceptedResponses;
        private int rejectedResponses;
        private int viewCount;
        private int maxTurn;
        private long peakHeapBytes;
        private int opponentHandObjects;
        private int opponentIdentifiableHandObjects;
        private int playerIdentityMismatches;

        RuntimeMageClient() {
            this.promptRegistry =
                    new HumanVsAiSpikeHarness.PromptRegistry(promptSecret());
        }

        void setSession(Session session) {
            this.session = session;
        }

        boolean hasStarted() {
            return started;
        }

        boolean isGameOver() {
            return gameOver;
        }

        UUID getGameId() {
            return gameId;
        }

        String getFatalError() {
            return fatalError;
        }

        long idleMillis() {
            return System.currentTimeMillis() - lastCallbackAt;
        }

        void markTableFinished() {
            tableFinished = true;
        }

        synchronized void fail(Throwable error) {
            if (fatalError == null) {
                fatalError = error.getClass().getSimpleName()
                        + ": " + String.valueOf(error.getMessage());
            }
        }

        @Override
        public MageVersion getVersion() {
            return VERSION;
        }

        @Override
        public void connected(String message) {
        }

        @Override
        public void disconnected(
                boolean askToReconnect,
                boolean keepMySessionActive
        ) {
        }

        @Override
        public void showMessage(String message) {
        }

        @Override
        public void showError(String message) {
            fail(new IllegalStateException("XMage client error: " + message));
        }

        @Override
        public void onNewConnection() {
        }

        @Override
        public synchronized void onCallback(ClientCallback callback) {
            lastCallbackAt = System.currentTimeMillis();
            sampleHeap();
            try {
                callback.decompressData();
                increment(callbackCounts, callback.getMethod());
                if (VIEW_CALLBACKS.contains(callback.getMethod())) {
                    recordCallbackView(callback);
                }

                switch (callback.getMethod()) {
                    case START_GAME:
                        TableClientMessage start =
                                (TableClientMessage) callback.getData();
                        gameId = start.getGameId();
                        playerId = start.getPlayerId();
                        started = true;
                        requireSession().joinGame(gameId);
                        break;
                    case GAME_INIT:
                        gameId = callback.getObjectId();
                        started = true;
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
                        respondQuestion(callback);
                        break;
                    case GAME_SELECT:
                        respondDone(callback);
                        break;
                    case GAME_TARGET:
                        respondTarget(callback);
                        break;
                    case GAME_CHOOSE_ABILITY:
                    case GAME_CHOOSE_PILE:
                    case GAME_CHOOSE_CHOICE:
                    case GAME_PLAY_MANA:
                    case GAME_PLAY_XMANA:
                    case GAME_GET_AMOUNT:
                    case GAME_GET_MULTI_AMOUNT:
                        respondTyped(callback);
                        break;
                    case END_GAME_INFO:
                        won = ((GameEndView) callback.getData()).hasWon();
                        break;
                    case GAME_OVER:
                        gameOver = true;
                        break;
                    case GAME_ERROR:
                        fail(new IllegalStateException(
                                "XMage GAME_ERROR: "
                                        + String.valueOf(callback.getData())
                        ));
                        break;
                    case SHOW_USERMESSAGE:
                        serverNotice = String.valueOf(callback.getData());
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
                fail(error);
            }
        }

        private void respondQuestion(ClientCallback callback) {
            GameClientMessage message =
                    requirePayload(callback, GameClientMessage.class);
            HumanVsAiSpikeHarness.Prompt prompt = promptRegistry.open(
                    callback,
                    message.getMessage(),
                    message.getOptions(),
                    Arrays.asList(Boolean.TRUE, Boolean.FALSE)
            );
            recordPrompt(prompt);
            Object response = promptRegistry.resolve(
                    prompt.promptId,
                    prompt.stateVersion,
                    prompt.optionIds.get(1)
            );
            dispatchLegacy(prompt.gameId, response);
        }

        private void respondDone(ClientCallback callback) {
            GameClientMessage message =
                    requirePayload(callback, GameClientMessage.class);
            HumanVsAiSpikeHarness.Prompt prompt = promptRegistry.open(
                    callback,
                    message.getMessage(),
                    message.getOptions(),
                    Collections.singletonList(Boolean.FALSE)
            );
            recordPrompt(prompt);
            Object response = promptRegistry.resolve(
                    prompt.promptId,
                    prompt.stateVersion,
                    prompt.optionIds.get(0)
            );
            dispatchLegacy(prompt.gameId, response);
        }

        private void respondTarget(ClientCallback callback) {
            GameClientMessage message =
                    requirePayload(callback, GameClientMessage.class);
            List<UUID> serverTargets = new ArrayList<>();
            if (message.getTargets() != null) {
                serverTargets.addAll(message.getTargets());
            }
            if (serverTargets.isEmpty() && message.getCardsView1() != null) {
                serverTargets.addAll(message.getCardsView1().keySet());
            }
            serverTargets.sort((left, right) ->
                    left.toString().compareTo(right.toString()));

            List<Object> safeOptions = new ArrayList<>();
            safeOptions.addAll(serverTargets);
            if (!message.isFlag()) {
                safeOptions.add(Boolean.FALSE);
            }
            if (safeOptions.isEmpty()) {
                throw new IllegalArgumentException(
                        "required target callback has no server target"
                );
            }

            HumanVsAiSpikeHarness.Prompt prompt = promptRegistry.open(
                    callback,
                    message.getMessage(),
                    message.getOptions(),
                    safeOptions
            );
            recordPrompt(prompt);
            int selectedIndex = message.isFlag()
                    ? 0
                    : prompt.optionIds.size() - 1;
            Object response = promptRegistry.resolve(
                    prompt.promptId,
                    prompt.stateVersion,
                    prompt.optionIds.get(selectedIndex)
            );
            dispatchLegacy(prompt.gameId, response);
        }

        private void respondTyped(ClientCallback callback) {
            HumanVsAiSpikeHarness.Prompt prompt =
                    promptRegistry.open(callback);
            recordPrompt(prompt);
            HumanVsAiSpikeHarness.ResolvedResponse response;
            switch (prompt.inputMode) {
                case INTEGER:
                    response = promptRegistry.resolveInteger(
                            prompt.promptId,
                            prompt.stateVersion,
                            prompt.minimum
                    );
                    break;
                case MULTI_AMOUNT:
                    if (!prompt.optionIds.isEmpty()) {
                        response = promptRegistry.resolveResponse(
                                prompt.promptId,
                                prompt.stateVersion,
                                prompt.optionIds.get(
                                        prompt.optionIds.size() - 1
                                )
                        );
                    } else {
                        response =
                                promptRegistry.resolveMinimumMultiAmount(
                                        prompt.promptId,
                                        prompt.stateVersion
                                );
                    }
                    break;
                case OPTIONS:
                    int selectedIndex = typedOptionIndex(callback, prompt);
                    response = promptRegistry.resolveResponse(
                            prompt.promptId,
                            prompt.stateVersion,
                            prompt.optionIds.get(selectedIndex)
                    );
                    break;
                default:
                    throw new IllegalStateException(
                            "unsupported prompt input mode"
                    );
            }
            dispatch(response);
        }

        private static int typedOptionIndex(
                ClientCallback callback,
                HumanVsAiSpikeHarness.Prompt prompt
        ) {
            if (prompt.optionIds.isEmpty()) {
                throw new IllegalArgumentException(
                        "typed options prompt has no options"
                );
            }
            if (prompt.kind == HumanVsAiSpikeHarness.PromptKind.CHOICE) {
                GameClientMessage message =
                        requirePayload(callback, GameClientMessage.class);
                if (message.getChoice() != null
                        && message.getChoice().isRequired()) {
                    return 0;
                }
            }
            return prompt.optionIds.size() - 1;
        }

        private void dispatchLegacy(UUID targetGameId, Object response) {
            long startedAt = System.nanoTime();
            boolean accepted;
            if (response instanceof Boolean) {
                accepted = requireSession().sendPlayerBoolean(
                        targetGameId,
                        (Boolean) response
                );
            } else if (response instanceof UUID) {
                accepted = requireSession().sendPlayerUUID(
                        targetGameId,
                        (UUID) response
                );
            } else {
                throw new IllegalArgumentException(
                        "legacy response type is not allowlisted"
                );
            }
            recordResponse(startedAt, accepted);
        }

        private void dispatch(
                HumanVsAiSpikeHarness.ResolvedResponse response
        ) {
            long startedAt = System.nanoTime();
            boolean accepted = response.dispatch(requireSession());
            recordResponse(startedAt, accepted);
        }

        private void recordResponse(long startedAt, boolean accepted) {
            responseLatenciesMicros.add(
                    Math.max(0L, (System.nanoTime() - startedAt) / 1_000L)
            );
            if (accepted) {
                acceptedResponses++;
            } else {
                rejectedResponses++;
                throw new IllegalStateException(
                        "XMage rejected an allowlisted response"
                );
            }
        }

        private void recordPrompt(
                HumanVsAiSpikeHarness.Prompt prompt
        ) {
            decisionCallbacks++;
            increment(promptCounts, prompt.kind);
            if (!prompt.promptId.startsWith("p_")) {
                throw new IllegalStateException("prompt id is not opaque");
            }
            for (String optionId : prompt.optionIds) {
                if (!optionId.startsWith("o_")
                        || optionId.contains(prompt.gameId.toString())) {
                    throw new IllegalStateException(
                            "response option id is not opaque"
                    );
                }
            }
        }

        private void recordCallbackView(ClientCallback callback) {
            Object payload = callback.getData();
            GameView view = null;
            if (payload instanceof GameView) {
                view = (GameView) payload;
            } else if (payload instanceof GameClientMessage) {
                view = ((GameClientMessage) payload).getGameView();
            } else if (payload instanceof AbilityPickerView) {
                view = ((AbilityPickerView) payload).getGameView();
            }
            recordView(view);
        }

        private void recordView(GameView view) {
            if (view == null) {
                return;
            }
            viewCount++;
            maxTurn = Math.max(maxTurn, view.getTurn());
            if (view.isPlayer() && playerId != null) {
                PlayerView mine = view.getMyPlayer();
                if (mine == null || !playerId.equals(mine.getPlayerId())) {
                    playerIdentityMismatches++;
                }
            }
            if (view.getOpponentHands() != null) {
                for (SimpleCardsView hand
                        : view.getOpponentHands().values()) {
                    if (hand == null) {
                        continue;
                    }
                    opponentHandObjects += hand.size();
                    for (SimpleCardView card : hand.values()) {
                        if (card != null
                                && notBlank(card.getExpansionSetCode())
                                && notBlank(card.getCardNumber())) {
                            opponentIdentifiableHandObjects++;
                        }
                    }
                }
            }
            sampleHeap();
        }

        synchronized Map<String, Object> report(
                RuntimeConfig config,
                long elapsedMs,
                long matchElapsedMs,
                boolean hardTimeout,
                boolean idleTimeout,
                boolean concedeAttempted,
                boolean concedeAccepted,
                UUID roomId,
                UUID tableId
        ) {
            sampleHeap();
            boolean hiddenLeak = opponentIdentifiableHandObjects > 0
                    || playerIdentityMismatches > 0;
            int deadlocks = idleTimeout ? 1 : 0;
            boolean completed = gameOver;
            boolean baseSafetyPass = completed
                    && deadlocks == 0
                    && !hiddenLeak
                    && rejectedResponses == 0
                    && fatalError == null;
            boolean runtimePass = config.expectTimeout
                    ? baseSafetyPass
                            && hardTimeout
                            && concedeAttempted
                            && concedeAccepted
                    : baseSafetyPass
                            && !hardTimeout
                            && !concedeAttempted;

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("runtime_status", runtimePass ? "PASS" : "FAIL");
            result.put("scope", "isolated_test_only");
            result.put(
                    "scenario",
                    config.expectTimeout
                            ? "expected_timeout_termination"
                            : "normal_completion"
            );
            result.put("run_id", config.runId);
            result.put("server", config.host + ":" + config.port);
            result.put("completed_human_match", completed);
            result.put("normal_completion", completed && !concedeAttempted);
            result.put("won", won);
            result.put("table_finished_observed", tableFinished);
            result.put("hard_timeout", hardTimeout);
            result.put("idle_timeout", idleTimeout);
            result.put("deadlocks", deadlocks);
            result.put("concede_attempted", concedeAttempted);
            result.put("concede_accepted", concedeAccepted);
            result.put("hidden_information_leak", hiddenLeak);
            result.put(
                    "opponent_hand_objects_observed",
                    opponentHandObjects
            );
            result.put(
                    "opponent_identifiable_hand_objects",
                    opponentIdentifiableHandObjects
            );
            result.put(
                    "player_identity_mismatches",
                    playerIdentityMismatches
            );
            result.put("elapsed_ms", elapsedMs);
            result.put("match_elapsed_ms", matchElapsedMs);
            result.put("views", viewCount);
            result.put("max_turn", maxTurn);
            result.put("decision_callbacks", decisionCallbacks);
            result.put("accepted_responses", acceptedResponses);
            result.put("rejected_responses", rejectedResponses);
            result.put(
                    "callback_counts",
                    enumCounts(callbackCounts)
            );
            result.put("prompt_counts", enumCounts(promptCounts));
            result.put(
                    "response_latency_p95_us",
                    percentile(responseLatenciesMicros, 95)
            );
            result.put(
                    "response_latency_max_us",
                    percentile(responseLatenciesMicros, 100)
            );
            result.put("client_peak_heap_bytes", peakHeapBytes);
            result.put("fatal_error", fatalError);
            result.put("server_notice", serverNotice);
            result.put("game_id_hash", hashUuid(gameId));
            result.put("room_id_hash", hashUuid(roomId));
            result.put("table_id_hash", hashUuid(tableId));
            return result;
        }

        private Session requireSession() {
            if (session == null) {
                throw new IllegalStateException("runtime session is missing");
            }
            return session;
        }

        private void sampleHeap() {
            Runtime runtime = Runtime.getRuntime();
            long used = runtime.totalMemory() - runtime.freeMemory();
            peakHeapBytes = Math.max(peakHeapBytes, used);
        }

        private static byte[] promptSecret() {
            try {
                return MessageDigest.getInstance("SHA-256").digest(
                        UUID.randomUUID().toString()
                                .getBytes(StandardCharsets.UTF_8)
                );
            } catch (Exception error) {
                throw new IllegalStateException(
                        "SHA-256 is unavailable",
                        error
                );
            }
        }

        private static <K> void increment(Map<K, Integer> counts, K key) {
            counts.put(key, counts.getOrDefault(key, 0) + 1);
        }

        private static Map<String, Integer> enumCounts(
                Map<?, Integer> counts
        ) {
            Map<String, Integer> result = new LinkedHashMap<>();
            for (Map.Entry<?, Integer> entry : counts.entrySet()) {
                result.put(entry.getKey().toString(), entry.getValue());
            }
            return result;
        }

        private static long percentile(List<Long> values, int percentile) {
            if (values.isEmpty()) {
                return 0L;
            }
            List<Long> sorted = new ArrayList<>(values);
            Collections.sort(sorted);
            int index = (int) Math.ceil(
                    (percentile / 100.0d) * sorted.size()
            ) - 1;
            return sorted.get(Math.max(0, Math.min(index, sorted.size() - 1)));
        }

        private static String hashUuid(UUID value) {
            if (value == null) {
                return null;
            }
            try {
                byte[] digest = MessageDigest.getInstance("SHA-256").digest(
                        value.toString().getBytes(StandardCharsets.UTF_8)
                );
                StringBuilder encoded = new StringBuilder();
                for (int index = 0; index < 8; index++) {
                    encoded.append(String.format("%02x", digest[index]));
                }
                return encoded.toString();
            } catch (Exception error) {
                throw new IllegalStateException(
                        "SHA-256 is unavailable",
                        error
                );
            }
        }

        private static boolean notBlank(String value) {
            return value != null && !value.trim().isEmpty();
        }

        private static <T> T requirePayload(
                ClientCallback callback,
                Class<T> payloadType
        ) {
            Object payload = callback.getData();
            if (!payloadType.isInstance(payload)) {
                throw new IllegalArgumentException(
                        "callback payload must be "
                                + payloadType.getSimpleName()
                );
            }
            return payloadType.cast(payload);
        }
    }

    private static final class RuntimeConfig {
        final String host;
        final int port;
        final long timeoutMs;
        final long idleTimeoutMs;
        final String runId;
        final String username;
        final boolean expectTimeout;

        RuntimeConfig(
                String host,
                int port,
                long timeoutMs,
                long idleTimeoutMs,
                String runId,
                boolean expectTimeout
        ) {
            this.host = host;
            this.port = port;
            this.timeoutMs = timeoutMs;
            this.idleTimeoutMs = idleTimeoutMs;
            this.runId = runId;
            this.expectTimeout = expectTimeout;
            String sanitized = runId.replaceAll("[^A-Za-z0-9]", "");
            this.username = "ml7_"
                    + sanitized.substring(0, Math.min(8, sanitized.length()));
        }

        static RuntimeConfig parse(String[] arguments) {
            Map<String, String> values = new LinkedHashMap<>();
            for (String argument : arguments) {
                int separator = argument.indexOf('=');
                if (!argument.startsWith("--") || separator <= 2) {
                    throw new IllegalArgumentException(
                            "arguments must use --name=value"
                    );
                }
                values.put(
                        argument.substring(2, separator),
                        argument.substring(separator + 1)
                );
            }
            String runId = values.getOrDefault(
                    "run-id",
                    Long.toString(System.currentTimeMillis())
            );
            if (runId.replaceAll("[^A-Za-z0-9]", "").isEmpty()) {
                throw new IllegalArgumentException(
                        "run-id must contain a letter or digit"
                );
            }
            return new RuntimeConfig(
                    values.getOrDefault("host", "127.0.0.1"),
                    parseInteger(
                            values.getOrDefault("port", "17171"),
                            "port"
                    ),
                    parseLong(
                            values.getOrDefault(
                                    "timeout-ms",
                                    Long.toString(DEFAULT_TIMEOUT_MS)
                            ),
                            "timeout-ms"
                    ),
                    parseLong(
                            values.getOrDefault(
                                    "idle-timeout-ms",
                                    Long.toString(DEFAULT_IDLE_TIMEOUT_MS)
                            ),
                            "idle-timeout-ms"
                    ),
                    runId,
                    parseBoolean(
                            values.getOrDefault(
                                    "expect-timeout",
                                    "false"
                            ),
                            "expect-timeout"
                    )
            );
        }

        private static int parseInteger(String value, String name) {
            try {
                int parsed = Integer.parseInt(value);
                if (parsed <= 0 || parsed > 65_535) {
                    throw new NumberFormatException();
                }
                return parsed;
            } catch (NumberFormatException error) {
                throw new IllegalArgumentException(
                        name + " must be between 1 and 65535"
                );
            }
        }

        private static long parseLong(String value, String name) {
            try {
                long parsed = Long.parseLong(value);
                if (parsed <= 0L) {
                    throw new NumberFormatException();
                }
                return parsed;
            } catch (NumberFormatException error) {
                throw new IllegalArgumentException(
                        name + " must be positive"
                );
            }
        }

        private static boolean parseBoolean(String value, String name) {
            if ("true".equals(value)) {
                return true;
            }
            if ("false".equals(value)) {
                return false;
            }
            throw new IllegalArgumentException(
                    name + " must be true or false"
            );
        }
    }
}
