#!/usr/bin/env python3
"""Tests for global Commander land floor package synthesizer."""

from __future__ import annotations

import unittest

import global_commander_land_floor_package_synthesizer as audit


def land_floor_policy(gap: int = 2) -> dict:
    return {
        "deck_policy_rows": [
            {
                "deck_id": "900",
                "deck_name": "Deck 900",
                "commander": "Test Commander",
                "status": "land_floor_policy_ready_for_pair_preflight_no_deck_action",
                "current_land_count": 34 - gap,
                "target_land_floor": 34,
            }
        ]
    }


def named_land_pool(count: int = 3) -> dict:
    return {
        "candidate_pools": [
            {
                "deck_id": "900",
                "top_candidates": [
                    {"card_name": f"Fixing Land {idx}", "score": 100 - idx, "status": "review_only_named_land_candidate"}
                    for idx in range(1, count + 1)
                ],
            }
        ]
    }


def land_cut_model(count: int = 3) -> dict:
    return {
        "source_db": "docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db",
        "deck_cut_pools": [
            {
                "deck_id": "900",
                "top_cut_candidates": [
                    {
                        "card_name": f"Cut Spell {idx}",
                        "score": 80 - idx,
                        "status": "review_only_cut_candidate",
                        "roles": ["engine"],
                    }
                    for idx in range(1, count + 1)
                ],
            }
        ],
    }


class GlobalCommanderLandFloorPackageSynthesizerTests(unittest.TestCase):
    def test_synthesizes_full_land_gap_package_and_allows_candidate_copy(self) -> None:
        payload = audit.build_report(
            land_floor_policy_payload=land_floor_policy(gap=2),
            named_land_pool_payload=named_land_pool(count=3),
            land_cut_model_payload=land_cut_model(count=3),
            deck_id="900",
        )

        self.assertEqual(payload["status"], audit.READY_STATUS)
        self.assertTrue(payload["candidate_copy_allowed_now"])
        self.assertFalse(payload["battle_gate_allowed_now"])
        self.assertEqual(payload["summary"]["land_gap"], 2)
        self.assertEqual(payload["summary"]["selected_pair_count"], 2)
        self.assertEqual([row["role"] for row in payload["pairs"]], ["land", "land"])
        self.assertEqual(payload["pairs"][0]["add"], "Fixing Land 1")
        self.assertEqual(payload["pairs"][0]["cut"], "Cut Spell 1")

    def test_blocks_when_unique_pairs_do_not_cover_land_gap(self) -> None:
        payload = audit.build_report(
            land_floor_policy_payload=land_floor_policy(gap=3),
            named_land_pool_payload=named_land_pool(count=2),
            land_cut_model_payload=land_cut_model(count=3),
            deck_id="900",
        )

        self.assertEqual(payload["status"], audit.BLOCKED_STATUS)
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertEqual(payload["summary"]["selected_pair_count"], 2)
        self.assertIn("insufficient_unique_named_lands_or_cuts_to_cover_land_floor_gap", payload["candidate_copy_blockers"])


if __name__ == "__main__":
    unittest.main()
