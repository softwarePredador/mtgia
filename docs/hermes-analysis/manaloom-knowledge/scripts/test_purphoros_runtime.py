#!/usr/bin/env python3
"""Focused runtime tests for Purphoros ETB damage engine."""

from __future__ import annotations

import importlib.util
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_purphoros_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def purphoros_effect() -> dict:
    return {
        "effect": "passive",
        "ability_kind": "triggered",
        "battle_model_scope": "controlled_creature_enters_damage_each_opponent_v1",
        "trigger": "creature_you_control_enters",
        "trigger_effect": "damage_each_opponent",
        "trigger_damage_each_opponent": 2,
        "damage": 2,
        "target_controller": "opponents",
        "trigger_creature_you_control_enters": True,
        "trigger_another_creature_you_control_enters": True,
    }


def test_purphoros_deals_two_to_each_opponent_when_another_creature_enters() -> None:
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [])
        opponent_a = battle.Player("Opponent A", None, [])
        opponent_b = battle.Player("Opponent B", None, [])
        purphoros = {
            "name": "Purphoros, God of the Forge",
            "type_line": "Legendary Enchantment Creature — God",
            **purphoros_effect(),
        }
        entering = {
            "name": "Goblin Token",
            "effect": "creature",
            "type_line": "Creature Token — Goblin",
            "power": 1,
            "toughness": 1,
        }
        active.battlefield = [purphoros, entering]

        resolved = battle.process_controlled_creature_enters_triggers(
            active,
            [opponent_a, opponent_b],
            entering,
            turn=5,
            source_event="test_creature_entered",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert resolved == 1
    assert opponent_a.life == 38
    assert opponent_b.life == 38
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Purphoros, God of the Forge"
        and data.get("trigger") == "creature_you_control_enters"
        and data.get("effect") == "damage_each_opponent"
        and data.get("amount") == 2
        and {row["player"] for row in data.get("damaged", [])} == {"Opponent A", "Opponent B"}
        for event, data in events
    )


def test_purphoros_another_creature_gate_skips_its_own_entry() -> None:
    battle = load_battle()
    active = battle.Player("Lorehold", None, [])
    opponent = battle.Player("Opponent", None, [])
    purphoros = {
        "name": "Purphoros, God of the Forge",
        "type_line": "Legendary Enchantment Creature — God",
        **purphoros_effect(),
    }
    active.battlefield = [purphoros]

    resolved = battle.process_controlled_creature_enters_triggers(
        active,
        [opponent],
        purphoros,
        turn=4,
        source_event="self_entered",
    )

    assert resolved == 0
    assert opponent.life == 40
