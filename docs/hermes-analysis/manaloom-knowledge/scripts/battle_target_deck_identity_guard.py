#!/usr/bin/env python3
"""Fail-closed identity guard for the Battle target cached in Hermes SQLite."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sqlite3
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_DB = Path(
    os.environ.get("MANALOOM_KNOWLEDGE_DB")
    or os.environ.get("HERMES_KNOWLEDGE_DB")
    or SCRIPT_DIR / "knowledge.db"
)
PROTECTED_HERMES_DECK_ID = 6
DEFAULT_EXPECTED_PG_DECK_ID = "8938b746-1a9e-46ce-b0d9-c2ec932ddddd"
PG_DECK_ID_RE = re.compile(r"(?:^|\s)pg_deck_id=([0-9a-fA-F-]{36})(?:\s|$)")


def _table_columns(conn: sqlite3.Connection, table: str) -> set[str]:
    return {str(row[1]) for row in conn.execute(f"PRAGMA table_info({table})")}


def _single_value(values: list[Any]) -> Any | None:
    if not values or any(value in (None, "") for value in values):
        return None
    return values[0] if len(set(values)) == 1 else None


def _json_value(value: Any) -> Any:
    if isinstance(value, (dict, list)):
        return value
    if isinstance(value, str) and value.strip():
        try:
            return json.loads(value)
        except json.JSONDecodeError as exc:
            raise ValueError("snapshot_json_invalid") from exc
    return []


def _stable_json(value: Any) -> str:
    return json.dumps(
        value,
        ensure_ascii=True,
        separators=(",", ":"),
        sort_keys=True,
    )


def compute_snapshot_hashes(rows: list[Any]) -> tuple[str, str, str]:
    ordered = sorted(
        rows,
        key=lambda row: (
            not bool(row["is_commander"]),
            str(row["card_name"] or ""),
            str(row["card_id"] or "").strip().lower(),
            int(row["quantity"] or 0),
            _stable_json(_json_value(row["functional_tags_json"])),
            _stable_json(_json_value(row["semantic_tags_v2_json"])),
            _stable_json(_json_value(row["battle_rules_json"])),
        ),
    )
    deck_payload = []
    semantics_payload = []
    ruleset_payload = []
    for row in ordered:
        card_id = str(row["card_id"] or "").strip()
        deck_payload.append(
            {
                "card_id": card_id,
                "card_name": str(row["card_name"] or "").strip(),
                "quantity": int(row["quantity"] or 0),
                "is_commander": bool(row["is_commander"]),
            }
        )
        semantics_payload.append(
            {
                "card_id": card_id,
                "functional_tags_json": _json_value(row["functional_tags_json"]),
                "semantic_tags_v2_json": _json_value(row["semantic_tags_v2_json"]),
            }
        )
        ruleset_payload.append(
            {
                "card_id": card_id,
                "battle_rules_json": _json_value(row["battle_rules_json"]),
            }
        )
    return tuple(
        hashlib.sha256(_stable_json(payload).encode("utf-8")).hexdigest()
        for payload in (deck_payload, semantics_payload, ruleset_payload)
    )


def inspect_target_identity(
    sqlite_db: Path,
    *,
    target_deck_id: int,
    expected_pg_deck_id: str,
    expected_deck_hash: str = "",
    min_distinct_cards: int = 90,
    expected_total_quantity: int = 100,
    expected_commanders: int = 1,
) -> dict[str, Any]:
    errors: list[str] = []
    sqlite_db = sqlite_db.resolve()
    report: dict[str, Any] = {
        "status": "blocked",
        "sqlite_db": str(sqlite_db),
        "target_deck_id": int(target_deck_id),
        "expected_pg_deck_id": expected_pg_deck_id.lower() or None,
        "expected_deck_hash": expected_deck_hash.lower() or None,
        "policy": {
            "min_distinct_cards": int(min_distinct_cards),
            "expected_total_quantity": int(expected_total_quantity),
            "expected_commanders": int(expected_commanders),
            "hashes_must_be_present_and_uniform": True,
            "sync_run_id_must_be_present_and_uniform": True,
        },
        "errors": errors,
    }
    if not sqlite_db.is_file() or sqlite_db.stat().st_size == 0:
        errors.append("knowledge_db_missing_or_empty")
        return report

    conn = sqlite3.connect(f"file:{sqlite_db}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    try:
        deck_columns = _table_columns(conn, "decks")
        card_columns = _table_columns(conn, "deck_cards")
        required_deck = {"id", "deck_name", "total_cards", "notes"}
        required_cards = {
            "deck_id",
            "card_id",
            "card_name",
            "quantity",
            "is_commander",
            "deck_hash",
            "semantics_hash",
            "ruleset_hash",
            "sync_run_id",
            "functional_tags_json",
            "semantic_tags_v2_json",
            "battle_rules_json",
        }
        if not required_deck.issubset(deck_columns):
            errors.append(
                "decks_schema_missing:" + ",".join(sorted(required_deck - deck_columns))
            )
        if not required_cards.issubset(card_columns):
            errors.append(
                "deck_cards_schema_missing:"
                + ",".join(sorted(required_cards - card_columns))
            )
        if errors:
            return report

        deck_row = conn.execute(
            "SELECT id, deck_name, total_cards, notes FROM decks WHERE id=?",
            (target_deck_id,),
        ).fetchone()
        if deck_row is None:
            errors.append("target_deck_row_missing")
            return report

        notes = str(deck_row["notes"] or "")
        match = PG_DECK_ID_RE.search(notes)
        actual_pg_deck_id = match.group(1).lower() if match else None
        rows = conn.execute(
            """
            SELECT card_id, card_name, quantity, is_commander,
                   deck_hash, semantics_hash, ruleset_hash, sync_run_id,
                   functional_tags_json, semantic_tags_v2_json, battle_rules_json
            FROM deck_cards
            WHERE deck_id=?
            """,
            (target_deck_id,),
        ).fetchall()
        distinct_card_ids = {
            str(row["card_id"] or "").strip().lower() for row in rows if row["card_id"]
        }
        card_hashes = [str(row["deck_hash"] or "").strip().lower() for row in rows]
        semantic_hashes = [
            str(row["semantics_hash"] or "").strip().lower() for row in rows
        ]
        ruleset_hashes = [
            str(row["ruleset_hash"] or "").strip().lower() for row in rows
        ]
        sync_run_ids = [str(row["sync_run_id"] or "").strip() for row in rows]
        deck_hash = _single_value(card_hashes)
        semantics_hash = _single_value(semantic_hashes)
        ruleset_hash = _single_value(ruleset_hashes)
        sync_run_id = _single_value(sync_run_ids)
        try:
            computed_deck_hash, computed_semantics_hash, computed_ruleset_hash = (
                compute_snapshot_hashes(rows)
            )
        except ValueError as exc:
            if str(exc) == "snapshot_json_invalid":
                errors.append("snapshot_json_invalid")
                computed_deck_hash = None
                computed_semantics_hash = None
                computed_ruleset_hash = None
            else:
                raise
        total_quantity = sum(int(row["quantity"] or 0) for row in rows)
        commander_quantity = sum(
            int(row["quantity"] or 0) for row in rows if int(row["is_commander"] or 0)
        )
        missing_card_ids = sum(1 for row in rows if not str(row["card_id"] or "").strip())
        report["actual"] = {
            "deck_name": str(deck_row["deck_name"] or ""),
            "declared_total_cards": int(deck_row["total_cards"] or 0),
            "notes": notes,
            "pg_deck_id": actual_pg_deck_id,
            "rows": len(rows),
            "distinct_card_ids": len(distinct_card_ids),
            "missing_card_ids": missing_card_ids,
            "total_quantity": total_quantity,
            "commander_quantity": commander_quantity,
            "deck_hash": deck_hash,
            "semantics_hash": semantics_hash,
            "ruleset_hash": ruleset_hash,
            "sync_run_id": sync_run_id,
            "computed_deck_hash": computed_deck_hash,
            "computed_semantics_hash": computed_semantics_hash,
            "computed_ruleset_hash": computed_ruleset_hash,
        }

        if expected_pg_deck_id and actual_pg_deck_id != expected_pg_deck_id.strip().lower():
            errors.append("pg_deck_id_mismatch")
        if len(distinct_card_ids) < min_distinct_cards:
            errors.append("distinct_card_count_below_minimum")
        if missing_card_ids:
            errors.append("missing_card_ids")
        if total_quantity != expected_total_quantity:
            errors.append("total_quantity_mismatch")
        if int(deck_row["total_cards"] or 0) != expected_total_quantity:
            errors.append("declared_total_cards_mismatch")
        if commander_quantity != expected_commanders:
            errors.append("commander_quantity_mismatch")
        for label, value in (
            ("deck_hash", deck_hash),
            ("semantics_hash", semantics_hash),
            ("ruleset_hash", ruleset_hash),
            ("sync_run_id", sync_run_id),
        ):
            if not value:
                errors.append(f"{label}_missing_or_nonuniform")
        if computed_deck_hash and deck_hash and deck_hash != computed_deck_hash:
            errors.append("deck_hash_content_mismatch")
        if computed_semantics_hash and semantics_hash and semantics_hash != computed_semantics_hash:
            errors.append("semantics_hash_content_mismatch")
        if computed_ruleset_hash and ruleset_hash and ruleset_hash != computed_ruleset_hash:
            errors.append("ruleset_hash_content_mismatch")
        if expected_deck_hash and deck_hash != expected_deck_hash.strip().lower():
            errors.append("deck_hash_mismatch")
        report["status"] = "pass" if not errors else "blocked"
        return report
    finally:
        conn.close()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument(
        "--target-deck-id", type=int, default=PROTECTED_HERMES_DECK_ID
    )
    parser.add_argument(
        "--expected-pg-deck-id",
        default=(
            os.environ.get("MANALOOM_BATTLE_EXPECTED_PG_DECK_ID")
            or os.environ.get("MANALOOM_CANONICAL_PG_DECK_ID")
            or ""
        ),
    )
    parser.add_argument(
        "--expected-deck-hash",
        default=os.environ.get("MANALOOM_BATTLE_EXPECTED_DECK_HASH", ""),
    )
    parser.add_argument("--min-distinct-cards", type=int, default=90)
    parser.add_argument("--expected-total-quantity", type=int, default=100)
    parser.add_argument("--expected-commanders", type=int, default=1)
    parser.add_argument("--output")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    expected_pg_deck_id = args.expected_pg_deck_id
    if (
        not expected_pg_deck_id
        and args.target_deck_id == PROTECTED_HERMES_DECK_ID
    ):
        expected_pg_deck_id = DEFAULT_EXPECTED_PG_DECK_ID
    report = inspect_target_identity(
        Path(args.sqlite_db),
        target_deck_id=args.target_deck_id,
        expected_pg_deck_id=expected_pg_deck_id,
        expected_deck_hash=args.expected_deck_hash,
        min_distinct_cards=args.min_distinct_cards,
        expected_total_quantity=args.expected_total_quantity,
        expected_commanders=args.expected_commanders,
    )
    output = json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True)
    print(output)
    if args.output:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(output + "\n", encoding="utf-8")
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
