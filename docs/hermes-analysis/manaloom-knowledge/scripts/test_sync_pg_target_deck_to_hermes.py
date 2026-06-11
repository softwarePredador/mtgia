#!/usr/bin/env python3
"""Unit tests for syncing real ManaLoom target decks into Hermes SQLite."""

from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

import sync_pg_target_deck_to_hermes as sync


class SyncPgTargetDeckToHermesTests(unittest.TestCase):
    def test_write_sqlite_collapses_duplicate_card_names(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"

            stats = sync.write_sqlite(
                str(db_path),
                6,
                {
                    "name": "Runtime Lorehold Learned",
                    "archetype": "midrange",
                    "total_qty": 100,
                    "pg_deck_id": "pg-deck-1",
                },
                [
                    {
                        "name": "Lorehold, the Historian",
                        "quantity": 1,
                        "is_commander": True,
                        "functional_tag": "engine",
                        "rule_review_status": "verified",
                        "cmc": 5,
                        "type_line": "Legendary Creature",
                        "oracle_text": "Fixture commander.",
                    },
                    {
                        "name": "Sol Ring",
                        "quantity": 1,
                        "is_commander": False,
                        "functional_tag": "unknown",
                        "rule_review_status": None,
                        "cmc": 1,
                        "type_line": "Artifact",
                        "oracle_text": "",
                    },
                    {
                        "name": "Sol Ring",
                        "quantity": 1,
                        "is_commander": False,
                        "functional_tag": "ramp",
                        "rule_review_status": "active",
                        "cmc": 1,
                        "type_line": "Artifact",
                        "oracle_text": "{T}: Add {C}{C}.",
                    },
                ],
                apply=True,
            )

            self.assertEqual(stats["cards_seen"], 3)
            self.assertEqual(stats["cards_written"], 2)
            self.assertEqual(stats["duplicate_rows_collapsed"], 1)
            self.assertEqual(stats["quantity_written"], 3)
            self.assertEqual(stats["commanders"], 1)

            conn = sqlite3.connect(db_path)
            conn.row_factory = sqlite3.Row
            try:
                rows = conn.execute(
                    """
                    SELECT card_name, quantity, functional_tag, is_commander
                    FROM deck_cards
                    ORDER BY is_commander DESC, card_name
                    """
                ).fetchall()
            finally:
                conn.close()

            self.assertEqual(len(rows), 2)
            self.assertEqual(rows[0]["card_name"], "Lorehold, the Historian")
            self.assertEqual(rows[0]["is_commander"], 1)
            self.assertEqual(rows[1]["card_name"], "Sol Ring")
            self.assertEqual(rows[1]["quantity"], 2)
            self.assertEqual(rows[1]["functional_tag"], "ramp")


if __name__ == "__main__":
    unittest.main()
