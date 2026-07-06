#!/usr/bin/env python3
"""Tests for same-lane cut-axis broadening planning."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_same_lane_cut_axis_broadening_plan as plan


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def miner_payload(*, fresh: int, recycled: int, roles: list[str]) -> dict[str, object]:
    rows = []
    for index in range(fresh):
        rows.append(
            {
                "card_name": f"Fresh Source {index}",
                "target_cut_role": roles[0],
                "status": "fresh_same_lane_cut_source_needs_trace",
            }
        )
    recycled_rows = []
    for index in range(recycled):
        recycled_rows.append(
            {
                "card_name": f"Recycled Source {index}",
                "target_cut_role": roles[index % len(roles)],
                "status": "blocked_recycled_cut_source",
            }
        )
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "target_roles": roles,
            "fresh_same_lane_cut_source_count": fresh,
            "blocked_recycled_cut_source_count": recycled,
            "scanned_same_lane_source_count": fresh + recycled,
        },
        "fresh_same_lane_cut_sources": rows,
        "blocked_recycled_cut_sources": recycled_rows,
        "blocked_new_cut_sources": [],
    }


def package_payload(roles: list[str]) -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "selected_add_package": [
            {
                "card_name": f"Add {role}",
                "replaces_cut_role": role,
                "selected_for_axis": f"{role}_replacement",
            }
            for role in roles
        ],
    }


def cut_pair_payload() -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "ready_pair_count": 0,
            "unpaired_add_count": 3,
            "selected_add_count": 3,
        }
    }


class GlobalCommanderSameLaneCutAxisBroadeningPlanTests(unittest.TestCase):
    def test_fresh_sources_block_broadening_until_trace(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = plan.build_report(
            miner_report=write_json(root, "miner.json", miner_payload(fresh=1, recycled=0, roles=["mana_acceleration"])),
            package_source_report=write_json(root, "package.json", package_payload(["mana_acceleration"])),
            cut_pair_report=write_json(root, "cut_pair.json", cut_pair_payload()),
        )

        self.assertEqual(report["status"], "same_lane_cut_axis_broadening_not_ready_fresh_sources_need_trace")
        self.assertEqual(report["summary"]["next_gate"], "collect_trace_for_new_same_lane_cut_source_hypotheses")
        self.assertEqual(report["broadening_actions"][0]["action"], "collect_trace_for_new_same_lane_cut_source_hypotheses")
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_exhausted_roles_route_to_external_nonpayoff_corpus(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = plan.build_report(
            miner_report=write_json(
                root,
                "miner.json",
                miner_payload(
                    fresh=0,
                    recycled=6,
                    roles=["haste_protection_silence", "mana_acceleration", "tutors_access"],
                ),
            ),
            package_source_report=write_json(
                root,
                "package.json",
                package_payload(["haste_protection_silence", "mana_acceleration", "tutors_access"]),
            ),
            cut_pair_report=write_json(root, "cut_pair.json", cut_pair_payload()),
        )

        self.assertEqual(report["status"], "same_lane_cut_axis_broadening_plan_ready_no_deck_action")
        self.assertEqual(
            report["summary"]["next_gate"],
            "collect_external_nonpayoff_same_lane_cut_corpus_for_exhausted_roles",
        )
        self.assertEqual(report["broadening_actions"][0]["action"], "collect_external_nonpayoff_same_lane_cut_corpus")
        self.assertIn("edhrec_commander_and_theme_pages", json.dumps(report["broadening_actions"]))
        self.assertIn("current_deck_same_lane_cut_sources_exhausted", report["candidate_copy_blockers"])

    def test_missing_role_source_routes_to_discovery_before_resynthesis(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = plan.build_report(
            miner_report=write_json(
                root,
                "miner.json",
                miner_payload(fresh=0, recycled=0, roles=["tutors_access"]),
            ),
            package_source_report=write_json(root, "package.json", package_payload([])),
            cut_pair_report=write_json(root, "cut_pair.json", cut_pair_payload()),
        )

        self.assertEqual(report["status"], "same_lane_cut_axis_broadening_plan_ready_no_deck_action")
        self.assertEqual(
            report["summary"]["next_gate"],
            "discover_same_lane_source_candidates_before_package_resynthesis",
        )
        actions = [row["action"] for row in report["broadening_actions"]]
        self.assertIn("discover_same_lane_source_candidates_before_package_resynthesis", actions)
        self.assertFalse(report["battle_gate_allowed_now"])


if __name__ == "__main__":
    unittest.main()
