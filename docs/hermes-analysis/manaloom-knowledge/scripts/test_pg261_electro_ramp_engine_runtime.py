#!/usr/bin/env python3
"""Focused runtime tests for PG261 Electro exact ramp-engine promotion."""

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
    spec = importlib.util.spec_from_file_location("battle_pg261_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def card(name, type_line, **extra):
    return {"name": name, "type_line": type_line, **extra}


def primary_from_index(index_entry, oracle_text=""):
    return hints.build_effect_hints(index_entry, oracle_text)["primary_candidate"]["effect_json"]


def family_lane(card_name, effect_json, types, effects, abilities, targets=None, costs=None):
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
                        "cost_classes": sorted(costs or []),
                        "primary_effect": effect_json,
                    },
                }
            ]
        }
    )
    return report["cards"][0]["promotion_lane"]


def electro_index_entry():
    return {
        "xmage_class_name": "ElectroAssaultingBattery",
        "effect_classes": [
            "AddManaToManaPoolSourceControllerEffect",
            "ElectroAssaultingBatteryEffect",
            "OneShotEffect",
            "YouDontLoseManaEffect",
        ],
        "ability_classes": [
            "FlyingAbility",
            "LeavesBattlefieldTriggeredAbility",
            "SimpleStaticAbility",
            "SpellCastControllerTriggeredAbility",
        ],
        "target_classes": ["TargetPlayer"],
        "constructor_metadata": {"card_types": ["CREATURE"]},
    }


def test_electro_mapper_and_classifier_are_exact_batch_safe():
    effect = primary_from_index(electro_index_entry())

    assert effect["effect"] == "ramp_engine"
    assert effect["battle_model_scope"] == (
        "instant_sorcery_cast_red_mana_trigger_persistent_red_leaves_x_damage_annotation_v1"
    )
    assert effect["trigger"] == "instant_sorcery_cast"
    assert effect["instant_sorcery_cast_add_mana"] == 1
    assert effect["instant_sorcery_cast_mana_color"] == "R"
    assert effect["mana_persists_steps"] is True
    assert effect["leaves_battlefield_pay_x_damage_target_player"] is True
    assert effect["leaves_battlefield_pay_x_damage_status"] == "annotation_only"
    assert (
        family_lane(
            "Electro, Assaulting Battery",
            effect,
            {"CREATURE"},
            {
                "AddManaToManaPoolSourceControllerEffect",
                "ElectroAssaultingBatteryEffect",
                "OneShotEffect",
                "YouDontLoseManaEffect",
            },
            {
                "FlyingAbility",
                "LeavesBattlefieldTriggeredAbility",
                "SimpleStaticAbility",
                "SpellCastControllerTriggeredAbility",
            },
            {"TargetPlayer"},
        )
        == "batch_metadata_candidate_requires_pg_precheck"
    )


def test_electro_runtime_triggers_only_for_instant_or_sorcery():
    battle = load_battle()
    active = battle.Player("Pilot", None, [])
    opponent = battle.Player("Opponent", None, [])
    electro = primary_from_index(electro_index_entry())
    active.battlefield = [card("Electro, Assaulting Battery", "Legendary Creature - Human Villain", **electro)]

    battle.trigger_spell_cast_engines(
        active,
        [active, opponent],
        card("Lightning Bolt", "Instant"),
        turn=2,
        phase="precombat_main",
    )
    assert active.mana_pool.red == 1

    battle.trigger_spell_cast_engines(
        active,
        [active, opponent],
        card("Goblin Guide", "Creature - Goblin Scout"),
        turn=2,
        phase="precombat_main",
    )
    assert active.mana_pool.red == 1


if __name__ == "__main__":
    test_electro_mapper_and_classifier_are_exact_batch_safe()
    test_electro_runtime_triggers_only_for_instant_or_sorcery()
    print("PASS test_pg261_electro_ramp_engine_runtime")
