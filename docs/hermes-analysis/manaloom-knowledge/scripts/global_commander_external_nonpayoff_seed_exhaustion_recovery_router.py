#!/usr/bin/env python3
"""Route recovery after reviewed external nonpayoff seeds exhaust.

This gate follows the current-DB rerun of
``global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner.py``.
It is a read-only routing step: it does not name a cut as value-safe, does not
copy a deck, does not run battle, and does not promote a package.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_SEEDED_MINER_CURRENT_DB_REPORT = (
    REPORT_DIR
    / "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1_current_db.json"
)
DEFAULT_SOURCE_CANDIDATE_REVIEWER_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_same_lane_source_candidate_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_FORCE_ACCESS_REPORT = (
    REPORT_DIR
    / "global_commander_reviewed_external_seeded_force_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1"
)

CURRENT_DECK_REVIEW = "external_source_candidate_local_review_current_deck_trace_required"
HELD_PACKAGE_REVIEW = "external_source_candidate_local_review_held_package_pair_required"
IDENTITY_REVIEW = "external_source_candidate_local_review_needs_identity_resolution"
READY_SEED_REVIEW = "external_source_candidate_local_review_ready_for_miner_seed"
CURRENT_DECK_REVIEW_STATUSES = {
    CURRENT_DECK_REVIEW,
    "new_external_source_local_review_blocks_current_deck",
    "expanded_source_candidate_local_review_blocks_current_deck",
}
HELD_PACKAGE_REVIEW_STATUSES = {
    HELD_PACKAGE_REVIEW,
    "new_external_source_local_review_blocks_held_package_add",
}
IDENTITY_REVIEW_STATUSES = {
    IDENTITY_REVIEW,
    "new_external_source_local_review_needs_identity_resolution",
    "expanded_source_candidate_local_review_needs_identity_resolution",
}
READY_SEED_REVIEW_STATUSES = {
    READY_SEED_REVIEW,
    "new_external_source_local_review_ready_for_seeded_miner",
    "expanded_source_candidate_local_review_ready_for_seeded_miner",
}
EXHAUSTED_ROLE = "reviewed_external_seeded_role_exhausted_current_deck_sources"
UNSEEDED_ROLE = "reviewed_external_seed_missing_for_target_role"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def count_by(rows: list[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get(field) or "unknown")] += 1
    return dict(counts)


def role_list(rows: list[Mapping[str, Any]]) -> list[str]:
    return sorted({str(row.get("target_cut_role") or "") for row in rows if row.get("target_cut_role")})


def names(rows: list[Mapping[str, Any]]) -> list[str]:
    result: list[str] = []
    for row in rows:
        name = str(row.get("card_name") or "").strip()
        if name and name not in result:
            result.append(name)
    return result


def rows_for_role(rows: list[Mapping[str, Any]], role: str) -> list[dict[str, Any]]:
    return [dict(row) for row in rows if str(row.get("target_cut_role") or "") == role]


def role_recovery_status(*, diagnostic: Mapping[str, Any], current_deck: list[Mapping[str, Any]], identity: list[Mapping[str, Any]]) -> tuple[str, str]:
    diagnostic_status = str(diagnostic.get("status") or "")
    if current_deck:
        return (
            "seed_exhaustion_role_needs_current_deck_negative_review",
            "collect_current_deck_negative_review_for_external_nonpayoff_candidates",
        )
    if identity:
        return (
            "seed_exhaustion_role_needs_identity_resolution",
            "resolve_external_nonpayoff_candidate_identity_before_more_seed_review",
        )
    if diagnostic_status == UNSEEDED_ROLE:
        return (
            "seed_exhaustion_role_needs_new_external_seed_discovery",
            "expand_external_nonpayoff_source_candidate_pool_for_unseeded_role",
        )
    return (
        "seed_exhaustion_role_needs_broader_external_seed_research",
        "expand_external_nonpayoff_source_candidate_pool_for_exhausted_role",
    )


def build_role_recovery_rows(
    *,
    role_diagnostics: list[Mapping[str, Any]],
    review_rows: list[Mapping[str, Any]],
    miner_seed_rows: list[Mapping[str, Any]],
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for diagnostic in role_diagnostics:
        role = str(diagnostic.get("target_cut_role") or "")
        role_reviews = rows_for_role(review_rows, role)
        current_deck = [row for row in role_reviews if row.get("review_status") in CURRENT_DECK_REVIEW_STATUSES]
        held_package = [row for row in role_reviews if row.get("review_status") in HELD_PACKAGE_REVIEW_STATUSES]
        identity = [row for row in role_reviews if row.get("review_status") in IDENTITY_REVIEW_STATUSES]
        ready_seed = [row for row in role_reviews if row.get("review_status") in READY_SEED_REVIEW_STATUSES]
        role_seeds = rows_for_role(miner_seed_rows, role)
        status, next_gate = role_recovery_status(
            diagnostic=diagnostic,
            current_deck=current_deck,
            identity=identity,
        )
        rows.append(
            {
                "target_cut_role": role,
                "status": status,
                "prior_role_status": diagnostic.get("status"),
                "prior_seed_count": diagnostic.get("seed_count") or 0,
                "prior_scanned_source_count": diagnostic.get("scanned_same_lane_source_count") or 0,
                "prior_fresh_source_count": diagnostic.get("fresh_same_lane_cut_source_count") or 0,
                "prior_recycled_source_count": diagnostic.get("blocked_recycled_cut_source_count") or 0,
                "reviewed_seed_cards": names(role_seeds),
                "ready_seed_candidate_count": len(ready_seed),
                "ready_seed_candidates": names(ready_seed),
                "current_deck_negative_review_candidate_count": len(current_deck),
                "current_deck_negative_review_candidates": names(current_deck),
                "held_package_pair_required_count": len(held_package),
                "held_package_pair_required_candidates": names(held_package),
                "identity_resolution_required_count": len(identity),
                "identity_resolution_required_candidates": names(identity),
                "required_evidence": [
                    "current_deck_negative_review_before_cut_consideration",
                    "expanded_external_nonpayoff_source_candidates_if_current_deck_review_does_not_open_cut_source",
                    "same_lane_value_safe_pair_before_candidate_copy",
                    "card_level_trace_or_equal_gate_before_promotion",
                ],
                "next_gate": next_gate,
                "card_level_cut_permission_now": False,
                "candidate_copy_allowed": False,
                "battle_gate_allowed": False,
                "value_safe_reclassification_allowed": False,
            }
        )
    return rows


def recovery_actions(
    *,
    current_deck_count: int,
    identity_count: int,
    exhausted_roles: list[str],
    unseeded_roles: list[str],
    held_package_count: int,
) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    if current_deck_count:
        actions.append(
            {
                "priority": "P0",
                "action": "collect_current_deck_negative_review_for_external_nonpayoff_candidates",
                "status": "required_now",
                "reason": "The strongest remaining external candidates are already in the current deck, so absence/popularity cannot prove they are cuts.",
                "candidate_count": current_deck_count,
                "candidate_copy_allowed": False,
            }
        )
    if exhausted_roles or unseeded_roles:
        actions.append(
            {
                "priority": "P1",
                "action": "expand_external_nonpayoff_source_candidate_pool",
                "status": "evidence_lane",
                "reason": "Reviewed seeds produced no fresh current-DB cut source; broaden source candidates without reusing exhausted cards.",
                "exhausted_roles": exhausted_roles,
                "unseeded_roles": unseeded_roles,
                "candidate_copy_allowed": False,
            }
        )
    if identity_count:
        actions.append(
            {
                "priority": "P2",
                "action": "resolve_external_nonpayoff_candidate_identity_before_seed_review",
                "status": "required_before_candidate_can_seed_miner",
                "reason": "Identity-missing source candidates cannot seed miner research.",
                "candidate_count": identity_count,
                "candidate_copy_allowed": False,
            }
        )
    if held_package_count:
        actions.append(
            {
                "priority": "P3",
                "action": "hold_package_adds_until_value_safe_same_lane_pair_exists",
                "status": "closed_no_deck_action",
                "reason": "Cards already selected as package adds still need value-safe same-lane cuts before materialization.",
                "candidate_count": held_package_count,
                "candidate_copy_allowed": False,
            }
        )
    actions.append(
        {
            "priority": "P4",
            "action": "keep_candidate_copy_battle_and_promotion_closed",
            "status": "closed_no_deck_action",
            "reason": "Seed exhaustion and external source review are not card-level cut permission.",
            "candidate_copy_allowed": False,
        }
    )
    return actions


def choose_status_and_next_gate(*, current_deck_count: int, identity_count: int, exhausted_roles: list[str], unseeded_roles: list[str]) -> tuple[str, str]:
    if current_deck_count:
        return (
            "external_nonpayoff_seed_exhaustion_recovery_routes_to_current_deck_negative_review",
            "collect_current_deck_negative_review_for_external_nonpayoff_candidates",
        )
    if identity_count:
        return (
            "external_nonpayoff_seed_exhaustion_recovery_needs_identity_resolution",
            "resolve_external_nonpayoff_candidate_identity_before_more_seed_review",
        )
    if exhausted_roles or unseeded_roles:
        return (
            "external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion",
            "expand_external_nonpayoff_source_candidate_pool",
        )
    return (
        "external_nonpayoff_seed_exhaustion_recovery_blocks_no_actionable_lane",
        "recheck_external_nonpayoff_seed_inputs",
    )


def build_report(
    *,
    seeded_miner_current_db_report: Path,
    source_candidate_reviewer_report: Path,
    force_access_report: Path,
) -> dict[str, Any]:
    miner_payload = load_json(seeded_miner_current_db_report)
    reviewer_payload = load_json(source_candidate_reviewer_report)
    force_payload = load_json(force_access_report)
    miner_summary = miner_payload.get("summary") or {}
    reviewer_summary = reviewer_payload.get("summary") or {}
    force_summary = force_payload.get("summary") or {}
    role_diagnostics = [
        dict(row)
        for row in miner_payload.get("role_diagnostics") or []
        if isinstance(row, Mapping) and row.get("target_cut_role")
    ]
    review_rows = [
        dict(row)
        for row in reviewer_payload.get("review_rows") or []
        if isinstance(row, Mapping) and row.get("target_cut_role")
    ]
    miner_seed_rows = [
        dict(row)
        for row in reviewer_payload.get("miner_source_seed_rows") or []
        if isinstance(row, Mapping) and row.get("target_cut_role")
    ]
    role_rows = build_role_recovery_rows(
        role_diagnostics=role_diagnostics,
        review_rows=review_rows,
        miner_seed_rows=miner_seed_rows,
    )
    exhausted_roles = [
        str(row.get("target_cut_role") or "")
        for row in role_diagnostics
        if row.get("status") == EXHAUSTED_ROLE
    ]
    unseeded_roles = [
        str(row.get("target_cut_role") or "")
        for row in role_diagnostics
        if row.get("status") == UNSEEDED_ROLE
    ]
    current_deck_rows = [row for row in review_rows if row.get("review_status") in CURRENT_DECK_REVIEW_STATUSES]
    held_package_rows = [row for row in review_rows if row.get("review_status") in HELD_PACKAGE_REVIEW_STATUSES]
    identity_rows = [row for row in review_rows if row.get("review_status") in IDENTITY_REVIEW_STATUSES]
    status, next_gate = choose_status_and_next_gate(
        current_deck_count=len(current_deck_rows),
        identity_count=len(identity_rows),
        exhausted_roles=exhausted_roles,
        unseeded_roles=unseeded_roles,
    )
    blockers = [
        "reviewed_external_seed_exhaustion_is_not_cut_permission",
        "candidate_copy_closed_until_current_deck_negative_review_or_fresh_cut_source_exists",
        "battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist",
    ]
    if current_deck_rows:
        blockers.append("current_deck_external_candidates_need_negative_review:" + ",".join(names(current_deck_rows)))
    if held_package_rows:
        blockers.append("held_package_external_candidates_need_value_safe_pairs:" + ",".join(names(held_package_rows)))
    if unseeded_roles:
        blockers.append("unseeded_roles_need_expanded_source_candidates:" + ",".join(unseeded_roles))
    if identity_rows:
        blockers.append("identity_resolution_required:" + ",".join(names(identity_rows)))
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_nonpayoff_seed_exhaustion_recovery_router",
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
        "card_level_cut_permission_now": False,
        "input_artifacts": {
            "seeded_miner_current_db_report": rel(seeded_miner_current_db_report),
            "source_candidate_reviewer_report": rel(source_candidate_reviewer_report),
            "force_access_report": rel(force_access_report),
        },
        "summary": {
            "deck_id": str(miner_summary.get("deck_id") or reviewer_summary.get("deck_id") or force_summary.get("deck_id") or ""),
            "commander": str(miner_summary.get("commander") or reviewer_summary.get("commander") or force_summary.get("commander") or ""),
            "target_role_count": len(role_rows),
            "seeded_exhausted_role_count": len(exhausted_roles),
            "unseeded_role_count": len(unseeded_roles),
            "current_deck_negative_review_candidate_count": len(current_deck_rows),
            "held_package_pair_required_count": len(held_package_rows),
            "identity_resolution_required_count": len(identity_rows),
            "prior_fresh_seeded_same_lane_cut_source_count": int(miner_summary.get("fresh_seeded_same_lane_cut_source_count") or 0),
            "prior_blocked_recycled_seeded_cut_source_count": int(miner_summary.get("blocked_recycled_seeded_cut_source_count") or 0),
            "force_access_selected_db_absent_count": int(force_summary.get("selected_db_absent_count") or 0),
            "role_status_counts": count_by(role_rows, "status"),
            "review_status_counts": count_by(review_rows, "review_status"),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "role_recovery_rows": role_rows,
        "current_deck_negative_review_rows": current_deck_rows,
        "held_package_pair_rows": held_package_rows,
        "identity_resolution_rows": identity_rows,
        "recovery_actions": recovery_actions(
            current_deck_count=len(current_deck_rows),
            identity_count=len(identity_rows),
            exhausted_roles=exhausted_roles,
            unseeded_roles=unseeded_roles,
            held_package_count=len(held_package_rows),
        ),
        "candidate_copy_blockers": blockers,
        "policy": {
            "seed_exhaustion_boundary": "Reviewed external seeds that exhaust the current DB do not create card-level cut permission.",
            "current_deck_boundary": "External candidates already in the current deck need target-deck negative review before any cut consideration.",
            "held_package_boundary": "External candidates already selected as adds remain held until value-safe same-lane pairs exist.",
            "promotion_boundary": "No candidate copy, battle gate, deck mutation, or promotion is opened by this router.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff Seed Exhaustion Recovery Router",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- target_role_count: `{summary['target_role_count']}`",
        f"- seeded_exhausted_role_count: `{summary['seeded_exhausted_role_count']}`",
        f"- unseeded_role_count: `{summary['unseeded_role_count']}`",
        f"- current_deck_negative_review_candidate_count: `{summary['current_deck_negative_review_candidate_count']}`",
        f"- held_package_pair_required_count: `{summary['held_package_pair_required_count']}`",
        f"- identity_resolution_required_count: `{summary['identity_resolution_required_count']}`",
        f"- prior_fresh_seeded_same_lane_cut_source_count: `{summary['prior_fresh_seeded_same_lane_cut_source_count']}`",
        f"- prior_blocked_recycled_seeded_cut_source_count: `{summary['prior_blocked_recycled_seeded_cut_source_count']}`",
        f"- force_access_selected_db_absent_count: `{summary['force_access_selected_db_absent_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Role Recovery",
        "",
        "| Role | Status | Seeds | Current Deck Review | Held Package | Identity | Next Gate |",
        "| --- | --- | ---: | ---: | ---: | ---: | --- |",
    ]
    for row in payload["role_recovery_rows"]:
        lines.append(
            "| `{role}` | `{status}` | {seeds} | {current} | {held} | {identity} | `{next}` |".format(
                role=row.get("target_cut_role"),
                status=row.get("status"),
                seeds=row.get("prior_seed_count"),
                current=row.get("current_deck_negative_review_candidate_count"),
                held=row.get("held_package_pair_required_count"),
                identity=row.get("identity_resolution_required_count"),
                next=row.get("next_gate"),
            )
        )
    lines.extend(["", "## Recovery Actions", ""])
    for row in payload["recovery_actions"]:
        lines.append(f"- `{row.get('priority')}` `{row.get('action')}`: {row.get('reason')}")
    lines.extend(["", "## Current Deck Negative Review Candidates", ""])
    if payload["current_deck_negative_review_rows"]:
        for row in payload["current_deck_negative_review_rows"]:
            lines.append(f"- `{row.get('card_name')}` -> `{row.get('target_cut_role')}`")
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
    parser.add_argument("--seeded-miner-current-db-report", type=Path, default=DEFAULT_SEEDED_MINER_CURRENT_DB_REPORT)
    parser.add_argument("--source-candidate-reviewer-report", type=Path, default=DEFAULT_SOURCE_CANDIDATE_REVIEWER_REPORT)
    parser.add_argument("--force-access-report", type=Path, default=DEFAULT_FORCE_ACCESS_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        seeded_miner_current_db_report=args.seeded_miner_current_db_report,
        source_candidate_reviewer_report=args.source_candidate_reviewer_report,
        force_access_report=args.force_access_report,
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
