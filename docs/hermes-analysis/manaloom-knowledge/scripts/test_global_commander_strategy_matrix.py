#!/usr/bin/env python3
"""Tests for global Commander strategy matrix routing."""

from __future__ import annotations

import unittest

from global_commander_strategy_matrix import (
    build_matrix,
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
                blocked_count=0,
            ),
            "ready_for_strategy_matrix",
        )
        self.assertEqual(
            readiness_status(
                ready_count=1,
                product_ready_count=1,
                source_lanes=0,
                blocked_count=0,
            ),
            "structure_ready_source_missing",
        )
        self.assertEqual(
            readiness_status(
                ready_count=0,
                product_ready_count=0,
                source_lanes=0,
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


if __name__ == "__main__":
    unittest.main()
