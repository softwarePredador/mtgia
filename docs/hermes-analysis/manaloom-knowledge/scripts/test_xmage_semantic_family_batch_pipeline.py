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

    def test_classifier_marks_supported_brain_freeze_and_cabal_runtime_scopes_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Brain Freeze",
                        "severity": "high",
                        "oracle_hash": "brain-freeze-hash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "BrainFreeze",
                            "path": "/xmage/BrainFreeze.java",
                            "types": ["INSTANT"],
                            "ability_classes": ["StormAbility"],
                            "effect_classes": ["MillCardsTargetEffect"],
                            "primary_effect": {
                                "effect": "brain_freeze",
                                "battle_model_scope": "storm_target_player_mill_fixed_count_v1",
                                "ability_kind": "one_shot",
                                "instant": True,
                                "target": "player",
                                "mill_count": 3,
                                "storm": True,
                            },
                        },
                    },
                    {
                        "card_name": "Cabal Ritual",
                        "severity": "high",
                        "oracle_hash": "cabal-ritual-hash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "CabalRitual",
                            "path": "/xmage/CabalRitual.java",
                            "types": ["INSTANT"],
                            "ability_classes": [],
                            "effect_classes": ["BasicManaEffect", "ConditionalManaEffect"],
                            "condition_classes": ["ThresholdCondition"],
                            "primary_effect": {
                                "effect": "ramp_ritual",
                                "battle_model_scope": "threshold_three_or_five_black_mana_ritual_v1",
                                "ability_kind": "one_shot",
                                "instant": True,
                                "mana_produced": 3,
                                "produces": "B",
                                "threshold_graveyard_count": 7,
                                "threshold_mana_produced": 5,
                            },
                        },
                    },
                ]
            }
        )

        by_name = {card["card_name"]: card for card in report["cards"]}
        self.assertEqual(by_name["Brain Freeze"]["family_id"], "mill_spell")
        self.assertEqual(by_name["Brain Freeze"]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")
        self.assertEqual(by_name["Cabal Ritual"]["family_id"], "ramp_ritual")
        self.assertEqual(by_name["Cabal Ritual"]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

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

    def test_classifier_marks_single_treasure_creation_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Strike It Rich",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "StrikeItRich",
                            "path": "/xmage/StrikeItRich.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["CreateTokenEffect", "WinGameSourceControllerEffect"],
                            "primary_effect": {
                                "effect": "treasure_maker",
                                "battle_model_scope": "single_treasure_creation_v1",
                                "ability_kind": "one_shot",
                                "treasure_count": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "treasure_maker")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_treasure_vault_x_treasure_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Treasure Vault",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "TreasureVault",
                            "path": "/xmage/TreasureVault.java",
                            "types": ["ARTIFACT", "LAND"],
                            "effect_classes": ["CreateTokenEffect"],
                            "ability_classes": ["ColorlessManaAbility", "SimpleActivatedAbility"],
                            "cost_classes": ["TapSourceCost", "SacrificeSourceCost"],
                            "primary_effect": {
                                "effect": "treasure_maker",
                                "battle_model_scope": "activated_xx_tap_sacrifice_create_x_treasures_v1",
                                "ability_kind": "activated",
                                "produces": "C",
                                "mana_produced": 1,
                                "activation_requires_tap": True,
                                "activation_requires_sacrifice": True,
                                "activation_cost_generic_is_x_twice": True,
                                "treasure_count_source": "x_value",
                                "treasure_count_per_x": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "treasure_maker")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_generator_uses_treasure_role_for_treasure_vault_batch_candidate(self) -> None:
        report = generator.build_generator_report(
            batch_audit={
                "generated_at": "2026-06-24T00:00:00+00:00",
                "status": "ready",
                "source": {"deck_id": 116},
                "summary": {},
                "cards": [
                    {
                        "card_name": "Treasure Vault",
                        "severity": "high",
                        "oracle_hash": "22f7f449ee56143d6b63814fecd37176",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "TreasureVault",
                            "path": "/xmage/TreasureVault.java",
                            "types": ["ARTIFACT", "LAND"],
                            "effect_classes": ["CreateTokenEffect"],
                            "ability_classes": ["ColorlessManaAbility", "SimpleActivatedAbility"],
                            "cost_classes": ["TapSourceCost", "SacrificeSourceCost"],
                            "primary_effect": {
                                "effect": "treasure_maker",
                                "battle_model_scope": "activated_xx_tap_sacrifice_create_x_treasures_v1",
                                "ability_kind": "activated",
                                "produces": "C",
                                "mana_produced": 1,
                                "activation_requires_tap": True,
                                "activation_requires_sacrifice": True,
                                "activation_cost_generic_is_x_twice": True,
                                "treasure_count_source": "x_value",
                                "treasure_count_per_x": 1,
                            },
                        },
                    }
                ],
            },
            external_harvest={
                "status": "ready_for_manual_review",
                "cards": [
                    {
                        "card_name": "Treasure Vault",
                        "candidate_rule": {
                            "oracle_hash": "22f7f449ee56143d6b63814fecd37176",
                        },
                        "external_references": {"scryfall": {"mana_cost": ""}},
                    }
                ],
            },
        )

        proposal = report["proposals"][0]
        self.assertEqual(proposal["family_id"], "treasure_maker")
        self.assertEqual(proposal["proposal_status"], "batch_pg_candidate_after_precheck")
        self.assertEqual(proposal["deck_role_json"]["category"], "ramp")
        self.assertEqual(proposal["deck_role_json"]["effect"], "treasure_maker")

    def test_classifier_marks_simple_copy_creature_token_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Electroduplicate",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "Electroduplicate",
                            "path": "/xmage/Electroduplicate.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["CreateTokenCopyTargetEffect"],
                            "primary_effect": {
                                "effect": "copy_creature_token",
                                "battle_model_scope": "copy_target_creature_you_control_haste_sacrifice_end_step_v1",
                                "ability_kind": "one_shot",
                                "copy_target_types": ["creature"],
                                "target_controller": "own",
                                "token_haste": True,
                                "sacrifice_token_at_end_step": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "copy_creature_token")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_kindred_sorcery_copy_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Kindle the Inner Flame",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "KindleTheInnerFlame",
                            "path": "/xmage/KindleTheInnerFlame.java",
                            "types": ["KINDRED", "SORCERY"],
                            "effect_classes": ["CreateTokenCopyTargetEffect", "SacrificeSourceEffect"],
                            "ability_classes": [
                                "BeginningOfEndStepTriggeredAbility",
                                "FlashbackAbility",
                                "HasteAbility",
                            ],
                            "primary_effect": {
                                "effect": "copy_creature_token",
                                "battle_model_scope": "copy_target_creature_you_control_haste_sacrifice_end_step_v1",
                                "ability_kind": "triggered",
                                "copy_target_types": ["creature"],
                                "target_controller": "own",
                                "token_haste": True,
                                "sacrifice_token_at_end_step": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "copy_creature_token")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_copy_target_permanent_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Flash Photography",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "FlashPhotography",
                            "path": "/xmage/FlashPhotography.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["CreateTokenCopyTargetEffect"],
                            "primary_effect": {
                                "effect": "copy_creature_token",
                                "battle_model_scope": "copy_target_permanent_v1",
                                "ability_kind": "one_shot",
                                "copy_target_types": ["permanent"],
                                "target_controller": "any",
                                "token_haste": False,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "copy_creature_token")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_copy_permanent_etb_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Phyrexian Metamorph",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "PhyrexianMetamorph",
                            "path": "/xmage/PhyrexianMetamorph.java",
                            "types": ["ARTIFACT", "CREATURE"],
                            "effect_classes": ["CopyPermanentEffect"],
                            "ability_classes": ["EntersBattlefieldAbility"],
                            "primary_effect": {
                                "effect": "copy_permanent_etb",
                                "battle_model_scope": "etb_copy_target_permanent_with_optional_extra_type_v1",
                                "ability_kind": "replacement",
                                "copy_target_types": ["artifact", "creature"],
                                "copy_additional_types": ["artifact"],
                                "target_controller": "any",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "copy_permanent_etb")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

        generator_report = generator.build_generator_report(
            batch_audit={
                "cards": [
                    {
                        "card_name": "Phyrexian Metamorph",
                        "severity": "high",
                        "oracle_hash": "metamorph-hash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "PhyrexianMetamorph",
                            "path": "/xmage/PhyrexianMetamorph.java",
                            "types": ["ARTIFACT", "CREATURE"],
                            "effect_classes": ["CopyPermanentEffect"],
                            "ability_classes": ["EntersBattlefieldAbility"],
                            "primary_effect": {
                                "effect": "copy_permanent_etb",
                                "battle_model_scope": "etb_copy_target_permanent_with_optional_extra_type_v1",
                                "ability_kind": "replacement",
                                "copy_target_types": ["artifact", "creature"],
                                "copy_additional_types": ["artifact"],
                                "target_controller": "any",
                            },
                        },
                    }
                ]
            },
            external_harvest={
                "cards": [
                    {
                        "card_name": "Phyrexian Metamorph",
                        "candidate_rule": {"oracle_hash": "metamorph-hash"},
                        "external_references": {"scryfall": {"mana_cost": "{3}{U/P}"}},
                    }
                ]
            },
        )
        proposal = generator_report["proposals"][0]
        self.assertEqual(proposal["family_id"], "copy_permanent_etb")
        self.assertEqual(proposal["deck_role_json"]["category"], "board_development")
        self.assertEqual(proposal["deck_role_json"]["effect"], "copy_permanent_etb")
        self.assertEqual(proposal["proposal_status"], "batch_pg_candidate_after_precheck")

    def test_classifier_marks_copy_permanent_modifier_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Mockingbird",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "Mockingbird",
                            "path": "/xmage/Mockingbird.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CopyPermanentEffect", "MockingbirdEffect", "OneShotEffect"],
                            "ability_classes": ["EntersBattlefieldAbility", "FlyingAbility"],
                            "primary_effect": {
                                "effect": "copy_permanent_etb",
                                "battle_model_scope": "etb_copy_target_creature_with_copy_applier_modifiers_v1",
                                "ability_kind": "replacement",
                                "copy_target_types": ["creature"],
                                "target_controller": "any",
                                "copy_additional_subtypes": ["Bird"],
                                "copy_granted_keywords": ["flying"],
                                "copy_target_mana_value_lte_source_mana_value": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "copy_permanent_etb")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_clone_legion_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Clone Legion",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "CloneLegion",
                            "path": "/xmage/CloneLegion.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["CreateTokenCopyTargetEffect"],
                            "primary_effect": {
                                "effect": "copy_creature_token",
                                "battle_model_scope": "copy_each_creature_target_player_controls_v1",
                                "ability_kind": "one_shot",
                                "copy_target_types": ["creature"],
                                "target_controller": "opponent",
                                "copy_all_matching_targets": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "copy_creature_token")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_jaxis_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Jaxis, the Troublemaker",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "JaxisTheTroublemaker",
                            "path": "/xmage/JaxisTheTroublemaker.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenCopyTargetEffect", "DrawCardSourceControllerEffect"],
                            "primary_effect": {
                                "effect": "copy_creature_token",
                                "battle_model_scope": "copy_target_another_creature_you_control_haste_draw_on_death_sacrifice_end_step_v1",
                                "ability_kind": "activated",
                                "copy_target_types": ["creature"],
                                "target_controller": "own",
                                "exclude_source_from_copy_targets": True,
                                "token_haste": True,
                                "token_draw_cards_when_this_dies": 1,
                                "sacrifice_token_at_end_step": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "copy_creature_token")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_rionya_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Rionya, Fire Dancer",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "RionyaFireDancer",
                            "path": "/xmage/RionyaFireDancer.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenCopyTargetEffect"],
                            "ability_classes": ["BeginningOfCombatTriggeredAbility"],
                            "primary_effect": {
                                "effect": "copy_creature_token",
                                "battle_model_scope": "copy_target_another_creature_you_control_x_instant_sorcery_plus_one_haste_exile_end_step_v1",
                                "ability_kind": "triggered",
                                "copy_target_types": ["creature"],
                                "target_controller": "own",
                                "exclude_source_from_copy_targets": True,
                                "token_count_source": "instant_or_sorcery_spells_cast_this_turn_plus_one",
                                "token_haste": True,
                                "exile_token_at_end_step": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "copy_creature_token")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_jolly_balloon_man_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "The Jolly Balloon Man",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "TheJollyBalloonMan",
                            "path": "/xmage/TheJollyBalloonMan.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenCopyTargetEffect"],
                            "ability_classes": ["ActivateAsSorceryActivatedAbility"],
                            "primary_effect": {
                                "effect": "copy_creature_token",
                                "battle_model_scope": "copy_target_another_creature_you_control_balloon_1_1_red_flying_haste_sacrifice_end_step_v1",
                                "ability_kind": "activated",
                                "copy_target_types": ["creature"],
                                "target_controller": "own",
                                "exclude_source_from_copy_targets": True,
                                "force_token_creature": True,
                                "token_power": 1,
                                "token_toughness": 1,
                                "token_extra_colors": ["R"],
                                "token_subtype": "Balloon",
                                "token_flying": True,
                                "token_haste": True,
                                "sacrifice_token_at_end_step": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "copy_creature_token")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_springheart_landfall_copy_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Springheart Nantuko",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "SpringheartNantuko",
                            "path": "/xmage/SpringheartNantuko.java",
                            "types": ["CREATURE", "ENCHANTMENT"],
                            "effect_classes": [
                                "CreateTokenCopyTargetEffect",
                                "CreateTokenEffect",
                                "BoostEnchantedEffect",
                            ],
                            "ability_classes": ["BestowAbility", "LandfallAbility", "SimpleStaticAbility"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "landfall_optional_pay_copy_attached_creature_else_insect_v1",
                                "ability_kind": "triggered",
                                "is_creature_permanent": True,
                                "power": 1,
                                "toughness": 1,
                                "landfall_optional_pay_copy_attached_creature_else_insect": True,
                                "landfall_copy_cost": "{1}{G}",
                                "bestow_cost": "{1}{G}",
                                "bestow_attached_creature_power_bonus": 1,
                                "bestow_attached_creature_toughness_bonus": 1,
                                "token_name": "Insect Token",
                                "token_subtype": "Insect",
                                "token_colors": ["G"],
                                "token_power": 1,
                                "token_toughness": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "creature")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_lotho_treasure_engine_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Lotho, Corrupt Shirriff",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "LothoCorruptShirriff",
                            "path": "/xmage/LothoCorruptShirriff.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenEffect", "LoseLifeSourceControllerEffect"],
                            "ability_classes": ["CastSecondSpellTriggeredAbility"],
                            "primary_effect": {
                                "effect": "ramp_engine",
                                "battle_model_scope": "opponent_second_spell_each_turn_create_treasure_life_loss_v1",
                                "ability_kind": "triggered",
                                "is_creature_permanent": True,
                                "power": 2,
                                "toughness": 1,
                                "trigger": "opponent_spell",
                                "opponent_second_spell_each_turn": True,
                                "treasure_count": 1,
                                "controller_loses_life_on_trigger": 1,
                                "draw_on_enter": False,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "ramp_engine")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_tataru_taru_treasure_engine_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Tataru Taru",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "TataruTaru",
                            "path": "/xmage/TataruTaru.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenEffect", "DrawCardSourceControllerEffect"],
                            "ability_classes": [
                                "DrawCardOpponentTriggeredAbility",
                                "EntersBattlefieldTriggeredAbility",
                            ],
                            "primary_effect": {
                                "effect": "ramp_engine",
                                "battle_model_scope": "etb_draw_target_opponent_may_draw_off_turn_once_each_turn_tapped_treasure_v1",
                                "ability_kind": "triggered",
                                "is_creature_permanent": True,
                                "power": 0,
                                "toughness": 3,
                                "trigger": "opponent_draw",
                                "treasure_count": 1,
                                "treasure_tokens_tapped": True,
                                "trigger_only_off_turn_opponent_draw": True,
                                "trigger_limit_each_turn": 1,
                                "etb_draw_count": 1,
                                "etb_target_opponent_may_draw_count": 1,
                                "etb_target_opponent_may_draw_choice_model": "compact_assume_yes_single_card_v1",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "ramp_engine")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_generator_uses_ramp_role_for_tataru_taru_batch_candidate(self) -> None:
        report = generator.build_generator_report(
            batch_audit={
                "cards": [
                    {
                        "card_name": "Tataru Taru",
                        "severity": "high",
                        "oracle_hash": "313b5afad418df592c6011b08c80d972",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "TataruTaru",
                            "path": "/xmage/TataruTaru.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenEffect", "DrawCardSourceControllerEffect"],
                            "ability_classes": [
                                "DrawCardOpponentTriggeredAbility",
                                "EntersBattlefieldTriggeredAbility",
                            ],
                            "primary_effect": {
                                "effect": "ramp_engine",
                                "battle_model_scope": "etb_draw_target_opponent_may_draw_off_turn_once_each_turn_tapped_treasure_v1",
                                "ability_kind": "triggered",
                                "is_creature_permanent": True,
                                "power": 0,
                                "toughness": 3,
                                "trigger": "opponent_draw",
                                "treasure_count": 1,
                                "treasure_tokens_tapped": True,
                                "trigger_only_off_turn_opponent_draw": True,
                                "trigger_limit_each_turn": 1,
                                "etb_draw_count": 1,
                                "etb_target_opponent_may_draw_count": 1,
                                "etb_target_opponent_may_draw_choice_model": "compact_assume_yes_single_card_v1",
                            },
                        },
                    }
                ]
            },
            external_harvest={
                "status": "ready_for_manual_review",
                "cards": [
                    {
                        "card_name": "Tataru Taru",
                        "candidate_rule": {
                            "oracle_hash": "313b5afad418df592c6011b08c80d972",
                        },
                    }
                ],
            },
        )

        proposal = report["proposals"][0]
        self.assertEqual(proposal["proposal_status"], "batch_pg_candidate_after_precheck")
        self.assertEqual(proposal["deck_role_json"]["category"], "ramp")
        self.assertEqual(proposal["deck_role_json"]["effect"], "ramp_engine")

    def test_classifier_marks_knuckles_treasure_engine_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Knuckles the Echidna",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "KnucklesTheEchidna",
                            "path": "/xmage/KnucklesTheEchidna.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenEffect", "WinGameSourceControllerEffect"],
                            "ability_classes": [
                                "DoubleStrikeAbility",
                                "HasteAbility",
                                "OneOrMoreCombatDamagePlayerTriggeredAbility",
                                "TrampleAbility",
                            ],
                            "primary_effect": {
                                "effect": "ramp_engine",
                                "battle_model_scope": "one_or_more_creatures_you_control_combat_damage_player_create_treasure_v1",
                                "ability_kind": "triggered",
                                "is_creature_permanent": True,
                                "power": 2,
                                "toughness": 4,
                                "double_strike": True,
                                "trample": True,
                                "haste": True,
                                "trigger": "combat_damage_to_player",
                                "trigger_creatures_you_control": True,
                                "treasure_count": 1,
                                "upkeep_win_if_control_artifacts_at_least": 30,
                                "upkeep_win_status": "annotation_only",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "ramp_engine")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_generator_uses_ramp_role_for_knuckles_batch_candidate(self) -> None:
        report = generator.build_generator_report(
            batch_audit={
                "cards": [
                    {
                        "card_name": "Knuckles the Echidna",
                        "severity": "high",
                        "oracle_hash": "c1d16fe4ac367c244d328c560c58f1dd",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "KnucklesTheEchidna",
                            "path": "/xmage/KnucklesTheEchidna.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenEffect"],
                            "ability_classes": [
                                "DoubleStrikeAbility",
                                "HasteAbility",
                                "OneOrMoreCombatDamagePlayerTriggeredAbility",
                                "TrampleAbility",
                            ],
                            "primary_effect": {
                                "effect": "ramp_engine",
                                "battle_model_scope": "one_or_more_creatures_you_control_combat_damage_player_create_treasure_v1",
                                "ability_kind": "triggered",
                                "is_creature_permanent": True,
                                "power": 2,
                                "toughness": 4,
                                "double_strike": True,
                                "trample": True,
                                "haste": True,
                                "trigger": "combat_damage_to_player",
                                "trigger_creatures_you_control": True,
                                "treasure_count": 1,
                                "upkeep_win_if_control_artifacts_at_least": 30,
                                "upkeep_win_status": "annotation_only",
                            },
                        },
                    }
                ]
            },
            external_harvest={
                "status": "ready_for_manual_review",
                "cards": [
                    {
                        "card_name": "Knuckles the Echidna",
                        "candidate_rule": {
                            "oracle_hash": "c1d16fe4ac367c244d328c560c58f1dd",
                        },
                    }
                ],
            },
        )

        proposal = report["proposals"][0]
        self.assertEqual(proposal["proposal_status"], "batch_pg_candidate_after_precheck")
        self.assertEqual(proposal["deck_role_json"]["category"], "ramp")
        self.assertEqual(proposal["deck_role_json"]["effect"], "ramp_engine")

    def test_classifier_marks_impulsive_pilferer_death_treasure_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Impulsive Pilferer",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "ImpulsivePilferer",
                            "path": "/xmage/ImpulsivePilferer.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenEffect"],
                            "ability_classes": ["DiesSourceTriggeredAbility", "EncoreAbility"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "dies_create_treasure_encore_v1",
                                "ability_kind": "triggered",
                                "power": 1,
                                "toughness": 1,
                                "dies_or_graveyard_from_battlefield_treasure": True,
                                "treasure_count": 1,
                                "encore_cost": "{3}{R}",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "creature")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_patrol_signaler_exact_token_creature_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Patrol Signaler",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "PatrolSignaler",
                            "path": "/xmage/PatrolSignaler.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenEffect"],
                            "ability_classes": ["SimpleActivatedAbility"],
                            "cost_classes": ["UntapSourceCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "activated_untap_self_create_1_1_white_kithkin_soldier_token_v1",
                                "ability_kind": "activated",
                                "is_creature_permanent": True,
                                "power": 1,
                                "toughness": 1,
                                "activated_create_token": True,
                                "activation_requires_source_tapped": True,
                                "activation_uses_untap_symbol": True,
                                "activation_cost_generic": 1,
                                "activation_cost_colors": ["W"],
                                "token_count": 1,
                                "token_name": "Kithkin Soldier Token",
                                "token_subtype": "Kithkin Soldier",
                                "token_colors": ["W"],
                                "token_power": 1,
                                "token_toughness": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "creature")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_astral_dragon_creature_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Astral Dragon",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "AstralDragon",
                            "path": "/xmage/AstralDragon.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenCopyTargetEffect"],
                            "ability_classes": ["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "etb_copy_target_noncreature_permanent_twice_as_3_3_flying_dragon_v1",
                                "ability_kind": "triggered",
                                "power": 4,
                                "toughness": 4,
                                "flying": True,
                                "etb_copy_target_types": ["noncreature_permanent"],
                                "etb_copy_token_count": 2,
                                "etb_copy_force_creature": True,
                                "etb_copy_token_power": 3,
                                "etb_copy_token_toughness": 3,
                                "etb_copy_token_flying": True,
                                "etb_copy_token_subtype": "Dragon",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "creature")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_prized_statue_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Prized Statue",
                        "severity": "high",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "PrizedStatue",
                            "path": "/xmage/PrizedStatue.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": ["CreateTokenEffect"],
                            "ability_classes": ["EntersBattlefieldOrDiesSourceTriggeredAbility"],
                            "primary_effect": {
                                "effect": "ramp_permanent",
                                "battle_model_scope": "artifact_etb_or_dies_create_treasure_v1",
                                "ability_kind": "triggered",
                                "treasure_count": 1,
                                "enters_treasure": 1,
                                "dies_or_graveyard_from_battlefield_treasure": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "ramp_permanent")
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

    def test_package_builder_matches_mdfc_left_face_against_full_card_name(self) -> None:
        proposal_report = {
            "generated_at": "2026-06-24T00:00:00+00:00",
            "proposals": [
                {
                    "card_name": "Sink into Stupor",
                    "normalized_name": "sink into stupor",
                    "oracle_hash": "sinkhash",
                    "logical_rule_key": "battle_rule_v1:sinkhash",
                    "effect_json": {
                        "effect": "bounce",
                        "battle_model_scope": "return_target_spell_or_opponent_nonland_permanent_or_tapped_blue_land_v1",
                    },
                    "deck_role_json": {"category": "interaction"},
                    "source": "curated",
                    "confidence": 0.94,
                    "review_status": "verified",
                    "execution_status": "auto",
                    "notes": "mdfc coverage",
                    "safe_for_batch_pg_package": True,
                    "family_id": "targeted_interaction",
                }
            ],
        }

        with tempfile.TemporaryDirectory() as tmp_dir:
            output_prefix = Path(tmp_dir) / "pg998_mdfc_batch"
            manifest = package_builder.build_package(
                proposal_report,
                deploy_id="PG998",
                slug="mdfc_batch",
                output_prefix=output_prefix,
                include_family=set(),
                include_card={"Sink into Stupor"},
                exclude_card=set(),
                max_cards=None,
            )

            precheck_sql = Path(manifest["files"]["precheck"]).read_text(encoding="utf-8")
            apply_sql = Path(manifest["files"]["apply"]).read_text(encoding="utf-8")
            rollback_sql = Path(manifest["files"]["rollback"]).read_text(encoding="utf-8")
            self.assertIn("split_part(lower(c.name), ' // ', 1) = p.normalized_name", precheck_sql)
            self.assertIn("normalized_name LIKE p.normalized_name || ' // %'", precheck_sql)
            self.assertIn("split_part(lower(c.name), ' // ', 1) = p.normalized_name", apply_sql)
            self.assertIn("normalized_name LIKE 'sink into stupor // %'", apply_sql)
            self.assertIn("normalized_name LIKE 'sink into stupor // %'", rollback_sql)

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

    def test_classifier_marks_agathas_soul_cauldron_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Agatha's Soul Cauldron",
                        "severity": "high",
                        "oracle_hash": "agatha-hash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "AgathasSoulCauldron",
                            "path": "/xmage/AgathasSoulCauldron.java",
                            "types": ["ARTIFACT"],
                            "ability_classes": [
                                "AddAbility",
                                "ReflexiveTriggeredAbility",
                                "SimpleActivatedAbility",
                                "SimpleStaticAbility",
                            ],
                            "effect_classes": [
                                "AddCountersTargetEffect",
                                "AgathasSoulCauldronAbilityEffect",
                                "AgathasSoulCauldronExileEffect",
                                "AgathasSoulCauldronManaEffect",
                                "AsThoughManaEffect",
                                "OneShotEffect",
                            ],
                            "cost_classes": ["TapSourceCost"],
                            "primary_effect": {
                                "effect": "passive",
                                "battle_model_scope": "graveyard_exile_counter_and_ability_grant_artifact_v1",
                                "ability_kind": "activated",
                                "mana_as_any_color_for_creature_activations": True,
                                "plus_one_counter_creatures_gain_activated_abilities_of_exiled_creatures": True,
                                "activated_tap_exile_target_card_from_graveyard": True,
                                "creature_exile_reflexive_plus_one_counter": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "passive")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_necropotence_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Necropotence",
                        "severity": "high",
                        "oracle_hash": "necro-hash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "Necropotence",
                            "path": "/xmage/Necropotence.java",
                            "types": ["ENCHANTMENT"],
                            "ability_classes": [
                                "AtTheBeginOfNextEndStepDelayedTriggeredAbility",
                                "NecropotenceTriggeredAbility",
                                "SimpleActivatedAbility",
                                "SimpleStaticAbility",
                            ],
                            "effect_classes": [
                                "ExileTargetEffect",
                                "NecropotenceEffect",
                                "OneShotEffect",
                                "ReturnToHandTargetEffect",
                                "SkipDrawStepEffect",
                            ],
                            "cost_classes": ["PayLifeCost"],
                            "primary_effect": {
                                "effect": "draw_engine",
                                "battle_model_scope": "skip_draw_discard_exile_pay_life_face_down_draw_next_end_step_v1",
                                "ability_kind": "activated",
                                "skip_draw_step": True,
                                "discard_trigger_exiles_discarded_card_from_graveyard": True,
                                "activated_pay_life": 1,
                                "activated_exile_top_card_face_down": True,
                                "activated_put_exiled_card_into_hand_next_end_step": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "draw_engine")
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

    def test_classifier_marks_insidious_roots_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Insidious Roots",
                        "severity": "high",
                        "oracle_hash": "insidioushash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "InsidiousRoots",
                            "path": "/xmage/InsidiousRoots.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": [
                                "AddCountersAllEffect",
                                "CreateTokenEffect",
                                "GainAbilityControlledEffect",
                            ],
                            "ability_classes": [
                                "CardsLeaveGraveyardTriggeredAbility",
                                "SimpleStaticAbility",
                            ],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "passive",
                                "battle_model_scope": "creature_tokens_tap_any_color_creature_graveyard_plant_growth_v1",
                                "creature_tokens_tap_for_any_color": True,
                                "creature_cards_leave_your_graveyard_create_plant_token": True,
                                "plant_tokens_get_plus_one_counter_on_creature_graveyard_exit": True,
                                "trigger_once_each_graveyard_exit_event": True,
                                "token_name": "Plant Token",
                                "token_subtype": "Plant",
                                "token_power": 0,
                                "token_toughness": 1,
                                "token_colors": ["G"],
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "passive")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_cryptolith_rite_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Cryptolith Rite",
                        "severity": "high",
                        "oracle_hash": "cryptolithhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "CryptolithRite",
                            "path": "/xmage/CryptolithRite.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["GainAbilityControlledEffect"],
                            "ability_classes": ["AnyColorManaAbility", "SimpleStaticAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "passive",
                                "battle_model_scope": "creatures_tap_any_color_static_enchantment_v1",
                                "creatures_tap_for_any_color": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "passive")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_enduring_vitality_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Enduring Vitality",
                        "severity": "high",
                        "oracle_hash": "enduringhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "EnduringVitality",
                            "path": "/xmage/EnduringVitality.java",
                            "types": ["CREATURE", "ENCHANTMENT"],
                            "effect_classes": ["GainAbilityControlledEffect"],
                            "ability_classes": [
                                "AnyColorManaAbility",
                                "EnduringGlimmerTriggeredAbility",
                                "SimpleStaticAbility",
                                "VigilanceAbility",
                            ],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "vigilance_three_three_creatures_tap_any_color_v1",
                                "power": 3,
                                "toughness": 3,
                                "vigilance": True,
                                "creatures_tap_for_any_color": True,
                                "death_return_status": "annotation_only",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "creature")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_magda_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Magda, Brazen Outlaw",
                        "severity": "high",
                        "oracle_hash": "magdahash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "MagdaBrazenOutlaw",
                            "path": "/xmage/MagdaBrazenOutlaw.java",
                            "types": ["CREATURE"],
                            "effect_classes": [
                                "BoostControlledEffect",
                                "CreateTokenEffect",
                                "SearchLibraryPutInPlayEffect",
                            ],
                            "ability_classes": [
                                "BecomesTappedTriggeredAbility",
                                "SimpleActivatedAbility",
                                "SimpleStaticAbility",
                            ],
                            "cost_classes": ["SacrificeTargetCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "magda_dwarf_tap_treasure_and_five_treasure_tutor_v1",
                                "power": 2,
                                "toughness": 1,
                                "other_dwarves_you_control_get_plus_one_power": True,
                                "controlled_dwarf_becomes_tapped_creates_treasure": True,
                                "activated_sacrifice_five_treasures_tutor_artifact_or_dragon": True,
                                "activated_treasure_tutor_cost": 5,
                                "activated_treasure_tutor_destination": "battlefield",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "creature")
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

    def test_classifier_marks_fate_unraveler_opponent_draw_punisher_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Fate Unraveler",
                        "severity": "high",
                        "oracle_hash": "fatehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "FateUnraveler",
                            "path": "/xmage/FateUnraveler.java",
                            "types": ["CREATURE", "ENCHANTMENT"],
                            "effect_classes": ["DamageTargetEffect"],
                            "ability_classes": ["DrawCardOpponentTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "opponent_draws_card_damage_that_player_v1",
                                "power": 3,
                                "toughness": 4,
                                "trigger": "opponent_draw",
                                "opponent_draw_damage_per_card": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_underworld_dreams_opponent_draw_punisher_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Underworld Dreams",
                        "severity": "high",
                        "oracle_hash": "underworldhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "UnderworldDreams",
                            "path": "/xmage/UnderworldDreams.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["DamageTargetEffect"],
                            "ability_classes": ["DrawCardOpponentTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "passive",
                                "battle_model_scope": "opponent_draws_card_damage_that_player_v1",
                                "trigger": "opponent_draw",
                                "opponent_draw_damage_per_card": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_geths_grimoire_opponent_discard_draw_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Geth's Grimoire",
                        "severity": "high",
                        "oracle_hash": "grimoirehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "GethsGrimoire",
                            "path": "/xmage/GethsGrimoire.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": ["DrawCardSourceControllerEffect"],
                            "ability_classes": ["DiscardsACardOpponentTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "draw_engine",
                                "battle_model_scope": "opponent_discards_card_may_draw_v1",
                                "draw_on_enter": False,
                                "trigger": "opponent_discard",
                                "opponent_discard_draw_per_card": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_megrim_opponent_discard_damage_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Megrim",
                        "severity": "high",
                        "oracle_hash": "megrimhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "Megrim",
                            "path": "/xmage/Megrim.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["DamageTargetEffect"],
                            "ability_classes": ["DiscardsACardOpponentTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "passive",
                                "battle_model_scope": "opponent_discards_card_damage_that_player_v1",
                                "trigger": "opponent_discard",
                                "opponent_discard_damage_per_card": 2,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_feast_of_sanity_controller_discard_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Feast of Sanity",
                        "severity": "high",
                        "oracle_hash": "feasthash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "FeastOfSanity",
                            "path": "/xmage/FeastOfSanity.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["DamageTargetEffect", "GainLifeEffect"],
                            "ability_classes": ["DiscardCardControllerTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "passive",
                                "battle_model_scope": "controller_discards_card_damage_any_target_and_gain_life_v1",
                                "trigger": "controller_discard",
                                "controller_discard_damage_any_target": 1,
                                "controller_discard_gain_life": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_cool_but_rude_exact_class_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Cool but Rude",
                        "severity": "high",
                        "oracle_hash": "coolhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "CoolButRude",
                            "path": "/xmage/CoolButRude.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": [
                                "DamagePlayersEffect",
                                "DiscardControllerEffect",
                                "DoIfCostPaid",
                                "DrawCardSourceControllerEffect",
                                "GainClassAbilitySourceEffect",
                                "SearchLibraryPutInHandEffect",
                            ],
                            "ability_classes": [
                                "AttacksWithCreaturesTriggeredAbility",
                                "BecomesClassLevelTriggeredAbility",
                                "ClassLevelAbility",
                                "ClassReminderAbility",
                                "SimpleStaticAbility",
                            ],
                            "cost_classes": ["DiscardCardCost"],
                            "primary_effect": {
                                "effect": "draw_engine",
                                "battle_model_scope": "cool_but_rude_class_attack_rummage_level_damage_tutor_v1",
                                "draw_on_enter": False,
                                "class_level_start": 1,
                                "class_level_costs": {"2": "{1}{R}", "3": "{1}{R}"},
                                "attack_trigger_optional_discard_draw": True,
                                "trigger": "controller_discard",
                                "controller_discard_damage_each_opponent": 2,
                                "controller_discard_damage_each_opponent_level_min": 2,
                                "class_level3_tutor_any_to_hand_random_discard": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_invoke_calamity_exact_free_cast_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Invoke Calamity",
                        "severity": "high",
                        "oracle_hash": "invokehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "InvokeCalamity",
                            "path": "/xmage/InvokeCalamity.java",
                            "types": ["INSTANT"],
                            "effect_classes": [
                                "ExileSpellEffect",
                                "InvokeCalamityEffect",
                                "InvokeCalamityReplacementEffect",
                                "OneShotEffect",
                            ],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "free_cast",
                                "battle_model_scope": (
                                    "cast_up_to_two_instant_sorcery_hand_graveyard_total_mv_lte_6_exile_replacement_v1"
                                ),
                                "instant": True,
                                "free_cast_from_zones": ["hand", "graveyard"],
                                "free_cast_card_types": ["instant", "sorcery"],
                                "free_cast_max_count": 2,
                                "free_cast_total_mana_value_max": 6,
                                "cast_without_paying_mana_cost": True,
                                "selected_spells_exile_instead_of_graveyard": True,
                                "exiles_self": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "free_cast")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_lightning_helix_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Lightning Helix",
                        "severity": "high",
                        "oracle_hash": "helixhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "LightningHelix",
                            "path": "/xmage/LightningHelix.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["DamageTargetEffect", "GainLifeEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "direct_damage",
                                "battle_model_scope": "damage_any_target_and_gain_life_v1",
                                "ability_kind": "one_shot",
                                "damage": 3,
                                "gain_life": 3,
                                "target": "any_target",
                                "instant": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "targeted_interaction")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_caldera_pyremaw_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Caldera Pyremaw",
                        "severity": "high",
                        "oracle_hash": "calderahash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "CalderaPyremaw",
                            "path": "/xmage/CalderaPyremaw.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["AddCountersSourceEffect", "DamageTargetEffect"],
                            "ability_classes": ["FlyingAbility", "SpellCastControllerTriggeredAbility"],
                            "target_classes": ["TargetOpponent"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "instant_sorcery_cast_add_counter_then_power_damage_target_opponent_v1",
                                "power": 3,
                                "toughness": 3,
                                "flying": True,
                                "trigger": "instant_sorcery_cast",
                                "trigger_effect": "source_counter_then_power_damage",
                                "trigger_add_plus_one_counter": 1,
                                "trigger_damage_amount_source": "source_power_after_counter",
                                "target": "opponent",
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

    def test_classifier_marks_wan_shi_tong_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Wan Shi Tong, Librarian",
                        "severity": "high",
                        "oracle_hash": "wanshihash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "WanShiTongLibrarian",
                            "path": "/xmage/WanShiTongLibrarian.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["AddCountersSourceEffect", "DrawCardSourceControllerEffect"],
                            "ability_classes": [
                                "EntersBattlefieldTriggeredAbility",
                                "FlashAbility",
                                "FlyingAbility",
                                "VigilanceAbility",
                                "WanShiTongLibrarianTriggeredAbility",
                            ],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "flash_flying_vigilance_etb_x_counters_draw_half_x_opponent_search_growth_v1",
                                "power": 1,
                                "toughness": 1,
                                "flash": True,
                                "flying": True,
                                "vigilance": True,
                                "etb_add_x_plus_one_counters": True,
                                "etb_draw_half_x_rounded_down": True,
                                "opponent_search_library_add_counter_and_draw": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_orcish_bowmasters_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Orcish Bowmasters",
                        "severity": "high",
                        "oracle_hash": "orcishhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "OrcishBowmasters",
                            "path": "/xmage/OrcishBowmasters.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["DamageTargetEffect", "AmassEffect"],
                            "ability_classes": [
                                "FlashAbility",
                                "OrTriggeredAbility",
                                "EntersBattlefieldTriggeredAbility",
                                "OpponentDrawCardExceptFirstCardDrawStepTriggeredAbility",
                            ],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "flash_etb_or_opponent_extra_draw_damage_any_target_amass_orcs_v1",
                                "power": 1,
                                "toughness": 1,
                                "flash": True,
                                "etb_or_opponent_extra_draw_damage_any_target": 1,
                                "amass_orcs": 1,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_hullbreaker_horror_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Hullbreaker Horror",
                        "severity": "high",
                        "oracle_hash": "hullhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "HullbreakerHorror",
                            "path": "/xmage/HullbreakerHorror.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["ReturnToHandTargetEffect"],
                            "ability_classes": [
                                "CantBeCounteredSourceAbility",
                                "FlashAbility",
                                "SpellCastControllerTriggeredAbility",
                            ],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "flash_cant_be_countered_cast_spell_bounce_spell_or_nonland_v1",
                                "power": 7,
                                "toughness": 8,
                                "flash": True,
                                "cant_be_countered": True,
                                "cast_spell_trigger_bounce_spell_you_dont_control": True,
                                "cast_spell_trigger_bounce_nonland_permanent": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_deathrite_shaman_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Deathrite Shaman",
                        "severity": "high",
                        "oracle_hash": "deathritehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "DeathriteShaman",
                            "path": "/xmage/DeathriteShaman.java",
                            "types": ["CREATURE"],
                            "effect_classes": [
                                "ExileTargetEffect",
                                "AddManaOfAnyColorEffect",
                                "LoseLifeOpponentsEffect",
                                "GainLifeEffect",
                            ],
                            "ability_classes": ["SimpleActivatedAbility"],
                            "cost_classes": ["TapSourceCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "graveyard_exile_mana_or_life_shaman_v1",
                                "power": 1,
                                "toughness": 2,
                                "tap_exile_land_from_graveyard_add_one_mana_any_color": True,
                                "black_tap_exile_instant_or_sorcery_from_graveyard_each_opponent_loses_life": 2,
                                "green_tap_exile_creature_from_graveyard_gain_life": 2,
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

    def test_classifier_marks_teferi_time_raveler_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Teferi, Time Raveler",
                        "severity": "high",
                        "oracle_hash": "teferihash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "TeferiTimeRaveler",
                            "path": "/xmage/TeferiTimeRaveler.java",
                            "types": ["PLANESWALKER"],
                            "effect_classes": [
                                "CastAsThoughItHadFlashAllEffect",
                                "DrawCardSourceControllerEffect",
                                "ReturnToHandTargetEffect",
                                "TeferiTimeRavelerReplacementEffect",
                            ],
                            "ability_classes": ["LoyaltyAbility", "SimpleStaticAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "planeswalker",
                                "battle_model_scope": "opponents_sorcery_speed_only_plus1_sorcery_flash_minus3_bounce_draw_v1",
                                "starting_loyalty": 4,
                                "opponents_can_cast_only_as_sorcery": True,
                                "plus_one_sorceries_have_flash_until_your_next_turn": True,
                                "minus_three_bounce_up_to_one_artifact_creature_or_enchantment_draw": 1,
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

    def test_classifier_marks_mana_leak_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Mana Leak",
                        "severity": "high",
                        "oracle_hash": "manaleakhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "ManaLeak",
                            "path": "/xmage/ManaLeak.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["CounterUnlessPaysEffect"],
                            "ability_classes": [],
                            "cost_classes": ["GenericManaCost"],
                            "primary_effect": {
                                "effect": "counter_spell",
                                "battle_model_scope": "counter_spell_unless_controller_pays_three_v1",
                                "target": "spell",
                                "instant": True,
                                "unless_controller_pays_generic": 3,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_miscast_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Miscast",
                        "severity": "high",
                        "oracle_hash": "miscasthash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "Miscast",
                            "path": "/xmage/Miscast.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["CounterUnlessPaysEffect"],
                            "ability_classes": [],
                            "cost_classes": ["GenericManaCost"],
                            "primary_effect": {
                                "effect": "counter_spell",
                                "battle_model_scope": "counter_instant_or_sorcery_unless_controller_pays_three_v1",
                                "target": "instant_or_sorcery_spell",
                                "instant": True,
                                "unless_controller_pays_generic": 3,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_spell_pierce_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Spell Pierce",
                        "severity": "high",
                        "oracle_hash": "spellpiercehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "SpellPierce",
                            "path": "/xmage/SpellPierce.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["CounterUnlessPaysEffect"],
                            "ability_classes": [],
                            "cost_classes": ["GenericManaCost"],
                            "primary_effect": {
                                "effect": "counter_spell",
                                "battle_model_scope": "counter_noncreature_spell_unless_controller_pays_two_v1",
                                "target": "noncreature_spell",
                                "instant": True,
                                "unless_controller_pays_generic": 2,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_dark_ritual_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Dark Ritual",
                        "severity": "high",
                        "oracle_hash": "darkritualhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "DarkRitual",
                            "path": "/xmage/DarkRitual.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["BasicManaEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "ramp_ritual",
                                "battle_model_scope": "three_black_mana_ritual_v1",
                                "instant": True,
                                "mana_produced": 3,
                                "produces": "B",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_pyretic_ritual_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Pyretic Ritual",
                        "severity": "high",
                        "oracle_hash": "pyretichash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "PyreticRitual",
                            "path": "/xmage/PyreticRitual.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["BasicManaEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "ramp_ritual",
                                "battle_model_scope": "three_red_mana_ritual_v1",
                                "instant": True,
                                "mana_produced": 3,
                                "produces": "R",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_desperate_ritual_arcane_splice_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Desperate Ritual",
                        "severity": "high",
                        "oracle_hash": "desperatehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "DesperateRitual",
                            "path": "/xmage/DesperateRitual.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["BasicManaEffect"],
                            "ability_classes": ["SpliceAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "ramp_ritual",
                                "battle_model_scope": "three_red_mana_arcane_splice_ritual_v1",
                                "instant": True,
                                "mana_produced": 3,
                                "produces": "R",
                                "subtype_arcane": True,
                                "splice_arcane_cost": "{1}{R}",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_elvish_spirit_guide_hand_exile_ritual_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Elvish Spirit Guide",
                        "severity": "high",
                        "oracle_hash": "esghash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "ElvishSpiritGuide",
                            "path": "/xmage/ElvishSpiritGuide.java",
                            "types": ["CREATURE"],
                            "effect_classes": [],
                            "ability_classes": ["SimpleManaAbility"],
                            "cost_classes": ["ExileSourceFromHandCost"],
                            "primary_effect": {
                                "effect": "ramp_ritual",
                                "battle_model_scope": "hand_exile_add_one_green_mana_ritual_v1",
                                "hand_exile_mana_ability": True,
                                "mana_produced": 1,
                                "produces": "G",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["family_id"], "ramp_ritual")
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_basic_one_color_land_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Mountain",
                        "severity": "medium",
                        "oracle_hash": "mountainhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "Mountain",
                            "path": "/xmage/Mountain.java",
                            "types": ["LAND"],
                            "effect_classes": [],
                            "ability_classes": ["RedManaAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "land",
                                "battle_model_scope": "basic_one_color_land_v1",
                                "mana_produced": 1,
                                "produces": "R",
                                "basic_land_types": ["Mountain"],
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "land")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_exotic_orchard_land_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Exotic Orchard",
                        "severity": "medium",
                        "oracle_hash": "orchardhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "ExoticOrchard",
                            "path": "/xmage/ExoticOrchard.java",
                            "types": ["LAND"],
                            "effect_classes": [],
                            "ability_classes": ["AnyColorLandsProduceManaAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "land",
                                "battle_model_scope": "any_color_from_opponent_land_production_v1",
                                "mana_produced": 1,
                                "produces": "WUBRG",
                                "opponent_land_color_dependency": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "land")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_fetch_land_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Misty Rainforest",
                        "severity": "medium",
                        "oracle_hash": "mistyhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "MistyRainforest",
                            "path": "/xmage/MistyRainforest.java",
                            "types": ["LAND"],
                            "effect_classes": [],
                            "ability_classes": ["FetchLandActivatedAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "ramp_permanent",
                                "battle_model_scope": "self_sacrifice_fetch_land_two_land_subtypes_v1",
                                "activated_self_sacrifice_land_tutor": True,
                                "activation_cost_generic": 0,
                                "activation_requires_tap": True,
                                "activated_pay_life": 1,
                                "land_count": 1,
                                "lands_to_battlefield": 1,
                                "land_enters_tapped": False,
                                "land_subtypes_any": ["Forest", "Island"],
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_culling_the_weak_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Culling the Weak",
                        "severity": "high",
                        "oracle_hash": "cullinghash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "CullingTheWeak",
                            "path": "/xmage/CullingTheWeak.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["BasicManaEffect"],
                            "ability_classes": [],
                            "cost_classes": ["SacrificeTargetCost"],
                            "primary_effect": {
                                "effect": "ramp_ritual",
                                "battle_model_scope": "sacrifice_creature_add_four_black_mana_ritual_v1",
                                "instant": True,
                                "requires_sacrifice_creature": True,
                                "mana_produced": 4,
                                "produces": "B",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_infernal_plunge_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Infernal Plunge",
                        "severity": "high",
                        "oracle_hash": "infernalhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "InfernalPlunge",
                            "path": "/xmage/InfernalPlunge.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["BasicManaEffect"],
                            "ability_classes": [],
                            "cost_classes": ["SacrificeTargetCost"],
                            "primary_effect": {
                                "effect": "ramp_ritual",
                                "battle_model_scope": "sacrifice_creature_add_three_red_mana_ritual_v1",
                                "instant": False,
                                "requires_sacrifice_creature": True,
                                "mana_produced": 3,
                                "produces": "R",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_mystical_tutor_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Mystical Tutor",
                        "severity": "high",
                        "oracle_hash": "mysticalhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "MysticalTutor",
                            "path": "/xmage/MysticalTutor.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["SearchLibraryPutOnLibraryEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "tutor",
                                "battle_model_scope": "instant_or_sorcery_tutor_to_top_v1",
                                "instant": True,
                                "target": "instant_or_sorcery_to_top",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_worldly_tutor_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Worldly Tutor",
                        "severity": "high",
                        "oracle_hash": "worldlyhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "WorldlyTutor",
                            "path": "/xmage/WorldlyTutor.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["SearchLibraryPutOnLibraryEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "tutor",
                                "battle_model_scope": "creature_tutor_to_top_v1",
                                "instant": True,
                                "target": "creature_to_top",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_vampiric_tutor_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Vampiric Tutor",
                        "severity": "high",
                        "oracle_hash": "vampirichash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "VampiricTutor",
                            "path": "/xmage/VampiricTutor.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["LoseLifeSourceControllerEffect", "SearchLibraryPutOnLibraryEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "tutor",
                                "battle_model_scope": "any_tutor_to_top_lose_two_life_v1",
                                "instant": True,
                                "target": "any_to_top",
                                "controller_loses_life_after_tutor": 2,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_imperial_seal_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Imperial Seal",
                        "severity": "high",
                        "oracle_hash": "imperialhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "ImperialSeal",
                            "path": "/xmage/ImperialSeal.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["LoseLifeSourceControllerEffect", "SearchLibraryPutOnLibraryEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "tutor",
                                "battle_model_scope": "any_tutor_to_top_lose_two_life_v1",
                                "instant": False,
                                "target": "any_to_top",
                                "controller_loses_life_after_tutor": 2,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_demonic_tutor_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Demonic Tutor",
                        "severity": "high",
                        "oracle_hash": "demonichash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "DemonicTutor",
                            "path": "/xmage/DemonicTutor.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["SearchLibraryPutInHandEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "tutor",
                                "battle_model_scope": "any_tutor_to_hand_v1",
                                "instant": False,
                                "target": "any_to_hand",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_diabolic_intent_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Diabolic Intent",
                        "severity": "high",
                        "oracle_hash": "diabolichash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "DiabolicIntent",
                            "path": "/xmage/DiabolicIntent.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["SearchLibraryPutInHandEffect"],
                            "ability_classes": [],
                            "cost_classes": ["SacrificeTargetCost"],
                            "primary_effect": {
                                "effect": "tutor",
                                "battle_model_scope": "sacrifice_creature_any_tutor_to_hand_v1",
                                "instant": False,
                                "target": "any_to_hand",
                                "requires_sacrifice_creature": True,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_sylvan_scrying_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Sylvan Scrying",
                        "severity": "high",
                        "oracle_hash": "sylvanhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "SylvanScrying",
                            "path": "/xmage/SylvanScrying.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["SearchLibraryPutInHandEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "tutor",
                                "battle_model_scope": "land_tutor_to_hand_v1",
                                "instant": False,
                                "target": "land_to_hand",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_expedition_map_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Expedition Map",
                        "severity": "high",
                        "oracle_hash": "maphash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "ExpeditionMap",
                            "path": "/xmage/ExpeditionMap.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": ["SearchLibraryPutInHandEffect"],
                            "ability_classes": ["SimpleActivatedAbility"],
                            "cost_classes": ["GenericManaCost", "TapSourceCost", "SacrificeSourceCost"],
                            "primary_effect": {
                                "effect": "ramp_permanent",
                                "battle_model_scope": "activated_self_sacrifice_land_tutor_to_hand_artifact_v1",
                                "activated_self_sacrifice_tutor_to_hand": True,
                                "activation_cost_generic": 2,
                                "activation_requires_tap": True,
                                "tutor_target": "land",
                                "tutor_destination": "hand",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_moonsilver_key_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Moonsilver Key",
                        "severity": "high",
                        "oracle_hash": "moonhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "MoonsilverKey",
                            "path": "/xmage/MoonsilverKey.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": ["SearchLibraryPutInHandEffect"],
                            "ability_classes": ["ManaAbility", "SimpleActivatedAbility"],
                            "cost_classes": ["GenericManaCost", "TapSourceCost", "SacrificeSourceCost"],
                            "primary_effect": {
                                "effect": "ramp_permanent",
                                "battle_model_scope": "activated_self_sacrifice_artifact_mana_ability_or_basic_land_tutor_to_hand_v1",
                                "activated_self_sacrifice_tutor_to_hand": True,
                                "activation_cost_generic": 1,
                                "activation_requires_tap": True,
                                "tutor_target": "artifact_mana_ability_or_basic_land",
                                "tutor_destination": "hand",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_weathered_wayfarer_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Weathered Wayfarer",
                        "severity": "high",
                        "oracle_hash": "wayfarerhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "WeatheredWayfarer",
                            "path": "/xmage/WeatheredWayfarer.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["SearchLibraryPutInHandEffect"],
                            "ability_classes": ["ActivateIfConditionActivatedAbility"],
                            "cost_classes": ["TapSourceCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "activated_opponent_more_lands_land_tutor_to_hand_creature_v1",
                                "power": 1,
                                "toughness": 1,
                                "land_tutor_to_hand_activated": True,
                                "activation_cost_generic": 0,
                                "activation_cost_colors": ["W"],
                                "activation_requires_tap": True,
                                "activation_condition": "opponent_controls_more_lands",
                                "tutor_target": "land",
                                "tutor_destination": "hand",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_rhystic_study_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Rhystic Study",
                        "severity": "high",
                        "oracle_hash": "rhystichash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "RhysticStudy",
                            "path": "/xmage/RhysticStudy.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["OneShotEffect", "RhysticStudyDrawEffect"],
                            "ability_classes": ["SpellCastOpponentTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "draw_engine",
                                "battle_model_scope": "opponent_spell_pay_one_or_draw_engine_v1",
                                "trigger": "opponent_spell",
                                "tax": 1,
                                "draw_on_enter": False,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_mystic_remora_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Mystic Remora",
                        "severity": "high",
                        "oracle_hash": "remorahash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "MysticRemora",
                            "path": "/xmage/MysticRemora.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["MysticRemoraEffect", "OneShotEffect"],
                            "ability_classes": ["CumulativeUpkeepAbility", "MysticRemoraTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "draw_engine",
                                "battle_model_scope": "opponent_noncreature_spell_pay_four_draw_engine_with_cumulative_upkeep_v1",
                                "trigger": "opponent_noncreature_spell",
                                "tax": 4,
                                "draw_on_enter": False,
                                "cumulative_upkeep_generic": 1,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_crop_rotation_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Crop Rotation",
                        "severity": "high",
                        "oracle_hash": "crophash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "CropRotation",
                            "path": "/xmage/CropRotation.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["SearchLibraryPutInPlayEffect"],
                            "ability_classes": [],
                            "cost_classes": ["SacrificeTargetCost"],
                            "primary_effect": {
                                "effect": "land_ramp",
                                "battle_model_scope": "sacrifice_land_for_any_land_to_battlefield_untapped_v1",
                                "instant": True,
                                "requires_sacrifice_land": True,
                                "land_count": 1,
                                "lands_to_battlefield": 1,
                                "land_enters_tapped": False,
                                "tutor_target": "land",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_elvish_reclaimer_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Elvish Reclaimer",
                        "severity": "high",
                        "oracle_hash": "reclaimerhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "ElvishReclaimer",
                            "path": "/xmage/ElvishReclaimer.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["BoostSourceEffect", "ConditionalContinuousEffect", "SearchLibraryPutInPlayEffect"],
                            "ability_classes": ["SimpleActivatedAbility", "SimpleStaticAbility"],
                            "cost_classes": ["GenericManaCost", "SacrificeTargetCost", "TapSourceCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "activated_land_tutor_with_land_sacrifice_and_graveyard_growth_v1",
                                "power": 1,
                                "toughness": 2,
                                "land_tutor_activated": True,
                                "activation_cost_generic": 2,
                                "activation_requires_tap": True,
                                "requires_sacrifice_land": True,
                                "land_count": 1,
                                "lands_to_battlefield": 1,
                                "land_enters_tapped": True,
                                "tutor_target": "land",
                                "plus_two_two_if_three_lands_in_your_graveyard": True,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_chord_of_calling_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Chord of Calling",
                        "severity": "high",
                        "oracle_hash": "chordhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "ChordOfCalling",
                            "path": "/xmage/ChordOfCalling.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["SearchLibraryWithLessCMCPutInPlayEffect"],
                            "ability_classes": ["ConvokeAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "tutor",
                                "battle_model_scope": "convoke_creature_tutor_to_battlefield_mana_value_x_or_less_v1",
                                "instant": True,
                                "target": "creature_to_battlefield",
                                "target_mana_value_max_from_x": True,
                                "convoke": True,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_green_suns_zenith_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Green Sun's Zenith",
                        "severity": "high",
                        "oracle_hash": "gszhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "GreenSunsZenith",
                            "path": "/xmage/GreenSunsZenith.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["SearchLibraryWithLessCMCPutInPlayEffect", "ShuffleSpellEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "tutor",
                                "battle_model_scope": "green_creature_tutor_to_battlefield_mana_value_x_or_less_then_shuffle_self_v1",
                                "instant": False,
                                "target": "green_creature_to_battlefield",
                                "target_mana_value_max_from_x": True,
                                "shuffle_self_into_library_on_resolution": True,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_whir_of_invention_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Whir of Invention",
                        "severity": "high",
                        "oracle_hash": "whirhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "WhirOfInvention",
                            "path": "/xmage/WhirOfInvention.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["SearchLibraryWithLessCMCPutInPlayEffect"],
                            "ability_classes": ["ImproviseAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "tutor",
                                "battle_model_scope": "improvise_artifact_tutor_to_battlefield_mana_value_x_or_less_v1",
                                "instant": True,
                                "target": "artifact_to_battlefield",
                                "target_mana_value_max_from_x": True,
                                "improvise": True,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_natures_rhythm_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Nature's Rhythm",
                        "severity": "high",
                        "oracle_hash": "rhythmhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "NaturesRhythm",
                            "path": "/xmage/NaturesRhythm.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["SearchLibraryPutInPlayEffect"],
                            "ability_classes": ["HarmonizeAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "tutor",
                                "battle_model_scope": "creature_tutor_to_battlefield_mana_value_x_or_less_harmonize_v1",
                                "instant": False,
                                "target": "creature_to_battlefield",
                                "target_mana_value_max_from_x": True,
                                "harmonize": True,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_double_vision_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Double Vision",
                        "severity": "high",
                        "oracle_hash": "doublevisionhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "DoubleVision",
                            "path": "/xmage/DoubleVision.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["CopyTargetStackObjectEffect"],
                            "ability_classes": ["DoubleVisionCopyTriggeredAbility", "SpellCastControllerTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "copy_spell",
                                "battle_model_scope": "first_instant_sorcery_cast_each_turn_copy_own_spell_v1",
                                "trigger": "instant_sorcery_cast",
                                "trigger_effect": "copy_spell",
                                "target": "own_instant_or_sorcery_on_stack",
                                "may_choose_new_targets": True,
                                "choose_new_targets_status": "may",
                                "trigger_first_instant_or_sorcery_each_turn": True,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_swarm_intelligence_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Swarm Intelligence",
                        "severity": "high",
                        "oracle_hash": "swarmhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "SwarmIntelligence",
                            "path": "/xmage/SwarmIntelligence.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["CopyTargetStackObjectEffect"],
                            "ability_classes": ["SpellCastControllerTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "copy_spell",
                                "battle_model_scope": "instant_sorcery_cast_copy_own_spell_v1",
                                "trigger": "instant_sorcery_cast",
                                "trigger_effect": "copy_spell",
                                "target": "own_instant_or_sorcery_on_stack",
                                "may_choose_new_targets": True,
                                "choose_new_targets_status": "may",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_pyromancer_ascension_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Pyromancer Ascension",
                        "severity": "high",
                        "oracle_hash": "pyromancerhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "PyromancerAscension",
                            "path": "/xmage/PyromancerAscension.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["AddCountersSourceEffect", "CopyTargetStackObjectEffect"],
                            "ability_classes": [
                                "PyromancerAscensionQuestTriggeredAbility",
                                "PyromancerAscensionCopyTriggeredAbility",
                            ],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "copy_spell",
                                "battle_model_scope": "pyromancer_ascension_quest_counter_copy_spell_v1",
                                "trigger": "instant_sorcery_cast",
                                "trigger_effect": "pyromancer_ascension",
                                "target": "own_instant_or_sorcery_on_stack",
                                "may_choose_new_targets": True,
                                "choose_new_targets_status": "may",
                                "quest_counter_on_same_name_in_graveyard": True,
                                "quest_counter_name_match_zone": "graveyard",
                                "quest_counter_threshold_to_copy": 2,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_profound_journey_rebound_recursion_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Profound Journey",
                        "severity": "high",
                        "oracle_hash": "profoundhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "ProfoundJourney",
                            "path": "/xmage/ProfoundJourney.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["ReturnFromGraveyardToBattlefieldTargetEffect"],
                            "ability_classes": ["ReboundAbility"],
                            "target_classes": ["TargetCardInYourGraveyard"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "recursion",
                                "battle_model_scope": "return_target_permanent_from_graveyard_to_battlefield_rebound_v1",
                                "target": "permanent",
                                "target_zone": "graveyard",
                                "target_controller": "self",
                                "destination": "battlefield",
                                "count": 1,
                                "rebound": True,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_and_generator_mark_fury_storm_copy_stack_scope_as_batch_safe(self) -> None:
        batch_audit = {
            "cards": [
                {
                    "card_name": "Fury Storm",
                    "severity": "high",
                    "oracle_hash": "furyhash",
                    "status": "ready_for_structured_xmage_pull_review_required",
                    "ready_for_structured_pull": True,
                    "valid_xmage_source": True,
                    "coherence_findings": ["no_active_battle_rule"],
                    "checks": {"focused_test_scenario_count": 1},
                    "xmage": {
                        "class_name": "FuryStorm",
                        "path": "/xmage/FuryStorm.java",
                        "types": ["INSTANT"],
                        "effect_classes": ["CopyTargetStackObjectEffect"],
                        "ability_classes": ["CommanderStormAbility"],
                        "cost_classes": [],
                        "primary_effect": {
                            "effect": "copy_spell",
                            "battle_model_scope": "copy_target_instant_or_sorcery_spell_may_choose_new_targets_v1",
                            "instant": True,
                            "target": "instant_or_sorcery_spell",
                            "may_choose_new_targets": True,
                            "choose_new_targets_status": "may",
                            "commander_storm": True,
                        },
                    },
                }
            ]
        }

        family_report = classifier.build_family_report(batch_audit)
        self.assertEqual(family_report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

        generator_report = generator.build_generator_report(batch_audit=batch_audit)
        proposal = generator_report["proposals"][0]
        self.assertTrue(proposal["safe_for_batch_pg_package"])
        self.assertEqual(proposal["proposal_status"], "batch_pg_candidate_after_precheck")
        self.assertEqual(proposal["deck_role_json"]["category"], "combo_value")
        self.assertEqual(proposal["deck_role_json"]["effect"], "copy_spell")

    def test_classifier_marks_candelabra_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Candelabra of Tawnos",
                        "severity": "high",
                        "oracle_hash": "candelabrahash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "CandelabraOfTawnos",
                            "path": "/xmage/CandelabraOfTawnos.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": ["UntapTargetEffect"],
                            "ability_classes": ["SimpleActivatedAbility"],
                            "cost_classes": ["TapSourceCost"],
                            "primary_effect": {
                                "effect": "untap_land_engine",
                                "battle_model_scope": "x_tap_untap_x_lands_v1",
                                "activated_untap_lands_for_mana_unlock": True,
                                "activation_requires_tap": True,
                                "activation_cost_generic_from_x": True,
                                "untap_target_land_count_from_x": True,
                                "untap_target_land_restriction": "land",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_earthcraft_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Earthcraft",
                        "severity": "high",
                        "oracle_hash": "earthcrafthash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "Earthcraft",
                            "path": "/xmage/Earthcraft.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["UntapTargetEffect"],
                            "ability_classes": ["SimpleActivatedAbility"],
                            "cost_classes": ["TapTargetCost"],
                            "primary_effect": {
                                "effect": "untap_land_engine",
                                "battle_model_scope": "tap_untapped_creature_untap_target_basic_land_v1",
                                "activated_untap_lands_for_mana_unlock": True,
                                "activation_taps_untapped_creature_you_control": True,
                                "untap_target_land_count": 1,
                                "untap_target_land_restriction": "land",
                                "untap_target_land_basic_only": True,
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_magus_of_the_candelabra_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Magus of the Candelabra",
                        "severity": "high",
                        "oracle_hash": "magushash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "MagusOfTheCandelabra",
                            "path": "/xmage/MagusOfTheCandelabra.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["UntapTargetEffect"],
                            "ability_classes": ["SimpleActivatedAbility"],
                            "cost_classes": ["TapSourceCost"],
                            "primary_effect": {
                                "effect": "untap_land_engine",
                                "battle_model_scope": "creature_x_tap_untap_x_lands_v1",
                                "power": 1,
                                "toughness": 2,
                                "activated_untap_lands_for_mana_unlock": True,
                                "activation_requires_tap": True,
                                "activation_cost_generic_from_x": True,
                                "untap_target_land_count_from_x": True,
                                "untap_target_land_restriction": "land",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_oboro_breezecaller_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Oboro Breezecaller",
                        "severity": "high",
                        "oracle_hash": "oborohash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "OboroBreezecaller",
                            "path": "/xmage/OboroBreezecaller.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["UntapTargetEffect"],
                            "ability_classes": ["FlyingAbility", "SimpleActivatedAbility"],
                            "cost_classes": ["GenericManaCost", "ReturnToHandChosenControlledPermanentCost"],
                            "primary_effect": {
                                "effect": "untap_land_engine",
                                "battle_model_scope": "pay_two_return_land_untap_target_land_v1",
                                "power": 1,
                                "toughness": 1,
                                "flying": True,
                                "activated_untap_lands_for_mana_unlock": True,
                                "activation_cost_generic": 2,
                                "activation_returns_land_to_hand": True,
                                "untap_target_land_count": 1,
                                "untap_target_land_restriction": "land",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_final_fortune_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Final Fortune",
                        "severity": "high",
                        "oracle_hash": "finalfortunehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "FinalFortune",
                            "path": "/xmage/FinalFortune.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["AddExtraTurnControllerEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "extra_turn",
                                "battle_model_scope": "single_extra_turn_then_lose_game_v1",
                                "instant": True,
                                "turns": 1,
                                "lose_after_extra_turn": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "extra_turn_spell")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_last_chance_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Last Chance",
                        "severity": "high",
                        "oracle_hash": "lastchancehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "LastChance",
                            "path": "/xmage/LastChance.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["AddExtraTurnControllerEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "extra_turn",
                                "battle_model_scope": "single_extra_turn_then_lose_game_v1",
                                "instant": False,
                                "turns": 1,
                                "lose_after_extra_turn": True,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "extra_turn_spell")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_ancestral_memories_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Ancestral Memories",
                        "severity": "high",
                        "oracle_hash": "ancestralmemorieshash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "AncestralMemories",
                            "path": "/xmage/AncestralMemories.java",
                            "types": ["SORCERY"],
                            "effect_classes": ["LookLibraryAndPickControllerEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "dig_to_hand",
                                "battle_model_scope": "look_top_n_pick_m_to_hand_rest_graveyard_v1",
                                "instant": False,
                                "look_count": 7,
                                "pick_count": 2,
                                "selection_destination": "hand",
                                "remainder_destination": "graveyard",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "dig_spell")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_scattered_thoughts_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Scattered Thoughts",
                        "severity": "high",
                        "oracle_hash": "scatteredthoughtshash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "ScatteredThoughts",
                            "path": "/xmage/ScatteredThoughts.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["LookLibraryAndPickControllerEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "dig_to_hand",
                                "battle_model_scope": "look_top_n_pick_m_to_hand_rest_graveyard_v1",
                                "instant": True,
                                "look_count": 4,
                                "pick_count": 2,
                                "selection_destination": "hand",
                                "remainder_destination": "graveyard",
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "dig_spell")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_fact_or_fiction_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Fact or Fiction",
                        "severity": "high",
                        "oracle_hash": "factorfictionhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "FactOrFiction",
                            "path": "/xmage/FactOrFiction.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["RevealAndSeparatePilesEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "pile_selection_draw",
                                "battle_model_scope": "reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1",
                                "instant": True,
                                "look_count": 5,
                                "splitter": "opponent",
                                "chooser": "controller",
                                "selection_destination": "hand",
                                "remainder_destination": "graveyard",
                                "pile_count": 2,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "pile_selection_spell")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_steam_augury_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Steam Augury",
                        "severity": "high",
                        "oracle_hash": "steamauguryhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "SteamAugury",
                            "path": "/xmage/SteamAugury.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["RevealAndSeparatePilesEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "pile_selection_draw",
                                "battle_model_scope": "reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1",
                                "instant": True,
                                "look_count": 5,
                                "splitter": "controller",
                                "chooser": "opponent",
                                "selection_destination": "hand",
                                "remainder_destination": "graveyard",
                                "pile_count": 2,
                            },
                        },
                    }
                ]
            }
        )

        card = report["cards"][0]
        self.assertEqual(card["family_id"], "pile_selection_spell")
        self.assertEqual(card["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_spellseeker_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Spellseeker",
                        "severity": "high",
                        "oracle_hash": "spellseekerhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "Spellseeker",
                            "path": "/xmage/Spellseeker.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["SearchLibraryPutInHandEffect"],
                            "ability_classes": ["EntersBattlefieldTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "spellseeker_etb_instant_or_sorcery_mana_value_2_or_less_to_hand_v1",
                                "power": 1,
                                "toughness": 1,
                                "etb_tutor_target": "cheap_instant_or_sorcery",
                                "etb_tutor_status": "runtime_library_to_hand",
                            },
                        },
                    }
                ]
            }
        )

        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_trophy_mage_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Trophy Mage",
                        "severity": "high",
                        "oracle_hash": "trophyhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "TrophyMage",
                            "path": "/xmage/TrophyMage.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["SearchLibraryPutInHandEffect"],
                            "ability_classes": ["EntersBattlefieldTriggeredAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "trophy_mage_etb_artifact_mana_value_3_to_hand_v1",
                                "power": 2,
                                "toughness": 2,
                                "etb_tutor_target": "artifact_mana_value_3",
                                "etb_tutor_status": "runtime_library_to_hand",
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

    def test_classifier_marks_bartolome_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Bartolomé del Presidio",
                        "severity": "high",
                        "oracle_hash": "bartolomehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "BartolomeDelPresidio",
                            "path": "/xmage/BartolomeDelPresidio.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["AddCountersSourceEffect"],
                            "ability_classes": ["SimpleActivatedAbility"],
                            "cost_classes": ["SacrificeTargetCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "sacrifice_another_creature_or_artifact_put_plus_one_counter_on_self_v1",
                                "power": 2,
                                "toughness": 1,
                                "activation_cost": "sacrifice_creature_or_artifact",
                                "self_add_plus_one_counter": 1,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_green_mana_dork_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Llanowar Elves",
                        "severity": "high",
                        "oracle_hash": "llanowarhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "LlanowarElves",
                            "path": "/xmage/LlanowarElves.java",
                            "types": ["CREATURE"],
                            "effect_classes": [],
                            "ability_classes": ["GreenManaAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "one_mana_one_one_green_mana_dork_v1",
                                "power": 1,
                                "toughness": 1,
                                "is_mana_source": True,
                                "mana_produced": 1,
                                "produces": "G",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_birds_of_paradise_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Birds of Paradise",
                        "severity": "high",
                        "oracle_hash": "birdshash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "BirdsOfParadise",
                            "path": "/xmage/BirdsOfParadise.java",
                            "types": ["CREATURE"],
                            "effect_classes": [],
                            "ability_classes": ["AnyColorManaAbility", "FlyingAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "one_mana_zero_one_flying_any_color_mana_dork_v1",
                                "power": 0,
                                "toughness": 1,
                                "flying": True,
                                "is_mana_source": True,
                                "mana_produced": 1,
                                "produces": "WUBRG",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_exalted_tricolor_mana_dork_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Noble Hierarch",
                        "severity": "high",
                        "oracle_hash": "noblehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "NobleHierarch",
                            "path": "/xmage/NobleHierarch.java",
                            "types": ["CREATURE"],
                            "effect_classes": [],
                            "ability_classes": ["BlueManaAbility", "ExaltedAbility", "GreenManaAbility", "WhiteManaAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "one_mana_zero_one_exalted_tricolor_mana_dork_v1",
                                "power": 0,
                                "toughness": 1,
                                "exalted": True,
                                "is_mana_source": True,
                                "mana_produced": 1,
                                "produces": "GWU",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_color_diversity_mana_dork_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Bloom Tender",
                        "severity": "high",
                        "oracle_hash": "bloomhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "BloomTender",
                            "path": "/xmage/BloomTender.java",
                            "types": ["CREATURE"],
                            "effect_classes": [],
                            "ability_classes": ["AddEachControlledColorManaAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "one_one_color_diversity_mana_dork_v1",
                                "power": 1,
                                "toughness": 1,
                                "is_mana_source": True,
                                "mana_produced_from_colors_among_permanents": True,
                                "mana_colors_from_controlled_permanents": True,
                                "produces": "WUBRG",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_any_color_rock_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Relic of Legends",
                        "severity": "high",
                        "oracle_hash": "relichash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "RelicOfLegends",
                            "path": "/xmage/RelicOfLegends.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": [],
                            "ability_classes": ["AnyColorManaAbility"],
                            "cost_classes": ["TapTargetCost"],
                            "primary_effect": {
                                "effect": "ramp_permanent",
                                "battle_model_scope": "one_any_color_mana_rock_v1",
                                "mana_produced": 1,
                                "produces": "WUBRG",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_support_any_color_rock_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Springleaf Drum",
                        "severity": "high",
                        "oracle_hash": "drumhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "SpringleafDrum",
                            "path": "/xmage/SpringleafDrum.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": [],
                            "ability_classes": ["AnyColorManaAbility"],
                            "cost_classes": ["TapTargetCost"],
                            "primary_effect": {
                                "effect": "ramp_permanent",
                                "battle_model_scope": "creature_support_any_color_mana_rock_v1",
                                "mana_produced": 1,
                                "produces": "WUBRG",
                                "mana_source_requires_untapped_creature": True,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_talisman_pain_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Talisman of Curiosity",
                        "severity": "high",
                        "oracle_hash": "talismanhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "TalismanOfCuriosity",
                            "path": "/xmage/TalismanOfCuriosity.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": ["DamageControllerEffect"],
                            "ability_classes": ["BlueManaAbility", "ColorlessManaAbility", "GreenManaAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "ramp_permanent",
                                "battle_model_scope": "pain_talisman_color_pair_partial_v1",
                                "mana_produced": 1,
                                "produces": "CUG",
                                "life_for_colored_mana": 1,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_black_pain_mana_dork_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Elves of Deep Shadow",
                        "severity": "high",
                        "oracle_hash": "elvesshadowhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "ElvesOfDeepShadow",
                            "path": "/xmage/ElvesOfDeepShadow.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["DamageControllerEffect"],
                            "ability_classes": ["SimpleManaAbility"],
                            "cost_classes": ["TapSourceCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "one_mana_one_one_black_pain_mana_dork_v1",
                                "power": 1,
                                "toughness": 1,
                                "is_mana_source": True,
                                "mana_produced": 1,
                                "produces": "B",
                                "damage_on_tap": 1,
                                "tap_damage_status": "annotation_only",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_colorless_or_any_color_pain_land_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Tarnished Citadel",
                        "severity": "high",
                        "oracle_hash": "citadelhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "TarnishedCitadel",
                            "path": "/xmage/TarnishedCitadel.java",
                            "types": ["LAND"],
                            "effect_classes": ["DamageControllerEffect"],
                            "ability_classes": ["AnyColorManaAbility", "SimpleManaAbility"],
                            "cost_classes": ["TapSourceCost"],
                            "primary_effect": {
                                "effect": "land",
                                "battle_model_scope": "colorless_or_any_color_pain_land_v1",
                                "mana_produced": 1,
                                "produces": "CWUBRG",
                                "life_for_colored_mana": 3,
                                "life_loss_on_colored_mana_status": "annotation_only",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_sol_ring_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Sol Ring",
                        "severity": "high",
                        "oracle_hash": "solringhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "SolRing",
                            "path": "/xmage/SolRing.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": [],
                            "ability_classes": ["SimpleManaAbility"],
                            "cost_classes": ["TapSourceCost"],
                            "primary_effect": {
                                "effect": "ramp_permanent",
                                "battle_model_scope": "two_colorless_mana_rock_v1",
                                "mana_produced": 2,
                                "produces": "C",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_grim_monolith_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Grim Monolith",
                        "severity": "high",
                        "oracle_hash": "grimhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "GrimMonolith",
                            "path": "/xmage/GrimMonolith.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": ["DontUntapInControllersUntapStepSourceEffect", "UntapSourceEffect"],
                            "ability_classes": ["SimpleActivatedAbility", "SimpleManaAbility", "SimpleStaticAbility"],
                            "cost_classes": ["TapSourceCost"],
                            "primary_effect": {
                                "effect": "ramp_permanent",
                                "battle_model_scope": "three_colorless_monolith_mana_rock_v1",
                                "mana_produced": 3,
                                "produces": "C",
                                "does_not_untap_in_untap_step": True,
                                "activated_untap_cost_generic": 4,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_basalt_monolith_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Basalt Monolith",
                        "severity": "high",
                        "oracle_hash": "basalthash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "BasaltMonolith",
                            "path": "/xmage/BasaltMonolith.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": ["DontUntapInControllersUntapStepSourceEffect", "UntapSourceEffect"],
                            "ability_classes": ["SimpleActivatedAbility", "SimpleManaAbility", "SimpleStaticAbility"],
                            "cost_classes": ["GenericManaCost", "TapSourceCost"],
                            "primary_effect": {
                                "effect": "ramp_permanent",
                                "battle_model_scope": "three_colorless_monolith_mana_rock_v1",
                                "mana_produced": 3,
                                "produces": "C",
                                "does_not_untap_in_untap_step": True,
                                "activated_untap_cost_generic": 3,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_generator_marks_creature_mana_source_role_as_ramp(self) -> None:
        report = generator.build_generator_report(
            batch_audit={
                "cards": [
                    {
                        "card_name": "Circle of Dreams Druid",
                        "severity": "high",
                        "oracle_hash": "circlehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "CircleOfDreamsDruid",
                            "path": "/xmage/CircleOfDreamsDruid.java",
                            "types": ["CREATURE"],
                            "effect_classes": [],
                            "ability_classes": ["DynamicManaAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "two_one_green_per_creature_mana_dork_v1",
                                "power": 2,
                                "toughness": 1,
                                "is_mana_source": True,
                                "mana_produced_from_controlled_creatures": True,
                                "produces": "G",
                            },
                        },
                    }
                ]
            },
            external_harvest={
                "cards": [
                    {
                        "card_name": "Circle of Dreams Druid",
                        "candidate_rule": {
                            "oracle_hash": "circlehash",
                            "effect_json": {
                                "effect": "creature",
                                "battle_model_scope": "two_one_green_per_creature_mana_dork_v1",
                                "power": 2,
                                "toughness": 1,
                                "is_mana_source": True,
                                "mana_produced_from_controlled_creatures": True,
                                "produces": "G",
                            },
                        },
                        "external_references": {"scryfall": {"mana_cost": "{G}{G}{G}"}},
                    }
                ]
            },
        )

        proposal = report["proposals"][0]
        self.assertEqual(proposal["deck_role_json"]["category"], "ramp")
        self.assertEqual(proposal["deck_role_json"]["effect"], "ramp_permanent")
        self.assertEqual(proposal["deck_role_json"]["subtype"], "mana_creature")

    def test_classifier_marks_signet_filter_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Izzet Signet",
                        "severity": "high",
                        "oracle_hash": "izzethash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["no_active_battle_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "IzzetSignet",
                            "path": "/xmage/IzzetSignet.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": [],
                            "ability_classes": ["SimpleManaAbility"],
                            "cost_classes": ["GenericManaCost", "TapSourceCost"],
                            "primary_effect": {
                                "effect": "ramp_permanent",
                                "battle_model_scope": "signet_filter_mana_rock_v1",
                                "mana_produced": 1,
                                "produces": "UR",
                                "activation_cost_generic": 1,
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

    def test_classifier_marks_into_the_flood_maw_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Into the Flood Maw",
                        "severity": "high",
                        "oracle_hash": "floodhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "IntoTheFloodMaw",
                            "path": "/xmage/IntoTheFloodMaw.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["ReturnToHandTargetEffect"],
                            "ability_classes": ["GiftAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "bounce",
                                "battle_model_scope": "gift_bounce_opponent_creature_or_nonland_v1",
                                "instant": True,
                                "gift_tapped_fish": True,
                                "target": "opponent_creature",
                                "gift_promised_target": "opponent_nonland_permanent",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_perch_protection_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Perch Protection",
                        "severity": "high",
                        "oracle_hash": "perchhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "PerchProtection",
                            "path": "/xmage/PerchProtection.java",
                            "types": ["INSTANT"],
                            "effect_classes": [
                                "CreateTokenEffect",
                                "ExileSpellEffect",
                                "GainAbilityControllerEffect",
                                "LifeTotalCantChangeControllerEffect",
                                "OneShotEffect",
                                "PerchProtectionEffect",
                            ],
                            "ability_classes": ["GiftAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "composite_resolution",
                                "battle_model_scope": (
                                    "create_four_birds_gift_phase_all_life_lock_protection_exile_self_v1"
                                ),
                                "instant": True,
                                "gift_extra_turn": True,
                                "gift_default_promised": True,
                                "exiles_self": True,
                                "_composite_rule_components": [
                                    {
                                        "effect": "token_maker",
                                        "token_count": 4,
                                        "token_name": "Bird Token",
                                        "token_subtype": "Bird",
                                        "token_colors": ["U"],
                                        "token_power": 2,
                                        "token_toughness": 2,
                                        "token_flying": True,
                                    },
                                    {
                                        "effect": "phase_out",
                                        "gift_required": True,
                                        "phase_out_all_permanents_you_control": True,
                                        "phase_out_includes_lands": True,
                                        "life_total_cant_change": True,
                                        "protection_from_everything": True,
                                    },
                                ],
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_sand_scout_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Sand Scout",
                        "severity": "high",
                        "oracle_hash": "sandhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "SandScout",
                            "path": "/xmage/SandScout.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenEffect", "SearchLibraryPutInPlayEffect"],
                            "ability_classes": [
                                "EntersBattlefieldTriggeredAbility",
                                "PutCardIntoGraveFromAnywhereAllTriggeredAbility",
                            ],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": (
                                    "sand_scout_etb_desert_if_behind_lands_land_graveyard_token_v1"
                                ),
                                "power": 2,
                                "toughness": 2,
                                "etb_land_ramp_count": 1,
                                "etb_land_ramp_condition": "opponent_controls_more_lands",
                                "land_subtypes_any": ["desert"],
                                "land_enters_tapped": True,
                                "land_cards_to_your_graveyard_create_token": True,
                                "land_graveyard_trigger_once_each_turn": True,
                                "land_graveyard_token_name": "Sand Warrior Token",
                                "land_graveyard_token_subtype": "Sand Warrior",
                                "land_graveyard_token_colors": ["R", "G", "W"],
                                "land_graveyard_token_power": 1,
                                "land_graveyard_token_toughness": 1,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_sun_titan_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Sun Titan",
                        "severity": "high",
                        "oracle_hash": "suntitanhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "SunTitan",
                            "path": "/xmage/SunTitan.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["ReturnFromGraveyardToBattlefieldTargetEffect"],
                            "ability_classes": [
                                "EntersBattlefieldOrAttacksSourceTriggeredAbility",
                                "VigilanceAbility",
                            ],
                            "target_classes": ["TargetCardInYourGraveyard"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": (
                                    "sun_titan_etb_attack_return_permanent_mv_lte_3_v1"
                                ),
                                "power": 6,
                                "toughness": 6,
                                "vigilance": True,
                                "etb_recursion_count": 1,
                                "etb_recursion_target": "permanent",
                                "etb_recursion_destination": "battlefield",
                                "etb_recursion_mana_value_max": 3,
                                "attack_trigger_graveyard_recursion": True,
                                "attack_recursion_count": 1,
                                "attack_recursion_target": "permanent",
                                "attack_recursion_destination": "battlefield",
                                "attack_recursion_mana_value_max": 3,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_squee_goblin_nabob_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Squee, Goblin Nabob",
                        "severity": "high",
                        "oracle_hash": "squeehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "SqueeGoblinNabob",
                            "path": "/xmage/SqueeGoblinNabob.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["ReturnSourceFromGraveyardToHandEffect"],
                            "ability_classes": ["BeginningOfUpkeepTriggeredAbility"],
                            "target_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "graveyard_upkeep_return_self_to_hand_v1",
                                "power": 1,
                                "toughness": 1,
                                "legendary": True,
                                "graveyard_upkeep_return_self_to_hand": True,
                                "graveyard_upkeep_optional": True,
                                "graveyard_upkeep_trigger_zone": "graveyard",
                                "graveyard_upkeep_trigger_controller": "source_controller",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_glint_horn_buccaneer_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Glint-Horn Buccaneer",
                        "severity": "high",
                        "oracle_hash": "glinthornhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "GlintHornBuccaneer",
                            "path": "/xmage/GlintHornBuccaneer.java",
                            "types": ["CREATURE"],
                            "effect_classes": [
                                "DamagePlayersEffect",
                                "DrawCardSourceControllerEffect",
                            ],
                            "ability_classes": [
                                "ActivateIfConditionActivatedAbility",
                                "HasteAbility",
                                "TriggeredAbilityImpl",
                            ],
                            "target_classes": [],
                            "cost_classes": ["DiscardCardCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": (
                                    "glint_horn_buccaneer_discard_damage_attack_loot_v1"
                                ),
                                "power": 2,
                                "toughness": 4,
                                "haste": True,
                                "trigger": "controller_discard",
                                "controller_discard_damage_each_opponent": 1,
                                "attacking_activated_discard_draw": True,
                                "attacking_activated_discard_draw_cost": "{1}{R}",
                                "attacking_activated_discard_count": 1,
                                "attacking_activated_draw_count": 1,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_young_pyromancer_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Young Pyromancer",
                        "severity": "high",
                        "oracle_hash": "youngpyromancerhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "YoungPyromancer",
                            "path": "/xmage/YoungPyromancer.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenEffect"],
                            "ability_classes": ["SpellCastControllerTriggeredAbility"],
                            "target_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "token_maker",
                                "battle_model_scope": (
                                    "instant_sorcery_cast_create_1_1_red_elemental_v1"
                                ),
                                "power": 2,
                                "toughness": 1,
                                "trigger": "instant_sorcery_cast",
                                "trigger_effect": "token_maker",
                                "trigger_token_count": 1,
                                "token_count": 1,
                                "token_name": "Elemental Token",
                                "token_subtype": "Elemental",
                                "token_colors": ["R"],
                                "token_power": 1,
                                "token_toughness": 1,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_snap_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Snap",
                        "severity": "high",
                        "oracle_hash": "snaphash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "Snap",
                            "path": "/xmage/Snap.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["ReturnToHandTargetEffect", "UntapLandsEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "bounce",
                                "battle_model_scope": "return_target_creature_then_untap_up_to_two_lands_v1",
                                "instant": True,
                                "target": "creature",
                                "untap_lands_count": 2,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_manamorphose_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Manamorphose",
                        "severity": "high",
                        "oracle_hash": "manahash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "Manamorphose",
                            "path": "/xmage/Manamorphose.java",
                            "types": ["INSTANT"],
                            "effect_classes": ["AddManaInAnyCombinationEffect", "DrawCardSourceControllerEffect"],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "draw_cards",
                                "battle_model_scope": "add_two_mana_any_combination_then_draw_v1",
                                "count": 1,
                                "instant": True,
                                "add_mana_any_combination": 2,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_tinder_wall_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Tinder Wall",
                        "severity": "high",
                        "oracle_hash": "tinderhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "TinderWall",
                            "path": "/xmage/TinderWall.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["DamageTargetEffect"],
                            "ability_classes": ["DefenderAbility", "SimpleActivatedAbility", "SimpleManaAbility"],
                            "cost_classes": ["SacrificeSourceCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "defender_sacrifice_for_rr_or_blocking_damage_v1",
                                "power": 0,
                                "toughness": 3,
                                "defender": True,
                                "sacrifice_for_red_mana": 2,
                                "red_sacrifice_damage_blocking_creature": 2,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_walking_ballista_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Walking Ballista",
                        "severity": "high",
                        "oracle_hash": "ballistahash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "WalkingBallista",
                            "path": "/xmage/WalkingBallista.java",
                            "types": ["ARTIFACT", "CREATURE"],
                            "effect_classes": [
                                "AddCountersSourceEffect",
                                "DamageTargetEffect",
                                "EntersBattlefieldWithXCountersEffect",
                            ],
                            "ability_classes": ["EntersBattlefieldAbility", "SimpleActivatedAbility"],
                            "cost_classes": ["GenericManaCost", "RemoveCountersSourceCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "x_etb_counters_add_counter_or_remove_counter_ping_v1",
                                "power": 0,
                                "toughness": 0,
                                "enters_with_x_plus_one_counters": True,
                                "activated_generic_four_add_plus_one_counter": 1,
                                "activated_remove_plus_one_counter_damage_any_target": 1,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_everflowing_chalice_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Everflowing Chalice",
                        "severity": "high",
                        "oracle_hash": "chalicehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "EverflowingChalice",
                            "path": "/xmage/EverflowingChalice.java",
                            "types": ["ARTIFACT"],
                            "effect_classes": ["AddCountersSourceEffect"],
                            "ability_classes": ["DynamicManaAbility", "EntersBattlefieldAbility", "MultikickerAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "artifact",
                                "battle_model_scope": "multikicker_charge_counter_mana_rock_v1",
                                "multikicker_cost": "{2}",
                                "etb_charge_counters_per_kick": True,
                                "tap_add_colorless_per_charge_counter": True,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_sink_into_stupor_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Sink into Stupor",
                        "severity": "high",
                        "oracle_hash": "sinkhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "SinkIntoStupor",
                            "path": "/xmage/SinkIntoStupor.java",
                            "types": ["INSTANT", "LAND"],
                            "effect_classes": ["ReturnToHandTargetEffect", "TapSourceUnlessPaysEffect"],
                            "ability_classes": ["AsEntersBattlefieldAbility", "BlueManaAbility"],
                            "cost_classes": ["PayLifeCost"],
                            "primary_effect": {
                                "effect": "bounce",
                                "battle_model_scope": "return_target_spell_or_opponent_nonland_permanent_or_tapped_blue_land_v1",
                                "instant": True,
                                "target": "spell_or_opponent_nonland_permanent",
                                "land_side_pay_three_life_else_tapped": True,
                                "land_side_add_mana": "U",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_disciple_of_freyalise_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Disciple of Freyalise",
                        "severity": "high",
                        "oracle_hash": "disciplehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "DiscipleOfFreyalise",
                            "path": "/xmage/DiscipleOfFreyalise.java",
                            "types": ["CREATURE", "LAND"],
                            "effect_classes": [
                                "DiscipleOfFreyaliseEffect",
                                "DrawCardSourceControllerEffect",
                                "GainLifeEffect",
                                "OneShotEffect",
                                "TapSourceUnlessPaysEffect",
                            ],
                            "ability_classes": ["AsEntersBattlefieldAbility", "EntersBattlefieldTriggeredAbility", "GreenManaAbility"],
                            "cost_classes": ["PayLifeCost", "SacrificeTargetCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "etb_sacrifice_another_creature_gain_draw_power_or_tapped_green_land_v1",
                                "power": 3,
                                "toughness": 3,
                                "etb_may_sacrifice_another_creature_gain_life_and_draw_equal_power": True,
                                "land_side_pay_three_life_else_tapped": True,
                                "land_side_add_mana": "G",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_vibrance_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Vibrance",
                        "severity": "high",
                        "oracle_hash": "vibrancehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "Vibrance",
                            "path": "/xmage/Vibrance.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["DamageTargetEffect", "GainLifeEffect", "SearchLibraryPutInHandEffect"],
                            "ability_classes": ["EntersBattlefieldTriggeredAbility", "EvokeAbility"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "evoke_etb_red_damage_or_green_land_tutor_lifegain_v1",
                                "power": 4,
                                "toughness": 4,
                                "evoke_cost": "{R/G}{R/G}",
                                "etb_if_red_red_spent_damage_any_target": 3,
                                "etb_if_green_green_spent_search_land_to_hand": True,
                                "etb_if_green_green_spent_gain_life": 2,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_archdruids_charm_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Archdruid's Charm",
                        "severity": "high",
                        "oracle_hash": "archhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "ArchdruidsCharm",
                            "path": "/xmage/ArchdruidsCharm.java",
                            "types": ["INSTANT"],
                            "effect_classes": [
                                "AddCountersTargetEffect",
                                "DamageWithPowerFromOneToAnotherTargetEffect",
                                "ExileTargetEffect",
                                "SearchEffect",
                                "SearchLibraryPutInHandOrOnBattlefieldEffect",
                            ],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "modal_spell",
                                "battle_model_scope": "search_creature_or_land_or_counter_fight_or_exile_artifact_enchantment_v1",
                                "instant": True,
                                "mode_search_creature_or_land_reveal_put_land_battlefield_tapped_else_hand": True,
                                "mode_put_plus_one_counter_on_controlled_creature_then_fight": True,
                                "mode_exile_target_artifact_or_enchantment": True,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_eldrazi_confluence_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Eldrazi Confluence",
                        "severity": "high",
                        "oracle_hash": "eldraziconfluencehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "EldraziConfluence",
                            "path": "/xmage/EldraziConfluence.java",
                            "types": ["INSTANT"],
                            "effect_classes": [
                                "BoostTargetEffect",
                                "CreateTokenEffect",
                                "ExileTargetEffect",
                                "ExileThenReturnTargetEffect",
                                "PhaseOutTargetEffect",
                                "ProliferateEffect",
                            ],
                            "ability_classes": [],
                            "target_classes": ["TargetCreaturePermanent", "TargetNonlandPermanent"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "modal_spell",
                                "battle_model_scope": "choose_three_pump_blink_tapped_or_create_eldrazi_scion_v1",
                                "instant": True,
                                "modal_choose_count": 3,
                                "modal_may_repeat_modes": True,
                                "mode_target_creature_plus_three_minus_three": True,
                                "mode_blink_target_nonland_permanent_tapped": True,
                                "mode_create_eldrazi_scion": True,
                                "token_name": "Eldrazi Scion Token",
                                "token_subtype": "Eldrazi Scion",
                                "token_power": 1,
                                "token_toughness": 1,
                                "token_colors": [],
                                "token_sacrifice_for_colorless_mana": True,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["family_id"], "modal_spell")
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_eldrazi_confluence_batch_safe_without_target_classes_in_validity_stage(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Eldrazi Confluence",
                        "severity": "high",
                        "oracle_hash": "eldraziconfluencehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 1},
                        "xmage": {
                            "class_name": "EldraziConfluence",
                            "path": "/xmage/EldraziConfluence.java",
                            "types": ["INSTANT"],
                            "effect_classes": [
                                "BoostTargetEffect",
                                "CreateTokenEffect",
                                "ExileTargetEffect",
                                "ExileThenReturnTargetEffect",
                                "PhaseOutTargetEffect",
                                "ProliferateEffect",
                            ],
                            "ability_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "modal_spell",
                                "battle_model_scope": "choose_three_pump_blink_tapped_or_create_eldrazi_scion_v1",
                                "instant": True,
                                "modal_choose_count": 3,
                                "modal_may_repeat_modes": True,
                                "mode_target_creature_plus_three_minus_three": True,
                                "mode_blink_target_nonland_permanent_tapped": True,
                                "mode_create_eldrazi_scion": True,
                                "token_name": "Eldrazi Scion Token",
                                "token_subtype": "Eldrazi Scion",
                                "token_power": 1,
                                "token_toughness": 1,
                                "token_colors": [],
                                "token_sacrifice_for_colorless_mana": True,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_ruthless_technomancer_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Ruthless Technomancer",
                        "severity": "high",
                        "oracle_hash": "technomancerhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "RuthlessTechnomancer",
                            "path": "/xmage/RuthlessTechnomancer.java",
                            "types": ["CREATURE"],
                            "effect_classes": [
                                "OneShotEffect",
                                "ReturnFromGraveyardToBattlefieldTargetEffect",
                                "RuthlessTechnomancerEffect",
                            ],
                            "ability_classes": ["EntersBattlefieldTriggeredAbility", "SimpleActivatedAbility"],
                            "cost_classes": ["SacrificeXTargetCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "etb_sacrifice_another_creature_create_treasures_and_x_artifact_reanimate_v1",
                                "power": 2,
                                "toughness": 4,
                                "etb_may_sacrifice_another_creature_create_treasures_equal_power": True,
                                "activated_cost": "{2}{B}",
                                "activated_sacrifice_x_artifacts_return_creature_with_power_x_or_less": True,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_emperor_of_bones_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Emperor of Bones",
                        "severity": "high",
                        "oracle_hash": "emperorhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "EmperorOfBones",
                            "path": "/xmage/EmperorOfBones.java",
                            "types": ["CREATURE"],
                            "effect_classes": [
                                "EmperorOfBonesEffect",
                                "ExileTargetEffect",
                                "GainAbilityTargetEffect",
                                "SacrificeTargetEffect",
                            ],
                            "ability_classes": [
                                "AdaptAbility",
                                "BeginningOfCombatTriggeredAbility",
                                "OneOrMoreCountersAddedTriggeredAbility",
                            ],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "combat_exile_adapt_finality_reanimate_v1",
                                "power": 2,
                                "toughness": 2,
                                "beginning_of_combat_exile_up_to_one_card_from_graveyard": True,
                                "adapt_cost": "{1}{B}",
                                "adapt_counters": 2,
                                "counters_trigger_reanimate_exiled_creature_with_finality_haste_and_sacrifice_eot": True,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_goldspan_dragon_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Goldspan Dragon",
                        "severity": "high",
                        "oracle_hash": "goldspanhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "GoldspanDragon",
                            "path": "/xmage/GoldspanDragon.java",
                            "types": ["CREATURE"],
                            "effect_classes": ["CreateTokenEffect", "GainAbilityControlledEffect"],
                            "ability_classes": [
                                "FlyingAbility",
                                "HasteAbility",
                                "OrTriggeredAbility",
                                "AttacksTriggeredAbility",
                                "BecomesTargetSourceTriggeredAbility",
                                "SimpleStaticAbility",
                                "SimpleManaAbility",
                            ],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "goldspan_dragon_attack_or_target_treasure_double_mana_v1",
                                "power": 4,
                                "toughness": 4,
                                "flying": True,
                                "haste": True,
                                "attack_or_becomes_target_create_treasure": True,
                                "attack_trigger_create_treasure": True,
                                "becomes_spell_target_create_treasure": True,
                                "treasure_count": 1,
                                "treasure_mana_value": 2,
                                "controlled_treasures_add_two_mana": True,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_surly_badgersaur_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Surly Badgersaur",
                        "severity": "high",
                        "oracle_hash": "surlyhash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "SurlyBadgersaur",
                            "path": "/xmage/SurlyBadgersaur.java",
                            "types": ["CREATURE"],
                            "effect_classes": [
                                "AddCountersSourceEffect",
                                "CreateTokenEffect",
                                "FightTargetSourceEffect",
                            ],
                            "ability_classes": ["DiscardCardControllerTriggeredAbility"],
                            "target_classes": ["TargetPermanent"],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "surly_badgersaur_discard_card_type_triggers_v1",
                                "power": 3,
                                "toughness": 3,
                                "trigger": "controller_discard",
                                "controller_discard_creature_add_plus_one_counter": True,
                                "controller_discard_counter_type": "+1/+1",
                                "controller_discard_counter_count": 1,
                                "controller_discard_land_create_treasure": True,
                                "controller_discard_treasure_count": 1,
                                "controller_discard_noncreature_nonland_fight": True,
                                "controller_discard_fight_target": "up_to_one_creature_you_dont_control",
                                "controller_discard_fight_optional": True,
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_taii_wakeen_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Taii Wakeen, Perfect Shot",
                        "severity": "high",
                        "oracle_hash": "taiihash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 2},
                        "xmage": {
                            "class_name": "TaiiWakeenPerfectShot",
                            "path": "/xmage/TaiiWakeenPerfectShot.java",
                            "types": ["CREATURE"],
                            "effect_classes": [
                                "DrawCardSourceControllerEffect",
                                "TaiiWakeenPerfectShotEffect",
                            ],
                            "ability_classes": [
                                "TaiiWakeenPerfectShotTriggeredAbility",
                                "SimpleActivatedAbility",
                            ],
                            "target_classes": [],
                            "cost_classes": ["TapSourceCost"],
                            "primary_effect": {
                                "effect": "creature",
                                "battle_model_scope": "taii_wakeen_noncombat_damage_equal_toughness_draw_plus_x_v1",
                                "power": 2,
                                "toughness": 3,
                                "trigger": "source_you_control_noncombat_damage_to_creature_equal_toughness",
                                "noncombat_damage_to_creature_equal_toughness_draw": True,
                                "noncombat_damage_equal_toughness_draw_count": 1,
                                "activated_noncombat_damage_plus_x_until_eot": True,
                                "activation_cost_x_generic": True,
                                "activation_requires_tap": True,
                                "damage_modifier_applies_to": "sources_you_control_noncombat_damage",
                                "damage_modifier_duration": "until_end_of_turn",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_classifier_marks_trouble_in_pairs_exact_scope_as_batch_safe(self) -> None:
        report = classifier.build_family_report(
            {
                "cards": [
                    {
                        "card_name": "Trouble in Pairs",
                        "severity": "high",
                        "oracle_hash": "troublehash",
                        "status": "ready_for_structured_xmage_pull_review_required",
                        "ready_for_structured_pull": True,
                        "valid_xmage_source": True,
                        "coherence_findings": ["review_only_or_needs_review_rule"],
                        "checks": {"focused_test_scenario_count": 3},
                        "xmage": {
                            "class_name": "TroubleInPairs",
                            "path": "/xmage/TroubleInPairs.java",
                            "types": ["ENCHANTMENT"],
                            "effect_classes": ["DrawCardSourceControllerEffect"],
                            "ability_classes": [
                                "SkipExtraTurnsAbility",
                                "TroubleInPairsTriggeredAbility",
                            ],
                            "target_classes": [],
                            "cost_classes": [],
                            "primary_effect": {
                                "effect": "draw_engine",
                                "battle_model_scope": "opponent_second_draw_second_spell_two_attackers_draw_v1",
                                "draw_count": 1,
                                "skip_opponent_extra_turns": True,
                                "opponent_attacks_you_with_two_or_more_creatures_draw": True,
                                "opponent_second_card_draw_each_turn": True,
                                "opponent_second_spell_each_turn": True,
                                "trigger": "opponent_second_spell",
                                "tax": 0,
                                "tax_payment_status": "not_applicable",
                            },
                        },
                    }
                ]
            }
        )
        self.assertEqual(report["cards"][0]["family_id"], "draw_engine")
        self.assertEqual(report["cards"][0]["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")


if __name__ == "__main__":
    unittest.main()
