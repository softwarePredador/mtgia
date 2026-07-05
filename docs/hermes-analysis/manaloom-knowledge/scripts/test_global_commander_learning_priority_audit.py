#!/usr/bin/env python3
"""Tests for global Commander learning priority audit."""

from __future__ import annotations

import unittest
from pathlib import Path

import global_commander_learning_priority_audit as audit


class GlobalCommanderLearningPriorityAuditTests(unittest.TestCase):
    def test_bracket_policy_accepts_current_five_bracket_model(self) -> None:
        status = audit.bracket_policy_status_from_text(
            "final b = bracket.clamp(1, 5); "
            "case 5: enum BracketCategory { gameChanger } "
            "officialGameChangerNamesForBracketPolicy"
        )

        self.assertEqual(status["status"], "aligned_with_current_official_bracket_model")
        self.assertTrue(status["backend_supports_five_brackets"])
        self.assertTrue(status["backend_has_game_changer_policy"])
        self.assertFalse(status["backend_clamps_to_legacy_four_brackets"])

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

    def test_land_cut_pool_ready_updates_core_floor_next_action(self) -> None:
        core_payload = {
            "decks": [
                {
                    "deck_id": "612",
                    "deck_name": "Lorehold Land Gap",
                    "commander": "Lorehold, the Historian",
                    "scope": "hermes_lorehold_variant",
                    "shape_status": "structure_ready",
                    "core_status": "core_role_gap",
                    "role_bands": [
                        {
                            "role": "land",
                            "count": 27,
                            "min": 34,
                            "max": 39,
                            "severity": "critical",
                            "status": "below_floor",
                        }
                    ],
                }
            ]
        }
        strategy_payload = {
            "commanders": [
                {
                    "commander_key": "lorehold, the historian",
                    "status": "structure_ready_source_missing",
                    "source_lane_count": 0,
                }
            ]
        }
        land_cut_payload = {
            "deck_cut_pools": [
                {
                    "deck_id": "612",
                    "status": "review_cut_pool_ready",
                    "cut_candidate_count": 3,
                    "pair_hypotheses": [{"add": "Ash Barrens", "cut": "Pyromancer's Goggles"}],
                }
            ]
        }

        report = audit.build_report(
            core_payload=core_payload,
            strategy_payload=strategy_payload,
            land_cut_payload=land_cut_payload,
            bracket_status=audit.bracket_policy_status_from_text(""),
            core_report_path=Path("docs/hermes-analysis/master_optimizer_reports/core.json"),
            strategy_report_path=Path("docs/hermes-analysis/master_optimizer_reports/strategy.json"),
            land_cut_report_path=Path("docs/hermes-analysis/master_optimizer_reports/cuts.json"),
        )

        [row] = report["deck_priorities"]
        self.assertEqual(row["repair_gate_state"], "land_add_cut_pool_ready_review_only")
        self.assertEqual(row["land_cut_candidate_count"], 3)
        self.assertIn("review_top_land_add_cut_pair", row["next_action"])
        self.assertEqual(report["summary"]["repair_gate_counts"]["land_add_cut_pool_ready_review_only"], 1)

    def test_nonland_pool_ready_updates_core_floor_next_action(self) -> None:
        core_payload = {
            "decks": [
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
                }
            ]
        }
        strategy_payload = {
            "commanders": [
                {
                    "commander_key": "kaalia of the vast",
                    "status": "structure_ready_source_missing",
                    "source_lane_count": 0,
                }
            ]
        }
        nonland_payload = {
            "nonland_pools": [
                {
                    "deck_id": "619",
                    "role": "removal",
                    "status": "review_nonland_add_cut_pool_ready",
                    "candidate_count": 12,
                    "cut_candidate_count": 12,
                    "pair_hypotheses": [{"add": "Feed the Swarm", "cut": "Birgi"}],
                }
            ]
        }

        report = audit.build_report(
            core_payload=core_payload,
            strategy_payload=strategy_payload,
            nonland_payload=nonland_payload,
            bracket_status=audit.bracket_policy_status_from_text(""),
            core_report_path=Path("docs/hermes-analysis/master_optimizer_reports/core.json"),
            strategy_report_path=Path("docs/hermes-analysis/master_optimizer_reports/strategy.json"),
            nonland_report_path=Path("docs/hermes-analysis/master_optimizer_reports/nonland.json"),
        )

        [row] = report["deck_priorities"]
        self.assertEqual(row["repair_gate_state"], "nonland_add_cut_pool_ready_review_only")
        self.assertEqual(row["nonland_candidate_count"], 12)
        self.assertEqual(row["nonland_cut_candidate_count"], 12)
        self.assertIn("review_top_nonland_add_cut_pair", row["next_action"])
        self.assertEqual(report["summary"]["repair_gate_counts"]["nonland_add_cut_pool_ready_review_only"], 1)

    def test_nonland_pool_ready_with_source_lane_can_move_to_candidate_copy(self) -> None:
        core_payload = {
            "decks": [
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
                }
            ]
        }
        strategy_payload = {
            "commanders": [
                {
                    "commander_key": "kaalia of the vast",
                    "status": "ready_for_strategy_matrix",
                    "source_lane_count": 1,
                }
            ]
        }
        nonland_payload = {
            "nonland_pools": [
                {
                    "deck_id": "619",
                    "role": "removal",
                    "status": "review_nonland_add_cut_pool_ready",
                    "candidate_count": 12,
                    "cut_candidate_count": 12,
                    "pair_hypotheses": [{"add": "Feed the Swarm", "cut": "Birgi"}],
                }
            ]
        }

        report = audit.build_report(
            core_payload=core_payload,
            strategy_payload=strategy_payload,
            nonland_payload=nonland_payload,
            bracket_status=audit.bracket_policy_status_from_text(""),
            core_report_path=Path("docs/hermes-analysis/master_optimizer_reports/core.json"),
            strategy_report_path=Path("docs/hermes-analysis/master_optimizer_reports/strategy.json"),
            nonland_report_path=Path("docs/hermes-analysis/master_optimizer_reports/nonland.json"),
        )

        [row] = report["deck_priorities"]
        self.assertEqual(row["repair_gate_state"], "nonland_add_cut_pool_ready_review_only")
        self.assertEqual(row["next_action"], "review_top_nonland_add_cut_pair_then_candidate_copy")

    def test_battle_feedback_summary_blocks_exact_pair_requeue(self) -> None:
        core_payload = {
            "decks": [
                {
                    "deck_id": "619",
                    "deck_name": "Kaalia Variant",
                    "commander": "Kaalia of the Vast",
                    "scope": "hermes_registered_variant",
                    "shape_status": "structure_ready",
                    "core_status": "core_role_gap",
                    "role_bands": [],
                }
            ]
        }
        strategy_payload = {
            "commanders": [
                {
                    "commander_key": "kaalia of the vast",
                    "status": "ready_for_strategy_matrix",
                    "source_lane_count": 1,
                }
            ]
        }
        feedback_payload = {
            "status": "pass",
            "summary": {
                "pair_count": 3,
                "blocked_pair_count": 2,
                "needs_exposure_pair_count": 1,
                "ready_pair_count": 0,
                "pair_status_counts": {
                    "pair_blocked_by_failed_gate": 2,
                    "pair_needs_exposure_replay_before_gate": 1,
                },
            },
        }

        report = audit.build_report(
            core_payload=core_payload,
            strategy_payload=strategy_payload,
            battle_feedback_payload=feedback_payload,
            bracket_status=audit.bracket_policy_status_from_text(""),
            core_report_path=Path("docs/hermes-analysis/master_optimizer_reports/core.json"),
            strategy_report_path=Path("docs/hermes-analysis/master_optimizer_reports/strategy.json"),
        )

        self.assertEqual(report["battle_feedback_summary"]["blocked_pair_count"], 2)
        self.assertEqual(report["summary"]["blocked_exact_add_cut_pair_count"], 2)
        self.assertIn("battle_feedback_model_before_requeue", report["method"]["priority_order"])
        self.assertEqual(
            report["battle_feedback_summary"]["next_gate"],
            "exclude_blocked_pairs_and_route_unexercised_packages_before_requeue",
        )


if __name__ == "__main__":
    unittest.main()
