#!/usr/bin/env python3
"""Regression tests for battle_target_pressure_audit."""

import battle_target_pressure_audit as audit


def test_passes_when_all_opponent_combat_targets_lorehold():
    result = audit.audit_events(
        [
            {
                "event": "combat",
                "turn": 2,
                "attacker": "Opponent A",
                "target": "Lorehold",
                "target_reason": "evaluation_target_pressure",
                "evaluation_target_active": True,
            },
            {
                "event": "combat",
                "turn": 3,
                "attacker": "Lorehold",
                "target": "Opponent A",
                "target_reason": "default_low_life",
            },
        ],
        "Lorehold",
    )
    assert result["status"] == "pass"
    assert result["opponent_combat_total"] == 1
    assert result["opponent_combat_to_target"] == 1
    assert result["findings"] == 0


def test_accepts_lethal_target_reason_when_evaluation_target_is_active():
    result = audit.audit_events(
        [
            {
                "event": "combat",
                "turn": 6,
                "attacker": "Opponent A",
                "target": "Lorehold",
                "target_reason": "lethal",
                "evaluation_target_active": True,
            }
        ],
        "Lorehold",
    )
    assert result["status"] == "pass"
    assert result["opponent_combat_to_target"] == 1
    assert result["opponent_combat_missing_pressure_reason"] == 0


def test_accepts_table_intent_target_reason_when_evaluation_target_is_active():
    result = audit.audit_events(
        [
            {
                "event": "combat",
                "turn": 4,
                "attacker": "Opponent A",
                "target": "Lorehold",
                "target_reason": "table_intent_table_threat",
                "evaluation_target_active": True,
                "table_intent_enabled": True,
            },
            {
                "event": "combat",
                "turn": 5,
                "attacker": "Opponent B",
                "target": "Lorehold",
                "target_reason": "table_intent_low_life_opportunism",
                "evaluation_target_active": True,
                "table_intent_enabled": True,
            },
        ],
        "Lorehold",
    )
    assert result["status"] == "pass"
    assert result["opponent_combat_to_target"] == 2
    assert result["opponent_combat_missing_pressure_reason"] == 0
    assert result["findings"] == 0


def test_blocks_when_opponent_combat_targets_non_lorehold_player():
    result = audit.audit_events(
        [
            {
                "event": "combat",
                "turn": 2,
                "attacker": "Opponent A",
                "target": "Opponent B",
                "target_reason": "default_low_life",
            }
        ],
        "Lorehold",
    )
    assert result["status"] == "blocked"
    assert result["opponent_combat_to_other"] == 1
    assert result["findings"] == 1
    assert result["violations"][0]["finding"] == "opponent_attacked_non_target_player"


def test_accepts_table_intent_political_attacks_to_other_players():
    result = audit.audit_events(
        [
            {
                "event": "combat",
                "turn": 5,
                "attacker": "Opponent A",
                "target": "Opponent B",
                "target_reason": "table_intent_table_threat",
                "table_intent_enabled": True,
            },
            {
                "event": "multi_defender_attack",
                "turn": 5,
                "attacker": "Opponent C",
                "groups": [
                    {"target": "Lorehold", "attackers": ["A"]},
                    {"target": "Opponent B", "attackers": ["B"]},
                ],
            },
        ],
        "Lorehold",
    )
    assert result["status"] == "pass"
    assert result["table_intent_mode_detected"] is True
    assert result["opponent_combat_to_other"] == 1
    assert result["opponent_combat_to_other_table_intent_accepted"] == 1
    assert result["opponent_multi_defender_attack"] == 1
    assert result["opponent_multi_defender_attack_table_intent_accepted"] == 1
    assert result["findings"] == 0


def test_ignores_opponent_combat_after_lorehold_is_eliminated():
    result = audit.audit_events(
        [
            {
                "event": "combat",
                "turn": 6,
                "attacker": "Opponent A",
                "target": "Lorehold",
                "target_reason": "evaluation_target_pressure",
                "evaluation_target_active": True,
            },
            {
                "event": "player_eliminated",
                "turn": 7,
                "player": "Lorehold",
                "reason": "life_zero",
            },
            {
                "event": "combat",
                "turn": 7,
                "attacker": "Opponent A",
                "target": "Opponent B",
                "target_reason": "default_low_life",
            },
        ],
        "Lorehold",
    )
    assert result["status"] == "pass"
    assert result["target_player_eliminated"] is True
    assert result["opponent_combat_to_target"] == 1
    assert result["opponent_combat_to_other"] == 0
    assert result["post_target_elimination_opponent_combat_ignored"] == 1
    assert result["findings"] == 0


if __name__ == "__main__":
    test_passes_when_all_opponent_combat_targets_lorehold()
    print("PASS test_passes_when_all_opponent_combat_targets_lorehold")
    test_accepts_lethal_target_reason_when_evaluation_target_is_active()
    print("PASS test_accepts_lethal_target_reason_when_evaluation_target_is_active")
    test_accepts_table_intent_target_reason_when_evaluation_target_is_active()
    print(
        "PASS "
        "test_accepts_table_intent_target_reason_when_evaluation_target_is_active"
    )
    test_blocks_when_opponent_combat_targets_non_lorehold_player()
    print("PASS test_blocks_when_opponent_combat_targets_non_lorehold_player")
    test_accepts_table_intent_political_attacks_to_other_players()
    print("PASS test_accepts_table_intent_political_attacks_to_other_players")
    test_ignores_opponent_combat_after_lorehold_is_eliminated()
    print("PASS test_ignores_opponent_combat_after_lorehold_is_eliminated")
