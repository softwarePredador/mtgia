#!/usr/bin/env python3
"""Tests for Commander post-forced recovery synthesis."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_post_forced_recovery_synthesizer as synthesizer


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def package_payload() -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast", "selected_add_count": 2},
        "selected_add_package": [
            {
                "card_name": "Dragon Mage",
                "selected_for_axis": "angels_demons_dragons_payoffs",
                "covered_axes": ["angels_demons_dragons_payoffs"],
                "score": 98,
            },
            {
                "card_name": "Bonehoard Dracosaur",
                "selected_for_axis": "angels_demons_dragons_payoffs",
                "covered_axes": ["angels_demons_dragons_payoffs"],
                "score": 97,
            },
        ],
    }


def cut_payload(*, value_safe: int, forced_usage: int) -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "required_cut_count": 2,
            "value_safe_cut_count": value_safe,
            "forced_usage_blocked_count": forced_usage,
            "remaining_cut_budget_after_selection": {"mana_acceleration": 1, "tutors_access": 1},
        },
        "stage_only_cut_candidates": [
            {
                "card_name": "Dark Ritual",
                "stage_reasons": ["structural_foundation_staple_requires_same_lane_or_battle_proof"],
            }
        ],
        "blocked_cut_candidates": [
            {"card_name": "Ancient Tomb", "block_reasons": ["protected_profile_role_lands"]}
        ],
    }


def reducer_payload(*, scoped_pairs: int, value_safe: int, forced_usage: int) -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "scoped_pair_count": scoped_pairs,
            "value_safe_cut_count": value_safe,
            "forced_usage_blocked_count": forced_usage,
            "dropped_add_count": 2 - scoped_pairs,
        }
    }


def profile_payload() -> dict[str, object]:
    return {
        "global_cut_review_pool": [
            {"card_name": "Diabolic Intent", "status": "review_only_profile_repair_cut_candidate"},
        ],
        "blocked_cut_review_pool": [
            {
                "card_name": "Arcane Signet",
                "status": "blocked_profile_repair_cut_candidate",
                "block_reasons": ["structural_foundation_staple_requires_same_lane_or_battle_proof"],
            }
        ],
    }


class GlobalCommanderPostForcedRecoverySynthesizerTests(unittest.TestCase):
    def test_blocks_current_package_when_no_value_safe_cut_or_pair_exists(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        payload = synthesizer.build_report(
            package_synthesis_report=write_json(root, "package.json", package_payload()),
            cut_source_report=write_json(root, "cuts.json", cut_payload(value_safe=0, forced_usage=3)),
            scope_reducer_report=write_json(root, "reducer.json", reducer_payload(scoped_pairs=0, value_safe=0, forced_usage=3)),
            profile_repair_report=write_json(root, "profile.json", profile_payload()),
            payoff_source_report=write_json(root, "payoff.json", {"summary": {"ready_candidate_count": 30}}),
        )

        self.assertEqual(payload["status"], "post_forced_recovery_blocks_candidate_copy_needs_new_cut_source")
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertEqual(payload["summary"]["next_gate"], "mine_new_value_safe_cut_source_before_package_resynthesis")
        self.assertEqual(payload["summary"]["forced_usage_blocked_count"], 3)
        self.assertIn("no_value_safe_cut_source_after_forced_access", payload["candidate_copy_blockers"])
        self.assertEqual(
            payload["recovery_actions"][0]["action"],
            "mine_new_value_safe_cut_source_before_package_resynthesis",
        )

    def test_routes_to_existing_reduced_scope_materializer_when_pair_is_ready(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        payload = synthesizer.build_report(
            package_synthesis_report=write_json(root, "package.json", package_payload()),
            cut_source_report=write_json(root, "cuts.json", cut_payload(value_safe=1, forced_usage=0)),
            scope_reducer_report=write_json(root, "reducer.json", reducer_payload(scoped_pairs=1, value_safe=1, forced_usage=0)),
            profile_repair_report=write_json(root, "profile.json", profile_payload()),
            payoff_source_report=write_json(root, "payoff.json", {"summary": {"ready_candidate_count": 30}}),
        )

        self.assertEqual(payload["status"], "post_forced_recovery_has_reduced_scope_materializer_route")
        self.assertTrue(payload["candidate_copy_allowed_now"])
        self.assertEqual(payload["summary"]["next_gate"], "materialize_reduced_scope_candidate_copy")


if __name__ == "__main__":
    unittest.main()
