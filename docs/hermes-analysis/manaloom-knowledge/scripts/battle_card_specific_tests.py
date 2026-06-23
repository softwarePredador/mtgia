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
        assert any(
            decision.get("decision_type") == "land_tax_upkeep_tutor"
            and decision.get("chosen_option", {}).get("found_cards") == ["Island", "Mountain", "Plains"]
            for decision in decisions
        )

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

    return [
        test_lorehold_miracle_requires_lorehold_on_battlefield,
        test_lorehold_miracle_casts_first_draw_only_with_lorehold,
        test_lorehold_miracle_does_not_use_second_draw_of_turn,
        test_lorehold_miracle_skips_bad_wheel_refill,
        test_lorehold_miracle_does_not_cast_counter_without_stack_target,
        test_lorehold_miracle_does_not_cast_redirect_without_stack_target,
        test_lorehold_upkeep_rummage_emits_pg035_rule_provenance,
        test_past_in_flames_grants_flashback_with_pg036_rule_provenance,
        test_path_to_exile_exiles_creature_with_pg037_rule_provenance,
        test_swords_to_plowshares_exiles_creature_and_gains_power_life_with_pg040_rule_provenance,
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
        test_austere_command_resolves_two_destroy_modes,
        test_blasphemous_act_deals_13_damage_to_each_creature,
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
        test_pg072_get_lost_removes_allowed_permanent_and_creates_map_tokens,
        test_pg073_esper_sentinel_draws_on_first_noncreature_spell_with_power_tax,
        test_pg073_wheel_of_misfortune_uses_secret_number_compact_runtime,
        test_smothering_tithe_draw_step_creates_treasure_with_rule_provenance,
        test_reckless_endeavor_damage_wipe_creates_treasures,
        test_reverse_the_sands_swaps_with_highest_life_opponent,
        test_birgi_adds_red_mana_when_controller_casts_spell,
        test_electroduplicate_creates_hasty_copy_and_sacrifices_at_end_step,
        test_heat_shimmer_copies_any_creature_and_exiles_token_at_end_step,
        test_twinflame_copies_own_creature_only_and_exiles_token_at_end_step,
        test_molten_duplication_copies_own_artifact_as_artifact_and_sacrifices_token,
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
    ]
