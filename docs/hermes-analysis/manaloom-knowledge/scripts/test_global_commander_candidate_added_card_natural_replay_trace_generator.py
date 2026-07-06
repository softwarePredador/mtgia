#!/usr/bin/env python3
"""Tests for candidate added-card natural replay trace generation."""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

import global_commander_candidate_added_card_natural_replay_trace_generator as generator


def write_audit(root: Path) -> Path:
    db = root / "candidate.db"
    db.write_text("", encoding="utf-8")
    path = root / "audit.json"
    path.write_text(
        json.dumps(
            {
                "status": "battle_probe_blocks_promotion",
                "deck_id": 612,
                "commander": "Lorehold, the Historian",
                "input_artifacts": {"candidate_db": str(db)},
                "replay": {
                    "added_cards_unexercised_in_events": [
                        "Bant Panorama",
                        "Pyromancer's Goggles",
                    ]
                },
            }
        ),
        encoding="utf-8",
    )
    return path


class GlobalCommanderCandidateAddedCardNaturalReplayTraceGeneratorTests(unittest.TestCase):
    def test_natural_replay_all_exercised_opens_larger_gate_next(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
            self.assertNotIn("MANALOOM_FORCE_FOCUS_ACCESS_MODE", env)
            Path(env["REPLAY_EVENTS_OUT"]).write_text(
                "\n".join(
                    [
                        json.dumps(
                            {
                                "event": "land_played",
                                "player": "Lorehold",
                                "card": "Bant Panorama",
                                "turn": 3,
                            }
                        ),
                        json.dumps(
                            {
                                "event": "cast_announced",
                                "player": "Lorehold",
                                "card": "Pyromancer's Goggles",
                                "turn": 5,
                            }
                        ),
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            Path(env["DECISION_TRACE_OUT"]).write_text("", encoding="utf-8")
            Path(env["REPLAY_OUT"]).write_text("ok", encoding="utf-8")
            Path(env["REPLAY_DECK_PROVENANCE_OUT"]).write_text("{}", encoding="utf-8")
            return subprocess.CompletedProcess(cmd, 0, stdout="ok", stderr="")

        payload = generator.build_report(
            battle_probe_audit=write_audit(root),
            replay_dir=root / "replays",
            seed_start=1,
            seed_count=1,
            runner=runner,
        )

        self.assertEqual(
            payload["status"],
            "candidate_added_card_natural_replay_all_exercised_ready_for_larger_gate",
        )
        self.assertTrue(payload["larger_battle_gate_allowed_next"])
        self.assertFalse(payload["promotion_allowed"])
        self.assertEqual(payload["summary"]["unexercised_added_cards"], [])

    def test_natural_replay_seen_without_exercise_blocks_larger_gate(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
            Path(env["REPLAY_EVENTS_OUT"]).write_text(
                json.dumps(
                    {
                        "event": "focus_card_access_snapshot",
                        "player": "Lorehold",
                        "focus_card_zones": {"Bant Panorama": {"zone": "library"}},
                    }
                )
                + "\n",
                encoding="utf-8",
            )
            Path(env["DECISION_TRACE_OUT"]).write_text("", encoding="utf-8")
            Path(env["REPLAY_OUT"]).write_text("ok", encoding="utf-8")
            Path(env["REPLAY_DECK_PROVENANCE_OUT"]).write_text("{}", encoding="utf-8")
            return subprocess.CompletedProcess(cmd, 0, stdout="ok", stderr="")

        payload = generator.build_report(
            battle_probe_audit=write_audit(root),
            replay_dir=root / "replays",
            seed_start=1,
            seed_count=1,
            runner=runner,
        )

        self.assertEqual(payload["status"], "candidate_added_card_natural_replay_blocks_larger_gate")
        self.assertFalse(payload["larger_battle_gate_allowed_next"])
        self.assertIn(
            "natural_replay_unexercised_added_cards:Bant Panorama,Pyromancer's Goggles",
            payload["larger_gate_blockers"],
        )


if __name__ == "__main__":
    unittest.main()
