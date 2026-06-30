#!/usr/bin/env python3
"""Validate the PostgreSQL -> Hermes -> SQLite data contract.

The goal is not to make SQLite mirror every PostgreSQL table. PostgreSQL is the
source of truth; Hermes SQLite is a local cache for battle/deckbuilding jobs.
This audit checks that each active SQLite cache table has the columns its sync
path reads/writes, that JSON fields are parseable, and that cache rows can be
traced back to the PostgreSQL relations that own the data.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import battle_rule_registry
from db_helper import connect, sanitized_database_target
from master_optimizer_common import resolve_default_knowledge_db
from reviewed_battle_card_rules import load_reviewed_rule_rows


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_SQLITE_DB = resolve_default_knowledge_db()
STALE_SIBLING_DB = SCRIPT_DIR.parent / "knowledge.db"

SQLITE_REQUIRED_COLUMNS: dict[str, set[str]] = {
    "battle_card_rules": {
        "normalized_name",
        "logical_rule_key",
        "card_name",
        "effect_json",
        "deck_role_json",
        "source",
        "confidence",
        "review_status",
        "execution_status",
        "rule_version",
        "oracle_hash",
        "notes",
        "created_at",
        "updated_at",
        "last_seen_at",
    },
    "card_oracle_cache": {
        "normalized_name",
        "card_id",
        "name",
        "mana_cost",
        "colors_json",
        "color_identity_json",
        "type_line",
        "oracle_text",
        "cmc",
        "power",
        "toughness",
        "keywords_json",
        "scryfall_id",
        "source",
        "updated_at",
    },
    "deck_cards": {
        "id",
        "deck_id",
        "card_id",
        "card_name",
        "quantity",
        "functional_tag",
        "functional_tags_json",
        "semantic_tags_v2_json",
        "battle_rules_json",
        "deck_hash",
        "semantics_hash",
        "ruleset_hash",
        "sync_run_id",
        "tag_confidence",
        "is_commander",
        "is_partner",
        "cmc",
        "type_line",
        "oracle_text",
    },
    "learned_decks": {
        "id",
        "source",
        "source_url",
        "commander",
        "deck_name",
        "archetype",
        "card_list",
        "card_count",
        "wincon_primary",
        "wincon_backup",
        "budget_level",
        "notes",
        "created_at",
    },
    "card_legalities": {
        "card_name",
        "format",
        "status",
        "scryfall_id",
        "synced_at",
    },
    "format_staples": {
        "card_name",
        "format",
        "archetype",
        "category",
        "color_identity",
        "edhrec_rank",
        "scryfall_id",
        "is_banned",
        "synced_at",
    },
}

SQLITE_NONEMPTY_TABLES = {
    "battle_card_rules",
    "card_oracle_cache",
    "deck_cards",
    "learned_decks",
    "card_legalities",
    "format_staples",
}

SQLITE_JSON_COLUMNS: dict[tuple[str, str], str] = {
    ("battle_card_rules", "effect_json"): "object",
    ("battle_card_rules", "deck_role_json"): "object",
    ("card_oracle_cache", "colors_json"): "array",
    ("card_oracle_cache", "color_identity_json"): "array",
    ("card_oracle_cache", "keywords_json"): "array",
    ("deck_cards", "functional_tags_json"): "array",
    ("deck_cards", "semantic_tags_v2_json"): "array",
    ("deck_cards", "battle_rules_json"): "array",
    ("learned_decks", "card_list"): "array",
}

PG_REQUIRED_COLUMNS: dict[str, set[str]] = {
    "cards": {
        "id",
        "scryfall_id",
        "name",
        "mana_cost",
        "type_line",
        "oracle_text",
        "colors",
        "color_identity",
        "cmc",
        "power",
        "toughness",
        "keywords",
        "oracle_id",
        "layout",
        "card_faces_json",
    },
    "card_intelligence_snapshot": {
        "id",
        "card_id",
        "name",
        "card_name",
        "normalized_card_name",
        "cmc",
        "type_line",
        "oracle_text",
        "function_tags",
        "semantic_tags_v2",
        "battle_rules",
        "verified_battle_rules",
        "source_coverage",
    },
    "card_battle_rules": {
        "normalized_name",
        "logical_rule_key",
        "card_id",
        "card_name",
        "effect_json",
        "deck_role_json",
        "source",
        "confidence",
        "review_status",
        "execution_status",
        "rule_version",
        "oracle_hash",
        "updated_at",
    },
    "deck_cards": {"id", "deck_id", "card_id", "quantity", "is_commander"},
    "card_legalities": {"card_id", "format", "status"},
    "format_staples": {
        "card_name",
        "format",
        "archetype",
        "category",
        "color_identity",
        "edhrec_rank",
        "scryfall_id",
        "is_banned",
    },
    "meta_decks": {
        "id",
        "commander_name",
        "shell_label",
        "strategy_archetype",
        "source_url",
        "card_list",
        "created_at",
    },
    "commander_learning_snapshot": {
        "commander_name_normalized",
        "commander_name",
        "active_learned_deck_count",
        "active_learned_decks",
        "top_usage_cards",
        "source_coverage",
    },
}


@dataclass
class Check:
    name: str
    status: str
    detail: str
    data: dict[str, Any] | None = None

    def as_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "name": self.name,
            "status": self.status,
            "detail": self.detail,
        }
        if self.data is not None:
            payload["data"] = self.data
        return payload


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def table_exists(conn: sqlite3.Connection, table: str) -> bool:
    return (
        conn.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
            (table,),
        ).fetchone()
        is not None
    )


def sqlite_columns(conn: sqlite3.Connection, table: str) -> set[str]:
    if not table_exists(conn, table):
        return set()
    return {str(row[1]) for row in conn.execute(f"PRAGMA table_info({table})")}


def sqlite_count(conn: sqlite3.Connection, table: str, where: str = "") -> int:
    sql = f"SELECT COUNT(*) FROM {table}"
    if where:
        sql += f" WHERE {where}"
    return int(conn.execute(sql).fetchone()[0] or 0)


def safe_json(value: str | None) -> Any:
    if value is None or value == "":
        return None
    return json.loads(value)


def json_kind_ok(value: Any, expected: str) -> bool:
    if value is None:
        return True
    if expected == "object":
        return isinstance(value, dict)
    if expected == "array":
        return isinstance(value, list)
    return True


def validate_json_column(
    conn: sqlite3.Connection,
    table: str,
    column: str,
    expected_kind: str,
) -> Check:
    if column not in sqlite_columns(conn, table):
        return Check(
            f"sqlite_json.{table}.{column}",
            "fail",
            "missing_column",
        )
    bad_rows: list[dict[str, Any]] = []
    scanned = 0
    for rowid, raw in conn.execute(
        f"SELECT rowid, {column} FROM {table} WHERE {column} IS NOT NULL AND {column} != ''"
    ):
        scanned += 1
        try:
            decoded = safe_json(raw)
        except Exception as exc:
            bad_rows.append({"rowid": rowid, "error": str(exc)[:120]})
            continue
        if not json_kind_ok(decoded, expected_kind):
            bad_rows.append({"rowid": rowid, "actual_type": type(decoded).__name__})
    if bad_rows:
        return Check(
            f"sqlite_json.{table}.{column}",
            "fail",
            f"invalid_json_rows={len(bad_rows)}",
            {"sample": bad_rows[:10], "scanned": scanned},
        )
    return Check(
        f"sqlite_json.{table}.{column}",
        "pass",
        f"scanned={scanned}",
    )


def sqlite_schema_checks(conn: sqlite3.Connection) -> list[Check]:
    checks: list[Check] = []
    for table, required in sorted(SQLITE_REQUIRED_COLUMNS.items()):
        if not table_exists(conn, table):
            checks.append(Check(f"sqlite_schema.{table}", "fail", "missing_table"))
            continue
        columns = sqlite_columns(conn, table)
        missing = sorted(required - columns)
        extra = sorted(columns - required)
        status = "fail" if missing else "pass"
        checks.append(
            Check(
                f"sqlite_schema.{table}",
                status,
                "ok" if not missing else "missing_columns=" + ",".join(missing),
                {"columns": sorted(columns), "extra_columns": extra},
            )
        )
        if table in SQLITE_NONEMPTY_TABLES:
            row_count = sqlite_count(conn, table)
            checks.append(
                Check(
                    f"sqlite_rows.{table}",
                    "pass" if row_count > 0 else "fail",
                    f"rows={row_count}",
                )
            )
    for (table, column), expected_kind in sorted(SQLITE_JSON_COLUMNS.items()):
        if table_exists(conn, table):
            checks.append(validate_json_column(conn, table, column, expected_kind))
    return checks


def sqlite_cache_integrity_checks(conn: sqlite3.Connection) -> list[Check]:
    checks: list[Check] = []
    if table_exists(conn, "card_oracle_cache"):
        columns = sqlite_columns(conn, "card_oracle_cache")
        if {"card_id", "source"}.issubset(columns):
            missing_card_id = sqlite_count(
                conn,
                "card_oracle_cache",
                "COALESCE(card_id, '') = '' AND source = 'postgres_cards'",
            )
            checks.append(
                Check(
                    "sqlite_integrity.card_oracle_cache_card_id",
                    "pass" if missing_card_id == 0 else "fail",
                    f"postgres_cache_rows_missing_card_id={missing_card_id}",
                )
            )

    if table_exists(conn, "deck_cards"):
        columns = sqlite_columns(conn, "deck_cards")
        if {"card_id", "deck_id"}.issubset(columns):
            total_missing = sqlite_count(conn, "deck_cards", "COALESCE(card_id, '') = ''")
            target_missing = sqlite_count(
                conn,
                "deck_cards",
                "deck_id = 6 AND COALESCE(card_id, '') = ''",
            )
            checks.append(
                Check(
                    "sqlite_integrity.deck_cards_target_card_id",
                    "pass" if target_missing == 0 else "fail",
                    f"deck_id_6_missing_card_id={target_missing}",
                )
            )
            checks.append(
                Check(
                    "sqlite_integrity.deck_cards_global_card_id",
                    "pass" if total_missing == 0 else "warn",
                    f"all_deck_cards_missing_card_id={total_missing}",
                )
            )
        if (
            table_exists(conn, "card_oracle_cache")
            and {"card_id", "card_name"}.issubset(columns)
            and {"normalized_name", "card_id", "name"}.issubset(sqlite_columns(conn, "card_oracle_cache"))
        ):
            drift_rows = conn.execute(
                """
                SELECT
                  dc.deck_id,
                  dc.card_name AS deck_card_name,
                  COALESCE(dc.card_id, '') AS deck_card_id,
                  coc.name AS oracle_cache_name,
                  coc.card_id AS oracle_cache_card_id
                FROM deck_cards dc
                JOIN card_oracle_cache coc
                  ON coc.normalized_name = lower(trim(dc.card_name))
                WHERE COALESCE(coc.card_id, '') != ''
                  AND (
                    dc.card_id IS NULL
                    OR dc.card_id = ''
                    OR lower(dc.card_id) != lower(coc.card_id)
                  )
                ORDER BY dc.deck_id, dc.card_name
                LIMIT 20
                """
            ).fetchall()
            drift_count = int(
                conn.execute(
                    """
                    SELECT COUNT(*)
                    FROM deck_cards dc
                    JOIN card_oracle_cache coc
                      ON coc.normalized_name = lower(trim(dc.card_name))
                    WHERE COALESCE(coc.card_id, '') != ''
                      AND (
                        dc.card_id IS NULL
                        OR dc.card_id = ''
                        OR lower(dc.card_id) != lower(coc.card_id)
                      )
                    """
                ).fetchone()[0]
                or 0
            )
            checks.append(
                Check(
                    "sqlite_integrity.deck_cards_card_id_cache_drift",
                    "pass" if drift_count == 0 else "fail",
                    f"deck_cards_rows_with_card_id_drift={drift_count}",
                    {
                        "canonical_field": "deck_cards.card_id",
                        "source_field": "card_oracle_cache.card_id",
                        "sample": [dict(row) for row in drift_rows],
                    },
                )
            )
            alias_rows = conn.execute(
                """
                SELECT
                  dc.deck_id,
                  dc.card_name AS deck_card_name,
                  dc.card_id AS card_id,
                  coc.name AS oracle_cache_name
                FROM deck_cards dc
                JOIN card_oracle_cache coc
                  ON coc.normalized_name = lower(trim(dc.card_name))
                WHERE dc.card_name != coc.name
                  AND COALESCE(dc.card_id, '') != ''
                  AND lower(dc.card_id) = lower(COALESCE(coc.card_id, ''))
                ORDER BY dc.deck_id, dc.card_name
                LIMIT 20
                """
            ).fetchall()
            alias_count = int(
                conn.execute(
                    """
                    SELECT COUNT(*)
                    FROM deck_cards dc
                    JOIN card_oracle_cache coc
                      ON coc.normalized_name = lower(trim(dc.card_name))
                    WHERE dc.card_name != coc.name
                      AND COALESCE(dc.card_id, '') != ''
                      AND lower(dc.card_id) = lower(COALESCE(coc.card_id, ''))
                    """
                ).fetchone()[0]
                or 0
            )
            checks.append(
                Check(
                    "sqlite_integrity.deck_cards_name_aliases_canonicalized_by_card_id",
                    "pass",
                    f"name_alias_rows_with_matching_card_id={alias_count}",
                    {
                        "canonical_field": "deck_cards.card_id",
                        "alias_fields": ["deck_cards.card_name", "card_oracle_cache.name"],
                        "sample": [dict(row) for row in alias_rows],
                    },
                )
            )

    if table_exists(conn, "battle_card_rules"):
        columns = sqlite_columns(conn, "battle_card_rules")
        if {"oracle_hash", "source", "review_status", "execution_status"}.issubset(columns):
            missing_hash = sqlite_count(
                conn,
                "battle_card_rules",
                """
                source IN ('curated', 'manual')
                AND review_status IN ('verified', 'active')
                AND execution_status IN ('auto', 'executable')
                AND COALESCE(oracle_hash, '') = ''
                """,
            )
            checks.append(
                Check(
                    "sqlite_integrity.battle_rules_trusted_oracle_hash_coverage",
                    "pass" if missing_hash == 0 else "warn",
                    f"trusted_executable_rules_missing_oracle_hash={missing_hash}",
                )
            )

    if table_exists(conn, "card_legalities"):
        for card_name, expected in (("Worldfire", "legal"), ("Mana Crypt", "banned")):
            row = conn.execute(
                """
                SELECT status
                FROM card_legalities
                WHERE lower(card_name)=lower(?) AND format='commander'
                LIMIT 1
                """,
                (card_name,),
            ).fetchone()
            actual = str(row[0]).lower() if row else "missing"
            checks.append(
                Check(
                    f"sqlite_integrity.commander_legality.{slug(card_name)}",
                    "pass" if actual == expected else "fail",
                    f"actual={actual} expected={expected}",
                )
            )
    return checks


def slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def pg_columns_and_counts() -> tuple[dict[str, set[str]], dict[str, int], str]:
    columns: dict[str, set[str]] = {}
    counts: dict[str, int] = {}
    with connect() as conn:
        with conn.cursor() as cur:
            for relation in sorted(PG_REQUIRED_COLUMNS):
                cur.execute("SELECT to_regclass(%s)", (f"public.{relation}",))
                if cur.fetchone()[0] is None:
                    columns[relation] = set()
                    counts[relation] = -1
                    continue
                cur.execute(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_schema='public' AND table_name=%s
                    ORDER BY ordinal_position
                    """,
                    (relation,),
                )
                columns[relation] = {str(row[0]) for row in cur.fetchall()}
                cur.execute(f'SELECT COUNT(*) FROM "{relation}"')
                counts[relation] = int(cur.fetchone()[0] or 0)
    return columns, counts, sanitized_database_target()


