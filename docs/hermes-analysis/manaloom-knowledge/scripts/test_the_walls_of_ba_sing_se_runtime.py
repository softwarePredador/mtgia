#!/usr/bin/env python3
"""Focused runtime tests for The Walls of Ba Sing Se static indestructible grant."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_walls_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def walls_card():
    return {
        "name": "The Walls of Ba Sing Se",
        "type_line": "Legendary Artifact Creature - Wall",
        "mana_cost": "{8}",
        "cmc": 8,
        "power": 0,
        "toughness": 30,
    }


def bear_card():
    return {
        "name": "Runeclaw Bear",
        "type_line": "Creature - Bear",
        "mana_cost": "{1}{G}",
        "cmc": 2,
        "power": 2,
        "toughness": 2,
    }


def put_creature(battle, controller, card, turn=4):
    battle.apply_effect_immediate(
        controller,
        [],
        card,
        turn=turn,
        rng=random.Random(616),
        effect_data_override={**battle.get_card_effect(card), "effect": "creature"},
    )
    return next(permanent for permanent in controller.battlefield if permanent.get("name") == card["name"])


def test_the_walls_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(walls_card())

    assert effect["effect"] == "creature"
    assert effect["battle_model_scope"] == "other_permanents_you_control_have_indestructible_static_v1"
    assert effect["artifact"] is True
    assert effect["legendary"] is True
    assert effect["defender"] is True
    assert effect["power"] == 0
    assert effect["toughness"] == 30
    assert effect["other_permanents_you_control_have_indestructible"] is True
    assert effect["static_grant_scope"] == "other_permanents_you_control"
    assert effect["_rule_logical_key"] == "battle_rule_v1:1e5bcf3b45fcae347879976d74d2ef84"
    assert effect["_rule_oracle_hash"] == "3eda937f066b2e5ab8fff222caecafab"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "The Walls of Ba Sing Se" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_the_walls_grants_indestructible_to_other_permanents_only():
    battle = load_battle()
    controller = player(battle, "Lorehold")
    bear = put_creature(battle, controller, bear_card())
    walls = put_creature(battle, controller, walls_card())

    assert walls["defender"] is True
    assert walls.get("indestructible") in (None, False)
    assert bear["indestructible"] is True
    assert bear["static_indestructible_source"] == "The Walls of Ba Sing Se"
    assert bear["static_indestructible_original"] is False


def test_the_walls_board_wipe_preserves_other_permanent_then_clears_grant():
    battle = load_battle()
    controller = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    bear = put_creature(battle, controller, bear_card())
    walls = put_creature(battle, controller, walls_card())
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.apply_effect_immediate(
            controller,
            [opponent],
            {"name": "Wrath of God", "type_line": "Sorcery", "cmc": 4},
            turn=6,
            rng=random.Random(617),
            effect_data_override={
                "effect": "board_wipe",
                "destroy_card_types": ["creature"],
            },
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert bear in controller.battlefield
    assert walls not in controller.battlefield
    assert walls in controller.graveyard
    assert bear.get("indestructible") is False
    assert "static_indestructible_source" not in bear
    assert any(
        event == "board_wipe_resolved"
        and data.get("protected") == 1
        and data.get("destroyed") == 1
        for event, data in events
    )
    assert any(
        event == "static_indestructible_removed"
        and data.get("card") == "Runeclaw Bear"
        for event, data in events
    )


def test_the_walls_damage_wipe_protects_other_creature_while_source_survives():
    battle = load_battle()
    controller = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    bear = put_creature(battle, controller, bear_card())
    walls = put_creature(battle, controller, walls_card())
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.apply_damage_wipe(
            opponent,
            [controller],
            {"name": "Blasphemous Act", "type_line": "Sorcery", "cmc": 9},
            {"effect": "damage_wipe", "damage": 10, "damage_scope": "each_creature"},
            turn=7,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert bear in controller.battlefield
    assert walls in controller.battlefield
    assert bear["indestructible"] is True
    assert bear["static_indestructible_source"] == "The Walls of Ba Sing Se"
    assert any(
        event == "damage_wipe_resolved"
        and any(item.get("name") == "Runeclaw Bear" for item in data.get("protected", []))
        for event, data in events
    )


if __name__ == "__main__":
    test_the_walls_get_card_effect_is_runtime_source()
    test_the_walls_grants_indestructible_to_other_permanents_only()
    test_the_walls_board_wipe_preserves_other_permanent_then_clears_grant()
    test_the_walls_damage_wipe_protects_other_creature_while_source_survives()
    print("PASS test_the_walls_of_ba_sing_se_runtime")
