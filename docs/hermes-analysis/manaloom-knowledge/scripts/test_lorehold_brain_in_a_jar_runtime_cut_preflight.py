from pathlib import Path

import lorehold_brain_in_a_jar_runtime_cut_preflight as brain


def _route_planner():
    return {
        "summary": {"selected_card": "Brain in a Jar"},
        "selected_route": {
            "card_name": "Brain in a Jar",
            "lane": "topdeck_miracle_access",
            "route_state": "next_single_card_runtime_lesson",
        },
    }


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
        "summary": {"matrix_contract_blocker_count": matrix_blockers},
        "blocked_candidate_rows": [
            {
                "add_card": "Brain in a Jar",
                "lane": "topdeck_miracle_access",
                "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
                "matrix_cells": ["topdeck_miracle_access", "turn_cycle_miracle_mana"],
            }
        ],
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
        value_model=overrides.get("value_model", _value_model()),
        cut_miner=overrides.get("cut_miner", _cut_miner()),
        paths=_paths(),
    )


def test_current_like_state_blocks_brain_without_rule_or_safe_cut() -> None:
    payload = _build()

    assert payload["summary"]["decision_status"] == (
        "brain_in_a_jar_runtime_cut_preflight_blocked_no_active_rule_no_safe_cut_keep_607"
    )
    assert payload["summary"]["route_planner_selected_brain"] is True
    assert payload["summary"]["brain_active_rule_count"] == 0
    assert payload["summary"]["safe_cut_count"] == 0
    assert payload["summary"]["blocked_same_lane_cut_count"] == 2
    assert payload["decision"]["deck_action_allowed"] is False
    assert payload["decision"]["natural_battle_allowed_now"] is False


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


def test_markdown_surfaces_brain_sources_and_closed_gates() -> None:
    markdown = brain.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "Natural battle gate allowed now: `false`" in markdown
    assert "https://scryfall.com/card/soi/252/brain-in-a-jar" in markdown
    assert "Scroll Rack" in markdown
