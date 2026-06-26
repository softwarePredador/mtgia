#!/usr/bin/env python3
from __future__ import annotations

import unittest

import xmage_acceleration_strategy_benchmark as benchmark


def proposal(card: str, status: str, family: str, effect: str, scope: str) -> dict[str, object]:
    return {
        "card_name": card,
        "proposal_status": status,
        "family_id": family,
        "effect": effect,
        "battle_model_scope": scope,
    }


class XMageAccelerationStrategyBenchmarkTests(unittest.TestCase):
    def test_recommends_hybrid_when_packages_and_clusters_exist(self) -> None:
        proposals = [
            proposal("Packaged A", "batch_pg_candidate_after_precheck", "draw", "draw", "draw_v1"),
            proposal("Packaged B", "batch_pg_candidate_after_precheck", "draw", "draw", "draw_v1"),
            proposal(
                "Packaged Partial",
                "partial_batch_pg_candidate_preserve_shadow_rows_after_precheck",
                "burn_engine",
                "damage_each_opponent",
                "controlled_creature_enters_damage_each_opponent_v1",
            ),
            proposal("Damage A", "split_family_scope_review_required", "targeted", "damage", "damage_v1"),
            proposal("Damage B", "split_family_scope_review_required", "targeted", "damage", "damage_v1"),
            proposal("Damage C", "split_family_scope_review_required", "targeted", "damage", "damage_v1"),
            proposal("Wipe A", "runtime_family_implementation_required", "wipe", "damage_all", "damage_all_v1"),
            proposal("Wipe B", "runtime_family_implementation_required", "wipe", "damage_all", "damage_all_v1"),
            proposal("Manual", "mapper_metadata_or_test_scenario_required", "manual", "manual", "manual_v1"),
        ]
        report = benchmark.build_report(
            proposal_report={"proposals": proposals},
            effective_queue_report={
                "effective_queue": {
                    "lane_counts": {
                        benchmark.PACKAGE_PREPARED_LANE: 2,
                        benchmark.PACKAGE_READY_LANE: 1,
                    },
                    "prepared_packages": [{"deploy_id": "PGT", "cards_in_current_queue": ["Packaged A", "Packaged B"]}],
                }
            },
            inventory_report={
                "summary": {
                    "card_implementation_files": 1000,
                    "java_files_total": 1200,
                    "effect_files": 50,
                    "test_files": 25,
                }
            },
            test_miner_report={
                "summary": {
                    "requested_card_count": 3,
                    "cards_with_test_reference": 2,
                    "usable_scenario_candidate_count": 1,
                }
            },
            sources={},
        )

        self.assertEqual(report["summary"]["recommended_strategy_id"], "hybrid_effective_queue_pattern_registry")
        ranking_ids = [row["strategy_id"] for row in report["summary"]["ranking"]]
        self.assertIn("full_xmage_first", ranking_ids)
        self.assertIn("card_by_card_queue", ranking_ids)

    def test_full_xmage_first_exposes_work_multiplier(self) -> None:
        proposals = [
            proposal("Only Card", "mapper_metadata_or_test_scenario_required", "manual", "manual", "manual_v1")
        ]
        rows = benchmark.build_strategy_rows(
            proposals=proposals,
            effective_queue={"effective_queue": {"lane_counts": {}, "prepared_packages": []}},
            inventory={"summary": {"card_implementation_files": 31706, "java_files_total": 38739}},
            test_miner=None,
        )

        full = next(row for row in rows if row["strategy_id"] == "full_xmage_first")
        self.assertEqual(full["verdict"], "reject_as_primary")
        self.assertGreater(full["evidence"]["work_multiplier_vs_current_queue"], 1000)

    def test_runtime_fragmentation_is_recorded(self) -> None:
        proposals = [
            proposal("Token A", "runtime_family_implementation_required", "token_maker", "token", "token_a_v1"),
            proposal("Token B", "runtime_family_implementation_required", "token_maker", "token", "token_b_v1"),
            proposal("Token C", "runtime_family_implementation_required", "token_maker", "token", "token_c_v1"),
        ]
        rows = benchmark.build_strategy_rows(
            proposals=proposals,
            effective_queue={"effective_queue": {"lane_counts": {}, "prepared_packages": []}},
            inventory={"summary": {"card_implementation_files": 100, "java_files_total": 100, "effect_files": 10}},
            test_miner=None,
        )

        runtime = next(row for row in rows if row["strategy_id"] == "runtime_exact_scope_first")
        self.assertEqual(runtime["evidence"]["largest_raw_runtime_family"]["scope_count"], 3)
        self.assertEqual(runtime["evidence"]["fragmentation_warning"], "largest raw runtime family is fragmented")


if __name__ == "__main__":
    unittest.main()
