from pathlib import Path

import lorehold_miracle_access_candidate_row_queue as queue


def _matrix(*, blockers=28, selected=True, routed=True):
    return {
        "summary": {
            "decision_status": queue.TARGET_MATRIX_STATUS,
            "selected_contract_key": queue.TARGET_MATRIX_CONTRACT if selected else "",
            "contract_aggregate_blocker_count": blockers,
            "next_shell_status": queue.TARGET_NEXT_SHELL_STATUS if routed else "",
            "engine_cut_path_closed": routed,
            "fallback_route_key": queue.TARGET_MATRIX_CONTRACT if routed else "",
            "fallback_structure_matrix_contract_allowed_now": routed,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
        }
    }


def _post_identity(cards=None):
    if cards is None:
        cards = [
            {
                "card_name": "Brain in a Jar",
                "lane": "topdeck_miracle_access",
                "priority_rank": 1,
                "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
                "verified_auto_rule_count": 0,
                "value_role": "alternate_cost_timing_engine",
                "source_keys": ["external_topdeck"],
                "required_contract": "single_card_runtime_contract_then_cut_safety",
            },
            {
                "card_name": "Entreat the Angels",
                "lane": "miracle_finisher",
                "priority_rank": 1,
                "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
                "verified_auto_rule_count": 0,
                "value_role": "miracle_token_closure",
                "source_keys": ["external_topdeck"],
                "required_contract": "miracle_token_runtime_contract_then_cut_safety",
            },
        ]
    return {"summary": {"queue_card_count": len(cards)}, "cards": cards}


def _cut_miner(*, cuts=0):
    return {
        "summary": {"named_seed_safe_cut_count": cuts},
        "ready_seed_safe_cuts": [
            {"card_name": f"Unit Safe Cut {idx}", "lane": "topdeck_miracle_setup"}
            for idx in range(cuts)
        ],
    }


def _value_model():
    return {"summary": {"quantity_total": 100}}


def _build(*, matrix=None, post_identity=None, cuts=0):
    return queue.build_report(
        matrix_contract=matrix if matrix is not None else _matrix(),
        post_identity=post_identity if post_identity is not None else _post_identity(),
        cut_miner=_cut_miner(cuts=cuts),
        value_model=_value_model(),
        paths={"matrix": Path("/tmp/matrix.json")},
    )


def test_current_queue_blocks_all_rows_and_keeps_607():
    payload = _build()

    assert payload["postgres_writes"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["decision_status"] == (
        "miracle_access_candidate_row_queue_blocked_no_scoreable_rows_keep_607"
    )
    assert payload["summary"]["matrix_next_shell_status"] == queue.TARGET_NEXT_SHELL_STATUS
    assert payload["summary"]["matrix_route_governed"] is True
    assert payload["summary"]["scoreable_candidate_row_count"] == 0
    assert payload["summary"]["blocked_candidate_row_count"] == 2
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False


def test_synthetic_runtime_ready_card_with_named_cut_can_feed_matrix_scoring_only():
    post = _post_identity(
        [
            {
                "card_name": "Unit Topdeck Tool",
                "lane": "topdeck_miracle_access",
                "priority_rank": 1,
                "blockers": [],
                "verified_auto_rule_count": 1,
                "value_role": "topdeck_tool",
                "source_keys": ["unit"],
                "required_contract": "unit_contract",
            }
        ]
    )
    payload = _build(matrix=_matrix(blockers=0), post_identity=post, cuts=1)

    assert payload["summary"]["decision_status"] == (
        "miracle_access_candidate_rows_ready_for_matrix_scoring_no_battle"
    )
    assert payload["summary"]["scoreable_candidate_row_count"] == 1
    assert payload["summary"]["matrix_scoring_allowed_now"] is True
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False


def test_combo_runtime_candidate_remains_blocked_even_with_cut():
    post = _post_identity(
        [
            {
                "card_name": "Haze of Rage",
                "lane": "storm_combo_pressure",
                "priority_rank": 2,
                "blockers": ["combo_runtime_required"],
                "verified_auto_rule_count": 1,
                "value_role": "storm_combo_payoff",
                "source_keys": ["spellbook"],
                "required_contract": "combo_runtime_contract_with_storm_kiln_artist",
            }
        ]
    )
    payload = _build(matrix=_matrix(blockers=0), post_identity=post, cuts=1)

    assert payload["summary"]["scoreable_candidate_row_count"] == 0
    assert payload["blocked_candidate_rows"][0]["add_card"] == "Haze of Rage"
    assert "combo_runtime_required" in payload["blocked_candidate_rows"][0]["blockers"]


def test_missing_matrix_contract_blocks_queue():
    payload = _build(matrix=_matrix(selected=False))

    assert payload["summary"]["decision_status"] == (
        "miracle_access_candidate_row_queue_blocked_missing_matrix_contract"
    )
    assert payload["summary"]["recommended_next_action"] == (
        "rerun_miracle_access_structure_matrix_contract"
    )


def test_matrix_without_next_shell_route_blocks_queue():
    payload = _build(matrix=_matrix(routed=False))

    assert payload["summary"]["decision_status"] == (
        "miracle_access_candidate_row_queue_blocked_matrix_route_not_governed"
    )
    assert payload["summary"]["recommended_next_action"] == (
        "rerun_routed_miracle_access_structure_matrix_contract"
    )
    assert payload["summary"]["matrix_route_governed"] is False
    assert "matrix_route_not_governed" in payload["blocked_candidate_rows"][0]["blockers"]


def test_markdown_surfaces_blocked_rows_and_no_mutation():
    markdown = queue.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert f"Matrix next-shell status: `{queue.TARGET_NEXT_SHELL_STATUS}`" in markdown
    assert "Matrix route governed: `true`" in markdown
    assert "Brain in a Jar" in markdown
    assert "Scoreable candidate rows: `0`" in markdown
    assert "Natural battle gate allowed now: `false`" in markdown
