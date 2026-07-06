#!/usr/bin/env python3
"""Tests for same-lane used cut recovery routing."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_same_lane_used_cut_recovery_router as router


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def trace_report(root: Path, rows: list[dict[str, object]]) -> Path:
    return write_json(
        root,
        "trace.json",
        {
            "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
            "review_rows": rows,
        },
    )


def package_report(root: Path) -> Path:
    return write_json(
        root,
        "package.json",
        {
            "summary": {
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "selected_add_count": 2,
            },
            "selected_add_package": [
                {
                    "card_name": "Fellwar Stone",
                    "replaces_cut_role": "mana_acceleration",
                    "selected_for_axis": "mana_acceleration_replacement",
                    "score": 120,
                },
                {
                    "card_name": "Gamble",
                    "replaces_cut_role": "tutors_access",
                    "selected_for_axis": "tutors_access_replacement",
                    "score": 110,
                },
            ],
        },
    )


def used_cut(
    name: str,
    role: str,
    *,
    reasons: list[str] | None = None,
    usage: int = 1,
) -> dict[str, object]:
    return {
        "card_name": name,
        "target_cut_role": role,
        "status": "same_lane_stage_cut_usage_trace_blocks_value_safe",
        "usage_event_count": usage,
        "exposure_event_count": 0,
        "decision_trace_count": 0,
        "stage_reasons": reasons or [],
        "evidence_lanes": [],
    }


class GlobalCommanderSameLaneUsedCutRecoveryRouterTests(unittest.TestCase):
    def test_structural_used_cut_routes_to_new_cut_source(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = router.build_report(
            trace_collector_report=trace_report(
                root,
                [
                    used_cut(
                        "Sol Ring",
                        "mana_acceleration",
                        reasons=["structural_foundation_staple_requires_same_lane_or_battle_proof"],
                        usage=7,
                    )
                ],
            ),
            package_source_report=package_report(root),
        )

        self.assertEqual(report["status"], "same_lane_used_cut_recovery_routes_to_new_cut_source")
        self.assertEqual(report["summary"]["strict_recovery_count"], 1)
        self.assertEqual(
            report["used_cut_recovery_rows"][0]["decision"],
            "used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source",
        )
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_used_cut_with_nonstructural_same_lane_route_needs_replacement_proof(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = router.build_report(
            trace_collector_report=trace_report(root, [used_cut("Flexible Tutor", "tutors_access", usage=2)]),
            package_source_report=package_report(root),
        )

        self.assertEqual(report["status"], "same_lane_used_cut_recovery_needs_replacement_proof")
        self.assertEqual(report["summary"]["same_lane_replacement_proof_count"], 1)
        self.assertEqual(report["used_cut_recovery_rows"][0]["route_count"], 1)
        self.assertEqual(report["used_cut_recovery_rows"][0]["same_lane_add_routes"][0]["add_card"], "Gamble")

    def test_no_used_cuts_routes_to_other_stage_cut_review(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = router.build_report(
            trace_collector_report=trace_report(
                root,
                [
                    {
                        "card_name": "Vampiric Tutor",
                        "target_cut_role": "tutors_access",
                        "status": "same_lane_stage_cut_seen_without_usage_needs_negative_review",
                    }
                ],
            ),
            package_source_report=package_report(root),
        )

        self.assertEqual(report["status"], "same_lane_used_cut_recovery_blocks_no_used_cuts")
        self.assertEqual(report["summary"]["used_cut_count"], 0)
        self.assertEqual(report["summary"]["next_gate"], "review_seen_or_external_stage_cuts_before_recovery")


if __name__ == "__main__":
    unittest.main()
