#!/usr/bin/env python3
"""Regression tests for replay_decision_auditor scope/status wording."""

from __future__ import annotations

import importlib.util
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("replay_decision_auditor.py")
spec = importlib.util.spec_from_file_location(
    "replay_decision_auditor_under_test",
    MODULE_PATH,
)
auditor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(auditor)


def test_clean_status_names_turn_invariants_not_full_replay_trust():
    summary = auditor.audit_summary(
        turn_findings=[],
        decision_findings=[],
        event_count=12,
        decision_count=3,
    )

    assert summary["status"] == "turn_invariants_clean"
    assert summary["status_scope"] == "turn_and_decision_trace_invariants"
    assert summary["structured_trace_usable"] is True
    assert summary["human_replay_complete"] == "not_evaluated_by_replay_decision_auditor"
    assert summary["rules_interaction_trusted"] == "not_evaluated_by_replay_decision_auditor"


def test_markdown_report_declares_not_evaluated_layers():
    markdown = auditor.render_report(
        deck_id=6,
        baseline_id=0,
        baseline_findings=[],
        turn_findings=[],
        decision_findings=[],
        event_count=12,
        decision_count=3,
        replay_files=[],
    )

    assert "- status: turn_invariants_clean" in markdown
    assert "- status_scope: turn_and_decision_trace_invariants" in markdown
    assert "- human_replay_complete: not_evaluated_by_replay_decision_auditor" in markdown
    assert "- rules_interaction_trusted: not_evaluated_by_replay_decision_auditor" in markdown
    assert "does not prove human replay completeness or full rules-interaction trust" in markdown


def test_low_power_removal_with_best_target_score_is_not_flagged():
    findings = auditor.audit_turn_events(
        [
            {
                "event": "removal_resolved",
                "replay_id": "seed_score",
                "turn": 10,
                "player": "Lorehold",
                "target": "Fiend Artisan",
                "target_power": 1,
                "target_is_creature": True,
                "target_effect": "creature",
                "available_targets": 3,
                "target_score": [0, 1, 2, 1, 1],
                "target_options": [
                    {
                        "target": "Fiend Artisan",
                        "target_power": 1,
                        "target_score": [0, 1, 2, 1, 1],
                    },
                    {
                        "target": "Token",
                        "target_power": 1,
                        "target_score": [0, 1, 0, 1, 1],
                    },
                    {
                        "target": "Mana Dork",
                        "target_power": 1,
                        "target_score": [0, 1, 1, 1, 1],
                    },
                ],
            }
        ]
    )

    assert findings == []


def test_low_power_removal_with_better_target_score_is_still_flagged():
    findings = auditor.audit_turn_events(
        [
            {
                "event": "removal_resolved",
                "replay_id": "seed_score",
                "turn": 10,
                "player": "Lorehold",
                "target": "Token",
                "target_power": 1,
                "target_is_creature": True,
                "target_effect": "creature",
                "available_targets": 3,
                "target_score": [0, 1, 0, 1, 1],
                "target_options": [
                    {
                        "target": "Fiend Artisan",
                        "target_power": 1,
                        "target_score": [0, 1, 2, 1, 1],
                    },
                    {
                        "target": "Token",
                        "target_power": 1,
                        "target_score": [0, 1, 0, 1, 1],
                    },
                ],
            }
        ]
    )

    assert len(findings) == 1
    assert findings[0]["finding"] == "Removal hit a low-power target while multiple targets were available."


if __name__ == "__main__":
    tests = [
        test_clean_status_names_turn_invariants_not_full_replay_trust,
        test_markdown_report_declares_not_evaluated_layers,
        test_low_power_removal_with_best_target_score_is_not_flagged,
        test_low_power_removal_with_better_target_score_is_still_flagged,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
