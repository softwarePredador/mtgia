from pathlib import Path

import lorehold_post_named_frontier_next_evidence_router as router


def _non_floor():
    return {
        "status": "non_floor_probe_evidence_closure_closed_no_matrix_rows_keep_607",
        "summary": {
            "non_floor_probe_count": 48,
            "non_floor_safe_cut_ready_count": 0,
            "non_floor_matrix_candidate_row_eligible_count": 0,
            "blocked_generic_mana_probe_count": 28,
        },
    }


def _named(*, matrix_ready=False):
    return {
        "status": (
            "named_same_lane_cut_frontier_has_structure_contract_rows_no_deck"
            if matrix_ready
            else "named_same_lane_cut_frontier_closed_no_safe_cut_keep_607"
        ),
        "summary": {
            "topdeck_matrix_ready_probe_count": 1 if matrix_ready else 0,
            "mana_eligible_pair_count": 0,
            "structure_matrix_contract_allowed_now": matrix_ready,
        },
    }


def _collector():
    return {
        "summary": {
            "cut_safety_blocked_target_count": 5,
            "seed_safe_same_lane_count": 0,
            "microbenchmark_runnable_count": 0,
        }
    }


def _nonanchor():
    return {
        "summary": {
            "clean_prior_blocked_target_count": 1,
            "seed_safe_nonanchor_count": 0,
            "reviewable_nonanchor_gap_count": 0,
        },
        "target_cut_models": [
            {
                "card_name": "Dragon's Rage Channeler",
                "clean_prior_target": True,
                "model_status": "clean_prior_target_blocked_no_nonanchor_cut",
                "same_lane_slot_count": 6,
                "seed_safe_nonanchor_count": 0,
                "reviewable_nonanchor_gap_count": 0,
                "top_blocked_same_lane_slots": [
                    {
                        "card_name": "Call Forth the Tempest",
                        "lane": "spell_velocity",
                        "unique_exposure_count": 8,
                        "hard_stop_blockers": ["miracle_or_finisher_core"],
                    }
                ],
                "next_action": "mine_external_or_new_trace_evidence_for_nonanchor_cut",
            },
            {
                "card_name": "Penance",
                "clean_prior_target": False,
                "model_status": "prior_reject_target_blocked_no_nonanchor_cut",
            },
        ],
    }


def _mana():
    return {
        "summary": {
            "eligible_model_ready_pair_count": 0,
            "exact_rejected_pair_count": 2,
        },
        "annotated_model_ready_pairs": [
            {
                "add": "Plateau",
                "cut": "Radiant Summit",
                "learning_status": "blocked_exact_tested_decision",
                "decision_status": "reject_promotion_keep_607_current_baseline",
                "next_action": "do_not_retest_exact_pair_without_new_mana_trace_evidence",
                "decision_blockers": ["natural_smoke_lost_to_607"],
            }
        ],
    }


def _current_best():
    return {
        "status": "current_best_baseline_synthesis_keep_607",
        "summary": {
            "top_deck_is_607": True,
            "current_positive_signal_count": 0,
            "recommended_next_action": "define_new_shell_contract_or_new_cut_evidence_before_any_battle_gate",
        },
    }


def _staples():
    return {
        "cards": [
            {
                "card_name": "Mana Vault",
                "collection": {"owned": False},
                "external": {"commander_legal": True, "game_changer": True},
                "hypothesis": {"readiness_status": "blocked_prior_reject"},
                "promotion": {"decision": "blocked_prior_gate_rejected"},
                "next_action": "do_not_offer_as_available_deck_change",
            },
            {
                "card_name": "The One Ring",
                "collection": {"owned": True},
                "external": {"commander_legal": True, "game_changer": True},
                "hypothesis": {"readiness_status": "blocked_prior_reject"},
                "promotion": {"decision": "blocked_existing_package_rejected"},
                "next_action": "show_owned_but_blocked_prior_reject",
            },
        ]
    }


def _paths():
    return {
        "non_floor_closure": Path("/tmp/non_floor.json"),
        "named_frontier": Path("/tmp/named.json"),
        "topdeck_collector": Path("/tmp/collector.json"),
        "nonanchor_model": Path("/tmp/nonanchor.json"),
        "mana_integrator": Path("/tmp/mana.json"),
        "current_best": Path("/tmp/current_best.json"),
        "staple_accessibility": Path("/tmp/staples.json"),
    }


def _build(**overrides):
    return router.build_report(
        non_floor_closure=overrides.get("non_floor_closure", _non_floor()),
        named_frontier=overrides.get("named_frontier", _named()),
        topdeck_collector=overrides.get("topdeck_collector", _collector()),
        nonanchor_model=overrides.get("nonanchor_model", _nonanchor()),
        mana_integrator=overrides.get("mana_integrator", _mana()),
        current_best=overrides.get("current_best", _current_best()),
        staple_accessibility=overrides.get("staple_accessibility", _staples()),
        paths=_paths(),
    )


def test_current_closed_frontier_selects_topdeck_cut_evidence_scout_only():
    payload = _build()

    assert payload["status"] == "post_named_frontier_next_evidence_router_learning_only_keep_607"
    assert payload["summary"]["selected_next_route"] == "topdeck_new_cut_evidence_scout"
    assert payload["summary"]["non_floor_probe_count"] == 48
    assert payload["summary"]["topdeck_clean_prior_blocked_target_count"] == 1
    assert payload["summary"]["topdeck_seed_safe_nonanchor_count"] == 0
    assert payload["summary"]["mana_exact_rejected_pair_count"] == 2
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["decision"]["deck_action_allowed"] is False
    routes = {row["route_key"]: row for row in payload["evidence_routes"]}
    assert routes["topdeck_new_cut_evidence_scout"]["learning_allowed_now"] is True
    assert routes["topdeck_new_cut_evidence_scout"]["execution_allowed_now"] is False
    assert routes["topdeck_new_cut_evidence_scout"]["evidence"]["clean_prior_targets"][0]["card_name"] == (
        "Dragon's Rage Channeler"
    )


def test_matrix_ready_frontier_takes_precedence_without_opening_deck_action():
    payload = _build(named_frontier=_named(matrix_ready=True))

    assert payload["status"] == "post_named_frontier_next_evidence_router_matrix_contract_review_no_deck"
    assert payload["summary"]["selected_next_route"] == "structure_matrix_contract_review"
    assert payload["summary"]["deck_action_allowed_now"] is False
    assert payload["decision"]["natural_battle_allowed_now"] is False


def test_missing_inputs_blocks_route():
    payload = _build(non_floor_closure={})

    assert payload["status"] == "post_named_frontier_next_evidence_router_inputs_missing_keep_607"
    assert "non_floor_closure" in payload["summary"]["missing_inputs"]
    assert payload["summary"]["selected_next_route"] == "repair_missing_inputs_before_next_evidence_route"
    assert payload["decision"]["deck_action_allowed"] is False


def test_markdown_surfaces_clean_target_staples_and_closed_battle():
    markdown = router.render_markdown(_build())

    assert "Dragon's Rage Channeler" in markdown
    assert "Mana Vault" in markdown
    assert "The One Ring" in markdown
    assert "Natural battle gate allowed: `false`" in markdown
    assert "find_new_nonanchor_same_lane_cut_evidence_not_in_current_hard_blocked_slots" in markdown
