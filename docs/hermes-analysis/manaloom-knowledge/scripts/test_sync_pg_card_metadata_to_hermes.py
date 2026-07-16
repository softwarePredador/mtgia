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
                    "card_id": "11111111-1111-1111-1111-111111111111",
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
                    "card_id": "22222222-2222-2222-2222-222222222222",
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
        self.assertEqual(report["card_id_rows_updated"], 2)
        self.assertEqual(report["cmc_rows_updated"], 1)
        self.assertEqual(report["suspicious_nonland_zero_cmc_after"], 0)
        sol_ring = self.cur.execute(
            "SELECT card_id, cmc, type_line, oracle_text FROM deck_cards WHERE card_name='Sol Ring'"
        ).fetchone()
        self.assertEqual(sol_ring["card_id"], "11111111-1111-1111-1111-111111111111")
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

    def test_suspicious_zero_cmc_treats_lander_as_nonland(self) -> None:
        self.cur.execute(
            """
            INSERT INTO deck_cards (
                deck_id, card_name, quantity, cmc, type_line, oracle_text
            ) VALUES (1, 'Lander Rizzi', 1, 0, '', '')
            """
        )
        sync.write_cache(
            self.cur,
            sync.cache_rows(
                [
                    {
                        "name": "Lander Rizzi",
                        "mana_cost": "{3}",
                        "type_line": "Legendary Artifact Creature — Lander Rogue",
                        "oracle_text": "{T}: Add one mana of any color.",
                        "colors": [],
                        "color_identity": [],
                        "cmc": 0,
                        "power": "3",
                        "toughness": "2",
                        "keywords": [],
                        "scryfall_id": None,
                    }
                ]
            ),
        )

        report = sync.backfill_deck_cards_from_cache(self.cur, dry_run=True)

        self.assertEqual(report["suspicious_nonland_zero_cmc_after"], 1)

    def test_backfill_rehashes_snapshot_after_card_id_canonicalization(self) -> None:
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        try:
            cur = conn.cursor()
            sync.ensure_cache_table(cur)
            cur.executescript(
                """
                CREATE TABLE decks (
                  id INTEGER PRIMARY KEY,
                  deck_name TEXT,
                  total_cards INTEGER,
                  notes TEXT
                );
                CREATE TABLE deck_cards (
                  deck_id INTEGER,
                  card_id TEXT,
                  card_name TEXT,
                  quantity INTEGER,
                  is_commander INTEGER,
                  cmc REAL,
                  type_line TEXT,
                  oracle_text TEXT,
                  functional_tags_json TEXT,
                  semantic_tags_v2_json TEXT,
                  battle_rules_json TEXT,
                  deck_hash TEXT,
                  semantics_hash TEXT,
                  ruleset_hash TEXT,
                  sync_run_id TEXT
                );
                INSERT INTO decks VALUES (
                  6,
                  'Lorehold 607 - Current Champion',
                  1,
                  'sync_pg_target_deck_to_hermes.py pg_deck_id=8938b746-1a9e-46ce-b0d9-c2ec932ddddd'
                );
                INSERT INTO deck_cards VALUES (
                  6,
                  'old-printing-id',
                  'Sol Ring',
                  1,
                  1,
                  0,
                  'Artifact',
                  '{T}: Add {C}{C}.',
                  '["ramp"]',
                  '[]',
                  '[]',
                  '', '', '', 'sync-before'
                );
                """
            )
            snapshot_rows = cur.execute(
                "SELECT * FROM deck_cards WHERE deck_id=6"
            ).fetchall()
            old_hashes = sync.compute_snapshot_hashes(snapshot_rows)
            cur.execute(
                """
                UPDATE deck_cards
                SET deck_hash=?, semantics_hash=?, ruleset_hash=?
                WHERE deck_id=6
                """,
                old_hashes,
            )
            cur.execute(
                """
                UPDATE decks
                SET notes = notes || ' deck_hash=' || ? ||
                            ' semantics_hash=' || ? ||
                            ' ruleset_hash=' || ?
                WHERE id=6
                """,
                old_hashes,
            )
            sync.write_cache(
                cur,
                sync.cache_rows(
                    [
                        {
                            "card_id": "11111111-1111-1111-1111-111111111111",
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

            report = sync.backfill_deck_cards_from_cache(cur, dry_run=False)

            self.assertEqual(report["card_id_rows_updated"], 1)
            self.assertEqual(report["snapshot_decks_drifted"], 1)
            self.assertEqual(report["snapshot_decks_rehashed"], 1)
            self.assertEqual(report["snapshot_rows_rehashed"], 1)
            row = cur.execute(
                "SELECT * FROM deck_cards WHERE deck_id=6"
            ).fetchone()
            self.assertEqual(
                row["card_id"], "11111111-1111-1111-1111-111111111111"
            )
            recomputed = sync.compute_snapshot_hashes([row])
            self.assertEqual(row["deck_hash"], recomputed[0])
            self.assertEqual(row["semantics_hash"], recomputed[1])
            self.assertEqual(row["ruleset_hash"], recomputed[2])
            self.assertNotEqual(row["deck_hash"], old_hashes[0])
            notes = cur.execute(
                "SELECT notes FROM decks WHERE id=6"
            ).fetchone()[0]
            self.assertIn(f"deck_hash={recomputed[0]}", notes)
            self.assertIn("sync_run_id=metadata_", notes)
        finally:
            conn.close()

    def test_rehash_rejects_drift_outside_metadata_changed_decks(self) -> None:
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        try:
            cur = conn.cursor()
            cur.executescript(
                """
                CREATE TABLE decks (
                  id INTEGER PRIMARY KEY,
                  notes TEXT
                );
                CREATE TABLE deck_cards (
                  deck_id INTEGER,
                  card_id TEXT,
                  card_name TEXT,
                  quantity INTEGER,
                  is_commander INTEGER,
                  functional_tags_json TEXT,
                  semantic_tags_v2_json TEXT,
                  battle_rules_json TEXT,
                  deck_hash TEXT,
                  semantics_hash TEXT,
                  ruleset_hash TEXT,
                  sync_run_id TEXT
                );
                INSERT INTO decks VALUES (
                  7,
                  'sync_pg_target_deck_to_hermes.py deck_hash=old semantics_hash=old ruleset_hash=old'
                );
                INSERT INTO deck_cards VALUES (
                  7, 'card-7', 'Original Name', 1, 1,
                  '[]', '[]', '[]', '', '', '', 'sync-before'
                );
                """
            )
            rows = cur.execute(
                "SELECT * FROM deck_cards WHERE deck_id=7"
            ).fetchall()
            original_hashes = sync.compute_snapshot_hashes(rows)
            cur.execute(
                "UPDATE deck_cards SET deck_hash=?, semantics_hash=?, ruleset_hash=? WHERE deck_id=7",
                original_hashes,
            )
            cur.execute(
                "UPDATE deck_cards SET card_name='Tampered Name' WHERE deck_id=7"
            )

            with self.assertRaisesRegex(
                RuntimeError,
                "snapshot_hash_drift_outside_metadata_change:7",
            ):
                sync.refresh_deck_snapshot_hashes(
                    cur,
                    dry_run=False,
                    allowed_rehash_deck_ids={6},
                )

            stored_hash = cur.execute(
                "SELECT deck_hash FROM deck_cards WHERE deck_id=7"
            ).fetchone()[0]
            self.assertEqual(stored_hash, original_hashes[0])
            self.assertNotEqual(
                stored_hash,
                sync.compute_snapshot_hashes(
                    cur.execute(
                        "SELECT * FROM deck_cards WHERE deck_id=7"
                    ).fetchall()
                )[0],
            )
        finally:
            conn.close()

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

    def test_collect_requested_names_includes_canonical_snapshot_not_generated_legacy(self) -> None:
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
        self.assertNotIn("Legacy Only", names)

    def test_collect_requested_names_refreshes_existing_postgres_cache_rows(self) -> None:
        self.cur.execute(
            """
            INSERT INTO card_oracle_cache (
                normalized_name, card_id, name, colors_json, color_identity_json,
                keywords_json, source, updated_at
            ) VALUES ('district guide', NULL, 'District Guide', '[]', '[]', '[]',
                      'postgres_cards', '2026-07-14T00:00:00Z')
            """
        )

        names = sync.collect_requested_names(self.cur)

        self.assertIn("District Guide", names)


if __name__ == "__main__":
    unittest.main()
