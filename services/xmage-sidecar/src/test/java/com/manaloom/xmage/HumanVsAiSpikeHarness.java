package com.manaloom.xmage;

import mage.abilities.Modes;
import mage.cards.decks.DeckCardLists;
import mage.choices.Choice;
import mage.constants.ManaType;
import mage.constants.MultiAmountType;
import mage.constants.PlayerAction;
import mage.game.match.MatchOptions;
import mage.interfaces.callback.ClientCallback;
import mage.interfaces.callback.ClientCallbackMethod;
import mage.players.PlayableObjectStats;
import mage.players.PlayableObjectsList;
import mage.players.PlayerType;
import mage.remote.Session;
import mage.util.MultiAmountMessage;
import mage.view.AbilityPickerView;
import mage.view.CardsView;
import mage.view.GameClientMessage;
import mage.view.GameView;
import mage.view.ManaPoolView;
import mage.view.PlayerView;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collections;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/**
 * Test-only BL7 spike. Nothing in this class is reachable from the HTTP
 * sidecar and it must not be promoted without a separate GO decision.
 */
final class HumanVsAiSpikeHarness {
    enum PromptKind {
        MULLIGAN,
        MAIN_ACTION,
        TARGET,
        COMBAT,
        ABILITY,
        PILE,
        CHOICE,
        MANA,
        X_MANA,
        AMOUNT,
        MULTI_AMOUNT
    }

    enum InputMode {
        OPTIONS,
        INTEGER,
        MULTI_AMOUNT
    }

    enum CallbackDisposition {
        TYPED_BRIDGE,
        UNSUPPORTED_FAIL_CLOSED
    }

    enum ResponseChannel {
        UUID,
        BOOLEAN,
        STRING,
        INTEGER,
        MANA_TYPE
    }

    enum TimeoutPolicy {
        CONCEDE_THEN_TERMINATE_PROCESS
    }

    enum Decision {
        GO,
        NO_GO
    }

    static final EnumSet<ClientCallbackMethod> DECISION_CALLBACKS = EnumSet.of(
            ClientCallbackMethod.GAME_TARGET,
            ClientCallbackMethod.GAME_CHOOSE_ABILITY,
            ClientCallbackMethod.GAME_CHOOSE_PILE,
            ClientCallbackMethod.GAME_CHOOSE_CHOICE,
            ClientCallbackMethod.GAME_ASK,
            ClientCallbackMethod.GAME_SELECT,
            ClientCallbackMethod.GAME_PLAY_MANA,
            ClientCallbackMethod.GAME_PLAY_XMANA,
            ClientCallbackMethod.GAME_GET_AMOUNT,
            ClientCallbackMethod.GAME_GET_MULTI_AMOUNT
    );

    static final EnumSet<ClientCallbackMethod> LEGACY_BRIDGED_CALLBACKS = EnumSet.of(
            ClientCallbackMethod.GAME_ASK,
            ClientCallbackMethod.GAME_SELECT,
            ClientCallbackMethod.GAME_TARGET
    );

    static final EnumSet<ClientCallbackMethod> TYPED_BRIDGED_CALLBACKS = EnumSet.of(
            ClientCallbackMethod.GAME_CHOOSE_ABILITY,
            ClientCallbackMethod.GAME_CHOOSE_PILE,
            ClientCallbackMethod.GAME_CHOOSE_CHOICE,
            ClientCallbackMethod.GAME_PLAY_MANA,
            ClientCallbackMethod.GAME_PLAY_XMANA,
            ClientCallbackMethod.GAME_GET_AMOUNT,
            ClientCallbackMethod.GAME_GET_MULTI_AMOUNT
    );

    static final EnumSet<ClientCallbackMethod> BRIDGED_CALLBACKS =
            EnumSet.copyOf(LEGACY_BRIDGED_CALLBACKS);

    static {
        BRIDGED_CALLBACKS.addAll(TYPED_BRIDGED_CALLBACKS);
    }

    private HumanVsAiSpikeHarness() {
    }

    static MatchOptions matchOptions(String name, String gameType) {
        MatchOptions options = new MatchOptions(name, gameType, true);
        options.getPlayerTypes().add(PlayerType.HUMAN);
        options.getPlayerTypes().add(PlayerType.COMPUTER_MAD);
        return options;
    }

