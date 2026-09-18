package com.manaloom.xmage;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import mage.players.PlayableObjectStats;
import mage.view.CommandObjectView;
import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

final class InteractiveBattleRegistryTest {
    @Test
    void runtimeIdsAreOpaqueAndStrictlyBounded() {
        assertTrue(InteractiveBattleRegistry.isRuntimeId(
                "ibsrt_abcdefghijklmnop"
        ));
        assertFalse(InteractiveBattleRegistry.isRuntimeId(
                "interactive-session-1"
        ));
        assertFalse(InteractiveBattleRegistry.isRuntimeId(
                "ibsrt_short"
        ));
        assertFalse(InteractiveBattleRegistry.isRuntimeId(null));
    }

    @Test
    void registryPublishesBoundedInteractiveOnlyCapacity() {
        InteractiveBattleRegistry registry =
                new InteractiveBattleRegistry("127.0.0.1", 19171, 4);
        try {
            Map<String, Object> metrics = registry.metrics();
            assertEquals(
                    InteractiveBattleRegistry.RUNTIME_SCHEMA,
                    metrics.get("schema_version")
            );
            assertEquals(4, metrics.get("maximum_active"));
            assertEquals(0, metrics.get("active"));
            assertEquals(0, metrics.get("retained"));
            assertEquals("interactive", metrics.get("runtime_mode"));
            assertEquals(
                    Boolean.FALSE,
                    metrics.get("batch_simulation_available")
            );
        } finally {
            registry.close();
        }
    }

    @Test
    void connectionBudgetCoversTheObservedServerReadyHandshake() {
        assertEquals(
                15_000L,
                InteractiveBattleRegistry.CONNECT_READY_TIMEOUT_MS
        );
    }

    @Test
    void registryRejectsUnsafeCapacityBeforeAllocatingThreads() {
        assertThrows(
                IllegalArgumentException.class,
                () -> new InteractiveBattleRegistry(
                        "127.0.0.1",
                        19171,
                        0
                )
        );
        assertThrows(
                IllegalArgumentException.class,
                () -> new InteractiveBattleRegistry(
                        "127.0.0.1",
                        19171,
                        33
                )
        );
    }

    @Test
    void playerTargetsAreDistinctAndDoNotExposeMarkup() {
        assertEquals(
                "Você",
                InteractiveBattleRegistry.playerTargetLabel(
                        true,
                        "Internal human player"
                )
        );
        assertEquals(
                "Adversário",
                InteractiveBattleRegistry.playerTargetLabel(false, " ")
        );
        assertEquals(
                "Adversário — Rival",
                InteractiveBattleRegistry.playerTargetLabel(
                        false,
                        "<strong>Rival</strong>"
                )
        );
    }

    @Test
    void productPlayerNamesReplaceTechnicalSeatKeys() {
        assertEquals(
                "Lorehold Lessons",
                InteractiveBattleRegistry.productPlayerName(
                        "deck_a",
                        "<strong>Lorehold Lessons</strong>",
                        "Rival"
                )
        );
        assertEquals(
                "Rival",
                InteractiveBattleRegistry.productPlayerName(
                        "deck_b",
                        "Lorehold Lessons",
                        "Rival"
                )
        );
        assertEquals(
                "Deck adversário",
                InteractiveBattleRegistry.productPlayerName(
                        "deck_b",
                        "Lorehold Lessons",
                        " "
                )
        );
    }

    @Test
    void productPromptMessagesNeverForwardEngineCopy() {
        assertEquals(
                "Jogue uma mágica, ative uma habilidade "
                        + "ou passe a prioridade.",
                InteractiveBattleRegistry.productPromptMessage(
                        HumanVsAiSpikeHarness.PromptKind.MAIN_ACTION,
                        "Play instants and activated abilities"
                )
        );
        assertEquals(
                "Escolha um alvo legal para continuar.",
                InteractiveBattleRegistry.productPromptMessage(
                        HumanVsAiSpikeHarness.PromptKind.TARGET,
                        "Select a starting player"
                )
        );
    }

    @Test
    void commanderOptionsExposeCardFirstIdentity() {
        StubCommandObject commandObject = new StubCommandObject(
                "Isamaru, Hound of Konda",
                "CHK"
        );
        Map<String, Object> descriptor =
                InteractiveBattleRegistry.commandObjectDescriptor(
                        commandObject
                );

        assertEquals(commandObject.getId().toString(), descriptor.get("id"));
        assertEquals("Isamaru, Hound of Konda", descriptor.get("name"));
        assertEquals("CHK", descriptor.get("set_code"));
        assertFalse(descriptor.containsKey("collector_number"));
    }

