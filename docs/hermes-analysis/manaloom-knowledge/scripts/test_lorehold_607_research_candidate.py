import unittest

import lorehold_607_research_candidate as research


class Lorehold607ResearchCandidateTest(unittest.TestCase):
    def test_penance_plan_is_one_card_ablation(self):
        plan = research.RESEARCH_PLANS["penance_v1"]
        self.assertEqual(plan["base_deck_id"], 607)
        self.assertEqual(plan["candidate_deck_id"], 6)
        self.assertEqual(plan["added"], [{"card_name": "Penance", "source_deck_id": 609}])
        self.assertEqual(plan["removed"], ["Promise of Loyalty"])

    def test_longshot_plan_is_one_card_ablation(self):
        plan = research.RESEARCH_PLANS["longshot_v1"]
        self.assertEqual(plan["added"], [{"card_name": "Longshot, Rebel Bowman", "source_deck_id": 615}])
        self.assertEqual(plan["removed"], ["Storm Herd"])

    def test_normalize_name(self):
        self.assertEqual(research.normalize_name("  Promise   of Loyalty "), "promise of loyalty")


if __name__ == "__main__":
    unittest.main()
