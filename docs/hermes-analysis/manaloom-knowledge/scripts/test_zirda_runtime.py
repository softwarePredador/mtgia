#!/usr/bin/env python3
"""Focused runtime tests for Zirda activated-ability cost reduction."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_zirda_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def zirda_card():
    return {
        "name": "Zirda, the Dawnwaker",
        "type_line": "Legendary Creature - Elemental Fox",
        "mana_cost": "{1}{R/W}{R/W}",
        "cmc": 3,
    }


def test_zirda_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(zirda_card())

    assert effect["effect"] == "static_cost_reduction"
    assert effect["battle_model_scope"] == "static_activated_ability_cost_reduction_variant_v1"
    assert effect["cost_reduction_applies_to"] == "activated_abilities_you_activate"
    assert effect["cost_reduction_generic"] == 2
    assert effect["cost_reduction_minimum_total_mana"] == 1
    assert effect["cost_reduction_excludes_mana_abilities"] is True
    assert effect["activated_ability_cost"] == "{1}, {T}"
    assert effect["activated_ability_effect"] == "cant_block_target_creature_until_eot"
    assert effect["activated_ability_target"] == "target_creature"
    assert effect["companion_condition"] == "each_permanent_card_in_starting_deck_has_activated_ability"
    assert effect["is_creature_permanent"] is True
    assert effect["legendary"] is True
    assert effect["power"] == 3
    assert effect["toughness"] == 3
    assert effect["_rule_logical_key"] == "battle_rule_v1:45c3e1db1be4f2f97a3337ce3de8f767"
    assert effect["_rule_oracle_hash"] == "23860bc4072cc27137ba346b82b9f548"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Zirda, the Dawnwaker" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_zirda_reduces_nonmana_activated_abilities_you_activate():
    battle = load_battle()
    active = player(battle, "Lorehold")
    zirda = {**zirda_card(), **battle.get_card_effect(zirda_card())}
    active.battlefield = [zirda]

    artifact = {"name": "The Mind Stone", "type_line": "Artifact"}
    enchantment = {"name": "Utility Enchantment", "type_line": "Enchantment"}
    creature = {"name": "Utility Creature", "type_line": "Creature - Advisor"}

    assert battle.adjusted_activated_ability_generic_cost(active, artifact, 3) == 1
    assert battle.adjusted_activated_ability_generic_cost(active, enchantment, 3) == 1
    assert battle.adjusted_activated_ability_generic_cost(active, creature, 2) == 1
    assert battle.adjusted_activated_ability_generic_cost(active, creature, 1) == 1
    assert (
        battle.adjusted_activated_ability_generic_cost(
            active,
            creature,
            1,
            activation_colors=["W"],
        )
        == 0
    )


def test_zirda_does_not_reduce_mana_abilities_and_remains_creature():
    battle = load_battle()
    active = player(battle, "Lorehold")
    zirda = {**zirda_card(), **battle.get_card_effect(zirda_card())}
    active.battlefield = [zirda]

    assert battle.is_battlefield_creature(zirda) is True
    assert (
        battle.adjusted_activated_ability_generic_cost(
            active,
            {"name": "Utility Mana Rock", "type_line": "Artifact"},
            3,
            is_mana_ability=True,
        )
        == 3
    )


if __name__ == "__main__":
    test_zirda_get_card_effect_is_runtime_source()
    test_zirda_reduces_nonmana_activated_abilities_you_activate()
    test_zirda_does_not_reduce_mana_abilities_and_remains_creature()
    print("PASS test_zirda_runtime")
