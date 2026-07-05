#!/usr/bin/env python3
"""Tests for global Commander candidate-copy materialization."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_candidate_copy_materializer as audit


class GlobalCommanderCandidateCopyMaterializerTests(unittest.TestCase):
    def _db(self) -> tuple[tempfile.TemporaryDirectory, Path]:
        tmp = tempfile.TemporaryDirectory()
        path = Path(tmp.name) / "knowledge.db"
        conn = sqlite3.connect(path)
        conn.execute(
            """
            CREATE TABLE deck_cards (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              deck_id INTEGER,
              card_name TEXT,
              quantity INTEGER,
              functional_tag TEXT,
              functional_tags_json TEXT,
              tag_confidence TEXT,
              is_commander INTEGER,
              is_partner INTEGER,
              cmc REAL,
              type_line TEXT,
              oracle_text TEXT,
              card_id TEXT,
              semantic_tags_v2_json TEXT,
              battle_rules_json TEXT,
              sync_run_id TEXT,
              deck_hash TEXT,
              semantics_hash TEXT,
              ruleset_hash TEXT
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE card_oracle_cache (
              name TEXT,
              normalized_name TEXT,
              mana_cost TEXT,
              colors_json TEXT,
              color_identity_json TEXT,
              type_line TEXT,
              oracle_text TEXT,
              cmc REAL,
              scryfall_id TEXT,
              card_id TEXT
            )
            """
        )
        conn.executemany(
            """
            INSERT INTO deck_cards (
              deck_id, card_name, quantity, functional_tag, functional_tags_json,
              tag_confidence, is_commander, is_partner, cmc, type_line,
              oracle_text, card_id, semantic_tags_v2_json, battle_rules_json,
              sync_run_id, deck_hash, semantics_hash, ruleset_hash
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    619,
                    "Kaalia of the Vast",
                    1,
                    "engine",
                    '["engine"]',
                    "test",
                    1,
                    0,
                    4,
                    "Legendary Creature",
                    "Flying",
                    "kaalia",
                    "[]",
                    "[]",
                    "seed",
                    "old",
                    "old",
                    "old",
                ),
                (
                    619,
                    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                    1,
                    "engine",
                    '["engine", "ramp"]',
                    "test",
                    0,
                    0,
                    3,
                    "Legendary Creature",
                    "Whenever you cast a spell, add R.",
                    "birgi",
                    "[]",
                    "[]",
                    "seed",
                    "old",
                    "old",
                    "old",
                ),
                (
                    619,
                    "Plains",
                    98,
                    "land",
                    '["land"]',
                    "test",
                    0,
                    0,
                    0,
                    "Basic Land - Plains",
                    "",
                    "plains",
                    "[]",
                    "[]",
                    "seed",
                    "old",
                    "old",
                    "old",
                ),
            ],
        )
        conn.execute(
            """
            INSERT INTO card_oracle_cache VALUES (
              'Feed the Swarm',
              'feed the swarm',
              '{1}{B}',
              '["B"]',
              '["B"]',
              'Sorcery',
              'Destroy target creature or enchantment an opponent controls. You lose life equal to that permanent''s mana value.',
              2,
              'scryfall-feed',
              'feed'
            )
            """
        )
        conn.commit()
        conn.close()
        return tmp, path

    def _pair_report(self, tmp: tempfile.TemporaryDirectory) -> Path:
        path = Path(tmp.name) / "pair_report.json"
        path.write_text(
            json.dumps(
                {
                    "nonland_pools": [
                        {
                            "deck_id": "619",
                            "deck_name": "Kaalia Variant",
                            "commander": "Kaalia of the Vast",
                            "role": "removal",
                            "status": "review_nonland_add_cut_pool_ready",
                            "top_candidates": [
                                {
                                    "card_name": "Feed the Swarm",
                                    "role": "removal",
                                    "source": "format_staples",
                                }
                            ],
                            "top_cut_candidates": [
                                {
                                    "card_name": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                                    "role": "engine",
                                }
                            ],
                            "pair_hypotheses": [
                                {
                                    "add": "Feed the Swarm",
                                    "cut": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                                    "role": "removal",
                                    "status": "review_only_nonland_add_cut_pair",
                                }
                            ],
                        }
                    ]
                }
            ),
            encoding="utf-8",
        )
        return path

    def test_materializes_swap_only_in_candidate_copy(self) -> None:
        tmp, source_db = self._db()
        self.addCleanup(tmp.cleanup)
        pair_report = self._pair_report(tmp)
        out_prefix = Path(tmp.name) / "out"

        payload = audit.build_payload(
            source_db=source_db,
            pair_report=pair_report,
            out_prefix=out_prefix,
            deck_id="619",
        )

        candidate_db = Path(payload["candidate_db"])
        self.assertEqual(payload["status"], "candidate_materialized_structure_ready_next_gate_closed")
        self.assertTrue(candidate_db.exists())
        self.assertTrue(payload["summary"]["source_unchanged"])
        self.assertTrue(payload["summary"]["source_candidate_hash_differs"])
        self.assertEqual(payload["structure_validation"]["status"], "pass")
        self.assertTrue(payload["structure_validation"]["checks"]["total_cards_100"])

        source_conn = sqlite3.connect(source_db)
        candidate_conn = sqlite3.connect(candidate_db)
        self.addCleanup(source_conn.close)
        self.addCleanup(candidate_conn.close)

        source_names = {
            row[0]
            for row in source_conn.execute("SELECT card_name FROM deck_cards WHERE deck_id=619").fetchall()
        }
        candidate_names = {
            row[0]
            for row in candidate_conn.execute("SELECT card_name FROM deck_cards WHERE deck_id=619").fetchall()
        }

        self.assertIn("Birgi, God of Storytelling // Harnfel, Horn of Bounty", source_names)
        self.assertNotIn("Feed the Swarm", source_names)
        self.assertIn("Feed the Swarm", candidate_names)
        self.assertNotIn("Birgi, God of Storytelling // Harnfel, Horn of Bounty", candidate_names)


if __name__ == "__main__":
    unittest.main()
