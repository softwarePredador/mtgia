package com.manaloom.xmage;

import mage.cards.decks.DeckCardLists;
import mage.constants.PlayerAction;
import mage.game.match.MatchOptions;
import mage.interfaces.callback.ClientCallback;
import mage.interfaces.callback.ClientCallbackMethod;
import mage.players.PlayerType;
import mage.remote.Session;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Proxy;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

final class HumanVsAiSpikeTest {
    @Test
    void onlyDeckAUsesHumanAndDeckBRemainsComputerMad() {
        MatchOptions options = HumanVsAiSpikeHarness.matchOptions(
                "BL7 isolated spike",
                "Freeform Commander Free For All"
        );
        assertEquals(
                Arrays.asList(PlayerType.HUMAN, PlayerType.COMPUTER_MAD),
                options.getPlayerTypes()
        );
        assertFalse(PlayerType.HUMAN.isAI());
        assertTrue(PlayerType.COMPUTER_MAD.isAI());

        List<Object[]> joinCalls = new ArrayList<>();
        Session session = (Session) Proxy.newProxyInstance(
                Session.class.getClassLoader(),
                new Class<?>[]{Session.class},
                (proxy, method, arguments) -> {
                    if ("joinTable".equals(method.getName())) {
                        joinCalls.add(arguments);
                        return true;
                    }
                    if (method.getReturnType() == boolean.class) {
                        return false;
                    }
                    return null;
                }
        );

        HumanVsAiSpikeHarness.joinSeats(
                session,
                UUID.randomUUID(),
                UUID.randomUUID(),
                new DeckCardLists(),
                new DeckCardLists()
        );

        assertEquals(2, joinCalls.size());
        assertEquals("deck_a", joinCalls.get(0)[2]);
        assertEquals(PlayerType.HUMAN, joinCalls.get(0)[3]);
        assertEquals("deck_b", joinCalls.get(1)[2]);
        assertEquals(PlayerType.COMPUTER_MAD, joinCalls.get(1)[3]);
    }

