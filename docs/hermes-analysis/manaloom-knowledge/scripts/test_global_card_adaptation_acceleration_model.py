#!/usr/bin/env python3
"""Unit tests for all-card adaptation acceleration modeling."""

from __future__ import annotations

import unittest

import global_card_adaptation_acceleration_model as model


def card(name: str, family: str, oracle_text: str, **overrides):
    payload = {
        "name": name,
        "normalized_name": name.lower(),
        "oracle_id": name.lower().replace(" ", "-"),
        "oracle_text_analysis": oracle_text,
        "family": family,
        "lanes": ["battle_family_mapper_required"],
        "commander_legality_status": "legal",
        "deck_count": 0,
        "ready_product_deck_count": 0,
    }
    payload.update(overrides)
    return payload


class GlobalCardAdaptationAccelerationModelTest(unittest.TestCase):
    def test_template_for_card_matches_common_patterns(self) -> None:
        self.assertEqual(
            model.template_for_card(card("Cancel", "counterspell_or_stack_interaction", "Counter target spell."))["template"],
            "counter_target_spell",
        )
        self.assertEqual(
            model.template_for_card(card("Shock", "damage_or_life_total_change", "Shock deals 2 damage to any target."))["template"],
            "direct_damage_fixed_amount",
        )
        self.assertEqual(
            model.template_for_card(card("Raise Alarm", "token_creation", "Create two 1/1 white Soldier creature tokens."))["template"],
            "create_fixed_tokens",
        )

    def test_work_unit_comparison_compresses_rows_to_templates(self) -> None:
        cards = [
            card("Cancel", "counterspell_or_stack_interaction", "Counter target spell.", deck_count=1),
            card("Shock", "damage_or_life_total_change", "Shock deals 2 damage to any target.", deck_count=1),
            card("Complex A", "manual_model_review", "A complex bespoke effect.", deck_count=1),
            card("Complex B", "manual_model_review", "Another complex bespoke effect.", deck_count=0),
        ]
        summary = model.summarize(cards)
        self.assertEqual(summary["battle_gap"]["row_count"], 4)
        self.assertEqual(summary["battle_gap"]["used_deck_unique_names"], 3)
        self.assertEqual(summary["template_first"]["template_count"], 2)
        self.assertEqual(summary["template_first"]["matched_used_deck_unique_names"], 2)
        self.assertLess(
            summary["work_unit_comparison"]["template_plus_residual_family_units"],
            summary["work_unit_comparison"]["card_row_units_if_done_one_by_one"],
        )


if __name__ == "__main__":
    unittest.main()
