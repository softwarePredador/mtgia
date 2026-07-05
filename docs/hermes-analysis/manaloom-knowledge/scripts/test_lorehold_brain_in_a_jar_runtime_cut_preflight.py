from pathlib import Path

import lorehold_brain_in_a_jar_runtime_cut_preflight as brain


def _route_planner(*, governed=True):
    return {
        "summary": {
            "decision_status": brain.TARGET_ROUTE_PLANNER_STATUS if governed else "stale_route",
            "selected_card": "Brain in a Jar" if governed else "",
            "candidate_queue_matrix_route_governed": governed,
            "candidate_queue_matrix_next_shell_status": brain.TARGET_NEXT_SHELL_STATUS if governed else "",
            "candidate_queue_matrix_fallback_route_key": brain.TARGET_MATRIX_CONTRACT if governed else "",
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "postgres_writes_allowed_now": False,
        },
        "selected_route": {
            "card_name": "Brain in a Jar" if governed else "",
            "lane": "topdeck_miracle_access",
            "route_state": "next_single_card_runtime_lesson",
        },
    }


def _legacy_route_planner():
    payload = _route_planner()
    payload["summary"]["decision_status"] = brain.LEGACY_TARGET_ROUTE_PLANNER_STATUS
    return payload


def _runtime_contract(*, active_rules=0, include_brain=True):
    contracts = []
    if include_brain:
        contracts.append(
            {
                "card_name": "Brain in a Jar",
                "xmage_class_found": True,
                "xmage_signal_hits": {
                    "AddCountersSourceEffect": True,
                    "BrainInAJarCastEffect": True,
                    "RemoveVariableCountersSourceCost": True,
                    "ScryEffect": True,
                    "ManaValuePredicate": True,
                },
                "required_runtime_slices": [
                    "activated_add_charge_counter_then_tap_cost",
                    "select_hand_instant_or_sorcery_by_exact_mana_value",
                    "cast_selected_spell_without_paying_mana_cost",
                    "activated_remove_x_charge_counters_scry_x",
                    "replay_charge_counter_and_free_cast_decision_fields",
                ],
                "active_rule_count": active_rules,
                "readiness": "blocked_requires_new_runtime_family",
                "manaloom_foundation": "generic_charge_counter_and_casting_primitives_exist_but_no_card_contract",
                "xmage_path": "/tmp/BrainInAJar.java",
            }
        )
    return {"summary": {"runtime_contract_count": len(contracts)}, "contracts": contracts}


def _candidate_queue(*, matrix_blockers=28):
    return {
        "summary": {
            "matrix_contract_blocker_count": matrix_blockers,
            "matrix_route_governed": True,
            "matrix_next_shell_status": brain.TARGET_NEXT_SHELL_STATUS,
            "matrix_fallback_route_key": brain.TARGET_MATRIX_CONTRACT,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
        },
        "blocked_candidate_rows": [
            {
                "add_card": "Brain in a Jar",
                "lane": "topdeck_miracle_access",
                "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
                "matrix_cells": ["topdeck_miracle_access", "turn_cycle_miracle_mana"],
            }
        ],
    }


def _exact_runtime_contract(*, drafted=False, adapter_present=False):
    if not drafted:
        return {}
    return {
        "status": "brain_exact_runtime_contract_drafted_adapter_missing_keep_607",
        "summary": {
            "contract_drafted": True,
            "effect_json_scope": "xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1",
            "brain_exact_scope_adapter_present": adapter_present,
            "recommended_next_action": "implement_brain_in_a_jar_runtime_adapter_no_deck_action",
        },
    }


def _value_model(*, names=None):
    if names is None:
        names = ["Scroll Rack", "Sensei's Divining Top"]
    return {
        "summary": {"quantity_total": 100},
        "all_card_values": [
            {
                "card_name": name,
                "functional_tag": "draw",
                "lanes": ["artifact", "draw", "topdeck_miracle_engine"],
                "value_tier": "tier_0_protected_engine_or_anchor",
                "value_score": 150,
                "cut_policy": "no_generic_cut_same_lane_battle_proof_required",
                "protected_anchor": True,
                "runtime_ready": True,
            }
            for name in names
        ],
    }


def _cut_miner(*, safe=False):
    if safe:
        rows = [
            {
                "card_name": "Scroll Rack",
                "lane": "draw",
                "status": "ready",
                "classification": "seed_safe_cut_ready",
                "unique_exposure_count": 1,
                "direct_event_count": 0,
                "hard_stop_blockers": [],
                "soft_evidence_blockers": [],
                "other_blockers": [],
            }
        ]
    else:
        rows = [
            {
                "card_name": "Scroll Rack",
                "lane": "early_mana",
                "status": "blocked",
                "classification": "closed_hard_stop_current_607",
                "unique_exposure_count": 42,
                "direct_event_count": 20,
                "hard_stop_blockers": ["early_mana_floor_support", "protected_cut"],
                "soft_evidence_blockers": ["manual_status_not_seed_safe"],
                "other_blockers": [],
            },
            {
                "card_name": "Sensei's Divining Top",
                "lane": "draw",
                "status": "blocked",
                "classification": "closed_hard_stop_current_607",
                "unique_exposure_count": 25,
                "direct_event_count": 14,
                "hard_stop_blockers": ["measured_high_cut_exposure", "protected_cut"],
                "soft_evidence_blockers": ["missing_cut_safety_row"],
                "other_blockers": [],
            },
        ]
    return {"summary": {"named_seed_safe_cut_count": int(safe)}, "all_cut_rows": rows}


def _paths():
    return {"route_planner": Path("/tmp/route.json")}


