package com.manaloom.xmage;

import mage.cards.decks.DeckCardLists;
import mage.choices.ChoiceImpl;
import mage.constants.ManaType;
import mage.constants.PlayerAction;
import mage.game.match.MatchOptions;
import mage.interfaces.callback.ClientCallback;
import mage.interfaces.callback.ClientCallbackMethod;
import mage.players.ManaPool;
import mage.players.PlayableObjectStats;
import mage.players.PlayerType;
import mage.remote.Session;
import mage.util.MultiAmountMessage;
import mage.view.AbilityPickerView;
import mage.view.CardsView;
import mage.view.GameClientMessage;
import mage.view.ManaPoolView;
import org.junit.jupiter.api.Test;

import java.io.Serializable;
import java.lang.reflect.Proxy;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
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
    void mapsLegacyAndSevenTypedFamiliesIncludingBoundedManaResponses() {
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
                HumanVsAiSpikeHarness.PromptKind.ABILITY,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_CHOOSE_ABILITY,
                        null,
                        Collections.emptyMap()
                )
        );
        assertEquals(
                HumanVsAiSpikeHarness.PromptKind.PILE,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_CHOOSE_PILE,
                        null,
                        Collections.emptyMap()
                )
        );
        assertEquals(
                HumanVsAiSpikeHarness.PromptKind.CHOICE,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_CHOOSE_CHOICE,
                        null,
                        Collections.emptyMap()
                )
        );
        assertEquals(
                HumanVsAiSpikeHarness.PromptKind.MANA,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_PLAY_MANA,
                        null,
                        Collections.emptyMap()
                )
        );
        assertEquals(
                HumanVsAiSpikeHarness.PromptKind.X_MANA,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_PLAY_XMANA,
                        null,
                        Collections.emptyMap()
                )
        );
        assertEquals(
                HumanVsAiSpikeHarness.PromptKind.AMOUNT,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_GET_AMOUNT,
                        null,
                        Collections.emptyMap()
                )
        );
        assertEquals(
                HumanVsAiSpikeHarness.PromptKind.MULTI_AMOUNT,
                HumanVsAiSpikeHarness.classify(
                        ClientCallbackMethod.GAME_GET_MULTI_AMOUNT,
                        null,
                        Collections.emptyMap()
                )
        );

        for (ClientCallbackMethod method
                : HumanVsAiSpikeHarness.TYPED_BRIDGED_CALLBACKS) {
            assertEquals(
                    HumanVsAiSpikeHarness.CallbackDisposition.TYPED_BRIDGE,
                    HumanVsAiSpikeHarness.callbackDisposition(method)
            );
        }
        assertTrue(HumanVsAiSpikeHarness.unhandledCallbacks().isEmpty());
    }

    @Test
    void exposesOnlyOpaqueSingleUseOptionsBoundToCallbackStateVersion() {
        HumanVsAiSpikeHarness.PromptRegistry registry =
                new HumanVsAiSpikeHarness.PromptRegistry(
                        "0123456789abcdef0123456789abcdef"
                                .getBytes(StandardCharsets.UTF_8)
        );
        UUID rawTarget = UUID.fromString("11111111-2222-3333-4444-555555555555");
        UUID gameId = UUID.fromString("99999999-8888-7777-6666-555555555555");
        ClientCallback callback = new ClientCallback(
                ClientCallbackMethod.GAME_TARGET,
                gameId
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
        assertFalse(prompt.promptId.contains(gameId.toString()));
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

        HumanVsAiSpikeHarness.PromptRegistry otherGameRegistry =
                new HumanVsAiSpikeHarness.PromptRegistry(
                        "0123456789abcdef0123456789abcdef"
                                .getBytes(StandardCharsets.UTF_8)
                );
        ClientCallback otherGame = new ClientCallback(
                ClientCallbackMethod.GAME_TARGET,
                UUID.fromString("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
        );
        otherGame.setMessageId(41);
        HumanVsAiSpikeHarness.Prompt otherGamePrompt = otherGameRegistry.open(
                otherGame,
                "Select target creature",
                Collections.emptyMap(),
                Collections.singletonList(rawTarget)
        );
        assertNotEquals(prompt.promptId, otherGamePrompt.promptId);
        assertFalse(
                otherGamePrompt.promptId.contains(otherGamePrompt.gameId.toString())
        );
    }

    @Test
    void bridgesSevenPinnedCallbackFamiliesWithExactSessionResponseChannels() {
        HumanVsAiSpikeHarness.PromptRegistry registry = newRegistry();
        UUID gameId = UUID.fromString("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee");
        List<String> sentMethods = new ArrayList<>();
        List<Object[]> sentArguments = new ArrayList<>();
        Session session = (Session) Proxy.newProxyInstance(
                Session.class.getClassLoader(),
                new Class<?>[]{Session.class},
                (proxy, method, arguments) -> {
                    if (method.getName().startsWith("sendPlayer")) {
                        sentMethods.add(method.getName());
                        sentArguments.add(arguments);
                    }
                    if (method.getReturnType() == boolean.class) {
                        return true;
                    }
                    return null;
                }
        );

        UUID abilityId = UUID.fromString(
                "11111111-1111-1111-1111-111111111111"
        );
        Map<UUID, String> abilityChoices = new LinkedHashMap<>();
        abilityChoices.put(abilityId, "Tap: add one green mana");
        HumanVsAiSpikeHarness.Prompt abilityPrompt = registry.open(callback(
                ClientCallbackMethod.GAME_CHOOSE_ABILITY,
                gameId,
                1,
                new AbilityPickerView(null, abilityChoices, "Choose an ability")
        ));
        assertEquals(HumanVsAiSpikeHarness.PromptKind.ABILITY, abilityPrompt.kind);
        assertEquals(HumanVsAiSpikeHarness.InputMode.OPTIONS, abilityPrompt.inputMode);
        assertEquals(2, abilityPrompt.optionIds.size());
        HumanVsAiSpikeHarness.ResolvedResponse abilityResponse =
                registry.resolveResponse(
                        abilityPrompt.promptId,
                        abilityPrompt.stateVersion,
                        abilityPrompt.optionIds.get(0)
                );
        assertEquals(HumanVsAiSpikeHarness.ResponseChannel.UUID,
                abilityResponse.command.channel);
        assertEquals(abilityId, abilityResponse.command.value);
        assertEquals(gameId, abilityResponse.gameId);
        assertTrue(abilityResponse.dispatch(session));
        assertThrows(
                IllegalStateException.class,
                () -> abilityResponse.dispatch(session)
        );

        GameClientMessage pileMessage = new GameClientMessage(
                null,
                Collections.<String, Serializable>emptyMap(),
                "Choose a pile",
                new CardsView(),
                new CardsView()
        );
        HumanVsAiSpikeHarness.Prompt pilePrompt = registry.open(callback(
                ClientCallbackMethod.GAME_CHOOSE_PILE,
                gameId,
                2,
                pileMessage
        ));
        assertEquals(HumanVsAiSpikeHarness.PromptKind.PILE, pilePrompt.kind);
        HumanVsAiSpikeHarness.ResolvedResponse pileResponse =
                registry.resolveResponse(
                        pilePrompt.promptId,
                        pilePrompt.stateVersion,
                        pilePrompt.optionIds.get(0)
                );
        assertEquals(HumanVsAiSpikeHarness.ResponseChannel.BOOLEAN,
                pileResponse.command.channel);
        assertEquals(true, pileResponse.command.value);
        assertTrue(pileResponse.dispatch(session));

        ChoiceImpl choice = new ChoiceImpl(true);
        choice.setChoices(new LinkedHashSet<>(Arrays.asList("red", "blue")));
        HumanVsAiSpikeHarness.Prompt choicePrompt = registry.open(callback(
                ClientCallbackMethod.GAME_CHOOSE_CHOICE,
                gameId,
                3,
                new GameClientMessage(
                        null,
                        Collections.<String, Serializable>emptyMap(),
                        choice
                )
        ));
        assertEquals(HumanVsAiSpikeHarness.PromptKind.CHOICE, choicePrompt.kind);
        HumanVsAiSpikeHarness.ResolvedResponse choiceResponse =
                registry.resolveResponse(
                        choicePrompt.promptId,
                        choicePrompt.stateVersion,
                        choicePrompt.optionIds.get(1)
                );
        assertEquals(HumanVsAiSpikeHarness.ResponseChannel.STRING,
                choiceResponse.command.channel);
        assertEquals("blue", choiceResponse.command.value);
        assertTrue(choiceResponse.dispatch(session));

        UUID manaSourceId = UUID.fromString(
                "22222222-2222-2222-2222-222222222222"
        );
        UUID manaPlayerId = UUID.fromString(
                "33333333-3333-3333-3333-333333333333"
        );
        Map<UUID, PlayableObjectStats> playableManaObjects =
                new LinkedHashMap<>();
        playableManaObjects.put(manaSourceId, new PlayableObjectStats());
        ManaPoolView manaPool = new ManaPoolView(new ManaPool(manaPlayerId)) {
            @Override
            public int getGreen() {
                return 1;
            }
        };
        List<HumanVsAiSpikeHarness.ResponseCommand> manaCommands =
                HumanVsAiSpikeHarness.PromptRegistry.buildManaResponses(
                        playableManaObjects,
                        manaPlayerId,
                        manaPool,
                        true
                );
        assertEquals(4, manaCommands.size());
        assertEquals(
                HumanVsAiSpikeHarness.ResponseChannel.UUID,
                manaCommands.get(0).channel
        );
        assertEquals(manaSourceId, manaCommands.get(0).value);
        assertEquals(
                HumanVsAiSpikeHarness.ResponseChannel.MANA_TYPE,
                manaCommands.get(1).channel
        );
        HumanVsAiSpikeHarness.ManaTypeResponse manaTypeResponse =
                (HumanVsAiSpikeHarness.ManaTypeResponse) manaCommands.get(1).value;
        assertEquals(manaPlayerId, manaTypeResponse.playerId);
        assertEquals(ManaType.GREEN, manaTypeResponse.manaType);
        assertEquals("special", manaCommands.get(2).value);
        assertEquals(false, manaCommands.get(3).value);
        for (HumanVsAiSpikeHarness.ResponseCommand command : manaCommands) {
            assertTrue(
                    new HumanVsAiSpikeHarness.ResolvedResponse(gameId, command)
                            .dispatch(session)
            );
        }

        HumanVsAiSpikeHarness.Prompt xManaPrompt = registry.open(callback(
                ClientCallbackMethod.GAME_PLAY_XMANA,
                gameId,
                5,
                new GameClientMessage(
                        null,
                        Collections.<String, Serializable>emptyMap(),
                        "Confirm X mana"
                )
        ));
        assertEquals(HumanVsAiSpikeHarness.PromptKind.X_MANA, xManaPrompt.kind);
        HumanVsAiSpikeHarness.ResolvedResponse xManaResponse =
                registry.resolveResponse(
                        xManaPrompt.promptId,
                        xManaPrompt.stateVersion,
                        xManaPrompt.optionIds.get(0)
                );
        assertEquals(true, xManaResponse.command.value);
        assertTrue(xManaResponse.dispatch(session));

        HumanVsAiSpikeHarness.Prompt amountPrompt = registry.open(callback(
                ClientCallbackMethod.GAME_GET_AMOUNT,
                gameId,
                6,
                new GameClientMessage(
                        null,
                        Collections.<String, Serializable>emptyMap(),
                        "Choose an amount",
                        2,
                        5
                )
        ));
        assertEquals(HumanVsAiSpikeHarness.InputMode.INTEGER, amountPrompt.inputMode);
        assertEquals(2, amountPrompt.minimum);
        assertEquals(5, amountPrompt.maximum);
        assertTrue(amountPrompt.optionIds.isEmpty());
        assertThrows(
                IllegalArgumentException.class,
                () -> registry.resolveInteger(
                        amountPrompt.promptId,
                        amountPrompt.stateVersion,
                        6
                )
        );
        HumanVsAiSpikeHarness.ResolvedResponse amountResponse =
                registry.resolveInteger(
                        amountPrompt.promptId,
                        amountPrompt.stateVersion,
                        4
                );
        assertEquals(HumanVsAiSpikeHarness.ResponseChannel.INTEGER,
                amountResponse.command.channel);
        assertEquals(4, amountResponse.command.value);
        assertTrue(amountResponse.dispatch(session));

        List<MultiAmountMessage> constraints = Arrays.asList(
                new MultiAmountMessage("first", 0, 3),
                new MultiAmountMessage("second", 1, 4)
        );
        HumanVsAiSpikeHarness.Prompt multiPrompt = registry.open(callback(
                ClientCallbackMethod.GAME_GET_MULTI_AMOUNT,
                gameId,
                7,
                new GameClientMessage(
                        null,
                        Collections.<String, Serializable>emptyMap(),
                        constraints,
                        2,
                        5
                )
        ));
        assertEquals(
                HumanVsAiSpikeHarness.InputMode.MULTI_AMOUNT,
                multiPrompt.inputMode
        );
        assertEquals(2, multiPrompt.multiAmountCount);
        assertThrows(
                IllegalArgumentException.class,
                () -> registry.resolveMultiAmount(
                        multiPrompt.promptId,
                        multiPrompt.stateVersion,
                        Arrays.asList(4, 1)
                )
        );
        HumanVsAiSpikeHarness.ResolvedResponse multiResponse =
                registry.resolveMultiAmount(
                        multiPrompt.promptId,
                        multiPrompt.stateVersion,
                        Arrays.asList(1, 2)
                );
        assertEquals(HumanVsAiSpikeHarness.ResponseChannel.STRING,
                multiResponse.command.channel);
        assertEquals("1 2", multiResponse.command.value);
        assertTrue(multiResponse.dispatch(session));

        assertEquals(
                Arrays.asList(
                        "sendPlayerUUID",
                        "sendPlayerBoolean",
                        "sendPlayerString",
                        "sendPlayerUUID",
                        "sendPlayerManaType",
                        "sendPlayerString",
                        "sendPlayerBoolean",
                        "sendPlayerBoolean",
                        "sendPlayerInteger",
                        "sendPlayerString"
                ),
                sentMethods
        );
        for (Object[] arguments : sentArguments) {
            assertEquals(gameId, arguments[0]);
        }
    }

    @Test
    void typedAdaptersRejectUnprovenOrMalformedResponsesWithoutConsumingPrompt() {
        HumanVsAiSpikeHarness.PromptRegistry malformedManaRegistry =
                newRegistry();
        IllegalArgumentException malformedManaError = assertThrows(
                IllegalArgumentException.class,
                () -> malformedManaRegistry.open(callback(
                        ClientCallbackMethod.GAME_PLAY_MANA,
                        UUID.randomUUID(),
                        1,
                        new GameClientMessage(
                                null,
                                Collections.<String, Serializable>emptyMap(),
                                "Pay mana"
                        )
                ))
        );
        assertTrue(
                malformedManaError.getMessage().contains(
                        "private player GameView"
                )
        );

        HumanVsAiSpikeHarness.PromptRegistry malformedRegistry = newRegistry();
        assertThrows(
                IllegalArgumentException.class,
                () -> malformedRegistry.open(callback(
                        ClientCallbackMethod.GAME_CHOOSE_ABILITY,
                        UUID.randomUUID(),
                        1,
                        new Object()
                ))
        );

        ChoiceImpl optionalSpecialChoice = new ChoiceImpl(false);
        optionalSpecialChoice.setChoices(
                new LinkedHashSet<>(Collections.singletonList("one"))
        );
        optionalSpecialChoice.setSpecial(true, false, "Remember", "Remember");
        HumanVsAiSpikeHarness.PromptRegistry choiceRegistry = newRegistry();
        HumanVsAiSpikeHarness.Prompt prompt = choiceRegistry.open(callback(
                ClientCallbackMethod.GAME_CHOOSE_CHOICE,
                UUID.randomUUID(),
                1,
                new GameClientMessage(
                        null,
                        Collections.<String, Serializable>emptyMap(),
                        optionalSpecialChoice
                )
        ));
        assertEquals(3, prompt.optionIds.size());
        HumanVsAiSpikeHarness.ResolvedResponse cancelResponse =
                choiceRegistry.resolveResponse(
                        prompt.promptId,
                        prompt.stateVersion,
                        prompt.optionIds.get(2)
                );
        assertEquals(HumanVsAiSpikeHarness.ResponseChannel.STRING,
                cancelResponse.command.channel);
        assertEquals(null, cancelResponse.command.value);

        Map<String, Serializable> cancellableOptions = new LinkedHashMap<>();
        cancellableOptions.put("canCancel", true);
        HumanVsAiSpikeHarness.PromptRegistry multiCancelRegistry = newRegistry();
        HumanVsAiSpikeHarness.Prompt multiCancelPrompt =
                multiCancelRegistry.open(callback(
                        ClientCallbackMethod.GAME_GET_MULTI_AMOUNT,
                        UUID.randomUUID(),
                        1,
                        new GameClientMessage(
                                null,
                                cancellableOptions,
                                Arrays.asList(
                                        new MultiAmountMessage("first", 0, 2),
                                        new MultiAmountMessage("second", 0, 2)
                                ),
                                1,
                                2
                        )
                ));
        assertEquals(1, multiCancelPrompt.optionIds.size());
        HumanVsAiSpikeHarness.ResolvedResponse multiCancelResponse =
                multiCancelRegistry.resolveResponse(
                        multiCancelPrompt.promptId,
                        multiCancelPrompt.stateVersion,
                        multiCancelPrompt.optionIds.get(0)
                );
        assertEquals(HumanVsAiSpikeHarness.ResponseChannel.BOOLEAN,
                multiCancelResponse.command.channel);
        assertEquals(false, multiCancelResponse.command.value);

        HumanVsAiSpikeHarness.PromptRegistry activeRegistry = newRegistry();
        HumanVsAiSpikeHarness.Prompt active = activeRegistry.open(callback(
                ClientCallbackMethod.GAME_PLAY_XMANA,
                UUID.randomUUID(),
                1,
                new GameClientMessage(
                        null,
                        Collections.<String, Serializable>emptyMap(),
                        "Confirm"
                )
        ));
        assertThrows(
                IllegalArgumentException.class,
                () -> activeRegistry.open(callback(
                        ClientCallbackMethod.GAME_PLAY_XMANA,
                        UUID.randomUUID(),
                        2,
                        new GameClientMessage(
                                null,
                                Collections.<String, Serializable>emptyMap(),
                                "Confirm again"
                        )
                ))
        );
        activeRegistry.resolveResponse(
                active.promptId,
                active.stateVersion,
                active.optionIds.get(1)
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
        assertEquals(null, result.concedeFailureClass);
        assertTrue(result.processTerminationInvoked);
        assertFalse(result.takeoverAttempted);
        assertTrue(terminated.get());

        AtomicBoolean terminatedAfterFailure = new AtomicBoolean();
        HumanVsAiSpikeHarness.TimeoutResult failedConcedeResult =
                HumanVsAiSpikeHarness.expire(
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
                );
        assertFalse(failedConcedeResult.concedeAcknowledged);
        assertEquals(
                "IllegalStateException",
                failedConcedeResult.concedeFailureClass
        );
        assertTrue(failedConcedeResult.processTerminationInvoked);
        assertFalse(failedConcedeResult.takeoverAttempted);
        assertTrue(terminatedAfterFailure.get());

        assertThrows(
                IllegalStateException.class,
                () -> HumanVsAiSpikeHarness.expire(
                        UUID.randomUUID(),
                        new HumanVsAiSpikeHarness.TimeoutBoundary() {
                            @Override
                            public boolean concede(UUID gameId) {
                                return false;
                            }

                            @Override
                            public void terminateProcess() {
                                throw new IllegalStateException(
                                        "process isolation boundary unavailable"
                                );
                            }
                        }
                )
        );
    }

    @Test
    void spikeIsNoGoWithoutRuntimeCompletionAndFullCallbackCoverage() {
        HumanVsAiSpikeHarness.Assessment assessment =
                HumanVsAiSpikeHarness.assess(false, false, 0);

        assertEquals(HumanVsAiSpikeHarness.Decision.NO_GO, assessment.decision);
        assertEquals(
                Arrays.asList(
                        "no_completed_human_runtime_match",
                        "human_to_ai_transition_unproven"
                ),
                assessment.blockers
        );
    }

    private static HumanVsAiSpikeHarness.PromptRegistry newRegistry() {
        return new HumanVsAiSpikeHarness.PromptRegistry(
                "0123456789abcdef0123456789abcdef"
                        .getBytes(StandardCharsets.UTF_8)
        );
    }

    private static ClientCallback callback(
            ClientCallbackMethod method,
            UUID gameId,
            int messageId,
            Object payload
    ) {
        ClientCallback callback = new ClientCallback(
                method,
                gameId,
                payload,
                false
        );
        callback.setMessageId(messageId);
        return callback;
    }
}