    static void joinSeats(
            Session session,
            UUID roomId,
            UUID tableId,
            DeckCardLists deckA,
            DeckCardLists deckB
    ) {
        if (!session.joinTable(
                roomId,
                tableId,
                "deck_a",
                PlayerType.HUMAN,
                5,
                deckA,
                ""
        )) {
            throw new IllegalStateException("XMage rejected HUMAN deck_a");
        }
        if (!session.joinTable(
                roomId,
                tableId,
                "deck_b",
                PlayerType.COMPUTER_MAD,
                5,
                deckB,
                ""
        )) {
            throw new IllegalStateException("XMage rejected COMPUTER_MAD deck_b");
        }
    }

    static PromptKind classify(
            ClientCallbackMethod method,
            String message,
            Map<String, ?> options
    ) {
        Map<String, ?> safeOptions = options == null
                ? Collections.<String, Object>emptyMap()
                : options;
        String normalized = message == null
                ? ""
                : message.trim().toLowerCase(Locale.ROOT);
        if (method == ClientCallbackMethod.GAME_ASK
                && normalized.startsWith("mulligan ")
                && "Mulligan".equals(safeOptions.get("UI.left.btn.text"))
                && "Keep".equals(safeOptions.get("UI.right.btn.text"))) {
            return PromptKind.MULLIGAN;
        }
        if (method == ClientCallbackMethod.GAME_SELECT) {
            if (normalized.startsWith("play spells and abilities")
                    || normalized.startsWith("play instants and activated abilities")) {
                return PromptKind.MAIN_ACTION;
            }
            if (normalized.startsWith("select attackers")
                    || normalized.startsWith("select blockers")) {
                return PromptKind.COMBAT;
            }
        }
        if (method == ClientCallbackMethod.GAME_TARGET) {
            if (normalized.startsWith("select attacker to block")
                    || normalized.startsWith("select defender")) {
                return PromptKind.COMBAT;
            }
            return PromptKind.TARGET;
        }
        if (method == ClientCallbackMethod.GAME_CHOOSE_ABILITY) {
            return PromptKind.ABILITY;
        }
        if (method == ClientCallbackMethod.GAME_CHOOSE_PILE) {
            return PromptKind.PILE;
        }
        if (method == ClientCallbackMethod.GAME_CHOOSE_CHOICE) {
            return PromptKind.CHOICE;
        }
        if (method == ClientCallbackMethod.GAME_PLAY_MANA) {
            return PromptKind.MANA;
        }
        if (method == ClientCallbackMethod.GAME_PLAY_XMANA) {
            return PromptKind.X_MANA;
        }
        if (method == ClientCallbackMethod.GAME_GET_AMOUNT) {
            return PromptKind.AMOUNT;
        }
        if (method == ClientCallbackMethod.GAME_GET_MULTI_AMOUNT) {
            return PromptKind.MULTI_AMOUNT;
        }
        return null;
    }

    static CallbackDisposition callbackDisposition(ClientCallbackMethod method) {
        if (BRIDGED_CALLBACKS.contains(method)) {
            return CallbackDisposition.TYPED_BRIDGE;
        }
        return CallbackDisposition.UNSUPPORTED_FAIL_CLOSED;
    }

    static EnumSet<ClientCallbackMethod> unhandledCallbacks() {
        EnumSet<ClientCallbackMethod> result = EnumSet.copyOf(DECISION_CALLBACKS);
        result.removeAll(BRIDGED_CALLBACKS);
        return result;
    }

    static boolean hasRemoteHumanToAiTransition() {
        for (Method method : Session.class.getMethods()) {
            String name = method.getName().toLowerCase(Locale.ROOT);
            if (name.contains("delegate")
                    || name.contains("replaceplayer")
                    || name.contains("convertplayer")
                    || name.contains("changeplayertype")) {
                return true;
            }
        }
        return false;
    }

    static TimeoutResult expire(UUID gameId, TimeoutBoundary boundary) {
        boolean concedeAcknowledged = false;
        String concedeFailureClass = null;
        try {
            concedeAcknowledged = boundary.concede(gameId);
        } catch (RuntimeException error) {
            concedeFailureClass = error.getClass().getSimpleName();
        } finally {
            boundary.terminateProcess();
        }
        return new TimeoutResult(
                TimeoutPolicy.CONCEDE_THEN_TERMINATE_PROCESS,
                concedeAcknowledged,
                concedeFailureClass,
                true,
                false
        );
    }

