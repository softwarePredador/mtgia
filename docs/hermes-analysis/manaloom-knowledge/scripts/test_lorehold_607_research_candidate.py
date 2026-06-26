import unittest

import lorehold_607_research_candidate as research


class Lorehold607ResearchCandidateTest(unittest.TestCase):
    def test_penance_plan_is_one_card_ablation(self):
        plan = research.RESEARCH_PLANS["penance_v1"]
        self.assertEqual(plan["base_deck_id"], 607)
        self.assertEqual(plan["candidate_deck_id"], 6)
        self.assertEqual(plan["added"], [{"card_name": "Penance", "source_deck_id": 609}])
        self.assertEqual(plan["removed"], ["Promise of Loyalty"])

    def test_birgi_plan_is_same_function_sidegrade(self):
        plan = research.RESEARCH_PLANS["birgi_v1"]
        self.assertEqual(
            plan["added"],
            [{"card_name": "Birgi, God of Storytelling // Harnfel, Horn of Bounty", "source_deck_id": 615}],
        )
        self.assertEqual(plan["removed"], ["Bender's Waterskin"])

    def test_longshot_plan_is_one_card_ablation(self):
        plan = research.RESEARCH_PLANS["longshot_v1"]
        self.assertEqual(plan["added"], [{"card_name": "Longshot, Rebel Bowman", "source_deck_id": 615}])
        self.assertEqual(plan["removed"], ["Storm Herd"])

    def test_reprieve_plan_is_same_function_counter_sidegrade(self):
        plan = research.RESEARCH_PLANS["reprieve_v1"]
        self.assertEqual(plan["added"], [{"card_name": "Reprieve", "source_deck_id": 612}])
        self.assertEqual(plan["removed"], ["Tibalt's Trickery"])

    def test_galvanoth_plan_is_expensive_topdeck_value_sidegrade(self):
        plan = research.RESEARCH_PLANS["galvanoth_v1"]
        self.assertEqual(plan["added"], [{"card_name": "Galvanoth", "source_deck_id": 614}])
        self.assertEqual(plan["removed"], ["Creative Technique"])

    def test_ghostly_prison_plan_is_stax_pressure_sidegrade(self):
        plan = research.RESEARCH_PLANS["ghostly_prison_v1"]
        self.assertEqual(plan["added"], [{"card_name": "Ghostly Prison", "source_deck_id": 613}])
        self.assertEqual(plan["removed"], ["High Noon"])

    def test_guttersnipe_plan_is_spell_payoff_sidegrade(self):
        plan = research.RESEARCH_PLANS["guttersnipe_v1"]
        self.assertEqual(plan["added"], [{"card_name": "Guttersnipe", "source_deck_id": 615}])
        self.assertEqual(plan["removed"], ["Prismari Pianist"])

    def test_normalize_name(self):
        self.assertEqual(research.normalize_name("  Promise   of Loyalty "), "promise of loyalty")


if __name__ == "__main__":
    unittest.main()
