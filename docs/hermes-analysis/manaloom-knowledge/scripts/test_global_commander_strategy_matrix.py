#!/usr/bin/env python3
"""Tests for global Commander strategy matrix routing."""

from __future__ import annotations

import unittest

from global_commander_strategy_matrix import (
    build_matrix,
    commander_intent_lane_count,
    empty_source_signals,
    normalize_commander,
    readiness_status,
)


class GlobalCommanderStrategyMatrixTests(unittest.TestCase):
    def test_normalize_commander_collapses_whitespace_and_case(self) -> None:
        self.assertEqual(
            normalize_commander("  Lorehold,   The Historian "),
            "lorehold, the historian",
        )

    def test_readiness_requires_structure_and_source_lane(self) -> None:
        self.assertEqual(
            readiness_status(
                ready_count=1,
                product_ready_count=1,
                source_lanes=1,
                commander_intent_lanes=1,
                blocked_count=0,
            ),
            "ready_for_strategy_matrix",
        )
        self.assertEqual(
            readiness_status(
                ready_count=1,
                product_ready_count=1,
                source_lanes=0,
                commander_intent_lanes=0,
                blocked_count=0,
            ),
            "structure_ready_source_missing",
        )
        self.assertEqual(
            readiness_status(
                ready_count=0,
                product_ready_count=0,
                source_lanes=0,
                commander_intent_lanes=0,
                blocked_count=1,
            ),
            "blocked_before_global_promotion",
        )

    def test_build_matrix_keeps_blocked_product_separate_from_ready_lab(self) -> None:
        source_signals = {
            "lorehold, the historian": {
                **empty_source_signals(),
                "reference_profile_count": 1,
            }
        }
        payload = build_matrix(
            [
                {
                    "source": "postgres",
                    "scope": "user_product",
                    "status": "needs_repair",
                    "issues": ["quantity_not_100"],
                    "deck_id": "bad",
                    "deck_name": "Incomplete Lorehold",
                    "commander": "Lorehold, the Historian",
                    "commander_key": "lorehold, the historian",
                    "quantity": 2,
                    "commander_count": 1,
                },
                {
                    "source": "hermes",
                    "scope": "hermes_lorehold_variant",
                    "status": "structure_ready",
                    "issues": [],
                    "deck_id": "607",
                    "deck_name": "VARIANT Lorehold",
                    "commander": "Lorehold, the Historian",
                    "commander_key": "lorehold, the historian",
                    "quantity": 100,
                    "commander_count": 1,
                },
            ],
            source_signals,
        )

        row = payload["commanders"][0]
        self.assertEqual(row["status"], "ready_for_strategy_matrix")
        self.assertEqual(row["ready_deck_count"], 1)
        self.assertEqual(row["lab_ready_deck_count"], 1)
        self.assertEqual(row["blocked_product_deck_count"], 1)
        self.assertEqual(row["blocked_issue_counts"], {"quantity_not_100": 1})

    def test_usage_or_learned_lane_does_not_replace_commander_intent_profile(self) -> None:
        signals = {
            **empty_source_signals(),
            "learned_deck_count": 1,
            "card_usage_count": 90,
        }
        payload = build_matrix(
            [
                {
                    "source": "postgres",
                    "scope": "user_product",
                    "status": "structure_ready",
                    "issues": [],
                    "deck_id": "animar",
                    "deck_name": "Animar",
                    "commander": "Animar, Soul of Elements",
                    "commander_key": "animar, soul of elements",
                    "quantity": 100,
                    "commander_count": 1,
                }
            ],
            {"animar, soul of elements": signals},
        )

        row = payload["commanders"][0]
        self.assertEqual(row["source_lane_count"], 2)
        self.assertEqual(row["commander_intent_lane_count"], 0)
        self.assertEqual(row["status"], "structure_ready_intent_profile_missing")
        self.assertIn("commander_intent_profile", row["next_gate"])
        self.assertEqual(commander_intent_lane_count(signals), 0)

    def test_build_matrix_records_skipped_source_lane_mode_for_commander_without_local_profile(self) -> None:
        payload = build_matrix(
            [
                {
                    "source": "hermes",
                    "scope": "hermes_registered_variant",
                    "status": "structure_ready",
                    "issues": [],
                    "deck_id": "617",
                    "deck_name": "VARIANT Kefka",
                    "commander": "Kefka, Court Mage // Kefka, Ruler of Ruin",
                    "commander_key": "kefka, court mage // kefka, ruler of ruin",
                    "quantity": 100,
                    "commander_count": 1,
                }
            ],
            {"kefka, court mage // kefka, ruler of ruin": empty_source_signals()},
            source_lane_mode="skipped_postgres_source_lanes",
        )

        self.assertEqual(payload["method"]["source_lane_mode"], "skipped_postgres_source_lanes")
        self.assertFalse(payload["method"]["source_lanes_available"])
        self.assertEqual(payload["commanders"][0]["status"], "structure_ready_source_missing")

    def test_local_runtime_profile_counts_as_source_lane_when_postgres_is_skipped(self) -> None:
        payload = build_matrix(
            [
                {
                    "source": "hermes",
                    "scope": "hermes_registered_variant",
                    "status": "structure_ready",
                    "issues": [],
                    "deck_id": "619",
                    "deck_name": "VARIANT Kaalia",
                    "commander": "Kaalia of the Vast",
                    "commander_key": "kaalia of the vast",
                    "quantity": 100,
                    "commander_count": 1,
                }
            ],
            {"kaalia of the vast": empty_source_signals()},
            source_lane_mode="skipped_postgres_source_lanes",
        )

        row = payload["commanders"][0]
        self.assertEqual(row["status"], "ready_for_strategy_matrix")
        self.assertEqual(row["source_lane_count"], 1)
        self.assertEqual(row["source_signals"]["local_runtime_profile_count"], 1)
        self.assertTrue(payload["method"]["source_lanes_available"])
        self.assertIn("kaalia of the vast", payload["method"]["local_runtime_reference_profiles"])


if __name__ == "__main__":
    unittest.main()
