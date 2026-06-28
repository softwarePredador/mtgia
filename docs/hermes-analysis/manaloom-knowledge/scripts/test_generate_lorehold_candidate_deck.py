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

    def test_effective_score_preserves_active_pressure_absorber(self):
        active_names = {"crawlspace"}
        crawlspace = {
            "card_name": "Crawlspace",
            "score": 46.0,
            "recommendation_lane": "core_keep",
            "deck_ids": [6, 610],
            "roles": ["protection", "stax"],
        }
        generic_protection = {
            "card_name": "Hexing Squelcher",
            "score": 56.0,
            "recommendation_lane": "priority_benchmark_candidate",
            "deck_ids": [606, 607, 609, 613, 614, 615, 616],
            "roles": ["protection"],
        }
        crawlspace_oracle = {
            "cmc": 3,
            "type_line": "Artifact",
            "oracle_text": "No more than two creatures can attack you each combat.",
        }
        generic_oracle = {
            "cmc": 2,
            "type_line": "Creature",
            "oracle_text": "When this enters, counter target activated or triggered ability.",
        }

        crawlspace_score = generator.effective_score(
            crawlspace,
            crawlspace_oracle,
            active_names=active_names,
        )
        generic_score = generator.effective_score(
            generic_protection,
            generic_oracle,
            active_names=active_names,
        )

        self.assertGreater(crawlspace_score, generic_score)

    def test_active_core_keep_nonland_is_forced(self):
        self.assertTrue(
            generator.force_keep_active_core(
                {
                    "card_name": "Orim's Chant",
                    "in_active_deck": True,
                    "is_land": False,
                    "recommendation_lane": "core_keep",
                }
            )
        )
        self.assertFalse(
            generator.force_keep_active_core(
                {
                    "card_name": "Ancient Den",
                    "in_active_deck": True,
                    "is_land": True,
                    "recommendation_lane": "core_keep",
                }
            )
        )


if __name__ == "__main__":
    unittest.main()