    static Assessment assess(
            boolean completedHumanRuntimeMatch,
            boolean hiddenInformationLeak,
            int deadlocks,
            boolean explicitTerminationPolicyProven
    ) {
        List<String> blockers = new ArrayList<>();
        if (!completedHumanRuntimeMatch) {
            blockers.add("no_completed_human_runtime_match");
        }
        if (!unhandledCallbacks().isEmpty()) {
            blockers.add("decision_callback_families_unhandled");
        }
        if (!hasRemoteHumanToAiTransition()
                && !explicitTerminationPolicyProven) {
            blockers.add("safe_timeout_terminal_path_unproven");
        }
        if (hiddenInformationLeak) {
            blockers.add("hidden_information_leak");
        }
        if (deadlocks > 0) {
            blockers.add("deadlock_observed");
        }
        return new Assessment(
                blockers.isEmpty() ? Decision.GO : Decision.NO_GO,
                blockers
        );
    }

    interface TimeoutBoundary {
        boolean concede(UUID gameId);

        void terminateProcess();
    }

    static final class TimeoutResult {
        final TimeoutPolicy policy;
        final boolean concedeAcknowledged;
        final String concedeFailureClass;
        final boolean processTerminationInvoked;
        final boolean takeoverAttempted;

        TimeoutResult(
                TimeoutPolicy policy,
                boolean concedeAcknowledged,
                String concedeFailureClass,
                boolean processTerminationInvoked,
                boolean takeoverAttempted
        ) {
            this.policy = policy;
            this.concedeAcknowledged = concedeAcknowledged;
            this.concedeFailureClass = concedeFailureClass;
            this.processTerminationInvoked = processTerminationInvoked;
            this.takeoverAttempted = takeoverAttempted;
        }
    }

    static final class Assessment {
        final Decision decision;
        final List<String> blockers;

        Assessment(Decision decision, List<String> blockers) {
            this.decision = decision;
            this.blockers = Collections.unmodifiableList(new ArrayList<>(blockers));
        }
    }

    static final class ResponseCommand {
        final ResponseChannel channel;
        final Object value;

        private ResponseCommand(ResponseChannel channel, Object value) {
            this.channel = channel;
            this.value = value;
        }

        static ResponseCommand uuid(UUID value) {
            if (value == null) {
                throw new IllegalArgumentException("UUID response cannot be null");
            }
            return new ResponseCommand(ResponseChannel.UUID, value);
        }

        static ResponseCommand bool(boolean value) {
            return new ResponseCommand(ResponseChannel.BOOLEAN, value);
        }

        static ResponseCommand string(String value) {
            return new ResponseCommand(ResponseChannel.STRING, value);
        }

        static ResponseCommand integer(int value) {
            return new ResponseCommand(ResponseChannel.INTEGER, value);
        }

        static ResponseCommand manaType(UUID playerId, ManaType manaType) {
            return new ResponseCommand(
                    ResponseChannel.MANA_TYPE,
                    new ManaTypeResponse(playerId, manaType)
            );
        }

        private boolean dispatch(Session session, UUID gameId) {
            switch (channel) {
                case UUID:
                    return session.sendPlayerUUID(gameId, (UUID) value);
                case BOOLEAN:
                    return session.sendPlayerBoolean(gameId, (Boolean) value);
                case STRING:
                    return session.sendPlayerString(gameId, (String) value);
                case INTEGER:
                    return session.sendPlayerInteger(gameId, (Integer) value);
                case MANA_TYPE:
                    ManaTypeResponse response = (ManaTypeResponse) value;
                    return session.sendPlayerManaType(
                            gameId,
                            response.playerId,
                            response.manaType
                    );
                default:
                    throw new IllegalStateException("unsupported response channel");
            }
        }

        String fingerprint() {
            return channel.name() + ":" + (value == null ? "<null>" : value.toString());
        }

        @Override
        public String toString() {
            return "ResponseCommand{" + channel.name() + "}";
        }
    }

    static final class ManaTypeResponse {
        final UUID playerId;
        final ManaType manaType;

        ManaTypeResponse(UUID playerId, ManaType manaType) {
            if (playerId == null || manaType == null) {
                throw new IllegalArgumentException(
                        "mana response requires player and mana type"
                );
            }
            this.playerId = playerId;
            this.manaType = manaType;
        }

        @Override
        public String toString() {
            return playerId + ":" + manaType.name();
        }
    }

    static final class ResolvedResponse {
        final UUID gameId;
        final ResponseCommand command;
        private boolean dispatched;

        ResolvedResponse(UUID gameId, ResponseCommand command) {
            this.gameId = gameId;
            this.command = command;
        }

