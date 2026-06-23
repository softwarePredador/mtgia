#!/usr/bin/env python3
"""Regression tests for battle_decision_strategy_auditor."""

from __future__ import annotations

import importlib.util
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("battle_decision_strategy_auditor.py")
spec = importlib.util.spec_from_file_location("battle_decision_strategy_auditor_under_test", MODULE_PATH)
auditor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(auditor)


def test_strategy_auditor_flags_bad_mulligan_keep():
    result = auditor.audit_strategy(
        events=[],
        decisions=[
            {
                "decision_id": "d-mull",
                "decision_type": "mulligan_decision",
                "chosen_option": {"action": "keep", "forced_keep": False},
                "score_components": {"lands": 3, "early_play": None},
                "strategic_principle": "opening_hand_must_have_mana_and_early_plan",
                "heuristic_version": "test",
                "resource_delta": {"mulligans_taken": 0},
                "risk_flags": ["no_early_game_plan"],
                "alternatives_considered": [{"name": "Expensive Spell", "cmc": 8}],
            }
        ],
    )

    codes = {finding["code"] for finding in result["findings"]}
    assert "mulligan_keep_without_early_plan" in codes
    assert result["summary"]["verdict"] == "blocked"


def test_strategy_auditor_flags_forced_keep_after_mana_screw_cap():
    result = auditor.audit_strategy(
        events=[],
        decisions=[
            {
                "decision_id": "decision-000004",
                "decision_type": "mulligan_decision",
                "chosen_option": {
                    "action": "keep",
                    "forced_keep": True,
                    "score": -7.0,
                },
                "score_components": {
                    "lands": 1,
                    "keep": False,
                },
                "strategic_principle": "opening_hand_must_have_mana_and_early_plan",
                "heuristic_version": "test",
                "resource_delta": {"mulligans_taken": 3, "cards_in_hand": 4},
                "risk_flags": [
                    "mana_screw",
                    "forced_keep_after_mulligan_cap",
                ],
                "alternatives_considered": [{"name": "Expensive Spell", "cmc": 8}],
                "reason": "too_few_lands",
            }
        ],
    )

    findings = result["findings"]
    codes = {finding["code"] for finding in findings}

    assert "forced_keep_after_bad_mulligan" in codes
    assert result["summary"]["code_counts"]["forced_keep_after_bad_mulligan"] == 1
    assert result["summary"]["verdict"] == "low_confidence_replay"
    assert result["summary"]["learning_confidence"] == "low_confidence_replay"
    assert result["summary"]["high_confidence_learning_eligible"] is False
    assert result["summary"]["high_confidence_learning_weight"] == 0.0
    assert result["summary"]["review_required_findings"] == 0
    assert result["summary"]["low_confidence_learning_findings"] == 1
    assert result["summary"]["low_confidence_learning_codes"] == ["forced_keep_after_bad_mulligan"]


def test_strategy_auditor_flags_one_shot_mana_without_unlock_signal():
    result = auditor.audit_strategy(
        events=[],
        decisions=[
            {
                "decision_id": "d-petal",
                "decision_type": "cast_spell",
                "chosen_option": {"card": "Lotus Petal", "effect": "ramp_ritual"},
                "score_components": {"role": "ramp"},
                "strategic_principle": "spend_ramp_resource_only_when_it_unlocks_or_accelerates_plan",
                "heuristic_version": "test",
                "resource_delta": {"effect": "ramp_ritual", "one_shot_mana": 1},
                "risk_flags": ["one_shot_mana"],
                "alternatives_considered": [{"card": "Lotus Petal"}],
            }
        ],
    )

    codes = {finding["code"] for finding in result["findings"]}
    assert "ramp_ritual_without_unlock_signal" in codes


