#!/usr/bin/env python3
"""Mine fresh same-lane cut sources after used cuts block recovery.

This read-only gate consumes the same-lane used-cut recovery router, the
stage-cut trace collector, the same-lane cut-pair collector, and the same-lane
source package. It scans the current evaluation deck for target-role cuts that
were not already used, seen, stage-only, blocked, or otherwise consumed by the
current evidence chain. It does not copy a deck, run battle, mutate any DB,
reclassify cuts, or promote a package.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_candidate_package_strategy_matrix as strategy_matrix
import global_commander_cut_source_lane_expander as cut_expander
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_RECOVERY_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_used_cut_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_TRACE_COLLECTOR_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_stage_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_CUT_PAIR_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_cut_pair_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PACKAGE_SOURCE_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_same_lane_new_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1"
)

TARGET_RISK_BY_ROLE = {
    "haste_protection_silence": {"haste_or_protection_cut", "attack_window_or_extra_combat_cut"},
    "mana_acceleration": {"mana_acceleration_cut"},
    "tutors_access": {"tutor_access_cut"},
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def resolve_repo_path(value: object, fallback: Path) -> Path:
    text = str(value or "").strip()
    if not text:
        return fallback
    path = Path(text)
    return path if path.is_absolute() else REPO_ROOT / path


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def table_exists(conn: sqlite3.Connection, table_name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
        (table_name,),
    ).fetchone()
    return bool(row)


def resolve_working_db(
    *,
    cut_pair_payload: Mapping[str, Any],
    trace_payload: Mapping[str, Any],
    sqlite_db: Path | None,
) -> tuple[Path, dict[str, Any]]:
    if sqlite_db is not None:
        return sqlite_db, {
            "selected_db": rel(sqlite_db),
            "source": "cli_override",
            "selected_db_exists": sqlite_db.exists(),
        }
    cut_pair_inputs = cut_pair_payload.get("input_artifacts") or {}
    selected_db = resolve_repo_path(cut_pair_inputs.get("selected_db"), DEFAULT_SQLITE_DB)
    if selected_db.exists():
        return selected_db, {
            "selected_db": rel(selected_db),
            "source": "same_lane_cut_pair_report",
            "selected_db_exists": True,
        }
    trace_inputs = trace_payload.get("input_artifacts") or {}
    trace_db = resolve_repo_path(trace_inputs.get("selected_db"), DEFAULT_SQLITE_DB)
    if trace_db.exists():
        return trace_db, {
            "requested_db": rel(selected_db),
            "selected_db": rel(trace_db),
            "source": "stage_cut_trace_collector_report",
            "selected_db_exists": True,
        }
    return DEFAULT_SQLITE_DB, {
        "requested_db": rel(selected_db),
        "selected_db": rel(DEFAULT_SQLITE_DB),
        "source": "default_sqlite_fallback",
        "selected_db_exists": DEFAULT_SQLITE_DB.exists(),
    }


def resolve_strategy_report(cut_pair_payload: Mapping[str, Any]) -> Path:
    inputs = cut_pair_payload.get("input_artifacts") or {}
    return resolve_repo_path(
        inputs.get("strategy_matrix_report"),
        REPORT_DIR
        / "global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1_repair_scope1.json",
    )


def target_roles_from_inputs(
    *,
    recovery_payload: Mapping[str, Any],
    cut_pair_payload: Mapping[str, Any],
    package_payload: Mapping[str, Any],
) -> list[str]:
    roles: set[str] = set()
    recovery_summary = recovery_payload.get("summary") or {}
    for role in (recovery_summary.get("target_role_counts") or {}):
        if str(role or "").strip():
            roles.add(str(role))
    cut_pair_summary = cut_pair_payload.get("summary") or {}
    for role in (cut_pair_summary.get("required_pair_count_by_role") or {}):
        if str(role or "").strip():
            roles.add(str(role))
    for row in package_payload.get("selected_add_package") or []:
        if isinstance(row, Mapping) and row.get("replaces_cut_role"):
            roles.add(str(row["replaces_cut_role"]))
    return sorted(roles)


def selected_add_names(package_payload: Mapping[str, Any]) -> set[str]:
    names: set[str] = set()
    for row in package_payload.get("selected_add_package") or []:
        if not isinstance(row, Mapping):
            continue
        key = normalize_name(str(row.get("card_name") or ""))
        if key:
            names.add(key)
    return names


def add_exclusion(
    exclusions_by_card: dict[str, list[dict[str, Any]]],
    *,
    card_name: object,
    role: object,
    category: str,
    source_status: object,
    source_artifact: str,
    reasons: object = None,
) -> None:
    card = str(card_name or "").strip()
    card_key = normalize_name(card)
    if not card_key:
        return
    record = {
        "card_name": card,
        "target_cut_role": str(role or ""),
        "category": category,
        "source_status": str(source_status or ""),
        "source_artifact": source_artifact,
        "reasons": as_list(reasons),
    }
    records = exclusions_by_card.setdefault(card_key, [])
    key = (
        record["target_cut_role"],
        record["category"],
        record["source_status"],
        record["source_artifact"],
    )
    if key not in {
        (item["target_cut_role"], item["category"], item["source_status"], item["source_artifact"])
        for item in records
    }:
        records.append(record)


def collect_exclusions(
    *,
    recovery_payload: Mapping[str, Any],
    trace_payload: Mapping[str, Any],
    cut_pair_payload: Mapping[str, Any],
) -> dict[str, list[dict[str, Any]]]:
    exclusions: dict[str, list[dict[str, Any]]] = {}
    for row in trace_payload.get("review_rows") or []:
        if not isinstance(row, Mapping):
            continue
        status = str(row.get("status") or "")
        if status == "same_lane_stage_cut_usage_trace_blocks_value_safe":
            category = "used_stage_cut_source"
        elif status == "same_lane_stage_cut_seen_without_usage_needs_negative_review":
            category = "seen_stage_cut_source"
        elif status == "same_lane_stage_cut_external_reference_needs_internal_trace":
            category = "external_reference_stage_cut_source"
        else:
            category = "trace_missing_stage_cut_source"
        add_exclusion(
            exclusions,
            card_name=row.get("card_name"),
            role=row.get("target_cut_role"),
            category=category,
            source_status=status,
            source_artifact="stage_cut_trace_collector",
            reasons=row.get("stage_reasons"),
        )
    for row in recovery_payload.get("used_cut_recovery_rows") or []:
        if not isinstance(row, Mapping):
            continue
        add_exclusion(
            exclusions,
            card_name=row.get("cut_card"),
            role=row.get("target_cut_role"),
            category="used_cut_recovery_source",
            source_status=row.get("decision"),
            source_artifact="used_cut_recovery_router",
            reasons=row.get("stage_reasons"),
        )
    for source_key, category in (
        ("ready_cut_candidates", "prior_ready_cut_source"),
        ("stage_only_cut_candidates", "prior_stage_only_cut_source"),
        ("blocked_cut_candidates", "prior_blocked_cut_source"),
    ):
        for row in cut_pair_payload.get(source_key) or []:
            if not isinstance(row, Mapping):
                continue
            add_exclusion(
                exclusions,
                card_name=row.get("card_name"),
                role=row.get("target_cut_role"),
                category=category,
                source_status=row.get("status"),
                source_artifact="same_lane_cut_pair_collector",
                reasons=row.get("stage_reasons") or row.get("block_reasons"),
            )
    return exclusions


def exclusion_categories(exclusions: list[Mapping[str, Any]]) -> list[str]:
    values = {
        str(item.get("category") or "")
        for item in exclusions
        if str(item.get("category") or "").strip()
    }
    return sorted(values)


def score_fresh_source(
    *,
    row: Mapping[str, Any],
    target_role: str,
    profile_roles: set[str],
    staple_tier: str,
) -> tuple[int, list[str]]:
    score = 42
    reasons = [f"fresh_same_lane_{target_role}"]
    if len(profile_roles) == 1:
        score += 10
        reasons.append("single_profile_role_slot")
    cmc = float(row.get("cmc") or 0)
    if cmc >= 4:
        score += 6
        reasons.append("higher_curve_cut_pressure")
    if target_role == "mana_acceleration" and cmc >= 3:
        score += 6
        reasons.append("slower_ramp_review_pressure")
    if target_role == "tutors_access" and cmc >= 3:
        score += 5
        reasons.append("high_curve_tutor_review_pressure")
    if staple_tier == "contextual_staple_stage_only":
        score -= 6
        reasons.append("contextual_staple_needs_trace")
    elif staple_tier == "format_staple_reviewable":
        score -= 8
        reasons.append("format_staple_needs_review")
    return score, reasons


def hard_block_reasons(
    *,
    row: Mapping[str, Any],
    target_role: str,
    profile_roles: set[str],
    risk_flags: list[str],
    staple_tier: str,
    selected_names: set[str],
    expected_anchors: set[str],
) -> list[str]:
    card_name = str(row.get("card_name") or "")
    card_key = normalize_name(card_name)
    reasons: list[str] = []
    if int(row.get("is_commander") or 0):
        reasons.append("commander_card")
    if card_key in selected_names:
        reasons.append("same_card_selected_as_add")
    if "lands" in profile_roles:
        reasons.append("land_slot_not_cut_by_nonland_same_lane_recovery")
    if "angels_demons_dragons_payoffs" in profile_roles:
        reasons.append("commander_payoff_slot_protected")
    if card_key in expected_anchors:
        reasons.append("commander_expected_package_anchor_requires_stage_proof")
    if card_key in cut_expander.GLOBAL_FEEDBACK_STAGE_ONLY_CUTS:
        reasons.append("global_battle_feedback_requires_new_same_lane_or_gate")
    if staple_tier == "structural_foundation_anchor":
        reasons.append("structural_foundation_staple_requires_same_lane_or_battle_proof")
    protected_other_roles = sorted(
        role
        for role in (profile_roles & cut_expander.PROTECTED_PROFILE_ROLES)
        if role not in {target_role, "lands", "angels_demons_dragons_payoffs"}
    )
    if protected_other_roles:
        reasons.append("other_protected_profile_role_" + ",".join(protected_other_roles))
    non_target_risks = sorted(set(risk_flags) - TARGET_RISK_BY_ROLE.get(target_role, set()))
    if non_target_risks:
        reasons.append("cross_role_risk_not_new_clean_source:" + ",".join(non_target_risks))
    return reasons


def staple_for_card(
    *,
    card_name: str,
    staples: Mapping[str, Mapping[str, Any]],
) -> tuple[str, Mapping[str, Any] | None]:
    staple = staples.get(normalize_name(card_name))
    return cut_expander.staple_tier(staple), staple


def classify_deck_row_for_role(
    *,
    row: Mapping[str, Any],
    target_role: str,
    exclusions_by_card: Mapping[str, list[dict[str, Any]]],
    selected_names: set[str],
    staples: Mapping[str, Mapping[str, Any]],
    expected_anchors: set[str],
) -> dict[str, Any]:
    card_name = str(row.get("card_name") or "")
    card_key = normalize_name(card_name)
    profile_roles = strategy_matrix.profile_roles_for_card(row)
    risk_flags = strategy_matrix.cut_risk(row)
    staple_tier, staple = staple_for_card(card_name=card_name, staples=staples)
    score, reasons = score_fresh_source(
        row=row,
        target_role=target_role,
        profile_roles=profile_roles,
        staple_tier=staple_tier,
    )
    base = {
        "card_name": card_name,
        "target_cut_role": target_role,
        "score": score,
        "profile_roles": sorted(profile_roles),
        "risk_flags": risk_flags,
        "cmc": row.get("cmc"),
        "type_line": row.get("type_line") or "",
        "staple_tier": staple_tier,
        "format_staple": staple or {},
        "source_reasons": reasons,
        "mutation_allowed": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "value_safe_reclassification_allowed": False,
    }
    exhausted = list(exclusions_by_card.get(card_key) or [])
    if exhausted:
        return {
            **base,
            "status": "blocked_recycled_cut_source",
            "block_reasons": ["already_consumed_by_same_lane_evidence_chain"],
            "exclusion_categories": exclusion_categories(exhausted),
            "exclusion_sample": exhausted[:6],
            "next_evidence": "do_not_recycle_without_new_trace_or_external_policy_change",
        }
    block_reasons = hard_block_reasons(
        row=row,
        target_role=target_role,
        profile_roles=profile_roles,
        risk_flags=risk_flags,
        staple_tier=staple_tier,
        selected_names=selected_names,
        expected_anchors=expected_anchors,
    )
    if block_reasons:
        return {
            **base,
            "status": "blocked_new_cut_source",
            "block_reasons": block_reasons,
            "exclusion_categories": [],
            "exclusion_sample": [],
            "next_evidence": "broaden_axis_or_collect_external_nonpayoff_cut_lane",
        }
    return {
        **base,
        "status": "fresh_same_lane_cut_source_needs_trace",
        "block_reasons": [],
        "exclusion_categories": [],
        "exclusion_sample": [],
        "next_evidence": "collect_trace_for_new_same_lane_cut_source_hypothesis",
    }


def candidate_sort_key(row: Mapping[str, Any]) -> tuple[int, str, str]:
    status_rank = {
        "fresh_same_lane_cut_source_needs_trace": 0,
        "blocked_recycled_cut_source": 1,
        "blocked_new_cut_source": 2,
    }.get(str(row.get("status") or ""), 9)
    return (status_rank, -as_int(row.get("score")), str(row.get("card_name") or ""))


def classify_deck_sources(
    *,
    db_path: Path,
    deck_id: str,
    target_roles: list[str],
    exclusions_by_card: Mapping[str, list[dict[str, Any]]],
    selected_names: set[str],
    strategy_payload: Mapping[str, Any],
) -> list[dict[str, Any]]:
    if not db_path.exists():
        return []
    conn = sqlite3.connect(db_path)
    try:
        if not table_exists(conn, "deck_cards"):
            return []
        deck_rows = cut_expander.deck_rows(conn, deck_id)
        staples = cut_expander.format_staples_by_name(conn)
    finally:
        conn.close()
    expected_anchors = cut_expander.expected_package_anchor_names(strategy_payload)
    rows: list[dict[str, Any]] = []
    for deck_row in deck_rows:
        if int(deck_row.get("is_commander") or 0):
            continue
        profile_roles = strategy_matrix.profile_roles_for_card(deck_row)
        for target_role in target_roles:
            if target_role not in profile_roles:
                continue
            rows.append(
                classify_deck_row_for_role(
                    row=deck_row,
                    target_role=target_role,
                    exclusions_by_card=exclusions_by_card,
                    selected_names=selected_names,
                    staples=staples,
                    expected_anchors=expected_anchors,
                )
            )
    rows.sort(key=candidate_sort_key)
    return rows


def count_by(rows: list[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get(field) or "unknown")] += 1
    return dict(counts)


def count_exclusions_by_category(exclusions_by_card: Mapping[str, list[Mapping[str, Any]]]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for records in exclusions_by_card.values():
        categories = {str(record.get("category") or "unknown") for record in records}
        for category in categories:
            counts[category] += 1
    return dict(counts)


def choose_status_and_next_gate(
    *,
    target_roles: list[str],
    fresh_count: int,
) -> tuple[str, str]:
    if not target_roles:
        return (
            "same_lane_new_cut_source_mining_blocks_no_target_roles",
            "rebuild_same_lane_recovery_inputs_before_candidate_copy",
        )
    if fresh_count:
        return (
            "same_lane_new_cut_source_hypotheses_ready_for_trace",
            "collect_trace_for_new_same_lane_cut_source_hypotheses",
        )
    return (
        "same_lane_new_cut_source_mining_exhausted_current_deck",
        "broaden_same_lane_cut_research_or_package_axis_before_candidate_copy",
    )


def build_report(
    *,
    recovery_report: Path,
    trace_collector_report: Path,
    cut_pair_report: Path,
    package_source_report: Path,
    sqlite_db: Path | None = None,
) -> dict[str, Any]:
    recovery_payload = load_json(recovery_report)
    trace_payload = load_json(trace_collector_report)
    cut_pair_payload = load_json(cut_pair_report)
    package_payload = load_json(package_source_report)
    strategy_report = resolve_strategy_report(cut_pair_payload)
    strategy_payload = load_json(strategy_report) if strategy_report.exists() else {}
    db_path, db_resolution = resolve_working_db(
        cut_pair_payload=cut_pair_payload,
        trace_payload=trace_payload,
        sqlite_db=sqlite_db,
    )
    recovery_summary = recovery_payload.get("summary") or {}
    trace_summary = trace_payload.get("summary") or {}
    package_summary = package_payload.get("summary") or {}
    deck_id = str(
        recovery_summary.get("deck_id")
        or trace_summary.get("deck_id")
        or package_summary.get("deck_id")
        or ""
    )
    commander = str(
        recovery_summary.get("commander")
        or trace_summary.get("commander")
        or package_summary.get("commander")
        or ""
    )
    target_roles = target_roles_from_inputs(
        recovery_payload=recovery_payload,
        cut_pair_payload=cut_pair_payload,
        package_payload=package_payload,
    )
    exclusions_by_card = collect_exclusions(
        recovery_payload=recovery_payload,
        trace_payload=trace_payload,
        cut_pair_payload=cut_pair_payload,
    )
    rows = classify_deck_sources(
        db_path=db_path,
        deck_id=deck_id,
        target_roles=target_roles,
        exclusions_by_card=exclusions_by_card,
        selected_names=selected_add_names(package_payload),
        strategy_payload=strategy_payload,
    )
    fresh_rows = [row for row in rows if row["status"] == "fresh_same_lane_cut_source_needs_trace"]
    recycled_rows = [row for row in rows if row["status"] == "blocked_recycled_cut_source"]
    hard_blocked_rows = [row for row in rows if row["status"] == "blocked_new_cut_source"]
    status, next_gate = choose_status_and_next_gate(target_roles=target_roles, fresh_count=len(fresh_rows))
    blockers = [
        "candidate_copy_closed_until_fresh_same_lane_cut_sources_have_trace",
        "used_or_seen_stage_cuts_cannot_be_recycled_as_fresh_sources",
    ]
    if not fresh_rows:
        blockers.append("no_fresh_same_lane_cut_source_found_in_current_deck")
    if hard_blocked_rows:
        blockers.append(f"hard_blocked_new_same_lane_sources:{len(hard_blocked_rows)}")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_same_lane_new_cut_source_miner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "battle_replay_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "input_artifacts": {
            "used_cut_recovery_report": rel(recovery_report),
            "trace_collector_report": rel(trace_collector_report),
            "cut_pair_report": rel(cut_pair_report),
            "package_source_report": rel(package_source_report),
            "strategy_matrix_report": rel(strategy_report),
            "selected_db": rel(db_path),
        },
        "db_resolution": db_resolution,
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "target_roles": target_roles,
            "target_role_count": len(target_roles),
            "exhausted_source_card_count": len(exclusions_by_card),
            "exhausted_source_counts_by_category": count_exclusions_by_category(exclusions_by_card),
            "scanned_same_lane_source_count": len(rows),
            "fresh_same_lane_cut_source_count": len(fresh_rows),
            "blocked_recycled_cut_source_count": len(recycled_rows),
            "blocked_new_cut_source_count": len(hard_blocked_rows),
            "status_counts": count_by(rows, "status"),
            "fresh_count_by_role": count_by(fresh_rows, "target_cut_role"),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "fresh_same_lane_cut_sources": fresh_rows[:30],
        "blocked_recycled_cut_sources": recycled_rows[:60],
        "blocked_new_cut_sources": hard_blocked_rows[:60],
        "policy": {
            "freshness_boundary": "A card already used, seen, stage-only, blocked, or traced in the current evidence chain is not fresh.",
            "same_lane_boundary": "Only cards with a profile role matching the recovery target role are considered.",
            "hard_block_boundary": "Commanders, lands, payoff slots, expected anchors, structural staples, and cross-role-risk sources are not fresh clean cuts.",
            "candidate_copy_boundary": "This miner never opens candidate copy, battle, promotion, or value-safe reclassification.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Same-Lane New Cut Source Miner",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- target_role_count: `{summary['target_role_count']}`",
        f"- exhausted_source_card_count: `{summary['exhausted_source_card_count']}`",
        f"- scanned_same_lane_source_count: `{summary['scanned_same_lane_source_count']}`",
        f"- fresh_same_lane_cut_source_count: `{summary['fresh_same_lane_cut_source_count']}`",
        f"- blocked_recycled_cut_source_count: `{summary['blocked_recycled_cut_source_count']}`",
        f"- blocked_new_cut_source_count: `{summary['blocked_new_cut_source_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Fresh Same-Lane Cut Sources",
        "",
        "| Card | Role | Score | Next Evidence |",
        "| --- | --- | ---: | --- |",
    ]
    if payload["fresh_same_lane_cut_sources"]:
        for row in payload["fresh_same_lane_cut_sources"][:30]:
            lines.append(
                "| `{card}` | `{role}` | {score} | `{next}` |".format(
                    card=row.get("card_name"),
                    role=row.get("target_cut_role"),
                    score=row.get("score"),
                    next=row.get("next_evidence"),
                )
            )
    else:
        lines.append("| none | `-` | 0 | `broaden_same_lane_cut_research_or_package_axis_before_candidate_copy` |")
    lines.extend(
        [
            "",
            "## Blocked Recycled Cut Source Sample",
            "",
            "| Card | Role | Categories |",
            "| --- | --- | --- |",
        ]
    )
    for row in payload["blocked_recycled_cut_sources"][:20]:
        lines.append(
            "| `{card}` | `{role}` | `{categories}` |".format(
                card=row.get("card_name"),
                role=row.get("target_cut_role"),
                categories=", ".join(row.get("exclusion_categories") or []),
            )
        )
    if not payload["blocked_recycled_cut_sources"]:
        lines.append("| none | `-` | `-` |")
    lines.extend(["", "## Blocked New Cut Source Sample", ""])
    if payload["blocked_new_cut_sources"]:
        for row in payload["blocked_new_cut_sources"][:20]:
            lines.append(
                "- `{card}` ({role}): `{reasons}`".format(
                    card=row.get("card_name"),
                    role=row.get("target_cut_role"),
                    reasons=", ".join(row.get("block_reasons") or []),
                )
            )
    else:
        lines.append("- none")
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--used-cut-recovery-report", type=Path, default=DEFAULT_RECOVERY_REPORT)
    parser.add_argument("--trace-collector-report", type=Path, default=DEFAULT_TRACE_COLLECTOR_REPORT)
    parser.add_argument("--cut-pair-report", type=Path, default=DEFAULT_CUT_PAIR_REPORT)
    parser.add_argument("--package-source-report", type=Path, default=DEFAULT_PACKAGE_SOURCE_REPORT)
    parser.add_argument("--db", type=Path)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        recovery_report=args.used_cut_recovery_report,
        trace_collector_report=args.trace_collector_report,
        cut_pair_report=args.cut_pair_report,
        package_source_report=args.package_source_report,
        sqlite_db=args.db,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "summary": payload["summary"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
