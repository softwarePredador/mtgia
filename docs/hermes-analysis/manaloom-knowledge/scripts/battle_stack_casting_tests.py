"""Stack, priority and casting-pipeline regression tests for battle_analyst_v9."""

import random


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
    def test_counterspell_consumes_card_mana_and_counters_target():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
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
        responder.refresh_mana_sources(turn=2)
        spell = {
            "name": "Approach of the Second Sun",
            "cmc": 7,
            "type_line": "Sorcery",
        }
        stack = battle.Stack()
        stack.push(spell, active, battle.get_card_effect(spell))

        assert battle.priority_round(active, [active, responder], stack, 2, random.Random(6)) is True
        assert stack.items[-1].countered is True
        assert responder.available_mana() == 0
        assert responder.hand == []
        assert responder.graveyard[0]["name"] == "Real Counter"
        assert any(event == "spell_countered" for event, _ in events)

        battle.priority_round(active, [active, responder], stack, 2, random.Random(6))
        assert stack.empty()
        assert active.graveyard[0]["name"] == "Approach of the Second Sun"

    def test_empty_stack_priority_requires_main_phase():
        active = player("Active")
        active.hand = [_card("Priority Bear", cmc=2, effect="creature", power=2)]
        active.mana_pool.add_generic(2)
        stack = battle.Stack()

        assert battle.priority_round(active, [active], stack, 2, random.Random(106)) is False
        assert len(active.hand) == 1
        assert active.battlefield == []

    def test_empty_stack_priority_casts_main_phase_creature():
        active = player("Active")
        active.hand = [_card("Priority Bear", cmc=2, effect="creature", power=2)]
        active.mana_pool.add_generic(2)
        stack = battle.Stack()

        assert battle.priority_round(
            active,
            [active],
            stack,
            2,
            random.Random(107),
            phase="precombat_main",
        ) is True
        assert active.hand == []
        assert stack.empty()
        assert active.battlefield[0]["name"] == "Priority Bear"
        assert active.battlefield[0]["summoning_sick"] is True

    def test_main_phase_priority_loop_casts_bounded_empty_stack_actions():
        active = player("Active")
        active.hand = [
            _card("Priority Bear A", cmc=2, effect="creature", power=2),
            _card("Priority Bear B", cmc=2, effect="creature", power=2),
        ]
        active.mana_pool.add_generic(4)
        stack = battle.Stack()

        assert battle.run_priority_loop(
            active,
            [active],
            stack,
            2,
            "precombat_main",
            random.Random(108),
            max_empty_actions=2,
        ) is True
        assert active.hand == []
        assert stack.empty()
        assert [card["name"] for card in active.battlefield] == [
            "Priority Bear A",
            "Priority Bear B",
        ]

    def test_empty_stack_priority_emits_apnap_pass_sequence():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            next_player = player("Next")
            last_player = player("Last")
            stack = battle.Stack()

            assert battle.priority_round(
                active,
                [active, next_player, last_player],
                stack,
                2,
                random.Random(110),
                phase="beginning_of_combat",
            ) is False

            passes = [data for event, data in events if event == "priority_pass"]
            assert [entry["player"] for entry in passes] == ["Active", "Next", "Last"]
            assert {entry["reason"] for entry in passes} == {"empty_stack"}
            assert all(entry["phase"] == "beginning_of_combat" for entry in passes)
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_main_phase_pass_trace_explains_held_interaction():
        decisions = []
        previous_handler = battle.DECISION_TRACE_HANDLER
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            active = player("Active")
            active.hand = [
                {
                    "name": "Counterspell",
                    "cmc": 2,
                    "mana_cost": "{U}{U}",
                    "type_line": "Instant",
                    "effect": "counter",
                }
            ]
            active.battlefield = [
                {"name": "Island", "type_line": "Land", "effect": "land"},
                {"name": "Island", "type_line": "Land", "effect": "land"},
            ]
            active.refresh_mana_sources(turn=2)
            stack = battle.Stack()

            assert battle.priority_round(
                active,
                [active],
                stack,
                2,
                random.Random(210),
                phase="precombat_main",
            ) is False
        finally:
            battle.DECISION_TRACE_HANDLER = previous_handler

        pass_traces = [trace for trace in decisions if trace["decision_type"] == "pass_no_action"]
        assert len(pass_traces) == 1
        trace = pass_traces[0]
        assert trace["reason"] == "hold_instant_speed_interaction"
        assert "holding_instant_speed_interaction" in trace["risk_flags"]
        assert trace["score_components"]["castable_now_count"] == 0
        assert trace["score_components"]["reactive_option_count"] == 1
        assert trace["available_options"][1]["card"] == "Counterspell"

    def test_main_phase_pass_trace_explains_mana_constrained_hand():
        decisions = []
        previous_handler = battle.DECISION_TRACE_HANDLER
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            active = player("Active")
            active.hand = [
                {
                    "name": "Austere Command",
                    "cmc": 6,
                    "mana_cost": "{4}{W}{W}",
                    "type_line": "Sorcery",
                    "effect": "board_wipe",
                }
            ]
            active.battlefield = [
                {"name": "Plains", "type_line": "Land", "effect": "land"},
                {"name": "Mountain", "type_line": "Land", "effect": "land"},
            ]
            active.refresh_mana_sources(turn=3)
            stack = battle.Stack()

            assert battle.priority_round(
                active,
                [active],
                stack,
                3,
                random.Random(211),
                phase="precombat_main",
            ) is False
        finally:
            battle.DECISION_TRACE_HANDLER = previous_handler

        pass_traces = [trace for trace in decisions if trace["decision_type"] == "pass_no_action"]
        assert len(pass_traces) == 1
        trace = pass_traces[0]
        assert trace["reason"] == "no_affordable_nonland_action"
        assert "mana_constrained_hand" in trace["risk_flags"]
        assert trace["score_components"]["affordable_card_count"] == 0
        assert trace["alternatives_considered"][0]["card"] == "Austere Command"

    def test_stack_resolution_emits_apnap_pass_sequence_before_resolve():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            responder = player("Responder")
            stack = battle.Stack()
            spell = {"name": "Unanswered Spell", "cmc": 1, "type_line": "Sorcery"}
            stack.push(spell, active, battle.get_card_effect(spell))

            battle.priority_round(
                active,
                [active, responder],
                stack,
                2,
                random.Random(111),
                phase="precombat_main",
            )

            passes = [data for event, data in events if event == "priority_pass"]
            assert [entry["player"] for entry in passes] == ["Active", "Responder"]
            assert {entry["reason"] for entry in passes} == {"stack_top_no_response"}
            assert {entry["stack_top"] for entry in passes} == {"Unanswered Spell"}
            assert stack.empty()
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_casting_context_locks_cost_before_payment():
        active = player("Active")
        spell = {
            "name": "Locked Cost Spell",
            "cmc": 2,
            "mana_cost": "{1}{U}",
            "type_line": "Sorcery",
        }
        active.mana_pool.add("blue", 1)
        active.mana_pool.add_generic(1)

        ctx = battle.begin_cast_context(active, spell, "precombat_main")
        spell["mana_cost"] = "{9}{U}"

        assert ctx.locked_cost["generic"] == 1
        assert dict(ctx.locked_cost["colored"]) == {"blue": 1}
        assert battle.commit_cast_payment(ctx) is True
        assert active.available_mana() == 0

    def test_casting_context_locks_x_alternative_and_additional_costs():
        active = player("Active")
        spell = {
            "name": "Advanced Cost Spell",
            "cmc": 7,
            "mana_cost": "{7}",
            "type_line": "Sorcery",
        }
        active.mana_pool.add("blue", 1)
        active.mana_pool.add("green", 1)
        active.mana_pool.add_generic(7)

        ctx = battle.begin_cast_context(
            active,
            spell,
            "precombat_main",
            alternative_cost="{X}{U}",
            x_value=4,
            additional_costs=["{2}", "{G}"],
            modes=["draw"],
            targets=["Opponent"],
            role="advanced",
        )
        spell["mana_cost"] = "{9}"

        assert ctx.locked_cost["generic"] == 6
        assert dict(ctx.locked_cost["colored"]) == {"blue": 1, "green": 1}
        assert ctx.alternative_cost == "{X}{U}"
        assert ctx.x_value == 4
        assert ctx.additional_costs == ["{2}", "{G}"]
        assert ctx.modes == ["draw"]
        assert ctx.targets == ["Opponent"]
        assert battle.commit_cast_payment(ctx) is True
        assert active.available_mana() == 1

    def test_casting_context_replay_exposes_modes_targets_and_x_value():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            spell = {
                "name": "Modal X Spell",
                "cmc": 1,
                "mana_cost": "{X}{R}",
                "type_line": "Instant",
            }
            active.mana_pool.add("red", 1)
            active.mana_pool.add_generic(3)

            ctx = battle.begin_cast_context(
                active,
                spell,
                "combat",
                x_value=3,
                modes=["damage"],
                targets=["Defender"],
                role="modal_x",
            )

            assert battle.commit_cast_payment(ctx) is True
            event = next(data for name, data in events if name == "cast_announced")
            assert event["x_value"] == 3
            assert event["modes"] == ["damage"]
            assert event["targets"] == ["Defender"]
            assert event["locked_cost"]["generic"] == 3
            assert event["locked_cost"]["colored"] == {"red": 1}
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_casting_context_rejects_illegal_timing_without_payment():
        active = player("Active")
        spell = {"name": "Timing Creature", "cmc": 2, "effect": "creature", "type_line": "Creature"}
        active.hand = [spell]
        active.mana_pool.add_generic(2)
        stack = battle.Stack()

        ctx = battle.begin_cast_context(active, spell, "end_step", effect_data=battle.get_card_effect(spell))

        assert battle.commit_cast_payment(ctx) is False
        assert active.available_mana() == 2
        assert active.hand == [spell]
        assert stack.empty()

    def test_cast_spells_emits_minimal_601_pipeline_fields():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            active.hand = [_card("Pipeline Bear", cmc=2, effect="creature", power=2)]
            active.mana_pool.add_generic(2)

            assert battle.cast_spells_v8(
                active,
                [],
                [active],
                2,
                "precombat_main",
                battle.Stack(),
                random.Random(109),
                max_actions=1,
            ) is True

            cast_event = next(data for event, data in events if event == "creature_cast")
            assert cast_event["cast_pipeline"] == "601.2_minimal"
            assert cast_event["locked_cost"]["generic"] == 2
            assert cast_event["role"] == "creature"
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_conformance_stack_resolves_lifo():
        controller = player("Controller")
        stack = battle.Stack()
        for name in ("First Spell", "Second Spell", "Third Spell"):
            stack.push({"name": name, "type_line": "Instant"}, controller, {"effect": "unknown"})

        resolved = []
        while not stack.empty():
            resolved.append(stack.resolve_top().card["name"])

        assert resolved == ["Third Spell", "Second Spell", "First Spell"]

    def test_player_does_not_counter_own_spell():
        active = player("Active")
        active.hand = [
            {
                "name": "Own Counter",
                "cmc": 2,
                "tag": "counter",
                "effect": "counter",
                "type_line": "Instant",
            }
        ]
        active.battlefield = ["land", "land"]
        active.refresh_mana_sources(turn=2)
        spell = {
            "name": "Approach of the Second Sun",
            "cmc": 7,
            "type_line": "Sorcery",
        }
        stack = battle.Stack()
        stack.push(spell, active, battle.get_card_effect(spell))

        battle.priority_round(active, [active], stack, 2, random.Random(10))

        assert stack.empty()
        assert active.approach_count == 1
        assert active.hand[0]["name"] == "Own Counter"
        assert active.available_mana() == 2

    return [
        test_counterspell_consumes_card_mana_and_counters_target,
        test_empty_stack_priority_requires_main_phase,
        test_empty_stack_priority_casts_main_phase_creature,
        test_main_phase_priority_loop_casts_bounded_empty_stack_actions,
        test_empty_stack_priority_emits_apnap_pass_sequence,
        test_main_phase_pass_trace_explains_held_interaction,
        test_main_phase_pass_trace_explains_mana_constrained_hand,
        test_stack_resolution_emits_apnap_pass_sequence_before_resolve,
        test_casting_context_locks_cost_before_payment,
        test_casting_context_locks_x_alternative_and_additional_costs,
        test_casting_context_replay_exposes_modes_targets_and_x_value,
        test_casting_context_rejects_illegal_timing_without_payment,
        test_cast_spells_emits_minimal_601_pipeline_fields,
        test_conformance_stack_resolves_lifo,
        test_player_does_not_counter_own_spell,
    ]