def test_strategy_auditor_accepts_one_shot_mana_with_unlock_context():
    result = auditor.audit_strategy(
        events=[],
        decisions=[
            {
                "decision_id": "d-petal-ok",
                "decision_type": "cast_spell",
                "chosen_option": {"card": "Lotus Petal", "effect": "ramp_ritual"},
                "score_components": {
                    "role": "ramp",
                    "unlocks_same_turn_action": 1,
                    "unlock_card": "Talisman of Conviction",
                    "unlock_role": "high_impact_spell",
                    "unlock_reason": "same_turn_castable_spell",
                    "resource_gate": "one_shot_ritual_unlock",
                },
                "strategic_principle": "spend_ramp_resource_only_when_it_unlocks_or_accelerates_plan",
                "heuristic_version": "test",
                "resource_delta": {
                    "effect": "ramp_ritual",
                    "one_shot_mana": 1,
                    "unlock_card": "Talisman of Conviction",
                    "unlock_role": "high_impact_spell",
                    "unlock_reason": "same_turn_castable_spell",
                    "resource_gate": "one_shot_ritual_unlock",
                },
                "risk_flags": ["one_shot_mana"],
                "alternatives_considered": [{"card": "Lotus Petal"}],
                "expected_payoff_reason": "same_turn_castable_spell",
            }
        ],
    )

    assert result["summary"]["findings"] == 0


def test_strategy_auditor_flags_land_cost_without_selection_context():
    result = auditor.audit_strategy(
        events=[
            {
                "event": "additional_cost_paid",
                "player": "Lorehold",
                "card": "Mox Diamond",
                "cost": "discard_land",
                "discarded": "Sacred Foundry",
                "strategic_risk_flags": ["spending_unique_color_land"],
            },
            {
                "event": "additional_cost_paid",
                "player": "Lorehold",
                "card": "Crop Rotation",
                "cost": "sacrifice_land",
                "sacrificed": "Plains",
                "land_options": [{"name": "Plains"}],
                "selection_reason": "prefer_redundant_tapped_basic_land_preserve_unique_colors",
                "strategic_risk_flags": ["spending_last_land"],
            },
        ],
        decisions=[],
    )

    codes = {finding["code"] for finding in result["findings"]}
    assert "resource_cost_without_selection_context" in codes
    assert "spending_unique_color_land" in codes
    assert "spending_last_land" in codes


def test_strategy_auditor_flags_risky_land_ramp_without_payoff_reason():
    result = auditor.audit_strategy(
        events=[],
        decisions=[
            {
                "decision_id": "d-mox-risk",
                "decision_type": "cast_spell",
                "chosen_option": {"card": "Mox Diamond", "effect": "ramp_permanent"},
                "score_components": {
                    "role": "ramp",
                    "requires_discard_land": True,
                    "resource_gate": "land_discard_ramp",
                },
                "strategic_principle": "spend_ramp_resource_only_when_it_unlocks_or_accelerates_plan",
                "heuristic_version": "test",
                "resource_delta": {
                    "effect": "ramp_permanent",
                    "requires_discard_land": True,
                    "resource_gate": "land_discard_ramp",
                    "resource_land": "Plateau",
                },
                "risk_flags": [
                    "requires_land_discard",
                    "spending_last_land",
                    "spending_unique_color_land",
                ],
                "alternatives_considered": [{"card": "Mox Diamond"}],
            }
        ],
    )

    codes = {finding["code"] for finding in result["findings"]}
    assert "resource_risk_without_payoff_reason" in codes


def test_strategy_auditor_ignores_failed_land_cost_when_no_land_exists():
    result = auditor.audit_strategy(
        events=[
            {
                "event": "additional_cost_failed",
                "player": "Lorehold",
                "card": "Crop Rotation",
                "cost": "sacrifice_land",
                "land_options": [],
                "strategic_risk_flags": ["no_land_options"],
            },
        ],
        decisions=[],
    )

    assert result["summary"]["findings"] == 0


