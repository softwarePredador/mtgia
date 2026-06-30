import random

import battle_analyst_v9 as battle


def neheb_permanent():
    return {
        "name": "Neheb, the Eternal",
        "type_line": "Legendary Creature - Zombie Minotaur Warrior",
        "effect": "ramp_engine",
        "battle_model_scope": "postcombat_main_add_red_for_opponents_life_lost_this_turn_v1",
        "is_creature_permanent": True,
        "permanent_type": "creature",
        "power": 4,
        "toughness": 6,
        "afflict": 3,
        "trigger": "beginning_postcombat_main",
        "postcombat_main_add_red_for_opponents_life_lost_this_turn": True,
        "opponents_lost_life_this_turn": True,
        "mana_added_per_opponent_life_lost": 1,
        "produces": "R",
        "mana_color": "red",
        "dynamic_mana_amount": True,
        "mana_amount_source": "opponents_lost_life_count_this_turn",
        "_rule_source": "test",
        "_rule_review_status": "verified",
        "_rule_execution_status": "auto",
        "_rule_confidence": 0.99,
        "_rule_logical_key": "battle_rule_v1:test_neheb_postcombat_mana",
    }


def resolve_pending(active, players, stack):
    for _ in range(8):
        if stack.empty() and not battle._pending_triggers:
            return
        battle.priority_round(
            active,
            players,
            stack,
            turn=7,
            rng=random.Random(607),
            phase="postcombat_main",
        )
    raise AssertionError("pending postcombat trigger did not resolve")


def test_neheb_adds_red_equal_to_opponents_life_lost_this_turn():
    active = battle.Player("Lorehold", None, [])
    opponent_one = battle.Player("Opponent One", None, [])
    opponent_two = battle.Player("Opponent Two", None, [])
    stack = battle.Stack()
    players = [active, opponent_one, opponent_two]
    active.battlefield = [neheb_permanent()]

    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.clear_pending_triggers()
    previous_turn = battle.CURRENT_REPLAY_TURN
    battle.CURRENT_REPLAY_TURN = 7
    try:
        battle.change_life(opponent_one, -3)
        battle.change_life(opponent_two, -2)
        triggered = battle.process_postcombat_main_phase_engines(
            active,
            [opponent_one, opponent_two],
            players,
            turn=7,
            rng=random.Random(7),
            stack=stack,
        )
        resolve_pending(active, players, stack)
    finally:
        battle.CURRENT_REPLAY_TURN = previous_turn
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.clear_pending_triggers()

    assert triggered == 1
    assert active.mana_pool.red == 5
    assert any(
        event == "trigger_put_on_stack"
        and data.get("card") == "Neheb, the Eternal"
        and data.get("trigger") == "beginning_postcombat_main"
        for event, data in events
    )
    assert any(
        event == "phase_trigger_resolved"
        and data.get("card") == "Neheb, the Eternal"
        and data.get("mana_added") == 5
        and data.get("mana_color") == "red"
        and data.get("opponents_life_lost_this_turn") == 5
        for event, data in events
    )


def test_neheb_postcombat_trigger_adds_zero_when_no_opponent_lost_life():
    active = battle.Player("Lorehold", None, [])
    opponent = battle.Player("Opponent", None, [])
    stack = battle.Stack()
    players = [active, opponent]
    active.battlefield = [neheb_permanent()]

    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.clear_pending_triggers()
    try:
        triggered = battle.process_postcombat_main_phase_engines(
            active,
            [opponent],
            players,
            turn=7,
            rng=random.Random(8),
            stack=stack,
        )
        resolve_pending(active, players, stack)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.clear_pending_triggers()

    assert triggered == 1
    assert active.mana_pool.red == 0
    assert any(
        event == "phase_trigger_resolved"
        and data.get("card") == "Neheb, the Eternal"
        and data.get("mana_added") == 0
        and data.get("opponents_life_lost_this_turn") == 0
        for event, data in events
    )
