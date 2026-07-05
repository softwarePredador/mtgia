#!/usr/bin/env python3
"""Prepare a review-only PostgreSQL package for Brain in a Jar.

This is the durable-rule handoff after the Brain in a Jar runtime adapter
exists. It writes precheck/apply/postcheck/rollback SQL plus a manifest, but it
does not connect to PostgreSQL, mutate Hermes SQLite, run battles, or touch
deck 607.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping

import battle_rule_registry


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_EXACT_CONTRACT = (
    REPORT_DIR
    / "lorehold_brain_in_a_jar_exact_runtime_contract_20260705_post_authorized_full_validation.json"
)
DEFAULT_PREFLIGHT = (
    REPORT_DIR
    / "lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_post_authorized_full_validation.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "lorehold_brain_in_a_jar_pg_package_preflight_20260705_post_authorized_full_validation"
)

BRAIN_NAME = "Brain in a Jar"
BRAIN_NORMALIZED = "brain in a jar"
BRAIN_ORACLE_TEXT = (
    "{1}, {T}: Put a charge counter on this artifact, then you may cast an instant "
    "or sorcery spell with mana value equal to the number of charge counters on "
    "this artifact from your hand without paying its mana cost.\n"
    "{3}, {T}, Remove X charge counters from this artifact: Scry X."
)
BRAIN_ORACLE_HASH = "41468898bf6400763de517269fdeb456"
BRAIN_SCRYFALL_ID = "88ecfcbe-e8db-4f08-aa8b-5b7b3e6c6ce7"
BRAIN_ORACLE_ID = "321dbd10-1d48-49fc-ba6a-1df241a53338"
BRAIN_SCOPE = "xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1"
TARGET_RUNTIME_PREFLIGHT_STATUS = (
    "brain_in_a_jar_runtime_cut_preflight_blocked_adapter_present_no_active_rule_no_safe_cut_keep_607"
)
LEGACY_TARGET_ROUTE_PLANNER_STATUS = "miracle_next_route_planner_selected_brain_package_review_keep_607"
TARGET_ROUTE_PLANNER_STATUS = (
    "miracle_next_route_planner_selected_brain_floor_protected_no_seed_safe_cut_keep_607"
)
TARGET_ROUTE_PLANNER_STATUSES = {TARGET_ROUTE_PLANNER_STATUS, LEGACY_TARGET_ROUTE_PLANNER_STATUS}
TARGET_NEXT_SHELL_STATUS = "next_shell_cut_path_closed_route_miracle_access_first_keep_607"
BACKUP_TABLE = (
    "manaloom_deploy_audit."
    "lorehold_brain_in_a_jar_pg_package_20260705_post_authorized_full_validation_backup"
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_dict(value: Any) -> dict[str, Any]:
    return dict(value) if isinstance(value, Mapping) else {}


def sql_quote(value: str) -> str:
    return "'" + str(value).replace("'", "''") + "'"


def json_sql(value: Mapping[str, Any]) -> str:
    return sql_quote(json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":"))) + "::jsonb"


def deck_role_json() -> dict[str, Any]:
    return {
        "category": "draw",
        "effect": "topdeck_manipulation",
        "lane": "topdeck_miracle_engine",
        "package": "topdeck_miracle_access",
    }


def source_rulings() -> dict[str, Any]:
    return {
        "scryfall_api_checked": True,
        "scryfall_id": BRAIN_SCRYFALL_ID,
        "oracle_id": BRAIN_ORACLE_ID,
        "oracle_hash": BRAIN_ORACLE_HASH,
        "oracle_text": BRAIN_ORACLE_TEXT,
        "rulings_to_preserve": [
            "the newly placed charge counter is counted for the first ability",
            "the cast is optional and casts at most one matching instant or sorcery from hand",
            "the spell is cast during Brain in a Jar ability resolution without paying mana cost",
            "alternative costs are not payable, additional costs can still matter, and X is zero unless another effect sets it",
        ],
    }


def build_proposed_rule(exact_contract: Mapping[str, Any]) -> dict[str, Any]:
    effect_json = as_dict(exact_contract.get("effect_json_contract"))
    if not effect_json:
        effect_json = {"effect": "topdeck_manipulation", "battle_model_scope": BRAIN_SCOPE}
    effect_json = dict(effect_json)
    effect_json.setdefault("effect", "topdeck_manipulation")
    effect_json.setdefault("battle_model_scope", BRAIN_SCOPE)
    effect_json.setdefault("source_card", BRAIN_NAME)
    effect_json.setdefault("free_cast_optional", True)
    effect_json.setdefault("free_cast_max_cards", 1)
    effect_json.setdefault("free_cast_timing", "during_brain_in_a_jar_ability_resolution")
    effect_json.setdefault("alternative_costs_payable", False)
    effect_json.setdefault("x_value_default_when_cast_without_paying_mana_cost", 0)
    effect_json.setdefault("additional_costs_policy", "runtime_followup_required_for_nontrivial_additional_costs")

    role_json = deck_role_json()
    logical_key = battle_rule_registry.logical_rule_key(
        {"effect_json": effect_json, "deck_role_json": role_json}
    )
    return {
        "normalized_name": BRAIN_NORMALIZED,
        "card_name": BRAIN_NAME,
        "oracle_hash": BRAIN_ORACLE_HASH,
        "logical_rule_key": logical_key,
        "effect_json": effect_json,
        "deck_role_json": role_json,
        "source": "curated",
        "confidence": 0.96,
        "review_status": "verified",
        "execution_status": "auto",
        "notes": (
            "Brain in a Jar exact runtime package: local XMage class plus ManaLoom "
            "adapter for add charge counter, exact mana-value free-cast from hand, "
            "and remove X charge counters to scry X. Package is prepared only; "
            "apply requires explicit PostgreSQL approval."
        ),
        "shadow_handling": "preserve_existing_rows",
    }


def proposed_values_sql(rule: Mapping[str, Any]) -> str:
    return (
        "WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, "
        "effect_json, deck_role_json, source, confidence, review_status, "
        "execution_status, notes, shadow_handling) AS (\n"
        "  VALUES\n"
        "    ("
        f"{sql_quote(str(rule['normalized_name']))}, "
        f"{sql_quote(str(rule['card_name']))}, "
        f"{sql_quote(str(rule['oracle_hash']))}, "
        f"{sql_quote(str(rule['logical_rule_key']))}, "
        f"{json_sql(as_dict(rule['effect_json']))}, "
        f"{json_sql(as_dict(rule['deck_role_json']))}, "
        f"{sql_quote(str(rule['source']))}, "
        f"{float(rule['confidence']):.2f}, "
        f"{sql_quote(str(rule['review_status']))}, "
        f"{sql_quote(str(rule['execution_status']))}, "
        f"{sql_quote(str(rule['notes']))}, "
        f"{sql_quote(str(rule['shadow_handling']))}"
        ")\n"
        ")"
    )


def build_precheck_sql(rule: Mapping[str, Any]) -> str:
    proposed = proposed_values_sql(rule)
    return f"""{proposed},
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name,
    c.oracle_id,
    c.scryfall_id
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
    min(db_card_name) AS canonical_card_name,
    min(oracle_id::text) AS canonical_oracle_id,
    min(scryfall_id::text) AS canonical_scryfall_id
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
same_scope_rows AS (
  SELECT p.normalized_name, count(r.*) AS active_same_scope_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.effect_json->>'battle_model_scope' = p.effect_json->>'battle_model_scope'
   AND r.review_status IN ('active', 'verified')
   AND r.execution_status IN ('auto', 'executable')
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.effect_json->>'battle_model_scope' AS battle_model_scope,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  tc.canonical_card_name,
  tc.canonical_oracle_id,
  tc.canonical_scryfall_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  ss.active_same_scope_rows_before
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN same_scope_rows ss USING (normalized_name)
ORDER BY p.card_name;
"""


def build_apply_sql(rule: Mapping[str, Any]) -> str:
    proposed = proposed_values_sql(rule)
    return f"""BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS {BACKUP_TABLE} AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = {sql_quote(BRAIN_NORMALIZED)}
   OR normalized_name LIKE {sql_quote(BRAIN_NORMALIZED + ' // %')};

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  {proposed},
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
    RAISE EXCEPTION 'Brain in a Jar package abort: expected at least one Oracle-hash-matched public.cards row: %', v_missing;
  END IF;
END $$;

{proposed},
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
    'codex-brain-in-a-jar',
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


def build_postcheck_sql(rule: Mapping[str, Any]) -> str:
    proposed = proposed_values_sql(rule)
    return f"""{proposed},
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status,
    r.effect_json,
    r.rule_version
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
  p.effect_json->>'battle_model_scope' AS expected_scope,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  count(r.*) FILTER (WHERE r.effect_json->>'battle_model_scope' = p.effect_json->>'battle_model_scope') AS promoted_scope_rows,
  count(r.*) FILTER (WHERE (r.effect_json->>'brain_in_a_jar_free_cast')::boolean IS TRUE) AS promoted_brain_free_cast_rows,
  count(r.*) FILTER (WHERE r.rule_version >= 2) AS promoted_rule_version_rows,
  (SELECT count(*) FROM {BACKUP_TABLE}) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash, expected_scope
ORDER BY p.card_name;
"""


def build_rollback_sql(rule: Mapping[str, Any]) -> str:
    key = str(rule["logical_rule_key"])
    return f"""BEGIN;

DELETE FROM public.card_battle_rules r
WHERE (
        r.normalized_name = {sql_quote(BRAIN_NORMALIZED)}
        OR r.normalized_name LIKE {sql_quote(BRAIN_NORMALIZED + ' // %')}
      )
  AND r.logical_rule_key = {sql_quote(key)};

INSERT INTO public.card_battle_rules
SELECT b.*
FROM {BACKUP_TABLE} b
WHERE NOT EXISTS (
  SELECT 1
  FROM public.card_battle_rules r
  WHERE r.normalized_name = b.normalized_name
    AND r.logical_rule_key = b.logical_rule_key
);

COMMIT;
"""


def runtime_preflight_governed(preflight: Mapping[str, Any]) -> bool:
    summary = as_dict(preflight.get("summary"))
    return (
        bool(preflight)
        and (preflight.get("status") or summary.get("decision_status")) == TARGET_RUNTIME_PREFLIGHT_STATUS
        and bool(summary.get("route_gate_valid"))
        and summary.get("route_planner_status") in TARGET_ROUTE_PLANNER_STATUSES
        and bool(summary.get("route_planner_candidate_queue_governed"))
        and summary.get("route_planner_candidate_queue_next_shell_status") == TARGET_NEXT_SHELL_STATUS
        and bool(summary.get("candidate_queue_matrix_route_governed"))
        and bool(summary.get("brain_exact_adapter_present"))
        and int(summary.get("brain_active_rule_count") or 0) == 0
        and int(summary.get("safe_cut_count") or 0) == 0
        and not bool(summary.get("postgres_writes_allowed_now"))
        and not bool(summary.get("deck_action_allowed_now"))
        and not bool(summary.get("natural_battle_gate_allowed_now"))
        and not bool(summary.get("promotion_allowed_now"))
    )


def package_status(exact_contract: Mapping[str, Any], preflight: Mapping[str, Any]) -> tuple[str, bool]:
    exact_summary = as_dict(exact_contract.get("summary"))
    adapter_present = bool(exact_summary.get("brain_exact_scope_adapter_present"))
    if not exact_contract or not exact_summary.get("contract_drafted"):
        return "blocked_missing_exact_runtime_contract", False
    if not adapter_present:
        return "blocked_adapter_missing_no_pg_package_apply", False
    if not runtime_preflight_governed(preflight):
        return "blocked_runtime_preflight_not_governed_keep_607", False
    return "prepared_read_only_pending_apply_approval", True


def recommended_next_action(status: str) -> str:
    if status == "prepared_read_only_pending_apply_approval":
        return "review_precheck_then_request_explicit_postgresql_apply_if_approved"
    if status == "blocked_missing_exact_runtime_contract":
        return "finish_exact_runtime_contract_before_pg_package"
    if status == "blocked_adapter_missing_no_pg_package_apply":
        return "finish_runtime_adapter_before_pg_package"
    if status == "blocked_runtime_preflight_not_governed_keep_607":
        return "rerun_governed_brain_runtime_cut_preflight_before_pg_package"
    return "finish_runtime_contract_and_adapter_before_pg_package"


def build_manifest(
    *,
    exact_contract: Mapping[str, Any],
    preflight: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    rule = build_proposed_rule(exact_contract)
    status, apply_ready = package_status(exact_contract, preflight)
    preflight_summary = as_dict(preflight.get("summary"))
    exact_summary = as_dict(exact_contract.get("summary"))
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_brain_in_a_jar_pg_package_preflight",
        "status": status,
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "source_reports": {name: rel(path) for name, path in paths.items()},
        "summary": {
            "decision_status": status,
            "apply_ready_for_manual_review": apply_ready,
            "apply_executed_by_this_script": False,
            "postgres_writes_allowed_now": False,
            "deck_action_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "brain_exact_adapter_present": bool(exact_summary.get("brain_exact_scope_adapter_present")),
            "runtime_preflight_required_status": TARGET_RUNTIME_PREFLIGHT_STATUS,
            "runtime_preflight_status": preflight.get("status")
            or preflight_summary.get("decision_status")
            or "",
            "runtime_preflight_route_gate_valid": bool(preflight_summary.get("route_gate_valid")),
            "runtime_preflight_route_planner_status": preflight_summary.get("route_planner_status"),
            "runtime_preflight_candidate_queue_governed": bool(
                preflight_summary.get("route_planner_candidate_queue_governed")
            ),
            "runtime_preflight_candidate_queue_next_shell_status": preflight_summary.get(
                "route_planner_candidate_queue_next_shell_status"
            ),
            "runtime_preflight_candidate_queue_matrix_route_governed": bool(
                preflight_summary.get("candidate_queue_matrix_route_governed")
            ),
            "brain_active_rule_count_before_apply": int(preflight_summary.get("brain_active_rule_count") or 0),
            "safe_cut_count_before_apply": int(preflight_summary.get("safe_cut_count") or 0),
            "logical_rule_key": rule["logical_rule_key"],
            "oracle_hash": rule["oracle_hash"],
            "battle_model_scope": as_dict(rule["effect_json"]).get("battle_model_scope"),
            "sql_file_count": 4,
            "recommended_next_action": recommended_next_action(status),
        },
        "proposed_rule": rule,
        "source_evidence": {
            "exact_runtime_contract_summary": exact_summary,
            "runtime_cut_preflight_summary": preflight_summary,
            "external_oracle_source": source_rulings(),
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "postgres_writes_allowed": False,
            "package_apply_requires_explicit_approval": True,
            "after_approved_apply_required_sequence": [
                "run_precheck_sql",
                "run_apply_sql",
                "run_postcheck_sql",
                "sync_postgresql_to_hermes_sqlite",
                "rerun_brain_runtime_cut_preflight",
                "mine_named_safe_cut_before_any_deck_candidate",
            ],
            "known_runtime_followup": (
                "Current Brain adapter handles the core exact mana-value free-cast and scry "
                "flow. Nontrivial additional costs and unusual X-spell choices remain explicit "
                "follow-up validation before using Brain as broad deck-quality proof."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = as_dict(payload.get("summary"))
    rule = as_dict(payload.get("proposed_rule"))
    source = as_dict(payload.get("source_evidence"))
    oracle = as_dict(source.get("external_oracle_source"))
    lines = [
        "# Lorehold Brain in a Jar PostgreSQL Package Preflight",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{payload['status']}`",
        f"- Apply ready for manual review: `{str(summary.get('apply_ready_for_manual_review')).lower()}`",
        f"- Apply executed by this script: `{str(summary.get('apply_executed_by_this_script')).lower()}`",
        f"- Brain exact adapter present: `{str(summary.get('brain_exact_adapter_present')).lower()}`",
        f"- Runtime preflight status: `{summary.get('runtime_preflight_status')}`",
        f"- Runtime preflight required status: `{summary.get('runtime_preflight_required_status')}`",
        f"- Runtime route gate valid: `{str(summary.get('runtime_preflight_route_gate_valid')).lower()}`",
        f"- Runtime route planner status: `{summary.get('runtime_preflight_route_planner_status')}`",
        "- Runtime candidate queue governed: "
        f"`{str(summary.get('runtime_preflight_candidate_queue_governed')).lower()}`",
        "- Runtime candidate queue next-shell status: "
        f"`{summary.get('runtime_preflight_candidate_queue_next_shell_status')}`",
        "- Runtime candidate queue matrix-route governed: "
        f"`{str(summary.get('runtime_preflight_candidate_queue_matrix_route_governed')).lower()}`",
        f"- Active Brain rule count before apply: `{summary.get('brain_active_rule_count_before_apply')}`",
        f"- Safe cut count before apply: `{summary.get('safe_cut_count_before_apply')}`",
        f"- Logical rule key: `{summary.get('logical_rule_key')}`",
        f"- Oracle hash: `{summary.get('oracle_hash')}`",
        f"- Battle model scope: `{summary.get('battle_model_scope')}`",
        f"- Recommended next action: `{summary.get('recommended_next_action')}`",
        "",
        "## Files",
        "",
    ]
    for name, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{name}`: `{path}`")
    lines.extend(
        [
            "",
            "## Proposed Rule",
            "",
            f"- card: `{rule.get('card_name')}`",
            f"- normalized_name: `{rule.get('normalized_name')}`",
            f"- review_status: `{rule.get('review_status')}`",
            f"- execution_status: `{rule.get('execution_status')}`",
            f"- source: `{rule.get('source')}`",
            f"- confidence: `{rule.get('confidence')}`",
            f"- shadow_handling: `{rule.get('shadow_handling')}`",
            "",
            "## Oracle Evidence",
            "",
            f"- Scryfall ID: `{oracle.get('scryfall_id')}`",
            f"- Oracle ID: `{oracle.get('oracle_id')}`",
            f"- Oracle hash: `{oracle.get('oracle_hash')}`",
            "- Rulings preserved:",
        ]
    )
    for ruling in oracle.get("rulings_to_preserve") or []:
        lines.append(f"  - {ruling}")
    decision = as_dict(payload.get("decision"))
    lines.extend(
        [
            "",
            "## Gates",
            "",
            f"- deck_action_allowed: `{str(decision.get('deck_action_allowed')).lower()}`",
            f"- natural_battle_allowed_now: `{str(decision.get('natural_battle_allowed_now')).lower()}`",
            f"- promotion_allowed: `{str(decision.get('promotion_allowed')).lower()}`",
            f"- postgres_writes_allowed: `{str(decision.get('postgres_writes_allowed')).lower()}`",
            f"- package_apply_requires_explicit_approval: `{str(decision.get('package_apply_requires_explicit_approval')).lower()}`",
            f"- known_runtime_followup: {decision.get('known_runtime_followup')}",
            "",
        ]
    )
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> dict[str, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    rule = as_dict(payload["proposed_rule"])
    files = {
        "precheck_sql": out_prefix.with_name(out_prefix.name + "_precheck.sql"),
        "apply_sql": out_prefix.with_name(out_prefix.name + "_apply.sql"),
        "rollback_sql": out_prefix.with_name(out_prefix.name + "_rollback.sql"),
        "postcheck_sql": out_prefix.with_name(out_prefix.name + "_postcheck.sql"),
        "manifest_json": out_prefix.with_suffix(".json"),
        "package_md": out_prefix.with_suffix(".md"),
    }
    files["precheck_sql"].write_text(build_precheck_sql(rule), encoding="utf-8")
    files["apply_sql"].write_text(build_apply_sql(rule), encoding="utf-8")
    files["rollback_sql"].write_text(build_rollback_sql(rule), encoding="utf-8")
    files["postcheck_sql"].write_text(build_postcheck_sql(rule), encoding="utf-8")
    enriched = dict(payload)
    enriched["source_reports"] = {
        **as_dict(payload.get("source_reports")),
        **{name: rel(path) for name, path in files.items() if name.endswith("_sql")},
    }
    files["manifest_json"].write_text(
        json.dumps(enriched, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    files["package_md"].write_text(render_markdown(enriched), encoding="utf-8")
    return files


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exact-contract", type=Path, default=DEFAULT_EXACT_CONTRACT)
    parser.add_argument("--preflight", type=Path, default=DEFAULT_PREFLIGHT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "exact_contract": args.exact_contract,
        "runtime_cut_preflight": args.preflight,
    }
    manifest = build_manifest(
        exact_contract=read_json(args.exact_contract),
        preflight=read_json(args.preflight),
        paths=paths,
    )
    files = write_outputs(manifest, args.out_prefix)
    for path in files.values():
        print(f"wrote {path}")
    print(json.dumps(manifest["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
