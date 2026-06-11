"""Minimal conformance registry and cross-domain conformance regressions."""


BASE_CONFORMANCE_SCENARIOS = [
    {
        "id": "stack_lifo_405",
        "rule": "CR 405, 608",
        "purpose": "Stack resolves last-in-first-out.",
    },
    {
        "id": "commander_damage_ledger_903_10a",
        "rule": "CR 903.10a",
        "purpose": "Commander damage ledger persists across commander zone changes.",
    },
    {
        "id": "commander_damage_per_origin_903_10a",
        "rule": "CR 903.10a",
        "purpose": "Multiple commanders track lethal 21 damage per commander origin.",
    },
    {
        "id": "empty_library_draw_104_3c",
        "rule": "CR 104.3c",
        "purpose": "A failed draw from an empty library loses even with cards in hand.",
    },
    {
        "id": "token_ceases_outside_battlefield_110_5f",
        "rule": "CR 110.5f",
        "purpose": "Tokens in non-battlefield zones cease to exist through the SBA loop.",
    },
    {
        "id": "plus_minus_counter_cancel_704_5q",
        "rule": "CR 704.5q",
        "purpose": "+1/+1 and -1/-1 counters cancel as a state-based action.",
    },
    {
        "id": "illegal_attachment_sba_704_5m_n",
        "rule": "CR 704.5m-n",
        "purpose": "Illegal Auras go to graveyard and illegal Equipment becomes unattached.",
    },
    {
        "id": "saga_final_chapter_sba_704_5s",
        "rule": "CR 704.5s",
        "purpose": "A Saga with final chapter reached is sacrificed after its chapter ability is done.",
    },
    {
        "id": "zone_change_lki_identity_400_7",
        "rule": "CR 400.7, 608.2g",
        "purpose": "Zone changes preserve LKI and advance logical object identity.",
    },
    {
        "id": "exile_visibility_406_3",
        "rule": "CR 406.3",
        "purpose": "Cards moved to exile preserve basic face-up or face-down visibility metadata.",
    },
    {
        "id": "blocked_stays_blocked_509_1h",
        "rule": "CR 509.1h",
        "purpose": "A creature remains blocked after all blockers leave combat.",
    },
    {
        "id": "end_of_combat_trigger_511_3",
        "rule": "CR 511.3, 603.3b",
        "purpose": "End of combat triggered abilities are put on the stack in APNAP order.",
    },
    {
        "id": "apnap_trigger_order_603_3b",
        "rule": "CR 603.3b",
        "purpose": "Triggers are placed on the stack in APNAP order.",
    },
    {
        "id": "prevention_before_damage_615",
        "rule": "CR 615",
        "purpose": "Prevention replacement applies before damage mutates life.",
    },
    {
        "id": "hybrid_phyrexian_payment_601_2h",
        "rule": "CR 601.2h, 107.4e, 107.4f, 106.6",
        "purpose": "Hybrid, monocolored hybrid, Phyrexian, hybrid Phyrexian, and restricted mana use legal payment alternatives.",
    },
]


def build_conformance_scenarios(extra_scenarios):
    return [*BASE_CONFORMANCE_SCENARIOS, *extra_scenarios]


def register_tests(battle, player, conformance_scenarios):
    def test_conformance_registry_has_executable_coverage():
        covered = {
            "stack_lifo_405",
            "commander_damage_ledger_903_10a",
            "commander_damage_per_origin_903_10a",
            "empty_library_draw_104_3c",
            "token_ceases_outside_battlefield_110_5f",
            "plus_minus_counter_cancel_704_5q",
            "illegal_attachment_sba_704_5m_n",
            "saga_final_chapter_sba_704_5s",
            "zone_change_lki_identity_400_7",
            "exile_visibility_406_3",
            "blocked_stays_blocked_509_1h",
            "end_of_combat_trigger_511_3",
            "apnap_trigger_order_603_3b",
            "prevention_before_damage_615",
            "hybrid_phyrexian_payment_601_2h",
            "commander_vehicle_spacecraft_903_3",
            "hybrid_identity_strict_903",
            "warp_exile_recast_702_185",
            "station_charge_unlock_702_184_721",
            "prepare_copy_from_exile_722",
            "omen_cast_characteristics_720",
            "flashback_exile_replacement_702",
            "multi_defender_attack_commander",
            "modern_ability_words_telemetry",
        }

        scenario_ids = {scenario["id"] for scenario in conformance_scenarios}

        assert scenario_ids == covered
        assert all(scenario.get("rule") for scenario in conformance_scenarios)
        assert all(scenario.get("purpose") for scenario in conformance_scenarios)

    def test_conformance_blocked_attacker_stays_blocked_after_blocker_leaves():
        attacker = player("Attacker")
        defender = player("Defender")
        attacking_creature = {
            "name": "Blocked Creature",
            "type_line": "Creature",
            "effect": "creature",
            "power": 7,
            "toughness": 7,
        }
        removed_blocker = {
            "name": "Removed Blocker",
            "type_line": "Creature",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
        }
        attacker.battlefield = [attacking_creature]
        defender.battlefield = []

        battle.combat_damage_steps(
            attacker,
            [defender],
            defender,
            [attacking_creature],
            [(attacking_creature, [removed_blocker])],
            turn=3,
        )

        assert defender.life == 40

    def test_conformance_apnap_trigger_order_is_lifo_after_stack_placement():
        battle.clear_pending_triggers()
        active = player("Active")
        nonactive = player("Nonactive")
        stack = battle.Stack()

        battle.resolve_or_enqueue_trigger(
            active,
            {"name": "Active Trigger"},
            "test_trigger",
            lambda: None,
            stack=stack,
            active_player=active,
            all_players=[active, nonactive],
        )
        battle.resolve_or_enqueue_trigger(
            nonactive,
            {"name": "Nonactive Trigger"},
            "test_trigger",
            lambda: None,
            stack=stack,
            active_player=active,
            all_players=[active, nonactive],
        )
        battle.flush_triggers_in_apnap(active, [active, nonactive], stack)

        assert [item.card["name"] for item in stack.items] == [
            "Active Trigger",
            "Nonactive Trigger",
        ]
        assert stack.resolve_top().card["name"] == "Nonactive Trigger"
        battle.clear_pending_triggers()

    def test_conformance_prevention_applies_before_damage_life_change():
        active = player("Active")
        active.life = 20
        battle.add_damage_prevention_shield(active, 3, source="Conformance Shield")

        assert battle.deal_damage(active, 5) is True

        assert active.life == 18
        assert active.damage_prevention_shields == []

    return [
        test_conformance_registry_has_executable_coverage,
        test_conformance_blocked_attacker_stays_blocked_after_blocker_leaves,
        test_conformance_apnap_trigger_order_is_lifo_after_stack_placement,
        test_conformance_prevention_applies_before_damage_life_change,
    ]
