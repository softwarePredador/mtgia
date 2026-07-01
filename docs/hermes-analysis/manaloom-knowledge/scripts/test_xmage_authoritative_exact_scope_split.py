#!/usr/bin/env python3
"""Tests for authoritative XMage exact-scope splitting."""

from __future__ import annotations

import unittest

import xmage_authoritative_exact_scope_split as split


def queue_row(unit: str, *, effect_classes: list[str], card_id: str = "card-1", ability_kind: str = "one_shot"):
    return {
        "card_id": card_id,
        "card_name": "Fixture Spell",
        "normalized_name": "fixture spell",
        "translation_lane": "xmage_authoritative_adapter_required",
        "adapter_work_unit": unit,
        "effect_json": {"ability_kind": ability_kind},
        "xmage_effect_classes": effect_classes,
        "xmage_class": "FixtureSpell",
        "xmage_path": "/tmp/FixtureSpell.java",
    }


def metadata(name: str = "Fixture Spell", *, type_line: str = "Instant", oracle_text: str = "Draw two cards."):
    return {
        "card_id": "card-1",
        "name": name,
        "type_line": type_line,
        "oracle_text": oracle_text,
        "oracle_hash": split.md5_text(oracle_text),
    }


class XMageAuthoritativeExactScopeSplitTest(unittest.TestCase):
    def test_fixed_source_controller_draw_spell_is_package_safe(self) -> None:
        row = queue_row(split.DRAW_UNIT, effect_classes=["DrawCardSourceControllerEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Draw two cards."),
            source_text="this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(2));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertIsNotNone(proposal)
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "draw_cards")
        self.assertEqual(effect["battle_model_scope"], split.DRAW_SCOPE)
        self.assertEqual(effect["count"], 2)
        self.assertTrue(proposal["safe_for_batch_pg_package"])

    def test_fixed_damage_spell_requires_numeric_damage_and_supported_target(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Fixture Spell deals 3 damage to any target."),
            source_text="this.getSpellAbility().addEffect(new DamageTargetEffect(3));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "direct_damage")
        self.assertEqual(effect["battle_model_scope"], split.DAMAGE_SCOPE)
        self.assertEqual(effect["amount"], 3)
        self.assertEqual(effect["target"], "any_target")

    def test_damage_spell_with_variable_x_stays_blocked(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Fixture Spell deals X damage to any target."),
            source_text="this.getSpellAbility().addEffect(new DamageTargetEffect(ManacostVariableValue.instance));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "damage_amount_not_fixed")

    def test_destroy_target_creature_maps_to_remove_creature_runtime(self) -> None:
        row = queue_row(split.DESTROY_UNIT, effect_classes=["DestroyTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy target creature."),
            source_text="this.getSpellAbility().addEffect(new DestroyTargetEffect());",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "remove_creature")
        self.assertEqual(effect["battle_model_scope"], split.DESTROY_SCOPE)
        self.assertEqual(effect["target"], "creature")

    def test_additional_cost_blocks_first_wave_package_candidate(self) -> None:
        row = queue_row(split.DESTROY_UNIT, effect_classes=["DestroyTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="As an additional cost to cast this spell, sacrifice a creature. Destroy target creature."),
            source_text=(
                "this.getSpellAbility().addCost(new SacrificeTargetCost());"
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "additional_cost_detected")

    def test_report_summarizes_selected_and_blocked_rows(self) -> None:
        rows = [
            queue_row(split.DRAW_UNIT, effect_classes=["DrawCardSourceControllerEffect"], card_id="draw"),
            queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"], card_id="variable"),
        ]
        report = split.build_exact_split_report(
            {"queue": rows, "generated_at": "fixture", "status": "ready", "method": {"scope": "test"}},
            card_metadata_by_id={
                "draw": metadata("Draw Fixture", oracle_text="Draw a card."),
                "variable": metadata("Variable Fixture", oracle_text="Variable Fixture deals X damage to any target."),
            },
            source_reader=lambda row: (
                "new DrawCardSourceControllerEffect(1)"
                if row["card_id"] == "draw"
                else "new DamageTargetEffect(ManacostVariableValue.instance)"
            ),
        )

        self.assertEqual(report["summary"]["proposal_count"], 1)
        self.assertEqual(report["summary"]["blocked_reason_counts"], {"damage_amount_not_fixed": 1})


if __name__ == "__main__":
    unittest.main()
