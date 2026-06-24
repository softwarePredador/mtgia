"""Summoning sickness, haste, vigilance, and creature activation regressions."""

import random


def register_tests(battle, player, card):
    def test_summoning_sick_creature_cannot_attack_until_next_turn():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        attacker = player("Attacker")
        defender = player("Defender")
        creature = {
            "name": "Fresh Creature",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
            "summoning_sick": True,
            "tapped": False,
        }
        attacker.battlefield = [creature]

        battle.combat_phase_v8(
            attacker,
            [defender],
            [attacker, defender],
            turn=2,
            rng=random.Random(33),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert creature["tapped"] is False
        assert defender.life == 40
        assert not [event for event, _ in events if event == "combat"]

    def test_creature_loses_summoning_sickness_at_start_of_controller_turn_and_taps_to_attack():
        active = player("Active", [card("Draw")])
        defender = player("Defender", [card("Opp Draw")])
        creature = {
            "name": "Ready Next Turn",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
            "summoning_sick": True,
            "tapped": False,
        }
        active.battlefield = [creature]

        battle.play_turn_v8(
            active,
            [defender],
            [active, defender],
            turn=3,
            rng=random.Random(34),
            stack=battle.Stack(),
        )

        assert creature["summoning_sick"] is False
        assert creature["tapped"] is True
        assert defender.life == 37

    def test_haste_creature_can_attack_while_summoning_sick_and_taps():
        attacker = player("Attacker")
        defender = player("Defender")
        creature = battle.enrich_card({
            "name": "Hasty Creature",
            "effect": "creature",
            "type_line": "Creature",
            "oracle_text": "Haste",
            "power": 4,
            "toughness": 4,
            "summoning_sick": True,
            "tapped": False,
        })
        attacker.battlefield = [creature]

        battle.combat_phase_v8(
            attacker,
            [defender],
            [attacker, defender],
            turn=2,
            rng=random.Random(35),
            stack=battle.Stack(),
        )

        assert attacker.battlefield[0]["tapped"] is True
        assert defender.life == 36

    def test_vigilance_creature_attacks_without_tapping():
        attacker = player("Attacker")
        defender = player("Defender")
        creature = battle.enrich_card({
            "name": "Vigilant Creature",
            "effect": "creature",
            "type_line": "Creature",
            "oracle_text": "Vigilance",
            "power": 3,
            "toughness": 3,
            "summoning_sick": False,
            "tapped": False,
        })
        attacker.battlefield = [creature]

        battle.combat_phase_v8(
            attacker,
            [defender],
            [attacker, defender],
            turn=2,
            rng=random.Random(44),
            stack=battle.Stack(),
        )

        assert attacker.battlefield[0]["tapped"] is False
        assert defender.life == 37

    def test_engine_creature_enters_with_summoning_sickness():
        active = player("Active")
        defender = player("Defender")
        battle.apply_effect_immediate(
            active,
            [defender],
            {
                "name": "Jin-Gitaxias, Progress Tyrant",
                "cmc": 7,
                "type_line": "Legendary Creature — Phyrexian Praetor",
                "oracle_text": "Whenever you cast an artifact, instant, or sorcery spell, copy that spell.",
                "power": 5,
                "toughness": 5,
            },
            turn=2,
            rng=random.Random(67),
        )

        permanent = active.battlefield[0]
        assert battle.is_battlefield_creature(permanent) is True
        assert permanent["effect"] == "copy_spell"
        assert permanent["summoning_sick"] is True
        assert permanent["tapped"] is False

        battle.combat_phase_v8(
            active,
            [defender],
            [active, defender],
            2,
            random.Random(68),
            battle.Stack(),
        )

        assert permanent["tapped"] is False
        assert defender.life == 40

    def test_contextual_haste_text_does_not_grant_self_haste():
        rionya = battle.enrich_card({
            "name": "Rionya, Fire Dancer",
            "type_line": "Legendary Creature — Human Wizard",
            "oracle_text": "At the beginning of combat on your turn, create X tokens. They gain haste.",
            "keywords": ["haste"],
        })
        spider_punk = battle.enrich_card({
            "name": "Spider-Punk",
            "type_line": "Creature",
            "oracle_text": "Haste",
            "keywords": ["haste"],
        })

        assert battle.has_haste(rionya) is False
        assert battle.has_haste(spider_punk) is True

    def test_token_maker_tokens_are_sick_unless_rule_grants_haste():
        active = player("Active")
        defender = player("Defender")
        token_spell = {"name": "Token Maker", "cmc": 4, "type_line": "Sorcery"}

        previous_normal = battle.HANDCRAFTED_KNOWN_CARD_RULES.get("Token Maker")
        previous_hasty = battle.HANDCRAFTED_KNOWN_CARD_RULES.get("Hasty Token Maker")
        normal_was_handcrafted = "Token Maker" in battle.HANDCRAFTED_KNOWN_CARDS
        hasty_was_handcrafted = "Hasty Token Maker" in battle.HANDCRAFTED_KNOWN_CARDS
        try:
            battle.HANDCRAFTED_KNOWN_CARD_RULES["Token Maker"] = {
                "effect": "token_maker",
                "token_count": 1,
                "token_power": 2,
            }
            battle.HANDCRAFTED_KNOWN_CARD_RULES["Hasty Token Maker"] = {
                "effect": "token_maker",
                "token_count": 1,
                "token_power": 2,
                "token_haste": True,
            }
            battle.HANDCRAFTED_KNOWN_CARDS.update({"Token Maker", "Hasty Token Maker"})

            battle.apply_effect_immediate(active, [defender], token_spell, 2, random.Random(36))
            token = active.battlefield[0]
            assert token["summoning_sick"] is True
            battle.combat_phase_v8(
                active,
                [defender],
                [active, defender],
                2,
                random.Random(36),
                battle.Stack(),
            )
            assert token["tapped"] is False
            assert defender.life == 40

            hasty = player("Hasty")
            hasty_spell = {**token_spell, "name": "Hasty Token Maker"}
            battle.apply_effect_immediate(hasty, [defender], hasty_spell, 2, random.Random(37))
            assert hasty.battlefield[0]["summoning_sick"] is False
            assert hasty.battlefield[0]["haste"] is True
            battle.combat_phase_v8(
                hasty,
                [defender],
                [hasty, defender],
                2,
                random.Random(37),
                battle.Stack(),
            )
            assert hasty.battlefield[0]["tapped"] is True
        finally:
            if previous_normal is None:
                battle.HANDCRAFTED_KNOWN_CARD_RULES.pop("Token Maker", None)
            else:
                battle.HANDCRAFTED_KNOWN_CARD_RULES["Token Maker"] = previous_normal
            if previous_hasty is None:
                battle.HANDCRAFTED_KNOWN_CARD_RULES.pop("Hasty Token Maker", None)
            else:
                battle.HANDCRAFTED_KNOWN_CARD_RULES["Hasty Token Maker"] = previous_hasty
            if not normal_was_handcrafted:
                battle.HANDCRAFTED_KNOWN_CARDS.discard("Token Maker")
            if not hasty_was_handcrafted:
                battle.HANDCRAFTED_KNOWN_CARDS.discard("Hasty Token Maker")

    def test_springheart_landfall_creates_sick_insect_token():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        nantuko = battle.enrich_card(
            {
                "name": "Springheart Nantuko",
                "effect": "creature",
                "type_line": "Enchantment Creature — Insect Monk",
                "power": 1,
                "toughness": 1,
                "landfall_optional_pay_copy_attached_creature_else_insect": True,
                "landfall_copy_cost": "{1}{G}",
                "token_name": "Insect Token",
                "token_subtype": "Insect",
                "token_colors": ["G"],
                "token_power": 1,
                "token_toughness": 1,
                "battle_model_scope": "landfall_optional_pay_copy_attached_creature_else_insect_v1",
            }
        )
        land = {"name": "Forest", "effect": "land", "type_line": "Basic Land — Forest"}
        active.battlefield = [nantuko, land]

        battle.trigger_landfall(active, land, turn=3, source_event="test_land_played")

        tokens = [card for card in active.battlefield if card.get("name") == "Insect Token"]
        assert len(tokens) == 1
        assert tokens[0]["power"] == 1
        assert tokens[0]["summoning_sick"] is True
        trigger = next(data for event, data in events if event == "trigger_resolved")
        assert trigger["trigger"] == "landfall"
        assert trigger["tokens_created"] == 1

    def test_springheart_landfall_pays_to_copy_attached_creature():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        target = battle.enrich_card(
            {
                "name": "Seasoned Dungeoneer",
                "effect": "creature",
                "type_line": "Creature — Human Warrior",
                "power": 3,
                "toughness": 4,
            }
        )
        nantuko = battle.enrich_card(
            {
                "name": "Springheart Nantuko",
                "effect": "creature",
                "type_line": "Enchantment Creature — Insect Monk",
                "power": 1,
                "toughness": 1,
                "landfall_optional_pay_copy_attached_creature_else_insect": True,
                "landfall_copy_cost": "{1}{G}",
                "attached_to": "Seasoned Dungeoneer",
                "token_name": "Insect Token",
                "token_subtype": "Insect",
                "token_colors": ["G"],
                "token_power": 1,
                "token_toughness": 1,
                "battle_model_scope": "landfall_optional_pay_copy_attached_creature_else_insect_v1",
            }
        )
        land_one = {"name": "Forest", "effect": "land", "type_line": "Basic Land — Forest"}
        land_two = {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"}
        active.battlefield = [target, nantuko, land_one, land_two]
        active.refresh_mana_sources(turn=4)

        battle.trigger_landfall(active, land_two, turn=4, source_event="test_land_played")

        copies = [card for card in active.battlefield if card.get("copy_of") == "Seasoned Dungeoneer"]
        insects = [card for card in active.battlefield if card.get("name") == "Insect Token"]
        assert len(copies) == 1
        assert not insects
        assert copies[0]["power"] == 3
        assert copies[0]["toughness"] == 4
        assert copies[0]["summoning_sick"] is True
        copy_event = next(data for event, data in events if event == "copy_creature_token_created")
        assert copy_event["target"] == "Seasoned Dungeoneer"
        trigger = next(
            data
            for event, data in events
            if event == "trigger_resolved"
            and data.get("card") == "Springheart Nantuko"
            and data.get("effect") == "copy_attached_creature_or_insect"
        )
        assert trigger["paid_copy_cost"] is True
        assert trigger["copied_target"] == "Seasoned Dungeoneer"

    def test_creature_mana_source_has_summoning_sickness_then_refreshes_mana():
        active = player("Active")
        plague_myr = {
            "name": "Plague Myr",
            "effect": "creature",
            "type_line": "Artifact Creature — Phyrexian Myr",
            "power": 1,
            "toughness": 1,
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "C",
        }
        active.hand = [plague_myr]
        active.battlefield = [
            {"name": "Wastes", "effect": "land", "type_line": "Basic Land"}
            for _ in range(2)
        ]
        active.refresh_mana_sources(turn=1)
        active.spend_card_mana(plague_myr)
        active.hand.remove(plague_myr)
        permanent = battle.enrich_card({**plague_myr, **battle.get_card_effect(plague_myr)})
        permanent["effect"] = "creature"
        permanent["summoning_sick"] = True
        permanent["tapped"] = False
        active.battlefield.append(permanent)

        assert active.untapped_creatures() == []
        active.refresh_mana_sources(turn=1)
        assert active.available_mana() == 2
        permanent["summoning_sick"] = False
        active.refresh_mana_sources(turn=2)
        assert active.available_mana() == 3

    def test_elvish_reclaimer_cannot_activate_while_summoning_sick():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.library = [{"name": "Forest", "effect": "land", "type_line": "Basic Land — Forest"}]
        active.battlefield = [
            {"name": "Forest A", "effect": "land", "type_line": "Basic Land — Forest"},
            {"name": "Forest B", "effect": "land", "type_line": "Basic Land — Forest"},
            {
                "name": "Elvish Reclaimer",
                "effect": "creature",
                "type_line": "Creature — Elf Warrior",
                "power": 1,
                "toughness": 2,
                "land_tutor_activated": True,
                "summoning_sick": True,
                "tapped": False,
            },
        ]
        active.refresh_mana_sources(turn=1)

        battle.activate_land_tutor_creatures(active, turn=1)

        assert len(active.library) == 1
        assert not [event for event, _ in events if event == "activated_ability"]

    def test_elvish_reclaimer_activates_after_sickness_clears():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.library = [{"name": "Forest", "effect": "land", "type_line": "Basic Land — Forest"}]
        reclaimer = {
            "name": "Elvish Reclaimer",
            "effect": "creature",
            "type_line": "Creature — Elf Warrior",
            "power": 1,
            "toughness": 2,
            "land_tutor_activated": True,
            "summoning_sick": False,
            "tapped": False,
        }
        active.battlefield = [
            {"name": "Forest A", "effect": "land", "type_line": "Basic Land — Forest"},
            {"name": "Forest B", "effect": "land", "type_line": "Basic Land — Forest"},
            reclaimer,
        ]
        active.refresh_mana_sources(turn=2)

        battle.activate_land_tutor_creatures(active, turn=2)

        assert active.library == []
        assert reclaimer["tapped"] is True
        assert any(event == "activated_ability" for event, _ in events)

    def test_elvish_reclaimer_does_not_sacrifice_unique_color_for_tapped_basic():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.library = [{"name": "Forest", "effect": "land", "type_line": "Basic Land — Forest"}]
        reclaimer = {
            "name": "Elvish Reclaimer",
            "effect": "creature",
            "type_line": "Creature — Elf Warrior",
            "power": 1,
            "toughness": 2,
            "land_tutor_activated": True,
            "summoning_sick": False,
            "tapped": False,
        }
        active.battlefield = [
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            reclaimer,
        ]
        active.refresh_mana_sources(turn=2)

        battle.activate_land_tutor_creatures(active, turn=2)

        assert [card["name"] for card in active.library] == ["Forest"]
        assert reclaimer["tapped"] is False
        skipped = [data for event, data in events if event == "activated_ability_skipped"]
        assert skipped
        assert skipped[-1]["reason"] == "strategic_guardrail"
        assert skipped[-1]["strategic_guardrail_reason"] == "unique_color_loss_without_clear_replacement"

    def test_elvish_reclaimer_prefers_redundant_tapped_land_for_high_value_target():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.library = [{"name": "Ancient Tomb", "effect": "land", "type_line": "Land"}]
        reclaimer = {
            "name": "Elvish Reclaimer",
            "effect": "creature",
            "type_line": "Creature — Elf Warrior",
            "power": 1,
            "toughness": 2,
            "land_tutor_activated": True,
            "summoning_sick": False,
            "tapped": False,
        }
        active.battlefield = [
            {"name": "Plains A", "effect": "land", "type_line": "Basic Land — Plains", "tapped": True},
            {"name": "Plains B", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            reclaimer,
        ]
        active.refresh_mana_sources(turn=2)

        battle.activate_land_tutor_creatures(active, turn=2)

        assert active.library == []
        assert "Plains A" in [card["name"] for card in active.graveyard]
        assert "Ancient Tomb" in [card["name"] for card in active.battlefield]
        activated = [data for event, data in events if event == "activated_ability"]
        assert activated
        assert activated[-1]["sacrificed"] == "Plains A"
        assert activated[-1]["found"] == "Ancient Tomb"
        assert activated[-1]["strategic_benefit_reason"] == "no_scarce_land_risk"
        assert any(
            option["name"] == "Ancient Tomb" and option["high_value_target"]
            for option in activated[-1]["land_ramp_target_options"]
        )

    return [
        test_summoning_sick_creature_cannot_attack_until_next_turn,
        test_creature_loses_summoning_sickness_at_start_of_controller_turn_and_taps_to_attack,
        test_haste_creature_can_attack_while_summoning_sick_and_taps,
        test_vigilance_creature_attacks_without_tapping,
        test_engine_creature_enters_with_summoning_sickness,
        test_contextual_haste_text_does_not_grant_self_haste,
        test_token_maker_tokens_are_sick_unless_rule_grants_haste,
        test_springheart_landfall_creates_sick_insect_token,
        test_creature_mana_source_has_summoning_sickness_then_refreshes_mana,
        test_elvish_reclaimer_cannot_activate_while_summoning_sick,
        test_elvish_reclaimer_activates_after_sickness_clears,
        test_elvish_reclaimer_does_not_sacrifice_unique_color_for_tapped_basic,
        test_elvish_reclaimer_prefers_redundant_tapped_land_for_high_value_target,
    ]