    @Test
    void visibleCardOptionsExposeTheExactOpaqueObjectId() {
        UUID objectId = UUID.fromString(
                "11111111-1111-4111-8111-111111111111"
        );
        Map<String, Object> descriptor =
                InteractiveBattleRegistry.promptCardDescriptor(
                        objectId,
                        "Swords to Plowshares",
                        "2XM",
                        "35"
                );

        assertEquals(objectId.toString(), descriptor.get("id"));
        assertEquals("Swords to Plowshares", descriptor.get("name"));
        assertEquals("2XM", descriptor.get("set_code"));
        assertEquals("35", descriptor.get("collector_number"));
        assertThrows(
                IllegalArgumentException.class,
                () -> InteractiveBattleRegistry.promptCardDescriptor(
                        null,
                        "Hidden object",
                        null,
                        null
                )
        );
    }

    @Test
    void combatOptionsUseThePermanentIdsPublishedByHumanPlayer() {
        UUID later = UUID.fromString(
                "ffffffff-ffff-4fff-8fff-ffffffffffff"
        );
        UUID earlier = UUID.fromString(
                "00000000-0000-4000-8000-000000000001"
        );
        Map<String, Object> metadata = new HashMap<>();
        metadata.put(
                "possibleAttackers",
                java.util.Arrays.asList(later, earlier)
        );
        metadata.put(
                "possibleBlockers",
                Collections.singletonList(later)
        );

        assertEquals(
                java.util.Arrays.asList(earlier, later),
                InteractiveBattleRegistry.combatSelectableIds(metadata)
        );
    }

    @Test
    void combatOptionsRejectMalformedEngineMetadata() {
        Map<String, Object> wrongContainer = new HashMap<>();
        wrongContainer.put("possibleAttackers", "not-a-list");
        assertThrows(
                IllegalArgumentException.class,
                () -> InteractiveBattleRegistry.combatSelectableIds(
                        wrongContainer
                )
        );

        Map<String, Object> wrongValue = new HashMap<>();
        wrongValue.put(
                "possibleBlockers",
                Collections.singletonList("not-a-uuid")
        );
        assertThrows(
                IllegalArgumentException.class,
                () -> InteractiveBattleRegistry.combatSelectableIds(
                        wrongValue
                )
        );
    }

    @Test
    void canonicalRequestHashMatchesTheBackendDefinition() {
        JsonObject nested = new JsonObject();
        nested.addProperty("b", true);
        nested.add("a", null);
        JsonArray list = new JsonArray();
        list.add(3);
        list.add("x");
        JsonObject request = new JsonObject();
        request.addProperty("z", 1);
        request.add("list", list);
        request.add("a", nested);
        request.addProperty("request_hash", "excluded-from-canonical-input");

        assertEquals(
                "4d1b4c9b71e840dd99f86933047dda7a"
                        + "b42d901b69698d7a3e5275a770412fef",
                InteractiveBattleRegistry.canonicalInteractiveRequestHash(
                        request
                )
        );

        nested.addProperty("request_hash", "nested-one");
        String nestedOne =
                InteractiveBattleRegistry.canonicalInteractiveRequestHash(
                        request
                );
        request.addProperty("request_hash", "different-root-value");
        assertEquals(
                nestedOne,
                InteractiveBattleRegistry.canonicalInteractiveRequestHash(
                        request
                )
        );
        nested.addProperty("request_hash", "nested-two");
        assertNotEquals(
                nestedOne,
                InteractiveBattleRegistry.canonicalInteractiveRequestHash(
                        request
                ),
                "only the root request_hash is excluded"
        );
    }

    @Test
    void acceptedActionReceiptContainsOnlyCorrelationMetadata() {
        JsonObject action = new JsonObject();
        action.addProperty(
                "schema_version",
                InteractiveBattleRegistry.ACTION_SCHEMA
        );
        action.addProperty("action_id", "accepted-action-1");
        action.addProperty("state_version", 4);
        action.addProperty("prompt_id", "p_abcdefghijklmnop");
        action.addProperty("response_kind", "delegate");
        action.addProperty("delegate", true);
        String fingerprint =
                InteractiveBattleRegistry.canonicalInteractiveActionHash(
                        action
                );
        InteractiveBattleRegistry.ActionReceipt receipt =
                new InteractiveBattleRegistry.ActionReceipt(
                        fingerprint,
                        "response",
                        4L
                );

        Map<String, Object> payload = receipt.payload("accepted-action-1");

        assertEquals(5, payload.size());
        assertEquals(
                InteractiveBattleRegistry.ACTION_RECEIPT_SCHEMA,
                payload.get("schema_version")
        );
        assertEquals("accepted-action-1", payload.get("action_id"));
        assertEquals(fingerprint, payload.get("request_fingerprint"));
        assertEquals("response", payload.get("kind"));
        assertEquals(4L, payload.get("accepted_state_version"));
        assertFalse(payload.containsKey("prompt"));
        assertFalse(payload.containsKey("private_state"));
        assertFalse(payload.containsKey("option_id"));
    }

