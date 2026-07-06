#!/usr/bin/env python3
"""Tests for ramp axis exhaustion routing."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_ramp_axis_exhaustion_router as router


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


class GlobalCommanderRampAxisExhaustionRouterTests(unittest.TestCase):
    def test_routes_to_global_pivot_when_ramp_lane_is_exhausted(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            recovery = write_json(
                root,
                "recovery.json",
                {
                    "deck_id": "619",
                    "commander": "Kaalia of the Vast",
                    "summary": {
                        "blocked_ramp_cut_count": 9,
                        "replacement_exact_ready_count": 0,
                    },
                    "blocked_cut_rows": [{"card_name": "Arcane Signet"}],
                },
            )
            forced = write_json(
                root,
                "forced.json",
                {
                    "deck_id": "619",
                    "commander": "Kaalia of the Vast",
                    "summary": {
                        "focus_card_count": 2,
                        "usage_blocked_count": 2,
                    },
                    "review_rows": [
                        {
                            "card_name": "Pyretic Ritual",
                            "status": "alternative_ramp_cut_forced_access_usage_observed_blocks_cut",
                        }
                    ],
                },
            )

            report = router.build_report(recovery_report=recovery, alternative_forced_report=forced)

        self.assertEqual(report["status"], "ramp_axis_exhausted_requires_global_role_axis_pivot")
        self.assertEqual(report["exhausted_role_axis"], "ramp")
        self.assertTrue(report["summary"]["current_ramp_lane_exhausted"])
        self.assertEqual(
            report["summary"]["next_gate"],
            "return_to_global_role_axis_learning_priority_after_ramp_axis_exhaustion",
        )
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_does_not_mark_exhausted_with_ready_replacement(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            recovery = write_json(
                root,
                "recovery.json",
                {
                    "deck_id": "619",
                    "commander": "Kaalia of the Vast",
                    "summary": {
                        "blocked_ramp_cut_count": 9,
                        "replacement_exact_ready_count": 1,
                    },
                },
            )
            forced = write_json(
                root,
                "forced.json",
                {
                    "summary": {
                        "focus_card_count": 2,
                        "usage_blocked_count": 2,
                    }
                },
            )

            report = router.build_report(recovery_report=recovery, alternative_forced_report=forced)

        self.assertEqual(report["status"], "ramp_axis_exhaustion_not_proven")
        self.assertIsNone(report["exhausted_role_axis"])
        self.assertFalse(report["summary"]["current_ramp_lane_exhausted"])


if __name__ == "__main__":
    unittest.main()
