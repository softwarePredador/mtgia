#!/usr/bin/env python3
"""Fast full MTGJSON cards/legalities sync.

The Dart sync keeps network/version orchestration. This helper performs the
heavy PostgreSQL merge with psycopg2 `execute_values`, which is much safer for
large AtomicCards loads than thousands of single-row prepared statement calls.

It writes only operational progress to stderr and emits a single JSON object to
stdout for the Dart caller.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
from pathlib import Path
from typing import Any

import psycopg2
import psycopg2.extras


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Fast full cards sync.")
    parser.add_argument("--atomic-cards", required=True)
    parser.add_argument("--batch-size", type=int, default=1000)
    return parser.parse_args()


def load_dotenv(path: Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key.strip() in os.environ:
            continue
        os.environ[key.strip()] = value.strip().strip('"').strip("'")


def connect():
    load_dotenv(Path(__file__).resolve().parents[1] / ".env")
    database_url = os.environ.get("DATABASE_URL")
    if database_url:
        return psycopg2.connect(database_url)
    required = ["DB_HOST", "DB_NAME", "DB_USER"]
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise RuntimeError("Missing DB config: " + ", ".join(missing))
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ.get("DB_PASS", ""),
    )


def normalize_set_code(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip().lower()
    return text or None


def selected_printing(card_name: str, printings: list[Any]) -> dict[str, Any] | None:
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


def scryfall_image_url(name: str, identifiers: dict[str, Any], set_code: str | None) -> str:
    scryfall_id = str(identifiers.get("scryfallId") or "").strip()
    if scryfall_id:
        return f"https://api.scryfall.com/cards/{scryfall_id}?format=image&version=normal"
    from urllib.parse import quote

    set_param = f"&set={set_code}" if set_code else ""
    return (
        "https://api.scryfall.com/cards/named?exact="
        f"{quote(name)}{set_param}&format=image"
    )


def list_of_strings(value: Any) -> list[str]:
    if isinstance(value, list):
        return [str(item) for item in value if item is not None]
    return []


def normalized_cmc(value: Any) -> float | None:
    try:
        cmc = float(value)
    except (TypeError, ValueError):
        return None
    if not math.isfinite(cmc) or cmc < 0 or cmc >= 1000:
        return None
    return cmc


def parse_atomic_cards(path: Path) -> tuple[list[tuple[Any, ...]], list[tuple[Any, ...]]]:
    decoded = json.loads(path.read_text(encoding="utf-8"))
    cards_map = decoded.get("data")
    if not isinstance(cards_map, dict):
        raise RuntimeError("AtomicCards.json does not contain a data object.")

    cards_by_oracle: dict[str, tuple[Any, ...]] = {}
    legalities_by_key: dict[tuple[str, str], tuple[str, str, str]] = {}

    for card_name, printings in cards_map.items():
        if not isinstance(printings, list):
            continue
        chosen = selected_printing(str(card_name), printings)
        if not chosen:
            continue
        identifiers = chosen.get("identifiers") or {}
        oracle_id = str(identifiers.get("scryfallOracleId") or "").strip()
        if not oracle_id:
            continue

        name = str(chosen.get("name") or card_name)
        set_code = normalize_set_code(
            (chosen.get("printings") or [None])[0]
            if isinstance(chosen.get("printings"), list)
            else None
        )
        cards_by_oracle[oracle_id] = (
            oracle_id,
            oracle_id,
            name,
            chosen.get("manaCost"),
            chosen.get("type"),
            chosen.get("text"),
            list_of_strings(chosen.get("colors")),
            list_of_strings(chosen.get("colorIdentity")),
            str(chosen["power"]) if chosen.get("power") is not None else None,
            str(chosen["toughness"]) if chosen.get("toughness") is not None else None,
            list_of_strings(chosen.get("keywords")),
            scryfall_image_url(name, identifiers, set_code),
            set_code,
            chosen.get("rarity"),
            normalized_cmc(chosen.get("manaValue", chosen.get("convertedManaCost"))),
            chosen.get("isReserved") is True,
        )

        legalities = chosen.get("legalities")
        if isinstance(legalities, dict):
            for fmt, status in legalities.items():
                legalities_by_key[(oracle_id, str(fmt))] = (
                    oracle_id,
                    str(fmt),
                    str(status).lower(),
                )

    return list(cards_by_oracle.values()), list(legalities_by_key.values())


def ensure_schema(conn) -> None:
    with conn.cursor() as cur:
        cur.execute("ALTER TABLE cards ADD COLUMN IF NOT EXISTS color_identity TEXT[]")
        cur.execute("ALTER TABLE cards ADD COLUMN IF NOT EXISTS power TEXT")
        cur.execute("ALTER TABLE cards ADD COLUMN IF NOT EXISTS toughness TEXT")
        cur.execute("ALTER TABLE cards ADD COLUMN IF NOT EXISTS keywords TEXT[]")
        cur.execute("ALTER TABLE cards ADD COLUMN IF NOT EXISTS is_reserved BOOLEAN")
        cur.execute("ALTER TABLE cards ADD COLUMN IF NOT EXISTS oracle_id UUID")
        cur.execute("ALTER TABLE cards ADD COLUMN IF NOT EXISTS cmc DECIMAL(4, 1) DEFAULT 0")
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_cards_color_identity ON cards USING GIN (color_identity)"
        )
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_cards_keywords ON cards USING GIN (keywords)"
        )
    conn.commit()


def upsert_cards(conn, rows: list[tuple[Any, ...]], batch_size: int) -> int:
    total = 0
    with conn.cursor() as cur:
        for index in range(0, len(rows), batch_size):
            batch = rows[index : index + batch_size]
            psycopg2.extras.execute_values(
                cur,
                """
                INSERT INTO cards (
                  scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
                  colors, color_identity, power, toughness, keywords,
                  image_url, set_code, rarity, cmc, is_reserved
                ) VALUES %s
                ON CONFLICT (scryfall_id) DO UPDATE SET
                  oracle_id = EXCLUDED.oracle_id,
                  name = EXCLUDED.name,
                  mana_cost = EXCLUDED.mana_cost,
                  type_line = EXCLUDED.type_line,
                  oracle_text = EXCLUDED.oracle_text,
                  colors = EXCLUDED.colors,
                  color_identity = EXCLUDED.color_identity,
                  power = EXCLUDED.power,
                  toughness = EXCLUDED.toughness,
                  keywords = EXCLUDED.keywords,
                  image_url = EXCLUDED.image_url,
                  set_code = EXCLUDED.set_code,
                  rarity = EXCLUDED.rarity,
                  cmc = EXCLUDED.cmc,
                  is_reserved = COALESCE(EXCLUDED.is_reserved, cards.is_reserved)
                """,
                batch,
                template=(
                    "(%s::uuid, %s::uuid, %s::text, %s::text, %s::text, %s::text, "
                    "%s::text[], %s::text[], %s::text, %s::text, %s::text[], "
                    "%s::text, %s::text, %s::text, %s::numeric, %s::boolean)"
                ),
                page_size=len(batch),
            )
            total += len(batch)
            print(f"cards {total}/{len(rows)}", file=sys.stderr, flush=True)
    return total


def load_card_ids(conn) -> dict[str, str]:
    with conn.cursor() as cur:
        cur.execute("SELECT scryfall_id::text, id::text FROM cards")
        return {row[0]: row[1] for row in cur.fetchall()}


def upsert_legalities(
    conn,
    rows: list[tuple[str, str, str]],
    card_ids: dict[str, str],
    batch_size: int,
) -> int:
    resolved = [
        (card_ids[oracle_id], fmt, status)
        for oracle_id, fmt, status in rows
        if oracle_id in card_ids
    ]

    total = 0
    with conn.cursor() as cur:
        for index in range(0, len(resolved), batch_size):
            batch = resolved[index : index + batch_size]
            psycopg2.extras.execute_values(
                cur,
                """
                INSERT INTO card_legalities (card_id, format, status)
                VALUES %s
                ON CONFLICT (card_id, format) DO UPDATE SET
                  status = EXCLUDED.status
                """,
                batch,
                template="(%s::uuid, %s::text, %s::text)",
                page_size=len(batch),
            )
            total += len(batch)
            print(f"legalities {total}/{len(resolved)}", file=sys.stderr, flush=True)
    return total


def main() -> None:
    args = parse_args()
    atomic_cards = Path(args.atomic_cards)
    if not atomic_cards.exists():
        raise SystemExit(f"AtomicCards.json not found: {atomic_cards}")

    card_rows, legality_rows = parse_atomic_cards(atomic_cards)
    conn = connect()
    try:
        ensure_schema(conn)
        processed_cards = upsert_cards(conn, card_rows, args.batch_size)
        card_ids = load_card_ids(conn)
        processed_legalities = upsert_legalities(
            conn,
            legality_rows,
            card_ids,
            args.batch_size,
        )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    print(
        json.dumps(
            {
                "processed_cards": processed_cards,
                "processed_legalities": processed_legalities,
            },
            ensure_ascii=True,
        )
    )


if __name__ == "__main__":
    main()