    @Test
    void sessionRequestAcceptsCanonicalHashAndRejectsPayloadMutation() {
        JsonObject valid = interactiveRequest();
        InteractiveBattleRegistry.SessionRequest parsed =
                InteractiveBattleRegistry.SessionRequest.parse(valid);
        assertEquals(valid.get("request_hash").getAsString(), parsed.requestHash);

        JsonObject mutated = interactiveRequest();
        mutated.addProperty("max_turns", 2);
        IllegalArgumentException error = assertThrows(
                IllegalArgumentException.class,
                () -> InteractiveBattleRegistry.SessionRequest.parse(mutated)
        );
        assertEquals(
                "interactive request_hash does not match request payload",
                error.getMessage()
        );
    }

    private static JsonObject interactiveRequest() {
        JsonObject request = new JsonObject();
        request.addProperty(
                "schema_version",
                InteractiveBattleRegistry.REQUEST_SCHEMA
        );
        request.addProperty("request_id", "interactive-request-1");
        request.addProperty(
                "session_id",
                "11111111-1111-4111-8111-111111111111"
        );
        request.addProperty("expected_engine", "xmage");
        request.addProperty(
                "expected_engine_version",
                SidecarMain.XMAGE_VERSION
        );
        request.addProperty(
                "expected_engine_commit",
                SidecarMain.XMAGE_COMMIT
        );
        request.addProperty(
                "expected_engine_patch_commit",
                SidecarMain.XMAGE_PATCH_COMMIT
        );
        request.addProperty("ai_profile", SidecarMain.AI_PROFILE);
        request.addProperty("ttl_seconds", 600);
        request.addProperty("prompt_timeout_seconds", 60);
        request.addProperty("max_turns", 100);

        JsonObject deckA = interactiveDeck(
                "deck-a",
                "Deck A",
                "Isamaru, Hound of Konda",
                "Plains"
        );
        JsonObject deckB = interactiveDeck(
                "deck-b",
                "Deck B",
                "Krenko, Mob Boss",
                "Mountain"
        );
        request.add("deck_a", deckA);
        request.add("deck_b", deckB);

        JsonObject hashes = new JsonObject();
        hashes.addProperty(
                "schema_version",
                SidecarMain.DECK_HASH_SCHEMA
        );
        hashes.addProperty("algorithm", "sha256");
        hashes.addProperty(
                "deck_a",
                XmageBattleService.canonicalDeckHash(
                        XmageBattleService.DeckInput.parse(deckA, "deck_a")
                )
        );
        hashes.addProperty(
                "deck_b",
                XmageBattleService.canonicalDeckHash(
                        XmageBattleService.DeckInput.parse(deckB, "deck_b")
                )
        );
        request.add("deck_hashes", hashes);
        request.addProperty(
                "request_hash",
                InteractiveBattleRegistry.canonicalInteractiveRequestHash(
                        request
                )
        );
        return request;
    }

    private static JsonObject interactiveDeck(
            String id,
            String name,
            String commander,
            String land
    ) {
        JsonObject deck = new JsonObject();
        deck.addProperty("id", id);
        deck.addProperty("name", name);
        JsonArray cards = new JsonArray();
        cards.add(interactiveCard(commander, 1, true));
        cards.add(interactiveCard(land, 99, false));
        deck.add("cards", cards);
        return deck;
    }

    private static JsonObject interactiveCard(
            String name,
            int quantity,
            boolean commander
    ) {
        JsonObject card = new JsonObject();
        card.addProperty("name", name);
        card.addProperty("quantity", quantity);
        card.addProperty("is_commander", commander);
        return card;
    }

    private static final class StubCommandObject
            implements CommandObjectView {
        private final UUID id = UUID.randomUUID();
        private final String name;
        private final String setCode;
        private PlayableObjectStats playableStats;
        private boolean choosable;
        private boolean selected;

        private StubCommandObject(String name, String setCode) {
            this.name = name;
            this.setCode = setCode;
        }

        @Override
        public String getExpansionSetCode() {
            return setCode;
        }

        @Override
        public String getName() {
            return name;
        }

        @Override
        public UUID getId() {
            return id;
        }

        @Override
        public String getImageFileName() {
            return "";
        }

        @Override
        public int getImageNumber() {
            return 0;
        }

        @Override
        public List<String> getRules() {
            return Collections.emptyList();
        }

        @Override
        public boolean isPlayable() {
            return playableStats != null;
        }

        @Override
        public void setPlayableStats(PlayableObjectStats value) {
            playableStats = value;
        }

        @Override
        public PlayableObjectStats getPlayableStats() {
            return playableStats;
        }

        @Override
        public boolean isChoosable() {
            return choosable;
        }

        @Override
        public void setChoosable(boolean value) {
            choosable = value;
        }

        @Override
        public boolean isSelected() {
            return selected;
        }

        @Override
        public void setSelected(boolean value) {
            selected = value;
        }
    }
}
