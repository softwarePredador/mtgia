#!/usr/bin/env python3
"""Sync production card metadata into the local Hermes SQLite cache.

This script is intentionally one-way:

- READS from the ManaLoom PostgreSQL `cards` table.
- WRITES only to the local Hermes `knowledge.db` SQLite file.
- Never mutates production data.
- Never prints credentials or connection strings.

Run from the Hermes scripts directory or any cwd:

    python3 sync_pg_card_metadata_to_hermes.py
    python3 sync_pg_card_metadata_to_hermes.py --dry-run
    python3 sync_pg_card_metadata_to_hermes.py --report ../card_oracle_cache_report.json
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from known_cards_fallback_snapshot import load_layered_known_cards

try:
    from db_helper import connect, sanitized_database_target
except Exception as exc:  # pragma: no cover - exercised in lean containers.
    connect = None
    _DB_HELPER_IMPORT_ERROR = exc

    def sanitized_database_target() -> str:
        database_url = os.environ.get("DATABASE_URL")
        if database_url:
            parsed = urlparse(database_url)
            return f"{parsed.hostname}:{parsed.port or 5432}/{parsed.path.lstrip('/')}"
        host = os.environ.get("PGHOST") or os.environ.get("DB_HOST") or "unknown-host"
        port = os.environ.get("PGPORT") or os.environ.get("DB_PORT") or "5432"
        dbname = os.environ.get("PGDATABASE") or os.environ.get("DB_NAME") or "unknown-db"
        return f"{host}:{port}/{dbname}"


DEFAULT_SQLITE_DB = Path(
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
)

COMBAT_KEYWORDS = (
    "flying",
    "reach",
    "trample",
    "deathtouch",
    "first strike",
    "double strike",
    "lifelink",
    "indestructible",
    "vigilance",
    "haste",
    "menace",
)


def normalize_name(name: str | None) -> str:
    text = (name or "").strip().lower()
    text = re.sub(r"\s+", " ", text)
    return text


def front_face_name(name: str | None) -> str:
    return (name or "").split(" // ", 1)[0].strip()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sync PostgreSQL card metadata into Hermes card_oracle_cache."
    )
    parser.add_argument(
        "--sqlite-db",
        default=str(DEFAULT_SQLITE_DB),
        help="Path to Hermes knowledge.db.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Read both databases and print/report coverage without writing SQLite.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Limit requested unique card names for a small smoke run.",
    )
    parser.add_argument(
        "--report",
        default="",
        help="Optional JSON report path with sanitized coverage details.",
    )
    return parser.parse_args()


def ensure_cache_table(cur: sqlite3.Cursor) -> None:
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS card_oracle_cache (
            normalized_name TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            mana_cost TEXT,
            colors_json TEXT,
            color_identity_json TEXT,
            type_line TEXT,
            oracle_text TEXT,
            cmc REAL,
            power TEXT,
            toughness TEXT,
            keywords_json TEXT,
            scryfall_id TEXT,
            source TEXT NOT NULL DEFAULT 'postgres_cards',
            updated_at TEXT NOT NULL
        )
        """
    )


def column_names(cur: sqlite3.Cursor, table: str) -> set[str]:
    try:
        return {str(row[1]) for row in cur.execute(f"PRAGMA table_info({table})")}
    except sqlite3.Error:
        return set()


def ensure_deck_cards_metadata_columns(cur: sqlite3.Cursor) -> None:
    if not table_exists(cur, "deck_cards"):
        return
    columns = column_names(cur, "deck_cards")
    for name, ddl in (
        ("cmc", "REAL"),
        ("type_line", "TEXT"),
        ("oracle_text", "TEXT"),
    ):
        if name not in columns:
            cur.execute(f"ALTER TABLE deck_cards ADD COLUMN {name} {ddl}")


