#!/usr/bin/env python3
"""Tests for scryfall_classifier multi-tag output contract."""

from __future__ import annotations

import unittest

import scryfall_classifier


class ScryfallClassifierMultiTagTests(unittest.TestCase):
    def test_external_sacrifice_outlet_classifier_matches_dart_contract(self) -> None:
        cases = {
            "Altar of Dementia": (
                "Sacrifice a creature: Target player mills cards equal to its power.",
                True,
            ),
            "Army Ants": ("{T}, Sacrifice a land: Destroy target land.", True),
            "Alquist Proft, Master Sleuth": (
                "When Alquist Proft enters, investigate. (Create a Clue token. "
                "It's an artifact with \"{2}, Sacrifice this token: Draw a card.\")\n"
                "{X}{W}{U}{U}, {T}, Sacrifice a Clue: Draw X cards.",
                True,
            ),
            "Angel's Herald": (
                "{2}{W}, {T}, Sacrifice a green creature, a white creature, and "
                "a blue creature: Search your library for a card.",
                True,
            ),
            "Baba Lysaga, Night Witch": (
                "{T}, Sacrifice up to three permanents: Draw three cards.",
                True,
            ),
            "Animal Boneyard": (
                "Enchant land\nEnchanted land has \"{T}, Sacrifice a creature: "
                "You gain life equal to its toughness.\"",
                True,
            ),
            "Choice Vessel": (
                "Sacrifice this artifact or another artifact: Add {C}{C}.",
                True,
            ),
            "Lotus Petal": (
                "{T}, Sacrifice this artifact: Add one mana of any color.",
                False,
            ),
            "Abandoned Outpost": (
                "{T}: Add {W}.\n{T}, Sacrifice this land: Add one mana of any color.",
                False,
            ),
            "Arek, False Goldwarden": (
                "{3}{W}{B}, {T}, Sacrifice Arek, False Goldwarden: Drain X.",
                False,
            ),
            "Adric, Mathematical Genius": (
                "Ultimate Sacrifice — {1}{U}, Sacrifice Adric: Counter target ability.",
                False,
            ),
            "A-Haywire Mite": (
                "{G}, Sacrifice Haywire Mite: Exile target artifact.",
                False,
            ),
            "Placeholder Vessel": ("{1}, Sacrifice ~: Draw a card.", False),
            "Ancestors' Aid": (
                "Create a Treasure token. (It's an artifact with \"{T}, "
                "Sacrifice this token: Add one mana of any color.\")",
                False,
            ),
            "Apocalypse Demon": (
                "At the beginning of your upkeep, tap this creature unless you "
                "sacrifice another creature.",
                False,
            ),
            "Ashad, the Lone Cyberman": (
                "This spell has casualty 2. (As you cast it, you may sacrifice a "
                "creature with power 2 or greater. When you do, copy it.)",
                False,
            ),
            "Village Rites": (
                "As an additional cost to cast this spell, sacrifice a creature. "
                "Draw two cards.",
                False,
            ),
            "Alchemist's Talent": (
                "Treasures you control have \"{T}, Sacrifice this artifact: Add "
                "two mana of any one color.\"",
                False,
            ),
        }

        for name, (oracle, expected) in cases.items():
            with self.subTest(name=name):
                tags = scryfall_classifier.infer_functional_card_tags(
                    name=name,
                    type_line="Artifact Creature — Test",
                    oracle_text=oracle,
                )
                outlet_tags = [
                    tag for tag in tags if tag["tag"] == "sacrifice_outlet"
                ]
                self.assertEqual(bool(outlet_tags), expected)
                if expected:
                    self.assertEqual(
                        outlet_tags[0]["evidence"],
                        "external_activated_sacrifice_outlet_cost",
                    )

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

    def test_build_deck_json_infers_commander_color_identity(self) -> None:
        deck = scryfall_classifier.build_deck_json(
            "Kinnan, Bonder Prodigy",
            [
                {
                    "name": "Kinnan, Bonder Prodigy",
                    "qty": 1,
                    "set_code": "",
                    "tag_comment": "Commander",
                    "functional_tag": "engine",
                    "functional_tags_json": ["engine", "ramp"],
                    "tags": [
                        {
                            "tag": "engine",
                            "confidence": 0.9,
                            "evidence": "fixture",
                        },
                        {
                            "tag": "ramp",
                            "confidence": 0.8,
                            "evidence": "fixture",
                        },
                    ],
                    "cmc": 2,
                    "type_line": "Legendary Creature — Human Druid",
                    "color_identity": ["G", "U"],
                },
                {
                    "name": "Sol Ring",
                    "qty": 1,
                    "set_code": "",
                    "tag_comment": "",
                    "functional_tag": "ramp",
                    "functional_tags_json": ["ramp"],
                    "tags": [
                        {
                            "tag": "ramp",
                            "confidence": 0.9,
                            "evidence": "fixture",
                        }
                    ],
                    "cmc": 1,
                    "type_line": "Artifact",
                    "color_identity": [],
                },
            ],
        )

        self.assertEqual(deck["color_identity"], "GU")
        self.assertEqual(deck["cards"][0]["color_identity"], "GU")


if __name__ == "__main__":
    unittest.main()
