from pathlib import Path

import lorehold_learning_frontier_after_probe_closure as frontier


def _probe(*, mana_eligible=0, matrix_rows=0, safe_cuts=0):
    return {
        "status": "topdeck_sidecar_probe_evidence_no_safe_cut_keep_607",
        "summary": {
            "probe_row_count": 48,
            "matrix_candidate_row_eligible_count": matrix_rows,
            "safe_cut_ready_count": safe_cuts,
            "mana_model_eligible_pair_count": mana_eligible,
            "mana_model_exact_rejected_pair_count": 2,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
        },
    }


def _queue(*, matrix_rows=0, safe_cuts=0):
    cards = [
        ("Penance", "topdeck_access_sidecar_primary"),
        ("Galvanoth", "topdeck_access_sidecar_primary"),
        ("Dragon's Rage Channeler", "topdeck_access_sidecar_primary"),
        ("Valakut Awakening // Valakut Stoneforge", "topdeck_access_sidecar_primary"),
        ("Wheel of Fortune", "topdeck_access_sidecar_primary"),
        ("Boros Charm", "pressure_window_after_topdeck_floor"),
        ("Deflecting Palm", "pressure_window_after_topdeck_floor"),
        ("Apex of Power", "spell_chain_after_miracle_floor"),
    ]
    return {
        "status": "topdeck_sidecar_candidate_queue_blocked_no_matrix_rows_keep_607",
        "summary": {
            "queue_row_count": len(cards),
            "matrix_candidate_row_eligible_count": matrix_rows,
            "safe_cut_seed_ready_count": safe_cuts,
            "safe_cut_reviewable_count": 0,
        },
        "candidate_queue": [
            {
                "add_card": add_card,
                "sidecar_tag": tag,
                "matrix_candidate_row_eligible_now": False,
                "candidate_deck_materialization_allowed_now": False,
                "natural_gate_allowed_now": False,
            }
            for add_card, tag in cards
        ],
    }


def _hypothesis(*, natural=0):
    return {
        "status": "lorehold_hypothesis_queue_ready_no_natural_gate",
        "summary": {
            "natural_gate_ready_count": natural,
            "gate_ready_now_count_from_preflight": 0,
            "promotion_allowed": False,
        },
    }


def _shell(*, can_battle=False, promotable=0):
    return {
        "summary": {
            "can_run_next_battle_gate": can_battle,
            "promotable_shell_signal_count": promotable,
            "best_natural_delta_wins": -1,
            "best_forced_delta_wins": -1,
        }
    }


def _post_safe(*, forced=0):
    return {
        "status": "topdeck_post_safe_cut_route_sidecar_shell_required_keep_607",
        "summary": {
            "forced_access_runnable_count": forced,
            "sidecar_shell_contract_required": True,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
        },
    }


def _mana(*, eligible=0):
    return {
        "status": "mana_base_model_ready_queue_exhausted_by_decisions",
        "summary": {
            "eligible_model_ready_pair_count": eligible,
            "exact_rejected_pair_count": 2,
            "promotion_allowed": False,
        },
    }


def _paths():
    return {
        "probe_evidence": Path("/tmp/probe.json"),
        "candidate_queue": Path("/tmp/queue.json"),
        "hypothesis_queue": Path("/tmp/hypothesis.json"),
        "shell_failure_synthesis": Path("/tmp/shell.json"),
        "post_safe_cut_route": Path("/tmp/post_safe.json"),
        "mana_decision_integrator": Path("/tmp/mana.json"),
    }


def _build(**overrides):
    return frontier.build_report(
        probe_evidence=overrides.get("probe_evidence", _probe()),
        candidate_queue=overrides.get("candidate_queue", _queue()),
        hypothesis_queue=overrides.get("hypothesis_queue", _hypothesis()),
        shell_failure_synthesis=overrides.get("shell_failure_synthesis", _shell()),
        post_safe_cut_route=overrides.get("post_safe_cut_route", _post_safe()),
        mana_decision_integrator=overrides.get("mana_decision_integrator", _mana()),
        paths=_paths(),
    )


def test_current_closed_execution_frontier_routes_to_topdeck_floor_trace_contract():
    payload = _build()

    assert payload["status"] == "learning_frontier_closed_execution_routes_keep_607"
    assert payload["summary"]["selected_next_route"] == "topdeck_floor_trace_target_contract"
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["decision"]["promotion_allowed"] is False
    assert payload["summary"]["topdeck_floor_trace_target_count"] == 5
    route = {
        row["frontier_key"]: row
        for row in payload["learning_frontiers"]
    }["topdeck_floor_trace_target_contract"]
    assert route["allowed_now"] is True
    assert "Penance" in route["evidence"]["target_cards"]
    assert "Galvanoth" in route["evidence"]["target_cards"]


def test_mana_eligible_pair_takes_precedence_without_allowing_mutation():
    payload = _build(mana_decision_integrator=_mana(eligible=1))

    assert payload["status"] == "learning_frontier_mana_preflight_available_keep_607"
    assert payload["summary"]["selected_next_route"] == "mana_base_pair_frontier"
    assert payload["summary"]["deck_action_allowed_now"] is False
    assert payload["decision"]["allow_candidate_materialization_now"] is False


def test_matrix_candidate_rows_take_precedence_after_mana_closure():
    payload = _build(candidate_queue=_queue(matrix_rows=2))

    assert payload["status"] == "learning_frontier_matrix_review_available_keep_607"
    assert payload["summary"]["selected_next_route"] == "topdeck_sidecar_matrix_rows"
    assert payload["summary"]["structure_matrix_scoring_allowed_now"] is False
    assert payload["decision"]["promotion_allowed"] is False


def test_missing_inputs_blocks_learning_route():
    payload = _build(probe_evidence={})

    assert payload["status"] == "learning_frontier_inputs_missing_keep_607"
    assert "probe_evidence" in payload["summary"]["missing_inputs"]
    assert payload["summary"]["selected_next_route"] == "repair_missing_inputs_before_learning_route"
    assert payload["decision"]["allow_deck_mutation_now"] is False


def test_markdown_surfaces_protected_607_and_blocked_staples():
    markdown = frontier.render_markdown(_build())

    assert "Deck 607 mutated: `false`" in markdown
    assert "Selected next route: `topdeck_floor_trace_target_contract`" in markdown
    assert "generic_staple_frontier" in markdown
    assert "Mana Vault" in markdown
    assert "The One Ring" in markdown
