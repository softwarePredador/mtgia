from pathlib import Path

import lorehold_diagnostic_contract_planner as planner


def _base_external_reconciliation():
    return {
        "signals": [
            {
                "signal_key": "external_spell_pressure_creature_package",
                "lane": "pressure_absorber",
                "external_strength": "medium",
                "contract_path": "full_shell",
                "blockers": ["not_a_current_one_for_one_cut", "prior_internal_reject"],
                "known_internal_decisions": [
                    "Storm-Kiln Artist had real signal but regressed Winota."
                ],
                "evidence_summary": "Pressure payoff cards need a pressure-safe shell.",
            },
            {
                "signal_key": "external_breach_wheel_aetherflux_conversion_shell",
                "lane": "spell_chain_conversion",
                "external_strength": "high",
                "contract_path": "full_shell",
                "blockers": ["not_a_current_one_for_one_cut"],
                "known_internal_decisions": ["Prior broad shells did not beat 607."],
                "evidence_summary": "Conversion shell has public support.",
            },
            {
                "signal_key": "external_one_ring_value_engine",
                "lane": "card_draw_selection",
                "external_strength": "high_global_low_context",
                "contract_path": "same_lane_package",
                "blockers": ["proposed_cut_not_seed_safe"],
                "known_internal_decisions": ["The One Ring tested cuts lost to 607."],
                "evidence_summary": "Global staple but no safe cut.",
            },
            {
                "signal_key": "external_approach_lapse_deterministic_line",
                "lane": "deterministic_finisher",
                "external_strength": "medium",
                "contract_path": "same_lane_package",
                "blockers": ["no_named_cut_card"],
                "known_internal_decisions": [],
                "evidence_summary": "Approach plus Lapse needs a named cut.",
            },
        ]
    }


def _base_shell_synthesis():
    return {
        "signals": [
            {
                "signal_key": "external_spell_pressure_creature_package",
                "lane": "pressure_absorber",
                "synthesis_status": "partial_or_uncovered_full_shell",
                "cards_checked": [
                    "Monastery Mentor",
                    "Young Pyromancer",
                    "Guttersnipe",
                    "Storm-Kiln Artist",
                ],
                "exact_coverage_count": 0,
                "best_coverages": [
                    {
                        "shell_slug": "miracle_topdeck_control",
                        "matched_cards": ["Storm-Kiln Artist"],
                        "missing_cards": [
                            "Monastery Mentor",
                            "Young Pyromancer",
                            "Guttersnipe",
                        ],
                    }
                ],
                "recommended_action": "define_smaller_named_shell_contract_before_battle",
            },
            {
                "signal_key": "external_breach_wheel_aetherflux_conversion_shell",
                "lane": "spell_chain_conversion",
                "synthesis_status": "covered_by_existing_nonpromotable_shell",
                "cards_checked": ["Underworld Breach", "Wheel of Fortune", "Aetherflux Reservoir"],
                "exact_coverage_count": 1,
                "best_coverages": [
                    {
                        "shell_slug": "access_density_control",
                        "matched_cards": [
                            "Underworld Breach",
                            "Wheel of Fortune",
                            "Aetherflux Reservoir",
                        ],
                        "missing_cards": [],
                    }
                ],
                "recommended_action": "do_not_repeat_full_shell_without_new_contract_change",
            },
            {
                "signal_key": "external_one_ring_value_engine",
                "lane": "card_draw_selection",
                "synthesis_status": "blocked_by_cut_safety",
                "cards_checked": ["The One Ring"],
                "exact_coverage_count": 0,
                "best_coverages": [],
                "recommended_action": "do_not_gate_until_cut_safety_changes",
            },
            {
                "signal_key": "external_approach_lapse_deterministic_line",
                "lane": "deterministic_finisher",
                "synthesis_status": "blocked_no_named_cut",
                "cards_checked": ["Lapse of Certainty"],
                "exact_coverage_count": 0,
                "best_coverages": [],
                "recommended_action": "name_cut_or_model_as_diagnostic_only",
            },
        ]
    }


def _base_hypothesis_queue():
    return {
        "summary": {
            "natural_gate_ready_count": 0,
            "promotion_allowed": False,
        },
        "hypotheses": [
            {
                "card_name": "Storm-Kiln Artist",
                "readiness_status": "blocked_prior_reject",
                "priority": "P3_learning_only",
                "allowed_next_test": "do_not_retest_without_new_cut_or_new_trace_hypothesis",
                "same_lane_current_607_anchors": [
                    {
                        "card_name": "Arcane Signet",
                        "primary_value_lane": "ramp",
                        "priority_class": "structural_foundation",
                        "cut_policy": "same_lane_only_with_card_use_and_equal_gate",
                    }
                ],
            },
            {
                "card_name": "The One Ring",
                "readiness_status": "blocked_prior_reject",
                "priority": "P3_learning_only",
                "allowed_next_test": "do_not_retest_without_new_cut_or_new_trace_hypothesis",
                "same_lane_current_607_anchors": [],
            },
            {
                "card_name": "Wheel of Fortune",
                "readiness_status": "needs_safe_cut_model",
                "priority": "P1_forced_access_diagnostic",
                "allowed_next_test": "forced_access_diagnostic_only_until_miracle_access_floors_pass",
                "same_lane_current_607_anchors": [
                    {
                        "card_name": "Reforge the Soul",
                        "primary_value_lane": "topdeck_miracle_setup",
                        "priority_class": "protected_payoff_finisher_anchor",
                        "cut_policy": "protected_anchor_no_cut_without_explicit_package_and_equal_gate",
                    }
                ],
            },
        ],
    }