def collect_requested_names(cur: sqlite3.Cursor) -> set[str]:
    names: set[str] = set()

    if table_exists(cur, "deck_cards"):
        for (name,) in cur.execute(
            "SELECT DISTINCT card_name FROM deck_cards WHERE COALESCE(card_name,'')!=''"
        ):
            names.add(name)

    if table_exists(cur, "learned_decks"):
        for (commander, card_list) in cur.execute(
            """
            SELECT commander, card_list
            FROM learned_decks
            WHERE COALESCE(commander,'')!='' OR COALESCE(card_list,'')!=''
            """
        ):
            if commander:
                names.add(commander)
            if not card_list:
                continue
            try:
                decoded = json.loads(card_list)
            except Exception:
                continue
            if not isinstance(decoded, list):
                continue
            for card in decoded:
                if isinstance(card, dict) and card.get("name"):
                    names.add(str(card["name"]))

    if table_exists(cur, "slot_benchmarks"):
        for added, removed in cur.execute(
            """
            SELECT DISTINCT card_added, card_removed
            FROM slot_benchmarks
            WHERE COALESCE(card_added,'')!='' OR COALESCE(card_removed,'')!=''
            """
        ):
            if added:
                names.add(str(added))
            if removed:
                names.add(str(removed))

    if table_exists(cur, "swap_benchmarks"):
        for added, removed in cur.execute(
            """
            SELECT DISTINCT card_added, card_removed
            FROM swap_benchmarks
            WHERE COALESCE(card_added,'')!='' OR COALESCE(card_removed,'')!=''
            """
        ):
            if added:
                names.add(str(added))
            if removed:
                names.add(str(removed))

    if table_exists(cur, "battle_card_rules"):
        for (name,) in cur.execute(
            """
            SELECT DISTINCT card_name
            FROM battle_card_rules
            WHERE COALESCE(card_name,'')!=''
            """
        ):
            if name:
                names.add(str(name))

    known_cards, _canonical_names, _generated_only_names = load_layered_known_cards()
    names.update(str(name) for name in known_cards.keys() if name)

    return {name.strip() for name in names if name and name.strip()}


def table_exists(cur: sqlite3.Cursor, table: str) -> bool:
    row = cur.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        (table,),
    ).fetchone()
    return row is not None


def backfill_deck_cards_from_cache(
    cur: sqlite3.Cursor,
    *,
    dry_run: bool,
) -> dict[str, Any]:
    """Copy authoritative PG metadata from card_oracle_cache into deck_cards.

    `deck_cards` is the table used by Hermes optimizers/battle simulations.
    It can be older than `card_oracle_cache`, so this step makes CMC/type/oracle
    consistency explicit and measurable.
    """

    if not table_exists(cur, "deck_cards"):
        return {
            "deck_cards_table_present": False,
            "rows_total": 0,
            "matched_cache_rows": 0,
            "cmc_rows_to_update": 0,
            "cmc_rows_updated": 0,
            "suspicious_nonland_zero_cmc_after": 0,
        }

    ensure_deck_cards_metadata_columns(cur)
    total = cur.execute(
        "SELECT COUNT(*) FROM deck_cards WHERE COALESCE(card_name,'')!=''"
    ).fetchone()[0]
    matched = cur.execute(
        """
        SELECT COUNT(*)
        FROM deck_cards dc
        JOIN card_oracle_cache coc
          ON coc.normalized_name = lower(trim(dc.card_name))
        WHERE COALESCE(dc.card_name,'')!=''
        """
    ).fetchone()[0]
    cmc_to_update = cur.execute(
        """
        SELECT COUNT(*)
        FROM deck_cards dc
        JOIN card_oracle_cache coc
          ON coc.normalized_name = lower(trim(dc.card_name))
        WHERE coc.cmc IS NOT NULL
          AND (
            dc.cmc IS NULL
            OR abs(CAST(dc.cmc AS REAL) - CAST(coc.cmc AS REAL)) > 0.001
          )
        """
    ).fetchone()[0]

    if not dry_run:
        cur.execute(
            """
            UPDATE deck_cards
            SET
              cmc = COALESCE(
                (
                  SELECT coc.cmc
                  FROM card_oracle_cache coc
                  WHERE coc.normalized_name = lower(trim(deck_cards.card_name))
                    AND coc.cmc IS NOT NULL
                  LIMIT 1
                ),
                cmc
              ),
              type_line = COALESCE(
                (
                  SELECT NULLIF(coc.type_line, '')
                  FROM card_oracle_cache coc
                  WHERE coc.normalized_name = lower(trim(deck_cards.card_name))
                  LIMIT 1
                ),
                type_line
              ),
              oracle_text = COALESCE(
                (
                  SELECT NULLIF(coc.oracle_text, '')
                  FROM card_oracle_cache coc
                  WHERE coc.normalized_name = lower(trim(deck_cards.card_name))
                  LIMIT 1
                ),
                oracle_text
              )
            WHERE EXISTS (
              SELECT 1
              FROM card_oracle_cache coc
              WHERE coc.normalized_name = lower(trim(deck_cards.card_name))
            )
            """
        )

    suspicious_after = cur.execute(
        """
        SELECT COUNT(*)
        FROM deck_cards dc
        LEFT JOIN card_oracle_cache coc
          ON coc.normalized_name = lower(trim(dc.card_name))
        WHERE COALESCE(lower(COALESCE(coc.type_line, dc.type_line, '')), '') NOT LIKE '%land%'
          AND COALESCE(CAST(COALESCE(coc.cmc, dc.cmc, 0) AS REAL), 0) = 0
          AND COALESCE(coc.mana_cost, '') NOT IN ('', '{0}')
        """
    ).fetchone()[0]

    return {
        "deck_cards_table_present": True,
        "rows_total": int(total or 0),
        "matched_cache_rows": int(matched or 0),
        "cmc_rows_to_update": int(cmc_to_update or 0),
        "cmc_rows_updated": 0 if dry_run else int(cmc_to_update or 0),
        "suspicious_nonland_zero_cmc_after": int(suspicious_after or 0),
    }


