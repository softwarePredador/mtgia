#!/usr/bin/env python3
"""Generate research-backed Lorehold 607 candidates in isolated SQLite DBs."""

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

from lorehold_strategy_profile import (
    STRATEGY_VERSION,
    commander_intent_alignment,
    strategy_tags_for_card,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_SOURCE_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_PLAN = "penance_v1"

RESEARCH_PLANS = {
    "penance_v1": {
        "base_deck_id": 607,
        "candidate_deck_id": 6,
        "added": [{"card_name": "Penance", "source_deck_id": 609}],
        "removed": ["Promise of Loyalty"],
        "intent": (
            "Test one external-learning swap: add Penance for topdeck setup and "
            "red/black damage prevention while removing one five-mana pressure spell. "
            "This protects the deck_607 shell and follows the one-card ablation rule."
        ),
        "external_signals": [
            "EDHREC average Lorehold lists include Penance as a commander-specific support card.",
            "Reddit discussion highlights Penance as a Lorehold enabler because it puts cards from hand on top of library.",
            "Local battle_card_rules has a verified auto rule for Penance.",
        ],
    },
    "longshot_v1": {
        "base_deck_id": 607,
        "candidate_deck_id": 6,
        "added": [{"card_name": "Longshot, Rebel Bowman", "source_deck_id": 615}],
        "removed": ["Storm Herd"],
        "intent": (
            "Test one external-learning payoff swap: replace a ten-mana token finisher "
            "with a lower-curve noncreature-spell payoff that also reduces noncreature "
            "spell costs. This preserves the deck_607 defensive shell."
        ),
        "external_signals": [
            "EDHREC and public Lorehold lists surface Longshot-style noncreature spell payoff as a recent spellslinger lane.",
            "Internal Lorehold variant 615 includes Longshot and ranked second in the intent matrix after deck_607.",
            "Local battle_card_rules has a verified auto rule for Longshot's noncreature-spell damage trigger.",
        ],
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


def load_deck_rows(conn: sqlite3.Connection, deck_id: int) -> dict[str, dict[str, Any]]:
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT * FROM deck_cards WHERE deck_id=? ORDER BY is_commander DESC, card_name",
        (deck_id,),
    ).fetchall()
    return {normalize_name(row["card_name"]): dict(row) for row in rows}


def load_card_from_deck(conn: sqlite3.Connection, *, deck_id: int, card_name: str) -> dict[str, Any]:
    row = conn.execute(
        """
        SELECT *
        FROM deck_cards
        WHERE deck_id=? AND lower(card_name)=lower(?)
        LIMIT 1
        """,
        (deck_id, card_name),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"missing source card {card_name!r} in deck {deck_id}")
    return dict(row)


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


def build_candidate_rows(
    conn: sqlite3.Connection,
    *,
    base_deck_id: int,
    added: list[Mapping[str, Any]],
    removed: list[str],
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    base = load_deck_rows(conn, base_deck_id)
    missing_remove = [name for name in removed if normalize_name(name) not in base]
    if missing_remove:
        raise RuntimeError(f"missing removed cards in deck {base_deck_id}: {missing_remove}")

    selected = {
        key: dict(row)
        for key, row in base.items()
        if key not in {normalize_name(name) for name in removed}
    }
    for item in added:
        card = load_card_from_deck(
            conn,
            deck_id=int(item["source_deck_id"]),
            card_name=str(item["card_name"]),
        )
        selected[normalize_name(card["card_name"])] = card

    commander_key = normalize_name("Lorehold, the Historian")
    rows = [selected[commander_key]] + [
        row
        for key, row in sorted(selected.items(), key=lambda item: item[1]["card_name"])
        if key != commander_key
    ]
    quantity_total = sum(int(row.get("quantity") or 1) for row in rows)
    if quantity_total != 100:
        raise RuntimeError(f"candidate quantity_total={quantity_total}, expected 100")
    if len(rows) != 94:
        raise RuntimeError(f"candidate row_count={len(rows)}, expected 94")

    metadata = {
        "base_deck_id": base_deck_id,
        "candidate_deck_id": 6,
        "added": list(added),
        "removed": removed,
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
    return {
        "candidate_hash": hashlib.sha256("\n".join(sorted(names)).encode("utf-8")).hexdigest(),
        "role_counts": dict(sorted(role_counts.items())),
        "strategy_package_counts": dict(sorted(strategy_counts.items())),
        "commander_intent_alignment": commander_intent_alignment(final_deck),
        "lands": role_counts.get("land", 0),
        "nonlands": 100 - role_counts.get("land", 0),
        "final_deck": final_deck,
    }


def render_markdown(report: Mapping[str, Any]) -> str:
    lines = [
        f"# Lorehold 607 Research Candidate {report['plan']}",
        "",
        f"- generated_at: `{report['generated_at']}`",
        f"- source_db: `{report['source_db']}`",
        f"- candidate_db: `{report['candidate_db']}`",
        f"- candidate_hash: `{report['candidate_hash']}`",
        f"- strategy_version: `{report['strategy_version']}`",
        f"- commander_intent_score: `{report['commander_intent_alignment']['score']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Intent",
        "",
        str(report["intent"]),
        "",
        "## External Signals",
        "",
    ]
    for signal in report.get("external_signals") or []:
        lines.append(f"- {signal}")
    lines.extend(["", "## Swaps", "", "| In | Out |", "| --- | --- |"])
    added_names = [str(item["card_name"]) for item in report["added"]]
    for add, remove in zip(added_names, report["removed"]):
        lines.append(f"| {add} | {remove} |")
    lines.extend(["", "## Counts", ""])
    for key in ("row_count", "quantity_total", "lands", "nonlands"):
        lines.append(f"- {key}: `{report[key]}`")
    lines.extend(["", "### Strategy Package Counts", ""])
    for key, value in report["strategy_package_counts"].items():
        lines.append(f"- `{key}`: {value}")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-db", type=Path, default=DEFAULT_SOURCE_DB)
    parser.add_argument("--plan", choices=sorted(RESEARCH_PLANS), default=DEFAULT_PLAN)
    parser.add_argument("--out-dir", type=Path, default=None)
    args = parser.parse_args()

    plan = RESEARCH_PLANS[args.plan]
    out_dir = args.out_dir or REPORT_DIR / f"lorehold_607_research_candidate_20260626_{args.plan}"
    out_dir.mkdir(parents=True, exist_ok=True)
    candidate_db = out_dir / "knowledge_candidate.db"
    shutil.copy2(args.source_db, candidate_db)

    conn = sqlite3.connect(candidate_db)
    rows, metadata = build_candidate_rows(
        conn,
        base_deck_id=int(plan["base_deck_id"]),
        added=list(plan["added"]),
        removed=list(plan["removed"]),
    )
    insert_deck_rows(conn, rows, deck_id=int(plan["candidate_deck_id"]))
    conn.execute(
        """
        UPDATE decks
        SET deck_name=?, archetype=?, notes=?
        WHERE id=?
        """,
        (
            f"Lorehold 607 Research Candidate {args.plan}",
            f"607-research-candidate-{args.plan}",
            "isolated candidate generated by lorehold_607_research_candidate.py",
            int(plan["candidate_deck_id"]),
        ),
    )
    conn.commit()
    conn.close()

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
        "external_signals": plan["external_signals"],
        **metadata,
        **summarize_cards(rows),
    }
    json_path = REPORT_DIR / f"lorehold_607_research_candidate_20260626_{args.plan}.json"
    md_path = REPORT_DIR / f"lorehold_607_research_candidate_20260626_{args.plan}.md"
    json_path.write_text(json.dumps(report, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(report), encoding="utf-8")
    print(
        json.dumps(
            {
                "status": report["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "candidate_db": str(candidate_db),
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
