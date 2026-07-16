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

    def test_missing_role_data_is_loaded_before_role_gap_inference(self) -> None:
        core_row = {
            "deck_id": "product-deck",
            "commander": "Example Commander",
            "shape_status": "structure_ready",
            "core_status": "role_data_unavailable",
            "role_bands": [],
        }

        stage = audit.stage_for_deck(core_row, None)

        self.assertEqual(stage, "role_data_load")
        self.assertEqual(audit.STAGE_RANK[stage], 97)
        self.assertEqual(audit.priority_score(core_row, stage), 102)
        self.assertIn("load_product_role_data", audit.next_action_for_stage(stage))

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
        self.assertEqual(row["source_exhaustion_state"], "not_applicable")
        self.assertEqual(row["next_action"], "review_top_nonland_add_cut_pair_then_candidate_copy")

    def test_source_exhaustion_blocks_nonland_candidate_copy_even_with_source_lane(self) -> None:
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
        source_exhaustion_payload = {
            "artifact_type": "global_commander_external_nonpayoff_seed_exhaustion_recovery_router",
            "status": "external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion",
            "candidate_copy_allowed_now": False,
            "battle_gate_allowed_now": False,
            "candidate_copy_blockers": [
                "reviewed_external_seed_exhaustion_is_not_cut_permission",
                "candidate_copy_closed_until_current_deck_negative_review_or_fresh_cut_source_exists",
            ],
            "summary": {
                "commander": "Kaalia of the Vast",
                "deck_id": "619",
                "next_gate": "expand_external_nonpayoff_source_candidate_pool",
                "target_role_count": 3,
                "seeded_exhausted_role_count": 3,
                "current_deck_negative_review_candidate_count": 0,
                "prior_fresh_seeded_same_lane_cut_source_count": 0,
                "prior_blocked_recycled_seeded_cut_source_count": 31,
            },
        }

        report = audit.build_report(
            core_payload=core_payload,
            strategy_payload=strategy_payload,
            nonland_payload=nonland_payload,
            source_exhaustion_payload=source_exhaustion_payload,
            bracket_status=audit.bracket_policy_status_from_text(""),
            core_report_path=Path("docs/hermes-analysis/master_optimizer_reports/core.json"),
            strategy_report_path=Path("docs/hermes-analysis/master_optimizer_reports/strategy.json"),
            nonland_report_path=Path("docs/hermes-analysis/master_optimizer_reports/nonland.json"),
            source_exhaustion_report_path=Path("docs/hermes-analysis/master_optimizer_reports/source_exhaustion.json"),
        )

        [row] = report["deck_priorities"]
        self.assertEqual(row["repair_gate_state"], "nonland_add_cut_pool_ready_review_only")
        self.assertEqual(row["source_exhaustion_state"], "source_expansion_required_before_candidate_copy")
        self.assertEqual(row["source_exhaustion_prior_fresh_cut_source_count"], 0)
        self.assertEqual(row["source_exhaustion_prior_blocked_recycled_cut_source_count"], 31)
        self.assertEqual(row["candidate_copy_allowed_by_source_exhaustion"], False)
        self.assertEqual(row["next_action"], "expand_external_nonpayoff_source_candidate_pool_before_candidate_copy")
        self.assertEqual(report["commander_queue"][0]["next_action"], row["next_action"])
        self.assertEqual(report["summary"]["source_exhaustion_blocked_deck_count"], 1)
        self.assertEqual(
            report["summary"]["source_exhaustion_gate_counts"]["source_expansion_required_before_candidate_copy"],
            1,
        )

    def test_repeated_source_expansion_cycles_pivot_to_cross_commander_learning(self) -> None:
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
        source_exhaustion_payload = {
            "artifact_type": "global_commander_external_nonpayoff_seed_exhaustion_recovery_router",
            "status": "external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion",
            "candidate_copy_allowed_now": False,
            "battle_gate_allowed_now": False,
            "candidate_copy_blockers": [
                "reviewed_external_seed_exhaustion_is_not_cut_permission",
                "candidate_copy_closed_until_current_deck_negative_review_or_fresh_cut_source_exists",
            ],
            "summary": {
                "commander": "Kaalia of the Vast",
                "deck_id": "619",
                "next_gate": "expand_external_nonpayoff_source_candidate_pool",
                "target_role_count": 3,
                "seeded_exhausted_role_count": 3,
                "current_deck_negative_review_candidate_count": 0,
                "prior_fresh_seeded_same_lane_cut_source_count": 0,
                "prior_blocked_recycled_seeded_cut_source_count": 47,
            },
        }

        report = audit.build_report(
            core_payload=core_payload,
            strategy_payload=strategy_payload,
            nonland_payload=nonland_payload,
            source_exhaustion_payload=source_exhaustion_payload,
            bracket_status=audit.bracket_policy_status_from_text(""),
            core_report_path=Path("docs/hermes-analysis/master_optimizer_reports/core.json"),
            strategy_report_path=Path("docs/hermes-analysis/master_optimizer_reports/strategy.json"),
            nonland_report_path=Path("docs/hermes-analysis/master_optimizer_reports/nonland.json"),
            source_exhaustion_report_path=Path("docs/hermes-analysis/master_optimizer_reports/source_exhaustion.json"),
        )

        [row] = report["deck_priorities"]
        self.assertEqual(row["source_exhaustion_state"], "source_expansion_cycle_requires_global_learning_pivot")
        self.assertTrue(row["source_exhaustion_all_seeded_roles_exhausted"])
        self.assertEqual(row["source_expansion_cycle_threshold"], 40)
        self.assertEqual(
            row["next_action"],
            "pivot_to_cross_commander_role_axis_learning_before_more_same_deck_source_expansion",
        )
        self.assertEqual(report["commander_queue"][0]["next_action"], row["next_action"])
        self.assertEqual(report["summary"]["source_exhaustion_blocked_deck_count"], 1)
        self.assertEqual(
            report["summary"]["source_exhaustion_gate_counts"][
                "source_expansion_cycle_requires_global_learning_pivot"
            ],
            1,
        )
        self.assertIn(
            "source_expansion_cycle_detection_before_more_same_deck_research",
            report["method"]["priority_order"],
        )

    def test_engine_axis_exhaustion_after_biotransference_protection_pivots_to_global_learning(self) -> None:
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
        engine_axis_pivot_payload = {
            "artifact_type": "global_commander_biotransference_protection_pivot_router",
            "status": "biotransference_protected_engine_axis_exhausted_pivot_required",
            "candidate_copy_allowed_now": False,
            "battle_gate_allowed_now": False,
            "summary": {
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "next_gate": "return_to_global_role_axis_learning_priority_after_engine_axis_exhaustion",
                "type_conversion_lane_exhausted": True,
                "biotransference_protected": True,
                "viable_non_biotransference_engine_cut_count": 0,
                "blocker_counts": {"no_outside_artifact_type_conversion_candidate": 1},
            },
        }

        report = audit.build_report(
            core_payload=core_payload,
            strategy_payload=strategy_payload,
            nonland_payload=nonland_payload,
            engine_axis_pivot_payload=engine_axis_pivot_payload,
            bracket_status=audit.bracket_policy_status_from_text(""),
            core_report_path=Path("docs/hermes-analysis/master_optimizer_reports/core.json"),
            strategy_report_path=Path("docs/hermes-analysis/master_optimizer_reports/strategy.json"),
            nonland_report_path=Path("docs/hermes-analysis/master_optimizer_reports/nonland.json"),
            engine_axis_pivot_report_path=Path("docs/hermes-analysis/master_optimizer_reports/engine_axis.json"),
        )

        [row] = report["deck_priorities"]
        self.assertEqual(
            row["engine_axis_pivot_state"],
            "engine_axis_exhausted_requires_global_learning_pivot",
        )
        self.assertTrue(row["engine_axis_biotransference_protected"])
        self.assertEqual(row["engine_axis_viable_non_biotransference_cut_count"], 0)
        self.assertEqual(
            row["next_action"],
            "pivot_to_cross_commander_role_axis_learning_after_engine_axis_exhaustion",
        )
        self.assertEqual(report["summary"]["engine_axis_pivot_blocked_deck_count"], 1)
        self.assertEqual(
            report["summary"]["engine_axis_pivot_gate_counts"][
                "engine_axis_exhausted_requires_global_learning_pivot"
            ],
            1,
        )
        self.assertIn(
            "engine_axis_exhaustion_router_before_more_same_deck_engine_research",
            report["method"]["priority_order"],
        )

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
                "package_count": 1,
                "blocked_package_count": 1,
                "needs_exercise_package_count": 0,
                "pair_status_counts": {
                    "pair_blocked_by_failed_gate": 2,
                    "pair_needs_exposure_replay_before_gate": 1,
                },
                "package_status_counts": {
                    "package_blocked_by_protected_baseline_gate": 1,
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
        self.assertEqual(report["battle_feedback_summary"]["blocked_package_count"], 1)
        self.assertEqual(report["summary"]["blocked_exact_add_cut_pair_count"], 2)
        self.assertEqual(report["summary"]["blocked_exact_package_count"], 1)
        self.assertIn("battle_feedback_model_before_requeue", report["method"]["priority_order"])
        self.assertEqual(
            report["battle_feedback_summary"]["next_gate"],
            "exclude_blocked_pairs_packages_and_route_unexercised_evidence_before_requeue",
        )

    def test_role_axis_exhaustion_after_ramp_cut_lane_blocks_same_axis_reentry(self) -> None:
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
                        },
                        {
                            "role": "ramp",
                            "count": 23,
                            "min": 8,
                            "max": 16,
                            "severity": "review",
                            "status": "above_range_review",
                        },
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
        role_axis_exhaustion_payload = {
            "artifact_type": "global_commander_ramp_axis_exhaustion_router",
            "status": "ramp_axis_exhausted_requires_global_role_axis_pivot",
            "exhausted_role_axis": "ramp",
            "candidate_copy_allowed_now": False,
            "battle_gate_allowed_now": False,
            "candidate_copy_blockers": ["ramp_axis_current_cut_lane_exhausted"],
            "summary": {
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "next_gate": "return_to_global_role_axis_learning_priority_after_ramp_axis_exhaustion",
                "blocked_ramp_cut_count": 9,
                "replacement_exact_ready_count": 0,
                "alternative_forced_usage_blocked_count": 2,
            },
        }

        report = audit.build_report(
            core_payload=core_payload,
            strategy_payload=strategy_payload,
            nonland_payload=nonland_payload,
            role_axis_exhaustion_payload=role_axis_exhaustion_payload,
            bracket_status=audit.bracket_policy_status_from_text(""),
            core_report_path=Path("docs/hermes-analysis/master_optimizer_reports/core.json"),
            strategy_report_path=Path("docs/hermes-analysis/master_optimizer_reports/strategy.json"),
            nonland_report_path=Path("docs/hermes-analysis/master_optimizer_reports/nonland.json"),
            role_axis_exhaustion_report_path=Path("docs/hermes-analysis/master_optimizer_reports/ramp_axis.json"),
        )

        [row] = report["deck_priorities"]
        self.assertEqual(row["role_axis_exhaustion_state"], "role_axis_exhausted_requires_global_learning_pivot")
        self.assertEqual(row["role_axis_exhausted_role"], "ramp")
        self.assertEqual(row["role_axis_blocked_cut_count"], 9)
        self.assertEqual(
            row["next_action"],
            "pivot_to_cross_commander_role_axis_learning_after_ramp_axis_exhaustion",
        )
        self.assertEqual(report["summary"]["role_axis_exhaustion_blocked_deck_count"], 1)
        self.assertEqual(
            report["summary"]["role_axis_exhaustion_gate_counts"][
                "role_axis_exhausted_requires_global_learning_pivot"
            ],
            1,
        )
        self.assertIn(
            "role_axis_exhaustion_router_before_more_same_deck_axis_research",
            report["method"]["priority_order"],
        )


if __name__ == "__main__":
    unittest.main()
