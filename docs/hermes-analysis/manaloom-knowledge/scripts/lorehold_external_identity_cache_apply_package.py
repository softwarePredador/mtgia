#!/usr/bin/env python3
"""Prepare a reviewed SQLite identity-cache apply package without executing it."""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_optimizer_common import normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_RESOLUTION_REPORT = REPORT_DIR / "lorehold_external_identity_resolution_queue_20260705_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_external_identity_cache_apply_package_20260705_current"
SOURCE_MARKER = "lorehold_external_identity_resolution_queue_20260705_current"


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


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def sql_quote(value: Any) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, (int, float)):
        return str(value)
    text = str(value).replace("'", "''")
    return f"'{text}'"


def json_sql(value: Any) -> str:
    return sql_quote(json.dumps(value if value is not None else [], ensure_ascii=False, separators=(",", ":")))


def ready_rows(resolution_report: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in as_list(resolution_report.get("resolution_rows")):
        if not isinstance(row, Mapping) or not row.get("cache_insert_ready"):
            continue
        lookup = row.get("lookup")
        if not isinstance(lookup, Mapping) or lookup.get("lookup_status") != "found":
            continue
        rows.append(dict(row))
    return sorted(rows, key=lambda row: normalize_name(str(row.get("card_name") or "")))


def cache_values(row: Mapping[str, Any]) -> dict[str, Any]:
    lookup = dict(row["lookup"])
    name = str(lookup.get("name") or row["card_name"])
    scryfall_id = lookup.get("scryfall_id")
    return {
        "normalized_name": normalize_name(name),
        "name": name,
        "mana_cost": lookup.get("mana_cost"),
        "colors_json": json.dumps(as_list(lookup.get("colors")), ensure_ascii=False, separators=(",", ":")),
        "color_identity_json": json.dumps(as_list(lookup.get("color_identity")), ensure_ascii=False, separators=(",", ":")),
        "type_line": lookup.get("type_line"),
        "oracle_text": lookup.get("oracle_text"),
        "cmc": lookup.get("cmc"),
        "power": None,
        "toughness": None,
        "keywords_json": json.dumps(as_list(lookup.get("keywords")), ensure_ascii=False, separators=(",", ":")),
        "scryfall_id": scryfall_id,
        "source": SOURCE_MARKER,
        "updated_at": "__UPDATED_AT__",
        "card_id": scryfall_id,
    }


def tuple_sql(values: Mapping[str, Any], *, updated_at: str) -> str:
    ordered = [
        values["normalized_name"],
        values["name"],
        values["mana_cost"],
        values["colors_json"],
        values["color_identity_json"],
        values["type_line"],
        values["oracle_text"],
        values["cmc"],
        values["power"],
        values["toughness"],
        values["keywords_json"],
        values["scryfall_id"],
        values["source"],
        updated_at,
        values["card_id"],
    ]
    return "(" + ", ".join(sql_quote(value) for value in ordered) + ")"


def name_list_sql(names: list[str]) -> str:
    return ", ".join(sql_quote(normalize_name(name)) for name in names)


def build_sql_files(rows: list[dict[str, Any]], *, updated_at: str) -> dict[str, str]:
    names = [str(row["card_name"]) for row in rows]
    normalized_names = name_list_sql(names)
    precheck = f"""-- Lorehold external identity cache precheck.
-- Expected before apply: existing_cache_rows = 0 for this package.
SELECT COUNT(*) AS existing_cache_rows
FROM card_oracle_cache
WHERE normalized_name IN ({normalized_names});

SELECT normalized_name, name, source, updated_at
FROM card_oracle_cache
WHERE normalized_name IN ({normalized_names})
ORDER BY normalized_name;
"""
    values = [cache_values(row) for row in rows]
    value_sql = ",\n  ".join(tuple_sql(value, updated_at=updated_at) for value in values)
    apply = f"""-- Lorehold external identity cache apply package.
-- Report-only generated SQL. Review before executing against local SQLite.
INSERT INTO card_oracle_cache (
  normalized_name,
  name,
  mana_cost,
  colors_json,
  color_identity_json,
  type_line,
  oracle_text,
  cmc,
  power,
  toughness,
  keywords_json,
  scryfall_id,
  source,
  updated_at,
  card_id
) VALUES
  {value_sql};
"""
    postcheck = f"""-- Lorehold external identity cache postcheck.
-- Expected after apply: resolved_cache_rows = {len(rows)}.
SELECT COUNT(*) AS resolved_cache_rows
FROM card_oracle_cache
WHERE normalized_name IN ({normalized_names})
  AND source = {sql_quote(SOURCE_MARKER)};

SELECT coc.normalized_name, coc.name, coc.card_id, coc.color_identity_json, cl.status AS commander_status
FROM card_oracle_cache coc
LEFT JOIN card_legalities cl
  ON lower(cl.card_name) = lower(coc.name)
 AND cl.format = 'commander'
WHERE coc.normalized_name IN ({normalized_names})
ORDER BY coc.normalized_name;
"""
    rollback = f"""-- Lorehold external identity cache rollback.
-- Deletes only rows inserted/updated by this package source marker.
DELETE FROM card_oracle_cache
WHERE normalized_name IN ({normalized_names})
  AND source = {sql_quote(SOURCE_MARKER)};

SELECT COUNT(*) AS remaining_package_cache_rows
FROM card_oracle_cache
WHERE normalized_name IN ({normalized_names})
  AND source = {sql_quote(SOURCE_MARKER)};
"""
    return {
        "precheck": precheck,
        "apply": apply,
        "postcheck": postcheck,
        "rollback": rollback,
    }


def build_payload(
    *,
    resolution_report: Mapping[str, Any],
    resolution_path: Path,
    sql_paths: Mapping[str, Path],
    rows: list[dict[str, Any]],
) -> dict[str, Any]:
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_external_identity_cache_apply_package",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "sqlite_apply_executed": False,
        "source_reports": {"identity_resolution_queue": rel(resolution_path)},
        "sql_files": {key: rel(path) for key, path in sql_paths.items()},
        "status": "external_identity_cache_apply_package_prepared_not_applied_keep_607",
        "summary": {
            "current_baseline": "deck_607",
            "cache_insert_ready_count": len(rows),
            "sqlite_apply_executed": False,
            "deck_test_ready_count": 0,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "recommended_next_action": "review_and_apply_sqlite_identity_cache_package_only_if_cache_update_is_approved",
        },
        "package_rows": [
            {
                "card_name": row["card_name"],
                "post_import_status": row["post_import_status"],
                "scryfall_id": row["lookup"].get("scryfall_id"),
                "oracle_id": row["lookup"].get("oracle_id"),
                "commander_legal": row["commander_legal"],
                "lorehold_color_identity_compatible": row["lorehold_color_identity_compatible"],
            }
            for row in rows
        ],
        "decision": {
            "keep_607_as_protected_baseline": True,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "next_actions": [
                "do_not_mutate_or_replace_deck_607",
                "review SQL precheck/apply/rollback before any SQLite cache update",
                "if applied, run postcheck and rerun identity/import preflight",
                "do not route shell-contract cards into one-for-one 607 swap gates",
            ],
            "reason": (
                "The package is ready for human/apply review, but it has not been "
                "executed. Identity cache readiness is not deck-quality or battle "
                "promotion evidence."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold External Identity Cache Apply Package",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Current baseline: `{summary['current_baseline']}`",
        f"- Source DB mutated: `{payload['source_db_mutated']}`",
        f"- SQLite apply executed: `{payload['sqlite_apply_executed']}`",
        "",
        "## SQL Files",
        "",
    ]
    for key, path in payload["sql_files"].items():
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(
        [
            "",
            "## Package Rows",
            "",
            "| Card | Post-Import Status | Commander | Color Fit |",
            "| --- | --- | ---: | ---: |",
        ]
    )
    for row in payload["package_rows"]:
        lines.append(
            f"| {row['card_name']} | `{row['post_import_status']}` | "
            f"`{row['commander_legal']}` | `{row['lorehold_color_identity_compatible']}` |"
        )
    decision = payload["decision"]
    lines.extend(
        [
            "",
            "## Decision",
            "",
            f"- Keep 607 as protected baseline: `{decision['keep_607_as_protected_baseline']}`",
            f"- Natural battle allowed now: `{decision['natural_battle_allowed_now']}`",
            f"- Promotion allowed: `{decision['promotion_allowed']}`",
            f"- Reason: {decision['reason']}",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--resolution-report", type=Path, default=DEFAULT_RESOLUTION_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    resolution_report = read_json(args.resolution_report)
    rows = ready_rows(resolution_report)
    generated_at = utc_now()
    sql_payloads = build_sql_files(rows, updated_at=generated_at)
    sql_paths = {
        "precheck": args.out_prefix.with_name(args.out_prefix.name + "_precheck.sql"),
        "apply": args.out_prefix.with_name(args.out_prefix.name + "_apply_sqlite.sql"),
        "postcheck": args.out_prefix.with_name(args.out_prefix.name + "_postcheck.sql"),
        "rollback": args.out_prefix.with_name(args.out_prefix.name + "_rollback_sqlite.sql"),
    }
    for key, path in sql_paths.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(sql_payloads[key], encoding="utf-8")
    payload = build_payload(
        resolution_report=resolution_report,
        resolution_path=args.resolution_report,
        sql_paths=sql_paths,
        rows=rows,
    )
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "cache_insert_ready_count": payload["summary"]["cache_insert_ready_count"],
                "sqlite_apply_executed": payload["summary"]["sqlite_apply_executed"],
            },
            ensure_ascii=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
