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
    "power_delta",
    "toughness_delta",
    "power_boost",
    "toughness_boost",
    "blocker_count_mode",
    "duration",
    "granted_keywords_until_eot",
    "additional_cost",
    "requires_sacrifice_creature",
    "requires_sacrifice_artifact_or_creature",
    "requires_sacrifice_land",
    "xmage_additional_cost_class",
    "xmage_additional_cost_target",
    "count",
    "draw_count",
    "discard_count",
    "draw_discard_order",
    "put_land_from_hand",
    "put_land_tapped",
    "count_from_x",
    "target_count_from_x",
    "target_player_draw",
    "target_count",
    "target_count_min",
    "target_count_max",
    "max_targets",
    "up_to_count",
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
    "mode_selection",
    "_composite_rule_components",
    "recursion_components",
    "recursion_mana_value_max",
    "recursion_mana_value_max_from_x",
    "target_mana_value_max_from_x",
    "pre_recursion_mill_count",
    "etb_draw_count",
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
    "etb_token_name",
    "etb_token_power",
    "etb_token_toughness",
    "etb_token_subtype",
    "etb_token_colors",
    "etb_token_keywords",
    "etb_token_flying",
    "etb_token_haste",
    "etb_token_tapped",
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
    "dies_token_count",
    "dies_token_name",
    "dies_token_power",
    "dies_token_toughness",
    "dies_token_subtype",
    "dies_token_colors",
    "dies_token_keywords",
    "dies_token_flying",
    "dies_token_haste",
    "dies_token_tapped",
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
    "dies_mana_produced",
    "dies_produces",
    "dies_produced_mana_symbols",
    "combat_damage_player_draw",
    "combat_damage_draw_count",
    "combat_damage_draw_optional",
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
    "exile_if_dies_from_damage",
    "exile_if_dies_target",
    "damage_scope",
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
    "destroy_mana_value_gte",
    "destroy_power_lte",
    "destroy_power_gte",
    "destroy_toughness_lte",
    "destroy_toughness_gte",
    "sacrifice_count",
    "sacrifice_card_types",
    "sacrifice_scope",
    "sacrifice_choice",
    "sacrifice_requires_multicolored",
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
    "mana_activation_requires_tap",
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
    "ability_kind",
    "activated_effect",
    "activated_battle_model_scope",
    "activated_remove_effect",
    "activated_remove_target",
    "activated_tap_target",
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
    "activation_discard_count",
    "activation_discard_target",
    "activation_requires_discard_card",
    "activation_discard_random",
    "activation_zone",
    "activation_requires_exile_source_from_graveyard",
    "activation_sacrifice_target",
    "activation_requires_sacrifice_target",
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
    "protection_from_card_types",
    "protection_from_subtypes",
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
    return {
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
    }


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
    }
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
        expected_tokens.append(
            {
                "name": component.get("token_name"),
                "count": int(component.get("token_count") or 1),
                "power": component.get("token_power"),
                "toughness": component.get("token_toughness"),
                "subtype": component.get("token_subtype"),
                "colors": component.get("token_colors") or [],
                "keywords": component.get("token_keywords") or [],
                "artifact": bool(component.get("artifact_tokens")),
            }
        )
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
        nonmatching_spell = {
            "name": f"E2E Nonmatching Green Spell for {rule['card_name']}",
            "type_line": "Sorcery",
            "colors": ["G"],
            "effect": "draw_cards",
            "cmc": 2,
        }
    source_effect = required.get("effect") or "life_gain_engine"
    source_type_line = "Creature - Cleric" if source_effect == "creature" else "Enchantment"
    return {
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
    }
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
    return {
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


def simple_mana_source_execution_scenario_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("effect") != "ramp_permanent" or not required.get("is_mana_source"):
        return None
    if required.get("battle_model_scope") not in {
        "xmage_simple_tap_mana_source_permanent_v1",
        "xmage_simple_tap_mana_source_with_activated_draw_v1",
        "xmage_simple_mana_source_with_etb_draw_v1",
    }:
        return None
    mana_produced = int(required.get("mana_produced") or 0)
    if mana_produced <= 0:
        return None
    controller_mana = _manifest_mana_for_activation_cost(required.get("activation_mana_cost"))
    activation_cost_total = sum(controller_mana.values())
    support_sources = _manifest_support_sources_for_controller_mana(controller_mana)
    enters_tapped = bool(required.get("enters_tapped"))
    activation_life_cost = int(required.get("activation_life_cost") or 0)
    scenario = {
        "name": f"{rule['card_name']} refreshes modeled mana source",
        "type": "simple_mana_source_refresh",
        "card": {"name": rule["card_name"]},
        "controller_mana": controller_mana,
        "expected_available_mana_after_refresh": (
            activation_cost_total if enters_tapped else mana_produced
        ),
        "expected_tapped": (
            enters_tapped or bool(required.get("mana_activation_requires_tap", True))
        ),
        "expected_sources": len(support_sources) + (0 if enters_tapped else 1),
        "expected_produced_mana_symbols": required.get("produced_mana_symbols") or [],
        "expected_conditional_mana": (
            mana_produced
            if _manifest_has_multiple_mana_choices(required.get("produces"))
            and not required.get("produced_mana_symbols")
            and not enters_tapped
            else 0
        ),
        "expected_activation_limit_per_turn": int(required.get("activation_limit_per_turn") or 0),
        "support_mana_sources": support_sources,
        "source_overrides": {"tapped": True} if enters_tapped else {},
        "logical_rule_key": rule["logical_rule_key"],
    }
    if activation_life_cost:
        scenario["starting_life"] = 40
        scenario["expected_life_paid"] = activation_life_cost
        scenario["expected_life_after_refresh"] = 40 - activation_life_cost
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
    return {
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
    return scenario


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
    return {
        "name": f"{rule['card_name']} activates add counters ability",
        "type": "simple_activated_add_counters_target",
        "card": {"name": rule["card_name"]},
        "controller_mana": _manifest_mana_for_required_activation(required),
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_target": target,
        "expected_counter_type": required.get("activated_add_counters_counter_type") or required.get("counter_type"),
        "expected_counter_count": int(
            required.get("activated_add_counters_count")
            or required.get("counter_count")
            or required.get("count")
            or 1
        ),
        "target": target_fixture,
        "logical_rule_key": rule["logical_rule_key"],
    }


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
    sacrifice_target_type = str(required.get("activation_sacrifice_target") or "").strip().lower()
    if required.get("activation_requires_sacrifice_target") or sacrifice_target_type:
        sacrifice_card_type = "creature" if sacrifice_target_type == "creature" else "permanent"
        scenario["sacrifice_target"] = _target_fixture_from_constraints(
            "E2E Activated Destroy Sacrifice Target",
            {"card_types": [sacrifice_card_type]},
            matching=True,
        )
        scenario["expect_target_sacrificed"] = True
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
    return {
        "name": f"{rule['card_name']} activates self boost ability",
        "type": "simple_activated_self_boost",
        "card": {
            "name": rule["card_name"],
            "type_line": "Creature - Soldier",
            "power": 2,
            "toughness": 2,
        },
        "controller_mana": _manifest_mana_for_required_activation(required),
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_power_delta": int(required.get("power_delta") or required.get("power_boost") or 0),
        "expected_toughness_delta": int(
            required.get("toughness_delta") or required.get("toughness_boost") or 0
        ),
        "expected_activation_limit_per_turn": int(required.get("activation_limit_per_turn") or 0),
        "logical_rule_key": rule["logical_rule_key"],
    }


def simple_activated_regenerate_source_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_permanent_simple_activated_regenerate_source_v1":
        return None
    return {
        "name": f"{rule['card_name']} activates regenerate source ability",
        "type": "simple_activated_regenerate_source",
        "card": {"name": rule["card_name"]},
        "controller_mana": _manifest_mana_for_required_activation(required),
        "expected_tapped_source": bool(required.get("activation_requires_tap")),
        "expected_regeneration_shields": 1,
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
    }:
        return None
    type_line = "Sorcery" if required.get("sorcery") is True else "Instant"
    return {
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
    if required.get("battle_model_scope") != "xmage_each_player_sacrifice_fixed_permanents_spell_v1":
        return None
    card_types = list(required.get("sacrifice_card_types") or ["creature"])
    sacrifice_count = max(1, int(required.get("sacrifice_count") or 1))
    return {
        "name": f"{rule['card_name']} each player sacrifices matching permanents",
        "type": "each_player_sacrifice",
        "card": {"name": rule["card_name"], "type_line": "Sorcery"},
        "sacrifice_count": sacrifice_count,
        "sacrifice_card_types": card_types,
        "sacrifice_requires_multicolored": bool(required.get("sacrifice_requires_multicolored")),
        "expected_sacrificed_per_player": sacrifice_count,
        "logical_rule_key": rule["logical_rule_key"],
    }


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

    subtypes = [str(value).lower() for value in active_constraints.get("required_subtypes") or [] if value]
    if not matching and active_constraints.get("exclude_subtypes"):
        subtypes = [str((active_constraints.get("exclude_subtypes") or ["spirit"])[0]).strip().lower()]
    type_line = _type_line_for_fixture(card_type, subtypes)
    if excluded_supertype:
        type_line = f"{excluded_supertype.title()} {type_line}"
    fixture = {
        "name": name,
        "type_line": type_line,
        "effect": "creature" if card_type == "creature" else card_type,
        "cmc": mana_value,
    }
    if "creature" in card_type:
        fixture["power"] = power
        fixture["toughness"] = toughness
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
    combat_state = str(active_constraints.get("combat_state") or "").strip().lower()
    if matching and combat_state:
        if combat_state in {"attacking", "attacking_or_blocking"}:
            fixture["attacking"] = True
        if combat_state in {"blocking", "attacking_or_blocking"}:
            fixture["blocking"] = True
    tapped_state = str(active_constraints.get("tapped_state") or active_constraints.get("tap_state") or "").strip().lower()
    if tapped_state:
        fixture["tapped"] = bool(matching and tapped_state == "tapped") or bool(
            not matching and tapped_state == "untapped"
        )
    return fixture


def single_target_removal_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_exile_target_spell_v1",
        "xmage_destroy_target_spell_v1",
        "xmage_destroy_target_and_controller_gain_life_spell_v1",
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
    return scenario


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


def multi_target_removal_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") not in {
        "xmage_exile_target_spell_v1",
        "xmage_destroy_target_spell_v1",
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
    return {
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


def multi_target_damage_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_fixed_multi_target_damage_spell_v1":
        return None
    if required.get("effect") != "multi_target_damage":
        return None
    total_damage = int(required.get("amount") or required.get("damage") or 0)
    target_count = int(required.get("target_count_max") or required.get("max_targets") or required.get("target_count") or 1)
    if total_damage <= 1 or target_count <= 1:
        return None
    target_count = max(2, min(target_count, total_damage, 3))
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
        "name": f"{rule['card_name']} divides {total_damage} damage",
        "type": "multi_target_damage",
        "card": {
            "name": rule["card_name"],
            "type_line": "Sorcery" if required.get("sorcery") is True else "Instant",
        },
        "targets": targets,
        "nonmatching_target": nonmatching,
        "expected_total_damage": total_damage,
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
        or required.get("battle_model_scope") != "xmage_counter_target_spell_unless_controller_pays_generic_v1"
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
        "logical_rule_key": rule["logical_rule_key"],
    }


def execution_scenario_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any] | None:
    return (
        counter_unless_pays_execution_scenario_from_expected_rule(rule)
        or static_controlled_pt_execution_scenario_from_expected_rule(rule)
        or static_controlled_keyword_execution_scenario_from_expected_rule(rule)
        or static_global_pt_execution_scenario_from_expected_rule(rule)
        or aura_static_pt_execution_scenario_from_expected_rule(rule)
        or static_count_pt_execution_scenario_from_expected_rule(rule)
        or destroy_target_create_treasure_execution_scenario_from_expected_rule(rule)
        or creature_etb_create_treasure_execution_scenario_from_expected_rule(rule)
        or creature_dies_create_treasure_execution_scenario_from_expected_rule(rule)
        or creature_etb_create_tokens_execution_scenario_from_expected_rule(rule)
        or creature_etb_scry_execution_scenario_from_expected_rule(rule)
        or creature_etb_library_pick_execution_scenario_from_expected_rule(rule)
        or creature_dies_create_tokens_execution_scenario_from_expected_rule(rule)
        or simple_mana_source_execution_scenario_from_expected_rule(rule)
        or sacrifice_mana_source_execution_scenario_from_expected_rule(rule)
        or damage_each_opponent_spell_execution_scenario_from_expected_rule(rule)
        or damage_gain_life_spell_execution_scenario_from_expected_rule(rule)
        or simple_activated_draw_execution_scenario_from_expected_rule(rule)
        or simple_activated_damage_execution_scenario_from_expected_rule(rule)
        or simple_activated_tap_target_execution_scenario_from_expected_rule(rule)
        or simple_activated_add_counters_target_execution_scenario_from_expected_rule(rule)
        or simple_activated_destroy_execution_scenario_from_expected_rule(rule)
        or simple_activated_self_boost_execution_scenario_from_expected_rule(rule)
        or simple_activated_self_keyword_execution_scenario_from_expected_rule(rule)
        or simple_activated_regenerate_source_execution_scenario_from_expected_rule(rule)
        or simple_activated_target_keyword_execution_scenario_from_expected_rule(rule)
        or controlled_stat_modifier_execution_scenario_from_expected_rule(rule)
        or target_keyword_spell_execution_scenario_from_expected_rule(rule)
        or boost_scry_spell_execution_scenario_from_expected_rule(rule)
        or attack_self_boost_execution_scenario_from_expected_rule(rule)
        or becomes_blocked_self_boost_execution_scenario_from_expected_rule(rule)
        or each_player_sacrifice_execution_scenario_from_expected_rule(rule)
        or multi_target_damage_execution_scenario_from_expected_rule(rule)
        or multi_target_removal_execution_scenario_from_expected_rule(rule)
        or single_target_removal_and_surveil_execution_scenario_from_expected_rule(rule)
        or single_target_removal_execution_scenario_from_expected_rule(rule)
        or simple_activated_create_token_execution_scenario_from_expected_rule(rule)
        or fixed_create_creature_tokens_execution_scenario_from_expected_rule(rule)
        or multi_create_creature_tokens_execution_scenario_from_expected_rule(rule)
        or dynamic_life_gain_execution_scenario_from_expected_rule(rule)
        or creature_etb_dynamic_life_gain_execution_scenario_from_expected_rule(rule)
        or creature_enters_life_gain_execution_scenario_from_expected_rule(rule)
        or creature_enters_draw_execution_scenario_from_expected_rule(rule)
        or creature_etb_draw_discard_execution_scenario_from_expected_rule(rule)
        or creature_etb_target_stat_modifier_execution_scenario_from_expected_rule(rule)
        or spell_cast_gain_life_execution_scenario_from_expected_rule(rule)
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
