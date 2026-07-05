from pathlib import Path

import lorehold_miracle_access_structure_matrix_contract as matrix


def _contract(*, selected=True, blockers=28, cuts=0, candidate_rows=None):
    payload = {
        "postgres_writes": False,
        "deck_607_mutated": False,
        "summary": {
            "selected_contract_key": matrix.TARGET_CONTRACT if selected else "",
            "contract_written": selected,
            "structure_matrix_contract_allowed_now": selected,
            "aggregate_blocker_count": blockers,
            "named_seed_safe_cut_count": cuts,
            "preflight_gate_ready_now_count": 0 if blockers else 1,
        },
        "contract": {
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
                "Library of Leng": 0,
                "Land Tax": 1,
            },
        },
    }
    if candidate_rows is not None:
        payload["candidate_rows"] = candidate_rows
    return payload


def _value_model():
    return {
        "summary": {
            "quantity_total": 100,
            "lane_profile": {
                "topdeck_miracle_setup": 9,
                "instant_sorcery_density": 36,
            },
            "mana_foundation": {"land_quantity": 34, "ramp_quantity": 15},
        }
    }


def _cut_miner(*, cuts=0):
    return {"summary": {"named_seed_safe_cut_count": cuts, "cut_shortage": max(0, 2 - cuts)}}


def _closing_trace():
    return {"summary": {"comparison_count": 13}}


def _next_shell(*, routed=True):
    if not routed:
        return {
            "status": "next_shell_contract_written_not_materializable_keep_607",
            "summary": {
                "decision_status": "next_shell_contract_written_not_materializable_keep_607",
                "recommended_next_action": "mine_two_named_seed_safe_nonanchor_cuts_for_engine_preserving_shell",
                "engine_cut_path_closed": False,
                "fallback_route_key": "",
                "fallback_structure_matrix_contract_allowed_now": False,
                "natural_battle_gate_allowed_now": False,
                "promotion_allowed_now": False,
                "candidate_deck_materialization_allowed_now": False,
            },
        }
    return {
        "status": matrix.TARGET_NEXT_SHELL_STATUS,
        "summary": {
            "decision_status": matrix.TARGET_NEXT_SHELL_STATUS,
            "recommended_next_action": matrix.TARGET_NEXT_SHELL_ACTION,
            "engine_cut_path_closed": True,
            "engine_cut_path_status": "no_current_cut_evidence_for_guttersnipe_storm_kiln_keep_607",
            "engine_cut_path_hard_stop_cut_count": 94,
            "engine_cut_path_target_lane_evidence_gap_count": 0,
            "fallback_route_key": matrix.TARGET_CONTRACT,
            "fallback_route_status": "miracle_access_first_contract_written_no_battle_blocked_before_structure_matrix",
            "fallback_structure_matrix_contract_allowed_now": True,
            "target_route_key": "guttersnipe_storm_kiln_engine_preserving_pair",
            "target_adds": ["Guttersnipe", "Storm-Kiln Artist"],
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
        },
    }


def _build(*, contract=None, cuts=0, next_shell=None):
    contract_payload = contract if contract is not None else _contract(cuts=cuts)
    return matrix.build_report(
        contract_payload=contract_payload,
        value_model=_value_model(),
        cut_miner=_cut_miner(cuts=cuts),
        closing_trace=_closing_trace(),
        next_shell_synthesis=next_shell if next_shell is not None else _next_shell(),
        paths={"contract": Path("/tmp/contract.json"), "next_shell_synthesis": Path("/tmp/next.json")},
    )


def test_current_matrix_template_ready_but_candidate_scoring_blocked():
    payload = _build()

    assert payload["postgres_writes"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["decision_status"] == (
        "miracle_access_structure_matrix_template_ready_no_candidate_no_battle"
    )
    assert payload["summary"]["next_shell_status"] == matrix.TARGET_NEXT_SHELL_STATUS
    assert payload["summary"]["engine_cut_path_closed"] is True
    assert payload["summary"]["fallback_route_key"] == matrix.TARGET_CONTRACT
    assert payload["summary"]["matrix_scoring_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False


def test_matrix_cells_prioritize_topdeck_and_same_lane_cuts():
    payload = _build()
    cells = {row["cell_key"]: row for row in payload["matrix_contract"]["matrix_cells"]}

    assert cells["topdeck_miracle_access"]["weight"] == 30
    assert "miracle_cast" in cells["topdeck_miracle_access"]["required_metrics"]
    assert cells["same_lane_cut_safety"]["weight"] == 25
    assert "Sensei's Divining Top" in cells["topdeck_miracle_access"]["protected_anchors"]


def test_synthetic_candidate_rows_can_be_scored_but_not_battled():
    candidate_rows = [
        {
            "candidate_key": "unit_miracle_access_test",
            "add_card": "Unit Topdeck Tool",
            "cut_card": "Unit Same Lane Flex",
            "lane": "topdeck_miracle_setup",
            "same_lane_cut_reason": "unit",
        }
    ]
    payload = _build(contract=_contract(blockers=0, cuts=2, candidate_rows=candidate_rows), cuts=2)

    assert payload["summary"]["decision_status"] == (
        "miracle_access_structure_matrix_ready_to_score_candidate_rows_no_battle"
    )
    assert payload["summary"]["matrix_scoring_allowed_now"] is True
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["summary"]["promotion_allowed_now"] is False


def test_missing_contract_blocks_matrix():
    payload = _build(contract=_contract(selected=False))

    assert payload["summary"]["decision_status"] == (
        "miracle_access_structure_matrix_blocked_missing_contract"
    )
    assert payload["summary"]["recommended_next_action"] == (
        "rerun_miracle_access_first_shell_contract"
    )


def test_missing_next_shell_route_blocks_matrix_even_with_contract():
    payload = _build(next_shell=_next_shell(routed=False))

    assert payload["summary"]["decision_status"] == (
        "miracle_access_structure_matrix_blocked_missing_next_shell_route"
    )
    assert payload["summary"]["recommended_next_action"] == "rerun_next_shell_contract_synthesis"
    gate = {
        row["gate_key"]: row
        for row in payload["matrix_contract"]["hard_gates"]
    }["next_shell_routes_to_miracle_access"]
    assert gate["passed"] is False
    assert gate["blocks_matrix_scoring"] is True


def test_entry_route_contract_keeps_pressure_conversion_learning_only():
    payload = _build()

    route_contract = payload["matrix_contract"]["entry_route_contract"]

    assert route_contract["required_next_shell_status"] == matrix.TARGET_NEXT_SHELL_STATUS
    assert route_contract["required_fallback_route"] == matrix.TARGET_CONTRACT
    assert route_contract["observed_route"]["target_adds"] == ["Guttersnipe", "Storm-Kiln Artist"]
    assert "learning-only" in route_contract["pressure_conversion_shell_policy"]


def test_markdown_surfaces_template_policy_and_no_mutation():
    markdown = matrix.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert f"Next-shell status: `{matrix.TARGET_NEXT_SHELL_STATUS}`" in markdown
    assert f"Fallback route: `{matrix.TARGET_CONTRACT}`" in markdown
    assert "topdeck_miracle_access" in markdown
    assert "do_not_generate_a_deck_from_template_only" in markdown
    assert "Natural battle gate allowed now: `false`" in markdown
