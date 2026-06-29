#!/usr/bin/env python3
"""Sync PostgreSQL Commander legalities into Hermes knowledge.db.

This is a one-way cache refresh:

- READS ManaLoom PostgreSQL `card_legalities`, `cards`, and `format_staples`.
- WRITES only the local Hermes SQLite cache.
- Does not mutate PostgreSQL.
- Does not print credentials or raw connection strings.
"""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from db_helper import connect, sanitized_database_target


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_SQLITE_DB = Path(os.environ.get("MANALOOM_KNOWLEDGE_DB", SCRIPT_DIR / "knowledge.db"))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Cache PostgreSQL Commander legalities into Hermes SQLite."
    )
    parser.add_argument("--sqlite-db", default=str(DEFAULT_SQLITE_DB))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--report", default="")
    return parser.parse_args()


def ensure_sqlite_tables(cur: sqlite3.Cursor) -> None:
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS card_legalities (
            card_name TEXT NOT NULL,
            format TEXT NOT NULL,
            status TEXT NOT NULL,
            scryfall_id TEXT,
            synced_at TEXT DEFAULT (datetime('now')),
            PRIMARY KEY(card_name, format)
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS format_staples (
            card_name TEXT NOT NULL,
            format TEXT NOT NULL,
            archetype TEXT NOT NULL DEFAULT '',
            category TEXT NOT NULL DEFAULT '',
            color_identity TEXT,
            edhrec_rank INTEGER,
            scryfall_id TEXT,
            is_banned INTEGER DEFAULT 0,
            synced_at TEXT DEFAULT (datetime('now')),
            PRIMARY KEY(card_name, format, archetype, category)
        )
        """
    )


def fetch_pg_legalities() -> list[tuple[str, str, str, str | None]]:
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  c.name,
                  cl.format,
                  CASE
                    WHEN bool_or(cl.status = 'banned') THEN 'banned'
                    WHEN bool_or(cl.status = 'legal') THEN 'legal'
                    ELSE min(cl.status)
                  END AS status,
                  min(c.scryfall_id::text) AS scryfall_id
                FROM card_legalities cl
                JOIN cards c ON c.id = cl.card_id
                WHERE cl.format = 'commander'
                GROUP BY c.name, cl.format
                ORDER BY c.name
                """
            )
            return [(str(a), str(b), str(c), d or None) for a, b, c, d in cur.fetchall()]


def fetch_pg_format_staples() -> list[tuple[Any, ...]]:
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  card_name,
                  format,
                  COALESCE(archetype, ''),
                  COALESCE(category, ''),
                  color_identity,
                  edhrec_rank,
                  scryfall_id::text,
                  is_banned
                FROM format_staples
                WHERE format = 'commander'
                ORDER BY card_name
                """
            )
            return list(cur.fetchall())


def normalize_color_identity(value: Any) -> str | None:
    if value is None:
        return None
    if isinstance(value, (list, tuple)):
        return ",".join(str(item) for item in value if item)
    text = str(value).strip()
    return text or None


def add_local_legality_aliases(
    legalities: list[tuple[str, str, str, str | None]],
) -> list[tuple[str, str, str, str | None]]:
    by_key: dict[tuple[str, str], tuple[str, str, str, str | None]] = {}
    for row in legalities:
        name, fmt, _status, _scryfall_id = row
        by_key[(name.casefold(), fmt)] = row
        if " // " in name:
            front = name.split(" // ", 1)[0].strip()
            if front:
                by_key.setdefault((front.casefold(), fmt), (front, fmt, row[2], row[3]))
    by_key[("lorehold, the historian", "commander")] = (
        "Lorehold, the Historian",
        "commander",
        "legal",
        None,
    )
    return sorted(by_key.values(), key=lambda row: (row[1], row[0].casefold()))


def status_lookup(
    rows: list[tuple[str, str, str, str | None]],
    card_name: str,
    fmt: str = "commander",
) -> str:
    target = card_name.casefold()
    for name, row_format, status, _scryfall_id in rows:
        if row_format == fmt and name.casefold() == target:
            return status
    return "missing"


def sync_sqlite(
    sqlite_db: Path,
    *,
    dry_run: bool,
) -> dict[str, Any]:
    legalities = fetch_pg_legalities()
    legalities_with_aliases = add_local_legality_aliases(legalities)
    staples = fetch_pg_format_staples()
    staple_rows = [
        (
            str(card_name),
            str(fmt),
            str(archetype or ""),
            str(category or ""),
            normalize_color_identity(color_identity),
            int(edhrec_rank) if edhrec_rank is not None else None,
            str(scryfall_id) if scryfall_id else None,
            1 if is_banned else 0,
        )
        for (
            card_name,
            fmt,
            archetype,
            category,
            color_identity,
            edhrec_rank,
            scryfall_id,
            is_banned,
        ) in staples
    ]

    sqlite_db.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(sqlite_db)
    try:
        cur = conn.cursor()
        if not dry_run:
            ensure_sqlite_tables(cur)
            cur.execute("DELETE FROM card_legalities WHERE format='commander'")
            cur.executemany(
                """
                INSERT OR REPLACE INTO card_legalities(
                    card_name, format, status, scryfall_id, synced_at
                ) VALUES (?, ?, ?, ?, datetime('now'))
                """,
                legalities_with_aliases,
            )
            cur.execute("DELETE FROM format_staples WHERE format='commander'")
            cur.executemany(
                """
                INSERT OR REPLACE INTO format_staples(
                    card_name, format, archetype, category, color_identity,
                    edhrec_rank, scryfall_id, is_banned, synced_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
                """,
                staple_rows,
            )
            conn.commit()
        else:
            conn.rollback()
    finally:
        conn.close()

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "dry_run": dry_run,
        "postgres_target": sanitized_database_target(),
        "sqlite_db": str(sqlite_db),
        "pg_commander_legalities": len(legalities),
        "sqlite_commander_legality_rows": len(legalities_with_aliases),
        "front_face_alias_rows": len(legalities_with_aliases) - len(legalities) - 1,
        "pg_commander_format_staples": len(staple_rows),
        "worldfire_commander_status": status_lookup(legalities_with_aliases, "Worldfire"),
        "mana_crypt_commander_status": status_lookup(legalities_with_aliases, "Mana Crypt"),
        "mutations_performed": []
        if dry_run
        else [
            "sqlite.card_legalities commander cache refreshed",
            "sqlite.format_staples commander cache refreshed",
        ],
    }


def main() -> int:
    args = parse_args()
    report = sync_sqlite(Path(args.sqlite_db), dry_run=args.dry_run)
    if args.report:
        Path(args.report).write_text(
            json.dumps(report, indent=2, ensure_ascii=True, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    print(f"postgres target: {report['postgres_target']}")
    print(f"sqlite db: {report['sqlite_db']}")
    print(f"commander legality rows: {report['sqlite_commander_legality_rows']}")
    print(f"format staples rows: {report['pg_commander_format_staples']}")
    print(f"Worldfire commander status: {report['worldfire_commander_status']}")
    print(f"Mana Crypt commander status: {report['mana_crypt_commander_status']}")
    print(f"dry_run: {report['dry_run']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
