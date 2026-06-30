#!/usr/bin/env python3
"""Focused runtime tests for exact artifact/topdeck split scopes."""

from __future__ import annotations

import importlib.util
import random
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_artifact_topdeck_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def leyline_dowser():
    return {
        "name": "Leyline Dowser",
        "type_line": "Artifact",
        "effect": "passive",
        "battle_model_scope": "pay_one_tap_mill_one_instant_sorcery_to_hand_tap_legendary_creature_to_untap_v1",
        "activation_cost_generic": 1,
        "activation_requires_tap": True,
        "activated_self_mill_count": 1,
        "mill_count": 1,
        "milled_card_types_to_hand": ["instant", "sorcery"],
        "secondary_untap_source_by_tapping_legendary_creature": True,
    }


def orcish_spy():
    return {
        "name": "Orcish Spy",
        "type_line": "Creature - Orc Rogue",
        "effect": "topdeck_play",
        "battle_model_scope": "tap_look_top_three_target_player_library_v1",
        "activation_requires_tap": True,
        "look_target_player_library_top_count": 3,
        "play_lands_from_top_library": False,
        "alternate_zone_permission": False,
        "may_cast_without_paying_mana_cost": False,
        "power": 1,
        "toughness": 1,
        "summoning_sick": False,
    }


def prototype_portal():
    return {
        "name": "Prototype Portal",
        "type_line": "Artifact",
        "effect": "passive",
        "battle_model_scope": "imprint_artifact_from_hand_create_token_copy_x_mana_value_v1",
        "imprint_artifact_card_from_hand_on_enter": True,
        "activated_create_token_copy_of_imprinted_card": True,
        "activation_requires_tap": True,
        "activation_x_cost_source": "imprinted_card_mana_value",
        "token_copy_source": "imprinted_card",
    }


def pyxis():
    return {
        "name": "Pyxis of Pandemonium",
        "type_line": "Artifact",
        "effect": "passive",
        "battle_model_scope": "tap_each_player_exile_top_face_down_seven_tap_sacrifice_put_exiled_permanents_onto_battlefield_v1",
        "activated_each_player_exile_top_face_down": True,
        "activated_put_exiled_permanents_onto_battlefield": True,
        "activation_requires_tap": True,
        "final_activation_requires_sacrifice": True,
        "final_activation_cost_generic": 7,
        "alternate_zone_permission": True,
        "may_cast_without_paying_mana_cost": False,
        "put_permanent_cards_from_exile_onto_battlefield": True,
    }


def test_leyline_dowser_mills_instant_to_hand_and_can_untap_with_legendary_creature():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        dowser = leyline_dowser()
        dowser["tapped"] = True
        legend = {
            "name": "Lorehold, the Historian",
            "type_line": "Legendary Creature - Avatar",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
        }
        milled_spell = {
            "name": "Thrill of Possibility",
            "type_line": "Instant",
            "effect": "draw_cards",
            "cmc": 2,
        }
        active.battlefield = [dowser, legend]
        active.library = [milled_spell]
        active.mana_pool.add_generic(1)

        activated = battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=3,
            rng=random.Random(610),
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert activated == 1
    assert legend["tapped"] is True
    assert dowser["tapped"] is True
    assert milled_spell in active.hand
    assert milled_spell not in active.graveyard
    assert any(
        event == "utility_artifact_activated"
        and data.get("activation_kind") == "leyline_dowser_mill_one_maybe_spell_to_hand"
        and data.get("destination") == "hand"
        for event, data in events
    )


def test_orcish_spy_taps_to_look_at_target_players_top_three_without_moving_cards():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        spy = orcish_spy()
        cards = [
            {"name": "Mountain", "type_line": "Basic Land - Mountain", "effect": "land"},
            {"name": "Lightning Bolt", "type_line": "Instant", "effect": "direct_damage"},
            {"name": "Island", "type_line": "Basic Land - Island", "effect": "land"},
        ]
        active.battlefield = [spy]
        opponent.library = list(cards)

        activated = battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(610),
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert activated == 1
    assert spy["tapped"] is True
    assert opponent.library == cards
    assert any(
        event == "top_library_looked"
        and data.get("card") == "Orcish Spy"
        and data.get("target_player") == "Opponent"
        and data.get("seen_cards") == ["Mountain", "Lightning Bolt", "Island"]
        for event, data in events
    )


def test_prototype_portal_imprints_artifact_on_enter_and_creates_token_copy_for_x():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        imprint = {
            "name": "Chromatic Star",
            "type_line": "Artifact",
            "effect": "passive",
            "cmc": 1,
            "mana_cost": "{1}",
        }
        card = {"name": "Prototype Portal", "type_line": "Artifact", "cmc": 4}
        effect = prototype_portal()
        active.hand = [imprint]

        battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=4,
            rng=random.Random(610),
            effect_data_override=effect,
            stack=battle.Stack(),
            phase="precombat_main",
        )
        portal = next(permanent for permanent in active.battlefield if permanent.get("name") == "Prototype Portal")
        active.mana_pool.add_generic(1)
        activated = battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=5,
            rng=random.Random(610),
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert imprint not in active.hand
    assert any(card.get("name") == "Chromatic Star" for card in active.exile)
    assert portal["imprinted_card"] == "Chromatic Star"
    assert activated == 1
    assert any(
        permanent.get("token_copy_of") == "Chromatic Star"
        for permanent in active.battlefield
        if isinstance(permanent, dict)
    )
    assert any(
        event == "token_created"
        and data.get("activation_kind") == "prototype_portal_create_token_copy"
        and data.get("token_copy_of") == "Chromatic Star"
        for event, data in events
    )


def test_pyxis_exiles_each_players_top_card_then_sacrifices_to_put_permanents_onto_battlefield():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        source = pyxis()
        active_artifact = {
            "name": "Mana Rock",
            "type_line": "Artifact",
            "effect": "ramp_permanent",
            "cmc": 2,
        }
        opponent_spell = {
            "name": "Ponder",
            "type_line": "Sorcery",
            "effect": "draw_cards",
            "cmc": 1,
        }
        active.battlefield = [source]
        active.library = [active_artifact]
        opponent.library = [opponent_spell]

        first = battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            rng=random.Random(610),
            phase="precombat_main",
        )
        assert active_artifact in active.exile
        assert opponent_spell in opponent.exile
        source["tapped"] = False
        source["utility_artifact_used_this_turn"] = False
        active.mana_pool.add_generic(7)
        second = battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=5,
            rng=random.Random(611),
            phase="postcombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert first == 1
    assert second == 1
    assert any(permanent.get("name") == "Mana Rock" for permanent in active.battlefield)
    assert source in active.graveyard
    assert opponent_spell in opponent.exile
    assert any(
        event == "utility_artifact_activated"
        and data.get("activation_kind") == "pyxis_reveal_exiled_put_permanents_onto_battlefield"
        and data.get("put_onto_battlefield_count") == 1
        for event, data in events
    )


if __name__ == "__main__":
    test_leyline_dowser_mills_instant_to_hand_and_can_untap_with_legendary_creature()
    test_orcish_spy_taps_to_look_at_target_players_top_three_without_moving_cards()
    test_prototype_portal_imprints_artifact_on_enter_and_creates_token_copy_for_x()
    test_pyxis_exiles_each_players_top_card_then_sacrifices_to_put_permanents_onto_battlefield()
    print("PASS test_artifact_topdeck_runtime")
