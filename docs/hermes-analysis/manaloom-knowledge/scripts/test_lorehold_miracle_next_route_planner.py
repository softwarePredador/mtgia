from pathlib import Path

import lorehold_miracle_next_route_planner as planner


def _post_identity(*, include_brain=True, include_entreat=True, include_haze=True):
    rows = []
    if include_brain:
        rows.append(
            {
                "card_name": "Brain in a Jar",
                "lane": "topdeck_miracle_access",
                "priority_rank": 1,
                "route_class": "runtime_or_manual_review",
                "required_contract": "single_card_runtime_contract_then_cut_safety",
                "deckbuilding_value": "charge counter and free-cast timing lesson",
                "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
                "battle_ready_now": False,
                "in_607": False,
            }
        )
    if include_entreat:
        rows.append(
            {
                "card_name": "Entreat the Angels",
                "lane": "miracle_finisher",
                "priority_rank": 1,
                "route_class": "runtime_or_manual_review",
                "required_contract": "miracle_token_runtime_contract_then_cut_safety",
                "deckbuilding_value": "miracle token finisher",
                "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
                "battle_ready_now": False,
                "in_607": False,
            }
        )
    if include_haze:
        rows.append(
            {
                "card_name": "Haze of Rage",
                "lane": "storm_combo_pressure",
                "priority_rank": 2,
                "route_class": "combo_runtime_contract",
                "required_contract": "combo_runtime_contract_with_storm_kiln_artist",
                "deckbuilding_value": "storm combo pressure package",
                "blockers": [
                    "verified_battle_rule_missing",
                    "combo_runtime_required",
                    "named_safe_cut_missing",
                ],
                "battle_ready_now": False,
                "in_607": False,
            }
        )
    rows.append(
        {
            "card_name": "Burning Prophet",
            "lane": "spell_scry_pressure",
            "priority_rank": 3,
            "route_class": "runtime_or_manual_review",
            "required_contract": "spell_trigger_runtime_review_then_diagnostic_cut_check",
            "deckbuilding_value": "cheap spell velocity",
            "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
            "battle_ready_now": False,
            "in_607": False,
        }
    )
    return {"summary": {"queue_card_count": len(rows)}, "cards": rows}


def _runtime_contract():
    return {
        "summary": {"runtime_contract_count": 3},
        "contracts": [
            {
                "card_name": "Entreat the Angels",
                "active_rule_count": 0,
                "xmage_class_found": True,
                "readiness": "best_first_runtime_contract_candidate",
                "required_runtime_slices": ["miracle", "tokens"],
            },
            {
                "card_name": "Brain in a Jar",
                "active_rule_count": 0,
                "xmage_class_found": True,
                "readiness": "blocked_requires_new_runtime_family",
                "required_runtime_slices": [
                    "charge_counter",
                    "exact_mana_value",
                    "free_cast",
                    "scry",
                ],
            },
            {
                "card_name": "Haze of Rage",
                "active_rule_count": 0,
                "xmage_class_found": True,
                "readiness": "blocked_complex_combo_runtime",
                "required_runtime_slices": ["storm", "buyback", "boost", "magecraft"],
            },
        ],
    }


def _candidate_queue(*, governed=True):
    return {
        "summary": {
            "decision_status": "miracle_access_candidate_row_queue_blocked_no_scoreable_rows_keep_607",
            "blocked_candidate_row_count": 3,
            "scoreable_candidate_row_count": 0,
            "matrix_route_governed": governed,
            "matrix_next_shell_status": planner.TARGET_NEXT_SHELL_STATUS if governed else "",
            "matrix_fallback_route_key": planner.TARGET_MATRIX_CONTRACT if governed else "",
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
        },
        "blocked_candidate_rows": [
            {
                "add_card": "Brain in a Jar",
                "lane": "topdeck_miracle_access",
                "matrix_cells": ["topdeck_miracle_access", "turn_cycle_miracle_mana"],
                "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
            },
            {
                "add_card": "Entreat the Angels",
                "lane": "miracle_finisher",
                "matrix_cells": ["approach_finisher_conversion", "topdeck_miracle_access"],
                "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
            },
            {
                "add_card": "Haze of Rage",
                "lane": "storm_combo_pressure",
                "matrix_cells": ["pressure_survival_floor"],
                "blockers": [
                    "verified_battle_rule_missing",
                    "named_safe_cut_missing",
                    "combo_runtime_required",
                ],
            },
        ],
    }


