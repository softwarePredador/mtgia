#!/usr/bin/env python3
"""Tests for external nonpayoff same-lane cut-policy mapping."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_same_lane_cut_policy_mapper as mapper


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def corpus_payload(status: str = "external_nonpayoff_corpus_collected_for_exhausted_same_lane_role") -> dict[str, object]:
    roles = ["haste_protection_silence", "mana_acceleration", "tutors_access"]
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "role_corpus_rows": [
            {
                "target_cut_role": role,
                "role_label": role,
                "status": status,
                "selected_add_count": 1,
                "fresh_source_count": 1 if status == "external_nonpayoff_corpus_blocked_fresh_sources_need_trace" else 0,
                "blocked_recycled_source_count": 5,
                "source_count": 6,
                "source_ids": ["edhrec_kaalia_current_2026_07_05"],
                "source_signal_requirements": ["commander_public_usage_presence_or_absence"],
                "nonpayoff_requirement": "exclude payoff bodies",
            }
            for role in roles
        ],
    }


class GlobalCommanderExternalNonpayoffSameLaneCutPolicyMapperTests(unittest.TestCase):
    def test_exhausted_role_corpus_requires_source_discovery_before_miner(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = mapper.build_report(corpus_report=write_json(root, "corpus.json", corpus_payload()))

        self.assertEqual(report["status"], "external_nonpayoff_same_lane_policy_ready_no_cut_permission")
        self.assertEqual(
            report["summary"]["next_gate"],
            "discover_external_nonpayoff_same_lane_source_candidates_before_miner",
        )
        self.assertEqual(report["summary"]["role_policy_count"], 3)
        self.assertEqual(report["summary"]["source_discovery_required_role_count"], 3)
        self.assertEqual(report["summary"]["card_level_cut_permission_count"], 0)
        self.assertFalse(report["card_level_cut_permission_now"])
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(
            report["role_policy_rows"][0]["cut_policy"],
            "require_external_nonpayoff_source_discovery_before_miner",
        )

    def test_fresh_sources_block_policy_until_trace(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = mapper.build_report(
            corpus_report=write_json(
                root,
                "corpus.json",
                corpus_payload("external_nonpayoff_corpus_blocked_fresh_sources_need_trace"),
            )
        )

        self.assertEqual(report["status"], "external_nonpayoff_same_lane_policy_blocks_fresh_sources_need_trace")
        self.assertEqual(report["summary"]["next_gate"], "collect_trace_for_new_same_lane_cut_source_hypotheses")
        self.assertEqual(
            report["role_policy_rows"][0]["cut_policy"],
            "block_source_discovery_until_fresh_trace_resolves",
        )
        self.assertFalse(report["battle_gate_allowed_now"])


if __name__ == "__main__":
    unittest.main()
