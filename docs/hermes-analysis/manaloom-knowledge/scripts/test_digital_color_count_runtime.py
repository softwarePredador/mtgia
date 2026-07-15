#!/usr/bin/env python3
"""Focused runtime coverage for digital color-count permanents."""

from __future__ import annotations

import importlib.util
import json
import random
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
REVIEWED_RULES_PATH = SCRIPT_DIR / "reviewed_battle_card_rules.json"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_digital_color_count_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def opulent_clomper_rule():
    payload = json.loads(REVIEWED_RULES_PATH.read_text(encoding="utf-8"))
    return payload["Opulent Clomper"]


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def test_opulent_clomper_reviewed_rule_has_runtime_and_oracle_contract():
    rule = opulent_clomper_rule()
    effect = rule["effect_json"]

    assert rule["review_status"] == "verified"
    assert rule["execution_status"] == "auto"
    assert rule["oracle_hash"] == "b4480729f529378cbbd436860f0edf4b"
    assert effect["static_power_toughness_source"] == "colors_among_permanents_you_control"
    assert effect["upkeep_add_random_missing_color"] is True
    assert effect["upkeep_color_choices"] == ["W", "U", "B", "R", "G"]
    assert effect["battle_model_scope"] == (
        "static_source_power_toughness_equal_controlled_colors_v1"
    )


def test_opulent_clomper_scales_adds_missing_colors_and_resets_on_zone_change():
    battle = load_battle()
    controller = player(battle, "Controller")
    opponent = player(battle, "Opponent")
    white_permanent = {
        "name": "White Permanent",
        "type_line": "Enchantment",
        "colors": ["W"],
    }
    blue_permanent = {
        "name": "Blue Permanent",
        "type_line": "Artifact Creature - Construct",
        "colors": ["U"],
        "power": 1,
        "toughness": 1,
    }
    controller.battlefield = [white_permanent, blue_permanent]
    clomper = {
        "name": "Opulent Clomper",
        "owner": controller.name,
        "controller": controller.name,
        **opulent_clomper_rule()["effect_json"],
    }
    events = []
    old_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        clomper = battle.prepare_entering_permanent(
            clomper,
            controller=controller,
            all_players=[controller, opponent],
            turn=2,
        )
        controller.battlefield.append(clomper)
        assert clomper["power"] == 3
        assert clomper["toughness"] == 3

        rng = random.Random(7)
        assert battle.process_random_missing_color_upkeep(
            controller, [controller, opponent], turn=3, rng=rng
        ) == 1
        assert clomper["power"] == 4
        assert clomper["toughness"] == 4

        battle.CURRENT_REPLAY_TURN = 3
        destination = battle.move_permanent_from_battlefield(
            controller,
            white_permanent,
            reason="destroyed_by_test",
            all_players=[controller, opponent],
        )
        assert destination == "graveyard"
        expected_colors = battle._controlled_permanent_color_count(controller)
        assert clomper["power"] == expected_colors
        assert clomper["toughness"] == expected_colors

        for turn in (4, 5, 6):
            assert battle.process_random_missing_color_upkeep(
                controller, [controller, opponent], turn=turn, rng=rng
            ) == 1
            expected_colors = battle._controlled_permanent_color_count(controller)
            assert clomper["power"] == expected_colors
            assert clomper["toughness"] == expected_colors
        assert clomper["power"] == 5
        assert clomper["toughness"] == 5
        assert battle.process_random_missing_color_upkeep(
            controller, [controller, opponent], turn=7, rng=rng
        ) == 0

        destination = battle.move_permanent_from_battlefield_to_hand(
            controller,
            clomper,
            reason="returned_by_test",
            turn=8,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = old_handler
        battle.CURRENT_REPLAY_TURN = None

    assert destination == "hand"
    assert clomper in controller.hand
    assert clomper not in controller.battlefield
    assert clomper["colors"] == ["G"]
    assert "_battlefield_added_colors" not in clomper
    assert "_printed_colors_before_battlefield_color_changes" not in clomper
    added_events = [data for event, data in events if event == "upkeep_random_missing_color_added"]
    assert len(added_events) == 4
    assert {event["chosen_color"] for event in added_events} == {"W", "U", "B", "R"}
    assert any(
        event == "trigger_skipped" and data.get("reason") == "permanent_already_all_colors"
        for event, data in events
    )


if __name__ == "__main__":
    test_opulent_clomper_reviewed_rule_has_runtime_and_oracle_contract()
    test_opulent_clomper_scales_adds_missing_colors_and_resets_on_zone_change()
    print("PASS test_digital_color_count_runtime")
