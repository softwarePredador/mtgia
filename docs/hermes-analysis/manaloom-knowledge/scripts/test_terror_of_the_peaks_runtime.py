#!/usr/bin/env python3
"""Focused runtime tests for Terror of the Peaks ETB power damage."""

from __future__ import annotations

import importlib.util
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_terror_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def creature(name, power=2, toughness=None, effect="creature"):
    return {
        "name": name,
        "effect": effect,
        "type_line": "Creature",
        "power": power,
        "toughness": toughness if toughness is not None else power,
    }


def terror_of_the_peaks():
    return {
        "name": "Terror of the Peaks",
        "effect": "creature",
        "type_line": "Creature — Dragon",
        "power": 5,
        "toughness": 4,
        "flying": True,
        "battle_model_scope": "controlled_other_creature_enters_power_damage_any_target_v1",
        "trigger": "creature_you_control_enters",
        "trigger_effect": "damage_any_target",
        "trigger_damage_amount_source": "entering_creature_power",
        "trigger_another_creature_you_control_enters": True,
        "target": "any_target",
        "target_constraints": {"scope": "any_target"},
        "opponent_spells_targeting_this_additional_life_cost": 3,
        "_rule_logical_key": "battle_rule_v1:terror_runtime_test",
        "_rule_oracle_hash": "terror-runtime-test-hash",
    }


def test_terror_of_the_peaks_etb_power_damage_can_finish_player():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        opponent.life = 6
        active.battlefield = [terror_of_the_peaks()]

        battle.create_creature_token(
            active,
            name="Six Power Token",
            power=6,
            toughness=6,
            opponents=[opponent],
            turn=5,
            all_players=[active, opponent],
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent.life == 0
    assert not opponent.is_alive()
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Terror of the Peaks"
        and data.get("trigger") == "creature_you_control_enters"
        and data.get("entering_creature") == "Six Power Token"
        and data.get("entering_creature_power") == 6
        and data.get("effect") == "damage_any_target"
        and data.get("target_player") == "Opponent"
        and data.get("result") == "player_damage"
        and data.get("amount") == 6
        and data.get("life_after") == 0
        for event, data in events
    )


def test_terror_of_the_peaks_etb_power_damage_kills_priority_creature_before_chip_damage():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        opponent.life = 40
        opponent.battlefield = [
            creature("Value Engine", power=2, toughness=4, effect="draw_engine"),
            creature("Large Creature", power=7, toughness=7),
        ]
        active.battlefield = [terror_of_the_peaks()]

        battle.create_creature_token(
            active,
            name="Four Power Token",
            power=4,
            toughness=4,
            opponents=[opponent],
            turn=6,
            all_players=[active, opponent],
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent.life == 40
    assert [card["name"] for card in opponent.battlefield] == ["Large Creature"]
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Terror of the Peaks"
        and data.get("entering_creature") == "Four Power Token"
        and data.get("target") == "Value Engine"
        and data.get("target_player") == "Opponent"
        and data.get("result") == "creature_destroyed"
        and data.get("destination") == "graveyard"
        for event, data in events
    )
