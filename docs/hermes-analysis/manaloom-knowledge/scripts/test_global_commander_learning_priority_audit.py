#!/usr/bin/env python3
"""Tests for global Commander learning priority audit."""

from __future__ import annotations

import unittest
from pathlib import Path

import global_commander_learning_priority_audit as audit


class GlobalCommanderLearningPriorityAuditTests(unittest.TestCase):
    def test_bracket_policy_detects_legacy_four_bracket_drift(self) -> None:
        status = audit.bracket_policy_status_from_text(
            "final b = bracket.clamp(1, 4); enum BracketCategory { gameChanger }"
        )

        self.assertEqual(status["status"], "needs_refresh_for_current_official_brackets")
        self.assertTrue(status["backend_clamps_to_legacy_four_brackets"])
        self.assertFalse(status["backend_supports_five_brackets"])

    def test_core_floor_repair_precedes_source_lane_build(self) -> None:
        core_row = {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "shape_status": "structure_ready",
            "core_status": "core_role_gap",
            "role_bands": [
                {
                    "role": "removal",
                    "count": 1,
                    "min": 6,
                    "max": 14,
                    "severity": "critical",
                    "status": "below_floor",
                }
            ],
        }
        commander_row = {"status": "structure_ready_source_missing", "source_lane_count": 0}

        stage = audit.stage_for_deck(core_row, commander_row)

        self.assertEqual(stage, "core_floor_repair")
        self.assertGreater(audit.priority_score(core_row, stage), 90)

    def test_607_is_benchmark_not_global_template(self) -> None:
        core_row = {
            "deck_id": "607",
            "commander": "Lorehold, the Historian",
            "shape_status": "structure_ready",
            "core_status": "core_review_ready",
            "role_bands": [],
        }
        commander_row = {"status": "structure_ready_source_missing", "source_lane_count": 0}

        stage = audit.stage_for_deck(core_row, commander_row)

        self.assertEqual(stage, "benchmark_regression_review_only")
        self.assertIn("regression_benchmark", audit.next_action_for_stage(stage))

    def test_build_report_ranks_non_lorehold_core_gap_before_607(self) -> None:
        core_payload = {
            "decks": [
                {
                    "deck_id": "607",
                    "deck_name": "Lorehold Benchmark",
                    "commander": "Lorehold, the Historian",
                    "scope": "hermes_lorehold_variant",
                    "shape_status": "structure_ready",
                    "core_status": "core_review_ready",
                    "role_bands": [],
                },
                {
                    "deck_id": "619",
                    "deck_name": "Kaalia Variant",
                    "commander": "Kaalia of the Vast",
                    "scope": "hermes_registered_variant",
                    "shape_status": "structure_ready",
                    "core_status": "core_role_gap",
                    "role_bands": [
                        {
                            "role": "removal",
                            "count": 1,
                            "min": 6,
                            "max": 14,
                            "severity": "critical",
                            "status": "below_floor",
                        }
                    ],
                },
            ]
        }
        strategy_payload = {
            "commanders": [
                {
                    "commander_key": "lorehold, the historian",
                    "status": "structure_ready_source_missing",
                    "source_lane_count": 0,
                },
                {
                    "commander_key": "kaalia of the vast",
                    "status": "structure_ready_source_missing",
                    "source_lane_count": 0,
                },
            ]
        }

        report = audit.build_report(
            core_payload=core_payload,
            strategy_payload=strategy_payload,
            bracket_status=audit.bracket_policy_status_from_text(""),
            core_report_path=Path("docs/hermes-analysis/master_optimizer_reports/core.json"),
            strategy_report_path=Path("docs/hermes-analysis/master_optimizer_reports/strategy.json"),
        )

        self.assertEqual(report["deck_priorities"][0]["deck_id"], "619")
        self.assertEqual(report["deck_priorities"][1]["stage"], "benchmark_regression_review_only")
        self.assertEqual(report["method"]["lorehold_607_role"], "benchmark_regression_only_not_global_template")


if __name__ == "__main__":
    unittest.main()
