#!/usr/bin/env python3
"""Tests for battle_table_intent_audit."""

import battle_table_intent_audit as audit


def test_passes_when_table_intent_and_opponent_actions_exist():
    result = audit.audit_events(
        [
            {
                "event": "combat",
                "attacker": "Opponent",
                "target": "Lorehold",
                "table_intent_enabled": True,
                "table_intent_scores": [
                    {
                        "target": "Lorehold",
                        "score": 72,
                        "reason": "table_intent_nemesis_hostility",
                    }
                ],
                "blockers": 1,
            },
            {"event": "spell_cast", "player": "Opponent", "card": "Sol Ring"},
            {"event": "spell_resolved", "player": "Opponent", "card": "Sol Ring"},
            {
                "event": "spell_countered",
                "player": "Opponent",
                "counter": "Flusterstorm",
                "target_controller": "Lorehold",
            },
        ],
        require_table_intent=True,
    )
    assert result["status"] == "pass"
    assert result["table_intent_combat_total"] == 1
    assert result["opponent_interaction_events"] == 1


def test_blocks_when_table_intent_is_required_but_missing():
    result = audit.audit_events(
        [
            {"event": "combat", "attacker": "Opponent", "target": "Lorehold"},
            {"event": "spell_cast", "player": "Opponent", "card": "Sol Ring"},
            {"event": "spell_resolved", "player": "Opponent", "card": "Sol Ring"},
            {
                "event": "spell_countered",
                "player": "Opponent",
                "counter": "Flusterstorm",
                "target_controller": "Lorehold",
            },
        ],
        require_table_intent=True,
    )
    assert result["status"] == "blocked"
    assert any(
        finding["code"] == "table_intent_missing"
        for finding in result["findings"]
    )


def test_reviews_high_illegal_cast_pressure():
    result = audit.audit_events(
        [
            {
                "event": "combat",
                "attacker": "Opponent",
                "target": "Lorehold",
                "table_intent_enabled": True,
                "table_intent_scores": [{"target": "Lorehold", "score": 10}],
            },
            {"event": "spell_cast", "player": "Opponent", "card": "Sol Ring"},
            {"event": "spell_resolved", "player": "Opponent", "card": "Sol Ring"},
            {"event": "cast_illegal", "player": "Opponent", "card": "Commander"},
            {"event": "cast_illegal", "player": "Opponent", "card": "Commander"},
            {"event": "cast_illegal", "player": "Opponent", "card": "Commander"},
            {
                "event": "spell_countered",
                "player": "Opponent",
                "counter": "Flusterstorm",
                "target_controller": "Lorehold",
            },
        ],
        require_table_intent=True,
    )
    assert result["status"] == "review_required"
    assert any(
        finding["code"] == "opponent_illegal_cast_pressure_high"
        for finding in result["findings"]
    )


def test_counts_opponent_spell_trigger_as_interaction():
    result = audit.audit_events(
        [
            {
                "event": "combat",
                "attacker": "Opponent",
                "target": "Lorehold",
                "table_intent_enabled": True,
                "table_intent_scores": [{"target": "Lorehold", "score": 10}],
            },
            {"event": "spell_cast", "player": "Opponent", "card": "Rhystic Study"},
            {"event": "spell_resolved", "player": "Opponent", "card": "Rhystic Study"},
            {
                "event": "trigger_resolved",
                "player": "Opponent",
                "card": "Rhystic Study",
                "trigger": "opponent_spell",
                "trigger_spell": "The One Ring",
            },
        ],
        require_table_intent=True,
    )
    assert result["status"] == "pass"
    assert result["opponent_interaction_events"] == 1
    assert result["opponent_trigger_interaction_events"] == 1


def test_passes_without_interaction_when_opponents_show_agency_and_win():
    result = audit.audit_events(
        [
            {
                "event": "combat",
                "attacker": "Opponent",
                "target": "Lorehold",
                "table_intent_enabled": True,
                "table_intent_scores": [{"target": "Lorehold", "score": 10}],
            },
            {"event": "spell_cast", "player": "Opponent", "card": "Creature"},
            {"event": "creature_cast", "player": "Opponent", "card": "Creature"},
            {"event": "game_won", "player": "Opponent"},
        ],
        require_table_intent=True,
    )
    assert result["status"] == "pass"
    assert result["opponent_interaction_events"] == 0
    assert result["opponent_wins"] == 1


def main():
    for test in (
        test_passes_when_table_intent_and_opponent_actions_exist,
        test_blocks_when_table_intent_is_required_but_missing,
        test_reviews_high_illegal_cast_pressure,
        test_counts_opponent_spell_trigger_as_interaction,
        test_passes_without_interaction_when_opponents_show_agency_and_win,
    ):
        test()
        print(f"PASS {test.__name__}")


if __name__ == "__main__":
    main()
