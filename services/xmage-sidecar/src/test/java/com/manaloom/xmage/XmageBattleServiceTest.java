package com.manaloom.xmage;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

final class XmageBattleServiceTest {
    @Test
    void sidecarPublishesAProcessIdentityAndAcceptsGlobalCorpusPayloads() {
        assertEquals(8 * 1024 * 1024, SidecarMain.MAX_REQUEST_BYTES);
        assertNotNull(SidecarMain.PROCESS_ID);
        assertFalse(SidecarMain.PROCESS_ID.trim().isEmpty());
        assertNotNull(SidecarMain.STARTED_AT);
    }

    @Test
    void simulationTimeoutUsesTheSameBoundsAsTheBattleService() {
        JsonObject request = new JsonObject();
        assertEquals(120000L, SidecarMain.simulationTimeoutMillis(request));

        request.addProperty("timeout_ms", 0L);
        assertEquals(1000L, SidecarMain.simulationTimeoutMillis(request));

        request.addProperty("timeout_ms", 45000L);
        assertEquals(45000L, SidecarMain.simulationTimeoutMillis(request));

        request.addProperty("timeout_ms", 1000000L);
        assertEquals(900000L, SidecarMain.simulationTimeoutMillis(request));
    }

    @Test
    void connectionUsernameAlwaysHasASafeSuffix() {
        assertEquals("ml_request", XmageBattleService.connectionUsername("---"));
        assertEquals("ml_abc12345", XmageBattleService.connectionUsername("abc-12345-xyz"));
        assertEquals("ml_request", XmageBattleService.connectionUsername(null));
    }

    @Test
    void unicodeIdentityAliasesResolveOnlyWhenTheCatalogKeyIsUnique() {
        assertEquals(
                "ratonhnhaketon",
                XmageBattleService.identityAliasKey("Ratonhnhak\u00e9\ua789ton")
        );

        Set<String> names = new HashSet<>(Arrays.asList(
                "Ratonhnhaketon",
                "Fire // Ice",
                "Fire-Ice",
                "Sol Ring"
        ));
        Map<String, String> aliases = XmageBattleService.buildUniqueCardAliases(names);

        assertEquals("Ratonhnhaketon", aliases.get("ratonhnhaketon"));
        assertEquals("Sol Ring", aliases.get("solring"));
        assertFalse(aliases.containsKey("fireice"));
    }

    @Test
    @SuppressWarnings("unchecked")
    void coverageReportsUnsupportedCardsWithoutDroppingThem() {
        XmageBattleService service = new XmageBattleService("127.0.0.1", 17171);
        JsonObject request = new JsonObject();
        request.add("deck_a", deck(
                "unsupported-deck",
                card("Molecule Man", 1, true),
                card("Mountain", 99, false)
        ));
        request.add("deck_b", deck(
                "supported-deck",
                card("Korvold, Fae-Cursed King", 1, true),
                card("Forest", 99, false)
        ));

        Map<String, Object> coverage = service.coverage(request);
        List<Map<String, Object>> unsupported =
                (List<Map<String, Object>>) coverage.get("unsupported_cards");

        assertFalse((Boolean) coverage.get("ready"));
        assertEquals("unsupported", coverage.get("status"));
        assertEquals(1, unsupported.size());
        assertEquals("deck_a", unsupported.get(0).get("deck_key"));
        assertEquals("Molecule Man", unsupported.get(0).get("name"));
        assertEquals(2, ((List<?>) coverage.get("decks")).size());
    }

    @Test
    @SuppressWarnings("unchecked")
    void cardCoverageSupportsCatalogBatchesWithoutDeckShape() {
        XmageBattleService service = new XmageBattleService("127.0.0.1", 17171);
        JsonObject request = new JsonObject();
        JsonArray cards = new JsonArray();
        JsonObject supported = card("Sol Ring", 1, false);
        supported.addProperty("card_id", "supported-id");
        cards.add(supported);
        JsonObject split = card("Fire // Ice", 1, false);
        split.addProperty("card_id", "split-id");
        cards.add(split);
        JsonObject unicodeAlias = card("Ratonhnhak\u00e9\ua789ton", 1, false);
        unicodeAlias.addProperty("card_id", "unicode-alias-id");
        cards.add(unicodeAlias);
        JsonObject unsupported = card("Molecule Man", 1, false);
        unsupported.addProperty("card_id", "unsupported-id");
        cards.add(unsupported);
        request.add("cards", cards);

        Map<String, Object> coverage = service.cardCoverage(request);
        List<Map<String, Object>> missing =
                (List<Map<String, Object>>) coverage.get("unsupported_cards");

        assertEquals(4, coverage.get("total"));
        assertEquals(3, coverage.get("supported"));
        assertEquals(1, coverage.get("unsupported"));
        assertEquals("unsupported-id", missing.get(0).get("card_id"));
        assertEquals(3, missing.get(0).get("input_index"));
    }

