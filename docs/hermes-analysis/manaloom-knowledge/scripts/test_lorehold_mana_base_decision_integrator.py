import json
from pathlib import Path

import lorehold_mana_base_decision_integrator as integrator


def write_json(path: Path, payload: dict) -> Path:
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def safe_model_payload() -> dict:
    return {
        "top_model_ready_pairs": [
            {
                "add": "Plateau",
                "cut": "Radiant Summit",
                "pair_score": 154,
                "status": "model_ready_for_candidate_materialization",
            },
            {
                "add": "Plateau",
                "cut": "Turbulent Steppe",
                "pair_score": 144,
                "status": "model_ready_for_candidate_materialization",
            },
        ],
        "current_lands": [
            {
                "card_name": "Radiant Summit",
                "oracle_text": "This land enters tapped unless you control two or more basic lands.",
            },
            {
                "card_name": "Turbulent Steppe",
                "oracle_text": "This land enters tapped unless your opponents control eight or more lands.",
            },
        ],
    }


def rejected_decision_payload() -> dict:
    return {
        "status": "reject_promotion_keep_607_current_baseline",
        "summary": {
            "candidate": "+Plateau / -Radiant Summit",
            "promotion_allowed": False,
            "full_confirmation_allowed_now": False,
            "blockers": [
                "forced_opening_hand_diagnostic_lost_to_607",
                "natural_smoke_lost_to_607",
            ],
        },
    }


def test_integrator_blocks_exact_rejected_pair_and_keeps_distinct_cut_diagnostic(tmp_path: Path) -> None:
    safe_model = write_json(tmp_path / "safe_model.json", safe_model_payload())
    decision = write_json(tmp_path / "decision.json", rejected_decision_payload())

    payload = integrator.build_payload(
        safe_cut_model_path=safe_model,
        decision_report_paths=[decision],
    )

    assert payload["status"] == "mana_base_next_diagnostic_pair_available"
    assert payload["summary"]["exact_rejected_pair_count"] == 1
    assert payload["summary"]["eligible_model_ready_pair_count"] == 1
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["summary"]["allow_natural_gate_now"] is False

    blocked, eligible = payload["annotated_model_ready_pairs"]
    assert blocked["learning_status"] == "blocked_exact_tested_decision"
    assert blocked["next_action"] == "do_not_retest_exact_pair_without_new_mana_trace_evidence"
    assert "natural_smoke_lost_to_607" in blocked["decision_blockers"]

    assert eligible["learning_status"] == "eligible_for_materialization_after_prior_decision_filter"
    assert eligible["cut"] == "Turbulent Steppe"
    assert eligible["same_added_card_prior_rejects"][0]["cut"] == "Radiant Summit"
    assert "opponents control eight or more lands" in eligible["cut_oracle_text"]
    assert payload["best_next_pair"]["cut"] == "Turbulent Steppe"
    assert payload["decision"]["next_action"] == "materialize_best_next_mana_base_pair_as_diagnostic"


def test_write_outputs_creates_integrator_report(tmp_path: Path) -> None:
    payload = integrator.build_payload(
        safe_cut_model_path=write_json(tmp_path / "safe_model.json", safe_model_payload()),
        decision_report_paths=[write_json(tmp_path / "decision.json", rejected_decision_payload())],
    )
    json_path, md_path = integrator.write_outputs(payload, tmp_path / "integrator")

    assert json_path.exists()
    assert md_path.exists()
    assert json.loads(json_path.read_text(encoding="utf-8"))["status"] == "mana_base_next_diagnostic_pair_available"
    assert "+Plateau / -Turbulent Steppe" in md_path.read_text(encoding="utf-8")
