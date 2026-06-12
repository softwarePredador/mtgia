#!/usr/bin/env python3
"""Tests for materializing learned decks into Hermes deck_cards rows."""

from __future__ import annotations

import argparse
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import materialize_learned_deck_to_deck_cards as materializer


class MaterializeLearnedDeckTests(unittest.TestCase):
    def test_materialize_adds_functional_tags_json_to_legacy_deck_cards(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            conn = sqlite3.connect(db_path)
            conn.execute(
                """
                CREATE TABLE learned_decks (
                  id INTEGER PRIMARY KEY,
                  commander TEXT,
                  deck_name TEXT,
                  card_list TEXT,
                  card_count INTEGER
                )
                """
            )
            conn.execute(
                """
                CREATE TABLE card_oracle_cache (
                  normalized_name TEXT PRIMARY KEY,
                  name TEXT,
                  cmc REAL,
                  type_line TEXT,
                  oracle_text TEXT
                )
                """
            )
            conn.execute(
                """
                CREATE TABLE deck_cards (
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
            conn.execute(
                """
                INSERT INTO learned_decks (
                  id, commander, deck_name, card_list, card_count
                ) VALUES (?, ?, ?, ?, ?)
                """,
                (
                    82,
                    "Lorehold, the Historian",
                    "Lorehold Learned Fixture",
                    json.dumps(
                        [
                            {"name": "Sol Ring", "quantity": 1},
                            {"name": "Esper Sentinel", "quantity": 1},
                        ]
                    ),
                    3,
                ),
            )
            conn.executemany(
                """
                INSERT INTO card_oracle_cache (
                  normalized_name, name, cmc, type_line, oracle_text
                ) VALUES (?, ?, ?, ?, ?)
                """,
                [
                    (
                        "lorehold, the historian",
                        "Lorehold, the Historian",
                        5,
                        "Legendary Creature",
                        "Fixture commander.",
                    ),
                    (
                        "sol ring",
                        "Sol Ring",
                        1,
                        "Artifact",
                        "{T}: Add {C}{C}.",
                    ),
                    (
                        "esper sentinel",
                        "Esper Sentinel",
                        1,
                        "Creature",
                        "Whenever an opponent casts their first noncreature spell, "
                        "draw a card unless that player pays {X}.",
                    ),
                ],
            )
            conn.commit()
            conn.close()

            summary = materializer.materialize(
                argparse.Namespace(
                    sqlite_db=str(db_path),
                    learned_deck_id=82,
                    target_deck_id=6,
                    min_cards=3,
                    allow_fill_basic=False,
                    fill_basic="Mountain",
                    apply=True,
                )
            )

            self.assertEqual(summary["quantity"], 3)
            conn = sqlite3.connect(db_path)
            conn.row_factory = sqlite3.Row
            try:
                columns = {
                    str(row[1])
                    for row in conn.execute("PRAGMA table_info(deck_cards)").fetchall()
                }
                rows = conn.execute(
                    """
                    SELECT card_name, functional_tag, functional_tags_json
                    FROM deck_cards
                    WHERE deck_id = 6
                    ORDER BY is_commander DESC, card_name
                    """
                ).fetchall()
            finally:
                conn.close()

            self.assertIn("functional_tags_json", columns)
            self.assertEqual(rows[0]["card_name"], "Lorehold, the Historian")
            self.assertEqual(
                json.loads(rows[0]["functional_tags_json"]),
                ["commander"],
            )
            self.assertEqual(rows[1]["card_name"], "Esper Sentinel")
            self.assertEqual(json.loads(rows[1]["functional_tags_json"]), ["draw"])
            self.assertEqual(rows[2]["card_name"], "Sol Ring")
            self.assertEqual(json.loads(rows[2]["functional_tags_json"]), ["ramp"])


if __name__ == "__main__":
    unittest.main()
