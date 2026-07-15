#!/usr/bin/env python3
"""Tests for the battle runtime surface manifest."""

from __future__ import annotations

from pathlib import Path

import battle_runtime_surface_manifest as manifest_mod


REPO_ROOT = Path(__file__).resolve().parents[4]
EXPECTED_TOTAL_FILES = 177
EXPECTED_CATEGORY_COUNTS = {
    "core runtime": 36,
    "focused evidence/promotion": 37,
    "learned-deck source": 16,
    "optimizer/scorecard": 30,
    "recurring audit gate": 32,
    "renderer": 4,
    "review queue": 1,
    "rule registry/sync": 21,
}
EXPECTED_AUTOMATION_COVERAGE_COUNTS = {
    "covered_by_recurring_run": 32,
    "imported_by_core_runtime": 7,
    "outside_recurring_run": 138,
}
EXPECTED_GATE_EXPECTED_COUNTS = {
    "core_runtime_import_regression": 7,
    "recurring_audit_required": 32,
    "targeted_manual_gate_required_before_change": 64,
    "targeted_test_required_before_change": 74,
}
REQUIRED_HIGH_SIGNAL_PATHS = {
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_adjustment_throughput_benchmark.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_acceleration_source_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_external_engine_crosscheck.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_mtga_player_log_parser.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/build_specialize_rule_registry.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/external_battle_async_runner.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/mtg_battle_external_source_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/seventeenlands_history_learning.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_card_adjustment_throughput_benchmark.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_card_acceleration_source_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_external_engine_crosscheck.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_mtga_player_log_parser.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_external_battle_async_runner.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_mtg_battle_external_source_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/global_commander_battle_feedback_model.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/global_commander_candidate_battle_probe_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/global_commander_larger_battle_gate_audit.py",
    "server/bin/manaloom_battle_rule_review_queue.py",
    "server/bin/manaloom_battle_rule_focused_evidence.py",
    "server/bin/manaloom_battle_product_e2e_audit.py",
    "server/bin/native_battle_sidecar.py",
    "server/bin/native_battle_worker.py",
    "server/bin/learned_deck_coherence_audit.py",
}


def test_manifest_classifies_current_battle_surface() -> None:
    manifest = manifest_mod.build_manifest(REPO_ROOT)
    summary = manifest["summary"]

    assert summary["total_files"] == EXPECTED_TOTAL_FILES
    assert summary["unclassified_files"] == []
    assert summary["category_counts"] == EXPECTED_CATEGORY_COUNTS
    assert summary["automation_coverage_counts"] == EXPECTED_AUTOMATION_COVERAGE_COUNTS
    assert summary["gate_expected_counts"] == EXPECTED_GATE_EXPECTED_COUNTS
    assert manifest["rules_alignment"]["source_contract"]["official_comprehensive_rules"][
        "url"
    ] == "https://magic.wizards.com/en/rules"
    assert {
        "official_comprehensive_rules",
        "xmage",
        "forge",
        "scryfall",
        "mtgjson",
        "commander",
    } <= set(manifest["rules_alignment"]["source_contract"])
    assert manifest["rules_alignment"]["status_counts"] == {
        "covered_by_core_tests": 4,
        "covered_with_known_mode_gaps": 1,
        "covered_with_known_scope_limits": 3,
        "family_mapper_required": 1,
        "partial_family_specific_support": 2,
    }
    assert {
        area["id"] for area in manifest["rules_alignment"]["areas"]
    } >= {
        "turn_priority_stack_casting_resolution",
        "mana_cost_payment_and_mana_abilities",
        "continuous_effect_layers",
        "card_specific_runtime_rules",
    }

    categories = set(summary["category_counts"])
    assert categories <= manifest_mod.ALLOWED_CATEGORIES
    assert {
        "core runtime",
        "renderer",
        "recurring audit gate",
        "rule registry/sync",
        "review queue",
        "focused evidence/promotion",
        "learned-deck source",
        "optimizer/scorecard",
    } <= categories

    recurring = set(summary["recurring_categories"])
    outside = set(summary["outside_recurring_categories"])
    assert {"core runtime", "renderer", "recurring audit gate"} <= recurring
    assert {
        "review queue",
        "focused evidence/promotion",
        "learned-deck source",
        "optimizer/scorecard",
    } <= outside

    for record in manifest["files"]:
        assert record["owner"] != "unassigned"
        assert record["gate_expected"]
        assert record["automation_coverage"]

    paths = {record["path"] for record in manifest["files"]}
    assert REQUIRED_HIGH_SIGNAL_PATHS <= paths


if __name__ == "__main__":
    test_manifest_classifies_current_battle_surface()
    print("PASS test_manifest_classifies_current_battle_surface")
