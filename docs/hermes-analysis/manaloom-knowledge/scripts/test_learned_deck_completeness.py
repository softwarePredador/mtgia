#!/usr/bin/env python3
"""Tests for Hermes learned deck completeness guards."""

from __future__ import annotations

import argparse
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

from learned_deck_completeness import learned_deck_completeness
from materialize_learned_deck_to_deck_cards import materialize


class LearnedDeckCompletenessTests(unittest.TestCase):
    def test_main_deck_plus_commander_column_counts_as_full_commander_deck(self) -> None:
        card_list = "\n".join(f"1 Main Card {index}" for index in range(99))

        summary = learned_deck_completeness(
            card_list,
            commander="Lorehold, the Historian",
            declared_quantity=99,
        )

        self.assertEqual(summary.parsed_quantity, 99)
        self.assertEqual(summary.total_with_commander, 100)
        self.assertEqual(summary.main_quantity, 99)
        self.assertTrue(summary.is_full_commander_deck())

    def test_partial_seed_is_not_training_eligible(self) -> None:
        card_list = "\n".join(f"1 Seed Card {index}" for index in range(12))

        summary = learned_deck_completeness(
            card_list,
            commander="Kinnan, Bonder Prodigy",
            declared_quantity=12,
        )

        self.assertEqual(summary.total_with_commander, 13)
        self.assertFalse(summary.eligible_for_training(min_total=90))
        self.assertFalse(summary.is_full_commander_deck())

    def test_materialize_refuses_to_fill_partial_decks_by_default(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            self._create_learned_db(
                db_path,
                card_list=json.dumps(
                    [{"name": f"Seed Card {index}", "quantity": 1} for index in range(10)]
                ),
                card_count=10,
            )

            with self.assertRaises(SystemExit) as err:
                materialize(
                    argparse.Namespace(
                        sqlite_db=str(db_path),
                        learned_deck_id=82,
                        target_deck_id=None,
                        min_cards=100,
                        fill_basic="Mountain",
                        allow_fill_basic=False,
                        apply=False,
                    )
                )

            self.assertIn("learned deck is partial", str(err.exception))

    def test_materialize_accepts_full_main_deck_without_basic_fill(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            self._create_learned_db(
                db_path,
                card_list=json.dumps(
                    [{"name": f"Main Card {index}", "quantity": 1} for index in range(99)]
                ),
                card_count=99,
            )

            summary = materialize(
                argparse.Namespace(
                    sqlite_db=str(db_path),
                    learned_deck_id=82,
                    target_deck_id=None,
                    min_cards=100,
                    fill_basic="Mountain",
                    allow_fill_basic=False,
                    apply=False,
                )
            )

            self.assertEqual(summary["quantity"], 100)
            self.assertEqual(summary["filled_basic"], 0)
            self.assertEqual(summary["source_total_with_commander"], 100)

    def _create_learned_db(
        self,
        db_path: Path,
        *,
        card_list: str,
        card_count: int,
    ) -> None:
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
            INSERT INTO learned_decks (id, commander, deck_name, card_list, card_count)
            VALUES (82, 'Lorehold, the Historian', 'Fixture Learned Deck', ?, ?)
            """,
            (card_list, card_count),
        )
        conn.commit()
        conn.close()


if __name__ == "__main__":
    unittest.main()
