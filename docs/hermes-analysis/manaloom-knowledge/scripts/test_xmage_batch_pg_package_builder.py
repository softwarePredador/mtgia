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
            "count_from_x": True,
            "target_count_from_x": True,
            "destination": "play",
            "enters_tapped": True,
            "exiles_self": False,
            "mode_selection": "one_or_both",
            "recursion_mana_value_max": 3,
            "recursion_mana_value_max_from_x": True,
            "target_mana_value_max_from_x": True,
            "pre_recursion_mill_count": 3,
            "etb_draw_count": 2,
            "etb_life_loss": 2,
            "etb_life_gain_amount": 3,
            "etb_damage_amount": 4,
            "etb_damage_target": "creature",
            "etb_remove_effect": "remove_permanent",
            "etb_remove_target": "artifact",
            "etb_token_count": 2,
            "etb_token_name": "Zombie",
            "etb_token_power": 2,
            "etb_token_toughness": 2,
            "etb_add_counters_target": "creature",
            "etb_add_counters_count": 1,
            "etb_add_counters_counter_type": "+1/+1",
            "etb_recursion_target": "artifact",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "etb_recursion_up_to_count": False,
            "etb_recursion_mana_value_max": 1,
            "etb_recursion_mill_count": 2,
            "etb_tutor_target": "basic_land_to_battlefield",
            "etb_tutor_count": 1,
            "tutor_enters_tapped": True,
            "dies_recursion_target": "artifact",
            "dies_recursion_count": 1,
            "dies_recursion_destination": "hand",
            "dies_recursion_exclude_self": True,
            "dies_damage_amount": 2,
            "dies_damage_target": "any_target",
            "dies_damage_optional": True,
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
            "exile_if_dies_from_damage": True,
            "exile_if_dies_target": "creature",
            "keywords": ["haste"],
            "_keywords_are_self": True,
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WBG",
            "produced_mana_symbols": ["W", "B", "G"],
            "mana_activation_requires_tap": True,
            "activation_mana_cost": "{0}",
            "cost_reduction_applies_to": "this_spell",
            "cost_reduction_amount_source": "fixed",
            "cost_reduction_generic": 3,
            "cost_reduction_condition": "opponent_graveyard_cards_at_least",
            "cost_reduction_opponent_graveyard_cards_min": 7,
            "ability_kind": "static_and_activated",
            "activated_effect": "direct_damage",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_damage_amount": 1,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": False,
            "_activated_rule_effects": [
                {
                    "effect": "direct_damage",
                    "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
                    "amount": 1,
                    "damage": 1,
                    "target": "any_target",
                }
            ],
            "xmage_ability_class": "SimpleActivatedAbility",
            "xmage_ability_classes": ["HasteAbility", "SimpleActivatedAbility"],
            "xmage_effect_class": "DamageTargetEffect",
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
            "count_from_x": True,
            "target_count_from_x": True,
            "destination": "play",
            "enters_tapped": True,
            "exiles_self": False,
            "mode_selection": "one_or_both",
            "recursion_mana_value_max": 3,
            "recursion_mana_value_max_from_x": True,
            "target_mana_value_max_from_x": True,
            "pre_recursion_mill_count": 3,
            "etb_draw_count": 2,
            "etb_life_loss": 2,
            "etb_life_gain_amount": 3,
            "etb_damage_amount": 4,
            "etb_damage_target": "creature",
            "etb_remove_effect": "remove_permanent",
            "etb_remove_target": "artifact",
            "etb_token_count": 2,
            "etb_token_name": "Zombie",
            "etb_token_power": 2,
            "etb_token_toughness": 2,
            "etb_add_counters_target": "creature",
            "etb_add_counters_count": 1,
            "etb_add_counters_counter_type": "+1/+1",
            "etb_recursion_target": "artifact",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "etb_recursion_up_to_count": False,
            "etb_recursion_mana_value_max": 1,
            "etb_recursion_mill_count": 2,
            "etb_tutor_target": "basic_land_to_battlefield",
            "etb_tutor_count": 1,
            "tutor_enters_tapped": True,
            "dies_recursion_target": "artifact",
            "dies_recursion_count": 1,
            "dies_recursion_destination": "hand",
            "dies_recursion_exclude_self": True,
            "dies_damage_amount": 2,
            "dies_damage_target": "any_target",
            "dies_damage_optional": True,
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
            "exile_if_dies_from_damage": True,
            "exile_if_dies_target": "creature",
            "keywords": ["haste"],
            "_keywords_are_self": True,
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WBG",
            "produced_mana_symbols": ["W", "B", "G"],
            "mana_activation_requires_tap": True,
            "activation_mana_cost": "{0}",
            "cost_reduction_applies_to": "this_spell",
            "cost_reduction_amount_source": "fixed",
            "cost_reduction_generic": 3,
            "cost_reduction_condition": "opponent_graveyard_cards_at_least",
            "cost_reduction_opponent_graveyard_cards_min": 7,
            "ability_kind": "static_and_activated",
            "activated_effect": "direct_damage",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_damage_amount": 1,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": False,
            "_activated_rule_effects": [
                {
                    "effect": "direct_damage",
                    "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
                    "amount": 1,
                    "damage": 1,
                    "target": "any_target",
                }
            ],
            "xmage_ability_class": "SimpleActivatedAbility",
            "xmage_ability_classes": ["HasteAbility", "SimpleActivatedAbility"],
            "xmage_effect_class": "DamageTargetEffect",
            "recursion_components": [
                {
                    "target": "creature",
                "count": 1,
                "destination": "hand",
                "target_controller": "self",
            }
        ],
    }


