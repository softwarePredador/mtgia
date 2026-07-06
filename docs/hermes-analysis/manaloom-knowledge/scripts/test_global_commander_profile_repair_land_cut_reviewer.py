#!/usr/bin/env python3
"""Tests for profile-repair land-cut role-loss review."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_profile_repair_land_cut_reviewer as reviewer


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def reorder_payload() -> dict[str, object]:
    return {
        "status": "profile_repair_cut_pair_reorder_ready_for_land_curve_review",
        "summary": {"deck_id": "612", "commander": "Lorehold, the Historian"},
        "reordered_pairs": [
            {
                "add": "Bant Panorama",
                "cut": "Storm-Kiln Artist",
                "add_axis": "lands",
                "add_profile_roles": ["lands"],
                "cut_profile_roles": [
                    "mana_acceleration",
                    "mana_rocks_treasure_ramp",
                    "spell_payoffs_copy_engines",
                ],
            },
            {
                "add": "Brokers Hideout",
                "cut": "Jeska's Will",
                "add_axis": "lands",
                "add_profile_roles": ["lands"],
                "cut_profile_roles": [
                    "draw_rummage_opponent_turn_draw",
                    "mana_acceleration",
                    "mana_rocks_treasure_ramp",
                ],
            },
            {
                "add": "Pyromancer's Goggles",
                "cut": "Artist's Talent",
                "add_axis": "protected_profile_anchor",
                "add_profile_roles": [
                    "mana_acceleration",
                    "mana_rocks_treasure_ramp",
                    "spell_payoffs_copy_engines",
                ],
                "cut_profile_roles": [
                    "draw_rummage_opponent_turn_draw",
                    "mana_acceleration",
                    "mana_rocks_treasure_ramp",
                    "spell_payoffs_copy_engines",
                ],
            },
            {
                "add": "Call Forth the Tempest",
                "cut": "Starfall Invocation",
                "add_axis": "protected_profile_anchor",
                "add_profile_roles": ["board_wipes_resets", "miracle_haymakers"],
                "cut_profile_roles": [
                    "board_wipes_resets",
                    "draw_rummage_opponent_turn_draw",
                    "miracle_haymakers",
                ],
            },
            {
                "add": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                "cut": "Brass's Bounty",
                "add_axis": "protected_profile_anchor",
                "add_profile_roles": ["mana_acceleration", "mana_rocks_treasure_ramp"],
                "cut_profile_roles": [
                    "dedicated_win_conditions",
                    "mana_acceleration",
                    "mana_rocks_treasure_ramp",
                    "miracle_haymakers",
                ],
            },
        ],
    }


def strategy_payload(*, ramp_candidate_count: int = 21) -> dict[str, object]:
    return {
        "blocker_reasons": [
            "protected_profile_anchor_cut:Pyromancer's Goggles",
            "protected_profile_anchor_cut:Call Forth the Tempest",
            "protected_profile_anchor_cut:Birgi, God of Storytelling // Harnfel, Horn of Bounty",
        ],
        "candidate_profile_role_counts": {
            "lands": 34,
            "mana_acceleration": ramp_candidate_count,
            "mana_rocks_treasure_ramp": ramp_candidate_count,
            "spell_payoffs_copy_engines": 13,
            "draw_rummage_opponent_turn_draw": 14,
            "board_wipes_resets": 8,
            "miracle_haymakers": 12,
            "dedicated_win_conditions": 14,
        },
        "target_evaluations": [
            {"role": "lands", "candidate_count": 34, "min": 36, "max": 38, "hard_floor": True},
            {
                "role": "mana_rocks_treasure_ramp",
                "candidate_count": ramp_candidate_count,
                "min": 10,
                "max": 13,
                "hard_floor": True,
            },
            {
                "role": "spell_payoffs_copy_engines",
                "candidate_count": 13,
                "min": 5,
                "max": 8,
                "hard_floor": True,
            },
            {
                "role": "draw_rummage_opponent_turn_draw",
                "candidate_count": 14,
                "min": 8,
                "max": 12,
                "hard_floor": True,
            },
            {"role": "board_wipes_resets", "candidate_count": 8, "min": 3, "max": 5, "hard_floor": True},
            {"role": "miracle_haymakers", "candidate_count": 12, "min": 10, "max": 16, "hard_floor": True},
            {
                "role": "dedicated_win_conditions",
                "candidate_count": 14,
                "min": 4,
                "max": 7,
                "hard_floor": True,
            },
        ],
        "candidate_expected_package_presence": {
            "spell_payoff_copy_package": {
                "expected_count": 9,
                "present_count": 2,
                "present_cards": ["Storm-Kiln Artist", "Young Pyromancer"],
                "missing_cards": ["Pyromancer's Goggles"],
            }
        },
    }


def candidate_payload() -> dict[str, object]:
    return {
        "global_cut_review_pool": [
            {"card_name": "Storm-Kiln Artist", "cmc": 4, "core_roles": ["engine", "ramp"]},
            {"card_name": "Jeska's Will", "cmc": 3, "core_roles": ["ramp"]},
        ]
    }


class GlobalCommanderProfileRepairLandCutReviewerTests(unittest.TestCase):
    def test_accepts_land_cuts_when_projected_package_preserves_hard_floors(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = reviewer.build_report(
            cut_pair_reorder_report=write_json(root, "reorder.json", reorder_payload()),
            strategy_matrix_report=write_json(root, "strategy.json", strategy_payload()),
            candidate_model_report=write_json(root, "candidate.json", candidate_payload()),
        )

        self.assertEqual(report["status"], "profile_repair_land_cut_review_ready_for_candidate_copy")
        self.assertTrue(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["ready_land_pair_count"], 2)
        self.assertEqual(report["summary"]["hard_floor_blocker_count"], 0)
        self.assertEqual(report["projected_role_counts"]["lands"], 36)
        self.assertEqual(report["summary"]["next_gate"], "materialize_profile_repair_candidate_copy")

    def test_blocks_land_cut_when_projected_role_falls_below_hard_floor(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = reviewer.build_report(
            cut_pair_reorder_report=write_json(root, "reorder.json", reorder_payload()),
            strategy_matrix_report=write_json(root, "strategy.json", strategy_payload(ramp_candidate_count=11)),
            candidate_model_report=write_json(root, "candidate.json", candidate_payload()),
        )

        self.assertEqual(report["status"], "profile_repair_land_cut_review_blocks_candidate_copy")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertIn(
            "projected_role_below_hard_floor:mana_rocks_treasure_ramp",
            report["candidate_copy_blockers"],
        )
        self.assertEqual(report["summary"]["next_gate"], "expand_land_floor_cut_source_before_candidate_copy")


if __name__ == "__main__":
    unittest.main()
