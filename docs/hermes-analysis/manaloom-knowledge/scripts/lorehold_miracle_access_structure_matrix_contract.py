#!/usr/bin/env python3
"""Define the Lorehold miracle-access micro-shell structure matrix contract.

This read-only matrix is the next gate after the miracle-access-first shell
contract. It defines scoring lanes, hard gates, and candidate-row requirements
for a future micro-shell, but it does not materialize a deck or run battle.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_CONTRACT = (
    REPORT_DIR / "lorehold_miracle_access_first_shell_contract_20260705_current_relearn.json"
)
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_CUT_MINER = (
    REPORT_DIR / "lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json"
)
DEFAULT_CLOSING_TRACE = REPORT_DIR / "lorehold_closing_window_trace_miner_20260704_role_tag_repair.json"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_miracle_access_structure_matrix_contract_20260705_current_relearn"
)

TARGET_CONTRACT = "miracle_access_first_shell_contract"

MATRIX_CELLS = [
    {
        "cell_key": "topdeck_miracle_access",
        "weight": 30,
        "lane": "topdeck_miracle_setup",
        "required_metrics": ["miracle_cast", "topdeck_manipulation_activated"],
        "protected_anchors": ["Sensei's Divining Top", "Scroll Rack", "Library of Leng", "Land Tax"],
        "scoring_rule": "candidate_must_meet_or_exceed_607_floor",
    },
    {
        "cell_key": "turn_cycle_miracle_mana",
        "weight": 20,
        "lane": "early_mana_and_opponent_turn_mana",
        "required_metrics": ["static_cost_reduction_total", "lorehold_cost_paid"],
        "protected_anchors": ["Bender's Waterskin", "Victory Chimes", "The Mind Stone"],
        "scoring_rule": "candidate_must_not_reduce_opponent_turn_miracle_mana",
    },
    {
        "cell_key": "spell_volume_density",
        "weight": 15,
        "lane": "instant_sorcery_density",
        "required_metrics": ["lorehold_spell_cast"],
        "protected_anchors": ["Mizzix's Mastery", "Creative Technique"],
        "scoring_rule": "candidate_must_preserve_spell_volume_and_non_dud_first_draws",
    },
    {
        "cell_key": "approach_finisher_conversion",
        "weight": 15,
        "lane": "deterministic_finisher",
        "required_metrics": ["approach_conversion", "miracle_cast:Approach of the Second Sun"],
        "protected_anchors": ["Approach of the Second Sun", "Storm Herd"],
        "scoring_rule": "candidate_must_not_make_approach_conversion_disappear",
    },
    {
        "cell_key": "pressure_survival_floor",
        "weight": 10,
        "lane": "protection_window_and_pressure_absorber",
        "required_metrics": ["Winota fast-pressure slice", "candidate_died_before_closing_window"],
        "protected_anchors": ["Teferi's Protection", "Flawless Maneuver", "Redirect Lightning"],
        "scoring_rule": "candidate_must_not_regress_fast_pressure_slice",
    },
    {
        "cell_key": "same_lane_cut_safety",
        "weight": 25,
        "lane": "same_lane_cuts",
        "required_metrics": ["named_seed_safe_cut_count", "cut_shortage"],
        "protected_anchors": [],
        "scoring_rule": "each_add_must_have_same_lane_named_cut_or_documented_shell_fork",
    },
]

HARD_GATES = [
    {
        "gate_key": "contract_written",
        "blocks_matrix_scoring_if_false": True,
        "source_field": "contract_written",
    },
    {
        "gate_key": "no_deck_607_mutation",
        "blocks_matrix_scoring_if_false": True,
        "source_field": "deck_607_mutated",
    },
    {
        "gate_key": "no_database_writes",
        "blocks_matrix_scoring_if_false": True,
        "source_field": "postgres_writes",
    },
    {
        "gate_key": "candidate_rows_declared",
        "blocks_matrix_scoring_if_false": True,
        "source_field": "candidate_rows",
    },
    {
        "gate_key": "named_same_lane_cuts_exist",
        "blocks_matrix_scoring_if_false": True,
        "source_field": "named_seed_safe_cut_count",
    },
    {
        "gate_key": "aggregate_blockers_cleared_or_explained",
        "blocks_matrix_scoring_if_false": True,
        "source_field": "aggregate_blocker_count",
    },
]

CANDIDATE_ROW_SCHEMA = [
    "candidate_key",
    "add_card",
    "cut_card",
    "lane",
    "same_lane_cut_reason",
    "protected_anchor_impact",
    "expected_metric_lift",
    "rule_runtime_status",
    "source_provenance",
    "floor_risk",
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


def candidate_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = payload.get("candidate_rows")
    return [dict(row) for row in as_list(rows) if isinstance(row, Mapping)]


def hard_gate_statuses(
    *,
    contract_summary: Mapping[str, Any],
    contract_payload: Mapping[str, Any],
    cut_summary: Mapping[str, Any],
    candidate_count: int,
) -> list[dict[str, Any]]:
    values = {
        "contract_written": bool(contract_summary.get("contract_written")),
        "deck_607_mutated": not bool(contract_payload.get("deck_607_mutated")),
        "postgres_writes": not bool(contract_payload.get("postgres_writes")),
        "candidate_rows": candidate_count > 0,
        "named_seed_safe_cut_count": as_int(cut_summary.get("named_seed_safe_cut_count")) > 0,
        "aggregate_blocker_count": as_int(contract_summary.get("aggregate_blocker_count")) == 0,
    }
    out: list[dict[str, Any]] = []
    for gate in HARD_GATES:
        source_field = str(gate["source_field"])
        passed = bool(values.get(source_field))
        out.append(
            {
                "gate_key": gate["gate_key"],
                "passed": passed,
                "source_field": source_field,
                "blocks_matrix_scoring": bool(gate["blocks_matrix_scoring_if_false"] and not passed),
            }
        )
    return out


def matrix_cell_rows(contract_payload: Mapping[str, Any], value_model: Mapping[str, Any]) -> list[dict[str, Any]]:
    contract = as_dict(contract_payload.get("contract"))
    strategic_floors = as_dict(contract.get("strategic_floors_from_607"))
    anchor_floors = as_dict(contract.get("anchor_access_floors_from_607"))
    lane_profile = as_dict(summary(value_model).get("lane_profile"))
    rows: list[dict[str, Any]] = []
    for cell in MATRIX_CELLS:
        floor_snapshot = {
            metric: strategic_floors.get(metric)
            for metric in as_list(cell.get("required_metrics"))
            if metric in strategic_floors
        }
        anchor_snapshot = {
            anchor: anchor_floors.get(anchor)
            for anchor in as_list(cell.get("protected_anchors"))
            if anchor in anchor_floors
        }
        rows.append(
            {
                **cell,
                "current_607_metric_floor_snapshot": floor_snapshot,
                "current_607_anchor_access_snapshot": anchor_snapshot,
                "current_607_lane_profile_count": lane_profile.get(cell.get("lane")) or 0,
            }
        )
    return rows


def decision_status(
    *,
    contract_summary: Mapping[str, Any],
    contract_payload: Mapping[str, Any],
    hard_gates: list[Mapping[str, Any]],
    candidate_count: int,
) -> tuple[str, str, bool]:
    if contract_summary.get("selected_contract_key") != TARGET_CONTRACT:
        return (
            "miracle_access_structure_matrix_blocked_missing_contract",
            "rerun_miracle_access_first_shell_contract",
            False,
        )
    if not bool(contract_summary.get("structure_matrix_contract_allowed_now")):
        return (
            "miracle_access_structure_matrix_blocked_contract_not_allowed",
            "repair_contract_before_matrix",
            False,
        )
    if candidate_count == 0:
        return (
            "miracle_access_structure_matrix_template_ready_no_candidate_no_battle",
            "declare_candidate_rows_with_named_same_lane_cuts_before_scoring",
            False,
        )
    blockers = [gate for gate in hard_gates if gate.get("blocks_matrix_scoring")]
    if blockers:
        return (
            "miracle_access_structure_matrix_candidate_blocked_by_hard_gates",
            "clear_named_cut_and_floor_blockers_before_scoring",
            False,
        )
    if contract_payload.get("deck_607_mutated") or contract_payload.get("postgres_writes"):
        return (
            "miracle_access_structure_matrix_blocked_mutation_detected",
            "discard_mutating_candidate_and_restart_read_only",
            False,
        )
    return (
        "miracle_access_structure_matrix_ready_to_score_candidate_rows_no_battle",
        "score_candidate_rows_then_generate_lab_deck_only_if_matrix_passes",
        True,
    )


def build_report(
    *,
    contract_payload: Mapping[str, Any],
    value_model: Mapping[str, Any],
    cut_miner: Mapping[str, Any],
    closing_trace: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    contract_summary = summary(contract_payload)
    value_summary = summary(value_model)
    cut_summary = summary(cut_miner)
    closing_summary = summary(closing_trace)
    rows = candidate_rows(contract_payload)
    cells = matrix_cell_rows(contract_payload, value_model)
    gates = hard_gate_statuses(
        contract_summary=contract_summary,
        contract_payload=contract_payload,
        cut_summary=cut_summary,
        candidate_count=len(rows),
    )
    status, next_action, scoring_allowed = decision_status(
        contract_summary=contract_summary,
        contract_payload=contract_payload,
        hard_gates=gates,
        candidate_count=len(rows),
    )
    blocking_gates = [gate["gate_key"] for gate in gates if gate["blocks_matrix_scoring"]]
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_miracle_access_structure_matrix_contract",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "status": status,
        "summary": {
            "decision_status": status,
            "selected_contract_key": contract_summary.get("selected_contract_key") or "",
            "matrix_cell_count": len(cells),
            "candidate_row_count": len(rows),
            "matrix_scoring_allowed_now": scoring_allowed,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "named_seed_safe_cut_count": as_int(cut_summary.get("named_seed_safe_cut_count")),
            "cut_shortage": as_int(cut_summary.get("cut_shortage")),
            "contract_aggregate_blocker_count": as_int(contract_summary.get("aggregate_blocker_count")),
            "blocking_hard_gate_count": len(blocking_gates),
            "preflight_gate_ready_now_count": as_int(contract_summary.get("preflight_gate_ready_now_count")),
            "closing_window_comparison_count": as_int(closing_summary.get("comparison_count")),
            "value_model_quantity_total": as_int(value_summary.get("quantity_total")),
            "value_model_land_quantity": as_int(
                as_dict(value_summary.get("mana_foundation")).get("land_quantity")
            ),
            "value_model_ramp_quantity": as_int(
                as_dict(value_summary.get("mana_foundation")).get("ramp_quantity")
            ),
            "recommended_next_action": next_action,
        },
        "matrix_contract": {
            "candidate_row_schema": CANDIDATE_ROW_SCHEMA,
            "matrix_cells": cells,
            "hard_gates": gates,
            "blocking_hard_gates": blocking_gates,
            "candidate_rows": rows,
            "scoring_policy": {
                "total_positive_weight": sum(as_int(cell.get("weight")) for cell in cells),
                "minimum_rule": "all_hard_gates_must_pass_before_any_score_matters",
                "tie_breaker": (
                    "prefer the row that preserves miracle/topdeck floors with the "
                    "fewest protected-anchor risks and the narrowest same-lane cut"
                ),
            },
            "materialization_policy": [
                "do_not_materialize_a_deck_from_template_only",
                "candidate_rows_must_name_adds_and_cuts_first",
                "any generated list stays lab-only until equal gate beats 607",
                "battle remains closed until matrix score and trace floors pass",
            ],
        },
        "source_evidence": {
            "contract_summary": contract_summary,
            "value_model_summary": value_summary,
            "cut_miner_summary": cut_summary,
            "closing_trace_summary": closing_summary,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "matrix_scoring_allowed_now": scoring_allowed,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "The matrix is defined, but scoring/materialization needs named "
                "candidate rows and hard-gate clearance first."
            )
            if not scoring_allowed
            else (
                "Candidate rows can be scored by the matrix, but battle and "
                "promotion remain closed until a scored lab deck passes later gates."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_generate_a_deck_from_template_only",
                "declare candidate add/cut rows before scoring",
                "require named same-lane cuts and miracle/topdeck floor preservation",
                "keep battle closed until matrix and trace gates pass",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    matrix = payload["matrix_contract"]
    lines = [
        "# Lorehold Miracle Access Structure Matrix Contract",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Selected contract: `{summary_row['selected_contract_key']}`",
        f"- Matrix cells: `{summary_row['matrix_cell_count']}`",
        f"- Candidate rows: `{summary_row['candidate_row_count']}`",
        f"- Matrix scoring allowed now: `{str(summary_row['matrix_scoring_allowed_now']).lower()}`",
        f"- Candidate deck materialization allowed now: `{str(summary_row['candidate_deck_materialization_allowed_now']).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- Named seed-safe cuts: `{summary_row['named_seed_safe_cut_count']}`",
        f"- Blocking hard gates: `{summary_row['blocking_hard_gate_count']}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Matrix Cells", ""])
    lines.append("| Cell | Lane | Weight | Metrics | Rule |")
    lines.append("| --- | --- | ---: | --- | --- |")
    for cell in as_list(matrix.get("matrix_cells")):
        lines.append(
            "| {cell} | `{lane}` | {weight} | `{metrics}` | {rule} |".format(
                cell=cell.get("cell_key") or "",
                lane=cell.get("lane") or "",
                weight=cell.get("weight") or 0,
                metrics=", ".join(as_list(cell.get("required_metrics"))),
                rule=cell.get("scoring_rule") or "",
            )
        )
    lines.extend(["", "## Hard Gates", ""])
    lines.append("| Gate | Passed | Blocks Scoring |")
    lines.append("| --- | ---: | ---: |")
    for gate in as_list(matrix.get("hard_gates")):
        lines.append(
            "| `{}` | `{}` | `{}` |".format(
                gate.get("gate_key"),
                str(gate.get("passed")).lower(),
                str(gate.get("blocks_matrix_scoring")).lower(),
            )
        )
    lines.extend(["", "## Candidate Row Schema", ""])
    for item in as_list(matrix.get("candidate_row_schema")):
        lines.append(f"- `{item}`")
    lines.extend(["", "## Materialization Policy", ""])
    for item in as_list(matrix.get("materialization_policy")):
        lines.append(f"- `{item}`")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- matrix_scoring_allowed_now: `{str(decision['matrix_scoring_allowed_now']).lower()}`")
    lines.append(f"- candidate_deck_materialization_allowed_now: `{str(decision['candidate_deck_materialization_allowed_now']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append("- next_actions:")
    for action in decision["next_actions"]:
        lines.append(f"  - {action}")
    lines.append("")
    return "\n".join(lines)


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
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--cut-miner", type=Path, default=DEFAULT_CUT_MINER)
    parser.add_argument("--closing-trace", type=Path, default=DEFAULT_CLOSING_TRACE)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "contract": args.contract,
        "value_model": args.value_model,
        "cut_miner": args.cut_miner,
        "closing_trace": args.closing_trace,
    }
    payload = build_report(
        contract_payload=read_json(args.contract),
        value_model=read_json(args.value_model),
        cut_miner=read_json(args.cut_miner),
        closing_trace=read_json(args.closing_trace),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
