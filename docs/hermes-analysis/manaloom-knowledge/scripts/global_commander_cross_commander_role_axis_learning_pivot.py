#!/usr/bin/env python3
"""Pivot repeated same-deck source exhaustion into cross-commander role learning.

This read-only report follows ``global_commander_learning_priority_audit`` when
the top action is a source-expansion cycle. It groups role floor gaps and role
excesses across commanders so the next learning action improves the global deck
model instead of repeating the same deck-specific source search.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT, rel


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
COMMANDER_CONTRACT = REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"
DEFAULT_PRIORITY_REPORT = (
    REPORT_DIR / "global_commander_learning_priority_audit_20260706_source_expansion_cycle_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_cross_commander_role_axis_learning_pivot_20260706_source_expansion_cycle_current"
)
ROLE_LABEL_RE = re.compile(r"^(?P<role>[^=]+)=(?P<count>-?\d+) target (?P<min>-?\d+)-(?P<max>-?\d+)$")
SOURCE_CYCLE_STATE = "source_expansion_cycle_requires_global_learning_pivot"


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


def parse_role_label(value: object) -> dict[str, Any] | None:
    match = ROLE_LABEL_RE.match(str(value or "").strip())
    if not match:
        return None
    return {
        "role": match.group("role"),
        "count": int(match.group("count")),
        "min": int(match.group("min")),
        "max": int(match.group("max")),
    }


def evidence_row(deck_row: Mapping[str, Any], parsed: Mapping[str, Any], direction: str) -> dict[str, Any]:
    deck_id = str(deck_row.get("deck_id") or "")
    source_cycle = str(deck_row.get("source_exhaustion_state") or "") == SOURCE_CYCLE_STATE
    return {
        "deck_id": deck_id,
        "deck_name": deck_row.get("deck_name"),
        "commander": deck_row.get("commander"),
        "role": parsed.get("role"),
        "direction": direction,
        "count": parsed.get("count"),
        "min": parsed.get("min"),
        "max": parsed.get("max"),
        "stage": deck_row.get("stage"),
        "repair_gate_state": deck_row.get("repair_gate_state"),
        "source_exhaustion_state": deck_row.get("source_exhaustion_state"),
        "source_cycle_blocks_same_deck_search": source_cycle,
        "source_exhaustion_prior_blocked_recycled_cut_source_count": int(
            deck_row.get("source_exhaustion_prior_blocked_recycled_cut_source_count") or 0
        ),
        "next_action": deck_row.get("next_action"),
        "benchmark_only": deck_id == "607",
        "deck_action_allowed": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "promotion_allowed": False,
    }


def collect_axis_evidence(deck_rows: Iterable[Mapping[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    axes: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for deck_row in deck_rows:
        for label in deck_row.get("below_floor_roles") or []:
            parsed = parse_role_label(label)
            if parsed:
                axes[str(parsed["role"])].append(evidence_row(deck_row, parsed, "below_floor"))
        for label in deck_row.get("above_range_roles") or []:
            parsed = parse_role_label(label)
            if parsed:
                axes[str(parsed["role"])].append(evidence_row(deck_row, parsed, "above_range"))
    return axes


def axis_next_gate(role: str, cycle_blocked_count: int, below_count: int, above_count: int) -> str:
    if cycle_blocked_count:
        return "build_cross_commander_role_axis_policy_before_more_same_deck_source_expansion"
    if below_count and above_count:
        return "calibrate_role_floor_and_ceiling_before_candidate_copy"
    if below_count:
        return "calibrate_role_floor_before_candidate_copy"
    if above_count:
        return "calibrate_role_ceiling_before_strategy_matrix"
    return "recheck_role_axis_inputs"


def axis_priority(role: str, rows: list[Mapping[str, Any]]) -> int:
    actionable = [row for row in rows if not row.get("benchmark_only")]
    cycle_blocked_count = sum(1 for row in actionable if row.get("source_cycle_blocks_same_deck_search"))
    below_count = sum(1 for row in actionable if row.get("direction") == "below_floor")
    above_count = sum(1 for row in actionable if row.get("direction") == "above_range")
    commander_count = len({str(row.get("commander") or "") for row in actionable})
    score = below_count * 30 + above_count * 10 + commander_count * 7
    if cycle_blocked_count:
        score += 200
    if below_count and above_count:
        score += 25
    if role == "land":
        score += 10
    return score


def build_axis_rows(axes: Mapping[str, list[dict[str, Any]]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for role, evidence in axes.items():
        actionable = [row for row in evidence if not row.get("benchmark_only")]
        benchmark = [row for row in evidence if row.get("benchmark_only")]
        below_count = sum(1 for row in actionable if row.get("direction") == "below_floor")
        above_count = sum(1 for row in actionable if row.get("direction") == "above_range")
        cycle_blocked = [row for row in actionable if row.get("source_cycle_blocks_same_deck_search")]
        commander_count = len({str(row.get("commander") or "") for row in actionable})
        status = "cross_commander_role_axis_ready_no_deck_action"
        if cycle_blocked:
            status = "cross_commander_role_axis_blocks_same_deck_source_cycle"
        rows.append(
            {
                "role": role,
                "status": status,
                "priority_score": axis_priority(role, evidence),
                "actionable_deck_count": len(actionable),
                "benchmark_only_deck_count": len(benchmark),
                "commander_count": commander_count,
                "below_floor_deck_count": below_count,
                "above_range_deck_count": above_count,
                "source_cycle_blocked_deck_count": len(cycle_blocked),
                "source_cycle_blocked_decks": [row["deck_id"] for row in cycle_blocked],
                "next_gate": axis_next_gate(role, len(cycle_blocked), below_count, above_count),
                "evidence_rows": evidence,
                "deck_action_allowed": False,
                "candidate_copy_allowed": False,
                "battle_gate_allowed": False,
                "promotion_allowed": False,
            }
        )
    rows.sort(key=lambda row: (-row["priority_score"], row["role"]))
    return rows


def choose_status(axis_rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if not axis_rows:
        return (
            "cross_commander_role_axis_learning_pivot_blocks_no_axes",
            "recheck_global_commander_learning_priority_inputs",
        )
    if any(row.get("source_cycle_blocked_deck_count") for row in axis_rows):
        return (
            "cross_commander_role_axis_learning_pivot_ready_no_deck_action",
            str(axis_rows[0].get("next_gate") or ""),
        )
    return (
        "cross_commander_role_axis_learning_pivot_ready_no_cycle",
        str(axis_rows[0].get("next_gate") or ""),
    )


def build_report(*, priority_report: Path) -> dict[str, Any]:
    priority_payload = load_json(priority_report)
    deck_rows = [
        dict(row)
        for row in priority_payload.get("deck_priorities") or []
        if isinstance(row, Mapping)
    ]
    axis_rows = build_axis_rows(collect_axis_evidence(deck_rows))
    status, next_gate = choose_status(axis_rows)
    top_axis = axis_rows[0] if axis_rows else {}
    axis_status_counts = Counter(str(row.get("status") or "unknown") for row in axis_rows)
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_cross_commander_role_axis_learning_pivot",
        "contract": rel(COMMANDER_CONTRACT),
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "learning_priority_report": artifact_rel(priority_report),
        },
        "summary": {
            "axis_count": len(axis_rows),
            "top_axis_role": top_axis.get("role", ""),
            "top_axis_status": top_axis.get("status", ""),
            "top_axis_priority_score": int(top_axis.get("priority_score") or 0),
            "source_cycle_axis_count": sum(1 for row in axis_rows if row.get("source_cycle_blocked_deck_count")),
            "benchmark_only_excluded_from_action_count": sum(
                int(row.get("benchmark_only_deck_count") or 0) for row in axis_rows
            ),
            "axis_status_counts": dict(sorted(axis_status_counts.items())),
            "candidate_copy_allowed_count": 0,
            "battle_gate_allowed_count": 0,
            "next_gate": next_gate,
        },
        "axis_rows": axis_rows,
        "candidate_copy_blockers": [
            "cross_commander_role_axis_learning_is_not_cut_permission",
            "source_cycle_decks_need_role_axis_policy_before_more_same_deck_source_expansion",
            "deck_607_is_benchmark_evidence_only_not_action_source",
            "battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist",
        ],
        "policy": {
            "pivot_boundary": "This report chooses a learning axis only; it does not add, cut, copy, battle, or promote decks.",
            "cycle_boundary": "High recycled cut-source counts with all seeded roles exhausted require role-axis learning before more same-deck source search.",
            "benchmark_boundary": "Deck 607 evidence is retained as benchmark context but excluded from actionable axis counts.",
            "global_boundary": "Axis evidence groups multiple commanders and variants so one deck cannot become the global objective function.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Cross-Commander Role Axis Learning Pivot",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- axis_count: `{summary['axis_count']}`",
        f"- top_axis_role: `{summary['top_axis_role']}`",
        f"- top_axis_status: `{summary['top_axis_status']}`",
        f"- top_axis_priority_score: `{summary['top_axis_priority_score']}`",
        f"- source_cycle_axis_count: `{summary['source_cycle_axis_count']}`",
        f"- benchmark_only_excluded_from_action_count: `{summary['benchmark_only_excluded_from_action_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Axis Queue",
        "",
        "| Role | Status | Score | Decks | Commanders | Below | Above | Cycle Decks | Next Gate |",
        "| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |",
    ]
    for row in payload["axis_rows"]:
        cycle = ", ".join(row.get("source_cycle_blocked_decks") or []) or "-"
        lines.append(
            "| `{role}` | `{status}` | {score} | {decks} | {commanders} | {below} | {above} | `{cycle}` | `{next}` |".format(
                role=row.get("role"),
                status=row.get("status"),
                score=row.get("priority_score"),
                decks=row.get("actionable_deck_count"),
                commanders=row.get("commander_count"),
                below=row.get("below_floor_deck_count"),
                above=row.get("above_range_deck_count"),
                cycle=cycle,
                next=row.get("next_gate"),
            )
        )
    lines.extend(["", "## Top Axis Evidence", ""])
    top = payload["axis_rows"][0] if payload["axis_rows"] else None
    if top:
        lines.append("| Deck | Commander | Direction | Count | Target | Source Cycle |")
        lines.append("| --- | --- | --- | ---: | --- | ---: |")
        for row in top.get("evidence_rows") or []:
            if row.get("benchmark_only"):
                continue
            target = f"{row.get('min')}-{row.get('max')}"
            lines.append(
                "| `{deck}` | `{commander}` | `{direction}` | {count} | `{target}` | {cycle} |".format(
                    deck=f"{row.get('deck_name')} ({row.get('deck_id')})".replace("|", "/"),
                    commander=str(row.get("commander") or "").replace("|", "/"),
                    direction=row.get("direction"),
                    count=row.get("count"),
                    target=target,
                    cycle=str(row.get("source_cycle_blocks_same_deck_search")).lower(),
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
    parser.add_argument("--priority-report", type=Path, default=DEFAULT_PRIORITY_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(priority_report=args.priority_report)
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
