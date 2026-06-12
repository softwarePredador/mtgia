#!/usr/bin/env python3
"""Tests for learned-opponent card identity audit."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import audit_learned_opponent_card_identity as audit


class LearnedOpponentCardIdentityAuditTests(unittest.TestCase):
    def test_decode_plain_text_decklist(self) -> None:
        cards = audit.decode_card_list(
            """
            Commander
            1 Sol Ring
            2x Island (ABC) 123
            Sideboard
            SB: 1 Counterspell
            """
        )

        self.assertEqual(
            cards,
            [
                {"name": "Sol Ring", "quantity": 1},
                {"name": "Island", "quantity": 2},
                {"name": "Counterspell", "quantity": 1},
            ],
        )

    def test_load_rows_and_audit_coverage_without_pg_writes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            conn = sqlite3.connect(db_path)
            conn.execute(
                """
                CREATE TABLE learned_decks (
                    id INTEGER PRIMARY KEY,
                    commander TEXT,
                    source TEXT,
                    archetype TEXT,
                    card_count INTEGER,
                    card_list TEXT
                )
                """
            )
            cards = [
                *({"name": "Sol Ring", "quantity": 1} for _ in range(2)),
                {"name": "Mystery Missing", "quantity": 1},
                {"name": "Ambiguous Front", "quantity": 1},
                *({"name": f"Padding Card {index}", "quantity": 1} for index in range(40)),
            ]
            conn.execute(
                """
                INSERT INTO learned_decks (
                    id, commander, source, archetype, card_count, card_list
                ) VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    101,
                    "Ral, Monsoon Mage",
                    "pg_meta_decks",
                    "spells",
                    len(cards),
                    json.dumps(cards),
                ),
            )
            conn.commit()
            conn.close()

            rows = audit.load_learned_rows(
                db_path,
                candidate_limit=10,
                deck_limit=10,
                min_cards=1,
            )

        self.assertEqual(len(rows), 1)
        with mock.patch.object(
            audit,
            "resolve_names",
            return_value=(
                {"sol ring": "card-id-sol-ring"},
                {"ambiguous front": 2},
            ),
        ), mock.patch.object(
            audit,
            "sanitized_database_target",
            return_value="db-host/db-name",
        ):
            summary = audit.audit(rows)

        self.assertFalse(summary["apply"])
        self.assertEqual(summary["decks_seen"], 1)
        self.assertEqual(summary["card_instances"], 44)
        self.assertEqual(summary["resolved_instances"], 2)
        self.assertEqual(summary["unresolved_instances"], 41)
        self.assertEqual(summary["ambiguous_instances"], 1)
        self.assertEqual(summary["resolution_coverage"], round(2 / 44, 6))
        self.assertIn(("Mystery Missing", 1), summary["unresolved_top"])


if __name__ == "__main__":
    unittest.main()
