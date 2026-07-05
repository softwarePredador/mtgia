from pathlib import Path

import lorehold_next_shell_contract_synthesis as synthesis


def _current_best(*, keep=True):
    return {
        "status": "current_best_baseline_synthesis_keep_607" if keep else "blocked",
        "summary": {
            "top_deck_is_607": keep,
            "current_positive_signal_count": 0 if keep else 1,
        },
    }


def _value_model(*, lands=34, ramp=15):
    return {
        "summary": {
            "mana_foundation": {
                "land_quantity": lands,
                "ramp_quantity": ramp,
                "mana_sources_land_plus_ramp": lands + ramp,
                "artifact_ramp_quantity": 11,
                "instant_sorcery_ramp_quantity": 3,
                "land_groups": {"basic_floor": 8},
            },
            "role_profile": {"land": lands, "ramp": ramp},
            "lane_profile": {"topdeck_miracle_engine": 9},
        }
    }


def _engine_contract(*, ready=False, cuts=0, include_route=True):
    target_route = (
        synthesis.TARGET_ROUTE_KEY
        if include_route
        else "different_route"
    )
    return {
        "summary": {
            "decision_status": "hypothesis_contract_ready_for_structure_matrix"
            if ready
            else "hypothesis_contract_written_blocked_no_named_safe_cuts",
            "target_route_key": target_route,
            "target_adds": ["Guttersnipe", "Storm-Kiln Artist"],
            "required_cut_count": 2,
            "available_named_seed_safe_cut_count": cuts,
            "structure_matrix_allowed_now": ready,
        },
        "candidate_package_contract": {
            "adds": ["Guttersnipe", "Storm-Kiln Artist"],
        },
        "route_evidence": {
            "blockers": [
                "no_current_positive_guttersnipe_trace",
                "pressure_conversion_unproven",
                "storm_kiln_arcane_signet_swap_rejected",
            ]
        },
    }


def _staples():
    return {
        "cards": [
            {
                "card_name": "Mana Vault",
                "app_accessibility_label": "rules_accessible_collection_missing_promotion_blocked",
                "collection": {"owned": False},
                "external": {"commander_legal": True, "game_changer": True},
                "hypothesis": {"readiness_status": "blocked_prior_reject"},
                "promotion": {"decision": "blocked_prior_gate_rejected"},
                "next_action": "do_not_offer_as_available_deck_change_until_collection_and_new_cut_trace_exist",
            },
            {
                "card_name": "The One Ring",
                "app_accessibility_label": "rules_collection_accessible_promotion_blocked",
                "collection": {"owned": True},
                "external": {"commander_legal": True, "game_changer": True},
                "hypothesis": {"readiness_status": "blocked_prior_reject"},
                "promotion": {"decision": "blocked_existing_package_rejected"},
                "next_action": "show_owned_but_blocked_prior_reject_and_require_new_same_lane_trace",
            },
        ],
        "summary": {"promotion_blocked_count": 2},
    }


def _sidecar():
    return {
        "summary": {
            "safe_cut_ready_count": 0,
            "matrix_candidate_row_eligible_count": 0,
            "floor_trace_cut_blocker_names": [
                "Call Forth the Tempest",
                "Esper Sentinel",
                "Everything Comes to Dust",
                "Hit the Mother Lode",
                "Rise of the Eldrazi",
                "Surge to Victory",
            ],
        }
    }


def _floor_miner():
    return {"target_floor_summaries": []}


def _artifact_audit(*, pass_status=True):
    return {
        "summary": {"artifact_count": 958, "unknown_or_invalid_count": 0 if pass_status else 1},
        "continuation_gate": {
            "artifact_contract_status": "pass" if pass_status else "fail",
        },
    }


def _cut_miner(*, closed=False):
    if not closed:
        return {}
    return {
        "status": "no_current_cut_evidence_for_guttersnipe_storm_kiln_keep_607",
        "summary": {
            "decision_status": "no_current_cut_evidence_for_guttersnipe_storm_kiln_keep_607",
            "named_seed_safe_cut_count": 0,
            "target_lane_evidence_gap_count": 0,
            "hard_stop_cut_count": 94,
            "total_cut_slots_reviewed": 94,
            "recommended_next_action": "do_not_battle_mine_new_nonanchor_trace_or_new_shell_contract",
        },
    }


def _closing_router():
    return {
        "summary": {
            "decision_status": "closing_window_shell_target_selected_no_battle",
            "selected_hypothesis_key": "preserve_topdeck_miracle_floor_micro_package",
            "recommended_next_action": "write_miracle_access_first_shell_contract_no_battle",
        }
    }