def _build(**overrides):
    return brain.build_report(
        route_planner=overrides.get("route_planner", _route_planner()),
        runtime_contract=overrides.get("runtime_contract", _runtime_contract()),
        candidate_queue=overrides.get("candidate_queue", _candidate_queue()),
        exact_runtime_contract=overrides.get("exact_runtime_contract", _exact_runtime_contract()),
        value_model=overrides.get("value_model", _value_model()),
        cut_miner=overrides.get("cut_miner", _cut_miner()),
        paths=_paths(),
    )


def test_current_like_state_blocks_brain_without_rule_or_safe_cut() -> None:
    payload = _build()

    assert payload["summary"]["decision_status"] == (
        "brain_in_a_jar_runtime_cut_preflight_blocked_no_active_rule_no_safe_cut_keep_607"
    )
    assert payload["summary"]["route_planner_status"] == brain.TARGET_ROUTE_PLANNER_STATUS
    assert payload["summary"]["route_planner_selected_brain"] is True
    assert payload["summary"]["route_gate_valid"] is True
    assert payload["summary"]["candidate_queue_matrix_route_governed"] is True
    assert payload["summary"]["brain_active_rule_count"] == 0
    assert payload["summary"]["safe_cut_count"] == 0
    assert payload["summary"]["blocked_same_lane_cut_count"] == 2
    assert payload["decision"]["deck_action_allowed"] is False
    assert payload["decision"]["natural_battle_allowed_now"] is False


def test_exact_contract_drafted_changes_blocker_to_adapter_missing() -> None:
    payload = _build(exact_runtime_contract=_exact_runtime_contract(drafted=True))

    assert payload["summary"]["decision_status"] == (
        "brain_in_a_jar_runtime_cut_preflight_blocked_adapter_missing_no_active_rule_no_safe_cut_keep_607"
    )
    assert payload["summary"]["exact_runtime_contract_drafted"] is True
    assert payload["summary"]["brain_exact_adapter_present"] is False
    assert payload["decision"]["runtime_family_required_before_battle"] is False
    assert payload["decision"]["runtime_adapter_required_before_battle"] is True
    assert payload["summary"]["recommended_next_action"] == (
        "implement_brain_in_a_jar_runtime_adapter_before_any_brain_deck_action"
    )


def test_adapter_present_changes_blocker_to_active_rule_and_safe_cut() -> None:
    payload = _build(exact_runtime_contract=_exact_runtime_contract(drafted=True, adapter_present=True))

    assert payload["summary"]["decision_status"] == (
        "brain_in_a_jar_runtime_cut_preflight_blocked_adapter_present_no_active_rule_no_safe_cut_keep_607"
    )
    assert payload["summary"]["brain_exact_adapter_present"] is True
    assert payload["decision"]["runtime_adapter_required_before_battle"] is False
    assert payload["decision"]["active_rule_required_before_battle"] is True
    assert payload["decision"]["named_safe_cut_required_before_scoring"] is True
    assert payload["summary"]["recommended_next_action"] == (
        "prepare_brain_in_a_jar_pg_package_precheck_and_mine_seed_safe_cut_no_deck_action"
    )


def test_active_rule_and_safe_cut_only_allow_matrix_scoring_no_battle() -> None:
    payload = _build(
        runtime_contract=_runtime_contract(active_rules=1),
        cut_miner=_cut_miner(safe=True),
        value_model=_value_model(names=["Scroll Rack"]),
        candidate_queue=_candidate_queue(matrix_blockers=0),
    )

    assert payload["summary"]["decision_status"] == (
        "brain_in_a_jar_runtime_cut_preflight_ready_for_matrix_scoring_no_battle"
    )
    assert payload["summary"]["safe_cut_count"] == 1
    assert payload["summary"]["matrix_scoring_allowed_now"] is True
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False


def test_missing_brain_contract_blocks_preflight() -> None:
    payload = _build(runtime_contract=_runtime_contract(include_brain=False))

    assert payload["summary"]["decision_status"] == (
        "brain_in_a_jar_runtime_cut_preflight_blocked_missing_runtime_contract"
    )
    assert payload["summary"]["brain_contract_found"] is False
    assert payload["decision"]["deck_action_allowed"] is False


def test_ungoverned_route_planner_blocks_preflight() -> None:
    payload = _build(route_planner=_route_planner(governed=False))

    assert payload["summary"]["decision_status"] == (
        "brain_in_a_jar_runtime_cut_preflight_blocked_route_not_governed_keep_607"
    )
    assert payload["summary"]["route_gate_valid"] is False
    assert payload["summary"]["route_planner_candidate_queue_governed"] is False
    assert payload["summary"]["recommended_next_action"] == (
        "rerun_governed_miracle_next_route_planner_before_brain_preflight"
    )
    assert payload["decision"]["active_rule_required_before_battle"] is False
    assert payload["decision"]["named_safe_cut_required_before_scoring"] is False


def test_legacy_route_planner_status_remains_governed() -> None:
    payload = _build(route_planner=_legacy_route_planner())

    assert payload["summary"]["route_gate_valid"] is True
    assert payload["summary"]["route_planner_status"] == brain.LEGACY_TARGET_ROUTE_PLANNER_STATUS
    assert payload["summary"]["decision_status"] == (
        "brain_in_a_jar_runtime_cut_preflight_blocked_no_active_rule_no_safe_cut_keep_607"
    )


def test_markdown_surfaces_brain_sources_and_closed_gates() -> None:
    markdown = brain.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "Route gate valid: `true`" in markdown
    assert "Natural battle gate allowed now: `false`" in markdown
    assert "321dbd10-1d48-49fc-ba6a-1df241a53338" in markdown
    assert "commander_legality: `legal`" in markdown
    assert "https://scryfall.com/card/soi/252/brain-in-a-jar" in markdown
    assert "Scroll Rack" in markdown
