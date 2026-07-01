#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "xmage_batch_pg_package_builder.py"


def load_module():
    spec = importlib.util.spec_from_file_location("xmage_batch_pg_package_builder_mod", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


builder = load_module()


def test_package_deck_role_derives_role_for_exact_effect_with_manual_placeholder() -> None:
    proposal = {
        "effect_json": {
            "effect": "ramp_permanent",
            "mana_produced": 1,
            "battle_model_scope": "land_type_mana_dork_plus_counter_triples_adapt_v1",
        },
        "deck_role_json": {
            "category": "manual_review",
            "effect": "external_reference_required_manual_model",
        },
    }

    assert builder.package_deck_role(proposal) == {
        "category": "ramp",
        "effect": "ramp_permanent",
    }


def test_package_deck_role_preserves_true_external_reference_placeholder() -> None:
    proposal = {
        "effect_json": {"effect": "external_reference_required_manual_model"},
        "deck_role_json": {
            "category": "manual_review",
            "effect": "external_reference_required_manual_model",
        },
    }

    assert builder.package_deck_role(proposal) == proposal["deck_role_json"]


def test_manifest_expected_rule_from_proposal_contains_e2e_fields() -> None:
    proposal = {
        "normalized_name": "verge rangers",
        "card_name": "Verge Rangers",
        "oracle_hash": "hash123",
        "logical_rule_key": "battle_rule_v1:abc",
        "effect_json": {
            "effect": "topdeck_play",
            "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
            "target": "land",
            "target_graveyard_controller": "opponent",
            "battlefield_controller": "self",
            "count": 1,
            "destination": "play",
            "enters_tapped": True,
            "exiles_self": False,
            "mode_selection": "one_or_both",
            "recursion_mana_value_max": 3,
            "etb_recursion_target": "artifact",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "etb_recursion_up_to_count": False,
            "etb_recursion_mana_value_max": 1,
            "dies_recursion_target": "artifact",
            "dies_recursion_count": 1,
            "dies_recursion_destination": "hand",
            "dies_recursion_exclude_self": True,
            "graveyard_exile_target": "any_card",
            "graveyard_exile_target_count": 3,
            "graveyard_exile_destination": "exile",
            "graveyard_exile_up_to_count": True,
            "graveyard_exile_single_graveyard": True,
            "graveyard_to_library_target": "creature",
            "graveyard_to_library_target_count": 1,
            "graveyard_to_library_destination": "library_top",
            "graveyard_to_library_up_to_count": False,
            "graveyard_to_library_activation_cost_mana": "{B}",
            "graveyard_to_library_activation_cost_generic": 0,
            "graveyard_to_library_activation_cost_colors": ["B"],
            "recursion_components": [
                {
                    "target": "creature",
                    "count": 1,
                    "destination": "hand",
                    "target_controller": "self",
                }
            ],
        },
        "review_status": "verified",
        "execution_status": "auto",
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["normalized_name"] == "verge rangers"
    assert expected["logical_rule_key"] == "battle_rule_v1:abc"
    assert expected["oracle_hash"] == "hash123"
    assert expected["min_rule_version"] == 2
    assert expected["required_effect_fields"] == {
            "effect": "topdeck_play",
            "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
            "target": "land",
            "target_graveyard_controller": "opponent",
            "battlefield_controller": "self",
            "count": 1,
            "destination": "play",
            "enters_tapped": True,
            "exiles_self": False,
            "mode_selection": "one_or_both",
            "recursion_mana_value_max": 3,
            "etb_recursion_target": "artifact",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "etb_recursion_up_to_count": False,
            "etb_recursion_mana_value_max": 1,
            "dies_recursion_target": "artifact",
            "dies_recursion_count": 1,
            "dies_recursion_destination": "hand",
            "dies_recursion_exclude_self": True,
            "graveyard_exile_target": "any_card",
            "graveyard_exile_target_count": 3,
            "graveyard_exile_destination": "exile",
            "graveyard_exile_up_to_count": True,
            "graveyard_exile_single_graveyard": True,
            "graveyard_to_library_target": "creature",
            "graveyard_to_library_target_count": 1,
            "graveyard_to_library_destination": "library_top",
            "graveyard_to_library_up_to_count": False,
            "graveyard_to_library_activation_cost_mana": "{B}",
            "graveyard_to_library_activation_cost_generic": 0,
            "graveyard_to_library_activation_cost_colors": ["B"],
            "recursion_components": [
                {
                    "target": "creature",
                "count": 1,
                "destination": "hand",
                "target_controller": "self",
            }
        ],
    }


def test_manifest_checks_from_expected_rule_split_snapshot_and_runtime_fields() -> None:
    rule = {
        "normalized_name": "verge rangers",
        "card_name": "Verge Rangers",
        "oracle_hash": "hash123",
        "logical_rule_key": "battle_rule_v1:abc",
        "review_status": "verified",
        "execution_status": "auto",
        "min_rule_version": 2,
        "required_effect_fields": {
            "effect": "topdeck_play",
            "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
        },
    }

    snapshot_check = builder.snapshot_check_from_expected_rule(rule)
    runtime_check = builder.runtime_check_from_expected_rule(rule)

    assert snapshot_check["required_effect_fields"] == {
        "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
    }
    assert runtime_check["effect"] == "topdeck_play"
    assert runtime_check["required_effect_fields"] == rule["required_effect_fields"]
