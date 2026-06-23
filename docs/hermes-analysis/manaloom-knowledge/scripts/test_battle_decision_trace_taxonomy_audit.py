#!/usr/bin/env python3
"""Tests for battle decision trace taxonomy audit."""

from __future__ import annotations

import json
import tempfile
from pathlib import Path

import battle_decision_trace_taxonomy_audit as audit_module


def write_engine(path: Path, decision_types: list[str]) -> None:
    calls = "\n".join(
        f'emit_decision_trace(decision_type="{decision_type}")'
        for decision_type in decision_types
    )
    path.write_text(
        "def emit_decision_trace(**kwargs):\n    return kwargs\n" + calls + "\n",
        encoding="utf-8",
    )


def base_decision(decision_type: str, score_components: dict[str, object]) -> dict[str, object]:
    return {
        "available_options": [{"action": "option", "score": 1}],
        "chosen_option": {"action": "option", "score": 1},
        "confidence": "medium",
        "decision_id": f"decision-{decision_type}",
        "decision_type": decision_type,
        "expected_benefit_score": 1,
        "phase": "precombat_main",
        "player": "Lorehold",
        "rule_source": "test",
        "rule_status": "verified",
        "score_components": score_components,
        "turn": 1,
        "alternatives_considered": [{"action": "option"}],
        "heuristic_version": "test",
        "resource_delta": {"cards": 0},
        "risk_flags": [],
        "strategic_principle": "test_contract",
    }


def write_trace(path: Path, decisions: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "\n".join(json.dumps(decision) for decision in decisions) + "\n",
        encoding="utf-8",
    )


def test_known_field_contract_waivers_are_not_generic_only_gaps():
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        engine = tmp / "engine.py"
        write_engine(
            engine,
            [
                "utility_artifact_activation",
                "lorehold_upkeep_rummage",
                "saga_chapter_resolution",
            ],
        )
        write_trace(
            tmp / "seed_1/replay.decision_trace.jsonl",
            [
                base_decision(
                    "utility_artifact_activation",
                    {"activation_cost_generic": 1, "cards_drawn": 1},
                ),
                base_decision(
                    "lorehold_upkeep_rummage",
                    {"discard_destination": "graveyard", "drawn_card": "Lightning Bolt"},
                ),
                base_decision(
                    "land_tax_upkeep_tutor",
                    {
                        "player_land_count": 1,
                        "opponent_land_counts": [{"player": "Opponent", "lands": 2}],
                        "max_opponent_land_count": 2,
                        "candidate_count": 1,
                        "selected_count": 1,
                        "max_count": 3,
                        "reveals": True,
                        "shuffle_after": True,
                    },
                ),
                base_decision(
                    "saga_chapter_resolution",
                    {"chapter": 3, "candidate_count": 2, "selected_reason": "best_target"},
                ),
            ],
        )

        audit = audit_module.build_audit(input_dir=tmp, engine_source=engine)
        summary = audit["summary"]

    assert summary["decision_trace_observed_without_specific_contract"] == 0
    assert summary["decision_trace_kinds_without_specific_contract"] == 0
    assert summary["decision_trace_contract_findings"] == 0
    assert summary["status"] == "decision_trace_taxonomy_ready"


def test_observed_unknown_decision_type_is_reported():
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        engine = tmp / "engine.py"
        write_engine(engine, ["new_unowned_decision"])
        write_trace(
            tmp / "seed_1/replay.decision_trace.jsonl",
            [base_decision("new_unowned_decision", {"heuristic": 1})],
        )

        audit = audit_module.build_audit(input_dir=tmp, engine_source=engine)
        summary = audit["summary"]

    assert summary["decision_trace_observed_without_specific_contract"] == 1
    assert summary["decision_trace_kinds_without_specific_contract"] == 1
    assert summary["decision_trace_observed_without_contract"] == 1
    assert audit["findings"][0]["code"] == "decision_type_without_contract"
    assert summary["status"] == "review_required"


def test_missing_type_specific_score_key_is_reported():
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        engine = tmp / "engine.py"
        write_engine(engine, ["lorehold_upkeep_rummage"])
        write_trace(
            tmp / "seed_1/replay.decision_trace.jsonl",
            [base_decision("lorehold_upkeep_rummage", {"drawn_card": "Lightning Bolt"})],
        )

        audit = audit_module.build_audit(input_dir=tmp, engine_source=engine)
        summary = audit["summary"]

    assert summary["decision_trace_observed_without_specific_contract"] == 0
    assert summary["decision_trace_contract_findings"] == 1
    assert "score_components.discard_destination" in audit["findings"][0]["missing"]
    assert summary["status"] == "review_required"


if __name__ == "__main__":
    tests = [
        test_known_field_contract_waivers_are_not_generic_only_gaps,
        test_observed_unknown_decision_type_is_reported,
        test_missing_type_specific_score_key_is_reported,
    ]
    for test in tests:
        test()
    print(f"{len(tests)} tests passed")
