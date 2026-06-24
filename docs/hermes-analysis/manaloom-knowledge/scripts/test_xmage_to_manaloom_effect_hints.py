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


if __name__ == "__main__":
    unittest.main()