def pg_schema_checks(columns: dict[str, set[str]], counts: dict[str, int]) -> list[Check]:
    checks: list[Check] = []
    for relation, required in sorted(PG_REQUIRED_COLUMNS.items()):
        actual = columns.get(relation, set())
        if not actual:
            checks.append(Check(f"pg_schema.{relation}", "fail", "missing_relation"))
            continue
        missing = sorted(required - actual)
        checks.append(
            Check(
                f"pg_schema.{relation}",
                "fail" if missing else "pass",
                "ok" if not missing else "missing_columns=" + ",".join(missing),
                {"columns": sorted(actual), "rows": counts.get(relation, -1)},
            )
        )
        row_count = counts.get(relation, -1)
        checks.append(
            Check(
                f"pg_rows.{relation}",
                "pass" if row_count > 0 else "fail",
                f"rows={row_count}",
            )
        )
    return checks


def reviewed_runtime_keys() -> set[tuple[str, str]]:
    keys: set[tuple[str, str]] = set()
    for row in load_reviewed_rule_rows():
        card_name = str(row.get("card_name") or "").strip()
        if not card_name:
            continue
        logical_key = str(row.get("logical_rule_key") or "")
        if not logical_key:
            logical_key = battle_rule_registry.logical_rule_key(
                {
                    "effect_json": row.get("effect_json") or {},
                    "deck_role_json": row.get("deck_role_json") or {},
                }
            )
        keys.add((battle_rule_registry.normalize_card_name(card_name), logical_key))
    return keys


