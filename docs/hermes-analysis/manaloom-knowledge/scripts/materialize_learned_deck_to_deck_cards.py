#!/usr/bin/env python3
"""Materialize a `learned_decks.card_list` JSON deck into `deck_cards`.

Hermes imports some EDHREC/meta decks as compact JSON in `learned_decks`.
The optimizer, however, intentionally operates on normalized `deck_cards`
rows so it can hash, freeze, swap and rollback one card at a time. This bridge
turns a learned deck into a normal optimizer target without touching PG.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_DB = Path(os.environ.get("MANALOOM_KNOWLEDGE_DB", SCRIPT_DIR / "knowledge.db"))
BASIC_LANDS = {"plains", "island", "swamp", "mountain", "forest", "wastes"}


def normalize_name(name: str) -> str:
    return re.sub(r"\s+", " ", str(name or "").strip().lower())


def read_json_list(raw: str | None) -> list[Any]:
    if not raw:
        return []
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        return []
    return value if isinstance(value, list) else []


def ensure_deck_cards(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS deck_cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER,
            card_name TEXT,
            quantity INTEGER DEFAULT 1,
            functional_tag TEXT,
            tag_confidence REAL DEFAULT 0.0,
            is_commander INTEGER DEFAULT 0,
            is_partner INTEGER DEFAULT 0,
            cmc REAL,
            type_line TEXT,
            oracle_text TEXT,
            UNIQUE(deck_id, card_name)
        )
        """
    )


def oracle_cache(conn: sqlite3.Connection, card_names: list[str]) -> dict[str, sqlite3.Row]:
    rows: dict[str, sqlite3.Row] = {}
    if not card_names:
        return rows
    placeholders = ",".join("?" for _ in card_names)
    query = f"""
        SELECT normalized_name, name, cmc, type_line, oracle_text
        FROM card_oracle_cache
        WHERE normalized_name IN ({placeholders})
    """
    for row in conn.execute(query, [normalize_name(name) for name in card_names]).fetchall():
        rows[str(row["normalized_name"])] = row
    return rows


def infer_tag(type_line: str, oracle_text: str) -> tuple[str, float]:
    text = f"{type_line}\n{oracle_text}".lower()
    if "land" in type_line.lower():
        return "land", 0.95
    if "counter target" in text:
        return "counter", 0.85
    if "destroy target" in text or "exile target" in text or "return target" in text:
        return "removal", 0.75
    if "search your library" in text:
        return "tutor", 0.75
    if "draw" in text:
        return "draw", 0.7
    if "add " in text or "treasure token" in text:
        return "ramp", 0.7
    if "create" in text and "token" in text:
        return "token_maker", 0.65
    if "creature" in type_line.lower():
        return "creature", 0.8
    return "unknown", 0.25


def materialize(args: argparse.Namespace) -> dict[str, Any]:
    db_path = Path(args.sqlite_db)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    ensure_deck_cards(conn)

    deck = conn.execute(
        """
        SELECT id, commander, deck_name, card_list
        FROM learned_decks
        WHERE id=?
        """,
        (args.learned_deck_id,),
    ).fetchone()
    if not deck:
        raise SystemExit(f"learned_deck_id not found: {args.learned_deck_id}")

    cards = read_json_list(deck["card_list"])
    card_names = [str(card.get("name") or "").strip() for card in cards if isinstance(card, dict)]
    commander = str(deck["commander"] or "").strip()
    names_for_oracle = [commander, *card_names]
    cache = oracle_cache(conn, names_for_oracle)
    target_deck_id = int(args.target_deck_id or args.learned_deck_id)

    rows: list[dict[str, Any]] = []
    if commander:
        rows.append({"name": commander, "quantity": 1, "is_commander": 1})
    for card in cards:
        if not isinstance(card, dict):
            continue
        name = str(card.get("name") or "").strip()
        if not name or normalize_name(name) == normalize_name(commander):
            continue
        quantity = int(card.get("quantity") or 1)
        rows.append({"name": name, "quantity": max(1, min(30, quantity)), "is_commander": 0})

    collapsed: dict[str, dict[str, Any]] = {}
    for row in rows:
        key = normalize_name(row["name"])
        if key in collapsed:
            if key in BASIC_LANDS:
                collapsed[key]["quantity"] += int(row["quantity"] or 1)
            continue
        collapsed[key] = dict(row)
    rows = list(collapsed.values())

    current_total = sum(int(row["quantity"] or 1) for row in rows)
    if args.min_cards and current_total < args.min_cards:
        fill_name = str(args.fill_basic or "Mountain").strip()
        fill_key = normalize_name(fill_name)
        fill_quantity = args.min_cards - current_total
        if fill_key in collapsed:
            collapsed[fill_key]["quantity"] += fill_quantity
        else:
            collapsed[fill_key] = {
                "name": fill_name,
                "quantity": fill_quantity,
                "is_commander": 0,
            }
        rows = list(collapsed.values())

    if args.apply:
        conn.execute("DELETE FROM deck_cards WHERE deck_id=?", (target_deck_id,))
        for row in rows:
            oracle = cache.get(normalize_name(row["name"]))
            type_line = str(oracle["type_line"] or "") if oracle else ""
            oracle_text = str(oracle["oracle_text"] or "") if oracle else ""
            cmc = oracle["cmc"] if oracle else None
            tag, confidence = infer_tag(type_line, oracle_text)
            if row["is_commander"]:
                tag, confidence = "commander", 1.0
            conn.execute(
                """
                INSERT OR REPLACE INTO deck_cards (
                    deck_id, card_name, quantity, functional_tag, tag_confidence,
                    is_commander, is_partner, cmc, type_line, oracle_text
                ) VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, ?)
                """,
                (
                    target_deck_id,
                    row["name"],
                    row["quantity"],
                    tag,
                    confidence,
                    row["is_commander"],
                    cmc,
                    type_line,
                    oracle_text,
                ),
            )
        conn.commit()

    summary = {
        "apply": bool(args.apply),
        "sqlite_db": str(db_path),
        "learned_deck_id": int(args.learned_deck_id),
        "target_deck_id": target_deck_id,
        "commander": commander,
        "deck_name": deck["deck_name"],
        "rows": len(rows),
        "quantity": sum(int(row["quantity"] or 1) for row in rows),
        "oracle_rows": len(cache),
    }
    conn.close()
    return summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument("--learned-deck-id", type=int, required=True)
    parser.add_argument("--target-deck-id", type=int)
    parser.add_argument("--min-cards", type=int, default=100)
    parser.add_argument("--fill-basic", default="Mountain")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    print(json.dumps(materialize(args), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
