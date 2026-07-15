#!/usr/bin/env python3
"""Focused runtime coverage for digital perpetual card modifications."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
REVIEWED_RULES_PATH = SCRIPT_DIR / "reviewed_battle_card_rules.json"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_digital_perpetual_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def runeblade_rule():
    payload = json.loads(REVIEWED_RULES_PATH.read_text(encoding="utf-8"))
    return payload["Runeblade Raiser"]


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def test_runeblade_reviewed_rule_has_runtime_and_oracle_contract():
    rule = runeblade_rule()
    effect = rule["effect_json"]

    assert rule["review_status"] == "verified"
    assert rule["execution_status"] == "auto"
    assert rule["oracle_hash"] == "a936629ea54340d8d098194956d53e35"
    assert effect["enters_tapped"] is True
    assert effect["dies_self_return_to_battlefield"] is True
    assert effect["dies_self_return_controller"] == "owner"
    assert effect["dies_self_return_perpetual_remove_ability_key"] == "dies_self_return_to_battlefield"


def test_runeblade_returns_to_owner_once_and_keeps_perpetual_state():
    battle = load_battle()
    owner = player(battle, "Owner")
    temporary_controller = player(battle, "Temporary Controller")
    effect = runeblade_rule()["effect_json"]
    runeblade = {
        "name": "Runeblade Raiser",
        "owner": owner.name,
        "controller": temporary_controller.name,
        **effect,
    }
    events = []
    old_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.CURRENT_REPLAY_TURN = 4
        temporary_controller.battlefield = [runeblade]
        destination = battle.move_creature_from_battlefield(
            temporary_controller,
            runeblade,
            reason="destroyed_by_test",
            all_players=[owner, temporary_controller],
        )

        assert destination == "graveyard"
        assert runeblade in owner.battlefield
        assert runeblade not in temporary_controller.graveyard
        assert runeblade not in owner.graveyard
        assert runeblade["controller"] == owner.name
        assert runeblade["tapped"] is True
        assert runeblade["summoning_sick"] is True
        assert runeblade["_perpetually_removed_ability_keys"] == [
            "dies_self_return_to_battlefield"
        ]

        battle.CURRENT_REPLAY_TURN = 5
        second_destination = battle.move_creature_from_battlefield(
            owner,
            runeblade,
            reason="sacrificed_by_test",
            all_players=[owner, temporary_controller],
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = old_handler
        battle.CURRENT_REPLAY_TURN = None

    assert second_destination == "graveyard"
    assert runeblade not in owner.battlefield
    assert runeblade in owner.graveyard
    assert sum(event == "dies_self_return_resolved" for event, _ in events) == 1
    assert sum(event == "dies_self_return_skipped" for event, _ in events) == 1
    resolved = next(data for event, data in events if event == "dies_self_return_resolved")
    skipped = next(data for event, data in events if event == "dies_self_return_skipped")
    assert resolved["player"] == owner.name
    assert resolved["previous_controller"] == temporary_controller.name
    assert resolved["returned_under_owner_control"] is True
    assert skipped["reason"] == "ability_perpetually_removed"


if __name__ == "__main__":
    test_runeblade_reviewed_rule_has_runtime_and_oracle_contract()
    test_runeblade_returns_to_owner_once_and_keeps_perpetual_state()
    print("PASS test_digital_perpetual_runtime")
