from pathlib import Path

import lorehold_topdeck_floor_trace_target_contract as contract


def _frontier(*, selected=True):
    return {
        "summary": {
            "selected_next_route": "topdeck_floor_trace_target_contract" if selected else "other",
            "safe_cut_ready_count": 0,
            "matrix_candidate_row_eligible_count": 0,
        }
    }


def _queue():
    cards = [
        "Penance",
        "Galvanoth",
        "Dragon's Rage Channeler",
        "Valakut Awakening // Valakut Stoneforge",
        "Wheel of Fortune",
    ]
    return {
        "summary": {"queue_row_count": len(cards), "matrix_candidate_row_eligible_count": 0},
        "candidate_queue": [
            {
                "add_card": card,
                "candidate_key": f"sidecar_{card.lower().replace(' ', '_')}",
                "sidecar_tag": contract.TARGET_SIDECAR_TAG,
                "lane": "topdeck_miracle_setup",
                "expected_metric_lift": "miracle_cast_and_topdeck_manipulation_floor_lift",
                "floor_risk": "can_improve_visibility_but_still_regress_win_conversion",
                "rule_runtime_status": "requires_xmage_runtime_trace_before_materialization",
                "readiness_status": "needs_safe_cut_model",
                "blockers": ["missing_named_same_lane_cut", "needs_safe_cut_model"],
            }
            for card in cards
        ],
    }


def _probe():
    return {
        "summary": {
            "probe_row_count": 48,
            "safe_cut_ready_count": 0,
            "matrix_candidate_row_eligible_count": 0,
        }
    }


def _paths():
    return {
        "frontier": Path("/tmp/frontier.json"),
        "candidate_queue": Path("/tmp/queue.json"),
        "probe_evidence": Path("/tmp/probe.json"),
    }


def _build(**overrides):
    return contract.build_report(
        frontier_report=overrides.get("frontier_report", _frontier()),
        candidate_queue=overrides.get("candidate_queue", _queue()),
        probe_evidence=overrides.get("probe_evidence", _probe()),
        paths=_paths(),
    )


def test_current_contract_writes_topdeck_targets_without_deck_action():
    payload = _build()

    assert payload["status"] == "topdeck_floor_trace_contract_written_no_deck_action_keep_607"
    assert payload["summary"]["trace_contract_ready"] is True
    assert payload["summary"]["target_card_count"] == 5
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["decision"]["promotion_allowed"] is False
    target_names = [row["add_card"] for row in payload["contract"]["target_cards"]]
    assert target_names[0] == "Penance"
    assert "Wheel of Fortune" in target_names


def test_non_selected_frontier_blocks_contract_readiness():
    payload = _build(frontier_report=_frontier(selected=False))

    assert payload["status"] == "topdeck_floor_trace_contract_waiting_on_frontier_route_keep_607"
    assert payload["summary"]["trace_contract_ready"] is False
    assert payload["summary"]["forced_access_allowed_now"] is False


def test_missing_queue_blocks_contract():
    payload = _build(candidate_queue={})

    assert payload["status"] == "topdeck_floor_trace_contract_inputs_missing_keep_607"
    assert "candidate_queue" in payload["summary"]["missing_inputs"]
    assert payload["decision"]["allow_deck_mutation_now"] is False


def test_markdown_surfaces_targets_floors_and_staple_blocks():
    markdown = contract.render_markdown(_build())

    assert "Deck 607 mutated: `false`" in markdown
    assert "Penance" in markdown
    assert "Galvanoth" in markdown
    assert "miracle_cast" in markdown
    assert "Mana Vault" in markdown
    assert "The One Ring" in markdown
