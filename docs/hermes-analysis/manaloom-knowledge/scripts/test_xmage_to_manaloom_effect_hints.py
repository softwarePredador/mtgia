#!/usr/bin/env python3
from __future__ import annotations

import unittest

import xmage_to_manaloom_effect_hints as hints


class XMageToManaLoomEffectHintsTests(unittest.TestCase):
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
        self.assertEqual(primary["produces"], "G")


if __name__ == "__main__":
    unittest.main()
