#!/usr/bin/env python3
"""Sync production PostgreSQL meta decklists into local Hermes learned_decks.

This is a one-way cache refresh:

- READS ManaLoom PostgreSQL `meta_decks`.
- WRITES only the local Hermes SQLite `learned_decks` table.
- Does not mutate production/PostgreSQL data.
- Does not print credentials or connection strings.

Run inside the Hermes container after sourcing DB env:

    python3 sync_pg_meta_decks_to_hermes.py --apply --limit 120
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

from db_helper import connect


DEFAULT_SQLITE_DB = Path(
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
)


@dataclass
class MetaDeck:
    pg_id: str
    commander: str
    deck_name: str
    archetype: str
    source_url: str
    cards: list[dict[str, object]]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Cache PG meta decks into Hermes learned_decks for battle opponents."
    )
    parser.add_argument("--sqlite-db", default=str(DEFAULT_SQLITE_DB))
    parser.add_argument("--limit", type=int, default=120)
    parser.add_argument("--min-cards", type=int, default=90)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--include-lorehold", action="store_true")
    return parser.parse_args()


def parse_decklist(text: str) -> list[dict[str, object]]:
    cards: list[dict[str, object]] = []
    for raw_line in (text or "").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.lower() in ("deck", "commander", "sideboard", "maybeboard"):
            continue
        line = re.sub(r"^(sb:|sideboard:)\s*", "", line, flags=re.I).strip()
        match = re.match(r"^(\d+)\s*x?\s+(.+)$", line, flags=re.I)
        if not match:
            continue
        quantity = max(1, min(30, int(match.group(1))))
        name = re.sub(r"\s+\([^)]*\)\s*\d*\s*$", "", match.group(2)).strip()
        if not name:
            continue
        for _ in range(quantity):
            cards.append({"name": name})
    return cards


def fetch_meta_decks(limit: int, include_lorehold: bool) -> list[MetaDeck]:
    lorehold_filter = "" if include_lorehold else "AND commander_name NOT ILIKE '%%Lorehold%%'"
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                f"""
                SELECT
                  id::text,
                  commander_name,
                  COALESCE(
                    NULLIF(shell_label, ''),
                    NULLIF(archetype, ''),
                    commander_name,
                    'PG Meta Deck'
                  ) AS deck_name,
                  COALESCE(NULLIF(strategy_archetype, ''), NULLIF(archetype, ''), NULLIF(shell_label, ''), 'meta') AS archetype,
                  COALESCE(source_url, '') AS source_url,
                  card_list
                FROM meta_decks
                WHERE COALESCE(commander_name, '') != ''
                  AND length(COALESCE(card_list, '')) >= 500
                  {lorehold_filter}
                ORDER BY created_at DESC NULLS LAST, id DESC
                LIMIT %s
                """,
                (limit,),
            )
            rows = cur.fetchall()

    decks = []
    for pg_id, commander, deck_name, archetype, source_url, card_list in rows:
        cards = parse_decklist(card_list or "")
        decks.append(
            MetaDeck(
                pg_id=pg_id,
                commander=commander,
                deck_name=deck_name,
                archetype=archetype,
                source_url=source_url,
                cards=cards,
            )
        )
    return decks


def ensure_learned_decks(cur: sqlite3.Cursor) -> None:
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS learned_decks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source TEXT NOT NULL,
            source_url TEXT,
            commander TEXT NOT NULL,
            deck_name TEXT,
            archetype TEXT,
            card_list TEXT,
            card_count INTEGER,
            wincon_primary TEXT,
            wincon_backup TEXT,
            budget_level TEXT,
            notes TEXT,
            created_at TEXT DEFAULT (datetime('now'))
        )
        """
    )


def write_decks(
    cur: sqlite3.Cursor,
    decks: Iterable[MetaDeck],
    *,
    min_cards: int,
    apply: bool,
) -> dict[str, int]:
    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    stats = {"seen": 0, "skipped": 0, "inserted": 0, "updated": 0}
    for deck in decks:
        stats["seen"] += 1
        card_count = len(deck.cards)
        if card_count < min_cards:
            stats["skipped"] += 1
            continue
        cache_source_url = f"pg:meta_decks:{deck.pg_id}"
        card_list_json = json.dumps(deck.cards, ensure_ascii=True)
        notes = f"sync_pg_meta_decks_to_hermes.py source_url={deck.source_url or 'n/a'}"
        existing = cur.execute(
            "SELECT id FROM learned_decks WHERE source=? AND source_url=?",
            ("pg_meta_decks", cache_source_url),
        ).fetchone()
        if existing:
            stats["updated"] += 1
            if apply:
                cur.execute(
                    """
                    UPDATE learned_decks
                    SET commander=?, deck_name=?, archetype=?, card_list=?, card_count=?, notes=?
                    WHERE id=?
                    """,
                    (
                        deck.commander,
                        deck.deck_name,
                        deck.archetype,
                        card_list_json,
                        card_count,
                        notes,
                        existing[0],
                    ),
                )
            continue
        stats["inserted"] += 1
        if apply:
            cur.execute(
                """
                INSERT INTO learned_decks (
                    source, source_url, commander, deck_name, archetype,
                    card_list, card_count, notes, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    "pg_meta_decks",
                    cache_source_url,
                    deck.commander,
                    deck.deck_name,
                    deck.archetype,
                    card_list_json,
                    card_count,
                    notes,
                    now,
                ),
            )
    return stats


def main() -> None:
    args = parse_args()
    sqlite_db = Path(args.sqlite_db)
    if not sqlite_db.exists():
        raise SystemExit(f"SQLite DB not found: {sqlite_db}")

    decks = fetch_meta_decks(args.limit, args.include_lorehold)
    conn = sqlite3.connect(sqlite_db)
    cur = conn.cursor()
    ensure_learned_decks(cur)
    stats = write_decks(cur, decks, min_cards=args.min_cards, apply=args.apply)
    if args.apply:
        conn.commit()
    else:
        conn.rollback()
    conn.close()
    print(
        "pg_meta_decks sync "
        f"apply={args.apply} seen={stats['seen']} skipped={stats['skipped']} "
        f"inserted={stats['inserted']} updated={stats['updated']}"
    )


if __name__ == "__main__":
    main()
