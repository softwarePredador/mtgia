#!/usr/bin/env python3
"""Generate a 607 -> v7 Lorehold bridge candidate in an isolated SQLite DB.

The bridge starts from deck 607, preserves its interaction-heavy battle shell,
and imports a small v7 engine/tutor/recursion package. It does not mutate the
source Hermes DB or PostgreSQL.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping

from lorehold_strategy_profile import STRATEGY_VERSION, strategy_tags_for_card


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_SOURCE_DB = (
    REPORT_DIR
    / "lorehold_generated_candidate_20260626_pg243_strategy_first_v7"
    / "knowledge_candidate.db"
)
DEFAULT_PLAN = "v1"

ADD_FROM_V7 = [
    "Aetherflux Reservoir",
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
    "Enlightened Tutor",
    "Gamble",
    "Past in Flames",
    "Storm-Kiln Artist",
]

REMOVE_FROM_607 = [
    "Bender's Waterskin",
    "Emeria's Call // Emeria, Shattered Skyclave",
    "Library of Leng",
    "Molecule Man",
    "The Scarlet Witch",
    "Tragic Arrogance",
]

BRIDGE_PLANS = {
    "v1": {
        "added_from_v7": ADD_FROM_V7,
        "removed_from_607": REMOVE_FROM_607,
        "intent": (
            "Start from the battle-winning `deck_607` shell, keep its pressure/removal "
            "density, and import only a compact v7 package that targets the known "
            "`deck_607` risks: tutor density, graveyard recursion, and spell-chain conversion."
        ),
    },
    "v2": {
        "added_from_v7": [
            "Aetherflux Reservoir",
            "Storm-Kiln Artist",
        ],
        "removed_from_607": [
            "Molecule Man",
            "The Scarlet Witch",
        ],
        "intent": (
            "Start from `deck_607` and test only two v7 payoff imports. This is a "
            "minimal bridge to check whether the v1 failure came from importing too "
            "large an engine/tutor package."
        ),
    },
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_name(value: object) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def json_list(value: object) -> list[Any]:
    if value is None or value == "":
        return []
    if isinstance(value, list):
        return value
    try:
        decoded = json.loads(str(value))
    except Exception:
        return []
    return decoded if isinstance(decoded, list) else []


def card_roles(row: Mapping[str, Any]) -> list[str]:
    roles = []
    for item in json_list(row.get("functional_tags_json")):
        if isinstance(item, dict):
            value = item.get("tag") or item.get("role") or item.get("category")
        else:
            value = item
        if value and str(value) not in roles:
            roles.append(str(value))
    if row.get("functional_tag") and str(row["functional_tag"]) not in roles:
        roles.append(str(row["functional_tag"]))
    if "Land" in str(row.get("type_line") or "") and "land" not in roles:
        roles.append("land")
    return roles


def load_rows(conn: sqlite3.Connection, deck_id: int) -> dict[str, dict[str, Any]]:
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT * FROM deck_cards WHERE deck_id=? ORDER BY is_commander DESC, card_name",
        (deck_id,),
    ).fetchall()
    return {normalize_name(row["card_name"]): dict(row) for row in rows}


def insert_deck_rows(conn: sqlite3.Connection, rows: list[dict[str, Any]], *, deck_id: int) -> None:
    columns = [row[1] for row in conn.execute("PRAGMA table_info(deck_cards)") if row[1] != "id"]
    placeholders = ",".join("?" for _ in columns)
    conn.execute("DELETE FROM deck_cards WHERE deck_id=?", (deck_id,))
    for source in rows:
        values = dict(source)
        values["deck_id"] = deck_id
        conn.execute(
            f"INSERT INTO deck_cards ({','.join(columns)}) VALUES ({placeholders})",
            [values.get(column) for column in columns],
        )


def build_bridge_rows(
    conn: sqlite3.Connection,
    *,
    added_from_v7: list[str],
    removed_from_607: list[str],
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    deck607 = load_rows(conn, 607)
    v7 = load_rows(conn, 6)
    missing_remove = [name for name in removed_from_607 if normalize_name(name) not in deck607]
    missing_add = [name for name in added_from_v7 if normalize_name(name) not in v7]
    if missing_remove or missing_add:
        raise RuntimeError(
            "bridge source mismatch: "
            f"missing_remove={missing_remove} missing_add={missing_add}"
        )

    selected = {
        key: dict(row)
        for key, row in deck607.items()
        if key not in {normalize_name(name) for name in removed_from_607}
    }
    for name in added_from_v7:
        key = normalize_name(name)
        selected[key] = dict(v7[key])

    commander_key = normalize_name("Lorehold, the Historian")
    rows = [selected[commander_key]] + [
        row
        for key, row in sorted(selected.items(), key=lambda item: item[1]["card_name"])
        if key != commander_key
    ]
    quantity_total = sum(int(row.get("quantity") or 1) for row in rows)
    if quantity_total != 100:
        raise RuntimeError(f"bridge quantity_total={quantity_total}, expected 100")
    if len(rows) != 94:
        raise RuntimeError(f"bridge row_count={len(rows)}, expected 94")

    metadata = {
        "base_deck_id": 607,
        "candidate_deck_id": 6,
        "added_from_v7": added_from_v7,
        "removed_from_607": removed_from_607,
        "row_count": len(rows),
        "quantity_total": quantity_total,
    }
    return rows, metadata


def summarize_cards(rows: list[Mapping[str, Any]]) -> dict[str, Any]:
    role_counts: Counter[str] = Counter()
    strategy_counts: Counter[str] = Counter()
    final_deck = []
    for row in rows:
        roles = card_roles(row)
        for role in roles:
            role_counts[role] += int(row.get("quantity") or 1)
        card = {
            "card_name": row.get("card_name"),
            "normalized_name": normalize_name(row.get("card_name")),
            "quantity": int(row.get("quantity") or 1),
            "roles": roles,
            "is_commander": bool(row.get("is_commander")),
            "is_land": "land" in roles or "Land" in str(row.get("type_line") or ""),
            "cmc": row.get("cmc"),
            "type_line": row.get("type_line") or "",
            "oracle_text": row.get("oracle_text") or "",
        }
        for tag in strategy_tags_for_card(card):
            strategy_counts[tag] += 1
        final_deck.append(card)
    names = [card["card_name"] for card in final_deck]
    candidate_hash = hashlib.sha256("\n".join(sorted(names)).encode("utf-8")).hexdigest()
    return {
        "candidate_hash": candidate_hash,
        "role_counts": dict(sorted(role_counts.items())),
        "strategy_package_counts": dict(sorted(strategy_counts.items())),
        "lands": role_counts.get("land", 0),
        "nonlands": 100 - role_counts.get("land", 0),
        "final_deck": final_deck,
    }


def render_markdown(report: Mapping[str, Any]) -> str:
    lines = [
        f"# Lorehold 607 Bridge Candidate {report['plan']}",
        "",
        f"- generated_at: `{report['generated_at']}`",
        f"- source_db: `{report['source_db']}`",
        f"- candidate_db: `{report['candidate_db']}`",
        f"- candidate_hash: `{report['candidate_hash']}`",
        f"- strategy_version: `{report['strategy_version']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Intent",
        "",
        str(report["intent"]),
        "",
        "## Swaps",
        "",
        "| In from v7 | Out from 607 | Rationale |",
        "| --- | --- | --- |",
    ]
    rationales = {
        "Aetherflux Reservoir": "adds a compact spell-chain finisher",
        "Birgi, God of Storytelling // Harnfel, Horn of Bounty": "adds mana/hand engine without cutting removal",
        "Enlightened Tutor": "addresses tutor shortfall and finds key artifacts/enchantments",
        "Gamble": "adds cheap tutor density",
        "Past in Flames": "addresses recursion shortfall for spell-chain recovery",
        "Storm-Kiln Artist": "adds mana conversion and wincon pressure from spell volume",
    }
    for add, remove in zip(report["added_from_v7"], report["removed_from_607"]):
        lines.append(f"| {add} | {remove} | {rationales.get(add, '')} |")
    lines.extend(
        [
            "",
            "## Counts",
            "",
            f"- rows: `{report['row_count']}`",
            f"- quantity_total: `{report['quantity_total']}`",
            f"- lands: `{report['lands']}`",
            f"- nonlands: `{report['nonlands']}`",
            "",
            "### Role Counts",
            "",
        ]
    )
    for key, value in report["role_counts"].items():
        lines.append(f"- `{key}`: {value}")
    lines.extend(["", "### Strategy Package Counts", ""])
    for key, value in report["strategy_package_counts"].items():
        lines.append(f"- `{key}`: {value}")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-db", type=Path, default=DEFAULT_SOURCE_DB)
    parser.add_argument("--plan", choices=sorted(BRIDGE_PLANS), default=DEFAULT_PLAN)
    parser.add_argument("--out-dir", type=Path, default=None)
    args = parser.parse_args()

    plan = BRIDGE_PLANS[args.plan]
    out_dir = args.out_dir or REPORT_DIR / f"lorehold_607_bridge_candidate_20260626_{args.plan}"
    out_dir.mkdir(parents=True, exist_ok=True)
    candidate_db = out_dir / "knowledge_candidate.db"
    shutil.copy2(args.source_db, candidate_db)

    conn = sqlite3.connect(candidate_db)
    rows, metadata = build_bridge_rows(
        conn,
        added_from_v7=list(plan["added_from_v7"]),
        removed_from_607=list(plan["removed_from_607"]),
    )
    insert_deck_rows(conn, rows, deck_id=6)
    conn.execute(
        """
        UPDATE decks
        SET deck_name=?, archetype=?, notes=?
        WHERE id=6
        """,
        (
            f"Lorehold 607 Bridge Candidate {args.plan}",
            f"607-bridge-strategy-candidate-{args.plan}",
            "isolated candidate generated by lorehold_607_bridge_candidate.py",
        ),
    )
    conn.commit()
    conn.close()

    summary = summarize_cards(rows)
    report = {
        "generated_at": utc_now(),
        "status": "generated_isolated_candidate",
        "source_db": str(args.source_db),
        "candidate_db": str(candidate_db),
        "strategy_version": STRATEGY_VERSION,
        "postgres_writes": False,
        "source_db_mutated": False,
        "plan": args.plan,
        "intent": plan["intent"],
        **metadata,
        **summary,
    }
    json_path = REPORT_DIR / f"lorehold_607_bridge_candidate_20260626_{args.plan}.json"
    md_path = REPORT_DIR / f"lorehold_607_bridge_candidate_20260626_{args.plan}.md"
    json_path.write_text(json.dumps(report, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(report), encoding="utf-8")
    print(json.dumps({"status": report["status"], "json": str(json_path), "markdown": str(md_path), "candidate_db": str(candidate_db)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