        synchronized boolean dispatch(Session session) {
            if (dispatched) {
                throw new IllegalStateException("response was already dispatched");
            }
            dispatched = true;
            return command.dispatch(session, gameId);
        }
    }

    static final class PromptRegistry {
        private static final String HMAC_ALGORITHM = "HmacSHA256";
        private static final int MAX_OPTION_COUNT = 256;
        private static final int MAX_MULTI_AMOUNT_COUNT = 64;
        private static final int MAX_PILE_CARD_COUNT = 512;
        private static final int MAX_RESPONSE_STRING_BYTES = 8192;

        private final byte[] secret;
        private long currentStateVersion;
        private String activePromptId;
        private Map<String, Object> activeOptions = Collections.emptyMap();
        private UUID activeGameId;
        private InputMode activeInputMode;
        private int activeMinimum;
        private int activeMaximum;
        private List<MultiAmountMessage> activeMultiAmounts = Collections.emptyList();

        PromptRegistry(byte[] secret) {
            if (secret == null || secret.length < 16) {
                throw new IllegalArgumentException("prompt secret must contain at least 16 bytes");
            }
            this.secret = secret.clone();
        }

        Prompt open(
                ClientCallback callback,
                String message,
                Map<String, ?> metadata,
                List<?> rawOptions
        ) {
            if (callback == null
                    || !LEGACY_BRIDGED_CALLBACKS.contains(callback.getMethod())) {
                throw new IllegalArgumentException("legacy callback is not allowlisted");
            }
            PromptKind kind = classify(callback.getMethod(), message, metadata);
            if (kind == null) {
                throw new IllegalArgumentException("callback is not allowlisted");
            }
            return begin(
                    callback,
                    kind,
                    InputMode.OPTIONS,
                    rawOptions,
                    0,
                    0,
                    Collections.<MultiAmountMessage>emptyList()
            );
        }

        Prompt open(ClientCallback callback) {
            if (callback == null || callback.getMethod() == null) {
                throw new IllegalArgumentException("callback and method are required");
            }
            if (!TYPED_BRIDGED_CALLBACKS.contains(callback.getMethod())) {
                throw new IllegalArgumentException("callback has no typed spike adapter");
            }

            switch (callback.getMethod()) {
                case GAME_CHOOSE_ABILITY:
                    return openAbility(callback);
                case GAME_CHOOSE_PILE:
                    return openPile(callback);
                case GAME_CHOOSE_CHOICE:
                    return openChoice(callback);
                case GAME_PLAY_MANA:
                    return openMana(callback);
                case GAME_PLAY_XMANA:
                    requirePayload(callback, GameClientMessage.class);
                    return begin(
                            callback,
                            PromptKind.X_MANA,
                            InputMode.OPTIONS,
                            responseOptions(
                                    ResponseCommand.bool(true),
                                    ResponseCommand.bool(false)
                            ),
                            0,
                            0,
                            Collections.<MultiAmountMessage>emptyList()
                    );
                case GAME_GET_AMOUNT:
                    return openAmount(callback);
                case GAME_GET_MULTI_AMOUNT:
                    return openMultiAmount(callback);
                default:
                    throw new IllegalArgumentException("callback has no typed spike adapter");
            }
        }

        private Prompt openMana(ClientCallback callback) {
            GameClientMessage payload = requirePayload(
                    callback,
                    GameClientMessage.class
            );
            GameView gameView = payload.getGameView();
            if (gameView == null || !gameView.isPlayer()) {
                throw new IllegalArgumentException(
                        "mana callback requires a private player GameView"
                );
            }
            PlayerView player = gameView.getMyPlayer();
            if (player == null || player.getPlayerId() == null) {
                throw new IllegalArgumentException(
                        "mana callback player identity is required"
                );
            }
            PlayableObjectsList playableObjects = gameView.getCanPlayObjects();
            if (playableObjects == null || playableObjects.getObjects() == null) {
                throw new IllegalArgumentException(
                        "mana callback playable objects are required"
                );
            }

            List<ResponseCommand> responses = buildManaResponses(
                    playableObjects.getObjects(),
                    player.getPlayerId(),
                    player.getManaPool(),
                    gameView.getSpecial()
            );
            return begin(
                    callback,
                    PromptKind.MANA,
                    InputMode.OPTIONS,
                    responses,
                    0,
                    0,
                    Collections.<MultiAmountMessage>emptyList()
            );
        }

