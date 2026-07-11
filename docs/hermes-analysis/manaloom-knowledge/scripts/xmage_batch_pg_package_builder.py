#!/usr/bin/env python3
"""Build review-only PostgreSQL package files from XMage batch proposals.

The generated SQL is not executed by this script. It is an approval-gated
package candidate for precheck/apply/postcheck/rollback review.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import battle_rule_registry


DEFAULT_REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"
E2E_REQUIRED_EFFECT_FIELDS = (
    "effect",
    "battle_model_scope",
    "instant",
    "sorcery",
    "cant_be_countered",
    "target",
    "target_controller",
    "target_graveyard_controller",
    "battlefield_controller",
    "library_controller",
    "target_constraints",
    "target_preference",
    "enchant_target",
    "enchant_target_controller",
    "static_effect",
    "static_applies_to",
    "static_power_bonus",
    "static_toughness_bonus",
    "static_controller_scope",
    "static_exclude_source",
    "static_granted_keywords",
    "static_required_subtypes",
    "static_required_colors",
    "static_required_supertypes",
    "static_required_combat_state",
    "static_required_tapped_state",
    "static_artifact_creature",
    "cost_increase_applies_to",
    "cost_increase_amount_source",
    "cost_increase_generic",
    "cost_increase_color_symbols",
    "cost_increase_filters",
    "cost_reduction_applies_to",
    "cost_reduction_amount_source",
    "cost_reduction_generic",
    "cost_reduction_color_symbols",
    "cost_reduction_filters",
    "applies_to_spell_colors",
    "applies_to_card_types",
    "applies_to_subtypes",
    "creature_filter",
    "permanent_type",
    "counter_unless_pays_generic",
    "counter_unless_pays_amount_source",
    "counter_unless_pays_base",
    "counter_unless_pays_per",
    "counter_unless_pays_subtype",
    "counter_unless_pays_battlefield_scope",
    "counter_unless_pays_default",
    "countered_spell_to_top_library",
    "countered_spell_to_exile",
    "countered_spell_to_exile_reason",
    "counter_target_mana_value_source",
    "xmage_target_adjuster",
    "draw_on_counter",
    "scry_on_counter",
    "life_gain_on_counter",
    "life_loss_on_counter",
    "target_controller_life_loss_on_counter",
    "target_controller_damage_on_resolve",
    "source_controller_life_loss_on_resolve",
    "source_controller_damage_on_resolve",
    "power_delta",
    "toughness_delta",
    "power_boost",
    "toughness_boost",
    "attached_keywords",
    "grants_flying",
    "grants_reach",
    "grants_trample",
    "grants_deathtouch",
    "grants_first_strike",
    "grants_double_strike",
    "grants_lifelink",
    "grants_indestructible",
    "grants_haste",
    "grants_vigilance",
    "grants_hexproof",
    "grants_shroud",
    "grants_menace",
    "grants_unblockable",
    "attached_creature_cant_be_blocked",
    "untap_target",
    "blocker_count_mode",
    "duration",
    "control_duration",
    "granted_keywords_until_eot",
    "additional_cost",
    "requires_one_additional_cost_option",
    "additional_cost_options",
    "requires_discard_card",
    "requires_discard_land",
    "requires_pay_life",
    "pay_life_amount",
    "requires_sacrifice_creature",
    "requires_sacrifice_creature_count",
    "requires_sacrifice_creature_or_land",
    "requires_sacrifice_creature_or_enchantment",
    "requires_sacrifice_creature_or_planeswalker",
    "requires_sacrifice_artifact_or_creature",
    "requires_sacrifice_artifact",
    "requires_sacrifice_goblin",
    "requires_sacrifice_land",
    "requires_return_land_to_hand",
    "xmage_additional_cost_class",
    "xmage_additional_cost_target",
    "count",
    "draw_count",
    "proliferate_count",
    "discard_count",
    "discard_random",
    "discard_unless_status",
    "discard_unless_filter",
    "discard_unless_count",
    "discard_unless_basic_land",
    "discard_unless_card_types",
    "draw_discard_order",
    "put_land_from_hand",
    "put_land_tapped",
    "count_from_x",
    "target_count_from_x",
    "target_count_source",
    "target_player_draw",
    "prevent_all_combat_damage_this_turn",
    "prevent_damage_from_creature_sources_this_turn",
    "prevent_damage_scope",
    "prevent_damage_kind",
    "prevent_damage_duration",
    "prevent_damage_amount",
    "prevent_source_constraints",
    "target_count",
    "target_count_min",
    "target_count_max",
    "max_targets",
    "up_to_count",
    "damage_per_target",
    "damage_assignment_mode",
    "divided_damage",
    "destination",
    "resolution_order",
    "rest_destination",
    "library_bottom_order",
    "look_count",
    "pick_count",
    "pick_target",
    "pick_up_to_count",
    "pick_all_matching",
    "reveal",
    "enters_tapped",
    "exiles_self",
    "shuffle_self_into_library_on_resolution",
    "mode_selection",
    "mode_selection_model",
    "mode_min",
    "mode_max",
    "modal_modes",
    "damage_amount",
    "damage_target",
    "destroy_target",
    "_composite_rule_components",
    "recursion_components",
    "recursion_mana_value_max",
    "recursion_mana_value_max_from_x",
    "target_mana_value_max_from_x",
    "pre_recursion_mill_count",
    "etb_draw_count",
    "etb_draw_condition_status",
    "etb_draw_condition",
    "etb_draw_condition_min_count",
    "etb_draw_condition_card_types",
    "etb_draw_condition_subtypes",
    "etb_draw_condition_colors",
    "etb_draw_condition_exclude_source",
    "etb_draw_optional",
    "etb_optional_discard_draw",
    "etb_optional_discard_count",
    "etb_optional_discard_draw_count",
    "etb_draw_discard",
    "etb_discard_count",
    "etb_target_stat_modifier",
    "etb_dynamic_draw",
    "draw_count_source",
    "etb_draw_count_source",
    "draw_count_subtype",
    "etb_draw_count_subtype",
    "draw_count_color",
    "etb_draw_count_color",
    "draw_count_exclude_source",
    "etb_draw_count_exclude_source",
    "etb_life_loss",
    "life_loss_amount",
    "damage_amount",
    "etb_life_gain_amount",
    "etb_dynamic_life_gain",
    "etb_scry_count",
    "trigger_scry_count",
    "scry_count",
    "surveil_count",
    "etb_damage_amount",
    "etb_damage_target",
    "etb_remove_effect",
    "etb_remove_target",
    "etb_treasure_count",
    "etb_treasure_condition",
    "etb_token_count",
    "etb_token_count_source",
    "etb_token_count_per_x",
    "etb_token_count_subtype",
    "etb_token_count_card_name",
    "etb_token_count_base",
    "token_count",
    "token_count_source",
    "token_count_per_x",
    "token_count_subtype",
    "token_count_card_name",
    "token_count_base",
    "token_component_count",
    "token_total_count",
    "xmage_token_class",
    "xmage_token_classes",
    "token_name",
    "token_power",
    "token_toughness",
    "token_subtype",
    "token_colors",
    "token_keywords",
    "token_flying",
    "token_haste",
    "token_tapped",
    "token_cant_block",
    "token_static_restrictions",
    "token_landwalk",
    "token_landwalk_land_type",
    "token_landwalk_land_types",
    "token_sacrifice_for_colorless_mana",
    "token_mana_activation_requires_sacrifice",
    "token_mana_activation_requires_tap",
    "token_mana_produced",
    "treasure_count",
    "controller_treasure_tokens",
    "treasure_recipient",
    "treasure_trigger",
    "dies_or_graveyard_from_battlefield_treasure",
    "dies_treasure_count",
    "token_produces",
    "token_produced_mana_symbols",
    "artifact_tokens",
    "token_artifact_only",
    "token_activated_ability",
    "token_activated_ability_status",
    "token_activated_battle_model_scope",
    "token_activated_life_gain_amount",
    "token_activation_cost_mana",
    "token_activation_cost_generic",
    "token_activation_requires_tap",
    "token_activation_requires_sacrifice",
    "token_activated_draw_on_self_sacrifice",
    "token_activated_self_sacrifice_draw",
    "token_draw_on_self_sacrifice",
    "token_draw_count",
    "token_is_mana_source",
    "token_mana_source_contextual_only",
    "token_mana_spend_restriction",
    "etb_token_name",
    "etb_token_power",
    "etb_token_toughness",
    "etb_token_subtype",
    "etb_token_colors",
    "etb_token_keywords",
    "etb_token_flying",
    "etb_token_haste",
    "etb_token_tapped",
    "etb_token_cant_block",
    "etb_token_static_restrictions",
    "etb_token_landwalk",
    "etb_token_landwalk_land_type",
    "etb_token_landwalk_land_types",
    "etb_token_sacrifice_for_colorless_mana",
    "etb_token_mana_activation_requires_sacrifice",
    "etb_token_mana_activation_requires_tap",
    "etb_token_mana_produced",
    "etb_token_produces",
    "etb_token_produced_mana_symbols",
    "etb_artifact_tokens",
    "etb_token_artifact_only",
    "etb_token_activated_ability",
    "etb_token_activated_ability_status",
    "etb_token_activated_battle_model_scope",
    "etb_token_activated_life_gain_amount",
    "etb_token_activation_cost_mana",
    "etb_token_activation_cost_generic",
    "etb_token_activation_requires_tap",
    "etb_token_activation_requires_sacrifice",
    "etb_token_activated_draw_on_self_sacrifice",
    "etb_token_activated_self_sacrifice_draw",
    "etb_token_draw_on_self_sacrifice",
    "etb_token_draw_count",
    "etb_token_is_mana_source",
    "etb_token_mana_source_contextual_only",
    "etb_token_mana_spend_restriction",
    "dies_token_count",
    "dies_token_count_source",
    "dies_token_count_per_x",
    "dies_token_count_subtype",
    "dies_token_count_card_name",
    "dies_token_count_base",
    "dies_token_name",
    "dies_token_power",
    "dies_token_toughness",
    "dies_token_subtype",
    "dies_token_colors",
    "dies_token_keywords",
    "dies_token_flying",
    "dies_token_haste",
    "dies_token_tapped",
    "dies_token_cant_block",
    "dies_token_static_restrictions",
    "dies_token_landwalk",
    "dies_token_landwalk_land_type",
    "dies_token_landwalk_land_types",
    "dies_token_sacrifice_for_colorless_mana",
    "dies_token_mana_activation_requires_sacrifice",
    "dies_token_mana_activation_requires_tap",
    "dies_token_mana_produced",
    "dies_token_produces",
    "dies_token_produced_mana_symbols",
    "dies_artifact_tokens",
    "dies_token_artifact_only",
    "dies_token_activated_ability",
    "dies_token_activated_ability_status",
    "dies_token_activated_battle_model_scope",
    "dies_token_activated_life_gain_amount",
    "dies_token_activation_cost_mana",
    "dies_token_activation_cost_generic",
    "dies_token_activation_requires_tap",
    "dies_token_activation_requires_sacrifice",
    "dies_token_activated_draw_on_self_sacrifice",
    "dies_token_activated_self_sacrifice_draw",
    "dies_token_draw_on_self_sacrifice",
    "dies_token_draw_count",
    "dies_token_is_mana_source",
    "dies_token_mana_source_contextual_only",
    "dies_token_mana_spend_restriction",
    "etb_add_counters_target",
    "etb_add_counters_count",
    "etb_add_counters_counter_type",
    "etb_recursion_target",
    "etb_recursion_count",
    "etb_recursion_destination",
    "etb_recursion_up_to_count",
    "etb_recursion_mana_value_max",
    "etb_recursion_mill_count",
    "etb_library_look_count",
    "etb_library_pick_count",
    "etb_library_pick_target",
    "etb_library_rest_destination",
    "etb_library_pick_all_matching",
    "etb_library_pick_up_to_count",
    "etb_library_bottom_order",
    "etb_tutor_target",
    "etb_tutor_count",
    "tutor_target",
    "tutor_count",
    "tutor_destination",
    "tutor_enters_tapped",
    "dies_recursion_target",
    "dies_recursion_count",
    "dies_recursion_destination",
    "dies_recursion_exclude_self",
    "dies_damage_amount",
    "dies_damage_target",
    "dies_damage_optional",
    "etb_mana_produced",
    "etb_produces",
    "etb_produced_mana_symbols",
    "etb_mana_condition",
    "dies_mana_produced",
    "dies_produces",
    "dies_produced_mana_symbols",
    "dies_add_counters",
    "dies_add_counters_target",
    "dies_add_counters_counter_type",
    "dies_add_counters_count",
    "dies_add_counters_optional",
    "combat_damage_player_draw",
    "combat_damage_draw_count",
    "combat_damage_draw_optional",
    "combat_damage_draw_optional_cost",
    "combat_damage_draw_optional_cost_count",
    "graveyard_exile_target",
    "graveyard_exile_target_count",
    "graveyard_exile_destination",
    "graveyard_exile_up_to_count",
    "graveyard_exile_single_graveyard",
    "graveyard_to_library_target",
    "graveyard_to_library_target_count",
    "graveyard_to_library_destination",
    "graveyard_to_library_up_to_count",
    "graveyard_to_library_activation_cost_mana",
    "graveyard_to_library_activation_cost_generic",
    "graveyard_to_library_activation_cost_colors",
    "graveyard_self_return_to_hand",
    "graveyard_self_return_to_battlefield",
    "graveyard_self_return_destination",
    "graveyard_self_return_activation_cost_mana",
    "graveyard_self_return_activation_cost_generic",
    "graveyard_self_return_activation_cost_colors",
    "amount",
    "damage",
    "gain_life",
    "controller_gain_life",
    "damage_amount_source",
    "damage_base_amount",
    "damage_per_graveyard_count",
    "damage_players",
    "exile_if_dies_from_damage",
    "exile_if_dies_target",
    "damage_scope",
    "damage_exclude_tokens",
    "damage_required_colors",
    "damage_excluded_subtypes",
    "destroy_card_types",
    "destroy_controller",
    "destroy_required_colors",
    "destroy_excluded_colors",
    "destroy_required_subtypes",
    "destroy_excluded_subtypes",
    "destroy_exclude_card_types",
    "destroy_tapped_state",
    "destroy_nonbasic_lands",
    "destroy_mana_value_lte",
    "destroy_mana_value_lte_source",
    "destroy_mana_value_gte",
    "destroy_power_lte",
    "destroy_power_gte",
    "destroy_toughness_lte",
    "destroy_toughness_gte",
    "destroy_counter_state",
    "destroy_combat_state",
    "destroy_color_count_lt",
    "destroy_dealt_damage_to_you_this_turn",
    "destroy_exclude_commanders",
    "destroy_enchanted_state",
    "return_card_types",
    "return_controller",
    "return_required_colors",
    "return_excluded_colors",
    "return_required_subtypes",
    "return_excluded_subtypes",
    "return_exclude_card_types",
    "return_combat_state",
    "sacrifice_count",
    "sacrifice_card_types",
    "sacrifice_scope",
    "sacrifice_choice",
    "sacrifice_requires_multicolored",
    "etb_each_player_sacrifice",
    "dies_each_player_sacrifice",
    "controller_gains_life",
    "life_gain",
    "life_gain_amount",
    "life_gain_amount_source",
    "life_gain_base_amount",
    "life_gain_per_count",
    "graveyard_count_scope",
    "graveyard_count_card_types",
    "battlefield_count_scope",
    "battlefield_count_card_types",
    "battlefield_count_subtypes",
    "battlefield_count_required_colors",
    "battlefield_count_excluded_card_types",
    "battlefield_count_excluded_subtypes",
    "battlefield_count_card_names",
    "battlefield_count_keywords",
    "battlefield_count_combat_state",
    "battlefield_count_tapped_state",
    "battlefield_count_exclude_source",
    "mana_symbol_count_color",
    "counter_type",
    "counter_count",
    "counter_amount",
    "additional_counter",
    "counter_grants_keywords",
    "keywords",
    "_keywords_are_self",
    "flash",
    "is_mana_source",
    "mana_source_contextual_only",
    "mana_produced",
    "produces",
    "produced_mana_symbols",
    "conditional_mana_modes",
    "conditional_mana_modes_status",
    "conditionally_produces_controller_land_colors",
    "conditionally_produces_opponent_land_colors",
    "land_mana_dependency_controller",
    "land_mana_dependency_allows_colorless",
    "dynamic_mana_amount_source",
    "dynamic_mana_battlefield_count_scope",
    "dynamic_mana_battlefield_count_card_types",
    "dynamic_mana_battlefield_count_subtypes",
    "conditional_mana_controlled_creature_power_gte",
    "conditional_mana_controlled_creature_count_gte",
    "conditional_mana_produced_when_condition_met",
    "conditional_mana_same_color_choice",
    "source_type_line",
    "source_mana_cost",
    "life_for_colored_mana",
    "mana_activation_life_gain",
    "mana_activation_requires_tap",
    "mana_source_requires_untapped_creature",
    "mana_source_requires_untapped_artifact_or_creature",
    "mana_activation_tap_support_count",
    "mana_activation_tap_support_type",
    "mana_source_support_can_include_source",
    "mana_activation_requires_sacrifice_target",
    "sacrifice_mana_source_contextual_only",
    "sacrifice_mana_produced",
    "sacrifice_produces",
    "sacrifice_produced_mana_symbols",
    "sacrifice_mana_activation_requires_tap",
    "sacrifice_activation_requires_tap",
    "sacrifice_mana_activation_requires_sacrifice",
    "sacrifice_activation_requires_sacrifice",
    "sacrifice_activation_mana_cost",
    "activation_mana_cost",
    "cost_reduction_applies_to",
    "cost_reduction_amount_source",
    "cost_reduction_generic",
    "cost_reduction_color_symbols",
    "cost_reduction_condition",
    "cost_reduction_required_subtype",
    "cost_reduction_required_keyword",
    "cost_reduction_opponent_graveyard_cards_min",
    "cost_reduction_opponent_poison_counters_min",
    "cost_reduction_graveyard_card_types_min",
    "trigger",
    "trigger_effect",
    "trigger_controller_scope",
    "trigger_gain_life",
    "trigger_draw_count",
    "trigger_another_creature_enters",
    "trigger_entering_card_types",
    "trigger_entering_power_min",
    "trigger_entering_subtypes",
    "trigger_optional",
    "trigger_limit_each_turn",
    "end_step_draw_count",
    "end_step_draw_optional",
    "end_step_draw_condition_status",
    "end_step_draw_condition",
    "end_step_draw_condition_threshold",
    "optional",
    "ability_kind",
    "activated_effect",
    "activated_battle_model_scope",
    "activated_remove_effect",
    "activated_remove_target",
    "activated_tap_target",
    "activated_untap_target",
    "activated_add_counters",
    "activated_add_counters_target",
    "activated_add_counters_counter_type",
    "activated_add_counters_count",
    "activated_damage_amount",
    "activated_draw",
    "activated_draw_discard",
    "activated_draw_count",
    "activated_discard_count",
    "activated_self_sacrifice_tutor_to_hand",
    "activated_self_sacrifice_draw",
    "activated_self_sacrifice_draw_discard",
    "activated_self_sacrifice_destroy",
    "regenerate_source",
    "activation_cost_mana",
    "activation_cost_generic",
    "activation_cost_colors",
    "activation_requires_tap",
    "activation_requires_sacrifice",
    "activation_limit_per_turn",
    "activation_life_cost",
    "activation_exile_top_library_count",
    "activation_remove_counter_cost",
    "activation_discard_count",
    "activation_discard_target",
    "activation_requires_discard_card",
    "activation_discard_random",
    "activation_zone",
    "activation_requires_exile_source_from_graveyard",
    "activation_sacrifice_cost",
    "activation_sacrifice_target",
    "activation_requires_sacrifice_target",
    "activation_tap_cost",
    "activation_requires_tap_target",
    "permanent_type",
    "spell_cast_draw_count",
    "spell_cast_draw_card_types",
    "spell_cast_draw_required_subtypes",
    "spell_cast_draw_required_supertypes",
    "spell_cast_draw_requires_historic",
    "spell_cast_draw_source_zone",
    "spell_cast_draw_mana_value_min",
    "spell_cast_draw_optional",
    "spell_cast_add_counters",
    "spell_cast_add_counters_target",
    "spell_cast_add_counters_count",
    "spell_cast_add_counters_counter_type",
    "spell_cast_add_counters_card_types",
    "spell_cast_add_counters_required_subtypes",
    "spell_cast_add_counters_required_supertypes",
    "spell_cast_add_counters_required_colors",
    "spell_cast_add_counters_requires_multicolored",
    "spell_cast_add_counters_requires_historic",
    "spell_cast_add_counters_source_zone",
    "spell_cast_add_counters_mana_value_min",
    "spell_cast_gain_life",
    "spell_cast_gain_life_amount",
    "spell_cast_gain_life_card_types",
    "spell_cast_gain_life_required_colors",
    "spell_cast_gain_life_source_zone",
    "spell_cast_gain_life_optional",
    "spell_cast_gain_life_any_player",
    "land_enter_gain_life",
    "land_enter_gain_life_amount",
    "land_enter_gain_life_subtypes",
    "spell_cast_token_maker",
    "spell_cast_token_card_types",
    "spell_cast_token_required_subtypes",
    "spell_cast_token_required_supertypes",
    "spell_cast_token_required_colors",
    "spell_cast_token_requires_multicolored",
    "spell_cast_token_requires_historic",
    "spell_cast_token_source_zone",
    "spell_cast_token_mana_value_min",
    "spell_cast_token_optional",
    "trigger_artifact_spell",
    "flashback_cost",
    "flashback_status",
    "cycling_cost",
    "cycling_status",
    "modeled_ability_subset",
    "_runtime_partial",
    "_runtime_partial_reason",
    "xmage_auxiliary_ability_classes",
    "xmage_mana_ability_classes",
    "xmage_unmodeled_auxiliary_ability_classes",
    "xmage_unmodeled_effect_classes",
    "xmage_effect_classes",
    "static_effect",
    "protection_from",
    "protection_from_colors",
    "protection_from_card_types",
    "protection_from_subtypes",
    "protection_filter",
    "protection_from_color_profile",
    "protection_from_mana_value_min",
    "cast_spells_as_flash",
    "cast_nonland_spells_as_flash",
    "flash_permission_filter",
    "flash_permission_controller",
    "flash_permission_any_player",
    "cant_be_blocked",
    "cannot_be_blocked",
    "unblockable",
    "cant_block",
    "cannot_block",
    "static_cant_block",
    "landwalk",
    "landwalk_keyword",
    "landwalk_land_type",
    "landwalk_land_types",
    "cant_be_blocked_by_filters",
    "can_be_blocked_only_by_filters",
    "can_block_only_flying",
    "horsemanship",
    "block_restriction",
    "static_power_toughness_source",
    "graveyard_count_scope",
    "graveyard_count_card_types",
    "graveyard_count_mode",
    "graveyard_count_card_names",
    "graveyard_count_subtypes",
    "graveyard_count_threshold",
    "static_power_bonus",
    "static_toughness_bonus",
    "stat_modifier_amount_source",
    "static_power_toughness_base",
    "static_power_toughness_count_multiplier",
    "static_power_bonus_per_graveyard_count",
    "static_toughness_bonus_per_graveyard_count",
    "dynamic_power_equals_count",
    "dynamic_toughness_equals_count",
    "dynamic_power_equals_graveyard_count",
    "dynamic_toughness_equals_graveyard_count",
    "_activated_rule_effects",
    "xmage_ability_class",
    "xmage_ability_classes",
    "xmage_effect_class",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def sql_literal(value: Any) -> str:
    return "'" + str(value).replace("'", "''") + "'"


def sql_json(value: Any) -> str:
    return sql_literal(json.dumps(value, sort_keys=True, separators=(",", ":"))) + "::jsonb"


def safe_ident(value: str, *, max_length: int = 56) -> str:
    ident = re.sub(r"[^a-z0-9_]+", "_", value.lower()).strip("_")
    if not ident:
        ident = "xmage_batch"
    if ident[0].isdigit():
        ident = "d_" + ident
    if len(ident) <= max_length:
        return ident
    suffix_len = min(15, max(8, max_length // 3))
    prefix_len = max_length - suffix_len - 1
    prefix = ident[:prefix_len].rstrip("_") or "xmage"
    suffix = ident[-suffix_len:].lstrip("_") or ident[-suffix_len:]
    return f"{prefix}_{suffix}"[:max_length]


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def select_proposals(
    proposals: list[dict[str, Any]],
    *,
    include_family: set[str],
    include_card: set[str],
    exclude_card: set[str],
    max_cards: int | None,
) -> list[dict[str, Any]]:
    selected = [proposal for proposal in proposals if proposal.get("safe_for_batch_pg_package")]
    if include_family:
        selected = [proposal for proposal in selected if proposal.get("family_id") in include_family]
    if include_card:
        selected = [proposal for proposal in selected if proposal.get("card_name") in include_card]
    if exclude_card:
        selected = [proposal for proposal in selected if proposal.get("card_name") not in exclude_card]
    if max_cards and max_cards > 0:
        selected = selected[:max_cards]
    return selected


def package_deck_role(proposal: dict[str, Any]) -> dict[str, Any]:
    deck_role = proposal.get("deck_role_json")
    if not isinstance(deck_role, dict):
        deck_role = {}
    effect_json = proposal.get("effect_json")
    if not isinstance(effect_json, dict):
        return deck_role
    effect = str(effect_json.get("effect") or "")
    placeholder_role = (
        str(deck_role.get("effect") or "") == "external_reference_required_manual_model"
        or str(deck_role.get("category") or "") == "manual_review"
        or str(deck_role.get("category") or "") == "unknown"
    )
    if effect and effect != "external_reference_required_manual_model" and placeholder_role:
        return battle_rule_registry.deck_role_from_effect(effect_json)
    return deck_role


def values_rows(proposals: list[dict[str, Any]]) -> str:
    rows = []
    for proposal in proposals:
        rows.append(
            "("
            + ", ".join(
                [
                    sql_literal(proposal["normalized_name"]),
                    sql_literal(proposal["card_name"]),
                    sql_literal(proposal["oracle_hash"]),
                    sql_literal(proposal["logical_rule_key"]),
                    sql_json(proposal["effect_json"]),
                    sql_json(package_deck_role(proposal)),
                    sql_literal(proposal["source"]),
                    str(float(proposal["confidence"])),
                    sql_literal(proposal["review_status"]),
                    sql_literal(proposal["execution_status"]),
                    sql_literal(proposal["notes"]),
                    sql_literal(proposal.get("shadow_handling") or "deprecate_nonmatching_rows"),
                ]
            )
            + ")"
        )
    return ",\n    ".join(rows)


def proposed_cte(proposals: list[dict[str, Any]]) -> str:
    return (
        "proposed(normalized_name, card_name, oracle_hash, logical_rule_key, "
        "effect_json, deck_role_json, source, confidence, review_status, "
        "execution_status, notes, shadow_handling) AS (\n  VALUES\n    "
        + values_rows(proposals)
        + "\n)"
    )


def alias_where_clause(column: str, proposals: list[dict[str, Any]]) -> str:
    names = [str(proposal["normalized_name"]) for proposal in proposals]
    exact = f"{column} IN ({', '.join(sql_literal(name) for name in names)})"
    alias_parts = [f"{column} LIKE {sql_literal(name + ' // %')}" for name in names]
    if not alias_parts:
        return exact
    return exact + "\n   OR " + "\n   OR ".join(alias_parts)


def build_precheck_sql(proposals: list[dict[str, Any]]) -> str:
    return f"""WITH {proposed_cte(proposals)},
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
"""


def build_apply_sql(proposals: list[dict[str, Any]], backup_table: str) -> str:
    backup_where = alias_where_clause("normalized_name", proposals)
    return f"""BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.{backup_table} AS
SELECT *
FROM public.card_battle_rules
WHERE {backup_where};

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH {proposed_cte(proposals)},
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH {proposed_cte(proposals)},
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH {proposed_cte(proposals)},
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes,
    p.shadow_handling
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
"""


def build_rollback_sql(proposals: list[dict[str, Any]], backup_table: str) -> str:
    delete_where = alias_where_clause("normalized_name", proposals)
    return f"""BEGIN;

DELETE FROM public.card_battle_rules
WHERE {delete_where};

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.{backup_table};

