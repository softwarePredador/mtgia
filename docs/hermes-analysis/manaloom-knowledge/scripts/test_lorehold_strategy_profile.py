import unittest
from collections import Counter

import lorehold_strategy_profile as profile


class LoreholdStrategyProfileTests(unittest.TestCase):
    def test_pressure_absorber_anchor_is_recognized(self):
        card = {
            "card_name": "Crawlspace",
            "roles": ["protection", "stax"],
            "type_line": "Artifact",
            "oracle_text": "No more than two creatures can attack you each combat.",
            "cmc": 3,
            "in_active_deck": True,
        }

        tags = profile.strategy_tags_for_card(card)
        breakdown = profile.strategy_score_breakdown(card)

        self.assertIn("pressure_absorber", tags)
        self.assertIn("protection_window", tags)
        self.assertGreaterEqual(breakdown["active_strategy_anchor"], 15.0)

    def test_gap_fill_prioritizes_missing_miracle_setup(self):
        card = {
            "card_name": "Sensei's Divining Top",
            "roles": ["draw"],
            "type_line": "Artifact",
            "oracle_text": "Look at the top three cards of your library.",
            "cmc": 1,
        }

        score = profile.strategy_score(
            card,
            current_counts=Counter({"topdeck_miracle_setup": 0, "early_plan": 0}),
        )

        self.assertGreater(score, 10.0)

    def test_active_fast_mana_is_strategy_anchor(self):
        card = {
            "card_name": "Lotus Petal",
            "roles": ["ramp"],
            "type_line": "Artifact",
            "oracle_text": "Sacrifice Lotus Petal: Add one mana of any color.",
            "cmc": 0,
            "in_active_deck": True,
        }

        tags = profile.strategy_tags_for_card(card)
        breakdown = profile.strategy_score_breakdown(card)

        self.assertIn("early_plan", tags)
        self.assertIn("spell_chain_conversion", tags)
        self.assertGreaterEqual(breakdown["active_strategy_anchor"], 10.0)

    def test_active_finisher_cut_risk_is_high(self):
        card = {
            "card_name": "Aetherflux Reservoir",
            "roles": ["wincon"],
            "type_line": "Artifact",
            "oracle_text": "Whenever you cast a spell, you gain life.",
            "cmc": 4,
            "in_active_deck": True,
        }

        breakdown = profile.strategy_score_breakdown(card)

        self.assertGreaterEqual(breakdown["active_strategy_anchor"], 25.0)
        self.assertTrue(profile.force_keep_active_anchor(card))

    def test_active_pilot_core_cards_are_force_kept(self):
        cases = [
            (
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                {"early_plan", "hand_filter", "spell_chain_conversion"},
            ),
            ("Flawless Maneuver", {"pressure_absorber", "protection_window"}),
            ("Get Lost", {"early_plan", "pressure_absorber"}),
            ("Mother of Runes", {"early_plan", "protection_window"}),
        ]

        for name, expected_tags in cases:
            with self.subTest(name=name):
                card = {
                    "card_name": name,
                    "roles": [],
                    "type_line": "Instant",
                    "oracle_text": "",
                    "cmc": 2,
                    "in_active_deck": True,
                }

                tags = profile.strategy_tags_for_card(card)
                breakdown = profile.strategy_score_breakdown(card)

                self.assertTrue(expected_tags.issubset(tags))
                self.assertGreaterEqual(breakdown["active_strategy_anchor"], 14.0)
                self.assertTrue(profile.force_keep_active_anchor(card))

    def test_strategy_shortfalls_are_package_specific(self):
        card = {
            "card_name": "Silence",
            "roles": ["protection"],
            "type_line": "Instant",
            "oracle_text": "Your opponents can't cast spells this turn.",
            "cmc": 1,
        }
        counts = profile.strategy_counts([card])
        shortfalls = profile.strategy_shortfalls([card])

        self.assertEqual(counts["protection_window"], 1)
        self.assertEqual(shortfalls["protection_window"]["actual"], 1)
        self.assertIn("pressure_absorber", shortfalls)

    def test_commander_intent_alignment_penalizes_overfilled_ramp(self):
        cards = [
            {
                "card_name": f"Ramp Piece {idx}",
                "roles": ["ramp"],
                "type_line": "Artifact",
                "oracle_text": "Add one mana of any color.",
                "cmc": 2,
            }
            for idx in range(40)
        ]

        alignment = profile.commander_intent_alignment(cards)

        self.assertEqual(alignment["role_ranges"]["ramp"]["status"], "overfilled")
        self.assertEqual(alignment["package_ranges"]["early_plan"]["status"], "aligned")
        self.assertLess(alignment["score"], 55.0)
        self.assertIn("role_ramp_overfilled", alignment["risks"])

    def test_commander_intent_model_requires_battle_proof(self):
        self.assertIn("deck_607", profile.COMMANDER_INTENT_MODEL["validation_rule"])
        self.assertIn("Winota", profile.COMMANDER_INTENT_MODEL["validation_rule"])

    def test_lorehold_specific_runtime_learnings_are_plan_aligned(self):
        cases = {
            "Longshot, Rebel Bowman": {"deterministic_finisher", "early_plan", "spell_chain_conversion"},
            "Molecule Man": {"topdeck_miracle_setup", "spell_chain_conversion"},
            "Penance": {"topdeck_miracle_setup", "protection_window", "pressure_absorber"},
            "The Scarlet Witch": {"early_plan", "spell_chain_conversion"},
            "Promise of Loyalty": {"pressure_absorber", "protection_window"},
            "Tragic Arrogance": {"pressure_absorber"},
        }

        for name, expected_tags in cases.items():
            with self.subTest(name=name):
                tags = profile.strategy_tags_for_card(
                    {
                        "card_name": name,
                        "roles": [],
                        "type_line": "Sorcery",
                        "oracle_text": "",
                        "cmc": 3,
                    }
                )
                self.assertTrue(expected_tags.issubset(tags))

    def test_pressure_payoff_package_cards_are_plan_aligned(self):
        cases = {
            "Monastery Mentor": {"pressure_absorber", "spell_chain_conversion"},
            "Young Pyromancer": {"pressure_absorber", "spell_chain_conversion"},
            "Storm-Kiln Artist": {"early_plan", "spell_chain_conversion"},
            "Guttersnipe": {"deterministic_finisher", "spell_chain_conversion"},
        }

        for name, expected_tags in cases.items():
            with self.subTest(name=name):
                tags = profile.strategy_tags_for_card(
                    {
                        "card_name": name,
                        "roles": [],
                        "type_line": "Creature",
                        "oracle_text": "",
                        "cmc": 3,
                    }
                )
                self.assertTrue(expected_tags.issubset(tags))


if __name__ == "__main__":
    unittest.main()
