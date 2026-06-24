#!/usr/bin/env python3
"""Tests for the battle runtime surface manifest."""

from __future__ import annotations

from pathlib import Path

import battle_runtime_surface_manifest as manifest_mod


REPO_ROOT = Path(__file__).resolve().parents[4]
EXPECTED_TOTAL_FILES = 122
EXPECTED_CATEGORY_COUNTS = {
    "core runtime": 31,
    "focused evidence/promotion": 10,
    "learned-deck source": 16,
    "optimizer/scorecard": 15,
    "recurring audit gate": 28,
    "renderer": 4,
    "review queue": 1,
    "rule registry/sync": 17,
}
EXPECTED_AUTOMATION_COVERAGE_COUNTS = {
    "covered_by_recurring_run": 31,
    "imported_by_core_runtime": 6,
    "outside_recurring_run": 85,
}
EXPECTED_GATE_EXPECTED_COUNTS = {
    "core_runtime_import_regression": 6,
    "recurring_audit_required": 31,
    "targeted_manual_gate_required_before_change": 37,
    "targeted_test_required_before_change": 48,
}
REQUIRED_HIGH_SIGNAL_PATHS = {
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py",
    "server/bin/manaloom_battle_rule_review_queue.py",
    "server/bin/manaloom_battle_rule_focused_evidence.py",
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
