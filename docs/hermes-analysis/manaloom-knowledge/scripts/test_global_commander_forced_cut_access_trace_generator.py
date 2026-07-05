#!/usr/bin/env python3
"""Tests for forced cut-access trace generation."""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

import global_commander_forced_cut_access_trace_generator as generator


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def collector_payload() -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "review_rows": [
            {
                "cut_card": "Dark Ritual",
                "status": "remaining_cut_not_seen_needs_forced_access_or_more_trace",
            },
            {
                "cut_card": "Sunforger",
                "status": "remaining_cut_used_by_target_trace_blocks_value_safe",
            },
        ],
    }


def trace_payload(root: Path) -> dict[str, object]:
    db = root / "knowledge.db"
    battle = root / "battle_replay.py"
    db.write_text("", encoding="utf-8")
    battle.write_text("", encoding="utf-8")
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "input_artifacts": {
            "selected_db": str(db),
            "battle_replay": str(battle),
        },
    }


class GlobalCommanderForcedCutAccessTraceGeneratorTests(unittest.TestCase):
    def test_forced_access_usage_blocks_value_safe_reclassification(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        collector = write_json(root, "collector.json", collector_payload())
        trace = write_json(root, "trace.json", trace_payload(root))

        def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
            Path(env["REPLAY_EVENTS_OUT"]).write_text(
                "\n".join(
                    [
                        json.dumps(
                            {
                                "event": "forced_focus_access_applied",
                                "player": "Kaalia of the Vast",
                                "card": "Dark Ritual",
                                "status": "moved",
                                "mode": "opening_hand",
                            }
                        ),
                        json.dumps(
                            {
                                "event": "spell_cast",
                                "player": "Kaalia of the Vast",
                                "card": "Dark Ritual",
                                "turn": 1,
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
            cut_trace_collector_report=collector,
            trace_generator_report=trace,
            replay_dir=root / "replays",
            seed_start=1,
            seed_count=1,
            runner=runner,
        )

        self.assertEqual(payload["status"], "forced_cut_access_trace_blocks_used_unresolved_cuts")
        self.assertEqual(payload["summary"]["focus_cards"], ["Dark Ritual"])
        self.assertEqual(payload["summary"]["usage_blocked_count"], 1)
        row = payload["review_rows"][0]
        self.assertEqual(row["status"], "forced_access_usage_observed_blocks_value_safe")
        self.assertFalse(payload["candidate_copy_allowed_now"])

    def test_forced_access_available_without_usage_needs_manual_review(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        collector = write_json(root, "collector.json", collector_payload())
        trace = write_json(root, "trace.json", trace_payload(root))

        def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
            Path(env["REPLAY_EVENTS_OUT"]).write_text(
                json.dumps(
                    {
                        "event": "forced_focus_access_applied",
                        "player": "Kaalia of the Vast",
                        "card": "Dark Ritual",
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

        payload = generator.build_report(
            cut_trace_collector_report=collector,
            trace_generator_report=trace,
            replay_dir=root / "replays",
            seed_start=1,
            seed_count=1,
            runner=runner,
        )

        self.assertEqual(payload["status"], "forced_cut_access_trace_needs_manual_negative_review")
        self.assertEqual(payload["summary"]["manual_review_count"], 1)
        self.assertEqual(
            payload["review_rows"][0]["status"],
            "forced_access_available_but_no_usage_blocks_reclassification",
        )
        self.assertFalse(payload["value_safe_reclassification_allowed_now"])


if __name__ == "__main__":
    unittest.main()
