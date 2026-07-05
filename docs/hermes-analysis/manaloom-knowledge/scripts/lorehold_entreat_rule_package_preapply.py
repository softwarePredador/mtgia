#!/usr/bin/env python3
"""Generate a review-only PostgreSQL package for Entreat the Angels."""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
XMAGE_PATH = Path("/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/e/EntreatTheAngels.java")

PACKAGE_ID = "pg472_lorehold_entreat_x_token_rule_20260705_current"
DEFAULT_OUT_PREFIX = REPORT_DIR / PACKAGE_ID
PREFLIGHT_REPORT = REPORT_DIR / "lorehold_entreat_x_token_runtime_preflight_20260705_current.json"

ORACLE_TEXT = (
    "Create X 4/4 white Angel creature tokens with flying.\n"
    "Miracle {X}{W}{W} (You may cast this card for its miracle cost when you draw it if it's the first card you drew this turn.)"
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def sql_literal(value: Any) -> str:
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def sql_json(value: Any) -> str:
    return sql_literal(json.dumps(value, ensure_ascii=True, sort_keys=True)) + "::jsonb"


def oracle_hash() -> str:
    return hashlib.md5(ORACLE_TEXT.encode("utf-8")).hexdigest()


def logical_rule_key() -> str:
    seed = "entreat the angels|xmage_x_create_creature_tokens_spell_v1|" + oracle_hash()
    return "battle_rule_v1:" + hashlib.md5(seed.encode("utf-8")).hexdigest()


def entreat_proposal() -> dict[str, Any]:
    effect_json = {
        "effect": "token_maker",
        "battle_model_scope": "xmage_x_create_creature_tokens_spell_v1",
        "ability_kind": "one_shot",
        "token_count_source": "x_value",
        "token_count_per_x": 1,
        "token_name": "Angel Token",
        "token_subtype": "Angel",
        "token_power": 4,
        "token_toughness": 4,
        "token_flying": True,
        "token_colors": ["W"],
        "x_spell": True,
        "normal_mana_cost": "{X}{X}{W}{W}{W}",
        "x_cost_symbol_count": 2,
        "miracle": True,
        "native_miracle": True,
        "miracle_cost": "{X}{W}{W}",
        "native_miracle_cost": "{X}{W}{W}",
        "miracle_x_cost_symbol_count": 1,
        "native_miracle_runtime_status": "blocked_requires_x_miracle_cast_plan",
        "sorcery": True,
        "xmage_effect_class": "CreateTokenEffect",
        "xmage_dynamic_value_class": "GetXValue",
        "xmage_token_class": "AngelToken",
        "xmage_ability_class": "MiracleAbility",
    }
    deck_role_json = {
        "category": "finisher",
        "effect": "token_maker",
        "subtype": "x_miracle_token_finisher",
        "lane": "miracle_finisher",
    }
    return {
        "normalized_name": "entreat the angels",
        "card_name": "Entreat the Angels",
        "mana_cost": "{X}{X}{W}{W}{W}",
        "oracle_text": ORACLE_TEXT,
        "oracle_hash": oracle_hash(),
        "logical_rule_key": logical_rule_key(),
        "effect_json": effect_json,
        "deck_role_json": deck_role_json,
        "source": "curated",
        "confidence": 0.91,
        "review_status": "needs_review",
        "execution_status": "review_only",
        "notes": (
            "PG472 review-only package: XMage exact class EntreatTheAngels uses CreateTokenEffect, "
            "AngelToken, GetXValue, and MiracleAbility. Normal XXWWW X-token runtime is covered, "
            "but native miracle XWW still requires an executable X miracle cast plan before auto execution."
        ),
        "shadow_handling": "preserve_existing_rows",
    }


def proposed_cte(proposal: dict[str, Any]) -> str:
    values = ", ".join(
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
            sql_literal(proposal["shadow_handling"]),
        ]
    )
    return (
        "WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, "
        "effect_json, deck_role_json, source, confidence, review_status, "
        "execution_status, notes, shadow_handling) AS (\n"
        f"  VALUES ({values})\n"
        ")"
    )


def render_precheck_sql(proposal: dict[str, Any]) -> str:
    return f"""{proposed_cte(proposal)},
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON lower(c.name) = p.normalized_name
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
)
SELECT
  p.card_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.review_status AS proposed_review_status,
  p.execution_status AS proposed_execution_status,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name);
"""


def render_apply_sql(proposal: dict[str, Any]) -> str:
    return f"""BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.{PACKAGE_ID} AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'entreat the angels';

DO $$
DECLARE
  v_target_rows int;
BEGIN
  {proposed_cte(proposal)},
  matched_cards AS (
    SELECT c.id
    FROM proposed p
    JOIN public.cards c
      ON lower(c.name) = p.normalized_name
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  )
  SELECT count(*) INTO v_target_rows FROM matched_cards;

  IF v_target_rows <> 1 THEN
    RAISE EXCEPTION 'PG472 precondition failed: Entreat target card rows=% expected 1', v_target_rows;
  END IF;
END $$;

{proposed_cte(proposal)},
matched_cards AS (
  SELECT
    p.*,
    c.id AS card_id,
    c.name AS db_card_name
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
    1,
    oracle_hash,
    notes,
    'codex-lorehold-pg472',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM matched_cards
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
SELECT count(*) AS review_only_upserted_rows FROM upserted;

COMMIT;
"""


