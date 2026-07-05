#!/usr/bin/env python3
"""Map external Commander corpus evidence into cut-policy decisions.

This read-only gate consumes the external reference corpus collector and creates
an explicit policy handoff for the next miner pass. It prevents the same
usage-blocked or externally protected cards from being recycled as fresh
value-safe hypotheses without new negative trace, same-lane, or equal-gate
evidence.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_CORPUS_REPORT = (
    REPORT_DIR / "global_commander_external_reference_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_external_corpus_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1"
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


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def policy_for_row(row: Mapping[str, Any]) -> dict[str, Any]:
    card = str(row.get("cut_card") or "")
    corpus_status = str(row.get("corpus_status") or "")
    trace_group = str(row.get("trace_group") or "")
    support = str(row.get("source_support_level") or "")
    if corpus_status == "external_corpus_supports_preserve_or_strict_same_lane_proof":
        policy = "protect_from_rerun_miner_until_same_lane_or_equal_gate"
        reason = "External corpus presence plus target usage makes this a protected review card, not value-safe cut fodder."
        required_evidence = [
            "same_lane_replacement_proof",
            "strategy_matrix_recheck",
            "equal_gate_with_card_lane_exercised",
        ]
    elif corpus_status == "external_presence_requires_negative_trace_before_cut":
        policy = "hold_for_negative_trace_review_before_rerun_miner"
        reason = "External corpus presence and seen-without-usage trace require negative review before cut consideration."
        required_evidence = [
            "manual_negative_trace_review_or_force_access",
            "external_corpus_interpretation_for_current_bracket",
        ]
    elif trace_group == "seen_without_usage":
        policy = "hold_for_negative_or_force_access_review_before_rerun_miner"
        reason = "Seen-without-usage is not a negative trace; absence from checked corpus is not enough."
        required_evidence = ["manual_negative_trace_review_or_force_access"]
    elif trace_group == "usage_blocked":
        policy = "exclude_from_rerun_miner_until_new_internal_evidence"
        reason = "Target-deck usage blocks value-safe reclassification even when checked external corpus is absent."
        required_evidence = [
            "new_target_deck_negative_trace",
            "same_lane_replacement_proof",
            "equal_gate_with_cut_lane_exercised",
        ]
    else:
        policy = "hold_until_trace_status_is_known"
        reason = "External corpus cannot decide a cut before internal trace status is known."
        required_evidence = ["expand_replay_window_or_force_access"]
    return {
        "cut_card": card,
        "trace_group": trace_group,
        "source_support_level": support,
        "corpus_status": corpus_status,
        "cut_policy": policy,
        "policy_reason": reason,
        "cut_roles": as_list(row.get("cut_roles")),
        "rerun_miner_allowed_for_card": False,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "required_evidence": required_evidence,
    }


def build_report(*, corpus_report: Path) -> dict[str, Any]:
    corpus_payload = load_json(corpus_report)
    corpus_summary = corpus_payload.get("summary") or {}
    policy_rows = [
        policy_for_row(row)
        for row in corpus_payload.get("card_corpus_rows") or []
        if isinstance(row, Mapping) and row.get("cut_card")
    ]
    policy_counts: dict[str, int] = {}
    for row in policy_rows:
        policy = str(row["cut_policy"])
        policy_counts[policy] = policy_counts.get(policy, 0) + 1
    excluded = [
        row["cut_card"]
        for row in policy_rows
        if row["cut_policy"]
        in {
            "protect_from_rerun_miner_until_same_lane_or_equal_gate",
            "exclude_from_rerun_miner_until_new_internal_evidence",
        }
    ]
    held_for_review = [
        row["cut_card"]
        for row in policy_rows
        if row["cut_policy"]
        in {
            "hold_for_negative_trace_review_before_rerun_miner",
            "hold_for_negative_or_force_access_review_before_rerun_miner",
        }
    ]
    return {
        "generated_at": utc_now(),
        "status": "external_corpus_cut_policy_blocks_current_hypotheses",
        "artifact_type": "global_commander_external_corpus_cut_policy_mapper",
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
        "input_artifacts": {"corpus_report": rel(corpus_report)},
        "summary": {
            "deck_id": str(corpus_summary.get("deck_id") or ""),
            "commander": str(corpus_summary.get("commander") or ""),
            "policy_row_count": len(policy_rows),
            "excluded_from_rerun_miner_count": len(excluded),
            "held_for_negative_review_count": len(held_for_review),
            "rerun_miner_allowed_card_count": sum(1 for row in policy_rows if row["rerun_miner_allowed_for_card"]),
            "policy_counts": policy_counts,
            "next_gate": "rerun_value_safe_cut_source_miner_with_external_policy_exclusions",
        },
        "excluded_from_rerun_miner": excluded,
        "held_for_negative_review": held_for_review,
        "cut_policy_rows": policy_rows,
        "candidate_copy_blockers": [
            "all_current_external_corpus_hypotheses_blocked_or_held",
            "candidate_copy_closed_until_fresh_value_safe_cut_pair_exists",
            "miner_must_consume_policy_exclusions_before_reusing_current_hypotheses",
        ],
        "policy": {
            "rerun_boundary": "The next miner pass must not re-emit excluded cards as fresh hypotheses without new evidence.",
            "review_boundary": "Held cards need negative or force-access review before any cut consideration.",
            "mutation_boundary": "This mapper does not copy decks, mutate DBs, run battles, or promote a package.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Corpus Cut Policy Mapper",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- policy_row_count: `{summary['policy_row_count']}`",
        f"- excluded_from_rerun_miner_count: `{summary['excluded_from_rerun_miner_count']}`",
        f"- held_for_negative_review_count: `{summary['held_for_negative_review_count']}`",
        f"- rerun_miner_allowed_card_count: `{summary['rerun_miner_allowed_card_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Cut Policy Rows",
        "",
        "| Cut | Trace | Corpus Status | Cut Policy |",
        "| --- | --- | --- | --- |",
    ]
    for row in payload["cut_policy_rows"]:
        lines.append(
            "| `{cut}` | `{trace}` | `{status}` | `{policy}` |".format(
                cut=row.get("cut_card"),
                trace=row.get("trace_group"),
                status=row.get("corpus_status"),
                policy=row.get("cut_policy"),
            )
        )
    lines.extend(["", "## Excluded From Rerun Miner", ""])
    for card in payload["excluded_from_rerun_miner"]:
        lines.append(f"- `{card}`")
    lines.extend(["", "## Held For Negative Review", ""])
    for card in payload["held_for_negative_review"]:
        lines.append(f"- `{card}`")
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
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
