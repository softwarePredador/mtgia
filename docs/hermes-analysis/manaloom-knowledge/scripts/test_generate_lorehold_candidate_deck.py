import unittest

import generate_lorehold_candidate_deck as generator


class GenerateLoreholdCandidateDeckTests(unittest.TestCase):
    def test_pending_or_off_color_rows_are_not_eligible(self):
        row = {
            "rule_status": "battle_ready",
            "recommendation_lane": "priority_benchmark_candidate",
            "promotion_lane": "mapper_metadata_or_test_scenario_required",
            "proposal_status": None,
        }
        oracle = {"color_identity_json": '["U"]'}

        reasons = generator.eligibility_reasons(row, oracle)

        self.assertIn(
            "pending_promotion_lane:mapper_metadata_or_test_scenario_required",
            reasons,
        )
        self.assertIn("color_identity_outside_lorehold:U", reasons)

    def test_role_metric_counts_keep_nonland_ramp_separate_from_lands(self):
        selected = [
            {"roles": {"land", "ramp"}, "is_land": True},
            {"roles": {"ramp", "draw"}, "is_land": False},
            {"roles": {"engine"}, "is_land": False},
        ]

        counts = generator.role_metric_counts(selected)

        self.assertEqual(counts["nonland_ramp"], 1)
        self.assertEqual(counts["draw"], 1)
        self.assertEqual(counts["engine"], 1)

    def test_candidate_hash_tracks_deck_identity(self):
        base = [
            {"card_name": "Lorehold, the Historian", "is_commander": True},
            {"card_name": "Plains // Plains", "is_commander": False},
        ]
        changed = [
            {"card_name": "Lorehold, the Historian", "is_commander": True},
            {"card_name": "Mountain // Mountain", "is_commander": False},
        ]

        self.assertNotEqual(
            generator.candidate_hash(base),
            generator.candidate_hash(changed),
        )


if __name__ == "__main__":
    unittest.main()
