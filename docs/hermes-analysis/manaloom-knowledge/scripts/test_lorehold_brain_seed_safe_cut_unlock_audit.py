from pathlib import Path

import lorehold_brain_seed_safe_cut_unlock_audit as audit


def _safe_cut_gap(*, active_rules=0, safe=False):
    rows = [
        {
            "card_name": "Molecule Man",
            "gap_category": "prior_rejected_protected_slot",
            "lanes": ["draw", "topdeck_miracle_engine"],
            "cut_lane": "draw",
            "functional_tag": "draw",
            "protected_anchor": True,
            "scout_status": "blocked_current_607_hard_stop",
            "blockers": ["prior_rejected_cut", "prior_rejected_cut_slot", "protected_cut"],
            "unique_exposure_count": 102,
            "direct_event_count": 101,
            "value_score": 150,
            "value_tier": "tier_0_protected_engine_or_anchor",
        },
        {
            "card_name": "Scroll Rack",
            "gap_category": "protected_core_topdeck_engine",
            "lanes": ["artifact", "draw", "topdeck_miracle_engine"],
            "cut_lane": "early_mana",
            "functional_tag": "draw",
            "protected_anchor": True,
            "scout_status": "blocked_current_607_hard_stop",
            "blockers": ["protected_cut", "measured_high_cut_exposure"],
            "unique_exposure_count": 2957,
            "direct_event_count": 2745,
            "value_score": 150,
        },
        {
            "card_name": "The Mind Stone",
            "gap_category": "protected_structural_floor",
            "lanes": ["artifact", "ramp", "topdeck_miracle_engine"],
            "cut_lane": "early_mana",
            "functional_tag": "ramp",
            "protected_anchor": True,
            "scout_status": "blocked_current_607_hard_stop",
            "blockers": ["cut_is_early_mana_floor_support"],
            "unique_exposure_count": 2312,
            "direct_event_count": 2266,
            "value_score": 150,
        },
        {
            "card_name": "Urza's Saga",
            "gap_category": "never_cut_mana_base",
            "lanes": ["land", "mana_base", "topdeck_miracle_engine"],
            "cut_lane": "mana_base",
            "functional_tag": "land",
            "scout_status": "blocked_current_607_hard_stop",
            "blockers": ["mana_base_never_cut", "never_cut_lane"],
            "unique_exposure_count": 2656,
            "direct_event_count": 2656,
            "value_score": 74,
        },
        {
            "card_name": "Lorehold, the Historian",
            "gap_category": "never_cut_commander",
            "lanes": ["commander_center", "topdeck_miracle_engine"],
            "cut_lane": "commander",
            "functional_tag": "engine",
            "scout_status": "blocked_current_607_hard_stop",
            "blockers": ["commander_never_cut"],
            "unique_exposure_count": 5768,
            "direct_event_count": 5558,
            "value_score": 230,
        },
    ]
    if safe:
        rows.append(
            {
                "card_name": "Brainstone",
                "gap_category": "seed_safe_same_lane_candidate",
                "lanes": ["artifact", "topdeck_miracle_engine"],
                "cut_lane": "artifact",
                "functional_tag": "engine",
                "scout_status": "safe_same_lane_cut_candidate",
                "blockers": [],
                "unique_exposure_count": 1,
                "direct_event_count": 0,
                "value_score": 40,
            }
        )
    return {
        "summary": {
            "decision_status": "brain_safe_cut_gap_no_active_rule_no_seed_safe_cut_keep_607",
            "brain_pg_package_status": "prepared_read_only_pending_apply_approval",
            "brain_active_rule_count": active_rules,
            "apply_ready_for_manual_review": True,
            "apply_executed_by_this_script": False,
            "brain_pg_package_route_governed": True,
            "safe_cut_count": int(safe),
            "blocked_same_lane_cut_count": len(rows) - int(safe),
            "matrix_scoring_allowed_now": bool(safe and active_rules),
        },
        "same_lane_cut_rows": rows,
    }


def _floor_trace():
    return {
        "summary": {
            "decision_status": "gap_floor_trace_miner_found_floor_evidence_keep_607",
            "target_with_floor_trace_count": 1,
        },
        "target_floor_summaries": [
            {
                "card_name": "The Mind Stone",
                "floor_trace_status": "floor_trace_found_cut_blocked",
                "same_slot_607_win_candidate_loss_trace_count": 12,
                "positive_target_delta_trace_count": 8,
            }
        ],
    }


def _all_floor_trace():
    return {
        "summary": {
            "decision_status": "brain_cut_slot_trace_miner_found_floor_evidence_keep_607",
            "target_with_floor_trace_count": 5,
        },
        "target_floor_summaries": [
            {
                "card_name": name,
                "floor_trace_status": "brain_cut_slot_floor_trace_found_cut_blocked",
                "same_slot_607_win_candidate_loss_trace_count": 3,
                "positive_target_delta_trace_count": 2,
            }
            for name in [
                "Molecule Man",
                "Scroll Rack",
                "The Mind Stone",
                "Urza's Saga",
                "Lorehold, the Historian",
            ]
        ],
    }


