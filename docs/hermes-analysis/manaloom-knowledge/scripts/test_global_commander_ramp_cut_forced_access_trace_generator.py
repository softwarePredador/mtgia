#!/usr/bin/env python3
"""Tests for ramp cut forced-access trace generation."""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

import global_commander_ramp_cut_forced_access_trace_generator as generator


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def ramp_trace_payload(root: Path) -> dict[str, object]:
    db = root / "knowledge.db"
    battle = root / "battle_replay.py"
    db.write_text("", encoding="utf-8")
    battle.write_text("", encoding="utf-8")
    return {
        "deck_id": "619",
        "commander": "Kaalia of the Vast",
        "input_artifacts": {
            "source_db": str(db),
            "battle_replay": str(battle),
        },
        "trace_review_rows": [
            {
                "card_name": "Culling the Weak",
                "status": "ramp_cut_natural_trace_no_target_exposure_needs_force_access",
            },
            {
                "card_name": "Basalt Monolith",
                "status": "ramp_cut_natural_trace_usage_observed_blocks_cut",
            },
        ],
    }


class GlobalCommanderRampCutForcedAccessTraceGeneratorTests(unittest.TestCase):
    def test_forced_access_usage_blocks_ramp_cut(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            ramp_trace = write_json(root, "ramp_trace.json", ramp_trace_payload(root))

            def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
                Path(env["REPLAY_EVENTS_OUT"]).write_text(
                    "\n".join(
                        [
                            json.dumps(
                                {
                                    "event": "forced_focus_access_applied",
                                    "player": "Kaalia of the Vast",
                                    "card": "Culling the Weak",
                                    "status": "moved",
                                    "mode": "opening_hand",
                                }
                            ),
                            json.dumps(
                                {
                                    "event": "spell_cast",
                                    "player": "Kaalia of the Vast",
                                    "card": "Culling the Weak",
                                    "turn": 2,
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

            report = generator.build_report(
                ramp_trace_report=ramp_trace,
                replay_dir=root / "replays",
                seed_start=1,
                seed_count=1,
                runner=runner,
            )

        self.assertEqual(report["status"], "ramp_cut_forced_access_trace_blocks_used_unexposed_cuts")
        self.assertEqual(report["summary"]["focus_cards"], ["Culling the Weak"])
        self.assertEqual(report["summary"]["usage_blocked_count"], 1)
        self.assertEqual(
            report["review_rows"][0]["status"],
            "ramp_cut_forced_access_usage_observed_blocks_cut",
        )
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])

    def test_forced_access_without_usage_needs_manual_review(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            ramp_trace = write_json(root, "ramp_trace.json", ramp_trace_payload(root))

            def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
                Path(env["REPLAY_EVENTS_OUT"]).write_text(
                    json.dumps(
                        {
                            "event": "forced_focus_access_applied",
                            "player": "Kaalia of the Vast",
                            "card": "Culling the Weak",
                            "status": "moved",
                            "mode": "opening_hand",
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
                ramp_trace_report=ramp_trace,
                replay_dir=root / "replays",
                seed_start=1,
                seed_count=1,
                runner=runner,
            )

        self.assertEqual(report["status"], "ramp_cut_forced_access_trace_needs_manual_negative_review")
        self.assertEqual(report["summary"]["manual_review_count"], 1)
        self.assertEqual(
            report["review_rows"][0]["status"],
            "ramp_cut_forced_access_available_but_no_usage_blocks_cut_clearance",
        )
        self.assertIn("candidate_copy_closed_after_ramp_forced_access_trace", report["candidate_copy_blockers"])


if __name__ == "__main__":
    unittest.main()
