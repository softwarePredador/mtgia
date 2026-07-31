package com.manaloom.xmage;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
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
}
