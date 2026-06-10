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

    return [
        test_draw_step_runs_once_with_multiple_permanents,
        test_approach_sets_explicit_win_state,
        test_turn_stops_immediately_after_approach_win,
        test_conformance_failed_draw_from_empty_library_loses,
        test_failed_draw_from_empty_library_loses_even_with_cards_in_hand,
        test_extra_turns_are_taken_before_next_player,
        test_treasure_maker_can_discard_draw_and_create_treasures,
    ]