def test_strategy_auditor_accepts_last_land_spend_with_commander_payoff():
    result = auditor.audit_strategy(
        events=[
            {
                "event": "additional_cost_paid",
                "player": "Thrasios",
                "turn": 1,
                "card": "Mox Diamond",
                "cost": "discard_land",
                "discarded": "City of Traitors",
                "land_options": [{"name": "City of Traitors"}],
                "selection_reason": "prefer_redundant_tapped_basic_land_preserve_unique_colors",
                "strategic_risk_flags": ["spending_last_land", "spending_unique_color_land"],
            },
            {
                "event": "commander_cast",
                "player": "Thrasios",
                "turn": 1,
                "card": "Thrasios, Triton Hero",
            },
        ],
        decisions=[],
    )

    assert result["summary"]["findings"] == 0


def test_strategy_auditor_accepts_documented_land_discard_unlock_context():
    result = auditor.audit_strategy(
        events=[
            {
                "event": "additional_cost_paid",
                "player": "Tayam",
                "turn": 4,
                "card": "Mox Diamond",
                "cost": "discard_land",
                "discarded": "Overgrown Tomb",
                "land_options": [{"name": "Overgrown Tomb"}],
                "selection_reason": "prefer_redundant_tapped_basic_land_preserve_unique_colors",
                "strategic_risk_flags": ["spending_last_land", "spending_unique_color_land"],
                "resource_gate": "land_discard_ramp",
                "unlock_card": "Tayam, Luminous Enigma",
                "unlock_role": "commander",
                "unlock_reason": "same_turn_commander_cast",
                "unlocks_same_turn_action": True,
            },
        ],
        decisions=[],
    )

    assert result["summary"]["findings"] == 0


def test_strategy_auditor_accepts_land_discard_payoff_after_trigger_window():
    result = auditor.audit_strategy(
        events=[
            {
                "event": "additional_cost_paid",
                "player": "Tayam",
                "turn": 4,
                "card": "Mox Diamond",
                "cost": "discard_land",
                "discarded": "Overgrown Tomb",
                "land_options": [{"name": "Overgrown Tomb"}],
                "selection_reason": "prefer_redundant_tapped_basic_land_preserve_unique_colors",
                "strategic_risk_flags": ["spending_last_land", "spending_unique_color_land"],
            },
            {"event": "trigger_put_on_stack", "player": "Lorehold", "turn": 4, "card": "Esper Sentinel"},
            {"event": "priority_pass", "player": "Tayam", "turn": 4},
            {"event": "priority_pass", "player": "Lorehold", "turn": 4},
            {"event": "priority_pass", "player": "Dargo", "turn": 4},
            {"event": "priority_pass", "player": "Rograkh", "turn": 4},
            {"event": "trigger_resolved", "player": "Lorehold", "turn": 4, "card": "Esper Sentinel"},
            {"event": "cast_announced", "player": "Tayam", "turn": 4, "card": "Tayam, Luminous Enigma"},
            {"event": "cost_paid", "player": "Tayam", "turn": 4, "card": "Tayam, Luminous Enigma"},
            {"event": "commander_cast", "player": "Tayam", "turn": 4, "card": "Tayam, Luminous Enigma"},
        ],
        decisions=[],
    )

    assert result["summary"]["findings"] == 0


def test_strategy_auditor_accepts_documented_land_sacrifice_benefit():
    result = auditor.audit_strategy(
        events=[
            {
                "event": "additional_cost_paid",
                "player": "Tayam",
                "turn": 4,
                "card": "Crop Rotation",
                "cost": "sacrifice_land",
                "sacrificed": "Dryad Arbor",
                "land_options": [{"name": "Dryad Arbor"}],
                "land_ramp_target_options": [
                    {
                        "name": "Ancient Tomb",
                        "high_value_target": True,
                        "estimated_mana_value": 2,
                        "enters_tapped": False,
                    },
                ],
                "selection_reason": "prefer_redundant_tapped_basic_land_preserve_unique_colors",
                "strategic_risk_flags": ["spending_last_land", "spending_unique_color_land"],
                "strategic_benefit_reason": "high_value_land_target",
            },
        ],
        decisions=[],
    )

    assert result["summary"]["findings"] == 0