def test_manifest_expected_rule_preserves_target_player_draw_fields() -> None:
    proposal = {
        "normalized_name": "inspiration",
        "card_name": "Inspiration",
        "oracle_hash": "hash-target-draw",
        "logical_rule_key": "battle_rule_v1:hash-target-draw",
        "effect_json": {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_target_player_draw_spell_v1",
            "target": "player",
            "target_controller": "target_player",
            "target_preference": "self",
            "target_constraints": {"players": ["any"]},
            "count": 2,
            "draw_count": 2,
            "target_player_draw": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "draw_cards",
        "battle_model_scope": "xmage_fixed_target_player_draw_spell_v1",
        "target": "player",
        "target_controller": "target_player",
        "target_constraints": {"players": ["any"]},
        "target_preference": "self",
        "count": 2,
        "draw_count": 2,
        "target_player_draw": True,
    }


def test_manifest_expected_rule_preserves_activation_discard_cost_fields() -> None:
    proposal = {
        "normalized_name": "goblin picker",
        "card_name": "Goblin Picker",
        "oracle_hash": "hash-activated-discard-draw",
        "logical_rule_key": "battle_rule_v1:hash-activated-discard-draw",
        "effect_json": {
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
            "activated_draw": True,
            "activated_draw_count": 1,
            "activation_cost_mana": "{R}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["R"],
            "activation_requires_tap": True,
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_requires_discard_card": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"]["activation_discard_count"] == 1
    assert expected["required_effect_fields"]["activation_discard_target"] == "any_card"
    assert expected["required_effect_fields"]["activation_requires_discard_card"] is True


def test_manifest_expected_rule_preserves_spell_additional_sacrifice_cost_fields() -> None:
    proposal = {
        "normalized_name": "bone splinters",
        "card_name": "Bone Splinters",
        "oracle_hash": "hash-bone-splinters",
        "logical_rule_key": "battle_rule_v1:hash-bone-splinters",
        "effect_json": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "destination": "graveyard",
            "additional_cost": "sacrifice_creature",
            "requires_sacrifice_creature": True,
            "xmage_additional_cost_class": "SacrificeTargetCost",
            "xmage_additional_cost_target": "creature",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"]["additional_cost"] == "sacrifice_creature"
    assert expected["required_effect_fields"]["requires_sacrifice_creature"] is True
    assert expected["required_effect_fields"]["xmage_additional_cost_class"] == "SacrificeTargetCost"
    assert expected["required_effect_fields"]["xmage_additional_cost_target"] == "creature"


def test_manifest_expected_rule_preserves_dynamic_graveyard_damage_fields() -> None:
    proposal = {
        "normalized_name": "kindle",
        "card_name": "Kindle",
        "oracle_hash": "hash-kindle",
        "logical_rule_key": "battle_rule_v1:hash-kindle",
        "effect_json": {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_dynamic_graveyard_count_damage_spell_v1",
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "damage": 0,
            "damage_amount_source": "graveyard_card_count",
            "damage_base_amount": 2,
            "damage_per_graveyard_count": 1,
            "graveyard_count_scope": "all_graveyards",
            "graveyard_count_card_names": ["Kindle"],
            "graveyard_count_subtypes": ["arcane"],
            "graveyard_count_card_types": ["instant"],
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["damage_amount_source"] == "graveyard_card_count"
    assert required["damage_base_amount"] == 2
    assert required["damage_per_graveyard_count"] == 1
    assert required["graveyard_count_scope"] == "all_graveyards"
    assert required["graveyard_count_card_names"] == ["Kindle"]
    assert required["graveyard_count_subtypes"] == ["arcane"]
    assert required["graveyard_count_card_types"] == ["instant"]


def test_manifest_expected_rule_preserves_composite_damage_draw_components() -> None:
    components = [
        {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
            "amount": 3,
            "damage": 3,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "compose_on_resolution": True,
            "xmage_effect_class": "DamageTargetEffect",
        },
        {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
            "count": 1,
            "compose_on_resolution": True,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
        },
    ]
    proposal = {
        "normalized_name": "ember shot",
        "card_name": "Ember Shot",
        "oracle_hash": "hash-ember-shot",
        "logical_rule_key": "battle_rule_v1:hash-ember-shot",
        "effect_json": {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_fixed_damage_target_and_draw_card_spell_v1",
            "amount": 3,
            "damage": 3,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "draw_count": 1,
            "count": 1,
            "_composite_rule_components": components,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["effect"] == "composite_resolution"
    assert required["battle_model_scope"] == "xmage_fixed_damage_target_and_draw_card_spell_v1"
    assert required["_composite_rule_components"] == components


def test_apply_sql_preserves_existing_backup_table_for_idempotent_rerun() -> None:
    proposal = {
        "normalized_name": "quarry beetle",
        "card_name": "Quarry Beetle",
        "oracle_hash": "hash-quarry",
        "logical_rule_key": "battle_rule_v1:hash-quarry",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_return_graveyard_card_to_battlefield_v1",
            "etb_recursion_target": "land",
            "etb_recursion_destination": "battlefield",
        },
        "deck_role_json": {"category": "unknown", "effect": "creature"},
        "source": "curated",
        "confidence": 0.96,
        "review_status": "verified",
        "execution_status": "auto",
        "notes": "fixture",
    }

    sql = builder.build_apply_sql([proposal], "pg_fixture_backup")

    assert "CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg_fixture_backup AS" in sql
    assert "DROP TABLE" not in sql


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
