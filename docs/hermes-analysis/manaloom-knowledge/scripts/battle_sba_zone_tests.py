"""State-based actions, zone metadata, and permanent lifecycle regressions."""

import random


def register_tests(battle, player, card):
    def test_sba_only_reports_new_elimination():
        dead = player("Dead")
        alive = player("Alive", [card("Library card")])
        dead.life = 0

        assert battle.check_sbas([alive, dead]) is True
        assert dead.eliminated is True
        assert battle.check_sbas([alive, dead]) is False

    def test_eliminated_player_battlefield_leaves_game():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            dead = player("Dead")
            dead.life = 0
            dead.battlefield = [
                {
                    "name": "Dead Creature",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 2,
                    "toughness": 2,
                },
                {
                    "name": "Dead Land",
                    "effect": "land",
                    "type_line": "Land",
                },
            ]
            dead.phased_out = [
                {
                    "name": "Phased Dead Creature",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 2,
                    "toughness": 2,
                }
            ]

            assert battle.check_sbas([dead]) is True
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert dead.eliminated is True
        assert dead.battlefield == []
        assert dead.phased_out == []
        event = next(data for event, data in events if event == "player_eliminated")
        assert event["battlefield_removed_from_game"] == 2
        assert event["phased_out_removed_from_game"] == 1
        assert event["owned_objects_removed_from_game"] == 3
        assert event["owned_objects_removed_by_zone"]["battlefield"] == 2
        assert event["owned_objects_removed_by_zone"]["phased_out"] == 1
        assert event["owned_object_zone_change_events_emitted"] == 0
        assert event["player_departure_rule"] == "CR 800.4a"

    def test_elimination_ends_temporary_control_without_zone_change_or_dies():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            dead = player("Departing Controller")
            survivor = player("Original Controller")
            temporarily_stolen = {
                "name": "Temporarily Stolen Creature",
                "owner": survivor.name,
                "controller": dead.name,
                "effect": "creature",
                "type_line": "Creature",
                "power": 3,
                "toughness": 3,
                "keywords": ["haste"],
                "haste": True,
                "summoning_sick": False,
                "tapped": True,
                "_until_eot_originals": {
                    "controller": survivor.name,
                    "keywords": None,
                    "haste": None,
                    "summoning_sick": True,
                },
                "_until_eot_control_return_player_ref": survivor,
                "_until_eot_control_return_player_name": survivor.name,
                "_compact_attack_projected_turn": 7,
                "_compact_attack_projected_by": dead.name,
            }
            dead.battlefield = [temporarily_stolen]
            dead.life = 0

            assert battle.check_sbas([dead, survivor]) is True
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert dead.eliminated is True
        assert dead.battlefield == []
        assert temporarily_stolen in survivor.battlefield
        assert temporarily_stolen["controller"] == survivor.name
        assert temporarily_stolen["haste"] is True
        assert temporarily_stolen["keywords"] == ["haste"]
        assert temporarily_stolen["summoning_sick"] is False
        assert temporarily_stolen["tapped"] is True
        assert temporarily_stolen["_compact_attack_projected_turn"] == 7
        assert not any(
            event in {
                "permanent_moved_from_battlefield",
                "token_ceased_to_exist",
                "dies_draw_resolved",
                "dies_life_gain_resolved",
            }
            for event, _data in events
        )
        returned_event = next(
            data for event, data in events if event == "temporary_control_returned"
        )
        assert returned_event["reason"] == "controller_left_game"
        assert returned_event["zone_changed"] is False
        eliminated_event = next(
            data for event, data in events if event == "player_eliminated"
        )
        assert eliminated_event["temporary_control_returned_count"] == 1
        assert eliminated_event["remaining_controlled_objects_exiled_count"] == 0

        battle.clear_until_eot(survivor)
        assert "haste" not in temporarily_stolen
        assert "keywords" not in temporarily_stolen
        assert temporarily_stolen["summoning_sick"] is True
        assert "_compact_attack_projected_turn" not in temporarily_stolen

    def test_elimination_owned_objects_leave_game_without_zone_or_token_lifecycle():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            dead = player("Departing Owner")
            survivor = player("Surviving Controller")
            owned_creature = {
                "name": "Departing Owner Creature",
                "owner": dead.name,
                "controller": survivor.name,
                "effect": "creature",
                "type_line": "Creature",
                "power": 2,
                "toughness": 2,
            }
            owned_token = {
                "name": "Departing Owner Token",
                "owner": dead.name,
                "controller": survivor.name,
                "effect": "creature",
                "type_line": "Creature Token",
                "tag": "token",
                "power": 1,
                "toughness": 1,
            }
            phased_owned = {
                "name": "Departing Owner Phased Permanent",
                "owner": dead.name,
                "controller": dead.name,
                "effect": "creature",
                "type_line": "Creature",
                "power": 4,
                "toughness": 4,
            }
            survivor.battlefield = [owned_creature, owned_token]
            dead.phased_out = [phased_owned]
            dead.life = 0

            assert battle.check_sbas([dead, survivor]) is True
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert owned_creature not in survivor.battlefield
        assert owned_token not in survivor.battlefield
        assert phased_owned not in dead.phased_out
        assert owned_creature not in survivor.exile
        assert owned_token not in survivor.exile
        assert not any(
            event in {
                "permanent_moved_from_battlefield",
                "token_ceased_to_exist",
                "dies_draw_resolved",
                "dies_life_gain_resolved",
            }
            for event, _data in events
        )
        eliminated_event = next(
            data for event, data in events if event == "player_eliminated"
        )
        assert eliminated_event["battlefield_removed_from_game"] == 2
        assert eliminated_event["phased_out_removed_from_game"] == 1
        assert eliminated_event["owned_objects_removed_from_game"] == 3
        assert eliminated_event["owned_object_zone_change_events_emitted"] == 0

    def test_elimination_exiles_only_objects_still_controlled_and_never_marks_dies():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            dead = player("Departing Bribery Controller")
            survivor = player("Object Owner")
            bribery_creature = {
                "name": "Bribery Creature",
                "owner": survivor.name,
                "controller": dead.name,
                "effect": "creature",
                "type_line": "Creature",
                "power": 5,
                "toughness": 5,
                "dies_draw": 3,
            }
            survivor_created_token = {
                "name": "Survivor-Created Gift Token",
                "owner": survivor.name,
                "controller": dead.name,
                "effect": "creature",
                "type_line": "Creature Token",
                "tag": "token",
                "power": 1,
                "toughness": 1,
            }
            phased_bribery_creature = {
                "name": "Phased Bribery Creature",
                "owner": survivor.name,
                "controller": dead.name,
                "effect": "creature",
                "type_line": "Creature",
                "power": 2,
                "toughness": 2,
            }
            dead.battlefield = [bribery_creature, survivor_created_token]
            dead.phased_out = [phased_bribery_creature]
            dead.life = 0

            assert battle.check_sbas([dead, survivor]) is True
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert dead.battlefield == []
        assert dead.phased_out == []
        assert bribery_creature in survivor.exile
        assert phased_bribery_creature in survivor.exile
        assert survivor_created_token not in survivor.exile
        move_events = [
            data
            for event, data in events
            if event == "permanent_moved_from_battlefield"
        ]
        assert {data["card"] for data in move_events} == {
            "Bribery Creature",
            "Survivor-Created Gift Token",
        }
        assert all(data["to_zone"] == "exile" for data in move_events)
        assert all(data["reason"] == "controller_left_game" for data in move_events)
        assert not any(event.startswith("dies_") for event, _data in events)
        token_event = next(
            data for event, data in events if event == "token_ceased_to_exist"
        )
        assert token_event["token"] == "Survivor-Created Gift Token"
        assert token_event["from_zone"] == "battlefield"
        assert token_event["to_zone"] == "exile"
        eliminated_event = next(
            data for event, data in events if event == "player_eliminated"
        )
        assert eliminated_event["battlefield_removed_from_game"] == 0
        assert eliminated_event["phased_out_removed_from_game"] == 0
        assert eliminated_event["remaining_controlled_objects_exiled_count"] == 3
        assert eliminated_event["owned_object_zone_change_events_emitted"] == 0

    def test_cleanup_runs_with_previously_eliminated_player():
        active = player("Active", [card("Draw") for _ in range(5)])
        active.hand = [card(f"Expensive {index}") for index in range(10)]
        dead = player("Dead")
        dead.life = 0
        dead.eliminated = True

        battle.play_turn_v8(
            active,
            [dead],
            [active, dead],
            turn=3,
            rng=random.Random(1),
            stack=battle.Stack(),
        )

        assert len(active.hand) == 7

    def test_plus_minus_counters_cancel_as_sba():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        creature = {
            "name": "Countered Creature",
            "effect": "creature",
            "type_line": "Creature",
            "power": 2,
            "toughness": 2,
            "plus_one_counters": 2,
            "minus_one_counters": 1,
        }
        active.battlefield = [creature]

        battle.check_sbas_until_stable([active])

        assert creature in active.battlefield
        assert creature["plus_one_counters"] == 1
        assert creature["minus_one_counters"] == 0
        assert any(event == "counters_cancelled" for event, _ in events)

    def test_zero_or_negative_toughness_dies_even_if_indestructible():
        active = player("Active")
        creature = {
            "name": "Indestructible 0 Toughness",
            "effect": "creature",
            "type_line": "Creature",
            "power": 1,
            "toughness": 0,
            "indestructible": True,
        }
        active.battlefield = [creature]

        battle.check_sbas_until_stable([active])

        assert creature not in active.battlefield
        assert creature in active.graveyard

    def test_noncreature_zero_toughness_permanents_survive_sba():
        active = player("Active")
        land = {
            "name": "Flooded Strand",
            "effect": "land",
            "type_line": "Land",
            "power": 0,
            "toughness": 0,
        }
        artifact = {
            "name": "Sol Ring",
            "effect": "ramp_permanent",
            "type_line": "Artifact",
            "power": 0,
            "toughness": 0,
        }
        active.battlefield = [land, artifact]

        battle.check_sbas_until_stable([active])

        assert land in active.battlefield
        assert artifact in active.battlefield
        assert active.graveyard == []

    def test_illegal_aura_goes_to_graveyard_and_equipment_detaches():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        creature = {
            "name": "Bearer",
            "effect": "creature",
            "type_line": "Creature",
            "power": 2,
            "toughness": 2,
        }
        land = {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"}
        aura = {
            "name": "Creature Aura",
            "type_line": "Enchantment — Aura",
            "oracle_text": "Enchant creature",
            "attached_to": "Missing Creature",
        }
        equipment = {
            "name": "Illegal Sword",
            "type_line": "Artifact — Equipment",
            "equipped_to": "Plains",
        }
        active.battlefield = [creature, land, aura, equipment]

        battle.check_sbas_until_stable([active])

        assert aura not in active.battlefield
        assert aura in active.graveyard
        assert equipment in active.battlefield
        assert "equipped_to" not in equipment
        assert [data["action"] for event, data in events if event == "attachment_sba"] == [
            "moved_to_graveyard",
            "detached",
        ]

    def test_saga_final_chapter_sacrifices_after_pending_ability_resolves():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        saga = {
            "name": "Test Saga",
            "type_line": "Enchantment — Saga",
            "lore_counters": 3,
            "final_chapter": 3,
            "chapter_ability_pending": True,
        }
        active.battlefield = [saga]

        battle.check_sbas_until_stable([active])
        assert saga in active.battlefield

        saga["chapter_ability_pending"] = False
        battle.check_sbas_until_stable([active])

        assert saga not in active.battlefield
        assert saga in active.graveyard
        assert any(event == "saga_sacrificed_by_sba" for event, _ in events)

    def test_zone_change_records_lki_and_advances_zone_identity():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        creature = {
            "name": "Tracked Creature",
            "effect": "creature",
            "type_line": "Creature",
            "power": 4,
            "toughness": 5,
            "cmc": 3,
            "_zone_id": 7,
        }
        active.battlefield = [creature]

        try:
            destination = battle.move_creature_from_battlefield(active, creature, reason="destroyed")
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert destination == "graveyard"
        assert creature not in active.battlefield
        assert creature in active.graveyard
        assert creature["_zone_id"] == 8
        assert creature["_last_zone"] == "battlefield"
        assert battle.get_lki(creature)["power"] == 4
        move_event = next(data for event, data in events if event == "permanent_moved_from_battlefield")
        assert move_event["card"] == "Tracked Creature"
        assert move_event["from_zone"] == "battlefield"
        assert move_event["to_zone"] == "graveyard"
        assert move_event["destination"] == "graveyard"
        assert battle.move_creature_from_battlefield(active, "not a permanent") == "none"

    def test_noncreature_permanent_zone_change_uses_generic_helper():
        active = player("Active")
        artifact = {
            "name": "Tracked Artifact",
            "effect": "ramp_permanent",
            "type_line": "Artifact",
            "cmc": 2,
            "_zone_id": 3,
        }
        active.battlefield = [artifact]

        destination = battle.move_permanent_from_battlefield(active, artifact, reason="destroyed")

        assert destination == "graveyard"
        assert artifact not in active.battlefield
        assert artifact in active.graveyard
        assert artifact["_zone_id"] == 4
        assert artifact["_last_zone"] == "battlefield"
        assert battle.get_lki(artifact)["type_line"] == "Artifact"

    def test_exile_records_face_up_and_face_down_visibility():
        active = player("Active")
        public_card = {"name": "Public Exile"}
        hidden_card = {"name": "Hidden Exile"}

        battle.move_to_exile(active, public_card, reason="test_public", turn=3)
        battle.move_to_exile(
            active,
            hidden_card,
            face_down=True,
            public=False,
            reason="test_hidden",
            turn=3,
        )

        assert active.exile == [public_card, hidden_card]
        assert public_card["_exile_face_down"] is False
        assert public_card["_exile_public"] is True
        assert public_card["_exile_reason"] == "test_public"
        assert public_card["_exile_turn"] == 3
        assert hidden_card["_exile_face_down"] is True
        assert hidden_card["_exile_public"] is False
        assert hidden_card["_exile_reason"] == "test_hidden"
        assert hidden_card["_exile_turn"] == 3

    return [
        test_sba_only_reports_new_elimination,
        test_eliminated_player_battlefield_leaves_game,
        test_elimination_ends_temporary_control_without_zone_change_or_dies,
        test_elimination_owned_objects_leave_game_without_zone_or_token_lifecycle,
        test_elimination_exiles_only_objects_still_controlled_and_never_marks_dies,
        test_cleanup_runs_with_previously_eliminated_player,
        test_plus_minus_counters_cancel_as_sba,
        test_zero_or_negative_toughness_dies_even_if_indestructible,
        test_noncreature_zero_toughness_permanents_survive_sba,
        test_illegal_aura_goes_to_graveyard_and_equipment_detaches,
        test_saga_final_chapter_sacrifices_after_pending_ability_resolves,
        test_zone_change_records_lki_and_advances_zone_identity,
        test_noncreature_permanent_zone_change_uses_generic_helper,
        test_exile_records_face_up_and_face_down_visibility,
    ]