        static List<ResponseCommand> buildManaResponses(
                Map<UUID, PlayableObjectStats> playableObjects,
                UUID playerId,
                ManaPoolView manaPool,
                boolean specialActionAvailable
        ) {
            if (playableObjects == null
                    || playerId == null
                    || manaPool == null) {
                throw new IllegalArgumentException(
                        "mana response inputs are required"
                );
            }

            for (Map.Entry<UUID, PlayableObjectStats> entry
                    : playableObjects.entrySet()) {
                UUID objectId = entry.getKey();
                if (objectId == null || entry.getValue() == null) {
                    throw new IllegalArgumentException(
                            "mana playable object entry is invalid"
                    );
                }
            }
            List<UUID> objectIds = new ArrayList<>(playableObjects.keySet());
            objectIds.sort((left, right) -> left.toString().compareTo(
                    right.toString()
            ));
            List<ResponseCommand> responses = new ArrayList<>();
            for (UUID objectId : objectIds) {
                responses.add(ResponseCommand.uuid(objectId));
            }

            addManaTypeIfPresent(
                    responses,
                    playerId,
                    ManaType.BLACK,
                    manaPool.getBlack()
            );
            addManaTypeIfPresent(
                    responses,
                    playerId,
                    ManaType.BLUE,
                    manaPool.getBlue()
            );
            addManaTypeIfPresent(
                    responses,
                    playerId,
                    ManaType.GREEN,
                    manaPool.getGreen()
            );
            addManaTypeIfPresent(
                    responses,
                    playerId,
                    ManaType.RED,
                    manaPool.getRed()
            );
            addManaTypeIfPresent(
                    responses,
                    playerId,
                    ManaType.WHITE,
                    manaPool.getWhite()
            );
            addManaTypeIfPresent(
                    responses,
                    playerId,
                    ManaType.COLORLESS,
                    manaPool.getColorless()
            );
            if (specialActionAvailable) {
                responses.add(ResponseCommand.string("special"));
            }

            // HumanPlayer treats any Boolean response as cancellation. Use the
            // same false value emitted by the native feedback panel.
            responses.add(ResponseCommand.bool(false));
            return responses;
        }

        private static void addManaTypeIfPresent(
                List<ResponseCommand> responses,
                UUID playerId,
                ManaType manaType,
                int count
        ) {
            if (count < 0) {
                throw new IllegalArgumentException(
                        "mana pool count cannot be negative"
                );
            }
            if (count > 0) {
                responses.add(ResponseCommand.manaType(playerId, manaType));
            }
        }

        private Prompt openAbility(ClientCallback callback) {
            AbilityPickerView payload = requirePayload(callback, AbilityPickerView.class);
            if (payload.getChoices() == null) {
                throw new IllegalArgumentException("ability choices are required");
            }
            List<ResponseCommand> responses = new ArrayList<>();
            boolean hasExplicitCancel = false;
            for (UUID abilityId : payload.getChoices().keySet()) {
                if (abilityId == null) {
                    throw new IllegalArgumentException("ability UUID cannot be null");
                }
                responses.add(ResponseCommand.uuid(abilityId));
                hasExplicitCancel = hasExplicitCancel
                        || Modes.CHOOSE_OPTION_CANCEL_ID.equals(abilityId);
            }
            if (!hasExplicitCancel) {
                responses.add(ResponseCommand.bool(false));
            }
            return begin(
                    callback,
                    PromptKind.ABILITY,
                    InputMode.OPTIONS,
                    responses,
                    0,
                    0,
                    Collections.<MultiAmountMessage>emptyList()
            );
        }

        private Prompt openPile(ClientCallback callback) {
            GameClientMessage payload = requirePayload(callback, GameClientMessage.class);
            CardsView first = payload.getCardsView1();
            CardsView second = payload.getCardsView2();
            if (first == null || second == null) {
                throw new IllegalArgumentException("both piles are required");
            }
            if (first.size() > MAX_PILE_CARD_COUNT || second.size() > MAX_PILE_CARD_COUNT) {
                throw new IllegalArgumentException("pile exceeds spike safety limit");
            }
            return begin(
                    callback,
                    PromptKind.PILE,
                    InputMode.OPTIONS,
                    responseOptions(
                            ResponseCommand.bool(true),
                            ResponseCommand.bool(false)
                    ),
                    0,
                    0,
                    Collections.<MultiAmountMessage>emptyList()
            );
        }

