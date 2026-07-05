#!/usr/bin/env python3
"""Tests for Commander external corpus cut-policy mapping."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_external_corpus_cut_policy_mapper as mapper


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def corpus_payload() -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "card_corpus_rows": [
            {
                "cut_card": "Necropotence",
                "trace_group": "usage_blocked",
                "source_support_level": "commander_corpus_present_high_power",
                "corpus_status": "external_corpus_supports_preserve_or_strict_same_lane_proof",
                "cut_roles": ["card_draw_selection"],
            },
            {
                "cut_card": "Biotransference",
                "trace_group": "usage_blocked",
                "source_support_level": "absent_from_checked_kaalia_sources",
                "corpus_status": "external_absence_cannot_override_target_usage",
                "cut_roles": [],
            },
            {
                "cut_card": "Trouble in Pairs",
                "trace_group": "seen_without_usage",
                "source_support_level": "commander_corpus_present",
                "corpus_status": "external_presence_requires_negative_trace_before_cut",
                "cut_roles": ["card_draw_selection"],
            },
            {
                "cut_card": "Puresteel Paladin",
                "trace_group": "seen_without_usage",
                "source_support_level": "absent_from_checked_kaalia_sources",
                "corpus_status": "external_absence_plus_seen_without_usage_requires_negative_review",
                "cut_roles": ["card_draw_selection"],
            },
        ],
    }


class GlobalCommanderExternalCorpusCutPolicyMapperTests(unittest.TestCase):
    def test_policy_blocks_current_hypotheses_from_rerun_miner(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        payload = mapper.build_report(corpus_report=write_json(root, "corpus.json", corpus_payload()))

        self.assertEqual(payload["status"], "external_corpus_cut_policy_blocks_current_hypotheses")
        self.assertEqual(payload["summary"]["next_gate"], "rerun_value_safe_cut_source_miner_with_external_policy_exclusions")
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertFalse(payload["value_safe_reclassification_allowed_now"])
        self.assertEqual(payload["summary"]["rerun_miner_allowed_card_count"], 0)
        self.assertEqual(payload["summary"]["excluded_from_rerun_miner_count"], 2)
        self.assertEqual(payload["summary"]["held_for_negative_review_count"], 2)
        rows = {row["cut_card"]: row for row in payload["cut_policy_rows"]}
        self.assertEqual(
            rows["Necropotence"]["cut_policy"],
            "protect_from_rerun_miner_until_same_lane_or_equal_gate",
        )
        self.assertEqual(
            rows["Biotransference"]["cut_policy"],
            "exclude_from_rerun_miner_until_new_internal_evidence",
        )
        self.assertEqual(
            rows["Trouble in Pairs"]["cut_policy"],
            "hold_for_negative_trace_review_before_rerun_miner",
        )
        self.assertEqual(
            rows["Puresteel Paladin"]["cut_policy"],
            "hold_for_negative_or_force_access_review_before_rerun_miner",
        )


if __name__ == "__main__":
    unittest.main()
