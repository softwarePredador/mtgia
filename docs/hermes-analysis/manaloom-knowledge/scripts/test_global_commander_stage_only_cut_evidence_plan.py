#!/usr/bin/env python3
"""Tests for Commander stage-only cut evidence planning."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_stage_only_cut_evidence_plan as planner


def stage_cut(name: str, reasons: list[str], score: int = 50) -> dict[str, object]:
    return {
        "card_name": name,
        "score": score,
        "matching_over_target_roles": ["mana_acceleration"],
        "stage_reasons": reasons,
        "status": "stage_only_commander_cut_source_candidate",
    }


class GlobalCommanderStageOnlyCutEvidencePlanTests(unittest.TestCase):
    def _json(self, root: Path, payload: dict[str, object]) -> Path:
        path = root / "cut_report.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_prioritizes_contextual_stage_review_before_structural_staples(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        report = self._json(
            Path(tmp.name),
            {
                "status": "commander_cut_source_lane_still_blocks_full_package",
                "summary": {
                    "deck_id": "619",
                    "commander": "Kaalia of the Vast",
                    "required_cut_count": 6,
                    "value_safe_cut_count": 0,
                    "blocked_cut_count": 10,
                },
                "stage_only_cut_candidates": [
                    stage_cut(
                        "Dark Ritual",
                        ["structural_foundation_staple_requires_same_lane_or_battle_proof"],
                        80,
                    ),
                    stage_cut(
                        "Professional Face-Breaker",
                        ["contextual_staple_requires_stage_review"],
                        60,
                    ),
                    stage_cut(
                        "Sunforger",
                        ["attack_window_cut_requires_same_lane_stage_proof"],
                        70,
                    ),
                ],
            },
        )

        payload = planner.build_report(cut_source_lane_report=report)

        self.assertEqual(payload["status"], "stage_only_cut_evidence_plan_ready")
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertEqual(payload["summary"]["stage_only_cut_count"], 3)
        self.assertEqual(payload["evidence_plan_rows"][0]["card_name"], "Professional Face-Breaker")
        self.assertEqual(payload["evidence_plan_rows"][0]["maximum_evidence_burden"], 1)
        self.assertIn(
            "contextual_staple_same_lane_usage_review",
            payload["evidence_plan_rows"][0]["evidence_lanes"],
        )

    def test_blocks_when_no_stage_only_rows_exist(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        report = self._json(
            Path(tmp.name),
            {
                "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
                "stage_only_cut_candidates": [],
            },
        )

        payload = planner.build_report(cut_source_lane_report=report)

        self.assertEqual(payload["status"], "stage_only_cut_evidence_plan_blocks_no_stage_only_rows")
        self.assertEqual(payload["summary"]["next_gate"], "find_new_cut_source_lane_before_package_materialization")
        self.assertIn("no_stage_only_cut_rows_to_backfill", payload["candidate_copy_blockers"])


if __name__ == "__main__":
    unittest.main()
