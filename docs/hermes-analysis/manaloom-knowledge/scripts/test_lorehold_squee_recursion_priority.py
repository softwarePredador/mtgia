import random

import battle_analyst_v9 as battle


def card(name, type_line="", cmc=0, **extra):
    payload = {"name": name, "type_line": type_line, "cmc": cmc}
    payload.update(extra)
    return payload


def lorehold_player_with_squee():
    lorehold = battle.Player(
        "Lorehold",
        {"name": "Lorehold, the Historian"},
        [],
        is_human=True,
    )
    lorehold.battlefield = [
        card(
            "Lorehold, the Historian",
            "Legendary Creature - Elder Dragon",
            5,
            effect="creature",
            opponent_upkeep_rummage=True,
            grants_miracle_cost=2,
        ),
        card("Plains", "Basic Land - Plains", effect="land", mana_produced=1),
        card("Mountain", "Basic Land - Mountain", effect="land", mana_produced=1),
        card("Sacred Foundry", "Land", effect="land", mana_produced=1),
    ]
    lorehold.hand = [
        card("Squee, Goblin Nabob", "Legendary Creature - Goblin", 3),
    ]
    lorehold.library = [
        card("Mountain", "Land", effect="land"),
    ]
    lorehold.refresh_mana_sources(turn=1)
    return lorehold


def test_lorehold_holds_squee_for_rummage_recursion_instead_of_main_phase_cast():
    lorehold = lorehold_player_with_squee()
    opponent = battle.Player("Opponent", None, [])
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        casted = battle.cast_spells_v8(
            lorehold,
            [opponent],
            [lorehold, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(1),
            max_actions=1,
        )
        triggered = battle.process_lorehold_opponent_upkeep_rummage(
            opponent,
            [lorehold, opponent],
            turn=2,
            rng=random.Random(2),
            stack=battle.Stack(),
        )
        returned = battle.process_graveyard_upkeep_self_return(lorehold, turn=3)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert casted is False
    assert triggered == 1
    assert returned == 1
    assert any(card["name"] == "Squee, Goblin Nabob" for card in lorehold.hand)
    assert not any(card["name"] == "Squee, Goblin Nabob" for card in lorehold.graveyard)
    assert not any(
        event == "creature_cast" and data.get("card") == "Squee, Goblin Nabob"
        for event, data in events
    )
    assert any(
        event == "lorehold_upkeep_rummage"
        and data.get("discarded") == "Squee, Goblin Nabob"
        and data.get("discard_destination") == "graveyard"
        and data.get("replacement_used") is False
        and data.get("reason") == "discard_squee_for_upkeep_recursion"
        for event, data in events
    )
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Squee, Goblin Nabob"
        and data.get("effect") == "graveyard_upkeep_return_self_to_hand"
        for event, data in events
    )
