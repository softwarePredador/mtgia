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


def test_counter_unless_pays_dynamic_fields_and_execution_scenario_are_manifested() -> None:
    proposal = {
        "normalized_name": "spell stutter",
        "card_name": "Spell Stutter",
        "oracle_hash": "hash-counter",
        "logical_rule_key": "battle_rule_v1:counter",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_unless_controller_pays_generic_v1",
            "target": "spell",
            "counter_unless_pays_generic": 0,
            "counter_unless_pays_amount_source": "controlled_subtype_count",
            "counter_unless_pays_subtype": "faerie",
            "counter_unless_pays_base": 2,
            "counter_unless_pays_per": 1,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert expected["required_effect_fields"]["counter_unless_pays_amount_source"] == "controlled_subtype_count"
    assert expected["required_effect_fields"]["counter_unless_pays_subtype"] == "faerie"
    assert scenario["type"] == "counter_unless_pays_response"
    assert scenario["expected_counter_unless_pays_generic"] == 4
    assert scenario["expected_counter_unless_pays_count"] == 2


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
            "activated_add_counters": True,
            "activated_add_counters_target": "self",
            "activated_add_counters_counter_type": "+1/+1",
            "activated_add_counters_count": 1,
            "spell_cast_add_counters": True,
            "spell_cast_add_counters_target": "self",
            "spell_cast_add_counters_count": 1,
            "spell_cast_add_counters_counter_type": "+1/+1",
            "spell_cast_add_counters_card_types": ["instant", "sorcery"],
            "spell_cast_add_counters_required_colors": ["W", "U"],
            "spell_cast_add_counters_requires_multicolored": False,
            "spell_cast_add_counters_mana_value_min": 2,
            "activated_damage_amount": 1,
            "counter_type": "+1/+1",
            "counter_count": 1,
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
            "activated_add_counters": True,
            "activated_add_counters_target": "self",
            "activated_add_counters_counter_type": "+1/+1",
            "activated_add_counters_count": 1,
            "spell_cast_add_counters": True,
            "spell_cast_add_counters_target": "self",
            "spell_cast_add_counters_count": 1,
            "spell_cast_add_counters_counter_type": "+1/+1",
            "spell_cast_add_counters_card_types": ["instant", "sorcery"],
            "spell_cast_add_counters_required_colors": ["W", "U"],
            "spell_cast_add_counters_requires_multicolored": False,
            "spell_cast_add_counters_mana_value_min": 2,
            "activated_damage_amount": 1,
            "counter_type": "+1/+1",
            "counter_count": 1,
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


def test_manifest_expected_rule_preserves_partial_mana_source_fields() -> None:
    proposal = {
        "normalized_name": "cultivator's caravan",
        "card_name": "Cultivator's Caravan",
        "oracle_hash": "hash-caravan",
        "logical_rule_key": "battle_rule_v1:hash-caravan",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": True,
            "modeled_ability_subset": "mana_source_only",
            "_runtime_partial": True,
            "_runtime_partial_reason": "Only mana source is modeled.",
            "xmage_mana_ability_classes": ["AnyColorManaAbility"],
            "xmage_auxiliary_ability_classes": ["CrewAbility"],
            "xmage_unmodeled_auxiliary_ability_classes": ["CrewAbility"],
            "xmage_unmodeled_effect_classes": [],
            "xmage_effect_classes": [],
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["modeled_ability_subset"] == "mana_source_only"
    assert required["_runtime_partial"] is True
    assert required["xmage_mana_ability_classes"] == ["AnyColorManaAbility"]
    assert required["xmage_unmodeled_auxiliary_ability_classes"] == ["CrewAbility"]


def test_simple_mana_source_execution_scenario_pays_activation_cost() -> None:
    rule = {
        "card_name": "Ceta Disciple",
        "logical_rule_key": "battle_rule_v1:ceta",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": True,
            "activation_mana_cost": "{G}",
        },
    }

    scenario = builder.simple_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["controller_mana"] == {
        "generic": 0,
        "white": 0,
        "blue": 0,
        "black": 0,
        "red": 0,
        "green": 1,
    }
    assert scenario["support_mana_sources"] == [
        {
            "name": "E2E Green Support Source 1",
            "type_line": "Artifact",
            "effect": "ramp_permanent",
            "battle_model_scope": "e2e_support_mana_source_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "G",
            "produced_mana_symbols": ["G"],
            "mana_activation_requires_tap": True,
        }
    ]
    assert scenario["expected_available_mana_after_refresh"] == 1
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expected_sources"] == 2


def test_simple_mana_source_execution_scenario_pays_life_cost() -> None:
    rule = {
        "card_name": "Phyrexian Lens",
        "logical_rule_key": "battle_rule_v1:phyrexian_lens",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": True,
            "activation_life_cost": 1,
        },
    }

    scenario = builder.simple_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["starting_life"] == 40
    assert scenario["expected_life_paid"] == 1
    assert scenario["expected_life_after_refresh"] == 39
    assert scenario["expected_conditional_mana"] == 1


def test_simple_mana_source_execution_scenario_preserves_activation_limit() -> None:
    rule = {
        "card_name": "Abzan Devotee",
        "logical_rule_key": "battle_rule_v1:abzan",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WBG",
            "mana_activation_requires_tap": False,
            "activation_mana_cost": "{1}",
            "activation_limit_per_turn": 1,
        },
    }

    scenario = builder.simple_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["expected_activation_limit_per_turn"] == 1
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expected_sources"] == 2


def test_simple_mana_source_execution_scenario_preserves_enters_tapped_state() -> None:
    rule = {
        "card_name": "Arc Reactor",
        "logical_rule_key": "battle_rule_v1:arc",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 3,
            "produces": "C",
            "produced_mana_symbols": ["C", "C", "C"],
            "mana_activation_requires_tap": True,
            "enters_tapped": True,
        },
    }

    scenario = builder.simple_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["expected_available_mana_after_refresh"] == 0
    assert scenario["expected_sources"] == 0
    assert scenario["expected_tapped"] is True
    assert scenario["source_overrides"] == {"tapped": True}


def test_simple_mana_source_execution_scenario_tracks_two_color_choices_as_conditional() -> None:
    rule = {
        "card_name": "Atarka Monument",
        "logical_rule_key": "battle_rule_v1:atarka",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "RG",
            "mana_activation_requires_tap": True,
        },
    }

    scenario = builder.simple_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["expected_available_mana_after_refresh"] == 1
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expected_sources"] == 1
    assert scenario["expected_tapped"] is True


def test_self_sacrifice_mana_source_execution_scenario_unlocks_spell() -> None:
    rule = {
        "card_name": "Chromatic Sphere",
        "logical_rule_key": "battle_rule_v1:chromatic",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_self_sacrifice_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_source_contextual_only": True,
            "mana_activation_requires_sacrifice": True,
            "activation_requires_sacrifice": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "activation_mana_cost": "{1}",
            "mana_activation_requires_tap": True,
            "activation_requires_tap": True,
        },
    }

    scenario = builder.sacrifice_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "sacrifice_mana_source_activation"
    assert scenario["expected_event"] == "self_sacrifice_mana_source_activated"
    assert scenario["controller_mana"]["generic"] == 1
    assert scenario["unlock_card"]["mana_cost"] == "{G}"
    assert scenario["expected_available_mana_after_activation"] == 1
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expect_source_sacrificed"] is True
    assert scenario["expect_target_sacrificed"] is False


