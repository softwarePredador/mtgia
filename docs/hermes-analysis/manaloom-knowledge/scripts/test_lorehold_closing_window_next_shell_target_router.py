from pathlib import Path

import lorehold_closing_window_next_shell_target_router as router


def _closing_trace():
    return {
        "summary": {
            "comparison_count": 13,
            "avg_607_turn_advantage": 10.15,
            "ready_micro_package_hypothesis_count": 3,
            "gap_counts": {
                "miracle_cast_deficit": 13,
                "topdeck_activation_deficit": 9,
                "topdeck_engine_card_deficit": 11,
                "candidate_died_before_closing_window": 13,
                "candidate_lost_multiple_turns_before_607_finish": 13,
                "approach_conversion_missing": 7,
                "lorehold_spell_volume_deficit": 13,
            },
            "top_strategic_deficits": [{"event": "lorehold_spell_cast", "delta_total": 134}],
            "top_anchor_card_deficits": [
                {"event": "topdeck_manipulation_activated:Sensei's Divining Top", "delta_total": 29}
            ],
        },
        "hypothesis_queue": [
            {
                "hypothesis_key": "pressure_survival_without_engine_cuts",
                "target_gap_tags": [
                    "candidate_died_before_closing_window",
                    "candidate_lost_multiple_turns_before_607_finish",
                ],
                "evidence_events": ["miracle_cast"],
                "evidence_cards": ["Sensei's Divining Top"],
                "requirements": ["preserve engine"],
            },
            {
                "hypothesis_key": "preserve_topdeck_miracle_floor_micro_package",
                "target_gap_tags": [
                    "miracle_cast_deficit",
                    "topdeck_activation_deficit",
                    "topdeck_engine_card_deficit",
                ],
                "evidence_events": ["miracle_cast", "topdeck_manipulation_activated"],
                "evidence_cards": ["Sensei's Divining Top", "Scroll Rack"],
                "requirements": ["do not cut topdeck anchors"],
            },
            {
                "hypothesis_key": "approach_big_spell_conversion_preservation",
                "target_gap_tags": ["approach_conversion_missing", "lorehold_spell_volume_deficit"],
                "evidence_events": ["lorehold_spell_cast"],
                "evidence_cards": ["Approach of the Second Sun"],
                "requirements": ["preserve Approach"],
            },
        ],
    }


def _shell_failure(can_battle=False):
    return {
        "summary": {
            "can_run_next_battle_gate": can_battle,
            "promotable_shell_signal_count": 0,
        }
    }


def _cut_miner(named_cuts=0):
    return {"summary": {"named_seed_safe_cut_count": named_cuts, "cut_shortage": 2 - named_cuts}}


def _miracle_failure(flags=None):
    return {
        "summary": {
            "blocking_failure_flags": flags
            if flags is not None
            else [
                "miracle_trace_missing",
                "topdeck_activation_missing",
                "topdeck_anchor_access_regressed",
                "pressure_causality_unproven",
                "fast_pressure_slice_not_protected",
            ]
        }
    }


def _build(*, can_battle=False, named_cuts=0, flags=None):
    return router.build_report(
        closing_trace=_closing_trace(),
        shell_failure=_shell_failure(can_battle=can_battle),
        cut_miner=_cut_miner(named_cuts=named_cuts),
        miracle_failure=_miracle_failure(flags=flags),
        paths={"closing_trace": Path("/tmp/closing.json")},
    )


def test_selects_miracle_access_first_shell_target_without_battle():
    payload = _build()

    assert payload["summary"]["decision_status"] == "closing_window_shell_target_selected_no_battle"
    assert payload["summary"]["selected_hypothesis_key"] == (
        "preserve_topdeck_miracle_floor_micro_package"
    )
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["selected_shell_target"]["shell_contract"]["contract_key"] == (
        "miracle_access_first_shell_contract"
    )


def test_pressure_route_is_diagnostic_after_engine_floor():
    payload = _build()
    pressure = next(
        row
        for row in payload["hypothesis_routes"]
        if row["hypothesis_key"] == "pressure_survival_without_engine_cuts"
    )

    assert pressure["status"] == "diagnostic_only_after_engine_floor"
    assert "pressure_route_must_follow_engine_floor_repair" in pressure["blockers"]
    assert pressure["battle_allowed_now"] is False


def test_clean_synthetic_case_can_be_ready_for_shell_contract():
    payload = _build(can_battle=True, named_cuts=2, flags=[])

    assert payload["hypothesis_routes"][0]["status"] == (
        "closing_window_target_ready_for_shell_contract"
    )
    assert payload["summary"]["selected_hypothesis_key"] == (
        "preserve_topdeck_miracle_floor_micro_package"
    )


def test_missing_hypotheses_requires_rerun_closing_window_miner():
    payload = router.build_report(
        closing_trace={"summary": {"comparison_count": 0}, "hypothesis_queue": []},
        shell_failure=_shell_failure(),
        cut_miner=_cut_miner(),
        miracle_failure=_miracle_failure(),
        paths={"closing_trace": Path("/tmp/closing.json")},
    )

    assert payload["summary"]["decision_status"] == "closing_window_shell_target_missing"
    assert payload["summary"]["recommended_next_action"] == (
        "rerun_closing_window_trace_miner_with_game_results"
    )


def test_markdown_surfaces_no_mutation_and_selected_contract():
    markdown = router.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "miracle_access_first_shell_contract" in markdown
    assert "Natural battle gate allowed now: `false`" in markdown
