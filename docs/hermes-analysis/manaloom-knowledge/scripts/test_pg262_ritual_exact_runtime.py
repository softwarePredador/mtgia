#!/usr/bin/env python3
"""Focused runtime tests for PG262 exact ritual-family promotions."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import xmage_semantic_family_classifier as classifier
import xmage_to_manaloom_effect_hints as hints


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_pg262_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def card(name, type_line, **extra):
    return {"name": name, "type_line": type_line, **extra}


def primary_from_index(index_entry, oracle_text=""):
    return hints.build_effect_hints(index_entry, oracle_text)["primary_candidate"]["effect_json"]


def family_lane(card_name, effect_json, types, effects, abilities, targets=None, filters=None, costs=None):
    report = classifier.build_family_report(
        {
            "cards": [
                {
                    "card_name": card_name,
                    "severity": "medium",
                    "oracle_hash": "hash",
                    "status": "ready_for_structured_xmage_pull_review_required",
                    "ready_for_structured_pull": True,
                    "valid_xmage_source": True,
                    "coherence_findings": ["trusted_rule_without_oracle_hash"],
                    "checks": {"focused_test_scenario_count": 1},
                    "xmage": {
                        "class_name": card_name.replace(" ", ""),
                        "path": f"/xmage/{card_name}.java",
                        "types": sorted(types),
                        "effect_classes": sorted(effects),
                        "ability_classes": sorted(abilities),
                        "target_classes": sorted(targets or []),
                        "filter_classes": sorted(filters or []),
                        "cost_classes": sorted(costs or []),
                        "primary_effect": effect_json,
                    },
                }
            ]
        }
    )
    return report["cards"][0]["promotion_lane"]


def mana_geyser_index_entry():
    return {
        "xmage_class_name": "ManaGeyser",
        "effect_classes": ["DynamicManaEffect"],
        "ability_classes": [],
        "target_classes": ["TargetController"],
        "filter_classes": ["FilterLandPermanent"],
        "constructor_metadata": {"card_types": ["SORCERY"]},
    }


def burnt_offering_index_entry():
    return {
        "xmage_class_name": "BurntOffering",
        "effect_classes": ["AddManaInAnyCombinationEffect"],
        "ability_classes": [],
        "cost_classes": ["SacrificeTargetCost"],
        "constructor_metadata": {"card_types": ["INSTANT"]},
        "raw_excerpt": (
            "SacrificeCostManaValue xValue = SacrificeCostManaValue.CREATURE; "
            "new AddManaInAnyCombinationEffect(xValue, xValue, ColoredManaSymbol.B, ColoredManaSymbol.R)"
        ),
    }


def test_mana_geyser_mapper_and_classifier_are_exact_batch_safe():
    effect = primary_from_index(
        mana_geyser_index_entry(),
        "Add {R} for each tapped land your opponents control.",
    )

    assert effect["effect"] == "ramp_ritual"
    assert effect["battle_model_scope"] == "add_red_for_each_tapped_land_opponents_control_v1"
    assert effect["mana_produced_from_opponents_tapped_lands"] is True
    assert effect["mana_per_tapped_land"] == 1
    assert (
        family_lane(
            "Mana Geyser",
            effect,
            {"SORCERY"},
            {"DynamicManaEffect"},
            set(),
            {"TargetController"},
            {"FilterLandPermanent"},
        )
        == "batch_metadata_candidate_requires_pg_precheck"
    )


def test_burnt_offering_mapper_and_classifier_are_exact_batch_safe():
    effect = primary_from_index(
        burnt_offering_index_entry(),
        "As an additional cost to cast this spell, sacrifice a creature. Add an amount of {B} and/or {R} equal to the sacrificed creature's mana value.",
    )

    assert effect["effect"] == "ramp_ritual"
    assert effect["battle_model_scope"] == "sacrifice_creature_add_black_or_red_equal_sacrificed_mana_value_v1"
    assert effect["requires_sacrifice_creature"] is True
    assert effect["mana_produced_from_sacrificed_cmc"] is True
    assert effect["produces"] == "BR"
    assert (
        family_lane(
            "Burnt Offering",
            effect,
            {"INSTANT"},
            {"AddManaInAnyCombinationEffect"},
            set(),
            costs={"SacrificeTargetCost"},
        )
        == "batch_metadata_candidate_requires_pg_precheck"
    )


def test_mana_geyser_counts_opponents_tapped_lands():
    battle = load_battle()
    active = battle.Player("Pilot", None, [])
    opponent_a = battle.Player("Opponent A", None, [])
    opponent_b = battle.Player("Opponent B", None, [])
    opponent_a.battlefield = [
        card("Island", "Basic Land - Island", effect="land", tapped=True),
        card("Swamp", "Basic Land - Swamp", effect="land", tapped=True),
        card("Forest", "Basic Land - Forest", effect="land", tapped=False),
    ]
    opponent_b.battlefield = [
        card("Mountain", "Basic Land - Mountain", effect="land", tapped=True),
        card("Nonland Rock", "Artifact", effect="ramp_permanent", tapped=True),
    ]
    effect = primary_from_index(
        mana_geyser_index_entry(),
        "Add {R} for each tapped land your opponents control.",
    )

    assert battle.ritual_mana_produced(active, effect, [opponent_a, opponent_b]) == 3


def test_burnt_offering_uses_sacrificed_creature_mana_value():
    battle = load_battle()
    active = battle.Player("Pilot", None, [])
    active.battlefield = [
        card("Four Mana Creature", "Creature - Elemental", effect="creature", cmc=4, power=4, toughness=4)
    ]
    effect = primary_from_index(
        burnt_offering_index_entry(),
        "As an additional cost to cast this spell, sacrifice a creature. Add an amount of {B} and/or {R} equal to the sacrificed creature's mana value.",
    )

    assert battle.pay_additional_card_costs(active, card("Burnt Offering", "Instant"), effect, turn=2) is True
    assert effect["_last_sacrificed_cmc"] == 4
    assert battle.ritual_mana_produced(active, effect) == 4


if __name__ == "__main__":
    test_mana_geyser_mapper_and_classifier_are_exact_batch_safe()
    test_burnt_offering_mapper_and_classifier_are_exact_batch_safe()
    test_mana_geyser_counts_opponents_tapped_lands()
    test_burnt_offering_uses_sacrificed_creature_mana_value()
    print("PASS test_pg262_ritual_exact_runtime")
