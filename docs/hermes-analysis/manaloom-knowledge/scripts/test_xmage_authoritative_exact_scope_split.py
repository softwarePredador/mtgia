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
    xmage_signals: list[str] | None = None,
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
        "xmage_signals": xmage_signals or [],
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
    def test_fixed_create_creature_tokens_spell_is_package_safe(self) -> None:
        row = queue_row(split.TOKEN_SPELL_UNIT, effect_classes=["CreateTokenEffect"], xmage_signals=["token"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Fodder",
                type_line="Sorcery",
                oracle_text="Create two 1/1 red Goblin creature tokens.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new CreateTokenEffect(new GoblinToken(), 2));
                class GoblinToken extends TokenImpl {
                    public GoblinToken() {
                        super("Goblin Token", "1/1 red Goblin creature token");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.GOBLIN);
                        color.setRed(true);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                    }
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "token_maker")
        self.assertEqual(effect["battle_model_scope"], split.TOKEN_SPELL_SCOPE)
        self.assertEqual(effect["token_count"], 2)
        self.assertEqual(effect["token_name"], "Goblin Token")
        self.assertEqual(effect["token_subtype"], "Goblin")
        self.assertEqual(effect["token_power"], 1)
        self.assertEqual(effect["token_toughness"], 1)
        self.assertEqual(effect["token_colors"], ["R"])

    def test_fixed_create_creature_tokens_spell_blocks_dynamic_count(self) -> None:
        row = queue_row(split.TOKEN_SPELL_UNIT, effect_classes=["CreateTokenEffect"], xmage_signals=["token"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Woods",
                type_line="Sorcery",
                oracle_text="Create X 1/1 green Forest Dryad land creature tokens.",
            ),
            source_text="this.getSpellAbility().addEffect(new CreateTokenEffect(new ForestDryadToken(), GetXValue.instance));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "token_source_create_token_not_fixed")

    def test_fixed_create_creature_tokens_spell_blocks_additional_tokens(self) -> None:
        row = queue_row(split.TOKEN_SPELL_UNIT, effect_classes=["CreateTokenEffect"], xmage_signals=["token"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Menace",
                type_line="Sorcery",
                oracle_text=(
                    "Create a 1/1 green Snake creature token, a 2/2 green Wolf "
                    "creature token, and a 3/3 green Elephant creature token."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new CreateTokenEffect(new SnakeToken())"
                ".withAdditionalTokens(new WolfToken(), new ElephantToken()));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "token_source_additional_tokens_not_supported")

    def test_fixed_create_creature_tokens_spell_blocks_unsupported_token_keyword(self) -> None:
        row = queue_row(split.TOKEN_SPELL_UNIT, effect_classes=["CreateTokenEffect"], xmage_signals=["token"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Wurm",
                type_line="Instant",
                oracle_text="Create a 5/5 green Wurm creature token with trample.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new CreateTokenEffect(new WurmWithTrampleToken()));
                class WurmWithTrampleToken extends TokenImpl {
                    public WurmWithTrampleToken() {
                        super("Wurm Token", "5/5 green Wurm creature token with trample");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.WURM);
                        color.setGreen(true);
                        power = new MageInt(5);
                        toughness = new MageInt(5);
                        addAbility(TrampleAbility.getInstance());
                    }
                }
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "token_description_keyword_not_supported")

    def test_creature_etb_create_tokens_is_package_safe(self) -> None:
        row = queue_row(
            split.ETB_TOKEN_CREATURE_UNIT,
            effect_classes=["CreateTokenEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["token", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Instigator",
                type_line="Creature - Goblin Rogue",
                oracle_text=(
                    "When Fixture Instigator enters the battlefield, create "
                    "two 1/1 red Goblin creature tokens."
                ),
            ),
            source_text="""
                this.addAbility(new EntersBattlefieldTriggeredAbility(
                    new CreateTokenEffect(new GoblinToken(), 2)));
                class GoblinToken extends TokenImpl {
                    public GoblinToken() {
                        super("Goblin Token", "1/1 red Goblin creature token");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.GOBLIN);
                        color.setRed(true);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                    }
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_TOKEN_CREATURE_SCOPE)
        self.assertEqual(effect["trigger"], "enters_battlefield")
        self.assertEqual(effect["etb_token_count"], 2)
        self.assertEqual(effect["etb_token_name"], "Goblin Token")
        self.assertEqual(effect["etb_token_subtype"], "Goblin")
        self.assertEqual(effect["etb_token_colors"], ["R"])

    def test_creature_etb_create_tokens_blocks_non_creature_token(self) -> None:
        row = queue_row(
            split.ETB_TOKEN_CREATURE_UNIT,
            effect_classes=["CreateTokenEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["token", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Pirate",
                type_line="Creature - Human Pirate",
                oracle_text="When Fixture Pirate enters the battlefield, create a Treasure token.",
            ),
            source_text="""
                this.addAbility(new EntersBattlefieldTriggeredAbility(
                    new CreateTokenEffect(new TreasureToken())));
                class TreasureToken extends TokenImpl {
                    public TreasureToken() {
                        super("Treasure Token", "colorless Treasure artifact token");
                        cardType.add(CardType.ARTIFACT);
                    }
                }
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "token_description_not_creature_token")

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

    def test_permanent_activated_draw_maps_simple_mana_and_tap_cost(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["draw", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Herald",
                type_line="Creature - Human Wizard",
                oracle_text="{3}{U}, {T}: Draw a card.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DrawCardSourceControllerEffect(1),
                    new ManaCostsImpl<>("{3}{U}")
                );
                ability.addCost(new TapSourceCost());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "draw_engine")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DRAW_SCOPE)
        self.assertEqual(effect["activated_draw_count"], 1)
        self.assertEqual(effect["activation_cost_generic"], 3)
        self.assertEqual(effect["activation_cost_colors"], ["U"])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertFalse(effect["activation_requires_sacrifice"])

    def test_permanent_activated_draw_maps_self_sacrifice_cost(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["draw", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Capsule",
                type_line="Artifact",
                oracle_text="{1}{U}, {T}, Sacrifice this artifact: Draw two cards.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DrawCardSourceControllerEffect(2),
                    new ManaCostsImpl<>("{1}{U}")
                );
                ability.addCost(new TapSourceCost());
                ability.addCost(new SacrificeSourceCost());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DRAW_SCOPE)
        self.assertEqual(effect["activated_draw_count"], 2)
        self.assertEqual(effect["draw_on_self_sacrifice"], 2)
        self.assertTrue(effect["activated_self_sacrifice_draw"])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])

    def test_permanent_activated_draw_blocks_discard_cost(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["draw", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Looter",
                type_line="Creature - Goblin",
                oracle_text="{R}, {T}, Discard a card: Draw a card.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DrawCardSourceControllerEffect(1),
                    new ManaCostsImpl<>("{R}")
                );
                ability.addCost(new TapSourceCost());
                ability.addCost(new DiscardCardCost());
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_draw_source_cost_not_supported")

    def test_permanent_activated_draw_blocks_dynamic_count(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["draw", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Loremaster",
                type_line="Creature - Merfolk Wizard",
                oracle_text="{T}: Draw a card for each Wizard you control.",
            ),
            source_text="""
                this.addAbility(new SimpleActivatedAbility(
                    new DrawCardSourceControllerEffect(WizardCount.instance),
                    new TapSourceCost()));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_draw_oracle_not_simple")

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

    def test_fixed_damage_gain_life_spell_maps_to_direct_damage_with_life_gain(self) -> None:
        row = queue_row(split.LIFE_UNIT, effect_classes=["DamageTargetEffect", "GainLifeEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Fixture Drain deals 3 damage to any target and you gain 2 life."),
            source_text=(
                "this.getSpellAbility().addEffect(new DamageTargetEffect(3));"
                "this.getSpellAbility().addEffect(new GainLifeEffect(2));"
                "this.getSpellAbility().addTarget(new TargetAnyTarget());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "direct_damage")
        self.assertEqual(effect["battle_model_scope"], split.DAMAGE_GAIN_LIFE_SCOPE)
        self.assertEqual(effect["amount"], 3)
        self.assertEqual(effect["gain_life"], 2)
        self.assertEqual(effect["target"], "any_target")

    def test_fixed_damage_gain_life_spell_allows_period_separated_life_gain(self) -> None:
        row = queue_row(split.LIFE_UNIT, effect_classes=["DamageTargetEffect", "GainLifeEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Fixture Drain deals 2 damage to target creature. You gain 2 life."),
            source_text=(
                "this.getSpellAbility().addEffect(new DamageTargetEffect(2));"
                "this.getSpellAbility().addEffect(new GainLifeEffect(2));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DAMAGE_GAIN_LIFE_SCOPE)
        self.assertEqual(effect["target"], "creature")

    def test_fixed_damage_gain_life_spell_blocks_variable_x(self) -> None:
        row = queue_row(split.LIFE_UNIT, effect_classes=["DamageTargetEffect", "GainLifeEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Fixture Drain deals X damage to any target and you gain X life."),
            source_text=(
                "this.getSpellAbility().addEffect(new DamageTargetEffect(GetXValue.instance));"
                "this.getSpellAbility().addEffect(new GainLifeEffect(GetXValue.instance));"
                "this.getSpellAbility().addTarget(new TargetAnyTarget());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "damage_life_gain_source_not_fixed")

    def test_destroy_gain_life_spell_maps_to_controller_life_gain(self) -> None:
        row = queue_row(split.LIFE_UNIT, effect_classes=["DestroyTargetEffect", "GainLifeEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy target artifact or enchantment. You gain 4 life."),
            source_text=(
                "this.getSpellAbility().addTarget(new TargetPermanent("
                "StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_ENCHANTMENT));"
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                "this.getSpellAbility().addEffect(new GainLifeEffect(4));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "remove_permanent")
        self.assertEqual(effect["battle_model_scope"], split.DESTROY_GAIN_LIFE_SCOPE)
        self.assertEqual(effect["target"], "artifact_or_enchantment")
        self.assertEqual(effect["controller_gains_life"], 4)
        self.assertEqual(effect["target_constraints"], {"card_types": ["artifact", "enchantment"]})

    def test_destroy_gain_life_spell_blocks_dynamic_life_gain(self) -> None:
        row = queue_row(split.LIFE_UNIT, effect_classes=["DestroyTargetEffect", "GainLifeEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy target artifact. You gain life equal to its mana value."),
            source_text=(
                "this.getSpellAbility().addTarget(new TargetArtifactPermanent());"
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                "this.getSpellAbility().addEffect(new GainLifeEffect(TargetManaValue.instance));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "destroy_life_gain_source_not_fixed")

    def test_destroy_gain_life_spell_blocks_restricted_target_filter(self) -> None:
        row = queue_row(split.LIFE_UNIT, effect_classes=["DestroyTargetEffect", "GainLifeEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy target tapped creature. You gain 2 life."),
            source_text=(
                "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                "this.getSpellAbility().addEffect(new GainLifeEffect(2));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "destroy_life_gain_source_not_fixed")

    def test_damage_spell_with_variable_x_stays_blocked(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Fixture Spell deals X damage to any target."),
            source_text="this.getSpellAbility().addEffect(new DamageTargetEffect(ManacostVariableValue.instance));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "damage_amount_not_fixed")

    def test_damage_spell_maps_attacking_or_blocking_creature_constraint(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Fixture Volley deals 4 damage to target attacking or blocking creature."),
            source_text=(
                "this.getSpellAbility().addEffect(new DamageTargetEffect(4));"
                "this.getSpellAbility().addTarget(new TargetAttackingOrBlockingCreature());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "combat_state": "attacking_or_blocking"},
        )

    def test_damage_spell_blocks_restricted_oracle_source_mismatch(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Fixture Volley deals 4 damage to target attacking or blocking creature."),
            source_text=(
                "this.getSpellAbility().addEffect(new DamageTargetEffect(4));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "damage_target_source_mismatch")

    def test_destroy_spell_maps_untapped_creature_constraint(self) -> None:
        row = queue_row(split.DESTROY_UNIT, effect_classes=["DestroyTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy target untapped creature."),
            source_text=(
                "filter.add(TappedPredicate.UNTAPPED);"
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "remove_creature")
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "tapped_state": "untapped"},
        )

    def test_destroy_spell_maps_filter_blocking_creature_constraint(self) -> None:
        row = queue_row(split.DESTROY_UNIT, effect_classes=["DestroyTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy target blocking creature."),
            source_text=(
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetPermanent(new FilterBlockingCreature()));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertEqual(
            proposal["effect_json"]["target_constraints"],
            {"card_types": ["creature"], "combat_state": "blocking"},
        )

    def test_exile_spell_maps_power_restricted_creature_constraint(self) -> None:
        row = queue_row(split.EXILE_UNIT, effect_classes=["ExileTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Exile target creature with power 4 or greater."),
            source_text=(
                "filter.add(new PowerPredicate(ComparisonType.MORE_THAN, 3));"
                "this.getSpellAbility().addEffect(new ExileTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "remove_creature")
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "power_min": 4})

    def test_exile_spell_maps_black_or_red_permanent_constraint(self) -> None:
        row = queue_row(split.EXILE_UNIT, effect_classes=["ExileTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Exile target black or red permanent."),
            source_text=(
                "new ColorPredicate(ObjectColor.BLACK);"
                "new ColorPredicate(ObjectColor.RED);"
                "FilterPermanent(\"black or red permanent\");"
                "this.getSpellAbility().addEffect(new ExileTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "remove_permanent")
        self.assertEqual(effect["target"], "permanent")
        self.assertEqual(effect["target_constraints"], {"card_types": ["permanent"], "target_colors": ["B", "R"]})

    def test_creature_tap_damage_maps_to_creature_with_activated_damage(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Archer",
                type_line="Creature - Human Archer",
                oracle_text="{T}: Fixture Archer deals 1 damage to any target.",
            ),
            source_text=(
                "this.addAbility(new SimpleActivatedAbility("
                "new DamageTargetEffect(1), new TapSourceCost()));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.CREATURE_TAP_DAMAGE_SCOPE)
        self.assertEqual(effect["activated_effect"], "direct_damage")
        self.assertEqual(effect["activated_damage_amount"], 1)
        self.assertEqual(effect["_activated_rule_effects"][0]["battle_model_scope"], split.TAP_DAMAGE_ACTIVATED_SCOPE)
        self.assertEqual(effect["_activated_rule_effects"][0]["target"], "any_target")

    def test_permanent_activated_damage_maps_creature_mana_tap_cost(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Shaman",
                type_line="Creature - Minotaur Shaman",
                oracle_text="{R}, {T}: Fixture Shaman deals 1 damage to any target.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(1),
                    new ManaCostsImpl<>("{R}")
                );
                ability.addCost(new TapSourceCost());
                ability.addTarget(new TargetAnyTarget());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DAMAGE_SCOPE)
        self.assertEqual(effect["activated_damage_amount"], 1)
        self.assertEqual(effect["target"], "any_target")
        self.assertEqual(effect["activation_cost_mana"], "{R}")
        self.assertEqual(effect["activation_cost_generic"], 0)
        self.assertEqual(effect["activation_cost_colors"], ["R"])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertFalse(effect["activation_requires_sacrifice"])
        self.assertEqual(effect["_activated_rule_effects"][0]["battle_model_scope"], split.PERMANENT_ACTIVATED_DAMAGE_SCOPE)

    def test_permanent_activated_damage_maps_artifact_tap_self_sacrifice(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Aeolipile",
                type_line="Artifact",
                oracle_text="{1}, {T}, Sacrifice this artifact: It deals 2 damage to any target.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(2),
                    new ManaCostsImpl<>("{1}")
                );
                ability.addCost(new TapSourceCost());
                ability.addCost(new SacrificeSourceCost());
                ability.addTarget(new TargetAnyTarget());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "artifact")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DAMAGE_SCOPE)
        self.assertEqual(effect["activated_damage_amount"], 2)
        self.assertEqual(effect["target"], "any_target")
        self.assertEqual(effect["activation_cost_mana"], "{1}")
        self.assertEqual(effect["activation_cost_generic"], 1)
        self.assertEqual(effect["activation_cost_colors"], [])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])
        self.assertTrue(effect["activated_self_sacrifice_damage"])

    def test_permanent_activated_damage_maps_creature_self_sacrifice_target_creature(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Lunatic",
                type_line="Creature - Barbarian",
                oracle_text="{2}{R}, Sacrifice this creature: It deals 2 damage to target creature.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(2),
                    new ManaCostsImpl<>("{2}{R}")
                );
                ability.addCost(new SacrificeSourceCost());
                ability.addTarget(new TargetCreaturePermanent());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DAMAGE_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"]})
        self.assertEqual(effect["activation_cost_mana"], "{2}{R}")
        self.assertEqual(effect["activation_cost_generic"], 2)
        self.assertEqual(effect["activation_cost_colors"], ["R"])
        self.assertFalse(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])

    def test_permanent_activated_damage_blocks_sacrifice_target_cost(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Dealer",
                type_line="Creature - Goblin Rogue",
                oracle_text="{R}, Sacrifice a Goblin: Fixture Dealer deals 4 damage to target creature.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(4),
                    new ManaCostsImpl<>("{R}")
                );
                ability.addCost(new SacrificeTargetCost(new TargetControlledCreaturePermanent()));
                ability.addTarget(new TargetCreaturePermanent());
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_damage_source_cost_not_supported")

    def test_permanent_activated_damage_blocks_dynamic_amount(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Elemental",
                type_line="Creature - Elemental",
                oracle_text="{X}{R}, Sacrifice this creature: It deals X damage to any target.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(ManacostVariableValue.instance),
                    new ManaCostsImpl<>("{X}{R}")
                );
                ability.addCost(new SacrificeSourceCost());
                ability.addTarget(new TargetAnyTarget());
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_damage_oracle_not_simple")

    def test_permanent_activated_damage_blocks_player_or_planeswalker_target(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Magmutt",
                type_line="Creature - Elemental Dog",
                oracle_text="{T}: Fixture Magmutt deals 1 damage to target player or planeswalker.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(1),
                    new TapSourceCost()
                );
                ability.addTarget(new TargetPlayerOrPlaneswalker());
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_damage_oracle_not_simple")

    def test_permanent_activated_destroy_maps_tapped_creature_target(self) -> None:
        row = queue_row(
            split.DESTROY_UNIT,
            effect_classes=["DestroyTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Assassin",
                type_line="Creature - Human Assassin",
                oracle_text="{T}: Destroy target tapped creature.",
            ),
            source_text="""
                filter.add(TappedPredicate.TAPPED);
                Ability ability = new SimpleActivatedAbility(
                    new DestroyTargetEffect(),
                    new TapSourceCost()
                );
                ability.addTarget(new TargetPermanent(filter));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DESTROY_SCOPE)
        self.assertEqual(effect["activated_effect"], "destroy_target")
        self.assertEqual(effect["activated_remove_effect"], "remove_creature")
        self.assertEqual(effect["activated_remove_target"], "tapped_creature")
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "tapped_state": "tapped"})
        self.assertEqual(effect["activation_cost_mana"], "{0}")
        self.assertTrue(effect["activation_requires_tap"])
        self.assertFalse(effect["activation_requires_sacrifice"])
        self.assertEqual(effect["_activated_rule_effects"][0]["battle_model_scope"], split.PERMANENT_ACTIVATED_DESTROY_SCOPE)

    def test_permanent_activated_destroy_maps_self_sacrifice_artifact_target(self) -> None:
        row = queue_row(
            split.DESTROY_UNIT,
            effect_classes=["DestroyTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Reveler",
                type_line="Creature - Devil",
                oracle_text="{R}, Sacrifice this creature: Destroy target artifact.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DestroyTargetEffect(),
                    new ManaCostsImpl<>("{R}")
                );
                ability.addCost(new SacrificeSourceCost());
                ability.addTarget(new TargetArtifactPermanent());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DESTROY_SCOPE)
        self.assertEqual(effect["activated_remove_effect"], "remove_permanent")
        self.assertEqual(effect["activated_remove_target"], "artifact")
        self.assertEqual(effect["target"], "artifact")
        self.assertEqual(effect["activation_cost_mana"], "{R}")
        self.assertEqual(effect["activation_cost_colors"], ["R"])
        self.assertFalse(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])
        self.assertTrue(effect["activated_self_sacrifice_destroy"])

    def test_permanent_activated_destroy_blocks_sacrifice_target_cost(self) -> None:
        row = queue_row(
            split.DESTROY_UNIT,
            effect_classes=["DestroyTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Attrition",
                type_line="Enchantment",
                oracle_text="{B}, Sacrifice a creature: Destroy target nonblack creature.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DestroyTargetEffect(),
                    new ManaCostsImpl<>("{B}")
                );
                ability.addCost(new SacrificeTargetCost(new TargetControlledCreaturePermanent()));
                ability.addTarget(new TargetCreaturePermanent(
                    StaticFilters.FILTER_PERMANENT_CREATURE_NON_BLACK
                ));
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_destroy_source_cost_not_supported")

    def test_permanent_activated_destroy_blocks_extra_oracle_clause(self) -> None:
        row = queue_row(
            split.DESTROY_UNIT,
            effect_classes=["DestroyTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Miner",
                type_line="Creature - Dwarf",
                oracle_text="{2}{R}, {T}: Destroy target nonbasic land. Activate only during your turn.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DestroyTargetEffect(),
                    new ManaCostsImpl<>("{2}{R}")
                );
                ability.addCost(new TapSourceCost());
                ability.addTarget(new TargetLandPermanent());
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_destroy_oracle_not_simple")

    def test_creature_etb_damage_maps_to_triggered_creature_scope(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Boulderfoot",
                type_line="Creature - Giant Warrior",
                oracle_text="When this creature enters, it deals 1 damage to any target.",
            ),
            source_text=(
                "this.addAbility(new EntersBattlefieldTriggeredAbility("
                "new DamageTargetEffect(1)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_DAMAGE_CREATURE_SCOPE)
        self.assertEqual(effect["etb_damage_amount"], 1)
        self.assertEqual(effect["etb_damage_target"], "any_target")

    def test_creature_etb_damage_blocks_variable_amount(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Ravager",
                type_line="Creature - Giant Wizard",
                oracle_text=(
                    "When this creature enters, it deals X damage to any target, "
                    "where X is the greatest number of creatures you control that have a creature type in common."
                ),
            ),
            source_text=(
                "this.addAbility(new EntersBattlefieldTriggeredAbility("
                "new DamageTargetEffect(new GreatestSharedCreatureTypeCount())));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_damage_target_not_supported")

    def test_creature_etb_damage_blocks_restricted_flying_target(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Rig",
                type_line="Artifact Creature - Construct",
                oracle_text=(
                    "When this creature enters, you may have it deal 4 damage "
                    "to target creature with flying."
                ),
            ),
            source_text=(
                "this.addAbility(new EntersBattlefieldTriggeredAbility("
                "new DamageTargetEffect(4), true));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_damage_target_not_supported")

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

    def test_graveyard_to_battlefield_spell_maps_to_recursion_runtime(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Sorcery",
                oracle_text="Return target creature card from your graveyard to the battlefield.",
            ),
            source_text="this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "recursion")
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_BATTLEFIELD_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["count"], 1)
        self.assertEqual(effect["destination"], "battlefield")
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
        )

    def test_graveyard_to_battlefield_opponent_graveyard_stays_blocked(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Sorcery",
                oracle_text="Put target creature card from an opponent's graveyard onto the battlefield under your control.",
            ),
            source_text="this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "recursion_battlefield_target_not_supported")

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

    def test_permanent_activated_recursion_maps_colored_tap_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Adun Oakenshield",
                type_line="Legendary Creature - Human Knight",
                oracle_text="{B}{R}{G}, {T}: Return target creature card from your graveyard to your hand.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToHandTargetEffect(),
                    new ManaCostsImpl<>("{B}{R}{G}")
                );
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                ability.addCost(new TapSourceCost());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_RECURSION_TO_HAND_SCOPE)
        self.assertEqual(effect["graveyard_to_hand_target"], "creature")
        self.assertEqual(effect["graveyard_to_hand_target_count"], 1)
        self.assertEqual(effect["activation_cost_generic"], 0)
        self.assertEqual(effect["activation_cost_colors"], ["B", "R", "G"])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertFalse(effect["activation_requires_sacrifice"])
        self.assertEqual(effect["_activated_rule_effects"][0]["effect"], "recursion")

    def test_permanent_activated_recursion_maps_up_to_three_self_sacrifice(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Font of Return",
                type_line="Enchantment",
                oracle_text="{3}{B}, Sacrifice this enchantment: Return up to three target creature cards from your graveyard to your hand.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToHandTargetEffect(),
                    new ManaCostsImpl<>("{3}{B}")
                );
                ability.addCost(new SacrificeSourceCost());
                ability.addTarget(new TargetCardInYourGraveyard(0, 3, StaticFilters.FILTER_CARD_CREATURES_YOUR_GRAVEYARD));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["graveyard_to_hand_target"], "creature")
        self.assertEqual(effect["graveyard_to_hand_target_count"], 3)
        self.assertTrue(effect["graveyard_to_hand_up_to_count"])
        self.assertEqual(effect["activation_cost_mana"], "{3}{B}")
        self.assertTrue(effect["activation_requires_sacrifice"])
        self.assertFalse(effect["activation_requires_tap"])

    def test_permanent_activated_recursion_maps_zero_mana_tap_self_sacrifice(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Rootwater Diver",
                type_line="Creature - Merfolk",
                oracle_text="{T}, Sacrifice this creature: Return target artifact card from your graveyard to your hand.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToHandTargetEffect(),
                    new TapSourceCost()
                );
                ability.addCost(new SacrificeSourceCost());
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_ARTIFACT_FROM_YOUR_GRAVEYARD));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["graveyard_to_hand_target"], "artifact")
        self.assertEqual(effect["activation_cost_mana"], "{0}")
        self.assertTrue(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])

    def test_permanent_activated_recursion_maps_basic_land_target(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Groundskeeper",
                type_line="Creature - Human Druid",
                oracle_text="{1}{G}: Return target basic land card from your graveyard to your hand.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToHandTargetEffect(),
                    new ManaCostsImpl<>("{1}{G}")
                );
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_BASIC_LAND));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["graveyard_to_hand_target"], "basic_land")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["land"], "supertypes": ["basic"]},
        )

    def test_permanent_activated_recursion_blocks_discard_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Tortured Existence",
                type_line="Enchantment",
                oracle_text="{B}, Discard a creature card: Return target creature card from your graveyard to your hand.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToHandTargetEffect(),
                    new ManaCostsImpl<>("{B}")
                );
                ability.addCost(new DiscardCardCost());
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_recursion_source_cost_not_supported")

    def test_permanent_activated_recursion_blocks_or_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Skeleton Shard",
                type_line="Artifact",
                oracle_text="{3}, {T} or {B}, {T}: Return target artifact creature card from your graveyard to your hand.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToHandTargetEffect(),
                    new OrCost(new GenericManaCost(3), new ManaCostsImpl<>("{B}"))
                );
                ability.addTarget(new TargetCardInYourGraveyard(filter));
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_recursion_source_cost_not_supported")

    def test_permanent_activated_recursion_blocks_multiple_distinct_targets(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Restoration Specialist",
                type_line="Creature - Dwarf Artificer",
                oracle_text="{W}, Sacrifice this creature: Return up to one target artifact card and up to one target enchantment card from your graveyard to your hand.",
            ),
            source_text="""
                Effect effect = new ReturnFromGraveyardToHandTargetEffect().setTargetPointer(new EachTargetPointer());
                Ability ability = new SimpleActivatedAbility(effect, new ManaCostsImpl<>("{W}"));
                ability.addTarget(new TargetCardInYourGraveyard(0, 1, StaticFilters.FILTER_CARD_ARTIFACT));
                ability.addTarget(new TargetCardInYourGraveyard(0, 1, new FilterEnchantmentCard()));
                ability.addCost(new SacrificeSourceCost());
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_recursion_oracle_not_simple")

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

    def test_fixed_boost_keyword_target_creature_maps_to_stat_modifier_with_keyword(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["BoostTargetEffect", "GainAbilityTargetEffect"],
            ability_classes=["FlyingAbility"],
            xmage_signals=["targeting"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text="Target creature you control gets +1/+1 and gains flying until end of turn."
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostTargetEffect(1, 1, Duration.EndOfTurn));"
                "this.getSpellAbility().addEffect(new GainAbilityTargetEffect("
                "FlyingAbility.getInstance(), Duration.EndOfTurn));"
                "this.getSpellAbility().addTarget(new TargetControlledCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "stat_modifier_until_eot")
        self.assertEqual(effect["battle_model_scope"], split.BOOST_KEYWORD_SCOPE)
        self.assertEqual(effect["power_delta"], 1)
        self.assertEqual(effect["toughness_delta"], 1)
        self.assertEqual(effect["granted_keywords_until_eot"], ["flying"])
        self.assertEqual(effect["target_controller"], "self")

    def test_fixed_boost_keyword_requires_target_controller_match(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["BoostTargetEffect", "GainAbilityTargetEffect"],
            ability_classes=["TrampleAbility"],
            xmage_signals=["targeting"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Target creature gets +2/+2 and gains trample until end of turn."),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostTargetEffect(2, 2, Duration.EndOfTurn));"
                "this.getSpellAbility().addEffect(new GainAbilityTargetEffect("
                "TrampleAbility.getInstance(), Duration.EndOfTurn));"
                "this.getSpellAbility().addTarget(new TargetControlledCreaturePermanent());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "boost_keyword_source_oracle_target_mismatch")

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

    def test_activated_self_boost_creature_maps_to_self_stat_modifier(self) -> None:
        row = queue_row(
            split.SELF_BOOST_ACTIVATED_UNIT,
            effect_classes=["BoostSourceEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Matron",
                type_line="Creature - Human Cleric",
                oracle_text="{W}, {T}: This creature gets +0/+3 until end of turn.",
            ),
            source_text=(
                'Ability ability = new SimpleActivatedAbility(new BoostSourceEffect(0,3,Duration.EndOfTurn), '
                'new ManaCostsImpl<>("{W}"));'
                "ability.addCost(new TapSourceCost());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.SELF_BOOST_ACTIVATED_SCOPE)
        self.assertEqual(effect["activated_effect"], "self_stat_modifier_until_eot")
        self.assertEqual(effect["power_delta"], 0)
        self.assertEqual(effect["toughness_delta"], 3)
        self.assertEqual(effect["activation_cost_mana"], "{W}")
        self.assertEqual(effect["activation_cost_colors"], ["W"])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertEqual(effect["_activated_rule_effects"][0]["target"], "self")

    def test_activated_self_boost_accepts_colored_mana_cost_source(self) -> None:
        row = queue_row(
            split.SELF_BOOST_ACTIVATED_UNIT,
            effect_classes=["BoostSourceEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Crusader",
                type_line="Creature - Human Soldier",
                oracle_text="{R}: This creature gets +1/+0 until end of turn.",
            ),
            source_text=(
                "this.addAbility(new SimpleActivatedAbility("
                "new BoostSourceEffect(1, 0, Duration.EndOfTurn), "
                "new ColoredManaCost(ColoredManaSymbol.R)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["activation_cost_mana"], "{R}")
        self.assertEqual(effect["activation_cost_colors"], ["R"])
        self.assertFalse(effect["activation_requires_tap"])

    def test_activated_self_boost_blocks_tapping_another_creature_cost(self) -> None:
        row = queue_row(
            split.SELF_BOOST_ACTIVATED_UNIT,
            effect_classes=["BoostSourceEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Behemoth",
                type_line="Creature - Elemental",
                oracle_text="Tap an untapped creature you control: This creature gets +1/+1 until end of turn.",
            ),
            source_text=(
                "this.addAbility(new SimpleActivatedAbility("
                "new BoostSourceEffect(1, 1, Duration.EndOfTurn), "
                "new TapTargetCost(StaticFilters.FILTER_CONTROLLED_UNTAPPED_CREATURE)));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_self_boost_oracle_cost_not_supported")

    def test_activated_self_boost_blocks_variable_power(self) -> None:
        row = queue_row(
            split.SELF_BOOST_ACTIVATED_UNIT,
            effect_classes=["BoostSourceEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Animist",
                type_line="Creature - Human Shaman",
                oracle_text="{3}: This creature gets +X/+0 until end of turn, where X is its power.",
            ),
            source_text=(
                "this.addAbility(new SimpleActivatedAbility("
                "new BoostSourceEffect(new SourcePermanentPowerValue(), 0, Duration.EndOfTurn), "
                "new GenericManaCost(3)));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_self_boost_oracle_not_simple")

    def test_activated_target_keyword_maps_to_keyword_until_eot(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["GainAbilityTargetEffect"],
            ability_kind="activated",
            ability_classes=["HasteAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Drillmaster",
                type_line="Creature - Goblin Shaman",
                oracle_text="{T}: Target creature gains haste until end of turn.",
            ),
            source_text=(
                "Ability ability = new SimpleActivatedAbility("
                "new GainAbilityTargetEffect(HasteAbility.getInstance(), Duration.EndOfTurn), "
                "new TapSourceCost());"
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.TARGET_KEYWORD_ACTIVATED_SCOPE)
        self.assertEqual(effect["activated_effect"], "target_keyword_until_eot")
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_controller"], "any")
        self.assertEqual(effect["granted_keywords_until_eot"], ["haste"])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertEqual(effect["_activated_rule_effects"][0]["granted_keywords_until_eot"], ["haste"])

    def test_activated_target_keyword_accepts_controlled_creature_target(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["GainAbilityTargetEffect"],
            ability_kind="activated",
            ability_classes=["FlyingAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Glidemaster",
                type_line="Creature - Human Wizard",
                oracle_text="{2}{U}: Target creature you control gains flying until end of turn.",
            ),
            source_text=(
                "Ability ability = new SimpleActivatedAbility("
                "new GainAbilityTargetEffect(FlyingAbility.getInstance(), Duration.EndOfTurn), "
                'new ManaCostsImpl<>("{2}{U}"));'
                "ability.addTarget(new TargetControlledCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(effect["activation_cost_generic"], 2)
        self.assertEqual(effect["activation_cost_colors"], ["U"])
        self.assertEqual(effect["granted_keywords_until_eot"], ["flying"])

    def test_activated_target_keyword_blocks_subtype_filter_target(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["GainAbilityTargetEffect"],
            ability_kind="activated",
            ability_classes=["FlyingAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Marshal",
                type_line="Creature - Human Soldier",
                oracle_text="{3}: Target Soldier gains flying until end of turn.",
            ),
            source_text=(
                "private static final FilterPermanent filter = new FilterPermanent(SubType.SOLDIER, \"Soldier\");"
                "Ability ability = new SimpleActivatedAbility("
                "new GainAbilityTargetEffect(FlyingAbility.getInstance()), new GenericManaCost(3));"
                "ability.addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_target_keyword_oracle_not_simple")

    def test_activated_target_keyword_blocks_source_sacrifice_cost(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["GainAbilityTargetEffect"],
            ability_kind="activated",
            ability_classes=["IndestructibleAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Savior",
                type_line="Creature - Dog",
                oracle_text="Sacrifice Fixture Savior: Another target creature you control gains indestructible until end of turn.",
            ),
            source_text=(
                "Ability ability = new SimpleActivatedAbility("
                "new GainAbilityTargetEffect(IndestructibleAbility.getInstance(), Duration.EndOfTurn), "
                "new SacrificeSourceCost());"
                "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_ANOTHER_TARGET_CREATURE_YOU_CONTROL));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_target_keyword_oracle_cost_not_supported")

    def test_static_keyword_creature_allows_multiline_keyword_oracle(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::FirstStrikeAbility,FlyingAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["FirstStrikeAbility", "FlyingAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Artifact Creature - Bird",
                oracle_text="Flying\nFirst strike",
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "this.addAbility(FirstStrikeAbility.getInstance());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertEqual(proposal["effect_json"]["keywords"], ["flying", "first_strike"])

    def test_static_self_keyword_creature_can_come_from_broad_protection_work_unit(self) -> None:
        row = queue_row(
            "grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["FlyingAbility", "HexproofAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Creature - Vedalken Wizard",
                oracle_text="Flying, hexproof",
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "this.addAbility(HexproofAbility.getInstance());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_KEYWORD_CREATURE_SCOPE)
        self.assertEqual(effect["keywords"], ["flying", "hexproof"])
        self.assertTrue(effect["hexproof"])

    def test_static_self_keyword_creature_maps_indestructible_and_shroud(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::IndestructibleAbility,ShroudAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["IndestructibleAbility", "ShroudAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Artifact Creature - Construct",
                oracle_text="Shroud\nIndestructible",
            ),
            source_text=(
                "this.addAbility(ShroudAbility.getInstance());"
                "this.addAbility(IndestructibleAbility.getInstance());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["keywords"], ["shroud", "indestructible"])
        self.assertTrue(effect["shroud"])
        self.assertTrue(effect["indestructible"])

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

    def test_creature_etb_gain_life_maps_to_triggered_creature_scope(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["GainLifeEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Cleric",
                type_line="Creature - Human Cleric",
                oracle_text="When Fixture Cleric enters, you gain 3 life.",
            ),
            source_text="this.addAbility(new EntersBattlefieldTriggeredAbility(new GainLifeEffect(3)));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_LIFE_GAIN_CREATURE_SCOPE)
        self.assertEqual(effect["etb_life_gain_amount"], 3)
        self.assertEqual(effect["trigger"], "enters_battlefield")

    def test_creature_etb_gain_life_preserves_static_keywords(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["GainLifeEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Angel",
                type_line="Creature - Angel",
                oracle_text="Flying\nWhen Fixture Angel enters the battlefield, you gain 4 life.",
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "this.addAbility(new EntersBattlefieldTriggeredAbility(new GainLifeEffect(4)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["flying"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertEqual(effect["etb_life_gain_amount"], 4)

    def test_creature_etb_gain_life_blocks_dynamic_amount(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["GainLifeEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Creature - Cleric",
                oracle_text="When this creature enters, you gain life equal to the number of creatures you control.",
            ),
            source_text="new GainLifeEffect(CreaturesYouControlCount.instance)",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_life_gain_amount_not_fixed")

    def test_creature_etb_gain_life_blocks_fixed_number_with_dynamic_multiplier(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["GainLifeEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Gate Angel",
                type_line="Creature - Angel",
                oracle_text="When Fixture Gate Angel enters the battlefield, you gain 2 life for each Gate you control.",
            ),
            source_text="new GainLifeEffect(new PermanentsOnBattlefieldCount(filter))",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_life_gain_amount_not_fixed")

    def test_creature_etb_draw_maps_to_triggered_creature_scope(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Visionary",
                type_line="Creature - Elf Shaman",
                oracle_text="When Fixture Visionary enters, draw a card.",
            ),
            source_text="this.addAbility(new EntersBattlefieldTriggeredAbility(new DrawCardSourceControllerEffect()));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_DRAW_CREATURE_SCOPE)
        self.assertEqual(effect["etb_draw_count"], 1)
        self.assertEqual(effect["trigger"], "enters_battlefield")

    def test_creature_etb_draw_preserves_static_keywords(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Drake",
                type_line="Creature - Drake",
                oracle_text="Flying\nWhen Fixture Drake enters the battlefield, draw two cards.",
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "this.addAbility(new EntersBattlefieldTriggeredAbility(new DrawCardSourceControllerEffect(2)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["flying"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertEqual(effect["etb_draw_count"], 2)

    def test_creature_etb_draw_blocks_dynamic_amount(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Judge",
                type_line="Creature - Elf",
                oracle_text="When Fixture Judge enters the battlefield, draw a card for each creature you control with a counter on it.",
            ),
            source_text="new DrawCardSourceControllerEffect(new PermanentsOnBattlefieldCount(filter))",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_draw_count_not_fixed")

    def test_creature_dies_draw_maps_to_triggered_creature_scope(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Scholar",
                type_line="Creature - Human Wizard",
                oracle_text="When this creature dies, draw two cards.",
            ),
            source_text="this.addAbility(new DiesSourceTriggeredAbility(new DrawCardSourceControllerEffect(2)));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.DIES_DRAW_CREATURE_SCOPE)
        self.assertEqual(effect["trigger"], "dies")
        self.assertEqual(effect["draw_cards_when_this_dies"], 2)

    def test_creature_dies_draw_preserves_static_keyword_and_optional_draw(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility", "FlyingAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Fisher",
                type_line="Creature - Bird",
                oracle_text="Flying\nWhen this creature dies, you may draw a card.",
            ),
            source_text="this.addAbility(FlyingAbility.getInstance()); this.addAbility(new DiesSourceTriggeredAbility(new DrawCardSourceControllerEffect()));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["flying"])
        self.assertTrue(effect["dies_draw_optional"])
        self.assertEqual(effect["draw_cards_when_this_dies"], 1)

    def test_creature_dies_draw_blocks_conditional_amount(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Zubera",
                type_line="Creature - Zubera Spirit",
                oracle_text="When this creature dies, draw a card for each Zubera that died this turn.",
            ),
            source_text="this.addAbility(new DiesSourceTriggeredAbility(new DrawCardSourceControllerEffect(new ZuberaValue())));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "dies_draw_count_not_fixed")

    def test_creature_etb_destroy_maps_to_triggered_creature_scope(self) -> None:
        row = queue_row(
            split.DESTROY_UNIT,
            effect_classes=["DestroyTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Sage",
                type_line="Creature - Elf Shaman",
                oracle_text="When this creature enters, you may destroy target artifact or enchantment.",
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(), true);"
                "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_ENCHANTMENT));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_DESTROY_CREATURE_SCOPE)
        self.assertEqual(effect["etb_remove_effect"], "remove_permanent")
        self.assertEqual(effect["etb_remove_target"], "artifact_or_enchantment")
        self.assertEqual(effect["trigger"], "enters_battlefield")

    def test_creature_etb_destroy_blocks_restricted_target_text(self) -> None:
        row = queue_row(
            split.DESTROY_UNIT,
            effect_classes=["DestroyTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Scorpion",
                type_line="Creature - Scorpion",
                oracle_text="When this creature enters, you may destroy target creature with power 1 or less.",
            ),
            source_text="new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(), true)",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_destroy_target_not_supported")

    def test_creature_etb_recursion_maps_to_triggered_creature_scope(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Elementalist",
                type_line="Creature - Human Shaman",
                oracle_text="When this creature enters, return target instant or sorcery card from your graveyard to your hand.",
            ),
            source_text="this.addAbility(new EntersBattlefieldTriggeredAbility(new ReturnFromGraveyardToHandTargetEffect()));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_RECURSION_CREATURE_SCOPE)
        self.assertEqual(effect["etb_recursion_target"], "instant_or_sorcery")
        self.assertEqual(effect["etb_recursion_count"], 1)
        self.assertEqual(effect["etb_recursion_destination"], "hand")
        self.assertEqual(effect["trigger"], "enters_battlefield")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["instant", "sorcery"]},
        )

    def test_creature_etb_recursion_preserves_up_to_two_land_target(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Treefolk",
                type_line="Creature - Treefolk Druid",
                oracle_text="When this creature enters, you may return up to two target land cards from your graveyard to your hand.",
            ),
            source_text="this.addAbility(new EntersBattlefieldTriggeredAbility(new ReturnFromGraveyardToHandTargetEffect()));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_recursion_target"], "land")
        self.assertEqual(effect["etb_recursion_count"], 2)
        self.assertTrue(effect["etb_recursion_up_to_count"])
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["land"]},
        )

    def test_creature_etb_recursion_preserves_static_keywords(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Gargoyle",
                type_line="Artifact Creature - Gargoyle",
                oracle_text=(
                    "Flying\n"
                    "When this creature enters, you may return target artifact card from your graveyard to your hand."
                ),
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "this.addAbility(new EntersBattlefieldTriggeredAbility(new ReturnFromGraveyardToHandTargetEffect(), true));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_recursion_target"], "artifact")
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["flying"])
        self.assertTrue(effect["_keywords_are_self"])

    def test_creature_etb_recursion_blocks_conditional_text(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Descender",
                type_line="Creature - Scout",
                oracle_text=(
                    "Descend 4 - When this creature enters, if there are four or more permanent cards "
                    "in your graveyard, return target permanent card from your graveyard to your hand."
                ),
            ),
            source_text="this.addAbility(new EntersBattlefieldTriggeredAbility(new ReturnFromGraveyardToHandTargetEffect()));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_recursion_target_not_supported")

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
