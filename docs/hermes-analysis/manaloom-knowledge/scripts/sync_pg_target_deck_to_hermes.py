#!/usr/bin/env python3
"""Sync one real PostgreSQL deck into Hermes SQLite `deck_cards`.

Hermes battle tooling expects a local SQLite target deck, traditionally
`deck_id=6`. This script makes a dev/runtime knowledge.db usable by importing a
real ManaLoom deck from Postgres instead of relying on old local artifacts.
"""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
from pathlib import Path
from typing import Any

from db_helper import connect, sanitized_database_target


DEFAULT_SQLITE_DB = Path(
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
)

ROLE_TO_TAG = {
    "draw": "draw",
    "engine": "engine",
    "land": "land",
    "protection": "protection",
    "ramp": "ramp",
    "removal": "removal",
    "tutor": "tutor",
    "unknown": "unknown",
    "wincon": "wincon",
    "wipe": "board_wipe",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Cache one PG deck into Hermes SQLite deck_cards."
    )
    parser.add_argument("--sqlite-db", default=str(DEFAULT_SQLITE_DB))
    parser.add_argument("--pg-deck-id", default=os.environ.get("MANALOOM_TARGET_PG_DECK_ID", ""))
    parser.add_argument(
        "--deck-name-like",
        default=os.environ.get("MANALOOM_TARGET_DECK_NAME_LIKE", "%Runtime Lorehold Learned%"),
    )
    parser.add_argument("--target-deck-id", type=int, default=6)
    parser.add_argument("--min-total-cards", type=int, default=90)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--report")
    return parser.parse_args()


def normalize_tag(value: str | None) -> str:
    text = (value or "unknown").strip().lower()
    return ROLE_TO_TAG.get(text, text or "unknown")


def infer_tag(row: dict[str, Any]) -> str:
    role = row.get("battle_role")
    if isinstance(role, dict):
        tag = normalize_tag(role.get("category"))
        if tag != "unknown":
            return tag
    effect = str(row.get("battle_effect") or "").lower()
    if effect in {"remove_creature", "remove_permanent", "remove_artifact_or_3dmg"}:
        return "removal"
    if effect in {"board_wipe", "damage_wipe"}:
        return "board_wipe"
    if effect.startswith("ramp"):
        return "ramp"
    if effect in {"draw_cards", "draw_engine", "loot", "topdeck_manipulation"}:
        return "draw"
    if effect in {"phase_out", "indestructible", "modal_boros_charm", "silence_opponents"}:
        return "protection"
    if effect in {"approach", "finisher", "token_maker", "steal_all_creatures"}:
        return "wincon"
    if effect == "tutor":
        return "tutor"
    type_line = str(row.get("type_line") or "").lower()
    oracle = str(row.get("oracle_text") or "").lower()
    if "land" in type_line:
        return "land"
    if "destroy target" in oracle or "exile target" in oracle:
        return "removal"
    if "draw" in oracle:
        return "draw"
    if "add " in oracle and "mana" in oracle:
        return "ramp"
    if "creature" in type_line:
        return "creature"
    return "unknown"