        private Prompt openChoice(ClientCallback callback) {
            GameClientMessage payload = requirePayload(callback, GameClientMessage.class);
            Choice choice = payload.getChoice();
            if (choice == null) {
                throw new IllegalArgumentException("choice payload is required");
            }

            List<String> values = new ArrayList<>();
            if (choice.isKeyChoice()) {
                if (choice.getKeyChoices() == null) {
                    throw new IllegalArgumentException("key choices are required");
                }
                values.addAll(choice.getKeyChoices().keySet());
            } else {
                if (choice.getChoices() == null) {
                    throw new IllegalArgumentException("choices are required");
                }
                values.addAll(choice.getChoices());
            }

            List<ResponseCommand> responses = new ArrayList<>();
            for (String value : values) {
                validateResponseString(value);
                responses.add(ResponseCommand.string(value));
            }
            if (choice.isSpecialEnabled()) {
                for (String value : values) {
                    String specialValue = "#" + value;
                    validateResponseString(specialValue);
                    responses.add(ResponseCommand.string(specialValue));
                }
            }
            if (!choice.isRequired()) {
                responses.add(ResponseCommand.string(null));
            }
            if (responses.isEmpty()) {
                throw new IllegalArgumentException("required choice has no response options");
            }
            return begin(
                    callback,
                    PromptKind.CHOICE,
                    InputMode.OPTIONS,
                    responses,
                    0,
                    0,
                    Collections.<MultiAmountMessage>emptyList()
            );
        }

        private Prompt openAmount(ClientCallback callback) {
            GameClientMessage payload = requirePayload(callback, GameClientMessage.class);
            if (payload.getMin() > payload.getMax()) {
                throw new IllegalArgumentException("amount bounds are inverted");
            }
            return begin(
                    callback,
                    PromptKind.AMOUNT,
                    InputMode.INTEGER,
                    Collections.emptyList(),
                    payload.getMin(),
                    payload.getMax(),
                    Collections.<MultiAmountMessage>emptyList()
            );
        }

        private Prompt openMultiAmount(ClientCallback callback) {
            GameClientMessage payload = requirePayload(callback, GameClientMessage.class);
            List<MultiAmountMessage> rawMessages = payload.getMessages();
            if (rawMessages == null
                    || rawMessages.isEmpty()
                    || rawMessages.size() > MAX_MULTI_AMOUNT_COUNT) {
                throw new IllegalArgumentException("multi-amount constraint count is invalid");
            }
            if (payload.getMin() > payload.getMax()) {
                throw new IllegalArgumentException("multi-amount total bounds are inverted");
            }

            List<MultiAmountMessage> constraints = new ArrayList<>();
            for (MultiAmountMessage raw : rawMessages) {
                if (raw == null || raw.min > raw.max) {
                    throw new IllegalArgumentException("multi-amount constraint is invalid");
                }
                constraints.add(new MultiAmountMessage(
                        raw.message,
                        raw.min,
                        raw.max,
                        raw.defaultValue
                ));
            }
            List<ResponseCommand> responses = new ArrayList<>();
            if (payload.getOptions() != null
                    && Boolean.TRUE.equals(payload.getOptions().get("canCancel"))) {
                responses.add(ResponseCommand.bool(false));
            }
            return begin(
                    callback,
                    PromptKind.MULTI_AMOUNT,
                    InputMode.MULTI_AMOUNT,
                    responses,
                    payload.getMin(),
                    payload.getMax(),
                    constraints
            );
        }

