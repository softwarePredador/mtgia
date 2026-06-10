#!/usr/bin/env python3
"""Sync Hermes battle/deckbuilding rules with PostgreSQL.

Postgres is the reviewable source of truth for executable card semantics.
SQLite remains the fast local cache used by battle/optimizer cron jobs.

Typical Hermes cron flow:

    python3 sync_battle_card_rules_pg.py --apply-pg
    python3 sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review

The first command seeds/updates PG from current manual/generated rules. The
second command refreshes the local SQLite cache from PG before simulations.
"""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import battle_rule_registry
from battle_rule_registry import DEFAULT_DB, normalize_card_name, upsert_battle_card_rule
from sync_battle_card_rules import build_rows

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


SOURCE_PRIORITY = {
    "manual": 100,
    "curated": 90,
    "generated": 40,
    "imported": 30,
    "heuristic": 20,
}

PG_SCHEMA = """
CREATE TABLE IF NOT EXISTS card_battle_rules (
  normalized_name TEXT PRIMARY KEY,
  card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
  card_name TEXT NOT NULL,
  effect_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  deck_role_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  source TEXT NOT NULL DEFAULT 'manual',
  confidence NUMERIC(4,3) NOT NULL DEFAULT 1.0
    CHECK (confidence >= 0 AND confidence <= 1),
  review_status TEXT NOT NULL DEFAULT 'verified',
  rule_version INTEGER NOT NULL DEFAULT 1 CHECK (rule_version >= 1),
  oracle_hash TEXT,
  notes TEXT,
  reviewed_by TEXT,
  reviewed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TIMESTAMP WITH TIME ZONE,
  CONSTRAINT chk_card_battle_rules_source CHECK (
    source IN ('manual', 'curated', 'generated', 'heuristic', 'imported')
  ),
  CONSTRAINT chk_card_battle_rules_review_status CHECK (
    review_status IN (
      'verified',
      'active',
      'needs_review',
      'rejected',
      'deprecated'
    )
  )
);
"""


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sync Hermes battle card rules with PostgreSQL."
    )
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument("--skip-generated", action="store_true")
    parser.add_argument(
        "--include-needs-review",
        action="store_true",
        help="Mirror PG needs_review rules into SQLite cache for broad coverage.",
    )
    parser.add_argument(
        "--apply-pg",
        action="store_true",
        help="Upsert current manual/generated rules into PostgreSQL.",
    )
    parser.add_argument(
        "--apply-sqlite-from-pg",
        action="store_true",
        help="Refresh SQLite battle_card_rules from PostgreSQL.",
    )
    parser.add_argument("--report")
    return parser.parse_args()


def require_pg() -> None:
    if connect is None:
        raise RuntimeError(
            "PostgreSQL helper is unavailable; install psycopg2 or provide db_helper.py. "
            f"Import error: {_DB_HELPER_IMPORT_ERROR}"
        )


def safe_database_target() -> str:
    try:
        return sanitized_database_target()
    except Exception:
        host = os.environ.get("PGHOST") or os.environ.get("DB_HOST") or "unknown-host"
        port = os.environ.get("PGPORT") or os.environ.get("DB_PORT") or "5432"
        dbname = os.environ.get("PGDATABASE") or os.environ.get("DB_NAME") or "unknown-db"
        return f"{host}:{port}/{dbname}"


