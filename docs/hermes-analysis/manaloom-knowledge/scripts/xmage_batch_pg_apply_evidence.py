#!/usr/bin/env python3
"""Run a generated XMage batch PG package and write apply evidence.

The package builder emits read-only SQL files until a human/operator approves
the exact deploy. This runner is the repeatable apply lane after that approval:
precheck -> apply -> postcheck -> JSON/Markdown evidence.
"""

from __future__ import annotations

import argparse
import json
from datetime import date, datetime, timezone
from decimal import Decimal
from pathlib import Path
from typing import Any
from uuid import UUID

import db_helper


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Actually run the package apply SQL. Without this the command aborts.",
    )
    parser.add_argument("--output-json")
    parser.add_argument("--output-md")
    return parser.parse_args()


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def json_default(value: Any) -> Any:
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if isinstance(value, Decimal):
        if value == value.to_integral_value():
            return int(value)
        return float(value)
    if isinstance(value, UUID):
        return str(value)
    return str(value)


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def resolve_manifest_file(manifest: dict[str, Any], key: str) -> Path:
    files = manifest.get("files") or {}
    path = files.get(key)
    if not path:
        raise ValueError(f"manifest files.{key} is missing")
    return Path(path)


def fetch_rows(conn: Any, sql_path: Path) -> list[dict[str, Any]]:
    with conn.cursor() as cur:
        cur.execute(sql_path.read_text(encoding="utf-8"))
        columns = [desc[0] for desc in (cur.description or [])]
        if not columns:
            return []
        return [dict(zip(columns, row)) for row in cur.fetchall()]


def run_apply(conn: Any, sql_path: Path) -> None:
    with conn.cursor() as cur:
        cur.execute(sql_path.read_text(encoding="utf-8"))


def int_value(value: Any) -> int:
    if value is None:
        return 0
    return int(value)


def summarize_precheck(rows: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "row_count": len(rows),
        "cards": [row.get("card_name") for row in rows],
        "missing_targets": [
            row.get("card_name")
            for row in rows
            if int_value(row.get("target_card_rows")) < 1
        ],
        "total_target_card_rows": sum(int_value(row.get("target_card_rows")) for row in rows),
        "existing_expected_rows_before": sum(
            int_value(row.get("expected_rule_rows_before")) for row in rows
        ),
        "would_deprecate_shadow_rows": sum(
            int_value(row.get("would_deprecate_shadow_rows")) for row in rows
        ),
    }


def summarize_postcheck(rows: list[dict[str, Any]]) -> dict[str, Any]:
    failed_cards: list[str] = []
    for row in rows:
        if (
            int_value(row.get("promoted_rule_rows")) < 1
            or int_value(row.get("promoted_verified_auto_rows")) < 1
            or int_value(row.get("promoted_oracle_hash_rows")) < 1
        ):
            failed_cards.append(str(row.get("card_name")))
    return {
        "row_count": len(rows),
        "cards": [row.get("card_name") for row in rows],
        "failed_cards": failed_cards,
        "promoted_rule_rows": sum(int_value(row.get("promoted_rule_rows")) for row in rows),
        "promoted_verified_auto_rows": sum(
            int_value(row.get("promoted_verified_auto_rows")) for row in rows
        ),
        "promoted_oracle_hash_rows": sum(
            int_value(row.get("promoted_oracle_hash_rows")) for row in rows
        ),
        "backup_rows": max((int_value(row.get("backup_rows")) for row in rows), default=0),
    }


def write_markdown(path: Path, report: dict[str, Any]) -> None:
    lines = [
        f"# {report['deploy_id']} PostgreSQL Apply Evidence",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Database: `{report['database_target']}`",
        f"- Mutations performed: `{json.dumps(report['mutations_performed'])}`",
        "",
        "## Precheck",
        "",
        f"`{json.dumps(report['precheck'], sort_keys=True, default=json_default)}`",
        "",
        "## Postcheck",
        "",
        f"`{json.dumps(report['postcheck'], sort_keys=True, default=json_default)}`",
        "",
    ]
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    args = parse_args()
    if not args.apply:
        raise SystemExit("Refusing to mutate PostgreSQL without --apply.")

    manifest_path = Path(args.manifest)
    manifest = load_json(manifest_path)
    deploy_id = str(manifest.get("deploy_id") or manifest_path.stem)
    slug = str(manifest.get("slug") or manifest_path.stem)
    default_prefix = manifest_path.with_name(manifest_path.stem.replace("_manifest", ""))
    output_json = Path(args.output_json or f"{default_prefix}_pg_apply_evidence.json")
    output_md = Path(args.output_md or f"{default_prefix}_pg_apply_evidence.md")

    precheck_path = resolve_manifest_file(manifest, "precheck")
    apply_path = resolve_manifest_file(manifest, "apply")
    postcheck_path = resolve_manifest_file(manifest, "postcheck")

    conn = db_helper.connect()
    try:
        conn.autocommit = True
        precheck_rows = fetch_rows(conn, precheck_path)
        precheck = summarize_precheck(precheck_rows)
        if precheck["missing_targets"]:
            raise RuntimeError(f"Precheck failed; missing targets: {precheck['missing_targets']}")

        run_apply(conn, apply_path)
        postcheck_rows = fetch_rows(conn, postcheck_path)
        postcheck = summarize_postcheck(postcheck_rows)
        if postcheck["failed_cards"]:
            raise RuntimeError(f"Postcheck failed; failed cards: {postcheck['failed_cards']}")
    finally:
        conn.close()

    report = {
        "generated_at": utc_now(),
        "deploy_id": deploy_id,
        "slug": slug,
        "manifest": str(manifest_path),
        "database_target": db_helper.sanitized_database_target(),
        "mutations_performed": [f"postgres_apply_{deploy_id.lower()}_{slug}"],
        "precheck": precheck,
        "precheck_rows": precheck_rows,
        "postcheck": postcheck,
        "postcheck_rows": postcheck_rows,
    }
    output_json.write_text(
        json.dumps(report, indent=2, sort_keys=True, default=json_default) + "\n",
        encoding="utf-8",
    )
    write_markdown(output_md, report)
    print(json.dumps(report, indent=2, sort_keys=True, default=json_default))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
