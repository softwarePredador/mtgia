#!/usr/bin/env python3
"""Tests for Commander same-lane package resynthesis requirements."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_same_lane_package_resynthesizer as resynthesizer


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def broadening_payload(*, value_safe_cut_count: int = 0) -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "package_axes": ["angels_demons_dragons_payoffs"],
            "target_cut_roles": {
                "haste_protection_silence": 4,
                "mana_acceleration": 1,
                "tutors_access": 8,
            },
            "value_safe_cut_count": value_safe_cut_count,
        }
    }


def package_payload(*, same_lane_axis: bool = False) -> dict[str, object]:
    add_axis = "mana_acceleration_replacement" if same_lane_axis else "angels_demons_dragons_payoffs"
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "selected_add_package": [
            {
                "card_name": "Dragon Mage",
                "selected_for_axis": "angels_demons_dragons_payoffs",
                "covered_axes": ["angels_demons_dragons_payoffs"],
                "fit_reasons": ["card_flow_payload"],
            },
            {
                "card_name": "Treasure Dragon",
                "selected_for_axis": add_axis,
                "covered_axes": [add_axis],
                "fit_reasons": ["mana_or_treasure_payload"],
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


def payoff_source_payload() -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "ready_candidate_count": 30,
        }
    }


class GlobalCommanderSameLanePackageResynthesizerTests(unittest.TestCase):
    def test_payoff_only_package_blocks_candidate_copy_and_names_requirements(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = resynthesizer.build_report(
            broadening_report=write_json(root, "broadening.json", broadening_payload()),
            package_synthesis_report=write_json(root, "package.json", package_payload()),
            payoff_source_report=write_json(root, "payoff.json", payoff_source_payload()),
        )

        self.assertEqual(
            report["status"],
            "same_lane_package_resynthesis_blocks_candidate_copy_needs_source_lanes",
        )
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertEqual(report["summary"]["same_lane_axis_requirement_count"], 3)
        self.assertEqual(report["summary"]["satisfied_same_lane_axis_count"], 0)
        self.assertEqual(report["summary"]["held_payoff_add_count"], 2)
        self.assertEqual(report["summary"]["next_gate"], "expand_same_lane_add_source_lanes_for_target_cut_roles")
        requirements = {row["cut_role"]: row["required_add_axis"] for row in report["same_lane_axis_requirements"]}
        self.assertEqual(requirements["mana_acceleration"], "mana_acceleration_replacement")
        self.assertEqual(requirements["tutors_access"], "tutors_access_replacement")
        self.assertIn("same_lane_add_source_lanes_missing_for_target_cut_roles", report["candidate_copy_blockers"])

    def test_existing_same_lane_axis_still_needs_value_safe_cut_proof(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = resynthesizer.build_report(
            broadening_report=write_json(root, "broadening.json", broadening_payload()),
            package_synthesis_report=write_json(
                root,
                "package.json",
                package_payload(same_lane_axis=True),
            ),
            payoff_source_report=write_json(root, "payoff.json", payoff_source_payload()),
        )

        self.assertEqual(report["summary"]["satisfied_same_lane_axis_count"], 1)
        self.assertEqual(report["summary"]["ready_pair_count"], 0)
        self.assertIn("same_lane_axes_still_need_value_safe_cut_proof", report["candidate_copy_blockers"])
        mana_req = [
            row for row in report["same_lane_axis_requirements"] if row["cut_role"] == "mana_acceleration"
        ][0]
        self.assertEqual(mana_req["status"], "same_lane_add_axis_present_needs_cut_proof")
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_ready_pair_count_only_opens_when_same_lane_axis_and_value_safe_cut_exist(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = resynthesizer.build_report(
            broadening_report=write_json(root, "broadening.json", broadening_payload(value_safe_cut_count=1)),
            package_synthesis_report=write_json(
                root,
                "package.json",
                package_payload(same_lane_axis=True),
            ),
            payoff_source_report=write_json(root, "payoff.json", payoff_source_payload()),
        )

        self.assertEqual(report["status"], "same_lane_package_resynthesis_has_pair_candidates")
        self.assertEqual(report["summary"]["ready_pair_count"], 1)
        self.assertEqual(report["summary"]["next_gate"], "rerun_package_scope_reducer_with_same_lane_requirements")
        self.assertFalse(report["candidate_copy_allowed_now"])


if __name__ == "__main__":
    unittest.main()
