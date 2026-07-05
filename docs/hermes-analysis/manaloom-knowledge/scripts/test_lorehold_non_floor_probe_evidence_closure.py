from pathlib import Path

import lorehold_non_floor_probe_evidence_closure as closure


def _planner():
    return {
        "summary": {
            "named_cut_probe_count": 3,
            "floor_trace_blocked_probe_count": 1,
            "floor_trace_cut_blocker_count": 6,
        },
        "cut_model_targets": [
            {
                "add_card": "Penance",
                "sidecar_tag": "topdeck_access_sidecar_primary",
                "candidate_cut_probes": [
                    {
                        "cut_card": "Artist's Talent",
                        "cut_value_tier": "tier_3_role_filler_with_battle_context",
                        "cut_value_score": 10,
                        "floor_trace_blocked": False,
                        "blockers": ["requires_exposure_trace_before_safe_cut"],
                    },
                    {
                        "cut_card": "Rise of the Eldrazi",
                        "cut_value_tier": "tier_1_structural_floor",
                        "cut_value_score": 90,
                        "floor_trace_blocked": True,
                        "blockers": ["floor_trace_cut_blocked"],
                    },
                ],
            },
            {
                "add_card": "Plateau",
                "sidecar_tag": "mana_base_safe_cut_model",
                "candidate_cut_probes": [
                    {
                        "cut_card": "Mountain // Mountain",
                        "cut_value_tier": "tier_1_structural_floor",
                        "cut_value_score": 18,
                        "floor_trace_blocked": False,
                        "blockers": ["mana_source_floor_equivalence_required"],
                    }
                ],
            },
        ],
    }


def _probe_evidence():
    return {
        "summary": {
            "probe_row_count": 2,
            "safe_cut_ready_count": 0,
            "matrix_candidate_row_eligible_count": 0,
            "blocked_exposed_topdeck_role_probe_count": 1,
            "blocked_generic_mana_probe_count": 1,
            "mana_route_status": "mana_route_closed_by_exact_decisions",
            "mana_model_exact_rejected_pair_count": 2,
            "mana_model_eligible_pair_count": 0,
        },
        "probe_evidence_rows": [
            {
                "add_card": "Penance",
                "target_tag": "topdeck_access_sidecar_primary",
                "cut_card": "Artist's Talent",
                "evidence_status": "blocked_exposed_topdeck_role_probe",
                "safe_cut_ready_now": False,
                "matrix_candidate_row_eligible_now": False,
                "candidate_deck_materialization_allowed_now": False,
                "next_action": "do not turn probe into cut",
                "blockers": ["probe_cut_has_material_exposure"],
            },
            {
                "add_card": "Plateau",
                "target_tag": "mana_base_safe_cut_model",
                "cut_card": "Mountain // Mountain",
                "evidence_status": "blocked_generic_mana_probe_not_pair_safe",
                "safe_cut_ready_now": False,
                "matrix_candidate_row_eligible_now": False,
                "candidate_deck_materialization_allowed_now": False,
                "next_action": "use dedicated mana model",
                "blockers": ["basic_land_floor_not_safe_from_probe"],
            },
        ],
    }


def _current_best():
    return {
        "summary": {
            "decision_status": "current_best_baseline_synthesis_keep_607",
            "top_deck_is_607": True,
        }
    }


def _paths():
    return {
        "cut_model_planner": Path("/tmp/planner.json"),
        "probe_evidence": Path("/tmp/probe.json"),
        "current_best": Path("/tmp/current.json"),
    }


def _build(**overrides):
    return closure.build_report(
        cut_model_planner=overrides.get("cut_model_planner", _planner()),
        probe_evidence=overrides.get("probe_evidence", _probe_evidence()),
        current_best=overrides.get("current_best", _current_best()),
        paths=_paths(),
    )


def test_closes_non_floor_probe_route_without_safe_cut_or_battle_gate():
    payload = _build()

    assert payload["status"] == "non_floor_probe_evidence_closure_closed_no_matrix_rows_keep_607"
    assert payload["summary"]["non_floor_probe_count"] == 2
    assert payload["summary"]["missing_probe_evidence_row_count"] == 0
    assert payload["summary"]["non_floor_safe_cut_ready_count"] == 0
    assert payload["summary"]["non_floor_matrix_candidate_row_eligible_count"] == 0
    assert payload["summary"]["blocked_exposed_topdeck_role_probe_count"] == 1
    assert payload["summary"]["blocked_generic_mana_probe_count"] == 1
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["decision"]["deck_action_allowed"] is False
    assert payload["decision"]["matrix_candidate_rows_ready"] is False


def test_missing_non_floor_probe_evidence_keeps_route_open():
    probe_evidence = _probe_evidence()
    probe_evidence["probe_evidence_rows"] = probe_evidence["probe_evidence_rows"][:1]
    payload = _build(probe_evidence=probe_evidence)

    assert payload["status"] == "non_floor_probe_evidence_closure_missing_evidence_keep_607"
    assert payload["summary"]["missing_probe_evidence_row_count"] == 1
    assert payload["decision"]["deck_action_allowed"] is False


def test_reviewable_probe_row_is_matrix_only_and_still_blocks_deck_action():
    probe_evidence = _probe_evidence()
    probe_evidence["probe_evidence_rows"][0]["safe_cut_ready_now"] = True
    probe_evidence["probe_evidence_rows"][0]["matrix_candidate_row_eligible_now"] = True
    payload = _build(probe_evidence=probe_evidence)

    assert payload["status"] == "non_floor_probe_evidence_closure_reviewable_rows_matrix_only"
    assert payload["summary"]["non_floor_safe_cut_ready_count"] == 1
    assert payload["summary"]["non_floor_matrix_candidate_row_eligible_count"] == 1
    assert payload["decision"]["matrix_candidate_rows_ready"] is True
    assert payload["decision"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["decision"]["natural_battle_allowed_now"] is False


def test_markdown_surfaces_closure_and_no_natural_battle_gate():
    markdown = closure.render_markdown(_build())

    assert "Non-floor probes: `2`" in markdown
    assert "Safe-cut ready: `0`" in markdown
    assert "Natural battle gate allowed now: `false`" in markdown
    assert "define_new_shell_contract_or_new_cut_evidence_before_any_battle_gate" in markdown
