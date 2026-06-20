#!/usr/bin/env python3
"""Restore a Hermes-local optimizer deck from an apply rollback file."""

from __future__ import annotations

import argparse
import json
import sqlite3
from pathlib import Path

from master_optimizer_common import (
    battle_gate_report_lines,
    connect,
    deck_hash,
    ensure_optimizer_tables,
    get_deck_summary,
    utc_now,
    write_report,
)


def ensure_rollback_table(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS optimizer_rollback_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER NOT NULL,
            swap_benchmark_id INTEGER,
            card_added TEXT,
            card_removed TEXT,
            before_hash TEXT NOT NULL,
            after_hash TEXT NOT NULL,
            reason TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """
    )
    conn.commit()


def restore_rows(conn: sqlite3.Connection, deck_id: int, rows: list[dict[str, object]]) -> None:
    columns = [row[1] for row in conn.execute("PRAGMA table_info(deck_cards)")]
    conn.execute("DELETE FROM deck_cards WHERE deck_id=?", (deck_id,))
    placeholders = ",".join("?" for _ in columns)
    column_list = ",".join(columns)
    for row in rows:
        values = [row.get(column) for column in columns]
        conn.execute(
            f"INSERT INTO deck_cards ({column_list}) VALUES ({placeholders})",
            values,
        )


def rollback(rollback_path: Path, reason: str, force: bool = False) -> tuple[dict[str, object], dict[str, object]]:
    payload = json.loads(rollback_path.read_text(encoding="utf-8"))
    deck_id = int(payload["deck_id"])
    before_hash = str(payload["before_hash"])
    after_hash = str(payload["after_hash"])
    rows = payload.get("before_rows") or []
    if not isinstance(rows, list) or not rows:
        raise RuntimeError("Rollback payload does not contain before_rows.")

    with connect() as conn:
        ensure_optimizer_tables(conn)
        ensure_rollback_table(conn)
        current_hash = deck_hash(conn, deck_id)
        if current_hash != after_hash and not force:
            raise RuntimeError(
                "Current deck hash does not match rollback after_hash. "
                f"current={current_hash} after_hash={after_hash}. Use --force only after manual review."
            )

        restore_rows(conn, deck_id, rows)
        restored_hash = deck_hash(conn, deck_id)
        if restored_hash != before_hash:
            raise RuntimeError(
                "Rollback restored a different hash than expected. "
                f"restored={restored_hash} expected={before_hash}"
            )

        swap_id = payload.get("swap_benchmark_id")
        if swap_id is not None:
            conn.execute("UPDATE swap_benchmarks SET applied=-1 WHERE id=?", (swap_id,))
            applied_rows = conn.execute(
                "SELECT id FROM optimizer_applied_swaps WHERE swap_benchmark_id=?",
                (swap_id,),
            ).fetchall()
            for applied_row in applied_rows:
                conn.execute(
                    """
                    UPDATE optimizer_product_handoffs
                    SET status='superseded_by_rollback'
                    WHERE applied_swap_id=?
                    """,
                    (applied_row["id"],),
                )
        conn.execute(
            """
            INSERT INTO optimizer_rollback_events
                (deck_id, swap_benchmark_id, card_added, card_removed,
                 before_hash, after_hash, reason, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                deck_id,
                swap_id,
                payload.get("card_added"),
                payload.get("card_removed"),
                before_hash,
                after_hash,
                reason,
                utc_now(),
            ),
        )
        conn.commit()
        summary = get_deck_summary(conn, deck_id)

    return payload, summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rollback-path", required=True)
    parser.add_argument("--reason", default="manual_rollback")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    payload, summary = rollback(Path(args.rollback_path), args.reason, args.force)
    markdown = "\n".join(
        [
            "# Hermes Master Optimizer Rollback",
            "",
            f"- deck_id: {payload['deck_id']}",
            f"- swap_benchmark_id: {payload.get('swap_benchmark_id')}",
            f"- reverted: `{payload.get('card_added')}`",
            f"- restored: `{payload.get('card_removed')}`",
            f"- reason: {args.reason}",
            f"- restored_hash: `{summary['hash']}`",
            f"- cards_after: {summary['cards']}",
            f"- lands_after: {summary['lands']}",
            f"- avg_cmc_after: {summary['avg_cmc']}",
            "",
            *battle_gate_report_lines(),
            "No production database was mutated. This restores only the Hermes local SQLite deck.",
        ]
    ) + "\n"
    print(markdown)
    if args.report:
        path = write_report("master_optimizer_rollback", markdown)
        print(f"Report written: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
