#!/usr/bin/env python3
"""Focused runtime tests for Firesong and Sunspeaker."""

from __future__ import annotations

import importlib.util
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_firesong_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def firesong_and_sunspeaker():
    return {
        "name": "Firesong and Sunspeaker",
        "effect": "creature",
        "type_line": "Legendary Creature - Minotaur Cleric",
        "mana_cost": "{4}{R}{W}",
        "colors": ["R", "W"],
        "power": 4,
        "toughness": 6,
        "battle_model_scope": "red_instant_sorcery_lifelink_white_lifegain_damage_v1",
        "instant_sorcery_spells_you_control_have_lifelink": True,
        "instant_sorcery_lifelink_colors": ["R"],
        "trigger": "white_instant_sorcery_lifegain",
        "trigger_effect": "damage_any_target",
        "white_instant_sorcery_lifegain_trigger_damage": 3,
        "target": "any_target",
        "target_constraints": {"scope": "any_target"},
        "_rule_logical_key": "battle_rule_v1:firesong_runtime_test",
        "_rule_oracle_hash": "firesong-runtime-test-hash",
    }


def direct_damage_spell(name, colors, mana_cost="{R}", gain_life=0):
    return {
        "name": name,
        "type_line": "Instant",
        "mana_cost": mana_cost,
        "colors": colors,
        "effect": "direct_damage",
        "damage": 3,
        "target": "player",
        "gain_life": gain_life,
    }


def test_firesong_grants_lifelink_to_red_instant_without_white_lifegain_trigger():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.life = 20
        opponent.life = 20
        active.battlefield = [firesong_and_sunspeaker()]

        bolt = direct_damage_spell("Lightning Bolt", ["R"])
        battle.apply_direct_damage(active, [opponent], bolt, bolt, turn=4, rng=None)
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert active.life == 23
    assert opponent.life == 17
    damage_events = [data for event, data in events if event == "damage_resolved"]
    assert damage_events[0]["spell_lifelink_life_gained"] == 3
    assert damage_events[0]["life_gained"] == 3
    assert damage_events[0]["spell_lifelink_sources"][0]["card"] == "Firesong and Sunspeaker"
    assert not any(
        event == "trigger_resolved"
        and data.get("card") == "Firesong and Sunspeaker"
        and data.get("trigger") == "white_instant_sorcery_lifegain"
        for event, data in events
    )


def test_firesong_white_instant_lifegain_triggers_three_damage():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.life = 20
        opponent.life = 20
        active.battlefield = [firesong_and_sunspeaker()]

        helix = direct_damage_spell(
            "Lightning Helix",
            ["R", "W"],
            mana_cost="{R}{W}",
            gain_life=3,
        )
        battle.apply_direct_damage(active, [opponent], helix, helix, turn=5, rng=None)
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert active.life == 26
    assert opponent.life == 14
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Firesong and Sunspeaker"
        and data.get("trigger") == "white_instant_sorcery_lifegain"
        and data.get("trigger_spell") == "Lightning Helix"
        and data.get("effect") == "damage_any_target"
        and data.get("life_gained") == 6
        and data.get("amount") == 3
        and data.get("target_player") == "Opponent"
        and data.get("result") == "player_damage"
        and data.get("life_after") == 14
        for event, data in events
    )
