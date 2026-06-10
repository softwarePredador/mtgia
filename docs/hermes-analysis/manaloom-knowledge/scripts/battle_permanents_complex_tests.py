"""Planeswalker, battle, DFC, adventure, prototype, and split regressions."""

import random


def register_tests(battle, player):
    def test_planeswalker_loyalty_activation_damage_and_sba():
        active = player("Active")
        walker = {
            "name": "Test Walker",
            "type_line": "Legendary Planeswalker",
            "starting_loyalty": 3,
        }
        battle.handle_planeswalker_etb(walker, active)
        active.battlefield = [walker]

        assert walker["loyalty"] == 3
        assert battle.activate_loyalty_ability(
            active,
            walker,
            -2,
            "precombat_main",
            battle.Stack(),
        ) is True
        assert walker["loyalty"] == 1
        assert battle.activate_loyalty_ability(
            active,
            walker,
            1,
            "precombat_main",
            battle.Stack(),
        ) is False
        assert battle.damage_to_planeswalker({"name": "Shock"}, walker, 1) is True
        assert walker["loyalty"] == 0

        assert battle.check_sbas([active]) is True
        assert walker in active.graveyard
        assert walker not in active.battlefield

    def test_battle_defense_damage_and_sba():
        active = player("Active")
        protector = player("Protector")
        siege = {
            "name": "Test Siege",
            "type_line": "Battle - Siege",
            "starting_defense": 3,
        }
        battle.handle_siege_etb(siege, active, [protector])
        active.battlefield = [siege]

        assert siege["defense"] == 3
        assert siege["protector"] == "Protector"
        assert battle.battle_takes_damage(siege, 3) is True
        assert siege["defense"] == 0

        assert battle.check_sbas([active, protector]) is True
        assert siege in active.exile
        assert siege not in active.battlefield
        assert siege["battle_defeated"] is True

    def test_battle_defeated_casts_back_face():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            protector = player("Protector")
            siege = {
                "name": "Test Siege // Reward Creature",
                "type_line": "Battle - Siege",
                "starting_defense": 2,
                "back_face": {
                    "name": "Reward Creature",
                    "type_line": "Creature",
                    "power": 3,
                    "toughness": 3,
                },
            }
            battle.handle_siege_etb(siege, active, [protector])
            active.battlefield = [siege]

            assert battle.battle_takes_damage(siege, 2) is True
            assert battle.check_sbas([active, protector]) is True

            assert siege in active.exile
            assert siege["battle_defeated"] is True
            assert len(active.battlefield) == 1
            assert active.battlefield[0]["name"] == "Reward Creature"
            assert active.battlefield[0]["effect"] == "creature"
            assert active.battlefield[0]["cast_from_battle_back_face"] is True
            assert "battle_back_face_cast" in [event for event, _ in events]
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_dfc_characteristics_and_color_identity_use_all_faces():
        dfc = {
            "name": "Front Face // Back Face",
            "is_dfc": True,
            "front_face": {
                "name": "Front Face",
                "mana_cost": "{W}",
                "colors": ["white"],
                "type_line": "Creature",
            },
            "back_face": {
                "name": "Back Face",
                "mana_cost": "{B}",
                "colors": ["black"],
                "type_line": "Creature",
            },
        }

        assert battle.get_card_characteristics(dfc, "hand")["name"] == "Front Face"
        dfc["is_transformed"] = True
        assert battle.get_card_characteristics(dfc, "battlefield")["name"] == "Back Face"
        assert battle.compute_color_identity(dfc) == ["white", "black"]

    def test_adventure_prototype_and_split_characteristics_by_cast_mode():
        adventure = {
            "name": "Questing Example",
            "mana_cost": "{2}{G}",
            "colors": ["green"],
            "type_line": "Creature",
            "adventure": {
                "name": "Example Adventure",
                "mana_cost": "{U}",
                "colors": ["blue"],
                "type_line": "Instant - Adventure",
            },
        }
        prototype = {
            "name": "Prototype Example",
            "mana_cost": "{7}",
            "colors": [],
            "type_line": "Artifact Creature",
            "prototype": {
                "name": "Prototype Example",
                "mana_cost": "{1}{R}",
                "colors": ["red"],
                "type_line": "Artifact Creature",
                "power": 2,
                "toughness": 2,
            },
        }
        split = {
            "name": "Left // Right",
            "is_split": True,
            "chosen_half": "half_b",
            "type_line": "Instant // Sorcery",
            "half_a": {"name": "Left", "cmc": 2, "colors": ["white"]},
            "half_b": {"name": "Right", "cmc": 3, "colors": ["red"]},
        }

        assert battle.get_card_characteristics(adventure, "stack", cast_mode="adventure")["name"] == "Example Adventure"
        assert battle.get_card_characteristics(adventure, "battlefield")["name"] == "Questing Example"
        assert battle.compute_color_identity(adventure) == ["blue", "green"]
        assert battle.get_card_characteristics(prototype, "stack", cast_mode="prototype")["mana_cost"] == "{1}{R}"
        assert battle.compute_color_identity(prototype) == ["red"]
        assert battle.get_card_characteristics(split, "stack")["name"] == "Right"
        outside_stack = battle.get_card_characteristics(split, "graveyard")
        assert outside_stack["cmc"] == 5
        assert outside_stack["colors"] == ["white", "red"]

    def test_adventure_resolves_to_exile_then_casts_creature_from_exile():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player(
                "Active",
                deck=[
                    {"name": "Drawn 1", "cmc": 1, "type_line": "Creature"},
                    {"name": "Drawn 2", "cmc": 1, "type_line": "Creature"},
                ],
            )
            opponent = player("Opponent")
            adventure_card = {
                "name": "Questing Example",
                "mana_cost": "{2}",
                "cmc": 2,
                "colors": ["green"],
                "type_line": "Creature",
                "power": 2,
                "toughness": 2,
                "adventure": {
                    "name": "Example Adventure",
                    "mana_cost": "{1}",
                    "cmc": 1,
                    "colors": ["blue"],
                    "type_line": "Instant - Adventure",
                    "tag": "draw",
                },
            }
            active.hand = [adventure_card]
            active.mana_pool.add_generic(1)
            stack = battle.Stack()

            assert battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                turn=3,
                phase="precombat_main",
                stack=stack,
                rng=random.Random(600),
                max_actions=1,
            ) is True

            assert active.hand and [card["name"] for card in active.hand] == ["Drawn 1", "Drawn 2"]
            assert len(active.exile) == 1
            assert active.exile[0]["name"] == "Questing Example"
            assert active.exile[0]["_adventure_available"] is True
            assert active.graveyard == []
            assert [event for event, _ in events if event.startswith("adventure")] == [
                "adventure_cast",
                "adventure_exiled",
            ]

            active.mana_pool.add_generic(2)
            assert battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                turn=3,
                phase="postcombat_main",
                stack=stack,
                rng=random.Random(601),
                max_actions=1,
            ) is True

            assert active.exile == []
            assert len(active.battlefield) == 1
            assert active.battlefield[0]["name"] == "Questing Example"
            assert active.battlefield[0]["effect"] == "creature"
            assert "adventure_creature_cast_from_exile" in [event for event, _ in events]
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    return [
        test_planeswalker_loyalty_activation_damage_and_sba,
        test_battle_defense_damage_and_sba,
        test_battle_defeated_casts_back_face,
        test_dfc_characteristics_and_color_identity_use_all_faces,
        test_adventure_prototype_and_split_characteristics_by_cast_mode,
        test_adventure_resolves_to_exile_then_casts_creature_from_exile,
    ]
