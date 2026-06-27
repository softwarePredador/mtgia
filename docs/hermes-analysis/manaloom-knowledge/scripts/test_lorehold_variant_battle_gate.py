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
        telemetry.record(
            "lorehold_upkeep_rummage",
            {
                "player": "Lorehold",
                "discarded": "Squee, Goblin Nabob",
                "discard_destination": "graveyard",
            },
        )
        telemetry.record(
            "trigger_resolved",
            {
                "player": "Lorehold",
                "card": "Monument to Endurance",
                "effect": "rummage",
                "discarded": "Squee, Goblin Nabob",
                "discarded_to_graveyard": ["Squee, Goblin Nabob"],
            },
        )
        telemetry.record(
            "permanent_moved_from_battlefield",
            {
                "player": "Lorehold",
                "card": "Squee, Goblin Nabob",
                "from_zone": "battlefield",
                "to_zone": "graveyard",
                "destination": "graveyard",
            },
        )
        telemetry.record(
            "trigger_resolved",
            {
                "player": "Lorehold",
                "card": "Squee, Goblin Nabob",
                "effect": "graveyard_upkeep_return_self_to_hand",
            },
        )
        telemetry.begin("game-2")
        telemetry.record(
            "trigger_resolved",
            {
                "player": "Lorehold",
                "card": "Squee, Goblin Nabob",
                "effect": "graveyard_upkeep_return_self_to_hand",
            },
        )

        payload = telemetry.as_json(2)

        self.assertEqual(payload["strategic_event_counts"]["miracle_cast"], 1)
        self.assertEqual(payload["strategic_event_counts"]["lorehold_upkeep_rummage"], 1)
        self.assertEqual(payload["strategic_event_counts"]["lorehold_rummage_discards_squee"], 1)
        self.assertEqual(payload["strategic_event_counts"]["lorehold_spell_rummage"], 1)
        self.assertEqual(payload["strategic_event_counts"]["lorehold_spell_rummage_discards_squee"], 1)
        self.assertEqual(payload["strategic_event_counts"]["squee_to_graveyard"], 3)
        self.assertEqual(payload["strategic_event_counts"]["squee_upkeep_return"], 2)
        self.assertEqual(payload["strategic_event_counts"]["squee_return_after_known_graveyard_entry"], 1)
        self.assertEqual(payload["strategic_event_counts"]["squee_return_without_known_graveyard_entry"], 1)
        self.assertEqual(payload["strategic_games"]["miracle_cast"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["miracle_cast"]["rate"], 0.5)
        self.assertEqual(payload["strategic_games"]["squee_upkeep_return"]["games"], 2)
        self.assertEqual(payload["strategic_games"]["squee_to_graveyard"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["squee_return_after_known_graveyard_entry"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["squee_return_without_known_graveyard_entry"]["games"], 1)
        self.assertEqual(payload["squee_known_graveyard_balance_by_game"]["game-1"], 2)
        self.assertEqual(payload["squee_anomalies"][0]["kind"], "squee_return_without_known_graveyard_entry")
        self.assertEqual(payload["squee_anomalies"][0]["game_id"], "game-2")
        self.assertIn("game-1", payload["squee_game_traces"])
        self.assertIn("game-2", payload["squee_game_traces"])
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

    def test_gate_telemetry_treats_milled_squee_as_graveyard_entry(self):
        telemetry = gate.GateTelemetry()
        telemetry.begin("game-mill")
        telemetry.record(
            "mill_resolved",
            {
                "player": "Opponent",
                "card": "Brain Freeze",
                "target_player": "Lorehold",
                "milled": ["Squee, Goblin Nabob", "Mountain"],
                "cards_milled": 2,
            },
        )
        telemetry.record(
            "trigger_resolved",
            {
                "player": "Lorehold",
                "card": "Squee, Goblin Nabob",
                "effect": "graveyard_upkeep_return_self_to_hand",
            },
        )

        payload = telemetry.as_json(1)

        self.assertEqual(payload["strategic_event_counts"]["squee_to_graveyard"], 1)
        self.assertEqual(payload["strategic_event_counts"]["squee_upkeep_return"], 1)
        self.assertEqual(payload["strategic_event_counts"]["squee_return_after_known_graveyard_entry"], 1)
        self.assertNotIn(
            "squee_return_without_known_graveyard_entry",
            payload["strategic_event_counts"],
        )
        self.assertEqual(payload["squee_known_graveyard_balance_by_game"]["game-mill"], 0)
        self.assertEqual(payload["squee_anomalies"], [])

    def test_gate_telemetry_does_not_count_spell_target_as_squee_graveyard_entry(self):
        telemetry = gate.GateTelemetry()
        telemetry.begin("game-target")
        telemetry.record(
            "spell_resolved",
            {
                "player": "Lorehold",
                "card": "Fated Clash",
                "target": "Squee, Goblin Nabob",
                "from_zone": "hand",
                "to_zone": "graveyard",
                "destination": "graveyard",
            },
        )
        telemetry.record(
            "trigger_resolved",
            {
                "player": "Lorehold",
                "card": "Squee, Goblin Nabob",
                "effect": "graveyard_upkeep_return_self_to_hand",
            },
        )

        payload = telemetry.as_json(1)

        self.assertNotIn("squee_to_graveyard", payload["strategic_event_counts"])
        self.assertEqual(payload["strategic_event_counts"]["squee_return_without_known_graveyard_entry"], 1)
        self.assertEqual(payload["squee_anomalies"][0]["game_id"], "game-target")

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
