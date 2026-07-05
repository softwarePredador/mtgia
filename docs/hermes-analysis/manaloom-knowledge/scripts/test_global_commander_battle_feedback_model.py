#!/usr/bin/env python3
"""Tests for global Commander battle feedback model."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_battle_feedback_model as model


def probe_payload(
    *,
    status: str,
    added: list[str],
    cut: list[str],
    blockers: list[str],
    exercised: list[str] | None = None,
    unobserved: list[str] | None = None,
    base_wr: float = 66.6,
    candidate_wr: float = 33.3,
    games: int = 9,
) -> dict[str, object]:
    return {
        "artifact_type": "global_commander_candidate_battle_probe_audit",
        "status": status,
        "deck_id": 619,
        "commander": "Kaalia of the Vast",
        "deck_diff": {
            "deck_id": 619,
            "added_cards": added,
            "cut_cards": cut,
            "base_count": 100,
            "candidate_count": 100,
        },
        "battle_metrics": {
            "base": {"win_rate": base_wr, "total_games": games},
            "candidate": {"win_rate": candidate_wr, "total_games": games},
            "win_rate_delta": candidate_wr - base_wr,
            "same_sample_shape": True,
        },
        "replay": {
            "added_cards_exercised_in_events": exercised or [],
            "added_cards_unobserved": unobserved or [],
            "added_cards_decision_only": [],
            "stale_lorehold_mentions": 0,
        },
        "blocker_reasons": blockers,
    }


class GlobalCommanderBattleFeedbackModelTests(unittest.TestCase):
    def test_larger_failed_gate_blocks_prior_ready_probe_for_same_pair(self) -> None:
        ready = model.observation_from_payload(
            Path("ready.json"),
            probe_payload(
                status="battle_probe_ready_for_larger_gate",
                added=["Feed the Swarm"],
                cut=["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
                blockers=[],
                exercised=["Feed the Swarm"],
                base_wr=33.3,
                candidate_wr=66.6,
                games=3,
            ),
        )
        failed = model.observation_from_payload(
            Path("failed.json"),
            probe_payload(
                status="battle_probe_blocks_promotion",
                added=["Feed the Swarm"],
                cut=["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
                blockers=["candidate_underperformed_base_probe"],
                exercised=["Feed the Swarm"],
                base_wr=66.6,
                candidate_wr=22.2,
                games=9,
            ),
        )

        [feedback] = model.aggregate_pair_feedback([ready, failed])  # type: ignore[list-item]

        self.assertEqual(feedback["pair_status"], "pair_blocked_by_failed_gate")
        self.assertEqual(feedback["recommendation"], "block_pair_until_new_source_lane_or_cut")
        self.assertEqual(feedback["superseded_ready_probe_count"], 1)
        self.assertEqual(feedback["largest_sample_games"], 9)
        self.assertEqual(feedback["classification_counts"]["ready_for_larger_equal_gate"], 1)
        self.assertEqual(feedback["classification_counts"]["failed_exercised_candidate_pair"], 1)

    def test_unexercised_added_package_requires_exposure_before_gate(self) -> None:
        observation = model.observation_from_payload(
            Path("wide_package.json"),
            probe_payload(
                status="battle_probe_blocks_promotion",
                added=["Feed the Swarm", "Terminate"],
                cut=["Archaeomancer's Map", "Genji Glove"],
                blockers=[
                    "candidate_underperformed_base_probe",
                    "added_cards_not_exercised_in_replay_events",
                ],
                unobserved=["Feed the Swarm", "Terminate"],
            ),
        )

        [feedback] = model.aggregate_pair_feedback([observation])  # type: ignore[list-item]

        self.assertEqual(feedback["pair_status"], "pair_needs_exposure_replay_before_gate")
        self.assertEqual(
            feedback["recommendation"],
            "run_exposure_replay_or_focused_test_before_candidate_gate",
        )
        self.assertEqual(feedback["classification_counts"]["failed_unexercised_candidate_pair"], 1)

    def test_build_report_is_review_only_and_counts_feedback(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        path = root / "probe.json"
        path.write_text(
            json.dumps(
                probe_payload(
                    status="battle_probe_blocks_promotion",
                    added=["Feed the Swarm"],
                    cut=["Archaeomancer's Map"],
                    blockers=["candidate_underperformed_base_probe"],
                    exercised=["Feed the Swarm"],
                )
            ),
            encoding="utf-8",
        )

        report = model.build_report([path])

        self.assertEqual(report["status"], "pass")
        self.assertFalse(report["battle_or_optimization_performed"])
        self.assertFalse(report["mutation_allowed"])
        self.assertFalse(report["promotion_allowed"])
        self.assertEqual(report["summary"]["pair_count"], 1)
        self.assertEqual(report["summary"]["blocked_pair_count"], 1)


if __name__ == "__main__":
    unittest.main()
