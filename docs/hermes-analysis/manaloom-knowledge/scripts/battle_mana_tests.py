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

    return [
        test_mana_sources_do_not_refill_after_spending,
        test_treasures_are_spent_without_refilling_sources,
        test_colored_mana_requires_the_correct_color,
        test_treasure_and_flexible_sources_pay_colored_costs,
        test_basic_lands_refresh_as_colored_sources,
        test_hybrid_and_phyrexian_mana_use_legal_payment_options,
    ]
