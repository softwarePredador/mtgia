"""Focused 2026 rules conformance tests for battle_analyst_v9.

This module is loaded by test_battle_analyst_v10_3.py and receives the active
engine module from that runner. Keeping these tests separate prevents the main
conformance file from growing into an unreviewable monolith while preserving
the exact same script-run workflow.
"""

import random


CONFORMANCE_SCENARIOS_2026 = [
    {
        "id": "commander_vehicle_spacecraft_903_3",
        "rule": "CR 903.3",
        "purpose": "Legendary Vehicle or Spacecraft cards with power/toughness can be commanders.",
    },
    {
        "id": "hybrid_identity_strict_903",
        "rule": "CR 903.4",
        "purpose": "Hybrid mana contributes all colors to commander color identity.",
    },
    {
        "id": "warp_exile_recast_702_185",
        "rule": "CR 702.185",
        "purpose": "Warp casts from hand for an alternative cost, exiles at end step, then recasts from exile.",
    },
    {
        "id": "station_charge_unlock_702_184_721",
        "rule": "CR 702.184, 721",
        "purpose": "Station cards use another creature's power to add counters and unlock.",
    },
    {
        "id": "prepare_copy_from_exile_722",
        "rule": "CR 722",
        "purpose": "Prepare creates a linked castable copy in exile and removes it when unprepared.",
    },
    {
        "id": "omen_cast_characteristics_720",
        "rule": "CR 720",
        "purpose": "Omen cast mode exposes the omen characteristics while color identity includes both parts.",
    },
    {
        "id": "flashback_exile_replacement_702",
        "rule": "CR 702",
        "purpose": "Flashback casts from graveyard and exiles after resolution.",
    },
    {
        "id": "multi_defender_attack_commander",
        "rule": "CR 802, 903",
        "purpose": "Commander free-for-all combat can attack multiple defending players in one combat.",
    },
    {
        "id": "modern_ability_words_telemetry",
        "rule": "Set mechanics telemetry",
        "purpose": "Void/Repartee/Opus/Increment/Infusion/Converge are tracked as non-enforcing signals.",
    },
]


