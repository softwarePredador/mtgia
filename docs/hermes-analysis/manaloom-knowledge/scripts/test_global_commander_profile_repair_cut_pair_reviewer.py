#!/usr/bin/env python3
"""Tests for Commander profile-repair cut-pair review."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_profile_repair_cut_pair_reviewer as reviewer


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def package_payload(*, same_lane: bool = False) -> dict[str, object]:
    if same_lane:
        cuts = [
            {
                "card_name": "Jeska's Will",
                "profile_roles": ["mana_rocks_treasure_ramp"],
            }
        ]
        adds = [
            {
                "card_name": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                "selected_for_axis": "protected_profile_anchor",
                "profile_roles": ["mana_rocks_treasure_ramp"],
            }
        ]
    else:
        adds = [
            {
                "card_name": "Bant Panorama",
                "selected_for_axis": "lands",
                "profile_roles": ["lands"],
            },
            {
                "card_name": "Call Forth the Tempest",
                "selected_for_axis": "protected_profile_anchor",
                "profile_roles": ["miracle_haymakers"],
            },
        ]
        cuts = [
            {
                "card_name": "Artist's Talent",
                "profile_roles": ["spell_payoffs_copy_engines"],
            },
            {
                "card_name": "Storm-Kiln Artist",
                "profile_roles": ["mana_rocks_treasure_ramp"],
            },
        ]
    return {
        "summary": {
            "deck_id": "612",
            "commander": "Lorehold, the Historian",
        },
        "selected_add_package": adds,
        "selected_cut_package": cuts,
    }


class GlobalCommanderProfileRepairCutPairReviewerTests(unittest.TestCase):
    def test_blocks_land_curve_and_cross_lane_protected_anchor_pairs(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = reviewer.build_report(package_resynthesis_report=write_json(root, "package.json", package_payload()))

        self.assertEqual(report["status"], "profile_repair_cut_pair_review_blocks_candidate_copy")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["ready_pair_count"], 0)
        self.assertIn("land_floor_pair_needs_curve_and_role_loss_review", report["candidate_copy_blockers"])
        self.assertIn("protected_anchor_pair_lacks_same_lane_overlap", report["candidate_copy_blockers"])
        self.assertEqual(report["summary"]["next_gate"], "reorder_or_expand_profile_repair_cut_pairs_before_candidate_copy")

    def test_same_lane_protected_anchor_pair_still_keeps_copy_closed_to_later_gate(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = reviewer.build_report(
            package_resynthesis_report=write_json(root, "package.json", package_payload(same_lane=True))
        )

        self.assertEqual(report["status"], "profile_repair_cut_pair_review_ready_for_candidate_copy")
        self.assertEqual(report["summary"]["ready_pair_count"], 1)
        self.assertEqual(report["candidate_copy_blockers"], [])
        self.assertEqual(report["summary"]["next_gate"], "materialize_profile_repair_candidate_copy")
        self.assertFalse(report["battle_gate_allowed_now"])


if __name__ == "__main__":
    unittest.main()