def json_obj(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def ensure_pg_table(cur: Any) -> None:
    for statement in [part.strip() for part in PG_SCHEMA.split(";") if part.strip()]:
        cur.execute(statement)


def resolve_card_id(cur: Any, card_name: str) -> str | None:
    front_face = card_name.split(" // ", 1)[0].strip()
    cur.execute(
        """
        SELECT id::text
        FROM cards
        WHERE lower(name) = lower(%s)
           OR lower(split_part(name, ' // ', 1)) = lower(%s)
        ORDER BY CASE WHEN lower(name) = lower(%s) THEN 0 ELSE 1 END
        LIMIT 1
        """,
        (card_name, front_face, card_name),
    )
    row = cur.fetchone()
    return row[0] if row else None


def current_pg_source(cur: Any, normalized_name: str) -> str | None:
    cur.execute(
        "SELECT source FROM card_battle_rules WHERE normalized_name = %s",
        (normalized_name,),
    )
    row = cur.fetchone()
    return str(row[0]) if row else None


def load_current_sources(cur: Any) -> dict[str, str]:
    cur.execute("SELECT normalized_name, source FROM card_battle_rules")
    return {str(row[0]): str(row[1]) for row in cur.fetchall()}


def load_card_id_lookup(cur: Any, card_names: list[str]) -> dict[str, str]:
    normalized_exact = sorted({normalize_card_name(name) for name in card_names})
    normalized_fronts = sorted(
        {normalize_card_name(name.split(" // ", 1)[0]) for name in card_names}
    )
    cur.execute(
        """
        SELECT id::text, name
        FROM cards
        WHERE lower(name) = ANY(%s)
           OR lower(split_part(name, ' // ', 1)) = ANY(%s)
        """,
        (normalized_exact, normalized_fronts),
    )
    exact: dict[str, str] = {}
    front: dict[str, str] = {}
    for card_id, name in cur.fetchall():
        exact[normalize_card_name(name)] = card_id
        front.setdefault(normalize_card_name(str(name).split(" // ", 1)[0]), card_id)

    lookup: dict[str, str] = {}
    for card_name in card_names:
        normalized = normalize_card_name(card_name)
        front_name = normalize_card_name(card_name.split(" // ", 1)[0])
        card_id = exact.get(normalized) or front.get(front_name)
        if card_id:
            lookup[normalized] = card_id
    return lookup


def upsert_pg_rule(cur: Any, row: dict[str, Any]) -> bool:
    card_name = str(row["card_name"])
    normalized_name = normalize_card_name(card_name)
    source = str(row.get("source") or "manual")
    current_source = current_pg_source(cur, normalized_name)
    if current_source:
        incoming_priority = SOURCE_PRIORITY.get(source, 0)
        current_priority = SOURCE_PRIORITY.get(current_source, 0)
        if incoming_priority < current_priority:
            cur.execute(
                """
                UPDATE card_battle_rules
                SET last_seen_at = CURRENT_TIMESTAMP
                WHERE normalized_name = %s
                """,
                (normalized_name,),
            )
            return False

    card_id = resolve_card_id(cur, card_name)
    effect_json = json.dumps(
        json_obj(row.get("effect_json")),
        ensure_ascii=True,
        sort_keys=True,
    )
    deck_role = row.get("deck_role_json")
    if not isinstance(deck_role, dict):
        deck_role = battle_rule_registry.deck_role_from_effect(json_obj(row.get("effect_json")))
    deck_role_json = json.dumps(deck_role, ensure_ascii=True, sort_keys=True)

    cur.execute(
        """
        INSERT INTO card_battle_rules (
          normalized_name,
          card_id,
          card_name,
          effect_json,
          deck_role_json,
          source,
          confidence,
          review_status,
          rule_version,
          oracle_hash,
          notes,
          reviewed_at,
          created_at,
          updated_at,
          last_seen_at
        )
        VALUES (
          %s, %s, %s, %s::jsonb, %s::jsonb, %s, %s, %s, 1, %s, %s,
          CASE WHEN %s IN ('verified', 'active') THEN CURRENT_TIMESTAMP ELSE NULL END,
          CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        )
        ON CONFLICT (normalized_name) DO UPDATE SET
          card_id = COALESCE(EXCLUDED.card_id, card_battle_rules.card_id),
          card_name = EXCLUDED.card_name,
          effect_json = EXCLUDED.effect_json,
          deck_role_json = EXCLUDED.deck_role_json,
          source = EXCLUDED.source,
          confidence = EXCLUDED.confidence,
          review_status = EXCLUDED.review_status,
          oracle_hash = EXCLUDED.oracle_hash,
          notes = EXCLUDED.notes,
          reviewed_at = CASE
            WHEN EXCLUDED.review_status IN ('verified', 'active') THEN CURRENT_TIMESTAMP
            ELSE card_battle_rules.reviewed_at
          END,
          updated_at = CURRENT_TIMESTAMP,
          last_seen_at = CURRENT_TIMESTAMP
        """,
        (
            normalized_name,
            card_id,
            card_name,
            effect_json,
            deck_role_json,
            source,
            float(row.get("confidence", 1.0)),
            str(row.get("review_status") or "verified"),
            row.get("oracle_hash"),
            str(row.get("notes") or ""),
            str(row.get("review_status") or "verified"),
        ),
    )
    return True


def upsert_pg_rules(cur: Any, rows: list[dict[str, Any]]) -> tuple[int, int]:
    from psycopg2.extras import execute_values

    current_sources = load_current_sources(cur)
    card_lookup = load_card_id_lookup(
        cur,
        [str(row["card_name"]) for row in rows if row.get("card_name")],
    )
    values: list[tuple[Any, ...]] = []
    skipped_names: list[str] = []
    for row in rows:
        card_name = str(row["card_name"])
        normalized_name = normalize_card_name(card_name)
        source = str(row.get("source") or "manual")
        current_source = current_sources.get(normalized_name)
        if current_source:
            incoming_priority = SOURCE_PRIORITY.get(source, 0)
            current_priority = SOURCE_PRIORITY.get(current_source, 0)
            if incoming_priority < current_priority:
                skipped_names.append(normalized_name)
                continue

        effect = json_obj(row.get("effect_json"))
        deck_role = row.get("deck_role_json")
        if not isinstance(deck_role, dict):
            deck_role = battle_rule_registry.deck_role_from_effect(effect)
        review_status = str(row.get("review_status") or "verified")
        reviewed_at = datetime.now(timezone.utc) if review_status in ("verified", "active") else None
        values.append(
            (
                normalized_name,
                card_lookup.get(normalized_name),
                card_name,
                json.dumps(effect, ensure_ascii=True, sort_keys=True),
                json.dumps(deck_role, ensure_ascii=True, sort_keys=True),
                source,
                float(row.get("confidence", 1.0)),
                review_status,
                row.get("oracle_hash"),
                str(row.get("notes") or ""),
                reviewed_at,
            )
        )

    if skipped_names:
        cur.execute(
            """
            UPDATE card_battle_rules
            SET last_seen_at = CURRENT_TIMESTAMP
            WHERE normalized_name = ANY(%s)
            """,
            (skipped_names,),
        )

    if values:
        execute_values(
            cur,
            """
            INSERT INTO card_battle_rules (
              normalized_name,
              card_id,
              card_name,
              effect_json,
              deck_role_json,
              source,
              confidence,
              review_status,
              rule_version,
              oracle_hash,
              notes,
              reviewed_at,
              created_at,
              updated_at,
              last_seen_at
            )
            VALUES %s
            ON CONFLICT (normalized_name) DO UPDATE SET
              card_id = COALESCE(EXCLUDED.card_id, card_battle_rules.card_id),
              card_name = EXCLUDED.card_name,
              effect_json = EXCLUDED.effect_json,
              deck_role_json = EXCLUDED.deck_role_json,
              source = EXCLUDED.source,
              confidence = EXCLUDED.confidence,
              review_status = EXCLUDED.review_status,
              oracle_hash = EXCLUDED.oracle_hash,
              notes = EXCLUDED.notes,
              reviewed_at = CASE
                WHEN EXCLUDED.review_status IN ('verified', 'active')
                  THEN COALESCE(card_battle_rules.reviewed_at, EXCLUDED.reviewed_at)
                ELSE card_battle_rules.reviewed_at
              END,
              updated_at = CURRENT_TIMESTAMP,
              last_seen_at = CURRENT_TIMESTAMP
            """,
            values,
            template=(
                "(%s, %s, %s, %s::jsonb, %s::jsonb, %s, %s, %s, 1, %s, %s, "
                "%s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
            ),
            page_size=250,
        )
    return len(values), len(skipped_names)


def load_pg_rules(cur: Any, *, include_needs_review: bool) -> list[dict[str, Any]]:
    statuses = ["verified", "active"]
    if include_needs_review:
        statuses.append("needs_review")
    cur.execute(
        """
        SELECT
          normalized_name,
          card_name,
          effect_json,
          deck_role_json,
          source,
          confidence::float,
          review_status,
          rule_version,
          oracle_hash,
          notes
        FROM card_battle_rules
        WHERE review_status = ANY(%s)
        ORDER BY normalized_name
        """,
        (statuses,),
    )
    loaded: list[dict[str, Any]] = []
    for row in cur.fetchall():
        loaded.append(
            {
                "normalized_name": row[0],
                "card_name": row[1],
                "effect_json": json_obj(row[2]),
                "deck_role_json": json_obj(row[3]),
                "source": row[4],
                "confidence": float(row[5]),
                "review_status": row[6],
                "rule_version": int(row[7]),
                "oracle_hash": row[8],
                "notes": row[9] or "",
            }
        )
    return loaded


def mirror_pg_rules_to_sqlite(sqlite_db: str, rows: list[dict[str, Any]]) -> int:
    changed = 0
    with sqlite3.connect(sqlite_db) as conn:
        battle_rule_registry.ensure_battle_card_rules(conn)
        for row in rows:
            did_change = upsert_battle_card_rule(
                conn,
                row["card_name"],
                row["effect_json"],
                source=row["source"],
                confidence=row["confidence"],
                review_status=row["review_status"],
                deck_role_json=row["deck_role_json"],
                notes=row["notes"],
                oracle_hash=row["oracle_hash"],
            )
            if did_change:
                changed += 1
        conn.commit()
    return changed


def main() -> int:
    args = parse_args()
    seed_rows = build_rows(
        include_generated=not args.skip_generated,
        sqlite_db=args.sqlite_db,
    )
    report: dict[str, Any] = {
        "generated_at": utc_now(),
        "database_target": safe_database_target(),
        "sqlite_db": args.sqlite_db,
        "apply_pg": bool(args.apply_pg),
        "apply_sqlite_from_pg": bool(args.apply_sqlite_from_pg),
        "include_generated": not args.skip_generated,
        "include_needs_review": bool(args.include_needs_review),
        "input_rows": len(seed_rows),
        "manual_rows": sum(1 for row in seed_rows if row["source"] == "manual"),
        "generated_rows": sum(1 for row in seed_rows if row["source"] == "generated"),
        "oracle_normalized_rows": sum(
            1 for row in seed_rows if row.get("_oracle_normalized")
        ),
        "pg_inserted_or_updated": 0,
        "pg_skipped_lower_priority": 0,
        "pg_rows_loaded": 0,
        "sqlite_inserted_or_updated": 0,
    }

    if args.apply_pg or args.apply_sqlite_from_pg:
        require_pg()

    if args.apply_pg:
        with connect() as conn:
            with conn.cursor() as cur:
                ensure_pg_table(cur)
                changed, skipped = upsert_pg_rules(cur, seed_rows)
                report["pg_inserted_or_updated"] += changed
                report["pg_skipped_lower_priority"] += skipped

    if args.apply_sqlite_from_pg:
        with connect() as conn:
            with conn.cursor() as cur:
                ensure_pg_table(cur)
                rows = load_pg_rules(cur, include_needs_review=args.include_needs_review)
        report["pg_rows_loaded"] = len(rows)
        report["sqlite_inserted_or_updated"] = mirror_pg_rules_to_sqlite(
            args.sqlite_db,
            rows,
        )

    output = json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True)
    print(output)
    if args.report:
        Path(args.report).write_text(output + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
