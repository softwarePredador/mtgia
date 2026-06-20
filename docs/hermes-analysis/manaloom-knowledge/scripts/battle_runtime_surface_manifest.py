#!/usr/bin/env python3
"""Build a manifest for the battle-related Python runtime surface."""

from __future__ import annotations

import argparse
import json
import os
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_REPO_ROOT = SCRIPT_DIR.parents[3]

SCAN_ROOTS = (
    "docs/hermes-analysis/manaloom-knowledge/scripts",
    "server/bin",
    "server/test",
)
FILENAME_TERMS = (
    "battle",
    "replay",
    "rule",
    "learned_deck",
    "learned-deck",
    "optimizer",
    "coherence",
)

ALLOWED_CATEGORIES = {
    "core runtime",
    "renderer",
    "recurring audit gate",
    "rule registry/sync",
    "review queue",
    "focused evidence/promotion",
    "learned-deck source",
    "optimizer/scorecard",
    "historical/deprecated",
}

CATEGORY_OWNER = {
    "core runtime": "battle-engine",
    "renderer": "battle-replay-renderer",
    "recurring audit gate": "battle-recurring-audit",
    "rule registry/sync": "battle-rule-registry",
    "review queue": "server-rule-review-queue",
    "focused evidence/promotion": "battle-focused-evidence",
    "learned-deck source": "learned-deck-pipeline",
    "optimizer/scorecard": "master-optimizer",
    "historical/deprecated": "battle-archive",
}

DIRECT_RECURRING_RUN_PATHS = {
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_trace_taxonomy_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_residual_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_target_pressure_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_trace_taxonomy_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_residual_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_registry_runtime_safe.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_target_pressure_audit.py",
    "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py",
}

CORE_SUPPORT_BASENAMES = {
    "battle_card_characteristics_support.py",
    "battle_land_support.py",
    "battle_mana_cost_support.py",
    "battle_replacement_support.py",
    "battle_sba_support.py",
    "battle_zone_transition_support.py",
}

CORE_TEST_BASENAMES = {
    "battle_card_import_tests.py",
    "battle_card_specific_tests.py",
    "battle_combat_tests.py",
    "battle_commander_tests.py",
    "battle_conformance_tests.py",
    "battle_continuous_effects_tests.py",
    "battle_decision_trace_tests.py",
    "battle_engine_metrics_tests.py",
    "battle_event_trigger_tests.py",
    "battle_mana_tests.py",
    "battle_misc_regression_tests.py",
    "battle_permanents_complex_tests.py",
    "battle_replacement_tests.py",
    "battle_rules_2026_tests.py",
    "battle_sba_zone_tests.py",
    "battle_stack_casting_tests.py",
    "battle_summoning_sickness_tests.py",
    "battle_targeting_tests.py",
    "battle_turn_flow_tests.py",
    "battle_zone_transition_tests.py",
    "test_battle_analyst_cli_help.py",
    "test_battle_analyst_v10_3.py",
    "test_battle_functional_tags_json.py",
    "test_battle_rule_alternatives.py",
}

RECURRING_GATE_BASENAMES = {
    "battle_action_critic.py",
    "battle_decision_strategy_auditor.py",
    "battle_decision_trace_taxonomy_audit.py",
    "battle_decision_research_review.py",
    "battle_event_contract_static_audit.py",
    "battle_effect_coverage_audit.py",
    "battle_effect_coverage_residual_audit.py",
    "battle_focused_template_dispatch_audit.py",
    "battle_forensic_audit.py",
    "replay_decision_auditor.py",
    "battle_runtime_surface_manifest.py",
    "battle_table_intent_audit.py",
    "battle_target_pressure_audit.py",
    "battle_unknown_template_backlog_audit.py",
    "test_battle_action_critic.py",
    "test_battle_decision_strategy_auditor.py",
    "test_battle_decision_trace_taxonomy_audit.py",
    "test_battle_decision_research_review.py",
    "test_battle_event_contract_static_audit.py",
    "test_battle_effect_coverage_known_cards.py",
    "test_battle_effect_coverage_residual_audit.py",
    "test_battle_focused_template_dispatch_audit.py",
    "test_battle_forensic_audit_supported_effects.py",
    "test_replay_decision_auditor_scope.py",
    "test_battle_runtime_surface_manifest.py",
    "test_battle_table_intent_audit.py",
    "test_battle_target_pressure_audit.py",
    "test_battle_unknown_template_backlog_audit.py",
}

