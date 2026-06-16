#!/usr/bin/env python3
"""Tests for battle_effect_coverage_audit known-cards source classification."""

from __future__ import annotations

import unittest

import battle_effect_coverage_audit as audit


class BattleEffectCoverageKnownCardsTests(unittest.TestCase):
    def test_effect_source_prefers_canonical_snapshot_over_generated(self) -> None:
        source = audit.effect_source(
            {"name": "Alpha Card", "type_line": "Instant"},
            {"Alpha Card": {"effect": "counter"}},
            {"Alpha Card"},
            set(),
            {},
        )

        self.assertEqual(source, "known_cards_canonical_snapshot")

    def test_effect_source_uses_generated_when_card_is_legacy_only(self) -> None:
        source = audit.effect_source(
            {"name": "Beta Card", "type_line": "Instant"},
            {"Beta Card": {"effect": "tutor"}},
            set(),
            {"Beta Card"},
            {},
        )

        self.assertEqual(source, "generated")


if __name__ == "__main__":
    unittest.main()
