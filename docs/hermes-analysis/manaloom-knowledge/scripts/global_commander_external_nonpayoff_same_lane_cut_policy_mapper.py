#!/usr/bin/env python3
"""Map external nonpayoff same-lane corpus into source-discovery policy."""

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
DEFAULT_CORPUS_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_same_lane_cut_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_same_lane_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1"
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


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def policy_for_role(row: Mapping[str, Any]) -> dict[str, Any]:
    role = str(row.get("target_cut_role") or "")
    status = str(row.get("status") or "")
    fresh = as_int(row.get("fresh_source_count"))
    if fresh:
        policy = "block_source_discovery_until_fresh_trace_resolves"
        next_evidence = "collect_trace_for_new_same_lane_cut_source_hypotheses"
        reason = "Fresh same-lane sources must be traced before external corpus can drive source discovery."
    elif status == "external_nonpayoff_corpus_collected_for_exhausted_same_lane_role":
        policy = "require_external_nonpayoff_source_discovery_before_miner"
        next_evidence = "discover_external_nonpayoff_same_lane_source_candidates"
        reason = "The current deck is exhausted for this role; external corpus can guide source discovery but not cut permission."
    else:
        policy = "require_same_lane_source_lane_discovery_before_policy_use"
        next_evidence = "discover_same_lane_source_candidates_before_policy_mapping"
        reason = "The role lacks enough scanned same-lane source context for policy-driven miner reruns."
    return {
        "target_cut_role": role,
        "role_label": row.get("role_label") or role,
        "corpus_status": status,
        "cut_policy": policy,
        "policy_reason": reason,
        "next_evidence": next_evidence,
        "selected_add_count": as_int(row.get("selected_add_count")),
        "source_count": as_int(row.get("source_count")),
        "source_ids": as_list(row.get("source_ids")),
        "source_signal_requirements": as_list(row.get("source_signal_requirements")),
        "nonpayoff_requirement": str(row.get("nonpayoff_requirement") or ""),
        "rerun_miner_allowed_for_role": False,
        "card_level_cut_permission_now": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "value_safe_reclassification_allowed": False,
        "required_evidence": [
            "named_external_source_candidate_rows",
            "local_identity_and_legality_check",
            "target_deck_trace_or_negative_review_before_cut_consideration",
            "same_lane_value_safe_pair_before_candidate_copy",
        ],
    }


def count_by(rows: list[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get(field) or "unknown")] += 1
    return dict(counts)


def choose_status_and_next_gate(rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if any(row["cut_policy"] == "block_source_discovery_until_fresh_trace_resolves" for row in rows):
        return (
            "external_nonpayoff_same_lane_policy_blocks_fresh_sources_need_trace",
            "collect_trace_for_new_same_lane_cut_source_hypotheses",
        )
    if any(row["cut_policy"] == "require_external_nonpayoff_source_discovery_before_miner" for row in rows):
        return (
            "external_nonpayoff_same_lane_policy_ready_no_cut_permission",
            "discover_external_nonpayoff_same_lane_source_candidates_before_miner",
        )
    return (
        "external_nonpayoff_same_lane_policy_ready_no_cut_permission",
        "discover_same_lane_source_candidates_before_policy_mapping",
    )


def build_report(*, corpus_report: Path) -> dict[str, Any]:
    corpus_payload = load_json(corpus_report)
    corpus_summary = corpus_payload.get("summary") or {}
    policy_rows = [
        policy_for_role(row)
        for row in corpus_payload.get("role_corpus_rows") or []
        if isinstance(row, Mapping) and row.get("target_cut_role")
    ]
    status, next_gate = choose_status_and_next_gate(policy_rows)
    discovery_required = [
        row["target_cut_role"]
        for row in policy_rows
        if row["cut_policy"] == "require_external_nonpayoff_source_discovery_before_miner"
    ]
    blockers = [
        "external_policy_is_role_level_not_card_cut_permission",
        "named_source_candidates_required_before_miner_rerun",
        "candidate_copy_closed_until_value_safe_same_lane_pair_exists",
        "battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist",
    ]
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_nonpayoff_same_lane_cut_policy_mapper",
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
        "input_artifacts": {"corpus_report": rel(corpus_report)},
        "summary": {
            "deck_id": str(corpus_summary.get("deck_id") or ""),
            "commander": str(corpus_summary.get("commander") or ""),
            "role_policy_count": len(policy_rows),
            "source_discovery_required_role_count": len(discovery_required),
            "rerun_miner_allowed_role_count": sum(1 for row in policy_rows if row["rerun_miner_allowed_for_role"]),
            "card_level_cut_permission_count": sum(1 for row in policy_rows if row["card_level_cut_permission_now"]),
            "policy_counts": count_by(policy_rows, "cut_policy"),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "source_discovery_required_roles": discovery_required,
        "role_policy_rows": policy_rows,
        "candidate_copy_blockers": blockers,
        "policy": {
            "role_boundary": "This mapper creates role-level source-discovery policy, not card-level cut permission.",
            "source_boundary": "Named external source candidates must be collected and checked locally before any miner rerun.",
            "trace_boundary": "Target-deck trace and same-lane value-safe pairing remain required before candidate copy.",
            "mutation_boundary": "This mapper does not mutate DBs, copy decks, run battles, or promote anything.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff Same-Lane Cut Policy Mapper",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- role_policy_count: `{summary['role_policy_count']}`",
        f"- source_discovery_required_role_count: `{summary['source_discovery_required_role_count']}`",
        f"- rerun_miner_allowed_role_count: `{summary['rerun_miner_allowed_role_count']}`",
        f"- card_level_cut_permission_count: `{summary['card_level_cut_permission_count']}`",
        f"- card_level_cut_permission_now: `{str(payload['card_level_cut_permission_now']).lower()}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Role Policy Rows",
        "",
        "| Role | Sources | Cut Policy | Next Evidence |",
        "| --- | ---: | --- | --- |",
    ]
    for row in payload["role_policy_rows"]:
        lines.append(
            "| `{role}` | {sources} | `{policy}` | `{next}` |".format(
                role=row.get("target_cut_role"),
                sources=row.get("source_count"),
                policy=row.get("cut_policy"),
                next=row.get("next_evidence"),
            )
        )
    lines.extend(["", "## Source Discovery Required Roles", ""])
    for role in payload["source_discovery_required_roles"]:
        lines.append(f"- `{role}`")
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
    parser.add_argument("--corpus-report", type=Path, default=DEFAULT_CORPUS_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(corpus_report=args.corpus_report)
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