RULE_REGISTRY_BASENAMES = {
    "audit_handcrafted_battle_rule_canonicalization.py",
    "audit_multi_rule_runtime_readiness.py",
    "battle_rule_registry.py",
    "derive_functional_tags_from_battle_rules.py",
    "reviewed_battle_card_rules.py",
    "sync_battle_card_rules.py",
    "sync_battle_card_rules_pg.py",
    "test_audit_handcrafted_battle_rule_canonicalization.py",
    "test_audit_multi_rule_runtime_readiness.py",
    "test_battle_rule_registry_runtime_safe.py",
    "test_derive_functional_tags_from_battle_rules.py",
    "test_reviewed_battle_card_rules.py",
    "test_runtime_pg_rule_fallback_for_promoted_hotfixes.py",
    "test_sync_battle_card_rules_manual_preserve.py",
    "test_sync_battle_card_rules_pg_selection.py",
}

LEARNED_DECK_BASENAMES = {
    "export_hermes_learned_deck.py",
    "learned_deck_completeness.py",
    "materialize_learned_deck_to_deck_cards.py",
    "auto_promote_learned_decks.py",
    "auto_sync_learned_decks.py",
    "learned_deck_coherence_audit.py",
    "plan_learned_deck_partner_identity_backfill.py",
    "test_export_hermes_learned_deck_metadata.py",
    "test_export_hermes_learned_deck_wrapper_parity.py",
    "test_learned_deck_completeness.py",
    "test_materialize_learned_deck_to_deck_cards.py",
    "auto_promote_learned_decks_test.py",
    "auto_sync_learned_decks_test.py",
    "learned_deck_coherence_audit_test.py",
    "plan_learned_deck_partner_identity_backfill_test.py",
}

OPTIMIZER_BASENAMES = {
    "master_optimizer_apply.py",
    "master_optimizer_baseline.py",
    "master_optimizer_common.py",
    "master_optimizer_confirmation.py",
    "master_optimizer_handoff.py",
    "master_optimizer_loop.py",
    "master_optimizer_post_apply_gate.py",
    "master_optimizer_product_handoff.py",
    "master_optimizer_quality_gate.py",
    "master_optimizer_rollback.py",
    "slot_optimizer.py",
    "universal_optimizer.py",
    "test_master_optimizer_hashes.py",
    "test_slot_optimizer_real_roles.py",
    "test_universal_optimizer_known_cards.py",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(os.environ.get("MANALOOM_REPO_DIR", DEFAULT_REPO_ROOT)),
    )
    parser.add_argument("--output", type=Path)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--fail-on-unclassified", action="store_true")
    return parser.parse_args()


def is_related_python_file(path: Path) -> bool:
    text = path.as_posix()
    return path.suffix == ".py" and any(term in text for term in FILENAME_TERMS)


def iter_related_files(repo_root: Path) -> list[Path]:
    files: list[Path] = []
    for root in SCAN_ROOTS:
        root_path = repo_root / root
        if not root_path.is_dir():
            continue
        for path in root_path.rglob("*.py"):
            rel = path.relative_to(repo_root)
            if is_related_python_file(rel):
                files.append(rel)
    return sorted(files, key=lambda item: item.as_posix())


def file_role(name: str) -> str:
    if name.startswith("test_") or name.endswith("_tests.py") or name.endswith("_test.py"):
        return "test"
    if name.endswith("_support.py"):
        return "support module"
    if name.startswith("audit_"):
        return "audit script"
    return "script"


def category_for(rel_path: Path) -> str | None:
    rel = rel_path.as_posix()
    name = rel_path.name

    if name in RECURRING_GATE_BASENAMES:
        return "recurring audit gate"
    if name in {"battle_replay_v10_3.py", "test_battle_replay_v10_3_renderer.py"}:
        return "renderer"
    if rel.startswith("server/bin/generate_card_replays.py") or name == "test_battle_runtime_cli_paths.py":
        return "renderer"
    if rel.startswith("server/bin/manaloom_battle_rule_review_queue.py"):
        return "review queue"
    if rel.startswith("server/bin/manaloom_battle_rule_focused_evidence.py"):
        return "focused evidence/promotion"
    if rel.startswith("server/bin/manaloom_battle_rule_promotion_gate.py"):
        return "focused evidence/promotion"
    if rel.startswith("server/bin/auto_promote_battle_rules.py"):
        return "focused evidence/promotion"
    if rel.startswith("server/bin/test_auto_promote_battle_rules.py"):
        return "focused evidence/promotion"
    if name in LEARNED_DECK_BASENAMES:
        return "learned-deck source"
    if name in OPTIMIZER_BASENAMES:
        return "optimizer/scorecard"
    if name in RULE_REGISTRY_BASENAMES:
        return "rule registry/sync"
    if name == "battle_analyst_v9.py" or name in CORE_SUPPORT_BASENAMES:
        return "core runtime"
    if name in CORE_TEST_BASENAMES:
        return "core runtime"
    return None


