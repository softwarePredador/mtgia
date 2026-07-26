package com.manaloom.xmage;

import com.google.gson.Gson;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

final class BattleLiveRegistryTest {
    private static final Gson GSON = new Gson();

    @Test
    @SuppressWarnings("unchecked")
    void publishesBoundedIncrementalRecordsAndDeduplicatesPollingSnapshots() {
        BattleLiveRegistry registry = new BattleLiveRegistry(2, 8, 60000L);
        registry.begin("battle-job-123");

        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("index", 0);
        snapshot.put("turn", 1);
        Map<String, Object> player = new LinkedHashMap<>();
        player.put("name", "deck_a");
        player.put("hand", Collections.singletonList("private-card"));
        player.put("hand_size", 7);
        player.put("library", Collections.singletonList("private-top-card"));
        player.put("library_size", 92);
        player.put("battlefield", Collections.singletonList("public-permanent"));
        snapshot.put("players", Collections.singletonList(player));
        snapshot.put("decision_options", Collections.singletonList("private-option"));

        Map<String, Object> event = new LinkedHashMap<>();
        event.put("index", 0);
        event.put("action", "life_change");
        event.put("turn", 1);
        event.put("player", "deck_a");
        event.put("from", 40);
        event.put("to", 38);

        registry.publish(
                "battle-job-123",
                Collections.singletonList(snapshot),
                Collections.singletonList(event)
        );
        registry.publish(
                "battle-job-123",
                Collections.singletonList(snapshot),
                Collections.singletonList(event)
        );

        Map<String, Object> body = registry.read("battle-job-123");
        assertNotNull(body);
        assertEquals(BattleLiveRegistry.SCHEMA, body.get("live_schema_version"));
        assertEquals("running", body.get("status"));
        assertFalse((Boolean) body.get("terminal"));
        List<Map<String, Object>> records =
                (List<Map<String, Object>>) body.get("records");
        assertEquals(2, records.size());
        assertEquals(0, records.get(0).get("sequence"));
        assertEquals(1, records.get(1).get("sequence"));

        String encoded = GSON.toJson(body);
        assertFalse(encoded.contains("private-card"));
        assertFalse(encoded.contains("private-top-card"));
        assertFalse(encoded.contains("private-option"));
        assertTrue(encoded.contains("\"hand_size\":7"));
        assertTrue(encoded.contains("\"library_size\":92"));
        assertTrue(encoded.contains("\"battlefield_count\":1"));
        Map<String, Object> metrics = registry.metrics();
        assertEquals(1, metrics.get("stream_count"));
        assertEquals(2, metrics.get("record_count"));
        assertEquals(0, metrics.get("truncated_stream_count"));

        Map<String, Object> firstPage = registry.read("battle-job-123", -1, 1);
        assertEquals(1, firstPage.get("page_record_count"));
        assertEquals(0, firstPage.get("next_after_sequence"));
        assertTrue((Boolean) firstPage.get("has_more"));
        Map<String, Object> secondPage = registry.read("battle-job-123", 0, 1);
        assertEquals(1, secondPage.get("page_record_count"));
        assertEquals(1, secondPage.get("next_after_sequence"));
        assertFalse((Boolean) secondPage.get("has_more"));
    }

    @Test
    @SuppressWarnings("unchecked")
    void preservesLegitimateRepeatedEventsWithoutRepublishingOldOccurrences() {
        BattleLiveRegistry registry = new BattleLiveRegistry(2, 8, 60000L);
        registry.begin("battle-job-repeat");
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("action", "tap_change");
        event.put("turn", 2);
        event.put("card_name", "Sol Ring");

        registry.publish(
                "battle-job-repeat",
                Collections.emptyList(),
                Collections.singletonList(event)
        );
        registry.publish(
                "battle-job-repeat",
                Collections.emptyList(),
                Arrays.asList(event, event)
        );
        registry.publish(
                "battle-job-repeat",
                Collections.emptyList(),
                Arrays.asList(event, event)
        );

        List<Map<String, Object>> records =
                (List<Map<String, Object>>) registry.read("battle-job-repeat").get("records");
        assertEquals(2, records.size());
    }

    @Test
    @SuppressWarnings("unchecked")
    void terminalStreamIsImmutableAndReportsExplicitOutcome() {
        BattleLiveRegistry registry = new BattleLiveRegistry(2, 8, 60000L);
        registry.begin("battle-job-terminal");
        registry.finish("battle-job-terminal", "timeout", "simulation timeout");

        Map<String, Object> late = new LinkedHashMap<>();
        late.put("turn", 99);
        registry.publish(
                "battle-job-terminal",
                Collections.singletonList(late),
                Collections.emptyList()
        );

        Map<String, Object> body = registry.read("battle-job-terminal");
        assertEquals("timeout", body.get("status"));
        assertEquals("simulation_timeout", body.get("terminal_reason"));
        assertTrue((Boolean) body.get("terminal"));
        assertTrue(((List<Map<String, Object>>) body.get("records")).isEmpty());
    }

    @Test
    @SuppressWarnings("unchecked")
    void recordBudgetTruncatesFailClosedWithoutGrowingTheBuffer() {
        BattleLiveRegistry registry = new BattleLiveRegistry(2, 2, 60000L);
        registry.begin("battle-job-bounded");
        Map<String, Object> first = new LinkedHashMap<>();
        first.put("index", 0);
        Map<String, Object> second = new LinkedHashMap<>();
        second.put("index", 1);
        Map<String, Object> third = new LinkedHashMap<>();
        third.put("index", 2);

        registry.publish(
                "battle-job-bounded",
                Arrays.asList(first, second, third),
                Collections.emptyList()
        );

        Map<String, Object> body = registry.read("battle-job-bounded");
        assertTrue((Boolean) body.get("source_truncated"));
        assertEquals(2, ((List<Map<String, Object>>) body.get("records")).size());
        assertEquals(1, registry.metrics().get("truncated_stream_count"));
    }

    @Test
    void rejectsUnsafeIdsAndUnknownStreams() {
        BattleLiveRegistry registry = new BattleLiveRegistry(2, 8, 60000L);
        assertThrows(IllegalArgumentException.class, () -> registry.begin("unsafe:id"));
        assertThrows(
                IllegalArgumentException.class,
                () -> registry.read("missing-stream", -2, 50)
        );
        assertThrows(
                IllegalArgumentException.class,
                () -> registry.read("missing-stream", -1, 501)
        );
        assertNull(registry.read("missing-stream"));
    }
}
