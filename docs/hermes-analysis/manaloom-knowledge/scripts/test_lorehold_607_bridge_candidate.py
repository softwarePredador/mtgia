import unittest

import lorehold_607_bridge_candidate as bridge


class Lorehold607BridgeCandidateTest(unittest.TestCase):
    def test_swap_plan_is_balanced_and_targets_known_gaps(self):
        self.assertEqual(len(bridge.ADD_FROM_V7), len(bridge.REMOVE_FROM_607))
        self.assertIn("Past in Flames", bridge.ADD_FROM_V7)
        self.assertIn("Gamble", bridge.ADD_FROM_V7)
        self.assertIn("Enlightened Tutor", bridge.ADD_FROM_V7)

    def test_v2_plan_is_minimal_two_card_bridge(self):
        plan = bridge.BRIDGE_PLANS["v2"]
        self.assertEqual(plan["added_from_v7"], ["Aetherflux Reservoir", "Storm-Kiln Artist"])
        self.assertEqual(plan["removed_from_607"], ["Molecule Man", "The Scarlet Witch"])

    def test_normalize_name(self):
        self.assertEqual(bridge.normalize_name("  Aetherflux   Reservoir "), "aetherflux reservoir")


if __name__ == "__main__":
    unittest.main()
