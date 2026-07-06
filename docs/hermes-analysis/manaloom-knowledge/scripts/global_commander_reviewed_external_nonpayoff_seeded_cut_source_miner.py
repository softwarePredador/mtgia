#!/usr/bin/env python3
"""Rerun same-lane cut-source mining with reviewed external nonpayoff seeds."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_same_lane_new_cut_source_miner as base_miner
from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_REVIEWER_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_same_lane_source_candidate_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1"
)


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


def count_by(rows: list[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get(field) or "unknown")] += 1
    return dict(counts)


def seed_rows(reviewer_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        dict(row)
        for row in reviewer_payload.get("miner_source_seed_rows") or []
        if isinstance(row, Mapping) and row.get("miner_source_seed_allowed")
    ]


def all_miner_rows(base_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for key in ("fresh_same_lane_cut_sources", "blocked_recycled_cut_sources", "blocked_new_cut_sources"):
        for row in base_payload.get(key) or []:
            if isinstance(row, Mapping):
                rows.append(dict(row))
    return rows


def role_rows(
    *,
    target_roles: list[str],
    seeds: list[Mapping[str, Any]],
    miner_rows: list[Mapping[str, Any]],
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for role in target_roles:
        role_seeds = [row for row in seeds if row.get("target_cut_role") == role]
        role_miner_rows = [row for row in miner_rows if row.get("target_cut_role") == role]
        fresh = [row for row in role_miner_rows if row.get("status") == "fresh_same_lane_cut_source_needs_trace"]
        recycled = [row for row in role_miner_rows if row.get("status") == "blocked_recycled_cut_source"]
        blocked = [row for row in role_miner_rows if row.get("status") == "blocked_new_cut_source"]
        if not role_seeds:
            status = "reviewed_external_seed_missing_for_target_role"
            next_evidence = "discover_and_review_more_external_nonpayoff_source_candidates"
        elif fresh:
            status = "reviewed_external_seeded_role_has_fresh_cut_source_needs_trace"
            next_evidence = "collect_trace_for_reviewed_external_seeded_cut_source_hypotheses"
        else:
            status = "reviewed_external_seeded_role_exhausted_current_deck_sources"
            next_evidence = "expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review"
        rows.append(
            {
                "target_cut_role": role,
                "status": status,
                "seed_count": len(role_seeds),
                "seed_cards": [str(row.get("card_name") or "") for row in role_seeds],
                "scanned_same_lane_source_count": len(role_miner_rows),
                "fresh_same_lane_cut_source_count": len(fresh),
                "blocked_recycled_cut_source_count": len(recycled),
                "blocked_new_cut_source_count": len(blocked),
                "next_evidence": next_evidence,
                "candidate_copy_allowed": False,
                "battle_gate_allowed": False,
                "value_safe_reclassification_allowed": False,
            }
        )
    return rows


def choose_status_and_next_gate(
    *,
    seed_count: int,
    fresh_seeded_count: int,
) -> tuple[str, str]:
    if not seed_count:
        return (
            "reviewed_external_seeded_cut_source_miner_blocks_no_reviewed_seeds",
            "review_external_nonpayoff_same_lane_source_candidates_locally_before_miner",
        )
    if fresh_seeded_count:
        return (
            "reviewed_external_seeded_cut_source_hypotheses_ready_for_trace",
            "collect_trace_for_reviewed_external_seeded_cut_source_hypotheses",
        )
    return (
        "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
        "expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review_before_candidate_copy",
    )


def build_report(
    *,
    reviewer_report: Path,
    recovery_report: Path,
    trace_collector_report: Path,
    cut_pair_report: Path,
    package_source_report: Path,
    sqlite_db: Path | None = None,
) -> dict[str, Any]:
    reviewer_payload = load_json(reviewer_report)
    seeds = seed_rows(reviewer_payload)
    seed_roles = sorted({str(row.get("target_cut_role") or "") for row in seeds if row.get("target_cut_role")})
    base_payload = base_miner.build_report(
        recovery_report=recovery_report,
        trace_collector_report=trace_collector_report,
        cut_pair_report=cut_pair_report,
        package_source_report=package_source_report,
        sqlite_db=sqlite_db,
    )
    miner_rows = all_miner_rows(base_payload)
    target_roles = list(base_payload.get("summary", {}).get("target_roles") or [])
    role_diagnostics = role_rows(target_roles=target_roles, seeds=seeds, miner_rows=miner_rows)
    seeded_miner_rows = [row for row in miner_rows if row.get("target_cut_role") in set(seed_roles)]
    fresh_seeded = [row for row in seeded_miner_rows if row.get("status") == "fresh_same_lane_cut_source_needs_trace"]
    recycled_seeded = [row for row in seeded_miner_rows if row.get("status") == "blocked_recycled_cut_source"]
    hard_blocked_seeded = [row for row in seeded_miner_rows if row.get("status") == "blocked_new_cut_source"]
    status, next_gate = choose_status_and_next_gate(
        seed_count=len(seeds),
        fresh_seeded_count=len(fresh_seeded),
    )
    unseeded_roles = sorted(set(target_roles) - set(seed_roles))
    blockers = [
        "reviewed_external_seeds_do_not_create_cut_permission",
        "candidate_copy_closed_until_seeded_fresh_cut_sources_have_trace",
        "battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist",
    ]
    if not fresh_seeded:
        blockers.append("reviewed_external_seeds_found_no_fresh_current_deck_cut_source")
    if unseeded_roles:
        blockers.append("unseeded_target_roles_remain_blocked:" + ",".join(unseeded_roles))
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner",
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
            "reviewer_report": rel(reviewer_report),
            "used_cut_recovery_report": rel(recovery_report),
            "trace_collector_report": rel(trace_collector_report),
            "cut_pair_report": rel(cut_pair_report),
            "package_source_report": rel(package_source_report),
            "selected_db": base_payload.get("input_artifacts", {}).get("selected_db"),
        },
        "base_miner_status": base_payload.get("status"),
        "base_miner_summary": base_payload.get("summary") or {},
        "summary": {
            "deck_id": str(base_payload.get("summary", {}).get("deck_id") or ""),
            "commander": str(base_payload.get("summary", {}).get("commander") or ""),
            "reviewed_seed_count": len(seeds),
            "seeded_role_count": len(seed_roles),
            "target_role_count": len(target_roles),
            "unseeded_target_role_count": len(unseeded_roles),
            "scanned_seeded_same_lane_source_count": len(seeded_miner_rows),
            "fresh_seeded_same_lane_cut_source_count": len(fresh_seeded),
            "blocked_recycled_seeded_cut_source_count": len(recycled_seeded),
            "blocked_new_seeded_cut_source_count": len(hard_blocked_seeded),
            "card_level_cut_permission_count": 0,
            "candidate_copy_allowed_count": 0,
            "seed_count_by_role": count_by(seeds, "target_cut_role"),
            "seeded_status_counts": count_by(seeded_miner_rows, "status"),
            "role_status_counts": count_by(role_diagnostics, "status"),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "miner_seed_rows": seeds,
        "role_diagnostics": role_diagnostics,
        "fresh_seeded_same_lane_cut_sources": fresh_seeded[:30],
        "blocked_recycled_seeded_cut_sources": recycled_seeded[:60],
        "blocked_new_seeded_cut_sources": hard_blocked_seeded[:60],
        "candidate_copy_blockers": blockers,
        "policy": {
            "seed_boundary": "Reviewed external nonpayoff cards are miner seeds only; they are not add approval or cut permission.",
            "cut_source_boundary": "A seeded role still needs a fresh same-lane current-deck cut source plus trace before candidate copy.",
            "recycling_boundary": "Current-deck sources already used, seen, stage-only, blocked, or traced remain unavailable.",
            "battle_boundary": "No battle gate opens before candidate copy and card-level usage evidence.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Reviewed External Nonpayoff Seeded Cut Source Miner",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- reviewed_seed_count: `{summary['reviewed_seed_count']}`",
        f"- seeded_role_count: `{summary['seeded_role_count']}`",
        f"- target_role_count: `{summary['target_role_count']}`",
        f"- unseeded_target_role_count: `{summary['unseeded_target_role_count']}`",
        f"- scanned_seeded_same_lane_source_count: `{summary['scanned_seeded_same_lane_source_count']}`",
        f"- fresh_seeded_same_lane_cut_source_count: `{summary['fresh_seeded_same_lane_cut_source_count']}`",
        f"- blocked_recycled_seeded_cut_source_count: `{summary['blocked_recycled_seeded_cut_source_count']}`",
        f"- blocked_new_seeded_cut_source_count: `{summary['blocked_new_seeded_cut_source_count']}`",
        f"- card_level_cut_permission_count: `{summary['card_level_cut_permission_count']}`",
        f"- candidate_copy_allowed_count: `{summary['candidate_copy_allowed_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Role Diagnostics",
        "",
        "| Role | Seeds | Scanned | Fresh | Recycled | Status |",
        "| --- | ---: | ---: | ---: | ---: | --- |",
    ]
    for row in payload["role_diagnostics"]:
        lines.append(
            "| `{role}` | {seeds} | {scanned} | {fresh} | {recycled} | `{status}` |".format(
                role=row.get("target_cut_role"),
                seeds=row.get("seed_count"),
                scanned=row.get("scanned_same_lane_source_count"),
                fresh=row.get("fresh_same_lane_cut_source_count"),
                recycled=row.get("blocked_recycled_cut_source_count"),
                status=row.get("status"),
            )
        )
    lines.extend(["", "## Miner Seeds", ""])
    for row in payload["miner_seed_rows"]:
        lines.append(f"- `{row.get('card_name')}` -> `{row.get('target_cut_role')}`")
    lines.extend(["", "## Fresh Seeded Same-Lane Cut Sources", ""])
    if payload["fresh_seeded_same_lane_cut_sources"]:
        for row in payload["fresh_seeded_same_lane_cut_sources"]:
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
    parser.add_argument("--reviewer-report", type=Path, default=DEFAULT_REVIEWER_REPORT)
    parser.add_argument("--used-cut-recovery-report", type=Path, default=base_miner.DEFAULT_RECOVERY_REPORT)
    parser.add_argument("--trace-collector-report", type=Path, default=base_miner.DEFAULT_TRACE_COLLECTOR_REPORT)
    parser.add_argument("--cut-pair-report", type=Path, default=base_miner.DEFAULT_CUT_PAIR_REPORT)
    parser.add_argument("--package-source-report", type=Path, default=base_miner.DEFAULT_PACKAGE_SOURCE_REPORT)
    parser.add_argument("--db", type=Path)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        reviewer_report=args.reviewer_report,
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
