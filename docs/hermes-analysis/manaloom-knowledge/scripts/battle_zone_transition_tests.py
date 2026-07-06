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

    def test_exile_removal_moves_commander_to_command_zone_and_off_battlefield():
        caster = player("Caster")
        opponent = player("Opponent")
        commander = battle.enrich_card({
            "name": "Kraum, Ludevic's Opus",
            "effect": "draw_engine",
            "type_line": "Legendary Creature — Zombie Horror",
            "is_commander": True,
            "power": 4,
            "toughness": 4,
        })
        opponent.battlefield = [commander]

        battle.apply_effect_immediate(
            caster,
            [opponent],
            {"name": "Path to Exile", "cmc": 1, "type_line": "Instant"},
            turn=7,
            rng=random.Random(711),
        )

        assert commander not in opponent.battlefield
        assert commander in opponent.command_zone
        assert commander not in opponent.graveyard
        assert commander not in opponent.exile

    def test_zone_move_uses_real_battlefield_object_for_declared_target_copy():
        opponent = player("Opponent")
        commander = battle.enrich_card({
            "name": "Kraum, Ludevic's Opus",
            "effect": "draw_engine",
            "type_line": "Legendary Creature — Zombie Horror",
            "is_commander": True,
            "power": 4,
            "toughness": 4,
        })
        declared_target_copy = dict(commander)
        declared_target_copy["_declared_target_snapshot"] = True
        opponent.battlefield = [commander]

        destination = battle.move_permanent_from_battlefield(
            opponent,
            declared_target_copy,
            reason="removal",
            source={"name": "Path to Exile"},
        )

        assert destination == "command_zone"
        assert commander not in opponent.battlefield
        assert commander in opponent.command_zone
        assert declared_target_copy not in opponent.command_zone

    def test_declared_removal_resolves_snapshot_target_to_live_permanent():
        caster = player("Caster")
        opponent = player("Opponent")
        commander = battle.enrich_card({
            "name": "Kraum, Ludevic's Opus",
            "effect": "draw_engine",
            "type_line": "Legendary Creature — Zombie Horror",
            "is_commander": True,
            "power": 4,
            "toughness": 4,
        })
        declared_target_snapshot = dict(commander)
        declared_target_snapshot["_declared_target_snapshot"] = True
        opponent.battlefield = [commander]

        resolved = battle.resolve_declared_single_removal(
            caster,
            [opponent],
            {"name": "Path to Exile", "cmc": 1, "type_line": "Instant"},
            {
                "effect": "remove_creature",
                "declared_targets": [
                    {
                        "target": declared_target_snapshot,
                        "controller": opponent,
                        "target_type": "creature",
                    }
                ],
            },
            turn=7,
            rng=random.Random(712),
        )

        assert resolved is True
        assert commander not in opponent.battlefield
        assert commander in opponent.command_zone
        assert declared_target_snapshot not in opponent.command_zone

    def test_apply_effect_declared_target_survives_effect_data_deepcopy():
        caster = player("Caster")
        opponent = player("Opponent")
        commander = battle.enrich_card({
            "name": "Kraum, Ludevic's Opus",
            "effect": "draw_engine",
            "type_line": "Legendary Creature — Zombie Horror",
            "is_commander": True,
            "power": 4,
            "toughness": 4,
        })
        opponent.battlefield = [commander]

        battle.apply_effect_immediate(
            caster,
            [opponent],
            {"name": "Path to Exile", "cmc": 1, "type_line": "Instant"},
            turn=7,
            rng=random.Random(713),
            effect_data_override={
                "effect": "remove_creature",
                "declared_targets": [
                    {
                        "target": commander,
                        "controller": opponent,
                        "target_type": "creature",
                    }
                ],
            },
        )

        assert commander not in opponent.battlefield
        assert commander in opponent.command_zone

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

        battle.apply_effect_immediate(
            active,
            [],
            mystical,
            turn=10,
            rng=random.Random(77),
            effect_data_override={
                "effect": "tutor",
                "instant": True,
                "target": "instant_or_sorcery_to_top",
                "battle_model_scope": "instant_or_sorcery_tutor_to_top_v1",
            },
        )

        assert creature in active.library
        assert active.library[0]["name"] == "Target Sorcery"
        assert sorcery in active.library
        assert sorcery not in active.hand
        assert mystical in active.graveyard

    def test_worldly_tutor_puts_creature_on_library_top():
        active = player("Active")
        removal = {"name": "Removal Spell", "cmc": 2, "type_line": "Instant", "effect": "removal_destroy"}
        creature = {"name": "Target Creature", "cmc": 5, "type_line": "Creature", "effect": "creature"}
        active.library = [removal, creature]
        worldly = {"name": "Worldly Tutor", "cmc": 1, "type_line": "Instant"}

        battle.apply_effect_immediate(
            active,
            [],
            worldly,
            turn=10,
            rng=random.Random(78),
            effect_data_override={
                "effect": "tutor",
                "instant": True,
                "target": "creature_to_top",
                "battle_model_scope": "creature_tutor_to_top_v1",
            },
        )

        assert active.library[0]["name"] == "Target Creature"
        assert creature in active.library
        assert creature not in active.hand
        assert worldly in active.graveyard

    def test_vampiric_tutor_puts_best_card_on_library_top_and_loses_two_life():
        active = player("Active")
        active.life = 20
        land = {"name": "Command Tower", "cmc": 0, "type_line": "Land", "effect": "land"}
        engine = {"name": "Rhystic Study", "cmc": 3, "type_line": "Enchantment", "effect": "draw_engine"}
        active.library = [land, engine]
        spell = {"name": "Vampiric Tutor", "cmc": 1, "type_line": "Instant"}

        battle.apply_effect_immediate(
            active,
            [],
            spell,
            turn=10,
            rng=random.Random(79),
            effect_data_override={
                "effect": "tutor",
                "instant": True,
                "target": "any_to_top",
                "controller_loses_life_after_tutor": 2,
                "battle_model_scope": "any_tutor_to_top_lose_two_life_v1",
            },
        )

        assert active.library[0]["name"] == "Rhystic Study"
        assert engine in active.library
        assert engine not in active.hand
        assert active.life == 18
        assert spell in active.graveyard

    def test_imperial_seal_puts_best_card_on_library_top_and_loses_two_life():
        active = player("Active")
        active.life = 18
        land = {"name": "Swamp", "cmc": 0, "type_line": "Land", "effect": "land"}
        engine = {"name": "Necropotence", "cmc": 3, "type_line": "Enchantment", "effect": "draw_engine"}
        active.library = [land, engine]
        spell = {"name": "Imperial Seal", "cmc": 1, "type_line": "Sorcery"}

        battle.apply_effect_immediate(
            active,
            [],
            spell,
            turn=10,
            rng=random.Random(80),
            effect_data_override={
                "effect": "tutor",
                "instant": False,
                "target": "any_to_top",
                "controller_loses_life_after_tutor": 2,
                "battle_model_scope": "any_tutor_to_top_lose_two_life_v1",
            },
        )

        assert active.library[0]["name"] == "Necropotence"
        assert engine in active.library
        assert engine not in active.hand
        assert active.life == 16
        assert spell in active.graveyard

    def test_demonic_tutor_puts_best_card_into_hand():
        active = player("Active")
        land = {"name": "Forest", "cmc": 0, "type_line": "Land", "effect": "land"}
        engine = {"name": "Rhystic Study", "cmc": 3, "type_line": "Enchantment", "effect": "draw_engine"}
        active.library = [land, engine]
        spell = {"name": "Demonic Tutor", "cmc": 2, "type_line": "Sorcery"}

        battle.apply_effect_immediate(
            active,
            [],
            spell,
            turn=10,
            rng=random.Random(81),
            effect_data_override={
                "effect": "tutor",
                "instant": False,
                "target": "any_to_hand",
                "battle_model_scope": "any_tutor_to_hand_v1",
            },
        )

        assert engine not in active.library
        assert engine in active.hand
        assert spell in active.graveyard

    def test_diabolic_intent_sacrifices_creature_and_puts_best_card_into_hand():
        active = player("Active")
        fodder = {
            "name": "Young Wolf",
            "cmc": 1,
            "type_line": "Creature",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
        }
        engine = {"name": "Necropotence", "cmc": 3, "type_line": "Enchantment", "effect": "draw_engine"}
        land = {"name": "Swamp", "cmc": 0, "type_line": "Land", "effect": "land"}
        active.battlefield = [fodder]
        active.library = [land, engine]
        spell = {"name": "Diabolic Intent", "cmc": 2, "type_line": "Sorcery"}

        battle.apply_effect_immediate(
            active,
            [],
            spell,
            turn=10,
            rng=random.Random(82),
            effect_data_override={
                "effect": "tutor",
                "instant": False,
                "target": "any_to_hand",
                "requires_sacrifice_creature": True,
                "battle_model_scope": "sacrifice_creature_any_tutor_to_hand_v1",
            },
        )

        assert fodder not in active.battlefield
        assert fodder in active.graveyard
        assert engine in active.hand
        assert spell in active.graveyard

    def test_sylvan_scrying_puts_land_into_hand():
        active = player("Active")
        land = {"name": "Command Tower", "cmc": 0, "type_line": "Land", "effect": "land"}
        spell_card = {"name": "Counterspell", "cmc": 2, "type_line": "Instant", "effect": "counter"}
        active.library = [spell_card, land]
        spell = {"name": "Sylvan Scrying", "cmc": 2, "type_line": "Sorcery"}

        battle.apply_effect_immediate(
            active,
            [],
            spell,
            turn=10,
            rng=random.Random(83),
            effect_data_override={
                "effect": "tutor",
                "instant": False,
                "target": "land_to_hand",
                "battle_model_scope": "land_tutor_to_hand_v1",
            },
        )

        assert land in active.hand
        assert land not in active.library
        assert spell_card in active.library
        assert spell in active.graveyard

    def test_expedition_map_activated_tutor_puts_land_into_hand():
        active = player("Active")
        active.mana_pool.add_generic(2)
        map_permanent = battle.enrich_card(
            {
                "name": "Expedition Map",
                "cmc": 1,
                "type_line": "Artifact",
                "effect": "ramp_permanent",
                "activated_self_sacrifice_tutor_to_hand": True,
                "activation_cost_generic": 2,
                "activation_requires_tap": True,
                "tutor_target": "land",
                "tutor_destination": "hand",
            }
        )
        land = {"name": "Ancient Tomb", "cmc": 0, "type_line": "Land", "effect": "land"}
        spell_card = {"name": "Wrath of God", "cmc": 4, "type_line": "Sorcery", "effect": "board_wipe"}
        active.battlefield = [map_permanent]
        active.library = [spell_card, land]

        activations = battle.activate_utility_artifacts(
            active,
            [],
            [active],
            turn=10,
            rng=random.Random(831),
            phase="precombat_main",
        )

        assert activations == 1
        assert map_permanent in active.graveyard
        assert land in active.hand
        assert land not in active.library
        assert spell_card in active.library

    def test_armillary_sphere_activated_tutor_puts_two_basic_lands_into_hand():
        active = player("Active")
        active.mana_pool.add_generic(2)
        sphere = battle.enrich_card(
            {
                "name": "Armillary Sphere",
                "cmc": 2,
                "type_line": "Artifact",
                "effect": "artifact",
                "activated_self_sacrifice_tutor_to_hand": True,
                "activation_cost_generic": 2,
                "activation_requires_tap": True,
                "tutor_target": "basic_land",
                "tutor_destination": "hand",
                "tutor_count": 2,
            }
        )
        plains = {"name": "Plains", "cmc": 0, "type_line": "Basic Land - Plains", "effect": "land"}
        mountain = {"name": "Mountain", "cmc": 0, "type_line": "Basic Land - Mountain", "effect": "land"}
        spell_card = {"name": "Wrath of God", "cmc": 4, "type_line": "Sorcery", "effect": "board_wipe"}
        active.battlefield = [sphere]
        active.library = [spell_card, plains, mountain]

        activations = battle.activate_utility_artifacts(
            active,
            [],
            [active],
            turn=10,
            rng=random.Random(570),
            phase="precombat_main",
        )

        assert activations == 1
        assert sphere in active.graveyard
        assert plains in active.hand
        assert mountain in active.hand
        assert plains not in active.library
        assert mountain not in active.library
        assert spell_card in active.library

    def test_moonsilver_key_activated_tutor_prefers_mana_artifact_target():
        active = player("Active")
        active.mana_pool.add_generic(1)
        key_permanent = battle.enrich_card(
            {
                "name": "Moonsilver Key",
                "cmc": 2,
                "type_line": "Artifact",
                "effect": "ramp_permanent",
                "activated_self_sacrifice_tutor_to_hand": True,
                "activation_cost_generic": 1,
                "activation_requires_tap": True,
                "tutor_target": "artifact_mana_ability_or_basic_land",
                "tutor_destination": "hand",
            }
        )
        active.battlefield = [
            key_permanent,
            {"name": "Plains", "type_line": "Basic Land — Plains", "effect": "land"},
            {"name": "Island", "type_line": "Basic Land — Island", "effect": "land"},
            {"name": "Mountain", "type_line": "Basic Land — Mountain", "effect": "land"},
            {"name": "Swamp", "type_line": "Basic Land — Swamp", "effect": "land"},
        ]
        mana_artifact = {
            "name": "Mind Stone",
            "cmc": 2,
            "type_line": "Artifact",
            "effect": "ramp_permanent",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "C",
        }
        non_target_artifact = {
            "name": "Darksteel Plate",
            "cmc": 3,
            "type_line": "Artifact",
            "effect": "passive",
        }
        active.library = [non_target_artifact, mana_artifact]

        activations = battle.activate_utility_artifacts(
            active,
            [],
            [active],
            turn=10,
            rng=random.Random(832),
            phase="precombat_main",
        )

        assert activations == 1
        assert key_permanent in active.graveyard
        assert mana_artifact in active.hand
        assert mana_artifact not in active.library
        assert non_target_artifact in active.library

    def test_journeyers_kite_activated_tutor_to_hand_does_not_sacrifice_source():
        active = player("Active")
        active.mana_pool.add_generic(3)
        kite = battle.enrich_card(
            {
                "name": "Journeyer's Kite",
                "cmc": 2,
                "type_line": "Artifact",
                "effect": "artifact",
                "_activated_rule_effects": [
                    {
                        "effect": "tutor",
                        "battle_model_scope": "xmage_permanent_simple_activated_library_search_to_hand_v1",
                        "ability_kind": "activated",
                        "activated_effect": "tutor",
                        "activation_cost_generic": 3,
                        "activation_cost_colors": [],
                        "activation_requires_tap": True,
                        "activation_requires_sacrifice": False,
                        "target": "basic_land",
                        "tutor_target": "basic_land",
                        "count": 1,
                        "tutor_count": 1,
                        "destination": "hand",
                        "tutor_destination": "hand",
                    }
                ],
            }
        )
        plains = {"name": "Plains", "cmc": 0, "type_line": "Basic Land - Plains", "effect": "land"}
        command_tower = {"name": "Command Tower", "cmc": 0, "type_line": "Land", "effect": "land"}
        active.battlefield = [kite]
        active.library = [command_tower, plains]

        activations = battle.activate_utility_artifacts(
            active,
            [],
            [active],
            turn=10,
            rng=random.Random(571),
            phase="precombat_main",
        )

        assert activations == 1
        assert kite in active.battlefield
        assert kite not in active.graveyard
        assert kite.get("tapped") is True
        assert plains in active.hand
        assert command_tower in active.library

    def test_captain_sisay_activated_tutor_finds_legendary_card_only():
        active = player("Active")
        sisay = battle.enrich_card(
            {
                "name": "Captain Sisay",
                "cmc": 4,
                "type_line": "Legendary Creature - Human Soldier",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "summoning_sick": False,
                "_activated_rule_effects": [
                    {
                        "effect": "tutor",
                        "battle_model_scope": "xmage_permanent_simple_activated_library_search_to_hand_v1",
                        "ability_kind": "activated",
                        "activated_effect": "tutor",
                        "activation_cost_generic": 0,
                        "activation_cost_colors": [],
                        "activation_requires_tap": True,
                        "activation_requires_sacrifice": False,
                        "target": "any",
                        "tutor_target": "any",
                        "required_supertypes": ["legendary"],
                        "count": 1,
                        "tutor_count": 1,
                        "destination": "hand",
                        "tutor_destination": "hand",
                    }
                ],
            }
        )
        legendary = {
            "name": "The One Ring",
            "cmc": 4,
            "type_line": "Legendary Artifact",
            "effect": "draw_engine",
        }
        nonlegendary = {"name": "Sol Ring", "cmc": 1, "type_line": "Artifact", "effect": "ramp_permanent"}
        active.battlefield = [sisay]
        active.library = [nonlegendary, legendary]

        activations = battle.activate_utility_artifacts(
            active,
            [],
            [active],
            turn=10,
            rng=random.Random(572),
            phase="precombat_main",
        )

        assert activations == 1
        assert sisay.get("tapped") is True
        assert legendary in active.hand
        assert nonlegendary in active.library

    def test_captain_sisay_activated_tutor_blocks_summoning_sick_creature():
        active = player("Active")
        sisay = battle.enrich_card(
            {
                "name": "Captain Sisay",
                "cmc": 4,
                "type_line": "Legendary Creature - Human Soldier",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "summoning_sick": True,
                "_activated_rule_effects": [
                    {
                        "effect": "tutor",
                        "battle_model_scope": "xmage_permanent_simple_activated_library_search_to_hand_v1",
                        "ability_kind": "activated",
                        "activated_effect": "tutor",
                        "activation_cost_generic": 0,
                        "activation_cost_colors": [],
                        "activation_requires_tap": True,
                        "activation_requires_sacrifice": False,
                        "target": "any",
                        "tutor_target": "any",
                        "required_supertypes": ["legendary"],
                        "count": 1,
                        "tutor_count": 1,
                        "destination": "hand",
                        "tutor_destination": "hand",
                    }
                ],
            }
        )
        legendary = {
            "name": "The One Ring",
            "cmc": 4,
            "type_line": "Legendary Artifact",
            "effect": "draw_engine",
        }
        active.battlefield = [sisay]
        active.library = [legendary]

        activations = battle.activate_utility_artifacts(
            active,
            [],
            [active],
            turn=10,
            rng=random.Random(573),
            phase="precombat_main",
        )

        assert activations == 0
        assert sisay.get("tapped") is not True
        assert legendary in active.library
        assert legendary not in active.hand

    def test_dragonstorm_forecaster_activated_tutor_respects_target_names():
        active = player("Active")
        active.mana_pool.add_generic(2)
        forecaster = battle.enrich_card(
            {
                "name": "Dragonstorm Forecaster",
                "cmc": 3,
                "type_line": "Creature - Human Shaman",
                "effect": "creature",
                "power": 2,
                "toughness": 3,
                "summoning_sick": False,
                "_activated_rule_effects": [
                    {
                        "effect": "tutor",
                        "battle_model_scope": "xmage_permanent_simple_activated_library_search_to_hand_v1",
                        "ability_kind": "activated",
                        "activated_effect": "tutor",
                        "activation_cost_generic": 2,
                        "activation_cost_colors": [],
                        "activation_requires_tap": True,
                        "activation_requires_sacrifice": False,
                        "target": "any",
                        "tutor_target": "any",
                        "target_names": ["Dragonstorm Globe", "Boulderborn Dragon"],
                        "count": 1,
                        "tutor_count": 1,
                        "destination": "hand",
                        "tutor_destination": "hand",
                    }
                ],
            }
        )
        target = {
            "name": "Boulderborn Dragon",
            "cmc": 7,
            "type_line": "Creature - Dragon",
            "effect": "creature",
        }
        non_target = {"name": "Ancient Gold Dragon", "cmc": 7, "type_line": "Creature - Dragon", "effect": "creature"}
        active.battlefield = [forecaster]
        active.library = [non_target, target]

        activations = battle.activate_utility_artifacts(
            active,
            [],
            [active],
            turn=10,
            rng=random.Random(574),
            phase="precombat_main",
        )

        assert activations == 1
        assert forecaster.get("tapped") is True
        assert target in active.hand
        assert non_target in active.library

    def test_claws_of_gix_life_gain_sacrifices_target_permanent_cost():
        active = player("Active")
        active.life = 37
        active.mana_pool.add_generic(1)
        claws = battle.enrich_card(
            {
                "name": "Claws of Gix",
                "cmc": 0,
                "type_line": "Artifact",
                "effect": "artifact",
                "battle_model_scope": "xmage_permanent_simple_activated_life_gain_v1",
                "activated_battle_model_scope": "xmage_permanent_simple_activated_life_gain_v1",
                "activated_effect": "controller_gain_life",
                "life_gain_amount": 1,
                "activated_life_gain_amount": 1,
                "activation_cost_mana": "{1}",
                "activation_cost_generic": 1,
                "activation_cost_colors": [],
                "activation_requires_tap": False,
                "activation_requires_sacrifice": False,
                "activation_sacrifice_target": "permanent",
                "activation_requires_sacrifice_target": True,
            }
        )
        servo = {
            "name": "Servo Token",
            "type_line": "Artifact Creature - Servo",
            "effect": "creature",
            "token": True,
            "is_token": True,
            "power": 1,
            "toughness": 1,
        }
        active.battlefield = [claws, servo]

        activations = battle.activate_utility_artifacts(
            active,
            [],
            [active],
            turn=10,
            rng=random.Random(575),
            phase="precombat_main",
        )

        assert activations == 1
        assert active.life == 38
        assert claws in active.battlefield
        assert servo not in active.battlefield
        assert servo not in active.graveyard

    def test_ravenous_baloth_life_gain_sacrifices_beast_only():
        active = player("Active")
        active.life = 34
        baloth = battle.enrich_card(
            {
                "name": "Ravenous Baloth",
                "cmc": 4,
                "type_line": "Creature - Beast",
                "effect": "creature",
                "power": 4,
                "toughness": 4,
                "summoning_sick": False,
                "battle_model_scope": "xmage_permanent_simple_activated_life_gain_v1",
                "activated_battle_model_scope": "xmage_permanent_simple_activated_life_gain_v1",
                "activated_effect": "controller_gain_life",
                "life_gain_amount": 4,
                "activated_life_gain_amount": 4,
                "activation_cost_mana": "{0}",
                "activation_cost_generic": 0,
                "activation_cost_colors": [],
                "activation_requires_tap": False,
                "activation_requires_sacrifice": False,
                "activation_sacrifice_target": "beast",
                "activation_requires_sacrifice_target": True,
            }
        )
        beast_token = {
            "name": "Beast Token",
            "type_line": "Creature - Beast",
            "effect": "creature",
            "token": True,
            "is_token": True,
            "power": 3,
            "toughness": 3,
        }
        elf = {
            "name": "Elf Token",
            "type_line": "Creature - Elf",
            "effect": "creature",
            "token": True,
            "is_token": True,
            "power": 1,
            "toughness": 1,
        }
        active.battlefield = [baloth, elf, beast_token]

        activations = battle.activate_utility_artifacts(
            active,
            [],
            [active],
            turn=10,
            rng=random.Random(576),
            phase="precombat_main",
        )

        assert activations == 1
        assert active.life == 38
        assert baloth in active.battlefield
        assert beast_token not in active.battlefield
        assert elf in active.battlefield

    def test_attrition_activated_destroy_sacrifices_creature_cost():
        active = player("Active")
        opponent = player("Opponent")
        attrition = battle.enrich_card(
            {
                "name": "Attrition",
                "cmc": 3,
                "type_line": "Enchantment",
                "effect": "enchantment",
                "_activated_rule_effects": [
                    {
                        "effect": "remove_creature",
                        "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
                        "ability_kind": "activated",
                        "activated_effect": "destroy_target",
                        "activated_remove_effect": "remove_creature",
                        "activated_remove_target": "nonblack_creature",
                        "target": "creature",
                        "target_constraints": {"card_types": ["creature"], "exclude_colors": ["B"]},
                        "destination": "graveyard",
                        "activation_cost_mana": "{0}",
                        "activation_cost_generic": 0,
                        "activation_cost_colors": [],
                        "activation_requires_tap": False,
                        "activation_requires_sacrifice": False,
                        "activation_sacrifice_target": "creature",
                        "activation_requires_sacrifice_target": True,
                    }
                ],
            }
        )
        expendable = {
            "name": "Servo Token",
            "type_line": "Artifact Creature - Servo",
            "effect": "creature",
            "token": True,
            "is_token": True,
            "power": 1,
            "toughness": 1,
        }
        black_creature = {
            "name": "Black Knight",
            "type_line": "Creature - Human Knight",
            "effect": "creature",
            "colors": ["B"],
            "power": 2,
            "toughness": 2,
        }
        white_creature = {
            "name": "Serra Angel",
            "type_line": "Creature - Angel",
            "effect": "creature",
            "colors": ["W"],
            "power": 4,
            "toughness": 4,
        }
        active.battlefield = [attrition, expendable]
        opponent.battlefield = [black_creature, white_creature]

        activated = battle.activate_best_generic_destroy_permanent(
            active,
            [opponent],
            [active, opponent],
            turn=10,
            rng=random.Random(573),
            phase="precombat_main",
        )

        assert activated is True
        assert attrition in active.battlefield
        assert expendable not in active.battlefield
        assert expendable not in active.graveyard
        assert black_creature in opponent.battlefield
        assert white_creature not in opponent.battlefield
        assert white_creature in opponent.graveyard

    def test_skirk_prospector_sacrifices_goblin_for_contextual_mana():
        active = player("Active")
        skirk = battle.enrich_card(
            {
                "name": "Skirk Prospector",
                "cmc": 1,
                "type_line": "Creature - Goblin",
                "effect": "ramp_permanent",
                "battle_model_scope": "xmage_target_sacrifice_mana_source_permanent_v1",
                "ability_kind": "activated_mana",
                "is_mana_source": True,
                "mana_source_contextual_only": True,
                "mana_produced": 1,
                "produces": "R",
                "produced_mana_symbols": ["R"],
                "activation_sacrifice_target": "goblin",
                "mana_activation_requires_sacrifice_target": True,
                "activation_requires_sacrifice_target": True,
                "mana_activation_requires_tap": False,
                "activation_requires_tap": False,
            }
        )
        goblin_token = {
            "name": "Goblin Token",
            "type_line": "Creature - Goblin",
            "effect": "creature",
            "token": True,
            "is_token": True,
            "power": 1,
            "toughness": 1,
        }
        payoff = {
            "name": "Shock",
            "mana_cost": "{R}",
            "cmc": 1,
            "type_line": "Instant",
            "effect": "direct_damage",
        }
        active.battlefield = [skirk, goblin_token]
        active.hand = [payoff]

        activated = battle.activate_self_sacrifice_mana_sources(
            active,
            [],
            [active],
            turn=3,
            phase="precombat_main",
        )

        assert activated == 1
        assert skirk in active.battlefield
        assert goblin_token not in active.battlefield
        assert goblin_token not in active.graveyard
        assert active.mana_pool.red == 1

    def test_weathered_wayfarer_activated_tutor_requires_opponent_more_lands():
        active = player("Active")
        opponent = player("Opponent")
        active.mana_pool.add("white", 1)
        wayfarer = battle.enrich_card(
            {
                "name": "Weathered Wayfarer",
                "cmc": 1,
                "type_line": "Creature — Human Nomad Cleric",
                "effect": "creature",
                "power": 1,
                "toughness": 1,
                "summoning_sick": False,
                "land_tutor_to_hand_activated": True,
                "activation_cost_generic": 0,
                "activation_cost_colors": ["W"],
                "activation_requires_tap": True,
                "activation_condition": "opponent_controls_more_lands",
                "tutor_target": "land",
                "tutor_destination": "hand",
            }
        )
        active.battlefield = [
            wayfarer,
            {"name": "Plains", "type_line": "Basic Land — Plains", "effect": "land"},
            {"name": "Mountain", "type_line": "Basic Land — Mountain", "effect": "land"},
        ]
        opponent.battlefield = [
            {"name": "Island", "type_line": "Basic Land — Island", "effect": "land"},
            {"name": "Swamp", "type_line": "Basic Land — Swamp", "effect": "land"},
            {"name": "Forest", "type_line": "Basic Land — Forest", "effect": "land"},
        ]
        land = {"name": "Command Tower", "cmc": 0, "type_line": "Land", "effect": "land"}
        spell_card = {"name": "Farewell", "cmc": 6, "type_line": "Sorcery", "effect": "board_wipe"}
        active.library = [spell_card, land]

        battle.activate_land_tutor_creatures(active, turn=10, opponents=[opponent])

        assert wayfarer.get("tapped") is True
        assert land in active.hand
        assert land not in active.library
        assert spell_card in active.library

    def test_spellseeker_etb_finds_cheap_instant_or_sorcery_only():
        active = player("Active")
        removal = {"name": "Swords to Plowshares", "cmc": 1, "type_line": "Instant", "effect": "remove_creature"}
        big_spell = {"name": "Time Warp", "cmc": 5, "type_line": "Sorcery", "effect": "extra_turn"}
        creature = {"name": "Birds of Paradise", "cmc": 1, "type_line": "Creature", "effect": "creature"}
        active.library = [big_spell, creature, removal]
        spellseeker = {"name": "Spellseeker", "cmc": 3, "type_line": "Creature"}

        battle.apply_effect_immediate(
            active,
            [],
            spellseeker,
            turn=10,
            rng=random.Random(84),
            effect_data_override={
                "effect": "creature",
                "power": 1,
                "toughness": 1,
                "etb_tutor_target": "cheap_instant_or_sorcery",
                "battle_model_scope": "spellseeker_etb_instant_or_sorcery_mana_value_2_or_less_to_hand_v1",
            },
        )

        assert removal in active.hand
        assert removal not in active.library
        assert big_spell in active.library
        assert creature in active.library

    def test_trophy_mage_etb_finds_artifact_with_mana_value_three_only():
        active = player("Active")
        cheap_artifact = {"name": "Sol Ring", "cmc": 1, "type_line": "Artifact", "effect": "ramp_permanent"}
        target_artifact = {"name": "Chromatic Lantern", "cmc": 3, "type_line": "Artifact", "effect": "ramp_engine"}
        creature = {"name": "Hullbreaker Horror", "cmc": 7, "type_line": "Creature", "effect": "creature"}
        active.library = [cheap_artifact, creature, target_artifact]
        trophy_mage = {"name": "Trophy Mage", "cmc": 3, "type_line": "Creature"}

        battle.apply_effect_immediate(
            active,
            [],
            trophy_mage,
            turn=10,
            rng=random.Random(85),
            effect_data_override={
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "etb_tutor_target": "artifact_mana_value_3",
                "battle_model_scope": "trophy_mage_etb_artifact_mana_value_3_to_hand_v1",
            },
        )

        assert target_artifact in active.hand
        assert target_artifact not in active.library
        assert cheap_artifact in active.library
        assert creature in active.library

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

    def test_draw_seven_non_wheel_override_draws_only_controller():
        decisions = []
        events = []
        battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        active.hand = []
        opponent.hand = []
        active.library = [card(f"Draw {index}", cmc=1) for index in range(8)]
        opponent.library = [card(f"Opponent Draw {index}", cmc=1) for index in range(8)]

        battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Jin-Gitaxias, Core Augur",
                "cmc": 10,
                "type_line": "Legendary Creature - Phyrexian Praetor",
                "effect": "draw_cards",
                "count": 7,
                "wheel_like": False,
            },
            turn=3,
            rng=random.Random(81),
        )
        battle.DECISION_TRACE_HANDLER = None
        battle.REPLAY_EVENT_HANDLER = None

        assert len(active.hand) == 7
        assert len(opponent.hand) == 0
        assert not [decision for decision in decisions if decision["decision_type"] == "wheel"]
        assert not [data for event, data in events if event == "wheel_resolved"]
        draw_events = [data for event, data in events if event == "draw_cards_resolved"]
        assert draw_events
        assert draw_events[0]["cards_drawn"] == 7

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

        assert battle.should_cast_wheel(
            active,
            [opponent],
            {"name": "Wheel of Fortune", "count": 7},
        ) is False

    def test_wheel_cast_guard_blocks_self_decking_even_with_payoff():
        active = player("Active")
        opponent = player("Opponent")
        active.hand = [{"name": "Wheel of Fortune", "cmc": 3, "type_line": "Sorcery"}]
        active.library = [{"name": "Only Draw", "cmc": 1, "type_line": "Instant"}]
        active.battlefield = [
            {
                "name": "Smothering Tithe",
                "cmc": 4,
                "effect": "ramp_engine",
                "type_line": "Enchantment",
            }
        ]
        opponent.hand = [{"name": "Opponent Card", "cmc": 1, "type_line": "Instant"}]

        context = battle.wheel_decision_context(active, [opponent], 7)

        assert context["payoff_expected"] is True
        assert context["library_cards_before"] == 1
        assert context["library_can_support_draw"] is False
        assert battle.should_cast_wheel(
            active,
            [opponent],
            {"name": "Wheel of Fortune", "count": 7},
        ) is False

    def test_reforge_defaults_wheel_draw_count_to_seven():
        active = player("Active")
        opponent = player("Opponent")
        active.hand = [{"name": "Reforge the Soul", "cmc": 5, "type_line": "Sorcery"}]
        opponent.hand = []

        assert battle.wheel_like_draw_count(
            {"name": "Reforge the Soul", "cmc": 5, "type_line": "Sorcery"},
            battle.get_card_effect({"name": "Reforge the Soul", "cmc": 5, "type_line": "Sorcery"}),
            player=active,
            opponents=[opponent],
        ) == 7

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
        test_exile_removal_moves_commander_to_command_zone_and_off_battlefield,
        test_zone_move_uses_real_battlefield_object_for_declared_target_copy,
        test_declared_removal_resolves_snapshot_target_to_live_permanent,
        test_apply_effect_declared_target_survives_effect_data_deepcopy,
        test_land_ramp_puts_library_land_tapped_and_spell_goes_to_graveyard,
        test_crop_rotation_can_find_untapped_high_value_land_with_context,
        test_crop_rotation_blocks_last_land_for_fetch_without_clear_payoff,
        test_land_recursion_returns_graveyard_lands_tapped,
        test_passive_permanent_does_not_draw_or_make_mana_on_resolution,
        test_tutor_to_graveyard_moves_library_card_without_drawing,
        test_mystical_tutor_finds_instant_or_sorcery_only,
        test_worldly_tutor_puts_creature_on_library_top,
        test_vampiric_tutor_puts_best_card_on_library_top_and_loses_two_life,
        test_imperial_seal_puts_best_card_on_library_top_and_loses_two_life,
        test_demonic_tutor_puts_best_card_into_hand,
        test_diabolic_intent_sacrifices_creature_and_puts_best_card_into_hand,
        test_sylvan_scrying_puts_land_into_hand,
        test_expedition_map_activated_tutor_puts_land_into_hand,
        test_armillary_sphere_activated_tutor_puts_two_basic_lands_into_hand,
        test_moonsilver_key_activated_tutor_prefers_mana_artifact_target,
        test_journeyers_kite_activated_tutor_to_hand_does_not_sacrifice_source,
        test_captain_sisay_activated_tutor_finds_legendary_card_only,
        test_captain_sisay_activated_tutor_blocks_summoning_sick_creature,
        test_dragonstorm_forecaster_activated_tutor_respects_target_names,
        test_claws_of_gix_life_gain_sacrifices_target_permanent_cost,
        test_ravenous_baloth_life_gain_sacrifices_beast_only,
        test_attrition_activated_destroy_sacrifices_creature_cost,
        test_skirk_prospector_sacrifices_goblin_for_contextual_mana,
        test_weathered_wayfarer_activated_tutor_requires_opponent_more_lands,
        test_spellseeker_etb_finds_cheap_instant_or_sorcery_only,
        test_trophy_mage_etb_finds_artifact_with_mana_value_three_only,
        test_tutor_trace_uses_contextual_target_scoring,
        test_board_wipe_trace_records_asymmetry_context,
        test_wheel_trace_uses_multiplayer_discard_draw_model,
        test_draw_seven_non_wheel_override_draws_only_controller,
        test_wheel_uses_library_of_leng_replacement_for_effect_discard,
        test_effect_discard_replacement_prefers_keepable_spells_over_graveyard,
        test_wheel_cast_guard_blocks_opponent_refill_without_payoff,
        test_wheel_cast_guard_blocks_self_decking_even_with_payoff,
        test_reforge_defaults_wheel_draw_count_to_seven,
        test_reanimation_recursion_returns_creature_to_battlefield,
    ]
