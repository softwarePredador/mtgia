#!/usr/bin/env python3
"""Scout usage and same-lane proof for engine-axis cut pressure.

This read-only gate follows
``global_commander_engine_axis_nonland_cut_policy_model``. It searches existing
local trace/proof artifacts for the cut-pressure cards and checks whether each
add/cut pair has an explicit same-lane replacement route. It does not run
battles, generate replays, copy decks, mutate databases, or promote packages.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT, rel
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_ENGINE_POLICY_REPORT = (
    REPORT_DIR / "global_commander_engine_axis_nonland_cut_policy_model_20260706_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_engine_cut_usage_same_lane_proof_scout_20260706_current"

TEXT_SUFFIXES = {".json", ".jsonl", ".md", ".txt", ".out"}
TRACE_ARTIFACT_MARKERS = (
    "trace",
    "replay",
    "same_lane",
    "battle_probe",
    "force_access",
    "usage",
)
PLANNING_REFERENCE_MARKERS = (
    "deckbuilding_contract_surface_audit",
    "engine_axis_nonland_cut_policy_model",
    "engine_cut_usage_same_lane_proof_scout",
    "external_cut_source_research_plan",
    "value_safe_cut_source_miner",
)
USAGE_MARKERS = (
    "usage_event_count",
    "used_by_target",
    "cast_announced",
    "spell_cast",
    "spell_resolved",
    "card_drawn",
    "first_usage_event",
    "decision_trace_count",
)


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
    try:
        return int(value or 0)
    except Exception:
        return 0


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def target_pool_rows(engine_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in engine_payload.get("pool_policy_rows") or []:
        if isinstance(row, Mapping):
            rows.append(dict(row))
    return rows


def ready_cut_rows(pool: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in pool.get("policy_cut_rows") or []:
        if isinstance(row, Mapping) and row.get("cut_pressure_ready"):
            rows.append(dict(row))
    rows.sort(key=lambda row: str(row.get("card_name") or ""))
    return rows


def pair_rows(pool: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in pool.get("pair_rows") or []:
        if isinstance(row, Mapping) and row.get("add") and row.get("cut"):
            rows.append(dict(row))
    return rows


def scope_matches(summary: Mapping[str, Any], *, deck_id: str, commander: str) -> bool:
    summary_deck = str(summary.get("deck_id") or "")
    summary_commander = normalize_name(str(summary.get("commander") or ""))
    if summary_deck and summary_deck != str(deck_id):
        return False
    if commander and summary_commander and normalize_name(commander) != summary_commander:
        return False
    return bool(summary_deck or summary_commander)


def trace_group_from_row(row: Mapping[str, Any]) -> str:
    status = str(row.get("status") or row.get("trace_status") or "").lower()
    usage = as_int(row.get("usage_event_count"))
    exposure = as_int(row.get("exposure_event_count"))
    decisions = as_int(row.get("decision_trace_count"))
    if usage > 0 or "used_by_target" in status or "usage_observed" in status:
        return "usage_blocked"
    if exposure > 0 or decisions > 0 or "seen_without_usage" in status:
        return "seen_without_usage"
    return "not_seen_or_no_trace"


def card_name_from_trace_row(row: Mapping[str, Any]) -> str:
    for key in ("cut_card", "card_name", "card"):
        if row.get(key):
            return str(row[key])
    return ""


def trace_rows_from_payload(payload: Mapping[str, Any]) -> Iterable[Mapping[str, Any]]:
    for key in ("review_rows", "hypothesis_same_lane_rows", "contextual_evidence_rows"):
        for row in payload.get(key) or []:
            if isinstance(row, Mapping):
                yield row
    aggregate = payload.get("aggregate_card_trace") or {}
    if isinstance(aggregate, Mapping):
        for card, row in aggregate.items():
            if isinstance(row, Mapping):
                yield {"card_name": str(card), **dict(row)}


def same_lane_routes_from_row(row: Mapping[str, Any]) -> list[dict[str, Any]]:
    routes = row.get("same_lane_replacement_routes") or []
    if not isinstance(routes, list):
        return []
    return [dict(item) for item in routes if isinstance(item, Mapping)]


def collect_structured_evidence(
    *,
    scan_roots: list[Path],
    deck_id: str,
    commander: str,
    cut_names: list[str],
) -> dict[str, list[dict[str, Any]]]:
    wanted = {normalize_name(name): name for name in cut_names}
    evidence: dict[str, list[dict[str, Any]]] = {name: [] for name in cut_names}
    for root in scan_roots:
        if not root.exists():
            continue
        paths = [root] if root.is_file() else sorted(root.rglob("*.json"))
        for path in paths:
            if path.name.startswith("global_commander_engine_cut_usage_same_lane_proof_scout_"):
                continue
            try:
                payload = load_json(path)
            except Exception:
                continue
            summary = payload.get("summary") or {}
            if not isinstance(summary, Mapping) or not scope_matches(summary, deck_id=deck_id, commander=commander):
                continue
            artifact_type = str(payload.get("artifact_type") or path.stem)
            for row in trace_rows_from_payload(payload):
                card = card_name_from_trace_row(row)
                key = normalize_name(card)
                if key not in wanted:
                    continue
                evidence[wanted[key]].append(
                    {
                        "source_artifact": artifact_rel(path),
                        "artifact_type": artifact_type,
                        "trace_group": trace_group_from_row(row),
                        "status": row.get("status") or row.get("trace_status") or "",
                        "usage_event_count": as_int(row.get("usage_event_count")),
                        "exposure_event_count": as_int(row.get("exposure_event_count")),
                        "decision_trace_count": as_int(row.get("decision_trace_count")),
                        "first_usage_event": row.get("first_usage_event"),
                        "first_exposure_event": row.get("first_exposure_event"),
                        "first_decision_trace": row.get("first_decision_trace"),
                        "same_lane_replacement_routes": same_lane_routes_from_row(row),
                        "decision": row.get("decision") or "",
                    }
                )
    for rows in evidence.values():
        rows.sort(
            key=lambda row: (
                0 if row["trace_group"] == "usage_blocked" else 1,
                str(row.get("source_artifact") or ""),
            )
        )
    return evidence


def is_text_artifact(path: Path) -> bool:
    return path.is_file() and path.suffix.lower() in TEXT_SUFFIXES


def iter_text_artifacts(scan_roots: list[Path]) -> Iterable[Path]:
    for root in scan_roots:
        if not root.exists():
            continue
        if is_text_artifact(root):
            yield root
            continue
        for path in root.rglob("*"):
            if is_text_artifact(path):
                yield path


def path_scope_class(path: Path, *, deck_id: str, commander: str) -> str:
    text = artifact_rel(path).lower()
    commander_key = normalize_name(commander).replace(" ", "_")
    has_scope = f"deck{deck_id}" in text or str(deck_id) in text or "kaalia" in text or commander_key in text
    has_trace = any(marker in text for marker in TRACE_ARTIFACT_MARKERS)
    if any(marker in text for marker in PLANNING_REFERENCE_MARKERS):
        return "planning_reference_not_proof"
    if has_scope and has_trace:
        return "current_scope_trace_reference"
    if has_trace:
        return "historical_or_cross_scope_trace_reference_not_proof"
    if has_scope:
        return "current_scope_non_trace_reference_not_proof"
    return "cross_scope_reference_not_proof"


def line_has_usage_marker(line: str) -> bool:
    lower = line.lower()
    return any(marker in lower for marker in USAGE_MARKERS)


def scan_text_occurrences(
    *,
    scan_roots: list[Path],
    cut_names: list[str],
    deck_id: str,
    commander: str,
    max_occurrences_per_file: int,
) -> list[dict[str, Any]]:
    wanted = [(name, normalize_name(name)) for name in cut_names]
    occurrences: list[dict[str, Any]] = []
    for path in iter_text_artifacts(scan_roots):
        if path.name.startswith("global_commander_engine_cut_usage_same_lane_proof_scout_"):
            continue
        path_text = artifact_rel(path).lower()
        if not (
            any(marker in path_text for marker in TRACE_ARTIFACT_MARKERS)
            or any(normalize_name(name) in normalize_name(path.name) for name in cut_names)
            or "kaalia" in path_text
            or str(deck_id) in path_text
        ):
            continue
        per_file = 0
        try:
            with path.open("r", encoding="utf-8", errors="ignore") as handle:
                for line_no, line in enumerate(handle, start=1):
                    normalized_line = normalize_name(line)
                    for card, key in wanted:
                        if key and key in normalized_line:
                            classification = path_scope_class(path, deck_id=deck_id, commander=commander)
                            if classification == "current_scope_trace_reference" and line_has_usage_marker(line):
                                classification = "current_scope_text_usage_reference_candidate"
                            occurrences.append(
                                {
                                    "card_name": card,
                                    "path": artifact_rel(path),
                                    "line": line_no,
                                    "classification": classification,
                                    "excerpt": " ".join(line.strip().split())[:260],
                                }
                            )
                            per_file += 1
                            if per_file >= max_occurrences_per_file:
                                break
                    if per_file >= max_occurrences_per_file:
                        break
        except OSError:
            continue
    occurrences.sort(
        key=lambda row: (
            0 if row["classification"] == "current_scope_text_usage_reference_candidate" else 1,
            str(row.get("card_name") or ""),
            str(row.get("path") or ""),
            as_int(row.get("line")),
        )
    )
    return occurrences


def strongest_trace_group(rows: list[Mapping[str, Any]]) -> str:
    groups = [str(row.get("trace_group") or "") for row in rows]
    if "usage_blocked" in groups:
        return "usage_blocked"
    if "seen_without_usage" in groups:
        return "seen_without_usage"
    return "not_seen_or_no_trace"


def cut_evidence_row(
    *,
    cut: Mapping[str, Any],
    structured_rows: list[dict[str, Any]],
    text_occurrences: list[Mapping[str, Any]],
) -> dict[str, Any]:
    card = str(cut.get("card_name") or "")
    group = strongest_trace_group(structured_rows)
    text_usage_count = sum(
        1
        for row in text_occurrences
        if row.get("card_name") == card and row.get("classification") == "current_scope_text_usage_reference_candidate"
    )
    if group == "usage_blocked":
        status = "engine_cut_usage_observed_blocks_candidate_copy"
        next_evidence = "find_different_cut_or_explicit_same_lane_replacement"
    elif group == "seen_without_usage":
        status = "engine_cut_seen_without_usage_needs_negative_review"
        next_evidence = "manual_negative_trace_review_before_candidate_copy"
    elif text_usage_count:
        status = "engine_cut_text_trace_candidate_needs_structured_review"
        next_evidence = "review_text_trace_candidate_before_candidate_copy"
    else:
        status = "engine_cut_missing_current_scope_usage_trace"
        next_evidence = "generate_or_import_current_scope_usage_trace_for_engine_cut"
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


def explicit_same_lane_roles(*, pair: Mapping[str, Any], cut: Mapping[str, Any], pool_role: str) -> list[str]:
    cut_roles = set(as_list(cut.get("roles")))
    candidate_role = str(pair.get("role") or pool_role or "")
    roles = []
    if candidate_role and candidate_role in cut_roles:
        roles.append(candidate_role)
    return sorted(roles)


def pair_review_row(
    *,
    pair: Mapping[str, Any],
    cut: Mapping[str, Any],
    cut_evidence: Mapping[str, Any],
    pool_role: str,
) -> dict[str, Any]:
    same_lane_roles = explicit_same_lane_roles(pair=pair, cut=cut, pool_role=pool_role)
    blockers: list[str] = []
    cut_status = str(cut_evidence.get("status") or "")
    if cut_status == "engine_cut_usage_observed_blocks_candidate_copy":
        blockers.append("cut_card_used_by_target_trace")
    elif cut_status == "engine_cut_seen_without_usage_needs_negative_review":
        blockers.append("cut_card_seen_without_usage_needs_negative_review")
    elif cut_status == "engine_cut_missing_current_scope_usage_trace":
        blockers.append("cut_card_missing_current_scope_usage_trace")
    elif cut_status == "engine_cut_text_trace_candidate_needs_structured_review":
        blockers.append("cut_card_text_trace_needs_structured_review")
    if not same_lane_roles:
        blockers.append("no_explicit_same_lane_replacement_route")
    status = (
        "engine_cut_pair_ready_for_manual_candidate_copy_review"
        if not blockers
        else "engine_cut_pair_blocks_candidate_copy"
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
    engine_policy_report: Path,
    scan_roots: list[Path] | None = None,
    max_occurrences_per_file: int = 5,
) -> dict[str, Any]:
    engine_payload = load_json(engine_policy_report)
    roots = scan_roots or [REPORT_DIR]
    cut_rows: list[dict[str, Any]] = []
    pair_reviews: list[dict[str, Any]] = []
    all_text_occurrences: list[dict[str, Any]] = []
    pool_summaries: list[dict[str, Any]] = []

    for pool in target_pool_rows(engine_payload):
        deck_id = str(pool.get("deck_id") or "")
        commander = str(pool.get("commander") or "")
        cuts = ready_cut_rows(pool)
        pairs = pair_rows(pool)
        cut_names = [str(row.get("card_name") or "") for row in cuts]
        structured = collect_structured_evidence(
            scan_roots=roots,
            deck_id=deck_id,
            commander=commander,
            cut_names=cut_names,
        )
        text_occurrences = scan_text_occurrences(
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
    pair_ready_count = sum(1 for row in pair_reviews if row.get("status") == "engine_cut_pair_ready_for_manual_candidate_copy_review")
    usage_blocked = [row["card_name"] for row in cut_rows if row["status"] == "engine_cut_usage_observed_blocks_candidate_copy"]
    missing_trace = [row["card_name"] for row in cut_rows if row["status"] == "engine_cut_missing_current_scope_usage_trace"]
    explicit_same_lane_route_count = sum(len(row.get("explicit_same_lane_roles") or []) for row in pair_reviews)
    if pair_ready_count:
        status = "engine_cut_usage_same_lane_proof_ready_for_manual_review"
        next_gate = "manual_review_engine_cut_pair_before_candidate_copy"
    else:
        status = "engine_cut_usage_same_lane_proof_blocks_candidate_copy"
        next_gate = "generate_current_scope_trace_or_find_explicit_same_lane_engine_replacement_before_candidate_copy"
    blockers = []
    if usage_blocked:
        blockers.append("usage_observed_blocks_engine_cuts:" + ",".join(usage_blocked))
    if missing_trace:
        blockers.append("missing_current_scope_usage_trace_for_engine_cuts:" + ",".join(missing_trace))
    if explicit_same_lane_route_count == 0 and pair_reviews:
        blockers.append("no_explicit_same_lane_replacement_route_for_engine_cut_pairs")
    if not cut_rows:
        blockers.append("no_engine_cut_pressure_rows_to_review")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_engine_cut_usage_same_lane_proof_scout",
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
            "engine_policy_report": artifact_rel(engine_policy_report),
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
            "usage_boundary": "Observed use by the target deck blocks treating an engine cut as safe.",
            "same_lane_boundary": "A removal add does not replace an engine or tutor cut unless an explicit same-lane route is proven.",
            "trace_boundary": "Textual trace references are scout evidence only; structured trace/proof rows drive this decision.",
            "mutation_boundary": "This scout does not copy decks, run battles, mutate DBs, or promote packages.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Engine Cut Usage Same-Lane Proof Scout",
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
    parser.add_argument("--engine-policy-report", type=Path, default=DEFAULT_ENGINE_POLICY_REPORT)
    parser.add_argument("--scan-root", action="append", type=Path)
    parser.add_argument("--max-occurrences-per-file", type=int, default=5)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    roots = args.scan_root if args.scan_root else [REPORT_DIR]
    payload = build_report(
        engine_policy_report=args.engine_policy_report,
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