def test_planner_ranks_pressure_safe_micro_shell_first():
    payload = planner.build_report(
        external_reconciliation=_base_external_reconciliation(),
        shell_synthesis=_base_shell_synthesis(),
        hypothesis_queue=_base_hypothesis_queue(),
        external_reconciliation_path=Path("/tmp/recon.json"),
        shell_synthesis_path=Path("/tmp/shell.json"),
        hypothesis_queue_path=Path("/tmp/hypothesis.json"),
    )

    assert payload["summary"]["top_diagnostic_key"] == (
        "pressure_safe_spell_payoff_micro_shell"
    )
    assert payload["summary"]["ready_deck_change_count"] == 0
    assert payload["summary"]["keep_607_protected"] is True
    assert payload["ranked_diagnostics"][0]["readiness"] == "design_next"
    assert payload["summary"]["natural_gate_ready_from_hypothesis_queue"] == 0
    assert payload["summary"]["recommended_next_action"] == (
        "draft_pressure_safe_spell_payoff_diagnostic_contract_no_natural_gate"
    )


def test_planner_keeps_covered_failed_conversion_shell_deferred():
    payload = planner.build_report(
        external_reconciliation=_base_external_reconciliation(),
        shell_synthesis=_base_shell_synthesis(),
        hypothesis_queue=_base_hypothesis_queue(),
        external_reconciliation_path=Path("/tmp/recon.json"),
        shell_synthesis_path=Path("/tmp/shell.json"),
        hypothesis_queue_path=Path("/tmp/hypothesis.json"),
    )
    row = next(
        item
        for item in payload["ranked_diagnostics"]
        if item["signal_key"] == "external_breach_wheel_aetherflux_conversion_shell"
    )

    assert row["readiness"] == "defer"
    assert row["priority_score"] < payload["ranked_diagnostics"][0]["priority_score"]


def test_planner_blocks_one_ring_until_cut_safety_changes():
    payload = planner.build_report(
        external_reconciliation=_base_external_reconciliation(),
        shell_synthesis=_base_shell_synthesis(),
        hypothesis_queue=_base_hypothesis_queue(),
        external_reconciliation_path=Path("/tmp/recon.json"),
        shell_synthesis_path=Path("/tmp/shell.json"),
        hypothesis_queue_path=Path("/tmp/hypothesis.json"),
    )
    row = next(
        item
        for item in payload["ranked_diagnostics"]
        if item["signal_key"] == "external_one_ring_value_engine"
    )

    assert row["readiness"] == "blocked_until_cut_safety_changes"
    assert row["score_components"]["risk_penalty"] >= 7
    assert row["hypothesis_queue_alignment"]["matched_cards"] == ["The One Ring"]
    assert row["natural_gate_allowed_now"] is False


def test_planner_keeps_approach_lapse_as_diagnostic_until_cut_exists():
    payload = planner.build_report(
        external_reconciliation=_base_external_reconciliation(),
        shell_synthesis=_base_shell_synthesis(),
        hypothesis_queue=_base_hypothesis_queue(),
        external_reconciliation_path=Path("/tmp/recon.json"),
        shell_synthesis_path=Path("/tmp/shell.json"),
        hypothesis_queue_path=Path("/tmp/hypothesis.json"),
    )
    row = next(
        item
        for item in payload["ranked_diagnostics"]
        if item["signal_key"] == "external_approach_lapse_deterministic_line"
    )

    assert row["readiness"] == "research_or_diagnostic_only"
    assert payload["summary"]["top_diagnostic_key"] == (
        "pressure_safe_spell_payoff_micro_shell"
    )


def test_planner_attaches_hypothesis_queue_anchor_context():
    payload = planner.build_report(
        external_reconciliation=_base_external_reconciliation(),
        shell_synthesis=_base_shell_synthesis(),
        hypothesis_queue=_base_hypothesis_queue(),
        external_reconciliation_path=Path("/tmp/recon.json"),
        shell_synthesis_path=Path("/tmp/shell.json"),
        hypothesis_queue_path=Path("/tmp/hypothesis.json"),
    )
    pressure = next(
        item
        for item in payload["ranked_diagnostics"]
        if item["signal_key"] == "external_spell_pressure_creature_package"
    )

    alignment = pressure["hypothesis_queue_alignment"]
    assert alignment["matched_cards"] == ["Storm-Kiln Artist"]
    assert alignment["natural_gate_allowed_by_queue"] is False
    assert alignment["same_lane_anchors_by_card"]["Storm-Kiln Artist"][0]["card_name"] == "Arcane Signet"
