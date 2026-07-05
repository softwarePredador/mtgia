from pathlib import Path

import lorehold_pressure_safe_cut_pool_resolver as resolver


def _contract_report():
    return {
        "summary": {
            "decision_status": "preflight_pass_cut_pool_required",
            "diagnostic_contract_status": "pressure_safe_diagnostic_contract_ready_no_battle",
            "diagnostic_only": True,
            "natural_gate_blocked_by_hypothesis_queue": True,
            "natural_gate_ready_from_hypothesis_queue": 0,
            "primary_package_missing_from_hypothesis_queue": 3,
            "primary_package_matched_in_hypothesis_queue": 1,
        },
        "hard_stop_rules": [
            {
                "rule": "no_natural_gate_when_queue_has_zero_ready_candidates",
                "condition": "natural_gate_ready_from_hypothesis_queue == 0",
                "action": "diagnostic_only_keep_607_protected",
            }
        ],
        "primary_package_preflight": [
            {"card_name": "Monastery Mentor"},
            {"card_name": "Young Pyromancer"},
            {"card_name": "Guttersnipe"},
            {"card_name": "Storm-Kiln Artist"},
        ]
    }


def _cut(card_name, lane, status="seed_safe_cut_ready", blockers=None, score=50, exposure=10):
    return {
        "card_name": card_name,
        "lane": lane,
        "status": status,
        "manual_status": "seed_safe",
        "blockers": blockers or [],
        "score": score,
        "unique_exposure_count": exposure,
        "direct_event_count": 1,
    }


def _diagnostic_cut(card_name, lane, score=50, exposure=10):
    row = _cut(
        card_name,
        lane,
        status="diagnostic_candidate",
        blockers=["manual_status_not_seed_safe"],
        score=score,
        exposure=exposure,
    )
    row["manual_status"] = "diagnostic_candidate"
    return row


def test_gate_ready_plan_requires_four_unblocked_seed_safe_cuts():
    seed_safe = {
        "seed_safe_cut_candidates": [
            _cut("Avatar's Wrath", "removal"),
            _cut("High Noon", "removal"),
            _cut("Prismari Pianist", "wincon"),
            _cut("Thor, God of Thunder", "removal"),
        ],
        "cut_slots": [],
    }

    payload = resolver.build_report(
        contract_report=_contract_report(),
        seed_safe_report=seed_safe,
        contract_path=Path("/tmp/contract.json"),
        seed_safe_path=Path("/tmp/seed.json"),
    )

    assert payload["summary"]["decision_status"] == "seed_safe_cut_plan_ready"
    assert payload["summary"]["gate_ready_plan_complete"] is True
    assert payload["summary"]["contract_blocks_natural_gate"] is True
    assert payload["gate_ready_cut_plan"]["cut_plan_validation"]["safe"] is True


def test_no_seed_safe_cuts_can_build_diagnostic_only_plan_from_reviewable_noncore_cuts():
    seed_safe = {
        "seed_safe_cut_candidates": [],
        "cut_slots": [
            _diagnostic_cut("Avatar's Wrath", "removal", score=100, exposure=8),
            _diagnostic_cut("High Noon", "removal", score=80, exposure=31),
            _diagnostic_cut("Prismari Pianist", "contextual", score=70, exposure=34),
            _diagnostic_cut("Thor, God of Thunder", "misc", score=10, exposure=97),
            _cut("Bender's Waterskin", "early_mana", status="blocked", blockers=["protected_cut"], score=999, exposure=1),
        ],
    }

    payload = resolver.build_report(
        contract_report=_contract_report(),
        seed_safe_report=seed_safe,
        contract_path=Path("/tmp/contract.json"),
        seed_safe_path=Path("/tmp/seed.json"),
    )

    assert payload["summary"]["decision_status"] == (
        "no_seed_safe_cut_plan_diagnostic_only_tradeoff_available"
    )
    assert payload["summary"]["gate_ready_plan_complete"] is False
    assert payload["diagnostic_tradeoff_cut_plan"]["promotion_eligible"] is False
    assert payload["diagnostic_tradeoff_cut_plan"]["natural_battle_gate_allowed"] is False
    assert [row["card_name"] for row in payload["diagnostic_tradeoff_cut_plan"]["selected_cuts"]] == [
        "Avatar's Wrath",
        "High Noon",
        "Prismari Pianist",
        "Thor, God of Thunder",
    ]


def test_structural_protected_or_mana_cuts_are_not_diagnostic_eligible():
    seed_safe = {
        "seed_safe_cut_candidates": [],
        "cut_slots": [
            _cut("Bender's Waterskin", "early_mana", status="blocked", blockers=["protected_cut"], score=100, exposure=1),
            _cut("Radiant Summit", "mana_base", status="blocked", blockers=[], score=90, exposure=2),
            _cut("Flawless Maneuver", "protection", status="blocked", blockers=[], score=80, exposure=3),
            _cut("Call Forth the Tempest", "spell_velocity", status="blocked", blockers=["structural_dependency"], score=70, exposure=4),
            _diagnostic_cut("Avatar's Wrath", "removal", score=60, exposure=5),
        ],
    }

    plan = resolver.build_diagnostic_tradeoff_plan(seed_safe["cut_slots"], add_count=1)

    assert plan["status"] == "diagnostic_plan_available"
    assert [row["card_name"] for row in plan["selected_cuts"]] == ["Avatar's Wrath"]
    assert plan["blocked_reason_counts"]["protected_cut"] == 1
    assert plan["blocked_reason_counts"]["diagnostic_lane_excluded:mana_base"] == 1
    assert plan["blocked_reason_counts"]["diagnostic_lane_excluded:protection"] == 1
    assert plan["blocked_reason_counts"]["structural_dependency"] == 1


def test_incomplete_diagnostic_cut_pool_stays_unavailable():
    seed_safe = {
        "seed_safe_cut_candidates": [],
        "cut_slots": [
            _cut("Call Forth the Tempest", "spell_velocity", status="blocked", blockers=["structural_dependency"], score=70, exposure=4),
        ],
    }

    payload = resolver.build_report(
        contract_report=_contract_report(),
        seed_safe_report=seed_safe,
        contract_path=Path("/tmp/contract.json"),
        seed_safe_path=Path("/tmp/seed.json"),
    )

    assert payload["summary"]["decision_status"] == (
        "no_seed_safe_cut_plan_no_diagnostic_tradeoff_current_607"
    )
    assert payload["diagnostic_tradeoff_cut_plan"]["status"] == "not_available"
