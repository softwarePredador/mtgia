#!/usr/bin/env python3
"""Review engine cut trace/replacement evidence before candidate copy.

This read-only reviewer consumes
``global_commander_engine_cut_trace_replacement_gate`` output. It interprets
natural trace context and replacement candidate lanes, but does not approve a
deck copy, battle gate, mutation, or promotion.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT, rel
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_TRACE_REPLACEMENT_REPORT = (
    REPORT_DIR / "global_commander_engine_cut_trace_replacement_gate_20260706_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_engine_cut_trace_replacement_reviewer_20260706_current"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def artifact_rel(path: Path) -> str:
    candidate = path if path.is_absolute() else REPO_ROOT / path
    try:
        return rel(candidate)
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def resolve_report_path(value: object) -> Path:
    path = Path(str(value or ""))
    return path if path.is_absolute() else REPO_ROOT / path


def iter_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    if not path.exists():
        return rows
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def option_for_card(options: object, card_name: str) -> Mapping[str, Any] | None:
    wanted = normalize_name(card_name)
    if not isinstance(options, list):
        return None
    for option in options:
        if isinstance(option, Mapping) and normalize_name(str(option.get("card") or "")) == wanted:
            return option
    return None


def raw_decision_trace_for_card(report_payload: Mapping[str, Any], card_name: str) -> Mapping[str, Any] | None:
    wanted = normalize_name(card_name)
    best = None
    for seed in report_payload.get("seed_reports") or []:
        if not isinstance(seed, Mapping):
            continue
        decisions_path = resolve_report_path(seed.get("decisions_path"))
        for row in iter_jsonl(decisions_path):
            encoded = normalize_name(json.dumps(row, sort_keys=True, ensure_ascii=True, default=str))
            if wanted not in encoded:
                continue
            if option_for_card(row.get("rejected_options"), card_name):
                return row
            if best is None:
                best = row
    return best


def trace_review(row: Mapping[str, Any], *, raw_decision: Mapping[str, Any] | None = None) -> dict[str, Any]:
    card = str(row.get("card_name") or "")
    status = str(row.get("status") or "")
    decision = raw_decision or row.get("first_decision_trace")
    option = option_for_card((decision or {}).get("rejected_options") if isinstance(decision, Mapping) else [], card)
    chosen_score = (decision or {}).get("chosen_option_score") if isinstance(decision, Mapping) else None
    rejected_score = option.get("score") if isinstance(option, Mapping) else None
    score_gap = None
    try:
        if chosen_score is not None and rejected_score is not None:
            score_gap = float(chosen_score) - float(rejected_score)
    except (TypeError, ValueError):
        score_gap = None
    if status == "engine_cut_natural_trace_usage_observed_blocks_cut":
        review_status = "trace_review_blocks_cut_usage_observed"
        next_gate = "find_different_engine_cut_or_exact_same_lane_replacement"
        reason = "natural_trace_usage_observed"
    elif option and score_gap is not None and score_gap <= 0:
        review_status = "trace_review_blocks_negative_clearance_equal_score_tutor_candidate"
        next_gate = "find_different_engine_cut_or_exact_same_lane_replacement"
        reason = "card_was_equal_or_better_tutor_candidate"
    elif option:
        review_status = "trace_review_blocks_negative_clearance_tutor_candidate"
        next_gate = "collect_more_trace_or_find_replacement_before_candidate_copy"
        reason = "card_was_tutor_candidate"
    elif status == "engine_cut_natural_trace_seen_without_usage_needs_manual_negative_review":
        review_status = "trace_review_needs_more_negative_context"
        next_gate = "collect_more_trace_or_force_access_before_candidate_copy"
        reason = "seen_without_usage_but_no_clear_decision_context"
    else:
        review_status = "trace_review_needs_more_trace"
        next_gate = "run_forced_access_or_expand_trace_window"
        reason = "insufficient_trace_context"
    return {
        "card_name": card,
        "input_status": status,
        "review_status": review_status,
        "reason": reason,
        "usage_event_count": int(row.get("usage_event_count") or 0),
        "exposure_event_count": int(row.get("exposure_event_count") or 0),
        "decision_trace_count": int(row.get("decision_trace_count") or 0),
        "tutor_candidate_score": rejected_score,
        "chosen_tutor_score": chosen_score,
        "score_gap_vs_chosen": score_gap,
        "chosen_card": ((decision or {}).get("chosen_option") or {}).get("card") if isinstance(decision, Mapping) else None,
        "next_gate": next_gate,
        "negative_clearance_allowed": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "mutation_allowed": False,
    }


def exact_artifact_spell_engine(row: Mapping[str, Any]) -> bool:
    text = normalize_name(f"{row.get('type_line') or ''} {row.get('oracle_excerpt') or ''}")
    return (
        (
            "artifact spell" in text
            or "artifact spells" in text
            or "creatures you control are artifacts" in text
            or "creature spells you control" in text
        )
        and ("create" in text or "draw" in text or "treasure" in text)
    )


def replacement_review(report_payload: Mapping[str, Any]) -> dict[str, Any]:
    candidates = [
        dict(row)
        for row in report_payload.get("replacement_candidate_rows") or []
        if isinstance(row, Mapping)
    ]
    exact = [row for row in candidates if exact_artifact_spell_engine(row)]
    strong = [
        row
        for row in candidates
        if row.get("status") == "same_lane_engine_candidate_needs_source_trace_review" and row not in exact
    ]
    adjacent = [
        row
        for row in candidates
        if row.get("status") == "adjacent_engine_candidate_needs_explicit_same_lane_proof"
    ]
    if exact:
        status = "replacement_review_has_exact_artifact_engine_candidates_needs_trace"
        next_gate = "source_trace_exact_artifact_engine_candidates_before_candidate_copy"
    elif strong:
        status = "replacement_review_downgrades_to_adjacent_engine_candidates"
        next_gate = "find_exact_artifact_spell_engine_replacement_or_new_engine_cut_before_candidate_copy"
    elif adjacent:
        status = "replacement_review_only_adjacent_engine_candidates"
        next_gate = "find_exact_artifact_spell_engine_replacement_or_new_engine_cut_before_candidate_copy"
    else:
        status = "replacement_review_no_candidates"
        next_gate = "expand_external_engine_replacement_source_lanes"
    return {
        "status": status,
        "exact_artifact_engine_candidate_count": len(exact),
        "downgraded_strong_candidate_count": len(strong),
        "adjacent_candidate_count": len(adjacent),
        "exact_candidate_sample": exact[:5],
        "downgraded_candidate_sample": strong[:5],
        "adjacent_candidate_sample": adjacent[:5],
        "next_gate": next_gate,
        "explicit_same_lane_replacement_proof_count": len(exact),
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "mutation_allowed": False,
    }


def build_report(*, trace_replacement_report: Path) -> dict[str, Any]:
    payload = load_json(trace_replacement_report)
    trace_reviews = []
    for row in payload.get("trace_review_rows") or []:
        if not isinstance(row, Mapping):
            continue
        card = str(row.get("card_name") or "")
        trace_reviews.append(trace_review(row, raw_decision=raw_decision_trace_for_card(payload, card)))
    replacement = replacement_review(payload)
    blockers = []
    trace_blocked = [
        row["card_name"]
        for row in trace_reviews
        if row["review_status"].startswith("trace_review_blocks")
    ]
    if trace_blocked:
        blockers.append("trace_review_blocks_negative_clearance:" + ",".join(trace_blocked))
    if replacement["explicit_same_lane_replacement_proof_count"] == 0:
        blockers.append("no_exact_artifact_spell_engine_replacement_proof")
    blockers.append("candidate_copy_closed_after_trace_replacement_review")
    if trace_blocked and replacement["explicit_same_lane_replacement_proof_count"] == 0:
        status = "engine_cut_trace_replacement_review_blocks_candidate_copy"
        next_gate = "find_exact_artifact_spell_engine_replacement_or_new_engine_cut_before_candidate_copy"
    elif trace_blocked:
        status = "engine_cut_trace_replacement_review_needs_replacement_trace"
        next_gate = replacement["next_gate"]
    else:
        status = "engine_cut_trace_replacement_review_needs_more_trace"
        next_gate = "collect_more_trace_before_candidate_copy"
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_engine_cut_trace_replacement_reviewer",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "trace_replacement_report": artifact_rel(trace_replacement_report),
            "trace_replacement_status": payload.get("status"),
        },
        "summary": {
            "trace_review_count": len(trace_reviews),
            "trace_negative_clearance_allowed_count": sum(
                1 for row in trace_reviews if row.get("negative_clearance_allowed")
            ),
            "trace_blocked_count": len(trace_blocked),
            "exact_artifact_engine_candidate_count": replacement["exact_artifact_engine_candidate_count"],
            "downgraded_strong_candidate_count": replacement["downgraded_strong_candidate_count"],
            "adjacent_candidate_count": replacement["adjacent_candidate_count"],
            "explicit_same_lane_replacement_proof_count": replacement[
                "explicit_same_lane_replacement_proof_count"
            ],
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "trace_review_rows": trace_reviews,
        "replacement_review": replacement,
        "candidate_copy_blockers": blockers,
        "policy": {
            "negative_trace_boundary": "Rejected or considered tutor candidates do not clear a cut just because they were not cast.",
            "same_lane_boundary": "Artifact/treasure adjacency is not exact Biotransference replacement proof without artifact-spell or type-conversion engine overlap.",
            "mutation_boundary": "This reviewer reads report artifacts only and keeps candidate copy, battle, and promotion closed.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    replacement = payload["replacement_review"]
    lines = [
        "# Global Commander Engine Cut Trace Replacement Reviewer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- trace_review_count: `{summary['trace_review_count']}`",
        f"- trace_blocked_count: `{summary['trace_blocked_count']}`",
        f"- exact_artifact_engine_candidate_count: `{summary['exact_artifact_engine_candidate_count']}`",
        f"- downgraded_strong_candidate_count: `{summary['downgraded_strong_candidate_count']}`",
        f"- adjacent_candidate_count: `{summary['adjacent_candidate_count']}`",
        f"- explicit_same_lane_replacement_proof_count: `{summary['explicit_same_lane_replacement_proof_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Trace Review",
        "",
        "| Card | Status | Chosen | Candidate Score | Gap | Next Gate |",
        "| --- | --- | --- | ---: | ---: | --- |",
    ]
    for row in payload["trace_review_rows"]:
        lines.append(
            "| `{card}` | `{status}` | `{chosen}` | {score} | {gap} | `{next}` |".format(
                card=row.get("card_name"),
                status=row.get("review_status"),
                chosen=row.get("chosen_card"),
                score=row.get("tutor_candidate_score"),
                gap=row.get("score_gap_vs_chosen"),
                next=row.get("next_gate"),
            )
        )
    if not payload["trace_review_rows"]:
        lines.append("| none |  |  |  |  |  |")
    lines.extend(["", "## Replacement Review", ""])
    lines.append(f"- status: `{replacement['status']}`")
    lines.append(f"- exact_artifact_engine_candidate_count: `{replacement['exact_artifact_engine_candidate_count']}`")
    lines.append(f"- downgraded_strong_candidate_count: `{replacement['downgraded_strong_candidate_count']}`")
    lines.append(f"- adjacent_candidate_count: `{replacement['adjacent_candidate_count']}`")
    lines.append(f"- next_gate: `{replacement['next_gate']}`")
    lines.extend(["", "## Downgraded Strong Candidate Sample", ""])
    if replacement["downgraded_candidate_sample"]:
        for row in replacement["downgraded_candidate_sample"]:
            lines.append(f"- `{row['card_name']}`: `{','.join(row.get('role_signals') or [])}`")
    else:
        lines.append("- none")
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trace-replacement-report", type=Path, default=DEFAULT_TRACE_REPLACEMENT_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(trace_replacement_report=args.trace_replacement_report)
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