def _current_best():
    return {
        "summary": {
            "decision_status": "current_best_baseline_synthesis_keep_607",
            "top_deck_is_607": True,
            "protected_baseline_rank": 1,
        }
    }


def _paths():
    return {
        "safe_cut_gap": Path("/tmp/safe_cut_gap.json"),
        "cut_slot_trace": Path("/tmp/cut_slot_trace.json"),
        "current_best": Path("/tmp/current_best.json"),
    }


def _build(**overrides):
    return audit.build_report(
        safe_cut_gap=overrides.get("safe_cut_gap", _safe_cut_gap()),
        cut_slot_trace=overrides.get("cut_slot_trace", _floor_trace()),
        current_best=overrides.get("current_best", _current_best()),
        paths=_paths(),
    )


def _rows_by_name(payload):
    return {row["card_name"]: row for row in payload["unlock_rows"]}


def test_current_like_state_keeps_607_and_unlocks_no_brain_cut() -> None:
    payload = _build()

    assert payload["postgres_writes"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["decision_status"] == (
        "brain_seed_safe_cut_unlock_audit_closed_no_unlockable_cut_keep_607"
    )
    assert payload["summary"]["unlockable_now_count"] == 0
    assert payload["summary"]["current_best_top_deck_is_607"] is True
    assert payload["summary"]["matrix_scoring_allowed_now"] is False
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["decision"]["keep_607_as_protected_baseline"] is True


def test_prior_rejected_molecule_man_is_diagnostic_only() -> None:
    payload = _build()
    rows = _rows_by_name(payload)

    molecule = rows["Molecule Man"]
    assert molecule["unlock_class"] == "diagnostic_only_prior_reject_requires_new_trace"
    assert "new_trace_evidence_reverses_prior_rejected_cut" in molecule["missing_evidence"]
    assert "targeted_floor_trace_for_this_cut_slot" in molecule["missing_evidence"]
    assert molecule["can_unlock_now"] is False
    assert payload["summary"]["diagnostic_focus_card"] == "Molecule Man"


def test_topdeck_anchor_and_structural_floor_get_different_requirements() -> None:
    payload = _build()
    rows = _rows_by_name(payload)

    scroll = rows["Scroll Rack"]
    assert scroll["unlock_class"] == "protected_topdeck_anchor_requires_role_preservation"
    assert "replacement_preserves_topdeck_miracle_anchor_role" in scroll["missing_evidence"]

    mind_stone = rows["The Mind Stone"]
    assert mind_stone["unlock_class"] == "protected_floor_requires_floor_replacement_trace"
    assert "replacement_preserves_mana_or_curve_floor" in mind_stone["missing_evidence"]
    assert mind_stone["floor_trace_available"] is True
    assert mind_stone["floor_trace_count"] == 12


def test_never_cut_slots_cannot_unlock_under_current_contract() -> None:
    payload = _build()
    rows = _rows_by_name(payload)

    assert rows["Lorehold, the Historian"]["unlock_class"] == (
        "locked_no_unlock_current_607_contract"
    )
    assert rows["Lorehold, the Historian"]["missing_evidence"] == [
        "cannot_unlock_under_current_607_contract"
    ]
    assert rows["Urza's Saga"]["unlock_class"] == "locked_no_unlock_current_607_contract"


def test_safe_row_with_active_rule_allows_matrix_only_not_battle() -> None:
    payload = _build(safe_cut_gap=_safe_cut_gap(active_rules=1, safe=True))

    assert payload["summary"]["decision_status"] == (
        "brain_seed_safe_cut_unlock_audit_reviewable_cut_exists_matrix_only"
    )
    assert payload["summary"]["unlockable_now_count"] == 1
    assert payload["summary"]["matrix_scoring_allowed_now"] is True
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False


def test_all_slots_with_trace_moves_next_action_to_cut_discovery_or_pg_review() -> None:
    payload = _build(cut_slot_trace=_all_floor_trace())

    assert payload["summary"]["targeted_floor_trace_missing_slot_count"] == 0
    assert payload["summary"]["recommended_next_action"] == (
        "continue_seed_safe_cut_discovery_or_request_explicit_brain_pg_apply_review_no_deck_action"
    )
    assert "use_brain_cut_slot_traces_as_cut_protection_evidence" in payload["decision"]["next_actions"]
    assert payload["summary"]["unlockable_now_count"] == 0


def test_markdown_surfaces_unlock_queue_and_external_lessons() -> None:
    markdown = audit.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "Brain safe-cut gap status" in markdown
    assert "Molecule Man" in markdown
    assert "diagnostic_only_prior_reject_requires_new_trace" in markdown
    assert "EDHREC Lorehold commander page" in markdown
    assert "Natural battle gate allowed now: `false`" in markdown
