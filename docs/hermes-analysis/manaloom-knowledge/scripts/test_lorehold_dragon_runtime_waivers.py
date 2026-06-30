#!/usr/bin/env python3
"""Runtime-waiver checks for Lorehold dragon cards learned from XMage."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_lorehold_dragons_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def test_lorehold_dragon_waivers_resolve_to_executable_runtime_rules():
    battle = load_battle()

    twinflame = battle.get_card_effect(
        {"name": "Twinflame Tyrant", "type_line": "Creature - Dragon", "cmc": 5}
    )
    terror = battle.get_card_effect(
        {"name": "Terror of the Peaks", "type_line": "Creature - Dragon", "cmc": 5}
    )

    assert twinflame["effect"] == "damage_modifier"
    assert twinflame["battle_model_scope"] == (
        "controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1"
    )
    assert twinflame["_rule_logical_key"] == "battle_rule_v1:2b4bda8e443bbbf48e1654884d61355c"
    assert twinflame["_rule_oracle_hash"] == "e4ca0585f743b1c34c36649bfbb1fff6"
    assert twinflame["_rule_review_status"] == "verified"
    assert twinflame["_rule_execution_status"] == "auto"

    assert terror["effect"] == "creature"
    assert terror["battle_model_scope"] == "controlled_other_creature_enters_power_damage_any_target_v1"
    assert terror["trigger"] == "creature_you_control_enters"
    assert terror["trigger_effect"] == "damage_any_target"
    assert terror["trigger_damage_amount_source"] == "entering_creature_power"
    assert terror["trigger_another_creature_you_control_enters"] is True
    assert terror["_rule_logical_key"] == "battle_rule_v1:ae8cab02963098960997301b3c227a80"
    assert terror["_rule_oracle_hash"] == "90c007ac59cdd400f58e89c47d81440e"
    assert terror["_rule_review_status"] == "verified"
    assert terror["_rule_execution_status"] == "auto"


def test_twinflame_tyrant_waiver_doubles_runtime_damage_from_get_card_effect():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.battlefield = [
            battle.get_card_effect(
                {"name": "Twinflame Tyrant", "type_line": "Creature - Dragon", "cmc": 5}
            )
        ]

        damage_dealt, final_amount, dealt = battle.deal_damage_to_player_with_static_replacements(
            active,
            opponent,
            {"name": "Lightning Bolt", "type_line": "Instant", "controller": "Lorehold"},
            3,
            turn=6,
            phase="resolution",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert dealt is True
    assert final_amount == 6
    assert damage_dealt == 6
    assert opponent.life == 34
    assert any(
        event == "static_damage_replacement_applied"
        and data.get("source") == "Lightning Bolt"
        and data.get("original_amount") == 3
        and data.get("final_amount") == 6
        for event, data in events
    )


def test_terror_of_the_peaks_waiver_deals_entering_creature_power_damage():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        opponent.life = 7
        terror = battle.get_card_effect(
            {"name": "Terror of the Peaks", "type_line": "Creature - Dragon", "cmc": 5}
        )
        active.battlefield = [
            {"name": "Terror of the Peaks", "type_line": "Creature - Dragon", **terror}
        ]

        battle.create_creature_token(
            active,
            name="Seven Power Token",
            power=7,
            toughness=7,
            opponents=[opponent],
            turn=7,
            all_players=[active, opponent],
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent.life == 0
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Terror of the Peaks"
        and data.get("trigger") == "creature_you_control_enters"
        and data.get("entering_creature") == "Seven Power Token"
        and data.get("entering_creature_power") == 7
        and data.get("effect") == "damage_any_target"
        and data.get("target_player") == "Opponent"
        and data.get("result") == "player_damage"
        and data.get("amount") == 7
        and data.get("life_after") == 0
        for event, data in events
    )
