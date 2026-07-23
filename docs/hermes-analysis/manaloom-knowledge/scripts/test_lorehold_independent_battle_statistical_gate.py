#!/usr/bin/env python3

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import external_battle_async_runner as runner
import lorehold_independent_battle_statistical_gate as gate


def evaluation() -> dict:
    return {
        "schema_version": gate.EVALUATION_SCHEMA,
        "evaluation_id": "lorehold-independent-fixture",
        "baseline_deck_id": "607",
        "baseline_protected": True,
        "automatic_promotion_allowed": False,
        "minimum_uncensored_per_variant_per_stratum": 20,
        "maximum_censor_rate": 0.0,
        "noninferiority_margin": 0.10,
        "critical_noninferiority_margin": 0.0,
        "critical_comparison_ids": ["opponent-a"],
        "comparison_ids": ["opponent-a", "opponent-b", "opponent-c"],
    }


def stratum(comparison_id: str, *, candidate_wins: int = 30, baseline_wins: int = 10) -> dict:
    total = 40
    return {
        "comparison_id": comparison_id,
        "opponent_deck_id": comparison_id,
        "critical": comparison_id == "opponent-a",
        "baseline_wins": baseline_wins,
        "baseline_losses": total - baseline_wins,
        "baseline_draws": 0,
        "baseline_total": total,
        "candidate_wins": candidate_wins,
        "candidate_losses": total - candidate_wins,
        "candidate_draws": 0,
        "candidate_total": total,
        "baseline_censored": 0,
        "candidate_censored": 0,
        "censor_rate": 0.0,
    }


class LoreholdIndependentBattleStatisticalGateTest(unittest.TestCase):
    def test_unpaired_interval_is_symmetric_when_groups_are_swapped(self):
        forward = gate.newcombe_unpaired_interval(30, 40, 10, 40)
        reverse = gate.newcombe_unpaired_interval(10, 40, 30, 40)

        self.assertAlmostEqual(forward["point_estimate"], -reverse["point_estimate"])
        self.assertAlmostEqual(forward["lower"], -reverse["upper"])
        self.assertAlmostEqual(forward["upper"], -reverse["lower"])
        self.assertEqual(
            forward["method"],
            "Newcombe_unpaired_hybrid_score_Wilson",
        )
        self.assertNotIn("method_10", forward["method"].lower())

    def test_strong_balanced_independent_samples_reach_manual_review_only(self):
        report = gate.build_decision(
            evaluation(),
            [stratum("opponent-a"), stratum("opponent-b"), stratum("opponent-c")],
            generated_at="2026-07-22T00:00:00Z",
        )

        self.assertEqual(report["status"], "pass")
        self.assertTrue(report["superiority_proven"])
        self.assertTrue(report["promotion_review_eligible"])
        self.assertFalse(report["automatic_promotion_allowed"])
        self.assertFalse(report["automatic_mutation_performed"])
        self.assertFalse(report["seed_pairing_claim"])
        self.assertEqual(report["baseline_deck_id"], "607")
        self.assertEqual(
            report["next_gate"],
            "manual_guarded_promotion_review_without_automatic_apply",
        )

    def test_critical_regression_rejects_candidate_even_if_aggregate_is_positive(self):
        report = gate.build_decision(
            evaluation(),
            [
                stratum("opponent-a", candidate_wins=8, baseline_wins=12),
                stratum("opponent-b", candidate_wins=38, baseline_wins=5),
                stratum("opponent-c", candidate_wins=38, baseline_wins=5),
            ],
        )

        self.assertEqual(report["status"], "blocked")
        self.assertIn(
            "critical_opponent_noninferiority",
            report["failed_criteria"],
        )
        self.assertEqual(
            report["decision"],
            "reject_candidate_keep_protected_baseline_607",
        )
        self.assertIn("opponent-a", report["aggregate"]["critical_regressions"])

    def test_censoring_blocker_cannot_be_hidden_by_positive_results(self):
        report = gate.build_decision(
            evaluation(),
            [stratum("opponent-a"), stratum("opponent-b"), stratum("opponent-c")],
            blockers=["opponent-a:rerun_required_after_censoring"],
        )

        self.assertEqual(report["status"], "blocked")
        self.assertFalse(report["promotion_review_eligible"])
        self.assertEqual(
            report["next_gate"],
            "repair_contract_or_rerun_balanced_uncensored_independent_samples",
        )

    def test_legacy_paired_registry_is_rejected_before_statistics(self):
        registry = {
            "schema_version": "external_battle_async_registry_v1",
            "seed_mode": "paired_per_game_v1",
            "jobs": [],
        }
        checkpoint = {
            "schema_version": runner.CHECKPOINT_SCHEMA,
            "registry_hash": runner.stable_registry_hash(registry),
            "jobs": {},
        }

        current, strata, blockers = gate.collect_strata(
            registry,
            checkpoint,
            evaluation_id="legacy-384-pairs",
        )

        self.assertEqual(current, {})
        self.assertEqual(strata, [])
        self.assertIn(
            f"registry_schema_must_be_{runner.REGISTRY_SCHEMA}",
            blockers,
        )
        self.assertIn("independent_evaluation_missing", blockers)


if __name__ == "__main__":
    unittest.main()