def register_tests(battle, player):
    def test_commander_vehicle_spacecraft_eligibility_and_hybrid_identity():
        assert battle.is_commander_eligible_card(
            {
                "name": "Legendary Vehicle",
                "type_line": "Legendary Artifact — Vehicle",
                "power": "5",
                "toughness": "5",
            }
        ) is True
        assert battle.is_commander_eligible_card(
            {
                "name": "Legendary Spacecraft",
                "type_line": "Legendary Artifact — Spacecraft",
                "power": "3",
                "toughness": "4",
            }
        ) is True
        assert battle.is_commander_eligible_card(
            {
                "name": "Uncrewed Legend",
                "type_line": "Legendary Artifact — Vehicle",
            }
        ) is False

        hybrid = {"name": "Hybrid Strict", "mana_cost": "{W/U}", "type_line": "Instant"}
        assert battle.compute_color_identity(hybrid) == ["white", "blue"]

    def test_warp_exiles_at_end_step_then_recasts_from_exile():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            warped = {
                "name": "Warp Creature",
                "cmc": 4,
                "mana_cost": "{4}",
                "warp_cost": "{1}",
                "type_line": "Creature",
                "power": 3,
                "toughness": 3,
            }
            active.hand = [warped]
            active.mana_pool.add_generic(1)

            assert battle.cast_warp_spell_from_hand(active, warped, 2, "precombat_main") is True
            assert active.hand == []
            assert active.battlefield[0]["name"] == "Warp Creature"
            assert active.battlefield[0]["_warped_this_turn"] is True

            assert battle.process_warp_end_step(active, 2) == ["Warp Creature"]
            assert active.battlefield == []
            assert active.exile[0]["_warp_recast_available"] is True

            active.mana_pool.add_generic(4)
            assert battle.cast_warp_card_from_exile(active, active.exile[0], 3, "precombat_main") is True
            assert active.exile == []
            assert active.battlefield[0]["name"] == "Warp Creature"
            assert [event for event, _ in events] == [
                "cast_announced",
                "warp_cast",
                "warp_exiled_end_step",
                "cast_announced",
                "warp_recast_from_exile",
            ]
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_flashback_cast_from_graveyard_exiles_after_resolution():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active", [{"name": "Draw One"}, {"name": "Draw Two"}])
            spell = {
                "name": "Flashback Draw",
                "cmc": 2,
                "mana_cost": "{1}{U}",
                "flashback_cost": "{1}",
                "tag": "draw",
                "type_line": "Sorcery",
            }
            active.graveyard = [spell]
            active.mana_pool.add_generic(1)
            stack = battle.Stack()

            assert battle.cast_flashback_spell_from_graveyard(
                active,
                spell,
                [],
                [active],
                4,
                "precombat_main",
                stack,
                random.Random(22),
            ) is True
            while not stack.empty():
                battle.priority_round(active, [active], stack, 4, random.Random(22))

            assert spell not in active.graveyard
            assert len(active.exile) == 1
            assert active.exile[0]["_flashback_cast"] is True
            assert "flashback_cast" in [event for event, _ in events]
            assert "flashback_exiled" in [event for event, _ in events]
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_station_activation_unlocks_spacecraft():
        active = player("Active")
        station = {
            "name": "Test Spacecraft",
            "type_line": "Legendary Artifact — Spacecraft",
            "power": "4",
            "toughness": "4",
            "station_threshold": 3,
            "charge_counters": 0,
        }
        tapper = {
            "name": "Crew Creature",
            "type_line": "Creature",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
            "tapped": False,
            "summoning_sick": False,
        }
        active.battlefield = [station, tapper]

        assert battle.activate_station_ability(
            active,
            station,
            tapper,
            "precombat_main",
            battle.Stack(),
        ) is True
        assert tapper["tapped"] is True
        assert station["charge_counters"] == 3
        assert station["station_online"] is True
        assert station["effect"] == "creature"

    def test_prepare_omen_paradigm_lander_and_ability_word_helpers():
        active = player("Active")
        creature = {"name": "Prepared Creature", "type_line": "Creature"}
        prepare_card = {
            "name": "Prepare Source",
            "type_line": "Instant",
            "prepare": {
                "name": "Prepared Copy",
                "mana_cost": "{R}",
                "type_line": "Instant",
            },
        }
        prepared = battle.prepare_spell_copy(active, prepare_card, creature, turn=5)
        assert prepared in active.exile
        assert prepared["_prepared_available"] is True
        assert battle.cleanup_prepared_copies(active, creature) == ["Prepared Copy"]
        assert active.exile == []

        omen = {
            "name": "Permanent With Omen",
            "mana_cost": "{2}{G}",
            "colors": ["green"],
            "type_line": "Creature",
            "omen": {
                "name": "Omen Half",
                "mana_cost": "{U}",
                "colors": ["blue"],
                "type_line": "Instant — Omen",
            },
        }
        assert battle.get_card_characteristics(omen, "stack", cast_mode="omen")["name"] == "Omen Half"
        assert battle.compute_color_identity(omen) == ["blue", "green"]

        paradigm_card = {"name": "Paradigm Spell", "type_line": "Sorcery"}
        paradigm = battle.resolve_paradigm_spell(active, paradigm_card, turn=6)
        assert paradigm in active.exile
        assert paradigm["_paradigm_available"] is True

        token = battle.create_lander_token(active)
        assert token["lander_token"] is True
        assert token["subtype"] == "Lander"

        signals = battle.modern_ability_word_signals(
            {
                "name": "Signal Card",
                "oracle_text": "Void — Whenever ... Repartee — Whenever ... Converge —",
            }
        )
        assert signals == ["void", "repartee", "converge"]

    def test_multi_defender_attack_commander_free_for_all():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            attacker = player("Attacker")
            defender_a = player("Defender A")
            defender_b = player("Defender B")
            defender_a.life = 40
            defender_b.life = 39
            attacker.battlefield = [
                {
                    "name": "Attacker One",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                    "summoning_sick": False,
                    "tapped": False,
                },
                {
                    "name": "Attacker Two",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                    "summoning_sick": False,
                    "tapped": False,
                },
            ]

            battle.combat_phase_v8(
                attacker,
                [defender_a, defender_b],
                [attacker, defender_a, defender_b],
                turn=3,
                rng=random.Random(42),
                stack=battle.Stack(),
            )

            multi = next(data for event, data in events if event == "multi_defender_attack")
            assert {group["target"] for group in multi["groups"]} == {"Defender A", "Defender B"}
            assert defender_a.life == 38
            assert defender_b.life == 37
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    return [
        test_commander_vehicle_spacecraft_eligibility_and_hybrid_identity,
        test_warp_exiles_at_end_step_then_recasts_from_exile,
        test_flashback_cast_from_graveyard_exiles_after_resolution,
        test_station_activation_unlocks_spacecraft,
        test_prepare_omen_paradigm_lander_and_ability_word_helpers,
        test_multi_defender_attack_commander_free_for_all,
    ]
