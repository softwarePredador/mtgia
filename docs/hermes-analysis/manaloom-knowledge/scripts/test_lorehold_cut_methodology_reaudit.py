import unittest

import lorehold_cut_methodology_reaudit as audit


def build_payload():
    return audit.build_report()


def pair_by_key(payload):
    return {row["pair_key"]: row for row in payload["pairs"]}


class LoreholdCutMethodologyReauditTest(unittest.TestCase):
    def test_one_ring_over_molecule_is_blocked_cross_lane_cut(self):
        payload = build_payload()
        pairs = pair_by_key(payload)
        row = pairs["the_one_ring_over_molecule_man"]

        self.assertEqual(row["lane_gate"]["status"], "blocked_cross_lane_cut")
        self.assertEqual(row["classification"]["decision"], "do_not_use_this_cut_as_deck-quality_proof")
        self.assertTrue(
            any("direct miracle-zero engine" in reason for reason in row["cut_profile"]["protected_reasons"])
        )
        self.assertIn("the_one_ring_over_molecule_man", payload["decision"]["blocked_pairs"])
        self.assertIs(payload["decision"]["ready_for_real_deck_change"], False)

    def test_mana_vault_over_bender_is_same_lane_with_external_caveat(self):
        payload = build_payload()
        pairs = pair_by_key(payload)
        row = pairs["mana_vault_over_benders_waterskin"]

        self.assertEqual(row["lane_gate"]["status"], "strict_same_lane")
        self.assertEqual(row["classification"]["status"], "valid_same_lane_with_external_caveat")
        self.assertGreater(row["external_evidence"]["cut_synergy_pct"], row["external_evidence"]["add_synergy_pct"])
        self.assertGreaterEqual(row["battle_evidence"]["promoted_candidate_add"]["spell_cast"], 1)

    def test_birgi_over_scarlet_is_same_macro_confirmation_required(self):
        payload = build_payload()
        pairs = pair_by_key(payload)
        row = pairs["birgi_god_of_storytelling_harnfel_horn_of_bounty_over_the_scarlet_witch"]

        self.assertEqual(row["lane_gate"]["status"], "same_macro_lane_needs_confirmation")
        self.assertEqual(row["classification"]["status"], "confirmation_required")
        self.assertIn(
            "birgi_god_of_storytelling_harnfel_horn_of_bounty_over_the_scarlet_witch",
            payload["decision"]["confirmation_pairs"],
        )
        self.assertGreaterEqual(row["battle_evidence"]["paired_restore_cut_card"]["spell_cast"], 1)

    def test_external_snapshot_records_lorehold_specific_evidence(self):
        payload = build_payload()
        cards = payload["external_stats_snapshot"]["cards"]

        self.assertGreater(cards["Molecule Man"]["synergy_pct"], cards["The One Ring"]["synergy_pct"])
        self.assertGreater(cards["Bender's Waterskin"]["inclusion_pct"], cards["Mana Vault"]["inclusion_pct"])
        self.assertGreaterEqual(
            cards["The Scarlet Witch"]["synergy_pct"],
            cards["Birgi, God of Storytelling // Harnfel, Horn of Bounty"]["synergy_pct"],
        )


if __name__ == "__main__":
    unittest.main()
