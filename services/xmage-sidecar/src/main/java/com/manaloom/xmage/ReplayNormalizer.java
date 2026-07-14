package com.manaloom.xmage;

import mage.view.CardView;
import mage.view.CombatGroupView;
import mage.view.CommandObjectView;
import mage.view.CounterView;
import mage.view.GameView;
import mage.view.PermanentView;
import mage.view.PlayerView;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

final class ReplayNormalizer {
    private static final Set<String> SEMANTIC_ACTIONS = new HashSet<>();

    static {
        Collections.addAll(
                SEMANTIC_ACTIONS,
                "zone_change",
                "stack_entry",
                "battlefield_entry",
                "visible_zone_entry",
                "visible_zone_exit",
                "controller_change",
                "tap_change",
                "damage_marked_change",
                "counter_change",
                "attacker_declared",
                "blocker_declared",
                "life_change"
        );
    }

    private ReplayNormalizer() {
    }

    static String fingerprint(GameView view) {
        StringBuilder result = new StringBuilder();
        result.append(view.getTurn()).append('|').append(view.getPhase()).append('|').append(view.getStep());
        result.append('|').append(view.getActivePlayerName());
        appendCardFingerprint(result, view.getStack().values());
        for (PlayerView player : sortedPlayers(view)) {
            result.append('|').append(player.getName())
                    .append(':').append(player.getLife())
                    .append(':').append(player.getLibraryCount())
                    .append(':').append(player.getHandCount())
                    .append(':').append(player.getBattlefield().size())
                    .append(':').append(player.getGraveyard().size())
                    .append(':').append(player.getExile().size());
            appendCardFingerprint(result, player.getBattlefield().values());
            appendCardFingerprint(result, player.getGraveyard().values());
            appendCardFingerprint(result, player.getExile().values());
            for (CommandObjectView card : player.getCommandObjectList()) {
                result.append(":command:").append(card.getId()).append(':').append(card.getName());
            }
        }
        for (CombatGroupView group : view.getCombat()) {
            result.append("|combat:").append(group.getDefenderId()).append(':').append(group.isBlocked());
            appendCardFingerprint(result, group.getAttackers().values());
            appendCardFingerprint(result, group.getBlockers().values());
        }
        return result.toString();
    }

    static List<Map<String, Object>> snapshots(List<GameView> views) {
        List<Map<String, Object>> snapshots = new ArrayList<>();
        int index = 0;
        for (GameView view : views) {
            Map<String, Object> snapshot = new LinkedHashMap<>();
            snapshot.put("index", index++);
            snapshot.put("turn", view.getTurn());
            snapshot.put("phase", view.getPhase() == null ? null : view.getPhase().toString());
            snapshot.put("step", view.getStep() == null ? null : view.getStep().toString());
            snapshot.put("active_player", view.getActivePlayerName());
            snapshot.put("priority_player", view.getPriorityPlayerName());

            List<Map<String, Object>> players = new ArrayList<>();
            for (PlayerView player : sortedPlayers(view)) {
                Map<String, Object> playerState = new LinkedHashMap<>();
                playerState.put("name", player.getName());
                playerState.put("life", player.getLife());
                playerState.put("library_count", player.getLibraryCount());
                playerState.put("library_size", player.getLibraryCount());
                playerState.put("hand_count", player.getHandCount());
                playerState.put("hand_size", player.getHandCount());
                playerState.put("has_left", player.hasLeft());
                playerState.put("battlefield", cards(player.getBattlefield().values()));
                playerState.put("graveyard", cards(player.getGraveyard().values()));
                playerState.put("graveyard_size", player.getGraveyard().size());
                playerState.put("exile", cards(player.getExile().values()));

                List<Map<String, Object>> command = new ArrayList<>();
                for (CommandObjectView card : player.getCommandObjectList()) {
                    command.add(commandCard(card));
                }
                sortCards(command);
                playerState.put("command", command);
                players.add(playerState);
            }
            snapshot.put("players", players);
            snapshot.put("stack", cards(view.getStack().values()));

            List<Map<String, Object>> combat = new ArrayList<>();
            for (CombatGroupView group : view.getCombat()) {
                Map<String, Object> groupState = new LinkedHashMap<>();
                groupState.put("defender_id", id(group.getDefenderId()));
                groupState.put("defender_name", group.getDefenderName());
                groupState.put("blocked", group.isBlocked());
                groupState.put("attackers", cards(group.getAttackers().values()));
                groupState.put("blockers", cards(group.getBlockers().values()));
                combat.add(groupState);
            }
            snapshot.put("combat", combat);
            snapshots.add(snapshot);
        }
        return snapshots;
    }

