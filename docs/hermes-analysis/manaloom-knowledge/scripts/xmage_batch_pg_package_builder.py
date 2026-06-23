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


DEFAULT_REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"


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
                    sql_json(proposal["deck_role_json"]),
                    sql_literal(proposal["source"]),
                    str(float(proposal["confidence"])),
                    sql_literal(proposal["review_status"]),
                    sql_literal(proposal["execution_status"]),
                    sql_literal(proposal["notes"]),
                ]
            )
            + ")"
        )
    return ",\n    ".join(rows)


def proposed_cte(proposals: list[dict[str, Any]]) -> str:
    return (
        "proposed(normalized_name, card_name, oracle_hash, logical_rule_key, "
        "effect_json, deck_role_json, source, confidence, review_status, "
        "execution_status, notes) AS (\n  VALUES\n    "
        + values_rows(proposals)
        + "\n)"
    )


def build_precheck_sql(proposals: list[dict[str, Any]]) -> str:
    return f"""WITH {proposed_cte(proposals)},
target_cards AS (
  SELECT p.normalized_name, count(c.id) AS target_card_rows
  FROM proposed p
  LEFT JOIN public.cards c
    ON lower(c.name) = p.normalized_name
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  GROUP BY p.normalized_name
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
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
  tc.target_card_rows,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
"""


def build_apply_sql(proposals: list[dict[str, Any]], backup_table: str) -> str:
    names = ", ".join(sql_literal(proposal["normalized_name"]) for proposal in proposals)
    return f"""BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.{backup_table} AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ({names});

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH {proposed_cte(proposals)},
  counts AS (
    SELECT p.card_name, p.normalized_name, p.oracle_hash, count(c.id) AS target_card_rows
    FROM proposed p
    LEFT JOIN public.cards c
      ON lower(c.name) = p.normalized_name
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows <> 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected exactly one Oracle-hash-matched card row for every proposed card: %', v_missing;
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
  WHERE r.normalized_name = p.normalized_name
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH {proposed_cte(proposals)},
target_cards AS (
  SELECT p.*, c.id AS card_id, c.name AS db_card_name
  FROM proposed p
  JOIN public.cards c
    ON lower(c.name) = p.normalized_name
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
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
  FROM target_cards
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
    names = ", ".join(sql_literal(proposal["normalized_name"]) for proposal in proposals)
    return f"""BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ({names});

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.{backup_table};

COMMIT;
"""


def build_postcheck_sql(proposals: list[dict[str, Any]], backup_table: str) -> str:
    return f"""WITH {proposed_cte(proposals)},
rule_rows AS (
  SELECT p.normalized_name, p.card_name, p.logical_rule_key, p.oracle_hash, r.*
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
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
LEFT JOIN rule_rows r USING (normalized_name, card_name, logical_rule_key, oracle_hash)
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
"""


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

    backup_table = safe_ident(f"{deploy_id}_{slug}_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}")
    files = {
        "precheck": f"{output_prefix}_precheck.sql",
        "apply": f"{output_prefix}_apply.sql",
        "rollback": f"{output_prefix}_rollback.sql",
        "postcheck": f"{output_prefix}_postcheck.sql",
        "manifest": f"{output_prefix}_manifest.json",
        "package": f"{output_prefix}_package.md",
    }
    Path(files["precheck"]).write_text(build_precheck_sql(selected), encoding="utf-8")
    Path(files["apply"]).write_text(build_apply_sql(selected, backup_table), encoding="utf-8")
    Path(files["rollback"]).write_text(build_rollback_sql(selected, backup_table), encoding="utf-8")
    Path(files["postcheck"]).write_text(build_postcheck_sql(selected, backup_table), encoding="utf-8")

    family_counts = Counter(proposal["family_id"] for proposal in selected)
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