def render_rollback_sql(proposal: dict[str, Any]) -> str:
    key = proposal["logical_rule_key"]
    return f"""BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'entreat the angels'
  AND logical_rule_key = {sql_literal(key)};

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.{PACKAGE_ID}
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
  execution_status = EXCLUDED.execution_status;

COMMIT;
"""


def render_postcheck_sql(proposal: dict[str, Any]) -> str:
    return f"""{proposed_cte(proposal)}
SELECT
  p.card_name,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS package_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'needs_review' AND r.execution_status = 'review_only') AS review_only_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS oracle_hash_rows
FROM proposed p
LEFT JOIN public.card_battle_rules r
  ON r.normalized_name = p.normalized_name
GROUP BY p.card_name, p.oracle_hash, p.logical_rule_key;
"""


def render_markdown(payload: dict[str, Any]) -> str:
    proposal = payload["proposal"]
    lines = [
        "# PG472 Lorehold Entreat X-Token Rule Package",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- PostgreSQL writes executed: `{payload['postgres_writes_executed']}`",
        f"- Deck 607 mutated: `{payload['deck_607_mutated']}`",
        f"- Proposed review status: `{proposal['review_status']}`",
        f"- Proposed execution status: `{proposal['execution_status']}`",
        f"- Logical rule key: `{proposal['logical_rule_key']}`",
        "",
        "## Rule Shape",
        "",
        f"- Effect: `{proposal['effect_json']['effect']}`",
        f"- Scope: `{proposal['effect_json']['battle_model_scope']}`",
        f"- Normal cost: `{proposal['effect_json']['normal_mana_cost']}`",
        f"- Native miracle cost: `{proposal['effect_json']['native_miracle_cost']}`",
        f"- Token count source: `{proposal['effect_json']['token_count_source']}`",
        f"- Runtime blocker: `{proposal['effect_json']['native_miracle_runtime_status']}`",
        "",
        "## Generated Files",
        "",
    ]
    for key, path in payload["generated_files"].items():
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(
        [
            "",
            "## Decision",
            "",
            "- This package is intentionally `review_only`.",
            "- Normal X-token casting is covered by runtime tests.",
            "- Native miracle XWW casting is not executable yet, so this must not become a natural 607 battle gate.",
        ]
    )
    return "\n".join(lines) + "\n"


def build_payload(out_prefix: Path) -> dict[str, Any]:
    proposal = entreat_proposal()
    base = out_prefix
    generated = {
        "manifest_json": rel(base.with_suffix(".json")),
        "markdown": rel(base.with_suffix(".md")),
        "precheck_sql": rel(base.with_name(base.name + "_precheck.sql")),
        "apply_sql": rel(base.with_name(base.name + "_apply.sql")),
        "rollback_sql": rel(base.with_name(base.name + "_rollback.sql")),
        "postcheck_sql": rel(base.with_name(base.name + "_postcheck.sql")),
    }
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_entreat_rule_package_preapply",
        "status": "review_only_package_generated_no_apply_keep_607",
        "postgres_writes_executed": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "proposal": proposal,
        "source_evidence": {
            "xmage_path": str(XMAGE_PATH),
            "runtime_preflight_report": rel(PREFLIGHT_REPORT),
            "external_oracle_confirmation": [
                "Gatherer search result confirms official Entreat card text surface.",
                "Scryfall exact-card search confirms normal cost XXWWW and miracle XWW.",
            ],
        },
        "generated_files": generated,
        "decision": {
            "keep_607_as_protected_baseline": True,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "The normal X-token runtime is available, but native miracle {X}{W}{W} still needs "
                "an executable X miracle cast plan before this can be auto or used in 607 battle gates."
            ),
        },
    }


def write_outputs(payload: dict[str, Any], out_prefix: Path) -> None:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    proposal = payload["proposal"]
    out_prefix.with_suffix(".json").write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    out_prefix.with_suffix(".md").write_text(render_markdown(payload), encoding="utf-8")
    out_prefix.with_name(out_prefix.name + "_precheck.sql").write_text(render_precheck_sql(proposal), encoding="utf-8")
    out_prefix.with_name(out_prefix.name + "_apply.sql").write_text(render_apply_sql(proposal), encoding="utf-8")
    out_prefix.with_name(out_prefix.name + "_rollback.sql").write_text(render_rollback_sql(proposal), encoding="utf-8")
    out_prefix.with_name(out_prefix.name + "_postcheck.sql").write_text(render_postcheck_sql(proposal), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(args.out_prefix)
    write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "manifest": str(args.out_prefix.with_suffix(".json")),
                "review_status": payload["proposal"]["review_status"],
                "execution_status": payload["proposal"]["execution_status"],
                "postgres_writes_executed": payload["postgres_writes_executed"],
            },
            ensure_ascii=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