def test_target_sacrifice_mana_source_execution_scenario_seeds_target() -> None:
    rule = {
        "card_name": "Phyrexian Altar",
        "logical_rule_key": "battle_rule_v1:altar",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_target_sacrifice_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_source_contextual_only": True,
            "mana_activation_requires_sacrifice_target": True,
            "activation_requires_sacrifice_target": True,
            "activation_sacrifice_target": "creature",
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": False,
            "activation_requires_tap": False,
        },
    }

    scenario = builder.sacrifice_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "sacrifice_mana_source_activation"
    assert scenario["expected_event"] == "target_sacrifice_mana_source_activated"
    assert scenario["sacrifice_target"]["type_line"] == "Creature - Fixture"
    assert scenario["unlock_card"]["mana_cost"] == "{G}"
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expect_source_sacrificed"] is False
    assert scenario["expect_target_sacrificed"] is True


def test_target_sacrifice_mana_source_execution_scenario_uses_manifest_aliases() -> None:
    rule = {
        "card_name": "Phyrexian Altar",
        "logical_rule_key": "battle_rule_v1:altar",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_target_sacrifice_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_source_contextual_only": True,
            "activation_requires_sacrifice_target": True,
            "activation_sacrifice_target": "creature",
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": False,
            "activation_requires_tap": False,
        },
    }

    scenario = builder.sacrifice_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["expected_event"] == "target_sacrifice_mana_source_activated"
    assert scenario["expect_source_sacrificed"] is False
    assert scenario["expect_target_sacrificed"] is True
    assert scenario["sacrifice_target"]["type_line"] == "Creature - Fixture"


def test_manifest_expected_rule_preserves_library_bottom_pick_fields() -> None:
    proposal = {
        "normalized_name": "shimmer of possibility",
        "card_name": "Shimmer of Possibility",
        "oracle_hash": "hash-shimmer",
        "logical_rule_key": "battle_rule_v1:hash-shimmer",
        "effect_json": {
            "effect": "dig_to_hand",
            "battle_model_scope": "xmage_look_library_pick_to_hand_rest_bottom_spell_v1",
            "look_count": 4,
            "pick_count": 1,
            "count": 1,
            "pick_target": "any_card",
            "target": "any_card",
            "destination": "hand",
            "rest_destination": "library_bottom",
            "library_bottom_order": "random",
            "pick_up_to_count": False,
            "pick_all_matching": False,
            "reveal": False,
            "xmage_effect_class": "LookLibraryAndPickControllerEffect",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["effect"] == "dig_to_hand"
    assert required["battle_model_scope"] == "xmage_look_library_pick_to_hand_rest_bottom_spell_v1"
    assert required["look_count"] == 4
    assert required["pick_count"] == 1
    assert required["rest_destination"] == "library_bottom"
    assert required["library_bottom_order"] == "random"
    assert required["xmage_effect_class"] == "LookLibraryAndPickControllerEffect"


def test_manifest_expected_rule_preserves_combat_damage_draw_fields() -> None:
    proposal = {
        "normalized_name": "scroll thief",
        "card_name": "Scroll Thief",
        "oracle_hash": "hash-scroll-thief",
        "logical_rule_key": "battle_rule_v1:hash-scroll-thief",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_combat_damage_draw_cards_v1",
            "ability_kind": "triggered",
            "trigger": "combat_damage_to_player",
            "trigger_effect": "draw_cards",
            "combat_damage_player_draw": True,
            "combat_damage_draw_count": 1,
            "draw_count": 1,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
            "xmage_ability_class": "DealsCombatDamageToAPlayerTriggeredAbility",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["effect"] == "creature"
    assert required["battle_model_scope"] == "xmage_creature_combat_damage_draw_cards_v1"
    assert required["trigger"] == "combat_damage_to_player"
    assert required["trigger_effect"] == "draw_cards"
    assert required["combat_damage_player_draw"] is True
    assert required["combat_damage_draw_count"] == 1
    assert required["draw_count"] == 1
    assert required["xmage_effect_class"] == "DrawCardSourceControllerEffect"
    assert required["xmage_ability_class"] == "DealsCombatDamageToAPlayerTriggeredAbility"


def test_manifest_expected_rule_preserves_etb_optional_and_dynamic_draw_fields() -> None:
    proposal = {
        "normalized_name": "fissure wizard",
        "card_name": "Fissure Wizard",
        "oracle_hash": "hash-fissure-wizard",
        "logical_rule_key": "battle_rule_v1:hash-fissure-wizard",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_optional_discard_draw_cards_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "trigger_effect": "optional_discard_draw",
            "etb_optional_discard_draw": True,
            "etb_optional_discard_count": 1,
            "etb_optional_discard_draw_count": 1,
            "draw_count": 1,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
            "xmage_ability_class": "EntersBattlefieldTriggeredAbility",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["etb_optional_discard_draw"] is True
    assert required["etb_optional_discard_count"] == 1
    assert required["etb_optional_discard_draw_count"] == 1
    assert required["draw_count"] == 1

    proposal["effect_json"] = {
        "effect": "creature",
        "battle_model_scope": "xmage_creature_etb_dynamic_draw_cards_v1",
        "ability_kind": "triggered",
        "trigger": "enters_battlefield",
        "trigger_effect": "dynamic_draw_cards",
        "etb_dynamic_draw": True,
        "draw_count_source": "controlled_creatures_with_color",
        "etb_draw_count_source": "controlled_creatures_with_color",
        "draw_count_color": "green",
        "etb_draw_count_color": "green",
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]
    assert required["etb_dynamic_draw"] is True
    assert required["draw_count_source"] == "controlled_creatures_with_color"
    assert required["etb_draw_count_source"] == "controlled_creatures_with_color"
    assert required["draw_count_color"] == "green"
    assert required["etb_draw_count_color"] == "green"


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
            "activation_discard_random": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"]["activation_discard_count"] == 1
    assert expected["required_effect_fields"]["activation_discard_target"] == "any_card"
    assert expected["required_effect_fields"]["activation_requires_discard_card"] is True
    assert expected["required_effect_fields"]["activation_discard_random"] is True


def test_manifest_builds_simple_activated_damage_execution_scenario() -> None:
    rule = {
        "normalized_name": "stormbind",
        "card_name": "Stormbind",
        "oracle_hash": "hash-stormbind",
        "logical_rule_key": "battle_rule_v1:hash-stormbind",
        "required_effect_fields": {
            "effect": "enchantment",
            "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_damage_amount": 2,
            "target": "any_target",
            "activation_cost_mana": "{2}",
            "activation_cost_generic": 2,
            "activation_cost_colors": [],
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_requires_discard_card": True,
            "activation_discard_random": True,
        },
    }

    scenario = builder.simple_activated_damage_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_damage"
    assert scenario["expected_damage"] == 2
    assert scenario["expected_discard_count"] == 1
    assert scenario["expected_discard_target"] == "any_card"
    assert scenario["expected_discard_random"] is True
    assert scenario["controller_mana"]["generic"] == 2
    assert len(scenario["controller_hand"]) == 2


def test_manifest_builds_damage_each_opponent_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "sizzle",
        "card_name": "Sizzle",
        "oracle_hash": "hash-sizzle",
        "logical_rule_key": "battle_rule_v1:hash-sizzle",
        "required_effect_fields": {
            "effect": "damage_each_opponent",
            "battle_model_scope": "spell_damage_each_opponent_v1",
            "ability_kind": "one_shot",
            "amount": 3,
            "damage": 3,
            "target_controller": "opponents",
            "sorcery": True,
        },
    }

    scenario = builder.damage_each_opponent_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "damage_each_opponent_spell"
    assert scenario["card"]["name"] == "Sizzle"
    assert scenario["card"]["type_line"] == "Sorcery"
    assert scenario["expected_damage"] == 3
    assert scenario["opponent_life"] == 9
    assert scenario["second_opponent_life"] == 11


def test_manifest_builds_simple_activated_tap_target_execution_scenario() -> None:
    rule = {
        "normalized_name": "akroan jailer",
        "card_name": "Akroan Jailer",
        "oracle_hash": "hash-akroan-jailer",
        "logical_rule_key": "battle_rule_v1:hash-akroan-jailer",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_tap_target_v1",
            "activated_effect": "tap_target",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_tap_target_v1",
            "activated_tap_target": "creature",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "activation_cost_mana": "{2}{W}",
            "activation_cost_generic": 2,
            "activation_cost_colors": ["W"],
            "activation_requires_tap": True,
        },
    }

    scenario = builder.simple_activated_tap_target_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_tap_target"
    assert scenario["expected_target"] == "creature"
    assert scenario["expected_tapped_source"] is True
    assert scenario["controller_mana"]["generic"] == 2
    assert scenario["controller_mana"]["white"] == 1


def test_manifest_builds_simple_activated_destroy_execution_scenario() -> None:
    rule = {
        "normalized_name": "caustic caterpillar",
        "card_name": "Caustic Caterpillar",
        "oracle_hash": "hash-caustic-caterpillar",
        "logical_rule_key": "battle_rule_v1:hash-caustic-caterpillar",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_effect": "destroy_target",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_remove_effect": "remove_permanent",
            "activated_remove_target": "artifact_or_enchantment",
            "target": "permanent",
            "target_constraints": {"card_types_any": ["artifact", "enchantment"]},
            "destination": "graveyard",
            "activation_cost_mana": "{1}{G}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["G"],
            "activation_requires_sacrifice": True,
            "activated_self_sacrifice_destroy": True,
        },
    }

    scenario = builder.simple_activated_destroy_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_destroy"
    assert scenario["expected_sacrificed_source"] is True
    assert scenario["expected_destination"] == "graveyard"
    assert scenario["controller_mana"]["generic"] == 1
    assert scenario["controller_mana"]["green"] == 1
    assert scenario["target"]["type_line"] == "Artifact"


def test_manifest_builds_simple_activated_self_keyword_execution_scenario() -> None:
    rule = {
        "normalized_name": "cobalt golem",
        "card_name": "Cobalt Golem",
        "oracle_hash": "hash-cobalt-golem",
        "logical_rule_key": "battle_rule_v1:hash-cobalt-golem",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_self_keyword_until_eot_v1",
            "activated_effect": "self_keyword_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_self_keyword_until_eot_v1",
            "target": "self",
            "target_controller": "self",
            "granted_keywords_until_eot": ["flying"],
            "activation_cost_mana": "{2}{R/W}",
            "activation_cost_generic": 2,
            "activation_cost_colors": ["R/W"],
            "activation_requires_tap": False,
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_requires_discard_card": True,
        },
    }

    scenario = builder.simple_activated_self_keyword_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_self_keyword"
    assert scenario["expected_keywords"] == ["flying"]
    assert scenario["expected_tapped_source"] is False
    assert scenario["controller_mana"]["generic"] == 2
    assert scenario["controller_mana"]["red"] == 1
    assert scenario["controller_mana"]["white"] == 0
    assert scenario["expected_discard_count"] == 1
    assert len(scenario["controller_hand"]) == 2


