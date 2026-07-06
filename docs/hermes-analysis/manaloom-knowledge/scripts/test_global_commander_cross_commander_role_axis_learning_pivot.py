#!/usr/bin/env python3
"""Tests for cross-commander role-axis learning pivot."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_cross_commander_role_axis_learning_pivot as pivot


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


class GlobalCommanderCrossCommanderRoleAxisLearningPivotTests(unittest.TestCase):
    def test_source_cycle_prioritizes_role_axis_without_deck_action(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        priority = write_json(
            root,
            "priority.json",
            {
                "deck_priorities": [
                    {
                        "deck_id": "619",
                        "deck_name": "Kaalia Variant",
                        "commander": "Kaalia of the Vast",
                        "stage": "core_floor_repair",
                        "repair_gate_state": "nonland_add_cut_pool_ready_review_only",
                        "source_exhaustion_state": "source_expansion_cycle_requires_global_learning_pivot",
                        "source_exhaustion_prior_blocked_recycled_cut_source_count": 47,
                        "below_floor_roles": ["removal=1 target 6-14"],
                        "above_range_roles": ["ramp=23 target 8-16"],
                        "next_action": "pivot_to_cross_commander_role_axis_learning_before_more_same_deck_source_expansion",
                    },
                    {
                        "deck_id": "609",
                        "deck_name": "Lorehold Variant",
                        "commander": "Lorehold, the Historian",
                        "stage": "core_floor_repair",
                        "repair_gate_state": "land_add_cut_pool_ready_review_only",
                        "source_exhaustion_state": "not_applicable",
                        "below_floor_roles": ["land=30 target 34-39"],
                        "above_range_roles": ["removal=15 target 6-14"],
                        "next_action": "review_top_land_add_cut_pair_then_candidate_copy",
                    },
                    {
                        "deck_id": "607",
                        "deck_name": "Lorehold Benchmark",
                        "commander": "Lorehold, the Historian",
                        "stage": "benchmark_regression_review_only",
                        "repair_gate_state": "not_applicable",
                        "source_exhaustion_state": "not_applicable",
                        "below_floor_roles": [],
                        "above_range_roles": ["removal=15 target 6-14"],
                        "next_action": "keep_as_regression_benchmark_do_not_use_as_global_template",
                    },
                ]
            },
        )

        report = pivot.build_report(priority_report=priority)

        self.assertEqual(report["status"], "cross_commander_role_axis_learning_pivot_ready_no_deck_action")
        self.assertEqual(report["summary"]["top_axis_role"], "removal")
        self.assertEqual(report["summary"]["source_cycle_axis_count"], 2)
        self.assertEqual(report["summary"]["benchmark_only_excluded_from_action_count"], 1)
        self.assertFalse(report["candidate_copy_allowed_now"])
        top = report["axis_rows"][0]
        self.assertEqual(top["status"], "cross_commander_role_axis_blocks_same_deck_source_cycle")
        self.assertEqual(top["source_cycle_blocked_decks"], ["619"])
        self.assertEqual(
            top["next_gate"],
            "build_cross_commander_role_axis_policy_before_more_same_deck_source_expansion",
        )

    def test_parse_role_label_requires_expected_shape(self) -> None:
        self.assertEqual(
            pivot.parse_role_label("land=32 target 34-39"),
            {"role": "land", "count": 32, "min": 34, "max": 39},
        )
        self.assertIsNone(pivot.parse_role_label("not a role label"))

    def test_engine_axis_exhaustion_suppresses_engine_reentry(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        priority = write_json(
            root,
            "priority.json",
            {
                "deck_priorities": [
                    {
                        "deck_id": "619",
                        "deck_name": "Kaalia Variant",
                        "commander": "Kaalia of the Vast",
                        "stage": "core_floor_repair",
                        "repair_gate_state": "nonland_add_cut_pool_ready_review_only",
                        "source_exhaustion_state": "source_expansion_cycle_requires_global_learning_pivot",
                        "engine_axis_pivot_state": "engine_axis_exhausted_requires_global_learning_pivot",
                        "source_exhaustion_prior_blocked_recycled_cut_source_count": 47,
                        "engine_axis_viable_non_biotransference_cut_count": 0,
                        "below_floor_roles": ["removal=1 target 6-14"],
                        "above_range_roles": ["engine=35 target 4-24", "ramp=23 target 8-16"],
                        "next_action": "pivot_to_cross_commander_role_axis_learning_after_engine_axis_exhaustion",
                    },
                    {
                        "deck_id": "620",
                        "deck_name": "Sauron Variant",
                        "commander": "Sauron, the Dark Lord",
                        "stage": "role_extreme_review_then_source_lane",
                        "repair_gate_state": "not_applicable",
                        "source_exhaustion_state": "not_applicable",
                        "engine_axis_pivot_state": "not_applicable",
                        "below_floor_roles": [],
                        "above_range_roles": ["engine=31 target 4-24"],
                        "next_action": "review_role_extremes_then_add_commander_profile_or_source_lane",
                    },
                ]
            },
        )

        report = pivot.build_report(priority_report=priority)

        self.assertEqual(
            report["status"],
            "cross_commander_role_axis_learning_pivot_ready_after_engine_axis_exhaustion_no_deck_action",
        )
        self.assertEqual(report["summary"]["top_axis_role"], "removal")
        self.assertEqual(report["summary"]["engine_axis_exhausted_axis_count"], 1)
        self.assertEqual(report["summary"]["engine_axis_suppressed_axis_count"], 1)
        engine = next(row for row in report["axis_rows"] if row["role"] == "engine")
        self.assertEqual(engine["status"], "cross_commander_role_axis_suppressed_engine_axis_exhausted")
        self.assertEqual(engine["engine_axis_exhausted_decks"], ["619"])
        self.assertTrue(engine["axis_suppressed_by_engine_axis_exhaustion"])
        self.assertLess(engine["priority_score"], report["axis_rows"][0]["priority_score"])

    def test_role_axis_exhaustion_suppresses_ramp_reentry(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        priority = write_json(
            root,
            "priority.json",
            {
                "deck_priorities": [
                    {
                        "deck_id": "619",
                        "deck_name": "Kaalia Variant",
                        "commander": "Kaalia of the Vast",
                        "stage": "core_floor_repair",
                        "repair_gate_state": "nonland_add_cut_pool_ready_review_only",
                        "source_exhaustion_state": "not_applicable",
                        "engine_axis_pivot_state": "not_applicable",
                        "role_axis_exhaustion_state": "role_axis_exhausted_requires_global_learning_pivot",
                        "role_axis_exhausted_role": "ramp",
                        "below_floor_roles": ["removal=1 target 6-14"],
                        "above_range_roles": ["ramp=23 target 8-16", "draw=20 target 8-16"],
                        "next_action": "pivot_to_cross_commander_role_axis_learning_after_ramp_axis_exhaustion",
                    },
                    {
                        "deck_id": "620",
                        "deck_name": "Sauron Variant",
                        "commander": "Sauron, the Dark Lord",
                        "stage": "role_extreme_review_then_source_lane",
                        "repair_gate_state": "not_applicable",
                        "source_exhaustion_state": "not_applicable",
                        "engine_axis_pivot_state": "not_applicable",
                        "role_axis_exhaustion_state": "not_applicable",
                        "below_floor_roles": [],
                        "above_range_roles": ["ramp=21 target 8-16"],
                        "next_action": "review_role_extremes_then_add_commander_profile_or_source_lane",
                    },
                ]
            },
        )

        report = pivot.build_report(priority_report=priority)

        self.assertEqual(
            report["status"],
            "cross_commander_role_axis_learning_pivot_ready_after_role_axis_exhaustion_no_deck_action",
        )
        self.assertEqual(report["summary"]["top_axis_role"], "removal")
        self.assertEqual(report["summary"]["role_axis_exhausted_axis_count"], 1)
        self.assertEqual(report["summary"]["role_axis_suppressed_axis_count"], 1)
        ramp = next(row for row in report["axis_rows"] if row["role"] == "ramp")
        self.assertEqual(ramp["status"], "cross_commander_role_axis_suppressed_ramp_axis_exhausted")
        self.assertEqual(ramp["role_axis_exhausted_decks"], ["619"])
        self.assertTrue(ramp["axis_suppressed_by_role_axis_exhaustion"])
        self.assertLess(ramp["priority_score"], report["axis_rows"][0]["priority_score"])


if __name__ == "__main__":
    unittest.main()
