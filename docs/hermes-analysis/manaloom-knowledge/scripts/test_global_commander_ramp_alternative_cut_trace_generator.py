#!/usr/bin/env python3
"""Tests for alternative ramp cut trace generation."""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

import global_commander_ramp_alternative_cut_trace_generator as generator


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def recovery_payload(root: Path) -> dict[str, object]:
    db = root / "knowledge.db"
    db.write_text("", encoding="utf-8")
    return {
        "deck_id": "619",
        "commander": "Kaalia of the Vast",
        "input_artifacts": {"source_db": str(db)},
        "alternative_cut_rows": [
            {
                "card_name": "Pyretic Ritual",
                "status": "alternative_cut_needs_current_scope_trace",
            },
            {
                "card_name": "Sol Ring",
                "status": "alternative_cut_blocked_premium_ramp_staple",
            },
        ],
    }


class GlobalCommanderRampAlternativeCutTraceGeneratorTests(unittest.TestCase):
    def test_usage_blocks_alternative_cut(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            recovery = write_json(root, "recovery.json", recovery_payload(root))

            def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
                Path(env["REPLAY_EVENTS_OUT"]).write_text(
                    json.dumps(
                        {
                            "event": "spell_cast",
                            "player": "Kaalia of the Vast",
                            "card": "Pyretic Ritual",
                            "turn": 3,
                        }
                    )
                    + "\n",
                    encoding="utf-8",
                )
                Path(env["DECISION_TRACE_OUT"]).write_text("", encoding="utf-8")
                Path(env["REPLAY_OUT"]).write_text("ok", encoding="utf-8")
                Path(env["REPLAY_DECK_PROVENANCE_OUT"]).write_text("{}", encoding="utf-8")
                return subprocess.CompletedProcess(cmd, 0, stdout="ok", stderr="")

            report = generator.build_report(
                recovery_report=recovery,
                battle_replay=root / "battle.py",
                replay_dir=root / "replays",
                seed_start=1,
                seed_count=1,
                runner=runner,
            )

        self.assertEqual(report["status"], "ramp_alternative_cut_trace_blocks_used_targets")
        self.assertEqual(report["summary"]["focus_cards"], ["Pyretic Ritual"])
        self.assertEqual(report["summary"]["usage_blocked_count"], 1)
        self.assertEqual(
            report["review_rows"][0]["status"],
            "alternative_ramp_cut_natural_trace_usage_observed_blocks_cut",
        )
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_no_exposure_requires_more_trace(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            recovery = write_json(root, "recovery.json", recovery_payload(root))

            def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
                Path(env["REPLAY_EVENTS_OUT"]).write_text("", encoding="utf-8")
                Path(env["DECISION_TRACE_OUT"]).write_text("", encoding="utf-8")
                Path(env["REPLAY_OUT"]).write_text("ok", encoding="utf-8")
                Path(env["REPLAY_DECK_PROVENANCE_OUT"]).write_text("{}", encoding="utf-8")
                return subprocess.CompletedProcess(cmd, 0, stdout="ok", stderr="")

            report = generator.build_report(
                recovery_report=recovery,
                battle_replay=root / "battle.py",
                replay_dir=root / "replays",
                seed_start=1,
                seed_count=1,
                runner=runner,
            )

        self.assertEqual(report["status"], "ramp_alternative_cut_trace_needs_force_access_or_more_trace")
        self.assertEqual(report["summary"]["no_exposure_count"], 1)
        self.assertEqual(
            report["review_rows"][0]["status"],
            "alternative_ramp_cut_no_current_exposure_needs_force_access_or_more_trace",
        )
        self.assertIn("candidate_copy_closed_after_alternative_ramp_cut_trace", report["candidate_copy_blockers"])


if __name__ == "__main__":
    unittest.main()
