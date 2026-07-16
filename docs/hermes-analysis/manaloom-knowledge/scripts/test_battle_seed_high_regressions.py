#!/usr/bin/env python3
"""Regressions for the fresh strategy-audit blockers in seeds 63470523/26."""

from __future__ import annotations

import importlib.util
import random
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_module(module_name: str, filename: str):
    spec = importlib.util.spec_from_file_location(module_name, SCRIPT_DIR / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name: str):
    return battle.Player(name, None, [], strategy="midrange")


def test_surge_copied_wipe_resolves_after_simultaneous_combat_damage():
    """A copied wipe cannot erase the rest of the current damage step."""
    battle = load_module("battle_seed_63470523_under_test", "battle_analyst_v9.py")
    events = []
    decisions = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_decision_handler = battle.DECISION_TRACE_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.DECISION_TRACE_HANDLER = lambda data: decisions.append(data)
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        attacker_a = {
            "name": "First Attacker",
            "effect": "creature",
            "type_line": "Creature — Soldier",
            "power": 3,
            "toughness": 3,
        }
        attacker_b = {
            "name": "Second Attacker",
            "effect": "creature",
            "type_line": "Creature — Soldier",
            "power": 4,
            "toughness": 4,
        }
        active.battlefield = [attacker_a, attacker_b]
        active.surge_to_victory_delayed_triggers = [
            {
                "source_card": "Surge to Victory",
                "exiled_card": {
                    "name": "Everything Comes to Dust",
                    "type_line": "Sorcery",
                    "cmc": 7,
                    "effect": "exile_artifact_enchantment_creature_convoke_wipe",
                },
                "_rule_source": "curated",
                "_rule_review_status": "verified",
                "_rule_execution_status": "auto",
                "_rule_confidence": 0.97,
                "_rule_version": 2,
                "_rule_logical_key": "battle_rule_v1:surge-combat-order-test",
                "_rule_oracle_hash": "surge-combat-order-test-hash",
            }
        ]

        battle.combat_damage_steps(
            active,
            [opponent],
            opponent,
            [attacker_a, attacker_b],
            [(attacker_a, []), (attacker_b, [])],
            turn=8,
            rng=random.Random(63470523),
            all_players=[active, opponent],
            stack=battle.Stack(),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.DECISION_TRACE_HANDLER = previous_decision_handler

    # Both 3 and 4 power creatures dealt damage before the first copied wipe.
    assert opponent.life == 33
    copy_triggers = [
        data
        for event, data in events
        if event == "trigger_resolved"
        and data.get("card") == "Surge to Victory"
        and data.get("trigger") == "combat_damage_to_player"
    ]
    assert [data["trigger_creature"] for data in copy_triggers] == [
        "First Attacker",
        "Second Attacker",
    ]
    assert all(data["cast_choice_optional"] is True for data in copy_triggers)
    optional_copy_decisions = [
        decision
        for decision in decisions
        if decision.get("score_components", {}).get("source_resolution")
        == "surge_to_victory_combat_damage_copy"
    ]
    assert len(optional_copy_decisions) == 2
    assert all(decision["phase"] == "combat_damage" for decision in optional_copy_decisions)
    assert all(
        decision["chosen_option"]["action"] == "decline_optional_spell_copy_cast"
        for decision in optional_copy_decisions
    )
    combat_result = next(data for event, data in events if event == "combat_result")
    assert combat_result["damage_to_player"] == 7
    assert combat_result["target_life_after"] == 33


def test_surge_delayed_trigger_preserves_rule_lineage():
    battle = load_module("battle_surge_lineage_under_test", "battle_analyst_v9.py")
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    active.battlefield = [
        {
            "name": "Attacker",
            "effect": "creature",
            "type_line": "Creature — Soldier",
            "power": 2,
            "toughness": 2,
        }
    ]
    active.graveyard = [
        {
            "name": "Test Draw",
            "type_line": "Sorcery",
            "cmc": 1,
            "effect": "draw_cards",
            "count": 1,
        }
    ]
    effect_data = {
        "effect": "pump_all",
        "target": "instant_or_sorcery_graveyard",
        "exiles_target_from_graveyard": True,
        "pump_power_from_exiled_card_mana_value": True,
        "combat_damage_player_copies_exiled_card": True,
        "casts_copies_without_paying_mana": True,
        "card_id": "surge-card-id",
        "semantic_hash": "surge-semantic-hash",
        "_rule_source": "curated",
        "_rule_review_status": "verified",
        "_rule_execution_status": "auto",
        "_rule_confidence": 0.97,
        "_rule_version": 2,
        "_rule_logical_key": "battle_rule_v1:surge-lineage-test",
        "_rule_oracle_hash": "surge-lineage-test-hash",
    }

    battle.resolve_surge_to_victory(
        active,
        [opponent],
        [active, opponent],
        {"name": "Surge to Victory", "type_line": "Sorcery", "cmc": 6},
        effect_data,
        turn=8,
        rng=random.Random(118),
        stack=battle.Stack(),
        phase="precombat_main",
    )

    delayed = active.surge_to_victory_delayed_triggers[0]
    lineage = battle.replay_rule_fields(delayed)
    assert lineage["rule_source"] == "curated"
    assert lineage["rule_review_status"] == "verified"
    assert lineage["rule_logical_key"] == "battle_rule_v1:surge-lineage-test"
    assert lineage["card_id"] == "surge-card-id"
    assert lineage["semantic_hash"] == "surge-semantic-hash"


def test_seed_63470526_effect_family_is_registered_as_live_runtime():
    forensic = load_module("battle_seed_63470526_forensic", "battle_forensic_audit.py")

    assert (
        "gift_destroy_all_creatures_return_own_destroyed_creature"
        in forensic.SUPPORTED_EFFECTS
    )
    assert "harnessed_blink" in forensic.SUPPORTED_EFFECTS
    assert (
        "gift_destroy_all_creatures_return_own_destroyed_creature"
        in forensic.GAME_IMPACT_EFFECTS
    )
    assert "harnessed_blink" in forensic.GAME_IMPACT_EFFECTS


def test_seed_2026071605_deafening_silence_counts_reset_each_global_turn():
    """A previous-turn noncreature cast cannot lock the next turn's first spell."""
    battle = load_module("battle_seed_2026071605_turn_reset", "battle_analyst_v9.py")
    active = player(battle, "Etali")
    opponent = player(battle, "Tayam")
    restriction = {
        "source": "Deafening Silence",
        "spell_limit_per_turn": 1,
        "restricted_spell_scope": "noncreature_spells",
    }
    active.static_spell_limit_restrictions = [restriction]
    artifact = {
        "name": "Lotus Petal",
        "type_line": "Artifact",
        "cmc": 0,
        "mana_cost": "{0}",
        "effect": "ramp",
    }

    battle.CURRENT_REPLAY_TURN = 1
    active.record_spell_cast(1, card=artifact)
    active.record_noncreature_spell_cast(1)
    assert battle.static_spell_limit_lock_for_card(active, artifact) == restriction

    battle.CURRENT_REPLAY_TURN = 2
    battle.clear_turn_scoped_permanent_flags([active, opponent])
    assert active._spells_cast_turn_marker == 2
    assert active._noncreature_spells_cast_turn_marker == 2
    assert active.spells_cast_this_turn == 0
    assert active.noncreature_spells_cast_this_turn == 0
    assert battle.static_spell_limit_lock_for_card(active, artifact) is None

    active.record_spell_cast(2, card=artifact)
    active.record_noncreature_spell_cast(2)
    assert battle.static_spell_limit_lock_for_card(active, artifact) == restriction


def test_seed_2026071605_ramp_scanner_skips_known_illegal_second_spell():
    """Ramp prioritization must not announce/retry a spell already limited by Silence."""
    battle = load_module("battle_seed_2026071605_ramp_scanner", "battle_analyst_v9.py")
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Etali")
        opponent = player(battle, "Tayam")
        ramp_card = {
            "name": "Sol Ring",
            "type_line": "Artifact",
            "cmc": 1,
            "mana_cost": "{1}",
            "effect": "ramp",
            "mana_produced": 2,
        }
        active.hand = [ramp_card]
        active.mana_pool.generic = 10
        active.static_spell_limit_restrictions = [
            {
                "source": "Deafening Silence",
                "spell_limit_per_turn": 1,
                "restricted_spell_scope": "noncreature_spells",
            }
        ]
        battle.CURRENT_REPLAY_TURN = 5
        active.record_spell_cast(5, card={"name": "Prior Spell", "type_line": "Sorcery"})
        active.record_noncreature_spell_cast(5)

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=5,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(2026071605),
            max_actions=1,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert acted is False
    assert not any(
        event in {"cast_announced", "cast_illegal"}
        and data.get("card") == "Sol Ring"
        for event, data in events
    )


if __name__ == "__main__":
    test_surge_copied_wipe_resolves_after_simultaneous_combat_damage()
    test_surge_delayed_trigger_preserves_rule_lineage()
    test_seed_63470526_effect_family_is_registered_as_live_runtime()
    test_seed_2026071605_deafening_silence_counts_reset_each_global_turn()
    test_seed_2026071605_ramp_scanner_skips_known_illegal_second_spell()
    print("PASS test_battle_seed_high_regressions")