    @Test
    void replayEventsExposeVisibleCardActivityWithoutInventingHiddenDraws() {
        Map<String, Object> solRingUntapped = replayCard("sol", "Sol Ring", false);
        Map<String, Object> goblin = replayCard("goblin", "Goblin Token", false);
        Map<String, Object> initial = replaySnapshot(
                Arrays.asList(solRingUntapped, goblin),
                Collections.emptyList(),
                Collections.emptyList()
        );

        Map<String, Object> solRingTapped = replayCard("sol", "Sol Ring", true);
        Map<String, Object> lightningBolt = replayCard("bolt", "Lightning Bolt", false);
        Map<String, Object> activatedAbility = replayCard("ability", "Ability", false);
        activatedAbility.put("is_ability", true);
        activatedAbility.put("source_card_id", "krenko");
        activatedAbility.put("source_card_name", "Krenko, Mob Boss");
        Map<String, Object> combatGroup = new LinkedHashMap<>();
        combatGroup.put("defender_id", "deck_b");
        combatGroup.put("defender_name", "deck_b");
        combatGroup.put("attackers", Collections.singletonList(goblin));
        combatGroup.put("blockers", Collections.emptyList());
        Map<String, Object> active = replaySnapshot(
                Arrays.asList(solRingTapped, goblin),
                Arrays.asList(lightningBolt, activatedAbility),
                Collections.singletonList(combatGroup)
        );

        List<Map<String, Object>> events = ReplayNormalizer.events(
                Collections.emptyList(),
                Arrays.asList(initial, active)
        );

        assertTrue(hasAction(events, "tap_change", "Sol Ring"));
        assertTrue(hasAction(events, "stack_entry", "Lightning Bolt"));
        assertTrue(hasAction(events, "attacker_declared", "Goblin Token"));
        assertFalse(hasAction(events, "battlefield_entry", "Sol Ring"));
        assertFalse(events.stream().anyMatch(event -> "draw".equals(event.get("action"))));
        Map<String, Object> stackEntry = events.stream()
                .filter(event -> "stack_entry".equals(event.get("action")))
                .findFirst()
                .orElseThrow(AssertionError::new);
        assertEquals("spell", stackEntry.get("stack_object_kind"));
        assertEquals("visible_activity_only", stackEntry.get("learning_grade"));
        Map<String, Object> abilityEntry = events.stream()
                .filter(event -> "ability".equals(event.get("stack_object_kind")))
                .findFirst()
                .orElseThrow(AssertionError::new);
        assertEquals("Krenko, Mob Boss", abilityEntry.get("source_card_name"));
    }

    private static JsonObject deck(String name, JsonObject... cards) {
        JsonObject deck = new JsonObject();
        deck.addProperty("id", name);
        deck.addProperty("name", name);
        JsonArray rows = new JsonArray();
        for (JsonObject card : cards) {
            rows.add(card);
        }
        deck.add("cards", rows);
        return deck;
    }

    private static JsonObject card(String name, int quantity, boolean commander) {
        JsonObject card = new JsonObject();
        card.addProperty("name", name);
        card.addProperty("quantity", quantity);
        card.addProperty("is_commander", commander);
        return card;
    }

    private static Map<String, Object> replayCard(String id, String name, boolean tapped) {
        Map<String, Object> card = new LinkedHashMap<>();
        card.put("id", id);
        card.put("name", name);
        card.put("is_ability", false);
        card.put("tapped", tapped);
        card.put("damage", 0);
        card.put("counters", Collections.emptyList());
        return card;
    }

    private static Map<String, Object> replaySnapshot(
            List<Map<String, Object>> battlefield,
            List<Map<String, Object>> stack,
            List<Map<String, Object>> combat
    ) {
        Map<String, Object> player = new LinkedHashMap<>();
        player.put("name", "deck_a");
        player.put("life", 40);
        player.put("battlefield", battlefield);
        player.put("graveyard", new ArrayList<>());
        player.put("exile", new ArrayList<>());
        player.put("command", new ArrayList<>());

        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("turn", 1);
        snapshot.put("phase", "COMBAT");
        snapshot.put("step", "DECLARE_ATTACKERS");
        snapshot.put("active_player", "deck_a");
        snapshot.put("players", Collections.singletonList(player));
        snapshot.put("stack", stack);
        snapshot.put("combat", combat);
        return snapshot;
    }

    private static boolean hasAction(
            List<Map<String, Object>> events,
            String action,
            String cardName
    ) {
        return events.stream().anyMatch(event ->
                action.equals(event.get("action")) && cardName.equals(event.get("card_name"))
        );
    }
}
