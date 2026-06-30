#!/usr/bin/env python3
"""Focused runtime tests for static damage replacement modifiers."""

from __future__ import annotations

import importlib.util
import random
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_static_damage_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def twinflame_tyrant():
    return {
        "name": "Twinflame Tyrant",
        "effect": "damage_modifier",
        "battle_model_scope": "controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1",
        "damage_modifier_applies_to": "sources_you_control",
        "damage_modifier_targets": ["opponents", "opponent_permanents"],
        "damage_modifier_duration": "while_on_battlefield",
        "damage_multiplier": 2,
        "type_line": "Creature - Dragon",
        "power": 3,
        "toughness": 5,
        "flying": True,
    }


def gisela_blade_of_goldnight():
    return {
        "name": "Gisela, Blade of Goldnight",
        "effect": "damage_modifier",
        "battle_model_scope": "opponent_or_opponent_permanent_damage_doubled_self_damage_halved_v1",
        "damage_modifier_applies_to": "any_source",
        "damage_modifier_targets": ["opponents", "opponent_permanents"],
        "damage_modifier_duration": "while_on_battlefield",
        "damage_multiplier": 2,
        "prevent_half_damage_to_you_and_permanents_you_control": True,
        "prevent_half_rounding": "rounded_up",
        "type_line": "Legendary Creature - Angel",
        "power": 5,
        "toughness": 5,
        "flying": True,
        "first_strike": True,
    }


def creature(name, toughness=4):
    return {
        "name": name,
        "effect": "creature",
        "type_line": "Creature",
        "power": toughness,
        "toughness": toughness,
    }


def test_twinflame_tyrant_doubles_damage_to_each_opponent():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent_a = player(battle, "Opponent A")
        opponent_b = player(battle, "Opponent B")
        active.battlefield = [twinflame_tyrant()]
        card = {"name": "Boltwave", "type_line": "Sorcery", "cmc": 1}
        effect_data = {
            "effect": "damage_each_opponent",
            "battle_model_scope": "spell_damage_each_opponent_v1",
            "amount": 3,
            "damage": 3,
            "target_controller": "opponents",
        }

        battle.apply_damage_each_opponent(active, [opponent_a, opponent_b], card, effect_data, turn=3)
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent_a.life == 34
    assert opponent_b.life == 34
    assert any(
        event == "static_damage_replacement_applied"
        and data.get("source") == "Boltwave"
        and data.get("original_amount") == 3
        and data.get("final_amount") == 6
        for event, data in events
    )
    assert any(
        event == "damage_each_opponent_resolved"
        and data.get("amount") == 6
        and all(entry.get("dealt") == 6 for entry in data.get("damage_results", []))
        for event, data in events
    )


def test_twinflame_tyrant_doubles_wipe_damage_only_to_opponent_permanents():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        own_survivor = creature("Own Four Toughness", toughness=4)
        opposing_creature = creature("Opposing Four Toughness", toughness=4)
        active.battlefield = [twinflame_tyrant(), own_survivor]
        opponent.battlefield = [opposing_creature]
        card = {"name": "Three Damage Wipe", "type_line": "Sorcery", "cmc": 4}
        effect_data = {
            "effect": "damage_wipe",
            "damage": 3,
            "damage_scope": "each_creature",
        }

        battle.apply_damage_wipe(active, [opponent], card, effect_data, turn=4)
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert own_survivor in active.battlefield
    assert opposing_creature not in opponent.battlefield
    replacement_events = [
        data for event, data in events if event == "static_damage_replacement_applied"
    ]
    assert any(
        data.get("target_controller") == "Opponent"
        and data.get("target") == "Opposing Four Toughness"
        and data.get("final_amount") == 6
        for data in replacement_events
    )
    assert not any(data.get("target_controller") == "Lorehold" for data in replacement_events)


def test_twinflame_tyrant_doubles_combat_damage_and_commander_damage():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        commander = {
            "name": "Lorehold Commander",
            "effect": "creature",
            "type_line": "Legendary Creature",
            "power": 3,
            "toughness": 3,
            "is_commander": True,
            "owner": "Lorehold",
        }
        active.battlefield = [twinflame_tyrant(), commander]

        battle.combat_damage_steps(
            active,
            [opponent],
            opponent,
            [commander],
            [(commander, [])],
            turn=5,
            rng=random.Random(5),
            all_players=[active, opponent],
            stack=battle.Stack(),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent.life == 34
    assert active.commander_damage[opponent.name] == 6
    assert any(
        event == "combat_result"
        and data.get("damage_to_player") == 6
        and data.get("target_life_after") == 34
        for event, data in events
    )


def test_twinflame_tyrant_does_not_double_opponent_source_damage_to_controller():
    battle = load_battle()
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    active.battlefield = [twinflame_tyrant()]
    source = {"name": "Opponent Shock", "type_line": "Instant", "effect": "direct_damage"}

    damage_dealt, final_amount, dealt = battle.deal_damage_to_player_with_static_replacements(
        opponent,
        active,
        source,
        3,
        turn=6,
        phase="resolution",
        damage_event_type="player",
    )

    assert dealt is True
    assert final_amount == 3
    assert damage_dealt == 3
    assert active.life == 37


def test_gisela_doubles_any_source_damage_to_opponents():
    battle = load_battle()
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    active.battlefield = [gisela_blade_of_goldnight()]
    source = {"name": "Lightning Bolt", "type_line": "Instant", "effect": "direct_damage", "owner": "Lorehold"}

    damage_dealt, final_amount, dealt = battle.deal_damage_to_player_with_static_replacements(
        active,
        opponent,
        source,
        3,
        turn=7,
        phase="resolution",
        damage_event_type="player",
    )

    assert dealt is True
    assert final_amount == 6
    assert damage_dealt == 6
    assert opponent.life == 34


def test_gisela_halves_damage_to_controller_rounded_up():
    battle = load_battle()
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    active.battlefield = [gisela_blade_of_goldnight()]
    source = {"name": "Opponent Blast", "type_line": "Instant", "effect": "direct_damage", "owner": "Opponent"}

    damage_dealt, final_amount, dealt = battle.deal_damage_to_player_with_static_replacements(
        opponent,
        active,
        source,
        5,
        turn=8,
        phase="resolution",
        damage_event_type="player",
    )

    assert dealt is True
    assert final_amount == 2
    assert damage_dealt == 2
    assert active.life == 38
