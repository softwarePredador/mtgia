#!/usr/bin/env python3
"""Sync Hermes battle/deckbuilding rules with PostgreSQL.

Postgres is the reviewable source of truth for executable card semantics.
SQLite remains the fast local cache used by battle/optimizer cron jobs.

Typical Hermes cron flow:

    python3 sync_battle_card_rules_pg.py --apply-pg
    python3 sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review

The first command now mainly mirrors generated rules or explicit temporary
runtime waivers into PG. Canonical card-specific manual inventory was removed
from the active runtime on 2026-06-16. The second command refreshes the local
SQLite cache from PG before simulations.
"""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import battle_rule_registry
from battle_rule_registry import DEFAULT_DB, normalize_card_name, upsert_battle_card_rule
from known_cards_fallback_snapshot import (
    build_snapshot_payload,
    resolve_canonical_snapshot_path,
    write_snapshot_payload,
)
from reviewed_battle_card_rules import DEFAULT_REVIEWED_RULES_PATH
from sync_battle_card_rules import (
    _oracle_normalized_rows,
    build_rows,
    cleanup_obsolete_manual_rows,
    cleanup_stale_reviewed_rows,
)

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
  normalized_name TEXT NOT NULL,
  logical_rule_key TEXT NOT NULL,
  card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
  card_name TEXT NOT NULL,
  effect_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  deck_role_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  source TEXT NOT NULL DEFAULT 'curated',
  confidence NUMERIC(4,3) NOT NULL DEFAULT 1.0
    CHECK (confidence >= 0 AND confidence <= 1),
  review_status TEXT NOT NULL DEFAULT 'verified',
  execution_status TEXT NOT NULL DEFAULT 'auto',
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
  ),
  CONSTRAINT chk_card_battle_rules_execution_status CHECK (
    execution_status IN (
      'auto',
      'executable',
      'annotation_only',
      'review_only',
      'disabled'
    )
  ),
  PRIMARY KEY (normalized_name, logical_rule_key)
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
        "--reviewed-rules-json",
        default=str(DEFAULT_REVIEWED_RULES_PATH),
        help="Versioned reviewed battle rule layer to seed before generated rules.",
    )
    parser.add_argument(
        "--include-needs-review",
        action="store_true",
        help="Mirror PG needs_review rules into SQLite cache for broad coverage.",
    )
    parser.add_argument(
        "--apply-pg",
        action="store_true",
        help="Upsert current generated rules and explicit runtime waivers into PostgreSQL.",
    )
    parser.add_argument(
        "--apply-sqlite-from-pg",
        action="store_true",
        help="Refresh SQLite battle_card_rules from PostgreSQL.",
    )
    parser.add_argument(
        "--export-canonical-fallback-json",
        default=str(resolve_canonical_snapshot_path()),
        help="Write a canonical fallback JSON snapshot after PG -> SQLite refresh.",
    )
    parser.add_argument(
        "--only-card",
        action="append",
        default=[],
        help="Restrict apply/mirror to specific card names. Can be repeated.",
    )
    parser.add_argument(
        "--only-summary-json",
        help="Audit summary JSON to derive a card subset.",
    )
    parser.add_argument(
        "--only-classification",
        action="append",
        default=[],
        help="When used with --only-summary-json, restrict to matching classifications.",
    )
    parser.add_argument(
        "--only-recommended-action",
        action="append",
        default=[],
        help="When used with --only-summary-json, restrict to matching recommended actions.",
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


def load_summary_entries(path: str | Path | None) -> list[dict[str, Any]]:
    if not path:
        return []
    payload = json.loads(Path(path).read_text(encoding="utf-8"))
    entries = payload.get("entries")
    return entries if isinstance(entries, list) else []


def resolve_selected_card_names(args: argparse.Namespace) -> list[str]:
    selected = {str(name).strip() for name in (args.only_card or []) if str(name).strip()}
    summary_entries = load_summary_entries(args.only_summary_json)
    if summary_entries:
        classifications = {str(value).strip() for value in (args.only_classification or []) if str(value).strip()}
        actions = {
            str(value).strip()
            for value in (args.only_recommended_action or [])
            if str(value).strip()
        }
        for entry in summary_entries:
            if not isinstance(entry, dict):
                continue
            if classifications and str(entry.get("classification") or "") not in classifications:
                continue
            if actions and str(entry.get("recommended_action") or "") not in actions:
                continue
            card_name = str(entry.get("card_name") or "").strip()
            if card_name:
                selected.add(card_name)
    return sorted(selected)


def filter_rows_by_card_names(rows: list[dict[str, Any]], card_names: list[str]) -> list[dict[str, Any]]:
    if not card_names:
        return rows
    allowed = {normalize_card_name(name) for name in card_names}
    return [
        row
        for row in rows
        if normalize_card_name(str(row.get("card_name") or "")) in allowed
    ]


def ensure_pg_table(cur: Any) -> None:
    for statement in [part.strip() for part in PG_SCHEMA.split(";") if part.strip()]:
        cur.execute(statement)
    cur.execute("ALTER TABLE card_battle_rules ADD COLUMN IF NOT EXISTS logical_rule_key TEXT")
    cur.execute("ALTER TABLE card_battle_rules ADD COLUMN IF NOT EXISTS execution_status TEXT")
    cur.execute(
        """
        UPDATE card_battle_rules
        SET execution_status = CASE
          WHEN review_status IN ('rejected', 'deprecated') THEN 'disabled'
          WHEN review_status = 'needs_review' THEN 'review_only'
          ELSE 'auto'
        END
        WHERE execution_status IS NULL OR execution_status = ''
        """
    )
    cur.execute(
        """
        ALTER TABLE card_battle_rules
        ALTER COLUMN execution_status SET DEFAULT 'auto'
        """
    )
    cur.execute(
        """
        ALTER TABLE card_battle_rules
        ALTER COLUMN execution_status SET NOT NULL
        """
    )
    cur.execute(
        """
        UPDATE card_battle_rules
        SET logical_rule_key = 'battle_rule_v1:' || substring(md5(
          jsonb_build_object(
            'effect', COALESCE(effect_json, '{}'::jsonb),
            'deck_role', COALESCE(deck_role_json, '{}'::jsonb),
            'face_name', COALESCE(effect_json->>'face_name', deck_role_json->>'face_name'),
            'face_index', COALESCE(effect_json->>'face_index', deck_role_json->>'face_index'),
            'variant_kind', COALESCE(effect_json->>'variant_kind', deck_role_json->>'variant_kind'),
            'ability_kind', COALESCE(effect_json->>'ability_kind', deck_role_json->>'ability_kind'),
            'timing_window', COALESCE(effect_json->>'timing_window', deck_role_json->>'timing_window'),
            'source_zone', COALESCE(effect_json->>'source_zone', deck_role_json->>'source_zone')
          )::text
        ) from 1 for 32)
        WHERE logical_rule_key IS NULL OR logical_rule_key = ''
        """
    )
    cur.execute(
        """
        CREATE UNIQUE INDEX IF NOT EXISTS idx_card_battle_rules_name_rule_key
        ON card_battle_rules (normalized_name, logical_rule_key)
        """
    )
    cur.execute(
        """
        ALTER TABLE card_battle_rules
        ALTER COLUMN logical_rule_key SET NOT NULL
        """
    )
    cur.execute(
        """
        DO $$
        DECLARE
          pk_name text;
          pk_cols text[];
        BEGIN
          SELECT conname,
                 array_agg(att.attname ORDER BY ord.ordinality)
            INTO pk_name, pk_cols
          FROM pg_constraint con
          JOIN unnest(con.conkey) WITH ORDINALITY AS ord(attnum, ordinality)
            ON true
          JOIN pg_attribute att
            ON att.attrelid = con.conrelid
           AND att.attnum = ord.attnum
          WHERE con.conrelid = 'card_battle_rules'::regclass
            AND con.contype = 'p'
          GROUP BY con.conname;

          IF pk_name IS NOT NULL AND pk_cols <> ARRAY['normalized_name', 'logical_rule_key'] THEN
            EXECUTE format('ALTER TABLE card_battle_rules DROP CONSTRAINT %I', pk_name);
            pk_name := NULL;
          END IF;

          IF pk_name IS NULL THEN
            ALTER TABLE card_battle_rules
            ADD CONSTRAINT card_battle_rules_pkey
            PRIMARY KEY (normalized_name, logical_rule_key);
          END IF;
        END $$;
        """
    )
    cur.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_card_battle_rules_normalized_name
        ON card_battle_rules (normalized_name)
        """
    )


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


def current_pg_source(
    cur: Any,
    normalized_name: str,
    logical_rule_key: str,
) -> str | None:
    cur.execute(
        """
        SELECT source
        FROM card_battle_rules
        WHERE normalized_name = %s
          AND logical_rule_key = %s
        """,
        (normalized_name, logical_rule_key),
    )
    row = cur.fetchone()
    return str(row[0]) if row else None


def load_current_sources(cur: Any) -> dict[tuple[str, str], str]:
    cur.execute("SELECT normalized_name, logical_rule_key, source FROM card_battle_rules")
    return {(str(row[0]), str(row[1])): str(row[2]) for row in cur.fetchall()}


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
    source = str(row.get("source") or "curated")
    execution_status = str(row.get("execution_status") or "auto")
    card_id = resolve_card_id(cur, card_name)
    effect = json_obj(row.get("effect_json"))
    deck_role = row.get("deck_role_json")
    if not isinstance(deck_role, dict):
        deck_role = battle_rule_registry.deck_role_from_effect(effect)
    logical_rule_key = str(
        row.get("logical_rule_key")
        or battle_rule_registry.logical_rule_key(
            {"effect_json": effect, "deck_role_json": deck_role}
        )
    )
    current_source = current_pg_source(cur, normalized_name, logical_rule_key)
    if current_source:
        incoming_priority = SOURCE_PRIORITY.get(source, 0)
        current_priority = SOURCE_PRIORITY.get(current_source, 0)
        if incoming_priority < current_priority:
            cur.execute(
                """
                UPDATE card_battle_rules
                SET last_seen_at = CURRENT_TIMESTAMP
                WHERE normalized_name = %s
                  AND logical_rule_key = %s
                """,
                (normalized_name, logical_rule_key),
            )
            return False

    effect_json = json.dumps(effect, ensure_ascii=True, sort_keys=True)
    deck_role_json = json.dumps(deck_role, ensure_ascii=True, sort_keys=True)

    cur.execute(
        """
        INSERT INTO card_battle_rules (
          normalized_name,
          logical_rule_key,
          card_id,
          card_name,
          effect_json,
          deck_role_json,
          source,
          confidence,
          review_status,
          execution_status,
          rule_version,
          oracle_hash,
          notes,
          reviewed_at,
          created_at,
          updated_at,
          last_seen_at
        )
        VALUES (
          %s, %s, %s, %s, %s::jsonb, %s::jsonb, %s, %s, %s, %s, 1, %s, %s,
          CASE WHEN %s IN ('verified', 'active') THEN CURRENT_TIMESTAMP ELSE NULL END,
          CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        )
        ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE SET
          card_id = COALESCE(EXCLUDED.card_id, card_battle_rules.card_id),
          card_name = EXCLUDED.card_name,
          effect_json = EXCLUDED.effect_json,
          deck_role_json = EXCLUDED.deck_role_json,
          source = EXCLUDED.source,
          confidence = EXCLUDED.confidence,
          review_status = EXCLUDED.review_status,
          execution_status = EXCLUDED.execution_status,
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
            logical_rule_key,
            card_id,
            card_name,
            effect_json,
            deck_role_json,
            source,
            float(row.get("confidence", 1.0)),
            str(row.get("review_status") or "verified"),
            execution_status,
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
    skipped_keys: list[tuple[str, str]] = []
    for row in rows:
        card_name = str(row["card_name"])
        normalized_name = normalize_card_name(card_name)
        source = str(row.get("source") or "curated")
        effect = json_obj(row.get("effect_json"))
        deck_role = row.get("deck_role_json")
        if not isinstance(deck_role, dict):
            deck_role = battle_rule_registry.deck_role_from_effect(effect)
        logical_rule_key = str(
            row.get("logical_rule_key")
            or battle_rule_registry.logical_rule_key(
                {"effect_json": effect, "deck_role_json": deck_role}
            )
        )
        current_source = current_sources.get((normalized_name, logical_rule_key))
        if current_source:
            incoming_priority = SOURCE_PRIORITY.get(source, 0)
            current_priority = SOURCE_PRIORITY.get(current_source, 0)
            if incoming_priority < current_priority:
                skipped_keys.append((normalized_name, logical_rule_key))
                continue

        review_status = str(row.get("review_status") or "verified")
        reviewed_at = datetime.now(timezone.utc) if review_status in ("verified", "active") else None
        values.append(
            (
                normalized_name,
                logical_rule_key,
                card_lookup.get(normalized_name),
                card_name,
                json.dumps(effect, ensure_ascii=True, sort_keys=True),
                json.dumps(deck_role, ensure_ascii=True, sort_keys=True),
                source,
                float(row.get("confidence", 1.0)),
                review_status,
                str(row.get("execution_status") or "auto"),
                row.get("oracle_hash"),
                str(row.get("notes") or ""),
                reviewed_at,
            )
        )

    if skipped_keys:
        for normalized_name, logical_rule_key in skipped_keys:
            cur.execute(
                """
                UPDATE card_battle_rules
                SET last_seen_at = CURRENT_TIMESTAMP
                WHERE normalized_name = %s
                  AND logical_rule_key = %s
                """,
                (normalized_name, logical_rule_key),
            )

    if values:
        execute_values(
            cur,
            """
            INSERT INTO card_battle_rules (
              normalized_name,
              logical_rule_key,
              card_id,
              card_name,
              effect_json,
              deck_role_json,
              source,
              confidence,
              review_status,
              execution_status,
              rule_version,
              oracle_hash,
              notes,
              reviewed_at,
              created_at,
              updated_at,
              last_seen_at
            )
            VALUES %s
            ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE SET
              card_id = COALESCE(EXCLUDED.card_id, card_battle_rules.card_id),
              card_name = EXCLUDED.card_name,
              effect_json = EXCLUDED.effect_json,
              deck_role_json = EXCLUDED.deck_role_json,
              source = EXCLUDED.source,
              confidence = EXCLUDED.confidence,
              review_status = EXCLUDED.review_status,
              execution_status = EXCLUDED.execution_status,
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
                "(%s, %s, %s, %s, %s::jsonb, %s::jsonb, %s, %s, %s, %s, 1, %s, %s, "
                "%s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
            ),
            page_size=250,
        )
    return len(values), len(skipped_keys)


def load_pg_rules(cur: Any, *, include_needs_review: bool) -> list[dict[str, Any]]:
    statuses = ["verified", "active"]
    if include_needs_review:
        statuses.append("needs_review")
    cur.execute(
        """
        SELECT
          normalized_name,
          logical_rule_key,
          card_name,
          effect_json,
          deck_role_json,
          source,
          confidence::float,
          review_status,
          execution_status,
          rule_version,
          oracle_hash,
          notes,
          updated_at,
          last_seen_at
        FROM card_battle_rules
        WHERE review_status = ANY(%s)
        ORDER BY normalized_name, logical_rule_key
        """,
        (statuses,),
    )
    loaded: list[dict[str, Any]] = []
    for row in cur.fetchall():
        loaded.append(
            {
                "normalized_name": row[0],
                "logical_rule_key": row[1],
                "card_name": row[2],
                "effect_json": json_obj(row[3]),
                "deck_role_json": json_obj(row[4]),
                "source": row[5],
                "confidence": float(row[6]),
                "review_status": row[7],
                "execution_status": row[8],
                "rule_version": int(row[9]),
                "oracle_hash": row[10],
                "notes": row[11] or "",
                "updated_at": row[12],
                "last_seen_at": row[13],
            }
        )
    return loaded


def filter_rows_for_current_reviewed_curated(
    rows: list[dict[str, Any]],
    reviewed_rows: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Keep reviewed curated cards aligned with the current reviewed corpus.

    PostgreSQL may temporarily contain historical curated siblings for the same
    card while the reviewed JSON has already moved to a newer logical rule. For
    the SQLite runtime cache we prefer the current reviewed layer for those
    cards, while preserving generated/manual rows and any cards outside the
    reviewed set.
    """
    allowed_by_name: dict[str, set[str]] = {}
    for row in reviewed_rows:
        if str(row.get("source") or "") != "curated":
            continue
        card_name = str(row.get("card_name") or "").strip()
        effect_json = dict(row.get("effect_json") or {})
        if not card_name or not effect_json:
            continue
        normalized = normalize_card_name(card_name)
        allowed_by_name.setdefault(normalized, set()).add(
            str(
                row.get("logical_rule_key")
                or battle_rule_registry.logical_rule_key(
                    {
                        "effect_json": effect_json,
                        "deck_role_json": row.get("deck_role_json"),
                    }
                )
            )
        )

    filtered: list[dict[str, Any]] = []
    for row in rows:
        normalized = normalize_card_name(str(row.get("card_name") or ""))
        if str(row.get("source") or "") != "curated":
            filtered.append(row)
            continue
        allowed_keys = allowed_by_name.get(normalized)
        if not allowed_keys:
            filtered.append(row)
            continue
        logical_key = str(
            row.get("logical_rule_key")
            or battle_rule_registry.logical_rule_key(
                {
                    "effect_json": json_obj(row.get("effect_json")),
                    "deck_role_json": row.get("deck_role_json"),
                }
            )
        )
        if logical_key in allowed_keys:
            filtered.append(row)
    return filtered


def mirror_pg_rules_to_sqlite(
    sqlite_db: str,
    rows: list[dict[str, Any]],
    *,
    reviewed_rows: list[dict[str, Any]] | None = None,
) -> int:
    changed = 0
    filtered_rows = filter_rows_for_current_reviewed_curated(
        rows,
        reviewed_rows or [],
    )
    with closing(sqlite3.connect(sqlite_db)) as conn:
        battle_rule_registry.ensure_battle_card_rules(conn)
        cleanup_obsolete_manual_rows(conn)
        cleanup_stale_reviewed_rows(conn, reviewed_rows or [])
        for row in filtered_rows:
            did_change = upsert_battle_card_rule(
                conn,
                row["card_name"],
                row["effect_json"],
                source=row["source"],
                confidence=row["confidence"],
                review_status=row["review_status"],
                execution_status=str(row.get("execution_status") or "auto"),
                deck_role_json=row["deck_role_json"],
                notes=row["notes"],
                oracle_hash=row["oracle_hash"],
            )
            if did_change:
                changed += 1
        conn.commit()
    return changed


def export_canonical_snapshot(
    rows: list[dict[str, Any]],
    *,
    sqlite_db: str,
    output_path: str | Path,
) -> int:
    normalized_rows = _oracle_normalized_rows(sqlite_db, rows)
    payload = build_snapshot_payload(normalized_rows)
    write_snapshot_payload(output_path, payload)
    return len(payload)


def main() -> int:
    args = parse_args()
    seed_rows = build_rows(
        include_generated=not args.skip_generated,
        sqlite_db=args.sqlite_db,
        reviewed_rules_path=args.reviewed_rules_json,
    )
    selected_card_names = resolve_selected_card_names(args)
    seed_rows = filter_rows_by_card_names(seed_rows, selected_card_names)
    report: dict[str, Any] = {
        "generated_at": utc_now(),
        "database_target": safe_database_target(),
        "sqlite_db": args.sqlite_db,
        "apply_pg": bool(args.apply_pg),
        "apply_sqlite_from_pg": bool(args.apply_sqlite_from_pg),
        "include_generated": not args.skip_generated,
        "reviewed_rules_json": args.reviewed_rules_json,
        "include_needs_review": bool(args.include_needs_review),
        "export_canonical_fallback_json": args.export_canonical_fallback_json,
        "selected_card_count": len(selected_card_names),
        "selected_cards": selected_card_names,
        "only_summary_json": args.only_summary_json,
        "only_classification": args.only_classification,
        "only_recommended_action": args.only_recommended_action,
        "input_rows": len(seed_rows),
        "manual_rows": sum(1 for row in seed_rows if row["source"] == "manual"),
        "curated_rows": sum(1 for row in seed_rows if row["source"] == "curated"),
        "generated_rows": sum(1 for row in seed_rows if row["source"] == "generated"),
        "oracle_normalized_rows": sum(
            1 for row in seed_rows if row.get("_oracle_normalized")
        ),
        "pg_inserted_or_updated": 0,
        "pg_skipped_lower_priority": 0,
        "pg_rows_loaded": 0,
        "sqlite_inserted_or_updated": 0,
        "canonical_snapshot_rows_exported": 0,
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
        rows = filter_rows_by_card_names(rows, selected_card_names)
        report["pg_rows_loaded"] = len(rows)
        report["sqlite_inserted_or_updated"] = mirror_pg_rules_to_sqlite(
            args.sqlite_db,
            rows,
            reviewed_rows=seed_rows,
        )
        report["canonical_snapshot_rows_exported"] = export_canonical_snapshot(
            rows,
            sqlite_db=args.sqlite_db,
            output_path=args.export_canonical_fallback_json,
        )

    output = json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True)
    print(output)
    if args.report:
        report_path = Path(args.report)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(output + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
