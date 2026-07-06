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
                    "Protected Payoff",
                    1,
                    "engine",
                    '["engine"]',
                    "test",
                    0,
                    0,
                    6,
                    "Creature - Demon",
                    "Flying.",
                    "protected",
                    "[]",
                    "[]",
                    "seed",
                    "old",
                    "old",
                    "old",
                ),
                (
                    619,
                    "Smuggler's Share",
                    1,
                    "card_draw_selection",
                    '["card_draw_selection"]',
                    "test",
                    0,
                    0,
                    3,
                    "Enchantment",
                    "Whenever an opponent draws their second card each turn, you draw a card.",
                    "smugglers-share",
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
                    96,
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
        conn.execute(
            """
            INSERT INTO card_oracle_cache VALUES (
              'Arena of Glory',
              'arena of glory',
              '',
              '[]',
              '["R"]',
              'Land',
              'Arena of Glory enters the battlefield tapped unless you control a Mountain.',
              0,
              'scryfall-arena',
              'arena'
            )
            """
        )
        conn.execute(
            """
            INSERT INTO card_oracle_cache VALUES (
              'Ash Barrens',
              'ash barrens',
              '',
              '[]',
              '[]',
              'Land',
              '{T}: Add {C}. Basic landcycling {1}.',
              0,
              'scryfall-ash',
              'ash'
            )
            """
        )
        conn.execute(
            """
            INSERT INTO card_oracle_cache VALUES (
              'Despark',
              'despark',
              '{W}{B}',
              '["W", "B"]',
              '["W", "B"]',
              'Instant',
              'Exile target permanent with mana value 4 or greater.',
              2,
              'scryfall-despark',
              'despark'
            )
            """
        )
        conn.commit()
        conn.close()
        return tmp, path

    def _pair_report(self, tmp: tempfile.TemporaryDirectory, source_db: Path) -> Path:
        path = Path(tmp.name) / "pair_report.json"
        path.write_text(
            json.dumps(
                {
                    "source_db": str(source_db.resolve()),
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
                            "blocked_cut_candidates": [
                                {
                                    "card_name": "Protected Payoff",
                                    "status": "blocked_commander_specific_payoff_cut",
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
        pair_report = self._pair_report(tmp, source_db)
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
        self.assertTrue(payload["summary"]["source_matches_pair_report"])
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

    def test_blocks_chained_source_db_by_default(self) -> None:
        tmp, source_db = self._db()
        self.addCleanup(tmp.cleanup)
        pair_report = self._pair_report(tmp, source_db)
        chained_source = Path(tmp.name) / "chained.db"
        chained_source.write_bytes(source_db.read_bytes())

        with self.assertRaisesRegex(RuntimeError, "source DB does not match pair report source_db"):
            audit.build_payload(
                source_db=chained_source,
                pair_report=pair_report,
                out_prefix=Path(tmp.name) / "out",
                deck_id="619",
            )

    def test_blocks_source_missing_protected_cut_candidate(self) -> None:
        tmp, source_db = self._db()
        self.addCleanup(tmp.cleanup)
        pair_report = self._pair_report(tmp, source_db)
        conn = sqlite3.connect(source_db)
        conn.execute("DELETE FROM deck_cards WHERE card_name='Protected Payoff'")
        conn.commit()
        conn.close()

        with self.assertRaisesRegex(RuntimeError, "protected blocked cut cards are absent"):
            audit.build_payload(
                source_db=source_db,
                pair_report=pair_report,
                out_prefix=Path(tmp.name) / "out",
                deck_id="619",
            )

    def test_materializes_value_safe_stage_pairs_only_in_candidate_copy(self) -> None:
        tmp, source_db = self._db()
        self.addCleanup(tmp.cleanup)
        cut_report = Path(tmp.name) / "cut_report.json"
        cut_report.write_text(
            json.dumps(
                {
                    "input_artifacts": {"selected_db": str(source_db.resolve())},
                    "blocked_cut_candidates": [
                        {
                            "card_name": "Protected Payoff",
                            "status": "blocked_commander_specific_payoff_cut",
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        stage_report = Path(tmp.name) / "stage_report.json"
        stage_report.write_text(
            json.dumps(
                {
                    "artifact_type": "global_commander_value_safe_stage_splitter",
                    "summary": {
                        "deck_id": "619",
                        "commander": "Kaalia of the Vast",
                    },
                    "input_artifacts": {
                        "cut_source_lane_report": str(cut_report),
                    },
                    "stages": [
                        {
                            "stage": 1,
                            "status": "stage_ready_for_candidate_copy",
                            "candidate_copy_allowed_now": True,
                            "next_gate": "materialize_value_safe_stage_1_candidate_copy",
                            "pairs": [
                                {
                                    "add": "Arena of Glory",
                                    "cut": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                                    "add_axis": "commander_attack_window",
                                    "cut_primary_role": "engine",
                                },
                                {
                                    "add": "Despark",
                                    "cut": "Smuggler's Share",
                                    "add_axis": "spot_interaction",
                                    "cut_primary_role": "card_draw_selection",
                                },
                            ],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )

        payload = audit.build_payload(
            source_db=source_db,
            pair_report=stage_report,
            out_prefix=Path(tmp.name) / "out",
            deck_id="619",
            stage=1,
        )

        candidate_db = Path(payload["candidate_db"])
        self.assertEqual(payload["status"], "candidate_materialized_structure_ready_next_gate_closed")
        self.assertTrue(payload["summary"]["source_unchanged"])
        self.assertEqual(payload["summary"]["pair_count"], 2)
        self.assertEqual(payload["summary"]["stage"], 1)
        self.assertEqual(payload["structure_validation"]["status"], "pass")
        self.assertTrue(payload["structure_validation"]["checks"]["all_adds_present_once"])
        self.assertTrue(payload["structure_validation"]["checks"]["all_cuts_absent"])

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
        self.assertIn("Smuggler's Share", source_names)
        self.assertNotIn("Arena of Glory", source_names)
        self.assertNotIn("Despark", source_names)
        self.assertIn("Arena of Glory", candidate_names)
        self.assertIn("Despark", candidate_names)
        self.assertNotIn("Birgi, God of Storytelling // Harnfel, Horn of Bounty", candidate_names)
        self.assertNotIn("Smuggler's Share", candidate_names)

    def test_materializes_reduced_scope_pairs_only_in_candidate_copy(self) -> None:
        tmp, source_db = self._db()
        self.addCleanup(tmp.cleanup)
        scope_report = Path(tmp.name) / "scope_report.json"
        scope_report.write_text(
            json.dumps(
                {
                    "artifact_type": "global_commander_package_scope_reducer",
                    "status": "commander_package_scope_reduced_ready_for_candidate_copy",
                    "reduced_scope_candidate_copy_allowed_now": True,
                    "full_package_candidate_copy_allowed_now": False,
                    "source_db": str(source_db.resolve()),
                    "summary": {
                        "deck_id": "619",
                        "commander": "Kaalia of the Vast",
                        "next_gate": "materialize_reduced_scope_candidate_copy",
                    },
                    "scoped_pairs": [
                        {
                            "pair_index": 1,
                            "add": "Despark",
                            "cut": "Smuggler's Share",
                            "add_axis": "spot_interaction",
                            "add_covered_axes": ["spot_interaction"],
                            "add_score": 88,
                            "cut_primary_role": "card_draw_selection",
                            "cut_matching_over_target_roles": ["card_draw_selection"],
                            "cut_score": 41,
                            "status": "review_only_reduced_scope_pair",
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )

        payload = audit.build_payload(
            source_db=source_db,
            pair_report=scope_report,
            out_prefix=Path(tmp.name) / "out",
            deck_id="619",
        )

        candidate_db = Path(payload["candidate_db"])
        self.assertEqual(payload["status"], "candidate_materialized_structure_ready_next_gate_closed")
        self.assertTrue(payload["summary"]["source_unchanged"])
        self.assertEqual(payload["summary"]["pair_count"], 1)
        self.assertEqual(payload["summary"]["source_artifact_type"], "global_commander_package_scope_reducer")
        self.assertEqual(payload["summary"]["stage_next_gate"], "materialize_reduced_scope_candidate_copy")
        self.assertEqual(payload["model_pairs"][0]["role"], "spot_interaction")
        self.assertEqual(payload["structure_validation"]["status"], "pass")

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
        self.assertIn("Smuggler's Share", source_names)
        self.assertNotIn("Despark", source_names)
        self.assertIn("Despark", candidate_names)
        self.assertNotIn("Smuggler's Share", candidate_names)

    def test_materializes_land_floor_package_pairs_only_in_candidate_copy(self) -> None:
        tmp, source_db = self._db()
        self.addCleanup(tmp.cleanup)
        package_report = Path(tmp.name) / "land_floor_package.json"
        package_report.write_text(
            json.dumps(
                {
                    "artifact_type": "global_commander_land_floor_package_synthesizer",
                    "status": "land_floor_package_synthesized_candidate_copy_ready",
                    "candidate_copy_allowed_now": True,
                    "source_db": str(source_db.resolve()),
                    "summary": {
                        "deck_id": "619",
                        "commander": "Kaalia of the Vast",
                        "deck_name": "Kaalia Variant",
                        "next_gate": "materialize_land_floor_package_candidate_copy",
                    },
                    "pairs": [
                        {
                            "add": "Arena of Glory",
                            "cut": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                            "role": "land",
                        },
                        {
                            "add": "Ash Barrens",
                            "cut": "Smuggler's Share",
                            "role": "land",
                        },
                    ],
                }
            ),
            encoding="utf-8",
        )

        payload = audit.build_payload(
            source_db=source_db,
            pair_report=package_report,
            out_prefix=Path(tmp.name) / "out",
            deck_id="619",
        )

        candidate_db = Path(payload["candidate_db"])
        self.assertEqual(payload["status"], "candidate_materialized_structure_ready_next_gate_closed")
        self.assertTrue(payload["summary"]["source_unchanged"])
        self.assertEqual(payload["summary"]["pair_count"], 2)
        self.assertEqual(payload["summary"]["source_artifact_type"], "global_commander_land_floor_package_synthesizer")
        self.assertEqual(payload["summary"]["stage_next_gate"], "materialize_land_floor_package_candidate_copy")
        self.assertEqual([row["role"] for row in payload["model_pairs"]], ["land", "land"])
        self.assertEqual(payload["structure_validation"]["status"], "pass")

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
        self.assertIn("Smuggler's Share", source_names)
        self.assertNotIn("Arena of Glory", source_names)
        self.assertNotIn("Ash Barrens", source_names)
        self.assertIn("Arena of Glory", candidate_names)
        self.assertIn("Ash Barrens", candidate_names)
        self.assertNotIn("Birgi, God of Storytelling // Harnfel, Horn of Bounty", candidate_names)
        self.assertNotIn("Smuggler's Share", candidate_names)

    def test_materializes_profile_repair_land_cut_review_pairs_only_in_candidate_copy(self) -> None:
        tmp, source_db = self._db()
        self.addCleanup(tmp.cleanup)
        review_report = Path(tmp.name) / "profile_repair_land_cut_review.json"
        review_report.write_text(
            json.dumps(
                {
                    "artifact_type": "global_commander_profile_repair_land_cut_reviewer",
                    "status": "profile_repair_land_cut_review_ready_for_candidate_copy",
                    "candidate_copy_allowed_now": True,
                    "source_db": str(source_db.resolve()),
                    "summary": {
                        "deck_id": "619",
                        "commander": "Kaalia of the Vast",
                        "next_gate": "materialize_profile_repair_candidate_copy",
                    },
                    "materialization_pairs": [
                        {
                            "add": "Arena of Glory",
                            "cut": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                            "role": "land",
                        },
                        {
                            "add": "Despark",
                            "cut": "Smuggler's Share",
                            "role": "spot_interaction",
                        },
                    ],
                }
            ),
            encoding="utf-8",
        )

        payload = audit.build_payload(
            source_db=source_db,
            pair_report=review_report,
            out_prefix=Path(tmp.name) / "out",
            deck_id="619",
        )

        candidate_db = Path(payload["candidate_db"])
        self.assertEqual(payload["status"], "candidate_materialized_structure_ready_next_gate_closed")
        self.assertTrue(payload["summary"]["source_unchanged"])
        self.assertEqual(payload["summary"]["pair_count"], 2)
        self.assertEqual(
            payload["summary"]["source_artifact_type"],
            "global_commander_profile_repair_land_cut_reviewer",
        )
        self.assertEqual(payload["summary"]["stage_next_gate"], "materialize_profile_repair_candidate_copy")
        self.assertEqual([row["role"] for row in payload["model_pairs"]], ["land", "spot_interaction"])
        self.assertEqual(payload["structure_validation"]["status"], "pass")

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
        self.assertIn("Smuggler's Share", source_names)
        self.assertNotIn("Arena of Glory", source_names)
        self.assertNotIn("Despark", source_names)
        self.assertIn("Arena of Glory", candidate_names)
        self.assertIn("Despark", candidate_names)
        self.assertNotIn("Birgi, God of Storytelling // Harnfel, Horn of Bounty", candidate_names)
        self.assertNotIn("Smuggler's Share", candidate_names)


if __name__ == "__main__":
    unittest.main()
