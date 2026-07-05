#!/usr/bin/env python3
"""Tests for Commander package scope reduction."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_package_scope_reducer as reducer


def add(name: str, axis: str, score: int) -> dict[str, object]:
    return {
        "card_name": name,
        "score": score,
        "selected_for_axis": axis,
        "covered_axes": [axis],
        "status": "review_only_synthesized_package_add",
    }


def cut(name: str) -> dict[str, object]:
    return {
        "card_name": name,
        "score": 70,
        "primary_cut_role": "mana_acceleration",
        "matching_over_target_roles": ["mana_acceleration"],
        "status": "review_only_expanded_cut_source_candidate",
    }


def package_payload() -> dict[str, object]:
    return {
        "status": "commander_payoff_package_synthesis_blocks_candidate_copy",
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "initial_axis_requirements": {
                "angels_demons_dragons_payoffs": 6,
                "reanimation_plan_b": 1,
            },
        },
        "candidate_copy_blockers": [
            "insufficient_reviewable_cuts_for_full_profile_package:required_7_ready_6",
        ],
        "selected_add_package": [
            add("Dragon Mage", "angels_demons_dragons_payoffs", 110),
            add("Necromancy", "reanimation_plan_b", 90),
        ],
    }


class GlobalCommanderPackageScopeReducerTests(unittest.TestCase):
    def _json(self, root: Path, name: str, payload: dict[str, object]) -> Path:
        path = root / name
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_reduces_scope_to_axis_closing_pair_when_cut_is_scarce(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        package = self._json(root, "package.json", package_payload())
        cuts = self._json(
            root,
            "cuts.json",
            {
                "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
                "db_resolution": {"selected_db": "candidate.db"},
                "candidate_copy_blockers": ["value_safe_cut_shortfall:required_7_ready_1"],
                "selected_value_safe_cuts": [cut("Cabal Ritual")],
            },
        )

        report = reducer.build_report(package_synthesis_report=package, cut_source_lane_report=cuts)

        self.assertEqual(report["status"], "commander_package_scope_reduced_ready_for_candidate_copy")
        self.assertTrue(report["reduced_scope_candidate_copy_allowed_now"])
        self.assertFalse(report["full_package_candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["scoped_pair_count"], 1)
        self.assertEqual(report["scoped_pairs"][0]["add"], "Necromancy")
        self.assertEqual(report["scoped_pairs"][0]["cut"], "Cabal Ritual")
        self.assertEqual(report["summary"]["remaining_axis_requirements"]["reanimation_plan_b"], 0)
        self.assertEqual(report["summary"]["remaining_axis_requirements"]["angels_demons_dragons_payoffs"], 6)
        self.assertIn("reduced_scope_dropped_adds:1", report["candidate_copy_blockers"])

    def test_blocks_when_no_value_safe_cut_exists(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        package = self._json(root, "package.json", package_payload())
        cuts = self._json(
            root,
            "cuts.json",
            {
                "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
                "selected_value_safe_cuts": [],
            },
        )

        report = reducer.build_report(package_synthesis_report=package, cut_source_lane_report=cuts)

        self.assertEqual(report["status"], "commander_package_scope_reduction_blocks_candidate_copy")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertIn("no_value_safe_reduced_scope_pair_ready", report["candidate_copy_blockers"])


if __name__ == "__main__":
    unittest.main()
