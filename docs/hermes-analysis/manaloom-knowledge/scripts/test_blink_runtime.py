#!/usr/bin/env python3
"""Focused runtime tests for exile-then-return blink rules."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_blink_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def value_creature(name="Wall of Omens", *, etb_token=False):
    card = {
        "name": name,
        "type_line": "Creature - Wall",
        "effect": "creature",
        "power": 0,
        "toughness": 4,
        "tapped": True,
        "summoning_sick": True,
    }
    if etb_token:
        card["etb_token_count"] = 1
        card["token_name"] = "Blink Value Token"
        card["token_power"] = 1
        card["token_toughness"] = 1
    return card


def test_ephemerate_exiles_and_returns_target_creature_with_rebound_metadata():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [{"name": "Drawn Card", "type_line": "Instant"}])
        opponent = battle.Player("Opponent", None, [])
        target = value_creature()
        active.battlefield = [target]

        spell = {
            "name": "Ephemerate",
            "type_line": "Instant",
            "oracle_text": (
                "Exile target creature you control, then return it to the battlefield "
                "under its owner's control. Rebound."
            ),
        }
        effect = battle.get_card_effect(spell)

        battle.apply_effect_immediate(
            active,
            [opponent],
            spell,
            turn=3,
            rng=random.Random(607),
            effect_data_override=effect,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert effect["effect"] == "blink"
    assert effect["battle_model_scope"] == "exile_then_return_target_creature_you_control_rebound_v1"
    assert effect["_rule_source"] in {"manual_runtime_waiver", "curated"}
    assert len(active.battlefield) == 1
    returned = active.battlefield[0]
    assert returned["name"] == "Wall of Omens"
    assert returned.get("tapped") is False
    assert spell in active.exile
    assert spell.get("_rebound_pending") is True
    assert any(
        event == "blink_resolved"
        and data.get("card") == "Ephemerate"
        and data.get("target") == "Wall of Omens"
        and data.get("returned") == "Wall of Omens"
        for event, data in events
    )


def test_displacer_kitten_blinks_nonland_permanent_on_noncreature_spell():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [])
        opponent = battle.Player("Opponent", None, [])
        kitten_effect = battle.get_card_effect({"name": "Displacer Kitten", "type_line": "Creature - Cat Beast"})
        kitten = battle.prepare_entering_permanent(
            {"name": "Displacer Kitten", "type_line": "Creature - Cat Beast", **kitten_effect},
            controller=active,
            all_players=[active, opponent],
            turn=4,
        )
        target = value_creature("Solemn Simulacrum", etb_token=True)
        active.battlefield = [kitten, target]

        battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            {"name": "Big Score", "type_line": "Instant"},
            turn=4,
            phase="resolution",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert kitten_effect["trigger_effect"] == "blink"
    assert any(card.get("name") == "Displacer Kitten" for card in active.battlefield)
    assert any(card.get("name") == "Solemn Simulacrum" for card in active.battlefield)
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Displacer Kitten"
        and data.get("effect") == "blink"
        and data.get("blinked") == "Solemn Simulacrum"
        for event, data in events
    )


def test_emiel_activated_blink_pays_three_and_excludes_self():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [])
        opponent = battle.Player("Opponent", None, [])
        emiel_effect = battle.get_card_effect({"name": "Emiel the Blessed", "type_line": "Legendary Creature - Unicorn"})
        emiel = battle.prepare_entering_permanent(
            {"name": "Emiel the Blessed", "type_line": "Legendary Creature - Unicorn", **emiel_effect},
            controller=active,
            all_players=[active, opponent],
            turn=5,
        )
        target = value_creature("Priest of Ancient Lore")
        active.battlefield = [emiel, target]
        active.library = [{"name": "Plains", "type_line": "Basic Land - Plains", "effect": "land"}]
        active.mana_pool.add_generic(3)

        activations = battle.process_precombat_main_phase_engines(
            active,
            [opponent],
            [active, opponent],
            turn=5,
            rng=random.Random(616),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert emiel_effect["activated_blink"] is True
    assert activations is None
    assert active.available_mana() == 0
    assert any(card.get("name") == "Emiel the Blessed" for card in active.battlefield)
    assert any(card.get("name") == "Priest of Ancient Lore" for card in active.battlefield)
    assert any(
        event == "activated_ability_resolved"
        and data.get("card") == "Emiel the Blessed"
        and data.get("ability") == "blink"
        and data.get("blinked") == "Priest of Ancient Lore"
        for event, data in events
    )
