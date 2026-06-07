#!/usr/bin/env python3
"""Backfill card power/toughness/keywords from MTGJSON AtomicCards.

This is a focused operational script for the `cards` table. It does not touch
deck/user data and updates only:

- cards.power
- cards.toughness
- cards.keywords

Credentials must come from `.env`/environment. Never print secrets.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any

import psycopg2
import psycopg2.extras


DEFAULT_ATOMIC_CARDS = Path(__file__).resolve().parents[1] / "AtomicCards.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Backfill cards.power/toughness/keywords from AtomicCards.json."
    )
    parser.add_argument(
        "--atomic-cards",
        default=str(DEFAULT_ATOMIC_CARDS),
        help="Path to MTGJSON AtomicCards.json.",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=1000,
        help="Number of rows per database batch.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Limit parsed rows for a smoke run.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse and count rows without updating the database.",
    )
    parser.add_argument(
        "--report",
        default="",
        help="Optional JSON report path.",
    )
    return parser.parse_args()


def load_dotenv(path: Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if key in os.environ:
            continue
        os.environ[key] = value.strip().strip('"').strip("'")


def connect():
    load_dotenv(Path(__file__).resolve().parents[1] / ".env")
    database_url = os.environ.get("DATABASE_URL")
    if database_url:
        return psycopg2.connect(database_url)
    required = ["DB_HOST", "DB_NAME", "DB_USER", "DB_PASS"]
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise RuntimeError("Missing DB config: " + ", ".join(missing))
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"],
    )


def selected_printing(printings: list[Any]) -> dict[str, Any] | None:
    for printing in printings:
        if not isinstance(printing, dict):
            continue
        identifiers = printing.get("identifiers")
        if not isinstance(identifiers, dict):
            continue
        oracle_id = str(identifiers.get("scryfallOracleId") or "").strip()
        if oracle_id:
            return printing
    return None


def parse_atomic_cards(path: Path, limit: int = 0) -> list[tuple[Any, ...]]:
    decoded = json.loads(path.read_text(encoding="utf-8"))
    cards_map = decoded.get("data")
    if not isinstance(cards_map, dict):
        raise RuntimeError("AtomicCards.json does not contain a data object.")

    rows: list[tuple[Any, ...]] = []
    for printings in cards_map.values():
        if not isinstance(printings, list):
            continue
        chosen = selected_printing(printings)
        if not chosen:
            continue
        identifiers = chosen.get("identifiers") or {}
        oracle_id = str(identifiers.get("scryfallOracleId") or "").strip()
        if not oracle_id:
            continue
        raw_keywords = chosen.get("keywords")
        keywords = (
            [str(keyword) for keyword in raw_keywords if keyword is not None]
            if isinstance(raw_keywords, list)
            else []
        )
        rows.append(
            (
                oracle_id,
                str(chosen["power"]) if chosen.get("power") is not None else None,
                str(chosen["toughness"])
                if chosen.get("toughness") is not None
                else None,
                keywords,
            )
        )
        if limit > 0 and len(rows) >= limit:
            break
    return rows


def ensure_columns(conn) -> None:
    with conn.cursor() as cur:
        cur.execute("ALTER TABLE cards ADD COLUMN IF NOT EXISTS power TEXT")
        cur.execute("ALTER TABLE cards ADD COLUMN IF NOT EXISTS toughness TEXT")
        cur.execute("ALTER TABLE cards ADD COLUMN IF NOT EXISTS keywords TEXT[]")
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_cards_keywords ON cards USING gin (keywords)"
        )
    conn.commit()


def update_batch(conn, rows: list[tuple[Any, ...]]) -> int:
    if not rows:
        return 0
    with conn.cursor() as cur:
        psycopg2.extras.execute_values(
            cur,
            """
            UPDATE cards AS c
            SET
              power = data.power,
              toughness = data.toughness,
              keywords = data.keywords
            FROM (VALUES %s) AS data(scryfall_id, power, toughness, keywords)
            WHERE c.scryfall_id = data.scryfall_id::uuid
            """,
            rows,
            template="(%s::uuid, %s::text, %s::text, %s::text[])",
            page_size=len(rows),
        )
        return cur.rowcount or 0


def coverage(conn) -> dict[str, int]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT
              count(*)::int,
              count(*) FILTER (WHERE power IS NOT NULL AND power <> '')::int,
              count(*) FILTER (WHERE toughness IS NOT NULL AND toughness <> '')::int,
              count(*) FILTER (
                WHERE keywords IS NOT NULL AND cardinality(keywords) > 0
              )::int
            FROM cards
            """
        )
        total, power, toughness, keywords = cur.fetchone()
    return {
        "cards_total": total,
        "power_known": power,
        "toughness_known": toughness,
        "keywords_known": keywords,
    }


def main() -> None:
    args = parse_args()
    atomic_cards = Path(args.atomic_cards)
    if not atomic_cards.exists():
        raise SystemExit(f"AtomicCards.json not found: {atomic_cards}")

    rows = parse_atomic_cards(atomic_cards, limit=args.limit)
    rows_with_power = sum(1 for row in rows if row[1])
    rows_with_toughness = sum(1 for row in rows if row[2])
    rows_with_keywords = sum(1 for row in rows if row[3])

    updated = 0
    before = after = {}
    if not args.dry_run:
        conn = connect()
        try:
            ensure_columns(conn)
            before = coverage(conn)
            for index in range(0, len(rows), args.batch_size):
                batch = rows[index : index + args.batch_size]
                updated += update_batch(conn, batch)
                conn.commit()
                print(f"updated {min(index + len(batch), len(rows))}/{len(rows)}")
            after = coverage(conn)
        finally:
            conn.close()

    report = {
        "dry_run": args.dry_run,
        "atomic_cards": str(atomic_cards),
        "rows_parsed": len(rows),
        "rows_with_power": rows_with_power,
        "rows_with_toughness": rows_with_toughness,
        "rows_with_keywords": rows_with_keywords,
        "rows_updated": updated,
        "coverage_before": before,
        "coverage_after": after,
    }
    if args.report:
        Path(args.report).write_text(
            json.dumps(report, indent=2, ensure_ascii=True) + "\n",
            encoding="utf-8",
        )

    print(json.dumps(report, indent=2, ensure_ascii=True))


if __name__ == "__main__":
    main()
