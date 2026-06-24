"""Mana and payment conformance tests for battle_analyst_v9."""


def register_tests(battle, player):
    def test_mana_sources_do_not_refill_after_spending():
        active = player("Active")
        active.battlefield = ["land", "land", "land"]
        active.refresh_mana_sources(turn=1)

        assert active.available_mana() == 3
        assert active.spend_mana(3) is True
        assert active.available_mana() == 0
        assert active.available_mana() == 0

    def test_treasures_are_spent_without_refilling_sources():
        active = player("Active")
        active.battlefield = ["land"]
        active.treasures = 2
        active.refresh_mana_sources(turn=1)

        assert active.available_mana() == 3
        assert active.spend_mana(2) is True
        assert active.available_mana() == 1
        assert active.treasures == 1

    def test_colored_mana_requires_the_correct_color():
        active = player("Active")
        active.mana_pool.add("white", 1)
        active.mana_pool.add_generic(2)
        white_spell = {"name": "White Spell", "cmc": 2, "mana_cost": "{1}{W}"}
        blue_spell = {"name": "Blue Spell", "cmc": 2, "mana_cost": "{1}{U}"}

        assert active.can_pay_card(white_spell) is True
        assert active.can_pay_card(blue_spell) is False
        assert active.spend_card_mana(white_spell) is True
        assert active.available_mana() == 1

    def test_treasure_and_flexible_sources_pay_colored_costs():
        active = player("Active")
        active.mana_pool.add("wildcard", 1)
        active.treasures = 1
        spell = {"name": "Dimir Spell", "cmc": 2, "mana_cost": "{U}{B}"}

        assert active.can_pay_card(spell) is True
        assert active.spend_card_mana(spell) is True
        assert active.available_mana() == 0
        assert active.treasures == 0

    def test_basic_lands_refresh_as_colored_sources():
        active = player("Active")
        active.battlefield = [
            {"name": "Plains", "effect": "land"},
            {"name": "Island", "effect": "land"},
        ]
        active.refresh_mana_sources(turn=1)

        assert active.mana_pool.white == 1
        assert active.mana_pool.blue == 1
        assert active.can_pay_card({"name": "Azorius", "cmc": 2, "mana_cost": "{W}{U}"})

    def test_l1b_nonfetch_lands_refresh_as_flexible_mana_sources():
        active = player("Active")
        active.battlefield = [
            {
                "name": "City of Brass",
                "effect": "land",
                "produces": "WUBRG",
                "mana_produced": 1,
                "battle_model_scope": "five_color_tap_damage_land_annotation_v1",
                "tap_damage_status": "annotation_only",
            },
            {
                "name": "Battlefield Forge",
                "effect": "land",
                "produces": "CWR",
                "mana_produced": 1,
                "battle_model_scope": "pain_land_flexible_mana_life_loss_annotation_v1",
                "life_loss_on_colored_mana_status": "annotation_only",
            },
        ]
        active.refresh_mana_sources(turn=1)

        assert active.mana_pool.wildcard == 2
        assert active.can_pay_card({"name": "Boros Spell", "cmc": 2, "mana_cost": "{W}{R}"})
        assert active.spend_card_mana({"name": "Boros Spell", "cmc": 2, "mana_cost": "{W}{R}"})
        assert active.available_mana() == 0

    def test_l3a_artifact_mana_rocks_refresh_with_oracle_scopes():
        active = player("Active")
        active.battlefield = [
            {
                "name": "Arcane Signet",
                "effect": "ramp_permanent",
                "type_line": "Artifact",
                "produces": "RW",
                "mana_produced": 1,
                "battle_model_scope": "commander_identity_mana_rock_deck_scoped_v1",
            },
            {
                "name": "Boros Signet",
                "effect": "ramp_permanent",
                "type_line": "Artifact",
                "produces": "RW",
                "mana_produced": 1,
                "activation_cost_generic": 1,
                "activation_cost_status": "abstracted_as_net_one_mana",
                "battle_model_scope": "activation_cost_net_mana_pair_rock_v1",
            },
            {
                "name": "Sol Ring",
                "effect": "ramp_permanent",
                "type_line": "Artifact",
                "produces": "C",
                "mana_produced": 2,
                "battle_model_scope": "colorless_two_mana_rock_v1",
            },
            {
                "name": "Mana Vault",
                "effect": "ramp_permanent",
                "type_line": "Artifact",
                "produces": "C",
                "mana_produced": 3,
                "normal_untap_status": "annotation_only",
                "draw_step_damage_status": "annotation_only",
                "battle_model_scope": "fast_mana_artifact_partial_v1",
            },
            {
                "name": "Mox Amber",
                "effect": "ramp_permanent",
                "type_line": "Legendary Artifact",
                "produces": "WUBRGC",
                "mana_produced": 1,
                "requires_legendary_creature_or_planeswalker_for_mana": True,
                "battle_model_scope": "legend_gated_fast_mana_v1",
            },
        ]

        active.refresh_mana_sources(turn=1)
        assert active.available_mana() == 7
        assert active.mana_pool.wildcard == 2
        assert active.mana_pool.colorless == 5

        active.battlefield.append(
            {
                "name": "Lorehold, the Historian",
                "effect": "creature",
                "type_line": "Legendary Creature - Elder Dragon",
                "power": 5,
                "toughness": 5,
            }
        )
        active.refresh_mana_sources(turn=2)
        assert active.available_mana() == 8
        assert active.mana_pool.wildcard == 3

    def test_pain_mana_source_shapes_refresh_without_new_runtime_executor():
        active = player("Active")
        active.battlefield = [
            {
                "name": "Elves of Deep Shadow",
                "effect": "creature",
                "type_line": "Creature — Elf Druid",
                "power": 1,
                "toughness": 1,
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "B",
                "damage_on_tap": 1,
                "tap_damage_status": "annotation_only",
                "summoning_sick": False,
            },
            {
                "name": "Talisman of Curiosity",
                "effect": "ramp_permanent",
                "type_line": "Artifact",
                "mana_produced": 1,
                "produces": "CUG",
                "life_for_colored_mana": 1,
                "battle_model_scope": "pain_talisman_color_pair_partial_v1",
            },
            {
                "name": "Tarnished Citadel",
                "effect": "land",
                "type_line": "Land",
                "mana_produced": 1,
                "produces": "CWUBRG",
                "life_for_colored_mana": 3,
                "life_loss_on_colored_mana_status": "annotation_only",
                "battle_model_scope": "colorless_or_any_color_pain_land_v1",
            },
        ]

        active.refresh_mana_sources(turn=1)
        assert active.available_mana() == 3
        assert active.mana_pool.black == 1
        assert active.mana_pool.wildcard == 2
        assert active.life == 40

    def test_global_creatures_tap_for_any_color_passive_turns_creatures_into_mana_sources():
        active = player("Active")
        active.battlefield = [
            {
                "name": "Cryptolith Rite",
                "effect": "passive",
                "type_line": "Enchantment",
                "creatures_tap_for_any_color": True,
                "battle_model_scope": "creatures_tap_any_color_static_enchantment_v1",
            },
            {
                "name": "Support Creature",
                "effect": "creature",
                "type_line": "Creature — Elf",
                "power": 2,
                "toughness": 2,
                "summoning_sick": False,
            },
            {
                "name": "Plant Token",
                "effect": "creature",
                "type_line": "Token Creature — Plant",
                "power": 0,
                "toughness": 1,
                "is_token": True,
                "summoning_sick": False,
            },
        ]

        active.refresh_mana_sources(turn=2)
        assert active.available_mana() == 2
        assert active.mana_pool.wildcard == 2

    def test_enduring_vitality_static_mana_grant_respects_summoning_sickness_on_self():
        active = player("Active")
        active.battlefield = [
            {
                "name": "Enduring Vitality",
                "effect": "creature",
                "type_line": "Enchantment Creature — Elk Glimmer",
                "power": 3,
                "toughness": 3,
                "vigilance": True,
                "creatures_tap_for_any_color": True,
                "summoning_sick": True,
                "battle_model_scope": "vigilance_three_three_creatures_tap_any_color_v1",
            },
            {
                "name": "Old Mana Body",
                "effect": "creature",
                "type_line": "Creature — Elf",
                "power": 1,
                "toughness": 1,
                "summoning_sick": False,
            },
        ]

        active.refresh_mana_sources(turn=3)
        assert active.available_mana() == 1
        assert active.mana_pool.wildcard == 1

    def test_training_grounds_reduces_generic_creature_activation_cost_to_floor_one():
        active = player("Active")
        active.battlefield = [
            {
                "name": "Training Grounds",
                "type_line": "Enchantment",
                "effect": "static_cost_reduction",
                "battle_model_scope": "static_activated_ability_cost_reduction_variant_v1",
                "cost_reduction_applies_to": "activated_abilities_of_creatures_you_control",
                "cost_reduction_generic": 2,
                "cost_reduction_minimum_total_mana": 1,
            }
        ]
        creature = {
            "name": "Utility Creature",
            "type_line": "Creature - Advisor",
        }

        assert battle.adjusted_activated_ability_generic_cost(active, creature, 3) == 1
        assert battle.adjusted_activated_ability_generic_cost(active, creature, 1) == 1
        assert battle.adjusted_activated_ability_generic_cost(
            active,
            creature,
            1,
            activation_colors=["U"],
        ) == 0

    def test_training_grounds_does_not_reduce_artifact_activation_cost():
        active = player("Active")
        active.battlefield = [
            {
                "name": "Training Grounds",
                "type_line": "Enchantment",
                "effect": "static_cost_reduction",
                "battle_model_scope": "static_activated_ability_cost_reduction_variant_v1",
                "cost_reduction_applies_to": "activated_abilities_of_creatures_you_control",
                "cost_reduction_generic": 2,
                "cost_reduction_minimum_total_mana": 1,
            }
        ]
        artifact = {
            "name": "Mind Stone",
            "type_line": "Artifact",
        }

        assert battle.adjusted_activated_ability_generic_cost(active, artifact, 2) == 2

    def test_hybrid_and_phyrexian_mana_use_legal_payment_options():
        white_payer = player("White")
        white_payer.mana_pool.add("white", 1)
        hybrid_spell = {"name": "Azorius Hybrid", "cmc": 1, "mana_cost": "{W/U}"}

        assert white_payer.can_pay_card(hybrid_spell) is True
        assert white_payer.spend_card_mana(hybrid_spell) is True
        assert white_payer.mana_pool.white == 0

        blue_payer = player("Blue")
        blue_payer.mana_pool.add("blue", 1)

        assert blue_payer.can_pay_card(hybrid_spell) is True
        assert blue_payer.spend_card_mana(hybrid_spell) is True
        assert blue_payer.mana_pool.blue == 0

        red_payer = player("Red")
        red_payer.mana_pool.add("red", 1)

        assert red_payer.can_pay_card(hybrid_spell) is False
        assert red_payer.available_mana() == 1

        life_payer = player("Life")
        life_payer.life = 10
        phyrexian_spell = {"name": "Phyrexian White", "cmc": 1, "mana_cost": "{W/P}"}

        assert life_payer.can_pay_card(phyrexian_spell) is True
        assert life_payer.spend_card_mana(phyrexian_spell) is True
        assert life_payer.life == 8

        mana_payer = player("Mana")
        mana_payer.life = 10
        mana_payer.mana_pool.add("white", 1)

        assert mana_payer.spend_card_mana(phyrexian_spell) is True
        assert mana_payer.life == 10
        assert mana_payer.mana_pool.white == 0

        low_life_payer = player("Low Life")
        low_life_payer.life = 1

        assert low_life_payer.can_pay_card(phyrexian_spell) is False
        assert low_life_payer.life == 1

    def test_monocolored_hybrid_and_hybrid_phyrexian_mana_use_legal_payment_options():
        white_payer = player("White")
        white_payer.mana_pool.add("white", 1)
        monocolored_hybrid_spell = {
            "name": "Monocolored Hybrid",
            "cmc": 2,
            "mana_cost": "{2/W}",
        }

        assert white_payer.can_pay_card(monocolored_hybrid_spell) is True
        assert white_payer.spend_card_mana(monocolored_hybrid_spell) is True
        assert white_payer.mana_pool.white == 0

        generic_payer = player("Generic")
        generic_payer.mana_pool.add_generic(2)

        assert generic_payer.can_pay_card(monocolored_hybrid_spell) is True
        assert generic_payer.spend_card_mana(monocolored_hybrid_spell) is True
        assert generic_payer.available_mana() == 0

        short_payer = player("Short")
        short_payer.mana_pool.add_generic(1)

        assert short_payer.can_pay_card(monocolored_hybrid_spell) is False

        blue_life_payer = player("Blue Life")
        blue_life_payer.life = 10
        hybrid_phyrexian_spell = {
            "name": "Hybrid Phyrexian",
            "cmc": 1,
            "mana_cost": "{W/U/P}",
        }

        assert blue_life_payer.can_pay_card(hybrid_phyrexian_spell) is True
        assert blue_life_payer.spend_card_mana(hybrid_phyrexian_spell) is True
        assert blue_life_payer.life == 8

        blue_mana_payer = player("Blue Mana")
        blue_mana_payer.life = 10
        blue_mana_payer.mana_pool.add("blue", 1)

        assert blue_mana_payer.spend_card_mana(hybrid_phyrexian_spell) is True
        assert blue_mana_payer.life == 10
        assert blue_mana_payer.mana_pool.blue == 0

    def test_restricted_mana_only_pays_matching_spell_categories():
        creature_payer = player("Creature Payer")
        creature_payer.add_restricted_mana(
            2,
            "creature_spell_only",
            color="wildcard",
        )
        creature_spell = {
            "name": "Restricted Creature",
            "cmc": 2,
            "mana_cost": "{1}{G}",
            "type_line": "Creature — Elf",
        }
        instant_spell = {
            "name": "Restricted Instant",
            "cmc": 2,
            "mana_cost": "{1}{G}",
            "type_line": "Instant",
        }

        assert creature_payer.available_mana() == 0
        assert creature_payer.can_pay_card(creature_spell) is True
        assert creature_payer.can_pay_card(instant_spell) is False
        assert creature_payer.spend_card_mana(creature_spell) is True
        assert creature_payer.restricted_mana == {}

    def test_restricted_mana_combines_with_treasure_for_matching_generic_costs():
        active = player("Active")
        active.add_restricted_mana(1, "creature_spell_only", color="generic")
        active.treasures = 1
        creature_spell = {
            "name": "Two Generic Creature",
            "cmc": 2,
            "mana_cost": "{2}",
            "type_line": "Creature",
        }
        noncreature_spell = {
            "name": "Two Generic Instant",
            "cmc": 2,
            "mana_cost": "{2}",
            "type_line": "Instant",
        }

        assert active.can_pay_card(noncreature_spell) is False
        assert active.can_pay_card(creature_spell) is True
        assert active.spend_card_mana(creature_spell) is True
        assert active.treasures == 0
        assert active.restricted_mana == {}

    return [
        test_mana_sources_do_not_refill_after_spending,
        test_treasures_are_spent_without_refilling_sources,
        test_colored_mana_requires_the_correct_color,
        test_treasure_and_flexible_sources_pay_colored_costs,
        test_basic_lands_refresh_as_colored_sources,
        test_l1b_nonfetch_lands_refresh_as_flexible_mana_sources,
        test_l3a_artifact_mana_rocks_refresh_with_oracle_scopes,
        test_pain_mana_source_shapes_refresh_without_new_runtime_executor,
        test_global_creatures_tap_for_any_color_passive_turns_creatures_into_mana_sources,
        test_enduring_vitality_static_mana_grant_respects_summoning_sickness_on_self,
        test_training_grounds_reduces_generic_creature_activation_cost_to_floor_one,
        test_training_grounds_does_not_reduce_artifact_activation_cost,
        test_hybrid_and_phyrexian_mana_use_legal_payment_options,
        test_monocolored_hybrid_and_hybrid_phyrexian_mana_use_legal_payment_options,
        test_restricted_mana_only_pays_matching_spell_categories,
        test_restricted_mana_combines_with_treasure_for_matching_generic_costs,
    ]
