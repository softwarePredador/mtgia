#!/usr/bin/env python3
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import xmage_batch_pg_package_builder as package_builder
import xmage_effect_json_batch_generator as generator
import xmage_semantic_family_classifier as classifier


def sample_batch_audit() -> dict:
    return {
        "generated_at": "2026-06-23T00:00:00+00:00",
        "status": "ready",
        "source": {"deck_id": 607},
        "summary": {},
        "cards": [
            {
                "card_name": "Pearl Medallion",
                "severity": "high",
                "oracle_hash": "77f7f449ee56143d6b63814fecd37176",
                "status": "ready_for_structured_xmage_pull_review_required",
                "ready_for_structured_pull": True,
                "valid_xmage_source": True,
                "coherence_findings": ["review_only_or_needs_review_rule"],
                "checks": {"focused_test_scenario_count": 2},
                "xmage": {
                    "class_name": "PearlMedallion",
                    "path": "/xmage/PearlMedallion.java",
                    "types": ["ARTIFACT"],
                    "primary_effect": {
                        "effect": "static_cost_reduction",
                        "battle_model_scope": "static_cost_reduction_for_matching_spells_v1",
                        "ability_kind": "static",
                        "cost_reduction_applies_to": "spells_you_cast",
                        "applies_to_spell_colors": ["W"],
                        "cost_reduction_generic": 1,
                    },
                },
            },
            {
                "card_name": "Promise of Loyalty",
                "severity": "high",
                "oracle_hash": "11f7f449ee56143d6b63814fecd37176",
                "status": "ready_for_structured_xmage_pull_review_required",
                "ready_for_structured_pull": True,
                "valid_xmage_source": True,
                "coherence_findings": ["review_only_or_needs_review_rule"],
                "checks": {"focused_test_scenario_count": 3},
                "xmage": {
                    "class_name": "PromiseOfLoyalty",
                    "path": "/xmage/PromiseOfLoyalty.java",
                    "types": ["SORCERY"],
                    "primary_effect": {
                        "effect": "vow_counter_each_player_sacrifice_rest",
                        "battle_model_scope": "each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1",
                        "ability_kind": "one_shot",
                    },
                },
            },
            {
                "card_name": "Molecule Man",
                "severity": "high",
                "oracle_hash": None,
                "status": "blocked_missing_xmage_class",
                "ready_for_structured_pull": False,
                "valid_xmage_source": False,
                "coherence_findings": ["no_active_battle_rule"],
                "checks": {},
                "xmage": {"status": "not_found"},
            },
        ],
    }


def sample_external_harvest() -> dict:
    return {
        "status": "ready_for_manual_review",
        "cards": [
            {
                "card_name": "Pearl Medallion",
                "candidate_rule": {
                    "oracle_hash": "77f7f449ee56143d6b63814fecd37176",
                    "effect_json": {
                        "effect": "static_cost_reduction",
                        "applies_to_spell_colors": ["W"],
                    },
                },
                "external_references": {"scryfall": {"mana_cost": "{2}"}},
            },
            {
                "card_name": "Promise of Loyalty",
                "candidate_rule": {"oracle_hash": "11f7f449ee56143d6b63814fecd37176"},
            },
        ],
    }


