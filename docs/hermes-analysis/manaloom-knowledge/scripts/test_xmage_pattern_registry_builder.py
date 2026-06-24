#!/usr/bin/env python3
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import xmage_pattern_registry_builder as registry


def proposal(
    card_name: str,
    status: str,
    family: str,
    effect: str,
    scope: str,
    *,
    ability_kind: str = "one_shot",
    target_constraints: dict[str, object] | None = None,
) -> dict[str, object]:
    return {
        "card_name": card_name,
        "normalized_name": card_name.lower(),
        "proposal_status": status,
        "family_id": family,
        "effect": effect,
        "battle_model_scope": scope,
        "effect_json": {
            "effect": effect,
            "battle_model_scope": scope,
            "ability_kind": ability_kind,
            **({"target_constraints": target_constraints} if target_constraints else {}),
        },
        "xmage_class": card_name.replace(" ", ""),
    }


class XMagePatternRegistryBuilderTests(unittest.TestCase):
    def test_prepared_package_pattern_is_governance_only_and_shadow(self) -> None:
        proposal_report = {
            "proposals": [
                proposal(
                    "Packaged Card",
                    "batch_pg_candidate_after_precheck",
                    "draw_engine",
                    "draw_cards",
                    "source_controller_draw_variant_v1",
                )
            ]
        }
        with tempfile.TemporaryDirectory() as tmp_dir:
            report_dir = Path(tmp_dir)
            (report_dir / "pg999_manifest.json").write_text(
                json.dumps(
                    {
                        "deploy_id": "PG999",
                        "slug": "prepared_card",
                        "status": "prepared_read_only_pending_apply_approval",
                        "selected_card_names": ["Packaged Card"],
                    }
                ),
                encoding="utf-8",
            )
            report = registry.build_report(proposal_report=proposal_report, report_dir=report_dir)

        self.assertEqual(report["summary"]["executable_pattern_count"], 0)
        self.assertEqual(report["summary"]["auto_promotable_pattern_count"], 0)
        pattern = report["patterns"][0]
        self.assertEqual(pattern["pattern_status"], "governance_only_pending_pg_apply")
        self.assertEqual(pattern["promotion_status"], "shadow_only")
        self.assertFalse(pattern["can_execute_in_battle"])
        self.assertFalse(pattern["can_auto_promote_to_card_battle_rules"])
        self.assertEqual(pattern["package_refs"][0]["deploy_id"], "PG999")

    def test_split_scope_with_distinct_subpatterns_requires_split_before_promotion(self) -> None:
        proposal_report = {
            "proposals": [
                proposal(
                    "Damage Spell",
                    "split_family_scope_review_required",
                    "targeted_interaction",
                    "direct_damage",
                    "targeted_damage_variant_v1",
                    ability_kind="one_shot",
                    target_constraints={"scope": "any_target"},
                ),
                proposal(
                    "Damage Trigger",
                    "split_family_scope_review_required",
                    "targeted_interaction",
                    "direct_damage",
                    "targeted_damage_variant_v1",
                    ability_kind="triggered",
                    target_constraints={"controller_scope": "opponent"},
                ),
            ]
        }
        with tempfile.TemporaryDirectory() as tmp_dir:
            report = registry.build_report(proposal_report=proposal_report, report_dir=Path(tmp_dir))

        pattern = report["patterns"][0]
        self.assertEqual(pattern["pattern_status"], "requires_subpattern_split_before_promotion")
        self.assertEqual(pattern["subpattern_count"], 2)
        self.assertEqual(pattern["card_count"], 2)
        self.assertIn("subpattern split", pattern["required_evidence_before_promotion"])

    def test_fragmented_single_token_runtime_is_observation_only(self) -> None:
        proposal_report = {
            "proposals": [
                proposal(
                    "Token One",
                    "runtime_family_implementation_required",
                    "token_maker",
                    "token_maker",
                    "xmage_create_token_variant_tokenone_v1",
                    ability_kind="triggered",
                )
            ]
        }
        with tempfile.TemporaryDirectory() as tmp_dir:
            report = registry.build_report(proposal_report=proposal_report, report_dir=Path(tmp_dir))

        pattern = report["patterns"][0]
        self.assertEqual(pattern["pattern_status"], "fragmented_runtime_observation_only")
        self.assertEqual(pattern["recommended_action"], "Keep as registry evidence; wait for taxonomy/test-miner support before executor work.")

    def test_schema_proposal_keeps_shadow_rows_non_executable(self) -> None:
        sql = registry.schema_proposal_sql()
        self.assertIn("xmage_pattern_registry", sql)
        self.assertIn("promotion_status <> 'shadow_only'", sql)
        self.assertIn("can_execute_in_battle = FALSE", sql)
        self.assertIn("can_auto_promote_to_card_battle_rules = FALSE", sql)


if __name__ == "__main__":
    unittest.main()
