#!/usr/bin/env python3
from __future__ import annotations

import battle_external_engine_crosscheck as crosscheck


def test_engine_registry_matches_current_external_execution_roles() -> None:
    engines = {engine.id: engine for engine in crosscheck.ENGINE_REGISTRY}

    assert set(engines) == {"forge", "magarena", "cockatrice"}
    assert engines["forge"].confidence_role == "structured_xmage_coverage_gap_executor"
    assert engines["forge"].adapter_status == "implemented_pinned_sidecar"
    assert "PostgreSQL" in engines["forge"].do_not_use_for
    assert engines["cockatrice"].role == "manual_game_client_and_replay_surface"


def test_crosscheck_plan_builds_card_candidate_links() -> None:
    plan = crosscheck.build_crosscheck_plan(["Approach of the Second Sun", "Pinnacle Monk // Mystic Peak"])

    assert plan["postgres_writes"] is False
    assert plan["registry_status"] == "external_engine_roles_current"
    assert plan["engine_count"] == 3
    assert plan["cards_requested"] == 2
    first = plan["cards"][0]
    assert first["normalized_slug"] == "approach_of_the_second_sun"
    assert len(first["engine_candidates"]) == 3
    forge = first["engine_candidates"][0]
    assert forge["engine_id"] == "forge"
    assert "Approach+of+the+Second+Sun" in forge["candidate_links"][0]

    split = plan["cards"][1]
    assert split["normalized_slug"] == "pinnacle_monk"


if __name__ == "__main__":
    test_engine_registry_matches_current_external_execution_roles()
    test_crosscheck_plan_builds_card_candidate_links()
    print("2 tests passed")