class XMageSemanticFamilyBatchPipelineTests(unittest.TestCase):
    def test_classifier_groups_cards_by_family_and_lane(self) -> None:
        report = classifier.build_family_report(sample_batch_audit())

        self.assertEqual(report["summary"]["card_count"], 3)
        self.assertEqual(report["summary"]["family_counts"]["static_cost_reducer"], 1)
        self.assertEqual(report["summary"]["family_counts"]["board_wipe_choice"], 1)
        self.assertEqual(report["summary"]["family_counts"]["manual_model"], 1)
        self.assertEqual(report["summary"]["batch_metadata_candidate_count"], 1)
        self.assertEqual(report["summary"]["runtime_family_required_count"], 1)

    def test_generator_marks_only_supported_oracle_hashed_family_as_batch_safe(self) -> None:
        report = generator.build_generator_report(
            batch_audit=sample_batch_audit(),
            external_harvest=sample_external_harvest(),
        )

        by_name = {proposal["card_name"]: proposal for proposal in report["proposals"]}

        self.assertTrue(by_name["Pearl Medallion"]["safe_for_batch_pg_package"])
        self.assertEqual(by_name["Pearl Medallion"]["review_status"], "verified")
        self.assertEqual(by_name["Pearl Medallion"]["effect_json"]["applies_to_spell_colors"], ["W"])
        self.assertEqual(by_name["Pearl Medallion"]["effect_json"]["cmc"], 2.0)
        self.assertEqual(by_name["Promise of Loyalty"]["proposal_status"], "runtime_family_implementation_required")
        self.assertFalse(by_name["Molecule Man"]["safe_for_batch_pg_package"])

    def test_classifier_marks_activated_ability_cost_reducer_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Training Grounds",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "TrainingGrounds",
                            "path": "/xmage/TrainingGrounds.java",
                            "primary_effect": {
                                "effect": "static_cost_reduction",
                                "battle_model_scope": "static_activated_ability_cost_reduction_variant_v1",
                                "cost_reduction_applies_to": "activated_abilities_of_creatures_you_control",
                                "cost_reduction_generic": 2,
                                "cost_reduction_minimum_total_mana": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_keeps_variable_self_spell_cost_reducer_out_of_batch_lane(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Dargo, the Shipwrecker",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "DargoTheShipwrecker",
                            "path": "/xmage/DargoTheShipwrecker.java",
                            "primary_effect": {
                                "effect": "static_cost_reduction",
                                "battle_model_scope": "static_variable_self_spell_cost_reduction_variant_v1",
                                "cost_reduction_applies_to": "this_spell",
                                "cost_reduction_amount_source": "sacrificed_artifact_or_creature_count_this_turn",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "split_family_scope_review_required")

    def test_package_builder_writes_review_only_sql_package_for_safe_proposals(self) -> None:
        proposal_report = generator.build_generator_report(
            batch_audit=sample_batch_audit(),
            external_harvest=sample_external_harvest(),
        )

        with tempfile.TemporaryDirectory() as tmp_dir:
            output_prefix = Path(tmp_dir) / "pg999_static_cost_reducer_batch"
            manifest = package_builder.build_package(
                proposal_report,
                deploy_id="PG999",
                slug="static_cost_reducer_batch",
                output_prefix=output_prefix,
                include_family={"static_cost_reducer"},
                include_card=set(),
                exclude_card=set(),
                max_cards=None,
            )

            self.assertEqual(manifest["selected_count"], 1)
            self.assertEqual(manifest["selected_card_names"], ["Pearl Medallion"])
            self.assertEqual(manifest["mutations_performed"], [])
            apply_sql = Path(manifest["files"]["apply"]).read_text(encoding="utf-8")
            self.assertIn("BEGIN;", apply_sql)
            self.assertIn("Pearl Medallion", apply_sql)
            self.assertIn("RAISE EXCEPTION", apply_sql)
            self.assertIn("target_card_rows < 1", apply_sql)
            self.assertIn("canonical_target_cards", apply_sql)

    def test_package_builder_reuses_existing_backup_table_from_manifest(self) -> None:
        proposal_report = generator.build_generator_report(
            batch_audit=sample_batch_audit(),
            external_harvest=sample_external_harvest(),
        )

        with tempfile.TemporaryDirectory() as tmp_dir:
            output_prefix = Path(tmp_dir) / "pg999_static_cost_reducer_batch"
            manifest_path = Path(f"{output_prefix}_manifest.json")
            manifest_path.write_text(
                json.dumps(
                    {
                        "backup_table": "manaloom_deploy_audit.pg999_existing_backup_table",
                    }
                ),
                encoding="utf-8",
            )

            manifest = package_builder.build_package(
                proposal_report,
                deploy_id="PG999",
                slug="static_cost_reducer_batch",
                output_prefix=output_prefix,
                include_family={"static_cost_reducer"},
                include_card=set(),
                exclude_card=set(),
                max_cards=None,
            )

            self.assertEqual(
                manifest["backup_table"],
                "manaloom_deploy_audit.pg999_existing_backup_table",
            )
            rollback_sql = Path(manifest["files"]["rollback"]).read_text(encoding="utf-8")
            postcheck_sql = Path(manifest["files"]["postcheck"]).read_text(encoding="utf-8")
            self.assertIn("pg999_existing_backup_table", rollback_sql)
            self.assertIn("pg999_existing_backup_table", postcheck_sql)

    def test_classifier_marks_spell_scope_runtime_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Counterspell",
                        "severity": "high",
                        "oracle_hash": "abc",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "Counterspell",
                            "path": "/xmage/Counterspell.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["CounterTargetEffect"],
                            "ability_classes": [],
                            "primary_effect": {
                                "effect": "counter_spell",
                                "battle_model_scope": "counter_target_stack_object_variant_v1",
                                "ability_kind": "one_shot",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_generator_uses_local_oracle_hash_when_external_harvest_is_missing(self) -> None:
        report = generator.build_generator_report(
            batch_audit={
                "cards": [
                    {
                        "card_name": "Counterspell",
                        "normalized_name": "counterspell",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "oracle_hash": "localhash123",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "Counterspell",
                            "path": "/xmage/Counterspell.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["CounterTargetEffect"],
                            "ability_classes": [],
                            "primary_effect": {
                                "effect": "counter_spell",
                                "battle_model_scope": "counter_target_stack_object_variant_v1",
                                "ability_kind": "one_shot",
                            },
                        },
                    }
                ]
            },
            external_harvest=None,
        )

        proposal = report["proposals"][0]
        self.assertEqual(proposal["oracle_hash"], "localhash123")
        self.assertTrue(proposal["safe_for_batch_pg_package"])

    def test_classifier_marks_supported_modal_mana_rock_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Hedron Archive",
                        "severity": "high",
                        "oracle_hash": "hedronhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "HedronArchive",
                            "path": "/xmage/HedronArchive.java",
                            "types": ["ARTIFACT"],
                            "ability_classes": ["SimpleManaAbility", "SimpleActivatedAbility"],
                            "effect_classes": ["DrawCardSourceControllerEffect"],
                            "cost_classes": ["GenericManaCost", "TapSourceCost", "SacrificeSourceCost"],
                            "primary_effect": {
                                "effect": "mana_rock_with_sacrifice_draw",
                                "battle_model_scope": "two_mana_rock_self_sacrifice_draw_two_v1",
                                "ability_kind": "activated",
                                "produces": "C",
                                "mana_produced": 2,
                                "activation_cost_generic": 2,
                                "activation_requires_tap": True,
                                "activated_self_sacrifice_draw": True,
                                "draw_on_self_sacrifice": 2,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_generator_normalizes_modal_mana_rock_to_runtime_ramp_effect(self) -> None:
        report = generator.build_generator_report(
            batch_audit={
                "cards": [
                    {
                        "card_name": "Hedron Archive",
                        "normalized_name": "hedron archive",
                        "severity": "high",
                        "oracle_hash": "hedronhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "HedronArchive",
                            "path": "/xmage/HedronArchive.java",
                            "types": ["ARTIFACT"],
                            "ability_classes": ["SimpleManaAbility", "SimpleActivatedAbility"],
                            "effect_classes": ["DrawCardSourceControllerEffect"],
                            "cost_classes": ["GenericManaCost", "TapSourceCost", "SacrificeSourceCost"],
                            "primary_effect": {
                                "effect": "mana_rock_with_sacrifice_draw",
                                "battle_model_scope": "two_mana_rock_self_sacrifice_draw_two_v1",
                                "ability_kind": "activated",
                                "produces": "C",
                                "mana_produced": 2,
                                "activation_cost_generic": 2,
                                "activation_requires_tap": True,
                                "activated_self_sacrifice_draw": True,
                                "draw_on_self_sacrifice": 2,
                            },
                        },
                    }
                ]
            },
            external_harvest=None,
        )

        proposal = report["proposals"][0]
        self.assertTrue(proposal["safe_for_batch_pg_package"])
        self.assertEqual(proposal["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(proposal["effect_json"]["battle_model_scope"], "two_mana_rock_self_sacrifice_draw_two_v1")
        self.assertEqual(proposal["effect_json"]["mana_produced"], 2)
        self.assertEqual(proposal["effect_json"]["draw_on_self_sacrifice"], 2)


if __name__ == "__main__":
    unittest.main()
