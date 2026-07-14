package com.manaloom.xmage;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

final class XmageBattleServiceTest {
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
        JsonObject unsupported = card("Molecule Man", 1, false);
        unsupported.addProperty("card_id", "unsupported-id");
        cards.add(unsupported);
        request.add("cards", cards);

        Map<String, Object> coverage = service.cardCoverage(request);
        List<Map<String, Object>> missing =
                (List<Map<String, Object>>) coverage.get("unsupported_cards");

        assertEquals(3, coverage.get("total"));
        assertEquals(2, coverage.get("supported"));
        assertEquals(1, coverage.get("unsupported"));
        assertEquals("unsupported-id", missing.get(0).get("card_id"));
        assertEquals(2, missing.get(0).get("input_index"));
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
}