COMMIT;
"""


def build_postcheck_sql(proposals: list[dict[str, Any]], backup_table: str) -> str:
    return f"""WITH {proposed_cte(proposals)},
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.{backup_table}) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
"""


def expected_rule_from_proposal(proposal: dict[str, Any]) -> dict[str, Any]:
    effect_json = proposal.get("effect_json") if isinstance(proposal.get("effect_json"), dict) else {}
    required_effect_fields = {}
    for field in E2E_REQUIRED_EFFECT_FIELDS:
        if effect_json.get(field) is not None:
            required_effect_fields[field] = effect_json[field]
    return {
        "normalized_name": proposal["normalized_name"],
        "card_name": proposal["card_name"],
        "logical_rule_key": proposal["logical_rule_key"],
        "oracle_hash": proposal["oracle_hash"],
        "review_status": proposal.get("review_status") or "verified",
        "execution_status": proposal.get("execution_status") or "auto",
        "min_rule_version": 2,
        "required_effect_fields": required_effect_fields,
        "forbid_annotation_only": True,
    }


def snapshot_check_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any]:
    required = dict(rule.get("required_effect_fields") or {})
    snapshot_required = {}
    if required.get("battle_model_scope") is not None:
        snapshot_required["battle_model_scope"] = required["battle_model_scope"]
    return {
        "card_name": rule["card_name"],
        "normalized_name": rule["normalized_name"],
        "logical_rule_key": rule["logical_rule_key"],
        "oracle_hash": rule["oracle_hash"],
        "review_status": rule.get("review_status") or "verified",
        "execution_status": rule.get("execution_status") or "auto",
        "min_rule_version": rule.get("min_rule_version") or 2,
        "required_effect_fields": snapshot_required,
        "forbid_annotation_only": True,
    }


def runtime_check_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any]:
    required = dict(rule.get("required_effect_fields") or {})
    check = {
        "card": {"name": rule["card_name"]},
        "card_name": rule["card_name"],
        "normalized_name": rule["normalized_name"],
        "logical_rule_key": rule["logical_rule_key"],
        "required_effect_fields": required,
        "forbid_annotation_only": True,
    }
    if required.get("effect") is not None:
        check["effect"] = required["effect"]
    return check


def static_filtered_protection_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_static_self_protection_from_filtered_creature_v1":
        return None
    matching_source = {
        "name": "E2E Matching Protection Source",
        "type_line": "Instant",
        "effect": "direct_damage",
        "cmc": 2,
        "colors": ["R"],
        "mana_cost": "{R}",
    }
    nonmatching_source = {
        "name": "E2E Nonmatching Protection Source",
        "type_line": "Instant",
        "effect": "direct_damage",
        "cmc": 1,
        "colors": [],
        "mana_cost": "{1}",
    }
    color_profile = str(required.get("protection_from_color_profile") or "").strip().lower()
    if color_profile == "multicolored":
        matching_source.update({"colors": ["R", "G"], "mana_cost": "{R}{G}", "cmc": 2})
        nonmatching_source.update({"colors": ["R"], "mana_cost": "{R}", "cmc": 1})
    elif color_profile == "monocolored":
        matching_source.update({"colors": ["R"], "mana_cost": "{R}", "cmc": 1})
        nonmatching_source.update({"colors": ["R", "G"], "mana_cost": "{R}{G}", "cmc": 2})
    elif required.get("protection_from_mana_value_min") not in (None, ""):
        minimum = int(required["protection_from_mana_value_min"])
        matching_source.update({"colors": ["B"], "mana_cost": f"{{{minimum}}}", "cmc": minimum})
        nonmatching_source.update({"colors": ["B"], "mana_cost": f"{{{max(0, minimum - 1)}}}", "cmc": max(0, minimum - 1)})
    else:
        return None
    return {
        "name": f"{rule['card_name']} static filtered protection blocks matching source",
        "type": "static_filtered_protection",
        "card": {"name": rule["card_name"]},
        "matching_source": matching_source,
        "nonmatching_source": nonmatching_source,
        "logical_rule_key": rule["logical_rule_key"],
    }


def static_subtype_protection_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_static_self_protection_from_subtypes_creature_v1":
        return None
    subtypes = [str(value).strip().lower() for value in required.get("protection_from_subtypes") or [] if value]
    if not subtypes:
        return None
    subtype = subtypes[0]
    nonmatching_subtype = "elf" if subtype != "elf" else "goblin"
    return {
        "name": f"{rule['card_name']} static subtype protection blocks matching source",
        "type": "static_subtype_protection",
        "card": {"name": rule["card_name"]},
        "matching_source": {
            "name": "E2E Matching Protection Source",
            "type_line": f"Creature - {subtype.title()}",
            "effect": "creature",
            "cmc": 2,
            "colors": ["R"],
            "mana_cost": "{1}{R}",
        },
        "nonmatching_source": {
            "name": "E2E Nonmatching Protection Source",
            "type_line": f"Creature - {nonmatching_subtype.title()}",
            "effect": "creature",
            "cmc": 2,
            "colors": ["G"],
            "mana_cost": "{1}{G}",
        },
        "logical_rule_key": rule["logical_rule_key"],
    }


def static_global_pt_execution_scenario_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("effect") != "static_global_power_toughness_boost":
        return None
    creature_filter = required.get("creature_filter") or {}
    if not isinstance(creature_filter, dict):
        creature_filter = {}
    subtypes = [
        str(value).strip()
        for value in creature_filter.get("subtypes", []) or []
        if str(value).strip()
    ]
    card_types = [
        str(value).strip().lower()
        for value in creature_filter.get("card_types", []) or []
        if str(value).strip()
    ]
    colors = [
        str(value).strip().upper()
        for value in creature_filter.get("colors", []) or []
        if str(value).strip()
    ]
    subtype = subtypes[0] if subtypes else "Soldier"
    type_prefix = "Land Creature" if "land" in card_types else "Creature"
    target = {
        "name": f"E2E Target for {rule['card_name']}",
        "type_line": f"{type_prefix} - {subtype.title()}",
        "base_power": 2,
        "base_toughness": 2,
        "power": 2,
        "toughness": 2,
    }
    if colors:
        target["colors"] = colors
        target["mana_cost"] = "".join(f"{{{color}}}" for color in colors)
    if creature_filter.get("token"):
        target["token"] = True
        target["is_token"] = True
    power_bonus = int(required.get("static_power_bonus") or 0)
    toughness_bonus = int(required.get("static_toughness_bonus") or 0)
    expected_toughness = target["base_toughness"] + toughness_bonus
    return {
        "name": f"{rule['card_name']} static global P/T applies",
        "type": "static_global_power_toughness_boost",
        "card": {"name": rule["card_name"]},
        "target": target,
        "target_owner": "opponent" if required.get("static_controller_scope") == "opponents" else "controller",
        "expected_power": target["base_power"] + power_bonus,
        "expected_toughness": expected_toughness,
        "expected_moved_to_graveyard": expected_toughness <= 0,
        "expected_source": rule["card_name"],
        "logical_rule_key": rule["logical_rule_key"],
    }


def static_controlled_pt_execution_scenario_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("static_effect") != "controlled_power_toughness_boost":
        return None
    subtypes = [
        str(value).strip().lower()
        for value in required.get("static_required_subtypes", []) or []
        if str(value).strip()
    ]
    colors = [
        str(value).strip().upper()
        for value in required.get("static_required_colors", []) or []
        if str(value).strip()
    ]
    supertypes = [
        str(value).strip().title()
        for value in required.get("static_required_supertypes", []) or []
        if str(value).strip()
    ]
    combat_state = str(required.get("static_required_combat_state") or "").strip().lower()
    tapped_state = str(required.get("static_required_tapped_state") or "").strip().lower()
    subtype = subtypes[0] if subtypes else "soldier"
    type_prefix = "Artifact Creature" if required.get("static_artifact_creature") else "Creature"
    if supertypes:
        type_prefix = f"{' '.join(supertypes)} {type_prefix}"
    matching_target = {
        "name": f"E2E Controlled P/T Target for {rule['card_name']}",
        "type_line": f"{type_prefix} - {subtype.title()}",
        "base_power": 2,
        "base_toughness": 2,
        "power": 2,
        "toughness": 2,
    }
    if colors:
        matching_target["colors"] = colors
        matching_target["mana_cost"] = "".join(f"{{{color}}}" for color in colors)
    if combat_state == "attacking":
        matching_target["attacking"] = True
    if tapped_state == "untapped":
        matching_target["tapped"] = False
    nonmatching_target = None
    if subtypes or colors or required.get("static_artifact_creature") or supertypes or combat_state or tapped_state:
        nonmatching_target = {
            "name": f"E2E Nonmatching P/T Target for {rule['card_name']}",
            "type_line": "Creature - Goblin",
            "base_power": 2,
            "base_toughness": 2,
            "power": 2,
            "toughness": 2,
        }
        if colors:
            off_color = "U" if "U" not in colors else "R"
            nonmatching_target["colors"] = [off_color]
            nonmatching_target["mana_cost"] = f"{{{off_color}}}"
        if combat_state == "attacking":
            nonmatching_target["attacking"] = False
        if tapped_state == "untapped":
            nonmatching_target["tapped"] = True
    opponent_target = dict(matching_target)
    opponent_target["name"] = f"E2E Opponent P/T Target for {rule['card_name']}"
    power_bonus = int(required.get("static_power_bonus") or 0)
    toughness_bonus = int(required.get("static_toughness_bonus") or 0)
    return {
        "name": f"{rule['card_name']} static controlled P/T applies",
        "type": "static_controlled_power_toughness_boost",
        "card": {"name": rule["card_name"]},
        "matching_target": matching_target,
        "nonmatching_target": nonmatching_target,
        "opponent_target": opponent_target,
        "expected_power": matching_target["base_power"] + power_bonus,
        "expected_toughness": matching_target["base_toughness"] + toughness_bonus,
        "expected_source": rule["card_name"],
        "logical_rule_key": rule["logical_rule_key"],
    }


def static_controlled_keyword_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("static_effect") != "controlled_keyword_grant":
        return None
    keywords = [
        str(value).strip().lower().replace(" ", "_")
        for value in required.get("static_granted_keywords", []) or []
        if str(value).strip()
    ]
    if not keywords:
        return None
    subtypes = [
        str(value).strip().lower()
        for value in required.get("static_required_subtypes", []) or []
        if str(value).strip()
    ]
    colors = [
        str(value).strip().upper()
        for value in required.get("static_required_colors", []) or []
        if str(value).strip()
    ]
    supertypes = [
        str(value).strip().title()
        for value in required.get("static_required_supertypes", []) or []
        if str(value).strip()
    ]
    subtype = subtypes[0] if subtypes else "soldier"
    type_prefix = "Artifact Creature" if required.get("static_artifact_creature") else "Creature"
    if supertypes:
        type_prefix = f"{' '.join(supertypes)} {type_prefix}"
    matching_target = {
        "name": f"E2E Controlled Keyword Target for {rule['card_name']}",
        "type_line": f"{type_prefix} - {subtype.title()}",
        "base_power": 2,
        "base_toughness": 2,
        "power": 2,
        "toughness": 2,
    }
    if colors:
        matching_target["colors"] = colors
        matching_target["mana_cost"] = "".join(f"{{{color}}}" for color in colors)
    nonmatching_target = None
    if subtypes or colors or required.get("static_artifact_creature") or supertypes:
        nonmatching_target = {
            "name": f"E2E Nonmatching Keyword Target for {rule['card_name']}",
            "type_line": "Creature - Goblin",
            "base_power": 2,
            "base_toughness": 2,
            "power": 2,
            "toughness": 2,
        }
        if colors:
            off_color = "U" if "U" not in colors else "R"
            nonmatching_target["colors"] = [off_color]
            nonmatching_target["mana_cost"] = f"{{{off_color}}}"
    opponent_target = dict(matching_target)
    opponent_target["name"] = f"E2E Opponent Keyword Target for {rule['card_name']}"
    return {
        "name": f"{rule['card_name']} static controlled keyword applies",
        "type": "static_controlled_keyword",
        "card": {"name": rule["card_name"]},
        "matching_target": matching_target,
        "nonmatching_target": nonmatching_target,
        "opponent_target": opponent_target,
        "expected_keyword": keywords[0],
        "expected_source": rule["card_name"],
        "logical_rule_key": rule["logical_rule_key"],
    }


def aura_static_pt_execution_scenario_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("effect") != "aura_static_attachment":
        return None
    power_bonus = int(required.get("power_boost") or required.get("static_power_bonus") or 0)
    toughness_bonus = int(required.get("toughness_boost") or required.get("static_toughness_bonus") or 0)
    target_controller = str(required.get("enchant_target_controller") or "any").lower()
    if target_controller in {"opponent", "opponents"}:
        target_owner = "opponent"
    elif target_controller in {"self", "you", "controller"}:
        target_owner = "controller"
    else:
        target_owner = "opponent" if power_bonus < 0 or toughness_bonus < 0 else "controller"
    target = {
        "name": f"E2E Aura Target for {rule['card_name']}",
        "type_line": "Creature - Soldier",
        "base_power": 2,
        "base_toughness": 2,
        "power": 2,
        "toughness": 2,
    }
    expected_toughness = target["base_toughness"] + toughness_bonus
    return {
        "name": f"{rule['card_name']} aura static P/T attaches",
        "type": "aura_static_power_toughness_attachment",
        "card": {"name": rule["card_name"]},
        "target": target,
        "target_owner": target_owner,
        "expected_power": target["base_power"] + power_bonus,
        "expected_toughness": expected_toughness,
        "expected_moved_to_graveyard": expected_toughness <= 0,
        "expected_source": rule["card_name"],
        "logical_rule_key": rule["logical_rule_key"],
    }


def equipment_static_pt_execution_scenario_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("effect") != "equipment_static_attachment":
        return None
    power_bonus = int(required.get("power_boost") or required.get("static_power_bonus") or 0)
    toughness_bonus = int(required.get("toughness_boost") or required.get("static_toughness_bonus") or 0)
    attached_keywords = [
        str(value).strip().lower().replace(" ", "_")
        for value in required.get("attached_keywords", []) or []
        if str(value).strip()
    ]
    target = {
        "name": f"E2E Equipment Target for {rule['card_name']}",
        "type_line": "Creature - Soldier",
        "base_power": 2,
        "base_toughness": 2,
        "power": 2,
        "toughness": 2,
    }
    return {
        "name": f"{rule['card_name']} equipment static P/T attaches",
        "type": "equipment_static_power_toughness_attachment",
        "card": {"name": rule["card_name"], "type_line": "Artifact - Equipment"},
        "target": target,
        "expected_power": target["base_power"] + power_bonus,
        "expected_toughness": target["base_toughness"] + toughness_bonus,
        "expected_keywords": attached_keywords,
        "expected_source": rule["card_name"],
        "logical_rule_key": rule["logical_rule_key"],
    }


def static_count_pt_execution_scenario_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_static_source_power_toughness_equal_count_v1":
        return None
    amount_source = str(required.get("static_power_toughness_source") or "")
    scope = str(required.get("battlefield_count_scope") or "controller_battlefield")
    card_types = [str(value).lower() for value in required.get("battlefield_count_card_types") or []]
    subtypes = [str(value).lower() for value in required.get("battlefield_count_subtypes") or []]
    required_colors = [str(value).upper() for value in required.get("battlefield_count_required_colors") or []]
    excluded_card_types = [
        str(value).lower() for value in required.get("battlefield_count_excluded_card_types") or []
    ]
    excluded_subtypes = [
        str(value).lower() for value in required.get("battlefield_count_excluded_subtypes") or []
    ]
    card_names = [str(value) for value in required.get("battlefield_count_card_names") or []]
    tapped_state = str(required.get("battlefield_count_tapped_state") or "").lower()
    source_type_line = "Creature - Avatar"
    matching_type_line = "Creature - Soldier"
    if "land" in card_types:
        source_type_line = "Creature - Avatar"
        matching_type_line = "Land"
    elif subtypes:
        subtype_title = subtypes[0].title()
        if subtypes[0] in {"plains", "island", "swamp", "mountain", "forest"}:
            source_type_line = "Creature - Avatar"
            matching_type_line = f"Land - {subtype_title}"
        else:
            source_type_line = f"Creature - {subtype_title}"
            matching_type_line = f"Creature - {subtype_title}"
    source_card = {
        "name": rule["card_name"],
        "type_line": source_type_line,
        "effect": "creature",
        "power": 0,
        "toughness": 0,
    }
    if required_colors:
        source_card["colors"] = [required_colors[0]]
        source_card["mana_cost"] = f"{{{required_colors[0]}}}"
    if tapped_state == "untapped":
        source_card["tapped"] = False
    controller_battlefield = []
    opponent_battlefield = []
    controller_hand = []
    opponent_hand = []
    if amount_source == "controller_hand_count":
        controller_hand = [
            {"name": f"E2E Controller Hand Card {index + 1}", "type_line": "Instant"}
            for index in range(3)
        ]
        expected_count = len(controller_hand)
    elif amount_source == "opponent_max_hand_count":
        opponent_hand = [
            {"name": f"E2E Opponent Hand Card {index + 1}", "type_line": "Sorcery"}
            for index in range(4)
        ]
        expected_count = len(opponent_hand)
    elif amount_source == "all_players_hand_count":
        controller_hand = [
            {"name": f"E2E Controller Hand Card {index + 1}", "type_line": "Instant"}
            for index in range(2)
        ]
        opponent_hand = [
            {"name": f"E2E Opponent Hand Card {index + 1}", "type_line": "Sorcery"}
            for index in range(3)
        ]
        expected_count = len(controller_hand) + len(opponent_hand)
    elif amount_source == "domain_basic_land_types":
        controller_battlefield = [
            {"name": subtype, "type_line": f"Basic Land - {subtype}", "subtypes": [subtype]}
            for subtype in ("Plains", "Island", "Swamp", "Mountain")
        ]
        expected_count = len(controller_battlefield)
    elif amount_source != "battlefield_permanent_count":
        return None
    elif card_names:
        matching_name = card_names[0]
        source_card["type_line"] = "Creature - Rat"
        controller_battlefield.extend(
            [
                {"name": matching_name.title(), "type_line": "Creature - Rat"},
                {"name": "E2E Nonmatching Rat", "type_line": "Creature - Rat"},
            ]
        )
        expected_count = 2
    elif required_colors:
        color = required_colors[0]
        controller_battlefield.extend(
            [
                {
                    "name": f"E2E Matching {color} Permanent",
                    "type_line": "Artifact",
                    "colors": [color],
                    "mana_cost": f"{{{color}}}",
                },
                {
                    "name": "E2E Off Color Permanent",
                    "type_line": "Artifact",
                    "colors": ["U" if color != "U" else "R"],
                    "mana_cost": "{U}" if color != "U" else "{R}",
                },
            ]
        )
        expected_count = 2
    elif excluded_card_types:
        controller_battlefield.extend(
            [
                {"name": "E2E Matching Artifact", "type_line": "Artifact"},
                {"name": "E2E Excluded Land", "type_line": "Land"},
            ]
        )
        expected_count = 2
    elif excluded_subtypes:
        controller_battlefield.extend(
            [
                {"name": "E2E Matching Creature", "type_line": "Creature - Soldier"},
                {"name": "E2E Excluded Wall", "type_line": "Creature - Wall"},
            ]
        )
        expected_count = 2
    elif tapped_state == "untapped":
        controller_battlefield.extend(
            [
                {"name": "E2E Untapped Artifact", "type_line": "Artifact", "tapped": False},
                {"name": "E2E Untapped Land", "type_line": "Land", "tapped": False},
                {"name": "E2E Tapped Creature", "type_line": "Creature - Soldier", "tapped": True},
            ]
        )
        expected_count = 3
    elif scope == "all_battlefields":
        controller_battlefield.append(
            {
                "name": f"E2E Controller Matching Permanent for {rule['card_name']}",
                "type_line": matching_type_line,
            }
        )
        opponent_battlefield.append(
            {
                "name": f"E2E Opponent Matching Permanent for {rule['card_name']}",
                "type_line": matching_type_line,
            }
        )
        expected_count = 3 if not card_types or "creature" in card_types or subtypes else 2
    else:
        if "creature" in card_types or (
            subtypes and subtypes[0] not in {"plains", "island", "swamp", "mountain", "forest"}
        ):
            controller_battlefield.append(
                {
                    "name": f"E2E Matching Creature for {rule['card_name']}",
                    "type_line": matching_type_line,
                }
            )
            expected_count = 2
        else:
            controller_battlefield.extend(
                [
                    {
                        "name": f"E2E Matching Land A for {rule['card_name']}",
                        "type_line": matching_type_line,
                    },
                    {
                        "name": f"E2E Matching Land B for {rule['card_name']}",
                        "type_line": matching_type_line,
                    },
                ]
            )
            expected_count = 2
    base = int(required.get("static_power_toughness_base") or 0)
    multiplier = int(required.get("static_power_toughness_count_multiplier") or 1)
    expected_value = base + (expected_count * multiplier)
    return {
        "name": f"{rule['card_name']} static count P/T recalculates",
        "type": "static_count_power_toughness",
        "card": source_card,
        "controller_battlefield": controller_battlefield,
        "opponent_battlefield": opponent_battlefield,
        "controller_hand": controller_hand,
        "opponent_hand": opponent_hand,
        "expected_count": expected_count,
        "expected_power": expected_value,
        "expected_toughness": expected_value,
        "logical_rule_key": rule["logical_rule_key"],
    }


def static_graveyard_threshold_boost_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_static_source_boost_if_graveyard_threshold_v1":
        return None
    if required.get("static_effect") != "source_power_toughness_boost_if_graveyard_count":
        return None

    base_power = 1
    base_toughness = 1
    count_mode = str(required.get("graveyard_count_mode") or "").strip().lower()
    card_types = [str(value).lower() for value in required.get("graveyard_count_card_types") or ["card"]]
    threshold = int(required.get("graveyard_count_threshold") or 0)
    if count_mode == "distinct_card_types":
        controller_graveyard = [
            {"name": "E2E Graveyard Creature", "type_line": "Creature"},
            {"name": "E2E Graveyard Instant", "type_line": "Instant"},
            {"name": "E2E Graveyard Land", "type_line": "Land"},
            {"name": "E2E Graveyard Enchantment", "type_line": "Enchantment"},
        ]
        expected_count = 4
    elif "permanent" in card_types:
        controller_graveyard = [
            {"name": "E2E Graveyard Creature", "type_line": "Creature"},
            {"name": "E2E Graveyard Artifact", "type_line": "Artifact"},
            {"name": "E2E Graveyard Land", "type_line": "Land"},
            {"name": "E2E Graveyard Enchantment", "type_line": "Enchantment"},
        ]
        expected_count = len(controller_graveyard)
    else:
        expected_count = max(threshold, 1)
        controller_graveyard = [
            {"name": f"E2E Graveyard Card {index}", "type_line": "Instant"}
            for index in range(1, expected_count + 1)
        ]

    return {
        "name": f"{rule['card_name']} graveyard threshold boost applies",
        "type": "static_graveyard_threshold_source_boost",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature - E2E",
            "power": base_power,
            "toughness": base_toughness,
        },
        "controller_graveyard": controller_graveyard,
        "expected_count": expected_count,
        "expected_active": True,
        "expected_power": base_power + int(required.get("static_power_bonus") or 0),
        "expected_toughness": base_toughness + int(required.get("static_toughness_bonus") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }


def destroy_target_create_treasure_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_destroy_target_create_treasure_spell_v1":
        return None
    target_type = str(required.get("target") or "permanent").lower()
    if target_type == "artifact_or_enchantment":
        target = {
            "name": f"E2E Artifact Target for {rule['card_name']}",
            "type_line": "Artifact",
            "effect": "artifact",
            "cmc": 2,
        }
    elif target_type == "creature_or_planeswalker":
        target = {
            "name": f"E2E Creature Target for {rule['card_name']}",
            "type_line": "Creature - Soldier",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
            "cmc": 3,
        }
    elif target_type == "creature":
        target = {
            "name": f"E2E Creature Target for {rule['card_name']}",
            "type_line": "Creature - Soldier",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "cmc": 2,
        }
    else:
        target = {
            "name": f"E2E Permanent Target for {rule['card_name']}",
            "type_line": "Artifact",
            "effect": "artifact",
            "cmc": 2,
        }
    return {
        "name": f"{rule['card_name']} destroys target and creates Treasure",
        "type": "destroy_target_create_treasure",
        "card": {"name": rule["card_name"]},
        "target": target,
        "expected_treasure_count": int(
            required.get("controller_treasure_tokens")
            or required.get("treasure_count")
            or 1
        ),
        "logical_rule_key": rule["logical_rule_key"],
    }


def creature_etb_fixed_mana_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_etb_add_fixed_mana_v1":
        return None
    produced = int(required.get("etb_mana_produced") or required.get("mana_produced") or 0)
    if produced <= 0:
        return None
    condition = str(required.get("etb_mana_condition") or "").strip()
    cast_from_zone = "hand" if condition == "cast_from_hand" else "graveyard" if condition == "cast" else "hand"
    return {
        "name": f"{rule['card_name']} ETB adds fixed mana",
        "type": "creature_etb_fixed_mana",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature - Elemental",
            "effect": required.get("effect") or "creature",
        },
        "was_cast": True,
        "cast_from_zone": cast_from_zone,
        "expected_mana_added": produced,
        "expected_produced_mana_symbols": list(
            required.get("etb_produced_mana_symbols")
            or required.get("produced_mana_symbols")
            or []
        ),
        "expected_condition": condition,
        "logical_rule_key": rule["logical_rule_key"],
    }


def creature_etb_create_treasure_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_etb_create_treasure_v1":
        return None
    expected_condition = required.get("etb_treasure_condition")
    scenario = {
        "name": f"{rule['card_name']} ETB creates Treasure",
        "type": "creature_etb_create_treasure",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature - Pirate",
            "effect": "creature",
        },
        "expected_treasure_count": int(
            required.get("etb_treasure_count")
            or required.get("treasure_count")
            or 1
        ),
        "expected_keywords": list(required.get("keywords") or []),
        "logical_rule_key": rule["logical_rule_key"],
    }
    if expected_condition:
        scenario["expected_condition"] = expected_condition
        if expected_condition == "opponent_controls_more_lands":
            scenario["controller_land_count"] = 1
            scenario["opponent_land_count"] = 2
    return scenario


def expected_token_from_component(component: dict[str, Any]) -> dict[str, Any]:
    expected = {
        "name": component.get("token_name"),
        "count": int(component.get("token_count") or 1),
        "power": component.get("token_power"),
        "toughness": component.get("token_toughness"),
        "subtype": component.get("token_subtype"),
        "colors": component.get("token_colors") or [],
        "keywords": component.get("token_keywords") or [],
        "artifact": bool(component.get("artifact_tokens")),
        "tapped": bool(component.get("token_tapped")),
        "sacrifice_for_colorless_mana": bool(
            component.get("token_sacrifice_for_colorless_mana")
        ),
        "mana_produced": component.get("token_mana_produced"),
        "produces": component.get("token_produces"),
        "produced_mana_symbols": component.get("token_produced_mana_symbols") or [],
        "artifact_only": bool(component.get("token_artifact_only")),
    }
    if component.get("token_cant_block"):
        expected["cant_block"] = True
    return expected


DYNAMIC_TOKEN_COUNT_SCENARIO_TARGET = 3


def apply_dynamic_token_count_scenario_fields(
    scenario: dict[str, Any],
    expected_token: dict[str, Any],
    source: str | None,
    *,
    source_prefix: str = "",
    include_dying_permanent: bool = False,
) -> None:
    source_text = str(source or "").strip().lower()
    if not source_text:
        return
    if source_prefix:
        scenario[f"{source_prefix}_token_count_source"] = source_text
    else:
        scenario["token_count_source"] = source_text
    expected_count = DYNAMIC_TOKEN_COUNT_SCENARIO_TARGET
    expected_token["count"] = expected_count
    if source_text == "controller_graveyard_creature_count":
        if include_dying_permanent:
            scenario["controller_graveyard_creature_count_before_death"] = max(0, expected_count - 1)
        else:
            scenario["controller_graveyard_creature_count"] = expected_count
    elif source_text == "controller_graveyard_instant_sorcery_count":
        scenario["controller_graveyard_instant_sorcery_count"] = expected_count
    elif source_text == "creatures_you_control_died_this_turn":
        scenario["creatures_you_control_died_this_turn_count"] = expected_count
    elif source_text.startswith("devotion_to_"):
        scenario["expected_dynamic_token_count"] = expected_count


def creature_etb_create_tokens_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_etb_create_tokens_v1":
        return None
    components = required.get("_composite_rule_components") or []
    scenario = {
        "name": f"{rule['card_name']} enters and creates modeled creature tokens",
        "type": "creature_etb_create_tokens",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature",
            "effect": "creature",
        },
        "expected_keywords": list(required.get("keywords") or []),
        "logical_rule_key": rule["logical_rule_key"],
    }
    if isinstance(components, list) and components:
        expected_tokens = [
            expected_token_from_component(component)
            for component in components
            if isinstance(component, dict) and component.get("effect") == "token_maker"
        ]
        if not expected_tokens:
            return None
        scenario["expected_tokens"] = expected_tokens
        scenario["expected_component_count"] = int(
            required.get("token_component_count") or len(expected_tokens)
        )
        scenario["expected_total_tokens"] = int(
            required.get("token_total_count")
            or sum(int(token.get("count") or 0) for token in expected_tokens)
        )
        return scenario
    scenario["expected_token"] = {
        "name": required.get("etb_token_name"),
        "count": int(required.get("etb_token_count") or 1),
        "power": required.get("etb_token_power"),
        "toughness": required.get("etb_token_toughness"),
        "subtype": required.get("etb_token_subtype"),
        "colors": required.get("etb_token_colors") or [],
        "keywords": required.get("etb_token_keywords") or [],
        "artifact": bool(required.get("etb_artifact_tokens")),
        "tapped": bool(required.get("etb_token_tapped")),
        "sacrifice_for_colorless_mana": bool(
            required.get("etb_token_sacrifice_for_colorless_mana")
        ),
        "mana_produced": required.get("etb_token_mana_produced"),
        "produces": required.get("etb_token_produces"),
        "produced_mana_symbols": required.get("etb_token_produced_mana_symbols") or [],
        "artifact_only": bool(required.get("etb_token_artifact_only")),
    }
    if required.get("etb_token_cant_block"):
        scenario["expected_token"]["cant_block"] = True
    apply_dynamic_token_count_scenario_fields(
        scenario,
        scenario["expected_token"],
        required.get("etb_token_count_source"),
        source_prefix="etb",
    )
    return scenario


def creature_etb_scry_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_etb_scry_v1":
        return None
    scry_count = int(
        required.get("etb_scry_count")
        or required.get("trigger_scry_count")
        or required.get("scry_count")
        or 0
    )
    if scry_count <= 0:
        return None
    return {
        "name": f"{rule['card_name']} enters and scries {scry_count}",
        "type": "creature_etb_scry",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature",
            "effect": "creature",
        },
        "expected_scry_count": scry_count,
        "expected_keywords": list(required.get("keywords") or []),
        "library_top_names": [
            "Low Priority Land",
            "High Priority Spell",
            "Medium Priority Creature",
            "Reserve Card",
        ],
        "logical_rule_key": rule["logical_rule_key"],
    }


def creature_dies_create_treasure_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_dies_create_treasure_v1":
        return None
    return {
        "name": f"{rule['card_name']} dies and creates Treasure",
        "type": "creature_dies_create_treasure",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature",
            "effect": "creature",
        },
        "expected_treasure_count": int(
            required.get("dies_treasure_count")
            or required.get("treasure_count")
            or 1
        ),
        "expected_keywords": list(required.get("keywords") or []),
        "logical_rule_key": rule["logical_rule_key"],
    }


def creature_dies_add_counters_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_dies_add_counters_target_creature_v1":
        return None
    constraints = dict(required.get("target_constraints") or {"card_types": ["creature"]})
    counter_type = str(required.get("dies_add_counters_counter_type") or required.get("counter_type") or "+1/+1")
    target_controller = str(required.get("target_controller") or "any")
    target_owner = "opponent" if counter_type == "-1/-1" and target_controller == "any" else "controller"
    if target_controller == "opponent":
        target_owner = "opponent"
    target = _target_fixture_from_constraints(
        "E2E Dies Counter Target",
        constraints,
        matching=True,
    )
    target.setdefault("power", 3)
    target.setdefault("toughness", 3)
    nonmatching = _target_fixture_from_constraints(
        "E2E Illegal Dies Counter Target",
        constraints,
        matching=False,
    )
    return {
        "name": f"{rule['card_name']} dies and adds counters to target creature",
        "type": "creature_dies_add_counters",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature",
            "effect": "creature",
        },
        "target": target,
        "target_owner": target_owner,
        "nonmatching_target": nonmatching,
        "expected_counter_type": counter_type,
        "expected_counter_count": int(
            required.get("dies_add_counters_count")
            or required.get("counter_count")
            or required.get("count")
            or 1
        ),
        "expected_target_controller": target_controller,
        "expected_target_constraints": constraints,
        "expected_optional": bool(required.get("dies_add_counters_optional") or required.get("optional")),
        "expected_keywords": list(required.get("keywords") or []),
        "logical_rule_key": rule["logical_rule_key"],
    }


def fixed_create_creature_tokens_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_fixed_create_creature_tokens_spell_v1",
        "xmage_controlled_subtype_create_creature_tokens_spell_v1",
        "xmage_dynamic_count_create_creature_tokens_spell_v1",
    }:
        return None
    expected_count = int(required.get("token_count") or 1)
    scenario = {
        "name": f"{rule['card_name']} creates modeled creature tokens",
        "type": "fixed_create_creature_tokens",
        "card": {"name": rule["card_name"]},
        "expected_token": {
            "name": required.get("token_name"),
            "count": expected_count,
            "power": required.get("token_power"),
            "toughness": required.get("token_toughness"),
            "subtype": required.get("token_subtype"),
            "colors": required.get("token_colors") or [],
            "keywords": required.get("token_keywords") or [],
            "artifact": bool(required.get("artifact_tokens")),
            "tapped": bool(required.get("token_tapped")),
        },
        "logical_rule_key": rule["logical_rule_key"],
    }
    if required.get("token_cant_block"):
        scenario["expected_token"]["cant_block"] = True
    if required.get("token_count_source") == "controlled_permanents_with_subtype":
        expected_count = 3
        scenario["expected_token"]["count"] = expected_count
        scenario["controlled_permanent_subtype"] = required.get("token_count_subtype")
        scenario["controlled_permanent_subtype_count"] = expected_count
    elif required.get("token_count_source") == "all_creatures_on_battlefield":
        expected_count = 4
        scenario["expected_token"]["count"] = expected_count
        scenario["opponent_battlefield_creature_count"] = 2
        scenario["controlled_battlefield_creature_count"] = expected_count - 2
    elif required.get("token_count_source") == "attacking_creatures":
        expected_count = 3
        scenario["expected_token"]["count"] = expected_count
        scenario["attacking_creature_count"] = expected_count
    elif required.get("token_count_source") == "controlled_tapped_creatures":
        expected_count = 3
        scenario["expected_token"]["count"] = expected_count
        scenario["controlled_tapped_creature_count"] = expected_count
    elif required.get("token_count_source") == "greatest_power_among_controlled_creatures":
        scenario["controlled_creature_powers"] = [1, 4, 2]
        scenario["expected_token"]["count"] = 4
    elif required.get("token_count_source") == "controller_hand_count":
        expected_count = 4
        scenario["expected_token"]["count"] = expected_count
        scenario["controller_hand_card_count"] = expected_count
    elif required.get("token_count_source") == "domain_basic_land_types":
        domain_subtypes = ["Plains", "Island", "Mountain"]
        scenario["expected_token"]["count"] = len(domain_subtypes)
        scenario["domain_basic_land_subtypes"] = domain_subtypes
    elif required.get("token_count_source") == "controller_graveyard_creature_count":
        expected_count = 3
        scenario["expected_token"]["count"] = expected_count
        scenario["controller_graveyard_creature_count"] = expected_count
    elif required.get("token_count_source") == "controller_graveyard_instant_sorcery_count":
        expected_count = 3
        scenario["expected_token"]["count"] = expected_count
        scenario["controller_graveyard_instant_sorcery_count"] = expected_count
    elif required.get("token_count_source") == "named_cards_in_controller_graveyard_plus_base":
        graveyard_count = 2
        base_count = int(required.get("token_count_base") or 0)
        scenario["controller_graveyard_named_card"] = required.get("token_count_card_name") or rule["card_name"]
        scenario["controller_graveyard_named_card_count"] = graveyard_count
        scenario["expected_token"]["count"] = base_count + graveyard_count
    elif str(required.get("token_count_source") or "").strip().lower() in {
        "creatures_you_control_died_this_turn",
        "devotion_to_white",
        "devotion_to_blue",
        "devotion_to_black",
        "devotion_to_red",
        "devotion_to_green",
    }:
        apply_dynamic_token_count_scenario_fields(
            scenario,
            scenario["expected_token"],
            required.get("token_count_source"),
        )
    return scenario


def multi_create_creature_tokens_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_multi_create_creature_tokens_spell_v1":
        return None
    components = required.get("_composite_rule_components") or []
    if not isinstance(components, list) or not components:
        return None
    expected_tokens = []
    for component in components:
        if not isinstance(component, dict) or component.get("effect") != "token_maker":
            return None
        expected_token = {
            "name": component.get("token_name"),
            "count": int(component.get("token_count") or 1),
            "power": component.get("token_power"),
            "toughness": component.get("token_toughness"),
            "subtype": component.get("token_subtype"),
            "colors": component.get("token_colors") or [],
            "keywords": component.get("token_keywords") or [],
            "artifact": bool(component.get("artifact_tokens")),
        }
        if component.get("token_cant_block"):
            expected_token["cant_block"] = True
        expected_tokens.append(expected_token)
    return {
        "name": f"{rule['card_name']} creates multiple modeled creature tokens",
        "type": "multi_create_creature_tokens",
        "card": {"name": rule["card_name"]},
        "expected_tokens": expected_tokens,
        "expected_component_count": int(required.get("token_component_count") or len(components)),
        "expected_total_tokens": int(
            required.get("token_total_count")
            or sum(int(token.get("count") or 0) for token in expected_tokens)
        ),
        "logical_rule_key": rule["logical_rule_key"],
    }


def dynamic_life_gain_execution_scenario_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_dynamic_controller_gain_life_spell_v1":
        return None
    source = str(required.get("life_gain_amount_source") or "").strip().lower()
    base = int(required.get("life_gain_base_amount") or 0)
    per = int(required.get("life_gain_per_count") or 1)
    scenario: dict[str, Any] = {
        "name": f"{rule['card_name']} resolves dynamic life gain",
        "type": "dynamic_life_gain",
        "card": {"name": rule["card_name"]},
        "starting_life": 20,
        "logical_rule_key": rule["logical_rule_key"],
        "expected_life_gain_source": source,
    }

    count = 0
    if source == "controller_hand_count":
        count = 3
        scenario["controller_hand"] = [
            {"name": f"E2E Hand Card {index + 1}", "type_line": "Sorcery"}
            for index in range(count)
        ]
    elif source == "domain_basic_land_types":
        subtypes = ["Plains", "Island", "Swamp", "Mountain"]
        count = len(subtypes)
        scenario["controller_battlefield"] = [
            {"name": subtype, "type_line": f"Basic Land - {subtype}", "subtypes": [subtype]}
            for subtype in subtypes
        ]
    elif source == "graveyard_card_count":
        count = 3
        scenario["controller_graveyard"] = [
            {"name": "E2E Graveyard Creature A", "type_line": "Creature - Spirit"},
            {"name": "E2E Graveyard Creature B", "type_line": "Creature - Soldier"},
        ]
        scenario["opponent_graveyard"] = [
            {"name": "E2E Opponent Graveyard Creature", "type_line": "Creature - Zombie"},
            {"name": "E2E Opponent Graveyard Instant", "type_line": "Instant"},
        ]
    elif source == "battlefield_permanent_count":
        scope = str(required.get("battlefield_count_scope") or "controller_battlefield")
        card_types = [str(value).lower() for value in required.get("battlefield_count_card_types") or []]
        subtypes = [str(value).lower() for value in required.get("battlefield_count_subtypes") or []]
        combat_state = str(required.get("battlefield_count_combat_state") or "").lower()
        tapped_state = str(required.get("battlefield_count_tapped_state") or "").lower()
        if scope == "opponents_battlefield":
            count = 3
            scenario["opponent_battlefield"] = [
                {
                    "name": f"E2E Attacking Creature {index + 1}",
                    "type_line": "Creature - Warrior",
                    "attacking": combat_state == "attacking",
                }
                for index in range(count)
            ]
        elif scope == "all_battlefields":
            subtype = (subtypes[0] if subtypes else "forest").title()
            count = 3
            scenario["controller_battlefield"] = [
                {"name": f"E2E {subtype} A", "type_line": f"Basic Land - {subtype}", "subtypes": [subtype]},
                {"name": f"E2E {subtype} B", "type_line": f"Basic Land - {subtype}", "subtypes": [subtype]},
            ]
            scenario["opponent_battlefield"] = [
                {"name": f"E2E Opponent {subtype}", "type_line": f"Basic Land - {subtype}", "subtypes": [subtype]}
            ]
        elif tapped_state == "tapped":
            count = 3
            scenario["controller_battlefield"] = [
                {"name": "E2E Tapped Artifact", "type_line": "Artifact", "tapped": True},
                {"name": "E2E Tapped Creature", "type_line": "Creature - Soldier", "tapped": True},
                {"name": "E2E Tapped Land", "type_line": "Basic Land - Plains", "tapped": True},
                {"name": "E2E Untapped Land", "type_line": "Basic Land - Island", "tapped": False},
            ]
        elif "land" in card_types:
            subtype = (subtypes[0] if subtypes else "plains").title()
            count = 3
            scenario["controller_battlefield"] = [
                {"name": f"E2E {subtype} {index + 1}", "type_line": f"Basic Land - {subtype}", "subtypes": [subtype]}
                for index in range(count)
            ]
        elif "creature" in card_types:
            count = 3
            scenario["controller_battlefield"] = [
                {"name": f"E2E Creature {index + 1}", "type_line": "Creature - Soldier"}
                for index in range(count)
            ]
        else:
            count = 3
            scenario["controller_battlefield"] = [
                {"name": f"E2E Permanent {index + 1}", "type_line": "Artifact"}
                for index in range(count)
            ]
    else:
        return None

    expected_life_gain = base + (count * per)
    scenario["expected_life_gain"] = expected_life_gain
    scenario["expected_life_after"] = int(scenario["starting_life"]) + expected_life_gain
    scenario["expected_dynamic_count"] = count
    return scenario


def _populate_etb_life_gain_count_fixture(scenario: dict[str, Any], required: dict[str, Any]) -> int | None:
    source = str(required.get("life_gain_amount_source") or "").strip().lower()
    if source == "controller_hand_count":
        count = 3
        scenario["controller_hand"] = [
            {"name": f"E2E Hand Card {index + 1}", "type_line": "Sorcery"}
            for index in range(count)
        ]
        return count
    if source == "domain_basic_land_types":
        subtypes = ["Plains", "Island", "Swamp", "Mountain"]
        scenario["controller_battlefield"] = [
            {"name": subtype, "type_line": f"Basic Land - {subtype}", "subtypes": [subtype]}
            for subtype in subtypes
        ]
        return len(subtypes)
    if source == "graveyard_card_count":
        card_types = [str(value).lower() for value in required.get("graveyard_count_card_types") or []]
        if "creature" in card_types:
            scenario["controller_graveyard"] = [
                {"name": "E2E Graveyard Creature A", "type_line": "Creature - Spirit"},
                {"name": "E2E Graveyard Creature B", "type_line": "Creature - Soldier"},
                {"name": "E2E Graveyard Instant", "type_line": "Instant"},
            ]
            return 2
        scenario["controller_graveyard"] = [
            {"name": "E2E Graveyard Card A", "type_line": "Creature - Spirit"},
            {"name": "E2E Graveyard Card B", "type_line": "Instant"},
            {"name": "E2E Graveyard Card C", "type_line": "Land"},
        ]
        return 3
    if source == "battlefield_permanent_count":
        card_types = [str(value).lower() for value in required.get("battlefield_count_card_types") or []]
        subtypes = [str(value).lower() for value in required.get("battlefield_count_subtypes") or []]
        keywords = [str(value).lower().replace(" ", "_") for value in required.get("battlefield_count_keywords") or []]
        count = 3
        if subtypes:
            subtype = subtypes[0].title()
            scenario["controller_battlefield"] = [
                {"name": f"E2E {subtype} {index + 1}", "type_line": f"Land - {subtype}", "subtypes": [subtype]}
                for index in range(count)
            ]
        elif keywords:
            keyword = keywords[0]
            scenario["controller_battlefield"] = [
                {"name": f"E2E Keyword Creature {index + 1}", "type_line": "Creature - Bird", keyword: True}
                for index in range(count)
            ]
        elif "creature" in card_types:
            scenario["controller_battlefield"] = [
                {"name": f"E2E Other Creature {index + 1}", "type_line": "Creature - Soldier"}
                for index in range(count)
            ]
        else:
            scenario["controller_battlefield"] = [
                {"name": f"E2E Permanent {index + 1}", "type_line": "Artifact"}
                for index in range(count)
            ]
        return count
    if source == "colors_among_permanents_you_control":
        scenario["controller_battlefield"] = [
            {"name": "E2E Boros Permanent", "type_line": "Artifact", "mana_cost": "{W}{R}"},
            {"name": "E2E Green Permanent", "type_line": "Creature - Elf", "mana_cost": "{G}"},
            {"name": "E2E Colorless Permanent", "type_line": "Artifact", "mana_cost": "{2}"},
        ]
        return 3
    if source == "party_count":
        scenario["controller_battlefield"] = [
            {"name": "E2E Cleric", "type_line": "Creature - Human Cleric"},
            {"name": "E2E Rogue", "type_line": "Creature - Human Rogue"},
            {"name": "E2E Warrior", "type_line": "Creature - Human Warrior"},
            {"name": "E2E Duplicate Rogue", "type_line": "Creature - Elf Rogue"},
        ]
        return 3
    if source == "controlled_permanents_mana_symbol_count":
        color = str(required.get("mana_symbol_count_color") or "G").upper()
        scenario["controller_battlefield"] = [
            {"name": "E2E Double Symbol", "type_line": "Creature - Druid", "mana_cost": f"{{{color}}}{{{color}}}"},
            {"name": "E2E Single Symbol", "type_line": "Enchantment", "mana_cost": f"{{2}}{{{color}}}"},
            {"name": "E2E Other Color", "type_line": "Artifact", "mana_cost": "{2}"},
        ]
        return 3
    if source == "greatest_toughness_among_other_controlled_creatures":
        scenario["controller_battlefield"] = [
            {"name": "E2E Tough Creature", "type_line": "Creature - Beast", "power": 2, "toughness": 5},
            {"name": "E2E Small Creature", "type_line": "Creature - Elf", "power": 1, "toughness": 2},
        ]
        return 5
    return None


def creature_etb_dynamic_life_gain_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_etb_dynamic_gain_life_v1":
        return None
    source = str(required.get("life_gain_amount_source") or "").strip().lower()
    base = int(required.get("life_gain_base_amount") or 0)
    per = int(required.get("life_gain_per_count") or 1)
    scenario: dict[str, Any] = {
        "name": f"{rule['card_name']} resolves ETB dynamic life gain",
        "type": "creature_etb_dynamic_life_gain",
        "card": {"name": rule["card_name"]},
        "starting_life": 20,
        "logical_rule_key": rule["logical_rule_key"],
        "expected_life_gain_source": source,
    }
    count = _populate_etb_life_gain_count_fixture(scenario, required)
    if count is None:
        return None
    expected_life_gain = base + (count * per)
    scenario["expected_dynamic_count"] = count
    scenario["expected_life_gain"] = expected_life_gain
    scenario["expected_life_after"] = int(scenario["starting_life"]) + expected_life_gain
    return scenario


def creature_enters_life_gain_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_enters_life_gain_trigger_v1":
        return None
    amount = int(required.get("trigger_gain_life") or 0)
    if amount <= 0:
        return None
    controller_scope = str(required.get("trigger_controller_scope") or "self")
    another_only = bool(required.get("trigger_another_creature_enters"))
    entering_controller = "opponent" if controller_scope == "any" else "controller"
    return {
        "name": f"{rule['card_name']} gains life when creature enters",
        "type": "creature_enters_life_gain",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature - Cleric",
            "effect": required.get("effect") or "creature",
        },
        "starting_life": 20,
        "source_starts_on_battlefield": bool(another_only or entering_controller == "opponent"),
        "entering_controller": entering_controller,
        "entering_creature": {
            "name": f"E2E Entering Creature for {rule['card_name']}",
            "type_line": "Creature - Soldier",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
        },
        "expected_trigger": required.get("trigger"),
        "expected_life_gain": amount,
        "expected_life_after": 20 + amount,
        "logical_rule_key": rule["logical_rule_key"],
    }


def creature_enters_draw_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_enters_draw_trigger_v1":
        return None
    count = int(required.get("trigger_draw_count") or 0)
    if count <= 0:
        return None
    controller_scope = str(required.get("trigger_controller_scope") or "self")
    entering_controller = "opponent" if controller_scope == "any" else "controller"
    subtypes = [str(value) for value in (required.get("trigger_entering_subtypes") or []) if value]
    subtype = subtypes[0].title() if subtypes else "Soldier"
    power = max(2, int(required.get("trigger_entering_power_min") or 0))
    library = [
        {"name": f"E2E Drawn Card {index + 1}", "type_line": "Sorcery", "effect": "draw_cards"}
        for index in range(count)
    ]
    return {
        "name": f"{rule['card_name']} draws when creature enters",
        "type": "creature_enters_draw",
        "card": {
            "name": rule["card_name"],
            "type_line": "Enchantment",
            "effect": required.get("effect") or "enchantment",
        },
        "source_starts_on_battlefield": True,
        "entering_controller": entering_controller,
        "entering_creature": {
            "name": f"E2E Entering Creature for {rule['card_name']}",
            "type_line": f"Creature - {subtype}",
            "subtypes": [subtype],
            "effect": "creature",
            "power": power,
            "toughness": max(1, power),
        },
        "controller_library": library,
        "expected_trigger": required.get("trigger"),
        "expected_draw_count": count,
        "expected_hand_after": count,
        "logical_rule_key": rule["logical_rule_key"],
    }


def _condition_fixture_permanents(required: dict[str, Any]) -> list[dict[str, Any]]:
    min_count = max(1, int(required.get("etb_draw_condition_min_count") or 1))
    card_types = [
        str(value).strip().lower()
        for value in (required.get("etb_draw_condition_card_types") or [])
        if str(value).strip()
    ]
    subtypes = [
        str(value).strip().lower()
        for value in (required.get("etb_draw_condition_subtypes") or [])
        if str(value).strip()
    ]
    colors = [
        str(value).strip().lower()
        for value in (required.get("etb_draw_condition_colors") or [])
        if str(value).strip()
    ]
    fixtures: list[dict[str, Any]] = []
    for index in range(min_count):
        if "artifact" in card_types:
            fixtures.append(
                {
                    "name": f"E2E Controlled Artifact {index + 1}",
                    "type_line": "Artifact",
                    "effect": "artifact",
                    "card_types": ["artifact"],
                }
            )
        elif "equipment" in subtypes:
            fixtures.append(
                {
                    "name": f"E2E Controlled Equipment {index + 1}",
                    "type_line": "Artifact - Equipment",
                    "effect": "artifact",
                    "card_types": ["artifact"],
                    "subtypes": ["Equipment"],
                }
            )
        elif "human" in subtypes:
            fixtures.append(
                {
                    "name": f"E2E Other Human {index + 1}",
                    "type_line": "Creature - Human",
                    "effect": "creature",
                    "power": 1,
                    "toughness": 1,
                    "subtypes": ["Human"],
                }
            )
        elif "gate" in subtypes:
            fixtures.append(
                {
                    "name": f"E2E Controlled Gate {index + 1}",
                    "type_line": "Land - Gate",
                    "effect": "land",
                    "subtypes": ["Gate"],
                }
            )
        elif "green" in colors or "g" in colors:
            fixtures.append(
                {
                    "name": f"E2E Green Permanent {index + 1}",
                    "type_line": "Creature - Elf",
                    "effect": "creature",
                    "mana_cost": "{G}",
                    "colors": ["G"],
                    "power": 1,
                    "toughness": 1,
                }
            )
        else:
            fixtures.append(
                {
                    "name": f"E2E Matching Permanent {index + 1}",
                    "type_line": "Artifact",
                    "effect": "artifact",
                }
            )
    return fixtures


def creature_etb_draw_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_etb_draw_cards_v1":
        return None
    if required.get("etb_draw_discard") or required.get("etb_dynamic_draw"):
        return None
    draw_count = int(required.get("etb_draw_count") or required.get("draw_count") or 0)
    if draw_count <= 0:
        return None
    scenario: dict[str, Any] = {
        "name": f"{rule['card_name']} draws on ETB",
        "type": "creature_etb_draw",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature - Wizard",
            "effect": required.get("effect") or "creature",
        },
        "controller_library": [
            {
                "name": f"E2E Drawn Card {index + 1}",
                "type_line": "Instant",
                "effect": "draw_cards",
                "cmc": 2,
            }
            for index in range(draw_count)
        ],
        "expected_draw_count": draw_count,
        "expected_hand_after": draw_count,
        "expected_keywords": list(required.get("keywords") or []),
        "logical_rule_key": rule["logical_rule_key"],
    }
    if required.get("etb_draw_condition"):
        scenario["expected_condition"] = required.get("etb_draw_condition")
        scenario["controller_battlefield"] = _condition_fixture_permanents(required)
    return scenario


def creature_etb_draw_discard_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_etb_draw_discard_cards_v1":
        return None
    draw_count = int(required.get("etb_draw_count") or required.get("draw_count") or 0)
    discard_count = int(required.get("etb_discard_count") or required.get("discard_count") or 0)
    if draw_count <= 0 or discard_count <= 0:
        return None
    return {
        "name": f"{rule['card_name']} draws then discards on ETB",
        "type": "creature_etb_draw_discard",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature - Wizard",
            "effect": required.get("effect") or "creature",
        },
        "controller_hand": [
            {
                "name": f"E2E Discard Candidate {index + 1}",
                "type_line": "Land",
                "effect": "land",
                "cmc": 0,
            }
            for index in range(discard_count)
        ],
        "controller_library": [
            {
                "name": f"E2E Drawn Card {index + 1}",
                "type_line": "Instant",
                "effect": "draw_cards",
                "cmc": 2,
            }
            for index in range(draw_count)
        ],
        "expected_draw_count": draw_count,
        "expected_discard_count": discard_count,
        "expected_hand_after": draw_count,
        "expected_graveyard_after": discard_count,
        "expected_keywords": list(required.get("keywords") or []),
        "logical_rule_key": rule["logical_rule_key"],
    }


def creature_etb_target_stat_modifier_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_etb_fixed_boost_target_until_eot_v1":
        return None
    return {
        "name": f"{rule['card_name']} boosts target creature on ETB",
        "type": "creature_etb_target_stat_modifier",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature - Soldier",
            "power": 2,
            "toughness": 2,
        },
        "target": {
            "name": "E2E Target Creature",
            "type_line": "Creature - Soldier",
            "power": 2,
            "toughness": 2,
        },
        "expected_power_delta": int(required.get("power_delta") or required.get("power_boost") or 0),
        "expected_toughness_delta": int(
            required.get("toughness_delta") or required.get("toughness_boost") or 0
        ),
        "logical_rule_key": rule["logical_rule_key"],
    }


def spell_cast_gain_life_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_spell_cast_gain_life_v1":
        return None
    amount = int(required.get("spell_cast_gain_life_amount") or 0)
    if amount <= 0:
        return None
    trigger = str(required.get("trigger") or "spell_cast")
    card_types = [str(value) for value in required.get("spell_cast_gain_life_card_types") or []]
    required_colors = [
        str(value)
        for value in required.get("spell_cast_gain_life_required_colors") or []
    ]
    matching_spell = {
        "name": f"E2E Matching Spell for {rule['card_name']}",
        "type_line": "Instant",
        "effect": "draw_cards",
        "cmc": 2,
    }
    nonmatching_spell = None
    if trigger == "noncreature_spell_cast":
        matching_spell["type_line"] = "Instant"
        nonmatching_spell = {
            "name": f"E2E Nonmatching Creature for {rule['card_name']}",
            "type_line": "Creature - Soldier",
            "effect": "creature",
            "cmc": 2,
        }
    elif card_types:
        primary_type = card_types[0]
        matching_spell["type_line"] = primary_type.title()
        nonmatching_spell = {
            "name": f"E2E Nonmatching Spell for {rule['card_name']}",
            "type_line": "Creature - Soldier",
            "effect": "creature",
            "cmc": 2,
        }
    elif required_colors:
        matching_spell["type_line"] = "Instant"
        matching_spell["colors"] = [required_colors[0]]
        nonmatching_color = next(
            (
                color
                for color in ["W", "U", "B", "R", "G"]
                if color not in set(required_colors)
            ),
            None,
        )
        nonmatching_spell = {
            "name": f"E2E Nonmatching Spell for {rule['card_name']}",
            "type_line": "Sorcery",
            "colors": [nonmatching_color or "C"],
            "effect": "draw_cards",
            "cmc": 2,
        }
    source_effect = required.get("effect") or "life_gain_engine"
    source_type_line = "Creature - Cleric" if source_effect == "creature" else "Artifact"
    scenario = {
        "name": f"{rule['card_name']} gains life when matching spell is cast",
        "type": "spell_cast_gain_life",
        "card": {
            "name": rule["card_name"],
            "type_line": source_type_line,
            "effect": source_effect,
        },
        "starting_life": 20,
        "matching_spell": matching_spell,
        "nonmatching_spell": nonmatching_spell,
        "expected_trigger": trigger,
        "expected_life_gain": amount,
        "expected_life_after": 20 + amount,
        "logical_rule_key": rule["logical_rule_key"],
    }
    if required.get("spell_cast_gain_life_any_player"):
        scenario["matching_spell_controller"] = "opponent"
        if nonmatching_spell is not None:
            scenario["nonmatching_spell_controller"] = "opponent"
    if required.get("land_enter_gain_life"):
        subtypes = [
            str(value).strip()
            for value in (required.get("land_enter_gain_life_subtypes") or [])
            if str(value).strip()
        ]
        matching_subtype = subtypes[0] if subtypes else "Plains"
        nonmatching_subtype = next(
            (
                subtype
                for subtype in ["Plains", "Island", "Swamp", "Mountain", "Forest"]
                if subtype.lower() != matching_subtype.lower()
            ),
            "Island",
        )
        scenario["matching_land"] = {
            "name": matching_subtype,
            "type_line": f"Basic Land - {matching_subtype}",
            "effect": "land",
        }
        scenario["nonmatching_land"] = {
            "name": nonmatching_subtype,
            "type_line": f"Basic Land - {nonmatching_subtype}",
            "effect": "land",
        }
        scenario["expected_land_life_after"] = (
            20 + amount + int(required.get("land_enter_gain_life_amount") or amount)
        )
        scenario["expected_land_subtypes"] = subtypes
    return scenario


def spell_cast_token_maker_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_spell_cast_create_creature_token_v1":
        return None
    expected_count = int(required.get("trigger_token_count") or required.get("token_count") or 1)
    if expected_count <= 0:
        return None
    trigger = str(required.get("trigger") or "spell_cast")
    card_types = [str(value) for value in required.get("spell_cast_token_card_types") or []]
    subtypes = [
        str(value).replace("_", " ").strip()
        for value in required.get("spell_cast_token_required_subtypes") or []
        if str(value).strip()
    ]
    required_colors = [
        str(value)
        for value in required.get("spell_cast_token_required_colors") or []
    ]
    mana_value_min = int(required.get("spell_cast_token_mana_value_min") or 0)
    matching_spell = {
        "name": f"E2E Matching Spell for {rule['card_name']}",
        "type_line": "Instant",
        "effect": "draw_cards",
        "cmc": max(2, mana_value_min or 2),
    }
    nonmatching_spell = {
        "name": f"E2E Nonmatching Spell for {rule['card_name']}",
        "type_line": "Creature - Goblin",
        "effect": "creature",
        "cmc": 2,
    }
    if trigger == "noncreature_spell_cast":
        matching_spell["type_line"] = "Instant"
        nonmatching_spell["type_line"] = "Creature - Soldier"
    elif card_types:
        primary_type = card_types[0].lower()
        if primary_type == "artifact":
            matching_spell["type_line"] = "Artifact"
            matching_spell["effect"] = "artifact"
        elif primary_type == "enchantment":
            matching_spell["type_line"] = "Enchantment"
            matching_spell["effect"] = "enchantment"
        elif primary_type == "creature":
            matching_spell["type_line"] = "Creature - Soldier"
            matching_spell["effect"] = "creature"
            nonmatching_spell["type_line"] = "Instant"
            nonmatching_spell["effect"] = "draw_cards"
        elif set(value.lower() for value in card_types) == {"instant", "sorcery"}:
            matching_spell["type_line"] = "Instant"
            nonmatching_spell["type_line"] = "Creature - Soldier"
    if subtypes:
        subtype_line = " ".join(subtype.title() for subtype in subtypes[:1])
        matching_spell["type_line"] = f"Creature - {subtype_line}"
        matching_spell["effect"] = "creature"
        nonmatching_spell["type_line"] = "Creature - Goblin"
        nonmatching_spell["effect"] = "creature"
    if required.get("spell_cast_token_requires_multicolored"):
        matching_spell["colors"] = ["W", "U"]
        matching_spell["mana_cost"] = "{W}{U}"
        nonmatching_spell["type_line"] = "Instant"
        nonmatching_spell["effect"] = "draw_cards"
        nonmatching_spell["colors"] = ["G"]
        nonmatching_spell["mana_cost"] = "{G}"
    elif required_colors:
        matching_spell["colors"] = [required_colors[0]]
        matching_spell["mana_cost"] = "{" + required_colors[0] + "}"
        nonmatching_spell["type_line"] = "Instant"
        nonmatching_spell["effect"] = "draw_cards"
        nonmatching_spell["colors"] = ["G"]
        nonmatching_spell["mana_cost"] = "{G}"
    if mana_value_min > 0:
        matching_spell["cmc"] = mana_value_min
        nonmatching_spell["type_line"] = matching_spell["type_line"]
        nonmatching_spell["effect"] = matching_spell.get("effect")
        nonmatching_spell["cmc"] = max(0, mana_value_min - 1)
    source_effect = str(required.get("effect") or "permanent")
    if source_effect == "creature":
        source_type_line = "Creature - Wizard"
    elif source_effect == "artifact":
        source_type_line = "Artifact"
    elif source_effect == "enchantment":
        source_type_line = "Enchantment"
    else:
        source_type_line = "Artifact"
    return {
        "name": f"{rule['card_name']} creates tokens when matching spell is cast",
        "type": "spell_cast_token_maker",
        "card": {
            "name": rule["card_name"],
            "type_line": source_type_line,
            "effect": source_effect,
        },
        "matching_spell": matching_spell,
        "nonmatching_spell": nonmatching_spell,
        "expected_trigger": trigger,
        "expected_token": expected_token_from_component(required),
        "expected_tokens_created": expected_count,
        "logical_rule_key": rule["logical_rule_key"],
    }


def creature_dies_create_tokens_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_dies_create_tokens_v1":
        return None
    scenario = {
        "name": f"{rule['card_name']} dies and creates modeled creature tokens",
        "type": "creature_dies_create_tokens",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature",
            "effect": "creature",
        },
        "expected_keywords": list(required.get("keywords") or []),
        "logical_rule_key": rule["logical_rule_key"],
    }
    components = required.get("_composite_rule_components") or []
    if isinstance(components, list) and components:
        expected_tokens = [
            expected_token_from_component(component)
            for component in components
            if isinstance(component, dict) and component.get("effect") == "token_maker"
        ]
        if not expected_tokens:
            return None
        scenario["expected_tokens"] = expected_tokens
        scenario["expected_component_count"] = int(
            required.get("token_component_count") or len(expected_tokens)
        )
        scenario["expected_total_tokens"] = int(
            required.get("token_total_count")
            or sum(int(token.get("count") or 0) for token in expected_tokens)
        )
        return scenario
    scenario["expected_token"] = {
        "name": required.get("dies_token_name"),
        "count": int(required.get("dies_token_count") or 1),
        "power": required.get("dies_token_power"),
        "toughness": required.get("dies_token_toughness"),
        "subtype": required.get("dies_token_subtype"),
        "colors": required.get("dies_token_colors") or [],
        "keywords": required.get("dies_token_keywords") or [],
        "artifact": bool(required.get("dies_artifact_tokens")),
        "tapped": bool(required.get("dies_token_tapped")),
        "sacrifice_for_colorless_mana": bool(
            required.get("dies_token_sacrifice_for_colorless_mana")
        ),
        "mana_produced": required.get("dies_token_mana_produced"),
        "produces": required.get("dies_token_produces"),
        "produced_mana_symbols": required.get("dies_token_produced_mana_symbols") or [],
        "artifact_only": bool(required.get("dies_token_artifact_only")),
    }
    if required.get("dies_token_cant_block"):
        scenario["expected_token"]["cant_block"] = True
    apply_dynamic_token_count_scenario_fields(
        scenario,
        scenario["expected_token"],
        required.get("dies_token_count_source"),
        source_prefix="dies",
        include_dying_permanent=True,
    )
    return scenario


def simple_activated_create_token_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_permanent_simple_activated_create_token_v1",
        "xmage_graveyard_self_exile_activated_create_token_v1",
    }:
        return None
    discard_target = str(required.get("activation_discard_target") or "any_card")
    discard_hand = []
    if int(required.get("activation_discard_count") or 0):
        if discard_target == "land_card":
            discard_hand = [
                {"name": "E2E Spare Mountain", "type_line": "Basic Land - Mountain", "effect": "land"},
                {"name": "E2E Nonland Spell", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        else:
            discard_hand = [
                {"name": "E2E Spare Card A", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
                {"name": "E2E Spare Card B", "type_line": "Instant", "effect": "direct_damage", "cmc": 1},
            ]
    scenario = {
        "name": f"{rule['card_name']} activates token ability",
        "type": "simple_activated_create_token",
        "card": {"name": rule["card_name"]},
        "controller_mana": _manifest_mana_for_required_activation(required),
        "controller_hand": discard_hand,
        "expected_token": {
            "name": required.get("token_name"),
            "count": int(required.get("token_count") or 1),
            "power": required.get("token_power"),
            "toughness": required.get("token_toughness"),
            "subtype": required.get("token_subtype"),
            "colors": required.get("token_colors") or [],
            "keywords": required.get("token_keywords") or [],
            "artifact": bool(required.get("artifact_tokens")),
            "tapped": bool(required.get("token_tapped")),
        },
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_discard_count": int(required.get("activation_discard_count") or 0),
        "expected_discard_target": discard_target,
        "expected_discard_random": bool(required.get("activation_discard_random")),
        "source_zone": required.get("activation_zone") or "battlefield",
        "expected_exiled_source_from_graveyard": bool(
            required.get("activation_requires_exile_source_from_graveyard")
        ),
        "logical_rule_key": rule["logical_rule_key"],
    }
    if required.get("token_cant_block"):
        scenario["expected_token"]["cant_block"] = True
    return scenario
    if required.get("token_cant_block"):
        result["expected_token"]["cant_block"] = True
    return result


def _manifest_mana_for_activation_cost(cost: str | None) -> dict[str, int]:
    mana = {
        "generic": 0,
        "white": 0,
        "blue": 0,
        "black": 0,
        "red": 0,
        "green": 0,
    }
    for token in re.findall(r"\{([^}]+)\}", str(cost or "")):
        token = token.strip().upper()
        if token.isdigit():
            mana["generic"] += int(token)
            continue
        if token == "S":
            mana["generic"] += 1
            continue
        if "/" in token:
            token = token.split("/", 1)[0]
        color = {
            "W": "white",
            "U": "blue",
            "B": "black",
            "R": "red",
            "G": "green",
        }.get(token)
        if color:
            mana[color] += 1
    return mana


def _manifest_mana_for_required_activation(
    required: dict[str, Any],
    *,
    cost_field: str = "activation_cost_mana",
    generic_field: str = "activation_cost_generic",
    colors_field: str = "activation_cost_colors",
) -> dict[str, int]:
    if required.get(cost_field) is not None:
        return _manifest_mana_for_activation_cost(required.get(cost_field))
    mana = _manifest_mana_for_activation_cost(None)
    mana["generic"] = int(required.get(generic_field) or 0)
    for symbol in list(required.get(colors_field) or []):
        token = str(symbol or "").strip().upper()
        if "/" in token:
            token = token.split("/", 1)[0]
        color = {
            "W": "white",
            "U": "blue",
            "B": "black",
            "R": "red",
            "G": "green",
        }.get(token)
        if color:
            mana[color] += 1
    return mana


def _manifest_has_multiple_mana_choices(value: Any) -> bool:
    if isinstance(value, str):
        symbols = re.findall(r"[WUBRG]", value.upper())
    elif isinstance(value, list):
        symbols = [
            str(item or "").strip().upper()
            for item in value
            if str(item or "").strip().upper() in {"W", "U", "B", "R", "G"}
        ]
    else:
        symbols = []
    return len(set(symbols)) > 1


def _manifest_conditional_life_loss_by_color(
    produces: Any,
    life_for_colored_mana: int,
) -> dict[str, int]:
    if not life_for_colored_mana:
        return {}
    color_names = {
        "W": "white",
        "U": "blue",
        "B": "black",
        "R": "red",
        "G": "green",
        "C": "colorless",
    }
    symbols = []
    if isinstance(produces, str):
        symbols = re.findall(r"[WUBRGC]", produces.upper())
    elif isinstance(produces, list):
        symbols = [
            str(symbol or "").strip().upper()
            for symbol in produces
            if str(symbol or "").strip().upper() in color_names
        ]
    result: dict[str, int] = {}
    for symbol in symbols:
        color = color_names.get(symbol)
        if not color:
            continue
        result[color] = 0 if symbol == "C" else int(life_for_colored_mana)
    return result


def _manifest_support_sources_for_controller_mana(mana: dict[str, int]) -> list[dict[str, Any]]:
    sources: list[dict[str, Any]] = []
    color_symbols = {
        "white": "W",
        "blue": "U",
        "black": "B",
        "red": "R",
        "green": "G",
        "generic": "C",
    }
    for color, symbol in color_symbols.items():
        for index in range(max(0, int(mana.get(color) or 0))):
            sources.append(
                {
                    "name": f"E2E {color.title()} Support Source {index + 1}",
                    "type_line": "Artifact",
                    "effect": "ramp_permanent",
                    "battle_model_scope": "e2e_support_mana_source_v1",
                    "is_mana_source": True,
                    "mana_produced": 1,
                    "produces": symbol,
                    "produced_mana_symbols": [symbol],
                    "mana_activation_requires_tap": True,
                }
            )
    return sources


def _manifest_land_color_dependency_lands(*, allows_colorless: bool) -> tuple[list[dict[str, Any]], list[str]]:
    lands = [
        {
            "name": "E2E Dependency Forest",
            "type_line": "Land",
            "produces": "G",
            "tapped": True,
        },
        {
            "name": "E2E Dependency Wastes",
            "type_line": "Land",
            "produces": "C",
            "tapped": True,
        },
    ]
    colors = ["green"]
    if allows_colorless:
        colors.append("colorless")
    return lands, colors


def _manifest_dynamic_fixed_mana_fixture(required: dict[str, Any]) -> tuple[dict[str, Any], int | None]:
    amount_source = str(required.get("dynamic_mana_amount_source") or "").strip().lower()
    if not amount_source:
        return {}, None
    if amount_source == "battlefield_permanent_count":
        scope = str(required.get("dynamic_mana_battlefield_count_scope") or "controller_battlefield").lower()
        subtypes = [str(value).lower() for value in required.get("dynamic_mana_battlefield_count_subtypes") or []]
        if "swamp" in subtypes:
            return {
                "controller_battlefield": [
                    {"name": f"E2E Swamp {index + 1}", "type_line": "Land - Swamp"}
                    for index in range(3)
                ]
            }, 3
        if "elf" in subtypes:
            fixture = {
                "controller_battlefield": [
                    {"name": "E2E Controller Elf", "type_line": "Creature - Elf"}
                ],
                "opponent_battlefield": [
                    {"name": "E2E Opponent Elf", "type_line": "Creature - Elf"}
                ],
            }
            return fixture, 3 if scope == "all_battlefield" else 2
    if amount_source == "devotion_to_green":
        return {
            "controller_battlefield": [
                {"name": "E2E Green Devotion One", "type_line": "Creature", "mana_cost": "{G}"},
                {"name": "E2E Green Devotion Two", "type_line": "Enchantment", "mana_cost": "{G}"},
            ]
        }, 3
    if amount_source == "source_power":
        return {"source_overrides": {"power": 3}}, 3
    return {}, None


def _manifest_controlled_creature_condition_conditional_mana_fixture(required: dict[str, Any]) -> tuple[dict[str, Any], int | None]:
    power_threshold = int(required.get("conditional_mana_controlled_creature_power_gte") or 0)
    count_threshold = int(required.get("conditional_mana_controlled_creature_count_gte") or 0)
    boosted_amount = int(required.get("conditional_mana_produced_when_condition_met") or 0)
    if (power_threshold <= 0 and count_threshold <= 0) or boosted_amount <= 0:
        return {}, None
    if power_threshold > 0:
        return {
            "controller_battlefield": [
                {
                    "name": "E2E Ferocious Creature",
                    "type_line": "Creature - Beast",
                    "power": power_threshold,
                    "toughness": power_threshold,
                }
            ]
        }, boosted_amount
    return {
        "controller_battlefield": [
            {"name": f"E2E Creature {index + 1}", "type_line": "Creature", "power": 1, "toughness": 1}
            for index in range(max(0, count_threshold - 1))
        ]
    }, boosted_amount


def simple_mana_source_execution_scenario_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("effect") != "ramp_permanent" or not required.get("is_mana_source"):
        return None
    if required.get("battle_model_scope") not in {
        "xmage_simple_tap_mana_source_permanent_v1",
        "xmage_simple_tap_mana_source_with_gain_life_v1",
        "xmage_simple_tap_mana_source_with_activated_draw_v1",
        "xmage_simple_mana_source_with_etb_draw_v1",
        "xmage_simple_tap_restricted_mana_source_permanent_v1",
        "xmage_simple_tap_land_color_dependent_mana_source_permanent_v1",
        "xmage_fixed_color_dynamic_mana_source_permanent_v1",
        "xmage_controlled_creature_condition_conditional_mana_source_permanent_v1",
        "pain_talisman_color_pair_partial_v1",
    }:
        return None
    mana_produced = int(required.get("mana_produced") or 0)
    if mana_produced <= 0:
        return None
    dynamic_fixture, dynamic_mana_produced = _manifest_dynamic_fixed_mana_fixture(required)
    controlled_creature_condition_fixture, controlled_creature_condition_mana_produced = _manifest_controlled_creature_condition_conditional_mana_fixture(required)
    expected_mana_produced = int(dynamic_mana_produced or controlled_creature_condition_mana_produced or mana_produced)
    controller_mana = _manifest_mana_for_activation_cost(required.get("activation_mana_cost"))
    activation_cost_total = sum(controller_mana.values())
    support_sources = _manifest_support_sources_for_controller_mana(controller_mana)
    enters_tapped = bool(required.get("enters_tapped"))
    activation_life_cost = int(required.get("activation_life_cost") or 0)
    activation_life_gain = int(required.get("mana_activation_life_gain") or 0)
    activation_discard_count = int(required.get("activation_discard_count") or 0)
    support_tap_count = int(required.get("mana_activation_tap_support_count") or 0)
    support_tap_type = str(required.get("mana_activation_tap_support_type") or "")
    controller_battlefield = []
    support_tapped_names: list[str] = []
    for index in range(max(0, support_tap_count)):
        if support_tap_type == "creature":
            support_card = {
                "name": f"E2E Untapped Support Creature {index + 1}",
                "type_line": "Creature - Citizen",
                "power": 1,
                "toughness": 1,
                "tapped": False,
            }
        elif support_tap_type == "artifact_or_creature":
            support_card = {
                "name": f"E2E Untapped Support Artifact {index + 1}",
                "type_line": "Artifact",
                "tapped": False,
            }
        else:
            support_card = {
                "name": f"E2E Untapped Support Permanent {index + 1}",
                "type_line": "Creature",
                "power": 1,
                "toughness": 1,
                "tapped": False,
            }
        controller_battlefield.append(support_card)
        support_tapped_names.append(support_card["name"])
    discard_hand = [
        {"name": f"E2E Spare Discard Card {index + 1}", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2}
        for index in range(max(0, activation_discard_count))
    ]
    conditional_modes = [
        mode
        for mode in required.get("conditional_mana_modes") or []
        if isinstance(mode, dict)
    ]
    conditional_restrictions = sorted(
        {
            str(mode.get("restriction") or "")
            for mode in conditional_modes
            if str(mode.get("restriction") or "")
        }
    )
    scenario = {
        "name": f"{rule['card_name']} refreshes modeled mana source",
        "type": "simple_mana_source_refresh",
        "card": {
            "name": rule["card_name"],
            "type_line": required.get("source_type_line") or "Artifact",
            "mana_cost": required.get("source_mana_cost") or "",
        },
        "type_line": required.get("source_type_line") or "Artifact",
        "controller_mana": controller_mana,
        "controller_hand": discard_hand,
        "expected_available_mana_after_refresh": (
            activation_cost_total if enters_tapped else expected_mana_produced
        ),
        "expected_tapped": (
            enters_tapped or bool(required.get("mana_activation_requires_tap", True))
        ),
        "expected_sources": len(support_sources) + (0 if enters_tapped else 1),
        "expected_produced_mana_symbols": required.get("produced_mana_symbols") or [],
        "expected_conditional_mana": (
            expected_mana_produced
            if (
                conditional_modes
                or (
                    _manifest_has_multiple_mana_choices(required.get("produces"))
                    and not required.get("produced_mana_symbols")
                )
            )
            and not enters_tapped
            else 0
        ),
        "expected_conditional_restrictions": conditional_restrictions,
        "expected_activation_limit_per_turn": int(required.get("activation_limit_per_turn") or 0),
        "controller_battlefield": controller_battlefield,
        "expected_support_tapped_count": support_tap_count,
        "expected_support_tapped_names": support_tapped_names,
        "support_mana_sources": support_sources,
        "source_overrides": {"tapped": True} if enters_tapped else {},
        "logical_rule_key": rule["logical_rule_key"],
    }
    for key, value in dynamic_fixture.items():
        if key == "source_overrides":
            scenario["source_overrides"] = {
                **dict(scenario.get("source_overrides") or {}),
                **dict(value or {}),
            }
        else:
            scenario[key] = value
    for key, value in controlled_creature_condition_fixture.items():
        if key == "source_overrides":
            scenario["source_overrides"] = {
                **dict(scenario.get("source_overrides") or {}),
                **dict(value or {}),
            }
        else:
            scenario[key] = value
    restriction_fixture_cards = {
        "creature_spell": (
            {"name": "E2E Creature Spell", "type_line": "Creature", "mana_cost": "{1}", "cmc": 1},
            {"name": "E2E Noncreature Spell", "type_line": "Sorcery", "mana_cost": "{1}", "cmc": 1},
        ),
        "artifact_spell": (
            {"name": "E2E Artifact Spell", "type_line": "Artifact", "mana_cost": "{1}", "cmc": 1},
            {"name": "E2E Creature Spell", "type_line": "Creature", "mana_cost": "{1}", "cmc": 1},
        ),
        "instant_or_sorcery_spell": (
            {"name": "E2E Sorcery Spell", "type_line": "Sorcery", "mana_cost": "{1}", "cmc": 1},
            {"name": "E2E Creature Spell", "type_line": "Creature", "mana_cost": "{1}", "cmc": 1},
        ),
        "noncreature_spell": (
            {"name": "E2E Noncreature Spell", "type_line": "Artifact", "mana_cost": "{1}", "cmc": 1},
            {"name": "E2E Creature Spell", "type_line": "Creature", "mana_cost": "{1}", "cmc": 1},
        ),
    }
    for restriction in conditional_restrictions:
        fixtures = restriction_fixture_cards.get(restriction)
        if fixtures:
            scenario["expected_restricted_mana_payable_card"] = fixtures[0]
            scenario["expected_restricted_mana_blocked_card"] = fixtures[1]
            break
    if activation_life_cost or activation_life_gain:
        scenario["starting_life"] = 40
        scenario["expected_life_after_refresh"] = 40 - activation_life_cost + activation_life_gain
    if activation_life_cost:
        scenario["expected_life_paid"] = activation_life_cost
    if activation_discard_count:
        scenario["expected_discard_count"] = activation_discard_count
        scenario["expected_discard_target"] = required.get("activation_discard_target") or "any_card"
    if activation_life_gain:
        scenario["expected_mana_activation_life_gain"] = activation_life_gain
    conditional_life_loss_by_color = _manifest_conditional_life_loss_by_color(
        required.get("produces"),
        int(required.get("life_for_colored_mana") or 0),
    )
    if conditional_life_loss_by_color:
        scenario["expected_conditional_life_loss_by_color"] = conditional_life_loss_by_color
    land_dependency_controller = str(required.get("land_mana_dependency_controller") or "")
    if land_dependency_controller in {"self", "opponent"}:
        lands, expected_colors = _manifest_land_color_dependency_lands(
            allows_colorless=bool(required.get("land_mana_dependency_allows_colorless"))
        )
        scenario["expected_conditional_colors"] = expected_colors
        if land_dependency_controller == "self":
            scenario["controller_lands"] = lands
        else:
            scenario["opponent_lands"] = lands
    return scenario


def _manifest_unlock_cost_for_mana_source(required: dict[str, Any]) -> str:
    symbols = [
        str(symbol or "").strip().upper()
        for symbol in (required.get("produced_mana_symbols") or [])
        if str(symbol or "").strip().upper() in {"W", "U", "B", "R", "G", "C"}
    ]
    if symbols:
        return "{1}" if symbols[0] == "C" else f"{{{symbols[0]}}}"
    produces = str(required.get("sacrifice_produces") or required.get("produces") or "").upper()
    for symbol in ("G", "W", "U", "B", "R"):
        if symbol in produces:
            return f"{{{symbol}}}"
    return "{1}"


def _manifest_sacrifice_cost_fixtures(
    base_name: str,
    sacrifice_cost: dict[str, Any] | None,
) -> list[dict[str, Any]]:
    if not isinstance(sacrifice_cost, dict):
        return []
    count = max(1, int(sacrifice_cost.get("count") or 1))
    constraints = dict(sacrifice_cost.get("constraints") or {})
    if constraints.get("target_subtypes") and not constraints.get("required_subtypes"):
        constraints["required_subtypes"] = list(constraints.get("target_subtypes") or [])
    if constraints.get("required_subtypes") and not constraints.get("card_types"):
        constraints["card_types"] = ["creature"]
    return [
        _target_fixture_from_constraints(
            f"{base_name} {index + 1}" if count > 1 else base_name,
            constraints,
            matching=True,
        )
        for index in range(count)
    ]


def _manifest_tap_cost_fixtures(
    base_name: str,
    tap_cost: dict[str, Any] | None,
) -> list[dict[str, Any]]:
    if not isinstance(tap_cost, dict):
        return []
    count = max(1, int(tap_cost.get("count") or 1))
    constraints = dict(tap_cost.get("constraints") or {})
    if constraints.get("target_subtypes") and not constraints.get("required_subtypes"):
        constraints["required_subtypes"] = list(constraints.get("target_subtypes") or [])
    if constraints.get("required_subtypes") and not constraints.get("card_types"):
        constraints["card_types"] = ["creature"]
    constraints.setdefault("tapped_state", "untapped")
    fixtures = [
        _target_fixture_from_constraints(
            f"{base_name} {index + 1}" if count > 1 else base_name,
            constraints,
            matching=True,
        )
        for index in range(count)
    ]
    for fixture in fixtures:
        fixture["tapped"] = False
    return fixtures


def _manifest_remove_counter_cost_fixture(
    base_name: str,
    remove_counter_cost: dict[str, Any] | None,
) -> tuple[dict[str, Any] | None, str | None, int]:
    if not isinstance(remove_counter_cost, dict):
        return None, None, 0
    count = max(1, int(remove_counter_cost.get("count") or 1))
    constraints = dict(remove_counter_cost.get("constraints") or {})
    counter_types = [
        str(value or "").strip().lower()
        for value in (remove_counter_cost.get("counter_types") or [])
        if str(value or "").strip()
    ]
    if not counter_types:
        return None, None, 0
    counter_type = "+1/+1" if "+1/+1" in counter_types or "any" in counter_types else counter_types[0]
    if constraints.get("target_subtypes") and not constraints.get("required_subtypes"):
        constraints["required_subtypes"] = list(constraints.get("target_subtypes") or [])
    if constraints.get("required_subtypes") and not constraints.get("card_types"):
        constraints["card_types"] = ["creature"]
    if counter_type in {"+1/+1", "-1/-1"} and constraints.get("card_types") == ["permanent"]:
        constraints["card_types"] = ["creature"]
    fixture = _target_fixture_from_constraints(
        base_name,
        constraints,
        matching=True,
    )
    counters = dict(fixture.get("counters") or {})
    if counter_type == "+1/+1":
        fixture["plus_one_counters"] = count
        counters["+1/+1"] = count
    elif counter_type == "-1/-1":
        fixture["minus_one_counters"] = count
        counters["-1/-1"] = count
    else:
        fixture[f"{counter_type}_counters"] = count
        counters[counter_type] = count
    fixture["counters"] = counters
    return fixture, counter_type, count


def sacrifice_mana_source_execution_scenario_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("effect") != "ramp_permanent" or not required.get("is_mana_source"):
        return None
    scope = str(required.get("battle_model_scope") or "")
    if scope not in {
        "xmage_self_sacrifice_mana_source_permanent_v1",
        "xmage_tap_and_self_sacrifice_mana_source_permanent_v1",
        "xmage_target_sacrifice_mana_source_permanent_v1",
    }:
        return None
    produced = int(required.get("sacrifice_mana_produced") or required.get("mana_produced") or 0)
    if produced <= 0:
        return None
    activation_cost = (
        required.get("sacrifice_activation_mana_cost")
        or required.get("activation_mana_cost")
    )
    controller_mana = _manifest_mana_for_activation_cost(activation_cost)
    unlock_cost = _manifest_unlock_cost_for_mana_source(required)
    target_sacrifice = bool(
        required.get("mana_activation_requires_sacrifice_target")
        or required.get("activation_requires_sacrifice_target")
        or required.get("activation_sacrifice_target")
    )
    scenario: dict[str, Any] = {
        "name": f"{rule['card_name']} activates contextual sacrifice mana source",
        "type": "sacrifice_mana_source_activation",
        "card": {"name": rule["card_name"]},
        "source_overrides": {
            "tapped": False,
            "summoning_sick": False,
        },
        "controller_mana": controller_mana,
        "unlock_card": {
            "name": "E2E Mana Unlock",
            "type_line": "Creature - Fixture",
            "effect": "creature",
            "cmc": max(1, produced),
            "mana_cost": unlock_cost,
        },
        "expected_available_mana_after_activation": produced,
        "expected_conditional_mana": (
            produced
            if _manifest_has_multiple_mana_choices(required.get("sacrifice_produces") or required.get("produces"))
            and not required.get("sacrifice_produced_mana_symbols")
            and not required.get("produced_mana_symbols")
            else 0
        ),
        "expected_event": (
            "target_sacrifice_mana_source_activated"
            if target_sacrifice
            else "self_sacrifice_mana_source_activated"
        ),
        "expected_produced": produced,
        "expect_source_sacrificed": not target_sacrifice,
        "expect_target_sacrificed": target_sacrifice,
        "logical_rule_key": rule["logical_rule_key"],
    }
    if target_sacrifice:
        scenario["sacrifice_target"] = {
            "name": "E2E Sacrifice Target",
            "type_line": "Creature - Fixture",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
        }
    return scenario


def simple_activated_damage_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_damage_v1":
        return None
    discard_target = str(required.get("activation_discard_target") or "any_card")
    discard_hand = []
    if int(required.get("activation_discard_count") or 0):
        if discard_target == "land_card":
            discard_hand = [
                {"name": "E2E Spare Mountain", "type_line": "Basic Land - Mountain", "effect": "land"},
                {"name": "E2E Nonland Spell", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        else:
            discard_hand = [
                {"name": "E2E Spare Card A", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
                {"name": "E2E Spare Card B", "type_line": "Instant", "effect": "direct_damage", "cmc": 1},
            ]
    scenario = {
        "name": f"{rule['card_name']} activates damage ability",
        "type": "simple_activated_damage",
        "card": {"name": rule["card_name"]},
        "opponent_life": 7,
        "starting_life": 40,
        "controller_mana": _manifest_mana_for_required_activation(required),
        "controller_hand": discard_hand,
        "expected_damage": int(required.get("activated_damage_amount") or required.get("amount") or 0),
        "expected_discard_count": int(required.get("activation_discard_count") or 0),
        "expected_discard_target": discard_target,
        "expected_discard_random": bool(required.get("activation_discard_random")),
        "expected_life_paid": int(required.get("activation_life_cost") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }
    tap_cost_targets = _manifest_tap_cost_fixtures(
        "E2E Activated Damage Tap Cost Target",
        required.get("activation_tap_cost") if isinstance(required.get("activation_tap_cost"), dict) else None,
    )
    if tap_cost_targets:
        scenario["tap_cost_targets"] = tap_cost_targets
        scenario["expected_tap_cost_count"] = len(tap_cost_targets)
    exile_top_library_count = int(required.get("activation_exile_top_library_count") or 0)
    if exile_top_library_count:
        scenario["controller_library"] = [
            {
                "name": f"E2E Activated Damage Exile Cost Card {index + 1}",
                "type_line": "Sorcery",
                "effect": "draw_cards",
                "cmc": 2,
            }
            for index in range(exile_top_library_count)
        ]
        scenario["expected_exiled_top_library_count"] = exile_top_library_count
    counter_cost_target, counter_type, counter_count = _manifest_remove_counter_cost_fixture(
        "E2E Activated Damage Counter Cost Target",
        required.get("activation_remove_counter_cost")
        if isinstance(required.get("activation_remove_counter_cost"), dict)
        else None,
    )
    if counter_cost_target:
        scenario["counter_cost_targets"] = [counter_cost_target]
        scenario["expected_remove_counter_cost_count"] = counter_count
        scenario["expected_remove_counter_type"] = counter_type
    target = str(required.get("target") or "").strip().lower()
    constraints = dict(required.get("target_constraints") or {})
    player_targets = {
        "any_target",
        "opponent",
        "opponent_or_planeswalker",
        "player",
        "player_or_planeswalker",
        "target_opponent",
        "target_player",
    }
    if str(constraints.get("scope") or "").strip().lower() != "any_target" and target not in player_targets:
        scenario["target"] = _target_fixture_from_constraints(
            "E2E Legal Activated Damage Target",
            constraints,
            matching=True,
        )
        scenario["expected_target"] = target or None
    return scenario


def simple_activated_draw_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_draw_v1":
        return None
    discard_count = int(required.get("activation_discard_count") or 0)
    sacrifice_target_type = str(required.get("activation_sacrifice_target") or "").strip().lower()
    controller_hand = []
    if discard_count:
        controller_hand = [
            {"name": "E2E Spare Draw Cost Card", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            {"name": "E2E Backup Draw Cost Card", "type_line": "Instant", "effect": "direct_damage", "cmc": 1},
        ]
    scenario: dict[str, Any] = {
        "name": f"{rule['card_name']} activates draw ability",
        "type": "simple_activated_draw",
        "card": {"name": rule["card_name"]},
        "controller_mana": _manifest_mana_for_required_activation(required),
        "controller_hand": controller_hand,
        "controller_library": [
            {"name": "E2E Activated Draw Card A", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            {"name": "E2E Activated Draw Card B", "type_line": "Instant", "effect": "direct_damage", "cmc": 1},
            {"name": "E2E Activated Draw Card C", "type_line": "Creature - Fixture", "effect": "creature", "cmc": 3},
            {"name": "E2E Activated Draw Card D", "type_line": "Artifact", "effect": "artifact", "cmc": 2},
        ],
        "expected_draw_count": int(required.get("activated_draw_count") or required.get("count") or 1),
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_discard_count": discard_count,
        "expected_discard_target": str(required.get("activation_discard_target") or "any_card"),
        "expected_life_paid": int(required.get("activation_life_cost") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }
    if required.get("activation_zone") == "graveyard":
        scenario["source_zone"] = "graveyard"
    if required.get("activation_requires_exile_source_from_graveyard"):
        scenario["source_zone"] = "graveyard"
        scenario["expected_exiled_source_from_graveyard"] = True
    if sacrifice_target_type:
        sacrifice_card_type = {
            "artifact": "artifact",
            "artifact_or_creature": "artifact",
            "artifact_or_land": "artifact",
            "creature": "creature",
            "creature_or_land": "creature",
            "land": "land",
            "nontoken_permanent": "artifact",
            "permanent": "artifact",
            "token": "creature",
        }.get(sacrifice_target_type, "creature")
        scenario["sacrifice_target"] = _target_fixture_from_constraints(
            "E2E Activated Draw Sacrifice Target",
            {
                "card_types": [sacrifice_card_type],
                **({"token": True} if sacrifice_target_type == "token" else {}),
            },
            matching=True,
        )
        scenario["expect_target_sacrificed"] = True
    tap_cost_targets = _manifest_tap_cost_fixtures(
        "E2E Activated Draw Tap Cost Target",
        required.get("activation_tap_cost") if isinstance(required.get("activation_tap_cost"), dict) else None,
    )
    if tap_cost_targets:
        scenario["tap_cost_targets"] = tap_cost_targets
        scenario["expected_tap_cost_count"] = len(tap_cost_targets)
    counter_cost_target, counter_type, counter_count = _manifest_remove_counter_cost_fixture(
        "E2E Activated Draw Counter Cost Target",
        required.get("activation_remove_counter_cost")
        if isinstance(required.get("activation_remove_counter_cost"), dict)
        else None,
    )
    if counter_cost_target:
        scenario["counter_cost_targets"] = [counter_cost_target]
        scenario["expected_remove_counter_cost_count"] = counter_count
        scenario["expected_remove_counter_type"] = counter_type
    return scenario


def simple_activated_draw_discard_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_draw_discard_v1":
        return None
    draw_count = int(required.get("activated_draw_count") or required.get("draw_count") or 1)
    discard_count = int(required.get("activated_discard_count") or required.get("discard_count") or 1)
    scenario: dict[str, Any] = {
        "name": f"{rule['card_name']} activates draw-discard ability",
        "type": "simple_activated_draw_discard",
        "card": {"name": rule["card_name"]},
        "controller_mana": _manifest_mana_for_required_activation(required),
        "controller_hand": [
            {"name": "E2E Activated Draw Discard Spare", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2}
        ],
        "controller_library": [
            {"name": "E2E Activated Draw Discard Card A", "type_line": "Instant", "effect": "direct_damage", "cmc": 1},
            {"name": "E2E Activated Draw Discard Card B", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            {"name": "E2E Activated Draw Discard Card C", "type_line": "Creature - Fixture", "effect": "creature", "cmc": 3},
        ],
        "expected_draw_count": draw_count,
        "expected_discard_count": discard_count,
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_life_paid": int(required.get("activation_life_cost") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }
    if required.get("activation_zone") == "graveyard":
        scenario["source_zone"] = "graveyard"
    if required.get("activation_requires_exile_source_from_graveyard"):
        scenario["source_zone"] = "graveyard"
        scenario["expected_exiled_source_from_graveyard"] = True
    return scenario


def target_player_draw_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_fixed_target_player_draw_spell_v1":
        return None
    draw_count_source = str(required.get("draw_count_source") or "").strip().lower()
    x_value = 0
    if draw_count_source == "x_value":
        x_value = int(required.get("x_value") or 3)
        expected_draw_count = x_value
    elif draw_count_source:
        return None
    else:
        expected_draw_count = int(required.get("draw_count") or required.get("count") or 1)
    return {
        "name": f"{rule['card_name']} target player draws cards",
        "type": "target_player_draw_spell",
        "card": {
            "name": rule["card_name"],
            "type_line": "Instant" if required.get("instant") else "Sorcery",
        },
        "controller_library": [
            {
                "name": f"E2E Target Player Draw Card {index + 1}",
                "type_line": "Instant" if index % 2 == 0 else "Sorcery",
                "effect": "draw_cards",
                "cmc": index + 1,
            }
            for index in range(max(expected_draw_count, 1))
        ],
        "expected_draw_count": expected_draw_count,
        "expected_target_player": "Spell Controller",
        "target_preference": str(required.get("target_preference") or "self"),
        **(
            {
                "expect_shuffle_self": True,
                "expected_spell_destination": "library",
            }
            if required.get("shuffle_self_into_library_on_resolution")
            else {}
        ),
        **({"x_value": x_value} if draw_count_source == "x_value" else {}),
        "logical_rule_key": rule["logical_rule_key"],
    }


def fixed_draw_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_fixed_source_controller_draw_spell_v1":
        return None
    expected_draw_count = int(required.get("draw_count") or required.get("count") or 0)
    if expected_draw_count <= 0:
        return None
    scenario: dict[str, Any] = {
        "name": f"{rule['card_name']} draws cards",
        "type": "fixed_draw_spell",
        "card": {
            "name": rule["card_name"],
            "type_line": "Instant" if required.get("instant") else "Sorcery",
        },
        "controller_library": [
            {
                "name": f"E2E Draw Card {index + 1}",
                "type_line": "Instant" if index % 2 == 0 else "Sorcery",
                "effect": "draw_cards",
                "cmc": index + 1,
            }
            for index in range(expected_draw_count)
        ],
        "expected_draw_count": expected_draw_count,
        "logical_rule_key": rule["logical_rule_key"],
    }
    if required.get("requires_sacrifice_creature_or_land"):
        scenario["controller_battlefield"] = [
            {
                "name": "E2E Sacrifice Cost Creature",
                "type_line": "Creature - Soldier",
                "effect": "creature",
                "power": 1,
                "toughness": 1,
            }
        ]
        scenario["expected_additional_cost"] = "sacrifice_creature_or_land"
        scenario["expected_sacrificed_names"] = ["E2E Sacrifice Cost Creature"]
    creature_count = int(required.get("requires_sacrifice_creature_count") or 0)
    if creature_count > 0:
        scenario["controller_battlefield"] = [
            {
                "name": f"E2E Sacrifice Cost Creature {index + 1}",
                "type_line": "Creature - Soldier",
                "effect": "creature",
                "power": 1,
                "toughness": 1,
            }
            for index in range(creature_count)
        ]
        scenario["expected_additional_cost"] = (
            "sacrifice_two_creatures" if creature_count == 2 else "sacrifice_creatures"
        )
        scenario["expected_sacrificed_names"] = [
            f"E2E Sacrifice Cost Creature {index + 1}"
            for index in range(creature_count)
        ]
    return scenario


def fixed_draw_discard_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_fixed_draw_discard_spell_v1":
        return None
    expected_draw_count = int(required.get("draw_count") or required.get("count") or 0)
    expected_discard_count = int(required.get("discard_count") or 0)
    if expected_draw_count <= 0 or expected_discard_count <= 0:
        return None
    controller_hand = [
        {
            "name": f"E2E Draw Discard Spare Card {index + 1}",
            "type_line": "Instant" if index % 2 == 0 else "Sorcery",
            "effect": "draw_cards",
            "cmc": index + 1,
        }
        for index in range(expected_discard_count)
    ]
    if required.get("discard_unless_status") == "runtime_executor_v1":
        expected_discard_count = int(required.get("discard_unless_count") or 1)
        if required.get("discard_unless_basic_land"):
            matching_card = {
                "name": "E2E Draw Discard Basic Land",
                "type_line": "Basic Land - Island",
                "cmc": 0,
            }
        else:
            card_type = str((required.get("discard_unless_card_types") or ["artifact"])[0])
            matching_card = {
                "name": f"E2E Draw Discard {card_type.title()} Card",
                "type_line": card_type.title(),
                "cmc": 1,
            }
        controller_hand = [matching_card] + controller_hand
    return {
        "name": f"{rule['card_name']} draws then discards",
        "type": "fixed_draw_discard_spell",
        "card": {
            "name": rule["card_name"],
            "type_line": "Instant" if required.get("instant") else "Sorcery",
        },
        "controller_library": [
            {
                "name": f"E2E Draw Discard Library Card {index + 1}",
                "type_line": "Instant" if index % 2 == 0 else "Sorcery",
                "effect": "draw_cards",
                "cmc": index + 1,
            }
            for index in range(expected_draw_count)
        ],
        "controller_hand": controller_hand,
        "expected_draw_count": expected_draw_count,
        "expected_discard_count": expected_discard_count,
        "expected_discard_random": bool(required.get("discard_random")),
        "expected_draw_discard_order": str(required.get("draw_discard_order") or "draw_then_discard"),
        "logical_rule_key": rule["logical_rule_key"],
    }


def combat_damage_draw_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_combat_damage_draw_cards_v1":
        return None
    draw_count = int(required.get("combat_damage_draw_count") or required.get("draw_count") or 1)
    optional_cost = str(required.get("combat_damage_draw_optional_cost") or "").strip()
    controller_hand = []
    if optional_cost == "discard_card":
        controller_hand = [
            {"name": "E2E Combat Draw Cost Card", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 4}
        ]
    card = {"name": rule["card_name"], "type_line": "Creature - E2E Fixture"}
    card.update(required)
    return {
        "name": f"{rule['card_name']} combat damage draw trigger",
        "type": "combat_damage_draw",
        "card": card,
        "controller_hand": controller_hand,
        "controller_library": [
            {
                "name": f"E2E Combat Draw Card {index + 1}",
                "type_line": "Instant",
                "effect": "draw_cards",
                "cmc": index + 1,
            }
            for index in range(max(draw_count, 1))
        ],
        "expected_draw_count": draw_count,
        "expected_optional_cost": optional_cost or None,
        "expected_discard_count": 1 if optional_cost == "discard_card" else 0,
        "expected_source_sacrificed": optional_cost == "sacrifice_source",
        "logical_rule_key": rule["logical_rule_key"],
    }


def beginning_end_step_draw_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_beginning_end_step_conditional_draw_v1":
        return None
    draw_count = int(required.get("end_step_draw_count") or 0)
    if draw_count <= 0:
        return None
    condition = str(required.get("end_step_draw_condition") or "").strip()
    if not condition:
        return None
    permanent_type = str(required.get("effect") or "draw_engine")
    type_line = {
        "creature": "Creature - E2E Fixture",
        "artifact": "Artifact",
        "enchantment": "Enchantment",
    }.get(permanent_type, "Enchantment")
    return {
        "name": f"{rule['card_name']} beginning end step conditional draw",
        "type": "beginning_end_step_draw",
        "card": {
            "name": rule["card_name"],
            "type_line": type_line,
            "effect": permanent_type,
            **required,
        },
        "controller_library": [
            {
                "name": f"E2E End Step Draw Card {index + 1}",
                "type_line": "Instant",
                "effect": "draw_cards",
                "cmc": index + 1,
            }
            for index in range(draw_count)
        ],
        "trigger": str(required.get("trigger") or "controller_end_step"),
        "expected_trigger": str(required.get("trigger") or "controller_end_step"),
        "expected_draw_count": draw_count,
        "expected_condition": condition,
        "expected_threshold": int(required.get("end_step_draw_condition_threshold") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }


def damage_each_opponent_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "spell_damage_each_opponent_v1":
        return None
    return {
        "name": f"{rule['card_name']} damages each opponent",
        "type": "damage_each_opponent_spell",
        "card": {
            "name": rule["card_name"],
            "type_line": "Instant" if required.get("instant") else "Sorcery",
        },
        "opponent_life": 9,
        "second_opponent_life": 11,
        "expected_damage": int(required.get("damage") or required.get("amount") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }


def damage_each_opponent_and_their_permanents_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if (
        required.get("battle_model_scope")
        != "xmage_damage_each_opponent_and_their_permanents_spell_v1"
    ):
        return None
    damage_scope = str(required.get("damage_scope") or "")
    if damage_scope not in {
        "each_creature_opponents_control",
        "each_creature_and_planeswalker_opponents_control",
    }:
        return None
    return {
        "name": f"{rule['card_name']} damages opponents and their permanents",
        "type": "damage_each_opponent_and_their_permanents_spell",
        "card": {
            "name": rule["card_name"],
            "type_line": "Instant" if required.get("instant") else "Sorcery",
        },
        "opponent_life": 9,
        "second_opponent_life": 11,
        "expected_damage": int(required.get("damage") or required.get("amount") or 0),
        "expected_damage_scope": damage_scope,
        "expected_planeswalker_damage": damage_scope == "each_creature_and_planeswalker_opponents_control",
        "logical_rule_key": rule["logical_rule_key"],
    }


def damage_gain_life_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_fixed_damage_target_and_controller_gain_life_spell_v1":
        return None
    damage = int(required.get("amount") or required.get("damage") or 0)
    life_gain = int(required.get("controller_gain_life") or required.get("gain_life") or 0)
    if damage <= 0 or life_gain <= 0:
        return None
    type_line = "Sorcery" if required.get("sorcery") is True else "Instant"
    target_constraints = dict(required.get("target_constraints") or {})
    target = _target_fixture_from_constraints(
        "E2E Damage Gain Legal Target",
        target_constraints,
        matching=True,
    )
    if target_constraints.get("scope") in {"player", "player_or_planeswalker", "opponent", "opponent_or_planeswalker"}:
        target = None
    return {
        "name": f"{rule['card_name']} deals damage and gains life",
        "type": "damage_gain_life_spell",
        "card": {"name": rule["card_name"], "type_line": type_line},
        "target": target,
        "expected_damage": damage,
        "expected_life_gain": life_gain,
        "expected_target": required.get("target"),
        "expected_target_constraints": target_constraints,
        "controller_life": 10,
        "opponent_life": max(20, damage + 5),
        **(
            {
                "expect_shuffle_self": True,
                "expected_spell_destination": "library",
            }
            if required.get("shuffle_self_into_library_on_resolution")
            else {}
        ),
        "logical_rule_key": rule["logical_rule_key"],
    }


def fixed_damage_target_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_fixed_damage_target_spell_v1":
        return None
    damage = int(required.get("amount") or required.get("damage") or 0)
    if damage <= 0:
        return None
    type_line = "Sorcery" if required.get("sorcery") is True else "Instant"
    target_constraints = dict(required.get("target_constraints") or {})
    target = _target_fixture_from_constraints(
        "E2E Fixed Damage Legal Target",
        target_constraints,
        matching=True,
    )
    nonmatching_target = _target_fixture_from_constraints(
        "E2E Fixed Damage Illegal Target",
        target_constraints,
        matching=False,
    )
    if target_constraints.get("scope") in {"player", "player_or_planeswalker", "opponent", "opponent_or_planeswalker"}:
        target = None
        nonmatching_target = None
    scenario = {
        "name": f"{rule['card_name']} deals fixed target damage",
        "type": "fixed_damage_target_spell",
        "card": {"name": rule["card_name"], "type_line": type_line},
        "target": target,
        "nonmatching_target": nonmatching_target,
        "expected_damage": damage,
        "expected_life_gain": 0,
        "expected_cant_be_countered": bool(required.get("cant_be_countered")),
        "expected_target": required.get("target"),
        "expected_target_constraints": target_constraints,
        "controller_life": 10,
        "opponent_life": max(20, damage + 5),
        **(
            {
                "expect_shuffle_self": True,
                "expected_spell_destination": "library",
            }
            if required.get("shuffle_self_into_library_on_resolution")
            else {}
        ),
        "logical_rule_key": rule["logical_rule_key"],
    }
    if required.get("requires_return_land_to_hand"):
        scenario["controller_battlefield"] = [
            {
                "name": "E2E Return Cost Land",
                "type_line": "Basic Land - Mountain",
                "effect": "land",
                "tapped": True,
            }
        ]
        scenario["expected_additional_cost"] = "return_land_to_hand"
        scenario["expected_returned_land_name"] = "E2E Return Cost Land"
    if required.get("requires_sacrifice_creature_or_enchantment"):
        scenario["controller_battlefield"] = [
            *scenario.get("controller_battlefield", []),
            {
                "name": "E2E Sacrifice Cost Enchantment",
                "type_line": "Enchantment",
                "effect": "enchantment",
            },
        ]
        scenario["expected_additional_cost"] = "sacrifice_creature_or_enchantment"
        scenario["expected_sacrificed_name"] = "E2E Sacrifice Cost Enchantment"
    if required.get("requires_sacrifice_creature_or_planeswalker"):
        scenario["controller_battlefield"] = [
            *scenario.get("controller_battlefield", []),
            {
                "name": "E2E Sacrifice Cost Planeswalker",
                "type_line": "Planeswalker",
                "effect": "planeswalker",
                "loyalty": 3,
            },
        ]
        scenario["expected_additional_cost"] = "sacrifice_creature_or_planeswalker"
        scenario["expected_sacrificed_name"] = "E2E Sacrifice Cost Planeswalker"
    return scenario


def damage_target_create_treasure_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_fixed_damage_target_create_treasure_spell_v1":
        return None
    damage = int(required.get("amount") or required.get("damage") or 0)
    if damage <= 0:
        return None
    target_constraints = dict(required.get("target_constraints") or {})
    target = _target_fixture_from_constraints(
        "E2E Damage Treasure Legal Target",
        target_constraints,
        matching=True,
    )
    nonmatching_target = _target_fixture_from_constraints(
        "E2E Damage Treasure Illegal Target",
        target_constraints,
        matching=False,
    )
    if target_constraints.get("scope") in {"player", "player_or_planeswalker", "opponent", "opponent_or_planeswalker"}:
        target = None
        nonmatching_target = None
    return {
        "name": f"{rule['card_name']} deals fixed target damage and creates Treasure",
        "type": "damage_target_create_treasure",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "target": target,
        "nonmatching_target": nonmatching_target,
        "expected_damage": damage,
        "expected_life_gain": 0,
        "expected_treasure_count": int(
            required.get("controller_treasure_tokens")
            or required.get("treasure_count")
            or 1
        ),
        "expected_target": required.get("target"),
        "expected_target_constraints": target_constraints,
        "controller_life": 10,
        "opponent_life": max(20, damage + 5),
        "logical_rule_key": rule["logical_rule_key"],
    }


def simple_activated_tap_target_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_tap_target_v1":
        return None
    target = required.get("activated_tap_target") or required.get("target") or "creature"
    constraints = dict(required.get("target_constraints") or {})
    if not constraints.get("card_types"):
        if str(target) == "artifact_creature_or_land":
            constraints["card_types"] = ["artifact", "creature", "land"]
        elif str(target) == "artifact_or_creature":
            constraints["card_types"] = ["artifact", "creature"]
    target_fixture = _target_fixture_from_constraints(
        "E2E Legal Tap Target",
        constraints or {"card_types": ["creature"]},
        matching=True,
    )
    return {
        "name": f"{rule['card_name']} activates tap target ability",
        "type": "simple_activated_tap_target",
        "card": {"name": rule["card_name"]},
        "controller_mana": _manifest_mana_for_required_activation(required),
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_target": target,
        "target": target_fixture,
        "logical_rule_key": rule["logical_rule_key"],
    }


def simple_activated_untap_target_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_untap_target_v1":
        return None
    target = required.get("activated_untap_target") or required.get("target") or "permanent"
    constraints = dict(required.get("target_constraints") or {})
    if not constraints.get("card_types"):
        if str(target) == "artifact_creature":
            constraints["card_types"] = ["artifact", "creature"]
            constraints["all_card_types_required"] = True
        else:
            constraints["card_types"] = ["creature"] if str(target) == "creature" else [str(target)]
    target_count = max(
        1,
        min(
            3,
            int(
                required.get("target_count_max")
                or required.get("target_count")
                or 1
            ),
        ),
    )
    targets = []
    for index in range(1, target_count + 1):
        fixture = _target_fixture_from_constraints(
            f"E2E Legal Untap Target {index}",
            constraints,
            matching=True,
        )
        fixture["tapped"] = True
        targets.append(fixture)
    nonmatching = _target_fixture_from_constraints(
        "E2E Illegal Untap Target",
        constraints,
        matching=False,
    )
    nonmatching["tapped"] = True
    return {
        "name": f"{rule['card_name']} activates untap target ability",
        "type": "simple_activated_untap_target",
        "card": {"name": rule["card_name"]},
        "controller_mana": _manifest_mana_for_required_activation(required),
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_target": target,
        "expected_target_count": target_count,
        "targets": targets,
        "nonmatching_target": nonmatching,
        "logical_rule_key": rule["logical_rule_key"],
    }


def tap_target_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_tap_target_spell_v1":
        return None
    target = required.get("target") or "permanent"
    constraints = dict(required.get("target_constraints") or {})
    if not constraints:
        constraints = {"card_types": ["creature"] if target == "creature" else [target]}
    if required.get("target_count_from_x") or required.get("target_count_source") == "x_value":
        target_count = 2
    else:
        target_count = int(
            required.get("target_count_max")
            or required.get("max_targets")
            or required.get("target_count")
            or 1
        )
    target_count = max(1, min(target_count, 3))
    targets = []
    for index in range(1, target_count + 1):
        fixture = _target_fixture_from_constraints(
            f"E2E Legal Tap Spell Target {index}",
            constraints,
            matching=True,
        )
        fixture["tapped"] = False
        targets.append(fixture)
    nonmatching = _target_fixture_from_constraints(
        "E2E Illegal Tap Spell Target",
        constraints,
        matching=False,
    )
    nonmatching["tapped"] = False
    return {
        "name": f"{rule['card_name']} taps target permanents",
        "type": "tap_target_spell",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "target": target,
        "targets": targets,
        "nonmatching_target": nonmatching,
        "expected_target_count": target_count,
        "expected_target_constraints": constraints,
        "x_value": target_count if required.get("target_count_from_x") else None,
        "logical_rule_key": rule["logical_rule_key"],
    }


def boost_untap_target_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1",
        "xmage_fixed_boost_keyword_and_untap_target_creature_until_eot_spell_v1",
    }:
        return None
    if required.get("effect") != "stat_modifier_until_eot_untap_target":
        return None
    constraints = dict(required.get("target_constraints") or {"card_types": ["creature"]})
    target_count = int(
        required.get("target_count_max")
        or required.get("max_targets")
        or required.get("target_count")
        or 1
    )
    target_count = max(1, min(target_count, 3))
    targets = []
    for index in range(1, target_count + 1):
        fixture = _target_fixture_from_constraints(
            f"E2E Legal Boost Untap Target {index}",
            constraints,
            matching=True,
        )
        fixture["tapped"] = True
        fixture.setdefault("power", 2)
        fixture.setdefault("toughness", 2)
        targets.append(fixture)
    nonmatching = _target_fixture_from_constraints(
        "E2E Illegal Boost Untap Target",
        constraints,
        matching=False,
    )
    nonmatching["tapped"] = True
    return {
        "name": f"{rule['card_name']} boosts and untaps target creatures",
        "type": "stat_modifier_until_eot_untap_target",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "targets": targets,
        "nonmatching_target": nonmatching,
        "expected_power_delta": int(required.get("power_delta") or required.get("power_boost") or 0),
        "expected_toughness_delta": int(required.get("toughness_delta") or required.get("toughness_boost") or 0),
        "expected_keywords": list(required.get("granted_keywords_until_eot") or []),
        "expected_target_count": target_count,
        "expected_target_constraints": constraints,
        "logical_rule_key": rule["logical_rule_key"],
    }


def add_counters_target_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_fixed_add_counters_target_creature_spell_v1",
        "xmage_fixed_add_counters_target_creatures_spell_v1",
    }:
        return None
    if required.get("effect") != "add_counters" or required.get("untap_target"):
        return None
    constraints = dict(required.get("target_constraints") or {"card_types": ["creature"]})
    target_count = max(
        1,
        int(required.get("target_count_max") or required.get("target_count") or 1),
    )
    targets = []
    for index in range(target_count):
        target = _target_fixture_from_constraints(
            f"E2E Legal Counter Target {index + 1}",
            constraints,
            matching=True,
        )
        target.setdefault("power", 2 + index)
        target.setdefault("toughness", 2 + index)
        targets.append(target)
    nonmatching = _target_fixture_from_constraints(
        "E2E Illegal Counter Target",
        constraints,
        matching=False,
    )
    return {
        "name": f"{rule['card_name']} adds counters to target creature spell",
        "type": "add_counters_target_spell",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "target": targets[0],
        "targets": targets,
        "nonmatching_target": nonmatching,
        "expected_target_constraints": constraints,
        "expected_target_count": target_count,
        "expected_counter_type": required.get("counter_type"),
        "expected_counter_count": int(
            required.get("counter_count")
            or required.get("count")
            or 1
        ),
        "logical_rule_key": rule["logical_rule_key"],
    }


def add_counters_untap_target_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_fixed_add_counters_and_untap_target_creature_spell_v1",
        "xmage_fixed_add_counters_and_untap_target_creatures_spell_v1",
    }:
        return None
    if required.get("effect") != "add_counters" or not required.get("untap_target"):
        return None
    constraints = dict(required.get("target_constraints") or {"card_types": ["creature"]})
    target_count = max(
        1,
        int(required.get("target_count_max") or required.get("target_count") or 1),
    )
    targets = []
    for index in range(target_count):
        target = _target_fixture_from_constraints(
            f"E2E Legal Counter Untap Target {index + 1}",
            constraints,
            matching=True,
        )
        target["tapped"] = True
        target.setdefault("power", 2 + index)
        target.setdefault("toughness", 2 + index)
        targets.append(target)
    nonmatching = _target_fixture_from_constraints(
        "E2E Illegal Counter Untap Target",
        constraints,
        matching=False,
    )
    nonmatching["tapped"] = True
    return {
        "name": f"{rule['card_name']} adds counters and untaps target creature",
        "type": "add_counters_untap_target_spell",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "target": targets[0],
        "targets": targets,
        "nonmatching_target": nonmatching,
        "expected_target_constraints": constraints,
        "expected_target_count": target_count,
        "expected_counter_type": required.get("counter_type"),
        "expected_counter_count": int(
            required.get("counter_count")
            or required.get("count")
            or 1
        ),
        "expected_untap_target": True,
        "logical_rule_key": rule["logical_rule_key"],
    }


def gain_control_untap_haste_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_gain_control_untap_haste_until_eot_spell_v1":
        return None
    if required.get("effect") != "gain_control_untap_haste_until_eot":
        return None
    constraints = dict(required.get("target_constraints") or {"card_types": ["creature"]})
    target = _target_fixture_from_constraints(
        "E2E Legal Temporary Control Target",
        constraints,
        matching=True,
    )
    target["tapped"] = True
    target.setdefault("power", 3)
    target.setdefault("toughness", 3)
    nonmatching = _target_fixture_from_constraints(
        "E2E Illegal Temporary Control Target",
        constraints,
        matching=False,
    )
    nonmatching["tapped"] = True
    return {
        "name": f"{rule['card_name']} gains temporary control",
        "type": "gain_control_untap_haste_until_eot",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "target": target,
        "nonmatching_target": nonmatching,
        "expected_target_constraints": constraints,
        "expected_granted_keywords": list(required.get("granted_keywords_until_eot") or ["haste"]),
        "expected_control_duration": required.get("control_duration") or "until_end_of_turn",
        "logical_rule_key": rule["logical_rule_key"],
    }


def simple_activated_add_counters_target_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_add_counters_target_creature_v1":
        return None
    target = required.get("activated_add_counters_target") or required.get("target") or "creature"
    constraints = dict(required.get("target_constraints") or {"card_types": ["creature"]})
    target_fixture = _target_fixture_from_constraints(
        "E2E Legal Counter Target",
        constraints,
        matching=True,
    )
    discard_count = max(0, int(required.get("activation_discard_count") or 0))
    discard_target = str(required.get("activation_discard_target") or "any_card")
    controller_hand = []
    if discard_count:
        if discard_target == "land_card":
            controller_hand = [
                {"name": "E2E Counter Cost Mountain", "type_line": "Basic Land - Mountain", "effect": "land"},
                {"name": "E2E Counter Cost Nonland", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        elif discard_target == "artifact_card":
            controller_hand = [
                {"name": "E2E Counter Cost Bauble", "type_line": "Artifact", "effect": "mana_source", "cmc": 1},
                {"name": "E2E Counter Cost Nonartifact", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        else:
            controller_hand = [
                {
                    "name": f"E2E Counter Cost Discard {index + 1}",
                    "type_line": "Instant",
                    "effect": "draw_cards",
                    "cmc": 2,
                }
                for index in range(discard_count)
            ]
    scenario = {
        "name": f"{rule['card_name']} activates add counters ability",
        "type": "simple_activated_add_counters_target",
        "card": {"name": rule["card_name"]},
        "controller_mana": _manifest_mana_for_required_activation(required),
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_sacrificed_source": bool(required.get("activation_requires_sacrifice")),
        "expected_target": target,
        "expected_counter_type": required.get("activated_add_counters_counter_type") or required.get("counter_type"),
        "expected_counter_count": int(
            required.get("activated_add_counters_count")
            or required.get("counter_count")
            or required.get("count")
            or 1
        ),
        "target": target_fixture,
        "starting_life": 40,
        "expected_discard_count": discard_count,
        "expected_discard_target": discard_target,
        "expected_life_paid": int(required.get("activation_life_cost") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }
    if controller_hand:
        scenario["controller_hand"] = controller_hand
    sacrifice_targets = _manifest_sacrifice_cost_fixtures(
        "E2E Counter Sacrifice Target",
        required.get("activation_sacrifice_cost") if isinstance(required.get("activation_sacrifice_cost"), dict) else None,
    )
    if sacrifice_targets:
        scenario["sacrifice_targets"] = sacrifice_targets
        scenario["expected_sacrifice_count"] = len(sacrifice_targets)
    return scenario


def simple_activated_add_counters_self_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_self_add_counters_v1":
        return None
    discard_count = max(0, int(required.get("activation_discard_count") or 0))
    discard_target = str(required.get("activation_discard_target") or "any_card")
    controller_hand = []
    if discard_count:
        if discard_target == "land_card":
            controller_hand = [
                {"name": "E2E Self Counter Cost Mountain", "type_line": "Basic Land - Mountain", "effect": "land"},
                {"name": "E2E Self Counter Cost Nonland", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        elif discard_target == "artifact_card":
            controller_hand = [
                {"name": "E2E Self Counter Cost Bauble", "type_line": "Artifact", "effect": "mana_source", "cmc": 1},
                {"name": "E2E Self Counter Cost Nonartifact", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        else:
            controller_hand = [
                {
                    "name": f"E2E Self Counter Cost Discard {index + 1}",
                    "type_line": "Instant",
                    "effect": "draw_cards",
                    "cmc": 2,
                }
                for index in range(discard_count)
            ]
    scenario = {
        "name": f"{rule['card_name']} activates self add counters ability",
        "type": "simple_activated_add_counters_self",
        "card": {"name": rule["card_name"]},
        "controller_mana": _manifest_mana_for_required_activation(required),
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_counter_type": required.get("activated_add_counters_counter_type") or required.get("counter_type"),
        "expected_counter_count": int(
            required.get("activated_add_counters_count")
            or required.get("counter_count")
            or required.get("count")
            or 1
        ),
        "starting_life": 40,
        "expected_discard_count": discard_count,
        "expected_discard_target": discard_target,
        "expected_life_paid": int(required.get("activation_life_cost") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }
    if controller_hand:
        scenario["controller_hand"] = controller_hand
    sacrifice_targets = _manifest_sacrifice_cost_fixtures(
        "E2E Self Counter Sacrifice Target",
        required.get("activation_sacrifice_cost") if isinstance(required.get("activation_sacrifice_cost"), dict) else None,
    )
    if sacrifice_targets:
        scenario["sacrifice_targets"] = sacrifice_targets
        scenario["expected_sacrifice_count"] = len(sacrifice_targets)
    return scenario


def simple_activated_destroy_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_destroy_target_v1":
        return None
    constraints = dict(required.get("target_constraints") or {})
    fixture_constraints = dict(constraints)
    if fixture_constraints.get("card_types_any") and not fixture_constraints.get("card_types"):
        first_type = str((fixture_constraints.get("card_types_any") or ["artifact"])[0]).strip().lower()
        fixture_constraints["card_types"] = [first_type]
    scenario = {
        "name": f"{rule['card_name']} activates destroy ability",
        "type": "simple_activated_destroy",
        "card": {"name": rule["card_name"]},
        "target": _target_fixture_from_constraints(
            "E2E Legal Activated Destroy Target",
            fixture_constraints,
            matching=True,
        ),
        "controller_mana": _manifest_mana_for_required_activation(required),
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_sacrificed_source": bool(required.get("activation_requires_sacrifice")),
        "expected_destination": str(required.get("destination") or "graveyard").lower(),
        "expected_target": required.get("activated_remove_target") or required.get("target"),
        "expected_target_constraints": constraints,
        "logical_rule_key": rule["logical_rule_key"],
    }
    discard_count = max(0, int(required.get("activation_discard_count") or 0))
    if discard_count:
        scenario["controller_hand"] = [
            {
                "name": f"E2E Activated Destroy Discard {index + 1}",
                "type_line": "Instant",
                "effect": "draw_cards",
                "cmc": 2,
            }
            for index in range(discard_count)
        ]
        scenario["expected_discard_count"] = discard_count
        scenario["expected_discard_target"] = required.get("activation_discard_target") or "any_card"
    sacrifice_targets = _manifest_sacrifice_cost_fixtures(
        "E2E Activated Destroy Sacrifice Target",
        required.get("activation_sacrifice_cost") if isinstance(required.get("activation_sacrifice_cost"), dict) else None,
    )
    sacrifice_target_type = str(required.get("activation_sacrifice_target") or "").strip().lower()
    if sacrifice_targets:
        scenario["sacrifice_targets"] = sacrifice_targets
        scenario["sacrifice_target"] = sacrifice_targets[0]
        scenario["expected_sacrifice_count"] = len(sacrifice_targets)
        scenario["expect_target_sacrificed"] = True
    elif required.get("activation_requires_sacrifice_target") or sacrifice_target_type:
        sacrifice_card_type = "creature" if sacrifice_target_type == "creature" else "permanent"
        scenario["sacrifice_target"] = _target_fixture_from_constraints(
            "E2E Activated Destroy Sacrifice Target",
            {"card_types": [sacrifice_card_type]},
            matching=True,
        )
        scenario["expect_target_sacrificed"] = True
    tap_cost_targets = _manifest_tap_cost_fixtures(
        "E2E Activated Destroy Tap Cost Target",
        required.get("activation_tap_cost") if isinstance(required.get("activation_tap_cost"), dict) else None,
    )
    if tap_cost_targets:
        scenario["tap_cost_targets"] = tap_cost_targets
        scenario["expected_tap_cost_count"] = len(tap_cost_targets)
    return scenario


def simple_activated_self_keyword_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_self_keyword_until_eot_v1":
        return None
    discard_target = str(required.get("activation_discard_target") or "any_card")
    discard_hand = []
    if int(required.get("activation_discard_count") or 0):
        if discard_target == "land_card":
            discard_hand = [
                {"name": "E2E Spare Mountain", "type_line": "Basic Land - Mountain", "effect": "land"},
                {"name": "E2E Nonland Spell", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        else:
            discard_hand = [
                {"name": "E2E Spare Card A", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
                {"name": "E2E Spare Card B", "type_line": "Instant", "effect": "direct_damage", "cmc": 1},
            ]
    return {
        "name": f"{rule['card_name']} activates self keyword ability",
        "type": "simple_activated_self_keyword",
        "card": {"name": rule["card_name"]},
        "controller_mana": _manifest_mana_for_required_activation(required),
        "controller_hand": discard_hand,
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_keywords": list(required.get("granted_keywords_until_eot") or []),
        "expected_discard_count": int(required.get("activation_discard_count") or 0),
        "expected_life_paid": int(required.get("activation_life_cost") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }


def simple_activated_self_boost_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_self_boost_until_eot_v1":
        return None
    discard_target = str(required.get("activation_discard_target") or "any_card")
    discard_hand = []
    if int(required.get("activation_discard_count") or 0):
        if discard_target == "land_card":
            discard_hand = [
                {"name": "E2E Spare Mountain", "type_line": "Basic Land - Mountain", "effect": "land"},
                {"name": "E2E Nonland Spell", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        elif discard_target == "artifact_card":
            discard_hand = [
                {"name": "E2E Spare Bauble", "type_line": "Artifact", "effect": "mana_source", "cmc": 1},
                {"name": "E2E Nonartifact Spell", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        else:
            discard_hand = [
                {"name": "E2E Spare Card A", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
                {"name": "E2E Spare Card B", "type_line": "Instant", "effect": "direct_damage", "cmc": 1},
            ]
    power_delta = int(required.get("power_delta") or required.get("power_boost") or 0)
    toughness_delta = int(required.get("toughness_delta") or required.get("toughness_boost") or 0)
    source_power = max(2, 1 + abs(min(0, power_delta)))
    source_toughness = max(2, 1 + abs(min(0, toughness_delta)))
    return {
        "name": f"{rule['card_name']} activates self boost ability",
        "type": "simple_activated_self_boost",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature - Soldier",
            "power": source_power,
            "toughness": source_toughness,
        },
        "controller_mana": _manifest_mana_for_required_activation(required),
        "controller_hand": discard_hand,
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_power_delta": power_delta,
        "expected_toughness_delta": toughness_delta,
        "expected_discard_count": int(required.get("activation_discard_count") or 0),
        "expected_life_paid": int(required.get("activation_life_cost") or 0),
        "expected_activation_limit_per_turn": int(required.get("activation_limit_per_turn") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }


def simple_activated_regenerate_source_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_regenerate_source_v1":
        return None
    discard_target = str(required.get("activation_discard_target") or "any_card")
    discard_hand = []
    if int(required.get("activation_discard_count") or 0):
        if discard_target == "land_card":
            discard_hand = [
                {"name": "E2E Spare Forest", "type_line": "Basic Land - Forest", "effect": "land"},
                {"name": "E2E Nonland Spell", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        elif discard_target == "artifact_card":
            discard_hand = [
                {"name": "E2E Spare Relic", "type_line": "Artifact", "effect": "mana_source", "cmc": 1},
                {"name": "E2E Nonartifact Spell", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        else:
            discard_hand = [
                {"name": "E2E Spare Card A", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
                {"name": "E2E Spare Card B", "type_line": "Instant", "effect": "direct_damage", "cmc": 1},
            ]
    return {
        "name": f"{rule['card_name']} activates regenerate source ability",
        "type": "simple_activated_regenerate_source",
        "card": {"name": rule["card_name"]},
        "controller_mana": _manifest_mana_for_required_activation(required),
        "controller_hand": discard_hand,
        "starting_life": 40,
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_regeneration_shields": 1,
        "expected_discard_count": int(required.get("activation_discard_count") or 0),
        "expected_discard_target": discard_target,
        "expected_life_paid": int(required.get("activation_life_cost") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }


def simple_activated_regenerate_target_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_regenerate_target_v1":
        return None
    discard_target = str(required.get("activation_discard_target") or "any_card")
    discard_hand = []
    if int(required.get("activation_discard_count") or 0):
        if discard_target == "land_card":
            discard_hand = [
                {"name": "E2E Spare Forest", "type_line": "Basic Land - Forest", "effect": "land"},
                {"name": "E2E Nonland Spell", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        elif discard_target == "artifact_card":
            discard_hand = [
                {"name": "E2E Spare Relic", "type_line": "Artifact", "effect": "mana_source", "cmc": 1},
                {"name": "E2E Nonartifact Spell", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
            ]
        else:
            discard_hand = [
                {"name": "E2E Spare Card A", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
                {"name": "E2E Spare Card B", "type_line": "Instant", "effect": "direct_damage", "cmc": 1},
            ]
    return {
        "name": f"{rule['card_name']} activates regenerate target ability",
        "type": "simple_activated_regenerate_target",
        "card": {
            "name": rule["card_name"],
            "type_line": required.get("source_type_line") or "Artifact",
            "effect": required.get("effect") or "artifact",
        },
        "target": {
            "name": "E2E Protected Creature",
            "type_line": "Creature - Bear",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
        },
        "controller_mana": _manifest_mana_for_required_activation(required),
        "controller_hand": discard_hand,
        "starting_life": 40,
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_regeneration_shields": 1,
        "expected_discard_count": int(required.get("activation_discard_count") or 0),
        "expected_discard_target": discard_target,
        "expected_life_paid": int(required.get("activation_life_cost") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }


def simple_activated_target_keyword_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_target_keyword_until_eot_v1":
        return None
    constraints = dict(required.get("target_constraints") or {})
    if not constraints.get("card_types"):
        target_type = str(required.get("target") or "creature").strip().lower()
        constraints["card_types"] = [target_type if target_type else "creature"]
    target = _target_fixture_from_constraints(
        "E2E Target Keyword Legal Target",
        constraints,
        matching=True,
    )
    target["cmc"] = max(int(target.get("cmc") or 0), 5)
    scenario: dict[str, Any] = {
        "name": f"{rule['card_name']} activates target keyword ability",
        "type": "simple_activated_target_keyword",
        "card": {"name": rule["card_name"]},
        "target": target,
        "controller_mana": _manifest_mana_for_required_activation(required),
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_sacrificed_source": bool(required.get("activation_requires_sacrifice")),
        "expected_keywords": list(required.get("granted_keywords_until_eot") or []),
        "expected_target": required.get("target") or "creature",
        "expected_target_constraints": constraints,
        "logical_rule_key": rule["logical_rule_key"],
    }
    sacrifice_target_type = str(required.get("activation_sacrifice_target") or "").strip().lower()
    if required.get("activation_requires_sacrifice_target") or sacrifice_target_type:
        sacrifice_card_type = {
            "artifact": "artifact",
            "artifact_or_creature": "artifact",
            "artifact_or_land": "artifact",
            "creature": "creature",
            "creature_or_land": "creature",
            "enchantment": "enchantment",
            "land": "land",
            "permanent": "artifact",
        }.get(sacrifice_target_type, "artifact")
        sacrifice_target = _target_fixture_from_constraints(
            "E2E Target Keyword Sacrifice Cost",
            {"card_types": [sacrifice_card_type]},
            matching=True,
        )
        sacrifice_target["cmc"] = 0
        scenario["sacrifice_target"] = sacrifice_target
        scenario["expect_target_sacrificed"] = True
    return scenario


def target_keyword_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_fixed_keyword_target_creature_until_eot_spell_v1",
        "xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1",
        "xmage_fixed_boost_target_creature_until_eot_spell_v1",
    }:
        return None
    type_line = "Sorcery" if required.get("sorcery") is True else "Instant"
    target_count = max(
        1,
        int(required.get("target_count_max") or required.get("target_count") or 1),
    )
    scenario = {
        "name": f"{rule['card_name']} grants target keyword until EOT",
        "type": "stat_modifier_until_eot",
        "card": {"name": rule["card_name"], "type_line": type_line},
        "target": {
            "name": "E2E Target Creature",
            "type_line": "Creature - Soldier",
            "power": 2,
            "toughness": 2,
        },
        "expected_power_delta": int(required.get("power_delta") or 0),
        "expected_toughness_delta": int(required.get("toughness_delta") or 0),
        "expected_keywords": list(required.get("granted_keywords_until_eot") or []),
        "expected_target_count": target_count,
        "logical_rule_key": rule["logical_rule_key"],
    }
    if target_count > 1:
        scenario["targets"] = [
            {
                "name": f"E2E Target Creature {index}",
                "type_line": "Creature - Soldier",
                "power": 2,
                "toughness": 2,
            }
            for index in range(1, target_count + 1)
        ]
    return scenario


def target_keyword_draw_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1",
        "xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1",
        "xmage_fixed_boost_keyword_target_creature_until_eot_draw_card_spell_v1",
    }:
        return None
    if required.get("effect") != "composite_resolution":
        return None
    components = [
        component
        for component in required.get("_composite_rule_components") or []
        if isinstance(component, dict)
    ]
    keyword_component = next(
        (component for component in components if component.get("effect") == "stat_modifier_until_eot"),
        None,
    )
    draw_component = next((component for component in components if component.get("effect") == "draw_cards"), None)
    if keyword_component is None or draw_component is None:
        return None
    draw_count = int(required.get("draw_count") or draw_component.get("draw_count") or draw_component.get("count") or 1)
    if draw_count <= 0:
        return None
    target_constraints = dict(
        required.get("target_constraints")
        or keyword_component.get("target_constraints")
        or {"card_types": ["creature"]}
    )
    return {
        "name": f"{rule['card_name']} grants target keyword and draws {draw_count}",
        "type": "target_keyword_draw_spell",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "target": _target_fixture_from_constraints(
            "E2E Target Creature",
            target_constraints,
            matching=True,
        ),
        "nonmatching_target": _target_fixture_from_constraints(
            "E2E Illegal Target Creature",
            target_constraints,
            matching=False,
        ),
        "expected_target_constraints": target_constraints,
        "expected_power_delta": int(required.get("power_delta") or keyword_component.get("power_delta") or 0),
        "expected_toughness_delta": int(
            required.get("toughness_delta") or keyword_component.get("toughness_delta") or 0
        ),
        "expected_keywords": list(required.get("granted_keywords_until_eot") or []),
        "expected_draw_count": draw_count,
        "library": [
            {"name": f"E2E Draw Card {index + 1}", "type_line": "Instant", "effect": "draw_cards"}
            for index in range(draw_count + 1)
        ],
        "logical_rule_key": rule["logical_rule_key"],
    }


def boost_scry_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_fixed_boost_target_creature_until_eot_scry_spell_v1":
        return None
    if required.get("effect") != "composite_resolution":
        return None
    components = [
        component
        for component in required.get("_composite_rule_components") or []
        if isinstance(component, dict)
    ]
    boost_component = next(
        (component for component in components if component.get("effect") == "stat_modifier_until_eot"),
        None,
    )
    scry_component = next(
        (component for component in components if component.get("effect") == "scry"),
        None,
    )
    if boost_component is None or scry_component is None:
        return None
    scry_count = int(required.get("scry_count") or scry_component.get("scry_count") or scry_component.get("count") or 1)
    if scry_count <= 0:
        return None
    type_line = "Sorcery" if required.get("sorcery") is True else "Instant"
    return {
        "name": f"{rule['card_name']} boosts target creature and scries {scry_count}",
        "type": "boost_scry_spell",
        "card": {"name": rule["card_name"], "type_line": type_line},
        "target": {
            "name": "E2E Target Creature",
            "type_line": "Creature - Soldier",
            "power": 2,
            "toughness": 2,
        },
        "expected_power_delta": int(required.get("power_delta") or boost_component.get("power_delta") or 0),
        "expected_toughness_delta": int(required.get("toughness_delta") or boost_component.get("toughness_delta") or 0),
        "expected_scry_count": scry_count,
        "library": [
            {"name": "E2E Low Priority Land", "type_line": "Land", "effect": "land", "cmc": 0},
            {"name": "E2E High Priority Spell", "type_line": "Instant", "effect": "direct_damage", "cmc": 5},
            {"name": "E2E Library Remainder", "type_line": "Creature", "effect": "creature", "cmc": 2},
        ],
        "logical_rule_key": rule["logical_rule_key"],
    }


def _global_stat_modifier_matching_creature(name: str, creature_filter: dict[str, Any]) -> dict[str, Any]:
    card: dict[str, Any] = {
        "name": name,
        "type_line": "Creature - Soldier",
        "power": 2,
        "toughness": 2,
    }
    if creature_filter.get("combat_state") == "attacking":
        card["attacking"] = True
    if creature_filter.get("combat_state") == "blocking":
        card["blocking"] = True
    colors = [str(value).strip().upper() for value in creature_filter.get("colors", []) or [] if str(value).strip()]
    if colors:
        card["colors"] = colors
        card["mana_cost"] = "".join(f"{{{color}}}" for color in colors)
    excluded_colors = {
        str(value).strip().upper()
        for value in creature_filter.get("exclude_colors", []) or []
        if str(value).strip()
    }
    if excluded_colors:
        color = "W" if "W" not in excluded_colors else "U"
        card["colors"] = [color]
        card["mana_cost"] = f"{{{color}}}"
    excluded_subtypes = {
        str(value).strip().lower()
        for value in creature_filter.get("exclude_subtypes", []) or []
        if str(value).strip()
    }
    if excluded_subtypes:
        card["type_line"] = "Creature - Soldier"
    return card


def _global_stat_modifier_nonmatching_permanent(name: str, creature_filter: dict[str, Any]) -> dict[str, Any]:
    if not creature_filter:
        return {"name": name, "type_line": "Artifact", "power": 2, "toughness": 2}
    card: dict[str, Any] = {
        "name": name,
        "type_line": "Creature - Soldier",
        "power": 2,
        "toughness": 2,
    }
    if creature_filter.get("combat_state") == "attacking":
        card["attacking"] = False
    if creature_filter.get("combat_state") == "blocking":
        card["blocking"] = False
    colors = [str(value).strip().upper() for value in creature_filter.get("colors", []) or [] if str(value).strip()]
    if colors:
        color = "B" if "B" not in colors else "W"
        card["colors"] = [color]
        card["mana_cost"] = f"{{{color}}}"
    excluded_colors = [
        str(value).strip().upper()
        for value in creature_filter.get("exclude_colors", []) or []
        if str(value).strip()
    ]
    if excluded_colors:
        color = excluded_colors[0]
        card["colors"] = [color]
        card["mana_cost"] = f"{{{color}}}"
    excluded_subtypes = [
        str(value).strip()
        for value in creature_filter.get("exclude_subtypes", []) or []
        if str(value).strip()
    ]
    if excluded_subtypes:
        card["type_line"] = f"Creature - {excluded_subtypes[0]}"
    excluded_card_types = {
        str(value).strip().lower()
        for value in creature_filter.get("exclude_card_types", []) or []
        if str(value).strip()
    }
    if "artifact" in excluded_card_types:
        card["type_line"] = "Artifact Creature - Golem"
    if creature_filter.get("no_counters"):
        card["counters"] = {"+1/+1": 1}
    return card


def global_stat_modifier_draw_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1":
        return None
    if required.get("effect") != "composite_resolution":
        return None
    components = [
        component
        for component in required.get("_composite_rule_components") or []
        if isinstance(component, dict)
    ]
    boost_component = next(
        (component for component in components if component.get("effect") == "global_stat_modifier_until_eot"),
        None,
    )
    draw_component = next((component for component in components if component.get("effect") == "draw_cards"), None)
    if boost_component is None or draw_component is None:
        return None
    draw_count = int(required.get("draw_count") or draw_component.get("draw_count") or draw_component.get("count") or 1)
    if draw_count <= 0:
        return None
    target_constraints = dict(required.get("target_constraints") or boost_component.get("target_constraints") or {})
    creature_filter = required.get("creature_filter") or boost_component.get("creature_filter") or target_constraints.get("creature_filter") or {}
    if not isinstance(creature_filter, dict):
        creature_filter = {}
    target_controller = str(required.get("target_controller") or boost_component.get("target_controller") or "all").lower()
    controller_matching = _global_stat_modifier_matching_creature("E2E Controller Matching Creature", creature_filter)
    opponent_matching = _global_stat_modifier_matching_creature("E2E Opponent Matching Creature", creature_filter)
    controller_nonmatching = _global_stat_modifier_nonmatching_permanent("E2E Controller Nonmatching Permanent", creature_filter)
    opponent_nonmatching = _global_stat_modifier_nonmatching_permanent("E2E Opponent Nonmatching Permanent", creature_filter)
    expected_affected_names: list[str] = []
    if target_controller in {"all", "any"}:
        expected_affected_names.extend([controller_matching["name"], opponent_matching["name"]])
    elif target_controller in {"opponent", "opponents"}:
        expected_affected_names.append(opponent_matching["name"])
    elif target_controller in {"self", "you", "controller", "controlled"}:
        expected_affected_names.append(controller_matching["name"])
    else:
        return None
    return {
        "name": f"{rule['card_name']} globally modifies creatures and draws {draw_count}",
        "type": "global_stat_modifier_draw_spell",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "controller_battlefield": [controller_matching, controller_nonmatching],
        "opponent_battlefield": [opponent_matching, opponent_nonmatching],
        "expected_affected_names": expected_affected_names,
        "expected_affected_count": len(expected_affected_names),
        "expected_power_delta": int(required.get("power_delta") or boost_component.get("power_delta") or 0),
        "expected_toughness_delta": int(required.get("toughness_delta") or boost_component.get("toughness_delta") or 0),
        "expected_draw_count": draw_count,
        "expected_target_controller": target_controller,
        "expected_creature_filter": creature_filter,
        "library": [
            {"name": f"E2E Draw Card {index + 1}", "type_line": "Instant", "effect": "draw_cards"}
            for index in range(draw_count)
        ],
        "logical_rule_key": rule["logical_rule_key"],
    }


def proliferate_draw_spell_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_fixed_proliferate_and_draw_cards_spell_v1":
        return None
    if required.get("effect") != "composite_resolution":
        return None
    components = [
        component
        for component in required.get("_composite_rule_components") or []
        if isinstance(component, dict)
    ]
    draw_component = next((component for component in components if component.get("effect") == "draw_cards"), None)
    proliferate_component = next((component for component in components if component.get("effect") == "proliferate"), None)
    if draw_component is None or proliferate_component is None:
        return None
    draw_count = int(required.get("draw_count") or draw_component.get("draw_count") or draw_component.get("count") or 1)
    if draw_count <= 0:
        return None
    return {
        "name": f"{rule['card_name']} proliferates and draws {draw_count}",
        "type": "proliferate_draw_spell",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "controller_battlefield": [
            {
                "name": "E2E Controller Counter Creature",
                "type_line": "Creature - Soldier",
                "power": 2,
                "toughness": 2,
                "plus_one_counters": 1,
                "counters": {"+1/+1": 1},
            }
        ],
        "opponent_battlefield": [
            {
                "name": "E2E Opponent Charge Artifact",
                "type_line": "Artifact",
                "charge_counters": 2,
                "counters": {"charge": 2},
            }
        ],
        "opponent_poison_counters": 1,
        "expected_controller_plus_one_counters": 2,
        "expected_controller_power": 3,
        "expected_controller_toughness": 3,
        "expected_opponent_charge_counters": 3,
        "expected_opponent_poison_counters": 2,
        "expected_draw_count": draw_count,
        "library": [
            {"name": f"E2E Draw Card {index + 1}", "type_line": "Instant", "effect": "draw_cards"}
            for index in range(draw_count)
        ],
        "logical_rule_key": rule["logical_rule_key"],
    }


def controlled_stat_modifier_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_fixed_boost_controlled_creatures_until_eot_spell_v1":
        return None
    if required.get("effect") != "controlled_stat_modifier_until_eot":
        return None
    target_constraints = dict(required.get("target_constraints") or {})
    creature_filter = required.get("creature_filter") or target_constraints.get("creature_filter") or {}
    if not isinstance(creature_filter, dict):
        creature_filter = {}
    colors = [
        str(value).strip().upper()
        for value in (creature_filter.get("colors") or [])
        if str(value).strip()
    ]
    matching = {
        "name": "E2E Matching Controlled Creature",
        "type_line": "Creature - Soldier",
        "power": 2,
        "toughness": 2,
        "colors": colors or ["W"],
        "mana_cost": "".join(f"{{{color}}}" for color in (colors or ["W"])),
    }
    nonmatching_color = "B" if "B" not in colors else "W"
    nonmatching = {
        "name": "E2E Nonmatching Controlled Creature",
        "type_line": "Creature - Soldier",
        "power": 2,
        "toughness": 2,
        "colors": [nonmatching_color],
        "mana_cost": f"{{{nonmatching_color}}}",
    }
    opponent_target = {
        "name": "E2E Opponent Matching Creature",
        "type_line": "Creature - Soldier",
        "power": 2,
        "toughness": 2,
        "colors": colors or ["W"],
        "mana_cost": "".join(f"{{{color}}}" for color in (colors or ["W"])),
    }
    return {
        "name": f"{rule['card_name']} boosts controlled filtered creatures until EOT",
        "type": "controlled_stat_modifier_until_eot",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "matching_target": matching,
        "nonmatching_target": nonmatching,
        "opponent_target": opponent_target,
        "expected_power_delta": int(required.get("power_delta") or 0),
        "expected_toughness_delta": int(required.get("toughness_delta") or 0),
        "expected_creature_filter": creature_filter,
        "logical_rule_key": rule["logical_rule_key"],
    }


def attack_self_boost_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_attack_self_boost_until_eot_v1":
        return None
    return {
        "name": f"{rule['card_name']} boosts itself when attacking",
        "type": "attack_self_boost",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature - Soldier",
            "power": 2,
            "toughness": 2,
        },
        "expected_power_delta": int(required.get("power_delta") or required.get("power_boost") or 0),
        "expected_toughness_delta": int(
            required.get("toughness_delta") or required.get("toughness_boost") or 0
        ),
        "logical_rule_key": rule["logical_rule_key"],
    }


def becomes_blocked_self_boost_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_creature_becomes_blocked_self_boost_until_eot_v1":
        return None
    blocker_count_mode = str(required.get("blocker_count_mode") or "fixed")
    blocker_count = 1
    if blocker_count_mode in {"per_blocker", "beyond_first"}:
        blocker_count = 3
    return {
        "name": f"{rule['card_name']} boosts itself when blocked",
        "type": "becomes_blocked_self_boost",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature - Soldier",
            "power": 6 if blocker_count_mode == "beyond_first" else 2,
            "toughness": 6 if blocker_count_mode == "beyond_first" else 2,
        },
        "expected_base_power_delta": int(required.get("power_delta") or required.get("power_boost") or 0),
        "expected_base_toughness_delta": int(
            required.get("toughness_delta") or required.get("toughness_boost") or 0
        ),
        "expected_blocker_count_mode": blocker_count_mode,
        "blocker_count": blocker_count,
        "logical_rule_key": rule["logical_rule_key"],
    }


def each_player_sacrifice_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    scope = required.get("battle_model_scope")
    if scope not in {
        "xmage_each_player_sacrifice_fixed_permanents_spell_v1",
        "xmage_creature_etb_each_player_sacrifice_fixed_permanents_v1",
        "xmage_creature_dies_each_player_sacrifice_fixed_permanents_v1",
    }:
        return None
    card_types = list(required.get("sacrifice_card_types") or ["creature"])
    sacrifice_count = max(1, int(required.get("sacrifice_count") or 1))
    if scope == "xmage_creature_dies_each_player_sacrifice_fixed_permanents_v1":
        scenario_type = "creature_dies_each_player_sacrifice"
        type_line = "Creature"
    elif scope == "xmage_creature_etb_each_player_sacrifice_fixed_permanents_v1":
        scenario_type = "each_player_sacrifice"
        type_line = "Creature"
    else:
        scenario_type = "each_player_sacrifice"
        type_line = "Sorcery"
    return {
        "name": f"{rule['card_name']} each player sacrifices matching permanents",
        "type": scenario_type,
        "card": {"name": rule["card_name"], "type_line": type_line},
        "sacrifice_count": sacrifice_count,
        "sacrifice_card_types": card_types,
        "sacrifice_requires_multicolored": bool(required.get("sacrifice_requires_multicolored")),
        "expected_sacrificed_per_player": sacrifice_count,
        "logical_rule_key": rule["logical_rule_key"],
    }


def board_wipe_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_destroy_all_matching_permanents_spell_v1":
        return None
    destroy_card_types = list(required.get("destroy_card_types") or ["creature"])
    scenario = {
        "name": f"{rule['card_name']} destroys matching permanents",
        "type": "board_wipe",
        "card": {"name": rule["card_name"], "type_line": "Sorcery"},
        "destroy_card_types": destroy_card_types,
        "destroy_controller": required.get("destroy_controller", "any"),
        "logical_rule_key": rule["logical_rule_key"],
    }
    for field in (
        "destroy_required_colors",
        "destroy_excluded_colors",
        "destroy_required_subtypes",
        "destroy_excluded_subtypes",
        "destroy_exclude_card_types",
        "destroy_tapped_state",
        "destroy_nonbasic_lands",
        "destroy_mana_value_lte",
        "destroy_mana_value_lte_source",
        "destroy_mana_value_gte",
        "destroy_power_lte",
        "destroy_power_gte",
        "destroy_toughness_lte",
        "destroy_toughness_gte",
        "destroy_counter_state",
        "destroy_combat_state",
        "destroy_color_count_lt",
        "destroy_dealt_damage_to_you_this_turn",
        "destroy_exclude_commanders",
        "destroy_enchanted_state",
    ):
        if required.get(field) not in (None, "", []):
            scenario[field] = required[field]
    if scenario.get("destroy_mana_value_lte_source") == "x_value":
        scenario["x_value"] = int(required.get("x_value") or required.get("destroy_mana_value_lte") or 3 or 0)
    return scenario


def damage_wipe_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("effect") != "damage_wipe":
        return None
    if required.get("battle_model_scope") not in {
        "xmage_fixed_damage_all_matching_permanents_spell_v1",
        "xmage_fixed_damage_each_creature_each_player_spell_v1",
    }:
        return None
    expected_damage = int(required.get("damage") or required.get("amount") or 1)
    return {
        "name": f"{rule['card_name']} deals damage to matching permanents",
        "type": "damage_wipe",
        "card": {"name": rule["card_name"], "type_line": "Sorcery"},
        "expected_damage": expected_damage,
        "expected_damage_scope": required.get("damage_scope") or "each_creature",
        "expected_damage_players": bool(required.get("damage_players")),
        "logical_rule_key": rule["logical_rule_key"],
    }


def mass_return_to_hand_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_return_all_matching_permanents_to_hand_spell_v1":
        return None
    return_card_types = list(required.get("return_card_types") or ["creature"])
    scenario = {
        "name": f"{rule['card_name']} returns matching permanents to hand",
        "type": "mass_return_to_hand",
        "card": {"name": rule["card_name"], "type_line": "Instant"},
        "return_card_types": return_card_types,
        "return_controller": required.get("return_controller", "any"),
        "logical_rule_key": rule["logical_rule_key"],
    }
    for field in (
        "return_required_colors",
        "return_excluded_colors",
        "return_required_subtypes",
        "return_excluded_subtypes",
        "return_exclude_card_types",
        "return_combat_state",
    ):
        if required.get(field) not in (None, "", []):
            scenario[field] = required[field]
    return scenario


def _library_pick_matching_card(target: str, *, name: str, cmc: int = 5) -> dict[str, Any]:
    normalized = str(target or "any_card").strip().lower()
    mapping = {
        "artifact": ("Artifact", {}),
        "artifact_or_pirate": ("Artifact", {}),
        "creature": ("Creature - Soldier", {}),
        "creature_or_enchantment": ("Enchantment", {}),
        "creature_or_land": ("Creature - Scout", {}),
        "elemental_island_or_mountain": ("Creature - Elemental", {}),
        "elf_swamp_or_forest": ("Creature - Elf", {}),
        "enchantment": ("Enchantment", {}),
        "green_card": ("Creature - Elf", {"colors": ["G"]}),
        "goblin_swamp_or_mountain": ("Creature - Goblin", {}),
        "human_card": ("Creature - Human Soldier", {}),
        "instant_or_sorcery": ("Instant", {}),
        "kithkin_forest_or_plains": ("Creature - Kithkin", {}),
        "land": ("Land", {}),
        "land_or_double_faced": ("Land", {}),
        "merfolk_plains_or_island": ("Creature - Merfolk", {}),
        "mount_creature_or_plains": ("Creature - Mount", {}),
    }
    type_line, extras = mapping.get(normalized, ("Creature - Soldier", {}))
    return {"name": name, "type_line": type_line, "cmc": cmc, **extras}


def _library_pick_nonmatching_card(target: str, *, cmc: int = 8) -> dict[str, Any]:
    normalized = str(target or "any_card").strip().lower()
    if normalized in {"artifact", "artifact_or_pirate"}:
        return {"name": "E2E Nonmatching Creature", "type_line": "Creature - Soldier", "cmc": cmc}
    if normalized in {"instant_or_sorcery"}:
        return {"name": "E2E Nonmatching Creature", "type_line": "Creature - Soldier", "cmc": cmc}
    if normalized in {"land", "land_or_double_faced"}:
        return {"name": "E2E Nonmatching Instant", "type_line": "Instant", "cmc": cmc}
    return {"name": "E2E Nonmatching Artifact", "type_line": "Artifact", "cmc": cmc}


def creature_etb_library_pick_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1",
        "xmage_creature_etb_look_library_pick_to_hand_rest_bottom_v1",
    }:
        return None
    look_count = max(1, int(required.get("etb_library_look_count") or 1))
    pick_count = max(1, int(required.get("etb_library_pick_count") or 1))
    pick_target = str(required.get("etb_library_pick_target") or required.get("target") or "any_card")
    pick_all_matching = bool(required.get("etb_library_pick_all_matching") or required.get("pick_all_matching"))
    matching = [
        _library_pick_matching_card(pick_target, name="E2E Preferred Match", cmc=5),
        _library_pick_matching_card(pick_target, name="E2E Secondary Match", cmc=2),
    ]
    if pick_target == "any_card":
        library = [
            {"name": "E2E Preferred Any", "type_line": "Sorcery", "cmc": 7},
            {"name": "E2E Secondary Any", "type_line": "Creature - Scout", "cmc": 2},
        ]
        expected_picked = ["E2E Preferred Any"]
    else:
        library = [_library_pick_nonmatching_card(pick_target), *matching]
        expected_picked = [card["name"] for card in matching[: (len(matching) if pick_all_matching else pick_count)]]
    while len(library) < look_count:
        library.append({"name": f"E2E Filler {len(library) + 1}", "type_line": "Artifact", "cmc": 1})
    return {
        "name": f"{rule['card_name']} digs on ETB",
        "type": "creature_etb_library_pick",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature - Scout",
            **required,
        },
        "controller_library": library,
        "expected_picked": expected_picked,
        "expected_look_count": look_count,
        "expected_rest_destination": str(required.get("etb_library_rest_destination") or "graveyard"),
        "expected_pick_target": pick_target,
        "logical_rule_key": rule["logical_rule_key"],
    }


def _primary_fixture_card_type(constraints: dict[str, Any]) -> str:
    card_types = [
        str(value or "").strip().lower()
        for value in constraints.get("card_types") or []
        if str(value or "").strip()
    ]
    for card_type in ("creature", "artifact", "enchantment", "planeswalker", "land"):
        if card_type in card_types:
            return card_type
    return "enchantment" if "permanent" in card_types else "creature"


def _type_line_for_fixture(card_type: str, subtypes: list[str] | None = None) -> str:
    clean_type = str(card_type or "creature").strip().lower()
    subtype_suffix = ""
    if subtypes:
        subtype_suffix = " - " + " ".join(str(value).title() for value in subtypes if value)
    if " " in clean_type:
        return f"{' '.join(part.title() for part in clean_type.split())}{subtype_suffix}"
    if clean_type == "creature":
        return f"Creature{subtype_suffix or ' - Soldier'}"
    if clean_type == "artifact":
        return f"Artifact{subtype_suffix}"
    if clean_type == "enchantment":
        return f"Enchantment{subtype_suffix}"
    if clean_type == "planeswalker":
        return "Planeswalker"
    if clean_type == "land":
        return f"Land{subtype_suffix}"
    return f"Permanent{subtype_suffix}"


def _fixture_color_not_in(excluded_colors: set[str]) -> str:
    for color in ("W", "U", "B", "R", "G"):
        if color not in excluded_colors:
            return color
    return "W"


def _fixture_subtype_not_in(required_subtypes: set[str], card_type: str) -> str:
    candidates = (
        ("plains", "island", "swamp", "mountain", "forest")
        if "land" in card_type
        else ("goblin", "elf", "spirit", "soldier", "wizard")
    )
    for subtype in candidates:
        if subtype not in required_subtypes:
            return subtype
    return "fixture_subtype"


def _merge_first_any_of_option(constraints: dict[str, Any]) -> dict[str, Any]:
    merged = dict(constraints)
    options = merged.pop("any_of", None)
    if isinstance(options, list):
        for option in options:
            if isinstance(option, dict):
                merged.update(option)
                break
    return merged


def _target_fixture_from_constraints(
    name: str,
    constraints: dict[str, Any],
    *,
    matching: bool,
) -> dict[str, Any]:
    if not matching and isinstance(constraints.get("any_of"), list):
        return {
            "name": name,
            "type_line": "Land",
            "effect": "land",
            "cmc": 0,
        }
    if not matching and not any(
        key in constraints
        for key in (
            "target_colors",
            "color_count_min",
            "color_count_max",
            "color_count_exact",
            "power_min",
            "power_max",
            "toughness_min",
            "toughness_max",
            "required_keywords",
            "excluded_keywords",
            "exclude_keywords",
            "required_subtypes",
            "exclude_card_types",
            "exclude_colors",
            "exclude_subtypes",
            "exclude_supertypes",
            "enchanted",
            "is_enchanted",
            "combat_state",
            "tapped_state",
            "tap_state",
        )
    ):
        card_types = {str(value or "").strip().lower() for value in constraints.get("card_types") or []}
        if "permanent" in card_types or "land" in card_types:
            return {
                "name": name,
                "type_line": "Instant",
                "effect": "draw_cards",
                "cmc": 1,
            }
        return {
            "name": name,
            "type_line": "Land",
            "effect": "land",
            "cmc": 0,
        }

    active_constraints = _merge_first_any_of_option(constraints) if matching else dict(constraints)
    card_type = _primary_fixture_card_type(active_constraints)
    card_types = {
        str(value or "").strip().lower()
        for value in active_constraints.get("card_types") or []
        if str(value or "").strip()
    }
    if matching and active_constraints.get("all_card_types_required"):
        if {"artifact", "creature"}.issubset(card_types):
            card_type = "artifact creature"
    if not matching and active_constraints.get("exclude_card_types"):
        excluded_type = str((active_constraints.get("exclude_card_types") or ["artifact"])[0]).strip().lower()
        if excluded_type:
            card_type = f"{excluded_type} {card_type}" if card_type != excluded_type else excluded_type
    excluded_supertype = ""
    if not matching and active_constraints.get("exclude_supertypes"):
        excluded_supertype = str((active_constraints.get("exclude_supertypes") or ["legendary"])[0]).strip().lower()
    colors: list[str] = []
    excluded_colors = {str(value).strip().upper() for value in active_constraints.get("exclude_colors") or [] if value}
    if matching:
        target_colors = [str(value) for value in active_constraints.get("target_colors") or [] if value]
        if target_colors:
            colors = [target_colors[0]]
        elif excluded_colors:
            colors = [_fixture_color_not_in(excluded_colors)]
        elif active_constraints.get("color_count_min") is not None:
            colors = ["W", "U"]
        elif active_constraints.get("color_count_exact") is not None:
            colors = ["W", "U", "B", "R", "G"][: max(1, int(active_constraints.get("color_count_exact") or 1))]
    else:
        if active_constraints.get("target_colors"):
            colors = ["B"]
            if "B" in {str(value) for value in active_constraints.get("target_colors") or []}:
                colors = ["W"]
        elif excluded_colors:
            colors = [sorted(excluded_colors)[0]]
        elif active_constraints.get("color_count_min") is not None:
            colors = ["W"]
        elif active_constraints.get("color_count_exact") is not None:
            exact = max(0, int(active_constraints.get("color_count_exact") or 0))
            colors = ["W", "U"] if exact <= 1 else ["W"]

    power = 2
    toughness = 2
    if active_constraints.get("power_min") is not None:
        minimum = int(active_constraints["power_min"])
        power = minimum if matching else max(0, minimum - 1)
    if active_constraints.get("power_max") is not None:
        maximum = int(active_constraints["power_max"])
        power = maximum if matching else maximum + 1
    if active_constraints.get("toughness_min") is not None:
        minimum = int(active_constraints["toughness_min"])
        toughness = minimum if matching else max(0, minimum - 1)
    if active_constraints.get("toughness_max") is not None:
        maximum = int(active_constraints["toughness_max"])
        toughness = maximum if matching else maximum + 1

    mana_value = 3
    if active_constraints.get("mana_value_min") is not None:
        minimum = int(active_constraints["mana_value_min"])
        mana_value = minimum if matching else max(0, minimum - 1)
    if active_constraints.get("mana_value_max") is not None:
        maximum = int(active_constraints["mana_value_max"])
        mana_value = maximum if matching else maximum + 1

    required_subtypes = {
        str(value).strip().lower()
        for value in active_constraints.get("required_subtypes") or []
        if str(value).strip()
    }
    if matching:
        subtypes = sorted(required_subtypes)
    elif required_subtypes:
        subtypes = [_fixture_subtype_not_in(required_subtypes, card_type)]
    else:
        subtypes = []
    if not matching and active_constraints.get("exclude_subtypes"):
        subtypes = [str((active_constraints.get("exclude_subtypes") or ["spirit"])[0]).strip().lower()]
    type_line = _type_line_for_fixture(card_type, subtypes)
    if matching and active_constraints.get("required_supertypes"):
        supertypes = [
            str(value).strip().title()
            for value in active_constraints.get("required_supertypes") or []
            if str(value).strip()
        ]
        if supertypes:
            type_line = f"{' '.join(supertypes)} {type_line}"
    if excluded_supertype:
        type_line = f"{excluded_supertype.title()} {type_line}"
    fixture = {
        "name": name,
        "type_line": type_line,
        "effect": "creature" if "creature" in card_type else card_type,
        "cmc": mana_value,
    }
    if "creature" in card_type:
        fixture["power"] = power
        fixture["toughness"] = toughness
    if active_constraints.get("requires_activated_ability_with_tap_cost"):
        fixture["has_activated_ability_with_tap_cost"] = bool(matching)
    if colors:
        fixture["colors"] = colors
    if active_constraints.get("token"):
        fixture["token"] = bool(matching)
        fixture["is_token"] = bool(matching)
    if subtypes:
        fixture["subtypes"] = subtypes
    if active_constraints.get("enchanted") or active_constraints.get("is_enchanted"):
        fixture["enchanted"] = bool(matching)
        if matching:
            fixture["enchanted_by"] = "E2E Fixture Aura"
    keywords = [
        str(value).strip().lower().replace(" ", "_")
        for value in active_constraints.get("required_keywords") or []
        if str(value).strip()
    ]
    if matching and keywords:
        fixture["keywords"] = keywords
    excluded_keywords = [
        str(value).strip().lower().replace(" ", "_")
        for value in (
            active_constraints.get("excluded_keywords")
            or active_constraints.get("exclude_keywords")
            or []
        )
        if str(value).strip()
    ]
    if not matching and excluded_keywords:
        fixture["keywords"] = excluded_keywords
    combat_state = str(active_constraints.get("combat_state") or "").strip().lower()
    if matching and combat_state:
        if combat_state in {"attacking", "attacking_or_blocking"}:
            fixture["attacking"] = True
        if combat_state == "blocked":
            fixture["blocked"] = True
        if combat_state == "blocking":
            fixture["blocking"] = True
    tapped_state = str(active_constraints.get("tapped_state") or active_constraints.get("tap_state") or "").strip().lower()
    if tapped_state:
        fixture["tapped"] = bool(matching and tapped_state == "tapped") or bool(
            not matching and tapped_state == "untapped"
        )
    return fixture


def _stack_object_fixture_from_constraints(
    name: str,
    constraints: dict[str, Any],
    *,
    matching: bool,
) -> dict[str, Any]:
    if not matching and isinstance(constraints.get("any_of"), list):
        return {
            "card": {
                "name": name,
                "type_line": "Mana Ability",
                "effect": "mana_ability",
                "cmc": 0,
            },
            "effect": {"effect": "mana_ability"},
        }

    if matching and isinstance(constraints.get("any_of"), list):
        active_constraints = dict(constraints)
        for option in constraints.get("any_of") or []:
            if isinstance(option, dict) and str(option.get("stack_object") or "").lower() == "spell":
                active_constraints.update(option)
                break
        else:
            active_constraints = _merge_first_any_of_option(constraints)
    else:
        active_constraints = dict(constraints)
    stack_object = str(active_constraints.get("stack_object") or "spell").strip().lower()
    if not matching and active_constraints.get("require_legendary"):
        stack_object = "spell"

    if (
        not matching
        and stack_object == "spell"
        and not any(
            active_constraints.get(key)
            for key in (
                "card_types",
                "target_card_types",
                "exclude_card_types",
                "spell_types",
                "target_spell_types",
                "spell_subtypes",
                "target_spell_subtypes",
                "exclude_spell_subtypes",
                "excluded_spell_subtypes",
                "spell_colors",
                "target_spell_colors",
                "exclude_spell_colors",
                "excluded_spell_colors",
                "spell_color_count_exact",
                "target_spell_color_count_exact",
                "spell_color_count_min",
                "target_spell_color_count_min",
                "counter_target_mana_value",
                "target_mana_value",
                "counter_target_cmc",
                "target_cmc",
                "counter_target_mana_value_min",
                "target_mana_value_min",
                "counter_target_cmc_min",
                "target_cmc_min",
                "counter_target_mana_value_max",
                "target_mana_value_max",
                "counter_target_cmc_max",
                "target_cmc_max",
                "counter_target_mana_value_source",
                "target_mana_value_source",
                "power_or_toughness_max",
                "target_power_or_toughness_max",
                "source_zone",
                "spell_source_zone",
                "spell_targets",
                "target_spell_targets",
                "spell_order_this_turn",
                "cast_order_this_turn",
                "spell_cast_order",
            )
        )
    ):
        return {
            "card": {
                "name": name,
                "type_line": "Activated Ability",
                "effect": "activated_ability",
                "cmc": 0,
            },
            "effect": {"effect": "activated_ability"},
        }

    if stack_object in {"activated_ability", "triggered_ability", "mana_ability"}:
        label = {
            "activated_ability": "Activated Ability",
            "triggered_ability": "Triggered Ability",
            "mana_ability": "Mana Ability",
        }[stack_object]
        return {
            "card": {
                "name": name,
                "type_line": label,
                "effect": stack_object,
                "cmc": 0,
            },
            "effect": {"effect": stack_object},
        }

    if active_constraints.get("card_types"):
        card = _target_fixture_from_constraints(name, active_constraints, matching=matching)
    else:
        spell_types = [str(value).strip().lower() for value in active_constraints.get("spell_types") or [] if value]
        type_line = "Instant"
        if spell_types:
            type_line = spell_types[0].title()
            if not matching:
                type_line = "Sorcery" if spell_types[0] != "sorcery" else "Instant"
        card = {
            "name": name,
            "type_line": type_line,
            "effect": "finisher",
            "cmc": 3,
            "mana_cost": "{2}{U}",
        }
    spell_subtypes = [
        str(value).strip().title()
        for value in active_constraints.get("spell_subtypes") or active_constraints.get("target_spell_subtypes") or []
        if str(value).strip()
    ]
    excluded_spell_subtypes = [
        str(value).strip().title()
        for value in active_constraints.get("exclude_spell_subtypes")
        or active_constraints.get("excluded_spell_subtypes")
        or []
        if str(value).strip()
    ]
    if matching and spell_subtypes and " - " not in str(card.get("type_line") or ""):
        card["type_line"] = f"{card.get('type_line') or 'Instant'} - {spell_subtypes[0]}"
    if not matching and excluded_spell_subtypes and " - " not in str(card.get("type_line") or ""):
        card["type_line"] = f"{card.get('type_line') or 'Instant'} - {excluded_spell_subtypes[0]}"

    if active_constraints.get("require_legendary"):
        if matching:
            if "legendary" not in str(card.get("type_line") or "").lower():
                card["type_line"] = f"Legendary {card.get('type_line') or 'Creature'}"
            card["legendary"] = True
            card["supertypes"] = ["legendary"]
        else:
            card["legendary"] = False
            card["supertypes"] = []
            card["type_line"] = str(card.get("type_line") or "Creature").replace("Legendary ", "")

    power_or_toughness_max = active_constraints.get("power_or_toughness_max")
    if power_or_toughness_max is not None:
        maximum = int(power_or_toughness_max)
        card["power"] = maximum if matching else maximum + 2
        card["toughness"] = maximum + 3 if matching else maximum + 2
        if matching and int(card["power"]) > maximum and int(card["toughness"]) > maximum:
            card["power"] = maximum

    if active_constraints.get("spell_colors"):
        colors = [str(active_constraints["spell_colors"][0]).strip().upper()]
        if not matching:
            colors = ["W"] if colors[0] != "W" else ["R"]
        card["colors"] = colors
        card["mana_cost"] = "".join(f"{{{color}}}" for color in colors)

    dynamic_mana_value_source = None
    for key in (
        "counter_target_mana_value_source",
        "target_mana_value_source",
        "counter_target_cmc_source",
        "target_cmc_source",
    ):
        if active_constraints.get(key) is not None:
            dynamic_mana_value_source = str(active_constraints.get(key)).strip().lower()
            break
    if dynamic_mana_value_source == "x_value":
        card["cmc"] = 3 if matching else 4
    else:
        exact_mana_value = None
        for key in (
            "counter_target_mana_value",
            "target_mana_value",
            "counter_target_cmc",
            "target_cmc",
        ):
            if active_constraints.get(key) is not None:
                exact_mana_value = int(active_constraints.get(key))
                break
        min_mana_value = None
        for key in (
            "counter_target_mana_value_min",
            "target_mana_value_min",
            "counter_target_cmc_min",
            "target_cmc_min",
        ):
            if active_constraints.get(key) is not None:
                min_mana_value = int(active_constraints.get(key))
                break
        max_mana_value = None
        for key in (
            "counter_target_mana_value_max",
            "target_mana_value_max",
            "counter_target_cmc_max",
            "target_cmc_max",
        ):
            if active_constraints.get(key) is not None:
                max_mana_value = int(active_constraints.get(key))
                break
        if exact_mana_value is not None:
            card["cmc"] = exact_mana_value if matching else exact_mana_value + 1
        elif max_mana_value is not None:
            card["cmc"] = max_mana_value if matching else max_mana_value + 1
        elif min_mana_value is not None:
            card["cmc"] = min_mana_value if matching else max(0, min_mana_value - 1)

    effect = {"effect": card.get("effect") or "finisher"}
    source_zone = active_constraints.get("source_zone") or active_constraints.get("spell_source_zone")
    if source_zone:
        effect["source_zone"] = str(source_zone)
        if not matching:
            effect["source_zone"] = "hand" if str(source_zone).lower() != "hand" else "graveyard"
    spell_targets = active_constraints.get("spell_targets") or active_constraints.get("target_spell_targets")
    if spell_targets:
        target_controller = "Responder" if matching else "Active"
        if str(spell_targets) == "creature":
            effect["targets"] = [
                {
                    "name": "Target Creature",
                    "type_line": "Creature - Soldier" if matching else "Planeswalker",
                    "target_controller": "Active",
                    "target_type": "creature" if matching else "planeswalker",
                }
            ]
        elif str(spell_targets) == "player":
            effect["targets"] = [
                {
                    "name": "Target Player" if matching else "Target Permanent",
                    "target_player": "Active" if matching else None,
                    "target_controller": "Active",
                    "target_type": "player" if matching else "permanent",
                    "type_line": "Player" if matching else "Creature - Soldier",
                    "zone": "player" if matching else "battlefield",
                }
            ]
        elif str(spell_targets) == "permanent_you_control":
            effect["targets"] = [
                {
                    "name": "Protected Permanent",
                    "type_line": "Creature - Soldier",
                    "target_controller": target_controller,
                    "target_type": "permanent",
                    "zone": "battlefield",
                }
            ]
        elif str(spell_targets) == "you_or_permanent_you_control":
            effect["targets"] = [
                {
                    "name": "Protected Permanent",
                    "type_line": "Creature - Soldier",
                    "target_controller": target_controller,
                    "target_type": "permanent",
                    "zone": "battlefield",
                }
            ]

    spell_order = (
        active_constraints.get("spell_order_this_turn")
        or active_constraints.get("cast_order_this_turn")
        or active_constraints.get("spell_cast_order")
    )
    if spell_order is not None:
        try:
            required_order = int(spell_order)
            effect["spell_order_this_turn"] = required_order if matching else max(1, required_order - 1)
        except Exception:
            pass

    if matching and stack_object == "spell":
        card["effect"] = "finisher"
        effect["effect"] = "finisher"

    return {"card": card, "effect": effect}


def counter_target_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    scope = str(required.get("battle_model_scope") or "")
    if (
        required.get("effect") != "counter"
        or scope not in {
            "xmage_counter_target_spell_v1",
            "xmage_counter_target_and_draw_card_spell_v1",
        }
    ):
        return None
    constraints = dict(required.get("target_constraints") or {"zone": "stack", "stack_object": "spell"})
    matching = _stack_object_fixture_from_constraints(
        "E2E Legal Counter Target",
        constraints,
        matching=True,
    )
    nonmatching = _stack_object_fixture_from_constraints(
        "E2E Illegal Counter Target",
        constraints,
        matching=False,
    )
    counter_card = {
        "name": rule["card_name"],
        "type_line": "Instant",
        "mana_cost": "{1}{U}",
        "cmc": 2,
        **required,
    }
    dynamic_mana_value_source = (
        required.get("counter_target_mana_value_source")
        or constraints.get("counter_target_mana_value_source")
        or required.get("target_mana_value_source")
        or constraints.get("target_mana_value_source")
    )
    if str(dynamic_mana_value_source or "").strip().lower() == "x_value":
        counter_card["mana_cost"] = "{X}{U}"
        counter_card["_cast_context"] = {"x_value": int(matching["card"].get("cmc") or 0)}
    return {
        "name": f"{rule['card_name']} counters a legal stack object",
        "type": "counter_target_response",
        "card": counter_card,
        "target_stack_object": matching["card"],
        "target_stack_effect": matching["effect"],
        "nonmatching_stack_object": nonmatching["card"],
        "nonmatching_stack_effect": nonmatching["effect"],
        "expected_target_constraints": constraints,
        "expected_cards_drawn": int(required.get("draw_on_counter") or 0),
        "expected_countered_spell_to_top_library": bool(
            required.get("countered_spell_to_top_library")
        ),
        "expected_countered_spell_to_exile": bool(required.get("countered_spell_to_exile")),
        "logical_rule_key": rule["logical_rule_key"],
    }


def _damage_source_fixture_from_prevention_constraints(
    name: str,
    constraints: dict[str, Any],
    *,
    matching: bool,
) -> dict[str, Any]:
    source = {
        "name": name,
        "type_line": "Creature - Warrior",
        "effect": "creature",
        "power": 4,
        "toughness": 4,
        "colors": ["R"],
    }
    requires_creature = "creature" in {
        str(card_type).lower() for card_type in constraints.get("card_types") or []
    }
    if not matching and requires_creature:
        if constraints.get("exclude_colors"):
            source["colors"] = [str((constraints.get("exclude_colors") or ["G"])[0]).upper()]
            return source
        if constraints.get("power_lte") is not None:
            source["power"] = int(constraints.get("power_lte") or 0) + 1
            source["toughness"] = max(int(source["power"]), 4)
            return source
        if constraints.get("combat_role") == "attacking":
            source["_combat_role"] = "blocking"
            return source
        if constraints.get("controller_scope") == "opponents_control":
            source["_controller_role"] = "self"
            return source
        source = {
            "name": name,
            "type_line": "Instant",
            "effect": "direct_damage",
            "amount": 3,
            "colors": ["R"],
        }
    return source


def damage_prevention_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("effect") != "damage_prevention_shield":
        return None
    if required.get("battle_model_scope") not in {
        "xmage_prevent_all_combat_damage_spell_v1",
        "xmage_prevent_damage_from_creatures_spell_v1",
    }:
        return None
    constraints = dict(required.get("prevent_source_constraints") or {})
    return {
        "name": f"{rule['card_name']} prevents matching damage source",
        "type": "damage_prevention",
        "card": {
            "name": rule["card_name"],
            "type_line": "Instant",
            "mana_cost": "{1}{W}",
            "cmc": 2,
            **required,
        },
        "matching_source": _damage_source_fixture_from_prevention_constraints(
            "E2E Matching Damage Source",
            constraints,
            matching=True,
        ),
        "nonmatching_source": _damage_source_fixture_from_prevention_constraints(
            "E2E Nonmatching Damage Source",
            constraints,
            matching=False,
        ),
        "expected_prevent_damage_scope": required.get("prevent_damage_scope"),
        "expected_prevent_damage_kind": required.get("prevent_damage_kind", "combat_damage"),
        "expected_source_constraints": constraints,
        "logical_rule_key": rule["logical_rule_key"],
    }


def single_target_removal_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_exile_target_spell_v1",
        "xmage_destroy_target_spell_v1",
        "xmage_destroy_target_and_controller_gain_life_spell_v1",
        "xmage_destroy_target_and_source_controller_loses_life_spell_v1",
        "xmage_destroy_target_and_source_controller_damage_spell_v1",
        "xmage_destroy_target_and_target_controller_damage_spell_v1",
        "xmage_return_target_to_hand_spell_v1",
    }:
        return None
    if required.get("effect") not in {"remove_creature", "remove_permanent"}:
        return None
    target_count = int(required.get("target_count_max") or required.get("max_targets") or required.get("target_count") or 1)
    if target_count > 1:
        return None
    constraints = dict(required.get("target_constraints") or {})
    destination = str(required.get("destination") or "graveyard").lower()
    scenario = {
        "name": f"{rule['card_name']} removes one legal target",
        "type": "single_target_removal",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "target": _target_fixture_from_constraints("E2E Legal Removal Target", constraints, matching=True),
        "nonmatching_target": _target_fixture_from_constraints(
            "E2E Illegal Removal Target",
            constraints,
            matching=False,
        ),
        "expected_destination": destination,
        "expected_effect": required.get("effect"),
        "expected_target_constraints": constraints,
        "logical_rule_key": rule["logical_rule_key"],
    }
    controller_life_gain = int(required.get("controller_gains_life") or 0)
    if controller_life_gain > 0:
        scenario["controller_life"] = 10
        scenario["expected_controller_life_gain"] = controller_life_gain
    source_controller_life_loss = int(required.get("source_controller_life_loss_on_resolve") or 0)
    source_controller_damage = int(required.get("source_controller_damage_on_resolve") or 0)
    target_controller_damage = int(required.get("target_controller_damage_on_resolve") or 0)
    if source_controller_life_loss > 0:
        scenario["controller_life"] = 20
        scenario["expected_source_controller_life_loss"] = source_controller_life_loss
    if source_controller_damage > 0:
        scenario["controller_life"] = 20
        scenario["expected_source_controller_damage"] = source_controller_damage
    if target_controller_damage > 0:
        scenario["target_controller_life"] = 20
        scenario["expected_target_controller_damage"] = target_controller_damage
    additional_cost_options = [
        option
        for option in required.get("additional_cost_options") or []
        if isinstance(option, dict)
    ]
    selected_additional_cost = str(required.get("additional_cost") or "").strip()
    selected_option = additional_cost_options[0] if additional_cost_options else {}
    if selected_option:
        selected_additional_cost = str(selected_option.get("cost") or "").strip()
    if selected_additional_cost == "discard_card":
        scenario["controller_hand"] = [
            {
                "name": "E2E Discard Cost Card",
                "type_line": "Sorcery",
                "effect": "draw_cards",
            }
        ]
        scenario["expected_additional_cost"] = "discard_card"
        scenario["expected_discarded_name"] = "E2E Discard Cost Card"
    elif selected_additional_cost == "pay_life":
        pay_life_amount = int(
            selected_option.get("pay_life_amount")
            or required.get("pay_life_amount")
            or 0
        )
        if pay_life_amount > 0:
            scenario["controller_life"] = max(20, pay_life_amount + 5)
            scenario["expected_additional_cost"] = "pay_life"
            scenario["expected_pay_life_amount"] = pay_life_amount
    elif selected_additional_cost in {
        "sacrifice_creature",
        "sacrifice_creature_or_enchantment",
        "sacrifice_creature_or_planeswalker",
        "sacrifice_artifact_or_creature",
    }:
        fixture_by_cost = {
            "sacrifice_creature": {
                "name": "E2E Sacrifice Cost Creature",
                "type_line": "Creature - Soldier",
                "effect": "creature",
                "power": 1,
                "toughness": 1,
            },
            "sacrifice_creature_or_enchantment": {
                "name": "E2E Sacrifice Cost Enchantment",
                "type_line": "Enchantment",
                "effect": "enchantment",
            },
            "sacrifice_creature_or_planeswalker": {
                "name": "E2E Sacrifice Cost Planeswalker",
                "type_line": "Planeswalker",
                "effect": "planeswalker",
                "loyalty": 3,
            },
            "sacrifice_artifact_or_creature": {
                "name": "E2E Sacrifice Cost Artifact",
                "type_line": "Artifact",
                "effect": "artifact",
            },
        }
        scenario["controller_battlefield"] = [
            *scenario.get("controller_battlefield", []),
            fixture_by_cost[selected_additional_cost],
        ]
        scenario["expected_additional_cost"] = selected_additional_cost
        scenario["expected_sacrificed_name"] = fixture_by_cost[selected_additional_cost]["name"]
    return scenario


def modal_damage_or_destroy_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_choose_one_damage_or_destroy_target_spell_v1":
        return None
    if required.get("effect") != "modal_spell":
        return None
    modes = [mode for mode in required.get("modal_modes") or [] if isinstance(mode, dict)]
    damage_mode = next((mode for mode in modes if mode.get("effect") == "direct_damage"), None)
    destroy_mode = next(
        (
            mode
            for mode in modes
            if mode.get("effect") in {"remove_creature", "remove_permanent"}
        ),
        None,
    )
    if damage_mode is None or destroy_mode is None:
        return None
    destroy_constraints = dict(destroy_mode.get("target_constraints") or {})
    damage_constraints = dict(damage_mode.get("target_constraints") or {})
    return {
        "name": f"{rule['card_name']} chooses destroy mode over damage mode",
        "type": "modal_damage_or_destroy",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "destroy_target": _target_fixture_from_constraints(
            "E2E Legal Modal Destroy Target",
            destroy_constraints,
            matching=True,
        ),
        "damage_target": _target_fixture_from_constraints(
            "E2E Legal Modal Damage Target",
            damage_constraints,
            matching=True,
        ),
        "expected_selected_mode": "destroy_target",
        "expected_removed_target": "E2E Legal Modal Destroy Target",
        "expected_damage_target_survives": "E2E Legal Modal Damage Target",
        "expected_destination": str(destroy_mode.get("destination") or "graveyard").lower(),
        "logical_rule_key": rule["logical_rule_key"],
    }


def single_target_removal_and_surveil_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_destroy_target_and_surveil_spell_v1":
        return None
    if required.get("effect") != "composite_resolution":
        return None
    components = [
        component
        for component in required.get("_composite_rule_components") or []
        if isinstance(component, dict)
    ]
    removal_component = next(
        (
            component
            for component in components
            if component.get("effect") in {"remove_creature", "remove_permanent"}
        ),
        None,
    )
    surveil_component = next(
        (component for component in components if component.get("effect") == "surveil"),
        None,
    )
    if removal_component is None or surveil_component is None:
        return None
    constraints = dict(required.get("target_constraints") or removal_component.get("target_constraints") or {})
    destination = str(required.get("destination") or removal_component.get("destination") or "graveyard").lower()
    surveil_count = int(
        required.get("surveil_count")
        or surveil_component.get("surveil_count")
        or surveil_component.get("count")
        or 1
    )
    return {
        "name": f"{rule['card_name']} destroys one legal target and surveils",
        "type": "single_target_removal_and_surveil",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "target": _target_fixture_from_constraints("E2E Legal Removal Target", constraints, matching=True),
        "nonmatching_target": _target_fixture_from_constraints(
            "E2E Illegal Removal Target",
            constraints,
            matching=False,
        ),
        "expected_destination": destination,
        "expected_effect": removal_component.get("effect"),
        "expected_target_constraints": constraints,
        "expected_surveil_count": surveil_count,
        "player_battlefield": [
            {"name": f"E2E Surveil Land {index}", "type_line": "Land", "effect": "land", "cmc": 0}
            for index in range(1, 5)
        ],
        "library": [
            {"name": "E2E Low Priority Land", "type_line": "Land", "effect": "land", "cmc": 0},
            {"name": "E2E High Priority Spell", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 7},
            {"name": "E2E Library Remainder", "type_line": "Instant", "effect": "direct_damage", "cmc": 2},
        ],
        "logical_rule_key": rule["logical_rule_key"],
    }


def single_target_removal_and_draw_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_exile_target_and_draw_card_spell_v1",
        "xmage_destroy_target_and_draw_card_spell_v1",
        "xmage_return_target_to_hand_and_draw_card_spell_v1",
    }:
        return None
    if required.get("effect") != "composite_resolution":
        return None
    components = [
        component
        for component in required.get("_composite_rule_components") or []
        if isinstance(component, dict)
    ]
    removal_component = next(
        (
            component
            for component in components
            if component.get("effect") in {"remove_creature", "remove_permanent"}
        ),
        None,
    )
    graveyard_exile_component = next(
        (
            component
            for component in components
            if component.get("effect") == "graveyard_exile"
        ),
        None,
    )
    draw_component = next(
        (component for component in components if component.get("effect") == "draw_cards"),
        None,
    )
    target_component = removal_component or graveyard_exile_component
    if target_component is None or draw_component is None:
        return None
    constraints = dict(required.get("target_constraints") or target_component.get("target_constraints") or {})
    destination = str(required.get("destination") or target_component.get("destination") or "graveyard").lower()
    draw_count = int(
        required.get("draw_count")
        or draw_component.get("draw_count")
        or draw_component.get("count")
        or 1
    )
    if draw_count <= 0:
        return None
    target_zone = "graveyard" if graveyard_exile_component is not None else "battlefield"
    if target_zone == "graveyard":
        target = {
            "name": "E2E Legal Graveyard Target",
            "type_line": "Instant",
            "effect": "draw_cards",
            "cmc": 2,
        }
        nonmatching = {
            "name": "E2E Battlefield Non-Target",
            "type_line": "Creature - Soldier",
            "effect": "creature",
            "cmc": 2,
            "power": 2,
            "toughness": 2,
        }
    else:
        target = _target_fixture_from_constraints("E2E Legal Removal Target", constraints, matching=True)
        nonmatching = _target_fixture_from_constraints(
            "E2E Illegal Removal Target",
            constraints,
            matching=False,
        )
    return {
        "name": f"{rule['card_name']} removes one legal target and draws {draw_count}",
        "type": "single_target_removal_and_draw",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "target": target,
        "nonmatching_target": nonmatching,
        "target_zone": target_zone,
        "target_owner": "opponent",
        "expected_destination": destination,
        "expected_effect": target_component.get("effect"),
        "expected_target_constraints": constraints,
        "expected_draw_count": draw_count,
        "controller_library": [
            {"name": f"E2E Draw Card {index}", "type_line": "Instant", "effect": "draw_cards"}
            for index in range(1, draw_count + 3)
        ],
        "logical_rule_key": rule["logical_rule_key"],
    }


def multi_target_removal_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_exile_target_spell_v1",
        "xmage_destroy_target_spell_v1",
        "xmage_destroy_target_and_source_controller_loses_life_spell_v1",
        "xmage_return_target_to_hand_spell_v1",
    }:
        return None
    if required.get("effect") not in {"remove_creature", "remove_permanent"}:
        return None
    target_count = int(required.get("target_count_max") or required.get("max_targets") or required.get("target_count") or 1)
    if target_count <= 1:
        return None
    target_count = max(2, min(target_count, 10))
    constraints = dict(required.get("target_constraints") or {})
    destination = str(required.get("destination") or "graveyard").lower()
    scenario = {
        "name": f"{rule['card_name']} removes {target_count} legal targets",
        "type": "multi_target_removal",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "targets": [
            _target_fixture_from_constraints(
                f"E2E Legal Removal Target {index}",
                constraints,
                matching=True,
            )
            for index in range(1, target_count + 1)
        ],
        "nonmatching_target": _target_fixture_from_constraints(
            "E2E Illegal Removal Target",
            constraints,
            matching=False,
        ),
        "expected_destination": destination,
        "expected_effect": required.get("effect"),
        "expected_target_constraints": constraints,
        "expected_target_count": target_count,
        "logical_rule_key": rule["logical_rule_key"],
    }
    source_controller_life_loss = int(required.get("source_controller_life_loss_on_resolve") or 0)
    if source_controller_life_loss > 0:
        scenario["controller_life"] = 20
        scenario["expected_source_controller_life_loss"] = source_controller_life_loss
    return scenario


def multi_target_damage_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_fixed_multi_target_damage_spell_v1",
        "xmage_fixed_damage_each_target_spell_v1",
    }:
        return None
    if required.get("effect") != "multi_target_damage":
        return None
    total_damage = int(required.get("amount") or required.get("damage") or 0)
    per_target_damage = int(required.get("damage_per_target") or total_damage or 0)
    each_target_mode = str(required.get("damage_assignment_mode") or "").strip().lower() == "each_target"
    target_count = int(required.get("target_count_max") or required.get("max_targets") or required.get("target_count") or 1)
    if (not each_target_mode and total_damage <= 1) or (each_target_mode and per_target_damage <= 0) or target_count <= 1:
        return None
    target_count = max(2, min(target_count, 3 if each_target_mode else total_damage, 3))
    constraints = dict(required.get("target_constraints") or {})
    targets = []
    for index in range(1, target_count + 1):
        fixture = _target_fixture_from_constraints(
            f"E2E Legal Damage Target {index}",
            constraints,
            matching=True,
        )
        if "creature" in str(fixture.get("type_line") or "").lower():
            fixture["toughness"] = max(6, int(fixture.get("toughness") or 0))
        targets.append(fixture)
    nonmatching = _target_fixture_from_constraints(
        "E2E Illegal Damage Target",
        constraints,
        matching=False,
    )
    return {
        "name": (
            f"{rule['card_name']} deals {per_target_damage} damage to each target"
            if each_target_mode
            else f"{rule['card_name']} divides {total_damage} damage"
        ),
        "type": "multi_target_damage",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "targets": targets,
        "nonmatching_target": nonmatching,
        "expected_total_damage": per_target_damage * target_count if each_target_mode else total_damage,
        "expected_target_count": target_count,
        "expected_effect": required.get("effect"),
        "expected_target_constraints": constraints,
        "logical_rule_key": rule["logical_rule_key"],
    }


def counter_unless_pays_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if (
        required.get("effect") != "counter"
        or required.get("battle_model_scope")
        not in {
            "xmage_counter_target_spell_unless_controller_pays_generic_v1",
            "xmage_counter_target_spell_unless_controller_pays_generic_draw_card_v1",
        }
    ):
        return None

    def safe_int(value: Any, default: int = 0) -> int:
        try:
            return int(float(value))
        except Exception:
            return int(default or 0)

    amount_source = str(required.get("counter_unless_pays_amount_source") or "").strip().lower()
    base = max(0, safe_int(required.get("counter_unless_pays_base"), 0))
    per = max(0, safe_int(required.get("counter_unless_pays_per"), 1))
    expected_tax = max(0, safe_int(required.get("counter_unless_pays_generic"), 0))
    expected_count: int | None = None
    target_stack_effect: dict[str, Any] = {"effect": "finisher"}
    active_battlefield: list[dict[str, Any]] = []
    responder_battlefield: list[dict[str, Any]] = []

    if amount_source == "x_value":
        expected_count = 3
        expected_tax = 3
        target_stack_effect["_cast_context"] = {"x_value": expected_tax}
    elif amount_source == "domain_basic_land_types":
        expected_count = 3
        responder_battlefield = [
            {"name": "Fixture Plains", "type_line": "Land - Plains", "subtypes": ["Plains"]},
            {"name": "Fixture Island", "type_line": "Land - Island", "subtypes": ["Island"]},
            {"name": "Fixture Mountain", "type_line": "Land - Mountain", "subtypes": ["Mountain"]},
        ]
        expected_tax = per * expected_count
    elif amount_source == "devotion_to_blue":
        expected_count = 3
        responder_battlefield = [
            {"name": "Fixture Blue Devotion One", "type_line": "Enchantment", "mana_cost": "{U}{U}"},
            {"name": "Fixture Blue Devotion Two", "type_line": "Artifact", "mana_cost": "{2}{U}"},
        ]
        expected_tax = expected_count
    elif amount_source == "party_count":
        expected_count = 4
        responder_battlefield = [
            {"name": "Fixture Cleric", "type_line": "Creature - Cleric", "subtypes": ["Cleric"]},
            {"name": "Fixture Rogue", "type_line": "Creature - Rogue", "subtypes": ["Rogue"]},
            {"name": "Fixture Warrior", "type_line": "Creature - Warrior", "subtypes": ["Warrior"]},
            {"name": "Fixture Wizard", "type_line": "Creature - Wizard", "subtypes": ["Wizard"]},
        ]
        expected_tax = base + (per * expected_count)
    elif amount_source == "controlled_subtype_count":
        expected_count = 2
        subtype = str(required.get("counter_unless_pays_subtype") or "faerie").strip().title()
        responder_battlefield = [
            {"name": f"Fixture {subtype} One", "type_line": f"Creature - {subtype}", "subtypes": [subtype]},
            {"name": f"Fixture {subtype} Two", "type_line": f"Creature - {subtype}", "subtypes": [subtype]},
        ]
        expected_tax = base + (per * expected_count)
    elif amount_source == "battlefield_subtype_count":
        expected_count = 2
        subtype = str(required.get("counter_unless_pays_subtype") or "wizard").strip().title()
        active_battlefield = [
            {"name": f"Active {subtype}", "type_line": f"Creature - {subtype}", "subtypes": [subtype]},
        ]
        responder_battlefield = [
            {"name": f"Responder {subtype}", "type_line": f"Creature - {subtype}", "subtypes": [subtype]},
        ]
        expected_tax = base + (per * expected_count)

    target_spell = {
        "name": "Counter Target Fixture",
        "cmc": 7,
        "mana_cost": "{5}{R}{R}",
        "type_line": "Creature - Dragon",
        "effect": "finisher",
    }
    if required.get("target") == "noncreature_spell":
        target_spell.update({"type_line": "Sorcery"})
    elif required.get("target") in {"instant_or_sorcery_spell", "instant_spell"}:
        target_spell.update({"type_line": "Instant"})
    elif required.get("target") == "sorcery_spell":
        target_spell.update({"type_line": "Sorcery"})

    return {
        "name": f"{rule['card_name']} counters unless tax is paid",
        "type": "counter_unless_pays_response",
        "card": {
            "name": rule["card_name"],
            "type_line": "Instant",
            "mana_cost": "{U}",
            "cmc": 1,
            "instant": True,
        },
        "target_spell": target_spell,
        "target_stack_effect": target_stack_effect,
        "active_battlefield": active_battlefield,
        "responder_battlefield": responder_battlefield,
        "responder_mana": {"blue": 1},
        "active_mana": {"generic": 0},
        "expected_countered": True,
        "expected_counter_tax_paid": False,
        "expected_counter_unless_pays_generic": expected_tax,
        "expected_counter_unless_pays_amount_source": amount_source or None,
        "expected_counter_unless_pays_count": expected_count,
        "expected_countered_spell_to_exile": bool(required.get("countered_spell_to_exile")),
        "expected_cards_drawn": max(0, safe_int(required.get("draw_on_counter"), 0)),
        "logical_rule_key": rule["logical_rule_key"],
    }


def static_cost_increase_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_static_generic_cost_increase_for_matching_spells_v1":
        return None
    if required.get("effect") != "static_cost_increase":
        return None
    filters = [
        spec
        for spec in (required.get("cost_increase_filters") or [{}])
        if isinstance(spec, dict)
    ] or [{}]
    first_filter = dict(filters[0])
    spell_colors = [str(value).upper() for value in first_filter.get("applies_to_spell_colors") or [] if value]
    spell_types = [str(value).lower() for value in first_filter.get("applies_to_card_types") or [] if value]
    color_symbol = spell_colors[0] if spell_colors else "W"
    color_name = {
        "W": "White",
        "U": "Blue",
        "B": "Black",
        "R": "Red",
        "G": "Green",
    }.get(color_symbol, "White")
    type_line = "Creature" if "creature" in spell_types else "Sorcery"
    target_spell = {
        "name": "E2E Matching Taxed Spell",
        "type_line": type_line,
        "colors": [color_symbol],
        "mana_cost": f"{{1}}{{{color_symbol}}}",
        "cmc": 2,
    }
    if type_line == "Creature":
        target_spell["effect"] = "creature"
    expected_colored = {color_name.lower(): 1}
    for symbol in required.get("cost_increase_color_symbols") or []:
        mapped = {
            "W": "white",
            "U": "blue",
            "B": "black",
            "R": "red",
            "G": "green",
        }.get(str(symbol).upper())
        if mapped:
            expected_colored[mapped] = expected_colored.get(mapped, 0) + 1
    return {
        "name": f"{rule['card_name']} increases matching spell cost",
        "type": "static_cost_increase_spell_cost",
        "card": {"name": rule["card_name"]},
        "target_spell": target_spell,
        "expected_generic": 1 + int(required.get("cost_increase_generic") or 0),
        "expected_colored": expected_colored,
        "expected_static_cost_increase_total": int(required.get("cost_increase_generic") or 0)
        + len(required.get("cost_increase_color_symbols") or []),
        "expected_static_cost_increase_color_symbols": list(required.get("cost_increase_color_symbols") or []),
        "logical_rule_key": rule["logical_rule_key"],
    }


def static_cost_reduction_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_static_generic_cost_reduction_for_matching_spells_v1":
        return None
    if required.get("effect") != "static_cost_reduction":
        return None
    color_symbols = [
        str(symbol).upper()
        for symbol in (required.get("cost_reduction_color_symbols") or [])
        if str(symbol).upper() in {"W", "U", "B", "R", "G"}
    ]
    spell_colors = [
        str(symbol).upper()
        for symbol in (required.get("applies_to_spell_colors") or [])
        if str(symbol).upper() in {"W", "U", "B", "R", "G"}
    ]
    test_colors = color_symbols or spell_colors or ["W"]
    card_types = [str(value).lower() for value in required.get("applies_to_card_types") or [] if value]
    subtypes = [str(value).lower() for value in required.get("applies_to_subtypes") or [] if value]
    if "instant" in card_types:
        type_line = "Instant"
    elif "sorcery" in card_types:
        type_line = "Sorcery"
    elif "artifact" in card_types:
        type_line = "Artifact"
    elif "enchantment" in card_types:
        type_line = "Enchantment"
    elif subtypes:
        type_line = "Creature - " + " ".join(part.capitalize() for part in subtypes[0].split())
    else:
        type_line = "Creature"
    base_generic = max(1, int(required.get("cost_reduction_generic") or 0))
    base_colored: dict[str, int] = {}
    for symbol in test_colors:
        mapped = {
            "W": "white",
            "U": "blue",
            "B": "black",
            "R": "red",
            "G": "green",
        }.get(symbol)
        if mapped:
            base_colored[mapped] = base_colored.get(mapped, 0) + 1
    expected_colored = dict(base_colored)
    applied_colored = 0
    for symbol in color_symbols:
        mapped = {
            "W": "white",
            "U": "blue",
            "B": "black",
            "R": "red",
            "G": "green",
        }.get(symbol)
        if mapped and expected_colored.get(mapped, 0) > 0:
            expected_colored[mapped] -= 1
            applied_colored += 1
    generic_reduction = max(0, int(required.get("cost_reduction_generic") or 0))
    applied_generic = min(base_generic, generic_reduction)
    return {
        "name": f"{rule['card_name']} reduces matching spell cost",
        "type": "static_cost_reduction_spell_cost",
        "card": {"name": rule["card_name"]},
        "target_spell": {
            "name": "E2E Matching Reduced Spell",
            "type_line": type_line,
            "colors": test_colors,
            "mana_cost": f"{{{base_generic}}}" + "".join(f"{{{symbol}}}" for symbol in test_colors),
            "cmc": base_generic + len(test_colors),
        },
        "expected_generic": base_generic - applied_generic,
        "expected_colored": expected_colored,
        "expected_static_cost_reduction_total": applied_generic + applied_colored,
        "expected_static_cost_reduction_color_symbols": list(color_symbols),
        "logical_rule_key": rule["logical_rule_key"],
    }


def execution_scenario_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any] | None:
    return (
        damage_prevention_execution_scenario_from_expected_rule(rule)
        or counter_target_execution_scenario_from_expected_rule(rule)
        or counter_unless_pays_execution_scenario_from_expected_rule(rule)
        or static_filtered_protection_execution_scenario_from_expected_rule(rule)
        or static_subtype_protection_execution_scenario_from_expected_rule(rule)
        or static_cost_reduction_execution_scenario_from_expected_rule(rule)
        or static_cost_increase_execution_scenario_from_expected_rule(rule)
        or static_controlled_pt_execution_scenario_from_expected_rule(rule)
        or static_controlled_keyword_execution_scenario_from_expected_rule(rule)
        or static_global_pt_execution_scenario_from_expected_rule(rule)
        or aura_static_pt_execution_scenario_from_expected_rule(rule)
        or equipment_static_pt_execution_scenario_from_expected_rule(rule)
        or static_graveyard_threshold_boost_execution_scenario_from_expected_rule(rule)
        or static_count_pt_execution_scenario_from_expected_rule(rule)
        or destroy_target_create_treasure_execution_scenario_from_expected_rule(rule)
        or creature_etb_fixed_mana_execution_scenario_from_expected_rule(rule)
        or creature_etb_create_treasure_execution_scenario_from_expected_rule(rule)
        or creature_dies_create_treasure_execution_scenario_from_expected_rule(rule)
        or creature_dies_add_counters_execution_scenario_from_expected_rule(rule)
        or creature_etb_create_tokens_execution_scenario_from_expected_rule(rule)
        or creature_etb_scry_execution_scenario_from_expected_rule(rule)
        or creature_etb_library_pick_execution_scenario_from_expected_rule(rule)
        or creature_dies_create_tokens_execution_scenario_from_expected_rule(rule)
        or simple_mana_source_execution_scenario_from_expected_rule(rule)
        or sacrifice_mana_source_execution_scenario_from_expected_rule(rule)
        or damage_each_opponent_spell_execution_scenario_from_expected_rule(rule)
        or damage_each_opponent_and_their_permanents_execution_scenario_from_expected_rule(rule)
        or damage_gain_life_spell_execution_scenario_from_expected_rule(rule)
        or fixed_damage_target_spell_execution_scenario_from_expected_rule(rule)
        or damage_target_create_treasure_execution_scenario_from_expected_rule(rule)
        or tap_target_spell_execution_scenario_from_expected_rule(rule)
        or gain_control_untap_haste_execution_scenario_from_expected_rule(rule)
        or add_counters_target_spell_execution_scenario_from_expected_rule(rule)
        or add_counters_untap_target_spell_execution_scenario_from_expected_rule(rule)
        or boost_untap_target_spell_execution_scenario_from_expected_rule(rule)
        or simple_activated_draw_execution_scenario_from_expected_rule(rule)
        or simple_activated_draw_discard_execution_scenario_from_expected_rule(rule)
        or fixed_draw_spell_execution_scenario_from_expected_rule(rule)
        or fixed_draw_discard_spell_execution_scenario_from_expected_rule(rule)
        or target_player_draw_execution_scenario_from_expected_rule(rule)
        or combat_damage_draw_execution_scenario_from_expected_rule(rule)
        or beginning_end_step_draw_execution_scenario_from_expected_rule(rule)
        or simple_activated_damage_execution_scenario_from_expected_rule(rule)
        or simple_activated_tap_target_execution_scenario_from_expected_rule(rule)
        or simple_activated_untap_target_execution_scenario_from_expected_rule(rule)
        or simple_activated_add_counters_target_execution_scenario_from_expected_rule(rule)
        or simple_activated_add_counters_self_execution_scenario_from_expected_rule(rule)
        or simple_activated_destroy_execution_scenario_from_expected_rule(rule)
        or simple_activated_self_boost_execution_scenario_from_expected_rule(rule)
        or simple_activated_self_keyword_execution_scenario_from_expected_rule(rule)
        or simple_activated_regenerate_source_execution_scenario_from_expected_rule(rule)
        or simple_activated_regenerate_target_execution_scenario_from_expected_rule(rule)
        or simple_activated_target_keyword_execution_scenario_from_expected_rule(rule)
        or controlled_stat_modifier_execution_scenario_from_expected_rule(rule)
        or target_keyword_spell_execution_scenario_from_expected_rule(rule)
        or target_keyword_draw_spell_execution_scenario_from_expected_rule(rule)
        or boost_scry_spell_execution_scenario_from_expected_rule(rule)
        or global_stat_modifier_draw_spell_execution_scenario_from_expected_rule(rule)
        or proliferate_draw_spell_execution_scenario_from_expected_rule(rule)
        or attack_self_boost_execution_scenario_from_expected_rule(rule)
        or becomes_blocked_self_boost_execution_scenario_from_expected_rule(rule)
        or damage_wipe_execution_scenario_from_expected_rule(rule)
        or board_wipe_execution_scenario_from_expected_rule(rule)
        or mass_return_to_hand_execution_scenario_from_expected_rule(rule)
        or each_player_sacrifice_execution_scenario_from_expected_rule(rule)
        or multi_target_damage_execution_scenario_from_expected_rule(rule)
        or multi_target_removal_execution_scenario_from_expected_rule(rule)
        or single_target_removal_and_draw_execution_scenario_from_expected_rule(rule)
        or single_target_removal_and_surveil_execution_scenario_from_expected_rule(rule)
        or modal_damage_or_destroy_execution_scenario_from_expected_rule(rule)
        or single_target_removal_execution_scenario_from_expected_rule(rule)
        or simple_activated_create_token_execution_scenario_from_expected_rule(rule)
        or fixed_create_creature_tokens_execution_scenario_from_expected_rule(rule)
        or multi_create_creature_tokens_execution_scenario_from_expected_rule(rule)
        or dynamic_life_gain_execution_scenario_from_expected_rule(rule)
        or creature_etb_dynamic_life_gain_execution_scenario_from_expected_rule(rule)
        or creature_enters_life_gain_execution_scenario_from_expected_rule(rule)
        or creature_enters_draw_execution_scenario_from_expected_rule(rule)
        or creature_etb_draw_execution_scenario_from_expected_rule(rule)
        or creature_etb_draw_discard_execution_scenario_from_expected_rule(rule)
        or creature_etb_target_stat_modifier_execution_scenario_from_expected_rule(rule)
        or spell_cast_gain_life_execution_scenario_from_expected_rule(rule)
        or spell_cast_token_maker_execution_scenario_from_expected_rule(rule)
    )


def markdown_package(manifest: dict[str, Any]) -> str:
    lines = [
        f"# {manifest['deploy_id']} XMage Batch PostgreSQL Package",
        "",
        "Status: `prepared_read_only_pending_apply_approval`.",
        "",
        "This package was generated from XMage batch proposals. No SQL was executed by the builder.",
        "",
        f"- Generated at: `{manifest['generated_at']}`",
        f"- Selected cards: `{json.dumps(manifest['selected_card_names'], sort_keys=True)}`",
        f"- Families: `{json.dumps(manifest['family_counts'], sort_keys=True)}`",
        "",
        "Files:",
        "",
    ]
    for label, path in manifest["files"].items():
        lines.append(f"- {label}: `{path}`")
    lines.extend(
        [
            "",
            "Apply gate:",
            "",
            "- Do not run apply SQL without explicit approval for the exact command.",
            "- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.",
        ]
    )
    return "\n".join(lines).rstrip() + "\n"


def existing_backup_table_from_manifest(manifest_path: Path) -> str | None:
    if not manifest_path.exists():
        return None
    try:
        payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception:
        return None
    value = str(payload.get("backup_table") or "").strip()
    if not value:
        return None
    if "." in value:
        value = value.split(".", 1)[1]
    if re.search(r"_\d{8}_$", value):
        return None
    return safe_ident(value)


def build_package(
    proposal_report: dict[str, Any],
    *,
    deploy_id: str,
    slug: str,
    output_prefix: Path,
    include_family: set[str],
    include_card: set[str],
    exclude_card: set[str],
    max_cards: int | None,
) -> dict[str, Any]:
    selected = select_proposals(
        proposal_report.get("proposals", []),
        include_family=include_family,
        include_card=include_card,
        exclude_card=exclude_card,
        max_cards=max_cards,
    )
    if not selected:
        raise ValueError("No safe proposals selected for package generation.")

    files = {
        "precheck": f"{output_prefix}_precheck.sql",
        "apply": f"{output_prefix}_apply.sql",
        "rollback": f"{output_prefix}_rollback.sql",
        "postcheck": f"{output_prefix}_postcheck.sql",
        "manifest": f"{output_prefix}_manifest.json",
        "package": f"{output_prefix}_package.md",
    }
    backup_table = existing_backup_table_from_manifest(Path(files["manifest"])) or safe_ident(
        f"{deploy_id}_{slug}_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}"
    )
    Path(files["precheck"]).write_text(build_precheck_sql(selected), encoding="utf-8")
    Path(files["apply"]).write_text(build_apply_sql(selected, backup_table), encoding="utf-8")
    Path(files["rollback"]).write_text(build_rollback_sql(selected, backup_table), encoding="utf-8")
    Path(files["postcheck"]).write_text(build_postcheck_sql(selected, backup_table), encoding="utf-8")

    family_counts = Counter(proposal["family_id"] for proposal in selected)
    expected_rules = [expected_rule_from_proposal(proposal) for proposal in selected]
    execution_scenarios = [
        scenario
        for rule in expected_rules
        for scenario in [execution_scenario_from_expected_rule(rule)]
        if scenario is not None
    ]
    manifest = {
        "generated_at": utc_now(),
        "status": "prepared_read_only_pending_apply_approval",
        "mutations_performed": [],
        "deploy_id": deploy_id,
        "slug": slug,
        "backup_table": f"manaloom_deploy_audit.{backup_table}",
        "selected_count": len(selected),
        "selected_card_names": [proposal["card_name"] for proposal in selected],
        "family_counts": dict(sorted(family_counts.items())),
        "expected_rules": expected_rules,
        "snapshot_checks": [snapshot_check_from_expected_rule(rule) for rule in expected_rules],
        "runtime_checks": [runtime_check_from_expected_rule(rule) for rule in expected_rules],
        "execution_scenarios": execution_scenarios,
        "files": files,
        "apply_gate": "Do not run apply SQL without explicit approval for the exact command.",
    }
    Path(files["manifest"]).write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    Path(files["package"]).write_text(markdown_package(manifest), encoding="utf-8")
    return manifest


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--proposal-report", required=True)
    parser.add_argument("--deploy-id", required=True)
    parser.add_argument("--slug", required=True)
    parser.add_argument("--output-prefix")
    parser.add_argument("--include-family", action="append", default=[])
    parser.add_argument("--include-card", action="append", default=[])
    parser.add_argument("--exclude-card", action="append", default=[])
    parser.add_argument("--max-cards", type=int)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    proposal_report = load_json(Path(args.proposal_report))
    stem = safe_ident(f"{args.deploy_id}_{args.slug}")
    output_prefix = Path(args.output_prefix or DEFAULT_REPORT_DIR / stem)
    output_prefix.parent.mkdir(parents=True, exist_ok=True)
    manifest = build_package(
        proposal_report,
        deploy_id=args.deploy_id,
        slug=args.slug,
        output_prefix=output_prefix,
        include_family=set(args.include_family or []),
        include_card=set(args.include_card or []),
        exclude_card=set(args.exclude_card or []),
        max_cards=args.max_cards,
    )
    print(f"manifest={manifest['files']['manifest']}")
    print(f"package={manifest['files']['package']}")
    print(f"selected_count={manifest['selected_count']}")
    print("mutations_performed=[]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
