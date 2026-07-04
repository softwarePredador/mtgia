#!/usr/bin/env python3
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import lorehold_promotion_gate_decision_audit as audit


def gate(seed: int, wins_by_deck: dict[str, int]) -> dict:
    results = []
    for deck_key, wins in wins_by_deck.items():
        games = 3
        results.append(
            {
                "deck_key": deck_key,
                "deck_name": deck_key,
                "archetype": "test",
                "structural_rank": {"deck_607": 1, "deck_614": 3, "deck_615": 2}.get(deck_key),
                "games": games,
                "wins": wins,
                "losses": games - wins,
                "stalls": 0,
                "avg_win_turn": 10,
                "win_reasons": {"elimination": wins} if wins else {},
                "opponents": [
                    {
                        "opponent": "Winota, Joiner of Forces #39 (real)",
                        "wins": wins,
                        "losses": games - wins,
                        "stalls": 0,
                    }
                ],
                "game_results": [
                    {"result": "win", "turns": 10}
                    for _ in range(wins)
                ]
                + [
                    {"result": "loss", "turns": 8}
                    for _ in range(games - wins)
                ],
                "telemetry": {
                    "strategic_games": {
                        "lorehold_spell_cast": {"games": games},
                        "miracle_cast": {"games": max(1, wins)},
                    },
                    "strategic_event_counts": {"lorehold_spell_cast": games},
                    "focus_card_access_summary": {},
                    "top_cards": [],
                },
            }
        )
    return {
        "status": "ready",
        "games_per_opponent": 3,
        "opponent_kind": "real",
        "opponent_seed": 20260626,
        "simulation_seed": seed,
        "forced_access_mode": "none",
        "deck_process_isolation": True,
        "opponents": ["Winota, Joiner of Forces #39 (real)"],
        "results": results,
    }


class LoreholdPromotionGateDecisionAuditTests(unittest.TestCase):
    def build_report(self, payloads: list[dict], candidate_keys: list[str] | None = None) -> dict:
        with tempfile.TemporaryDirectory() as tmp:
            paths = []
            for index, payload in enumerate(payloads):
                path = Path(tmp) / f"gate_{index}.json"
                path.write_text(json.dumps(payload), encoding="utf-8")
                paths.append(path)
            kwargs = {"candidate_keys": candidate_keys} if candidate_keys else {}
            return audit.build_report(paths, **kwargs)

    def test_keeps_baseline_when_challengers_do_not_beat_aggregate(self) -> None:
        report = self.build_report(
            [
                gate(1, {"deck_607": 2, "deck_614": 1, "deck_615": 2}),
                gate(2, {"deck_607": 2, "deck_614": 1, "deck_615": 1}),
            ]
        )

        self.assertEqual(report["decision"]["status"], "keep_protected_baseline")
        self.assertFalse(report["decision"]["ready_for_real_deck_change"])
        self.assertEqual(report["decision"]["promoted_deck_keys"], [])

    def test_promotes_when_challenger_clears_aggregate_seed_and_pressure(self) -> None:
        report = self.build_report(
            [
                gate(1, {"deck_607": 1, "deck_614": 1, "deck_615": 2}),
                gate(2, {"deck_607": 1, "deck_614": 1, "deck_615": 2}),
            ]
        )

        promoted = report["decision"]["promoted_deck_keys"]
        self.assertIn("deck_615", promoted)
        self.assertTrue(report["decision"]["ready_for_real_deck_change"])

    def test_assesses_explicit_candidate_key_outside_historical_challengers(self) -> None:
        report = self.build_report(
            [
                gate(1, {"deck_607": 1, "candidate_custom": 2}),
                gate(2, {"deck_607": 1, "candidate_custom": 2}),
            ],
            candidate_keys=["candidate_custom"],
        )

        self.assertEqual(report["decision"]["candidate_keys"], ["candidate_custom"])
        self.assertIn("candidate_custom", report["decision"]["promoted_deck_keys"])
        self.assertTrue(report["decision"]["ready_for_real_deck_change"])

    def test_blocks_explicit_candidate_that_loses_head_to_head_against_607(self) -> None:
        payload = gate(1, {"deck_607": 0, "candidate_custom": 1})
        payload["opponents"].append("Fixed Lorehold deck 607")
        candidate = next(row for row in payload["results"] if row["deck_key"] == "candidate_custom")
        candidate["opponents"].append(
            {
                "opponent": "Fixed Lorehold deck 607",
                "wins": 0,
                "losses": 1,
                "stalls": 0,
            }
        )

        report = self.build_report([payload], candidate_keys=["candidate_custom"])

        assessment = report["candidate_assessments"][0]
        self.assertEqual(report["decision"]["promoted_deck_keys"], [])
        self.assertFalse(report["decision"]["ready_for_real_deck_change"])
        self.assertIn("head-to-head vs protected 607 not won (0/1, losses=1)", assessment["blockers"])

    def test_card_use_metrics_are_aggregated_from_game_card_event_counts(self) -> None:
        payload = gate(1, {"deck_607": 1, "candidate_custom": 2})
        candidate = next(row for row in payload["results"] if row["deck_key"] == "candidate_custom")
        candidate["game_results"][0]["card_event_counts"] = {
            "cost_paid:Mana Vault": 2,
            "utility_artifact_activated:The One Ring": 3,
        }

        report = self.build_report([payload], candidate_keys=["candidate_custom"])
        metrics = report["deck_aggregates"]["candidate_custom"]["card_use_metrics"]

        self.assertEqual(metrics["Mana Vault"]["cost_paid"], 2)
        self.assertEqual(metrics["The One Ring"]["utility_artifact_activated"], 3)


if __name__ == "__main__":
    unittest.main()
