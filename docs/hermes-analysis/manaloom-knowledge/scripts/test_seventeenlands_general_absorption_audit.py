#!/usr/bin/env python3
from __future__ import annotations

import seventeenlands_general_absorption_audit as audit


def fixture_profile() -> dict[str, object]:
    return {
        "header": {"field_count": 100, "max_turn_column": 10},
        "manaloom_general_adjustments": [
            {
                "adjustment": "Compare rhythm.",
                "area": "battle_replay_cadence_gate",
                "status": "ready",
            },
            {
                "adjustment": "Keep rules separate.",
                "area": "card_rule_promotion",
                "status": "blocked_by_methodology",
            },
        ],
        "manaloom_signal_coverage": {
            "battle_prior_ready": True,
            "deckbuilder_access_gate_ready": True,
            "runtime_rule_oracle_ready": False,
        },
        "not_recommended_use": ["Do not promote card battle rules directly from replay_data."],
        "rows_sampled": 2,
        "sample_summary": {
            "card_observation_metrics": {
                "top_by_direct_use": [
                    {"arena_id": "1234", "direct_use_entries": 2, "natural_access_entries": 1}
                ],
                "top_by_natural_access": [
                    {"arena_id": "1235", "direct_use_entries": 1, "natural_access_entries": 3}
                ],
                "top_by_total_observations": [
                    {"arena_id": "1236", "total_observation_entries": 5}
                ],
            },
            "turn_behavior_metrics": {"1": {}, "2": {}},
        },
        "source": "fixture.csv",
    }


def test_build_absorption_audit_keeps_17lands_general_and_read_only() -> None:
    report = audit.build_absorption_audit(
        fixture_profile(),
        profile_path=audit.DEFAULT_PROFILE_JSON,
    )
    assert report["status"] == "general_absorption_ready"
    assert report["postgres_writes"] is False
    assert report["source_db_mutated"] is False
    contracts = {item["contract"]: item["status"] for item in report["absorbed_into_manaloom"]}
    assert contracts["general_signal_coverage"] == "implemented"
    assert contracts["card_access_vs_use_metrics"] == "implemented"
    assert contracts["candidate_scoreability_thresholds"] == "implemented"
    assert report["card_observation_metric_sample"]["top_by_direct_use_first"]["arena_id"] == "1234"
    assert any("Do not promote" in item for item in report["blocked_uses"])


if __name__ == "__main__":
    test_build_absorption_audit_keeps_17lands_general_and_read_only()
    print("1 tests passed")
