#!/usr/bin/env python3
"""Write the Lorehold topdeck floor trace target contract.

This read-only contract is narrower than a shell contract. It names the current
topdeck target cards and the floor evidence each must provide before any
sidecar materialization, structure matrix, forced-access diagnostic, or natural
battle gate.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_FRONTIER = (
    REPORT_DIR / "lorehold_learning_frontier_after_probe_closure_20260705_current.json"
)
DEFAULT_CANDIDATE_QUEUE = (
    REPORT_DIR / "lorehold_topdeck_sidecar_candidate_queue_20260705_current.json"
)
DEFAULT_PROBE_EVIDENCE = (
    REPORT_DIR / "lorehold_topdeck_sidecar_probe_evidence_miner_20260705_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_topdeck_floor_trace_target_contract_20260705_current"

TARGET_SIDECAR_TAG = "topdeck_access_sidecar_primary"
TARGET_CARD_ORDER = [
    "Penance",
    "Galvanoth",
    "Dragon's Rage Channeler",
    "Valakut Awakening // Valakut Stoneforge",
    "Wheel of Fortune",
]

BASELINE_FLOOR_METRICS = [
    {
        "metric": "miracle_cast",
        "floor_rule": "meet_or_exceed_current_607_same_seed_floor",
        "why": "The candidate cannot reduce Lorehold's primary miracle window.",
    },
    {
        "metric": "topdeck_manipulation_activated",
        "floor_rule": "meet_or_exceed_current_607_same_seed_floor",
        "why": "The candidate must preserve active top-library control.",
    },
    {
        "metric": "lorehold_upkeep_rummage",
        "floor_rule": "meet_or_exceed_current_607_same_seed_floor",
        "why": "Lorehold's opponent-turn discard/draw setup is the engine timing.",
    },
    {
        "metric": "lorehold_spell_cast",
        "floor_rule": "no_material_regression_against_607",
        "why": "Topdeck access is only useful if it keeps spell-chain volume intact.",
    },
    {
        "metric": "static_cost_reduction_total",
        "floor_rule": "no_material_regression_against_607",
        "why": "Cost reduction is part of converting the miracle window into action.",
    },
    {
        "metric": "Winota_fast_pressure_slice",
        "floor_rule": "tie_or_improve_current_607_before_promotion",
        "why": "Prior positive-looking packages failed because fast pressure regressed.",
    },
]

TRACE_REQUIREMENTS = [
    "candidate_card_drawn_or_accessed",
    "candidate_card_cast_or_activated_when_applicable",
    "candidate_effect_resolved_or_relevant_static_effect_observed",
    "protected_topdeck_anchors_still_accessed",
    "no_miracle_topdeck_floor_regression",
    "no_fast_pressure_regression_before_promotion",
]

PROTECTED_ANCHORS = [
    "Lorehold, the Historian",
    "Sensei's Divining Top",
    "Scroll Rack",
    "Library of Leng",
    "Land Tax",
    "Bender's Waterskin",
    "Victory Chimes",
    "The Mind Stone",
    "Approach of the Second Sun",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_dict(value: Any) -> dict[str, Any]:
    return dict(value) if isinstance(value, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def queue_target_rows(candidate_queue: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in as_list(candidate_queue.get("candidate_queue")):
        if not isinstance(row, Mapping):
            continue
        if row.get("sidecar_tag") != TARGET_SIDECAR_TAG:
            continue
        add_card = str(row.get("add_card") or "")
        if not add_card:
            continue
        rows.append(
            {
                "add_card": add_card,
                "candidate_key": row.get("candidate_key") or "",
                "lane": row.get("lane") or "",
                "expected_metric_lift": row.get("expected_metric_lift") or "",
                "floor_risk": row.get("floor_risk") or "",
                "rule_runtime_status": row.get("rule_runtime_status") or "",
                "readiness_status": row.get("readiness_status") or "",
                "blockers": as_list(row.get("blockers")),
                "source_provenance": row.get("source_provenance") or "",
            }
        )
    rows.sort(
        key=lambda row: (
            TARGET_CARD_ORDER.index(row["add_card"])
            if row["add_card"] in TARGET_CARD_ORDER
            else len(TARGET_CARD_ORDER),
            row["add_card"],
        )
    )
    return rows


def contract_target_rows(target_rows: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for row in target_rows:
        add_card = str(row.get("add_card") or "")
        out.append(
            {
                "add_card": add_card,
                "candidate_key": row.get("candidate_key") or "",
                "contract_status": "trace_target_only_not_matrix_row",
                "trace_collection_allowed_now": True,
                "forced_access_allowed_now": False,
                "structure_matrix_allowed_now": False,
                "candidate_materialization_allowed_now": False,
                "natural_battle_gate_allowed_now": False,
                "promotion_allowed_now": False,
                "baseline_floor_metrics": BASELINE_FLOOR_METRICS,
                "trace_requirements": TRACE_REQUIREMENTS,
                "blocked_before_matrix": [
                    "missing_named_same_lane_cut",
                    "needs_safe_cut_model",
                    "must_preserve_607_topdeck_miracle_floor",
                    "must_preserve_protected_anchors",
                ],
                "lane": row.get("lane") or "",
                "expected_metric_lift": row.get("expected_metric_lift") or "",
                "floor_risk": row.get("floor_risk") or "",
                "rule_runtime_status": row.get("rule_runtime_status") or "",
                "source_provenance": row.get("source_provenance") or "",
            }
        )
    return out


def build_report(
    *,
    frontier_report: Mapping[str, Any],
    candidate_queue: Mapping[str, Any],
    probe_evidence: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    frontier_summary = summary(frontier_report)
    queue_summary = summary(candidate_queue)
    probe_summary = summary(probe_evidence)
    targets = contract_target_rows(queue_target_rows(candidate_queue))
    frontier_selected = frontier_summary.get("selected_next_route") == "topdeck_floor_trace_target_contract"
    missing_inputs = [
        key
        for key, payload in {
            "frontier_report": frontier_report,
            "candidate_queue": candidate_queue,
            "probe_evidence": probe_evidence,
        }.items()
        if not payload
    ]
    if missing_inputs:
        status = "topdeck_floor_trace_contract_inputs_missing_keep_607"
        next_action = "rerun_missing_inputs_before_trace_contract"
        trace_contract_ready = False
    elif not targets:
        status = "topdeck_floor_trace_contract_no_targets_keep_607"
        next_action = "refresh_sidecar_candidate_queue_before_trace_contract"
        trace_contract_ready = False
    elif not frontier_selected:
        status = "topdeck_floor_trace_contract_waiting_on_frontier_route_keep_607"
        next_action = "rerun_learning_frontier_after_probe_closure"
        trace_contract_ready = False
    else:
        status = "topdeck_floor_trace_contract_written_no_deck_action_keep_607"
        next_action = "collect_trace_floor_evidence_for_targets_before_matrix_or_sidecar"
        trace_contract_ready = True
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_floor_trace_target_contract",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": status,
            "frontier_selected_route": frontier_summary.get("selected_next_route") or "",
            "missing_inputs": missing_inputs,
            "trace_contract_ready": trace_contract_ready,
            "target_card_count": len(targets),
            "queue_row_count": as_int(queue_summary.get("queue_row_count")),
            "probe_row_count": as_int(probe_summary.get("probe_row_count")),
            "safe_cut_ready_count": as_int(frontier_summary.get("safe_cut_ready_count"))
            or as_int(probe_summary.get("safe_cut_ready_count")),
            "matrix_candidate_row_eligible_count": as_int(
                frontier_summary.get("matrix_candidate_row_eligible_count")
            )
            or as_int(queue_summary.get("matrix_candidate_row_eligible_count")),
            "trace_collection_allowed_now": trace_contract_ready,
            "forced_access_allowed_now": False,
            "structure_matrix_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "recommended_next_action": next_action,
        },
        "contract": {
            "contract_key": "topdeck_floor_trace_target_contract",
            "purpose": (
                "Define non-promotional trace floors for current topdeck target cards "
                "before any matrix row, sidecar shell, forced access, or battle gate."
            ),
            "protected_baseline": "deck_607",
            "protected_anchors": PROTECTED_ANCHORS,
            "baseline_floor_metrics": BASELINE_FLOOR_METRICS,
            "target_cards": targets,
            "global_staple_policy": {
                "Mana Vault": "blocked_until_same_lane_nonanchor_cut_and_no_topdeck_floor_regression",
                "The One Ring": "blocked_until_same_lane_draw_value_cut_and_fast_pressure_guard",
            },
            "promotion_gate_reminder": [
                "trace evidence is not deck promotion",
                "forced access is diagnostic only",
                "structure matrix must pass before battle",
                "natural battle gate must use same opponents and seeds against current deck_607",
            ],
        },
        "source_evidence": {
            "frontier_summary": frontier_summary,
            "candidate_queue_summary": queue_summary,
            "probe_evidence_summary": probe_summary,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "allow_deck_mutation_now": False,
            "allow_candidate_materialization_now": False,
            "allow_forced_access_now": False,
            "allow_structure_matrix_now": False,
            "allow_natural_battle_gate_now": False,
            "promotion_allowed": False,
            "reason": (
                "The current queue has topdeck target cards but no safe cut or matrix row. "
                "The only allowed progress is to collect trace-floor evidence as learning."
            ),
            "next_actions": [
                next_action,
                "do_not_convert_trace_targets_into_deck_changes",
                "do_not_route pressure or spell-chain followups until topdeck floors pass",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = summary(payload)
    contract = as_dict(payload.get("contract"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Topdeck Floor Trace Target Contract",
        "",
        f"- Generated at: `{payload.get('generated_at')}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload.get('status')}`",
        f"- Trace contract ready: `{str(summary_row.get('trace_contract_ready')).lower()}`",
        f"- Target card count: `{summary_row.get('target_card_count')}`",
        f"- Safe-cut ready: `{summary_row.get('safe_cut_ready_count')}`",
        f"- Matrix-eligible rows: `{summary_row.get('matrix_candidate_row_eligible_count')}`",
        f"- Forced access allowed: `{str(summary_row.get('forced_access_allowed_now')).lower()}`",
        f"- Structure matrix allowed: `{str(summary_row.get('structure_matrix_allowed_now')).lower()}`",
        f"- Natural battle gate allowed: `{str(summary_row.get('natural_battle_gate_allowed_now')).lower()}`",
        f"- Promotion allowed: `{str(summary_row.get('promotion_allowed_now')).lower()}`",
        f"- Recommended next action: `{summary_row.get('recommended_next_action')}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Protected Anchors", ""])
    for card in as_list(contract.get("protected_anchors")):
        lines.append(f"- `{card}`")
    lines.extend(["", "## Floor Metrics", ""])
    lines.extend(["| Metric | Floor Rule | Why |", "| --- | --- | --- |"])
    for row in as_list(contract.get("baseline_floor_metrics")):
        if isinstance(row, Mapping):
            lines.append(f"| `{row.get('metric')}` | `{row.get('floor_rule')}` | {row.get('why')} |")
    lines.extend(["", "## Target Cards", ""])
    lines.extend(
        [
            "| Card | Contract Status | Trace Allowed | Matrix Allowed | Materialization Allowed | Expected Lift |",
            "| --- | --- | --- | --- | --- | --- |",
        ]
    )
    for row in as_list(contract.get("target_cards")):
        if not isinstance(row, Mapping):
            continue
        lines.append(
            "| `{card}` | `{status}` | `{trace}` | `{matrix}` | `{materialize}` | {lift} |".format(
                card=row.get("add_card"),
                status=row.get("contract_status"),
                trace=str(bool(row.get("trace_collection_allowed_now"))).lower(),
                matrix=str(bool(row.get("structure_matrix_allowed_now"))).lower(),
                materialize=str(bool(row.get("candidate_materialization_allowed_now"))).lower(),
                lift=row.get("expected_metric_lift"),
            )
        )
    lines.extend(["", "## Staple Policy", ""])
    for card, status in sorted(as_dict(contract.get("global_staple_policy")).items()):
        lines.append(f"- `{card}`: `{status}`")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision.get('keep_607_as_protected_baseline')).lower()}`")
    lines.append(f"- allow_deck_mutation_now: `{str(decision.get('allow_deck_mutation_now')).lower()}`")
    lines.append(f"- allow_candidate_materialization_now: `{str(decision.get('allow_candidate_materialization_now')).lower()}`")
    lines.append(f"- allow_forced_access_now: `{str(decision.get('allow_forced_access_now')).lower()}`")
    lines.append(f"- allow_structure_matrix_now: `{str(decision.get('allow_structure_matrix_now')).lower()}`")
    lines.append(f"- allow_natural_battle_gate_now: `{str(decision.get('allow_natural_battle_gate_now')).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision.get('promotion_allowed')).lower()}`")
    lines.append(f"- reason: {decision.get('reason')}")
    lines.append("- next_actions:")
    for action in as_list(decision.get("next_actions")):
        lines.append(f"  - `{action}`")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--frontier", type=Path, default=DEFAULT_FRONTIER)
    parser.add_argument("--candidate-queue", type=Path, default=DEFAULT_CANDIDATE_QUEUE)
    parser.add_argument("--probe-evidence", type=Path, default=DEFAULT_PROBE_EVIDENCE)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "frontier": args.frontier,
        "candidate_queue": args.candidate_queue,
        "probe_evidence": args.probe_evidence,
    }
    payload = build_report(
        frontier_report=read_json(args.frontier),
        candidate_queue=read_json(args.candidate_queue),
        probe_evidence=read_json(args.probe_evidence),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "target_card_count": payload["summary"]["target_card_count"],
                "json": rel(json_path),
                "markdown": rel(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
