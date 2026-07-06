#!/usr/bin/env python3
"""Rank the next safe global Commander deckbuilding learning actions."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT, rel
from global_commander_strategy_matrix import normalize_commander


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
COMMANDER_CONTRACT = REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"
DEFAULT_CORE_REPORT = REPORT_DIR / "global_commander_core_role_audit_20260705_global_goal_hermes_only.json"
DEFAULT_STRATEGY_REPORT = REPORT_DIR / "global_commander_strategy_matrix_20260701_current.json"
DEFAULT_LAND_CUT_REPORT = REPORT_DIR / "global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only.json"
DEFAULT_NONLAND_REPORT = REPORT_DIR / "global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only.json"
DEFAULT_BATTLE_FEEDBACK_REPORT = REPORT_DIR / "global_commander_battle_feedback_model_20260706_larger_gate_current.json"
DEFAULT_SOURCE_EXHAUSTION_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_followup_live_after_manual_trace.json"
)
DEFAULT_ENGINE_AXIS_PIVOT_REPORT = (
    REPORT_DIR / "global_commander_biotransference_protection_pivot_router_20260706_current.json"
)
DEFAULT_ROLE_AXIS_EXHAUSTION_REPORT = REPORT_DIR / "global_commander_ramp_axis_exhaustion_router_20260706_current.json"
BRACKET_POLICY_FILE = REPO_ROOT / "server/lib/edh_bracket_policy.dart"
SOURCE_EXPANSION_CYCLE_RECYCLED_CUT_SOURCE_THRESHOLD = 40

EXTERNAL_RESEARCH_SNAPSHOT = [
    {
        "source": "Wizards Commander format page",
        "url": "https://magic.wizards.com/en/formats/commander",
        "imported_principle": "current_official_bracket_model_has_five_brackets_and_game_changers",
        "guardrail": "bracket_and_game_changer_signals_set_power_intent_not_deck_quality",
    },
    {
        "source": "Official Commander rules",
        "url": "https://mtgcommander.net/index.php/rules/",
        "imported_principle": "exact_100_card_singleton_shape_with_card_text_exceptions",
        "guardrail": "legality_shape_is_required_before_strategy_or_battle",
    },
    {
        "source": "EDHREC Commander deckbuilding guide",
        "url": "https://edhrec.com/guides/how-to-build-a-commander-deck",
        "imported_principle": "commander_pages_top_cards_high_synergy_and_categories_are_reference_lanes",
        "guardrail": "public_popularity_is_evidence_not_automatic_truth",
    },
    {
        "source": "BinderBrew Commander template",
        "url": "https://binderbrew.com/commander-deck-building-template",
        "imported_principle": "lands_ramp_draw_interaction_wipes_are_flexible_starting_targets",
        "guardrail": "templates_are_starting_ranges_and_must_bend_to_commander_intent",
    },
    {
        "source": "Commander Spellbook",
        "url": "https://commanderspellbook.com/",
        "imported_principle": "combo_database_can_find_deterministic_finishers_and_variants",
        "guardrail": "combo_presence_does_not_prove_full_deck_balance_or_runtime_readiness",
    },
]

STAGE_RANK = {
    "structure_repair": 100,
    "role_data_backfill": 95,
    "core_floor_repair": 90,
    "role_extreme_review_then_source_lane": 75,
    "role_extreme_review": 70,
    "source_lane_build": 60,
    "commander_strategy_matrix_ready": 50,
    "benchmark_regression_review_only": 20,
    "no_action": 0,
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def load_optional_json(path: Path) -> dict[str, Any]:
    return load_json(path) if path.exists() else {}


def artifact_rel(path: Path) -> str:
    candidate = path if path.is_absolute() else REPO_ROOT / path
    try:
        return rel(candidate)
    except ValueError:
        return str(path)


def bracket_policy_status_from_text(text: str) -> dict[str, Any]:
    clamps_to_legacy_four = "clamp(1, 4)" in text
    supports_five = "case 5" in text or "clamp(1, 5)" in text
    has_game_changers = "gameChanger" in text and "officialGameChangerNamesForBracketPolicy" in text
    status = "aligned_with_current_official_bracket_model"
    if not supports_five or not has_game_changers:
        status = "needs_refresh_for_current_official_brackets"
    return {
        "path": rel(BRACKET_POLICY_FILE),
        "status": status,
        "current_official_bracket_model": "five_brackets_beta_plus_game_changers",
        "backend_supports_five_brackets": supports_five,
        "backend_has_game_changer_policy": has_game_changers,
        "backend_clamps_to_legacy_four_brackets": clamps_to_legacy_four,
        "next_gate": (
            "audit_and_upgrade_backend_bracket_policy_before_using_bracket_as_final_quality_gate"
            if status != "aligned_with_current_official_bracket_model"
            else "keep_bracket_policy_in_surface_audit"
        ),
    }


def bracket_policy_status(path: Path = BRACKET_POLICY_FILE) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    return bracket_policy_status_from_text(text)


def role_rows_by_status(core_row: dict[str, Any], status: str) -> list[dict[str, Any]]:
    return [row for row in core_row.get("role_bands", []) if row.get("status") == status]


def critical_gap_count(core_row: dict[str, Any]) -> int:
    return sum(
        1
        for row in role_rows_by_status(core_row, "below_floor")
        if row.get("severity") == "critical"
    )


def role_label(row: dict[str, Any]) -> str:
    return f"{row['role']}={row['count']} target {row['min']}-{row['max']}"


def stage_for_deck(core_row: dict[str, Any], commander_row: dict[str, Any] | None) -> str:
    deck_id = str(core_row.get("deck_id") or "")
    core_status = str(core_row.get("core_status") or "")
    shape_status = str(core_row.get("shape_status") or "")
    commander_status = str((commander_row or {}).get("status") or "")
    if shape_status != "structure_ready":
        return "structure_repair"
    if core_status == "role_data_incomplete":
        return "role_data_backfill"
    if core_status == "core_role_gap":
        return "core_floor_repair"
    if deck_id == "607":
        return "benchmark_regression_review_only"
    if core_status == "core_review_ready":
        if commander_status == "structure_ready_source_missing":
            return "role_extreme_review_then_source_lane"
        return "role_extreme_review"
    if commander_status == "structure_ready_source_missing":
        return "source_lane_build"
    if commander_status == "ready_for_strategy_matrix":
        return "commander_strategy_matrix_ready"
    return "no_action"


def next_action_for_stage(stage: str) -> str:
    return {
        "structure_repair": "repair_shape_legality_or_scope_before_deckbuilding_learning",
        "role_data_backfill": "backfill_functional_roles_or_verify_oracle_text_before_strategy_matrix",
        "core_floor_repair": "repair_core_role_floor_before_reference_or_strategy_matrix",
        "role_extreme_review_then_source_lane": "review_role_extremes_then_add_commander_profile_or_source_lane",
        "role_extreme_review": "write_commander_specific_role_targets_before_strategy_matrix",
        "source_lane_build": "add_reference_profile_public_corpus_or_learned_source_lane",
        "commander_strategy_matrix_ready": "run_commander_specific_strategy_matrix_before_battle_gate",
        "benchmark_regression_review_only": "keep_as_regression_benchmark_do_not_use_as_global_template",
    }.get(stage, "no_global_learning_action")


def land_cut_pools_by_deck(land_cut_payload: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(row.get("deck_id")): row
        for row in land_cut_payload.get("deck_cut_pools", [])
        if row.get("deck_id")
    }


def nonland_pools_by_deck(nonland_payload: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
    pools: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in nonland_payload.get("nonland_pools", []):
        deck_id = str(row.get("deck_id") or "")
        if deck_id:
            pools[deck_id].append(row)
    return pools


def source_exhaustion_summary_by_deck(source_exhaustion_payload: dict[str, Any]) -> dict[str, dict[str, Any]]:
    if not source_exhaustion_payload:
        return {}
    summary = source_exhaustion_payload.get("summary") or {}
    deck_id = str(summary.get("deck_id") or source_exhaustion_payload.get("deck_id") or "")
    if not deck_id:
        return {}
    candidate_copy_value = source_exhaustion_payload.get("candidate_copy_allowed_now")
    candidate_copy_allowed = bool(candidate_copy_value) if isinstance(candidate_copy_value, bool) else None
    next_gate = str(summary.get("next_gate") or "")
    prior_fresh = int(summary.get("prior_fresh_seeded_same_lane_cut_source_count") or 0)
    seeded_exhausted = int(summary.get("seeded_exhausted_role_count") or 0)
    target_role_count = int(summary.get("target_role_count") or 0)
    current_deck_review = int(summary.get("current_deck_negative_review_candidate_count") or 0)
    blocked_recycled = int(summary.get("prior_blocked_recycled_seeded_cut_source_count") or 0)
    all_seeded_roles_exhausted = bool(target_role_count and seeded_exhausted >= target_role_count)
    state = "not_applicable"
    if candidate_copy_allowed is False:
        if current_deck_review > 0:
            state = "current_deck_negative_review_required_before_candidate_copy"
        elif (
            prior_fresh == 0
            and all_seeded_roles_exhausted
            and blocked_recycled >= SOURCE_EXPANSION_CYCLE_RECYCLED_CUT_SOURCE_THRESHOLD
        ):
            state = "source_expansion_cycle_requires_global_learning_pivot"
        elif "source_candidate_pool" in next_gate or (prior_fresh == 0 and seeded_exhausted > 0):
            state = "source_expansion_required_before_candidate_copy"
        else:
            state = "source_exhaustion_unresolved_before_candidate_copy"
    elif candidate_copy_allowed is True:
        state = "source_exhaustion_cleared_for_candidate_copy"
    return {
        deck_id: {
            "artifact_type": source_exhaustion_payload.get("artifact_type"),
            "status": source_exhaustion_payload.get("status") or "unknown",
            "state": state,
            "commander": summary.get("commander") or source_exhaustion_payload.get("commander"),
            "candidate_copy_allowed_now": candidate_copy_allowed,
            "battle_gate_allowed_now": bool(source_exhaustion_payload.get("battle_gate_allowed_now")),
            "next_gate": next_gate or "none",
            "target_role_count": target_role_count,
            "seeded_exhausted_role_count": seeded_exhausted,
            "unseeded_role_count": int(summary.get("unseeded_role_count") or 0),
            "current_deck_negative_review_candidate_count": current_deck_review,
            "prior_fresh_seeded_same_lane_cut_source_count": prior_fresh,
            "prior_blocked_recycled_seeded_cut_source_count": blocked_recycled,
            "all_seeded_roles_exhausted": all_seeded_roles_exhausted,
            "source_expansion_cycle_threshold": SOURCE_EXPANSION_CYCLE_RECYCLED_CUT_SOURCE_THRESHOLD,
            "candidate_copy_blockers": list(source_exhaustion_payload.get("candidate_copy_blockers") or []),
        }
    }


def source_exhaustion_blocks_candidate_copy(source_exhaustion_summary: dict[str, Any] | None) -> bool:
    if not source_exhaustion_summary:
        return False
    state = source_exhaustion_summary.get("state") or source_exhaustion_summary.get("source_exhaustion_state")
    return str(state or "") in {
        "current_deck_negative_review_required_before_candidate_copy",
        "source_expansion_cycle_requires_global_learning_pivot",
        "source_expansion_required_before_candidate_copy",
        "source_exhaustion_unresolved_before_candidate_copy",
    }


def engine_axis_pivot_summary_by_deck(engine_axis_payload: dict[str, Any]) -> dict[str, dict[str, Any]]:
    if not engine_axis_payload:
        return {}
    summary = engine_axis_payload.get("summary") or {}
    deck_id = str(summary.get("deck_id") or "")
    if not deck_id:
        return {}
    raw_status = str(engine_axis_payload.get("status") or "unknown")
    state = "not_applicable"
    if raw_status == "biotransference_protected_engine_axis_exhausted_pivot_required":
        state = "engine_axis_exhausted_requires_global_learning_pivot"
    elif bool(engine_axis_payload.get("candidate_copy_allowed_now")):
        state = "engine_axis_cleared_for_candidate_copy"
    elif raw_status:
        state = "engine_axis_unresolved_before_candidate_copy"
    return {
        deck_id: {
            "artifact_type": engine_axis_payload.get("artifact_type"),
            "status": raw_status,
            "state": state,
            "commander": summary.get("commander"),
            "candidate_copy_allowed_now": bool(engine_axis_payload.get("candidate_copy_allowed_now")),
            "battle_gate_allowed_now": bool(engine_axis_payload.get("battle_gate_allowed_now")),
            "next_gate": summary.get("next_gate") or "none",
            "type_conversion_lane_exhausted": bool(summary.get("type_conversion_lane_exhausted")),
            "biotransference_protected": bool(summary.get("biotransference_protected")),
            "viable_non_biotransference_engine_cut_count": int(
                summary.get("viable_non_biotransference_engine_cut_count") or 0
            ),
            "blocker_counts": summary.get("blocker_counts") or {},
        }
    }


def engine_axis_pivot_blocks_candidate_copy(engine_axis_summary: dict[str, Any] | None) -> bool:
    if not engine_axis_summary:
        return False
    state = engine_axis_summary.get("state") or engine_axis_summary.get("engine_axis_pivot_state")
    return str(state or "") in {
        "engine_axis_exhausted_requires_global_learning_pivot",
        "engine_axis_unresolved_before_candidate_copy",
    }


def role_axis_exhaustion_summary_by_deck(role_axis_payload: dict[str, Any]) -> dict[str, dict[str, Any]]:
    if not role_axis_payload:
        return {}
    summary = role_axis_payload.get("summary") or {}
    deck_id = str(summary.get("deck_id") or role_axis_payload.get("deck_id") or "")
    if not deck_id:
        return {}
    raw_status = str(role_axis_payload.get("status") or "unknown")
    exhausted_axis = str(role_axis_payload.get("exhausted_role_axis") or "").strip()
    state = "not_applicable"
    if raw_status.endswith("_axis_exhausted_requires_global_role_axis_pivot") and exhausted_axis:
        state = "role_axis_exhausted_requires_global_learning_pivot"
    elif bool(role_axis_payload.get("candidate_copy_allowed_now")):
        state = "role_axis_exhaustion_cleared_for_candidate_copy"
    elif raw_status:
        state = "role_axis_exhaustion_unresolved_before_candidate_copy"
    return {
        deck_id: {
            "artifact_type": role_axis_payload.get("artifact_type"),
            "status": raw_status,
            "state": state,
            "commander": summary.get("commander") or role_axis_payload.get("commander"),
            "exhausted_role_axis": exhausted_axis,
            "candidate_copy_allowed_now": bool(role_axis_payload.get("candidate_copy_allowed_now")),
            "battle_gate_allowed_now": bool(role_axis_payload.get("battle_gate_allowed_now")),
            "next_gate": summary.get("next_gate") or "none",
            "blocked_axis_cut_count": int(summary.get("blocked_ramp_cut_count") or 0),
            "replacement_exact_ready_count": int(summary.get("replacement_exact_ready_count") or 0),
            "alternative_forced_usage_blocked_count": int(
                summary.get("alternative_forced_usage_blocked_count") or 0
            ),
            "candidate_copy_blockers": list(role_axis_payload.get("candidate_copy_blockers") or []),
        }
    }


def role_axis_exhaustion_blocks_candidate_copy(role_axis_summary: dict[str, Any] | None) -> bool:
    if not role_axis_summary:
        return False
    state = role_axis_summary.get("state") or role_axis_summary.get("role_axis_exhaustion_state")
    return str(state or "") in {
        "role_axis_exhausted_requires_global_learning_pivot",
        "role_axis_exhaustion_unresolved_before_candidate_copy",
    }


def preferred_nonland_pool(core_row: dict[str, Any], pools: list[dict[str, Any]]) -> dict[str, Any] | None:
    missing = {row.get("role") for row in role_rows_by_status(core_row, "below_floor")} - {"land"}
    if not missing:
        return None
    status_rank = {
        "review_nonland_add_cut_pool_ready": 3,
        "needs_commander_specific_source_lane": 2,
        "needs_candidate_or_cut_source_lane": 1,
    }
    matching = [row for row in pools if row.get("role") in missing]
    if not matching:
        return None
    return max(
        matching,
        key=lambda row: (
            status_rank.get(str(row.get("status") or ""), 0),
            int(row.get("candidate_count") or 0),
            int(row.get("cut_candidate_count") or 0),
        ),
    )


def repair_gate_state(
    core_row: dict[str, Any],
    land_cut_pool: dict[str, Any] | None,
    nonland_pool: dict[str, Any] | None = None,
) -> str:
    missing = {row.get("role") for row in role_rows_by_status(core_row, "below_floor")}
    missing_nonland = missing - {"land"}
    if "land" in missing:
        if land_cut_pool and land_cut_pool.get("status") == "review_cut_pool_ready":
            return "land_add_cut_pool_ready_review_only"
        return "needs_land_candidate_and_cut_model"
    if missing_nonland:
        if nonland_pool:
            status = str(nonland_pool.get("status") or "")
            if status == "review_nonland_add_cut_pool_ready":
                return "nonland_add_cut_pool_ready_review_only"
            if status == "needs_commander_specific_source_lane":
                return "needs_commander_specific_source_lane"
            if status == "needs_candidate_or_cut_source_lane":
                return "needs_candidate_or_cut_source_lane"
        return "needs_nonland_core_repair_hypothesis"
    if land_cut_pool and land_cut_pool.get("status") == "review_cut_pool_ready":
        return "land_cut_pool_available_for_review"
    return "not_applicable"


def next_action_for_deck(
    stage: str,
    core_row: dict[str, Any],
    land_cut_pool: dict[str, Any] | None,
    nonland_pool: dict[str, Any] | None = None,
    has_commander_source_lane: bool = False,
    source_exhaustion_summary: dict[str, Any] | None = None,
    engine_axis_pivot_summary: dict[str, Any] | None = None,
    role_axis_exhaustion_summary: dict[str, Any] | None = None,
) -> str:
    gate_state = repair_gate_state(core_row, land_cut_pool, nonland_pool)
    if stage == "core_floor_repair" and role_axis_exhaustion_blocks_candidate_copy(role_axis_exhaustion_summary):
        if str((role_axis_exhaustion_summary or {}).get("state")) == "role_axis_exhausted_requires_global_learning_pivot":
            axis = str((role_axis_exhaustion_summary or {}).get("exhausted_role_axis") or "role")
            return f"pivot_to_cross_commander_role_axis_learning_after_{axis}_axis_exhaustion"
        return "resolve_role_axis_exhaustion_before_candidate_copy"
    if stage == "core_floor_repair" and engine_axis_pivot_blocks_candidate_copy(engine_axis_pivot_summary):
        if str((engine_axis_pivot_summary or {}).get("state")) == "engine_axis_exhausted_requires_global_learning_pivot":
            return "pivot_to_cross_commander_role_axis_learning_after_engine_axis_exhaustion"
        return "resolve_engine_axis_pivot_before_candidate_copy"
    if stage == "core_floor_repair" and source_exhaustion_blocks_candidate_copy(source_exhaustion_summary):
        if str((source_exhaustion_summary or {}).get("state")) == "current_deck_negative_review_required_before_candidate_copy":
            return "collect_current_deck_negative_review_before_candidate_copy"
        if str((source_exhaustion_summary or {}).get("state")) == "source_expansion_cycle_requires_global_learning_pivot":
            return "pivot_to_cross_commander_role_axis_learning_before_more_same_deck_source_expansion"
        return "expand_external_nonpayoff_source_candidate_pool_before_candidate_copy"
    if stage == "core_floor_repair" and gate_state == "land_add_cut_pool_ready_review_only":
        if has_commander_source_lane:
            return "review_top_land_add_cut_pair_then_candidate_copy"
        return "review_top_land_add_cut_pair_then_candidate_copy_after_commander_source_lane"
    if stage == "core_floor_repair" and gate_state == "nonland_add_cut_pool_ready_review_only":
        if has_commander_source_lane:
            return "review_top_nonland_add_cut_pair_then_candidate_copy"
        return "review_top_nonland_add_cut_pair_then_candidate_copy_after_commander_source_lane"
    if stage == "core_floor_repair" and gate_state == "needs_commander_specific_source_lane":
        return "build_commander_specific_win_plan_source_lane_before_named_nonland_cards"
    if stage == "core_floor_repair" and gate_state == "needs_candidate_or_cut_source_lane":
        return "backfill_nonland_candidate_or_cut_source_lane_before_candidate_copy"
    return next_action_for_stage(stage)


def priority_score(core_row: dict[str, Any], stage: str) -> int:
    score = STAGE_RANK.get(stage, 0) + critical_gap_count(core_row) * 8
    if str(core_row.get("commander") or "") != "Lorehold, the Historian":
        score += 5
    else:
        score -= 10
    if str(core_row.get("deck_id")) == "607":
        score -= 20
    return score


def build_deck_priorities(
    core_payload: dict[str, Any],
    strategy_payload: dict[str, Any],
    land_cut_payload: dict[str, Any] | None = None,
    nonland_payload: dict[str, Any] | None = None,
    source_exhaustion_payload: dict[str, Any] | None = None,
    engine_axis_pivot_payload: dict[str, Any] | None = None,
    role_axis_exhaustion_payload: dict[str, Any] | None = None,
) -> list[dict[str, Any]]:
    commander_rows = {
        row["commander_key"]: row
        for row in strategy_payload.get("commanders", [])
        if row.get("commander_key")
    }
    cut_pools = land_cut_pools_by_deck(land_cut_payload or {})
    nonland_pools = nonland_pools_by_deck(nonland_payload or {})
    source_exhaustion_by_deck = source_exhaustion_summary_by_deck(source_exhaustion_payload or {})
    engine_axis_by_deck = engine_axis_pivot_summary_by_deck(engine_axis_pivot_payload or {})
    role_axis_exhaustion_by_deck = role_axis_exhaustion_summary_by_deck(role_axis_exhaustion_payload or {})
    priorities = []
    for core_row in core_payload.get("decks", []):
        commander_key = normalize_commander(str(core_row.get("commander") or ""))
        commander_row = commander_rows.get(commander_key)
        has_commander_source_lane = int((commander_row or {}).get("source_lane_count") or 0) > 0
        stage = stage_for_deck(core_row, commander_row)
        land_cut_pool = cut_pools.get(str(core_row.get("deck_id") or ""))
        nonland_pool = preferred_nonland_pool(
            core_row,
            nonland_pools.get(str(core_row.get("deck_id") or ""), []),
        )
        source_exhaustion_summary = source_exhaustion_by_deck.get(str(core_row.get("deck_id") or ""))
        engine_axis_pivot_summary = engine_axis_by_deck.get(str(core_row.get("deck_id") or ""))
        role_axis_exhaustion_summary = role_axis_exhaustion_by_deck.get(str(core_row.get("deck_id") or ""))
        gate_state = repair_gate_state(core_row, land_cut_pool, nonland_pool)
        below = role_rows_by_status(core_row, "below_floor")
        above = role_rows_by_status(core_row, "above_range_review")
        priorities.append(
            {
                "deck_id": str(core_row.get("deck_id") or ""),
                "deck_name": core_row.get("deck_name"),
                "commander": core_row.get("commander"),
                "scope": core_row.get("scope"),
                "stage": stage,
                "priority_score": priority_score(core_row, stage),
                "core_status": core_row.get("core_status"),
                "commander_source_status": (commander_row or {}).get("status"),
                "source_lane_count": int((commander_row or {}).get("source_lane_count") or 0),
                "critical_gap_count": critical_gap_count(core_row),
                "below_floor_roles": [role_label(row) for row in below],
                "above_range_roles": [role_label(row) for row in above],
                "repair_gate_state": gate_state,
                "land_cut_candidate_count": int((land_cut_pool or {}).get("cut_candidate_count") or 0),
                "land_pair_hypothesis_count": len((land_cut_pool or {}).get("pair_hypotheses") or []),
                "nonland_pool_role": (nonland_pool or {}).get("role"),
                "nonland_pool_status": (nonland_pool or {}).get("status"),
                "nonland_candidate_count": int((nonland_pool or {}).get("candidate_count") or 0),
                "nonland_cut_candidate_count": int((nonland_pool or {}).get("cut_candidate_count") or 0),
                "nonland_pair_hypothesis_count": len((nonland_pool or {}).get("pair_hypotheses") or []),
                "source_exhaustion_state": (source_exhaustion_summary or {}).get("state", "not_applicable"),
                "source_exhaustion_status": (source_exhaustion_summary or {}).get("status"),
                "source_exhaustion_next_gate": (source_exhaustion_summary or {}).get("next_gate"),
                "source_exhaustion_target_role_count": int(
                    (source_exhaustion_summary or {}).get("target_role_count") or 0
                ),
                "source_exhaustion_seeded_exhausted_role_count": int(
                    (source_exhaustion_summary or {}).get("seeded_exhausted_role_count") or 0
                ),
                "source_exhaustion_prior_fresh_cut_source_count": int(
                    (source_exhaustion_summary or {}).get("prior_fresh_seeded_same_lane_cut_source_count") or 0
                ),
                "source_exhaustion_prior_blocked_recycled_cut_source_count": int(
                    (source_exhaustion_summary or {}).get("prior_blocked_recycled_seeded_cut_source_count") or 0
                ),
                "source_exhaustion_all_seeded_roles_exhausted": bool(
                    (source_exhaustion_summary or {}).get("all_seeded_roles_exhausted")
                ),
                "source_expansion_cycle_threshold": int(
                    (source_exhaustion_summary or {}).get("source_expansion_cycle_threshold") or 0
                ),
                "candidate_copy_allowed_by_source_exhaustion": (
                    (source_exhaustion_summary or {}).get("candidate_copy_allowed_now")
                ),
                "source_exhaustion_blockers": (source_exhaustion_summary or {}).get("candidate_copy_blockers", []),
                "engine_axis_pivot_state": (engine_axis_pivot_summary or {}).get("state", "not_applicable"),
                "engine_axis_pivot_status": (engine_axis_pivot_summary or {}).get("status"),
                "engine_axis_pivot_next_gate": (engine_axis_pivot_summary or {}).get("next_gate"),
                "engine_axis_type_conversion_lane_exhausted": bool(
                    (engine_axis_pivot_summary or {}).get("type_conversion_lane_exhausted")
                ),
                "engine_axis_biotransference_protected": bool(
                    (engine_axis_pivot_summary or {}).get("biotransference_protected")
                ),
                "engine_axis_viable_non_biotransference_cut_count": int(
                    (engine_axis_pivot_summary or {}).get("viable_non_biotransference_engine_cut_count") or 0
                ),
                "engine_axis_blocker_counts": (engine_axis_pivot_summary or {}).get("blocker_counts", {}),
                "role_axis_exhaustion_state": (role_axis_exhaustion_summary or {}).get("state", "not_applicable"),
                "role_axis_exhaustion_status": (role_axis_exhaustion_summary or {}).get("status"),
                "role_axis_exhaustion_next_gate": (role_axis_exhaustion_summary or {}).get("next_gate"),
                "role_axis_exhausted_role": (role_axis_exhaustion_summary or {}).get("exhausted_role_axis"),
                "role_axis_blocked_cut_count": int(
                    (role_axis_exhaustion_summary or {}).get("blocked_axis_cut_count") or 0
                ),
                "role_axis_replacement_exact_ready_count": int(
                    (role_axis_exhaustion_summary or {}).get("replacement_exact_ready_count") or 0
                ),
                "role_axis_alternative_forced_usage_blocked_count": int(
                    (role_axis_exhaustion_summary or {}).get("alternative_forced_usage_blocked_count") or 0
                ),
                "role_axis_exhaustion_blockers": (role_axis_exhaustion_summary or {}).get(
                    "candidate_copy_blockers", []
                ),
                "next_action": next_action_for_deck(
                    stage,
                    core_row,
                    land_cut_pool,
                    nonland_pool,
                    has_commander_source_lane=has_commander_source_lane,
                    source_exhaustion_summary=source_exhaustion_summary,
                    engine_axis_pivot_summary=engine_axis_pivot_summary,
                    role_axis_exhaustion_summary=role_axis_exhaustion_summary,
                ),
            }
        )
    priorities.sort(
        key=lambda row: (
            -row["priority_score"],
            row["commander"] == "Lorehold, the Historian",
            row["deck_id"],
        )
    )
    return priorities


def build_commander_queue(deck_priorities: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_commander: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in deck_priorities:
        by_commander[str(row.get("commander") or "")].append(row)
    queue = []
    for commander, rows in by_commander.items():
        stage_counts = Counter(row["stage"] for row in rows)
        top = max(rows, key=lambda row: row["priority_score"])
        queue.append(
            {
                "commander": commander,
                "deck_count": len(rows),
                "top_stage": top["stage"],
                "top_priority_score": top["priority_score"],
                "stage_counts": dict(sorted(stage_counts.items())),
                "next_action": top["next_action"],
                "top_decks": [
                    {
                        "deck_id": row["deck_id"],
                        "stage": row["stage"],
                        "priority_score": row["priority_score"],
                        "below_floor_roles": row["below_floor_roles"],
                    }
                    for row in sorted(rows, key=lambda item: -item["priority_score"])[:5]
                ],
            }
        )
    queue.sort(
        key=lambda row: (
            -row["top_priority_score"],
            row["commander"] == "Lorehold, the Historian",
            row["commander"],
        )
    )
    return queue


def battle_feedback_summary(payload: dict[str, Any] | None) -> dict[str, Any]:
    if not payload:
        return {
            "status": "unavailable",
            "pair_count": 0,
            "blocked_pair_count": 0,
            "needs_exposure_pair_count": 0,
            "ready_pair_count": 0,
            "package_count": 0,
            "blocked_package_count": 0,
            "needs_exercise_package_count": 0,
            "pair_status_counts": {},
            "package_status_counts": {},
            "next_gate": "run_global_commander_battle_feedback_model_before_requeueing_tested_pairs",
        }
    summary = payload.get("summary") or {}
    pair_status_counts = summary.get("pair_status_counts") or {}
    package_status_counts = summary.get("package_status_counts") or {}
    blocked = int(summary.get("blocked_pair_count") or 0)
    needs_exposure = int(summary.get("needs_exposure_pair_count") or 0)
    blocked_packages = int(summary.get("blocked_package_count") or 0)
    needs_exercise_packages = int(summary.get("needs_exercise_package_count") or 0)
    next_gate = "exclude_blocked_pairs_packages_and_route_unexercised_evidence_before_requeue"
    if not blocked and not needs_exposure and not blocked_packages and not needs_exercise_packages:
        next_gate = "no_battle_feedback_blockers_currently_known"
    return {
        "status": payload.get("status") or "unknown",
        "pair_count": int(summary.get("pair_count") or 0),
        "blocked_pair_count": blocked,
        "needs_exposure_pair_count": needs_exposure,
        "ready_pair_count": int(summary.get("ready_pair_count") or 0),
        "package_count": int(summary.get("package_count") or 0),
        "blocked_package_count": blocked_packages,
        "needs_exercise_package_count": needs_exercise_packages,
        "pair_status_counts": pair_status_counts,
        "package_status_counts": package_status_counts,
        "next_gate": next_gate,
    }


def build_report(
    *,
    core_payload: dict[str, Any],
    strategy_payload: dict[str, Any],
    land_cut_payload: dict[str, Any] | None = None,
    nonland_payload: dict[str, Any] | None = None,
    battle_feedback_payload: dict[str, Any] | None = None,
    source_exhaustion_payload: dict[str, Any] | None = None,
    engine_axis_pivot_payload: dict[str, Any] | None = None,
    role_axis_exhaustion_payload: dict[str, Any] | None = None,
    bracket_status: dict[str, Any],
    core_report_path: Path,
    strategy_report_path: Path,
    land_cut_report_path: Path | None = None,
    nonland_report_path: Path | None = None,
    battle_feedback_report_path: Path | None = None,
    source_exhaustion_report_path: Path | None = None,
    engine_axis_pivot_report_path: Path | None = None,
    role_axis_exhaustion_report_path: Path | None = None,
) -> dict[str, Any]:
    land_cut_payload = land_cut_payload or {}
    nonland_payload = nonland_payload or {}
    source_exhaustion_payload = source_exhaustion_payload or {}
    engine_axis_pivot_payload = engine_axis_pivot_payload or {}
    role_axis_exhaustion_payload = role_axis_exhaustion_payload or {}
    deck_priorities = build_deck_priorities(
        core_payload,
        strategy_payload,
        land_cut_payload,
        nonland_payload,
        source_exhaustion_payload,
        engine_axis_pivot_payload,
        role_axis_exhaustion_payload,
    )
    commander_queue = build_commander_queue(deck_priorities)
    stage_counts = Counter(row["stage"] for row in deck_priorities)
    repair_gate_counts = Counter(row["repair_gate_state"] for row in deck_priorities)
    source_exhaustion_gate_counts = Counter(row["source_exhaustion_state"] for row in deck_priorities)
    engine_axis_pivot_gate_counts = Counter(row["engine_axis_pivot_state"] for row in deck_priorities)
    role_axis_exhaustion_gate_counts = Counter(row["role_axis_exhaustion_state"] for row in deck_priorities)
    input_artifacts = {
        "core_role_report": artifact_rel(core_report_path),
        "strategy_matrix_report": artifact_rel(strategy_report_path),
    }
    if land_cut_report_path is not None:
        input_artifacts["land_cut_candidate_model"] = artifact_rel(land_cut_report_path)
    if nonland_report_path is not None:
        input_artifacts["nonland_core_candidate_model"] = artifact_rel(nonland_report_path)
    if battle_feedback_report_path is not None and battle_feedback_report_path.exists():
        input_artifacts["battle_feedback_model"] = artifact_rel(battle_feedback_report_path)
    if source_exhaustion_report_path is not None and source_exhaustion_report_path.exists():
        input_artifacts["source_exhaustion_router"] = artifact_rel(source_exhaustion_report_path)
    if engine_axis_pivot_report_path is not None and engine_axis_pivot_report_path.exists():
        input_artifacts["engine_axis_pivot_router"] = artifact_rel(engine_axis_pivot_report_path)
    if role_axis_exhaustion_report_path is not None and role_axis_exhaustion_report_path.exists():
        input_artifacts["role_axis_exhaustion_router"] = artifact_rel(role_axis_exhaustion_report_path)
    feedback_summary = battle_feedback_summary(battle_feedback_payload)
    return {
        "generated_at": utc_now(),
        "status": "pass",
        "artifact_type": "global_commander_learning_priority_audit",
        "contract": rel(COMMANDER_CONTRACT),
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "input_artifacts": input_artifacts,
        "method": {
            "postgres_is_product_truth": True,
            "hermes_is_lab_cache": True,
            "lorehold_607_role": "benchmark_regression_only_not_global_template",
            "external_research_snapshot_date": "2026-07-05",
            "priority_order": [
                "shape_and_legality",
                "role_data_and_core_floor",
                "land_candidate_pool_and_cut_model",
                "nonland_candidate_pool_and_cut_model",
                "source_exhaustion_router_before_candidate_copy",
                "source_expansion_cycle_detection_before_more_same_deck_research",
                "engine_axis_exhaustion_router_before_more_same_deck_engine_research",
                "role_axis_exhaustion_router_before_more_same_deck_axis_research",
                "role_extreme_review",
                "commander_profile_and_source_lanes",
                "commander_specific_strategy_matrix",
                "battle_gate_with_drawn_cast_used_trace",
                "battle_feedback_model_before_requeue",
            ],
        },
        "external_research_snapshot": EXTERNAL_RESEARCH_SNAPSHOT,
        "backend_contract_gaps": {"bracket_policy": bracket_status},
        "summary": {
            "deck_count": len(deck_priorities),
            "commander_count": len(commander_queue),
            "stage_counts": dict(sorted(stage_counts.items())),
            "repair_gate_counts": dict(sorted(repair_gate_counts.items())),
            "source_exhaustion_gate_counts": dict(sorted(source_exhaustion_gate_counts.items())),
            "engine_axis_pivot_gate_counts": dict(sorted(engine_axis_pivot_gate_counts.items())),
            "role_axis_exhaustion_gate_counts": dict(sorted(role_axis_exhaustion_gate_counts.items())),
            "top_next_action": commander_queue[0]["next_action"] if commander_queue else "none",
            "bracket_policy_status": bracket_status["status"],
            "battle_feedback_status": feedback_summary["status"],
            "blocked_exact_add_cut_pair_count": feedback_summary["blocked_pair_count"],
            "blocked_exact_package_count": feedback_summary["blocked_package_count"],
            "source_exhaustion_blocked_deck_count": sum(
                1 for row in deck_priorities if source_exhaustion_blocks_candidate_copy(row)
            ),
            "engine_axis_pivot_blocked_deck_count": sum(
                1 for row in deck_priorities if engine_axis_pivot_blocks_candidate_copy(row)
            ),
            "role_axis_exhaustion_blocked_deck_count": sum(
                1 for row in deck_priorities if role_axis_exhaustion_blocks_candidate_copy(row)
            ),
            "battle_feedback_pair_status_counts": feedback_summary["pair_status_counts"],
            "battle_feedback_package_status_counts": feedback_summary["package_status_counts"],
        },
        "battle_feedback_summary": feedback_summary,
        "commander_queue": commander_queue,
        "deck_priorities": deck_priorities,
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Global Commander Learning Priority Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Decks ranked: `{payload['summary']['deck_count']}`",
        f"- Commanders ranked: `{payload['summary']['commander_count']}`",
        f"- Battle or optimization performed: `{payload['battle_or_optimization_performed']}`",
        f"- Bracket policy status: `{payload['summary']['bracket_policy_status']}`",
        "",
        "## Stage Counts",
        "",
        "| Stage | Decks |",
        "| --- | ---: |",
    ]
    for stage, count in payload["summary"]["stage_counts"].items():
        lines.append(f"| `{stage}` | {count} |")

    lines.extend(["", "## Repair Gate Counts", "", "| Gate State | Decks |", "| --- | ---: |"])
    for state, count in payload["summary"]["repair_gate_counts"].items():
        lines.append(f"| `{state}` | {count} |")

    lines.extend(["", "## Source Exhaustion Gate Counts", "", "| Gate State | Decks |", "| --- | ---: |"])
    for state, count in payload["summary"]["source_exhaustion_gate_counts"].items():
        lines.append(f"| `{state}` | {count} |")

    lines.extend(["", "## Engine Axis Pivot Counts", "", "| Gate State | Decks |", "| --- | ---: |"])
    for state, count in payload["summary"]["engine_axis_pivot_gate_counts"].items():
        lines.append(f"| `{state}` | {count} |")

    lines.extend(["", "## Role Axis Exhaustion Counts", "", "| Gate State | Decks |", "| --- | ---: |"])
    for state, count in payload["summary"]["role_axis_exhaustion_gate_counts"].items():
        lines.append(f"| `{state}` | {count} |")

    lines.extend(["", "## Commander Queue", "", "| Commander | Top Stage | Decks | Next Action |", "| --- | --- | ---: | --- |"])
    for row in payload["commander_queue"]:
        lines.append(
            f"| `{str(row['commander']).replace('|', '/')}` | `{row['top_stage']}` | {row['deck_count']} | `{row['next_action']}` |"
        )

    lines.extend(
        [
            "",
            "## Top Deck Priorities",
            "",
            "| Score | Deck | Commander | Stage | Repair Gate | Source/Pivot/Axis Gates | Below Floor | Above Range | Next Action |",
            "| ---: | --- | --- | --- | --- | --- | --- | --- | --- |",
        ]
    )
    for row in payload["deck_priorities"][:20]:
        deck = f"{row['deck_name']} ({row['deck_id']})".replace("|", "/")
        commander = str(row.get("commander") or "").replace("|", "/")
        below = ", ".join(f"`{item}`" for item in row["below_floor_roles"]) or "-"
        above = ", ".join(f"`{item}`" for item in row["above_range_roles"]) or "-"
        lines.append(
            f"| {row['priority_score']} | `{deck}` | `{commander}` | `{row['stage']}` | `{row['repair_gate_state']}` | `{row['source_exhaustion_state']} / {row['engine_axis_pivot_state']} / {row['role_axis_exhaustion_state']}` | {below} | {above} | `{row['next_action']}` |"
        )

    bracket_policy = payload["backend_contract_gaps"]["bracket_policy"]
    battle_feedback = payload["battle_feedback_summary"]
    lines.extend(
        [
            "",
            "## Backend Contract Gaps",
            "",
            f"- Bracket policy: `{bracket_policy['status']}`.",
            f"- Next gate: `{bracket_policy['next_gate']}`.",
            "",
            "## Battle Feedback",
            "",
            f"- Status: `{battle_feedback['status']}`.",
            f"- Pair status counts: `{battle_feedback['pair_status_counts']}`.",
            f"- Package status counts: `{battle_feedback['package_status_counts']}`.",
            f"- Next gate: `{battle_feedback['next_gate']}`.",
            "",
            "## Method Notes",
            "",
            f"- Priority order: `{payload['method']['priority_order']}`.",
            "- This is a learning queue, not a deck mutation permit.",
            "- Exact add/cut pairs blocked by battle feedback must not be requeued as fresh hypotheses.",
            "- Source-exhaustion routers override candidate-copy routing until a fresh same-lane cut source or required negative review exists.",
            "- Engine-axis exhaustion after Biotransference protection routes back to global role-axis learning instead of forcing same-deck cuts.",
            "- Role-axis exhaustion routes back to global role-axis learning before repeating same-deck source search for that exhausted axis.",
            "- Repeated source expansion with all seeded roles exhausted and high recycled cut-source counts pivots to cross-commander role-axis learning before more same-deck research.",
            "- External sources calibrate priorities; PostgreSQL/backend remains product truth.",
            "- Deck 607 is ranked only as a regression benchmark and must not become the global objective function.",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--core-report", type=Path, default=DEFAULT_CORE_REPORT)
    parser.add_argument("--strategy-report", type=Path, default=DEFAULT_STRATEGY_REPORT)
    parser.add_argument("--land-cut-report", type=Path, default=DEFAULT_LAND_CUT_REPORT)
    parser.add_argument("--nonland-report", type=Path, default=DEFAULT_NONLAND_REPORT)
    parser.add_argument("--battle-feedback-report", type=Path, default=DEFAULT_BATTLE_FEEDBACK_REPORT)
    parser.add_argument("--source-exhaustion-report", type=Path, default=DEFAULT_SOURCE_EXHAUSTION_REPORT)
    parser.add_argument("--engine-axis-pivot-report", type=Path, default=DEFAULT_ENGINE_AXIS_PIVOT_REPORT)
    parser.add_argument("--role-axis-exhaustion-report", type=Path, default=DEFAULT_ROLE_AXIS_EXHAUSTION_REPORT)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "global_commander_learning_priority_audit_20260706_source_exhaustion_current",
    )
    args = parser.parse_args()
    payload = build_report(
        core_payload=load_json(args.core_report),
        strategy_payload=load_json(args.strategy_report),
        land_cut_payload=load_optional_json(args.land_cut_report),
        nonland_payload=load_optional_json(args.nonland_report),
        battle_feedback_payload=load_optional_json(args.battle_feedback_report),
        source_exhaustion_payload=load_optional_json(args.source_exhaustion_report),
        engine_axis_pivot_payload=load_optional_json(args.engine_axis_pivot_report),
        role_axis_exhaustion_payload=load_optional_json(args.role_axis_exhaustion_report),
        bracket_status=bracket_policy_status(),
        core_report_path=args.core_report,
        strategy_report_path=args.strategy_report,
        land_cut_report_path=args.land_cut_report,
        nonland_report_path=args.nonland_report,
        battle_feedback_report_path=args.battle_feedback_report,
        source_exhaustion_report_path=args.source_exhaustion_report,
        engine_axis_pivot_report_path=args.engine_axis_pivot_report,
        role_axis_exhaustion_report_path=args.role_axis_exhaustion_report,
    )
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "summary": payload["summary"],
            },
            ensure_ascii=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
