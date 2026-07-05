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


def _build(*, contract=None, cuts=0):
    contract_payload = contract if contract is not None else _contract(cuts=cuts)
    return matrix.build_report(
        contract_payload=contract_payload,
        value_model=_value_model(),
        cut_miner=_cut_miner(cuts=cuts),
        closing_trace=_closing_trace(),
        paths={"contract": Path("/tmp/contract.json")},
    )


def test_current_matrix_template_ready_but_candidate_scoring_blocked():
    payload = _build()

    assert payload["postgres_writes"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["decision_status"] == (
        "miracle_access_structure_matrix_template_ready_no_candidate_no_battle"
    )
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


def test_markdown_surfaces_template_policy_and_no_mutation():
    markdown = matrix.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "topdeck_miracle_access" in markdown
    assert "do_not_generate_a_deck_from_template_only" in markdown
    assert "Natural battle gate allowed now: `false`" in markdown
