#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_SQLITE_DB = SCRIPT_DIR / "knowledge.db"

TARGET_REVIEW_STATUSES = ("verified", "active")
TARGET_EXECUTION_STATUS = "auto"
TARGET_SOURCE = "curated"


def oracle_hash(oracle_text: str | None) -> str | None:
    text = str(oracle_text or "").strip()
    if not text:
        return None
    return hashlib.md5(text.encode("utf-8")).hexdigest()


def _missing_hash_rows(conn: sqlite3.Connection) -> list[sqlite3.Row]:
    conn.row_factory = sqlite3.Row
    return list(
        conn.execute(
            """
            SELECT
              b.normalized_name,
              b.logical_rule_key,
              b.card_name,
              b.source,
              b.review_status,
              b.execution_status,
              c.oracle_text
            FROM battle_card_rules b
            LEFT JOIN card_oracle_cache c
              ON c.normalized_name = b.normalized_name
            WHERE b.source = ?
              AND b.review_status IN (?, ?)
              AND b.execution_status = ?
              AND COALESCE(b.oracle_hash, '') = ''
            ORDER BY b.normalized_name, b.logical_rule_key
            """,
            (
                TARGET_SOURCE,
                TARGET_REVIEW_STATUSES[0],
                TARGET_REVIEW_STATUSES[1],
                TARGET_EXECUTION_STATUS,
            ),
        )
    )


def build_backfill_plan(sqlite_db: Path) -> dict[str, Any]:
    with sqlite3.connect(sqlite_db) as conn:
        rows = _missing_hash_rows(conn)

    updates: list[dict[str, str]] = []
    skipped_missing_oracle_text: list[dict[str, str]] = []
    for row in rows:
        hashed = oracle_hash(row["oracle_text"])
        item = {
            "normalized_name": str(row["normalized_name"]),
            "card_name": str(row["card_name"]),
            "logical_rule_key": str(row["logical_rule_key"]),
        }
        if hashed:
            updates.append({**item, "oracle_hash": hashed})
        else:
            skipped_missing_oracle_text.append(item)

    return {
        "sqlite_db": str(sqlite_db),
        "target_filter": {
            "source": TARGET_SOURCE,
            "review_status": list(TARGET_REVIEW_STATUSES),
            "execution_status": TARGET_EXECUTION_STATUS,
            "missing_oracle_hash": True,
        },
        "candidate_count": len(rows),
        "update_count": len(updates),
        "skipped_missing_oracle_text_count": len(skipped_missing_oracle_text),
        "updates": updates,
        "skipped_missing_oracle_text": skipped_missing_oracle_text,
    }


def apply_backfill(sqlite_db: Path, plan: dict[str, Any]) -> int:
    updates = plan["updates"]
    now = datetime.now(timezone.utc).isoformat()
    changed = 0
    with sqlite3.connect(sqlite_db) as conn:
        for item in updates:
            cur = conn.execute(
                """
                UPDATE battle_card_rules
                SET oracle_hash = ?,
                    updated_at = ?
                WHERE normalized_name = ?
                  AND logical_rule_key = ?
                  AND source = ?
                  AND review_status IN (?, ?)
                  AND execution_status = ?
                  AND COALESCE(oracle_hash, '') = ''
                """,
                (
                    item["oracle_hash"],
                    now,
                    item["normalized_name"],
                    item["logical_rule_key"],
                    TARGET_SOURCE,
                    TARGET_REVIEW_STATUSES[0],
                    TARGET_REVIEW_STATUSES[1],
                    TARGET_EXECUTION_STATUS,
                ),
            )
            changed += cur.rowcount
        conn.commit()
    return changed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Backfill missing oracle_hash on trusted SQLite battle rules."
    )
    parser.add_argument("--sqlite-db", default=str(DEFAULT_SQLITE_DB))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--report", help="Optional JSON report path.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    sqlite_db = Path(args.sqlite_db)
    plan = build_backfill_plan(sqlite_db)
    applied_count = 0
    if not args.dry_run:
        applied_count = apply_backfill(sqlite_db, plan)
    report = {
        **plan,
        "dry_run": bool(args.dry_run),
        "applied_count": applied_count,
    }
    if args.report:
        Path(args.report).write_text(
            json.dumps(report, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    print(
        json.dumps(
            {
                "sqlite_db": report["sqlite_db"],
                "dry_run": report["dry_run"],
                "candidate_count": report["candidate_count"],
                "update_count": report["update_count"],
                "skipped_missing_oracle_text_count": report[
                    "skipped_missing_oracle_text_count"
                ],
                "applied_count": report["applied_count"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
