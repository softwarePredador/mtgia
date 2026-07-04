from pathlib import Path

import lorehold_pressure_safe_cut_pool_resolver as resolver


def _contract_report():
    return {
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
    assert payload["gate_ready_cut_plan"]["cut_plan_validation"]["safe"] is True


def test_no_seed_safe_cuts_can_still_build_diagnostic_only_plan():
    seed_safe = {
        "seed_safe_cut_candidates": [],
        "cut_slots": [
            _cut("Call Forth the Tempest", "spell_velocity", status="blocked", blockers=["structural_dependency"], score=100, exposure=8),
            _cut("Tempt with Bunnies", "wincon", status="blocked", blockers=["structural_dependency"], score=80, exposure=31),
            _cut("Everything Comes to Dust", "spell_velocity", status="blocked", blockers=["structural_dependency"], score=70, exposure=34),
            _cut("Mizzix's Mastery", "wincon", status="blocked", blockers=["structural_dependency"], score=10, exposure=97),
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
        "Call Forth the Tempest",
        "Tempt with Bunnies",
        "Everything Comes to Dust",
        "Mizzix's Mastery",
    ]


def test_protected_or_mana_cuts_are_not_diagnostic_eligible():
    seed_safe = {
        "seed_safe_cut_candidates": [],
        "cut_slots": [
            _cut("Bender's Waterskin", "early_mana", status="blocked", blockers=["protected_cut"], score=100, exposure=1),
            _cut("Radiant Summit", "mana_base", status="blocked", blockers=[], score=90, exposure=2),
            _cut("Flawless Maneuver", "protection", status="blocked", blockers=[], score=80, exposure=3),
            _cut("Call Forth the Tempest", "spell_velocity", status="blocked", blockers=["structural_dependency"], score=70, exposure=4),
        ],
    }

    plan = resolver.build_diagnostic_tradeoff_plan(seed_safe["cut_slots"], add_count=1)

    assert plan["status"] == "diagnostic_plan_available"
    assert [row["card_name"] for row in plan["selected_cuts"]] == ["Call Forth the Tempest"]
    assert plan["blocked_reason_counts"]["protected_cut"] == 1
    assert plan["blocked_reason_counts"]["diagnostic_lane_excluded:mana_base"] == 1
    assert plan["blocked_reason_counts"]["diagnostic_lane_excluded:protection"] == 1


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

    assert payload["summary"]["decision_status"] == "no_viable_cut_plan"
    assert payload["diagnostic_tradeoff_cut_plan"]["status"] == "not_available"
