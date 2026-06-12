#!/usr/bin/env python3
"""Report-only audit for stable IDs in learned opponent cardlists.

Battle replays can only emit `card_id`/semantic provenance when a card came
from a trusted snapshot. This script measures whether real learned-opponent
decklists can be resolved against PostgreSQL `cards` without writing anything.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter
from pathlib import Path
from typing import Any

from battle_rule_registry import DEFAULT_DB, normalize_card_name
from db_helper import connect, sanitized_database_target


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument("--candidate-limit", type=int, default=96)
    parser.add_argument("--deck-limit", type=int, default=12)
    parser.add_argument("--min-cards", type=int, default=80)
    parser.add_argument("--report")
    return parser.parse_args()


def decode_card_list(value: Any) -> list[dict[str, Any]]:
    if not value:
        return []
    text = str(value)
    try:
        decoded = json.loads(text)
    except Exception:
        decoded = None
    if isinstance(decoded, list):
        return [
            item if isinstance(item, dict) else {"name": str(item)}
            for item in decoded
            if item
        ]

    cards: list[dict[str, Any]] = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if (
            not line
            or line.startswith("#")
            or line.lower() in ("deck", "commander", "sideboard", "maybeboard")
        ):
            continue
        line = re.sub(r"^(sb:|sideboard:)\s*", "", line, flags=re.I).strip()
        match = re.match(r"^(\d+)\s*x?\s+(.+)$", line, flags=re.I)
        if not match:
            continue
        quantity = max(1, min(30, int(match.group(1))))
        name = re.sub(r"\s+\([^)]*\)\s*\d*\s*$", "", match.group(2)).strip()
        if name:
            cards.append({"name": name, "quantity": quantity})
    return cards


def quantity(value: Any) -> int:
    try:
        return max(1, min(30, int(value)))
    except (TypeError, ValueError):
        return 1


def load_learned_rows(
    sqlite_db: str | Path,
    *,
    candidate_limit: int,
    deck_limit: int,
    min_cards: int,
) -> list[dict[str, Any]]:
    conn = sqlite3.connect(sqlite_db)
    conn.row_factory = sqlite3.Row
    try:
        rows = conn.execute(
            """
            SELECT id, commander, source, archetype, card_count, card_list
            FROM learned_decks
            WHERE COALESCE(commander, '') != ''
              AND commander NOT LIKE '%Lorehold%'
              AND COALESCE(card_list, '') != ''
              AND length(card_list) >= 500
              AND COALESCE(card_count, 0) >= ?
            ORDER BY
              CASE WHEN source = 'pg_meta_decks' THEN 0 ELSE 1 END,
              COALESCE(card_count, 0) DESC,
              id DESC
            LIMIT ?
            """,
            (min_cards, candidate_limit),
        ).fetchall()
    finally:
        conn.close()

    decks: list[dict[str, Any]] = []
    for row in rows:
        cards = decode_card_list(row["card_list"])
        expanded_count = sum(quantity(card.get("quantity")) for card in cards)
        if expanded_count < min_cards:
            continue
        decks.append(
            {
                "id": row["id"],
                "commander": row["commander"],
                "source": row["source"],
                "archetype": row["archetype"],
                "card_count": row["card_count"],
                "cards": cards,
                "expanded_count": expanded_count,
            }
        )
        if len(decks) >= deck_limit:
            break
    return decks


def resolve_names(names: set[str]) -> tuple[dict[str, str], dict[str, int]]:
    normalized_names = sorted({normalize_card_name(name) for name in names if name})
    if not normalized_names:
        return {}, {}
    resolved: dict[str, str] = {}
    ambiguous: dict[str, int] = {}
    with connect() as conn:
        with conn.cursor() as cur:
            for index in range(0, len(normalized_names), 500):
                chunk = normalized_names[index : index + 500]
                cur.execute(
                    """
                    SELECT id::text, name
                    FROM cards
                    WHERE lower(name) = ANY(%s)
                       OR lower(split_part(name, ' // ', 1)) = ANY(%s)
                    """,
                    (chunk, chunk),
                )
                candidates_by_key: dict[str, list[tuple[str, str, bool]]] = {
                    key: [] for key in chunk
                }
                for card_id, card_name in cur.fetchall():
                    exact_key = normalize_card_name(card_name)
                    front_key = normalize_card_name(str(card_name).split(" // ", 1)[0])
                    if exact_key in candidates_by_key:
                        candidates_by_key[exact_key].append((card_id, card_name, True))
                    if front_key in candidates_by_key and front_key != exact_key:
                        candidates_by_key[front_key].append((card_id, card_name, False))
                for key, candidates in candidates_by_key.items():
                    exact = [(card_id, name) for card_id, name, is_exact in candidates if is_exact]
                    front = [(card_id, name) for card_id, name, is_exact in candidates if not is_exact]
                    if len(exact) == 1:
                        resolved[key] = exact[0][0]
                    elif len(exact) > 1:
                        ambiguous[key] = len(exact)
                    elif len(front) == 1:
                        resolved[key] = front[0][0]
                    elif len(front) > 1:
                        ambiguous[key] = len(front)
    return resolved, ambiguous


def audit(decks: list[dict[str, Any]]) -> dict[str, Any]:
    unique_names = {
        str(card.get("name") or "").strip()
        for deck in decks
        for card in deck["cards"]
        if str(card.get("name") or "").strip()
    }
    resolved, ambiguous = resolve_names(unique_names)
    unresolved_names: Counter[str] = Counter()
    totals = {
        "decks_seen": len(decks),
        "card_instances": 0,
        "resolved_instances": 0,
        "unresolved_instances": 0,
        "ambiguous_instances": 0,
    }
    deck_summaries: list[dict[str, Any]] = []
    for deck in decks:
        deck_total = 0
        deck_resolved = 0
        deck_unresolved = 0
        deck_ambiguous = 0
        for card in deck["cards"]:
            name = str(card.get("name") or "").strip()
            if not name:
                continue
            qty = quantity(card.get("quantity"))
            key = normalize_card_name(name)
            deck_total += qty
            if key in resolved:
                deck_resolved += qty
            elif key in ambiguous:
                deck_ambiguous += qty
            else:
                deck_unresolved += qty
                unresolved_names[name] += qty
        totals["card_instances"] += deck_total
        totals["resolved_instances"] += deck_resolved
        totals["unresolved_instances"] += deck_unresolved
        totals["ambiguous_instances"] += deck_ambiguous
        deck_summaries.append(
            {
                "learned_deck_id": deck["id"],
                "commander": deck["commander"],
                "source": deck["source"],
                "card_instances": deck_total,
                "resolved_instances": deck_resolved,
                "unresolved_instances": deck_unresolved,
                "ambiguous_instances": deck_ambiguous,
            }
        )

    coverage = (
        totals["resolved_instances"] / totals["card_instances"]
        if totals["card_instances"]
        else 0.0
    )
    return {
        "database_target": sanitized_database_target(),
        "decks_seen": totals["decks_seen"],
        "card_instances": totals["card_instances"],
        "resolved_instances": totals["resolved_instances"],
        "unresolved_instances": totals["unresolved_instances"],
        "ambiguous_instances": totals["ambiguous_instances"],
        "resolution_coverage": round(coverage, 6),
        "unique_names": len(unique_names),
        "resolved_unique_names": len(resolved),
        "ambiguous_unique_names": len(ambiguous),
        "unresolved_top": unresolved_names.most_common(20),
        "decks": deck_summaries,
        "apply": False,
    }


def main() -> int:
    args = parse_args()
    decks = load_learned_rows(
        args.sqlite_db,
        candidate_limit=args.candidate_limit,
        deck_limit=args.deck_limit,
        min_cards=args.min_cards,
    )
    summary = audit(decks)
    payload = json.dumps(summary, ensure_ascii=True, indent=2, sort_keys=True) + "\n"
    if args.report:
        Path(args.report).parent.mkdir(parents=True, exist_ok=True)
        Path(args.report).write_text(payload, encoding="utf-8")
    print("LEARNED_OPPONENT_CARD_IDENTITY_AUDIT " + json.dumps(summary, ensure_ascii=True, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
