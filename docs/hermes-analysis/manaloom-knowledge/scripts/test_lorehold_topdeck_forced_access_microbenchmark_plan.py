from pathlib import Path

import lorehold_topdeck_forced_access_microbenchmark_plan as plan


def _audit_row(name, rank=1):
    return {
        "card_name": name,
        "learning_priority_rank": rank,
        "diagnostic_allowed_now": True,
        "blockers_before_deck_action": ["deck_607_protected_no_mutation"],
    }


def _audit():
    return {
        "status": "topdeck_forced_access_diagnostic_ready_no_natural_gate_keep_607",
        "candidates": [
            _audit_row("Penance", 1),
            _audit_row("Galvanoth", 2),
            _audit_row("Dragon's Rage Channeler", 3),
            _audit_row("Valakut Awakening // Valakut Stoneforge", 4),
            _audit_row("Wheel of Fortune", 5),
        ],
    }


def _package(
    key,
    add,
    cut,
    *,
    decision="not_run_cut_safety_blocked",
    cut_status="blocked_cut_safety",
    prior_status="clear",
    prior_decision=None,
):
    match = {}
    if prior_decision:
        match = {
            "decision": prior_decision,
            "delta_pp": -100.0,
            "forced_access_mode": "none",
            "source_report": "/tmp/prior.json",
        }
    return {
        "package_key": key,
        "family": "test",
        "adds": [add],
        "cuts": [cut],
        "status": "skipped",
        "decision": decision,
        "cut_safety": {"status": cut_status},
        "prior_evidence": {"status": prior_status, "matches": [match] if match else []},
    }


def _preflight():
    return {
        "packages": [
            _package(
                "penance_cut_squelcher",
                "Penance",
                "Hexing Squelcher",
                prior_decision="reject_or_rework",
            ),
            _package(
                "galvanoth_cut_chimes",
                "Galvanoth",
                "Victory Chimes",
                prior_decision="reject_or_rework",
            ),
            _package(
                "drc_cut_scarlet",
                "Dragon's Rage Channeler",
                "The Scarlet Witch",
                prior_decision=None,
            ),
            _package(
                "valakut_cut_big_score",
                "Valakut Awakening // Valakut Stoneforge",
                "Big Score",
                decision="not_run_prior_reject_blocked",
                cut_status="clear",
                prior_status="blocked_prior_reject",
                prior_decision="reject_or_rework",
            ),
            _package(
                "wheel_cut_big_score",
                "Wheel of Fortune",
                "Big Score",
                decision="not_run_prior_reject_blocked",
                cut_status="clear",
                prior_status="blocked_prior_reject",
                prior_decision="reject_or_rework",
            ),
        ]
    }


def _paths():
    return {
        "forced_access_audit": Path("/tmp/audit.json"),
        "package_preflight": Path("/tmp/preflight.json"),
    }


def _build(**overrides):
    return plan.build_report(
        forced_access_audit=overrides.get("forced_access_audit", _audit()),
        package_preflight=overrides.get("package_preflight", _preflight()),
        paths=_paths(),
    )


def test_plan_designs_five_microbenchmarks_but_runs_zero_now():
    payload = _build()

    assert payload["status"] == "topdeck_microbenchmark_plan_ready_but_no_executable_package_keep_607"
    assert payload["summary"]["microbenchmark_design_count"] == 5
    assert payload["summary"]["runnable_now_count"] == 0
    assert payload["summary"]["natural_promotion_allowed_count"] == 0
    assert payload["decision"]["allow_execution_now"] is False
    assert payload["decision"]["promotion_allowed"] is False


def test_valakut_and_wheel_are_blocked_by_prior_reject_not_retestable_big_score_pair():
    payload = _build()
    rows = {row["card_name"]: row for row in payload["microbenchmarks"]}

    assert rows["Valakut Awakening // Valakut Stoneforge"]["package_execution_status"] == (
        "blocked_prior_reject_new_cut_required"
    )
    assert rows["Wheel of Fortune"]["package_execution_status"] == (
        "blocked_prior_reject_new_cut_required"
    )
    assert rows["Wheel of Fortune"]["next_action"] == (
        "do_not_retest_prior_pair; declare_new_cut_and_failure_hypothesis"
    )


def test_penance_and_galvanoth_surface_cut_safety_and_prior_reject_blockers():
    payload = _build()
    rows = {row["card_name"]: row for row in payload["microbenchmarks"]}

    assert rows["Penance"]["package_execution_status"] == "blocked_prior_reject_and_cut_safety"
    assert "cut_safety_blocked" in rows["Penance"]["blockers"]
    assert "prior_exact_or_strategy_reject" in rows["Galvanoth"]["blockers"]


def test_drc_uses_opening_hand_mode_and_cannot_promote_from_forced_access():
    payload = _build()
    drc = {row["card_name"]: row for row in payload["microbenchmarks"]}["Dragon's Rage Channeler"]

    assert drc["primary_forced_access_mode"] == "opening_hand"
    assert drc["secondary_forced_access_modes"][0]["mode"] == "library_top"
    assert drc["secondary_forced_access_modes"][0]["status"] == "not_primary_for_enabler_card"
    assert drc["natural_promotion_allowed"] is False


def test_command_template_uses_existing_forced_access_runtime_contract():
    payload = _build()
    penance = payload["microbenchmarks"][0]
    template = penance["command_template"]

    assert template["runnable_now"] is False
    assert template["environment"]["MANALOOM_FORCE_FOCUS_ACCESS_MODE"] == "opening_hand"
    assert template["environment"]["MANALOOM_FOCUS_ACCESS_CARDS"] == '["Penance"]'
    assert "--forced-access-mode" in template["command"]
    assert "opening_hand" in template["command"]
    assert "<package_manifest_with_safe_cut_required>" in template["command"]


def test_missing_audit_input_blocks_plan_status():
    payload = plan.build_report(
        forced_access_audit={"candidates": []},
        package_preflight=_preflight(),
        paths=_paths(),
        target_cards=("Penance",),
    )

    assert payload["status"] == "topdeck_microbenchmark_plan_inputs_missing_keep_607"
    assert "forced_access_audit:Penance" in payload["summary"]["missing_inputs"]