def test_manifest_builds_simple_activated_self_boost_execution_scenario() -> None:
    rule = {
        "normalized_name": "rootwalla",
        "card_name": "Rootwalla",
        "oracle_hash": "hash-rootwalla",
        "logical_rule_key": "battle_rule_v1:hash-rootwalla",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "activated_effect": "self_stat_modifier_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "target": "self",
            "target_controller": "self",
            "power_delta": 2,
            "toughness_delta": 2,
            "activation_cost_mana": "{1}{G}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["G"],
            "activation_limit_per_turn": 1,
        },
    }

    scenario = builder.simple_activated_self_boost_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_self_boost"
    assert scenario["card"]["name"] == "Rootwalla"
    assert scenario["controller_mana"]["generic"] == 1
    assert scenario["controller_mana"]["green"] == 1
    assert scenario["expected_power_delta"] == 2
    assert scenario["expected_toughness_delta"] == 2
    assert scenario["expected_activation_limit_per_turn"] == 1


def test_manifest_builds_target_keyword_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "double cleave",
        "card_name": "Double Cleave",
        "oracle_hash": "hash-double-cleave",
        "logical_rule_key": "battle_rule_v1:hash-double-cleave",
        "required_effect_fields": {
            "effect": "stat_modifier_until_eot",
            "battle_model_scope": "xmage_fixed_keyword_target_creature_until_eot_spell_v1",
            "target": "creature",
            "target_controller": "any",
            "target_constraints": {"card_types": ["creature"]},
            "power_delta": 0,
            "toughness_delta": 0,
            "granted_keywords_until_eot": ["double_strike"],
        },
    }

    scenario = builder.target_keyword_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "stat_modifier_until_eot"
    assert scenario["expected_power_delta"] == 0
    assert scenario["expected_toughness_delta"] == 0
    assert scenario["expected_keywords"] == ["double_strike"]


def test_manifest_builds_controlled_stat_modifier_filtered_execution_scenario() -> None:
    rule = {
        "normalized_name": "guardians' pledge",
        "card_name": "Guardians' Pledge",
        "oracle_hash": "hash-guardians-pledge",
        "logical_rule_key": "battle_rule_v1:hash-guardians-pledge",
        "required_effect_fields": {
            "effect": "controlled_stat_modifier_until_eot",
            "battle_model_scope": "xmage_fixed_boost_controlled_creatures_until_eot_spell_v1",
            "target": "controlled_w_creatures",
            "target_controller": "self",
            "target_constraints": {
                "controller": "self",
                "card_types": ["creature"],
                "creature_filter": {"colors": ["W"]},
            },
            "creature_filter": {"colors": ["W"]},
            "power_delta": 2,
            "toughness_delta": 2,
        },
    }

    scenario = builder.controlled_stat_modifier_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "controlled_stat_modifier_until_eot"
    assert scenario["expected_power_delta"] == 2
    assert scenario["expected_toughness_delta"] == 2
    assert scenario["expected_creature_filter"] == {"colors": ["W"]}
    assert scenario["matching_target"]["colors"] == ["W"]
    assert scenario["nonmatching_target"]["colors"] == ["B"]
    assert scenario["opponent_target"]["colors"] == ["W"]


def test_manifest_builds_attack_self_boost_execution_scenario() -> None:
    rule = {
        "normalized_name": "benalish veteran",
        "card_name": "Benalish Veteran",
        "oracle_hash": "hash-benalish-veteran",
        "logical_rule_key": "battle_rule_v1:hash-benalish-veteran",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_attack_self_boost_until_eot_v1",
            "trigger": "attack",
            "trigger_effect": "self_stat_modifier_until_eot",
            "power_delta": 1,
            "toughness_delta": 1,
        },
    }

    scenario = builder.attack_self_boost_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "attack_self_boost"
    assert scenario["card"]["name"] == "Benalish Veteran"
    assert scenario["expected_power_delta"] == 1
    assert scenario["expected_toughness_delta"] == 1


def test_manifest_builds_becomes_blocked_self_boost_execution_scenario() -> None:
    rule = {
        "normalized_name": "gang of elk",
        "card_name": "Gang of Elk",
        "oracle_hash": "hash-gang-of-elk",
        "logical_rule_key": "battle_rule_v1:hash-gang-of-elk",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_becomes_blocked_self_boost_until_eot_v1",
            "trigger": "becomes_blocked",
            "trigger_effect": "self_stat_modifier_until_eot",
            "power_delta": 2,
            "toughness_delta": 2,
            "blocker_count_mode": "per_blocker",
        },
    }

    scenario = builder.becomes_blocked_self_boost_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "becomes_blocked_self_boost"
    assert scenario["card"]["name"] == "Gang of Elk"
    assert scenario["expected_base_power_delta"] == 2
    assert scenario["expected_base_toughness_delta"] == 2
    assert scenario["expected_blocker_count_mode"] == "per_blocker"
    assert scenario["blocker_count"] == 3


