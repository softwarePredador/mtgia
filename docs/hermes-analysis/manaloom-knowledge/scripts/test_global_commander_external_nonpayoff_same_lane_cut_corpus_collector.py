#!/usr/bin/env python3
"""Tests for external nonpayoff same-lane cut corpus collection."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_same_lane_cut_corpus_collector as collector


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def axis_payload(*, fresh: int = 0, recycled: int = 6, roles: list[str] | None = None) -> dict[str, object]:
    target_roles = roles or ["haste_protection_silence", "mana_acceleration", "tutors_access"]
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "fresh_same_lane_cut_source_count": fresh,
            "blocked_recycled_cut_source_count": recycled,
            "ready_pair_count": 0,
            "unpaired_add_count": len(target_roles),
        },
        "role_pressure_rows": [
            {
                "target_cut_role": role,
                "selected_add_count": 1,
                "fresh_source_count": fresh if index == 0 else 0,
                "blocked_recycled_source_count": recycled if fresh == 0 else 0,
                "blocked_new_source_count": 0,
                "scanned_source_count": fresh + recycled,
            }
            for index, role in enumerate(target_roles)
        ],
    }


def miner_payload(*, fresh: int = 0, recycled: int = 6) -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "fresh_same_lane_cut_source_count": fresh,
            "blocked_recycled_cut_source_count": recycled,
        }
    }


def package_payload(roles: list[str] | None = None) -> dict[str, object]:
    target_roles = roles or ["haste_protection_silence", "mana_acceleration", "tutors_access"]
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "selected_add_package": [
            {"card_name": f"Add {role}", "replaces_cut_role": role}
            for role in target_roles
        ],
    }


class GlobalCommanderExternalNonpayoffSameLaneCutCorpusCollectorTests(unittest.TestCase):
    def test_exhausted_roles_collect_corpus_without_cut_permission(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = collector.build_report(
            axis_broadening_report=write_json(root, "axis.json", axis_payload()),
            new_cut_source_miner_report=write_json(root, "miner.json", miner_payload()),
            package_source_report=write_json(root, "package.json", package_payload()),
        )

        self.assertEqual(report["status"], "external_nonpayoff_same_lane_corpus_collected_no_cut_permission")
        self.assertEqual(
            report["summary"]["next_gate"],
            "map_external_nonpayoff_same_lane_corpus_to_cut_policy_before_source_discovery",
        )
        self.assertEqual(report["summary"]["target_role_count"], 3)
        self.assertEqual(report["summary"]["exhausted_role_count"], 3)
        self.assertFalse(report["external_cut_permission_now"])
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertIn("edhrec_kaalia_current_2026_07_05", json.dumps(report))
        self.assertIn("external_corpus_is_not_cut_permission", report["candidate_copy_blockers"])

    def test_fresh_sources_block_external_corpus_until_trace(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = collector.build_report(
            axis_broadening_report=write_json(root, "axis.json", axis_payload(fresh=1, recycled=0, roles=["mana_acceleration"])),
            new_cut_source_miner_report=write_json(root, "miner.json", miner_payload(fresh=1, recycled=0)),
            package_source_report=write_json(root, "package.json", package_payload(["mana_acceleration"])),
        )

        self.assertEqual(report["status"], "external_nonpayoff_same_lane_corpus_blocked_fresh_sources_need_trace")
        self.assertEqual(report["summary"]["next_gate"], "collect_trace_for_new_same_lane_cut_source_hypotheses")
        self.assertEqual(
            report["role_corpus_rows"][0]["status"],
            "external_nonpayoff_corpus_blocked_fresh_sources_need_trace",
        )
        self.assertFalse(report["value_safe_reclassification_allowed_now"])

    def test_role_without_scanned_sources_routes_to_source_discovery(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = collector.build_report(
            axis_broadening_report=write_json(root, "axis.json", axis_payload(fresh=0, recycled=0, roles=["tutors_access"])),
            new_cut_source_miner_report=write_json(root, "miner.json", miner_payload(fresh=0, recycled=0)),
            package_source_report=write_json(root, "package.json", package_payload(["tutors_access"])),
        )

        self.assertEqual(report["status"], "external_nonpayoff_same_lane_corpus_collected_no_cut_permission")
        self.assertEqual(
            report["summary"]["next_gate"],
            "discover_same_lane_source_candidates_before_policy_mapping",
        )
        self.assertEqual(
            report["role_corpus_rows"][0]["status"],
            "external_nonpayoff_corpus_needs_source_lane_discovery",
        )


if __name__ == "__main__":
    unittest.main()
