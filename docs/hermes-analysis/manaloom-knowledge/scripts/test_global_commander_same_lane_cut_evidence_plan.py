#!/usr/bin/env python3
"""Tests for same-lane cut evidence planning."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_same_lane_cut_evidence_plan as planner


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def collector_payload(
    *,
    ready_pair_count: int = 0,
    stage_rows: list[dict[str, object]] | None = None,
    blocked_rows: list[dict[str, object]] | None = None,
) -> dict[str, object]:
    return {
        "status": "same_lane_cut_pair_collection_blocks_candidate_copy",
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "selected_add_count": 2,
            "ready_pair_count": ready_pair_count,
            "unpaired_add_count": 2 - ready_pair_count,
        },
        "stage_only_cut_candidates": stage_rows or [],
        "blocked_cut_candidates": blocked_rows or [],
    }


class GlobalCommanderSameLaneCutEvidencePlanTests(unittest.TestCase):
    def test_plans_evidence_for_stage_only_same_lane_cuts(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report_path = write_json(
            root,
            "collector.json",
            collector_payload(
                stage_rows=[
                    {
                        "card_name": "Smothering Tithe",
                        "target_cut_role": "mana_acceleration",
                        "score": 60,
                        "stage_reasons": [
                            "structural_foundation_staple_requires_same_lane_or_battle_proof"
                        ],
                    },
                    {
                        "card_name": "Hammer of Nazahn",
                        "target_cut_role": "haste_protection_silence",
                        "score": 58,
                        "stage_reasons": [
                            "target_role_is_protected_profile_lane_requires_trace_or_equal_gate"
                        ],
                    },
                ],
                blocked_rows=[
                    {
                        "card_name": "Arena of Glory",
                        "target_cut_role": "haste_protection_silence",
                        "block_reasons": ["land_slot_not_cut_by_nonland_same_lane_pair"],
                    }
                ],
            ),
        )

        report = planner.build_report(cut_pair_report=report_path)

        self.assertEqual(report["status"], "same_lane_cut_evidence_plan_ready_no_deck_action")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["stage_only_cut_evidence_count"], 2)
        self.assertEqual(report["summary"]["hard_blocked_cut_count"], 1)
        lanes = report["summary"]["evidence_lane_counts"]
        self.assertEqual(lanes["structural_staple_same_lane_or_equal_gate_proof"], 1)
        self.assertEqual(lanes["protected_same_lane_usage_trace_or_equal_gate"], 1)
        self.assertEqual(
            report["summary"]["next_gate"],
            "collect_trace_or_external_evidence_for_same_lane_stage_only_cuts",
        )

    def test_ready_pairs_route_to_scope_reducer(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report_path = write_json(root, "collector.json", collector_payload(ready_pair_count=1))

        report = planner.build_report(cut_pair_report=report_path)

        self.assertEqual(report["status"], "same_lane_cut_evidence_plan_ready_pairs_need_scope_reducer")
        self.assertEqual(report["summary"]["next_gate"], "run_same_lane_package_scope_reducer_before_candidate_copy")

    def test_no_stage_only_lane_routes_to_broader_research(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report_path = write_json(root, "collector.json", collector_payload())

        report = planner.build_report(cut_pair_report=report_path)

        self.assertEqual(report["status"], "same_lane_cut_evidence_plan_blocks_no_stage_only_lane")
        self.assertEqual(report["summary"]["next_gate"], "broaden_same_lane_cut_source_research")
        self.assertEqual(report["summary"]["stage_only_cut_evidence_count"], 0)


if __name__ == "__main__":
    unittest.main()
