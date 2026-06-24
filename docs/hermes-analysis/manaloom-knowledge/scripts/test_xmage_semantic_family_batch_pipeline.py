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

    def test_classifier_marks_variable_self_spell_cost_reducer_as_batch_safe(self) -> None:
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
                            "types": ["CREATURE"],
                            "cost_classes": ["SacrificeXTargetCost"],
                            "primary_effect": {
                                "effect": "static_cost_reduction",
                                "battle_model_scope": "static_variable_self_spell_cost_reduction_variant_v1",
                                "cost_reduction_applies_to": "this_spell",
                                "cost_reduction_amount_source": "sacrificed_artifact_or_creature_count_this_turn",
                                "cost_reduction_counts_additional_sacrifices_paid_while_casting": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

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

    def test_classifier_marks_natures_claim_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Nature's Claim",
                        "severity": "high",
                        "oracle_hash": "naturesclaimhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "NaturesClaim",
                            "path": "/xmage/NaturesClaim.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["DestroyTargetEffect", "GainLifeTargetControllerEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "remove_permanent",
                                "battle_model_scope": "artifact_or_enchantment_removal_lifegain_v1",
                                "target": "artifact_or_enchantment",
                                "target_controller_gains_life": 4,
                                "instant": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_seal_of_primordium_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Seal of Primordium",
                        "severity": "high",
                        "oracle_hash": "sealhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "SealOfPrimordium",
                            "path": "/xmage/SealOfPrimordium.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["DestroyTargetEffect"],
                            "ability_classes": ["SimpleActivatedAbility"],
                            "cost_classes": ["SacrificeSourceCost"],
                            "primary_effect": {
                                "effect": "remove_permanent",
                                "battle_model_scope": "activated_sacrifice_self_destroy_artifact_or_enchantment_v1",
                                "target": "artifact_or_enchantment",
                                "activation_cost": "sacrifice_self",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_aura_of_silence_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Aura of Silence",
                        "severity": "high",
                        "oracle_hash": "aurahash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "AuraOfSilence",
                            "path": "/xmage/AuraOfSilence.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["DestroyTargetEffect", "SpellsCostIncreasingAllEffect"],
                            "ability_classes": ["SimpleActivatedAbility", "SimpleStaticAbility"],
                            "cost_classes": ["SacrificeSourceCost"],
                            "primary_effect": {
                                "effect": "remove_permanent",
                                "battle_model_scope": "aura_of_silence_tax_and_sacrifice_removal_waiver_v1",
                                "target": "artifact_or_enchantment",
                                "activation_cost": "sacrifice_self",
                                "taxes_opponent_artifact_enchantment_spells": 2,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_veil_of_summer_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Veil of Summer",
                        "severity": "high",
                        "oracle_hash": "veilhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "VeilOfSummer",
                            "path": "/xmage/VeilOfSummer.java",
                            "types": ["INSTANT"],
                            "effect_classes": [
                                "ConditionalOneShotEffect",
                                "DrawCardSourceControllerEffect",
                                "CantBeCounteredControlledEffect",
                                "GainAbilityControlledEffect",
                                "GainAbilityControllerEffect",
                                "VeilOfSummerEffect",
                            ],
                            "ability_classes": ["HexproofFromBlueAbility", "HexproofFromBlackAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "draw_cards",
                                "battle_model_scope": "veil_of_summer_draw_and_protection_waiver_v1",
                                "count": 1,
                                "instant": True,
                                "conditional_draw_if_opponent_cast_blue_or_black_spell_this_turn": True,
                                "spells_you_control_cant_be_countered_this_turn": True,
                                "controller_and_permanents_hexproof_from_colors_until_eot": ["U", "B"],
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_rishkar_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Rishkar, Peema Renegade",
                        "severity": "high",
                        "oracle_hash": "rishkarhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "RishkarPeemaRenegade",
                            "path": "/xmage/RishkarPeemaRenegade.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["AddCountersTargetEffect", "GainAbilityControlledEffect"],
                            "ability_classes": ["EntersBattlefieldTriggeredAbility", "SimpleStaticAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "rishkar_counter_mana_creature_waiver_v1",
                                "power": 2,
                                "toughness": 2,
                                "etb_plus_one_counter_targets": 2,
                                "countered_creatures_tap_for_mana": True,
                                "produces": "G",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_colossal_skyturtle_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Colossal Skyturtle",
                        "severity": "high",
                        "oracle_hash": "skyturtlehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "ColossalSkyturtle",
                            "path": "/xmage/ColossalSkyturtle.java",
                            "types": ["CREATURE", "ENCHANTMENT"],
                            "effect_classes": [
                                "ReturnFromGraveyardToHandTargetEffect",
                                "ReturnToHandTargetEffect",
                            ],
                            "ability_classes": ["ChannelAbility", "FlyingAbility", "WardAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "flying_ward_channel_regrowth_or_bounce_creature_v1",
                                "power": 6,
                                "toughness": 5,
                                "flying": True,
                                "ward_cost": "{2}",
                                "channel_return_graveyard_card_to_hand": "{2}{G}",
                                "channel_return_target_creature_to_hand": "{1}{U}",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_abigale_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Abigale, Eloquent First-Year",
                        "severity": "high",
                        "oracle_hash": "abigalehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "AbigaleEloquentFirstYear",
                            "path": "/xmage/AbigaleEloquentFirstYear.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["LoseAllAbilitiesTargetEffect", "AddCountersTargetEffect"],
                            "ability_classes": [
                                "EntersBattlefieldTriggeredAbility",
                                "FlyingAbility",
                                "FirstStrikeAbility",
                                "LifelinkAbility",
                            ],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "etb_strip_other_creature_abilities_and_grant_keyword_counters_v1",
                                "power": 1,
                                "toughness": 1,
                                "flying": True,
                                "first_strike": True,
                                "lifelink": True,
                                "etb_other_target_creature_loses_all_abilities": True,
                                "etb_grants_keyword_counters": ["flying", "first_strike", "lifelink"],
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_glen_elendra_archmage_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Glen Elendra Archmage",
                        "severity": "high",
                        "oracle_hash": "glenhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "GlenElendraArchmage",
                            "path": "/xmage/GlenElendraArchmage.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CounterTargetEffect"],
                            "ability_classes": ["SimpleActivatedAbility", "FlyingAbility", "PersistAbility"],
                            "cost_classes": ["SacrificeSourceCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "flying_persist_sacrifice_self_counter_noncreature_spell_v1",
                                "power": 2,
                                "toughness": 2,
                                "flying": True,
                                "persist": True,
                                "activated_counter_noncreature_spell_cost": "{U}",
                                "activation_cost": "sacrifice_self",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_borne_upon_a_wind_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Borne Upon a Wind",
                        "severity": "high",
                        "oracle_hash": "bornehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "BorneUponAWind",
                            "path": "/xmage/BorneUponAWind.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["CastAsThoughItHadFlashAllEffect", "DrawCardSourceControllerEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "draw_cards",
                                "battle_model_scope": "draw_one_and_source_controller_spells_gain_flash_until_eot_v1",
                                "count": 1,
                                "instant": True,
                                "source_controller_spells_have_flash_until_eot": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_consecrated_sphinx_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Consecrated Sphinx",
                        "severity": "high",
                        "oracle_hash": "sphinxhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "ConsecratedSphinx",
                            "path": "/xmage/ConsecratedSphinx.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["DrawCardSourceControllerEffect"],
                            "ability_classes": ["ConsecratedSphinxTriggeredAbility", "FlyingAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "flying_may_draw_two_when_opponent_draws_card_v1",
                                "power": 4,
                                "toughness": 6,
                                "flying": True,
                                "opponent_draws_card_may_draw": 2,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_faerie_mastermind_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Faerie Mastermind",
                        "severity": "high",
                        "oracle_hash": "faeriehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "FaerieMastermind",
                            "path": "/xmage/FaerieMastermind.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["DrawCardSourceControllerEffect", "DrawCardAllEffect"],
                            "ability_classes": [
                                "DrawNthCardTriggeredAbility",
                                "FlashAbility",
                                "FlyingAbility",
                                "SimpleActivatedAbility",
                            ],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "flash_flying_second_opponent_draw_draw_one_and_activated_each_player_draw_v1",
                                "power": 2,
                                "toughness": 1,
                                "flash": True,
                                "flying": True,
                                "opponent_second_card_each_turn_draw": 1,
                                "activated_each_player_draw_cost": "{3}{U}",
                                "activated_each_player_draw_count": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_nezahal_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Nezahal, Primal Tide",
                        "severity": "high",
                        "oracle_hash": "nezahalhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "NezahalPrimalTide",
                            "path": "/xmage/NezahalPrimalTide.java",
                            "types": ["CREATURE"],
                            "effect_classes": [
                                "DrawCardSourceControllerEffect",
                                "ExileReturnBattlefieldOwnerNextEndStepSourceEffect",
                                "MaximumHandSizeControllerEffect",
                            ],
                            "ability_classes": [
                                "CantBeCounteredSourceAbility",
                                "SimpleActivatedAbility",
                                "SimpleStaticAbility",
                                "SpellCastOpponentTriggeredAbility",
                            ],
                            "cost_classes": ["DiscardTargetCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "cant_be_countered_no_max_hand_opponent_noncreature_cast_draw_exile_blink_v1",
                                "power": 7,
                                "toughness": 7,
                                "cant_be_countered": True,
                                "no_maximum_hand_size": True,
                                "opponent_casts_noncreature_draw": 1,
                                "activated_discard_cards_to_exile_and_return_tapped_count": 3,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_goblin_bombardment_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Goblin Bombardment",
                        "severity": "high",
                        "oracle_hash": "bombardmenthash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "GoblinBombardment",
                            "path": "/xmage/GoblinBombardment.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["DamageTargetEffect"],
                            "ability_classes": ["SimpleActivatedAbility"],
                            "cost_classes": ["SacrificeTargetCost"],
                            "primary_effect": {
                                "effect": "direct_damage",
                                "battle_model_scope": "activated_sacrifice_creature_deal_one_any_target_v1",
                                "activation_cost": "sacrifice_creature",
                                "damage": 1,
                                "target": "any_target",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_vexing_bauble_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Vexing Bauble",
                        "severity": "high",
                        "oracle_hash": "baublehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "VexingBauble",
                            "path": "/xmage/VexingBauble.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": ["CounterTargetEffect", "DrawCardSourceControllerEffect"],
                            "ability_classes": ["SpellCastAllTriggeredAbility", "SimpleActivatedAbility"],
                            "cost_classes": ["GenericManaCost", "TapSourceCost", "SacrificeSourceCost"],
                            "primary_effect": {
                                "effect": "artifact",
                                "battle_model_scope": "counter_no_mana_spent_spells_and_cantrip_sacrifice_v1",
                                "trigger_counter_spell_if_no_mana_was_spent": True,
                                "activated_generic_one_tap_sacrifice_draw": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_soul_guide_lantern_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Soul-Guide Lantern",
                        "severity": "high",
                        "oracle_hash": "lanternhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "SoulGuideLantern",
                            "path": "/xmage/SoulGuideLantern.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": [
                                "ExileTargetEffect",
                                "DrawCardSourceControllerEffect",
                                "OneShotEffect",
                                "SoulGuideLanternEffect",
                            ],
                            "ability_classes": ["EntersBattlefieldTriggeredAbility", "SimpleActivatedAbility"],
                            "cost_classes": ["TapSourceCost", "SacrificeSourceCost", "GenericManaCost"],
                            "primary_effect": {
                                "effect": "artifact",
                                "battle_model_scope": "etb_exile_graveyard_card_or_sacrifice_for_mass_graveyard_exile_or_draw_v1",
                                "etb_exile_target_card_from_graveyard": True,
                                "activated_tap_sacrifice_exile_each_opponents_graveyard": True,
                                "activated_generic_one_tap_sacrifice_draw": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_cyclonic_rift_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Cyclonic Rift",
                        "severity": "high",
                        "oracle_hash": "rifthash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "CyclonicRift",
                            "path": "/xmage/CyclonicRift.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["ReturnToHandTargetEffect"],
                            "ability_classes": ["OverloadAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "bounce",
                                "battle_model_scope": "return_target_nonland_permanent_you_dont_control_or_overload_all_opponents_nonlands_v1",
                                "instant": True,
                                "target": "nonland_permanent_you_dont_control",
                                "overload_cost": "{6}{U}",
                                "overload_bounces_each_nonland_permanent_you_dont_control": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_red_elemental_blast_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Red Elemental Blast",
                        "severity": "high",
                        "oracle_hash": "rebehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "RedElementalBlast",
                            "path": "/xmage/RedElementalBlast.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["CounterTargetEffect", "DestroyTargetEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "modal_spell",
                                "battle_model_scope": "counter_target_blue_spell_or_destroy_target_blue_permanent_v1",
                                "counter_target_blue_spell": True,
                                "destroy_target_blue_permanent": True,
                                "instant": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_an_offer_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "An Offer You Can't Refuse",
                        "severity": "high",
                        "oracle_hash": "offerhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "AnOfferYouCantRefuse",
                            "path": "/xmage/AnOfferYouCantRefuse.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["CounterTargetEffect", "CreateTokenControllerTargetEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "counter_spell",
                                "battle_model_scope": "counter_noncreature_spell_target_controller_treasure_two_v1",
                                "target": "noncreature_spell",
                                "instant": True,
                                "target_controller_creates_treasure": 2,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_swan_song_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Swan Song",
                        "severity": "high",
                        "oracle_hash": "swanhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "SwanSong",
                            "path": "/xmage/SwanSong.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["CounterTargetEffect", "CreateTokenControllerTargetEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "counter_spell",
                                "battle_model_scope": "counter_enchantment_instant_sorcery_spell_target_controller_bird_v1",
                                "target": "enchantment_instant_or_sorcery_spell",
                                "instant": True,
                                "target_controller_creates_token": {
                                    "name": "Bird",
                                    "count": 1,
                                    "power": 2,
                                    "toughness": 2,
                                    "colors": ["U"],
                                    "keywords": ["flying"],
                                },
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_pact_of_negation_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Pact of Negation",
                        "severity": "high",
                        "oracle_hash": "pacthash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "PactOfNegation",
                            "path": "/xmage/PactOfNegation.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["CounterTargetEffect", "CreateDelayedTriggeredAbilityEffect"],
                            "ability_classes": ["PactDelayedTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "counter_spell",
                                "battle_model_scope": "pact_of_negation_delayed_upkeep_counter_v1",
                                "target": "spell",
                                "instant": True,
                                "delayed_upkeep_mana_payment": "{3}{U}{U}",
                                "lose_game_if_unpaid": True,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_refute_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Refute",
                        "severity": "high",
                        "oracle_hash": "refutehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "Refute",
                            "path": "/xmage/Refute.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["CounterTargetEffect", "DrawDiscardControllerEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "counter_spell",
                                "battle_model_scope": "counter_spell_draw_then_discard_v1",
                                "target": "spell",
                                "instant": True,
                                "draw_then_discard": 1,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_wizards_retort_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Wizard's Retort",
                        "severity": "high",
                        "oracle_hash": "retorthash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "WizardsRetort",
                            "path": "/xmage/WizardsRetort.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["CounterTargetEffect", "SpellCostReductionSourceEffect"],
                            "ability_classes": ["SimpleStaticAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "counter_spell",
                                "battle_model_scope": "counter_spell_costs_one_less_if_control_wizard_v1",
                                "target": "spell",
                                "instant": True,
                                "cost_reduction_generic_if_control_wizard": 1,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_carrion_feeder_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Carrion Feeder",
                        "severity": "high",
                        "oracle_hash": "feederhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "CarrionFeeder",
                            "path": "/xmage/CarrionFeeder.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["AddCountersSourceEffect"],
                            "ability_classes": ["CantBlockAbility", "SimpleActivatedAbility"],
                            "cost_classes": ["SacrificeTargetCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "sacrifice_creature_put_plus_one_counter_on_self_cant_block_v1",
                                "power": 1,
                                "toughness": 1,
                                "cant_block": True,
                                "activation_cost": "sacrifice_creature",
                                "self_add_plus_one_counter": 1,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_icatian_moneychanger_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Icatian Moneychanger",
                        "severity": "high",
                        "oracle_hash": "moneyhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "IcatianMoneychanger",
                            "path": "/xmage/IcatianMoneychanger.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["AddCountersSourceEffect", "DamageControllerEffect", "GainLifeEffect"],
                            "ability_classes": [
                                "EntersBattlefieldAbility",
                                "EntersBattlefieldTriggeredAbility",
                                "BeginningOfUpkeepTriggeredAbility",
                                "ActivateIfConditionActivatedAbility",
                            ],
                            "cost_classes": ["SacrificeSourceCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "credit_counter_upkeep_growth_sacrifice_for_life_v1",
                                "power": 0,
                                "toughness": 2,
                                "enters_with_credit_counters": 3,
                                "etb_damage_controller": 3,
                                "upkeep_add_credit_counter": 1,
                                "activation_cost": "sacrifice_self",
                                "gain_life_per_credit_counter": True,
                                "activation_only_your_upkeep": True,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_warden_of_the_grove_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Warden of the Grove",
                        "severity": "high",
                        "oracle_hash": "wardenhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "WardenOfTheGrove",
                            "path": "/xmage/WardenOfTheGrove.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["AddCountersSourceEffect", "EndureSourceEffect", "OneShotEffect", "WardenOfTheGroveEffect"],
                            "ability_classes": ["BeginningOfEndStepTriggeredAbility", "EntersBattlefieldAllTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "end_step_plus_one_counter_and_other_nontoken_creature_endures_x_v1",
                                "power": 2,
                                "toughness": 2,
                                "end_step_add_plus_one_counter": 1,
                                "other_nontoken_creature_endures_equal_to_source_counters": True,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_wildborn_preserver_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Wildborn Preserver",
                        "severity": "high",
                        "oracle_hash": "wildhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "WildbornPreserver",
                            "path": "/xmage/WildbornPreserver.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["AddCountersSourceEffect"],
                            "ability_classes": [
                                "FlashAbility",
                                "ReachAbility",
                                "EntersBattlefieldControlledTriggeredAbility",
                                "ReflexiveTriggeredAbility",
                            ],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "flash_reach_nonhuman_etb_pay_x_put_x_plus_one_counters_on_self_v1",
                                "power": 2,
                                "toughness": 2,
                                "flash": True,
                                "reach": True,
                                "another_nonhuman_etb_optional_pay_x_for_x_plus_one_counters_on_self": True,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

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
