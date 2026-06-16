#!/usr/bin/env python3
"""Unit tests for Hermes PostgreSQL metadata sync helpers."""

from __future__ import annotations

import json
import os
import sqlite3
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import sync_pg_card_metadata_to_hermes as sync


class SyncPgCardMetadataToHermesTest(unittest.TestCase):
    def setUp(self) -> None:
        self.conn = sqlite3.connect(":memory:")
        self.conn.row_factory = sqlite3.Row
        self.cur = self.conn.cursor()
        sync.ensure_cache_table(self.cur)
        self.cur.execute(
            """
            CREATE TABLE deck_cards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                deck_id INTEGER,
                card_name TEXT,
                quantity INTEGER,
                cmc REAL,
                type_line TEXT,
                oracle_text TEXT
            )
            """
        )

    def tearDown(self) -> None:
        self.conn.close()

    def test_backfill_updates_deck_cards_from_authoritative_cache(self) -> None:
        self.cur.executemany(
            """
            INSERT INTO deck_cards (
                deck_id, card_name, quantity, cmc, type_line, oracle_text
            ) VALUES (1, ?, 1, ?, '', '')
            """,
            [
                ("Sol Ring", 0.0),
                ("Mountain", 0.0),
                ("Unknown Card", 0.0),
            ],
        )
        rows = sync.cache_rows(
            [
                {
                    "name": "Sol Ring",
                    "mana_cost": "{1}",
                    "type_line": "Artifact",
                    "oracle_text": "{T}: Add {C}{C}.",
                    "colors": [],
                    "color_identity": [],
                    "cmc": 1,
                    "power": None,
                    "toughness": None,
                    "keywords": [],
                    "scryfall_id": "00000000-0000-0000-0000-000000000001",
                },
                {
                    "name": "Mountain",
                    "mana_cost": "",
                    "type_line": "Basic Land — Mountain",
                    "oracle_text": "({T}: Add {R}.)",
                    "colors": [],
                    "color_identity": ["R"],
                    "cmc": 0,
                    "power": None,
                    "toughness": None,
                    "keywords": [],
                    "scryfall_id": "00000000-0000-0000-0000-000000000002",
                },
            ]
        )
        sync.write_cache(self.cur, rows)

        report = sync.backfill_deck_cards_from_cache(self.cur, dry_run=False)

        self.assertTrue(report["deck_cards_table_present"])
        self.assertEqual(report["rows_total"], 3)
        self.assertEqual(report["matched_cache_rows"], 2)
        self.assertEqual(report["cmc_rows_updated"], 1)
        self.assertEqual(report["suspicious_nonland_zero_cmc_after"], 0)
        sol_ring = self.cur.execute(
            "SELECT cmc, type_line, oracle_text FROM deck_cards WHERE card_name='Sol Ring'"
        ).fetchone()
        self.assertEqual(sol_ring["cmc"], 1.0)
        self.assertEqual(sol_ring["type_line"], "Artifact")
        self.assertIn("Add {C}{C}", sol_ring["oracle_text"])

    def test_dry_run_reports_without_mutating(self) -> None:
        self.cur.execute(
            """
            INSERT INTO deck_cards (
                deck_id, card_name, quantity, cmc, type_line, oracle_text
            ) VALUES (1, 'Sol Ring', 1, 0, '', '')
            """
        )
        sync.write_cache(
            self.cur,
            sync.cache_rows(
                [
                    {
                        "name": "Sol Ring",
                        "mana_cost": "{1}",
                        "type_line": "Artifact",
                        "oracle_text": "{T}: Add {C}{C}.",
                        "colors": [],
                        "color_identity": [],
                        "cmc": 1,
                        "power": None,
                        "toughness": None,
                        "keywords": [],
                        "scryfall_id": None,
                    }
                ]
            ),
        )

        report = sync.backfill_deck_cards_from_cache(self.cur, dry_run=True)

        self.assertEqual(report["cmc_rows_to_update"], 1)
        self.assertEqual(report["cmc_rows_updated"], 0)
        cmc = self.cur.execute(
            "SELECT cmc FROM deck_cards WHERE card_name='Sol Ring'"
        ).fetchone()[0]
        self.assertEqual(cmc, 0.0)

    def test_absent_deck_cards_table_reports_explicitly(self) -> None:
        conn = sqlite3.connect(":memory:")
        try:
            cur = conn.cursor()
            sync.ensure_cache_table(cur)

            report = sync.backfill_deck_cards_from_cache(cur, dry_run=False)

            self.assertFalse(report["deck_cards_table_present"])
            self.assertEqual(report["rows_total"], 0)
            self.assertEqual(report["cmc_rows_updated"], 0)
        finally:
            conn.close()

    def test_sqlite_path_can_be_bootstrapped_when_absent(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "nested" / "knowledge.db"

            db_path.parent.mkdir(parents=True, exist_ok=True)
            conn = sqlite3.connect(db_path)
            try:
                cur = conn.cursor()
                sync.ensure_cache_table(cur)
                self.assertTrue(
                    sync.table_exists(cur, "card_oracle_cache"),
                )
            finally:
                conn.close()

    def test_collect_requested_names_includes_canonical_snapshot_cards(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            canonical_path = Path(tmp) / "known_cards_canonical_snapshot.json"
            generated_path = Path(tmp) / "known_cards_generated.json"
            canonical_path.write_text(
                json.dumps(
                    {
                        "Canonical Only": {
                            "effect": "counter",
                            "battle_rule_source": "manual",
                            "battle_rule_review_status": "verified",
                            "battle_rule_confidence": 1.0,
                        }
                    }
                ),
                encoding="utf-8",
            )
            generated_path.write_text(
                json.dumps({"Legacy Only": {"effect": "tutor"}}),
                encoding="utf-8",
            )

            with mock.patch.dict(
                os.environ,
                {
                    "MANALOOM_CANONICAL_KNOWN_CARDS_JSON": str(canonical_path),
                    "MANALOOM_KNOWN_CARDS_JSON": str(generated_path),
                },
                clear=False,
            ):
                names = sync.collect_requested_names(self.cur)

        self.assertIn("Canonical Only", names)
        self.assertIn("Legacy Only", names)


if __name__ == "__main__":
    unittest.main()
