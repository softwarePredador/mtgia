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


if __name__ == "__main__":
    unittest.main()