def _miracle_access_contract():
    return {
        "summary": {
            "decision_status": "miracle_access_first_contract_written_no_battle_blocked_before_structure_matrix",
            "selected_contract_key": "miracle_access_first_shell_contract",
            "selected_hypothesis_key": "preserve_topdeck_miracle_floor_micro_package",
            "recommended_next_action": "design_micro_shell_structure_matrix_contract_no_battle",
            "structure_matrix_contract_allowed_now": True,
            "structure_matrix_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
        },
        "contract": {
            "contract_key": "miracle_access_first_shell_contract",
            "target_metrics_from_router": ["miracle_cast", "topdeck_manipulation_activated"],
            "event_floor_requirements": [
                {"requirement_key": "miracle_cast_floor", "metric": "miracle_cast"}
            ],
            "protected_anchors": ["Sensei's Divining Top", "Scroll Rack"],
            "blocked_shortcuts": [
                {"shortcut_key": "pressure_conversion_blocked_until_miracle_floor"}
            ],
        },
    }


def _paths():
    return {
        "current_best": Path("/tmp/current.json"),
        "value_model": Path("/tmp/value.json"),
        "engine_contract": Path("/tmp/engine.json"),
        "staple_accessibility": Path("/tmp/staples.json"),
        "sidecar_cut_planner": Path("/tmp/sidecar.json"),
        "gap_floor_trace_miner": Path("/tmp/floor.json"),
        "artifact_audit": Path("/tmp/artifact.json"),
        "cut_miner": Path("/tmp/cut_miner.json"),
        "closing_router": Path("/tmp/closing_router.json"),
        "miracle_access_contract": Path("/tmp/miracle_access.json"),
    }


def _build(**overrides):
    args = {
        "current_best": _current_best(),
        "value_model": _value_model(),
        "engine_contract": _engine_contract(),
        "staple_accessibility": _staples(),
        "sidecar_cut_planner": _sidecar(),
        "gap_floor_trace_miner": _floor_miner(),
        "artifact_audit": _artifact_audit(),
        "cut_miner": {},
        "closing_router": {},
        "miracle_access_contract": {},
        "paths": _paths(),
    }
    args.update(overrides)
    return synthesis.build_report(**args)


def test_current_next_shell_is_learning_only_and_keeps_607():
    payload = _build()

    assert payload["status"] == "next_shell_contract_written_not_materializable_keep_607"
    assert payload["postgres_writes"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["land_quantity_floor"] == 34
    assert payload["summary"]["ramp_quantity_floor"] == 15
    assert payload["summary"]["available_named_seed_safe_cut_count"] == 0
    assert payload["summary"]["cut_shortage"] == 2
    assert payload["decision"]["deck_action_allowed"] is False
    assert payload["decision"]["candidate_deck_materialization_allowed_now"] is False


def test_shell_surfaces_staples_as_learning_only_not_accessible_deck_actions():
    payload = _build()
    labels = {
        row["card_name"]: row["app_accessibility_label"]
        for row in payload["shell_contract"]["learning_only_staples"]
    }

    assert labels["Mana Vault"] == "rules_accessible_collection_missing_promotion_blocked"
    assert labels["The One Ring"] == "rules_collection_accessible_promotion_blocked"


def test_synthetic_ready_shell_allows_structure_matrix_but_not_deck_action():
    payload = _build(engine_contract=_engine_contract(ready=True, cuts=2))

    assert payload["status"] == "next_shell_contract_ready_for_structure_matrix_not_deck_action"
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is True
    assert payload["summary"]["structure_matrix_allowed_now"] is True
    assert payload["summary"]["deck_action_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False


def test_closed_engine_cut_path_routes_to_miracle_access_first_contract():
    payload = _build(
        cut_miner=_cut_miner(closed=True),
        closing_router=_closing_router(),
        miracle_access_contract=_miracle_access_contract(),
    )

    assert payload["status"] == "next_shell_cut_path_closed_route_miracle_access_first_keep_607"
    assert payload["summary"]["engine_cut_path_closed"] is True
    assert payload["summary"]["engine_cut_path_hard_stop_cut_count"] == 94
    assert payload["summary"]["fallback_route_key"] == "miracle_access_first_shell_contract"
    assert payload["summary"]["fallback_structure_matrix_contract_allowed_now"] is True
    assert payload["summary"]["recommended_next_action"] == (
        "design_micro_shell_structure_matrix_contract_no_battle"
    )
    assert payload["decision"]["deck_action_allowed"] is False
    assert payload["decision"]["candidate_deck_materialization_allowed_now"] is False


def test_contract_blocks_when_current_best_no_longer_keeps_607():
    payload = _build(current_best=_current_best(keep=False))

    assert payload["validation"]["status"] == "fail"
    assert "current-best synthesis does not keep deck_607" in payload["validation"]["errors"]
    assert payload["status"] == "next_shell_contract_blocked_review_required"


def test_contract_blocks_when_mana_floor_is_not_protected_baseline():
    payload = _build(value_model=_value_model(lands=33, ramp=15))

    assert payload["validation"]["status"] == "fail"
    assert (
        "value model mana floor is not the protected 34 land / 15 ramp baseline"
        in payload["validation"]["errors"]
    )


def test_markdown_surfaces_external_learning_and_no_mutation():
    markdown = synthesis.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "Mana Vault" in markdown
    assert "The One Ring" in markdown
    assert "https://magic.wizards.com/en/banned-restricted-list" in markdown
