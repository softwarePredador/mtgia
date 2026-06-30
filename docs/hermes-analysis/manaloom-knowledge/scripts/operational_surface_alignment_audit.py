#!/usr/bin/env python3
"""Audit ManaLoom battle/rules/deckbuilding surfaces against current contracts.

This is a static governance audit. It does not promote card rules, mutate
PostgreSQL, mutate Hermes SQLite, run battles, or decide deck swaps.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DOCS_DIR = REPO_ROOT / "docs" / "hermes-analysis"
REPORT_DIR = DOCS_DIR / "master_optimizer_reports"

README = DOCS_DIR / "README.md"
SCRIPTS_README = SCRIPT_DIR / "README.md"
OPERATIONAL_LOOKUP_GUIDE = DOCS_DIR / "MANALOOM_OPERATIONAL_LOOKUP_GUIDE_2026-06-30.md"
FAILURE_MODE_MATRIX = DOCS_DIR / "MANALOOM_FAILURE_MODE_VALIDATION_MATRIX_2026-06-30.md"
XMAGE_FLOW = DOCS_DIR / "XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md"
BATTLE_RULES_CONTRACT = DOCS_DIR / "BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md"
DECKBUILDING_CONTRACT = DOCS_DIR / "COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"
XMAGE_AUDIT = SCRIPT_DIR / "xmage_strategy_consistency_audit.py"
DECKBUILDING_AUDIT = SCRIPT_DIR / "deckbuilding_contract_surface_audit.py"
LOREHOLD_ARTIFACT_AUDIT = SCRIPT_DIR / "lorehold_artifact_contract_audit.py"
LOREHOLD_PROMOTION_DECISION_AUDIT = SCRIPT_DIR / "lorehold_promotion_gate_decision_audit.py"
VARIANT_MATRIX = SCRIPT_DIR / "lorehold_variant_strategy_matrix.py"
VARIANT_GATE = SCRIPT_DIR / "lorehold_variant_battle_gate.py"
STRATEGY_LEARNING_AUDIT = SCRIPT_DIR / "lorehold_strategy_learning_audit.py"
IDEAL_MATRIX = SCRIPT_DIR / "lorehold_ideal_deck_candidate_matrix.py"
LOREHOLD_ACCESS_CUT_MODEL = SCRIPT_DIR / "lorehold_access_cut_model.py"
LOREHOLD_HAND_FILTER_CUT_MODEL = SCRIPT_DIR / "lorehold_hand_filter_cut_model.py"
LOREHOLD_TUTOR_CUT_MODEL = SCRIPT_DIR / "lorehold_tutor_cut_model.py"
LOREHOLD_RECURSION_CUT_MODEL = SCRIPT_DIR / "lorehold_recursion_cut_model.py"
LOREHOLD_SAFE_CUT_REPLANNER = SCRIPT_DIR / "lorehold_safe_cut_replanner.py"
LOREHOLD_MANUAL_CUT_REVIEW = SCRIPT_DIR / "lorehold_manual_cut_review.py"
LOREHOLD_FOCUS_ACCESS_GENERATOR = SCRIPT_DIR / "lorehold_focus_access_package_generator.py"
LOREHOLD_REGISTRY_CANDIDATE_RUNNER = SCRIPT_DIR / "lorehold_registry_candidate_runner.py"
LOREHOLD_LOSS_FAILURE_CLASSIFIER = SCRIPT_DIR / "lorehold_loss_failure_classifier.py"
LEGACY_CONTAMINATION_AUDIT = SCRIPT_DIR / "legacy_contamination_audit.py"
BUILD_OPTIMIZED_DECK = SCRIPT_DIR / "build_optimized_deck.py"
UNIVERSAL_OPTIMIZER = SCRIPT_DIR / "universal_optimizer.py"
ROUTE_GENERATE = REPO_ROOT / "server" / "routes" / "ai" / "generate" / "index.dart"
DECKBUILDING_SUPPORT = REPO_ROOT / "server" / "lib" / "ai" / "commander_deckbuilding_contract_support.dart"
REBUILD_GUIDED_SERVICE = REPO_ROOT / "server" / "lib" / "ai" / "rebuild_guided_service.dart"
LEGACY_CONTAMINATION_BASELINE = DOCS_DIR / "LEGACY_CONTAMINATION_BASELINE_2026-06-30.json"

CURRENT_XMAGE_MANIFEST = (
    "xmage_current_replay_batch_pipeline_20260630_post_pg276_assemble_the_players_manifest.md"
)
CURRENT_LOREHOLD_MATRIX = "lorehold_variant_strategy_matrix_20260629_deckbuilding_contract"

FORBIDDEN_OPERATIONAL_SNIPPETS = {
    README: [
        "Decisao atual para acelerar XMage -> ManaLoom: usar\n    `hybrid_effective_queue_pattern_registry`",
        "Workflow operacional atual para a fila real Lorehold 608-616",
        "xmage_current_replay_batch_pipeline_20260629_135909_post_adagia_family_mapper_lorehold_6_607_616_manifest.md",
    ],
    XMAGE_AUDIT: [
        "xmage_current_replay_batch_pipeline_20260629_145746_post_pg249_pg250_apply_sync_manifest.md",
    ],
    BUILD_OPTIMIZED_DECK: [
        "replacement=lorehold_ideal_deck_candidate_matrix.py",
        "generate_matrix_then_use_slot_optimizer_with_baseline_hash_guard",
    ],
    UNIVERSAL_OPTIMIZER: [
        "replacement=lorehold_ideal_deck_candidate_matrix.py_then_slot_optimizer.py",
    ],
}


@dataclass
class Check:
    name: str
    status: str
    detail: str

    def as_dict(self) -> dict[str, str]:
        return {"name": self.name, "status": self.status, "detail": self.detail}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def check_contains(path: Path, patterns: list[str], name: str) -> Check:
    if not path.exists():
        return Check(name, "fail", f"missing_file:{rel(path)}")
    text = read(path)
    missing = [pattern for pattern in patterns if pattern not in text]
    if missing:
        return Check(name, "fail", "missing=" + json.dumps(missing, ensure_ascii=True))
    return Check(name, "pass", rel(path))


def check_absent(path: Path, patterns: list[str], name: str) -> Check:
    if not path.exists():
        return Check(name, "fail", f"missing_file:{rel(path)}")
    text = read(path)
    present = [pattern for pattern in patterns if pattern in text]
    if present:
        return Check(name, "fail", "present=" + json.dumps(present, ensure_ascii=True))
    return Check(name, "pass", rel(path))


def file_inventory() -> dict[str, int]:
    script_files = [path for path in SCRIPT_DIR.iterdir() if path.is_file()]
    top_docs = [path for path in DOCS_DIR.iterdir() if path.is_file() and path.suffix == ".md"]
    report_files = [path for path in REPORT_DIR.iterdir() if path.is_file()] if REPORT_DIR.exists() else []
    return {
        "script_files": len(script_files),
        "top_level_docs": len(top_docs),
        "report_files": len(report_files),
    }


def build_checks() -> list[Check]:
    checks = [
        check_contains(
            README,
            [
                "Status atual: canonico",
                "XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md",
                "COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md",
                "MANALOOM_OPERATIONAL_LOOKUP_GUIDE_2026-06-30.md",
                "MANALOOM_FAILURE_MODE_VALIDATION_MATRIX_2026-06-30.md",
                "legacy_contamination_audit.py",
                CURRENT_XMAGE_MANIFEST,
                "build_optimized_deck.py` e `universal_optimizer.py` ficam como historicos",
            ],
            "docs.root_readme_routes_current_contracts",
        ),
        check_contains(
            OPERATIONAL_LOOKUP_GUIDE,
            [
                "Status: `current_lookup_index`",
                "resolve_default_knowledge_db()",
                "lorehold_failure_targeted_synergy_hypotheses.py",
                "--allow-legacy-registry-runner",
                "--candidate-deck-id 607",
                "MANALOOM_FAILURE_MODE_VALIDATION_MATRIX_2026-06-30.md",
                "legacy_contamination_audit.py",
                "xmage_strategy_consistency_audit.py",
                "--output-prefix",
            ],
            "docs.operational_lookup_guide_covers_lookup_params_and_legacy_blocks",
        ),
        check_contains(
            FAILURE_MODE_MATRIX,
            [
                "Status: `current_failure_mode_gate`",
                "raw multi-row intelligence joins",
                "protected baseline `607`",
                "inclusionRate",
                "legacy baseline `deck_6`",
                "PostgreSQL -> Hermes/SQLite",
                "Legacy contamination",
                "legacy_contamination_audit.py",
            ],
            "docs.failure_mode_matrix_exists_and_covers_old_bug_classes",
        ),
        check_contains(
            XMAGE_FLOW,
            [
                "Status: `current_operating_standard`",
                "PG267/PG271 runtime-rule checkpoint",
                CURRENT_XMAGE_MANIFEST,
                "ready_for_structured_xmage_pull_review_required=64",
                "xmage_source_valid_mapper_required=61",
                "runtime_family_required_count=0",
            ],
            "docs.xmage_flow_points_to_current_manifest",
        ),
        check_contains(
            BATTLE_RULES_CONTRACT,
            [
                "Status: `frozen_operating_contract`",
                "PostgreSQL `card_battle_rules` is the durable source of truth",
                "Hermes SQLite is cache/lab/runtime evidence and must not overwrite PostgreSQL",
                "Pattern registry rows are `shadow_only`, non-executable, and non-autopromotable",
            ],
            "docs.battle_rules_contract_freezes_source_boundaries",
        ),
        check_contains(
            DECKBUILDING_CONTRACT,
            [
                "Status: `frozen_operating_contract`",
                "Source Hierarchy",
                "Lorehold Promotion Gate",
                "deck `607` is the current protected structural",
                "deckbuilding_contract",
                "lorehold_artifact_contract_audit.py",
                "lorehold_promotion_gate_decision_audit.py",
                "keep `607` as protected baseline",
            ],
            "docs.deckbuilding_contract_freezes_lorehold_gate",
        ),
        check_contains(
            SCRIPTS_README,
            [
                "`battle_analyst_v9.py` is the active battle engine",
                "Legacy engines",
                "Refresh the SQLite battle cache from PostgreSQL first",
                "legacy_contamination_audit.py",
            ],
            "scripts.readme_names_active_engine_and_cache_boundary",
        ),
        check_contains(
            LEGACY_CONTAMINATION_AUDIT,
            [
                "LEGACY_CONTAMINATION_BASELINE_2026-06-30.json",
                "stale_sqlite_path",
                "hardcoded_pg_fallback",
                "legacy_deck6_current_default",
                "legacy_ranked_decks_schema",
                "raw_edhrec_inclusion_score",
                "excess_group_count",
            ],
            "scripts.legacy_contamination_audit_blocks_new_old_patterns",
        ),
        check_contains(
            LEGACY_CONTAMINATION_BASELINE,
            [
                "legacy_contamination_baseline",
                "allowed_max_by_category_file",
                "stale_sqlite_path",
                "hardcoded_pg_fallback",
                "legacy_deck6_current_default",
                "legacy_ranked_decks_schema",
            ],
            "docs.legacy_contamination_baseline_exists",
        ),
        check_contains(
            XMAGE_AUDIT,
            [
                CURRENT_XMAGE_MANIFEST,
                '"ready_for_structured_xmage_pull_review_required": 64',
                '"xmage_source_valid_mapper_required": 61',
                '"mapper_metadata_or_test_scenario_required": 61',
                '"split_family_scope_review_required": 64',
            ],
            "scripts.xmage_strategy_audit_uses_current_manifest",
        ),
        check_contains(
            DECKBUILDING_AUDIT,
            [
                CURRENT_LOREHOLD_MATRIX,
                "build_optimized_deck.py",
                "universal_optimizer.py",
                "historical_blocked_surfaces",
                "lorehold_artifact_contract_audit.py",
                "lorehold_promotion_gate_decision_audit.py",
            ],
            "scripts.deckbuilding_surface_audit_blocks_legacy",
        ),
        check_contains(
            LOREHOLD_ARTIFACT_AUDIT,
            [
                "strategy_matrix_current_v1",
                "strategy_matrix_legacy_ranked_decks_v0",
                "ready_for_real_deck_change",
            ],
            "scripts.lorehold_artifact_contract_audit_normalizes_history",
        ),
        check_contains(
            LOREHOLD_PROMOTION_DECISION_AUDIT,
            [
                "BASELINE_KEY = \"deck_607\"",
                "CHALLENGER_KEYS = (\"deck_614\", \"deck_615\")",
                "keep_protected_baseline",
                "ready_for_real_deck_change",
            ],
            "scripts.lorehold_promotion_gate_decision_audit_keeps_baseline_guard",
        ),
        check_contains(
            VARIANT_MATRIX,
            [CURRENT_LOREHOLD_MATRIX],
            "scripts.lorehold_variant_matrix_default_is_contract",
        ),
        check_contains(
            VARIANT_GATE,
            [
                f"{CURRENT_LOREHOLD_MATRIX}.json",
                "Aetherflux Reservoir",
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                "Mana Vault",
                "Molecule Man",
            ],
            "scripts.lorehold_variant_gate_uses_contract_matrix_and_focus_cards",
        ),
        check_contains(
            STRATEGY_LEARNING_AUDIT,
            [f"{CURRENT_LOREHOLD_MATRIX}.json"],
            "scripts.lorehold_strategy_learning_uses_contract_matrix",
        ),
        check_contains(
            LOREHOLD_ACCESS_CUT_MODEL,
            ["DEFAULT_BASELINE_DECK_ID = 607"],
            "scripts.lorehold_access_cut_model_defaults_to_protected_607",
        ),
        check_contains(
            LOREHOLD_HAND_FILTER_CUT_MODEL,
            ["DEFAULT_BASELINE_DECK_ID = 607"],
            "scripts.lorehold_hand_filter_cut_model_defaults_to_protected_607",
        ),
        check_contains(
            LOREHOLD_TUTOR_CUT_MODEL,
            ["DEFAULT_BASELINE_DECK_ID = 607"],
            "scripts.lorehold_tutor_cut_model_defaults_to_protected_607",
        ),
        check_contains(
            LOREHOLD_RECURSION_CUT_MODEL,
            ["DEFAULT_BASELINE_DECK_ID = 607"],
            "scripts.lorehold_recursion_cut_model_defaults_to_protected_607",
        ),
        check_contains(
            LOREHOLD_SAFE_CUT_REPLANNER,
            ["DEFAULT_BASELINE_DECK_ID = 607"],
            "scripts.lorehold_safe_cut_replanner_defaults_to_protected_607",
        ),
        check_contains(
            LOREHOLD_MANUAL_CUT_REVIEW,
            ["DEFAULT_BASELINE_DECK_ID = 607"],
            "scripts.lorehold_manual_cut_review_defaults_to_protected_607",
        ),
        check_contains(
            LOREHOLD_FOCUS_ACCESS_GENERATOR,
            ["lorehold_access_cut_model_20260630_post_pg276_lane_core_blocked.json"],
            "scripts.lorehold_focus_generator_uses_corrected_access_model",
        ),
        check_contains(
            LOREHOLD_FOCUS_ACCESS_GENERATOR,
            ["lorehold_runtime_gap_family_queue_20260630_post_pg280_kayla_music_box.json"],
            "scripts.lorehold_focus_generator_uses_current_runtime_gap_queue",
        ),
        check_contains(
            LOREHOLD_REGISTRY_CANDIDATE_RUNNER,
            [
                "blocked_legacy_registry_runner",
                "--allow-legacy-registry-runner",
                "lorehold_failure_targeted_synergy_hypotheses.py",
                "lorehold_exposure_aware_gate_queue.py",
            ],
            "scripts.lorehold_registry_runner_blocked_by_default",
        ),
        check_contains(
            LOREHOLD_LOSS_FAILURE_CLASSIFIER,
            [
                'CURRENT_BASELINE_KEY = "deck_607"',
                'LEGACY_BASELINE_KEY = "deck_6"',
                'CURRENT_BASELINE_PACKAGE_KEY = "protected_baseline_607"',
                'LEGACY_BASELINE_PACKAGE_KEY = "legacy_baseline_deck_6"',
            ],
            "scripts.lorehold_loss_classifier_labels_current_and_legacy_baselines",
        ),
        check_contains(
            IDEAL_MATRIX,
            [
                "historical Lorehold rule-first candidate matrix",
                "not the active Commander deckbuilding",
                "lorehold_variant_strategy_matrix.py",
                "lorehold_variant_battle_gate.py",
            ],
            "scripts.ideal_matrix_is_historical_methodology",
        ),
        check_contains(
            BUILD_OPTIMIZED_DECK,
            [
                "status=historical_disabled",
                "lorehold_variant_strategy_matrix.py_then_lorehold_variant_battle_gate.py",
            ],
            "scripts.build_optimized_deck_is_blocked",
        ),
        check_contains(
            UNIVERSAL_OPTIMIZER,
            [
                "legacy_deprecated_not_authorized_for_handoff",
                "lorehold_variant_strategy_matrix.py_then_lorehold_variant_battle_gate.py",
                "MANALOOM_ALLOW_LEGACY_UNIVERSAL_OPTIMIZER",
            ],
            "scripts.universal_optimizer_is_blocked_by_default",
        ),
        check_contains(
            ROUTE_GENERATE,
            [
                "commander_deckbuilding_contract_support.dart",
                "'deckbuilding_contract': deckbuildingContractDiagnostics",
            ],
            "server.ai_generate_emits_deckbuilding_contract",
        ),
        check_contains(
            DECKBUILDING_SUPPORT,
            [
                "commanderDeckbuildingContractVersion",
                "buildCommanderDeckbuildingContractDiagnostics",
                "ready_for_battle_gate",
            ],
            "server.deckbuilding_contract_support_exists",
        ),
        check_contains(
            REBUILD_GUIDED_SERVICE,
            [
                "rebuildGuidedEdhrecTopCardWeight",
                "card.inclusionRate * 20",
            ],
            "server.rebuild_guided_scores_edhrec_by_inclusion_rate",
        ),
    ]

    for path, patterns in FORBIDDEN_OPERATIONAL_SNIPPETS.items():
        checks.append(
            check_absent(
                path,
                patterns,
                f"forbidden_operational_stale_snippets.{path.name}",
            )
        )

    return checks


def build_report() -> dict[str, Any]:
    checks = build_checks()
    status_counts: dict[str, int] = {}
    for check in checks:
        status_counts[check.status] = status_counts.get(check.status, 0) + 1
    return {
        "generated_at": utc_now(),
        "status": "pass" if status_counts.get("fail", 0) == 0 else "fail",
        "inventory": file_inventory(),
        "summary": {
            "check_count": len(checks),
            "status_counts": status_counts,
        },
        "checks": [check.as_dict() for check in checks],
        "mutations_performed": [],
    }


def write_markdown(report: dict[str, Any], path: Path) -> None:
    lines = [
        "# Operational Surface Alignment Audit",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- Summary: `{json.dumps(report['summary'], sort_keys=True)}`",
        f"- Inventory: `{json.dumps(report['inventory'], sort_keys=True)}`",
        "",
        "| Check | Status | Detail |",
        "| --- | --- | --- |",
    ]
    for check in report["checks"]:
        detail = str(check.get("detail") or "").replace("|", "\\|")
        lines.append(f"| `{check['name']}` | `{check['status']}` | {detail} |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "operational_surface_alignment_audit_20260629",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report()
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_markdown(report, md_path)
    print(json.dumps({"status": report["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