def ensure_sqlite_schema(cur: sqlite3.Cursor) -> None:
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS decks (
            id INTEGER PRIMARY KEY,
            deck_name TEXT,
            archetype TEXT,
            total_cards INTEGER DEFAULT 100,
            notes TEXT
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS deck_cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER,
            card_name TEXT NOT NULL,
            quantity INTEGER DEFAULT 1,
            functional_tag TEXT,
            tag_confidence REAL,
            is_commander INTEGER DEFAULT 0,
            is_partner INTEGER DEFAULT 0,
            cmc REAL,
            type_line TEXT,
            oracle_text TEXT,
            UNIQUE(deck_id, card_name)
        )
        """
    )


def aggregate_cards(cards: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Collapse duplicate card-name rows before writing into unique SQLite rows."""
    aggregated: dict[str, dict[str, Any]] = {}
    for card in cards:
        name = str(card.get("name") or "").strip()
        if not name:
            continue
        key = name.casefold()
        quantity = int(card.get("quantity") or 1)
        existing = aggregated.get(key)
        if existing is None:
            normalized = dict(card)
            normalized["name"] = name
            normalized["quantity"] = quantity
            normalized["is_commander"] = bool(card.get("is_commander"))
            aggregated[key] = normalized
            continue

        existing["quantity"] = int(existing.get("quantity") or 0) + quantity
        existing["is_commander"] = bool(existing.get("is_commander")) or bool(
            card.get("is_commander")
        )

        existing_tag = str(existing.get("functional_tag") or "unknown")
        candidate_tag = str(card.get("functional_tag") or "unknown")
        if existing_tag == "unknown" and candidate_tag != "unknown":
            existing["functional_tag"] = candidate_tag

        for field in (
            "cmc",
            "type_line",
            "oracle_text",
            "rule_source",
            "rule_review_status",
        ):
            if not existing.get(field) and card.get(field):
                existing[field] = card[field]

    return sorted(
        aggregated.values(),
        key=lambda card: (not bool(card.get("is_commander")), str(card.get("name") or "")),
    )


def selected_deck_sql(args: argparse.Namespace) -> tuple[str, tuple[Any, ...]]:
    if args.pg_deck_id:
        return "WHERE d.id = %s", (args.pg_deck_id,)
    return (
        """
        WHERE d.name ILIKE %s
           OR EXISTS (
             SELECT 1
             FROM deck_cards dc2
             JOIN cards c2 ON c2.id = dc2.card_id
             WHERE dc2.deck_id = d.id
               AND dc2.is_commander = true
               AND c2.name ILIKE '%%Lorehold%%'
           )
        """,
        (args.deck_name_like,),
    )


def fetch_target_deck(args: argparse.Namespace) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    where_sql, params = selected_deck_sql(args)
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                f"""
                SELECT
                  d.id::text,
                  d.name,
                  d.format,
                  d.archetype,
                  d.bracket,
                  d.created_at,
                  count(dc.*) AS rows,
                  COALESCE(sum(dc.quantity), 0) AS total_qty,
                  max(CASE WHEN dc.is_commander THEN c.name ELSE NULL END) AS commander
                FROM decks d
                JOIN deck_cards dc ON dc.deck_id = d.id
                JOIN cards c ON c.id = dc.card_id
                {where_sql}
                GROUP BY d.id, d.name, d.format, d.archetype, d.bracket, d.created_at
                ORDER BY
                  CASE WHEN COALESCE(sum(dc.quantity), 0) = 100 THEN 0 ELSE 1 END,
                  CASE WHEN count(dc.*) >= 80 THEN 0 ELSE 1 END,
                  d.created_at DESC NULLS LAST
                LIMIT 1
                """,
                params,
            )
            deck_row = cur.fetchone()
            if not deck_row:
                raise RuntimeError("No PG target deck found.")
            pg_deck_id = deck_row[0]
            deck = {
                "pg_deck_id": pg_deck_id,
                "name": deck_row[1],
                "format": deck_row[2],
                "archetype": deck_row[3],
                "bracket": deck_row[4],
                "created_at": str(deck_row[5]),
                "rows": int(deck_row[6]),
                "total_qty": int(deck_row[7]),
                "commander": deck_row[8],
            }
            if deck["total_qty"] < args.min_total_cards:
                raise RuntimeError(
                    "Selected PG deck is partial: "
                    f"total_qty={deck['total_qty']}, min_total_cards={args.min_total_cards}, "
                    f"pg_deck_id={pg_deck_id}. Refusing to sync phantom deck."
                )
            if not deck["commander"]:
                raise RuntimeError(
                    f"Selected PG deck has no commander row: pg_deck_id={pg_deck_id}."
                )
            cur.execute(
                """
                SELECT
                  c.name,
                  dc.quantity,
                  dc.is_commander,
                  c.cmc::float,
                  c.type_line,
                  c.oracle_text,
                  cbr.effect_json,
                  cbr.deck_role_json,
                  cbr.source,
                  cbr.review_status
                FROM deck_cards dc
                JOIN cards c ON c.id = dc.card_id
                LEFT JOIN card_battle_rules cbr
                  ON cbr.card_id = c.id
                WHERE dc.deck_id = %s
                ORDER BY dc.is_commander DESC, c.name
                """,
                (pg_deck_id,),
            )
            cards = []
            for row in cur.fetchall():
                effect_json = row[6] if isinstance(row[6], dict) else {}
                role_json = row[7] if isinstance(row[7], dict) else {}
                card = {
                    "name": row[0],
                    "quantity": int(row[1] or 1),
                    "is_commander": bool(row[2]),
                    "cmc": float(row[3] or 0),
                    "type_line": row[4] or "",
                    "oracle_text": row[5] or "",
                    "battle_effect": effect_json.get("effect"),
                    "battle_role": role_json,
                    "rule_source": row[8],
                    "rule_review_status": row[9],
                }
                card["functional_tag"] = infer_tag(card)
                cards.append(card)
            return deck, cards


