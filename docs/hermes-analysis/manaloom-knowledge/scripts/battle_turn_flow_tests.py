"""Turn flow, draw, library loss, and extra-turn regressions."""

import random


def register_tests(battle, player, card):
    def test_draw_step_runs_once_with_multiple_permanents():
        active = player("Active", [card("Draw") for _ in range(5)])
        active.battlefield = [
            {"name": "Permanent A", "effect": "unknown"},
            {"name": "Permanent B", "effect": "unknown"},
        ]
        opponent = player("Opponent", [card("Opp Draw") for _ in range(5)])

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            rng=random.Random(2),
            stack=battle.Stack(),
        )

        assert len(active.hand) == 1

    def test_approach_sets_explicit_win_state():
        active = player("Active")
        opponent = player("Opponent")
        approach = {
            "name": "Approach of the Second Sun",
            "cmc": 7,
            "type_line": "Sorcery",
        }

        battle.apply_effect_immediate(active, [opponent], approach, 5, random.Random(3))
        assert active.has_won() is False
        battle.apply_effect_immediate(active, [opponent], approach, 6, random.Random(3))

        assert active.has_won() is True
        assert active.win_reason == "approach"

    def test_turn_stops_immediately_after_approach_win():
        active = player("Active", [card("Library card") for _ in range(10)])
        opponent = player("Opponent", [card("Opp Library") for _ in range(10)])
        active.approach_count = 1
        active.hand = [
            {
                "name": "Approach of the Second Sun",
                "cmc": 7,
                "type_line": "Sorcery",
            },
            {
                "name": "Must Stay In Hand",
                "cmc": 1,
                "tag": "draw",
                "type_line": "Sorcery",
            },
        ]
        active.battlefield = ["land" for _ in range(10)]

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=5,
            rng=random.Random(5),
            stack=battle.Stack(),
        )

        assert active.has_won() is True
        assert any(card["name"] == "Must Stay In Hand" for card in active.hand)

    def test_conformance_failed_draw_from_empty_library_loses():
        active = player("Active")
        active.hand = [card("Still in hand")]

        assert active.draw(1, random.Random(120)) == []
        assert battle.check_sbas_until_stable([active]) is None

        assert active.eliminated is True
        assert active.life == 0

    def test_failed_draw_from_empty_library_loses_even_with_cards_in_hand():
        active = player("Active")
        active.hand = [card("Still in hand")]

        drawn = active.draw(1, random.Random(45))
        eliminated = battle.check_sbas([active])

        assert drawn == []
        assert eliminated is True
        assert active.eliminated is True
        assert active.life == 0

    def test_one_shot_ritual_is_not_spent_without_same_turn_payoff():
        active = player("Active")
        opponent = player("Opponent")
        petal = {
            "name": "Lotus Petal",
            "cmc": 0,
            "type_line": "Artifact",
            "effect": "ramp_ritual",
            "mana_produced": 1,
        }
        expensive = {
            "name": "Expensive Sorcery",
            "cmc": 7,
            "type_line": "Sorcery",
            "effect": "draw",
        }
        active.hand = [petal, expensive]
        active.mana_pool.add_generic(1)

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(91),
        )

        assert acted is False
        assert petal in active.hand
        assert active.graveyard == []

    def test_one_shot_ritual_can_be_spent_when_it_unlocks_spell():
        active = player("Active")
        opponent = player("Opponent")
        petal = {
            "name": "Lotus Petal",
            "cmc": 0,
            "type_line": "Artifact",
            "effect": "ramp_ritual",
            "mana_produced": 1,
        }
        two_drop = {
            "name": "Two Drop Creature",
            "cmc": 2,
            "type_line": "Creature",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
        }
        active.hand = [petal, two_drop]
        active.mana_pool.add_generic(1)

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(92),
        )

        assert acted is True
        assert petal in active.graveyard
        assert two_drop not in active.hand
        assert any(
            isinstance(permanent, dict)
            and permanent.get("name") == "Two Drop Creature"
            for permanent in active.battlefield
        )

    def test_one_shot_ritual_trace_records_unlock_payoff():
        decisions = []
        previous_handler = battle.DECISION_TRACE_HANDLER
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            active = player("Active")
            opponent = player("Opponent")
            petal = {
                "name": "Lotus Petal",
                "cmc": 0,
                "type_line": "Artifact",
                "effect": "ramp_ritual",
                "mana_produced": 1,
            }
            two_drop = {
                "name": "Two Drop Creature",
                "cmc": 2,
                "type_line": "Creature",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
            }
            active.hand = [petal, two_drop]
            active.mana_pool.add_generic(1)

            acted = battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                turn=1,
                phase="precombat_main",
                stack=battle.Stack(),
                rng=random.Random(9201),
            )
        finally:
            battle.DECISION_TRACE_HANDLER = previous_handler

        assert acted is True
        trace = next(
            trace
            for trace in decisions
            if trace["decision_type"] == "cast_spell"
            and trace["chosen_option"].get("card") == "Lotus Petal"
        )
        assert trace["expected_payoff_reason"] == "same_turn_castable_spell"
        assert trace["score_components"]["unlock_card"] == "Two Drop Creature"
        assert trace["resource_delta"]["unlock_card"] == "Two Drop Creature"
        assert trace["resource_delta"]["unlock_reason"] == "same_turn_castable_spell"

    def test_extra_turns_are_taken_before_next_player():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active", [card("Draw 1"), card("Draw 2"), card("Draw 3")])
        defender = player("Defender", [card("Opp Draw")])
        active.extra_turns = 1

        battle.play_turn_sequence_v8(
            active,
            [defender],
            [active, defender],
            turn=4,
            rng=random.Random(46),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert active.extra_turns == 0
        assert [event for event, _ in events].count("turn_start") == 2
        assert any(event == "extra_turn_taken" for event, _ in events)

    def test_final_fortune_extra_turn_causes_loss_after_taken_turn():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active", [card("Draw 1"), card("Draw 2"), card("Draw 3"), card("Draw 4")])
        defender = player("Defender", [card("Opp Draw 1"), card("Opp Draw 2")])

        battle.apply_effect_immediate(
            active,
            [defender],
            {"name": "Final Fortune", "cmc": 2, "type_line": "Instant"},
            turn=4,
            rng=random.Random(4601),
            effect_data_override={
                "effect": "extra_turn",
                "instant": True,
                "turns": 1,
                "lose_after_extra_turn": True,
                "battle_model_scope": "single_extra_turn_then_lose_game_v1",
            },
        )

        assert active.extra_turns == 1
        assert active.extra_turn_loss_pending == 1

        battle.play_turn_sequence_v8(
            active,
            [defender],
            [active, defender],
            turn=4,
            rng=random.Random(4602),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert active.eliminated is True
        assert active.extra_turns == 0
        assert active.extra_turn_loss_pending == 0
        assert any(event == "extra_turn_scheduled" for event, _ in events)
        assert any(
            event == "player_eliminated"
            and data.get("reason") == "delayed_extra_turn_loss"
            for event, data in events
        )

    def test_scattered_thoughts_selects_two_from_top_four_and_bins_the_rest():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.library = [
            {"name": "Land Slot", "type_line": "Land"},
            {"name": "Counter Slot", "cmc": 2, "type_line": "Instant", "effect": "counter"},
            {"name": "Refill Slot", "cmc": 4, "type_line": "Sorcery", "effect": "draw_cards", "count": 2},
            {"name": "Big Creature", "cmc": 7, "type_line": "Creature", "effect": "creature"},
            {"name": "Bottom Card", "cmc": 1, "type_line": "Sorcery", "effect": "draw_cards", "count": 1},
        ]

        battle.apply_effect_immediate(
            active,
            [],
            {"name": "Scattered Thoughts", "cmc": 4, "type_line": "Instant"},
            turn=4,
            rng=random.Random(4603),
            effect_data_override={
                "effect": "dig_to_hand",
                "instant": True,
                "look_count": 4,
                "pick_count": 2,
                "selection_destination": "hand",
                "remainder_destination": "graveyard",
                "battle_model_scope": "look_top_n_pick_m_to_hand_rest_graveyard_v1",
            },
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert {card["name"] for card in active.hand} == {"Counter Slot", "Refill Slot"}
        assert {card["name"] for card in active.graveyard} == {"Land Slot", "Big Creature"}
        assert [card["name"] for card in active.library] == ["Bottom Card"]
        assert any(event == "dig_to_hand_resolved" for event, _ in events)

    def test_extra_combat_effect_schedules_and_untaps_creatures():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.battlefield = [
            {
                "name": "Tapped Attacker",
                "effect": "creature",
                "power": 3,
                "toughness": 3,
                "tapped": True,
            }
        ]

        battle.apply_effect_immediate(
            active,
            [],
            {
                "name": "Relentless Assault Test",
                "effect": "extra_combat",
                "combats": 1,
                "type_line": "Sorcery",
            },
            turn=4,
            rng=random.Random(47),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert active.extra_combats == 1
        assert active.battlefield[0]["tapped"] is False
        assert any(event == "extra_combat_scheduled" for event, _ in events)

    def test_extra_combat_is_taken_before_postcombat_main():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active", [card("Draw 1"), card("Draw 2"), card("Draw 3")])
        defender = player("Defender", [card("Opp Draw")])
        defender.life = 40
        active.extra_combats = 1
        active.battlefield = [
            {
                "name": "Vigilant Attacker",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "summoning_sick": False,
                "tapped": False,
                "vigilance": True,
            }
        ]

        battle.play_turn_v8(
            active,
            [defender],
            [active, defender],
            turn=4,
            rng=random.Random(48),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert active.extra_combats == 0
        assert [event for event, _ in events].count("combat") == 2
        assert any(event == "extra_combat_taken" for event, _ in events)
        assert defender.life == 36

    def test_treasure_maker_can_discard_draw_and_create_treasures():
        active = player("Caster")
        active.hand = [{"name": "Discard Me", "cmc": 1, "type_line": "Sorcery"}]
        active.library = [
            {"name": "Drawn A", "cmc": 1, "type_line": "Instant"},
            {"name": "Drawn B", "cmc": 2, "type_line": "Sorcery"},
        ]

        battle.apply_effect_immediate(
            active,
            [],
            {"name": "Unexpected Windfall", "cmc": 4, "type_line": "Instant"},
            turn=4,
            rng=random.Random(9),
        )

        assert active.treasures == 2
        assert [card["name"] for card in active.hand] == ["Drawn A", "Drawn B"]
        assert [card["name"] for card in active.graveyard] == [
            "Discard Me",
            "Unexpected Windfall",
        ]

    def test_mulligan_rejects_three_lands_with_only_expensive_spells():
        hand = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain"},
            {"name": "Sacred Foundry", "cmc": 0, "type_line": "Land"},
            {"name": "Eight Mana Spell", "cmc": 8, "type_line": "Sorcery", "effect": "wipe"},
            {"name": "Nine Mana Spell", "cmc": 9, "type_line": "Creature", "effect": "creature"},
            {"name": "Eight Mana Artifact", "cmc": 8, "type_line": "Artifact", "effect": "draw"},
            {"name": "Nine Mana Wincon", "cmc": 9, "type_line": "Sorcery", "effect": "wincon"},
        ]

        evaluation = battle.mulligan_evaluation(hand)

        assert evaluation["keep"] is False
        assert evaluation["reason"] == "expensive_cluster_without_setup"
        assert "expensive_dead_hand" in evaluation["risk_flags"]

    def test_mulligan_rejects_three_lands_with_single_early_body_and_expensive_cluster():
        hand = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain"},
            {"name": "Sacred Foundry", "cmc": 0, "type_line": "Land"},
            {"name": "Two Drop", "cmc": 2, "type_line": "Creature", "effect": "creature"},
            {"name": "Eight Mana Spell", "cmc": 8, "type_line": "Sorcery", "effect": "wipe"},
            {"name": "Nine Mana Spell", "cmc": 9, "type_line": "Creature", "effect": "creature"},
            {"name": "Seven Mana Spell", "cmc": 7, "type_line": "Sorcery", "effect": "draw"},
        ]

        evaluation = battle.mulligan_evaluation(hand)

        assert evaluation["keep"] is False
        assert evaluation["reason"] == "expensive_cluster_without_setup"
        assert "expensive_dead_hand" in evaluation["risk_flags"]

    def test_mulligan_keeps_two_lands_with_cheap_ramp():
        hand = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain"},
            {"name": "Arcane Signet", "cmc": 2, "type_line": "Artifact", "effect": "ramp_permanent"},
            {"name": "Four Mana Spell", "cmc": 4, "type_line": "Sorcery", "effect": "draw"},
            {"name": "Eight Mana Spell", "cmc": 8, "type_line": "Sorcery", "effect": "wipe"},
            {"name": "Nine Mana Spell", "cmc": 9, "type_line": "Creature", "effect": "creature"},
            {"name": "Seven Mana Spell", "cmc": 7, "type_line": "Sorcery", "effect": "draw"},
        ]

        evaluation = battle.mulligan_evaluation(hand)

        assert evaluation["keep"] is True
        assert evaluation["reason"].startswith("early_ramp:Arcane Signet")

    def test_mulligan_keeps_three_lands_with_card_flow_even_with_expensive_cluster():
        hand = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain"},
            {"name": "Sacred Foundry", "cmc": 0, "type_line": "Land"},
            {"name": "Faithless Looting", "cmc": 1, "type_line": "Sorcery", "effect": "rummage"},
            {"name": "Eight Mana Spell", "cmc": 8, "type_line": "Sorcery", "effect": "wipe"},
            {"name": "Nine Mana Spell", "cmc": 9, "type_line": "Creature", "effect": "creature"},
            {"name": "Seven Mana Spell", "cmc": 7, "type_line": "Sorcery", "effect": "draw"},
        ]

        evaluation = battle.mulligan_evaluation(hand)

        assert evaluation["keep"] is True
        assert evaluation["reason"].startswith("early_card_flow:Faithless Looting")

    def test_mulligan_rejects_off_color_early_hand_without_fixing():
        hand = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {"name": "Wastes", "cmc": 0, "type_line": "Basic Land — Wastes"},
            {
                "name": "Faithless Looting",
                "cmc": 1,
                "mana_cost": "{R}",
                "type_line": "Sorcery",
                "effect": "rummage",
            },
            {"name": "Four Mana Spell", "cmc": 4, "type_line": "Sorcery", "effect": "draw"},
            {"name": "Five Mana Spell", "cmc": 5, "type_line": "Sorcery", "effect": "draw"},
            {"name": "Six Mana Spell", "cmc": 6, "type_line": "Creature", "effect": "creature"},
        ]

        evaluation = battle.mulligan_evaluation(hand)

        assert evaluation["keep"] is False
        assert evaluation["reason"] == "no_castable_early_play_by_color"
        assert "off_color_early_hand" in evaluation["risk_flags"]
        assert evaluation["off_color_early_cards"] == ["Faithless Looting"]

    def test_mulligan_keeps_off_color_early_hand_when_wildcard_fixing_exists():
        hand = [
            {
                "name": "Command Tower",
                "cmc": 0,
                "type_line": "Land",
                "produces": "WUBRGC",
            },
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {
                "name": "Faithless Looting",
                "cmc": 1,
                "mana_cost": "{R}",
                "type_line": "Sorcery",
                "effect": "rummage",
            },
            {"name": "Four Mana Spell", "cmc": 4, "type_line": "Sorcery", "effect": "draw"},
            {"name": "Five Mana Spell", "cmc": 5, "type_line": "Sorcery", "effect": "draw"},
            {"name": "Six Mana Spell", "cmc": 6, "type_line": "Creature", "effect": "creature"},
            {"name": "Seven Mana Spell", "cmc": 7, "type_line": "Sorcery", "effect": "draw"},
        ]

        evaluation = battle.mulligan_evaluation(hand)

        assert evaluation["keep"] is True
        assert evaluation["reason"].startswith("early_card_flow:Faithless Looting")
        assert evaluation["off_color_early_count"] == 0

    def test_mulligan_treats_fetch_land_as_opening_color_fixing():
        hand = [
            {"name": "Bloodstained Mire", "cmc": 0, "type_line": "Land"},
            {"name": "Urza's Saga", "cmc": 0, "type_line": "Enchantment Land"},
            {
                "name": "Esper Sentinel",
                "cmc": 1,
                "mana_cost": "{W}",
                "type_line": "Artifact Creature",
                "effect": "draw_engine",
            },
            {
                "name": "Land Tax",
                "cmc": 1,
                "mana_cost": "{W}",
                "type_line": "Enchantment",
                "effect": "passive",
            },
            {
                "name": "Ghostly Prison",
                "cmc": 3,
                "mana_cost": "{2}{W}",
                "type_line": "Enchantment",
                "effect": "attack_tax",
            },
        ]

        evaluation = battle.mulligan_evaluation(hand)

        assert evaluation["keep"] is True
        assert evaluation["reason"].startswith("early_card_flow:Esper Sentinel")
        assert "off_color_early_hand" not in evaluation["risk_flags"]

    def test_mulligan_rejects_five_lands_with_only_reactive_spell():
        hand = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain"},
            {"name": "Sacred Foundry", "cmc": 0, "type_line": "Land"},
            {"name": "Battlefield Forge", "cmc": 0, "type_line": "Land"},
            {"name": "Needleverge Pathway", "cmc": 0, "type_line": "Land"},
            {"name": "Adamant Will", "cmc": 2, "type_line": "Instant", "effect": "indestructible"},
            {"name": "Eight Mana Spell", "cmc": 8, "type_line": "Sorcery", "effect": "wipe"},
        ]

        evaluation = battle.mulligan_evaluation(hand)

        assert evaluation["keep"] is False
        assert evaluation["reason"] == "land_heavy_reactive_only"
        assert "land_heavy_low_action" in evaluation["risk_flags"]

    def test_mulligan_rejects_dead_mox_amber_hand_without_live_legend():
        hand = [
            {"name": "Mana Confluence", "cmc": 0, "type_line": "Land"},
            {"name": "Command Tower", "cmc": 0, "type_line": "Land"},
            {"name": "Inspiring Vantage", "cmc": 0, "type_line": "Land"},
            {"name": "Scalding Tarn", "cmc": 0, "type_line": "Land"},
            {"name": "Mox Amber", "cmc": 0, "type_line": "Legendary Artifact", "effect": "ramp_permanent"},
            {"name": "Mizzix's Mastery", "cmc": 4, "type_line": "Sorcery", "effect": "overload_recursion"},
            {"name": "Rise of the Eldrazi", "cmc": 12, "type_line": "Sorcery", "effect": "extra_turn"},
        ]

        evaluation = battle.mulligan_evaluation(hand)

        assert evaluation["keep"] is False
        assert evaluation["reason"] == "no_play_before_turn_3"
        assert "no_early_game_plan" in evaluation["risk_flags"]

    def test_mulligan_bottoms_expensive_cards_before_lands_and_early_play():
        hand = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain"},
            {"name": "Sacred Foundry", "cmc": 0, "type_line": "Land"},
            {"name": "Arcane Signet", "cmc": 2, "type_line": "Artifact", "effect": "ramp_permanent"},
            {"name": "Cheap Removal", "cmc": 1, "type_line": "Instant", "effect": "remove_creature"},
            {"name": "Eight Mana Spell", "cmc": 8, "type_line": "Sorcery", "effect": "wipe"},
            {"name": "Nine Mana Wincon", "cmc": 9, "type_line": "Sorcery", "effect": "wincon"},
        ]

        bottomed = battle.choose_mulligan_bottom_cards(hand, 2)

        assert [card["name"] for card in bottomed] == [
            "Nine Mana Wincon",
            "Eight Mana Spell",
        ]

    def test_mulligan_bottoms_expensive_card_even_in_land_heavy_hand():
        hand = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain"},
            {"name": "Sacred Foundry", "cmc": 0, "type_line": "Land"},
            {"name": "Clifftop Retreat", "cmc": 0, "type_line": "Land"},
            {"name": "Battlefield Forge", "cmc": 0, "type_line": "Land"},
            {"name": "Two Drop", "cmc": 2, "type_line": "Creature", "effect": "creature"},
            {"name": "Eight Mana Spell", "cmc": 8, "type_line": "Sorcery", "effect": "wipe"},
        ]

        bottomed = battle.choose_mulligan_bottom_cards(hand, 1)

        assert bottomed[0]["name"] == "Eight Mana Spell"

    def test_mulligan_bottoms_off_color_early_spell_after_dead_bomb():
        hand = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {"name": "Wastes", "cmc": 0, "type_line": "Basic Land — Wastes"},
            {"name": "Clifftop Retreat", "cmc": 0, "type_line": "Land"},
            {
                "name": "Faithless Looting",
                "cmc": 1,
                "mana_cost": "{R}",
                "type_line": "Sorcery",
                "effect": "rummage",
            },
            {"name": "Helpful Two Drop", "cmc": 2, "type_line": "Creature", "effect": "creature"},
            {"name": "Eight Mana Spell", "cmc": 8, "type_line": "Sorcery", "effect": "wipe"},
        ]

        bottomed = battle.choose_mulligan_bottom_cards(hand, 2)

        assert [card["name"] for card in bottomed] == [
            "Eight Mana Spell",
            "Faithless Looting",
        ]

    def test_mulligan_bottoms_excess_land_when_no_dead_spell_exists():
        hand = [
            {"name": "Plains", "cmc": 0, "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "cmc": 0, "type_line": "Basic Land — Mountain"},
            {"name": "Sacred Foundry", "cmc": 0, "type_line": "Land"},
            {"name": "Clifftop Retreat", "cmc": 0, "type_line": "Land"},
            {"name": "Battlefield Forge", "cmc": 0, "type_line": "Land"},
            {"name": "Two Drop", "cmc": 2, "type_line": "Creature", "effect": "creature"},
            {"name": "Three Drop", "cmc": 3, "type_line": "Creature", "effect": "creature"},
        ]

        bottomed = battle.choose_mulligan_bottom_cards(hand, 1)

        assert battle.is_effective_land(bottomed[0])

    return [
        test_draw_step_runs_once_with_multiple_permanents,
        test_approach_sets_explicit_win_state,
        test_turn_stops_immediately_after_approach_win,
        test_conformance_failed_draw_from_empty_library_loses,
        test_failed_draw_from_empty_library_loses_even_with_cards_in_hand,
        test_one_shot_ritual_is_not_spent_without_same_turn_payoff,
        test_one_shot_ritual_can_be_spent_when_it_unlocks_spell,
        test_one_shot_ritual_trace_records_unlock_payoff,
        test_extra_turns_are_taken_before_next_player,
        test_extra_combat_effect_schedules_and_untaps_creatures,
        test_extra_combat_is_taken_before_postcombat_main,
        test_treasure_maker_can_discard_draw_and_create_treasures,
        test_mulligan_rejects_three_lands_with_only_expensive_spells,
        test_mulligan_rejects_three_lands_with_single_early_body_and_expensive_cluster,
        test_mulligan_keeps_two_lands_with_cheap_ramp,
        test_mulligan_keeps_three_lands_with_card_flow_even_with_expensive_cluster,
        test_mulligan_rejects_off_color_early_hand_without_fixing,
        test_mulligan_keeps_off_color_early_hand_when_wildcard_fixing_exists,
        test_mulligan_treats_fetch_land_as_opening_color_fixing,
        test_mulligan_rejects_five_lands_with_only_reactive_spell,
        test_mulligan_rejects_dead_mox_amber_hand_without_live_legend,
        test_mulligan_bottoms_expensive_cards_before_lands_and_early_play,
        test_mulligan_bottoms_expensive_card_even_in_land_heavy_hand,
        test_mulligan_bottoms_off_color_early_spell_after_dead_bomb,
        test_mulligan_bottoms_excess_land_when_no_dead_spell_exists,
    ]