def load_pg_columns() -> set[str]:
    if connect is None:
        rows = run_psql_json(
            """
            SELECT json_agg(column_name ORDER BY column_name)
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'cards'
            """
        )
        return set(rows or [])

    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT column_name
                FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = 'cards'
                """
            )
            return {row[0] for row in cur.fetchall()}


def run_psql_json(sql: str) -> Any:
    command = ["psql", "-X", "-q", "-t", "-A", "-c", sql]
    database_url = os.environ.get("DATABASE_URL")
    env = os.environ.copy()
    if database_url:
        command.insert(1, database_url)
    else:
        missing = [
            name
            for name in ("PGHOST", "PGDATABASE", "PGUSER", "PGPASSWORD")
            if not env.get(name)
        ]
        if missing:
            raise RuntimeError(
                "psycopg2 is unavailable and psql environment is incomplete: "
                + ", ".join(missing)
            )
    result = subprocess.run(
        command,
        env=env,
        capture_output=True,
        text=True,
        timeout=180,
    )
    if result.returncode != 0:
        detail = (result.stderr or "psql failed").strip().splitlines()[-1]
        raise RuntimeError(detail[:300])
    output = result.stdout.strip()
    if not output:
        return None
    return json.loads(output)


def selectable(column: str, pg_columns: set[str], fallback_sql: str) -> str:
    if column in pg_columns:
        return f"c.{column}"
    return fallback_sql


def pg_text_array(values: list[str]) -> str:
    escaped = [value.replace("\\", "\\\\").replace("'", "''") for value in values]
    return "ARRAY[" + ",".join(f"'{value}'" for value in escaped) + "]::text[]"


def cards_select_sql(pg_columns: set[str], names_sql: str | None = None) -> str:
    names_expression = names_sql or "%s"
    where = f"""
        WHERE lower(c.name) = ANY({names_expression})
           OR lower(split_part(c.name, ' // ', 1)) = ANY({names_expression})
    """
    return f"""
        SELECT
          c.name,
          {selectable('mana_cost', pg_columns, 'NULL::text')} AS mana_cost,
          {selectable('type_line', pg_columns, 'NULL::text')} AS type_line,
          {selectable('oracle_text', pg_columns, 'NULL::text')} AS oracle_text,
          {selectable('colors', pg_columns, 'NULL::text[]')} AS colors,
          {selectable('color_identity', pg_columns, 'NULL::text[]')} AS color_identity,
          {selectable('cmc', pg_columns, 'NULL::numeric')} AS cmc,
          {selectable('power', pg_columns, 'NULL::text')} AS power,
          {selectable('toughness', pg_columns, 'NULL::text')} AS toughness,
          {selectable('keywords', pg_columns, 'NULL::text[]')} AS keywords,
          {selectable('scryfall_id', pg_columns, 'NULL::uuid')}::text AS scryfall_id
        FROM cards c
        {where}
        ORDER BY c.name
    """


def fetch_pg_cards(names: set[str], pg_columns: set[str]) -> list[dict[str, Any]]:
    if not names:
        return []

    normalized = sorted({normalize_name(name) for name in names if normalize_name(name)})
    if connect is None:
        names_sql = pg_text_array(normalized)
        query = f"SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json) FROM ({cards_select_sql(pg_columns, names_sql)}) t"
        return run_psql_json(query)

    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(cards_select_sql(pg_columns), (normalized, normalized))
            columns = [desc[0] for desc in cur.description]
            return [dict(zip(columns, row)) for row in cur.fetchall()]


def extract_keywords(row: dict[str, Any]) -> list[str]:
    found = set()
    raw_keywords = row.get("keywords")
    if isinstance(raw_keywords, (list, tuple)):
        found.update(str(keyword).strip().lower() for keyword in raw_keywords if keyword)

    text = f"{row.get('type_line') or ''}\n{row.get('oracle_text') or ''}".lower()
    for keyword in COMBAT_KEYWORDS:
        if keyword in text:
            found.add(keyword.replace(" ", "_"))
    return sorted(keyword for keyword in found if keyword)


def json_list(value: Any) -> str:
    if value is None:
        return "[]"
    if isinstance(value, (list, tuple)):
        return json.dumps([str(item) for item in value if item is not None], ensure_ascii=True)
    if isinstance(value, str) and value.strip():
        return json.dumps([value.strip()], ensure_ascii=True)
    return "[]"


def cache_rows(pg_cards: list[dict[str, Any]]) -> list[tuple[Any, ...]]:
    now = datetime.now(timezone.utc).isoformat()
    rows: list[tuple[Any, ...]] = []
    seen: set[str] = set()

    for card in pg_cards:
        aliases = {normalize_name(card["name"]), normalize_name(front_face_name(card["name"]))}
        for alias in sorted(alias for alias in aliases if alias):
            if alias in seen:
                continue
            seen.add(alias)
            rows.append(
                (
                    alias,
                    card["name"],
                    card.get("mana_cost"),
                    json_list(card.get("colors")),
                    json_list(card.get("color_identity")),
                    card.get("type_line"),
                    card.get("oracle_text"),
                    float(card["cmc"]) if card.get("cmc") is not None else None,
                    card.get("power"),
                    card.get("toughness"),
                    json.dumps(extract_keywords(card), ensure_ascii=True),
                    card.get("scryfall_id"),
                    "postgres_cards",
                    now,
                )
            )
    return rows


def write_cache(cur: sqlite3.Cursor, rows: list[tuple[Any, ...]]) -> None:
    cur.executemany(
        """
        INSERT INTO card_oracle_cache (
            normalized_name, name, mana_cost, colors_json, color_identity_json,
            type_line, oracle_text, cmc, power, toughness, keywords_json,
            scryfall_id, source, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(normalized_name) DO UPDATE SET
            name = excluded.name,
            mana_cost = excluded.mana_cost,
            colors_json = excluded.colors_json,
            color_identity_json = excluded.color_identity_json,
            type_line = excluded.type_line,
            oracle_text = excluded.oracle_text,
            cmc = excluded.cmc,
            power = excluded.power,
            toughness = excluded.toughness,
            keywords_json = excluded.keywords_json,
            scryfall_id = excluded.scryfall_id,
            source = excluded.source,
            updated_at = excluded.updated_at
        """,
        rows,
    )


def build_report(
    *,
    requested_names: set[str],
    pg_cards: list[dict[str, Any]],
    rows: list[tuple[Any, ...]],
    pg_columns: set[str],
    dry_run: bool,
    deck_cards_backfill: dict[str, Any],
) -> dict[str, Any]:
    resolved_aliases = {row[0] for row in rows}
    unresolved = sorted(
        name for name in requested_names if normalize_name(name) not in resolved_aliases
    )
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "dry_run": dry_run,
        "postgres_target": sanitized_database_target(),
        "requested_unique_names": len(requested_names),
        "postgres_cards_matched": len(pg_cards),
        "sqlite_cache_alias_rows": len(rows),
        "unresolved_count": len(unresolved),
        "unresolved_sample": unresolved[:50],
        "postgres_columns_present": sorted(
            column
            for column in (
                "mana_cost",
                "colors",
                "color_identity",
                "type_line",
                "oracle_text",
                "cmc",
                "power",
                "toughness",
                "keywords",
                "scryfall_id",
            )
            if column in pg_columns
        ),
        "field_coverage": {
            "mana_cost": sum(1 for card in pg_cards if card.get("mana_cost")),
            "oracle_text": sum(1 for card in pg_cards if card.get("oracle_text")),
            "colors": sum(1 for card in pg_cards if card.get("colors")),
            "color_identity": sum(1 for card in pg_cards if card.get("color_identity")),
            "power": sum(1 for card in pg_cards if card.get("power")),
            "toughness": sum(1 for card in pg_cards if card.get("toughness")),
            "keywords": sum(1 for card in pg_cards if extract_keywords(card)),
        },
        "deck_cards_backfill": deck_cards_backfill,
    }


def main() -> None:
    args = parse_args()
    sqlite_db = Path(args.sqlite_db)
    sqlite_db.parent.mkdir(parents=True, exist_ok=True)

    sqlite_conn = sqlite3.connect(sqlite_db)
    sqlite_cur = sqlite_conn.cursor()
    ensure_cache_table(sqlite_cur)

    requested_names = collect_requested_names(sqlite_cur)
    if args.limit and args.limit > 0:
        requested_names = set(sorted(requested_names)[: args.limit])

    pg_columns = load_pg_columns()
    pg_cards = fetch_pg_cards(requested_names, pg_columns)
    rows = cache_rows(pg_cards)

    if not args.dry_run:
        write_cache(sqlite_cur, rows)
        deck_cards_backfill = backfill_deck_cards_from_cache(
            sqlite_cur,
            dry_run=False,
        )
        sqlite_conn.commit()
    else:
        deck_cards_backfill = backfill_deck_cards_from_cache(
            sqlite_cur,
            dry_run=True,
        )
        sqlite_conn.rollback()

    report = build_report(
        requested_names=requested_names,
        pg_cards=pg_cards,
        rows=rows,
        pg_columns=pg_columns,
        dry_run=args.dry_run,
        deck_cards_backfill=deck_cards_backfill,
    )

    if args.report:
        Path(args.report).write_text(
            json.dumps(report, indent=2, ensure_ascii=True) + "\n",
            encoding="utf-8",
        )

    print(f"postgres target: {report['postgres_target']}")
    print(f"requested unique names: {report['requested_unique_names']}")
    print(f"postgres cards matched: {report['postgres_cards_matched']}")
    print(f"sqlite cache alias rows: {report['sqlite_cache_alias_rows']}")
    print(
        "deck_cards backfill: "
        f"present={deck_cards_backfill['deck_cards_table_present']} "
        f"matched={deck_cards_backfill['matched_cache_rows']}/"
        f"{deck_cards_backfill['rows_total']} "
        f"cmc_updates={deck_cards_backfill['cmc_rows_updated']} "
        "suspicious_nonland_zero_cmc_after="
        f"{deck_cards_backfill['suspicious_nonland_zero_cmc_after']}"
    )
    print(f"unresolved: {report['unresolved_count']}")
    print(f"dry_run: {report['dry_run']}")

    sqlite_conn.close()


if __name__ == "__main__":
    main()
