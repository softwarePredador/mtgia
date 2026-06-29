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
                "structural_rank": {"deck_607": 1, "deck_614": 3, "deck_615": 2}[deck_key],
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
    def build_report(self, payloads: list[dict]) -> dict:
        with tempfile.TemporaryDirectory() as tmp:
            paths = []
            for index, payload in enumerate(payloads):
                path = Path(tmp) / f"gate_{index}.json"
                path.write_text(json.dumps(payload), encoding="utf-8")
                paths.append(path)
            return audit.build_report(paths)

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


if __name__ == "__main__":
    unittest.main()
