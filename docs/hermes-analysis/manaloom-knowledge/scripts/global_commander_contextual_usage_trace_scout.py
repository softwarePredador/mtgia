#!/usr/bin/env python3
"""Scout current-scope usage traces for contextual Commander stage cuts.

This read-only gate consumes the contextual stage-cut evidence collector report
and searches local report artifacts for current-scope replay/trace evidence of
the contextual cut cards. Historical planning references and cross-deck traces
are recorded as non-proof only. The scout does not run battles, mutate any DB,
reclassify cuts, materialize candidates, or promote packages.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_CONTEXTUAL_EVIDENCE_REPORT = (
    REPORT_DIR / "global_commander_contextual_stage_cut_evidence_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_contextual_usage_trace_scout_20260705_kaalia_value_safe_stage1_repair_scope1"
)

TRACE_MARKERS = ("replay", "trace", "events", "forensic", "battle_probe")
USAGE_EVENT_MARKERS = (
    "draw",
    "drawn",
    "cast",
    "resolve",
    "resolved",
    "used",
    "activated",
    "spell_resolved",
    "cost_paid",
    "decision",
)
NON_PROOF_PLANNING_MARKERS = (
    "stage_only_cut_evidence_plan",
    "contextual_stage_cut_evidence_collector",
    "contextual_usage_trace_scout",
    "cut_source_lane_expander",
    "payoff_package_synthesizer",
    "profile_repair_candidate_model",
    "candidate_package_strategy_matrix",
    "package_scope_reducer",
)
TEXT_SUFFIXES = {".json", ".jsonl", ".md", ".txt", ".out"}


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


def target_cards(payload: Mapping[str, Any]) -> list[str]:
    cards = []
    for row in payload.get("contextual_evidence_rows") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            cards.append(str(row["card_name"]))
    return cards


def scope_tokens(summary: Mapping[str, Any]) -> set[str]:
    tokens = {"global_commander"}
    deck_id = str(summary.get("deck_id") or "").strip()
    commander = normalize_name(str(summary.get("commander") or ""))
    if deck_id:
        tokens.add(f"deck{deck_id}")
    if "kaalia" in commander:
        tokens.add("kaalia")
    return tokens


def is_text_artifact(path: Path) -> bool:
    return path.is_file() and path.suffix.lower() in TEXT_SUFFIXES


def iter_artifacts(scan_root: Path) -> Iterable[Path]:
    if scan_root.is_file():
        yield scan_root
        return
    for path in scan_root.rglob("*"):
        if is_text_artifact(path):
            yield path


def has_trace_marker(path_text: str) -> bool:
    return any(marker in path_text for marker in TRACE_MARKERS)


def has_current_scope(path_text: str, scopes: set[str]) -> bool:
    return any(token in path_text for token in scopes)


def is_planning_reference(path_text: str) -> bool:
    return any(marker in path_text for marker in NON_PROOF_PLANNING_MARKERS)


def line_has_usage_marker(line: str) -> bool:
    lowered = line.lower()
    return any(marker in lowered for marker in USAGE_EVENT_MARKERS)


def classify_occurrence(*, path: Path, line: str, scopes: set[str]) -> str:
    path_text = rel(path).lower()
    if is_planning_reference(path_text):
        return "planning_reference_not_usage_trace"
    if has_current_scope(path_text, scopes) and has_trace_marker(path_text) and line_has_usage_marker(line):
        return "current_scope_usage_trace_candidate"
    if has_current_scope(path_text, scopes) and has_trace_marker(path_text):
        return "current_scope_trace_reference_without_usage_marker"
    if has_trace_marker(path_text):
        return "historical_or_cross_deck_trace_reference_not_proof"
    if has_current_scope(path_text, scopes):
        return "current_scope_non_trace_reference_not_proof"
    return "cross_scope_reference_not_proof"


def scan_file_for_cards(*, path: Path, cards: list[str], scopes: set[str], max_occurrences: int) -> list[dict[str, Any]]:
    wanted = [(card, normalize_name(card)) for card in cards]
    occurrences: list[dict[str, Any]] = []
    try:
        with path.open("r", encoding="utf-8", errors="ignore") as handle:
            for line_number, line in enumerate(handle, start=1):
                normalized_line = normalize_name(line)
                for card, key in wanted:
                    if key and key in normalized_line:
                        occurrences.append(
                            {
                                "card_name": card,
                                "path": rel(path),
                                "line": line_number,
                                "classification": classify_occurrence(path=path, line=line, scopes=scopes),
                                "excerpt": " ".join(line.strip().split())[:260],
                            }
                        )
                        if len(occurrences) >= max_occurrences:
                            return occurrences
    except OSError:
        return occurrences
    return occurrences


def scan_artifacts(
    *,
    scan_roots: list[Path],
    cards: list[str],
    scopes: set[str],
    max_occurrences_per_file: int,
) -> list[dict[str, Any]]:
    occurrences: list[dict[str, Any]] = []
    for root in scan_roots:
        if not root.exists():
            continue
        for path in iter_artifacts(root):
            if path.name.startswith("global_commander_contextual_usage_trace_scout_"):
                continue
            path_text = rel(path).lower()
            if not (
                has_current_scope(path_text, scopes)
                or has_trace_marker(path_text)
                or any(normalize_name(card) in normalize_name(path.name) for card in cards)
            ):
                continue
            occurrences.extend(
                scan_file_for_cards(
                    path=path,
                    cards=cards,
                    scopes=scopes,
                    max_occurrences=max_occurrences_per_file,
                )
            )
    occurrences.sort(
        key=lambda row: (
            0 if row["classification"] == "current_scope_usage_trace_candidate" else 1,
            str(row.get("card_name") or ""),
            str(row.get("path") or ""),
            int(row.get("line") or 0),
        )
    )
    return occurrences


def group_counts(rows: list[Mapping[str, Any]], key: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for row in rows:
        value = str(row.get(key) or "")
        counts[value] = counts.get(value, 0) + 1
    return counts


def evidence_by_card(rows: list[Mapping[str, Any]], cards: list[str]) -> dict[str, dict[str, Any]]:
    result = {card: {"current_usage_trace_count": 0, "non_proof_reference_count": 0} for card in cards}
    for row in rows:
        card = str(row.get("card_name") or "")
        if card not in result:
            continue
        if row.get("classification") == "current_scope_usage_trace_candidate":
            result[card]["current_usage_trace_count"] += 1
        else:
            result[card]["non_proof_reference_count"] += 1
    return result


def build_report(
    *,
    contextual_evidence_report: Path,
    scan_roots: list[Path] | None = None,
    max_occurrences_per_file: int = 5,
) -> dict[str, Any]:
    contextual_payload = load_json(contextual_evidence_report)
    summary = contextual_payload.get("summary") or {}
    cards = target_cards(contextual_payload)
    scopes = scope_tokens(summary)
    roots = scan_roots if scan_roots is not None else [REPORT_DIR]
    occurrences = scan_artifacts(
        scan_roots=roots,
        cards=cards,
        scopes=scopes,
        max_occurrences_per_file=max_occurrences_per_file,
    )
    current_usage = [row for row in occurrences if row["classification"] == "current_scope_usage_trace_candidate"]
    by_card = evidence_by_card(occurrences, cards)
    if not cards:
        status = "contextual_usage_trace_scout_blocks_no_contextual_cards"
        next_gate = "find_contextual_stage_cut_rows_before_usage_trace_scout"
    elif current_usage:
        status = "contextual_usage_trace_scout_partial_current_trace_evidence"
        next_gate = "review_current_scope_trace_events_before_any_reclassification"
    else:
        status = "contextual_usage_trace_scout_no_current_trace_evidence"
        next_gate = "generate_or_import_current_scope_usage_trace_before_reclassification"
    blockers = []
    if cards and not current_usage:
        blockers.append("no_current_scope_usage_trace_evidence_for_contextual_stage_cuts")
    if not cards:
        blockers.append("no_contextual_cards_to_trace")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_contextual_usage_trace_scout",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_run_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "input_artifacts": {
            "contextual_evidence_report": rel(contextual_evidence_report),
            "scan_roots": [rel(root) for root in roots],
        },
        "summary": {
            "deck_id": str(summary.get("deck_id") or ""),
            "commander": str(summary.get("commander") or ""),
            "contextual_card_count": len(cards),
            "occurrence_count": len(occurrences),
            "current_usage_trace_evidence_count": len(current_usage),
            "non_proof_reference_count": len(occurrences) - len(current_usage),
            "classification_counts": group_counts(occurrences, "classification"),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "evidence_by_card": by_card,
        "usage_trace_occurrences": current_usage[:30],
        "non_proof_occurrence_sample": [row for row in occurrences if row not in current_usage][:30],
        "policy": {
            "scout_boundary": "This scout searches existing artifacts only; it does not run a battle.",
            "proof_boundary": "Planning, rule-coherence, and cross-deck occurrences do not prove a contextual cut is safe.",
            "reclassification_boundary": "Even current-scope trace evidence requires manual value-safe review before candidate copy.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Contextual Usage Trace Scout",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- contextual_card_count: `{summary['contextual_card_count']}`",
        f"- occurrence_count: `{summary['occurrence_count']}`",
        f"- current_usage_trace_evidence_count: `{summary['current_usage_trace_evidence_count']}`",
        f"- non_proof_reference_count: `{summary['non_proof_reference_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_run_performed: `{str(payload['battle_run_performed']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Evidence By Card",
        "",
        "| Card | Current Usage Trace | Non-Proof References |",
        "| --- | ---: | ---: |",
    ]
    for card, row in payload["evidence_by_card"].items():
        lines.append(
            f"| `{card}` | {row['current_usage_trace_count']} | {row['non_proof_reference_count']} |"
        )
    lines.extend(["", "## Current Usage Trace Occurrences", ""])
    if payload["usage_trace_occurrences"]:
        for row in payload["usage_trace_occurrences"][:12]:
            lines.append(
                f"- `{row['card_name']}` in `{row['path']}` line `{row['line']}`: {row['excerpt']}"
            )
    else:
        lines.append("- none")
    lines.extend(["", "## Non-Proof Occurrence Sample", ""])
    for row in payload["non_proof_occurrence_sample"][:12]:
        lines.append(
            f"- `{row['card_name']}`: `{row['classification']}` in `{row['path']}` line `{row['line']}`"
        )
    if not payload["non_proof_occurrence_sample"]:
        lines.append("- none")
    lines.extend(["", "## Blockers", ""])
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
            lines.append(f"- `{blocker}`")
    else:
        lines.append("- none")
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
    parser.add_argument("--contextual-evidence-report", type=Path, default=DEFAULT_CONTEXTUAL_EVIDENCE_REPORT)
    parser.add_argument("--scan-root", action="append", type=Path)
    parser.add_argument("--max-occurrences-per-file", type=int, default=5)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    roots = args.scan_root if args.scan_root else [REPORT_DIR]
    payload = build_report(
        contextual_evidence_report=args.contextual_evidence_report,
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
