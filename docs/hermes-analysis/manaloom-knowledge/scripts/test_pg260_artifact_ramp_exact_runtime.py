#!/usr/bin/env python3
"""Focused runtime tests for PG260 artifact ramp exact-scope promotions."""

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
    spec = importlib.util.spec_from_file_location("battle_pg260_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def primary_from_index(index_entry, oracle_text=""):
    return hints.build_effect_hints(index_entry, oracle_text)["primary_candidate"]["effect_json"]


def family_lane(card_name, effect_json, types, effects, abilities, costs=None):
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
                        "cost_classes": sorted(costs or []),
                        "primary_effect": effect_json,
                    },
                }
            ]
        }
    )
    return report["cards"][0]["promotion_lane"]


def test_cursed_mirror_mapper_and_classifier_are_exact_batch_safe():
    index_entry = {
        "xmage_class_name": "CursedMirror",
        "effect_classes": ["CopyPermanentEffect"],
        "ability_classes": ["EntersBattlefieldAbility", "RedManaAbility"],
        "constructor_metadata": {"card_types": ["ARTIFACT"]},
    }

    effect = primary_from_index(index_entry)

    assert effect["effect"] == "ramp_permanent"
    assert effect["battle_model_scope"] == "red_mana_rock_etb_copy_creature_haste_annotation_v1"
    assert effect["produces"] == "R"
    assert effect["mana_produced"] == 1
    assert effect["etb_may_copy_any_creature_until_eot"] is True
    assert effect["etb_copy_grants_haste"] is True
    assert effect["etb_copy_status"] == "annotation_only"
    assert (
        family_lane(
            "Cursed Mirror",
            effect,
            {"ARTIFACT"},
            {"CopyPermanentEffect"},
            {"EntersBattlefieldAbility", "RedManaAbility"},
        )
        == "batch_metadata_candidate_requires_pg_precheck"
    )


def test_cursed_mirror_runtime_adds_red_mana_source():
    battle = load_battle()
    player = battle.Player("Active", None, [])
    cursed_mirror = {
        "name": "Cursed Mirror",
        "type_line": "Artifact",
        "effect": "ramp_permanent",
        "permanent_type": "artifact",
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "R",
        "activation_requires_tap": True,
        "battle_model_scope": "red_mana_rock_etb_copy_creature_haste_annotation_v1",
    }
    player.battlefield.append(cursed_mirror)

    player.refresh_mana_sources(turn=2)

    assert player.mana_pool.red == 1
    assert player.available_mana() == 1


if __name__ == "__main__":
    test_cursed_mirror_mapper_and_classifier_are_exact_batch_safe()
    test_cursed_mirror_runtime_adds_red_mana_source()
    print("PASS test_pg260_artifact_ramp_exact_runtime")
