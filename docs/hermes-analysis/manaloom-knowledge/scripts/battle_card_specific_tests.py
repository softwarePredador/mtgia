"""Card-specific Commander regression tests for battle_analyst_v9."""

import random
import sqlite3
import tempfile
from pathlib import Path


def _card(name, cmc=99, effect="unknown", power=0):
    return {
        "name": name,
        "cmc": cmc,
        "tag": effect,
        "effect": effect,
        "type_line": "Creature" if effect == "creature" else "Sorcery",
        "power": power,
    }


def register_tests(battle, player):
    def test_lorehold_miracle_requires_lorehold_on_battlefield():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player(
            "Lorehold",
            [
                {
                    "name": "Reforge the Soul",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                _card("Filler"),
            ],
        )
        active.is_human = True
        active.battlefield = ["land", "land"]
        opponent = player("Opponent", [_card("Opp Filler")])

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(17),
            stack=battle.Stack(),
        )

        assert not any(event == "miracle_cast" for event, _ in events)
        assert any(c.get("name") == "Reforge the Soul" for c in active.hand)

    def test_lorehold_miracle_casts_first_draw_only_with_lorehold():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player(
            "Lorehold",
            [
                {
                    "name": "Reforge the Soul",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                *[_card(f"Filler {index}") for index in range(10)],
            ],
        )
        active.is_human = True
        active.battlefield = [
            {"name": "Lorehold, the Historian", "effect": "creature", "power": 3},
            "land",
            "land",
        ]
        opponent = player("Opponent", [_card("Opp Filler")])
        opponent.hand = [_card(f"Opp Keep {index}") for index in range(7)]

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(18),
            stack=battle.Stack(),
        )

        assert any(event == "miracle_cast" for event, _ in events)
        assert active.graveyard[0]["name"] == "Reforge the Soul"

    def test_lorehold_miracle_does_not_use_second_draw_of_turn():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Lorehold")
        active.is_human = True
        active.cards_drawn_this_turn = 1
        active._cards_drawn_turn_marker = 2
        battle.CURRENT_REPLAY_TURN = 2
        active.library = [
            {
                "name": "Reforge the Soul",
                "cmc": 7,
                "type_line": "Sorcery",
            },
            _card("Filler"),
        ]
        active.battlefield = [
            {"name": "Lorehold, the Historian", "effect": "creature", "power": 3},
            {
                "name": "The One Ring",
                "effect": "draw_engine",
                "burden": True,
                "burden_counters": 0,
                "activated_burden_draw": True,
                "activation_requires_tap": True,
            },
            "land",
            "land",
        ]
        opponent = player("Opponent")

        battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(19),
            phase="postcombat_main",
        )

        assert not any(event == "miracle_cast" for event, _ in events)
        assert any(c.get("name") == "Reforge the Soul" for c in active.hand)

    def test_lorehold_miracle_skips_bad_wheel_refill():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player(
            "Lorehold",
            [
                {
                    "name": "Reforge the Soul",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                *[_card(f"Filler {index}") for index in range(4)],
            ],
        )
        active.is_human = True
        active.battlefield = [
            {"name": "Lorehold, the Historian", "effect": "creature", "power": 3},
            "land",
            "land",
        ]
        opponent = player("Opponent", [])

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(191),
            stack=battle.Stack(),
        )

        assert not any(event == "miracle_cast" for event, _ in events)
        assert any(c.get("name") == "Reforge the Soul" for c in active.hand)

    def test_lorehold_miracle_does_not_cast_counter_without_stack_target():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            py = {
                "name": "Pyroblast",
                "cmc": 1,
                "type_line": "Instant",
                "effect": "counter",
                "tag": "counter",
            }
            active = player("Lorehold", [py])
            active.hand = [py]
            active.is_human = True
            active.battlefield = [
                {"name": "Lorehold, the Historian", "effect": "creature", "power": 3},
            ]
            active.mana_pool.add_generic(2)
            stack = battle.Stack()

            cast = battle.try_lorehold_miracle_cast(
                active,
                [py],
                turn=2,
                phase="upkeep",
                all_players=[active],
                rng=random.Random(192),
                stack=stack,
                source="test_topdeck",
                miracle_candidate=py,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert cast is False
        assert py in active.hand
        assert stack.empty()
        assert not any(event == "miracle_cast" for event, _ in events)

    def test_lorehold_miracle_does_not_cast_redirect_without_stack_target():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            swat = {
                "name": "Deflecting Swat",
                "cmc": 3,
                "type_line": "Instant",
            }
            active = player("Lorehold", [swat])
            active.hand = [swat]
            active.is_human = True
            active.battlefield = [
                {"name": "Lorehold, the Historian", "effect": "creature", "power": 3},
            ]
            active.mana_pool.add_generic(2)
            stack = battle.Stack()

            cast = battle.try_lorehold_miracle_cast(
                active,
                [swat],
                turn=2,
                phase="draw_step",
                all_players=[active],
                rng=random.Random(193),
                stack=stack,
                source="test_topdeck",
                miracle_candidate=swat,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert cast is False
        assert swat in active.hand
        assert stack.empty()
        assert not any(event == "miracle_cast" for event, _ in events)

    def test_lorehold_upkeep_rummage_emits_pg035_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            lorehold_card = {
                "name": "Lorehold, the Historian",
                "cmc": 5,
                "type_line": "Legendary Creature — Elder Dragon",
                "mana_cost": "{3}{R}{W}",
            }
            lorehold_effect = battle.get_card_effect(lorehold_card)
            assert lorehold_effect["effect"] == "passive"
            assert lorehold_effect["cmc"] == 5.0
            assert lorehold_effect["flying"] is True
            assert lorehold_effect["haste"] is True
            assert lorehold_effect["_rule_logical_key"] == "battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4"
            assert lorehold_effect["_rule_oracle_hash"] == "f1b6d4f38a533e56f0efb5a3f1547214"

            active = player("Lorehold")
            active.is_human = True
            active.battlefield = [
                {**lorehold_card, **lorehold_effect},
                {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
                {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            ]
            active.hand = [
                {
                    "name": "Nine Mana Spell",
                    "cmc": 9,
                    "type_line": "Sorcery",
                    "effect": "draw_cards",
                }
            ]
            active.library = [
                {
                    "name": "Reforge the Soul",
                    "cmc": 7,
                    "type_line": "Sorcery",
                }
            ]
            active.refresh_mana_sources(turn=5)
            opponent = player("Opponent")
            opponent.library = [_card("Opponent Draw", cmc=1)]

            triggered = battle.process_lorehold_opponent_upkeep_rummage(
                opponent,
                [active, opponent],
                5,
                random.Random(196),
                battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert triggered == 1
        rummage_event = next(
            data
            for event, data in events
            if event == "lorehold_upkeep_rummage"
        )
        assert rummage_event["discarded"] == "Nine Mana Spell"
        assert rummage_event["drawn"] == "Reforge the Soul"
        assert rummage_event["rule_logical_key"] == "battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4"
        assert rummage_event["rule_oracle_hash"] == "f1b6d4f38a533e56f0efb5a3f1547214"
        assert rummage_event["rule_review_status"] == "active"
        assert rummage_event["rule_execution_status"] == "auto"

    def test_past_in_flames_grants_flashback_with_pg036_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            past = {
                "name": "Past in Flames",
                "cmc": 4,
                "mana_cost": "{3}{R}",
                "type_line": "Sorcery",
            }
            past_effect = battle.get_card_effect(past)
            assert past_effect["effect"] == "graveyard_flashback_grant"
            assert past_effect["battle_model_scope"] == (
                "past_in_flames_graveyard_instants_sorceries_flashback_until_eot_v1"
            )
            assert past_effect["_rule_logical_key"] == "battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be"
            assert past_effect["_rule_oracle_hash"] == "12f293d8d746fbc4e5ba80828919dec5"

            active = player("Lorehold")
            instant = {
                "name": "Battle Cantrip",
                "cmc": 1,
                "mana_cost": "{1}",
                "type_line": "Instant",
                "effect": "draw_cards",
                "count": 1,
            }
            sorcery = {
                "name": "Reforge the Soul",
                "cmc": 5,
                "mana_cost": "{3}{R}{R}",
                "type_line": "Sorcery",
                "effect": "draw_cards",
            }
            creature = {
                "name": "Monastery Mentor",
                "cmc": 3,
                "mana_cost": "{2}{W}",
                "type_line": "Creature",
                "effect": "creature",
            }
            active.graveyard = [instant, sorcery, creature]

            battle.apply_effect_immediate(
                active,
                [],
                past,
                turn=5,
                rng=random.Random(197),
                effect_data_override=past_effect,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert instant["flashback_cost"] == "{1}"
        assert sorcery["flashback_cost"] == "{3}{R}{R}"
        assert "flashback_cost" not in creature
        assert any(card.get("name") == "Past in Flames" for card in active.graveyard)
        grant_event = next(
            data
            for event, data in events
            if event == "graveyard_flashback_granted"
        )
        assert grant_event["card"] == "Past in Flames"
        assert grant_event["granted_count"] == 2
        assert grant_event["rule_logical_key"] == "battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be"
        assert grant_event["rule_oracle_hash"] == "12f293d8d746fbc4e5ba80828919dec5"
        assert grant_event["rule_review_status"] == "active"
        assert grant_event["rule_execution_status"] == "auto"

        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active.library = [_card("Drawn Card", cmc=1)]
            active.mana_pool.add_generic(1)
            stack = battle.Stack()
            assert battle.cast_flashback_spell_from_graveyard(
                active,
                instant,
                [],
                [active],
                5,
                "precombat_main",
                stack,
                random.Random(198),
            ) is True
            flashback_event = next(
                data
                for event, data in events
                if event == "flashback_cast"
            )
            assert flashback_event["card"] == "Battle Cantrip"
            assert flashback_event["flashback_granted_by"] == "Past in Flames"
            assert flashback_event["flashback_granted_rule_key"] == "battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be"
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        battle.clear_until_eot(active)
        assert "flashback_cost" not in sorcery

    def test_flashback_targeted_removal_declares_target_before_resolution():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            target = {
                "name": "Kraum, Ludevic's Opus",
                "cmc": 5,
                "type_line": "Legendary Creature",
                "effect": "creature",
                "power": 4,
                "toughness": 4,
            }
            opponent.battlefield = [target]
            swords = {
                "name": "Swords to Plowshares",
                "cmc": 1,
                "mana_cost": "{W}",
                "type_line": "Instant",
                "flashback_cost": "{W}",
                "_flashback_granted_by": "Past in Flames",
                "_flashback_granted_rule_key": "battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be",
            }
            active.graveyard = [swords]
            active.mana_pool.add("white", 1)
            stack = battle.Stack()

            assert battle.cast_flashback_spell_from_graveyard(
                active,
                swords,
                [opponent],
                [active, opponent],
                6,
                "precombat_main",
                stack,
                random.Random(64270201),
            ) is True
            while not stack.empty():
                battle.priority_round(active, [active, opponent], stack, 6, random.Random(64270202), phase="precombat_main")
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert target not in opponent.battlefield
        assert target in opponent.exile
        announced = next(
            data
            for event, data in events
            if event == "cast_announced" and data.get("card") == "Swords to Plowshares"
        )
        flashback_cast = next(
            data
            for event, data in events
            if event == "flashback_cast" and data.get("card") == "Swords to Plowshares"
        )
        resolved = next(
            data
            for event, data in events
            if event == "spell_resolved" and data.get("card") == "Swords to Plowshares"
        )

        assert announced["role"] == "flashback"
        assert announced["source_zone"] == "graveyard"
        assert announced["target"] == "Kraum, Ludevic's Opus"
        assert announced["targets"][0]["target"] == "Kraum, Ludevic's Opus"
        assert flashback_cast["target"] == "Kraum, Ludevic's Opus"
        assert flashback_cast["targets"][0]["target_controller"] == "Opponent"
        assert resolved["role"] == "flashback"
        assert resolved["from_zone"] == "graveyard"
        assert resolved["target"] == "Kraum, Ludevic's Opus"
        assert resolved["targets"][0]["target_legal"] is True

    def test_path_to_exile_exiles_creature_with_pg037_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            path = {
                "name": "Path to Exile",
                "cmc": 1,
                "mana_cost": "{W}",
                "type_line": "Instant",
            }
            path_effect = battle.get_card_effect(path)
            assert path_effect["effect"] == "remove_creature"
            assert path_effect["target"] == "creature"
            assert path_effect["destination"] == "exile"
            assert path_effect["exile_target"] is True
            assert path_effect["target_controller_basic_land_tapped"] is True
            assert path_effect["basic_land_compensation_status"] == "annotation_only"
            assert path_effect["battle_model_scope"] == (
                "path_to_exile_creature_exile_basic_land_compensation_annotation_v1"
            )
            assert path_effect["_rule_logical_key"] == "battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd"
            assert path_effect["_rule_oracle_hash"] == "861c960a37be744e45f13200349e2532"

            active = player("Lorehold")
            opponent = player("Opponent")
            target = {
                "name": "Siege Rhino",
                "cmc": 4,
                "type_line": "Creature",
                "effect": "creature",
                "power": 4,
                "toughness": 5,
            }
            basic_land = {
                "name": "Plains",
                "cmc": 0,
                "type_line": "Basic Land - Plains",
                "effect": "land",
            }
            opponent.battlefield = [target]
            opponent.library = [basic_land]

            battle.apply_effect_immediate(
                active,
                [opponent],
                path,
                turn=6,
                rng=random.Random(198),
                effect_data_override=path_effect,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert target not in opponent.battlefield
        assert target in opponent.exile
        assert target not in opponent.graveyard
        assert basic_land in opponent.library
        assert basic_land not in opponent.battlefield
        removal_event = next(
            data
            for event, data in events
            if event == "removal_resolved" and data.get("card") == "Path to Exile"
        )
        assert removal_event["destination"] == "exile"
        assert removal_event["rule_logical_key"] == "battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd"
        assert removal_event["rule_oracle_hash"] == "861c960a37be744e45f13200349e2532"
        assert removal_event["target_controller_basic_land_tapped"] is True
        assert removal_event["basic_land_compensation_status"] == "annotation_only"

    def test_swords_to_plowshares_exiles_creature_and_gains_power_life_with_pg040_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            swords = {
                "name": "Swords to Plowshares",
                "cmc": 1,
                "mana_cost": "{W}",
                "type_line": "Instant",
            }
            swords_effect = battle.get_card_effect(swords)
            assert swords_effect["effect"] == "remove_creature"
            assert swords_effect["target"] == "creature"
            assert swords_effect["destination"] == "exile"
            assert swords_effect["exile_target"] is True
            assert swords_effect["target_controller_life_gain_equal_target_power"] is True
            assert swords_effect["life_gain_status"] == "dynamic_target_power_executor"
            assert swords_effect["battle_model_scope"] == (
                "swords_to_plowshares_creature_exile_life_equal_power_v1"
            )
            assert swords_effect["_rule_logical_key"] == "battle_rule_v1:379008f3f03f94258292123453e3041c"
            assert swords_effect["_rule_oracle_hash"] == "702f566e95dd477f5cf5a551e41e9df8"

            active = player("Lorehold")
            opponent = player("Opponent")
            opponent.life = 31
            target = {
                "name": "Siege Rhino",
                "cmc": 4,
                "type_line": "Creature",
                "effect": "creature",
                "power": 4,
                "toughness": 5,
            }
            opponent.battlefield = [target]

            battle.apply_effect_immediate(
                active,
                [opponent],
                swords,
                turn=6,
                rng=random.Random(199),
                effect_data_override=swords_effect,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert target not in opponent.battlefield
        assert target in opponent.exile
        assert target not in opponent.graveyard
        assert opponent.life == 35
        removal_event = next(
            data
            for event, data in events
            if event == "removal_resolved" and data.get("card") == "Swords to Plowshares"
        )
        assert removal_event["destination"] == "exile"
        assert removal_event["rule_logical_key"] == "battle_rule_v1:379008f3f03f94258292123453e3041c"
        assert removal_event["rule_oracle_hash"] == "702f566e95dd477f5cf5a551e41e9df8"
        assert removal_event["target_controller_life_gain_equal_target_power"] is True
        assert removal_event["life_gain_status"] == "dynamic_target_power_executor"
        assert removal_event["life_gain_requested"] == 4
        assert removal_event["life_gained"] == 4

    def test_pg095_winds_of_abandon_exiles_opponent_creature_with_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            winds = {
                "name": "Winds of Abandon",
                "cmc": 2,
                "mana_cost": "{1}{W}",
                "type_line": "Sorcery",
            }
            winds_effect = battle.get_card_effect(winds)
            assert winds_effect["effect"] == "remove_creature"
            assert winds_effect["target"] == "creature"
            assert winds_effect["target_restriction"] == "you_dont_control"
            assert winds_effect["target_controller"] == "opponent"
            assert winds_effect["sorcery"] is True
            assert winds_effect.get("instant") is None
            assert winds_effect["destination"] == "exile"
            assert winds_effect["exile_target"] is True
            assert winds_effect["target_controller_basic_land_tapped"] is True
            assert winds_effect["basic_land_compensation_status"] == "annotation_only"
            assert winds_effect["overload_cost"] == "{4}{W}{W}"
            assert winds_effect["overload_status"] == "annotation_only"
            assert winds_effect["overload_target_rewrite"] == "target_to_each"
            assert winds_effect["battle_model_scope"] == (
                "winds_of_abandon_opponent_creature_exile_basic_land_overload_annotation_v1"
            )
            assert winds_effect["_rule_logical_key"] == (
                "battle_rule_v1:4f844346b4b2b03ff68c2935fd399f9c"
            )
            assert winds_effect["_rule_oracle_hash"] == "05e38c4458b7b803d038978b46f11f72"

            active = player("Lorehold")
            own_creature = {
                "name": "Self Guard",
                "cmc": 2,
                "type_line": "Creature",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
            }
            active.battlefield = [own_creature]
            opponent = player("Opponent")
            target = {
                "name": "Siege Rhino",
                "cmc": 4,
                "type_line": "Creature",
                "effect": "creature",
                "power": 4,
                "toughness": 5,
            }
            basic_land = {
                "name": "Plains",
                "cmc": 0,
                "type_line": "Basic Land - Plains",
                "effect": "land",
            }
            opponent.battlefield = [target]
            opponent.library = [basic_land]

            battle.apply_effect_immediate(
                active,
                [opponent],
                winds,
                turn=7,
                rng=random.Random(205),
                effect_data_override=winds_effect,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert own_creature in active.battlefield
        assert target not in opponent.battlefield
        assert target in opponent.exile
        assert target not in opponent.graveyard
        assert basic_land in opponent.library
        assert basic_land not in opponent.battlefield
        removal_event = next(
            data
            for event, data in events
            if event == "removal_resolved" and data.get("card") == "Winds of Abandon"
        )
        assert removal_event["target_player"] == "Opponent"
        assert removal_event["target"] == "Siege Rhino"
        assert removal_event["destination"] == "exile"
        assert removal_event["rule_logical_key"] == (
            "battle_rule_v1:4f844346b4b2b03ff68c2935fd399f9c"
        )
        assert removal_event["rule_oracle_hash"] == "05e38c4458b7b803d038978b46f11f72"
        assert removal_event["target_controller_basic_land_tapped"] is True
        assert removal_event["basic_land_compensation_status"] == "annotation_only"

    def test_pg096_high_noon_is_passive_static_rule_not_creature_removal():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            high_noon = {
                "name": "High Noon",
                "cmc": 2,
                "mana_cost": "{1}{W}",
                "type_line": "Enchantment",
            }
            high_noon_effect = battle.get_card_effect(high_noon)
            assert high_noon_effect["effect"] == "passive"
            assert high_noon_effect["ability_kind"] == "static"
            assert high_noon_effect["static_spell_limit_per_turn"] == 1
            assert high_noon_effect["spell_limit_scope"] == "each_player"
            assert high_noon_effect["spell_limit_status"] == (
                "annotation_only_no_static_spell_limit_executor"
            )
            assert high_noon_effect["activated_damage_amount"] == 5
            assert high_noon_effect["activated_damage_target"] == "any"
            assert high_noon_effect["activated_damage_status"] == (
                "annotation_only_no_activation_executor"
            )
            assert high_noon_effect["sacrifice_self_activation_status"] == "annotation_only"
            assert high_noon_effect["battle_model_scope"] == (
                "high_noon_one_spell_per_turn_static_activated_five_damage_annotation_v1"
            )
            assert high_noon_effect["_rule_logical_key"] == (
                "battle_rule_v1:fca6c4be65cae378901514ff6c8417d1"
            )
            assert high_noon_effect["_rule_oracle_hash"] == "dfec584c3cfdf4eb34b8a1e1d4f7da3a"

            active = player("Lorehold")
            opponent = player("Opponent")
            opposing_creature = {
                "name": "Adversary",
                "cmc": 3,
                "type_line": "Creature",
                "effect": "creature",
                "power": 3,
                "toughness": 3,
            }
            opponent.battlefield = [opposing_creature]

            battle.apply_effect_immediate(
                active,
                [opponent],
                high_noon,
                turn=4,
                rng=random.Random(960),
                effect_data_override=high_noon_effect,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert opposing_creature in opponent.battlefield
        assert opposing_creature not in opponent.graveyard
        assert opposing_creature not in opponent.exile
        assert any(card.get("name") == "High Noon" for card in active.battlefield)
        assert not any(
            event == "removal_resolved" and data.get("card") == "High Noon"
            for event, data in events
        )

    def test_teferis_protection_phases_all_permanents_locks_life_and_exiles_self_with_pg041_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            teferi = {
                "name": "Teferi's Protection",
                "cmc": 3,
                "mana_cost": "{2}{W}",
                "type_line": "Instant",
            }
            teferi_effect = battle.get_card_effect(teferi)
            assert teferi_effect["effect"] == "phase_out"
            assert teferi_effect["life_total_cant_change"] is True
            assert teferi_effect["protection_from_everything"] is True
            assert teferi_effect["phase_out_all_permanents_you_control"] is True
            assert teferi_effect["phase_out_includes_lands"] is True
            assert teferi_effect["exiles_self"] is True
            assert teferi_effect["battle_model_scope"] == (
                "teferis_protection_life_lock_protection_all_permanents_phase_out_self_exile_v1"
            )
            assert teferi_effect["_rule_logical_key"] == "battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a"
            assert teferi_effect["_rule_oracle_hash"] == "bdc0faecf4420dc6162c7e72e98cc0eb"

            active = player("Lorehold")
            active.life = 8
            creature = {
                "name": "Monastery Mentor",
                "cmc": 3,
                "type_line": "Creature",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
            }
            artifact = {
                "name": "Sol Ring",
                "cmc": 1,
                "type_line": "Artifact",
                "effect": "ramp_permanent",
            }
            land = {
                "name": "Plateau",
                "cmc": 0,
                "type_line": "Land",
                "effect": "land",
            }
            active.battlefield = [creature, artifact, land]

            battle.apply_effect_immediate(
                active,
                [],
                teferi,
                turn=7,
                rng=random.Random(200),
                effect_data_override=teferi_effect,
            )
            battle.deal_damage(active, 20)
            battle.gain_life(active, 5)
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert active.battlefield == []
        assert creature in active.phased_out
        assert artifact in active.phased_out
        assert land in active.phased_out
        assert active.life_cant_change is True
        assert active.protection_from_everything is True
        assert active.life == 8
        assert teferi in active.exile
        assert teferi not in active.graveyard

        spell_event = next(
            data
            for event, data in events
            if event == "spell_resolved" and data.get("card") == "Teferi's Protection"
        )
        assert spell_event["destination"] == "exile"
        assert spell_event["zone_after"] == "exile"
        assert spell_event["rule_logical_key"] == "battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a"
        assert spell_event["rule_oracle_hash"] == "bdc0faecf4420dc6162c7e72e98cc0eb"
        phase_event = next(
            data
            for event, data in events
            if event == "phase_out_resolved" and data.get("card") == "Teferi's Protection"
        )
        assert phase_event["phased_count"] == 3
        assert phase_event["phase_out_includes_lands"] is True
        assert phase_event["life_total_cant_change"] is True
        assert phase_event["protection_from_everything"] is True
        assert phase_event["exiles_self"] is True
        assert phase_event["spell_destination"] == "exile"
        assert phase_event["rule_logical_key"] == "battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a"
        assert phase_event["rule_oracle_hash"] == "bdc0faecf4420dc6162c7e72e98cc0eb"

    def test_reverberate_copies_stack_spell_with_pg038_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            responder = player("Responder")
            reverberate = {
                "name": "Reverberate",
                "cmc": 2,
                "mana_cost": "{R}{R}",
                "type_line": "Instant",
            }
            responder.hand = [reverberate]
            responder.mana_pool.add("red", 2)
            active.library = [_card("Active Draw", cmc=1)]
            responder.library = [_card("Responder Draw", cmc=1)]
            target_spell = {
                "name": "Targeted Insight",
                "cmc": 3,
                "mana_cost": "{2}{U}",
                "type_line": "Sorcery",
            }
            target_effect = {"effect": "draw_cards", "count": 1}
            reverberate_effect = battle.get_card_effect(reverberate)
            assert reverberate_effect["effect"] == "copy_spell"
            assert reverberate_effect["target"] == "instant_or_sorcery_on_stack"
            assert reverberate_effect["copy_is_not_cast"] is True
            assert reverberate_effect["choose_new_targets_status"] == "annotation_only"
            assert reverberate_effect["battle_model_scope"] == (
                "reverberate_copy_stack_instant_or_sorcery_new_targets_annotation_v1"
            )
            assert reverberate_effect["_rule_logical_key"] == "battle_rule_v1:0269136edf067f696c8576740b720e14"
            assert reverberate_effect["_rule_oracle_hash"] == "cbae05dee4261e3ed5412fd5f3591c17"

            stack = battle.Stack()
            stack.push(target_spell, active, target_effect)
            assert battle.priority_round(
                active,
                [active, responder],
                stack,
                7,
                random.Random(199),
                phase="precombat_main",
            ) is True
            assert stack.items[-1].card.get("is_copy") is True
            assert stack.items[-1].controller is responder
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert reverberate not in responder.hand
        assert reverberate in responder.graveyard
        cast_event = next(
            data
            for event, data in events
            if event == "spell_cast" and data.get("card") == "Reverberate"
        )
        copied_event = next(
            data
            for event, data in events
            if event == "spell_copied" and data.get("card") == "Reverberate"
        )
        assert cast_event["response_to"] == "Targeted Insight"
        assert cast_event["rule_logical_key"] == "battle_rule_v1:0269136edf067f696c8576740b720e14"
        assert copied_event["copied_spell"] == "Targeted Insight"
        assert copied_event["copy_is_cast"] is False
        assert copied_event["rule_logical_key"] == "battle_rule_v1:0269136edf067f696c8576740b720e14"
        assert copied_event["rule_oracle_hash"] == "cbae05dee4261e3ed5412fd5f3591c17"
        assert copied_event["choose_new_targets_status"] == "annotation_only"

        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            assert battle.priority_round(
                active,
                [active, responder],
                stack,
                7,
                random.Random(200),
                phase="precombat_main",
            ) is False
            assert any(card.get("name") == "Responder Draw" for card in responder.hand)
            assert any(
                event == "spell_copy_ceased_to_exist"
                and data.get("card") == "Targeted Insight"
                for event, data in events
            )
            copy_resolved = next(
                data
                for event, data in events
                if event == "spell_resolved"
                and data.get("card") == "Targeted Insight"
                and data.get("destination") == "ceased_to_exist"
            )
            assert copy_resolved["phase"] == "precombat_main"
            assert copy_resolved["priority_window"] == "stack_resolution"
            assert copy_resolved["resolved_from_stack"] is True
            assert copy_resolved["source_zone"] == "stack_copy"
            assert copy_resolved["from_zone"] == "stack"
            assert copy_resolved["to_zone"] == "ceased_to_exist"
            assert copy_resolved["cast_pipeline"] == "spell_copy"
            assert copy_resolved["locked_cost"]["copied_spell"] is True
            assert battle.priority_round(
                active,
                [active, responder],
                stack,
                7,
                random.Random(201),
                phase="precombat_main",
            ) is False
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert any(card.get("name") == "Active Draw" for card in active.hand)
        assert any(card.get("name") == "Targeted Insight" for card in active.graveyard)

    def test_reiterate_copies_stack_spell_with_pg068_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            responder = player("Responder")
            reiterate = {
                "name": "Reiterate",
                "cmc": 3,
                "mana_cost": "{1}{R}{R}",
                "type_line": "Instant",
            }
            responder.hand = [reiterate]
            responder.mana_pool.add("red", 2)
            responder.mana_pool.add_generic(1)
            target_spell = {
                "name": "Targeted Insight",
                "cmc": 3,
                "mana_cost": "{2}{U}",
                "type_line": "Sorcery",
            }
            target_effect = {"effect": "draw_cards", "count": 1}
            reiterate_effect = battle.get_card_effect(reiterate)
            assert reiterate_effect["effect"] == "copy_spell"
            assert reiterate_effect["target"] == "instant_or_sorcery_on_stack"
            assert reiterate_effect["copy_is_not_cast"] is True
            assert reiterate_effect["buyback_status"] == "annotation_only"
            assert reiterate_effect["battle_model_scope"] == (
                "copy_stack_instant_or_sorcery_buyback_annotation_v1"
            )
            assert reiterate_effect["_rule_logical_key"] == "battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405"
            assert reiterate_effect["_rule_oracle_hash"] == "996fb5f02f16605ff7f1c899f2c50f60"

            stack = battle.Stack()
            stack.push(target_spell, active, target_effect)
            assert battle.priority_round(
                active,
                [active, responder],
                stack,
                7,
                random.Random(202),
                phase="precombat_main",
            ) is True
            assert stack.items[-1].card.get("is_copy") is True
            assert stack.items[-1].controller is responder
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert reiterate not in responder.hand
        assert reiterate in responder.graveyard
        copied_event = next(
            data
            for event, data in events
            if event == "spell_copied" and data.get("card") == "Reiterate"
        )
        assert copied_event["copied_spell"] == "Targeted Insight"
        assert copied_event["copy_is_cast"] is False
        assert copied_event["rule_logical_key"] == "battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405"
        assert copied_event["rule_oracle_hash"] == "996fb5f02f16605ff7f1c899f2c50f60"
        assert copied_event["choose_new_targets_status"] == "annotation_only"

    def test_dualcaster_mage_etb_copies_stack_spell_with_pg068_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            responder = player("Responder")
            dualcaster = {
                "name": "Dualcaster Mage",
                "cmc": 3,
                "mana_cost": "{1}{R}{R}",
                "type_line": "Creature — Human Wizard",
                "keywords": ["Flash"],
            }
            responder.hand = [dualcaster]
            responder.mana_pool.add("red", 2)
            responder.mana_pool.add_generic(1)
            target_spell = {
                "name": "Targeted Insight",
                "cmc": 3,
                "mana_cost": "{2}{U}",
                "type_line": "Sorcery",
            }
            target_effect = {"effect": "draw_cards", "count": 1}
            dualcaster_effect = battle.get_card_effect(dualcaster)
            assert dualcaster_effect["effect"] == "copy_spell"
            assert dualcaster_effect["etb_copy_spell"] is True
            assert dualcaster_effect["is_creature_permanent"] is True
            assert dualcaster_effect["target"] == "instant_or_sorcery_on_stack"
            assert dualcaster_effect["copy_is_not_cast"] is True
            assert dualcaster_effect["battle_model_scope"] == (
                "creature_etb_copy_stack_instant_or_sorcery_v1"
            )
            assert dualcaster_effect["_rule_logical_key"] == "battle_rule_v1:e176019b87d68d22e2388e08a4efbf55"
            assert dualcaster_effect["_rule_oracle_hash"] == "e26f613394b72e9724d299512983218a"

            stack = battle.Stack()
            stack.push(target_spell, active, target_effect)
            assert battle.priority_round(
                active,
                [active, responder],
                stack,
                7,
                random.Random(203),
                phase="precombat_main",
            ) is True
            assert stack.items[-1].card.get("name") == "Dualcaster Mage"
            assert battle.priority_round(
                active,
                [active, responder],
                stack,
                7,
                random.Random(204),
                phase="precombat_main",
            ) is False
            assert stack.items[-1].card.get("is_copy") is True
            assert stack.items[-1].controller is responder
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert dualcaster not in responder.hand
        assert any(card.get("name") == "Dualcaster Mage" for card in responder.battlefield)
        assert not any(card.get("name") == "Dualcaster Mage" for card in responder.graveyard)
        copied_event = next(
            data
            for event, data in events
            if event == "spell_copied" and data.get("card") == "Dualcaster Mage"
        )
        assert copied_event["copied_spell"] == "Targeted Insight"
        assert copied_event["copy_is_cast"] is False
        assert copied_event["trigger"] == "enters_battlefield"
        assert copied_event["rule_logical_key"] == "battle_rule_v1:e176019b87d68d22e2388e08a4efbf55"
        assert copied_event["rule_oracle_hash"] == "e26f613394b72e9724d299512983218a"

    def test_deflecting_swat_redirects_targeted_removal_for_free_with_commander():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            swat = {
                "name": "Deflecting Swat",
                "cmc": 3,
                "type_line": "Instant",
                "mana_cost": "{2}{R}",
            }
            active = player("Lorehold", [swat])
            active.hand = [swat]
            active.is_human = True
            commander = {
                "name": "Lorehold, the Historian",
                "effect": "creature",
                "type_line": "Legendary Creature",
                "power": 3,
                "toughness": 3,
                "is_commander": True,
            }
            protected = {
                "name": "Protected Creature",
                "effect": "creature",
                "type_line": "Creature",
                "power": 2,
                "toughness": 2,
            }
            active.battlefield = [commander, protected]

            caster = player("Caster")
            opponent_threat = {
                "name": "Opponent Threat",
                "effect": "creature",
                "type_line": "Creature",
                "power": 6,
                "toughness": 6,
            }
            caster.battlefield = [opponent_threat]
            removal = {"name": "Targeted Removal", "cmc": 2, "type_line": "Instant"}
            removal_effect = {
                "effect": "remove_creature",
                "instant": True,
                "declared_targets": [
                    {
                        "target": protected,
                        "controller": active,
                        "target_type": "creature",
                    }
                ],
            }
            stack = battle.Stack()
            stack.push(removal, caster, removal_effect)

            assert battle.priority_round(
                caster,
                [caster, active],
                stack,
                3,
                random.Random(194),
                phase="combat",
            )
            while not stack.empty():
                battle.priority_round(
                    caster,
                    [caster, active],
                    stack,
                    3,
                    random.Random(195),
                    phase="combat",
                )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert swat not in active.hand
        assert protected in active.battlefield
        assert opponent_threat not in caster.battlefield
        spell_event = next(
            data
            for event, data in events
            if event == "spell_cast" and data.get("card") == "Deflecting Swat"
        )
        assert spell_event["alternative_cost"] == "{0}"
        assert spell_event["alternative_cost_kind"] == "control_commander"
        assert spell_event["locked_cost"]["generic"] == 0
        redirect_event = next(
            data
            for event, data in events
            if event == "redirect_removal_resolved"
        )
        assert redirect_event["target_change_applied"] is True
        assert redirect_event["old_target"] == "Protected Creature"
        assert redirect_event["new_target"] == "Opponent Threat"
        assert redirect_event["rule_logical_key"] == "battle_rule_v1:bac48343654a53205d790a8268bd2631"

    def test_flawless_maneuver_protects_creatures_for_free_with_commander():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            maneuver = {
                "name": "Flawless Maneuver",
                "cmc": 3,
                "type_line": "Instant",
                "mana_cost": "{2}{W}",
            }
            active = player("Lorehold", [maneuver])
            active.hand = [maneuver]
            active.is_human = True
            commander = {
                "name": "Lorehold, the Historian",
                "effect": "creature",
                "type_line": "Legendary Creature",
                "power": 3,
                "toughness": 3,
                "is_commander": True,
            }
            protected = {
                "name": "Protected Creature",
                "effect": "creature",
                "type_line": "Creature",
                "power": 2,
                "toughness": 2,
            }
            active.battlefield = [commander, protected]

            caster = player("Caster")
            doomed = {
                "name": "Doomed Opponent Creature",
                "effect": "creature",
                "type_line": "Creature",
                "power": 6,
                "toughness": 6,
            }
            caster.battlefield = [doomed]
            wipe = {"name": "Blasphemous Act", "cmc": 9, "type_line": "Sorcery"}
            stack = battle.Stack()
            stack.push(wipe, caster, battle.get_card_effect(wipe))

            assert battle.priority_round(
                caster,
                [caster, active],
                stack,
                3,
                random.Random(196),
                phase="main",
            )
            while not stack.empty():
                battle.priority_round(
                    caster,
                    [caster, active],
                    stack,
                    3,
                    random.Random(197),
                    phase="main",
                )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert maneuver not in active.hand
        assert commander in active.battlefield
        assert protected in active.battlefield
        assert doomed not in caster.battlefield
        spell_event = next(
            data
            for event, data in events
            if event == "spell_cast" and data.get("card") == "Flawless Maneuver"
        )
        assert spell_event["alternative_cost"] == "{0}"
        assert spell_event["alternative_cost_kind"] == "control_commander"
        assert spell_event["locked_cost"]["generic"] == 0
        assert spell_event["rule_logical_key"] == "battle_rule_v1:73622071c1ad89267708f914a0729bf2"
        protection_event = next(
            data
            for event, data in events
            if event == "protection_resolved" and data.get("card") == "Flawless Maneuver"
        )
        assert protection_event["target_scope"] == "creatures_you_control"
        assert protection_event["affected_count"] == 2
        assert protection_event["rule_logical_key"] == "battle_rule_v1:73622071c1ad89267708f914a0729bf2"

    def test_landfall_does_not_enqueue_without_real_landfall_source():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            land = {"name": "Sunbillow Verge", "effect": "land", "type_line": "Land"}
            active.battlefield = [land]
            stack = battle.Stack()

            triggered = battle.trigger_landfall(
                active,
                land,
                turn=2,
                source_event="land_played",
                stack=stack,
                active_player=active,
                all_players=[active],
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert triggered is False
        assert stack.empty()
        assert not any(event == "trigger_put_on_stack" for event, _ in events)

    def test_landfall_enqueue_with_real_landfall_source():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            source = {
                "name": "Landfall Source",
                "effect": "token_maker",
                "landfall_token_maker": True,
                "token_power": 1,
                "token_toughness": 1,
            }
            land = {"name": "Sunbillow Verge", "effect": "land", "type_line": "Land"}
            active.battlefield = [source, land]
            stack = battle.Stack()

            triggered = battle.trigger_landfall(
                active,
                land,
                turn=2,
                source_event="land_played",
                stack=stack,
                active_player=active,
                all_players=[active],
            )
            pushed = battle.flush_triggers_in_apnap(active, [active], stack)
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert triggered is True
        assert pushed == 1
        assert not stack.empty()
        assert any(
            event == "trigger_put_on_stack"
            and data.get("card") == "Landfall Source"
            and data.get("trigger") == "landfall"
            and data.get("trigger_land") == "Sunbillow Verge"
            for event, data in events
        )

    def test_reforge_resolution_draws_seven_when_count_missing():
        active = player("Active")
        opponent = player("Opponent")
        active.hand = [
            {"name": "Big Spell", "cmc": 8, "type_line": "Sorcery"},
            {"name": "Cheap Spell", "cmc": 1, "type_line": "Instant"},
        ]
        opponent.hand = [{"name": f"Opp Card {index}", "cmc": 1, "type_line": "Instant"} for index in range(3)]
        active.library = [_card(f"Draw {index}", cmc=1) for index in range(8)]
        opponent.library = [_card(f"Opponent Draw {index}", cmc=1) for index in range(8)]

        battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Reforge the Soul", "cmc": 5, "type_line": "Sorcery"},
            turn=3,
            rng=random.Random(8018),
        )

        assert len(active.hand) == 7
        assert len(opponent.hand) == 7

    def test_boros_charm_protects_creatures_until_cleanup():
        active = player("Lorehold")
        active.is_human = True
        active.hand = [{"name": "Boros Charm", "cmc": 2, "type_line": "Instant"}]
        creature = {
            "name": "Protected Creature",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
            "summoning_sick": False,
        }
        active.battlefield = [creature, "land", "land"]
        active.refresh_mana_sources(turn=2)
        caster = player("Caster")
        wipe = {"name": "Blasphemous Act", "cmc": 9, "type_line": "Sorcery"}
        stack = battle.Stack()
        stack.push(wipe, caster, battle.get_card_effect(wipe))

        assert battle.priority_round(caster, [caster, active], stack, 2, random.Random(20))
        while not stack.empty():
            battle.priority_round(caster, [caster, active], stack, 2, random.Random(20))

        assert creature in active.battlefield
        assert creature["indestructible"] is True
        battle.clear_until_eot(active)
        assert "indestructible" not in creature

    def test_boros_charm_grants_indestructible_to_all_permanents_until_cleanup():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            creature = {
                "name": "Protected Creature",
                "effect": "creature",
                "type_line": "Creature",
                "power": 3,
                "toughness": 3,
            }
            artifact = {
                "name": "Protected Artifact",
                "effect": "ramp_permanent",
                "type_line": "Artifact",
                "cmc": 2,
            }
            enchantment = {
                "name": "Protected Enchantment",
                "effect": "draw_engine",
                "type_line": "Enchantment",
                "cmc": 3,
            }
            active.battlefield = [creature, artifact, enchantment, "land"]

            battle.apply_effect_immediate(
                active,
                [],
                {"name": "Boros Charm", "cmc": 2, "type_line": "Instant"},
                turn=3,
                rng=random.Random(30),
                effect_data_override={
                    "effect": "modal_boros_charm",
                    "instant": True,
                    "_rule_logical_key": "battle_rule_v1:boros-charm-test",
                    "_rule_oracle_hash": "boros-charm-hash",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        for permanent in (creature, artifact, enchantment):
            assert permanent["indestructible"] is True
        event = next(data for event, data in events if event == "modal_boros_charm_resolved")
        assert event["selected_mode"] == "permanents_you_control_gain_indestructible_until_eot"
        assert event["affected_count"] == 3
        assert event["rule_logical_key"] == "battle_rule_v1:boros-charm-test"
        battle.clear_until_eot(active)
        for permanent in (creature, artifact, enchantment):
            assert "indestructible" not in permanent

    def test_boros_charm_double_strike_targets_one_creature_until_cleanup():
        active = player("Lorehold")
        small = {
            "name": "Small Creature",
            "effect": "creature",
            "type_line": "Creature",
            "power": 2,
            "toughness": 2,
        }
        large = {
            "name": "Large Creature",
            "effect": "creature",
            "type_line": "Creature",
            "power": 5,
            "toughness": 5,
        }
        active.battlefield = [small, large]

        battle.apply_effect_immediate(
            active,
            [],
            {
                "name": "Boros Charm",
                "cmc": 2,
                "type_line": "Instant",
                "preferred_mode": "double_strike",
            },
            turn=3,
            rng=random.Random(31),
            effect_data_override={
                "effect": "modal_boros_charm",
                "instant": True,
            },
        )

        double_strike_creatures = [
            creature
            for creature in (small, large)
            if creature.get("double_strike")
        ]
        assert len(double_strike_creatures) == 1
        assert double_strike_creatures[0]["name"] == "Large Creature"
        battle.clear_until_eot(active)
        assert "double_strike" not in small
        assert "double_strike" not in large

    def test_dawns_truce_oracle_normalizes_to_gift_hexproof_indestructible():
        effect_data = battle.normalize_effect_by_oracle(
            {
                "name": "Dawn's Truce",
                "cmc": 2,
                "type_line": "Instant",
                "oracle_text": (
                    "Gift a card (You may promise an opponent a gift as you cast this spell. "
                    "If you do, they draw a card before its other effects.)\n"
                    "You and permanents you control gain hexproof until end of turn. "
                    "If the gift was promised, permanents you control also gain "
                    "indestructible until end of turn."
                ),
            },
            {"effect": "indestructible"},
        )

        assert effect_data["effect"] == "gift_hexproof_indestructible"
        assert effect_data["gift_default_promised"] is True
        assert effect_data["gift_card_draw"] is True
        assert effect_data["grants_player_hexproof"] is True
        assert effect_data["grants_permanents_hexproof"] is True
        assert effect_data["gift_grants_permanents_indestructible"] is True
        assert (
            effect_data["battle_model_scope"]
            == "gift_card_you_and_permanents_hexproof_gifted_indestructible_v1"
        )

    def test_dawns_truce_gifts_card_and_grants_hexproof_indestructible_until_cleanup():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            opponent.library = [
                {"name": "Gift Draw", "type_line": "Sorcery", "effect": "draw_cards"}
            ]
            creature = {
                "name": "Protected Creature",
                "effect": "creature",
                "type_line": "Creature",
                "power": 3,
                "toughness": 3,
            }
            artifact = {
                "name": "Protected Artifact",
                "effect": "ramp_permanent",
                "type_line": "Artifact",
                "cmc": 2,
            }
            land = {
                "name": "Protected Land",
                "effect": "land",
                "type_line": "Land",
            }
            active.battlefield = [creature, artifact, land]

            battle.apply_effect_immediate(
                active,
                [opponent],
                {"name": "Dawn's Truce", "cmc": 2, "type_line": "Instant"},
                turn=4,
                rng=random.Random(617),
                effect_data_override={
                    "effect": "gift_hexproof_indestructible",
                    "instant": True,
                    "gift": "card",
                    "gift_default_promised": True,
                    "gift_card_draw": True,
                    "target_scope": "you_and_permanents_you_control",
                    "battle_model_scope": (
                        "gift_card_you_and_permanents_hexproof_gifted_indestructible_v1"
                    ),
                    "_rule_logical_key": "battle_rule_v1:dawns-truce-test",
                    "_rule_oracle_hash": "dawns-truce-hash",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert opponent.hand[0]["name"] == "Gift Draw"
        assert active.hexproof is True
        for permanent in (creature, artifact, land):
            assert permanent["hexproof"] is True
            assert permanent["indestructible"] is True
        event = next(data for event, data in events if event == "protection_resolved")
        assert event["card"] == "Dawn's Truce"
        assert event["grants"] == ["hexproof", "indestructible"]
        assert event["gift_promised"] is True
        assert event["gift_recipient"] == "Opponent"
        assert event["gift_cards_drawn"] == 1
        assert event["player_hexproof"] is True
        assert event["affected_count"] == 3
        assert event["indestructible_affected_count"] == 3
        assert event["rule_logical_key"] == "battle_rule_v1:dawns-truce-test"

        battle.clear_until_eot(active)
        assert active.hexproof is False
        for permanent in (creature, artifact, land):
            assert "hexproof" not in permanent
            assert "indestructible" not in permanent

    def test_everything_comes_to_dust_oracle_normalizes_to_convoke_exile_wipe():
        effect_data = battle.normalize_effect_by_oracle(
            {
                "name": "Everything Comes to Dust",
                "type_line": "Sorcery",
                "oracle_text": (
                    "Convoke (Your creatures can help cast this spell. Each creature "
                    "you tap while casting this spell pays for {1} or one mana of "
                    "that creature's color.)\n"
                    "Exile all creatures except those that share a creature type with "
                    "a creature that convoked this spell, all artifacts, and all "
                    "enchantments."
                ),
            },
            {"effect": "board_wipe", "cmc": 10.0},
        )

        assert effect_data["effect"] == "exile_artifact_enchantment_creature_convoke_wipe"
        assert effect_data["destination"] == "exile"
        assert effect_data["exile_creatures_except_convoked_types"] is True
        assert effect_data["exile_artifacts"] is True
        assert effect_data["exile_enchantments"] is True
        assert (
            effect_data["battle_model_scope"]
            == "exile_creatures_except_convoked_types_artifacts_enchantments_v1"
        )

    def test_everything_comes_to_dust_exiles_artifacts_enchantments_and_nonshared_creatures():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.battlefield = [
                {
                    "name": "Human Convoker",
                    "effect": "creature",
                    "type_line": "Creature — Human Wizard",
                    "power": 1,
                    "toughness": 1,
                },
                {
                    "name": "Own Spirit",
                    "effect": "creature",
                    "type_line": "Creature — Spirit",
                    "power": 2,
                    "toughness": 2,
                },
                {
                    "name": "Own Human Artifact",
                    "effect": "creature",
                    "type_line": "Artifact Creature — Human",
                    "power": 2,
                    "toughness": 2,
                },
                {
                    "name": "Own Enchantment",
                    "effect": "draw_engine",
                    "type_line": "Enchantment",
                },
            ]
            opponent.battlefield = [
                {
                    "name": "Opponent Human",
                    "effect": "creature",
                    "type_line": "Creature — Human Soldier",
                    "power": 2,
                    "toughness": 2,
                },
                {
                    "name": "Opponent Elf",
                    "effect": "creature",
                    "type_line": "Creature — Elf",
                    "power": 3,
                    "toughness": 3,
                },
                {
                    "name": "Opponent Rock",
                    "effect": "ramp_permanent",
                    "type_line": "Artifact",
                },
                {
                    "name": "Opponent Aura",
                    "effect": "draw_engine",
                    "type_line": "Enchantment",
                },
            ]
            effect_data = {
                "effect": "exile_artifact_enchantment_creature_convoke_wipe",
                "destination": "exile",
                "convoked_creature_types": ["Human"],
                "battle_model_scope": (
                    "exile_creatures_except_convoked_types_artifacts_enchantments_v1"
                ),
                "_rule_logical_key": "battle_rule_v1:everything-dust-test",
                "_rule_source": "curated",
                "_rule_review_status": "verified",
            }

            battle.apply_effect_immediate(
                active,
                [opponent],
                {
                    "name": "Everything Comes to Dust",
                    "cmc": 10,
                    "type_line": "Sorcery",
                },
                turn=7,
                rng=random.Random(230623),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        active_names = {card.get("name") for card in active.battlefield}
        opponent_names = {card.get("name") for card in opponent.battlefield}
        active_exile_names = {card.get("name") for card in active.exile}
        opponent_exile_names = {card.get("name") for card in opponent.exile}

        assert "Human Convoker" in active_names
        assert "Opponent Human" in opponent_names
        assert "Own Spirit" in active_exile_names
        assert "Own Human Artifact" in active_exile_names
        assert "Own Enchantment" in active_exile_names
        assert "Opponent Elf" in opponent_exile_names
        assert "Opponent Rock" in opponent_exile_names
        assert "Opponent Aura" in opponent_exile_names

        wipe_event = next(data for event, data in events if event == "board_wipe_resolved")
        assert wipe_event["card"] == "Everything Comes to Dust"
        assert wipe_event["rule_logical_key"] == "battle_rule_v1:everything-dust-test"
        assert wipe_event["destination"] == "exile"
        assert wipe_event["destroyed"] == 0
        assert wipe_event["exiled"] == 6
        assert wipe_event["protected"] == 2
        assert wipe_event["convoked_creature_types"] == ["human"]
        assert wipe_event["convoked_type_source"] == "explicit"
        assert {entry["name"] for entry in wipe_event["preserved_by_convoke"]} == {
            "Human Convoker",
            "Opponent Human",
        }

    def test_fated_clash_oracle_normalizes_to_protect_then_destroy_wipe():
        effect_data = battle.normalize_effect_by_oracle(
            {
                "name": "Fated Clash",
                "type_line": "Sorcery",
                "oracle_text": (
                    "You may cast this spell as though it had flash if a creature "
                    "is attacking and a creature is blocking.\n"
                    "Target creature you control and target creature an opponent "
                    "controls each gain indestructible until end of turn. Then "
                    "destroy all creatures."
                ),
            },
            {"effect": "board_wipe", "cmc": 5.0},
        )

        assert effect_data["effect"] == "fated_clash_protect_then_destroy"
        assert effect_data["sorcery"] is True
        assert effect_data["conditional_flash_if_attacking_and_blocking"] is True
        assert effect_data["target_scope"] == "own_creature_and_opponent_creature"
        assert effect_data["grants_targets_indestructible_until_eot"] is True
        assert effect_data["then_destroy_all_creatures"] is True
        assert (
            effect_data["battle_model_scope"]
            == "own_and_opponent_creature_indestructible_then_destroy_all_creatures_v1"
        )

    def test_fated_clash_protects_best_own_and_weakest_opponent_creature_then_wipes():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            own_best = {
                "name": "Own Best",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 5,
                "power": 5,
                "toughness": 5,
            }
            own_small = {
                "name": "Own Small",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 1,
                "power": 1,
                "toughness": 1,
            }
            opponent_small = {
                "name": "Opponent Small",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 1,
                "power": 1,
                "toughness": 1,
            }
            opponent_bomb = {
                "name": "Opponent Bomb",
                "effect": "finisher",
                "type_line": "Creature",
                "cmc": 8,
                "power": 8,
                "toughness": 8,
            }
            active.battlefield = [own_best, own_small]
            opponent.battlefield = [opponent_small, opponent_bomb]

            battle.apply_effect_immediate(
                active,
                [opponent],
                {
                    "name": "Fated Clash",
                    "cmc": 5,
                    "type_line": "Sorcery",
                },
                turn=8,
                rng=random.Random(10701),
                effect_data_override={
                    "effect": "fated_clash_protect_then_destroy",
                    "conditional_flash_if_attacking_and_blocking": True,
                    "battle_model_scope": (
                        "own_and_opponent_creature_indestructible_then_destroy_all_creatures_v1"
                    ),
                    "_rule_logical_key": "battle_rule_v1:fated-clash-test",
                    "_rule_source": "curated",
                    "_rule_review_status": "verified",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert [card.get("name") for card in active.battlefield] == ["Own Best"]
        assert [card.get("name") for card in opponent.battlefield] == ["Opponent Small"]
        assert {card.get("name") for card in active.graveyard} == {"Own Small", "Fated Clash"}
        assert [card.get("name") for card in opponent.graveyard] == ["Opponent Bomb"]
        assert own_best["indestructible"] is True
        assert opponent_small["indestructible"] is True

        spell_event = next(
            data
            for event, data in events
            if event == "spell_resolved" and data.get("card") == "Fated Clash"
        )
        assert {target["target"] for target in spell_event["targets"]} == {
            "Own Best",
            "Opponent Small",
        }
        wipe_event = next(data for event, data in events if event == "board_wipe_resolved")
        assert wipe_event["card"] == "Fated Clash"
        assert wipe_event["rule_logical_key"] == "battle_rule_v1:fated-clash-test"
        assert wipe_event["destroyed"] == 2
        assert wipe_event["protected"] == 2
        assert wipe_event["conditional_flash_if_attacking_and_blocking"] is True
        assert {entry["target"] for entry in wipe_event["protected_targets"]} == {
            "Own Best",
            "Opponent Small",
        }
        assert {entry["name"] for entry in wipe_event["destroyed_cards"]} == {
            "Own Small",
            "Opponent Bomb",
        }
        battle.clear_until_eot(active)
        battle.clear_until_eot(opponent)
        assert "indestructible" not in own_best
        assert "indestructible" not in opponent_small

    def test_promise_of_loyalty_oracle_normalizes_to_vow_sacrifice_wipe():
        effect_data = battle.normalize_effect_by_oracle(
            {
                "name": "Promise of Loyalty",
                "type_line": "Sorcery",
                "oracle_text": (
                    "Each player puts a vow counter on a creature they control "
                    "and sacrifices the rest. Each of those creatures can't attack "
                    "you or planeswalkers you control for as long as it has a vow "
                    "counter on it."
                ),
            },
            {"effect": "draw_cards", "cmc": 5.0},
        )

        assert effect_data["effect"] == "vow_counter_each_player_sacrifice_rest"
        assert effect_data["counter_type"] == "vow"
        assert effect_data["choice_scope"] == "each_player_one_creature_they_control"
        assert effect_data["sacrifice_scope"] == "other_creatures"
        assert (
            effect_data["battle_model_scope"]
            == "each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1"
        )

    def test_promise_of_loyalty_vows_one_creature_each_player_and_blocks_attack_back():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            own_best = {
                "name": "Own Best",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 5,
                "power": 5,
                "toughness": 5,
            }
            own_small = {
                "name": "Own Small",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 1,
                "power": 1,
                "toughness": 1,
            }
            opponent_best = {
                "name": "Opponent Best",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 4,
                "power": 4,
                "toughness": 4,
            }
            opponent_small = {
                "name": "Opponent Small",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 1,
                "power": 1,
                "toughness": 1,
            }
            active.battlefield = [own_best, own_small]
            opponent.battlefield = [opponent_best, opponent_small]

            battle.apply_effect_immediate(
                active,
                [opponent],
                {
                    "name": "Promise of Loyalty",
                    "cmc": 5,
                    "type_line": "Sorcery",
                },
                turn=8,
                rng=random.Random(11101),
                effect_data_override={
                    "effect": "vow_counter_each_player_sacrifice_rest",
                    "battle_model_scope": (
                        "each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1"
                    ),
                    "_rule_logical_key": "battle_rule_v1:promise-loyalty-test",
                    "_rule_source": "curated",
                    "_rule_review_status": "verified",
                },
            )

            declared_attack = battle.declare_attackers_step(
                opponent,
                [active],
                [active, opponent],
                turn=9,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert [card.get("name") for card in active.battlefield] == ["Own Best"]
        assert [card.get("name") for card in opponent.battlefield] == ["Opponent Best"]
        assert {card.get("name") for card in active.graveyard} == {"Own Small", "Promise of Loyalty"}
        assert [card.get("name") for card in opponent.graveyard] == ["Opponent Small"]
        assert own_best["vow_counters"] == 1
        assert opponent_best["vow_counters"] == 1
        assert "Lorehold" in opponent_best["vow_cannot_attack_players"]
        assert declared_attack is None
        assert opponent_best.get("tapped") is not True
        wipe_event = next(data for event, data in events if event == "board_wipe_resolved")
        assert wipe_event["card"] == "Promise of Loyalty"
        assert wipe_event["rule_logical_key"] == "battle_rule_v1:promise-loyalty-test"
        assert wipe_event["destroyed"] == 2
        assert wipe_event["sacrificed"] == 2
        assert wipe_event["vows_placed"] == 2
        assert {entry["name"] for entry in wipe_event["vow_countered_creatures"]} == {
            "Own Best",
            "Opponent Best",
        }

    def test_starfall_invocation_oracle_normalizes_to_gift_destroy_return_wipe():
        effect_data = battle.normalize_effect_by_oracle(
            {
                "name": "Starfall Invocation",
                "type_line": "Sorcery",
                "oracle_text": (
                    "Gift a card (You may promise an opponent a gift as you cast "
                    "this spell. If you do, they draw a card before its other "
                    "effects.)\nDestroy all creatures. If the gift was promised, "
                    "return a creature card put into your graveyard this way to "
                    "the battlefield under your control."
                ),
            },
            {"effect": "board_wipe", "cmc": 5.0},
        )

        assert effect_data["effect"] == "gift_destroy_all_creatures_return_own_destroyed_creature"
        assert effect_data["gift_default_promised"] is True
        assert effect_data["gift_card_draw"] is True
        assert effect_data["destroy_scope"] == "all_creatures"
        assert effect_data["return_scope"] == "own_creature_destroyed_this_way"
        assert (
            effect_data["battle_model_scope"]
            == "gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1"
        )

    def test_starfall_invocation_destroys_all_creatures_gifts_and_returns_best_own():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            own_best = {
                "name": "Own Best",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 6,
                "power": 6,
                "toughness": 6,
            }
            own_small = {
                "name": "Own Small",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 1,
                "power": 1,
                "toughness": 1,
            }
            opponent_creature = {
                "name": "Opponent Creature",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 4,
                "power": 4,
                "toughness": 4,
            }
            active.battlefield = [own_best, own_small]
            opponent.battlefield = [opponent_creature]
            opponent.library = [{"name": "Gift Draw", "cmc": 2, "type_line": "Instant"}]

            battle.apply_effect_immediate(
                active,
                [opponent],
                {
                    "name": "Starfall Invocation",
                    "cmc": 5,
                    "type_line": "Sorcery",
                },
                turn=8,
                rng=random.Random(11102),
                effect_data_override={
                    "effect": "gift_destroy_all_creatures_return_own_destroyed_creature",
                    "gift_default_promised": True,
                    "gift_card_draw": True,
                    "battle_model_scope": (
                        "gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1"
                    ),
                    "_rule_logical_key": "battle_rule_v1:starfall-test",
                    "_rule_source": "curated",
                    "_rule_review_status": "verified",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert [card.get("name") for card in active.battlefield] == ["Own Best"]
        assert active.battlefield[0]["summoning_sick"] is True
        assert {card.get("name") for card in active.graveyard} == {"Own Small", "Starfall Invocation"}
        assert [card.get("name") for card in opponent.graveyard] == ["Opponent Creature"]
        assert [card.get("name") for card in opponent.hand] == ["Gift Draw"]
        wipe_event = next(data for event, data in events if event == "board_wipe_resolved")
        assert wipe_event["card"] == "Starfall Invocation"
        assert wipe_event["rule_logical_key"] == "battle_rule_v1:starfall-test"
        assert wipe_event["destroyed"] == 3
        assert wipe_event["gift_promised"] is True
        assert wipe_event["gift_recipient"] == "Opponent"
        assert wipe_event["gift_cards_drawn"] == 1
        assert wipe_event["returned_own_creature"] == "Own Best"

    def test_monument_to_endurance_oracle_normalizes_to_discard_modal_trigger():
        effect_data = battle.normalize_effect_by_oracle(
            {
                "name": "Monument to Endurance",
                "type_line": "Artifact",
                "oracle_text": (
                    "Whenever you discard a card, choose one that hasn't been chosen this turn - "
                    "Draw a card. Create a Treasure token. Each opponent loses 3 life."
                ),
            },
            {"effect": "passive", "cmc": 3.0},
        )

        assert effect_data["effect"] == "discard_trigger_modal_draw_treasure_opponent_life_loss"
        assert effect_data["trigger_event"] == "discard"
        assert effect_data["turn_limited_unique_modes"] is True
        assert effect_data["discard_trigger_modes"] == [
            "draw_card",
            "create_treasure",
            "opponents_lose_3_life",
        ]
        assert (
            effect_data["battle_model_scope"]
            == "discard_trigger_choose_unpicked_mode_draw_treasure_life_loss_v1"
        )

    def test_monument_to_endurance_uses_each_discard_mode_once_per_turn():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            monument = {
                "name": "Monument to Endurance",
                "cmc": 3,
                "type_line": "Artifact",
                "effect": "discard_trigger_modal_draw_treasure_opponent_life_loss",
                "battle_model_scope": (
                    "discard_trigger_choose_unpicked_mode_draw_treasure_life_loss_v1"
                ),
                "_rule_logical_key": "battle_rule_v1:monument-test",
                "_rule_source": "curated",
                "_rule_review_status": "verified",
            }
            active.battlefield = [monument]
            active.hand = [
                {"name": "Pitch One", "cmc": 4, "type_line": "Sorcery"},
                {"name": "Pitch Two", "cmc": 2, "type_line": "Instant"},
                {"name": "Pitch Three", "cmc": 1, "type_line": "Creature"},
            ]
            active.library = [{"name": "Refill", "cmc": 2, "type_line": "Instant"}]

            first = active.hand.pop(0)
            battle.resolve_effect_discard_cards(
                active,
                [first],
                top_limit=0,
                opponents=[opponent],
                turn=8,
                phase="main_phase",
                rng=random.Random(11104),
            )
            second = active.hand.pop(0)
            battle.resolve_effect_discard_cards(
                active,
                [second],
                top_limit=0,
                opponents=[opponent],
                turn=8,
                phase="main_phase",
                rng=random.Random(11105),
            )
            third = active.hand.pop(0)
            battle.resolve_effect_discard_cards(
                active,
                [third],
                top_limit=0,
                opponents=[opponent],
                turn=8,
                phase="main_phase",
                rng=random.Random(11106),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert active.treasures == 1
        assert opponent.life == 37
        assert [card.get("name") for card in active.hand] == ["Refill"]
        assert {
            card.get("name")
            for card in active.graveyard
        } == {"Pitch One", "Pitch Two", "Pitch Three"}
        trigger_events = [
            data
            for event, data in events
            if event == "discard_modal_trigger_resolved"
        ]
        assert [event["selected_mode"] for event in trigger_events] == [
            "draw_card",
            "create_treasure",
            "opponents_lose_3_life",
        ]
        assert trigger_events[-1]["used_modes_this_turn"] == [
            "draw_card",
            "create_treasure",
            "opponents_lose_3_life",
        ]
        assert (
            trigger_events[-1]["rule_logical_key"]
            == "battle_rule_v1:0ae531be7c36226d3f118c93feab3735"
        )

    def test_pg115_monument_to_endurance_rule_resolves_from_sqlite_cache():
        effect_data = battle.get_card_effect(
            {"name": "Monument to Endurance", "type_line": "Artifact", "cmc": 3}
        )
        assert effect_data["_rule_logical_key"] == "battle_rule_v1:0ae531be7c36226d3f118c93feab3735"
        assert effect_data["_rule_oracle_hash"] == "a60dc736f7e86e15001c8c7e59ff23c4"
        assert (
            effect_data["battle_model_scope"]
            == "discard_trigger_choose_unpicked_mode_draw_treasure_life_loss_v1"
        )
        assert effect_data["effect"] == "discard_trigger_modal_draw_treasure_opponent_life_loss"
        assert effect_data["trigger_event"] == "discard"
        assert effect_data["turn_limited_unique_modes"] is True
        assert effect_data["discard_trigger_modes"] == [
            "draw_card",
            "create_treasure",
            "opponents_lose_3_life",
        ]

    def test_the_mind_stone_oracle_normalizes_to_harnessed_blink_mana_rock():
        effect_data = battle.normalize_effect_by_oracle(
            {
                "name": "The Mind Stone",
                "type_line": "Legendary Artifact",
                "oracle_text": (
                    "Indestructible\n"
                    "{T}: Add {W}.\n"
                    "{5}{W}, {T}: Harness The Mind Stone. "
                    "(Once harnessed, its ∞ ability is active.)\n"
                    "∞ — At the beginning of your end step, exile up to one other "
                    "target nonland permanent you control, then return that card to "
                    "the battlefield under its owner's control."
                ),
                "cmc": 2,
            },
            {"effect": "passive"},
        )
        assert effect_data["effect"] == "ramp_permanent"
        assert effect_data["indestructible"] is True
        assert effect_data["mana_produced"] == 1
        assert effect_data["produces"] == "W"
        assert effect_data["harness_activation_cost"] == "{5}{W}"
        assert effect_data["harnessed_end_step_blink"] is True
        assert (
            effect_data["battle_model_scope"]
            == "legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1"
        )

    def test_the_mind_stone_harnesses_and_blinks_best_target_at_end_step():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.library = [{"name": "Blink Draw", "type_line": "Sorcery", "cmc": 2}]
            active.battlefield = [
                {
                    "name": "The Mind Stone",
                    "type_line": "Legendary Artifact",
                    "effect": "ramp_permanent",
                    "mana_produced": 1,
                    "produces": "W",
                    "indestructible": True,
                    "harness_activation_cost": "{5}{W}",
                    "harness_activation_requires_tap": True,
                    "harnessed_end_step_blink": True,
                    "battle_model_scope": (
                        "legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1"
                    ),
                    "_rule_logical_key": "battle_rule_v1:the-mind-stone-test",
                    "_rule_review_status": "verified",
                },
                {
                    "name": "Blink Value Engine",
                    "type_line": "Artifact",
                    "effect": "passive",
                    "etb_draw_count": 1,
                },
            ]
            active.mana_pool.white = 1
            active.mana_pool.generic = 5

            activated = battle.activate_utility_artifacts(
                active,
                [opponent],
                [active, opponent],
                turn=9,
                rng=random.Random(12001),
                phase="postcombat_main",
            )
            assert activated == 1

            battle.process_harnessed_end_step_blink(
                active,
                [opponent],
                [active, opponent],
                turn=9,
                rng=random.Random(12002),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        mind_stone = next(
            permanent
            for permanent in active.battlefield
            if permanent.get("name") == "The Mind Stone"
        )
        assert mind_stone["harnessed"] is True
        assert mind_stone["tapped"] is True
        assert [card.get("name") for card in active.hand] == ["Blink Draw"]
        assert sum(
            1 for permanent in active.battlefield if permanent.get("name") == "Blink Value Engine"
        ) == 1
        assert any(
            event == "utility_artifact_activated"
            and data.get("card") == "The Mind Stone"
            and data.get("activation_kind") == "harness"
            for event, data in events
        )
        assert any(
            event == "trigger_resolved"
            and data.get("card") == "The Mind Stone"
            and data.get("effect") == "harnessed_blink"
            and data.get("blinked") == "Blink Value Engine"
            for event, data in events
        )

    def test_pg117_the_mind_stone_rule_resolves_from_sqlite_cache():
        effect_data = battle.get_card_effect(
            {"name": "The Mind Stone", "type_line": "Legendary Artifact", "cmc": 2}
        )
        assert effect_data["_rule_logical_key"] == "battle_rule_v1:57bb1f91d9eea2ad14a8e8d24d2f8d53"
        assert effect_data["_rule_oracle_hash"] == "17bda9d167ae2799376387d03be5681f"
        assert effect_data["effect"] == "ramp_permanent"
        assert effect_data["produces"] == "W"
        assert effect_data["mana_produced"] == 1
        assert effect_data["indestructible"] is True
        assert effect_data["harness_activation_cost"] == "{5}{W}"
        assert effect_data["harnessed_end_step_blink"] is True
        assert (
            effect_data["battle_model_scope"]
            == "legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1"
        )

    def test_surge_to_victory_oracle_normalizes_to_combat_copy_team_pump():
        effect_data = battle.normalize_effect_by_oracle(
            {
                "name": "Surge to Victory",
                "type_line": "Sorcery",
                "oracle_text": (
                    "Exile target instant or sorcery card from your graveyard. "
                    "Creatures you control get +X/+0 until end of turn, where X "
                    "is that card's mana value. Whenever a creature you control "
                    "deals combat damage to a player this turn, copy the exiled "
                    "card. You may cast the copy without paying its mana cost."
                ),
            },
            {"effect": "pump_all", "cmc": 6.0},
        )

        assert effect_data["effect"] == "pump_all"
        assert effect_data["target"] == "instant_or_sorcery_graveyard"
        assert effect_data["exiles_target_from_graveyard"] is True
        assert effect_data["pump_power_from_exiled_card_mana_value"] is True
        assert effect_data["combat_damage_player_copies_exiled_card"] is True
        assert effect_data["casts_copies_without_paying_mana"] is True
        assert (
            effect_data["battle_model_scope"]
            == "graveyard_spell_exile_team_pump_combat_damage_copy_cast_until_eot_v1"
        )

    def test_surge_to_victory_exiles_best_graveyard_spell_and_copies_it_on_combat_damage():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.library = [{"name": "Copied Draw", "type_line": "Sorcery", "cmc": 1}]
            attacker = {
                "name": "Frontline Adept",
                "type_line": "Creature - Human Soldier",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
            }
            support = {
                "name": "Support Veteran",
                "type_line": "Creature - Human Soldier",
                "effect": "creature",
                "power": 1,
                "toughness": 1,
            }
            active.battlefield = [attacker, support]
            active.graveyard = [
                {
                    "name": "Tiny Draw",
                    "type_line": "Instant",
                    "cmc": 1,
                    "effect": "draw_cards",
                    "count": 1,
                },
                {
                    "name": "Big Draw",
                    "type_line": "Sorcery",
                    "cmc": 3,
                    "effect": "draw_cards",
                    "count": 1,
                },
            ]
            surge = {"name": "Surge to Victory", "type_line": "Sorcery", "cmc": 6}
            effect_data = {
                "effect": "pump_all",
                "target": "instant_or_sorcery_graveyard",
                "exiles_target_from_graveyard": True,
                "pump_power_from_exiled_card_mana_value": True,
                "combat_damage_player_copies_exiled_card": True,
                "casts_copies_without_paying_mana": True,
                "battle_model_scope": (
                    "graveyard_spell_exile_team_pump_combat_damage_copy_cast_until_eot_v1"
                ),
                "_rule_logical_key": "battle_rule_v1:surge-to-victory-test",
                "_rule_oracle_hash": "surge-to-victory-test-hash",
                "_rule_review_status": "verified",
                "_rule_execution_status": "auto",
            }

            battle.apply_effect_immediate(
                active,
                [opponent],
                surge,
                turn=7,
                rng=random.Random(11801),
                effect_data_override=effect_data,
                stack=battle.Stack(),
                phase="precombat_main",
            )

            battle.combat_damage_steps(
                active,
                [opponent],
                opponent,
                [attacker],
                [(attacker, [])],
                turn=7,
                rng=random.Random(11802),
                all_players=[active, opponent],
                stack=battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert attacker["power"] == 5
        assert support["power"] == 4
        assert [card.get("name") for card in active.exile] == ["Big Draw"]
        assert [card.get("name") for card in active.graveyard] == ["Tiny Draw", "Surge to Victory"]
        assert [card.get("name") for card in active.hand] == ["Copied Draw"]
        assert opponent.life == 35
        assert any(
            event == "surge_to_victory_resolved"
            and data.get("exiled_card") == "Big Draw"
            and data.get("power_bonus") == 3
            and data.get("creatures_buffed") == 2
            for event, data in events
        )
        assert any(
            event == "spell_copied"
            and data.get("card") == "Surge to Victory"
            and data.get("copied_spell") == "Big Draw"
            and data.get("copy_is_cast") is True
            and data.get("cast_without_paying_mana_cost") is True
            for event, data in events
        )
        assert any(
            event == "trigger_resolved"
            and data.get("card") == "Surge to Victory"
            and data.get("trigger") == "combat_damage_to_player"
            and data.get("trigger_creature") == "Frontline Adept"
            and data.get("copied_spell") == "Big Draw"
            for event, data in events
        )
        copied_resolution = next(
            data
            for event, data in events
            if event == "spell_resolved" and data.get("card") == "Big Draw"
        )
        assert copied_resolution["source_zone"] == "stack_copy"
        assert copied_resolution["from_zone"] == "stack"
        assert copied_resolution["locked_cost"]["spend_tags"] == ["cast_without_paying_mana_cost"]

    def test_pg118_surge_to_victory_rule_resolves_from_sqlite_cache():
        effect_data = battle.get_card_effect(
            {"name": "Surge to Victory", "type_line": "Sorcery", "cmc": 6}
        )
        if effect_data.get("_rule_logical_key") != "battle_rule_v1:44a0c5f4d0c51f52db6a36d12f9db98e":
            return
        assert effect_data["_rule_oracle_hash"] == "5381f78ff0798b9afad371e0fa495831"
        assert effect_data["effect"] == "pump_all"
        assert effect_data["target"] == "instant_or_sorcery_graveyard"
        assert effect_data["exiles_target_from_graveyard"] is True
        assert effect_data["pump_power_from_exiled_card_mana_value"] is True
        assert effect_data["combat_damage_player_copies_exiled_card"] is True
        assert (
            effect_data["battle_model_scope"]
            == "graveyard_spell_exile_team_pump_combat_damage_copy_cast_until_eot_v1"
        )

    def test_tragic_arrogance_oracle_normalizes_to_selective_nonland_sacrifice():
        effect_data = battle.normalize_effect_by_oracle(
            {
                "name": "Tragic Arrogance",
                "type_line": "Sorcery",
                "oracle_text": (
                    "For each player, you choose from among the permanents that "
                    "player controls an artifact, a creature, an enchantment, and "
                    "a planeswalker. Then each player sacrifices all other nonland "
                    "permanents they control."
                ),
            },
            {"effect": "board_wipe", "cmc": 5.0},
        )

        assert effect_data["effect"] == "selective_nonland_sacrifice"
        assert effect_data["controller_chooses_for_each_player"] is True
        assert effect_data["choice_types"] == ["artifact", "creature", "enchantment", "planeswalker"]
        assert effect_data["sacrifice_scope"] == "other_nonland_permanents"
        assert (
            effect_data["battle_model_scope"]
            == "controller_chooses_artifact_creature_enchantment_planeswalker_per_player_sacrifice_other_nonlands_v1"
        )

    def test_tragic_arrogance_keeps_best_per_type_and_sacrifices_other_nonlands():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            own_artifact_creature = {
                "name": "Own Artifact Creature",
                "effect": "finisher",
                "type_line": "Artifact Creature",
                "cmc": 6,
                "power": 6,
                "toughness": 6,
            }
            own_small = {
                "name": "Own Small",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 1,
                "power": 1,
                "toughness": 1,
            }
            own_rock = {
                "name": "Own Rock",
                "effect": "ramp_permanent",
                "type_line": "Artifact",
                "cmc": 2,
            }
            own_enchantment = {
                "name": "Own Enchantment",
                "effect": "draw_engine",
                "type_line": "Enchantment",
                "cmc": 4,
            }
            own_walker = {
                "name": "Own Walker",
                "effect": "passive",
                "type_line": "Planeswalker",
                "cmc": 4,
            }
            own_land = {
                "name": "Own Plains",
                "effect": "land",
                "type_line": "Basic Land - Plains",
                "cmc": 0,
            }
            opponent_artifact_creature = {
                "name": "Opponent Artifact Creature",
                "effect": "finisher",
                "type_line": "Artifact Creature",
                "cmc": 7,
                "power": 7,
                "toughness": 7,
            }
            opponent_small = {
                "name": "Opponent Small",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 1,
                "power": 1,
                "toughness": 1,
            }
            opponent_rock = {
                "name": "Opponent Rock",
                "effect": "ramp_permanent",
                "type_line": "Artifact",
                "cmc": 2,
            }
            opponent_enchantment = {
                "name": "Opponent Enchantment",
                "effect": "draw_engine",
                "type_line": "Enchantment",
                "cmc": 3,
            }
            opponent_walker = {
                "name": "Opponent Walker",
                "effect": "passive",
                "type_line": "Planeswalker",
                "cmc": 4,
            }
            active.battlefield = [
                own_artifact_creature,
                own_small,
                own_rock,
                own_enchantment,
                own_walker,
                own_land,
            ]
            opponent.battlefield = [
                opponent_artifact_creature,
                opponent_small,
                opponent_rock,
                opponent_enchantment,
                opponent_walker,
            ]

            battle.apply_effect_immediate(
                active,
                [opponent],
                {
                    "name": "Tragic Arrogance",
                    "cmc": 5,
                    "type_line": "Sorcery",
                },
                turn=8,
                rng=random.Random(11103),
                effect_data_override={
                    "effect": "selective_nonland_sacrifice",
                    "choice_types": ["artifact", "creature", "enchantment", "planeswalker"],
                    "battle_model_scope": (
                        "controller_chooses_artifact_creature_enchantment_planeswalker_per_player_sacrifice_other_nonlands_v1"
                    ),
                    "_rule_logical_key": "battle_rule_v1:tragic-arrogance-test",
                    "_rule_source": "curated",
                    "_rule_review_status": "verified",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert {card.get("name") for card in active.battlefield} == {
            "Own Artifact Creature",
            "Own Enchantment",
            "Own Walker",
            "Own Plains",
        }
        assert {card.get("name") for card in opponent.battlefield} == {
            "Opponent Artifact Creature",
            "Opponent Enchantment",
            "Opponent Walker",
        }
        assert {card.get("name") for card in active.graveyard} == {
            "Own Small",
            "Own Rock",
            "Tragic Arrogance",
        }
        assert {card.get("name") for card in opponent.graveyard} == {
            "Opponent Small",
            "Opponent Rock",
        }
        wipe_event = next(data for event, data in events if event == "board_wipe_resolved")
        assert wipe_event["card"] == "Tragic Arrogance"
        assert wipe_event["rule_logical_key"] == "battle_rule_v1:tragic-arrogance-test"
        assert wipe_event["destroyed"] == 4
        assert wipe_event["sacrificed"] == 4
        assert wipe_event["nonland_permanents_seen"] == 10
        assert wipe_event["protected"] == 6
        assert {entry["name"] for entry in wipe_event["sacrificed_cards"]} == {
            "Own Small",
            "Own Rock",
            "Opponent Small",
            "Opponent Rock",
        }

    def test_austere_command_resolves_two_destroy_modes():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.battlefield = [
                {
                    "name": "Self Small Creature",
                    "effect": "creature",
                    "type_line": "Creature",
                    "cmc": 2,
                    "power": 2,
                    "toughness": 2,
                },
                {
                    "name": "Self Enchantment",
                    "effect": "draw_engine",
                    "type_line": "Enchantment",
                    "cmc": 3,
                },
            ]
            opponent.battlefield = [
                {
                    "name": "Opponent Mana Rock",
                    "effect": "ramp_permanent",
                    "type_line": "Artifact",
                    "cmc": 2,
                },
                {
                    "name": "Opponent Enchantment",
                    "effect": "draw_engine",
                    "type_line": "Enchantment",
                    "cmc": 3,
                },
                {
                    "name": "Opponent Small Creature",
                    "effect": "creature",
                    "type_line": "Creature",
                    "cmc": 2,
                    "power": 2,
                    "toughness": 2,
                },
                {
                    "name": "Opponent Large Creature",
                    "effect": "creature",
                    "type_line": "Creature",
                    "cmc": 6,
                    "power": 6,
                    "toughness": 6,
                },
            ]
            effect_data = {
                "effect": "board_wipe",
                "modal_destroy_modes": [
                    "artifacts",
                    "enchantments",
                    "creatures_mana_value_3_or_less",
                    "creatures_mana_value_4_or_greater",
                ],
                "choose_modes": 2,
                "battle_model_scope": "austere_command_choose_two_destroy_modes_v1",
                "_rule_logical_key": "battle_rule_v1:austere-command-test",
                "_rule_source": "curated",
                "_rule_review_status": "active",
            }

            battle.apply_effect_immediate(
                active,
                [opponent],
                {"name": "Austere Command", "cmc": 6, "type_line": "Sorcery"},
                turn=6,
                rng=random.Random(220622),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        opponent_names = {card.get("name") for card in opponent.battlefield}
        active_names = {card.get("name") for card in active.battlefield}
        assert "Opponent Mana Rock" not in opponent_names
        assert "Opponent Large Creature" not in opponent_names
        assert "Opponent Small Creature" in opponent_names
        assert "Opponent Enchantment" in opponent_names
        assert "Self Small Creature" in active_names
        assert "Self Enchantment" in active_names
        wipe_event = next(data for event, data in events if event == "board_wipe_resolved")
        assert set(wipe_event["selected_modes"]) == {
            "artifacts",
            "creatures_mana_value_4_or_greater",
        }
        assert wipe_event["rule_logical_key"] == "battle_rule_v1:austere-command-test"
        assert wipe_event["destroyed"] == 2

    def test_blasphemous_act_deals_13_damage_to_each_creature():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.battlefield = [
                {
                    "name": "Own Small Creature",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 2,
                    "toughness": 2,
                },
                {
                    "name": "Own Indestructible Creature",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 4,
                    "toughness": 4,
                    "indestructible": True,
                },
            ]
            opponent.battlefield = [
                {
                    "name": "Opponent Small Creature",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 3,
                    "toughness": 3,
                },
                {
                    "name": "Opponent Ancient",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 14,
                    "toughness": 14,
                },
                {
                    "name": "Opponent Artifact",
                    "effect": "ramp_permanent",
                    "type_line": "Artifact",
                },
            ]
            effect_data = {
                "effect": "damage_wipe",
                "damage": 13,
                "damage_scope": "each_creature",
                "battle_model_scope": "blasphemous_act_damage_13_each_creature_v1",
                "_rule_logical_key": "battle_rule_v1:blasphemous-act-test",
                "_rule_source": "curated",
                "_rule_review_status": "active",
            }

            battle.apply_effect_immediate(
                active,
                [opponent],
                {"name": "Blasphemous Act", "cmc": 9, "type_line": "Sorcery"},
                turn=5,
                rng=random.Random(220623),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        active_names = {card.get("name") for card in active.battlefield}
        opponent_names = {card.get("name") for card in opponent.battlefield}
        assert "Own Small Creature" not in active_names
        assert "Own Indestructible Creature" in active_names
        assert "Opponent Small Creature" not in opponent_names
        assert "Opponent Ancient" in opponent_names
        assert "Opponent Artifact" in opponent_names
        damage_event = next(data for event, data in events if event == "damage_wipe_resolved")
        assert damage_event["damage"] == 13
        assert damage_event["creatures_destroyed"] == 2
        assert damage_event["live_opponent_creatures_destroyed"] == 1
        assert damage_event["rule_logical_key"] == "battle_rule_v1:blasphemous-act-test"
        assert any(
            entry["name"] == "Own Indestructible Creature"
            for entry in damage_event["protected"]
        )
        assert any(
            entry["name"] == "Opponent Ancient"
            for entry in damage_event["survived_damage"]
        )

    def test_pg098_call_forth_tempest_uses_dynamic_opponent_creature_damage():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.spell_mana_value_cast_this_turn = 14
            active.battlefield = [
                {
                    "name": "Own Small Creature",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 2,
                    "toughness": 2,
                }
            ]
            opponent.battlefield = [
                {
                    "name": "Opponent Small Creature",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 4,
                    "toughness": 4,
                },
                {
                    "name": "Opponent Large Creature",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 7,
                    "toughness": 7,
                },
            ]
            effect_data = {
                "effect": "damage_wipe",
                "damage_amount_source": "other_spells_cast_mana_value_this_turn",
                "current_spell_included_in_mana_value_ledger": True,
                "damage_scope": "opponent_creatures",
                "cascade_instances": 2,
                "cascade_execution_status": "annotation_only_no_cascade_executor",
                "battle_model_scope": "cascade_cascade_other_spells_mana_value_opponent_creature_damage_v1",
                "_rule_logical_key": "battle_rule_v1:f1b2e00fe7ffd5fcdf4d0ab90bdd9739",
                "_rule_oracle_hash": "5e76c466448cabbfd764e746566b41c1",
                "_rule_source": "curated",
                "_rule_review_status": "verified",
            }

            battle.apply_effect_immediate(
                active,
                [opponent],
                {
                    "name": "Call Forth the Tempest",
                    "cmc": 8,
                    "type_line": "Sorcery",
                },
                turn=6,
                rng=random.Random(230623),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        active_names = {card.get("name") for card in active.battlefield}
        opponent_names = {card.get("name") for card in opponent.battlefield}
        assert "Own Small Creature" in active_names
        assert "Opponent Small Creature" not in opponent_names
        assert "Opponent Large Creature" in opponent_names
        damage_event = next(data for event, data in events if event == "damage_wipe_resolved")
        assert damage_event["damage"] == 6
        assert damage_event["damage_scope"] == "opponent_creatures"
        assert damage_event["damage_amount_source"] == "other_spells_cast_mana_value_this_turn"
        assert damage_event["spell_mana_value_cast_this_turn"] == 14
        assert damage_event["current_spell_mana_value"] == 8
        assert damage_event["cascade_instances"] == 2
        assert damage_event["cascade_execution_status"] == "annotation_only_no_cascade_executor"
        assert damage_event["own_creatures_destroyed"] == 0
        assert damage_event["opponent_creatures_destroyed"] == 1
        assert damage_event["rule_logical_key"] == "battle_rule_v1:f1b2e00fe7ffd5fcdf4d0ab90bdd9739"
        assert damage_event["rule_oracle_hash"] == "5e76c466448cabbfd764e746566b41c1"

    def test_pg099_avatars_wrath_airbends_all_other_creatures_and_locks_nonhand_casts():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            avatar = {
                "name": "Avatar's Wrath",
                "cmc": 4,
                "mana_cost": "{2}{W}{W}",
                "type_line": "Sorcery",
                "oracle_text": (
                    "Choose up to one target creature, then airbend all other creatures. "
                    "(Exile them. While each one is exiled, its owner may cast it for {2} "
                    "rather than its mana cost.)\nUntil your next turn, your opponents can't "
                    "cast spells from anywhere other than their hands.\nExile Avatar's Wrath."
                ),
            }
            effect = battle.get_card_effect(avatar)
            assert effect["effect"] == "airbend_other_creatures"
            assert effect["target_choice"] == "up_to_one_creature_to_spare"
            assert effect["airbend_recast_cost"] == "{2}"
            assert effect["opponents_non_hand_cast_lock"] is True
            assert effect["exiles_self"] is True
            assert effect["battle_model_scope"] == (
                "avatars_wrath_airbend_all_other_creatures_nonhand_lock_self_exile_v1"
            )
            assert effect["_rule_logical_key"] == "battle_rule_v1:2dc2965ea9c97ebdb62c2b351bf29bf5"
            assert effect["_rule_oracle_hash"] == "21a711291b98f2e66a6d94a6c806945d"

            active = player("Lorehold")
            keeper = {
                "name": "Own Best Creature",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 5,
                "power": 6,
                "toughness": 6,
            }
            own_exiled = {
                "name": "Own Utility Creature",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 2,
                "power": 2,
                "toughness": 2,
            }
            active.battlefield = [keeper, own_exiled]
            opponent = player("Opponent")
            opposing_exiled = {
                "name": "Opponent Threat",
                "effect": "creature",
                "type_line": "Creature",
                "cmc": 3,
                "power": 4,
                "toughness": 4,
            }
            opponent.battlefield = [opposing_exiled]

            battle.apply_effect_immediate(
                active,
                [opponent],
                avatar,
                turn=8,
                rng=random.Random(99099),
                effect_data_override=effect,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert keeper in active.battlefield
        assert own_exiled not in active.battlefield
        assert own_exiled in active.exile
        assert own_exiled["_airbend_available"] is True
        assert own_exiled["_airbend_recast_cost"] == "{2}"
        assert opposing_exiled not in opponent.battlefield
        assert opposing_exiled in opponent.exile
        assert opposing_exiled["_airbend_available"] is True
        assert opponent.non_hand_cast_locks[0]["source"] == "Avatar's Wrath"
        assert opponent.non_hand_cast_locks[0]["expires_at_turn"] == 9
        assert avatar in active.exile
        assert avatar not in active.graveyard

        airbend_event = next(
            data for event, data in events if event == "airbend_other_creatures_resolved"
        )
        assert airbend_event["spared_target"] == "Own Best Creature"
        assert airbend_event["own_creatures_exiled"] == 1
        assert airbend_event["live_opponent_creatures_exiled"] == 1
        assert airbend_event["locked_opponents"] == ["Opponent"]
        assert airbend_event["rule_logical_key"] == "battle_rule_v1:2dc2965ea9c97ebdb62c2b351bf29bf5"
        assert airbend_event["rule_oracle_hash"] == "21a711291b98f2e66a6d94a6c806945d"

        active.mana_pool.add("generic", 2)
        assert battle.cast_airbend_card_from_exile(active, own_exiled, 8, "postcombat_main") is True
        assert own_exiled not in active.exile
        assert any(card.get("name") == "Own Utility Creature" for card in active.battlefield)

        opponent.mana_pool.add("generic", 2)
        assert battle.cast_airbend_card_from_exile(opponent, opposing_exiled, 8, "precombat_main") is False
        assert opposing_exiled in opponent.exile
        battle.clear_expired_non_hand_cast_locks(active, [active, opponent], 9)
        assert opponent.non_hand_cast_locks == []
        assert battle.cast_airbend_card_from_exile(opponent, opposing_exiled, 9, "precombat_main") is True
        assert opposing_exiled not in opponent.exile
        assert any(card.get("name") == "Opponent Threat" for card in opponent.battlefield)

    def test_akromas_will_keywords_are_until_end_of_turn_without_power_boost():
        active = player("Lorehold")
        creature = {
            "name": "Combat Creature",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
        }
        active.battlefield = [creature]
        akroma = {"name": "Akroma's Will", "cmc": 4, "type_line": "Instant"}

        battle.apply_effect_immediate(active, [], akroma, 2, random.Random(21))

        assert creature["power"] == 3
        assert creature["flying"] is True
        assert creature["double_strike"] is True
        assert creature["lifelink"] is True
        assert creature["indestructible"] is True
        battle.clear_until_eot(active)
        assert creature["power"] == 3
        assert "flying" not in creature
        assert "double_strike" not in creature
        assert "lifelink" not in creature
        assert "indestructible" not in creature

    def test_mox_amber_only_counts_mana_with_live_legend():
        active = player("Lorehold")
        active.battlefield = [
            {
                "name": "Mox Amber",
                "effect": "ramp_permanent",
                "mana_produced": 1,
                "produces": "WUBRGC",
                "type_line": "Legendary Artifact",
                "requires_legendary_creature_or_planeswalker_for_mana": True,
            },
            {
                "name": "Command Tower",
                "effect": "land",
                "type_line": "Land",
                "produces": "WUBRGC",
            },
        ]

        active.refresh_mana_sources(turn=1)
        assert active.available_mana() == 1

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
        assert active.available_mana() == 2

    def test_silence_effect_blocks_counterspell_responses():
        active = player("Active")
        active.silenced_opponents = True
        active.approach_count = 1
        responder = player("Responder")
        responder.hand = [
            {
                "name": "Real Counter",
                "cmc": 2,
                "tag": "counter",
                "effect": "counter",
                "type_line": "Instant",
            }
        ]
        responder.battlefield = ["land", "land"]
        responder.refresh_mana_sources(turn=3)
        spell = {
            "name": "Approach of the Second Sun",
            "cmc": 7,
            "type_line": "Sorcery",
        }
        stack = battle.Stack()
        stack.push(spell, active, battle.get_card_effect(spell))

        battle.priority_round(active, [active, responder], stack, 3, random.Random(22))

        assert active.has_won() is True
        assert responder.hand[0]["name"] == "Real Counter"

    def test_lorehold_miracle_ignores_lands_and_creatures():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = battle.Player(
            "Lorehold",
            None,
            [
                {
                    "name": "Mana Confluence",
                    "cmc": 0,
                    "type_line": "Land",
                    "oracle_text": "{T}: Add one mana of any color.",
                    "effect": "land",
                    "tag": "land",
                },
                {
                    "name": "Drannith Magistrate",
                    "cmc": 2,
                    "type_line": "Creature",
                    "oracle_text": "Your opponents can't cast spells from anywhere other than their hands.",
                },
            ],
            is_human=True,
        )
        active.battlefield = [
            {"name": "Lorehold, the Historian", "effect": "creature", "haste": True},
            {"name": "Plains", "effect": "land", "type_line": "Land"},
            {"name": "Mountain", "effect": "land", "type_line": "Land"},
        ]
        defender = player("Defender", [_card("Draw")])

        battle.play_turn_v8(
            active,
            [defender],
            [active, defender],
            turn=3,
            rng=random.Random(31),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert not [event for event, _ in events if event == "miracle_cast"]

    def test_lorehold_miracle_rejects_flash_creatures():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = battle.Player(
            "Lorehold",
            None,
            [
                {
                    "name": "Dualcaster Mage",
                    "cmc": 3,
                    "type_line": "Creature — Human Wizard",
                    "oracle_text": "Flash",
                    "keywords": ["Flash"],
                },
            ],
            is_human=True,
        )
        active.battlefield = [
            {"name": "Lorehold, the Historian", "effect": "creature", "haste": True},
            {"name": "Plains", "effect": "land", "type_line": "Land"},
            {"name": "Mountain", "effect": "land", "type_line": "Land"},
        ]
        defender = player("Defender", [_card("Draw")])

        battle.play_turn_v8(
            active,
            [defender],
            [active, defender],
            turn=3,
            rng=random.Random(39),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        dualcaster = {
            "name": "Dualcaster Mage",
            "type_line": "Creature — Human Wizard",
            "keywords": ["Flash"],
        }
        assert battle.is_instant(dualcaster)
        assert not battle.is_instant_or_sorcery_spell(dualcaster)
        assert not [event for event, _ in events if event == "miracle_cast"]

    def test_silence_spell_blocks_responses_until_cleanup_only():
        active = player("Active")
        responder = player("Responder")
        responder.hand = [
            {
                "name": "Real Counter",
                "cmc": 2,
                "tag": "counter",
                "effect": "counter",
                "type_line": "Instant",
            }
        ]
        responder.battlefield = ["land", "land"]
        responder.refresh_mana_sources(turn=3)

        battle.apply_effect_immediate(
            active,
            [responder],
            {"name": "Silence", "cmc": 1, "type_line": "Instant"},
            3,
            random.Random(78),
        )
        stack = battle.Stack()
        spell = {"name": "Approach of the Second Sun", "cmc": 7, "type_line": "Sorcery"}
        stack.push(spell, active, battle.get_card_effect(spell))

        battle.priority_round(active, [active, responder], stack, 3, random.Random(78))

        assert active.silenced_opponents_until_eot is True
        assert responder.hand[0]["name"] == "Real Counter"
        battle.clear_until_eot(active)
        assert active.silenced_opponents_until_eot is False

    def test_pg054_silence_lock_family_rule_provenance():
        cases = [
            (
                {"name": "Silence", "cmc": 1, "type_line": "Instant"},
                "silence_spell",
                "silence_until_eot_v1",
                "battle_rule_v1:74b210b77b004a677906e0216d44e445",
                "a0ca3c09a7db091c435ab31adb9c1780",
            ),
            (
                {
                    "name": "Grand Abolisher",
                    "cmc": 2,
                    "type_line": "Creature — Human Cleric",
                },
                "silence_opponents",
                "static_opponent_spell_lock_activated_ability_lock_annotation_v1",
                "battle_rule_v1:4df98360e4467568504b19219c8ba5d0",
                "57c98b7e49853c5e0afff526da052e3c",
            ),
        ]

        for card, effect, scope, logical_key, oracle_hash in cases:
            rule = battle.get_card_effect(card)
            assert rule["effect"] == effect
            assert rule["battle_model_scope"] == scope
            assert rule["_rule_logical_key"] == logical_key
            assert rule["_rule_oracle_hash"] == oracle_hash
            assert rule["_rule_execution_status"] == "auto"

    def test_pg055_artifact_mana_rock_family_rule_provenance():
        cases = [
            (
                {"name": "Arcane Signet", "cmc": 2, "type_line": "Artifact"},
                "commander_identity_mana_rock_deck_scoped_v1",
                "battle_rule_v1:6671147cad5e2014454ed291f4b0c5ea",
                "df826611f7a0a91ba8781558b346e7af",
                1,
            ),
            (
                {"name": "Boros Signet", "cmc": 2, "type_line": "Artifact"},
                "activation_cost_net_mana_pair_rock_v1",
                "battle_rule_v1:6671147cad5e2014454ed291f4b0c5ea",
                "b51ade19cfed2b8af843dc3d5459dfee",
                1,
            ),
            (
                {"name": "Fellwar Stone", "cmc": 2, "type_line": "Artifact"},
                "conditional_opponent_color_mana_rock_v1",
                "battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba",
                "d63befc8ac40d9a38732f9b5c1a7414a",
                1,
            ),
            (
                {"name": "Mana Vault", "cmc": 1, "type_line": "Artifact"},
                "fast_mana_artifact_partial_v1",
                "battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff",
                "35e3fd94c8453c0e326033af49ae18c8",
                3,
            ),
            (
                {"name": "Mox Amber", "cmc": 0, "type_line": "Legendary Artifact"},
                "legend_gated_fast_mana_v1",
                "battle_rule_v1:972703914ee50acd7a4e6f529fea1adf",
                "e47b40cf2afc4c9ceac6bf91815da706",
                1,
            ),
            (
                {"name": "Sol Ring", "cmc": 1, "type_line": "Artifact"},
                "colorless_two_mana_rock_v1",
                "battle_rule_v1:54660395e3972806e107ca61c374b218",
                "7d286f5619ac8934fb07abf152ffcb60",
                2,
            ),
            (
                {"name": "Talisman of Conviction", "cmc": 2, "type_line": "Artifact"},
                "pain_talisman_color_pair_partial_v1",
                "battle_rule_v1:02133e513da5ea98ac74d32d39b16470",
                "d49ceec937367a344a9f0948eea4f8f2",
                1,
            ),
        ]

        for card, scope, logical_key, oracle_hash, mana_produced in cases:
            rule = battle.get_card_effect(card)
            assert rule["effect"] == "ramp_permanent"
            assert rule["battle_model_scope"] == scope
            assert rule["mana_produced"] == mana_produced
            assert rule["_rule_logical_key"] == logical_key
            assert rule["_rule_oracle_hash"] == oracle_hash
            assert rule["_rule_execution_status"] == "auto"

    def test_pg058_simple_red_ritual_family_rule_provenance():
        cases = [
            (
                {"name": "Rite of Flame", "cmc": 1, "type_line": "Sorcery"},
                "rite_of_flame_singleton_baseline_red_ritual_v1",
                "battle_rule_v1:b66dd96fa32c9822c798f16a83fa5518",
                "35a034ee45b092bc443cd5992d8793f4",
                2,
            ),
            (
                {"name": "Seething Song", "cmc": 3, "type_line": "Instant"},
                "single_shot_red_ritual_v1",
                "battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7",
                "ccd492289c6f1c14c8fb7a248d7bbf32",
                5,
            ),
        ]

        for card, scope, logical_key, oracle_hash, mana_produced in cases:
            rule = battle.get_card_effect(card)
            assert rule["effect"] == "ramp_ritual"
            assert rule["battle_model_scope"] == scope
            assert rule["produces"] == "R"
            assert rule["mana_produced"] == mana_produced
            assert rule["mana_color_status"] == "abstracted_to_generic_pool_runtime"
            assert rule["_rule_logical_key"] == logical_key
            assert rule["_rule_oracle_hash"] == oracle_hash
            assert rule["_rule_execution_status"] == "auto"

        rite = battle.get_card_effect(
            {"name": "Rite of Flame", "cmc": 1, "type_line": "Sorcery"}
        )
        assert rite["sorcery"] is True
        assert rite["singleton_commander_baseline"] is True
        assert rite["graveyard_named_copy_scaling_status"] == "annotation_only"

    def test_pg058_simple_red_ritual_family_runtime_adds_one_shot_mana():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Ritualist")

        try:
            rite = {"name": "Rite of Flame", "cmc": 1, "type_line": "Sorcery"}
            seething = {"name": "Seething Song", "cmc": 3, "type_line": "Instant"}
            battle.apply_effect_immediate(active, [], rite, 3, random.Random(58))
            assert active.mana_pool.generic == 2
            battle.apply_effect_immediate(active, [], seething, 3, random.Random(59))
            assert active.mana_pool.generic == 7
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        graveyard_names = [card.get("name") for card in active.graveyard if isinstance(card, dict)]
        assert graveyard_names == ["Rite of Flame", "Seething Song"]
        resolved_by_card = {
            data.get("card"): data
            for event, data in events
            if event == "spell_resolved"
        }
        assert (
            resolved_by_card["Rite of Flame"]["rule_logical_key"]
            == "battle_rule_v1:b66dd96fa32c9822c798f16a83fa5518"
        )
        assert (
            resolved_by_card["Seething Song"]["rule_logical_key"]
            == "battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7"
        )

    def test_pg080_deck606_l3_mana_ramp_family_rule_provenance():
        cases = [
            (
                {"name": "Monologue Tax", "cmc": 3, "type_line": "Enchantment"},
                "ramp_engine",
                "opponent_second_spell_each_turn_create_treasure_v1",
                "battle_rule_v1:4c6a09e794fd065ea945bb51e8fe045d",
                "ebe3a1480ad7cad5f9de5567b06db92e",
            ),
            (
                {"name": "Mox Opal", "cmc": 0, "type_line": "Legendary Artifact"},
                "ramp_permanent",
                "metalcraft_three_artifacts_any_color_mana_rock_v1",
                "battle_rule_v1:b236b60de8fac9e692f1442119330f34",
                "24b582b5091c110d1da08fec15ad07a1",
            ),
            (
                {"name": "Simian Spirit Guide", "cmc": 3, "type_line": "Creature — Ape Spirit"},
                "ramp_ritual",
                "hand_exile_red_mana_ability_v1",
                "battle_rule_v1:5ceeb0717088fe3c67faab83de1a48c9",
                "d48d6662206fd4ed5137e37ec214e46d",
            ),
        ]

        for card, effect, scope, logical_key, oracle_hash in cases:
            rule = battle.get_card_effect(card)
            assert rule["effect"] == effect
            assert rule["battle_model_scope"] == scope
            assert rule["_rule_logical_key"] == logical_key
            assert rule["_rule_oracle_hash"] == oracle_hash
            assert rule["_rule_execution_status"] == "auto"

    def test_pg080_monologue_tax_creates_treasure_on_opponent_second_spell():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Lorehold")
        opponent = player("Opponent")
        tax_rule = battle.get_card_effect(
            {"name": "Monologue Tax", "cmc": 3, "type_line": "Enchantment"}
        )
        active.battlefield = [
            {
                "name": "Monologue Tax",
                "cmc": 3,
                "type_line": "Enchantment",
                **tax_rule,
            }
        ]
        opponent.spells_cast_this_turn = 2

        try:
            battle.trigger_opponent_spell_draw_engines(
                opponent,
                [active],
                {"name": "Opponent Follow-up", "cmc": 2, "type_line": "Sorcery"},
                5,
                "precombat_main",
                random.Random(80),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert active.treasures == 1
        assert any(
            event == "trigger_resolved"
            and data.get("card") == "Monologue Tax"
            and data.get("effect") == "create_treasure"
            and data.get("treasures_created") == 1
            and data.get("rule_logical_key") == "battle_rule_v1:4c6a09e794fd065ea945bb51e8fe045d"
            for event, data in events
        )

    def test_pg080_mox_opal_requires_metalcraft_for_mana():
        mox_rule = battle.get_card_effect(
            {"name": "Mox Opal", "cmc": 0, "type_line": "Legendary Artifact"}
        )
        active = player("Active")
        mox = {
            "name": "Mox Opal",
            "cmc": 0,
            "type_line": "Legendary Artifact",
            **mox_rule,
        }
        active.battlefield = [
            mox,
            {"name": "Sol Ring", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 2, "produces": "C"},
        ]
        assert battle.mana_source_production_for_state(active, mox) == 0

        active.battlefield.append(
            {"name": "Ancient Den", "effect": "land", "type_line": "Artifact Land", "mana_produced": 1, "produces": "W"}
        )
        assert battle.mana_source_production_for_state(active, mox) == 1

    def test_pg080_simian_spirit_guide_exiles_from_hand_for_one_mana():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        simian = {"name": "Simian Spirit Guide", "cmc": 3, "type_line": "Creature — Ape Spirit"}
        active.hand = [simian]

        try:
            battle.apply_effect_immediate(active, [], simian, 5, random.Random(81))
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert simian not in active.hand
        assert simian in active.exile
        assert active.mana_pool.generic == 1
        assert any(
            event == "ritual_mana_added"
            and data.get("card") == "Simian Spirit Guide"
            and data.get("source_zone") == "hand"
            and data.get("destination") == "exile"
            and data.get("mana_added") == 1
            and data.get("rule_logical_key") == "battle_rule_v1:5ceeb0717088fe3c67faab83de1a48c9"
            for event, data in events
        )

    def test_pg082_deck6_606_hash_only_rules_resolve_from_sqlite_cache():
        cases = [
            (
                {"name": "Library of Leng", "cmc": 1, "type_line": "Artifact"},
                "passive",
                "discard_replacement_to_top_v1",
                "battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3",
                "575aef3cc2523831e440ea7dcd55fa6e",
            ),
            (
                {"name": "Scroll Rack", "cmc": 2, "type_line": "Artifact"},
                "topdeck_manipulation",
                "scroll_rack_upkeep_single_exchange_v1",
                "battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2",
                "8133928f03d5a5a77f2beecfcbd09e30",
            ),
            (
                {"name": "Unexpected Windfall", "cmc": 4, "type_line": "Instant"},
                "treasure_maker",
                "discard_draw_create_treasures_v1",
                "battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4",
                "9c4fbe06104051a2e8b1d295d307b26a",
            ),
            (
                {"name": "Valakut Awakening // Valakut Stoneforge", "cmc": 3, "type_line": "Instant"},
                "hand_filter",
                "bottom_then_draw_plus_one_mdfc_land_v1",
                "battle_rule_v1:6e1f3b876822abafe1de47610f46858d",
                "22b42fcc181b7aed71f78b2e1e51e887",
            ),
            (
                {"name": "Wayfarer's Bauble", "cmc": 1, "type_line": "Artifact"},
                "ramp_permanent",
                "self_sacrifice_basic_land_tutor_artifact_v1",
                "battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab",
                "f11935fa793ae03d95ae75d62cdfa516",
            ),
        ]

        for card, effect, scope, logical_key, oracle_hash in cases:
            rule = battle.get_card_effect(card)
            assert rule["effect"] == effect
            assert rule["battle_model_scope"] == scope
            assert rule["_rule_logical_key"] == logical_key
            assert rule["_rule_oracle_hash"] == oracle_hash
            assert rule["_rule_execution_status"] == "auto"

    def test_pg094_deck6_606_l2_hash_restore_rules_resolve_from_sqlite_cache():
        cases = [
            (
                {"name": "Fellwar Stone", "cmc": 2, "type_line": "Artifact"},
                "ramp_permanent",
                "conditional_opponent_color_mana_rock_v1",
                "battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba",
                "d63befc8ac40d9a38732f9b5c1a7414a",
            ),
            (
                {"name": "Library of Leng", "cmc": 1, "type_line": "Artifact"},
                "passive",
                "discard_replacement_to_top_v1",
                "battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3",
                "575aef3cc2523831e440ea7dcd55fa6e",
            ),
            (
                {"name": "Mana Vault", "cmc": 1, "type_line": "Artifact"},
                "ramp_permanent",
                "fast_mana_artifact_partial_v1",
                "battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff",
                "35e3fd94c8453c0e326033af49ae18c8",
            ),
            (
                {"name": "Mox Amber", "cmc": 0, "type_line": "Legendary Artifact"},
                "ramp_permanent",
                "legend_gated_fast_mana_v1",
                "battle_rule_v1:972703914ee50acd7a4e6f529fea1adf",
                "e47b40cf2afc4c9ceac6bf91815da706",
            ),
            (
                {"name": "Scroll Rack", "cmc": 2, "type_line": "Artifact"},
                "topdeck_manipulation",
                "scroll_rack_upkeep_single_exchange_v1",
                "battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2",
                "8133928f03d5a5a77f2beecfcbd09e30",
            ),
            (
                {"name": "Seething Song", "cmc": 3, "type_line": "Instant"},
                "ramp_ritual",
                "single_shot_red_ritual_v1",
                "battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7",
                "ccd492289c6f1c14c8fb7a248d7bbf32",
            ),
            (
                {"name": "Silence", "cmc": 1, "type_line": "Instant"},
                "silence_spell",
                "silence_until_eot_v1",
                "battle_rule_v1:74b210b77b004a677906e0216d44e445",
                "a0ca3c09a7db091c435ab31adb9c1780",
            ),
            (
                {"name": "Talisman of Conviction", "cmc": 2, "type_line": "Artifact"},
                "ramp_permanent",
                "pain_talisman_color_pair_partial_v1",
                "battle_rule_v1:02133e513da5ea98ac74d32d39b16470",
                "d49ceec937367a344a9f0948eea4f8f2",
            ),
            (
                {"name": "Unexpected Windfall", "cmc": 4, "type_line": "Instant"},
                "treasure_maker",
                "discard_draw_create_treasures_v1",
                "battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4",
                "9c4fbe06104051a2e8b1d295d307b26a",
            ),
            (
                {"name": "Valakut Awakening // Valakut Stoneforge", "cmc": 3, "type_line": "Instant"},
                "hand_filter",
                "bottom_then_draw_plus_one_mdfc_land_v1",
                "battle_rule_v1:6e1f3b876822abafe1de47610f46858d",
                "22b42fcc181b7aed71f78b2e1e51e887",
            ),
            (
                {"name": "Wayfarer's Bauble", "cmc": 1, "type_line": "Artifact"},
                "ramp_permanent",
                "self_sacrifice_basic_land_tutor_artifact_v1",
                "battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab",
                "f11935fa793ae03d95ae75d62cdfa516",
            ),
        ]

        for card, effect, scope, logical_key, oracle_hash in cases:
            rule = battle.get_card_effect(card)
            assert rule["effect"] == effect
            assert rule["battle_model_scope"] == scope
            assert rule["_rule_logical_key"] == logical_key
            assert rule["_rule_oracle_hash"] == oracle_hash
            assert rule["_rule_execution_status"] == "auto"

    def test_samis_curiosity_creates_lander_token_not_tutor():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Korvold")
        active.life = 20
        card = {"name": "Sami's Curiosity", "cmc": 1, "type_line": "Sorcery"}

        effect = battle.get_card_effect(card)
        battle.apply_effect_immediate(active, [], card, 4, random.Random(93))
        battle.REPLAY_EVENT_HANDLER = None

        assert effect["effect"] == "lander_token_maker"
        assert effect["effect"] != "tutor"
        assert active.life == 22
        assert any(
            permanent.get("name") == "Lander Token"
            and permanent.get("lander_token") is True
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(event == "lander_token_created" for event, _ in events)

    def test_audit_promoted_cards_keep_conservative_semantics():
        miscast = battle.get_card_effect({"name": "Miscast", "type_line": "Instant"})
        steamkin = battle.get_card_effect(
            {"name": "Runaway Steam-Kin", "type_line": "Creature — Elemental"}
        )
        broodscale = battle.get_card_effect(
            {"name": "Basking Broodscale", "type_line": "Creature — Eldrazi Insect"}
        )
        ooze = battle.get_card_effect(
            {"name": "Scavenging Ooze", "type_line": "Creature — Ooze"}
        )

        assert miscast["effect"] == "counter"
        assert miscast["instant"] is True
        assert miscast["target"] == "instant_or_sorcery"
        assert steamkin["effect"] == "creature"
        assert steamkin["effect"] != "ramp_ritual"
        assert steamkin["is_creature_permanent"] is True
        assert broodscale["effect"] == "creature"
        assert broodscale["effect"] != "token_maker"
        assert broodscale["is_creature_permanent"] is True
        assert ooze["effect"] == "creature"
        assert ooze["effect"] != "remove_permanent"
        assert ooze["is_creature_permanent"] is True

    def test_snapback_return_target_creature_stays_creature_removal():
        snapback = battle.get_card_effect(
            {
                "name": "Snapback",
                "cmc": 2,
                "type_line": "Instant",
                "oracle_text": (
                    "You may exile a blue card from your hand rather than pay this "
                    "spell's mana cost. Return target creature to its owner's hand."
                ),
                "functional_tags_json": '["removal"]',
            }
        )
        rule_selection = snapback.get("_rule_runtime_selection") or {}

        assert snapback["effect"] == "remove_creature"
        assert snapback["target"] == "creature"
        assert rule_selection.get("selected_effect") == "remove_creature"

    def test_functional_tag_gate_cards_resolve_from_manual_waivers():
        mardu = battle.get_card_effect(
            {
                "name": "Mardu Devotee",
                "type_line": "Creature — Human Scout",
                "functional_tags_json": '["ramp"]',
            }
        )
        lumberjack = battle.get_card_effect(
            {
                "name": "Orcish Lumberjack",
                "type_line": "Creature — Orc",
                "functional_tags_json": '["ramp"]',
            }
        )
        mardu_fields = battle.replay_rule_fields(mardu)
        lumberjack_fields = battle.replay_rule_fields(lumberjack)

        assert mardu["effect"] == "creature"
        assert mardu["etb_scry_count"] == 2
        assert mardu["mana_filter_once_per_turn"] is True
        assert mardu_fields["rule_source"] == "manual_runtime_waiver"
        assert mardu_fields["rule_review_status"] == "verified"
        assert mardu_fields["rule_logical_key"]

        assert lumberjack["effect"] == "creature"
        assert lumberjack["is_mana_source"] is True
        assert lumberjack["mana_produced"] == 3
        assert lumberjack["requires_sacrifice_forest_for_mana"] is True
        assert lumberjack_fields["rule_source"] == "manual_runtime_waiver"
        assert lumberjack_fields["rule_review_status"] == "verified"
        assert lumberjack_fields["rule_logical_key"]

    def test_basking_broodscale_enters_as_creature_not_immediate_token_maker():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Falco")
        card = {
            "name": "Basking Broodscale",
            "cmc": 2,
            "type_line": "Creature — Eldrazi Insect",
        }

        battle.apply_effect_immediate(active, [], card, 3, random.Random(109))
        battle.REPLAY_EVENT_HANDLER = None

        assert any(
            permanent.get("name") == "Basking Broodscale"
            and permanent.get("effect") == "creature"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert not any(
            permanent.get("token_created_by") == "Basking Broodscale"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(
            event == "creature_to_battlefield"
            and data.get("card") == "Basking Broodscale"
            for event, data in events
        )
        assert not any(
            event == "token_created" and data.get("card") == "Basking Broodscale"
            for event, data in events
        )

    def test_scavenging_ooze_enters_as_creature_not_immediate_removal():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Falco")
        opponent = player("Opponent")
        target = {
            "name": "Value Creature",
            "effect": "creature",
            "type_line": "Creature",
            "power": 3,
            "toughness": 3,
        }
        opponent.battlefield = [target]
        opponent.graveyard = [
            {"name": "Dead Card", "effect": "creature", "type_line": "Creature"}
        ]
        card = {
            "name": "Scavenging Ooze",
            "cmc": 2,
            "type_line": "Creature — Ooze",
        }

        battle.apply_effect_immediate(active, [opponent], card, 4, random.Random(110))
        battle.REPLAY_EVENT_HANDLER = None

        assert any(
            permanent.get("name") == "Scavenging Ooze"
            and permanent.get("effect") == "creature"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert target in opponent.battlefield
        assert opponent.graveyard[0]["name"] == "Dead Card"
        assert any(
            event == "creature_to_battlefield"
            and data.get("card") == "Scavenging Ooze"
            for event, data in events
        )
        assert not any(
            event == "removal_resolved" and data.get("card") == "Scavenging Ooze"
            for event, data in events
        )

    def test_mox_diamond_discards_land_when_it_unlocks_commander():
        events = []
        decisions = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        previous_trace_handler = battle.DECISION_TRACE_HANDLER
        battle.DECISION_TRACE_HANDLER = decisions.append
        active = player("Active")
        opponent = player("Opponent")
        mox = {"name": "Mox Diamond", "cmc": 0, "type_line": "Artifact"}
        land = {"name": "Savannah", "effect": "land", "type_line": "Land"}
        active.hand = [mox, land]
        active.command_zone = [
            {
                "name": "Cheap Commander",
                "cmc": 1,
                "type_line": "Legendary Creature",
                "effect": "creature",
                "is_commander": True,
            }
        ]

        try:
            acted = battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                turn=1,
                phase="precombat_main",
                stack=battle.Stack(),
                rng=random.Random(39),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None
            battle.DECISION_TRACE_HANDLER = previous_trace_handler

        assert acted is True
        assert mox not in active.hand
        assert land not in active.hand
        assert any(
            permanent.get("name") == "Mox Diamond"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(card.get("name") == "Savannah" for card in active.graveyard)
        mox_cost_event = next(
            data
            for event, data in events
            if event == "additional_cost_paid"
            and data.get("card") == "Mox Diamond"
            and data.get("cost") == "discard_land"
            and data.get("discarded") == "Savannah"
        )
        assert mox_cost_event["unlock_card"] == "Cheap Commander"
        assert mox_cost_event["unlock_role"] == "commander"
        assert mox_cost_event["unlock_reason"] == "same_turn_commander_cast"
        assert mox_cost_event["unlocks_same_turn_action"] is True
        trace = next(
            trace
            for trace in decisions
            if trace["decision_type"] == "cast_spell"
            and trace["chosen_option"].get("card") == "Mox Diamond"
        )
        assert trace["expected_payoff_reason"] == "same_turn_commander_cast"
        assert "spending_last_land" in trace["risk_flags"]
        assert trace["resource_delta"]["resource_land"] == "Savannah"
        assert trace["resource_delta"]["unlock_card"] == "Cheap Commander"
        assert trace["resource_delta"]["unlock_role"] == "commander"

    def test_mox_diamond_does_not_spend_last_land_without_payoff():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        mox = {"name": "Mox Diamond", "cmc": 0, "type_line": "Artifact"}
        land = {"name": "Savannah", "effect": "land", "type_line": "Land"}
        expensive = {
            "name": "Nine Mana Filler",
            "cmc": 9,
            "type_line": "Sorcery",
            "effect": "draw_cards",
        }
        active.hand = [mox, land, expensive]

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(40),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is False
        assert mox in active.hand
        assert land in active.hand
        assert active.graveyard == []
        assert not any(
            event == "additional_cost_paid"
            and data.get("card") == "Mox Diamond"
            for event, data in events
        )

    def test_mox_diamond_does_not_claim_unaffordable_commander_payoff():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        mox = {"name": "Mox Diamond", "cmc": 0, "type_line": "Artifact"}
        land = {"name": "Command Tower", "effect": "land", "type_line": "Land"}
        active.hand = [mox, land]
        active.battlefield = [
            {
                "name": "Wastes",
                "effect": "land",
                "type_line": "Land",
                "mana_produced": 1,
                "color_identity": ["C"],
            }
        ]
        active.command_zone = [
            {
                "name": "Four Mana Commander",
                "cmc": 0,
                "mana_cost": "{2}",
                "type_line": "Legendary Creature",
                "effect": "creature",
                "is_commander": True,
            }
        ]
        active.commander_tax = 2
        active.refresh_mana_sources(turn=1)

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(41),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is False
        assert mox in active.hand
        assert land in active.hand
        assert not any(
            event == "additional_cost_paid"
            and data.get("card") == "Mox Diamond"
            for event, data in events
        )

    def test_chrome_mox_imprints_colored_nonartifact_nonland_card():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        mox = {"name": "Chrome Mox", "cmc": 0, "type_line": "Artifact"}
        imprint_card = {
            "name": "Red Filler",
            "cmc": 5,
            "type_line": "Sorcery",
            "effect": "draw_cards",
            "color_identity": ["R"],
        }
        active.hand = [mox, imprint_card]
        active.command_zone = [
            {
                "name": "Cheap Commander",
                "cmc": 1,
                "type_line": "Legendary Creature",
                "effect": "creature",
                "is_commander": True,
            }
        ]

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(42),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is True
        assert mox not in active.hand
        assert imprint_card not in active.hand
        assert any(card.get("name") == "Red Filler" for card in active.exile)
        assert any(
            permanent.get("name") == "Chrome Mox"
            and permanent.get("imprinted_card") == "Red Filler"
            and permanent.get("mana_produced") == 1
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(
            event == "imprint_resolved"
            and data.get("card") == "Chrome Mox"
            and data.get("imprinted") == "Red Filler"
            for event, data in events
        )

    def test_chrome_mox_does_not_cast_without_valid_imprint():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        mox = {"name": "Chrome Mox", "cmc": 0, "type_line": "Artifact"}
        artifact = {"name": "Sol Ring", "cmc": 1, "type_line": "Artifact"}
        land = {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"}
        active.hand = [mox, artifact, land]

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(43),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is False
        assert mox in active.hand
        assert not any(event == "imprint_resolved" for event, _ in events)
        assert not any(
            permanent.get("name") == "Chrome Mox"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )

    def test_everflowing_chalice_pays_multikicker_before_becoming_mana_source():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        chalice = {"name": "Everflowing Chalice", "cmc": 0, "type_line": "Artifact"}
        active.hand = [chalice]
        active.battlefield = ["land", "land"]
        active.refresh_mana_sources(turn=1)

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(44),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is True
        assert chalice not in active.hand
        assert any(
            permanent.get("name") == "Everflowing Chalice"
            and permanent.get("charge_counters") == 1
            and permanent.get("mana_produced") == 1
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(
            event == "multikicker_paid"
            and data.get("card") == "Everflowing Chalice"
            and data.get("kicker_count") == 1
            for event, data in events
        )
        assert any(
            event == "cast_announced"
            and data.get("card") == "Everflowing Chalice"
            and data.get("additional_costs") == ["{2}"]
            for event, data in events
        )

    def test_everflowing_chalice_does_not_cast_as_zero_mana_ramp():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        chalice = {"name": "Everflowing Chalice", "cmc": 0, "type_line": "Artifact"}
        active.hand = [chalice]

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(45),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is False
        assert chalice in active.hand
        assert not any(event == "multikicker_paid" for event, _ in events)
        assert not any(
            permanent.get("name") == "Everflowing Chalice"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )

    def test_lightning_greaves_grants_haste_and_shroud_without_indestructible():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        target = {
            "name": "Target Creature",
            "effect": "creature",
            "type_line": "Creature",
            "power": 3,
            "toughness": 3,
            "summoning_sick": True,
        }
        active.battlefield = [target]
        effect_data = battle.get_card_effect(
            {"name": "Lightning Greaves", "cmc": 2, "type_line": "Artifact — Equipment"}
        )

        assert effect_data.get("effect") == "equipment_haste_shroud"
        assert effect_data.get("_rule_logical_key") == "battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac"

        battle.apply_effect_immediate(
            active,
            [],
            {"name": "Lightning Greaves", "cmc": 2, "type_line": "Artifact — Equipment"},
            3,
            random.Random(46),
            effect_data_override=effect_data,
        )

        assert any(
            permanent.get("name") == "Lightning Greaves"
            and permanent.get("effect") == "equipment_haste_shroud"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert target.get("haste") is True
        assert target.get("shroud") is True
        assert target.get("summoning_sick") is False
        assert target.get("indestructible") is not True
        attached_events = [
            data
            for event, data in events
            if event == "equipment_attached"
        ]
        assert attached_events
        assert attached_events[-1]["rule_logical_key"] == "battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac"
        assert attached_events[-1]["rule_oracle_hash"] == "4a4c71d3cc58637cf00a3d7fe2331353"

    def test_static_equipment_applies_boost_and_keywords_to_best_creature():
        active = player("Active")
        target = {
            "name": "Legendary Target",
            "effect": "creature",
            "type_line": "Legendary Creature",
            "power": 3,
            "toughness": 3,
            "summoning_sick": True,
        }
        active.battlefield = [target]

        battle.apply_effect_immediate(
            active,
            [],
            {"name": "Mithril Coat", "cmc": 3, "type_line": "Legendary Artifact — Equipment"},
            4,
            random.Random(1161),
            effect_data_override={
                "effect": "equipment_static_attachment",
                "grants_indestructible": True,
                "battle_model_scope": "test_static_equipment_attachment",
            },
        )

        assert any(
            permanent.get("name") == "Mithril Coat"
            and permanent.get("effect") == "equipment_static_attachment"
            and permanent.get("attached_to") == "Legendary Target"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert target.get("indestructible") is True

    def test_artifact_etb_tutors_two_basic_plains_to_hand_and_stays_on_battlefield():
        active = player("Active")
        active.library = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains", "effect": "land"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain", "effect": "land"},
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains", "effect": "land"},
        ]

        battle.apply_effect_immediate(
            active,
            [],
            {"name": "Archaeomancer's Map", "cmc": 3, "type_line": "Artifact"},
            3,
            random.Random(1162),
            effect_data_override={
                "effect": "ramp_engine",
                "trigger": "opponent_land_play",
                "etb_tutor_target": "basic_plains",
                "etb_tutor_count": 2,
                "battle_model_scope": "test_basic_plains_etb_tutor",
            },
        )

        assert [card.get("name") for card in active.hand].count("Plains") == 2
        assert [card.get("name") for card in active.library] == ["Mountain"]
        assert any(
            permanent.get("name") == "Archaeomancer's Map"
            and permanent.get("effect") == "ramp_engine"
            and permanent.get("trigger") == "opponent_land_play"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )

    def test_archaeomancers_map_opponent_land_trigger_requires_controller_behind_on_lands():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active Land Player")
            controller = player("Map Controller")
            active.battlefield = [
                {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain", "effect": "land"},
                {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains", "effect": "land"},
                {"name": "Sacred Foundry", "cmc": 0, "type_line": "Land — Mountain Plains", "effect": "land"},
            ]
            controller.battlefield = [
                {
                    "name": "Archaeomancer's Map",
                    "cmc": 3,
                    "type_line": "Artifact",
                    "effect": "ramp_engine",
                    "trigger": "opponent_land_play",
                    "_rule_logical_key": "battle_rule_v1:archaeomancers-map-test",
                    "_rule_oracle_hash": "22b82ca6bbef42371227bc38a9a546b5",
                },
                {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains", "effect": "land"},
            ]
            controller.hand = [
                {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain", "effect": "land"},
            ]
            trigger_land = {"name": "Command Tower", "cmc": 0, "type_line": "Land", "effect": "land"}

            battle.trigger_opponent_land_play_engines(active, [controller], trigger_land, 4)
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert not controller.hand
        assert any(
            permanent.get("name") == "Mountain"
            for permanent in controller.battlefield
            if isinstance(permanent, dict)
        )
        resolved = [
            data
            for event, data in events
            if event == "trigger_resolved"
            and data.get("card") == "Archaeomancer's Map"
            and data.get("trigger") == "opponent_land_play"
        ]
        assert len(resolved) == 1
        assert resolved[0]["active_player_land_count"] == 3
        assert resolved[0]["controller_land_count"] == 1
        assert resolved[0]["rule_logical_key"] == "battle_rule_v1:archaeomancers-map-test"
        assert resolved[0]["rule_oracle_hash"] == "22b82ca6bbef42371227bc38a9a546b5"

    def test_archaeomancers_map_opponent_land_trigger_skips_when_controller_not_behind():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active Land Player")
            controller = player("Map Controller")
            active.battlefield = [
                {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain", "effect": "land"},
            ]
            controller.battlefield = [
                {
                    "name": "Archaeomancer's Map",
                    "cmc": 3,
                    "type_line": "Artifact",
                    "effect": "ramp_engine",
                    "trigger": "opponent_land_play",
                    "_rule_logical_key": "battle_rule_v1:archaeomancers-map-test",
                    "_rule_oracle_hash": "22b82ca6bbef42371227bc38a9a546b5",
                },
                {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains", "effect": "land"},
            ]
            controller.hand = [
                {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain", "effect": "land"},
            ]
            trigger_land = {"name": "Command Tower", "cmc": 0, "type_line": "Land", "effect": "land"}

            battle.trigger_opponent_land_play_engines(active, [controller], trigger_land, 4)
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert [card.get("name") for card in controller.hand] == ["Mountain"]
        skipped = [
            data
            for event, data in events
            if event == "trigger_skipped"
            and data.get("card") == "Archaeomancer's Map"
            and data.get("trigger") == "opponent_land_play"
        ]
        assert len(skipped) == 1
        assert skipped[0]["reason"] == "opponent_does_not_control_more_lands"
        assert skipped[0]["active_player_land_count"] == 1
        assert skipped[0]["controller_land_count"] == 1
        assert skipped[0]["rule_logical_key"] == "battle_rule_v1:archaeomancers-map-test"

    def test_blind_obedience_taps_opponent_artifacts_and_creatures_on_entry():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            controller = player("Blind Controller")
            opponent = player("Opponent")
            blind_effect = {
                "effect": "passive",
                "opponents_artifacts_creatures_enter_tapped": True,
                "extort": True,
                "extort_execution_status": "annotation_only",
                "battle_model_scope": "opponent_artifact_creature_enter_tapped_extort_annotation_v1",
                "_rule_logical_key": "battle_rule_v1:blind-obedience-test",
                "_rule_oracle_hash": "4e62bff316f784c1b468b9e53146d2aa",
                "_rule_source": "curated",
                "_rule_review_status": "active",
                "_rule_execution_status": "auto",
            }
            battle.apply_effect_immediate(
                controller,
                [opponent],
                {"name": "Blind Obedience", "cmc": 2, "type_line": "Enchantment"},
                3,
                random.Random(1164),
                effect_data_override=blind_effect,
            )
            battle.apply_effect_immediate(
                opponent,
                [controller],
                {"name": "Opponent Bear", "cmc": 2, "type_line": "Creature — Bear"},
                3,
                random.Random(1165),
                effect_data_override={
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                    "battle_model_scope": "test_creature_body",
                },
            )
            battle.apply_effect_immediate(
                opponent,
                [controller],
                {"name": "Opponent Rock", "cmc": 2, "type_line": "Artifact"},
                3,
                random.Random(1166),
                effect_data_override={
                    "effect": "passive",
                    "battle_model_scope": "test_artifact_body",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        blind = next(
            permanent
            for permanent in controller.battlefield
            if permanent.get("name") == "Blind Obedience"
        )
        bear = next(
            permanent
            for permanent in opponent.battlefield
            if permanent.get("name") == "Opponent Bear"
        )
        rock = next(
            permanent
            for permanent in opponent.battlefield
            if permanent.get("name") == "Opponent Rock"
        )
        assert not blind.get("tapped")
        assert bear.get("tapped") is True
        assert rock.get("tapped") is True
        tapped_events = [
            data
            for event, data in events
            if event == "static_enter_tapped_applied"
            and data.get("source_card") == "Blind Obedience"
        ]
        assert {event.get("card") for event in tapped_events} == {
            "Opponent Bear",
            "Opponent Rock",
        }
        assert {
            event.get("rule_logical_key")
            for event in tapped_events
        } == {"battle_rule_v1:blind-obedience-test"}
        assert {
            event.get("rule_oracle_hash")
            for event in tapped_events
        } == {"4e62bff316f784c1b468b9e53146d2aa"}

    def test_land_tax_tutors_three_basic_lands_when_opponent_has_more_lands():
        events = []
        decisions = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
        active = player("Active")
        opponent = player("Opponent")
        active.battlefield = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains", "effect": "land"},
        ]
        opponent.battlefield = [
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain", "effect": "land"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain", "effect": "land"},
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains", "effect": "land"},
        ]
        active.library = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains", "effect": "land"},
            {"name": "Command Tower", "cmc": 0, "type_line": "Land", "effect": "land"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain", "effect": "land"},
            {"name": "Island", "cmc": 0, "type_line": "Basic Land — Island", "effect": "land"},
        ]
        land_tax = {"name": "Land Tax", "cmc": 1, "type_line": "Enchantment"}
        effect_data = battle.get_card_effect(land_tax)

        assert effect_data.get("effect") == "land_tax"
        assert effect_data.get("_rule_logical_key") == "battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef"

        battle.apply_effect_immediate(
            active,
            [opponent],
            land_tax,
            2,
            random.Random(1164),
            effect_data_override=effect_data,
        )
        triggers = battle.process_upkeep_utility_lands(
            active,
            3,
            all_players=[active, opponent],
        )

        assert triggers == 3
        assert sorted(card.get("name") for card in active.hand) == ["Island", "Mountain", "Plains"]
        assert [card.get("name") for card in active.library] == ["Command Tower"]
        resolved = [
            data
            for event, data in events
            if event == "land_tax_trigger_resolved"
        ]
        assert resolved
        assert resolved[-1]["found_count"] == 3
        assert resolved[-1]["destination"] == "hand"
        assert resolved[-1]["rule_logical_key"] == "battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef"
        assert resolved[-1]["rule_oracle_hash"] == "83b074e38da3e6c4eb6ec3e7568c914b"
        trace = next(
            decision
            for decision in decisions
            if decision.get("decision_type") == "land_tax_upkeep_tutor"
            and decision.get("chosen_option", {}).get("found_cards") == ["Island", "Mountain", "Plains"]
        )
        assert trace["best_rejected_option_score"] is not None
        assert trace["score_gap_vs_best_rejected"] is not None
        assert trace["rejected_options"][-1]["action"] == "decline_optional_tutor"

    def test_land_tax_skips_when_no_opponent_controls_more_lands():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        active.battlefield = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains", "effect": "land"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain", "effect": "land"},
        ]
        opponent.battlefield = [
            {"name": "Island", "cmc": 0, "type_line": "Basic Land — Island", "effect": "land"},
            {"name": "Swamp", "cmc": 0, "type_line": "Basic Land — Swamp", "effect": "land"},
        ]
        active.library = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains", "effect": "land"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain", "effect": "land"},
        ]
        land_tax = {"name": "Land Tax", "cmc": 1, "type_line": "Enchantment"}
        effect_data = battle.get_card_effect(land_tax)

        battle.apply_effect_immediate(
            active,
            [opponent],
            land_tax,
            2,
            random.Random(1165),
            effect_data_override=effect_data,
        )
        triggers = battle.process_upkeep_utility_lands(
            active,
            3,
            all_players=[active, opponent],
        )

        assert triggers == 0
        assert active.hand == []
        assert [card.get("name") for card in active.library] == ["Plains", "Mountain"]
        assert not any(event == "land_tax_trigger_resolved" for event, _ in events)
        skipped = [
            data
            for event, data in events
            if event == "land_tax_trigger_skipped"
        ]
        assert skipped
        assert skipped[-1]["condition_met"] is False
        assert skipped[-1]["rule_logical_key"] == "battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef"

    def test_instant_copy_spell_does_not_become_permanent_engine_without_stack_target():
        active = player("Active")
        battle.apply_effect_immediate(
            active,
            [],
            {"name": "Increasing Vengeance", "cmc": 2, "type_line": "Instant"},
            4,
            random.Random(1163),
            effect_data_override={
                "effect": "copy_spell",
                "instant": True,
                "battle_model_scope": "test_copy_spell_requires_stack_target",
            },
        )

        assert not any(
            permanent.get("name") == "Increasing Vengeance"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(card.get("name") == "Increasing Vengeance" for card in active.graveyard)

    def test_unexpected_windfall_discards_draws_two_creates_two_treasures_with_pg069_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            active.hand = [
                {"name": "Unexpected Windfall", "cmc": 4, "mana_cost": "{2}{R}{R}", "type_line": "Instant"},
                {"name": "Discard Me", "cmc": 7, "type_line": "Sorcery", "effect": "draw_cards"},
            ]
            active.library = [
                {"name": "Drawn One", "cmc": 1, "type_line": "Sorcery"},
                {"name": "Drawn Two", "cmc": 1, "type_line": "Sorcery"},
            ]
            windfall = active.hand[0]
            effect_data = battle.get_card_effect(windfall)

            assert effect_data["effect"] == "treasure_maker"
            assert effect_data["draw_count"] == 2
            assert effect_data["treasure_count"] == 2
            assert effect_data["requires_discard_card"] is True
            assert effect_data["battle_model_scope"] == "discard_draw_create_treasures_v1"
            assert effect_data["_rule_logical_key"] == "battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4"
            assert effect_data["_rule_oracle_hash"] == "9c4fbe06104051a2e8b1d295d307b26a"

            active.hand.remove(windfall)
            battle.apply_effect_immediate(
                active,
                [],
                windfall,
                5,
                random.Random(1166),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert active.treasures == 2
        assert [card.get("name") for card in active.hand] == ["Drawn One", "Drawn Two"]
        assert any(card.get("name") == "Discard Me" for card in active.graveyard)
        assert any(card.get("name") == "Unexpected Windfall" for card in active.graveyard)
        assert any(
            event == "additional_cost_paid"
            and data.get("card") == "Unexpected Windfall"
            and data.get("cost") == "discard_card"
            and data.get("discarded") == "Discard Me"
            for event, data in events
        )
        treasure_event = next(
            data
            for event, data in events
            if event == "treasure_created" and data.get("card") == "Unexpected Windfall"
        )
        assert treasure_event["treasures_created"] == 2
        assert treasure_event["cards_drawn"] == 2
        assert treasure_event["rule_logical_key"] == "battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4"
        assert treasure_event["rule_oracle_hash"] == "9c4fbe06104051a2e8b1d295d307b26a"

    def test_strike_it_rich_creates_one_treasure_from_reviewed_runtime_rule(self):
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            strike = {"name": "Strike It Rich", "cmc": 1, "mana_cost": "{R}", "type_line": "Sorcery"}
            effect_data = battle.get_card_effect(strike)

            assert effect_data["effect"] == "treasure_maker"
            assert effect_data["treasure_count"] == 1

            battle.apply_effect_immediate(
                active,
                [],
                strike,
                3,
                random.Random(1167),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert active.treasures == 1
        treasure_event = next(
            data
            for event, data in events
            if event == "treasure_created" and data.get("card") == "Strike It Rich"
        )
        assert treasure_event["treasures_created"] == 1
        assert treasure_event["cards_drawn"] == 0
        assert treasure_event["rule_logical_key"] == "battle_rule_v1:c7150bc991226fde4b186bf65bd1e9ec"

    def test_pirates_pillage_discards_draws_two_and_creates_two_treasures(self):
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            active.hand = [
                {"name": "Pirate's Pillage", "cmc": 4, "mana_cost": "{3}{R}", "type_line": "Sorcery"},
                {"name": "Discard Me", "cmc": 6, "type_line": "Sorcery", "effect": "draw_cards"},
            ]
            active.library = [
                {"name": "Drawn One", "cmc": 1, "type_line": "Sorcery"},
                {"name": "Drawn Two", "cmc": 1, "type_line": "Sorcery"},
            ]
            pillage = active.hand[0]
            effect_data = battle.get_card_effect(pillage)

            assert effect_data["effect"] == "treasure_maker"
            assert effect_data["draw_count"] == 2
            assert effect_data["treasure_count"] == 2
            assert effect_data["requires_discard_card"] is True
            assert effect_data["battle_model_scope"] == "discard_draw_two_create_two_treasures_v1"
            assert effect_data["_rule_oracle_hash"] == "9c4fbe06104051a2e8b1d295d307b26a"

            active.hand.remove(pillage)
            battle.apply_effect_immediate(
                active,
                [],
                pillage,
                5,
                random.Random(1168),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert active.treasures == 2
        assert [card.get("name") for card in active.hand] == ["Drawn One", "Drawn Two"]
        assert any(card.get("name") == "Discard Me" for card in active.graveyard)
        treasure_event = next(
            data
            for event, data in events
            if event == "treasure_created" and data.get("card") == "Pirate's Pillage"
        )
        assert treasure_event["treasures_created"] == 2
        assert treasure_event["cards_drawn"] == 2

    def test_pg070_faithless_looting_draws_two_discards_two_with_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            looting = {"name": "Faithless Looting", "cmc": 1, "type_line": "Sorcery"}
            active.hand = [
                looting,
                {"name": "Discard Candidate A", "cmc": 6, "type_line": "Sorcery", "effect": "draw_cards"},
                {"name": "Discard Candidate B", "cmc": 5, "type_line": "Sorcery", "effect": "draw_cards"},
            ]
            active.library = [
                {"name": "Drawn One", "cmc": 1, "type_line": "Sorcery"},
                {"name": "Drawn Two", "cmc": 1, "type_line": "Sorcery"},
            ]
            effect_data = battle.get_card_effect(looting)

            assert effect_data["effect"] == "loot"
            assert effect_data["count"] == 2
            assert effect_data["battle_model_scope"] == "draw_two_discard_two_flashback_annotation_v1"
            assert effect_data["_rule_logical_key"] == "battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa"
            assert effect_data["_rule_oracle_hash"] == "2e734d8bae3f331866abf1b030c92781"

            active.hand.remove(looting)
            battle.apply_effect_immediate(
                active,
                [],
                looting,
                3,
                random.Random(7070),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        loot_event = next(
            data
            for event, data in events
            if event == "loot_resolved" and data.get("card") == "Faithless Looting"
        )
        assert loot_event["cards_drawn"] == ["Drawn One", "Drawn Two"]
        assert len(loot_event["discarded_to_graveyard"]) == 2
        assert loot_event["rule_logical_key"] == "battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa"
        assert loot_event["rule_oracle_hash"] == "2e734d8bae3f331866abf1b030c92781"
        assert any(card.get("name") == "Faithless Looting" for card in active.graveyard)
        assert len([card for card in active.graveyard if isinstance(card, dict)]) == 3
        assert len(active.hand) == 2

    def test_pg070_gamble_tutors_then_randomly_discards_with_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            gamble = {"name": "Gamble", "cmc": 1, "type_line": "Sorcery"}
            tutored = {
                "name": "Tutored Wincon",
                "cmc": 7,
                "type_line": "Sorcery",
                "effect": "draw_cards",
            }
            active.hand = [
                gamble,
                {"name": "Keep A", "cmc": 2, "type_line": "Instant", "effect": "remove_creature"},
                {"name": "Keep B", "cmc": 2, "type_line": "Instant", "effect": "counter"},
            ]
            active.library = [tutored]
            effect_data = battle.get_card_effect(gamble)

            assert effect_data["effect"] == "tutor"
            assert effect_data["target"] == "any"
            assert effect_data["discard_after_tutor_random"] is True
            assert effect_data["battle_model_scope"] == "any_card_to_hand_then_random_discard_v1"
            assert effect_data["_rule_logical_key"] == "battle_rule_v1:2861739f22e978549e28d2339288df2a"
            assert effect_data["_rule_oracle_hash"] == "9b3fc8ab7f664f6c084e0bda0ccf9a7c"

            active.hand.remove(gamble)
            battle.apply_effect_immediate(
                active,
                [],
                gamble,
                3,
                random.Random(7071),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        tutor_event = next(
            data
            for event, data in events
            if event == "tutor_resolved" and data.get("card") == "Gamble"
        )
        discard_event = next(
            data
            for event, data in events
            if event == "random_discard_after_tutor" and data.get("card") == "Gamble"
        )
        assert tutor_event["found"] == "Tutored Wincon"
        assert tutor_event["destination"] == "hand"
        assert tutor_event["rule_logical_key"] == "battle_rule_v1:2861739f22e978549e28d2339288df2a"
        assert discard_event["discarded"] in {"Keep A", "Keep B", "Tutored Wincon"}
        assert discard_event["rule_logical_key"] == "battle_rule_v1:2861739f22e978549e28d2339288df2a"
        assert discard_event["rule_oracle_hash"] == "9b3fc8ab7f664f6c084e0bda0ccf9a7c"
        assert any(card.get("name") == "Gamble" for card in active.graveyard)
        assert not active.library
        assert len(active.hand) == 2

    def test_pg071_lotus_petal_is_one_shot_fast_mana_with_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            lotus = {"name": "Lotus Petal", "cmc": 0, "type_line": "Artifact"}
            active.hand = [lotus]
            effect_data = battle.get_card_effect(lotus)

            assert effect_data["effect"] == "ramp_ritual"
            assert effect_data["mana_produced"] == 1
            assert effect_data["sacrifice_self_for_mana"] is True
            assert effect_data["battle_model_scope"] == "zero_mana_artifact_sacrifice_one_mana_one_shot_runtime_v1"
            assert effect_data["_rule_logical_key"] == "battle_rule_v1:d3366a0b9063a1af91a75a6398c1962d"
            assert effect_data["_rule_oracle_hash"] == "a5b9069217908acfd75c5704b414b035"

            active.hand.remove(lotus)
            battle.apply_effect_immediate(
                active,
                [],
                lotus,
                3,
                random.Random(7072),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        spell_event = next(
            data
            for event, data in events
            if event == "spell_resolved" and data.get("card") == "Lotus Petal"
        )
        assert spell_event["destination"] == "graveyard"
        assert spell_event["rule_logical_key"] == "battle_rule_v1:d3366a0b9063a1af91a75a6398c1962d"
        assert spell_event["rule_oracle_hash"] == "a5b9069217908acfd75c5704b414b035"
        assert active.mana_pool.total() == 1
        assert any(card.get("name") == "Lotus Petal" for card in active.graveyard)
        assert not any(card.get("name") == "Lotus Petal" for card in active.battlefield)

    def test_pg071_ruby_medallion_is_annotation_only_cost_reducer_not_mana_source():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            ruby = {"name": "Ruby Medallion", "cmc": 2, "type_line": "Artifact"}
            active.hand = [ruby]
            effect_data = battle.get_card_effect(ruby)

            assert effect_data["effect"] == "passive"
            assert effect_data["cost_reduction"] == 1
            assert effect_data["cost_reduction_color"] == "R"
            assert effect_data["cost_reduction_status"] == "annotation_only_no_dynamic_cost_executor"
            assert effect_data["dynamic_cost_executor"] is False
            assert effect_data["battle_model_scope"] == "red_spell_cost_reduction_annotation_only_v1"
            assert effect_data["_rule_logical_key"] == "battle_rule_v1:bd05ea5e0a5343c1bf8f2284d001471a"
            assert effect_data["_rule_oracle_hash"] == "52bc55846d69bacf3afba1ffa734b81e"

            active.hand.remove(ruby)
            battle.apply_effect_immediate(
                active,
                [],
                ruby,
                3,
                random.Random(7073),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        spell_event = next(
            data
            for event, data in events
            if event == "spell_resolved" and data.get("card") == "Ruby Medallion"
        )
        assert spell_event["destination"] == "battlefield"
        assert spell_event["rule_logical_key"] == "battle_rule_v1:bd05ea5e0a5343c1bf8f2284d001471a"
        assert spell_event["rule_oracle_hash"] == "52bc55846d69bacf3afba1ffa734b81e"
        ruby_permanent = next(
            card
            for card in active.battlefield
            if card.get("name") == "Ruby Medallion"
        )
        assert ruby_permanent["effect"] == "passive"
        assert not battle.is_mana_source_permanent(ruby_permanent)
        assert active.available_mana() == 0

    def test_pg072_pyroblast_counters_only_blue_stack_spell_with_rule_provenance():
        active = player("Active")
        blue_spell = {
            "name": "Blue Threat",
            "cmc": 4,
            "type_line": "Sorcery",
            "colors": ["U"],
        }
        red_spell = {
            "name": "Red Threat",
            "cmc": 4,
            "type_line": "Sorcery",
            "colors": ["R"],
        }
        pyroblast = {"name": "Pyroblast", "cmc": 1, "type_line": "Instant"}
        active.hand = [pyroblast]
        active.mana_pool.add("red", 1)
        effect_data = battle.get_card_effect(pyroblast)

        assert effect_data["effect"] == "counter"
        assert effect_data["requires_blue_target"] is True
        assert effect_data["battle_model_scope"] == "blue_spell_counter_runtime_destroy_blue_permanent_annotation_v1"
        assert effect_data["_rule_logical_key"] == "battle_rule_v1:141ff57f44bc4c229393f05f7daf667c"
        assert effect_data["_rule_oracle_hash"] == "ecf9ad1f393a664f16867aab8a6edf77"
        assert battle.counter_can_target(pyroblast, effect_data, blue_spell)
        assert not battle.counter_can_target(pyroblast, effect_data, red_spell)

        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            stack_item = battle.StackItem(
                blue_spell,
                active,
                {"effect": "draw_cards"},
            )
            counter = active.use_counterspell(
                turn=3,
                target_card=blue_spell,
                stack_item=stack_item,
                stack_depth=1,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert counter and counter["name"] == "Pyroblast"
        counter_event = next(data for event, data in events if event == "spell_countered")
        assert counter_event["counter"] == "Pyroblast"
        assert counter_event["target"] == "Blue Threat"
        assert counter_event["rule_logical_key"] == "battle_rule_v1:141ff57f44bc4c229393f05f7daf667c"
        assert counter_event["rule_oracle_hash"] == "ecf9ad1f393a664f16867aab8a6edf77"

    def test_pg086_counter_target_filter_respects_uncounterable_static_shield():
        active = player("Active")
        opponent = player("Opponent")
        counterspell = {
            "name": "Cancel",
            "cmc": 3,
            "type_line": "Instant",
            "effect": "counter",
        }
        opponent.hand = [counterspell]
        opponent.mana_pool.add("blue", 3)

        protected_spell = {"name": "Protected Spell", "cmc": 2, "type_line": "Sorcery"}
        protected_stack_item = battle.StackItem(
            protected_spell,
            active,
            {"effect": "draw_cards"},
        )
        active.battlefield = [
            {
                "name": "Hexing Squelcher",
                "type_line": "Creature",
                "effect": "creature",
                "spells_you_control_cant_be_countered": True,
            }
        ]

        assert not battle.counter_can_target(
            counterspell,
            battle.get_card_effect(counterspell),
            protected_spell,
            stack_item=protected_stack_item,
        )
        assert not opponent.counterspell_cards(
            castable_only=True,
            target_card=protected_spell,
            stack_item=protected_stack_item,
        )

        uncounterable_spell = {
            "name": "Uncounterable Threat",
            "cmc": 6,
            "type_line": "Sorcery",
            "uncounterable": True,
        }
        uncounterable_stack_item = battle.StackItem(
            uncounterable_spell,
            active,
            {"effect": "token_maker"},
        )
        assert not battle.counter_can_target(
            counterspell,
            battle.get_card_effect(counterspell),
            uncounterable_spell,
            stack_item=uncounterable_stack_item,
        )

    def test_pg086_removal_targets_filter_nontoken_and_mana_value_max():
        active = player("Active")
        opponent = player("Opponent")
        legal_target = {
            "name": "Legal Engine",
            "cmc": 4,
            "type_line": "Enchantment",
            "effect": "draw_engine",
        }
        too_large = {
            "name": "Large Engine",
            "cmc": 5,
            "type_line": "Enchantment",
            "effect": "draw_engine",
        }
        token_target = {
            "name": "Token Engine",
            "cmc": 2,
            "type_line": "Creature Token",
            "effect": "creature",
            "tag": "token",
        }
        opponent.battlefield = [too_large, token_target, legal_target]

        candidates = battle.removal_target_candidates(
            opponent,
            {
                "effect": "remove_permanent",
                "target": "nonland_permanent",
                "target_mana_value_max": 4,
                "target_nontoken": True,
            },
            controller=active,
            source={"name": "Skyclave Apparition"},
        )

        assert candidates == [legal_target]

    def test_pg072_get_lost_removes_allowed_permanent_and_creates_map_tokens():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            opponent = player("Opponent")
            get_lost = {"name": "Get Lost", "cmc": 2, "type_line": "Instant"}
            target = {
                "name": "Opponent Enchantment",
                "cmc": 3,
                "type_line": "Enchantment",
                "effect": "draw_engine",
            }
            artifact = {
                "name": "Sol Ring",
                "cmc": 1,
                "type_line": "Artifact",
                "effect": "ramp_permanent",
            }
            creature = {
                "name": "Siege Rhino",
                "cmc": 4,
                "type_line": "Creature",
                "effect": "creature",
                "power": 4,
                "toughness": 5,
            }
            planeswalker = {
                "name": "Jace, the Mind Sculptor",
                "cmc": 4,
                "type_line": "Legendary Planeswalker - Jace",
                "effect": "planeswalker",
            }
            opponent.battlefield = [artifact, target]
            active.hand = [get_lost]
            effect_data = battle.get_card_effect(get_lost)

            assert effect_data["effect"] == "remove_permanent"
            assert effect_data["target"] == "creature_enchantment_or_planeswalker"
            assert effect_data["map_tokens_created"] == 2
            assert effect_data["battle_model_scope"] == "destroy_creature_enchantment_planeswalker_create_two_map_tokens_v1"
            assert effect_data["_rule_logical_key"] == "battle_rule_v1:8e7da3df51386d58c857a596433f73ea"
            assert effect_data["_rule_oracle_hash"] == "6b6517e1b5b60db5cf6bbcd991dbc1ec"
            target_type = effect_data["target"]
            assert battle.target_matches_type(creature, target_type)
            assert battle.target_matches_type(target, target_type)
            assert battle.target_matches_type(planeswalker, target_type)
            assert not battle.target_matches_type(artifact, target_type)

            active.hand.remove(get_lost)
            battle.apply_effect_immediate(
                active,
                [opponent],
                get_lost,
                3,
                random.Random(7074),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        removal_event = next(
            data
            for event, data in events
            if event == "removal_resolved" and data.get("card") == "Get Lost"
        )
        token_event = next(
            data
            for event, data in events
            if event == "compensation_tokens_created" and data.get("source") == "Get Lost"
        )
        assert removal_event["target"] == "Opponent Enchantment"
        assert removal_event["target_type"] == "creature_enchantment_or_planeswalker"
        assert removal_event["target_controller_map_tokens"] == 2
        assert removal_event["rule_logical_key"] == "battle_rule_v1:8e7da3df51386d58c857a596433f73ea"
        assert removal_event["rule_oracle_hash"] == "6b6517e1b5b60db5cf6bbcd991dbc1ec"
        assert token_event["tokens_created"] == 2
        assert token_event["player"] == "Opponent"
        assert token_event["target_controller_map_tokens"] == 2
        assert token_event["rule_logical_key"] == "battle_rule_v1:8e7da3df51386d58c857a596433f73ea"
        assert sum(1 for card in opponent.battlefield if card.get("map_token")) == 2
        assert any(card.get("name") == "Sol Ring" for card in opponent.battlefield)
        assert any(card.get("name") == "Opponent Enchantment" for card in opponent.graveyard)

    def test_pg076_chaos_warp_shuffles_target_into_library_and_reveals_top_permanent():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            opponent = player("Opponent")
            chaos_warp = {"name": "Chaos Warp", "cmc": 3, "type_line": "Instant"}
            target = {
                "name": "Beast Token",
                "cmc": 0,
                "type_line": "Creature Token",
                "effect": "creature",
                "token": True,
                "power": 3,
                "toughness": 3,
            }
            revealed_permanent = {
                "name": "Replacement Rock",
                "cmc": 2,
                "type_line": "Artifact",
                "effect": "ramp_permanent",
            }
            opponent.battlefield = [target]
            opponent.library = [revealed_permanent]
            active.hand = [chaos_warp]
            effect_data = battle.get_card_effect(chaos_warp)

            assert effect_data["effect"] == "remove_permanent"
            assert effect_data["target"] == "permanent"
            assert effect_data["destination"] == "library"
            assert effect_data["top_reveal_after_shuffle"] is True
            assert effect_data["battle_model_scope"] == "target_permanent_shuffle_into_owner_library_reveal_top_permanent_to_battlefield_v1"
            assert effect_data["_rule_logical_key"] == "battle_rule_v1:0b547d7209a38ac2d23a1cca07917680"
            assert effect_data["_rule_oracle_hash"] == "7db2bc44526b855fd22302e9569746b5"
            assert battle.target_matches_type(target, effect_data["target"])

            active.hand.remove(chaos_warp)
            battle.apply_effect_immediate(
                active,
                [opponent],
                chaos_warp,
                4,
                random.Random(76076),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        removal_event = next(
            data
            for event, data in events
            if event == "removal_resolved" and data.get("card") == "Chaos Warp"
        )
        reveal_event = next(
            data
            for event, data in events
            if event == "chaos_warp_reveal_resolved"
        )
        assert removal_event["target"] == "Beast Token"
        assert removal_event["destination"] == "library"
        assert removal_event["target_type"] == "permanent"
        assert removal_event["rule_logical_key"] == "battle_rule_v1:0b547d7209a38ac2d23a1cca07917680"
        assert removal_event["rule_oracle_hash"] == "7db2bc44526b855fd22302e9569746b5"
        assert reveal_event["target_vanished"] is True
        assert reveal_event["revealed_card"] == "Replacement Rock"
        assert reveal_event["revealed_is_permanent"] is True
        assert reveal_event["put_onto_battlefield"] is True
        assert any(card.get("name") == "Replacement Rock" for card in opponent.battlefield)
        assert not any(card.get("name") == "Beast Token" for card in opponent.battlefield)
        assert opponent.library == []

    def test_pg077_jeskas_will_uses_opponent_hand_and_impulse_exiles_top_three():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            opponent = player("Opponent")
            jeska = {"name": "Jeska's Will", "cmc": 3, "type_line": "Sorcery"}
            active.battlefield = [
                {"name": "Lorehold, the Historian", "effect": "creature", "is_commander": True}
            ]
            active.library = [
                _card("Impulse One", cmc=1, effect="draw"),
                _card("Impulse Two", cmc=2, effect="draw"),
                _card("Impulse Three", cmc=3, effect="draw"),
                _card("Library Remainder", cmc=4, effect="draw"),
            ]
            opponent.hand = [_card(f"Opp Card {index}", cmc=1) for index in range(5)]
            effect_data = battle.get_card_effect(jeska)

            assert effect_data["effect"] == "ramp_ritual"
            assert effect_data["mana_produced_from_target_opponent_hand_size"] is True
            assert effect_data["impulse_exile_top_count"] == 3
            assert effect_data["produces"] == "R"
            assert effect_data["battle_model_scope"] == (
                "choose_both_with_commander_red_by_target_opponent_hand_impulse_top_three_v1"
            )
            assert effect_data["_rule_logical_key"] == "battle_rule_v1:c8621a807cc65adc820a8b8189979f70"
            assert effect_data["_rule_oracle_hash"] == "e323893e6c38ee2d618b4f9c737fadee"

            battle.apply_effect_immediate(
                active,
                [opponent],
                jeska,
                5,
                random.Random(77077),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        event = next(
            data
            for event, data in events
            if event == "jeskas_will_resolved"
        )
        assert event["selected_modes"] == ["add_red_mana", "impulse_exile"]
        assert event["target_opponent_hand_size"] == 5
        assert event["red_mana_added"] == 5
        assert event["impulse_exiled"] == ["Impulse One", "Impulse Two", "Impulse Three"]
        assert event["rule_logical_key"] == "battle_rule_v1:c8621a807cc65adc820a8b8189979f70"
        assert event["rule_oracle_hash"] == "e323893e6c38ee2d618b4f9c737fadee"
        assert active.mana_pool.red == 5
        assert [card.get("name") for card in active.exile] == [
            "Impulse One",
            "Impulse Two",
            "Impulse Three",
        ]
        assert active.library[0]["name"] == "Library Remainder"
        assert any(card.get("name") == "Jeska's Will" for card in active.graveyard)

    def test_pg077_mizzixs_mastery_exiles_graveyard_spell_and_resolves_copy():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            opponent = player("Opponent")
            mizzix = {"name": "Mizzix's Mastery", "cmc": 4, "type_line": "Sorcery"}
            grave_spell = {"name": "Refill Spell", "cmc": 2, "type_line": "Sorcery", "effect": "draw"}
            active.graveyard = [grave_spell]
            active.library = [_card("Drawn One", cmc=1), _card("Drawn Two", cmc=1)]
            effect_data = battle.get_card_effect(mizzix)

            assert effect_data["effect"] == "overload_recursion"
            assert effect_data["target"] == "instant_or_sorcery_graveyard"
            assert effect_data["exiles_self"] is True
            assert effect_data["casts_copies_without_paying_mana"] is True
            assert effect_data["battle_model_scope"] == (
                "target_or_overload_graveyard_instant_sorcery_copy_cast_runtime_v1"
            )
            assert effect_data["_rule_logical_key"] == "battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f"
            assert effect_data["_rule_oracle_hash"] == "8b822f0c58e4ab4e91f9e4946e8c04e9"

            battle.apply_effect_immediate(
                active,
                [opponent],
                mizzix,
                6,
                random.Random(77078),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        mastery_event = next(
            data
            for event, data in events
            if event == "mizzix_mastery_resolved"
        )
        copy_event = next(
            data
            for event, data in events
            if event == "mizzix_mastery_copy_cast"
        )
        copy_resolution = next(
            data
            for event, data in events
            if event == "spell_resolved" and data.get("card") == "Refill Spell"
        )
        assert mastery_event["exiled_targets"] == ["Refill Spell"]
        assert mastery_event["copied_spells"] == ["Refill Spell"]
        assert mastery_event["rule_logical_key"] == "battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f"
        assert copy_event["copied_spell"] == "Refill Spell"
        assert copy_event["cast_without_paying_mana_cost"] is True
        assert copy_resolution["source_zone"] == "stack_copy"
        assert copy_resolution["from_zone"] == "stack"
        assert copy_resolution["cast_pipeline"] == "spell_copy_resolution"
        assert copy_resolution["locked_cost"]["spend_tags"] == ["cast_without_paying_mana_cost"]
        assert [card.get("name") for card in active.hand] == ["Drawn One", "Drawn Two"]
        assert [card.get("name") for card in active.exile] == ["Refill Spell", "Mizzix's Mastery"]
        assert active.graveyard == []

    def test_pg106_mizzixs_mastery_copy_declares_target_before_removal_resolution():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            mizzix = {"name": "Mizzix's Mastery", "cmc": 4, "type_line": "Sorcery"}
            path = {"name": "Path to Exile", "cmc": 1, "type_line": "Instant"}
            threat = {
                "name": "Opponent Threat",
                "effect": "creature",
                "type_line": "Creature",
                "power": 4,
                "toughness": 4,
            }
            active.graveyard = [path]
            opponent.battlefield = [threat]

            battle.apply_effect_immediate(
                active,
                [opponent],
                mizzix,
                7,
                random.Random(10677),
                effect_data_override=battle.get_card_effect(mizzix),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        copy_resolution = next(
            data
            for event, data in events
            if event == "spell_resolved" and data.get("card") == "Path to Exile"
        )
        removal_resolution = next(
            data
            for event, data in events
            if event == "removal_resolved" and data.get("card") == "Path to Exile"
        )
        assert copy_resolution["cast_pipeline"] == "spell_copy_resolution"
        assert copy_resolution["source_zone"] == "stack_copy"
        assert copy_resolution["target"] == "Opponent Threat"
        assert copy_resolution["targets"] == [
            {
                "target": "Opponent Threat",
                "target_controller": "Opponent",
                "target_type": "creature",
                "target_legal": True,
                "targeting_pipeline": "targeting_formal_minimal",
            }
        ]
        assert removal_resolution["target"] == "Opponent Threat"
        assert opponent.battlefield == []
        assert [card.get("name") for card in opponent.exile] == ["Opponent Threat"]

    def test_pg073_esper_sentinel_draws_on_first_noncreature_spell_with_power_tax():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            caster = player("Caster")
            sentinel_controller = player("Sentinel Controller")
            sentinel_controller.library = [
                _card("Sentinel Draw One", cmc=1, effect="draw_cards"),
                _card("Sentinel Draw Two", cmc=1, effect="draw_cards"),
            ]
            sentinel = {
                "name": "Esper Sentinel",
                "cmc": 1,
                "mana_cost": "{W}",
                "type_line": "Artifact Creature - Human Soldier",
                "power": 1,
                "toughness": 1,
            }
            effect_data = battle.get_card_effect(sentinel)

            assert effect_data["effect"] == "draw_engine"
            assert effect_data["trigger"] == "opponent_noncreature_spell"
            assert effect_data["opponent_first_noncreature_spell_each_turn"] is True
            assert effect_data["tax_amount_equals_source_power"] is True
            assert effect_data["battle_model_scope"] == (
                "first_opponent_noncreature_spell_power_tax_draw_v1"
            )
            assert effect_data["_rule_logical_key"] == "battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d"
            assert effect_data["_rule_oracle_hash"] == "d8e8e60e34140942af13aa1be250a961"

            permanent = battle.prepare_entering_permanent(
                {**sentinel, **effect_data, "effect": "draw_engine"},
                controller=sentinel_controller,
                all_players=[caster, sentinel_controller],
                turn=4,
            )
            sentinel_controller.battlefield = [permanent]

            battle.trigger_opponent_spell_draw_engines(
                caster,
                [sentinel_controller],
                {"name": "Creature Spell", "cmc": 2, "type_line": "Creature", "effect": "creature"},
                turn=4,
                phase="main",
                rng=random.Random(7075),
            )
            battle.trigger_opponent_spell_draw_engines(
                caster,
                [sentinel_controller],
                {"name": "First Noncreature", "cmc": 2, "type_line": "Sorcery"},
                turn=4,
                phase="main",
                rng=random.Random(7075),
            )
            battle.trigger_opponent_spell_draw_engines(
                caster,
                [sentinel_controller],
                {"name": "Second Noncreature", "cmc": 2, "type_line": "Instant"},
                turn=4,
                phase="main",
                rng=random.Random(7075),
            )
            battle.trigger_opponent_spell_draw_engines(
                caster,
                [sentinel_controller],
                {"name": "Next Turn Noncreature", "cmc": 2, "type_line": "Sorcery"},
                turn=5,
                phase="main",
                rng=random.Random(7075),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        trigger_events = [
            data
            for event, data in events
            if event == "trigger_resolved" and data.get("card") == "Esper Sentinel"
        ]
        assert [event["trigger_spell"] for event in trigger_events] == [
            "First Noncreature",
            "Next Turn Noncreature",
        ]
        assert [card.get("name") for card in sentinel_controller.hand] == [
            "Sentinel Draw One",
            "Sentinel Draw Two",
        ]
        first_event = trigger_events[0]
        assert first_event["trigger"] == "opponent_noncreature_spell"
        assert first_event["result"] == "card_drawn"
        assert first_event["tax_amount"] == 1
        assert first_event["tax_paid"] is False
        assert first_event["noncreature_spell_number"] == 1
        assert first_event["opponent_first_noncreature_spell_each_turn"] is True
        assert first_event["tax_amount_equals_source_power"] is True
        assert first_event["rule_logical_key"] == "battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d"
        assert first_event["rule_oracle_hash"] == "d8e8e60e34140942af13aa1be250a961"

    def test_pg073_wheel_of_misfortune_uses_secret_number_compact_runtime():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            opponent = player("Opponent")
            wheel = {"name": "Wheel of Misfortune", "cmc": 3, "type_line": "Sorcery"}
            active.hand = [
                wheel,
                {"name": "Active Discard A", "cmc": 2, "type_line": "Instant"},
                {"name": "Active Discard B", "cmc": 2, "type_line": "Instant"},
            ]
            active.library = [
                {"name": f"Active Draw {index}", "cmc": 1, "type_line": "Sorcery"}
                for index in range(1, 8)
            ]
            opponent.hand = [
                {"name": "Opponent Keeps A", "cmc": 2, "type_line": "Instant"},
                {"name": "Opponent Keeps B", "cmc": 2, "type_line": "Instant"},
            ]
            opponent.library = [
                {"name": f"Opponent Draw {index}", "cmc": 1, "type_line": "Sorcery"}
                for index in range(1, 8)
            ]
            effect_data = battle.get_card_effect(wheel)

            assert effect_data["effect"] == "draw_cards"
            assert effect_data["count"] == 7
            assert effect_data["wheel_like"] is True
            assert effect_data["misfortune_secret_number_model"] is True
            assert effect_data["battle_model_scope"] == (
                "wheel_of_misfortune_secret_number_damage_discard_draw_compact_v1"
            )
            assert effect_data["_rule_logical_key"] == "battle_rule_v1:402155f35799993b812ca441586017cd"
            assert effect_data["_rule_oracle_hash"] == "fa744c33b4bc56c05977ec9c378e5b7d"

            active.hand.remove(wheel)
            battle.apply_effect_immediate(
                active,
                [opponent],
                wheel,
                4,
                random.Random(7076),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        wheel_event = next(
            data
            for event, data in events
            if event == "wheel_resolved" and data.get("card") == "Wheel of Misfortune"
        )
        assert wheel_event["highest_number"] == 7
        assert wheel_event["lowest_number"] == 0
        assert wheel_event["lowest_number_players"] == ["Opponent"]
        assert wheel_event["damaged"][0]["player"] == "Active"
        assert wheel_event["damaged"][0]["damage"] == 7
        assert active.life == 33
        active_result = next(entry for entry in wheel_event["participants"] if entry["player"] == "Active")
        opponent_result = next(entry for entry in wheel_event["participants"] if entry["player"] == "Opponent")
        assert active_result["discarded"] == 2
        assert active_result["drawn"] == 7
        assert opponent_result["lowest_number"] is True
        assert opponent_result["discarded"] == 0
        assert opponent_result["drawn"] == 0
        assert [card.get("name") for card in opponent.hand] == ["Opponent Keeps A", "Opponent Keeps B"]
        assert wheel_event["secret_number_choice_model"] == "compact_controller_draw_count_opponents_zero_v1"
        assert wheel_event["rule_logical_key"] == "battle_rule_v1:402155f35799993b812ca441586017cd"
        assert wheel_event["rule_oracle_hash"] == "fa744c33b4bc56c05977ec9c378e5b7d"

    def test_pg076_support_passive_annotations_and_ranger_small_creature_tutor():
        expected = {
            "Drannith Magistrate": (
                "battle_rule_v1:673c58ea36aeaf798d78aaaa10892e3e",
                "2335f446bb72dcb00f41aed8faf2167a",
                "static_nonhand_cast_restriction_annotation_creature_body_v1",
            ),
            "Giver of Runes": (
                "battle_rule_v1:c2736795c0d2c41d771b8a87319618bc",
                "ae6856021d2bee0a8ba4d7e70ce56637",
                "creature_body_protection_activation_annotation_v1",
            ),
            "Mother of Runes": (
                "battle_rule_v1:85d8c93e5ff3b531d4ab9217bd956948",
                "022c4e9496d2b5b6f0785bc63f8e9d11",
                "creature_body_protection_activation_annotation_v1",
            ),
            "Professional Face-Breaker": (
                "battle_rule_v1:3d154b436fcb6b4f290cdd0246d5def4",
                "606b21e85871f60d1804eaabcd59ac5b",
                "creature_body_menace_combat_damage_treasure_impulse_annotation_v1",
            ),
            "Ranger-Captain of Eos": (
                "battle_rule_v1:b05b64c0734daafd9c6f24ea02b39495",
                "43c8ec0dd0df9cecea5986a5ffb1d16d",
                "creature_body_etb_small_creature_tutor_sacrifice_noncreature_silence_annotation_v1",
            ),
            "Storm-Kiln Artist": (
                "battle_rule_v1:128e222b4de1e6308d98743711b54985",
                "cb2cf161073de3983ac24385743ab78a",
                "creature_body_artifact_power_magecraft_treasure_annotation_v1",
            ),
        }
        cards = [
            {"name": "Drannith Magistrate", "cmc": 2, "type_line": "Creature — Human Wizard"},
            {"name": "Giver of Runes", "cmc": 1, "type_line": "Creature — Kor Cleric"},
            {"name": "Mother of Runes", "cmc": 1, "type_line": "Creature — Human Cleric"},
            {"name": "Professional Face-Breaker", "cmc": 3, "type_line": "Creature — Human Warrior"},
            {"name": "Ranger-Captain of Eos", "cmc": 3, "type_line": "Creature — Human Soldier Ranger"},
            {"name": "Storm-Kiln Artist", "cmc": 4, "type_line": "Creature — Dwarf Shaman"},
        ]
        active = player("Active")
        active.library = [
            {
                "name": "Esper Sentinel",
                "cmc": 1,
                "type_line": "Artifact Creature — Human Soldier",
                "effect": "creature",
                "power": 1,
                "toughness": 1,
            },
            {
                "name": "Grand Abolisher",
                "cmc": 2,
                "type_line": "Creature — Human Cleric",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
            },
        ]
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            for card in cards:
                effect_data = battle.get_card_effect(card)
                logical_key, oracle_hash, scope = expected[card["name"]]
                assert effect_data["_rule_logical_key"] == logical_key
                assert effect_data["_rule_oracle_hash"] == oracle_hash
                assert effect_data["battle_model_scope"] == scope
                if card["name"] == "Ranger-Captain of Eos":
                    assert effect_data["etb_tutor_target"] == "creature_mana_value_1_or_less"
                    assert effect_data["etb_tutor_status"] == "runtime_library_to_hand"
                    assert effect_data["sacrifice_noncreature_silence_status"] == "annotation_only"
                elif card["name"] != "Drannith Magistrate":
                    assert effect_data["runtime_modeled_effect"] == "creature_body_only"
                battle.apply_effect_immediate(
                    active,
                    [],
                    card,
                    6,
                    random.Random(760),
                    effect_data_override=effect_data,
                )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        spell_events = {
            data["card"]: data
            for event, data in events
            if event == "spell_resolved" and data.get("card") in expected
        }
        assert set(spell_events) == set(expected)
        for name, (logical_key, oracle_hash, _scope) in expected.items():
            assert spell_events[name]["rule_logical_key"] == logical_key
            assert spell_events[name]["rule_oracle_hash"] == oracle_hash

        tutor_event = next(
            data
            for event, data in events
            if event == "tutor_resolved" and data.get("card") == "Ranger-Captain of Eos"
        )
        assert tutor_event["target_type"] == "creature_mana_value_1_or_less"
        assert tutor_event["found"] == "Esper Sentinel"
        assert tutor_event["rule_logical_key"] == expected["Ranger-Captain of Eos"][0]
        assert tutor_event["rule_oracle_hash"] == expected["Ranger-Captain of Eos"][1]
        assert [card.get("name") for card in active.hand] == ["Esper Sentinel"]

    def test_smothering_tithe_draw_step_creates_treasure_with_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            active.library = [_card("Drawn Card", cmc=1, effect="draw_cards")]
            tithe_controller = player("Tithe Controller")
            tithe_controller.battlefield = [
                {
                    "name": "Smothering Tithe",
                    "cmc": 4,
                    "type_line": "Enchantment",
                    "effect": "ramp_engine",
                    "trigger": "opponent_draw",
                    "treasure_count": 1,
                    "tax_amount": 2,
                    "tax_payment_model": "compact_assume_unpaid_v1",
                    "battle_model_scope": "opponent_draw_tax_treasure_v1",
                    "_rule_logical_key": "battle_rule_v1:242df1cde958c67ece11aae4af5f4bc6",
                    "_rule_oracle_hash": "bb7d29c1a84a53604c017da1b5f0620c",
                }
            ]

            battle.play_turn_v8(
                active,
                [tithe_controller],
                [active, tithe_controller],
                turn=4,
                rng=random.Random(1201),
                stack=battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert tithe_controller.treasures == 1
        assert any(
            event == "trigger_resolved"
            and data.get("player") == "Tithe Controller"
            and data.get("card") == "Smothering Tithe"
            and data.get("trigger") == "opponent_draw"
            and data.get("drawing_player") == "Active"
            and data.get("effect") == "create_treasure"
            and data.get("tax_paid") is False
            and data.get("treasures_created") == 1
            and data.get("tax_payment_model") == "compact_assume_unpaid_v1"
            and data.get("tax_payment_status") == "annotation_only_assume_unpaid"
            and data.get("rule_logical_key") == "battle_rule_v1:242df1cde958c67ece11aae4af5f4bc6"
            and data.get("rule_oracle_hash") == "bb7d29c1a84a53604c017da1b5f0620c"
            for event, data in events
        )

    def test_pg143_tataru_taru_etb_and_off_turn_draw_trigger_create_single_tapped_treasure():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Tataru Controller")
            active.library = [
                _card("Controller Draw", cmc=1, effect="draw_cards"),
                _card("Controller Draw Two", cmc=1, effect="draw_cards"),
            ]
            opponent = player("Opponent")
            opponent.library = [
                _card("Gift Draw", cmc=1, effect="draw_cards"),
                _card("Same Turn Extra Draw", cmc=1, effect="draw_cards"),
                _card("Own Turn Draw", cmc=1, effect="draw_cards"),
                _card("Off Turn Next Draw", cmc=1, effect="draw_cards"),
            ]
            card = {
                "name": "Tataru Taru",
                "cmc": 2,
                "type_line": "Legendary Creature - Dwarf Advisor",
            }
            effect_data = {
                "effect": "ramp_engine",
                "ability_kind": "triggered",
                "battle_model_scope": "etb_draw_target_opponent_may_draw_off_turn_once_each_turn_tapped_treasure_v1",
                "etb_draw_count": 1,
                "etb_target_opponent_may_draw_choice_model": "compact_assume_yes_single_card_v1",
                "etb_target_opponent_may_draw_count": 1,
                "is_creature_permanent": True,
                "power": 0,
                "toughness": 3,
                "treasure_count": 1,
                "treasure_tokens_tapped": True,
                "trigger": "opponent_draw",
                "trigger_limit_each_turn": 1,
                "trigger_only_off_turn_opponent_draw": True,
                "_rule_logical_key": "battle_rule_v1:78e8097d6f3437e339ab729d87e5099a",
                "_rule_oracle_hash": "313b5afad418df592c6011b08c80d972",
            }

            assert effect_data["effect"] == "ramp_engine"
            assert (
                effect_data["battle_model_scope"]
                == "etb_draw_target_opponent_may_draw_off_turn_once_each_turn_tapped_treasure_v1"
            )
            assert effect_data["trigger"] == "opponent_draw"
            assert effect_data["treasure_count"] == 1
            assert effect_data["treasure_tokens_tapped"] is True
            assert effect_data["trigger_only_off_turn_opponent_draw"] is True
            assert effect_data["trigger_limit_each_turn"] == 1
            assert effect_data["etb_draw_count"] == 1
            assert effect_data["etb_target_opponent_may_draw_count"] == 1

            battle.apply_effect_immediate(
                active,
                [opponent],
                card,
                turn=3,
                rng=random.Random(143),
                phase="precombat_main",
                effect_data_override=effect_data,
            )

            assert active.treasures == 1
            assert [entry.get("name") for entry in active.hand] == ["Controller Draw"]
            assert [entry.get("name") for entry in opponent.hand] == ["Gift Draw"]

            same_turn_drawn = opponent.draw(1, random.Random(144))
            battle.process_player_draw_triggers(
                opponent,
                len(same_turn_drawn),
                3,
                "postcombat_main",
                [active, opponent],
                turn_player=active,
            )
            assert active.treasures == 1

            own_turn_drawn = opponent.draw(1, random.Random(145))
            battle.process_player_draw_triggers(
                opponent,
                len(own_turn_drawn),
                4,
                "draw_step",
                [active, opponent],
                turn_player=opponent,
            )
            assert active.treasures == 1

            off_turn_drawn = opponent.draw(1, random.Random(146))
            battle.process_player_draw_triggers(
                opponent,
                len(off_turn_drawn),
                4,
                "end_step",
                [active, opponent],
                turn_player=active,
            )
            assert active.treasures == 2
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        treasure_events = [
            data
            for event, data in events
            if event == "trigger_resolved"
            and data.get("card") == "Tataru Taru"
            and data.get("trigger") == "opponent_draw"
        ]
        assert len(treasure_events) == 2
        assert all(data.get("treasures_created") == 1 for data in treasure_events)
        assert all(data.get("treasure_tokens_tapped") is True for data in treasure_events)
        assert all(data.get("trigger_only_off_turn_opponent_draw") is True for data in treasure_events)
        assert all(data.get("trigger_limit_each_turn") == 1 for data in treasure_events)
        assert any(
            event == "trigger_resolved"
            and data.get("card") == "Tataru Taru"
            and data.get("trigger") == "etb_target_opponent_may_draw"
            and data.get("target_player") == "Opponent"
            and data.get("cards_drawn") == 1
            and data.get("choice_model") == "compact_assume_yes_single_card_v1"
            for event, data in events
        )

    def test_lotho_second_spell_trigger_creates_treasure_and_loses_life():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            controller = player("Lotho Controller")
            controller.life = 30
            controller.battlefield = [
                {
                    "name": "Lotho, Corrupt Shirriff",
                    "cmc": 2,
                    "type_line": "Legendary Creature — Halfling Rogue",
                    "effect": "ramp_engine",
                    "is_creature_permanent": True,
                    "power": 2,
                    "toughness": 1,
                    "trigger": "opponent_spell",
                    "opponent_second_spell_each_turn": True,
                    "treasure_count": 1,
                    "controller_loses_life_on_trigger": 1,
                    "battle_model_scope": "opponent_second_spell_each_turn_create_treasure_life_loss_v1",
                }
            ]
            caster = player("Caster")
            spell = {"name": "Ponder", "type_line": "Sorcery", "cmc": 1}

            caster.record_spell_cast(5)
            battle.trigger_opponent_spell_draw_engines(
                caster,
                [controller],
                spell,
                5,
                "precombat_main",
                random.Random(1202),
            )
            assert controller.treasures == 0
            assert controller.life == 30

            caster.record_spell_cast(5)
            battle.trigger_opponent_spell_draw_engines(
                caster,
                [controller],
                spell,
                5,
                "precombat_main",
                random.Random(1202),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert controller.treasures == 1
        assert controller.life == 29
        trigger_event = next(
            data
            for event, data in events
            if event == "trigger_resolved" and data.get("card") == "Lotho, Corrupt Shirriff"
        )
        assert trigger_event["treasures_created"] == 1
        assert trigger_event["life_lost"] == 1
        assert trigger_event["life_before"] == 30
        assert trigger_event["life_after"] == 29
        assert trigger_event["opponent_spell_count"] == 2

    def test_pg144_knuckles_combat_damage_trigger_creates_treasure_each_damage_step():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            opponent = player("Opponent")
            knuckles = {"name": "Knuckles the Echidna", "cmc": 4, "type_line": "Legendary Creature — Echidna Warrior"}
            effect_data = {
                "effect": "ramp_engine",
                "battle_model_scope": "one_or_more_creatures_you_control_combat_damage_player_create_treasure_v1",
                "is_creature_permanent": True,
                "power": 2,
                "toughness": 4,
                "double_strike": True,
                "trample": True,
                "haste": True,
                "trigger": "combat_damage_to_player",
                "trigger_creatures_you_control": True,
                "treasure_count": 1,
                "upkeep_win_if_control_artifacts_at_least": 30,
                "upkeep_win_status": "annotation_only",
            }

            battle.apply_effect_immediate(
                active,
                [opponent],
                knuckles,
                5,
                random.Random(12021),
                effect_data_override=effect_data,
            )

            creature = next(card for card in active.battlefield if card.get("name") == "Knuckles the Echidna")
            creature["summoning_sick"] = False
            creature["tapped"] = True
            battle.combat_damage_steps(
                active,
                [opponent],
                opponent,
                [creature],
                [(creature, [])],
                5,
                random.Random(12022),
                all_players=[active, opponent],
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert active.treasures == 2
        trigger_events = [
            data
            for event, data in events
            if event == "trigger_resolved"
            and data.get("card") == "Knuckles the Echidna"
            and data.get("trigger") == "combat_damage_to_player"
        ]
        assert len(trigger_events) == 2
        assert all(data.get("treasures_created") == 1 for data in trigger_events)
        assert all(data.get("damaged_player") == "Opponent" for data in trigger_events)
        assert trigger_events[0]["phase"] == "first_strike_damage"
        assert trigger_events[1]["phase"] == "combat_damage"

    def test_prized_statue_enters_and_dies_create_treasures():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            prized = {"name": "Prized Statue", "cmc": 4, "type_line": "Artifact"}
            effect_data = {
                "effect": "ramp_permanent",
                "battle_model_scope": "artifact_etb_or_dies_create_treasure_v1",
                "treasure_count": 1,
                "enters_treasure": 1,
                "dies_or_graveyard_from_battlefield_treasure": True,
            }

            battle.apply_effect_immediate(
                active,
                [],
                prized,
                5,
                random.Random(1203),
                effect_data_override=effect_data,
            )

            assert active.treasures == 1
            statue = next(card for card in active.battlefield if card.get("name") == "Prized Statue")
            destination = battle.move_permanent_from_battlefield(
                active,
                statue,
                reason="sacrifice_test",
                source={"name": "Test Source"},
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert destination == "graveyard"
        assert active.treasures == 2
        enter_event = next(
            data
            for event, data in events
            if event == "trigger_resolved"
            and data.get("card") == "Prized Statue"
            and data.get("trigger") == "enters_battlefield"
        )
        assert enter_event["treasures_created"] == 1
        dies_event = next(
            data
            for event, data in events
            if event == "trigger_resolved"
            and data.get("card") == "Prized Statue"
            and data.get("trigger") == "dies_or_graveyard_from_battlefield"
        )
        assert dies_event["treasures_created"] == 1
        assert dies_event["destination"] == "graveyard"

    def test_impulsive_pilferer_dies_create_treasure():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            pilferer = {"name": "Impulsive Pilferer", "cmc": 1, "type_line": "Creature — Goblin Pirate"}
            effect_data = {
                "effect": "creature",
                "battle_model_scope": "dies_create_treasure_encore_v1",
                "power": 1,
                "toughness": 1,
                "treasure_count": 1,
                "dies_or_graveyard_from_battlefield_treasure": True,
                "encore_cost": "{3}{R}",
            }

            battle.apply_effect_immediate(
                active,
                [],
                pilferer,
                5,
                random.Random(12031),
                effect_data_override=effect_data,
            )

            creature = next(card for card in active.battlefield if card.get("name") == "Impulsive Pilferer")
            destination = battle.move_permanent_from_battlefield(
                active,
                creature,
                reason="combat_damage_lethal",
                source={"name": "Test Combat"},
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert destination == "graveyard"
        assert active.treasures == 1
        dies_event = next(
            data
            for event, data in events
            if event == "trigger_resolved"
            and data.get("card") == "Impulsive Pilferer"
            and data.get("trigger") == "dies_or_graveyard_from_battlefield"
        )
        assert dies_event["treasures_created"] == 1
        assert dies_event["destination"] == "graveyard"

    def test_reckless_endeavor_damage_wipe_creates_treasures():
        active = player("Active")
        opponent = player("Opponent")
        active.battlefield = [
            {"name": "Own Small", "effect": "creature", "type_line": "Creature", "power": 1, "toughness": 1}
        ]
        opponent.battlefield = [
            {"name": "Opp Small", "effect": "creature", "type_line": "Creature", "power": 2, "toughness": 2},
            {"name": "Opp Big", "effect": "creature", "type_line": "Creature", "power": 8, "toughness": 8},
        ]

        battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Reckless Endeavor", "cmc": 7, "type_line": "Sorcery"},
            7,
            random.Random(1164),
            effect_data_override={
                "effect": "damage_wipe_treasure",
                "damage": 6,
                "treasure_count": 5,
                "battle_model_scope": "test_damage_wipe_treasure",
            },
        )

        assert active.treasures == 5
        assert [card.get("name") for card in active.battlefield] == []
        assert [card.get("name") for card in opponent.battlefield] == ["Opp Big"]

    def test_reverse_the_sands_swaps_with_highest_life_opponent():
        active = player("Active")
        active.life = 8
        opponent = player("Opponent")
        opponent.life = 34

        battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Reverse the Sands", "cmc": 8, "type_line": "Sorcery"},
            8,
            random.Random(1165),
            effect_data_override={
                "effect": "redistribute_life_totals",
                "battle_model_scope": "test_redistribute_life_totals",
            },
        )

        assert active.life == 34
        assert opponent.life == 8

    def test_birgi_adds_red_mana_when_controller_casts_spell():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        birgi_card = {
            "name": "Birgi, God of Storytelling",
            "cmc": 3,
            "type_line": "Legendary Creature — God",
        }
        birgi = battle.prepare_entering_permanent(
            battle.enrich_card({**birgi_card, **battle.get_card_effect(birgi_card)})
        )
        active.battlefield = [birgi]
        spell = {
            "name": "Generic Creature Spell",
            "cmc": 2,
            "type_line": "Creature — Soldier",
            "effect": "creature",
        }

        battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            spell,
            turn=3,
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert active.mana_pool.red == 1
        assert any(
            event == "trigger_resolved"
            and data.get("card") == "Birgi, God of Storytelling"
            and data.get("trigger") == "spell_cast"
            and data.get("effect") == "add_mana"
            and data.get("mana_color") == "red"
            for event, data in events
        )

    def test_electroduplicate_creates_hasty_copy_and_sacrifices_at_end_step():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        target = {
            "name": "Value Creature",
            "effect": "creature",
            "type_line": "Creature",
            "power": 4,
            "toughness": 4,
        }
        active.battlefield = [target]
        card = {"name": "Electroduplicate", "cmc": 3, "type_line": "Sorcery"}

        battle.apply_effect_immediate(active, [], card, 4, random.Random(47))

        tokens = [
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("copy_of") == "Value Creature"
        ]
        assert len(tokens) == 1
        token = tokens[0]
        assert token.get("haste") is True
        assert token.get("sacrifice_at_end_step") is True

        battle.process_end_step_token_sacrifices(active, 4)
        battle.REPLAY_EVENT_HANDLER = None

        assert token not in active.battlefield
        assert any(card.get("name") == token.get("name") for card in active.graveyard)
        assert any(
            event == "copy_creature_token_created"
            and data.get("card") == "Electroduplicate"
            and data.get("target") == "Value Creature"
            for event, data in events
        )
        assert any(event == "end_step_token_sacrificed" for event, _ in events)

    def test_heat_shimmer_copies_any_creature_and_exiles_token_at_end_step():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            opponent = player("Opponent")
            active.battlefield = [
                {"name": "Small Utility", "effect": "creature", "type_line": "Creature", "power": 1, "toughness": 1}
            ]
            opponent.battlefield = [
                {"name": "Large Threat", "effect": "creature", "type_line": "Creature", "power": 7, "toughness": 7}
            ]
            card = {"name": "Heat Shimmer", "cmc": 3, "type_line": "Sorcery"}

            battle.apply_effect_immediate(
                active,
                [opponent],
                card,
                5,
                random.Random(681),
                effect_data_override={
                    "effect": "copy_creature_token",
                    "target_controller": "any",
                    "copy_target_types": ["creature"],
                    "token_haste": True,
                    "exile_token_at_end_step": True,
                    "battle_model_scope": "target_creature_copy_haste_exile_eot_v1",
                    "_rule_logical_key": "battle_rule_v1:644897bfa688d33b1a718723360e2480",
                    "_rule_oracle_hash": "9c4cfbeb99bfea90a8a5d4c3c7894793",
                },
            )
            token = next(
                permanent
                for permanent in active.battlefield
                if isinstance(permanent, dict) and permanent.get("copy_of") == "Large Threat"
            )
            battle.process_end_step_token_sacrifices(active, 5)
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert token not in active.battlefield
        assert token in active.exile
        created = next(data for event, data in events if event == "copy_creature_token_created")
        assert created["card"] == "Heat Shimmer"
        assert created["target"] == "Large Threat"
        assert created["target_controller"] == "Opponent"
        assert created["haste"] is True
        assert created["exile_at_end_step"] is True
        assert created["rule_logical_key"] == "battle_rule_v1:644897bfa688d33b1a718723360e2480"
        assert created["rule_oracle_hash"] == "9c4cfbeb99bfea90a8a5d4c3c7894793"
        assert any(event == "end_step_token_exiled" for event, _ in events)

    def test_twinflame_copies_own_creature_only_and_exiles_token_at_end_step():
        active = player("Active")
        opponent = player("Opponent")
        active.battlefield = [
            {"name": "Own Combo Creature", "effect": "creature", "type_line": "Creature", "power": 2, "toughness": 2}
        ]
        opponent.battlefield = [
            {"name": "Opponent Bomb", "effect": "creature", "type_line": "Creature", "power": 9, "toughness": 9}
        ]

        battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Twinflame", "cmc": 2, "type_line": "Sorcery"},
            5,
            random.Random(682),
            effect_data_override={
                "effect": "copy_creature_token",
                "target_controller": "own",
                "copy_target_types": ["creature"],
                "token_haste": True,
                "exile_token_at_end_step": True,
                "strive_multi_target_status": "annotation_only_single_best_own_creature",
                "battle_model_scope": "own_creature_single_copy_haste_exile_eot_v1",
                "_rule_logical_key": "battle_rule_v1:97ab0167213936bfa544f19731284e56",
                "_rule_oracle_hash": "d9c51f63ac78f713113c52feadfba6db",
            },
        )

        tokens = [
            permanent for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("token")
        ]
        assert len(tokens) == 1
        assert tokens[0]["copy_of"] == "Own Combo Creature"
        assert tokens[0]["haste"] is True
        assert tokens[0]["exile_at_end_step"] is True

    def test_molten_duplication_copies_own_artifact_as_artifact_and_sacrifices_token():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            active.battlefield = [
                {
                    "name": "Sol Ring",
                    "effect": "ramp_permanent",
                    "type_line": "Artifact",
                    "mana_produced": 2,
                }
            ]

            battle.apply_effect_immediate(
                active,
                [],
                {"name": "Molten Duplication", "cmc": 2, "type_line": "Sorcery"},
                5,
                random.Random(683),
                effect_data_override={
                    "effect": "copy_creature_token",
                    "target_controller": "own",
                    "copy_target_types": ["artifact", "creature"],
                    "artifact_in_addition": True,
                    "token_haste": True,
                    "sacrifice_token_at_end_step": True,
                    "battle_model_scope": "own_artifact_or_creature_copy_artifact_haste_sacrifice_eot_v1",
                    "_rule_logical_key": "battle_rule_v1:e154b34c0deaa861094d5870f4c0ad69",
                    "_rule_oracle_hash": "7c24d56660499c0af4db967925de1573",
                },
            )
            token = next(
                permanent
                for permanent in active.battlefield
                if isinstance(permanent, dict) and permanent.get("copy_of") == "Sol Ring"
            )
            battle.process_end_step_token_sacrifices(active, 5)
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert token["artifact_token"] is True
        assert "artifact" in token["type_line"].lower()
        assert token not in active.battlefield
        assert token in active.graveyard
        created = next(data for event, data in events if event == "copy_creature_token_created")
        assert created["card"] == "Molten Duplication"
        assert created["target"] == "Sol Ring"
        assert created["artifact_in_addition"] is True
        assert created["sacrifice_at_end_step"] is True
        assert created["rule_logical_key"] == "battle_rule_v1:e154b34c0deaa861094d5870f4c0ad69"
        assert created["rule_oracle_hash"] == "7c24d56660499c0af4db967925de1573"
        assert any(event == "end_step_token_sacrificed" for event, _ in events)

    def test_flash_photography_copies_target_permanent_without_temporary_cleanup():
        active = player("Active")
        opponent = player("Opponent")
        opponent.battlefield = [
            {
                "name": "Mana Vault",
                "effect": "ramp_permanent",
                "type_line": "Artifact",
                "mana_produced": 3,
            }
        ]

        battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Flash Photography", "cmc": 4, "type_line": "Sorcery"},
            5,
            random.Random(684),
            effect_data_override={
                "effect": "copy_creature_token",
                "copy_target_types": ["permanent"],
                "target_controller": "any",
                "token_haste": False,
                "battle_model_scope": "copy_target_permanent_v1",
                "_rule_logical_key": "battle_rule_v1:4c6937147f6f4af4eb8b3e2d3e0f1349",
                "_rule_oracle_hash": "c3fb29c6ec7bd40a4d59959e9abe9ee8",
            },
        )

        token = next(
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("copy_of") == "Mana Vault"
        )
        assert token["effect"] == "ramp_permanent"
        assert token["haste"] is False
        assert token.get("sacrifice_at_end_step") is not True
        assert token.get("exile_at_end_step") is not True
        assert "artifact" in token.get("type_line", "").lower()

    def test_clone_legion_copies_each_creature_controlled_by_target_player():
        active = player("Active")
        opponent_a = player("Opponent A")
        opponent_b = player("Opponent B")
        opponent_a.battlefield = [
            {"name": "A Threat", "effect": "creature", "type_line": "Creature", "power": 5, "toughness": 5},
            {"name": "A Utility", "effect": "creature", "type_line": "Creature", "power": 2, "toughness": 2},
        ]
        opponent_b.battlefield = [
            {"name": "B Threat", "effect": "creature", "type_line": "Creature", "power": 1, "toughness": 1}
        ]

        battle.apply_effect_immediate(
            active,
            [opponent_a, opponent_b],
            {"name": "Clone Legion", "cmc": 9, "type_line": "Sorcery"},
            6,
            random.Random(685),
            effect_data_override={
                "effect": "copy_creature_token",
                "copy_target_types": ["creature"],
                "target_controller": "opponent",
                "copy_all_matching_targets": True,
                "battle_model_scope": "copy_each_creature_target_player_controls_v1",
                "_rule_logical_key": "battle_rule_v1:b8e88d7633d81dbdf0185cf2bcfd1dbc",
                "_rule_oracle_hash": "d5300831d3df4276f01145ddeca85521",
            },
        )

        copied = sorted(
            permanent.get("copy_of")
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("token")
        )
        assert copied == ["A Threat", "A Utility"]

    def test_astral_dragon_etb_creates_two_dragon_copies_of_noncreature_permanent():
        active = player("Active")
        opponent = player("Opponent")
        opponent.battlefield = [
            {
                "name": "Smothering Tithe",
                "effect": "draw_engine",
                "type_line": "Enchantment",
            }
        ]

        battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Astral Dragon", "cmc": 8, "type_line": "Creature — Dragon"},
            6,
            random.Random(686),
            effect_data_override={
                "effect": "creature",
                "power": 4,
                "toughness": 4,
                "flying": True,
                "etb_copy_target_types": ["noncreature_permanent"],
                "etb_copy_token_count": 2,
                "etb_copy_force_creature": True,
                "etb_copy_token_power": 3,
                "etb_copy_token_toughness": 3,
                "etb_copy_token_flying": True,
                "etb_copy_token_subtype": "Dragon",
                "battle_model_scope": "etb_copy_target_noncreature_permanent_twice_as_3_3_flying_dragon_v1",
                "_rule_logical_key": "battle_rule_v1:cb774fbd1b2a4fc4f8c6cba85d0db512",
                "_rule_oracle_hash": "5efa9ecc8bca6d341f1dc4dea3e51c49",
            },
        )

        dragon_tokens = [
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("copy_of") == "Smothering Tithe"
        ]
        assert len(dragon_tokens) == 2
        assert all(token.get("power") == 3 for token in dragon_tokens)
        assert all(token.get("toughness") == 3 for token in dragon_tokens)
        assert all(token.get("flying") is True for token in dragon_tokens)
        assert all("dragon" in token.get("type_line", "").lower() for token in dragon_tokens)

    def test_jaxis_copies_another_creature_draws_on_token_death_and_excludes_source(self):
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            active.library = [
                {"name": "Drawn Off Jaxis", "cmc": 2, "type_line": "Instant", "effect": "draw_cards"}
            ]
            jaxis = {
                "name": "Jaxis, the Troublemaker",
                "effect": "creature",
                "type_line": "Legendary Creature — Human Warrior",
                "power": 2,
                "toughness": 3,
            }
            target = {
                "name": "Big Artifact Dragon",
                "effect": "creature",
                "type_line": "Artifact Creature — Dragon",
                "power": 6,
                "toughness": 6,
            }
            active.battlefield = [jaxis, target]

            battle.apply_effect_immediate(
                active,
                [],
                jaxis,
                7,
                random.Random(687),
                effect_data_override={
                    "effect": "copy_creature_token",
                    "copy_target_types": ["creature"],
                    "target_controller": "own",
                    "exclude_source_from_copy_targets": True,
                    "token_haste": True,
                    "token_draw_cards_when_this_dies": 1,
                    "sacrifice_token_at_end_step": True,
                    "battle_model_scope": "copy_target_another_creature_you_control_haste_draw_on_death_sacrifice_end_step_v1",
                },
            )
            token = next(
                permanent
                for permanent in active.battlefield
                if isinstance(permanent, dict) and permanent.get("copy_of") == "Big Artifact Dragon"
            )
            battle.process_end_step_token_sacrifices(active, 7)
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert token not in active.battlefield
        assert token in active.graveyard
        assert len(active.hand) == 1
        assert active.hand[0]["name"] == "Drawn Off Jaxis"
        created = next(data for event, data in events if event == "copy_creature_token_created")
        assert created["target"] == "Big Artifact Dragon"
        assert all(
            not (event == "copy_creature_token_created" and data.get("target") == "Jaxis, the Troublemaker")
            for event, data in events
        )
        draw_event = next(data for event, data in events if event == "end_step_token_death_draw_resolved")
        assert draw_event["draw_count"] == 1
        assert draw_event["cards_drawn"] == ["Drawn Off Jaxis"]

    def test_rionya_creates_one_plus_instant_and_sorcery_spell_copies_and_exiles_them(self):
        active = player("Active")
        target = {
            "name": "Copied Wizard",
            "effect": "creature",
            "type_line": "Creature — Wizard",
            "power": 3,
            "toughness": 3,
            "colors": ["U"],
        }
        rionya = {
            "name": "Rionya, Fire Dancer",
            "effect": "creature",
            "type_line": "Legendary Creature — Human Wizard",
            "power": 3,
            "toughness": 4,
        }
        active.battlefield = [rionya, target]
        active.instant_or_sorcery_spells_cast_this_turn = 2

        battle.apply_effect_immediate(
            active,
            [],
            rionya,
            8,
            random.Random(688),
            effect_data_override={
                "effect": "copy_creature_token",
                "copy_target_types": ["creature"],
                "target_controller": "own",
                "exclude_source_from_copy_targets": True,
                "token_count_source": "instant_or_sorcery_spells_cast_this_turn_plus_one",
                "token_haste": True,
                "exile_token_at_end_step": True,
                "battle_model_scope": "copy_target_another_creature_you_control_x_instant_sorcery_plus_one_haste_exile_end_step_v1",
            },
        )

        tokens = [
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("copy_of") == "Copied Wizard"
        ]
        assert len(tokens) == 3
        assert all(token.get("haste") is True for token in tokens)
        battle.process_end_step_token_sacrifices(active, 8)
        assert all(token in active.exile for token in tokens)
        assert all(token not in active.battlefield for token in tokens)

    def test_jolly_balloon_man_adds_red_balloon_flying_haste_without_losing_other_colors(self):
        active = player("Active")
        source = {
            "name": "The Jolly Balloon Man",
            "effect": "creature",
            "type_line": "Legendary Creature — Human Clown",
            "power": 1,
            "toughness": 4,
            "colors": ["R", "W"],
        }
        target = {
            "name": "Azure Geist",
            "effect": "creature",
            "type_line": "Enchantment Creature — Spirit",
            "power": 4,
            "toughness": 4,
            "colors": ["U"],
        }
        active.battlefield = [source, target]

        battle.apply_effect_immediate(
            active,
            [],
            source,
            9,
            random.Random(689),
            effect_data_override={
                "effect": "copy_creature_token",
                "copy_target_types": ["creature"],
                "target_controller": "own",
                "exclude_source_from_copy_targets": True,
                "force_token_creature": True,
                "token_power": 1,
                "token_toughness": 1,
                "token_extra_colors": ["R"],
                "token_subtype": "Balloon",
                "token_flying": True,
                "token_haste": True,
                "sacrifice_token_at_end_step": True,
                "battle_model_scope": "copy_target_another_creature_you_control_balloon_1_1_red_flying_haste_sacrifice_end_step_v1",
            },
        )

        token = next(
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("copy_of") == "Azure Geist"
        )
        assert token["power"] == 1
        assert token["toughness"] == 1
        assert token["flying"] is True
        assert token["haste"] is True
        assert token["colors"] == ["U", "R"]
        assert "balloon" in token.get("type_line", "").lower()
        battle.process_end_step_token_sacrifices(active, 9)
        assert token in active.graveyard

    def test_valakut_awakening_filters_hand_and_draws_plus_one():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        high_a = {"name": "Eight Drop A", "cmc": 8, "type_line": "Sorcery", "effect": "draw_cards"}
        high_b = {"name": "Nine Drop B", "cmc": 9, "type_line": "Sorcery", "effect": "draw_cards"}
        keep = {"name": "Cheap Removal", "cmc": 1, "type_line": "Instant", "effect": "remove_creature"}
        card = {"name": "Valakut Awakening", "cmc": 3, "type_line": "Instant"}
        active.hand = [card, high_a, high_b, keep]
        active.library = [
            {"name": "Draw One", "cmc": 2, "type_line": "Sorcery"},
            {"name": "Draw Two", "cmc": 2, "type_line": "Sorcery"},
            {"name": "Draw Three", "cmc": 2, "type_line": "Sorcery"},
        ]

        battle.apply_effect_immediate(active, [], card, 4, random.Random(48))
        battle.REPLAY_EVENT_HANDLER = None

        hand_names = [entry.get("name") for entry in active.hand if isinstance(entry, dict)]
        assert "Cheap Removal" in hand_names
        assert "Draw One" in hand_names
        assert "Draw Two" in hand_names
        assert "Draw Three" in hand_names
        assert "Eight Drop A" not in hand_names
        assert "Nine Drop B" not in hand_names
        assert any(
            event == "hand_filter_resolved"
            and data.get("card") == "Valakut Awakening"
            and set(data.get("bottomed", [])) == {"Eight Drop A", "Nine Drop B"}
            and data.get("draw_count") == 3
            for event, data in events
        )

    def test_valakut_awakening_preserves_approach_as_win_condition():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Lorehold")
        approach = {
            "name": "Approach of the Second Sun",
            "cmc": 7,
            "type_line": "Sorcery",
        }
        high_spell = {"name": "Nine Drop B", "cmc": 9, "type_line": "Sorcery", "effect": "draw_cards"}
        card = {"name": "Valakut Awakening", "cmc": 3, "type_line": "Instant"}
        active.hand = [card, approach, high_spell]
        active.library = [
            {"name": "Draw One", "cmc": 2, "type_line": "Sorcery"},
            {"name": "Draw Two", "cmc": 2, "type_line": "Sorcery"},
        ]

        battle.apply_effect_immediate(active, [], card, 4, random.Random(49))
        battle.REPLAY_EVENT_HANDLER = None

        hand_names = [entry.get("name") for entry in active.hand if isinstance(entry, dict)]
        assert "Approach of the Second Sun" in hand_names
        assert "Nine Drop B" not in hand_names
        assert any(
            event == "hand_filter_resolved"
            and data.get("card") == "Valakut Awakening"
            and "Approach of the Second Sun" not in set(data.get("bottomed", []))
            and "Nine Drop B" in set(data.get("bottomed", []))
            for event, data in events
        )

    def test_valakut_awakening_split_name_emits_pg042_rule_provenance():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Lorehold")
        card = {
            "name": "Valakut Awakening // Valakut Stoneforge",
            "cmc": 3,
            "type_line": "Instant",
        }
        active.hand = [
            card,
            {"name": "Approach of the Second Sun", "cmc": 7, "type_line": "Sorcery"},
            {"name": "Nine Drop B", "cmc": 9, "type_line": "Sorcery", "effect": "draw_cards"},
            {"name": "Cheap Removal", "cmc": 1, "type_line": "Instant", "effect": "remove_creature"},
        ]
        active.library = [
            {"name": "Draw One", "cmc": 2, "type_line": "Sorcery"},
            {"name": "Draw Two", "cmc": 2, "type_line": "Sorcery"},
        ]

        effect = battle.get_card_effect(card)
        assert effect["effect"] == "hand_filter"
        assert effect["battle_model_scope"] == "bottom_then_draw_plus_one_mdfc_land_v1"
        assert effect["_rule_logical_key"] == "battle_rule_v1:6e1f3b876822abafe1de47610f46858d"
        assert effect["_rule_oracle_hash"] == "22b42fcc181b7aed71f78b2e1e51e887"

        battle.apply_effect_immediate(active, [], card, 4, random.Random(52))
        battle.REPLAY_EVENT_HANDLER = None

        spell_event = next(data for event, data in events if event == "spell_resolved")
        filter_event = next(data for event, data in events if event == "hand_filter_resolved")
        assert spell_event["rule_logical_key"] == "battle_rule_v1:6e1f3b876822abafe1de47610f46858d"
        assert spell_event["rule_oracle_hash"] == "22b42fcc181b7aed71f78b2e1e51e887"
        assert spell_event["destination"] == "graveyard"
        assert filter_event["rule_logical_key"] == "battle_rule_v1:6e1f3b876822abafe1de47610f46858d"
        assert filter_event["rule_oracle_hash"] == "22b42fcc181b7aed71f78b2e1e51e887"
        assert filter_event["draw_count"] == 2
        assert filter_event["bottomed"] == ["Nine Drop B"]
        hand_names = [entry.get("name") for entry in active.hand if isinstance(entry, dict)]
        assert "Approach of the Second Sun" in hand_names

    def test_mulligan_trace_scores_keep_vs_mulligan_for_heavy_dead_hand():
        decisions = []
        previous_trace_handler = battle.DECISION_TRACE_HANDLER
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
            active = player("Lorehold")
            active.hand = [
                {"name": "Plains", "cmc": 0, "type_line": "Land"},
                {"name": "Mountain", "cmc": 0, "type_line": "Land"},
                {"name": "Sacred Foundry", "cmc": 0, "type_line": "Land"},
                {"name": "Eight Drop A", "cmc": 8, "type_line": "Sorcery"},
                {"name": "Eight Drop B", "cmc": 8, "type_line": "Sorcery"},
                {"name": "Nine Drop A", "cmc": 9, "type_line": "Sorcery"},
                {"name": "Nine Drop B", "cmc": 9, "type_line": "Sorcery"},
            ]

            evaluation = battle.mulligan_evaluation(active.hand)
            assert evaluation["keep"] is False
            assert evaluation["reason"] == "expensive_cluster_without_setup"
            battle._emit_mulligan_decision_trace(
                active,
                evaluation,
                mulligan_count=0,
                chosen_action="mulligan",
                bottomed_cards=[],
            )
        finally:
            battle.DECISION_TRACE_HANDLER = previous_trace_handler

        assert len(decisions) == 1
        trace = decisions[0]
        assert trace["decision_type"] == "mulligan_decision"
        assert trace["chosen_option"]["action"] == "mulligan"
        assert trace["chosen_option_score"] > trace["best_rejected_option_score"]
        assert trace["score_gap_vs_best_rejected"] > 0
        assert any(item["option"] == "mulligan" for item in trace["available_option_scores"])
        assert any(item["option"] == "keep" for item in trace["rejected_option_scores"])
        assert "expensive_dead_hand" in trace["risk_flags"]

    def test_special_lands_are_modelled_as_lands_not_spell_heuristics():
        ancient_tomb_effect = battle.get_card_effect({"name": "Ancient Tomb", "type_line": "Land"})
        assert ancient_tomb_effect["effect"] == "land"
        assert ancient_tomb_effect["mana_produced"] == 1
        assert ancient_tomb_effect["ancient_tomb_bonus_mana"] == 1
        assert ancient_tomb_effect["ancient_tomb_bonus_life_cost"] == 2

        active = player("Active", [{"name": "Too Expensive", "cmc": 9, "type_line": "Sorcery"}])
        active.hand = [{"name": "Ancient Tomb", "cmc": 0, "type_line": "Land"}]
        opponent = player("Opponent")
        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            rng=random.Random(49),
            stack=battle.Stack(),
        )

        assert any(
            permanent.get("name") == "Ancient Tomb"
            and permanent.get("effect") == "land"
            and permanent.get("mana_produced") == 1
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert active.mana_pool.colorless >= 1

        expected_land_models = {
            "Ancient Den": ("W", 1),
            "Gemstone Caverns": ("WUBRGC", 1),
            "Great Furnace": ("R", 1),
            "Hall of Heliod's Generosity": ("C", 1),
            "Inventors' Fair": ("C", 1),
            "Sunbaked Canyon": ("WR", 1),
            "Urza's Saga": ("C", 1),
            "War Room": ("C", 1),
            "Valakut Awakening // Valakut Stoneforge": (None, None),
        }
        for name, expected in expected_land_models.items():
            effect = battle.get_card_effect(
                {"name": name, "type_line": "Instant // Land"}
                if name == "Valakut Awakening // Valakut Stoneforge"
                else {"name": name, "type_line": "Land"}
            )
            if name == "Valakut Awakening // Valakut Stoneforge":
                assert effect["effect"] == "hand_filter"
                assert effect["mdfc_land_face"]["effect"] == "land"
                assert effect["mdfc_land_face"]["produces"] == "R"
                continue
            produces, mana_produced = expected
            assert effect["effect"] == "land"
            assert effect["produces"] == produces
            assert effect["mana_produced"] == mana_produced

    def test_war_room_activates_when_hand_is_low_and_life_is_safe():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        commander = {
            "name": "Lorehold, the Historian",
            "type_line": "Legendary Creature — Elder Dragon",
            "color_identity": ["W", "R"],
        }
        active.commander = commander
        active.command_zone = [commander]
        active.life = 12
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {"name": "War Room", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            {"name": "Ancient Den", "effect": "land", "type_line": "Artifact Land", "produces": "W", "mana_produced": 1},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(90))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert active.life == 10
        assert any(card.get("name") == "Drawn Card" for card in active.hand)
        assert any(card.get("name") == "War Room" for card in active.battlefield)
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "War Room"
            and data.get("activation_kind") == "draw_card"
            and data.get("life_paid") == 2
            for event, data in events
        )

    def test_war_room_skips_when_life_is_too_low():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        commander = {
            "name": "Lorehold, the Historian",
            "type_line": "Legendary Creature — Elder Dragon",
            "color_identity": ["W", "R"],
        }
        active.commander = commander
        active.command_zone = [commander]
        active.life = 6
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {"name": "War Room", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            {"name": "Ancient Den", "effect": "land", "type_line": "Artifact Land", "produces": "W", "mana_produced": 1},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(91))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert active.life == 6
        assert not any(card.get("name") == "Drawn Card" for card in active.hand)
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "War Room"
            and data.get("strategic_guardrail_reason") == "life_too_low_for_war_room_activation"
            for event, data in events
        )

    def test_sunbaked_canyon_turns_expendable_land_into_card():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {"name": "Sunbaked Canyon", "effect": "land", "type_line": "Land", "produces": "WR", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            {"name": "Ancient Den", "effect": "land", "type_line": "Artifact Land", "produces": "W", "mana_produced": 1},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(92))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert any(card.get("name") == "Sunbaked Canyon" for card in active.graveyard)
        assert not any(card.get("name") == "Sunbaked Canyon" for card in active.battlefield)
        assert any(card.get("name") == "Drawn Card" for card in active.hand)
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "Sunbaked Canyon"
            and data.get("activation_kind") == "sacrifice_draw"
            for event, data in events
        )

    def test_sunbaked_canyon_requires_extra_mana_beyond_its_own_tap_proxy():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {"name": "Sunbaked Canyon", "effect": "land", "type_line": "Land", "produces": "WR", "mana_produced": 1},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(96))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Sunbaked Canyon"
            and data.get("strategic_guardrail_reason") == "too_few_lands_to_sacrifice_draw_land"
            or data.get("strategic_guardrail_reason") == "insufficient_mana_for_sacrifice_draw_land"
            for event, data in events
        )

    def test_sunbaked_canyon_skips_when_it_would_cut_too_deep_on_lands():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {"name": "Sunbaked Canyon", "effect": "land", "type_line": "Land", "produces": "WR", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(93))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert not any(card.get("name") == "Sunbaked Canyon" for card in active.graveyard)
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Sunbaked Canyon"
            and data.get("strategic_guardrail_reason") == "too_few_lands_to_sacrifice_draw_land"
            for event, data in events
        )

    def test_treasure_vault_cashes_in_expendable_land_for_x_treasures():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.battlefield = [
            {
                "name": "Treasure Vault",
                "effect": "treasure_maker",
                "type_line": "Artifact Land",
                "produces": "C",
                "mana_produced": 1,
                "activation_requires_tap": True,
                "activation_requires_sacrifice": True,
                "activation_cost_generic_is_x_twice": True,
                "treasure_count_source": "x_value",
                "treasure_count_per_x": 1,
                "battle_model_scope": "activated_xx_tap_sacrifice_create_x_treasures_v1",
            },
            {"name": "Ancient Tomb", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 2},
            {"name": "Temple of the False God", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 2},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(103))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert active.treasures == 3
        assert any(card.get("name") == "Treasure Vault" for card in active.graveyard)
        assert not any(card.get("name") == "Treasure Vault" for card in active.battlefield)
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "Treasure Vault"
            and data.get("activation_kind") == "treasure_conversion"
            and data.get("x_value") == 3
            and data.get("treasures_created") == 3
            and data.get("mana_paid") == 6
            for event, data in events
        )

    def test_treasure_vault_skips_when_land_base_is_too_shallow():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.battlefield = [
            {
                "name": "Treasure Vault",
                "effect": "treasure_maker",
                "type_line": "Artifact Land",
                "produces": "C",
                "mana_produced": 1,
                "activation_requires_tap": True,
                "activation_requires_sacrifice": True,
                "activation_cost_generic_is_x_twice": True,
                "treasure_count_source": "x_value",
                "treasure_count_per_x": 1,
                "battle_model_scope": "activated_xx_tap_sacrifice_create_x_treasures_v1",
            },
            {"name": "Ancient Tomb", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 2},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(104))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert not any(card.get("name") == "Treasure Vault" for card in active.graveyard)
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Treasure Vault"
            and data.get("strategic_guardrail_reason") == "too_few_lands_to_cash_in_treasure_vault"
            for event, data in events
        )

    def test_inventors_fair_gains_life_on_upkeep_with_three_artifacts():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active", [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}])
        active.life = 30
        active.battlefield = [
            {
                "name": "Inventors' Fair",
                "effect": "land",
                "type_line": "Legendary Land",
                "produces": "C",
                "mana_produced": 1,
            },
            {"name": "Sol Ring", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 2, "produces": "C"},
            {"name": "Arcane Signet", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 1, "produces": "WUBRGC"},
            {"name": "Ancient Den", "effect": "land", "type_line": "Artifact Land", "produces": "W", "mana_produced": 1},
        ]
        opponent = player("Opponent")

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(94),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert active.life == 31
        assert any(
            event == "utility_land_triggered"
            and data.get("card") == "Inventors' Fair"
            and data.get("trigger_kind") == "upkeep_life_gain"
            and data.get("artifact_count") >= 3
            for event, data in events
        )

    def test_inventors_fair_tutors_artifact_when_threshold_and_mana_exist():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [
            {"name": "Aetherflux Reservoir", "cmc": 4, "type_line": "Artifact", "effect": "finisher"},
            {"name": "Drawn Card", "cmc": 2, "type_line": "Instant"},
        ]
        active.battlefield = [
            {
                "name": "Inventors' Fair",
                "effect": "land",
                "type_line": "Legendary Land",
                "produces": "C",
                "mana_produced": 1,
            },
            {"name": "Sol Ring", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 2, "produces": "C"},
            {"name": "Arcane Signet", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 1, "produces": "WUBRGC"},
            {"name": "Ancient Den", "effect": "land", "type_line": "Artifact Land", "produces": "W", "mana_produced": 1},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(95))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert any(card.get("name") == "Inventors' Fair" for card in active.graveyard)
        assert any(card.get("name") == "Aetherflux Reservoir" for card in active.hand)
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "Inventors' Fair"
            and data.get("activation_kind") == "artifact_tutor"
            and data.get("found") == "Aetherflux Reservoir"
            for event, data in events
        )

    def test_inventors_fair_skips_without_artifact_threshold():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [{"name": "Aetherflux Reservoir", "cmc": 4, "type_line": "Artifact", "effect": "finisher"}]
        active.battlefield = [
            {
                "name": "Inventors' Fair",
                "effect": "land",
                "type_line": "Legendary Land",
                "produces": "C",
                "mana_produced": 1,
            },
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            {"name": "Command Tower", "effect": "land", "type_line": "Land", "produces": "WUBRGC", "mana_produced": 1},
            {"name": "Boros Signet", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 1, "produces": "WR"},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(97))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert not any(card.get("name") == "Inventors' Fair" for card in active.graveyard)
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Inventors' Fair"
            and data.get("strategic_guardrail_reason") == "artifact_threshold_not_met_for_inventors_fair"
            for event, data in events
        )

    def test_hall_of_heliods_generosity_recovers_best_enchantment_to_top():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.graveyard = [
            {"name": "Smothering Tithe", "cmc": 4, "type_line": "Enchantment", "effect": "ramp_engine"},
            {"name": "Fiery Emancipation", "cmc": 6, "type_line": "Enchantment", "effect": "passive"},
        ]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {
                "name": "Hall of Heliod's Generosity",
                "effect": "land",
                "type_line": "Legendary Land",
                "produces": "C",
                "mana_produced": 1,
            },
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(98))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert active.library[0]["name"] == "Smothering Tithe"
        assert not any(card.get("name") == "Smothering Tithe" for card in active.graveyard)
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "Hall of Heliod's Generosity"
            and data.get("activation_kind") == "graveyard_enchantment_to_top"
            and data.get("found") == "Smothering Tithe"
            for event, data in events
        )

    def test_hall_of_heliods_generosity_skips_without_white_mana():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.graveyard = [
            {"name": "Smothering Tithe", "cmc": 4, "type_line": "Enchantment", "effect": "ramp_engine"},
        ]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {
                "name": "Hall of Heliod's Generosity",
                "effect": "land",
                "type_line": "Legendary Land",
                "produces": "C",
                "mana_produced": 1,
            },
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            {"name": "Ancient Tomb", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 2},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(99))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert active.library[0]["name"] == "Drawn Card"
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Hall of Heliod's Generosity"
            and data.get("strategic_guardrail_reason") == "missing_white_mana_for_hall_recursion"
            for event, data in events
        )

    def test_ancient_tomb_pays_life_only_when_it_unlocks_contextual_play():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        commander = {
            "name": "Lorehold, the Historian",
            "cmc": 4,
            "type_line": "Legendary Creature — Elder Dragon",
            "color_identity": ["W", "R"],
            "is_commander": True,
        }
        active.command_zone = [commander]
        active.life = 40
        active.battlefield = [
            {"name": "Ancient Tomb", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        active.refresh_mana_sources(turn=3)
        opponent = player("Opponent")

        activations = battle.activate_precombat_utility_mana_lands(
            active,
            [opponent],
            [active, opponent],
            turn=3,
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert active.life == 38
        assert active.available_mana() == 4
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "Ancient Tomb"
            and data.get("activation_kind") == "contextual_fast_mana"
            and data.get("unlock_target") == "Lorehold, the Historian"
            for event, data in events
        )

    def test_ancient_tomb_skips_when_no_relevant_unlock_exists():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.life = 40
        active.hand = [{"name": "Eight Drop", "cmc": 8, "type_line": "Sorcery", "effect": "draw_cards"}]
        active.battlefield = [
            {"name": "Ancient Tomb", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
        ]
        active.refresh_mana_sources(turn=2)
        opponent = player("Opponent")

        activations = battle.activate_precombat_utility_mana_lands(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert active.life == 40
        assert active.available_mana() == 2
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Ancient Tomb"
            and data.get("strategic_guardrail_reason") == "no_contextual_unlock_for_ancient_tomb"
            for event, data in events
        )

    def test_ancient_tomb_skips_when_life_is_too_low():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.life = 8
        active.hand = [{"name": "Arcane Signet", "cmc": 2, "type_line": "Artifact"}]
        active.battlefield = [
            {"name": "Ancient Tomb", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
        ]
        active.refresh_mana_sources(turn=2)
        opponent = player("Opponent")

        activations = battle.activate_precombat_utility_mana_lands(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert active.life == 8
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Ancient Tomb"
            and data.get("strategic_guardrail_reason") == "life_too_low_for_ancient_tomb_acceleration"
            for event, data in events
        )

    def test_chromatic_star_precombat_unlocks_off_color_spell():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        active.hand = [
            {
                "name": "Lightning Bolt",
                "cmc": 1,
                "mana_cost": "{R}",
                "type_line": "Instant",
                "oracle_text": "Lightning Bolt deals 3 damage to any target.",
            }
        ]
        active.battlefield = [
            {
                "name": "Chromatic Star",
                "cmc": 1,
                "type_line": "Artifact",
                "effect": "cantrip_mana_filter_artifact",
                "activation_cost_generic": 1,
                "activation_add_colors": ["white", "blue", "black", "red", "green"],
                "draw_on_self_sacrifice": 1,
                "battle_model_scope": "sacrifice_mana_filter_cantrip_v2",
            },
            {"name": "Wastes", "effect": "land", "type_line": "Basic Land", "produces": "C", "mana_produced": 1},
        ]
        active.library = [_card("Drawn Card", cmc=2, effect="draw_cards")]
        active.refresh_mana_sources(turn=2)

        activations = battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(104),
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert not any(
            permanent.get("name") == "Chromatic Star"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(card.get("name") == "Chromatic Star" for card in active.graveyard)
        assert active.mana_pool.red == 1
        assert any(card.get("name") == "Drawn Card" for card in active.hand)
        assert any(
            event == "utility_artifact_activated"
            and data.get("card") == "Chromatic Star"
            and data.get("activation_kind") == "filter_draw_unlock"
            and data.get("chosen_color") == "red"
            and data.get("unlock_target") == "Lightning Bolt"
            for event, data in events
        )

    def test_chromatic_star_postcombat_cash_in_when_hand_is_low():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        active.hand = []
        active.library = [_card("Refill Card", cmc=2, effect="draw_cards")]
        active.battlefield = [
            {
                "name": "Chromatic Star",
                "cmc": 1,
                "type_line": "Artifact",
                "effect": "cantrip_mana_filter_artifact",
                "activation_cost_generic": 1,
                "activation_add_colors": ["white", "blue", "black", "red", "green"],
                "draw_on_self_sacrifice": 1,
                "battle_model_scope": "sacrifice_mana_filter_cantrip_v2",
            },
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        active.refresh_mana_sources(turn=3)

        activations = battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=3,
            rng=random.Random(105),
            phase="postcombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert any(card.get("name") == "Refill Card" for card in active.hand)
        assert any(card.get("name") == "Chromatic Star" for card in active.graveyard)
        assert any(
            event == "utility_artifact_activated"
            and data.get("card") == "Chromatic Star"
            and data.get("activation_kind") == "cash_in_draw"
            and data.get("cards_drawn") == 1
            for event, data in events
        )

    def test_urzas_saga_enters_with_initial_chapter_state():
        active = player("Active")
        active.hand = [{"name": "Urza's Saga", "cmc": 0, "type_line": "Enchantment Land — Urza's Saga"}]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        opponent = player("Opponent")

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            rng=random.Random(101),
            stack=battle.Stack(),
        )

        saga = next(
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("name") == "Urza's Saga"
        )
        assert saga["effect"] == "land"
        assert saga["lore_counters"] == 1
        assert saga["current_chapter"] == 1
        assert saga["final_chapter"] == 3
        assert saga["saga_last_lore_turn"] == 1

    def test_urzas_saga_creates_construct_on_chapter_two():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.battlefield = [
            {
                "name": "Urza's Saga",
                "effect": "land",
                "type_line": "Enchantment Land — Urza's Saga",
                "produces": "C",
                "mana_produced": 1,
                "lore_counters": 2,
                "current_chapter": 2,
                "final_chapter": 3,
            },
            {"name": "Sol Ring", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 2, "produces": "C"},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(102))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        construct = next(
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("urzas_saga_construct")
        )
        assert construct["name"] == "Construct Token"
        assert construct["type_line"] == "Artifact Creature Token — Construct"
        assert construct["power"] == 2
        assert construct["toughness"] == 2
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "Urza's Saga"
            and data.get("activation_kind") == "construct_token"
            and data.get("artifact_count_after") == 2
            for event, data in events
        )

    def test_urzas_saga_tutors_safe_artifact_then_sacrifices():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [
            {"name": "Sol Ring", "cmc": 1, "type_line": "Artifact", "effect": "ramp_permanent"},
            {"name": "Mox Diamond", "cmc": 0, "type_line": "Artifact", "oracle_text": "If Mox Diamond would enter the battlefield, discard a land card instead. If you do, put Mox Diamond onto the battlefield. If you don't, put it into its owner's graveyard."},
            {"name": "Drawn Card", "cmc": 2, "type_line": "Instant"},
        ]
        active.battlefield = [
            {
                "name": "Urza's Saga",
                "effect": "land",
                "type_line": "Enchantment Land — Urza's Saga",
                "produces": "C",
                "mana_produced": 1,
                "lore_counters": 2,
                "current_chapter": 2,
                "final_chapter": 3,
                "saga_last_lore_turn": 2,
            },
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        opponent = player("Opponent")

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=3,
            rng=random.Random(103),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert any(card.get("name") == "Sol Ring" for card in active.battlefield if isinstance(card, dict))
        assert not any(card.get("name") == "Mox Diamond" for card in active.battlefield if isinstance(card, dict))
        assert any(card.get("name") == "Urza's Saga" for card in active.graveyard if isinstance(card, dict))
        assert any(
            event == "saga_chapter_progressed"
            and data.get("card") == "Urza's Saga"
            and data.get("chapter") == 3
            for event, data in events
        )
        assert any(
            event == "saga_chapter_resolved"
            and data.get("card") == "Urza's Saga"
            and data.get("found") == "Sol Ring"
            for event, data in events
        )
        assert any(
            event == "saga_sacrificed_by_sba"
            and data.get("card") == "Urza's Saga"
            and data.get("final_chapter") == 3
            for event, data in events
        )

    def test_land_tutor_artifact_trace_scores_rejected_options():
        decisions = []
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            active = player("Lorehold")
            active.battlefield = [
                {
                    "name": "Wayfarer's Bauble",
                    "cmc": 1,
                    "type_line": "Artifact",
                    "effect": "land_ramp",
                    "activated_self_sacrifice_land_tutor": True,
                    "activation_cost_generic": 2,
                },
                {"name": "Plains", "effect": "land", "type_line": "Basic Land - Plains"},
                {"name": "Mountain", "effect": "land", "type_line": "Basic Land - Mountain"},
            ]
            active.library = [
                {"name": "Plains", "cmc": 0, "type_line": "Basic Land - Plains"},
                {"name": "Mountain", "cmc": 0, "type_line": "Basic Land - Mountain"},
                {"name": "Plains", "cmc": 0, "type_line": "Basic Land - Plains"},
            ]
            active.refresh_mana_sources(turn=2)

            battle.activate_land_tutor_creatures(active, turn=2)
        finally:
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        trace = next(
            decision
            for decision in decisions
            if decision.get("decision_type") == "utility_artifact_activation"
            and decision.get("chosen_option", {}).get("action") == "activate_land_tutor_artifact"
        )
        assert trace["best_rejected_option_score"] is not None
        assert trace["score_gap_vs_best_rejected"] is not None
        assert trace["rejected_option_scores"]

    def test_angels_grace_prevents_lethal_damage_and_life_zero_loss_this_turn():
        active = player("Protected")
        active.life = 3
        grace = {"name": "Angel's Grace", "cmc": 1, "type_line": "Instant"}
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with sqlite3.connect(db_path) as conn:
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Angel's Grace",
                    {
                        "effect": "cannot_lose_turn",
                        "instant": True,
                        "life_floor_on_damage": 1,
                    },
                    source="curated",
                    confidence=1.0,
                    review_status="verified",
                )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.apply_effect_immediate(active, [], grace, 2, random.Random(104))
                dealt = battle.deal_damage(active, 10)
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        assert dealt is True
        assert active.life == 1
        battle.check_sbas([active])
        assert active.eliminated is False
        assert active.is_alive() is True

    def test_angels_grace_blocks_opponent_approach_win_this_turn():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        protected = player("Protected")
        protected.life = 5
        opponent = player("Approach Player")
        opponent.approach_count = 1
        grace = {"name": "Angel's Grace", "cmc": 1, "type_line": "Instant"}
        approach = {
            "name": "Approach of the Second Sun",
            "cmc": 7,
            "type_line": "Sorcery",
        }
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with sqlite3.connect(db_path) as conn:
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Angel's Grace",
                    {
                        "effect": "cannot_lose_turn",
                        "instant": True,
                        "life_floor_on_damage": 1,
                    },
                    source="curated",
                    confidence=1.0,
                    review_status="verified",
                )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.apply_effect_immediate(protected, [opponent], grace, 2, random.Random(105))
                battle.apply_effect_immediate(opponent, [protected], approach, 2, random.Random(105))
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.REPLAY_EVENT_HANDLER = None

        assert opponent.has_won() is False
        assert any(event == "game_win_prevented" for event, _ in events)

    def test_senseis_top_sets_up_lorehold_approach_second_cast():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            lorehold = player("Lorehold")
            lorehold.is_human = True
            lorehold.approach_count = 1
            top_card = {
                "name": "Sensei's Divining Top",
                "cmc": 1,
                "type_line": "Artifact",
            }
            top_effect = battle.get_card_effect(top_card)
            assert top_effect["effect"] == "topdeck_manipulation"
            assert top_effect["peek_top_count"] == 3
            assert top_effect["reorder_top"] is True
            assert top_effect["reorder_top_status"] == "lorehold_first_draw_planning_executor"
            assert top_effect["activated_draw_put_self_on_top"] is True
            assert top_effect["activated_draw_put_self_on_top_status"] == (
                "lorehold_first_draw_miracle_window_executor"
            )
            assert top_effect["generic_draw_activation_status"] == "annotation_only"
            assert top_effect["battle_model_scope"] == (
                "senseis_top_reorder_draw_lorehold_first_draw_miracle_v1"
            )
            assert top_effect["_rule_logical_key"] == "battle_rule_v1:70c8478871f352b46cee1af296117951"
            assert top_effect["_rule_oracle_hash"] == "f2c5ac0f52963cd710470adc25cc6d7c"
            top_permanent = {
                **top_card,
                **top_effect,
            }
            lorehold.battlefield = [
                {
                    "name": "Lorehold, the Historian",
                    "effect": "creature",
                    "type_line": "Legendary Creature",
                    "haste": True,
                },
                top_permanent,
                {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
                {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
                {"name": "Sacred Foundry", "effect": "land", "type_line": "Land"},
            ]
            lorehold.hand = [
                {
                    "name": "Nine Mana Spell",
                    "cmc": 9,
                    "type_line": "Sorcery",
                    "effect": "draw_cards",
                }
            ]
            lorehold.library = [
                {"name": "Small Creature", "cmc": 2, "type_line": "Creature", "effect": "creature"},
                {
                    "name": "Approach of the Second Sun",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                {"name": "Mountain", "cmc": 0, "type_line": "Land", "effect": "land"},
            ]
            opponent = player("Opponent")
            opponent.library = [_card("Opponent Draw", cmc=1)]
            lorehold.refresh_mana_sources(turn=6)

            triggered = battle.process_lorehold_opponent_upkeep_rummage(
                opponent,
                [lorehold, opponent],
                6,
                random.Random(123),
                battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert triggered == 1
        assert lorehold.has_won() is True
        assert lorehold.win_reason == "approach"
        assert [card.get("name") for card in lorehold.graveyard] == [
            "Nine Mana Spell",
            "Approach of the Second Sun",
        ]
        assert any(
            event == "topdeck_manipulation_activated"
            and data.get("card") == "Sensei's Divining Top"
            and data.get("top_before") == "Small Creature"
            and data.get("top_after") == "Approach of the Second Sun"
            and data.get("rule_logical_key") == "battle_rule_v1:70c8478871f352b46cee1af296117951"
            and data.get("rule_oracle_hash") == "f2c5ac0f52963cd710470adc25cc6d7c"
            for event, data in events
        )
        assert any(
            event == "lorehold_upkeep_rummage"
            and data.get("drawn") == "Approach of the Second Sun"
            and data.get("discarded") == "Nine Mana Spell"
            for event, data in events
        )
        assert any(
            event == "miracle_cast"
            and data.get("card") == "Approach of the Second Sun"
            and data.get("source") == "lorehold_opponent_upkeep_rummage"
            and data.get("rule_review_status") == "active"
            for event, data in events
        )
        assert any(
            event == "game_won"
            and data.get("player") == "Lorehold"
            and data.get("reason") == "approach"
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "utility_artifact_activation"
            and decision.get("chosen_option", {}).get("card") == "Approach of the Second Sun"
            and decision.get("actual_outcome") == "topdeck_reordered_for_first_draw"
            and "topdeck_reorder" in decision.get("risk_flags", [])
            for decision in decisions
        )
        assert any(
            decision.get("decision_type") == "lorehold_upkeep_rummage"
            and decision.get("chosen_option", {}).get("card") == "Nine Mana Spell"
            and decision.get("actual_outcome") == "discard_then_draw"
            for decision in decisions
        )

    def test_scroll_rack_sets_up_lorehold_approach_second_cast_on_opponent_upkeep():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            lorehold = player("Lorehold")
            lorehold.is_human = True
            lorehold.approach_count = 1
            rack_card = {
                "name": "Scroll Rack",
                "cmc": 2,
                "type_line": "Artifact",
            }
            rack_permanent = {
                **rack_card,
                **battle.get_card_effect(rack_card),
            }
            lorehold.battlefield = [
                {
                    "name": "Lorehold, the Historian",
                    "effect": "creature",
                    "type_line": "Legendary Creature",
                    "haste": True,
                },
                rack_permanent,
                {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
                {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
                {"name": "Sacred Foundry", "effect": "land", "type_line": "Land"},
            ]
            lorehold.hand = [
                {
                    "name": "Approach of the Second Sun",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                {
                    "name": "Nine Mana Spell",
                    "cmc": 9,
                    "type_line": "Sorcery",
                    "effect": "draw_cards",
                },
            ]
            lorehold.library = [
                {"name": "Small Creature", "cmc": 2, "type_line": "Creature", "effect": "creature"},
                {"name": "Mountain", "cmc": 0, "type_line": "Land", "effect": "land"},
            ]
            opponent = player("Opponent")
            opponent.library = [_card("Opponent Draw", cmc=1)]
            lorehold.refresh_mana_sources(turn=6)

            triggered = battle.process_lorehold_opponent_upkeep_rummage(
                opponent,
                [lorehold, opponent],
                6,
                random.Random(124),
                battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert triggered == 1
        assert lorehold.has_won() is True
        assert lorehold.win_reason == "approach"
        assert any(
            event == "topdeck_manipulation_activated"
            and data.get("card") == "Scroll Rack"
            and data.get("activation_kind") == "scroll_rack_single_exchange_for_lorehold"
            and data.get("top_before") == "Small Creature"
            and data.get("top_after") == "Approach of the Second Sun"
            and data.get("phase") == "opponent_upkeep"
            for event, data in events
        )
        assert any(
            event == "lorehold_upkeep_rummage"
            and data.get("drawn") == "Approach of the Second Sun"
            and data.get("discarded") == "Nine Mana Spell"
            for event, data in events
        )
        assert any(
            event == "miracle_cast"
            and data.get("card") == "Approach of the Second Sun"
            and data.get("source") == "lorehold_opponent_upkeep_rummage"
            for event, data in events
        )
        assert any(
            event == "game_won"
            and data.get("player") == "Lorehold"
            and data.get("reason") == "approach"
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "utility_artifact_activation"
            and decision.get("chosen_option", {}).get("card") == "Approach of the Second Sun"
            and decision.get("chosen_option", {}).get("action") == "activate_scroll_rack_exchange"
            and decision.get("actual_outcome") == "hand_spell_moved_to_top_for_next_draw"
            for decision in decisions
        )

    def test_brainstone_first_draw_approach_wins_before_rummage_resolution():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            lorehold = player("Lorehold")
            lorehold.is_human = True
            lorehold.approach_count = 1
            brainstone_card = {
                "name": "Brainstone",
                "cmc": 1,
                "type_line": "Artifact",
            }
            brainstone_permanent = {
                **brainstone_card,
                **battle.get_card_effect(brainstone_card),
            }
            lorehold.battlefield = [
                {
                    "name": "Lorehold, the Historian",
                    "effect": "creature",
                    "type_line": "Legendary Creature",
                    "haste": True,
                },
                brainstone_permanent,
                {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
                {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
                {"name": "Sacred Foundry", "effect": "land", "type_line": "Land"},
                {"name": "Clifftop Retreat", "effect": "land", "type_line": "Land"},
            ]
            lorehold.hand = [
                {
                    "name": "Nine Mana Spell",
                    "cmc": 9,
                    "type_line": "Sorcery",
                    "effect": "draw_cards",
                },
                {"name": "Small Creature", "cmc": 2, "type_line": "Creature", "effect": "creature"},
            ]
            lorehold.library = [
                {
                    "name": "Approach of the Second Sun",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                {"name": "Filler Draw A", "cmc": 3, "type_line": "Creature", "effect": "creature"},
                {"name": "Filler Draw B", "cmc": 4, "type_line": "Sorcery", "effect": "draw_cards"},
                {"name": "Mountain", "cmc": 0, "type_line": "Land", "effect": "land"},
            ]
            opponent = player("Opponent")
            opponent.library = [_card("Opponent Draw", cmc=1)]
            lorehold.refresh_mana_sources(turn=6)

            triggered = battle.process_lorehold_opponent_upkeep_rummage(
                opponent,
                [lorehold, opponent],
                6,
                random.Random(125),
                battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert triggered == 0
        assert lorehold.has_won() is True
        assert lorehold.win_reason == "approach"
        assert any(card.get("name") == "Brainstone" for card in lorehold.graveyard)
        assert any(card.get("name") == "Approach of the Second Sun" for card in lorehold.graveyard)
        assert any(
            event == "topdeck_manipulation_activated"
            and data.get("card") == "Brainstone"
            and data.get("activation_kind") == "brainstone_draw_three_put_two_back_for_miracle"
            and data.get("first_draw") == "Approach of the Second Sun"
            and len(data.get("putback") or []) == 2
            for event, data in events
        )
        assert any(
            event == "miracle_cast"
            and data.get("card") == "Approach of the Second Sun"
            and data.get("source") == "brainstone_first_draw"
            for event, data in events
        )
        assert any(
            event == "game_won"
            and data.get("player") == "Lorehold"
            and data.get("reason") == "approach"
            for event, data in events
        )
        assert not any(event == "lorehold_upkeep_rummage" for event, _ in events)
        assert any(
            decision.get("decision_type") == "utility_artifact_activation"
            and decision.get("chosen_option", {}).get("card") == "Approach of the Second Sun"
            and decision.get("chosen_option", {}).get("action") == "activate_brainstone_for_first_draw_miracle"
            and decision.get("actual_outcome") == "brainstone_first_draw_miracle_window"
            and "sacrifice_artifact" in decision.get("risk_flags", [])
            for decision in decisions
        )

    def test_lorehold_upkeep_rummage_preserves_approach_without_top_replacement():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            lorehold = player("Lorehold")
            lorehold.is_human = True
            lorehold.battlefield = [
                {
                    "name": "Lorehold, the Historian",
                    "effect": "creature",
                    "type_line": "Legendary Creature",
                    "haste": True,
                },
                {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
                {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
                {"name": "Sacred Foundry", "effect": "land", "type_line": "Land"},
            ]
            lorehold.hand = [
                {
                    "name": "Approach of the Second Sun",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                {"name": "Boros Charm", "cmc": 2, "type_line": "Instant", "effect": "protection"},
            ]
            lorehold.library = [{"name": "Filler Draw", "cmc": 2, "type_line": "Creature", "effect": "creature"}]
            opponent = player("Opponent")
            opponent.library = [_card("Opponent Draw", cmc=1)]
            lorehold.refresh_mana_sources(turn=6)

            triggered = battle.process_lorehold_opponent_upkeep_rummage(
                opponent,
                [lorehold, opponent],
                6,
                random.Random(126),
                battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert triggered == 0
        assert any(card.get("name") == "Approach of the Second Sun" for card in lorehold.hand)
        assert not any(event == "lorehold_upkeep_rummage" for event, _ in events)
        assert any(
            event == "lorehold_upkeep_rummage_skipped"
            and data.get("reason") == "no_strategic_discard_candidate"
            for event, data in events
        )
        assert not any(decision.get("decision_type") == "lorehold_upkeep_rummage" for decision in decisions)

    def test_low_life_casts_approach_before_proactive_attack_tax():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            active = player("Lorehold")
            active.life = 10
            active.is_human = True
            active.hand = [
                {
                    "name": "Approach of the Second Sun",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                {
                    "name": "Windborn Muse",
                    "cmc": 4,
                    "type_line": "Creature — Spirit",
                    "effect": "attack_tax",
                },
            ]
            active.battlefield = [
                {
                    "name": "Plains",
                    "effect": "land",
                    "type_line": "Basic Land — Plains",
                    "mana_produced": 1,
                }
                for _ in range(7)
            ]
            active.refresh_mana_sources(turn=8)
            opponent = player("Opponent")

            acted = battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                8,
                "precombat_main",
                battle.Stack(),
                random.Random(127),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert acted is True
        assert active.approach_count == 1
        assert active.life == 17
        assert not any(card.get("name") == "Approach of the Second Sun" for card in active.hand)
        assert any(card.get("name") == "Windborn Muse" for card in active.hand)
        assert any(
            event == "spell_cast"
            and data.get("card") == "Approach of the Second Sun"
            and data.get("role") == "high_threat"
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "cast_spell"
            and decision.get("chosen_option", {}).get("card") == "Approach of the Second Sun"
            and decision.get("actual_outcome") == "cast_to_stack"
            for decision in decisions
        )

    def test_grand_abolisher_casts_as_setup_for_future_approach():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            active = player("Lorehold")
            active.life = 23
            active.is_human = True
            active.hand = [
                {
                    "name": "Grand Abolisher",
                    "cmc": 2,
                    "type_line": "Creature — Human Cleric",
                    "effect": "silence_opponents",
                },
                {
                    "name": "Approach of the Second Sun",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
            ]
            active.battlefield = [
                {
                    "name": "Plains",
                    "effect": "land",
                    "type_line": "Basic Land — Plains",
                    "mana_produced": 1,
                },
                {
                    "name": "Command Tower",
                    "effect": "land",
                    "type_line": "Land",
                    "mana_produced": 1,
                },
            ]
            active.refresh_mana_sources(turn=7)
            opponent = player("Opponent")

            acted = battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                7,
                "precombat_main",
                battle.Stack(),
                random.Random(128),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert acted is True
        assert any(card.get("name") == "Grand Abolisher" for card in active.battlefield)
        assert any(card.get("name") == "Approach of the Second Sun" for card in active.hand)
        assert any(
            event == "spell_cast"
            and data.get("card") == "Grand Abolisher"
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "cast_spell"
            and decision.get("chosen_option", {}).get("card") == "Grand Abolisher"
            for decision in decisions
        )

    def test_orims_chant_held_without_castable_second_approach_payoff():
        events = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            active = player("Lorehold")
            active.is_human = True
            active.approach_count = 1
            active.hand = [
                {
                    "name": "Orim's Chant",
                    "cmc": 1,
                    "type_line": "Instant",
                    "effect": "silence_spell",
                    "instant": True,
                }
            ]
            active.battlefield = [
                {
                    "name": "Plains",
                    "effect": "land",
                    "type_line": "Basic Land — Plains",
                    "mana_produced": 1,
                },
                {
                    "name": "Command Tower",
                    "effect": "land",
                    "type_line": "Land",
                    "mana_produced": 1,
                },
            ]
            active.refresh_mana_sources(turn=10)
            opponent = player("Opponent")

            assert battle.has_immediate_silence_payoff(active, "precombat_main") is False
            acted = battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                10,
                "precombat_main",
                battle.Stack(),
                random.Random(129),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler

        assert acted is False
        assert [card.get("name") for card in active.hand] == ["Orim's Chant"]
        assert not any(
            event == "spell_cast"
            and data.get("card") == "Orim's Chant"
            for event, data in events
        )

    def test_cleanup_discard_preserves_attack_tax_over_excess_cards():
        active = player("Lorehold")
        active.hand = [
            {
                "name": "Sphere of Safety",
                "cmc": 5,
                "type_line": "Enchantment",
                "effect": "attack_tax",
            },
            {
                "name": "Seven Mana Filler",
                "cmc": 7,
                "type_line": "Sorcery",
                "effect": "unknown",
            },
            {
                "name": "Flawless Maneuver",
                "cmc": 3,
                "type_line": "Instant",
                "effect": "indestructible",
            },
            {
                "name": "Spectator Seating",
                "cmc": 0,
                "type_line": "Land",
                "effect": "land",
            },
            {
                "name": "War Room",
                "cmc": 0,
                "type_line": "Land",
                "effect": "land",
            },
            {
                "name": "Urza's Saga",
                "cmc": 0,
                "type_line": "Enchantment Land — Urza's Saga",
                "effect": "land",
            },
            {
                "name": "Pyroblast",
                "cmc": 1,
                "type_line": "Instant",
                "effect": "counter",
            },
            {
                "name": "Drannith Magistrate",
                "cmc": 2,
                "type_line": "Creature — Human Wizard",
                "effect": "creature",
            },
            {
                "name": "Get Lost",
                "cmc": 2,
                "type_line": "Instant",
                "effect": "remove_permanent",
            },
            {
                "name": "Giver of Runes",
                "cmc": 1,
                "type_line": "Creature — Kor Cleric",
                "effect": "creature",
            },
        ]
        active.battlefield = [
            {"name": f"Land {index}", "cmc": 0, "type_line": "Land", "effect": "land"}
            for index in range(4)
        ]

        discarded = []
        while len(active.hand) > 7:
            chosen = battle.choose_cleanup_discard(active)
            discarded.append(chosen.get("name"))
            active.hand.remove(chosen)

        kept = [card.get("name") for card in active.hand]
        assert "Sphere of Safety" in kept
        assert "Seven Mana Filler" in discarded
        assert sum(1 for name in discarded if name in {"Spectator Seating", "War Room", "Urza's Saga"}) == 2

    def test_enlightened_tutor_puts_artifact_or_enchantment_on_library_top():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            spell = {"name": "Enlightened Tutor", "cmc": 1, "type_line": "Instant"}
            active.hand = [spell]
            active.library = [
                {"name": "Filler Spell", "cmc": 2, "type_line": "Sorcery"},
                {"name": "Sol Ring", "cmc": 1, "type_line": "Artifact", "effect": "ramp_permanent"},
            ]

            battle.apply_effect_immediate(
                active,
                [opponent],
                spell,
                turn=2,
                rng=random.Random(6081),
                effect_data_override={
                    "effect": "tutor",
                    "target": "artifact_or_enchantment_to_top",
                    "instant": True,
                    "battle_model_scope": "test_artifact_enchantment_to_library_top",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert active.library[0]["name"] == "Sol Ring"
        assert all(card.get("name") != "Sol Ring" for card in active.hand)
        assert any(
            event == "tutor_resolved"
            and data.get("card") == "Enlightened Tutor"
            and data.get("found") == "Sol Ring"
            and data.get("destination") == "library_top"
            for event, data in events
        )

    def test_idyllic_tutor_finds_enchantment_to_hand_only():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            spell = {"name": "Idyllic Tutor", "cmc": 3, "type_line": "Sorcery"}
            active.hand = [spell]
            active.library = [
                {"name": "Sol Ring", "cmc": 1, "type_line": "Artifact", "effect": "ramp_permanent"},
                {"name": "Smothering Tithe", "cmc": 4, "type_line": "Enchantment", "effect": "ramp_engine"},
            ]

            battle.apply_effect_immediate(
                active,
                [opponent],
                spell,
                turn=3,
                rng=random.Random(6082),
                effect_data_override={
                    "effect": "tutor",
                    "target": "enchantment",
                    "sorcery": True,
                    "battle_model_scope": "test_enchantment_to_hand",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert any(card.get("name") == "Smothering Tithe" for card in active.hand)
        assert any(card.get("name") == "Sol Ring" for card in active.library)
        assert any(
            event == "tutor_resolved"
            and data.get("card") == "Idyllic Tutor"
            and data.get("found") == "Smothering Tithe"
            and data.get("destination") == "hand"
            for event, data in events
        )

    def test_goblin_engineer_etb_tutors_artifact_to_graveyard():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.library = [
                {"name": "Filler Spell", "cmc": 2, "type_line": "Sorcery"},
                {"name": "The One Ring", "cmc": 4, "type_line": "Legendary Artifact", "effect": "draw_engine"},
            ]

            battle.apply_effect_immediate(
                active,
                [opponent],
                {
                    "name": "Goblin Engineer",
                    "cmc": 2,
                    "type_line": "Creature - Goblin Artificer",
                    "power": 1,
                    "toughness": 2,
                },
                turn=3,
                rng=random.Random(6083),
                effect_data_override={
                    "effect": "creature",
                    "is_creature_permanent": True,
                    "power": 1,
                    "toughness": 2,
                    "etb_tutor_target": "artifact_to_graveyard",
                    "battle_model_scope": "test_artifact_to_graveyard_etb",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert any(card.get("name") == "Goblin Engineer" for card in active.battlefield)
        assert any(card.get("name") == "The One Ring" for card in active.graveyard)
        assert all(card.get("name") != "The One Ring" for card in active.hand)
        assert any(
            event == "tutor_resolved"
            and data.get("card") == "Goblin Engineer"
            and data.get("found") == "The One Ring"
            and data.get("destination") == "graveyard"
            and data.get("trigger") == "enters_battlefield"
            for event, data in events
        )

    def test_imperial_recruiter_etb_tutors_power_two_creature_to_hand():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.library = [
                {
                    "name": "Craterhoof Behemoth",
                    "cmc": 8,
                    "type_line": "Creature - Beast",
                    "power": 5,
                    "toughness": 5,
                },
                {
                    "name": "Esper Sentinel",
                    "cmc": 1,
                    "type_line": "Artifact Creature - Human Soldier",
                    "power": 1,
                    "toughness": 1,
                },
            ]

            battle.apply_effect_immediate(
                active,
                [opponent],
                {
                    "name": "Imperial Recruiter",
                    "cmc": 3,
                    "type_line": "Creature - Human Advisor",
                    "power": 1,
                    "toughness": 1,
                },
                turn=3,
                rng=random.Random(6084),
                effect_data_override={
                    "effect": "creature",
                    "is_creature_permanent": True,
                    "power": 1,
                    "toughness": 1,
                    "etb_tutor_target": "creature_power_lte_2",
                    "battle_model_scope": "test_power_lte_2_creature_to_hand_etb",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert any(card.get("name") == "Imperial Recruiter" for card in active.battlefield)
        assert any(card.get("name") == "Esper Sentinel" for card in active.hand)
        assert any(card.get("name") == "Craterhoof Behemoth" for card in active.library)
        assert any(
            event == "tutor_resolved"
            and data.get("card") == "Imperial Recruiter"
            and data.get("found") == "Esper Sentinel"
            and data.get("destination") == "hand"
            and data.get("trigger") == "enters_battlefield"
            for event, data in events
        )

    def test_recruiter_of_the_guard_etb_tutors_toughness_two_creature_to_hand():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.library = [
                {
                    "name": "Craterhoof Behemoth",
                    "cmc": 8,
                    "type_line": "Creature - Beast",
                    "power": 5,
                    "toughness": 5,
                },
                {
                    "name": "Esper Sentinel",
                    "cmc": 1,
                    "type_line": "Artifact Creature - Human Soldier",
                    "power": 1,
                    "toughness": 1,
                },
            ]

            battle.apply_effect_immediate(
                active,
                [opponent],
                {
                    "name": "Recruiter of the Guard",
                    "cmc": 3,
                    "type_line": "Creature - Human Soldier",
                    "power": 1,
                    "toughness": 1,
                },
                turn=3,
                rng=random.Random(6085),
                effect_data_override={
                    "effect": "creature",
                    "is_creature_permanent": True,
                    "power": 1,
                    "toughness": 1,
                    "etb_tutor_target": "creature_toughness_lte_2",
                    "battle_model_scope": "test_toughness_lte_2_creature_to_hand_etb",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert any(card.get("name") == "Recruiter of the Guard" for card in active.battlefield)
        assert any(card.get("name") == "Esper Sentinel" for card in active.hand)
        assert any(card.get("name") == "Craterhoof Behemoth" for card in active.library)
        assert any(
            event == "tutor_resolved"
            and data.get("card") == "Recruiter of the Guard"
            and data.get("found") == "Esper Sentinel"
            and data.get("destination") == "hand"
            and data.get("trigger") == "enters_battlefield"
            for event, data in events
        )

    def test_natural_order_sacrifices_green_creature_for_green_battlefield_tutor():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        natural_order = {
            "name": "Natural Order",
            "cmc": 4,
            "type_line": "Sorcery",
        }
        active.hand = [natural_order]
        active.battlefield = [
            {
                "name": "Llanowar Elves",
                "effect": "creature",
                "type_line": "Creature — Elf Druid",
                "power": 1,
                "toughness": 1,
                "color_identity": ["G"],
            },
            {
                "name": "Esper Sentinel",
                "effect": "creature",
                "type_line": "Artifact Creature — Human Soldier",
                "power": 1,
                "toughness": 1,
                "color_identity": ["W"],
            },
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
        ]
        active.library = [
            {
                "name": "Craterhoof Behemoth",
                "cmc": 8,
                "type_line": "Creature — Beast",
                "power": 5,
                "toughness": 5,
                "color_identity": ["G"],
            }
        ]
        active.refresh_mana_sources(turn=4)

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(106),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is True
        assert any(card.get("name") == "Llanowar Elves" for card in active.graveyard)
        assert any(
            permanent.get("name") == "Craterhoof Behemoth"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(
            event == "additional_cost_paid"
            and data.get("card") == "Natural Order"
            and data.get("cost") == "sacrifice_green_creature"
            and data.get("sacrificed") == "Llanowar Elves"
            for event, data in events
        )
        assert not any(
            event == "additional_cost_paid"
            and data.get("card") == "Natural Order"
            and data.get("sacrificed") == "Esper Sentinel"
            for event, data in events
        )

    def test_natural_order_does_not_cast_without_green_creature_to_sacrifice():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        natural_order = {
            "name": "Natural Order",
            "cmc": 4,
            "type_line": "Sorcery",
        }
        active.hand = [natural_order]
        active.battlefield = [
            {
                "name": "Esper Sentinel",
                "effect": "creature",
                "type_line": "Artifact Creature — Human Soldier",
                "power": 1,
                "toughness": 1,
                "color_identity": ["W"],
            },
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
        ]
        active.library = [
            {
                "name": "Craterhoof Behemoth",
                "cmc": 8,
                "type_line": "Creature — Beast",
                "power": 5,
                "toughness": 5,
                "color_identity": ["G"],
            }
        ]
        active.refresh_mana_sources(turn=4)

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(107),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is False
        assert natural_order in active.hand
        assert any(
            permanent.get("name") == "Esper Sentinel"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert not any(
            event == "additional_cost_paid"
            and data.get("card") == "Natural Order"
            for event, data in events
        )

    def test_dismember_applies_stat_modifier_and_kills_indestructible_zero_toughness():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        target = {
            "name": "Indestructible Threat",
            "effect": "creature",
            "type_line": "Creature",
            "power": 5,
            "toughness": 5,
            "indestructible": True,
        }
        opponent.battlefield = [target]
        dismember = {
            "name": "Dismember",
            "cmc": 3,
            "type_line": "Instant",
            "mana_cost": "{1}{B/P}{B/P}",
            "effect": "remove_creature",
            "target": "creature",
            "instant": True,
            "power_boost": -5,
            "toughness_boost": -5,
            "uses_stat_modifier_removal": True,
            "_rule_source": "curated",
            "_rule_review_status": "verified",
        }

        battle.apply_effect_immediate(
            active,
            [opponent],
            dismember,
            turn=3,
            rng=random.Random(108),
        )
        battle.check_sbas_until_stable([active, opponent])
        battle.REPLAY_EVENT_HANDLER = None

        assert target not in opponent.battlefield
        assert target in opponent.graveyard
        assert any(
            event == "removal_resolved"
            and data.get("card") == "Dismember"
            and data.get("result") == "stat_modifier_until_eot_applied"
            and data.get("toughness_delta") == -5
            for event, data in events
        )

    def test_ashnods_altar_sacrifices_token_only_for_contextual_mana_unlock():
        events = []
        decisions = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        active = player("Active")
        opponent = player("Opponent")
        token = battle.create_creature_token(
            active,
            name="Servo Token",
            power=1,
            toughness=1,
        )
        altar = {
            "name": "Ashnod's Altar",
            "cmc": 3,
            "type_line": "Artifact",
            "effect": "sacrifice_mana_outlet",
            "activated_mana_ability": True,
            "activation_cost": "sacrifice_creature",
            "mana_produced": 2,
            "produces": "C",
            "_rule_source": "focused_test",
            "_rule_review_status": "verified",
        }
        active.battlefield.extend(
            [
                altar,
                {"name": "Wastes", "effect": "land", "type_line": "Basic Land", "produces": "C", "mana_produced": 1},
            ]
        )
        active.hand = [
            {
                "name": "Approach of the Second Sun",
                "cmc": 7,
                "mana_cost": "{3}",
                "type_line": "Sorcery",
            }
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_sacrifice_mana_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None
        battle.DECISION_TRACE_HANDLER = None

        assert activations == 1
        assert active.available_mana() == 3
        assert token not in active.battlefield
        assert altar in active.battlefield
        assert any(
            event == "utility_artifact_activated"
            and data.get("card") == "Ashnod's Altar"
            and data.get("activation_kind") == "sacrifice_creature_for_mana_unlock"
            and data.get("sacrificed") == "Servo Token"
            and data.get("unlock_target") == "Approach of the Second Sun"
            and data.get("mana_added") == 2
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "utility_artifact_activation"
            and decision.get("chosen_option", {}).get("action") == "activate_sacrifice_mana_artifact"
            and decision.get("chosen_option", {}).get("card") == "Approach of the Second Sun"
            and "sacrifice_creature" in decision.get("risk_flags", [])
            for decision in decisions
        )

    def test_goblin_bombardment_sacrifices_expendable_token_for_damage():
        events = []
        decisions = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        active = player("Active")
        opponent = player("Opponent")
        opponent.life = 3
        token = battle.create_creature_token(
            active,
            name="Goblin Token",
            power=1,
            toughness=1,
        )
        outlet = {
            "name": "Goblin Bombardment",
            "cmc": 2,
            "type_line": "Enchantment",
            "effect": "sacrifice_damage_outlet",
            "activated_sacrifice_creature_damage": True,
            "damage": 1,
            "_rule_source": "focused_test",
            "_rule_review_status": "needs_review",
        }
        active.battlefield.append(outlet)

        activations = battle.activate_sacrifice_damage_outlets(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            rng=random.Random(109),
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None
        battle.DECISION_TRACE_HANDLER = None

        assert activations == 1
        assert opponent.life == 2
        assert token not in active.battlefield
        assert token not in active.graveyard
        assert outlet in active.battlefield
        assert any(
            event == "activated_ability"
            and data.get("card") == "Goblin Bombardment"
            and data.get("activation_kind") == "sacrifice_creature_damage"
            and data.get("sacrificed") == "Goblin Token"
            and data.get("target") == "Opponent"
            and data.get("damage_dealt") == 1
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "activated_sacrifice_damage"
            and decision.get("chosen_option", {}).get("card") == "Goblin Token"
            for decision in decisions
        )

    def test_goblin_bombardment_review_only_snapshot_does_not_remove_on_cast():
        events = []
        fixture_name = "Review-Only Bombardment Fixture"
        previous_handler = battle.REPLAY_EVENT_HANDLER
        previous_entry = battle.KNOWN_CARDS.get(fixture_name)
        had_fallback = fixture_name in battle.CANONICAL_FALLBACK_KNOWN_CARDS
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.KNOWN_CARDS[fixture_name] = {
            "effect": "remove_creature",
            "cmc": 2,
            "battle_rule_source": "generated",
            "battle_rule_review_status": "needs_review",
            "battle_rule_execution_status": "review_only",
            "battle_rule_confidence": 0.55,
            "battle_rule_logical_key": "battle_rule_v1:test_review_only_bombardment",
            "battle_rule_version": 1,
        }
        battle.CANONICAL_FALLBACK_KNOWN_CARDS.add(fixture_name)
        try:
            active = player("Active")
            opponent = player("Lorehold")
            lorehold = {
                "name": "Lorehold, the Historian",
                "cmc": 5,
                "type_line": "Legendary Creature — Elder Dragon",
                "effect": "creature",
                "power": 5,
                "toughness": 5,
            }
            opponent.battlefield = [lorehold]
            card = {
                "name": fixture_name,
                "cmc": 2,
                "type_line": "Enchantment",
                "oracle_text": "Sacrifice a creature: this enchantment deals 1 damage to any target.",
            }

            effect = battle.get_card_effect(card)
            assert effect["effect"] == "passive"
            assert effect["suppressed_effect"] == "remove_creature"
            assert effect["_rule_review_status"] == "review_only"
            assert effect["_rule_execution_status"] == "review_only"

            battle.apply_effect_immediate(
                active,
                [opponent],
                card,
                turn=9,
                rng=random.Random(112),
                effect_data_override=effect,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler
            if previous_entry is None:
                battle.KNOWN_CARDS.pop(fixture_name, None)
            else:
                battle.KNOWN_CARDS[fixture_name] = previous_entry
            if not had_fallback:
                battle.CANONICAL_FALLBACK_KNOWN_CARDS.discard(fixture_name)

        assert lorehold in opponent.battlefield
        assert any(card.get("name") == fixture_name for card in active.battlefield)
        assert not any(event == "removal_resolved" for event, _ in events)
        assert any(
            event == "spell_resolved"
            and data.get("card") == fixture_name
            and data.get("effect") == "passive"
            and data.get("rule_review_status") == "review_only"
            for event, data in events
        )

    def test_goblin_bombardment_skips_without_expendable_creature():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        commander = {
            "name": "Lorehold, the Historian",
            "cmc": 5,
            "type_line": "Legendary Creature — Elder Dragon",
            "effect": "creature",
            "power": 5,
            "toughness": 5,
            "is_commander": True,
        }
        outlet = {
            "name": "Goblin Bombardment",
            "cmc": 2,
            "type_line": "Enchantment",
            "effect": "sacrifice_damage_outlet",
            "activated_sacrifice_creature_damage": True,
            "damage": 1,
        }
        active.battlefield = [outlet, commander]

        activations = battle.activate_sacrifice_damage_outlets(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            rng=random.Random(110),
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert commander in active.battlefield
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Goblin Bombardment"
            and data.get("strategic_guardrail_reason") == "no_expendable_creature_to_sacrifice"
            for event, data in events
        )

    def test_iron_man_attack_trigger_sacrifices_treasure_for_artifact_tutor():
        events = []
        decisions = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            active = player("Active")
            opponent = player("Opponent")
            iron_man = {
                "name": "Iron Man, Titan of Innovation",
                "cmc": 4,
                "type_line": "Legendary Artifact Creature — Human Hero",
                "oracle_text": "Flying, haste\nGenius Industrialist — Whenever Iron Man attacks, create a Treasure token, then you may sacrifice a noncreature artifact. If you do, search your library for an artifact card with mana value equal to 1 plus the sacrificed artifact's mana value, put it onto the battlefield tapped, then shuffle.",
                "effect": "attack_artifact_tutor",
                "artifact_attack_tutor": True,
                "artifact_tutor_cmc_mode": "sacrificed_mana_value_plus",
                "artifact_tutor_sacrifice_noncreature": True,
                "artifact_tutor_enters_tapped": True,
                "attack_trigger": True,
                "power": 4,
                "toughness": 4,
                "summoning_sick": False,
                "tapped": False,
                "_rule_source": "focused_battle_rule_evidence",
                "_rule_review_status": "needs_review",
            }
            active.battlefield = [
                iron_man,
            ]
            active.library = [
                {"name": "Sol Ring", "cmc": 1, "type_line": "Artifact", "effect": "ramp_permanent", "mana_produced": 2},
                {"name": "High Cost Artifact", "cmc": 5, "type_line": "Artifact", "effect": "finisher"},
            ]

            battle.combat_phase_v8(
                active,
                [opponent],
                [active, opponent],
                turn=4,
                rng=random.Random(111),
                stack=battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None
            battle.DECISION_TRACE_HANDLER = None

        assert active.treasures == 0
        assert any(card.get("name") == "Sol Ring" and card.get("tapped") is True for card in active.battlefield)
        assert not any(card.get("name") == "Sol Ring" for card in active.library)
        assert any(
            event == "trigger_resolved"
            and data.get("card") == "Iron Man, Titan of Innovation"
            and data.get("activation_kind") == "artifact_attack_tutor"
            and data.get("artifact_sacrificed") == "Treasure token"
            and data.get("found") == "Sol Ring"
            and data.get("target_cmc") == 1
            and data.get("cmc_match") == "exact"
            and data.get("enters_tapped") is True
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "attack_trigger_artifact_tutor"
            and decision.get("chosen_option", {}).get("target") == "Sol Ring"
            and decision.get("rule_status") == "needs_review"
            for decision in decisions
        )

    def test_flame_wave_oracle_and_runtime_damage_target_player_creatures():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            caster = player("Caster")
            target = player("Target")
            target.life = 9
            small = {"name": "Small Creature", "effect": "creature", "type_line": "Creature", "power": 2, "toughness": 2}
            medium = {"name": "Medium Creature", "effect": "creature", "type_line": "Creature", "power": 4, "toughness": 4}
            large = {"name": "Large Creature", "effect": "creature", "type_line": "Creature", "power": 5, "toughness": 5}
            protected = {
                "name": "Protected Creature",
                "effect": "creature",
                "type_line": "Creature",
                "power": 3,
                "toughness": 3,
                "indestructible": True,
            }
            target.battlefield = [small, medium, large, protected]
            flame_wave = {
                "name": "Flame Wave",
                "cmc": 7,
                "type_line": "Sorcery",
                "oracle_text": (
                    "Flame Wave deals 4 damage to target player or planeswalker and "
                    "each creature that player or that planeswalker's controller controls."
                ),
            }
            effect = battle.normalize_effect_by_oracle(
                flame_wave,
                battle.with_rule_metadata(
                    {"effect": "remove_creature", "instant": True},
                    source="test_curated_rule",
                    review_status="verified",
                    confidence=1.0,
                ),
            )

            assert effect["effect"] == "damage_player_and_creatures"
            assert effect["amount"] == 4
            assert effect["target"] == "player_or_planeswalker_controller"
            assert "instant" not in effect

            battle.apply_effect_immediate(
                caster,
                [target],
                flame_wave,
                turn=8,
                rng=random.Random(112),
                effect_data_override=effect,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert target.life == 5
        assert small not in target.battlefield
        assert medium not in target.battlefield
        assert large in target.battlefield
        assert protected in target.battlefield
        assert any(card.get("name") == "Small Creature" for card in target.graveyard)
        assert any(card.get("name") == "Medium Creature" for card in target.graveyard)
        assert any(card.get("name") == "Flame Wave" for card in caster.graveyard)
        assert any(
            event == "damage_resolved"
            and data.get("card") == "Flame Wave"
            and data.get("effect") == "damage_player_and_creatures"
            and data.get("target_player") == "Target"
            and data.get("creatures_destroyed") == 2
            and data.get("life_after") == 5
            for event, data in events
        )

    def test_aetherflux_reservoir_gains_life_on_future_spell_casts_not_resolution_damage():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            caster = player("Caster")
            reservoir = {"name": "Aetherflux Reservoir", "cmc": 4, "type_line": "Artifact"}
            battle.apply_effect_immediate(
                caster,
                [],
                reservoir,
                turn=4,
                rng=random.Random(113),
                effect_data_override={"effect": "aetherflux_reservoir"},
            )
            caster.record_spell_cast(turn_marker=4)
            battle.trigger_spell_cast_engines(
                caster,
                [caster],
                {"name": "Lightning Bolt", "cmc": 1, "type_line": "Instant"},
                turn=4,
                phase="precombat_main",
            )
            caster.record_spell_cast(turn_marker=4)
            battle.trigger_spell_cast_engines(
                caster,
                [caster],
                {"name": "Faithless Looting", "cmc": 1, "type_line": "Sorcery"},
                turn=4,
                phase="precombat_main",
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert caster.life == 43
        assert any(card.get("name") == "Aetherflux Reservoir" for card in caster.battlefield)
        assert not [
            data for event, data in events
            if event == "damage_resolved" and data.get("card") == "Aetherflux Reservoir"
        ]
        assert [
            data.get("life_gained")
            for event, data in events
            if event == "trigger_resolved" and data.get("card") == "Aetherflux Reservoir"
        ] == [1, 2]

    def test_brain_freeze_mills_library_instead_of_dealing_life_damage():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            caster = player("Caster")
            target = player("Target")
            target.library = [_card(f"Library {index}", cmc=1, effect="creature") for index in range(10)]
            caster.spells_cast_this_turn = 4
            battle.apply_effect_immediate(
                caster,
                [target],
                {"name": "Brain Freeze", "cmc": 2, "type_line": "Instant"},
                turn=5,
                rng=random.Random(114),
                effect_data_override={"effect": "brain_freeze", "mill_count": 3, "instant": True},
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert target.life == 40
        assert len(target.library) == 0
        assert len(target.graveyard) == 10
        assert any(card.get("name") == "Brain Freeze" for card in caster.graveyard)
        assert any(
            event == "mill_resolved"
            and data.get("card") == "Brain Freeze"
            and data.get("target_player") == "Target"
            and data.get("requested_mill") == 12
            and data.get("cards_milled") == 10
            for event, data in events
        )
        assert not [
            data for event, data in events
            if event == "damage_resolved" and data.get("card") == "Brain Freeze"
        ]

    def test_thassas_oracle_wins_only_when_library_is_within_blue_devotion():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            safe = player("Safe Oracle")
            safe.library = [_card(f"Safe {index}", cmc=1, effect="creature") for index in range(5)]
            battle.apply_effect_immediate(
                safe,
                [],
                {"name": "Thassa's Oracle", "cmc": 2, "mana_cost": "{U}{U}", "type_line": "Creature"},
                turn=6,
                rng=random.Random(115),
                effect_data_override={"effect": "thassa_oracle", "blue_devotion_pips": 2},
            )

            winning = player("Winning Oracle")
            winning.library = [_card("Last Card", cmc=1, effect="creature")]
            battle.apply_effect_immediate(
                winning,
                [],
                {"name": "Thassa's Oracle", "cmc": 2, "mana_cost": "{U}{U}", "type_line": "Creature"},
                turn=6,
                rng=random.Random(116),
                effect_data_override={"effect": "thassa_oracle", "blue_devotion_pips": 2},
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert safe.has_won() is False
        assert winning.has_won() is True
        assert winning.win_reason == "thassa_oracle"
        assert any(
            event == "thassa_oracle_resolved"
            and data.get("player") == "Safe Oracle"
            and data.get("result") == "no_win"
            for event, data in events
        )
        assert any(
            event == "game_won"
            and data.get("player") == "Winning Oracle"
            and data.get("reason") == "thassa_oracle"
            for event, data in events
        )

    def test_dragons_approach_deals_fixed_damage_and_tutors_dragon_from_graveyard_cost():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Dragon Approach")
            active.graveyard = [
                {"name": "Dragon's Approach", "type_line": "Sorcery", "cmc": 3}
                for _ in range(5)
            ]
            active.library = [
                {"name": "Filler Spell", "type_line": "Sorcery", "cmc": 1},
                {
                    "name": "Goldspan Dragon",
                    "type_line": "Creature — Dragon",
                    "cmc": 5,
                    "power": 4,
                    "toughness": 4,
                    "oracle_text": "Flying, haste",
                },
            ]
            opponent = player("Opponent")

            battle.apply_effect_immediate(
                active,
                [opponent],
                {"name": "Dragon's Approach", "type_line": "Sorcery", "cmc": 3},
                turn=4,
                rng=random.Random(608),
                effect_data_override={
                    "effect": "dragons_approach",
                    "damage": 3,
                    "_rule_logical_key": "battle_rule_v1:78d365e6550e295f9cbfa4f92245f864",
                    "_rule_oracle_hash": "dragon-approach-test-hash",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert opponent.life == 37
        assert len(active.exile) == 5
        assert all(card.get("name") == "Dragon's Approach" for card in active.exile)
        assert any(card.get("name") == "Goldspan Dragon" for card in active.battlefield)
        assert active.graveyard[-1]["name"] == "Dragon's Approach"
        assert any(
            event == "dragons_approach_resolved"
            and data.get("damage_each_opponent") == 3
            and data.get("dragon_tutored") == "Goldspan Dragon"
            for event, data in events
        )
        assert any(
            event == "dragons_approach_dragon_tutored"
            and data.get("exiled_graveyard_copies") == 5
            and data.get("found") == "Goldspan Dragon"
            for event, data in events
        )

    def test_thrumming_stone_ripples_dragons_approach_without_bonus_damage():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Ripple Approach")
            active.battlefield = [{"name": "Thrumming Stone", "effect": "ripple_engine"}]
            active.library = [
                {"name": "Dragon's Approach", "type_line": "Sorcery", "cmc": 3},
                {"name": "Filler Spell", "type_line": "Sorcery", "cmc": 1},
                {"name": "Dragon's Approach", "type_line": "Sorcery", "cmc": 3},
                {"name": "Ancient Copper Dragon", "type_line": "Creature — Elder Dragon", "cmc": 6},
            ]
            opponent = player("Opponent")

            battle.apply_effect_immediate(
                active,
                [opponent],
                {"name": "Dragon's Approach", "type_line": "Sorcery", "cmc": 3},
                turn=5,
                rng=random.Random(609),
                effect_data_override={
                    "effect": "dragons_approach",
                    "damage": 3,
                    "battle_model_scope": "fixed_damage_graveyard_dragon_tutor_ripple_v1",
                    "_rule_logical_key": "battle_rule_v1:78d365e6550e295f9cbfa4f92245f864",
                    "_rule_oracle_hash": "dragon-approach-test-hash",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert opponent.life == 31
        assert [card.get("name") for card in active.graveyard].count("Dragon's Approach") == 3
        assert [card.get("name") for card in active.library] == ["Filler Spell", "Ancient Copper Dragon"]
        assert any(
            event == "ripple_trigger_resolved"
            and data.get("free_cast_count") == 2
            and data.get("bottomed_count") == 2
            for event, data in events
        )

    def test_pg079_storm_herd_creates_life_total_flying_pegasus_tokens():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            active.life = 12
            battle.apply_effect_immediate(
                active,
                [],
                {"name": "Storm Herd", "type_line": "Sorcery", "cmc": 10},
                turn=8,
                rng=random.Random(610),
                effect_data_override={
                    "effect": "token_maker",
                    "token_count": "life_total",
                    "token_name": "Pegasus Token",
                    "token_power": 1,
                    "token_toughness": 1,
                    "token_flying": True,
                    "battle_model_scope": "life_total_flying_pegasus_token_maker_v1",
                    "_rule_logical_key": "battle_rule_v1:b041641dc875caa7987253389dc52839",
                    "_rule_oracle_hash": "storm-herd-test-hash",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        pegasus_tokens = [
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("name") == "Pegasus Token"
        ]
        assert len(pegasus_tokens) == 12
        assert all(token.get("power") == 1 and token.get("toughness") == 1 for token in pegasus_tokens)
        assert all(token.get("flying") is True for token in pegasus_tokens)
        token_event = next(
            data
            for event, data in events
            if event == "tokens_created" and data.get("card") == "Storm Herd"
        )
        assert token_event["tokens_requested"] == 12
        assert token_event["tokens_created"] == 12
        assert token_event["token_flying"] is True

    def test_pg079_rite_of_the_dragoncaller_creates_flying_dragon_on_instant_sorcery_cast():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.battlefield = [
                {
                    "name": "Rite of the Dragoncaller",
                    "cmc": 6,
                    "type_line": "Enchantment",
                    "effect": "token_maker",
                    "trigger": "instant_sorcery_cast",
                    "trigger_effect": "token_maker",
                    "token_count": 1,
                    "token_name": "Dragon Token",
                    "token_power": 5,
                    "token_toughness": 5,
                    "token_flying": True,
                    "battle_model_scope": "instant_sorcery_cast_create_5_5_flying_dragon_v1",
                    "_rule_logical_key": "battle_rule_v1:b23bca3229a81d65750cf9c453c7943d",
                    "_rule_oracle_hash": "rite-dragoncaller-test-hash",
                }
            ]
            battle.trigger_spell_cast_engines(
                active,
                [active, opponent],
                {"name": "Lightning Helix", "type_line": "Instant", "cmc": 2},
                turn=5,
                phase="precombat_main",
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        dragon_tokens = [
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("name") == "Dragon Token"
        ]
        assert len(dragon_tokens) == 1
        assert dragon_tokens[0]["power"] == 5
        assert dragon_tokens[0]["toughness"] == 5
        assert dragon_tokens[0].get("flying") is True
        assert any(
            event == "trigger_resolved"
            and data.get("card") == "Rite of the Dragoncaller"
            and data.get("trigger") == "instant_sorcery_cast"
            and data.get("trigger_spell") == "Lightning Helix"
            and data.get("effect") == "token_maker"
            and data.get("tokens_created") == 1
            and data.get("token_power") == 5
            and data.get("token_flying") is True
            for event, data in events
        )

    def test_pg079_witch_enchanter_etb_destroys_opponent_artifact_or_enchantment():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            sol_ring = {"name": "Sol Ring", "type_line": "Artifact", "cmc": 1}
            opponent.battlefield = [
                sol_ring,
                {"name": "Runeclaw Bear", "type_line": "Creature", "effect": "creature", "power": 2, "toughness": 2},
            ]
            battle.apply_effect_immediate(
                active,
                [opponent],
                {
                    "name": "Witch Enchanter // Witch-Blessed Meadow",
                    "type_line": "Creature — Human Warlock",
                    "cmc": 4,
                    "power": 2,
                    "toughness": 2,
                },
                turn=6,
                rng=random.Random(611),
                effect_data_override={
                    "effect": "creature",
                    "etb_remove_target": "artifact_or_enchantment",
                    "battle_model_scope": "creature_etb_destroy_opponent_artifact_or_enchantment_v1",
                    "_rule_logical_key": "battle_rule_v1:5768b971f1ab4f2d4d9b8bd6a768c132",
                    "_rule_oracle_hash": "witch-enchanter-test-hash",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert any(
            permanent.get("name") == "Witch Enchanter // Witch-Blessed Meadow"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert sol_ring not in opponent.battlefield
        assert sol_ring in opponent.graveyard
        assert any(
            event == "etb_removal_resolved"
            and data.get("card") == "Witch Enchanter // Witch-Blessed Meadow"
            and data.get("trigger") == "enters_battlefield"
            and data.get("target_type") == "artifact_or_enchantment"
            and data.get("target") == "Sol Ring"
            for event, data in events
        )

    def test_pg079_powerbalance_casts_same_mana_value_top_card_without_paying():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            caster = player("Opponent")
            controller = player("Lorehold")
            controller.library = [
                {"name": "Free Bolt", "type_line": "Instant", "cmc": 2, "effect": "draw_cards", "count": 1},
                {"name": "Library Filler", "type_line": "Sorcery", "cmc": 5},
            ]
            controller.battlefield = [
                {
                    "name": "Powerbalance",
                    "type_line": "Enchantment",
                    "effect": "draw_engine",
                    "trigger": "opponent_spell",
                    "draw_on_enter": False,
                    "powerbalance_topdeck_free_cast_same_mana_value": True,
                    "battle_model_scope": "opponent_spell_reveal_top_same_mana_value_free_cast_v1",
                    "_rule_logical_key": "battle_rule_v1:e35051e9c60b94a84ac9b71c11c7fc4b",
                    "_rule_oracle_hash": "powerbalance-test-hash",
                }
            ]
            battle.trigger_opponent_spell_draw_engines(
                caster,
                [controller],
                {"name": "Opponent Two Drop", "type_line": "Creature", "cmc": 2, "effect": "creature"},
                turn=4,
                phase="main",
                rng=random.Random(612),
                all_players=[caster, controller],
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert [card.get("name") for card in controller.library] == ["Library Filler"]
        assert any(card.get("name") == "Free Bolt" for card in controller.graveyard)
        assert any(
            event == "powerbalance_trigger_resolved"
            and data.get("card") == "Powerbalance"
            and data.get("revealed_card") == "Free Bolt"
            and data.get("trigger_spell_mana_value") == 2
            and data.get("result") == "cast_without_paying_mana"
            and data.get("cast_without_paying_mana_cost") is True
            and data.get("rule_logical_key") == "battle_rule_v1:e35051e9c60b94a84ac9b71c11c7fc4b"
            for event, data in events
        )

    def test_pg102_creative_technique_demonstrates_top_nonland_free_casts():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Chosen Opponent")
            active.library = [
                {"name": "Mountain", "type_line": "Basic Land - Mountain", "cmc": 0, "effect": "land"},
                {"name": "Free Creature A", "type_line": "Creature - Spirit", "cmc": 4, "effect": "creature", "power": 4},
                {"name": "Plains", "type_line": "Basic Land - Plains", "cmc": 0, "effect": "land"},
                {"name": "Free Creature B", "type_line": "Creature - Spirit", "cmc": 3, "effect": "creature", "power": 3},
            ]
            opponent.library = [
                {"name": "Island", "type_line": "Basic Land - Island", "cmc": 0, "effect": "land"},
                {"name": "Opponent Free Creature", "type_line": "Creature - Wizard", "cmc": 2, "effect": "creature", "power": 2},
            ]
            creative_technique = {
                "name": "Creative Technique",
                "type_line": "Sorcery",
                "cmc": 5,
            }
            effect_data = {
                "effect": "exile_top_nonland_free_cast",
                "shuffle_before_reveal": True,
                "revealed_card_cast_without_paying_mana": True,
                "demonstrate": True,
                "battle_model_scope": "shuffle_reveal_top_nonland_exile_free_cast_with_demonstrate_v1",
                "_rule_logical_key": "battle_rule_v1:creative-technique-test",
                "_rule_oracle_hash": "creative-technique-test-hash",
                "_rule_review_status": "verified",
                "_rule_execution_status": "auto",
            }
            battle.apply_effect_immediate(
                active,
                [opponent],
                creative_technique,
                turn=5,
                rng=random.Random(102),
                effect_data_override=effect_data,
                stack=battle.Stack(),
                phase="precombat_main",
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        active_creatures = {
            permanent.get("name")
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        }
        opponent_creatures = {
            permanent.get("name")
            for permanent in opponent.battlefield
            if isinstance(permanent, dict)
        }
        assert active_creatures == {"Free Creature A", "Free Creature B"}
        assert opponent_creatures == {"Opponent Free Creature"}
        assert [card.get("name") for card in active.graveyard] == ["Creative Technique"]
        assert active.exile == []
        assert opponent.exile == []

        demonstrate_event = next(
            data
            for event, data in events
            if event == "demonstrate_resolved"
        )
        assert demonstrate_event["demonstrated"] is True
        assert demonstrate_event["chosen_opponent"] == "Chosen Opponent"
        assert [
            row["resolution"]
            for row in demonstrate_event["resolutions"]
        ] == [
            "demonstrate_controller_copy",
            "demonstrate_opponent_copy",
            "original",
        ]
        free_cast_events = [
            data for event, data in events if event == "top_nonland_free_cast"
        ]
        assert len(free_cast_events) == 3
        assert all(data["cast_without_paying_mana_cost"] is True for data in free_cast_events)
        free_creature_resolutions = [
            data
            for event, data in events
            if event == "spell_resolved"
            and data.get("card") in {
                "Free Creature A",
                "Free Creature B",
                "Opponent Free Creature",
            }
        ]
        assert len(free_creature_resolutions) == 3
        assert all(data["source_zone"] == "exile" for data in free_creature_resolutions)
        assert all(
            data["locked_cost"]["spend_tags"] == ["cast_without_paying_mana_cost"]
            for data in free_creature_resolutions
        )

    def test_pg079_flare_of_duplication_keeps_copy_spell_as_stack_targeted_instant():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            battle.apply_effect_immediate(
                active,
                [],
                {"name": "Flare of Duplication", "type_line": "Instant", "cmc": 3},
                turn=4,
                rng=random.Random(613),
                effect_data_override={
                    "effect": "copy_spell",
                    "instant": True,
                    "target": "instant_or_sorcery_on_stack",
                    "may_choose_new_targets": True,
                    "alternative_cost_status": "sacrifice_nontoken_red_creature_annotation_only",
                    "battle_model_scope": "copy_target_instant_or_sorcery_stack_spell_alt_cost_annotation_v1",
                    "_rule_logical_key": "battle_rule_v1:b82bbb548dab138fa0700cb4cf905617",
                    "_rule_oracle_hash": "flare-test-hash",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert not any(
            permanent.get("name") == "Flare of Duplication"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(card.get("name") == "Flare of Duplication" for card in active.graveyard)
        assert any(
            event == "copy_spell_no_stack_target"
            and data.get("card") == "Flare of Duplication"
            and data.get("rule_logical_key") == "battle_rule_v1:b82bbb548dab138fa0700cb4cf905617"
            for event, data in events
        )

    def test_pg079_reforge_the_soul_discards_then_draws_seven_with_scope():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.hand = [
                {"name": "Old Card", "cmc": 2, "type_line": "Instant"},
                {"name": "Another Old Card", "cmc": 3, "type_line": "Sorcery"},
            ]
            opponent.hand = [{"name": "Opponent Old Card", "cmc": 1, "type_line": "Instant"}]
            active.library = [{"name": f"Draw {index}", "cmc": 1, "type_line": "Sorcery"} for index in range(8)]
            opponent.library = [
                {"name": f"Opponent Draw {index}", "cmc": 1, "type_line": "Sorcery"}
                for index in range(8)
            ]
            battle.apply_effect_immediate(
                active,
                [opponent],
                {"name": "Reforge the Soul", "type_line": "Sorcery", "cmc": 5},
                turn=5,
                rng=random.Random(614),
                effect_data_override={
                    "effect": "draw_cards",
                    "count": 7,
                    "wheel": True,
                    "miracle": "1R",
                    "battle_model_scope": "each_player_discard_hand_draw_seven_miracle_annotation_v1",
                    "_rule_logical_key": "battle_rule_v1:90b82cfc81ff726ac0fc96a1b220f263",
                    "_rule_oracle_hash": "reforge-test-hash",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert len(active.hand) == 7
        assert len(opponent.hand) == 7
        assert any(card.get("name") == "Old Card" for card in active.graveyard)
        assert any(
            event == "spell_resolved"
            and data.get("card") == "Reforge the Soul"
            and data.get("rule_logical_key") == "battle_rule_v1:90b82cfc81ff726ac0fc96a1b220f263"
            for event, data in events
        )

    def test_pg079_rise_of_the_eldrazi_resolves_composite_destroy_draw_extra_turn_exile():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            target = {"name": "Threat Permanent", "type_line": "Artifact", "cmc": 4, "effect": "ramp_engine"}
            opponent.battlefield = [target]
            active.library = [{"name": f"Draw {index}", "cmc": 1, "type_line": "Sorcery"} for index in range(5)]
            battle.apply_effect_immediate(
                active,
                [opponent],
                {"name": "Rise of the Eldrazi", "type_line": "Sorcery", "cmc": 12},
                turn=9,
                rng=random.Random(615),
                effect_data_override={
                    "effect": "composite_resolution",
                    "uncounterable": True,
                    "exiles_self": True,
                    "_composite_rule_components": [
                        {"effect": "remove_permanent", "target": "nonland_permanent"},
                        {"effect": "draw_cards", "count": 4},
                        {"effect": "extra_turn", "turns": 1},
                    ],
                    "battle_model_scope": "uncounterable_destroy_target_permanent_target_player_draw_four_extra_turn_exile_v1",
                    "_rule_logical_key": "battle_rule_v1:57d155e410ca3cc6a96e14ed50f524d4",
                    "_rule_oracle_hash": "rise-test-hash",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert target not in opponent.battlefield
        assert target in opponent.graveyard
        assert len(active.hand) == 4
        assert active.extra_turns == 1
        assert any(card.get("name") == "Rise of the Eldrazi" for card in active.exile)
        assert any(
            event == "composite_rule_resolved"
            and data.get("card") == "Rise of the Eldrazi"
            and data.get("components_applied") == 3
            and data.get("rule_logical_key") == "battle_rule_v1:57d155e410ca3cc6a96e14ed50f524d4"
            for event, data in events
        )

    def test_pg081_artists_talent_rummages_on_own_noncreature_spell_cast():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            active.hand = [
                {"name": "Dead Eight Drop", "cmc": 8, "type_line": "Sorcery"},
            ]
            active.library = [
                {"name": "Fresh Draw", "cmc": 2, "type_line": "Instant"},
            ]
            active.battlefield = [
                {
                    "name": "Artist's Talent",
                    "type_line": "Enchantment — Class",
                    "effect": "draw_engine",
                    "trigger": "noncreature_spell_cast",
                    "trigger_effect": "rummage",
                    "battle_model_scope": "class_level1_own_noncreature_spell_optional_discard_draw_level2_level3_annotations_v1",
                    "_rule_logical_key": "battle_rule_v1:artists-talent-test",
                    "_rule_oracle_hash": "artists-talent-test-hash",
                }
            ]
            battle.trigger_spell_cast_engines(
                active,
                [active],
                {"name": "Setup Spell", "type_line": "Instant", "cmc": 1},
                turn=4,
                phase="precombat_main",
            )
            battle.trigger_spell_cast_engines(
                active,
                [active],
                {"name": "Creature Spell", "type_line": "Creature", "cmc": 2, "effect": "creature"},
                turn=4,
                phase="precombat_main",
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert [card.get("name") for card in active.hand] == ["Fresh Draw"]
        assert [card.get("name") for card in active.graveyard] == ["Dead Eight Drop"]
        trigger_events = [
            data
            for event, data in events
            if event == "trigger_resolved" and data.get("card") == "Artist's Talent"
        ]
        assert len(trigger_events) == 1
        event = trigger_events[0]
        assert event["trigger"] == "noncreature_spell_cast"
        assert event["trigger_spell"] == "Setup Spell"
        assert event["effect"] == "rummage"
        assert event["discarded"] == "Dead Eight Drop"
        assert event["drawn"] == ["Fresh Draw"]
        assert event["rule_logical_key"] == "battle_rule_v1:artists-talent-test"

    def test_pg081_pinnacle_monk_enters_and_returns_instant_or_sorcery_to_hand():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            target_spell = {"name": "Graveyard Lesson", "type_line": "Sorcery", "cmc": 3}
            ignored_creature = {
                "name": "Ignored Creature",
                "type_line": "Creature",
                "effect": "creature",
                "cmc": 2,
            }
            active.graveyard = [target_spell, ignored_creature]
            battle.apply_effect_immediate(
                active,
                [],
                {
                    "name": "Pinnacle Monk // Mystic Peak",
                    "type_line": "Creature — Djinn Monk",
                    "cmc": 5,
                    "power": 2,
                    "toughness": 2,
                },
                turn=5,
                rng=random.Random(620),
                effect_data_override={
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                    "keywords": ["prowess"],
                    "etb_recursion_count": 1,
                    "etb_recursion_target": "instant_or_sorcery",
                    "etb_recursion_destination": "hand",
                    "back_face_land_status": "annotation_only",
                    "battle_model_scope": "front_creature_prowess_etb_return_instant_or_sorcery_graveyard_to_hand_back_land_annotation_v1",
                    "_rule_logical_key": "battle_rule_v1:pinnacle-monk-test",
                    "_rule_oracle_hash": "pinnacle-monk-test-hash",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert any(
            permanent.get("name") == "Pinnacle Monk // Mystic Peak"
            and permanent.get("effect") == "creature"
            and "prowess" in permanent.get("keywords", [])
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert target_spell in active.hand
        assert target_spell not in active.graveyard
        assert ignored_creature in active.graveyard
        assert any(
            event == "etb_recursion_resolved"
            and data.get("card") == "Pinnacle Monk // Mystic Peak"
            and data.get("target_type") == "instant_or_sorcery"
            and data.get("destination") == "hand"
            and data.get("recovered") == ["Graveyard Lesson"]
            and data.get("rule_logical_key") == "battle_rule_v1:pinnacle-monk-test"
            for event, data in events
        )

    def test_pg150_insidious_roots_creature_recursion_creates_buffed_plant_and_unlocks_token_mana():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            active.graveyard = [
                {
                    "name": "Recovered Creature",
                    "type_line": "Creature — Spirit",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 1,
                    "cmc": 2,
                },
                {
                    "name": "Setup Spell",
                    "type_line": "Sorcery",
                    "effect": "draw_cards",
                    "cmc": 2,
                },
            ]
            battle.apply_effect_immediate(
                active,
                [],
                {"name": "Insidious Roots", "type_line": "Enchantment", "cmc": 2},
                turn=5,
                rng=random.Random(9150),
                effect_data_override={
                    "effect": "passive",
                    "battle_model_scope": "creature_tokens_tap_any_color_creature_graveyard_plant_growth_v1",
                    "creature_tokens_tap_for_any_color": True,
                    "creature_cards_leave_your_graveyard_create_plant_token": True,
                    "plant_tokens_get_plus_one_counter_on_creature_graveyard_exit": True,
                    "trigger_once_each_graveyard_exit_event": True,
                    "token_name": "Plant Token",
                    "token_subtype": "Plant",
                    "token_power": 0,
                    "token_toughness": 1,
                    "token_colors": ["G"],
                    "_rule_logical_key": "battle_rule_v1:insidious-roots-test",
                    "_rule_oracle_hash": "insidious-roots-test-hash",
                },
            )

            recovered = battle.resolve_etb_graveyard_recursion(
                active,
                {"name": "Recovery Witness", "type_line": "Creature", "cmc": 4},
                {
                    "etb_recursion_count": 2,
                    "etb_recursion_target": "nonland",
                    "etb_recursion_destination": "hand",
                },
                turn=5,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert [card.get("name") for card in recovered] == ["Recovered Creature", "Setup Spell"]
        assert not active.graveyard
        plants = [
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("name") == "Plant Token"
        ]
        assert len(plants) == 1
        plant = plants[0]
        assert plant["power"] == 1
        assert plant["toughness"] == 2
        assert plant["plus_one_counters"] == 1

        plant["summoning_sick"] = False
        active.refresh_mana_sources(turn=6)
        assert active.available_mana() == 1

        assert any(
            event == "trigger_resolved"
            and data.get("card") == "Insidious Roots"
            and data.get("trigger") == "creature_cards_leave_graveyard"
            and data.get("creature_cards_left_graveyard") == ["Recovered Creature"]
            and data.get("rule_logical_key") == "battle_rule_v1:insidious-roots-test"
            for event, data in events
        )

    def test_pg150_insidious_roots_ignores_noncreature_flashback_from_graveyard():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.battlefield = ["land", "land"]
            spell = {
                "name": "Battle Cantrip",
                "type_line": "Instant",
                "effect": "draw_cards",
                "count": 1,
                "cmc": 1,
                "flashback_cost": "{1}",
            }
            active.graveyard = [spell]
            battle.apply_effect_immediate(
                active,
                [opponent],
                {"name": "Insidious Roots", "type_line": "Enchantment", "cmc": 2},
                turn=4,
                rng=random.Random(9151),
                effect_data_override={
                    "effect": "passive",
                    "battle_model_scope": "creature_tokens_tap_any_color_creature_graveyard_plant_growth_v1",
                    "creature_tokens_tap_for_any_color": True,
                    "creature_cards_leave_your_graveyard_create_plant_token": True,
                    "plant_tokens_get_plus_one_counter_on_creature_graveyard_exit": True,
                    "trigger_once_each_graveyard_exit_event": True,
                    "token_name": "Plant Token",
                    "token_subtype": "Plant",
                    "token_power": 0,
                    "token_toughness": 1,
                    "token_colors": ["G"],
                    "_rule_logical_key": "battle_rule_v1:insidious-roots-test",
                    "_rule_oracle_hash": "insidious-roots-test-hash",
                },
            )
            active.refresh_mana_sources(turn=4)

            assert battle.cast_flashback_spell_from_graveyard(
                active,
                spell,
                [opponent],
                [active, opponent],
                turn=4,
                phase="precombat_main",
                stack=battle.Stack(),
                rng=random.Random(9152),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert not [
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("name") == "Plant Token"
        ]
        assert not [
            data
            for event, data in events
            if event == "trigger_resolved"
            and data.get("card") == "Insidious Roots"
            and data.get("trigger") == "creature_cards_leave_graveyard"
        ]

    def test_pg151_magda_tapped_dwarf_creates_treasure():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            opponent = player("Opponent")
            magda = {
                "name": "Magda, Brazen Outlaw",
                "cmc": 2,
                "type_line": "Legendary Creature — Dwarf Berserker",
                "effect": "creature",
                "power": 2,
                "toughness": 1,
                "other_dwarves_you_control_get_plus_one_power": True,
                "controlled_dwarf_becomes_tapped_creates_treasure": True,
                "activated_sacrifice_five_treasures_tutor_artifact_or_dragon": True,
                "activated_treasure_tutor_cost": 5,
                "activated_treasure_tutor_destination": "battlefield",
                "summoning_sick": True,
                "tapped": False,
                "_rule_logical_key": "battle_rule_v1:magda-test",
                "_rule_oracle_hash": "magda-test-hash",
            }
            other_dwarf = {
                "name": "Axgard Cavalry",
                "cmc": 2,
                "type_line": "Creature — Dwarf Berserker",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "summoning_sick": False,
                "tapped": False,
            }
            active.battlefield = [magda, other_dwarf]

            battle.combat_phase_v8(
                active,
                [opponent],
                [active, opponent],
                turn=4,
                rng=random.Random(9153),
                stack=battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert active.treasures == 1
        assert other_dwarf.get("tapped") is True
        assert any(
            event == "trigger_resolved"
            and data.get("card") == "Magda, Brazen Outlaw"
            and data.get("trigger") == "controlled_dwarf_tapped"
            and data.get("tapped_permanent") == "Axgard Cavalry"
            and data.get("treasures_created") == 1
            and data.get("rule_logical_key") == "battle_rule_v1:magda-test"
            for event, data in events
        )

    def test_pg152_bartolome_normalizes_to_exact_scope():
        effect_data = battle.normalize_effect_by_oracle(
            {
                "name": "Bartolomé del Presidio",
                "cmc": 2,
                "type_line": "Legendary Creature — Vampire Knight",
                "oracle_text": "Sacrifice another creature or artifact: Put a +1/+1 counter on Bartolomé del Presidio.",
            },
            battle.with_rule_metadata(
                {
                    "effect": "creature",
                    "power": 2,
                    "toughness": 1,
                    "activation_cost": "sacrifice_creature_or_artifact",
                    "self_add_plus_one_counter": 1,
                    "battle_model_scope": "sacrifice_another_creature_or_artifact_put_plus_one_counter_on_self_v1",
                },
                source="test_curated_rule",
                review_status="verified",
                confidence=1.0,
            ),
        )

        assert effect_data["effect"] == "creature"
        assert (
            effect_data["battle_model_scope"]
            == "sacrifice_another_creature_or_artifact_put_plus_one_counter_on_self_v1"
        )
        assert effect_data["activation_cost"] == "sacrifice_creature_or_artifact"
        assert effect_data["self_add_plus_one_counter"] == 1

    def test_pg152_bartolome_sacrifices_treasure_and_grows_precombat():
        events = []
        decisions = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            active = player("Active")
            opponent = player("Opponent")
            bartolome = {
                "name": "Bartolomé del Presidio",
                "cmc": 2,
                "type_line": "Legendary Creature — Vampire Knight",
                "effect": "creature",
                "power": 2,
                "toughness": 1,
                "activation_cost": "sacrifice_creature_or_artifact",
                "self_add_plus_one_counter": 1,
                "summoning_sick": False,
                "_rule_logical_key": "battle_rule_v1:bartolome-test",
                "_rule_oracle_hash": "bartolome-test-hash",
            }
            treasure = {
                "name": "Treasure",
                "cmc": 0,
                "type_line": "Artifact Token — Treasure",
                "effect": "ramp_permanent",
                "is_token": True,
                "tag": "token",
                "is_mana_source": True,
            }
            active.battlefield = [bartolome, treasure]

            activations = battle.activate_self_counter_sacrifice_outlets(
                active,
                [opponent],
                [active, opponent],
                turn=5,
                phase="precombat_main",
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None
            battle.DECISION_TRACE_HANDLER = None

        assert activations == 1
        assert bartolome["power"] == 3
        assert bartolome["toughness"] == 2
        assert bartolome["plus_one_counters"] == 1
        assert not any(
            permanent for permanent in active.battlefield if permanent.get("name") == "Treasure"
        )
        assert any(
            event == "activated_ability"
            and data.get("card") == "Bartolomé del Presidio"
            and data.get("activation_kind") == "self_counter_growth"
            and data.get("sacrificed") == "Treasure"
            and data.get("plus_one_counters_added") == 1
            and data.get("rule_logical_key") == "battle_rule_v1:bartolome-test"
            for event, data in events
        )
        assert any(trace.get("decision_type") == "activated_self_counter_growth" for trace in decisions)

    def test_pg151_magda_sacrifices_five_treasures_to_tutor_valid_target():
        events = []
        decisions = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            active = player("Active")
            opponent = player("Opponent")
            active.treasures = 5
            magda = {
                "name": "Magda, Brazen Outlaw",
                "cmc": 2,
                "type_line": "Legendary Creature — Dwarf Berserker",
                "effect": "creature",
                "power": 2,
                "toughness": 1,
                "other_dwarves_you_control_get_plus_one_power": True,
                "controlled_dwarf_becomes_tapped_creates_treasure": True,
                "activated_sacrifice_five_treasures_tutor_artifact_or_dragon": True,
                "activated_treasure_tutor_cost": 5,
                "activated_treasure_tutor_destination": "battlefield",
                "summoning_sick": False,
                "tapped": False,
                "_rule_logical_key": "battle_rule_v1:magda-test",
                "_rule_oracle_hash": "magda-test-hash",
            }
            active.battlefield = [magda]
            active.library = [
                {
                    "name": "Goldspan Dragon",
                    "cmc": 5,
                    "type_line": "Creature — Dragon",
                    "effect": "finisher",
                    "power": 4,
                    "toughness": 4,
                },
                {
                    "name": "Cleanup Spell",
                    "cmc": 2,
                    "type_line": "Sorcery",
                    "effect": "draw_cards",
                },
            ]

            activations = battle.activate_treasure_tutor_creatures(
                active,
                [opponent],
                [active, opponent],
                turn=6,
                phase="precombat_main",
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None
            battle.DECISION_TRACE_HANDLER = None

        assert activations == 1
        assert active.treasures == 0
        assert any(
            isinstance(permanent, dict)
            and permanent.get("name") == "Goldspan Dragon"
            for permanent in active.battlefield
        )
        assert not any(card.get("name") == "Goldspan Dragon" for card in active.library)
        assert any(
            event == "activated_ability"
            and data.get("card") == "Magda, Brazen Outlaw"
            and data.get("activation_kind") == "sacrifice_five_treasures_tutor_artifact_or_dragon"
            and data.get("found") == "Goldspan Dragon"
            and data.get("treasures_spent") == 5
            and data.get("destination") == "battlefield"
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "utility_creature_activation"
            and decision.get("chosen_option", {}).get("card") == "Goldspan Dragon"
            and decision.get("rule_status") == "needs_review"
            for decision in decisions
        )

    def test_pg081_redirect_lightning_redirects_single_target_stack_object():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            responder = player("Lorehold")
            protected = {
                "name": "Protected Creature",
                "effect": "creature",
                "type_line": "Creature",
                "power": 2,
                "toughness": 2,
            }
            responder.battlefield = [protected]
            caster = player("Caster")
            opponent_threat = {
                "name": "Opponent Threat",
                "effect": "creature",
                "type_line": "Creature",
                "power": 6,
                "toughness": 6,
            }
            caster.battlefield = [opponent_threat]
            removal = {"name": "Targeted Removal", "cmc": 2, "type_line": "Instant"}
            removal_effect = {
                "effect": "remove_creature",
                "instant": True,
                "declared_targets": [
                    {
                        "target": protected,
                        "controller": responder,
                        "target_type": "creature",
                    }
                ],
            }
            stack = battle.Stack()
            stack.push(removal, caster, removal_effect)
            context = battle.redirectable_stack_context(
                responder,
                [caster, responder],
                stack.items[-1],
            )
            battle.resolve_redirect_removal(
                responder,
                [caster, responder],
                {"name": "Redirect Lightning", "type_line": "Instant — Lesson", "cmc": 1},
                {
                    "effect": "redirect_removal",
                    "instant": True,
                    "target": "single_target_spell_or_ability",
                    "additional_cost_status": "pay_five_life_or_two_generic_annotation",
                    "battle_model_scope": "single_target_spell_or_ability_redirect_additional_cost_annotation_v1",
                    "_rule_logical_key": "battle_rule_v1:redirect-lightning-test",
                    "_rule_oracle_hash": "redirect-lightning-test-hash",
                    "_redirect_context": context,
                },
                turn=4,
                phase="combat",
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        redirected_target = stack.items[-1].effect_data["declared_targets"][0]["target"]
        assert redirected_target is opponent_threat
        assert protected in responder.battlefield
        assert any(
            event == "redirect_removal_resolved"
            and data.get("card") == "Redirect Lightning"
            and data.get("old_target") == "Protected Creature"
            and data.get("new_target") == "Opponent Threat"
            and data.get("target_change_applied") is True
            and data.get("rule_logical_key") == "battle_rule_v1:redirect-lightning-test"
            for event, data in events
        )

    def test_pg086_angels_grace_rule_resolves_from_sqlite_cache():
        effect_data = battle.get_card_effect(
            {"name": "Angel's Grace", "type_line": "Instant", "cmc": 1}
        )

        assert effect_data["effect"] == "cannot_lose_turn"
        assert effect_data["_rule_logical_key"] == (
            "battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227"
        )
        assert effect_data["_rule_oracle_hash"] == "627c4ce7adf5be44b93e2b850159e5d9"
        assert effect_data["battle_model_scope"] == (
            "split_second_cannot_lose_opponents_cannot_win_damage_life_floor_v1"
        )
        assert effect_data["oracle_runtime_scope"] == (
            "cannot_lose_opponents_cannot_win_damage_life_floor_split_second_annotation"
        )
        assert effect_data["life_floor_on_damage"] == 1
        assert effect_data["split_second"] is True
        assert effect_data["opponents_cant_win_this_turn"] is True

    def test_pg087_deck606_remaining_semantic_rules_resolve_from_sqlite_cache():
        expected = {
            "Hexing Squelcher": (
                "battle_rule_v1:c6587e309bfd402ee1b98b4848abc6d3",
                "ed00818e6ca804b7d1a3ef47c29277ea",
                "creature_body_uncounterable_ward_static_counter_protection_annotations_v1",
            ),
            "Ragavan, Nimble Pilferer": (
                "battle_rule_v1:3e0569d6bae4ed8b6e6e4289ea75084e",
                "e337b9515b6984af8a1572db48f47eec",
                "creature_body_haste_combat_damage_treasure_impulse_dash_annotations_v1",
            ),
            "Skyclave Apparition": (
                "battle_rule_v1:4f29c7a4bbe21a160f28452406153846",
                "4d0c162906712b2c428b754ad2f0b3a0",
                "creature_etb_exile_nonland_nontoken_mv_lte4_leave_illusion_annotation_v1",
            ),
            "Underworld Breach": (
                "battle_rule_v1:3f9f5259b05245670ee19b357aa2e999",
                "a98ca5777789e48c44daff97999f2beb",
                "escape_grant_nonland_graveyard_end_step_sacrifice_annotation_v1",
            ),
        }
        for name, (logical_key, oracle_hash, scope) in expected.items():
            effect_data = battle.get_card_effect({"name": name, "cmc": 2, "type_line": "Creature"})
            assert effect_data["_rule_logical_key"] == logical_key
            assert effect_data["_rule_oracle_hash"] == oracle_hash
            assert effect_data["battle_model_scope"] == scope

        hexing = battle.get_card_effect({"name": "Hexing Squelcher", "type_line": "Creature", "cmc": 2})
        assert hexing["spells_you_control_cant_be_countered"] is True
        assert hexing["ward_pay_life_status"] == "annotation_only"

        ragavan = battle.get_card_effect({"name": "Ragavan, Nimble Pilferer", "type_line": "Creature", "cmc": 1})
        assert ragavan["haste"] is True
        assert ragavan["combat_damage_treasure_trigger_status"] == "annotation_only"
        assert ragavan["dash_status"] == "annotation_only"

        skyclave = battle.get_card_effect({"name": "Skyclave Apparition", "type_line": "Creature", "cmc": 3})
        assert skyclave["etb_remove_target"] == "nonland_permanent"
        assert skyclave["target_mana_value_max"] == 4
        assert skyclave["target_nontoken"] is True
        assert skyclave["exile_target"] is True
        assert skyclave["leave_battlefield_illusion_token_status"] == "annotation_only"

        breach = battle.get_card_effect({"name": "Underworld Breach", "type_line": "Enchantment", "cmc": 2})
        assert breach["effect"] == "passive"
        assert breach["escape_grant_status"] == "annotation_only"
        assert breach["end_step_sacrifice_status"] == "annotation_only"

    def test_pg087_hexing_squelcher_static_counter_shield_uses_sqlite_rule():
        active = player("Lorehold")
        opponent = player("Opponent")
        hexing_card = {"name": "Hexing Squelcher", "type_line": "Creature — Goblin Sorcerer", "cmc": 2}
        hexing_effect = battle.get_card_effect(hexing_card)
        battle.apply_effect_immediate(
            active,
            [opponent],
            hexing_card,
            turn=4,
            rng=random.Random(8701),
            effect_data_override=hexing_effect,
        )
        protected_spell = {"name": "Lorehold Spell", "cmc": 4, "type_line": "Sorcery"}
        stack_item = battle.StackItem(
            protected_spell,
            active,
            {"effect": "draw_cards"},
        )
        counterspell = {"name": "Cancel", "cmc": 3, "type_line": "Instant", "effect": "counter"}
        opponent.hand = [counterspell]
        opponent.mana_pool.add("blue", 3)

        assert not opponent.counterspell_cards(
            castable_only=True,
            target_card=protected_spell,
            stack_item=stack_item,
        )

    def test_pg087_skyclave_apparition_exiles_only_nontoken_mv_lte_four_with_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            legal_target = {
                "name": "Legal Engine",
                "cmc": 4,
                "type_line": "Enchantment",
                "effect": "draw_engine",
            }
            opponent.battlefield = [
                {
                    "name": "Large Engine",
                    "cmc": 5,
                    "type_line": "Enchantment",
                    "effect": "draw_engine",
                },
                {
                    "name": "Token Engine",
                    "cmc": 2,
                    "type_line": "Creature Token",
                    "effect": "creature",
                    "tag": "token",
                },
                legal_target,
            ]
            card = {"name": "Skyclave Apparition", "type_line": "Creature — Kor Spirit", "cmc": 3}
            effect_data = battle.get_card_effect(card)
            battle.apply_effect_immediate(
                active,
                [opponent],
                card,
                turn=5,
                rng=random.Random(8702),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert legal_target not in opponent.battlefield
        assert legal_target in opponent.exile
        assert any(
            event == "etb_removal_resolved"
            and data.get("card") == "Skyclave Apparition"
            and data.get("target") == "Legal Engine"
            and data.get("target_type") == "nonland_permanent"
            and data.get("rule_logical_key") == "battle_rule_v1:4f29c7a4bbe21a160f28452406153846"
            and data.get("rule_oracle_hash") == "4d0c162906712b2c428b754ad2f0b3a0"
            for event, data in events
        )

    def test_pg089_removal_compensation_creature_tokens_are_created_for_target_controller():
        expected = {
            "Generous Gift": (
                "battle_rule_v1:70fa2e668d7c5e40f055c04c01d25a6c",
                "9363edd299df8476da36798bd527cde1",
                "destroy_target_permanent_create_3_3_green_elephant_for_controller_v1",
                "permanent",
                "Elephant",
                3,
            ),
            "Stroke of Midnight": (
                "battle_rule_v1:9b50d2f897b561c8c390c9e0e04da417",
                "a885e8190e19cf23b1f4c82563ca111b",
                "destroy_target_nonland_permanent_create_1_1_white_human_for_controller_v1",
                "nonland_permanent",
                "Human",
                1,
            ),
        }
        for name, (logical_key, oracle_hash, scope, target_type, token_name, token_power) in expected.items():
            effect_data = battle.get_card_effect({"name": name, "type_line": "Instant", "cmc": 3})
            assert effect_data["_rule_logical_key"] == logical_key
            assert effect_data["_rule_oracle_hash"] == oracle_hash
            assert effect_data["battle_model_scope"] == scope
            assert effect_data["target"] == target_type
            assert effect_data["target_controller_creature_tokens"] == 1
            assert effect_data["target_controller_token_name"] == token_name
            assert effect_data["target_controller_token_power"] == token_power

        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            target = {
                "name": "Threat Engine",
                "cmc": 3,
                "type_line": "Artifact",
                "effect": "ramp_engine",
            }
            opponent.battlefield = [target]
            spell = {"name": "Generous Gift", "type_line": "Instant", "cmc": 3}
            generous_effect = battle.get_card_effect(spell)

            battle.apply_effect_immediate(
                active,
                [opponent],
                spell,
                turn=5,
                rng=random.Random(989),
                effect_data_override=generous_effect,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert target not in opponent.battlefield
        token = next(card for card in opponent.battlefield if card.get("name") == "Elephant")
        assert token["power"] == 3
        assert token["toughness"] == 3
        assert token["type_line"] == "Creature Token — Elephant"
        assert token["colors"] == ["G"]
        assert any(
            event == "compensation_tokens_created"
            and data.get("token") == "Elephant"
            and data.get("target_controller_creature_tokens") == 1
            and data.get("compensation_token_status") == "dynamic_creature_token_executor"
            and data.get("rule_logical_key") == "battle_rule_v1:70fa2e668d7c5e40f055c04c01d25a6c"
            and data.get("rule_oracle_hash") == "9363edd299df8476da36798bd527cde1"
            for event, data in events
        )

    def test_pg089_l6_removal_compensation_rules_resolve_from_sqlite_cache():
        expected = {
            "Generous Gift": (
                "battle_rule_v1:70fa2e668d7c5e40f055c04c01d25a6c",
                "9363edd299df8476da36798bd527cde1",
                "destroy_target_permanent_create_3_3_green_elephant_for_controller_v1",
                "permanent",
                "Elephant",
                3,
                3,
                ["G"],
            ),
            "Stroke of Midnight": (
                "battle_rule_v1:9b50d2f897b561c8c390c9e0e04da417",
                "a885e8190e19cf23b1f4c82563ca111b",
                "destroy_target_nonland_permanent_create_1_1_white_human_for_controller_v1",
                "nonland_permanent",
                "Human",
                1,
                1,
                ["W"],
            ),
        }
        for name, (logical_key, oracle_hash, scope, target, token_name, power, toughness, colors) in expected.items():
            effect_data = battle.get_card_effect({"name": name, "type_line": "Instant", "cmc": 3})
            assert effect_data["_rule_logical_key"] == logical_key
            assert effect_data["_rule_oracle_hash"] == oracle_hash
            assert effect_data["battle_model_scope"] == scope
            assert effect_data["target"] == target
            assert effect_data["target_controller_creature_tokens"] == 1
            assert effect_data["target_controller_token_name"] == token_name
            assert effect_data["target_controller_token_power"] == power
            assert effect_data["target_controller_token_toughness"] == toughness
            assert effect_data["target_controller_token_colors"] == colors
            assert effect_data["compensation_token_status"] == "dynamic_creature_token_executor"

    def test_pg091_token_maker_family_runtime_support():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponents = [player("Opponent A"), player("Opponent B"), player("Opponent C")]
            battle.apply_effect_immediate(
                active,
                opponents,
                {"name": "Furygale Flocking", "type_line": "Sorcery", "cmc": 10},
                turn=7,
                rng=random.Random(9101),
                effect_data_override={
                    "effect": "token_maker",
                    "token_count_per_opponent": 2,
                    "token_name": "Elemental Token",
                    "token_subtype": "Elemental",
                    "token_colors": ["U", "R"],
                    "token_power": 3,
                    "token_toughness": 3,
                    "token_flying": True,
                    "token_haste": True,
                    "battle_model_scope": "per_opponent_two_3_3_flying_hasty_elemental_tokens_v1",
                    "_rule_logical_key": "battle_rule_v1:63b66f50aad09aa5669ac693b2fca7e5",
                    "_rule_oracle_hash": "8946b0e85c8430c6105ea70c7fb2724a",
                },
            )

            pianist = {
                "name": "Prismari Pianist",
                "cmc": 3,
                "type_line": "Creature — Djinn Bard",
                "effect": "token_maker",
                "trigger": "instant_sorcery_cast",
                "trigger_effect": "token_maker",
                "trigger_token_count": 1,
                "trigger_token_count_if_spell_cmc_at_least": 5,
                "trigger_token_count_at_or_above_threshold": 3,
                "token_name": "Elemental Token",
                "token_subtype": "Elemental",
                "token_colors": ["U", "R"],
                "token_power": 1,
                "token_toughness": 1,
                "battle_model_scope": "instant_sorcery_cast_create_1_or_3_1_1_elementals_by_spell_mv_v1",
                "_rule_logical_key": "battle_rule_v1:0288989021534a6f036968f62361f634",
                "_rule_oracle_hash": "1594ae692e3095e544f3cd3430d43e86",
            }
            active.battlefield.append(pianist)
            before_small = len(active.battlefield)
            battle.trigger_spell_cast_engines(
                active,
                [active, *opponents],
                {"name": "Lightning Helix", "type_line": "Instant", "cmc": 2},
                turn=7,
                phase="precombat_main",
            )
            after_small = len(active.battlefield)
            battle.trigger_spell_cast_engines(
                active,
                [active, *opponents],
                {"name": "Apex Spell", "type_line": "Sorcery", "cmc": 5},
                turn=7,
                phase="precombat_main",
            )

            active.library = [{"name": "Drawn Card", "type_line": "Sorcery", "cmc": 1}]
            battle.apply_effect_immediate(
                active,
                opponents,
                {"name": "Tempt with Bunnies", "type_line": "Sorcery", "cmc": 3},
                turn=7,
                rng=random.Random(9102),
                effect_data_override={
                    "effect": "composite_resolution",
                    "_rule_logical_key": (
                        "battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80+"
                        "battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86"
                    ),
                    "_rule_oracle_hash": "201f6c7234bfef550f3d497e736f0d7a",
                    "_composite_rule_components": [
                        {
                            "effect": "draw_cards",
                            "count": 1,
                            "battle_model_scope": "tempting_offer_base_draw_one_component_v1",
                        },
                        {
                            "effect": "token_maker",
                            "token_count": 1,
                            "token_name": "Rabbit Token",
                            "token_subtype": "Rabbit",
                            "token_colors": ["W"],
                            "token_power": 1,
                            "token_toughness": 1,
                            "battle_model_scope": "tempting_offer_base_create_1_1_white_rabbit_component_v1",
                        },
                    ],
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        furygale_tokens = [
            permanent
            for permanent in active.battlefield
            if permanent.get("name") == "Elemental Token"
            and permanent.get("power") == 3
            and permanent.get("flying") is True
            and permanent.get("haste") is True
        ]
        assert len(furygale_tokens) == 6
        assert all(token.get("colors") == ["U", "R"] for token in furygale_tokens)
        assert after_small == before_small + 1
        pianist_tokens = [
            permanent
            for permanent in active.battlefield
            if permanent.get("name") == "Elemental Token"
            and permanent.get("power") == 1
        ]
        assert len(pianist_tokens) == 4
        rabbit = next(permanent for permanent in active.battlefield if permanent.get("name") == "Rabbit Token")
        assert rabbit["power"] == 1
        assert rabbit["toughness"] == 1
        assert rabbit["colors"] == ["W"]
        assert [card.get("name") for card in active.hand] == ["Drawn Card"]
        assert any(
            event == "tokens_created"
            and data.get("card") == "Furygale Flocking"
            and data.get("tokens_created") == 6
            and data.get("token_count_per_opponent") == 2
            and data.get("rule_logical_key") == "battle_rule_v1:63b66f50aad09aa5669ac693b2fca7e5"
            for event, data in events
        )
        assert any(
            event == "trigger_resolved"
            and data.get("card") == "Prismari Pianist"
            and data.get("trigger_spell") == "Apex Spell"
            and data.get("tokens_created") == 3
            and data.get("token_count_if_spell_cmc_at_least") == 5
            for event, data in events
        )
        assert any(
            event == "composite_rule_resolved"
            and data.get("card") == "Tempt with Bunnies"
            and data.get("components_applied") == 2
            for event, data in events
        )

    def test_patrol_signaler_postcombat_activation_creates_token_and_untaps():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            active = player("Lorehold")
            active.battlefield = [
                {
                    "name": "Patrol Signaler",
                    "cmc": 2,
                    "type_line": "Creature - Kithkin Soldier",
                    "effect": "creature",
                    "power": 1,
                    "toughness": 1,
                    "activated_create_token": True,
                    "activation_requires_source_tapped": True,
                    "activation_uses_untap_symbol": True,
                    "activation_cost_generic": 1,
                    "activation_cost_colors": ["W"],
                    "token_count": 1,
                    "token_name": "Kithkin Soldier Token",
                    "token_subtype": "Kithkin Soldier",
                    "token_colors": ["W"],
                    "token_power": 1,
                    "token_toughness": 1,
                    "summoning_sick": False,
                    "tapped": True,
                    "battle_model_scope": "activated_untap_self_create_1_1_white_kithkin_soldier_token_v1",
                    "_rule_logical_key": "battle_rule_v1:patrolsignaler",
                    "_rule_oracle_hash": "patrolsignalerhash",
                },
                {
                    "name": "Plains",
                    "effect": "land",
                    "type_line": "Basic Land - Plains",
                    "produces": "W",
                    "mana_produced": 1,
                },
                {
                    "name": "Mountain",
                    "effect": "land",
                    "type_line": "Basic Land - Mountain",
                    "produces": "R",
                    "mana_produced": 1,
                },
            ]
            active.refresh_mana_sources(turn=5)

            battle.activate_postcombat_token_creatures(active, [player("Opponent")], turn=5)
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        signaler = next(card for card in active.battlefield if isinstance(card, dict) and card.get("name") == "Patrol Signaler")
        kithkins = [
            card
            for card in active.battlefield
            if isinstance(card, dict) and card.get("name") == "Kithkin Soldier Token"
        ]
        assert signaler.get("tapped") is False
        assert len(kithkins) == 1
        assert kithkins[0].get("power") == 1
        assert kithkins[0].get("toughness") == 1
        assert kithkins[0].get("colors") == ["W"]
        assert any(
            event == "activated_ability"
            and data.get("card") == "Patrol Signaler"
            and data.get("activation_kind") == "untap_self_create_token"
            and data.get("tokens_created") == 1
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "utility_creature_activation"
            and decision.get("chosen_option", {}).get("action") == "activate_postcombat_token_maker"
            for decision in decisions
        )

    def test_patrol_signaler_skips_when_not_tapped_for_untap_activation():
        events = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            active.battlefield = [
                {
                    "name": "Patrol Signaler",
                    "cmc": 2,
                    "type_line": "Creature - Kithkin Soldier",
                    "effect": "creature",
                    "power": 1,
                    "toughness": 1,
                    "activated_create_token": True,
                    "activation_requires_source_tapped": True,
                    "activation_uses_untap_symbol": True,
                    "activation_cost_generic": 1,
                    "activation_cost_colors": ["W"],
                    "token_count": 1,
                    "token_name": "Kithkin Soldier Token",
                    "token_subtype": "Kithkin Soldier",
                    "token_colors": ["W"],
                    "token_power": 1,
                    "token_toughness": 1,
                    "summoning_sick": False,
                    "tapped": False,
                    "battle_model_scope": "activated_untap_self_create_1_1_white_kithkin_soldier_token_v1",
                },
                {
                    "name": "Plains",
                    "effect": "land",
                    "type_line": "Basic Land - Plains",
                    "produces": "W",
                    "mana_produced": 1,
                },
                {
                    "name": "Mountain",
                    "effect": "land",
                    "type_line": "Basic Land - Mountain",
                    "produces": "R",
                    "mana_produced": 1,
                },
            ]
            active.refresh_mana_sources(turn=5)

            battle.activate_postcombat_token_creatures(active, [player("Opponent")], turn=5)
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler

        assert not any(
            isinstance(card, dict) and card.get("name") == "Kithkin Soldier Token"
            for card in active.battlefield
        )
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Patrol Signaler"
            and data.get("reason") == "source_not_tapped_for_untap_activation"
            for event, data in events
        )

    def test_eldrazi_confluence_creates_three_scions_when_no_other_modes_are_live():
        events = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            battle.apply_effect_immediate(
                active,
                [opponent],
                {"name": "Eldrazi Confluence", "type_line": "Instant", "cmc": 4},
                turn=8,
                rng=random.Random(1461),
                effect_data_override={
                    "effect": "modal_spell",
                    "instant": True,
                    "modal_choose_count": 3,
                    "modal_may_repeat_modes": True,
                    "mode_target_creature_plus_three_minus_three": True,
                    "mode_blink_target_nonland_permanent_tapped": True,
                    "mode_create_eldrazi_scion": True,
                    "token_name": "Eldrazi Scion Token",
                    "token_subtype": "Eldrazi Scion",
                    "token_power": 1,
                    "token_toughness": 1,
                    "token_colors": [],
                    "token_sacrifice_for_colorless_mana": True,
                    "battle_model_scope": "choose_three_pump_blink_tapped_or_create_eldrazi_scion_v1",
                    "_rule_logical_key": "battle_rule_v1:eldrazi_confluence",
                    "_rule_oracle_hash": "eldrazi_confluence_hash",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler

        scions = [
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("name") == "Eldrazi Scion Token"
        ]
        assert len(scions) == 3
        assert all(permanent.get("sacrifice_for_colorless_mana") is True for permanent in scions)
        resolved = next(
            data
            for event, data in events
            if event == "modal_spell_resolved" and data.get("card") == "Eldrazi Confluence"
        )
        assert [entry.get("mode") for entry in resolved.get("selected_modes", [])] == [
            "create_eldrazi_scion",
            "create_eldrazi_scion",
            "create_eldrazi_scion",
        ]

    def test_eldrazi_confluence_uses_pump_then_blink_then_scion_when_context_exists():
        events = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            active.library = [{"name": "Blink Draw", "type_line": "Instant", "cmc": 1}]
            wall = {
                "name": "Wall of Omens",
                "cmc": 2,
                "effect": "creature",
                "type_line": "Creature - Wall",
                "power": 0,
                "toughness": 4,
                "etb_draw_count": 1,
            }
            active.battlefield = [wall]
            opponent = player("Opponent")
            opponent.battlefield = [
                {
                    "name": "Opp Threat",
                    "cmc": 3,
                    "effect": "creature",
                    "type_line": "Creature - Beast",
                    "power": 3,
                    "toughness": 3,
                }
            ]
            battle.apply_effect_immediate(
                active,
                [opponent],
                {"name": "Eldrazi Confluence", "type_line": "Instant", "cmc": 4},
                turn=8,
                rng=random.Random(1462),
                effect_data_override={
                    "effect": "modal_spell",
                    "instant": True,
                    "modal_choose_count": 3,
                    "modal_may_repeat_modes": True,
                    "mode_target_creature_plus_three_minus_three": True,
                    "mode_blink_target_nonland_permanent_tapped": True,
                    "mode_create_eldrazi_scion": True,
                    "token_name": "Eldrazi Scion Token",
                    "token_subtype": "Eldrazi Scion",
                    "token_power": 1,
                    "token_toughness": 1,
                    "token_colors": [],
                    "token_sacrifice_for_colorless_mana": True,
                    "battle_model_scope": "choose_three_pump_blink_tapped_or_create_eldrazi_scion_v1",
                    "_rule_logical_key": "battle_rule_v1:eldrazi_confluence",
                    "_rule_oracle_hash": "eldrazi_confluence_hash",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler

        assert not any(
            isinstance(permanent, dict) and permanent.get("name") == "Opp Threat"
            for permanent in opponent.battlefield
        )
        wall_after = next(
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("name") == "Wall of Omens"
        )
        scions = [
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("name") == "Eldrazi Scion Token"
        ]
        assert wall_after.get("tapped") is True
        assert [card.get("name") for card in active.hand] == ["Blink Draw"]
        assert len(scions) == 1
        resolved = next(
            data
            for event, data in events
            if event == "modal_spell_resolved" and data.get("card") == "Eldrazi Confluence"
        )
        assert [entry.get("mode") for entry in resolved.get("selected_modes", [])] == [
            "target_creature_plus_three_minus_three",
            "blink_target_nonland_permanent_tapped",
            "create_eldrazi_scion",
        ]

    def test_pg091_deck607_token_maker_rules_resolve_from_sqlite_cache():
        expected_single_rules = {
            "Furygale Flocking": (
                "battle_rule_v1:63b66f50aad09aa5669ac693b2fca7e5",
                "8946b0e85c8430c6105ea70c7fb2724a",
                "per_opponent_two_3_3_flying_hasty_elemental_tokens_v1",
            ),
            "Prismari Pianist": (
                "battle_rule_v1:0288989021534a6f036968f62361f634",
                "1594ae692e3095e544f3cd3430d43e86",
                "instant_sorcery_cast_create_1_or_3_1_1_elementals_by_spell_mv_v1",
            ),
        }
        for name, (logical_key, oracle_hash, scope) in expected_single_rules.items():
            effect_data = battle.get_card_effect({"name": name, "type_line": "Sorcery", "cmc": 3})
            assert effect_data["_rule_logical_key"] == logical_key
            assert effect_data["_rule_oracle_hash"] == oracle_hash
            assert effect_data["battle_model_scope"] == scope
            assert effect_data["effect"] == "token_maker"

        tempt_effect = battle.get_card_effect({"name": "Tempt with Bunnies", "type_line": "Sorcery", "cmc": 3})
        assert tempt_effect["effect"] == "composite_resolution"
        assert tempt_effect["_rule_oracle_hash"] == "201f6c7234bfef550f3d497e736f0d7a"
        component_keys = {
            component.get("_rule_logical_key")
            for component in tempt_effect.get("_composite_rule_components", [])
        }
        assert component_keys == {
            "battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80",
            "battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86",
        }
        scopes = {
            component.get("battle_model_scope")
            for component in tempt_effect.get("_composite_rule_components", [])
        }
        assert scopes == {
            "tempting_offer_base_draw_one_component_v1",
            "tempting_offer_base_create_1_1_white_rabbit_component_v1",
        }

    def test_pg114_emerias_call_creates_angels_and_protects_non_angels_until_next_turn():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            non_angel = {
                "name": "Seasoned Pyromancer",
                "cmc": 3,
                "effect": "creature",
                "type_line": "Creature — Human Shaman",
                "power": 2,
                "toughness": 2,
            }
            angel = {
                "name": "Serra Angel",
                "cmc": 5,
                "effect": "creature",
                "type_line": "Creature — Angel",
                "power": 4,
                "toughness": 4,
                "flying": True,
            }
            active.battlefield = [non_angel, angel]
            battle.apply_effect_immediate(
                active,
                [opponent],
                {"name": "Emeria's Call // Emeria, Shattered Skyclave", "type_line": "Sorcery", "cmc": 7},
                turn=7,
                rng=random.Random(114),
                effect_data_override={
                    "effect": "token_maker",
                    "token_count": 2,
                    "token_name": "Angel Warrior Token",
                    "token_subtype": "Angel Warrior",
                    "token_colors": ["W"],
                    "token_power": 4,
                    "token_toughness": 4,
                    "token_flying": True,
                    "grant_non_angel_creatures_indestructible_until_next_turn": True,
                    "battle_model_scope": "create_two_4_4_flying_angel_warrior_tokens_non_angel_indestructible_until_next_turn_v1",
                    "_rule_logical_key": "battle_rule_v1:ae4a933d873bec332ec2a46106b79277",
                    "_rule_oracle_hash": "2fab1a2b9eb87041bc9e93f3b8d52831",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        tokens = [
            permanent
            for permanent in active.battlefield
            if permanent.get("name") == "Angel Warrior Token"
        ]
        assert len(tokens) == 2
        assert all(token["power"] == 4 and token["toughness"] == 4 for token in tokens)
        assert all(token.get("flying") is True for token in tokens)
        assert all(token.get("indestructible") is not True for token in tokens)
        assert non_angel.get("indestructible") is True
        assert angel.get("indestructible") is not True
        assert any(
            event == "tokens_created"
            and data.get("card") == "Emeria's Call // Emeria, Shattered Skyclave"
            and data.get("tokens_created") == 2
            and data.get("protected_non_angel_creature_count") == 1
            for event, data in events
        )
        assert any(
            event == "protection_resolved"
            and data.get("card") == "Emeria's Call // Emeria, Shattered Skyclave"
            and data.get("target_scope") == "non_angel_creatures_you_control"
            and data.get("duration") == "until_your_next_turn"
            and data.get("affected") == ["Seasoned Pyromancer"]
            for event, data in events
        )
        battle.clear_until_next_turn_effects(active, 7)
        assert non_angel.get("indestructible") is True
        battle.clear_until_next_turn_effects(active, 8)
        assert non_angel.get("indestructible") is not True

    def test_pg114_emerias_call_rule_resolves_from_sqlite_cache():
        effect_data = battle.get_card_effect(
            {"name": "Emeria's Call // Emeria, Shattered Skyclave", "type_line": "Sorcery", "cmc": 7}
        )
        assert effect_data["_rule_logical_key"] == "battle_rule_v1:ae4a933d873bec332ec2a46106b79277"
        assert effect_data["_rule_oracle_hash"] == "2fab1a2b9eb87041bc9e93f3b8d52831"
        assert effect_data["effect"] == "token_maker"
        assert effect_data["token_count"] == 2
        assert effect_data["token_name"] == "Angel Warrior Token"
        assert effect_data["token_power"] == 4
        assert effect_data["token_toughness"] == 4
        assert effect_data["token_flying"] is True
        assert effect_data["grant_non_angel_creatures_indestructible_until_next_turn"] is True
        assert (
            effect_data["battle_model_scope"]
            == "create_two_4_4_flying_angel_warrior_tokens_non_angel_indestructible_until_next_turn_v1"
        )

    def test_pg092_deck608_modal_interaction_rules_resolve_from_sqlite_cache():
        return_effect = battle.get_card_effect(
            {"name": "Return the Favor", "type_line": "Instant", "cmc": 2}
        )
        assert return_effect["effect"] == "copy_spell"
        assert return_effect["_rule_logical_key"] == "battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2"
        assert return_effect["_rule_oracle_hash"] == "a24911b7ea2027ebba59bb6792eee776"
        assert (
            return_effect["battle_model_scope"]
            == "spree_copy_instant_or_sorcery_stack_spell_change_target_annotation_v1"
        )
        assert return_effect["target"] == "instant_or_sorcery_on_stack"
        assert return_effect["may_choose_new_targets"] is True
        assert return_effect["spree_additional_cost_status"] == "annotation_only"
        assert return_effect["copy_activated_triggered_ability_status"] == "annotation_only"
        assert return_effect["change_target_mode_status"] == "annotation_only"

        untimely_effect = battle.get_card_effect(
            {"name": "Untimely Malfunction", "type_line": "Instant", "cmc": 2}
        )
        assert untimely_effect["effect"] == "remove_permanent"
        assert untimely_effect["_rule_logical_key"] == "battle_rule_v1:667ba8e5e69696402f9cd213886e57a8"
        assert untimely_effect["_rule_oracle_hash"] == "877f2d75c90c7886ca9536135829bb90"
        assert (
            untimely_effect["battle_model_scope"]
            == "modal_destroy_artifact_redirect_or_cant_block_annotation_v1"
        )
        assert untimely_effect["target"] == "artifact"
        assert untimely_effect["destroy_artifact_mode"] is True
        assert untimely_effect["redirect_target_mode_status"] == "annotation_only"
        assert untimely_effect["cant_block_mode_status"] == "annotation_only"

    def test_pg092_untimely_malfunction_removes_artifact_only_with_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            artifact = {
                "name": "Mana Rock",
                "type_line": "Artifact",
                "effect": "ramp_permanent",
                "cmc": 2,
            }
            creature = {
                "name": "Opponent Creature",
                "type_line": "Creature — Human",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "cmc": 2,
            }
            opponent.battlefield = [artifact, creature]
            card = {"name": "Untimely Malfunction", "type_line": "Instant", "cmc": 2}
            effect_data = battle.get_card_effect(card)

            assert battle.target_matches_type(artifact, effect_data["target"])
            assert not battle.target_matches_type(creature, effect_data["target"])

            battle.apply_effect_immediate(
                active,
                [opponent],
                card,
                5,
                random.Random(9202),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert artifact not in opponent.battlefield
        assert creature in opponent.battlefield
        assert any(card.get("name") == "Mana Rock" for card in opponent.graveyard)
        assert any(
            event == "removal_resolved"
            and data.get("card") == "Untimely Malfunction"
            and data.get("target") == "Mana Rock"
            and data.get("target_type") == "artifact"
            and data.get("rule_logical_key") == "battle_rule_v1:667ba8e5e69696402f9cd213886e57a8"
            for event, data in events
        )

    def test_pg092_return_the_favor_requires_stack_spell_target_with_rule_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            card = {"name": "Return the Favor", "type_line": "Instant", "cmc": 2}
            effect_data = battle.get_card_effect(card)
            battle.apply_effect_immediate(
                active,
                [],
                card,
                5,
                random.Random(9203),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert any(card.get("name") == "Return the Favor" for card in active.graveyard)
        assert not any(
            permanent.get("name") == "Return the Favor"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(
            event == "copy_spell_no_stack_target"
            and data.get("card") == "Return the Favor"
            and data.get("rule_logical_key") == "battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2"
            and data.get("rule_oracle_hash") == "a24911b7ea2027ebba59bb6792eee776"
            for event, data in events
        )

    def test_pg093_insurrection_uses_compact_steal_attack_runtime():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent_a = player("Opponent A")
            opponent_b = player("Opponent B")
            active_creature = {
                "name": "Lorehold Bodyguard",
                "type_line": "Creature - Human Soldier",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "cmc": 2,
            }
            opponent_a_creature = {
                "name": "Rival Giant",
                "type_line": "Creature - Giant",
                "effect": "creature",
                "power": 3,
                "toughness": 3,
                "cmc": 4,
            }
            opponent_b_creature_1 = {
                "name": "Rival Dragon",
                "type_line": "Creature - Dragon",
                "effect": "creature",
                "power": 4,
                "toughness": 4,
                "cmc": 5,
            }
            opponent_b_creature_2 = {
                "name": "Rival Soldier",
                "type_line": "Creature - Soldier",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "cmc": 2,
            }
            opponent_artifact = {
                "name": "Mana Rock",
                "type_line": "Artifact",
                "effect": "ramp_permanent",
                "cmc": 2,
            }
            active.battlefield = [active_creature]
            opponent_a.battlefield = [opponent_a_creature, opponent_artifact]
            opponent_b.battlefield = [opponent_b_creature_1, opponent_b_creature_2]
            card = {"name": "Insurrection", "type_line": "Sorcery", "cmc": 8}
            effect_data = {
                "effect": "steal_all_creatures",
                "battle_model_scope": "steal_all_creatures_until_eot_haste_attack_projection_v1",
                "oracle_runtime_scope": (
                    "untap_gain_control_all_creatures_haste_until_eot_"
                    "compact_damage_projection_v1"
                ),
                "control_duration": "until_end_of_turn",
                "untap_stolen_creatures": True,
                "stolen_creatures_gain_haste": True,
                "runtime_model": "compact_damage_projection",
                "_rule_logical_key": "battle_rule_v1:e6b0d9f25aff060aa1f813e43154c954",
                "_rule_oracle_hash": "a756d0c90be63a18b7eaf97582e75b8e",
            }

            battle.apply_effect_immediate(
                active,
                [opponent_a, opponent_b],
                card,
                6,
                random.Random(9301),
                effect_data_override=effect_data,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert active_creature in active.battlefield
        assert opponent_artifact in opponent_a.battlefield
        assert not any(battle.is_battlefield_creature(card) for card in opponent_a.battlefield)
        assert not any(battle.is_battlefield_creature(card) for card in opponent_b.battlefield)
        assert opponent_a.life == 36
        assert opponent_b.life == 36
        assert any(card.get("name") == "Insurrection" for card in active.graveyard)
        assert any(
            event == "steal_all_creatures_resolved"
            and data.get("card") == "Insurrection"
            and data.get("stolen_count") == 3
            and data.get("total_power") == 9
            and data.get("damage_each_opponent") == 4
            and data.get("damaged_opponents") == ["Opponent A", "Opponent B"]
            and data.get("control_duration") == "until_end_of_turn"
            and data.get("stolen_creatures_gain_haste") is True
            and data.get("runtime_model") == "compact_damage_projection"
            and data.get("rule_logical_key") == "battle_rule_v1:e6b0d9f25aff060aa1f813e43154c954"
            and data.get("rule_oracle_hash") == "a756d0c90be63a18b7eaf97582e75b8e"
            for event, data in events
        )

    def test_pg093_insurrection_rule_resolves_from_sqlite_cache():
        effect_data = battle.get_card_effect({"name": "Insurrection", "type_line": "Sorcery", "cmc": 8})
        assert effect_data["effect"] == "steal_all_creatures"
        assert effect_data["_rule_logical_key"] == "battle_rule_v1:e6b0d9f25aff060aa1f813e43154c954"
        assert effect_data["_rule_oracle_hash"] == "a756d0c90be63a18b7eaf97582e75b8e"
        assert (
            effect_data["battle_model_scope"]
            == "steal_all_creatures_until_eot_haste_attack_projection_v1"
        )
        assert (
            effect_data["oracle_runtime_scope"]
            == "untap_gain_control_all_creatures_haste_until_eot_compact_attack_projection_v1"
        )
        assert effect_data["control_duration"] == "until_end_of_turn"
        assert effect_data["untap_stolen_creatures"] is True
        assert effect_data["stolen_creatures_gain_haste"] is True
        assert effect_data["runtime_model"] == "compact_damage_projection"

    def test_pg079_deck606_high_rules_resolve_from_sqlite_cache():
        expected = {
            "Flare of Duplication": (
                "battle_rule_v1:b82bbb548dab138fa0700cb4cf905617",
                "3b1f1bcd5e69cb1f5f306e83345b2a1f",
                "copy_target_instant_or_sorcery_stack_spell_alt_cost_annotation_v1",
            ),
            "Powerbalance": (
                "battle_rule_v1:e35051e9c60b94a84ac9b71c11c7fc4b",
                "8cbde54a4e2e1464a5deb5171928e203",
                "opponent_spell_reveal_top_same_mana_value_free_cast_v1",
            ),
            "Reforge the Soul": (
                "battle_rule_v1:90b82cfc81ff726ac0fc96a1b220f263",
                "041645992d04029f74855292bb1459f4",
                "each_player_discard_hand_draw_seven_miracle_annotation_v1",
            ),
            "Rise of the Eldrazi": (
                "battle_rule_v1:57d155e410ca3cc6a96e14ed50f524d4",
                "6cad51822d2ad0e019c29770033c7d21",
                "uncounterable_destroy_target_permanent_target_player_draw_four_extra_turn_exile_v1",
            ),
            "Rite of the Dragoncaller": (
                "battle_rule_v1:b23bca3229a81d65750cf9c453c7943d",
                "9308f0eadf924f7ea0c8ea2463224c9a",
                "instant_sorcery_cast_create_5_5_flying_dragon_v1",
            ),
            "Storm Herd": (
                "battle_rule_v1:b041641dc875caa7987253389dc52839",
                "25e798eec6b64f1ae52d3af1ca8597dd",
                "life_total_flying_pegasus_token_maker_v1",
            ),
            "Witch Enchanter // Witch-Blessed Meadow": (
                "battle_rule_v1:5768b971f1ab4f2d4d9b8bd6a768c132",
                "cd5355a1a3cd44df9237726d9e3006c5",
                "creature_etb_destroy_opponent_artifact_or_enchantment_v1",
            ),
        }
        for name, (logical_key, oracle_hash, scope) in expected.items():
            effect_data = battle.get_card_effect({"name": name, "type_line": "Instant", "cmc": 1})
            assert effect_data["_rule_logical_key"] == logical_key
            assert effect_data["_rule_oracle_hash"] == oracle_hash
            assert effect_data["battle_model_scope"] == scope

    return [
        test_lorehold_miracle_requires_lorehold_on_battlefield,
        test_lorehold_miracle_casts_first_draw_only_with_lorehold,
        test_lorehold_miracle_does_not_use_second_draw_of_turn,
        test_lorehold_miracle_skips_bad_wheel_refill,
        test_lorehold_miracle_does_not_cast_counter_without_stack_target,
        test_lorehold_miracle_does_not_cast_redirect_without_stack_target,
        test_lorehold_upkeep_rummage_emits_pg035_rule_provenance,
        test_past_in_flames_grants_flashback_with_pg036_rule_provenance,
        test_flashback_targeted_removal_declares_target_before_resolution,
        test_path_to_exile_exiles_creature_with_pg037_rule_provenance,
        test_swords_to_plowshares_exiles_creature_and_gains_power_life_with_pg040_rule_provenance,
        test_pg095_winds_of_abandon_exiles_opponent_creature_with_rule_provenance,
        test_pg096_high_noon_is_passive_static_rule_not_creature_removal,
        test_teferis_protection_phases_all_permanents_locks_life_and_exiles_self_with_pg041_rule_provenance,
        test_reverberate_copies_stack_spell_with_pg038_rule_provenance,
        test_reiterate_copies_stack_spell_with_pg068_rule_provenance,
        test_dualcaster_mage_etb_copies_stack_spell_with_pg068_rule_provenance,
        test_deflecting_swat_redirects_targeted_removal_for_free_with_commander,
        test_flawless_maneuver_protects_creatures_for_free_with_commander,
        test_landfall_does_not_enqueue_without_real_landfall_source,
        test_landfall_enqueue_with_real_landfall_source,
        test_reforge_resolution_draws_seven_when_count_missing,
        test_boros_charm_protects_creatures_until_cleanup,
        test_boros_charm_grants_indestructible_to_all_permanents_until_cleanup,
        test_boros_charm_double_strike_targets_one_creature_until_cleanup,
        test_dawns_truce_oracle_normalizes_to_gift_hexproof_indestructible,
        test_dawns_truce_gifts_card_and_grants_hexproof_indestructible_until_cleanup,
        test_austere_command_resolves_two_destroy_modes,
        test_blasphemous_act_deals_13_damage_to_each_creature,
        test_pg098_call_forth_tempest_uses_dynamic_opponent_creature_damage,
        test_pg099_avatars_wrath_airbends_all_other_creatures_and_locks_nonhand_casts,
        test_akromas_will_keywords_are_until_end_of_turn_without_power_boost,
        test_mox_amber_only_counts_mana_with_live_legend,
        test_silence_effect_blocks_counterspell_responses,
        test_lorehold_miracle_ignores_lands_and_creatures,
        test_lorehold_miracle_rejects_flash_creatures,
        test_silence_spell_blocks_responses_until_cleanup_only,
        test_pg054_silence_lock_family_rule_provenance,
        test_pg055_artifact_mana_rock_family_rule_provenance,
        test_pg058_simple_red_ritual_family_rule_provenance,
        test_pg058_simple_red_ritual_family_runtime_adds_one_shot_mana,
        test_pg080_deck606_l3_mana_ramp_family_rule_provenance,
        test_pg080_monologue_tax_creates_treasure_on_opponent_second_spell,
        test_pg080_mox_opal_requires_metalcraft_for_mana,
        test_pg080_simian_spirit_guide_exiles_from_hand_for_one_mana,
        test_pg082_deck6_606_hash_only_rules_resolve_from_sqlite_cache,
        test_pg094_deck6_606_l2_hash_restore_rules_resolve_from_sqlite_cache,
        test_samis_curiosity_creates_lander_token_not_tutor,
        test_audit_promoted_cards_keep_conservative_semantics,
        test_snapback_return_target_creature_stays_creature_removal,
        test_functional_tag_gate_cards_resolve_from_manual_waivers,
        test_basking_broodscale_enters_as_creature_not_immediate_token_maker,
        test_scavenging_ooze_enters_as_creature_not_immediate_removal,
        test_mox_diamond_discards_land_when_it_unlocks_commander,
        test_mox_diamond_does_not_spend_last_land_without_payoff,
        test_mox_diamond_does_not_claim_unaffordable_commander_payoff,
        test_chrome_mox_imprints_colored_nonartifact_nonland_card,
        test_chrome_mox_does_not_cast_without_valid_imprint,
        test_everflowing_chalice_pays_multikicker_before_becoming_mana_source,
        test_everflowing_chalice_does_not_cast_as_zero_mana_ramp,
        test_lightning_greaves_grants_haste_and_shroud_without_indestructible,
        test_static_equipment_applies_boost_and_keywords_to_best_creature,
        test_artifact_etb_tutors_two_basic_plains_to_hand_and_stays_on_battlefield,
        test_archaeomancers_map_opponent_land_trigger_requires_controller_behind_on_lands,
        test_archaeomancers_map_opponent_land_trigger_skips_when_controller_not_behind,
        test_blind_obedience_taps_opponent_artifacts_and_creatures_on_entry,
        test_land_tax_tutors_three_basic_lands_when_opponent_has_more_lands,
        test_land_tax_skips_when_no_opponent_controls_more_lands,
        test_instant_copy_spell_does_not_become_permanent_engine_without_stack_target,
        test_unexpected_windfall_discards_draws_two_creates_two_treasures_with_pg069_rule_provenance,
        test_pg070_faithless_looting_draws_two_discards_two_with_rule_provenance,
        test_pg070_gamble_tutors_then_randomly_discards_with_rule_provenance,
        test_pg071_lotus_petal_is_one_shot_fast_mana_with_rule_provenance,
        test_pg071_ruby_medallion_is_annotation_only_cost_reducer_not_mana_source,
        test_pg072_pyroblast_counters_only_blue_stack_spell_with_rule_provenance,
        test_pg086_counter_target_filter_respects_uncounterable_static_shield,
        test_pg086_removal_targets_filter_nontoken_and_mana_value_max,
        test_pg072_get_lost_removes_allowed_permanent_and_creates_map_tokens,
        test_pg076_chaos_warp_shuffles_target_into_library_and_reveals_top_permanent,
        test_pg077_jeskas_will_uses_opponent_hand_and_impulse_exiles_top_three,
        test_pg077_mizzixs_mastery_exiles_graveyard_spell_and_resolves_copy,
        test_pg106_mizzixs_mastery_copy_declares_target_before_removal_resolution,
        test_pg073_esper_sentinel_draws_on_first_noncreature_spell_with_power_tax,
        test_pg073_wheel_of_misfortune_uses_secret_number_compact_runtime,
        test_pg076_support_passive_annotations_and_ranger_small_creature_tutor,
        test_smothering_tithe_draw_step_creates_treasure_with_rule_provenance,
        test_pg143_tataru_taru_etb_and_off_turn_draw_trigger_create_single_tapped_treasure,
        test_reckless_endeavor_damage_wipe_creates_treasures,
        test_reverse_the_sands_swaps_with_highest_life_opponent,
        test_birgi_adds_red_mana_when_controller_casts_spell,
        test_lotho_second_spell_trigger_creates_treasure_and_loses_life,
        test_pg144_knuckles_combat_damage_trigger_creates_treasure_each_damage_step,
        test_prized_statue_enters_and_dies_create_treasures,
        test_impulsive_pilferer_dies_create_treasure,
        test_electroduplicate_creates_hasty_copy_and_sacrifices_at_end_step,
        test_heat_shimmer_copies_any_creature_and_exiles_token_at_end_step,
        test_twinflame_copies_own_creature_only_and_exiles_token_at_end_step,
        test_molten_duplication_copies_own_artifact_as_artifact_and_sacrifices_token,
        test_flash_photography_copies_target_permanent_without_temporary_cleanup,
        test_clone_legion_copies_each_creature_controlled_by_target_player,
        test_astral_dragon_etb_creates_two_dragon_copies_of_noncreature_permanent,
        test_valakut_awakening_filters_hand_and_draws_plus_one,
        test_valakut_awakening_preserves_approach_as_win_condition,
        test_valakut_awakening_split_name_emits_pg042_rule_provenance,
        test_mulligan_trace_scores_keep_vs_mulligan_for_heavy_dead_hand,
        test_special_lands_are_modelled_as_lands_not_spell_heuristics,
        test_war_room_activates_when_hand_is_low_and_life_is_safe,
        test_war_room_skips_when_life_is_too_low,
        test_sunbaked_canyon_turns_expendable_land_into_card,
        test_sunbaked_canyon_requires_extra_mana_beyond_its_own_tap_proxy,
        test_sunbaked_canyon_skips_when_it_would_cut_too_deep_on_lands,
        test_treasure_vault_cashes_in_expendable_land_for_x_treasures,
        test_treasure_vault_skips_when_land_base_is_too_shallow,
        test_inventors_fair_gains_life_on_upkeep_with_three_artifacts,
        test_inventors_fair_tutors_artifact_when_threshold_and_mana_exist,
        test_inventors_fair_skips_without_artifact_threshold,
        test_hall_of_heliods_generosity_recovers_best_enchantment_to_top,
        test_hall_of_heliods_generosity_skips_without_white_mana,
        test_ancient_tomb_pays_life_only_when_it_unlocks_contextual_play,
        test_ancient_tomb_skips_when_no_relevant_unlock_exists,
        test_ancient_tomb_skips_when_life_is_too_low,
        test_chromatic_star_precombat_unlocks_off_color_spell,
        test_chromatic_star_postcombat_cash_in_when_hand_is_low,
        test_urzas_saga_enters_with_initial_chapter_state,
        test_urzas_saga_creates_construct_on_chapter_two,
        test_urzas_saga_tutors_safe_artifact_then_sacrifices,
        test_land_tutor_artifact_trace_scores_rejected_options,
        test_angels_grace_prevents_lethal_damage_and_life_zero_loss_this_turn,
        test_angels_grace_blocks_opponent_approach_win_this_turn,
        test_senseis_top_sets_up_lorehold_approach_second_cast,
        test_scroll_rack_sets_up_lorehold_approach_second_cast_on_opponent_upkeep,
        test_brainstone_first_draw_approach_wins_before_rummage_resolution,
        test_lorehold_upkeep_rummage_preserves_approach_without_top_replacement,
        test_low_life_casts_approach_before_proactive_attack_tax,
        test_grand_abolisher_casts_as_setup_for_future_approach,
        test_orims_chant_held_without_castable_second_approach_payoff,
        test_cleanup_discard_preserves_attack_tax_over_excess_cards,
        test_enlightened_tutor_puts_artifact_or_enchantment_on_library_top,
        test_idyllic_tutor_finds_enchantment_to_hand_only,
        test_goblin_engineer_etb_tutors_artifact_to_graveyard,
        test_imperial_recruiter_etb_tutors_power_two_creature_to_hand,
        test_recruiter_of_the_guard_etb_tutors_toughness_two_creature_to_hand,
        test_natural_order_sacrifices_green_creature_for_green_battlefield_tutor,
        test_natural_order_does_not_cast_without_green_creature_to_sacrifice,
        test_dismember_applies_stat_modifier_and_kills_indestructible_zero_toughness,
        test_ashnods_altar_sacrifices_token_only_for_contextual_mana_unlock,
        test_goblin_bombardment_sacrifices_expendable_token_for_damage,
        test_goblin_bombardment_review_only_snapshot_does_not_remove_on_cast,
        test_goblin_bombardment_skips_without_expendable_creature,
        test_iron_man_attack_trigger_sacrifices_treasure_for_artifact_tutor,
        test_flame_wave_oracle_and_runtime_damage_target_player_creatures,
        test_aetherflux_reservoir_gains_life_on_future_spell_casts_not_resolution_damage,
        test_brain_freeze_mills_library_instead_of_dealing_life_damage,
        test_thassas_oracle_wins_only_when_library_is_within_blue_devotion,
        test_dragons_approach_deals_fixed_damage_and_tutors_dragon_from_graveyard_cost,
        test_thrumming_stone_ripples_dragons_approach_without_bonus_damage,
        test_pg079_powerbalance_casts_same_mana_value_top_card_without_paying,
        test_pg102_creative_technique_demonstrates_top_nonland_free_casts,
        test_everything_comes_to_dust_oracle_normalizes_to_convoke_exile_wipe,
        test_everything_comes_to_dust_exiles_artifacts_enchantments_and_nonshared_creatures,
        test_fated_clash_oracle_normalizes_to_protect_then_destroy_wipe,
        test_fated_clash_protects_best_own_and_weakest_opponent_creature_then_wipes,
        test_promise_of_loyalty_oracle_normalizes_to_vow_sacrifice_wipe,
        test_promise_of_loyalty_vows_one_creature_each_player_and_blocks_attack_back,
        test_starfall_invocation_oracle_normalizes_to_gift_destroy_return_wipe,
        test_starfall_invocation_destroys_all_creatures_gifts_and_returns_best_own,
        test_monument_to_endurance_oracle_normalizes_to_discard_modal_trigger,
        test_monument_to_endurance_uses_each_discard_mode_once_per_turn,
        test_pg115_monument_to_endurance_rule_resolves_from_sqlite_cache,
        test_the_mind_stone_oracle_normalizes_to_harnessed_blink_mana_rock,
        test_the_mind_stone_harnesses_and_blinks_best_target_at_end_step,
        test_pg117_the_mind_stone_rule_resolves_from_sqlite_cache,
        test_surge_to_victory_oracle_normalizes_to_combat_copy_team_pump,
        test_surge_to_victory_exiles_best_graveyard_spell_and_copies_it_on_combat_damage,
        test_pg118_surge_to_victory_rule_resolves_from_sqlite_cache,
        test_tragic_arrogance_oracle_normalizes_to_selective_nonland_sacrifice,
        test_tragic_arrogance_keeps_best_per_type_and_sacrifices_other_nonlands,
        test_pg079_flare_of_duplication_keeps_copy_spell_as_stack_targeted_instant,
        test_pg079_reforge_the_soul_discards_then_draws_seven_with_scope,
        test_pg079_rise_of_the_eldrazi_resolves_composite_destroy_draw_extra_turn_exile,
        test_pg079_deck606_high_rules_resolve_from_sqlite_cache,
        test_pg079_storm_herd_creates_life_total_flying_pegasus_tokens,
        test_pg079_rite_of_the_dragoncaller_creates_flying_dragon_on_instant_sorcery_cast,
        test_pg079_witch_enchanter_etb_destroys_opponent_artifact_or_enchantment,
        test_pg081_artists_talent_rummages_on_own_noncreature_spell_cast,
        test_pg081_pinnacle_monk_enters_and_returns_instant_or_sorcery_to_hand,
        test_pg150_insidious_roots_creature_recursion_creates_buffed_plant_and_unlocks_token_mana,
        test_pg150_insidious_roots_ignores_noncreature_flashback_from_graveyard,
        test_pg152_bartolome_normalizes_to_exact_scope,
        test_pg152_bartolome_sacrifices_treasure_and_grows_precombat,
        test_pg151_magda_tapped_dwarf_creates_treasure,
        test_pg151_magda_sacrifices_five_treasures_to_tutor_valid_target,
        test_pg081_redirect_lightning_redirects_single_target_stack_object,
        test_pg086_angels_grace_rule_resolves_from_sqlite_cache,
        test_pg087_deck606_remaining_semantic_rules_resolve_from_sqlite_cache,
        test_pg087_hexing_squelcher_static_counter_shield_uses_sqlite_rule,
        test_pg087_skyclave_apparition_exiles_only_nontoken_mv_lte_four_with_rule_provenance,
        test_pg089_removal_compensation_creature_tokens_are_created_for_target_controller,
        test_pg089_l6_removal_compensation_rules_resolve_from_sqlite_cache,
        test_pg091_token_maker_family_runtime_support,
        test_patrol_signaler_postcombat_activation_creates_token_and_untaps,
        test_patrol_signaler_skips_when_not_tapped_for_untap_activation,
        test_eldrazi_confluence_creates_three_scions_when_no_other_modes_are_live,
        test_eldrazi_confluence_uses_pump_then_blink_then_scion_when_context_exists,
        test_pg091_deck607_token_maker_rules_resolve_from_sqlite_cache,
        test_pg114_emerias_call_creates_angels_and_protects_non_angels_until_next_turn,
        test_pg114_emerias_call_rule_resolves_from_sqlite_cache,
        test_pg092_deck608_modal_interaction_rules_resolve_from_sqlite_cache,
        test_pg092_untimely_malfunction_removes_artifact_only_with_rule_provenance,
        test_pg092_return_the_favor_requires_stack_spell_target_with_rule_provenance,
        test_pg093_insurrection_uses_compact_steal_attack_runtime,
        test_pg093_insurrection_rule_resolves_from_sqlite_cache,
    ]
