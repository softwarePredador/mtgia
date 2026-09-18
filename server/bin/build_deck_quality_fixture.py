#!/usr/bin/env python3
"""Freeze real Commander decks into a deterministic deck-quality fixture.

The deck-quality harness must run with no network, no LLM and no database.
This script is the ONLY step that touches an external data source: it reads
the local Hermes/ManaLoom SQLite cache once and writes a self-contained JSON
fixture. After that the harness depends solely on the committed fixture.

Source of truth note: the SQLite cache is a laboratory mirror, never product
truth. Freezing it here is deliberate -- it converts a live dependency into a
committed, reviewable artifact.

Determinism: rows are sorted, no timestamps are emitted, and the payload
carries a SHA-256 digest of the extracted content so regeneration drift is
detectable.

Usage:
  python3 server/bin/build_deck_quality_fixture.py --check
  python3 server/bin/build_deck_quality_fixture.py --apply
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
import sys
from pathlib import Path

SCHEMA_VERSION = "deck_quality_fixture_v1"

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DB = (
    REPO_ROOT
    / "docs"
    / "hermes-analysis"
    / "manaloom-knowledge"
    / "scripts"
    / "knowledge.db"
)
DEFAULT_OUT = REPO_ROOT / "server" / "test" / "fixtures" / "deck_quality_fixture.json"

# A Commander deck is exactly 100 cards. Anything else is a seed or a partial
# import and must not silently enter a quality baseline.
REQUIRED_DECK_SIZE = 100

# Mirrors basic_land_utils.isLandTypeLine on the Dart side. Kept in sync
# deliberately: the fixture's land accounting must match how the simulator
# classifies the same card.
_LAND_TYPE_LINE = re.compile(r"(^|[^a-z])land([^a-z]|$)", re.IGNORECASE)


def _is_land_type_line(type_line: str | None) -> bool:
    return bool(_LAND_TYPE_LINE.search(type_line or ""))


def _connect_readonly(db_path: Path) -> sqlite3.Connection:
    if not db_path.exists():
        raise SystemExit(f"source database not found: {db_path}")
    return sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)


def _load_decks(conn: sqlite3.Connection) -> list[dict]:
    deck_rows = conn.execute(
        """
        SELECT d.id, d.deck_name, d.archetype, d.total_cards
        FROM decks d
        WHERE EXISTS (SELECT 1 FROM deck_cards dc WHERE dc.deck_id = d.id)
        ORDER BY d.id
        """
    ).fetchall()

    decks: list[dict] = []
    for deck_id, deck_name, archetype, total_cards in deck_rows:
        card_rows = conn.execute(
            """
            SELECT
              dc.card_name,
              dc.quantity,
              dc.type_line,
              dc.oracle_text,
              dc.cmc,
              dc.is_commander,
              (
                -- Correlated subquery, NOT a join: card_oracle_cache holds
                -- case-insensitive duplicate names (double-faced cards,
                -- accented names), so a LEFT JOIN fans out and inflates deck
                -- size. LIMIT 1 with a total ordering keeps one deterministic
                -- row per card.
                SELECT o.mana_cost
                FROM card_oracle_cache o
                WHERE LOWER(o.name) = LOWER(dc.card_name)
                  AND o.mana_cost IS NOT NULL
                  AND o.mana_cost <> ''
                ORDER BY o.mana_cost, o.normalized_name
                LIMIT 1
              ) AS mana_cost
            FROM deck_cards dc
            WHERE dc.deck_id = ?
            ORDER BY LOWER(dc.card_name), dc.id
            """,
            (deck_id,),
        ).fetchall()

        cards: list[dict] = []
        commander = None
        quantity_total = 0
        nonland_rows = 0
        nonland_with_mana_cost = 0
        for name, quantity, type_line, oracle_text, cmc, is_commander, mana_cost in card_rows:
            qty = int(quantity or 0)
            if qty <= 0:
                continue
            quantity_total += qty
            # Lands legitimately have no mana cost, so counting them would
            # understate coverage. Only non-lands are a meaningful denominator.
            if not _is_land_type_line(type_line):
                nonland_rows += 1
                if mana_cost:
                    nonland_with_mana_cost += 1
            if is_commander and commander is None:
                commander = name

            card: dict = {
                "name": name,
                "quantity": qty,
                "type_line": type_line or "",
                "oracle_text": oracle_text or "",
            }
            # Only emit cmc/mana_cost when present. safeCmcForOptimization
            # prefers `cmc` and falls back to parsing `mana_cost`; emitting
            # nulls would be indistinguishable from a genuine zero.
            if cmc is not None:
                card["cmc"] = int(cmc)
            if mana_cost:
                card["mana_cost"] = mana_cost
            cards.append(card)

        if quantity_total != REQUIRED_DECK_SIZE:
            continue

        decks.append(
            {
                "deck_id": int(deck_id),
                "deck_name": deck_name or f"deck:{deck_id}",
                "archetype": archetype or "",
                "commander": commander or "",
                "card_count": quantity_total,
                "distinct_card_rows": len(cards),
                # Colored-mana requirements degrade when mana_cost is absent.
                # Surfacing coverage keeps the baseline honest instead of
                # silently scoring an under-specified deck. Lands are excluded
                # from the denominator: they have no mana cost by definition.
                "nonland_rows": nonland_rows,
                "nonland_mana_cost_coverage": (
                    round(nonland_with_mana_cost / nonland_rows, 4)
                    if nonland_rows
                    else 0.0
                ),
                "cards": cards,
            }
        )

    return decks


def _digest(payload: list[dict]) -> str:
    canonical = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def build_payload(db_path: Path) -> dict:
    conn = _connect_readonly(db_path)
    try:
        decks = _load_decks(conn)
    finally:
        conn.close()

    if not decks:
        raise SystemExit(
            "no complete 100-card deck found; refusing to write an empty fixture"
        )

    return {
        "schema_version": SCHEMA_VERSION,
        "source": "manaloom-knowledge/scripts/knowledge.db",
        "required_deck_size": REQUIRED_DECK_SIZE,
        "deck_count": len(decks),
        "content_digest_sha256": _digest(decks),
        "decks": decks,
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", default=str(DEFAULT_DB), help="source SQLite cache")
    parser.add_argument("--out", default=str(DEFAULT_OUT), help="fixture output path")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--check",
        action="store_true",
        help="report what would be written without touching the fixture",
    )
    mode.add_argument("--apply", action="store_true", help="write the fixture")
    args = parser.parse_args(argv)

    payload = build_payload(Path(args.db))
    out_path = Path(args.out)

    summary = {
        "deck_count": payload["deck_count"],
        "content_digest_sha256": payload["content_digest_sha256"],
        "decks": [
            {
                "deck_id": d["deck_id"],
                "deck_name": d["deck_name"],
                "commander": d["commander"],
                "nonland_mana_cost_coverage": d["nonland_mana_cost_coverage"],
            }
            for d in payload["decks"]
        ],
    }

    if not args.apply:
        existing_digest = None
        if out_path.exists():
            try:
                existing_digest = json.loads(out_path.read_text())["content_digest_sha256"]
            except (ValueError, KeyError):
                existing_digest = "unreadable"
        summary["existing_digest_sha256"] = existing_digest
        summary["would_change"] = existing_digest != payload["content_digest_sha256"]
        print(json.dumps(summary, ensure_ascii=False, indent=2))
        return 0

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    )
    summary["written_to"] = str(out_path.relative_to(REPO_ROOT))
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
