#!/usr/bin/env python3
"""Focused runtime tests for Brain in a Jar exact charge-counter adapter."""

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
    spec = importlib.util.spec_from_file_location("battle_brain_in_a_jar_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def brain_in_a_jar(battle):
    return {
        "name": "Brain in a Jar",
        "type_line": "Artifact",
        "cmc": 2,
        "effect": "topdeck_manipulation",
        "battle_model_scope": battle.BRAIN_IN_A_JAR_SCOPE,
        "activation_cost_mana": "{1}",
        "activation_cost_generic": 1,
        "activation_requires_tap": True,
        "activated_add_counters": True,
        "activated_add_counters_target": "self",
        "activated_add_counters_counter_type": "charge",
        "activated_add_counters_count": 1,
        "brain_in_a_jar_free_cast": True,
        "free_cast_from_zone": "hand",
        "free_cast_card_types": ["instant", "sorcery"],
        "free_cast_mana_value_match": "source_charge_counters_after_add",
        "cast_without_paying_mana_cost": True,
        "secondary_activation_requires_tap": True,
        "secondary_activation_cost_mana": "{3}",
        "secondary_activation_cost_generic": 3,
        "secondary_activation_remove_counter_type": "charge",
        "secondary_activation_remove_x_counters": True,
        "secondary_activation_scry_count_source": "removed_charge_counters",
        "_rule_review_status": "verified",
        "_rule_execution_status": "auto",
    }


def ponder():
    return {"name": "Ponder", "type_line": "Sorcery", "cmc": 1, "mana_cost": "{U}"}


def divination():
    return {"name": "Divination", "type_line": "Sorcery", "cmc": 3, "effect": "draw"}


def sol_ring():
    return {"name": "Sol Ring", "type_line": "Artifact", "cmc": 1, "effect": "ramp"}


def test_utility_activation_adds_charge_then_free_casts_exact_hand_spell():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        brain = brain_in_a_jar(battle)
        active.battlefield = [brain]
        active.hand = [divination(), ponder(), sol_ring()]
        active.library = [{"name": "Drawn Card", "type_line": "Instant", "cmc": 1, "effect": "draw"}]
        active.mana_pool.add_generic(1)

        activated = battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=5,
            rng=random.Random(607),
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert activated == 1
    assert brain["tapped"] is True
    assert brain["charge_counters"] == 1
    assert active.available_mana() == 0
    assert all(card.get("name") != "Ponder" for card in active.hand)
    assert any(card.get("name") == "Ponder" for card in active.graveyard)
    assert any(card.get("name") == "Drawn Card" for card in active.hand)
    assert any(
        event == "brain_in_a_jar_charge_counter_added"
        and data.get("card") == "Brain in a Jar"
        and data.get("counter_type") == "charge"
        and data.get("counters_before") == 0
        and data.get("counters_after") == 1
        for event, data in events
    )
    assert any(
        event == "brain_in_a_jar_free_cast"
        and data.get("cast_card") == "Ponder"
        and data.get("selected_mana_value") == 1
        and data.get("charge_counters_after") == 1
        and data.get("eligible_spell_names") == ["Ponder"]
        and data.get("cast_without_paying_mana_cost") is True
        and data.get("locked_cost", {}).get("spend_tags") == ["cast_without_paying_mana_cost"]
        for event, data in events
    )
    assert any(
        event == "spell_cast"
        and data.get("card") == "Ponder"
        and data.get("source_zone") == "hand"
        and data.get("locked_cost", {}).get("spend_tags") == ["cast_without_paying_mana_cost"]
        for event, data in events
    )


def test_remove_variable_charge_counters_scry_x():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        brain = brain_in_a_jar(battle)
        brain["charge_counters"] = 3
        active.battlefield = [brain]
        active.library = [
            {"name": "Low Priority Land", "type_line": "Basic Land - Mountain", "cmc": 0, "effect": "land"},
            {"name": "High Priority Spell", "type_line": "Sorcery", "cmc": 5, "effect": "draw"},
            {"name": "Medium Priority Spell", "type_line": "Instant", "cmc": 2, "effect": "draw"},
        ]
        active.mana_pool.add_generic(3)

        result = battle.resolve_brain_in_a_jar_remove_variable_charge_counters_scry(
            active,
            brain,
            turn=6,
            remove_count=2,
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert result["activated"] is True
    assert result["removed_charge_counters"] == 2
    assert brain["charge_counters"] == 1
    assert brain["tapped"] is True
    assert active.available_mana() == 0
    assert result["scry_result"]["looked_at"] == ["Low Priority Land", "High Priority Spell"]
    assert active.library[0]["name"] == "High Priority Spell"
    assert any(
        event == "brain_in_a_jar_scry"
        and data.get("activation_kind") == "remove_variable_charge_counters_scry_x"
        and data.get("removed_charge_counters") == 2
        and data.get("charge_counters_after") == 1
        and data.get("scry_count") == 2
        and data.get("scry_top_after", [None])[0] == "High Priority Spell"
        for event, data in events
    )


if __name__ == "__main__":
    test_utility_activation_adds_charge_then_free_casts_exact_hand_spell()
    test_remove_variable_charge_counters_scry_x()
    print("PASS test_brain_in_a_jar_runtime")
