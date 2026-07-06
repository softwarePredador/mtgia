#!/usr/bin/env python3
"""Tests for global Commander role-axis policy builder."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_role_axis_policy_builder as builder


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


class GlobalCommanderRoleAxisPolicyBuilderTests(unittest.TestCase):
    def test_engine_cycle_blocks_same_deck_source_expansion(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        pivot = write_json(
            root,
            "pivot.json",
            {
                "axis_rows": [
                    {
                        "role": "engine",
                        "status": "cross_commander_role_axis_blocks_same_deck_source_cycle",
                        "priority_score": 402,
                        "actionable_deck_count": 16,
                        "commander_count": 6,
                        "below_floor_deck_count": 0,
                        "above_range_deck_count": 16,
                        "source_cycle_blocked_deck_count": 1,
                        "source_cycle_blocked_decks": ["619"],
                        "evidence_rows": [
                            {
                                "deck_id": "619",
                                "deck_name": "Kaalia Variant",
                                "commander": "Kaalia of the Vast",
                                "direction": "above_range",
                                "count": 35,
                                "min": 4,
                                "max": 24,
                                "source_cycle_blocks_same_deck_search": True,
                            }
                        ],
                    },
                    {
                        "role": "removal",
                        "status": "cross_commander_role_axis_blocks_same_deck_source_cycle",
                        "priority_score": 289,
                        "actionable_deck_count": 3,
                        "commander_count": 2,
                        "below_floor_deck_count": 1,
                        "above_range_deck_count": 2,
                        "source_cycle_blocked_deck_count": 1,
                        "source_cycle_blocked_decks": ["619"],
                        "evidence_rows": [
                            {
                                "deck_id": "619",
                                "deck_name": "Kaalia Variant",
                                "commander": "Kaalia of the Vast",
                                "direction": "below_floor",
                                "count": 1,
                                "min": 6,
                                "max": 14,
                                "source_cycle_blocks_same_deck_search": True,
                            }
                        ],
                    },
                ]
            },
        )

        report = builder.build_report(pivot_report=pivot)

        self.assertEqual(report["status"], "role_axis_policy_ready_blocks_same_deck_source_cycle")
        self.assertEqual(report["summary"]["top_policy_role"], "engine")
        self.assertEqual(report["summary"]["top_pressure_class"], "ceiling_saturation_axis")
        self.assertEqual(
            report["summary"]["next_gate"],
            "apply_engine_axis_policy_to_nonland_cut_model_before_more_same_deck_source_expansion",
        )
        self.assertFalse(report["candidate_copy_allowed_now"])
        engine = report["axis_policy_rows"][0]
        self.assertIn("treat_engine_as_capacity_ceiling_not_missing_role", engine["policy_actions"])
        self.assertIn("619", report["source_cycle_deck_role_pressure"])

    def test_foundation_floor_axis_gets_floor_policy(self) -> None:
        axis = {
            "role": "land",
            "below_floor_deck_count": 4,
            "above_range_deck_count": 0,
            "source_cycle_blocked_deck_count": 0,
        }

        self.assertEqual(builder.pressure_class(axis), "floor_repair_axis")
        self.assertEqual(builder.next_gate_for_axis(axis, "floor_repair_axis"), "calibrate_land_floor_policy_before_candidate_copy")

    def test_engine_axis_exhaustion_holds_engine_and_routes_next_axis(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        pivot = write_json(
            root,
            "pivot.json",
            {
                "axis_rows": [
                    {
                        "role": "ramp",
                        "status": "cross_commander_role_axis_blocks_same_deck_source_cycle",
                        "priority_score": 321,
                        "actionable_deck_count": 10,
                        "commander_count": 3,
                        "below_floor_deck_count": 0,
                        "above_range_deck_count": 10,
                        "source_cycle_blocked_deck_count": 1,
                        "source_cycle_blocked_decks": ["619"],
                        "engine_axis_exhausted_deck_count": 0,
                        "engine_axis_exhausted_decks": [],
                        "axis_suppressed_by_engine_axis_exhaustion": False,
                        "evidence_rows": [
                            {
                                "deck_id": "619",
                                "deck_name": "Kaalia Variant",
                                "commander": "Kaalia of the Vast",
                                "direction": "above_range",
                                "count": 23,
                                "min": 8,
                                "max": 16,
                                "source_cycle_blocks_same_deck_search": True,
                                "deck_engine_axis_exhausted_requires_global_pivot": True,
                                "engine_axis_exhaustion_blocks_this_axis": False,
                            }
                        ],
                    },
                    {
                        "role": "engine",
                        "status": "cross_commander_role_axis_suppressed_engine_axis_exhausted",
                        "priority_score": -98,
                        "actionable_deck_count": 16,
                        "commander_count": 6,
                        "below_floor_deck_count": 0,
                        "above_range_deck_count": 16,
                        "source_cycle_blocked_deck_count": 1,
                        "source_cycle_blocked_decks": ["619"],
                        "engine_axis_exhausted_deck_count": 1,
                        "engine_axis_exhausted_decks": ["619"],
                        "axis_suppressed_by_engine_axis_exhaustion": True,
                        "evidence_rows": [
                            {
                                "deck_id": "619",
                                "deck_name": "Kaalia Variant",
                                "commander": "Kaalia of the Vast",
                                "direction": "above_range",
                                "count": 35,
                                "min": 4,
                                "max": 24,
                                "source_cycle_blocks_same_deck_search": True,
                                "deck_engine_axis_exhausted_requires_global_pivot": True,
                                "engine_axis_exhaustion_blocks_this_axis": True,
                            }
                        ],
                    },
                ]
            },
        )

        report = builder.build_report(pivot_report=pivot)

        self.assertEqual(
            report["status"],
            "role_axis_policy_ready_after_engine_axis_exhaustion_blocks_same_deck_source_cycle",
        )
        self.assertEqual(report["summary"]["top_policy_role"], "ramp")
        self.assertEqual(report["summary"]["held_engine_axis_count"], 1)
        self.assertEqual(
            report["summary"]["next_gate"],
            "apply_ramp_axis_policy_before_more_same_deck_source_expansion",
        )
        held = next(row for row in report["axis_policy_rows"] if row["role"] == "engine")
        self.assertEqual(held["status"], "role_axis_policy_holds_exhausted_engine_axis")
        self.assertIn(
            "hold_engine_axis_after_biotransference_protection_exhaustion",
            held["policy_actions"],
        )
        self.assertIn("619", report["engine_axis_exhausted_deck_role_pressure"])

    def test_role_axis_exhaustion_holds_ramp_and_routes_next_axis(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        pivot = write_json(
            root,
            "pivot.json",
            {
                "axis_rows": [
                    {
                        "role": "removal",
                        "status": "cross_commander_role_axis_ready_no_deck_action",
                        "priority_score": 220,
                        "actionable_deck_count": 1,
                        "commander_count": 1,
                        "below_floor_deck_count": 1,
                        "above_range_deck_count": 0,
                        "source_cycle_blocked_deck_count": 0,
                        "source_cycle_blocked_decks": [],
                        "role_axis_exhausted_deck_count": 0,
                        "role_axis_exhausted_decks": [],
                        "axis_suppressed_by_role_axis_exhaustion": False,
                        "evidence_rows": [
                            {
                                "deck_id": "619",
                                "deck_name": "Kaalia Variant",
                                "commander": "Kaalia of the Vast",
                                "direction": "below_floor",
                                "count": 1,
                                "min": 6,
                                "max": 14,
                                "deck_role_axis_exhausted_requires_global_pivot": True,
                                "role_axis_exhaustion_blocks_this_axis": False,
                            }
                        ],
                    },
                    {
                        "role": "ramp",
                        "status": "cross_commander_role_axis_suppressed_ramp_axis_exhausted",
                        "priority_score": -140,
                        "actionable_deck_count": 2,
                        "commander_count": 2,
                        "below_floor_deck_count": 0,
                        "above_range_deck_count": 2,
                        "source_cycle_blocked_deck_count": 0,
                        "source_cycle_blocked_decks": [],
                        "role_axis_exhausted_deck_count": 1,
                        "role_axis_exhausted_decks": ["619"],
                        "role_axis_exhausted_role": "ramp",
                        "axis_suppressed_by_role_axis_exhaustion": True,
                        "evidence_rows": [
                            {
                                "deck_id": "619",
                                "deck_name": "Kaalia Variant",
                                "commander": "Kaalia of the Vast",
                                "direction": "above_range",
                                "count": 23,
                                "min": 8,
                                "max": 16,
                                "deck_role_axis_exhausted_requires_global_pivot": True,
                                "role_axis_exhaustion_blocks_this_axis": True,
                            }
                        ],
                    },
                ]
            },
        )

        report = builder.build_report(pivot_report=pivot)

        self.assertEqual(
            report["status"],
            "role_axis_policy_ready_after_role_axis_exhaustion_no_deck_action",
        )
        self.assertEqual(report["summary"]["top_policy_role"], "removal")
        self.assertEqual(report["summary"]["held_role_axis_count"], 1)
        self.assertEqual(report["summary"]["role_axis_exhausted_deck_count"], 1)
        held = next(row for row in report["axis_policy_rows"] if row["role"] == "ramp")
        self.assertEqual(held["status"], "role_axis_policy_holds_exhausted_role_axis")
        self.assertIn("hold_ramp_axis_after_current_cut_lane_exhaustion", held["policy_actions"])
        self.assertIn("619", report["role_axis_exhausted_deck_role_pressure"])


if __name__ == "__main__":
    unittest.main()
