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


if __name__ == "__main__":
    unittest.main()
