#!/usr/bin/env python3
"""Focused runtime tests for Wand of Vertebrae graveyard utility."""

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
    spec = importlib.util.spec_from_file_location("battle_wand_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def wand_card():
    return {
        "name": "Wand of Vertebrae",
        "type_line": "Artifact",
        "mana_cost": "{1}",
        "cmc": 1,
    }


def spell(name, cmc=2, type_line="Sorcery"):
    return {"name": name, "cmc": cmc, "type_line": type_line}


def test_wand_of_vertebrae_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(wand_card())

    assert effect["effect"] == "passive"
    assert effect["battle_model_scope"] == "tap_self_mill_or_self_exile_graveyard_shuffle_artifact_v1"
    assert effect["artifact"] is True
    assert effect["mana_cost"] == "{1}"
    assert effect["activated_self_mill_count"] == 1
    assert effect["self_mill_activation_requires_tap"] is True
    assert effect["graveyard_shuffle_activation_cost_generic"] == 2
    assert effect["graveyard_shuffle_activation_requires_tap"] is True
    assert effect["graveyard_shuffle_exiles_self"] is True
    assert effect["graveyard_shuffle_target_count"] == 5
    assert effect["_rule_logical_key"] == "battle_rule_v1:ab583f78c19a22031bb99e0ac2d0d131"
    assert effect["_rule_oracle_hash"] == "71de2615587654002b225714c5130a68"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Wand of Vertebrae" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_wand_of_vertebrae_precombat_self_mills_one_card():
    battle = load_battle()
    active = player(battle, "Lorehold")
    permanent = {**wand_card(), **battle.get_card_effect(wand_card())}
    active.battlefield = [permanent]
    active.library = [
        spell("Top Card", 5),
        spell("Second Card", 3),
        spell("Third Card", 2),
        spell("Fourth Card", 1),
        spell("Fifth Card", 1),
    ]
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        activated = battle.activate_utility_artifacts(
            active,
            [],
            [active],
            turn=3,
            rng=random.Random(607),
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert activated == 1
    assert permanent["tapped"] is True
    assert permanent["utility_artifact_used_this_turn"] is True
    assert [card["name"] for card in active.graveyard] == ["Top Card"]
    assert [card["name"] for card in active.library] == [
        "Second Card",
        "Third Card",
        "Fourth Card",
        "Fifth Card",
    ]
    activated_event = next(
        data
        for event, data in events
        if event == "utility_artifact_activated" and data.get("card") == "Wand of Vertebrae"
    )
    assert activated_event["activation_kind"] == "tap_self_mill"
    assert activated_event["milled"] == ["Top Card"]
    assert activated_event["rule_logical_key"] == "battle_rule_v1:ab583f78c19a22031bb99e0ac2d0d131"


def test_wand_of_vertebrae_exiles_self_and_shuffles_graveyard_targets():
    battle = load_battle()
    active = player(battle, "Lorehold")
    permanent = {**wand_card(), **battle.get_card_effect(wand_card())}
    active.battlefield = [permanent]
    active.library = [spell("Library Card", 1)]
    active.graveyard = [
        spell("Big Sorcery", 8),
        spell("Medium Spell", 4),
        spell("Small Spell", 2),
        spell("Basic Plains", 0, "Basic Land - Plains"),
        spell("Another Spell", 3),
        spell("Left Behind", 1),
    ]
    active.mana_pool.add_generic(2)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        activated = battle.activate_utility_artifacts(
            active,
            [],
            [active],
            turn=6,
            rng=random.Random(616),
            phase="postcombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert activated == 1
    assert permanent not in active.battlefield
    assert permanent in active.exile
    assert active.available_mana() == 0
    assert len(active.graveyard) == 1
    assert active.graveyard[0]["name"] == "Basic Plains"
    library_names = {card["name"] for card in active.library}
    assert library_names == {
        "Library Card",
        "Big Sorcery",
        "Medium Spell",
        "Small Spell",
        "Another Spell",
        "Left Behind",
    }
    activated_event = next(
        data
        for event, data in events
        if event == "utility_artifact_activated" and data.get("card") == "Wand of Vertebrae"
    )
    assert activated_event["activation_kind"] == "self_exile_shuffle_graveyard_to_library"
    assert activated_event["moved_count"] == 5
    assert activated_event["exiled_self"] is True
    assert activated_event["mana_paid"] == 2
    assert activated_event["rule_logical_key"] == "battle_rule_v1:ab583f78c19a22031bb99e0ac2d0d131"


if __name__ == "__main__":
    test_wand_of_vertebrae_get_card_effect_is_runtime_source()
    test_wand_of_vertebrae_precombat_self_mills_one_card()
    test_wand_of_vertebrae_exiles_self_and_shuffles_graveyard_targets()
    print("PASS test_wand_of_vertebrae_runtime")
