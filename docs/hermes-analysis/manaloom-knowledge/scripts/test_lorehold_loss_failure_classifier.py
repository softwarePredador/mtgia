import json
import tempfile
import unittest
from pathlib import Path

import lorehold_loss_failure_classifier as classifier


def game(
    *,
    game_id="deck_6:Opponent:0",
    result="loss",
    turns=6,
    event_counts=None,
    strategic_event_counts=None,
    reason="life_zero|found=False|countered=0",
):
    return {
        "game_id": game_id,
        "game_index": 0,
        "opponent": "Opponent",
        "opponent_archetype": "aggro",
        "picked_opponents": ["Opponent"],
        "result": result,
        "turns": turns,
        "reason": reason,
        "event_counts": event_counts or {},
        "strategic_event_counts": strategic_event_counts or {},
    }


class LoreholdLossFailureClassifierTest(unittest.TestCase):
    def test_approach_event_overrides_stale_reason_text(self):
        row = game(
            turns=10,
            event_counts={
                "approach_cast_tracked": 1,
                "approach_first_resolution": 1,
                "combat": 12,
                "combat_result": 12,
                "player_eliminated": 1,
            },
            strategic_event_counts={
                "discard_to_top_replacement": 4,
                "lorehold_spell_cast": 8,
            },
            reason="life_zero|found=False|countered=0",
        )

        result = classifier.classify_loss(row)

        self.assertEqual(
            result["primary_cause"],
            "second_approach_window_failed_under_pressure",
        )
        self.assertIn("approach_seen", result["flags"])
        self.assertIn("combat_pressure_death", result["flags"])

    def test_discard_to_top_without_miracle_is_separate_from_missing_engine(self):
        row = game(
            turns=9,
            event_counts={"combat": 10, "combat_result": 10, "player_eliminated": 1},
            strategic_event_counts={
                "discard_to_top_replacement": 3,
                "lorehold_rummage_discard_to_top": 3,
                "lorehold_spell_cast": 7,
            },
        )

        result = classifier.classify_loss(row)

        self.assertEqual(
            result["primary_cause"],
            "topdeck_without_miracle_conversion_under_pressure",
        )
        self.assertIn("discard_to_top_seen", result["flags"])
        self.assertIn("miracle_missing", result["flags"])

    def test_collect_loss_rows_dedupes_repeated_baseline_but_keeps_candidates(self):
        payload_a = {
            "simulation_seed": 7,
            "results": [
                {
                    "deck_key": "deck_6",
                    "game_results": [game(game_id="deck_6:Opponent:0")],
                },
                {
                    "deck_key": "synergy_a",
                    "game_results": [game(game_id="synergy_a:Opponent:0")],
                },
            ],
        }
        payload_b = {
            "simulation_seed": 7,
            "results": [
                {
                    "deck_key": "deck_6",
                    "game_results": [game(game_id="deck_6:Opponent:0")],
                },
                {
                    "deck_key": "synergy_b",
                    "game_results": [game(game_id="synergy_b:Opponent:0")],
                },
            ],
        }
        with tempfile.TemporaryDirectory() as tmp:
            path_a = Path(tmp) / "a.json"
            path_b = Path(tmp) / "b.json"
            path_a.write_text(json.dumps(payload_a), encoding="utf-8")
            path_b.write_text(json.dumps(payload_b), encoding="utf-8")

            rows = classifier.collect_loss_rows([path_a, path_b])

        self.assertEqual(len(rows), 3)
        self.assertEqual(
            sorted(row["package_key"] for row in rows),
            ["a", "b", "baseline_squee_champion"],
        )

    def test_default_gate_paths_include_versioned_topfreecast_details_only(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            detailed_v1 = tmp_path / "lorehold_topfreecast_conversion_gate_20260627_seed42_v1_topfreecast_v1_galvanoth.json"
            detailed_v2 = tmp_path / "lorehold_topfreecast_conversion_gate_20260627_seed42_v2_topfreecast_v2_galvanoth.json"
            detailed_spell_land = tmp_path / "lorehold_spell_protection_land_gate_20260627_seed42_v1_spell_protection_land_v1_boseiju.json"
            summary_v2 = tmp_path / "lorehold_topfreecast_conversion_gate_20260627_seed42_v2_topfreecast_v2.json"
            detailed_v1.write_text("{}", encoding="utf-8")
            detailed_v2.write_text("{}", encoding="utf-8")
            detailed_spell_land.write_text("{}", encoding="utf-8")
            summary_v2.write_text("{}", encoding="utf-8")

            original = classifier.REPORT_DIR
            classifier.REPORT_DIR = tmp_path
            try:
                paths = classifier.default_gate_paths()
            finally:
                classifier.REPORT_DIR = original

        self.assertIn(detailed_v1, paths)
        self.assertIn(detailed_v2, paths)
        self.assertIn(detailed_spell_land, paths)
        self.assertNotIn(summary_v2, paths)


if __name__ == "__main__":
    unittest.main()