def _entreat_scout(*, safe_cuts=0, active_rules=0, pg_writes=False):
    return {
        "summary": {
            "safe_cut_count": safe_cuts,
            "entreat_active_rule_count": active_rules,
            "runtime_primitive_ready": True,
            "postgres_writes_executed": pg_writes,
        }
    }


def _cut_miner(*, named_cuts=0):
    return {"summary": {"named_seed_safe_cut_count": named_cuts}}


def _brain_safe_cut_gap(*, present=True, governed=True, active_rules=0, safe_cuts=0):
    if not present:
        return {}
    return {
        "summary": {
            "decision_status": planner.BRAIN_PACKAGE_ROUTE_STATUS,
            "brain_pg_package_status": "prepared_read_only_pending_apply_approval",
            "brain_pg_package_route_governed": governed,
            "apply_ready_for_manual_review": True,
            "apply_executed_by_this_script": False,
            "brain_active_rule_count": active_rules,
            "safe_cut_count": safe_cuts,
        }
    }


def _brain_unlock_audit(
    *,
    present=True,
    governed=True,
    active_rules=0,
    safe_cuts=0,
    unlockable=0,
    targeted_missing=0,
):
    if not present:
        return {}
    return {
        "summary": {
            "decision_status": planner.BRAIN_UNLOCK_AUDIT_STATUS,
            "brain_pg_package_route_governed": governed,
            "brain_active_rule_count": active_rules,
            "safe_cut_count": safe_cuts,
            "unlockable_now_count": unlockable,
            "targeted_floor_trace_missing_slot_count": targeted_missing,
            "matrix_scoring_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "recommended_next_action": planner.BRAIN_FLOOR_PROTECTED_ROUTE_PLANNER_ACTION,
        }
    }


def _paths():
    return {"post_identity": Path("/tmp/post_identity.json")}


def _build(**overrides):
    return planner.build_report(
        post_identity=overrides.get("post_identity", _post_identity()),
        runtime_contract=overrides.get("runtime_contract", _runtime_contract()),
        candidate_queue=overrides.get("candidate_queue", _candidate_queue()),
        entreat_scout=overrides.get("entreat_scout", _entreat_scout()),
        cut_miner=overrides.get("cut_miner", _cut_miner()),
        brain_safe_cut_gap=overrides.get("brain_safe_cut_gap", _brain_safe_cut_gap()),
        brain_unlock_audit=overrides.get("brain_unlock_audit", _brain_unlock_audit()),
        paths=_paths(),
    )


def test_current_like_state_selects_brain_floor_protected_route_without_deck_action() -> None:
    payload = _build()

    assert payload["summary"]["decision_status"] == (
        planner.BRAIN_FLOOR_PROTECTED_ROUTE_PLANNER_STATUS
    )
    assert payload["summary"]["candidate_queue_matrix_route_governed"] is True
    assert payload["summary"]["candidate_queue_matrix_next_shell_status"] == (
        planner.TARGET_NEXT_SHELL_STATUS
    )
    assert payload["summary"]["selected_card"] == "Brain in a Jar"
    assert payload["summary"]["selected_route_state"] == (
        planner.BRAIN_FLOOR_PROTECTED_ROUTE_STATE
    )
    assert payload["summary"]["brain_pg_package_route_governed"] is True
    assert payload["summary"]["brain_apply_ready_for_manual_review"] is True
    assert payload["summary"]["brain_active_rule_count"] == 0
    assert payload["summary"]["brain_safe_cut_count"] == 0
    assert payload["summary"]["brain_unlock_audit_status"] == planner.BRAIN_UNLOCK_AUDIT_STATUS
    assert payload["summary"]["brain_unlockable_now_count"] == 0
    assert payload["summary"]["brain_targeted_floor_trace_missing_slot_count"] == 0
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["decision"]["deck_action_allowed"] is False
    assert payload["decision"]["postgres_writes_allowed"] is False


