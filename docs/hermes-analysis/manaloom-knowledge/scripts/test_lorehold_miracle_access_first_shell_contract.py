from pathlib import Path

import lorehold_miracle_access_first_shell_contract as contract


def _router(*, blockers=None, selected=True, key=contract.TARGET_HYPOTHESIS):
    selected_row = {
        "hypothesis_key": key,
        "status": "primary_shell_contract_target_blocked_but_actionable_as_design",
        "blockers": blockers
        if blockers is not None
        else [
            "from_scratch_shell_gate_not_allowed",
            "miracle_trace_missing",
            "no_named_seed_safe_cuts_in_current_607",
        ],
        "shell_contract": {
            "contract_key": contract.TARGET_CONTRACT,
            "shell_type": "micro_shell_before_full_generation",
            "must_preserve": [
                "Sensei's Divining Top",
                "Scroll Rack",
                "Bender's Waterskin",
                "Victory Chimes",
                "Approach of the Second Sun",
            ],
            "target_metrics": [
                "miracle_cast",
                "topdeck_manipulation_activated",
                "lorehold_spell_cast",
                "lorehold_upkeep_rummage",
                "static_cost_reduction_total",
            ],
            "forbidden_shortcut": "Do not add tutors before the miracle floor.",
        },
    }
    return {
        "summary": {
            "selected_hypothesis_key": key if selected else "",
            "selected_contract_key": contract.TARGET_CONTRACT if selected else "",
        },
        "selected_shell_target": selected_row if selected else {},
        "hypothesis_routes": [selected_row] if selected else [],
    }


def _preflight(*, ready=0, blockers=None):
    return {
        "summary": {
            "candidate_count": 2,
            "gate_ready_now_count": ready,
            "promotion_allowed": False,
            "strategic_floors_from_607": {
                "miracle_cast": 4,
                "topdeck_manipulation_activated": 5,
                "lorehold_spell_cast": 22,
                "lorehold_cost_paid": 27,
                "lorehold_upkeep_rummage": 5,
            },
            "anchor_access_floors_from_607": {
                "Sensei's Divining Top": 2,
                "Scroll Rack": 1,
                "Lorehold, the Historian": 3,
            },
            "blocking_reasons": blockers
            if blockers is not None
            else [
                "miracle_cast_below_607_floor",
                "topdeck_manipulation_activated_below_607_floor",
            ],
        },
        "contract": {
            "protected_anchors_not_negotiable_without_proof": [
                "Molecule Man",
                "The Scarlet Witch",
            ]
        },
    }


def _closing_trace():
    return {
        "summary": {
            "comparison_count": 13,
            "avg_607_turn_advantage": 10.15,
            "gap_counts": {
                "miracle_cast_deficit": 13,
                "topdeck_activation_deficit": 9,
                "approach_conversion_missing": 7,
            },
            "top_strategic_deficits": [
                {"event": "miracle_cast", "delta_total": 71},
                {"event": "topdeck_manipulation_activated", "delta_total": 41},
            ],
            "top_anchor_card_deficits": [
                {"event": "topdeck_manipulation_activated:Sensei's Divining Top", "delta_total": 29}
            ],
        }
    }


def _shell_failure(*, can_battle=False, blockers=None):
    return {
        "summary": {
            "can_run_next_battle_gate": can_battle,
            "promotable_shell_signal_count": 0,
            "blockers": blockers
            if blockers is not None
            else ["broad shell changes overfill package lanes or regress miracle/topdeck cadence"],
        }
    }


def _cut_miner(*, cuts=0):
    return {"summary": {"named_seed_safe_cut_count": cuts, "cut_shortage": max(0, 2 - cuts)}}


def _miracle_failure(*, flags=None):
    return {
        "summary": {
            "blocking_failure_flags": flags
            if flags is not None
            else ["miracle_trace_missing", "topdeck_activation_missing"]
        }
    }


def _build(
    *,
    router=None,
    preflight=None,
    shell_failure=None,
    cut_miner=None,
    miracle_failure=None,
):
    return contract.build_report(
        router=router if router is not None else _router(),
        preflight=preflight if preflight is not None else _preflight(),
        closing_trace=_closing_trace(),
        shell_failure=shell_failure if shell_failure is not None else _shell_failure(),
        cut_miner=cut_miner if cut_miner is not None else _cut_miner(),
        miracle_failure=miracle_failure if miracle_failure is not None else _miracle_failure(),
        paths={"router": Path("/tmp/router.json")},
    )


def test_current_contract_is_written_without_battle_or_deck_mutation():
    payload = _build()

    assert payload["postgres_writes"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["decision_status"] == (
        "miracle_access_first_contract_written_no_battle_blocked_before_structure_matrix"
    )
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["summary"]["deck_action_allowed_now"] is False
    assert "Sensei's Divining Top" in payload["contract"]["protected_anchors"]


def test_pressure_and_staple_shortcuts_are_blocked_until_miracle_floor():
    payload = _build()
    shortcuts = {row["shortcut_key"] for row in payload["contract"]["blocked_shortcuts"]}

    assert "pressure_conversion_blocked_until_miracle_floor" in shortcuts
    assert "global_staple_not_cross_lane_cut_proof" in shortcuts
    assert "broad_from_scratch_shell_blocked" in shortcuts


def test_clean_synthetic_case_only_allows_structure_matrix_not_battle():
    payload = _build(
        router=_router(blockers=[]),
        preflight=_preflight(ready=1, blockers=[]),
        shell_failure=_shell_failure(can_battle=True, blockers=[]),
        cut_miner=_cut_miner(cuts=2),
        miracle_failure=_miracle_failure(flags=[]),
    )

    assert payload["summary"]["decision_status"] == (
        "miracle_access_first_contract_ready_for_structure_matrix_no_battle"
    )
    assert payload["summary"]["structure_matrix_allowed_now"] is True
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["summary"]["promotion_allowed_now"] is False


def test_missing_router_target_blocks_and_requires_rerun():
    payload = _build(router=_router(selected=False))

    assert payload["summary"]["decision_status"] == (
        "miracle_access_contract_blocked_missing_router_target"
    )
    assert payload["summary"]["recommended_next_action"] == (
        "rerun_closing_window_next_shell_target_router"
    )
    assert payload["summary"]["structure_matrix_contract_allowed_now"] is False


def test_markdown_surfaces_research_floors_and_no_mutation():
    markdown = contract.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "EDHREC Boros Miracles on a Budget" in markdown
    assert "miracle_cast_floor" in markdown
    assert "pressure_conversion_blocked_until_miracle_floor" in markdown
