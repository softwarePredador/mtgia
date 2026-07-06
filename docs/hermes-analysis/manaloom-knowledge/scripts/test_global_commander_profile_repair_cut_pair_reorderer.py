#!/usr/bin/env python3
"""Tests for Commander profile-repair cut-pair reordering."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_profile_repair_cut_pair_reorderer as reorderer


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def package_payload() -> dict[str, object]:
    return {
        "summary": {"deck_id": "612", "commander": "Lorehold, the Historian"},
        "selected_add_package": [
            {"card_name": "Bant Panorama", "selected_for_axis": "lands", "profile_roles": ["lands"]},
            {"card_name": "Brokers Hideout", "selected_for_axis": "lands", "profile_roles": ["lands"]},
            {
                "card_name": "Pyromancer's Goggles",
                "selected_for_axis": "protected_profile_anchor",
                "profile_roles": ["mana_rocks_treasure_ramp", "spell_payoffs_copy_engines"],
            },
            {
                "card_name": "Call Forth the Tempest",
                "selected_for_axis": "protected_profile_anchor",
                "profile_roles": ["board_wipes_resets", "miracle_haymakers"],
            },
            {
                "card_name": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                "selected_for_axis": "protected_profile_anchor",
                "profile_roles": ["mana_rocks_treasure_ramp"],
            },
        ],
    }


def candidate_payload(*, missing_call_lane: bool = False) -> dict[str, object]:
    cuts = [
        {
            "card_name": "Artist's Talent",
            "score": 72,
            "profile_roles": ["mana_rocks_treasure_ramp", "spell_payoffs_copy_engines"],
        },
        {
            "card_name": "Starfall Invocation",
            "score": 55,
            "profile_roles": [] if missing_call_lane else ["board_wipes_resets", "miracle_haymakers"],
        },
        {
            "card_name": "Jeska's Will",
            "score": 53,
            "profile_roles": ["mana_rocks_treasure_ramp"],
        },
        {"card_name": "Land Cut A", "score": 40, "profile_roles": ["draw_rummage_opponent_turn_draw"]},
        {"card_name": "Land Cut B", "score": 39, "profile_roles": ["dedicated_win_conditions"]},
    ]
    return {
        "summary": {"deck_id": "612", "commander": "Lorehold, the Historian"},
        "global_cut_review_pool": cuts,
    }


class GlobalCommanderProfileRepairCutPairReordererTests(unittest.TestCase):
    def test_reorders_protected_anchors_to_same_lane_and_routes_land_review(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = reorderer.build_report(
            package_resynthesis_report=write_json(root, "package.json", package_payload()),
            candidate_model_report=write_json(root, "candidate.json", candidate_payload()),
        )

        self.assertEqual(report["status"], "profile_repair_cut_pair_reorder_ready_for_land_curve_review")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["protected_anchor_ready_pair_count"], 3)
        self.assertEqual(report["summary"]["land_pair_review_count"], 2)
        pair_by_add = {row["add"]: row for row in report["reordered_pairs"]}
        self.assertEqual(pair_by_add["Pyromancer's Goggles"]["cut"], "Artist's Talent")
        self.assertEqual(pair_by_add["Call Forth the Tempest"]["cut"], "Starfall Invocation")
        self.assertEqual(
            pair_by_add["Birgi, God of Storytelling // Harnfel, Horn of Bounty"]["cut"],
            "Jeska's Will",
        )
        self.assertIn(
            "land_floor_pair_needs_curve_and_role_loss_review",
            report["candidate_copy_blockers"],
        )
        self.assertEqual(report["summary"]["next_gate"], "review_land_floor_cut_role_loss_before_candidate_copy")

    def test_blocks_when_protected_anchor_still_has_no_same_lane_cut(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = reorderer.build_report(
            package_resynthesis_report=write_json(root, "package.json", package_payload()),
            candidate_model_report=write_json(root, "candidate.json", candidate_payload(missing_call_lane=True)),
        )

        self.assertEqual(report["status"], "profile_repair_cut_pair_reorder_blocks_candidate_copy")
        call_pair = {row["add"]: row for row in report["reordered_pairs"]}["Call Forth the Tempest"]
        self.assertIn("protected_anchor_pair_lacks_same_lane_overlap", call_pair["blockers"])
        self.assertEqual(report["summary"]["next_gate"], "expand_profile_repair_cut_source_lane_before_candidate_copy")

    def test_nonland_floor_repair_add_uses_over_target_cut_before_land_pairs(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        package = {
            "summary": {"deck_id": "616", "commander": "Lorehold, the Historian"},
            "selected_add_package": [
                {"card_name": "Bant Panorama", "selected_for_axis": "lands", "profile_roles": ["lands"]},
                {"card_name": "Boros Signet", "selected_for_axis": "mana_rocks_treasure_ramp", "profile_roles": ["mana_rocks_treasure_ramp"]},
            ],
        }
        candidate = {
            "summary": {"deck_id": "616", "commander": "Lorehold, the Historian"},
            "global_cut_review_pool": [
                {"card_name": "Worldfire", "score": 80, "profile_roles": ["board_wipes_resets"]},
                {"card_name": "Reckless Endeavor", "score": 30, "profile_roles": ["mana_rocks_treasure_ramp"]},
            ],
        }

        report = reorderer.build_report(
            package_resynthesis_report=write_json(root, "package.json", package),
            candidate_model_report=write_json(root, "candidate.json", candidate),
        )

        pair_by_add = {row["add"]: row for row in report["reordered_pairs"]}
        self.assertEqual(pair_by_add["Boros Signet"]["cut"], "Worldfire")
        self.assertEqual(pair_by_add["Boros Signet"]["status"], "reordered_profile_floor_repair_pair")
        self.assertEqual(pair_by_add["Bant Panorama"]["cut"], "Reckless Endeavor")
        self.assertEqual(report["status"], "profile_repair_cut_pair_reorder_ready_for_land_curve_review")


if __name__ == "__main__":
    unittest.main()
