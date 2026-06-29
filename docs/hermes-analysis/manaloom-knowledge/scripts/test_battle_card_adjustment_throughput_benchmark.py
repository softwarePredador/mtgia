#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

import battle_card_adjustment_throughput_benchmark as benchmark


REPO_ROOT = Path(__file__).resolve().parents[4]


def test_dry_run_benchmark_is_network_free_and_reports_estimates() -> None:
    report = benchmark.build_report(live=False, limit=5, timeout_seconds=1)

    assert report["mode"] == "dry_run"
    assert report["postgres_writes"] is False
    assert report["sample_card_count"] == 5
    assert {item["id"] for item in report["benchmarks"]} == {
        "local_lookup_attempt_planning",
        "scryfall_collection_bulk_oracle",
        "scryfall_bulk_cache_lookup",
        "scryfall_named_hard_fallback",
        "local_source_gate_audit",
    }
    assert report["throughput"]["verdict"] == "pass"
    assert "local_planning_seconds_per_card" in report["throughput"]["estimates"]
    assert "bulk_cache_lookup_seconds_per_card" in report["throughput"]["estimates"]


def test_collection_identifier_uses_safe_exact_lookup_attempt() -> None:
    planner = benchmark.load_planner()
    identifier = benchmark.exact_collection_identifier_for_name(
        planner,
        "1 Emeria's Call // Emeria, Shattered Skyclave (ZNR)",
    )

    assert identifier == {"name": "Emeria's Call // Emeria, Shattered Skyclave"}


def test_classify_throughput_recommends_bulk_cache_when_it_beats_live_collection() -> None:
    results = [
        benchmark.TimedResult(
            id="local_lookup_attempt_planning",
            mode="local",
            card_count=10,
            elapsed_seconds=0.001,
            success_count=10,
            failure_count=0,
        ),
        benchmark.TimedResult(
            id="scryfall_collection_bulk_oracle",
            mode="live",
            card_count=10,
            elapsed_seconds=1.0,
            success_count=10,
            failure_count=0,
        ),
        benchmark.TimedResult(
            id="scryfall_bulk_cache_lookup",
            mode="live",
            card_count=10,
            elapsed_seconds=0.001,
            success_count=10,
            failure_count=0,
            details={"load_and_index_elapsed_seconds": 0.2},
        ),
        benchmark.TimedResult(
            id="scryfall_named_hard_fallback",
            mode="live",
            card_count=2,
            elapsed_seconds=1.0,
            success_count=2,
            failure_count=0,
        ),
    ]

    classified = benchmark.classify_throughput(results)

    assert classified["verdict"] == "pass"
    assert classified["estimates"]["oracle_bulk_seconds_per_card"] == 0.1
    assert classified["estimates"]["bulk_cache_lookup_seconds_per_card"] == 0.0001
    assert "Use local Scryfall Oracle Cards cache" in classified["recommendations"][0]


if __name__ == "__main__":
    test_dry_run_benchmark_is_network_free_and_reports_estimates()
    test_collection_identifier_uses_safe_exact_lookup_attempt()
    test_classify_throughput_recommends_bulk_cache_when_it_beats_live_collection()
    print("3 tests passed")