def test_strategy_auditor_still_blocks_last_land_spend_without_payoff():
    result = auditor.audit_strategy(
        events=[
            {
                "event": "additional_cost_paid",
                "player": "Dargo",
                "turn": 1,
                "card": "Mox Diamond",
                "cost": "discard_land",
                "discarded": "Exotic Orchard",
                "land_options": [{"name": "Exotic Orchard"}],
                "selection_reason": "prefer_redundant_tapped_basic_land_preserve_unique_colors",
                "strategic_risk_flags": ["spending_last_land", "spending_unique_color_land"],
            },
            {
                "event": "spell_cast",
                "player": "Dargo",
                "turn": 1,
                "card": "Infernal Plunge",
                "effect": "ramp_permanent",
            },
        ],
        decisions=[],
    )

    codes = {finding["code"] for finding in result["findings"]}
    assert "spending_last_land" in codes
    assert "spending_unique_color_land" in codes


def test_strategy_auditor_flags_unjustified_tutor_and_wipe_wheel():
    result = auditor.audit_strategy(
        events=[],
        decisions=[
            {
                "decision_id": "d-tutor",
                "decision_type": "tutor",
                "chosen_option": {"action": "no_target"},
                "score_components": {"target_type": "any", "candidate_count": 0},
                "strategic_principle": "tutor_for_mana_interaction_engine_or_wincon_by_game_state",
                "heuristic_version": "test",
                "resource_delta": {"target_type": "any"},
                "risk_flags": ["no_tutor_target"],
                "alternatives_considered": [],
            },
            {
                "decision_id": "d-wipe",
                "decision_type": "board_wipe",
                "chosen_option": {"card": "Wrath", "effect": "board_wipe"},
                "score_components": {
                    "asymmetry": 0,
                    "lethal_pressure": False,
                    "timing_justified": False,
                },
                "strategic_principle": "wipe_when_behind_under_lethal_pressure_or_asymmetric",
                "heuristic_version": "test",
                "resource_delta": {"asymmetry": 0},
                "risk_flags": ["wipe_without_timing_justification"],
                "alternatives_considered": [{"card": "Wrath"}],
            },
            {
                "decision_id": "d-wheel",
                "decision_type": "wheel",
                "chosen_option": {"card": "Wheel of Fortune", "effect": "draw_cards"},
                "score_components": {
                    "opponent_refill_risk": 2,
                    "model_scope": "self_draw_only",
                    "timing_justified": False,
                    "wheel_payoffs": [],
                },
                "strategic_principle": "wheel_only_when_refill_or_payoff_outweighs_opponent_refill",
                "heuristic_version": "test",
                "resource_delta": {"draw_count": 7},
                "risk_flags": ["wheel_model_simplified", "opponent_refill_risk"],
                "alternatives_considered": [{"card": "Wheel of Fortune"}],
            },
        ],
    )

    codes = {finding["code"] for finding in result["findings"]}
    assert "tutor_without_candidates" in codes
    assert "tutor_no_target" in codes
    assert "board_wipe_without_timing_justification" in codes
    assert "wheel_model_simplified" in codes
    assert "wheel_opponent_refill_risk" in codes
    assert result["summary"]["verdict"] == "needs_review"


def test_strategy_auditor_accepts_contextual_pass_no_action():
    result = auditor.audit_strategy(
        events=[],
        decisions=[
            {
                "decision_id": "d-pass-context",
                "decision_type": "pass_no_action",
                "chosen_option": {
                    "action": "pass",
                    "reason": "hold_instant_speed_interaction",
                },
                "score_components": {
                    "stack_empty": 1,
                    "main_phase_action_taken": 0,
                    "castable_now_count": 1,
                    "reactive_option_count": 1,
                },
                "strategic_principle": "pass_when_no_profitable_or_legal_action_is_available",
                "heuristic_version": "test",
                "resource_delta": {},
                "risk_flags": ["holding_instant_speed_interaction"],
                "alternatives_considered": [
                    {
                        "card": "Counterspell",
                        "action": "consider",
                        "payable": True,
                        "phase_legal": True,
                        "reactive": True,
                    }
                ],
                "reason": "hold_instant_speed_interaction",
            }
        ],
    )

    assert result["summary"]["findings"] == 0


