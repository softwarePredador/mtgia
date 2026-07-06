#!/usr/bin/env python3
"""Tests for Commander profile-repair package resynthesis."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_profile_repair_package_resynthesizer as resynthesizer


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def candidate_model_payload(*, cut_count: int = 5) -> dict[str, object]:
    cuts = [
        {
            "card_name": f"Cut {index}",
            "score": 100 - index,
            "status": "review_only_profile_repair_cut_candidate",
            "profile_roles": ["mana_rocks_treasure_ramp"],
            "core_roles": ["ramp"],
            "cut_reasons": ["over_target_mana_rocks_treasure_ramp"],
        }
        for index in range(1, cut_count + 1)
    ]
    return {
        "summary": {
            "deck_id": "612",
            "commander": "Lorehold, the Historian",
        },
        "candidate_copy_blockers": [
            "protected_profile_anchor:Birgi, God of Storytelling // Harnfel, Horn of Bounty:protected_anchor_restore_requires_package_resynthesis",
        ],
        "repair_axis_pools": [
            {
                "repair_axis": "lands",
                "blocker": "profile_lands_below_target",
                "status": "review_only_profile_repair_candidate_pool_ready",
                "shortfall_to_min": 2,
                "top_add_candidates": [
                    {
                        "card_name": "Fabled Passage",
                        "score": 46,
                        "status": "review_only_named_land_candidate",
                        "profile_roles": ["lands"],
                        "fit_reasons": ["fills_land_quantity_gap"],
                    },
                    {
                        "card_name": "Gemstone Mine",
                        "score": 46,
                        "status": "review_only_named_land_candidate",
                        "profile_roles": ["lands"],
                        "fit_reasons": ["fills_land_quantity_gap"],
                    },
                ],
            },
            {
                "repair_axis": "protected_profile_anchor",
                "blocker": "protected_profile_anchor_cut:Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                "status": "protected_anchor_restore_requires_package_resynthesis",
                "shortfall_to_min": 0,
                "top_add_candidates": [
                    {
                        "card_name": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                        "score": 115,
                        "status": "review_only_profile_repair_add_candidate",
                        "profile_roles": ["mana_rocks_treasure_ramp"],
                        "fit_reasons": ["restores_protected_profile_anchor"],
                    }
                ],
            },
        ],
        "global_cut_review_pool": cuts,
    }


class GlobalCommanderProfileRepairPackageResynthesizerTests(unittest.TestCase):
    def test_ready_adds_and_cuts_route_to_cut_pair_review_without_candidate_copy(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = resynthesizer.build_report(
            candidate_model_report=write_json(root, "candidate.json", candidate_model_payload(cut_count=3))
        )

        self.assertEqual(report["status"], "profile_repair_package_resynthesis_ready_for_cut_pair_review")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertEqual(report["summary"]["selected_add_count"], 3)
        self.assertEqual(report["summary"]["selected_cut_count"], 3)
        self.assertEqual(report["summary"]["next_gate"], "review_resynthesized_profile_repair_cut_pairs_before_candidate_copy")
        add_names = [row["card_name"] for row in report["selected_add_package"]]
        self.assertEqual(
            add_names,
            [
                "Fabled Passage",
                "Gemstone Mine",
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            ],
        )
        self.assertEqual(report["candidate_copy_blockers"], ["cut_pair_review_required_before_candidate_copy"])

    def test_insufficient_cut_pool_blocks_resynthesis(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = resynthesizer.build_report(
            candidate_model_report=write_json(root, "candidate.json", candidate_model_payload(cut_count=1))
        )

        self.assertEqual(report["status"], "profile_repair_package_resynthesis_blocks_candidate_copy")
        self.assertIn("cut_pool:insufficient_ready_cuts:1_of_3", report["candidate_copy_blockers"])
        self.assertEqual(report["summary"]["next_gate"], "expand_profile_repair_add_or_cut_source_lane")


if __name__ == "__main__":
    unittest.main()
