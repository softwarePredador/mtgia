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

        destination = battle.move_creature_from_battlefield(active, creature, reason="destroyed")

        assert destination == "graveyard"
        assert creature not in active.battlefield
        assert creature in active.graveyard
        assert creature["_zone_id"] == 8
        assert creature["_last_zone"] == "battlefield"
        assert battle.get_lki(creature)["power"] == 4
        assert battle.move_creature_from_battlefield(active, "not a permanent") == "none"

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
        test_cleanup_runs_with_previously_eliminated_player,
        test_plus_minus_counters_cancel_as_sba,
        test_zero_or_negative_toughness_dies_even_if_indestructible,
        test_illegal_aura_goes_to_graveyard_and_equipment_detaches,
        test_saga_final_chapter_sacrifices_after_pending_ability_resolves,
        test_zone_change_records_lki_and_advances_zone_identity,
        test_exile_records_face_up_and_face_down_visibility,
    ]
