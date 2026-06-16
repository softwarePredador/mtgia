#!/usr/bin/env python3
"""Audit handwritten battle overrides against canonical rule stores.

This is a report-only tool. It does not mutate PostgreSQL or SQLite.

Goals:

1. inventory every entry in HANDCRAFTED_KNOWN_CARDS;
2. classify each entry as engine primitive, promotable card rule, or
   temporary hotfix;
3. compare the handwritten rule with PostgreSQL card_battle_rules and the
   SQLite battle_card_rules cache;
4. highlight which overrides still need canonization into PostgreSQL.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
from collections import Counter
from pathlib import Path
from typing import Any

import battle_rule_registry
from battle_rule_registry import DEFAULT_DB, deck_role_from_effect, logical_rule_key, normalize_card_name, stable_json

try:
    from db_helper import connect
except Exception as exc:  # pragma: no cover - environment specific
    connect = None
    _DB_HELPER_IMPORT_ERROR = exc


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
SERVER_ENV_PATH = REPO_ROOT / "server" / ".env"
BATTLE_PATH = Path(os.environ.get("MANALOOM_BATTLE_SCRIPT", SCRIPT_DIR / "battle_analyst_v9.py"))

# These are currently accepted as containment patches, not as the long-term
# canonical storage model.
TEMPORARY_HOTFIX_NAMES = {
    "Ancient Den",
    "Ancient Tomb",
    "Birgi, God of Storytelling",
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
    "Chrome Mox",
    "Electroduplicate",
    "Everflowing Chalice",
    "Gemstone Caverns",
    "Great Furnace",
    "Hall of Heliod's Generosity",
    "Inventors' Fair",
    "Lightning Greaves",
    "Sunbaked Canyon",
    "Urza's Saga",
    "Valakut Awakening",
    "Valakut Awakening // Valakut Stoneforge",
    "War Room",
}

# Reserved for true engine scaffolding if needed later. Most entries should
# migrate to PostgreSQL.
ENGINE_PRIMITIVE_ALLOWLIST: set[str] = set()


def load_battle_module(path: Path):
    spec = importlib.util.spec_from_file_location("audit_handcrafted_battle", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = load_battle_module(BATTLE_PATH)


def load_server_dotenv_fallback() -> None:
    if os.environ.get("DATABASE_URL") or not SERVER_ENV_PATH.is_file():
        return
    for raw_line in SERVER_ENV_PATH.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Inventory handwritten battle overrides and compare them with PG/SQLite canonical rule stores.",
    )
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument("--report-json")
    parser.add_argument("--report-md")
    parser.add_argument(
        "--full-stdout",
        action="store_true",
        help="Print the full JSON payload to stdout instead of a compact summary.",
    )
    return parser.parse_args()


def manual_rule_payload(card_name: str, effect_json: dict[str, Any]) -> dict[str, Any]:
    return {
        "normalized_name": normalize_card_name(card_name),
        "card_name": card_name,
        "effect_json": effect_json,
        "deck_role_json": deck_role_from_effect(effect_json),
    }


def effective_rule_key(card_name: str, effect_json: dict[str, Any]) -> str:
    return logical_rule_key(manual_rule_payload(card_name, effect_json))


def json_dict(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def load_sqlite_rules(sqlite_db: str | Path) -> dict[str, dict[str, Any]]:
    return battle_rule_registry.load_active_battle_card_rules(sqlite_db)


def load_pg_rows(card_names: list[str]) -> tuple[dict[str, dict[str, Any]], dict[str, str], str | None]:
    load_server_dotenv_fallback()
    if connect is None:
        return {}, {}, f"db_helper_unavailable: {_DB_HELPER_IMPORT_ERROR}"
    conn = None
    try:
        conn = connect()
        cur = conn.cursor()
        normalized_names = [normalize_card_name(name) for name in card_names]
        cur.execute(
            """
            SELECT
              cbr.normalized_name,
              cbr.card_name,
              cbr.card_id::text,
              cbr.effect_json::text,
              cbr.deck_role_json::text,
              cbr.source,
              cbr.confidence::float8,
              cbr.review_status,
              cbr.rule_version,
              cbr.oracle_hash,
              cbr.notes
            FROM card_battle_rules cbr
            WHERE cbr.normalized_name = ANY(%s)
            """,
            (normalized_names,),
        )
        rows: dict[str, dict[str, Any]] = {}
        for row in cur.fetchall():
            normalized_name = str(row[0])
            rows[normalized_name] = {
                "normalized_name": normalized_name,
                "card_name": str(row[1]),
                "card_id": row[2],
                "effect_json": json.loads(row[3]) if row[3] else {},
                "deck_role_json": json.loads(row[4]) if row[4] else {},
                "source": str(row[5]),
                "confidence": float(row[6] or 0.0),
                "review_status": str(row[7]),
                "rule_version": int(row[8] or 1),
                "oracle_hash": row[9],
                "notes": row[10],
            }
            rows[normalized_name]["logical_rule_key"] = logical_rule_key(rows[normalized_name])

        cur.execute(
            """
            SELECT id::text, name
            FROM cards
            WHERE lower(name) = ANY(%s)
               OR lower(split_part(name, ' // ', 1)) = ANY(%s)
            """,
            (
                normalized_names,
                [normalize_card_name(name.split(" // ", 1)[0]) for name in card_names],
            ),
        )
        card_lookup: dict[str, str] = {}
        for card_id, card_name in cur.fetchall():
            normalized = normalize_card_name(card_name)
            card_lookup.setdefault(normalized, card_id)
            card_lookup.setdefault(normalize_card_name(str(card_name).split(" // ", 1)[0]), card_id)

        cur.close()
        conn.close()
        return rows, card_lookup, None
    except Exception as exc:  # pragma: no cover - depends on env/db availability
        if conn is not None:
            try:
                conn.close()
            except Exception:
                pass
        return {}, {}, str(exc)


def compare_manual_to_store(
    card_name: str,
    manual_effect: dict[str, Any],
    store_rule: dict[str, Any] | None,
) -> str:
    if not store_rule:
        return "missing"
    manual_key = effective_rule_key(card_name, manual_effect)
    store_key = str(store_rule.get("logical_rule_key") or "")
    if manual_key == store_key:
        return "exact_match"
    if stable_json(json_dict(store_rule.get("effect_json"))) == stable_json(manual_effect):
        return "effect_match_role_drift"
    return "drift"


def classify_override(
    card_name: str,
    manual_effect: dict[str, Any],
    pg_state: str,
    pg_row: dict[str, Any] | None,
) -> str:
    if card_name in ENGINE_PRIMITIVE_ALLOWLIST:
        return "engine_primitive"
    if card_name in TEMPORARY_HOTFIX_NAMES and pg_state != "exact_match":
        return "temporary_hotfix"
    if pg_row and str(pg_row.get("review_status") or "") not in {"verified", "active"}:
        return "temporary_hotfix"
    return "card_rule_promotable"


def recommended_action(
    classification: str,
    pg_state: str,
    sqlite_state: str,
    pg_row: dict[str, Any] | None,
    card_exists_in_pg_catalog: bool,
) -> str:
    if classification == "engine_primitive":
        return "keep_in_code_only"
    if not card_exists_in_pg_catalog:
        return "resolve_pg_card_identity_first"
    if pg_state == "missing":
        return "create_pg_rule"
    if pg_state in {"drift", "effect_match_role_drift"}:
        return "reconcile_pg_rule"
    if pg_row and str(pg_row.get("review_status") or "") not in {"verified", "active"}:
        return "review_pg_rule"
    if sqlite_state != "exact_match":
        return "refresh_sqlite_from_pg"
    if classification == "temporary_hotfix":
        return "promote_hotfix_and_remove_manual_override"
    return "already_canonicalized"


def build_entries(sqlite_db: str | Path) -> dict[str, Any]:
    card_names = sorted(battle.HANDCRAFTED_KNOWN_CARDS)
    sqlite_rules = load_sqlite_rules(sqlite_db)
    pg_rows, pg_card_lookup, pg_error = load_pg_rows(card_names)

    entries: list[dict[str, Any]] = []
    for card_name in card_names:
        manual_effect = dict(battle.KNOWN_CARDS[card_name])
        normalized_name = normalize_card_name(card_name)
        pg_row = pg_rows.get(normalized_name)
        sqlite_row = sqlite_rules.get(normalized_name)
        pg_state = compare_manual_to_store(card_name, manual_effect, pg_row)
        sqlite_state = compare_manual_to_store(card_name, manual_effect, sqlite_row)
        card_exists_in_pg_catalog = (
            normalize_card_name(card_name) in pg_card_lookup
            or normalize_card_name(card_name.split(" // ", 1)[0]) in pg_card_lookup
        )
        classification = classify_override(card_name, manual_effect, pg_state, pg_row)
        entry = {
            "card_name": card_name,
            "normalized_name": normalized_name,
            "classification": classification,
            "manual_effect": manual_effect,
            "manual_effect_name": str(manual_effect.get("effect") or "unknown"),
            "manual_logical_rule_key": effective_rule_key(card_name, manual_effect),
            "pg_state": pg_state,
            "sqlite_state": sqlite_state,
            "pg_review_status": str(pg_row.get("review_status") or "") if pg_row else "",
            "pg_source": str(pg_row.get("source") or "") if pg_row else "",
            "sqlite_review_status": str(sqlite_row.get("review_status") or "") if sqlite_row else "",
            "sqlite_source": str(sqlite_row.get("source") or "") if sqlite_row else "",
            "card_exists_in_pg_catalog": card_exists_in_pg_catalog,
            "recommended_action": recommended_action(
                classification,
                pg_state,
                sqlite_state,
                pg_row,
                card_exists_in_pg_catalog,
            ),
        }
        entries.append(entry)

    counts = {
        "classification": dict(Counter(entry["classification"] for entry in entries)),
        "pg_state": dict(Counter(entry["pg_state"] for entry in entries)),
        "sqlite_state": dict(Counter(entry["sqlite_state"] for entry in entries)),
        "recommended_action": dict(Counter(entry["recommended_action"] for entry in entries)),
    }
    return {
        "generated_at": battle_rule_registry.utc_now(),
        "battle_script": str(BATTLE_PATH),
        "sqlite_db": str(sqlite_db),
        "sqlite_rule_count": len(sqlite_rules),
        "pg_target": None if pg_error else "configured",
        "pg_error": pg_error,
        "handcrafted_count": len(entries),
        "counts": counts,
        "entries": entries,
    }


def render_markdown(summary: dict[str, Any]) -> str:
    counts = summary["counts"]
    lines = [
        "# Handcrafted Battle Rule Canonicalization Audit",
        "",
        "## Summary",
        "",
        f"- Handcrafted overrides: `{summary['handcrafted_count']}`",
        f"- SQLite cached rules seen: `{summary['sqlite_rule_count']}`",
        f"- PG target: `{summary['pg_target'] or 'unavailable'}`",
    ]
    if summary.get("pg_error"):
        lines.append(f"- PG access: `error` (`{summary['pg_error']}`)")
    lines.extend(
        [
            "",
            "## Counts",
            "",
            f"- Classification: `{json.dumps(counts['classification'], ensure_ascii=True, sort_keys=True)}`",
            f"- PG state: `{json.dumps(counts['pg_state'], ensure_ascii=True, sort_keys=True)}`",
            f"- SQLite state: `{json.dumps(counts['sqlite_state'], ensure_ascii=True, sort_keys=True)}`",
            f"- Recommended action: `{json.dumps(counts['recommended_action'], ensure_ascii=True, sort_keys=True)}`",
            "",
            "## Action Queue",
            "",
            "| Card | Class | PG | SQLite | Action |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    action_priority = {
        "create_pg_rule": 0,
        "reconcile_pg_rule": 1,
        "review_pg_rule": 2,
        "refresh_sqlite_from_pg": 3,
        "promote_hotfix_and_remove_manual_override": 4,
        "resolve_pg_card_identity_first": 5,
        "already_canonicalized": 6,
        "keep_in_code_only": 7,
    }
    for entry in sorted(
        summary["entries"],
        key=lambda item: (
            action_priority.get(item["recommended_action"], 99),
            item["classification"],
            item["card_name"],
        ),
    ):
        lines.append(
            f"| {entry['card_name']} | {entry['classification']} | {entry['pg_state']} | {entry['sqlite_state']} | {entry['recommended_action']} |"
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    summary = build_entries(args.sqlite_db)
    output = json.dumps(summary, ensure_ascii=True, indent=2, sort_keys=True)
    if args.full_stdout:
        print(output)
    else:
        preview = {
            "generated_at": summary["generated_at"],
            "handcrafted_count": summary["handcrafted_count"],
            "counts": summary["counts"],
            "pg_target": summary["pg_target"],
            "pg_error": summary["pg_error"],
            "report_json": args.report_json,
            "report_md": args.report_md,
        }
        print(json.dumps(preview, ensure_ascii=True, sort_keys=True))
    if args.report_json:
        Path(args.report_json).write_text(output + "\n", encoding="utf-8")
    if args.report_md:
        Path(args.report_md).write_text(render_markdown(summary), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
