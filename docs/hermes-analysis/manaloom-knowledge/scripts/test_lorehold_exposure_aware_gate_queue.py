import lorehold_exposure_aware_gate_queue as queue


def package_definitions():
    return {
        "mana_vault_fast_mana_cut_arcane_signet": {
            "family": "fast_mana",
            "hypothesis": "force exposure before judging Mana Vault",
            "adds": ["Mana Vault"],
            "cuts": ["Arcane Signet"],
        },
        "pg245_twinflame_damage_payoff_cut_thor": {
            "family": "static_damage_modifier",
            "hypothesis": "test damage payoff",
            "adds": ["Twinflame Tyrant"],
            "cuts": ["Thor, God of Thunder"],
        },
        "perch_protection_cut_avatar_wrath": {
            "family": "protection_window",
            "hypothesis": "prior negative protection test",
            "adds": ["Perch Protection"],
            "cuts": ["Avatar's Wrath"],
        },
    }


def readiness_report():
    return {
        "cards": [
            {
                "card_name": "Twinflame Tyrant",
                "status": "pg_precheck_blocked",
                "next_action": "Rerun PostgreSQL precheck.",
                "family_id": "static_damage_modifier",
            }
        ]
    }


def hypothesis_queue():
    return {
        "queue": [
            {
                "package_key": "pg245_twinflame_damage_payoff_cut_thor",
                "status": "tested_negative_do_not_promote",
                "adds": ["Twinflame Tyrant"],
                "cuts": ["Thor, God of Thunder"],
            },
            {
                "package_key": "perch_protection_cut_avatar_wrath",
                "status": "tested_negative_do_not_promote",
                "adds": ["Perch Protection"],
                "cuts": ["Avatar's Wrath"],
            },
        ]
    }


def planner_payload():
    return {
        "summary": {
            "prior_inconclusive_low_exposure_keys": [
                "mana_vault_fast_mana_cut_arcane_signet"
            ]
        }
    }


def build_report():
    return queue.build_report(
        readiness_report=readiness_report(),
        hypothesis_queue=hypothesis_queue(),
        planner_payload=planner_payload(),
        registry_payload={"untested_queue": []},
        package_definitions=package_definitions(),
        cut_safety={"enabled": False},
        prior_results={"enabled": False},
        command_stem="test_gate_queue",
    )


def blocking_prior_results():
    return {
        "enabled": True,
        "by_package_key": {
            "mana_vault_fast_mana_cut_arcane_signet": [
                {
                    "package_key": "mana_vault_fast_mana_cut_arcane_signet",
                    "adds": ["Mana Vault"],
                    "cuts": ["Arcane Signet"],
                    "decision": "reject_or_rework",
                }
            ]
        },
        "by_signature": {},
    }


def test_low_exposure_package_becomes_forced_exposure_diagnostic():
    report = build_report()

    ready = {row["package_key"]: row for row in report["ready_queue"]}
    mana_vault = ready["mana_vault_fast_mana_cut_arcane_signet"]
    assert mana_vault["status"] == "forced_exposure_probe_ready"
    assert mana_vault["natural_promotion_allowed"] is False
    assert mana_vault["forced_access_mode"] == "opening_hand"
    assert "--forced-access-mode" in mana_vault["command"]
    assert report["summary"]["recommended_next_action"] == (
        "run_forced_exposure_probe_before_natural_gate"
    )


def test_low_exposure_diagnostic_can_override_prior_reject_blocker():
    report = queue.build_report(
        readiness_report=readiness_report(),
        hypothesis_queue={"queue": []},
        planner_payload=planner_payload(),
        registry_payload={"untested_queue": []},
        package_definitions=package_definitions(),
        cut_safety={"enabled": False},
        prior_results=blocking_prior_results(),
        command_stem="test_gate_queue",
    )

    ready = {row["package_key"]: row for row in report["ready_queue"]}
    mana_vault = ready["mana_vault_fast_mana_cut_arcane_signet"]
    assert mana_vault["status"] == "forced_exposure_probe_ready"
    assert mana_vault["prior_evidence"]["status"] == (
        "forced_access_diagnostic_despite_prior_reject"
    )


def test_exact_negative_package_is_not_run_again():
    rows = {row["package_key"]: row for row in build_report()["packages"]}

    perch = rows["perch_protection_cut_avatar_wrath"]
    assert perch["status"] == "blocked_hypothesis_queue_prior_negative"
    assert perch["decision"] == "not_run_exact_pair_already_negative"
    assert "hypothesis_queue_exact_negative" in perch["blockers"]


def test_runtime_or_pg_blocked_added_card_wins_over_prior_negative():
    rows = {row["package_key"]: row for row in build_report()["packages"]}

    twinflame = rows["pg245_twinflame_damage_payoff_cut_thor"]
    assert twinflame["status"] == "blocked_added_card_readiness"
    assert twinflame["decision"] == "not_run_added_card_runtime_or_pg_blocked"
    assert twinflame["readiness_blockers"][0]["status"] == "pg_precheck_blocked"


def test_extract_child_status_from_executor_stdout():
    stdout = """
irrelevant package output
{
  "status": "ready",
  "json": "/tmp/report.json",
  "markdown": "/tmp/report.md"
}
"""

    status = queue.extract_child_status(stdout)
    assert status["json"] == "/tmp/report.json"
    assert status["markdown"] == "/tmp/report.md"
