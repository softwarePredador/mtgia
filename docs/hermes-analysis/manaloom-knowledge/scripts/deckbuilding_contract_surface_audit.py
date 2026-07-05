#!/usr/bin/env python3
"""Audit active Commander deckbuilding surfaces against the frozen contract."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

CONTRACT_DOC = REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"
SUPPORT_FILE = REPO_ROOT / "server/lib/ai/commander_deckbuilding_contract_support.dart"
REFERENCE_PROFILE_SUPPORT_FILE = REPO_ROOT / "server/lib/ai/commander_reference_profile_support.dart"
STAPLE_POLICY_FILE = REPO_ROOT / "server/lib/ai/commander_staple_impact_policy.dart"
REBUILD_GUIDED_SERVICE = REPO_ROOT / "server/lib/ai/rebuild_guided_service.dart"
GENERATE_ROUTE = REPO_ROOT / "server/routes/ai/generate/index.dart"
SUPPORT_TEST = REPO_ROOT / "server/test/commander_deckbuilding_contract_support_test.dart"
VARIANT_MATRIX = SCRIPT_DIR / "lorehold_variant_strategy_matrix.py"
VARIANT_GATE = SCRIPT_DIR / "lorehold_variant_battle_gate.py"
ARTIFACT_CONTRACT_AUDIT = SCRIPT_DIR / "lorehold_artifact_contract_audit.py"
PROMOTION_DECISION_AUDIT = SCRIPT_DIR / "lorehold_promotion_gate_decision_audit.py"
GLOBAL_COMMANDER_AUDIT = SCRIPT_DIR / "global_commander_deck_contract_audit.py"
GLOBAL_COMMANDER_MATRIX = SCRIPT_DIR / "global_commander_strategy_matrix.py"
GLOBAL_COMMANDER_CORE_ROLE_AUDIT = SCRIPT_DIR / "global_commander_core_role_audit.py"
GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS = SCRIPT_DIR / "global_commander_core_repair_hypothesis.py"
GLOBAL_COMMANDER_MANA_BASE_PROFILE = SCRIPT_DIR / "global_commander_mana_base_profile.py"
GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL = SCRIPT_DIR / "global_commander_named_land_candidate_pool.py"
GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL = SCRIPT_DIR / "global_commander_land_cut_candidate_model.py"
GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL = SCRIPT_DIR / "global_commander_nonland_core_candidate_model.py"
GLOBAL_COMMANDER_LEARNING_PRIORITY_AUDIT = SCRIPT_DIR / "global_commander_learning_priority_audit.py"
GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER = SCRIPT_DIR / "global_commander_candidate_copy_materializer.py"
GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER_TEST = (
    SCRIPT_DIR / "test_global_commander_candidate_copy_materializer.py"
)
GLOBAL_COMMANDER_CANDIDATE_BATTLE_PROBE_AUDIT = (
    SCRIPT_DIR / "global_commander_candidate_battle_probe_audit.py"
)
README = REPO_ROOT / "docs/hermes-analysis/README.md"

CONTRACT_MATRIX_JSON = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.json"
)
CONTRACT_MATRIX_MD = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.md"
)
ARTIFACT_CONTRACT_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_20260629_v615_mana_engine_current.md"
)
PROMOTION_DECISION_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_decision_audit_20260629_v615_mana_engine_v1.md"
)
CUT_METHODOLOGY_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/lorehold_cut_methodology_reaudit_20260629.md"
)
GLOBAL_COMMANDER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_deck_contract_audit_20260701_post_scope_legalities.md"
)
GLOBAL_COMMANDER_MATRIX_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_strategy_matrix_20260701_current.md"
)
GLOBAL_COMMANDER_CORE_ROLE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_core_role_audit_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_core_repair_hypothesis_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_MANA_BASE_PROFILE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_mana_base_profile_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_named_land_candidate_pool_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_LEARNING_PRIORITY_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_learning_priority_audit_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_nonland_top_pair.md"
)
GLOBAL_COMMANDER_CANDIDATE_BATTLE_PROBE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_battle_probe_audit_20260705_kaalia_nonland_floor_dynamic_target.md"
)

REQUIRED_FOCUS_CARDS = {
    "Aetherflux Reservoir",
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
    "Mana Vault",
    "Molecule Man",
    "Sensei's Divining Top",
    "Scroll Rack",
}

HISTORICAL_BLOCKED_SURFACES = {
    SCRIPT_DIR / "build_optimized_deck.py": "status=historical_disabled",
    SCRIPT_DIR / "universal_optimizer.py": "legacy_deprecated_not_authorized_for_handoff",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def check_contains(path: Path, patterns: list[str]) -> dict[str, Any]:
    text = read(path)
    missing = [pattern for pattern in patterns if pattern not in text]
    return {
        "path": rel(path),
        "exists": path.exists(),
        "status": "pass" if path.exists() and not missing else "fail",
        "missing": missing,
    }


def build_audit() -> dict[str, Any]:
    checks: list[dict[str, Any]] = []
    checks.append(
        check_contains(
            CONTRACT_DOC,
            [
                "Status: `frozen_operating_contract`",
                "Source Hierarchy",
                "Lorehold Promotion Gate",
                "Research-Backed Deck Planning Flow",
                "Lane Order And Deck Overview Contract",
                "Staple Impact Policy",
                "staple_impact_and_role_policy",
                "staple_impact_by_role",
                "battle_cleared_with_cut_methodology_caveat",
                "decks[] + ranked_deck_keys",
                "lorehold_artifact_contract_audit.py",
                "lorehold_promotion_gate_decision_audit.py",
                "candidate_607_v615_mana_engine_v1",
                "Global Commander Rollout - 2026-07-01",
                "Global Commander Core Pivot - 2026-07-05",
                "benchmark/regression deck",
                "global_commander_deck_contract_audit.py",
                "global_commander_strategy_matrix.py",
                "global_commander_core_role_audit.py",
                "global_commander_core_role_audit_20260705_global_goal_hermes_only.md",
                "global_commander_core_repair_hypothesis.py",
                "global_commander_core_repair_hypothesis_20260705_global_goal_hermes_only.md",
                "global_commander_mana_base_profile.py",
                "global_commander_mana_base_profile_20260705_global_goal_hermes_only.md",
                "global_commander_named_land_candidate_pool.py",
                "global_commander_named_land_candidate_pool_20260705_global_goal_hermes_only.md",
                "global_commander_land_cut_candidate_model.py",
                "global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only.md",
                "global_commander_nonland_core_candidate_model.py",
                "global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only.md",
                "Kaalia Angel/Demon/Dragon creatures are blocked",
                "global_commander_learning_priority_audit.py",
                "global_commander_learning_priority_audit_20260705_global_goal_hermes_only.md",
                "global_commander_candidate_copy_materializer.py",
                "global_commander_candidate_copy_materializer_20260705_kaalia_nonland_top_pair.md",
                "must reject stale chained sources",
                "Bloodthirster",
                "global_commander_candidate_battle_probe_audit.py",
                "global_commander_candidate_battle_probe_audit_20260705_kaalia_nonland_floor_dynamic_target.md",
                "33.3%",
                "66.7%",
                "five Commander",
                "brackets `1..5`",
                "Game Changer budgets",
            ],
        )
    )
    checks.append(
        check_contains(
            SUPPORT_FILE,
            [
                "commanderDeckbuildingContractVersion",
                "commanderDeckPlanningFlowVersion",
                "commanderDeckPlanningFlow",
                "commanderDeckPlanningLaneOrder",
                "commanderDeckOverviewRequiredFields",
                "commanderStapleImpactPolicyDiagnostics",
                "buildCommanderDeckbuildingContractDiagnostics",
                "ready_for_battle_gate",
            ],
        )
    )
    checks.append(
        check_contains(
            REFERENCE_PROFILE_SUPPORT_FILE,
            [
                "kaaliaReferenceCommanderName",
                "buildKaaliaReferenceProfilePayload",
                "isKaaliaCommanderReferenceCandidate",
                "non_angel_demon_dragon_haymaker_as_kaalia_payoff",
                "haste_and_protection_for_attack_window",
            ],
        )
    )
    checks.append(
        check_contains(
            STAPLE_POLICY_FILE,
            [
                "commanderStapleImpactPolicyVersion",
                "commanderStapleImpactPolicyDiagnostics",
                "commanderStapleWeaknessMultiplier",
                "inclusionRate",
                "structural_foundation",
                "generic_or_low_context_signal",
            ],
        )
    )
    checks.append(
        check_contains(
            REBUILD_GUIDED_SERVICE,
            [
                "rebuildGuidedEdhrecTopCardWeight",
                "card.inclusionRate * 20",
            ],
        )
    )
    checks.append(
        check_contains(
            GENERATE_ROUTE,
            [
                "commander_deckbuilding_contract_support.dart",
                "'deckbuilding_contract': deckbuildingContractDiagnostics",
            ],
        )
    )
    checks.append(
        check_contains(
            SUPPORT_TEST,
            [
                "ready_for_battle_gate",
                "reference_lanes_missing",
                "planning_flow",
                "staple_impact_and_role_policy",
                "staple_impact_by_role",
                "lane_balanced_cuts_and_anchor_protection",
            ],
        )
    )
    checks.append(
        check_contains(
            VARIANT_MATRIX,
            ["lorehold_variant_strategy_matrix_20260629_deckbuilding_contract"],
        )
    )
    checks.append(
        check_contains(
            VARIANT_GATE,
            [
                "lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.json",
                *sorted(REQUIRED_FOCUS_CARDS),
            ],
        )
    )
    checks.append(
        check_contains(
            ARTIFACT_CONTRACT_AUDIT,
            [
                "strategy_matrix_current_v1",
                "strategy_matrix_legacy_ranked_decks_v0",
                "ready_for_real_deck_change",
            ],
        )
    )
    checks.append(
        check_contains(
            PROMOTION_DECISION_AUDIT,
            [
                "BASELINE_KEY = \"deck_607\"",
                "CHALLENGER_KEYS = (\"deck_614\", \"deck_615\")",
                "ready_for_real_deck_change",
                "keep_protected_baseline",
            ],
        )
    )
    checks.append(
        check_contains(
            README,
            [
                "COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md",
                "deckbuilding_contract_surface_audit.py",
                "lorehold_artifact_contract_audit.py",
                "lorehold_promotion_gate_decision_audit.py",
                "global_commander_deck_contract_audit.py",
                "global_commander_strategy_matrix.py",
                "global_commander_deck_contract_audit_20260701_post_scope_legalities.md",
                "global_commander_strategy_matrix_20260701_current.md",
                "global_commander_deck_contract_audit_20260705_global_core_pivot_hermes_only.md",
                "global_commander_strategy_matrix_20260705_global_core_pivot_hermes_only.md",
                "global_commander_core_repair_hypothesis.py",
                "global_commander_core_repair_hypothesis_20260705_global_goal_hermes_only.md",
                "global_commander_mana_base_profile.py",
                "global_commander_mana_base_profile_20260705_global_goal_hermes_only.md",
                "global_commander_named_land_candidate_pool.py",
                "global_commander_named_land_candidate_pool_20260705_global_goal_hermes_only.md",
                "global_commander_land_cut_candidate_model.py",
                "global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only.md",
                "global_commander_nonland_core_candidate_model.py",
                "global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only.md",
                "Angel/Demon/Dragon ficam bloqueadas",
                "global_commander_candidate_copy_materializer.py",
                "global_commander_candidate_copy_materializer_20260705_kaalia_nonland_top_pair.md",
                "fonte encadeada/stale",
                "Bloodthirster",
                "global_commander_candidate_battle_probe_audit.py",
                "global_commander_candidate_battle_probe_audit_20260705_kaalia_nonland_floor_dynamic_target.md",
                "candidato `33.3%` vs",
                "nenhuma das cinco remocoes adicionadas foi exercida",
            ],
        )
    )
    checks.append(
        {
            "path": rel(CONTRACT_MATRIX_JSON),
            "exists": CONTRACT_MATRIX_JSON.exists(),
            "status": "pass" if CONTRACT_MATRIX_JSON.exists() else "fail",
            "missing": [] if CONTRACT_MATRIX_JSON.exists() else ["matrix_json"],
        }
    )
    checks.append(
        {
            "path": rel(CONTRACT_MATRIX_MD),
            "exists": CONTRACT_MATRIX_MD.exists(),
            "status": "pass" if CONTRACT_MATRIX_MD.exists() else "fail",
            "missing": [] if CONTRACT_MATRIX_MD.exists() else ["matrix_md"],
        }
    )
    checks.append(
        {
            "path": rel(ARTIFACT_CONTRACT_REPORT),
            "exists": ARTIFACT_CONTRACT_REPORT.exists(),
            "status": "pass" if ARTIFACT_CONTRACT_REPORT.exists() else "fail",
            "missing": [] if ARTIFACT_CONTRACT_REPORT.exists() else ["artifact_contract_report"],
        }
    )
    checks.append(
        {
            "path": rel(PROMOTION_DECISION_REPORT),
            "exists": PROMOTION_DECISION_REPORT.exists(),
            "status": "pass" if PROMOTION_DECISION_REPORT.exists() else "fail",
            "missing": [] if PROMOTION_DECISION_REPORT.exists() else ["promotion_decision_report"],
        }
    )
    checks.append(
        check_contains(
            CUT_METHODOLOGY_REPORT,
            [
                "battle_cleared_with_cut_methodology_caveat",
                "The One Ring",
                "Molecule Man",
                "blocked_cross_lane_cut",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_AUDIT,
            [
                "postgres_is_product_truth",
                "lorehold_607_role",
                "registered_pg_variant",
                "test_or_fixture",
                "partner_or_multi_commander_requires_profile",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_MATRIX,
            [
                "global_commander_deck_contract_audit.py",
                "postgres_is_product_truth",
                "hermes_is_lab_cache",
                "ready_for_strategy_matrix",
                "structure_ready_source_missing",
                "local_runtime_reference_profiles",
                "local_runtime_profile_count",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CORE_ROLE_AUDIT,
            [
                "global_commander_core_role_audit",
                "CORE_ROLE_BANDS",
                "structured_tags_first_then_oracle_text_diagnostic_fallback",
                "benchmark_regression_only_not_global_template",
                "battle_or_optimization_performed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS,
            [
                "global_commander_core_repair_hypothesis",
                "mutation_allowed",
                "needs_mana_base_profile_before_named_cards",
                "needs_commander_win_plan_source_lane",
                "review_only_requires_commander_color_identity_and_fit",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_MANA_BASE_PROFILE,
            [
                "global_commander_mana_base_profile",
                "mutation_allowed",
                "mana_profile_ready_for_named_land_candidate_pool",
                "blocked_missing_commander_color_identity",
                "direct_or_fetch_access_by_color",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL,
            [
                "global_commander_named_land_candidate_pool",
                "review_only_named_land_candidate",
                "color_identity_allowed",
                "commander_legality",
                "current_deck_names",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL,
            [
                "global_commander_land_cut_candidate_model",
                "review_only_land_add_cut_pair",
                "carries_missing_core_role",
                "printed_deck_construction_exception_requires_source_lane",
                "potential_topdeck_engine_anchor_requires_commander_source_lane",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL,
            [
                "global_commander_nonland_core_candidate_model",
                "format_staples_expanded_role_pool",
                "review_only_nonland_add_cut_pair",
                "review_nonland_add_cut_pool_ready",
                "needs_commander_specific_source_lane",
                "kaalia_angel_demon_dragon_payoff_requires_source_lane",
                "commander_payoff_protection",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LEARNING_PRIORITY_AUDIT,
            [
                "global_commander_learning_priority_audit",
                "EXTERNAL_RESEARCH_SNAPSHOT",
                "land_add_cut_pool_ready_review_only",
                "nonland_add_cut_pool_ready_review_only",
                "global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only",
                "global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only",
                "current_official_bracket_model_has_five_brackets_and_game_changers",
                "benchmark_regression_only_not_global_template",
                "battle_or_optimization_performed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER,
            [
                "global_commander_candidate_copy_materializer",
                "candidate_materialized_structure_ready_next_gate_closed",
                "source_db_mutated",
                "source_unchanged",
                "validate_source_db_for_pair",
                "source_matches_pair_report",
                "protected_blocked_cut_cards",
                "protected blocked cut cards are absent",
                "--allow-chained-source",
                "promotion_allowed",
                "allow_battle_gate_now",
                "allow_next_strategy_matrix",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER_TEST,
            [
                "test_blocks_chained_source_db_by_default",
                "test_blocks_source_missing_protected_cut_candidate",
                "source_matches_pair_report",
                "Protected Payoff",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CANDIDATE_BATTLE_PROBE_AUDIT,
            [
                "global_commander_candidate_battle_probe_audit",
                "battle_probe_blocks_promotion",
                "candidate_underperformed_base_probe",
                "added_cards_not_exercised_in_replay_events",
                "stale_lorehold_mentions",
                "promotion_allowed",
                "larger_battle_gate_required",
            ],
        )
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_REPORT),
            "exists": GLOBAL_COMMANDER_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_REPORT.exists() else "fail",
            "missing": [] if GLOBAL_COMMANDER_REPORT.exists() else ["global_commander_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_MATRIX_REPORT),
            "exists": GLOBAL_COMMANDER_MATRIX_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_MATRIX_REPORT.exists() else "fail",
            "missing": [] if GLOBAL_COMMANDER_MATRIX_REPORT.exists() else ["global_commander_matrix_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_CORE_ROLE_REPORT),
            "exists": GLOBAL_COMMANDER_CORE_ROLE_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_CORE_ROLE_REPORT.exists() else "fail",
            "missing": [] if GLOBAL_COMMANDER_CORE_ROLE_REPORT.exists() else ["global_commander_core_role_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS_REPORT),
            "exists": GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS_REPORT.exists()
            else ["global_commander_core_repair_hypothesis_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_MANA_BASE_PROFILE_REPORT),
            "exists": GLOBAL_COMMANDER_MANA_BASE_PROFILE_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_MANA_BASE_PROFILE_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_MANA_BASE_PROFILE_REPORT.exists()
            else ["global_commander_mana_base_profile_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL_REPORT),
            "exists": GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL_REPORT.exists()
            else ["global_commander_named_land_candidate_pool_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL_REPORT),
            "exists": GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL_REPORT.exists()
            else ["global_commander_land_cut_candidate_model_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL_REPORT),
            "exists": GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL_REPORT.exists()
            else ["global_commander_nonland_core_candidate_model_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_LEARNING_PRIORITY_REPORT),
            "exists": GLOBAL_COMMANDER_LEARNING_PRIORITY_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_LEARNING_PRIORITY_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_LEARNING_PRIORITY_REPORT.exists()
            else ["global_commander_learning_priority_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER_REPORT),
            "exists": GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER_REPORT.exists()
            else ["global_commander_candidate_copy_materializer_report"],
        }
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CANDIDATE_BATTLE_PROBE_REPORT,
            [
                "battle_probe_blocks_promotion",
                "base_wr: `66.7`",
                "candidate_wr: `33.3`",
                "candidate_underperformed_base_probe",
                "added_cards_not_exercised_in_replay_events",
                "stale_lorehold_mentions: `0`",
            ],
        )
    )

    historical = []
    for path, marker in HISTORICAL_BLOCKED_SURFACES.items():
        text = read(path)
        historical.append(
            {
                "path": rel(path),
                "exists": path.exists(),
                "marker": marker,
                "status": "pass" if path.exists() and marker in text else "fail",
            }
        )

    failures = [check for check in checks if check["status"] != "pass"]
    failures.extend(row for row in historical if row["status"] != "pass")
    return {
        "generated_at": utc_now(),
        "status": "pass" if not failures else "fail",
        "contract": rel(CONTRACT_DOC),
        "active_surfaces": checks,
        "historical_blocked_surfaces": historical,
        "failures": failures,
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Deckbuilding Contract Surface Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Contract: `{payload['contract']}`",
        "",
        "## Active Surfaces",
        "",
        "| Status | Path | Missing |",
        "| --- | --- | --- |",
    ]
    for row in payload["active_surfaces"]:
        missing = ", ".join(row.get("missing") or [])
        lines.append(f"| {row['status']} | `{row['path']}` | {missing} |")
    lines.extend(["", "## Historical Blocked Surfaces", "", "| Status | Path | Marker |", "| --- | --- | --- |"])
    for row in payload["historical_blocked_surfaces"]:
        lines.append(f"| {row['status']} | `{row['path']}` | `{row['marker']}` |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "deckbuilding_contract_surface_audit_20260629",
    )
    args = parser.parse_args()
    payload = build_audit()
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
