#!/usr/bin/env python3
"""Scout usage and same-lane proof for ramp-axis cut pressure.

This read-only gate follows ``global_commander_ramp_axis_nonland_cut_policy_model``.
It searches existing local trace/proof artifacts for ramp cut-pressure cards
and checks whether each add/cut pair has an explicit same-lane replacement
route. It does not run battles, generate replays, copy decks, mutate databases,
or promote packages.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_engine_cut_usage_same_lane_proof_scout as base_scout
from global_commander_deck_contract_audit import REPO_ROOT, rel
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_RAMP_POLICY_REPORT = (
    REPORT_DIR / "global_commander_ramp_axis_nonland_cut_policy_model_20260706_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_ramp_cut_usage_same_lane_proof_scout_20260706_current"


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


def as_int(value: object) -> int:
    return base_scout.as_int(value)


def as_list(value: object) -> list[str]:
    return base_scout.as_list(value)


def cut_evidence_row(
    *,
    cut: Mapping[str, Any],
    structured_rows: list[dict[str, Any]],
    text_occurrences: list[Mapping[str, Any]],
) -> dict[str, Any]:
    card = str(cut.get("card_name") or "")
    group = base_scout.strongest_trace_group(structured_rows)
    text_usage_count = sum(
        1
        for row in text_occurrences
        if row.get("card_name") == card and row.get("classification") == "current_scope_text_usage_reference_candidate"
    )
    if group == "usage_blocked":
        status = "ramp_cut_usage_observed_blocks_candidate_copy"
        next_evidence = "find_different_cut_or_explicit_same_lane_replacement"
    elif group == "seen_without_usage":
        status = "ramp_cut_seen_without_usage_needs_negative_review"
        next_evidence = "manual_negative_trace_review_before_candidate_copy"
    elif text_usage_count:
        status = "ramp_cut_text_trace_candidate_needs_structured_review"
        next_evidence = "review_text_trace_candidate_before_candidate_copy"
    else:
        status = "ramp_cut_missing_current_scope_usage_trace"
        next_evidence = "generate_or_import_current_scope_usage_trace_for_ramp_cut"
    return {
        "card_name": card,
        "status": status,
        "trace_group": group,
        "roles": as_list(cut.get("roles")),
        "matching_excess_roles": as_list(cut.get("matching_excess_roles")),
        "policy_bucket": cut.get("policy_bucket"),
        "structured_evidence_count": len(structured_rows),
        "text_usage_candidate_count": text_usage_count,
        "same_lane_replacement_route_count": sum(
            len(row.get("same_lane_replacement_routes") or []) for row in structured_rows
        ),
        "structured_evidence_sample": structured_rows[:5],
        "next_required_evidence": next_evidence,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "promotion_allowed": False,
        "mutation_allowed": False,
    }


def pair_review_row(
    *,
    pair: Mapping[str, Any],
    cut: Mapping[str, Any],
    cut_evidence: Mapping[str, Any],
    pool_role: str,
) -> dict[str, Any]:
    same_lane_roles = base_scout.explicit_same_lane_roles(pair=pair, cut=cut, pool_role=pool_role)
    blockers: list[str] = []
    cut_status = str(cut_evidence.get("status") or "")
    if cut_status == "ramp_cut_usage_observed_blocks_candidate_copy":
        blockers.append("cut_card_used_by_target_trace")
    elif cut_status == "ramp_cut_seen_without_usage_needs_negative_review":
        blockers.append("cut_card_seen_without_usage_needs_negative_review")
    elif cut_status == "ramp_cut_missing_current_scope_usage_trace":
        blockers.append("cut_card_missing_current_scope_usage_trace")
    elif cut_status == "ramp_cut_text_trace_candidate_needs_structured_review":
        blockers.append("cut_card_text_trace_needs_structured_review")
    if not same_lane_roles:
        blockers.append("no_explicit_same_lane_replacement_route")
    status = (
        "ramp_cut_pair_ready_for_manual_candidate_copy_review"
        if not blockers
        else "ramp_cut_pair_blocks_candidate_copy"
    )
    return {
        "add": pair.get("add"),
        "cut": pair.get("cut"),
        "status": status,
        "cut_evidence_status": cut_status,
        "candidate_role": str(pair.get("role") or pool_role or ""),
        "cut_roles": as_list(cut.get("roles")),
        "explicit_same_lane_roles": same_lane_roles,
        "blockers": blockers,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "promotion_allowed": False,
        "mutation_allowed": False,
    }


def build_report(
    *,
    ramp_policy_report: Path,
    scan_roots: list[Path] | None = None,
    max_occurrences_per_file: int = 5,
) -> dict[str, Any]:
    ramp_payload = load_json(ramp_policy_report)
    roots = scan_roots or [REPORT_DIR]
    cut_rows: list[dict[str, Any]] = []
    pair_reviews: list[dict[str, Any]] = []
    all_text_occurrences: list[dict[str, Any]] = []
    pool_summaries: list[dict[str, Any]] = []

    for pool in base_scout.target_pool_rows(ramp_payload):
        deck_id = str(pool.get("deck_id") or "")
        commander = str(pool.get("commander") or "")
        cuts = base_scout.ready_cut_rows(pool)
        pairs = base_scout.pair_rows(pool)
        cut_names = [str(row.get("card_name") or "") for row in cuts]
        structured = base_scout.collect_structured_evidence(
            scan_roots=roots,
            deck_id=deck_id,
            commander=commander,
            cut_names=cut_names,
        )
        text_occurrences = base_scout.scan_text_occurrences(
            scan_roots=roots,
            cut_names=cut_names,
            deck_id=deck_id,
            commander=commander,
            max_occurrences_per_file=max(1, max_occurrences_per_file),
        )
        all_text_occurrences.extend(text_occurrences)
        cut_by_name = {normalize_name(str(row.get("card_name") or "")): row for row in cuts}
        evidence_by_name: dict[str, dict[str, Any]] = {}
        for cut in cuts:
            card = str(cut.get("card_name") or "")
            row = cut_evidence_row(
                cut=cut,
                structured_rows=structured.get(card, []),
                text_occurrences=text_occurrences,
            )
            evidence_by_name[normalize_name(card)] = row
            cut_rows.append({"deck_id": deck_id, "commander": commander, **row})
        for pair in pairs:
            cut_key = normalize_name(str(pair.get("cut") or ""))
            if cut_key not in cut_by_name:
                continue
            pair_reviews.append(
                pair_review_row(
                    pair=pair,
                    cut=cut_by_name[cut_key],
                    cut_evidence=evidence_by_name.get(cut_key, {}),
                    pool_role=str(pool.get("role") or ""),
                )
            )
        pool_summaries.append(
            {
                "deck_id": deck_id,
                "commander": commander,
                "role": pool.get("role"),
                "cut_count": len(cuts),
                "pair_count": len(pairs),
            }
        )

    status_counts = Counter(str(row.get("status") or "") for row in cut_rows)
    pair_status_counts = Counter(str(row.get("status") or "") for row in pair_reviews)
    pair_ready_count = sum(
        1 for row in pair_reviews if row.get("status") == "ramp_cut_pair_ready_for_manual_candidate_copy_review"
    )
    usage_blocked = [row["card_name"] for row in cut_rows if row["status"] == "ramp_cut_usage_observed_blocks_candidate_copy"]
    missing_trace = [row["card_name"] for row in cut_rows if row["status"] == "ramp_cut_missing_current_scope_usage_trace"]
    explicit_same_lane_route_count = sum(len(row.get("explicit_same_lane_roles") or []) for row in pair_reviews)
    if pair_ready_count:
        status = "ramp_cut_usage_same_lane_proof_ready_for_manual_review"
        next_gate = "manual_review_ramp_cut_pair_before_candidate_copy"
    else:
        status = "ramp_cut_usage_same_lane_proof_blocks_candidate_copy"
        next_gate = "generate_current_scope_trace_or_find_explicit_same_lane_ramp_replacement_before_candidate_copy"
    blockers = []
    if usage_blocked:
        blockers.append("usage_observed_blocks_ramp_cuts:" + ",".join(usage_blocked))
    if missing_trace:
        blockers.append("missing_current_scope_usage_trace_for_ramp_cuts:" + ",".join(missing_trace))
    if explicit_same_lane_route_count == 0 and pair_reviews:
        blockers.append("no_explicit_same_lane_replacement_route_for_ramp_cut_pairs")
    if not cut_rows:
        blockers.append("no_ramp_cut_pressure_rows_to_review")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_ramp_cut_usage_same_lane_proof_scout",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_run_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "ramp_policy_report": artifact_rel(ramp_policy_report),
            "scan_roots": [artifact_rel(root) for root in roots],
        },
        "summary": {
            "pool_count": len(pool_summaries),
            "cut_card_count": len(cut_rows),
            "pair_count": len(pair_reviews),
            "usage_blocked_cut_count": len(usage_blocked),
            "missing_trace_cut_count": len(missing_trace),
            "explicit_same_lane_route_count": explicit_same_lane_route_count,
            "pair_ready_count": pair_ready_count,
            "candidate_copy_blocker_count": len(blockers),
            "cut_status_counts": dict(sorted(status_counts.items())),
            "pair_status_counts": dict(sorted(pair_status_counts.items())),
            "text_occurrence_count": len(all_text_occurrences),
            "next_gate": next_gate,
        },
        "pool_summaries": pool_summaries,
        "cut_evidence_rows": cut_rows,
        "pair_review_rows": pair_reviews,
        "candidate_copy_blockers": blockers,
        "text_occurrence_sample": all_text_occurrences[:30],
        "policy": {
            "usage_boundary": "Observed use by the target deck blocks treating a ramp cut as safe.",
            "same_lane_boundary": "A removal add does not replace a ramp cut unless an explicit same-lane route is proven.",
            "trace_boundary": "Textual trace references are scout evidence only; structured trace/proof rows drive this decision.",
            "mutation_boundary": "This scout does not copy decks, run battles, mutate DBs, or promote packages.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Ramp Cut Usage Same-Lane Proof Scout",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- cut_card_count: `{summary['cut_card_count']}`",
        f"- pair_count: `{summary['pair_count']}`",
        f"- usage_blocked_cut_count: `{summary['usage_blocked_cut_count']}`",
        f"- missing_trace_cut_count: `{summary['missing_trace_cut_count']}`",
        f"- explicit_same_lane_route_count: `{summary['explicit_same_lane_route_count']}`",
        f"- pair_ready_count: `{summary['pair_ready_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_run_performed: `{str(payload['battle_run_performed']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Cut Evidence",
        "",
        "| Cut | Status | Trace Group | Structured Evidence | Same-Lane Routes | Next Evidence |",
        "| --- | --- | --- | ---: | ---: | --- |",
    ]
    for row in payload["cut_evidence_rows"]:
        lines.append(
            "| `{card}` | `{status}` | `{group}` | {structured} | {routes} | `{next}` |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                group=row.get("trace_group"),
                structured=row.get("structured_evidence_count"),
                routes=row.get("same_lane_replacement_route_count"),
                next=row.get("next_required_evidence"),
            )
        )
    if not payload["cut_evidence_rows"]:
        lines.append("| none |  |  |  |  |  |")
    lines.extend(["", "## Pair Review", ""])
    lines.extend(["| Pair | Status | Same-Lane Roles | Blockers |", "| --- | --- | --- | --- |"])
    for row in payload["pair_review_rows"]:
        lines.append(
            "| `+{add} / -{cut}` | `{status}` | `{roles}` | {blockers} |".format(
                add=row.get("add"),
                cut=row.get("cut"),
                status=row.get("status"),
                roles=",".join(row.get("explicit_same_lane_roles") or []) or "-",
                blockers=", ".join(row.get("blockers") or []) or "-",
            )
        )
    if not payload["pair_review_rows"]:
        lines.append("| none |  |  |  |")
    lines.extend(["", "## Blockers", ""])
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
            lines.append(f"- `{blocker}`")
    else:
        lines.append("- none")
    lines.extend(["", "## Text Occurrence Sample", ""])
    for row in payload["text_occurrence_sample"][:12]:
        lines.append(
            f"- `{row['card_name']}`: `{row['classification']}` in `{row['path']}` line `{row['line']}`"
        )
    if not payload["text_occurrence_sample"]:
        lines.append("- none")
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
    parser.add_argument("--ramp-policy-report", type=Path, default=DEFAULT_RAMP_POLICY_REPORT)
    parser.add_argument("--scan-root", action="append", type=Path)
    parser.add_argument("--max-occurrences-per-file", type=int, default=5)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    roots = args.scan_root if args.scan_root else [REPORT_DIR]
    payload = build_report(
        ramp_policy_report=args.ramp_policy_report,
        scan_roots=roots,
        max_occurrences_per_file=max(1, args.max_occurrences_per_file),
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
