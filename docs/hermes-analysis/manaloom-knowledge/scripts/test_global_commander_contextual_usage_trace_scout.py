#!/usr/bin/env python3
"""Tests for contextual Commander usage trace scouting."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_contextual_usage_trace_scout as scout


def collector_report(cards: list[str]) -> dict[str, object]:
    return {
        "status": "contextual_stage_cut_evidence_collected_no_value_safe_reclassification",
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "contextual_evidence_rows": [{"card_name": card} for card in cards],
    }


class GlobalCommanderContextualUsageTraceScoutTests(unittest.TestCase):
    def _json(self, root: Path, payload: dict[str, object]) -> Path:
        path = root / "collector.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_counts_current_scope_usage_trace_without_opening_reclassification(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report = self._json(root, collector_report(["Diabolic Intent", "Professional Face-Breaker"]))
        trace = root / "global_commander_candidate_battle_probe_audit_20260705_kaalia_trace.jsonl"
        trace.write_text(
            '{"event":"spell_resolved","card":"Diabolic Intent","result":"resolved"}\n',
            encoding="utf-8",
        )
        planning = root / "global_commander_stage_only_cut_evidence_plan_20260705_kaalia.json"
        planning.write_text('{"card_name":"Professional Face-Breaker"}\n', encoding="utf-8")

        payload = scout.build_report(contextual_evidence_report=report, scan_roots=[root])

        self.assertEqual(payload["status"], "contextual_usage_trace_scout_partial_current_trace_evidence")
        self.assertEqual(payload["summary"]["current_usage_trace_evidence_count"], 1)
        self.assertEqual(payload["evidence_by_card"]["Diabolic Intent"]["current_usage_trace_count"], 1)
        self.assertFalse(payload["value_safe_reclassification_allowed_now"])
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertFalse(payload["battle_run_performed"])
        self.assertEqual(
            payload["non_proof_occurrence_sample"][0]["classification"],
            "planning_reference_not_usage_trace",
        )

    def test_blocks_when_only_non_proof_references_exist(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report = self._json(root, collector_report(["Ornithopter of Paradise"]))
        cross_scope = root / "lorehold_single_battle_replay_20260620_1810.events.jsonl"
        cross_scope.write_text(
            '{"event":"spell_resolved","card":"Ornithopter of Paradise"}\n',
            encoding="utf-8",
        )

        payload = scout.build_report(contextual_evidence_report=report, scan_roots=[root])

        self.assertEqual(payload["status"], "contextual_usage_trace_scout_no_current_trace_evidence")
        self.assertEqual(payload["summary"]["current_usage_trace_evidence_count"], 0)
        self.assertIn(
            "no_current_scope_usage_trace_evidence_for_contextual_stage_cuts",
            payload["candidate_copy_blockers"],
        )
        self.assertEqual(
            payload["non_proof_occurrence_sample"][0]["classification"],
            "historical_or_cross_deck_trace_reference_not_proof",
        )


if __name__ == "__main__":
    unittest.main()
