import battle_analyst_v9 as battle


def lorehold_commander():
    return {
        "name": "Lorehold, the Historian",
        "type_line": "Legendary Creature - Elder Dragon",
        "is_commander": True,
    }


def urzas_saga_on_final_setup_turn():
    return {
        "name": "Urza's Saga",
        "type_line": "Enchantment Land - Urza's Saga",
        "effect": "land",
        "current_chapter": 2,
        "lore_counters": 2,
    }


def artifact_targets():
    return [
        {
            "name": "Esper Sentinel",
            "cmc": 1,
            "type_line": "Artifact Creature - Human Soldier",
        },
        {
            "name": "Sol Ring",
            "cmc": 1,
            "type_line": "Artifact",
        },
        {
            "name": "Sensei's Divining Top",
            "cmc": 1,
            "type_line": "Artifact",
        },
        {
            "name": "Library of Leng",
            "cmc": 1,
            "type_line": "Artifact",
        },
    ]


def test_urzas_saga_prefers_lorehold_topdeck_engine_over_generic_value():
    lorehold = battle.Player("Lorehold", lorehold_commander(), [], is_human=True)
    lorehold.battlefield = [urzas_saga_on_final_setup_turn()]
    lorehold.library = artifact_targets()

    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.process_upkeep_utility_lands(lorehold, turn=3, all_players=[lorehold])
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert any(card["name"] == "Sensei's Divining Top" for card in lorehold.battlefield)
    resolved = [data for event, data in events if event == "saga_chapter_resolved"]
    assert resolved
    assert resolved[-1]["found"] == "Sensei's Divining Top"
    assert resolved[-1]["selected_reason"] == "find_lorehold_topdeck_miracle_engine"
    assert resolved[-1]["candidate_names"][:4] == [
        "Sensei's Divining Top",
        "Library of Leng",
        "Sol Ring",
        "Esper Sentinel",
    ]
