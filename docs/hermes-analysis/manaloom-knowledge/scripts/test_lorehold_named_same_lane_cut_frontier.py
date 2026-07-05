from pathlib import Path

import lorehold_named_same_lane_cut_frontier as frontier


def _sidecar_contract():
    return {
        "summary": {
            "contract_key": frontier.TARGET_CONTRACT,
            "decision_status": "topdeck_access_first_sidecar_contract_written_no_matrix_rows_keep_607",
        },
        "contract": {
            "blocked_staple_policy": [
                {
                    "card": "Mana Vault",
                    "lane": "early_mana_and_spell_chain_conversion",
                    "current_policy": "learning_only_not_607_change",
                },
                {
                    "card": "The One Ring",
                    "lane": "draw_and_resource_density",
                    "current_policy": "learning_only_not_607_change",
                },
            ]
        },
    }


def _probe_evidence(*, ready=False):
    topdeck_probe = {
        "add_card": "Dragon's Rage Channeler",
        "target_tag": "topdeck_access_sidecar_primary",
        "cut_card": "Artist's Talent",
        "evidence_status": "reviewable_low_exposure_probe_needs_floor_test"
        if ready
        else "blocked_exposed_topdeck_role_probe",
        "safe_cut_ready_now": ready,
        "matrix_candidate_row_eligible_now": ready,
        "exposure": {
            "unique_exposure_count": 1 if ready else 535,
            "inferred_role": "runtime_ready_unexposed" if ready else "draw_filter_value",
        },
        "blockers": [] if ready else ["probe_cut_has_material_exposure"],
    }
    mana_probe = {
        "add_card": "Plateau",
        "target_tag": "mana_base_safe_cut_model",
        "cut_card": "Mountain // Mountain",
        "evidence_status": "blocked_generic_mana_probe_not_pair_safe",
        "safe_cut_ready_now": False,
        "matrix_candidate_row_eligible_now": False,
        "exposure": {"unique_exposure_count": 402, "inferred_role": "runtime_ready_unexposed"},
        "blockers": ["basic_land_floor_not_safe_from_probe"],
    }
    return {
        "summary": {
            "probe_row_count": 2,
            "safe_cut_ready_count": 1 if ready else 0,
            "matrix_candidate_row_eligible_count": 1 if ready else 0,
        },
        "probe_evidence_rows": [topdeck_probe, mana_probe],
    }


def _nonanchor():
    return {
        "summary": {
            "primary_target": "Dragon's Rage Channeler",
            "primary_target_model_status": "clean_prior_target_blocked_no_nonanchor_cut",
        },
        "target_cut_models": [
            {
                "card_name": "Dragon's Rage Channeler",
                "model_status": "clean_prior_target_blocked_no_nonanchor_cut",
                "same_lane_slot_count": 6,
                "seed_safe_nonanchor_count": 0,
                "reviewable_nonanchor_gap_count": 0,
                "prior_reject_count": 0,
            }
        ],
    }


def _integrator(*, eligible=False):
    pair = {
        "add": "Plateau",
        "cut": "Radiant Summit",
        "pair_score": 52,
        "learning_status": "eligible_for_materialization_after_prior_decision_filter"
        if eligible
        else "blocked_exact_tested_decision",
        "decision_status": "reject_promotion_keep_607_current_baseline",
        "next_action": "do_not_retest_exact_pair_without_new_mana_trace_evidence",
    }
    return {
        "summary": {
            "eligible_model_ready_pair_count": 1 if eligible else 0,
            "exact_rejected_pair_count": 0 if eligible else 1,
        },
        "annotated_model_ready_pairs": [pair],
    }


def _paths():
    return {
        "sidecar_contract": Path("/tmp/contract.json"),
        "probe_evidence": Path("/tmp/probe.json"),
        "nonanchor_cut_model": Path("/tmp/nonanchor.json"),
        "mana_decision_integrator": Path("/tmp/integrator.json"),
    }


def _build(**overrides):
    return frontier.build_report(
        sidecar_contract=overrides.get("sidecar_contract", _sidecar_contract()),
        probe_evidence=overrides.get("probe_evidence", _probe_evidence()),
        nonanchor_cut_model=overrides.get("nonanchor_cut_model", _nonanchor()),
        mana_decision_integrator=overrides.get("mana_decision_integrator", _integrator()),
        paths=_paths(),
    )


def test_current_like_frontier_is_closed_and_keeps_607_protected():
    payload = _build()

    assert payload["status"] == "named_same_lane_cut_frontier_closed_no_safe_cut_keep_607"
    assert payload["postgres_writes"] is False
    assert payload["source_db_mutated"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["structure_matrix_contract_allowed_now"] is False
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["summary"]["mana_exact_rejected_pair_count"] == 1
    assert payload["decision"]["deck_action_allowed"] is False


def test_ready_probe_or_eligible_mana_pair_only_opens_structure_contract():
    payload = _build(
        probe_evidence=_probe_evidence(ready=True),
        mana_decision_integrator=_integrator(eligible=True),
    )

    assert payload["status"] == "named_same_lane_cut_frontier_has_structure_contract_rows_no_deck"
    assert payload["summary"]["structure_matrix_contract_allowed_now"] is True
    assert payload["summary"]["structure_matrix_allowed_now"] is False
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["decision"]["natural_battle_allowed_now"] is False
    assert payload["decision"]["promotion_allowed"] is False


def test_missing_input_blocks_frontier():
    payload = _build(probe_evidence={})

    assert payload["status"] == "named_same_lane_cut_frontier_inputs_missing_keep_607"
    assert payload["summary"]["missing_inputs"] == ["probe_evidence"]
    assert payload["summary"]["structure_matrix_contract_allowed_now"] is False


def test_markdown_surfaces_drc_plateau_and_blocked_staples():
    markdown = frontier.render_markdown(_build())

    assert "Deck 607 mutated: `false`" in markdown
    assert "Dragon's Rage Channeler" in markdown
    assert "Plateau" in markdown
    assert "Radiant Summit" in markdown
    assert "Mana Vault" in markdown
    assert "The One Ring" in markdown
    assert "Candidate deck materialization allowed now: `false`" in markdown
