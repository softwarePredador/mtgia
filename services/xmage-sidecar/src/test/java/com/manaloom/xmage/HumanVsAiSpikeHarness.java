package com.manaloom.xmage;

import mage.cards.decks.DeckCardLists;
import mage.constants.PlayerAction;
import mage.game.match.MatchOptions;
import mage.interfaces.callback.ClientCallback;
import mage.interfaces.callback.ClientCallbackMethod;
import mage.players.PlayerType;
import mage.remote.Session;

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
        COMBAT
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

    static final EnumSet<ClientCallbackMethod> ALLOWLISTED_CALLBACKS = EnumSet.of(
            ClientCallbackMethod.GAME_ASK,
            ClientCallbackMethod.GAME_SELECT,
            ClientCallbackMethod.GAME_TARGET
    );

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
        String normalized = message == null
                ? ""
                : message.trim().toLowerCase(Locale.ROOT);
        if (method == ClientCallbackMethod.GAME_ASK
                && normalized.startsWith("mulligan ")
                && "Mulligan".equals(options.get("UI.left.btn.text"))
                && "Keep".equals(options.get("UI.right.btn.text"))) {
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
        return null;
    }

    static EnumSet<ClientCallbackMethod> unhandledCallbacks() {
        EnumSet<ClientCallbackMethod> result = EnumSet.copyOf(DECISION_CALLBACKS);
        result.removeAll(ALLOWLISTED_CALLBACKS);
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
        try {
            concedeAcknowledged = boundary.concede(gameId);
            return new TimeoutResult(
                    TimeoutPolicy.CONCEDE_THEN_TERMINATE_PROCESS,
                    concedeAcknowledged
            );
        } finally {
            boundary.terminateProcess();
        }
    }

    static Assessment assess(
            boolean completedHumanRuntimeMatch,
            boolean hiddenInformationLeak,
            int deadlocks
    ) {
        List<String> blockers = new ArrayList<>();
        if (!completedHumanRuntimeMatch) {
            blockers.add("no_completed_human_runtime_match");
        }
        if (!unhandledCallbacks().isEmpty()) {
            blockers.add("decision_callback_families_unhandled");
        }
        if (!hasRemoteHumanToAiTransition()) {
            blockers.add("human_to_ai_transition_unproven");
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

        TimeoutResult(TimeoutPolicy policy, boolean concedeAcknowledged) {
            this.policy = policy;
            this.concedeAcknowledged = concedeAcknowledged;
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

    static final class PromptRegistry {
        private static final String HMAC_ALGORITHM = "HmacSHA256";

        private final byte[] secret;
        private long currentStateVersion;
        private String activePromptId;
        private Map<String, Object> activeOptions = Collections.emptyMap();

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
            PromptKind kind = classify(callback.getMethod(), message, metadata);
            if (kind == null) {
                throw new IllegalArgumentException("callback is not allowlisted");
            }
            long stateVersion = callback.getMessageId();
            if (stateVersion <= currentStateVersion) {
                throw new IllegalArgumentException("callback state is stale");
            }
            if (rawOptions == null || rawOptions.isEmpty()) {
                throw new IllegalArgumentException("prompt must expose bounded response options");
            }

            String promptId = token(
                    "prompt",
                    stateVersion,
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
                        rawOption.toString()
                );
                if (options.put(optionId, rawOption) != null) {
                    throw new IllegalArgumentException("opaque option collision");
                }
                ordinal++;
            }

            currentStateVersion = stateVersion;
            activePromptId = promptId;
            activeOptions = options;
            return new Prompt(
                    promptId,
                    stateVersion,
                    kind,
                    new ArrayList<>(options.keySet())
            );
        }

        Object resolve(String promptId, long stateVersion, String optionId) {
            if (activePromptId == null
                    || !activePromptId.equals(promptId)
                    || stateVersion != currentStateVersion) {
                throw new IllegalArgumentException("prompt state is stale");
            }
            if (!activeOptions.containsKey(optionId)) {
                throw new IllegalArgumentException("response option is not allowlisted");
            }
            Object result = activeOptions.get(optionId);
            activePromptId = null;
            activeOptions = Collections.emptyMap();
            return result;
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
        final PromptKind kind;
        final List<String> optionIds;

        Prompt(
                String promptId,
                long stateVersion,
                PromptKind kind,
                List<String> optionIds
        ) {
            this.promptId = promptId;
            this.stateVersion = stateVersion;
            this.kind = kind;
            this.optionIds = Collections.unmodifiableList(new ArrayList<>(optionIds));
        }
    }

    static boolean concede(Session session, UUID gameId) {
        return session.sendPlayerAction(PlayerAction.CONCEDE, gameId, null);
    }
}