    @Test
    void mapsOnlyTheFourTimeBoxedPromptFamiliesAndInventoriesTheRest() {
        Map<String, Object> mulliganOptions = new LinkedHashMap<>();
        mulliganOptions.put("UI.left.btn.text", "Mulligan");
        mulliganOptions.put("UI.right.btn.text", "Keep");

        assertEquals(
                HumanVsAiSpikeHarness.PromptKind.MULLIGAN,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_ASK,
                        "Mulligan down to 6 cards?",
                        mulliganOptions
                )
        );
        assertEquals(
                HumanVsAiSpikeHarness.PromptKind.MAIN_ACTION,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_SELECT,
                        "Play spells and abilities",
                        Collections.emptyMap()
                )
        );
        assertEquals(
                HumanVsAiSpikeHarness.PromptKind.TARGET,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_TARGET,
                        "Select target creature",
                        Collections.emptyMap()
                )
        );
        assertEquals(
                HumanVsAiSpikeHarness.PromptKind.COMBAT,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_SELECT,
                        "Select attackers",
                        Collections.emptyMap()
                )
        );
        assertEquals(
                HumanVsAiSpikeHarness.PromptKind.COMBAT,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_TARGET,
                        "Select attacker to block",
                        Collections.emptyMap()
                )
        );

        assertEquals(
                null,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_ASK,
                        "Use replacement effect?",
                        Collections.emptyMap()
                )
        );
        assertEquals(
                null,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_SELECT,
                        "Unknown selection",
                        Collections.emptyMap()
                )
        );
        assertEquals(
                EnumSet.of(
                        ClientCallbackMethod.GAME_CHOOSE_ABILITY,
                        ClientCallbackMethod.GAME_CHOOSE_PILE,
                        ClientCallbackMethod.GAME_CHOOSE_CHOICE,
                        ClientCallbackMethod.GAME_PLAY_MANA,
                        ClientCallbackMethod.GAME_PLAY_XMANA,
                        ClientCallbackMethod.GAME_GET_AMOUNT,
                        ClientCallbackMethod.GAME_GET_MULTI_AMOUNT
                ),
                HumanVsAiSpikeHarness.unhandledCallbacks()
        );
    }

    @Test
    void exposesOnlyOpaqueSingleUseOptionsBoundToCallbackStateVersion() {
        HumanVsAiSpikeHarness.PromptRegistry registry =
                new HumanVsAiSpikeHarness.PromptRegistry(
                        "0123456789abcdef0123456789abcdef"
                                .getBytes(StandardCharsets.UTF_8)
                );
        UUID rawTarget = UUID.fromString("11111111-2222-3333-4444-555555555555");
        ClientCallback callback = new ClientCallback(
                ClientCallbackMethod.GAME_TARGET,
                UUID.randomUUID()
        );
        callback.setMessageId(41);

        HumanVsAiSpikeHarness.Prompt prompt = registry.open(
                callback,
                "Select target creature",
                Collections.emptyMap(),
                Collections.singletonList(rawTarget)
        );

        assertEquals(41L, prompt.stateVersion);
        assertEquals(HumanVsAiSpikeHarness.PromptKind.TARGET, prompt.kind);
        assertFalse(prompt.promptId.contains(rawTarget.toString()));
        assertFalse(prompt.optionIds.get(0).contains(rawTarget.toString()));
        assertNotEquals(rawTarget.toString(), prompt.optionIds.get(0));
        assertThrows(
                IllegalArgumentException.class,
                () -> registry.resolve(
                        prompt.promptId,
                        40L,
                        prompt.optionIds.get(0)
                )
        );
        assertThrows(
                IllegalArgumentException.class,
                () -> registry.resolve(prompt.promptId, 41L, "o_arbitrary")
        );
        assertEquals(
                rawTarget,
                registry.resolve(
                        prompt.promptId,
                        prompt.stateVersion,
                        prompt.optionIds.get(0)
                )
        );
        assertThrows(
                IllegalArgumentException.class,
                () -> registry.resolve(
                        prompt.promptId,
                        prompt.stateVersion,
                        prompt.optionIds.get(0)
                )
        );

        ClientCallback stale = new ClientCallback(
                ClientCallbackMethod.GAME_TARGET,
                UUID.randomUUID()
        );
        stale.setMessageId(40);
        assertThrows(
                IllegalArgumentException.class,
                () -> registry.open(
                        stale,
                        "Select target creature",
                        Collections.emptyMap(),
                        Collections.singletonList(rawTarget)
                )
        );
    }

    @Test
    void timeoutConcedesThenTerminatesAndNeverClaimsAiDelegation() throws Exception {
        assertFalse(HumanVsAiSpikeHarness.hasRemoteHumanToAiTransition());
        assertEquals(
                PlayerAction.CONCEDE,
                PlayerAction.valueOf("CONCEDE")
        );
        Session.class.getMethod(
                "sendPlayerAction",
                PlayerAction.class,
                UUID.class,
                Object.class
        );

        AtomicBoolean terminated = new AtomicBoolean();
        HumanVsAiSpikeHarness.TimeoutResult result =
                HumanVsAiSpikeHarness.expire(
                        UUID.randomUUID(),
                        new HumanVsAiSpikeHarness.TimeoutBoundary() {
                            @Override
                            public boolean concede(UUID gameId) {
                                return true;
                            }

                            @Override
                            public void terminateProcess() {
                                terminated.set(true);
                            }
                        }
                );

        assertEquals(
                HumanVsAiSpikeHarness.TimeoutPolicy.CONCEDE_THEN_TERMINATE_PROCESS,
                result.policy
        );
        assertTrue(result.concedeAcknowledged);
        assertTrue(terminated.get());

        AtomicBoolean terminatedAfterFailure = new AtomicBoolean();
        assertThrows(
                IllegalStateException.class,
                () -> HumanVsAiSpikeHarness.expire(
                        UUID.randomUUID(),
                        new HumanVsAiSpikeHarness.TimeoutBoundary() {
                            @Override
                            public boolean concede(UUID gameId) {
                                throw new IllegalStateException("connection lost");
                            }

                            @Override
                            public void terminateProcess() {
                                terminatedAfterFailure.set(true);
                            }
                        }
                )
        );
        assertTrue(terminatedAfterFailure.get());
    }

    @Test
    void spikeIsNoGoWithoutRuntimeCompletionAndFullCallbackCoverage() {
        HumanVsAiSpikeHarness.Assessment assessment =
                HumanVsAiSpikeHarness.assess(false, false, 0);

        assertEquals(HumanVsAiSpikeHarness.Decision.NO_GO, assessment.decision);
        assertEquals(
                Arrays.asList(
                        "no_completed_human_runtime_match",
                        "decision_callback_families_unhandled",
                        "human_to_ai_transition_unproven"
                ),
                assessment.blockers
        );
    }
}