def test_strategy_auditor_accepts_multiplayer_wheel_with_payoff():
    result = auditor.audit_strategy(
        events=[],
        decisions=[
            {
                "decision_id": "d-wheel-ok",
                "decision_type": "wheel",
                "chosen_option": {"card": "Wheel of Fortune", "effect": "draw_cards"},
                "score_components": {
                    "opponent_refill_risk": 2,
                    "model_scope": "multiplayer_discard_draw_v1",
                    "timing_justified": True,
                    "wheel_payoffs": ["Smothering Tithe"],
                },
                "strategic_principle": "wheel_only_when_refill_or_payoff_outweighs_opponent_refill",
                "heuristic_version": "test",
                "resource_delta": {"draw_count": 7},
                "risk_flags": [],
                "alternatives_considered": [{"card": "Wheel of Fortune"}],
            },
        ],
    )

    assert result["summary"]["findings"] == 0


def test_strategy_auditor_accepts_wheel_of_misfortune_compact_scope():
    result = auditor.audit_strategy(
        events=[],
        decisions=[
            {
                "decision_id": "d-wheel-misfortune",
                "decision_type": "wheel",
                "chosen_option": {"card": "Wheel of Misfortune", "effect": "wheel"},
                "score_components": {
                    "opponent_refill_risk": 0,
                    "model_scope": "wheel_of_misfortune_secret_number_compact_v1",
                    "timing_justified": True,
                    "wheel_payoffs": [],
                    "opponent_net_cards": [0, 0, 0],
                    "total_opponent_net_cards": 0,
                },
                "strategic_principle": "wheel_only_when_refill_or_payoff_outweighs_opponent_refill",
                "heuristic_version": "test",
                "resource_delta": {"draw_count": 7, "opponent_net_cards": [0, 0, 0]},
                "risk_flags": ["wheel_model_simplified"],
                "alternatives_considered": [{"card": "Wheel of Misfortune"}],
            },
        ],
    )

    codes = {finding["code"] for finding in result["findings"]}
    assert "wheel_model_simplified" not in codes
    assert result["summary"]["review_required_findings"] == 0


def test_strategy_auditor_flags_worldfire_without_known_follow_up():
    result = auditor.audit_strategy(
        events=[],
        decisions=[
            {
                "decision_id": "d-worldfire",
                "decision_type": "worldfire_reset",
                "chosen_option": {"card": "Worldfire", "effect": "worldfire_reset"},
                "score_components": {
                    "model_scope": "worldfire_total_reset_v1",
                    "known_follow_up_line": False,
                    "timing_justified": False,
                    "commander_redeploy_available": False,
                },
                "strategic_principle": "resolve_worldfire_only_with_known_post_reset_win_line",
                "heuristic_version": "test",
                "resource_delta": {"known_follow_up_line": False},
                "risk_flags": ["worldfire_without_known_win_line"],
                "alternatives_considered": [{"card": "Worldfire"}],
            },
        ],
    )

    codes = {finding["code"] for finding in result["findings"]}
    assert "worldfire_without_known_win_line" in codes


