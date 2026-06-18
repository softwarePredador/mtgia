"""Combat-focused conformance tests for battle_analyst_v9.

The main v10.3 runner stays as the single execution entrypoint. This module
only groups combat tests so the legacy runner can keep shrinking safely.
"""

import random


def register_tests(battle, player):
    def test_only_attacked_player_can_block():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        attacker = player("Attacker")
        non_target = player("Non Target")
        target = player("Target")
        non_target.life = 40
        target.life = 39
        attacker.battlefield = [
            {
                "name": "Attacker Creature",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "summoning_sick": False,
                "tapped": False,
            }
        ]
        non_target.battlefield = [
            {"name": "Wrong Blocker", "effect": "creature", "power": 3, "toughness": 3}
        ]
        target.battlefield = [
            {"name": "Right Blocker", "effect": "creature", "power": 3, "toughness": 3}
        ]

        battle.combat_phase_v8(
            attacker,
            [non_target, target],
            [attacker, non_target, target],
            turn=2,
            rng=random.Random(1),
            stack=battle.Stack(),
        )

        combat = next(data for event, data in events if event == "combat")
        assert combat["target"] == "Target"
        assert combat["blockers"] == 1
        assert non_target.battlefield[0]["name"] == "Wrong Blocker"
        assert attacker.battlefield == []

    def test_combat_prioritizes_visible_lethal():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        attacker = player("Attacker")
        lethal = player("Lethal")
        healthy = player("Healthy")
        lethal.life = 4
        healthy.life = 40
        attacker.battlefield = [
            {
                "name": "Five Power",
                "effect": "creature",
                "power": 5,
                "summoning_sick": False,
                "tapped": False,
            }
        ]

        battle.combat_phase_v8(
            attacker,
            [healthy, lethal],
            [attacker, healthy, lethal],
            turn=2,
            rng=random.Random(7),
            stack=battle.Stack(),
        )

        combat = next(data for event, data in events if event == "combat")
        assert combat["target"] == "Lethal"
        assert lethal.life == -1
        assert healthy.life == 40

    def test_combat_focuses_known_approach_caster():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        attacker = player("Attacker")
        approach = player("Approach Caster")
        other = player("Other")
        attacker.approach_revealed.append(approach.name)
        attacker.battlefield = [
            {
                "name": "Attacker Creature",
                "effect": "creature",
                "power": 3,
                "summoning_sick": False,
                "tapped": False,
            }
        ]

        battle.combat_phase_v8(
            attacker,
            [other, approach],
            [attacker, other, approach],
            turn=2,
            rng=random.Random(8),
            stack=battle.Stack(),
        )

        combat = next(data for event, data in events if event == "combat")
        assert combat["target"] == "Approach Caster"

    def test_first_strike_does_not_deal_regular_damage_twice():
        attacker = player("Attacker")
        defender = player("Defender")
        attacker.battlefield = [
            {
                "name": "First Striker",
                "effect": "creature",
                "power": 3,
                "first_strike": True,
                "summoning_sick": False,
                "tapped": False,
            }
        ]

        battle.combat_phase_v8(
            attacker,
            [defender],
            [attacker, defender],
            turn=2,
            rng=random.Random(9),
            stack=battle.Stack(),
        )

        assert defender.life == 37

    def test_must_attack_zero_power_creature_attacks_if_able():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        attacker = player("Attacker")
        defender = player("Defender")
        must_attack = {
            "name": "Compelled Recruit",
            "effect": "creature",
            "power": 0,
            "toughness": 2,
            "must_attack_each_combat_if_able": True,
            "summoning_sick": False,
            "tapped": False,
        }
        attacker.battlefield = [must_attack]

        battle.combat_phase_v8(
            attacker,
            [defender],
            [attacker, defender],
            turn=2,
            rng=random.Random(17),
            stack=battle.Stack(),
        )

        declare_attackers = next(
            data for event, data in events if data.get("step") == "declare_attackers"
        )
        assert declare_attackers["attackers"] == 1
        assert must_attack["tapped"] is True
        assert defender.life == 40

    def test_cant_attack_alone_creature_does_not_attack_by_itself():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        attacker = player("Attacker")
        defender = player("Defender")
        lone_attacker = {
            "name": "Bonded Raider",
            "effect": "creature",
            "power": 4,
            "toughness": 4,
            "cant_attack_alone": True,
            "summoning_sick": False,
            "tapped": False,
        }
        attacker.battlefield = [lone_attacker]

        battle.combat_phase_v8(
            attacker,
            [defender],
            [attacker, defender],
            turn=2,
            rng=random.Random(18),
            stack=battle.Stack(),
        )

        assert lone_attacker["tapped"] is False
        assert defender.life == 40
        assert not any(data.get("step") == "declare_attackers" for _, data in events)

    def test_cant_attack_alone_creature_attacks_with_another_attacker():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        attacker = player("Attacker")
        defender = player("Defender")
        bonded = {
            "name": "Bonded Raider",
            "effect": "creature",
            "power": 4,
            "toughness": 4,
            "cant_attack_alone": True,
            "summoning_sick": False,
            "tapped": False,
        }
        partner = {
            "name": "Partner Raider",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "summoning_sick": False,
            "tapped": False,
        }
        attacker.battlefield = [bonded, partner]

        battle.combat_phase_v8(
            attacker,
            [defender],
            [attacker, defender],
            turn=2,
            rng=random.Random(19),
            stack=battle.Stack(),
        )

        declare_attackers = next(
            data for event, data in events if data.get("step") == "declare_attackers"
        )
        assert declare_attackers["attackers"] == 2
        assert bonded["tapped"] is True
        assert partner["tapped"] is True
        assert defender.life == 34

    def test_multiple_blockers_can_gang_block():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        attacker = player("Attacker")
        defender = player("Defender")
        defender.life = 5
        attacker.battlefield = [
            {
                "name": "Large Attacker",
                "effect": "creature",
                "power": 6,
                "toughness": 6,
                "summoning_sick": False,
                "tapped": False,
            }
        ]
        defender.battlefield = [
            {"name": "Blocker A", "effect": "creature", "power": 3, "toughness": 3},
            {"name": "Blocker B", "effect": "creature", "power": 3, "toughness": 3},
        ]

        battle.combat_phase_v8(
            attacker, [defender], [attacker, defender], 2, random.Random(11), battle.Stack()
        )

        combat = next(data for event, data in events if event == "combat")
        assert combat["blockers"] == 2
        assert combat["multi_blocks"] == 1
        assert attacker.battlefield == []
        assert defender.battlefield == []
        assert defender.life == 5

    def test_trample_assigns_excess_damage_to_defender():
        attacker = player("Attacker")
        defender = player("Defender")
        defender.life = 5
        attacker.battlefield = [
            {
                "name": "Trampler",
                "effect": "creature",
                "power": 7,
                "toughness": 7,
                "trample": True,
                "summoning_sick": False,
                "tapped": False,
            }
        ]
        defender.battlefield = [
            {"name": "Small Blocker", "effect": "creature", "power": 2, "toughness": 2}
        ]

        battle.combat_phase_v8(
            attacker, [defender], [attacker, defender], 2, random.Random(12), battle.Stack()
        )

        assert defender.life == 0
        assert defender.battlefield == []
        assert attacker.battlefield[0]["name"] == "Trampler"

    def test_damage_assignment_order_prioritizes_low_lethal_blocker():
        attacker = player("Attacker")
        defender = player("Defender")
        trampler = {
            "name": "Ordering Trampler",
            "effect": "creature",
            "power": 4,
            "toughness": 5,
            "trample": True,
            "summoning_sick": False,
            "tapped": True,
        }
        large_blocker = {
            "name": "Large Wall",
            "effect": "creature",
            "power": 1,
            "toughness": 8,
        }
        small_blocker = {
            "name": "Small Blocker",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
        }
        attacker.battlefield = [trampler]
        defender.battlefield = [large_blocker, small_blocker]

        battle.combat_damage_steps(
            attacker,
            [defender],
            defender,
            [trampler],
            [(trampler, [large_blocker, small_blocker])],
            turn=2,
        )

        assert [creature["name"] for creature in defender.battlefield] == [
            "Large Wall"
        ]
        assert attacker.battlefield[0]["name"] == "Ordering Trampler"
        assert defender.life == 40

    def test_deathtouch_assigns_one_lethal_damage_per_blocker():
        attacker = player("Attacker")
        defender = player("Defender")
        defender.life = 2
        attacker.battlefield = [
            {
                "name": "Deathtouch Attacker",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "deathtouch": True,
                "summoning_sick": False,
                "tapped": False,
            }
        ]
        defender.battlefield = [
            {"name": "Blocker A", "effect": "creature", "power": 1, "toughness": 8},
            {"name": "Blocker B", "effect": "creature", "power": 1, "toughness": 8},
        ]

        battle.combat_phase_v8(
            attacker, [defender], [attacker, defender], 2, random.Random(13), battle.Stack()
        )

        assert defender.battlefield == []
        assert attacker.battlefield == []
        assert defender.life == 2

    def test_first_strike_blocker_kills_before_regular_damage():
        attacker = player("Attacker")
        defender = player("Defender")
        defender.life = 3
        attacker.battlefield = [
            {
                "name": "Regular Attacker",
                "effect": "creature",
                "power": 3,
                "toughness": 3,
                "summoning_sick": False,
                "tapped": False,
            }
        ]
        defender.battlefield = [
            {
                "name": "First Strike Blocker",
                "effect": "creature",
                "power": 3,
                "toughness": 3,
                "first_strike": True,
            }
        ]

        battle.combat_phase_v8(
            attacker, [defender], [attacker, defender], 2, random.Random(14), battle.Stack()
        )

        assert attacker.battlefield == []
        assert defender.battlefield[0]["name"] == "First Strike Blocker"
        assert defender.life == 3

    def test_indestructible_blocker_survives_lethal_combat_damage():
        attacker = player("Attacker")
        defender = player("Defender")
        defender.life = 5
        attacker.battlefield = [
            {
                "name": "Large Attacker",
                "effect": "creature",
                "power": 5,
                "toughness": 5,
                "summoning_sick": False,
                "tapped": False,
            }
        ]
        defender.battlefield = [
            {
                "name": "Indestructible Blocker",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "indestructible": True,
            }
        ]

        battle.combat_phase_v8(
            attacker, [defender], [attacker, defender], 2, random.Random(15), battle.Stack()
        )

        assert defender.battlefield[0]["name"] == "Indestructible Blocker"
        assert defender.life == 5

    def test_double_strike_trample_deals_excess_in_both_steps():
        attacker = player("Attacker")
        defender = player("Defender")
        defender.life = 4
        attacker.battlefield = [
            {
                "name": "Double Strike Trampler",
                "effect": "creature",
                "power": 4,
                "toughness": 4,
                "double_strike": True,
                "trample": True,
                "summoning_sick": False,
                "tapped": False,
            }
        ]
        defender.battlefield = [
            {
                "name": "Small Blocker",
                "effect": "creature",
                "power": 1,
                "toughness": 2,
            }
        ]

        battle.combat_phase_v8(
            attacker, [defender], [attacker, defender], 2, random.Random(16), battle.Stack()
        )

        assert defender.battlefield == []
        assert defender.life == -2

    return [
        test_only_attacked_player_can_block,
        test_combat_prioritizes_visible_lethal,
        test_combat_focuses_known_approach_caster,
        test_first_strike_does_not_deal_regular_damage_twice,
        test_must_attack_zero_power_creature_attacks_if_able,
        test_cant_attack_alone_creature_does_not_attack_by_itself,
        test_cant_attack_alone_creature_attacks_with_another_attacker,
        test_multiple_blockers_can_gang_block,
        test_trample_assigns_excess_damage_to_defender,
        test_damage_assignment_order_prioritizes_low_lethal_blocker,
        test_deathtouch_assigns_one_lethal_damage_per_blocker,
        test_first_strike_blocker_kills_before_regular_damage,
        test_indestructible_blocker_survives_lethal_combat_damage,
        test_double_strike_trample_deals_excess_in_both_steps,
    ]