    static List<Map<String, Object>> events(
            List<Map<String, Object>> messages,
            List<Map<String, Object>> snapshots
    ) {
        List<Map<String, Object>> events = new ArrayList<>();
        for (Map<String, Object> message : messages) {
            events.add(new LinkedHashMap<>(message));
        }

        Map<String, ZoneCard> previousZones = Collections.emptyMap();
        Map<String, Integer> previousLife = Collections.emptyMap();
        Map<String, CombatCard> previousAttackers = Collections.emptyMap();
        Map<String, CombatCard> previousBlockers = Collections.emptyMap();
        boolean initialized = false;
        for (Map<String, Object> snapshot : snapshots) {
            Map<String, ZoneCard> zones = zones(snapshot);
            if (initialized) {
                for (Map.Entry<String, ZoneCard> entry : zones.entrySet()) {
                    ZoneCard before = previousZones.get(entry.getKey());
                    ZoneCard after = entry.getValue();
                    if (before == null) {
                        events.add(visibleEntryEvent(snapshot, after));
                    } else {
                        if (!before.zone.equals(after.zone)) {
                            Map<String, Object> event = cardEvent(snapshot, "zone_change", after);
                            event.put("from_zone", before.zone);
                            event.put("to_zone", after.zone);
                            events.add(event);
                        }
                        if (!before.player.equals(after.player)) {
                            Map<String, Object> event = cardEvent(snapshot, "controller_change", after);
                            event.put("from_player", before.player);
                            event.put("to_player", after.player);
                            events.add(event);
                        }
                        if ("battlefield".equals(before.zone) && "battlefield".equals(after.zone)) {
                            addPermanentStateEvents(events, snapshot, before, after);
                        }
                    }
                }
                for (Map.Entry<String, ZoneCard> entry : previousZones.entrySet()) {
                    if (zones.containsKey(entry.getKey())) {
                        continue;
                    }
                    ZoneCard before = entry.getValue();
                    Map<String, Object> event = cardEvent(snapshot, "visible_zone_exit", before);
                    event.put("from_zone", before.zone);
                    event.put("learning_grade", "visible_activity_only_destination_unknown");
                    events.add(event);
                }
            }

            Map<String, Integer> life = life(snapshot);
            for (Map.Entry<String, Integer> entry : life.entrySet()) {
                Integer before = previousLife.get(entry.getKey());
                if (before != null && !before.equals(entry.getValue())) {
                    Map<String, Object> event = eventContext(snapshot, "life_change");
                    event.put("player", entry.getKey());
                    event.put("from", before);
                    event.put("to", entry.getValue());
                    events.add(event);
                }
            }

            Map<String, CombatCard> attackers = combatCards(snapshot, "attackers");
            Map<String, CombatCard> blockers = combatCards(snapshot, "blockers");
            if (initialized) {
                addCombatEvents(events, snapshot, previousAttackers, attackers, "attacker_declared");
                addCombatEvents(events, snapshot, previousBlockers, blockers, "blocker_declared");
            }
            previousZones = zones;
            previousLife = life;
            previousAttackers = attackers;
            previousBlockers = blockers;
            initialized = true;
        }

        events.sort(Comparator.comparingInt(ReplayNormalizer::eventTurn));
        for (int index = 0; index < events.size(); index++) {
            events.get(index).put("index", index);
        }
        return events;
    }

    static boolean isSemanticAction(String action) {
        return SEMANTIC_ACTIONS.contains(action);
    }

