"""Commander-focused conformance tests for battle_analyst_v9."""

import random


def register_tests(battle, player):
    def test_conformance_commander_damage_ledger_persists_across_zone_change():
        attacker = player("Commander Player")
        defender = player("Defender")
        commander = {
            "name": "Ledger Commander",
            "type_line": "Legendary Creature",
            "effect": "creature",
            "power": 11,
            "toughness": 11,
            "is_commander": True,
            "owner": attacker.name,
        }
        attacker.battlefield = [commander]

        battle.combat_damage_steps(
            attacker,
            [defender],
            defender,
            [commander],
            [(commander, [])],
            turn=1,
        )
        assert attacker.commander_damage[defender.name] == 11
        assert (
            battle.move_creature_from_battlefield(attacker, commander, reason="destroyed")
            == "command_zone"
        )

        attacker.battlefield = [commander]
        battle.combat_damage_steps(
            attacker,
            [defender],
            defender,
            [commander],
            [(commander, [])],
            turn=2,
        )
        battle.check_sbas_until_stable([attacker, defender])

        assert attacker.commander_damage[defender.name] == 22
        assert defender.eliminated is True

    def test_commander_damage_is_tracked_per_commander_origin():
        attacker = player("Partner Player")
        defender = player("Defender")
        commander_a = {
            "name": "Partner A",
            "type_line": "Legendary Creature",
            "effect": "creature",
            "power": 11,
            "toughness": 11,
            "is_commander": True,
            "owner": attacker.name,
            "commander_origin_id": "partner-a-origin",
        }
        commander_b = {
            "name": "Partner B",
            "type_line": "Legendary Creature",
            "effect": "creature",
            "power": 10,
            "toughness": 10,
            "is_commander": True,
            "owner": attacker.name,
            "commander_origin_id": "partner-b-origin",
        }

        attacker.battlefield = [commander_a, commander_b]
        battle.combat_damage_steps(
            attacker,
            [defender],
            defender,
            [commander_a, commander_b],
            [(commander_a, []), (commander_b, [])],
            turn=1,
        )
        battle.check_sbas_until_stable([attacker, defender])

        assert attacker.commander_damage[defender.name] == 21
        assert attacker.commander_damage_by_source["Defender::partner-a-origin"] == 11
        assert attacker.commander_damage_by_source["Defender::partner-b-origin"] == 10
        assert defender.eliminated is False

        battle.combat_damage_steps(
            attacker,
            [defender],
            defender,
            [commander_a],
            [(commander_a, [])],
            turn=2,
        )
        battle.check_sbas_until_stable([attacker, defender])

        assert attacker.commander_damage_by_source["Defender::partner-a-origin"] == 22
        assert defender.eliminated is True

    def test_commander_destroyed_in_combat_returns_to_command_zone():
        attacker = player("Attacker")
        defender = player("Defender")
        commander = battle.enrich_card({
            "name": "Tiny Commander",
            "effect": "creature",
            "type_line": "Legendary Creature",
            "power": 1,
            "toughness": 1,
            "summoning_sick": False,
            "tapped": False,
            "is_commander": True,
        })
        blocker = battle.enrich_card({
            "name": "Big Blocker",
            "effect": "creature",
            "type_line": "Creature",
            "power": 3,
            "toughness": 3,
            "summoning_sick": False,
            "tapped": False,
        })
        attacker.battlefield = [commander]
        defender.battlefield = [blocker]
        defender.life = 1

        battle.combat_phase_v8(
            attacker,
            [defender],
            [attacker, defender],
            turn=5,
            rng=random.Random(69),
            stack=battle.Stack(),
        )

        assert commander not in attacker.battlefield
        assert commander in attacker.command_zone
        assert commander not in attacker.graveyard

    def test_unaffordable_commander_is_held_without_illegal_cast_event():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        pilot = player("Pilot")
        commander = battle.enrich_card({
            "name": "Expensive Commander",
            "cmc": 5,
            "mana_cost": "{5}",
            "effect": "creature",
            "type_line": "Legendary Creature",
            "power": 5,
            "toughness": 5,
            "is_commander": True,
            "owner": pilot.name,
        })
        pilot.commander = commander
        pilot.command_zone = [commander]

        try:
            result = battle.cast_spells_v8(
                pilot,
                [],
                [pilot],
                turn=1,
                phase="precombat_main",
                stack=battle.Stack(),
                rng=random.Random(70),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert result is False
        assert commander in pilot.command_zone
        assert not [data for event, data in events if event == "cast_illegal"]

    def test_affordable_commander_cast_uses_command_zone_source():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        pilot = player("Pilot")
        commander = battle.enrich_card({
            "name": "Cheap Commander",
            "cmc": 1,
            "mana_cost": "{1}",
            "effect": "creature",
            "type_line": "Legendary Creature",
            "power": 1,
            "toughness": 1,
            "is_commander": True,
            "owner": pilot.name,
        })
        pilot.commander = commander
        pilot.command_zone = [commander]
        pilot.mana_pool.add_generic(1)

        try:
            result = battle.cast_spells_v8(
                pilot,
                [],
                [pilot],
                turn=1,
                phase="precombat_main",
                stack=battle.Stack(),
                rng=random.Random(71),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert result is True
        assert commander not in pilot.command_zone
        assert any(card.get("name") == "Cheap Commander" for card in pilot.battlefield)
        commander_events = [data for event, data in events if event == "commander_cast"]
        assert len(commander_events) == 1
        assert commander_events[0]["source_zone"] == "command_zone"
        assert not [data for event, data in events if event == "cast_illegal"]

    def test_dargo_commander_cast_uses_variable_self_reduction_and_sacrifices_artifacts():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        previous_get_card_effect = battle.get_card_effect
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        pilot = player("Pilot")
        dargo = battle.enrich_card({
            "name": "Dargo, the Shipwrecker",
            "cmc": 7,
            "mana_cost": "{6}{R}",
            "effect": "static_cost_reduction",
            "battle_model_scope": "static_variable_self_spell_cost_reduction_variant_v1",
            "cost_reduction_applies_to": "this_spell",
            "cost_reduction_amount_source": "sacrificed_artifact_or_creature_count_this_turn",
            "cost_reduction_counts_additional_sacrifices_paid_while_casting": True,
            "type_line": "Legendary Creature - Giant Pirate",
            "power": 7,
            "toughness": 5,
            "is_commander": True,
            "owner": pilot.name,
        })
        pilot.commander = dargo
        pilot.command_zone = [dargo]
        pilot.battlefield = [
            {
                "name": "Spent Relic",
                "type_line": "Artifact",
                "cmc": 0,
                "tapped": True,
            },
            {
                "name": "Treasure Token",
                "type_line": "Artifact Token - Treasure",
                "cmc": 0,
                "tag": "token",
            },
        ]
        pilot.mana_pool.add("red", 1)
        pilot.mana_pool.add_generic(2)

        try:
            def patched_get_card_effect(card):
                if isinstance(card, dict) and card.get("name") == "Dargo, the Shipwrecker":
                    return {
                        "effect": "static_cost_reduction",
                        "battle_model_scope": "static_variable_self_spell_cost_reduction_variant_v1",
                        "cost_reduction_applies_to": "this_spell",
                        "cost_reduction_amount_source": "sacrificed_artifact_or_creature_count_this_turn",
                        "cost_reduction_counts_additional_sacrifices_paid_while_casting": True,
                        "_rule_source": "curated",
                        "_rule_review_status": "verified",
                    }
                return previous_get_card_effect(card)

            battle.get_card_effect = patched_get_card_effect
            result = battle.cast_spells_v8(
                pilot,
                [],
                [pilot],
                turn=1,
                phase="precombat_main",
                stack=battle.Stack(),
                rng=random.Random(72),
            )
        finally:
            battle.get_card_effect = previous_get_card_effect
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert result is True
        assert dargo not in pilot.command_zone
        assert any(card.get("name") == "Dargo, the Shipwrecker" for card in pilot.battlefield)
        assert {card.get("name") for card in pilot.graveyard} == {"Spent Relic"}
        commander_events = [data for event, data in events if event == "commander_cast"]
        assert len(commander_events) == 1
        assert commander_events[0]["source_zone"] == "command_zone"
        additional_cost_events = [data for event, data in events if event == "additional_cost_paid"]
        assert any(
            data.get("cost") == "sacrifice_artifact_or_creature_any_number"
            and data.get("sacrificed_count") == 2
            for data in additional_cost_events
        )

    return [
        test_conformance_commander_damage_ledger_persists_across_zone_change,
        test_commander_damage_is_tracked_per_commander_origin,
        test_commander_destroyed_in_combat_returns_to_command_zone,
        test_unaffordable_commander_is_held_without_illegal_cast_event,
        test_affordable_commander_cast_uses_command_zone_source,
        test_dargo_commander_cast_uses_variable_self_reduction_and_sacrifices_artifacts,
    ]