def test_manifest_builds_single_target_exile_execution_scenario() -> None:
    rule = {
        "normalized_name": "radiant purge",
        "card_name": "Radiant Purge",
        "oracle_hash": "hash-radiant-purge",
        "logical_rule_key": "battle_rule_v1:hash-radiant-purge",
        "required_effect_fields": {
            "effect": "remove_permanent",
            "battle_model_scope": "xmage_exile_target_spell_v1",
            "target": "permanent",
            "target_constraints": {"card_types": ["creature", "enchantment"], "color_count_min": 2},
            "destination": "exile",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["expected_effect"] == "remove_permanent"
    assert scenario["expected_destination"] == "exile"
    assert scenario["target"]["colors"] == ["W", "U"]
    assert scenario["nonmatching_target"]["colors"] == ["W"]


def test_single_target_removal_scenario_uses_illegal_fixture_for_simple_creature_target() -> None:
    rule = {
        "normalized_name": "oblivion strike",
        "card_name": "Oblivion Strike",
        "oracle_hash": "hash-oblivion-strike",
        "logical_rule_key": "battle_rule_v1:hash-oblivion-strike",
        "required_effect_fields": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_exile_target_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "destination": "exile",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["target"]["type_line"].startswith("Creature")
    assert scenario["nonmatching_target"]["type_line"] == "Land"


def test_single_target_bounce_scenario_moves_target_to_hand() -> None:
    rule = {
        "normalized_name": "cut the earthly bond",
        "card_name": "Cut the Earthly Bond",
        "oracle_hash": "hash-cut-the-earthly-bond",
        "logical_rule_key": "battle_rule_v1:hash-cut-the-earthly-bond",
        "required_effect_fields": {
            "effect": "remove_permanent",
            "battle_model_scope": "xmage_return_target_to_hand_spell_v1",
            "target": "enchanted_permanent",
            "target_constraints": {"card_types": ["permanent"], "enchanted": True},
            "destination": "hand",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["expected_destination"] == "hand"
    assert scenario["target"]["enchanted"] is True
    assert scenario["nonmatching_target"].get("enchanted") is False


def test_multi_target_removal_scenario_uses_declared_target_count() -> None:
    rule = {
        "normalized_name": "into the void",
        "card_name": "Into the Void",
        "oracle_hash": "hash-into-the-void",
        "logical_rule_key": "battle_rule_v1:hash-into-the-void",
        "required_effect_fields": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_return_target_to_hand_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "destination": "hand",
            "target_count_min": 0,
            "target_count_max": 2,
            "max_targets": 2,
            "up_to_count": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "multi_target_removal"
    assert scenario["expected_destination"] == "hand"
    assert scenario["expected_target_count"] == 2
    assert len(scenario["targets"]) == 2
    assert builder.single_target_removal_execution_scenario_from_expected_rule(rule) is None


def test_multi_target_damage_scenario_exercises_divided_damage() -> None:
    rule = {
        "normalized_name": "arc lightning",
        "card_name": "Arc Lightning",
        "oracle_hash": "hash-arc-lightning",
        "logical_rule_key": "battle_rule_v1:hash-arc-lightning",
        "required_effect_fields": {
            "effect": "multi_target_damage",
            "battle_model_scope": "xmage_fixed_multi_target_damage_spell_v1",
            "amount": 3,
            "damage": 3,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "target_count_min": 1,
            "target_count_max": 3,
            "max_targets": 3,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "multi_target_damage"
    assert scenario["expected_total_damage"] == 3
    assert scenario["expected_target_count"] == 3
    assert len(scenario["targets"]) == 3


def test_single_target_removal_scenario_models_excluded_color_and_combat_state() -> None:
    rule = {
        "normalized_name": "assassins blade",
        "card_name": "Assassin's Blade",
        "oracle_hash": "hash-assassins-blade",
        "logical_rule_key": "battle_rule_v1:hash-assassins-blade",
        "required_effect_fields": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {
                "card_types": ["creature"],
                "combat_state": "attacking",
                "exclude_colors": ["B"],
            },
            "destination": "graveyard",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["target"]["attacking"] is True
    assert scenario["target"]["colors"] == ["W"]
    assert scenario["nonmatching_target"]["colors"] == ["B"]


def test_single_target_removal_scenario_models_excluded_card_type() -> None:
    rule = {
        "normalized_name": "expunge",
        "card_name": "Expunge",
        "oracle_hash": "hash-expunge",
        "logical_rule_key": "battle_rule_v1:hash-expunge",
        "required_effect_fields": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {
                "card_types": ["creature"],
                "exclude_card_types": ["artifact"],
                "exclude_colors": ["B"],
            },
            "destination": "graveyard",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["target"]["type_line"].startswith("Creature")
    assert scenario["target"]["colors"] == ["W"]
    assert "Artifact Creature" in scenario["nonmatching_target"]["type_line"]
    assert scenario["nonmatching_target"]["colors"] == ["B"]


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


def test_manifest_expected_rule_preserves_extended_board_wipe_fields() -> None:
    proposal = {
        "normalized_name": "planar cleansing",
        "card_name": "Planar Cleansing",
        "oracle_hash": "hash-planar-cleansing",
        "logical_rule_key": "battle_rule_v1:hash-planar-cleansing",
        "effect_json": {
            "effect": "board_wipe",
            "battle_model_scope": "xmage_destroy_all_matching_permanents_spell_v1",
            "destroy_card_types": ["permanent"],
            "destroy_controller": "opponents_control",
            "destroy_required_colors": ["W"],
            "destroy_excluded_colors": ["G"],
            "destroy_required_subtypes": ["plains"],
            "destroy_excluded_subtypes": ["aura"],
            "destroy_exclude_card_types": ["land"],
            "destroy_tapped_state": "tapped",
            "destroy_nonbasic_lands": True,
            "destroy_mana_value_lte": 3,
            "destroy_power_gte": 4,
            "destroy_toughness_gte": 4,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["destroy_card_types"] == ["permanent"]
    assert required["destroy_controller"] == "opponents_control"
    assert required["destroy_required_colors"] == ["W"]
    assert required["destroy_excluded_colors"] == ["G"]
    assert required["destroy_required_subtypes"] == ["plains"]
    assert required["destroy_excluded_subtypes"] == ["aura"]
    assert required["destroy_exclude_card_types"] == ["land"]
    assert required["destroy_tapped_state"] == "tapped"
    assert required["destroy_nonbasic_lands"] is True
    assert required["destroy_mana_value_lte"] == 3
    assert required["destroy_power_gte"] == 4
    assert required["destroy_toughness_gte"] == 4

    proposal["effect_json"] = {
        "effect": "damage_wipe",
        "battle_model_scope": "xmage_fixed_damage_all_matching_permanents_spell_v1",
        "amount": 2,
        "damage": 2,
        "damage_scope": "each_nonartifact_creature",
    }
    expected = builder.expected_rule_from_proposal(proposal)
    assert expected["required_effect_fields"]["damage_scope"] == "each_nonartifact_creature"


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


def test_manifest_expected_rule_preserves_zero_amount_for_x_damage() -> None:
    proposal = {
        "normalized_name": "blaze",
        "card_name": "Blaze",
        "oracle_hash": "hash-blaze",
        "logical_rule_key": "battle_rule_v1:hash-blaze",
        "effect_json": {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_x_damage_target_spell_v1",
            "amount": 0,
            "damage": 0,
            "damage_amount_source": "x_value",
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["amount"] == 0
    assert required["damage"] == 0
    assert required["damage_amount_source"] == "x_value"


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


def test_safe_ident_preserves_timestamp_suffix_when_truncated() -> None:
    ident = builder.safe_ident("PG485_activated_damage_discard_cost_new_server_20260705_055236")

    assert len(ident) <= 56
    assert ident.endswith("20260705_055236")


def test_existing_backup_table_from_manifest_ignores_truncated_timestamp(tmp_path) -> None:
    manifest = tmp_path / "manifest.json"
    manifest.write_text(
        '{"backup_table":"manaloom_deploy_audit.pg485_activated_damage_discard_cost_new_server_20260705_"}',
        encoding="utf-8",
    )

    assert builder.existing_backup_table_from_manifest(manifest) is None

    manifest.write_text(
        '{"backup_table":"manaloom_deploy_audit.pg485_activated_damage_20260705_055236"}',
        encoding="utf-8",
    )

    assert builder.existing_backup_table_from_manifest(manifest) == "pg485_activated_damage_20260705_055236"


def test_manifest_expected_rule_preserves_contextual_mana_source_field() -> None:
    proposal = {
        "normalized_name": "wild cantor",
        "card_name": "Wild Cantor",
        "oracle_hash": "hash-contextual-mana",
        "logical_rule_key": "battle_rule_v1:hash-contextual-mana",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_self_sacrifice_mana_source_permanent_v1",
            "ability_kind": "activated_mana",
            "is_mana_source": True,
            "mana_source_contextual_only": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": False,
            "activation_requires_tap": False,
            "activation_requires_sacrifice": True,
            "permanent_type": "creature",
            "xmage_ability_class": "AnyColorManaAbility",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "ramp_permanent",
        "battle_model_scope": "xmage_self_sacrifice_mana_source_permanent_v1",
        "ability_kind": "activated_mana",
        "is_mana_source": True,
        "mana_source_contextual_only": True,
        "mana_produced": 1,
        "produces": "WUBRG",
        "mana_activation_requires_tap": False,
        "activation_requires_tap": False,
        "activation_requires_sacrifice": True,
        "permanent_type": "creature",
        "xmage_ability_class": "AnyColorManaAbility",
    }


def test_manifest_expected_rule_preserves_tap_and_sacrifice_mana_fields() -> None:
    proposal = {
        "normalized_name": "eye of ramos",
        "card_name": "Eye of Ramos",
        "oracle_hash": "hash-ramos",
        "logical_rule_key": "battle_rule_v1:hash-ramos",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_tap_and_self_sacrifice_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "U",
            "produced_mana_symbols": ["U"],
            "mana_activation_requires_tap": True,
            "sacrifice_mana_source_contextual_only": True,
            "sacrifice_mana_produced": 1,
            "sacrifice_produces": "U",
            "sacrifice_produced_mana_symbols": ["U"],
            "sacrifice_mana_activation_requires_tap": False,
            "sacrifice_activation_requires_tap": False,
            "sacrifice_mana_activation_requires_sacrifice": True,
            "sacrifice_activation_requires_sacrifice": True,
            "permanent_type": "artifact",
            "ability_kind": "mana_and_sacrifice_mana",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "ramp_permanent",
        "battle_model_scope": "xmage_tap_and_self_sacrifice_mana_source_permanent_v1",
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "U",
        "produced_mana_symbols": ["U"],
        "mana_activation_requires_tap": True,
        "sacrifice_mana_source_contextual_only": True,
        "sacrifice_mana_produced": 1,
        "sacrifice_produces": "U",
        "sacrifice_produced_mana_symbols": ["U"],
        "sacrifice_mana_activation_requires_tap": False,
        "sacrifice_activation_requires_tap": False,
        "sacrifice_mana_activation_requires_sacrifice": True,
        "sacrifice_activation_requires_sacrifice": True,
        "permanent_type": "artifact",
        "ability_kind": "mana_and_sacrifice_mana",
    }


def test_manifest_expected_rule_preserves_dies_mana_fields() -> None:
    proposal = {
        "normalized_name": "cathodion",
        "card_name": "Cathodion",
        "oracle_hash": "hash-cathodion",
        "logical_rule_key": "battle_rule_v1:hash-cathodion",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_dies_add_fixed_mana_v1",
            "ability_kind": "triggered",
            "trigger": "dies",
            "trigger_effect": "add_mana",
            "permanent_type": "artifact_creature",
            "dies_mana_produced": 3,
            "dies_produces": "C",
            "dies_produced_mana_symbols": ["C", "C", "C"],
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_dies_add_fixed_mana_v1",
        "ability_kind": "triggered",
        "trigger": "dies",
        "trigger_effect": "add_mana",
        "permanent_type": "artifact_creature",
        "dies_mana_produced": 3,
        "dies_produces": "C",
        "dies_produced_mana_symbols": ["C", "C", "C"],
    }


def test_manifest_expected_rule_preserves_aura_static_power_toughness_fields() -> None:
    proposal = {
        "normalized_name": "dead weight",
        "card_name": "Dead Weight",
        "oracle_hash": "hash-dead-weight",
        "logical_rule_key": "battle_rule_v1:dead-weight",
        "effect_json": {
            "effect": "aura_static_attachment",
            "battle_model_scope": "xmage_aura_static_power_toughness_attachment_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "zone": "battlefield"},
            "enchant_target": "creature",
            "enchant_target_controller": "any",
            "power_boost": -2,
            "toughness_boost": -2,
            "static_power_bonus": -2,
            "static_toughness_bonus": -2,
            "aura": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "aura_static_attachment",
        "battle_model_scope": "xmage_aura_static_power_toughness_attachment_v1",
        "target": "creature",
        "target_constraints": {"card_types": ["creature"], "zone": "battlefield"},
        "enchant_target": "creature",
        "enchant_target_controller": "any",
        "static_power_bonus": -2,
        "static_toughness_bonus": -2,
        "power_boost": -2,
        "toughness_boost": -2,
    }


def test_manifest_expected_rule_preserves_static_controlled_keyword_fields() -> None:
    proposal = {
        "normalized_name": "groundshaker sliver",
        "card_name": "Groundshaker Sliver",
        "oracle_hash": "hash-groundshaker",
        "logical_rule_key": "battle_rule_v1:groundshaker-sliver",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_static_controlled_keyword_grant_v1",
            "static_effect": "controlled_keyword_grant",
            "static_applies_to": "creatures_you_control",
            "static_granted_keywords": ["trample"],
            "static_required_subtypes": ["sliver"],
            "static_exclude_source": False,
            "target": "controlled_creatures",
            "target_controller": "self",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "creature",
        "battle_model_scope": "xmage_static_controlled_keyword_grant_v1",
        "target": "controlled_creatures",
        "target_controller": "self",
        "static_effect": "controlled_keyword_grant",
        "static_applies_to": "creatures_you_control",
        "static_exclude_source": False,
        "static_granted_keywords": ["trample"],
        "static_required_subtypes": ["sliver"],
    }


def test_manifest_expected_rule_preserves_static_controlled_pt_filtered_fields() -> None:
    proposal = {
        "normalized_name": "dire fleet neckbreaker",
        "card_name": "Dire Fleet Neckbreaker",
        "oracle_hash": "hash-neckbreaker",
        "logical_rule_key": "battle_rule_v1:dire-fleet-neckbreaker",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_static_controlled_power_toughness_boost_v1",
            "static_effect": "controlled_power_toughness_boost",
            "static_applies_to": "creatures_you_control",
            "static_power_bonus": 2,
            "static_toughness_bonus": 0,
            "static_required_subtypes": ["pirate"],
            "static_required_combat_state": "attacking",
            "static_exclude_source": False,
            "target": "controlled_creatures",
            "target_controller": "self",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "creature",
        "battle_model_scope": "xmage_static_controlled_power_toughness_boost_v1",
        "target": "controlled_creatures",
        "target_controller": "self",
        "static_effect": "controlled_power_toughness_boost",
        "static_applies_to": "creatures_you_control",
        "static_power_bonus": 2,
        "static_toughness_bonus": 0,
        "static_exclude_source": False,
        "static_required_subtypes": ["pirate"],
        "static_required_combat_state": "attacking",
    }


def test_static_controlled_pt_execution_scenario_uses_filter_negative_and_opponent() -> None:
    rule = {
        "normalized_name": "builder's blessing",
        "card_name": "Builder's Blessing",
        "logical_rule_key": "battle_rule_v1:builders-blessing",
        "required_effect_fields": {
            "effect": "passive",
            "battle_model_scope": "xmage_static_controlled_power_toughness_boost_v1",
            "static_effect": "controlled_power_toughness_boost",
            "static_power_bonus": 0,
            "static_toughness_bonus": 2,
            "static_required_tapped_state": "untapped",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "static_controlled_power_toughness_boost"
    assert scenario["expected_power"] == 2
    assert scenario["expected_toughness"] == 4
    assert scenario["matching_target"]["tapped"] is False
    assert scenario["nonmatching_target"]["tapped"] is True
    assert scenario["opponent_target"]["tapped"] is False


def test_static_controlled_keyword_execution_scenario_uses_filter_negative_and_opponent() -> None:
    rule = {
        "normalized_name": "roughshod mentor",
        "card_name": "Roughshod Mentor",
        "logical_rule_key": "battle_rule_v1:roughshod-mentor",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_static_controlled_keyword_grant_v1",
            "static_effect": "controlled_keyword_grant",
            "static_granted_keywords": ["trample"],
            "static_required_colors": ["G"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "static_controlled_keyword"
    assert scenario["expected_keyword"] == "trample"
    assert scenario["matching_target"]["colors"] == ["G"]
    assert scenario["nonmatching_target"]["colors"] == ["U"]
    assert scenario["opponent_target"]["colors"] == ["G"]


def test_aura_static_power_toughness_execution_scenario_targets_debuff_to_opponent() -> None:
    rule = {
        "normalized_name": "dead weight",
        "card_name": "Dead Weight",
        "logical_rule_key": "battle_rule_v1:dead-weight",
        "required_effect_fields": {
            "effect": "aura_static_attachment",
            "battle_model_scope": "xmage_aura_static_power_toughness_attachment_v1",
            "enchant_target_controller": "any",
            "power_boost": -2,
            "toughness_boost": -2,
            "static_power_bonus": -2,
            "static_toughness_bonus": -2,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario == {
        "name": "Dead Weight aura static P/T attaches",
        "type": "aura_static_power_toughness_attachment",
        "card": {"name": "Dead Weight"},
        "target": {
            "name": "E2E Aura Target for Dead Weight",
            "type_line": "Creature - Soldier",
            "base_power": 2,
            "base_toughness": 2,
            "power": 2,
            "toughness": 2,
        },
        "target_owner": "opponent",
        "expected_power": 0,
        "expected_toughness": 0,
        "expected_moved_to_graveyard": True,
        "expected_source": "Dead Weight",
        "logical_rule_key": "battle_rule_v1:dead-weight",
    }


def test_aura_static_power_toughness_execution_scenario_targets_boost_to_controller() -> None:
    rule = {
        "normalized_name": "giant strength",
        "card_name": "Giant Strength",
        "logical_rule_key": "battle_rule_v1:giant-strength",
        "required_effect_fields": {
            "effect": "aura_static_attachment",
            "battle_model_scope": "xmage_aura_static_power_toughness_attachment_v1",
            "enchant_target_controller": "any",
            "power_boost": 2,
            "toughness_boost": 2,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "aura_static_power_toughness_attachment"
    assert scenario["target_owner"] == "controller"
    assert scenario["expected_power"] == 4
    assert scenario["expected_toughness"] == 4
    assert scenario["expected_moved_to_graveyard"] is False


def test_creature_etb_create_treasure_execution_scenario() -> None:
    rule = {
        "normalized_name": "prosperous pirates",
        "card_name": "Prosperous Pirates",
        "logical_rule_key": "battle_rule_v1:prosperous-pirates",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_create_treasure_v1",
            "etb_treasure_count": 2,
            "treasure_count": 2,
            "keywords": ["defender"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario == {
        "name": "Prosperous Pirates ETB creates Treasure",
        "type": "creature_etb_create_treasure",
        "card": {
            "name": "Prosperous Pirates",
            "type_line": "Creature - Pirate",
            "effect": "creature",
        },
        "expected_treasure_count": 2,
        "expected_keywords": ["defender"],
        "logical_rule_key": "battle_rule_v1:prosperous-pirates",
    }


def test_conditional_creature_etb_create_treasure_execution_scenario_sets_lands() -> None:
    rule = {
        "normalized_name": "ticket tortoise",
        "card_name": "Ticket Tortoise",
        "logical_rule_key": "battle_rule_v1:ticket-tortoise",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_create_treasure_v1",
            "etb_treasure_count": 1,
            "treasure_count": 1,
            "etb_treasure_condition": "opponent_controls_more_lands",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_etb_create_treasure"
    assert scenario["expected_condition"] == "opponent_controls_more_lands"
    assert scenario["controller_land_count"] == 1
    assert scenario["opponent_land_count"] == 2


def test_creature_etb_scry_execution_scenario() -> None:
    rule = {
        "normalized_name": "omenspeaker",
        "card_name": "Omenspeaker",
        "logical_rule_key": "battle_rule_v1:omenspeaker",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_scry_v1",
            "trigger": "enters_battlefield",
            "etb_trigger_effect": "scry",
            "etb_scry_count": 2,
            "trigger_scry_count": 2,
            "keywords": ["flying"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_etb_scry"
    assert scenario["expected_scry_count"] == 2
    assert scenario["expected_keywords"] == ["flying"]
    assert scenario["card"]["name"] == "Omenspeaker"
    assert scenario["logical_rule_key"] == "battle_rule_v1:omenspeaker"


def test_creature_etb_library_pick_bottom_execution_scenario() -> None:
    rule = {
        "normalized_name": "augur of bolas",
        "card_name": "Augur of Bolas",
        "logical_rule_key": "battle_rule_v1:augur-of-bolas",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_look_library_pick_to_hand_rest_bottom_v1",
            "trigger": "enters_battlefield",
            "etb_library_look_count": 3,
            "etb_library_pick_count": 1,
            "etb_library_pick_target": "instant_or_sorcery",
            "etb_library_rest_destination": "library_bottom",
            "etb_library_pick_up_to_count": True,
            "etb_library_bottom_order": "any",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_etb_library_pick"
    assert scenario["expected_look_count"] == 3
    assert scenario["expected_pick_target"] == "instant_or_sorcery"
    assert scenario["expected_rest_destination"] == "library_bottom"
    assert scenario["expected_picked"] == ["E2E Preferred Match"]
    assert scenario["card"]["name"] == "Augur of Bolas"
    assert scenario["logical_rule_key"] == "battle_rule_v1:augur-of-bolas"


def test_creature_dies_create_tokens_execution_scenario() -> None:
    rule = {
        "normalized_name": "carrier thrall",
        "card_name": "Carrier Thrall",
        "logical_rule_key": "battle_rule_v1:carrier-thrall",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_dies_create_tokens_v1",
            "dies_trigger_effect": "token_maker",
            "dies_token_count": 1,
            "dies_token_name": "Eldrazi Scion Token",
            "dies_token_power": 1,
            "dies_token_toughness": 1,
            "dies_token_subtype": "Eldrazi Scion",
            "dies_token_colors": [],
            "dies_token_sacrifice_for_colorless_mana": True,
            "dies_token_mana_produced": 1,
            "dies_token_produces": "C",
            "dies_token_produced_mana_symbols": ["C"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario == {
        "name": "Carrier Thrall dies and creates modeled creature tokens",
        "type": "creature_dies_create_tokens",
        "card": {
            "name": "Carrier Thrall",
            "type_line": "Creature",
            "effect": "creature",
        },
        "expected_token": {
            "name": "Eldrazi Scion Token",
            "count": 1,
            "power": 1,
            "toughness": 1,
            "subtype": "Eldrazi Scion",
            "colors": [],
            "keywords": [],
            "artifact": False,
            "tapped": False,
            "sacrifice_for_colorless_mana": True,
            "mana_produced": 1,
            "produces": "C",
            "produced_mana_symbols": ["C"],
        },
        "expected_keywords": [],
        "logical_rule_key": "battle_rule_v1:carrier-thrall",
    }


def test_creature_dies_create_tokens_execution_scenario_preserves_artifact_tapped_token() -> None:
    rule = {
        "normalized_name": "gravpack monoist",
        "card_name": "Gravpack Monoist",
        "logical_rule_key": "battle_rule_v1:gravpack-monoist",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_dies_create_tokens_v1",
            "dies_trigger_effect": "token_maker",
            "dies_token_count": 1,
            "dies_token_name": "Robot Token",
            "dies_token_power": 2,
            "dies_token_toughness": 2,
            "dies_token_subtype": "Robot",
            "dies_token_colors": [],
            "dies_token_tapped": True,
            "dies_artifact_tokens": True,
            "keywords": ["flying"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_dies_create_tokens"
    assert scenario["expected_token"]["artifact"] is True
    assert scenario["expected_token"]["tapped"] is True
    assert scenario["expected_keywords"] == ["flying"]


def test_creature_etb_create_multi_tokens_execution_scenario() -> None:
    rule = {
        "normalized_name": "trostanis summoner",
        "card_name": "Trostani's Summoner",
        "logical_rule_key": "battle_rule_v1:trostanis-summoner",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_create_tokens_v1",
            "trigger": "enters_battlefield",
            "etb_trigger_effect": "token_maker",
            "token_component_count": 3,
            "token_total_count": 3,
            "_composite_rule_components": [
                {
                    "effect": "token_maker",
                    "token_count": 1,
                    "token_name": "Knight Token",
                    "token_power": 2,
                    "token_toughness": 2,
                    "token_subtype": "Knight",
                    "token_colors": ["W"],
                    "token_keywords": ["vigilance"],
                },
                {
                    "effect": "token_maker",
                    "token_count": 1,
                    "token_name": "Centaur Token",
                    "token_power": 3,
                    "token_toughness": 3,
                    "token_subtype": "Centaur",
                    "token_colors": ["G"],
                },
                {
                    "effect": "token_maker",
                    "token_count": 1,
                    "token_name": "Rhino Token",
                    "token_power": 4,
                    "token_toughness": 4,
                    "token_subtype": "Rhino",
                    "token_colors": ["G"],
                    "token_keywords": ["trample"],
                },
            ],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_etb_create_tokens"
    assert scenario["expected_component_count"] == 3
    assert scenario["expected_total_tokens"] == 3
    assert [token["name"] for token in scenario["expected_tokens"]] == [
        "Knight Token",
        "Centaur Token",
        "Rhino Token",
    ]


def test_creature_dies_create_multi_tokens_execution_scenario() -> None:
    rule = {
        "normalized_name": "wurmcoil engine",
        "card_name": "Wurmcoil Engine",
        "logical_rule_key": "battle_rule_v1:wurmcoil-engine",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_dies_create_tokens_v1",
            "dies_trigger_effect": "token_maker",
            "token_component_count": 2,
            "token_total_count": 2,
            "keywords": ["deathtouch", "lifelink"],
            "_composite_rule_components": [
                {
                    "effect": "token_maker",
                    "token_count": 1,
                    "token_name": "Phyrexian Wurm Token",
                    "token_power": 3,
                    "token_toughness": 3,
                    "token_subtype": "Phyrexian Wurm",
                    "token_colors": [],
                    "token_keywords": ["deathtouch"],
                    "artifact_tokens": True,
                },
                {
                    "effect": "token_maker",
                    "token_count": 1,
                    "token_name": "Phyrexian Wurm Token",
                    "token_power": 3,
                    "token_toughness": 3,
                    "token_subtype": "Phyrexian Wurm",
                    "token_colors": [],
                    "token_keywords": ["lifelink"],
                    "artifact_tokens": True,
                },
            ],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_dies_create_tokens"
    assert scenario["expected_component_count"] == 2
    assert scenario["expected_total_tokens"] == 2
    assert scenario["expected_keywords"] == ["deathtouch", "lifelink"]
    assert [token["keywords"] for token in scenario["expected_tokens"]] == [["deathtouch"], ["lifelink"]]


def test_creature_dies_create_treasure_execution_scenario() -> None:
    rule = {
        "normalized_name": "gleaming barrier",
        "card_name": "Gleaming Barrier",
        "logical_rule_key": "battle_rule_v1:gleaming-barrier",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_dies_create_treasure_v1",
            "dies_trigger_effect": "treasure_maker",
            "dies_or_graveyard_from_battlefield_treasure": True,
            "dies_treasure_count": 1,
            "treasure_count": 1,
            "keywords": ["defender"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario == {
        "name": "Gleaming Barrier dies and creates Treasure",
        "type": "creature_dies_create_treasure",
        "card": {
            "name": "Gleaming Barrier",
            "type_line": "Creature",
            "effect": "creature",
        },
        "expected_treasure_count": 1,
        "expected_keywords": ["defender"],
        "logical_rule_key": "battle_rule_v1:gleaming-barrier",
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


def test_simple_activated_create_token_execution_scenario_includes_discard_cost() -> None:
    rule = {
        "normalized_name": "icatian crier",
        "card_name": "Icatian Crier",
        "logical_rule_key": "battle_rule_v1:icatian-crier",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_create_token_v1",
            "activation_cost_mana": "{1}{W}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["W"],
            "activation_requires_tap": True,
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_requires_discard_card": True,
            "token_count": 2,
            "token_name": "Citizen Token",
            "token_power": 1,
            "token_toughness": 1,
            "token_subtype": "Citizen",
            "token_colors": ["W"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_activated_create_token"
    assert scenario["controller_mana"] == {
        "generic": 1,
        "white": 1,
        "blue": 0,
        "black": 0,
        "red": 0,
        "green": 0,
    }
    assert len(scenario["controller_hand"]) == 2
    assert scenario["expected_discard_count"] == 1
    assert scenario["expected_discard_target"] == "any_card"
    assert scenario["expected_token"]["name"] == "Citizen Token"
    assert scenario["expected_token"]["count"] == 2


def test_controlled_subtype_token_spell_execution_scenario_seeds_support_permanents() -> None:
    rule = {
        "normalized_name": "elven ambush",
        "card_name": "Elven Ambush",
        "logical_rule_key": "battle_rule_v1:elven-ambush",
        "required_effect_fields": {
            "effect": "token_maker",
            "battle_model_scope": "xmage_controlled_subtype_create_creature_tokens_spell_v1",
            "token_count_source": "controlled_permanents_with_subtype",
            "token_count_subtype": "Elf",
            "token_name": "Elf Warrior Token",
            "token_power": 1,
            "token_toughness": 1,
            "token_subtype": "Elf Warrior",
            "token_colors": ["G"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "fixed_create_creature_tokens"
    assert scenario["controlled_permanent_subtype"] == "Elf"
    assert scenario["controlled_permanent_subtype_count"] == 3
    assert scenario["expected_token"]["count"] == 3
    assert scenario["expected_token"]["name"] == "Elf Warrior Token"


def test_dynamic_count_token_spell_execution_scenarios_seed_support_state() -> None:
    fixtures = [
        (
            "Deploy to the Front",
            {"token_count_source": "all_creatures_on_battlefield"},
            {"expected_count": 4, "controlled_battlefield_creature_count": 2, "opponent_battlefield_creature_count": 2},
        ),
        (
            "Flurry of Wings",
            {"token_count_source": "attacking_creatures"},
            {"expected_count": 3, "attacking_creature_count": 3},
        ),
        (
            "Crash the Party",
            {"token_count_source": "controlled_tapped_creatures", "token_tapped": True},
            {"expected_count": 3, "controlled_tapped_creature_count": 3},
        ),
        (
            "Fungal Sprouting",
            {"token_count_source": "greatest_power_among_controlled_creatures"},
            {"expected_count": 4, "controlled_creature_powers": [1, 4, 2]},
        ),
        (
            "Spontaneous Generation",
            {"token_count_source": "controller_hand_count"},
            {"expected_count": 4, "controller_hand_card_count": 4},
        ),
        (
            "Ordered Migration",
            {"token_count_source": "domain_basic_land_types"},
            {"expected_count": 3, "domain_basic_land_subtypes": ["Plains", "Island", "Mountain"]},
        ),
        (
            "Fixture Graveborn",
            {"token_count_source": "controller_graveyard_creature_count"},
            {"expected_count": 3, "controller_graveyard_creature_count": 3},
        ),
        (
            "Rise from the Tides",
            {"token_count_source": "controller_graveyard_instant_sorcery_count"},
            {"expected_count": 3, "controller_graveyard_instant_sorcery_count": 3},
        ),
        (
            "Goblin Gathering",
            {
                "token_count_source": "named_cards_in_controller_graveyard_plus_base",
                "token_count_card_name": "Goblin Gathering",
                "token_count_base": 2,
            },
            {"expected_count": 4, "controller_graveyard_named_card_count": 2},
        ),
    ]
    for card_name, count_fields, expected in fixtures:
        rule = {
            "normalized_name": card_name.lower(),
            "card_name": card_name,
            "logical_rule_key": f"battle_rule_v1:{card_name.lower().replace(' ', '-')}",
            "required_effect_fields": {
                "effect": "token_maker",
                "battle_model_scope": "xmage_dynamic_count_create_creature_tokens_spell_v1",
                "token_name": "Soldier Token",
                "token_power": 1,
                "token_toughness": 1,
                "token_subtype": "Soldier",
                "token_colors": ["W"],
                **count_fields,
            },
        }

        scenario = builder.execution_scenario_from_expected_rule(rule)

        assert scenario["type"] == "fixed_create_creature_tokens"
        assert scenario["expected_token"]["count"] == expected["expected_count"]
        for key, value in expected.items():
            if key != "expected_count":
                assert scenario[key] == value


def test_expected_rule_preserves_named_graveyard_token_count_fields() -> None:
    proposal = {
        "normalized_name": "goblin gathering",
        "card_name": "Goblin Gathering",
        "oracle_hash": "hash-goblin-gathering",
        "logical_rule_key": "battle_rule_v1:goblin-gathering",
        "effect_json": {
            "effect": "token_maker",
            "battle_model_scope": "xmage_dynamic_count_create_creature_tokens_spell_v1",
            "token_count_source": "named_cards_in_controller_graveyard_plus_base",
            "token_count_card_name": "Goblin Gathering",
            "token_count_base": 2,
            "token_name": "Goblin Token",
            "token_power": 1,
            "token_toughness": 1,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["token_count_source"] == "named_cards_in_controller_graveyard_plus_base"
    assert required["token_count_card_name"] == "Goblin Gathering"
    assert required["token_count_base"] == 2


def test_graveyard_self_exile_activated_create_token_execution_scenario_marks_source_zone() -> None:
    rule = {
        "normalized_name": "eternal student",
        "card_name": "Eternal Student",
        "logical_rule_key": "battle_rule_v1:eternal-student",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_graveyard_self_exile_activated_create_token_v1",
            "activation_cost_mana": "{1}{B}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["B"],
            "activation_zone": "graveyard",
            "activation_requires_exile_source_from_graveyard": True,
            "token_count": 2,
            "token_name": "Inkling Token",
            "token_power": 1,
            "token_toughness": 1,
            "token_subtype": "Inkling",
            "token_colors": ["W", "B"],
            "token_keywords": ["flying"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_activated_create_token"
    assert scenario["source_zone"] == "graveyard"
    assert scenario["expected_exiled_source_from_graveyard"] is True
    assert scenario["controller_mana"] == {
        "generic": 1,
        "white": 0,
        "blue": 0,
        "black": 1,
        "red": 0,
        "green": 0,
    }
    assert scenario["expected_token"]["name"] == "Inkling Token"
    assert scenario["expected_token"]["keywords"] == ["flying"]


def test_spell_cast_gain_life_execution_scenario_uses_matching_and_nonmatching_spells() -> None:
    rule = {
        "normalized_name": "student of ojutai",
        "card_name": "Student of Ojutai",
        "logical_rule_key": "battle_rule_v1:student-of-ojutai",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_spell_cast_gain_life_v1",
            "trigger": "noncreature_spell_cast",
            "trigger_effect": "gain_life",
            "spell_cast_gain_life": True,
            "spell_cast_gain_life_amount": 2,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "spell_cast_gain_life"
    assert scenario["expected_life_gain"] == 2
    assert scenario["expected_trigger"] == "noncreature_spell_cast"
    assert scenario["matching_spell"]["type_line"] == "Instant"
    assert "Creature" in scenario["nonmatching_spell"]["type_line"]


def test_creature_enters_draw_execution_scenario_uses_matching_entering_creature() -> None:
    rule = {
        "normalized_name": "elemental bond",
        "card_name": "Elemental Bond",
        "logical_rule_key": "battle_rule_v1:elemental-bond",
        "required_effect_fields": {
            "effect": "enchantment",
            "battle_model_scope": "xmage_creature_enters_draw_trigger_v1",
            "trigger": "creature_you_control_enters",
            "trigger_effect": "draw_cards",
            "trigger_controller_scope": "self",
            "trigger_draw_count": 1,
            "trigger_entering_card_types": ["creature"],
            "trigger_entering_power_min": 3,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_enters_draw"
    assert scenario["expected_draw_count"] == 1
    assert scenario["expected_trigger"] == "creature_you_control_enters"
    assert scenario["entering_controller"] == "controller"
    assert scenario["entering_creature"]["power"] == 3


def test_each_player_sacrifice_fields_and_execution_scenario() -> None:
    proposal = {
        "normalized_name": "renounce the guilds",
        "card_name": "Renounce the Guilds",
        "oracle_hash": "hash-renounce-the-guilds",
        "logical_rule_key": "battle_rule_v1:hash-renounce-the-guilds",
        "effect_json": {
            "effect": "each_player_sacrifice",
            "battle_model_scope": "xmage_each_player_sacrifice_fixed_permanents_spell_v1",
            "sacrifice_count": 1,
            "sacrifice_card_types": ["permanent"],
            "sacrifice_scope": "each_player",
            "sacrifice_choice": "controller_choice_lowest_value",
            "sacrifice_requires_multicolored": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["sacrifice_count"] == 1
    assert required["sacrifice_card_types"] == ["permanent"]
    assert required["sacrifice_scope"] == "each_player"
    assert required["sacrifice_choice"] == "controller_choice_lowest_value"
    assert required["sacrifice_requires_multicolored"] is True

    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "each_player_sacrifice"
    assert scenario["sacrifice_count"] == 1
    assert scenario["sacrifice_card_types"] == ["permanent"]
    assert scenario["sacrifice_requires_multicolored"] is True
    assert scenario["expected_sacrificed_per_player"] == 1


def test_simple_activated_regenerate_source_execution_scenario_uses_activation_mana() -> None:
    rule = {
        "normalized_name": "cudgel troll",
        "card_name": "Cudgel Troll",
        "logical_rule_key": "battle_rule_v1:cudgel-troll",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_regenerate_source_v1",
            "activated_effect": "regenerate_source",
            "activation_cost_mana": "{G}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["G"],
            "activation_requires_tap": False,
            "regenerate_source": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_activated_regenerate_source"
    assert scenario["controller_mana"] == {
        "generic": 0,
        "white": 0,
        "blue": 0,
        "black": 0,
        "red": 0,
        "green": 1,
    }
    assert scenario["expected_regeneration_shields"] == 1
