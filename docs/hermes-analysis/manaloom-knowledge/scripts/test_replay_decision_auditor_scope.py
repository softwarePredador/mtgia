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


def test_cleanup_allows_no_maximum_hand_size_permanent():
    findings = auditor.audit_turn_events([
        {
            "event": "turn_end",
            "replay_id": "seed_hand",
            "turn": 7,
            "player": "Lorehold",
            "hand": 8,
            "discarded": 0,
            "board_snapshot": [
                {"name": "Library of Leng", "type_line": "Artifact"},
            ],
        }
    ])

    assert findings == []


def test_cleanup_flags_large_hand_without_no_maximum_hand_size_permanent():
    findings = auditor.audit_turn_events([
        {
            "event": "turn_end",
            "replay_id": "seed_hand",
            "turn": 7,
            "player": "Lorehold",
            "hand": 8,
            "discarded": 0,
            "board_snapshot": [
                {"name": "Lorehold, the Historian", "type_line": "Legendary Creature"},
            ],
        }
    ])

    assert len(findings) == 1
    assert findings[0]["finding"] == "Cleanup ended with hand size 8 > 7."


def test_multi_defender_combat_uses_target_group_power_for_lethal_checks():
    findings = auditor.audit_turn_events([
        {
            "event": "combat",
            "replay_id": "seed_multi",
            "turn": 7,
            "attacker": "Lorehold",
            "target": "Primary Defender",
            "attackers": 7,
            "blockers": 0,
            "total_power": 23,
            "target_group_power": 11,
            "target_life_before": 18,
            "target_reason": "table_intent_table_threat",
            "attack_groups": [
                {"target": "Primary Defender", "group_power": 11},
                {"target": "Second Defender", "group_power": 6},
                {"target": "Third Defender", "group_power": 6},
            ],
        },
        {
            "event": "combat_result",
            "replay_id": "seed_multi",
            "turn": 7,
            "attacker": "Lorehold",
            "target": "Primary Defender",
            "damage_to_player": 11,
            "target_dead": False,
        },
    ])

    assert findings == []


def test_multi_defender_combat_flags_false_lethal_label():
    findings = auditor.audit_turn_events([
        {
            "event": "combat",
            "replay_id": "seed_multi",
            "turn": 7,
            "attacker": "Lorehold",
            "target": "Primary Defender",
            "attackers": 7,
            "blockers": 0,
            "total_power": 23,
            "target_group_power": 11,
            "target_life_before": 18,
            "target_reason": "table_intent_lethal",
            "attack_groups": [
                {"target": "Primary Defender", "group_power": 11},
                {"target": "Second Defender", "group_power": 6},
                {"target": "Third Defender", "group_power": 6},
            ],
        }
    ])

    assert [finding["finding"] for finding in findings] == [
        "Attack was tagged as lethal using only 11 assigned power against 18 life."
    ]


def test_table_intent_lethal_label_is_accepted_when_assigned_power_is_lethal():
    findings = auditor.audit_turn_events([
        {
            "event": "combat",
            "replay_id": "seed_lethal",
            "turn": 9,
            "attacker": "Lorehold",
            "target": "Defender",
            "attackers": 1,
            "blockers": 0,
            "total_power": 5,
            "target_life_before": 5,
            "target_reason": "table_intent_lethal",
        },
        {
            "event": "combat_result",
            "replay_id": "seed_lethal",
            "turn": 9,
            "attacker": "Lorehold",
            "target": "Defender",
            "damage_to_player": 5,
            "target_life_before": 5,
            "target_dead": True,
        },
    ])

    assert findings == []


def test_selective_wipe_allows_more_retained_than_destroyed_when_accounted():
    findings = auditor.audit_turn_events([
        {
            "event": "board_wipe_resolved",
            "replay_id": "seed_wipe",
            "turn": 8,
            "player": "Lorehold",
            "destroyed": 2,
            "protected": 3,
            "nonland_permanents_seen": 5,
            "choices": [
                {
                    "controller": "Lorehold",
                    "choice_type": "artifact",
                    "name": "Sol Ring",
                    "type_line": "Artifact",
                },
                {
                    "controller": "Lorehold",
                    "choice_type": "creature",
                    "name": "Commander",
                    "type_line": "Legendary Creature",
                },
                {
                    "controller": "Opponent",
                    "choice_type": "enchantment",
                    "name": "Rhystic Study",
                    "type_line": "Enchantment",
                },
            ],
        }
    ])

    assert findings == []


def test_general_wipe_protection_count_does_not_require_selective_choices():
    findings = auditor.audit_turn_events([
        {
            "event": "board_wipe_resolved",
            "replay_id": "seed_wipe",
            "turn": 8,
            "player": "Lorehold",
            "destroyed": 2,
            "protected": 3,
            "unprotected_seen": 2,
        }
    ])

    assert findings == []


