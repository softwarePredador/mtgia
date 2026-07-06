#!/usr/bin/env python3
"""Tests for global engine-axis nonland cut policy model."""

from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_engine_axis_nonland_cut_policy_model as model


def create_db(path: Path) -> None:
    conn = sqlite3.connect(path)
    conn.execute(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            card_name TEXT,
            quantity INTEGER,
            functional_tag TEXT,
            is_commander INTEGER,
            cmc REAL,
            type_line TEXT,
            oracle_text TEXT,
            card_id TEXT
        )
        """
    )
    rows = [
        (
            619,
            "Plain Engine",
            1,
            None,
            0,
            3,
            "Artifact",
            "Whenever you cast a spell, create a token.",
            "plain-engine",
        ),
        (
            619,
            "Kaalia Combat Engine",
            1,
            None,
            0,
            5,
            "Artifact - Equipment",
            "Equipped creature has double strike. Whenever equipped creature attacks, there is an additional combat phase.",
            "kaalia-combat-engine",
        ),
        (
            619,
            "Tutor Engine",
            1,
            None,
            0,
            3,
            "Artifact",
            "When this artifact enters, search your library for a card. Whenever a land enters, draw a card.",
            "tutor-engine",
        ),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", rows)
    conn.commit()
    conn.close()


class GlobalCommanderEngineAxisNonlandCutPolicyModelTests(unittest.TestCase):
    def test_engine_policy_splits_ready_and_protected_cuts(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            create_db(db_path)
            policy_payload = {
                "axis_policy_rows": [
                    {
                        "role": "engine",
                        "source_cycle_blocked_decks": ["619"],
                        "policy_actions": [
                            "treat_engine_as_capacity_ceiling_not_missing_role",
                            "split_engine_cards_by_primary_function_before_cut_selection",
                            "protect_engine_cards_that_also_cover_missing_floor_roles_or_commander_plan",
                            "prefer_engine_only_or_overlapping_excess_role_cards_as_cut_pressure",
                        ],
                    }
                ]
            }
            nonland_payload = {
                "nonland_pools": [
                    {
                        "deck_id": "619",
                        "deck_name": "Kaalia Test",
                        "commander": "Kaalia of the Vast",
                        "role": "removal",
                        "top_candidates": [{"card_name": "Feed the Swarm"}],
                        "top_cut_candidates": [
                            {
                                "card_name": "Plain Engine",
                                "score": 20,
                                "roles": ["engine"],
                                "matching_excess_roles": ["engine"],
                                "classification_source": "text_inferred",
                                "cut_reasons": ["matches_excess_roles:engine"],
                            },
                            {
                                "card_name": "Kaalia Combat Engine",
                                "score": 19,
                                "roles": ["engine"],
                                "matching_excess_roles": ["engine"],
                                "classification_source": "text_inferred",
                                "cut_reasons": ["matches_excess_roles:engine"],
                            },
                            {
                                "card_name": "Tutor Engine",
                                "score": 18,
                                "roles": ["engine", "tutor"],
                                "matching_excess_roles": ["engine", "tutor"],
                                "classification_source": "text_inferred",
                                "cut_reasons": ["matches_excess_roles:engine,tutor"],
                            },
                        ],
                    }
                ]
            }
            core_payload = {
                "decks": [
                    {
                        "deck_id": "619",
                        "core_repair_plan": {
                            "missing_role_slots": [{"role": "removal"}],
                            "excess_role_slots": [{"role": "engine"}, {"role": "tutor"}],
                        },
                    }
                ]
            }

            report = model.build_report(
                role_axis_policy_payload=policy_payload,
                nonland_model_payload=nonland_payload,
                core_role_payload=core_payload,
                sqlite_db=db_path,
            )

        self.assertEqual(report["status"], "engine_axis_nonland_cut_policy_applied_review_only")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["engine_cut_pressure_ready_count"], 2)
        self.assertEqual(report["summary"]["protected_engine_cut_count"], 1)
        self.assertEqual(
            report["summary"]["next_gate"],
            "collect_card_level_usage_and_same_lane_proof_for_engine_policy_cut_pressure",
        )
        pool = report["pool_policy_rows"][0]
        by_name = {row["card_name"]: row for row in pool["policy_cut_rows"]}
        self.assertEqual(by_name["Plain Engine"]["policy_bucket"], "engine_only_excess_cut_pressure")
        self.assertEqual(by_name["Tutor Engine"]["policy_bucket"], "engine_overlap_excess_cut_pressure")
        self.assertEqual(
            by_name["Kaalia Combat Engine"]["policy_status"],
            "engine_axis_policy_blocks_cut_until_source_lane_review",
        )
        self.assertIn("kaalia_attack_window_or_extra_combat", by_name["Kaalia Combat Engine"]["commander_plan_signals"])

    def test_missing_engine_policy_actions_blocks_report(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            create_db(db_path)
            report = model.build_report(
                role_axis_policy_payload={"axis_policy_rows": [{"role": "engine", "policy_actions": []}]},
                nonland_model_payload={"nonland_pools": []},
                core_role_payload={"decks": []},
                sqlite_db=db_path,
            )
        self.assertEqual(
            report["status"],
            "engine_axis_nonland_cut_policy_blocks_missing_policy_actions",
        )


if __name__ == "__main__":
    unittest.main()
