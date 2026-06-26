import unittest
from tempfile import TemporaryDirectory
from pathlib import Path

import lorehold_variant_battle_gate as gate


class LoreholdVariantBattleGateTest(unittest.TestCase):
    def test_gate_telemetry_counts_lorehold_strategy_events(self):
        telemetry = gate.GateTelemetry()
        telemetry.begin("game-1")
        telemetry.record("miracle_cast", {"player": "Lorehold", "card": "Austere Command"})
        telemetry.record("cost_paid", {"player": "Lorehold", "card": "Sol Ring"})
        telemetry.record("spell_cast", {"player": "Opponent", "card": "Counterspell"})
        telemetry.record("topdeck_manipulation_activated", {"player": "Lorehold", "card": "Scroll Rack"})

        payload = telemetry.as_json(2)

        self.assertEqual(payload["strategic_event_counts"]["miracle_cast"], 1)
        self.assertEqual(payload["strategic_games"]["miracle_cast"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["miracle_cast"]["rate"], 0.5)
        self.assertNotIn("lorehold_spell_cast", payload["strategic_event_counts"])

    def test_merge_structural_context_assigns_battle_rank(self):
        results = [
            {"deck_key": "deck_6", "win_rate": 10, "losses": 3, "stalls": 0},
            {"deck_key": "candidate_v7", "win_rate": 30, "losses": 2, "stalls": 1},
        ]
        merged = gate.merge_structural_context(
            results,
            {
                "deck_6": {"structural_rank": 2, "strategy_score": 138.2},
                "candidate_v7": {"structural_rank": 1, "strategy_score": 141.7},
            },
        )

        by_key = {row["deck_key"]: row for row in merged}
        self.assertEqual(by_key["candidate_v7"]["battle_rank"], 1)
        self.assertEqual(by_key["candidate_v7"]["structural_rank"], 1)
        self.assertEqual(by_key["deck_6"]["battle_rank"], 2)

    def test_write_game_checkpoint_persists_latest_progress(self):
        with TemporaryDirectory() as tmpdir:
            payload = {
                "generated_at": "2026-06-26T00:00:00Z",
                "status": "running",
                "stem": "checkpoint_test",
                "completed_games": 1,
                "total_games": 3,
                "game_timeout_seconds": 30.0,
                "latest": {
                    "deck_key": "deck_607",
                    "opponent": "Winota",
                    "last_result": "stall",
                    "last_turns": 8,
                    "last_reason": "game_timeout_30.0s",
                },
                "events": [
                    {
                        "completed_games": 1,
                        "deck_key": "deck_607",
                        "opponent": "Winota",
                        "last_result": "stall",
                        "last_turns": 8,
                        "last_reason": "game_timeout_30.0s",
                    }
                ],
            }
            json_path, md_path = gate.write_game_checkpoint(
                payload,
                "checkpoint_test",
                report_dir=Path(tmpdir),
            )

            self.assertTrue(json_path.exists())
            self.assertTrue(md_path.exists())
            self.assertIn("game_timeout_30.0s", md_path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
