#!/usr/bin/env python3
"""Unit tests for the authoritative XMage adaptation queue."""

from __future__ import annotations

import unittest
from pathlib import Path

from xmage_authoritative_adaptation_queue import (
    DEFAULT_SCOPE,
    adapter_work_unit,
    compact_queue_row,
    translation_lane,
    unique_identity_cards,
)
from xmage_local_rule_indexer import ResolvedSource


def card(name: str, **overrides):
    payload = {
        "card_id": f"id-{name}",
        "name": name,
        "normalized_name": name.lower(),
        "oracle_id": f"oracle-{name.lower()}",
        "oracle_text_analysis": "Draw a card.",
        "family": "draw_selection_topdeck",
        "lanes": ["battle_family_mapper_required"],
        "commander_legality_status": "legal",
    }
    payload.update(overrides)
    return payload


def parsed(effect_json=None):
    if effect_json is None:
        effect_json = {
            "effect": "draw_cards",
            "battle_model_scope": "draw_fixed_cards_variant_v1",
        }
    return {
        "card_superclass": "CardImpl",
        "signals": ["draw"],
        "effect_classes": ["DrawCardSourceControllerEffect"],
        "ability_classes": ["SpellAbility"],
        "target_classes": ["TargetPlayer"],
        "condition_classes": [],
        "candidate_effect_hints": {
            "primary_candidate": {
                "status": "review_candidate",
                "confidence_reason": "XMage uses draw effect.",
                "effect_json": effect_json,
            }
        },
    }


class XMageAuthoritativeAdaptationQueueTest(unittest.TestCase):
    def test_unique_identity_cards_dedupes_reprints_by_oracle_id(self) -> None:
        rows = unique_identity_cards(
            [
                card("Alpha Draw", card_id="one", oracle_id="same"),
                card("Alpha Draw", card_id="two", oracle_id="same"),
                card("Other Draw", oracle_id="other"),
            ],
            DEFAULT_SCOPE,
        )
        self.assertEqual(len(rows), 2)
        self.assertEqual({row["oracle_id"] for row in rows}, {"same", "other"})

    def test_translation_lane_treats_resolved_xmage_as_authoritative_adapter_work(self) -> None:
        resolved = ResolvedSource("AlphaDraw", Path("/tmp/AlphaDraw.java"), "class_index_candidate")
        self.assertEqual(
            translation_lane(resolved=resolved, parsed_entry=parsed()),
            "xmage_authoritative_adapter_required",
        )

    def test_translation_lane_separates_parser_gap_from_missing_source(self) -> None:
        resolved = ResolvedSource("AlphaDraw", Path("/tmp/AlphaDraw.java"), "class_index_candidate")
        self.assertEqual(
            translation_lane(resolved=resolved, parsed_entry=parsed(effect_json={})),
            "xmage_authoritative_parser_gap",
        )
        self.assertEqual(
            translation_lane(resolved=None, parsed_entry=None),
            "xmage_missing_source_exception",
        )

    def test_compact_row_marks_xmage_source_as_authoritative_not_review_only(self) -> None:
        resolved = ResolvedSource("AlphaDraw", Path("/tmp/AlphaDraw.java"), "class_index_candidate")
        row = compact_queue_row(card("Alpha Draw"), resolved=resolved, parsed_entry=parsed())
        self.assertEqual(row["source_truth_status"], "xmage_authoritative")
        self.assertEqual(row["translation_lane"], "xmage_authoritative_adapter_required")
        self.assertTrue(row["logical_rule_key"].startswith("battle_rule_v1:"))

    def test_manual_model_hint_is_split_by_xmage_java_signature(self) -> None:
        unit = adapter_work_unit(
            {
                "effect": "external_reference_required_manual_model",
                "battle_model_scope": "xmage_reference_requires_manual_model_review_v1",
            },
            parsed(),
        )
        self.assertTrue(unit.startswith("xmage_signature::"))
        self.assertIn("DrawCardSourceControllerEffect", unit)
        self.assertNotEqual(
            unit,
            "external_reference_required_manual_model::xmage_reference_requires_manual_model_review_v1",
        )

    def test_card_specific_token_variants_are_grouped_by_xmage_signature(self) -> None:
        unit = adapter_work_unit(
            {
                "effect": "token_maker",
                "battle_model_scope": "xmage_create_token_variant_fixturecard_v1",
            },
            {
                "card_superclass": "CardImpl",
                "signals": ["token", "triggered_ability"],
                "effect_classes": ["CreateTokenEffect"],
                "ability_classes": ["EntersBattlefieldTriggeredAbility"],
                "target_classes": [],
                "condition_classes": [],
            },
        )

        self.assertEqual(
            unit,
            "token_maker::xmage_signature::CreateTokenEffect::EntersBattlefieldTriggeredAbility::no_target_class::no_condition_class::token,triggered_ability",
        )
        self.assertNotIn("fixturecard", unit)

    def test_specific_token_runtime_scope_stays_as_effect_scope_unit(self) -> None:
        unit = adapter_work_unit(
            {
                "effect": "token_maker",
                "battle_model_scope": "instant_sorcery_cast_create_1_1_red_elemental_v1",
            },
            parsed(),
        )

        self.assertEqual(
            unit,
            "token_maker::instant_sorcery_cast_create_1_1_red_elemental_v1",
        )


if __name__ == "__main__":
    unittest.main()
