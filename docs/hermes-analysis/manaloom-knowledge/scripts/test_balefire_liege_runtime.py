#!/usr/bin/env python3
"""Focused runtime tests for Balefire Liege spell-color triggers."""

from __future__ import annotations

import importlib.util
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_balefire_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def balefire_liege():
    return {
        "name": "Balefire Liege",
        "effect": "creature",
        "type_line": "Creature - Spirit Horror",
        "mana_cost": "{2}{R/W}{R/W}{R/W}",
        "colors": ["R", "W"],
        "power": 2,
        "toughness": 4,
        "battle_model_scope": "red_spell_damage_white_spell_lifegain_static_creature_boost_v1",
        "trigger": "spell_cast",
        "trigger_effect": "spell_color_damage_life",
        "red_spell_trigger_damage": 3,
        "red_spell_trigger_damage_target": "player_or_planeswalker",
        "white_spell_trigger_gain_life": 3,
        "static_boost_other_red_creatures_you_control": {"power": 1, "toughness": 1},
        "static_boost_other_white_creatures_you_control": {"power": 1, "toughness": 1},
        "_rule_logical_key": "battle_rule_v1:balefire_runtime_test",
        "_rule_oracle_hash": "balefire-runtime-test-hash",
    }


def spell(name, colors, mana_cost):
    return {
        "name": name,
        "effect": "direct_damage",
        "type_line": "Instant",
        "mana_cost": mana_cost,
        "colors": colors,
    }


def test_balefire_liege_red_spell_deals_three_to_target_player_or_planeswalker():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.life = 20
        opponent.life = 10
        active.battlefield = [balefire_liege()]
        opponent_creature = {
            "name": "Small Blocker",
            "effect": "creature",
            "type_line": "Creature",
            "power": 2,
            "toughness": 2,
        }
        opponent.battlefield = [opponent_creature]

        battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            spell("Lightning Bolt", ["R"], "{R}"),
            turn=4,
            phase="main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent.life == 7
    assert opponent_creature in opponent.battlefield
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Balefire Liege"
        and data.get("effect") == "damage_player_or_planeswalker"
        and data.get("trigger_spell_color") == "R"
        and data.get("amount") == 3
        and data.get("damage_dealt") == 3
        and data.get("target_player") == "Opponent"
        and data.get("result") == "player_damage"
        and data.get("life_before") == 10
        and data.get("life_after") == 7
        for event, data in events
    )


def test_balefire_liege_white_spell_gains_three_life():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.life = 20
        opponent.life = 10
        active.battlefield = [balefire_liege()]

        battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            spell("Reprieve", ["W"], "{1}{W}"),
            turn=5,
            phase="main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert active.life == 23
    assert opponent.life == 10
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Balefire Liege"
        and data.get("effect") == "gain_life"
        and data.get("trigger_spell_color") == "W"
        and data.get("life_gain_requested") == 3
        and data.get("life_gained") == 3
        and data.get("life_before") == 20
        and data.get("life_after") == 23
        for event, data in events
    )


def test_balefire_liege_red_white_spell_fires_both_triggers():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.life = 20
        opponent.life = 10
        active.battlefield = [balefire_liege()]

        battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            spell("Lightning Helix", ["R", "W"], "{R}{W}"),
            turn=6,
            phase="main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert active.life == 23
    assert opponent.life == 7
    balefire_events = [
        data
        for event, data in events
        if event == "trigger_resolved" and data.get("card") == "Balefire Liege"
    ]
    assert [data.get("trigger_spell_color") for data in balefire_events] == ["R", "W"]
    assert balefire_events[0]["effect"] == "damage_player_or_planeswalker"
    assert balefire_events[1]["effect"] == "gain_life"
