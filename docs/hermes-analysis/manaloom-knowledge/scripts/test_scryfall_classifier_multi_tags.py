#!/usr/bin/env python3
"""Tests for scryfall_classifier multi-tag output contract."""

from __future__ import annotations

import unittest

import scryfall_classifier


class ScryfallClassifierMultiTagTests(unittest.TestCase):
    def test_classify_deck_emits_tags_and_functional_tags_json(self) -> None:
        old_fetch_cards = scryfall_classifier.fetch_cards
        try:
            scryfall_classifier.fetch_cards = lambda _names: {
                "test charm": {
                    "object": "card",
                    "name": "Test Charm",
                    "type_line": "Instant",
                    "oracle_text": "Destroy target artifact. Draw a card.",
                    "cmc": 2,
                }
            }

            enriched = scryfall_classifier.classify_deck([
                {
                    "name": "Test Charm",
                    "qty": 1,
                    "set_code": "",
                    "tag_comment": "",
                }
            ])
        finally:
            scryfall_classifier.fetch_cards = old_fetch_cards

        self.assertEqual(enriched[0]["functional_tag"], "draw")
        self.assertEqual(enriched[0]["functional_tags_json"], ["draw", "removal"])
        self.assertEqual(
            [tag["tag"] for tag in enriched[0]["tags"]],
            ["draw", "removal"],
        )

    def test_build_deck_json_maps_board_wipe_tag_to_legacy_wipe_role(self) -> None:
        deck = scryfall_classifier.build_deck_json(
            "Lorehold, the Historian",
            [
                {
                    "name": "Wrath Variant",
                    "qty": 2,
                    "set_code": "",
                    "tag_comment": "",
                    "functional_tag": "wipe",
                    "functional_tags_json": ["board_wipe"],
                    "tags": [
                        {
                            "tag": "board_wipe",
                            "confidence": 0.9,
                            "evidence": "mass_removal_text",
                        }
                    ],
                    "cmc": 4,
                    "type_line": "Sorcery",
                }
            ],
        )

        self.assertEqual(deck["board_wipe_count"], 2)
        self.assertEqual(deck["cards"][0]["functional_tag"], "wipe")
        self.assertEqual(deck["cards"][0]["functional_tags_json"], ["board_wipe"])

    def test_user_override_adds_high_confidence_tag_without_losing_inferred_tags(self) -> None:
        old_fetch_cards = scryfall_classifier.fetch_cards
        try:
            scryfall_classifier.fetch_cards = lambda _names: {
                "commented spell": {
                    "object": "card",
                    "name": "Commented Spell",
                    "type_line": "Instant",
                    "oracle_text": "Draw a card.",
                    "cmc": 2,
                }
            }

            enriched = scryfall_classifier.classify_deck([
                {
                    "name": "Commented Spell",
                    "qty": 1,
                    "set_code": "",
                    "tag_comment": "Interaction",
                }
            ])
        finally:
            scryfall_classifier.fetch_cards = old_fetch_cards

        self.assertEqual(enriched[0]["functional_tag"], "removal")
        self.assertEqual(enriched[0]["functional_tags_json"], ["removal", "draw"])
        self.assertEqual(enriched[0]["tags"][0]["evidence"], "user_tag_comment")


if __name__ == "__main__":
    unittest.main()
