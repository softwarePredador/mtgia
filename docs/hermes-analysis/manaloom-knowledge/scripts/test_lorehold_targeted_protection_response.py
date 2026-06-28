import random

import battle_analyst_v9 as battle


def player(name, *, commander=None, is_human=False):
    return battle.Player(name, commander, [], is_human=is_human)


def lorehold_commander():
    return {
        "name": "Lorehold, the Historian",
        "effect": "commander",
        "type_line": "Legendary Creature — Elder Dragon",
        "cmc": 4,
        "power": 4,
        "toughness": 4,
        "is_commander": True,
    }


def flood_maw_stack_item(controller, target_controller, target):
    card = {
        "name": "Into the Flood Maw",
        "cmc": 1,
        "type_line": "Instant",
        "colors": ["U"],
    }
    effect = {
        "effect": "remove_creature",
        "target": "creature",
        "declared_targets": [
            {
                "target": target,
                "controller": target_controller,
                "target_type": "creature",
                "declared_by": controller,
            }
        ],
    }
    return card, effect


def resolve_targeted_removal_after_response(active, players, stack):
    battle.priority_round(active, players, stack, turn=4, rng=random.Random(2), phase="precombat_main")


def penance_permanent():
    return {
        "name": "Penance",
        "cmc": 3,
        "type_line": "Enchantment",
        "effect": "damage_prevention_shield",
        "activation_cost": "put_card_from_hand_on_top_of_library",
        "activation_cost_generic": 0,
        "activation_requires_put_card_from_hand_on_top_library": True,
        "activated_prevent_next_damage_from_chosen_source": True,
        "battle_model_scope": "activated_put_card_from_hand_on_top_library_prevent_next_damage_from_chosen_black_or_red_source_to_you_v1",
        "rule_source": "test",
        "review_status": "verified",
    }


def hidden_retreat_permanent():
    return {
        "name": "Hidden Retreat",
        "cmc": 3,
        "type_line": "Enchantment",
        "effect": "damage_prevention_shield",
        "activation_cost": "put_card_from_hand_on_top_of_library",
        "activation_cost_generic": 0,
        "activation_requires_put_card_from_hand_on_top_library": True,
        "activated_prevent_damage_from_target_spell": True,
        "battle_model_scope": "activated_put_card_from_hand_on_top_library_prevent_damage_from_target_instant_or_sorcery_spell_v1",
        "can_setup_lorehold_miracle_draw": True,
        "prevent_damage_amount": 999,
        "prevent_damage_duration": "until_end_of_turn",
        "prevent_damage_from_target_spell": True,
        "prevent_damage_target_type": "instant_or_sorcery_spell",
        "spell_target_required": True,
        "target_spell_card_types": ["instant", "sorcery"],
        "rule_source": "test",
        "review_status": "verified",
    }


