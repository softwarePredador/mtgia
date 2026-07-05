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
    def test_fixed_equipment_static_attachment_maps_exact_scope(self) -> None:
        row = queue_row(
            "xmage_signature::BoostEquippedEffect,GainAbilityAttachedEffect::"
            "EquipAbility,SimpleStaticAbility,VigilanceAbility::no_target_class::"
            "no_condition_class::static_ability",
            effect_classes=["BoostEquippedEffect", "GainAbilityAttachedEffect"],
            ability_kind="static",
            ability_classes=["EquipAbility", "SimpleStaticAbility", "VigilanceAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Accorder's Shield",
                type_line="Artifact - Equipment",
                oracle_text=(
                    "Equipped creature gets +0/+3 and has vigilance.\n"
                    "Equip {3} ({3}: Attach to target creature you control. Equip only as a sorcery.)"
                ),
            ),
            source_text="""
                this.subtype.add(SubType.EQUIPMENT);
                Ability ability = new SimpleStaticAbility(new BoostEquippedEffect(0, 3));
                ability.addEffect(new GainAbilityAttachedEffect(
                    VigilanceAbility.getInstance(), AttachmentType.EQUIPMENT));
                this.addAbility(ability);
                this.addAbility(new EquipAbility(3));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "equipment_static_attachment")
        self.assertEqual(effect["battle_model_scope"], split.EQUIPMENT_STATIC_ATTACHMENT_SCOPE)
        self.assertEqual(effect["power_boost"], 0)
        self.assertEqual(effect["toughness_boost"], 3)
        self.assertEqual(effect["attached_keywords"], ["vigilance"])
        self.assertTrue(effect["grants_vigilance"])

    def test_fixed_equipment_static_attachment_blocks_extra_granted_trigger(self) -> None:
        row = queue_row(
            "xmage_signature::BoostEquippedEffect,GainAbilityAttachedEffect::"
            "EquipAbility,ReachAbility,SimpleStaticAbility::no_target_class::"
            "no_condition_class::static_ability",
            effect_classes=["BoostEquippedEffect", "GainAbilityAttachedEffect"],
            ability_kind="static",
            ability_classes=["EquipAbility", "ReachAbility", "SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Web-Shooters",
                type_line="Artifact - Equipment",
                oracle_text=(
                    "Equipped creature gets +1/+1 and has reach and "
                    "\"Whenever this creature attacks, tap target creature an opponent controls.\"\n"
                    "Equip {2}"
                ),
            ),
            source_text="""
                Ability ability = new SimpleStaticAbility(new BoostEquippedEffect(1, 1));
                ability.addEffect(new GainAbilityAttachedEffect(
                    ReachAbility.getInstance(), AttachmentType.EQUIPMENT));
                ability.addEffect(new GainAbilityAttachedEffect(gainedAbility, AttachmentType.EQUIPMENT));
                this.addAbility(ability);
                this.addAbility(new EquipAbility(2));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "equipment_static_oracle_keyword_not_supported")

    def test_fixed_aura_static_power_toughness_attachment_maps_exact_scope(self) -> None:
        row = queue_row(
            "xmage_signature::AttachEffect,BoostEnchantedEffect::EnchantAbility,SimpleStaticAbility::"
            "TargetCreaturePermanent,TargetPermanent::no_condition_class::targeting,static_ability",
            effect_classes=["AttachEffect", "BoostEnchantedEffect"],
            ability_kind="static",
            ability_classes=["EnchantAbility", "SimpleStaticAbility"],
            xmage_signals=["targeting", "static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Dead Weight",
                type_line="Enchantment - Aura",
                oracle_text="Enchant creature\nEnchanted creature gets -2/-2.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new AttachEffect(Outcome.Detriment));
                Ability ability = new EnchantAbility(new TargetCreaturePermanent());
                this.addAbility(ability);
                this.addAbility(new SimpleStaticAbility(new BoostEnchantedEffect(-2, -2, Duration.WhileOnBattlefield)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "aura_static_attachment")
        self.assertEqual(effect["battle_model_scope"], split.AURA_STATIC_PT_ATTACHMENT_SCOPE)
        self.assertEqual(effect["power_boost"], -2)
        self.assertEqual(effect["toughness_boost"], -2)
        self.assertEqual(effect["enchant_target_controller"], "any")
        self.assertEqual(effect["xmage_effect_classes"], ["AttachEffect", "BoostEnchantedEffect"])

    def test_fixed_aura_static_power_toughness_blocks_dynamic_source(self) -> None:
        row = queue_row(
            "xmage_signature::AttachEffect,BoostEnchantedEffect::EnchantAbility,SimpleStaticAbility::"
            "TargetCreaturePermanent,TargetPermanent::no_condition_class::targeting,static_ability",
            effect_classes=["AttachEffect", "BoostEnchantedEffect"],
            ability_kind="static",
            ability_classes=["EnchantAbility", "SimpleStaticAbility"],
            xmage_signals=["targeting", "static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Ancestral Mask",
                type_line="Enchantment - Aura",
                oracle_text=(
                    "Enchant creature\n"
                    "Enchanted creature gets +2/+2 for each other enchantment on the battlefield."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new AttachEffect(Outcome.BoostCreature));
                this.addAbility(new EnchantAbility(new TargetCreaturePermanent()));
                DynamicValue countEnchantments = new PermanentsOnBattlefieldCount(filter);
                this.addAbility(new SimpleStaticAbility(
                    new BoostEnchantedEffect(countEnchantments, countEnchantments, Duration.WhileOnBattlefield)));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "aura_static_pt_oracle_not_exact_fixed")

    def test_static_cast_as_flash_permission_maps_artifact_filter(self) -> None:
        row = queue_row(
            split.FLASH_PERMISSION_UNIT,
            effect_classes=["CastAsThoughItHadFlashAllEffect"],
            ability_kind="static",
            ability_classes=["FlashAbility", "SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Shimmer Myr",
                type_line="Artifact Creature - Myr",
                oracle_text=(
                    "Flash\n"
                    "You may cast artifact spells as though they had flash."
                ),
            ),
            source_text="""
                private static final FilterArtifactCard filter = new FilterArtifactCard("artifact spells");
                this.addAbility(FlashAbility.getInstance());
                this.addAbility(new SimpleStaticAbility(new CastAsThoughItHadFlashAllEffect(
                    Duration.WhileOnBattlefield, filter, false)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_CAST_AS_FLASH_PERMISSION_SCOPE)
        self.assertEqual(effect["effect"], "flash_permission")
        self.assertTrue(effect["cast_spells_as_flash"])
        self.assertFalse(effect["cast_nonland_spells_as_flash"])
        self.assertEqual(effect["flash_permission_filter"], "artifact_spells")
        self.assertEqual(effect["flash_permission_controller"], "self")
        self.assertEqual(effect["keywords"], ["flash"])

    def test_static_cast_as_flash_permission_maps_any_player_sliver_filter(self) -> None:
        row = queue_row(
            split.FLASH_PERMISSION_UNIT,
            effect_classes=["CastAsThoughItHadFlashAllEffect"],
            ability_kind="static",
            ability_classes=["FlashAbility", "SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Quick Sliver",
                type_line="Creature - Sliver",
                oracle_text=(
                    "Flash\n"
                    "Any player may cast Sliver spells as though they had flash."
                ),
            ),
            source_text="""
                private static final FilterCreatureCard filter = new FilterCreatureCard("Sliver spells");
                static { filter.add(SubType.SLIVER.getPredicate()); }
                this.addAbility(FlashAbility.getInstance());
                this.addAbility(new SimpleStaticAbility(new CastAsThoughItHadFlashAllEffect(
                    Duration.WhileOnBattlefield, filter, true)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["flash_permission_filter"], "sliver_spells")
        self.assertEqual(effect["flash_permission_controller"], "any_player")
        self.assertTrue(effect["flash_permission_any_player"])

    def test_static_cast_as_flash_permission_blocks_unmodeled_leyline_auxiliary(self) -> None:
        row = queue_row(
            split.FLASH_PERMISSION_UNIT,
            effect_classes=["CastAsThoughItHadFlashAllEffect"],
            ability_kind="static",
            ability_classes=["LeylineAbility", "SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Leyline of Anticipation",
                type_line="Enchantment",
                oracle_text=(
                    "If Leyline of Anticipation is in your opening hand, you may begin the game "
                    "with it on the battlefield.\n"
                    "You may cast spells as though they had flash."
                ),
            ),
            source_text="""
                this.addAbility(new LeylineAbility());
                this.addAbility(new SimpleStaticAbility(new CastAsThoughItHadFlashAllEffect(
                    Duration.WhileOnBattlefield, new FilterNonlandCard("spells"))));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "unsupported_adapter_work_unit")

    def test_static_cant_be_blocked_creature_maps_to_runtime(self) -> None:
        row = queue_row(
            split.CANT_BE_BLOCKED_SOURCE_UNIT,
            effect_classes=[],
            ability_kind="static",
            ability_classes=["CantBeBlockedSourceAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Slither Blade",
                type_line="Creature - Snake Rogue",
                oracle_text="This creature can't be blocked.",
            ),
            source_text="""
                import mage.abilities.keyword.CantBeBlockedSourceAbility;
                this.addAbility(new CantBeBlockedSourceAbility());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_CANT_BE_BLOCKED_CREATURE_SCOPE)
        self.assertEqual(effect["effect"], "creature")
        self.assertTrue(effect["cant_be_blocked"])
        self.assertTrue(effect["unblockable"])
        self.assertEqual(effect["static_effect"], "self_cant_be_blocked")

    def test_static_cant_be_blocked_creature_blocks_filtered_evasion_text(self) -> None:
        row = queue_row(
            split.CANT_BE_BLOCKED_SOURCE_UNIT,
            effect_classes=[],
            ability_kind="static",
            ability_classes=["CantBeBlockedSourceAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Filtered Sneak",
                type_line="Creature - Rogue",
                oracle_text="Filtered Sneak can't be blocked except by Rogues.",
            ),
            source_text="""
                this.addAbility(new CantBeBlockedSourceAbility());
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_cant_be_blocked_oracle_not_exact")

    def test_static_cant_block_creature_maps_to_runtime(self) -> None:
        row = queue_row(
            split.CANT_BLOCK_SOURCE_UNIT,
            effect_classes=[],
            ability_kind="static",
            ability_classes=["CantBlockAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Goblin Raider",
                type_line="Creature - Goblin Warrior",
                oracle_text="This creature can't block.",
            ),
            source_text="""
                import mage.abilities.keyword.CantBlockAbility;
                this.addAbility(new CantBlockAbility());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_CANT_BLOCK_CREATURE_SCOPE)
        self.assertEqual(effect["effect"], "creature")
        self.assertTrue(effect["cant_block"])
        self.assertTrue(effect["cannot_block"])
        self.assertTrue(effect["static_cant_block"])
        self.assertEqual(effect["static_effect"], "self_cant_block")

    def test_static_cant_block_creature_blocks_nonexact_source(self) -> None:
        row = queue_row(
            split.CANT_BLOCK_SOURCE_UNIT,
            effect_classes=[],
            ability_kind="static",
            ability_classes=["CantBlockAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Recursive Fixture",
                type_line="Creature - Construct",
                oracle_text="This creature can't block.",
            ),
            source_text="""
                this.addAbility(new CantBlockAbility());
                this.addAbility(new SimpleActivatedAbility(new ReturnSourceFromGraveyardToBattlefieldEffect()));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_cant_block_source_not_exact")

    def test_static_horsemanship_creature_maps_to_runtime(self) -> None:
        row = queue_row(
            split.HORSEMANSHIP_SOURCE_UNIT,
            effect_classes=[],
            ability_kind="static",
            ability_classes=["HorsemanshipAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Barbarian General",
                type_line="Creature - Human Barbarian Soldier",
                oracle_text=(
                    "Horsemanship (This creature can't be blocked except by "
                    "creatures with horsemanship.)"
                ),
            ),
            source_text="""
                import mage.abilities.keyword.HorsemanshipAbility;
                this.addAbility(HorsemanshipAbility.getInstance());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_HORSEMANSHIP_CREATURE_SCOPE)
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["static_effect"], "self_horsemanship")
        self.assertEqual(effect["keywords"], ["horsemanship"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertTrue(effect["horsemanship"])
        self.assertEqual(effect["xmage_ability_class"], "HorsemanshipAbility")

    def test_static_horsemanship_creature_blocks_nonexact_source(self) -> None:
        row = queue_row(
            split.HORSEMANSHIP_SOURCE_UNIT,
            effect_classes=[],
            ability_kind="static",
            ability_classes=["HorsemanshipAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Riding Fixture",
                type_line="Creature - Human Soldier",
                oracle_text=(
                    "Horsemanship (This creature can't be blocked except by "
                    "creatures with horsemanship.)"
                ),
            ),
            source_text="""
                Effect effect = new GainAbilityTargetEffect(
                    HorsemanshipAbility.getInstance(), Duration.EndOfTurn);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_horsemanship_source_not_exact")

    def test_static_filtered_evasion_creature_maps_color_filter(self) -> None:
        row = queue_row(
            split.FILTERED_EVASION_UNIT,
            effect_classes=["CantBeBlockedByCreaturesSourceEffect"],
            ability_kind="static",
            ability_classes=["SimpleEvasionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Barrenton Cragtreads",
                type_line="Creature - Kithkin Scout",
                oracle_text="This creature can't be blocked by red creatures.",
            ),
            source_text="""
                private static final FilterCreaturePermanent filter = new FilterCreaturePermanent("red creatures");
                static { filter.add(new ColorPredicate(ObjectColor.RED)); }
                this.addAbility(new SimpleEvasionAbility(new CantBeBlockedByCreaturesSourceEffect(
                    filter, Duration.WhileOnBattlefield)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_FILTERED_EVASION_CREATURE_SCOPE)
        self.assertEqual(effect["static_effect"], "self_filtered_evasion")
        self.assertEqual(effect["cant_be_blocked_by_filters"], [{"kind": "color", "colors": ["R"]}])

    def test_static_filtered_evasion_creature_maps_power_filter(self) -> None:
        row = queue_row(
            split.FILTERED_EVASION_UNIT,
            effect_classes=["CantBeBlockedByCreaturesSourceEffect"],
            ability_kind="static",
            ability_classes=["SimpleEvasionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Amrou Kithkin",
                type_line="Creature - Kithkin",
                oracle_text="This creature can't be blocked by creatures with power 3 or greater.",
            ),
            source_text="""
                private static final FilterCreaturePermanent filter = new FilterCreaturePermanent("creatures with power 3 or greater");
                static { filter.add(new PowerPredicate(ComparisonType.MORE_THAN, 2)); }
                this.addAbility(new SimpleEvasionAbility(new CantBeBlockedByCreaturesSourceEffect(
                    filter, Duration.WhileOnBattlefield)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertEqual(
            proposal["effect_json"]["cant_be_blocked_by_filters"],
            [{"kind": "power", "operator": "gte", "value": 3}],
        )

    def test_static_filtered_evasion_creature_maps_except_by_allowed_filters(self) -> None:
        row = queue_row(
            split.FILTERED_EVASION_UNIT,
            effect_classes=["CantBeBlockedByCreaturesSourceEffect"],
            ability_kind="static",
            ability_classes=["SimpleEvasionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Amrou Seekers",
                type_line="Creature - Kithkin Rebel",
                oracle_text="This creature can't be blocked except by artifact creatures and/or white creatures.",
            ),
            source_text="""
                private static final FilterCreaturePermanent filter = new FilterCreaturePermanent(
                    "except by artifact creatures and/or white creatures");
                static {
                    filter.add(Predicates.not(Predicates.or(
                        CardType.ARTIFACT.getPredicate(),
                        new ColorPredicate(ObjectColor.WHITE))));
                }
                this.addAbility(new SimpleEvasionAbility(new CantBeBlockedByCreaturesSourceEffect(
                    filter, Duration.WhileOnBattlefield)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertEqual(
            proposal["effect_json"]["can_be_blocked_only_by_filters"],
            [{"kind": "artifact"}, {"kind": "color", "colors": ["W"]}],
        )

    def test_static_filtered_evasion_creature_blocks_source_oracle_mismatch(self) -> None:
        row = queue_row(
            split.FILTERED_EVASION_UNIT,
            effect_classes=["CantBeBlockedByCreaturesSourceEffect"],
            ability_kind="static",
            ability_classes=["SimpleEvasionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Mismatch Sneak",
                type_line="Creature - Rogue",
                oracle_text="This creature can't be blocked by red creatures.",
            ),
            source_text="""
                private static final FilterCreaturePermanent filter = new FilterCreaturePermanent("blue creatures");
                static { filter.add(new ColorPredicate(ObjectColor.BLUE)); }
                this.addAbility(new SimpleEvasionAbility(new CantBeBlockedByCreaturesSourceEffect(
                    filter, Duration.WhileOnBattlefield)));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_filtered_evasion_source_oracle_mismatch")

    def test_static_basic_landwalk_creature_maps_to_runtime(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::SwampwalkAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["SwampwalkAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Anaconda",
                type_line="Creature - Snake",
                oracle_text="Swampwalk (This creature can't be blocked as long as defending player controls a Swamp.)",
            ),
            source_text="""
                import mage.abilities.keyword.SwampwalkAbility;
                this.addAbility(new SwampwalkAbility());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_LANDWALK_CREATURE_SCOPE)
        self.assertEqual(effect["effect"], "creature")
        self.assertTrue(effect["landwalk"])
        self.assertEqual(effect["landwalk_keyword"], "swampwalk")
        self.assertEqual(effect["landwalk_land_type"], "swamp")
        self.assertEqual(effect["landwalk_land_types"], ["swamp"])

    def test_static_basic_landwalk_creature_blocks_nonbasic_landwalk_text(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::ForestwalkAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["ForestwalkAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Snow Dryad",
                type_line="Creature - Dryad",
                oracle_text="Snow forestwalk",
            ),
            source_text="""
                import mage.abilities.keyword.ForestwalkAbility;
                this.addAbility(new ForestwalkAbility());
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_landwalk_oracle_not_basic_exact")

    def test_static_play_lands_from_graveyard_maps_to_runtime(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["PlayFromGraveyardControllerEffect"],
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Crucible of Worlds",
                type_line="Artifact",
                oracle_text="You may play lands from your graveyard.",
            ),
            source_text="""
                this.addAbility(new SimpleStaticAbility(
                    PlayFromGraveyardControllerEffect.playLands()));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.GRAVEYARD_LAND_PLAY_SCOPE)
        self.assertEqual(effect["ability_kind"], "static")
        self.assertEqual(effect["static_effect"], "play_lands_from_graveyard")
        self.assertTrue(effect["play_lands_from_graveyard"])
        self.assertEqual(effect["land_play_source_zone"], "graveyard")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["land"]},
        )

    def test_static_play_lands_from_graveyard_blocks_extra_unmodeled_ability(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["PlayFromGraveyardControllerEffect"],
            ability_classes=["SimpleStaticAbility", "UnearthAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Perennial Behemoth",
                type_line="Creature - Dinosaur",
                oracle_text="You may play lands from your graveyard.\nUnearth {G}{G}",
            ),
            source_text="""
                this.addAbility(new SimpleStaticAbility(
                    PlayFromGraveyardControllerEffect.playLands()));
                this.addAbility(new UnearthAbility(new ManaCostsImpl<>("{G}{G}")));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "play_lands_from_graveyard_ability_class_not_simple_static")

    def test_static_play_lands_from_graveyard_blocks_cast_spells_variant(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["PlayFromGraveyardControllerEffect"],
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Yawgmoth's Agenda",
                type_line="Enchantment",
                oracle_text="You may play lands and cast spells from your graveyard.",
            ),
            source_text="""
                this.addAbility(new SimpleStaticAbility(
                    PlayFromGraveyardControllerEffect.playLandsAndCastSpells(Duration.WhileOnBattlefield)));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "play_lands_from_graveyard_oracle_not_exact")

    def test_dynamic_graveyard_count_damage_spells_map_to_runtime(self) -> None:
        fixtures = [
            {
                "name": "Galvanic Bombardment",
                "type_line": "Instant",
                "oracle": (
                    "Galvanic Bombardment deals X damage to target creature, where X is 2 plus "
                    "the number of cards named Galvanic Bombardment in your graveyard."
                ),
                "source": """
                    filter.add(new NamePredicate("Galvanic Bombardment"));
                    Effect effect = new DamageTargetEffect(
                        new GalvanicBombardmentCardsInControllerGraveyardCount(filter));
                    this.getSpellAbility().addTarget(new TargetCreaturePermanent());
                """,
                "target": "creature",
                "scope": "controller_graveyard",
                "card_names": ["Galvanic Bombardment"],
                "base": 2,
            },
            {
                "name": "Ire of Kaminari",
                "type_line": "Instant - Arcane",
                "oracle": (
                    "Ire of Kaminari deals damage to any target equal to the number of Arcane cards "
                    "in your graveyard."
                ),
                "source": """
                    filter.add(SubType.ARCANE.getPredicate());
                    this.getSpellAbility().addEffect(new DamageTargetEffect(
                        new CardsInControllerGraveyardCount(filter)));
                    this.getSpellAbility().addTarget(new TargetAnyTarget());
                """,
                "target": "any_target",
                "scope": "controller_graveyard",
                "subtypes": ["arcane"],
                "base": 0,
            },
            {
                "name": "Kindle",
                "type_line": "Instant",
                "oracle": (
                    "Kindle deals X damage to any target, where X is 2 plus the number of cards "
                    "named Kindle in all graveyards."
                ),
                "source": """
                    filter.add(new NamePredicate("Kindle"));
                    Effect effect = new DamageTargetEffect(new KindleCardsInAllGraveyardsCount(filter));
                    this.getSpellAbility().addTarget(new TargetAnyTarget());
                """,
                "target": "any_target",
                "scope": "all_graveyards",
                "card_names": ["Kindle"],
                "base": 2,
            },
            {
                "name": "Scrapyard Salvo",
                "type_line": "Sorcery",
                "oracle": (
                    "Scrapyard Salvo deals damage to target player or planeswalker equal to the "
                    "number of artifact cards in your graveyard."
                ),
                "source": """
                    this.getSpellAbility().addTarget(new TargetPlayerOrPlaneswalker());
                    this.getSpellAbility().addEffect(new DamageTargetEffect(
                        new CardsInControllerGraveyardCount(new FilterArtifactCard())));
                """,
                "target": "player_or_planeswalker",
                "scope": "controller_graveyard",
                "card_types": ["artifact"],
                "base": 0,
            },
        ]

        for fixture in fixtures:
            with self.subTest(card=fixture["name"]):
                row = queue_row(
                    split.RECURSION_UNIT,
                    effect_classes=["DamageTargetEffect"],
                    card_id=fixture["name"],
                    xmage_signals=["targeting"],
                )
                proposal, reason = split.split_row(
                    row,
                    metadata(
                        name=fixture["name"],
                        type_line=fixture["type_line"],
                        oracle_text=fixture["oracle"],
                    ),
                    source_text=fixture["source"],
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["battle_model_scope"], split.GRAVEYARD_COUNT_DAMAGE_SCOPE)
                self.assertEqual(effect["damage_amount_source"], "graveyard_card_count")
                self.assertEqual(effect["target"], fixture["target"])
                self.assertEqual(effect["graveyard_count_scope"], fixture["scope"])
                self.assertEqual(effect["damage_base_amount"], fixture["base"])
                if "card_names" in fixture:
                    self.assertEqual(effect["graveyard_count_card_names"], fixture["card_names"])
                if "subtypes" in fixture:
                    self.assertEqual(effect["graveyard_count_subtypes"], fixture["subtypes"])
                if "card_types" in fixture:
                    self.assertEqual(effect["graveyard_count_card_types"], fixture["card_types"])

    def test_attack_trigger_grants_flying_to_another_attacking_creature(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["GainAbilityTargetEffect"],
            ability_kind="triggered",
            ability_classes=["AttacksTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Aerial Guide",
                type_line="Creature - Drake",
                oracle_text=(
                    "Flying\n"
                    "Whenever this creature attacks, another target attacking creature "
                    "gains flying until end of turn."
                ),
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                Ability ability = new AttacksTriggeredAbility(
                    new GainAbilityTargetEffect(FlyingAbility.getInstance(), Duration.EndOfTurn),
                    false
                );
                ability.addTarget(new TargetPermanent(new FilterAttackingCreature("another target attacking creature")));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ATTACK_TRIGGER_TARGET_KEYWORD_SCOPE)
        self.assertEqual(effect["trigger"], "attack")
        self.assertEqual(effect["trigger_effect"], "target_keyword_until_eot")
        self.assertEqual(effect["granted_keywords_until_eot"], ["flying"])
        self.assertEqual(effect["target_controller"], "any")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "exclude_source": True, "combat_state": "attacking"},
        )
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["_keywords_are_self"])

    def test_attack_trigger_grants_flying_to_controlled_subtype_without_flying(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["GainAbilityTargetEffect"],
            ability_kind="triggered",
            ability_classes=["AttacksTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Trusted Pegasus",
                type_line="Creature - Pegasus",
                oracle_text=(
                    "Flying\n"
                    "Whenever this creature attacks, target attacking creature without flying "
                    "gains flying until end of turn."
                ),
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                FilterPermanent filter = new FilterAttackingCreature("attacking creature without flying");
                filter.add(Predicates.not(new AbilityPredicate(FlyingAbility.class)));
                Ability ability = new AttacksTriggeredAbility(
                    new GainAbilityTargetEffect(FlyingAbility.getInstance(), Duration.EndOfTurn),
                    false
                );
                ability.addTarget(new TargetPermanent(filter));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ATTACK_TRIGGER_TARGET_KEYWORD_SCOPE)
        self.assertEqual(effect["target_controller"], "any")
        self.assertEqual(
            effect["target_constraints"],
            {
                "card_types": ["creature"],
                "combat_state": "attacking",
                "excluded_keywords": ["flying"],
            },
        )

    def test_attack_trigger_grants_flying_to_controlled_knight(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["GainAbilityTargetEffect"],
            ability_kind="triggered",
            ability_classes=["AttacksTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Garrison Griffin",
                type_line="Creature - Griffin",
                oracle_text=(
                    "Flying\n"
                    "Whenever this creature attacks, target Knight you control gains flying until end of turn."
                ),
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                private static final FilterPermanent filter = new FilterControlledPermanent(SubType.KNIGHT);
                Ability ability = new AttacksTriggeredAbility(
                    new GainAbilityTargetEffect(FlyingAbility.getInstance(), Duration.EndOfTurn),
                    false
                );
                ability.addTarget(new TargetPermanent(filter));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "target_subtypes": ["knight"]},
        )

    def test_attack_trigger_blocks_non_matching_source_target(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["GainAbilityTargetEffect"],
            ability_kind="triggered",
            ability_classes=["AttacksTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Mismatch",
                type_line="Creature - Drake",
                oracle_text=(
                    "Flying\n"
                    "Whenever this creature attacks, target creature you control gains flying until end of turn."
                ),
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                Ability ability = new AttacksTriggeredAbility(
                    new GainAbilityTargetEffect(FlyingAbility.getInstance(), Duration.EndOfTurn),
                    false
                );
                ability.addTarget(new TargetCreaturePermanent());
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "attack_target_keyword_source_oracle_mismatch")

    def test_creature_etb_dynamic_graveyard_count_damage_maps_to_runtime(self) -> None:
        fixtures = [
            {
                "name": "Cyclops Electromancer",
                "oracle": (
                    "When Cyclops Electromancer enters the battlefield, it deals X damage to target "
                    "creature an opponent controls, where X is the number of instant and sorcery "
                    "cards in your graveyard."
                ),
                "source": """
                    this.addAbility(new EntersBattlefieldTriggeredAbility(
                        new DamageTargetEffect(new CardsInControllerGraveyardCount(
                            StaticFilters.FILTER_CARD_INSTANT_OR_SORCERY)))
                        .setText("it deals X damage to target creature an opponent controls"));
                    ability.addTarget(new TargetOpponentsCreaturePermanent());
                """,
                "target": "creature",
                "target_controller": "opponent",
                "card_types": ["instant", "sorcery"],
                "per": 1,
            },
            {
                "name": "Lotleth Giant",
                "oracle": (
                    "Undergrowth — When Lotleth Giant enters the battlefield, it deals 1 damage "
                    "to target opponent for each creature card in your graveyard."
                ),
                "source": """
                    this.addAbility(new EntersBattlefieldTriggeredAbility(
                        new DamageTargetEffect(new CardsInControllerGraveyardCount(
                            StaticFilters.FILTER_CARD_CREATURE))));
                    this.getSpellAbility().addTarget(new TargetOpponent());
                """,
                "target": "opponent",
                "card_types": ["creature"],
                "per": 1,
            },
            {
                "name": "Ossuary Rats",
                "oracle": (
                    "When Ossuary Rats enters, it deals X damage to target creature or planeswalker "
                    "an opponent controls, where X is the number of creature cards in your graveyard."
                ),
                "source": """
                    FilterCreatureOrPlaneswalkerPermanent filter =
                        new FilterCreatureOrPlaneswalkerPermanent(
                            "creature or planeswalker an opponent controls");
                    filter.add(TargetController.OPPONENT.getControllerPredicate());
                    this.addAbility(new EntersBattlefieldTriggeredAbility(
                        new DamageTargetEffect(new CardsInControllerGraveyardCount(
                            StaticFilters.FILTER_CARD_CREATURES))));
                    ability.addTarget(new TargetPermanent(filter));
                """,
                "target": "creature_or_planeswalker",
                "target_controller": "opponent",
                "card_types": ["creature"],
                "per": 1,
            },
        ]

        for fixture in fixtures:
            with self.subTest(card=fixture["name"]):
                row = queue_row(
                    split.RECURSION_UNIT,
                    effect_classes=["DamageTargetEffect"],
                    card_id=fixture["name"],
                    ability_kind="triggered",
                    ability_classes=["EntersBattlefieldTriggeredAbility"],
                    xmage_signals=["targeting", "triggered_ability"],
                )
                proposal, reason = split.split_row(
                    row,
                    metadata(
                        name=fixture["name"],
                        type_line="Creature - Zombie",
                        oracle_text=fixture["oracle"],
                    ),
                    source_text=fixture["source"],
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["effect"], "creature")
                self.assertEqual(effect["battle_model_scope"], split.ETB_GRAVEYARD_COUNT_DAMAGE_CREATURE_SCOPE)
                self.assertTrue(effect["etb_dynamic_damage"])
                self.assertEqual(effect["damage_amount_source"], "graveyard_card_count")
                self.assertEqual(effect["graveyard_count_scope"], "controller_graveyard")
                self.assertEqual(effect["graveyard_count_card_types"], fixture["card_types"])
                self.assertEqual(effect["damage_per_graveyard_count"], fixture["per"])
                self.assertEqual(effect["target"], fixture["target"])
                self.assertEqual(effect.get("target_controller"), fixture.get("target_controller"))
                if fixture.get("target_controller"):
                    self.assertEqual(effect["target_constraints"]["controller"], fixture["target_controller"])

    def test_creature_etb_dynamic_battlefield_count_damage_maps_to_runtime(self) -> None:
        fixtures = [
            {
                "name": "Basalt Ravager",
                "oracle": (
                    "When this creature enters, it deals X damage to any target, where X is the "
                    "greatest number of creatures you control that have a creature type in common."
                ),
                "source": """
                    this.addAbility(new EntersBattlefieldTriggeredAbility(new DamageTargetEffect(
                        GreatestSharedCreatureTypeCount.instance)));
                    ability.addTarget(new TargetAnyTarget());
                """,
                "target": "any_target",
                "amount_source": "greatest_shared_creature_type_count",
            },
            {
                "name": "Explosive Prodigy",
                "oracle": (
                    "Vivid — When this creature enters, it deals X damage to target creature an opponent "
                    "controls, where X is the number of colors among permanents you control."
                ),
                "source": """
                    this.addAbility(new EntersBattlefieldTriggeredAbility(
                        new DamageTargetEffect(ColorsAmongControlledPermanentsCount.ALL_PERMANENTS)));
                    ability.addTarget(new TargetOpponentsCreaturePermanent());
                """,
                "target": "creature",
                "target_controller": "opponent",
                "amount_source": "colors_among_permanents_you_control",
            },
            {
                "name": "Firefist Adept",
                "oracle": (
                    "When this creature enters, it deals X damage to target creature an opponent controls, "
                    "where X is the number of Wizards you control."
                ),
                "source": """
                    private static final FilterControlledPermanent filterCount =
                        new FilterControlledPermanent("Wizards you control");
                    static { filterCount.add(SubType.WIZARD.getPredicate()); }
                    this.addAbility(new EntersBattlefieldTriggeredAbility(
                        new DamageTargetEffect(new PermanentsOnBattlefieldCount(filterCount))));
                    ability.addTarget(new TargetOpponentsCreaturePermanent());
                """,
                "target": "creature",
                "target_controller": "opponent",
                "amount_source": "battlefield_permanent_count",
                "count_fields": {"battlefield_count_subtypes": ["wizard"]},
            },
            {
                "name": "Gruesome Scourger",
                "oracle": (
                    "When this creature enters, it deals damage to target opponent or planeswalker "
                    "equal to the number of creatures you control."
                ),
                "source": """
                    DynamicValue xValue = new PermanentsOnBattlefieldCount(
                        StaticFilters.FILTER_CONTROLLED_CREATURES, 1);
                    this.addAbility(new EntersBattlefieldTriggeredAbility(new DamageTargetEffect(xValue)));
                    ability.addTarget(new TargetOpponentOrPlaneswalker());
                """,
                "target": "opponent_or_planeswalker",
                "amount_source": "battlefield_permanent_count",
                "count_fields": {"battlefield_count_card_types": ["creature"]},
            },
            {
                "name": "Kessig Malcontents",
                "oracle": (
                    "When this creature enters, it deals damage to target player or planeswalker "
                    "equal to the number of Humans you control."
                ),
                "source": """
                    private static final FilterControlledPermanent filter =
                        new FilterControlledPermanent("Humans you control");
                    static { filter.add(SubType.HUMAN.getPredicate()); }
                    this.addAbility(new EntersBattlefieldTriggeredAbility(
                        new DamageTargetEffect(new PermanentsOnBattlefieldCount(filter), "it")));
                    ability.addTarget(new TargetPlayerOrPlaneswalker());
                """,
                "target": "player_or_planeswalker",
                "amount_source": "battlefield_permanent_count",
                "count_fields": {"battlefield_count_subtypes": ["human"]},
            },
            {
                "name": "Outrage Shaman",
                "oracle": (
                    "Chroma — When this creature enters, it deals damage to target creature equal to the "
                    "number of red mana symbols in the mana costs of permanents you control."
                ),
                "source": """
                    DynamicValue xValue = new ChromaCount(ManaType.RED);
                    this.addAbility(new EntersBattlefieldTriggeredAbility(new DamageTargetEffect(xValue)));
                    ability.addTarget(new TargetCreaturePermanent());
                """,
                "target": "creature",
                "amount_source": "controlled_permanents_mana_symbol_count",
                "count_fields": {"mana_symbol_count_color": "R"},
            },
            {
                "name": "Thundering Sparkmage",
                "oracle": (
                    "When this creature enters, it deals X damage to target creature or planeswalker, "
                    "where X is the number of creatures in your party. (Your party consists of up to one "
                    "each of Cleric, Rogue, Warrior, and Wizard.)"
                ),
                "source": """
                    this.addAbility(new EntersBattlefieldTriggeredAbility(
                        new DamageTargetEffect(PartyCount.instance)));
                    ability.addTarget(new TargetCreatureOrPlaneswalker());
                """,
                "target": "creature_or_planeswalker",
                "amount_source": "party_count",
            },
            {
                "name": "Volley Veteran",
                "oracle": (
                    "When this creature enters, it deals damage to target creature an opponent controls "
                    "equal to the number of Goblins you control."
                ),
                "source": """
                    private static final FilterControlledPermanent filter =
                        new FilterControlledPermanent("Goblins you control");
                    static { filter.add(SubType.GOBLIN.getPredicate()); }
                    this.addAbility(new EntersBattlefieldTriggeredAbility(
                        new DamageTargetEffect(new PermanentsOnBattlefieldCount(filter))));
                    ability.addTarget(new TargetOpponentsCreaturePermanent());
                """,
                "target": "creature",
                "target_controller": "opponent",
                "amount_source": "battlefield_permanent_count",
                "count_fields": {"battlefield_count_subtypes": ["goblin"]},
            },
        ]

        for fixture in fixtures:
            with self.subTest(card=fixture["name"]):
                row = queue_row(
                    split.DAMAGE_UNIT,
                    effect_classes=["DamageTargetEffect"],
                    card_id=fixture["name"],
                    ability_kind="triggered",
                    ability_classes=["EntersBattlefieldTriggeredAbility"],
                    xmage_signals=["targeting", "triggered_ability"],
                )
                proposal, reason = split.split_row(
                    row,
                    metadata(
                        name=fixture["name"],
                        type_line="Creature",
                        oracle_text=fixture["oracle"],
                    ),
                    source_text=fixture["source"],
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["effect"], "creature")
                self.assertEqual(effect["battle_model_scope"], split.ETB_DYNAMIC_COUNT_DAMAGE_CREATURE_SCOPE)
                self.assertTrue(effect["etb_dynamic_damage"])
                self.assertEqual(effect["damage_amount_source"], fixture["amount_source"])
                self.assertEqual(effect["target"], fixture["target"])
                self.assertEqual(effect.get("target_controller"), fixture.get("target_controller"))
                for key, value in fixture.get("count_fields", {}).items():
                    self.assertEqual(effect.get(key), value)

    def test_dynamic_graveyard_count_damage_blocks_unsupported_neighbors(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["DamageTargetEffect"],
            xmage_signals=["targeting"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Frantic Firebolt",
                type_line="Instant",
                oracle_text=(
                    "Frantic Firebolt deals X damage to target creature, where X is 2 plus the "
                    "number of cards in your graveyard that are instant cards, sorcery cards, "
                    "and/or have an Adventure."
                ),
            ),
            source_text="""
                filter.add(Predicates.or(
                    CardType.INSTANT.getPredicate(),
                    CardType.SORCERY.getPredicate(),
                    AdventurePredicate.instance));
                this.getSpellAbility().addEffect(new DamageTargetEffect(xValue));
                this.getSpellAbility().addTarget(new TargetCreaturePermanent());
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "graveyard_count_damage_adventure_filter_not_supported")

        proposal, reason = split.split_row(
            row,
            metadata(
                name="Harvest Pyre",
                type_line="Instant",
                oracle_text=(
                    "As an additional cost to cast this spell, exile X cards from your graveyard. "
                    "Harvest Pyre deals X damage to target creature."
                ),
            ),
            source_text="""
                this.getSpellAbility().addCost(new ExileXFromYourGraveCost(
                    StaticFilters.FILTER_CARDS_FROM_YOUR_GRAVEYARD));
                this.getSpellAbility().addEffect(new DamageTargetEffect(GetXValue.instance));
                this.getSpellAbility().addTarget(new TargetCreaturePermanent());
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "graveyard_count_damage_exile_x_graveyard_cost_not_supported")

    def test_dynamic_count_damage_spells_map_to_runtime(self) -> None:
        fixtures = [
            {
                "name": "Armed Response",
                "oracle": (
                    "Armed Response deals damage to target attacking creature equal to the number "
                    "of Equipment you control."
                ),
                "source": """
                    Effect effect = new DamageTargetEffect(new PermanentsOnBattlefieldCount(
                        StaticFilters.FILTER_CONTROLLED_PERMANENT_EQUIPMENT));
                    this.getSpellAbility().addTarget(new TargetAttackingCreature());
                """,
                "target": "creature",
                "constraints": {"card_types": ["creature"], "combat_state": "attacking"},
                "amount_source": "battlefield_permanent_count",
                "count_fields": {
                    "battlefield_count_scope": "controller_battlefield",
                    "battlefield_count_card_types": ["artifact"],
                    "battlefield_count_subtypes": ["equipment"],
                },
            },
            {
                "name": "Artillery Blast",
                "oracle": (
                    "Domain — Artillery Blast deals X damage to target tapped creature, where X is "
                    "1 plus the number of basic land types among lands you control."
                ),
                "source": """
                    this.getSpellAbility().addEffect(new DamageTargetEffect(
                        new IntPlusDynamicValue(1, DomainValue.REGULAR)));
                    filter.add(TappedPredicate.TAPPED);
                    this.getSpellAbility().addTarget(new TargetPermanent(filter));
                """,
                "target": "creature",
                "constraints": {"card_types": ["creature"], "tapped_state": "tapped"},
                "amount_source": "domain_basic_land_types",
                "base": 1,
                "count_fields": {},
            },
            {
                "name": "Dogpile",
                "oracle": "Dogpile deals damage to any target equal to the number of attacking creatures you control.",
                "source": """
                    private static final FilterAttackingCreature filter = new FilterAttackingCreature("attacking creatures you control");
                    filter.add(TargetController.YOU.getControllerPredicate());
                    this.getSpellAbility().addEffect(new DamageTargetEffect(new PermanentsOnBattlefieldCount(filter)));
                    this.getSpellAbility().addTarget(new TargetAnyTarget());
                """,
                "target": "any_target",
                "constraints": {"scope": "any_target"},
                "amount_source": "battlefield_permanent_count",
                "count_fields": {
                    "battlefield_count_scope": "controller_battlefield",
                    "battlefield_count_card_types": ["creature"],
                    "battlefield_count_combat_state": "attacking",
                },
            },
            {
                "name": "Earth Tremor",
                "oracle": (
                    "Earth Tremor deals damage to target creature or planeswalker equal to the number "
                    "of lands you control."
                ),
                "source": """
                    this.getSpellAbility().addEffect(new DamageTargetEffect(LandsYouControlCount.instance));
                    this.getSpellAbility().addTarget(new TargetCreatureOrPlaneswalker());
                """,
                "target": "creature_or_planeswalker",
                "constraints": {"card_types": ["creature", "planeswalker"]},
                "amount_source": "battlefield_permanent_count",
                "count_fields": {
                    "battlefield_count_scope": "controller_battlefield",
                    "battlefield_count_card_types": ["land"],
                },
            },
            {
                "name": "Goblin War Strike",
                "oracle": (
                    "Goblin War Strike deals damage to target player or planeswalker equal to the number "
                    "of Goblins you control."
                ),
                "source": """
                    private static final DynamicValue xValue = new PermanentsOnBattlefieldCount(
                        new FilterControlledPermanent(SubType.GOBLIN, "Goblins you control"), null);
                    this.getSpellAbility().addEffect(new DamageTargetEffect(xValue));
                    this.getSpellAbility().addTarget(new TargetPlayerOrPlaneswalker());
                """,
                "target": "player_or_planeswalker",
                "constraints": {"scope": "player_or_planeswalker"},
                "amount_source": "battlefield_permanent_count",
                "count_fields": {
                    "battlefield_count_scope": "controller_battlefield",
                    "battlefield_count_subtypes": ["goblin"],
                },
            },
            {
                "name": "Spiraling Embers",
                "oracle": "Spiraling Embers deals damage to any target equal to the number of cards in your hand.",
                "source": """
                    Effect effect = new DamageTargetEffect(CardsInControllerHandCount.ANY);
                    this.getSpellAbility().addTarget(new TargetAnyTarget());
                """,
                "target": "any_target",
                "constraints": {"scope": "any_target"},
                "amount_source": "controller_hand_count",
                "count_fields": {},
            },
            {
                "name": "Storm Seeker",
                "oracle": "Storm Seeker deals damage to target player equal to the number of cards in that player's hand.",
                "source": """
                    Effect effect = new DamageTargetEffect(CardsInTargetHandCount.instance);
                    effect.setText("{this} deals damage to target player equal to the number of cards in that player's hand.");
                    this.getSpellAbility().addEffect(effect);
                    this.getSpellAbility().addTarget(new TargetPlayer());
                """,
                "target": "player",
                "constraints": {"scope": "player"},
                "amount_source": "target_hand_count",
                "count_fields": {},
            },
            {
                "name": "Runeflare Trap",
                "oracle": (
                    "If an opponent drew three or more cards this turn, you may pay {R} rather than pay this spell's mana cost.\n"
                    "Runeflare Trap deals damage to target player equal to the number of cards in that player's hand."
                ),
                "source": """
                    this.addAbility(new AlternativeCostSourceAbility(new ManaCostsImpl<>("{R}"), RuneflareTrapCondition.instance), new CardsAmountDrawnThisTurnWatcher());
                    this.getSpellAbility().addEffect(new DamageTargetEffect(new TargetPlayerCardsInHandCount())
                            .setText("{this} deals damage to target player equal to the number of cards in that player's hand"));
                    this.getSpellAbility().addTarget(new TargetPlayer());
                """,
                "target": "player",
                "constraints": {"scope": "player"},
                "amount_source": "target_hand_count",
                "count_fields": {},
            },
            {
                "name": "Thunder Salvo",
                "oracle": (
                    "Thunder Salvo deals X damage to target creature, where X is 2 plus the number "
                    "of other spells you've cast this turn."
                ),
                "source": """
                    this.getSpellAbility().addEffect(new DamageTargetEffect(new IntPlusDynamicValue(2, ThunderSalvoValue.instance))
                            .setText("{this} deals X damage to target creature, where X is 2 plus the number of other spells you've cast this turn."));
                    this.getSpellAbility().addTarget(new TargetCreaturePermanent());
                    this.getSpellAbility().addHint(new ValueHint("Number of other spells you've cast this turn", ThunderSalvoValue.instance));
                """,
                "target": "creature",
                "constraints": {"card_types": ["creature"]},
                "amount_source": "other_spells_cast_this_turn",
                "base": 2,
                "count_fields": {},
            },
            {
                "name": "Welding Sparks",
                "oracle": (
                    "Welding Sparks deals X damage to target creature, where X is 3 plus the number "
                    "of artifacts you control."
                ),
                "source": """
                    Effect effect = new DamageTargetEffect(new IntPlusDynamicValue(
                        3, new PermanentsOnBattlefieldCount(new FilterControlledArtifactPermanent("artifacts you control"))));
                    this.getSpellAbility().addTarget(new TargetCreaturePermanent());
                """,
                "target": "creature",
                "constraints": {"card_types": ["creature"]},
                "amount_source": "battlefield_permanent_count",
                "base": 3,
                "count_fields": {
                    "battlefield_count_scope": "controller_battlefield",
                    "battlefield_count_card_types": ["artifact"],
                },
            },
        ]

        for fixture in fixtures:
            with self.subTest(card=fixture["name"]):
                row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"], xmage_signals=["targeting"])
                proposal, reason = split.split_row(
                    row,
                    metadata(
                        name=fixture["name"],
                        type_line="Instant",
                        oracle_text=fixture["oracle"],
                    ),
                    source_text=fixture["source"],
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["battle_model_scope"], split.DYNAMIC_COUNT_DAMAGE_SCOPE)
                self.assertEqual(effect["target"], fixture["target"])
                self.assertEqual(effect["target_constraints"], fixture["constraints"])
                self.assertEqual(effect["damage_amount_source"], fixture["amount_source"])
                self.assertEqual(effect["damage_base_amount"], fixture.get("base", 0))
                self.assertEqual(effect["damage_per_count"], 1)
                for key, expected in fixture["count_fields"].items():
                    self.assertEqual(effect.get(key), expected)

    def test_x_damage_spells_map_to_runtime_x_value(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Blaze",
                type_line="Sorcery",
                oracle_text="Blaze deals X damage to any target.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new DamageTargetEffect(GetXValue.instance));
                this.getSpellAbility().addTarget(new TargetAnyTarget());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.X_DAMAGE_SCOPE)
        self.assertEqual(effect["damage_amount_source"], "x_value")
        self.assertEqual(effect["amount"], 0)
        self.assertEqual(effect["target"], "any_target")
        self.assertEqual(effect["target_constraints"], {"scope": "any_target"})

    def test_x_damage_spell_with_buyback_stays_blocked_until_auxiliary_model_exists(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fanning the Flames",
                type_line="Sorcery",
                oracle_text="Buyback {3}\nFanning the Flames deals X damage to any target.",
            ),
            source_text="""
                this.addAbility(new BuybackAbility("{3}"));
                this.getSpellAbility().addEffect(new DamageTargetEffect(GetXValue.instance));
                this.getSpellAbility().addTarget(new TargetAnyTarget());
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "x_damage_buyback_not_supported")

    def test_x_damage_spell_with_alternative_timing_stays_blocked(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Ghitu Fire",
                type_line="Sorcery",
                oracle_text=(
                    "You may cast this spell as though it had flash if you pay {2} more to cast it.\n"
                    "Ghitu Fire deals X damage to any target."
                ),
            ),
            source_text="""
                Effect effect = new DamageTargetEffect(GetXValue.instance);
                Ability ability = new PayMoreToCastAsThoughtItHadFlashAbility(this, new ManaCostsImpl<>("{2}"));
                ability.addEffect(effect);
                ability.addTarget(new TargetAnyTarget());
                this.addAbility(ability);
                this.getSpellAbility().addEffect(effect);
                this.getSpellAbility().addTarget(new TargetAnyTarget());
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "x_damage_alternative_timing_not_supported")

    def test_x_damage_spell_with_unknown_auxiliary_ability_stays_blocked(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Auxiliary Fixture",
                type_line="Sorcery",
                oracle_text="Auxiliary Fixture deals X damage to any target.",
            ),
            source_text="""
                this.addAbility(new FixtureAuxiliaryAbility());
                this.getSpellAbility().addEffect(new DamageTargetEffect(GetXValue.instance));
                this.getSpellAbility().addTarget(new TargetAnyTarget());
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "x_damage_auxiliary_ability_not_supported")

    def test_dynamic_count_damage_blocks_x_cost_and_composite_counts(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"], xmage_signals=["targeting"])

        proposal, reason = split.split_row(
            row,
            metadata(
                name="Hobbit's Sting",
                type_line="Instant",
                oracle_text=(
                    "Hobbit's Sting deals X damage to target creature, where X is the number of "
                    "creatures you control plus the number of Foods you control."
                ),
            ),
            source_text="""
                private static final DynamicValue xValue = new AdditiveDynamicValue(
                    CreaturesYouControlCount.PLURAL,
                    new PermanentsOnBattlefieldCount(new FilterControlledPermanent(SubType.FOOD))
                );
                this.getSpellAbility().addEffect(new DamageTargetEffect(xValue));
                this.getSpellAbility().addTarget(new TargetCreaturePermanent());
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "dynamic_count_damage_oracle_composite_count_not_supported")

    def test_return_all_graveyard_enchantments_to_battlefield_spell_maps_to_runtime(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromYourGraveyardToBattlefieldAllEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Replenish",
                type_line="Sorcery",
                oracle_text="Return all enchantment cards from your graveyard to the battlefield.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromYourGraveyardToBattlefieldAllEffect(
                    StaticFilters.FILTER_CARD_ENCHANTMENTS));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_BATTLEFIELD_ALL_SCOPE)
        self.assertEqual(effect["target"], "enchantment")
        self.assertTrue(effect["return_all_matching"])
        self.assertEqual(effect["destination"], "battlefield")
        self.assertEqual(effect["target_graveyard_controller"], "self")
        self.assertEqual(effect["battlefield_controller"], "self")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["enchantment"]},
        )

    def test_return_all_graveyard_creatures_with_mana_value_limit_maps_to_runtime(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromYourGraveyardToBattlefieldAllEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Raise the Past",
                type_line="Sorcery",
                oracle_text="Return all creature cards with mana value 2 or less from your graveyard to the battlefield.",
            ),
            source_text="""
                private static final FilterCard filter = new FilterCreatureCard(
                    "creature cards with mana value 2 or less");
                static { filter.add(new ManaValuePredicate(ComparisonType.FEWER_THAN, 3)); }
                this.getSpellAbility().addEffect(new ReturnFromYourGraveyardToBattlefieldAllEffect(filter));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_BATTLEFIELD_ALL_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertTrue(effect["return_all_matching"])
        self.assertEqual(effect["recursion_mana_value_max"], 2)
        self.assertEqual(
            effect["target_constraints"],
            {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "mana_value_max": 2,
            },
        )

    def test_return_all_graveyard_exact_x_mana_value_is_blocked(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromYourGraveyardToBattlefieldAllEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Exact X",
                type_line="Sorcery",
                oracle_text=(
                    "Return each artifact and creature card with mana value X "
                    "from your graveyard to the battlefield."
                ),
            ),
            source_text="""
                filter.add(Predicates.or(CardType.ARTIFACT.getPredicate(), CardType.CREATURE.getPredicate()));
                enum FixturePredicate implements ObjectSourcePlayerPredicate<Card> {
                    instance;
                    public boolean apply(ObjectSourcePlayer<Card> input, Game game) {
                        return input.getObject().getManaValue() == GetXValue.instance.calculate(game, input.getSource(), null);
                    }
                }
                this.getSpellAbility().addEffect(new ReturnFromYourGraveyardToBattlefieldAllEffect(filter));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "recursion_battlefield_all_exact_x_mana_value_not_supported")

    def test_graveyard_exile_target_card_spell_with_flashback_maps_to_runtime(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ExileTargetEffect"],
            ability_classes=["FlashbackAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Coffin Purge",
                type_line="Instant",
                oracle_text=(
                    "Exile target card from a graveyard.\n"
                    "Flashback {B} (You may cast this card from your graveyard for its flashback cost. "
                    "Then exile it.)"
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ExileTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInGraveyard());
                this.addAbility(new FlashbackAbility(this, new ManaCostsImpl<>("{B}")));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "graveyard_exile")
        self.assertEqual(effect["battle_model_scope"], split.GRAVEYARD_EXILE_SPELL_SCOPE)
        self.assertEqual(effect["graveyard_exile_target"], "any_card")
        self.assertEqual(effect["graveyard_exile_target_count"], 1)
        self.assertEqual(effect["target_controller"], "any")
        self.assertFalse(effect["graveyard_exile_single_graveyard"])
        self.assertEqual(effect["flashback_cost"], "{B}")

    def test_graveyard_exile_up_to_three_single_graveyard_with_cycling_maps_to_runtime(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ExileTargetEffect"],
            ability_classes=["CyclingAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Rapid Decay",
                type_line="Instant",
                oracle_text=(
                    "Exile up to three target cards from a single graveyard.\n"
                    "Cycling {2} ({2}, Discard this card: Draw a card.)"
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ExileTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInASingleGraveyard(
                    0, 3, StaticFilters.FILTER_CARD_CARDS));
                this.addAbility(new CyclingAbility(new GenericManaCost(2)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.GRAVEYARD_EXILE_SPELL_SCOPE)
        self.assertEqual(effect["graveyard_exile_target_count"], 3)
        self.assertTrue(effect["graveyard_exile_single_graveyard"])
        self.assertTrue(effect["graveyard_exile_up_to_count"])
        self.assertEqual(effect["cycling_cost"], "{2}")

    def test_graveyard_exile_spell_blocks_unsupported_transmute_auxiliary(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ExileTargetEffect"],
            ability_classes=["TransmuteAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Shred Memory",
                type_line="Instant",
                oracle_text=(
                    "Exile up to four target cards from a single graveyard.\n"
                    "Transmute {1}{B}{B}"
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ExileTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInASingleGraveyard(
                    0, 4, StaticFilters.FILTER_CARD_CARDS));
                this.addAbility(new TransmuteAbility("{1}{B}{B}"));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "graveyard_exile_ability_class_not_supported")

    def test_recursion_battlefield_total_mana_value_limit_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Patch Up",
                type_line="Sorcery",
                oracle_text=(
                    "Return up to three target creature cards with total mana value "
                    "3 or less from your graveyard to the battlefield."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());"
                "private static final FilterCard filterStatic = new FilterCreatureCard("
                "\"creature cards with total mana value 3 or less from your graveyard\");"
                "this.getSpellAbility().addTarget(new PatchUpTarget());"
                "class PatchUpTarget extends TargetCardInYourGraveyard {"
                "PatchUpTarget() { super(0, 3, filterStatic, false); }"
                "return CardUtil.checkCanTargetTotalValueLimit(this.getTargets(), id, "
                "MageObject::getManaValue, 3, game);"
                "return CardUtil.checkPossibleTargetsTotalValueLimit(this.getTargets(), "
                "super.possibleTargets(sourceControllerId, source, game), "
                "MageObject::getManaValue, 3, game);"
                "}"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_BATTLEFIELD_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["count"], 3)
        self.assertTrue(effect["up_to_count"])
        self.assertEqual(effect["recursion_total_mana_value_max"], 3)
        self.assertEqual(effect["target_constraints"]["total_mana_value_max"], 3)

    def test_recursion_battlefield_ally_total_mana_value_limit_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="March from the Tomb",
                type_line="Sorcery",
                oracle_text=(
                    "Return any number of target Ally creature cards with total mana value "
                    "8 or less from your graveyard to the battlefield."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());"
                "private static final FilterCreatureCard filterStatic = new FilterCreatureCard("
                "\"Ally creature cards with total mana value 8 or less from your graveyard\");"
                "filterStatic.add(SubType.ALLY.getPredicate());"
                "this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(filterStatic));"
                "MarchFromTheTombTarget() { super(0, Integer.MAX_VALUE, filterStatic); }"
                "return CardUtil.checkCanTargetTotalValueLimit(this.getTargets(), id, "
                "MageObject::getManaValue, 8, game);"
                "return CardUtil.checkPossibleTargetsTotalValueLimit(this.getTargets(), "
                "super.possibleTargets(sourceControllerId, source, game), "
                "MageObject::getManaValue, 8, game);"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "ally_creature")
        self.assertEqual(effect["count"], 99)
        self.assertTrue(effect["up_to_count"])
        self.assertEqual(effect["recursion_total_mana_value_max"], 8)
        self.assertEqual(effect["target_constraints"]["subtypes"], ["ally"])

    def test_recursion_battlefield_this_turn_graveyard_filter_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Continue?",
                type_line="Instant",
                oracle_text=(
                    "Choose up to four target creature cards in your graveyard that were put "
                    "there from the battlefield this turn. Return them to the battlefield."
                ),
            ),
            source_text=(
                "private static final FilterCard filter = new FilterCreatureCard("
                "\"creature cards in your graveyard that were put there from the battlefield this turn\");"
                "filter.add(PutIntoGraveFromBattlefieldThisTurnPredicate.instance);"
                "this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 4, filter));"
                "this.getSpellAbility().addWatcher(new CardsPutIntoGraveyardWatcher());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["count"], 4)
        self.assertTrue(effect["up_to_count"])
        self.assertTrue(effect["graveyard_from_battlefield_this_turn"])
        self.assertTrue(effect["target_constraints"]["graveyard_from_battlefield_this_turn"])

    def test_recursion_battlefield_this_turn_permanents_enter_tapped_is_preserved(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Brought Back",
                type_line="Instant",
                oracle_text=(
                    "Choose up to two target permanent cards in your graveyard that were put "
                    "there from the battlefield this turn. Return them to the battlefield tapped."
                ),
            ),
            source_text=(
                "private static final FilterCard filter = new FilterPermanentCard("
                "\"permanent cards in your graveyard that were put there from the battlefield this turn\");"
                "filter.add(PutIntoGraveFromBattlefieldThisTurnPredicate.instance);"
                "this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect(true));"
                "this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 2, filter));"
                "this.getSpellAbility().addWatcher(new CardsPutIntoGraveyardWatcher());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "permanent")
        self.assertEqual(effect["count"], 2)
        self.assertTrue(effect["up_to_count"])
        self.assertTrue(effect["enters_tapped"])
        self.assertTrue(effect["graveyard_from_battlefield_this_turn"])

    def test_static_controlled_power_toughness_boost_all_creatures_is_package_safe(self) -> None:
        row = queue_row(
            split.STATIC_CONTROLLED_PT_UNIT,
            effect_classes=["BoostControlledEffect"],
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Glorious Anthem",
                type_line="Enchantment",
                oracle_text="Creatures you control get +1/+1.",
            ),
            source_text=(
                "this.addAbility(new SimpleStaticAbility(new BoostControlledEffect("
                "1, 1, Duration.WhileOnBattlefield, StaticFilters.FILTER_PERMANENT_CREATURES, false)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_CONTROLLED_PT_SCOPE)
        self.assertEqual(effect["static_power_bonus"], 1)
        self.assertEqual(effect["static_toughness_bonus"], 1)
        self.assertFalse(effect["static_exclude_source"])
        self.assertEqual(effect["target_constraints"], {"controller": "self", "card_types": ["creature"]})

    def test_static_controlled_power_toughness_boost_other_creatures_excludes_source(self) -> None:
        row = queue_row(
            split.STATIC_CONTROLLED_PT_UNIT,
            effect_classes=["BoostControlledEffect"],
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Benalish Marshal",
                type_line="Creature - Human Knight",
                oracle_text="Other creatures you control get +1/+1.",
            ),
            source_text=(
                "this.addAbility(new SimpleStaticAbility(new BoostControlledEffect("
                "1, 1, Duration.WhileOnBattlefield, true)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertTrue(effect["static_exclude_source"])
        self.assertEqual(effect["static_power_bonus"], 1)
        self.assertEqual(effect["static_toughness_bonus"], 1)

    def test_static_controlled_power_toughness_boost_artifact_creatures_is_package_safe(self) -> None:
        row = queue_row(
            split.STATIC_CONTROLLED_PT_UNIT,
            effect_classes=["BoostControlledEffect"],
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Chief of the Foundry",
                type_line="Artifact Creature - Construct",
                oracle_text="Other artifact creatures you control get +1/+1.",
            ),
            source_text=(
                "this.addAbility(new SimpleStaticAbility(new BoostControlledEffect("
                "1, 1, Duration.WhileOnBattlefield, "
                "StaticFilters.FILTER_PERMANENTS_ARTIFACT_CREATURE, true)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertTrue(effect["static_artifact_creature"])
        self.assertTrue(effect["static_exclude_source"])
        self.assertEqual(effect["target_constraints"]["card_types"], ["artifact", "creature"])

    def test_static_controlled_power_toughness_boost_subtype_plural_is_package_safe(self) -> None:
        row = queue_row(
            split.STATIC_CONTROLLED_PT_UNIT,
            effect_classes=["BoostControlledEffect"],
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Pride of the Perfect",
                type_line="Enchantment",
                oracle_text="Elves you control get +2/+0.",
            ),
            source_text=(
                "private static final FilterPermanent filter = new FilterPermanent(SubType.ELF, \"Elves\");"
                "this.addAbility(new SimpleStaticAbility(new BoostControlledEffect("
                "2, 0, Duration.WhileOnBattlefield, filter, false)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["static_required_subtypes"], ["elf"])
        self.assertEqual(effect["target_constraints"]["subtypes"], ["elf"])
        self.assertEqual(effect["static_power_bonus"], 2)
        self.assertEqual(effect["static_toughness_bonus"], 0)

    def test_static_controlled_power_toughness_boost_blocks_color_filtered_lord(self) -> None:
        row = queue_row(
            split.STATIC_CONTROLLED_PT_UNIT,
            effect_classes=["BoostControlledEffect"],
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Honor of the Pure",
                type_line="Enchantment",
                oracle_text="White creatures you control get +1/+1.",
            ),
            source_text=(
                "filter.add(new ColorPredicate(ObjectColor.WHITE));"
                "this.addAbility(new SimpleStaticAbility(new BoostControlledEffect("
                "1, 1, Duration.WhileOnBattlefield, filter, false)));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_controlled_pt_oracle_filter_not_supported")

    def test_static_graveyard_count_power_toughness_controller_creatures_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["SetBasePowerToughnessSourceEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Boneyard Wurm",
                type_line="Creature - Wurm",
                oracle_text=(
                    "Boneyard Wurm's power and toughness are each equal to "
                    "the number of creature cards in your graveyard."
                ),
            ),
            source_text=(
                "DynamicValue value = new CardsInControllerGraveyardCount("
                "StaticFilters.FILTER_CARD_CREATURES);"
                "this.addAbility(new SimpleStaticAbility(Zone.ALL, "
                "new SetBasePowerToughnessSourceEffect(value)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_GRAVEYARD_COUNT_PT_SCOPE)
        self.assertEqual(effect["static_power_toughness_source"], "graveyard_count")
        self.assertEqual(effect["graveyard_count_scope"], "controller_graveyard")
        self.assertEqual(effect["graveyard_count_card_types"], ["creature"])
        self.assertTrue(effect["dynamic_power_equals_graveyard_count"])
        self.assertTrue(effect["dynamic_toughness_equals_graveyard_count"])

    def test_static_graveyard_count_power_toughness_all_graveyards_with_keyword_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["SetBasePowerToughnessSourceEffect"],
            ability_kind="static",
            ability_classes=["HasteAbility", "SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Magnivore",
                type_line="Creature - Lhurgoyf",
                oracle_text=(
                    "Haste\n"
                    "Magnivore's power and toughness are each equal to "
                    "the number of sorcery cards in all graveyards."
                ),
            ),
            source_text=(
                "private static final FilterCard filter = new FilterCard(\"sorcery cards\");"
                "filter.add(CardType.SORCERY.getPredicate());"
                "this.addAbility(new SimpleStaticAbility(Zone.ALL, "
                "new SetBasePowerToughnessSourceEffect(new CardsInAllGraveyardsCount(filter))));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["graveyard_count_scope"], "all_graveyards")
        self.assertEqual(effect["graveyard_count_card_types"], ["sorcery"])
        self.assertEqual(effect["keywords"], ["haste"])
        self.assertTrue(effect["haste"])

    def test_static_graveyard_count_power_toughness_blocks_battlefield_plus_graveyard_formula(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["SetBasePowerToughnessSourceEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Soulless One",
                type_line="Creature - Zombie Avatar",
                oracle_text=(
                    "Soulless One's power and toughness are each equal to "
                    "the number of Zombies on the battlefield plus the number "
                    "of Zombie cards in all graveyards."
                ),
            ),
            source_text=(
                "int count = game.getBattlefield().count(zombiesBattlefield, "
                "sourceAbility.getControllerId(), sourceAbility, game);"
                "this.addAbility(new SimpleStaticAbility(Zone.ALL, "
                "new SetBasePowerToughnessSourceEffect(new SoullessOneDynamicCount())));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_graveyard_count_pt_oracle_not_exact")

    def test_static_graveyard_threshold_boost_threshold_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["BoostSourceEffect", "ConditionalContinuousEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["condition", "static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Anurid Barkripper",
                type_line="Creature - Frog Beast",
                oracle_text=(
                    "Threshold — This creature gets +2/+2 as long as "
                    "there are seven or more cards in your graveyard."
                ),
            ),
            source_text=(
                "this.addAbility(new SimpleStaticAbility(new ConditionalContinuousEffect("
                "new BoostSourceEffect(2, 2, Duration.WhileOnBattlefield), "
                "ThresholdCondition.instance, \"threshold\")));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_GRAVEYARD_THRESHOLD_BOOST_SCOPE)
        self.assertEqual(effect["static_effect"], "source_power_toughness_boost_if_graveyard_count")
        self.assertEqual(effect["graveyard_count_scope"], "controller_graveyard")
        self.assertEqual(effect["graveyard_count_card_types"], ["card"])
        self.assertEqual(effect["graveyard_count_threshold"], 7)
        self.assertEqual(effect["static_power_bonus"], 2)
        self.assertEqual(effect["static_toughness_bonus"], 2)

    def test_static_graveyard_threshold_boost_descend_permanents_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["BoostSourceEffect", "ConditionalContinuousEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["condition", "static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Basking Capybara",
                type_line="Creature - Capybara",
                oracle_text=(
                    "Descend 4 — This creature gets +3/+0 as long as "
                    "there are four or more permanent cards in your graveyard."
                ),
            ),
            source_text=(
                "this.addAbility(new SimpleStaticAbility(new ConditionalContinuousEffect("
                "new BoostSourceEffect(3, 0, Duration.WhileOnBattlefield), "
                "DescendCondition.FOUR, \"descend 4\")));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_GRAVEYARD_THRESHOLD_BOOST_SCOPE)
        self.assertEqual(effect["graveyard_count_card_types"], ["permanent"])
        self.assertEqual(effect["graveyard_count_threshold"], 4)
        self.assertEqual(effect["static_power_bonus"], 3)
        self.assertEqual(effect["static_toughness_bonus"], 0)

    def test_static_graveyard_threshold_boost_blocks_opponent_graveyard_count(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["BoostSourceEffect", "ConditionalContinuousEffect"],
            ability_kind="static",
            ability_classes=["FlyingAbility", "SimpleStaticAbility"],
            xmage_signals=["condition", "static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Jace's Phantasm",
                type_line="Creature - Illusion",
                oracle_text=(
                    "Flying\n"
                    "This creature gets +4/+4 as long as an opponent has "
                    "ten or more cards in their graveyard."
                ),
            ),
            source_text=(
                "this.addAbility(new SimpleStaticAbility(new ConditionalContinuousEffect("
                "new BoostSourceEffect(4, 4, Duration.WhileOnBattlefield), "
                "CardsInOpponentGraveyardCondition.TEN, \"opponent graveyard\")));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_graveyard_threshold_boost_oracle_not_exact")

    def test_static_graveyard_count_boost_controller_creatures_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["BoostSourceEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Liliana's Elite",
                type_line="Creature - Zombie",
                oracle_text="This creature gets +1/+1 for each creature card in your graveyard.",
            ),
            source_text=(
                "DynamicValue amount = new CardsInControllerGraveyardCount(StaticFilters.FILTER_CARD_CREATURE);"
                "this.addAbility(new SimpleStaticAbility(new BoostSourceEffect("
                "amount, amount, Duration.WhileOnBattlefield)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_GRAVEYARD_COUNT_BOOST_SCOPE)
        self.assertEqual(effect["static_effect"], "source_power_toughness_boost_equal_graveyard_count")
        self.assertEqual(effect["graveyard_count_scope"], "controller_graveyard")
        self.assertEqual(effect["graveyard_count_card_types"], ["creature"])
        self.assertEqual(effect["static_power_bonus_per_graveyard_count"], 1)
        self.assertEqual(effect["static_toughness_bonus_per_graveyard_count"], 1)

    def test_static_graveyard_count_boost_controller_artifacts_power_only_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["BoostSourceEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Salvage Slasher",
                type_line="Artifact Creature - Human Rogue",
                oracle_text="This creature gets +1/+0 for each artifact card in your graveyard.",
            ),
            source_text=(
                "BoostSourceEffect effect = new BoostSourceEffect("
                "new CardsInControllerGraveyardCount(new FilterArtifactCard()), "
                "StaticValue.get(0), Duration.WhileOnBattlefield);"
                "this.addAbility(new SimpleStaticAbility(effect));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_GRAVEYARD_COUNT_BOOST_SCOPE)
        self.assertEqual(effect["graveyard_count_scope"], "controller_graveyard")
        self.assertEqual(effect["graveyard_count_card_types"], ["artifact"])
        self.assertEqual(effect["static_power_bonus_per_graveyard_count"], 1)
        self.assertEqual(effect["static_toughness_bonus_per_graveyard_count"], 0)

    def test_static_graveyard_count_boost_artifact_or_enchantment_power_only_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["BoostSourceEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility", "TrampleAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Runaway Trash-Bot",
                type_line="Artifact Creature - Construct",
                oracle_text=(
                    "Trample\n"
                    "This creature gets +1/+0 for each artifact and/or enchantment card in your graveyard."
                ),
            ),
            source_text=(
                "private static final FilterCard filter "
                "= new FilterArtifactOrEnchantmentCard(\"artifact and/or enchantment card\");"
                "private static final DynamicValue xValue = new CardsInControllerGraveyardCount(filter);"
                "this.addAbility(new SimpleStaticAbility(new BoostSourceEffect("
                "xValue, StaticValue.get(0), Duration.WhileOnBattlefield)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_GRAVEYARD_COUNT_BOOST_SCOPE)
        self.assertEqual(effect["graveyard_count_scope"], "controller_graveyard")
        self.assertEqual(effect["graveyard_count_card_types"], ["artifact", "enchantment"])
        self.assertEqual(effect["static_power_bonus_per_graveyard_count"], 1)
        self.assertEqual(effect["static_toughness_bonus_per_graveyard_count"], 0)
        self.assertIn("trample", effect["keywords"])

    def test_static_graveyard_count_boost_noncreature_nonland_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["BoostSourceEffect"],
            ability_kind="static",
            ability_classes=["MenaceAbility", "SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Xande, Dark Mage",
                type_line="Legendary Creature - Human Wizard",
                oracle_text=(
                    "Menace\n"
                    "Xande gets +1/+1 for each noncreature, nonland card in your graveyard."
                ),
            ),
            source_text=(
                "private static final FilterCard filter = new FilterCard(\"noncreature, nonland card\");"
                "static {"
                "filter.add(Predicates.not(CardType.CREATURE.getPredicate()));"
                "filter.add(Predicates.not(CardType.LAND.getPredicate()));"
                "}"
                "private static final DynamicValue xValue = new CardsInControllerGraveyardCount(filter);"
                "this.addAbility(new SimpleStaticAbility(new BoostSourceEffect("
                "xValue, xValue, Duration.WhileOnBattlefield)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_GRAVEYARD_COUNT_BOOST_SCOPE)
        self.assertEqual(effect["graveyard_count_scope"], "controller_graveyard")
        self.assertEqual(effect["graveyard_count_card_types"], ["noncreature_nonland"])
        self.assertEqual(effect["static_power_bonus_per_graveyard_count"], 1)
        self.assertEqual(effect["static_toughness_bonus_per_graveyard_count"], 1)
        self.assertIn("menace", effect["keywords"])

    def test_static_graveyard_count_boost_opponents_graveyards_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["BoostSourceEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Wight of Precinct Six",
                type_line="Creature - Zombie",
                oracle_text=(
                    "This creature gets +1/+1 for each creature card "
                    "in your opponents' graveyards."
                ),
            ),
            source_text=(
                "private static final FilterCard filter = new FilterCreatureCard("
                "\"creature card in your opponents' graveyards\");"
                "DynamicValue boost = new CardsInOpponentGraveyardsCount(filter);"
                "this.addAbility(new SimpleStaticAbility(new BoostSourceEffect("
                "boost, boost, Duration.WhileOnBattlefield)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_GRAVEYARD_COUNT_BOOST_SCOPE)
        self.assertEqual(effect["graveyard_count_scope"], "opponents_graveyards")
        self.assertEqual(effect["graveyard_count_card_types"], ["creature"])
        self.assertEqual(effect["static_power_bonus_per_graveyard_count"], 1)
        self.assertEqual(effect["static_toughness_bonus_per_graveyard_count"], 1)

    def test_static_graveyard_count_boost_blocks_fixed_boost_source_effect(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["BoostSourceEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Bear",
                type_line="Creature - Bear",
                oracle_text="This creature gets +1/+1.",
            ),
            source_text=(
                "this.addAbility(new SimpleStaticAbility(new BoostSourceEffect("
                "1, 1, Duration.WhileOnBattlefield)));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_graveyard_count_boost_oracle_not_exact")

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

    def test_x_create_creature_tokens_spell_maps_get_x_value(self) -> None:
        row = queue_row(split.TOKEN_SPELL_UNIT, effect_classes=["CreateTokenEffect"], xmage_signals=["token"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Wastes",
                type_line="Instant",
                oracle_text="Create X 1/1 white Warrior creature tokens.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new CreateTokenEffect(new WarriorToken(), GetXValue.instance));
                class WarriorToken extends TokenImpl {
                    public WarriorToken() {
                        super("Warrior Token", "1/1 white Warrior creature token");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.WARRIOR);
                        color.setWhite(true);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                    }
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.X_TOKEN_SPELL_SCOPE)
        self.assertEqual(effect["token_count_source"], "x_value")
        self.assertEqual(effect["token_count_per_x"], 1)
        self.assertEqual(effect["token_name"], "Warrior Token")
        self.assertEqual(effect["token_power"], 1)
        self.assertEqual(effect["token_toughness"], 1)

    def test_x_create_creature_tokens_spell_blocks_land_tokens_until_runtime_supported(self) -> None:
        row = queue_row(split.TOKEN_SPELL_UNIT, effect_classes=["CreateTokenEffect"], xmage_signals=["token"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Woods",
                type_line="Sorcery",
                oracle_text="Create X 1/1 green Forest Dryad land creature tokens.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new CreateTokenEffect(new ForestDryadToken(), GetXValue.instance));
                class ForestDryadToken extends TokenImpl {
                    public ForestDryadToken() {
                        super("Forest Dryad Token", "1/1 green Forest Dryad land creature token");
                        cardType.add(CardType.CREATURE);
                        cardType.add(CardType.LAND);
                        subtype.add(SubType.FOREST);
                        subtype.add(SubType.DRYAD);
                        color.setGreen(true);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                    }
                }
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "token_land_token_runtime_not_supported")

    def test_create_creature_tokens_spell_blocks_contextual_dynamic_count(self) -> None:
        row = queue_row(split.TOKEN_SPELL_UNIT, effect_classes=["CreateTokenEffect"], xmage_signals=["token"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Ambush",
                type_line="Instant",
                oracle_text="Create a 1/1 green Elf Warrior creature token for each Elf you control.",
            ),
            source_text="this.getSpellAbility().addEffect(new CreateTokenEffect(new ElfWarriorToken(), elfCount));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "token_source_create_token_not_fixed")

    def test_permanent_activated_create_token_maps_simple_mana_tap_cost(self) -> None:
        unit = (
            split.ACTIVATED_TOKEN_PERMANENT_UNIT_PREFIX
            + "no_target_class::no_condition_class::token,activated_ability"
        )
        row = queue_row(
            unit,
            effect_classes=["CreateTokenEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["token", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Mage",
                type_line="Creature - Human Shaman",
                oracle_text="{2}{G}, {T}: Create a 1/1 green Saproling creature token.",
            ),
            source_text="""
                SimpleActivatedAbility ability = new SimpleActivatedAbility(
                    new CreateTokenEffect(new SaprolingToken()),
                    new ManaCostsImpl<>("{2}{G}")
                );
                ability.addCost(new TapSourceCost());
                this.addAbility(ability);
                class SaprolingToken extends TokenImpl {
                    public SaprolingToken() {
                        super("Saproling Token", "1/1 green Saproling creature token");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.SAPROLING);
                        color.setGreen(true);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                    }
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_TOKEN_SCOPE)
        self.assertEqual(effect["activated_effect"], "token_maker")
        self.assertEqual(effect["activation_cost_mana"], "{2}{G}")
        self.assertTrue(effect["activation_requires_tap"])
        self.assertEqual(effect["token_count"], 1)
        self.assertEqual(effect["token_name"], "Saproling Token")
        self.assertEqual(effect["_activated_rule_effects"][0]["effect"], "token_maker")

    def test_permanent_activated_create_token_blocks_discard_cost(self) -> None:
        unit = (
            split.ACTIVATED_TOKEN_PERMANENT_UNIT_PREFIX
            + "no_target_class::no_condition_class::token,activated_ability"
        )
        row = queue_row(
            unit,
            effect_classes=["CreateTokenEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["token", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Crier",
                type_line="Creature - Human",
                oracle_text="{1}{W}, {T}, Discard a card: Create two 1/1 white Citizen creature tokens.",
            ),
            source_text="""
                SimpleActivatedAbility ability = new SimpleActivatedAbility(
                    new CreateTokenEffect(new CitizenToken(), 2),
                    new ManaCostsImpl<>("{1}{W}")
                );
                ability.addCost(new TapSourceCost());
                ability.addCost(new DiscardCardCost());
                this.addAbility(ability);
                class CitizenToken extends TokenImpl {
                    public CitizenToken() {
                        super("Citizen Token", "1/1 white Citizen creature token");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.CITIZEN);
                        color.setWhite(true);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                    }
                }
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_token_source_cost_not_supported")

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

    def test_fixed_create_creature_tokens_spell_maps_static_token_keyword(self) -> None:
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

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.TOKEN_SPELL_SCOPE)
        self.assertEqual(effect["token_name"], "Wurm Token")
        self.assertEqual(effect["token_power"], 5)
        self.assertEqual(effect["token_toughness"], 5)
        self.assertEqual(effect["token_keywords"], ["trample"])

    def test_token_class_parser_follows_delegating_noarg_constructor(self) -> None:
        token_data, reason = split.parse_simple_token_class(
            """
            public final class InsectToken extends TokenImpl {
                public InsectToken() {
                    this((String) null);
                }

                public InsectToken(String setCode) {
                    super("Insect Token", "1/1 green Insect creature token");
                    cardType.add(CardType.CREATURE);
                    color.setGreen(true);
                    subtype.add(SubType.INSECT);
                    power = new MageInt(1);
                    toughness = new MageInt(1);
                }
            }
            """,
            "InsectToken",
        )

        self.assertIsNone(reason)
        self.assertEqual(token_data["token_name"], "Insect Token")
        self.assertEqual(token_data["token_power"], 1)
        self.assertEqual(token_data["token_toughness"], 1)
        self.assertEqual(token_data["token_subtype"], "Insect")
        self.assertEqual(token_data["token_colors"], ["G"])

    def test_permanent_activated_create_token_maps_named_keyword_artifact_token(self) -> None:
        unit = (
            split.ACTIVATED_TOKEN_PERMANENT_UNIT_PREFIX
            + "no_target_class::no_condition_class::token,activated_ability"
        )
        row = queue_row(
            unit,
            effect_classes=["CreateTokenEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["token", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="The Hive",
                type_line="Artifact",
                oracle_text=(
                    "{5}, {T}: Create a 1/1 colorless Insect artifact creature "
                    "token with flying named Wasp."
                ),
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new CreateTokenEffect(new WaspToken(), 1),
                    new GenericManaCost(5)
                );
                ability.addCost(new TapSourceCost());
                this.addAbility(ability);
                class WaspToken extends TokenImpl {
                    public WaspToken() {
                        super("Wasp", "1/1 colorless Insect artifact creature token with flying named Wasp");
                        cardType.add(CardType.ARTIFACT);
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.INSECT);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                        addAbility(FlyingAbility.getInstance());
                    }
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_TOKEN_SCOPE)
        self.assertEqual(effect["token_name"], "Wasp")
        self.assertEqual(effect["token_subtype"], "Insect")
        self.assertEqual(effect["token_keywords"], ["flying"])
        self.assertTrue(effect["token_flying"])
        self.assertTrue(effect["artifact_tokens"])

    def test_fixed_create_creature_tokens_spell_maps_basic_landwalk_token_keyword(self) -> None:
        row = queue_row(split.TOKEN_SPELL_UNIT, effect_classes=["CreateTokenEffect"], xmage_signals=["token"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Goblin Scouts",
                type_line="Sorcery",
                oracle_text="Create three 1/1 red Goblin Scout creature tokens with mountainwalk.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new CreateTokenEffect(new GoblinScoutsToken(), 3));
                class GoblinScoutsToken extends TokenImpl {
                    public GoblinScoutsToken() {
                        super("Goblin Scout Token", "1/1 red Goblin Scout creature tokens with mountainwalk");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.GOBLIN);
                        subtype.add(SubType.SCOUT);
                        color.setRed(true);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                        this.addAbility(new MountainwalkAbility());
                    }
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.TOKEN_SPELL_SCOPE)
        self.assertEqual(effect["token_count"], 3)
        self.assertEqual(effect["token_keywords"], ["mountainwalk"])
        self.assertTrue(effect["token_landwalk"])
        self.assertEqual(effect["token_landwalk_land_type"], "mountain")
        self.assertEqual(effect["token_landwalk_land_types"], ["mountain"])

    def test_fixed_create_creature_tokens_spell_still_blocks_unsupported_token_keyword(self) -> None:
        row = queue_row(split.TOKEN_SPELL_UNIT, effect_classes=["CreateTokenEffect"], xmage_signals=["token"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Carrion Call",
                type_line="Instant",
                oracle_text="Create two 1/1 green Phyrexian Insect creature tokens with infect.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new CreateTokenEffect(new InsectInfectToken(), 2));
                class InsectInfectToken extends TokenImpl {
                    public InsectInfectToken() {
                        super("Insect Token", "1/1 green Phyrexian Insect creature token with infect");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.PHYREXIAN);
                        subtype.add(SubType.INSECT);
                        color.setGreen(true);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                        addAbility(new InfectAbility());
                    }
                }
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "token_description_keyword_not_supported")

    def test_destroy_with_controller_creature_token_compensation_maps_beast_within(self) -> None:
        row = queue_row(
            split.DESTROY_UNIT,
            effect_classes=["DestroyTargetEffect", "CreateTokenControllerTargetEffect"],
            xmage_signals=["token"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Beast Within",
                type_line="Instant",
                oracle_text="Destroy target permanent. Its controller creates a 3/3 green Beast creature token.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new DestroyTargetEffect());
                this.getSpellAbility().addEffect(new CreateTokenControllerTargetEffect(new BeastToken()));
                this.getSpellAbility().addTarget(new TargetPermanent());
                class BeastToken extends TokenImpl {
                    public BeastToken() {
                        super("Beast Token", "3/3 green Beast creature token");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.BEAST);
                        color.setGreen(true);
                        power = new MageInt(3);
                        toughness = new MageInt(3);
                    }
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DESTROY_COMPENSATION_TOKEN_SCOPE)
        self.assertEqual(effect["effect"], "remove_permanent")
        self.assertEqual(effect["target"], "permanent")
        self.assertEqual(effect["target_controller_creature_tokens"], 1)
        self.assertEqual(effect["target_controller_token_name"], "Beast Token")
        self.assertEqual(effect["target_controller_token_subtype"], "Beast")
        self.assertEqual(effect["target_controller_token_power"], 3)
        self.assertEqual(effect["target_controller_token_toughness"], 3)
        self.assertEqual(effect["target_controller_token_colors"], ["G"])

    def test_exile_with_controller_creature_token_compensation_preserves_flying_token(self) -> None:
        row = queue_row(
            split.EXILE_UNIT,
            effect_classes=["ExileTargetEffect", "CreateTokenControllerTargetEffect"],
            xmage_signals=["token"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Angelic Ascension",
                type_line="Instant",
                oracle_text=(
                    "Exile target creature or planeswalker. Its controller creates "
                    "a 4/4 white Angel creature token with flying."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ExileTargetEffect());
                this.getSpellAbility().addEffect(new CreateTokenControllerTargetEffect(new AngelToken()));
                this.getSpellAbility().addTarget(new TargetCreatureOrPlaneswalker());
                class AngelToken extends TokenImpl {
                    public AngelToken() {
                        super("Angel Token", "4/4 white Angel creature token with flying");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.ANGEL);
                        color.setWhite(true);
                        power = new MageInt(4);
                        toughness = new MageInt(4);
                        addAbility(FlyingAbility.getInstance());
                    }
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.EXILE_COMPENSATION_TOKEN_SCOPE)
        self.assertEqual(effect["effect"], "remove_permanent")
        self.assertEqual(effect["target"], "creature_or_planeswalker")
        self.assertEqual(effect["destination"], "exile")
        self.assertEqual(effect["target_controller_token_name"], "Angel Token")
        self.assertEqual(effect["target_controller_token_colors"], ["W"])
        self.assertEqual(effect["target_controller_token_keywords"], ["flying"])
        self.assertTrue(effect["target_controller_token_flying"])

    def test_token_class_parser_accepts_concatenated_java_string_description(self) -> None:
        token_data, reason = split.parse_simple_token_class(
            """
            public final class FixtureClericToken extends TokenImpl {
                public FixtureClericToken() {
                    super("Cleric Token", "1/1 white " +
                        "Cleric creature token");
                    cardType.add(CardType.CREATURE);
                    subtype.add(SubType.CLERIC);
                    color.setWhite(true);
                    power = new MageInt(1);
                    toughness = new MageInt(1);
                }
            }
            """,
            "FixtureClericToken",
        )

        self.assertIsNone(reason)
        self.assertEqual(token_data["token_name"], "Cleric Token")
        self.assertEqual(token_data["token_description"], "1/1 white Cleric creature token")
        self.assertEqual(token_data["token_power"], 1)
        self.assertEqual(token_data["token_toughness"], 1)
        self.assertEqual(token_data["token_subtype"], "Cleric")
        self.assertEqual(token_data["token_colors"], ["W"])

    def test_token_class_parser_maps_colorless_sacrifice_mana_token(self) -> None:
        token_data, reason = split.parse_simple_token_class(
            r"""
            public final class FixtureScionToken extends TokenImpl {
                public FixtureScionToken() {
                    super("Eldrazi Scion Token", "1/1 colorless Eldrazi Scion creature token with \"Sacrifice this creature: Add {C}.\"");
                    cardType.add(CardType.CREATURE);
                    subtype.add(SubType.ELDRAZI);
                    subtype.add(SubType.SCION);
                    power = new MageInt(1);
                    toughness = new MageInt(1);
                    addAbility(new SimpleManaAbility(Zone.BATTLEFIELD, Mana.ColorlessMana(1), new SacrificeSourceCost()));
                }
            }
            """,
            "FixtureScionToken",
        )

        self.assertIsNone(reason)
        self.assertEqual(token_data["token_name"], "Eldrazi Scion Token")
        self.assertEqual(token_data["token_subtype"], "Eldrazi Scion")
        self.assertEqual(token_data["token_power"], 1)
        self.assertEqual(token_data["token_toughness"], 1)
        self.assertTrue(token_data["token_sacrifice_for_colorless_mana"])
        self.assertTrue(token_data["token_mana_activation_requires_sacrifice"])
        self.assertFalse(token_data["token_mana_activation_requires_tap"])
        self.assertEqual(token_data["token_mana_produced"], 1)
        self.assertEqual(token_data["token_produces"], "C")
        self.assertEqual(token_data["token_produced_mana_symbols"], ["C"])

    def test_fixed_create_creature_tokens_spell_maps_colorless_sacrifice_mana_token(self) -> None:
        row = queue_row(split.TOKEN_SPELL_UNIT, effect_classes=["CreateTokenEffect"], xmage_signals=["token"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Invasion",
                type_line="Sorcery",
                oracle_text=(
                    "Create three 1/1 colorless Eldrazi Scion creature tokens. "
                    "They have \"Sacrifice this creature: Add {C}.\""
                ),
            ),
            source_text=r"""
                this.getSpellAbility().addEffect(new CreateTokenEffect(new FixtureScionToken(), 3));
                public final class FixtureScionToken extends TokenImpl {
                    public FixtureScionToken() {
                        super("Eldrazi Scion Token", "1/1 colorless Eldrazi Scion creature token with \"Sacrifice this creature: Add {C}.\"");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.ELDRAZI);
                        subtype.add(SubType.SCION);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                        addAbility(new SimpleManaAbility(Zone.BATTLEFIELD, Mana.ColorlessMana(1), new SacrificeSourceCost()));
                    }
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.TOKEN_SPELL_SCOPE)
        self.assertEqual(effect["token_count"], 3)
        self.assertTrue(effect["token_sacrifice_for_colorless_mana"])
        self.assertEqual(effect["token_produced_mana_symbols"], ["C"])

    def test_dies_create_tokens_matches_plural_keyword_token_description(self) -> None:
        row = queue_row(
            split.DIES_TOKEN_CREATURE_UNIT,
            effect_classes=["CreateTokenEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["token", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Guard",
                type_line="Creature - Human Scout",
                oracle_text=(
                    "When Fixture Guard dies, create two 1/1 white "
                    "Spirit creature tokens with flying."
                ),
            ),
            source_text="""
                this.addAbility(new DiesSourceTriggeredAbility(
                    new CreateTokenEffect(new SpiritWhiteToken(), 2)));
                class SpiritWhiteToken extends TokenImpl {
                    public SpiritWhiteToken() {
                        super("Spirit Token", "1/1 white Spirit creature token with flying");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.SPIRIT);
                        color.setWhite(true);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                        addAbility(FlyingAbility.getInstance());
                    }
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DIES_TOKEN_CREATURE_SCOPE)
        self.assertEqual(effect["dies_token_count"], 2)
        self.assertEqual(effect["dies_token_name"], "Spirit Token")
        self.assertEqual(effect["dies_token_keywords"], ["flying"])

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

    def test_creature_etb_create_tokens_maps_static_token_keyword(self) -> None:
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
                name="Jungleborn Pioneer",
                type_line="Creature - Merfolk Scout",
                oracle_text="When Jungleborn Pioneer enters the battlefield, create a 1/1 blue Merfolk creature token with hexproof.",
            ),
            source_text="""
                this.addAbility(new EntersBattlefieldTriggeredAbility(
                    new CreateTokenEffect(new MerfolkHexproofToken())));
                class MerfolkHexproofToken extends TokenImpl {
                    public MerfolkHexproofToken() {
                        super("Merfolk Token", "1/1 blue Merfolk creature token with hexproof");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.MERFOLK);
                        color.setBlue(true);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                        addAbility(new HexproofAbility());
                    }
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ETB_TOKEN_CREATURE_SCOPE)
        self.assertEqual(effect["etb_token_name"], "Merfolk Token")
        self.assertEqual(effect["etb_token_keywords"], ["hexproof"])

    def test_creature_dies_create_tokens_is_package_safe(self) -> None:
        row = queue_row(
            split.DIES_TOKEN_CREATURE_UNIT,
            effect_classes=["CreateTokenEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["token", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Beskir Shieldmate",
                type_line="Creature - Human Warrior",
                oracle_text="When Beskir Shieldmate dies, create a 1/1 white Human Warrior creature token.",
            ),
            source_text="""
                this.addAbility(new DiesSourceTriggeredAbility(
                    new CreateTokenEffect(new HumanWarriorToken())));
                class HumanWarriorToken extends TokenImpl {
                    public HumanWarriorToken() {
                        super("Human Warrior Token", "1/1 white Human Warrior creature token");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.HUMAN);
                        subtype.add(SubType.WARRIOR);
                        color.setWhite(true);
                        power = new MageInt(1);
                        toughness = new MageInt(1);
                    }
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.DIES_TOKEN_CREATURE_SCOPE)
        self.assertEqual(effect["trigger"], "dies")
        self.assertEqual(effect["dies_trigger_effect"], "token_maker")
        self.assertEqual(effect["dies_token_count"], 1)
        self.assertEqual(effect["dies_token_name"], "Human Warrior Token")
        self.assertEqual(effect["dies_token_subtype"], "Human Warrior")
        self.assertEqual(effect["dies_token_power"], 1)
        self.assertEqual(effect["dies_token_toughness"], 1)
        self.assertEqual(effect["dies_token_colors"], ["W"])

    def test_creature_dies_create_tokens_blocks_non_creature_token(self) -> None:
        row = queue_row(
            split.DIES_TOKEN_CREATURE_UNIT,
            effect_classes=["CreateTokenEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["token", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Hoarder",
                type_line="Creature - Human Pirate",
                oracle_text="When Fixture Hoarder dies, create a Treasure token.",
            ),
            source_text="""
                this.addAbility(new DiesSourceTriggeredAbility(
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

    def test_creature_dies_create_tokens_blocks_conditional_oracle(self) -> None:
        row = queue_row(
            split.DIES_TOKEN_CREATURE_UNIT,
            effect_classes=["CreateTokenEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["token", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Deathknell Berserker",
                type_line="Creature - Elf Berserker",
                oracle_text=(
                    "When Deathknell Berserker dies, if its power was 3 or greater, "
                    "create a 2/2 black Zombie Berserker creature token."
                ),
            ),
            source_text="""
                this.addAbility(new DiesSourceTriggeredAbility(
                    new CreateTokenEffect(new ZombieBerserkerToken())));
                class ZombieBerserkerToken extends TokenImpl {
                    public ZombieBerserkerToken() {
                        super("Zombie Berserker Token", "2/2 black Zombie Berserker creature token");
                        cardType.add(CardType.CREATURE);
                        subtype.add(SubType.ZOMBIE);
                        subtype.add(SubType.BERSERKER);
                        color.setBlack(true);
                        power = new MageInt(2);
                        toughness = new MageInt(2);
                    }
                }
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "dies_token_oracle_not_simple")

    def test_creature_dies_create_tokens_blocks_dynamic_count(self) -> None:
        row = queue_row(
            split.DIES_TOKEN_CREATURE_UNIT,
            effect_classes=["CreateTokenEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["token", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Dripping-Tongue Zubera",
                type_line="Creature - Zubera Spirit",
                oracle_text=(
                    "When Dripping-Tongue Zubera dies, create a 1/1 colorless Spirit "
                    "creature token for each Zubera that died this turn."
                ),
            ),
            source_text=(
                "this.addAbility(new DiesSourceTriggeredAbility("
                "new CreateTokenEffect(new SpiritToken(), ZuberasDiedDynamicValue.instance)));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "token_source_create_token_not_fixed")

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

    def test_fixed_draw_put_land_from_hand_spell_maps_growth_spiral(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=[
                "DrawCardSourceControllerEffect",
                "PutCardFromHandOntoBattlefieldEffect",
            ],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Draw a card. You may put a land card from your hand onto the battlefield."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1));"
                "this.getSpellAbility().addEffect(new PutCardFromHandOntoBattlefieldEffect("
                "StaticFilters.FILTER_CARD_LAND_A));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertIsNotNone(proposal)
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "composite_resolution")
        self.assertEqual(effect["battle_model_scope"], split.DRAW_PUT_LAND_SCOPE)
        self.assertEqual(effect["draw_count"], 1)
        self.assertFalse(effect["put_land_tapped"])
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["draw_cards", "put_land_from_hand_onto_battlefield"],
        )

    def test_fixed_draw_put_land_from_hand_spell_preserves_tapped_entry(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=[
                "DrawCardSourceControllerEffect",
                "PutCardFromHandOntoBattlefieldEffect",
            ],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Draw three cards. You may put a land card from your hand onto the battlefield tapped."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(3));"
                "this.getSpellAbility().addEffect(new PutCardFromHandOntoBattlefieldEffect("
                "StaticFilters.FILTER_CARD_LAND_A, false, true));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertIsNotNone(proposal)
        effect = proposal["effect_json"]
        self.assertEqual(effect["draw_count"], 3)
        self.assertTrue(effect["put_land_tapped"])

    def test_fixed_draw_put_land_from_hand_spell_blocks_dynamic_permanent_x(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=[
                "DrawCardSourceControllerEffect",
                "PutCardFromHandOntoBattlefieldEffect",
            ],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Draw X cards. Then you may put a permanent card with mana value X or less "
                    "from your hand onto the battlefield tapped."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(GetXValue.instance));"
                "this.getSpellAbility().addEffect(new PutCardFromHandOntoBattlefieldEffect(filter, false, true));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertIn(reason, {"draw_put_land_oracle_not_simple", "draw_put_land_oracle_not_exact_fixed"})

    def test_fixed_draw_spell_with_self_cost_reduction_maps(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DrawCardSourceControllerEffect", "SpellCostReductionSourceEffect"],
            ability_classes=["SimpleStaticAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Into the Story",
                type_line="Instant",
                oracle_text=(
                    "This spell costs {3} less to cast if an opponent has seven or more "
                    "cards in their graveyard.\nDraw four cards."
                ),
            ),
            source_text=(
                "this.addAbility(new SimpleStaticAbility("
                "Zone.ALL, new SpellCostReductionSourceEffect(3, CardsInOpponentGraveyardCondition.SEVEN)"
                ").setRuleAtTheTop(true));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(4));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DRAW_SELF_COST_REDUCTION_SCOPE)
        self.assertEqual(effect["effect"], "draw_cards")
        self.assertEqual(effect["draw_count"], 4)
        self.assertEqual(effect["cost_reduction_applies_to"], "this_spell")
        self.assertEqual(effect["cost_reduction_generic"], 3)
        self.assertEqual(effect["cost_reduction_condition"], "opponent_graveyard_cards_at_least")
        self.assertEqual(effect["cost_reduction_opponent_graveyard_cards_min"], 7)

    def test_fixed_draw_spell_with_colored_or_x_cost_reduction_stays_blocked(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DrawCardSourceControllerEffect", "SpellCostReductionSourceEffect"],
            ability_classes=["SimpleStaticAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Even the Score",
                type_line="Instant",
                oracle_text=(
                    "This spell costs {U}{U}{U} less to cast if an opponent has drawn four "
                    "or more cards this turn.\nDraw X cards."
                ),
            ),
            source_text=(
                "new SpellCostReductionSourceEffect(new ManaCostsImpl<>(\"{U}{U}{U}\"), condition);"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(GetXValue.instance));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "draw_self_cost_reduction_oracle_not_exact_fixed")

    def test_fixed_draw_discard_spell_maps_draw_discard_controller_effect(self) -> None:
        row = queue_row(split.DRAW_UNIT, effect_classes=["DrawDiscardControllerEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Draw three cards, then discard a card."),
            source_text="this.getSpellAbility().addEffect(new DrawDiscardControllerEffect(3, 1));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DRAW_DISCARD_SPELL_SCOPE)
        self.assertTrue(effect["draw_discard_spell"])
        self.assertEqual(effect["draw_count"], 3)
        self.assertEqual(effect["discard_count"], 1)
        self.assertEqual(effect["draw_discard_order"], "draw_then_discard")
        self.assertFalse(effect["discard_random"])

    def test_fixed_controller_draw_lose_life_spell_maps(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DrawCardSourceControllerEffect", "LoseLifeSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="You draw three cards and you lose 3 life."),
            source_text=(
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(3, true));"
                "this.getSpellAbility().addEffect(new LoseLifeSourceControllerEffect(3).concatBy(\"and\"));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DRAW_LOSE_LIFE_SPELL_SCOPE)
        self.assertTrue(effect["draw_lose_life_spell"])
        self.assertEqual(effect["draw_count"], 3)
        self.assertEqual(effect["life_loss"], 3)
        self.assertEqual(effect["target_controller"], "self")

    def test_fixed_target_player_draw_lose_life_spell_maps(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DrawCardTargetEffect", "LoseLifeTargetEffect"],
            xmage_signals=["targeting", "draw"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Target player draws two cards and loses 2 life."),
            source_text=(
                "this.getSpellAbility().addTarget(new TargetPlayer());"
                "this.getSpellAbility().addEffect(new DrawCardTargetEffect(2));"
                "this.getSpellAbility().addEffect(new LoseLifeTargetEffect(2).withTargetDescription(\"and\"));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.TARGET_DRAW_LOSE_LIFE_SPELL_SCOPE)
        self.assertEqual(effect["target_controller"], "target_player")
        self.assertEqual(effect["target"], "player")
        self.assertEqual(effect["target_preference"], "self")
        self.assertEqual(effect["draw_count"], 2)
        self.assertEqual(effect["life_loss"], 2)

    def test_fixed_target_player_draw_spell_maps(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DrawCardTargetEffect"],
            xmage_signals=["targeting", "draw"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Target player draws four cards."),
            source_text=(
                "this.getSpellAbility().addTarget(new TargetPlayer());"
                "this.getSpellAbility().addEffect(new DrawCardTargetEffect(4));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.TARGET_DRAW_SCOPE)
        self.assertTrue(effect["target_player_draw"])
        self.assertEqual(effect["target_controller"], "target_player")
        self.assertEqual(effect["target"], "player")
        self.assertEqual(effect["target_preference"], "self")
        self.assertEqual(effect["draw_count"], 4)
        self.assertEqual(effect["count"], 4)

    def test_fixed_target_player_draw_spell_blocks_dynamic_source_count(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DrawCardTargetEffect"],
            xmage_signals=["targeting", "draw"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Target player draws X cards."),
            source_text=(
                "this.getSpellAbility().addTarget(new TargetPlayer());"
                "this.getSpellAbility().addEffect(new DrawCardTargetEffect(GetXValue.instance));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "target_player_draw_spell_oracle_not_exact_fixed")

    def test_fixed_draw_lose_life_spell_blocks_dynamic_source_count(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DrawCardSourceControllerEffect", "LoseLifeSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="You draw three cards and you lose 3 life."),
            source_text=(
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(BlackDevotionCount.instance));"
                "this.getSpellAbility().addEffect(new LoseLifeSourceControllerEffect(BlackDevotionCount.instance));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "draw_lose_life_spell_source_count_not_fixed")

    def test_fixed_draw_discard_spell_maps_random_discard_pair(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DiscardControllerEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Draw four cards, then discard three cards."),
            source_text=(
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(4));"
                "this.getSpellAbility().addEffect(new DiscardControllerEffect(3, true));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DRAW_DISCARD_SPELL_SCOPE)
        self.assertEqual(effect["draw_count"], 4)
        self.assertEqual(effect["discard_count"], 3)
        self.assertEqual(effect["draw_discard_order"], "draw_then_discard")
        self.assertTrue(effect["discard_random"])

    def test_fixed_draw_discard_spell_maps_discard_then_draw_pair(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DiscardControllerEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Discard a card, then draw two cards."),
            source_text=(
                "this.getSpellAbility().addEffect(new DiscardControllerEffect(1));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(2));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DRAW_DISCARD_SPELL_SCOPE)
        self.assertEqual(effect["draw_count"], 2)
        self.assertEqual(effect["discard_count"], 1)
        self.assertEqual(effect["draw_discard_order"], "discard_then_draw")

    def test_fixed_draw_discard_spell_blocks_dynamic_source_count(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DiscardControllerEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Draw four cards, then discard two cards."),
            source_text=(
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(GetXValue.instance));"
                "this.getSpellAbility().addEffect(new DiscardControllerEffect(2));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "draw_discard_spell_source_count_not_fixed")

    def test_fixed_source_controller_draw_spell_accepts_creature_sacrifice_cost(self) -> None:
        row = queue_row(split.DRAW_UNIT, effect_classes=["DrawCardSourceControllerEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Altar's Reap",
                oracle_text="As an additional cost to cast this spell, sacrifice a creature.\nDraw two cards.",
            ),
            source_text=(
                "this.getSpellAbility().addCost(new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(2));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DRAW_SCOPE)
        self.assertEqual(effect["count"], 2)
        self.assertEqual(effect["additional_cost"], "sacrifice_creature")
        self.assertTrue(effect["requires_sacrifice_creature"])
        self.assertEqual(effect["xmage_additional_cost_class"], "SacrificeTargetCost")
        self.assertEqual(effect["xmage_additional_cost_target"], "creature")

    def test_fixed_source_controller_draw_spell_accepts_discard_card_cost(self) -> None:
        row = queue_row(split.DRAW_UNIT, effect_classes=["DrawCardSourceControllerEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Tormenting Voice",
                oracle_text="As an additional cost to cast this spell, discard a card.\nDraw two cards.",
            ),
            source_text=(
                "this.getSpellAbility().addCost(new DiscardCardCost());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(2));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["additional_cost"], "discard_card")
        self.assertTrue(effect["requires_discard_card"])
        self.assertEqual(effect["xmage_additional_cost_class"], "DiscardCardCost")
        self.assertEqual(effect["xmage_additional_cost_target"], "card")

    def test_fixed_source_controller_draw_spell_accepts_discard_land_cost(self) -> None:
        row = queue_row(split.DRAW_UNIT, effect_classes=["DrawCardSourceControllerEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Magmatic Insight",
                oracle_text="As an additional cost to cast this spell, discard a land card.\nDraw two cards.",
            ),
            source_text=(
                "this.getSpellAbility().addCost(new DiscardTargetCost(new TargetCardInHand(new FilterLandCard())));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(2));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["additional_cost"], "discard_land")
        self.assertTrue(effect["requires_discard_land"])
        self.assertEqual(effect["xmage_additional_cost_class"], "DiscardTargetCost")
        self.assertEqual(effect["xmage_additional_cost_target"], "land")

    def test_fixed_source_controller_draw_spell_accepts_artifact_or_creature_sacrifice_cost(self) -> None:
        row = queue_row(split.DRAW_UNIT, effect_classes=["DrawCardSourceControllerEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Costly Plunder",
                oracle_text=(
                    "As an additional cost to cast this spell, sacrifice an artifact or creature.\n"
                    "Draw two cards."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addCost(new SacrificeTargetCost("
                "StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_CREATURE));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(2));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["additional_cost"], "sacrifice_artifact_or_creature")
        self.assertTrue(effect["requires_sacrifice_artifact_or_creature"])
        self.assertEqual(effect["xmage_additional_cost_class"], "SacrificeTargetCost")
        self.assertEqual(effect["xmage_additional_cost_target"], "artifact_or_creature")

    def test_fixed_source_controller_draw_spell_blocks_unsupported_additional_cost(self) -> None:
        row = queue_row(split.DRAW_UNIT, effect_classes=["DrawCardSourceControllerEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Bankrupt in Blood",
                oracle_text="As an additional cost to cast this spell, sacrifice two creatures.\nDraw three cards.",
            ),
            source_text=(
                "this.getSpellAbility().addCost(new SacrificeTargetCost(2, StaticFilters.FILTER_PERMANENT_CREATURES));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(3));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "draw_additional_cost_not_supported")

    def test_reveal_library_pick_spell_creature_or_land_is_package_safe(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["RevealLibraryPickControllerEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Grisly Salvage",
                type_line="Instant",
                oracle_text=(
                    "Reveal the top five cards of your library. "
                    "You may put a creature or land card from among them into your hand. "
                    "Put the rest into your graveyard."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new RevealLibraryPickControllerEffect(
                    5, 1, StaticFilters.FILTER_CARD_CREATURE_OR_LAND, PutCards.HAND, PutCards.GRAVEYARD));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "dig_to_hand")
        self.assertEqual(effect["battle_model_scope"], split.LIBRARY_PICK_SPELL_SCOPE)
        self.assertEqual(effect["look_count"], 5)
        self.assertEqual(effect["pick_count"], 1)
        self.assertEqual(effect["pick_target"], "creature_or_land")
        self.assertEqual(effect["target_constraints"]["card_types"], ["creature", "land"])
        self.assertEqual(effect["rest_destination"], "graveyard")
        self.assertTrue(effect["pick_up_to_count"])
        self.assertFalse(effect["pick_all_matching"])

    def test_reveal_library_pick_spell_snow_all_matching_is_package_safe(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["RevealLibraryPickControllerEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Glacial Revelation",
                type_line="Sorcery",
                oracle_text=(
                    "Reveal the top six cards of your library. "
                    "You may put any number of snow permanent cards from among them into your hand. "
                    "Put the rest into your graveyard."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterPermanentCard("snow permanent cards");
                static {
                    filter.add(SuperType.SNOW.getPredicate());
                }
                this.getSpellAbility().addEffect(new RevealLibraryPickControllerEffect(
                    6, Integer.MAX_VALUE, filter, PutCards.HAND, PutCards.GRAVEYARD));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["look_count"], 6)
        self.assertEqual(effect["pick_count"], 6)
        self.assertEqual(effect["pick_target"], "snow_permanent")
        self.assertTrue(effect["pick_all_matching"])
        self.assertEqual(effect["target_constraints"]["supertypes"], ["snow"])

    def test_reveal_library_pick_spell_blocks_flashback_ability(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["RevealLibraryPickControllerEffect"],
            ability_classes=["FlashbackAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Tracker's Instincts",
                type_line="Sorcery",
                oracle_text=(
                    "Reveal the top four cards of your library. "
                    "You may put a creature card from among them into your hand. "
                    "Put the rest into your graveyard. Flashback {2}{U}"
                ),
            ),
            source_text="this.getSpellAbility().addEffect(new RevealLibraryPickControllerEffect(4, 1, filter, PutCards.HAND, PutCards.GRAVEYARD));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "library_pick_ability_class_not_simple")

    def test_look_library_pick_spell_any_card_bottom_is_package_safe(self) -> None:
        row = queue_row(
            split.LOOK_LIBRARY_PICK_SPELL_UNIT,
            effect_classes=["LookLibraryAndPickControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Anticipate",
                type_line="Instant",
                oracle_text=(
                    "Look at the top three cards of your library. "
                    "Put one of them into your hand and the rest on the bottom "
                    "of your library in any order."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new LookLibraryAndPickControllerEffect("
                "3, 1, PutCards.HAND, PutCards.BOTTOM_ANY));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "dig_to_hand")
        self.assertEqual(effect["battle_model_scope"], split.LOOK_LIBRARY_PICK_SPELL_SCOPE)
        self.assertEqual(effect["look_count"], 3)
        self.assertEqual(effect["pick_count"], 1)
        self.assertEqual(effect["pick_target"], "any_card")
        self.assertEqual(effect["rest_destination"], "library_bottom")
        self.assertEqual(effect["library_bottom_order"], "any")
        self.assertFalse(effect["pick_up_to_count"])

    def test_look_library_pick_spell_filtered_bottom_is_package_safe(self) -> None:
        row = queue_row(
            split.LOOK_LIBRARY_PICK_SPELL_UNIT,
            effect_classes=["LookLibraryAndPickControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Adventurous Impulse",
                type_line="Sorcery",
                oracle_text=(
                    "Look at the top three cards of your library. "
                    "You may reveal a creature or land card from among them and put it into your hand. "
                    "Put the rest on the bottom of your library in any order."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new LookLibraryAndPickControllerEffect("
                "3, 1, StaticFilters.FILTER_CARD_CREATURE_OR_LAND, "
                "PutCards.HAND, PutCards.BOTTOM_ANY));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["pick_target"], "creature_or_land")
        self.assertEqual(effect["target_constraints"]["card_types"], ["creature", "land"])
        self.assertTrue(effect["pick_up_to_count"])
        self.assertTrue(effect["reveal"])

    def test_look_library_pick_spell_blocks_top_destination(self) -> None:
        row = queue_row(
            split.LOOK_LIBRARY_PICK_SPELL_UNIT,
            effect_classes=["LookLibraryAndPickControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Diabolic Vision",
                type_line="Sorcery",
                oracle_text=(
                    "Look at the top five cards of your library. "
                    "Put one of them into your hand and the rest on top of your library in any order."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new LookLibraryAndPickControllerEffect("
                "5, 1, PutCards.HAND, PutCards.TOP_ANY));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "look_library_pick_oracle_not_simple")

    def test_library_tutor_land_to_battlefield_spell_is_package_safe(self) -> None:
        row = queue_row(split.TUTOR_UNIT, effect_classes=["SearchLibraryPutInPlayEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Farseek",
                type_line="Sorcery",
                oracle_text=(
                    "Search your library for a Plains, Island, Swamp, or Mountain card, "
                    "put it onto the battlefield tapped, then shuffle."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard("Plains, Island, Swamp, or Mountain card");
                this.getSpellAbility().addEffect(new SearchLibraryPutInPlayEffect(
                    new TargetCardInLibrary(filter), true));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "tutor")
        self.assertEqual(effect["battle_model_scope"], split.TUTOR_BATTLEFIELD_SCOPE)
        self.assertEqual(effect["target"], "plains_island_swamp_or_mountain_to_battlefield")
        self.assertEqual(effect["count"], 1)
        self.assertTrue(effect["tutor_enters_tapped"])

    def test_library_tutor_to_top_spell_is_package_safe(self) -> None:
        row = queue_row(split.TUTOR_UNIT, effect_classes=["SearchLibraryPutOnLibraryEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Personal Tutor",
                type_line="Sorcery",
                oracle_text="Search your library for a sorcery card, reveal it, then shuffle and put that card on top.",
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard("sorcery card");
                this.getSpellAbility().addEffect(new SearchLibraryPutOnLibraryEffect(new TargetCardInLibrary(filter), true));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "tutor")
        self.assertEqual(effect["battle_model_scope"], split.TUTOR_TOP_SCOPE)
        self.assertEqual(effect["target"], "sorcery_to_top")
        self.assertEqual(effect["count"], 1)

    def test_library_tutor_to_hand_spell_is_package_safe(self) -> None:
        row = queue_row(split.TUTOR_HAND_UNIT, effect_classes=["SearchLibraryPutInHandEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Tutor",
                type_line="Sorcery",
                oracle_text="Search your library for a card, reveal it, put it into your hand, then shuffle.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new SearchLibraryPutInHandEffect(new TargetCardInLibrary(), true));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "tutor")
        self.assertEqual(effect["battle_model_scope"], split.TUTOR_HAND_SCOPE)
        self.assertEqual(effect["target"], "any_to_hand")
        self.assertEqual(effect["destination"], "hand")
        self.assertEqual(effect["count"], 1)

    def test_library_tutor_to_hand_spell_preserves_subtype_constraints(self) -> None:
        row = queue_row(split.TUTOR_HAND_UNIT, effect_classes=["SearchLibraryPutInHandEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Armory",
                type_line="Sorcery",
                oracle_text="Search your library for an Aura or Equipment card, reveal it, put it into your hand, then shuffle.",
            ),
            source_text="""
                private static final FilterCard auraOrEquipmentTarget = new FilterCard("Aura or Equipment card");
                this.getSpellAbility().addEffect(
                    new SearchLibraryPutInHandEffect(new TargetCardInLibrary(1, 1, auraOrEquipmentTarget), true));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.TUTOR_HAND_SCOPE)
        self.assertEqual(effect["target"], "any_to_hand")
        self.assertEqual(effect["target_subtypes"], ["aura", "equipment"])

    def test_library_tutor_to_hand_spell_preserves_land_subtype_constraints(self) -> None:
        row = queue_row(split.TUTOR_HAND_UNIT, effect_classes=["SearchLibraryPutInHandEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Safewright",
                type_line="Sorcery",
                oracle_text="Search your library for a Forest or Plains card, reveal it, put it into your hand, then shuffle.",
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard("Forest or Plains card");
                static {
                    filter.add(Predicates.or(SubType.FOREST.getPredicate(), SubType.PLAINS.getPredicate()));
                }
                this.getSpellAbility().addEffect(new SearchLibraryPutInHandEffect(new TargetCardInLibrary(filter), true));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "land_to_hand")
        self.assertEqual(effect["target_card_types"], ["land"])
        self.assertEqual(effect["target_subtypes"], ["forest", "plains"])

    def test_library_tutor_to_hand_spell_preserves_source_creature_subtype_constraint(self) -> None:
        row = queue_row(split.TUTOR_HAND_UNIT, effect_classes=["SearchLibraryPutInHandEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Mercenary",
                type_line="Sorcery",
                oracle_text="Search your library for a Mercenary card, reveal that card, put it into your hand, then shuffle.",
            ),
            source_text="""
                private static final FilterCard filter = new FilterCreatureCard("Mercenary card");
                static {
                    filter.add(SubType.MERCENARY.getPredicate());
                }
                this.getSpellAbility().addEffect(new SearchLibraryPutInHandEffect(new TargetCardInLibrary(filter), true, true));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "any_to_hand")
        self.assertEqual(effect["target_card_types"], ["creature"])
        self.assertEqual(effect["target_subtypes"], ["mercenary"])

    def test_library_tutor_to_hand_spell_blocks_dynamic_land_count(self) -> None:
        row = queue_row(split.TUTOR_HAND_UNIT, effect_classes=["SearchLibraryPutInHandEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Beseech",
                type_line="Sorcery",
                oracle_text=(
                    "Search your library for a card with mana value less than or equal to the number of lands you control, "
                    "reveal it, put it into your hand, then shuffle."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard("card with mana value less than or equal to the number of lands you control");
                this.getSpellAbility().addEffect(new SearchLibraryPutInHandEffect(new TargetCardInLibrary(filter), true));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "library_tutor_oracle_target_not_supported")

    def test_library_tutor_spell_blocks_additional_cost(self) -> None:
        row = queue_row(split.TUTOR_UNIT, effect_classes=["SearchLibraryPutInPlayEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Migration",
                type_line="Sorcery",
                oracle_text=(
                    "As an additional cost to cast this spell, reveal a Dinosaur card from your hand or pay {1}. "
                    "Search your library for a basic land card, put it onto the battlefield tapped, then shuffle."
                ),
            ),
            source_text="""
                this.getSpellAbility().addCost(new OptionalAdditionalCostImpl("reveal a Dinosaur card from your hand or pay {1}"));
                this.getSpellAbility().addEffect(new SearchLibraryPutInPlayEffect(
                    new TargetCardInLibrary(StaticFilters.FILTER_CARD_BASIC_LAND), true));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "additional_cost_detected")

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

    def test_permanent_activated_draw_maps_sacrifice_target_cost(self) -> None:
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
                name="Fixture Chef",
                type_line="Enchantment Creature - Human Citizen",
                oracle_text="{1}{B}, Sacrifice an artifact or creature: Draw a card.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DrawCardSourceControllerEffect(1), new ManaCostsImpl<>("{1}{B}")
                );
                ability.addCost(new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_CREATURE));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DRAW_SCOPE)
        self.assertEqual(effect["activated_draw_count"], 1)
        self.assertEqual(effect["activation_sacrifice_target"], "artifact_or_creature")
        self.assertTrue(effect["activation_requires_sacrifice_target"])
        self.assertFalse(effect["activation_requires_sacrifice"])

    def test_permanent_activated_draw_maps_pay_life_cost(self) -> None:
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
                name="Fixture Greed",
                type_line="Enchantment",
                oracle_text="{B}, Pay 2 life: Draw a card.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DrawCardSourceControllerEffect(1), new ManaCostsImpl<>("{B}")
                );
                ability.addCost(new PayLifeCost(2));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DRAW_SCOPE)
        self.assertEqual(effect["activated_draw_count"], 1)
        self.assertEqual(effect["activation_life_cost"], 2)
        self.assertFalse(effect["activation_requires_tap"])
        self.assertFalse(effect["activation_requires_sacrifice"])

    def test_permanent_activated_draw_blocks_source_and_target_sacrifice_cost(self) -> None:
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
                name="Fixture Unsafe Altar",
                type_line="Artifact",
                oracle_text="{1}, Sacrifice a creature: Draw a card.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DrawCardSourceControllerEffect(1), new GenericManaCost(1)
                );
                ability.addCost(new SacrificeSourceCost());
                ability.addCost(new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE));
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_draw_source_cost_not_supported")

    def test_permanent_activated_draw_maps_discard_card_cost(self) -> None:
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

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DRAW_SCOPE)
        self.assertTrue(effect["activated_draw"])
        self.assertEqual(effect["activated_draw_count"], 1)
        self.assertEqual(effect["activation_cost_mana"], "{R}")
        self.assertEqual(effect["activation_discard_count"], 1)
        self.assertEqual(effect["activation_discard_target"], "any_card")
        self.assertTrue(effect["activation_requires_discard_card"])
        self.assertTrue(effect["activation_requires_tap"])

    def test_permanent_activated_draw_blocks_filtered_discard_cost(self) -> None:
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
                name="Fixture Entomber",
                type_line="Creature - Zombie",
                oracle_text="{T}, Discard a creature card: Draw a card.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DrawCardSourceControllerEffect(1),
                    new TapSourceCost()
                );
                ability.addCost(new DiscardCardCost(StaticFilters.FILTER_CARD_CREATURE_A));
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_draw_oracle_cost_not_supported")

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

    def test_permanent_activated_draw_discard_maps_simple_tap_cost(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawDiscardControllerEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Looter",
                type_line="Creature - Merfolk Rogue",
                oracle_text="{T}: Draw a card, then discard a card.",
            ),
            source_text="""
                this.addAbility(new SimpleActivatedAbility(
                    new DrawDiscardControllerEffect(), new TapSourceCost()));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DRAW_DISCARD_SCOPE)
        self.assertTrue(effect["activated_draw_discard"])
        self.assertEqual(effect["activated_draw_count"], 1)
        self.assertEqual(effect["activated_discard_count"], 1)
        self.assertTrue(effect["activation_requires_tap"])
        self.assertFalse(effect["activation_requires_sacrifice"])

    def test_permanent_activated_draw_discard_maps_fixed_counts_and_life_cost(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawDiscardControllerEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Desires",
                type_line="Enchantment",
                oracle_text="{1}, Pay 1 life: Draw two cards, then discard three cards.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DrawDiscardControllerEffect(2, 3), new ManaCostsImpl<>("{1}")
                );
                ability.addCost(new PayLifeCost(1));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DRAW_DISCARD_SCOPE)
        self.assertEqual(effect["activated_draw_count"], 2)
        self.assertEqual(effect["activated_discard_count"], 3)
        self.assertEqual(effect["activation_cost_generic"], 1)
        self.assertEqual(effect["activation_life_cost"], 1)

    def test_permanent_activated_draw_discard_maps_self_sacrifice_cost(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawDiscardControllerEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Researcher",
                type_line="Creature - Human Wizard",
                oracle_text="Sacrifice Fixture Researcher: Draw a card, then discard a card.",
            ),
            source_text="""
                this.addAbility(new SimpleActivatedAbility(
                    new DrawDiscardControllerEffect(), new SacrificeSourceCost()));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DRAW_DISCARD_SCOPE)
        self.assertTrue(effect["activation_requires_sacrifice"])
        self.assertTrue(effect["activated_self_sacrifice_draw_discard"])

    def test_permanent_activated_draw_discard_blocks_optional_effect(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawDiscardControllerEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Optional Looter",
                type_line="Creature - Wizard",
                oracle_text="{T}: You may draw a card. If you do, discard a card.",
            ),
            source_text="""
                this.addAbility(new SimpleActivatedAbility(
                    new DrawDiscardControllerEffect(true), new TapSourceCost()));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_draw_discard_oracle_not_simple")

    def test_spell_cast_draw_engine_maps_creature_spell_filter(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["SpellCastControllerTriggeredAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Beast Whisperer",
                type_line="Creature - Elf Druid",
                oracle_text="Whenever you cast a creature spell, draw a card.",
            ),
            source_text="""
                this.addAbility(new SpellCastControllerTriggeredAbility(
                    new DrawCardSourceControllerEffect(1),
                    StaticFilters.FILTER_SPELL_A_CREATURE, false
                ));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.SPELL_CAST_DRAW_ENGINE_SCOPE)
        self.assertEqual(effect["trigger"], "spell_cast")
        self.assertEqual(effect["trigger_effect"], "draw_cards")
        self.assertEqual(effect["spell_cast_draw_count"], 1)
        self.assertEqual(effect["spell_cast_draw_card_types"], ["creature"])

    def test_spell_cast_draw_engine_maps_subtype_or_filter(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["SpellCastControllerTriggeredAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Sram, Senior Edificer",
                type_line="Legendary Creature - Dwarf Advisor",
                oracle_text="Whenever you cast an Aura, Equipment, or Vehicle spell, draw a card.",
            ),
            source_text="""
                private static final FilterSpell filter = new FilterSpell(
                    "an Aura, Equipment, or Vehicle spell");
                static {
                    filter.add(Predicates.or(SubType.AURA.getPredicate(),
                        SubType.EQUIPMENT.getPredicate(),
                        SubType.VEHICLE.getPredicate()));
                }
                this.addAbility(new SpellCastControllerTriggeredAbility(
                    new DrawCardSourceControllerEffect(1), filter, false));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["spell_cast_draw_count"], 1)
        self.assertEqual(effect["spell_cast_draw_required_subtypes"], ["aura", "equipment", "vehicle"])

    def test_spell_cast_draw_engine_maps_graveyard_source_filter(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["SpellCastControllerTriggeredAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Secrets of the Dead",
                type_line="Enchantment",
                oracle_text="Whenever you cast a spell from your graveyard, draw a card.",
            ),
            source_text="""
                private static final FilterSpell filter = new FilterSpell("a spell from your graveyard");
                static {
                    filter.add(new SpellZonePredicate(Zone.GRAVEYARD));
                }
                this.addAbility(new SpellCastControllerTriggeredAbility(
                    new DrawCardSourceControllerEffect(1), filter, false));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["trigger"], "spell_cast")
        self.assertEqual(effect["spell_cast_draw_source_zone"], "graveyard")

    def test_spell_cast_draw_engine_blocks_optional_cost(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["SpellCastControllerTriggeredAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Dreamcatcher",
                type_line="Creature - Spirit",
                oracle_text=(
                    "Whenever you cast a Spirit or Arcane spell, you may sacrifice "
                    "Dreamcatcher. If you do, draw a card."
                ),
            ),
            source_text="""
                this.addAbility(new SpellCastControllerTriggeredAbility(new DoIfCostPaid(
                    new DrawCardSourceControllerEffect(1), new SacrificeSourceCost()
                ), StaticFilters.FILTER_SPELL_SPIRIT_OR_ARCANE, false));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "spell_cast_draw_oracle_filter_not_supported")

    def test_spell_cast_add_counters_maps_noncreature_spell_filter_with_keyword(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_SOURCE_UNIT,
            effect_classes=["AddCountersSourceEffect"],
            ability_kind="triggered",
            ability_classes=["SpellCastControllerTriggeredAbility", "TrampleAbility"],
            xmage_signals=["counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Pyroceratops",
                type_line="Creature - Elemental Dinosaur",
                oracle_text=(
                    "Trample\n"
                    "Whenever you cast a noncreature spell, put a +1/+1 counter on Pyroceratops."
                ),
            ),
            source_text="""
                this.addAbility(TrampleAbility.getInstance());
                this.addAbility(new SpellCastControllerTriggeredAbility(
                    new AddCountersSourceEffect(CounterType.P1P1.createInstance()),
                    StaticFilters.FILTER_SPELL_A_NON_CREATURE, false
                ));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.SPELL_CAST_ADD_COUNTERS_SOURCE_SCOPE)
        self.assertEqual(effect["trigger"], "noncreature_spell_cast")
        self.assertEqual(effect["trigger_effect"], "add_counters")
        self.assertTrue(effect["spell_cast_add_counters"])
        self.assertEqual(effect["spell_cast_add_counters_count"], 1)
        self.assertEqual(effect["spell_cast_add_counters_counter_type"], "+1/+1")
        self.assertEqual(effect["spell_cast_add_counters_target"], "self")
        self.assertEqual(effect["counter_count"], 1)
        self.assertEqual(effect["keywords"], ["trample"])

    def test_spell_cast_add_counters_maps_creature_mana_value_filter(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_SOURCE_UNIT,
            effect_classes=["AddCountersSourceEffect"],
            ability_kind="triggered",
            ability_classes=["SpellCastControllerTriggeredAbility"],
            xmage_signals=["counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Kurgadon",
                type_line="Creature - Beast",
                oracle_text=(
                    "Whenever you cast a creature spell with mana value 6 or greater, "
                    "put three +1/+1 counters on Kurgadon."
                ),
            ),
            source_text="""
                private static final FilterSpell filterSpell = new FilterSpell(
                    "a creature spell with mana value 6 or greater");
                static {
                    filterSpell.add(CardType.CREATURE.getPredicate());
                    filterSpell.add(new ManaValuePredicate(ComparisonType.MORE_THAN, 5));
                }
                this.addAbility(new SpellCastControllerTriggeredAbility(
                    new AddCountersSourceEffect(CounterType.P1P1.createInstance(3)),
                    filterSpell, false));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["spell_cast_add_counters_count"], 3)
        self.assertEqual(effect["spell_cast_add_counters_card_types"], ["creature"])
        self.assertEqual(effect["spell_cast_add_counters_mana_value_min"], 6)

    def test_spell_cast_add_counters_maps_color_filter(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_SOURCE_UNIT,
            effect_classes=["AddCountersSourceEffect"],
            ability_kind="triggered",
            ability_classes=["SpellCastControllerTriggeredAbility"],
            xmage_signals=["counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Quirion Dryad",
                type_line="Creature - Dryad",
                oracle_text=(
                    "Whenever you cast a spell that's white, blue, black, or red, "
                    "put a +1/+1 counter on this creature."
                ),
            ),
            source_text="""
                private static final FilterSpell filter =
                    new FilterSpell("a spell that's white, blue, black, or red");
                static {
                    filter.add(Predicates.or(
                        new ColorPredicate(ObjectColor.WHITE),
                        new ColorPredicate(ObjectColor.BLUE),
                        new ColorPredicate(ObjectColor.BLACK),
                        new ColorPredicate(ObjectColor.RED)));
                }
                this.addAbility(new SpellCastControllerTriggeredAbility(
                    new AddCountersSourceEffect(CounterType.P1P1.createInstance(1)),
                    filter, false));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["spell_cast_add_counters_required_colors"], ["W", "U", "B", "R"])

    def test_spell_cast_add_counters_blocks_adventure_filter(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_SOURCE_UNIT,
            effect_classes=["AddCountersSourceEffect"],
            ability_kind="triggered",
            ability_classes=["SpellCastControllerTriggeredAbility"],
            xmage_signals=["counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Wandermare",
                type_line="Creature - Horse",
                oracle_text=(
                    "Whenever you cast a creature spell that has an Adventure, "
                    "put a +1/+1 counter on Wandermare."
                ),
            ),
            source_text="""
                private static final FilterSpell filter =
                    new FilterCreatureSpell("a creature spell that has an Adventure");
                static {
                    filter.add(AdventurePredicate.instance);
                }
                this.addAbility(new SpellCastControllerTriggeredAbility(
                    new AddCountersSourceEffect(CounterType.P1P1.createInstance()),
                    filter, false));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "spell_cast_add_counters_oracle_filter_not_supported")

    def test_permanent_activated_life_gain_maps_simple_mana_and_tap_cost(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["GainLifeEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fountain of Youth",
                type_line="Artifact",
                oracle_text="{2}, {T}: You gain 1 life.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new GainLifeEffect(1),
                    new GenericManaCost(2)
                );
                ability.addCost(new TapSourceCost());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "artifact")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_LIFE_GAIN_SCOPE)
        self.assertEqual(effect["activated_effect"], "controller_gain_life")
        self.assertEqual(effect["life_gain_amount"], 1)
        self.assertEqual(effect["activated_life_gain_amount"], 1)
        self.assertEqual(effect["activation_cost_mana"], "{2}")
        self.assertEqual(effect["activation_cost_generic"], 2)
        self.assertEqual(effect["activation_cost_colors"], [])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertFalse(effect["activation_requires_sacrifice"])

    def test_permanent_activated_life_gain_maps_self_sacrifice_cost(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["GainLifeEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Bottle Gnomes",
                type_line="Artifact Creature - Gnome",
                oracle_text="Sacrifice this creature: You gain 3 life.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new GainLifeEffect(3),
                    new SacrificeSourceCost()
                );
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_LIFE_GAIN_SCOPE)
        self.assertEqual(effect["life_gain_amount"], 3)
        self.assertEqual(effect["activation_cost_mana"], "{0}")
        self.assertEqual(effect["activation_cost_generic"], 0)
        self.assertEqual(effect["activation_cost_colors"], [])
        self.assertFalse(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])
        self.assertTrue(effect["activated_self_sacrifice_life_gain"])

    def test_permanent_activated_life_gain_blocks_target_sacrifice_cost(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["GainLifeEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Altar",
                type_line="Artifact",
                oracle_text="{1}, Sacrifice a creature: You gain 3 life.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new GainLifeEffect(3),
                    new GenericManaCost(1)
                );
                ability.addCost(new SacrificeTargetCost(new TargetControlledCreaturePermanent()));
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_life_gain_oracle_cost_not_supported")

    def test_permanent_activated_life_gain_blocks_dynamic_amount(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["GainLifeEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Healer",
                type_line="Creature - Cleric",
                oracle_text="{T}: You gain life equal to this creature's toughness.",
            ),
            source_text="""
                this.addAbility(new SimpleActivatedAbility(
                    new GainLifeEffect(SourcePermanentToughnessValue.instance),
                    new TapSourceCost()));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_life_gain_oracle_not_simple")

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

    def test_fixed_damage_spell_maps_nonred_and_nonwhite_creature_targets(self) -> None:
        cases = [
            (
                "Strafe",
                "Strafe deals 3 damage to target nonred creature.",
                'new FilterCreaturePermanent("nonred creature");'
                "filter.add(Predicates.not(new ColorPredicate(ObjectColor.RED)));",
                {"card_types": ["creature"], "exclude_colors": ["R"]},
            ),
            (
                "Sunlance",
                "Sunlance deals 3 damage to target nonwhite creature.",
                'new FilterCreaturePermanent("nonwhite creature");'
                "filter.add(Predicates.not(new ColorPredicate(ObjectColor.WHITE)));",
                {"card_types": ["creature"], "exclude_colors": ["W"]},
            ),
        ]
        for name, oracle, source_filter, constraints in cases:
            with self.subTest(card=name):
                row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"], xmage_signals=["targeting"])
                proposal, reason = split.split_row(
                    row,
                    metadata(name=name, type_line="Sorcery", oracle_text=oracle),
                    source_text=(
                        source_filter
                        + "this.getSpellAbility().addEffect(new DamageTargetEffect(3));"
                        + "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
                    ),
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["battle_model_scope"], split.DAMAGE_SCOPE)
                self.assertEqual(effect["amount"], 3)
                self.assertEqual(effect["target"], "creature")
                self.assertEqual(effect["target_constraints"], constraints)

    def test_fixed_damage_spell_maps_creature_sacrifice_additional_cost(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="As an additional cost to cast this spell, sacrifice a creature. Fixture Blast deals 3 damage to any target."),
            source_text=(
                "this.getSpellAbility().addCost(new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE));"
                "this.getSpellAbility().addTarget(new TargetAnyTarget());"
                "this.getSpellAbility().addEffect(new DamageTargetEffect(3));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DAMAGE_SCOPE)
        self.assertEqual(effect["amount"], 3)
        self.assertTrue(effect["requires_sacrifice_creature"])
        self.assertEqual(effect["additional_cost"], "sacrifice_creature")
        self.assertEqual(effect["xmage_additional_cost_target"], "creature")

    def test_fixed_damage_spell_maps_land_sacrifice_additional_cost(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="As an additional cost to cast this spell, sacrifice a land. Fixture Volley deals 3 damage to any target."),
            source_text=(
                "this.getSpellAbility().addCost(new SacrificeTargetCost(StaticFilters.FILTER_LAND));"
                "this.getSpellAbility().addEffect(new DamageTargetEffect(3));"
                "this.getSpellAbility().addTarget(new TargetAnyTarget());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertTrue(effect["requires_sacrifice_land"])
        self.assertEqual(effect["additional_cost"], "sacrifice_land")
        self.assertEqual(effect["xmage_additional_cost_target"], "land")

    def test_fixed_damage_spell_maps_artifact_or_creature_sacrifice_additional_cost(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "As an additional cost to cast this spell, sacrifice an artifact or creature. "
                    "Fixture Blast deals 5 damage to any target."
                )
            ),
            source_text=(
                "this.getSpellAbility().addCost(new SacrificeTargetCost("
                "StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_CREATURE));"
                "this.getSpellAbility().addTarget(new TargetAnyTarget());"
                "this.getSpellAbility().addEffect(new DamageTargetEffect(5));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DAMAGE_SCOPE)
        self.assertEqual(effect["amount"], 5)
        self.assertEqual(effect["additional_cost"], "sacrifice_artifact_or_creature")
        self.assertTrue(effect["requires_sacrifice_artifact_or_creature"])
        self.assertEqual(effect["xmage_additional_cost_target"], "artifact_or_creature")

    def test_fixed_damage_spell_blocks_creature_or_enchantment_sacrifice_cost(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="As an additional cost to cast this spell, sacrifice a creature or enchantment. Fixture Flare deals 5 damage to target creature."),
            source_text=(
                "this.getSpellAbility().addCost(new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE_OR_ENCHANTMENT));"
                "this.getSpellAbility().addEffect(new DamageTargetEffect(5));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "damage_additional_cost_not_supported")

    def test_fixed_damage_exile_if_dies_spell_maps_to_runtime(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect", "ExileTargetIfDiesEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Lava Coil",
                type_line="Sorcery",
                oracle_text=(
                    "Lava Coil deals 4 damage to target creature. "
                    "If that creature would die this turn, exile it instead."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new DamageTargetEffect(4));"
                "this.getSpellAbility().addEffect(new ExileTargetIfDiesEffect());"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DAMAGE_EXILE_IF_DIES_SCOPE)
        self.assertEqual(effect["amount"], 4)
        self.assertEqual(effect["target"], "creature")
        self.assertTrue(effect["exile_if_dies_from_damage"])
        self.assertEqual(effect["xmage_effect_classes"], ["DamageTargetEffect", "ExileTargetIfDiesEffect"])

    def test_fixed_damage_exile_if_dies_spell_maps_creature_or_planeswalker_target(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect", "ExileTargetIfDiesEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Scorching Dragonfire",
                type_line="Instant",
                oracle_text=(
                    "Scorching Dragonfire deals 3 damage to target creature or planeswalker. "
                    "If that creature or planeswalker would die this turn, exile it instead."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new DamageTargetEffect(3));"
                "this.getSpellAbility().addEffect(new ExileTargetIfDiesEffect());"
                "this.getSpellAbility().addTarget(new TargetCreatureOrPlaneswalker());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DAMAGE_EXILE_IF_DIES_SCOPE)
        self.assertEqual(effect["target"], "creature_or_planeswalker")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature", "planeswalker"]})

    def test_fixed_damage_exile_if_dies_spell_blocks_additional_cost(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect", "ExileTargetIfDiesEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Betrayer's Bargain",
                type_line="Instant",
                oracle_text=(
                    "As an additional cost to cast this spell, sacrifice a creature or enchantment. "
                    "Betrayer's Bargain deals 5 damage to target creature. "
                    "If that creature would die this turn, exile it instead."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addCost(new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE_OR_ENCHANTMENT));"
                "this.getSpellAbility().addEffect(new DamageTargetEffect(5));"
                "this.getSpellAbility().addEffect(new ExileTargetIfDiesEffect());"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertIn(reason, {"additional_cost_detected", "damage_exile_if_dies_additional_cost_not_supported"})

    def test_fixed_damage_exile_if_dies_spell_blocks_activated_permanent(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect", "ExileTargetIfDiesEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Nine-Ringed Bo",
                type_line="Legendary Artifact - Equipment",
                oracle_text=(
                    "Equipped creature has \"{T}: This creature deals 1 damage to target creature. "
                    "If that creature would die this turn, exile it instead.\""
                ),
            ),
            source_text=(
                "Ability ability = new SimpleActivatedAbility(new DamageTargetEffect(1), new TapSourceCost());"
                "ability.addEffect(new ExileTargetIfDiesEffect());"
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "not_instant_or_sorcery_spell")

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

    def test_fixed_life_gain_draw_spell_maps_to_composite_runtime(self) -> None:
        row = queue_row(split.LIFE_UNIT, effect_classes=["GainLifeEffect", "DrawCardSourceControllerEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="You gain 3 life.\nDraw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new GainLifeEffect(3));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "composite_resolution")
        self.assertEqual(effect["battle_model_scope"], split.LIFE_GAIN_DRAW_SCOPE)
        self.assertEqual(effect["life_gain_amount"], 3)
        self.assertEqual(effect["draw_count"], 1)
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["life_total_change", "draw_cards"],
        )

    def test_fixed_life_gain_draw_spell_blocks_dynamic_draw(self) -> None:
        row = queue_row(split.LIFE_UNIT, effect_classes=["GainLifeEffect", "DrawCardSourceControllerEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="You gain 3 life.\nDraw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new GainLifeEffect(3));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(2));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "life_gain_draw_source_not_fixed")

    def test_fixed_boost_draw_spell_maps_to_composite_runtime(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["BoostTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Target creature gets +1/+0 until end of turn. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostTargetEffect(1, 0, Duration.EndOfTurn));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "composite_resolution")
        self.assertEqual(effect["battle_model_scope"], split.BOOST_DRAW_SCOPE)
        self.assertEqual(effect["power_delta"], 1)
        self.assertEqual(effect["toughness_delta"], 0)
        self.assertEqual(effect["draw_count"], 1)
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["stat_modifier_until_eot", "draw_cards"],
        )

    def test_fixed_boost_draw_spell_blocks_dynamic_draw(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["BoostTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Target creature gets +1/+0 until end of turn. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostTargetEffect(1, 0, Duration.EndOfTurn));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(2));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "boost_draw_source_oracle_mismatch")

    def test_fixed_keyword_draw_spell_maps_bladebrand_pattern(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DrawCardSourceControllerEffect", "GainAbilityTargetEffect"],
            ability_classes=["DeathtouchAbility"],
            xmage_signals=["targeting", "draw"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Target creature gains deathtouch until end of turn. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new GainAbilityTargetEffect("
                "DeathtouchAbility.getInstance(), Duration.EndOfTurn));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1).concatBy(\"<br>\"));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "composite_resolution")
        self.assertEqual(effect["battle_model_scope"], split.KEYWORD_DRAW_SCOPE)
        self.assertEqual(effect["target_controller"], "any")
        self.assertEqual(effect["granted_keywords_until_eot"], ["deathtouch"])
        self.assertEqual(effect["draw_count"], 1)
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["stat_modifier_until_eot", "draw_cards"],
        )

    def test_fixed_keyword_draw_spell_blocks_nonmatching_source_draw_count(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DrawCardSourceControllerEffect", "GainAbilityTargetEffect"],
            ability_classes=["FlyingAbility"],
            xmage_signals=["targeting", "draw"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Target creature gains flying until end of turn. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new GainAbilityTargetEffect("
                "FlyingAbility.getInstance(), Duration.EndOfTurn));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(2));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "keyword_draw_source_oracle_draw_count_mismatch")

    def test_fixed_boost_keyword_draw_spell_maps_guided_strike_pattern(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=[
                "BoostTargetEffect",
                "GainAbilityTargetEffect",
                "DrawCardSourceControllerEffect",
            ],
            ability_classes=["FirstStrikeAbility"],
            xmage_signals=["targeting", "draw"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Target creature gets +1/+0 and gains first strike until end of turn.\n"
                    "Draw a card."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "Effect effect = new BoostTargetEffect(1, 0, Duration.EndOfTurn);"
                "this.getSpellAbility().addEffect(effect);"
                "effect = new GainAbilityTargetEffect(FirstStrikeAbility.getInstance(), Duration.EndOfTurn);"
                "this.getSpellAbility().addEffect(effect);"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1).concatBy(\"<br>\"));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "composite_resolution")
        self.assertEqual(effect["battle_model_scope"], split.BOOST_KEYWORD_DRAW_SCOPE)
        self.assertEqual(effect["power_delta"], 1)
        self.assertEqual(effect["toughness_delta"], 0)
        self.assertEqual(effect["granted_keywords_until_eot"], ["first_strike"])
        self.assertEqual(effect["draw_count"], 1)
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["stat_modifier_until_eot", "draw_cards"],
        )

    def test_fixed_boost_keyword_draw_spell_blocks_dynamic_boost_oracle(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=[
                "BoostTargetEffect",
                "GainAbilityTargetEffect",
                "DrawCardSourceControllerEffect",
            ],
            ability_classes=["TrampleAbility"],
            xmage_signals=["targeting", "draw"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Target creature gains trample and gets +X/+0 until end of turn, "
                    "where X is 1 plus the number of cards named Ancestral Anger in your graveyard.\n"
                    "Draw a card."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostTargetEffect(1, 0, Duration.EndOfTurn));"
                "this.getSpellAbility().addEffect(new GainAbilityTargetEffect("
                "TrampleAbility.getInstance(), Duration.EndOfTurn));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "boost_keyword_draw_oracle_not_exact_fixed")

    def test_fixed_boost_keyword_draw_spell_blocks_non_eot_source_duration(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=[
                "BoostTargetEffect",
                "GainAbilityTargetEffect",
                "DrawCardSourceControllerEffect",
            ],
            ability_classes=["FirstStrikeAbility"],
            xmage_signals=["targeting", "draw"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Target creature gets +1/+0 and gains first strike until end of turn.\n"
                    "Draw a card."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostTargetEffect(1, 0, Duration.EndOfTurn));"
                "this.getSpellAbility().addEffect(new GainAbilityTargetEffect("
                "FirstStrikeAbility.getInstance(), Duration.WhileOnBattlefield));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "boost_keyword_draw_source_not_exact_fixed")

    def test_fixed_boost_keyword_draw_spell_blocks_activated_or_multi_ability_pattern(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=[
                "BoostTargetEffect",
                "GainAbilityTargetEffect",
                "DrawCardSourceControllerEffect",
            ],
            ability_classes=[
                "ActivateAsSorceryActivatedAbility",
                "SimpleActivatedAbility",
                "TrampleAbility",
            ],
            xmage_signals=["targeting", "draw", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Artifact",
                oracle_text=(
                    "{1}, Sacrifice this artifact: Draw a card.\n"
                    "{2}{G}, Sacrifice this artifact: Target creature you control gets +3/+3 "
                    "and gains trample until end of turn. Draw a card. Activate only as a sorcery."
                ),
            ),
            source_text=(
                "this.addAbility(new SimpleActivatedAbility(new DrawCardSourceControllerEffect(1)));"
                "Ability ability = new ActivateAsSorceryActivatedAbility(new BoostTargetEffect(3, 3));"
                "ability.addEffect(new GainAbilityTargetEffect(TrampleAbility.getInstance()));"
                "ability.addTarget(new TargetControlledCreaturePermanent());"
                "ability.addEffect(new DrawCardSourceControllerEffect(1));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "not_instant_or_sorcery_spell")

    def test_fixed_scry_draw_spell_maps_scry_first_order_to_composite_runtime(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["ScryEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Scry 2, then draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new ScryEffect(2));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "composite_resolution")
        self.assertEqual(effect["battle_model_scope"], split.SCRY_DRAW_SCOPE)
        self.assertEqual(effect["scry_count"], 2)
        self.assertEqual(effect["draw_count"], 1)
        self.assertEqual(effect["resolution_order"], "scry_then_draw")
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["scry", "draw_cards"],
        )

    def test_fixed_scry_draw_spell_maps_draw_first_order_to_composite_runtime(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["ScryEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Draw a card. Scry 2."),
            source_text=(
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect());"
                "this.getSpellAbility().addEffect(new ScryEffect(2));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["resolution_order"], "draw_then_scry")
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["draw_cards", "scry"],
        )

    def test_fixed_scry_draw_spell_accepts_fixed_two_arg_scry_and_auxiliary_casting_ability(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["ScryEffect", "DrawCardSourceControllerEffect"],
            ability_classes=["ForetellAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Scry 2, then draw two cards.\n"
                    "Foretell {1}{U} (During your turn, you may pay {2} and exile this card "
                    "from your hand face down. Cast it on a later turn for its foretell cost.)"
                )
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new ScryEffect(2, false));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(2).concatBy(\", then\"));"
                "this.addAbility(new ForetellAbility(this, new ManaCostsImpl<>(\"{1}{U}\")));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["scry_count"], 2)
        self.assertEqual(effect["draw_count"], 2)
        self.assertEqual(effect["resolution_order"], "scry_then_draw")

    def test_fixed_scry_draw_spell_blocks_dynamic_scry(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["ScryEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Scry X, where X is the greatest mana value among permanents you control, "
                    "then draw three cards."
                )
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new ScryEffect(GreatestAmongPermanentsValue.instance));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(3));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "scry_draw_oracle_not_exact_fixed")

    def test_fixed_damage_scry_spell_maps_to_composite_runtime(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect", "ScryEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Magma Jet deals 2 damage to any target. Scry 2. "
                    "(Look at the top two cards of your library, then put any number of them on the bottom "
                    "and the rest on top in any order.)"
                )
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new DamageTargetEffect(2));"
                "this.getSpellAbility().addTarget(new TargetAnyTarget());"
                "this.getSpellAbility().addEffect(new ScryEffect(2));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "composite_resolution")
        self.assertEqual(effect["battle_model_scope"], split.DAMAGE_SCRY_SCOPE)
        self.assertEqual(effect["amount"], 2)
        self.assertEqual(effect["target"], "any_target")
        self.assertEqual(effect["scry_count"], 2)
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["direct_damage", "scry"],
        )

    def test_fixed_damage_scry_spell_blocks_triggered_source(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect", "ScryEffect"],
            ability_kind="triggered",
            ability_classes=["CastSecondSpellTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Iron-Fist Pulverizer",
                type_line="Creature - Goblin Artificer",
                oracle_text="Whenever you cast your second spell each turn, Iron-Fist Pulverizer deals 2 damage to target opponent. Scry 1.",
            ),
            source_text=(
                "Ability ability = new CastSecondSpellTriggeredAbility(new DamageTargetEffect(2));"
                "ability.addEffect(new ScryEffect(1));"
                "ability.addTarget(new TargetOpponent());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "not_instant_or_sorcery_spell")

    def test_fixed_destroy_scry_spell_maps_to_composite_runtime(self) -> None:
        row = queue_row(split.DESTROY_UNIT, effect_classes=["DestroyTargetEffect", "ScryEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy target artifact or enchantment. Scry 2."),
            source_text=(
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetPermanent(StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_ENCHANTMENT));"
                "this.getSpellAbility().addEffect(new ScryEffect(2));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DESTROY_SCRY_SCOPE)
        self.assertEqual(effect["target"], "artifact_or_enchantment")
        self.assertEqual(effect["destination"], "graveyard")
        self.assertEqual(effect["_composite_rule_components"][0]["effect"], "remove_permanent")
        self.assertEqual(effect["_composite_rule_components"][1]["effect"], "scry")

    def test_fixed_destroy_scry_spell_maps_power_three_restricted_target(self) -> None:
        row = queue_row(split.DESTROY_UNIT, effect_classes=["DestroyTargetEffect", "ScryEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy target creature with power 3 or greater. Scry 1."),
            source_text=(
                "filter.add(new PowerPredicate(ComparisonType.MORE_THAN, 2));"
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent(filter));"
                "this.getSpellAbility().addEffect(new ScryEffect(1));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "power_min": 3})

    def test_fixed_exile_scry_spell_maps_to_composite_runtime(self) -> None:
        row = queue_row(split.EXILE_UNIT, effect_classes=["ExileTargetEffect", "ScryEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Exile target artifact or enchantment. Scry 1."),
            source_text=(
                "this.getSpellAbility().addEffect(new ExileTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetPermanent(StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_ENCHANTMENT));"
                "this.getSpellAbility().addEffect(new ScryEffect(1));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.EXILE_SCRY_SCOPE)
        self.assertEqual(effect["target"], "artifact_or_enchantment")
        self.assertEqual(effect["destination"], "exile")
        self.assertEqual(effect["_composite_rule_components"][0]["effect"], "remove_permanent")
        self.assertEqual(effect["_composite_rule_components"][1]["effect"], "scry")

    def test_fixed_exile_scry_spell_maps_black_or_red_creature_or_planeswalker_target(self) -> None:
        row = queue_row(split.EXILE_UNIT, effect_classes=["ExileTargetEffect", "ScryEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Exile target creature or planeswalker that's black or red. Scry 1."),
            source_text=(
                "new FilterCreatureOrPlaneswalkerPermanent(\"creature or planeswalker that's black or red\");"
                "new ColorPredicate(ObjectColor.BLACK);"
                "new ColorPredicate(ObjectColor.RED);"
                "this.getSpellAbility().addEffect(new ExileTargetEffect());"
                "this.getSpellAbility().addEffect(new ScryEffect(1));"
                "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.EXILE_SCRY_SCOPE)
        self.assertEqual(effect["target"], "permanent")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature", "planeswalker"], "target_colors": ["B", "R"]})
        self.assertEqual(effect["resolution_order"], "exile_then_scry")

    def test_fixed_exile_scry_spell_maps_creature_vehicle_or_nonbasic_land_target(self) -> None:
        row = queue_row(split.EXILE_UNIT, effect_classes=["ExileTargetEffect", "ScryEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Exile target creature, Vehicle, or nonbasic land. Scry 1."),
            source_text=(
                'new FilterPermanent("creature, Vehicle, or nonbasic land");'
                "CardType.CREATURE.getPredicate();"
                "SubType.VEHICLE.getPredicate();"
                "Predicates.not(SuperType.BASIC.getPredicate());"
                "CardType.LAND.getPredicate();"
                "this.getSpellAbility().addEffect(new ExileTargetEffect());"
                "this.getSpellAbility().addEffect(new ScryEffect(1));"
                "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.EXILE_SCRY_SCOPE)
        self.assertEqual(effect["target"], "permanent")
        self.assertEqual(
            effect["target_constraints"],
            {
                "any_of": [
                    {"card_types": ["creature"]},
                    {"card_types": ["artifact"], "required_subtypes": ["vehicle"]},
                    {"card_types": ["land"], "exclude_supertypes": ["basic"]},
                ]
            },
        )
        self.assertEqual(effect["resolution_order"], "exile_then_scry")

    def test_fixed_bounce_scry_spell_maps_to_composite_runtime(self) -> None:
        row = queue_row(split.BOUNCE_UNIT, effect_classes=["ReturnToHandTargetEffect", "ScryEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Return target tapped creature to its owner's hand. Scry 1."),
            source_text=(
                "this.getSpellAbility().addEffect(new ReturnToHandTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent(filter));"
                "filter.add(TappedPredicate.TAPPED);"
                "this.getSpellAbility().addEffect(new ScryEffect(1));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.BOUNCE_SCRY_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "tapped_state": "tapped"})
        self.assertEqual(effect["destination"], "hand")
        self.assertEqual(effect["_composite_rule_components"][0]["effect"], "remove_creature")
        self.assertEqual(effect["_composite_rule_components"][1]["effect"], "scry")

    def test_fixed_damage_draw_spell_maps_to_composite_runtime(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DamageTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Zap deals 1 damage to any target. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new DamageTargetEffect(1));"
                "this.getSpellAbility().addTarget(new TargetAnyTarget());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "composite_resolution")
        self.assertEqual(effect["battle_model_scope"], split.DAMAGE_DRAW_SCOPE)
        self.assertEqual(effect["amount"], 1)
        self.assertEqual(effect["target"], "any_target")
        self.assertEqual(effect["draw_count"], 1)
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["direct_damage", "draw_cards"],
        )

    def test_fixed_damage_draw_spell_blocks_conditional_draw(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DamageTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Tweeze deals 3 damage to any target. You may discard a card. "
                    "If you do, draw a card."
                )
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new DamageTargetEffect(3));"
                "this.getSpellAbility().addTarget(new TargetAnyTarget());"
                "this.getSpellAbility().addEffect(new DoIfCostPaid(new DrawCardSourceControllerEffect(), "
                "new DiscardCardCost()));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "damage_draw_oracle_not_exact_fixed")

    def test_fixed_destroy_draw_spell_maps_to_composite_runtime(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DestroyTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy target nonblack creature. It can't be regenerated. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent(StaticFilters.FILTER_CREATURE_NON_BLACK));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "composite_resolution")
        self.assertEqual(effect["battle_model_scope"], split.DESTROY_DRAW_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "exclude_colors": ["B"]})
        self.assertEqual(effect["draw_count"], 1)
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["remove_creature", "draw_cards"],
        )
        self.assertEqual(effect["_composite_rule_components"][0]["destination"], "graveyard")

    def test_fixed_destroy_draw_spell_maps_colored_creature_cant_regenerate_targets(self) -> None:
        cases = [
            (
                "Annihilate",
                "Destroy target nonblack creature. It can't be regenerated. Draw a card.",
                "TargetPermanent(FILTER_PERMANENT_CREATURE_NON_BLACK);",
                {"card_types": ["creature"], "exclude_colors": ["B"]},
            ),
            (
                "Execute",
                "Destroy target white creature. It can't be regenerated. Draw a card.",
                'new FilterCreaturePermanent("white creature");'
                "filter.add(new ColorPredicate(ObjectColor.WHITE));",
                {"card_types": ["creature"], "target_colors": ["W"]},
            ),
            (
                "Slay",
                "Destroy target green creature. It can't be regenerated. Draw a card.",
                'new FilterCreaturePermanent("green creature");'
                "filter.add(new ColorPredicate(ObjectColor.GREEN));",
                {"card_types": ["creature"], "target_colors": ["G"]},
            ),
        ]
        for name, oracle, source_filter, constraints in cases:
            with self.subTest(card=name):
                row = queue_row(
                    split.DRAW_UNIT,
                    effect_classes=["DestroyTargetEffect", "DrawCardSourceControllerEffect"],
                )
                proposal, reason = split.split_row(
                    row,
                    metadata(name=name, type_line="Instant", oracle_text=oracle),
                    source_text=(
                        source_filter
                        + "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
                        + "this.getSpellAbility().addEffect(new DestroyTargetEffect(true));"
                        + "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1));"
                    ),
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["battle_model_scope"], split.DESTROY_DRAW_SCOPE)
                self.assertEqual(effect["target"], "creature")
                self.assertEqual(effect["target_constraints"], constraints)
                self.assertEqual(effect["draw_count"], 1)
                self.assertEqual(
                    effect["_composite_rule_components"][0]["target_constraints"],
                    constraints,
                )

    def test_permanent_activated_destroy_maps_green_creature_target(self) -> None:
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
                name="Eastern Paladin",
                type_line="Creature - Phyrexian Zombie Knight",
                oracle_text="{B}{B}, {T}: Destroy target green creature.",
            ),
            source_text="""
                private static final FilterCreaturePermanent filter =
                    new FilterCreaturePermanent("green creature");
                static { filter.add(new ColorPredicate(ObjectColor.GREEN)); }
                Ability ability = new SimpleActivatedAbility(
                    new DestroyTargetEffect(),
                    new ManaCostsImpl<>("{B}{B}")
                );
                ability.addTarget(new TargetPermanent(filter));
                ability.addCost(new TapSourceCost());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DESTROY_SCOPE)
        self.assertEqual(effect["activated_remove_target"], "green_creature")
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "target_colors": ["G"]})
        self.assertEqual(effect["activation_cost_mana"], "{B}{B}")
        self.assertTrue(effect["activation_requires_tap"])

    def test_fixed_destroy_draw_spell_blocks_dynamic_source_draw(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DestroyTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy target creature. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(2));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "destroy_draw_source_not_fixed")

    def test_fixed_destroy_draw_spell_blocks_dynamic_oracle_draw(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["DestroyTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy target creature. Draw a card for each creature that died this turn."),
            source_text=(
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "destroy_draw_oracle_not_exact_fixed")

    def test_fixed_bounce_draw_spell_maps_to_composite_runtime(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["ReturnToHandTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Return target creature to its owner's hand. Draw a card."),
            source_text=(
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new ReturnToHandTargetEffect());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "composite_resolution")
        self.assertEqual(effect["battle_model_scope"], split.BOUNCE_DRAW_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["destination"], "hand")
        self.assertEqual(effect["draw_count"], 1)
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["remove_creature", "draw_cards"],
        )
        self.assertEqual(effect["_composite_rule_components"][0]["destination"], "hand")

    def test_fixed_bounce_draw_spell_maps_nonland_permanent_target(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["ReturnToHandTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Return target nonland permanent to its owner's hand. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new ReturnToHandTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetNonlandPermanent());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.BOUNCE_DRAW_SCOPE)
        self.assertEqual(effect["target"], "nonland_permanent")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["permanent"], "exclude_card_types": ["land"]},
        )
        self.assertEqual(effect["_composite_rule_components"][0]["effect"], "remove_permanent")

    def test_fixed_bounce_draw_spell_maps_tapped_creature_constraint(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["ReturnToHandTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Return target tapped creature to its owner's hand. Draw a card."),
            source_text=(
                "filter.add(TappedPredicate.TAPPED);"
                "this.getSpellAbility().addEffect(new ReturnToHandTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "tapped_state": "tapped"})

    def test_fixed_bounce_draw_spell_blocks_dynamic_draw(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["ReturnToHandTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Return target creature to its owner's hand. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new ReturnToHandTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(2));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "bounce_draw_source_not_fixed")

    def test_fixed_bounce_draw_spell_blocks_modal_oracle(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["ReturnToHandTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Choose one — Draw three cards. Return up to two target creatures to their owners' hands."),
            source_text=(
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(3));"
                "Mode mode = new Mode(new ReturnToHandTargetEffect());"
                "mode.addTarget(new TargetCreaturePermanent(0, 2));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "bounce_draw_oracle_not_simple")

    def test_fixed_bounce_draw_spell_blocks_x_target_adjuster(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["ReturnToHandTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Return target nonland permanent with mana value X to its owner's hand. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new ReturnToHandTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetPermanent(new FilterNonlandPermanent(\"nonland permanent with mana value X\")));"
                "this.getSpellAbility().setTargetAdjuster(new XManaValueTargetAdjuster());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect(1));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "bounce_draw_oracle_not_exact_fixed")

    def test_damage_spell_with_mana_variable_x_maps_to_runtime(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Fixture Spell deals X damage to any target."),
            source_text="this.getSpellAbility().addEffect(new DamageTargetEffect(ManacostVariableValue.instance));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.X_DAMAGE_SCOPE)
        self.assertEqual(effect["damage_amount_source"], "x_value")

    def test_damage_spell_with_custom_variable_x_stays_blocked(self) -> None:
        row = queue_row(split.DAMAGE_UNIT, effect_classes=["DamageTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Fixture Spell deals X damage to any target."),
            source_text="this.getSpellAbility().addEffect(new DamageTargetEffect(FixtureDynamicValue.instance));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "x_damage_source_not_supported")

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

    def test_exile_spell_maps_mana_value_restricted_permanent_constraints(self) -> None:
        fixtures = [
            {
                "oracle": "Exile target permanent with mana value 4 or greater.",
                "source": (
                    "private static final FilterPermanent filter = "
                    "new FilterPermanent(\"permanent with mana value 4 or greater\");"
                    "filter.add(new ManaValuePredicate(ComparisonType.MORE_THAN, 3));"
                    "this.getSpellAbility().addEffect(new ExileTargetEffect());"
                    "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
                ),
                "constraints": {"card_types": ["permanent"], "mana_value_min": 4},
            },
            {
                "oracle": "Exile target permanent with mana value 1.",
                "source": (
                    "private static final FilterPermanent filter = "
                    "new FilterPermanent(\"permanent with mana value 1\");"
                    "filter.add(new ManaValuePredicate(ComparisonType.EQUAL_TO, 1));"
                    "this.getSpellAbility().addEffect(new ExileTargetEffect());"
                    "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
                ),
                "constraints": {"card_types": ["permanent"], "mana_value_min": 1, "mana_value_max": 1},
            },
            {
                "oracle": "Exile target creature with mana value 3 or less.",
                "source": (
                    "private static final FilterPermanent filter = "
                    "new FilterCreaturePermanent(\"creature with mana value 3 or less\");"
                    "filter.add(new ManaValuePredicate(ComparisonType.FEWER_THAN, 4));"
                    "this.getSpellAbility().addEffect(new ExileTargetEffect());"
                    "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
                ),
                "effect": "remove_creature",
                "target": "creature",
                "constraints": {"card_types": ["creature"], "mana_value_max": 3},
            },
        ]
        for fixture in fixtures:
            with self.subTest(oracle=fixture["oracle"]):
                row = queue_row(split.EXILE_UNIT, effect_classes=["ExileTargetEffect"])
                proposal, reason = split.split_row(
                    row,
                    metadata(oracle_text=fixture["oracle"]),
                    source_text=fixture["source"],
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["effect"], fixture.get("effect", "remove_permanent"))
                self.assertEqual(effect["target"], fixture.get("target", "permanent"))
                self.assertEqual(effect["target_constraints"], fixture["constraints"])
                self.assertEqual(effect["destination"], "exile")

    def test_exile_spell_blocks_mana_value_source_mismatch(self) -> None:
        row = queue_row(split.EXILE_UNIT, effect_classes=["ExileTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Exile target permanent with mana value 4 or greater."),
            source_text=(
                "this.getSpellAbility().addEffect(new ExileTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetPermanent());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "exile_target_source_mismatch")

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

    def test_permanent_activated_damage_maps_discard_card_cost(self) -> None:
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
                name="Kris Mage",
                type_line="Creature - Human Spellshaper",
                oracle_text="{R}, {T}, Discard a card: This creature deals 1 damage to any target.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(1),
                    new ManaCostsImpl<>("{R}")
                );
                ability.addCost(new TapSourceCost());
                ability.addCost(new DiscardCardCost());
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
        self.assertEqual(effect["activation_discard_count"], 1)
        self.assertEqual(effect["activation_discard_target"], "any_card")
        self.assertEqual(effect["_activated_rule_effects"][0]["activation_discard_count"], 1)
        self.assertEqual(effect["_activated_rule_effects"][0]["activation_discard_target"], "any_card")

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

    def test_permanent_activated_damage_maps_flash_artifact_tap_self_sacrifice(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="static_and_activated",
            ability_classes=["FlashAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Springjaw Trap",
                type_line="Artifact",
                oracle_text="Flash\n{4}, {T}, Sacrifice Springjaw Trap: It deals 3 damage to any target.",
            ),
            source_text="""
                this.addAbility(FlashAbility.getInstance());
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(3, "it"), new GenericManaCost(4)
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
        self.assertEqual(effect["activated_damage_amount"], 3)
        self.assertEqual(effect["activation_cost_mana"], "{4}")
        self.assertTrue(effect["activated_self_sacrifice_damage"])
        self.assertEqual(effect["keywords"], ["flash"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertTrue(effect["flash"])

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

    def test_permanent_activated_damage_maps_sacrifice_target_cost(self) -> None:
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
                name="Arms Dealer",
                type_line="Creature - Goblin Rogue",
                oracle_text="{1}{R}, Sacrifice a Goblin: Arms Dealer deals 4 damage to target creature.",
            ),
            source_text="""
                FilterControlledPermanent filter = new FilterControlledPermanent("a Goblin");
                filter.add(SubType.GOBLIN.getPredicate());
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(4),
                    new ManaCostsImpl<>("{1}{R}")
                );
                ability.addCost(new SacrificeTargetCost(filter));
                ability.addTarget(new TargetCreaturePermanent());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DAMAGE_SCOPE)
        self.assertEqual(effect["activated_damage_amount"], 4)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["activation_cost_mana"], "{1}{R}")
        self.assertEqual(effect["activation_cost_generic"], 1)
        self.assertEqual(effect["activation_cost_colors"], ["R"])
        self.assertFalse(effect["activation_requires_tap"])
        self.assertFalse(effect["activation_requires_sacrifice"])
        self.assertTrue(effect["activation_requires_sacrifice_target"])
        self.assertEqual(
            effect["activation_sacrifice_cost"],
            {
                "count": 1,
                "target_controller": "self",
                "constraints": {"target_subtypes": ["goblin"]},
            },
        )
        self.assertEqual(effect["_activated_rule_effects"][0]["activation_sacrifice_cost"], effect["activation_sacrifice_cost"])

    def test_permanent_activated_damage_maps_colored_cost_and_creature_sacrifice_target(self) -> None:
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
                name="Scorched Rusalka",
                type_line="Creature - Spirit",
                oracle_text="{R}, Sacrifice a creature: Scorched Rusalka deals 1 damage to target player or planeswalker.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(1),
                    new ColoredManaCost(ColoredManaSymbol.R)
                );
                ability.addCost(new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE));
                ability.addTarget(new TargetPlayerOrPlaneswalker());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "player_or_planeswalker")
        self.assertEqual(effect["activation_cost_mana"], "{R}")
        self.assertEqual(effect["activation_cost_generic"], 0)
        self.assertEqual(effect["activation_cost_colors"], ["R"])
        self.assertTrue(effect["activation_requires_sacrifice_target"])
        self.assertEqual(
            effect["activation_sacrifice_cost"],
            {
                "count": 1,
                "target_controller": "self",
                "constraints": {"card_types": ["creature"]},
            },
        )

    def test_permanent_activated_damage_maps_damaged_this_turn_creature_target(self) -> None:
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
                name="Opportunist",
                type_line="Creature - Human Soldier",
                oracle_text="{T}: This creature deals 1 damage to target creature that was dealt damage this turn.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(new DamageTargetEffect(1), new TapSourceCost());
                ability.addTarget(new TargetPermanent(StaticFilters.FILTER_CREATURE_DAMAGED_THIS_TURN));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DAMAGE_SCOPE)
        self.assertEqual(effect["activated_damage_amount"], 1)
        self.assertEqual(effect["target"], "creature_damaged_this_turn")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "damaged_this_turn": True})
        self.assertEqual(effect["activation_cost_mana"], "{0}")
        self.assertTrue(effect["activation_requires_tap"])

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

    def test_permanent_activated_damage_maps_player_or_planeswalker_target(self) -> None:
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

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "player_or_planeswalker")
        self.assertEqual(effect["target_constraints"], {"scope": "player_or_planeswalker"})
        self.assertEqual(effect["activated_damage_amount"], 1)
        self.assertTrue(effect["activation_requires_tap"])

    def test_permanent_activated_damage_maps_opponent_target(self) -> None:
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
                name="Deadeye Duelist",
                type_line="Creature - Human Pirate",
                oracle_text="{1}, {T}: This creature deals 1 damage to target opponent.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(new DamageTargetEffect(1), new GenericManaCost(1));
                ability.addCost(new TapSourceCost());
                ability.addTarget(new TargetOpponent());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "opponent")
        self.assertEqual(effect["target_constraints"], {"scope": "opponent"})
        self.assertEqual(effect["activation_cost_mana"], "{1}")
        self.assertEqual(effect["activated_damage_amount"], 1)
        self.assertTrue(effect["activation_requires_tap"])

    def test_permanent_activated_damage_maps_player_target(self) -> None:
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
                name="Pyroclastic Elemental",
                type_line="Creature - Elemental",
                oracle_text="{1}{R}{R}: This creature deals 1 damage to target player.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(1), new ManaCostsImpl<>("{1}{R}{R}")
                );
                ability.addTarget(new TargetPlayer());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "player")
        self.assertEqual(effect["target_constraints"], {"scope": "player"})
        self.assertEqual(effect["activation_cost_mana"], "{1}{R}{R}")
        self.assertEqual(effect["activation_cost_generic"], 1)
        self.assertEqual(effect["activation_cost_colors"], ["R", "R"])
        self.assertFalse(effect["activation_requires_tap"])

    def test_permanent_activated_damage_maps_opponent_or_planeswalker_target(self) -> None:
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
                name="Razortip Whip",
                type_line="Artifact",
                oracle_text="{1}, {T}: This artifact deals 1 damage to target opponent or planeswalker.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(new DamageTargetEffect(1), new ManaCostsImpl<>("{1}"));
                ability.addCost(new TapSourceCost());
                ability.addTarget(new TargetOpponentOrPlaneswalker());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "artifact")
        self.assertEqual(effect["target"], "opponent_or_planeswalker")
        self.assertEqual(effect["target_constraints"], {"scope": "opponent_or_planeswalker"})
        self.assertEqual(effect["activated_damage_amount"], 1)
        self.assertTrue(effect["activation_requires_tap"])

    def test_permanent_activated_damage_maps_creature_or_planeswalker_target(self) -> None:
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
                name="Elite Headhunter",
                type_line="Creature - Human Assassin",
                oracle_text=(
                    "{B/R}{B/R}{B/R}, Sacrifice another creature or an artifact: "
                    "This creature deals 2 damage to target creature or planeswalker."
                ),
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(2), new ManaCostsImpl<>("{B/R}{B/R}{B/R}")
                );
                ability.addCost(new SacrificeTargetCost(StaticFilters.FILTER_CONTROLLED_ARTIFACT_OR_OTHER_CREATURE));
                ability.addTarget(new TargetCreatureOrPlaneswalker());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature_or_planeswalker")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature", "planeswalker"]})
        self.assertEqual(effect["activation_cost_mana"], "{B/R}{B/R}{B/R}")
        self.assertEqual(effect["activation_cost_colors"], ["B/R", "B/R", "B/R"])
        self.assertTrue(effect["activation_requires_sacrifice_target"])
        self.assertEqual(
            effect["activation_sacrifice_cost"],
            {
                "count": 1,
                "target_controller": "self",
                "constraints": {"card_types": ["artifact", "creature"], "exclude_source": True},
            },
        )

    def test_permanent_activated_damage_allows_static_keyword_auxiliary(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="activated",
            ability_classes=["FlyingAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Hellkite",
                type_line="Creature - Dragon",
                oracle_text="Flying\n{1}{R}: Fixture Hellkite deals 1 damage to any target.",
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                Ability ability = new SimpleActivatedAbility(
                    new DamageTargetEffect(1),
                    new ManaCostsImpl<>("{1}{R}")
                );
                ability.addTarget(new TargetAnyTarget());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DAMAGE_SCOPE)
        self.assertEqual(effect["activated_damage_amount"], 1)
        self.assertEqual(effect["activation_cost_mana"], "{1}{R}")
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["flying"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertEqual(effect["xmage_ability_classes"], ["FlyingAbility", "SimpleActivatedAbility"])

    def test_permanent_activated_damage_rejects_non_keyword_auxiliary(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="activated",
            ability_classes=["CrewAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Vehicle",
                type_line="Artifact - Vehicle",
                oracle_text="{T}: Fixture Vehicle deals 1 damage to any target.",
            ),
            source_text="""
                this.addAbility(new CrewAbility(2));
                Ability ability = new SimpleActivatedAbility(new DamageTargetEffect(1), new TapSourceCost());
                ability.addTarget(new TargetAnyTarget());
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "not_instant_or_sorcery_spell")

    def test_permanent_activated_damage_maps_flying_creature_target(self) -> None:
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
                name="Centaur Archer",
                type_line="Creature - Centaur Archer",
                oracle_text="{T}: Centaur Archer deals 1 damage to target creature with flying.",
            ),
            source_text="""
                Ability activatedAbility = new SimpleActivatedAbility(new DamageTargetEffect(1), new TapSourceCost());
                activatedAbility.addTarget(new TargetPermanent(StaticFilters.FILTER_CREATURE_FLYING));
                this.addAbility(activatedAbility);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "flying_creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "required_keywords": ["flying"]})
        self.assertEqual(effect["activated_damage_amount"], 1)

    def test_permanent_activated_damage_maps_attacking_flying_creature_target(self) -> None:
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
                name="Femeref Archers",
                type_line="Creature - Human Archer",
                oracle_text="{T}: This creature deals 4 damage to target attacking creature with flying.",
            ),
            source_text="""
                private static final FilterAttackingCreature filter = new FilterAttackingCreature("attacking creature with flying");
                Ability ability = new SimpleActivatedAbility(new DamageTargetEffect(4), new TapSourceCost());
                ability.addTarget(new TargetPermanent(filter));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "attacking_flying_creature")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "combat_state": "attacking", "required_keywords": ["flying"]},
        )
        self.assertEqual(effect["activated_damage_amount"], 4)

    def test_permanent_activated_damage_maps_simple_color_creature_targets(self) -> None:
        fixtures = [
            ("Shauku's Minion", "white", "W", "WHITE", "{B}{R}"),
            ("Slingshot Goblin", "blue", "U", "BLUE", "{R}"),
        ]
        for name, color_word, color_symbol, object_color, cost_text in fixtures:
            with self.subTest(name=name):
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
                        name=name,
                        type_line="Creature - Fixture",
                        oracle_text=f"{cost_text}, {{T}}: This creature deals 2 damage to target {color_word} creature.",
                    ),
                    source_text=f"""
                        private static final FilterCreaturePermanent filter = new FilterCreaturePermanent("{color_word} creature");
                        filter.add(new ColorPredicate(ObjectColor.{object_color}));
                        Ability ability = new SimpleActivatedAbility(new DamageTargetEffect(2), new ManaCostsImpl<>("{cost_text}"));
                        ability.addCost(new TapSourceCost());
                        ability.addTarget(new TargetPermanent(filter));
                        this.addAbility(ability);
                    """,
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["target"], f"{color_word}_creature")
                self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "target_colors": [color_symbol]})
                self.assertEqual(effect["activated_damage_amount"], 2)

    def test_permanent_activated_damage_maps_attacking_or_blocking_creature_target(self) -> None:
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
                name="Crossbow Infantry",
                type_line="Creature - Human Soldier Archer",
                oracle_text="{T}: Crossbow Infantry deals 1 damage to target attacking or blocking creature.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(new DamageTargetEffect(1), new TapSourceCost());
                ability.addTarget(new TargetAttackingOrBlockingCreature());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "attacking_or_blocking_creature")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "combat_state": "attacking_or_blocking"},
        )
        self.assertEqual(effect["activated_damage_amount"], 1)

    def test_permanent_activated_damage_maps_blocking_creature_target(self) -> None:
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
                name="War-Torch Goblin",
                type_line="Creature - Goblin Warrior",
                oracle_text="Sacrifice War-Torch Goblin: It deals 2 damage to target blocking creature.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(new DamageTargetEffect(2), new SacrificeSourceCost());
                ability.addTarget(new TargetBlockingCreature());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "blocking_creature")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "combat_state": "blocking"},
        )
        self.assertEqual(effect["activated_damage_amount"], 2)
        self.assertTrue(effect["activation_requires_sacrifice"])

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

    def test_permanent_activated_destroy_maps_artifact_creature_target(self) -> None:
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
                name="Chandler",
                type_line="Legendary Creature - Human Rogue",
                oracle_text="{R}{R}{R}, {T}: Destroy target artifact creature.",
            ),
            source_text="""
                private static final FilterCreaturePermanent filter =
                    new FilterCreaturePermanent("artifact creature");
                static { filter.add(CardType.ARTIFACT.getPredicate()); }
                Ability ability = new SimpleActivatedAbility(
                    new DestroyTargetEffect(),
                    new ManaCostsImpl<>("{R}{R}{R}")
                );
                ability.addCost(new TapSourceCost());
                ability.addTarget(new TargetPermanent(filter));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["activated_remove_target"], "artifact_creature")
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["artifact", "creature"], "all_card_types_required": True},
        )
        self.assertEqual(effect["activation_cost_mana"], "{R}{R}{R}")
        self.assertTrue(effect["activation_requires_tap"])

    def test_permanent_activated_destroy_maps_filter_permanent_artifact_target(self) -> None:
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
                name="Goblin Replica",
                type_line="Artifact Creature - Goblin",
                oracle_text="{3}{R}, Sacrifice this creature: Destroy target artifact.",
            ),
            source_text="""
                private static final FilterPermanent filter = new FilterPermanent("artifact");
                static { filter.add(CardType.ARTIFACT.getPredicate()); }
                Ability ability = new SimpleActivatedAbility(
                    new DestroyTargetEffect(),
                    new ManaCostsImpl<>("{3}{R}")
                );
                ability.addCost(new SacrificeSourceCost());
                ability.addTarget(new TargetPermanent(filter));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["activated_remove_target"], "artifact")
        self.assertEqual(effect["target"], "artifact")
        self.assertEqual(effect["activation_cost_mana"], "{3}{R}")
        self.assertTrue(effect["activation_requires_sacrifice"])

    def test_permanent_activated_destroy_maps_nonbasic_land_target(self) -> None:
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
                name="Dwarven Miner",
                type_line="Creature - Dwarf",
                oracle_text="{2}{R}, {T}: Destroy target nonbasic land.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DestroyTargetEffect(),
                    new ManaCostsImpl<>("{2}{R}")
                );
                ability.addCost(new TapSourceCost());
                ability.addTarget(new TargetNonBasicLandPermanent());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["activated_remove_target"], "nonbasic_land")
        self.assertEqual(effect["target"], "land")
        self.assertEqual(effect["target_constraints"], {"card_types": ["land"], "exclude_supertypes": ["basic"]})
        self.assertEqual(effect["activation_cost_mana"], "{2}{R}")
        self.assertTrue(effect["activation_requires_tap"])

    def test_permanent_activated_destroy_maps_wall_and_power_filters(self) -> None:
        row = queue_row(
            split.DESTROY_UNIT,
            effect_classes=["DestroyTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        wall_proposal, wall_reason = split.split_row(
            row,
            metadata(
                name="Dwarven Demolition Team",
                type_line="Creature - Dwarf",
                oracle_text="{T}: Destroy target Wall.",
            ),
            source_text="""
                private static final FilterPermanent filter = new FilterPermanent(SubType.WALL);
                Ability ability = new SimpleActivatedAbility(
                    new DestroyTargetEffect(),
                    new TapSourceCost()
                );
                ability.addTarget(new TargetPermanent(filter));
                this.addAbility(ability);
            """,
        )
        self.assertEqual(wall_reason, "selected_exact_scope")
        self.assertEqual(wall_proposal["effect_json"]["activated_remove_target"], "wall_creature")
        self.assertEqual(
            wall_proposal["effect_json"]["target_constraints"],
            {"card_types": ["creature"], "required_subtypes": ["wall"]},
        )

        power_proposal, power_reason = split.split_row(
            row,
            metadata(
                name="Intrepid Hero",
                type_line="Creature - Human Soldier",
                oracle_text="{T}: Destroy target creature with power 4 or greater.",
            ),
            source_text="""
                filter.add(new PowerPredicate(ComparisonType.MORE_THAN,3));
                Ability ability = new SimpleActivatedAbility(
                    new DestroyTargetEffect(),
                    new TapSourceCost()
                );
                ability.addTarget(new TargetPermanent(filter));
                this.addAbility(ability);
            """,
        )
        self.assertEqual(power_reason, "selected_exact_scope")
        self.assertEqual(power_proposal["effect_json"]["activated_remove_target"], "creature_power_4_or_greater")
        self.assertEqual(power_proposal["effect_json"]["target_constraints"], {"card_types": ["creature"], "power_min": 4})

    def test_permanent_activated_destroy_maps_damaged_this_turn_creature_target(self) -> None:
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
                name="Witch's Mist",
                type_line="Enchantment",
                oracle_text="{2}{B}, {T}: Destroy target creature that was dealt damage this turn.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new DestroyTargetEffect(),
                    new ManaCostsImpl<>("{2}{B}")
                );
                ability.addTarget(new TargetPermanent(StaticFilters.FILTER_CREATURE_DAMAGED_THIS_TURN));
                ability.addCost(new TapSourceCost());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_DESTROY_SCOPE)
        self.assertEqual(effect["activated_remove_target"], "creature_damaged_this_turn")
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "damaged_this_turn": True})
        self.assertEqual(effect["activation_cost_mana"], "{2}{B}")
        self.assertTrue(effect["activation_requires_tap"])

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

    def test_creature_etb_dynamic_count_damage_maps_to_triggered_creature_scope(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        fixtures = [
            {
                "name": "Fixture Ravager",
                "oracle": (
                    "When this creature enters, it deals X damage to any target, "
                    "where X is the greatest number of creatures you control that have a creature type in common."
                ),
                "source": (
                    "this.addAbility(new EntersBattlefieldTriggeredAbility("
                    "new DamageTargetEffect(new GreatestSharedCreatureTypeCount())));"
                ),
                "target": "any_target",
                "constraints": {"scope": "any_target"},
                "source_key": "greatest_shared_creature_type_count",
            },
            {
                "name": "Fixture Party Mage",
                "oracle": (
                    "When this creature enters, it deals damage to target creature an opponent controls "
                    "equal to the number of creatures in your party."
                ),
                "source": (
                    "Ability ability = new EntersBattlefieldTriggeredAbility("
                    "new DamageTargetEffect(PartyCount.instance));"
                    "ability.addTarget(new TargetCreaturePermanent());"
                    "this.addAbility(ability);"
                ),
                "target": "creature",
                "target_controller": "opponent",
                "constraints": {"card_types": ["creature"], "controller_scope": "opponent"},
                "source_key": "party_count",
            },
            {
                "name": "Fixture Chromatic",
                "oracle": (
                    "When this creature enters, it deals damage to target opponent equal to "
                    "the number of colors among permanents you control."
                ),
                "source": (
                    "Ability ability = new EntersBattlefieldTriggeredAbility("
                    "new DamageTargetEffect(ColorsAmongControlledPermanentsCount.instance));"
                    "ability.addTarget(new TargetOpponent());"
                    "this.addAbility(ability);"
                ),
                "target": "opponent",
                "constraints": {"scope": "opponent"},
                "source_key": "colors_among_permanents_you_control",
            },
            {
                "name": "Fixture Chroma",
                "oracle": (
                    "When this creature enters, it deals damage to target player equal to the number "
                    "of red mana symbols in the mana costs of permanents you control."
                ),
                "source": (
                    "Ability ability = new EntersBattlefieldTriggeredAbility("
                    "new DamageTargetEffect(new ChromaCount(ManaType.RED)));"
                    "ability.addTarget(new TargetPlayer());"
                    "this.addAbility(ability);"
                ),
                "target": "player",
                "constraints": {"scope": "player"},
                "source_key": "controlled_permanents_mana_symbol_count",
                "mana_symbol_count_color": "R",
            },
        ]

        for fixture in fixtures:
            with self.subTest(card=fixture["name"]):
                proposal, reason = split.split_row(
                    row,
                    metadata(
                        name=fixture["name"],
                        type_line="Creature - Giant Wizard",
                        oracle_text=fixture["oracle"],
                    ),
                    source_text=fixture["source"],
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["effect"], "creature")
                self.assertEqual(effect["battle_model_scope"], split.ETB_DYNAMIC_COUNT_DAMAGE_CREATURE_SCOPE)
                self.assertTrue(effect["etb_dynamic_damage"])
                self.assertEqual(effect["etb_damage_target"], fixture["target"])
                self.assertEqual(effect["target"], fixture["target"])
                self.assertEqual(effect["target_constraints"], fixture["constraints"])
                self.assertEqual(effect["damage_amount_source"], fixture["source_key"])
                self.assertEqual(effect["damage_base_amount"], 0)
                self.assertEqual(effect["damage_per_count"], 1)
                if "target_controller" in fixture:
                    self.assertEqual(effect["target_controller"], fixture["target_controller"])
                if "mana_symbol_count_color" in fixture:
                    self.assertEqual(effect["mana_symbol_count_color"], fixture["mana_symbol_count_color"])

    def test_creature_etb_damage_maps_restricted_flying_target(self) -> None:
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
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new DamageTargetEffect(4), true);"
                "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_CREATURE_FLYING));"
                "this.addAbility(ability);"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ETB_DAMAGE_CREATURE_SCOPE)
        self.assertEqual(effect["etb_damage_amount"], 4)
        self.assertEqual(effect["etb_damage_target"], "flying_creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "required_keywords": ["flying"]})

    def test_creature_etb_damage_maps_self_controlled_creature_target(self) -> None:
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
                name="Fixture Moloch",
                type_line="Creature - Lizard",
                oracle_text="When this creature enters, it deals 3 damage to target creature you control.",
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility(new DamageTargetEffect(3));"
                "ability.addTarget(new TargetControlledCreaturePermanent());"
                "this.addAbility(ability);"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_damage_amount"], 3)
        self.assertEqual(effect["etb_damage_target"], "creature")
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "controller_scope": "self"})

    def test_creature_etb_damage_maps_damaged_opponent_creature_target(self) -> None:
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
                name="Fixture Boltcaster",
                type_line="Creature - Human Wizard",
                oracle_text=(
                    "When this creature enters, it deals 5 damage to target creature "
                    "an opponent controls that was dealt damage this turn."
                ),
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility(new DamageTargetEffect(5));"
                "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_OPPONENTS_CREATURE_DAMAGED_THIS_TURN));"
                "this.addAbility(ability);"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_damage_amount"], 5)
        self.assertEqual(effect["etb_damage_target"], "creature")
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_controller"], "opponent")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "controller_scope": "opponent", "damaged_this_turn": True},
        )

    def test_creature_etb_damage_maps_player_or_planeswalker_target(self) -> None:
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
                name="Fixture Firebeast",
                type_line="Creature - Elemental Ox",
                oracle_text="When this creature enters, it deals 4 damage to target player or planeswalker.",
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility(new DamageTargetEffect(4));"
                "ability.addTarget(new TargetPlayerOrPlaneswalker());"
                "this.addAbility(ability);"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_damage_amount"], 4)
        self.assertEqual(effect["etb_damage_target"], "player_or_planeswalker")
        self.assertEqual(effect["target_constraints"], {"scope": "player_or_planeswalker"})

    def test_creature_dies_damage_maps_any_target_scope(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Myr",
                type_line="Artifact Creature - Myr",
                oracle_text="When Fixture Myr dies, it deals 2 damage to any target.",
            ),
            source_text="""
                Ability ability = new DiesSourceTriggeredAbility(new DamageTargetEffect(2, "it"), false);
                ability.addTarget(new TargetAnyTarget());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DIES_DAMAGE_CREATURE_SCOPE)
        self.assertEqual(effect["dies_damage_amount"], 2)
        self.assertEqual(effect["dies_damage_target"], "any_target")
        self.assertEqual(effect["target_constraints"], {"scope": "any_target"})

    def test_creature_dies_damage_maps_creature_or_planeswalker_filter_scope(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Careless Fixture",
                type_line="Creature - Satyr Shaman",
                oracle_text=(
                    "When Careless Fixture dies, it deals 2 damage to target creature "
                    "or planeswalker an opponent controls."
                ),
            ),
            source_text="""
                private static final FilterPermanent filter
                        = new FilterPermanent("creature or planeswalker an opponent controls");
                static {
                    filter.add(TargetController.OPPONENT.getControllerPredicate());
                    filter.add(Predicates.or(
                            CardType.CREATURE.getPredicate(),
                            CardType.PLANESWALKER.getPredicate()
                    ));
                }
                Ability ability = new DiesSourceTriggeredAbility(new DamageTargetEffect(2, "it"));
                ability.addTarget(new TargetPermanent(filter));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["dies_damage_target"], "creature_or_planeswalker")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature", "planeswalker"]})

    def test_creature_dies_damage_preserves_optional_trigger(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Arsonist",
                type_line="Creature - Goblin Shaman",
                oracle_text="When Fixture Arsonist dies, you may have it deal 1 damage to any target.",
            ),
            source_text="""
                Ability ability = new DiesSourceTriggeredAbility(
                    new DamageTargetEffect(1).setText("it deal 1 damage to any target"),
                    true
                );
                ability.addTarget(new TargetAnyTarget());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertTrue(proposal["effect_json"]["dies_damage_optional"])

    def test_creature_dies_damage_blocks_variable_amount(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Blazing Fixture",
                type_line="Creature - Elemental",
                oracle_text=(
                    "When Blazing Fixture dies, it deals X damage to target creature, "
                    "where X is 3 plus the amount of damage dealt to it this turn."
                ),
            ),
            source_text="""
                Ability ability = new DiesSourceTriggeredAbility(
                    new DamageTargetEffect(BlazingFixtureCount.instance),
                    false
                );
                ability.addTarget(new TargetCreaturePermanent());
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "dies_damage_amount_not_fixed")

    def test_creature_dies_damage_blocks_source_oracle_target_mismatch(self) -> None:
        row = queue_row(
            split.DAMAGE_UNIT,
            effect_classes=["DamageTargetEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Firefiend",
                type_line="Creature - Spirit",
                oracle_text="When Fixture Firefiend dies, it deals 2 damage to any target.",
            ),
            source_text="""
                Ability ability = new DiesSourceTriggeredAbility(new DamageTargetEffect(2), false);
                ability.addTarget(new TargetCreaturePermanent());
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "dies_damage_target_source_oracle_mismatch")

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

    def test_destroy_target_spell_maps_color_and_type_restricted_targets(self) -> None:
        cases = [
            (
                "Destroy target noncreature permanent.",
                "StaticFilters.FILTER_PERMANENT_NON_CREATURE",
                "permanent",
                {"card_types": ["permanent"], "exclude_card_types": ["creature"]},
            ),
            (
                "Destroy target noncreature artifact.",
                'new FilterArtifactPermanent("noncreature artifact")',
                "artifact",
                {"card_types": ["artifact"], "exclude_card_types": ["creature"]},
            ),
            (
                "Destroy target nonblack creature. It can't be regenerated.",
                "FILTER_PERMANENT_CREATURE_NON_BLACK",
                "creature",
                {"card_types": ["creature"], "exclude_colors": ["B"]},
            ),
            (
                "Destroy target black creature.",
                'new FilterCreaturePermanent("black creature")',
                "creature",
                {"card_types": ["creature"], "target_colors": ["B"]},
            ),
            (
                "Destroy target green or white creature.",
                'new FilterCreaturePermanent("green or white creature")',
                "creature",
                {"card_types": ["creature"], "target_colors": ["G", "W"]},
            ),
            (
                "Destroy target nonartifact creature.",
                'new FilterCreaturePermanent("nonartifact creature")',
                "creature",
                {"card_types": ["creature"], "exclude_card_types": ["artifact"]},
            ),
            (
                "Destroy target legendary creature.",
                'new FilterCreaturePermanent("legendary creature")',
                "creature",
                {"card_types": ["creature"], "required_supertypes": ["legendary"]},
            ),
            (
                "Destroy target nonwhite permanent.",
                'new FilterPermanent("nonwhite permanent")',
                "permanent",
                {"card_types": ["permanent"], "exclude_colors": ["W"]},
            ),
            (
                "Destroy target nonartifact, nonblack creature. It can't be regenerated.",
                'new FilterCreaturePermanent("nonartifact, nonblack creature")',
                "creature",
                {"card_types": ["creature"], "exclude_card_types": ["artifact"], "exclude_colors": ["B"]},
            ),
            (
                "Destroy target monocolored creature.",
                'new FilterCreaturePermanent("monocolored creature")',
                "creature",
                {"card_types": ["creature"], "color_count_exact": 1},
            ),
        ]
        for oracle, source_filter, target, constraints in cases:
            with self.subTest(oracle=oracle):
                row = queue_row(split.DESTROY_UNIT, effect_classes=["DestroyTargetEffect"])
                proposal, reason = split.split_row(
                    row,
                    metadata(oracle_text=oracle),
                    source_text=(
                        f"{source_filter};"
                        "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                        "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
                    ),
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["battle_model_scope"], split.DESTROY_SCOPE)
                self.assertEqual(effect["target"], target)
                self.assertEqual(effect["target_constraints"], constraints)

    def test_destroy_target_spell_maps_extended_static_target_filters(self) -> None:
        cases = [
            (
                "Destroy target nonlegendary creature.",
                'new FilterCreaturePermanent("nonlegendary creature"); Predicates.not(SuperType.LEGENDARY.getPredicate());',
                "creature",
                {"card_types": ["creature"], "exclude_supertypes": ["legendary"]},
            ),
            (
                "Destroy target nonsnow creature.",
                'new FilterCreaturePermanent("nonsnow creature"); Predicates.not(SuperType.SNOW.getPredicate());',
                "creature",
                {"card_types": ["creature"], "exclude_supertypes": ["snow"]},
            ),
            (
                "Destroy target non-Spirit creature. It can't be regenerated.",
                'new FilterCreaturePermanent("non-Spirit creature"); Predicates.not(SubType.SPIRIT.getPredicate());',
                "creature",
                {"card_types": ["creature"], "exclude_subtypes": ["spirit"]},
            ),
            (
                "Destroy target non-Angel, non-Demon, non-Devil, non-Dragon creature.",
                (
                    'new FilterCreaturePermanent("non-Angel, non-Demon, non-Devil, non-Dragon creature");'
                    "Predicates.not(SubType.ANGEL.getPredicate());"
                    "Predicates.not(SubType.DEMON.getPredicate());"
                    "Predicates.not(SubType.DEVIL.getPredicate());"
                    "Predicates.not(SubType.DRAGON.getPredicate());"
                ),
                "creature",
                {"card_types": ["creature"], "exclude_subtypes": ["angel", "demon", "devil", "dragon"]},
            ),
            (
                "Destroy target Human creature.",
                'new FilterCreaturePermanent("Human creature"); SubType.HUMAN.getPredicate();',
                "creature",
                {"card_types": ["creature"], "required_subtypes": ["human"]},
            ),
            (
                "Destroy target Spirit or enchantment.",
                'new FilterPermanent("Spirit or enchantment"); SubType.SPIRIT.getPredicate(); CardType.ENCHANTMENT.getPredicate();',
                "permanent",
                {
                    "any_of": [
                        {"card_types": ["creature"], "required_subtypes": ["spirit"]},
                        {"card_types": ["enchantment"]},
                    ]
                },
            ),
            (
                "Destroy target attacking or blocking creature with power 3 or less.",
                "new FilterAttackingOrBlockingCreature(); new PowerPredicate(ComparisonType.FEWER_THAN, 4);",
                "creature",
                {"card_types": ["creature"], "combat_state": "attacking_or_blocking", "power_max": 3},
            ),
            (
                "Destroy target attacking creature with power 3 or less.",
                "new FilterAttackingCreature(); new PowerPredicate(ComparisonType.FEWER_THAN, 4);",
                "creature",
                {"card_types": ["creature"], "combat_state": "attacking", "power_max": 3},
            ),
        ]
        for oracle, source_filter, target, constraints in cases:
            with self.subTest(oracle=oracle):
                row = queue_row(split.DESTROY_UNIT, effect_classes=["DestroyTargetEffect"])
                proposal, reason = split.split_row(
                    row,
                    metadata(oracle_text=oracle),
                    source_text=(
                        f"{source_filter};"
                        "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                        "this.getSpellAbility().addTarget(new TargetPermanent(filter));"
                    ),
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["battle_model_scope"], split.DESTROY_SCOPE)
                self.assertEqual(effect["target"], target)
                self.assertEqual(effect["target_constraints"], constraints)

    def test_destroy_target_spell_blocks_color_restricted_source_mismatch(self) -> None:
        row = queue_row(split.DESTROY_UNIT, effect_classes=["DestroyTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy target black creature."),
            source_text=(
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "destroy_target_source_mismatch")

    def test_destroy_target_spell_accepts_creature_sacrifice_additional_cost(self) -> None:
        row = queue_row(split.DESTROY_UNIT, effect_classes=["DestroyTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="As an additional cost to cast this spell, sacrifice a creature. Destroy target creature."),
            source_text=(
                "this.getSpellAbility().addCost(new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DESTROY_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["additional_cost"], "sacrifice_creature")
        self.assertTrue(effect["requires_sacrifice_creature"])
        self.assertEqual(effect["xmage_additional_cost_class"], "SacrificeTargetCost")
        self.assertEqual(effect["xmage_additional_cost_target"], "creature")

    def test_destroy_target_spell_blocks_or_additional_cost(self) -> None:
        row = queue_row(split.DESTROY_UNIT, effect_classes=["DestroyTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "As an additional cost to cast this spell, sacrifice a creature or discard a card. "
                    "Destroy target creature."
                )
            ),
            source_text=(
                "this.getSpellAbility().addCost(new OrCost("
                "\"sacrifice a creature or discard a card\", "
                "new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE), "
                "new DiscardCardCost()));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
                "this.getSpellAbility().addEffect(new DestroyTargetEffect());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "destroy_additional_cost_not_supported")

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

    def test_creature_etb_fixed_mana_maps_to_triggered_ramp_permanent(self) -> None:
        row = queue_row(
            split.RAMP_CREATURE_UNIT,
            effect_classes=["BasicManaEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Burning-Tree Emissary",
                type_line="Creature - Human Shaman",
                oracle_text="When this creature enters, add {R}{G}.",
            ),
            source_text=(
                "this.addAbility(new EntersBattlefieldTriggeredAbility("
                "new BasicManaEffect(new Mana(0, 0, 0, 1, 1, 0, 0, 0))));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "ramp_permanent")
        self.assertEqual(effect["battle_model_scope"], split.ETB_FIXED_MANA_CREATURE_SCOPE)
        self.assertEqual(effect["trigger"], "enters_battlefield")
        self.assertEqual(effect["trigger_effect"], "add_mana")
        self.assertFalse(effect["is_mana_source"])
        self.assertEqual(effect["etb_mana_produced"], 2)
        self.assertEqual(effect["etb_produces"], "RG")
        self.assertEqual(effect["etb_produced_mana_symbols"], ["R", "G"])

    def test_creature_etb_fixed_mana_accepts_colored_mana_symbol_constructor(self) -> None:
        row = queue_row(
            split.RAMP_CREATURE_UNIT,
            effect_classes=["BasicManaEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Akki Rockspeaker",
                type_line="Creature - Goblin Shaman",
                oracle_text="When this creature enters, add {R}.",
            ),
            source_text=(
                "this.addAbility(new EntersBattlefieldTriggeredAbility("
                "new BasicManaEffect(new Mana(ColoredManaSymbol.R))));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ETB_FIXED_MANA_CREATURE_SCOPE)
        self.assertEqual(effect["etb_mana_produced"], 1)
        self.assertEqual(effect["etb_produced_mana_symbols"], ["R"])

    def test_creature_etb_conditional_mana_stays_blocked(self) -> None:
        row = queue_row(
            split.RAMP_CREATURE_UNIT,
            effect_classes=["BasicManaEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Coal Stoker",
                type_line="Creature - Elemental",
                oracle_text=(
                    "When this creature enters, if you cast it from your hand, "
                    "add {R}{R}{R}."
                ),
            ),
            source_text=(
                "this.addAbility(new EntersBattlefieldTriggeredAbility("
                "new BasicManaEffect(Mana.RedMana(3)))"
                ".withInterveningIf(CastFromHandSourcePermanentCondition.instance));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_mana_oracle_not_simple_fixed")

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

    def test_simple_creature_multi_symbol_mana_source_maps_fixed_symbols(self) -> None:
        row = queue_row(
            split.RAMP_CREATURE_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["SimpleManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Gyre Engineer",
                type_line="Creature - Vedalken Artificer",
                oracle_text="{T}: Add {G}{U}.",
            ),
            source_text=(
                "this.addAbility(new SimpleManaAbility(Zone.BATTLEFIELD, "
                "new Mana(0, 1, 0, 0, 1, 0, 0, 0), new TapSourceCost()));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.MANA_SCOPE)
        self.assertEqual(effect["produces"], "GU")
        self.assertEqual(effect["mana_produced"], 2)
        self.assertEqual(effect["produced_mana_symbols"], ["G", "U"])
        self.assertEqual(effect["permanent_type"], "creature")

    def test_simple_colorless_mana_source_ignores_parenthetical_reminder(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["ColorlessManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Hedron Crawler",
                type_line="Artifact Creature - Construct",
                oracle_text="{T}: Add {C}. ({C} represents colorless mana.)",
            ),
            source_text="this.addAbility(new ColorlessManaAbility());",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.MANA_SCOPE)
        self.assertEqual(effect["produces"], "C")
        self.assertEqual(effect["produced_mana_symbols"], ["C"])

    def test_simple_mana_source_with_enters_tapped_auxiliary_maps(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["BlackManaAbility", "EntersBattlefieldTappedAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Charcoal Diamond",
                type_line="Artifact",
                oracle_text="This artifact enters tapped.\n{T}: Add {B}.",
            ),
            source_text=(
                "this.addAbility(new EntersBattlefieldTappedAbility());"
                "this.addAbility(new BlackManaAbility());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["produces"], "B")
        self.assertTrue(effect["enters_tapped"])

    def test_simple_mana_source_with_static_keyword_auxiliary_maps(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["AnyColorManaAbility", "IndestructibleAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Darksteel Ingot",
                type_line="Artifact",
                oracle_text=(
                    "Indestructible (Effects that say \"destroy\" don't destroy this artifact.)\n"
                    "{T}: Add one mana of any color."
                ),
            ),
            source_text=(
                "this.addAbility(IndestructibleAbility.getInstance());"
                "this.addAbility(new AnyColorManaAbility());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["produces"], "WUBRG")
        self.assertEqual(effect["keywords"], ["indestructible"])

    def test_simple_mana_source_with_activated_self_sacrifice_draw_maps(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="activated",
            ability_classes=[
                "BlackManaAbility",
                "GreenManaAbility",
                "SimpleActivatedAbility",
                "WhiteManaAbility",
            ],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Abzan Banner",
                type_line="Artifact",
                oracle_text=(
                    "{T}: Add {W}, {B}, or {G}.\n"
                    "{W}{B}{G}, {T}, Sacrifice this artifact: Draw a card."
                ),
            ),
            source_text=(
                "this.addAbility(new WhiteManaAbility());"
                "this.addAbility(new BlackManaAbility());"
                "this.addAbility(new GreenManaAbility());"
                "Ability ability = new SimpleActivatedAbility("
                "new DrawCardSourceControllerEffect(1), new ManaCostsImpl<>(\"{W}{B}{G}\"));"
                "ability.addCost(new TapSourceCost());"
                "ability.addCost(new SacrificeSourceCost());"
                "this.addAbility(ability);"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "ramp_permanent")
        self.assertEqual(effect["battle_model_scope"], split.MANA_WITH_ACTIVATED_DRAW_SCOPE)
        self.assertTrue(effect["is_mana_source"])
        self.assertEqual(effect["produces"], "WBG")
        self.assertEqual(effect["mana_produced"], 1)
        self.assertEqual(effect["ability_kind"], "mana_and_activated")
        self.assertTrue(effect["activated_draw"])
        self.assertEqual(effect["activated_draw_count"], 1)
        self.assertEqual(effect["draw_on_self_sacrifice"], 1)
        self.assertEqual(effect["activation_cost_mana"], "{W}{B}{G}")
        self.assertEqual(effect["activation_cost_colors"], ["W", "B", "G"])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])
        self.assertEqual(effect["xmage_mana_ability_classes"], ["BlackManaAbility", "GreenManaAbility", "WhiteManaAbility"])
        self.assertEqual(effect["_activated_rule_effects"][0]["battle_model_scope"], split.PERMANENT_ACTIVATED_DRAW_SCOPE)

    def test_simple_mana_source_with_etb_draw_maps(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["AnyColorManaAbility", "EntersBattlefieldTriggeredAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Prophetic Prism",
                type_line="Artifact",
                oracle_text=(
                    "When this artifact enters, draw a card.\n"
                    "{1}, {T}: Add one mana of any color."
                ),
            ),
            source_text=(
                "this.addAbility(new EntersBattlefieldTriggeredAbility("
                "new DrawCardSourceControllerEffect(1)));"
                "Ability ability = new AnyColorManaAbility(new GenericManaCost(1));"
                "ability.addCost(new TapSourceCost());"
                "this.addAbility(ability);"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.MANA_WITH_ETB_DRAW_SCOPE)
        self.assertTrue(effect["is_mana_source"])
        self.assertEqual(effect["produces"], "WUBRG")
        self.assertEqual(effect["activation_mana_cost"], "{1}")
        self.assertTrue(effect["mana_activation_requires_tap"])
        self.assertEqual(effect["etb_draw_count"], 1)
        self.assertEqual(effect["ability_kind"], "mana_and_triggered")

    def test_mana_source_with_no_tap_activation_cost_maps(self) -> None:
        row = queue_row(
            split.RAMP_CREATURE_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["SimpleManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Agent of Stromgald",
                type_line="Creature - Human Knight",
                oracle_text="{R}: Add {B}.",
            ),
            source_text=(
                "this.addAbility(new SimpleManaAbility(Zone.BATTLEFIELD, "
                "Mana.BlackMana(1), new ManaCostsImpl<>(\"{R}\")));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.MANA_SCOPE)
        self.assertEqual(effect["produces"], "B")
        self.assertEqual(effect["produced_mana_symbols"], ["B"])
        self.assertEqual(effect["activation_mana_cost"], "{R}")
        self.assertFalse(effect["mana_activation_requires_tap"])

    def test_mana_source_with_etb_draw_and_food_ability_stays_blocked(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=[
                "AnyColorManaAbility",
                "EntersBattlefieldTriggeredAbility",
                "FoodAbility",
            ],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Golden Egg",
                type_line="Artifact - Food",
                oracle_text=(
                    "When this artifact enters, draw a card.\n"
                    "{1}, {T}, Sacrifice this artifact: Add one mana of any color.\n"
                    "{2}, {T}, Sacrifice this artifact: You gain 3 life."
                ),
            ),
            source_text=(
                "this.addAbility(new EntersBattlefieldTriggeredAbility("
                "new DrawCardSourceControllerEffect(1)));"
                "Ability ability = new AnyColorManaAbility(new GenericManaCost(1));"
                "ability.addCost(new TapSourceCost());"
                "ability.addCost(new SacrificeSourceCost());"
                "this.addAbility(ability);"
                "this.addAbility(new FoodAbility());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "mana_source_auxiliary_ability_not_supported")

    def test_simple_mana_source_with_hybrid_activated_draw_cost_maps(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="activated",
            ability_classes=["BlueManaAbility", "SimpleActivatedAbility", "WhiteManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Azorius Locket",
                type_line="Artifact",
                oracle_text=(
                    "{T}: Add {W} or {U}.\n"
                    "{W/U}{W/U}{W/U}{W/U}, {T}, Sacrifice this artifact: Draw two cards."
                ),
            ),
            source_text=(
                "this.addAbility(new WhiteManaAbility());"
                "this.addAbility(new BlueManaAbility());"
                "Ability ability = new SimpleActivatedAbility("
                "new DrawCardSourceControllerEffect(2), new ManaCostsImpl<>(\"{W/U}{W/U}{W/U}{W/U}\"));"
                "ability.addCost(new TapSourceCost());"
                "ability.addCost(new SacrificeSourceCost());"
                "this.addAbility(ability);"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.MANA_WITH_ACTIVATED_DRAW_SCOPE)
        self.assertEqual(effect["effect"], "ramp_permanent")
        self.assertEqual(effect["produces"], "WU")
        self.assertEqual(effect["mana_produced"], 1)
        self.assertEqual(effect["activated_draw_count"], 2)
        self.assertEqual(effect["draw_on_self_sacrifice"], 2)
        self.assertEqual(effect["activation_cost_mana"], "{W/U}{W/U}{W/U}{W/U}")
        self.assertEqual(effect["activation_cost_generic"], 0)
        self.assertEqual(effect["activation_cost_colors"], ["W/U", "W/U", "W/U", "W/U"])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])
        self.assertTrue(effect["activated_self_sacrifice_draw"])
        self.assertEqual(effect["_activated_rule_effects"][0]["activation_cost_mana"], "{W/U}{W/U}{W/U}{W/U}")

    def test_simple_mana_source_with_unsupported_auxiliary_stays_blocked(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["AnyColorManaAbility", "CrewAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Cultivator's Caravan",
                type_line="Artifact - Vehicle",
                oracle_text=(
                    "{T}: Add one mana of any color.\n"
                    "Crew 3 (Tap any number of creatures you control with total power 3 or more: "
                    "This Vehicle becomes an artifact creature until end of turn.)"
                ),
            ),
            source_text=(
                "this.addAbility(new AnyColorManaAbility());"
                "this.addAbility(new CrewAbility(3));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "mana_source_auxiliary_ability_not_supported")

    def test_simple_creature_mana_source_with_activation_cost_maps_fixed_symbols(self) -> None:
        row = queue_row(
            split.RAMP_CREATURE_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["SimpleManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Apprentice Wizard",
                type_line="Creature - Human Wizard",
                oracle_text="{U}, {T}: Add {C}{C}{C}.",
            ),
            source_text=(
                "Ability ability = new SimpleManaAbility(Zone.BATTLEFIELD, "
                "Mana.ColorlessMana(3), new ManaCostsImpl<>(\"{U}\"));"
                "ability.addCost(new TapSourceCost());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["produces"], "C")
        self.assertEqual(effect["mana_produced"], 3)
        self.assertEqual(effect["produced_mana_symbols"], ["C", "C", "C"])
        self.assertEqual(effect["activation_mana_cost"], "{U}")

    def test_simple_creature_sacrifice_mana_source_maps_contextual_only(self) -> None:
        row = queue_row(
            split.RAMP_CREATURE_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["SimpleManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Blood Pet",
                type_line="Creature - Thrull",
                oracle_text="Sacrifice Blood Pet: Add {B}.",
            ),
            source_text=(
                "this.addAbility(new SimpleManaAbility(Zone.BATTLEFIELD, "
                "Mana.BlackMana(1), new SacrificeSourceCost()));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.SELF_SACRIFICE_MANA_SOURCE_SCOPE)
        self.assertTrue(effect["is_mana_source"])
        self.assertTrue(effect["mana_source_contextual_only"])
        self.assertTrue(effect["mana_activation_requires_sacrifice"])
        self.assertFalse(effect["mana_activation_requires_tap"])
        self.assertEqual(effect["produces"], "B")
        self.assertEqual(effect["produced_mana_symbols"], ["B"])
        self.assertEqual(effect["permanent_type"], "creature")

    def test_any_color_creature_sacrifice_mana_source_maps_contextual_only(self) -> None:
        row = queue_row(
            split.RAMP_CREATURE_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["AnyColorManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Wild Cantor",
                type_line="Creature - Human Druid",
                oracle_text="({R/G} can be paid with either {R} or {G}.)\nSacrifice this creature: Add one mana of any color.",
            ),
            source_text=(
                "this.addAbility(new AnyColorManaAbility(new SacrificeSourceCost()));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.SELF_SACRIFICE_MANA_SOURCE_SCOPE)
        self.assertTrue(effect["mana_source_contextual_only"])
        self.assertEqual(effect["produces"], "WUBRG")
        self.assertEqual(effect["mana_produced"], 1)
        self.assertNotIn("produced_mana_symbols", effect)
        self.assertEqual(effect["xmage_ability_class"], "AnyColorManaAbility")

    def test_simple_creature_tap_sacrifice_mana_source_maps(self) -> None:
        row = queue_row(
            split.RAMP_CREATURE_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["SimpleManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Basal Thrull",
                type_line="Creature - Thrull",
                oracle_text="{T}, Sacrifice Basal Thrull: Add {B}{B}.",
            ),
            source_text=(
                "Ability ability = new SimpleManaAbility(Zone.BATTLEFIELD, "
                "Mana.BlackMana(2), new TapSourceCost());"
                "ability.addCost(new SacrificeSourceCost());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.SELF_SACRIFICE_MANA_SOURCE_SCOPE)
        self.assertTrue(effect["mana_activation_requires_tap"])
        self.assertEqual(effect["mana_produced"], 2)
        self.assertEqual(effect["produced_mana_symbols"], ["B", "B"])

    def test_simple_artifact_sacrifice_mana_source_with_activation_cost_maps(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["SimpleManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Coal Golem",
                type_line="Artifact Creature - Golem",
                oracle_text="{3}, Sacrifice Coal Golem: Add {R}{R}{R}.",
            ),
            source_text=(
                "Ability ability = new SimpleManaAbility(Zone.BATTLEFIELD, "
                "Mana.RedMana(3), new GenericManaCost(3));"
                "ability.addCost(new SacrificeSourceCost());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.SELF_SACRIFICE_MANA_SOURCE_SCOPE)
        self.assertEqual(effect["activation_mana_cost"], "{3}")
        self.assertEqual(effect["mana_produced"], 3)
        self.assertEqual(effect["produced_mana_symbols"], ["R", "R", "R"])

    def test_simple_artifact_sacrifice_any_one_color_with_activation_cost_maps(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=["AddManaOfAnyColorEffect"],
            ability_kind="activated",
            ability_classes=["SimpleManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Implements of Sacrifice",
                type_line="Artifact",
                oracle_text="{1}, {T}, Sacrifice this artifact: Add two mana of any one color.",
            ),
            source_text=(
                "SimpleManaAbility ability = new SimpleManaAbility("
                "Zone.BATTLEFIELD, new AddManaOfAnyColorEffect(2), new ManaCostsImpl<>(\"{1}\"));"
                "ability.addCost(new TapSourceCost());"
                "ability.addCost(new SacrificeSourceCost());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.SELF_SACRIFICE_MANA_SOURCE_SCOPE)
        self.assertEqual(effect["produces"], "WUBRG")
        self.assertEqual(effect["mana_produced"], 2)
        self.assertEqual(effect["activation_mana_cost"], "{1}")
        self.assertTrue(effect["mana_activation_requires_tap"])
        self.assertTrue(effect["mana_activation_requires_sacrifice"])
        self.assertNotIn("produced_mana_symbols", effect)
        self.assertEqual(effect["xmage_effect_classes"], ["AddManaOfAnyColorEffect"])

    def test_simple_artifact_sacrifice_mana_source_maps_composite_mana_constructor(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["SimpleManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Composite Golem",
                type_line="Artifact Creature - Golem",
                oracle_text="Sacrifice Composite Golem: Add {W}{U}{B}{R}{G}.",
            ),
            source_text=(
                "this.addAbility(new SimpleManaAbility(Zone.BATTLEFIELD, "
                "new Mana(1, 1, 1, 1, 1, 0, 0, 0), new SacrificeSourceCost()));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.SELF_SACRIFICE_MANA_SOURCE_SCOPE)
        self.assertEqual(effect["produces"], "WUBRG")
        self.assertEqual(effect["produced_mana_symbols"], ["W", "U", "B", "R", "G"])
        self.assertEqual(effect["mana_produced"], 5)

    def test_simple_artifact_sacrifice_mana_source_accepts_source_constructor_color_order(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["SimpleManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Rith's Attendant",
                type_line="Artifact Creature - Golem",
                oracle_text="{1}, Sacrifice Rith's Attendant: Add {R}{G}{W}.",
            ),
            source_text=(
                "Ability ability = new SimpleManaAbility(Zone.BATTLEFIELD, "
                "new Mana(1, 0, 0, 1, 1, 0, 0, 0), new ManaCostsImpl<>(\"{1}\"));"
                "ability.addCost(new SacrificeSourceCost());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.SELF_SACRIFICE_MANA_SOURCE_SCOPE)
        self.assertEqual(effect["produced_mana_symbols"], ["R", "G", "W"])
        self.assertEqual(effect["produces"], "RGW")

    def test_tap_and_self_sacrifice_mana_source_maps_combined_scope(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=[],
            ability_kind="activated",
            ability_classes=["BlueManaAbility", "SimpleManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Eye of Ramos",
                type_line="Artifact",
                oracle_text="{T}: Add {U}.\nSacrifice Eye of Ramos: Add {U}.",
            ),
            source_text=(
                "this.addAbility(new BlueManaAbility());"
                "this.addAbility(new SimpleManaAbility(Zone.BATTLEFIELD, "
                "Mana.BlueMana(1), new SacrificeSourceCost()));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.TAP_AND_SELF_SACRIFICE_MANA_SOURCE_SCOPE)
        self.assertTrue(effect["is_mana_source"])
        self.assertEqual(effect["produces"], "U")
        self.assertEqual(effect["mana_produced"], 1)
        self.assertEqual(effect["produced_mana_symbols"], ["U"])
        self.assertTrue(effect["mana_activation_requires_tap"])
        self.assertTrue(effect["sacrifice_mana_source_contextual_only"])
        self.assertEqual(effect["sacrifice_produces"], "U")
        self.assertEqual(effect["sacrifice_mana_produced"], 1)
        self.assertEqual(effect["sacrifice_produced_mana_symbols"], ["U"])
        self.assertFalse(effect["sacrifice_mana_activation_requires_tap"])
        self.assertTrue(effect["sacrifice_mana_activation_requires_sacrifice"])
        self.assertEqual(effect["ability_kind"], "mana_and_sacrifice_mana")

    def test_etb_draw_sacrifice_mana_source_stays_out_of_tap_sacrifice_scope(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "SimpleManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Kaleidostone",
                type_line="Artifact",
                oracle_text=(
                    "When this artifact enters, draw a card.\n"
                    "{5}, {T}, Sacrifice this artifact: Add {W}{U}{B}{R}{G}."
                ),
            ),
            source_text=(
                "this.addAbility(new EntersBattlefieldTriggeredAbility("
                "new DrawCardSourceControllerEffect(1)));"
                "Ability ability = new SimpleManaAbility(Zone.BATTLEFIELD, "
                "new Mana(1, 1, 1, 1, 1, 0, 0, 0), new GenericManaCost(5));"
                "ability.addCost(new TapSourceCost());"
                "ability.addCost(new SacrificeSourceCost());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertIn(
            reason,
            {
                "mana_source_sacrifice_oracle_not_simple",
                "mana_source_source_sacrifice_cost_not_supported",
                "tap_sacrifice_mana_source_tap_oracle_not_simple",
            },
        )

    def test_conditional_simple_mana_source_stays_blocked(self) -> None:
        row = queue_row(
            split.RAMP_CREATURE_UNIT,
            effect_classes=["BasicManaEffect", "ConditionalManaEffect"],
            ability_kind="activated",
            ability_classes=["SimpleManaAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Leafkin Druid",
                type_line="Creature - Elemental Druid",
                oracle_text="{T}: Add {G}. If you control four or more creatures, add {G}{G} instead.",
            ),
            source_text=(
                "this.addAbility(new SimpleManaAbility(new ConditionalManaEffect("
                "new BasicManaEffect(Mana.GreenMana(2)), new BasicManaEffect(Mana.GreenMana(1))), "
                "new TapSourceCost()));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "mana_source_effect_class_not_simple")

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

    def test_counter_target_mana_value_spell_maps_to_stack_mana_value_constraints(self) -> None:
        row = queue_row(split.COUNTER_UNIT, effect_classes=["CounterTargetEffect"])

        high_value, high_reason = split.split_row(
            row,
            metadata(oracle_text="Counter target spell with mana value 4 or greater."),
            source_text="this.getSpellAbility().addEffect(new CounterTargetEffect());",
        )
        low_value, low_reason = split.split_row(
            row,
            metadata(oracle_text="Counter target spell with mana value 1 or less."),
            source_text="this.getSpellAbility().addEffect(new CounterTargetEffect());",
        )
        exact_value, exact_reason = split.split_row(
            row,
            metadata(oracle_text="Counter target spell with mana value 2."),
            source_text="this.getSpellAbility().addEffect(new CounterTargetEffect());",
        )

        self.assertEqual(high_reason, "selected_exact_scope")
        self.assertEqual(low_reason, "selected_exact_scope")
        self.assertEqual(exact_reason, "selected_exact_scope")
        self.assertEqual(high_value["effect_json"]["target"], "spell_mana_value_4_or_greater")
        self.assertEqual(
            high_value["effect_json"]["target_constraints"]["counter_target_mana_value_min"],
            4,
        )
        self.assertEqual(
            low_value["effect_json"]["target_constraints"]["counter_target_mana_value_max"],
            1,
        )
        self.assertEqual(
            exact_value["effect_json"]["target_constraints"]["counter_target_mana_value"],
            2,
        )

    def test_counter_target_extended_color_and_alternative_spell_filters(self) -> None:
        row = queue_row(split.COUNTER_UNIT, effect_classes=["CounterTargetEffect"])
        cases = [
            (
                "Counter target colorless spell.",
                "colorless_spell",
                {"spell_color_count_exact": 0},
            ),
            (
                "Counter target red or green spell.",
                "red_or_green_spell",
                {"spell_colors": ["R", "G"]},
            ),
            (
                "Counter target nonblue spell.",
                "nonblue_spell",
                {"exclude_spell_colors": ["U"]},
            ),
            (
                "Counter target multicolored spell.",
                "multicolored_spell",
                {"spell_color_count_min": 2},
            ),
            (
                "Counter target blue instant spell.",
                "blue_instant_spell",
                {"spell_types": ["instant"], "spell_colors": ["U"]},
            ),
            (
                "Counter target creature or sorcery spell.",
                "creature_or_sorcery_spell",
                {"any_of": [{"card_types": ["creature"]}, {"spell_types": ["sorcery"]}]},
            ),
            (
                "Counter target creature or Aura spell.",
                "creature_or_aura_spell",
                {"any_of": [{"card_types": ["creature"]}, {"spell_subtypes": ["aura"]}]},
            ),
            (
                "Counter target Spirit or Arcane spell.",
                "spirit_or_arcane_spell",
                {"spell_subtypes": ["spirit", "arcane"]},
            ),
        ]

        for oracle_text, target, expected_fields in cases:
            with self.subTest(oracle_text=oracle_text):
                proposal, reason = split.split_row(
                    row,
                    metadata(oracle_text=oracle_text),
                    source_text="this.getSpellAbility().addEffect(new CounterTargetEffect());",
                )
                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["target"], target)
                for key, value in expected_fields.items():
                    self.assertEqual(effect["target_constraints"][key], value)

    def test_counter_draw_spell_maps_to_counter_runtime_with_draw_on_counter(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["CounterTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Counter target creature spell. Draw a card."),
            source_text=(
                "this.getSpellAbility().addEffect(new CounterTargetEffect());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "counter")
        self.assertEqual(effect["battle_model_scope"], split.COUNTER_DRAW_SCOPE)
        self.assertEqual(effect["target"], "creature_spell")
        self.assertEqual(effect["draw_on_counter"], 1)
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "stack", "stack_object": "spell", "card_types": ["creature"]},
        )
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["counter", "draw_cards"],
        )

    def test_counter_gain_life_spell_maps_to_counter_runtime_with_life_gain(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["CounterTargetEffect", "GainLifeEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Counter target spell. You gain 3 life."),
            source_text=(
                "this.getSpellAbility().addEffect(new CounterTargetEffect());"
                "this.getSpellAbility().addEffect(new GainLifeEffect(3));"
                "this.getSpellAbility().addTarget(new TargetSpell());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "counter")
        self.assertEqual(effect["battle_model_scope"], split.COUNTER_GAIN_LIFE_SCOPE)
        self.assertEqual(effect["target"], "spell")
        self.assertEqual(effect["life_gain_on_counter"], 3)
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "stack", "stack_object": "spell"},
        )
        self.assertEqual(
            [component["effect"] for component in effect["_composite_rule_components"]],
            ["counter", "life_total_change"],
        )

    def test_counter_gain_life_spell_blocks_dynamic_life_gain(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["CounterTargetEffect", "GainLifeEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Counter target spell. You gain 3 life."),
            source_text=(
                "this.getSpellAbility().addEffect(new CounterTargetEffect());"
                "this.getSpellAbility().addEffect(new GainLifeEffect(TargetManaValue.instance));"
                "this.getSpellAbility().addTarget(new TargetSpell());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "counter_life_gain_source_not_fixed")

    def test_counter_unless_pays_fixed_generic_spell_maps_to_tax_counter_runtime(self) -> None:
        row = queue_row(
            split.COUNTER_UNLESS_PAYS_UNIT,
            effect_classes=["CounterUnlessPaysEffect"],
            xmage_signals=["targeting", "counter"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Counter target nonartifact spell unless its controller pays {2}."),
            source_text=(
                "this.getSpellAbility().addEffect("
                "new CounterUnlessPaysEffect(new GenericManaCost(2)));"
                "this.getSpellAbility().addTarget(new TargetSpell(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "counter")
        self.assertEqual(effect["battle_model_scope"], split.COUNTER_UNLESS_PAYS_SCOPE)
        self.assertEqual(effect["target"], "nonartifact_spell")
        self.assertEqual(effect["counter_unless_pays_generic"], 2)
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "stack", "stack_object": "spell", "exclude_card_types": ["artifact"]},
        )

    def test_counter_unless_pays_fixed_generic_exile_replacement_maps_to_runtime(self) -> None:
        row = queue_row(
            split.COUNTER_UNLESS_PAYS_UNIT,
            effect_classes=["CounterUnlessPaysEffect"],
            xmage_signals=["targeting", "counter"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Counter target creature or planeswalker spell unless its controller pays {3}. "
                    "If that spell is countered this way, exile it instead of putting into its owner's graveyard."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect("
                "new CounterUnlessPaysEffect(new GenericManaCost(3), true));"
                "this.getSpellAbility().addTarget(new TargetSpell(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature_or_planeswalker_spell")
        self.assertEqual(effect["counter_unless_pays_generic"], 3)
        self.assertTrue(effect["countered_spell_to_exile"])
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "stack", "stack_object": "spell", "card_types": ["creature", "planeswalker"]},
        )

    def test_counter_unless_pays_fixed_generic_artifact_or_creature_maps_to_runtime(self) -> None:
        row = queue_row(
            split.COUNTER_UNLESS_PAYS_UNIT,
            effect_classes=["CounterUnlessPaysEffect"],
            xmage_signals=["targeting", "counter"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Counter target artifact or creature spell unless its controller pays {4}."),
            source_text=(
                "this.getSpellAbility().addEffect("
                "new CounterUnlessPaysEffect(new GenericManaCost(4)));"
                "this.getSpellAbility().addTarget(new TargetSpell(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "artifact_or_creature_spell")
        self.assertEqual(effect["counter_unless_pays_generic"], 4)
        self.assertNotIn("countered_spell_to_exile", effect)
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "stack", "stack_object": "spell", "card_types": ["artifact", "creature"]},
        )

    def test_counter_unless_pays_blocks_dynamic_variant(self) -> None:
        row = queue_row(
            split.COUNTER_UNLESS_PAYS_UNIT,
            effect_classes=["CounterUnlessPaysEffect"],
            xmage_signals=["targeting", "counter"],
        )
        dynamic_proposal, dynamic_reason = split.split_row(
            row,
            metadata(oracle_text="Counter target spell unless its controller pays {1}."),
            source_text=(
                "this.getSpellAbility().addEffect("
                "new CounterUnlessPaysEffect(GetXValue.instance));"
                "this.getSpellAbility().addTarget(new TargetSpell());"
            ),
        )

        self.assertIsNone(dynamic_proposal)
        self.assertEqual(dynamic_reason, "counter_unless_pays_source_not_fixed_generic")

    def test_counter_draw_spell_with_activated_ability_target_stays_blocked(self) -> None:
        row = queue_row(
            split.DRAW_UNIT,
            effect_classes=["CounterTargetEffect", "DrawCardSourceControllerEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Counter target activated ability. "
                    "(Mana abilities can't be targeted.) Draw a card."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new CounterTargetEffect());"
                "this.getSpellAbility().addEffect(new DrawCardSourceControllerEffect());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "counter_draw_target_not_supported")

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

    def test_multi_zone_graveyard_recursion_spell_maps_battlefield_then_hand(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=[
                "ReturnFromGraveyardToBattlefieldTargetEffect",
                "ReturnFromGraveyardToHandTargetEffect",
            ],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Badlands Revival",
                type_line="Sorcery",
                oracle_text=(
                    "Return up to one target creature card from your graveyard to the battlefield. "
                    "Return up to one target permanent card from your graveyard to your hand."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect().setTargetPointer(new SecondTargetPointer()));
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 1, StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 1, filter));
                private static final FilterCard filter = new FilterPermanentCard("permanent card from your graveyard");
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "recursion")
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_MULTI_ZONE_SCOPE)
        self.assertEqual(effect["mode_selection"], "all_components")
        self.assertEqual(
            [(component["target"], component["destination"], component["count"]) for component in effect["recursion_components"]],
            [("creature", "battlefield", 1), ("permanent", "hand", 1)],
        )
        self.assertTrue(all(component["up_to_count"] for component in effect["recursion_components"]))

    def test_multi_zone_graveyard_recursion_spell_maps_hand_then_tapped_battlefield(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=[
                "ReturnFromGraveyardToBattlefieldTargetEffect",
                "ReturnFromGraveyardToHandTargetEffect",
            ],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Pull Through the Weft",
                type_line="Sorcery",
                oracle_text=(
                    "Return up to two target nonland permanent cards from your graveyard to your hand, "
                    "then return up to two target land cards from your graveyard to the battlefield tapped."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterNonlandCard("nonland permanent cards from your graveyard");
                static { filter.add(PermanentPredicate.instance); }
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 2, filter));
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect(true)
                    .setTargetPointer(new SecondTargetPointer()));
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 2, StaticFilters.FILTER_CARD_LAND_FROM_YOUR_GRAVEYARD));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_MULTI_ZONE_SCOPE)
        self.assertEqual(
            [(component["target"], component["destination"], component["count"]) for component in effect["recursion_components"]],
            [("nonland_permanent", "hand", 2), ("land", "battlefield", 2)],
        )
        self.assertTrue(effect["recursion_components"][1]["enters_tapped"])

    def test_multi_zone_graveyard_recursion_blocks_threshold_conditional(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=[
                "ConditionalOneShotEffect",
                "ReturnFromGraveyardToBattlefieldTargetEffect",
                "ReturnFromGraveyardToHandTargetEffect",
            ],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Stitch Together",
                type_line="Sorcery",
                oracle_text=(
                    "Return target creature card from your graveyard to your hand. "
                    "Threshold - Return that card from your graveyard to the battlefield instead "
                    "if seven or more cards are in your graveyard."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ConditionalOneShotEffect(
                    new ReturnFromGraveyardToBattlefieldTargetEffect(), new ReturnFromGraveyardToHandTargetEffect(),
                    ThresholdCondition.instance));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "recursion_effect_class_not_pure")

    def test_mill_then_return_creature_spell_maps_to_recursion_runtime(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["MillCardsControllerEffect", "ReturnCardChosenFromGraveyardEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Corpse Churn",
                type_line="Instant",
                oracle_text=(
                    "Put the top three cards of your library into your graveyard, "
                    "then you may return a creature card from your graveyard to your hand."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new MillCardsControllerEffect(3));"
                "this.getSpellAbility().addEffect(new ReturnCardChosenFromGraveyardEffect(true, "
                "StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD, PutCards.HAND).concatBy(\", then\"));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_MILL_RETURN_SCOPE)
        self.assertEqual(effect["pre_recursion_mill_count"], 3)
        self.assertEqual(effect["target"], "creature")
        self.assertTrue(effect["up_to_count"])
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
        )

    def test_mill_then_return_creature_or_land_spell_maps_to_recursion_runtime(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["MillCardsControllerEffect", "ReturnCardChosenFromGraveyardEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Grapple with the Past",
                type_line="Instant",
                oracle_text=(
                    "Mill three cards, then you may return a creature or land card "
                    "from your graveyard to your hand."
                ),
            ),
            source_text=(
                "filter.add(Predicates.or(CardType.CREATURE.getPredicate(), CardType.LAND.getPredicate()));"
                "this.getSpellAbility().addEffect(new MillCardsControllerEffect(3));"
                "this.getSpellAbility().addEffect(new ReturnCardChosenFromGraveyardEffect(true, "
                "filter, PutCards.HAND).concatBy(\", then\"));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature_or_land")
        self.assertEqual(effect["pre_recursion_mill_count"], 3)
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["creature", "land"]},
        )

    def test_mill_then_return_spell_blocks_source_oracle_mill_mismatch(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["MillCardsControllerEffect", "ReturnCardChosenFromGraveyardEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Churn",
                type_line="Instant",
                oracle_text=(
                    "Mill three cards, then you may return a creature card "
                    "from your graveyard to your hand."
                ),
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new MillCardsControllerEffect(2));"
                "this.getSpellAbility().addEffect(new ReturnCardChosenFromGraveyardEffect(true, "
                "StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD, PutCards.HAND).concatBy(\", then\"));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "mill_return_source_oracle_mill_count_mismatch")

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

    def test_graveyard_to_hand_two_creatures_maps_exact_count(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(name="Death's Duet", oracle_text="Return two target creature cards from your graveyard to your hand."),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(2, StaticFilters.FILTER_CARD_CREATURES_YOUR_GRAVEYARD));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["count"], 2)
        self.assertNotIn("up_to_count", effect)

    def test_graveyard_to_hand_x_creatures_maps_count_from_x(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Death Denied",
                type_line="Instant",
                oracle_text="Return X target creature cards from your graveyard to your hand.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(
                    StaticFilters.FILTER_CARD_CREATURES_YOUR_GRAVEYARD));
                this.getSpellAbility().setTargetAdjuster(new XTargetsCountAdjuster());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["count"], 0)
        self.assertTrue(effect["count_from_x"])
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
        )

    def test_graveyard_to_hand_x_creatures_requires_xmage_adjuster(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Death Denied",
                type_line="Instant",
                oracle_text="Return X target creature cards from your graveyard to your hand.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(
                    StaticFilters.FILTER_CARD_CREATURES_YOUR_GRAVEYARD));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "recursion_source_x_count_not_supported")

    def test_graveyard_to_hand_color_and_subtype_targets_map(self) -> None:
        cases = [
            (
                "Revive",
                "Return target green card from your graveyard to your hand.",
                "green_card",
                {"zone": "graveyard", "controller": "self", "colors": ["G"]},
            ),
            (
                "Reborn Hope",
                "Return target multicolored card from your graveyard to your hand.",
                "multicolored_card",
                {"zone": "graveyard", "controller": "self", "min_colors": 2},
            ),
            (
                "Boggart Birth Rite",
                "Return target Goblin card from your graveyard to your hand.",
                "goblin_card",
                {"zone": "graveyard", "controller": "self", "subtypes": ["goblin"]},
            ),
        ]
        for name, oracle, target, constraints in cases:
            with self.subTest(name=name):
                row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
                proposal, reason = split.split_row(
                    row,
                    metadata(name=name, oracle_text=oracle),
                    source_text="this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());",
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["target"], target)
                self.assertEqual(effect["target_constraints"], constraints)

    def test_graveyard_to_hand_maps_up_to_three_chosen_creature_type(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Aphetto Dredging",
                type_line="Sorcery",
                oracle_text=(
                    "Return up to three target creature cards of the creature type of your choice "
                    "from your graveyard to your hand."
                ),
            ),
            source_text="""
                Effect effect = new ReturnFromGraveyardToHandTargetEffect();
                Choice typeChoice = new ChoiceCreatureType(game, ability);
                FilterCreatureCard filter = new FilterCreatureCard(chosenType + " cards");
                filter.add(SubType.byDescription(chosenType).getPredicate());
                ability.addTarget(new TargetCardInYourGraveyard(0, 3, filter));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_SCOPE)
        self.assertEqual(effect["target"], "shared_creature_type")
        self.assertEqual(effect["count"], 3)
        self.assertTrue(effect["up_to_count"])
        self.assertEqual(
            effect["target_constraints"],
            {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "shared_subtype_group": "creature_type",
            },
        )

    def test_graveyard_to_hand_blocks_chosen_creature_type_without_xmage_choice_source(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Aphetto Dredging",
                type_line="Sorcery",
                oracle_text=(
                    "Return up to three target creature cards of the creature type of your choice "
                    "from your graveyard to your hand."
                ),
            ),
            source_text="this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "recursion_source_target_not_supported")

    def test_graveyard_to_hand_choose_one_or_both_maps_components(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Grim Discovery",
                oracle_text=(
                    "Choose one or both —\n"
                    "• Return target creature card from your graveyard to your hand.\n"
                    "• Return target land card from your graveyard to your hand."
                ),
            ),
            source_text="""
                this.getSpellAbility().getModes().setMinModes(1);
                this.getSpellAbility().getModes().setMaxModes(2);
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                Mode mode = new Mode(new ReturnFromGraveyardToHandTargetEffect());
                this.getSpellAbility().addMode(mode);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], "xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1")
        self.assertEqual(effect["mode_selection"], "one_or_both")
        self.assertEqual(
            effect["recursion_components"],
            [
                {
                    "target": "creature",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
                    "count": 1,
                    "destination": "hand",
                    "target_controller": "self",
                },
                {
                    "target": "land",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["land"]},
                    "count": 1,
                    "destination": "hand",
                    "target_controller": "self",
                },
            ],
        )

    def test_graveyard_to_hand_choose_one_or_both_requires_source_modes(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Grim Discovery",
                oracle_text=(
                    "Choose one or both —\n"
                    "• Return target creature card from your graveyard to your hand.\n"
                    "• Return target land card from your graveyard to your hand."
                ),
            ),
            source_text="this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "recursion_choose_one_or_both_source_not_supported")

    def test_graveyard_to_hand_choose_one_maps_subtype_component(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Ghoulcaller's Chant",
                oracle_text=(
                    "Choose one —\n"
                    "• Return target creature card from your graveyard to your hand.\n"
                    "• Return two target Zombie cards from your graveyard to your hand."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                Mode mode = new Mode(new ReturnFromGraveyardToHandTargetEffect());
                mode.addTarget(new TargetCardInYourGraveyard(2, filter));
                this.getSpellAbility().addMode(mode);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], "xmage_return_choose_one_graveyard_cards_to_hand_spell_v1")
        self.assertEqual(effect["mode_selection"], "choose_one")
        self.assertEqual(effect["recursion_components"][1]["target"], "zombie_card")
        self.assertEqual(effect["recursion_components"][1]["count"], 2)

    def test_graveyard_to_hand_choose_one_maps_shared_creature_type_component(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToHandTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Unbury",
                oracle_text=(
                    "Choose one —\n"
                    "• Return target creature card from your graveyard to your hand.\n"
                    "• Return two target creature cards that share a creature type from your graveyard to your hand."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                Mode mode = new Mode(new ReturnFromGraveyardToHandTargetEffect());
                mode.addTarget(new UnburyTarget());
                this.getSpellAbility().addMode(mode);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["mode_selection"], "choose_one")
        self.assertEqual(effect["recursion_components"][1]["target"], "shared_creature_type")
        self.assertEqual(effect["recursion_components"][1]["shared_subtype_group"], "creature_type")

    def test_graveyard_to_hand_exile_self_spell_maps_to_recursion_runtime(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect", "ExileSpellEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Restock",
                type_line="Sorcery",
                oracle_text="Return two target cards from your graveyard to your hand. Exile Restock.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(2, StaticFilters.FILTER_CARD_FROM_YOUR_GRAVEYARD));
                this.getSpellAbility().addEffect(new ExileSpellEffect());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_SCOPE)
        self.assertEqual(effect["target"], "any_card")
        self.assertEqual(effect["count"], 2)
        self.assertEqual(effect["destination"], "hand")
        self.assertTrue(effect["exiles_self"])
        self.assertEqual(effect["xmage_additional_effect_class"], "ExileSpellEffect")

    def test_graveyard_to_hand_exile_self_variable_x_maps_to_recursion_runtime(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect", "ExileSpellEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Wildest Dreams",
                type_line="Sorcery",
                oracle_text="Return X target cards from your graveyard to your hand. Exile Wildest Dreams.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard());
                this.getSpellAbility().setTargetAdjuster(new XTargetsCountAdjuster());
                this.getSpellAbility().addEffect(new ExileSpellEffect());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_SCOPE)
        self.assertEqual(effect["target"], "any_card")
        self.assertEqual(effect["target_constraints"], {"zone": "graveyard", "controller": "self", "scope": "any_card"})
        self.assertEqual(effect["count"], 0)
        self.assertTrue(effect["count_from_x"])
        self.assertTrue(effect["exiles_self"])
        self.assertNotIn("up_to_count", effect)

    def test_graveyard_to_hand_exile_self_up_to_x_instant_or_sorcery_maps_to_recursion_runtime(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect", "ExileSpellEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Divergent Equation",
                type_line="Instant",
                oracle_text=(
                    "Return up to X target instant and/or sorcery cards from your graveyard to your hand. "
                    "Exile Divergent Equation."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 1, new FilterInstantOrSorceryCard("instant and/or sorcery cards")));
                this.getSpellAbility().setTargetAdjuster(new XTargetsCountAdjuster());
                this.getSpellAbility().addEffect(new ExileSpellEffect());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "instant_or_sorcery")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["instant", "sorcery"]},
        )
        self.assertEqual(effect["count"], 0)
        self.assertTrue(effect["count_from_x"])
        self.assertTrue(effect["up_to_count"])
        self.assertTrue(effect["exiles_self"])

    def test_graveyard_to_battlefield_spell_maps_to_recursion_runtime(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Sorcery",
                oracle_text="Return target creature card from your graveyard to the battlefield.",
            ),
            source_text="""
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(filter));
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "recursion")
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_BATTLEFIELD_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["count"], 1)
        self.assertEqual(effect["destination"], "battlefield")
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(effect["target_graveyard_controller"], "self")
        self.assertEqual(effect["battlefield_controller"], "self")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
        )

    def test_graveyard_to_battlefield_opponent_graveyard_maps_under_your_control(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Ashen Powder",
                type_line="Sorcery",
                oracle_text="Put target creature card from an opponent's graveyard onto the battlefield under your control.",
            ),
            source_text="""
                this.getSpellAbility().addTarget(new TargetCardInOpponentsGraveyard(new FilterCreatureCard()));
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_controller"], "opponent")
        self.assertEqual(effect["target_graveyard_controller"], "opponent")
        self.assertEqual(effect["battlefield_controller"], "self")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "opponent", "card_types": ["creature"]},
        )

    def test_graveyard_to_battlefield_any_graveyard_maps_under_your_control(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Hymn of Rebirth",
                type_line="Sorcery",
                oracle_text="Put target creature card from a graveyard onto the battlefield under your control.",
            ),
            source_text="""
                this.getSpellAbility().addTarget(new TargetCardInGraveyard(StaticFilters.FILTER_CARD_CREATURE_A_GRAVEYARD));
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target_controller"], "any_player")
        self.assertEqual(effect["target_graveyard_controller"], "any_player")
        self.assertEqual(effect["battlefield_controller"], "self")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "any_player", "card_types": ["creature"]},
        )

    def test_graveyard_to_battlefield_mana_value_limit_and_tapped_are_preserved(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Helping Hand",
                type_line="Sorcery",
                oracle_text="Return target creature card with mana value 3 or less from your graveyard to the battlefield tapped.",
            ),
            source_text="""
                filter.add(new ManaValuePredicate(ComparisonType.FEWER_THAN, 4));
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect(true));
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(filter));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["recursion_mana_value_max"], 3)
        self.assertTrue(effect["enters_tapped"])
        self.assertEqual(
            effect["target_constraints"],
            {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "mana_value_max": 3,
            },
        )

    def test_graveyard_to_battlefield_x_mana_value_limit_maps_from_x_adjuster(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Stir the Grave",
                type_line="Sorcery",
                oracle_text="Return target creature card with mana value X or less from your graveyard to the battlefield.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect()
                    .setText("return target creature card with mana value X or less from your graveyard to the battlefield"));
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(
                    StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                this.getSpellAbility().setTargetAdjuster(new XManaValueTargetAdjuster(ComparisonType.OR_LESS));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_BATTLEFIELD_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertTrue(effect["target_mana_value_max_from_x"])
        self.assertEqual(
            effect["target_constraints"],
            {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "mana_value_max_source": "x_value",
            },
        )

    def test_graveyard_to_battlefield_x_outlaw_count_maps_from_x_adjuster(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Back in Town",
                type_line="Sorcery",
                oracle_text=(
                    "Return X target outlaw creature cards from your graveyard to the battlefield. "
                    "(Assassins, Mercenaries, Pirates, Rogues, and Warlocks are outlaws.)"
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterCreatureCard("outlaw cards");
                filter.add(OutlawPredicate.instance);
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(filter));
                this.getSpellAbility().setTargetAdjuster(new TargetsCountAdjuster(GetXValue.instance));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_BATTLEFIELD_SCOPE)
        self.assertEqual(effect["target"], "outlaw_creature")
        self.assertEqual(effect["count"], 0)
        self.assertTrue(effect["count_from_x"])
        self.assertEqual(
            effect["target_constraints"],
            {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "subtype_group": "outlaw",
                "subtypes": ["assassin", "mercenary", "pirate", "rogue", "warlock"],
            },
        )

    def test_graveyard_to_battlefield_with_plus_one_counters_maps_to_counter_scope(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldWithCounterTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Evil Reawakened",
                type_line="Sorcery",
                oracle_text=(
                    "Return target creature card from your graveyard to the battlefield "
                    "with two additional +1/+1 counters on it."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(
                    new ReturnFromGraveyardToBattlefieldWithCounterTargetEffect(
                        true, CounterType.P1P1.createInstance(2)));
                this.getSpellAbility().addTarget(
                    new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_BATTLEFIELD_COUNTER_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["destination"], "battlefield")
        self.assertEqual(effect["target_graveyard_controller"], "self")
        self.assertEqual(effect["battlefield_controller"], "self")
        self.assertEqual(effect["counter_type"], "+1/+1")
        self.assertEqual(effect["counter_amount"], 2)
        self.assertTrue(effect["additional_counter"])

    def test_graveyard_to_battlefield_with_lifelink_counter_preserves_keyword(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldWithCounterTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Unbreakable Bond",
                type_line="Sorcery",
                oracle_text=(
                    "Return target creature card from your graveyard to the battlefield "
                    "with a lifelink counter on it."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(
                    new ReturnFromGraveyardToBattlefieldWithCounterTargetEffect(
                        CounterType.LIFELINK.createInstance()));
                this.getSpellAbility().addTarget(
                    new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["counter_type"], "lifelink")
        self.assertEqual(effect["counter_amount"], 1)
        self.assertEqual(effect["keywords"], ["lifelink"])
        self.assertEqual(effect["counter_grants_keywords"], ["lifelink"])

    def test_graveyard_to_battlefield_with_counter_any_graveyard_preserves_count(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldWithCounterTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Aberrant Return",
                type_line="Sorcery",
                oracle_text=(
                    "Put one, two, or three target creature cards from graveyards onto the battlefield "
                    "under your control. Each of them enters with an additional -1/-1 counter on it."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(
                    new ReturnFromGraveyardToBattlefieldWithCounterTargetEffect(
                        CounterType.M1M1.createInstance()));
                this.getSpellAbility().addTarget(
                    new TargetCardInGraveyard(1, 3, StaticFilters.FILTER_CARD_CREATURES));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["count"], 3)
        self.assertEqual(effect["target_count_min"], 1)
        self.assertEqual(effect["target_graveyard_controller"], "any_player")
        self.assertEqual(effect["counter_type"], "-1/-1")
        self.assertEqual(effect["counter_amount"], 1)

    def test_graveyard_to_battlefield_with_counter_blocks_unmodeled_counter(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldWithCounterTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Return",
                type_line="Sorcery",
                oracle_text=(
                    "Return target creature card from your graveyard to the battlefield "
                    "with a lifelink counter on it."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(
                    new ReturnFromGraveyardToBattlefieldWithCounterTargetEffect(
                        CounterType.FINALITY.createInstance()));
                this.getSpellAbility().addTarget(
                    new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "recursion_battlefield_counter_source_counter_not_supported")

    def test_graveyard_to_library_spell_maps_to_library_top_recursion(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["PutOnLibraryTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Reclaim",
                type_line="Instant",
                oracle_text="Put target card from your graveyard on top of your library.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new PutOnLibraryTargetEffect(true));
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "recursion")
        self.assertEqual(effect["battle_model_scope"], split.GRAVEYARD_TO_LIBRARY_SPELL_SCOPE)
        self.assertEqual(effect["target"], "any_card")
        self.assertEqual(effect["count"], 1)
        self.assertEqual(effect["destination"], "library_top")
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(effect["target_graveyard_controller"], "self")
        self.assertEqual(effect["library_controller"], "self")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "scope": "any_card"},
        )

    def test_graveyard_to_library_up_to_three_creatures_preserves_count(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["PutOnLibraryTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Reinforcements",
                type_line="Instant",
                oracle_text="Put up to three target creature cards from your graveyard on top of your library.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new PutOnLibraryTargetEffect(true));
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(
                    0, 3, StaticFilters.FILTER_CARD_CREATURES_YOUR_GRAVEYARD));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["count"], 3)
        self.assertTrue(effect["up_to_count"])
        self.assertEqual(effect["destination"], "library_top")

    def test_graveyard_to_library_source_destination_mismatch_blocks(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["PutOnLibraryTargetEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Bottom",
                type_line="Sorcery",
                oracle_text="Put target card from your graveyard on top of your library.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new PutOnLibraryTargetEffect(false));
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard());
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "graveyard_to_library_source_oracle_destination_mismatch")

    def test_target_player_shuffle_graveyard_cards_to_library_spell_maps(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["TargetPlayerShufflesTargetCardsEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Dwell on the Past",
                type_line="Sorcery",
                oracle_text=(
                    "Target player shuffles up to four target cards from their graveyard into their library."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new TargetPlayerShufflesTargetCardsEffect());
                this.getSpellAbility().addTarget(new TargetPlayer());
                this.getSpellAbility().addTarget(new TargetCardInTargetPlayersGraveyard(4));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.GRAVEYARD_TO_LIBRARY_SPELL_SCOPE)
        self.assertEqual(effect["xmage_effect_class"], "TargetPlayerShufflesTargetCardsEffect")
        self.assertEqual(effect["target"], "any_card")
        self.assertEqual(effect["count"], 4)
        self.assertTrue(effect["up_to_count"])
        self.assertEqual(effect["destination"], "library_shuffle")
        self.assertEqual(effect["target_controller"], "target_player")
        self.assertEqual(effect["target_graveyard_controller"], "target_player")
        self.assertEqual(effect["library_controller"], "target_player")

    def test_target_player_shuffle_graveyard_cards_to_library_allows_flashback(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["TargetPlayerShufflesTargetCardsEffect"],
            ability_classes=["FlashbackAbility"],
            xmage_signals=["targeting"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Memory's Journey",
                type_line="Instant",
                oracle_text=(
                    "Target player shuffles up to three target cards from their graveyard into their library. "
                    "Flashback {G}"
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new TargetPlayerShufflesTargetCardsEffect());
                this.getSpellAbility().addTarget(new TargetPlayer());
                this.getSpellAbility().addTarget(new TargetCardInTargetPlayersGraveyard(3));
                this.addAbility(new FlashbackAbility(this, new ManaCostsImpl<>("{G}")));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["count"], 3)
        self.assertEqual(effect["flashback_cost"], "{G}")
        self.assertEqual(effect["flashback_status"], "runtime_executor_v1")

    def test_target_player_shuffle_graveyard_cards_count_mismatch_blocks(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["TargetPlayerShufflesTargetCardsEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Reclamation",
                type_line="Instant",
                oracle_text=(
                    "Target player shuffles up to three target cards from their graveyard into their library."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new TargetPlayerShufflesTargetCardsEffect());
                this.getSpellAbility().addTarget(new TargetPlayer());
                this.getSpellAbility().addTarget(new TargetCardInTargetPlayersGraveyard(2));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "graveyard_shuffle_to_library_source_oracle_count_mismatch")

    def test_permanent_activated_graveyard_to_library_maps_bottom_self_graveyard(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["PutOnLibraryTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Epitaph Golem",
                type_line="Artifact Creature - Golem",
                oracle_text="{2}: Put target card from your graveyard on the bottom of your library.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new PutOnLibraryTargetEffect(false),
                    new ManaCostsImpl<>("{2}"));
                ability.addTarget(new TargetCardInYourGraveyard());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_GRAVEYARD_TO_LIBRARY_SCOPE)
        self.assertEqual(effect["activated_effect"], "graveyard_to_library")
        self.assertEqual(effect["graveyard_to_library_target"], "any_card")
        self.assertEqual(effect["graveyard_to_library_target_count"], 1)
        self.assertEqual(effect["graveyard_to_library_destination"], "library_bottom")
        self.assertEqual(effect["activation_cost_mana"], "{2}")
        self.assertEqual(effect["activation_cost_generic"], 2)
        self.assertEqual(effect["activation_cost_colors"], [])
        self.assertFalse(effect["activation_requires_tap"])
        self.assertEqual(effect["_activated_rule_effects"][0]["destination"], "library_bottom")

    def test_permanent_activated_graveyard_to_library_maps_top_creature(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["PutOnLibraryTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Haunted Crossroads",
                type_line="Enchantment",
                oracle_text="{B}: Put target creature card from your graveyard on top of your library.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new PutOnLibraryTargetEffect(true),
                    new ManaCostsImpl<>("{B}"));
                ability.addTarget(new TargetCardInYourGraveyard(
                    StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "enchantment")
        self.assertEqual(effect["graveyard_to_library_target"], "creature")
        self.assertEqual(effect["graveyard_to_library_destination"], "library_top")
        self.assertEqual(effect["activation_cost_generic"], 0)
        self.assertEqual(effect["activation_cost_colors"], ["B"])
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
        )

    def test_permanent_activated_graveyard_to_library_maps_any_graveyard_owner_library(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["PutOnLibraryTargetEffect"],
            ability_kind="activated",
            ability_classes=["ReachAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Cogwork Archivist",
                type_line="Artifact Creature - Construct",
                oracle_text="{2}, {T}: Put target card from a graveyard on the bottom of its owner's library.",
            ),
            source_text="""
                this.addAbility(ReachAbility.getInstance());
                Ability ability = new SimpleActivatedAbility(
                    new PutOnLibraryTargetEffect(false),
                    new GenericManaCost(2));
                ability.addCost(new TapSourceCost());
                ability.addTarget(new TargetCardInGraveyard());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_GRAVEYARD_TO_LIBRARY_SCOPE)
        self.assertEqual(effect["graveyard_to_library_target"], "any_card")
        self.assertEqual(effect["graveyard_to_library_target_count"], 1)
        self.assertEqual(effect["graveyard_to_library_destination"], "library_bottom")
        self.assertEqual(effect["target_graveyard_controller"], "any")
        self.assertEqual(effect["library_controller"], "owner")
        self.assertEqual(effect["target_controller"], "any")
        self.assertEqual(effect["target_constraints"], {"zone": "graveyard", "controller": "any", "scope": "any_card"})
        self.assertEqual(effect["activation_cost_mana"], "{2}")
        self.assertEqual(effect["activation_cost_generic"], 2)
        self.assertEqual(effect["activation_cost_colors"], [])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertEqual(effect["keywords"], ["reach"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertTrue(effect["reach"])
        activated = effect["_activated_rule_effects"][0]
        self.assertEqual(activated["target_graveyard_controller"], "any")
        self.assertEqual(activated["library_controller"], "owner")

    def test_permanent_activated_graveyard_to_library_maps_tap_cost_constructor(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["PutOnLibraryTargetEffect"],
            ability_kind="activated",
            ability_classes=["DefenderAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Junktroller",
                type_line="Artifact Creature - Golem",
                oracle_text="{T}: Put target card from a graveyard on the bottom of its owner's library.",
            ),
            source_text="""
                this.addAbility(DefenderAbility.getInstance());
                Ability ability = new SimpleActivatedAbility(
                    new PutOnLibraryTargetEffect(false), new TapSourceCost());
                ability.addTarget(new TargetCardInGraveyard());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["graveyard_to_library_activation_cost_mana"], "{0}")
        self.assertEqual(effect["graveyard_to_library_activation_cost_generic"], 0)
        self.assertEqual(effect["graveyard_to_library_activation_cost_colors"], [])
        self.assertTrue(effect["graveyard_to_library_activation_requires_tap"])
        self.assertEqual(effect["target_graveyard_controller"], "any")
        self.assertEqual(effect["library_controller"], "owner")
        self.assertEqual(effect["keywords"], ["defender"])
        self.assertTrue(effect["defender"])

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
        self.assertEqual(reason, "recursion_choose_one_or_both_source_not_supported")

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

    def test_permanent_activated_recursion_accepts_discard_creature_cost(self) -> None:
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
                ability.addCost(new DiscardCardCost(StaticFilters.FILTER_CARD_CREATURE_A));
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_RECURSION_TO_HAND_SCOPE)
        self.assertEqual(effect["activation_cost_mana"], "{B}")
        self.assertEqual(effect["activation_cost_generic"], 0)
        self.assertEqual(effect["activation_cost_colors"], ["B"])
        self.assertEqual(effect["activation_discard_count"], 1)
        self.assertEqual(effect["activation_discard_target"], "creature_card")
        self.assertEqual(effect["graveyard_to_hand_activation_discard_count"], 1)
        self.assertEqual(effect["graveyard_to_hand_activation_discard_target"], "creature_card")
        self.assertEqual(effect["activation_additional_cost"], "discard_cards")
        self.assertIn("permanent with a simple activated graveyard-to-hand ability", proposal["notes"])
        self.assertNotIn("narrow instant/sorcery spell", proposal["notes"])

    def test_permanent_activated_recursion_accepts_tap_discard_any_cost(self) -> None:
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
                name="Undertaker",
                type_line="Creature - Human Spellshaper",
                oracle_text="{B}, {T}, Discard a card: Return target creature card from your graveyard to your hand.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToHandTargetEffect(),
                    new ManaCostsImpl<>("{B}")
                );
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                ability.addCost(new TapSourceCost());
                ability.addCost(new DiscardCardCost());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertTrue(effect["activation_requires_tap"])
        self.assertEqual(effect["activation_discard_count"], 1)
        self.assertEqual(effect["activation_discard_target"], "any_card")
        self.assertEqual(effect["_activated_rule_effects"][0]["activation_discard_target"], "any_card")
        self.assertIn("permanent with a simple activated graveyard-to-hand ability", proposal["notes"])
        self.assertNotIn("narrow instant/sorcery spell", proposal["notes"])

    def test_permanent_activated_recursion_accepts_pay_life_cost(self) -> None:
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
                name="Phyrexian Reclamation",
                type_line="Enchantment",
                oracle_text="{1}{B}, Pay 2 life: Return target creature card from your graveyard to your hand.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToHandTargetEffect(),
                    new ManaCostsImpl<>("{1}{B}")
                );
                ability.addCost(new PayLifeCost(2));
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_RECURSION_TO_HAND_SCOPE)
        self.assertEqual(effect["graveyard_to_hand_target"], "creature")
        self.assertEqual(effect["activation_cost_mana"], "{1}{B}")
        self.assertEqual(effect["activation_life_cost"], 2)
        self.assertEqual(effect["graveyard_to_hand_activation_life_cost"], 2)
        self.assertFalse(effect["activation_requires_tap"])
        self.assertFalse(effect["activation_requires_sacrifice"])

    def test_permanent_activated_recursion_accepts_sacrifice_target_cost(self) -> None:
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
                name="Malevolent Awakening",
                type_line="Enchantment",
                oracle_text="{1}{B}{B}, Sacrifice a creature: Return target creature card from your graveyard to your hand.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToHandTargetEffect(),
                    new ManaCostsImpl<>("{1}{B}{B}")
                );
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                ability.addCost(new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["graveyard_to_hand_target"], "creature")
        self.assertEqual(effect["activation_sacrifice_target"], "creature")
        self.assertTrue(effect["activation_requires_sacrifice_target"])
        self.assertEqual(effect["graveyard_to_hand_activation_sacrifice_target"], "creature")

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
        self.assertEqual(reason, "activated_recursion_oracle_cost_not_supported")

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

    def test_permanent_activated_recursion_maps_hana_kami_arcane_self_sacrifice(self) -> None:
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
                name="Hana Kami",
                type_line="Creature - Spirit",
                oracle_text="{1}{G}, Sacrifice this creature: Return target Arcane card from your graveyard to your hand.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToHandTargetEffect(),
                    new ManaCostsImpl<>("{1}{G}")
                );
                ability.addCost(new SacrificeSourceCost());
                FilterCard filter = new FilterCard("Arcane card from your graveyard");
                filter.add(SubType.ARCANE.getPredicate());
                ability.addTarget(new TargetCardInYourGraveyard(filter));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertIsNotNone(proposal)
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_RECURSION_TO_HAND_SCOPE)
        self.assertEqual(effect["graveyard_to_hand_target"], "arcane_card")
        self.assertEqual(effect["target_constraints"], {"zone": "graveyard", "controller": "self", "subtypes": ["arcane"]})
        self.assertEqual(effect["graveyard_to_hand_activation_cost_mana"], "{1}{G}")
        self.assertEqual(effect["graveyard_to_hand_activation_cost_generic"], 1)
        self.assertEqual(effect["graveyard_to_hand_activation_cost_colors"], ["G"])
        self.assertFalse(effect["graveyard_to_hand_activation_requires_tap"])
        self.assertTrue(effect["graveyard_to_hand_activation_requires_sacrifice"])
        self.assertTrue(effect["activated_self_sacrifice_recursion"])

    def test_permanent_activated_recursion_to_battlefield_maps_doomed_necromancer(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Doomed Necromancer",
                type_line="Creature - Human Cleric Mercenary",
                oracle_text="{B}, {T}, Sacrifice this creature: Return target creature card from your graveyard to the battlefield.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToBattlefieldTargetEffect(),
                    new ColoredManaCost(ColoredManaSymbol.B)
                );
                ability.addCost(new TapSourceCost());
                ability.addCost(new SacrificeSourceCost());
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_RECURSION_TO_BATTLEFIELD_SCOPE)
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["graveyard_to_hand_target"], "creature")
        self.assertEqual(effect["graveyard_to_hand_target_count"], 1)
        self.assertEqual(effect["graveyard_to_hand_destination"], "battlefield")
        self.assertEqual(effect["target_constraints"], {"zone": "graveyard", "controller": "self", "card_types": ["creature"]})
        self.assertEqual(effect["activation_cost_mana"], "{B}")
        self.assertEqual(effect["activation_cost_generic"], 0)
        self.assertEqual(effect["activation_cost_colors"], ["B"])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])
        self.assertTrue(effect["activated_self_sacrifice_recursion"])
        activated = effect["_activated_rule_effects"][0]
        self.assertEqual(activated["destination"], "battlefield")
        self.assertEqual(activated["activated_battle_model_scope"], split.PERMANENT_ACTIVATED_RECURSION_TO_BATTLEFIELD_SCOPE)

    def test_permanent_activated_recursion_to_battlefield_accepts_activate_as_sorcery_self_sacrifice(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="activated",
            ability_classes=["ActivateAsSorceryActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Bonecaller Cleric",
                type_line="Creature - Human Cleric",
                oracle_text=(
                    "{3}{B}, Sacrifice this creature: Return target creature card "
                    "from your graveyard to the battlefield. Activate only as a sorcery."
                ),
            ),
            source_text="""
                Ability ability = new ActivateAsSorceryActivatedAbility(
                    new ReturnFromGraveyardToBattlefieldTargetEffect(),
                    new ManaCostsImpl<>("{3}{B}")
                );
                ability.addCost(new SacrificeSourceCost());
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_RECURSION_TO_BATTLEFIELD_SCOPE)
        self.assertEqual(effect["xmage_ability_class"], "ActivateAsSorceryActivatedAbility")
        self.assertEqual(effect["activation_timing"], "sorcery")
        self.assertEqual(effect["activation_cost_mana"], "{3}{B}")
        self.assertEqual(effect["activation_cost_generic"], 3)
        self.assertEqual(effect["activation_cost_colors"], ["B"])
        self.assertFalse(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])
        self.assertEqual(effect["graveyard_to_hand_target"], "creature")
        self.assertEqual(effect["graveyard_to_hand_destination"], "battlefield")
        activated = effect["_activated_rule_effects"][0]
        self.assertEqual(activated["xmage_ability_class"], "ActivateAsSorceryActivatedAbility")
        self.assertEqual(activated["activation_timing"], "sorcery")

    def test_permanent_activated_recursion_to_battlefield_maps_protomatter_powder(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Protomatter Powder",
                type_line="Artifact",
                oracle_text="{4}{W}, {T}, Sacrifice this artifact: Return target artifact card from your graveyard to the battlefield.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToBattlefieldTargetEffect(),
                    new ManaCostsImpl<>("{4}{W}")
                );
                ability.addCost(new TapSourceCost());
                ability.addCost(new SacrificeSourceCost());
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_ARTIFACT_FROM_YOUR_GRAVEYARD));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "artifact")
        self.assertEqual(effect["graveyard_to_hand_target"], "artifact")
        self.assertEqual(effect["graveyard_to_hand_destination"], "battlefield")
        self.assertEqual(effect["activation_cost_mana"], "{4}{W}")
        self.assertEqual(effect["activation_cost_generic"], 4)
        self.assertEqual(effect["activation_cost_colors"], ["W"])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])

    def test_permanent_activated_recursion_to_battlefield_maps_sacrifice_target_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Ghen, Arcanum Weaver",
                type_line="Legendary Creature - Human Wizard",
                oracle_text="{R}{W}{B}, {T}, Sacrifice an enchantment: Return target enchantment card from your graveyard to the battlefield.",
            ),
            source_text="""
                private static final FilterControlledPermanent filter
                        = new FilterControlledEnchantmentPermanent("an enchantment");
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToBattlefieldTargetEffect(),
                    new ManaCostsImpl<>("{R}{W}{B}")
                );
                ability.addCost(new TapSourceCost());
                ability.addCost(new SacrificeTargetCost(filter));
                ability.addTarget(new TargetCardInYourGraveyard(new FilterEnchantmentCard()));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_RECURSION_TO_BATTLEFIELD_SCOPE)
        self.assertEqual(effect["graveyard_to_hand_target"], "enchantment")
        self.assertEqual(effect["graveyard_to_hand_destination"], "battlefield")
        self.assertEqual(effect["activation_sacrifice_target"], "enchantment")
        self.assertTrue(effect["activation_requires_sacrifice_target"])
        self.assertEqual(effect["graveyard_to_hand_activation_sacrifice_target"], "enchantment")

    def test_permanent_activated_recursion_to_battlefield_blocks_multi_sacrifice_target_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Whisper, Blood Liturgist",
                type_line="Legendary Creature - Human Cleric",
                oracle_text="{T}, Sacrifice two creatures: Return target creature card from your graveyard to the battlefield.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToBattlefieldTargetEffect(),
                    new TapSourceCost()
                );
                ability.addCost(new SacrificeTargetCost(2, StaticFilters.FILTER_PERMANENT_CREATURES));
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_recursion_battlefield_oracle_cost_not_supported")

    def test_permanent_activated_recursion_to_battlefield_blocks_this_turn_target_window(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Othelm, Sigardian Outcast",
                type_line="Legendary Creature - Human",
                oracle_text="{2}, {T}: Choose target creature card in your graveyard that was put there from the battlefield this turn. Return it to the battlefield tapped.",
            ),
            source_text="""
                FilterCard filter = new FilterCreatureCard("creature card in your graveyard that was put there from the battlefield this turn");
                filter.add(PutIntoGraveFromBattlefieldThisTurnPredicate.instance);
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToBattlefieldTargetEffect(true),
                    new GenericManaCost(2)
                );
                ability.addCost(new TapSourceCost());
                ability.addTarget(new TargetCardInYourGraveyard(filter));
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_recursion_battlefield_source_this_turn_not_supported")

    def test_permanent_activated_graveyard_exile_maps_up_to_three_single_graveyard(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ExileTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Carrion Beetles",
                type_line="Creature - Insect",
                oracle_text="{2}{B}, {T}: Exile up to three target cards from a single graveyard.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(new ExileTargetEffect(), new ManaCostsImpl<>("{2}{B}"));
                ability.addCost(new TapSourceCost());
                ability.addTarget(new TargetCardInASingleGraveyard(0, 3, StaticFilters.FILTER_CARD_CARDS));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_GRAVEYARD_EXILE_SCOPE)
        self.assertEqual(effect["activated_effect"], "graveyard_exile")
        self.assertEqual(effect["graveyard_exile_target"], "any_card")
        self.assertEqual(effect["graveyard_exile_target_count"], 3)
        self.assertTrue(effect["graveyard_exile_up_to_count"])
        self.assertTrue(effect["graveyard_exile_single_graveyard"])
        self.assertEqual(effect["activation_cost_mana"], "{2}{B}")
        self.assertEqual(effect["activation_cost_generic"], 2)
        self.assertEqual(effect["activation_cost_colors"], ["B"])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertFalse(effect["activation_requires_sacrifice"])
        self.assertEqual(effect["_activated_rule_effects"][0]["effect"], "graveyard_exile")

    def test_permanent_activated_graveyard_exile_maps_creature_target_tap_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ExileTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Thraben Heretic",
                type_line="Creature - Human Wizard",
                oracle_text="{T}: Exile target creature card from a graveyard.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(new ExileTargetEffect(), new TapSourceCost());
                ability.addTarget(new TargetCardInGraveyard(StaticFilters.FILTER_CARD_CREATURE_A_GRAVEYARD));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["graveyard_exile_target"], "creature")
        self.assertEqual(effect["graveyard_exile_target_count"], 1)
        self.assertEqual(effect["activation_cost_mana"], "{0}")
        self.assertTrue(effect["activation_requires_tap"])
        self.assertFalse(effect["activation_requires_sacrifice"])
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "any", "card_types": ["creature"]},
        )

    def test_permanent_activated_graveyard_exile_blocks_variable_reveal_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ExileTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Martyr of Bones",
                type_line="Creature - Human Wizard",
                oracle_text="{1}: Exile target card from a graveyard.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(new ExileTargetEffect(), new GenericManaCost(1));
                ability.addCost(new RevealVariableBlackCardsFromHandCost());
                ability.addCost(new SacrificeSourceCost());
                ability.addTarget(new TargetCardInASingleGraveyard(0, 1, new FilterCard("up to X target cards")));
                ability.setTargetAdjuster(new XTargetsCountAdjuster());
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_graveyard_exile_source_cost_not_supported")

    def test_permanent_activated_graveyard_exile_blocks_multiple_abilities(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ExileTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Steamclaw",
                type_line="Artifact",
                oracle_text="{3}: Exile target card from a graveyard.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(new ExileTargetEffect(), new TapSourceCost());
                ability.addCost(new GenericManaCost(3));
                ability.addTarget(new TargetCardInGraveyard());
                this.addAbility(ability);
                ability = new SimpleActivatedAbility(new ExileTargetEffect(), new GenericManaCost(1));
                ability.addCost(new SacrificeSourceCost());
                ability.addTarget(new TargetCardInGraveyard());
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_graveyard_exile_source_multiple_abilities_not_supported")

    def test_graveyard_self_return_mana_only_creature_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnSourceFromGraveyardToHandEffect"],
            ability_kind="graveyard_activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Sanitarium Skeleton",
                type_line="Creature - Skeleton",
                oracle_text="{2}{B}: Return this card from your graveyard to your hand.",
            ),
            source_text="""
                this.addAbility(new SimpleActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToHandEffect(),
                    new ManaCostsImpl<>("{2}{B}")
                ));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.GRAVEYARD_SELF_RETURN_TO_HAND_SCOPE)
        self.assertTrue(effect["graveyard_self_return_to_hand"])
        self.assertEqual(effect["activation_cost_mana"], "{2}{B}")
        self.assertEqual(effect["activation_cost_generic"], 2)
        self.assertEqual(effect["activation_cost_colors"], ["B"])
        self.assertEqual(effect["source_zone"], "graveyard")
        self.assertEqual(effect["destination"], "hand")

    def test_graveyard_self_return_to_hand_accepts_discard_creature_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnSourceFromGraveyardToHandEffect"],
            ability_kind="graveyard_activated",
            ability_classes=["FlyingAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Kraul Swarm",
                type_line="Creature - Insect Warrior",
                oracle_text=(
                    "Flying\n"
                    "{2}{B}, Discard a creature card: Return this card from your graveyard to your hand."
                ),
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                Ability ability = new SimpleActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToHandEffect(),
                    new ManaCostsImpl<>("{2}{B}")
                );
                ability.addCost(new DiscardTargetCost(
                    new TargetCardInHand(StaticFilters.FILTER_CARD_CREATURE_A)
                ));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.GRAVEYARD_SELF_RETURN_TO_HAND_SCOPE)
        self.assertEqual(effect["activation_cost_mana"], "{2}{B}")
        self.assertEqual(effect["activation_cost_generic"], 2)
        self.assertEqual(effect["activation_cost_colors"], ["B"])
        self.assertEqual(effect["graveyard_self_return_activation_discard_count"], 1)
        self.assertEqual(effect["graveyard_self_return_activation_discard_target"], "creature_card")
        self.assertEqual(effect["activation_discard_count"], 1)
        self.assertEqual(effect["activation_discard_target"], "creature_card")
        self.assertEqual(effect["activation_additional_cost"], "discard_cards")
        self.assertEqual(effect["keywords"], ["flying"])

    def test_graveyard_self_return_to_hand_accepts_activate_as_sorcery_mana_only(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnSourceFromGraveyardToHandEffect"],
            ability_kind="graveyard_activated",
            ability_classes=["ActivateAsSorceryActivatedAbility", "VigilanceAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Summoned Dromedary",
                type_line="Creature - Spirit Camel",
                oracle_text=(
                    "Vigilance\n"
                    "{1}{W}: Return this card from your graveyard to your hand. Activate only as a sorcery."
                ),
            ),
            source_text="""
                this.addAbility(VigilanceAbility.getInstance());
                this.addAbility(new ActivateAsSorceryActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToHandEffect(),
                    new ManaCostsImpl<>("{1}{W}")
                ));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["activation_cost_mana"], "{1}{W}")
        self.assertEqual(effect["activation_cost_generic"], 1)
        self.assertEqual(effect["activation_cost_colors"], ["W"])
        self.assertEqual(effect["activation_timing"], "sorcery")
        self.assertEqual(effect["xmage_ability_class"], "ActivateAsSorceryActivatedAbility")
        self.assertEqual(effect["keywords"], ["vigilance"])

    def test_graveyard_self_return_to_hand_blocks_discard_target_mismatch(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnSourceFromGraveyardToHandEffect"],
            ability_kind="graveyard_activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Kraul Swarm",
                type_line="Creature - Insect Warrior",
                oracle_text="{2}{B}, Discard a creature card: Return this card from your graveyard to your hand.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToHandEffect(),
                    new ManaCostsImpl<>("{2}{B}")
                );
                ability.addCost(new DiscardTargetCost(new TargetCardInHand(1, StaticFilters.FILTER_CARD_CARDS)));
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "graveyard_self_return_source_cost_not_supported")

    def test_graveyard_self_return_preserves_static_keyword_and_enters_tapped(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnSourceFromGraveyardToHandEffect"],
            ability_kind="graveyard_activated",
            ability_classes=["FlyingAbility", "SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Firewing Phoenix",
                type_line="Creature - Phoenix",
                oracle_text="Flying\n{1}{R}{R}{R}: Return this card from your graveyard to your hand.",
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                this.addAbility(new SimpleActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToHandEffect(),
                    new ManaCostsImpl<>("{1}{R}{R}{R}")
                ));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertEqual(effect["activation_cost_colors"], ["R", "R", "R"])

        row["xmage_ability_classes"] = ["EntersBattlefieldTappedAbility", "SimpleActivatedAbility"]
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Clay Revenant",
                type_line="Artifact Creature - Golem",
                oracle_text="This creature enters tapped.\n{2}{B}: Return this card from your graveyard to your hand.",
            ),
            source_text="""
                this.addAbility(new EntersBattlefieldTappedAbility());
                this.addAbility(new SimpleActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToHandEffect(),
                    new ManaCostsImpl<>("{2}{B}")
                ));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertTrue(proposal["effect_json"]["enters_tapped"])

    def test_graveyard_self_return_to_battlefield_mana_only_creature_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnSourceFromGraveyardToBattlefieldEffect"],
            ability_kind="graveyard_activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Reassembling Skeleton",
                type_line="Creature - Skeleton Warrior",
                oracle_text="{1}{B}: Return this card from your graveyard to the battlefield tapped.",
            ),
            source_text="""
                this.addAbility(new SimpleActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToBattlefieldEffect(true, false),
                    new ManaCostsImpl<>("{1}{B}")
                ));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.GRAVEYARD_SELF_RETURN_TO_BATTLEFIELD_SCOPE)
        self.assertTrue(effect["graveyard_self_return_to_battlefield"])
        self.assertEqual(effect["graveyard_self_return_destination"], "battlefield")
        self.assertEqual(effect["activation_cost_mana"], "{1}{B}")
        self.assertEqual(effect["activation_cost_generic"], 1)
        self.assertEqual(effect["activation_cost_colors"], ["B"])
        self.assertEqual(effect["source_zone"], "graveyard")
        self.assertEqual(effect["destination"], "battlefield")
        self.assertTrue(effect["enters_tapped"])

    def test_graveyard_self_return_to_battlefield_discard_two_cards_is_package_safe(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnSourceFromGraveyardToBattlefieldEffect"],
            ability_kind="graveyard_activated",
            ability_classes=["FlyingAbility", "SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Advanced Stitchwing",
                type_line="Creature - Zombie Horror",
                oracle_text=(
                    "Flying\n"
                    "{2}{U}, Discard two cards: Return this card from your graveyard to the battlefield tapped."
                ),
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                Ability ability = new SimpleActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToBattlefieldEffect(true, false),
                    new ManaCostsImpl<>("{2}{U}")
                );
                ability.addCost(new DiscardTargetCost(new TargetCardInHand(2, StaticFilters.FILTER_CARD_CARDS)));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.GRAVEYARD_SELF_RETURN_TO_BATTLEFIELD_SCOPE)
        self.assertTrue(effect["graveyard_self_return_to_battlefield"])
        self.assertEqual(effect["graveyard_self_return_destination"], "battlefield")
        self.assertEqual(effect["activation_cost_mana"], "{2}{U}")
        self.assertEqual(effect["activation_cost_generic"], 2)
        self.assertEqual(effect["activation_cost_colors"], ["U"])
        self.assertEqual(effect["graveyard_self_return_activation_discard_count"], 2)
        self.assertEqual(effect["activation_discard_count"], 2)
        self.assertEqual(effect["activation_discard_target"], "any_card")
        self.assertEqual(effect["activation_additional_cost"], "discard_cards")
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["enters_tapped"])

    def test_graveyard_self_return_to_battlefield_blocks_source_oracle_tapped_mismatch(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnSourceFromGraveyardToBattlefieldEffect"],
            ability_kind="graveyard_activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Skeleton",
                type_line="Creature - Skeleton",
                oracle_text="{1}{B}: Return this card from your graveyard to the battlefield tapped.",
            ),
            source_text="""
                this.addAbility(new SimpleActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToBattlefieldEffect(false, false),
                    new ManaCostsImpl<>("{1}{B}")
                ));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "graveyard_self_return_battlefield_source_oracle_mismatch")

    def test_graveyard_self_return_to_battlefield_accepts_exile_other_graveyard_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnSourceFromGraveyardToBattlefieldEffect"],
            ability_kind="graveyard_activated",
            ability_classes=["FlyingAbility", "SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Bone Dragon",
                type_line="Creature - Dragon Skeleton",
                oracle_text=(
                    "Flying\n"
                    "{3}{B}{B}, Exile seven other cards from your graveyard: "
                    "Return this card from your graveyard to the battlefield tapped."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard("other cards");
                static {
                    filter.add(AnotherPredicate.instance);
                }
                this.addAbility(FlyingAbility.getInstance());
                Ability ability = new SimpleActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToBattlefieldEffect(true, false),
                    new ManaCostsImpl<>("{3}{B}{B}")
                );
                ability.addCost(new ExileFromGraveCost(new TargetCardInYourGraveyard(7, filter)));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.GRAVEYARD_SELF_RETURN_TO_BATTLEFIELD_SCOPE)
        self.assertTrue(effect["graveyard_self_return_to_battlefield"])
        self.assertEqual(effect["activation_cost_mana"], "{3}{B}{B}")
        self.assertEqual(effect["activation_cost_generic"], 3)
        self.assertEqual(effect["activation_cost_colors"], ["B", "B"])
        self.assertEqual(effect["graveyard_self_return_activation_exile_from_graveyard_count"], 7)
        self.assertEqual(effect["graveyard_self_return_activation_exile_from_graveyard_target"], "any_card")
        self.assertTrue(effect["graveyard_self_return_activation_exile_from_graveyard_other"])
        self.assertEqual(effect["activation_additional_cost"], "exile_from_graveyard")
        self.assertTrue(effect["enters_tapped"])
        self.assertEqual(effect["keywords"], ["flying"])

    def test_graveyard_self_return_to_battlefield_accepts_exile_another_creature_and_cant_block(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnSourceFromGraveyardToBattlefieldEffect"],
            ability_kind="graveyard_activated",
            ability_classes=["CantBlockAbility", "SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Scrapheap Scrounger",
                type_line="Artifact Creature - Construct",
                oracle_text=(
                    "Scrapheap Scrounger can't block.\n"
                    "{1}{B}, Exile another creature card from your graveyard: "
                    "Return this card from your graveyard to the battlefield."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterCreatureCard("another creature card");
                static {
                    filter.add(AnotherPredicate.instance);
                }
                this.addAbility(new CantBlockAbility());
                Ability ability = new SimpleActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToBattlefieldEffect(false, false),
                    new ManaCostsImpl<>("{1}{B}")
                );
                ability.addCost(new ExileFromGraveCost(new TargetCardInYourGraveyard(filter)));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["activation_cost_mana"], "{1}{B}")
        self.assertEqual(effect["activation_cost_generic"], 1)
        self.assertEqual(effect["activation_cost_colors"], ["B"])
        self.assertEqual(effect["graveyard_self_return_activation_exile_from_graveyard_count"], 1)
        self.assertEqual(effect["graveyard_self_return_activation_exile_from_graveyard_target"], "creature_card")
        self.assertTrue(effect["graveyard_self_return_activation_exile_from_graveyard_other"])
        self.assertEqual(effect["activation_exile_from_graveyard_count"], 1)
        self.assertEqual(effect["activation_exile_from_graveyard_target"], "creature_card")
        self.assertEqual(effect["activation_additional_cost"], "exile_from_graveyard")
        self.assertFalse(effect["enters_tapped"])
        self.assertTrue(effect["cant_block"])
        self.assertTrue(effect["static_cant_block"])

    def test_graveyard_self_return_to_battlefield_blocks_exile_cost_without_other_predicate(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnSourceFromGraveyardToBattlefieldEffect"],
            ability_kind="graveyard_activated",
            ability_classes=["FlyingAbility", "SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Bone Dragon",
                type_line="Creature - Dragon Skeleton",
                oracle_text=(
                    "Flying\n"
                    "{3}{B}{B}, Exile seven other cards from your graveyard: "
                    "Return this card from your graveyard to the battlefield tapped."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard("cards");
                this.addAbility(FlyingAbility.getInstance());
                Ability ability = new SimpleActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToBattlefieldEffect(true, false),
                    new ManaCostsImpl<>("{3}{B}{B}")
                );
                ability.addCost(new ExileFromGraveCost(new TargetCardInYourGraveyard(7, filter)));
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "graveyard_self_return_battlefield_source_cost_not_supported")

    def test_graveyard_self_return_blocks_additional_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnSourceFromGraveyardToHandEffect"],
            ability_kind="graveyard_activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Dutiful Griffin",
                type_line="Creature - Griffin",
                oracle_text="Flying\n{2}{W}, Sacrifice two enchantments: Return this card from your graveyard to your hand.",
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    Zone.GRAVEYARD,
                    new ReturnSourceFromGraveyardToHandEffect(),
                    new ManaCostsImpl<>("{2}{W}")
                );
                ability.addCost(new SacrificeTargetCost(new TargetControlledPermanent(2, 2, filter, true)));
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "graveyard_self_return_oracle_not_simple")

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

    def test_board_wipe_selective_toughness_scope_maps_to_constraints(self) -> None:
        row = queue_row(split.BOARD_WIPE_UNIT, effect_classes=["DestroyAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy all creatures with toughness 4 or greater."),
            source_text="this.getSpellAbility().addEffect(new DestroyAllEffect(filter));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "board_wipe")
        self.assertEqual(effect["destroy_card_types"], ["creature"])
        self.assertEqual(effect["destroy_toughness_gte"], 4)

    def test_board_wipe_land_subtype_scope_maps_to_constraints(self) -> None:
        row = queue_row(split.BOARD_WIPE_UNIT, effect_classes=["DestroyAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy all Islands."),
            source_text="this.getSpellAbility().addEffect(new DestroyAllEffect(filter));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["destroy_card_types"], ["land"])
        self.assertEqual(effect["destroy_required_subtypes"], ["island"])

        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy all Plains."),
            source_text="this.getSpellAbility().addEffect(new DestroyAllEffect(filter));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertEqual(proposal["effect_json"]["destroy_required_subtypes"], ["plains"])

    def test_board_wipe_color_and_controller_scopes_map_to_constraints(self) -> None:
        row = queue_row(split.BOARD_WIPE_UNIT, effect_classes=["DestroyAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy all green creatures."),
            source_text="this.getSpellAbility().addEffect(new DestroyAllEffect(filter));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertEqual(proposal["effect_json"]["destroy_required_colors"], ["G"])

        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy all creatures you don't control."),
            source_text="this.getSpellAbility().addEffect(new DestroyAllEffect(filter, true));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertEqual(proposal["effect_json"]["destroy_controller"], "opponents_control")

    def test_board_wipe_source_modal_stays_blocked(self) -> None:
        row = queue_row(split.BOARD_WIPE_UNIT, effect_classes=["DestroyAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Destroy all creatures."),
            source_text=(
                "this.getSpellAbility().addEffect(new DestroyAllEffect(filter));"
                "this.getSpellAbility().addMode(new Mode(new DestroyAllEffect(filter2)));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "board_wipe_source_multiple_destroy_all_effects")

    def test_damage_wipe_flying_scope_maps_and_dynamic_source_blocks(self) -> None:
        row = queue_row(split.BOARD_WIPE_UNIT, effect_classes=["DamageAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Gale Force deals 5 damage to each creature with flying."),
            source_text="this.getSpellAbility().addEffect(new DamageAllEffect(5, StaticFilters.FILTER_CREATURE_FLYING));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        self.assertEqual(proposal["effect_json"]["damage_scope"], "each_flying_creature")

        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Windstorm deals X damage to each creature with flying."),
            source_text="this.getSpellAbility().addEffect(new DamageAllEffect(GetXValue.instance, StaticFilters.FILTER_CREATURE_FLYING));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "board_wipe_damage_amount_not_fixed")

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

    def test_activated_self_add_counter_maps_to_source_counter_runtime(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_SOURCE_UNIT,
            effect_classes=["AddCountersSourceEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["counter", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Carnivorous Moss-Beast",
                type_line="Creature - Plant Elemental Beast",
                oracle_text="{5}{G}{G}: Put a +1/+1 counter on Carnivorous Moss-Beast.",
            ),
            source_text=(
                "this.addAbility(new SimpleActivatedAbility("
                "new AddCountersSourceEffect(CounterType.P1P1.createInstance()), "
                "new ManaCostsImpl<>(\"{5}{G}{G}\")));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_SELF_ADD_COUNTERS_SCOPE)
        self.assertTrue(effect["activated_add_counters"])
        self.assertEqual(effect["activated_add_counters_target"], "self")
        self.assertEqual(effect["activated_add_counters_counter_type"], "+1/+1")
        self.assertEqual(effect["activated_add_counters_count"], 1)
        self.assertEqual(effect["counter_count"], 1)
        self.assertEqual(effect["activation_cost_mana"], "{5}{G}{G}")

    def test_activated_self_add_counter_preserves_static_keyword(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_SOURCE_UNIT,
            effect_classes=["AddCountersSourceEffect"],
            ability_kind="activated",
            ability_classes=["FlyingAbility", "SimpleActivatedAbility"],
            xmage_signals=["counter", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Jenara, Asura of War",
                type_line="Legendary Creature - Angel",
                oracle_text="Flying\n{1}{W}: Put a +1/+1 counter on Jenara.",
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "this.addAbility(new SimpleActivatedAbility("
                "new AddCountersSourceEffect(CounterType.P1P1.createInstance()), "
                "new ManaCostsImpl<>(\"{1}{W}\")));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertEqual(effect["activation_cost_mana"], "{1}{W}")

    def test_activated_self_add_counter_with_sacrifice_cost_stays_blocked(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_SOURCE_UNIT,
            effect_classes=["AddCountersSourceEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["counter", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Bloodflow Connoisseur",
                type_line="Creature - Vampire",
                oracle_text="Sacrifice a creature: Put a +1/+1 counter on Bloodflow Connoisseur.",
            ),
            source_text=(
                "Cost abilityCost = new SacrificeTargetCost(StaticFilters.FILTER_PERMANENT_CREATURE);"
                "Ability ability = new SimpleActivatedAbility("
                "new AddCountersSourceEffect(CounterType.P1P1.createInstance()), abilityCost);"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_self_add_counters_source_cost_not_supported")

    def test_creature_etb_plus_one_counter_target_creature_maps_to_etb_scope(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_TARGET_UNIT,
            effect_classes=["AddCountersTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Creature - Insect",
                oracle_text=(
                    "When this creature enters, put a +1/+1 counter on target creature."
                ),
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new AddCountersTargetEffect(CounterType.P1P1.createInstance()));"
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_ADD_COUNTERS_CREATURE_SCOPE)
        self.assertEqual(effect["etb_add_counters_counter_type"], "+1/+1")
        self.assertEqual(effect["etb_add_counters_count"], 1)
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"]})

    def test_creature_etb_counter_with_self_keyword_preserves_keyword(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_TARGET_UNIT,
            effect_classes=["AddCountersTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Creature - Bird",
                oracle_text=(
                    "Flying\n"
                    "When this creature enters, put a +1/+1 counter on target creature."
                ),
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new AddCountersTargetEffect(CounterType.P1P1.createInstance()));"
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["_keywords_are_self"])

    def test_creature_etb_minus_one_counter_target_creature_you_control_maps_self_target(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_TARGET_UNIT,
            effect_classes=["AddCountersTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "LifelinkAbility"],
            xmage_signals=["targeting", "counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Baleful Ammit",
                type_line="Creature - Crocodile Demon",
                oracle_text=(
                    "Lifelink\n"
                    "When this creature enters, put a -1/-1 counter on target creature you control."
                ),
            ),
            source_text=(
                "this.addAbility(LifelinkAbility.getInstance());"
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new AddCountersTargetEffect(CounterType.M1M1.createInstance(1)));"
                "ability.addTarget(new TargetControlledCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ETB_ADD_COUNTERS_CREATURE_SCOPE)
        self.assertEqual(effect["etb_add_counters_counter_type"], "-1/-1")
        self.assertEqual(effect["etb_add_counters_count"], 1)
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "controller_scope": "self"})
        self.assertEqual(effect["keywords"], ["lifelink"])

    def test_creature_etb_up_to_two_other_controlled_counters_maps_multi_target(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_TARGET_UNIT,
            effect_classes=["AddCountersTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "LifelinkAbility"],
            xmage_signals=["targeting", "counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Basri's Acolyte",
                type_line="Creature - Cat Cleric",
                oracle_text=(
                    "Lifelink\n"
                    "When this creature enters, put a +1/+1 counter on each of up to two "
                    "other target creatures you control."
                ),
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new AddCountersTargetEffect(CounterType.P1P1.createInstance())"
                ".setText(\"put a +1/+1 counter on each of up to two other target creatures you control\"));"
                "ability.addTarget(new TargetPermanent(0, 2, StaticFilters.FILTER_OTHER_CONTROLLED_CREATURES, false));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(effect["target_count_min"], 0)
        self.assertEqual(effect["target_count_max"], 2)
        self.assertTrue(effect["up_to_count"])
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "controller_scope": "self", "exclude_source": True},
        )

    def test_creature_etb_counter_another_controlled_subtype_maps_constraints(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_TARGET_UNIT,
            effect_classes=["AddCountersTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Aeronaut Cavalry",
                type_line="Creature - Human Soldier",
                oracle_text=(
                    "Flying\n"
                    "When this creature enters, put a +1/+1 counter on another target Soldier you control."
                ),
            ),
            source_text=(
                "private static final FilterPermanent filter = "
                "new FilterControlledPermanent(SubType.SOLDIER, \"another target Soldier you control\");"
                "static { filter.add(AnotherPredicate.instance); }"
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new AddCountersTargetEffect(CounterType.P1P1.createInstance()));"
                "ability.addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(
            effect["target_constraints"],
            {
                "card_types": ["creature"],
                "controller_scope": "self",
                "exclude_source": True,
                "required_subtypes": ["soldier"],
            },
        )

    def test_creature_etb_counter_controlled_without_flying_maps_excluded_keyword(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_TARGET_UNIT,
            effect_classes=["AddCountersTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Pileated Provisioner",
                type_line="Creature - Bird Scout",
                oracle_text=(
                    "Flying\n"
                    "When this creature enters, put a +1/+1 counter on target creature you control without flying."
                ),
            ),
            source_text=(
                "private static final FilterPermanent filter = "
                "new FilterControlledCreaturePermanent(\"creature you control without flying\");"
                "static { filter.add(Predicates.not(new AbilityPredicate(FlyingAbility.class))); }"
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new AddCountersTargetEffect(CounterType.P1P1.createInstance()));"
                "ability.addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(
            effect["target_constraints"],
            {
                "card_types": ["creature"],
                "controller_scope": "self",
                "excluded_keywords": ["flying"],
            },
        )

    def test_creature_etb_three_minus_one_counters_target_creature_maps_fixed_count(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_TARGET_UNIT,
            effect_classes=["AddCountersTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Skinrender",
                type_line="Creature - Phyrexian Zombie",
                oracle_text="When this creature enters, put three -1/-1 counters on target creature.",
            ),
            source_text=(
                "Effect putCountersEffect = new AddCountersTargetEffect("
                "CounterType.M1M1.createInstance(3), Outcome.UnboostCreature);"
                "Ability ability = new EntersBattlefieldTriggeredAbility(putCountersEffect, false);"
                "Target target = new TargetCreaturePermanent();"
                "ability.addTarget(target);"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_add_counters_counter_type"], "-1/-1")
        self.assertEqual(effect["etb_add_counters_count"], 3)
        self.assertEqual(effect["target_controller"], "any")

    def test_creature_etb_minus_one_counter_after_reminder_text_maps_to_etb_scope(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_TARGET_UNIT,
            effect_classes=["AddCountersTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Artifact Creature - Phyrexian Horror",
                oracle_text=(
                    "({B/P} can be paid with either {B} or 2 life.)\n"
                    "When this creature enters, put a -1/-1 counter on target creature."
                ),
            ),
            source_text=(
                "EntersBattlefieldTriggeredAbility ability = new EntersBattlefieldTriggeredAbility("
                "new AddCountersTargetEffect(CounterType.M1M1.createInstance()));"
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_add_counters_counter_type"], "-1/-1")
        self.assertEqual(effect["etb_add_counters_count"], 1)

    def test_creature_etb_counter_source_oracle_controller_mismatch_stays_blocked(self) -> None:
        row = queue_row(
            split.ADD_COUNTERS_TARGET_UNIT,
            effect_classes=["AddCountersTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "counter", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                type_line="Creature - Angel Soldier",
                oracle_text=(
                    "When Angelic Quartermaster enters the battlefield, put a +1/+1 counter "
                    "on each of up to two other target creatures."
                ),
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new AddCountersTargetEffect(CounterType.P1P1.createInstance()));"
                "ability.addTarget(new TargetPermanent(0, 2, StaticFilters.FILTER_CONTROLLED_ANOTHER_CREATURE));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_add_counters_source_oracle_mismatch")

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

    def test_dynamic_graveyard_count_boost_maps_festive_funeral(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["BoostTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Festive Funeral",
                type_line="Instant",
                oracle_text=(
                    "Target creature gets -X/-X until end of turn, where X is the number of cards in your graveyard."
                ),
            ),
            source_text="""
                private static final DynamicValue cardsInGraveyard = new CardsInControllerGraveyardCount(
                    StaticFilters.FILTER_CARD_CARDS, null
                );
                private static final DynamicValue xValue = new SignInversionDynamicValue(cardsInGraveyard);
                this.getSpellAbility().addEffect(new BoostTargetEffect(xValue, xValue, Duration.EndOfTurn));
                this.getSpellAbility().addTarget(new TargetCreaturePermanent());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DYNAMIC_GRAVEYARD_COUNT_BOOST_TARGET_SCOPE)
        self.assertEqual(effect["stat_modifier_amount_source"], "graveyard_card_count")
        self.assertEqual(effect["graveyard_count_card_types"], ["card"])
        self.assertEqual(effect["power_delta_per_graveyard_count"], -1)
        self.assertEqual(effect["toughness_delta_per_graveyard_count"], -1)

    def test_dynamic_graveyard_count_boost_maps_ghouls_feast(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["BoostTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Ghoul's Feast",
                type_line="Instant",
                oracle_text=(
                    "Target creature gets +X/+0 until end of turn, where X is the number of creature cards in your graveyard."
                ),
            ),
            source_text="""
                private static final DynamicValue xValue = new CardsInControllerGraveyardCount(
                    StaticFilters.FILTER_CARD_CREATURES, null
                );
                this.getSpellAbility().addEffect(new BoostTargetEffect(
                    xValue, StaticValue.get(0), Duration.EndOfTurn
                ));
                this.getSpellAbility().addTarget(new TargetCreaturePermanent());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["graveyard_count_card_types"], ["creature"])
        self.assertEqual(effect["power_delta_per_graveyard_count"], 1)
        self.assertEqual(effect["toughness_delta_per_graveyard_count"], 0)

    def test_dynamic_graveyard_count_boost_blocks_growth_cycle_composite(self) -> None:
        row = queue_row(split.RECURSION_UNIT, effect_classes=["BoostTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Growth Cycle",
                type_line="Instant",
                oracle_text=(
                    "Target creature gets +3/+3 until end of turn. It gets an additional +2/+2 until end of turn "
                    "for each card named Growth Cycle in your graveyard."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new BoostTargetEffect(3, 3, Duration.EndOfTurn));
                this.getSpellAbility().addEffect(new BoostTargetEffect(xValue, xValue, Duration.EndOfTurn));
                this.getSpellAbility().addTarget(new TargetCreaturePermanent());
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "graveyard_count_boost_source_not_single")

    def test_dynamic_count_boost_maps_defile_controlled_swamps(self) -> None:
        row = queue_row(split.BOOST_TARGET_UNIT, effect_classes=["BoostTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Defile",
                type_line="Instant",
                oracle_text="Target creature gets -1/-1 until end of turn for each Swamp you control.",
            ),
            source_text="""
                private static final FilterPermanent filter = new FilterControlledPermanent(SubType.SWAMP, "Swamp you control");
                private static final DynamicValue xValue = new PermanentsOnBattlefieldCount(filter, -1);
                this.getSpellAbility().addEffect(new BoostTargetEffect(xValue, xValue, Duration.EndOfTurn));
                this.getSpellAbility().addTarget(new TargetCreaturePermanent());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DYNAMIC_COUNT_BOOST_TARGET_SCOPE)
        self.assertEqual(effect["stat_modifier_amount_source"], "battlefield_permanent_count")
        self.assertEqual(effect["battlefield_count_scope"], "controller_battlefield")
        self.assertEqual(effect["battlefield_count_card_types"], ["land"])
        self.assertEqual(effect["battlefield_count_subtypes"], ["swamp"])
        self.assertEqual(effect["power_delta_per_graveyard_count"], -1)
        self.assertEqual(effect["toughness_delta_per_graveyard_count"], -1)

    def test_dynamic_count_boost_maps_hunger_plus_zero_artifacts(self) -> None:
        row = queue_row(split.BOOST_TARGET_UNIT, effect_classes=["BoostTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Hunger of the Nim",
                type_line="Instant",
                oracle_text="Target creature gets +1/+0 until end of turn for each artifact you control.",
            ),
            source_text="""
                getSpellAbility().addEffect(new BoostTargetEffect(
                    ArtifactYouControlCount.instance, StaticValue.get(0), Duration.EndOfTurn
                ));
                this.getSpellAbility().addTarget(new TargetCreaturePermanent());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battlefield_count_card_types"], ["artifact"])
        self.assertEqual(effect["power_delta_per_graveyard_count"], 1)
        self.assertEqual(effect["toughness_delta_per_graveyard_count"], 0)

    def test_dynamic_count_boost_maps_domain_spell(self) -> None:
        row = queue_row(split.BOOST_TARGET_UNIT, effect_classes=["BoostTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Gaea's Might",
                type_line="Instant",
                oracle_text=(
                    "Domain — Target creature gets +1/+1 until end of turn for each basic land type among lands you control."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new BoostTargetEffect(
                    DomainValue.REGULAR, DomainValue.REGULAR, Duration.EndOfTurn
                ));
                this.getSpellAbility().addTarget(new TargetCreaturePermanent());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["stat_modifier_amount_source"], "domain_basic_land_types")
        self.assertEqual(effect["power_delta_per_graveyard_count"], 1)
        self.assertEqual(effect["toughness_delta_per_graveyard_count"], 1)

    def test_dynamic_count_boost_maps_deserts_due_base_plus_deserts(self) -> None:
        row = queue_row(split.BOOST_TARGET_UNIT, effect_classes=["BoostTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Desert's Due",
                type_line="Instant",
                oracle_text=(
                    "Target creature gets -2/-2 until end of turn. "
                    "It gets an additional -1/-1 until end of turn for each Desert you control."
                ),
            ),
            source_text="""
                private static final DynamicValue desertCount = new PermanentsOnBattlefieldCount(
                    new FilterControlledPermanent(SubType.DESERT)
                );
                private static final DynamicValue xValue = new AdditiveDynamicValue(
                    new SignInversionDynamicValue(desertCount), StaticValue.get(-2)
                );
                this.getSpellAbility().addEffect(new BoostTargetEffect(xValue, xValue));
                this.getSpellAbility().addTarget(new TargetCreaturePermanent());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["power_base_delta"], -2)
        self.assertEqual(effect["toughness_base_delta"], -2)
        self.assertEqual(effect["battlefield_count_subtypes"], ["desert"])

    def test_dynamic_count_boost_maps_wirewood_pride_elves_plural(self) -> None:
        row = queue_row(split.BOOST_TARGET_UNIT, effect_classes=["BoostTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Wirewood Pride",
                type_line="Instant",
                oracle_text=(
                    "Target creature gets +X/+X until end of turn, where X is the number of Elves on the battlefield."
                ),
            ),
            source_text="""
                private static final DynamicValue xValue = new PermanentsOnBattlefieldCount(
                    new FilterPermanent(SubType.ELF, "Elves on the battlefield"), null
                );
                this.getSpellAbility().addEffect(new BoostTargetEffect(xValue, xValue, Duration.EndOfTurn));
                this.getSpellAbility().addTarget(new TargetCreaturePermanent());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battlefield_count_scope"], "all_battlefields")
        self.assertEqual(effect["battlefield_count_subtypes"], ["elf"])

    def test_dynamic_count_boost_maps_feeding_frenzy_zombies_plural(self) -> None:
        row = queue_row(split.BOOST_TARGET_UNIT, effect_classes=["BoostTargetEffect"], xmage_signals=["targeting"])
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Feeding Frenzy",
                type_line="Instant",
                oracle_text=(
                    "Target creature gets -X/-X until end of turn, where X is the number of Zombies on the battlefield."
                ),
            ),
            source_text="""
                private static final DynamicValue xValue = new SignInversionDynamicValue(
                    new PermanentsOnBattlefieldCount(new FilterPermanent(SubType.ZOMBIE, "Zombies on the battlefield"), null)
                );
                this.getSpellAbility().addEffect(new BoostTargetEffect(xValue, xValue, Duration.EndOfTurn));
                this.getSpellAbility().addTarget(new TargetCreaturePermanent());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battlefield_count_scope"], "all_battlefields")
        self.assertEqual(effect["battlefield_count_subtypes"], ["zombie"])
        self.assertEqual(effect["power_delta_per_graveyard_count"], -1)

    def test_fixed_boost_controlled_creatures_spell_maps_to_controlled_stat_modifier(self) -> None:
        row = queue_row(split.BOOST_CONTROLLED_SPELL_UNIT, effect_classes=["BoostControlledEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Creatures you control get +2/+0 until end of turn."),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostControlledEffect("
                "2, 0, Duration.EndOfTurn, StaticFilters.FILTER_PERMANENT_CREATURES, false));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "controlled_stat_modifier_until_eot")
        self.assertEqual(effect["battle_model_scope"], split.BOOST_CONTROLLED_SPELL_SCOPE)
        self.assertEqual(effect["target"], "controlled_creatures")
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(effect["power_delta"], 2)
        self.assertEqual(effect["toughness_delta"], 0)

    def test_boost_controlled_color_filter_stays_blocked(self) -> None:
        row = queue_row(split.BOOST_CONTROLLED_SPELL_UNIT, effect_classes=["BoostControlledEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="White creatures you control get +2/+2 until end of turn."),
            source_text=(
                "filter.add(new ColorPredicate(ObjectColor.WHITE));"
                "this.getSpellAbility().addEffect(new BoostControlledEffect("
                "2, 2, Duration.EndOfTurn, filter, false));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "boost_controlled_source_filter_not_supported")

    def test_boost_controlled_modal_spell_stays_blocked(self) -> None:
        row = queue_row(split.BOOST_CONTROLLED_SPELL_UNIT, effect_classes=["BoostControlledEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Choose one — • Creatures you control get +2/+0 until end of turn. "
                    "• Creatures you control get +0/+2 until end of turn."
                )
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostControlledEffect(2, 0, Duration.EndOfTurn));"
                "this.getSpellAbility().addEffect(new BoostControlledEffect(0, 2, Duration.EndOfTurn));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "boost_controlled_source_not_single_fixed")

    def test_fixed_boost_all_creatures_spell_maps_to_global_modifier(self) -> None:
        row = queue_row(split.BOOST_ALL_SPELL_UNIT, effect_classes=["BoostAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="All creatures get -2/-2 until end of turn."),
            source_text="this.getSpellAbility().addEffect(new BoostAllEffect(-2, -2, Duration.EndOfTurn));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "global_stat_modifier_until_eot")
        self.assertEqual(effect["battle_model_scope"], split.BOOST_ALL_SPELL_SCOPE)
        self.assertEqual(effect["target"], "all_creatures")
        self.assertEqual(effect["target_controller"], "all")
        self.assertEqual(effect["power_delta"], -2)
        self.assertEqual(effect["toughness_delta"], -2)

    def test_fixed_boost_opponents_creatures_spell_maps_to_global_modifier(self) -> None:
        row = queue_row(split.BOOST_ALL_SPELL_UNIT, effect_classes=["BoostAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Creatures your opponents control get -1/-1 until end of turn."),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostAllEffect("
                "-1, -1, Duration.EndOfTurn, StaticFilters.FILTER_OPPONENTS_PERMANENT_CREATURES, false));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "opponents_creatures")
        self.assertEqual(effect["target_controller"], "opponents")

    def test_fixed_boost_attacking_creatures_spell_maps_to_filtered_global_modifier(self) -> None:
        row = queue_row(split.BOOST_ALL_SPELL_UNIT, effect_classes=["BoostAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Attacking creatures get +2/+0 until end of turn."),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostAllEffect("
                "2, 0, Duration.EndOfTurn, StaticFilters.FILTER_ATTACKING_CREATURES, false));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.BOOST_ALL_FILTERED_SPELL_SCOPE)
        self.assertEqual(effect["target"], "attacking_creatures")
        self.assertEqual(effect["creature_filter"], {"combat_state": "attacking"})

    def test_fixed_boost_non_elf_creatures_spell_maps_to_filtered_global_modifier(self) -> None:
        row = queue_row(split.BOOST_ALL_SPELL_UNIT, effect_classes=["BoostAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Non-Elf creatures get -2/-2 until end of turn."),
            source_text=(
                "private static final FilterCreaturePermanent filter = new FilterCreaturePermanent(\"Non-Elf creatures\");"
                "static { filter.add(Predicates.not(SubType.ELF.getPredicate())); }"
                "this.getSpellAbility().addEffect(new BoostAllEffect(-2, -2, Duration.EndOfTurn, filter, false));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.BOOST_ALL_FILTERED_SPELL_SCOPE)
        self.assertEqual(effect["target"], "non_elf_creatures")
        self.assertEqual(effect["creature_filter"], {"exclude_subtypes": ["Elf"]})

    def test_fixed_boost_creatures_with_no_counters_spell_maps_to_filtered_global_modifier(self) -> None:
        row = queue_row(split.BOOST_ALL_SPELL_UNIT, effect_classes=["BoostAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Creatures with no counters on them get -2/-2 until end of turn."),
            source_text=(
                "private static final FilterCreaturePermanent filter = new FilterCreaturePermanent(\"creatures with no counters on them\");"
                "static { filter.add(Predicates.not(CounterAnyPredicate.instance)); }"
                "this.getSpellAbility().addEffect(new BoostAllEffect(-2, -2, Duration.EndOfTurn, filter, false));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creatures_with_no_counters")
        self.assertEqual(effect["creature_filter"], {"no_counters": True})

    def test_boost_all_unsupported_filter_stays_blocked(self) -> None:
        row = queue_row(split.BOOST_ALL_SPELL_UNIT, effect_classes=["BoostAllEffect"])
        proposal, reason = split.split_row(
            row,
            metadata(oracle_text="Modified creatures get -2/-2 until end of turn."),
            source_text="this.getSpellAbility().addEffect(new BoostAllEffect(-2, -2, Duration.EndOfTurn, filter, false));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "boost_all_source_filter_not_supported")

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

    def test_fixed_boost_keyword_allows_trailing_reminder_text(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["BoostTargetEffect", "GainAbilityTargetEffect"],
            ability_classes=["TrampleAbility"],
            xmage_signals=["targeting"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                oracle_text=(
                    "Target creature gets +3/+1 and gains trample until end of turn. "
                    "(It can deal excess combat damage to the player or planeswalker it's attacking.)"
                )
            ),
            source_text=(
                "this.getSpellAbility().addEffect(new BoostTargetEffect(3, 1, Duration.EndOfTurn));"
                "this.getSpellAbility().addEffect(new GainAbilityTargetEffect("
                "TrampleAbility.getInstance(), Duration.EndOfTurn));"
                "this.getSpellAbility().addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["power_delta"], 3)
        self.assertEqual(effect["toughness_delta"], 1)
        self.assertEqual(effect["granted_keywords_until_eot"], ["trample"])

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

    def test_static_keyword_creature_maps_flash_to_timing_keyword(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::FlashAbility,FlyingAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["FlashAbility", "FlyingAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Aven Reedstalker",
                type_line="Creature - Bird Soldier",
                oracle_text="Flash\nFlying",
            ),
            source_text=(
                "this.addAbility(FlashAbility.getInstance());"
                "this.addAbility(FlyingAbility.getInstance());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_KEYWORD_CREATURE_SCOPE)
        self.assertEqual(effect["keywords"], ["flash", "flying"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertTrue(effect["flash"])
        self.assertTrue(effect["flying"])

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

    def test_activated_self_boost_accepts_leading_static_keyword(self) -> None:
        row = queue_row(
            "xmage_signature::BoostSourceEffect::FlyingAbility,SimpleActivatedAbility::"
            "no_target_class::no_condition_class::activated_ability",
            effect_classes=["BoostSourceEffect"],
            ability_kind="activated",
            ability_classes=["FlyingAbility", "SimpleActivatedAbility"],
            xmage_signals=["activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Drake",
                type_line="Creature - Drake",
                oracle_text="Flying\n{R}: Fixture Drake gets +1/+0 until end of turn.",
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "this.addAbility(new SimpleActivatedAbility("
                "new BoostSourceEffect(1, 0, Duration.EndOfTurn), "
                'new ManaCostsImpl<>("{R}")));'
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.SELF_BOOST_ACTIVATED_SCOPE)
        self.assertEqual(effect["activation_cost_mana"], "{R}")
        self.assertEqual(effect["power_delta"], 1)
        self.assertEqual(effect["toughness_delta"], 0)
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertTrue(effect["flying"])

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

    def test_activated_target_boost_maps_to_target_stat_modifier(self) -> None:
        row = queue_row(
            split.TARGET_BOOST_ACTIVATED_UNIT,
            effect_classes=["BoostTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Steed",
                type_line="Creature - Beast",
                oracle_text="{2}{U}, {T}: Target creature gets -2/-0 until end of turn.",
            ),
            source_text=(
                "Ability ability = new SimpleActivatedAbility("
                "new BoostTargetEffect(-2, 0, Duration.EndOfTurn), "
                'new ManaCostsImpl<>("{2}{U}"));'
                "ability.addCost(new TapSourceCost());"
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.TARGET_BOOST_ACTIVATED_SCOPE)
        self.assertEqual(effect["activated_effect"], "target_stat_modifier_until_eot")
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_controller"], "any")
        self.assertEqual(effect["power_delta"], -2)
        self.assertEqual(effect["toughness_delta"], 0)
        self.assertEqual(effect["activation_cost_generic"], 2)
        self.assertEqual(effect["activation_cost_colors"], ["U"])
        self.assertTrue(effect["activation_requires_tap"])
        self.assertEqual(effect["_activated_rule_effects"][0]["power_delta"], -2)

    def test_activated_target_boost_accepts_colored_mana_cost_source(self) -> None:
        row = queue_row(
            split.TARGET_BOOST_ACTIVATED_UNIT,
            effect_classes=["BoostTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Flame",
                type_line="Enchantment",
                oracle_text="{R}: Target creature gets +1/+0 until end of turn.",
            ),
            source_text=(
                "this.addAbility(new SimpleActivatedAbility("
                "new BoostTargetEffect(1, 0, Duration.EndOfTurn), "
                "new ColoredManaCost(ColoredManaSymbol.R)));"
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "enchantment")
        self.assertEqual(effect["activation_cost_mana"], "{R}")
        self.assertEqual(effect["activation_cost_colors"], ["R"])
        self.assertFalse(effect["activation_requires_tap"])

    def test_activated_target_boost_accepts_source_sacrifice_cost(self) -> None:
        row = queue_row(
            split.TARGET_BOOST_ACTIVATED_UNIT,
            effect_classes=["BoostTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Candle",
                type_line="Artifact",
                oracle_text="{6}, {T}, Sacrifice this artifact: Target creature gets -5/-5 until end of turn.",
            ),
            source_text=(
                "Ability ability = new SimpleActivatedAbility("
                "new BoostTargetEffect(-5, -5, Duration.EndOfTurn), "
                "new GenericManaCost(6));"
                "ability.addCost(new TapSourceCost());"
                "ability.addCost(new SacrificeSourceCost());"
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["activation_cost_mana"], "{6}")
        self.assertEqual(effect["activation_cost_generic"], 6)
        self.assertTrue(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "exclude_source": True})
        self.assertTrue(effect["_activated_rule_effects"][0]["activation_requires_sacrifice"])

    def test_activated_target_boost_blocks_sacrifice_target_cost(self) -> None:
        row = queue_row(
            split.TARGET_BOOST_ACTIVATED_UNIT,
            effect_classes=["BoostTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Sledder",
                type_line="Creature - Goblin",
                oracle_text="Sacrifice a Goblin: Target creature gets +1/+1 until end of turn.",
            ),
            source_text=(
                "Ability ability = new SimpleActivatedAbility("
                "new BoostTargetEffect(1, 1, Duration.EndOfTurn), "
                "new SacrificeTargetCost(filter));"
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_target_boost_oracle_cost_not_supported")

    def test_activated_target_boost_blocks_filtered_target_permanent(self) -> None:
        row = queue_row(
            split.TARGET_BOOST_ACTIVATED_UNIT,
            effect_classes=["BoostTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Guildmage",
                type_line="Creature - Human Wizard",
                oracle_text="{G}: Target green creature gets +1/+1 until end of turn.",
            ),
            source_text=(
                "Ability ability = new SimpleActivatedAbility("
                "new BoostTargetEffect(1, 1, Duration.EndOfTurn), new GenericManaCost(1));"
                "ability.addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_target_boost_oracle_not_simple")

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

    def test_activated_target_keyword_preserves_leading_static_keyword(self) -> None:
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
                name="Fixture Efreet",
                type_line="Creature - Efreet",
                oracle_text="Flying\n{1}{U}{U}: Target creature gains flying until end of turn.",
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "Ability ability = new SimpleActivatedAbility("
                "new GainAbilityTargetEffect(FlyingAbility.getInstance(), Duration.EndOfTurn), "
                'new ManaCostsImpl<>("{1}{U}{U}"));'
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertTrue(effect["flying"])
        self.assertEqual(effect["granted_keywords_until_eot"], ["flying"])
        self.assertEqual(effect["activation_cost_generic"], 1)
        self.assertEqual(effect["activation_cost_colors"], ["U", "U"])

    def test_activated_target_keyword_accepts_permanent_subtype_filter_target(self) -> None:
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

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "permanent")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["permanent"], "target_subtypes": ["soldier"]},
        )
        self.assertEqual(effect["activation_cost_generic"], 3)
        self.assertEqual(effect["granted_keywords_until_eot"], ["flying"])

    def test_activated_target_keyword_accepts_power_filter_target(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["GainAbilityTargetEffect"],
            ability_kind="activated",
            ability_classes=["VigilanceAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Behemoth",
                type_line="Creature - Beast",
                oracle_text="{1}: Target creature with power 5 or greater gains vigilance until end of turn.",
            ),
            source_text=(
                "private static final FilterCreaturePermanent filter = "
                "new FilterCreaturePermanent(\"creature with power 5 or greater\");"
                "Ability ability = new SimpleActivatedAbility("
                "new GainAbilityTargetEffect(VigilanceAbility.getInstance(), Duration.EndOfTurn), "
                'new ManaCostsImpl<>("{1}"));'
                "ability.addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "power_min": 5})
        self.assertEqual(effect["granted_keywords_until_eot"], ["vigilance"])

    def test_activated_target_keyword_accepts_power_max_filter_target(self) -> None:
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
                name="Fixture Glider",
                type_line="Artifact",
                oracle_text="{2}: Target creature with power 3 or less gains flying until end of turn.",
            ),
            source_text=(
                "private static final FilterCreaturePermanent filter = "
                "new FilterCreaturePermanent(\"creature with power 3 or less\");"
                "Ability ability = new SimpleActivatedAbility("
                "new GainAbilityTargetEffect(FlyingAbility.getInstance(), Duration.EndOfTurn), "
                'new ManaCostsImpl<>("{2}"));'
                "ability.addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "power_max": 3})
        self.assertEqual(effect["granted_keywords_until_eot"], ["flying"])

    def test_activated_target_keyword_accepts_color_or_filter_target(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["GainAbilityTargetEffect"],
            ability_kind="activated",
            ability_classes=["TrampleAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Weaver",
                type_line="Artifact Creature - Scarecrow",
                oracle_text="{2}: Target red or white creature gains trample until end of turn.",
            ),
            source_text=(
                "private static final FilterCreaturePermanent filter = "
                "new FilterCreaturePermanent(\"red or white creature\");"
                "Ability ability = new SimpleActivatedAbility("
                "new GainAbilityTargetEffect(TrampleAbility.getInstance(), Duration.EndOfTurn), "
                'new ManaCostsImpl<>("{2}"));'
                "ability.addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "target_colors": ["W", "R"]},
        )

    def test_activated_target_keyword_accepts_another_target_creature(self) -> None:
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
                name="Fixture Runner",
                type_line="Creature - Gnome",
                oracle_text="Haste\n{T}: Another target creature gains haste until end of turn.",
            ),
            source_text=(
                "this.addAbility(HasteAbility.getInstance());"
                "Ability ability = new SimpleActivatedAbility("
                "new GainAbilityTargetEffect(HasteAbility.getInstance(), Duration.EndOfTurn), "
                "new TapSourceCost());"
                "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_ANOTHER_TARGET_CREATURE));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "exclude_source": True})
        self.assertTrue(effect["activation_requires_tap"])
        self.assertEqual(effect["keywords"], ["haste"])

    def test_activated_target_keyword_accepts_attacking_subtype_target(self) -> None:
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
                name="Fixture Horde",
                type_line="Creature - Zombie",
                oracle_text="{1}{B}: Target attacking Zombie gains indestructible until end of turn.",
            ),
            source_text=(
                "private static final FilterCreaturePermanent filter = "
                "new FilterAttackingCreature(\"attacking Zombie\");"
                "Ability ability = new SimpleActivatedAbility("
                "new GainAbilityTargetEffect(IndestructibleAbility.getInstance(), Duration.EndOfTurn), "
                'new ManaCostsImpl<>("{1}{B}"));'
                "ability.addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "combat_state": "attacking", "target_subtypes": ["zombie"]},
        )
        self.assertEqual(effect["activation_cost_colors"], ["B"])

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

    def test_activated_target_keyword_blocks_snow_mana_cost_until_supported(self) -> None:
        row = queue_row(
            split.BOOST_KEYWORD_UNIT,
            effect_classes=["GainAbilityTargetEffect"],
            ability_kind="activated",
            ability_classes=["FirstStrikeAbility", "SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Yeti",
                type_line="Snow Creature - Yeti",
                oracle_text="{2}{S}: Target snow creature gains first strike until end of turn.",
            ),
            source_text=(
                "private static final FilterCreaturePermanent filter = "
                "new FilterCreaturePermanent(\"snow creature\");"
                "Ability ability = new SimpleActivatedAbility("
                "new GainAbilityTargetEffect(FirstStrikeAbility.getInstance(), Duration.EndOfTurn), "
                'new ManaCostsImpl<>("{2}{S}"));'
                "ability.addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "activated_target_keyword_oracle_cost_not_supported")

    def test_activated_target_keyword_allows_trailing_reminder_text(self) -> None:
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
                name="Fixture Inciter",
                type_line="Creature - Human Warrior",
                oracle_text="{T}: Target creature gains haste until end of turn. (It can attack and {T} this turn.)",
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
        self.assertEqual(effect["target_controller"], "any")
        self.assertEqual(effect["granted_keywords_until_eot"], ["haste"])
        self.assertTrue(effect["activation_requires_tap"])

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

    def test_creature_dies_gain_life_maps_to_triggered_creature_scope(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["GainLifeEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Lurker",
                type_line="Creature - Construct",
                oracle_text="When Fixture Lurker dies, you gain 3 life.",
            ),
            source_text="this.addAbility(new DiesSourceTriggeredAbility(new GainLifeEffect(3)));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.DIES_LIFE_GAIN_CREATURE_SCOPE)
        self.assertEqual(effect["trigger"], "dies")
        self.assertEqual(effect["gain_life_when_this_dies"], 3)

    def test_permanent_dies_fixed_mana_maps_to_triggered_scope(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=["BasicManaEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Cathodion",
                type_line="Artifact Creature - Construct",
                oracle_text="When Fixture Cathodion dies, add {C}{C}{C}.",
            ),
            source_text=(
                "this.addAbility(new DiesSourceTriggeredAbility("
                "new BasicManaEffect(Mana.ColorlessMana(3)), false));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DIES_FIXED_MANA_PERMANENT_SCOPE)
        self.assertEqual(effect["trigger"], "dies")
        self.assertEqual(effect["trigger_effect"], "add_mana")
        self.assertEqual(effect["dies_mana_produced"], 3)
        self.assertEqual(effect["dies_produces"], "C")
        self.assertEqual(effect["dies_produced_mana_symbols"], ["C", "C", "C"])

    def test_permanent_dies_fixed_mana_blocks_conditional_trigger(self) -> None:
        row = queue_row(
            split.RAMP_ARTIFACT_UNIT,
            effect_classes=["BasicManaEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Conditional Battery",
                type_line="Artifact Creature - Construct",
                oracle_text="When Fixture Conditional Battery dies, if you control a Mountain, add {R}.",
            ),
            source_text=(
                "this.addAbility(new DiesSourceTriggeredAbility(new BasicManaEffect(Mana.RedMana(1)))"
                ".withInterveningIf(ControlsMountainCondition.instance));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "dies_mana_oracle_not_simple_fixed")

    def test_creature_dies_gain_life_preserves_static_keywords(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["GainLifeEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility", "ReachAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Longneck",
                type_line="Creature - Dinosaur",
                oracle_text="Reach\nWhen this creature dies, you gain four life.",
            ),
            source_text=(
                "this.addAbility(ReachAbility.getInstance());"
                "this.addAbility(new DiesSourceTriggeredAbility(new GainLifeEffect(4)));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["keywords"], ["reach"])
        self.assertTrue(effect["reach"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertEqual(effect["gain_life_when_this_dies"], 4)

    def test_creature_dies_gain_life_blocks_dynamic_amount(self) -> None:
        row = queue_row(
            split.LIFE_UNIT,
            effect_classes=["GainLifeEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Zubera",
                type_line="Creature - Zubera Spirit",
                oracle_text="When Fixture Zubera dies, you gain 2 life for each Zubera that died this turn.",
            ),
            source_text="this.addAbility(new DiesSourceTriggeredAbility(new GainLifeEffect(new ZuberaValue())));",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "dies_life_gain_amount_not_fixed")

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

    def test_creature_etb_optional_discard_draw_maps_to_triggered_creature_scope(self) -> None:
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
                name="Fissure Wizard",
                type_line="Creature - Goblin Wizard",
                oracle_text="When this creature enters, you may discard a card. If you do, draw a card.",
            ),
            source_text="""
                this.addAbility(new EntersBattlefieldTriggeredAbility(new DoIfCostPaid(
                    new DrawCardSourceControllerEffect(), new DiscardCardCost())));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ETB_OPTIONAL_DISCARD_DRAW_CREATURE_SCOPE)
        self.assertTrue(effect["etb_optional_discard_draw"])
        self.assertEqual(effect["etb_optional_discard_count"], 1)
        self.assertEqual(effect["etb_optional_discard_draw_count"], 1)
        self.assertNotIn("etb_draw_count", effect)

    def test_creature_etb_dynamic_draw_maps_plus_one_counter_count(self) -> None:
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
                name="Armorcraft Judge",
                type_line="Creature - Elf Artificer",
                oracle_text=(
                    "When this creature enters, draw a card for each creature you control "
                    "with a +1/+1 counter on it."
                ),
            ),
            source_text=(
                "this.addAbility(new EntersBattlefieldTriggeredAbility(new DrawCardSourceControllerEffect("
                "new PermanentsOnBattlefieldCount(StaticFilters.FILTER_CONTROLLED_CREATURE_P1P1))));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ETB_DYNAMIC_DRAW_CREATURE_SCOPE)
        self.assertTrue(effect["etb_dynamic_draw"])
        self.assertEqual(effect["etb_draw_count_source"], "controlled_creatures_with_plus_one_counters")

    def test_creature_etb_dynamic_draw_maps_color_and_subtype_counts(self) -> None:
        fixtures = [
            (
                "Regal Force",
                "When this creature enters, draw a card for each green creature you control.",
                (
                    'private static final FilterControlledCreaturePermanent filter = '
                    'new FilterControlledCreaturePermanent("green creature you control");'
                    "filter.add(new ColorPredicate(ObjectColor.GREEN));"
                    "this.addAbility(new EntersBattlefieldTriggeredAbility(new DrawCardSourceControllerEffect("
                    "new PermanentsOnBattlefieldCount(filter))));"
                ),
                "controlled_creatures_with_color",
                {"etb_draw_count_color": "green"},
            ),
            (
                "Earthshaker Dreadmaw",
                "Trample\nWhen this creature enters, draw a card for each other Dinosaur you control.",
                (
                    'private static final FilterPermanent filter = new FilterControlledPermanent(SubType.DINOSAUR, '
                    '"other Dinosaur you control");'
                    "filter.add(AnotherPredicate.instance);"
                    "private static final DynamicValue xValue = new PermanentsOnBattlefieldCount(filter);"
                    "this.addAbility(new EntersBattlefieldTriggeredAbility(new DrawCardSourceControllerEffect(xValue)));"
                ),
                "controlled_creatures_with_subtype",
                {"etb_draw_count_subtype": "dinosaur", "etb_draw_count_exclude_source": True},
            ),
        ]
        for name, oracle_text, source_text, expected_source, expected_fields in fixtures:
            with self.subTest(name=name):
                row = queue_row(
                    split.DRAW_ENGINE_UNIT,
                    effect_classes=["DrawCardSourceControllerEffect"],
                    ability_kind="triggered",
                    ability_classes=["EntersBattlefieldTriggeredAbility", "TrampleAbility"] if "Trample" in oracle_text else ["EntersBattlefieldTriggeredAbility"],
                    xmage_signals=["draw", "triggered_ability"],
                )
                proposal, reason = split.split_row(
                    row,
                    metadata(name=name, type_line="Creature", oracle_text=oracle_text),
                    source_text=source_text,
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["battle_model_scope"], split.ETB_DYNAMIC_DRAW_CREATURE_SCOPE)
                self.assertEqual(effect["etb_draw_count_source"], expected_source)
                for key, value in expected_fields.items():
                    self.assertEqual(effect[key], value)

    def test_creature_etb_dynamic_draw_blocks_turn_death_count(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlashAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Liliana's Standard Bearer",
                type_line="Creature - Zombie Knight",
                oracle_text=(
                    "Flash\nWhen this creature enters, draw X cards, where X is the number "
                    "of creatures that died under your control this turn."
                ),
            ),
            source_text="new DrawCardSourceControllerEffect(new CreaturesDiedUnderYourControlThisTurnCount())",
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_draw_count_not_fixed")

    def test_creature_etb_draw_lose_life_maps_to_triggered_creature_scope(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect", "LoseLifeSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Rager",
                type_line="Creature - Horror",
                oracle_text="When Fixture Rager enters the battlefield, you draw a card and you lose 1 life.",
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new DrawCardSourceControllerEffect(1, true));"
                "ability.addEffect(new LoseLifeSourceControllerEffect(1).concatBy(\"and\"));"
                "this.addAbility(ability);"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_DRAW_LOSE_LIFE_CREATURE_SCOPE)
        self.assertEqual(effect["etb_draw_count"], 1)
        self.assertEqual(effect["etb_life_loss"], 1)
        self.assertEqual(effect["trigger"], "enters_battlefield")

    def test_creature_etb_draw_lose_life_blocks_condition(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect", "LoseLifeSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["draw", "condition", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Hexblade",
                type_line="Creature - Human Assassin",
                oracle_text=(
                    "When Fixture Hexblade enters the battlefield, if mana from a Treasure was spent to cast it, "
                    "you draw a card and you lose 1 life."
                ),
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility(new DrawCardSourceControllerEffect(1, true))"
                ".withInterveningIf(Condition.instance);"
                "ability.addEffect(new LoseLifeSourceControllerEffect(1).concatBy(\"and\"));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "unsupported_adapter_work_unit")

    def test_creature_etb_draw_lose_life_blocks_dynamic_amount(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect", "LoseLifeSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Champion",
                type_line="Creature - Vampire Knight",
                oracle_text=(
                    "When Fixture Champion enters the battlefield, you draw X cards and you lose X life, "
                    "where X is the number of Vampires you control."
                ),
            ),
            source_text=(
                "DynamicValue xCount = new PermanentsOnBattlefieldCount(filter);"
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new DrawCardSourceControllerEffect(xCount).setText(\"you draw X cards\"));"
                "ability.addEffect(new LoseLifeSourceControllerEffect(xCount));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_draw_lose_life_oracle_not_exact_fixed")

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

    def test_creature_combat_damage_draw_maps_to_triggered_creature_scope(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["DealsCombatDamageToAPlayerTriggeredAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Scroll Thief",
                type_line="Creature - Merfolk Rogue",
                oracle_text="Whenever Scroll Thief deals combat damage to a player, draw a card.",
            ),
            source_text=(
                "this.addAbility(new DealsCombatDamageToAPlayerTriggeredAbility("
                "new DrawCardSourceControllerEffect(), false));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.COMBAT_DAMAGE_DRAW_CREATURE_SCOPE)
        self.assertEqual(effect["trigger"], "combat_damage_to_player")
        self.assertTrue(effect["combat_damage_player_draw"])
        self.assertEqual(effect["combat_damage_draw_count"], 1)
        self.assertEqual(effect["draw_count"], 1)

    def test_creature_combat_damage_draw_preserves_static_keyword_and_optional_draw(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["DealsCombatDamageToAPlayerTriggeredAbility", "FlyingAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Sky Spy",
                type_line="Creature - Bird Rogue",
                oracle_text=(
                    "Flying\n"
                    "Whenever Fixture Sky Spy deals combat damage to a player, you may draw two cards."
                ),
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "this.addAbility(new DealsCombatDamageToAPlayerTriggeredAbility("
                "new DrawCardSourceControllerEffect(2), true));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["flying"])
        self.assertTrue(effect["combat_damage_draw_optional"])
        self.assertEqual(effect["combat_damage_draw_count"], 2)

    def test_creature_combat_damage_draw_ignores_keyword_class_used_only_in_filter(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["DealsCombatDamageToAPlayerTriggeredAbility", "DefenderAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Stealer of Secrets",
                type_line="Creature - Human Rogue",
                oracle_text="Whenever Stealer of Secrets deals combat damage to a player, draw a card.",
            ),
            source_text=(
                "import mage.abilities.keyword.DefenderAbility;"
                "filter.add(new AbilityPredicate(DefenderAbility.class));"
                "this.addAbility(new DealsCombatDamageToAPlayerTriggeredAbility("
                "new DrawCardSourceControllerEffect(1), false));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertNotIn("keywords", effect)
        self.assertNotIn("defender", effect)
        self.assertEqual(effect["combat_damage_draw_count"], 1)

    def test_creature_combat_damage_draw_blocks_damage_dealt_amount(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["DealsCombatDamageToAPlayerTriggeredAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Cold-Eyed Selkie",
                type_line="Creature - Merfolk Rogue",
                oracle_text=(
                    "Whenever Cold-Eyed Selkie deals combat damage to a player, "
                    "you may draw that many cards."
                ),
            ),
            source_text=(
                "this.addAbility(new DealsCombatDamageToAPlayerTriggeredAbility("
                "new DrawCardSourceControllerEffect(EachDamageValue.instance), true));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "combat_damage_draw_amount_damage_dealt_not_supported")

    def test_creature_combat_damage_draw_blocks_unmodeled_auxiliary_ability(self) -> None:
        row = queue_row(
            split.DRAW_ENGINE_UNIT,
            effect_classes=["DrawCardSourceControllerEffect"],
            ability_kind="triggered",
            ability_classes=["DealsCombatDamageToAPlayerTriggeredAbility", "NinjutsuAbility"],
            xmage_signals=["draw", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Ninja of the Deep Hours",
                type_line="Creature - Human Ninja",
                oracle_text=(
                    "Ninjutsu {1}{U}\n"
                    "Whenever Ninja of the Deep Hours deals combat damage to a player, you may draw a card."
                ),
            ),
            source_text=(
                "this.addAbility(new NinjutsuAbility(new ManaCostsImpl<>(\"{1}{U}\")));"
                "this.addAbility(new DealsCombatDamageToAPlayerTriggeredAbility("
                "new DrawCardSourceControllerEffect(), true));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "unsupported_adapter_work_unit")

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

    def test_creature_etb_destroy_allows_static_self_keywords(self) -> None:
        row = queue_row(
            split.DESTROY_UNIT,
            effect_classes=["DestroyTargetEffect"],
            ability_kind="triggered",
            ability_classes=["DeathtouchAbility", "EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Acidic Slime",
                type_line="Creature - Ooze",
                oracle_text=(
                    "Deathtouch\n"
                    "When Acidic Slime enters the battlefield, destroy target artifact, "
                    "enchantment, or land."
                ),
            ),
            source_text=(
                "this.addAbility(DeathtouchAbility.getInstance());"
                "private static final FilterPermanent filter = new FilterPermanent(\"artifact, enchantment, or land\");"
                "filter.add(Predicates.or(CardType.ARTIFACT.getPredicate(), "
                "CardType.ENCHANTMENT.getPredicate(), CardType.LAND.getPredicate()));"
                "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(), false);"
                "ability.addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ETB_DESTROY_CREATURE_SCOPE)
        self.assertEqual(effect["etb_remove_target"], "artifact_or_enchantment_or_land")
        self.assertEqual(effect["keywords"], ["deathtouch"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertTrue(effect["deathtouch"])

    def test_creature_etb_destroy_blocks_nonstatic_auxiliary_abilities(self) -> None:
        row = queue_row(
            split.DESTROY_UNIT,
            effect_classes=["DestroyTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "KickerAbility"],
            xmage_signals=["targeting", "condition", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Kor Sanctifiers",
                type_line="Creature - Kor Cleric",
                oracle_text=(
                    "Kicker {W}\n"
                    "When Kor Sanctifiers enters the battlefield, if it was kicked, "
                    "destroy target artifact or enchantment."
                ),
            ),
            source_text=(
                "this.addAbility(new KickerAbility(new ManaCostsImpl<>(\"{W}\")));"
                "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(), true);"
                "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_PERMANENT_ARTIFACT_OR_ENCHANTMENT));"
            ),
        )

        self.assertIsNone(proposal)
        self.assertNotEqual(reason, "selected_exact_scope")

    def test_creature_etb_destroy_maps_restricted_target_constraints(self) -> None:
        row = queue_row(
            split.DESTROY_UNIT,
            effect_classes=["DestroyTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        cases = [
            (
                "Bala Ged Scorpion",
                "When Bala Ged Scorpion enters the battlefield, you may destroy target creature with power 1 or less.",
                (
                    "FilterCreaturePermanent filter = new FilterCreaturePermanent(\"creature with power 1 or less\");"
                    "filter.add(new PowerPredicate(ComparisonType.FEWER_THAN, 2));"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(), true);"
                    "ability.addTarget(new TargetPermanent(filter));"
                ),
                "creature",
                {"card_types": ["creature"], "power_max": 1},
                None,
            ),
            (
                "Dakmor Lancer",
                "When Dakmor Lancer enters the battlefield, you may destroy target nonblack creature.",
                (
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(), true);"
                    "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_PERMANENT_CREATURE_NON_BLACK));"
                ),
                "creature",
                {"card_types": ["creature"], "exclude_colors": ["B"]},
                None,
            ),
            (
                "Dark Hatchling",
                "Flying\nWhen Dark Hatchling enters, destroy target nonblack creature. It can't be regenerated.",
                (
                    "this.addAbility(FlyingAbility.getInstance());"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(true));"
                    "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_PERMANENT_CREATURE_NON_BLACK));"
                ),
                "creature",
                {"card_types": ["creature"], "exclude_colors": ["B"]},
                None,
            ),
            (
                "Angel of Despair",
                "Flying\nWhen this creature enters, destroy target permanent.",
                (
                    "this.addAbility(FlyingAbility.getInstance());"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect());"
                    "ability.addTarget(new TargetPermanent());"
                ),
                "permanent",
                {"card_types": ["permanent"]},
                "any",
            ),
            (
                "Armaggon, Future Shark",
                "Flash\nWhen Armaggon enters, destroy up to three target creatures.",
                (
                    "this.addAbility(FlashAbility.getInstance());"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect());"
                    "ability.addTarget(new TargetCreaturePermanent(0, 3));"
                ),
                "creature",
                {"card_types": ["creature"]},
                None,
            ),
            (
                "Final-Sting Faerie",
                "Flying\nWhen this creature enters, destroy target creature that was dealt damage this turn.",
                (
                    "this.addAbility(FlyingAbility.getInstance());"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect());"
                    "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_CREATURE_DAMAGED_THIS_TURN));"
                ),
                "creature",
                {"card_types": ["creature"], "damaged_this_turn": True},
                None,
            ),
            (
                "Gilt-Leaf Winnower",
                (
                    "Menace\n"
                    "When this creature enters, you may destroy target non-Elf creature "
                    "whose power and toughness aren't equal."
                ),
                (
                    "private static final FilterCreaturePermanent filter = "
                    "new FilterCreaturePermanent(\"non-Elf creature whose power and toughness aren't equal\");"
                    "filter.add(Predicates.not(SubType.ELF.getPredicate()));"
                    "filter.add(new PowerToughnessNotEqualPredicate());"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(), true);"
                    "ability.addTarget(new TargetPermanent(filter));"
                ),
                "creature",
                {
                    "card_types": ["creature"],
                    "exclude_subtypes": ["elf"],
                    "power_toughness_not_equal": True,
                },
                None,
            ),
            (
                "Kraul Whipcracker",
                "Reach\nWhen this creature enters, destroy target token an opponent controls.",
                (
                    "private static final FilterPermanent filter = new FilterPermanent(\"token an opponent controls\");"
                    "filter.add(TokenPredicate.TRUE);"
                    "filter.add(TargetController.OPPONENT.getControllerPredicate());"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect());"
                    "ability.addTarget(new TargetPermanent(filter));"
                ),
                "permanent",
                {"card_types": ["permanent"], "controller_scope": "opponent", "token": True},
                "opponent",
            ),
            (
                "Nekrataal",
                (
                    "First strike\n"
                    "When this creature enters, destroy target nonartifact, nonblack creature. "
                    "That creature can't be regenerated."
                ),
                (
                    "private static final FilterCreaturePermanent filter = "
                    "new FilterCreaturePermanent(\"nonartifact, nonblack creature\");"
                    "filter.add(Predicates.not(CardType.ARTIFACT.getPredicate()));"
                    "filter.add(Predicates.not(new ColorPredicate(ObjectColor.BLACK)));"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(true));"
                    "ability.addTarget(new TargetPermanent(filter));"
                ),
                "creature",
                {"card_types": ["creature"], "exclude_card_types": ["artifact"], "exclude_colors": ["B"]},
                None,
            ),
            (
                "Ogre Gatecrasher",
                "When this creature enters, destroy target creature with defender.",
                (
                    "private static final FilterCreaturePermanent filter = "
                    "new FilterCreaturePermanent(\"creature with defender\");"
                    "filter.add(new AbilityPredicate(DefenderAbility.class));"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(), false);"
                    "ability.addTarget(new TargetPermanent(filter));"
                ),
                "creature",
                {"card_types": ["creature"], "required_keywords": ["defender"]},
                None,
            ),
            (
                "Stingerfling Spider",
                "Reach\nWhen this creature enters, you may destroy target creature with flying.",
                (
                    "this.addAbility(ReachAbility.getInstance());"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(), true);"
                    "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_CREATURE_FLYING));"
                ),
                "creature",
                {"card_types": ["creature"], "required_keywords": ["flying"]},
                None,
            ),
            (
                "Fathom Fleet Cutthroat",
                (
                    "When Fathom Fleet Cutthroat enters the battlefield, destroy target creature "
                    "an opponent controls that was dealt damage this turn."
                ),
                (
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(), false);"
                    "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_OPPONENTS_CREATURE_DAMAGED_THIS_TURN));"
                ),
                "creature",
                {"card_types": ["creature"], "controller_scope": "opponent", "damaged_this_turn": True},
                "opponent",
            ),
            (
                "Vraska's Finisher",
                (
                    "When Vraska's Finisher enters the battlefield, destroy target creature or planeswalker "
                    "an opponent controls that was dealt damage this turn."
                ),
                (
                    "private static final FilterPermanent filter = new FilterCreatureOrPlaneswalkerPermanent("
                    "\"creature or planeswalker an opponent controls that was dealt damage this turn\");"
                    "filter.add(WasDealtDamageThisTurnPredicate.instance);"
                    "filter.add(TargetController.OPPONENT.getControllerPredicate());"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect());"
                    "ability.addTarget(new TargetPermanent(filter));"
                ),
                "creature_or_planeswalker",
                {
                    "card_types": ["creature", "planeswalker"],
                    "controller_scope": "opponent",
                    "damaged_this_turn": True,
                },
                "opponent",
            ),
            (
                "Ravenous Baboons",
                "When Ravenous Baboons enters the battlefield, destroy target nonbasic land.",
                (
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect());"
                    "ability.addTarget(new TargetNonBasicLandPermanent());"
                ),
                "land",
                {"card_types": ["land"], "exclude_supertypes": ["basic"]},
                "any",
            ),
            (
                "Setessan Starbreaker",
                "When Setessan Starbreaker enters the battlefield, you may destroy target Aura.",
                (
                    "FilterEnchantmentPermanent filter = new FilterEnchantmentPermanent(\"Aura\");"
                    "filter.add(SubType.AURA.getPredicate());"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(), true);"
                    "ability.addTarget(new TargetPermanent(filter));"
                ),
                "enchantment",
                {"card_types": ["enchantment"], "required_subtypes": ["aura"]},
                "any",
            ),
            (
                "Slayer of the Wicked",
                "When Slayer of the Wicked enters the battlefield, you may destroy target Vampire, Werewolf, or Zombie.",
                (
                    "FilterCreaturePermanent filter = new FilterCreaturePermanent(\"Vampire, Werewolf, or Zombie\");"
                    "filter.add(Predicates.or(SubType.VAMPIRE.getPredicate(), SubType.WEREWOLF.getPredicate(), "
                    "SubType.ZOMBIE.getPredicate()));"
                    "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect(), true);"
                    "ability.addTarget(new TargetPermanent(filter));"
                ),
                "creature",
                {"card_types": ["creature"], "required_subtypes": ["vampire", "werewolf", "zombie"]},
                None,
            ),
        ]

        for name, oracle_text, source_text, target, constraints, controller in cases:
            with self.subTest(name=name):
                proposal, reason = split.split_row(
                    row,
                    metadata(
                        name=name,
                        type_line="Creature - Fixture",
                        oracle_text=oracle_text,
                    ),
                    source_text=source_text,
                )

                self.assertEqual(reason, "selected_exact_scope")
                effect = proposal["effect_json"]
                self.assertEqual(effect["effect"], "creature")
                self.assertEqual(effect["battle_model_scope"], split.ETB_DESTROY_CREATURE_SCOPE)
                self.assertEqual(effect["etb_remove_target"], target)
                self.assertEqual(effect["target_constraints"], constraints)
                if name == "Armaggon, Future Shark":
                    self.assertEqual(effect["max_targets"], 3)
                if controller:
                    self.assertEqual(effect["target_controller"], controller)
                else:
                    self.assertNotIn("target_controller", effect)

    def test_creature_etb_destroy_blocks_damage_this_turn_source_mismatch(self) -> None:
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
                name="Fathom Fleet Cutthroat",
                type_line="Creature - Human Pirate",
                oracle_text=(
                    "When Fathom Fleet Cutthroat enters the battlefield, destroy target creature "
                    "an opponent controls that was dealt damage this turn."
                ),
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility(new DestroyTargetEffect());"
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_destroy_source_target_not_supported")

    def test_creature_etb_bounce_maps_to_triggered_creature_scope(self) -> None:
        row = queue_row(
            split.BOUNCE_UNIT,
            effect_classes=["ReturnToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Aether Adept",
                type_line="Creature - Human Wizard",
                oracle_text="When Aether Adept enters the battlefield, return target creature to its owner's hand.",
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnToHandTargetEffect());"
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_BOUNCE_CREATURE_SCOPE)
        self.assertEqual(effect["etb_remove_effect"], "remove_creature")
        self.assertEqual(effect["etb_remove_target"], "creature")
        self.assertEqual(effect["destination"], "hand")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"]})

    def test_creature_etb_bounce_maps_opponent_and_keyword_constraints(self) -> None:
        row = queue_row(
            split.BOUNCE_UNIT,
            effect_classes=["ReturnToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Riddlemaster Sphinx",
                type_line="Creature - Sphinx",
                oracle_text=(
                    "Flying\n"
                    "When Riddlemaster Sphinx enters the battlefield, you may return target creature "
                    "an opponent controls to its owner's hand."
                ),
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnToHandTargetEffect(), true);"
                "ability.addTarget(new TargetPermanent(FILTER_OPPONENTS_PERMANENT_CREATURE));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target_controller"], "opponent")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "controller_scope": "opponent"},
        )
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["etb_bounce_optional"])

    def test_creature_etb_bounce_marks_another_target_as_exclude_source(self) -> None:
        row = queue_row(
            split.BOUNCE_UNIT,
            effect_classes=["ReturnToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Voidmage",
                type_line="Creature - Wizard",
                oracle_text=(
                    "When Fixture Voidmage enters the battlefield, "
                    "return another target creature to its owner's hand."
                ),
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnToHandTargetEffect());"
                "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_ANOTHER_CREATURE));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertTrue(effect["exclude_source"])
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "exclude_source": True})

    def test_creature_etb_bounce_maps_self_bounce_with_exclude_source(self) -> None:
        row = queue_row(
            split.BOUNCE_UNIT,
            effect_classes=["ReturnToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlashAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Deputy of Acquittals",
                type_line="Creature - Human Wizard",
                oracle_text=(
                    "Flash\n"
                    "When Deputy of Acquittals enters the battlefield, you may return another target "
                    "creature you control to its owner's hand."
                ),
            ),
            source_text=(
                "this.addAbility(FlashAbility.getInstance());"
                "Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnToHandTargetEffect(), true);"
                "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_ANOTHER_TARGET_CREATURE_YOU_CONTROL));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["creature"], "controller_scope": "self", "exclude_source": True},
        )
        self.assertTrue(effect["exclude_source"])
        self.assertTrue(effect["etb_bounce_optional"])
        self.assertEqual(effect["keywords"], ["flash"])

    def test_creature_etb_bounce_maps_self_permanent_up_to_one(self) -> None:
        row = queue_row(
            split.BOUNCE_UNIT,
            effect_classes=["ReturnToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Exosuit Savior",
                type_line="Creature - Human Soldier",
                oracle_text=(
                    "Flying\n"
                    "When this creature enters, return up to one other target permanent you control "
                    "to its owner's hand."
                ),
            ),
            source_text=(
                "private static final FilterControlledPermanent filter = "
                "new FilterControlledPermanent(\"other target permanent you control\");"
                "filter.add(AnotherPredicate.instance);"
                "Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnToHandTargetEffect());"
                "ability.addTarget(new TargetControlledPermanent(0, 1, filter, false));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(effect["etb_bounce_target"], "permanent")
        self.assertEqual(
            effect["target_constraints"],
            {"card_types": ["permanent"], "controller_scope": "self", "exclude_source": True},
        )
        self.assertTrue(effect["exclude_source"])
        self.assertTrue(effect["up_to_count"])
        self.assertEqual(effect["target_count"], 1)
        self.assertEqual(effect["keywords"], ["flying"])

    def test_creature_etb_bounce_maps_ability_word_other_creature(self) -> None:
        row = queue_row(
            split.BOUNCE_UNIT,
            effect_classes=["ReturnToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Air-Cult Elemental",
                type_line="Creature - Elemental",
                oracle_text=(
                    "Flying\n"
                    "Whirlwind - When Air-Cult Elemental enters the battlefield, "
                    "return up to one other target creature to its owner's hand."
                ),
            ),
            source_text=(
                "private static final FilterCreaturePermanent filter = "
                "new FilterCreaturePermanent(\"other target creature\");"
                "filter.add(AnotherPredicate.instance);"
                "Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnToHandTargetEffect());"
                "ability.addTarget(new TargetPermanent(0, 1, filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target_controller"], "any")
        self.assertEqual(effect["etb_bounce_target"], "creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "exclude_source": True})
        self.assertTrue(effect["up_to_count"])
        self.assertEqual(effect["keywords"], ["flying"])

    def test_creature_etb_bounce_maps_non_spirit_creature(self) -> None:
        row = queue_row(
            split.BOUNCE_UNIT,
            effect_classes=["ReturnToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Roaming Ghostlight",
                type_line="Creature - Spirit",
                oracle_text=(
                    "Flying\n"
                    "When Roaming Ghostlight enters the battlefield, "
                    "return up to one target non-Spirit creature to its owner's hand."
                ),
            ),
            source_text=(
                "private static final FilterCreaturePermanent filter = "
                "new FilterCreaturePermanent(\"non-Spirit creature\");"
                "filter.add(Predicates.not(SubType.SPIRIT.getPredicate()));"
                "Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnToHandTargetEffect());"
                "ability.addTarget(new TargetPermanent(0, 1, filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_bounce_target"], "non_spirit_creature")
        self.assertEqual(effect["target_constraints"], {"card_types": ["creature"], "exclude_subtypes": ["spirit"]})
        self.assertTrue(effect["up_to_count"])

    def test_creature_etb_bounce_maps_historic_permanent_you_control(self) -> None:
        row = queue_row(
            split.BOUNCE_UNIT,
            effect_classes=["ReturnToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Guardians of Koilos",
                type_line="Artifact Creature - Construct",
                oracle_text=(
                    "When Guardians of Koilos enters the battlefield, you may return another target "
                    "historic permanent you control to its owner's hand. "
                    "(Artifacts, legendaries, and Sagas are historic.)"
                ),
            ),
            source_text=(
                "private static final FilterControlledPermanent filter = "
                "new FilterControlledPermanent(\"another historic permanent you control\");"
                "filter.add(AnotherPredicate.instance);"
                "filter.add(HistoricPredicate.instance);"
                "Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnToHandTargetEffect(), true);"
                "ability.addTarget(new TargetPermanent(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target_controller"], "self")
        self.assertEqual(effect["etb_bounce_target"], "historic_permanent")
        self.assertEqual(
            effect["target_constraints"],
            {
                "any_of": [
                    {"card_types": ["artifact"]},
                    {"card_types": ["permanent"], "required_supertypes": ["legendary"]},
                    {"card_types": ["enchantment"], "required_subtypes": ["saga"]},
                ],
                "controller_scope": "self",
                "exclude_source": True,
            },
        )
        self.assertTrue(effect["exclude_source"])
        self.assertTrue(effect["etb_bounce_optional"])

    def test_creature_etb_bounce_blocks_condition_and_self_without_exclude_source(self) -> None:
        conditional_row = queue_row(
            split.BOUNCE_UNIT,
            effect_classes=["ReturnToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "condition", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            conditional_row,
            metadata(
                name="Deadeye Rig-Hauler",
                type_line="Creature - Human Pirate",
                oracle_text=(
                    "Raid - When Deadeye Rig-Hauler enters the battlefield, if you attacked this turn, "
                    "you may return target creature to its owner's hand."
                ),
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnToHandTargetEffect(), true)"
                ".withInterveningIf(RaidCondition.instance);"
                "ability.addTarget(new TargetCreaturePermanent());"
            ),
        )
        self.assertIsNone(proposal)
        self.assertNotEqual(reason, "selected_exact_scope")

        self_row = queue_row(
            split.BOUNCE_UNIT,
            effect_classes=["ReturnToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            self_row,
            metadata(
                name="Fixture Rescue Mage",
                type_line="Creature - Human Wizard",
                oracle_text="When this creature enters, you may return target creature you control to its owner's hand.",
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnToHandTargetEffect(), true);"
                "ability.addTarget(new TargetPermanent(StaticFilters.FILTER_CONTROLLED_CREATURE));"
            ),
        )
        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_bounce_self_without_exclude_source_not_supported")

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

    def test_creature_combat_damage_recursion_maps_arcane_target(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=[
                "DealsCombatDamageToAPlayerTriggeredAbility",
                "FlyingAbility",
                "TrampleAbility",
            ],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="The Unspeakable",
                type_line="Legendary Creature - Spirit",
                oracle_text=(
                    "Flying, trample\n"
                    "Whenever The Unspeakable deals combat damage to a player, "
                    "you may return target Arcane card from your graveyard to your hand."
                ),
            ),
            source_text=(
                "this.addAbility(FlyingAbility.getInstance());"
                "this.addAbility(TrampleAbility.getInstance());"
                "Ability ability = new DealsCombatDamageToAPlayerTriggeredAbility("
                "new ReturnFromGraveyardToHandTargetEffect(), true);"
                "ability.addTarget(new TargetCardInYourGraveyard(filter));"
                "filter.add(SubType.ARCANE.getPredicate());"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DAMAGE_RECURSION_CREATURE_SCOPE)
        self.assertTrue(effect["combat_damage_player_graveyard_recursion"])
        self.assertEqual(effect["combat_damage_recursion_target"], "arcane_card")
        self.assertEqual(effect["combat_damage_recursion_destination"], "hand")
        self.assertEqual(effect["keywords"], ["flying", "trample"])

    def test_permanent_attack_recursion_maps_trigger_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=[
                "AttacksTriggeredAbility",
                "EntersBattlefieldTappedAbility",
            ],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Eternal Taskmaster",
                type_line="Creature - Zombie",
                oracle_text=(
                    "This creature enters tapped.\n"
                    "Whenever this creature attacks, you may pay {2}{B}. If you do, "
                    "return target creature card from your graveyard to your hand."
                ),
            ),
            source_text=(
                "this.addAbility(new EntersBattlefieldTappedAbility());"
                "Ability ability = new AttacksTriggeredAbility(new DoIfCostPaid("
                "new ReturnFromGraveyardToHandTargetEffect(), new ManaCostsImpl<>(\"{2}{B}\")), false);"
                "ability.addTarget(new TargetCardInYourGraveyard("
                "StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ATTACK_RECURSION_PERMANENT_SCOPE)
        self.assertTrue(effect["attack_trigger_graveyard_recursion"])
        self.assertEqual(effect["attack_recursion_target"], "creature")
        self.assertEqual(effect["attack_recursion_trigger_cost_mana"], "{2}{B}")
        self.assertEqual(effect["attack_recursion_trigger_cost_generic"], 2)
        self.assertEqual(effect["attack_recursion_trigger_cost_colors"], ["B"])
        self.assertTrue(effect["enters_tapped"])

    def test_activated_recursion_to_hand_accepts_activate_as_sorcery(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="activated",
            ability_classes=["ActivateAsSorceryActivatedAbility", "ReachAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Pillardrop Warden",
                type_line="Creature - Spirit Dwarf",
                oracle_text=(
                    "Reach\n"
                    "{2}, {T}, Sacrifice this creature: Return target instant or sorcery card "
                    "from your graveyard to your hand. Activate only as a sorcery."
                ),
            ),
            source_text=(
                "this.addAbility(ReachAbility.getInstance());"
                "Ability ability = new ActivateAsSorceryActivatedAbility("
                "new ReturnFromGraveyardToHandTargetEffect(), new GenericManaCost(2));"
                "ability.addCost(new TapSourceCost());"
                "ability.addCost(new SacrificeSourceCost());"
                "ability.addTarget(new TargetCardInYourGraveyard("
                "new FilterInstantOrSorceryCard(\"instant or sorcery card from your graveyard\")));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_RECURSION_TO_HAND_SCOPE)
        self.assertEqual(effect["graveyard_to_hand_target"], "instant_or_sorcery")
        self.assertEqual(effect["activation_timing"], "sorcery")
        self.assertEqual(effect["xmage_ability_class"], "ActivateAsSorceryActivatedAbility")
        self.assertTrue(effect["activation_requires_tap"])
        self.assertTrue(effect["activation_requires_sacrifice"])
        self.assertEqual(effect["keywords"], ["reach"])

    def test_creature_etb_recursion_to_battlefield_maps_land_target(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Quarry Beetle",
                type_line="Creature - Insect",
                oracle_text=(
                    "When Quarry Beetle enters the battlefield, you may return target "
                    "land card from your graveyard to the battlefield."
                ),
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new ReturnFromGraveyardToBattlefieldTargetEffect(), true);"
                "ability.addTarget(new TargetCardInYourGraveyard(new FilterLandCard("
                "\"land card from your graveyard\")));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_RECURSION_BATTLEFIELD_CREATURE_SCOPE)
        self.assertEqual(effect["etb_recursion_target"], "land")
        self.assertEqual(effect["etb_recursion_count"], 1)
        self.assertEqual(effect["etb_recursion_destination"], "battlefield")
        self.assertEqual(effect["destination"], "battlefield")
        self.assertEqual(effect["trigger"], "enters_battlefield")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["land"]},
        )

    def test_creature_etb_recursion_to_battlefield_maps_vampire_or_wizard_target(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "LifelinkAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Bloodline Necromancer",
                type_line="Creature - Vampire Wizard",
                oracle_text=(
                    "Lifelink\n"
                    "When Bloodline Necromancer enters the battlefield, you may return target "
                    "Vampire or Wizard creature card from your graveyard to the battlefield."
                ),
            ),
            source_text=(
                "private static final FilterCreatureCard filter = new FilterCreatureCard("
                "\"Vampire or Wizard creature card from your graveyard\");"
                "filter.add(Predicates.or(SubType.VAMPIRE.getPredicate(), "
                "SubType.WIZARD.getPredicate()));"
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new ReturnFromGraveyardToBattlefieldTargetEffect(), true);"
                "Target target = new TargetCardInYourGraveyard(filter);"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ETB_RECURSION_BATTLEFIELD_CREATURE_SCOPE)
        self.assertEqual(effect["etb_recursion_target"], "vampire_or_wizard_creature")
        self.assertEqual(effect["keywords"], ["lifelink"])
        self.assertTrue(effect["lifelink"])
        self.assertEqual(
            effect["target_constraints"],
            {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "subtypes": ["vampire", "wizard"],
            },
        )

    def test_creature_etb_recursion_to_battlefield_maps_artifact_target(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Sharuum the Hegemon",
                type_line="Legendary Artifact Creature - Sphinx",
                oracle_text=(
                    "Flying\n"
                    "When Sharuum the Hegemon enters the battlefield, you may return target "
                    "artifact card from your graveyard to the battlefield."
                ),
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility("
                "new ReturnFromGraveyardToBattlefieldTargetEffect(), true);"
                "ability.addTarget(new TargetCardInYourGraveyard("
                "StaticFilters.FILTER_CARD_ARTIFACT_FROM_YOUR_GRAVEYARD));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ETB_RECURSION_BATTLEFIELD_CREATURE_SCOPE)
        self.assertEqual(effect["etb_recursion_target"], "artifact")
        self.assertEqual(effect["etb_recursion_destination"], "battlefield")
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["artifact"]},
        )

    def test_creature_etb_recursion_to_battlefield_blocks_reflexive_cost_variant(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "ReflexiveTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Young Necromancer",
                type_line="Creature - Human Warlock",
                oracle_text=(
                    "When Young Necromancer enters the battlefield, you may exile two cards "
                    "from your graveyard. When you do, return target creature card from your "
                    "graveyard to the battlefield."
                ),
            ),
            source_text=(
                "new EntersBattlefieldTriggeredAbility(new DoWhenCostPaid("
                "new ReflexiveTriggeredAbility(new ReturnFromGraveyardToBattlefieldTargetEffect(), false), "
                "new ExileFromGraveCost(new TargetCardInYourGraveyard(2, StaticFilters.FILTER_CARD_CARDS))))"
            ),
        )

        self.assertIsNone(proposal)
        self.assertNotEqual(reason, "selected_exact_scope")

    def test_creature_etb_mill_then_return_permanent_maps_to_triggered_scope(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["MillCardsControllerEffect", "ReturnCardChosenFromGraveyardEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Acolyte of Affliction",
                type_line="Creature - Human Cleric",
                oracle_text=(
                    "When Acolyte of Affliction enters the battlefield, put the top two cards "
                    "of your library into your graveyard, then you may return a permanent card "
                    "from your graveyard to your hand."
                ),
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility(new MillCardsControllerEffect(2));"
                "ability.addEffect(new ReturnCardChosenFromGraveyardEffect(true, "
                "filter, PutCards.HAND).concatBy(\", then\"));"
                "private static final FilterPermanentCard filter = new FilterPermanentCard(\"permanent card from your graveyard\");"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_MILL_RECURSION_CREATURE_SCOPE)
        self.assertEqual(effect["etb_recursion_mill_count"], 2)
        self.assertEqual(effect["etb_recursion_target"], "permanent")
        self.assertEqual(effect["etb_recursion_count"], 1)
        self.assertTrue(effect["etb_recursion_up_to_count"])
        self.assertEqual(
            effect["target_constraints"],
            {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["artifact", "creature", "enchantment", "planeswalker", "battle", "land"],
            },
        )

    def test_creature_etb_mill_then_return_land_maps_to_triggered_scope(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["MillCardsControllerEffect", "ReturnCardChosenFromGraveyardEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Eccentric Farmer",
                type_line="Creature - Human Peasant",
                oracle_text=(
                    "When Eccentric Farmer enters the battlefield, mill three cards, "
                    "then you may return a land card from your graveyard to your hand."
                ),
            ),
            source_text=(
                "Ability ability = new EntersBattlefieldTriggeredAbility(new MillCardsControllerEffect(3));"
                "ability.addEffect(new ReturnCardChosenFromGraveyardEffect(true, "
                "StaticFilters.FILTER_CARD_LAND_FROM_YOUR_GRAVEYARD, PutCards.HAND).concatBy(\", then\"));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_recursion_mill_count"], 3)
        self.assertEqual(effect["etb_recursion_target"], "land")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["land"]},
        )

    def test_creature_etb_recursion_maps_subtype_card_target(self) -> None:
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
                name="Barrow Witches",
                type_line="Creature - Human Warlock",
                oracle_text="When Barrow Witches enters the battlefield, return target Knight card from your graveyard to your hand.",
            ),
            source_text="""
                filter.add(SubType.KNIGHT.getPredicate());
                Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnFromGraveyardToHandTargetEffect());
                ability.addTarget(new TargetCardInYourGraveyard(filter));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_recursion_target"], "knight_card")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "subtypes": ["knight"]},
        )

    def test_creature_etb_recursion_maps_artifact_mana_value_limit(self) -> None:
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
                name="Leonin Squire",
                type_line="Creature - Cat Soldier",
                oracle_text=(
                    "When Leonin Squire enters the battlefield, return target artifact card "
                    "with converted mana cost 1 or less from your graveyard to your hand."
                ),
            ),
            source_text="""
                filter.add(new ManaValuePredicate(ComparisonType.FEWER_THAN, 2));
                Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnFromGraveyardToHandTargetEffect());
                ability.addTarget(new TargetCardInYourGraveyard(filter));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_recursion_target"], "artifact")
        self.assertEqual(effect["etb_recursion_mana_value_max"], 1)
        self.assertEqual(
            effect["target_constraints"],
            {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["artifact"],
                "mana_value_max": 1,
            },
        )

    def test_creature_etb_recursion_maps_instant_and_or_sorcery_up_to_two(self) -> None:
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
                name="Scholar of the Ages",
                type_line="Creature - Human Wizard",
                oracle_text=(
                    "When Scholar of the Ages enters the battlefield, return up to two target "
                    "instant and/or sorcery cards from your graveyard to your hand."
                ),
            ),
            source_text="""
                Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnFromGraveyardToHandTargetEffect());
                ability.addTarget(new TargetCardInYourGraveyard(0, 2, filter));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_recursion_target"], "instant_or_sorcery")
        self.assertEqual(effect["etb_recursion_count"], 2)
        self.assertTrue(effect["etb_recursion_up_to_count"])

    def test_creature_etb_recursion_maps_creature_or_food_up_to_one(self) -> None:
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
                name="Ragamuffin Raptor",
                type_line="Creature - Dinosaur",
                oracle_text="When this creature enters, return up to one target creature or Food card from your graveyard to your hand.",
            ),
            source_text="""
                filter.add(Predicates.or(CardType.CREATURE.getPredicate(), SubType.FOOD.getPredicate()));
                Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnFromGraveyardToHandTargetEffect());
                ability.addTarget(new TargetCardInYourGraveyard(0, 1, filter));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_recursion_target"], "creature_or_food")
        self.assertEqual(effect["etb_recursion_count"], 1)
        self.assertTrue(effect["etb_recursion_up_to_count"])
        self.assertEqual(
            effect["target_constraints"],
            {
                "zone": "graveyard",
                "controller": "self",
                "any_of": [
                    {"card_types": ["creature"]},
                    {"subtypes": ["food"]},
                ],
            },
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

    def test_creature_etb_recursion_maps_spirit_instant_or_sorcery(self) -> None:
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
                name="Returned Pastcaller",
                type_line="Creature - Spirit Cleric",
                oracle_text=(
                    "Flying\n"
                    "When this creature enters, return target Spirit, instant, or sorcery card "
                    "from your graveyard to your hand."
                ),
            ),
            source_text=(
                "filter.add(Predicates.or(SubType.SPIRIT.getPredicate(), "
                "CardType.INSTANT.getPredicate(), CardType.SORCERY.getPredicate()));"
                "Ability ability = new EntersBattlefieldTriggeredAbility(new ReturnFromGraveyardToHandTargetEffect());"
                "ability.addTarget(new TargetCardInYourGraveyard(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_recursion_target"], "spirit_instant_or_sorcery")
        self.assertEqual(effect["etb_recursion_count"], 1)
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertEqual(
            effect["target_constraints"],
            {
                "zone": "graveyard",
                "controller": "self",
                "any_of": [
                    {"subtypes": ["spirit"]},
                    {"card_types": ["instant"]},
                    {"card_types": ["sorcery"]},
                ],
            },
        )

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

    def test_creature_etb_library_pick_maps_to_triggered_creature_scope(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["LookLibraryAndPickControllerEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Organ Hoarder",
                type_line="Creature - Zombie",
                oracle_text=(
                    "When Organ Hoarder enters the battlefield, look at the top three cards "
                    "of your library, then put one of them into your hand and the rest into your graveyard."
                ),
            ),
            source_text="""
                this.addAbility(new EntersBattlefieldTriggeredAbility(new LookLibraryAndPickControllerEffect(
                    3, 1, PutCards.HAND, PutCards.GRAVEYARD
                )));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_LIBRARY_PICK_CREATURE_SCOPE)
        self.assertEqual(effect["etb_library_look_count"], 3)
        self.assertEqual(effect["etb_library_pick_count"], 1)
        self.assertEqual(effect["etb_library_pick_target"], "any_card")
        self.assertEqual(effect["etb_library_rest_destination"], "graveyard")
        self.assertEqual(effect["trigger"], "enters_battlefield")

    def test_creature_etb_library_pick_preserves_static_keywords(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["LookLibraryAndPickControllerEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Tower Geist",
                type_line="Creature - Spirit",
                oracle_text=(
                    "Flying\n"
                    "When Tower Geist enters the battlefield, look at the top two cards of your library. "
                    "Put one of them into your hand and the other into your graveyard."
                ),
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                this.addAbility(new EntersBattlefieldTriggeredAbility(
                    new LookLibraryAndPickControllerEffect(2, 1, PutCards.HAND, PutCards.GRAVEYARD)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["flying"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertEqual(effect["etb_library_look_count"], 2)

    def test_creature_etb_library_pick_blocks_top_any_destination(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["LookLibraryAndPickControllerEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Sage of Days",
                type_line="Creature - Human Wizard",
                oracle_text=(
                    "When Sage of Days enters the battlefield, look at the top three cards of your library. "
                    "You may put one of those cards back on top of your library. Put the rest into your graveyard."
                ),
            ),
            source_text="""
                this.addAbility(new EntersBattlefieldTriggeredAbility(new LookLibraryAndPickControllerEffect(
                    3, 1, PutCards.TOP_ANY, PutCards.GRAVEYARD, true
                )));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_library_pick_oracle_not_simple")

    def test_creature_etb_library_tutor_to_battlefield_maps_land_scope(self) -> None:
        row = queue_row(
            split.TUTOR_UNIT,
            effect_classes=["SearchLibraryPutInPlayEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Cultivator",
                type_line="Creature - Turtle Druid",
                oracle_text=(
                    "When Fixture Cultivator enters the battlefield, you may search your library for a "
                    "basic Forest or Island card, put it onto the battlefield, then shuffle."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard("a basic Forest or Island card");
                static {
                    filter.add(SuperType.BASIC.getPredicate());
                    filter.add(Predicates.or(SubType.FOREST.getPredicate(), SubType.ISLAND.getPredicate()));
                }
                this.addAbility(new EntersBattlefieldTriggeredAbility(
                    new SearchLibraryPutInPlayEffect(new TargetCardInLibrary(filter), false), true));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_TUTOR_BATTLEFIELD_CREATURE_SCOPE)
        self.assertEqual(effect["etb_tutor_target"], "basic_forest_or_island_to_battlefield")
        self.assertEqual(effect["etb_tutor_count"], 1)
        self.assertEqual(effect["destination"], "battlefield")
        self.assertFalse(effect["tutor_enters_tapped"])
        self.assertEqual(effect["trigger"], "enters_battlefield")

    def test_creature_etb_library_tutor_to_battlefield_preserves_static_keywords(self) -> None:
        row = queue_row(
            split.TUTOR_UNIT,
            effect_classes=["SearchLibraryPutInPlayEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Hawk",
                type_line="Creature - Bird",
                oracle_text=(
                    "Flying\n"
                    "When Fixture Hawk enters the battlefield, you may search your library for a Plains card, "
                    "put it onto the battlefield tapped, then shuffle."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard(SubType.PLAINS);
                this.addAbility(FlyingAbility.getInstance());
                this.addAbility(new EntersBattlefieldTriggeredAbility(
                    new SearchLibraryPutInPlayEffect(new TargetCardInLibrary(filter), true), true));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_tutor_target"], "plains_to_battlefield")
        self.assertTrue(effect["tutor_enters_tapped"])
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["flying"])

    def test_permanent_activated_tutor_to_battlefield_maps_rebel_mana_value(self) -> None:
        row = queue_row(
            split.TUTOR_UNIT,
            effect_classes=["SearchLibraryPutInPlayEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Amrou Scout",
                type_line="Creature - Kithkin Rebel Scout",
                oracle_text=(
                    "{4}, {T}: Search your library for a Rebel permanent card with mana value 3 or less, "
                    "put it onto the battlefield, then shuffle."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterPermanentCard("Rebel permanent card with mana value 3 or less");
                static {
                    filter.add(SubType.REBEL.getPredicate());
                    filter.add(new ManaValuePredicate(ComparisonType.FEWER_THAN, 4));
                }
                Ability ability = new SimpleActivatedAbility(
                    new SearchLibraryPutInPlayEffect(new TargetCardInLibrary(filter), false),
                    new ManaCostsImpl<>("{4}"));
                ability.addCost(new TapSourceCost());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_TUTOR_BATTLEFIELD_SCOPE)
        self.assertEqual(effect["target"], "any_to_battlefield")
        self.assertEqual(effect["target_subtypes"], ["rebel"])
        self.assertEqual(
            effect["target_card_types"],
            ["artifact", "creature", "enchantment", "planeswalker", "land", "battle"],
        )
        self.assertEqual(effect["target_mana_value_max"], 3)
        self.assertEqual(effect["activation_cost_mana"], "{4}")
        self.assertEqual(effect["activation_cost_generic"], 4)
        self.assertTrue(effect["activation_requires_tap"])
        self.assertFalse(effect["activation_requires_sacrifice"])
        self.assertFalse(effect["tutor_enters_tapped"])
        self.assertEqual(effect["_activated_rule_effects"][0]["tutor_target"], "any_to_battlefield")

    def test_permanent_activated_tutor_to_battlefield_maps_self_sacrifice_basic_land(self) -> None:
        row = queue_row(
            split.TUTOR_UNIT,
            effect_classes=["SearchLibraryPutInPlayEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Burnished Hart",
                type_line="Artifact Creature - Elk",
                oracle_text=(
                    "{3}, Sacrifice Burnished Hart: Search your library for up to two basic land cards, "
                    "put them onto the battlefield tapped, then shuffle."
                ),
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new SearchLibraryPutInPlayEffect(
                        new TargetCardInLibrary(0, 2, StaticFilters.FILTER_CARD_BASIC_LANDS), true),
                    new GenericManaCost(3));
                ability.addCost(new SacrificeSourceCost());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.PERMANENT_ACTIVATED_TUTOR_BATTLEFIELD_SCOPE)
        self.assertEqual(effect["target"], "basic_land_to_battlefield")
        self.assertEqual(effect["count"], 2)
        self.assertTrue(effect["up_to_count"])
        self.assertTrue(effect["tutor_enters_tapped"])
        self.assertEqual(effect["activation_cost_mana"], "{3}")
        self.assertTrue(effect["activation_requires_sacrifice"])
        self.assertTrue(effect["activated_self_sacrifice_tutor_to_battlefield"])

    def test_permanent_activated_tutor_to_battlefield_blocks_sacrifice_target_cost(self) -> None:
        row = queue_row(
            split.TUTOR_UNIT,
            effect_classes=["SearchLibraryPutInPlayEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Kuldotha Forgemaster",
                type_line="Artifact Creature - Construct",
                oracle_text=(
                    "{T}, Sacrifice three artifacts: Search your library for an artifact card, "
                    "put it onto the battlefield, then shuffle."
                ),
            ),
            source_text="""
                Ability ability = new SimpleActivatedAbility(
                    new SearchLibraryPutInPlayEffect(
                        new TargetCardInLibrary(StaticFilters.FILTER_CARD_ARTIFACT), false),
                    new ManaCostsImpl<>("{0}"));
                ability.addCost(new TapSourceCost());
                ability.addCost(new SacrificeTargetCost(3, StaticFilters.FILTER_PERMANENT_ARTIFACT));
                this.addAbility(ability);
            """,
        )

        self.assertIsNone(proposal)
        self.assertIn(
            reason,
            {
                "activated_library_tutor_oracle_cost_not_supported",
                "activated_library_tutor_source_cost_not_supported",
            },
        )

    def test_creature_etb_library_tutor_to_hand_maps_basic_land_scope(self) -> None:
        row = queue_row(
            split.ETB_TUTOR_HAND_CREATURE_UNIT,
            effect_classes=["SearchLibraryPutInHandEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Ranger",
                type_line="Creature - Elf Scout",
                oracle_text=(
                    "When Fixture Ranger enters the battlefield, you may search your library for a basic land card, "
                    "reveal it, put it into your hand, then shuffle."
                ),
            ),
            source_text="""
                this.addAbility(new EntersBattlefieldTriggeredAbility(
                    new SearchLibraryPutInHandEffect(new TargetCardInLibrary(StaticFilters.FILTER_CARD_BASIC_LAND), true), true));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_TUTOR_HAND_CREATURE_SCOPE)
        self.assertEqual(effect["etb_tutor_target"], "basic_land_to_hand")
        self.assertEqual(effect["destination"], "hand")
        self.assertEqual(effect["trigger"], "enters_battlefield")

    def test_creature_etb_library_tutor_to_hand_preserves_keyword_and_any_card(self) -> None:
        row = queue_row(
            split.ETB_TUTOR_HAND_CREATURE_UNIT,
            effect_classes=["SearchLibraryPutInHandEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Demon",
                type_line="Creature - Demon",
                oracle_text=(
                    "Flying\n"
                    "When Fixture Demon enters the battlefield, you may search your library for a card, "
                    "put it into your hand, then shuffle."
                ),
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                this.addAbility(new EntersBattlefieldTriggeredAbility(
                    new SearchLibraryPutInHandEffect(new TargetCardInLibrary(), false), true));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_tutor_target"], "any_to_hand")
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["flying"])

    def test_creature_etb_library_tutor_to_hand_preserves_mana_value_constraint(self) -> None:
        row = queue_row(
            split.ETB_TUTOR_HAND_CREATURE_UNIT,
            effect_classes=["SearchLibraryPutInHandEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Tribute",
                type_line="Creature - Human Wizard",
                oracle_text=(
                    "When Fixture Tribute enters the battlefield, you may search your library for an artifact card "
                    "with mana value 2, reveal that card, put it into your hand, then shuffle."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterArtifactCard("artifact card with mana value 2");
                static {
                    filter.add(new ManaValuePredicate(ComparisonType.EQUAL_TO, 2));
                }
                this.addAbility(new EntersBattlefieldTriggeredAbility(
                    new SearchLibraryPutInHandEffect(new TargetCardInLibrary(filter), true), true));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_tutor_target"], "artifact_to_hand")
        self.assertEqual(effect["target_card_types"], ["artifact"])
        self.assertEqual(effect["target_mana_value_min"], 2)
        self.assertEqual(effect["target_mana_value_max"], 2)

    def test_creature_etb_library_tutor_to_hand_blocks_distinct_name_source(self) -> None:
        row = queue_row(
            split.ETB_TUTOR_HAND_CREATURE_UNIT,
            effect_classes=["SearchLibraryPutInHandEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Shared",
                type_line="Creature - Human",
                oracle_text=(
                    "When Fixture Shared enters the battlefield, you may search your library for up to two creature cards "
                    "with different names, reveal them, put them into your hand, then shuffle."
                ),
            ),
            source_text="""
                this.addAbility(new EntersBattlefieldTriggeredAbility(
                    new SearchLibraryPutInHandEffect(new TargetCardWithDifferentNameInLibrary(
                        0, 2, StaticFilters.FILTER_CARD_CREATURES), true), true));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "etb_library_tutor_to_hand_source_distinct_names_not_supported")

    def test_creature_etb_library_tutor_to_battlefield_blocks_condition(self) -> None:
        row = queue_row(
            split.TUTOR_UNIT,
            effect_classes=["SearchLibraryPutInPlayEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "condition", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Hawk",
                type_line="Creature - Bird",
                oracle_text=(
                    "When Fixture Hawk enters the battlefield, if an opponent controls more lands than you, "
                    "search your library for a basic Plains card, put it onto the battlefield tapped, then shuffle."
                ),
            ),
            source_text="""
                this.addAbility(new EntersBattlefieldTriggeredAbility(
                    new SearchLibraryPutInPlayEffect(new TargetCardInLibrary(StaticFilters.FILTER_CARD_BASIC_LAND), true),
                    false, condition));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "not_instant_or_sorcery_spell")

    def test_creature_etb_graveyard_to_library_maps_artifact_or_creature_top(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["PutOnLibraryTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Dukhara Scavenger",
                type_line="Creature - Crocodile",
                oracle_text=(
                    "When Dukhara Scavenger enters the battlefield, you may put target "
                    "artifact or creature card from your graveyard on top of your library."
                ),
            ),
            source_text="""
                Effect effect = new PutOnLibraryTargetEffect(true);
                Ability ability = new EntersBattlefieldTriggeredAbility(effect, true);
                ability.addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_ARTIFACT_OR_CREATURE));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["effect"], "creature")
        self.assertEqual(effect["battle_model_scope"], split.ETB_GRAVEYARD_TO_LIBRARY_CREATURE_SCOPE)
        self.assertEqual(effect["etb_recursion_target"], "artifact_or_creature")
        self.assertEqual(effect["etb_recursion_count"], 1)
        self.assertEqual(effect["etb_recursion_destination"], "library_top")
        self.assertEqual(effect["target_graveyard_controller"], "self")
        self.assertEqual(effect["library_controller"], "self")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["artifact", "creature"]},
        )

    def test_creature_etb_graveyard_to_library_maps_instant_or_sorcery_up_to_one_top(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["PutOnLibraryTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Biblioplex Assistant",
                type_line="Artifact Creature - Gargoyle",
                oracle_text=(
                    "Flying\n"
                    "When Biblioplex Assistant enters the battlefield, put up to one target instant "
                    "or sorcery card from your graveyard on top of your library."
                ),
            ),
            source_text="""
                private static final FilterCard filter =
                    new FilterInstantOrSorceryCard("instant or sorcery card from your graveyard");
                Ability ability = new EntersBattlefieldTriggeredAbility(new PutOnLibraryTargetEffect(true));
                ability.addTarget(new TargetCardInYourGraveyard(0, 1, filter));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ETB_GRAVEYARD_TO_LIBRARY_CREATURE_SCOPE)
        self.assertEqual(effect["etb_recursion_target"], "instant_or_sorcery")
        self.assertEqual(effect["etb_recursion_count"], 1)
        self.assertTrue(effect["etb_recursion_up_to_count"])
        self.assertEqual(effect["etb_recursion_destination"], "library_top")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["instant", "sorcery"]},
        )

    def test_creature_etb_graveyard_to_library_maps_noncreature_nonland_top(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["PutOnLibraryTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Monastery Messenger",
                type_line="Creature - Bird Scout",
                oracle_text=(
                    "Flying, vigilance\n"
                    "When this creature enters, put up to one target noncreature, "
                    "nonland card from your graveyard on top of your library."
                ),
            ),
            source_text="""
                private static final FilterCard filter =
                    new FilterNonlandCard("noncreature, nonland card from your graveyard");
                static {
                    filter.add(Predicates.not(CardType.CREATURE.getPredicate()));
                }
                Ability ability = new EntersBattlefieldTriggeredAbility(new PutOnLibraryTargetEffect(true));
                ability.addTarget(new TargetCardInYourGraveyard(0, 1, filter));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ETB_GRAVEYARD_TO_LIBRARY_CREATURE_SCOPE)
        self.assertEqual(effect["etb_recursion_target"], "noncreature_nonland")
        self.assertEqual(effect["etb_recursion_count"], 1)
        self.assertTrue(effect["etb_recursion_up_to_count"])
        self.assertEqual(effect["etb_recursion_destination"], "library_top")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "exclude_card_types": ["creature", "land"]},
        )

    def test_creature_etb_graveyard_to_library_maps_any_graveyard_owner_library(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["PutOnLibraryTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Nantuko Tracer",
                type_line="Creature - Insect Druid",
                oracle_text=(
                    "When Nantuko Tracer enters the battlefield, you may put target card "
                    "from a graveyard on the bottom of its owner's library."
                ),
            ),
            source_text="""
                Ability ability = new EntersBattlefieldTriggeredAbility(new PutOnLibraryTargetEffect(false), true);
                ability.addTarget(new TargetCardInGraveyard());
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.ETB_GRAVEYARD_TO_LIBRARY_CREATURE_SCOPE)
        self.assertEqual(effect["etb_recursion_target"], "any_card")
        self.assertEqual(effect["etb_recursion_count"], 1)
        self.assertEqual(effect["etb_recursion_destination"], "library_bottom")
        self.assertEqual(effect["target_graveyard_controller"], "any")
        self.assertEqual(effect["target_controller"], "any")
        self.assertEqual(effect["library_controller"], "owner")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "any", "scope": "any_card"},
        )

    def test_creature_etb_graveyard_to_library_maps_up_to_one_any_graveyard_owner_library(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["PutOnLibraryTargetEffect"],
            ability_kind="triggered",
            ability_classes=["EntersBattlefieldTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Swiftgear Drake",
                type_line="Artifact Creature - Drake",
                oracle_text=(
                    "Flying, haste\n"
                    "When Swiftgear Drake enters the battlefield, put up to one target card "
                    "from a graveyard on the bottom of its owner's library."
                ),
            ),
            source_text="""
                Ability ability = new EntersBattlefieldTriggeredAbility(new PutOnLibraryTargetEffect(false));
                ability.addTarget(new TargetCardInGraveyard(0, 1));
                this.addAbility(ability);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["etb_recursion_target"], "any_card")
        self.assertEqual(effect["etb_recursion_count"], 1)
        self.assertTrue(effect["etb_recursion_up_to_count"])
        self.assertEqual(effect["etb_recursion_destination"], "library_bottom")
        self.assertEqual(effect["target_graveyard_controller"], "any")
        self.assertEqual(effect["library_controller"], "owner")

    def test_creature_dies_recursion_maps_artifact_target(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility", "FlyingAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Junk Diver",
                type_line="Artifact Creature - Myr",
                oracle_text=(
                    "Flying\n"
                    "When this creature dies, return another target artifact card "
                    "from your graveyard to your hand."
                ),
            ),
            source_text=(
                "Effect effect = new ReturnFromGraveyardToHandTargetEffect();"
                "Ability ability = new DiesSourceTriggeredAbility(effect);"
                "ability.addTarget(new TargetCardInYourGraveyard(filter));"
            ),
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.DIES_RECURSION_CREATURE_SCOPE)
        self.assertEqual(effect["dies_recursion_target"], "artifact")
        self.assertEqual(effect["dies_recursion_count"], 1)
        self.assertEqual(effect["dies_recursion_destination"], "hand")
        self.assertTrue(effect["dies_recursion_exclude_self"])
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["flying"])
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["artifact"]},
        )

    def test_creature_dies_recursion_blocks_optional_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="triggered",
            ability_classes=["DiesSourceTriggeredAbility"],
            xmage_signals=["targeting", "triggered_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Carrion Thrash",
                type_line="Creature - Lizard Warrior",
                oracle_text=(
                    "When Carrion Thrash dies, you may pay {2}. If you do, return another target "
                    "creature card from your graveyard to your hand."
                ),
            ),
            source_text=(
                "DiesSourceTriggeredAbility ability = new DiesSourceTriggeredAbility("
                "new DoIfCostPaid(new ReturnFromGraveyardToHandTargetEffect(), "
                "new GenericManaCost(2)), false);"
            ),
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "dies_recursion_optional_cost_not_supported")

    def test_recursion_spell_with_flashback_maps_to_hand_and_preserves_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="one_shot",
            ability_classes=["FlashbackAbility"],
            xmage_signals=["targeting"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Morgue Theft",
                type_line="Sorcery",
                oracle_text="Return target creature card from your graveyard to your hand. Flashback {4}{B}",
            ),
            source_text="""
                // Return target creature card from your graveyard to your hand.
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE));
                // Flashback {4}{B}
                this.addAbility(new FlashbackAbility(this, new ManaCostsImpl<>("{4}{B}")));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["destination"], "hand")
        self.assertEqual(effect["flashback_cost"], "{4}{B}")
        self.assertEqual(effect["flashback_status"], "runtime_executor_v1")
        self.assertEqual(effect["xmage_auxiliary_ability_classes"], ["FlashbackAbility"])

    def test_recursion_spell_with_cycling_maps_to_hand_and_preserves_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
            ability_kind="one_shot",
            ability_classes=["CyclingAbility"],
            xmage_signals=["targeting"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Wander in Death",
                type_line="Sorcery",
                oracle_text="Return up to two target creature cards from your graveyard to your hand. Cycling {2}",
            ),
            source_text="""
                // Return up to two target creature cards from your graveyard to your hand.
                getSpellAbility().addTarget(new TargetCardInYourGraveyard(
                    0, 2, StaticFilters.FILTER_CARD_CREATURES_YOUR_GRAVEYARD));
                getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                // Cycling {2}
                this.addAbility(new CyclingAbility(new GenericManaCost(2)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["count"], 2)
        self.assertTrue(effect["up_to_count"])
        self.assertEqual(effect["cycling_cost"], "{2}")
        self.assertEqual(effect["cycling_status"], "runtime_executor_v1")

    def test_recursion_spell_with_cycling_maps_to_battlefield_and_preserves_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="one_shot",
            ability_classes=["CyclingAbility"],
            xmage_signals=["targeting"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Unearth",
                type_line="Sorcery",
                oracle_text=(
                    "Return target creature card with mana value 3 or less from your graveyard "
                    "to the battlefield. Cycling {2}"
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterCreatureCard(
                    "creature card with mana value 3 or less from your graveyard");
                static {
                    filter.add(new ManaValuePredicate(ComparisonType.FEWER_THAN, 4));
                }
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(filter));
                this.addAbility(new CyclingAbility(new ManaCostsImpl<>("{2}")));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.RECURSION_BATTLEFIELD_SCOPE)
        self.assertEqual(effect["target"], "creature")
        self.assertEqual(effect["destination"], "battlefield")
        self.assertEqual(effect["recursion_mana_value_max"], 3)
        self.assertEqual(effect["cycling_cost"], "{2}")
        self.assertEqual(
            effect["target_constraints"],
            {"zone": "graveyard", "controller": "self", "card_types": ["creature"], "mana_value_max": 3},
        )

    def test_recursion_spell_blocks_flashback_non_mana_cost(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="one_shot",
            ability_classes=["FlashbackAbility"],
            xmage_signals=["targeting"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Dread Return",
                type_line="Sorcery",
                oracle_text=(
                    "Return target creature card from your graveyard to the battlefield. "
                    "Flashback-Sacrifice three creatures."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(
                    StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                this.addAbility(new FlashbackAbility(this, new SacrificeTargetCost(3, filter)));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "recursion_auxiliary_flashback_cost_not_supported")

    def test_recursion_exile_self_multicolored_up_to_three_maps_to_hand(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ExileSpellEffect", "ReturnFromGraveyardToHandTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Vivid Revival",
                type_line="Sorcery",
                oracle_text=(
                    "Return up to three target multicolored cards from your graveyard to your hand. "
                    "Exile Vivid Revival."
                ),
            ),
            source_text="""
                filter.add(MulticoloredPredicate.instance);
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 3, filter));
                this.getSpellAbility().addEffect(new ExileSpellEffect());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertTrue(effect["exiles_self"])
        self.assertEqual(effect["target"], "multicolored_card")
        self.assertEqual(effect["count"], 3)
        self.assertTrue(effect["up_to_count"])
        self.assertEqual(effect["target_constraints"], {"zone": "graveyard", "controller": "self", "min_colors": 2})

    def test_recursion_exile_self_reconstruct_history_maps_components(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ExileSpellEffect", "ReturnFromGraveyardToHandTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Reconstruct History",
                type_line="Sorcery",
                oracle_text=(
                    "Return up to one target artifact card, up to one target enchantment card, "
                    "up to one target instant card, up to one target sorcery card, and up to one "
                    "target planeswalker card from your graveyard to your hand.\n"
                    "Exile Reconstruct History."
                ),
            ),
            source_text="""
                new FilterArtifactCard();
                new FilterEnchantmentCard();
                CardType.INSTANT.getPredicate();
                CardType.SORCERY.getPredicate();
                new FilterPlaneswalkerCard();
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect()
                    .setTargetPointer(new EachTargetPointer()));
                this.getSpellAbility().addEffect(new ExileSpellEffect().concatBy("<br>"));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(
            effect["battle_model_scope"],
            "xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1",
        )
        self.assertTrue(effect["exiles_self"])
        self.assertEqual(
            [component["target"] for component in effect["recursion_components"]],
            ["artifact", "enchantment", "instant", "sorcery", "planeswalker"],
        )
        self.assertTrue(all(component.get("up_to_count") for component in effect["recursion_components"]))

    def test_recursion_exile_self_retrieve_maps_noncreature_permanent_component(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ExileSpellEffect", "ReturnFromGraveyardToHandTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Retrieve",
                type_line="Sorcery",
                oracle_text=(
                    "Return up to one target creature card and up to one target noncreature permanent "
                    "card from your graveyard to your hand. Exile Retrieve."
                ),
            ),
            source_text="""
                FilterCard filter = new FilterPermanentCard("noncreature permanent card from your graveyard");
                filter.add(Predicates.not(CardType.CREATURE.getPredicate()));
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect()
                    .setTargetPointer(new EachTargetPointer()));
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 1, StaticFilters.FILTER_CARD_CREATURE));
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 1, filter));
                this.getSpellAbility().addEffect(new ExileSpellEffect());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(
            [component["target"] for component in effect["recursion_components"]],
            ["creature", "noncreature_permanent"],
        )
        self.assertEqual(
            effect["recursion_components"][1]["target_constraints"],
            {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["artifact", "enchantment", "planeswalker", "battle", "land"],
                "exclude_card_types": ["creature"],
            },
        )

    def test_recursion_for_each_color_maps_color_creature_components(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Rogues' Gallery",
                type_line="Sorcery",
                oracle_text=(
                    "For each color, return up to one target creature card of that color "
                    "from your graveyard to your hand."
                ),
            ),
            source_text="""
                new ReturnFromGraveyardToHandTargetEffect();
                class RoguesGalleryTarget extends TargetCardInYourGraveyard {
                    RoguesGalleryTarget() {
                        super(0, 5, new FilterCreatureCard("creature cards"), false);
                    }
                    ColorAssignment colorAssignment = new ColorAssignment();
                    ColorlessPredicate.instance.apply(card, game);
                }
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], "xmage_return_one_graveyard_creature_per_color_to_hand_spell_v1")
        self.assertEqual(effect["mode_selection"], "all_components")
        self.assertEqual(
            [component["target"] for component in effect["recursion_components"]],
            ["white_creature", "blue_creature", "black_creature", "red_creature", "green_creature"],
        )
        self.assertTrue(all(component.get("up_to_count") for component in effect["recursion_components"]))
        self.assertEqual(effect["recursion_components"][0]["target_constraints"]["colors"], ["W"])
        self.assertEqual(effect["recursion_components"][1]["target_constraints"]["colors"], ["U"])

    def test_recursion_for_each_color_requires_xmage_color_target(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Rogues' Gallery",
                type_line="Sorcery",
                oracle_text=(
                    "For each color, return up to one target creature card of that color "
                    "from your graveyard to your hand."
                ),
            ),
            source_text="""
                new ReturnFromGraveyardToHandTargetEffect();
                new TargetCardInYourGraveyard(0, 5, new FilterCreatureCard("creature cards"), false);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "recursion_for_each_color_source_not_supported")

    def test_recursion_multi_target_maps_mount_vehicle_and_no_abilities_components(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Rise from the Wreck",
                type_line="Sorcery",
                oracle_text=(
                    "Return up to one target creature card, up to one target Mount card, "
                    "up to one target Vehicle card, and up to one target creature card with no "
                    "abilities from your graveyard to your hand."
                ),
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect()
                    .setTargetPointer(new EachTargetPointer()));
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 1, StaticFilters.FILTER_CARD_CREATURE));
                FilterCard filter = new FilterCard("Mount card");
                filter.add(SubType.MOUNT.getPredicate());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 1, filter));
                FilterCard filter2 = new FilterCard("Vehicle card");
                filter2.add(SubType.VEHICLE.getPredicate());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 1, filter2));
                FilterCard filter3 = new FilterCard("creature card with no abilities");
                filter3.add(NoAbilityPredicate.instance);
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(0, 1, filter3));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], "xmage_return_multiple_graveyard_cards_to_hand_spell_v1")
        self.assertEqual(
            [component["target"] for component in effect["recursion_components"]],
            ["creature", "mount_card", "vehicle_card", "creature_no_abilities"],
        )
        self.assertTrue(all(component.get("up_to_count") for component in effect["recursion_components"]))
        self.assertEqual(effect["recursion_components"][3]["target_constraints"]["requires_no_abilities"], True)

    def test_recursion_multi_target_requires_xmage_subtype_and_no_ability_filters(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToHandTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Rise from the Wreck",
                type_line="Sorcery",
                oracle_text=(
                    "Return up to one target creature card, up to one target Mount card, "
                    "up to one target Vehicle card, and up to one target creature card with no "
                    "abilities from your graveyard to your hand."
                ),
            ),
            source_text="""
                new ReturnFromGraveyardToHandTargetEffect().setTargetPointer(new EachTargetPointer());
                new TargetCardInYourGraveyard(0, 1, StaticFilters.FILTER_CARD_CREATURE);
                new TargetCardInYourGraveyard(0, 1, StaticFilters.FILTER_CARD_CREATURE);
                new TargetCardInYourGraveyard(0, 1, StaticFilters.FILTER_CARD_ARTIFACT);
                new TargetCardInYourGraveyard(0, 1, StaticFilters.FILTER_CARD_CREATURE);
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "recursion_multi_target_source_not_supported")

    def test_recursion_battlefield_dynamic_graveyard_permanent_count_maps(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Squirming Emergence",
                type_line="Sorcery",
                oracle_text=(
                    "Fathomless descent — Return to the battlefield target nonland permanent card "
                    "in your graveyard with mana value less than or equal to the number of permanent "
                    "cards in your graveyard."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterNonlandCard(
                    "nonland permanent card in your graveyard with mana value less than or equal to the number of permanent cards in your graveyard"
                );
                static {
                    filter.add(PermanentPredicate.instance);
                    filter.add(SquirmingEmergencePredicate.instance);
                }
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(filter));
                return player.getGraveyard().count(StaticFilters.FILTER_CARD_PERMANENT, game) >= input.getObject().getManaValue();
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "nonland_permanent")
        self.assertTrue(effect["target_mana_value_max_from_graveyard_permanent_count"])
        self.assertEqual(effect["target_constraints"]["mana_value_max_source"], "graveyard_permanent_count")

    def test_recursion_battlefield_choose_one_or_both_maps_components(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Rise to Glory",
                type_line="Sorcery",
                oracle_text=(
                    "Choose one or both —\n"
                    "• Return target creature card from your graveyard to the battlefield.\n"
                    "• Return target Aura card from your graveyard to the battlefield."
                ),
            ),
            source_text="""
                this.getSpellAbility().getModes().setMinModes(1);
                this.getSpellAbility().getModes().setMaxModes(2);
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToBattlefieldTargetEffect());
                this.getSpellAbility().addTarget(new TargetCardInYourGraveyard(StaticFilters.FILTER_CARD_CREATURE_YOUR_GRAVEYARD));
                FilterCard filter = new FilterCard("Aura card from your graveyard");
                filter.add(SubType.AURA.getPredicate());
                Mode mode = new Mode(new ReturnFromGraveyardToBattlefieldTargetEffect());
                mode.addTarget(new TargetCardInYourGraveyard(filter));
                this.getSpellAbility().addMode(mode);
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["mode_selection"], "one_or_both")
        self.assertEqual(effect["battle_model_scope"], "xmage_return_one_or_both_graveyard_cards_to_battlefield_spell_v1")
        self.assertEqual(
            [component["target"] for component in effect["recursion_components"]],
            ["creature", "aura_card"],
        )
        self.assertTrue(all(component["destination"] == "battlefield" for component in effect["recursion_components"]))

    def test_activated_recursion_battlefield_maps_this_turn_tapped_target(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Othelm, Sigardian Outcast",
                type_line="Legendary Creature - Human",
                oracle_text=(
                    "{2}, {T}: Choose target creature card in your graveyard that was put there "
                    "from the battlefield this turn. Return it to the battlefield tapped.\n"
                    "Partner—Friends forever (You can have two commanders if both have this ability.)"
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterCreatureCard(
                    "creature card in your graveyard that was put there from the battlefield this turn"
                );
                static { filter.add(PutIntoGraveFromBattlefieldThisTurnPredicate.instance); }
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToBattlefieldTargetEffect(true),
                    new GenericManaCost(2)
                );
                ability.addCost(new TapSourceCost());
                ability.addTarget(new TargetCardInYourGraveyard(filter));
                this.addAbility(ability, new CardsPutIntoGraveyardWatcher());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "creature")
        self.assertTrue(effect["enters_tapped"])
        self.assertTrue(effect["graveyard_from_battlefield_this_turn"])
        self.assertTrue(effect["target_constraints"]["graveyard_from_battlefield_this_turn"])

    def test_activated_recursion_battlefield_maps_rebel_permanent_mana_value(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ReturnFromGraveyardToBattlefieldTargetEffect"],
            ability_kind="activated",
            ability_classes=["SimpleActivatedAbility"],
            xmage_signals=["targeting", "activated_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Ramosian Revivalist",
                type_line="Creature - Human Rebel Cleric",
                oracle_text=(
                    "{6}, {T}: Return target Rebel permanent card with mana value 5 or less "
                    "from your graveyard to the battlefield."
                ),
            ),
            source_text="""
                private static final FilterPermanentCard filter = new FilterPermanentCard(
                    "Rebel permanent card with mana value 5 or less from your graveyard"
                );
                static {
                    filter.add(SubType.REBEL.getPredicate());
                    filter.add(new ManaValuePredicate(ComparisonType.FEWER_THAN, 6));
                }
                Ability ability = new SimpleActivatedAbility(
                    new ReturnFromGraveyardToBattlefieldTargetEffect(), new GenericManaCost(6)
                );
                ability.addCost(new TapSourceCost());
                ability.addTarget(new TargetCardInYourGraveyard(filter));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["target"], "rebel_permanent")
        self.assertEqual(effect["recursion_mana_value_max"], 5)
        self.assertEqual(effect["target_constraints"]["subtypes"], ["rebel"])
        self.assertEqual(effect["target_constraints"]["mana_value_max"], 5)

    def test_recursion_exile_self_variable_x_requires_source_adjuster(self) -> None:
        row = queue_row(
            split.RECURSION_UNIT,
            effect_classes=["ExileSpellEffect", "ReturnFromGraveyardToHandTargetEffect"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Wildest Dreams",
                type_line="Sorcery",
                oracle_text="Return X target cards from your graveyard to your hand. Exile Wildest Dreams.",
            ),
            source_text="""
                this.getSpellAbility().addEffect(new ReturnFromGraveyardToHandTargetEffect());
                this.getSpellAbility().addEffect(new ExileSpellEffect());
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "recursion_exile_self_source_x_count_not_supported")

    def test_static_protection_from_color_creature_maps_to_runtime(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::ProtectionAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["ProtectionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Death Speakers",
                type_line="Creature - Cleric",
                oracle_text="Protection from black",
            ),
            source_text="this.addAbility(ProtectionAbility.from(ObjectColor.BLACK));",
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_PROTECTION_FROM_COLORS_CREATURE_SCOPE)
        self.assertEqual(effect["static_effect"], "self_protection_from_colors")
        self.assertEqual(effect["protection_from"], ["black"])
        self.assertEqual(effect["protection_from_colors"], ["black"])

    def test_static_protection_from_multiple_colors_creature_maps_filter_predicates(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::ProtectionAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["ProtectionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Oversoul of Dusk",
                type_line="Creature - Spirit Avatar",
                oracle_text="Protection from blue, from black, and from red",
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard("blue, black, and red");
                static {
                    filter.add(new ColorPredicate(ObjectColor.BLUE));
                    filter.add(new ColorPredicate(ObjectColor.BLACK));
                    filter.add(new ColorPredicate(ObjectColor.RED));
                }
                this.addAbility(new ProtectionAbility(filter));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["protection_from"], ["blue", "black", "red"])

    def test_static_protection_with_flying_creature_maps_keyword_and_color(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::FlyingAbility,ProtectionAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["FlyingAbility", "ProtectionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Abbey Gargoyles",
                type_line="Creature - Gargoyle",
                oracle_text="Flying, protection from red",
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                this.addAbility(ProtectionAbility.from(ObjectColor.RED));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_PROTECTION_FROM_COLORS_CREATURE_SCOPE)
        self.assertEqual(effect["protection_from"], ["red"])
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["flying"])

    def test_static_protection_from_artifacts_creature_maps_card_type_protection(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::ProtectionAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["ProtectionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Nacatl Savage",
                type_line="Creature - Cat Warrior",
                oracle_text="Protection from artifacts",
            ),
            source_text="""
                this.addAbility(new ProtectionAbility(new FilterArtifactCard("artifacts")));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_PROTECTION_FROM_CARD_TYPES_CREATURE_SCOPE)
        self.assertEqual(effect["static_effect"], "self_protection_from_card_types")
        self.assertEqual(effect["protection_from_card_types"], ["artifact"])

    def test_static_protection_from_card_type_creature_preserves_static_keywords(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::FlyingAbility,ProtectionAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["FlyingAbility", "ProtectionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Azorius First-Wing",
                type_line="Creature - Griffin",
                oracle_text="Flying, protection from enchantments",
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                this.addAbility(new ProtectionAbility(new FilterEnchantmentCard("enchantments")));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_PROTECTION_FROM_CARD_TYPES_CREATURE_SCOPE)
        self.assertEqual(effect["protection_from_card_types"], ["enchantment"])
        self.assertEqual(effect["keywords"], ["flying"])
        self.assertTrue(effect["flying"])

    def test_static_protection_from_card_type_creature_allows_trailing_keyword_clause(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::ProtectionAbility,ReachAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["ProtectionAbility", "ReachAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Tel-Jilad Archers",
                type_line="Creature - Elf Archer",
                oracle_text="Protection from artifacts; reach",
            ),
            source_text="""
                this.addAbility(new ProtectionAbility(new FilterArtifactCard("artifacts")));
                this.addAbility(ReachAbility.getInstance());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_PROTECTION_FROM_CARD_TYPES_CREATURE_SCOPE)
        self.assertEqual(effect["protection_from_card_types"], ["artifact"])
        self.assertEqual(effect["keywords"], ["reach"])
        self.assertTrue(effect["reach"])

    def test_static_protection_from_subtypes_creature_maps_subtype_protection(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::FirstStrikeAbility,FlyingAbility,LifelinkAbility,ProtectionAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["FirstStrikeAbility", "FlyingAbility", "LifelinkAbility", "ProtectionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Baneslayer Angel",
                type_line="Creature - Angel",
                oracle_text="Flying, first strike, lifelink, protection from Demons and from Dragons",
            ),
            source_text="""
                private static final FilterPermanent filter = new FilterCreaturePermanent("Demons and from Dragons");
                filter.add(Predicates.or(SubType.DEMON.getPredicate(), SubType.DRAGON.getPredicate()));
                this.addAbility(FlyingAbility.getInstance());
                this.addAbility(FirstStrikeAbility.getInstance());
                this.addAbility(LifelinkAbility.getInstance());
                this.addAbility(new ProtectionAbility(filter));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_PROTECTION_FROM_SUBTYPES_CREATURE_SCOPE)
        self.assertEqual(effect["static_effect"], "self_protection_from_subtypes")
        self.assertEqual(effect["protection_from_subtypes"], ["demon", "dragon"])
        self.assertEqual(effect["keywords"], ["flying", "first_strike", "lifelink"])

    def test_static_protection_from_subtypes_creature_ignores_source_order(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::ProtectionAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["ProtectionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Kitsune Riftwalker",
                type_line="Creature - Fox Wizard",
                oracle_text="Protection from Spirits and from Arcane",
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard("Spirits and from Arcane");
                filter.add(Predicates.or(SubType.ARCANE.getPredicate(), SubType.SPIRIT.getPredicate()));
                this.addAbility(new ProtectionAbility(filter));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_PROTECTION_FROM_SUBTYPES_CREATURE_SCOPE)
        self.assertEqual(effect["protection_from_subtypes"], ["arcane", "spirit"])

    def test_static_protection_with_flash_creature_maps_timing_keyword_and_color(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::FlashAbility,ProtectionAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["FlashAbility", "ProtectionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Defender of Law",
                type_line="Creature - Human Knight",
                oracle_text="Flash, protection from red",
            ),
            source_text="""
                this.addAbility(FlashAbility.getInstance());
                this.addAbility(ProtectionAbility.from(ObjectColor.RED));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_PROTECTION_FROM_COLORS_CREATURE_SCOPE)
        self.assertEqual(effect["protection_from"], ["red"])
        self.assertEqual(effect["keywords"], ["flash"])
        self.assertTrue(effect["_keywords_are_self"])
        self.assertTrue(effect["flash"])

    def test_static_protection_with_flying_creature_maps_each_color(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::FlyingAbility,ProtectionAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["FlyingAbility", "ProtectionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Iridescent Angel",
                type_line="Creature - Angel",
                oracle_text="Flying, protection from each color",
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                private static final FilterCard filter = new FilterCard("each color");
                static {
                    filter.add(new ColorPredicate(ObjectColor.BLACK));
                    filter.add(new ColorPredicate(ObjectColor.BLUE));
                    filter.add(new ColorPredicate(ObjectColor.GREEN));
                    filter.add(new ColorPredicate(ObjectColor.RED));
                    filter.add(new ColorPredicate(ObjectColor.WHITE));
                }
                this.addAbility(new ProtectionAbility(filter));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["protection_from"], ["white", "blue", "black", "red", "green"])
        self.assertEqual(effect["keywords"], ["flying"])

    def test_static_protection_creature_blocks_multicolored_protection(self) -> None:
        row = queue_row(
            "xmage_signature::no_effect_class::ProtectionAbility::no_target_class::no_condition_class::no_signal",
            effect_classes=[],
            ability_kind="static",
            ability_classes=["ProtectionAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Enemy of the Guildpact",
                type_line="Creature - Spirit",
                oracle_text="Protection from multicolored",
            ),
            source_text="""
                private static final FilterObject<?> filter = new FilterObject<>("multicolored");
                this.addAbility(new ProtectionAbility(filter));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_protection_oracle_not_color_or_card_type_or_subtype_exact")

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

    def test_static_flying_can_block_only_flying_creature_maps_to_runtime(self) -> None:
        row = queue_row(
            split.FLYING_CAN_BLOCK_ONLY_FLYING_UNIT,
            effect_classes=[],
            ability_kind="static",
            ability_classes=["CanBlockOnlyFlyingAbility", "FlyingAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Cloud Elemental",
                type_line="Creature - Elemental",
                oracle_text="Flying\nThis creature can block only creatures with flying.",
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                this.addAbility(new CanBlockOnlyFlyingAbility());
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(
            effect["battle_model_scope"],
            split.STATIC_FLYING_CAN_BLOCK_ONLY_FLYING_CREATURE_SCOPE,
        )
        self.assertEqual(effect["static_effect"], "self_flying_can_block_only_flying")
        self.assertTrue(effect["flying"])
        self.assertTrue(effect["can_block_only_flying"])
        self.assertEqual(effect["block_restriction"], "creatures_with_flying_only")

    def test_static_flying_can_block_only_flying_blocks_nonexact_oracle(self) -> None:
        row = queue_row(
            split.FLYING_CAN_BLOCK_ONLY_FLYING_UNIT,
            effect_classes=[],
            ability_kind="static",
            ability_classes=["CanBlockOnlyFlyingAbility", "FlyingAbility"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Fixture Drake",
                type_line="Creature - Drake",
                oracle_text="Flying\nThis creature can block only creatures with flying or reach.",
            ),
            source_text="""
                this.addAbility(FlyingAbility.getInstance());
                this.addAbility(new CanBlockOnlyFlyingAbility());
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_flying_block_restriction_oracle_not_exact")

    def test_static_generic_cost_reduction_maps_subtype_spells(self) -> None:
        row = queue_row(
            split.STATIC_GENERIC_COST_REDUCTION_UNIT,
            effect_classes=["SpellsCostReductionControllerEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["cost_reduction", "static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Ballyrush Banneret",
                type_line="Creature - Kithkin Soldier",
                oracle_text="Kithkin spells and Soldier spells you cast cost {1} less to cast.",
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard("Kithkin spells and Soldier spells");
                static {
                    filter.add(Predicates.or(
                        SubType.KITHKIN.getPredicate(),
                        SubType.SOLDIER.getPredicate()));
                }
                this.addAbility(new SimpleStaticAbility(
                    new SpellsCostReductionControllerEffect(filter, 1)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["battle_model_scope"], split.STATIC_GENERIC_COST_REDUCTION_SCOPE)
        self.assertEqual(effect["effect"], "static_cost_reduction")
        self.assertEqual(effect["cost_reduction_generic"], 1)
        self.assertEqual(effect["applies_to_subtypes"], ["kithkin", "soldier"])

    def test_static_generic_cost_reduction_maps_color_spells(self) -> None:
        row = queue_row(
            split.STATIC_GENERIC_COST_REDUCTION_UNIT,
            effect_classes=["SpellsCostReductionControllerEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["cost_reduction", "static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Thornscape Familiar",
                type_line="Creature - Insect",
                oracle_text="Red spells and white spells you cast cost {1} less to cast.",
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard("red spells and white spells");
                static {
                    filter.add(Predicates.or(
                        new ColorPredicate(ObjectColor.RED),
                        new ColorPredicate(ObjectColor.WHITE)));
                }
                this.addAbility(new SimpleStaticAbility(
                    new SpellsCostReductionControllerEffect(filter, 1)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["cost_reduction_generic"], 1)
        self.assertEqual(effect["applies_to_spell_colors"], ["W", "R"])

    def test_static_generic_cost_reduction_maps_card_type_and_mana_value_minimum(self) -> None:
        row = queue_row(
            split.STATIC_GENERIC_COST_REDUCTION_UNIT,
            effect_classes=["SpellsCostReductionControllerEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["cost_reduction", "static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Krosan Drover",
                type_line="Creature - Elf",
                oracle_text="Creature spells you cast with mana value 6 or greater cost {2} less to cast.",
            ),
            source_text="""
                private static final FilterCreatureCard filter = new FilterCreatureCard("Creature spells");
                static {
                    filter.add(new ManaValuePredicate(ComparisonType.MORE_THAN, 5));
                }
                this.addAbility(new SimpleStaticAbility(
                    new SpellsCostReductionControllerEffect(filter, 2)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["cost_reduction_generic"], 2)
        self.assertEqual(effect["applies_to_card_types"], ["creature"])
        self.assertEqual(effect["mana_value_min"], 6)

    def test_static_generic_cost_reduction_accepts_xmage_internal_up_to_generic_flag(self) -> None:
        row = queue_row(
            split.STATIC_GENERIC_COST_REDUCTION_UNIT,
            effect_classes=["SpellsCostReductionControllerEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["cost_reduction", "static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Stone Calendar",
                type_line="Artifact",
                oracle_text="Spells you cast cost {1} less to cast.",
            ),
            source_text="""
                this.addAbility(new SimpleStaticAbility(
                    new SpellsCostReductionControllerEffect(new FilterCard("spells"), 1, true)));
            """,
        )

        self.assertEqual(reason, "selected_exact_scope")
        effect = proposal["effect_json"]
        self.assertEqual(effect["cost_reduction_generic"], 1)
        self.assertNotIn("applies_to_card_types", effect)
        self.assertNotIn("cost_reduction_up_to", effect)

    def test_static_generic_cost_reduction_blocks_colored_mana_reductions(self) -> None:
        row = queue_row(
            split.STATIC_GENERIC_COST_REDUCTION_UNIT,
            effect_classes=["SpellsCostReductionControllerEffect"],
            ability_kind="static",
            ability_classes=["SimpleStaticAbility"],
            xmage_signals=["cost_reduction", "static_ability"],
        )
        proposal, reason = split.split_row(
            row,
            metadata(
                name="Edgewalker",
                type_line="Creature - Human Cleric",
                oracle_text=(
                    "Cleric spells you cast cost {W}{B} less to cast. "
                    "This effect reduces only the amount of colored mana you pay."
                ),
            ),
            source_text="""
                private static final FilterCard filter = new FilterCard("Cleric spells");
                static {
                    filter.add(SubType.CLERIC.getPredicate());
                }
                this.addAbility(new SimpleStaticAbility(
                    new SpellsCostReductionControllerEffect(filter, new ManaCostsImpl<>("{W}{B}"))));
            """,
        )

        self.assertIsNone(proposal)
        self.assertEqual(reason, "static_cost_reduction_colored_mana_not_supported")

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
                else "new DamageTargetEffect(FixtureDynamicValue.instance)"
            ),
        )

        self.assertEqual(report["summary"]["proposal_count"], 1)
        self.assertEqual(report["summary"]["blocked_reason_counts"], {"x_damage_source_not_supported": 1})


if __name__ == "__main__":
    unittest.main()
