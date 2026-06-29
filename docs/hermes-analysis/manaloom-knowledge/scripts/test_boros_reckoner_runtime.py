#!/usr/bin/env python3
"""Focused runtime tests for Boros Reckoner-style damage reflection."""

from __future__ import annotations

import importlib.util
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_boros_reckoner_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def boros_reckoner(battle):
    card = {
        "name": "Boros Reckoner",
        "type_line": "Creature - Minotaur Wizard",
        "mana_cost": "{R/W}{R/W}{R/W}",
        "cmc": 3,
    }
    return {**card, **battle.get_card_effect(card)}


def damage_wipe(name, amount):
    return (
        {"name": name, "type_line": "Sorcery", "cmc": 2},
        {"effect": "damage_wipe", "damage": amount, "damage_scope": "each_creature"},
    )


def test_boros_reckoner_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(
        {
            "name": "Boros Reckoner",
            "type_line": "Creature - Minotaur Wizard",
            "mana_cost": "{R/W}{R/W}{R/W}",
            "cmc": 3,
        }
    )

    assert effect["effect"] == "creature"
    assert effect["battle_model_scope"] == "source_dealt_damage_reflect_to_any_target_v1"
    assert effect["trigger"] == "source_dealt_damage"
    assert effect["trigger_effect"] == "damage_any_target"
    assert effect["damage_amount_source"] == "damage_dealt_to_source"
    assert effect["source_damage_reflect_to_any_target"] is True
    assert effect["activated_gain_first_strike_until_eot"] is True
    assert effect["_rule_source"] == "curated"
    assert effect["_rule_logical_key"] == "battle_rule_v1:f344d0f95f1afcd03e9b0d840981aeef"
    assert effect["_rule_oracle_hash"] == "8cb6c980428b2501343f3f38dc686efb"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Boros Reckoner" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_boros_reckoner_reflects_damage_to_selected_any_target():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.battlefield = [boros_reckoner(battle)]
        spell, effect = damage_wipe("Pyroclasm", 2)

        battle.apply_damage_wipe(opponent, [active], spell, effect, turn=4)
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent.life == 38
    assert active.battlefield[0]["name"] == "Boros Reckoner"
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Boros Reckoner"
        and data.get("trigger") == "source_dealt_damage"
        and data.get("effect") == "damage_any_target"
        and data.get("source") == "Pyroclasm"
        and data.get("source_controller") == "Opponent"
        and data.get("damaged_creature") == "Boros Reckoner"
        and data.get("target_player") == "Opponent"
        and data.get("original_damage_to_source") == 2
        and data.get("amount") == 2
        and data.get("damage_dealt") == 2
        and data.get("result") == "player_damage"
        for event, data in events
    )


def test_boros_reckoner_reflection_uses_saved_damage_amount():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.battlefield = [boros_reckoner(battle)]
        spell, effect = damage_wipe("Blasphemous Act", 13)

        battle.apply_damage_wipe(opponent, [active], spell, effect, turn=7)
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent.life == 27
    assert active.battlefield == []
    trigger_events = [
        data
        for event, data in events
        if event == "trigger_resolved" and data.get("card") == "Boros Reckoner"
    ]
    assert len(trigger_events) == 1
    assert trigger_events[0]["original_damage_to_source"] == 13
    assert trigger_events[0]["amount"] == 13
    assert trigger_events[0]["damage_dealt"] == 13