        private Prompt begin(
                ClientCallback callback,
                PromptKind kind,
                InputMode inputMode,
                List<?> rawOptions,
                int minimum,
                int maximum,
                List<MultiAmountMessage> multiAmounts
        ) {
            if (callback.getObjectId() == null) {
                throw new IllegalArgumentException("callback game id is required");
            }
            long stateVersion = callback.getMessageId();
            if (stateVersion <= currentStateVersion) {
                throw new IllegalArgumentException("callback state is stale");
            }
            if (activePromptId != null) {
                throw new IllegalArgumentException("another prompt is still active");
            }
            if (rawOptions == null || rawOptions.size() > MAX_OPTION_COUNT) {
                throw new IllegalArgumentException("prompt option count exceeds safety limit");
            }
            if (inputMode == InputMode.OPTIONS && rawOptions.isEmpty()) {
                throw new IllegalArgumentException("prompt must expose bounded response options");
            }

            String promptId = token(
                    "prompt",
                    stateVersion,
                    callback.getObjectId().toString(),
                    callback.getMethod().name(),
                    kind.name()
            );
            Map<String, Object> options = new LinkedHashMap<>();
            int ordinal = 0;
            for (Object rawOption : rawOptions) {
                if (rawOption == null) {
                    throw new IllegalArgumentException("null response option");
                }
                String optionId = token(
                        "option",
                        stateVersion,
                        promptId,
                        String.valueOf(ordinal),
                        optionFingerprint(rawOption)
                );
                if (options.put(optionId, rawOption) != null) {
                    throw new IllegalArgumentException("opaque option collision");
                }
                ordinal++;
            }

            currentStateVersion = stateVersion;
            activePromptId = promptId;
            activeOptions = options;
            activeGameId = callback.getObjectId();
            activeInputMode = inputMode;
            activeMinimum = minimum;
            activeMaximum = maximum;
            activeMultiAmounts = Collections.unmodifiableList(
                    new ArrayList<>(multiAmounts)
            );
            return new Prompt(
                    promptId,
                    stateVersion,
                    callback.getObjectId(),
                    kind,
                    inputMode,
                    minimum,
                    maximum,
                    multiAmounts.size(),
                    new ArrayList<>(options.keySet())
            );
        }

        Object resolve(String promptId, long stateVersion, String optionId) {
            assertActive(promptId, stateVersion);
            if (!activeOptions.containsKey(optionId)) {
                throw new IllegalArgumentException("response option is not allowlisted");
            }
            Object result = activeOptions.get(optionId);
            clearActive();
            return result;
        }

        ResolvedResponse resolveResponse(
                String promptId,
                long stateVersion,
                String optionId
        ) {
            assertActive(promptId, stateVersion);
            Object raw = activeOptions.get(optionId);
            if (!(raw instanceof ResponseCommand)) {
                throw new IllegalArgumentException("option has no typed response command");
            }
            UUID gameId = activeGameId;
            ResponseCommand command = (ResponseCommand) raw;
            clearActive();
            return new ResolvedResponse(gameId, command);
        }

        ResolvedResponse resolveInteger(
                String promptId,
                long stateVersion,
                int value
        ) {
            assertActive(promptId, stateVersion);
            if (activeInputMode != InputMode.INTEGER) {
                throw new IllegalArgumentException("prompt does not accept an integer");
            }
            if (value < activeMinimum || value > activeMaximum) {
                throw new IllegalArgumentException("integer response is outside callback bounds");
            }
            UUID gameId = activeGameId;
            clearActive();
            return new ResolvedResponse(gameId, ResponseCommand.integer(value));
        }

        ResolvedResponse resolveMultiAmount(
                String promptId,
                long stateVersion,
                List<Integer> values
        ) {
            assertActive(promptId, stateVersion);
            if (activeInputMode != InputMode.MULTI_AMOUNT) {
                throw new IllegalArgumentException("prompt does not accept multi-amount values");
            }
            if (values == null || values.size() != activeMultiAmounts.size()) {
                throw new IllegalArgumentException("multi-amount response count is invalid");
            }

            long total = 0L;
            for (int index = 0; index < values.size(); index++) {
                Integer value = values.get(index);
                MultiAmountMessage constraint = activeMultiAmounts.get(index);
                if (value == null || value < constraint.min || value > constraint.max) {
                    throw new IllegalArgumentException(
                            "multi-amount response violates an individual bound"
                    );
                }
                total += value;
            }
            if (total < activeMinimum || total > activeMaximum
                    || !MultiAmountType.isGoodValues(
                    values,
                    activeMultiAmounts,
                    activeMinimum,
                    activeMaximum
            )) {
                throw new IllegalArgumentException(
                        "multi-amount response violates total bounds"
                );
            }

            StringBuilder encoded = new StringBuilder();
            for (Integer value : values) {
                if (encoded.length() > 0) {
                    encoded.append(' ');
                }
                encoded.append(value);
            }
            UUID gameId = activeGameId;
            clearActive();
            return new ResolvedResponse(
                    gameId,
                    ResponseCommand.string(encoded.toString())
            );
        }

