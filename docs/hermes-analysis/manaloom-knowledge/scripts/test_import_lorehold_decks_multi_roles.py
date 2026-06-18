#!/usr/bin/env python3
"""Tests for multi-role inference in the manual Lorehold importer."""

from __future__ import annotations

import unittest

import import_lorehold_decks


class ImportLoreholdDecksMultiRoleTests(unittest.TestCase):
    def test_infer_roles_preserves_multiple_roles_for_one_card(self) -> None:
        oracle = {
            "type_line": "Instant",
            "oracle_text": "Destroy target artifact. Draw a card.",
            "functional_tag": "",
        }

        roles = import_lorehold_decks.infer_roles("Prismari Command", oracle)

        self.assertEqual(roles, ["draw", "removal", "spell"])
        self.assertEqual(
            import_lorehold_decks.infer_role("Prismari Command", oracle),
            "draw",
        )

    def test_infer_roles_uses_legacy_functional_tag_as_overlay(self) -> None:
        oracle = {
            "type_line": "Enchantment",
            "oracle_text": "Whenever you cast your second spell each turn, draw a card.",
            "functional_tag": "engine, draw",
        }

        roles = import_lorehold_decks.infer_roles("Trouble in Pairs", oracle)

        self.assertEqual(roles, ["draw", "engine"])


if __name__ == "__main__":
    unittest.main()
