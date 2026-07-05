#!/usr/bin/env python3
"""Tests for Commander value-safe stage splitting."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_value_safe_stage_splitter as splitter


def add(index: int) -> dict[str, object]:
    return {
        "card_name": f"Add {index}",
        "selected_for_axis": "angels_demons_dragons_payoffs",
        "covered_axes": ["angels_demons_dragons_payoffs"],
        "score": 100 - index,
    }


def cut(index: int) -> dict[str, object]:
    return {
        "card_name": f"Cut {index}",
        "primary_cut_role": "mana_acceleration",
        "matching_over_target_roles": ["mana_acceleration"],
        "score": 80 - index,
    }


class GlobalCommanderValueSafeStageSplitterTests(unittest.TestCase):
    def _json(self, root: Path, name: str, payload: dict[str, object]) -> Path:
        path = root / name
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def _reports(self, root: Path, *, adds: int, cuts: int, limit: int) -> tuple[Path, Path]:
        package = self._json(
            root,
            "package.json",
            {
                "summary": {
                    "deck_id": "619",
                    "commander": "Kaalia of the Vast",
                    "package_size_limit": limit,
                },
                "selected_add_package": [add(index) for index in range(1, adds + 1)],
            },
        )
        cut_lane = self._json(
            root,
            "cuts.json",
            {
                "summary": {
                    "deck_id": "619",
                    "commander": "Kaalia of the Vast",
                    "package_size_limit": limit,
                },
                "selected_value_safe_cuts": [cut(index) for index in range(1, cuts + 1)],
            },
        )
        return package, cut_lane

    def test_splits_ready_stages_and_keeps_full_package_blocked_when_adds_unpaired(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        package, cut_lane = self._reports(root, adds=10, cuts=8, limit=4)

        report = splitter.build_report(package_synthesis_report=package, cut_source_lane_report=cut_lane)

        self.assertEqual(report["status"], "commander_value_safe_stage_split_ready_for_stage_candidate_copy")
        self.assertTrue(report["stage_candidate_copy_allowed_now"])
        self.assertFalse(report["full_package_candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertEqual(report["summary"]["stage_count"], 2)
        self.assertEqual([stage["pair_count"] for stage in report["stages"]], [4, 4])
        self.assertEqual(report["summary"]["unpaired_add_count"], 2)
        self.assertIn("full_package_unpaired_adds:required_10_paired_8", report["candidate_copy_blockers"])
        self.assertEqual(report["summary"]["next_gate"], "materialize_value_safe_stage_1_candidate_copy")

    def test_blocks_stage_copy_when_no_value_safe_pairs_exist(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        package, cut_lane = self._reports(root, adds=3, cuts=0, limit=4)

        report = splitter.build_report(package_synthesis_report=package, cut_source_lane_report=cut_lane)

        self.assertEqual(report["status"], "commander_value_safe_stage_split_blocks_candidate_copy")
        self.assertFalse(report["stage_candidate_copy_allowed_now"])
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertIn("no_value_safe_stage_ready", report["candidate_copy_blockers"])
        self.assertEqual(report["summary"]["next_gate"], "backfill_value_safe_cuts_before_stage_copy")


if __name__ == "__main__":
    unittest.main()