        ResolvedResponse resolveMinimumMultiAmount(
                String promptId,
                long stateVersion
        ) {
            assertActive(promptId, stateVersion);
            if (activeInputMode != InputMode.MULTI_AMOUNT) {
                throw new IllegalArgumentException(
                        "prompt does not accept multi-amount values"
                );
            }

            List<Integer> values = new ArrayList<>();
            long total = 0L;
            for (MultiAmountMessage constraint : activeMultiAmounts) {
                values.add(constraint.min);
                total += constraint.min;
            }
            if (total > activeMaximum) {
                throw new IllegalArgumentException(
                        "multi-amount minimums exceed total maximum"
                );
            }

            long missing = Math.max(0L, (long) activeMinimum - total);
            for (int index = 0; index < activeMultiAmounts.size()
                    && missing > 0L; index++) {
                MultiAmountMessage constraint = activeMultiAmounts.get(index);
                int current = values.get(index);
                int increment = (int) Math.min(
                        missing,
                        (long) constraint.max - current
                );
                values.set(index, current + increment);
                missing -= increment;
            }
            if (missing > 0L) {
                throw new IllegalArgumentException(
                        "multi-amount bounds have no minimum solution"
                );
            }
            return resolveMultiAmount(promptId, stateVersion, values);
        }

        private void assertActive(String promptId, long stateVersion) {
            if (activePromptId == null
                    || !activePromptId.equals(promptId)
                    || stateVersion != currentStateVersion) {
                throw new IllegalArgumentException("prompt state is stale");
            }
        }

        private void clearActive() {
            activePromptId = null;
            activeOptions = Collections.emptyMap();
            activeGameId = null;
            activeInputMode = null;
            activeMinimum = 0;
            activeMaximum = 0;
            activeMultiAmounts = Collections.emptyList();
        }

        private static String optionFingerprint(Object rawOption) {
            if (rawOption instanceof ResponseCommand) {
                return ((ResponseCommand) rawOption).fingerprint();
            }
            return rawOption.toString();
        }

        private static List<ResponseCommand> responseOptions(
                ResponseCommand... commands
        ) {
            List<ResponseCommand> result = new ArrayList<>();
            Collections.addAll(result, commands);
            return result;
        }

        private static void validateResponseString(String value) {
            if (value == null) {
                throw new IllegalArgumentException("choice response cannot be null");
            }
            if (value.getBytes(StandardCharsets.UTF_8).length
                    > MAX_RESPONSE_STRING_BYTES) {
                throw new IllegalArgumentException("choice response exceeds safety limit");
            }
        }

        private static <T> T requirePayload(
                ClientCallback callback,
                Class<T> payloadType
        ) {
            Object payload = callback.getData();
            if (!payloadType.isInstance(payload)) {
                throw new IllegalArgumentException(
                        "callback payload must be " + payloadType.getSimpleName()
                );
            }
            return payloadType.cast(payload);
        }

        private String token(String namespace, long version, String... values) {
            try {
                Mac mac = Mac.getInstance(HMAC_ALGORITHM);
                mac.init(new SecretKeySpec(secret, HMAC_ALGORITHM));
                mac.update(namespace.getBytes(StandardCharsets.UTF_8));
                mac.update((byte) 0);
                mac.update(Long.toString(version).getBytes(StandardCharsets.UTF_8));
                for (String value : values) {
                    mac.update((byte) 0);
                    mac.update(value.getBytes(StandardCharsets.UTF_8));
                }
                String encoded = Base64.getUrlEncoder()
                        .withoutPadding()
                        .encodeToString(mac.doFinal());
                return namespace.substring(0, 1) + "_" + encoded.substring(0, 32);
            } catch (GeneralSecurityException error) {
                throw new IllegalStateException("HMAC-SHA256 unavailable", error);
            }
        }
    }

    static final class Prompt {
        final String promptId;
        final long stateVersion;
        final UUID gameId;
        final PromptKind kind;
        final InputMode inputMode;
        final int minimum;
        final int maximum;
        final int multiAmountCount;
        final List<String> optionIds;

        Prompt(
                String promptId,
                long stateVersion,
                UUID gameId,
                PromptKind kind,
                InputMode inputMode,
                int minimum,
                int maximum,
                int multiAmountCount,
                List<String> optionIds
        ) {
            this.promptId = promptId;
            this.stateVersion = stateVersion;
            this.gameId = gameId;
            this.kind = kind;
            this.inputMode = inputMode;
            this.minimum = minimum;
            this.maximum = maximum;
            this.multiAmountCount = multiAmountCount;
            this.optionIds = Collections.unmodifiableList(new ArrayList<>(optionIds));
        }
    }

    static boolean concede(Session session, UUID gameId) {
        return session.sendPlayerAction(PlayerAction.CONCEDE, gameId, null);
    }
}
