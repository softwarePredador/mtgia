#!/usr/bin/env python3
"""Tests for report-only battle-rule to functional-tag derivation."""

from __future__ import annotations

import unittest

import derive_functional_tags_from_battle_rules as derive


class DeriveFunctionalTagsFromBattleRulesTests(unittest.TestCase):
    def test_build_candidate_accepts_trusted_rule_and_maps_wipe_alias(self) -> None:
        candidate = derive.build_candidate(
            {
                "card_id": "card-1",
                "card_name": "Wrath Fixture",
                "effect_json": {"effect": "damage_wipe"},
                "deck_role_json": {"category": "wipe"},
                "source": "manual",
                "confidence": 0.9,
                "review_status": "verified",
                "rule_version": 2,
            },
            min_confidence=0.75,
        )

        self.assertEqual(candidate["tag"], "board_wipe")
        self.assertEqual(candidate["source"], derive.DERIVED_SOURCE)
        self.assertEqual(candidate["rejection_reason"], "")
        self.assertTrue(candidate["logical_rule_key"].startswith("battle_rule_v1:"))
        self.assertIn("logical_rule_key", candidate["evidence"])

    def test_build_candidate_rejects_untrusted_inputs(self) -> None:
        base = {
            "card_id": "card-1",
            "card_name": "Draw Fixture",
            "effect_json": {"effect": "draw_cards"},
            "deck_role_json": {"category": "draw"},
            "source": "manual",
            "confidence": 0.9,
            "review_status": "verified",
            "rule_version": 1,
        }

        cases = [
            ({**base, "card_id": None}, "missing_card_id"),
            ({**base, "review_status": "needs_review"}, "untrusted_review_status"),
            ({**base, "source": "generated"}, "untrusted_source"),
            ({**base, "confidence": 0.5}, "low_confidence"),
            (
                {
                    **base,
                    "effect_json": {"effect": "passive"},
                    "deck_role_json": {"category": "unknown"},
                },
                "non_derivable_tag",
            ),
        ]

        for row, expected_reason in cases:
            with self.subTest(expected_reason=expected_reason):
                candidate = derive.build_candidate(row, min_confidence=0.75)
                self.assertEqual(candidate["rejection_reason"], expected_reason)

    def test_report_classification_dedupes_candidates_and_existing_tags(self) -> None:
        rules = [
            {
                "card_id": "card-1",
                "card_name": "Draw Fixture",
                "effect_json": {"effect": "draw_cards", "amount": 1},
                "deck_role_json": {"category": "draw"},
                "source": "manual",
                "confidence": 0.9,
                "review_status": "verified",
                "rule_version": 1,
            },
            {
                "card_id": "card-1",
                "card_name": "Draw Fixture",
                "effect_json": {"effect": "draw_cards", "amount": 1},
                "deck_role_json": {"category": "draw"},
                "source": "manual",
                "confidence": 0.9,
                "review_status": "verified",
                "rule_version": 1,
            },
            {
                "card_id": "card-2",
                "card_name": "Ramp Fixture",
                "effect_json": {"effect": "ramp_permanent"},
                "deck_role_json": {"category": "ramp"},
                "source": "curated",
                "confidence": 0.8,
                "review_status": "active",
                "rule_version": 1,
            },
        ]
        existing = {("card-2", "ramp")}

        new_candidates = []
        already_present = []
        seen = set()
        for row in rules:
            candidate = derive.build_candidate(row, min_confidence=0.75)
            key = (
                str(candidate["card_id"]),
                str(candidate["tag"]),
                str(candidate["logical_rule_key"]),
            )
            if key in seen:
                continue
            seen.add(key)
            if (str(candidate["card_id"]), str(candidate["tag"])) in existing:
                already_present.append(candidate)
            else:
                new_candidates.append(candidate)

        self.assertEqual(len(new_candidates), 1)
        self.assertEqual(new_candidates[0]["tag"], "draw")
        self.assertEqual(len(already_present), 1)
        self.assertEqual(already_present[0]["tag"], "ramp")


if __name__ == "__main__":
    unittest.main()
