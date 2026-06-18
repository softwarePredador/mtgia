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


def test_strategy_auditor_renders_markdown():
    result = auditor.audit_strategy(events=[], decisions=[])
    markdown = auditor.render_markdown(result)

    assert "# Battle Decision Strategy Auditor" in markdown
    assert "usable_for_strategy_learning" in markdown


if __name__ == "__main__":
    tests = [
        test_strategy_auditor_flags_bad_mulligan_keep,
        test_strategy_auditor_flags_one_shot_mana_without_unlock_signal,
        test_strategy_auditor_flags_land_cost_without_selection_context,
        test_strategy_auditor_ignores_failed_land_cost_when_no_land_exists,
        test_strategy_auditor_accepts_last_land_spend_with_commander_payoff,
        test_strategy_auditor_accepts_documented_land_sacrifice_benefit,
        test_strategy_auditor_still_blocks_last_land_spend_without_payoff,
        test_strategy_auditor_flags_unjustified_tutor_and_wipe_wheel,
        test_strategy_auditor_accepts_multiplayer_wheel_with_payoff,
        test_strategy_auditor_flags_worldfire_without_known_follow_up,
        test_strategy_auditor_renders_markdown,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
