#!/usr/bin/env python3
"""Tests for reviewed external seeded forced-access trace generation."""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

import global_commander_reviewed_external_seeded_force_access_trace_generator as generator


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def seeded_trace_payload() -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast", "hypothesis_count": 2},
        "review_rows": [
            {
                "cut_card": "Basalt Monolith",
                "target_cut_role": "mana_acceleration",
                "source_score": 58,
                "source_reasons": ["fresh_same_lane_mana_acceleration"],
                "status": "reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace",
            },
            {
                "cut_card": "Monologue Tax",
                "target_cut_role": "mana_acceleration",
                "source_score": 58,
                "status": "reviewed_seeded_cut_hypothesis_used_by_target_trace_blocks_cut",
            },
        ],
    }


def trace_generator_payload(root: Path, *, db_exists: bool = True) -> dict[str, object]:
    db = root / "knowledge.db"
    battle = root / "battle_replay.py"
    if db_exists:
        db.write_text("", encoding="utf-8")
    battle.write_text("", encoding="utf-8")
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "input_artifacts": {
            "selected_db": str(db),
            "battle_replay": str(battle),
        },
    }


class GlobalCommanderReviewedExternalSeededForceAccessTraceGeneratorTests(unittest.TestCase):
    def test_forced_access_usage_blocks_seeded_hypothesis_cut(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        seeded = write_json(root, "seeded.json", seeded_trace_payload())
        trace = write_json(root, "trace.json", trace_generator_payload(root))

        def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
            Path(env["REPLAY_EVENTS_OUT"]).write_text(
                "\n".join(
                    [
                        json.dumps(
                            {
                                "event": "forced_focus_access_applied",
                                "player": "Kaalia of the Vast",
                                "card": "Basalt Monolith",
                                "status": "moved",
                                "mode": "opening_hand",
                            }
                        ),
                        json.dumps(
                            {
                                "event": "spell_cast",
                                "player": "Kaalia of the Vast",
                                "card": "Basalt Monolith",
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

        payload = generator.build_report(
            seeded_trace_collector_report=seeded,
            trace_generator_report=trace,
            replay_dir=root / "replays",
            seed_start=1,
            seed_count=1,
            runner=runner,
        )

        self.assertEqual(payload["status"], "reviewed_external_seeded_forced_access_blocks_used_hypotheses")
        self.assertEqual(payload["summary"]["focus_cards"], ["Basalt Monolith"])
        self.assertEqual(payload["summary"]["usage_blocked_count"], 1)
        self.assertEqual(
            payload["review_rows"][0]["status"],
            "reviewed_seeded_forced_access_usage_observed_blocks_cut",
        )
        self.assertFalse(payload["candidate_copy_allowed_now"])

    def test_forced_access_without_usage_still_does_not_open_cut_permission(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        seeded = write_json(root, "seeded.json", seeded_trace_payload())
        trace = write_json(root, "trace.json", trace_generator_payload(root))

        def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
            Path(env["REPLAY_EVENTS_OUT"]).write_text(
                json.dumps(
                    {
                        "event": "forced_focus_access_applied",
                        "player": "Kaalia of the Vast",
                        "card": "Basalt Monolith",
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
            seeded_trace_collector_report=seeded,
            trace_generator_report=trace,
            replay_dir=root / "replays",
            seed_start=1,
            seed_count=1,
            runner=runner,
        )

        self.assertEqual(payload["status"], "reviewed_external_seeded_forced_access_needs_negative_review")
        self.assertEqual(payload["summary"]["manual_review_count"], 1)
        self.assertEqual(
            payload["review_rows"][0]["status"],
            "reviewed_seeded_forced_access_available_but_no_usage_blocks_cut_permission",
        )
        self.assertFalse(payload["card_level_cut_permission_now"])

    def test_missing_candidate_db_blocks_forced_access_execution(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        seeded = write_json(root, "seeded.json", seeded_trace_payload())
        trace = write_json(root, "trace.json", trace_generator_payload(root, db_exists=False))

        payload = generator.build_report(
            seeded_trace_collector_report=seeded,
            trace_generator_report=trace,
            replay_dir=root / "replays",
            seed_start=1,
            seed_count=1,
        )

        self.assertEqual(payload["status"], "reviewed_external_seeded_forced_access_missing_inputs")
        self.assertEqual(payload["summary"]["seed_count"], 0)
        self.assertEqual(payload["summary"]["missing_input_count"], 1)
        self.assertFalse(payload["forced_access_replay_performed"])

    def test_forced_access_not_found_routes_to_current_db_remine(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        seeded = write_json(root, "seeded.json", seeded_trace_payload())
        trace = write_json(root, "trace.json", trace_generator_payload(root))

        def runner(cmd, cwd, env, capture_output, text, timeout):  # noqa: ANN001
            Path(env["REPLAY_EVENTS_OUT"]).write_text(
                json.dumps(
                    {
                        "event": "forced_focus_access_applied",
                        "player": "Kaalia of the Vast",
                        "card": "Basalt Monolith",
                        "status": "not_found",
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
            seeded_trace_collector_report=seeded,
            trace_generator_report=trace,
            replay_dir=root / "replays",
            seed_start=1,
            seed_count=1,
            runner=runner,
        )

        self.assertEqual(payload["status"], "reviewed_external_seeded_forced_access_blocks_absent_hypotheses")
        self.assertEqual(payload["summary"]["selected_db_absent_count"], 1)
        self.assertEqual(
            payload["review_rows"][0]["status"],
            "reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission",
        )
        self.assertEqual(payload["summary"]["next_gate"], "rerun_seeded_cut_source_miner_against_current_evaluation_db")


if __name__ == "__main__":
    unittest.main()