    private static Map<String, Object> visibleEntryEvent(Map<String, Object> snapshot, ZoneCard after) {
        String action;
        if ("stack".equals(after.zone)) {
            action = "stack_entry";
        } else if ("battlefield".equals(after.zone)) {
            action = "battlefield_entry";
        } else {
            action = "visible_zone_entry";
        }
        Map<String, Object> event = cardEvent(snapshot, action, after);
        event.put("to_zone", after.zone);
        if ("stack".equals(after.zone)) {
            event.put(
                    "stack_object_kind",
                    Boolean.TRUE.equals(after.card.get("is_ability")) ? "ability" : "spell"
            );
        }
        event.put("learning_grade", "visible_activity_only");
        return event;
    }

    private static Map<String, Object> cardEvent(
            Map<String, Object> snapshot,
            String action,
            ZoneCard zoneCard
    ) {
        Map<String, Object> event = eventContext(snapshot, action);
        if (!zoneCard.player.isEmpty()) {
            event.put("player", zoneCard.player);
        }
        event.put("card", zoneCard.card);
        event.put("card_id", zoneCard.card.get("id"));
        event.put("card_name", zoneCard.card.get("name"));
        return event;
    }

    private static void addPermanentStateEvents(
            List<Map<String, Object>> events,
            Map<String, Object> snapshot,
            ZoneCard before,
            ZoneCard after
    ) {
        addStateEvent(events, snapshot, before, after, "tapped", "tap_change");
        addStateEvent(events, snapshot, before, after, "damage", "damage_marked_change");
        addStateEvent(events, snapshot, before, after, "counters", "counter_change");
    }

    private static void addStateEvent(
            List<Map<String, Object>> events,
            Map<String, Object> snapshot,
            ZoneCard before,
            ZoneCard after,
            String field,
            String action
    ) {
        Object oldValue = before.card.get(field);
        Object newValue = after.card.get(field);
        if (Objects.equals(oldValue, newValue)) {
            return;
        }
        Map<String, Object> event = cardEvent(snapshot, action, after);
        event.put("from", oldValue);
        event.put("to", newValue);
        event.put("learning_grade", "state_transition_only");
        events.add(event);
    }

    private static void addCombatEvents(
            List<Map<String, Object>> events,
            Map<String, Object> snapshot,
            Map<String, CombatCard> previous,
            Map<String, CombatCard> current,
            String action
    ) {
        for (Map.Entry<String, CombatCard> entry : current.entrySet()) {
            if (previous.containsKey(entry.getKey())) {
                continue;
            }
            CombatCard combatCard = entry.getValue();
            Map<String, Object> event = eventContext(snapshot, action);
            event.put("card", combatCard.card);
            event.put("card_id", combatCard.card.get("id"));
            event.put("card_name", combatCard.card.get("name"));
            event.put("defender_id", combatCard.defenderId);
            event.put("defender_name", combatCard.defenderName);
            event.put("learning_grade", "visible_combat_activity");
            events.add(event);
        }
    }

