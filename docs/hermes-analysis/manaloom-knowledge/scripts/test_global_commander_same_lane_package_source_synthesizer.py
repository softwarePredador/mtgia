#!/usr/bin/env python3
"""Tests for same-lane source package synthesis."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_same_lane_package_source_synthesizer as synthesizer


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def candidate(name: str, score: int, roles: list[str]) -> dict[str, object]:
    return {
        "card_name": name,
        "score": score,
        "source_lanes": ["local_oracle_same_lane_scan"],
        "profile_roles": roles,
        "fit_reasons": ["commander_legal"],
        "commander_legality": "legal",
        "color_identity": [],
        "cmc": 2,
        "type_line": "Artifact",
    }


def source_lane_payload(*, missing_tutor: bool = False) -> dict[str, object]:
    tutor_candidates = [] if missing_tutor else [
        candidate("Gamble", 124, ["tutors_access"]),
        candidate("Wishclaw Talisman", 121, ["tutors_access"]),
        candidate("Entomb", 120, ["tutors_access"]),
    ]
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "source_lanes": [
            {
                "required_add_axis": "commander_attack_window",
                "cut_role": "haste_protection_silence",
                "target_cut_count": 4,
                "ready_candidate_count": 3,
                "top_candidates": [
                    candidate("Boros Charm", 132, ["haste_protection_silence"]),
                    candidate("Swiftfoot Boots", 123, ["haste_protection_silence"]),
                    candidate("Flawless Maneuver", 113, ["haste_protection_silence"]),
                ],
            },
            {
                "required_add_axis": "mana_acceleration_replacement",
                "cut_role": "mana_acceleration",
                "target_cut_count": 1,
                "ready_candidate_count": 2,
                "top_candidates": [
                    candidate("Fellwar Stone", 136, ["mana_acceleration"]),
                    candidate("Orzhov Signet", 135, ["mana_acceleration"]),
                ],
            },
            {
                "required_add_axis": "tutors_access_replacement",
                "cut_role": "tutors_access",
                "target_cut_count": 8,
                "ready_candidate_count": len(tutor_candidates),
                "top_candidates": tutor_candidates,
            },
        ],
    }


class GlobalCommanderSameLanePackageSourceSynthesizerTests(unittest.TestCase):
    def test_synthesizes_bounded_package_with_all_axes_covered(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = synthesizer.build_report(
            source_lane_report=write_json(root, "source.json", source_lane_payload()),
            package_size_limit=4,
        )

        self.assertEqual(report["status"], "same_lane_source_package_synthesized_no_cut_pairs")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["selected_add_count"], 4)
        self.assertEqual(report["summary"]["axes_covered_count"], 3)
        self.assertEqual(report["summary"]["unpaired_add_count"], 4)
        self.assertEqual(report["summary"]["ready_pair_count"], 0)
        selected = {row["card_name"] for row in report["selected_add_package"]}
        self.assertIn("Boros Charm", selected)
        self.assertIn("Fellwar Stone", selected)
        self.assertIn("Gamble", selected)
        self.assertEqual(
            report["summary"]["next_gate"],
            "collect_value_safe_same_lane_cut_pairs_for_resynthesized_package",
        )

    def test_missing_axis_blocks_source_package_synthesis(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = synthesizer.build_report(
            source_lane_report=write_json(root, "source.json", source_lane_payload(missing_tutor=True)),
            package_size_limit=4,
        )

        self.assertEqual(report["status"], "same_lane_source_package_synthesis_blocks_on_missing_axes")
        self.assertEqual(report["summary"]["missing_axes"], ["tutors_access_replacement"])
        self.assertEqual(report["summary"]["next_gate"], "external_same_lane_source_research_for_missing_axes")

    def test_package_size_limit_is_respected(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        report = synthesizer.build_report(
            source_lane_report=write_json(root, "source.json", source_lane_payload()),
            package_size_limit=3,
        )

        self.assertEqual(report["summary"]["selected_add_count"], 3)
        self.assertEqual(report["summary"]["axes_covered_count"], 3)
        axes = {row["selected_for_axis"] for row in report["selected_add_package"]}
        self.assertEqual(
            axes,
            {
                "commander_attack_window",
                "mana_acceleration_replacement",
                "tutors_access_replacement",
            },
        )


if __name__ == "__main__":
    unittest.main()
