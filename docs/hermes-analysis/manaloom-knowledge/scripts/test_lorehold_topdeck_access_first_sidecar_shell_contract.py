from pathlib import Path

import lorehold_topdeck_access_first_sidecar_shell_contract as contract


def _route(*, selected=True):
    return {
        "summary": {
            "selected_route": contract.TARGET_ROUTE if selected else "repair_inputs_before_learning_route",
            "sidecar_shell_contract_required": selected,
            "recommended_next_action": (
                "write_or_refresh_topdeck_access_first_sidecar_shell_contract_before_materialization"
            ),
        }
    }


def _queue(*, eligible=False):
    rows = [
        {
            "add_card": "Dragon's Rage Channeler",
            "sidecar_tag": "topdeck_access_sidecar_primary",
            "matrix_candidate_row_eligible_now": eligible,
            "nonanchor_model_status": "clean_prior_target_blocked_no_nonanchor_cut",
            "nonanchor_same_lane_slot_count": 6,
            "nonanchor_seed_safe_count": 0,
            "nonanchor_reviewable_gap_count": 0,
            "blockers": []
            if eligible
            else [
                "missing_named_same_lane_cut",
                "needs_safe_cut_model",
                "nonanchor_model_has_no_reviewable_gap",
                "nonanchor_model_has_no_seed_safe_cut",
            ],
        },
        {
            "add_card": "Penance",
            "sidecar_tag": "topdeck_access_sidecar_primary",
            "matrix_candidate_row_eligible_now": False,
            "nonanchor_model_status": "prior_reject_target_blocked_no_nonanchor_cut",
            "nonanchor_same_lane_slot_count": 20,
            "nonanchor_seed_safe_count": 0,
            "nonanchor_reviewable_gap_count": 0,
            "blockers": [
                "missing_named_same_lane_cut",
                "needs_safe_cut_model",
                "nonanchor_model_has_no_reviewable_gap",
                "nonanchor_model_has_no_seed_safe_cut",
                "prior_reject_requires_new_trace_hypothesis",
            ],
        },
    ]
    return {
        "summary": {
            "queue_row_count": len(rows),
            "matrix_candidate_row_eligible_count": 1 if eligible else 0,
            "candidate_deck_materialization_allowed_now": False,
            "nonanchor_primary_target": "Dragon's Rage Channeler",
            "nonanchor_seed_safe_count": 0,
            "nonanchor_reviewable_gap_count": 0,
        },
        "candidate_queue": rows,
    }


def _nonanchor():
    return {
        "summary": {
            "primary_target": "Dragon's Rage Channeler",
            "primary_target_model_status": "clean_prior_target_blocked_no_nonanchor_cut",
            "seed_safe_nonanchor_count": 0,
            "reviewable_nonanchor_gap_count": 0,
        }
    }


def _miracle_contract():
    return {
        "summary": {
            "selected_contract_key": "miracle_access_first_shell_contract",
            "structure_matrix_contract_allowed_now": True,
        },
        "contract": {
            "protected_anchors": [
                "Lorehold, the Historian",
                "Sensei's Divining Top",
                "Scroll Rack",
                "Approach of the Second Sun",
                "Storm Herd",
            ]
        },
    }


def _value_model():
    return {
        "summary": {
            "mana_foundation": {
                "land_quantity": 34,
                "ramp_quantity": 15,
                "mana_sources_land_plus_ramp": 49,
                "land_groups": {
                    "basic_floor": 8,
                    "fetch_or_search_fixing": 8,
                    "utility_engine_land": 8,
                },
            }
        }
    }


def _trace():
    return {
        "summary": {
            "trace_collection_allowed_count": 5,
            "microbenchmark_runnable_count": 0,
        }
    }


def _paths():
    return {
        "post_safe_cut_route": Path("/tmp/route.json"),
        "sidecar_queue": Path("/tmp/queue.json"),
        "nonanchor_cut_model": Path("/tmp/nonanchor.json"),
        "miracle_shell_contract": Path("/tmp/miracle.json"),
        "value_model": Path("/tmp/value.json"),
        "trace_evidence": Path("/tmp/trace.json"),
    }


def _build(**overrides):
    return contract.build_report(
        post_safe_cut_route=overrides.get("post_safe_cut_route", _route()),
        sidecar_queue=overrides.get("sidecar_queue", _queue()),
        nonanchor_cut_model=overrides.get("nonanchor_cut_model", _nonanchor()),
        miracle_shell_contract=overrides.get("miracle_shell_contract", _miracle_contract()),
        value_model=overrides.get("value_model", _value_model()),
        trace_evidence=overrides.get("trace_evidence", _trace()),
        paths=_paths(),
    )


def test_current_like_contract_blocks_deck_materialization_and_battle():
    payload = _build()

    assert payload["postgres_writes"] is False
    assert payload["source_db_mutated"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["decision_status"] == (
        "topdeck_access_first_sidecar_contract_written_no_matrix_rows_keep_607"
    )
    assert payload["summary"]["contract_written"] is True
    assert payload["summary"]["structure_matrix_contract_allowed_now"] is False
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["forced_access_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["summary"]["promotion_allowed_now"] is False


def test_contract_preserves_mana_floor_and_topdeck_anchors():
    payload = _build()

    assert payload["summary"]["land_quantity_floor"] == 34
    assert payload["summary"]["ramp_quantity_floor"] == 15
    assert payload["summary"]["mana_sources_land_plus_ramp_floor"] == 49
    anchors = set(payload["contract"]["protected_anchors"])
    assert "Sensei's Divining Top" in anchors
    assert "Scroll Rack" in anchors
    assert "Bender's Waterskin" in anchors
    assert "Victory Chimes" in anchors


def test_synthetic_eligible_row_only_allows_structure_contract():
    payload = _build(sidecar_queue=_queue(eligible=True))

    assert payload["summary"]["decision_status"] == (
        "topdeck_access_first_sidecar_contract_ready_for_structure_contract_no_deck"
    )
    assert payload["summary"]["structure_matrix_contract_allowed_now"] is True
    assert payload["summary"]["structure_matrix_allowed_now"] is False
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["decision"]["natural_battle_allowed_now"] is False
    assert payload["decision"]["promotion_allowed"] is False


def test_wrong_route_blocks_contract_written_flag():
    payload = _build(post_safe_cut_route=_route(selected=False))

    assert payload["summary"]["decision_status"] == (
        "topdeck_access_first_sidecar_contract_blocked_wrong_route_keep_607"
    )
    assert payload["summary"]["contract_written"] is False
    assert payload["summary"]["recommended_next_action"] == (
        "rerun_post_safe_cut_route_before_sidecar_contract"
    )


def test_missing_input_blocks_and_reports_missing_source():
    payload = _build(trace_evidence={})

    assert payload["summary"]["decision_status"] == (
        "topdeck_access_first_sidecar_contract_inputs_missing_keep_607"
    )
    assert payload["summary"]["contract_written"] is False
    assert payload["summary"]["missing_inputs"] == ["trace_evidence"]


def test_markdown_surfaces_drc_staples_and_607_protection():
    markdown = contract.render_markdown(_build())

    assert "Deck 607 mutated: `false`" in markdown
    assert "Dragon's Rage Channeler" in markdown
    assert "Mana Vault" in markdown
    assert "The One Ring" in markdown
    assert "607 land floor: `34`" in markdown
    assert "Candidate deck materialization allowed now: `false`" in markdown
