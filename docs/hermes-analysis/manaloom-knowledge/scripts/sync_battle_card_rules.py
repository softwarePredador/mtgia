#!/usr/bin/env python3
"""Sync canonical battle/deckbuilding rules into Hermes SQLite.

This does not infer new rules from scratch. It takes the current manual rules
and generated rules, stores them in `battle_card_rules`, and makes their source
and review state explicit for battle/optimizer consumers.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from pathlib import Path

import battle_analyst_v8 as battle
from battle_rule_registry import (
    DEFAULT_DB,
    ensure_battle_card_rules,
    upsert_battle_card_rule,
)


SCRIPT_DIR = Path(__file__).resolve().parent
GENERATED_PATH = SCRIPT_DIR / "known_cards_generated.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument("--skip-generated", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--report")
    return parser.parse_args()


def load_generated_rules() -> dict[str, dict]:
    if not GENERATED_PATH.exists():
        return {}
    try:
        decoded = json.loads(GENERATED_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {}
    return decoded if isinstance(decoded, dict) else {}


def build_rows(include_generated: bool) -> list[dict]:
    rows: list[dict] = []
    for name in sorted(battle.HANDCRAFTED_KNOWN_CARDS):
        effect = dict(battle.KNOWN_CARDS[name])
        rows.append(
            {
                "card_name": name,
                "effect_json": effect,
                "source": "manual",
                "confidence": 1.0,
                "review_status": "verified",
                "notes": "Seeded from HANDCRAFTED_KNOWN_CARDS.",
            }
        )

    if include_generated:
        for name, effect in sorted(load_generated_rules().items()):
            if name in battle.HANDCRAFTED_KNOWN_CARDS:
                continue
            if not isinstance(effect, dict):
                continue
            rows.append(
                {
                    "card_name": name,
                    "effect_json": dict(effect),
                    "source": "generated",
                    "confidence": 0.55,
                    "review_status": "needs_review",
                    "notes": "Seeded from known_cards_generated.json; audit before trusting.",
                }
            )
    return rows


def main() -> int:
    args = parse_args()
    rows = build_rows(include_generated=not args.skip_generated)
    report = {
        "sqlite_db": args.sqlite_db,
        "apply": bool(args.apply),
        "input_rows": len(rows),
        "manual_rows": sum(1 for row in rows if row["source"] == "manual"),
        "generated_rows": sum(1 for row in rows if row["source"] == "generated"),
        "inserted_or_updated": 0,
        "skipped_lower_priority": 0,
    }

    if args.apply:
        conn = sqlite3.connect(args.sqlite_db)
        ensure_battle_card_rules(conn)
        for row in rows:
            changed = upsert_battle_card_rule(
                conn,
                row["card_name"],
                row["effect_json"],
                source=row["source"],
                confidence=row["confidence"],
                review_status=row["review_status"],
                notes=row["notes"],
            )
            if changed:
                report["inserted_or_updated"] += 1
            else:
                report["skipped_lower_priority"] += 1
        conn.commit()
        conn.close()

    output = json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True)
    print(output)
    if args.report:
        Path(args.report).write_text(output + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
