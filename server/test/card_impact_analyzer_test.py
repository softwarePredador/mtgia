#!/usr/bin/env python3
"""Tests for Commander-safe replay card impact scorecards."""

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = ROOT / "bin" / "card_impact_analyzer.py"
sys.path.insert(0, str(ROOT / "bin"))


spec = importlib.util.spec_from_file_location("card_impact_analyzer_under_test", SCRIPT_PATH)
card_impact_analyzer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(card_impact_analyzer)


class CardImpactAnalyzerTest(unittest.TestCase):
    def test_replay_scorecard_reports_seen_cast_and_baseline_metrics(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            replay_dir = Path(tmp)
            self._write_replay(
                replay_dir / "game_1.jsonl",
                [
                    {"event": "spell_cast", "player": "Lorehold", "card": "Sol Ring"},
                    {"event": "game_won", "player": "Lorehold", "reason": "elimination"},
                ],
            )
            self._write_replay(
                replay_dir / "game_2.jsonl",
                [
                    {
                        "event": "lorehold_upkeep_rummage",
                        "player": "Lorehold",
                        "drawn": "Reforge the Soul",
                    },
                    {"event": "spell_cast", "player": "Lorehold", "card": "Lightning Greaves"},
                    {"event": "player_eliminated", "player": "Lorehold", "reason": "life_zero"},
                ],
            )
            self._write_replay(
                replay_dir / "game_3.jsonl",
                [
                    {"event": "spell_cast", "player": "Opponent", "card": "Sol Ring"},
                    {"event": "game_won", "player": "Lorehold", "reason": "approach"},
                ],
            )

            stats = card_impact_analyzer._compute_from_replays(
                str(replay_dir),
                deck_name="Lorehold",
                min_seen=1,
                baseline_hash="baseline-test",
                min_usable_sample=2,
            )

        self.assertEqual(stats["Sol Ring"]["seen"], 1)
        self.assertEqual(stats["Sol Ring"]["cast"], 1)
        self.assertEqual(stats["Sol Ring"]["seen_wr"], 100.0)
        self.assertEqual(stats["Sol Ring"]["not_seen_wr"], 50.0)
        self.assertEqual(stats["Sol Ring"]["cast_wr"], 100.0)
        self.assertEqual(stats["Sol Ring"]["not_cast_wr"], 50.0)
        self.assertEqual(stats["Sol Ring"]["delta_vs_baseline"], 33.3)
        self.assertEqual(stats["Sol Ring"]["delta_seen_vs_not_seen"], 50.0)
        self.assertEqual(stats["Sol Ring"]["baseline_wr"], 66.7)
        self.assertEqual(stats["Sol Ring"]["baseline_hash"], "baseline-test")
        self.assertEqual(stats["Sol Ring"]["sample_quality"], "low_sample")

        self.assertEqual(stats["Reforge the Soul"]["seen"], 1)
        self.assertEqual(stats["Reforge the Soul"]["cast"], 0)
        self.assertEqual(stats["Reforge the Soul"]["seen_wr"], 0.0)
        self.assertIsNone(stats["Reforge the Soul"]["cast_wr"])
        self.assertEqual(stats["Reforge the Soul"]["not_seen_wr"], 100.0)

    def test_scorecard_summary_blocks_low_sample_conclusions(self) -> None:
        stats = {
            "Sol Ring": {
                "sample_quality": "low_sample",
                "baseline_wr": 66.7,
                "baseline_hash": "baseline-test",
            },
            "Reforge the Soul": {
                "sample_quality": "low_sample",
                "baseline_wr": 66.7,
                "baseline_hash": "baseline-test",
            },
        }

        summary = card_impact_analyzer._build_scorecard_summary(stats)

        self.assertEqual(summary["status"], "needs_more_samples")
        self.assertEqual(summary["usable_cards"], 0)
        self.assertEqual(summary["low_sample_cards"], 2)
        self.assertIn("no_usable_card_samples", summary["blockers"])
        self.assertFalse(summary["policy"]["auto_apply"])

    def test_scorecard_summary_trusts_usable_corpus_only(self) -> None:
        stats = {
            "Sol Ring": {
                "sample_quality": "usable",
                "baseline_wr": 66.7,
                "baseline_hash": "baseline-test",
            },
            "Reforge the Soul": {
                "sample_quality": "usable",
                "baseline_wr": 66.7,
                "baseline_hash": "baseline-test",
            },
        }

        summary = card_impact_analyzer._build_scorecard_summary(stats)

        self.assertEqual(summary["status"], "trusted")
        self.assertEqual(summary["usable_cards"], 2)
        self.assertEqual(summary["blockers"], [])

    def _write_replay(self, path: Path, events: list[dict]) -> None:
        path.write_text(
            "\n".join(json.dumps(event, sort_keys=True) for event in events) + "\n",
            encoding="utf-8",
        )


if __name__ == "__main__":
    unittest.main()
