from pathlib import Path

import lorehold_brain_safe_cut_gap_audit as audit


def _preflight(*, safe=False):
    rows = [
        {
            "card_name": "Scroll Rack",
            "lanes": ["artifact", "draw", "topdeck_miracle_engine"],
            "value_score": 150,
            "protected_anchor": True,
            "unique_exposure_count": 2957,
            "direct_event_count": 2745,
            "scout_status": "blocked_current_607_hard_stop",
            "blockers": ["protected_cut", "measured_high_cut_exposure"],
        },
        {
            "card_name": "Molecule Man",
            "lanes": ["draw", "topdeck_miracle_engine"],
            "value_score": 150,
            "protected_anchor": True,
            "unique_exposure_count": 102,
            "direct_event_count": 101,
            "scout_status": "blocked_current_607_hard_stop",
            "blockers": ["prior_rejected_cut", "prior_rejected_cut_slot", "protected_cut"],
        },
        {
            "card_name": "Urza's Saga",
            "lanes": ["global_top_500", "land", "mana_base", "topdeck_miracle_engine"],
            "value_score": 74,
            "unique_exposure_count": 2656,
            "direct_event_count": 2656,
            "scout_status": "blocked_current_607_hard_stop",
            "blockers": ["mana_base_never_cut", "never_cut_lane"],
        },
        {
            "card_name": "Lorehold, the Historian",
            "lanes": ["commander_center", "topdeck_miracle_engine"],
            "value_score": 150,
            "unique_exposure_count": 5768,
            "direct_event_count": 5558,
            "scout_status": "blocked_current_607_hard_stop",
            "blockers": ["commander_never_cut"],
        },
    ]
    if safe:
        rows.append(
            {
                "card_name": "Brainstone",
                "lanes": ["artifact", "topdeck_miracle_engine"],
                "value_score": 60,
                "unique_exposure_count": 1,
                "direct_event_count": 0,
                "scout_status": "safe_same_lane_cut_candidate",
                "blockers": [],
            }
        )
    return {
        "summary": {
            "brain_active_rule_count": 0,
            "same_lane_candidate_count": len(rows),
            "safe_cut_count": int(safe),
        },
        "same_lane_cut_rows": rows,
    }


def _package(*, active_rules=0, ready=True, applied=False):
    return {
        "status": "prepared_read_only_pending_apply_approval",
        "summary": {
            "apply_ready_for_manual_review": ready,
            "apply_executed_by_this_script": applied,
            "runtime_preflight_status": audit.TARGET_RUNTIME_PREFLIGHT_STATUS,
            "runtime_preflight_route_gate_valid": True,
            "runtime_preflight_route_planner_status": audit.TARGET_ROUTE_PLANNER_STATUS,
            "runtime_preflight_candidate_queue_governed": True,
            "runtime_preflight_candidate_queue_next_shell_status": audit.TARGET_NEXT_SHELL_STATUS,
            "runtime_preflight_candidate_queue_matrix_route_governed": True,
            "brain_active_rule_count_before_apply": active_rules,
            "brain_exact_adapter_present": True,
            "oracle_hash": "41468898bf6400763de517269fdeb456",
        },
    }


def _value_model():
    return {"summary": {"deck_id": 607, "quantity_total": 100}}


def _paths():
    return {
        "brain_preflight": Path("/tmp/brain_preflight.json"),
        "brain_pg_package": Path("/tmp/brain_pg_package.json"),
        "value_model": Path("/tmp/value_model.json"),
    }


def _build(**overrides):
    return audit.build_report(
        brain_preflight=overrides.get("brain_preflight", _preflight()),
        brain_pg_package=overrides.get("brain_pg_package", _package()),
        value_model=overrides.get("value_model", _value_model()),
        paths=_paths(),
    )


def test_current_like_state_blocks_brain_and_keeps_607() -> None:
    payload = _build()

    assert payload["postgres_writes"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["decision_status"] == (
        "brain_safe_cut_gap_no_active_rule_no_seed_safe_cut_keep_607"
    )
    assert payload["summary"]["safe_cut_count"] == 0
    assert payload["summary"]["brain_pg_package_route_governed"] is True
    assert payload["summary"]["runtime_preflight_route_gate_valid"] is True
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["decision"]["keep_607_as_protected_baseline"] is True


def test_active_rule_and_safe_cut_allow_only_matrix_not_battle() -> None:
    payload = _build(
        brain_preflight=_preflight(safe=True),
        brain_pg_package=_package(active_rules=1, applied=True),
    )

    assert payload["summary"]["decision_status"] == (
        "brain_safe_cut_gap_ready_for_candidate_matrix_no_battle"
    )
    assert payload["summary"]["safe_cut_count"] == 1
    assert payload["summary"]["matrix_scoring_allowed_now"] is True
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False


def test_ready_package_without_governed_route_blocks_pg_review_path() -> None:
    stale_package = _package()
    stale_package["summary"]["runtime_preflight_route_gate_valid"] = False

    payload = _build(brain_pg_package=stale_package)

    assert payload["summary"]["decision_status"] == (
        "brain_safe_cut_gap_pg_package_route_not_governed_keep_607"
    )
    assert payload["summary"]["brain_pg_package_route_governed"] is False
    assert payload["summary"]["recommended_next_action"] == (
        "rerun_governed_brain_runtime_and_package_preflight"
    )
    assert payload["summary"]["matrix_scoring_allowed_now"] is False


def test_external_brain_signal_is_low_context_not_staple_proof() -> None:
    payload = _build()

    assert payload["summary"]["external_signal_classification"] == (
        "low_context_signal_not_staple"
    )
    assert payload["decision"]["external_signal_is_staple_proof"] is False
    assert payload["summary"]["external_brain_global_inclusion_percent"] == 0.03
    assert payload["summary"]["external_brain_lorehold_inclusion_percent"] == 0.4


def test_lowest_exposure_prior_rejected_slot_remains_diagnostic_only() -> None:
    payload = _build()

    assert payload["summary"]["lowest_risk_diagnostic_cut_candidate"] == "Molecule Man"
    assert payload["summary"]["lowest_risk_diagnostic_cut_category"] == (
        "prior_rejected_protected_slot"
    )
    assert payload["summary"]["lowest_risk_diagnostic_allowed_now"] is False
    candidate = payload["lowest_risk_diagnostic_candidate"]
    assert "new_trace_evidence_reverses_prior_rejected_cut" in candidate["unlock_requirements"]


def test_markdown_surfaces_external_evidence_and_closed_gates() -> None:
    markdown = audit.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "Brain PG package route governed: `true`" in markdown
    assert audit.TARGET_ROUTE_PLANNER_STATUS in markdown
    assert "Natural battle gate allowed now: `false`" in markdown
    assert "Brain EDHREC global inclusion: `0.03%`" in markdown
    assert "https://edhrec.com/cards/brain-in-a-jar" in markdown
    assert "Molecule Man" in markdown
