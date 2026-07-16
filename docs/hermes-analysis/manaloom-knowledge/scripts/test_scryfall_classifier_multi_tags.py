#!/usr/bin/env python3
"""Tests for scryfall_classifier multi-tag output contract."""

from __future__ import annotations

import unittest

import scryfall_classifier


class ScryfallClassifierMultiTagTests(unittest.TestCase):
    def test_treasure_beneficiary_matrix_matches_dart_contract(self) -> None:
        negative_cases = {
            "An Offer You Can't Refuse": (
                "Counter target noncreature spell. Its controller creates two "
                "Treasure tokens. (They are artifacts with \"{T}, Sacrifice "
                "this token: Add one mana of any color.\")",
                "object_controller_compensation",
            ),
            "Buy Your Silence": (
                "Exile target nonland permanent. Its controller creates a "
                "Treasure token. (It is an artifact with \"{T}, Sacrifice "
                "this token: Add one mana of any color.\")",
                "object_controller_compensation",
            ),
            "Wanted Scoundrels": (
                "When this creature dies, target opponent creates two Treasure "
                "tokens. (They are artifacts with \"{T}, Sacrifice this token: "
                "Add one mana of any color.\")",
                "opponent_only",
            ),
            "Blooming Blast": (
                "Gift a Treasure (You may promise an opponent a gift as you cast "
                "this spell. If you do, they create a Treasure token. It is an "
                "artifact with \"{T}, Sacrifice this token: Add one mana of any "
                "color.\")\nBlooming Blast deals 2 damage to target creature.",
                "opponent_only",
            ),
            "Dockbreacher": (
                "If an opponent would create a Treasure token beyond the first "
                "one each turn, instead you draw a card.",
                "replacement_or_prevention_only",
            ),
            "Kitesail Larcenist": (
                "Chosen permanents become Treasure artifacts with \"{T}, "
                "Sacrifice this artifact: Add one mana of any color\" and lose "
                "all other abilities.",
                "transformation_only",
            ),
            "Minimus Containment": (
                "Enchanted permanent is a Treasure artifact with \"{T}, "
                "Sacrifice this artifact: Add one mana of any color,\" and it "
                "loses all other abilities.",
                "transformation_only",
            ),
            "Vraska, Betrayal's Sting": (
                "Target creature becomes a Treasure artifact with \"{T}, "
                "Sacrifice this artifact: Add one mana of any color\" and loses "
                "all other abilities.",
                "transformation_only",
            ),
            "Erestor of the Council": (
                "Whenever players finish voting, each opponent who voted for a "
                "choice you voted for creates a Treasure token.",
                "opponent_only",
            ),
            "North Pole Research Base": (
                "At the beginning of your upkeep, target opponent draws a card "
                "and creates a Treasure token.",
                "opponent_only",
            ),
        }
        positive_cases = {
            "Ancestors' Aid": (
                "Create a Treasure token.", "direct_self"),
            "Bloodroot Apothecary": (
                "You and target opponent each create a Treasure token.",
                "shared_includes_self"),
            "Gonti, Night Minister": (
                "Whenever a player casts a spell they do not own, that player "
                "creates a Treasure token.", "any_player_includes_self"),
            "Prismari Command": (
                "Target player creates a Treasure token.",
                "target_player_selectable"),
            "Bootleggers' Stash": (
                "Lands you control have \"{T}: Create a Treasure token.\"",
                "controlled_granted_ability"),
            "Diamond Pick-Axe": (
                "Equipped creature has \"Whenever this creature attacks, create "
                "a Treasure token.\"", "controlled_granted_ability"),
            "Hoarding Ogre": (
                "Whenever this creature attacks, roll a d20.\n"
                "1—9 | Create a Treasure token.\n"
                "10—19 | Create two Treasure tokens.", "direct_self"),
        }

        for name, (oracle, expected_signal) in negative_cases.items():
            with self.subTest(name=name):
                self.assertEqual(
                    expected_signal,
                    scryfall_classifier.classify_treasure_ramp(oracle),
                )
                self.assertFalse(scryfall_classifier.looks_like_ramp(oracle, ""))
                tags = scryfall_classifier.infer_functional_card_tags(
                    name=name, type_line="Instant", oracle_text=oracle)
                tag_names = {tag["tag"] for tag in tags}
                self.assertNotIn("ramp", tag_names)
                self.assertNotIn("token_maker", tag_names)

        for name, (oracle, expected_signal) in positive_cases.items():
            with self.subTest(name=name):
                self.assertEqual(
                    expected_signal,
                    scryfall_classifier.classify_treasure_ramp(oracle),
                )
                self.assertTrue(scryfall_classifier.looks_like_ramp(oracle, ""))
                tags = scryfall_classifier.infer_functional_card_tags(
                    name=name, type_line="Artifact", oracle_text=oracle)
                self.assertIn("ramp", {tag["tag"] for tag in tags})

    def test_quoted_mana_and_land_type_boundaries_match_dart(self) -> None:
        controlled = (
            'Creatures you control have "{T}: Add one mana of any color."')
        transformed = (
            'Target creature becomes an artifact with "{T}: Add one mana of '
            'any color" and loses all other abilities.')
        target_land_fixing = (
            'Exile this card from your hand: Target land gains '
            '"{T}: Add {G}, {W}, or {U}."')
        self.assertTrue(scryfall_classifier.looks_like_ramp(controlled, ""))
        self.assertFalse(scryfall_classifier.looks_like_ramp(transformed, ""))
        self.assertFalse(scryfall_classifier.looks_like_ramp(
            target_land_fixing, ""))
        self.assertTrue(scryfall_classifier.looks_like_ramp(
            'Target land gains "{T}: Add {G}{G}{G}" until end of turn.', ""))
        toxicrene = (
            'Reach, deathtouch\nHypertoxic Miasma — All lands have '
            '"{T}: Add one mana of any color" and lose all other abilities.')
        self.assertFalse(scryfall_classifier.looks_like_ramp(toxicrene, ""))

        land_tags = scryfall_classifier.infer_functional_card_tags(
            name="Ancient Tomb",
            type_line="Land",
            oracle_text="{T}: Add {C}{C}.",
        )
        self.assertEqual({"land"}, {tag["tag"] for tag in land_tags})
        lander_tags = scryfall_classifier.infer_functional_card_tags(
            name="Lander Rizzi",
            type_line="Legendary Artifact Creature — Lander Rogue",
            oracle_text="{T}: Add one mana of any color.",
        )
        self.assertNotIn("land", {tag["tag"] for tag in lander_tags})
        self.assertIn("ramp", {tag["tag"] for tag in lander_tags})

    def test_compound_tap_mana_ability_is_not_ritual(self) -> None:
        oracle = (
            "{T}, Exile a card from your graveyard: Add {R}. When you do, this "
            "creature deals 1 damage to each opponent.")
        tags = scryfall_classifier.infer_functional_card_tags(
            name="Rubble Rouser",
            type_line="Creature — Dwarf Sorcerer",
            oracle_text=oracle,
        )
        names = {tag["tag"] for tag in tags}
        self.assertIn("ramp", names)
        self.assertNotIn("ritual", names)

    def test_ramp_classifier_separates_permission_from_production(self) -> None:
        negative_cases = {
            "Nita, Forum Conciliator": (
                "Whenever you cast a spell you don't own, put a +1/+1 counter "
                "on each creature you control.\n"
                "{2}, Sacrifice another creature: Exile target instant or "
                "sorcery card from an opponent's graveyard. You may cast it "
                "this turn, and mana of any type can be spent to cast that "
                "spell. If that spell would be put into a graveyard, exile "
                "it instead. Activate only as a sorcery."
            ),
            "Generic color permission": (
                "You may cast that spell, and mana of any color can be spent "
                "to cast it."
            ),
            "As though permission": (
                "You may spend mana as though it were mana of any color to "
                "cast spells from exile."
            ),
        }
        positive_cases = {
            "Ronin, Shadow Stalker": (
                "Pay 2 life: Add two mana of any one color. Spend this mana "
                "only to cast Equipment spells or activate equip abilities."
            ),
            "Arcane Signet": (
                "{T}: Add one mana of any color in your commander's color "
                "identity."
            ),
        }

        for name, oracle in negative_cases.items():
            with self.subTest(name=name):
                self.assertFalse(scryfall_classifier.looks_like_ramp(oracle, ""))
                tags = scryfall_classifier.infer_functional_card_tags(
                    name=name,
                    type_line="Legendary Creature — Human Advisor",
                    oracle_text=oracle,
                )
                self.assertNotIn("ramp", {tag["tag"] for tag in tags})

        for name, oracle in positive_cases.items():
            with self.subTest(name=name):
                self.assertTrue(scryfall_classifier.looks_like_ramp(oracle, ""))
                tags = scryfall_classifier.infer_functional_card_tags(
                    name=name,
                    type_line="Artifact",
                    oracle_text=oracle,
                )
                self.assertIn("ramp", {tag["tag"] for tag in tags})

    def test_ramp_classifier_preserves_six_alternate_accelerators(self) -> None:
        cases = {
            "Gonti, Canny Acquisitor": (
                "Legendary Creature — Aetherborn Rogue",
                "Spells you cast but don't own cost {1} less to cast.\n"
                "You may play that card for as long as it remains exiled, and "
                "mana of any type can be spent to cast that spell.",
            ),
            "Gonti, Night Minister": (
                "Legendary Creature — Aetherborn Rogue",
                "Whenever a player casts a spell they don't own, that player "
                "creates a Treasure token.\nMana of any type can be spent to "
                "cast a spell this way.",
            ),
            "Manascape Refractor": (
                "Artifact",
                "This artifact enters tapped.\nThis artifact has all activated "
                "abilities of all lands on the battlefield.\nYou may spend mana "
                "as though it were mana of any color to pay the activation costs "
                "of this artifact's abilities.",
            ),
            "The Snapstone Wielder": (
                "Legendary Creature — Human Gamer",
                "At the beginning of your upkeep, you get a mana counter. During "
                "each of your turns, you can spend mana of any color equal to the "
                "number of mana counters you have.",
            ),
            "Fallaji Wayfarer": (
                "Creature — Human Scout",
                "This ability doesn't affect its color identity. Multicolored "
                "spells you cast have convoke.",
            ),
            "The Paradise Bird": (
                "Legendary Creature — Bird",
                "{G}, {T}: Create a Birds of Paradise token. If this creature is "
                "your commander, your deck can include cards of any color identity.",
            ),
        }

        for name, (type_line, oracle) in cases.items():
            with self.subTest(name=name):
                self.assertTrue(scryfall_classifier.looks_like_ramp(oracle, type_line))
                tags = scryfall_classifier.infer_functional_card_tags(
                    name=name,
                    type_line=type_line,
                    oracle_text=oracle,
                )
                self.assertIn("ramp", {tag["tag"] for tag in tags})

    def test_ramp_classifier_preserves_contextual_controller_acceleration(self) -> None:
        cases = {
            "Charmed Pendant": (
                "{T}, Mill a card: For each colored mana symbol in the milled "
                "card's mana cost, add one mana of that color."),
            "Diabolical Salvation": (
                "Create four Devil tokens with haste and \"When this creature "
                "dies, create a colorless Treasure artifact token with "
                "'{T}, Sacrifice this artifact: Add one mana of any color.'\""),
            "Done for the Day": (
                "You may get {TK} or create a Treasure token."),
            "Garruk's Lost Wolf": (
                "Create a Huntsman Role token attached to another target "
                "creature you control. (Enchanted creature gets +1/+1 and has "
                "\"{T}: Add {G}\")"),
            "Gluntch, the Bestower": (
                "Choose a player to draw a card. Then choose a third player "
                "to create two Treasure tokens."),
            "Item Crate": (
                "Create a tapped colorless token at random with the listed "
                "name and ability.\n• Banana with \"{T}, Sacrifice this token: "
                "Add {R} or {G}.\""),
            "Kibo, Uktabi Prince": (
                "{T}: Each player creates a colorless artifact token named "
                "Banana with \"{T}, Sacrifice this token: Add {R} or {G}.\""),
            "Oddric, Lunar Marquis": (
                "Creatures you control gain the activated ability \"Sacrifice "
                "this creature: Add {C}.\""),
            "Pain Distributor": (
                "Whenever a player casts their first spell each turn, they "
                "create a Treasure token."),
            "Racketeer Boss": (
                "Choose up to two creature cards in your hand. They perpetually "
                "gain \"When you cast this spell, create a Treasure token.\""),
            "You Compleat Me": (
                "You get an emblem with \"Pay 2 life: Add one mana of any color\"."),
            "Firebending Adept": (
                "Creatures you control have firebending 1."),
        }

        for name, oracle in cases.items():
            with self.subTest(name=name):
                self.assertTrue(scryfall_classifier.looks_like_ramp(oracle, ""))

    def test_mechanic_and_token_name_collisions_do_not_become_ramp(self) -> None:
        self.assertFalse(scryfall_classifier.looks_like_ramp(
            "Firebending Lesson deals 3 damage to any target.", ""))
        self.assertFalse(scryfall_classifier.looks_like_ramp(
            "Create a 2/2 gold Dragon creature token with flying.", ""))
        self.assertTrue(scryfall_classifier.looks_like_ramp(
            "Creatures you control have firebending 1.", ""))
        self.assertTrue(scryfall_classifier.looks_like_ramp(
            "Create a Gold token.", ""))

    def test_ramp_classifier_matches_dart_land_untap_and_refund_lanes(self) -> None:
        cases = {
            "Peregrine Drake": (
                "Creature — Drake",
                "Flying\nWhen Peregrine Drake enters, untap up to five lands.",
            ),
            "High Tide": (
                "Instant",
                "Until end of turn, whenever a player taps an Island for mana, "
                "that player adds an additional {U}.",
            ),
        }

        for name, (type_line, oracle) in cases.items():
            with self.subTest(name=name):
                self.assertTrue(scryfall_classifier.looks_like_ramp(oracle, type_line))
                tags = scryfall_classifier.infer_functional_card_tags(
                    name=name,
                    type_line=type_line,
                    oracle_text=oracle,
                )
                self.assertIn("ramp", {tag["tag"] for tag in tags})

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
