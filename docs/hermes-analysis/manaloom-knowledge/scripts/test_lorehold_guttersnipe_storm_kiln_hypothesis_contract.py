from pathlib import Path

import lorehold_guttersnipe_storm_kiln_hypothesis_contract as contract


def _route(*, gate=False):
    return {
        "route_key": contract.TARGET_ROUTE_KEY,
        "adds": contract.TARGET_ADDS,
        "lane": "engine_preserving_pressure_conversion_pair",
        "package_key": "pressure_2_card_guttersnipe_storm_kiln_artist",
        "required_cut_count": 2,
        "gate_ready": gate,
        "status": "engine_preserving_pressure_conversion_gate_candidate_requires_structure_matrix"
        if gate
        else "best_next_learning_route_contract_required_no_deck_action",
        "blockers": [] if gate else ["insufficient_seed_safe_cut_capacity"],
    }


def _engine_router(*, gate=False, include_route=True):
    return {
        "summary": {"decision_status": "engine_preserving_pressure_conversion_not_gate_ready_keep_607"},
        "routes": [_route(gate=gate)] if include_route else [],
    }


def _seed_safe(*, ready_count=0):
    ready = [
        {
            "card_name": f"Safe Flex {idx}",
            "lane": "spell_velocity",
            "score": 80 - idx,
            "unique_exposure_count": idx,
            "blockers": [],
        }
        for idx in range(ready_count)
    ]
    return {
        "summary": {
            "seed_safe_cut_ready_count": ready_count,
            "same_lane_only_count": 2,
            "blocked_count": 94 - ready_count,
            "same_lane_only_cut_cards": ["Creative Technique", "Bender's Waterskin"],
            "blocker_counts": {"protected_cut": 22},
        },
        "seed_safe_cut_candidates": ready,
        "same_lane_only_cut_slots": [
            {
                "card_name": "Creative Technique",
                "lane": "big_spell_value",
                "status": "same_lane_only_not_seed_safe",
                "blockers": ["same_lane_only_requires_concrete_same_lane_add"],
            },
            {
                "card_name": "Bender's Waterskin",
                "lane": "topdeck_setup",
                "status": "same_lane_only_not_seed_safe",
                "blockers": ["same_lane_only_requires_concrete_same_lane_add"],
            },
        ],
    }


def _trace_expander():
    return {
        "summary": {
            "hard_blocked_count": 92,
            "top_near_miss_cut_cards": [
                "Creative Technique",
                "Bender's Waterskin",
                "Generous Gift",
            ],
            "blocker_counts": {"prior_rejected_cut": 37},
        },
        "same_lane_hard_blocked_queue": [
            {
                "card_name": "Creative Technique",
                "lane": "big_spell_value",
                "blockers": ["miracle_or_finisher_core"],
            }
        ],
    }


def _closing_trace():
    return {"summary": {"comparison_count": 13, "avg_607_turn_advantage": 10.15}}


def _miracle_trace():
    return {"summary": {"blocking_failure_flags": ["pressure_conversion_unproven"]}}


def _package_router():
    return {
        "packages": [
            {
                "package_key": "pressure_2_card_guttersnipe_storm_kiln_artist",
                "status": "blocked_no_cut_or_hypothesis_capacity",
            }
        ]
    }


def _build(*, gate=False, ready_count=0, include_route=True):
    return contract.build_report(
        engine_router=_engine_router(gate=gate, include_route=include_route),
        seed_safe_report=_seed_safe(ready_count=ready_count),
        trace_expander=_trace_expander(),
        closing_trace=_closing_trace(),
        miracle_trace=_miracle_trace(),
        package_router=_package_router(),
        paths={"engine_router": Path("/tmp/router.json")},
    )


def test_current_contract_is_written_but_blocked_without_named_safe_cuts():
    payload = _build()

    assert payload["postgres_writes"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["decision_status"] == (
        "hypothesis_contract_written_blocked_no_named_safe_cuts"
    )
    assert payload["summary"]["available_named_seed_safe_cut_count"] == 0
    assert payload["summary"]["cut_shortage"] == 2
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["decision"]["deck_action_allowed"] is False


def test_contract_lists_same_lane_slots_as_not_seed_safe():
    payload = _build()
    slots = {
        row["card_name"]: row
        for row in payload["candidate_package_contract"]["same_lane_only_slots_not_seed_safe"]
    }

    assert "Creative Technique" in slots
    assert "Bender's Waterskin" in slots
    assert "same_lane_only_requires_concrete_same_lane_add" in slots["Creative Technique"]["blockers"]


def test_synthetic_ready_contract_requires_structure_matrix_before_battle():
    payload = _build(gate=True, ready_count=2)

    assert payload["summary"]["decision_status"] == (
        "hypothesis_contract_ready_for_structure_matrix"
    )
    assert payload["summary"]["structure_matrix_allowed_now"] is True
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert len(payload["candidate_package_contract"]["available_named_seed_safe_cuts"]) == 2


def test_missing_engine_route_blocks_contract():
    payload = _build(include_route=False)

    assert payload["summary"]["decision_status"] == (
        "hypothesis_contract_blocked_missing_engine_preserving_route"
    )
    assert payload["summary"]["recommended_next_action"] == (
        "rebuild_engine_preserving_router_before_contract_or_battle"
    )


def test_markdown_surfaces_event_requirements_and_no_mutation():
    markdown = contract.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "guttersnipe_direct_spell_damage" in markdown
    assert "storm_kiln_treasure_conversion" in markdown
    assert "Available named seed-safe cuts: `0`" in markdown
