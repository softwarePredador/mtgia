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
    "count",
    "up_to_count",
    "destination",
    "enters_tapped",
    "exiles_self",
    "mode_selection",
    "recursion_components",
    "recursion_mana_value_max",
    "etb_recursion_target",
    "etb_recursion_count",
    "etb_recursion_destination",
    "etb_recursion_up_to_count",
    "etb_recursion_mana_value_max",
    "dies_recursion_target",
    "dies_recursion_count",
    "dies_recursion_destination",
    "dies_recursion_exclude_self",
    "graveyard_exile_target",
    "graveyard_exile_target_count",
    "graveyard_exile_destination",
    "graveyard_exile_up_to_count",
    "graveyard_exile_single_graveyard",
    "graveyard_self_return_to_hand",
    "graveyard_self_return_to_battlefield",
    "graveyard_self_return_destination",
    "graveyard_self_return_activation_cost_mana",
    "graveyard_self_return_activation_cost_generic",
    "graveyard_self_return_activation_cost_colors",
    "damage",
    "life_gain",
    "counter_type",
    "counter_amount",
    "keywords",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def sql_literal(value: Any) -> str:
    return "'" + str(value).replace("'", "''") + "'"


def sql_json(value: Any) -> str:
    return sql_literal(json.dumps(value, sort_keys=True, separators=(",", ":"))) + "::jsonb"


def safe_ident(value: str) -> str:
    ident = re.sub(r"[^a-z0-9_]+", "_", value.lower()).strip("_")
    if not ident:
        ident = "xmage_batch"
    if ident[0].isdigit():
        ident = "d_" + ident
    return ident[:56]


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

CREATE TABLE manaloom_deploy_audit.{backup_table} AS
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
        return value.split(".", 1)[1]
    return value


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
