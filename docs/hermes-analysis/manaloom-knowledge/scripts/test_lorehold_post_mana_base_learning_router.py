import json
from pathlib import Path

import lorehold_post_mana_base_learning_router as router


def write_json(path: Path, payload: dict) -> Path:
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def fixture_reports(tmp_path: Path, *, diagnostic_tradeoff: bool = True) -> dict[str, Path]:
    return {
        "mana_base_path": write_json(
            tmp_path / "mana_base.json",
            {
                "status": "mana_base_model_ready_queue_exhausted_by_decisions",
                "summary": {"eligible_model_ready_pair_count": 0},
            },
        ),
        "hypothesis_queue_path": write_json(
            tmp_path / "hypothesis.json",
            {
                "status": "lorehold_hypothesis_queue_ready_no_natural_gate",
                "summary": {"natural_gate_ready_count": 0},
            },
        ),
        "diagnostic_planner_path": write_json(
            tmp_path / "diagnostic.json",
            {
                "summary": {
                    "recommended_next_action": "build_pressure_safe_spell_payoff_micro_shell_contract",
                    "top_diagnostic_key": "pressure_safe_spell_payoff_micro_shell",
                },
            },
        ),
        "pressure_micro_path": write_json(
            tmp_path / "pressure_micro.json",
            {
                "status": "pressure_micro_package_no_gate_ready_keep_607",
                "summary": {
                    "gate_ready_package_count": 0,
                    "seed_safe_cut_ready_count": 0,
                    "natural_trigger_cards": ["Guttersnipe", "Young Pyromancer"],
                },
            },
        ),
        "pressure_cut_pool_path": write_json(
            tmp_path / "pressure_cut.json",
            {
                "summary": {
                    "diagnostic_tradeoff_plan_available": diagnostic_tradeoff,
                    "gate_ready_plan_complete": False,
                },
            },
        ),
        "external_shell_path": write_json(
            tmp_path / "external_shell.json",
            {"summary": {"promotable_shell_count": 0}},
        ),
        "pressure_tradeoff_path": write_json(
            tmp_path / "pressure_tradeoff.json",
            {"summary": {"promotion_allowed": False}},
        ),
        "spell_pressure_topdeck_path": write_json(
            tmp_path / "spell_pressure.json",
            {"summary": {"aggregate_delta_wins": 1}},
        ),
        "promotion_readiness_path": write_json(
            tmp_path / "promotion.json",
            {"summary": {"gate_ready_candidate_count": 0}},
        ),
    }


def test_router_selects_pressure_safe_cut_expansion_after_mana_base_closure(tmp_path: Path) -> None:
    payload = router.build_payload(**fixture_reports(tmp_path))

    assert payload["status"] == "post_mana_base_route_cut_safety_expansion_required"
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["summary"]["natural_battle_allowed_now"] is False
    assert payload["summary"]["recommended_next_route"] == "build_pressure_safe_cut_expansion_model"
    routes = {row["route_key"]: row for row in payload["routes"]}
    assert routes["close_simple_mana_base_swaps"]["allowed_now"] is False
    assert routes["build_pressure_safe_cut_expansion_model"]["priority"] == "P1_next"
    assert routes["build_pressure_safe_cut_expansion_model"]["allowed_now"] is True


def test_router_stops_when_no_cut_safety_route_is_available(tmp_path: Path) -> None:
    payload = router.build_payload(**fixture_reports(tmp_path, diagnostic_tradeoff=False))

    assert payload["status"] == "post_mana_base_no_allowed_next_route"
    assert payload["summary"]["recommended_next_route"] is None
    assert payload["decision"]["next_action"] == "stop_before_battle_until_a_route_has_safe_cuts"


def test_write_outputs_creates_router_report(tmp_path: Path) -> None:
    payload = router.build_payload(**fixture_reports(tmp_path))
    json_path, md_path = router.write_outputs(payload, tmp_path / "router")

    assert json_path.exists()
    assert md_path.exists()
    assert "Lorehold Post-Mana-Base Learning Router" in md_path.read_text(encoding="utf-8")