def test_selective_wipe_flags_choice_type_mismatch():
    findings = auditor.audit_turn_events([
        {
            "event": "board_wipe_resolved",
            "replay_id": "seed_wipe",
            "turn": 8,
            "player": "Lorehold",
            "destroyed": 1,
            "protected": 1,
            "nonland_permanents_seen": 2,
            "choices": [
                {
                    "controller": "Opponent",
                    "choice_type": "artifact",
                    "name": "Delighted Halfling",
                    "type_line": "Creature - Halfling Citizen",
                }
            ],
        }
    ])

    assert [finding["finding"] for finding in findings] == [
        "Selective wipe retained Delighted Halfling as artifact, but its emitted type line is `Creature - Halfling Citizen`."
    ]


def test_selective_wipe_allows_one_multitype_permanent_in_multiple_slots():
    findings = auditor.audit_turn_events([
        {
            "event": "board_wipe_resolved",
            "replay_id": "seed_multitype_wipe",
            "turn": 8,
            "player": "Lorehold",
            "destroyed": 0,
            "protected": 1,
            "nonland_permanents_seen": 1,
            "choices": [
                {
                    "controller": "Lorehold",
                    "choice_type": "artifact",
                    "name": "Artifact Creature",
                    "type_line": "Artifact Creature — Golem",
                },
                {
                    "controller": "Lorehold",
                    "choice_type": "creature",
                    "name": "Artifact Creature",
                    "type_line": "Artifact Creature — Golem",
                },
            ],
        }
    ])

    assert findings == []


def test_selective_wipe_counts_same_name_objects_by_object_id():
    findings = auditor.audit_turn_events([
        {
            "event": "board_wipe_resolved",
            "replay_id": "seed_same_name_objects",
            "turn": 8,
            "player": "Lorehold",
            "destroyed": 0,
            "protected": 2,
            "nonland_permanents_seen": 2,
            "object_identity_scope": "tragic_arrogance_resolution_v1",
            "protected_object_ids": ["tragic:1:battlefield:0", "tragic:1:battlefield:1"],
            "sacrificed_object_ids": [],
            "sacrificed_cards": [],
            "choices": [
                {
                    "controller": "Opponent",
                    "choice_type": "artifact",
                    "name": "Same Printed Name",
                    "object_id": "tragic:1:battlefield:0",
                    "type_line": "Artifact",
                },
                {
                    "controller": "Opponent",
                    "choice_type": "creature",
                    "name": "Same Printed Name",
                    "object_id": "tragic:1:battlefield:1",
                    "type_line": "Creature — Shapeshifter",
                },
            ],
        }
    ])

    assert findings == []


def test_selective_wipe_flags_object_id_reconciliation_mismatch():
    findings = auditor.audit_turn_events([
        {
            "event": "board_wipe_resolved",
            "replay_id": "seed_bad_object_reconciliation",
            "turn": 8,
            "player": "Lorehold",
            "destroyed": 1,
            "protected": 1,
            "nonland_permanents_seen": 2,
            "object_identity_scope": "tragic_arrogance_resolution_v1",
            "protected_object_ids": ["tragic:1:battlefield:0"],
            "sacrificed_object_ids": ["tragic:1:battlefield:0"],
            "sacrificed_cards": [
                {
                    "controller": "Opponent",
                    "name": "Same Object",
                    "object_id": "tragic:1:battlefield:0",
                    "type_line": "Creature",
                }
            ],
            "choices": [
                {
                    "controller": "Opponent",
                    "choice_type": "creature",
                    "name": "Same Object",
                    "object_id": "tragic:1:battlefield:0",
                    "type_line": "Creature",
                }
            ],
        }
    ])

    assert any("both retained and sacrificed" in finding["finding"] for finding in findings)
    assert any("object ids accounted for 1 of 2" in finding["finding"] for finding in findings)


if __name__ == "__main__":
    tests = [
        test_clean_status_names_turn_invariants_not_full_replay_trust,
        test_markdown_report_declares_not_evaluated_layers,
        test_low_power_removal_with_best_target_score_is_not_flagged,
        test_low_power_removal_with_better_target_score_is_still_flagged,
        test_cleanup_allows_no_maximum_hand_size_permanent,
        test_cleanup_flags_large_hand_without_no_maximum_hand_size_permanent,
        test_multi_defender_combat_uses_target_group_power_for_lethal_checks,
        test_multi_defender_combat_flags_false_lethal_label,
        test_table_intent_lethal_label_is_accepted_when_assigned_power_is_lethal,
        test_selective_wipe_allows_more_retained_than_destroyed_when_accounted,
        test_general_wipe_protection_count_does_not_require_selective_choices,
        test_selective_wipe_flags_choice_type_mismatch,
        test_selective_wipe_allows_one_multitype_permanent_in_multiple_slots,
        test_selective_wipe_counts_same_name_objects_by_object_id,
        test_selective_wipe_flags_object_id_reconciliation_mismatch,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
