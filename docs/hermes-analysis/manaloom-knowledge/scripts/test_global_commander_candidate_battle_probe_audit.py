#!/usr/bin/env python3
"""Tests for global Commander candidate battle probe audit."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_candidate_battle_probe_audit as audit


class GlobalCommanderCandidateBattleProbeAuditTests(unittest.TestCase):
    def _db(self, path: Path, cards: list[tuple[str, int]]) -> None:
        conn = sqlite3.connect(path)
        conn.execute(
            """
            CREATE TABLE deck_cards (
              deck_id INTEGER,
              card_name TEXT,
              quantity INTEGER,
              is_commander INTEGER
            )
            """
        )
        conn.executemany(
            "INSERT INTO deck_cards VALUES (619, ?, 1, ?)",
            cards,
        )
        conn.commit()
        conn.close()

    def _metrics(self, path: Path, *, wins: int, losses: int, win_rate: float) -> None:
        path.write_text(
            json.dumps(
                {
                    "metadata": {
                        "wins": wins,
                        "losses": losses,
                        "stalls": 0,
                        "total_games": wins + losses,
                        "games_per_opponent": 1,
                        "opponents": wins + losses,
                        "opponent_kind": "real",
                        "evaluation_mode": "target-deck-under-pressure",
                        "evaluation_target_player": "Kaalia of the Vast",
                        "win_rate": win_rate,
                    },
                    "event_counts": {},
                    "warnings": [],
                }
            ),
            encoding="utf-8",
        )

    def test_probe_blocks_promotion_when_candidate_loses_and_added_card_not_exercised(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        base_db = root / "base.db"
        candidate_db = root / "candidate.db"
        self._db(base_db, [("Kaalia of the Vast", 1), ("Old Card", 0)])
        self._db(candidate_db, [("Kaalia of the Vast", 1), ("Terminate", 0)])
        base_metrics = root / "base_metrics.json"
        candidate_metrics = root / "candidate_metrics.json"
        self._metrics(base_metrics, wins=2, losses=1, win_rate=66.666)
        self._metrics(candidate_metrics, wins=1, losses=2, win_rate=33.333)
        replay_dir = root / "replay"
        replay_dir.mkdir()
        (replay_dir / "deck_provenance.json").write_text(
            json.dumps({"decks": [{"name": "Kaalia of the Vast"}]}),
            encoding="utf-8",
        )
        (replay_dir / "replay.events.jsonl").write_text(
            json.dumps({"event": "turn_start", "player": "Kaalia of the Vast"}) + "\n",
            encoding="utf-8",
        )
        (replay_dir / "replay.decision_trace.jsonl").write_text(
            json.dumps({"actual_outcome": "mulligan", "alternatives_considered": [{"name": "Terminate"}]}) + "\n",
            encoding="utf-8",
        )

        payload = audit.build_payload(
            base_db=base_db,
            candidate_db=candidate_db,
            deck_id=619,
            base_metrics=base_metrics,
            candidate_metrics=candidate_metrics,
            replay_dir=replay_dir,
        )

        self.assertEqual(payload["status"], "battle_probe_blocks_promotion")
        self.assertFalse(payload["promotion_allowed"])
        self.assertEqual(payload["deck_diff"]["added_cards"], ["Terminate"])
        self.assertEqual(payload["deck_diff"]["cut_cards"], ["Old Card"])
        self.assertIn("candidate_underperformed_base_probe", payload["blocker_reasons"])
        self.assertIn("added_cards_not_exercised_in_replay_events", payload["blocker_reasons"])
        self.assertEqual(payload["replay"]["stale_lorehold_mentions"], 0)
        self.assertEqual(payload["replay"]["added_cards_decision_only"], ["Terminate"])
        self.assertIn("3-game equal-sample", payload["policy"]["battle_sample"])

    def test_focus_snapshot_mentions_do_not_count_as_exercised_added_cards(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        base_db = root / "base.db"
        candidate_db = root / "candidate.db"
        self._db(base_db, [("Kaalia of the Vast", 1), ("Old Card", 0)])
        self._db(candidate_db, [("Kaalia of the Vast", 1), ("Terminate", 0)])
        base_metrics = root / "base_metrics.json"
        candidate_metrics = root / "candidate_metrics.json"
        self._metrics(base_metrics, wins=1, losses=1, win_rate=50.0)
        self._metrics(candidate_metrics, wins=2, losses=0, win_rate=100.0)
        replay_dir = root / "replay"
        replay_dir.mkdir()
        (replay_dir / "deck_provenance.json").write_text(
            json.dumps({"decks": [{"name": "Kaalia of the Vast"}]}),
            encoding="utf-8",
        )
        (replay_dir / "replay.events.jsonl").write_text(
            json.dumps(
                {
                    "event": "focus_card_access_snapshot",
                    "focus_card_zones": {"Terminate": {"zone": "library"}},
                }
            )
            + "\n",
            encoding="utf-8",
        )
        (replay_dir / "replay.decision_trace.jsonl").write_text("", encoding="utf-8")

        payload = audit.build_payload(
            base_db=base_db,
            candidate_db=candidate_db,
            deck_id=619,
            base_metrics=base_metrics,
            candidate_metrics=candidate_metrics,
            replay_dir=replay_dir,
        )

        self.assertEqual(payload["status"], "battle_probe_blocks_promotion")
        self.assertEqual(payload["replay"]["added_cards_exercised_in_events"], [])
        self.assertEqual(payload["replay"]["added_cards_seen_without_exercise"], ["Terminate"])
        self.assertEqual(payload["replay"]["added_cards_unexercised_in_events"], ["Terminate"])
        self.assertIn("added_cards_not_exercised_in_replay_events", payload["blocker_reasons"])


if __name__ == "__main__":
    unittest.main()
