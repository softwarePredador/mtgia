#!/usr/bin/env python3
"""Focused runtime tests for Storm-Kiln Artist magecraft Treasure execution."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_storm_kiln_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def card(name: str, type_line: str, **extra):
    return {"name": name, "type_line": type_line, **extra}


def storm_kiln_rule():
    return {
        "name": "Storm-Kiln Artist",
        "cmc": 4,
        "type_line": "Creature - Dwarf Shaman",
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
        "trigger": "instant_sorcery_cast",
        "trigger_effect": "magecraft_create_treasure",
        "magecraft_trigger": "cast_or_copy_instant_or_sorcery",
        "magecraft_treasure_count": 1,
        "magecraft_treasure_status": "runtime_executor_v1",
        "artifact_power_bonus_status": "annotation_only",
        "battle_model_scope": "creature_body_artifact_power_annotation_magecraft_treasure_runtime_v1",
        "_rule_logical_key": "battle_rule_v1:storm_kiln_runtime_test",
        "_rule_oracle_hash": "storm-kiln-runtime-test-hash",
    }


def test_storm_kiln_magecraft_creates_treasure_for_instant_and_sorcery_only():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [])
        opponent = battle.Player("Opponent", None, [])
        active.battlefield = [storm_kiln_rule()]

        battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            card("Lightning Helix", "Instant", cmc=2),
            turn=4,
            phase="precombat_main",
        )
        battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            card("Bear Cub", "Creature", cmc=2),
            turn=4,
            phase="precombat_main",
        )
        battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            card("Reforge the Soul", "Sorcery", cmc=5),
            turn=4,
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert active.treasures == 2
    trigger_events = [
        data
        for event, data in events
        if event == "trigger_resolved" and data.get("card") == "Storm-Kiln Artist"
    ]
    assert [event["trigger_spell"] for event in trigger_events] == [
        "Lightning Helix",
        "Reforge the Soul",
    ]
    assert all(event["effect"] == "create_treasure" for event in trigger_events)
    assert trigger_events[-1]["treasures_after"] == 2
    assert trigger_events[-1]["artifact_count_after"] == 2
    assert all(
        event["rule_logical_key"] == "battle_rule_v1:storm_kiln_runtime_test"
        and event["rule_oracle_hash"] == "storm-kiln-runtime-test-hash"
        for event in trigger_events
    )


def test_storm_kiln_magecraft_creates_treasure_for_spell_copy():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [])
        opponent = battle.Player("Opponent", None, [])
        active.battlefield = [storm_kiln_rule()]

        battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            card("Copied Lightning Helix", "Instant", cmc=2, _is_spell_copy=True),
            turn=5,
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert active.treasures == 1
    trigger_event = next(
        data
        for event, data in events
        if event == "trigger_resolved" and data.get("card") == "Storm-Kiln Artist"
    )
    assert trigger_event["trigger_spell"] == "Copied Lightning Helix"
    assert trigger_event["trigger_spell_is_copy"] is True
    assert trigger_event["treasures_created"] == 1


if __name__ == "__main__":
    test_storm_kiln_magecraft_creates_treasure_for_instant_and_sorcery_only()
    test_storm_kiln_magecraft_creates_treasure_for_spell_copy()
    print("PASS test_storm_kiln_artist_runtime")
