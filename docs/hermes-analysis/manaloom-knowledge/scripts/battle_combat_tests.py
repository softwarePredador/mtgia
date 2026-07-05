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

    def test_evaluation_mode_forces_opponents_to_pressure_lorehold():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        previous_target = battle.os.environ.get(battle.EVALUATION_TARGET_ENV)
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.os.environ[battle.EVALUATION_TARGET_ENV] = "Lorehold"
        try:
            attacker = player("Opponent")
            lorehold = player("Lorehold")
            low_life_other = player("Other Opponent")
            lorehold.life = 40
            low_life_other.life = 1
            attacker.battlefield = [
                {
                    "name": "Three Power",
                    "effect": "creature",
                    "power": 3,
                    "toughness": 3,
                    "summoning_sick": False,
                    "tapped": False,
                }
            ]

            battle.combat_phase_v8(
                attacker,
                [low_life_other, lorehold],
                [attacker, low_life_other, lorehold],
                turn=2,
                rng=random.Random(18),
                stack=battle.Stack(),
            )

            combat = next(data for event, data in events if event == "combat")
            assert combat["target"] == "Lorehold"
            assert combat["target_reason"] == "evaluation_target_pressure"
            assert combat["evaluation_target_active"] is True
            assert lorehold.life == 37
            assert low_life_other.life == 1
            assert not any(event == "multi_defender_attack" for event, _ in events)
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler
            if previous_target is None:
                battle.os.environ.pop(battle.EVALUATION_TARGET_ENV, None)
            else:
                battle.os.environ[battle.EVALUATION_TARGET_ENV] = previous_target

    def test_evaluation_mode_tags_lorehold_lethal_pressure_as_lethal():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        previous_target = battle.os.environ.get(battle.EVALUATION_TARGET_ENV)
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.os.environ[battle.EVALUATION_TARGET_ENV] = "Lorehold"
        try:
            attacker = player("Opponent")
            lorehold = player("Lorehold")
            other = player("Other Opponent")
            lorehold.life = 7
            other.life = 1
            attacker.battlefield = [
                {
                    "name": "Seven Power",
                    "effect": "creature",
                    "power": 7,
                    "toughness": 7,
                    "summoning_sick": False,
                    "tapped": False,
                }
            ]

            battle.combat_phase_v8(
                attacker,
                [other, lorehold],
                [attacker, other, lorehold],
                turn=2,
                rng=random.Random(19),
                stack=battle.Stack(),
            )

            combat = next(data for event, data in events if event == "combat")
            assert combat["target"] == "Lorehold"
            assert combat["target_reason"] == "lethal"
            assert combat["evaluation_target_active"] is True
            assert lorehold.life == 0
            assert other.life == 1
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler
            if previous_target is None:
                battle.os.environ.pop(battle.EVALUATION_TARGET_ENV, None)
            else:
                battle.os.environ[battle.EVALUATION_TARGET_ENV] = previous_target

    def test_table_intent_uses_nemesis_memory_for_attack_targeting():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        previous_mode = battle.os.environ.get(battle.EVALUATION_MODE_ENV)
        previous_target = battle.os.environ.get(battle.EVALUATION_TARGET_ENV)
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.os.environ[battle.EVALUATION_MODE_ENV] = "table_intent"
        battle.os.environ[battle.EVALUATION_TARGET_ENV] = "Lorehold"
        try:
            attacker = player("Opponent")
            lorehold = player("Lorehold")
            other = player("Other Opponent")
            other.life = 20
            attacker.table_hostility[lorehold.name] = 70
            attacker.battlefield = [
                {
                    "name": "Three Power",
                    "effect": "creature",
                    "power": 3,
                    "toughness": 3,
                    "summoning_sick": False,
                    "tapped": False,
                }
            ]

            battle.combat_phase_v8(
                attacker,
                [other, lorehold],
                [attacker, other, lorehold],
                turn=4,
                rng=random.Random(20),
                stack=battle.Stack(),
            )

            combat = next(data for event, data in events if event == "combat")
            assert combat["target"] == "Lorehold"
            assert combat["target_reason"] == "table_intent_nemesis_hostility"
            assert combat["table_intent_enabled"] is True
            assert any(
                row["target"] == "Lorehold"
                and row["components"]["nemesis_hostility"] == 70
                for row in combat["table_intent_scores"]
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler
            if previous_mode is None:
                battle.os.environ.pop(battle.EVALUATION_MODE_ENV, None)
            else:
                battle.os.environ[battle.EVALUATION_MODE_ENV] = previous_mode
            if previous_target is None:
                battle.os.environ.pop(battle.EVALUATION_TARGET_ENV, None)
            else:
                battle.os.environ[battle.EVALUATION_TARGET_ENV] = previous_target

    def test_table_intent_records_combat_damage_as_future_hostility():
        previous_handler = battle.REPLAY_EVENT_HANDLER
        previous_mode = battle.os.environ.get(battle.EVALUATION_MODE_ENV)
        battle.REPLAY_EVENT_HANDLER = lambda event, data: None
        battle.os.environ[battle.EVALUATION_MODE_ENV] = "table_intent"
        try:
            attacker = player("Lorehold")
            defender = player("Opponent")
            other = player("Other Opponent")
            defender.life = 38
            attacker.battlefield = [
                {
                    "name": "Four Power",
                    "effect": "creature",
                    "power": 4,
                    "toughness": 4,
                    "summoning_sick": False,
                    "tapped": False,
                }
            ]

            battle.combat_phase_v8(
                attacker,
                [other, defender],
                [attacker, other, defender],
                turn=4,
                rng=random.Random(21),
                stack=battle.Stack(),
            )

            assert defender.life == 34
            assert defender.table_hostility["Lorehold"] >= 4
            assert defender.table_hostility_events[-1]["reason"] == "combat_damage_received"
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler
            if previous_mode is None:
                battle.os.environ.pop(battle.EVALUATION_MODE_ENV, None)
            else:
                battle.os.environ[battle.EVALUATION_MODE_ENV] = previous_mode

    def test_table_intent_lethal_keeps_attackers_on_chosen_target():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        previous_mode = battle.os.environ.get(battle.EVALUATION_MODE_ENV)
        previous_target = battle.os.environ.get(battle.EVALUATION_TARGET_ENV)
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.os.environ[battle.EVALUATION_MODE_ENV] = "table_intent"
        battle.os.environ.pop(battle.EVALUATION_TARGET_ENV, None)
        try:
            attacker = player("Attacker")
            lethal_target = player("Low Life")
            other_a = player("Other A")
            other_b = player("Other B")
            lethal_target.life = 7
            other_a.life = 40
            other_b.life = 40
            attacker.battlefield = [
                {
                    "name": "Six Power",
                    "effect": "creature",
                    "power": 6,
                    "toughness": 6,
                    "summoning_sick": False,
                    "tapped": False,
                },
                {
                    "name": "Three Power",
                    "effect": "creature",
                    "power": 3,
                    "toughness": 3,
                    "summoning_sick": False,
                    "tapped": False,
                },
            ]

            battle.combat_phase_v8(
                attacker,
                [other_a, lethal_target, other_b],
                [attacker, other_a, lethal_target, other_b],
                turn=5,
                rng=random.Random(21),
                stack=battle.Stack(),
            )

            combat = next(data for event, data in events if event == "combat")
            assert combat["target"] == "Low Life"
            assert combat["target_reason"] == "lethal"
            assert combat["target_group_power"] == 9
            assert len(combat["attack_groups"]) == 1
            assert lethal_target.life == -2
            assert not any(event == "multi_defender_attack" for event, _ in events)
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler
            if previous_mode is None:
                battle.os.environ.pop(battle.EVALUATION_MODE_ENV, None)
            else:
                battle.os.environ[battle.EVALUATION_MODE_ENV] = previous_mode
            if previous_target is None:
                battle.os.environ.pop(battle.EVALUATION_TARGET_ENV, None)
            else:
                battle.os.environ[battle.EVALUATION_TARGET_ENV] = previous_target

    def test_table_intent_target_reserves_blockers_when_under_pressure():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        previous_mode = battle.os.environ.get(battle.EVALUATION_MODE_ENV)
        previous_target = battle.os.environ.get(battle.EVALUATION_TARGET_ENV)
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.os.environ[battle.EVALUATION_MODE_ENV] = "table_intent"
        battle.os.environ[battle.EVALUATION_TARGET_ENV] = "Lorehold"
        try:
            lorehold = player("Lorehold")
            threatening_opponent = player("Threatening Opponent")
            other_opponent = player("Other Opponent")
            lorehold.life = 4
            attacker_a = {
                "name": "Lorehold Token A",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "summoning_sick": False,
                "tapped": False,
            }
            attacker_b = {
                "name": "Lorehold Token B",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "summoning_sick": False,
                "tapped": False,
            }
            lorehold.battlefield = [attacker_a, attacker_b]
            threatening_opponent.battlefield = [
                {
                    "name": "Six Power Threat",
                    "effect": "creature",
                    "power": 6,
                    "toughness": 6,
                    "summoning_sick": False,
                    "tapped": False,
                }
            ]

            battle.combat_phase_v8(
                lorehold,
                [threatening_opponent, other_opponent],
                [lorehold, threatening_opponent, other_opponent],
                turn=8,
                rng=random.Random(22),
                stack=battle.Stack(),
            )

            assert attacker_a["tapped"] is False
            assert attacker_b["tapped"] is False
            assert threatening_opponent.life == 40
            assert other_opponent.life == 40
            assert not any(data.get("step") == "declare_attackers" for _, data in events)
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler
            if previous_mode is None:
                battle.os.environ.pop(battle.EVALUATION_MODE_ENV, None)
            else:
                battle.os.environ[battle.EVALUATION_MODE_ENV] = previous_mode
            if previous_target is None:
                battle.os.environ.pop(battle.EVALUATION_TARGET_ENV, None)
            else:
                battle.os.environ[battle.EVALUATION_TARGET_ENV] = previous_target

    def test_table_intent_target_can_attack_with_vigilance_while_reserving_blockers():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        previous_mode = battle.os.environ.get(battle.EVALUATION_MODE_ENV)
        previous_target = battle.os.environ.get(battle.EVALUATION_TARGET_ENV)
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.os.environ[battle.EVALUATION_MODE_ENV] = "table_intent"
        battle.os.environ[battle.EVALUATION_TARGET_ENV] = "Lorehold"
        try:
            lorehold = player("Lorehold")
            threatening_opponent = player("Threatening Opponent")
            other_opponent = player("Other Opponent")
            lorehold.life = 4
            vigilant = {
                "name": "Vigilant Lorehold Token",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "vigilance": True,
                "summoning_sick": False,
                "tapped": False,
            }
            reserve = {
                "name": "Reserved Lorehold Token",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "summoning_sick": False,
                "tapped": False,
            }
            lorehold.battlefield = [vigilant, reserve]
            threatening_opponent.battlefield = [
                {
                    "name": "Six Power Threat",
                    "effect": "creature",
                    "power": 6,
                    "toughness": 6,
                    "summoning_sick": False,
                    "tapped": False,
                }
            ]

            battle.combat_phase_v8(
                lorehold,
                [threatening_opponent, other_opponent],
                [lorehold, threatening_opponent, other_opponent],
                turn=8,
                rng=random.Random(23),
                stack=battle.Stack(),
            )

            declare_attackers = next(
                data for event, data in events if data.get("step") == "declare_attackers"
            )
            assert declare_attackers["attackers"] == 1
            assert declare_attackers["reserved_attackers_for_self_preservation"] == 1
            assert declare_attackers["attackers_detail"][0]["name"] == "Vigilant Lorehold Token"
            assert vigilant["tapped"] is False
            assert reserve["tapped"] is False
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler
            if previous_mode is None:
                battle.os.environ.pop(battle.EVALUATION_MODE_ENV, None)
            else:
                battle.os.environ[battle.EVALUATION_MODE_ENV] = previous_mode
            if previous_target is None:
                battle.os.environ.pop(battle.EVALUATION_TARGET_ENV, None)
            else:
                battle.os.environ[battle.EVALUATION_TARGET_ENV] = previous_target

    def test_crawlspace_effect_limits_attackers_against_defender():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            attacker = player("Attacker")
            defender = player("Defender")
            attacker.battlefield = [
                {
                    "name": f"Attacker {index}",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                    "summoning_sick": False,
                    "tapped": False,
                }
                for index in range(4)
            ]
            defender.battlefield = [
                {
                    "name": "Crawlspace",
                    "effect": "attack_limit",
                    "max_attackers_against_you": 2,
                }
            ]

            battle.combat_phase_v8(
                attacker,
                [defender],
                [attacker, defender],
                turn=4,
                rng=random.Random(24),
                stack=battle.Stack(),
            )

            declare_attackers = next(
                data for event, data in events if data.get("step") == "declare_attackers"
            )
            combat = next(data for event, data in events if event == "combat")
            assert combat["attackers"] == 2
            assert declare_attackers["attack_restrictions"][0]["attack_limit"] == 2
            assert declare_attackers["attack_restrictions"][0]["attackers_restricted"] == 2
            assert sum(1 for card in attacker.battlefield if card.get("tapped")) == 2
            assert defender.life == 36
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_ghostly_prison_effect_taxes_attackers_against_defender():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            attacker = player("Attacker")
            defender = player("Defender")
            attacker.mana_pool.add_generic(2)
            attacker.battlefield = [
                {
                    "name": f"Attacker {index}",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                    "summoning_sick": False,
                    "tapped": False,
                }
                for index in range(3)
            ]
            defender.battlefield = [
                {
                    "name": "Ghostly Prison",
                    "effect": "attack_tax",
                    "attack_tax_per_creature": 2,
                }
            ]

            battle.combat_phase_v8(
                attacker,
                [defender],
                [attacker, defender],
                turn=4,
                rng=random.Random(25),
                stack=battle.Stack(),
            )

            declare_attackers = next(
                data for event, data in events if data.get("step") == "declare_attackers"
            )
            combat = next(data for event, data in events if event == "combat")
            assert combat["attackers"] == 1
            assert declare_attackers["attack_restrictions"][0]["attack_tax_per_creature"] == 2
            assert declare_attackers["attack_restrictions"][0]["tax_paid"] == 2
            assert declare_attackers["attack_restrictions"][0]["attack_restriction_sources"] == [
                "Ghostly Prison"
            ]
            assert declare_attackers["attack_restrictions"][0]["attack_tax_sources"] == [
                {
                    "card": "Ghostly Prison",
                    "attack_tax_per_creature": 2,
                    "attack_tax_per_enchantment": 0,
                    "enchantment_count": 0,
                    "total_attack_tax_per_creature": 2,
                }
            ]
            assert attacker.available_mana() == 0
            assert sum(1 for card in attacker.battlefield if card.get("tapped")) == 1
            assert defender.life == 38
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_sphere_of_safety_scales_attack_tax_with_enchantments():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            attacker = player("Attacker")
            defender = player("Defender")
            attacker.mana_pool.add_generic(10)
            attacker.battlefield = [
                {
                    "name": f"Attacker {index}",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                    "summoning_sick": False,
                    "tapped": False,
                }
                for index in range(3)
            ]
            defender.battlefield = [
                {
                    "name": "Sphere of Safety",
                    "type_line": "Enchantment",
                    "effect": "attack_tax",
                    "attack_tax_per_enchantment": 1,
                },
                {
                    "name": "Ghostly Prison",
                    "type_line": "Enchantment",
                    "effect": "attack_tax",
                    "attack_tax_per_creature": 2,
                },
                {
                    "name": "Land Tax",
                    "type_line": "Enchantment",
                    "effect": "passive",
                },
                {
                    "name": "Sol Ring",
                    "type_line": "Artifact",
                    "effect": "ramp_permanent",
                },
            ]

            battle.combat_phase_v8(
                attacker,
                [defender],
                [attacker, defender],
                turn=4,
                rng=random.Random(26),
                stack=battle.Stack(),
            )

            declare_attackers = next(
                data for event, data in events if data.get("step") == "declare_attackers"
            )
            combat = next(data for event, data in events if event == "combat")
            assert combat["attackers"] == 2
            assert declare_attackers["attack_restrictions"][0]["attack_tax_per_creature"] == 5
            assert declare_attackers["attack_restrictions"][0]["tax_paid"] == 10
            assert declare_attackers["attack_restrictions"][0]["attack_restriction_sources"] == [
                "Sphere of Safety",
                "Ghostly Prison",
            ]
            assert declare_attackers["attack_restrictions"][0]["attack_tax_sources"] == [
                {
                    "card": "Sphere of Safety",
                    "attack_tax_per_creature": 0,
                    "attack_tax_per_enchantment": 1,
                    "enchantment_count": 3,
                    "total_attack_tax_per_creature": 3,
                },
                {
                    "card": "Ghostly Prison",
                    "attack_tax_per_creature": 2,
                    "attack_tax_per_enchantment": 0,
                    "enchantment_count": 3,
                    "total_attack_tax_per_creature": 2,
                },
            ]
            assert attacker.available_mana() == 0
            assert sum(1 for card in attacker.battlefield if card.get("tapped")) == 2
            assert defender.life == 36
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_ensnaring_bridge_limits_attackers_by_controller_hand_size():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            attacker = player("Attacker")
            defender = player("Defender")
            defender.hand = [{"name": "Card A"}, {"name": "Card B"}]
            attacker.battlefield = [
                {
                    "name": "Big Attacker",
                    "effect": "creature",
                    "power": 5,
                    "toughness": 5,
                    "summoning_sick": False,
                    "tapped": False,
                },
                {
                    "name": "Small Attacker",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                    "summoning_sick": False,
                    "tapped": False,
                },
            ]
            defender.battlefield = [
                {
                    "name": "Ensnaring Bridge",
                    "effect": "attack_limit",
                    "max_attacker_power_by_controller_hand_size": True,
                }
            ]

            battle.combat_phase_v8(
                attacker,
                [defender],
                [attacker, defender],
                turn=4,
                rng=random.Random(27),
                stack=battle.Stack(),
            )

            declare_attackers = next(
                data for event, data in events if data.get("step") == "declare_attackers"
            )
            combat = next(data for event, data in events if event == "combat")
            assert combat["attackers"] == 1
            assert combat["target_group_power"] == 2
            assert declare_attackers["attack_restrictions"][0]["attack_max_power"] == 2
            assert declare_attackers["attack_restrictions"][0]["attackers_restricted"] == 1
            assert defender.life == 38
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_magus_of_the_moat_allows_only_flying_attackers():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            attacker = player("Attacker")
            defender = player("Defender")
            attacker.battlefield = [
                {
                    "name": "Ground Attacker",
                    "effect": "creature",
                    "power": 5,
                    "toughness": 5,
                    "keywords": [],
                    "summoning_sick": False,
                    "tapped": False,
                },
                {
                    "name": "Flying Attacker",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                    "keywords": ["flying"],
                    "summoning_sick": False,
                    "tapped": False,
                },
            ]
            defender.battlefield = [
                {
                    "name": "Magus of the Moat",
                    "effect": "attack_limit",
                    "attack_requires_keyword": "flying",
                }
            ]

            battle.combat_phase_v8(
                attacker,
                [defender],
                [attacker, defender],
                turn=4,
                rng=random.Random(28),
                stack=battle.Stack(),
            )

            declare_attackers = next(
                data for event, data in events if data.get("step") == "declare_attackers"
            )
            combat = next(data for event, data in events if event == "combat")
            assert combat["attackers"] == 1
            assert combat["target_group_power"] == 2
            assert declare_attackers["attack_restrictions"][0]["attack_requires_keywords"] == [
                "flying"
            ]
            assert declare_attackers["attack_restrictions"][0]["attackers_restricted"] == 1
            assert defender.life == 38
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_magus_of_the_moat_limits_controller_own_ground_attackers():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            attacker = player("Attacker")
            defender = player("Defender")
            magus = {
                "name": "Magus of the Moat",
                "type_line": "Creature — Human Wizard",
                "effect": "attack_limit",
                "attack_requires_keyword": "flying",
                "power": 0,
                "toughness": 3,
                "keywords": [],
                "summoning_sick": False,
                "tapped": False,
            }
            ground = {
                "name": "Ground Attacker",
                "effect": "creature",
                "power": 5,
                "toughness": 5,
                "keywords": [],
                "summoning_sick": False,
                "tapped": False,
            }
            flying = {
                "name": "Flying Attacker",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "keywords": ["flying"],
                "summoning_sick": False,
                "tapped": False,
            }
            attacker.battlefield = [magus, ground, flying]

            battle.combat_phase_v8(
                attacker,
                [defender],
                [attacker, defender],
                turn=4,
                rng=random.Random(29),
                stack=battle.Stack(),
            )

            declare_attackers = next(
                data for event, data in events if data.get("step") == "declare_attackers"
            )
            combat = next(data for event, data in events if event == "combat")
            assert combat["attackers"] == 1
            assert combat["target_group_power"] == 2
            assert declare_attackers["attack_restrictions"][0]["target"] == "all_defenders"
            assert declare_attackers["attack_restrictions"][0]["attack_requires_keywords"] == [
                "flying"
            ]
            assert declare_attackers["attack_restrictions"][0]["attackers_restricted"] == 1
            assert magus["tapped"] is False
            assert ground["tapped"] is False
            assert flying["tapped"] is True
            assert defender.life == 38
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_silent_arbiter_limits_total_attackers_globally():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            attacker = player("Attacker")
            defender = player("Defender")
            attacker.battlefield = [
                {
                    "name": f"Attacker {index}",
                    "effect": "creature",
                    "power": 2 + index,
                    "toughness": 2,
                    "summoning_sick": False,
                    "tapped": False,
                }
                for index in range(3)
            ]
            defender.battlefield = [
                {
                    "name": "Silent Arbiter",
                    "effect": "attack_limit",
                    "max_attackers": 1,
                }
            ]

            battle.combat_phase_v8(
                attacker,
                [defender],
                [attacker, defender],
                turn=4,
                rng=random.Random(30),
                stack=battle.Stack(),
            )

            declare_attackers = next(
                data for event, data in events if data.get("step") == "declare_attackers"
            )
            combat = next(data for event, data in events if event == "combat")
            assert combat["attackers"] == 1
            assert combat["target_group_power"] == 4
            assert declare_attackers["attack_restrictions"][0]["target"] == "all_defenders"
            assert declare_attackers["attack_restrictions"][0]["attack_limit"] == 1
            assert declare_attackers["attack_restrictions"][0]["attackers_restricted"] == 2
            assert sum(1 for card in attacker.battlefield if card.get("tapped")) == 1
            assert defender.life == 36
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

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

    def test_teferis_protection_is_held_for_lethal_combat_damage():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            attacker = player("Attacker")
            defender = player("Lorehold")
            defender.is_human = True
            defender.life = 5
            defender.hand = [
                {"name": "Teferi's Protection", "cmc": 3, "type_line": "Instant"}
            ]
            defender.mana_pool.add("white", 1)
            defender.mana_pool.add_generic(2)
            attacker.battlefield = [
                {
                    "name": "Lethal Attacker",
                    "effect": "creature",
                    "power": 6,
                    "toughness": 6,
                    "summoning_sick": False,
                    "tapped": False,
                }
            ]

            battle.combat_phase_v8(
                attacker,
                [defender],
                [attacker, defender],
                2,
                random.Random(151),
                battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert defender.life == 5
        assert defender.life_cant_change is True
        assert defender.hand == []
        assert any(
            event == "spell_cast"
            and data.get("card") == "Teferi's Protection"
            and data.get("response_to") == "combat_damage"
            for event, data in events
        )

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

    def test_defender_creature_cannot_attack_without_explicit_exception():
        attacker = player("Attacker")
        defender = player("Defender")
        defender.life = 4
        wall = {
            "name": "Defender Wall",
            "effect": "creature",
            "power": 4,
            "toughness": 4,
            "defender": True,
            "summoning_sick": False,
            "tapped": False,
        }
        attacker.battlefield = [wall]

        assert battle.can_attack_this_combat(wall) is False
        assert battle.declare_attackers_step(attacker, [defender], [attacker, defender], 2) is None

        exception_wall = dict(wall)
        exception_wall["can_attack_as_though_no_defender"] = True
        attacker.battlefield = [exception_wall]
        assert battle.can_attack_this_combat(exception_wall) is True

        battle.combat_phase_v8(
            attacker, [defender], [attacker, defender], 2, random.Random(17), battle.Stack()
        )

        assert defender.life == 0

    return [
        test_only_attacked_player_can_block,
        test_combat_prioritizes_visible_lethal,
        test_combat_focuses_known_approach_caster,
        test_evaluation_mode_forces_opponents_to_pressure_lorehold,
        test_evaluation_mode_tags_lorehold_lethal_pressure_as_lethal,
        test_table_intent_uses_nemesis_memory_for_attack_targeting,
        test_table_intent_records_combat_damage_as_future_hostility,
        test_table_intent_lethal_keeps_attackers_on_chosen_target,
        test_table_intent_target_reserves_blockers_when_under_pressure,
        test_table_intent_target_can_attack_with_vigilance_while_reserving_blockers,
        test_crawlspace_effect_limits_attackers_against_defender,
        test_ghostly_prison_effect_taxes_attackers_against_defender,
        test_sphere_of_safety_scales_attack_tax_with_enchantments,
        test_ensnaring_bridge_limits_attackers_by_controller_hand_size,
        test_magus_of_the_moat_allows_only_flying_attackers,
        test_magus_of_the_moat_limits_controller_own_ground_attackers,
        test_silent_arbiter_limits_total_attackers_globally,
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
        test_teferis_protection_is_held_for_lethal_combat_damage,
        test_double_strike_trample_deals_excess_in_both_steps,
        test_defender_creature_cannot_attack_without_explicit_exception,
    ]
