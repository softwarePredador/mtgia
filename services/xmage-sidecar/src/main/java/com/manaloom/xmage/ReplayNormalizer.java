package com.manaloom.xmage;

import mage.view.CardView;
import mage.view.CommandObjectView;
import mage.view.GameView;
import mage.view.PermanentView;
import mage.view.PlayerView;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

final class ReplayNormalizer {
    private ReplayNormalizer() {
    }

    static String fingerprint(GameView view) {
        StringBuilder result = new StringBuilder();
        result.append(view.getTurn()).append('|').append(view.getPhase()).append('|').append(view.getStep());
        result.append('|').append(view.getActivePlayerName()).append('|').append(view.getStack().size());
        for (PlayerView player : sortedPlayers(view)) {
            result.append('|').append(player.getName())
                    .append(':').append(player.getLife())
                    .append(':').append(player.getLibraryCount())
                    .append(':').append(player.getHandCount())
                    .append(':').append(player.getBattlefield().size())
                    .append(':').append(player.getGraveyard().size())
                    .append(':').append(player.getExile().size());
            for (PermanentView permanent : player.getBattlefield().values()) {
                result.append(':').append(permanent.getId());
            }
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
                playerState.put("command", command);
                players.add(playerState);
            }
            snapshot.put("players", players);
            snapshot.put("stack", cards(view.getStack().values()));
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
        for (Map<String, Object> snapshot : snapshots) {
            Map<String, ZoneCard> zones = zones(snapshot);
            for (Map.Entry<String, ZoneCard> entry : zones.entrySet()) {
                ZoneCard before = previousZones.get(entry.getKey());
                ZoneCard after = entry.getValue();
                if (before != null && !before.zone.equals(after.zone)) {
                    Map<String, Object> event = eventContext(snapshot, "zone_change");
                    event.put("player", after.player);
                    event.put("card", after.card);
                    event.put("card_name", after.card.get("name"));
                    event.put("from_zone", before.zone);
                    event.put("to_zone", after.zone);
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
            previousZones = zones;
            previousLife = life;
        }

        events.sort(Comparator.comparingInt(ReplayNormalizer::eventTurn));
        for (int index = 0; index < events.size(); index++) {
            events.get(index).put("index", index);
        }
        return events;
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
                        result.put(playerName + '|' + id, new ZoneCard(playerName, zone, card));
                    }
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
        return result;
    }

    private static Map<String, Object> card(CardView card) {
        Map<String, Object> result = new LinkedHashMap<>();
        UUID id = card.getId();
        result.put("id", id == null ? null : id.toString());
        result.put("name", card.getName());
        result.put("set_code", card.getExpansionSetCode());
        result.put("card_number", card.getCardNumber());
        if (card instanceof PermanentView) {
            result.put("tapped", ((PermanentView) card).isTapped());
        }
        return result;
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
}
