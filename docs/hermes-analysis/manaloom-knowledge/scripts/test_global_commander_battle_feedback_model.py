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


def larger_gate_payload() -> dict[str, object]:
    return {
        "artifact_type": "global_commander_larger_battle_gate_audit",
        "status": "larger_battle_gate_blocks_promotion",
        "input_artifacts": {"strategy_report": "strategy.json"},
        "summary": {
            "deck_id": "612",
            "commander": "Lorehold, the Historian",
            "candidate_key": "candidate_profile_repair_package",
            "protected_baseline_key": "deck_607",
            "immediate_base_key": "deck_612",
            "games_per_opponent": 3,
            "opponent_count": 8,
            "forced_access_mode": "none",
            "candidate_vs_protected": {
                "candidate_beats_other": False,
                "win_delta": -3,
                "win_rate_delta": -12.5,
            },
            "candidate_vs_immediate_base": {
                "candidate_beats_other": True,
                "win_delta": 2,
                "win_rate_delta": 8.34,
            },
            "larger_gate_exercised_added_cards": ["Bant Panorama"],
            "larger_gate_unexercised_added_cards": ["Call Forth the Tempest"],
        },
        "blockers": [
            "candidate_did_not_beat_protected_baseline",
            "larger_gate_unexercised_added_cards:Call Forth the Tempest",
        ],
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

    def test_larger_gate_beating_weak_base_but_losing_protected_baseline_blocks_package(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        gate_path = root / "larger_gate.json"
        strategy_path = root / "strategy.json"
        strategy_path.write_text(
            json.dumps(
                {
                    "summary": {
                        "deck_id": "612",
                        "commander": "Lorehold, the Historian",
                        "package_adds": ["Bant Panorama", "Call Forth the Tempest"],
                        "package_cuts": ["Storm-Kiln Artist", "Jeska's Will"],
                    }
                }
            ),
            encoding="utf-8",
        )
        payload = larger_gate_payload()
        payload["input_artifacts"] = {"strategy_report": str(strategy_path)}
        gate_path.write_text(json.dumps(payload), encoding="utf-8")

        report = model.build_report([gate_path])

        self.assertEqual(report["summary"]["package_count"], 1)
        self.assertEqual(report["summary"]["blocked_package_count"], 1)
        self.assertEqual(
            report["summary"]["package_classification_counts"][
                "package_improved_weak_base_but_failed_protected_baseline"
            ],
            1,
        )
        [feedback] = report["package_feedback"]
        self.assertEqual(feedback["package_status"], "package_blocked_by_protected_baseline_gate")
        self.assertEqual(feedback["recommendation"], "block_package_until_new_source_lane_cut_or_strategy")
        self.assertEqual(feedback["worst_candidate_vs_protected_win_delta"], -3)
        self.assertEqual(feedback["best_candidate_vs_immediate_base_win_delta"], 2)
        self.assertEqual(feedback["unexercised_added_cards"], ["Call Forth the Tempest"])


if __name__ == "__main__":
    unittest.main()