def test_lorehold_uses_penance_as_proactive_miracle_topdeck_setup():
    commander = lorehold_commander()
    lorehold = player("Lorehold", commander=commander, is_human=True)
    opponent = player("Opponent")
    penance = penance_permanent()
    storm_herd = {
        "name": "Storm Herd",
        "cmc": 10,
        "type_line": "Sorcery",
    }
    plains = {
        "name": "Plains",
        "cmc": 0,
        "type_line": "Basic Land — Plains",
    }
    lorehold.battlefield = [commander, penance]
    lorehold.hand = [storm_herd]
    lorehold.library = [plains]

    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        activated = battle.activate_lorehold_topdeck_artifacts(
            lorehold,
            turn=5,
            rng=random.Random(4),
            phase="opponent_upkeep",
            all_players=[opponent, lorehold],
            stack=battle.Stack(),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert activated == 1
    assert storm_herd not in lorehold.hand
    assert lorehold.library[0] is storm_herd
    assert penance["utility_artifact_used_this_turn"] is True
    assert any(
        event == "hand_to_topdeck_activation"
        and data.get("card") == "Penance"
        and data.get("hand_to_top") == "Storm Herd"
        for event, data in events
    )
    assert any(
        event == "topdeck_manipulation_activated"
        and data.get("card") == "Penance"
        and data.get("activation_kind") == "hand_to_top_for_lorehold_miracle_setup"
        for event, data in events
    )


def test_lorehold_does_not_use_hidden_retreat_as_proactive_upkeep_setup_without_target_spell():
    commander = lorehold_commander()
    lorehold = player("Lorehold", commander=commander, is_human=True)
    opponent = player("Opponent")
    hidden_retreat = hidden_retreat_permanent()
    storm_herd = {
        "name": "Storm Herd",
        "cmc": 10,
        "type_line": "Sorcery",
    }
    plains = {
        "name": "Plains",
        "cmc": 0,
        "type_line": "Basic Land — Plains",
    }
    lorehold.battlefield = [commander, hidden_retreat]
    lorehold.hand = [storm_herd]
    lorehold.library = [plains]

    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        activated = battle.activate_lorehold_topdeck_artifacts(
            lorehold,
            turn=5,
            rng=random.Random(4),
            phase="opponent_upkeep",
            all_players=[opponent, lorehold],
            stack=battle.Stack(),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert activated == 0
    assert storm_herd in lorehold.hand
    assert lorehold.library[0] is plains
    assert not hidden_retreat.get("utility_artifact_used_this_turn")
    assert not any(event == "hand_to_topdeck_activation" for event, _ in events)


def test_lorehold_uses_hidden_retreat_against_target_instant_or_sorcery_damage_spell():
    commander = lorehold_commander()
    lorehold = player("Lorehold", commander=commander, is_human=True)
    opponent = player("Opponent")
    hidden_retreat = hidden_retreat_permanent()
    storm_herd = {
        "name": "Storm Herd",
        "cmc": 10,
        "type_line": "Sorcery",
    }
    plains = {
        "name": "Plains",
        "cmc": 0,
        "type_line": "Basic Land — Plains",
    }
    damage_spell = {
        "name": "Flame Rift",
        "cmc": 2,
        "type_line": "Instant",
        "colors": ["R"],
    }
    damage_effect = {
        "effect": "damage_each_opponent",
        "amount": 5,
        "instant": True,
    }
    lorehold.life = 5
    opponent.life = 20
    lorehold.battlefield = [commander, hidden_retreat]
    lorehold.hand = [storm_herd]
    lorehold.library = [plains]
    stack = battle.Stack()
    stack.push(damage_spell, opponent, damage_effect)

    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        responded = battle.priority_round(
            opponent,
            [opponent, lorehold],
            stack,
            turn=4,
            rng=random.Random(8),
            phase="precombat_main",
        )
        resolved = battle.priority_round(
            opponent,
            [opponent, lorehold],
            stack,
            turn=4,
            rng=random.Random(9),
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert responded is True
    assert resolved is False
    assert stack.empty()
    assert lorehold.life == 5
    assert storm_herd not in lorehold.hand
    assert lorehold.library[0] is storm_herd
    assert hidden_retreat["utility_artifact_used_this_turn"] is True
    assert any(
        event == "activated_ability"
        and data.get("card") == "Hidden Retreat"
        and data.get("activation_kind") == "put_card_from_hand_on_top_library_prevent_target_spell_damage"
        and data.get("target_spell") == "Flame Rift"
        for event, data in events
    )
    assert any(
        event == "replacement_applied"
        and data.get("affected_player") == "Lorehold"
        and data.get("source") == "Flame Rift"
        and data.get("prevented") is True
        for event, data in events
    )
    assert any(
        event == "damage_each_opponent_resolved"
        and data.get("card") == "Flame Rift"
        and any(
            result.get("player") == "Lorehold"
            and result.get("result") == "prevented"
            for result in data.get("damage_results", [])
        )
        for event, data in events
    )


def test_lorehold_does_not_use_penance_when_top_card_is_already_better():
    commander = lorehold_commander()
    lorehold = player("Lorehold", commander=commander, is_human=True)
    opponent = player("Opponent")
    penance = penance_permanent()
    storm_herd = {
        "name": "Storm Herd",
        "cmc": 10,
        "type_line": "Sorcery",
    }
    approach = {
        "name": "Approach of the Second Sun",
        "cmc": 7,
        "type_line": "Sorcery",
    }
    lorehold.battlefield = [commander, penance]
    lorehold.hand = [storm_herd]
    lorehold.library = [approach]

    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        activated = battle.activate_lorehold_topdeck_artifacts(
            lorehold,
            turn=5,
            rng=random.Random(5),
            phase="opponent_upkeep",
            all_players=[opponent, lorehold],
            stack=battle.Stack(),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert activated == 0
    assert storm_herd in lorehold.hand
    assert lorehold.library[0] is approach
    assert not any(event == "hand_to_topdeck_activation" for event, _ in events)


def test_lorehold_uses_gods_willing_response_for_targeted_commander_removal():
    commander = lorehold_commander()
    lorehold = player("Lorehold", commander=commander, is_human=True)
    opponent = player("Opponent")
    lorehold.battlefield = [commander]
    lorehold.mana_pool.add("white", 1)
    gods_willing = {
        "name": "Gods Willing",
        "cmc": 1,
        "mana_cost": "{W}",
        "type_line": "Instant",
        "colors": ["W"],
    }
    lorehold.hand = [gods_willing]
    card, effect = flood_maw_stack_item(opponent, lorehold, commander)
    stack = battle.Stack()
    stack.push(card, opponent, effect)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        responded = battle.priority_round(
            opponent,
            [opponent, lorehold],
            stack,
            turn=4,
            rng=random.Random(1),
            phase="precombat_main",
        )
        resolve_targeted_removal_after_response(opponent, [opponent, lorehold], stack)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert responded is True
    assert gods_willing not in lorehold.hand
    assert commander in lorehold.battlefield
    assert commander["protection_from"] == ["blue"]
    assert any(
        event == "targeted_protection_granted"
        and data.get("card") == "Gods Willing"
        and data.get("target") == "Lorehold, the Historian"
        and data.get("protection_from") == ["blue"]
        for event, data in events
    )
    assert any(
        event == "removal_resolved"
        and data.get("card") == "Into the Flood Maw"
        and data.get("result") == "no_legal_target"
        for event, data in events
    )


def test_lorehold_uses_mother_of_runes_tap_response_for_targeted_commander_removal():
    commander = lorehold_commander()
    lorehold = player("Lorehold", commander=commander, is_human=True)
    opponent = player("Opponent")
    mother = {
        "name": "Mother of Runes",
        "cmc": 1,
        "type_line": "Creature — Human Cleric",
        "colors": ["W"],
    }
    lorehold.battlefield = [commander, mother]
    card, effect = flood_maw_stack_item(opponent, lorehold, commander)
    stack = battle.Stack()
    stack.push(card, opponent, effect)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        responded = battle.priority_round(
            opponent,
            [opponent, lorehold],
            stack,
            turn=4,
            rng=random.Random(3),
            phase="precombat_main",
        )
        resolve_targeted_removal_after_response(opponent, [opponent, lorehold], stack)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert responded is True
    assert mother["tapped"] is True
    assert commander in lorehold.battlefield
    assert commander["protection_from"] == ["blue"]
    assert any(
        event == "activated_ability"
        and data.get("card") == "Mother of Runes"
        and data.get("activation_kind") == "targeted_protection_response"
        for event, data in events
    )
