#!/usr/bin/env python3
"""Tests for Commander package-axis broadening planning."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_package_axis_broadening_plan as broadening


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def miner_payload(*, hypothesis_count: int, next_gate: str) -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "hypothesis_count": hypothesis_count,
            "blocked_hypothesis_count": 88,
            "external_policy_exclusion_count": 8,
            "target_cut_roles": {"mana_acceleration": 1, "tutors_access": 2},
            "next_gate": next_gate,
        }
    }


def package_payload(*, axis: str) -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "unpaired_add_count": 1,
        },
        "selected_add_package": [
            {
                "card_name": "Dragon Mage",
                "selected_for_axis": axis,
                "covered_axes": [axis],
                "fit_reasons": ["card_flow_payload", "kaalia_cheat_curve"],
            },
            {
                "card_name": "The Balrog of Moria",
                "selected_for_axis": axis,
                "covered_axes": [axis],
                "fit_reasons": ["haste", "mana_or_treasure_payload"],
            },
        ],
        "selected_cut_package": [
            {
                "card_name": "Dark Ritual",
                "matching_over_target_roles": ["mana_acceleration"],
                "cut_reasons": ["over_target_mana_acceleration"],
            }
        ],
    }


def cut_payload() -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "value_safe_cut_count": 0,
            "remaining_cut_budget_after_selection": {"mana_acceleration": 1, "tutors_access": 2},
        }
    }


def policy_payload() -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "policy_row_count": 8,
            "rerun_miner_allowed_card_count": 0,
        }
    }


def corpus_payload() -> dict[str, object]:
    return {"summary": {"deck_id": "619", "commander": "Kaalia of the Vast", "source_count": 5}}


class GlobalCommanderPackageAxisBroadeningPlanTests(unittest.TestCase):
    def test_mismatched_package_axis_routes_to_same_lane_resynthesis(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = broadening.build_report(
            miner_report=write_json(
                root,
                "miner.json",
                miner_payload(
                    hypothesis_count=0,
                    next_gate="broaden_commander_package_axis_or_external_cut_research",
                ),
            ),
            package_synthesis_report=write_json(
                root,
                "package.json",
                package_payload(axis="angels_demons_dragons_payoffs"),
            ),
            cut_source_report=write_json(root, "cut.json", cut_payload()),
            policy_report=write_json(root, "policy.json", policy_payload()),
            corpus_report=write_json(root, "corpus.json", corpus_payload()),
        )

        self.assertEqual(report["status"], "commander_package_axis_broadening_plan_ready_no_deck_action")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertFalse(report["value_safe_reclassification_allowed_now"])
        self.assertEqual(report["summary"]["lane_alignment_status"], "package_axis_mismatch_with_exhausted_cut_lanes")
        self.assertEqual(report["summary"]["next_gate"], "resynthesize_package_with_same_lane_axis_requirements")
        actions = [row["action"] for row in report["broadening_actions"]]
        self.assertIn("resynthesize_package_with_same_lane_axis_requirements", actions)
        self.assertIn("collect_external_nonpayoff_cut_lane_corpus", actions)
        self.assertIn("incidental_payload_is_not_same_lane_cut_proof", json.dumps(report))

    def test_fresh_hypotheses_block_axis_broadening_until_trace(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = broadening.build_report(
            miner_report=write_json(
                root,
                "miner.json",
                miner_payload(
                    hypothesis_count=2,
                    next_gate="collect_usage_trace_for_new_cut_source_hypotheses",
                ),
            ),
            package_synthesis_report=write_json(
                root,
                "package.json",
                package_payload(axis="angels_demons_dragons_payoffs"),
            ),
            cut_source_report=write_json(root, "cut.json", cut_payload()),
            policy_report=write_json(root, "policy.json", policy_payload()),
            corpus_report=write_json(root, "corpus.json", corpus_payload()),
        )

        self.assertEqual(report["status"], "package_axis_broadening_not_ready_hypotheses_need_trace")
        self.assertEqual(report["summary"]["next_gate"], "collect_usage_trace_for_new_cut_source_hypotheses")
        self.assertEqual(report["broadening_actions"][0]["action"], "collect_usage_trace_for_remaining_fresh_hypotheses")
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_same_lane_axis_still_requires_value_safe_cut_pair(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = broadening.build_report(
            miner_report=write_json(
                root,
                "miner.json",
                miner_payload(
                    hypothesis_count=0,
                    next_gate="broaden_commander_package_axis_or_external_cut_research",
                ),
            ),
            package_synthesis_report=write_json(
                root,
                "package.json",
                package_payload(axis="mana_acceleration"),
            ),
            cut_source_report=write_json(root, "cut.json", cut_payload()),
            policy_report=write_json(root, "policy.json", policy_payload()),
            corpus_report=write_json(root, "corpus.json", corpus_payload()),
        )

        self.assertEqual(report["status"], "commander_package_axis_broadening_plan_ready_no_deck_action")
        self.assertEqual(
            report["summary"]["lane_alignment_status"],
            "partial_same_lane_axis_coverage_needs_explicit_cut_proof",
        )
        self.assertEqual(
            report["summary"]["next_gate"],
            "collect_or_validate_same_lane_value_safe_cut_pairs_before_resynthesis",
        )
        self.assertIn("same_lane_axis_still_needs_value_safe_cut_proof", report["candidate_copy_blockers"])


if __name__ == "__main__":
    unittest.main()
