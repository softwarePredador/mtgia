#!/usr/bin/env python3
"""Close the Lorehold non-floor sidecar probe evidence route.

The sidecar cut-model planner asked for evidence on non-floor-trace probes. The
probe evidence miner then classified those probes, but its recommendation still
left the prior "collect evidence" step implicit. This read-only closure report
joins both artifacts and states whether any non-floor probe became safe-cut or
matrix eligible before another battle/deck route is allowed.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_CUT_MODEL_PLANNER = (
    REPORT_DIR / "lorehold_topdeck_sidecar_cut_model_planner_20260705_current.json"
)
DEFAULT_PROBE_EVIDENCE = (
    REPORT_DIR / "lorehold_topdeck_sidecar_probe_evidence_miner_20260705_current.json"
)
DEFAULT_CURRENT_BEST = (
    REPORT_DIR / "lorehold_current_best_baseline_synthesis_20260705_brain_floor_protected_route_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_non_floor_probe_evidence_closure_20260705_current"
)


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


def normalize_name(value: Any) -> str:
    return " ".join(str(value or "").strip().lower().replace("’", "'").split())


def row_key(row: Mapping[str, Any]) -> tuple[str, str, str]:
    return (
        normalize_name(row.get("add_card")),
        normalize_name(row.get("cut_card")),
        normalize_name(row.get("target_tag") or row.get("sidecar_tag")),
    )


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def planner_probe_rows(planner: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for target in as_list(planner.get("cut_model_targets")):
        if not isinstance(target, Mapping):
            continue
        add_card = target.get("add_card") or ""
        target_tag = target.get("sidecar_tag") or ""
        for probe in as_list(target.get("candidate_cut_probes")):
            if not isinstance(probe, Mapping):
                continue
            rows.append(
                {
                    "add_card": add_card or probe.get("add_card") or "",
                    "cut_card": probe.get("cut_card") or "",
                    "target_tag": target_tag or probe.get("target_tag") or "",
                    "planner_floor_trace_blocked": bool(probe.get("floor_trace_blocked")),
                    "planner_blockers": as_list(probe.get("blockers")),
                    "planner_required_evidence": as_list(probe.get("required_evidence")),
                    "planner_cut_value_tier": probe.get("cut_value_tier") or "",
                    "planner_cut_value_score": as_int(probe.get("cut_value_score")),
                }
            )
    rows.sort(key=lambda row: (row["target_tag"], row["add_card"], row["cut_card"]))
    return rows


def evidence_rows(probe_evidence: Mapping[str, Any]) -> dict[tuple[str, str, str], dict[str, Any]]:
    rows = {}
    for row in as_list(probe_evidence.get("probe_evidence_rows")):
        if not isinstance(row, Mapping):
            continue
        rows[row_key(row)] = dict(row)
    return rows


def closure_class(row: Mapping[str, Any]) -> str:
    if row.get("planner_floor_trace_blocked"):
        return "excluded_floor_trace_blocked_probe"
    if row.get("missing_probe_evidence_row"):
        return "missing_probe_evidence"
    if row.get("safe_cut_ready_now") or row.get("matrix_candidate_row_eligible_now"):
        return "reviewable_matrix_only"
    status = row.get("evidence_status")
    if status == "blocked_exposed_topdeck_role_probe":
        return "closed_exposed_topdeck_role"
    if status == "blocked_generic_mana_probe_not_pair_safe":
        return "closed_generic_mana_probe_route"
    if status == "route_to_dedicated_mana_model_pair":
        return "route_to_dedicated_mana_model_pair"
    if status == "blocked_missing_exposure_evidence":
        return "missing_exposure_evidence"
    return "closed_or_blocked_by_probe_evidence"


def build_closure_rows(
    *,
    planner: Mapping[str, Any],
    probe_evidence: Mapping[str, Any],
) -> list[dict[str, Any]]:
    evidence_by_key = evidence_rows(probe_evidence)
    closure_rows: list[dict[str, Any]] = []
    for probe in planner_probe_rows(planner):
        evidence = evidence_by_key.get(row_key(probe), {})
        row = {
            **probe,
            "included_in_non_floor_closure": not probe["planner_floor_trace_blocked"],
            "missing_probe_evidence_row": not bool(evidence),
            "evidence_status": evidence.get("evidence_status") or "",
            "safe_cut_ready_now": bool(evidence.get("safe_cut_ready_now")),
            "matrix_candidate_row_eligible_now": bool(
                evidence.get("matrix_candidate_row_eligible_now")
            ),
            "candidate_deck_materialization_allowed_now": bool(
                evidence.get("candidate_deck_materialization_allowed_now")
            ),
            "probe_next_action": evidence.get("next_action") or "",
            "probe_blockers": as_list(evidence.get("blockers")),
            "exposure": as_dict(evidence.get("exposure")),
        }
        row["closure_class"] = closure_class(row)
        closure_rows.append(row)
    return closure_rows


def build_report(
    *,
    cut_model_planner: Mapping[str, Any],
    probe_evidence: Mapping[str, Any],
    current_best: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    missing_inputs = [
        key
        for key, payload in {
            "cut_model_planner": cut_model_planner,
            "probe_evidence": probe_evidence,
        }.items()
        if not payload
    ]
    closure_rows = (
        build_closure_rows(planner=cut_model_planner, probe_evidence=probe_evidence)
        if not missing_inputs
        else []
    )
    non_floor_rows = [row for row in closure_rows if row["included_in_non_floor_closure"]]
    status_counts = Counter(row.get("evidence_status") or "missing_probe_evidence_row" for row in non_floor_rows)
    class_counts = Counter(str(row.get("closure_class") or "") for row in non_floor_rows)
    missing_evidence = [row for row in non_floor_rows if row["missing_probe_evidence_row"]]
    reviewable_rows = [
        row
        for row in non_floor_rows
        if row["safe_cut_ready_now"] or row["matrix_candidate_row_eligible_now"]
    ]
    planner_summary = summary(cut_model_planner)
    probe_summary = summary(probe_evidence)
    current_best_summary = summary(current_best)
    mana_route_status = str(probe_summary.get("mana_route_status") or "")

    if missing_inputs:
        report_status = "non_floor_probe_evidence_closure_missing_inputs_keep_607"
    elif reviewable_rows:
        report_status = "non_floor_probe_evidence_closure_reviewable_rows_matrix_only"
    elif missing_evidence:
        report_status = "non_floor_probe_evidence_closure_missing_evidence_keep_607"
    else:
        report_status = "non_floor_probe_evidence_closure_closed_no_matrix_rows_keep_607"

    recommended_next_action = (
        "define_new_shell_contract_or_new_cut_evidence_before_any_battle_gate"
        if report_status == "non_floor_probe_evidence_closure_closed_no_matrix_rows_keep_607"
        else "repair_or_review_probe_evidence_before_any_battle_gate"
    )
    if report_status == "non_floor_probe_evidence_closure_reviewable_rows_matrix_only":
        recommended_next_action = "score_reviewable_rows_in_structure_matrix_before_any_battle_gate"

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_non_floor_probe_evidence_closure",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": report_status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": report_status,
            "planner_named_probe_count": as_int(planner_summary.get("named_cut_probe_count")),
            "planner_floor_trace_blocked_probe_count": as_int(
                planner_summary.get("floor_trace_blocked_probe_count")
            ),
            "planner_floor_trace_cut_blocker_count": as_int(
                planner_summary.get("floor_trace_cut_blocker_count")
            ),
            "non_floor_probe_count": len(non_floor_rows),
            "probe_evidence_row_count": as_int(probe_summary.get("probe_row_count")),
            "missing_probe_evidence_row_count": len(missing_evidence),
            "non_floor_safe_cut_ready_count": sum(1 for row in non_floor_rows if row["safe_cut_ready_now"]),
            "non_floor_matrix_candidate_row_eligible_count": sum(
                1 for row in non_floor_rows if row["matrix_candidate_row_eligible_now"]
            ),
            "blocked_exposed_topdeck_role_probe_count": status_counts.get(
                "blocked_exposed_topdeck_role_probe", 0
            ),
            "blocked_generic_mana_probe_count": status_counts.get(
                "blocked_generic_mana_probe_not_pair_safe", 0
            ),
            "mana_route_status": mana_route_status,
            "mana_model_eligible_pair_count": as_int(probe_summary.get("mana_model_eligible_pair_count")),
            "mana_model_exact_rejected_pair_count": as_int(
                probe_summary.get("mana_model_exact_rejected_pair_count")
            ),
            "current_best_decision_status": current_best_summary.get("decision_status") or "",
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "status_counts": dict(sorted(status_counts.items())),
            "closure_class_counts": dict(sorted(class_counts.items())),
            "missing_inputs": missing_inputs,
            "recommended_next_action": recommended_next_action,
        },
        "closure_rows": closure_rows,
        "source_evidence": {
            "cut_model_planner_summary": planner_summary,
            "probe_evidence_summary": probe_summary,
            "current_best_summary": current_best_summary,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "safe_cut_ready_now": False,
            "matrix_candidate_rows_ready": bool(reviewable_rows),
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "All non-floor sidecar probes have evidence and none produced a safe cut "
                "or matrix-eligible row; the dedicated mana route has no currently "
                "eligible exact pair."
            )
            if report_status == "non_floor_probe_evidence_closure_closed_no_matrix_rows_keep_607"
            else "Non-floor probe evidence still requires repair or matrix-only review before any deck action.",
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_run_battle_without_a_materializable_candidate_contract",
                "do_not_convert reviewable probes directly into cuts",
                recommended_next_action,
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Non-Floor Probe Evidence Closure",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Planner named probes: `{summary_row.get('planner_named_probe_count')}`",
        f"- Non-floor probes: `{summary_row.get('non_floor_probe_count')}`",
        f"- Missing probe evidence rows: `{summary_row.get('missing_probe_evidence_row_count')}`",
        f"- Safe-cut ready: `{summary_row.get('non_floor_safe_cut_ready_count')}`",
        f"- Matrix candidate rows eligible: `{summary_row.get('non_floor_matrix_candidate_row_eligible_count')}`",
        f"- Natural battle gate allowed now: `{str(summary_row.get('natural_battle_gate_allowed_now')).lower()}`",
        f"- Mana route status: `{summary_row.get('mana_route_status')}`",
        f"- Mana model exact rejected pairs: `{summary_row.get('mana_model_exact_rejected_pair_count')}`",
        f"- Mana model eligible pairs: `{summary_row.get('mana_model_eligible_pair_count')}`",
        f"- Recommended next action: `{summary_row.get('recommended_next_action')}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Closure Summary", ""])
    lines.append(
        f"- status_counts: `{json.dumps(summary_row.get('status_counts') or {}, sort_keys=True)}`"
    )
    lines.append(
        f"- closure_class_counts: `{json.dumps(summary_row.get('closure_class_counts') or {}, sort_keys=True)}`"
    )
    lines.extend(["", "## Non-Floor Closure Rows", ""])
    lines.append("| Add | Probe cut | Target | Closure | Evidence status | Safe cut | Matrix row |")
    lines.append("| --- | --- | --- | --- | --- | ---: | ---: |")
    for row in as_list(payload.get("closure_rows")):
        if not row.get("included_in_non_floor_closure"):
            continue
        lines.append(
            "| {add} | `{cut}` | `{target}` | `{closure}` | `{status}` | `{safe}` | `{matrix}` |".format(
                add=row.get("add_card") or "",
                cut=row.get("cut_card") or "",
                target=row.get("target_tag") or "",
                closure=row.get("closure_class") or "",
                status=row.get("evidence_status") or "",
                safe=str(bool(row.get("safe_cut_ready_now"))).lower(),
                matrix=str(bool(row.get("matrix_candidate_row_eligible_now"))).lower(),
            )
        )
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision.get('keep_607_as_protected_baseline')).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision.get('deck_action_allowed')).lower()}`")
    lines.append(f"- safe_cut_ready_now: `{str(decision.get('safe_cut_ready_now')).lower()}`")
    lines.append(f"- matrix_candidate_rows_ready: `{str(decision.get('matrix_candidate_rows_ready')).lower()}`")
    lines.append(f"- candidate_deck_materialization_allowed_now: `{str(decision.get('candidate_deck_materialization_allowed_now')).lower()}`")
    lines.append(f"- forced_access_allowed_now: `{str(decision.get('forced_access_allowed_now')).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision.get('natural_battle_allowed_now')).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision.get('promotion_allowed')).lower()}`")
    lines.append(f"- reason: {decision.get('reason')}")
    lines.append("- next_actions:")
    for action in as_list(decision.get("next_actions")):
        lines.append(f"  - {action}")
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
    parser.add_argument("--cut-model-planner", type=Path, default=DEFAULT_CUT_MODEL_PLANNER)
    parser.add_argument("--probe-evidence", type=Path, default=DEFAULT_PROBE_EVIDENCE)
    parser.add_argument("--current-best", type=Path, default=DEFAULT_CURRENT_BEST)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "current_best": args.current_best,
        "cut_model_planner": args.cut_model_planner,
        "probe_evidence": args.probe_evidence,
    }
    payload = build_report(
        cut_model_planner=read_json(args.cut_model_planner),
        probe_evidence=read_json(args.probe_evidence),
        current_best=read_json(args.current_best),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
