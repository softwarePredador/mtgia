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
    "creature_filter",
    "permanent_type",
    "counter_unless_pays_generic",
    "power_delta",
    "toughness_delta",
    "power_boost",
    "toughness_boost",
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
    "put_land_from_hand",
    "put_land_tapped",
    "count_from_x",
    "target_count_from_x",
    "target_player_draw",
    "target_count_min",
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
    "etb_damage_amount",
    "etb_damage_target",
    "etb_remove_effect",
    "etb_remove_target",
    "etb_treasure_count",
    "etb_token_count",
    "token_count",
    "token_count_source",
    "token_count_per_x",
    "token_component_count",
    "token_total_count",
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
    "etb_tutor_target",
    "etb_tutor_count",
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
    "life_gain",
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
    "ability_kind",
    "activated_effect",
    "activated_battle_model_scope",
    "activated_add_counters",
    "activated_add_counters_target",
    "activated_add_counters_counter_type",
    "activated_add_counters_count",
    "activated_damage_amount",
    "activated_draw",
    "activated_draw_discard",
    "activated_draw_count",
    "activated_discard_count",
    "activated_self_sacrifice_draw",
    "activated_self_sacrifice_draw_discard",
    "activation_cost_mana",
    "activation_cost_generic",
    "activation_cost_colors",
    "activation_requires_tap",
    "activation_requires_sacrifice",
    "activation_life_cost",
    "activation_discard_count",
    "activation_discard_target",
    "activation_requires_discard_card",
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
    "flashback_cost",
    "flashback_status",
    "cycling_cost",
    "cycling_status",
    "xmage_auxiliary_ability_classes",
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
    "static_power_bonus_per_graveyard_count",
    "static_toughness_bonus_per_graveyard_count",
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
    return {
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
        "logical_rule_key": rule["logical_rule_key"],
    }


def fixed_create_creature_tokens_execution_scenario_from_expected_rule(
    rule: dict[str, Any],
) -> dict[str, Any] | None:
    required = dict(rule.get("required_effect_fields") or {})
    if required.get("battle_model_scope") != "xmage_fixed_create_creature_tokens_spell_v1":
        return None
    return {
        "name": f"{rule['card_name']} creates modeled creature tokens",
        "type": "fixed_create_creature_tokens",
        "card": {"name": rule["card_name"]},
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
        "logical_rule_key": rule["logical_rule_key"],
    }


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


def execution_scenario_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any] | None:
    return (
        static_global_pt_execution_scenario_from_expected_rule(rule)
        or aura_static_pt_execution_scenario_from_expected_rule(rule)
        or destroy_target_create_treasure_execution_scenario_from_expected_rule(rule)
        or creature_etb_create_treasure_execution_scenario_from_expected_rule(rule)
        or fixed_create_creature_tokens_execution_scenario_from_expected_rule(rule)
        or multi_create_creature_tokens_execution_scenario_from_expected_rule(rule)
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
