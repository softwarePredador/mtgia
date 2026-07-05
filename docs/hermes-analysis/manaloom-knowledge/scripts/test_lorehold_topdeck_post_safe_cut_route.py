from pathlib import Path

import lorehold_topdeck_post_safe_cut_route as route


def _safe_cut(*, seed_safe=0, reviewable=0):
    return {
        "summary": {
            "seed_safe_cut_candidate_count": seed_safe,
            "reviewable_same_lane_gap_count": reviewable,
            "runnable_now_count": 0,
        },
        "decision": {
            "allow_forced_access_execution_now": False,
            "promotion_allowed": False,
        },
    }


def _micro(*, runnable=0):
    return {
        "summary": {
            "runnable_now_count": runnable,
            "target_card_count": 5,
        }
    }


def _miracle_contract(*, contract_allowed=True, structure_allowed=False):
    return {
        "summary": {
            "structure_matrix_contract_allowed_now": contract_allowed,
            "structure_matrix_allowed_now": structure_allowed,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
        }
    }


def _shell_failure(*, can_battle=False, promotable=0):
    return {
        "summary": {
            "can_run_next_battle_gate": can_battle,
            "promotable_shell_signal_count": promotable,
        }
    }


def _router():
    return {
        "summary": {
            "selected_status": "primary_shell_contract_target_blocked_but_actionable_as_design"
        }
    }


def _queue():
    return {
        "summary": {
            "natural_gate_ready_count": 0,
            "gate_ready_now_count_from_preflight": 0,
        }
    }


def _paths():
    return {
        "safe_cut_miner": Path("/tmp/safe.json"),
        "microbenchmark_plan": Path("/tmp/micro.json"),
        "miracle_shell_contract": Path("/tmp/miracle.json"),
        "shell_failure_synthesis": Path("/tmp/shell.json"),
        "closing_window_router": Path("/tmp/router.json"),
        "hypothesis_queue": Path("/tmp/queue.json"),
    }


def _build(**overrides):
    return route.build_report(
        safe_cut_miner=overrides.get("safe_cut_miner", _safe_cut()),
        microbenchmark_plan=overrides.get("microbenchmark_plan", _micro()),
        miracle_shell_contract=overrides.get("miracle_shell_contract", _miracle_contract()),
        shell_failure_synthesis=overrides.get("shell_failure_synthesis", _shell_failure()),
        closing_window_router=overrides.get("closing_window_router", _router()),
        hypothesis_queue=overrides.get("hypothesis_queue", _queue()),
        paths=_paths(),
    )


def test_current_like_zero_safe_cuts_routes_to_sidecar_shell_and_keeps_607():
    payload = _build()

    assert payload["status"] == "topdeck_post_safe_cut_route_sidecar_shell_required_keep_607"
    assert payload["summary"]["one_for_one_cut_ready_count"] == 0
    assert payload["summary"]["forced_access_runnable_count"] == 0
    assert payload["summary"]["sidecar_shell_contract_required"] is True
    assert payload["deck_607_mutated"] is False
    assert payload["decision"]["allow_deck_mutation_now"] is False
    assert payload["decision"]["allow_natural_gate_now"] is False
    assert payload["route"]["selected_route"] == "topdeck_access_first_sidecar_shell"


def test_seed_safe_cut_routes_back_to_package_gate_not_sidecar():
    payload = _build(safe_cut_miner=_safe_cut(seed_safe=1))

    assert payload["status"] == "topdeck_post_safe_cut_route_return_to_safe_cut_package_gate_keep_607"
    assert payload["summary"]["sidecar_shell_contract_required"] is False
    assert payload["route"]["selected_route"] == "safe_cut_package_gate"
    assert payload["decision"]["promotion_allowed"] is False


def test_forced_runnable_without_safe_cut_is_diagnostic_only_not_promotion():
    payload = _build(microbenchmark_plan=_micro(runnable=1))

    assert payload["status"] == "topdeck_post_safe_cut_route_forced_access_diagnostic_only_keep_607"
    assert payload["route"]["selected_route"] == "forced_access_diagnostic_only_requires_cut_proof"
    assert payload["decision"]["allow_forced_access_execution_now"] is False
    assert payload["decision"]["promotion_allowed"] is False


def test_missing_miracle_shell_contract_blocks_route_as_missing_input():
    payload = _build(miracle_shell_contract={})

    assert payload["status"] == "topdeck_post_safe_cut_route_inputs_missing_keep_607"
    assert "miracle_shell_contract" in payload["summary"]["missing_inputs"]
    assert payload["decision"]["allow_deck_mutation_now"] is False


def test_markdown_surfaces_no_mutation_sidecar_and_staple_policy():
    markdown = route.render_markdown(_build())

    assert "Deck 607 mutated: `false`" in markdown
    assert "Natural battle gate allowed: `false`" in markdown
    assert "topdeck_access_first_sidecar_shell" in markdown
    assert "Mana Vault" in markdown
    assert "The One Ring" in markdown
