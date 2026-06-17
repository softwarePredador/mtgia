#!/usr/bin/env python3
"""Tests for battle_effect_coverage_audit known-cards source classification."""

from __future__ import annotations

import unittest

import battle_effect_coverage_audit as audit


class BattleEffectCoverageKnownCardsTests(unittest.TestCase):
    def test_effect_source_prefers_canonical_snapshot_over_generated(self) -> None:
        source = audit.effect_source(
            {"name": "Alpha Card", "type_line": "Instant"},
            {"Alpha Card"},
            {},
        )

        self.assertEqual(source, "known_cards_canonical_snapshot")

    def test_effect_source_rejects_legacy_only_generated_fallback_as_runtime_truth(self) -> None:
        source = audit.effect_source(
            {"name": "Beta Card", "type_line": "Instant"},
            set(),
            {},
        )

        self.assertEqual(source, "unknown")


if __name__ == "__main__":
    unittest.main()