def pg_runtime_keys() -> set[tuple[str, str]]:
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT normalized_name, logical_rule_key
                FROM card_battle_rules
                WHERE review_status IN ('verified', 'active', 'needs_review', 'deprecated')
                  AND execution_status != 'disabled'
                """
            )
            return {(str(row[0]), str(row[1])) for row in cur.fetchall()}


def pg_sqlite_parity_checks(conn: sqlite3.Connection, *, skip_pg: bool) -> list[Check]:
    checks: list[Check] = []
    if skip_pg:
        checks.append(Check("pg_sqlite_parity", "warn", "skipped_pg"))
        return checks

    if table_exists(conn, "battle_card_rules"):
        pg_keys = pg_runtime_keys()
        reviewed_keys = reviewed_runtime_keys()
        sqlite_rows = conn.execute(
            """
            SELECT normalized_name, logical_rule_key, source
            FROM battle_card_rules
            WHERE review_status IN ('verified', 'active', 'needs_review', 'deprecated')
              AND execution_status != 'disabled'
            """
        ).fetchall()
        sqlite_keys = {(str(row[0]), str(row[1])) for row in sqlite_rows}
        unresolved = sorted(sqlite_keys - pg_keys - reviewed_keys)
        checks.append(
            Check(
                "pg_sqlite_parity.battle_card_rules_runtime_keys",
                "pass" if not unresolved else "fail",
                f"sqlite_runtime_keys={len(sqlite_keys)} pg_runtime_keys={len(pg_keys)} unresolved={len(unresolved)}",
                {"unresolved_sample": unresolved[:20]},
            )
        )

    if table_exists(conn, "decks") and table_exists(conn, "deck_cards"):
        deck = conn.execute(
            "SELECT id, deck_name, notes FROM decks WHERE id=6 LIMIT 1"
        ).fetchone()
        if deck:
            match = re.search(r"pg_deck_id=([0-9a-fA-F-]{36})", str(deck[2] or ""))
            if match:
                pg_deck_id = match.group(1)
                sqlite_qty = sqlite_count(conn, "deck_cards", "deck_id=6")
                sqlite_total_qty = int(
                    conn.execute(
                        "SELECT COALESCE(SUM(quantity), 0) FROM deck_cards WHERE deck_id=6"
                    ).fetchone()[0]
                    or 0
                )
                with connect() as pg_conn:
                    with pg_conn.cursor() as cur:
                        cur.execute(
                            """
                            SELECT COUNT(*), COALESCE(SUM(quantity), 0)
                            FROM deck_cards
                            WHERE deck_id=%s
                            """,
                            (pg_deck_id,),
                        )
                        pg_rows, pg_qty = cur.fetchone()
                status = "pass" if int(pg_rows) == sqlite_qty and int(pg_qty) == sqlite_total_qty else "fail"
                checks.append(
                    Check(
                        "pg_sqlite_parity.deck_id_6_pg_snapshot",
                        status,
                        f"pg_deck_id={pg_deck_id} sqlite_rows={sqlite_qty} pg_rows={int(pg_rows)} sqlite_qty={sqlite_total_qty} pg_qty={int(pg_qty)}",
                    )
                )
            else:
                checks.append(
                    Check(
                        "pg_sqlite_parity.deck_id_6_pg_snapshot",
                        "warn",
                        "deck_id_6_has_no_pg_deck_id_note",
                    )
                )
    return checks


def build_report(sqlite_db: Path, *, skip_pg: bool = False) -> dict[str, Any]:
    checks: list[Check] = []
    sqlite_db = sqlite_db.resolve()
    if not sqlite_db.exists() or sqlite_db.stat().st_size == 0:
        checks.append(
            Check(
                "sqlite_db.active",
                "fail",
                f"missing_or_empty:{sqlite_db}",
            )
        )
    else:
        checks.append(Check("sqlite_db.active", "pass", str(sqlite_db)))
        with sqlite3.connect(sqlite_db) as conn:
            conn.row_factory = sqlite3.Row
            checks.extend(sqlite_schema_checks(conn))
            checks.extend(sqlite_cache_integrity_checks(conn))
            checks.extend(pg_sqlite_parity_checks(conn, skip_pg=skip_pg))

    if STALE_SIBLING_DB.exists() and STALE_SIBLING_DB.stat().st_size == 0:
        checks.append(
            Check(
                "sqlite_db.empty_sibling",
                "warn",
                f"empty_legacy_artifact:{STALE_SIBLING_DB}",
            )
        )

    pg_target = "skipped"
    if skip_pg:
        checks.append(Check("pg_connection", "warn", "skipped_pg"))
    else:
        pg_columns, pg_counts, pg_target = pg_columns_and_counts()
        checks.append(Check("pg_connection", "pass", pg_target))
        checks.extend(pg_schema_checks(pg_columns, pg_counts))

    status_counts: dict[str, int] = {}
    for check in checks:
        status_counts[check.status] = status_counts.get(check.status, 0) + 1

    return {
        "generated_at": utc_now(),
        "status": "fail" if status_counts.get("fail", 0) else "pass",
        "postgres_target": pg_target,
        "sqlite_db": str(sqlite_db),
        "summary": {
            "check_count": len(checks),
            "status_counts": status_counts,
        },
        "checks": [check.as_dict() for check in checks],
        "mutations_performed": [],
    }


def write_markdown(report: dict[str, Any], path: Path) -> None:
    lines = [
        "# PG Hermes SQLite Contract Audit",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- PostgreSQL target: `{report['postgres_target']}`",
        f"- SQLite DB: `{report['sqlite_db']}`",
        f"- Summary: `{json.dumps(report['summary'], sort_keys=True)}`",
        "",
        "| Check | Status | Detail |",
        "| --- | --- | --- |",
    ]
    for check in report["checks"]:
        detail = str(check.get("detail") or "").replace("|", "\\|")
        lines.append(f"| `{check['name']}` | `{check['status']}` | {detail} |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sqlite-db", default=str(DEFAULT_SQLITE_DB))
    parser.add_argument("--skip-pg", action="store_true")
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "pg_hermes_sqlite_contract_audit_20260629",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report(Path(args.sqlite_db), skip_pg=args.skip_pg)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(
        json.dumps(report, indent=2, ensure_ascii=True, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    write_markdown(report, md_path)
    print(
        json.dumps(
            {
                "status": report["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "summary": report["summary"],
            },
            sort_keys=True,
        )
    )
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