def write_sqlite(
    sqlite_db: str,
    target_deck_id: int,
    deck: dict[str, Any],
    cards: list[dict[str, Any]],
    *,
    apply: bool,
) -> dict[str, int]:
    aggregated_cards = aggregate_cards(cards)
    stats = {
        "cards_seen": len(cards),
        "quantity_seen": sum(int(card["quantity"]) for card in cards),
        "duplicate_rows_collapsed": len(cards) - len(aggregated_cards),
        "cards_written": 0,
        "quantity_written": 0,
        "commanders": sum(1 for card in aggregated_cards if card["is_commander"]),
    }
    conn = sqlite3.connect(sqlite_db)
    try:
        cur = conn.cursor()
        ensure_sqlite_schema(cur)
        if apply:
            cur.execute("DELETE FROM deck_cards WHERE deck_id=?", (target_deck_id,))
            cur.execute("DELETE FROM decks WHERE id=?", (target_deck_id,))
            cur.execute(
                """
                INSERT INTO decks (id, deck_name, archetype, total_cards, notes)
                VALUES (?, ?, ?, ?, ?)
                """,
                (
                    target_deck_id,
                    deck["name"],
                    deck.get("archetype") or "unknown",
                    deck["total_qty"],
                    f"sync_pg_target_deck_to_hermes.py pg_deck_id={deck['pg_deck_id']}",
                ),
            )
            for card in aggregated_cards:
                cur.execute(
                    """
                    INSERT INTO deck_cards (
                        deck_id,
                        card_name,
                        quantity,
                        functional_tag,
                        tag_confidence,
                        is_commander,
                        is_partner,
                        cmc,
                        type_line,
                        oracle_text
                    )
                    VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, ?)
                    """,
                    (
                        target_deck_id,
                        card["name"],
                        card["quantity"],
                        card["functional_tag"],
                        1.0 if card.get("rule_review_status") in ("verified", "active") else 0.55,
                        1 if card["is_commander"] else 0,
                        card["cmc"],
                        card["type_line"],
                        card["oracle_text"],
                    ),
                )
                stats["cards_written"] += 1
                stats["quantity_written"] += int(card["quantity"])
            conn.commit()
        else:
            conn.rollback()
    finally:
        conn.close()
    return stats


def main() -> int:
    args = parse_args()
    sqlite_db = Path(args.sqlite_db)
    sqlite_db.parent.mkdir(parents=True, exist_ok=True)
    deck, cards = fetch_target_deck(args)
    stats = write_sqlite(
        str(sqlite_db),
        args.target_deck_id,
        deck,
        cards,
        apply=args.apply,
    )
    report = {
        "apply": bool(args.apply),
        "database_target": sanitized_database_target(),
        "sqlite_db": str(sqlite_db),
        "target_deck_id": args.target_deck_id,
        "deck": deck,
        "stats": stats,
        "tags": dict(sorted({tag: sum(1 for c in cards if c["functional_tag"] == tag) for tag in {c["functional_tag"] for c in cards}}.items())),
    }
    output = json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True)
    print(output)
    if args.report:
        Path(args.report).write_text(output + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
