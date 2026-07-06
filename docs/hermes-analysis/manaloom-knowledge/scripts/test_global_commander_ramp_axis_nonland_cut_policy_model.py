#!/usr/bin/env python3
"""Tests for global ramp-axis nonland cut policy model."""

from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_ramp_axis_nonland_cut_policy_model as model


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
            "Plain Rock",
            1,
            None,
            0,
            2,
            "Artifact",
            "{T}: Add {R}.",
            "plain-rock",
        ),
        (
            619,
            "Ramp Engine",
            1,
            None,
            0,
            3,
            "Artifact",
            "{T}: Add {R}. Whenever you cast a spell, create a Treasure token.",
            "ramp-engine",
        ),
        (
            619,
            "Kaalia Demon Ramp",
            1,
            None,
            0,
            6,
            "Creature - Demon",
            "Flying. Whenever this creature attacks, create a Treasure token.",
            "kaalia-demon-ramp",
        ),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", rows)
    conn.commit()
    conn.close()


class GlobalCommanderRampAxisNonlandCutPolicyModelTests(unittest.TestCase):
    def test_ramp_policy_splits_ready_and_protected_blocked_cuts(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            create_db(db_path)
            policy_payload = {
                "axis_policy_rows": [
                    {
                        "role": "ramp",
                        "source_cycle_blocked_decks": ["619"],
                        "policy_actions": [
                            "treat_ramp_above_range_as_cut_pressure_not_add_lane",
                            "protect_ramp_cards_that_cover_missing_floor_roles",
                            "block_more_same_deck_source_expansion_until_axis_policy_is_applied",
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
                        "blocked_cut_candidates": [
                            {
                                "card_name": "Plain Rock",
                                "roles": ["ramp"],
                                "classification_source": "text_inferred",
                                "block_reasons": ["cross_lane_ramp_cut_requires_same_lane_source_or_gate"],
                            },
                            {
                                "card_name": "Ramp Engine",
                                "roles": ["ramp", "engine"],
                                "classification_source": "text_inferred",
                                "block_reasons": ["cross_lane_ramp_cut_requires_same_lane_source_or_gate"],
                            },
                            {
                                "card_name": "Kaalia Demon Ramp",
                                "roles": ["ramp"],
                                "classification_source": "text_inferred",
                                "block_reasons": ["kaalia_angel_demon_dragon_payoff_requires_source_lane"],
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
                            "excess_role_slots": [{"role": "ramp"}, {"role": "engine"}],
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

        self.assertEqual(report["status"], "ramp_axis_nonland_cut_policy_applied_review_only")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["ramp_cut_pressure_ready_count"], 2)
        self.assertEqual(report["summary"]["protected_ramp_cut_count"], 1)
        self.assertEqual(
            report["summary"]["next_gate"],
            "collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure",
        )
        pool = report["pool_policy_rows"][0]
        by_name = {row["card_name"]: row for row in pool["policy_cut_rows"]}
        self.assertEqual(by_name["Plain Rock"]["policy_bucket"], "ramp_only_excess_cut_pressure")
        self.assertEqual(by_name["Ramp Engine"]["policy_bucket"], "ramp_overlap_excess_cut_pressure")
        self.assertEqual(
            by_name["Kaalia Demon Ramp"]["policy_status"],
            "ramp_axis_policy_blocks_cut_until_source_lane_review",
        )
        self.assertIn("kaalia_angel_demon_dragon_payoff", by_name["Kaalia Demon Ramp"]["commander_plan_signals"])

    def test_missing_ramp_policy_actions_blocks_report(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            create_db(db_path)
            report = model.build_report(
                role_axis_policy_payload={"axis_policy_rows": [{"role": "ramp", "policy_actions": []}]},
                nonland_model_payload={"nonland_pools": []},
                core_role_payload={"decks": []},
                sqlite_db=db_path,
            )
        self.assertEqual(
            report["status"],
            "ramp_axis_nonland_cut_policy_blocks_missing_policy_actions",
        )


if __name__ == "__main__":
    unittest.main()
