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


def test_critic_flags_counter_spell_without_stack_target():
    result = critic.criticize_actions([
        {
            "event": "end_step_instant",
            "replay_id": "r-counter",
            "turn": 1,
            "player": "Opponent",
            "card": "Mental Misstep",
            "effect": "counter",
            "type_line": "Instant",
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
        {
            "event": "spell_resolved",
            "replay_id": "r-counter",
            "turn": 1,
            "player": "Opponent",
            "card": "Mental Misstep",
            "effect": "counter",
            "type_line": "Instant",
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
    ])

    codes = {finding["code"] for finding in result["findings"]}

    assert "counter_without_stack_target" in codes
    assert "counter_resolved_as_normal_spell" in codes


def test_critic_accepts_counter_with_target_stack_object_and_result():
    result = critic.criticize_actions([
        {
            "event": "spell_countered",
            "replay_id": "r-counter-ok",
            "turn": 2,
            "player": "Responder",
            "counter": "Counterspell",
            "target": "Approach of the Second Sun",
            "stack_object": "Approach of the Second Sun",
            "result": "countered",
            "phase": "precombat_main",
            "priority_window": "stack_response",
            "effect": "counter",
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
    ])

    assert result["summary"]["findings"] == 0


def test_critic_flags_counter_without_priority_window():
    result = critic.criticize_actions([
        {
            "event": "spell_countered",
            "replay_id": "r-counter-no-window",
            "turn": 2,
            "player": "Responder",
            "counter": "Counterspell",
            "target": "Approach of the Second Sun",
            "stack_object": "Approach of the Second Sun",
            "result": "countered",
            "effect": "counter",
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
    ])

    codes = {finding["code"] for finding in result["findings"]}

    assert "counter_without_priority_window" in codes


def test_critic_accepts_redirect_with_target_change_provenance():
    result = critic.criticize_actions([
        {
            "event": "redirect_removal_resolved",
            "replay_id": "r-redirect-ok",
            "turn": 4,
            "player": "Responder",
            "card": "Deflecting Swat",
            "redirected_object": "Doom Blade",
            "old_target": "Protected Target",
            "new_target": "Caster Backup",
            "target_type": "creature",
            "legal_redirect_opportunity": True,
            "target_change_applied": True,
            "result": "redirected",
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
    ])

    assert result["summary"]["findings"] == 0


def test_critic_flags_redirect_without_target_change_provenance():
    result = critic.criticize_actions([
        {
            "event": "redirect_removal_resolved",
            "replay_id": "r-redirect-bad",
            "turn": 4,
            "player": "Responder",
            "card": "Deflecting Swat",
            "redirected_object": "Doom Blade",
            "old_target": "Protected Target",
            "legal_redirect_opportunity": True,
            "target_change_applied": False,
            "result": "redirected",
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
    ])

    codes = {finding["code"] for finding in result["findings"]}

    assert "redirect_without_target_change_provenance" in codes


def test_critic_flags_targeted_removal_without_declared_target():
    result = critic.criticize_actions([
        {
            "event": "spell_cast",
            "replay_id": "r-removal-bad",
            "turn": 3,
            "player": "Caster",
            "card": "Swords to Plowshares",
            "effect": "remove_creature",
            "type_line": "Instant",
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
    ])

    codes = {finding["code"] for finding in result["findings"]}

    assert "targeted_removal_without_declared_target" in codes


def test_critic_accepts_targeted_removal_with_declared_target():
    result = critic.criticize_actions(
        [
            {
                "event": "spell_cast",
                "replay_id": "r-removal-ok",
                "turn": 3,
                "player": "Caster",
                "card": "Swords to Plowshares",
                "effect": "remove_creature",
                "type_line": "Instant",
                "target": "Threat Creature",
                "targets": [{"target": "Threat Creature"}],
                "rule_source": "curated",
                "rule_review_status": "verified",
            },
        ],
        [
            {
                "decision_id": "d-removal-ok",
                "turn": 3,
                "player": "Caster",
                "chosen_option": {"card": "Swords to Plowshares"},
                "score_components": {"target_priority": 1},
            },
        ],
    )

    assert result["summary"]["findings"] == 0


def test_critic_tracks_flashback_cast_before_resolution():
    result = critic.criticize_actions([
        {
            "event": "flashback_cast",
            "replay_id": "r-flashback-ok",
            "turn": 6,
            "phase": "precombat_main",
            "player": "Lorehold",
            "card": "Swords to Plowshares",
            "effect": "remove_creature",
            "type_line": "Instant",
            "target": "Threat Creature",
            "targets": [{"target": "Threat Creature"}],
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
        {
            "event": "spell_resolved",
            "replay_id": "r-flashback-ok",
            "turn": 6,
            "phase": "precombat_main",
            "player": "Lorehold",
            "card": "Swords to Plowshares",
            "effect": "remove_creature",
            "type_line": "Instant",
            "resolved_from_stack": True,
            "stack_depth": 1,
            "source_zone": "graveyard",
            "from_zone": "graveyard",
            "to_zone": "exile",
            "target": "Threat Creature",
            "targets": [{"target": "Threat Creature"}],
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
    ])

    codes = {finding["code"] for finding in result["findings"]}

    assert "resolve_without_cast" not in codes
    assert "targeted_removal_without_declared_target" not in codes


def test_critic_does_not_consume_original_cast_for_spell_copy_resolution():
    result = critic.criticize_actions([
        {
            "event": "spell_cast",
            "replay_id": "r-copy-ok",
            "turn": 8,
            "phase": "precombat_main",
            "player": "Lorehold",
            "card": "Fateful Showdown",
            "effect": "draw_cards",
            "type_line": "Instant",
            "rule_source": "curated",
            "rule_review_status": "verified",
            "cast_pipeline": "601.2_minimal",
        },
        {
            "event": "spell_resolved",
            "replay_id": "r-copy-ok",
            "turn": 8,
            "phase": "precombat_main",
            "player": "Lorehold",
            "card": "Fateful Showdown",
            "effect": "draw_cards",
            "type_line": "Instant",
            "rule_source": "curated",
            "rule_review_status": "verified",
            "role": "copy",
            "source_zone": "stack_copy",
            "from_zone": "stack",
            "to_zone": "ceased_to_exist",
            "destination": "ceased_to_exist",
            "zone_after": "ceased_to_exist",
            "result": "resolved",
            "resolved_from_stack": True,
            "stack_depth": 2,
            "priority_window": "stack_resolution",
            "cast_pipeline": "spell_copy",
            "locked_cost": {"copied_spell": True},
        },
        {
            "event": "spell_resolved",
            "replay_id": "r-copy-ok",
            "turn": 8,
            "phase": "precombat_main",
            "player": "Lorehold",
            "card": "Fateful Showdown",
            "effect": "draw_cards",
            "type_line": "Instant",
            "rule_source": "curated",
            "rule_review_status": "verified",
            "role": "normal",
            "source_zone": "hand",
            "from_zone": "hand",
            "to_zone": "graveyard",
            "destination": "graveyard",
            "zone_after": "graveyard",
            "result": "resolved",
            "resolved_from_stack": True,
            "stack_depth": 1,
            "priority_window": "stack_resolution",
            "cast_pipeline": "601.2_minimal",
            "locked_cost": {"generic": 2, "colored": {"red": 2}},
        },
    ])

    codes = {finding["code"] for finding in result["findings"]}

    assert "resolve_without_cast" not in codes


def test_critic_does_not_consume_decision_trace_from_wrong_phase():
    result = critic.criticize_actions(
        [
            {
                "event": "miracle_cast",
                "replay_id": "r-same-card",
                "turn": 6,
                "phase": "draw_step",
                "player": "Lorehold",
                "card": "Silence",
                "effect": "silence_spell",
                "rule_source": "curated",
                "rule_review_status": "verified",
            },
            {
                "event": "spell_cast",
                "replay_id": "r-same-card",
                "turn": 6,
                "phase": "precombat_main",
                "player": "Lorehold",
                "card": "Silence",
                "effect": "silence_spell",
                "rule_source": "curated",
                "rule_review_status": "verified",
            },
        ],
        [
            {
                "decision_id": "decision-silence-main",
                "turn": 6,
                "phase": "precombat_main",
                "player": "Lorehold",
                "chosen_option": {"card": "Silence"},
                "score_components": {"threat_score": 50},
            },
        ],
    )

    assert result["summary"]["findings"] == 0
    spell_rows = [
        row
        for row in result["actions"]
        if row["event"] == "spell_cast" and row["label"] == "Silence"
    ]
    assert spell_rows
    assert "decision=decision-silence-main" in spell_rows[0]["evidence"]


def test_critic_flags_spell_resolved_without_resolution_provenance():
    result = critic.criticize_actions([
        {
            "event": "spell_resolved",
            "replay_id": "r-resolution-bad",
            "turn": 3,
            "player": "Caster",
            "card": "Divination",
            "effect": "draw_cards",
            "type_line": "Sorcery",
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
    ])

    codes = {finding["code"] for finding in result["findings"]}

    assert "spell_resolved_without_resolution_provenance" in codes


def test_critic_accepts_spell_resolved_with_resolution_provenance():
    result = critic.criticize_actions(
        [
            {
                "event": "spell_cast",
                "replay_id": "r-resolution-ok",
                "turn": 3,
                "phase": "precombat_main",
                "player": "Caster",
                "card": "Divination",
                "effect": "draw_cards",
                "type_line": "Sorcery",
                "rule_source": "curated",
                "rule_review_status": "verified",
            },
            {
                "event": "spell_resolved",
                "replay_id": "r-resolution-ok",
                "turn": 3,
                "phase": "precombat_main",
                "priority_window": "stack_resolution",
                "player": "Caster",
                "card": "Divination",
                "effect": "draw_cards",
                "type_line": "Sorcery",
                "source_zone": "hand",
                "from_zone": "hand",
                "to_zone": "graveyard",
                "destination": "graveyard",
                "zone_after": "graveyard",
                "stack_depth": 1,
                "stack_object": "Divination",
                "cast_pipeline": "601.2_minimal",
                "locked_cost": {"generic": 2, "colored": {"blue": 1}},
                "resolved_from_stack": True,
                "result": "resolved",
                "rule_source": "curated",
                "rule_review_status": "verified",
            },
        ],
        [
            {
                "decision_id": "d-resolution-ok",
                "turn": 3,
                "player": "Caster",
                "chosen_option": {"card": "Divination"},
                "score_components": {"cast_priority": 1},
            },
        ],
    )

    assert result["summary"]["findings"] == 0


def test_critic_flags_trigger_without_auditable_stack_metadata():
    result = critic.criticize_actions([
        {
            "event": "trigger_put_on_stack",
            "replay_id": "r-trigger-bad",
            "turn": 2,
            "player": "Lorehold",
        },
    ])

    codes = {finding["code"] for finding in result["findings"]}

    assert "trigger_without_auditable_stack_metadata" in codes


def test_critic_accepts_trigger_with_source_trigger_and_stack_order():
    result = critic.criticize_actions([
        {
            "event": "trigger_put_on_stack",
            "replay_id": "r-trigger-ok",
            "turn": 2,
            "player": "Lorehold",
            "card": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            "trigger": "spell_cast",
            "timestamp": 4,
        },
    ])

    assert result["summary"]["findings"] == 0
    assert result["actions"][0]["evidence"] != "-"


def test_critic_flags_replacement_without_causal_metadata():
    result = critic.criticize_actions([
        {
            "event": "replacement_applied",
            "replay_id": "r-replacement-bad",
            "turn": 3,
            "affected_player": "Commander Player",
            "card": "Test Commander",
            "event_type": "zone_change",
            "from_zone": "battlefield",
            "to_zone": "command_zone",
            "replacements": ["commander_to_command_zone"],
            "replacement_order": ["commander_to_command_zone"],
        },
    ])

    codes = {finding["code"] for finding in result["findings"]}

    assert "replacement_without_causal_metadata" in codes


def test_critic_accepts_replacement_with_causal_metadata():
    result = critic.criticize_actions([
        {
            "event": "replacement_applied",
            "replay_id": "r-replacement-ok",
            "turn": 3,
            "affected_player": "Commander Player",
            "card": "Test Commander",
            "event_type": "zone_change",
            "from_zone": "battlefield",
            "to_zone": "command_zone",
            "source": "Swords to Plowshares",
            "reason": "removal",
            "causal_event": {
                "event_type": "zone_change",
                "source": "Swords to Plowshares",
                "reason": "removal",
                "from_zone": "battlefield",
                "to_zone": "command_zone",
                "replacements": ["commander_to_command_zone"],
            },
            "replacements": ["commander_to_command_zone"],
            "replacement_order": ["commander_to_command_zone"],
        },
    ])

    assert result["summary"]["findings"] == 0
    assert "source=Swords to Plowshares" in result["actions"][0]["evidence"]


def test_critic_accepts_life_replacement_with_affected_player_metadata():
    result = critic.criticize_actions([
        {
            "event": "replacement_applied",
            "replay_id": "r-replacement-life-ok",
            "turn": 4,
            "affected_player": "Protected Player",
            "event_type": "life_change",
            "amount": 0,
            "delta": 0,
            "original_amount": 0,
            "final_amount": 0,
            "original_delta": 4,
            "final_delta": 0,
            "reason": "prevention:life_total_cant_change",
            "replacement_rule_source": "Teferi's Protection",
            "replacement_rule_sources": ["Teferi's Protection"],
            "causal_event": {
                "event_type": "life_change",
                "reason": "prevention:life_total_cant_change",
                "source": "Teferi's Protection",
                "original_delta": 4,
                "final_delta": 0,
                "replacements": ["life_total_cant_change"],
                "replacement_rule_sources": ["Teferi's Protection"],
            },
            "prevented": True,
            "replacements": ["life_total_cant_change"],
            "replacement_order": ["life_total_cant_change"],
        },
    ])

    assert result["summary"]["findings"] == 0
    assert "affected_player=Protected Player" in result["actions"][0]["evidence"]
    assert "replacement_rule_source=Teferi's Protection" in result["actions"][0]["evidence"]


def test_critic_flags_life_replacement_without_original_final_metadata():
    result = critic.criticize_actions([
        {
            "event": "replacement_applied",
            "replay_id": "r-replacement-life-bad",
            "turn": 4,
            "affected_player": "Protected Player",
            "event_type": "damage",
            "amount": 0,
            "delta": 0,
            "reason": "prevention:life_total_cant_change",
            "causal_event": {
                "event_type": "damage",
                "reason": "prevention:life_total_cant_change",
                "replacements": ["life_total_cant_change"],
            },
            "prevented": True,
            "replacements": ["life_total_cant_change"],
            "replacement_order": ["life_total_cant_change"],
        },
    ])

    codes = {finding["code"] for finding in result["findings"]}

    assert "replacement_without_zone_or_object_metadata" in codes


def test_critic_accepts_large_hand_with_no_max_hand_size_permanent():
    result = critic.criticize_actions([
        {
            "event": "turn_end",
            "replay_id": "r-hand-ok",
            "turn": 7,
            "player": "Lorehold",
            "hand": 8,
            "board": 2,
            "graveyard": 3,
            "board_snapshot": [
                {"name": "Library of Leng", "type_line": "Artifact"},
                {"name": "Lorehold, the Historian", "type_line": "Legendary Creature"},
            ],
        },
    ])

    codes = {finding["code"] for finding in result["findings"]}

    assert "cleanup_hand_size" not in codes


def test_critic_flags_large_hand_without_no_max_hand_size_permanent():
    result = critic.criticize_actions([
        {
            "event": "turn_end",
            "replay_id": "r-hand-bad",
            "turn": 7,
            "player": "Lorehold",
            "hand": 8,
            "board": 1,
            "graveyard": 3,
            "board_snapshot": [
                {"name": "Lorehold, the Historian", "type_line": "Legendary Creature"},
            ],
        },
    ])

    codes = {finding["code"] for finding in result["findings"]}

    assert "cleanup_hand_size" in codes


def test_critic_reports_event_contract_denominators():
    result = critic.criticize_actions([
        {"event": "priority_pass", "replay_id": "r-contract", "turn": 1, "player": "A"},
        {"event": "spell_cast", "replay_id": "r-contract", "turn": 1, "player": "A", "card": "Bolt"},
        {"event": "damage_resolved", "replay_id": "r-contract", "turn": 1, "player": "A"},
        {"event": "activated_ability_skipped", "replay_id": "r-contract", "turn": 1, "player": "A"},
        {"event": "future_new_event", "replay_id": "r-contract", "turn": 1, "player": "A"},
    ])

    contract = result["summary"]["event_contract"]

    assert contract["events_total"] == 5
    assert contract["event_class_counts"]["action_audited"] == 1
    assert contract["event_class_counts"]["technical"] == 1
    assert contract["event_class_counts"]["renderer_only"] == 1
    assert contract["event_class_counts"]["ignored_with_reason"] == 1
    assert contract["events_unclassified"] == 1
    assert contract["event_types_unclassified"] == ["future_new_event"]


def test_critic_classifies_flashback_and_land_tax_auxiliary_events():
    result = critic.criticize_actions([
        {"event": "adventure_exiled", "replay_id": "r-contract", "turn": 1, "player": "A", "card": "Adventure Spell"},
        {"event": "flashback_exiled", "replay_id": "r-contract", "turn": 1, "player": "A", "card": "Past in Flames"},
        {"event": "graveyard_flashback_granted", "replay_id": "r-contract", "turn": 1, "player": "A", "card": "Past in Flames"},
        {"event": "land_tax_trigger_skipped", "replay_id": "r-contract", "turn": 1, "player": "A", "card": "Land Tax"},
    ])

    contract = result["summary"]["event_contract"]

    assert contract["events_unclassified"] == 0
    assert contract["event_types_unclassified"] == []
    assert contract["event_class_counts"]["technical"] == 2
    assert contract["event_class_counts"]["strategy_signal"] == 1
    assert contract["event_class_counts"]["ignored_with_reason"] == 1


if __name__ == "__main__":
    tests = [
        test_critic_flags_action_level_findings,
        test_critic_renders_markdown_ledger,
        test_critic_flags_counter_spell_without_stack_target,
        test_critic_accepts_counter_with_target_stack_object_and_result,
        test_critic_flags_counter_without_priority_window,
        test_critic_accepts_redirect_with_target_change_provenance,
        test_critic_flags_redirect_without_target_change_provenance,
        test_critic_flags_trigger_without_auditable_stack_metadata,
        test_critic_accepts_trigger_with_source_trigger_and_stack_order,
        test_critic_flags_replacement_without_causal_metadata,
        test_critic_accepts_replacement_with_causal_metadata,
        test_critic_accepts_life_replacement_with_affected_player_metadata,
        test_critic_flags_life_replacement_without_original_final_metadata,
        test_critic_accepts_large_hand_with_no_max_hand_size_permanent,
        test_critic_flags_large_hand_without_no_max_hand_size_permanent,
        test_critic_tracks_flashback_cast_before_resolution,
        test_critic_does_not_consume_original_cast_for_spell_copy_resolution,
        test_critic_does_not_consume_decision_trace_from_wrong_phase,
        test_critic_flags_spell_resolved_without_resolution_provenance,
        test_critic_accepts_spell_resolved_with_resolution_provenance,
        test_critic_reports_event_contract_denominators,
        test_critic_classifies_flashback_and_land_tax_auxiliary_events,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