def test_global_learning_eligibility_blocks_high_strategy_seed_when_other_gates_review_required():
    result = auditor.compute_global_learning_eligibility(
        [
            {
                "seed": "63202364",
                "strategy_confidence": "high_confidence_replay",
                "action_findings": 1,
                "decision_decision_findings": 1,
                "forensic_rule_findings": 1,
                "forensic_high_or_critical": True,
            }
        ],
        final_status="review_required",
        mandatory_gate_divergences=[
            "action_critic=review_required",
            "forensic_audit=blocked",
        ],
    )

    reasons = result["global_learning_eligibility_reasons"]["63202364"]
    assert result["global_learning_eligible_seeds"] == []
    assert result["global_not_learning_eligible_seeds"] == ["63202364"]
    assert "action_critic_findings=1" in reasons
    assert "replay_decision_findings=1" in reasons
    assert "forensic_rule_findings=1" in reasons
    assert "forensic_audit_high_or_critical" in reasons
    assert "final_status:review_required" in reasons
    assert "mandatory_gate:forensic_audit=blocked" in reasons


def test_global_learning_eligibility_allows_clean_high_seed_and_excludes_low_confidence_seed():
    result = auditor.compute_global_learning_eligibility(
        [
            {
                "seed": "63202355",
                "strategy_confidence": "high_confidence_replay",
            },
            {
                "seed": "63202357",
                "strategy_confidence": "low_confidence_replay",
            },
        ],
        final_status="trusted_for_strategy_learning",
        mandatory_gate_divergences=[],
    )

    assert result["global_learning_eligible_seeds"] == ["63202355"]
    assert result["global_not_learning_eligible_seeds"] == ["63202357"]
    assert result["global_learning_eligibility_reasons"]["63202355"] == []
    assert result["global_learning_eligibility_reasons"]["63202357"] == [
        "strategy_audit:low_confidence_replay"
    ]
    assert (
        result["global_learning_eligibility_policy"]
        == "requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass"
    )


def test_summarize_learned_opponent_provenance_groups_sources_and_seeds():
    result = auditor.summarize_learned_opponent_provenance(
        [
            {
                "seed": "63210007",
                "source_kind": "learned_decks",
                "source_system": "pg_meta_decks",
                "source_ref": "learned_deck:58",
                "source_url": "pg:meta_decks:eceb0abb-e46d-4b79-9f82-c8f426f3e91b",
                "name": "Thrasios, Triton Hero #58 (real)",
                "commander": "Thrasios, Triton Hero",
                "deck_name": "Thrasios, Triton Hero + Vial Smasher the Fierce",
                "source_card_count": 100,
                "battle_card_count": 99,
                "cached_metadata_used_for_metrics": False,
                "metrics_basis": "runtime_derived_from_resolved_built_deck",
                "blocker_domain": "none",
            },
            {
                "seed": "63210008",
                "source_kind": "learned_decks",
                "source_system": "pg_meta_decks",
                "source_ref": "learned_deck:58",
                "source_url": "pg:meta_decks:eceb0abb-e46d-4b79-9f82-c8f426f3e91b",
                "name": "Thrasios, Triton Hero #58 (real)",
                "commander": "Thrasios, Triton Hero",
                "deck_name": "Thrasios, Triton Hero + Vial Smasher the Fierce",
                "source_card_count": 100,
                "battle_card_count": 99,
                "cached_metadata_used_for_metrics": False,
                "metrics_basis": "runtime_derived_from_resolved_built_deck",
                "blocker_domain": "none",
            },
        ]
    )

    assert result["learned_opponent_source_counts"] == {"pg_meta_decks": 2}
    assert result["opponent_deck_provenance"]["learned_opponent_unique_count"] == 1
    assert result["opponent_deck_provenance"]["learned_opponent_appearance_count"] == 2
    assert result["opponent_deck_provenance"]["status"] == "learned_opponent_provenance_present_with_shape_waiver"
    opponent = result["learned_deck_opponents"][0]
    assert opponent["source_row_id"] == 58
    assert opponent["source_url"] == "pg:meta_decks:eceb0abb-e46d-4b79-9f82-c8f426f3e91b"
    assert opponent["source_url_status"] == "present"
    assert opponent["commander"] == "Thrasios, Triton Hero"
    assert opponent["deck_name"] == "Thrasios, Triton Hero + Vial Smasher the Fierce"
    assert opponent["appearances"] == 2
    assert opponent["seeds"] == ["63210007", "63210008"]
    assert opponent["source_card_count"] == 100
    assert opponent["battle_card_count"] == 99
    assert opponent["cached_metadata_used_for_metrics"] is False
    assert opponent["construction_status"] == "waived_not_emitted_by_replay_deck_provenance"
    assert opponent["deck_coherence_status"] == "waived_not_emitted_by_replay_deck_provenance"
    assert "waiver_reason" in opponent
    assert result["opponent_deck_provenance"]["source_url_missing_count"] == 0


