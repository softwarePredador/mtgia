"""Replay event and triggered-ability ordering regressions."""

import random


def register_tests(battle, player, card):
    def test_combat_emits_structured_event():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        attacker = player("Attacker")
        defender = player("Defender")
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
            [defender],
            [attacker, defender],
            turn=2,
            rng=random.Random(4),
            stack=battle.Stack(),
        )

        combat_events = [data for event, data in events if event == "combat"]
        assert len(combat_events) == 1
        assert combat_events[0]["attacker"] == "Attacker"
        assert combat_events[0]["target"] == "Defender"
        assert combat_events[0]["attackers"] == 1
        combat_steps = [
            data["step"]
            for event, data in events
            if event == "combat_step"
        ]
        assert combat_steps == [
            "beginning_of_combat",
            "declare_attackers",
            "declare_blockers",
            "combat_damage",
            "end_of_combat",
        ]

    def test_end_of_combat_triggers_use_stack_and_apnap_order():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active", [{"name": "Active Draw"}])
            nonactive = player("Nonactive", [{"name": "Nonactive Draw"}])
            active.battlefield = [
                {
                    "name": "Active End Engine",
                    "trigger": "end_of_combat",
                    "trigger_effect": "draw",
                    "trigger_draw_count": 1,
                }
            ]
            nonactive.battlefield = [
                {
                    "name": "Nonactive End Engine",
                    "trigger": "end_of_combat",
                    "trigger_effect": "draw",
                    "trigger_draw_count": 1,
                }
            ]
            stack = battle.Stack()

            battle.end_of_combat_step(
                active,
                [active, nonactive],
                turn=4,
                rng=random.Random(4),
                stack=stack,
            )

            assert stack.empty()
            assert [card["name"] for card in active.hand] == ["Active Draw"]
            assert [card["name"] for card in nonactive.hand] == ["Nonactive Draw"]
            put_on_stack = [
                data["player"]
                for event, data in events
                if event == "trigger_put_on_stack" and data.get("trigger") == "end_of_combat"
            ]
            assert put_on_stack == ["Active", "Nonactive"]
            resolved = [
                data["player"]
                for event, data in events
                if event == "trigger_resolved" and data.get("trigger") == "end_of_combat"
            ]
            assert resolved == ["Nonactive", "Active"]
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_apnap_trigger_order_puts_nonactive_trigger_on_top():
        if not hasattr(battle, "clear_pending_triggers"):
            return

        battle.clear_pending_triggers()
        events = []
        active = player("Active")
        opponent = player("Opponent")
        stack = battle.Stack()

        battle.resolve_or_enqueue_trigger(
            active,
            {"name": "Active Trigger Source"},
            "active_test_trigger",
            lambda: events.append("active"),
            stack=stack,
            active_player=active,
            all_players=[active, opponent],
        )
        battle.resolve_or_enqueue_trigger(
            opponent,
            {"name": "Opponent Trigger Source"},
            "opponent_test_trigger",
            lambda: events.append("opponent"),
            stack=stack,
            active_player=active,
            all_players=[active, opponent],
        )

        assert battle.flush_triggers_in_apnap(active, [active, opponent], stack) == 2
        assert [item.effect_data["trigger"] for item in stack.items] == [
            "active_test_trigger",
            "opponent_test_trigger",
        ]

        battle.priority_round(active, [active, opponent], stack, 1, random.Random(100))
        assert events == ["opponent"]
        battle.priority_round(active, [active, opponent], stack, 1, random.Random(101))
        assert events == ["opponent", "active"]

    def test_same_controller_triggers_keep_timestamp_stack_order():
        if not hasattr(battle, "clear_pending_triggers"):
            return

        battle.clear_pending_triggers()
        active = player("Active")
        stack = battle.Stack()

        battle.resolve_or_enqueue_trigger(
            active,
            {"name": "First"},
            "first_trigger",
            lambda: None,
            stack=stack,
            active_player=active,
            all_players=[active],
        )
        battle.resolve_or_enqueue_trigger(
            active,
            {"name": "Second"},
            "second_trigger",
            lambda: None,
            stack=stack,
            active_player=active,
            all_players=[active],
        )

        battle.flush_triggers_in_apnap(active, [active], stack)

        assert [item.card["name"] for item in stack.items] == ["First", "Second"]

    def test_spell_cast_trigger_resolves_from_stack_before_spell():
        if not hasattr(battle, "clear_pending_triggers"):
            return

        battle.clear_pending_triggers()
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active", [card("Drawn")])
            opponent = player("Opponent", [card("Opp Drawn")])
            active.battlefield = [
                {
                    "name": "Guttersnipe",
                    "effect": "creature",
                    "type_line": "Creature",
                    "trigger": "instant_sorcery_cast",
                    "trigger_effect": "damage_each_opponent",
                    "damage": 2,
                }
            ]
            spell = {
                "name": "Test Sorcery",
                "cmc": 2,
                "effect": "draw",
                "type_line": "Sorcery",
            }
            stack = battle.Stack()

            battle.trigger_spell_cast_engines(
                active,
                [active, opponent],
                spell,
                turn=1,
                phase="precombat_main",
                stack=stack,
                active_player=active,
            )
            stack.push(spell, active, battle.get_card_effect(spell))

            battle.priority_round(active, [active, opponent], stack, 1, random.Random(102))
            assert opponent.life == 38
            assert stack.items[-1].card["name"] == "Test Sorcery"
            battle.priority_round(active, [active, opponent], stack, 1, random.Random(103))
            assert stack.empty()

            event_names = [event for event, _ in events]
            assert event_names.index("trigger_resolved") < event_names.index("spell_resolved")
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    return [
        test_combat_emits_structured_event,
        test_end_of_combat_triggers_use_stack_and_apnap_order,
        test_apnap_trigger_order_puts_nonactive_trigger_on_top,
        test_same_controller_triggers_keep_timestamp_stack_order,
        test_spell_cast_trigger_resolves_from_stack_before_spell,
    ]
