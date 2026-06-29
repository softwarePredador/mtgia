import unittest

import lorehold_607_research_candidate as research


class Lorehold607ResearchCandidateTest(unittest.TestCase):
    def test_squee_plan_regenerates_current_champion_swap(self):
        plan = research.RESEARCH_PLANS["squee_v1"]
        self.assertEqual(plan["base_deck_id"], 607)
        self.assertEqual(plan["candidate_deck_id"], 6)
        self.assertEqual(plan["added"], [{"card_name": "Squee, Goblin Nabob", "source_deck_id": 609}])
        self.assertEqual(plan["removed"], ["Insurrection"])

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
        self.assertEqual(plan["removed"], ["Promise of Loyalty"])

    def test_guttersnipe_plan_is_spell_payoff_sidegrade(self):
        plan = research.RESEARCH_PLANS["guttersnipe_v1"]
        self.assertEqual(plan["added"], [{"card_name": "Guttersnipe", "source_deck_id": 615}])
        self.assertEqual(plan["removed"], ["Prismari Pianist"])

    def test_v615_mana_engine_plan_is_narrow_package_not_whole_deck_swap(self):
        plan = research.RESEARCH_PLANS["v615_mana_engine_v1"]
        self.assertEqual(plan["base_deck_id"], 607)
        self.assertEqual(plan["candidate_deck_id"], 6)
        self.assertEqual(plan["candidate_key"], "candidate_607_v615_mana_engine_v1")
        self.assertEqual(
            plan["added"],
            [
                {"card_name": "Mana Vault", "source_deck_id": 615},
                {"card_name": "Birgi, God of Storytelling // Harnfel, Horn of Bounty", "source_deck_id": 615},
                {"card_name": "The One Ring", "source_deck_id": 615},
            ],
        )
        self.assertEqual(plan["removed"], ["Bender's Waterskin", "The Scarlet Witch", "Molecule Man"])
        self.assertTrue(any("cross-lane" in signal for signal in plan["external_signals"]))
        self.assertFalse(any("cuts are narrow same-lane" in signal.lower() for signal in plan["external_signals"]))

    def test_v615_mana_engine_molecule_retest_reverts_only_one_ring_cut(self):
        plan = research.RESEARCH_PLANS["v615_mana_engine_molecule_retest_v1"]
        self.assertEqual(plan["candidate_key"], "candidate_607_v615_mana_engine_molecule_retest_v1")
        self.assertEqual(
            plan["added"],
            [
                {"card_name": "Mana Vault", "source_deck_id": 615},
                {"card_name": "Birgi, God of Storytelling // Harnfel, Horn of Bounty", "source_deck_id": 615},
            ],
        )
        self.assertEqual(plan["removed"], ["Bender's Waterskin", "The Scarlet Witch"])

    def test_v615_mana_engine_scarlet_retest_reverts_only_birgi_cut(self):
        plan = research.RESEARCH_PLANS["v615_mana_engine_scarlet_retest_v1"]
        self.assertEqual(plan["candidate_key"], "candidate_607_v615_mana_engine_scarlet_retest_v1")
        self.assertEqual(
            plan["added"],
            [
                {"card_name": "Mana Vault", "source_deck_id": 615},
                {"card_name": "The One Ring", "source_deck_id": 615},
            ],
        )
        self.assertEqual(plan["removed"], ["Bender's Waterskin", "Molecule Man"])

    def test_v615_mana_engine_molecule_scarlet_retest_reverts_both_disputed_cuts(self):
        plan = research.RESEARCH_PLANS["v615_mana_engine_molecule_scarlet_retest_v1"]
        self.assertEqual(
            plan["candidate_key"],
            "candidate_607_v615_mana_engine_molecule_scarlet_retest_v1",
        )
        self.assertEqual(plan["added"], [{"card_name": "Mana Vault", "source_deck_id": 615}])
        self.assertEqual(plan["removed"], ["Bender's Waterskin"])

    def test_render_markdown_includes_final_decklist_sections(self):
        report = {
            "plan": "test",
            "generated_at": "now",
            "source_db": "source.db",
            "candidate_db": "candidate.db",
            "candidate_hash": "abc",
            "strategy_version": "test",
            "commander_intent_alignment": {"score": 100},
            "intent": "intent",
            "external_signals": [],
            "added": [{"card_name": "Mana Vault"}],
            "removed": ["Bender's Waterskin"],
            "row_count": 3,
            "quantity_total": 3,
            "lands": 1,
            "nonlands": 1,
            "strategy_package_counts": {},
            "final_deck": [
                {"card_name": "Lorehold, the Historian", "quantity": 1, "is_commander": True, "is_land": False},
                {"card_name": "Mana Vault", "quantity": 1, "is_commander": False, "is_land": False},
                {"card_name": "Command Tower", "quantity": 1, "is_commander": False, "is_land": True},
            ],
        }

        markdown = research.render_markdown(report)

        self.assertIn("## Final Decklist", markdown)
        self.assertIn("### Commander", markdown)
        self.assertIn("1 Lorehold, the Historian", markdown)
        self.assertIn("### Nonlands", markdown)
        self.assertIn("1 Mana Vault", markdown)
        self.assertIn("### Lands", markdown)
        self.assertIn("1 Command Tower", markdown)

    def test_display_card_name_collapses_duplicate_split_faces_only(self):
        self.assertEqual(research.display_card_name("Mountain // Mountain"), "Mountain")
        self.assertEqual(
            research.display_card_name("Emeria's Call // Emeria, Shattered Skyclave"),
            "Emeria's Call // Emeria, Shattered Skyclave",
        )

    def test_render_decklist_text_is_importable_line_format(self):
        report = {
            "final_deck": [
                {"card_name": "Lorehold, the Historian", "quantity": 1, "is_commander": True, "is_land": False},
                {"card_name": "Mana Vault", "quantity": 1, "is_commander": False, "is_land": False},
                {"card_name": "Mountain // Mountain", "quantity": 4, "is_commander": False, "is_land": True},
            ]
        }

        decklist = research.render_decklist_text(report)

        self.assertEqual(decklist, "1 Lorehold, the Historian\n1 Mana Vault\n4 Mountain\n")

    def test_normalize_name(self):
        self.assertEqual(research.normalize_name("  Promise   of Loyalty "), "promise of loyalty")


if __name__ == "__main__":
    unittest.main()
