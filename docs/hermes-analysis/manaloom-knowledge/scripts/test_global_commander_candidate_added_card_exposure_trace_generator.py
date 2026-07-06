#!/usr/bin/env python3
"""Tests for candidate added-card exposure trace generation."""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

import global_commander_candidate_added_card_exposure_trace_generator as generator


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
                "deck_diff": {"added_cards": ["Pyromancer's Goggles", "Bant Panorama"]},
                "replay": {
                    "added_cards_unexercised_in_events": [
                        "Pyromancer's Goggles",
                        "Bant Panorama",
                    ]
                },
            }
        ),
        encoding="utf-8",
    )
    return path


class GlobalCommanderCandidateAddedCardExposureTraceGeneratorTests(unittest.TestCase):
    def test_forced_access_exercise_is_diagnostic_not_natural_gate(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
            Path(env["REPLAY_EVENTS_OUT"]).write_text(
                "\n".join(
                    [
                        json.dumps(
                            {
                                "event": "forced_focus_access_applied",
                                "player": "Lorehold",
                                "card": "Pyromancer's Goggles",
                                "status": "moved",
                            }
                        ),
                        json.dumps(
                            {
                                "event": "utility_artifact_activated",
                                "player": "Lorehold",
                                "card": "Pyromancer's Goggles",
                                "turn": 3,
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

        self.assertEqual(payload["status"], "candidate_added_card_forced_exposure_blocks_battle_gate")
        self.assertEqual(payload["summary"]["exercised_added_cards"], ["Pyromancer's Goggles"])
        self.assertIn("Bant Panorama", payload["summary"]["unexercised_added_cards"])
        self.assertFalse(payload["natural_gate_satisfied_now"])
        self.assertFalse(payload["promotion_allowed"])

    def test_forced_access_without_exercise_blocks_gate(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
            Path(env["REPLAY_EVENTS_OUT"]).write_text(
                json.dumps(
                    {
                        "event": "forced_focus_access_applied",
                        "player": "Lorehold",
                        "card": "Pyromancer's Goggles",
                        "status": "moved",
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

        self.assertEqual(payload["status"], "candidate_added_card_forced_exposure_blocks_battle_gate")
        self.assertEqual(payload["summary"]["exercised_added_cards"], [])
        self.assertIn(
            "forced_access_unexercised_added_cards:Pyromancer's Goggles,Bant Panorama",
            payload["candidate_copy_blockers"],
        )
        self.assertEqual(
            payload["review_rows"][0]["status"],
            "forced_added_card_present_but_unexercised_blocks_gate",
        )

    def test_action_event_snapshot_mentions_are_not_exercise(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        events = root / "events.jsonl"
        decisions = root / "decisions.jsonl"
        events.write_text(
            json.dumps(
                {
                    "event": "land_played",
                    "player": "Lorehold",
                    "card": "Other Land",
                    "board_snapshot": [{"name": "Bant Panorama"}],
                }
            )
            + "\n",
            encoding="utf-8",
        )
        decisions.write_text("", encoding="utf-8")

        summary = generator.summarize_trace_files(
            events_path=events,
            decisions_path=decisions,
            card_names=["Bant Panorama"],
            target_player="Lorehold, the Historian",
        )

        self.assertEqual(summary["cards"]["Bant Panorama"]["exercise_event_count"], 0)
        self.assertEqual(summary["cards"]["Bant Panorama"]["reference_event_count"], 1)


if __name__ == "__main__":
    unittest.main()
