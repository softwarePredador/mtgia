"""Stack, priority and casting-pipeline regression tests for battle_analyst_v9."""

import random
import sqlite3
import tempfile
from pathlib import Path


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

        assert battle.priority_round(
            active,
            [active, responder],
            stack,
            2,
            random.Random(6),
            phase="precombat_main",
        ) is True
        assert stack.items[-1].countered is True
        assert responder.available_mana() == 0
        assert responder.hand == []
        assert responder.graveyard[0]["name"] == "Real Counter"
        counter_event = next(data for event, data in events if event == "spell_countered")
        assert counter_event["phase"] == "precombat_main"
        assert counter_event["priority_window"] == "stack_response"

        battle.priority_round(active, [active, responder], stack, 2, random.Random(6), phase="precombat_main")
        assert stack.empty()
        assert active.graveyard[0]["name"] == "Approach of the Second Sun"

    def test_counterspell_respects_mana_value_target_restriction():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            responder = player("Responder")
            windborn = {
                "name": "Windborn Muse",
                "cmc": 4,
                "effect": "attack_tax",
                "type_line": "Creature - Spirit",
            }
            responder.hand = [
                {
                    "name": "Mental Misstep",
                    "cmc": 1,
                    "type_line": "Instant",
                }
            ]
            responder.mana_pool.add_generic(1)
            stack = battle.Stack()
            stack.push(windborn, active, {"effect": "attack_tax"})

            counter = responder.use_counterspell(
                turn=7,
                target_card=windborn,
                stack_item=stack.items[-1],
                stack_depth=len(stack.items),
                phase="precombat_main",
            )

            assert counter is None
            assert [card["name"] for card in responder.hand] == ["Mental Misstep"]
            assert not [data for event, data in events if event == "spell_countered"]

            one_drop = {
                "name": "Esper Sentinel",
                "cmc": 1,
                "type_line": "Artifact Creature - Human Soldier",
            }
            stack = battle.Stack()
            stack.push(one_drop, active, {"effect": "draw_engine"})

            counter = responder.use_counterspell(
                turn=7,
                target_card=one_drop,
                stack_item=stack.items[-1],
                stack_depth=len(stack.items),
                phase="precombat_main",
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert counter is not None
        assert counter["name"] == "Mental Misstep"
        assert responder.hand == []
        assert any(
            event == "spell_countered" and data.get("target") == "Esper Sentinel"
            for event, data in events
        )

    def test_cannot_lose_turn_response_not_spent_on_nonlethal_removal():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with sqlite3.connect(db_path) as conn:
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Angel's Grace",
                    {
                        "effect": "cannot_lose_turn",
                        "instant": True,
                        "life_floor_on_damage": 1,
                    },
                    source="curated",
                    confidence=1.0,
                    review_status="verified",
                )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                active = player("Active")
                responder = player("Lorehold")
                responder.is_human = True
                responder.life = 20
                responder.hand = [
                    {
                        "name": "Angel's Grace",
                        "cmc": 1,
                        "mana_cost": "{W}",
                        "type_line": "Instant",
                    }
                ]
                responder.battlefield = [
                    {
                        "name": "Lorehold",
                        "cmc": 4,
                        "is_commander": True,
                        "type_line": "Legendary Creature",
                        "effect": "creature",
                        "power": 3,
                        "toughness": 4,
                    }
                ]
                responder.mana_pool.add("white", 1)
                stack = battle.Stack()
                stack.push(
                    {"name": "Chain of Vapor", "cmc": 1, "type_line": "Instant"},
                    active,
                    {"effect": "remove_permanent", "instant": True, "target": "nonland"},
                )

                battle.priority_round(
                    active,
                    [active, responder],
                    stack,
                    3,
                    random.Random(602),
                    phase="precombat_main",
                )
            finally:
                battle.REPLAY_EVENT_HANDLER = previous_handler
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        assert [card["name"] for card in responder.hand] == ["Angel's Grace"]
        assert not [
            data
            for event, data in events
            if event == "spell_cast" and data.get("card") == "Angel's Grace"
        ]

    def test_cannot_lose_turn_response_cast_for_second_approach():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with sqlite3.connect(db_path) as conn:
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Angel's Grace",
                    {
                        "effect": "cannot_lose_turn",
                        "instant": True,
                        "life_floor_on_damage": 1,
                    },
                    source="curated",
                    confidence=1.0,
                    review_status="verified",
                )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.DECISION_TRACE_HANDLER = decisions.append
                active = player("Approach Player")
                active.approach_count = 1
                responder = player("Lorehold")
                responder.is_human = True
                responder.life = 5
                responder.hand = [
                    {
                        "name": "Angel's Grace",
                        "cmc": 1,
                        "mana_cost": "{W}",
                        "type_line": "Instant",
                    }
                ]
                responder.mana_pool.add("white", 1)
                stack = battle.Stack()
                stack.push(
                    {
                        "name": "Approach of the Second Sun",
                        "cmc": 7,
                        "type_line": "Sorcery",
                    },
                    active,
                    {"effect": "approach", "gain_life": 7},
                )

                acted = battle.priority_round(
                    active,
                    [active, responder],
                    stack,
                    8,
                    random.Random(603),
                    phase="precombat_main",
                )
            finally:
                battle.REPLAY_EVENT_HANDLER = previous_event_handler
                battle.DECISION_TRACE_HANDLER = previous_decision_handler
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        assert acted is True
        assert responder.hand == []
        assert responder.cannot_lose_this_turn is True
        assert any(
            event == "spell_cast" and data.get("card") == "Angel's Grace"
            for event, data in events
        )
        assert any(
            data.get("actual_outcome") == "cannot_lose_response_cast"
            and data.get("score_components", {}).get("immediate_loss_source") == "approach_second_cast"
            for data in decisions
        )

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

    def test_empty_stack_priority_skips_tutor_without_library_target():
        active = player("Active")
        tutor = {
            "name": "Vampiric Tutor",
            "cmc": 1,
            "tag": "tutor",
            "effect": "tutor",
            "type_line": "Instant",
        }
        active.hand = [tutor]
        active.library = []
        active.mana_pool.add("black", 1)
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            acted = battle.run_priority_loop(
                active,
                [active],
                battle.Stack(),
                16,
                "precombat_main",
                random.Random(109),
                max_empty_actions=1,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert acted is False
        assert active.hand == [tutor]
        assert active.graveyard == []
        assert not [data for event, data in events if event == "tutor_resolved"]

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

    def test_spell_resolved_includes_stack_and_zone_provenance():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            responder = player("Responder")
            active.mana_pool.add_generic(1)
            stack = battle.Stack()
            spell = {
                "name": "Audited Draw",
                "cmc": 1,
                "mana_cost": "{1}",
                "type_line": "Sorcery",
            }
            effect = {"effect": "draw_cards", "count": 1}
            ctx = battle.begin_cast_context(
                active,
                spell,
                "precombat_main",
                effect_data=effect,
                role="normal",
            )
            assert battle.commit_cast_payment(ctx) is True
            stack.push(spell, active, effect)

            battle.priority_round(
                active,
                [active, responder],
                stack,
                2,
                random.Random(112),
                phase="precombat_main",
            )

            resolved = next(data for event, data in events if event == "spell_resolved")
            assert resolved["phase"] == "precombat_main"
            assert resolved["priority_window"] == "stack_resolution"
            assert resolved["stack_depth"] == 1
            assert resolved["stack_object"] == "Audited Draw"
            assert resolved["source_zone"] == "hand"
            assert resolved["from_zone"] == "hand"
            assert resolved["to_zone"] == "graveyard"
            assert resolved["destination"] == "graveyard"
            assert resolved["zone_after"] == "graveyard"
            assert resolved["cast_pipeline"] == "601.2_minimal"
            assert resolved["resolved_from_stack"] is True
            assert resolved["result"] == "resolved"
            assert resolved["locked_cost"]["generic"] == 1
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_direct_spell_resolution_fills_minimum_resolution_context():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            active.library = [{"name": "Drawn", "cmc": 1, "type_line": "Sorcery"}]
            active.mana_pool.add_generic(1)
            spell = {
                "name": "Direct Audited Draw",
                "cmc": 1,
                "mana_cost": "{1}",
                "type_line": "Sorcery",
            }
            effect = {"effect": "draw_cards", "count": 1}
            ctx = battle.begin_cast_context(
                active,
                spell,
                "precombat_main",
                effect_data=effect,
                role="normal",
            )
            assert battle.commit_cast_payment(ctx) is True

            battle.apply_effect_immediate(
                active,
                [],
                spell,
                2,
                random.Random(113),
                effect_data_override=effect,
                phase="precombat_main",
            )

            resolved = next(data for event, data in events if event == "spell_resolved")
            assert resolved["phase"] == "precombat_main"
            assert resolved["priority_window"] == "direct_resolution"
            assert resolved["stack_depth"] == 0
            assert resolved["source_zone"] == "hand"
            assert resolved["from_zone"] == "hand"
            assert resolved["to_zone"] == "graveyard"
            assert resolved["cast_pipeline"] == "601.2_minimal"
            assert resolved["resolved_from_stack"] is False
            assert resolved["locked_cost"]["generic"] == 1
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

    def test_casting_context_emits_cost_paid_event():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            spell = {
                "name": "Audited Cost Spell",
                "cmc": 2,
                "mana_cost": "{1}{U}",
                "type_line": "Sorcery",
            }
            active.mana_pool.add("blue", 1)
            active.mana_pool.add_generic(1)

            ctx = battle.begin_cast_context(active, spell, "precombat_main")

            assert battle.commit_cast_payment(ctx) is True
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        paid = next(data for event, data in events if event == "cost_paid")
        assert paid["card"] == "Audited Cost Spell"
        assert paid["mana_before"] == 2
        assert paid["mana_after"] == 0
        assert paid["locked_cost"]["generic"] == 1
        assert paid["locked_cost"]["colored"] == {"blue": 1}

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

    def test_player_does_not_protect_against_own_wheel_payoff():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
        try:
            active = player("Active")
            opponent = player("Opponent")
            active.is_human = True
            active.approach_count = 1
            active.hand = [
                {
                    "name": "Teferi's Protection",
                    "cmc": 3,
                    "mana_cost": "{2}{W}",
                    "type_line": "Instant",
                }
            ]
            active.battlefield = [
                {
                    "name": "Smothering Tithe",
                    "cmc": 4,
                    "effect": "ramp_engine",
                    "type_line": "Enchantment",
                }
            ]
            active.mana_pool.add("white", 1)
            active.mana_pool.add_generic(2)
            active.library = [_card(f"Draw {index}", cmc=1, effect="draw_cards") for index in range(8)]
            opponent.library = [_card(f"Opponent Draw {index}", cmc=1, effect="draw_cards") for index in range(8)]
            stack = battle.Stack()
            wheel = {"name": "Wheel of Fortune", "cmc": 3, "type_line": "Sorcery"}
            stack.push(wheel, active, battle.get_card_effect(wheel))

            battle.priority_round(active, [active, opponent], stack, 12, random.Random(213), phase="precombat_main")
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert not [
            data for event, data in events
            if event == "spell_cast" and data.get("card") == "Teferi's Protection"
        ]
        assert active.phased_out == []
        wheel_events = [data for event, data in events if event == "wheel_resolved"]
        assert wheel_events
        assert wheel_events[0]["treasures_created"] == 7
        wheel_decisions = [data for data in decisions if data.get("decision_type") == "wheel"]
        assert wheel_decisions
        assert wheel_decisions[0]["score_components"]["wheel_payoffs"] == ["Smothering Tithe"]

    def test_end_step_interaction_does_not_cast_counter_without_stack_target():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            responder = player("Responder")
            responder.hand = [
                {
                    "name": "Empty Stack Counter",
                    "cmc": 1,
                    "tag": "counter",
                    "effect": "counter",
                    "type_line": "Instant",
                }
            ]
            responder.mana_pool.add_generic(1)

            battle.play_turn_v8(
                active,
                [responder],
                [active, responder],
                1,
                random.Random(212),
                battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert responder.hand[0]["name"] == "Empty Stack Counter"
        assert not any(
            event == "end_step_instant" and data.get("card") == "Empty Stack Counter"
            for event, data in events
        )

    def test_empty_stack_priority_holds_response_only_instants():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.is_human = True
            active.hand = [
                {"name": "Teferi's Protection", "cmc": 3, "type_line": "Instant"},
                {"name": "Deflecting Swat", "cmc": 3, "type_line": "Instant"},
                {"name": "Boros Charm", "cmc": 2, "type_line": "Instant"},
                {"name": "Flawless Maneuver", "cmc": 3, "type_line": "Instant"},
                {"name": "Silence", "cmc": 1, "type_line": "Instant"},
            ]
            active.mana_pool.add_generic(10)

            battle.run_priority_loop(
                active,
                [active, opponent],
                battle.Stack(),
                4,
                "precombat_main",
                random.Random(214),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert [card["name"] for card in active.hand] == [
            "Teferi's Protection",
            "Deflecting Swat",
            "Boros Charm",
            "Flawless Maneuver",
            "Silence",
        ]
        assert not [
            data for event, data in events
            if event == "spell_cast" and data.get("player") == "Lorehold"
        ]

    def test_low_life_main_phase_preserves_survival_response_mana():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.is_human = True
            active.life = 2
            active.hand = [
                {
                    "name": "Teferi's Protection",
                    "cmc": 3,
                    "mana_cost": "{2}{W}",
                    "type_line": "Instant",
                },
                {
                    "name": "Windborn Muse",
                    "cmc": 4,
                    "mana_cost": "{3}{W}",
                    "type_line": "Creature - Spirit",
                },
            ]
            active.mana_pool.add("white", 1)
            active.mana_pool.add_generic(4)

            acted = battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                8,
                "precombat_main",
                battle.Stack(),
                random.Random(215),
                max_actions=1,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert acted is False
        assert [card["name"] for card in active.hand] == [
            "Teferi's Protection",
            "Windborn Muse",
        ]
        assert not [
            data for event, data in events
            if event == "spell_cast" and data.get("card") == "Windborn Muse"
        ]

        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.is_human = True
            active.life = 2
            active.hand = [
                {
                    "name": "Teferi's Protection",
                    "cmc": 3,
                    "mana_cost": "{2}{W}",
                    "type_line": "Instant",
                },
                {
                    "name": "Windborn Muse",
                    "cmc": 4,
                    "mana_cost": "{3}{W}",
                    "type_line": "Creature - Spirit",
                },
            ]
            active.mana_pool.add("white", 2)
            active.mana_pool.add_generic(5)

            acted = battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                8,
                "precombat_main",
                battle.Stack(),
                random.Random(216),
                max_actions=1,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert acted is True
        assert [card["name"] for card in active.hand] == ["Teferi's Protection"]
        assert any(
            event == "spell_cast" and data.get("card") == "Windborn Muse"
            for event, data in events
        )

    def test_combat_response_handles_commander_damage_lethal():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
        try:
            attacker = player("Kraum Pilot")
            defender = player("Lorehold")
            defender.is_human = True
            defender.life = 6
            defender.hand = [
                {
                    "name": "Teferi's Protection",
                    "cmc": 3,
                    "mana_cost": "{2}{W}",
                    "type_line": "Instant",
                }
            ]
            defender.mana_pool.add("white", 1)
            defender.mana_pool.add_generic(2)
            commander = {
                "name": "Kraum, Ludevic's Opus",
                "cmc": 5,
                "is_commander": True,
                "owner": attacker.name,
                "power": 5,
                "toughness": 4,
                "type_line": "Legendary Creature - Zombie Horror",
            }
            attacker.battlefield = [commander]
            source_key = battle.commander_damage_key(
                defender.name,
                commander,
                attacker.name,
            )
            attacker.commander_damage_by_source[source_key] = 16

            acted = battle.combat_defensive_response_window(
                attacker,
                defender,
                [commander],
                [(commander, [])],
                [attacker, defender],
                11,
                random.Random(218),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert acted is True
        assert defender.hand == []
        assert defender.protection_from_everything is True
        assert any(
            event == "spell_cast" and data.get("card") == "Teferi's Protection"
            for event, data in events
        )
        combat_decision = next(
            data for data in decisions
            if data.get("actual_outcome") == "combat_survival_response_cast"
        )
        assert combat_decision["score_components"]["projected_combat_damage"] == 5
        assert combat_decision["score_components"]["commander_lethal"] is True

    def test_board_wipe_trace_uses_resolution_result_after_phase_out():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.protection_from_everything = True
            active.phased_out = [
                {
                    "name": "Phased Threat",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 3,
                    "toughness": 3,
                }
            ]
            active.battlefield = [
                {
                    "name": "Plains",
                    "effect": "land",
                    "type_line": "Basic Land - Plains",
                }
            ]
            opponent.battlefield = [
                {
                    "name": "Live Opponent Threat",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 6,
                    "toughness": 6,
                }
            ]

            battle.apply_effect_immediate(
                active,
                [opponent],
                {"name": "Blasphemous Act", "cmc": 9, "type_line": "Sorcery"},
                12,
                random.Random(219),
                effect_data_override={
                    "effect": "board_wipe",
                    "rule_source": "curated",
                    "rule_review_status": "verified",
                },
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        board_decision = next(
            data for data in decisions
            if data.get("decision_type") == "board_wipe"
        )
        score = board_decision["score_components"]
        assert "wipe_without_timing_justification" not in board_decision["risk_flags"]
        assert "wipe_without_clear_asymmetry" not in board_decision["risk_flags"]
        assert "pre_resolution_timing_justified" in score
        assert score["timing_justified"] is True
        assert score["self_protected_from_wipe"] is True
        assert score["own_creatures_destroyed"] == 0
        assert score["live_opponent_creatures_destroyed"] == 1
        assert score["actual_asymmetry"] == 1
        assert opponent.battlefield == []
        assert active.phased_out[0]["name"] == "Phased Threat"
        wipe_event = next(data for event, data in events if event == "board_wipe_resolved")
        assert wipe_event["live_opponent_creatures_destroyed"] == 1
        assert wipe_event["self_protected_from_wipe"] is True

    def test_mid_life_commander_cast_preserves_survival_response_mana():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.is_human = True
            active.life = 11
            active.command_zone = [
                {
                    "name": "Lorehold, the Historian",
                    "cmc": 5,
                    "mana_cost": "{3}{R}{W}",
                    "type_line": "Legendary Creature - Elder Dragon",
                }
            ]
            active.hand = [
                {
                    "name": "Teferi's Protection",
                    "cmc": 3,
                    "mana_cost": "{2}{W}",
                    "type_line": "Instant",
                }
            ]
            active.mana_pool.add_generic(5)
            active.mana_pool.add("red", 1)
            active.mana_pool.add("colorless", 1)
            active.mana_pool.add("wildcard", 1)

            acted = battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                6,
                "precombat_main",
                battle.Stack(),
                random.Random(217),
                max_actions=1,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert acted is False
        assert active.command_zone
        assert [card["name"] for card in active.hand] == ["Teferi's Protection"]
        assert not [
            data for event, data in events
            if event in {"commander_cast", "spell_cast"}
        ]

    def test_critical_life_prioritizes_attack_tax_over_commander():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            opponent = player("Opponent")
            active.is_human = True
            active.life = 1
            active.command_zone = [
                {
                    "name": "Lorehold, the Historian",
                    "cmc": 5,
                    "mana_cost": "{3}{R}{W}",
                    "type_line": "Legendary Creature - Elder Dragon",
                }
            ]
            active.hand = [
                {
                    "name": "Windborn Muse",
                    "cmc": 4,
                    "mana_cost": "{3}{W}",
                    "effect": "attack_tax",
                    "attack_tax_per_creature": 2,
                    "type_line": "Creature - Spirit",
                }
            ]
            active.mana_pool.add_generic(5)
            active.mana_pool.add("red", 1)
            active.mana_pool.add("colorless", 1)
            active.mana_pool.add("wildcard", 1)

            acted = battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                7,
                "precombat_main",
                battle.Stack(),
                random.Random(218),
                max_actions=1,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert acted is True
        assert active.command_zone
        assert active.hand == []
        assert any(
            event == "spell_cast" and data.get("card") == "Windborn Muse"
            for event, data in events
        )
        assert not [
            data for event, data in events
            if event == "commander_cast"
        ]

    def test_stack_resolution_recovers_missing_cast_ledger_event():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            opponent = player("Opponent")
            card = {
                "name": "Loose Stack Artifact",
                "cmc": 1,
                "type_line": "Artifact",
            }
            effect = battle.store_cast_context_fields(
                {"effect": "passive"},
                {
                    "phase": "precombat_main",
                    "cast_pipeline": "601.2_minimal",
                    "locked_cost": {
                        "generic": 1,
                        "colored": {},
                        "hybrid": [],
                        "monocolored_hybrid": [],
                        "phyrexian": [],
                        "phyrexian_hybrid": [],
                    },
                    "role": "normal",
                    "source_zone": "hand",
                },
            )
            stack = battle.Stack()
            stack.push(card, active, effect)

            battle.priority_round(
                active,
                [active, opponent],
                stack,
                4,
                random.Random(217),
                phase="precombat_main",
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        event_names = [event for event, _data in events]
        assert "spell_cast" in event_names
        assert "spell_resolved" in event_names
        assert event_names.index("spell_cast") < event_names.index("spell_resolved")
        recovered_cast = next(
            data for event, data in events
            if event == "spell_cast" and data.get("card") == "Loose Stack Artifact"
        )
        assert recovered_cast["cast_ledger_recovered"] is True
        assert recovered_cast["recovery_reason"] == "stack_item_missing_cast_ledger"

    def test_the_one_ring_enters_with_protection_without_etb_draw():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            active.library = [
                {"name": "Drawn Card", "cmc": 1, "type_line": "Instant"},
            ]
            ring = {
                "name": "The One Ring",
                "cmc": 4,
                "type_line": "Legendary Artifact",
            }

            battle.apply_effect_immediate(
                active,
                [],
                ring,
                6,
                random.Random(219),
                effect_data_override={"effect": "draw_engine", "burden": True},
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

        assert active.protection_from_everything is True
        assert active.life_cant_change is False
        assert [card["name"] for card in active.hand] == []
        permanent = next(card for card in active.battlefield if card["name"] == "The One Ring")
        assert permanent["effect"] == "draw_engine"
        assert permanent["burden"] is True
        assert permanent["burden_counters"] == 0
        assert permanent["activated_burden_draw"] is True
        assert any(
            event == "protection_from_everything_granted"
            and data.get("card") == "The One Ring"
            and data.get("life_cant_change") is False
            for event, data in events
        )

    def test_the_one_ring_burden_activation_draws_and_adds_counter():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
        try:
            active = player("Lorehold")
            active.library = [
                {"name": "First Draw", "cmc": 1, "type_line": "Instant"},
                {"name": "Second Draw", "cmc": 1, "type_line": "Instant"},
            ]
            active.battlefield = [
                {
                    "name": "The One Ring",
                    "cmc": 4,
                    "type_line": "Legendary Artifact",
                    "effect": "draw_engine",
                    "burden": True,
                    "burden_counters": 0,
                    "activated_burden_draw": True,
                    "activation_requires_tap": True,
                }
            ]

            activated = battle.activate_utility_artifacts(
                active,
                [],
                [active],
                7,
                random.Random(220),
                phase="postcombat_main",
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert activated == 1
        permanent = active.battlefield[0]
        assert permanent["burden_counters"] == 1
        assert permanent["tapped"] is True
        assert [card["name"] for card in active.hand] == ["First Draw"]
        assert any(
            event == "utility_artifact_activated"
            and data.get("activation_kind") == "burden_draw"
            and data.get("burden_counters") == 1
            and data.get("cards_drawn") == 1
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "utility_artifact_activation"
            and decision.get("chosen_option", {}).get("action") == "activate_burden_draw"
            for decision in decisions
        )

    def test_the_one_ring_burden_activation_skips_next_upkeep_self_lethal():
        events = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            active.life = 2
            active.library = [
                {"name": "Risky Draw", "cmc": 1, "type_line": "Instant"},
            ]
            active.battlefield = [
                {
                    "name": "The One Ring",
                    "cmc": 4,
                    "type_line": "Legendary Artifact",
                    "effect": "draw_engine",
                    "burden": True,
                    "burden_counters": 1,
                    "activated_burden_draw": True,
                    "activation_requires_tap": True,
                }
            ]

            activated = battle.activate_utility_artifacts(
                active,
                [],
                [active],
                10,
                random.Random(221),
                phase="postcombat_main",
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler

        assert activated == 0
        permanent = active.battlefield[0]
        assert permanent["burden_counters"] == 1
        assert not permanent.get("tapped")
        assert active.hand == []
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "The One Ring"
            and data.get("strategic_guardrail_reason")
            == "next_upkeep_burden_life_loss_risk_too_high"
            for event, data in events
        )

    def test_the_one_ring_burden_activation_skips_cycle_combat_pressure_risk():
        events = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Lorehold")
            active.life = 13
            active.library = [
                {"name": "Risky Draw", "cmc": 1, "type_line": "Instant"},
            ]
            active.battlefield = [
                {
                    "name": "The One Ring",
                    "cmc": 4,
                    "type_line": "Legendary Artifact",
                    "effect": "draw_engine",
                    "burden": True,
                    "burden_counters": 0,
                    "activated_burden_draw": True,
                    "activation_requires_tap": True,
                },
                {
                    "name": "Silent Arbiter",
                    "cmc": 4,
                    "type_line": "Artifact Creature",
                    "effect": "creature",
                    "power": 1,
                    "toughness": 5,
                },
            ]
            opponents = [
                player("Tayam"),
                player("Kinnan"),
                player("Dargo"),
            ]
            opponents[0].battlefield = [_card("Tayam Attacker", effect="creature", power=3)]
            opponents[1].battlefield = [_card("Kinnan Attacker", effect="creature", power=2)]
            opponents[2].battlefield = [_card("Dargo Attacker", effect="creature", power=7)]

            activated = battle.activate_utility_artifacts(
                active,
                opponents,
                [active, *opponents],
                9,
                random.Random(222),
                phase="postcombat_main",
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler

        assert activated == 0
        permanent = next(card for card in active.battlefield if card["name"] == "The One Ring")
        assert permanent["burden_counters"] == 0
        assert not permanent.get("tapped")
        assert active.hand == []
        skip = next(
            data
            for event, data in events
            if event == "activated_ability_skipped"
            and data.get("card") == "The One Ring"
        )
        assert skip["strategic_guardrail_reason"] == "burden_cycle_combat_pressure_risk_too_high"
        assert "projected_combat_pressure" in skip["strategic_risk_flags"]
        assert "future_burden_clock" in skip["strategic_risk_flags"]

    def test_kicked_orims_chant_prevents_lethal_attack_declaration():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
        try:
            attacker = player("Dargo")
            defender = player("Lorehold")
            defender.life = 10
            defender.mana_pool.add("white", 2)
            defender.hand = [
                {
                    "name": "Orim's Chant",
                    "cmc": 1,
                    "effect": "silence_spell",
                    "instant": True,
                    "type_line": "Instant",
                }
            ]
            attacker.battlefield = [
                {
                    "name": "Dargo, the Shipwrecker",
                    "cmc": 7,
                    "effect": "creature",
                    "type_line": "Legendary Creature",
                    "power": 12,
                    "toughness": 5,
                    "summoning_sick": False,
                    "tapped": False,
                }
            ]

            declared = battle.declare_attackers_step(
                attacker,
                [defender],
                [attacker, defender],
                8,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert declared is None
        assert defender.hand == []
        assert defender.graveyard[0]["name"] == "Orim's Chant"
        assert attacker.battlefield[0]["tapped"] is False
        assert attacker.creatures_cant_attack_this_turn is True
        assert any(
            event == "attack_prevented_by_orims_chant"
            and data.get("prevented_attacker") == "Dargo"
            and data.get("projected_combat_damage") == 12
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "response"
            and decision.get("chosen_option", {}).get("action") == "kick_prevent_attacks"
            for decision in decisions
        )

    def test_low_life_casts_the_one_ring_before_attack_limit_when_under_pressure():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
        try:
            active = player("Lorehold")
            active.life = 17
            active.mana_pool.add_generic(5)
            active.hand = [
                {
                    "name": "The One Ring",
                    "cmc": 4,
                    "type_line": "Legendary Artifact",
                    "effect": "draw_engine",
                    "burden": True,
                },
                {
                    "name": "Silent Arbiter",
                    "cmc": 4,
                    "type_line": "Artifact Creature - Construct",
                    "effect": "attack_limit",
                },
                {
                    "name": "Teferi's Protection",
                    "cmc": 3,
                    "type_line": "Instant",
                    "effect": "phase_out",
                },
            ]
            opponent = player("Opponent")
            opponent.battlefield = [
                {
                    "name": "Large Attacker",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 18,
                    "toughness": 18,
                }
            ]
            stack = battle.Stack()

            acted = battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                6,
                "precombat_main",
                stack,
                random.Random(221),
                max_actions=1,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert acted is True
        assert any(
            event == "spell_cast" and data.get("card") == "The One Ring"
            for event, data in events
        )
        assert not any(
            event == "spell_cast" and data.get("card") == "Silent Arbiter"
            for event, data in events
        )
        assert active.protection_from_everything is True
        cast_decision = next(
            decision for decision in decisions
            if decision.get("actual_outcome") == "cast_to_stack"
        )
        assert cast_decision["chosen_option"]["card"] == "The One Ring"
        assert cast_decision["score_components"]["threat_score"] >= 80

    return [
        test_counterspell_consumes_card_mana_and_counters_target,
        test_counterspell_respects_mana_value_target_restriction,
        test_cannot_lose_turn_response_not_spent_on_nonlethal_removal,
        test_cannot_lose_turn_response_cast_for_second_approach,
        test_empty_stack_priority_requires_main_phase,
        test_empty_stack_priority_casts_main_phase_creature,
        test_main_phase_priority_loop_casts_bounded_empty_stack_actions,
        test_empty_stack_priority_skips_tutor_without_library_target,
        test_empty_stack_priority_emits_apnap_pass_sequence,
        test_main_phase_pass_trace_explains_held_interaction,
        test_main_phase_pass_trace_explains_mana_constrained_hand,
        test_stack_resolution_emits_apnap_pass_sequence_before_resolve,
        test_spell_resolved_includes_stack_and_zone_provenance,
        test_direct_spell_resolution_fills_minimum_resolution_context,
        test_casting_context_locks_cost_before_payment,
        test_casting_context_emits_cost_paid_event,
        test_casting_context_locks_x_alternative_and_additional_costs,
        test_casting_context_replay_exposes_modes_targets_and_x_value,
        test_casting_context_rejects_illegal_timing_without_payment,
        test_cast_spells_emits_minimal_601_pipeline_fields,
        test_conformance_stack_resolves_lifo,
        test_player_does_not_counter_own_spell,
        test_player_does_not_protect_against_own_wheel_payoff,
        test_end_step_interaction_does_not_cast_counter_without_stack_target,
        test_empty_stack_priority_holds_response_only_instants,
        test_low_life_main_phase_preserves_survival_response_mana,
        test_combat_response_handles_commander_damage_lethal,
        test_board_wipe_trace_uses_resolution_result_after_phase_out,
        test_mid_life_commander_cast_preserves_survival_response_mana,
        test_critical_life_prioritizes_attack_tax_over_commander,
        test_stack_resolution_recovers_missing_cast_ledger_event,
        test_the_one_ring_enters_with_protection_without_etb_draw,
        test_the_one_ring_burden_activation_draws_and_adds_counter,
        test_kicked_orims_chant_prevents_lethal_attack_declaration,
        test_low_life_casts_the_one_ring_before_attack_limit_when_under_pressure,
    ]
