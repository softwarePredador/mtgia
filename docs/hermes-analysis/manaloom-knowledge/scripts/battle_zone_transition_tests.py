"""Zone transition, token lifecycle, tutor, and recursion regressions."""

import random


def register_tests(battle, player, card):
    def test_permanent_activated_removal_text_does_not_become_free_removal():
        staff = {
            "name": "Staff of Compleation",
            "type_line": "Artifact",
            "oracle_text": "{T}, Pay 3 life: Destroy target permanent you own.",
        }
        lantern = {
            "name": "Soul-Guide Lantern",
            "type_line": "Artifact",
            "oracle_text": "When this artifact enters, exile target card from a graveyard.",
        }
        speaker = {
            "name": "Formidable Speaker",
            "type_line": "Creature — Elf Druid",
            "oracle_text": "When this creature enters, you may discard a card. If you do, search your library for a creature card.",
            "power": 2,
            "toughness": 4,
        }

        assert battle.get_card_effect(staff)["effect"] == "ramp_permanent"
        assert battle.get_card_effect(lantern)["effect"] == "hate_artifact"
        assert battle.get_card_effect(speaker)["effect"] == "creature"

    def test_token_destroyed_by_board_wipe_does_not_remain_in_graveyard():
        active = player("Active")
        token = battle.create_creature_token(active, name="Soldier Token", power=1, toughness=1)
        previous = battle.KNOWN_CARDS.get("Wrath")
        was_handcrafted = "Wrath" in battle.HANDCRAFTED_KNOWN_CARDS
        try:
            battle.KNOWN_CARDS["Wrath"] = {"effect": "board_wipe"}
            battle.HANDCRAFTED_KNOWN_CARDS.add("Wrath")
            battle.apply_effect_immediate(
                active,
                [],
                {"name": "Wrath", "cmc": 4, "type_line": "Sorcery"},
                turn=6,
                rng=random.Random(70),
            )
        finally:
            if previous is None:
                battle.KNOWN_CARDS.pop("Wrath", None)
            else:
                battle.KNOWN_CARDS["Wrath"] = previous
            if not was_handcrafted:
                battle.HANDCRAFTED_KNOWN_CARDS.discard("Wrath")

        assert token not in active.battlefield
        assert token not in active.graveyard

    def test_token_sba_removes_tokens_from_non_battlefield_zones():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        token_in_hand = {
            "name": "Hand Token",
            "is_token": True,
            "effect": "creature",
            "type_line": "Creature Token",
        }
        token_in_exile = {
            "name": "Exile Token",
            "tag": "token",
            "effect": "creature",
            "type_line": "Creature Token",
        }
        active.hand = [token_in_hand]
        active.exile = [token_in_exile]

        battle.check_sbas_until_stable([active])

        assert token_in_hand not in active.hand
        assert token_in_exile not in active.exile
        assert [event for event, _ in events].count("token_ceased_to_exist") == 2

    def test_artifact_removal_does_not_destroy_creature_target_by_mistake():
        caster = player("Caster")
        opponent = player("Opponent")
        creature = battle.enrich_card({
            "name": "Real Creature",
            "effect": "creature",
            "type_line": "Creature",
            "power": 6,
            "toughness": 6,
        })
        artifact = battle.enrich_card({
            "name": "Mana Rock",
            "effect": "ramp_permanent",
            "type_line": "Artifact",
            "mana_produced": 1,
        })
        opponent.battlefield = [creature, artifact]
        opponent.life = 35

        battle.apply_effect_immediate(
            caster,
            [opponent],
            {"name": "Nature's Claim", "cmc": 1, "type_line": "Instant"},
            turn=7,
            rng=random.Random(71),
        )

        assert creature in opponent.battlefield
        assert artifact not in opponent.battlefield
        assert artifact in opponent.graveyard
        assert opponent.life == 39

    def test_land_ramp_puts_library_land_tapped_and_spell_goes_to_graveyard():
        active = player("Active")
        forest = {"name": "Forest", "effect": "land", "type_line": "Basic Land — Forest"}
        spell = {"name": "Rampant Growth", "cmc": 2, "type_line": "Sorcery"}
        active.library = [forest]

        battle.apply_effect_immediate(active, [], spell, turn=8, rng=random.Random(72))

        assert spell in active.graveyard
        assert forest not in active.library
        assert any(
            card.get("name") == "Forest" and card.get("tapped") is True
            for card in active.battlefield
            if isinstance(card, dict)
        )
        assert not any(
            card.get("name") == "Rampant Growth"
            for card in active.battlefield
            if isinstance(card, dict)
        )

    def test_land_recursion_returns_graveyard_lands_tapped():
        active = player("Active")
        plains = {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"}
        spell = {"name": "Splendid Reclamation", "cmc": 4, "type_line": "Sorcery"}
        active.graveyard = [plains]

        battle.apply_effect_immediate(active, [], spell, turn=9, rng=random.Random(73))

        assert plains not in active.graveyard
        assert spell in active.graveyard
        assert any(
            card.get("name") == "Plains" and card.get("tapped") is True
            for card in active.battlefield
            if isinstance(card, dict)
        )

    def test_passive_permanent_does_not_draw_or_make_mana_on_resolution():
        active = player("Active")
        active.library = [card("Future Draw", cmc=1)]
        skullclamp = {"name": "Skullclamp", "cmc": 1, "type_line": "Artifact — Equipment"}

        battle.apply_effect_immediate(active, [], skullclamp, turn=10, rng=random.Random(74))

        assert len(active.library) == 1
        assert active.available_mana() == 0
        assert any(
            permanent.get("name") == "Skullclamp" and permanent.get("effect") == "passive"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )

    def test_tutor_to_graveyard_moves_library_card_without_drawing():
        active = player("Active")
        target = {"name": "Graveyard Target", "cmc": 7, "type_line": "Creature", "effect": "creature"}
        active.library = [target, card("Small Card", cmc=1)]
        entomb = {"name": "Entomb", "cmc": 1, "type_line": "Instant"}

        battle.apply_effect_immediate(active, [], entomb, turn=10, rng=random.Random(75))

        assert target not in active.library
        assert target in active.graveyard
        assert entomb in active.graveyard
        assert active.hand == []

    def test_mystical_tutor_finds_instant_or_sorcery_only():
        active = player("Active")
        creature = {"name": "Large Creature", "cmc": 9, "type_line": "Creature", "effect": "creature"}
        instant = {"name": "Target Instant", "cmc": 2, "type_line": "Instant", "effect": "counter"}
        sorcery = {"name": "Target Sorcery", "cmc": 4, "type_line": "Sorcery", "effect": "draw_cards"}
        active.library = [creature, instant, sorcery]
        mystical = {"name": "Mystical Tutor", "cmc": 1, "type_line": "Instant"}

        battle.apply_effect_immediate(active, [], mystical, turn=10, rng=random.Random(77))

        assert creature in active.library
        assert sorcery not in active.library
        assert sorcery in active.hand
        assert mystical in active.graveyard

    def test_reanimation_recursion_returns_creature_to_battlefield():
        active = player("Active")
        target = {
            "name": "Reanimated Creature",
            "cmc": 4,
            "type_line": "Creature",
            "effect": "creature",
            "power": 4,
            "toughness": 4,
        }
        reanimate = {"name": "Reanimate", "cmc": 1, "type_line": "Sorcery"}
        active.graveyard = [target]

        battle.apply_effect_immediate(active, [], reanimate, turn=10, rng=random.Random(76))

        assert target not in active.graveyard
        assert reanimate in active.graveyard
        assert any(
            permanent.get("name") == "Reanimated Creature"
            and permanent.get("effect") == "creature"
            and permanent.get("summoning_sick") is True
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )

    return [
        test_permanent_activated_removal_text_does_not_become_free_removal,
        test_token_destroyed_by_board_wipe_does_not_remain_in_graveyard,
        test_token_sba_removes_tokens_from_non_battlefield_zones,
        test_artifact_removal_does_not_destroy_creature_target_by_mistake,
        test_land_ramp_puts_library_land_tapped_and_spell_goes_to_graveyard,
        test_land_recursion_returns_graveyard_lands_tapped,
        test_passive_permanent_does_not_draw_or_make_mana_on_resolution,
        test_tutor_to_graveyard_moves_library_card_without_drawing,
        test_mystical_tutor_finds_instant_or_sorcery_only,
        test_reanimation_recursion_returns_creature_to_battlefield,
    ]