def test_missing_unlock_audit_falls_back_to_brain_package_review() -> None:
    payload = _build(brain_unlock_audit=_brain_unlock_audit(present=False))

    assert payload["summary"]["decision_status"] == planner.BRAIN_ROUTE_PLANNER_STATUS
    assert payload["summary"]["selected_card"] == "Brain in a Jar"
    assert payload["summary"]["selected_route_state"] == (
        "brain_package_prepared_no_active_rule_no_seed_safe_cut"
    )
    assert payload["summary"]["recommended_next_action"] == planner.BRAIN_ROUTE_PLANNER_ACTION


def test_missing_brain_progress_artifact_uses_old_runtime_learning_route() -> None:
    payload = _build(
        brain_safe_cut_gap=_brain_safe_cut_gap(present=False),
        brain_unlock_audit=_brain_unlock_audit(present=False),
    )

    assert payload["summary"]["decision_status"] == (
        "miracle_next_route_planner_selected_brain_runtime_learning_keep_607"
    )
    assert payload["summary"]["selected_card"] == "Brain in a Jar"
    assert payload["selected_route"]["route_state"] == "next_single_card_runtime_lesson"


def test_entreat_ready_route_beats_brain_but_still_no_battle() -> None:
    payload = _build(
        entreat_scout=_entreat_scout(safe_cuts=1, active_rules=1, pg_writes=True),
        cut_miner=_cut_miner(named_cuts=1),
    )

    assert payload["summary"]["decision_status"] == (
        "miracle_next_route_planner_selected_entreat_refresh_keep_607"
    )
    assert payload["summary"]["selected_card"] == "Entreat the Angels"
    assert payload["selected_route"]["route_state"] == "resume_entreat_matrix_refresh"
    assert payload["decision"]["natural_battle_allowed_now"] is False


def test_haze_becomes_fallback_when_brain_missing_and_entreat_blocked() -> None:
    payload = _build(post_identity=_post_identity(include_brain=False))

    assert payload["summary"]["decision_status"] == (
        "miracle_next_route_planner_selected_haze_combo_learning_keep_607"
    )
    assert payload["summary"]["selected_card"] == "Haze of Rage"
    assert payload["selected_route"]["route_state"] == "combo_package_runtime_lesson"
    assert "commander_spellbook" in payload["selected_route"]["external_evidence"]["links"]


def test_no_candidates_blocks_route_planner() -> None:
    payload = _build(post_identity={"summary": {}, "cards": []})

    assert payload["summary"]["decision_status"] == (
        "miracle_next_route_planner_blocked_no_candidates_keep_607"
    )
    assert payload["summary"]["selected_card"] == ""
    assert payload["decision"]["deck_action_allowed"] is False


def test_ungoverned_candidate_queue_blocks_selection() -> None:
    payload = _build(candidate_queue=_candidate_queue(governed=False))

    assert payload["summary"]["decision_status"] == (
        "miracle_next_route_planner_blocked_candidate_queue_not_governed_keep_607"
    )
    assert payload["summary"]["selected_card"] == ""
    assert payload["summary"]["candidate_queue_matrix_route_governed"] is False
    assert payload["summary"]["recommended_next_action"] == (
        "rerun_routed_candidate_row_queue_before_route_selection"
    )
    assert payload["decision"]["deck_action_allowed"] is False


def test_markdown_surfaces_selected_route_and_closed_gates() -> None:
    markdown = planner.render_markdown(_build())

    assert "Candidate queue matrix route governed: `true`" in markdown
    assert "Selected card: `Brain in a Jar`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "Natural battle gate allowed now: `false`" in markdown
    assert planner.BRAIN_FLOOR_PROTECTED_ROUTE_PLANNER_ACTION in markdown
    assert "Brain PG package route governed: `true`" in markdown
    assert "Brain targeted floor trace missing slots: `0`" in markdown
    assert "https://scryfall.com/card/soi/252/brain-in-a-jar" in markdown
