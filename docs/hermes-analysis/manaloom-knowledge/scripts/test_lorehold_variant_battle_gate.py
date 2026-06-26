import unittest

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


if __name__ == "__main__":
    unittest.main()
