#!/usr/bin/env python3
import unittest

import master_optimizer_gate_baseline as gate_baseline


class MasterOptimizerGateBaselineTests(unittest.TestCase):
    def test_gate_stats_uses_table_intent_wins_and_seed_count(self) -> None:
        stats = gate_baseline.gate_stats(
            {
                "seeds_completed": 16,
                "mandatory_gate_statuses": {
                    "table_intent": {
                        "target_wins": 2,
                        "opponent_wins": 14,
                    }
                },
            }
        )

        self.assertEqual(stats["wins"], 2)
        self.assertEqual(stats["losses"], 14)
        self.assertEqual(stats["stalls"], 0)
        self.assertEqual(stats["total_games"], 16)
        self.assertEqual(stats["wr"], 12.5)

    def test_gate_stats_supports_top_level_table_intent_fields(self) -> None:
        stats = gate_baseline.gate_stats(
            {
                "table_intent_target_wins": 3,
                "table_intent_opponent_wins": 12,
            }
        )

        self.assertEqual(stats["wins"], 3)
        self.assertEqual(stats["losses"], 12)
        self.assertEqual(stats["stalls"], 0)
        self.assertEqual(stats["total_games"], 15)
        self.assertEqual(stats["wr"], 20.0)


if __name__ == "__main__":
    unittest.main()