def test_summarize_learned_opponent_provenance_marks_present_reports():
    result = auditor.summarize_learned_opponent_provenance(
        [
            {
                "seed": "63210009",
                "source_kind": "learned_decks",
                "source_system": "pg_meta_decks",
                "source_ref": "learned_deck:25",
                "source_url": "pg:meta_decks:94ae22cd-7c7f-412c-b15f-2892c0b9d21d",
                "name": "Tayam, Luminous Enigma #25 (real)",
                "source_card_count": 100,
                "battle_card_count": 99,
                "cached_metadata_used_for_metrics": False,
                "metrics_basis": "runtime_derived_from_resolved_built_deck",
                "blocker_domain": "none",
                "construction_report": {"is_valid": True},
                "deck_coherence_report": {"status": "pass"},
            }
        ]
    )

    assert result["opponent_deck_provenance"]["status"] == "learned_opponent_provenance_present"
    opponent = result["learned_deck_opponents"][0]
    assert opponent["construction_report_present"] is True
    assert opponent["deck_coherence_report_present"] is True
    assert opponent["construction_status"] == "present"
    assert opponent["deck_coherence_status"] == "present"
    assert "waiver_reason" not in opponent


def test_strategy_auditor_renders_markdown():
    result = auditor.audit_strategy(events=[], decisions=[])
    markdown = auditor.render_markdown(result)

    assert "# Battle Decision Strategy Auditor" in markdown
    assert "usable_for_strategy_learning" in markdown
    assert "Learning confidence" in markdown


if __name__ == "__main__":
    tests = [
        test_strategy_auditor_flags_bad_mulligan_keep,
        test_strategy_auditor_flags_forced_keep_after_mana_screw_cap,
        test_strategy_auditor_flags_one_shot_mana_without_unlock_signal,
        test_strategy_auditor_accepts_one_shot_mana_with_unlock_context,
        test_strategy_auditor_flags_land_cost_without_selection_context,
        test_strategy_auditor_flags_risky_land_ramp_without_payoff_reason,
        test_strategy_auditor_ignores_failed_land_cost_when_no_land_exists,
        test_strategy_auditor_accepts_last_land_spend_with_commander_payoff,
        test_strategy_auditor_accepts_documented_land_discard_unlock_context,
        test_strategy_auditor_accepts_land_discard_payoff_after_trigger_window,
        test_strategy_auditor_accepts_documented_land_sacrifice_benefit,
        test_strategy_auditor_still_blocks_last_land_spend_without_payoff,
        test_strategy_auditor_flags_unjustified_tutor_and_wipe_wheel,
        test_strategy_auditor_accepts_contextual_pass_no_action,
        test_strategy_auditor_accepts_multiplayer_wheel_with_payoff,
        test_strategy_auditor_accepts_wheel_of_misfortune_compact_scope,
        test_strategy_auditor_flags_worldfire_without_known_follow_up,
        test_global_learning_eligibility_blocks_high_strategy_seed_when_other_gates_review_required,
        test_global_learning_eligibility_allows_clean_high_seed_and_excludes_low_confidence_seed,
        test_summarize_learned_opponent_provenance_groups_sources_and_seeds,
        test_summarize_learned_opponent_provenance_marks_present_reports,
        test_strategy_auditor_renders_markdown,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
