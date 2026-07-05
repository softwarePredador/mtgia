#!/usr/bin/env python3
"""Tests for contextual Commander usage trace generation."""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

import global_commander_contextual_usage_trace_generator as generator


def contextual_report(db_path: Path) -> dict[str, object]:
    return {
        "status": "contextual_stage_cut_evidence_collected_no_value_safe_reclassification",
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "input_artifacts": {"selected_db": str(db_path)},
        "contextual_evidence_rows": [
            {"card_name": "Diabolic Intent"},
            {"card_name": "Professional Face-Breaker"},
        ],
    }


class GlobalCommanderContextualUsageTraceGeneratorTests(unittest.TestCase):
    def _write_contextual(self, root: Path, db_path: Path) -> Path:
        path = root / "contextual.json"
        path.write_text(json.dumps(contextual_report(db_path)), encoding="utf-8")
        db_path.write_text("not a real sqlite db for subprocess-mocked tests", encoding="utf-8")
        return path

    def test_generates_usage_trace_summary_without_opening_gates(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report = self._write_contextual(root, root / "candidate.db")

        def fake_runner(cmd, cwd, env, capture_output, text, timeout):
            Path(env["REPLAY_EVENTS_OUT"]).write_text(
                json.dumps(
                    {
                        "event": "spell_resolved",
                        "card": "Diabolic Intent",
                        "player": "Kaalia of the Vast",
                        "turn": 4,
                    }
                )
                + "\n"
                + json.dumps(
                    {
                        "event": "spell_resolved",
                        "card": "Professional Face-Breaker",
                        "player": "Opponent",
                        "turn": 4,
                    }
                )
                + "\n",
                encoding="utf-8",
            )
            Path(env["DECISION_TRACE_OUT"]).write_text("", encoding="utf-8")
            Path(env["REPLAY_DECK_PROVENANCE_OUT"]).write_text(
                json.dumps(
                    {
                        "decks": [
                            {
                                "name": "Kaalia of the Vast",
                                "target_deck_id": 619,
                                "source_ref": "deck_id:619",
                                "construction_report": {"is_valid": True, "issues": []},
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )
            Path(env["REPLAY_OUT"]).write_text("ok", encoding="utf-8")
            return subprocess.CompletedProcess(cmd, 0, stdout="ok", stderr="")

        payload = generator.build_report(
            contextual_evidence_report=report,
            replay_dir=root / "replays",
            seed_start=7,
            seed_count=1,
            runner=fake_runner,
        )

        self.assertEqual(payload["status"], "contextual_usage_trace_generated_partial_current_usage_review_required")
        self.assertTrue(payload["battle_replay_performed"])
        self.assertFalse(payload["battle_gate_performed"])
        self.assertFalse(payload["value_safe_reclassification_allowed_now"])
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertEqual(payload["aggregate_card_trace"]["Diabolic Intent"]["usage_event_count"], 1)
        self.assertEqual(payload["aggregate_card_trace"]["Professional Face-Breaker"]["usage_event_count"], 0)
        self.assertEqual(payload["summary"]["usage_event_cards"], ["Diabolic Intent"])
        self.assertEqual(
            payload["summary"]["next_gate"],
            "review_used_cards_and_generate_focused_trace_for_missing_cards_before_reclassification",
        )

    def test_generated_replay_without_target_exposure_keeps_blocker(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report = self._write_contextual(root, root / "candidate.db")

        def fake_runner(cmd, cwd, env, capture_output, text, timeout):
            Path(env["REPLAY_EVENTS_OUT"]).write_text(
                json.dumps({"event": "turn_start", "player": "Kaalia of the Vast", "turn": 1}) + "\n",
                encoding="utf-8",
            )
            Path(env["DECISION_TRACE_OUT"]).write_text("", encoding="utf-8")
            Path(env["REPLAY_DECK_PROVENANCE_OUT"]).write_text(
                json.dumps({"decks": [{"name": "Kaalia of the Vast", "source_ref": "deck_id:619"}]}),
                encoding="utf-8",
            )
            Path(env["REPLAY_OUT"]).write_text("ok", encoding="utf-8")
            return subprocess.CompletedProcess(cmd, 0, stdout="ok", stderr="")

        payload = generator.build_report(
            contextual_evidence_report=report,
            replay_dir=root / "replays",
            seed_start=7,
            seed_count=1,
            runner=fake_runner,
        )

        self.assertEqual(payload["status"], "contextual_usage_trace_generated_no_target_exposure")
        self.assertIn(
            "current_scope_usage_missing_for_cards:Diabolic Intent,Professional Face-Breaker",
            payload["candidate_copy_blockers"],
        )
        self.assertEqual(payload["summary"]["next_gate"], "increase_seed_count_or_force_access_trace_for_contextual_cards")


if __name__ == "__main__":
    unittest.main()
