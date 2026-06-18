#!/usr/bin/env python3
"""Regression tests for battle_action_critic."""

from __future__ import annotations

import importlib.util
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("battle_action_critic.py")
spec = importlib.util.spec_from_file_location("battle_action_critic_under_test", MODULE_PATH)
critic = importlib.util.module_from_spec(spec)
spec.loader.exec_module(critic)


def test_critic_flags_action_level_findings():
    events = [
        {"event": "turn_start", "replay_id": "r1", "turn": 1, "player": "A", "life": 40, "hand": 7},
        {"event": "turn_start", "replay_id": "r1", "turn": 1, "player": "B", "life": 40, "hand": 7},
        {
            "event": "land_played",
            "replay_id": "r1",
            "turn": 1,
            "player": "A",
            "card": "Plains",
            "effect": "land",
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
        {
            "event": "land_played",
            "replay_id": "r1",
            "turn": 1,
            "player": "A",
            "card": "Mountain",
            "effect": "land",
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
        {
            "event": "spell_cast",
            "replay_id": "r1",
            "turn": 1,
            "phase": "precombat_main",
            "player": "A",
            "card": "Review Creature",
            "effect": "creature",
            "type_line": "Creature",
            "rule_source": "generated",
            "rule_review_status": "needs_review",
        },
        {"event": "player_eliminated", "replay_id": "r1", "turn": 2, "player": "B", "reason": "life_zero"},
    ]
    decisions = [
        {
            "decision_id": "d1",
            "turn": 1,
            "player": "A",
            "chosen_option": {"card": "Review Creature"},
            "score_components": {"threat_score": 1},
        }
    ]

    result = critic.criticize_actions(events, decisions)
    codes = {finding["code"] for finding in result["findings"]}

    assert "multiple_land_plays" in codes
    assert "review_rule_used" in codes
    assert "missing_game_won" in codes
    assert result["summary"]["total_actions"] == 7


def test_critic_renders_markdown_ledger():
    result = critic.criticize_actions([
        {"event": "turn_start", "replay_id": "r2", "turn": 1, "player": "A", "life": 40, "hand": 7},
        {
            "event": "land_played",
            "replay_id": "r2",
            "turn": 1,
            "player": "A",
            "card": "Forest",
            "effect": "land",
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
    ])

    markdown = critic.render_markdown(result)

    assert "# Battle Action Critic" in markdown
    assert "Action Ledger" in markdown
    assert "Forest" in markdown


if __name__ == "__main__":
    tests = [
        test_critic_flags_action_level_findings,
        test_critic_renders_markdown_ledger,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
