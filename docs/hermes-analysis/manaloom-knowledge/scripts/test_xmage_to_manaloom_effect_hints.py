#!/usr/bin/env python3
from __future__ import annotations

import unittest

import xmage_effect_json_batch_generator as generator
import xmage_semantic_family_classifier as classifier
import xmage_to_manaloom_effect_hints as hints


class XMageToManaLoomEffectHintsTests(unittest.TestCase):
    def test_colorless_land_with_sacrifice_mana_mode_keeps_modes_separate(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "CrystalVein",
                "effect_classes": [],
                "ability_classes": ["ColorlessManaAbility", "SimpleManaAbility"],
                "cost_classes": ["TapSourceCost", "SacrificeSourceCost"],
                "constructor_metadata": {"card_types": ["LAND"]},
                "raw_excerpt": "new SimpleManaAbility(Zone.BATTLEFIELD, Mana.ColorlessMana(2), new TapSourceCost()).addCost(new SacrificeSourceCost());",
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(
            primary["battle_model_scope"],
            "colorless_land_tap_or_tap_sacrifice_two_colorless_mode_v1",
        )
        self.assertTrue(primary["is_mana_source"])
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["default_mana_produced"], 1)
        self.assertTrue(primary["has_sacrifice_mana_mode"])
        self.assertEqual(primary["sacrifice_mana_produced"], 2)
        self.assertEqual(primary["sacrifice_mana_mode_status"], "runtime_required")
        self.assertEqual(
            primary["alternate_mana_modes"],
            [
                {
                    "mode": "tap_sacrifice_for_two_colorless",
                    "produces": "C",
                    "mana_produced": 2,
                    "activation_requires_tap": True,
                    "activation_requires_sacrifice": True,
                    "status": "runtime_required",
                }
            ],
        )
        self.assertEqual(
            result["primary_candidate"]["suggested_tests"],
            [
                "tap land for one colorless mana without sacrificing it",
                "tap and sacrifice land for two colorless mana when the extra mana unlocks a cast",
            ],
        )

    def test_generic_library_search_routes_to_tutor_family(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Intuition",
                "effect_classes": ["SearchEffect"],
                "ability_classes": [],
                "target_classes": ["TargetOpponent", "TargetCardInLibrary"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": "Search your library for any three cards and reveal them.",
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(primary["battle_model_scope"], "xmage_library_search_variant_review_v1")
        self.assertTrue(primary["instant"])

    def test_generic_static_draw_text_routes_to_draw_family(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "TymnaTheWeaver",
                "effect_classes": ["OneShotEffect", "TymnaTheWeaverEffect"],
                "ability_classes": ["BeginningOfPostcombatMainTriggeredAbility"],
                "cost_classes": ["PayLifeCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": "you may pay X life. If you do, draw X cards",
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "draw_engine")
        self.assertEqual(primary["battle_model_scope"], "xmage_draw_card_variant_review_v1")
        self.assertEqual(primary["ability_kind"], "triggered")

    def test_alhammarrets_archive_maps_to_exact_draw_life_replacement_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "AlhammarretsArchive",
                "effect_classes": [
                    "AlhammarretsArchiveReplacementEffect",
                    "GainDoubleLifeReplacementEffect",
                ],
                "ability_classes": ["SimpleStaticAbility"],
                "target_classes": [],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "draw_engine")
        self.assertEqual(
            primary["battle_model_scope"],
            "static_double_life_gain_and_draw_except_first_draw_step_v1",
        )
        self.assertFalse(primary["draw_on_enter"])
        self.assertTrue(primary["life_gain_replacement_double"])
        self.assertEqual(primary["life_gain_multiplier"], 2)
        self.assertTrue(primary["draw_replacement_double_except_first_draw_step"])
        self.assertTrue(primary["draw_replacement_first_draw_step_exception"])

    def test_currency_converter_maps_to_exact_discard_exile_token_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "CurrencyConverter",
                "effect_classes": [
                    "CurrencyConverterExileEffect",
                    "CurrencyConverterTokenEffect",
                    "DrawDiscardControllerEffect",
                    "OneShotEffect",
                ],
                "ability_classes": [
                    "DiscardCardControllerTriggeredAbility",
                    "SimpleActivatedAbility",
                ],
                "target_classes": ["TargetCard", "TargetCardInExile"],
                "cost_classes": ["GenericManaCost", "TapSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": "TreasureToken RogueToken DrawDiscardControllerEffect(1, 1)",
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "draw_engine")
        self.assertEqual(
            primary["battle_model_scope"],
            "currency_converter_discard_exile_draw_discard_token_v1",
        )
        self.assertTrue(primary["controller_discard_may_exile_discarded_card_from_graveyard"])
        self.assertTrue(primary["activated_draw_discard"])
        self.assertEqual(primary["draw_discard_activation_cost_generic"], 2)
        self.assertEqual(primary["token_from_exiled_land"], "treasure")
        self.assertEqual(primary["token_from_exiled_nonland"], "rogue")
        self.assertEqual(primary["token_name"], "Rogue Token")

    def test_unrecognized_xmage_source_stays_manual(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "UnclearCard",
                "effect_classes": ["UnclearCardEffect", "OneShotEffect"],
                "ability_classes": [],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": "Do a very unusual thing that has no supported ManaLoom signal.",
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "external_reference_required_manual_model")

    def test_generic_blink_effect_routes_to_targeted_zone_transition_family(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Ephemerate",
                "effect_classes": ["ExileThenReturnTargetEffect"],
                "ability_classes": ["ReboundAbility"],
                "target_classes": ["TargetCreaturePermanent"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": "Exile target creature you control, then return it to the battlefield under its owner's control.",
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "blink")
        self.assertEqual(primary["battle_model_scope"], "xmage_exile_then_return_target_variant_review_v1")
        self.assertEqual(primary["zone_transition"], "exile_then_return")
        self.assertEqual(primary["destination"], "battlefield")
        self.assertTrue(primary["instant"])

    def test_one_spell_per_turn_restriction_routes_to_passive_family(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "EidolonOfRhetoric",
                "effect_classes": ["CantCastMoreThanOneSpellEffect"],
                "ability_classes": ["SimpleStaticAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT", "CREATURE"]},
            },
            "Each player can't cast more than one spell each turn.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "passive")
        self.assertEqual(primary["battle_model_scope"], "static_one_spell_per_turn_restriction_variant_review_v1")
        self.assertEqual(primary["spell_limit_per_turn"], 1)
        self.assertEqual(primary["restriction_controller_scope"], "each_player")

    def test_cast_as_flash_permission_routes_to_passive_timing_family(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "VedalkenOrrery",
                "effect_classes": ["CastAsThoughItHadFlashAllEffect"],
                "ability_classes": ["SimpleStaticAbility"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
            },
            "You may cast spells as though they had flash.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "passive")
        self.assertEqual(primary["battle_model_scope"], "static_cast_as_flash_permission_variant_review_v1")
        self.assertTrue(primary["grants_cast_as_flash"])

    def test_generic_target_untap_routes_to_targeted_interaction_family(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "VoltaicKey",
                "effect_classes": ["UntapTargetEffect"],
                "ability_classes": ["SimpleActivatedAbility"],
                "target_classes": ["TargetArtifactPermanent"],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
            },
            "{1}, {T}: Untap target artifact.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "untap_target")
        self.assertEqual(primary["battle_model_scope"], "xmage_targeted_untap_variant_review_v1")
        self.assertEqual(primary["untap_target_card_types"], ["artifact"])
        self.assertTrue(primary["activation_requires_tap"])

    def test_dynamic_mana_spell_routes_to_ritual_family(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "ManaGeyser",
                "effect_classes": ["DynamicManaEffect"],
                "ability_classes": [],
                "constructor_metadata": {"card_types": ["SORCERY"]},
            },
            "Add {R} for each tapped land your opponents control.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "ramp_ritual")
        self.assertEqual(primary["battle_model_scope"], "xmage_spell_mana_ritual_variant_review_v1")
        self.assertTrue(primary["dynamic_mana_amount"])
        self.assertEqual(primary["produces"], "R")

    def test_neheb_routes_to_exact_postcombat_life_lost_mana_engine(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "NehebTheEternal",
                "effect_classes": ["DynamicManaEffect"],
                "ability_classes": ["AfflictAbility", "BeginningOfPostcombatMainTriggeredAbility"],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            (
                "Afflict 3. At the beginning of your postcombat main phase, "
                "add {R} for each 1 life your opponents have lost this turn."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "ramp_engine")
        self.assertEqual(
            primary["battle_model_scope"],
            "postcombat_main_add_red_for_opponents_life_lost_this_turn_v1",
        )
        self.assertEqual(primary["trigger"], "beginning_postcombat_main")
        self.assertTrue(primary["opponents_lost_life_this_turn"])
        self.assertEqual(primary["mana_added_per_opponent_life_lost"], 1)
        self.assertEqual(primary["produces"], "R")

    def test_red_utility_land_splits_exact_mana_mode_from_nonmana_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "ShinkaTheBloodsoakedKeep",
                "effect_classes": ["GainAbilityTargetEffect"],
                "ability_classes": ["RedManaAbility", "SimpleActivatedAbility"],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["LAND"]},
            },
            "{T}: Add {R}. {R}, {T}: Target legendary creature gains first strike until end of turn.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(
            primary["battle_model_scope"],
            "land_tap_one_red_mana_nonmana_ability_pending_v1",
        )
        self.assertTrue(primary["is_mana_source"])
        self.assertEqual(primary["produces"], "R")
        self.assertEqual(primary["mana_produced"], 1)
        self.assertTrue(primary["activation_requires_tap"])
        self.assertFalse(primary["activation_requires_sacrifice"])
        self.assertTrue(primary["nonmana_abilities_require_separate_scope"])
        self.assertEqual(primary["nonmana_effect_classes"], ["GainAbilityTargetEffect"])
        self.assertEqual(
            primary["nonmana_abilities_status"],
            "separate_scope_required_before_full_card_promotion",
        )
        self.assertFalse(result["primary_candidate"]["requires_runtime_executor"])

    def test_multi_damage_and_redirect_stack_signals_route_to_families(self) -> None:
        multi = hints.build_effect_hints(
            {
                "xmage_class_name": "Pyrokinesis",
                "effect_classes": ["DamageMultiEffect"],
                "ability_classes": ["AlternativeCostSourceAbility"],
                "target_classes": ["TargetAnyTargetAmount"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
            }
        )["primary_candidate"]["effect_json"]

        redirect = hints.build_effect_hints(
            {
                "xmage_class_name": "Misdirection",
                "effect_classes": ["ChooseNewTargetsTargetEffect"],
                "ability_classes": ["AlternativeCostSourceAbility"],
                "target_classes": ["TargetSpell"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
            }
        )["primary_candidate"]["effect_json"]

        self.assertEqual(multi["effect"], "multi_target_damage")
        self.assertEqual(multi["battle_model_scope"], "xmage_multi_target_damage_variant_review_v1")
        self.assertEqual(redirect["effect"], "redirect_target")
        self.assertEqual(redirect["battle_model_scope"], "xmage_choose_new_targets_variant_review_v1")

    def test_generic_life_gain_routes_to_life_total_family(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "HeroesRemembered",
                "effect_classes": ["GainLifeEffect"],
                "ability_classes": ["SuspendAbility"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": "new GainLifeEffect(20)",
            },
            "You gain 20 life. Suspend 10-{W}.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "life_gain")
        self.assertEqual(primary["battle_model_scope"], "xmage_life_gain_variant_review_v1")
        self.assertEqual(primary["gain_life"], 20)
        self.assertTrue(primary["sorcery"])

    def test_cost_reduction_is_not_labeled_as_mana_ramp(self) -> None:
        entry = {
            "xmage_class_name": "PearlMedallion",
            "effect_classes": ["SpellsCostReductionControllerEffect"],
            "ability_classes": ["SimpleStaticAbility"],
            "target_classes": [],
            "filter_classes": ["FilterCard"],
        }

        result = hints.build_effect_hints(entry, "White spells you cast cost {1} less to cast.")
        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "static_cost_reduction")
        self.assertNotEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["ability_kind"], "static")
        self.assertEqual(primary["cost_reduction_generic"], 1)
        self.assertEqual(primary["applies_to_spell_colors"], ["W"])
        self.assertEqual(primary["cost_reduction_applies_to"], "spells_you_cast")

    def test_cloud_key_maps_to_chosen_card_type_cost_reduction(self) -> None:
        entry = {
            "xmage_class_name": "CloudKey",
            "constructor_metadata": {"card_types": ["ARTIFACT"]},
            "effect_classes": [
                "ChooseCardTypeEffect",
                "SpellsCostReductionAllOfChosenCardTypeEffect",
            ],
            "ability_classes": ["AsEntersBattlefieldAbility", "SimpleStaticAbility"],
            "target_classes": [],
            "cost_classes": [],
            "filter_classes": ["FilterCard"],
        }

        result = hints.build_effect_hints(
            entry,
            (
                "As Cloud Key enters the battlefield, choose artifact, creature, "
                "enchantment, instant, or sorcery. Spells you cast of the chosen "
                "type cost {1} less to cast."
            ),
        )
        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "static_cost_reduction")
        self.assertEqual(primary["battle_model_scope"], "chosen_card_type_cost_reduction_v1")
        self.assertTrue(primary["choose_card_type_on_enter"])
        self.assertEqual(
            primary["chosen_card_type_options"],
            ["artifact", "creature", "enchantment", "instant", "sorcery"],
        )
        self.assertEqual(primary["cost_reduction_applies_to"], "spells_you_cast_of_chosen_card_type")
        self.assertTrue(primary["cost_reduction_uses_chosen_card_type"])
        self.assertEqual(primary["cost_reduction_generic"], 1)

    def test_custom_power_based_cost_reduction_extracts_scarlet_witch_filters(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [],
                "custom_inner_classes": [
                    {
                        "class_name": "TheScarletWitchEffect",
                        "extends": "CostModificationEffectImpl",
                    }
                ],
            },
            "Instant and sorcery spells you cast with mana value 4 or greater cost {X} less to cast, where X is this creature's power. CardUtil.reduceCost(abilityToModify, power);",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "static_cost_reduction")
        self.assertEqual(
            primary["battle_model_scope"],
            "static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1",
        )
        self.assertEqual(primary["cost_reduction_amount_source"], "source_power")
        self.assertEqual(primary["applies_to_card_types"], ["instant", "sorcery"])
        self.assertEqual(primary["minimum_mana_value"], 4)
        self.assertNotIn("cost_reduction_generic", primary)
        self.assertIn(
            "source power",
            result["primary_candidate"]["suggested_tests"][0],
        )

    def test_training_grounds_is_scoped_as_activated_ability_cost_reduction(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SpellsCostReductionControllerEffect"],
                "ability_classes": ["SimpleStaticAbility"],
            },
            "Activated abilities of creatures you control cost {2} less to activate. This effect can't reduce the mana in that cost to less than one mana.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "static_cost_reduction")
        self.assertEqual(
            primary["battle_model_scope"],
            "static_activated_ability_cost_reduction_variant_v1",
        )
        self.assertEqual(
            primary["cost_reduction_applies_to"],
            "activated_abilities_of_creatures_you_control",
        )
        self.assertEqual(primary["cost_reduction_minimum_total_mana"], 1)

    def test_dargo_is_scoped_as_variable_self_spell_cost_reduction(self) -> None:
        result = hints.build_effect_hints(
            {
                "custom_inner_classes": [
                    {"class_name": "DargoCostReductionEffect", "extends": "CostModificationEffectImpl"}
                ],
            },
            "This spell costs {2} less to cast for each artifact or creature you've sacrificed this turn.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "static_cost_reduction")
        self.assertEqual(
            primary["battle_model_scope"],
            "static_variable_self_spell_cost_reduction_variant_v1",
        )
        self.assertEqual(primary["cost_reduction_applies_to"], "this_spell")
        self.assertEqual(
            primary["cost_reduction_amount_source"],
            "sacrificed_artifact_or_creature_count_this_turn",
        )

    def test_dargo_full_oracle_keeps_variable_self_spell_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "custom_inner_classes": [
                    {"class_name": "DargoCostReductionEffect", "extends": "CostModificationEffectImpl"}
                ],
            },
            "As an additional cost to cast this spell, you may sacrifice any number of artifacts and/or creatures. This spell costs {2} less to cast for each permanent sacrificed this way and {2} less to cast for each other artifact or creature you've sacrificed this turn.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(
            primary["battle_model_scope"],
            "static_variable_self_spell_cost_reduction_variant_v1",
        )
        self.assertTrue(
            primary["cost_reduction_counts_additional_sacrifices_paid_while_casting"]
        )

    def test_tolarian_terror_keeps_self_scope_for_graveyard_instant_sorcery_cost_reduction(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "TolarianTerror",
                "effect_classes": ["SpellCostReductionForEachSourceEffect"],
                "ability_classes": ["SimpleStaticAbility", "WardAbility"],
                "dynamic_value_classes": ["CardsInControllerGraveyardCount"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            "This spell costs {1} less to cast for each instant and sorcery card in your graveyard. Ward {2}.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "static_cost_reduction")
        self.assertEqual(
            primary["battle_model_scope"],
            "static_self_spell_cost_reduction_variant_v1",
        )
        self.assertEqual(primary["cost_reduction_applies_to"], "this_spell")
        self.assertEqual(
            primary["cost_reduction_amount_source"],
            "instant_sorcery_cards_in_your_graveyard_count",
        )
        self.assertEqual(primary["graveyard_count_card_types"], ["instant", "sorcery"])

    def test_bedlam_reveler_maps_to_exact_creature_scope_with_etb_and_graveyard_cost_reduction(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "BedlamReveler",
                "effect_classes": [
                    "DiscardHandControllerEffect",
                    "DrawCardSourceControllerEffect",
                    "SpellCostReductionForEachSourceEffect",
                ],
                "ability_classes": [
                    "EntersBattlefieldTriggeredAbility",
                    "ProwessAbility",
                    "SimpleStaticAbility",
                ],
                "dynamic_value_classes": ["CardsInControllerGraveyardCount"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            "This spell costs {1} less to cast for each instant and sorcery card in your graveyard. Prowess. When Bedlam Reveler enters the battlefield, discard your hand, then draw three cards.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "front_creature_prowess_etb_discard_hand_draw_three_self_instant_sorcery_graveyard_cost_reduction_v1",
        )
        self.assertTrue(primary["is_creature_permanent"])
        self.assertEqual(primary["power"], 3)
        self.assertEqual(primary["toughness"], 4)
        self.assertEqual(primary["keywords"], ["prowess"])
        self.assertEqual(primary["etb_discard_hand_then_draw_count"], 3)
        self.assertEqual(primary["cost_reduction_applies_to"], "this_spell")
        self.assertEqual(primary["cost_reduction_generic"], 1)
        self.assertEqual(
            primary["cost_reduction_amount_source"],
            "instant_sorcery_cards_in_your_graveyard_count",
        )

    def test_primal_amulet_maps_to_exact_cost_reduction_transform_copy_land_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "PrimalAmulet",
                "effect_classes": [
                    "AddCountersSourceEffect",
                    "CopyTargetStackObjectEffect",
                    "CreateDelayedTriggeredAbilityEffect",
                    "OneShotEffect",
                    "SpellsCostReductionControllerEffect",
                ],
                "ability_classes": [
                    "AnyColorManaAbility",
                    "DelayedTriggeredAbility",
                    "SimpleStaticAbility",
                    "SpellCastControllerTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["ARTIFACT", "LAND"]},
                "raw_excerpt": (
                    "new SimpleStaticAbility(new SpellsCostReductionControllerEffect(filter, 1)); "
                    "new SpellCastControllerTriggeredAbility(new AddCountersSourceEffect(CounterType.CHARGE.createInstance()), "
                    "StaticFilters.FILTER_SPELL_AN_INSTANT_OR_SORCERY, false); "
                    "Then if there are four or more charge counters on it, you may remove those counters and transform it. "
                    "new AnyColorManaAbility(); "
                    "When that mana is spent to cast an instant or sorcery spell, copy that spell and you may choose new targets for the copy."
                ),
            },
            "Instant and sorcery spells you cast cost {1} less to cast. "
            "Whenever you cast an instant or sorcery spell, put a charge counter on Primal Amulet. "
            "Then if there are four or more charge counters on it, you may remove those counters and transform it. "
            "Add one mana of any color. When that mana is spent to cast an instant or sorcery spell, "
            "copy that spell and you may choose new targets for the copy.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "static_cost_reduction")
        self.assertEqual(
            primary["battle_model_scope"],
            "artifact_instant_sorcery_cost_reduction_charge_transform_to_any_color_spell_copy_land_v1",
        )
        self.assertEqual(primary["cost_reduction_applies_to"], "instant_sorcery_spells_you_cast")
        self.assertEqual(primary["cost_reduction_generic"], 1)
        self.assertEqual(primary["applies_to_card_types"], ["instant", "sorcery"])
        self.assertEqual(primary["trigger"], "instant_sorcery_cast")
        self.assertEqual(primary["trigger_effect"], "add_named_counter_then_transform")
        self.assertEqual(primary["trigger_counter_type"], "charge")
        self.assertEqual(primary["transform_counter_threshold"], 4)
        self.assertTrue(primary["transform_remove_all_named_counters"])
        self.assertEqual(primary["transform_to"]["name"], "Primal Wellspring")
        self.assertEqual(primary["transform_to"]["effect"], "land")
        self.assertTrue(primary["transform_to"]["copy_when_mana_spent_to_cast_matching_spell"])
        self.assertEqual(primary["transform_to"]["copy_when_mana_spent_card_types"], ["instant", "sorcery"])
        self.assertEqual(primary["transform_to"]["produces"], "WUBRG")

    def test_primal_amulet_exact_scope_survives_truncated_local_excerpt(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "PrimalAmulet",
                "effect_classes": [
                    "AddCountersSourceEffect",
                    "CopyTargetStackObjectEffect",
                    "CreateDelayedTriggeredAbilityEffect",
                    "OneShotEffect",
                    "SpellsCostReductionControllerEffect",
                ],
                "ability_classes": [
                    "AnyColorManaAbility",
                    "DelayedTriggeredAbility",
                    "PrimalWellspringTriggeredAbility",
                    "SimpleStaticAbility",
                    "SpellCastControllerTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["ARTIFACT", "LAND"]},
                "raw_excerpt": (
                    "public final class PrimalAmulet extends TransformingDoubleFacedCard { "
                    "new SimpleStaticAbility(new SpellsCostReductionControllerEffect(filter, 1)); "
                    "new SpellCastControllerTriggeredAbility(new AddCountersSourceEffect(CounterType.CHARGE.createInstance()), "
                    "StaticFilters.FILTER_SPELL_AN_INSTANT_OR_SORCERY, false); "
                    "new CreateDelayedTriggeredAbilityEffect(new PrimalWellspringTriggeredAbility("
                    "new CopyTargetStackObjectEffect(true)));"
                ),
            },
            "",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "static_cost_reduction")
        self.assertEqual(
            primary["battle_model_scope"],
            "artifact_instant_sorcery_cost_reduction_charge_transform_to_any_color_spell_copy_land_v1",
        )

    def test_pyromancers_goggles_maps_to_red_mana_copy_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "PyromancersGoggles",
                "effect_classes": ["CopyTargetStackObjectEffect"],
                "ability_classes": ["PyromancersGogglesTriggeredAbility", "RedManaAbility"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    "Ability ability = new RedManaAbility(); "
                    "Effect effect = new CopyTargetStackObjectEffect(true); "
                    "this.addAbility(new PyromancersGogglesTriggeredAbility(ability.getOriginalId(), effect)); "
                    "setTriggerPhrase(\"When that mana is used to cast a red instant or sorcery spell, \");"
                ),
            },
            "Add {R}. When that mana is used to cast a red instant or sorcery spell, copy that spell and you may choose new targets for the copy.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(
            primary["battle_model_scope"],
            "red_mana_rock_red_instant_sorcery_mana_spent_copy_spell_v1",
        )
        self.assertTrue(primary["is_mana_source"])
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "R")
        self.assertEqual(primary["trigger"], "instant_sorcery_cast")
        self.assertEqual(primary["trigger_effect"], "copy_when_mana_spent")
        self.assertEqual(primary["target"], "own_instant_or_sorcery_on_stack")
        self.assertTrue(primary["copy_when_mana_spent_to_cast_matching_spell"])
        self.assertEqual(primary["copy_when_mana_spent_card_types"], ["instant", "sorcery"])
        self.assertEqual(primary["copy_when_mana_spent_spell_colors"], ["R"])
        self.assertTrue(primary["may_choose_new_targets"])

    def test_palantir_of_orthanc_maps_to_exact_end_step_choice_draw_engine_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "PalantirOfOrthanc",
                "effect_classes": [
                    "AddCountersSourceEffect",
                    "OneShotEffect",
                    "ScryEffect",
                ],
                "ability_classes": [
                    "BeginningOfEndStepTriggeredAbility",
                ],
                "target_classes": ["TargetOpponent"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
            },
            "",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "draw_engine")
        self.assertEqual(
            primary["battle_model_scope"],
            "controller_end_step_add_influence_scry_two_target_opponent_may_draw_else_mill_and_life_loss_v1",
        )
        self.assertEqual(primary["trigger"], "controller_end_step")
        self.assertEqual(
            primary["trigger_effect"],
            "add_named_counter_scry_target_opponent_may_draw_else_mill_life_loss",
        )
        self.assertEqual(primary["trigger_counter_type"], "influence")
        self.assertEqual(primary["trigger_counter_count"], 1)
        self.assertEqual(primary["trigger_scry_count"], 2)
        self.assertEqual(primary["target"], "opponent")
        self.assertEqual(primary["target_opponent_may_have_you_draw_count"], 1)
        self.assertEqual(primary["decline_mill_count_source"], "source_named_counter_count")
        self.assertEqual(primary["decline_mill_counter_type"], "influence")
        self.assertTrue(primary["decline_opponent_life_loss_equals_milled_cards_total_mana_value"])

    def test_galvanoth_maps_to_exact_upkeep_topdeck_free_cast_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Galvanoth",
                "effect_classes": ["OneShotEffect"],
                "ability_classes": ["BeginningOfUpkeepTriggeredAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            (
                "public final class Galvanoth extends CardImpl { "
                "this.addAbility(new BeginningOfUpkeepTriggeredAbility(new GalvanothEffect(), true)); "
                "new MayCastTargetCardEffect(CastManaAdjustment.WITHOUT_PAYING_MANA_COST); "
                "look at the top card of your library. "
                "You may cast it without paying its mana cost if it's an instant or sorcery spell;"
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "controller_upkeep_look_top_instant_or_sorcery_may_cast_without_paying_mana_v1",
        )
        self.assertEqual(primary["power"], 3)
        self.assertEqual(primary["toughness"], 3)
        self.assertEqual(primary["trigger"], "controller_upkeep")
        self.assertEqual(
            primary["trigger_effect"],
            "look_top_card_may_cast_if_instant_or_sorcery",
        )
        self.assertTrue(primary["upkeep_look_top_card"])
        self.assertTrue(primary["upkeep_may_cast_top_instant_or_sorcery_without_paying_mana"])
        self.assertEqual(primary["upkeep_top_library_cast_types"], ["instant", "sorcery"])

    def test_velomachus_lorehold_maps_to_exact_attack_top_seven_free_cast_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "VelomachusLorehold",
                "effect_classes": ["OneShotEffect"],
                "ability_classes": [
                    "AttacksTriggeredAbility",
                    "FlyingAbility",
                    "HasteAbility",
                    "VigilanceAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            (
                "public final class VelomachusLorehold extends CardImpl { "
                "this.addAbility(new AttacksTriggeredAbility(new VelomachusLoreholdEffect(), false)); "
                "Flying Vigilance Haste. "
                "Whenever Velomachus Lorehold attacks, look at the top seven cards of your library. "
                "You may cast an instant or sorcery spell with mana value less than or equal to "
                "Velomachus Lorehold's power from among them without paying its mana cost. "
                "Put the rest on the bottom of your library in a random order."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "attack_top_seven_instant_or_sorcery_lte_power_may_cast_without_paying_mana_v1",
        )
        self.assertEqual(primary["power"], 5)
        self.assertEqual(primary["toughness"], 5)
        self.assertTrue(primary["flying"])
        self.assertTrue(primary["vigilance"])
        self.assertTrue(primary["haste"])
        self.assertEqual(primary["trigger"], "attack")
        self.assertEqual(
            primary["trigger_effect"],
            "look_top_seven_may_cast_instant_or_sorcery_lte_power",
        )
        self.assertEqual(primary["attack_look_top_count"], 7)
        self.assertEqual(primary["attack_top_library_cast_types"], ["instant", "sorcery"])
        self.assertTrue(primary["attack_may_cast_from_looked_cards_without_paying_mana"])
        self.assertEqual(primary["attack_cast_mana_value_max_source"], "source_power")
        self.assertTrue(primary["attack_put_rest_bottom_random"])

    def test_goliath_daydreamer_maps_to_dream_counter_attack_free_cast_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "GoliathDaydreamer",
                "effect_classes": [
                    "GoliathDaydreamerCastEffect",
                    "GoliathDaydreamerExileEffect",
                    "OneShotEffect",
                ],
                "ability_classes": [
                    "AttacksTriggeredAbility",
                    "SpellCastControllerTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            (
                "Whenever you cast an instant or sorcery spell from your hand, exile that card "
                "with a dream counter on it instead of putting it into your graveyard as it resolves. "
                "Whenever this creature attacks, you may cast a spell from among cards you own in exile "
                "with dream counters on them without paying its mana cost. CounterType.DREAM"
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "free_cast")
        self.assertEqual(
            primary["battle_model_scope"],
            "instant_sorcery_from_hand_exile_dream_counter_attack_free_cast_v1",
        )
        self.assertEqual(primary["power"], 4)
        self.assertEqual(primary["toughness"], 4)
        self.assertEqual(primary["spell_cast_from_hand_card_types"], ["instant", "sorcery"])
        self.assertTrue(primary["spell_cast_from_hand_exile_instead_of_graveyard"])
        self.assertEqual(primary["exiled_counter_type"], "dream")
        self.assertTrue(primary["attack_may_cast_owned_exiled_card_with_counter_without_paying_mana"])

    def test_twinflame_tyrant_maps_to_static_damage_modifier_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "TwinflameTyrant",
                "effect_classes": ["TwinflameTyrantEffect"],
                "ability_classes": ["FlyingAbility", "SimpleStaticAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            (
                "If a source you control would deal damage to an opponent or a permanent an opponent controls, "
                "it deals double that damage instead. GameEvent.EventType.DAMAGE_PLAYER "
                "GameEvent.EventType.DAMAGE_PERMANENT"
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "damage_modifier")
        self.assertEqual(
            primary["battle_model_scope"],
            "controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1",
        )
        self.assertEqual(primary["damage_multiplier"], 2)
        self.assertEqual(primary["damage_modifier_applies_to"], "sources_you_control")
        self.assertEqual(primary["damage_modifier_targets"], ["opponents", "opponent_permanents"])

    def test_verge_rangers_maps_to_topdeck_land_play_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "VergeRangers",
                "effect_classes": [
                    "LookAtTopCardOfLibraryAnyTimeEffect",
                    "PlayFromTopOfLibraryEffect",
                    "VergeRangersEffect",
                ],
                "ability_classes": ["FirstStrikeAbility", "SimpleStaticAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            (
                "You may look at the top card of your library any time. "
                "As long as an opponent controls more lands than you, you may play lands from the top of your library."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "topdeck_play")
        self.assertEqual(
            primary["battle_model_scope"],
            "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
        )
        self.assertEqual(primary["keywords"], ["first_strike"])
        self.assertTrue(primary["look_top_library_any_time"])
        self.assertTrue(primary["play_lands_from_top_library"])
        self.assertEqual(primary["play_from_top_condition"], "opponent_controls_more_lands")

    def test_lens_of_clarity_maps_to_visibility_only_topdeck_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "LensOfClarity",
                "effect_classes": [
                    "LookAtTopCardOfLibraryAnyTimeEffect",
                    "LookAtOpponentFaceDownCreaturesAnyTimeEffect",
                ],
                "ability_classes": ["SimpleStaticAbility"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
            },
            "You may look at the top card of your library and at face-down creatures you don't control any time.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "topdeck_play")
        self.assertEqual(
            primary["battle_model_scope"],
            "look_top_library_any_time_and_opponent_face_down_creatures_v1",
        )
        self.assertTrue(primary["look_top_library_any_time"])
        self.assertTrue(primary["look_opponent_face_down_creatures_any_time"])
        self.assertFalse(primary["play_lands_from_top_library"])
        self.assertFalse(primary["alternate_zone_permission"])
        self.assertFalse(primary["may_cast_without_paying_mana_cost"])

    def test_vanquish_the_horde_maps_to_exact_cost_reduced_board_wipe_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "VanquishTheHorde",
                "effect_classes": ["DestroyAllEffect", "SpellCostReductionSourceEffect"],
                "ability_classes": ["SimpleStaticAbility"],
                "dynamic_value_classes": ["PermanentsOnBattlefieldCount"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
            },
            "",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "board_wipe")
        self.assertEqual(
            primary["battle_model_scope"],
            "destroy_all_creatures_cost_reduced_by_creatures_on_battlefield_v1",
        )
        self.assertTrue(primary["destroy_all_creatures"])
        self.assertEqual(primary["cost_reduction_applies_to"], "this_spell")
        self.assertEqual(primary["cost_reduction_amount_source"], "creature_count_on_battlefield")

    def test_explosive_singularity_maps_to_exact_cost_reduced_damage_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "ExplosiveSingularity",
                "effect_classes": ["DamageTargetEffect", "ExplosiveSingularityCostReductionEffect"],
                "ability_classes": ["SimpleStaticAbility", "SpellAbility"],
                "cost_classes": ["TapVariableTargetCost"],
                "target_classes": ["TargetAnyTarget"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "custom_inner_classes": [
                    {"class_name": "ExplosiveSingularityCostReductionEffect", "extends": "CostModificationEffectImpl"}
                ],
            },
            "",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "direct_damage")
        self.assertEqual(
            primary["battle_model_scope"],
            "damage_any_target_cost_reduced_by_tapped_controlled_creatures_v1",
        )
        self.assertEqual(primary["target"], "any_target")
        self.assertEqual(primary["damage"], 10)
        self.assertEqual(
            primary["additional_cost_kind"],
            "tap_any_number_untapped_creatures_you_control",
        )

    def test_oracle_text_can_trigger_gift_destroy_all_hint(self) -> None:
        result = hints.build_effect_hints(
            {"effect_classes": ["DestroyAllEffect"], "ability_classes": [], "condition_classes": []},
            "Gift a card. Destroy all creatures. If the gift was promised, return a creature card.",
        )

        self.assertEqual(
            result["primary_candidate"]["effect_json"]["effect"],
            "gift_destroy_all_creatures_return_own_destroyed_creature",
        )
        self.assertTrue(result["primary_candidate"]["requires_runtime_executor"])

    def test_static_text_from_custom_inner_effect_can_trigger_vow_hint(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["PromiseOfLoyaltyEffect"],
                "counter_types": ["VOW"],
                "custom_inner_classes": [
                    {"class_name": "PromiseOfLoyaltyEffect", "extends": "OneShotEffect"}
                ],
                "raw_excerpt": "staticText = \"each player puts a vow counter on a creature they control and sacrifices the rest\";",
            }
        )

        self.assertEqual(
            result["primary_candidate"]["effect_json"]["effect"],
            "vow_counter_each_player_sacrifice_rest",
        )

    def test_other_turn_any_color_mana_rock_hint(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["UntapSourceDuringEachOtherPlayersUntapStepEffect"],
                "ability_classes": ["AnyColorManaAbility", "SimpleStaticAbility"],
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "other_turn_untapping_any_color_mana_rock")
        self.assertEqual(primary["ability_kind"], "activated")

    def test_victory_chimes_target_player_colorless_hint(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["ManaEffect", "UntapSourceDuringEachOtherPlayersUntapStepEffect", "VictoryChimesManaEffect"],
                "ability_classes": ["SimpleManaAbility", "SimpleStaticAbility"],
                "target_classes": ["TargetPlayer"],
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "other_turn_untapping_target_player_colorless_mana_rock")
        self.assertEqual(primary["target_constraints"]["mana_pool_owner"], "chosen_player")

    def test_modal_mana_rock_extracts_runtime_fields_from_xmage_structure(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DrawCardSourceControllerEffect"],
                "ability_classes": ["SimpleManaAbility", "SimpleActivatedAbility"],
                "cost_classes": ["GenericManaCost", "TapSourceCost", "SacrificeSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": "this.addAbility(new SimpleManaAbility(Zone.BATTLEFIELD, Mana.ColorlessMana(2), new TapSourceCost())); Ability ability = new SimpleActivatedAbility(new DrawCardSourceControllerEffect(2), new GenericManaCost(2)); ability.addCost(new TapSourceCost()); ability.addCost(new SacrificeSourceCost());",
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "mana_rock_with_sacrifice_draw")
        self.assertEqual(primary["battle_model_scope"], "two_mana_rock_self_sacrifice_draw_two_v1")
        self.assertEqual(primary["mana_produced"], 2)
        self.assertEqual(primary["activation_cost_generic"], 2)
        self.assertEqual(primary["draw_on_self_sacrifice"], 2)
        self.assertTrue(primary["activated_self_sacrifice_draw"])

    def test_disciple_of_freyalise_is_not_false_positive_modal_mana_rock(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DiscipleOfFreyaliseEffect", "DrawCardSourceControllerEffect", "GainLifeEffect", "TapSourceUnlessPaysEffect"],
                "ability_classes": ["AsEntersBattlefieldAbility", "EntersBattlefieldTriggeredAbility", "GreenManaAbility"],
                "cost_classes": ["PayLifeCost", "SacrificeTargetCost"],
                "constructor_metadata": {"card_types": ["CREATURE", "LAND"]},
                "raw_excerpt": "this.getRightHalfCard().addAbility(new GreenManaAbility()); SacrificeTargetCost cost = new SacrificeTargetCost(StaticFilters.FILTER_ANOTHER_CREATURE); new GainLifeEffect(xValue).apply(game, source); new DrawCardSourceControllerEffect(xValue).apply(game, source);",
            }
        )

        self.assertNotEqual(
            result["primary_candidate"]["effect_json"]["effect"],
            "mana_rock_with_sacrifice_draw",
        )

    def test_llanowar_elves_maps_to_exact_green_mana_dork_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["GreenManaAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.CREATURE},"{G}"); '
                    "this.power = new MageInt(1); this.toughness = new MageInt(1); "
                    "this.addAbility(new GreenManaAbility());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "one_mana_one_one_green_mana_dork_v1")
        self.assertTrue(primary["is_mana_source"])
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "G")

    def test_avacyns_pilgrim_maps_to_exact_white_mana_dork_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["WhiteManaAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.CREATURE},"{G}"); '
                    "this.power = new MageInt(1); this.toughness = new MageInt(1); "
                    "this.addAbility(new WhiteManaAbility());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "one_mana_one_one_white_mana_dork_v1")
        self.assertTrue(primary["is_mana_source"])
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "W")

    def test_birds_of_paradise_maps_to_exact_any_color_flying_mana_dork_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["AnyColorManaAbility", "FlyingAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.CREATURE},"{G}"); '
                    "this.power = new MageInt(0); this.toughness = new MageInt(1); "
                    "this.addAbility(FlyingAbility.getInstance()); this.addAbility(new AnyColorManaAbility());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "one_mana_zero_one_flying_any_color_mana_dork_v1")
        self.assertTrue(primary["flying"])
        self.assertTrue(primary["is_mana_source"])
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "WUBRG")

    def test_noble_hierarch_maps_to_exalted_tricolor_mana_dork_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": [
                    "BlueManaAbility",
                    "ExaltedAbility",
                    "GreenManaAbility",
                    "WhiteManaAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.CREATURE},"{G}"); '
                    "this.power = new MageInt(0); this.toughness = new MageInt(1); "
                    "this.addAbility(new ExaltedAbility()); this.addAbility(new GreenManaAbility()); "
                    "this.addAbility(new WhiteManaAbility()); this.addAbility(new BlueManaAbility());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "one_mana_zero_one_exalted_tricolor_mana_dork_v1")
        self.assertEqual(primary["produces"], "GWU")
        self.assertTrue(primary["exalted"])
        self.assertTrue(primary["is_mana_source"])

    def test_bloom_tender_maps_to_color_diversity_mana_dork_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["AddEachControlledColorManaAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.CREATURE}, "{1}{G}"); '
                    "this.power = new MageInt(1); this.toughness = new MageInt(1); "
                    "this.addAbility(new AddEachControlledColorManaAbility());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "one_one_color_diversity_mana_dork_v1")
        self.assertTrue(primary["mana_produced_from_colors_among_permanents"])
        self.assertTrue(primary["mana_colors_from_controlled_permanents"])
        self.assertEqual(primary["produces"], "WUBRG")

    def test_circle_of_dreams_druid_maps_to_green_per_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["DynamicManaAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.CREATURE}, "{G}{G}{G}"); '
                    "this.power = new MageInt(2); this.toughness = new MageInt(1); "
                    "new DynamicManaAbility(Mana.GreenMana(1), new PermanentsOnBattlefieldCount(StaticFilters.FILTER_CONTROLLED_CREATURE));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "two_one_green_per_creature_mana_dork_v1")
        self.assertTrue(primary["mana_produced_from_controlled_creatures"])
        self.assertEqual(primary["produces"], "G")

    def test_mountain_maps_to_basic_one_color_land_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Mountain",
                "ability_classes": ["RedManaAbility"],
                "effect_classes": [],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["LAND"], "subtypes": ["MOUNTAIN"]},
                "raw_excerpt": "super(ownerId, setInfo, new RedManaAbility());",
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "land")
        self.assertEqual(primary["battle_model_scope"], "basic_one_color_land_v1")
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "R")
        self.assertEqual(primary["basic_land_types"], ["Mountain"])

    def test_elvish_spirit_guide_maps_to_hand_exile_green_ritual_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "ElvishSpiritGuide",
                "types": ["CREATURE"],
                "ability_classes": ["SimpleManaAbility"],
                "effect_classes": [],
                "cost_classes": ["ExileSourceFromHandCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.CREATURE},"{2}{G}"); '
                    "this.addAbility(new SimpleManaAbility(Zone.HAND, Mana.GreenMana(1), new ExileSourceFromHandCost()));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_ritual")
        self.assertEqual(primary["battle_model_scope"], "hand_exile_add_one_green_mana_ritual_v1")
        self.assertTrue(primary["hand_exile_mana_ability"])
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "G")

    def test_exotic_orchard_maps_to_dynamic_any_color_land_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "ExoticOrchard",
                "types": ["LAND"],
                "ability_classes": ["AnyColorLandsProduceManaAbility"],
                "effect_classes": [],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["LAND"]},
                "raw_excerpt": "this.addAbility(new AnyColorLandsProduceManaAbility(TargetController.OPPONENT));",
            },
            "Tap: Add one mana of any color that a land an opponent controls could produce.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "land")
        self.assertEqual(primary["battle_model_scope"], "any_color_from_opponent_land_production_v1")
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "WUBRG")
        self.assertTrue(primary["opponent_land_color_dependency"])

    def test_relic_of_legends_maps_to_any_color_mana_rock_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["AnyColorManaAbility"],
                "cost_classes": ["TapTargetCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    "this.addAbility(new AnyColorManaAbility()); "
                    "this.addAbility(new AnyColorManaAbility(new TapTargetCost(new TargetControlledPermanent(filter))));"
                ),
            },
            "Add one mana of any color. Tap an untapped legendary creature you control: Add one mana of any color.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["battle_model_scope"], "one_any_color_mana_rock_v1")
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "WUBRG")

    def test_springleaf_drum_maps_to_creature_support_any_color_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["AnyColorManaAbility"],
                "cost_classes": ["TapTargetCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    "Ability ability = new AnyColorManaAbility(); "
                    "ability.addCost(new TapTargetCost(StaticFilters.FILTER_CONTROLLED_UNTAPPED_CREATURE));"
                ),
            },
            "Tap an untapped creature you control: Add one mana of any color.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["battle_model_scope"], "creature_support_any_color_mana_rock_v1")
        self.assertTrue(primary["mana_source_requires_untapped_creature"])
        self.assertEqual(primary["produces"], "WUBRG")

    def test_talisman_of_curiosity_maps_to_pain_talisman_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["BlueManaAbility", "ColorlessManaAbility", "GreenManaAbility"],
                "effect_classes": ["DamageControllerEffect"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    "this.addAbility(new ColorlessManaAbility()); "
                    "Ability ability = new GreenManaAbility(); "
                    "ability.addEffect(new DamageControllerEffect(1)); "
                    "this.addAbility(ability); "
                    "ability = new BlueManaAbility(); "
                    "ability.addEffect(new DamageControllerEffect(1)); "
                    "this.addAbility(ability);"
                ),
            },
            "{T}: Add {C}. {T}: Add {G} or {U}. Talisman of Curiosity deals 1 damage to you.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["battle_model_scope"], "pain_talisman_color_pair_partial_v1")
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "CUG")
        self.assertEqual(primary["life_for_colored_mana"], 1)

    def test_elves_of_deep_shadow_maps_to_black_pain_dork_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["SimpleManaAbility"],
                "effect_classes": ["DamageControllerEffect"],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.CREATURE},"{G}"); '
                    "this.power = new MageInt(1); "
                    "this.toughness = new MageInt(1); "
                    "Ability ability = new SimpleManaAbility(Zone.BATTLEFIELD, Mana.BlackMana(1), new TapSourceCost()); "
                    "ability.addEffect(new DamageControllerEffect(1)); "
                    "this.addAbility(ability);"
                ),
            },
            "{T}: Add {B}. Elves of Deep Shadow deals 1 damage to you.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "one_mana_one_one_black_pain_mana_dork_runtime_v1")
        self.assertTrue(primary["is_mana_source"])
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "B")
        self.assertEqual(primary["damage_on_tap"], 1)
        self.assertEqual(primary["tap_damage_status"], "runtime_executor_v1")
        self.assertEqual(primary["conditional_mana_modes_status"], "runtime_executor_v1")
        self.assertEqual(primary["conditional_mana_modes"][0]["life_loss_on_spend"], 1)

    def test_tarnished_citadel_maps_to_colorless_or_any_color_pain_land_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["AnyColorManaAbility", "SimpleManaAbility"],
                "effect_classes": ["DamageControllerEffect"],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["LAND"]},
                "raw_excerpt": (
                    "this.addAbility(new SimpleManaAbility(Zone.BATTLEFIELD, Mana.ColorlessMana(1), new TapSourceCost())); "
                    "ActivatedManaAbilityImpl ability = new AnyColorManaAbility(new TapSourceCost()); "
                    "ability.addEffect(new DamageControllerEffect(3)); "
                    "this.addAbility(ability);"
                ),
            },
            "{T}: Add {C}. {T}: Add one mana of any color. Tarnished Citadel deals 3 damage to you.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "land")
        self.assertEqual(primary["battle_model_scope"], "colorless_or_any_color_pain_land_runtime_v1")
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "CWUBRG")
        self.assertEqual(primary["life_for_colored_mana"], 3)
        self.assertEqual(primary["life_loss_on_colored_mana_status"], "runtime_executor_v1")
        self.assertEqual(primary["conditional_mana_modes_status"], "runtime_executor_v1")
        self.assertEqual(primary["conditional_mana_modes"][0]["life_loss_on_spend"], 0)
        self.assertEqual(primary["conditional_mana_modes"][1]["life_loss_on_spend"], 3)

    def test_redress_fate_maps_to_all_artifact_enchantment_recursion_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "RedressFate",
                "effect_classes": ["ReturnFromYourGraveyardToBattlefieldAllEffect"],
                "ability_classes": ["MiracleAbility"],
                "filter_classes": ["FilterArtifactOrEnchantmentCard", "FilterCard"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.SORCERY}, "{6}{W}{W}"); '
                    "new ReturnFromYourGraveyardToBattlefieldAllEffect(filter); "
                    'this.addAbility(new MiracleAbility("{3}{W}"));'
                ),
            },
            "Return all artifact and enchantment cards from your graveyard to the battlefield. Miracle {3}{W}.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "recursion")
        self.assertEqual(
            primary["battle_model_scope"],
            "return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_miracle_v1",
        )
        self.assertEqual(primary["target"], "artifact_or_enchantment")
        self.assertEqual(primary["destination"], "battlefield")
        self.assertTrue(primary["return_all_matching"])
        self.assertEqual(primary["target_card_types"], ["artifact", "enchantment"])
        self.assertTrue(primary["miracle"])
        self.assertEqual(primary["miracle_cost"], "{3}{W}")

    def test_brilliant_restoration_maps_to_all_artifact_enchantment_recursion_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "BrilliantRestoration",
                "effect_classes": ["ReturnFromYourGraveyardToBattlefieldAllEffect"],
                "ability_classes": [],
                "filter_classes": ["FilterArtifactOrEnchantmentCard", "FilterCard"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.SORCERY}, "{3}{W}{W}{W}{W}"); '
                    "new ReturnFromYourGraveyardToBattlefieldAllEffect(filter);"
                ),
            },
            "Return all artifact and enchantment cards from your graveyard to the battlefield.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "recursion")
        self.assertEqual(
            primary["battle_model_scope"],
            "return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_v1",
        )
        self.assertEqual(primary["target"], "artifact_or_enchantment")
        self.assertEqual(primary["destination"], "battlefield")
        self.assertTrue(primary["return_all_matching"])
        self.assertEqual(primary["target_card_types"], ["artifact", "enchantment"])
        self.assertNotIn("miracle", primary)

    def test_wake_the_past_maps_to_all_artifact_recursion_haste_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "WakeThePast",
                "effect_classes": ["WakeThePastEffect", "GainAbilityTargetEffect"],
                "ability_classes": [],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.SORCERY}, "{5}{R}{W}"); '
                    "Cards cards = new CardsImpl(player.getGraveyard().getCards(StaticFilters.FILTER_CARD_ARTIFACT, game)); "
                    "player.moveCards(cards, Zone.BATTLEFIELD, source, game); "
                    "game.addEffect(new GainAbilityTargetEffect(HasteAbility.getInstance(), Duration.EndOfTurn));"
                ),
            },
            "Return all artifact cards from your graveyard to the battlefield. They gain haste until end of turn.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "recursion")
        self.assertEqual(
            primary["battle_model_scope"],
            "return_all_artifact_cards_from_graveyard_to_battlefield_haste_eot_v1",
        )
        self.assertEqual(primary["target"], "artifact")
        self.assertEqual(primary["destination"], "battlefield")
        self.assertTrue(primary["return_all_matching"])
        self.assertEqual(primary["target_card_types"], ["artifact"])
        self.assertTrue(primary["grants_haste_until_eot"])

    def test_open_the_vaults_maps_to_all_graveyards_artifact_enchantment_recursion_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "OpenTheVaults",
                "effect_classes": ["OneShotEffect", "OpenTheVaultsEffect"],
                "ability_classes": [],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.SORCERY},"{4}{W}{W}"); '
                    "this.getSpellAbility().addEffect(new OpenTheVaultsEffect());"
                ),
            },
            "Return all artifact and enchantment cards from all graveyards to the battlefield under their owners' control.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "recursion")
        self.assertEqual(
            primary["battle_model_scope"],
            "return_all_artifact_enchantment_cards_from_all_graveyards_to_battlefield_v1",
        )
        self.assertEqual(primary["target"], "artifact_or_enchantment")
        self.assertEqual(primary["target_controller"], "each_player")
        self.assertEqual(primary["destination"], "battlefield")
        self.assertTrue(primary["return_all_matching"])
        self.assertEqual(primary["target_card_types"], ["artifact", "enchantment"])

    def test_roar_of_reclamation_maps_to_all_graveyards_artifact_recursion_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "RoarOfReclamation",
                "effect_classes": ["OneShotEffect", "RoarOfReclamationEffect"],
                "ability_classes": [],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.SORCERY}, "{5}{W}{W}"); '
                    "this.getSpellAbility().addEffect(new RoarOfReclamationEffect());"
                ),
            },
            "Each player returns all artifact cards from their graveyard to the battlefield.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "recursion")
        self.assertEqual(
            primary["battle_model_scope"],
            "return_all_artifact_cards_from_all_graveyards_to_battlefield_v1",
        )
        self.assertEqual(primary["target"], "artifact")
        self.assertEqual(primary["target_controller"], "each_player")
        self.assertEqual(primary["destination"], "battlefield")
        self.assertTrue(primary["return_all_matching"])
        self.assertEqual(primary["target_card_types"], ["artifact"])

    def test_triumphant_reckoning_maps_to_artifact_enchantment_planeswalker_recursion_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "TriumphantReckoning",
                "effect_classes": ["ReturnFromYourGraveyardToBattlefieldAllEffect"],
                "ability_classes": [],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.SORCERY}, "{6}{W}{W}{W}"); '
                    "this.getSpellAbility().addEffect(new ReturnFromYourGraveyardToBattlefieldAllEffect(filter));"
                ),
            },
            "Return all artifact, enchantment, and planeswalker cards from your graveyard to the battlefield.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "recursion")
        self.assertEqual(
            primary["battle_model_scope"],
            "return_all_artifact_enchantment_planeswalker_cards_from_graveyard_to_battlefield_v1",
        )
        self.assertEqual(primary["target"], "artifact_or_enchantment_or_planeswalker")
        self.assertEqual(primary["target_controller"], "self")
        self.assertEqual(primary["destination"], "battlefield")
        self.assertTrue(primary["return_all_matching"])
        self.assertEqual(primary["target_card_types"], ["artifact", "enchantment", "planeswalker"])

    def test_moonsnare_prototype_maps_to_artifact_or_creature_support_colorless_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["ChannelAbility", "ColorlessManaAbility"],
                "effect_classes": ["PutOnTopOrBottomLibraryTargetEffect"],
                "cost_classes": ["TapTargetCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    "Ability ability = new ColorlessManaAbility(); "
                    "ability.addCost(new TapTargetCost(new TargetControlledPermanent(filter))); "
                    "filter.add(Predicates.or(CardType.ARTIFACT.getPredicate(), CardType.CREATURE.getPredicate())); "
                    "this.addAbility(ability); "
                    'ability = new ChannelAbility("{4}{U}", new PutOnTopOrBottomLibraryTargetEffect(true));'
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["battle_model_scope"], "artifact_or_creature_support_colorless_mana_rock_v1")
        self.assertTrue(primary["mana_source_requires_untapped_artifact_or_creature"])
        self.assertEqual(primary["produces"], "C")

    def test_sol_ring_maps_to_exact_two_colorless_mana_rock_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["SimpleManaAbility"],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.ARTIFACT},"{1}"); '
                    "this.addAbility(new SimpleManaAbility(Zone.BATTLEFIELD, Mana.ColorlessMana(2), new TapSourceCost()));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["battle_model_scope"], "two_colorless_mana_rock_v1")
        self.assertEqual(primary["mana_produced"], 2)
        self.assertEqual(primary["produces"], "C")

    def test_grim_monolith_maps_to_exact_monolith_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DontUntapInControllersUntapStepSourceEffect", "UntapSourceEffect"],
                "ability_classes": ["SimpleActivatedAbility", "SimpleManaAbility", "SimpleStaticAbility"],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "xmage_class_name": "GrimMonolith",
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.ARTIFACT},"{2}"); '
                    "this.addAbility(new SimpleStaticAbility(new DontUntapInControllersUntapStepSourceEffect())); "
                    "this.addAbility(new SimpleManaAbility(Zone.BATTLEFIELD, Mana.ColorlessMana(3), new TapSourceCost())); "
                    'this.addAbility(new SimpleActivatedAbility(new UntapSourceEffect(), new ManaCostsImpl<>("{4}")));'
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["battle_model_scope"], "three_colorless_monolith_mana_rock_v1")
        self.assertEqual(primary["mana_produced"], 3)
        self.assertEqual(primary["produces"], "C")
        self.assertTrue(primary["does_not_untap_in_untap_step"])
        self.assertEqual(primary["activated_untap_cost_generic"], 4)

    def test_basalt_monolith_maps_to_exact_monolith_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DontUntapInControllersUntapStepSourceEffect", "UntapSourceEffect"],
                "ability_classes": ["SimpleActivatedAbility", "SimpleManaAbility", "SimpleStaticAbility"],
                "cost_classes": ["GenericManaCost", "TapSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "xmage_class_name": "BasaltMonolith",
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.ARTIFACT},"{3}"); '
                    "this.addAbility(new SimpleStaticAbility(new DontUntapInControllersUntapStepSourceEffect())); "
                    "this.addAbility(new SimpleManaAbility(Zone.BATTLEFIELD, Mana.ColorlessMana(3), new TapSourceCost())); "
                    "this.addAbility(new SimpleActivatedAbility(new UntapSourceEffect(), new GenericManaCost(3)));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["battle_model_scope"], "three_colorless_monolith_mana_rock_v1")
        self.assertEqual(primary["mana_produced"], 3)
        self.assertEqual(primary["produces"], "C")
        self.assertTrue(primary["does_not_untap_in_untap_step"])
        self.assertEqual(primary["activated_untap_cost_generic"], 3)

    def test_izzet_signet_maps_to_exact_signet_filter_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["SimpleManaAbility"],
                "cost_classes": ["GenericManaCost", "TapSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.ARTIFACT},"{2}"); '
                    "Ability ability = new SimpleManaAbility(Zone.BATTLEFIELD, new Mana(0, 1, 0, 1, 0, 0, 0, 0), new GenericManaCost(1)); "
                    "ability.addCost(new TapSourceCost()); this.addAbility(ability);"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["battle_model_scope"], "signet_filter_mana_rock_v1")
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "UR")
        self.assertEqual(primary["activation_cost_generic"], 1)

    def test_simic_signet_maps_to_exact_signet_filter_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["SimpleManaAbility"],
                "cost_classes": ["GenericManaCost", "TapSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.ARTIFACT},"{2}"); '
                    "Ability ability = new SimpleManaAbility(Zone.BATTLEFIELD, new Mana(0, 1, 0, 0, 1, 0, 0, 0), new GenericManaCost(1)); "
                    "ability.addCost(new TapSourceCost()); this.addAbility(ability);"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["battle_model_scope"], "signet_filter_mana_rock_v1")
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "GU")
        self.assertEqual(primary["activation_cost_generic"], 1)

    def test_monument_to_endurance_modal_discard_hint_precedes_generic_token(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CreateTokenEffect", "DrawCardSourceControllerEffect", "LoseLifeOpponentsEffect"],
                "ability_classes": ["DiscardCardControllerTriggeredAbility"],
            }
        )

        self.assertEqual(
            result["primary_candidate"]["effect_json"]["effect"],
            "discard_trigger_modal_draw_treasure_opponent_life_loss",
        )

    def test_surge_to_victory_custom_effect_hint(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["BoostControlledEffect", "SurgeToVictoryCastEffect", "SurgeToVictoryExileEffect"],
                "ability_classes": ["DelayedTriggeredAbility", "SurgeToVictoryTriggeredAbility"],
                "target_classes": ["TargetCardInYourGraveyard"],
            },
            "Exile target instant or sorcery card from your graveyard. Whenever a creature you control deals combat damage to a player this turn, copy the exiled card.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "exile_instant_sorcery_boost_combat_damage_copy_cast")
        self.assertEqual(primary["target_constraints"]["zone"], "graveyard")

    def test_strike_it_rich_maps_to_single_treasure_creation(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CreateTokenEffect", "WinGameSourceControllerEffect"],
                "ability_classes": ["FlashbackAbility"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
            },
            "Create a Treasure token. Flashback {2}{R}.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "treasure_maker")
        self.assertEqual(primary["battle_model_scope"], "single_treasure_creation_v1")
        self.assertEqual(primary["treasure_count"], 1)

    def test_pirates_pillage_maps_to_discard_draw_two_create_two_treasures(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CreateTokenEffect", "DrawCardSourceControllerEffect"],
                "ability_classes": [],
                "constructor_metadata": {"card_types": ["SORCERY"]},
            },
            "As an additional cost to cast this spell, discard a card. Draw two cards and create two Treasure tokens.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "treasure_maker")
        self.assertEqual(primary["battle_model_scope"], "discard_draw_two_create_two_treasures_v1")
        self.assertEqual(primary["draw_count"], 2)
        self.assertEqual(primary["treasure_count"], 2)
        self.assertTrue(primary["requires_discard_card"])

    def test_treasure_vault_maps_to_exact_x_treasure_land_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CreateTokenEffect"],
                "ability_classes": ["ColorlessManaAbility", "SimpleActivatedAbility"],
                "cost_classes": ["TapSourceCost", "SacrificeSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT", "LAND"]},
                "raw_excerpt": "new CreateTokenEffect(new TreasureToken(), GetXValue.instance); new ManaCostsImpl<>(\"{X}{X}\")",
            },
            "{X}{X}, {T}, Sacrifice Treasure Vault: Create X Treasure tokens.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "treasure_maker")
        self.assertEqual(primary["battle_model_scope"], "activated_xx_tap_sacrifice_create_x_treasures_v1")
        self.assertEqual(primary["produces"], "C")
        self.assertEqual(primary["mana_produced"], 1)
        self.assertTrue(primary["activation_requires_tap"])
        self.assertTrue(primary["activation_requires_sacrifice"])
        self.assertTrue(primary["activation_cost_generic_is_x_twice"])
        self.assertEqual(primary["treasure_count_source"], "x_value")
        self.assertEqual(primary["treasure_count_per_x"], 1)

    def test_blood_sun_maps_to_exact_etb_draw_land_suppression_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "BloodSun",
                "effect_classes": ["BloodSunEffect", "DrawCardSourceControllerEffect"],
                "ability_classes": ["EntersBattlefieldTriggeredAbility", "SimpleStaticAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
            },
            "When Blood Sun enters the battlefield, draw a card. All lands lose all abilities except mana abilities.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "passive")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_draw_all_lands_lose_nonmana_abilities_v1",
        )
        self.assertEqual(primary["etb_draw_count"], 1)
        self.assertTrue(primary["suppresses_land_nonmana_abilities"])

    def test_authority_of_the_consuls_maps_to_exact_opponent_creature_tap_lifegain_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "AuthorityOfTheConsuls",
                "effect_classes": ["GainLifeEffect", "PermanentsEnterBattlefieldTappedEffect"],
                "ability_classes": ["EntersBattlefieldOpponentTriggeredAbility", "SimpleStaticAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
            },
            "Creatures your opponents control enter the battlefield tapped. Whenever a creature enters the battlefield under an opponent's control, you gain 1 life.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "passive")
        self.assertEqual(
            primary["battle_model_scope"],
            "opponent_creature_enter_tapped_gain_life_v1",
        )
        self.assertTrue(primary["opponents_creatures_enter_tapped"])
        self.assertEqual(primary["trigger"], "creature_enters_under_opponent_control")
        self.assertEqual(primary["trigger_effect"], "gain_life")
        self.assertEqual(primary["trigger_gain_life"], 1)

    def test_magus_of_the_wheel_maps_to_exact_activated_wheel_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "MagusOfTheWheel",
                "effect_classes": ["DiscardHandAllEffect", "DrawCardAllEffect"],
                "ability_classes": ["SimpleActivatedAbility"],
                "cost_classes": ["TapSourceCost", "SacrificeSourceCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": 'new SimpleActivatedAbility(new DiscardHandAllEffect(), new ManaCostsImpl<>("{1}{R}"));',
            },
            "{1}{R}, {T}, Sacrifice Magus of the Wheel: Each player discards their hand, then draws seven cards.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "activated_tap_sacrifice_self_each_player_discards_hand_draws_seven_v1",
        )
        self.assertEqual(primary["power"], 3)
        self.assertEqual(primary["toughness"], 3)
        self.assertEqual(primary["activation_cost_generic"], 1)
        self.assertEqual(primary["activation_cost_colors"], ["R"])
        self.assertTrue(primary["activation_requires_tap"])
        self.assertTrue(primary["activation_requires_sacrifice"])
        self.assertEqual(primary["activation_cost"], "sacrifice_self")
        self.assertEqual(primary["activated_multiplayer_discard_draw_count"], 7)
        self.assertTrue(primary["wheel_like"])

    def test_patrol_signaler_maps_to_exact_untap_token_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "PatrolSignaler",
                "effect_classes": ["CreateTokenEffect"],
                "ability_classes": ["SimpleActivatedAbility"],
                "cost_classes": ["UntapSourceCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "new CreateTokenEffect(new KithkinSoldierToken()); "
                    "new ManaCostsImpl<>(\"{1}{W}\"); ability.addCost(new UntapSourceCost())"
                ),
            },
            "{1}{W}, {Q}: Create a 1/1 white Kithkin Soldier creature token.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "activated_untap_self_create_1_1_white_kithkin_soldier_token_v1",
        )
        self.assertTrue(primary["is_creature_permanent"])
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 1)
        self.assertTrue(primary["activated_create_token"])
        self.assertTrue(primary["activation_requires_source_tapped"])
        self.assertTrue(primary["activation_uses_untap_symbol"])
        self.assertEqual(primary["activation_cost_generic"], 1)
        self.assertEqual(primary["activation_cost_colors"], ["W"])
        self.assertEqual(primary["token_count"], 1)
        self.assertEqual(primary["token_name"], "Kithkin Soldier Token")
        self.assertEqual(primary["token_subtype"], "Kithkin Soldier")
        self.assertEqual(primary["token_colors"], ["W"])
        self.assertEqual(primary["token_power"], 1)
        self.assertEqual(primary["token_toughness"], 1)

    def test_springheart_nantuko_maps_to_exact_landfall_copy_or_insect_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "SpringheartNantuko",
                "effect_classes": ["CreateTokenCopyTargetEffect", "CreateTokenEffect", "BoostEnchantedEffect"],
                "ability_classes": ["BestowAbility", "LandfallAbility", "SimpleStaticAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT", "CREATURE"]},
            },
            "Bestow {1}{G}. Enchanted creature gets +1/+1. Landfall — Whenever a land you control enters, you may pay {1}{G} if Springheart Nantuko is attached to a creature you control. If you do, create a token that's a copy of that creature. If you didn't create a token this way, create a 1/1 green Insect creature token.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "landfall_optional_pay_copy_attached_creature_else_insect_v1",
        )
        self.assertTrue(primary["is_creature_permanent"])
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 1)
        self.assertTrue(primary["landfall_optional_pay_copy_attached_creature_else_insect"])
        self.assertEqual(primary["landfall_copy_cost"], "{1}{G}")
        self.assertEqual(primary["bestow_cost"], "{1}{G}")
        self.assertEqual(primary["bestow_attached_creature_power_bonus"], 1)
        self.assertEqual(primary["bestow_attached_creature_toughness_bonus"], 1)
        self.assertEqual(primary["token_name"], "Insect Token")
        self.assertEqual(primary["token_subtype"], "Insect")
        self.assertEqual(primary["token_colors"], ["G"])
        self.assertEqual(primary["token_power"], 1)
        self.assertEqual(primary["token_toughness"], 1)

    def test_electroduplicate_maps_to_copy_creature_token(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Electroduplicate",
                "effect_classes": ["CreateTokenCopyTargetEffect"],
                "ability_classes": ["FlashbackAbility"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
            },
            "Create a token that's a copy of target creature you control, except it has haste and \"At the beginning of the end step, sacrifice this token.\"",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "copy_creature_token")
        self.assertEqual(
            primary["battle_model_scope"],
            "copy_target_creature_you_control_haste_sacrifice_end_step_v1",
        )
        self.assertEqual(primary["copy_target_types"], ["creature"])
        self.assertEqual(primary["target_controller"], "own")
        self.assertTrue(primary["token_haste"])
        self.assertTrue(primary["sacrifice_token_at_end_step"])

    def test_adagia_maps_to_station_legendary_artifact_enchantment_copy_token(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "AdagiaWindsweptBastion",
                "effect_classes": ["CreateTokenCopyTargetEffect"],
                "ability_classes": ["StationAbility", "StationLevelAbility", "ActivateAsSorceryActivatedAbility"],
                "target_classes": ["TargetPermanent"],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["LAND"]},
                "raw_excerpt": "new CreateTokenCopyTargetEffect().setPermanentModifier(token -> token.addSuperType(SuperType.LEGENDARY)); TargetPermanent(FILTER_PERMANENT_CONTROLLED_ARTIFACT_OR_ENCHANTMENT)",
            },
            "{3}{W}, {T}: Create a token that's a copy of target artifact or enchantment you control, except it's legendary. Activate only as a sorcery.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "copy_creature_token")
        self.assertEqual(
            primary["battle_model_scope"],
            "station_12_copy_artifact_or_enchantment_you_control_legendary_token_v1",
        )
        self.assertEqual(primary["copy_target_types"], ["artifact", "enchantment"])
        self.assertEqual(primary["target_controller"], "own")
        self.assertTrue(primary["token_legendary"])
        self.assertEqual(primary["station_level_required"], 12)
        self.assertNotIn("runtime_missing_components", primary)

    def test_hazels_brewmaster_maps_to_food_ability_share_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "HazelsBrewmaster",
                "effect_classes": ["ExileTargetEffect", "CreateTokenEffect"],
                "ability_classes": [
                    "EntersBattlefieldOrAttacksSourceTriggeredAbility",
                    "SimpleStaticAbility",
                    "MenaceAbility",
                ],
                "target_classes": ["TargetCardInGraveyard"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "new EntersBattlefieldOrAttacksSourceTriggeredAbility(new ExileTargetEffect().setToSourceExileZone(true)); "
                    "ability.addEffect(new CreateTokenEffect(new FoodToken()).concatBy(\"and\")); "
                    "Foods you control have all activated abilities of all creature cards exiled with Hazel's Brewmaster."
                ),
            },
            "Whenever Hazel's Brewmaster enters or attacks, exile up to one target card from a graveyard and create a Food token. "
            "Foods you control have all activated abilities of all creature cards exiled with Hazel's Brewmaster.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_or_attack_exile_graveyard_card_create_food_share_exiled_creature_activated_abilities_v1",
        )
        self.assertEqual(primary["trigger"], "enters_battlefield_or_attacks")
        self.assertEqual(primary["trigger_effect"], "exile_graveyard_card_create_food")
        self.assertTrue(primary["hazel_brewmaster_etb_or_attack_exile_graveyard_card_create_food"])
        self.assertTrue(primary["create_food_token"])
        self.assertTrue(primary["foods_gain_activated_abilities_from_exiled_creatures"])
        self.assertEqual(primary["target_zone"], "graveyard")
        self.assertEqual(primary["target_count_max"], 1)

    def test_jaxis_maps_to_copy_another_creature_haste_dies_draw_sacrifice(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "JaxisTheTroublemaker",
                "effect_classes": ["CreateTokenCopyTargetEffect", "DrawCardSourceControllerEffect"],
                "ability_classes": ["ActivateAsSorceryActivatedAbility", "DiesSourceTriggeredAbility", "HasteAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            "Create a token that's a copy of another target creature you control. It gains haste and \"When this creature dies, draw a card.\" Sacrifice it at the beginning of the next end step.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "copy_creature_token")
        self.assertEqual(
            primary["battle_model_scope"],
            "copy_target_another_creature_you_control_haste_draw_on_death_sacrifice_end_step_v1",
        )
        self.assertEqual(primary["copy_target_types"], ["creature"])
        self.assertEqual(primary["target_controller"], "own")
        self.assertTrue(primary["exclude_source_from_copy_targets"])
        self.assertTrue(primary["token_haste"])
        self.assertEqual(primary["token_draw_cards_when_this_dies"], 1)
        self.assertTrue(primary["sacrifice_token_at_end_step"])

    def test_rionya_maps_to_dynamic_copy_count_haste_exile_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "RionyaFireDancer",
                "effect_classes": ["CreateTokenCopyTargetEffect"],
                "ability_classes": ["BeginningOfCombatTriggeredAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            "At the beginning of combat on your turn, create X tokens that are copies of another target creature you control, where X is one plus the number of instant and sorcery spells you've cast this turn. They gain haste. Exile them at the beginning of the next end step.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "copy_creature_token")
        self.assertEqual(
            primary["battle_model_scope"],
            "copy_target_another_creature_you_control_x_instant_sorcery_plus_one_haste_exile_end_step_v1",
        )
        self.assertEqual(primary["copy_target_types"], ["creature"])
        self.assertEqual(primary["target_controller"], "own")
        self.assertTrue(primary["exclude_source_from_copy_targets"])
        self.assertEqual(
            primary["token_count_source"],
            "instant_or_sorcery_spells_cast_this_turn_plus_one",
        )
        self.assertTrue(primary["token_haste"])
        self.assertTrue(primary["exile_token_at_end_step"])

    def test_jolly_balloon_man_maps_to_balloon_copy_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "TheJollyBalloonMan",
                "effect_classes": ["CreateTokenCopyTargetEffect"],
                "ability_classes": ["ActivateAsSorceryActivatedAbility", "HasteAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            "Create a token that's a copy of another target creature you control, except it's a 1/1 red Balloon creature in addition to its other colors and types and it has flying and haste. Sacrifice it at the beginning of the next end step.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "copy_creature_token")
        self.assertEqual(
            primary["battle_model_scope"],
            "copy_target_another_creature_you_control_balloon_1_1_red_flying_haste_sacrifice_end_step_v1",
        )
        self.assertEqual(primary["copy_target_types"], ["creature"])
        self.assertEqual(primary["target_controller"], "own")
        self.assertTrue(primary["exclude_source_from_copy_targets"])
        self.assertTrue(primary["force_token_creature"])
        self.assertEqual(primary["token_power"], 1)
        self.assertEqual(primary["token_toughness"], 1)
        self.assertEqual(primary["token_extra_colors"], ["R"])
        self.assertEqual(primary["token_subtype"], "Balloon")
        self.assertTrue(primary["token_flying"])
        self.assertTrue(primary["token_haste"])
        self.assertTrue(primary["sacrifice_token_at_end_step"])

    def test_flash_photography_maps_to_copy_target_permanent(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "FlashPhotography",
                "effect_classes": ["CreateTokenCopyTargetEffect"],
                "ability_classes": ["CastAsThoughItHadFlashIfConditionAbility", "FlashbackAbility"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
            },
            "Create a token that's a copy of target permanent.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "copy_creature_token")
        self.assertEqual(primary["battle_model_scope"], "copy_target_permanent_v1")
        self.assertEqual(primary["copy_target_types"], ["permanent"])
        self.assertEqual(primary["target_controller"], "any")
        self.assertFalse(primary["token_haste"])

    def test_flash_photography_maps_to_copy_target_permanent_from_xmage_structure_only(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "FlashPhotography",
                "effect_classes": ["CreateTokenCopyTargetEffect"],
                "ability_classes": ["CastAsThoughItHadFlashIfConditionAbility", "FlashbackAbility"],
                "condition_classes": ["SourceTargetsPermanentCondition"],
                "target_classes": ["TargetPermanent"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "copy_creature_token")
        self.assertEqual(primary["battle_model_scope"], "copy_target_permanent_v1")
        self.assertEqual(primary["copy_target_types"], ["permanent"])
        self.assertEqual(primary["target_controller"], "any")

    def test_copy_enchantment_maps_to_permanent_copy_etb_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "CopyEnchantment",
                "effect_classes": ["CopyPermanentEffect"],
                "ability_classes": ["EntersBattlefieldAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "this.addAbility(new EntersBattlefieldAbility("
                    "new CopyPermanentEffect(StaticFilters.FILTER_PERMANENT_ENCHANTMENT), true));"
                ),
            },
            "You may have this enchantment enter as a copy of an enchantment on the battlefield.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "copy_permanent_etb")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_copy_target_permanent_with_optional_extra_type_v1",
        )
        self.assertEqual(primary["copy_target_types"], ["enchantment"])
        self.assertEqual(primary["target_controller"], "any")
        self.assertNotIn("copy_additional_types", primary)

    def test_phyrexian_metamorph_maps_to_permanent_copy_etb_scope_with_artifact_addition(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "PhyrexianMetamorph",
                "effect_classes": ["CopyPermanentEffect"],
                "ability_classes": ["EntersBattlefieldAbility"],
                "constructor_metadata": {"card_types": ["ARTIFACT", "CREATURE"]},
                "raw_excerpt": (
                    "new CopyPermanentEffect(StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_CREATURE, applier)"
                    " getText() { return \", except it's an artifact in addition to its other types\"; }"
                ),
            },
            (
                "You may have this creature enter as a copy of any artifact or creature on the battlefield, "
                "except it's an artifact in addition to its other types."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "copy_permanent_etb")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_copy_target_permanent_with_optional_extra_type_v1",
        )
        self.assertEqual(primary["copy_target_types"], ["artifact", "creature"])
        self.assertEqual(primary["copy_additional_types"], ["artifact"])
        self.assertEqual(primary["target_controller"], "any")

    def test_mockingbird_maps_to_copy_applier_modifier_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Mockingbird",
                "effect_classes": ["CopyPermanentEffect", "MockingbirdEffect", "OneShotEffect"],
                "ability_classes": ["EntersBattlefieldAbility", "FlyingAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "CopyPermanentEffect(filter, new CopyApplier() { "
                    "blueprint.addSubType(SubType.BIRD); "
                    "blueprint.getAbilities().add(FlyingAbility.getInstance());"
                ),
            },
            (
                "You may have Mockingbird enter the battlefield as a copy of any creature on the battlefield "
                "with mana value less than or equal to the amount of mana spent to cast Mockingbird, "
                "except it is a Bird in addition to its other types and has flying."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "copy_permanent_etb")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_copy_target_creature_with_copy_applier_modifiers_v1",
        )
        self.assertEqual(primary["copy_target_types"], ["creature"])
        self.assertEqual(primary["target_controller"], "any")
        self.assertEqual(primary["copy_additional_subtypes"], ["Bird"])
        self.assertEqual(primary["copy_granted_keywords"], ["flying"])
        self.assertTrue(primary["copy_target_mana_value_lte_source_mana_value"])

    def test_imposter_mech_maps_to_copy_applier_modifier_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "ImposterMech",
                "effect_classes": ["CopyPermanentEffect"],
                "ability_classes": ["CrewAbility", "EntersBattlefieldAbility"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    "new CopyPermanentEffect(StaticFilters.FILTER_OPPONENTS_PERMANENT_A_CREATURE, applier) "
                    "blueprint.removeAllCardTypes(); blueprint.addCardType(CardType.ARTIFACT); "
                    "blueprint.addSubType(SubType.VEHICLE); blueprint.getAbilities().add(new CrewAbility(3));"
                ),
            },
            (
                "You may have Imposter Mech enter the battlefield as a copy of a creature an opponent controls, "
                "except it's a Vehicle artifact with crew 3 and it loses all other card types."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "copy_permanent_etb")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_copy_target_creature_with_copy_applier_modifiers_v1",
        )
        self.assertEqual(primary["copy_target_types"], ["creature"])
        self.assertEqual(primary["target_controller"], "opponent")
        self.assertEqual(primary["copy_overwrite_types"], ["artifact"])
        self.assertEqual(primary["copy_overwrite_subtypes"], ["Vehicle"])
        self.assertEqual(primary["copy_vehicle_crew_value"], 3)

    def test_clone_legion_maps_to_copy_each_creature_target_player_controls(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "CloneLegion",
                "effect_classes": ["CreateTokenCopyTargetEffect"],
                "ability_classes": [],
                "constructor_metadata": {"card_types": ["SORCERY"]},
            },
            "For each creature target player controls, create a token that's a copy of that creature.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "copy_creature_token")
        self.assertEqual(primary["battle_model_scope"], "copy_each_creature_target_player_controls_v1")
        self.assertEqual(primary["copy_target_types"], ["creature"])
        self.assertEqual(primary["target_controller"], "opponent")
        self.assertTrue(primary["copy_all_matching_targets"])

    def test_lotho_maps_to_second_spell_treasure_engine(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CreateTokenEffect", "LoseLifeSourceControllerEffect"],
                "ability_classes": ["CastSecondSpellTriggeredAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            "Whenever a player casts their second spell each turn, you lose 1 life and create a Treasure token.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "ramp_engine")
        self.assertEqual(
            primary["battle_model_scope"],
            "opponent_second_spell_each_turn_create_treasure_life_loss_v1",
        )
        self.assertEqual(primary["trigger"], "opponent_spell")
        self.assertTrue(primary["opponent_second_spell_each_turn"])
        self.assertEqual(primary["treasure_count"], 1)
        self.assertEqual(primary["controller_loses_life_on_trigger"], 1)

    def test_impulsive_pilferer_maps_to_death_treasure_creature(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CreateTokenEffect"],
                "ability_classes": ["DiesSourceTriggeredAbility", "EncoreAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            "When Impulsive Pilferer dies, create a Treasure token. Encore {3}{R}.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "dies_create_treasure_encore_v1")
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 1)
        self.assertTrue(primary["dies_or_graveyard_from_battlefield_treasure"])
        self.assertEqual(primary["treasure_count"], 1)
        self.assertEqual(primary["encore_cost"], "{3}{R}")

    def test_astral_dragon_maps_to_creature_etb_copy_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "AstralDragon",
                "effect_classes": ["CreateTokenCopyTargetEffect"],
                "ability_classes": ["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            "Flying. When Astral Dragon enters the battlefield, create two tokens that are copies of target noncreature permanent, except they're 3/3 Dragon creatures in addition to their other types, and they have flying.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_copy_target_noncreature_permanent_twice_as_3_3_flying_dragon_v1",
        )
        self.assertEqual(primary["power"], 4)
        self.assertEqual(primary["toughness"], 4)
        self.assertTrue(primary["flying"])
        self.assertEqual(primary["etb_copy_target_types"], ["noncreature_permanent"])
        self.assertEqual(primary["etb_copy_token_count"], 2)
        self.assertTrue(primary["etb_copy_force_creature"])
        self.assertEqual(primary["etb_copy_token_power"], 3)
        self.assertEqual(primary["etb_copy_token_toughness"], 3)
        self.assertTrue(primary["etb_copy_token_flying"])
        self.assertEqual(primary["etb_copy_token_subtype"], "Dragon")

    def test_prized_statue_maps_to_etb_or_dies_treasure_artifact(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CreateTokenEffect"],
                "ability_classes": ["EntersBattlefieldOrDiesSourceTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
            },
            "When this artifact enters or is put into a graveyard from the battlefield, create a Treasure token.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["battle_model_scope"], "artifact_etb_or_dies_create_treasure_v1")
        self.assertEqual(primary["treasure_count"], 1)
        self.assertEqual(primary["enters_treasure"], 1)
        self.assertTrue(primary["dies_or_graveyard_from_battlefield_treasure"])

    def test_natures_claim_maps_to_artifact_or_enchantment_lifegain_removal(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DestroyTargetEffect", "GainLifeTargetControllerEffect"],
                "target_classes": ["TargetPermanent"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new DestroyTargetEffect()); "
                    "this.getSpellAbility().addEffect(new GainLifeTargetControllerEffect(4)); "
                    "this.getSpellAbility().addTarget(new TargetPermanent("
                    "StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_ENCHANTMENT));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "remove_permanent")
        self.assertEqual(primary["battle_model_scope"], "artifact_or_enchantment_removal_lifegain_v1")
        self.assertEqual(primary["target"], "artifact_or_enchantment")
        self.assertEqual(primary["target_controller_gains_life"], 4)
        self.assertTrue(primary["instant"])

    def test_erode_maps_to_exact_creature_or_planeswalker_basic_land_annotation_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "DestroyTargetEffect",
                    "SearchLibraryPutInPlayTargetControllerEffect",
                ],
                "target_classes": ["TargetCreatureOrPlaneswalker"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new DestroyTargetEffect()); "
                    "this.getSpellAbility().addEffect(new SearchLibraryPutInPlayTargetControllerEffect(true)); "
                    "this.getSpellAbility().addTarget(new TargetCreatureOrPlaneswalker());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "remove_permanent")
        self.assertEqual(
            primary["battle_model_scope"],
            "destroy_creature_or_planeswalker_target_controller_basic_land_tapped_annotation_v1",
        )
        self.assertEqual(primary["target"], "creature_or_planeswalker")
        self.assertTrue(primary["target_controller_basic_land_tapped"])
        self.assertEqual(primary["basic_land_compensation_status"], "annotation_only")
        self.assertTrue(primary["instant"])

    def test_sundering_eruption_maps_to_exact_land_destroy_annotation_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "CantBlockAllEffect",
                    "DestroyTargetEffect",
                    "SearchLibraryPutInPlayTargetControllerEffect",
                    "TapSourceUnlessPaysEffect",
                ],
                "ability_classes": ["AsEntersBattlefieldAbility", "RedManaAbility"],
                "target_classes": ["TargetLandPermanent"],
                "constructor_metadata": {"card_types": ["SORCERY", "LAND"]},
                "raw_excerpt": (
                    "this.getLeftHalfCard().getSpellAbility().addTarget(new TargetLandPermanent()); "
                    "this.getLeftHalfCard().getSpellAbility().addEffect(new DestroyTargetEffect()); "
                    "this.getLeftHalfCard().getSpellAbility().addEffect(new SearchLibraryPutInPlayTargetControllerEffect(true)); "
                    "this.getLeftHalfCard().getSpellAbility().addEffect(new CantBlockAllEffect(filter, Duration.EndOfTurn)); "
                    "this.getRightHalfCard().addAbility(new AsEntersBattlefieldAbility(new TapSourceUnlessPaysEffect(new PayLifeCost(3)))); "
                    "this.getRightHalfCard().addAbility(new RedManaAbility());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "remove_permanent")
        self.assertEqual(
            primary["battle_model_scope"],
            "destroy_target_land_target_controller_basic_land_tapped_runtime_nonfliers_cant_block_runtime_v1",
        )
        self.assertEqual(primary["target"], "land")
        self.assertTrue(primary["target_controller_basic_land_tapped"])
        self.assertEqual(primary["basic_land_compensation_status"], "runtime_executor_v1")
        self.assertEqual(primary["cant_block_mode_status"], "runtime_executor_v1")
        self.assertTrue(primary["land_side_pay_three_life_else_tapped"])
        self.assertEqual(primary["land_side_add_mana"], "R")

    def test_star_of_extinction_maps_to_exact_land_destroy_then_damage_wipe_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DamageAllEffect", "DestroyTargetEffect"],
                "filter_classes": ["FilterCreatureOrPlaneswalkerPermanent"],
                "target_classes": ["TargetLandPermanent"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new DestroyTargetEffect()); "
                    "this.getSpellAbility().addEffect(new DamageAllEffect(20, "
                    "new FilterCreatureOrPlaneswalkerPermanent(\"creature and each planeswalker\"))); "
                    "this.getSpellAbility().addTarget(new TargetLandPermanent());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(
            primary["effect"],
            "destroy_target_land_then_damage_all_creatures_and_planeswalkers",
        )
        self.assertEqual(
            primary["battle_model_scope"],
            "destroy_target_land_then_deal_20_to_each_creature_and_planeswalker_v1",
        )
        self.assertEqual(primary["target"], "land")
        self.assertEqual(primary["damage"], 20)
        self.assertEqual(primary["damage_scope"], "each_creature_and_planeswalker")
        self.assertTrue(primary["sorcery"])

    def test_vandalblast_maps_to_exact_artifact_overload_annotation_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DestroyTargetEffect"],
                "ability_classes": ["OverloadAbility"],
                "target_classes": ["TargetPermanent"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    "OverloadAbility.implementOverloadAbility(this, new ManaCostsImpl<>(\"{4}{R}\"), "
                    "new TargetPermanent(FILTER), new DestroyTargetEffect()); "
                    "FILTER.add(TargetController.NOT_YOU.getControllerPredicate());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "remove_permanent")
        self.assertEqual(
            primary["battle_model_scope"],
            "destroy_target_opponent_artifact_or_overload_all_opponent_artifacts_annotation_v1",
        )
        self.assertEqual(primary["target"], "artifact")
        self.assertEqual(primary["target_controller"], "opponent")
        self.assertEqual(primary["overload_cost"], "{4}{R}")
        self.assertEqual(primary["overload_status"], "annotation_only")
        self.assertEqual(primary["overload_target_rewrite"], "target_to_each")
        self.assertTrue(primary["sorcery"])

    def test_agathas_soul_cauldron_maps_to_exact_passive_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "AddCountersTargetEffect",
                    "AgathasSoulCauldronAbilityEffect",
                    "AgathasSoulCauldronExileEffect",
                    "AgathasSoulCauldronManaEffect",
                    "AsThoughManaEffect",
                    "OneShotEffect",
                ],
                "ability_classes": [
                    "AddAbility",
                    "ReflexiveTriggeredAbility",
                    "SimpleActivatedAbility",
                    "SimpleStaticAbility",
                ],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
            },
            (
                "You may spend mana as though it were mana of any color to activate abilities of creatures you control. "
                "Creatures you control with +1/+1 counters on them have all activated abilities of all creature cards exiled with Agatha's Soul Cauldron. "
                "{T}: Exile target card from a graveyard. When a creature card is exiled this way, put a +1/+1 counter on target creature you control."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "passive")
        self.assertEqual(
            primary["battle_model_scope"],
            "graveyard_exile_counter_and_ability_grant_artifact_v1",
        )
        self.assertTrue(primary["mana_as_any_color_for_creature_activations"])
        self.assertTrue(primary["plus_one_counter_creatures_gain_activated_abilities_of_exiled_creatures"])

    def test_necropotence_maps_to_exact_draw_engine_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "ExileTargetEffect",
                    "NecropotenceEffect",
                    "OneShotEffect",
                    "ReturnToHandTargetEffect",
                    "SkipDrawStepEffect",
                ],
                "ability_classes": [
                    "AtTheBeginOfNextEndStepDelayedTriggeredAbility",
                    "NecropotenceTriggeredAbility",
                    "SimpleActivatedAbility",
                    "SimpleStaticAbility",
                ],
                "cost_classes": ["PayLifeCost"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
            },
            (
                "Skip your draw step. Whenever you discard a card, exile that card from your graveyard. "
                "Pay 1 life: Exile the top card of your library face down. Put that card into your hand at the beginning of your next end step."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "draw_engine")
        self.assertEqual(
            primary["battle_model_scope"],
            "skip_draw_discard_exile_pay_life_face_down_draw_next_end_step_v1",
        )
        self.assertTrue(primary["skip_draw_step"])
        self.assertEqual(primary["activated_pay_life"], 1)

    def test_seal_of_primordium_maps_to_sacrifice_self_artifact_or_enchantment_removal(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DestroyTargetEffect"],
                "ability_classes": ["SimpleActivatedAbility"],
                "cost_classes": ["SacrificeSourceCost"],
                "target_classes": ["TargetPermanent"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "Ability ability = new SimpleActivatedAbility(new DestroyTargetEffect(), "
                    "new SacrificeSourceCost()); ability.addTarget(new TargetPermanent("
                    "StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_ENCHANTMENT));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "remove_permanent")
        self.assertEqual(
            primary["battle_model_scope"],
            "activated_sacrifice_self_destroy_artifact_or_enchantment_v1",
        )
        self.assertEqual(primary["target"], "artifact_or_enchantment")
        self.assertEqual(primary["activation_cost"], "sacrifice_self")

    def test_aura_of_silence_maps_to_tax_plus_sacrifice_removal(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DestroyTargetEffect", "SpellsCostIncreasingAllEffect"],
                "ability_classes": ["SimpleActivatedAbility", "SimpleStaticAbility"],
                "cost_classes": ["SacrificeSourceCost"],
                "target_classes": ["TargetPermanent"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "this.addAbility(new SimpleStaticAbility(new SpellsCostIncreasingAllEffect("
                    "2, filter, TargetController.OPPONENT))); "
                    "Ability ability = new SimpleActivatedAbility(new DestroyTargetEffect(), "
                    "new SacrificeSourceCost()); ability.addTarget(new TargetPermanent("
                    "StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_ENCHANTMENT));"
                ),
            },
            "Artifact and enchantment spells your opponents cast cost {2} more to cast. "
            "Sacrifice Aura of Silence: Destroy target artifact or enchantment.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "remove_permanent")
        self.assertEqual(
            primary["battle_model_scope"],
            "aura_of_silence_tax_and_sacrifice_removal_waiver_v1",
        )
        self.assertEqual(primary["target"], "artifact_or_enchantment")
        self.assertEqual(primary["activation_cost"], "sacrifice_self")
        self.assertEqual(primary["taxes_opponent_artifact_enchantment_spells"], 2)

    def test_aura_of_silence_source_text_without_oracle_still_maps_to_tax_plus_sacrifice_removal(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DestroyTargetEffect", "SpellsCostIncreasingAllEffect"],
                "ability_classes": ["SimpleActivatedAbility", "SimpleStaticAbility"],
                "cost_classes": ["SacrificeSourceCost"],
                "target_classes": ["TargetPermanent"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "this.addAbility(new SimpleStaticAbility(new SpellsCostIncreasingAllEffect("
                    "2, filter, TargetController.OPPONENT))); "
                    "Ability ability = new SimpleActivatedAbility(new DestroyTargetEffect(), "
                    "new SacrificeSourceCost()); ability.addTarget(new TargetPermanent("
                    "StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_ENCHANTMENT));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(
            primary["battle_model_scope"],
            "aura_of_silence_tax_and_sacrifice_removal_waiver_v1",
        )
        self.assertEqual(primary["taxes_opponent_artifact_enchantment_spells"], 2)

    def test_veil_of_summer_maps_to_exact_draw_and_protection_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "ConditionalOneShotEffect",
                    "DrawCardSourceControllerEffect",
                    "CantBeCounteredControlledEffect",
                    "GainAbilityControlledEffect",
                    "GainAbilityControllerEffect",
                    "VeilOfSummerEffect",
                ],
                "ability_classes": ["HexproofFromBlueAbility", "HexproofFromBlackAbility"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new ConditionalOneShotEffect("
                    "new DrawCardSourceControllerEffect(1), VeilOfSummerCondition.instance)); "
                    "this.getSpellAbility().addEffect(new CantBeCounteredControlledEffect("
                    "StaticFilters.FILTER_SPELL, Duration.EndOfTurn)); "
                    "this.getSpellAbility().addEffect(new VeilOfSummerEffect()); "
                    "game.addEffect(new GainAbilityControlledEffect(HexproofFromBlueAbility.getInstance(), Duration.EndOfTurn, StaticFilters.FILTER_PERMANENTS), source); "
                    "game.addEffect(new GainAbilityControlledEffect(HexproofFromBlackAbility.getInstance(), Duration.EndOfTurn, StaticFilters.FILTER_PERMANENTS), source);"
                ),
            },
            "Draw a card if an opponent has cast a blue or black spell this turn. "
            "Spells you control can't be countered this turn. You and permanents you control "
            "gain hexproof from blue and from black until end of turn.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "draw_cards")
        self.assertEqual(
            primary["battle_model_scope"],
            "veil_of_summer_draw_and_protection_waiver_v1",
        )
        self.assertEqual(primary["count"], 1)
        self.assertTrue(primary["instant"])
        self.assertTrue(primary["conditional_draw_if_opponent_cast_blue_or_black_spell_this_turn"])
        self.assertTrue(primary["spells_you_control_cant_be_countered_this_turn"])
        self.assertEqual(
            primary["controller_and_permanents_hexproof_from_colors_until_eot"],
            ["U", "B"],
        )

    def test_rishkar_maps_to_exact_counter_mana_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["AddCountersTargetEffect", "GainAbilityControlledEffect"],
                "ability_classes": ["EntersBattlefieldTriggeredAbility", "SimpleStaticAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "Effect effect = new AddCountersTargetEffect(CounterType.P1P1.createInstance()); "
                    "Ability ability = new EntersBattlefieldTriggeredAbility(effect, false); "
                    "ability.addTarget(new TargetCreaturePermanent(0, 2)); "
                    "this.addAbility(new SimpleStaticAbility(new GainAbilityControlledEffect("
                    "new GreenManaAbility(), Duration.WhileOnBattlefield, filter))); "
                    "filter.add(CounterAnyPredicate.instance);"
                ),
            },
            'When this creature enters the battlefield, put a +1/+1 counter on each of up to two target creatures. '
            'Each creature you control with a counter on it has "{T}: Add {G}."',
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "rishkar_counter_mana_creature_waiver_v1",
        )
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 2)
        self.assertEqual(primary["etb_plus_one_counter_targets"], 2)
        self.assertTrue(primary["countered_creatures_tap_for_mana"])

    def test_bartolome_maps_to_exact_self_counter_sacrifice_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["AddCountersSourceEffect"],
                "ability_classes": ["SimpleActivatedAbility"],
                "cost_classes": ["SacrificeTargetCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "public BartolomeDelPresidio(UUID ownerId, CardSetInfo setInfo) { "
                    "super(ownerId, setInfo, new CardType[]{CardType.CREATURE}, \"{W}{B}\"); "
                    "this.power = new MageInt(2); this.toughness = new MageInt(1); "
                    "this.addAbility(new SimpleActivatedAbility("
                    "new AddCountersSourceEffect(CounterType.P1P1.createInstance()), "
                    "new SacrificeTargetCost(StaticFilters.FILTER_CONTROLLED_ANOTHER_CREATURE_OR_ARTIFACT)"
                    ")); }"
                ),
            },
            "Sacrifice another creature or artifact: Put a +1/+1 counter on Bartolomé del Presidio.",
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "sacrifice_another_creature_or_artifact_put_plus_one_counter_on_self_v1",
        )
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 1)
        self.assertEqual(primary["activation_cost"], "sacrifice_creature_or_artifact")
        self.assertEqual(primary["self_add_plus_one_counter"], 1)

    def test_insidious_roots_maps_to_exact_passive_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "AddCountersAllEffect",
                    "CreateTokenEffect",
                    "GainAbilityControlledEffect",
                ],
                "ability_classes": [
                    "CardsLeaveGraveyardTriggeredAbility",
                    "SimpleStaticAbility",
                ],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "this.addAbility(new SimpleStaticAbility(new GainAbilityControlledEffect("
                    "new AnyColorManaAbility(), Duration.WhileOnBattlefield, StaticFilters.FILTER_CREATURE_TOKENS))); "
                    "Ability ability = new CardsLeaveGraveyardTriggeredAbility("
                    "new CreateTokenEffect(new PlantToken()), StaticFilters.FILTER_CARD_CREATURES); "
                    "ability.addEffect(new AddCountersAllEffect(CounterType.P1P1.createInstance(), filter));"
                ),
            },
            (
                'Creature tokens you control have "{T}: Add one mana of any color." '
                "Whenever one or more creature cards leave your graveyard, create a 0/1 green Plant creature token, "
                "then put a +1/+1 counter on each Plant you control."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "passive")
        self.assertEqual(
            primary["battle_model_scope"],
            "creature_tokens_tap_any_color_creature_graveyard_plant_growth_v1",
        )
        self.assertTrue(primary["creature_tokens_tap_for_any_color"])
        self.assertTrue(primary["creature_cards_leave_your_graveyard_create_plant_token"])
        self.assertTrue(primary["plant_tokens_get_plus_one_counter_on_creature_graveyard_exit"])
        self.assertEqual(primary["token_name"], "Plant Token")
        self.assertEqual(primary["token_subtype"], "Plant")
        self.assertEqual(primary["token_power"], 0)
        self.assertEqual(primary["token_toughness"], 1)
        self.assertEqual(primary["token_colors"], ["G"])

    def test_cryptolith_rite_maps_to_creatures_tap_any_color_static_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["GainAbilityControlledEffect"],
                "ability_classes": ["AnyColorManaAbility", "SimpleStaticAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "this.addAbility(new SimpleStaticAbility(new GainAbilityControlledEffect("
                    "new AnyColorManaAbility(), Duration.WhileOnBattlefield, StaticFilters.FILTER_PERMANENT_CREATURES, false)));"
                ),
            },
            'Each creature you control has "{T}: Add one mana of any color."',
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "passive")
        self.assertEqual(primary["battle_model_scope"], "creatures_tap_any_color_static_enchantment_v1")
        self.assertTrue(primary["creatures_tap_for_any_color"])

    def test_enduring_vitality_maps_to_creature_tap_any_color_static_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["GainAbilityControlledEffect"],
                "ability_classes": [
                    "AnyColorManaAbility",
                    "EnduringGlimmerTriggeredAbility",
                    "SimpleStaticAbility",
                    "VigilanceAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE", "ENCHANTMENT"]},
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.ENCHANTMENT, CardType.CREATURE}, "{1}{G}{G}"); '
                    "this.power = new MageInt(3); "
                    "this.toughness = new MageInt(3); "
                    "this.addAbility(VigilanceAbility.getInstance()); "
                    "this.addAbility(new SimpleStaticAbility(new GainAbilityControlledEffect("
                    "new AnyColorManaAbility(), Duration.WhileOnBattlefield, StaticFilters.FILTER_PERMANENT_CREATURES))); "
                    "this.addAbility(new EnduringGlimmerTriggeredAbility());"
                ),
            },
            'Vigilance. Each creature you control has "{T}: Add one mana of any color."',
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "vigilance_three_three_creatures_tap_any_color_v1")
        self.assertEqual(primary["power"], 3)
        self.assertEqual(primary["toughness"], 3)
        self.assertTrue(primary["vigilance"])
        self.assertTrue(primary["creatures_tap_for_any_color"])
        self.assertEqual(primary["death_return_status"], "annotation_only")

    def test_magda_maps_to_exact_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
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
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.addAbility(new SimpleStaticAbility(new BoostControlledEffect(1, 0, Duration.WhileOnBattlefield, filter, true))); "
                    "this.addAbility(new BecomesTappedTriggeredAbility(new CreateTokenEffect(new TreasureToken()), false, filter2)); "
                    "this.addAbility(new SimpleActivatedAbility(new SearchLibraryPutInPlayEffect(new TargetCardInLibrary(filter3), false, true), "
                    "new SacrificeTargetCost(5, filter4)));"
                ),
            },
            (
                "Other Dwarves you control get +1/+0. "
                "Whenever a Dwarf you control becomes tapped, create a Treasure token. "
                "Sacrifice five Treasures: Search your library for an artifact or Dragon card, put that card onto the battlefield, then shuffle your library."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]

        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "magda_dwarf_tap_treasure_and_five_treasure_tutor_v1",
        )
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 1)
        self.assertTrue(primary["other_dwarves_you_control_get_plus_one_power"])
        self.assertTrue(primary["controlled_dwarf_becomes_tapped_creates_treasure"])
        self.assertTrue(primary["activated_sacrifice_five_treasures_tutor_artifact_or_dragon"])
        self.assertEqual(primary["activated_treasure_tutor_cost"], 5)
        self.assertEqual(primary["activated_treasure_tutor_destination"], "battlefield")

    def test_an_offer_you_cant_refuse_maps_to_exact_counter_treasure_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CounterTargetEffect", "CreateTokenControllerTargetEffect"],
                "target_classes": ["TargetSpell"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new CounterTargetEffect()); "
                    "this.getSpellAbility().addEffect(new CreateTokenControllerTargetEffect(new TreasureToken(), 2, false)); "
                    "this.getSpellAbility().addTarget(new TargetSpell(StaticFilters.FILTER_SPELL_NON_CREATURE));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "counter_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "counter_noncreature_spell_target_controller_treasure_two_v1",
        )
        self.assertEqual(primary["target"], "noncreature_spell")
        self.assertEqual(primary["target_controller_creates_treasure"], 2)

    def test_swan_song_maps_to_exact_counter_bird_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CounterTargetEffect", "CreateTokenControllerTargetEffect"],
                "target_classes": ["TargetSpell"],
                "filter_classes": ["FilterSpell"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "filter.add(Predicates.or(CardType.ENCHANTMENT.getPredicate(), CardType.INSTANT.getPredicate(), CardType.SORCERY.getPredicate())); "
                    "this.getSpellAbility().addEffect(new CounterTargetEffect()); "
                    "this.getSpellAbility().addEffect(new CreateTokenControllerTargetEffect(new SwanSongBirdToken())); "
                    "this.getSpellAbility().addTarget(new TargetSpell(filter));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "counter_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "counter_enchantment_instant_sorcery_spell_target_controller_bird_v1",
        )
        self.assertEqual(primary["target"], "enchantment_instant_or_sorcery_spell")
        self.assertEqual(primary["target_controller_creates_token"]["name"], "Bird")
        self.assertEqual(primary["target_controller_creates_token"]["power"], 2)

    def test_pact_of_negation_maps_to_exact_delayed_upkeep_counter_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CounterTargetEffect", "CreateDelayedTriggeredAbilityEffect"],
                "ability_classes": ["PactDelayedTriggeredAbility"],
                "target_classes": ["TargetSpell"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addTarget(new TargetSpell()); "
                    "this.getSpellAbility().addEffect(new CounterTargetEffect()); "
                    "this.getSpellAbility().addEffect(new CreateDelayedTriggeredAbilityEffect("
                    "new PactDelayedTriggeredAbility(new ManaCostsImpl<>(\"{3}{U}{U}\")), false));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "counter_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "pact_of_negation_delayed_upkeep_counter_v1",
        )
        self.assertEqual(primary["target"], "spell")
        self.assertEqual(primary["delayed_upkeep_mana_payment"], "{3}{U}{U}")
        self.assertTrue(primary["lose_game_if_unpaid"])

    def test_refute_maps_to_exact_counter_draw_discard_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CounterTargetEffect", "DrawDiscardControllerEffect"],
                "target_classes": ["TargetSpell"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new CounterTargetEffect()); "
                    "this.getSpellAbility().addTarget(new TargetSpell()); "
                    "this.getSpellAbility().addEffect(new DrawDiscardControllerEffect(1, 1));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "counter_spell")
        self.assertEqual(primary["battle_model_scope"], "counter_spell_draw_then_discard_v1")
        self.assertEqual(primary["draw_then_discard"], 1)

    def test_wizards_retort_maps_to_exact_control_wizard_counter_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CounterTargetEffect", "SpellCostReductionSourceEffect"],
                "ability_classes": ["SimpleStaticAbility"],
                "target_classes": ["TargetSpell"],
                "filter_classes": ["FilterControlledPermanent"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "filter.add(SubType.WIZARD.getPredicate()); "
                    "Ability ability = new SimpleStaticAbility(Zone.ALL, new SpellCostReductionSourceEffect(1, condition)); "
                    "ability.addHint(new ConditionHint(condition, \"You control a Wizard\")); "
                    "this.getSpellAbility().addTarget(new TargetSpell()); "
                    "this.getSpellAbility().addEffect(new CounterTargetEffect());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "counter_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "counter_spell_costs_one_less_if_control_wizard_v1",
        )
        self.assertEqual(primary["cost_reduction_generic_if_control_wizard"], 1)

    def test_bolt_bend_maps_to_exact_ferocious_redirect_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["ChooseNewTargetsTargetEffect", "SpellCostReductionSourceEffect"],
                "target_classes": ["TargetStackObject"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "private static final FilterStackObject filter = new FilterStackObject(\"spell or ability with a single target\"); "
                    "filter.add(new NumberOfTargetsPredicate(1)); "
                    "this.addAbility(new SimpleStaticAbility(Zone.ALL, new SpellCostReductionSourceEffect(3, FerociousCondition.instance))); "
                    "this.getSpellAbility().addEffect(new ChooseNewTargetsTargetEffect(true, true)); "
                    "this.getSpellAbility().addTarget(new TargetStackObject(filter));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "redirect_removal")
        self.assertEqual(
            primary["battle_model_scope"],
            "single_target_spell_or_ability_redirect_costs_three_less_if_control_power_four_v1",
        )
        self.assertEqual(primary["target"], "single_target_spell_or_ability")
        self.assertEqual(primary["cost_reduction_applies_to"], "this_spell")
        self.assertEqual(primary["cost_reduction_generic"], 3)
        self.assertEqual(primary["cost_reduction_condition"], "control_creature_power_4_or_greater")

    def test_modal_copy_change_target_maps_to_partial_runtime_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CopyTargetStackObjectEffect", "ChooseNewTargetsTargetEffect"],
                "target_classes": ["TargetStackObject"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.addAbility(new SpreeAbility()); "
                    "this.getSpellAbility().addEffect(new CopyTargetStackObjectEffect()); "
                    "this.getSpellAbility().addEffect(new ChooseNewTargetsTargetEffect(true, true)); "
                    "FilterStackObject filter = new FilterStackObject(\"spell or ability with a single target\"); "
                    "filter.add(new NumberOfTargetsPredicate(1)); "
                    "this.getSpellAbility().addTarget(new TargetStackObject(filter)); "
                    "Copy target instant spell, sorcery spell, activated ability, or triggered ability. "
                    "You may choose new targets for the copy. Change the target of target spell or ability with a single target."
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "copy_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "spree_copy_stack_object_change_target_selected_mode_runtime_v1",
        )
        self.assertEqual(primary["target"], "stack_object")
        self.assertEqual(primary["change_target_mode_status"], "runtime_executor_v1")
        self.assertEqual(
            primary["target_change_pipeline"],
            "single_target_stack_object_redirect_runtime_v1",
        )
        self.assertTrue(primary["spree"])
        self.assertEqual(primary["spree_additional_cost_status"], "runtime_executor_v1")
        self.assertEqual(primary["spree_selected_mode_cost_status"], "runtime_executor_v1")
        self.assertEqual(primary["spree_mode_costs"]["copy_instant_or_sorcery_spell"], "{1}")
        self.assertEqual(primary["spree_mode_costs"]["change_single_target"], "{1}")
        self.assertEqual(primary["copy_activated_triggered_ability_status"], "runtime_executor_v1")

    def test_modal_destroy_artifact_redirect_maps_to_partial_runtime_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DestroyTargetEffect", "ChooseNewTargetsTargetEffect"],
                "target_classes": ["TargetPermanent", "TargetStackObject"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addTarget(new TargetPermanent(StaticFilters.FILTER_ARTIFACT_PERMANENT)); "
                    "this.getSpellAbility().addEffect(new DestroyTargetEffect()); "
                    "FilterStackObject filter = new FilterStackObject(\"spell or ability with a single target\"); "
                    "filter.add(new NumberOfTargetsPredicate(1)); "
                    "this.getSpellAbility().addTarget(new TargetStackObject(filter)); "
                    "this.getSpellAbility().addEffect(new ChooseNewTargetsTargetEffect(true, true)); "
                    "Target creature can't block this turn."
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "remove_permanent")
        self.assertEqual(
            primary["battle_model_scope"],
            "modal_destroy_artifact_redirect_target_cant_block_runtime_v1",
        )
        self.assertEqual(primary["target"], "artifact")
        self.assertTrue(primary["destroy_artifact_mode"])
        self.assertEqual(primary["redirect_target_mode_status"], "runtime_executor_v1")
        self.assertEqual(primary["cant_block_mode_status"], "runtime_executor_v1")
        self.assertEqual(
            primary["target_change_pipeline"],
            "single_target_stack_object_redirect_runtime_v1",
        )

    def test_mana_leak_maps_to_exact_soft_counter_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CounterUnlessPaysEffect"],
                "cost_classes": ["GenericManaCost"],
                "target_classes": ["TargetSpell"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addTarget(new TargetSpell()); "
                    "this.getSpellAbility().addEffect(new CounterUnlessPaysEffect(new GenericManaCost(3)));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "counter_spell")
        self.assertEqual(primary["battle_model_scope"], "counter_spell_unless_controller_pays_three_v1")
        self.assertEqual(primary["target"], "spell")
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["unless_controller_pays_generic"], 3)

    def test_miscast_maps_to_exact_soft_instant_or_sorcery_counter_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CounterUnlessPaysEffect"],
                "cost_classes": ["GenericManaCost"],
                "target_classes": ["TargetSpell"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new CounterUnlessPaysEffect(new GenericManaCost(3))); "
                    "this.getSpellAbility().addTarget(new TargetSpell(StaticFilters.FILTER_SPELL_INSTANT_OR_SORCERY));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "counter_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "counter_instant_or_sorcery_unless_controller_pays_three_v1",
        )
        self.assertEqual(primary["target"], "instant_or_sorcery_spell")
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["unless_controller_pays_generic"], 3)

    def test_spell_pierce_maps_to_exact_soft_noncreature_counter_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CounterUnlessPaysEffect"],
                "cost_classes": ["GenericManaCost"],
                "target_classes": ["TargetSpell"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addTarget(new TargetSpell(StaticFilters.FILTER_SPELL_NON_CREATURE)); "
                    "this.getSpellAbility().addEffect(new CounterUnlessPaysEffect(new GenericManaCost(2)));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "counter_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "counter_noncreature_spell_unless_controller_pays_two_v1",
        )
        self.assertEqual(primary["target"], "noncreature_spell")
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["unless_controller_pays_generic"], 2)

    def test_flusterstorm_maps_to_storm_soft_counter_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Flusterstorm",
                "effect_classes": ["CounterUnlessPaysEffect"],
                "ability_classes": ["StormAbility"],
                "target_classes": ["TargetSpell"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    'this.getSpellAbility().addEffect(new CounterUnlessPaysEffect(new ManaCostsImpl<>("{1}"))); '
                    "this.getSpellAbility().addTarget(new TargetSpell(StaticFilters.FILTER_SPELL_INSTANT_OR_SORCERY)); "
                    "this.addAbility(new StormAbility());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "counter_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "storm_counter_instant_or_sorcery_unless_controller_pays_one_v1",
        )
        self.assertEqual(primary["target"], "instant_or_sorcery_spell")
        self.assertEqual(primary["unless_controller_pays_generic"], 1)
        self.assertTrue(primary["storm"])

    def test_brain_freeze_maps_to_storm_mill_runtime_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "BrainFreeze",
                "effect_classes": ["MillCardsTargetEffect"],
                "ability_classes": ["StormAbility"],
                "target_classes": ["TargetPlayer"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addTarget(new TargetPlayer()); "
                    "this.getSpellAbility().addEffect(new MillCardsTargetEffect(3)); "
                    "this.addAbility(new StormAbility());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "brain_freeze")
        self.assertEqual(primary["battle_model_scope"], "storm_target_player_mill_fixed_count_v1")
        self.assertEqual(primary["mill_count"], 3)
        self.assertTrue(primary["storm"])

    def test_dark_ritual_maps_to_exact_black_ritual_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["BasicManaEffect"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": "this.getSpellAbility().addEffect(new BasicManaEffect(Mana.BlackMana(3)));",
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_ritual")
        self.assertEqual(primary["battle_model_scope"], "three_black_mana_ritual_v1")
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["mana_produced"], 3)
        self.assertEqual(primary["produces"], "B")

    def test_cabal_ritual_maps_to_threshold_black_ritual_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "CabalRitual",
                "effect_classes": ["BasicManaEffect", "ConditionalManaEffect"],
                "condition_classes": ["ThresholdCondition"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "new ConditionalManaEffect("
                    "new BasicManaEffect(Mana.BlackMana(5)), "
                    "new BasicManaEffect(Mana.BlackMana(3)), "
                    "ThresholdCondition.instance)"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_ritual")
        self.assertEqual(primary["battle_model_scope"], "threshold_three_or_five_black_mana_ritual_v1")
        self.assertEqual(primary["mana_produced"], 3)
        self.assertEqual(primary["threshold_graveyard_count"], 7)
        self.assertEqual(primary["threshold_mana_produced"], 5)

    def test_pyretic_ritual_maps_to_exact_red_ritual_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["BasicManaEffect"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": "this.getSpellAbility().addEffect(new BasicManaEffect(Mana.RedMana(3)));",
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_ritual")
        self.assertEqual(primary["battle_model_scope"], "three_red_mana_ritual_v1")
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["mana_produced"], 3)
        self.assertEqual(primary["produces"], "R")

    def test_desperate_ritual_maps_to_arcane_splice_red_ritual_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["BasicManaEffect"],
                "ability_classes": ["SpliceAbility"],
                "constructor_metadata": {"card_types": ["INSTANT"], "subtypes": ["ARCANE"]},
                "raw_excerpt": (
                    "this.subtype.add(SubType.ARCANE); "
                    "this.getSpellAbility().addEffect(new BasicManaEffect(Mana.RedMana(3))); "
                    'this.addAbility(new SpliceAbility(SpliceAbility.ARCANE, "{1}{R}"));'
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_ritual")
        self.assertEqual(primary["battle_model_scope"], "three_red_mana_arcane_splice_ritual_v1")
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["mana_produced"], 3)
        self.assertEqual(primary["produces"], "R")
        self.assertTrue(primary["subtype_arcane"])
        self.assertEqual(primary["splice_arcane_cost"], "{1}{R}")

    def test_misty_rainforest_maps_to_fetch_land_exact_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["FetchLandActivatedAbility"],
                "constructor_metadata": {"card_types": ["LAND"]},
                "raw_excerpt": "this.addAbility(new FetchLandActivatedAbility(SubType.FOREST, SubType.ISLAND));",
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["battle_model_scope"], "self_sacrifice_fetch_land_two_land_subtypes_v1")
        self.assertTrue(primary["activated_self_sacrifice_land_tutor"])
        self.assertEqual(primary["activation_cost_generic"], 0)
        self.assertTrue(primary["activation_requires_tap"])
        self.assertEqual(primary["activated_pay_life"], 1)
        self.assertEqual(primary["land_count"], 1)
        self.assertEqual(primary["lands_to_battlefield"], 1)
        self.assertFalse(primary["land_enters_tapped"])
        self.assertEqual(primary["land_subtypes_any"], ["Forest", "Island"])

    def test_polluted_delta_maps_to_fetch_land_exact_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "ability_classes": ["FetchLandActivatedAbility"],
                "constructor_metadata": {"card_types": ["LAND"]},
                "raw_excerpt": "this.addAbility(new FetchLandActivatedAbility(SubType.ISLAND, SubType.SWAMP));",
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["battle_model_scope"], "self_sacrifice_fetch_land_two_land_subtypes_v1")
        self.assertEqual(primary["land_subtypes_any"], ["Island", "Swamp"])

    def test_culling_the_weak_maps_to_creature_sacrifice_black_ritual_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["BasicManaEffect"],
                "cost_classes": ["SacrificeTargetCost"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addCost(new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE)); "
                    "this.getSpellAbility().addEffect(new BasicManaEffect(Mana.BlackMana(4)));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_ritual")
        self.assertEqual(primary["battle_model_scope"], "sacrifice_creature_add_four_black_mana_ritual_v1")
        self.assertTrue(primary["instant"])
        self.assertTrue(primary["requires_sacrifice_creature"])
        self.assertEqual(primary["mana_produced"], 4)
        self.assertEqual(primary["produces"], "B")

    def test_infernal_plunge_maps_to_creature_sacrifice_red_ritual_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["BasicManaEffect"],
                "cost_classes": ["SacrificeTargetCost"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addCost(new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE)); "
                    "this.getSpellAbility().addEffect(new BasicManaEffect(Mana.RedMana(3)));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_ritual")
        self.assertEqual(primary["battle_model_scope"], "sacrifice_creature_add_three_red_mana_ritual_v1")
        self.assertFalse(primary["instant"])
        self.assertTrue(primary["requires_sacrifice_creature"])

    def test_chain_of_vapor_maps_to_bounce_copy_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "ChainOfVapor",
                "effect_classes": ["ChainOfVaporEffect", "OneShotEffect"],
                "target_classes": ["TargetNonlandPermanent", "TargetSacrifice"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "Return target nonland permanent to its owner's hand. Then that permanent's controller "
                    "may sacrifice a land of their choice. If the player does, they may copy this spell "
                    "and may choose a new target for that copy"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "bounce")
        self.assertEqual(
            primary["battle_model_scope"],
            "return_target_nonland_permanent_controller_may_sacrifice_land_copy_v1",
        )
        self.assertEqual(primary["target"], "nonland_permanent")
        self.assertTrue(primary["target_controller_may_sacrifice_land_to_copy"])

    def test_blood_artist_maps_to_death_life_drain_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "BloodArtist",
                "effect_classes": ["GainLifeEffect", "LoseLifeTargetEffect"],
                "ability_classes": ["DiesThisOrAnotherTriggeredAbility"],
                "target_classes": ["TargetPlayer"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(0); this.toughness = new MageInt(1); "
                    "new DiesThisOrAnotherTriggeredAbility(new LoseLifeTargetEffect(1), false); "
                    "new GainLifeEffect(1)"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "another_creature_dies_target_player_loses_life_you_gain_life_v1",
        )
        self.assertEqual(primary["target_player_loses_life"], 1)
        self.assertEqual(primary["controller_gains_life"], 1)

    def test_fury_storm_maps_to_copy_stack_spell_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "FuryStorm",
                "effect_classes": ["CopyTargetStackObjectEffect"],
                "ability_classes": ["CommanderStormAbility"],
                "target_classes": ["TargetSpell"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.addAbility(new CommanderStormAbility(true)); "
                    "this.getSpellAbility().addEffect(new CopyTargetStackObjectEffect()); "
                    "this.getSpellAbility().addTarget(new TargetSpell(StaticFilters.FILTER_SPELL_INSTANT_OR_SORCERY));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "copy_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "copy_target_instant_or_sorcery_stack_spell_choose_new_targets_runtime_v1",
        )
        self.assertEqual(primary["target"], "instant_or_sorcery_on_stack")
        self.assertTrue(primary["may_choose_new_targets"])
        self.assertEqual(primary["choose_new_targets_status"], "runtime_executor_v1")
        self.assertEqual(primary["copy_target_selection_status"], "runtime_executor_v1")
        self.assertEqual(
            primary["copy_target_selection_pipeline"],
            "copy_spell_runtime_choose_new_targets_v1",
        )
        self.assertTrue(primary["commander_storm"])
        self.assertFalse(result["primary_candidate"]["requires_runtime_executor"])

    def test_reiterate_maps_to_copy_stack_buyback_runtime_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Reiterate",
                "effect_classes": ["CopyTargetStackObjectEffect"],
                "ability_classes": ["BuybackAbility"],
                "target_classes": ["TargetSpell"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.addAbility(new BuybackAbility(\"{3}\")); "
                    "this.getSpellAbility().addEffect(new CopyTargetStackObjectEffect()); "
                    "this.getSpellAbility().addTarget(new TargetSpell(StaticFilters.FILTER_SPELL_INSTANT_OR_SORCERY));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "copy_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "copy_stack_instant_or_sorcery_new_targets_runtime_buyback_runtime_v1",
        )
        self.assertEqual(primary["target"], "instant_or_sorcery_on_stack")
        self.assertTrue(primary["may_choose_new_targets"])
        self.assertEqual(primary["choose_new_targets_status"], "runtime_executor_v1")
        self.assertEqual(primary["copy_target_selection_status"], "runtime_executor_v1")
        self.assertEqual(primary["buyback_status"], "runtime_executor_v1")
        self.assertEqual(primary["buyback_cost"], "{3}")
        self.assertEqual(
            primary["oracle_runtime_scope"],
            "copy_target_instant_or_sorcery_stack_spell_choose_new_targets_buyback_runtime_v1",
        )
        self.assertFalse(result["primary_candidate"]["requires_runtime_executor"])

    def test_mystical_tutor_maps_to_instant_or_sorcery_topdeck_tutor_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutOnLibraryEffect"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    'private static final FilterCard filter = new FilterCard("instant or sorcery card"); '
                    "filter.add(Predicates.or(CardType.INSTANT.getPredicate(), CardType.SORCERY.getPredicate())); "
                    "this.getSpellAbility().addEffect(new SearchLibraryPutOnLibraryEffect(new TargetCardInLibrary(filter), true));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(primary["battle_model_scope"], "instant_or_sorcery_tutor_to_top_v1")
        self.assertTrue(primary["instant"])

    def test_grim_tutor_maps_to_any_tutor_with_life_loss_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "GrimTutor",
                "effect_classes": ["LoseLifeSourceControllerEffect", "SearchLibraryPutInHandEffect"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new SearchLibraryPutInHandEffect(new TargetCardInLibrary(), false, true)); "
                    "this.getSpellAbility().addEffect(new LoseLifeSourceControllerEffect(3));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(primary["battle_model_scope"], "any_tutor_to_hand_controller_loses_life_v1")
        self.assertEqual(primary["target"], "any_to_hand")
        self.assertEqual(primary["controller_loses_life_after_tutor"], 3)

    def test_demonic_counsel_maps_to_delirium_upgrade_tutor_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "DemonicCounsel",
                "effect_classes": ["ConditionalOneShotEffect", "SearchLibraryPutInHandEffect"],
                "condition_classes": ["DeliriumCondition"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    "new SearchLibraryPutInHandEffect(new TargetCardInLibrary(new FilterCard(\"a Demon card\")), true); "
                    "new ConditionalOneShotEffect(new SearchLibraryPutInHandEffect(new TargetCardInLibrary(), false), "
                    "new SearchLibraryPutInHandEffect(new TargetCardInLibrary(new FilterCard(\"a Demon card\")), true), "
                    "DeliriumCondition.instance);"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(primary["battle_model_scope"], "conditional_delirium_restricted_or_any_tutor_to_hand_v1")
        self.assertEqual(primary["target"], "demon_to_hand")
        self.assertEqual(primary["delirium_target"], "any_to_hand")
        self.assertEqual(primary["delirium_graveyard_card_type_count"], 4)

    def test_wishclaw_talisman_maps_to_counter_artifact_tutor_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "WishclawTalisman",
                "effect_classes": [
                    "ContinuousEffect",
                    "GainControlTargetEffect",
                    "OneShotEffect",
                    "SearchLibraryPutInHandEffect",
                    "WishclawTalismanEffect",
                ],
                "ability_classes": ["ActivateIfConditionActivatedAbility", "EntersBattlefieldWithCountersAbility", "SimpleActivatedAbility"],
                "condition_classes": ["MyTurnCondition"],
                "cost_classes": ["GenericManaCost", "RemoveCountersSourceCost", "TapSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    "this.addAbility(new EntersBattlefieldWithCountersAbility(CounterType.WISH.createInstance(3))); "
                    "new SearchLibraryPutInHandEffect(new TargetCardInLibrary(), false); "
                    "new GenericManaCost(1); ability.addCost(new TapSourceCost()); "
                    "ability.addCost(new RemoveCountersSourceCost(CounterType.WISH.createInstance())); "
                    "new GainControlTargetEffect();"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(
            primary["battle_model_scope"],
            "artifact_wish_counter_any_tutor_to_hand_then_opponent_gains_control_v1",
        )
        self.assertEqual(primary["activation_removes_counter"], "wish")
        self.assertTrue(primary["opponent_gains_control_after_activation"])

    def test_rune_scarred_demon_maps_to_etb_creature_tutor_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "RuneScarredDemon",
                "effect_classes": ["SearchLibraryPutInHandEffect"],
                "ability_classes": ["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(6); this.toughness = new MageInt(6); "
                    "new EntersBattlefieldTriggeredAbility(new SearchLibraryPutInHandEffect(new TargetCardInLibrary(), false));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "etb_tutor_to_hand_creature_variant_v1")
        self.assertEqual(primary["etb_tutor_target"], "any_to_hand")
        self.assertEqual(primary["power"], 6)

    def test_worldly_tutor_maps_to_creature_topdeck_tutor_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutOnLibraryEffect"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect("
                    "new SearchLibraryPutOnLibraryEffect(new TargetCardInLibrary(StaticFilters.FILTER_CARD_CREATURE), true));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(primary["battle_model_scope"], "creature_tutor_to_top_v1")
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["target"], "creature_to_top")

    def test_vampiric_tutor_maps_to_any_topdeck_life_loss_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutOnLibraryEffect", "LoseLifeSourceControllerEffect"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new SearchLibraryPutOnLibraryEffect(new TargetCardInLibrary(), false)); "
                    "this.getSpellAbility().addEffect(new LoseLifeSourceControllerEffect(2));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(primary["battle_model_scope"], "any_tutor_to_top_lose_two_life_v1")
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["target"], "any_to_top")
        self.assertEqual(primary["controller_loses_life_after_tutor"], 2)

    def test_imperial_seal_maps_to_any_topdeck_life_loss_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutOnLibraryEffect", "LoseLifeSourceControllerEffect"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new SearchLibraryPutOnLibraryEffect(new TargetCardInLibrary(), false)); "
                    "this.getSpellAbility().addEffect(new LoseLifeSourceControllerEffect(2));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(primary["battle_model_scope"], "any_tutor_to_top_lose_two_life_v1")
        self.assertFalse(primary["instant"])
        self.assertEqual(primary["target"], "any_to_top")
        self.assertEqual(primary["controller_loses_life_after_tutor"], 2)

    def test_demonic_tutor_maps_to_any_tutor_to_hand_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInHandEffect"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect("
                    "new SearchLibraryPutInHandEffect(new TargetCardInLibrary(), false, true));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(primary["battle_model_scope"], "any_tutor_to_hand_v1")
        self.assertFalse(primary["instant"])
        self.assertEqual(primary["target"], "any_to_hand")

    def test_diabolic_intent_maps_to_sacrifice_creature_any_tutor_to_hand_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInHandEffect"],
                "cost_classes": ["SacrificeTargetCost"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addCost(new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE)); "
                    "this.getSpellAbility().addEffect(new SearchLibraryPutInHandEffect(new TargetCardInLibrary(), false, true));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(primary["battle_model_scope"], "sacrifice_creature_any_tutor_to_hand_v1")
        self.assertEqual(primary["target"], "any_to_hand")
        self.assertTrue(primary["requires_sacrifice_creature"])

    def test_sylvan_scrying_maps_to_land_tutor_to_hand_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInHandEffect"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    'private static final FilterLandCard filter = new FilterLandCard("land card"); '
                    "this.getSpellAbility().addEffect(new SearchLibraryPutInHandEffect(new TargetCardInLibrary(filter), true));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(primary["battle_model_scope"], "land_tutor_to_hand_v1")
        self.assertEqual(primary["target"], "land_to_hand")

    def test_expedition_map_maps_to_activated_land_tutor_to_hand_artifact_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInHandEffect"],
                "ability_classes": ["SimpleActivatedAbility"],
                "cost_classes": ["GenericManaCost", "TapSourceCost", "SacrificeSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "xmage_class_name": "ExpeditionMap",
                "raw_excerpt": (
                    'TargetCardInLibrary target = new TargetCardInLibrary(new FilterLandCard()); '
                    "SimpleActivatedAbility ability = new SimpleActivatedAbility("
                    "new SearchLibraryPutInHandEffect(target, true), new GenericManaCost(2)); "
                    "ability.addCost(new TapSourceCost()); ability.addCost(new SacrificeSourceCost());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(primary["battle_model_scope"], "activated_self_sacrifice_land_tutor_to_hand_artifact_v1")
        self.assertTrue(primary["activated_self_sacrifice_tutor_to_hand"])
        self.assertEqual(primary["activation_cost_generic"], 2)
        self.assertEqual(primary["tutor_target"], "land")
        self.assertEqual(primary["tutor_destination"], "hand")

    def test_moonsilver_key_maps_to_activated_mana_artifact_or_basic_land_tutor_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInHandEffect"],
                "ability_classes": ["ManaAbility", "SimpleActivatedAbility"],
                "cost_classes": ["GenericManaCost", "TapSourceCost", "SacrificeSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "xmage_class_name": "MoonsilverKey",
                "raw_excerpt": (
                    'private static final FilterCard filter = new FilterCard("an artifact card with a mana ability or a basic land card"); '
                    "Ability ability = new SimpleActivatedAbility(new SearchLibraryPutInHandEffect("
                    "new TargetCardInLibrary(filter), true), new GenericManaCost(1)); "
                    "ability.addCost(new TapSourceCost()); ability.addCost(new SacrificeSourceCost()); "
                    "return input.isArtifact(game) && input.getAbilities(game).stream().anyMatch(ManaAbility.class::isInstance);"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(
            primary["battle_model_scope"],
            "activated_self_sacrifice_artifact_mana_ability_or_basic_land_tutor_to_hand_v1",
        )
        self.assertEqual(primary["activation_cost_generic"], 1)
        self.assertEqual(primary["tutor_target"], "artifact_mana_ability_or_basic_land")
        self.assertEqual(primary["tutor_destination"], "hand")

    def test_weathered_wayfarer_maps_to_conditional_land_tutor_to_hand_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInHandEffect"],
                "ability_classes": ["ActivateIfConditionActivatedAbility"],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "xmage_class_name": "WeatheredWayfarer",
                "raw_excerpt": (
                    "private static final Condition condition = new OpponentControlsMoreCondition(StaticFilters.FILTER_LANDS); "
                    "Ability ability = new ActivateIfConditionActivatedAbility("
                    "new SearchLibraryPutInHandEffect(new TargetCardInLibrary(StaticFilters.FILTER_CARD_LAND_A), true), "
                    'new ManaCostsImpl<>("{W}"), condition); ability.addCost(new TapSourceCost());'
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "activated_opponent_more_lands_land_tutor_to_hand_creature_v1",
        )
        self.assertTrue(primary["land_tutor_to_hand_activated"])
        self.assertEqual(primary["activation_cost_colors"], ["W"])
        self.assertEqual(primary["activation_condition"], "opponent_controls_more_lands")
        self.assertEqual(primary["tutor_target"], "land")

    def test_scholar_of_new_horizons_maps_to_counter_plains_tutor_upgrade_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["OneShotEffect", "ScholarOfNewHorizonsEffect"],
                "ability_classes": ["EntersBattlefieldWithCountersAbility", "SimpleActivatedAbility"],
                "condition_classes": ["OpponentControlsMoreCondition"],
                "cost_classes": ["TapSourceCost", "RemoveCounterCost"],
                "counter_types": ["P1P1"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "xmage_class_name": "ScholarOfNewHorizons",
                "raw_excerpt": (
                    "this.addAbility(new EntersBattlefieldWithCountersAbility(CounterType.P1P1.createInstance(1))); "
                    "Ability ability = new SimpleActivatedAbility(new ScholarOfNewHorizonsEffect(), new TapSourceCost()); "
                    "ability.addCost(new RemoveCounterCost(new TargetControlledPermanent())); "
                    'private static final FilterCard filter = new FilterLandCard("Plains card"); '
                    "filter.add(SubType.PLAINS.getPredicate()); "
                    "private static final Condition condition = new OpponentControlsMoreCondition(StaticFilters.FILTER_LAND); "
                    "If an opponent controls more lands than you, you may put that card onto the battlefield tapped. "
                    "If you don't put the card onto the battlefield, put it into your hand."
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "activated_remove_counter_plains_tutor_battlefield_tapped_if_behind_else_hand_v1",
        )
        self.assertEqual(primary["enters_with_plus_one_counter_count"], 1)
        self.assertTrue(primary["land_tutor_to_hand_activated"])
        self.assertTrue(primary["activation_requires_tap"])
        self.assertTrue(primary["activation_requires_remove_plus_one_counter_from_controlled_permanent"])
        self.assertTrue(primary["activation_put_tutored_land_onto_battlefield_tapped_if_opponent_more_lands"])
        self.assertEqual(primary["tutor_target"], "plains")
        self.assertEqual(primary["tutor_destination"], "hand")

    def test_knight_of_the_white_orchid_maps_to_etb_plains_catchup_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInPlayEffect"],
                "ability_classes": ["EntersBattlefieldTriggeredAbility", "FirstStrikeAbility"],
                "condition_classes": ["OpponentControlsMoreCondition"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "xmage_class_name": "KnightOfTheWhiteOrchid",
                "raw_excerpt": (
                    "private static final FilterCard filter = new FilterCard(SubType.PLAINS); "
                    "private static final Condition condition = new OpponentControlsMoreCondition(StaticFilters.FILTER_LANDS); "
                    "this.addAbility(new EntersBattlefieldTriggeredAbility("
                    "new SearchLibraryPutInPlayEffect(new TargetCardInLibrary(filter), true)).setCondition(condition)); "
                    "If an opponent controls more lands than you, you may search your library for a Plains card, "
                    "put it onto the battlefield tapped, then shuffle."
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_opponent_more_lands_plains_to_battlefield_tapped_v1",
        )
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 2)
        self.assertEqual(primary["etb_land_ramp_count"], 1)
        self.assertEqual(primary["etb_land_ramp_condition"], "opponent_controls_more_lands")
        self.assertTrue(primary["land_enters_tapped"])
        self.assertEqual(primary["tutor_target"], "plains")
        self.assertEqual(primary["keywords"], ["first_strike"])

    def test_loyal_warhound_maps_to_etb_basic_plains_catchup_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInPlayEffect"],
                "ability_classes": ["EntersBattlefieldTriggeredAbility", "VigilanceAbility"],
                "condition_classes": ["OpponentControlsMoreCondition"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "xmage_class_name": "LoyalWarhound",
                "raw_excerpt": (
                    "private static final Condition condition = new OpponentControlsMoreCondition(StaticFilters.FILTER_LANDS); "
                    "this.addAbility(new EntersBattlefieldTriggeredAbility("
                    "new SearchLibraryPutInPlayEffect(new TargetCardInLibrary(StaticFilters.FILTER_CARD_BASIC_PLAINS), true)"
                    ").setCondition(condition)); "
                    "If an opponent controls more lands than you, you may search your library for a basic Plains card, "
                    "put it onto the battlefield tapped, then shuffle."
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_opponent_more_lands_plains_to_battlefield_tapped_v1",
        )
        self.assertEqual(primary["power"], 3)
        self.assertEqual(primary["toughness"], 1)
        self.assertEqual(primary["etb_land_ramp_count"], 1)
        self.assertEqual(primary["etb_land_ramp_condition"], "opponent_controls_more_lands")
        self.assertTrue(primary["land_enters_tapped"])
        self.assertEqual(primary["tutor_target"], "basic_plains")
        self.assertEqual(primary["keywords"], ["vigilance"])

    def test_rhystic_study_maps_to_opponent_spell_tax_draw_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["OneShotEffect", "RhysticStudyDrawEffect"],
                "ability_classes": ["SpellCastOpponentTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "xmage_class_name": "RhysticStudy",
                "raw_excerpt": (
                    "this.addAbility(new SpellCastOpponentTriggeredAbility("
                    "Zone.BATTLEFIELD, new RhysticStudyDrawEffect(), StaticFilters.FILTER_SPELL_A, false, SetTargetPointer.PLAYER)); "
                    'this.staticText = "you may draw a card unless that player pays {1}";'
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "draw_engine")
        self.assertEqual(primary["battle_model_scope"], "opponent_spell_pay_one_or_draw_engine_v1")
        self.assertEqual(primary["trigger"], "opponent_spell")
        self.assertEqual(primary["tax"], 1)
        self.assertFalse(primary["draw_on_enter"])

    def test_mystic_remora_maps_to_noncreature_tax_draw_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["MysticRemoraEffect", "OneShotEffect"],
                "ability_classes": ["CumulativeUpkeepAbility", "MysticRemoraTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "xmage_class_name": "MysticRemora",
                "raw_excerpt": (
                    "this.addAbility(new CumulativeUpkeepAbility(new ManaCostsImpl<>(\"{1}\"))); "
                    "Spell spell = game.getStack().getSpell(event.getTargetId()); "
                    "if (spell != null && !spell.isCreature(game)) { "
                    'this.staticText = "you may draw a card unless that player pays {4}"; }'
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "draw_engine")
        self.assertEqual(
            primary["battle_model_scope"],
            "opponent_noncreature_spell_pay_four_draw_engine_with_cumulative_upkeep_v1",
        )
        self.assertEqual(primary["trigger"], "opponent_noncreature_spell")
        self.assertEqual(primary["tax"], 4)
        self.assertEqual(primary["cumulative_upkeep_generic"], 1)
        self.assertFalse(primary["draw_on_enter"])

    def test_crop_rotation_maps_to_sacrifice_land_ramp_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInPlayEffect"],
                "cost_classes": ["SacrificeTargetCost"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "xmage_class_name": "CropRotation",
                "raw_excerpt": (
                    "this.getSpellAbility().addCost(new SacrificeTargetCost(StaticFilters.FILTER_LAND)); "
                    "this.getSpellAbility().addEffect(new SearchLibraryPutInPlayEffect("
                    "new TargetCardInLibrary(new FilterLandCard()), false, true));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "land_ramp")
        self.assertEqual(primary["battle_model_scope"], "sacrifice_land_for_any_land_to_battlefield_untapped_v1")
        self.assertTrue(primary["instant"])
        self.assertTrue(primary["requires_sacrifice_land"])
        self.assertFalse(primary["land_enters_tapped"])
        self.assertEqual(primary["tutor_target"], "land")

    def test_elvish_reclaimer_maps_to_land_tutor_growth_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["BoostSourceEffect", "ConditionalContinuousEffect", "SearchLibraryPutInPlayEffect"],
                "ability_classes": ["SimpleActivatedAbility", "SimpleStaticAbility"],
                "cost_classes": ["GenericManaCost", "SacrificeTargetCost", "TapSourceCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "xmage_class_name": "ElvishReclaimer",
                "raw_excerpt": (
                    "private static final Condition condition = new CardsInControllerGraveyardCondition(3, StaticFilters.FILTER_CARD_LAND); "
                    "this.addAbility(new SimpleStaticAbility(new ConditionalContinuousEffect("
                    "new BoostSourceEffect(2, 2, Duration.WhileOnBattlefield), condition, text))); "
                    "Ability ability = new SimpleActivatedAbility(new SearchLibraryPutInPlayEffect("
                    "new TargetCardInLibrary(StaticFilters.FILTER_CARD_LAND_A), true), new GenericManaCost(2)); "
                    "ability.addCost(new TapSourceCost()); ability.addCost(new SacrificeTargetCost(StaticFilters.FILTER_LAND));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "activated_land_tutor_with_land_sacrifice_and_graveyard_growth_v1",
        )
        self.assertTrue(primary["land_tutor_activated"])
        self.assertEqual(primary["activation_cost_generic"], 2)
        self.assertTrue(primary["activation_requires_tap"])
        self.assertTrue(primary["requires_sacrifice_land"])
        self.assertTrue(primary["land_enters_tapped"])
        self.assertTrue(primary["plus_two_two_if_three_lands_in_your_graveyard"])

    def test_chord_of_calling_maps_to_x_creature_tutor_to_battlefield_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryWithLessCMCPutInPlayEffect"],
                "ability_classes": ["ConvokeAbility"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "xmage_class_name": "ChordOfCalling",
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.INSTANT}, "{X}{G}{G}{G}"); '
                    "this.addAbility(new ConvokeAbility()); "
                    "this.getSpellAbility().addEffect(new SearchLibraryWithLessCMCPutInPlayEffect(StaticFilters.FILTER_CARD_CREATURE));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(
            primary["battle_model_scope"],
            "convoke_creature_tutor_to_battlefield_mana_value_x_or_less_v1",
        )
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["target"], "creature_to_battlefield")
        self.assertTrue(primary["target_mana_value_max_from_x"])
        self.assertTrue(primary["convoke"])

    def test_green_suns_zenith_maps_to_x_green_creature_tutor_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryWithLessCMCPutInPlayEffect", "ShuffleSpellEffect"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "xmage_class_name": "GreenSunsZenith",
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.SORCERY}, "{X}{G}"); '
                    'private static final FilterCard filter = new FilterCard("green creature card"); '
                    "filter.add(new ColorPredicate(ObjectColor.GREEN)); "
                    "filter.add(CardType.CREATURE.getPredicate()); "
                    "this.getSpellAbility().addEffect(new SearchLibraryWithLessCMCPutInPlayEffect(filter)); "
                    "this.getSpellAbility().addEffect(ShuffleSpellEffect.getInstance());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(
            primary["battle_model_scope"],
            "green_creature_tutor_to_battlefield_mana_value_x_or_less_then_shuffle_self_v1",
        )
        self.assertFalse(primary["instant"])
        self.assertEqual(primary["target"], "green_creature_to_battlefield")
        self.assertTrue(primary["target_mana_value_max_from_x"])
        self.assertTrue(primary["shuffle_self_into_library_on_resolution"])

    def test_whir_of_invention_maps_to_x_artifact_tutor_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryWithLessCMCPutInPlayEffect"],
                "ability_classes": ["ImproviseAbility"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "xmage_class_name": "WhirOfInvention",
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.INSTANT}, "{X}{U}{U}{U}"); '
                    "this.addAbility(new ImproviseAbility()); "
                    "this.getSpellAbility().addEffect(new SearchLibraryWithLessCMCPutInPlayEffect(StaticFilters.FILTER_CARD_ARTIFACT));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(
            primary["battle_model_scope"],
            "improvise_artifact_tutor_to_battlefield_mana_value_x_or_less_v1",
        )
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["target"], "artifact_to_battlefield")
        self.assertTrue(primary["target_mana_value_max_from_x"])
        self.assertTrue(primary["improvise"])

    def test_natures_rhythm_maps_to_x_creature_tutor_harmonize_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInPlayEffect"],
                "ability_classes": ["HarmonizeAbility"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "xmage_class_name": "NaturesRhythm",
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.SORCERY}, "{X}{G}{G}"); '
                    'private static final FilterCard filter = new FilterCreatureCard("a creature card with mana value X or less"); '
                    "this.getSpellAbility().addEffect(new SearchLibraryPutInPlayEffect(new TargetCardInLibrary(filter))); "
                    'this.addAbility(new HarmonizeAbility(this, "{X}{G}{G}{G}{G}")); '
                    "return input.getObject().getManaValue() <= GetXValue.instance.calculate(game, input.getSource(), null);"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "tutor")
        self.assertEqual(
            primary["battle_model_scope"],
            "creature_tutor_to_battlefield_mana_value_x_or_less_harmonize_v1",
        )
        self.assertFalse(primary["instant"])
        self.assertEqual(primary["target"], "creature_to_battlefield")
        self.assertTrue(primary["target_mana_value_max_from_x"])
        self.assertTrue(primary["harmonize"])

    def test_double_vision_maps_to_first_instant_sorcery_copy_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CopyTargetStackObjectEffect"],
                "ability_classes": ["DoubleVisionCopyTriggeredAbility", "SpellCastControllerTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "xmage_class_name": "DoubleVision",
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.ENCHANTMENT}, "{3}{R}{R}"); '
                    "this.addAbility(new DoubleVisionCopyTriggeredAbility()); "
                    "new CopyTargetStackObjectEffect(true); "
                    "isFirstInstantOrSorceryCastByPlayerOnTurn(spell, game);"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "copy_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "first_instant_sorcery_cast_each_turn_copy_own_spell_v1",
        )
        self.assertEqual(primary["trigger"], "instant_sorcery_cast")
        self.assertEqual(primary["trigger_effect"], "copy_spell")
        self.assertEqual(primary["target"], "own_instant_or_sorcery_on_stack")
        self.assertTrue(primary["may_choose_new_targets"])
        self.assertEqual(primary["choose_new_targets_status"], "may")
        self.assertTrue(primary["trigger_first_instant_or_sorcery_each_turn"])

    def test_swarm_intelligence_maps_to_instant_sorcery_copy_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CopyTargetStackObjectEffect"],
                "ability_classes": ["SpellCastControllerTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "xmage_class_name": "SwarmIntelligence",
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.ENCHANTMENT}, "{6}{U}"); '
                    "this.addAbility(new SpellCastControllerTriggeredAbility("
                    "new CopyTargetStackObjectEffect(true).setText(\"you may copy that spell. You may choose new targets for the copy\"), "
                    "new FilterInstantOrSorcerySpell(\"an instant or sorcery spell\"), true, SetTargetPointer.SPELL));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "copy_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "instant_sorcery_cast_copy_own_spell_v1",
        )
        self.assertEqual(primary["trigger"], "instant_sorcery_cast")
        self.assertEqual(primary["trigger_effect"], "copy_spell")
        self.assertEqual(primary["target"], "own_instant_or_sorcery_on_stack")
        self.assertTrue(primary["may_choose_new_targets"])
        self.assertEqual(primary["choose_new_targets_status"], "may")
        self.assertFalse(primary.get("trigger_first_instant_or_sorcery_each_turn", False))

    def test_pyromancer_ascension_maps_to_quest_counter_copy_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["AddCountersSourceEffect", "CopyTargetStackObjectEffect"],
                "ability_classes": [
                    "PyromancerAscensionQuestTriggeredAbility",
                    "PyromancerAscensionCopyTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "xmage_class_name": "PyromancerAscension",
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.ENCHANTMENT}, "{1}{R}"); '
                    "new AddCountersSourceEffect(CounterType.QUEST.createInstance(), true); "
                    "new CopyTargetStackObjectEffect(true); "
                    "Whenever you cast an instant or sorcery spell while Pyromancer Ascension has two or more quest counters on it, "
                    "you may copy that spell. You may choose new targets for the copy."
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "copy_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "pyromancer_ascension_quest_counter_copy_spell_v1",
        )
        self.assertEqual(primary["trigger"], "instant_sorcery_cast")
        self.assertEqual(primary["trigger_effect"], "pyromancer_ascension")
        self.assertEqual(primary["target"], "own_instant_or_sorcery_on_stack")
        self.assertTrue(primary["may_choose_new_targets"])
        self.assertTrue(primary["quest_counter_on_same_name_in_graveyard"])
        self.assertEqual(primary["quest_counter_name_match_zone"], "graveyard")
        self.assertEqual(primary["quest_counter_threshold_to_copy"], 2)

    def test_profound_journey_maps_to_permanent_rebound_recursion_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["ReturnFromGraveyardToBattlefieldTargetEffect"],
                "ability_classes": ["ReboundAbility"],
                "target_classes": ["TargetCardInYourGraveyard"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "xmage_class_name": "ProfoundJourney",
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.SORCERY}, "{5}{W}{W}"); '
                    'private static final FilterCard filter = new FilterPermanentCard("permanent card from your graveyard"); '
                    "this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect()); "
                    "this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(filter)); "
                    "this.addAbility(new ReboundAbility());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "recursion")
        self.assertEqual(
            primary["battle_model_scope"],
            "return_target_permanent_from_graveyard_to_battlefield_rebound_v1",
        )
        self.assertEqual(primary["target"], "permanent")
        self.assertEqual(primary["target_zone"], "graveyard")
        self.assertEqual(primary["target_controller"], "self")
        self.assertEqual(primary["destination"], "battlefield")
        self.assertEqual(primary["count"], 1)
        self.assertTrue(primary["rebound"])

    def test_candelabra_of_tawnos_maps_to_x_untap_lands_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["UntapTargetEffect"],
                "ability_classes": ["SimpleActivatedAbility"],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "xmage_class_name": "CandelabraOfTawnos",
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.ARTIFACT}, "{1}"); '
                    'Effect effect = new UntapTargetEffect(); effect.setText("untap X target lands"); '
                    'Ability ability = new SimpleActivatedAbility(effect, new ManaCostsImpl<>("{X}")); '
                    "ability.addCost(new TapSourceCost()); ability.setTargetAdjuster(new XTargetsCountAdjuster());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "untap_land_engine")
        self.assertEqual(primary["battle_model_scope"], "x_tap_untap_x_lands_v1")
        self.assertTrue(primary["activated_untap_lands_for_mana_unlock"])
        self.assertTrue(primary["activation_requires_tap"])
        self.assertTrue(primary["activation_cost_generic_from_x"])
        self.assertTrue(primary["untap_target_land_count_from_x"])
        self.assertEqual(primary["untap_target_land_restriction"], "land")

    def test_earthcraft_maps_to_tap_creature_untap_basic_land_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["UntapTargetEffect"],
                "ability_classes": ["SimpleActivatedAbility"],
                "cost_classes": ["TapTargetCost"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "xmage_class_name": "Earthcraft",
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.ENCHANTMENT}, "{1}{G}"); '
                    'new SimpleActivatedAbility(new UntapTargetEffect(), '
                    'new TapTargetCost(new TargetControlledPermanent(StaticFilters.FILTER_CONTROLLED_UNTAPPED_CREATURE))); '
                    'private static final FilterPermanent filterLand = new FilterLandPermanent("basic land");'
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "untap_land_engine")
        self.assertEqual(primary["battle_model_scope"], "tap_untapped_creature_untap_target_basic_land_v1")
        self.assertTrue(primary["activated_untap_lands_for_mana_unlock"])
        self.assertTrue(primary["activation_taps_untapped_creature_you_control"])
        self.assertEqual(primary["untap_target_land_count"], 1)
        self.assertEqual(primary["untap_target_land_restriction"], "land")
        self.assertTrue(primary["untap_target_land_basic_only"])

    def test_magus_of_the_candelabra_maps_to_creature_x_untap_lands_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["UntapTargetEffect"],
                "ability_classes": ["SimpleActivatedAbility"],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "xmage_class_name": "MagusOfTheCandelabra",
                "raw_excerpt": (
                    'super(ownerId, setInfo, new CardType[]{CardType.CREATURE}, "{G}"); '
                    "this.power = new MageInt(1); this.toughness = new MageInt(2); "
                    'Effect effect = new UntapTargetEffect(); effect.setText("untap X target lands"); '
                    'Ability ability = new SimpleActivatedAbility(effect, new ManaCostsImpl<>("{X}")); '
                    "ability.addCost(new TapSourceCost()); ability.setTargetAdjuster(new XTargetsCountAdjuster());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "untap_land_engine")
        self.assertEqual(primary["battle_model_scope"], "creature_x_tap_untap_x_lands_v1")
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 2)
        self.assertTrue(primary["activation_requires_tap"])
        self.assertTrue(primary["activation_cost_generic_from_x"])
        self.assertTrue(primary["untap_target_land_count_from_x"])

    def test_oboro_breezecaller_maps_to_return_land_untap_land_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["UntapTargetEffect"],
                "ability_classes": ["FlyingAbility", "SimpleActivatedAbility"],
                "cost_classes": ["GenericManaCost", "ReturnToHandChosenControlledPermanentCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "xmage_class_name": "OboroBreezecaller",
                "raw_excerpt": (
                    'super(ownerId,setInfo,new CardType[]{CardType.CREATURE},"{1}{U}"); '
                    "this.addAbility(FlyingAbility.getInstance()); "
                    "Ability ability = new SimpleActivatedAbility(new UntapTargetEffect(), new GenericManaCost(2)); "
                    "ability.addCost(new ReturnToHandChosenControlledPermanentCost(new TargetControlledPermanent(filter))); "
                    "ability.addTarget(new TargetLandPermanent());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "untap_land_engine")
        self.assertEqual(primary["battle_model_scope"], "pay_two_return_land_untap_target_land_v1")
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 1)
        self.assertTrue(primary["flying"])
        self.assertEqual(primary["activation_cost_generic"], 2)
        self.assertTrue(primary["activation_returns_land_to_hand"])
        self.assertEqual(primary["untap_target_land_count"], 1)

    def test_final_fortune_maps_to_single_extra_turn_then_lose_game_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["AddExtraTurnControllerEffect"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new AddExtraTurnControllerEffect(true)); "
                    "Take an extra turn after this one. At the beginning of that turn's end step, you lose the game."
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "extra_turn")
        self.assertEqual(primary["battle_model_scope"], "single_extra_turn_then_lose_game_v1")
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["turns"], 1)
        self.assertTrue(primary["lose_after_extra_turn"])

    def test_last_chance_maps_to_single_extra_turn_then_lose_game_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["AddExtraTurnControllerEffect"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new AddExtraTurnControllerEffect(true)); "
                    "Take an extra turn after this one. At the beginning of that turn's end step, you lose the game."
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "extra_turn")
        self.assertEqual(primary["battle_model_scope"], "single_extra_turn_then_lose_game_v1")
        self.assertFalse(primary["instant"])
        self.assertEqual(primary["turns"], 1)
        self.assertTrue(primary["lose_after_extra_turn"])

    def test_ancestral_memories_maps_to_top_dig_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "AncestralMemories",
                "effect_classes": ["LookLibraryAndPickControllerEffect"],
                "ability_classes": [],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": "this.getSpellAbility().addEffect(new LookLibraryAndPickControllerEffect(7, 2, PutCards.HAND, PutCards.GRAVEYARD));",
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "dig_to_hand")
        self.assertEqual(primary["battle_model_scope"], "look_top_n_pick_m_to_hand_rest_graveyard_v1")
        self.assertFalse(primary["instant"])
        self.assertEqual(primary["look_count"], 7)
        self.assertEqual(primary["pick_count"], 2)
        self.assertEqual(primary["selection_destination"], "hand")
        self.assertEqual(primary["remainder_destination"], "graveyard")

    def test_scattered_thoughts_maps_to_top_dig_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "ScatteredThoughts",
                "effect_classes": ["LookLibraryAndPickControllerEffect"],
                "ability_classes": [],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": "this.getSpellAbility().addEffect(new LookLibraryAndPickControllerEffect(4, 2, PutCards.HAND, PutCards.GRAVEYARD));",
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "dig_to_hand")
        self.assertEqual(primary["battle_model_scope"], "look_top_n_pick_m_to_hand_rest_graveyard_v1")
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["look_count"], 4)
        self.assertEqual(primary["pick_count"], 2)
        self.assertEqual(primary["selection_destination"], "hand")
        self.assertEqual(primary["remainder_destination"], "graveyard")

    def test_fact_or_fiction_maps_to_two_pile_reveal_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "FactOrFiction",
                "effect_classes": ["RevealAndSeparatePilesEffect"],
                "ability_classes": [],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new RevealAndSeparatePilesEffect("
                    "5, TargetController.OPPONENT, TargetController.YOU, Zone.GRAVEYARD));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "pile_selection_draw")
        self.assertEqual(
            primary["battle_model_scope"],
            "reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1",
        )
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["look_count"], 5)
        self.assertEqual(primary["splitter"], "opponent")
        self.assertEqual(primary["chooser"], "controller")
        self.assertEqual(primary["selection_destination"], "hand")
        self.assertEqual(primary["remainder_destination"], "graveyard")
        self.assertEqual(primary["pile_count"], 2)

    def test_steam_augury_maps_to_two_pile_reveal_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "SteamAugury",
                "effect_classes": ["RevealAndSeparatePilesEffect"],
                "ability_classes": [],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new RevealAndSeparatePilesEffect("
                    "5, TargetController.YOU, TargetController.OPPONENT, Zone.GRAVEYARD));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "pile_selection_draw")
        self.assertEqual(
            primary["battle_model_scope"],
            "reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1",
        )
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["look_count"], 5)
        self.assertEqual(primary["splitter"], "controller")
        self.assertEqual(primary["chooser"], "opponent")
        self.assertEqual(primary["selection_destination"], "hand")
        self.assertEqual(primary["remainder_destination"], "graveyard")
        self.assertEqual(primary["pile_count"], 2)

    def test_spellseeker_maps_to_etb_cheap_instant_or_sorcery_tutor_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInHandEffect"],
                "ability_classes": ["EntersBattlefieldTriggeredAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "xmage_class_name": "Spellseeker",
                "raw_excerpt": (
                    'private static final FilterInstantOrSorceryCard filter = new FilterInstantOrSorceryCard("an instant or sorcery card with mana value 2 or less"); '
                    "filter.add(new ManaValuePredicate(ComparisonType.FEWER_THAN, 3)); "
                    "this.addAbility(new EntersBattlefieldTriggeredAbility(new SearchLibraryPutInHandEffect(new TargetCardInLibrary(filter), true), true));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "spellseeker_etb_instant_or_sorcery_mana_value_2_or_less_to_hand_v1",
        )
        self.assertEqual(primary["etb_tutor_target"], "cheap_instant_or_sorcery")
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 1)

    def test_trophy_mage_maps_to_etb_artifact_mana_value_three_tutor_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInHandEffect"],
                "ability_classes": ["EntersBattlefieldTriggeredAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "xmage_class_name": "TrophyMage",
                "raw_excerpt": (
                    'private static final FilterCard filter = new FilterCard("an artifact card with mana value 3"); '
                    "filter.add(CardType.ARTIFACT.getPredicate()); "
                    "filter.add(new ManaValuePredicate(ComparisonType.EQUAL_TO, 3)); "
                    "this.addAbility(new EntersBattlefieldTriggeredAbility(new SearchLibraryPutInHandEffect(new TargetCardInLibrary(filter), true), true));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "trophy_mage_etb_artifact_mana_value_3_to_hand_v1")
        self.assertEqual(primary["etb_tutor_target"], "artifact_mana_value_3")
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 2)

    def test_starfield_shepherd_maps_to_basic_plains_or_small_creature_tutor_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["SearchLibraryPutInHandEffect"],
                "ability_classes": [
                    "EntersBattlefieldTriggeredAbility",
                    "FlyingAbility",
                    "WarpAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "xmage_class_name": "StarfieldShepherd",
                "raw_excerpt": (
                    'private static final FilterCard filter = new FilterCard("a basic Plains card or a creature card with mana value 1 or less"); '
                    "filter.add(Predicates.or("
                    "Predicates.and(SuperType.BASIC.getPredicate(), SubType.PLAINS.getPredicate()), "
                    "Predicates.and(CardType.CREATURE.getPredicate(), new ManaValuePredicate(ComparisonType.FEWER_THAN, 2))"
                    ")); "
                    "this.addAbility(new EntersBattlefieldTriggeredAbility("
                    "new SearchLibraryPutInHandEffect(new TargetCardInLibrary(filter), true)"
                    ")); this.addAbility(new WarpAbility(this, \"{1}{W}\"));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "starfield_shepherd_etb_basic_plains_or_creature_mana_value_1_or_less_to_hand_v1",
        )
        self.assertEqual(
            primary["etb_tutor_target"],
            "basic_plains_or_creature_mana_value_1_or_less",
        )
        self.assertEqual(primary["etb_tutor_status"], "runtime_library_to_hand")
        self.assertEqual(primary["power"], 3)
        self.assertEqual(primary["toughness"], 2)

    def test_carrion_feeder_maps_to_exact_sacrifice_self_growth_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["AddCountersSourceEffect"],
                "ability_classes": ["CantBlockAbility", "SimpleActivatedAbility"],
                "cost_classes": ["SacrificeTargetCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.addAbility(new CantBlockAbility()); "
                    "this.addAbility(new SimpleActivatedAbility("
                    "new AddCountersSourceEffect(CounterType.P1P1.createInstance()), "
                    "new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE)));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "sacrifice_creature_put_plus_one_counter_on_self_cant_block_v1",
        )
        self.assertTrue(primary["cant_block"])
        self.assertEqual(primary["activation_cost"], "sacrifice_creature")
        self.assertEqual(primary["self_add_plus_one_counter"], 1)

    def test_icatian_moneychanger_maps_to_exact_credit_counter_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["AddCountersSourceEffect", "DamageControllerEffect", "GainLifeEffect"],
                "ability_classes": [
                    "EntersBattlefieldAbility",
                    "EntersBattlefieldTriggeredAbility",
                    "BeginningOfUpkeepTriggeredAbility",
                    "ActivateIfConditionActivatedAbility",
                ],
                "cost_classes": ["SacrificeSourceCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "new AddCountersSourceEffect(CounterType.CREDIT.createInstance(3)) "
                    "new EntersBattlefieldTriggeredAbility(new DamageControllerEffect(3, \"it\")); "
                    "new BeginningOfUpkeepTriggeredAbility(new AddCountersSourceEffect(CounterType.CREDIT.createInstance())); "
                    "new ActivateIfConditionActivatedAbility(new GainLifeEffect(new CountersSourceCount(CounterType.CREDIT)), new SacrificeSourceCost(), IsStepCondition.getMyUpkeep())"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "credit_counter_upkeep_growth_sacrifice_for_life_v1",
        )
        self.assertEqual(primary["enters_with_credit_counters"], 3)
        self.assertEqual(primary["etb_damage_controller"], 3)
        self.assertEqual(primary["upkeep_add_credit_counter"], 1)
        self.assertTrue(primary["gain_life_per_credit_counter"])

    def test_warden_of_the_grove_maps_to_exact_endure_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["AddCountersSourceEffect", "EndureSourceEffect", "OneShotEffect", "WardenOfTheGroveEffect"],
                "ability_classes": ["BeginningOfEndStepTriggeredAbility", "EntersBattlefieldAllTriggeredAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.addAbility(new BeginningOfEndStepTriggeredAbility(new AddCountersSourceEffect(CounterType.P1P1.createInstance()))); "
                    "this.addAbility(new EntersBattlefieldAllTriggeredAbility(Zone.BATTLEFIELD, new WardenOfTheGroveEffect(), filter, false, SetTargetPointer.PERMANENT)); "
                    "staticText = \"it endures X, where X is the number of counters on {this}\";"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "end_step_plus_one_counter_and_other_nontoken_creature_endures_x_v1",
        )
        self.assertEqual(primary["end_step_add_plus_one_counter"], 1)
        self.assertTrue(primary["other_nontoken_creature_endures_equal_to_source_counters"])

    def test_wildborn_preserver_maps_to_exact_pay_x_counter_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["AddCountersSourceEffect"],
                "ability_classes": [
                    "FlashAbility",
                    "ReachAbility",
                    "EntersBattlefieldControlledTriggeredAbility",
                    "ReflexiveTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.addAbility(FlashAbility.getInstance()); "
                    "this.addAbility(ReachAbility.getInstance()); "
                    "this.addAbility(new EntersBattlefieldControlledTriggeredAbility(new WildbornPreserverCreateReflexiveTriggerEffect(), filter)); "
                    "filter = new FilterCreaturePermanent(\"another non-Human creature\"); "
                    "cost.add(new GenericManaCost(costX)); "
                    "game.fireReflexiveTriggeredAbility(new ReflexiveTriggeredAbility(new AddCountersSourceEffect(CounterType.P1P1.createInstance(costX)), false, \"put X +1/+1 counters on {this}\"), source);"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "flash_reach_nonhuman_etb_pay_x_put_x_plus_one_counters_on_self_v1",
        )
        self.assertTrue(primary["flash"])
        self.assertTrue(primary["reach"])
        self.assertTrue(primary["another_nonhuman_etb_optional_pay_x_for_x_plus_one_counters_on_self"])

    def test_colossal_skyturtle_maps_to_exact_channel_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "ReturnFromGraveyardToHandTargetEffect",
                    "ReturnToHandTargetEffect",
                ],
                "ability_classes": ["ChannelAbility", "FlyingAbility", "WardAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT", "CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(6); this.toughness = new MageInt(5); "
                    "this.addAbility(FlyingAbility.getInstance()); "
                    "this.addAbility(new WardAbility(new ManaCostsImpl<>(\"{2}\"), false)); "
                    "Ability ability = new ChannelAbility(\"{2}{G}\", new ReturnFromGraveyardToHandTargetEffect()); "
                    "ability = new ChannelAbility(\"{1}{U}\", new ReturnToHandTargetEffect());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "flying_ward_channel_regrowth_or_bounce_creature_v1",
        )
        self.assertEqual(primary["power"], 6)
        self.assertEqual(primary["toughness"], 5)
        self.assertTrue(primary["flying"])
        self.assertEqual(primary["ward_cost"], "{2}")
        self.assertEqual(primary["channel_return_graveyard_card_to_hand"], "{2}{G}")
        self.assertEqual(primary["channel_return_target_creature_to_hand"], "{1}{U}")

    def test_abigale_maps_to_exact_keyword_counter_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["LoseAllAbilitiesTargetEffect", "AddCountersTargetEffect"],
                "ability_classes": [
                    "EntersBattlefieldTriggeredAbility",
                    "FlyingAbility",
                    "FirstStrikeAbility",
                    "LifelinkAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(1); this.toughness = new MageInt(1); "
                    "this.addAbility(FlyingAbility.getInstance()); "
                    "this.addAbility(FirstStrikeAbility.getInstance()); "
                    "this.addAbility(LifelinkAbility.getInstance()); "
                    "new LoseAllAbilitiesTargetEffect(Duration.Custom).setText(\"up to one other target creature loses all abilities\"); "
                    "Put a flying counter, a first strike counter, and a lifelink counter on that creature"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_strip_other_creature_abilities_and_grant_keyword_counters_v1",
        )
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 1)
        self.assertTrue(primary["flying"])
        self.assertTrue(primary["first_strike"])
        self.assertTrue(primary["lifelink"])
        self.assertTrue(primary["etb_other_target_creature_loses_all_abilities"])
        self.assertEqual(
            primary["etb_grants_keyword_counters"],
            ["flying", "first_strike", "lifelink"],
        )

    def test_glen_elendra_archmage_maps_to_exact_counter_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CounterTargetEffect"],
                "ability_classes": ["SimpleActivatedAbility", "FlyingAbility", "PersistAbility"],
                "cost_classes": ["SacrificeSourceCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(2); this.toughness = new MageInt(2); "
                    "this.addAbility(FlyingAbility.getInstance()); "
                    "Ability ability = new SimpleActivatedAbility(new CounterTargetEffect(), new ManaCostsImpl<>(\"{U}\")); "
                    "ability.addCost(new SacrificeSourceCost()); "
                    "this.addAbility(new PersistAbility());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "flying_persist_sacrifice_self_counter_noncreature_spell_v1",
        )
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 2)
        self.assertTrue(primary["flying"])
        self.assertTrue(primary["persist"])
        self.assertEqual(primary["activated_counter_noncreature_spell_cost"], "{U}")
        self.assertEqual(primary["activation_cost"], "sacrifice_self")

    def test_borne_upon_a_wind_maps_to_exact_flash_draw_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CastAsThoughItHadFlashAllEffect", "DrawCardSourceControllerEffect"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect(new CastAsThoughItHadFlashAllEffect(Duration.EndOfTurn, filter)); "
                    "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1).concatBy(\"<br>\"));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "draw_cards")
        self.assertEqual(
            primary["battle_model_scope"],
            "draw_one_and_source_controller_spells_gain_flash_until_eot_v1",
        )
        self.assertEqual(primary["count"], 1)
        self.assertTrue(primary["instant"])
        self.assertTrue(primary["source_controller_spells_have_flash_until_eot"])

    def test_consecrated_sphinx_maps_to_exact_draw_two_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DrawCardSourceControllerEffect"],
                "ability_classes": ["ConsecratedSphinxTriggeredAbility", "FlyingAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(4); this.toughness = new MageInt(6); "
                    "this.addAbility(FlyingAbility.getInstance()); "
                    "this.addAbility(new ConsecratedSphinxTriggeredAbility()); "
                    "new DrawCardSourceControllerEffect(2)"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "flying_may_draw_two_when_opponent_draws_card_v1",
        )
        self.assertEqual(primary["power"], 4)
        self.assertEqual(primary["toughness"], 6)
        self.assertTrue(primary["flying"])
        self.assertEqual(primary["opponent_draws_card_may_draw"], 2)

    def test_fate_unraveler_maps_to_exact_opponent_draw_punisher_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DamageTargetEffect"],
                "ability_classes": ["DrawCardOpponentTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT", "CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(3); this.toughness = new MageInt(4); "
                    "this.addAbility(new DrawCardOpponentTriggeredAbility(new DamageTargetEffect(1).withTargetDescription(\"that player\"), false, true));"
                ),
                "oracle_text": "Whenever an opponent draws a card, Fate Unraveler deals 1 damage to that player.",
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "opponent_draws_card_damage_that_player_v1",
        )
        self.assertEqual(primary["power"], 3)
        self.assertEqual(primary["toughness"], 4)
        self.assertEqual(primary["trigger"], "opponent_draw")
        self.assertEqual(primary["opponent_draw_damage_per_card"], 1)

    def test_underworld_dreams_maps_to_exact_opponent_draw_punisher_passive_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DamageTargetEffect"],
                "ability_classes": ["DrawCardOpponentTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "this.addAbility(new DrawCardOpponentTriggeredAbility(new DamageTargetEffect(1).withTargetDescription(\"that player\"), false, true));"
                ),
                "oracle_text": "Whenever an opponent draws a card, Underworld Dreams deals 1 damage to that player.",
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "passive")
        self.assertEqual(
            primary["battle_model_scope"],
            "opponent_draws_card_damage_that_player_v1",
        )
        self.assertEqual(primary["trigger"], "opponent_draw")
        self.assertEqual(primary["opponent_draw_damage_per_card"], 1)

    def test_geths_grimoire_maps_to_exact_opponent_discard_draw_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "GethsGrimoire",
                "effect_classes": ["DrawCardSourceControllerEffect"],
                "ability_classes": ["DiscardsACardOpponentTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    "Effect drawTrigger = new DrawCardSourceControllerEffect(1); "
                    "drawTrigger.setText(\"you may draw a card.\"); "
                    "this.addAbility(new DiscardsACardOpponentTriggeredAbility(drawTrigger, true));"
                ),
            },
            "Whenever an opponent discards a card, you may draw a card.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "draw_engine")
        self.assertEqual(primary["battle_model_scope"], "opponent_discards_card_may_draw_v1")
        self.assertEqual(primary["trigger"], "opponent_discard")
        self.assertEqual(primary["opponent_discard_draw_per_card"], 1)
        self.assertFalse(primary["draw_on_enter"])

    def test_megrim_maps_to_exact_opponent_discard_damage_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Megrim",
                "effect_classes": ["DamageTargetEffect"],
                "ability_classes": ["DiscardsACardOpponentTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "this.addAbility(new DiscardsACardOpponentTriggeredAbility("
                    "new DamageTargetEffect(2).withTargetDescription(\"that player\"), false, SetTargetPointer.PLAYER));"
                ),
            },
            "Whenever an opponent discards a card, Megrim deals 2 damage to that player.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "passive")
        self.assertEqual(primary["battle_model_scope"], "opponent_discards_card_damage_that_player_v1")
        self.assertEqual(primary["trigger"], "opponent_discard")
        self.assertEqual(primary["opponent_discard_damage_per_card"], 2)

    def test_feast_of_sanity_maps_to_exact_controller_discard_damage_and_lifegain_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "FeastOfSanity",
                "effect_classes": ["DamageTargetEffect", "GainLifeEffect"],
                "ability_classes": ["DiscardCardControllerTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "Ability ability = new DiscardCardControllerTriggeredAbility(new DamageTargetEffect(1), false); "
                    "ability.addEffect(new GainLifeEffect(1).concatBy(\"and\")); "
                    "ability.addTarget(new TargetAnyTarget());"
                ),
            },
            "Whenever you discard a card, Feast of Sanity deals 1 damage to any target and you gain 1 life.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "passive")
        self.assertEqual(
            primary["battle_model_scope"],
            "controller_discards_card_damage_any_target_and_gain_life_v1",
        )
        self.assertEqual(primary["trigger"], "controller_discard")
        self.assertEqual(primary["controller_discard_damage_any_target"], 1)
        self.assertEqual(primary["controller_discard_gain_life"], 1)

    def test_glint_horn_buccaneer_maps_to_exact_attack_loot_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "GlintHornBuccaneer",
                "effect_classes": [
                    "DamagePlayersEffect",
                    "DrawCardSourceControllerEffect",
                ],
                "ability_classes": [
                    "ActivateIfConditionActivatedAbility",
                    "HasteAbility",
                    "TriggeredAbilityImpl",
                ],
                "cost_classes": ["DiscardCardCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.addAbility(HasteAbility.getInstance()); "
                    "new DamagePlayersEffect(1, TargetController.OPPONENT); "
                    "event.getType() == GameEvent.EventType.DISCARDED_CARD; "
                    "isControlledBy(event.getPlayerId()); "
                    "new ActivateIfConditionActivatedAbility(new DrawCardSourceControllerEffect(1), "
                    "new ManaCostsImpl<>(\"{1}{R}\"), SourceAttackingCondition.instance); "
                    "ability.addCost(new DiscardCardCost());"
                ),
            },
            (
                "Haste. Whenever you discard a card, Glint-Horn Buccaneer deals 1 damage "
                "to each opponent. {1}{R}, Discard a card: Draw a card. Activate only if "
                "Glint-Horn Buccaneer is attacking."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "glint_horn_buccaneer_discard_damage_attack_loot_v1",
        )
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 4)
        self.assertTrue(primary["haste"])
        self.assertEqual(primary["trigger"], "controller_discard")
        self.assertEqual(primary["controller_discard_damage_each_opponent"], 1)
        self.assertTrue(primary["attacking_activated_discard_draw"])
        self.assertEqual(primary["attacking_activated_discard_draw_cost"], "{1}{R}")
        self.assertEqual(primary["attacking_activated_discard_count"], 1)
        self.assertEqual(primary["attacking_activated_draw_count"], 1)

    def test_boltwave_maps_to_spell_damage_each_opponent_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Boltwave",
                "effect_classes": ["DamagePlayersEffect"],
                "ability_classes": [],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addEffect("
                    "new DamagePlayersEffect(3, TargetController.OPPONENT));"
                ),
            },
            "Boltwave deals 3 damage to each opponent.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "damage_each_opponent")
        self.assertEqual(primary["battle_model_scope"], "spell_damage_each_opponent_v1")
        self.assertEqual(primary["amount"], 3)
        self.assertEqual(primary["damage"], 3)
        self.assertEqual(primary["target_controller"], "opponents")
        self.assertFalse(primary["instant"])
        self.assertTrue(primary["sorcery"])

    def test_soul_immolation_maps_to_blight_x_opponent_damage_sweep_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "SoulImmolation",
                "effect_classes": ["DamagePlayersEffect", "DamageAllEffect"],
                "ability_classes": [],
                "cost_classes": ["BlightCost"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addCost(new SoulImmolationCost()); "
                    "GreatestAmongPermanentsValue.TOUGHNESS_CONTROLLED_CREATURES.getHint(); "
                    "new DamagePlayersEffect(GetXValue.instance, TargetController.OPPONENT); "
                    "new DamageAllEffect(GetXValue.instance, StaticFilters.FILTER_OPPONENTS_PERMANENT_CREATURES);"
                ),
            },
            (
                "As an additional cost to cast this spell, blight X. X can't be greater than the greatest "
                "toughness among creatures you control. Soul Immolation deals X damage to each opponent "
                "and each creature they control."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "damage_each_opponent_and_opponent_creatures")
        self.assertEqual(
            primary["battle_model_scope"],
            "blight_x_damage_each_opponent_and_opponent_creatures_v1",
        )
        self.assertTrue(primary["requires_blight_x"])
        self.assertEqual(primary["x_value_source"], "blight_greatest_toughness_controlled_creature")
        self.assertEqual(primary["additional_cost_kind"], "blight_x")
        self.assertEqual(primary["target_controller"], "opponents")
        self.assertEqual(primary["damage_amount_source"], "x_value")
        self.assertTrue(primary["sorcery"])

    def test_armageddon_maps_to_destroy_all_lands_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Armageddon",
                "effect_classes": ["DestroyAllEffect"],
                "ability_classes": [],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": "new DestroyAllEffect(StaticFilters.FILTER_LANDS)",
            },
            "Destroy all lands.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "board_wipe")
        self.assertEqual(primary["battle_model_scope"], "destroy_all_lands_v1")
        self.assertEqual(primary["destroy_card_types"], ["land"])
        self.assertTrue(primary["destroy_all_lands"])
        self.assertEqual(primary["destination"], "graveyard")
        self.assertTrue(primary["sorcery"])

    def test_ultima_maps_to_artifact_creature_wipe_then_end_turn_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Ultima",
                "effect_classes": ["DestroyAllEffect", "EndTurnEffect"],
                "ability_classes": [],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["SORCERY"]},
                "raw_excerpt": (
                    'FilterPermanent filter = new FilterPermanent("artifacts and creatures"); '
                    "filter.add(Predicates.or(CardType.ARTIFACT.getPredicate(), "
                    "CardType.CREATURE.getPredicate())); "
                    "this.getSpellAbility().addEffect(new DestroyAllEffect(filter)); "
                    "this.getSpellAbility().addEffect(new EndTurnEffect());"
                ),
            },
            "Destroy all artifacts and creatures. End the turn.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "board_wipe")
        self.assertEqual(
            primary["battle_model_scope"],
            "destroy_all_artifacts_and_creatures_end_turn_v1",
        )
        self.assertEqual(primary["destroy_card_types"], ["artifact", "creature"])
        self.assertTrue(primary["destroy_all_artifacts"])
        self.assertTrue(primary["destroy_all_creatures"])
        self.assertTrue(primary["end_the_turn"])
        self.assertEqual(primary["turn_end_scope"], "current_turn_after_resolution")
        self.assertEqual(primary["destination"], "graveyard")
        self.assertTrue(primary["sorcery"])

    def test_agate_instigator_maps_to_another_creature_enter_damage_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "AgateInstigator",
                "effect_classes": ["DamagePlayersEffect"],
                "ability_classes": ["EntersBattlefieldControlledTriggeredAbility", "OffspringAbility"],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(1); this.toughness = new MageInt(3); "
                    "this.addAbility(new EntersBattlefieldControlledTriggeredAbility("
                    "new DamagePlayersEffect(1, TargetController.OPPONENT), "
                    "StaticFilters.FILTER_ANOTHER_CREATURE));"
                ),
            },
            "Whenever another creature you control enters, this creature deals 1 damage to each opponent.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "controlled_creature_enters_damage_each_opponent_v1",
        )
        self.assertEqual(primary["trigger"], "creature_you_control_enters")
        self.assertEqual(primary["trigger_effect"], "damage_each_opponent")
        self.assertEqual(primary["trigger_damage_each_opponent"], 1)
        self.assertTrue(primary["trigger_another_creature_you_control_enters"])
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 3)

    def test_impact_tremors_maps_to_creature_enter_damage_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "ImpactTremors",
                "effect_classes": ["DamagePlayersEffect"],
                "ability_classes": ["EntersBattlefieldControlledTriggeredAbility"],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "new EntersBattlefieldControlledTriggeredAbility("
                    "Zone.BATTLEFIELD, new DamagePlayersEffect(Outcome.Damage, "
                    "StaticValue.get(1), TargetController.OPPONENT), "
                    "StaticFilters.FILTER_PERMANENT_A_CREATURE, false)"
                ),
            },
            "Whenever a creature you control enters, Impact Tremors deals 1 damage to each opponent.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "passive")
        self.assertEqual(
            primary["battle_model_scope"],
            "controlled_creature_enters_damage_each_opponent_v1",
        )
        self.assertTrue(primary["trigger_creature_you_control_enters"])
        self.assertFalse(primary["trigger_another_creature_you_control_enters"])
        self.assertEqual(primary["target_controller"], "opponents")

    def test_coruscation_mage_maps_to_noncreature_spell_cast_damage_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "CoruscationMage",
                "effect_classes": ["DamagePlayersEffect"],
                "ability_classes": ["OffspringAbility", "SpellCastControllerTriggeredAbility"],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(2); this.toughness = new MageInt(2); "
                    "this.addAbility(new SpellCastControllerTriggeredAbility("
                    "new DamagePlayersEffect(1, TargetController.OPPONENT, \"this creature\"), "
                    "StaticFilters.FILTER_SPELL_A_NON_CREATURE, false));"
                ),
            },
            "Whenever you cast a noncreature spell, this creature deals 1 damage to each opponent.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "noncreature_spell_cast_damage_each_opponent_v1",
        )
        self.assertEqual(primary["trigger"], "noncreature_spell_cast")
        self.assertEqual(primary["trigger_effect"], "damage_each_opponent")
        self.assertEqual(primary["trigger_damage_each_opponent"], 1)
        self.assertEqual(primary["damage"], 1)
        self.assertEqual(primary["target_controller"], "opponents")
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 2)

    def test_xmage_another_predicate_marks_creature_enter_damage_as_another_only(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "PurphorosGodOfTheForge",
                "effect_classes": ["DamagePlayersEffect", "BoostControlledEffect", "LoseCreatureTypeSourceEffect"],
                "ability_classes": [
                    "EntersBattlefieldControlledTriggeredAbility",
                    "SimpleActivatedAbility",
                    "SimpleStaticAbility",
                ],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["ENCHANTMENT", "CREATURE"]},
                "raw_excerpt": (
                    'private static final FilterPermanent filter = new FilterCreaturePermanent("another creature"); '
                    "filter.add(AnotherPredicate.instance); "
                    "new EntersBattlefieldControlledTriggeredAbility("
                    "new DamagePlayersEffect(2, TargetController.OPPONENT), filter)"
                ),
            },
            "Whenever another creature you control enters, Purphoros deals 2 damage to each opponent.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "controlled_creature_enters_damage_each_opponent_v1",
        )
        self.assertEqual(primary["trigger_damage_each_opponent"], 2)
        self.assertTrue(primary["trigger_another_creature_you_control_enters"])

    def test_young_pyromancer_maps_to_exact_spell_cast_elemental_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "YoungPyromancer",
                "effect_classes": ["CreateTokenEffect"],
                "ability_classes": ["SpellCastControllerTriggeredAbility"],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "new SpellCastControllerTriggeredAbility("
                    "new CreateTokenEffect(new RedElementalToken()), "
                    "StaticFilters.FILTER_SPELL_AN_INSTANT_OR_SORCERY, false)"
                ),
            },
            (
                "Whenever you cast an instant or sorcery spell, create a 1/1 red "
                "Elemental creature token."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "token_maker")
        self.assertEqual(
            primary["battle_model_scope"],
            "instant_sorcery_cast_create_1_1_red_elemental_v1",
        )
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 1)
        self.assertEqual(primary["trigger"], "instant_sorcery_cast")
        self.assertEqual(primary["trigger_effect"], "token_maker")
        self.assertEqual(primary["trigger_token_count"], 1)
        self.assertEqual(primary["token_name"], "Elemental Token")
        self.assertEqual(primary["token_subtype"], "Elemental")
        self.assertEqual(primary["token_colors"], ["R"])
        self.assertEqual(primary["token_power"], 1)
        self.assertEqual(primary["token_toughness"], 1)

    def test_monastery_mentor_maps_to_noncreature_spell_cast_monk_prowess_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "MonasteryMentor",
                "effect_classes": ["CreateTokenEffect"],
                "ability_classes": ["ProwessAbility", "SpellCastControllerTriggeredAbility"],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.addAbility(new ProwessAbility());"
                    "new SpellCastControllerTriggeredAbility("
                    "new CreateTokenEffect(new MonasteryMentorToken()), "
                    "StaticFilters.FILTER_SPELL_A_NON_CREATURE, false)"
                ),
            },
            (
                "Prowess\nWhenever you cast a noncreature spell, create a 1/1 "
                "white Monk creature token with prowess."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "token_maker")
        self.assertEqual(
            primary["battle_model_scope"],
            "noncreature_spell_cast_create_1_1_white_monk_prowess_v1",
        )
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 2)
        self.assertTrue(primary["prowess"])
        self.assertEqual(primary["trigger"], "noncreature_spell_cast")
        self.assertEqual(primary["trigger_effect"], "token_maker")
        self.assertEqual(primary["trigger_token_count"], 1)
        self.assertEqual(primary["token_name"], "Monk Token")
        self.assertEqual(primary["token_subtype"], "Monk")
        self.assertEqual(primary["token_colors"], ["W"])
        self.assertEqual(primary["token_power"], 1)
        self.assertEqual(primary["token_toughness"], 1)
        self.assertEqual(primary["token_keywords"], ["prowess"])
        self.assertTrue(primary["token_prowess"])

    def test_utvara_hellkite_maps_to_dragon_attack_token_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "UtvaraHellkite",
                "effect_classes": ["CreateTokenEffect"],
                "ability_classes": [
                    "AttacksCreatureYouControlTriggeredAbility",
                    "FlyingAbility",
                ],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "filter.add(SubType.DRAGON.getPredicate());"
                    "new AttacksCreatureYouControlTriggeredAbility("
                    "new CreateTokenEffect(new UtvaraHellkiteDragonToken()), false, filter)"
                ),
            },
            (
                "Flying\nWhenever a Dragon you control attacks, create a 6/6 "
                "red Dragon creature token with flying."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "token_maker")
        self.assertEqual(
            primary["battle_model_scope"],
            "dragon_you_control_attacks_create_6_6_red_flying_dragon_v1",
        )
        self.assertEqual(primary["power"], 6)
        self.assertEqual(primary["toughness"], 6)
        self.assertTrue(primary["flying"])
        self.assertEqual(primary["trigger"], "dragon_you_control_attacks")
        self.assertEqual(primary["trigger_effect"], "token_maker")
        self.assertEqual(primary["trigger_token_count"], 1)
        self.assertEqual(primary["trigger_attacking_creature_subtype"], "Dragon")
        self.assertEqual(primary["token_name"], "Dragon Token")
        self.assertEqual(primary["token_subtype"], "Dragon")
        self.assertEqual(primary["token_colors"], ["R"])
        self.assertEqual(primary["token_power"], 6)
        self.assertEqual(primary["token_toughness"], 6)
        self.assertTrue(primary["token_flying"])
        self.assertEqual(primary["token_keywords"], ["flying"])

    def test_blaze_commando_maps_to_spell_damage_soldier_token_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "BlazeCommando",
                "effect_classes": ["CreateTokenEffect"],
                "ability_classes": ["SpellControlledDealsDamageTriggeredAbility"],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "new SpellControlledDealsDamageTriggeredAbility(Zone.BATTLEFIELD, "
                    "new CreateTokenEffect(new SoldierHasteToken(), 2), "
                    "StaticFilters.FILTER_SPELL_INSTANT_OR_SORCERY, false)"
                ),
            },
            (
                "Whenever an instant or sorcery spell you control deals damage, "
                "create two 1/1 red and white Soldier creature tokens with haste."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "token_maker")
        self.assertEqual(
            primary["battle_model_scope"],
            "instant_sorcery_spell_damage_create_two_1_1_red_white_soldier_haste_v1",
        )
        self.assertEqual(primary["power"], 5)
        self.assertEqual(primary["toughness"], 3)
        self.assertEqual(primary["trigger"], "instant_sorcery_spell_you_control_deals_damage")
        self.assertEqual(primary["trigger_effect"], "token_maker")
        self.assertEqual(primary["trigger_token_count"], 2)
        self.assertEqual(primary["token_count"], 2)
        self.assertEqual(primary["token_name"], "Soldier Token")
        self.assertEqual(primary["token_subtype"], "Soldier")
        self.assertEqual(primary["token_colors"], ["R", "W"])
        self.assertEqual(primary["token_power"], 1)
        self.assertEqual(primary["token_toughness"], 1)
        self.assertTrue(primary["token_haste"])
        self.assertEqual(primary["token_keywords"], ["haste"])

    def test_cool_but_rude_maps_to_exact_class_attack_rummage_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "CoolButRude",
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
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "new AttacksWithCreaturesTriggeredAbility(new DoIfCostPaid("
                    "new DrawCardSourceControllerEffect(1), new DiscardCardCost()), 1); "
                    "new ClassLevelAbility(2, \"{1}{R}\"); "
                    "new GainClassAbilitySourceEffect(new DiscardCardControllerTriggeredAbility("
                    "new DamagePlayersEffect(2, TargetController.OPPONENT), false), 2); "
                    "new ClassLevelAbility(3, \"{1}{R}\"); "
                    "new BecomesClassLevelTriggeredAbility(new SearchLibraryPutInHandEffect("
                    "new TargetCardInLibrary(), false), 3); "
                    "ability.addEffect(new DiscardControllerEffect(1, true));"
                ),
            },
            (
                "Whenever you attack, you may discard a card. If you do, draw a card. "
                "{1}{R}: Level 2. Whenever you discard a card, this Class deals 2 damage "
                "to each opponent. {1}{R}: Level 3. When this Class becomes level 3, "
                "search your library for a card, put it into your hand, shuffle, then "
                "discard a card at random."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "draw_engine")
        self.assertEqual(
            primary["battle_model_scope"],
            "cool_but_rude_class_attack_rummage_level_damage_tutor_v1",
        )
        self.assertFalse(primary["draw_on_enter"])
        self.assertEqual(primary["class_level_start"], 1)
        self.assertEqual(primary["class_level_costs"], {"2": "{1}{R}", "3": "{1}{R}"})
        self.assertTrue(primary["attack_trigger_optional_discard_draw"])
        self.assertEqual(primary["trigger"], "controller_discard")
        self.assertEqual(primary["controller_discard_damage_each_opponent"], 2)
        self.assertEqual(primary["controller_discard_damage_each_opponent_level_min"], 2)
        self.assertTrue(primary["class_level3_tutor_any_to_hand_random_discard"])

    def test_invoke_calamity_maps_to_exact_free_cast_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "InvokeCalamity",
                "effect_classes": [
                    "ExileSpellEffect",
                    "InvokeCalamityEffect",
                    "InvokeCalamityReplacementEffect",
                    "OneShotEffect",
                ],
                "ability_classes": [],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "CardUtil.castMultipleWithAttributeForFree(player, source, game, cards, "
                    "StaticFilters.FILTER_CARD_INSTANT_OR_SORCERY, 2, new InvokeCalamityTracker()); "
                    "return card.getManaValue() + totalManaValue <= 6; "
                    "new InvokeCalamityReplacementEffect(card.getId()); "
                    "this.getSpellAbility().addEffect(new ExileSpellEffect());"
                ),
            },
            (
                "You may cast up to two instant and/or sorcery spells with total mana value "
                "6 or less from your graveyard and/or hand without paying their mana costs. "
                "If those spells would be put into your graveyard, exile them instead. "
                "Exile Invoke Calamity."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "free_cast")
        self.assertEqual(
            primary["battle_model_scope"],
            "cast_up_to_two_instant_sorcery_hand_graveyard_total_mv_lte_6_exile_replacement_v1",
        )
        self.assertEqual(primary["free_cast_from_zones"], ["hand", "graveyard"])
        self.assertEqual(primary["free_cast_card_types"], ["instant", "sorcery"])
        self.assertEqual(primary["free_cast_max_count"], 2)
        self.assertEqual(primary["free_cast_total_mana_value_max"], 6)
        self.assertTrue(primary["cast_without_paying_mana_cost"])
        self.assertTrue(primary["selected_spells_exile_instead_of_graveyard"])
        self.assertTrue(primary["exiles_self"])

    def test_lightning_helix_maps_to_exact_damage_any_target_and_lifegain_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "LightningHelix",
                "effect_classes": ["DamageTargetEffect", "GainLifeEffect"],
                "ability_classes": [],
                "target_classes": ["TargetAnyTarget"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().addTarget(new TargetAnyTarget()); "
                    "this.getSpellAbility().addEffect(new DamageTargetEffect(3)); "
                    "this.getSpellAbility().addEffect(new GainLifeEffect(3).concatBy(\"and\"));"
                ),
            },
            "Lightning Helix deals 3 damage to any target and you gain 3 life.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "direct_damage")
        self.assertEqual(primary["battle_model_scope"], "damage_any_target_and_gain_life_v1")
        self.assertEqual(primary["damage"], 3)
        self.assertEqual(primary["gain_life"], 3)
        self.assertEqual(primary["target"], "any_target")
        self.assertTrue(primary["instant"])

    def test_repercussion_maps_to_global_creature_damage_reflect_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Repercussion",
                "effect_classes": ["DamageTargetEffect"],
                "ability_classes": ["DealtDamageAnyTriggeredAbility"],
                "target_classes": [],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "this.addAbility(new DealtDamageAnyTriggeredAbility("
                    "new DamageTargetEffect(SavedDamageValue.MUCH), "
                    "StaticFilters.FILTER_PERMANENT_A_CREATURE, SetTargetPointer.PLAYER, false));"
                ),
            },
            "Whenever a creature is dealt damage, Repercussion deals that much damage to that creature's controller.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "passive")
        self.assertEqual(primary["battle_model_scope"], "creature_damage_controller_reflect_global_v1")
        self.assertEqual(primary["ability_kind"], "triggered_static_enchantment")
        self.assertEqual(primary["trigger"], "creature_dealt_damage")
        self.assertEqual(primary["trigger_effect"], "damage_creature_controller")
        self.assertEqual(primary["damage_amount_source"], "damage_dealt_to_creature")
        self.assertTrue(primary["global_creature_damage_reflect_to_controller"])

    def test_boros_reckoner_maps_to_source_damaged_reflect_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "BorosReckoner",
                "effect_classes": ["DamageTargetEffect", "GainAbilitySourceEffect"],
                "ability_classes": [
                    "DealtDamageToSourceTriggeredAbility",
                    "FirstStrikeAbility",
                    "SimpleActivatedAbility",
                ],
                "dynamic_value_classes": ["SavedDamageValue"],
                "target_classes": ["TargetAnyTarget"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(3); this.toughness = new MageInt(3); "
                    "Ability ability = new DealtDamageToSourceTriggeredAbility("
                    "new DamageTargetEffect(SavedDamageValue.MUCH, \"it\"), false); "
                    "ability.addTarget(new TargetAnyTarget()); "
                    "this.addAbility(new SimpleActivatedAbility(new GainAbilitySourceEffect("
                    "FirstStrikeAbility.getInstance(), Duration.EndOfTurn), new ManaCostsImpl<>(\"{R/W}\")));"
                ),
            },
            (
                "Whenever Boros Reckoner is dealt damage, it deals that much damage to any target. "
                "{R/W}: Boros Reckoner gains first strike until end of turn."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "source_dealt_damage_reflect_to_any_target_v1")
        self.assertEqual(primary["power"], 3)
        self.assertEqual(primary["toughness"], 3)
        self.assertEqual(primary["trigger"], "source_dealt_damage")
        self.assertEqual(primary["trigger_effect"], "damage_any_target")
        self.assertEqual(primary["damage_amount_source"], "damage_dealt_to_source")
        self.assertTrue(primary["source_damage_reflect_to_any_target"])
        self.assertEqual(primary["target"], "any_target")
        self.assertTrue(primary["activated_gain_first_strike_until_eot"])
        self.assertEqual(primary["first_strike_activation_cost"], "{R/W}")

    def test_terror_of_the_peaks_maps_to_etb_power_damage_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "TerrorOfThePeaks",
                "effect_classes": ["DamageTargetEffect", "TerrorOfThePeaksCostIncreaseEffect"],
                "ability_classes": [
                    "EntersBattlefieldControlledTriggeredAbility",
                    "FlyingAbility",
                    "SimpleStaticAbility",
                    "SpellAbility",
                ],
                "cost_classes": ["PayLifeCost"],
                "target_classes": ["TargetAnyTarget"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(5); this.toughness = new MageInt(4); "
                    "this.addAbility(FlyingAbility.getInstance()); "
                    "this.addAbility(new SimpleStaticAbility(new TerrorOfThePeaksCostIncreaseEffect())); "
                    "Ability ability = new EntersBattlefieldControlledTriggeredAbility("
                    "new DamageTargetEffect(TerrorOfThePeaksValue.instance), "
                    "StaticFilters.FILTER_ANOTHER_CREATURE); "
                    "ability.addTarget(new TargetAnyTarget());"
                ),
            },
            (
                "Flying. Spells your opponents cast that target Terror of the Peaks cost an additional 3 life to cast. "
                "Whenever another creature you control enters, Terror of the Peaks deals damage equal to that creature's power to any target."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "controlled_other_creature_enters_power_damage_any_target_v1",
        )
        self.assertEqual(primary["power"], 5)
        self.assertEqual(primary["toughness"], 4)
        self.assertTrue(primary["flying"])
        self.assertEqual(primary["trigger"], "creature_you_control_enters")
        self.assertEqual(primary["trigger_effect"], "damage_any_target")
        self.assertEqual(primary["trigger_damage_amount_source"], "entering_creature_power")
        self.assertTrue(primary["trigger_another_creature_you_control_enters"])
        self.assertEqual(primary["target"], "any_target")
        self.assertEqual(primary["opponent_spells_targeting_this_additional_life_cost"], 3)

    def test_firesong_and_sunspeaker_maps_to_lifelink_lifegain_damage_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "FiresongAndSunspeaker",
                "effect_classes": ["DamageTargetEffect", "GainAbilityControlledSpellsEffect"],
                "ability_classes": [
                    "FiresongAndSunspeakerTriggeredAbility",
                    "LifelinkAbility",
                    "SimpleStaticAbility",
                ],
                "target_classes": ["TargetCreatureOrPlayer"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(4); this.toughness = new MageInt(6); "
                    "Effect effect = new GainAbilityControlledSpellsEffect("
                    "LifelinkAbility.getInstance(), filter); "
                    "this.addAbility(new SimpleStaticAbility(effect)); "
                    "this.addAbility(new FiresongAndSunspeakerTriggeredAbility()); "
                    "super(Zone.BATTLEFIELD, new DamageTargetEffect(3), false); "
                    "this.addTarget(new TargetCreatureOrPlayer());"
                ),
            },
            (
                "Red instant and sorcery spells you control have lifelink. "
                "Whenever a white instant or sorcery spell causes you to gain life, "
                "Firesong and Sunspeaker deals 3 damage to any target."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "red_instant_sorcery_lifelink_white_lifegain_damage_v1",
        )
        self.assertEqual(primary["power"], 4)
        self.assertEqual(primary["toughness"], 6)
        self.assertTrue(primary["instant_sorcery_spells_you_control_have_lifelink"])
        self.assertEqual(primary["instant_sorcery_lifelink_colors"], ["R"])
        self.assertEqual(primary["trigger"], "white_instant_sorcery_lifegain")
        self.assertEqual(primary["trigger_effect"], "damage_any_target")
        self.assertEqual(primary["white_instant_sorcery_lifegain_trigger_damage"], 3)
        self.assertEqual(primary["target"], "any_target")

    def test_balefire_liege_maps_to_spell_color_damage_life_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "BalefireLiege",
                "effect_classes": [
                    "BoostControlledEffect",
                    "DamageTargetEffect",
                    "GainLifeEffect",
                ],
                "ability_classes": [
                    "SimpleStaticAbility",
                    "SpellCastControllerTriggeredAbility",
                ],
                "target_classes": ["TargetPlayerOrPlaneswalker"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(2); this.toughness = new MageInt(4); "
                    "this.addAbility(new SimpleStaticAbility(new BoostControlledEffect(1, 1, "
                    "Duration.WhileOnBattlefield, filterRed, true))); "
                    "this.addAbility(new SimpleStaticAbility(new BoostControlledEffect(1, 1, "
                    "Duration.WhileOnBattlefield, filterWhite, true))); "
                    "this.addAbility(new SpellCastControllerTriggeredAbility("
                    "new DamageTargetEffect(3), filterRedSpell, false)); "
                    "this.addTarget(new TargetPlayerOrPlaneswalker()); "
                    "this.addAbility(new SpellCastControllerTriggeredAbility("
                    "new GainLifeEffect(3), filterWhiteSpell, false));"
                ),
            },
            (
                "Other red creatures you control get +1/+1. Other white creatures you control get +1/+1. "
                "Whenever you cast a red spell, Balefire Liege deals 3 damage to target player or planeswalker. "
                "Whenever you cast a white spell, you gain 3 life."
            ),
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "red_spell_damage_white_spell_lifegain_static_creature_boost_v1",
        )
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 4)
        self.assertEqual(primary["trigger"], "spell_cast")
        self.assertEqual(primary["trigger_effect"], "spell_color_damage_life")
        self.assertEqual(primary["red_spell_trigger_damage"], 3)
        self.assertEqual(primary["red_spell_trigger_damage_target"], "player_or_planeswalker")
        self.assertEqual(primary["white_spell_trigger_gain_life"], 3)
        self.assertEqual(
            primary["static_boost_other_red_creatures_you_control"],
            {"power": 1, "toughness": 1},
        )
        self.assertEqual(
            primary["static_boost_other_white_creatures_you_control"],
            {"power": 1, "toughness": 1},
        )

    def test_caldera_pyremaw_maps_to_counter_then_power_damage_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "CalderaPyremaw",
                "effect_classes": ["AddCountersSourceEffect", "DamageTargetEffect"],
                "ability_classes": ["FlyingAbility", "SpellCastControllerTriggeredAbility"],
                "target_classes": ["TargetOpponent"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(3); this.toughness = new MageInt(3); "
                    "this.addAbility(FlyingAbility.getInstance()); "
                    "Ability ability = new SpellCastControllerTriggeredAbility("
                    "new AddCountersSourceEffect(CounterType.P1P1.createInstance()), "
                    "StaticFilters.FILTER_SPELL_AN_INSTANT_OR_SORCERY, false); "
                    "ability.addEffect(new DamageTargetEffect(SourcePermanentPowerValue.NOT_NEGATIVE)); "
                    "ability.addTarget(new TargetOpponent());"
                ),
            },
            "Whenever you cast an instant or sorcery spell, put a +1/+1 counter on this creature. Then this creature deals damage equal to its power to target opponent.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "instant_sorcery_cast_add_counter_then_power_damage_target_opponent_v1",
        )
        self.assertEqual(primary["power"], 3)
        self.assertEqual(primary["toughness"], 3)
        self.assertTrue(primary["flying"])
        self.assertEqual(primary["trigger"], "instant_sorcery_cast")
        self.assertEqual(primary["trigger_effect"], "source_counter_then_power_damage")
        self.assertEqual(primary["trigger_add_plus_one_counter"], 1)
        self.assertEqual(primary["trigger_damage_amount_source"], "source_power_after_counter")
        self.assertEqual(primary["target"], "opponent")

    def test_faerie_mastermind_maps_to_exact_draw_trigger_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DrawCardSourceControllerEffect", "DrawCardAllEffect"],
                "ability_classes": [
                    "DrawNthCardTriggeredAbility",
                    "FlashAbility",
                    "FlyingAbility",
                    "SimpleActivatedAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(2); this.toughness = new MageInt(1); "
                    "this.addAbility(FlashAbility.getInstance()); this.addAbility(FlyingAbility.getInstance()); "
                    "new DrawNthCardTriggeredAbility(new DrawCardSourceControllerEffect(1, true), false, TargetController.OPPONENT, 2); "
                    "this.addAbility(new SimpleActivatedAbility(new DrawCardAllEffect(1), new ManaCostsImpl<>(\"{3}{U}\")));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "flash_flying_second_opponent_draw_draw_one_and_activated_each_player_draw_v1",
        )
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 1)
        self.assertTrue(primary["flash"])
        self.assertTrue(primary["flying"])
        self.assertEqual(primary["opponent_second_card_each_turn_draw"], 1)
        self.assertEqual(primary["activated_each_player_draw_cost"], "{3}{U}")
        self.assertEqual(primary["activated_each_player_draw_count"], 1)

    def test_tataru_taru_maps_to_exact_off_turn_treasure_engine_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CreateTokenEffect", "DrawCardSourceControllerEffect"],
                "ability_classes": [
                    "DrawCardOpponentTriggeredAbility",
                    "EntersBattlefieldTriggeredAbility",
                ],
                "target_classes": ["TargetOpponent"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(0); this.toughness = new MageInt(3); "
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DrawCardSourceControllerEffect(1, true)); "
                    "ability.addTarget(new TargetOpponent()); "
                    "this.addAbility(new DrawCardOpponentTriggeredAbility(new CreateTokenEffect(new TreasureToken(), 1, true), false, false)"
                    ".setTriggersLimitEachTurn(1).withInterveningIf(TataruTaruCondition.instance));"
                ),
                "oracle_text": (
                    "When Tataru Taru enters, you draw a card and target opponent may draw a card.\n"
                    "Whenever an opponent draws a card, if it isn't that player's turn, create a tapped Treasure token. "
                    "This ability triggers only once each turn."
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_engine")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_draw_target_opponent_may_draw_off_turn_once_each_turn_tapped_treasure_v1",
        )
        self.assertEqual(primary["trigger"], "opponent_draw")
        self.assertEqual(primary["treasure_count"], 1)
        self.assertTrue(primary["treasure_tokens_tapped"])
        self.assertTrue(primary["trigger_only_off_turn_opponent_draw"])
        self.assertEqual(primary["trigger_limit_each_turn"], 1)
        self.assertEqual(primary["etb_draw_count"], 1)
        self.assertEqual(primary["etb_target_opponent_may_draw_count"], 1)
        self.assertEqual(
            primary["etb_target_opponent_may_draw_choice_model"],
            "compact_assume_yes_single_card_v1",
        )

    def test_knuckles_maps_to_exact_combat_damage_treasure_engine_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CreateTokenEffect"],
                "ability_classes": [
                    "DoubleStrikeAbility",
                    "HasteAbility",
                    "OneOrMoreCombatDamagePlayerTriggeredAbility",
                    "TrampleAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(2); this.toughness = new MageInt(4); "
                    "this.addAbility(DoubleStrikeAbility.getInstance()); "
                    "this.addAbility(TrampleAbility.getInstance()); "
                    "this.addAbility(HasteAbility.getInstance()); "
                    "this.addAbility(new OneOrMoreCombatDamagePlayerTriggeredAbility("
                    "new CreateTokenEffect(new TreasureToken()), StaticFilters.FILTER_CONTROLLED_CREATURES));"
                ),
                "oracle_text": (
                    "Double strike, trample, haste\n"
                    "Whenever one or more creatures you control deal combat damage to a player, create a Treasure token.\n"
                    "At the beginning of your upkeep, if you control thirty or more artifacts, you win the game."
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_engine")
        self.assertEqual(
            primary["battle_model_scope"],
            "one_or_more_creatures_you_control_combat_damage_player_create_treasure_v1",
        )
        self.assertEqual(primary["trigger"], "combat_damage_to_player")
        self.assertTrue(primary["trigger_creatures_you_control"])
        self.assertEqual(primary["treasure_count"], 1)
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 4)
        self.assertTrue(primary["double_strike"])
        self.assertTrue(primary["trample"])
        self.assertTrue(primary["haste"])
        self.assertEqual(primary["upkeep_win_if_control_artifacts_at_least"], 30)
        self.assertEqual(primary["upkeep_win_status"], "annotation_only")

    def test_wan_shi_tong_maps_to_exact_x_growth_draw_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["AddCountersSourceEffect", "DrawCardSourceControllerEffect"],
                "ability_classes": [
                    "EntersBattlefieldTriggeredAbility",
                    "FlashAbility",
                    "FlyingAbility",
                    "VigilanceAbility",
                    "WanShiTongLibrarianTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(1); this.toughness = new MageInt(1); "
                    "this.addAbility(FlashAbility.getInstance()); this.addAbility(FlyingAbility.getInstance()); this.addAbility(VigilanceAbility.getInstance()); "
                    "new EntersBattlefieldTriggeredAbility(new AddCountersSourceEffect(CounterType.P1P1.createInstance(), GetXValue.instance)); "
                    "ability.addEffect(new DrawCardSourceControllerEffect(xValue)); "
                    "this.addAbility(new WanShiTongLibrarianTriggeredAbility());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "flash_flying_vigilance_etb_x_counters_draw_half_x_opponent_search_growth_v1",
        )
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 1)
        self.assertTrue(primary["flash"])
        self.assertTrue(primary["flying"])
        self.assertTrue(primary["vigilance"])
        self.assertTrue(primary["etb_add_x_plus_one_counters"])
        self.assertTrue(primary["etb_draw_half_x_rounded_down"])
        self.assertTrue(primary["opponent_search_library_add_counter_and_draw"])

    def test_orcish_bowmasters_maps_to_exact_etb_or_extra_draw_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DamageTargetEffect", "AmassEffect"],
                "ability_classes": [
                    "FlashAbility",
                    "OrTriggeredAbility",
                    "EntersBattlefieldTriggeredAbility",
                    "OpponentDrawCardExceptFirstCardDrawStepTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(1); this.toughness = new MageInt(1); "
                    "this.addAbility(FlashAbility.getInstance()); "
                    "new OrTriggeredAbility(Zone.BATTLEFIELD, new DamageTargetEffect(1, \"{this}\"), "
                    "new EntersBattlefieldTriggeredAbility(null, false), "
                    "new OpponentDrawCardExceptFirstCardDrawStepTriggeredAbility(Zone.BATTLEFIELD, null, false)); "
                    "Effect amass = new AmassEffect(1, SubType.ORC);"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "flash_etb_or_opponent_extra_draw_damage_any_target_amass_orcs_v1",
        )
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 1)
        self.assertTrue(primary["flash"])
        self.assertEqual(primary["etb_or_opponent_extra_draw_damage_any_target"], 1)
        self.assertEqual(primary["amass_orcs"], 1)

    def test_hullbreaker_horror_maps_to_exact_cast_spell_bounce_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["ReturnToHandTargetEffect"],
                "ability_classes": [
                    "CantBeCounteredSourceAbility",
                    "FlashAbility",
                    "SpellCastControllerTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(7); this.toughness = new MageInt(8); "
                    "this.addAbility(FlashAbility.getInstance()); this.addAbility(new CantBeCounteredSourceAbility()); "
                    "Ability ability = new SpellCastControllerTriggeredAbility(new ReturnToHandTargetEffect(), false); "
                    "ability.addTarget(new TargetSpell(filter)); Mode mode = new Mode(new ReturnToHandTargetEffect()); mode.addTarget(new TargetNonlandPermanent());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "flash_cant_be_countered_cast_spell_bounce_spell_or_nonland_v1",
        )
        self.assertEqual(primary["power"], 7)
        self.assertEqual(primary["toughness"], 8)
        self.assertTrue(primary["flash"])
        self.assertTrue(primary["cant_be_countered"])
        self.assertTrue(primary["cast_spell_trigger_bounce_spell_you_dont_control"])
        self.assertTrue(primary["cast_spell_trigger_bounce_nonland_permanent"])

    def test_deathrite_shaman_maps_to_exact_graveyard_mode_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "ExileTargetEffect",
                    "AddManaOfAnyColorEffect",
                    "LoseLifeOpponentsEffect",
                    "GainLifeEffect",
                ],
                "ability_classes": ["SimpleActivatedAbility"],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(1); this.toughness = new MageInt(2); "
                    "Ability ability = new SimpleActivatedAbility(new ExileTargetEffect(), new TapSourceCost()); "
                    "ability.addEffect(new AddManaOfAnyColorEffect(1, new LimitedDynamicValue(1, new CardsInControllerGraveyardCount(StaticFilters.FILTER_CARD_LAND)), false)); "
                    "ability = new SimpleActivatedAbility(new ExileTargetEffect(), new ManaCostsImpl<>(\"{B}\")); ability.addCost(new TapSourceCost()); ability.addEffect(new LoseLifeOpponentsEffect(2)); "
                    "ability = new SimpleActivatedAbility(new ExileTargetEffect(), new ManaCostsImpl<>(\"{G}\")); ability.addCost(new TapSourceCost()); ability.addEffect(new GainLifeEffect(2));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "graveyard_exile_mana_or_life_shaman_v1",
        )
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 2)
        self.assertTrue(primary["tap_exile_land_from_graveyard_add_one_mana_any_color"])
        self.assertEqual(primary["black_tap_exile_instant_or_sorcery_from_graveyard_each_opponent_loses_life"], 2)
        self.assertEqual(primary["green_tap_exile_creature_from_graveyard_gain_life"], 2)

    def test_nezahal_maps_to_exact_static_draw_blink_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
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
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(7); this.toughness = new MageInt(7); "
                    "this.addAbility(new CantBeCounteredSourceAbility()); "
                    "this.addAbility(new SimpleStaticAbility(new MaximumHandSizeControllerEffect(Integer.MAX_VALUE, Duration.WhileOnBattlefield, MaximumHandSizeControllerEffect.HandSizeModification.SET))); "
                    "this.addAbility(new SpellCastOpponentTriggeredAbility(Zone.BATTLEFIELD, new DrawCardSourceControllerEffect(1), StaticFilters.FILTER_SPELL_A_NON_CREATURE, false, SetTargetPointer.NONE)); "
                    "this.addAbility(new SimpleActivatedAbility(new ExileReturnBattlefieldOwnerNextEndStepSourceEffect(true), new DiscardTargetCost(new TargetCardInHand(3, StaticFilters.FILTER_CARD_CARDS))));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "cant_be_countered_no_max_hand_opponent_noncreature_cast_draw_exile_blink_v1",
        )
        self.assertEqual(primary["power"], 7)
        self.assertEqual(primary["toughness"], 7)
        self.assertTrue(primary["cant_be_countered"])
        self.assertTrue(primary["no_maximum_hand_size"])
        self.assertEqual(primary["opponent_casts_noncreature_draw"], 1)
        self.assertEqual(primary["activated_discard_cards_to_exile_and_return_tapped_count"], 3)

    def test_teferi_time_raveler_maps_to_exact_planeswalker_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "CastAsThoughItHadFlashAllEffect",
                    "DrawCardSourceControllerEffect",
                    "ReturnToHandTargetEffect",
                    "TeferiTimeRavelerReplacementEffect",
                ],
                "ability_classes": ["LoyaltyAbility", "SimpleStaticAbility"],
                "constructor_metadata": {"card_types": ["PLANESWALKER"]},
                "raw_excerpt": (
                    "this.setStartingLoyalty(4); Each opponent can cast spells only any time they could cast a sorcery. "
                    "Until your next turn, you may cast sorcery spells as though they had flash. "
                    "Return up to one target artifact, creature, or enchantment to its owner's hand. Draw a card."
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "planeswalker")
        self.assertEqual(
            primary["battle_model_scope"],
            "opponents_sorcery_speed_only_plus1_sorcery_flash_minus3_bounce_draw_v1",
        )
        self.assertEqual(primary["starting_loyalty"], 4)
        self.assertTrue(primary["opponents_can_cast_only_as_sorcery"])
        self.assertTrue(primary["plus_one_sorceries_have_flash_until_your_next_turn"])
        self.assertEqual(primary["minus_three_bounce_up_to_one_artifact_creature_or_enchantment_draw"], 1)

    def test_goblin_bombardment_maps_to_exact_sacrifice_damage_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DamageTargetEffect"],
                "ability_classes": ["SimpleActivatedAbility"],
                "cost_classes": ["SacrificeTargetCost"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "Ability ability = new SimpleActivatedAbility(new DamageTargetEffect(1), "
                    "new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE)); "
                    "ability.addTarget(new TargetAnyTarget());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "direct_damage")
        self.assertEqual(
            primary["battle_model_scope"],
            "activated_sacrifice_creature_deal_one_any_target_v1",
        )
        self.assertEqual(primary["activation_cost"], "sacrifice_creature")
        self.assertEqual(primary["damage"], 1)
        self.assertEqual(primary["target"], "any_target")

    def test_soul_guide_lantern_maps_to_exact_graveyard_hate_artifact_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["ExileTargetEffect", "DrawCardSourceControllerEffect", "OneShotEffect", "SoulGuideLanternEffect"],
                "ability_classes": ["EntersBattlefieldTriggeredAbility", "SimpleActivatedAbility"],
                "cost_classes": ["TapSourceCost", "SacrificeSourceCost", "GenericManaCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new ExileTargetEffect()); "
                    "ability = new SimpleActivatedAbility(new SoulGuideLanternEffect(), new TapSourceCost()); "
                    "ability.addCost(new SacrificeSourceCost()); "
                    "ability = new SimpleActivatedAbility(new DrawCardSourceControllerEffect(1), new GenericManaCost(1)); "
                    "ability.addCost(new TapSourceCost()); ability.addCost(new SacrificeSourceCost());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "artifact")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_exile_graveyard_card_or_sacrifice_for_mass_graveyard_exile_or_draw_v1",
        )
        self.assertTrue(primary["etb_exile_target_card_from_graveyard"])
        self.assertTrue(primary["activated_tap_sacrifice_exile_each_opponents_graveyard"])
        self.assertEqual(primary["activated_generic_one_tap_sacrifice_draw"], 1)

    def test_vexing_bauble_maps_to_exact_counter_free_spell_artifact_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CounterTargetEffect", "DrawCardSourceControllerEffect"],
                "ability_classes": ["SpellCastAllTriggeredAbility", "SimpleActivatedAbility"],
                "cost_classes": ["GenericManaCost", "TapSourceCost", "SacrificeSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    "this.addAbility(new SpellCastAllTriggeredAbility(new CounterTargetEffect(), StaticFilters.FILTER_SPELL_NO_MANA_SPENT, false, SetTargetPointer.SPELL)); "
                    "Ability ability = new SimpleActivatedAbility(new DrawCardSourceControllerEffect(1), new GenericManaCost(1)); "
                    "ability.addCost(new TapSourceCost()); ability.addCost(new SacrificeSourceCost());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "artifact")
        self.assertEqual(
            primary["battle_model_scope"],
            "counter_no_mana_spent_spells_and_cantrip_sacrifice_v1",
        )
        self.assertTrue(primary["trigger_counter_spell_if_no_mana_was_spent"])
        self.assertEqual(primary["activated_generic_one_tap_sacrifice_draw"], 1)

    def test_cyclonic_rift_maps_to_exact_overload_bounce_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["ReturnToHandTargetEffect"],
                "ability_classes": ["OverloadAbility"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "OverloadAbility.implementOverloadAbility(this, new ManaCostsImpl<>(\"{6}{U}\"), "
                    "new TargetPermanent(filter), new ReturnToHandTargetEffect()); "
                    "filter.add(TargetController.NOT_YOU.getControllerPredicate());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "bounce")
        self.assertEqual(
            primary["battle_model_scope"],
            "return_target_nonland_permanent_you_dont_control_or_overload_all_opponents_nonlands_v1",
        )
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["target"], "nonland_permanent_you_dont_control")
        self.assertEqual(primary["overload_cost"], "{6}{U}")
        self.assertTrue(primary["overload_bounces_each_nonland_permanent_you_dont_control"])

    def test_red_elemental_blast_maps_to_exact_modal_blue_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CounterTargetEffect", "DestroyTargetEffect"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "Choose one - Counter target blue spell; or destroy target blue permanent. "
                    "this.getSpellAbility().addEffect(new CounterTargetEffect()); "
                    "Mode mode = new Mode(new DestroyTargetEffect());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "modal_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "counter_target_blue_spell_or_destroy_target_blue_permanent_v1",
        )
        self.assertTrue(primary["counter_target_blue_spell"])
        self.assertTrue(primary["destroy_target_blue_permanent"])
        self.assertTrue(primary["instant"])

    def test_into_the_flood_maw_maps_to_exact_gift_bounce_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["ReturnToHandTargetEffect"],
                "ability_classes": ["GiftAbility"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "bounce")
        self.assertEqual(primary["battle_model_scope"], "gift_bounce_opponent_creature_or_nonland_v1")
        self.assertTrue(primary["instant"])
        self.assertTrue(primary["gift_tapped_fish"])
        self.assertEqual(primary["target"], "opponent_creature")
        self.assertEqual(primary["gift_promised_target"], "opponent_nonland_permanent")

    def test_perch_protection_maps_to_exact_composite_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "CreateTokenEffect",
                    "ExileSpellEffect",
                    "GainAbilityControllerEffect",
                    "LifeTotalCantChangeControllerEffect",
                    "OneShotEffect",
                    "PerchProtectionEffect",
                ],
                "ability_classes": ["GiftAbility"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "new CreateTokenEffect(new SwanSongBirdToken(), 4); "
                    "new LifeTotalCantChangeControllerEffect(Duration.UntilYourNextTurn); "
                    "new GainAbilityControllerEffect(new ProtectionFromEverythingAbility(), Duration.UntilYourNextTurn); "
                    "new ExileSpellEffect();"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "composite_resolution")
        self.assertEqual(
            primary["battle_model_scope"],
            "create_four_birds_gift_phase_all_life_lock_protection_exile_self_v1",
        )
        self.assertTrue(primary["gift_extra_turn"])
        self.assertTrue(primary["exiles_self"])
        components = primary["_composite_rule_components"]
        self.assertEqual(components[0]["effect"], "token_maker")
        self.assertEqual(components[0]["token_count"], 4)
        self.assertEqual(components[0]["token_name"], "Bird Token")
        self.assertEqual(components[1]["effect"], "phase_out")
        self.assertTrue(components[1]["phase_out_includes_lands"])
        self.assertTrue(components[1]["life_total_cant_change"])

    def test_sand_scout_maps_to_exact_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["CreateTokenEffect", "SearchLibraryPutInPlayEffect"],
                "ability_classes": [
                    "EntersBattlefieldTriggeredAbility",
                    "PutCardIntoGraveFromAnywhereAllTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "filter.add(SubType.DESERT.getPredicate()); "
                    "new SearchLibraryPutInPlayEffect(new TargetCardInLibrary(filter), true); "
                    "new CreateTokenEffect(new SandWarriorToken());"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "sand_scout_etb_desert_if_behind_lands_land_graveyard_token_v1",
        )
        self.assertEqual(primary["etb_land_ramp_condition"], "opponent_controls_more_lands")
        self.assertEqual(primary["land_subtypes_any"], ["desert"])
        self.assertEqual(primary["land_graveyard_token_name"], "Sand Warrior Token")
        self.assertEqual(primary["land_graveyard_token_colors"], ["R", "G", "W"])

    def test_snap_maps_to_exact_bounce_and_untap_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["ReturnToHandTargetEffect", "UntapLandsEffect"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "bounce")
        self.assertEqual(
            primary["battle_model_scope"],
            "return_target_creature_then_untap_up_to_two_lands_v1",
        )
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["target"], "creature")
        self.assertEqual(primary["untap_lands_count"], 2)

    def test_gods_willing_maps_to_targeted_protection_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["GainProtectionFromColorTargetEffect", "ScryEffect"],
                "target_classes": ["TargetControlledCreaturePermanent"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "grant_protection_from_chosen_color")
        self.assertEqual(
            primary["battle_model_scope"],
            "target_creature_you_control_protection_from_chosen_color_until_eot_v1",
        )
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["target"], "creature_you_control")
        self.assertTrue(primary["protection_from_chosen_color_until_eot"])

    def test_sejiri_shelter_mdfc_maps_to_targeted_protection_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["GainProtectionFromColorTargetEffect"],
                "ability_classes": ["EntersBattlefieldTappedAbility", "WhiteManaAbility"],
                "target_classes": ["TargetControlledCreaturePermanent"],
                "constructor_metadata": {"card_types": ["INSTANT", "LAND"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "grant_protection_from_chosen_color")
        self.assertEqual(
            primary["battle_model_scope"],
            "target_creature_you_control_protection_from_chosen_color_until_eot_v1",
        )

    def test_eight_and_a_half_tails_maps_to_creature_body_with_mana_protection_response(self) -> None:
        result = hints.build_effect_hints(
            {
                "class_name": "EightAndAHalfTails",
                "effect_classes": ["GainAbilityTargetEffect", "BecomesColorTargetEffect"],
                "ability_classes": ["SimpleActivatedAbility"],
                "target_classes": ["TargetControlledPermanent", "TargetSpellOrPermanent"],
                "constructor_metadata": {
                    "card_types": ["CREATURE"],
                    "power": 2,
                    "toughness": 2,
                },
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "creature_body_target_permanent_protection_from_white_make_source_white_activation_runtime_v1",
        )
        self.assertEqual(
            primary["runtime_modeled_effect"],
            "creature_body_plus_targeted_protection_response",
        )
        self.assertTrue(primary["can_make_source_white_for_protection"])
        self.assertEqual(primary["targeted_protection_activation_mana_cost"], "{2}{W}")
        self.assertFalse(primary["tap_activation"])

    def test_manamorphose_maps_to_exact_mana_then_draw_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["AddManaInAnyCombinationEffect", "DrawCardSourceControllerEffect"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "draw_cards")
        self.assertEqual(primary["battle_model_scope"], "add_two_mana_any_combination_then_draw_v1")
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["count"], 1)
        self.assertEqual(primary["add_mana_any_combination"], 2)

    def test_tinder_wall_maps_to_exact_defender_sacrifice_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DamageTargetEffect"],
                "ability_classes": ["DefenderAbility", "SimpleActivatedAbility", "SimpleManaAbility"],
                "cost_classes": ["SacrificeSourceCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "defender_sacrifice_for_rr_or_blocking_damage_v1")
        self.assertEqual(primary["power"], 0)
        self.assertEqual(primary["toughness"], 3)
        self.assertTrue(primary["defender"])
        self.assertEqual(primary["sacrifice_for_red_mana"], 2)
        self.assertEqual(primary["red_sacrifice_damage_blocking_creature"], 2)

    def test_walking_ballista_maps_to_exact_counter_ping_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "AddCountersSourceEffect",
                    "DamageTargetEffect",
                    "EntersBattlefieldWithXCountersEffect",
                ],
                "ability_classes": ["EntersBattlefieldAbility", "SimpleActivatedAbility"],
                "cost_classes": ["GenericManaCost", "RemoveCountersSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT", "CREATURE"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "x_etb_counters_add_counter_or_remove_counter_ping_v1")
        self.assertEqual(primary["power"], 0)
        self.assertEqual(primary["toughness"], 0)
        self.assertTrue(primary["enters_with_x_plus_one_counters"])
        self.assertEqual(primary["activated_generic_four_add_plus_one_counter"], 1)
        self.assertEqual(primary["activated_remove_plus_one_counter_damage_any_target"], 1)

    def test_everflowing_chalice_maps_to_exact_multikicker_charge_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["AddCountersSourceEffect"],
                "ability_classes": ["DynamicManaAbility", "EntersBattlefieldAbility", "MultikickerAbility"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "artifact")
        self.assertEqual(primary["battle_model_scope"], "multikicker_charge_counter_mana_rock_v1")
        self.assertEqual(primary["multikicker_cost"], "{2}")
        self.assertTrue(primary["etb_charge_counters_per_kick"])
        self.assertTrue(primary["tap_add_colorless_per_charge_counter"])

    def test_sink_into_stupor_maps_to_exact_spell_or_nonland_bounce_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["ReturnToHandTargetEffect", "TapSourceUnlessPaysEffect"],
                "ability_classes": ["AsEntersBattlefieldAbility", "BlueManaAbility"],
                "cost_classes": ["PayLifeCost"],
                "constructor_metadata": {"card_types": ["INSTANT", "LAND"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "bounce")
        self.assertEqual(
            primary["battle_model_scope"],
            "return_target_spell_or_opponent_nonland_permanent_or_tapped_blue_land_v1",
        )
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["target"], "spell_or_opponent_nonland_permanent")
        self.assertTrue(primary["land_side_pay_three_life_else_tapped"])
        self.assertEqual(primary["land_side_add_mana"], "U")

    def test_razorgrass_ambush_maps_to_exact_attacking_blocking_damage_land_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "RazorgrassAmbush",
                "effect_classes": ["DamageTargetEffect", "TapSourceUnlessPaysEffect"],
                "ability_classes": ["AsEntersBattlefieldAbility", "WhiteManaAbility"],
                "target_classes": ["TargetAttackingOrBlockingCreature"],
                "cost_classes": ["PayLifeCost"],
                "constructor_metadata": {"card_types": ["INSTANT", "LAND"]},
                "raw_excerpt": (
                    "this.getLeftHalfCard().getSpellAbility().addTarget(new TargetAttackingOrBlockingCreature()); "
                    "this.getLeftHalfCard().getSpellAbility().addEffect(new DamageTargetEffect(3)); "
                    "this.getRightHalfCard().addAbility(new AsEntersBattlefieldAbility(new TapSourceUnlessPaysEffect(new PayLifeCost(3)))); "
                    "this.getRightHalfCard().addAbility(new WhiteManaAbility());"
                ),
            },
            "Razorgrass Ambush deals 3 damage to target attacking or blocking creature.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "direct_damage")
        self.assertEqual(
            primary["battle_model_scope"],
            "damage_target_attacking_or_blocking_creature_or_tapped_white_land_v1",
        )
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["target"], "creature")
        self.assertEqual(primary["damage"], 3)
        self.assertTrue(primary["land_side_pay_three_life_else_tapped"])
        self.assertEqual(primary["land_side_add_mana"], "W")
        self.assertEqual(primary["target_constraints"]["combat_state"], "attacking_or_blocking")

    def test_disciple_of_freyalise_maps_to_exact_etb_sacrifice_and_land_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "DiscipleOfFreyaliseEffect",
                    "DrawCardSourceControllerEffect",
                    "GainLifeEffect",
                    "OneShotEffect",
                    "TapSourceUnlessPaysEffect",
                ],
                "ability_classes": ["AsEntersBattlefieldAbility", "EntersBattlefieldTriggeredAbility", "GreenManaAbility"],
                "constructor_metadata": {"card_types": ["CREATURE", "LAND"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_sacrifice_another_creature_gain_draw_power_or_tapped_green_land_v1",
        )
        self.assertEqual(primary["power"], 3)
        self.assertEqual(primary["toughness"], 3)
        self.assertTrue(primary["etb_may_sacrifice_another_creature_gain_life_and_draw_equal_power"])
        self.assertTrue(primary["land_side_pay_three_life_else_tapped"])
        self.assertEqual(primary["land_side_add_mana"], "G")

    def test_vibrance_maps_to_exact_evoke_dual_etb_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": ["DamageTargetEffect", "GainLifeEffect", "SearchLibraryPutInHandEffect"],
                "ability_classes": ["EntersBattlefieldTriggeredAbility", "EvokeAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "evoke_etb_red_damage_or_green_land_tutor_lifegain_v1")
        self.assertEqual(primary["power"], 4)
        self.assertEqual(primary["toughness"], 4)
        self.assertEqual(primary["evoke_cost"], "{R/G}{R/G}")
        self.assertEqual(primary["etb_if_red_red_spent_damage_any_target"], 3)
        self.assertTrue(primary["etb_if_green_green_spent_search_land_to_hand"])
        self.assertEqual(primary["etb_if_green_green_spent_gain_life"], 2)

    def test_archdruids_charm_maps_to_exact_modal_three_mode_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "AddCountersTargetEffect",
                    "DamageWithPowerFromOneToAnotherTargetEffect",
                    "ExileTargetEffect",
                    "SearchEffect",
                    "SearchLibraryPutInHandOrOnBattlefieldEffect",
                ],
                "constructor_metadata": {"card_types": ["INSTANT"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "modal_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "search_creature_or_land_or_counter_fight_or_exile_artifact_enchantment_v1",
        )
        self.assertTrue(primary["instant"])
        self.assertTrue(primary["mode_search_creature_or_land_reveal_put_land_battlefield_tapped_else_hand"])
        self.assertTrue(primary["mode_put_plus_one_counter_on_controlled_creature_then_fight"])
        self.assertTrue(primary["mode_exile_target_artifact_or_enchantment"])

    def test_eldrazi_confluence_maps_to_exact_repeatable_three_mode_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "EldraziConfluence",
                "effect_classes": [
                    "BoostTargetEffect",
                    "CreateTokenEffect",
                    "ExileTargetEffect",
                    "ExileThenReturnTargetEffect",
                    "PhaseOutTargetEffect",
                    "ProliferateEffect",
                ],
                "target_classes": ["TargetCreaturePermanent", "TargetNonlandPermanent"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "this.getSpellAbility().getModes().setMinModes(3); "
                    "this.getSpellAbility().getModes().setMaxModes(3); "
                    "this.getSpellAbility().getModes().setMayChooseSameModeMoreThanOnce(true); "
                    "this.getSpellAbility().addEffect(new BoostTargetEffect(3, -3)); "
                    "this.getSpellAbility().addMode(new Mode(new ExileThenReturnTargetEffect(false, false, PutCards.BATTLEFIELD_TAPPED)).addTarget(new TargetNonlandPermanent())); "
                    "this.getSpellAbility().addMode(new Mode(new CreateTokenEffect(new EldraziScionToken())));"
                ),
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "modal_spell")
        self.assertEqual(
            primary["battle_model_scope"],
            "choose_three_pump_blink_tapped_or_create_eldrazi_scion_v1",
        )
        self.assertTrue(primary["instant"])
        self.assertEqual(primary["modal_choose_count"], 3)
        self.assertTrue(primary["modal_may_repeat_modes"])
        self.assertTrue(primary["mode_target_creature_plus_three_minus_three"])
        self.assertTrue(primary["mode_blink_target_nonland_permanent_tapped"])
        self.assertTrue(primary["mode_create_eldrazi_scion"])
        self.assertEqual(primary["token_name"], "Eldrazi Scion Token")
        self.assertEqual(primary["token_subtype"], "Eldrazi Scion")
        self.assertEqual(primary["token_power"], 1)
        self.assertEqual(primary["token_toughness"], 1)
        self.assertEqual(primary["token_colors"], [])
        self.assertTrue(primary["token_sacrifice_for_colorless_mana"])

    def test_clever_concealment_maps_to_controlled_nonland_phase_out_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "CleverConcealment",
                "effect_classes": ["PhaseOutTargetEffect"],
                "ability_classes": ["ConvokeAbility"],
                "target_classes": ["TargetPermanent"],
                "filter_classes": ["FilterControlledPermanent", "FilterPermanent"],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    'private static final FilterPermanent filter = new FilterControlledPermanent("nonland permanents you control"); '
                    "filter.add(Predicates.not(CardType.LAND.getPredicate())); "
                    "this.addAbility(new ConvokeAbility()); "
                    "this.getSpellAbility().addEffect(new PhaseOutTargetEffect()); "
                    "this.getSpellAbility().addTarget(new TargetPermanent(0, Integer.MAX_VALUE, filter));"
                ),
            },
            "Convoke. Any number of target nonland permanents you control phase out.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "phase_out")
        self.assertEqual(primary["battle_model_scope"], "target_nonland_permanents_you_control_phase_out_v1")
        self.assertTrue(primary["instant"])
        self.assertTrue(primary["convoke"])
        self.assertEqual(primary["target"], "nonland_permanents_you_control")
        self.assertTrue(primary["phase_out_all_permanents_you_control"])
        self.assertFalse(primary["phase_out_includes_lands"])
        self.assertEqual(primary["choice_model"], "phase_out_all_legal_nonland_permanents_you_control")
        self.assertEqual(primary["target_constraints"]["exclude_card_types"], ["land"])

    def test_ruthless_technomancer_maps_to_exact_treasure_and_reanimate_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "effect_classes": [
                    "OneShotEffect",
                    "ReturnFromGraveyardToBattlefieldTargetEffect",
                    "RuthlessTechnomancerEffect",
                ],
                "ability_classes": ["EntersBattlefieldTriggeredAbility", "SimpleActivatedAbility"],
                "cost_classes": ["SacrificeXTargetCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "etb_sacrifice_another_creature_create_treasures_and_x_artifact_reanimate_v1",
        )
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 4)
        self.assertTrue(primary["etb_may_sacrifice_another_creature_create_treasures_equal_power"])
        self.assertEqual(primary["activated_cost"], "{2}{B}")
        self.assertTrue(primary["activated_sacrifice_x_artifacts_return_creature_with_power_x_or_less"])

    def test_emperor_of_bones_maps_to_exact_exile_adapt_reanimate_scope(self) -> None:
        result = hints.build_effect_hints(
            {
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
                "constructor_metadata": {"card_types": ["CREATURE"]},
            }
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "combat_exile_adapt_finality_reanimate_v1")
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 2)
        self.assertTrue(primary["beginning_of_combat_exile_up_to_one_card_from_graveyard"])
        self.assertEqual(primary["adapt_cost"], "{1}{B}")
        self.assertEqual(primary["adapt_counters"], 2)
        self.assertTrue(primary["counters_trigger_reanimate_exiled_creature_with_finality_haste_and_sacrifice_eot"])

    def test_sun_titan_maps_to_exact_etb_attack_recursion_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "SunTitan",
                "effect_classes": ["ReturnFromGraveyardToBattlefieldTargetEffect"],
                "ability_classes": [
                    "EntersBattlefieldOrAttacksSourceTriggeredAbility",
                    "VigilanceAbility",
                ],
                "target_classes": ["TargetCardInYourGraveyard"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "FilterPermanentCard filter = new FilterPermanentCard(\"permanent card "
                    "with mana value 3 or less from your graveyard\"); "
                    "filter.add(new ManaValuePredicate(ComparisonType.FEWER_THAN, 4));"
                ),
            },
            "Whenever Sun Titan enters the battlefield or attacks, you may return target permanent card "
            "with mana value 3 or less from your graveyard to the battlefield.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "sun_titan_etb_attack_return_permanent_mv_lte_3_v1",
        )
        self.assertEqual(primary["power"], 6)
        self.assertEqual(primary["toughness"], 6)
        self.assertTrue(primary["vigilance"])
        self.assertEqual(primary["etb_recursion_target"], "permanent")
        self.assertEqual(primary["etb_recursion_destination"], "battlefield")
        self.assertEqual(primary["etb_recursion_mana_value_max"], 3)
        self.assertTrue(primary["attack_trigger_graveyard_recursion"])
        self.assertEqual(primary["attack_recursion_target"], "permanent")
        self.assertEqual(primary["attack_recursion_destination"], "battlefield")
        self.assertEqual(primary["attack_recursion_mana_value_max"], 3)

    def test_squee_goblin_nabob_maps_to_exact_graveyard_upkeep_return_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "SqueeGoblinNabob",
                "effect_classes": ["ReturnSourceFromGraveyardToHandEffect"],
                "ability_classes": ["BeginningOfUpkeepTriggeredAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.addAbility(new BeginningOfUpkeepTriggeredAbility(Zone.GRAVEYARD, "
                    "TargetController.YOU, new ReturnSourceFromGraveyardToHandEffect(), true));"
                ),
            },
            "At the beginning of your upkeep, you may return Squee, Goblin Nabob from your graveyard to your hand.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "graveyard_upkeep_return_self_to_hand_v1",
        )
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 1)
        self.assertTrue(primary["legendary"])
        self.assertTrue(primary["graveyard_upkeep_return_self_to_hand"])
        self.assertTrue(primary["graveyard_upkeep_optional"])
        self.assertEqual(primary["graveyard_upkeep_trigger_zone"], "graveyard")
        self.assertEqual(primary["graveyard_upkeep_trigger_controller"], "source_controller")

    def test_goldspan_dragon_maps_to_exact_attack_or_target_treasure_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "GoldspanDragon",
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
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "new OrTriggeredAbility(Zone.BATTLEFIELD, "
                    "new CreateTokenEffect(new TreasureToken()), false, "
                    "new AttacksTriggeredAbility(null), "
                    "new BecomesTargetSourceTriggeredAbility(null, StaticFilters.FILTER_SPELL_A)); "
                    "new GainAbilityControlledEffect(ability, Duration.WhileOnBattlefield, filter); "
                    "new AddManaOfAnyColorEffect(2)"
                ),
            },
            "Whenever Goldspan Dragon attacks or becomes the target of a spell, create a Treasure token. "
            "Treasures you control have \"{T}, Sacrifice this artifact: Add two mana of any one color.\"",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "goldspan_dragon_attack_or_target_treasure_double_mana_v1",
        )
        self.assertEqual(primary["power"], 4)
        self.assertEqual(primary["toughness"], 4)
        self.assertTrue(primary["flying"])
        self.assertTrue(primary["haste"])
        self.assertTrue(primary["attack_or_becomes_target_create_treasure"])
        self.assertTrue(primary["attack_trigger_create_treasure"])
        self.assertTrue(primary["becomes_spell_target_create_treasure"])
        self.assertEqual(primary["treasure_count"], 1)
        self.assertEqual(primary["treasure_mana_value"], 2)
        self.assertTrue(primary["controlled_treasures_add_two_mana"])

    def test_surly_badgersaur_maps_to_exact_discard_card_type_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "SurlyBadgersaur",
                "effect_classes": [
                    "AddCountersSourceEffect",
                    "CreateTokenEffect",
                    "FightTargetSourceEffect",
                ],
                "ability_classes": ["DiscardCardControllerTriggeredAbility"],
                "target_classes": ["TargetPermanent"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "new DiscardCardControllerTriggeredAbility(new AddCountersSourceEffect("
                    "CounterType.P1P1.createInstance()), false, StaticFilters.FILTER_CARD_CREATURE_A); "
                    "new DiscardCardControllerTriggeredAbility(new CreateTokenEffect(new TreasureToken()), "
                    "false, StaticFilters.FILTER_CARD_LAND_A); "
                    "FilterCard filter = new FilterNonlandCard(\"a noncreature, nonland card\"); "
                    "filter.add(Predicates.not(CardType.CREATURE.getPredicate())); "
                    "new FightTargetSourceEffect(); new TargetPermanent(0, 1, "
                    "StaticFilters.FILTER_CREATURE_YOU_DONT_CONTROL, false)"
                ),
            },
            "Whenever you discard a creature card, put a +1/+1 counter on Surly Badgersaur. "
            "Whenever you discard a land card, create a Treasure token. Whenever you discard a "
            "noncreature, nonland card, Surly Badgersaur fights up to one target creature you don't control.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "surly_badgersaur_discard_card_type_triggers_v1",
        )
        self.assertEqual(primary["power"], 3)
        self.assertEqual(primary["toughness"], 3)
        self.assertEqual(primary["trigger"], "controller_discard")
        self.assertTrue(primary["controller_discard_creature_add_plus_one_counter"])
        self.assertEqual(primary["controller_discard_counter_type"], "+1/+1")
        self.assertEqual(primary["controller_discard_counter_count"], 1)
        self.assertTrue(primary["controller_discard_land_create_treasure"])
        self.assertEqual(primary["controller_discard_treasure_count"], 1)
        self.assertTrue(primary["controller_discard_noncreature_nonland_fight"])
        self.assertEqual(
            primary["controller_discard_fight_target"],
            "up_to_one_creature_you_dont_control",
        )
        self.assertTrue(primary["controller_discard_fight_optional"])

    def test_bone_miser_maps_to_exact_discard_card_type_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "BoneMiser",
                "effect_classes": [
                    "BasicManaEffect",
                    "CreateTokenEffect",
                    "DrawCardSourceControllerEffect",
                ],
                "ability_classes": ["DiscardCardControllerTriggeredAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "new DiscardCardControllerTriggeredAbility(new CreateTokenEffect(new ZombieToken()), "
                    "false, StaticFilters.FILTER_CARD_CREATURE_A); "
                    "new DiscardCardControllerTriggeredAbility(new BasicManaEffect(Mana.BlackMana(2)), "
                    "false, StaticFilters.FILTER_CARD_LAND_A); "
                    "FilterCard filter = new FilterNonlandCard(\"a noncreature, nonland card\"); "
                    "new DiscardCardControllerTriggeredAbility(new DrawCardSourceControllerEffect(1), false, filter)"
                ),
            },
            "Whenever you discard a creature card, create a 2/2 black Zombie creature token. "
            "Whenever you discard a land card, add {B}{B}. Whenever you discard a noncreature, "
            "nonland card, draw a card.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "controller_discards_card_type_token_mana_draw_v1",
        )
        self.assertEqual(primary["trigger"], "controller_discard")
        self.assertTrue(primary["controller_discard_creature_create_token"])
        self.assertEqual(primary["token_name"], "Zombie Token")
        self.assertEqual(primary["token_colors"], ["B"])
        self.assertEqual(primary["controller_discard_land_add_mana_color"], "black")
        self.assertEqual(primary["controller_discard_land_add_mana_amount"], 2)
        self.assertEqual(primary["controller_discard_noncreature_nonland_draw_cards"], 1)

    def test_waste_not_maps_to_exact_opponent_discard_card_type_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "WasteNot",
                "effect_classes": [
                    "BasicManaEffect",
                    "CreateTokenEffect",
                    "DrawCardSourceControllerEffect",
                ],
                "ability_classes": [
                    "WasteNotCreatureTriggeredAbility",
                    "WasteNotLandTriggeredAbility",
                    "WasteNotOtherTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "new CreateTokenEffect(new ZombieToken()); "
                    "new BasicManaEffect(Mana.BlackMana(2)); "
                    "new DrawCardSourceControllerEffect(1)"
                ),
            },
            "Whenever an opponent discards a creature card, create a 2/2 black Zombie creature token. "
            "Whenever an opponent discards a land card, add {B}{B}. Whenever an opponent discards a "
            "noncreature, nonland card, draw a card.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "token_maker")
        self.assertEqual(
            primary["battle_model_scope"],
            "opponent_discards_card_type_token_mana_draw_v1",
        )
        self.assertEqual(primary["trigger"], "opponent_discard")
        self.assertTrue(primary["opponent_discard_creature_create_token"])
        self.assertEqual(primary["token_name"], "Zombie Token")
        self.assertEqual(primary["token_colors"], ["B"])
        self.assertEqual(primary["opponent_discard_land_add_mana_color"], "black")
        self.assertEqual(primary["opponent_discard_land_add_mana_amount"], 2)
        self.assertEqual(primary["opponent_discard_noncreature_nonland_draw_cards"], 1)

    def test_green_goblin_nemesis_maps_to_exact_discard_nonland_counter_land_treasure_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "GreenGoblinNemesis",
                "effect_classes": [
                    "AddCountersTargetEffect",
                    "CreateTokenEffect",
                ],
                "ability_classes": ["DiscardCardControllerTriggeredAbility"],
                "target_classes": ["TargetPermanent"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(3); this.toughness = new MageInt(3); "
                    "this.addAbility(FlyingAbility.getInstance()); "
                    "new DiscardCardControllerTriggeredAbility(new AddCountersTargetEffect("
                    "CounterType.P1P1.createInstance()), false, StaticFilters.FILTER_CARD_A_NON_LAND); "
                    "new FilterControlledPermanent(SubType.GOBLIN); new TargetPermanent(filter); "
                    "new DiscardCardControllerTriggeredAbility(new CreateTokenEffect(new TreasureToken(), 1, true), "
                    "false, StaticFilters.FILTER_CARD_LAND_A)"
                ),
            },
            "Flying. Whenever you discard a nonland card, put a +1/+1 counter on target Goblin you control. "
            "Whenever you discard a land card, create a tapped Treasure token.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "controller_discards_nonland_counter_land_treasure_v1",
        )
        self.assertEqual(primary["power"], 3)
        self.assertEqual(primary["toughness"], 3)
        self.assertTrue(primary["flying"])
        self.assertEqual(primary["trigger"], "controller_discard")
        self.assertTrue(primary["controller_discard_nonland_add_plus_one_counter_to_controlled_subtype"])
        self.assertEqual(primary["controller_discard_counter_target_subtype"], "Goblin")
        self.assertTrue(primary["controller_discard_land_create_treasure"])
        self.assertTrue(primary["controller_discard_treasure_tapped"])

    def test_aclazotz_maps_to_exact_opponent_discard_land_bat_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "AclazotzDeepestBetrayal",
                "effect_classes": [
                    "AclazotzDeepestBetrayalEffect",
                    "AclazotzDeepestBetrayalTransformEffect",
                    "CreateTokenEffect",
                ],
                "ability_classes": [
                    "AttacksTriggeredAbility",
                    "AclazotzDeepestBetrayalTriggeredAbility",
                    "DiesSourceTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.getLeftHalfCard().setPT(4, 4); "
                    "this.getLeftHalfCard().addAbility(FlyingAbility.getInstance()); "
                    "this.getLeftHalfCard().addAbility(LifelinkAbility.getInstance()); "
                    "event.getType() == GameEvent.EventType.DISCARDED_CARD; "
                    "game.getOpponents(this.getControllerId()).contains(event.getPlayerId()); "
                    "discarded != null && discarded.isLand(game); "
                    "new CreateTokenEffect(new BatToken())"
                ),
            },
            "Flying, lifelink. Whenever an opponent discards a land card, create a 1/1 black Bat creature token with flying.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "opponent_discards_land_create_bat_token_v1",
        )
        self.assertEqual(primary["power"], 4)
        self.assertEqual(primary["toughness"], 4)
        self.assertTrue(primary["flying"])
        self.assertTrue(primary["lifelink"])
        self.assertEqual(primary["trigger"], "opponent_discard")
        self.assertTrue(primary["opponent_discard_land_create_token"])
        self.assertEqual(primary["token_name"], "Bat Token")
        self.assertEqual(primary["token_colors"], ["B"])
        self.assertTrue(primary["token_flying"])

    def test_black_market_connections_maps_to_exact_precombat_modal_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "BlackMarketConnections",
                "effect_classes": [
                    "CreateTokenEffect",
                    "DrawCardSourceControllerEffect",
                    "LoseLifeSourceControllerEffect",
                ],
                "ability_classes": ["BeginningOfFirstMainTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "new BeginningOfFirstMainTriggeredAbility(new CreateTokenEffect(new TreasureToken())); "
                    "new LoseLifeSourceControllerEffect(1); "
                    "new Mode(new DrawCardSourceControllerEffect(1)).addEffect(new LoseLifeSourceControllerEffect(2)); "
                    "new Mode(new CreateTokenEffect(new Shapeshifter32Token())).addEffect(new LoseLifeSourceControllerEffect(3));"
                ),
            },
            "At the beginning of your precombat main phase, choose one or more.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "token_maker")
        self.assertEqual(
            primary["battle_model_scope"],
            "precombat_main_choose_modes_treasure_draw_shapeshifter_life_loss_v1",
        )
        self.assertTrue(primary["precombat_main_choose_modes_treasure_draw_token_life_loss"])
        self.assertEqual(len(primary["precombat_main_modes"]), 3)
        self.assertEqual(primary["precombat_main_modes"][2]["token"]["token_subtype"], "Shapeshifter")

    def test_smugglers_share_maps_to_exact_each_end_step_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "SmugglersShare",
                "effect_classes": ["CreateTokenEffect", "DrawCardSourceControllerEffect"],
                "ability_classes": ["BeginningOfEndStepTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "new BeginningOfEndStepTriggeredAbility(TargetController.EACH_PLAYER, "
                    "new DrawCardSourceControllerEffect(SmugglersShareDrawValue.instance), false); "
                    "new CreateTokenEffect(new TreasureToken(), SmugglersShareTreasureValue.instance); "
                    "new CardsAmountDrawnThisTurnWatcher(); new PermanentsEnteredBattlefieldWatcher();"
                ),
            },
            "At the beginning of each end step, draw a card for each opponent who drew two or more cards this turn.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "token_maker")
        self.assertEqual(
            primary["battle_model_scope"],
            "each_end_step_opponent_extra_draw_landfall_draw_treasure_v1",
        )
        self.assertEqual(primary["trigger"], "each_end_step")
        self.assertEqual(primary["opponent_cards_drawn_threshold"], 2)
        self.assertEqual(primary["opponent_lands_entered_threshold"], 2)

    def test_davros_maps_to_exact_end_step_lost_life_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "DavrosDalekCreator",
                "effect_classes": ["CreateTokenEffect", "DavrosDalekCreatorEffect"],
                "ability_classes": ["BeginningOfEndStepTriggeredAbility", "MenaceAbility"],
                "constructor_metadata": {"card_types": ["ARTIFACT", "CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(3); this.toughness = new MageInt(4); "
                    "new BeginningOfEndStepTriggeredAbility(new ConditionalOneShotEffect("
                    "new CreateTokenEffect(new DalekToken()), new OpponentLostLifeCondition(ComparisonType.OR_GREATER, 3))); "
                    "PlayerLostLifeWatcher watcher = game.getState().getWatcher(PlayerLostLifeWatcher.class); "
                    "new FaceVillainousChoice(Outcome.Detriment, new DavrosDalekCreatorFirstChoice(), new DavrosDalekCreatorSecondChoice())"
                ),
            },
            "At the beginning of your end step, create a Dalek if an opponent lost 3 or more life this turn.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "controller_end_step_opponent_lost_life_dalek_villainous_choice_v1",
        )
        self.assertEqual(primary["opponent_life_lost_threshold"], 3)
        self.assertEqual(primary["token_name"], "Dalek Token")
        self.assertTrue(primary["artifact_tokens"])

    def test_taii_wakeen_maps_to_exact_noncombat_damage_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "TaiiWakeenPerfectShot",
                "effect_classes": [
                    "DrawCardSourceControllerEffect",
                    "TaiiWakeenPerfectShotEffect",
                ],
                "ability_classes": [
                    "TaiiWakeenPerfectShotTriggeredAbility",
                    "SimpleActivatedAbility",
                ],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(2); this.toughness = new MageInt(3); "
                    "event.getType() == GameEvent.EventType.DAMAGED_PERMANENT; "
                    "new DrawCardSourceControllerEffect(1); "
                    "new SimpleActivatedAbility(new TaiiWakeenPerfectShotEffect(), "
                    "new ManaCostsImpl<>(\"{X}\")); ability.addCost(new TapSourceCost()); "
                    "case DAMAGE_PERMANENT: case DAMAGE_PLAYER: "
                    "event.setAmount(CardUtil.overflowInc(event.getAmount(), "
                    "CardUtil.getSourceCostsTag(game, source, \"X\", 0)));"
                ),
            },
            "Whenever a source you control deals noncombat damage to a creature equal to that creature's toughness, draw a card. "
            "{X}, {T}: If a source you control would deal noncombat damage to a permanent or player this turn, "
            "it deals that much damage plus X instead.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "taii_wakeen_noncombat_damage_equal_toughness_draw_plus_x_v1",
        )
        self.assertEqual(primary["power"], 2)
        self.assertEqual(primary["toughness"], 3)
        self.assertEqual(
            primary["trigger"],
            "source_you_control_noncombat_damage_to_creature_equal_toughness",
        )
        self.assertTrue(primary["noncombat_damage_to_creature_equal_toughness_draw"])
        self.assertEqual(primary["noncombat_damage_equal_toughness_draw_count"], 1)
        self.assertTrue(primary["activated_noncombat_damage_plus_x_until_eot"])
        self.assertTrue(primary["activation_cost_x_generic"])
        self.assertTrue(primary["activation_requires_tap"])
        self.assertEqual(
            primary["damage_modifier_applies_to"],
            "sources_you_control_noncombat_damage",
        )
        self.assertEqual(primary["damage_modifier_duration"], "until_end_of_turn")

    def test_trouble_in_pairs_maps_to_exact_second_action_draw_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "TroubleInPairs",
                "effect_classes": ["DrawCardSourceControllerEffect"],
                "ability_classes": [
                    "SkipExtraTurnsAbility",
                    "TroubleInPairsTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "new SkipExtraTurnsAbility(true); "
                    "new TroubleInPairsTriggeredAbility(); "
                    "event.getType() == GameEvent.EventType.DECLARED_ATTACKERS "
                    "|| event.getType() == GameEvent.EventType.DREW_CARD "
                    "|| event.getType() == GameEvent.EventType.SPELL_CAST; "
                    "CardsDrawnThisTurnWatcher drawWatcher; "
                    "drawWatcher.getCardsDrawnThisTurn(event.getPlayerId()) == 2; "
                    "CastSpellLastTurnWatcher spellWatcher; "
                    "spellWatcher.getAmountOfSpellsPlayerCastOnCurrentTurn(event.getPlayerId()) == 2; "
                    "new DrawCardSourceControllerEffect(1)"
                ),
            },
            "If an opponent would begin an extra turn, that player skips that turn instead. "
            "Whenever an opponent attacks you with two or more creatures, draws their second card each turn, "
            "or casts their second spell each turn, you draw a card.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "draw_engine")
        self.assertEqual(
            primary["battle_model_scope"],
            "opponent_second_draw_second_spell_two_attackers_draw_v1",
        )
        self.assertTrue(primary["skip_opponent_extra_turns"])
        self.assertTrue(primary["opponent_attacks_you_with_two_or_more_creatures_draw"])
        self.assertTrue(primary["opponent_second_card_draw_each_turn"])
        self.assertTrue(primary["opponent_second_spell_each_turn"])
        self.assertEqual(primary["trigger"], "opponent_second_spell")
        self.assertEqual(primary["tax"], 0)
        self.assertEqual(primary["draw_count"], 1)

    def test_deflecting_palm_maps_to_exact_prevent_reflect_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "DeflectingPalm",
                "effect_classes": ["PreventNextDamageFromChosenSourceEffect"],
                "ability_classes": [],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["INSTANT"]},
                "raw_excerpt": (
                    "new PreventNextDamageFromChosenSourceEffect(Duration.EndOfTurn, true, "
                    "DeflectingPalmPreventionApplier.instance); "
                    "objectController.damage(prevented, source.getSourceId(), source, game);"
                ),
            },
            "The next time a source of your choice would deal damage to you this turn, "
            "prevent that damage. If damage is prevented this way, Deflecting Palm deals "
            "that much damage to that source's controller.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "damage_prevention_reflect")
        self.assertEqual(
            primary["battle_model_scope"],
            "prevent_next_damage_from_chosen_source_to_you_reflect_to_controller_v1",
        )
        self.assertTrue(primary["instant"])
        self.assertTrue(primary["prevent_next_damage_from_chosen_source"])
        self.assertEqual(primary["prevent_damage_to"], "you")
        self.assertEqual(primary["prevent_damage_duration"], "until_end_of_turn")
        self.assertTrue(primary["reflect_prevented_damage"])
        self.assertEqual(primary["reflect_target"], "chosen_source_controller")
        self.assertTrue(primary["source_choice_required"])

    def test_penance_maps_to_exact_activated_prevention_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Penance",
                "effect_classes": ["PreventNextDamageFromChosenSourceEffect"],
                "ability_classes": ["SimpleActivatedAbility"],
                "cost_classes": ["PutCardFromHandOnTopOfLibraryCost"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "new SimpleActivatedAbility(new PreventNextDamageFromChosenSourceEffect("
                    "Duration.EndOfTurn, false, filter), new PutCardFromHandOnTopOfLibraryCost()); "
                    "new FilterSource(\"black or red source\");"
                ),
            },
            "Put a card from your hand on top of your library: The next time a black or red "
            "source of your choice would deal damage this turn, prevent that damage.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "damage_prevention_shield")
        self.assertEqual(
            primary["battle_model_scope"],
            "activated_put_card_from_hand_on_top_library_prevent_next_damage_from_chosen_black_or_red_source_to_you_v1",
        )
        self.assertTrue(primary["activated_prevent_next_damage_from_chosen_source"])
        self.assertEqual(primary["activation_cost"], "put_card_from_hand_on_top_of_library")
        self.assertEqual(primary["activation_cost_generic"], 0)
        self.assertTrue(primary["activation_requires_put_card_from_hand_on_top_library"])
        self.assertTrue(primary["prevent_next_damage_from_chosen_source"])
        self.assertEqual(primary["prevent_damage_to"], "you")
        self.assertEqual(primary["prevent_damage_duration"], "until_end_of_turn")
        self.assertEqual(primary["prevent_damage_amount"], 999)
        self.assertTrue(primary["source_choice_required"])
        self.assertEqual(primary["source_color_filter"], ["black", "red"])

    def test_hidden_retreat_maps_to_exact_spell_prevention_topdeck_scope(self) -> None:
        entry = {
            "xmage_class_name": "HiddenRetreat",
            "effect_classes": ["HiddenRetreatEffect"],
            "ability_classes": ["SimpleActivatedAbility"],
            "cost_classes": ["PutCardFromHandOnTopOfLibraryCost"],
            "target_classes": ["TargetSpell"],
            "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
            "raw_excerpt": (
                "Ability ability = new SimpleActivatedAbility(new HiddenRetreatEffect(), "
                "new PutCardFromHandOnTopOfLibraryCost()); "
                "ability.addTarget(new TargetSpell(StaticFilters.FILTER_SPELL_INSTANT_OR_SORCERY)); "
                "class HiddenRetreatEffect extends PreventionEffectImpl { "
                "super(Duration.EndOfTurn, Integer.MAX_VALUE, false, false); "
                "game.getObject(source.getFirstTarget()).isInstantOrSorcery(game);"
            ),
        }
        result = hints.build_effect_hints(
            entry,
            "Put a card from your hand on top of your library: Prevent all damage that "
            "would be dealt by target instant or sorcery spell this turn.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "damage_prevention_shield")
        self.assertEqual(
            primary["battle_model_scope"],
            "activated_put_card_from_hand_on_top_library_prevent_damage_from_target_instant_or_sorcery_spell_v1",
        )
        self.assertTrue(primary["activated_prevent_damage_from_target_spell"])
        self.assertEqual(primary["activation_cost"], "put_card_from_hand_on_top_of_library")
        self.assertEqual(primary["activation_cost_generic"], 0)
        self.assertTrue(primary["activation_requires_put_card_from_hand_on_top_library"])
        self.assertTrue(primary["can_setup_lorehold_miracle_draw"])
        self.assertTrue(primary["prevent_damage_from_target_spell"])
        self.assertEqual(primary["prevent_damage_target_type"], "instant_or_sorcery_spell")
        self.assertEqual(primary["prevent_damage_duration"], "until_end_of_turn")
        self.assertEqual(primary["prevent_damage_amount"], 999)
        self.assertTrue(primary["spell_target_required"])
        self.assertEqual(primary["target_spell_card_types"], ["instant", "sorcery"])

        card = {
            "card_name": "Hidden Retreat",
            "ready_for_structured_pull": True,
            "status": "xmage_source_valid_mapper_required",
            "xmage": {
                "types": ["ENCHANTMENT"],
                "ability_classes": entry["ability_classes"],
                "effect_classes": entry["effect_classes"],
                "cost_classes": entry["cost_classes"],
                "target_classes": entry["target_classes"],
                "primary_effect": primary,
            },
        }
        self.assertTrue(classifier.exact_scope_batch_safe(card))
        classified = classifier.classify_card(card)
        self.assertEqual(classified["family_id"], "damage_prevention_shield")
        self.assertEqual(classified["promotion_lane"], "batch_metadata_candidate_requires_pg_precheck")

    def test_magmakin_artillerist_maps_to_exact_discard_damage_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "MagmakinArtillerist",
                "effect_classes": ["DamagePlayersEffect"],
                "ability_classes": [
                    "DiscardOneOrMoreCardsTriggeredAbility",
                    "CyclingAbility",
                    "CycleTriggeredAbility",
                ],
                "cost_classes": ["ManaCostsImpl"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "new DiscardOneOrMoreCardsTriggeredAbility(new DamagePlayersEffect("
                    "SavedDiscardValue.MUCH, TargetController.OPPONENT)); "
                    "new CyclingAbility(new ManaCostsImpl<>(\"{1}{R}\")); "
                    "new CycleTriggeredAbility(new DamagePlayersEffect(1, TargetController.OPPONENT, \"it\"));"
                ),
            },
            "Whenever you discard one or more cards, Magmakin Artillerist deals that much damage "
            "to each opponent. Cycling {1}{R}. When you cycle this card, it deals 1 damage to each opponent.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "controller_discards_one_or_more_damage_each_opponent_cycling_ping_annotation_v1",
        )
        self.assertEqual(primary["power"], 1)
        self.assertEqual(primary["toughness"], 4)
        self.assertEqual(primary["trigger"], "controller_discard")
        self.assertEqual(primary["controller_discard_damage_each_opponent"], 1)
        self.assertEqual(primary["controller_discard_count_mode"], "discarded_cards")
        self.assertEqual(primary["cycling_cost"], "{1}{R}")
        self.assertEqual(primary["cycling_status"], "annotation_only")
        self.assertEqual(primary["cycle_trigger_damage_each_opponent"], 1)
        self.assertEqual(primary["cycle_trigger_status"], "annotation_only")

    def test_millikin_maps_to_exact_mana_creature_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Millikin",
                "effect_classes": [],
                "ability_classes": ["ColorlessManaAbility"],
                "cost_classes": ["MillCardsCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT", "CREATURE"]},
                "raw_excerpt": (
                    "this.power = new MageInt(0); "
                    "this.toughness = new MageInt(1); "
                    "ColorlessManaAbility ability = new ColorlessManaAbility(); "
                    "ability.addCost(new MillCardsCost()); "
                    "ability.setUndoPossible(false);"
                ),
            },
            "{T}, Put the top card of your library into your graveyard: Add {C}.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(primary["battle_model_scope"], "zero_one_colorless_mana_dork_mill_one_v1")
        self.assertEqual(primary["power"], 0)
        self.assertEqual(primary["toughness"], 1)
        self.assertTrue(primary["is_mana_source"])
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "C")
        self.assertEqual(primary["mana_source_mill_count"], 1)
        self.assertEqual(primary["mana_source_mill_status"], "annotation_only")

    def test_tablet_of_discovery_maps_to_exact_red_spell_mana_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "TabletOfDiscovery",
                "effect_classes": ["OneShotEffect", "TabletOfDiscoveryEffect"],
                "ability_classes": [
                    "ConditionalColoredManaAbility",
                    "EntersBattlefieldTriggeredAbility",
                    "RedManaAbility",
                ],
                "cost_classes": [],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
                "raw_excerpt": (
                    "this.addAbility(new EntersBattlefieldTriggeredAbility(new TabletOfDiscoveryEffect())); "
                    "this.addAbility(new RedManaAbility()); "
                    "Ability ability = new ConditionalColoredManaAbility(new Mana(0, 0, 0, 2, 0, 0, 0, 0), "
                    "new InstantOrSorcerySpellManaBuilder());"
                ),
            },
            "When this artifact enters, mill a card. You may play that card this turn. {T}: Add {R}. "
            "{T}: Add {R}{R}. Spend this mana only to cast instant and sorcery spells.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "ramp_permanent")
        self.assertEqual(
            primary["battle_model_scope"],
            "artifact_etb_mill_one_play_milled_card_this_turn_red_spell_mana_v1",
        )
        self.assertTrue(primary["is_mana_source"])
        self.assertEqual(primary["mana_produced"], 1)
        self.assertEqual(primary["produces"], "R")
        self.assertEqual(primary["etb_mill_count"], 1)
        self.assertTrue(primary["etb_milled_card_playable_this_turn"])
        self.assertEqual(primary["etb_milled_card_play_status"], "annotation_only")
        self.assertEqual(primary["conditional_instant_sorcery_mana_produced"], 2)
        self.assertEqual(primary["conditional_instant_sorcery_mana_color"], "R")
        self.assertEqual(primary["conditional_instant_sorcery_mana_status"], "annotation_only")

    def test_fable_maps_to_exact_saga_transform_copy_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "FableOfTheMirrorBreaker",
                "effect_classes": [
                    "CreateTokenEffect",
                    "DiscardAndDrawThatManyEffect",
                    "ExileSagaAndReturnTransformedEffect",
                    "CreateTokenCopyTargetEffect",
                ],
                "ability_classes": ["SagaAbility", "SimpleActivatedAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "new SagaAbility(this.getLeftHalfCard()); "
                    "new CreateTokenEffect(new FableOfTheMirrorBreakerToken()); "
                    "new DiscardAndDrawThatManyEffect(2); "
                    "new ExileSagaAndReturnTransformedEffect(); "
                    "class ReflectionOfKikiJikiEffect extends OneShotEffect { "
                    "new CreateTokenCopyTargetEffect(null, null, true); }"
                ),
            },
            "I — Create a 2/2 red Goblin Shaman creature token. "
            "II — You may discard up to two cards. If you do, draw that many cards. "
            "III — Exile this Saga, then return it transformed. "
            "{1}, {T}: Create a token that's a copy of another target nonlegendary creature you control, "
            "except it has haste. Sacrifice it at the beginning of the next end step.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "token_maker")
        self.assertEqual(primary["battle_model_scope"], "saga_goblin_rummage_transform_reflection_copy_v1")
        self.assertEqual(primary["saga_chapter_effects"]["1"]["token_subtype"], "Goblin Shaman")
        self.assertEqual(primary["saga_chapter_effects"]["2"]["max_discard"], 2)
        self.assertEqual(primary["transform_to"]["name"], "Reflection of Kiki-Jiki")
        self.assertTrue(primary["transform_to"]["activated_copy_target_another_nonlegendary_creature_you_control"])

    def test_locust_god_maps_to_exact_draw_token_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "TheLocustGod",
                "effect_classes": [
                    "CreateTokenEffect",
                    "DrawDiscardControllerEffect",
                    "CreateDelayedTriggeredAbilityEffect",
                ],
                "ability_classes": [
                    "DrawCardControllerTriggeredAbility",
                    "SimpleActivatedAbility",
                    "DiesSourceTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
                "raw_excerpt": (
                    "new DrawCardControllerTriggeredAbility(new CreateTokenEffect(new TheLocustGodInsectToken(), 1, false, false), false); "
                    "new SimpleActivatedAbility(new DrawDiscardControllerEffect(1, 1, false), new ManaCostsImpl<>(\"{2}{U}{R}\")); "
                    "new CreateDelayedTriggeredAbilityEffect(new AtTheBeginOfNextEndStepDelayedTriggeredAbility(new ReturnToHandTargetEffect()))"
                ),
            },
            "Flying. Whenever you draw a card, create a 1/1 blue and red Insect creature token with flying and haste. "
            "{2}{U}{R}: Draw a card, then discard a card. When The Locust God dies, return it to its owner's hand.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "creature")
        self.assertEqual(
            primary["battle_model_scope"],
            "controller_draw_create_1_1_flying_haste_insect_token_loot_death_return_v1",
        )
        self.assertTrue(primary["controller_draw_create_token"])
        self.assertEqual(primary["token_subtype"], "Insect")
        self.assertTrue(primary["token_flying"])
        self.assertTrue(primary["token_haste"])

    def test_biotransference_maps_to_exact_artifact_spell_token_scope(self) -> None:
        result = hints.build_effect_hints(
            {
                "xmage_class_name": "Biotransference",
                "effect_classes": [
                    "ModifyObjectAllMultiZoneEffect",
                    "LoseLifeSourceControllerEffect",
                    "CreateTokenEffect",
                ],
                "ability_classes": ["SimpleStaticAbility", "SpellCastControllerTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                "raw_excerpt": (
                    "new SimpleStaticAbility(new BiotransferenceEffect()); "
                    "new SpellCastControllerTriggeredAbility(new LoseLifeSourceControllerEffect(1), StaticFilters.FILTER_SPELL_AN_ARTIFACT, false); "
                    "new CreateTokenEffect(new NecronWarriorToken(), 1); "
                    "class BiotransferenceEffect extends ModifyObjectAllMultiZoneEffect"
                ),
            },
            "Creatures you control are artifacts in addition to their other types. "
            "The same is true for creature spells you control and creature cards you own that aren't on the battlefield. "
            "Whenever you cast an artifact spell, you lose 1 life and create a 2/2 black Necron Warrior artifact creature token.",
        )

        primary = result["primary_candidate"]["effect_json"]
        self.assertEqual(primary["effect"], "token_maker")
        self.assertEqual(
            primary["battle_model_scope"],
            "controlled_creatures_are_artifacts_artifact_spell_life_loss_necron_token_v1",
        )
        self.assertTrue(primary["trigger_artifact_spell"])
        self.assertTrue(primary["controlled_creatures_and_creature_spells_are_artifacts"])
        self.assertEqual(primary["controller_loses_life_on_trigger"], 1)
        self.assertEqual(primary["token_subtype"], "Necron Warrior")

    def test_lorehold_manual_model_runtime_gap_cards_route_to_structured_review_families(self) -> None:
        cases = [
            (
                "AncientGoldDragon",
                {
                    "effect_classes": ["AncientGoldDragonEffect", "OneShotEffect"],
                    "ability_classes": ["DealsCombatDamageToAPlayerTriggeredAbility", "FlyingAbility"],
                    "constructor_metadata": {"card_types": ["CREATURE"]},
                },
                "token_maker",
                "xmage_combat_damage_d20_faerie_dragon_token_review_v1",
            ),
            (
                "BloodMoon",
                {
                    "effect_classes": ["NonbasicLandsAreMountainsEffect"],
                    "ability_classes": ["SimpleStaticAbility"],
                    "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                },
                "passive",
                "xmage_nonbasic_lands_are_mountains_static_review_v1",
            ),
            (
                "ChandrasIgnition",
                {
                    "effect_classes": ["ChandrasIgnitionEffect", "OneShotEffect"],
                    "ability_classes": [],
                    "target_classes": ["TargetControlledCreaturePermanent"],
                    "constructor_metadata": {"card_types": ["SORCERY"]},
                },
                "sweeper_damage",
                "xmage_controlled_creature_power_damage_each_other_creature_each_opponent_review_v1",
            ),
            (
                "DeathbellowWarCry",
                {
                    "effect_classes": ["SearchLibraryPutInPlayEffect"],
                    "ability_classes": [],
                    "cost_classes": [],
                    "target_classes": ["TargetCardWithDifferentNameInLibrary"],
                    "constructor_metadata": {"card_types": ["SORCERY"]},
                    "raw_excerpt": (
                        "new SearchLibraryPutInPlayEffect(new "
                        "TargetCardWithDifferentNameInLibrary(0, 4, minotaurFilter)); "
                        "FilterCreatureCard(\"Minotaur creature cards with different names\"); "
                        "minotaurFilter.add(SubType.MINOTAUR.getPredicate());"
                    ),
                },
                "tutor",
                "up_to_four_different_name_minotaur_creatures_to_battlefield_v1",
            ),
            (
                "GhoulcallersBell",
                {
                    "effect_classes": ["MillCardsEachPlayerEffect"],
                    "ability_classes": ["SimpleActivatedAbility"],
                    "cost_classes": ["TapSourceCost"],
                    "constructor_metadata": {"card_types": ["ARTIFACT"]},
                },
                "mill_engine",
                "artifact_tap_each_player_mill_one_v1",
            ),
            (
                "KarnTheGreatCreator",
                {
                    "effect_classes": [
                        "KarnTheGreatCreatorAnimateEffect",
                        "KarnTheGreatCreatorCantActivateEffect",
                        "RestrictionEffect",
                        "WishEffect",
                    ],
                    "ability_classes": ["LoyaltyAbility", "SimpleStaticAbility"],
                    "target_classes": ["TargetPermanent"],
                    "filter_classes": ["FilterArtifactPermanent", "FilterPermanent"],
                    "constructor_metadata": {"card_types": ["PLANESWALKER"]},
                },
                "passive",
                "xmage_artifact_activation_lock_planeswalker_wish_review_v1",
            ),
            (
                "KaylasMusicBox",
                {
                    "effect_classes": [
                        "ContinuousEffect",
                        "KaylasMusicBoxExileEffect",
                        "KaylasMusicBoxLookEffect",
                        "KaylasMusicBoxPlayFromExileEffect",
                        "OneShotEffect",
                    ],
                    "ability_classes": ["SimpleActivatedAbility"],
                    "cost_classes": ["TapSourceCost"],
                    "constructor_metadata": {"card_types": ["ARTIFACT"]},
                },
                "free_cast",
                "artifact_w_tap_exile_top_face_down_tap_play_owned_exiled_until_eot_v1",
            ),
            (
                "LanternOfInsight",
                {
                    "effect_classes": [
                        "PlayWithTheTopCardRevealedEffect",
                        "ShuffleLibraryTargetEffect",
                    ],
                    "ability_classes": ["SimpleActivatedAbility", "SimpleStaticAbility"],
                    "cost_classes": ["SacrificeSourceCost", "TapSourceCost"],
                    "target_classes": ["TargetPlayer"],
                    "constructor_metadata": {"card_types": ["ARTIFACT"]},
                },
                "topdeck_play",
                "each_player_top_library_revealed_tap_sacrifice_target_player_shuffle_v1",
            ),
            (
                "LeylineDowser",
                {
                    "effect_classes": ["MillThenPutInHandEffect", "UntapSourceEffect"],
                    "ability_classes": ["SimpleActivatedAbility"],
                    "cost_classes": ["GenericManaCost", "TapSourceCost", "TapTargetCost"],
                    "target_classes": ["TargetControlledPermanent"],
                    "filter_classes": ["FilterControlledCreaturePermanent"],
                    "constructor_metadata": {"card_types": ["ARTIFACT"]},
                },
                "recursion",
                "pay_one_tap_mill_one_instant_sorcery_to_hand_tap_legendary_creature_to_untap_v1",
            ),
            (
                "OrcishSpy",
                {
                    "effect_classes": ["LookLibraryTopCardTargetPlayerEffect"],
                    "ability_classes": ["SimpleActivatedAbility"],
                    "cost_classes": ["TapSourceCost"],
                    "target_classes": ["TargetPlayer"],
                    "constructor_metadata": {"card_types": ["CREATURE"]},
                },
                "topdeck_play",
                "tap_look_top_three_target_player_library_v1",
            ),
            (
                "PossibilityStorm",
                {
                    "effect_classes": ["OneShotEffect", "PossibilityStormEffect"],
                    "ability_classes": ["PossibilityStormTriggeredAbility"],
                    "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
                },
                "free_cast",
                "spell_from_hand_exile_until_shared_type_free_cast_bottom_rest_random_v1",
            ),
            (
                "PrototypePortal",
                {
                    "effect_classes": [
                        "OneShotEffect",
                        "PrototypePortalCreateTokenEffect",
                        "PrototypePortalEffect",
                    ],
                    "ability_classes": [
                        "EntersBattlefieldTriggeredAbility",
                        "SimpleActivatedAbility",
                    ],
                    "cost_classes": ["TapSourceCost"],
                    "target_classes": ["TargetCard"],
                    "constructor_metadata": {"card_types": ["ARTIFACT"]},
                },
                "token_maker",
                "imprint_artifact_from_hand_create_token_copy_x_mana_value_v1",
            ),
            (
                "PyxisOfPandemonium",
                {
                    "effect_classes": [
                        "OneShotEffect",
                        "PyxisOfPandemoniumExileEffect",
                        "PyxisOfPandemoniumPutOntoBattlefieldEffect",
                    ],
                    "ability_classes": ["SimpleActivatedAbility"],
                    "cost_classes": ["GenericManaCost", "SacrificeSourceCost", "TapSourceCost"],
                    "constructor_metadata": {"card_types": ["ARTIFACT"]},
                },
                "free_cast",
                "tap_each_player_exile_top_face_down_seven_tap_sacrifice_put_exiled_permanents_onto_battlefield_v1",
            ),
        ]

        for class_name, entry, expected_effect, expected_scope in cases:
            with self.subTest(class_name=class_name):
                result = hints.build_effect_hints({"xmage_class_name": class_name, **entry})
                primary = result["primary_candidate"]["effect_json"]
                self.assertEqual(primary["effect"], expected_effect)
                self.assertEqual(primary["battle_model_scope"], expected_scope)
                self.assertNotEqual(primary["effect"], "external_reference_required_manual_model")
                if class_name in {
                    "DeathbellowWarCry",
                    "GhoulcallersBell",
                    "KaylasMusicBox",
                    "DeathbellowWarCry",
                    "LanternOfInsight",
                    "LeylineDowser",
                    "OrcishSpy",
                    "PossibilityStorm",
                    "PrototypePortal",
                    "PyxisOfPandemonium",
                }:
                    self.assertFalse(expected_scope.startswith("xmage_"))
                    self.assertFalse(expected_scope.endswith("_review_v1"))
                else:
                    self.assertTrue(expected_scope.startswith("xmage_"))
                if class_name == "KaylasMusicBox":
                    self.assertTrue(primary["activated_exile_top_card_face_down"])
                    self.assertEqual(primary["activation_cost_mana"], "{W}")
                    self.assertTrue(primary["activation_requires_tap"])
                    self.assertTrue(primary["activated_play_owned_cards_exiled_with_source_until_eot"])
                    self.assertTrue(primary["play_from_exile_requires_tap"])
                    self.assertEqual(primary["play_from_exile_duration"], "until_end_of_turn")
                    self.assertEqual(
                        primary["play_from_exile_owner_scope"],
                        "controller_owned_cards_exiled_with_source",
                    )
                    self.assertTrue(primary["play_lands_from_exile"])
                    self.assertFalse(primary["may_cast_without_paying_mana_cost"])
                    card = {
                        "card_name": "Kayla's Music Box",
                        "ready_for_structured_pull": True,
                        "status": "xmage_source_valid_mapper_required",
                        "xmage": {
                            "types": ["ARTIFACT"],
                            "ability_classes": entry.get("ability_classes", []),
                            "effect_classes": entry.get("effect_classes", []),
                            "cost_classes": entry.get("cost_classes", []),
                            "target_classes": entry.get("target_classes", []),
                            "primary_effect": primary,
                        },
                    }
                    self.assertTrue(classifier.exact_scope_batch_safe(card))
                if class_name == "DeathbellowWarCry":
                    self.assertEqual(primary["target"], "minotaur_creatures_to_battlefield")
                    self.assertEqual(primary["target_subtypes"], ["minotaur"])
                    self.assertEqual(primary["target_card_types"], ["creature"])
                    self.assertEqual(primary["tutor_destination"], "battlefield")
                    self.assertEqual(primary["max_targets"], 4)
                    self.assertEqual(primary["min_targets"], 0)
                    self.assertTrue(primary["requires_different_names"])
                    card = {
                        "card_name": "Deathbellow War Cry",
                        "ready_for_structured_pull": True,
                        "status": "xmage_source_valid_mapper_required",
                        "xmage": {
                            "class_name": class_name,
                            "types": ["SORCERY"],
                            "ability_classes": entry.get("ability_classes", []),
                            "effect_classes": entry.get("effect_classes", []),
                            "cost_classes": entry.get("cost_classes", []),
                            "target_classes": entry.get("target_classes", []),
                            "primary_effect": primary,
                        },
                    }
                    self.assertTrue(classifier.exact_scope_batch_safe(card))

    def test_generic_xmage_review_scope_never_promotes_to_batch_candidate(self) -> None:
        card = {
            "card_name": "Blood Moon",
            "ready_for_structured_pull": True,
            "status": "xmage_source_valid_mapper_required",
            "xmage": {
                "types": ["ENCHANTMENT"],
                "ability_classes": ["SimpleStaticAbility"],
                "effect_classes": ["NonbasicLandsAreMountainsEffect"],
                "primary_effect": {
                    "effect": "passive",
                    "battle_model_scope": "xmage_nonbasic_lands_are_mountains_static_review_v1",
                },
            },
        }
        family = classifier.FAMILY_DEFINITIONS["passive"]

        self.assertFalse(classifier.exact_scope_batch_safe(card))
        self.assertEqual(classifier.promotion_lane(card, family), "split_family_scope_review_required")

    def test_batch_generator_downgrades_stale_generic_review_batch_lane(self) -> None:
        proposal = generator.build_proposal(
            {
                "card_name": "Blood Moon",
                "normalized_name": "blood moon",
                "family_id": "passive",
                "effect": "passive",
                "battle_model_scope": "xmage_nonbasic_lands_are_mountains_static_review_v1",
                "promotion_lane": "batch_metadata_candidate_requires_pg_precheck",
                "focused_test_scenario_count": 2,
                "effect_json": {
                    "effect": "passive",
                    "battle_model_scope": "xmage_nonbasic_lands_are_mountains_static_review_v1",
                },
            },
            {"candidate_rule": {"oracle_hash": "abc123", "effect_json": {}}},
        )

        self.assertEqual(proposal["proposal_status"], "split_family_scope_review_required")
        self.assertFalse(proposal["safe_for_batch_pg_package"])
        self.assertEqual(proposal["review_status"], "needs_review")
        self.assertEqual(proposal["execution_status"], "review_only")


if __name__ == "__main__":
    unittest.main()
