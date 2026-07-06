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


if __name__ == "__main__":
    unittest.main()
