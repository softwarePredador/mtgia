#!/usr/bin/env python3
"""Create the read-only Lorehold current champion snapshot.

This is the deckbuilding checkpoint after trace-targeted micro-package modeling.
It does not mutate PostgreSQL or SQLite. It records deck 607 as the protected
current champion until a future package has named adds, named cuts, and a
seed-safe cut decision.
"""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = Path(os.environ.get("MANALOOM_KNOWLEDGE_DB", SCRIPT_DIR / "knowledge.db"))
DEFAULT_DECK_ID = 607
DEFAULT_MICRO_PACKAGE_MODEL = (
    REPORT_DIR / "lorehold_trace_targeted_micro_package_model_20260630_goal_learning.json"
)
DEFAULT_PLANNER_REPORT = (
    REPORT_DIR / "lorehold_next_action_planner_20260630_goal_learning_micro_package_model.json"
)
BASE_PROTECTED_ANCHORS = [
    "Lorehold, the Historian",
    "Sensei's Divining Top",
    "Scroll Rack",
    "Approach of the Second Sun",
    "Victory Chimes",
    "Mizzix's Mastery",
    "Bender's Waterskin",
    "Jeska's Will",
    "Library of Leng",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json_if_exists(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def normalize(name: str) -> str:
    return " ".join(str(name).strip().lower().split())


def is_land(type_line: object) -> bool:
    return "land" in str(type_line or "").lower()


def classify_role(row: sqlite3.Row) -> str:
    if int(row["is_commander"] or 0):
        return "commander"
    if is_land(row["type_line"]):
        return "land"
    return str(row["functional_tag"] or "unknown")


def deck_rows(conn: sqlite3.Connection, deck_id: int) -> list[sqlite3.Row]:
    return conn.execute(
        """
        SELECT card_name, quantity, functional_tag, is_commander, cmc, type_line,
               card_id, deck_hash, semantics_hash, ruleset_hash
        FROM deck_cards
        WHERE deck_id=?
        ORDER BY
          is_commander DESC,
          CASE WHEN lower(COALESCE(type_line, '')) LIKE '%land%' THEN 2 ELSE 1 END,
          COALESCE(cmc, 999),
          card_name
        """,
        (deck_id,),
    ).fetchall()


def extract_card_from_event(event: str) -> str | None:
    if ":" not in event:
        return None
    card = event.split(":", 1)[1].strip()
    return card or None


def anchor_cards_from_model(model: Mapping[str, Any] | None) -> list[str]:
    anchors = list(BASE_PROTECTED_ANCHORS)
    if model:
        evidence = model.get("protected_anchor_evidence") or {}
        for row in evidence.get("top_anchor_card_deficits") or []:
            card = extract_card_from_event(str(row.get("event") or ""))
            if card:
                anchors.append(card)
    seen: set[str] = set()
    result: list[str] = []
    for card in anchors:
        key = normalize(card)
        if key not in seen:
            seen.add(key)
            result.append(card)
    return result


def summarize_hashes(rows: Iterable[sqlite3.Row]) -> dict[str, list[str]]:
    hashes: dict[str, set[str]] = {
        "deck_hashes": set(),
        "semantics_hashes": set(),
        "ruleset_hashes": set(),
    }
    for row in rows:
        if row["deck_hash"]:
            hashes["deck_hashes"].add(str(row["deck_hash"]))
        if row["semantics_hash"]:
            hashes["semantics_hashes"].add(str(row["semantics_hash"]))
        if row["ruleset_hash"]:
            hashes["ruleset_hashes"].add(str(row["ruleset_hash"]))
    return {key: sorted(values) for key, values in hashes.items()}


def build_snapshot(
    *,
    conn: sqlite3.Connection,
    deck_id: int,
    db_path: Path,
    micro_package_model: Mapping[str, Any] | None,
    planner_report: Mapping[str, Any] | None,
    micro_package_model_path: Path,
    planner_report_path: Path,
) -> dict[str, Any]:
    rows = deck_rows(conn, deck_id)
    role_counts: Counter[str] = Counter()
    card_names: set[str] = set()
    cards: list[dict[str, Any]] = []
    for row in rows:
        qty = int(row["quantity"] or 0)
        role = classify_role(row)
        role_counts[role] += qty
        card_names.add(normalize(str(row["card_name"])))
        cards.append(
            {
                "quantity": qty,
                "name": row["card_name"],
                "role": role,
                "functional_tag": row["functional_tag"],
                "is_commander": bool(row["is_commander"]),
                "cmc": row["cmc"],
                "type_line": row["type_line"],
                "card_id": row["card_id"],
            }
        )

    total_cards = sum(card["quantity"] for card in cards)
    commander_count = sum(card["quantity"] for card in cards if card["is_commander"])
    land_count = sum(card["quantity"] for card in cards if is_land(card["type_line"]))
    protected_anchors = anchor_cards_from_model(micro_package_model)
    missing_anchors = [card for card in protected_anchors if normalize(card) not in card_names]
    validation_errors: list[str] = []
    if total_cards != 100:
        validation_errors.append(f"expected 100 cards, found {total_cards}")
    if commander_count != 1:
        validation_errors.append(f"expected 1 commander, found {commander_count}")
    if missing_anchors:
        validation_errors.append(f"missing protected anchors: {', '.join(missing_anchors)}")

    micro_summary = (micro_package_model or {}).get("summary") or {}
    planner_summary = (planner_report or {}).get("summary") or {}
    recommended = str(planner_summary.get("recommended_next_action") or "")
    status = "current_champion_snapshot" if not validation_errors else "blocked"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_current_champion_snapshot",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_id": deck_id,
        "status": status,
        "sqlite_db": rel(db_path),
        "micro_package_model_report": rel(micro_package_model_path),
        "planner_report": rel(planner_report_path),
        "summary": {
            "deck_id": deck_id,
            "deck_row_count": len(cards),
            "total_cards": total_cards,
            "commander_count": commander_count,
            "land_count": land_count,
            "role_counts": dict(sorted(role_counts.items())),
            "protected_anchor_count": len(protected_anchors),
            "missing_protected_anchor_count": len(missing_anchors),
            "validation_error_count": len(validation_errors),
            "planner_recommended_next_action": recommended,
            "micro_package_ready_count": int(
                micro_summary.get("ready_micro_package_count") or 0
            ),
            "seed_safe_cut_ready_count": int(micro_summary.get("seed_safe_cut_ready_count") or 0),
        },
        "champion_decision": {
            "decision": "keep_607_as_current_champion",
            "reason": (
                "Trace-targeted hypotheses exist, but no micro-package has both named "
                "adds and a seed-safe cut."
            ),
            "replacement_allowed_only_when": [
                "package names exact add cards and cut cards",
                "cut is seed-safe under the current cut model",
                "natural gate ties or beats protected 607 on the same opponent and seed window",
                "miracle/topdeck/spell-volume and pressure-window targets do not regress",
                "added cards are drawn, cast, resolved, activated, or otherwise used enough to prove impact",
            ],
        },
        "protected_anchors": protected_anchors,
        "missing_protected_anchors": missing_anchors,
        "hash_summary": summarize_hashes(rows),
        "validation_errors": validation_errors,
        "cards": cards,
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Current Champion Snapshot",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Deck id: `{payload['deck_id']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        f"- SQLite DB: `{payload['sqlite_db']}`",
        f"- Micro-package model: `{payload['micro_package_model_report']}`",
        f"- Planner report: `{payload['planner_report']}`",
        f"- Total cards: `{summary['total_cards']}`",
        f"- Deck rows: `{summary['deck_row_count']}`",
        f"- Lands: `{summary['land_count']}`",
        f"- Commander count: `{summary['commander_count']}`",
        f"- Missing protected anchors: `{summary['missing_protected_anchor_count']}`",
        f"- Planner next action: `{summary['planner_recommended_next_action']}`",
        f"- Micro-package ready count: `{summary['micro_package_ready_count']}`",
        f"- Seed-safe cut ready count: `{summary['seed_safe_cut_ready_count']}`",
        "",
        "## Decision",
        "",
        f"- `{payload['champion_decision']['decision']}`: {payload['champion_decision']['reason']}",
        "",
        "## Replacement Contract",
        "",
    ]
    for rule in payload["champion_decision"]["replacement_allowed_only_when"]:
        lines.append(f"- {rule}")
    lines.extend(["", "## Protected Anchors", ""])
    for card in payload["protected_anchors"]:
        lines.append(f"- {card}")
    lines.extend(["", "## Validation", ""])
    if payload["validation_errors"]:
        for error in payload["validation_errors"]:
            lines.append(f"- ERROR: {error}")
    else:
        lines.append("- PASS: 100 cards and exactly one commander.")
        lines.append("- PASS: protected anchors are present in deck 607.")
    lines.extend(["", "## Role Counts", ""])
    for role, count in summary["role_counts"].items():
        lines.append(f"- {role}: {count}")
    lines.extend(["", "## Decklist", "", "```text"])
    for card in payload["cards"]:
        lines.append(f"{card['quantity']} {card['name']}")
    lines.extend(["```", ""])
    return "\n".join(lines)


def render_decklist(payload: Mapping[str, Any]) -> str:
    return "\n".join(f"{card['quantity']} {card['name']}" for card in payload["cards"]) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_DECK_ID)
    parser.add_argument("--micro-package-model", type=Path, default=DEFAULT_MICRO_PACKAGE_MODEL)
    parser.add_argument("--planner-report", type=Path, default=DEFAULT_PLANNER_REPORT)
    parser.add_argument("--stem", default="lorehold_current_champion_snapshot_20260630_current")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.db.exists():
        raise SystemExit(f"SQLite DB not found: {args.db}")
    conn = sqlite3.connect(args.db)
    conn.row_factory = sqlite3.Row
    try:
        payload = build_snapshot(
            conn=conn,
            deck_id=args.deck_id,
            db_path=args.db,
            micro_package_model=read_json_if_exists(args.micro_package_model),
            planner_report=read_json_if_exists(args.planner_report),
            micro_package_model_path=args.micro_package_model,
            planner_report_path=args.planner_report,
        )
    finally:
        conn.close()

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    decklist_path = REPORT_DIR / f"{args.stem}.decklist.txt"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    decklist_path.write_text(render_decklist(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(f"wrote {decklist_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 1 if payload["validation_errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
