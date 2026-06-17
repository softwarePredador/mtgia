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
        previous = battle.HANDCRAFTED_KNOWN_CARD_RULES.get("Wrath")
        was_handcrafted = "Wrath" in battle.HANDCRAFTED_KNOWN_CARDS
        try:
            battle.HANDCRAFTED_KNOWN_CARD_RULES["Wrath"] = {"effect": "board_wipe"}
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
                battle.HANDCRAFTED_KNOWN_CARD_RULES.pop("Wrath", None)
            else:
                battle.HANDCRAFTED_KNOWN_CARD_RULES["Wrath"] = previous
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

    def test_crop_rotation_can_find_untapped_high_value_land_with_context():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        dryad_arbor = {
            "name": "Dryad Arbor",
            "effect": "land",
            "type_line": "Land Creature — Forest Dryad",
            "color_identity": ["G"],
        }
        ancient_tomb = {
            "name": "Ancient Tomb",
            "effect": "land",
            "type_line": "Land",
        }
        spell = {"name": "Crop Rotation", "cmc": 1, "type_line": "Instant"}
        active.battlefield = [dryad_arbor]
        active.library = [ancient_tomb]

        battle.apply_effect_immediate(active, [], spell, turn=8, rng=random.Random(721))
        battle.REPLAY_EVENT_HANDLER = None

        assert dryad_arbor in active.graveyard
        assert ancient_tomb not in active.library
        assert any(
            card.get("name") == "Ancient Tomb" and card.get("tapped") is False
            for card in active.battlefield
            if isinstance(card, dict)
        )
        cost_events = [data for event, data in events if event == "additional_cost_paid"]
        assert cost_events
        assert cost_events[0]["strategic_benefit_reason"] == "high_value_land_target"

    def test_crop_rotation_blocks_last_land_for_fetch_without_clear_payoff():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        dryad_arbor = {
            "name": "Dryad Arbor",
            "effect": "land",
            "type_line": "Land Creature — Forest Dryad",
            "color_identity": ["G"],
        }
        marsh_flats = {
            "name": "Marsh Flats",
            "effect": "land",
            "type_line": "Land",
        }
        spell = {"name": "Crop Rotation", "cmc": 1, "type_line": "Instant"}
        active.battlefield = [dryad_arbor]
        active.library = [marsh_flats]

        battle.apply_effect_immediate(active, [], spell, turn=8, rng=random.Random(722))
        battle.REPLAY_EVENT_HANDLER = None

        assert dryad_arbor in active.battlefield
        assert dryad_arbor not in active.graveyard
        assert marsh_flats in active.library
        failed = [data for event, data in events if event == "additional_cost_failed"]
        assert failed
        assert failed[0]["reason"] == "strategic_guardrail"
        assert failed[0]["strategic_guardrail_reason"] in {
            "last_land_spend_without_clear_payoff",
            "unique_color_loss_without_clear_replacement",
        }

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

    def test_tutor_trace_uses_contextual_target_scoring():
        decisions = []
        battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
        active = player("Active")
        land = {"name": "Command Tower", "cmc": 0, "type_line": "Land", "effect": "land"}
        big_creature = {"name": "Large Creature", "cmc": 9, "type_line": "Creature", "effect": "creature"}
        active.library = [big_creature, land]
        tutor = {"name": "Demonic Tutor", "cmc": 2, "type_line": "Sorcery"}

        battle.apply_effect_immediate(active, [], tutor, turn=2, rng=random.Random(78))
        battle.DECISION_TRACE_HANDLER = None

        tutor_decisions = [decision for decision in decisions if decision["decision_type"] == "tutor"]
        assert tutor_decisions
        assert tutor_decisions[0]["chosen_option"]["card"] == "Command Tower"
        assert tutor_decisions[0]["score_components"]["selected_reason"] == "fix_mana_or_land_drop"
        assert land in active.hand

    def test_board_wipe_trace_records_asymmetry_context():
        decisions = []
        battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
        active = player("Active")
        opponent = player("Opponent")
        active.battlefield = [
            {"name": "Small Creature", "effect": "creature", "type_line": "Creature", "power": 1, "toughness": 1},
        ]
        opponent.battlefield = [
            {"name": f"Threat {index}", "effect": "creature", "type_line": "Creature", "power": 3, "toughness": 3}
            for index in range(3)
        ]

        battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Wrath", "cmc": 4, "type_line": "Sorcery", "effect": "board_wipe"},
            turn=5,
            rng=random.Random(79),
        )
        battle.DECISION_TRACE_HANDLER = None

        wipe_decisions = [decision for decision in decisions if decision["decision_type"] == "board_wipe"]
        assert wipe_decisions
        assert wipe_decisions[0]["score_components"]["asymmetry"] == 2
        assert wipe_decisions[0]["risk_flags"] == []

    def test_wheel_trace_uses_multiplayer_discard_draw_model():
        decisions = []
        events = []
        battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        opponent.hand = []
        active.hand = [{"name": "Stranded Spell", "cmc": 5, "type_line": "Sorcery"}]
        active.library = [card(f"Draw {index}", cmc=1) for index in range(8)]
        opponent.library = [card(f"Opponent Draw {index}", cmc=1) for index in range(8)]

        battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Wheel of Fortune", "cmc": 3, "type_line": "Sorcery"},
            turn=3,
            rng=random.Random(80),
        )
        battle.DECISION_TRACE_HANDLER = None
        battle.REPLAY_EVENT_HANDLER = None

        wheel_decisions = [decision for decision in decisions if decision["decision_type"] == "wheel"]
        assert wheel_decisions
        assert wheel_decisions[0]["score_components"]["model_scope"] == "multiplayer_discard_draw_v1"
        assert "wheel_model_simplified" not in wheel_decisions[0]["risk_flags"]
        assert "opponent_refill_risk" in wheel_decisions[0]["risk_flags"]
        assert len(active.hand) == 7
        assert len(opponent.hand) == 7
        assert any(card_item.get("name") == "Stranded Spell" for card_item in active.graveyard)
        wheel_events = [data for event, data in events if event == "wheel_resolved"]
        assert wheel_events
        assert wheel_events[0]["opponent_cards_drawn"] == 7

    def test_wheel_uses_library_of_leng_replacement_for_effect_discard():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        library_of_leng = battle.enrich_card(
            {
                **battle.get_card_effect({"name": "Library of Leng", "type_line": "Artifact"}),
                "name": "Library of Leng",
                "type_line": "Artifact",
            }
        )
        active.battlefield = [library_of_leng]
        active.hand = [
            {
                "name": "Swords to Plowshares",
                "cmc": 1,
                "type_line": "Instant",
                "effect": "remove_creature",
            },
            {
                "name": "Big Spell",
                "cmc": 8,
                "type_line": "Sorcery",
                "effect": "draw_cards",
            },
        ]
        active.library = [card(f"Draw {index}", cmc=1) for index in range(8)]
        opponent.library = [card(f"Opponent Draw {index}", cmc=1) for index in range(8)]

        battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Wheel of Fortune", "cmc": 3, "type_line": "Sorcery"},
            turn=3,
            rng=random.Random(801),
        )
        battle.REPLAY_EVENT_HANDLER = None

        hand_names = [entry.get("name") for entry in active.hand if isinstance(entry, dict)]
        graveyard_names = [entry.get("name") for entry in active.graveyard if isinstance(entry, dict)]
        wheel_events = [data for event, data in events if event == "wheel_resolved"]

        assert "Swords to Plowshares" in hand_names
        assert "Big Spell" in hand_names
        assert "Swords to Plowshares" not in graveyard_names
        assert "Big Spell" not in graveyard_names
        assert wheel_events
        participant = next(item for item in wheel_events[0]["participants"] if item["player"] == "Active")
        assert participant["discarded_to_top"] == ["Swords to Plowshares", "Big Spell"]
        assert participant["discarded_to_graveyard"] == []

    def test_effect_discard_replacement_prefers_keepable_spells_over_graveyard():
        active = player("Active")
        library_of_leng = battle.enrich_card(
            {
                **battle.get_card_effect({"name": "Library of Leng", "type_line": "Artifact"}),
                "name": "Library of Leng",
                "type_line": "Artifact",
            }
        )
        active.battlefield = [library_of_leng]
        swords = {
            "name": "Swords to Plowshares",
            "cmc": 1,
            "type_line": "Instant",
            "effect": "remove_creature",
        }
        filler_land = {
            "name": "Plains",
            "cmc": 0,
            "type_line": "Basic Land — Plains",
            "effect": "land",
        }

        resolution = battle.resolve_effect_discard_cards(
            active,
            [swords, filler_land],
            top_limit=1,
        )

        assert [entry.get("name") for entry in resolution["to_top"]] == ["Swords to Plowshares"]
        assert [entry.get("name") for entry in resolution["to_graveyard"]] == ["Plains"]
        assert [entry.get("name") for entry in active.library[:1]] == ["Swords to Plowshares"]
        assert [entry.get("name") for entry in active.graveyard] == ["Plains"]

    def test_wheel_cast_guard_blocks_opponent_refill_without_payoff():
        active = player("Active")
        opponent = player("Opponent")
        active.hand = [{"name": "Wheel of Fortune", "cmc": 3, "type_line": "Sorcery"}]
        opponent.hand = []

        assert battle.should_cast_wheel(active, [opponent], {"count": 7}) is False

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
        test_crop_rotation_can_find_untapped_high_value_land_with_context,
        test_crop_rotation_blocks_last_land_for_fetch_without_clear_payoff,
        test_land_recursion_returns_graveyard_lands_tapped,
        test_passive_permanent_does_not_draw_or_make_mana_on_resolution,
        test_tutor_to_graveyard_moves_library_card_without_drawing,
        test_mystical_tutor_finds_instant_or_sorcery_only,
        test_tutor_trace_uses_contextual_target_scoring,
        test_board_wipe_trace_records_asymmetry_context,
        test_wheel_trace_uses_multiplayer_discard_draw_model,
        test_wheel_uses_library_of_leng_replacement_for_effect_discard,
        test_effect_discard_replacement_prefers_keepable_spells_over_graveyard,
        test_wheel_cast_guard_blocks_opponent_refill_without_payoff,
        test_reanimation_recursion_returns_creature_to_battlefield,
    ]
