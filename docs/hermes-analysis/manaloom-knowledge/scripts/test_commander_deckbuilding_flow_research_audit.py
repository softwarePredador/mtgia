import unittest

import commander_deckbuilding_flow_research_audit as audit


class CommanderDeckbuildingFlowResearchAuditTest(unittest.TestCase):
    def test_flow_research_audit_passes_current_contract_and_backend_surface(self):
        payload = audit.build_report()

        self.assertEqual(payload["status"], "pass")
        self.assertIn("primary_and_backup_win_plan", payload["required_flow"])
        self.assertIn("lane_balanced_cuts_and_anchor_protection", payload["required_flow"])
        self.assertIn("protected_anchors_and_cut_rules", payload["required_overview_fields"])
        self.assertFalse(payload["failures"])

    def test_research_sources_cover_rules_templates_ramp_and_combos(self):
        payload = audit.build_report()
        names = {source["source"] for source in payload["research_sources"]}

        self.assertIn("Wizards Commander format page", names)
        self.assertIn("EDHREC How to Build a Commander Deck", names)
        self.assertIn("The Command Zone template via EDHREC", names)
        self.assertIn("EDHREC Ramp in Commander", names)
        self.assertIn("Commander Spellbook", names)


if __name__ == "__main__":
    unittest.main()
