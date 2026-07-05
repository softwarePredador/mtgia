#!/usr/bin/env python3
"""Audit global Commander core role coverage.

This is a read-only deckbuilding diagnostic. It checks whether every
structure-ready Commander deck has the basic role floor needed before spending
optimizer or battle-gate time: lands, ramp, draw, interaction, wipes,
protection, recursion, win plans, engines, and same-lane cut readiness.

PostgreSQL remains product truth. When PostgreSQL is skipped or unavailable,
the report is a local Hermes/lab diagnostic and must not be treated as product
readiness.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter, defaultdict
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT
from global_commander_strategy_matrix import collect_deck_matrix_rows
from semantic_role_metrics import normalize_tag, parse_json_list


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
COMMANDER_CONTRACT = REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"

CORE_ROLE_BANDS = {
    "land": {"min": 34, "max": 39, "severity": "critical"},
    "ramp": {"min": 8, "max": 16, "severity": "critical"},
    "draw": {"min": 8, "max": 16, "severity": "critical"},
    "removal": {"min": 6, "max": 14, "severity": "critical"},
    "board_wipe": {"min": 2, "max": 5, "severity": "critical"},
    "protection": {"min": 3, "max": 10, "severity": "support"},
    "recursion": {"min": 1, "max": 8, "severity": "support"},
    "tutor": {"min": 0, "max": 8, "severity": "support"},
    "wincon": {"min": 3, "max": 14, "severity": "critical"},
    "engine": {"min": 4, "max": 24, "severity": "support"},
}

ROLE_ORDER = [
    "land",
    "ramp",
    "draw",
    "removal",
    "board_wipe",
    "protection",
    "recursion",
    "tutor",
    "wincon",
    "engine",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def table_columns(conn: sqlite3.Connection, table: str) -> set[str]:
    return {row[1] for row in conn.execute(f"PRAGMA table_info({table})")}


def role_from_raw_tags(row: Mapping[str, Any]) -> set[str]:
    raw_tags = []
    raw_tags.extend(parse_json_list(row.get("functional_tags_json")))
    if row.get("functional_tag"):
        raw_tags.append(str(row["functional_tag"]))
    roles = {normalize_tag(tag) for tag in raw_tags}
    return {role for role in roles if role in CORE_ROLE_BANDS}


def text_contains(text: str, *patterns: str) -> bool:
    return any(pattern in text for pattern in patterns)


def infer_roles_from_text(row: Mapping[str, Any]) -> set[str]:
    type_line = str(row.get("type_line") or "")
    oracle = str(row.get("oracle_text") or "")
    text = f"{type_line}\n{oracle}".lower()
    roles: set[str] = set()
    is_land = "land" in type_line.lower()

    if is_land:
        roles.add("land")
    if not is_land and text_contains(
        text,
        "add one mana",
        "add two mana",
        "{t}: add",
        "treasure token",
        "create a treasure",
        "costs less to cast",
    ):
        roles.add("ramp")
    if text_contains(
        text,
        "draw a card",
        "draw two cards",
        "draw three cards",
        "draw cards",
        "draw that many",
        "exile the top card",
        "play that card",
        "cast that card",
    ):
        roles.add("draw")
    if text_contains(
        text,
        "destroy target",
        "exile target",
        "counter target spell",
        "return target",
        "deals damage to any target",
        "deals x damage",
    ):
        roles.add("removal")
    if (
        text_contains(text, "destroy all", "exile all", "all creatures", "each creature")
        or re.search(r"deals? \d+ damage to each", text)
    ):
        roles.add("board_wipe")
    if text_contains(
        text,
        "hexproof",
        "indestructible",
        "protection from",
        "prevent all damage",
        "can't be countered",
        "phase out",
        "change the target",
    ):
        roles.add("protection")
    if text_contains(
        text,
        "from your graveyard",
        "from a graveyard",
        "return target card",
        "return target creature card",
        "flashback",
        "escape",
        "retrace",
        "aftermath",
    ):
        roles.add("recursion")
    if not is_land and text_contains(text, "search your library", "search their library"):
        roles.add("tutor")
    if text_contains(
        text,
        "you win the game",
        "loses the game",
        "opponent loses",
        "each opponent loses",
        "extra combat",
        "extra turn",
        "double that damage",
        "twice that much",
    ):
        roles.add("wincon")
    if text_contains(
        text,
        "whenever",
        "at the beginning",
        "you may cast",
        "copy target",
        "copy that spell",
        "magecraft",
        "storm",
    ):
        roles.add("engine")

    return roles


def card_roles(row: Mapping[str, Any]) -> tuple[set[str], str]:
    roles = role_from_raw_tags(row)
    inferred = infer_roles_from_text(row)
    if roles:
        return roles | inferred, "tag_plus_text" if inferred - roles else "tag"
    if inferred:
        return inferred, "text_inferred"
    return {"unknown"}, "unknown"


def load_role_rows(conn: sqlite3.Connection) -> list[dict[str, Any]]:
    columns = table_columns(conn, "deck_cards")
    functional_tags_expr = "functional_tags_json" if "functional_tags_json" in columns else "'[]' AS functional_tags_json"
    oracle_expr = "oracle_text" if "oracle_text" in columns else "'' AS oracle_text"
    type_expr = "type_line" if "type_line" in columns else "'' AS type_line"
    rows = []
    for row in conn.execute(
        f"""
        SELECT deck_id, card_name, COALESCE(quantity, 1) AS quantity,
               functional_tag, {functional_tags_expr}, {type_expr}, {oracle_expr}
        FROM deck_cards
        ORDER BY deck_id, card_name
        """
    ):
        rows.append(dict(row))
    return rows


def role_counts_by_deck(card_rows: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    by_deck: dict[str, dict[str, Any]] = defaultdict(
        lambda: {
            "total_cards": 0,
            "role_counts": Counter(),
            "classification_source_counts": Counter(),
            "unknown_cards": [],
        }
    )
    for row in card_rows:
        deck_id = str(row["deck_id"])
        qty = int(row.get("quantity") or 1)
        roles, source = card_roles(row)
        deck = by_deck[deck_id]
        deck["total_cards"] += qty
        deck["classification_source_counts"][source] += qty
        for role in roles:
            if role == "unknown":
                deck["role_counts"]["unknown"] += qty
                if len(deck["unknown_cards"]) < 20:
                    deck["unknown_cards"].append(row["card_name"])
            else:
                deck["role_counts"][role] += qty
    return by_deck


def band_status(role: str, count: int) -> dict[str, Any]:
    band = CORE_ROLE_BANDS[role]
    if count < int(band["min"]):
        status = "below_floor"
    elif count > int(band["max"]):
        status = "above_range_review"
    else:
        status = "in_range"
    return {
        "role": role,
        "count": count,
        "min": band["min"],
        "max": band["max"],
        "severity": band["severity"],
        "status": status,
    }


def deck_core_status(*, shape_status: str, total_cards: int, role_rows: list[dict[str, Any]], unknown_count: int) -> str:
    critical_gaps = [
        row for row in role_rows if row["status"] == "below_floor" and row["severity"] == "critical"
    ]
    if shape_status != "structure_ready":
        return "structure_blocked"
    if total_cards != 100:
        return "quantity_blocked"
    if unknown_count > 15:
        return "role_data_incomplete"
    if critical_gaps:
        return "core_role_gap"
    if any(row["status"] != "in_range" for row in role_rows):
        return "core_review_ready"
    return "core_ready_for_commander_profile"


def build_report(
    *,
    sqlite_db: Path,
    skip_postgres: bool,
    skip_hermes: bool,
) -> dict[str, Any]:
    deck_rows = collect_deck_matrix_rows(
        sqlite_db=sqlite_db,
        skip_postgres=skip_postgres,
        skip_hermes=skip_hermes,
    )
    matrix_by_deck = {str(row["deck_id"]): row for row in deck_rows}
    with sqlite3.connect(sqlite_db) as conn:
        conn.row_factory = sqlite3.Row
        role_by_deck = role_counts_by_deck(load_role_rows(conn))

    audited_rows: list[dict[str, Any]] = []
    for deck_id, matrix in sorted(
        matrix_by_deck.items(),
        key=lambda item: (0, int(item[0])) if item[0].isdigit() else (1, item[0]),
    ):
        role_data = role_by_deck.get(deck_id, {})
        counts = Counter(role_data.get("role_counts") or {})
        total_cards = int(role_data.get("total_cards") or matrix.get("quantity") or 0)
        role_band_rows = [band_status(role, int(counts.get(role) or 0)) for role in ROLE_ORDER]
        status = deck_core_status(
            shape_status=str(matrix.get("status") or ""),
            total_cards=total_cards,
            role_rows=role_band_rows,
            unknown_count=int(counts.get("unknown") or 0),
        )
        audited_rows.append(
            {
                "deck_id": deck_id,
                "deck_name": matrix.get("deck_name"),
                "commander": matrix.get("commander"),
                "scope": matrix.get("scope"),
                "shape_status": matrix.get("status"),
                "core_status": status,
                "total_cards": total_cards,
                "role_counts": {role: int(counts.get(role) or 0) for role in [*ROLE_ORDER, "unknown"]},
                "role_bands": role_band_rows,
                "classification_source_counts": dict(role_data.get("classification_source_counts") or {}),
                "unknown_card_sample": role_data.get("unknown_cards") or [],
                "next_gate": next_gate(status),
            }
        )

    status_counts = Counter(row["core_status"] for row in audited_rows)
    commander_counts = Counter(row["commander"] for row in audited_rows if row.get("commander"))
    return {
        "generated_at": utc_now(),
        "status": "pass",
        "artifact_type": "global_commander_core_role_audit",
        "contract": rel(COMMANDER_CONTRACT),
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "method": {
            "postgres_is_product_truth": True,
            "hermes_is_lab_cache": True,
            "sqlite_db": str(sqlite_db),
            "skip_postgres": skip_postgres,
            "skip_hermes": skip_hermes,
            "role_bands": CORE_ROLE_BANDS,
            "role_source_policy": "structured_tags_first_then_oracle_text_diagnostic_fallback",
            "lorehold_607_role": "benchmark_regression_only_not_global_template",
        },
        "summary": {
            "deck_count": len(audited_rows),
            "commander_count": len(commander_counts),
            "status_counts": dict(sorted(status_counts.items())),
            "core_ready_count": status_counts.get("core_ready_for_commander_profile", 0),
            "role_data_incomplete_count": status_counts.get("role_data_incomplete", 0),
            "core_role_gap_count": status_counts.get("core_role_gap", 0),
            "structure_blocked_count": status_counts.get("structure_blocked", 0),
            "next_action": "repair_role_data_or_core_gaps_before_strategy_matrix",
        },
        "decks": audited_rows,
    }


def next_gate(status: str) -> str:
    if status == "core_ready_for_commander_profile":
        return "commander_profile_and_source_lanes_before_strategy_matrix"
    if status == "core_review_ready":
        return "review_role_extremes_before_strategy_matrix"
    if status == "core_role_gap":
        return "repair_core_role_floor_before_strategy_matrix"
    if status == "role_data_incomplete":
        return "backfill_functional_roles_or_verify_oracle_text_inference"
    if status == "quantity_blocked":
        return "repair_deck_quantity_before_core_quality"
    return "repair_structure_before_core_quality"


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Global Commander Core Role Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Decks audited: `{payload['summary']['deck_count']}`",
        f"- Commanders audited: `{payload['summary']['commander_count']}`",
        f"- PostgreSQL skipped: `{payload['method']['skip_postgres']}`",
        f"- Battle or optimization performed: `{payload['battle_or_optimization_performed']}`",
        "",
        "## Status Counts",
        "",
        "| Status | Decks |",
        "| --- | ---: |",
    ]
    for status, count in payload["summary"]["status_counts"].items():
        lines.append(f"| `{status}` | {count} |")
    lines.extend(
        [
            "",
            "## Deck Core Rows",
            "",
            "| Deck | Commander | Scope | Core Status | Lands | Ramp | Draw | Removal | Wipes | Protection | Wincon | Unknown | Next Gate |",
            "| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |",
        ]
    )
    for row in payload["decks"]:
        counts = row["role_counts"]
        lines.append(
            "| `{deck}` | `{commander}` | `{scope}` | `{status}` | {land} | {ramp} | {draw} | {removal} | {wipe} | {protection} | {wincon} | {unknown} | `{next_gate}` |".format(
                deck=f"{row['deck_name']} ({row['deck_id']})".replace("|", "/"),
                commander=str(row.get("commander") or "").replace("|", "/"),
                scope=row["scope"],
                status=row["core_status"],
                land=counts["land"],
                ramp=counts["ramp"],
                draw=counts["draw"],
                removal=counts["removal"],
                wipe=counts["board_wipe"],
                protection=counts["protection"],
                wincon=counts["wincon"],
                unknown=counts["unknown"],
                next_gate=row["next_gate"],
            )
        )
    lines.extend(
        [
            "",
            "## Method Notes",
            "",
            "- This report is read-only and does not promote decks.",
            "- Role bands are generic Commander floors; commander-specific profiles may adjust them later.",
            "- Structured tags win; Oracle text inference is diagnostic fallback for untagged lab decks.",
            "- Deck 607 is treated as a benchmark/regression deck, not a global template.",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sqlite-db", type=Path, default=DEFAULT_SQLITE_DB)
    parser.add_argument("--skip-postgres", action="store_true")
    parser.add_argument("--skip-hermes", action="store_true")
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "global_commander_core_role_audit_20260705_current",
    )
    args = parser.parse_args()
    payload = build_report(
        sqlite_db=args.sqlite_db,
        skip_postgres=args.skip_postgres,
        skip_hermes=args.skip_hermes,
    )
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "summary": payload["summary"],
            },
            ensure_ascii=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
