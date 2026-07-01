#!/usr/bin/env python3
"""Tests for authoritative XMage exact-scope splitting."""

from __future__ import annotations

import unittest

import xmage_authoritative_exact_scope_split as split


def queue_row(
    unit: str,
    *,
    effect_classes: list[str],
    card_id: str = "card-1",
    ability_kind: str = "one_shot",
    ability_classes: list[str] | None = None,
):
    return {
        "card_id": card_id,
        "card_name": "Fixture Spell",
        "normalized_name": "fixture spell",
        "translation_lane": "xmage_authoritative_adapter_required",
        "adapter_work_unit": unit,
        "effect_json": {"ability_kind": ability_kind},
        "xmage_effect_classes": effect_classes,
        "xmage_ability_classes": ability_classes or [],
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

    def test_fixed_life_gain_spell_maps_to_life_total_change_runtime(self) -> None:
        row = queue_row(split.LIFE_UNIT, effect_classes=["GainLifeEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="You gain 7 life."),
            source_text="this.getSpellAbility().addEffect(new GainLifeEffect(7));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "life_total_change")
        self.assertEqual(effect["battle_model_scope"], split.LIFE_SCOPE)
        self.assertEqual(effect["life_gain_amount"], 7)
        self.assertEqual(effect["target"], "self")

    def test_life_gain_spell_with_condition_stays_blocked(self) -> None:
        row = queue_row(split.LIFE_UNIT, effect_classes=["GainLifeEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="You gain 4 life. If you control a creature, draw a card."),
            source_text="this.getSpellAbility().addEffect(new GainLifeEffect(4));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "life_gain_oracle_not_simple")

    def test_fixed_exile_target_spell_maps_destination_to_exile(self) -> None:
        row = queue_row(split.EXILE_UNIT, effect_classes=["ExileTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Exile target creature or enchantment."),
            source_text="this.getSpellAbility().addEffect(new ExileTargetEffect());",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "remove_permanent")
        self.assertEqual(effect["battle_model_scope"], split.EXILE_SCOPE)
        self.assertEqual(effect["target"], "creature_or_enchantment")
        self.assertEqual(effect["destination"], "exile")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature", "enchantment"]})

    def test_exile_spell_with_additional_cost_stays_blocked(self) -> None:
        row = queue_row(split.EXILE_UNIT, effect_classes=["ExileTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="As an additional cost to cast this spell, sacrifice a permanent. Exile target creature."),
            source_text=(
                "this.getSpellAbility().addCost(new SacrificeTargetCost());"
                "this.getSpellAbility().addEffect(new ExileTargetEffect());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "additional_cost_detected")

    def test_simple_artifact_mana_source_maps_to_ramp_permanent(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=["BasicManaEffect"],
            ability_kind="activated",
            ability_classes=["BlackManaAbility", "RedManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(type_line="Artifact", oracle_text="{T}: Add {B} or {R}."),
            source_text="this.addAbility(new BlackManaAbility()); this.addAbility(new RedManaAbility());",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "ramp_permanent")
        self.assertEqual(effect["battle_model_scope"], split.MANA_SCOPE)
        self.assertEqual(effect["produces"], "BR")
        self.assertEqual(effect["mana_produced"], 1)
        self.assertTrue(effect["activation_requires_tap"])
        self.assertEqual(effect["permanent_type"], "artifact")

    def test_simple_creature_mana_source_maps_to_ramp_permanent(self) -> None:
        row = queue_row(
            split.RAMP_CREATURE_UNIT,
            effect_classes=["AddManaOfAnyColorEffect"],
            ability_kind="activated",
            ability_classes=["AnyColorManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(type_line="Creature - Druid", oracle_text="{T}: Add one mana of any color."),
            source_text="this.addAbility(new AnyColorManaAbility());",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "ramp_permanent")
        self.assertEqual(effect["produces"], "WUBRG")
        self.assertEqual(effect["permanent_type"], "creature")

    def test_conditional_mana_source_stays_blocked(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=["BasicManaEffect"],
            ability_kind="activated",
            ability_classes=["ConditionalAnyColorManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(type_line="Artifact", oracle_text="{T}: Add one mana of any color."),
            source_text="this.addAbility(new ConditionalAnyColorManaAbility());",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "mana_source_unsafe_ability_class")

    def test_counter_target_creature_spell_maps_to_stack_constraints(self) -> None:
        row = queue_row(split.COUNTER_UNIT, effect_classes=["CounterTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Counter target creature spell."),
            source_text="this.getSpellAbility().addEffect(new CounterTargetEffect());",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "counter")
        self.assertEqual(effect["battle_model_scope"], split.COUNTER_SCOPE)
        self.assertEqual(effect["target"], "creature_spell")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "stack", "stack_object": "spell", "card_types": ["creature"]},
        )

    def test_counter_target_blue_spell_preserves_color_constraint(self) -> None:
        row = queue_row(split.COUNTER_UNIT, effect_classes=["CounterTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Counter target blue spell."),
            source_text="this.getSpellAbility().addEffect(new CounterTargetEffect());",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "blue_spell")
        self.assertEqual(effect["target_constraints"]["spell_colors"], ["U"])
        self.assertTrue(effect["requires_blue_target"])

    def test_counter_spell_with_unless_clause_stays_blocked(self) -> None:
        row = queue_row(split.COUNTER_UNIT, effect_classes=["CounterTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Counter target spell unless its controller pays {1}."),
            source_text="this.getSpellAbility().addEffect(new CounterTargetEffect());",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "counter_oracle_not_simple")

    def test_counter_spell_with_compound_effect_stays_blocked(self) -> None:
        row = queue_row(
            split.COUNTER_UNIT,
            effect_classes=["CounterTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Counter target spell. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new CounterTargetEffect());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "counter_effect_class_not_pure")

    def test_return_target_creature_to_hand_maps_to_bounce_runtime_destination(self) -> None:
        row = queue_row(split.BOUNCE_UNIT, effect_classes=["ReturnToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Return target creature to its owner's hand."),
            source_text="this.getSpellAbility().addEffect(new ReturnToHandTargetEffect());",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "remove_creature")
        self.assertEqual(effect["battle_model_scope"], split.BOUNCE_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["destination"], "hand")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"]})

    def test_return_target_nonland_permanent_to_hand_maps_to_permanent_bounce(self) -> None:
        row = queue_row(split.BOUNCE_UNIT, effect_classes=["ReturnToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Return target nonland permanent to its owner's hand."),
            source_text="this.getSpellAbility().addEffect(new ReturnToHandTargetEffect());",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "remove_permanent")
        self.assertEqual(effect["target"], "nonland_permanent")
        self.assertEqual(effect["destination"], "hand")

    def test_bounce_spell_with_compound_effect_stays_blocked(self) -> None:
        row = queue_row(
            split.BOUNCE_UNIT,
            effect_classes=["ReturnToHandTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Return target creature to its owner's hand. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new ReturnToHandTargetEffect());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "bounce_effect_class_not_pure")

    def test_graveyard_to_hand_spell_maps_to_recursion_runtime(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Return target instant or sorcery card from your graveyard to your hand."),
            source_text="this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "recursion")
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_SCOPE)
        self.assertEqual(effect["target"], "instant_or_sorcery")
        self.assertEqual(effect["count"], 1)
        self.assertEqual(effect["destination"], "hand")
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["instant", "sorcery"]},
        )

    def test_graveyard_to_hand_up_to_two_creatures_preserves_count(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Return up to two target creature cards from your graveyard to your hand."),
            source_text="this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["count"], 2)
        self.assertTrue(effect["up_to_count"])

    def test_graveyard_to_hand_modal_spell_stays_blocked(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Choose one or both — Return target creature card from your graveyard to your hand. "
                    "Return target artifact card from your graveyard to your hand."
                )
            ),
            source_text="this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "recursion_oracle_not_simple")

    def test_graveyard_to_hand_additional_cost_stays_blocked(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "As an additional cost to cast this spell, discard a card. "
                    "Return target creature card from your graveyard to your hand."
                )
            ),
            source_text=(
                "this.getSpellAbility().addCost(new DiscardCardCost());"
                "this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "additional_cost_detected")

    def test_destroy_all_creatures_maps_to_board_wipe_scope(self) -> None:
        row = queue_row(split.BOARD_WIPE_UNIT, effect_classes=["DestroyAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy all creatures. They can't be regenerated."),
            source_text="this.getSpellAbility().addEffect(new DestroyAllEffect(filter));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "board_wipe")
        self.assertEqual(effect["battle_model_scope"], split.BOARD_WIPE_SCOPE)
        self.assertEqual(effect["destroy_card_types"], ["creature"])
        self.assertEqual(effect["destination"], "graveyard")

    def test_damage_all_creatures_maps_to_damage_wipe_scope(self) -> None:
        row = queue_row(split.BOARD_WIPE_UNIT, effect_classes=["DamageAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Fixture Sweep deals 2 damage to each creature."),
            source_text="this.getSpellAbility().addEffect(new DamageAllEffect(2));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "damage_wipe")
        self.assertEqual(effect["battle_model_scope"], split.DAMAGE_WIPE_SCOPE)
        self.assertEqual(effect["damage"], 2)
        self.assertEqual(effect["damage_scope"], "each_creature")

    def test_storm_inside_card_name_does_not_count_as_complexity_keyword(self) -> None:
        row = queue_row(split.BOARD_WIPE_UNIT, effect_classes=["DamageAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Storm's Wrath deals 4 damage to each creature and each planeswalker."),
            source_text="this.getSpellAbility().addEffect(new DamageAllEffect(4));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertEqual(proposal["effect_json"]["damage_scope"], "each_creature_and_planeswalker")

    def test_storm_mechanic_word_still_blocks_simple_spell_package(self) -> None:
        self.assertTrue(split.has_oracle_complexity(metadata(oracle_text="Draw a card. Storm")))

    def test_board_wipe_with_conditional_replacement_stays_blocked(self) -> None:
        row = queue_row(split.BOARD_WIPE_UNIT, effect_classes=["DamageAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Fixture Sweep deals 3 damage to each creature. "
                    "If a creature dealt damage this way would die this turn, exile it instead."
                )
            ),
            source_text="this.getSpellAbility().addEffect(new DamageAllEffect(3));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "board_wipe_oracle_not_simple")

    def test_board_wipe_selective_scope_stays_blocked(self) -> None:
        row = queue_row(split.BOARD_WIPE_UNIT, effect_classes=["DestroyAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy all creatures with toughness 4 or greater."),
            source_text="this.getSpellAbility().addEffect(new DestroyAllEffect(filter));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "board_wipe_destroy_scope_not_supported")

    def test_fixed_plus_one_counter_target_creature_maps_to_add_counters_runtime(self) -> None:
        row = queue_row(split.ADD_COUNTERS_TARGET_UNIT, effect_classes=["AddCountersTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Put a +1/+1 counter on target creature."),
            source_text=(
                "this.getSpellAbility().addEffect(new AddCountersTargetEffect("
                "CounterType.P1P1.createInstance()));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "add_counters")
        self.assertEqual(effect["battle_model_scope"], split.ADD_COUNTERS_TARGET_SCOPE)
        self.assertEqual(effect["counter_type"], "+1/+1")
        self.assertEqual(effect["counter_count"], 1)
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"]})

    def test_fixed_minus_one_counters_target_creature_preserves_count(self) -> None:
        row = queue_row(split.ADD_COUNTERS_TARGET_UNIT, effect_classes=["AddCountersTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Put four -1/-1 counters on target creature."),
            source_text=(
                "this.getSpellAbility().addEffect(new AddCountersTargetEffect("
                "CounterType.M1M1.createInstance(4)));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["counter_type"], "-1/-1")
        self.assertEqual(effect["counter_count"], 4)

    def test_add_counters_multi_target_spell_stays_blocked(self) -> None:
        row = queue_row(split.ADD_COUNTERS_TARGET_UNIT, effect_classes=["AddCountersTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Put a +1/+1 counter on each of up to two target creatures."),
            source_text=(
                "this.getSpellAbility().addEffect(new AddCountersTargetEffect("
                "CounterType.P1P1.createInstance()));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent(0, 2));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "add_counters_counter_not_fixed")

    def test_fixed_boost_target_creature_maps_to_stat_modifier_until_eot(self) -> None:
        row = queue_row(split.BOOST_TARGET_UNIT, effect_classes=["BoostTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Target creature gets +3/+3 until end of turn."),
            source_text=(
                "this.getSpellAbility().getEffects().add(new BoostTargetEffect("
                "3, 3, Duration.EndOfTurn));"
                "this.getSpellAbility().getTargets().add(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "stat_modifier_until_eot")
        self.assertEqual(effect["battle_model_scope"], split.BOOST_TARGET_SCOPE)
        self.assertEqual(effect["power_delta"], 3)
        self.assertEqual(effect["toughness_delta"], 3)
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"]})

    def test_fixed_boost_allows_leading_mana_reminder_text(self) -> None:
        row = queue_row(split.BOOST_TARGET_UNIT, effect_classes=["BoostTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text="({G/P} can be paid with either {G} or 2 life.)\n"
                "Target creature gets +2/+2 until end of turn."
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostTargetEffect(2, 2));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertEqual(proposal["effect_json"]["power_delta"], 2)
        self.assertEqual(proposal["effect_json"]["toughness_delta"], 2)

    def test_boost_multi_target_spell_stays_blocked(self) -> None:
        row = queue_row(split.BOOST_TARGET_UNIT, effect_classes=["BoostTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Target creature gets +3/+3 until end of turn.\nTarget creature gets +3/+3 until end of turn."),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostTargetEffect(3, 3));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new BoostTargetEffect(3, 3).setTargetPointer(new SecondTargetPointer()));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "boost_target_source_not_single_fixed")

    def test_static_combat_keyword_creature_maps_to_creature_with_keywords(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::FlyingAbility,VigilanceAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["FlyingAbility", "VigilanceAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Creature - Bird",
                oracle_text="Flying, vigilance",
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "this.addAbility(VigilanceAbility.getInstance());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.STATIC_KEYWORD_CREATURE_SCOPE)
        self.assertEqual(effect["keywords"], ["flying", "vigilance"])
        self.assertTrue(effect["flying"])
        self.assertTrue(effect["vigilance"])
        self.assertTrue(effect["_keywords_are_self"])

    def test_static_keyword_creature_requires_oracle_keyword_match(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::FlyingAbility,VigilanceAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["FlyingAbility", "VigilanceAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Creature - Bird",
                oracle_text="Flying",
            ),
            source_text="",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_keyword_oracle_mismatch")

    def test_static_keyword_creature_blocks_protection_until_color_scope_exists(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::ProtectionAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["ProtectionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Creature - Cleric",
                oracle_text="Protection from black",
            ),
            source_text="this.addAbility(new ProtectionAbility(filter));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "unsupported_adapter_work_unit")

    def test_static_keyword_creature_requires_creature_type(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::FlyingAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["FlyingAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Artifact - Vehicle",
                oracle_text="Flying",
            ),
            source_text="this.addAbility(FlyingAbility.getInstance());",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_keyword_not_creature")

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
