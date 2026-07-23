#!/usr/bin/env python3
"""Unit tests for the authoritative XMage adaptation queue."""

from __future__ import annotations

import unittest
from pathlib import Path

from xmage_authoritative_adaptation_queue import (
    DEFAULT_SCOPE,
    adapter_work_unit,
    compact_queue_row,
    operational_coverage_lane,
    prioritize_queue_rows,
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
        "ready_product_deck_count": 0,
        "deck_count": 0,
        "total_quantity": 0,
        "commander_slot_count": 0,
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

    def test_translation_lane_retains_historical_native_analysis_shape(self) -> None:
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

    def test_compact_row_requires_runtime_catalog_confirmation(self) -> None:
        resolved = ResolvedSource("AlphaDraw", Path("/tmp/AlphaDraw.java"), "class_index_candidate")
        row = compact_queue_row(card("Alpha Draw"), resolved=resolved, parsed_entry=parsed())
        self.assertEqual(row["source_truth_status"], "xmage_local_source_candidate")
        self.assertEqual(row["source_resolution_status"], "local_source_candidate")
        self.assertTrue(row["runtime_catalog_confirmation_required"])
        self.assertEqual(row["runtime_coverage_status"], "unconfirmed")
        self.assertEqual(
            row["operational_coverage_lane"],
            "pinned_xmage_catalog_confirmation_required",
        )
        self.assertFalse(row["native_adapter_required"])
        self.assertEqual(row["translation_lane"], "xmage_authoritative_adapter_required")
        self.assertTrue(row["logical_rule_key"].startswith("battle_rule_v1:"))

    def test_operational_lane_routes_only_external_residual_to_native_review(self) -> None:
        resolved = ResolvedSource("AlphaDraw", Path("/tmp/AlphaDraw.java"), "class_index_candidate")
        self.assertEqual(
            operational_coverage_lane(resolved=resolved),
            "pinned_xmage_catalog_confirmation_required",
        )
        self.assertEqual(
            operational_coverage_lane(resolved=None),
            "forge_then_native_residual_review",
        )

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

    def test_priority_combines_product_usage_impact_and_residual(self) -> None:
        resolved = ResolvedSource("AlphaDraw", Path("/tmp/AlphaDraw.java"), "class_index_candidate")
        row = compact_queue_row(
            card(
                "Alpha Draw",
                ready_product_deck_count=2,
                deck_count=7,
                total_quantity=8,
                commander_slot_count=1,
            ),
            resolved=resolved,
            parsed_entry=parsed(),
        )

        prioritized = prioritize_queue_rows(
            [row],
            battle_usage_by_name={"alpha draw": 2},
        )[0]

        self.assertEqual(prioritized["priority_band"], "P0")
        self.assertGreater(prioritized["priority_score"], 0)
        self.assertTrue(
            all(
                prioritized["priority_components"][component]["score"] > 0
                for component in ("product", "real_usage", "impact", "residual")
            )
        )
        self.assertEqual(prioritized["owner"], "external_engine_coverage")
        self.assertEqual(
            prioritized["next_gate"],
            "confirm_exact_pinned_xmage_catalog_then_count_external_coverage",
        )

    def test_registered_decks_do_not_fake_real_usage_or_mutate_owner_intent(self) -> None:
        row = compact_queue_row(
            card("Alpha Draw", deck_count=99, total_quantity=120),
            resolved=None,
            parsed_entry=None,
        )

        prioritized = prioritize_queue_rows([row])[0]

        self.assertEqual(
            prioritized["priority_components"]["real_usage"][
                "typed_natural_positive_battle_count"
            ],
            0,
        )
        self.assertEqual(prioritized["priority_components"]["real_usage"]["score"], 0)
        self.assertEqual(prioritized["registered_deck_count"], 99)
        self.assertEqual(
            prioritized["owner_intent_policy"],
            {
                "preserve_user_skeleton": True,
                "allow_auto_fill": False,
                "allow_auto_delete": False,
                "allow_deck_mutation": False,
            },
        )
        self.assertFalse(prioritized["promotion_allowed"])
        self.assertTrue(prioritized["postgresql_is_product_truth"])

    def test_each_operational_lane_has_explicit_owner_and_next_gate(self) -> None:
        rows = [
            {
                "card_id": lane,
                "card_name": lane,
                "normalized_name": lane,
                "adapter_work_unit": lane,
                "translation_lane": "xmage_authoritative_adapter_required",
                "operational_coverage_lane": lane,
            }
            for lane in (
                "pinned_xmage_catalog_confirmation_required",
                "forge_then_native_residual_review",
            )
        ]

        prioritized = prioritize_queue_rows(rows)

        self.assertEqual(len(prioritized), 2)
        self.assertTrue(all(row["owner"] for row in prioritized))
        self.assertTrue(all(row["next_gate"] for row in prioritized))
        self.assertEqual(len({row["owner"] for row in prioritized}), 2)


if __name__ == "__main__":
    unittest.main()