    @SuppressWarnings("unchecked")
    private static Map<String, ZoneCard> zones(Map<String, Object> snapshot) {
        Map<String, ZoneCard> result = new HashMap<>();
        for (Map<String, Object> player : (List<Map<String, Object>>) snapshot.get("players")) {
            String playerName = String.valueOf(player.get("name"));
            for (String zone : new String[]{"battlefield", "graveyard", "exile", "command"}) {
                for (Map<String, Object> card : (List<Map<String, Object>>) player.get(zone)) {
                    Object id = card.get("id");
                    if (id != null) {
                        result.put(String.valueOf(id), new ZoneCard(playerName, zone, card));
                    }
                }
            }
        }
        Object stackValue = snapshot.get("stack");
        if (stackValue instanceof List) {
            for (Map<String, Object> card : (List<Map<String, Object>>) stackValue) {
                Object id = card.get("id");
                if (id != null) {
                    result.put(String.valueOf(id), new ZoneCard("", "stack", card));
                }
            }
        }
        return result;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, CombatCard> combatCards(Map<String, Object> snapshot, String role) {
        Map<String, CombatCard> result = new HashMap<>();
        Object combatValue = snapshot.get("combat");
        if (!(combatValue instanceof List)) {
            return result;
        }
        for (Map<String, Object> group : (List<Map<String, Object>>) combatValue) {
            Object cardsValue = group.get(role);
            if (!(cardsValue instanceof List)) {
                continue;
            }
            for (Map<String, Object> card : (List<Map<String, Object>>) cardsValue) {
                Object id = card.get("id");
                if (id != null) {
                    result.put(
                            String.valueOf(id),
                            new CombatCard(
                                    card,
                                    group.get("defender_id"),
                                    group.get("defender_name")
                            )
                    );
                }
            }
        }
        return result;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Integer> life(Map<String, Object> snapshot) {
        Map<String, Integer> result = new HashMap<>();
        for (Map<String, Object> player : (List<Map<String, Object>>) snapshot.get("players")) {
            result.put(String.valueOf(player.get("name")), ((Number) player.get("life")).intValue());
        }
        return result;
    }

    private static Map<String, Object> eventContext(Map<String, Object> snapshot, String action) {
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("action", action);
        event.put("turn", snapshot.get("turn"));
        event.put("phase", snapshot.get("phase"));
        event.put("step", snapshot.get("step"));
        event.put("active_player", snapshot.get("active_player"));
        return event;
    }

    private static int eventTurn(Map<String, Object> event) {
        Object turn = event.get("turn");
        return turn instanceof Number ? ((Number) turn).intValue() : 0;
    }

    private static List<PlayerView> sortedPlayers(GameView view) {
        List<PlayerView> players = new ArrayList<>(view.getPlayers());
        players.sort(Comparator.comparing(PlayerView::getName));
        return players;
    }

    private static List<Map<String, Object>> cards(Iterable<? extends CardView> cards) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (CardView card : cards) {
            result.add(card(card));
        }
        sortCards(result);
        return result;
    }

    private static void sortCards(List<Map<String, Object>> cards) {
        cards.sort(Comparator.comparing(card -> String.valueOf(card.get("id"))));
    }

    private static Map<String, Object> card(CardView card) {
        Map<String, Object> result = new LinkedHashMap<>();
        UUID id = card.getId();
        result.put("id", id == null ? null : id.toString());
        result.put("name", card.getName());
        result.put("set_code", card.getExpansionSetCode());
        result.put("card_number", card.getCardNumber());
        result.put("is_ability", card.isAbility());
        result.put("object_type", String.valueOf(card.getMageObjectType()));
        if (card instanceof PermanentView) {
            PermanentView permanent = (PermanentView) card;
            result.put("tapped", permanent.isTapped());
            result.put("damage", permanent.getDamage());
            result.put("controller_name", permanent.getNameController());
            result.put("counters", counters(permanent.getCounters()));
        }
        return result;
    }

    private static List<Map<String, Object>> counters(List<CounterView> counters) {
        List<Map<String, Object>> result = new ArrayList<>();
        if (counters == null) {
            return result;
        }
        for (CounterView counter : counters) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("name", counter.getName());
            row.put("count", counter.getCount());
            result.add(row);
        }
        result.sort(Comparator.comparing(counter -> String.valueOf(counter.get("name"))));
        return result;
    }

    private static void appendCardFingerprint(
            StringBuilder result,
            Iterable<? extends CardView> cards
    ) {
        List<Map<String, Object>> normalized = ReplayNormalizer.cards(cards);
        for (Map<String, Object> card : normalized) {
            result.append(":card:").append(card.get("id"))
                    .append(':').append(card.get("name"))
                    .append(':').append(card.get("tapped"))
                    .append(':').append(card.get("damage"))
                    .append(':').append(card.get("counters"));
        }
    }

    private static String id(UUID id) {
        return id == null ? null : id.toString();
    }

    private static Map<String, Object> commandCard(CommandObjectView card) {
        Map<String, Object> result = new LinkedHashMap<>();
        UUID id = card.getId();
        result.put("id", id == null ? null : id.toString());
        result.put("name", card.getName());
        result.put("set_code", card.getExpansionSetCode());
        return result;
    }

    private static final class ZoneCard {
        final String player;
        final String zone;
        final Map<String, Object> card;

        ZoneCard(String player, String zone, Map<String, Object> card) {
            this.player = player;
            this.zone = zone;
            this.card = card;
        }
    }

    private static final class CombatCard {
        final Map<String, Object> card;
        final Object defenderId;
        final Object defenderName;

        CombatCard(Map<String, Object> card, Object defenderId, Object defenderName) {
            this.card = card;
            this.defenderId = defenderId;
            this.defenderName = defenderName;
        }
    }
}