def automation_coverage(rel: str, category: str, role: str) -> str:
    if rel in DIRECT_RECURRING_RUN_PATHS:
        return "covered_by_recurring_run"
    if category == "core runtime" and role == "support module":
        return "imported_by_core_runtime"
    if category == "historical/deprecated":
        return "outside_recurring_run_historical"
    return "outside_recurring_run"


def gate_expected(category: str, coverage: str, role: str) -> str:
    if coverage == "covered_by_recurring_run":
        return "recurring_audit_required"
    if coverage == "imported_by_core_runtime":
        return "core_runtime_import_regression"
    if category == "historical/deprecated":
        return "freshness_check_before_use"
    if role == "test":
        return "targeted_test_required_before_change"
    return "targeted_manual_gate_required_before_change"


def build_manifest(repo_root: Path) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    records: list[dict[str, Any]] = []
    unclassified: list[str] = []

    for rel_path in iter_related_files(repo_root):
        rel = rel_path.as_posix()
        category = category_for(rel_path)
        if category is None:
            unclassified.append(rel)
            category = "unclassified"
        role = file_role(rel_path.name)
        coverage = automation_coverage(rel, category, role)
        record = {
            "path": rel,
            "category": category,
            "owner": CATEGORY_OWNER.get(category, "unassigned"),
            "role": role,
            "gate_expected": gate_expected(category, coverage, role),
            "automation_coverage": coverage,
        }
        records.append(record)

    category_counts = Counter(record["category"] for record in records)
    owner_counts = Counter(record["owner"] for record in records)
    gate_counts = Counter(record["gate_expected"] for record in records)
    coverage_counts = Counter(record["automation_coverage"] for record in records)

    recurring_categories = sorted(
        {
            record["category"]
            for record in records
            if record["automation_coverage"] == "covered_by_recurring_run"
        }
    )
    outside_categories = sorted(
        {
            record["category"]
            for record in records
            if record["automation_coverage"].startswith("outside_recurring_run")
        }
    )

    summary = {
        "total_files": len(records),
        "allowed_categories": sorted(ALLOWED_CATEGORIES),
        "category_counts": dict(sorted(category_counts.items())),
        "owner_counts": dict(sorted(owner_counts.items())),
        "gate_expected_counts": dict(sorted(gate_counts.items())),
        "automation_coverage_counts": dict(sorted(coverage_counts.items())),
        "recurring_categories": recurring_categories,
        "outside_recurring_categories": outside_categories,
        "unclassified_files": unclassified,
    }

    return {
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "repo_root": str(repo_root),
        "scan_roots": list(SCAN_ROOTS),
        "filename_terms": list(FILENAME_TERMS),
        "summary": summary,
        "files": records,
    }


def render_markdown(manifest: dict[str, Any]) -> str:
    summary = manifest["summary"]
    lines = [
        "# Battle Runtime Surface Manifest",
        "",
        f"- Generated UTC: `{manifest['generated_at_utc']}`",
        f"- Total related Python files: `{summary['total_files']}`",
        f"- Unclassified files: `{len(summary['unclassified_files'])}`",
        f"- Recurring categories covered: `{json.dumps(summary['recurring_categories'])}`",
        f"- Categories outside recurring run: `{json.dumps(summary['outside_recurring_categories'])}`",
        "",
        "## Category Counts",
        "",
        "| Category | Files |",
        "| --- | ---: |",
    ]
    for category, count in summary["category_counts"].items():
        lines.append(f"| `{category}` | `{count}` |")

    lines.extend(
        [
            "",
            "## Automation Coverage Counts",
            "",
            "| Coverage | Files |",
            "| --- | ---: |",
        ]
    )
    for coverage, count in summary["automation_coverage_counts"].items():
        lines.append(f"| `{coverage}` | `{count}` |")

    lines.extend(
        [
            "",
            "## Files",
            "",
            "| Path | Category | Owner | Role | Gate expected | Automation coverage |",
            "| --- | --- | --- | --- | --- | --- |",
        ]
    )
    for record in manifest["files"]:
        lines.append(
            "| `{path}` | `{category}` | `{owner}` | `{role}` | `{gate_expected}` | `{automation_coverage}` |".format(
                **record
            )
        )

    if summary["unclassified_files"]:
        lines.extend(["", "## Unclassified Files", ""])
        for path in summary["unclassified_files"]:
            lines.append(f"- `{path}`")

    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    manifest = build_manifest(args.repo_root)
    markdown = render_markdown(manifest)

    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(
            json.dumps(manifest, indent=2, sort_keys=True),
            encoding="utf-8",
        )
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(markdown, encoding="utf-8")
    if not args.output and not args.json_output:
        print(markdown)

    if args.fail_on_unclassified and manifest["summary"]["unclassified_files"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
