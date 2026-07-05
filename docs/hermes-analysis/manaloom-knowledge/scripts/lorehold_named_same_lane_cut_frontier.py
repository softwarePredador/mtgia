#!/usr/bin/env python3
"""Route Lorehold named same-lane cut evidence after sidecar probes.

The sidecar contract and probe miners now expose named add/cut probes, but a
named probe is not a safe cut. This read-only router consolidates the current
frontier: topdeck cuts, mana-base pairs, non-anchor cut status, and staple
policy. It decides whether any row can advance to a structure-matrix contract
without mutating deck 607 or materializing a deck.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_SIDECAR_CONTRACT = (
    REPORT_DIR / "lorehold_topdeck_access_first_sidecar_shell_contract_20260705_current.json"
)
DEFAULT_PROBE_EVIDENCE = (
    REPORT_DIR / "lorehold_topdeck_sidecar_probe_evidence_miner_20260705_current.json"
)
DEFAULT_NONANCHOR_CUT_MODEL = (
    REPORT_DIR / "lorehold_topdeck_nonanchor_cut_model_miner_20260705_current.json"
)
DEFAULT_MANA_DECISION_INTEGRATOR = (
    REPORT_DIR / "lorehold_mana_base_decision_integrator_20260705_after_plateau_turbulent_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_named_same_lane_cut_frontier_20260705_current"
)

TARGET_CONTRACT = "topdeck_access_first_sidecar_shell_contract"

STRUCTURE_MATRIX_REQUIREMENTS = [
    "named_add_and_named_cut_pair",
    "safe_cut_ready_now_or_eligible_mana_pair_after_decision_filter",
    "no_exact_prior_reject_for_the_add_cut_signature",
    "protected_607_anchor_not_cut_without_same_lane_battle_proof",
    "topdeck_miracle_or_mana_floor_equivalence_declared",
    "direct_trace_plan_for_added_card_and_cut_floor",
    "same_seed_equal_gate_stays_closed_until_structure_matrix_passes",
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


def missing_inputs(payloads: Mapping[str, Mapping[str, Any]]) -> list[str]:
    return [key for key, payload in payloads.items() if not payload]


def grouped_probe_rows(probe_evidence: Mapping[str, Any], target_tag: str) -> dict[str, list[dict[str, Any]]]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in as_list(probe_evidence.get("probe_evidence_rows")):
        if not isinstance(row, Mapping) or row.get("target_tag") != target_tag:
            continue
        grouped[str(row.get("add_card") or "")].append(dict(row))
    for rows in grouped.values():
        rows.sort(
            key=lambda row: (
                as_int(as_dict(row.get("exposure")).get("unique_exposure_count")),
                str(row.get("cut_card") or ""),
            )
        )
    return dict(sorted(grouped.items()))


def topdeck_frontier_rows(probe_evidence: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for add_card, probes in grouped_probe_rows(
        probe_evidence, "topdeck_access_sidecar_primary"
    ).items():
        status_counts = Counter(str(row.get("evidence_status") or "") for row in probes)
        blocker_counts = Counter(
            blocker for row in probes for blocker in as_list(row.get("blockers"))
        )
        matrix_ready = [
            row
            for row in probes
            if row.get("safe_cut_ready_now") or row.get("matrix_candidate_row_eligible_now")
        ]
        rows.append(
            {
                "add_card": add_card,
                "probe_count": len(probes),
                "matrix_ready_probe_count": len(matrix_ready),
                "status_counts": dict(sorted(status_counts.items())),
                "blocker_counts": dict(sorted(blocker_counts.items())),
                "lowest_exposure_probe_cuts": [
                    {
                        "cut_card": row.get("cut_card") or "",
                        "evidence_status": row.get("evidence_status") or "",
                        "unique_exposure_count": as_int(
                            as_dict(row.get("exposure")).get("unique_exposure_count")
                        ),
                        "inferred_role": as_dict(row.get("exposure")).get("inferred_role")
                        or "",
                        "blockers": as_list(row.get("blockers"))[:6],
                    }
                    for row in probes[:4]
                ],
                "frontier_status": (
                    "structure_contract_candidate_requires_review"
                    if matrix_ready
                    else "blocked_exposed_or_floor_sensitive_topdeck_cuts"
                ),
                "next_action": (
                    "feed_safe_cut_probe_to_structure_contract"
                    if matrix_ready
                    else "collect_new_low_exposure_cut_or_floor_trace_before_matrix"
                ),
            }
        )
    return rows


def nonanchor_index(nonanchor_cut_model: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(row.get("card_name") or ""): dict(row)
        for row in as_list(nonanchor_cut_model.get("target_cut_models"))
        if isinstance(row, Mapping) and row.get("card_name")
    }


def annotate_topdeck_with_nonanchor(
    rows: list[dict[str, Any]],
    nonanchor_cut_model: Mapping[str, Any],
) -> list[dict[str, Any]]:
    index = nonanchor_index(nonanchor_cut_model)
    out: list[dict[str, Any]] = []
    for row in rows:
        model = index.get(str(row.get("add_card") or ""), {})
        out.append(
            {
                **row,
                "nonanchor_model_status": model.get("model_status") or "",
                "nonanchor_same_lane_slot_count": as_int(model.get("same_lane_slot_count")),
                "nonanchor_seed_safe_count": as_int(model.get("seed_safe_nonanchor_count")),
                "nonanchor_reviewable_gap_count": as_int(
                    model.get("reviewable_nonanchor_gap_count")
                ),
                "prior_reject_count": as_int(model.get("prior_reject_count")),
            }
        )
    return out


def mana_frontier(
    *,
    probe_evidence: Mapping[str, Any],
    mana_decision_integrator: Mapping[str, Any],
) -> dict[str, Any]:
    generic_probe_rows = [
        row
        for rows in grouped_probe_rows(probe_evidence, "mana_base_safe_cut_model").values()
        for row in rows
    ]
    annotated_pairs = [
        dict(row)
        for row in as_list(mana_decision_integrator.get("annotated_model_ready_pairs"))
        if isinstance(row, Mapping)
    ]
    eligible_pairs = [
        row
        for row in annotated_pairs
        if row.get("learning_status") == "eligible_for_materialization_after_prior_decision_filter"
    ]
    rejected_pairs = [
        row for row in annotated_pairs if row.get("learning_status") == "blocked_exact_tested_decision"
    ]
    return {
        "generic_probe_count": len(generic_probe_rows),
        "generic_probe_status_counts": dict(
            sorted(Counter(str(row.get("evidence_status") or "") for row in generic_probe_rows).items())
        ),
        "annotated_model_ready_pair_count": len(annotated_pairs),
        "eligible_pair_count": len(eligible_pairs),
        "exact_rejected_pair_count": len(rejected_pairs),
        "eligible_pairs": eligible_pairs[:8],
        "exact_rejected_pairs": rejected_pairs[:8],
        "frontier_status": (
            "eligible_mana_pair_requires_structure_contract"
            if eligible_pairs
            else (
                "mana_route_closed_by_exact_decisions"
                if rejected_pairs
                else "generic_mana_probes_blocked_by_floor_equivalence"
            )
        ),
        "next_action": (
            "write_structure_contract_for_eligible_mana_pair_no_battle"
            if eligible_pairs
            else "do_not_retest_exact_plateau_pairs_without_new_mana_trace_evidence"
        ),
    }


def blocked_staples(sidecar_contract: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        dict(row)
        for row in as_list(as_dict(sidecar_contract.get("contract")).get("blocked_staple_policy"))
        if isinstance(row, Mapping)
    ]


def build_report(
    *,
    sidecar_contract: Mapping[str, Any],
    probe_evidence: Mapping[str, Any],
    nonanchor_cut_model: Mapping[str, Any],
    mana_decision_integrator: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    payloads = {
        "sidecar_contract": sidecar_contract,
        "probe_evidence": probe_evidence,
        "nonanchor_cut_model": nonanchor_cut_model,
        "mana_decision_integrator": mana_decision_integrator,
    }
    missing = missing_inputs(payloads)
    topdeck_rows = (
        []
        if missing
        else annotate_topdeck_with_nonanchor(topdeck_frontier_rows(probe_evidence), nonanchor_cut_model)
    )
    mana = (
        {
            "generic_probe_count": 0,
            "annotated_model_ready_pair_count": 0,
            "eligible_pair_count": 0,
            "exact_rejected_pair_count": 0,
            "frontier_status": "inputs_missing",
            "next_action": "rerun_missing_frontier_inputs",
            "eligible_pairs": [],
            "exact_rejected_pairs": [],
        }
        if missing
        else mana_frontier(
            probe_evidence=probe_evidence,
            mana_decision_integrator=mana_decision_integrator,
        )
    )
    topdeck_matrix_ready = sum(as_int(row.get("matrix_ready_probe_count")) for row in topdeck_rows)
    mana_matrix_ready = as_int(mana.get("eligible_pair_count"))
    structure_contract_allowed = bool(topdeck_matrix_ready or mana_matrix_ready) and not missing
    if missing:
        status = "named_same_lane_cut_frontier_inputs_missing_keep_607"
        next_action = "rerun_missing_named_cut_frontier_inputs"
    elif structure_contract_allowed:
        status = "named_same_lane_cut_frontier_has_structure_contract_rows_no_deck"
        next_action = "write_structure_matrix_contract_for_frontier_rows_no_battle"
    else:
        status = "named_same_lane_cut_frontier_closed_no_safe_cut_keep_607"
        next_action = "collect_new_topdeck_floor_or_mana_trace_evidence_before_structure_matrix"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_named_same_lane_cut_frontier",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": status,
            "contract_key": summary(sidecar_contract).get("contract_key") or "",
            "contract_status": summary(sidecar_contract).get("decision_status") or "",
            "probe_row_count": as_int(summary(probe_evidence).get("probe_row_count")),
            "topdeck_frontier_target_count": len(topdeck_rows),
            "topdeck_matrix_ready_probe_count": topdeck_matrix_ready,
            "mana_generic_probe_count": as_int(mana.get("generic_probe_count")),
            "mana_eligible_pair_count": mana_matrix_ready,
            "mana_exact_rejected_pair_count": as_int(mana.get("exact_rejected_pair_count")),
            "blocked_staple_count": len(blocked_staples(sidecar_contract)),
            "structure_matrix_contract_allowed_now": structure_contract_allowed,
            "structure_matrix_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "missing_inputs": missing,
            "recommended_next_action": next_action,
        },
        "structure_matrix_requirements": STRUCTURE_MATRIX_REQUIREMENTS,
        "topdeck_frontier": topdeck_rows,
        "mana_frontier": mana,
        "blocked_staple_policy": blocked_staples(sidecar_contract),
        "source_evidence": {
            "sidecar_contract_summary": summary(sidecar_contract),
            "probe_evidence_summary": summary(probe_evidence),
            "nonanchor_cut_model_summary": summary(nonanchor_cut_model),
            "mana_decision_integrator_summary": summary(mana_decision_integrator),
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "structure_matrix_contract_allowed_now": structure_contract_allowed,
            "structure_matrix_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "At least one named same-lane row can be routed into a structure contract, "
                "but deck materialization and battle remain closed."
            )
            if structure_contract_allowed
            else (
                "All current named same-lane topdeck and mana cut probes are blocked by "
                "material exposure, mana-floor risk, non-anchor cut absence, or exact "
                "rejected Plateau pair evidence."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_materialize_decks_from_review_only_cut_probes",
                "do_not_retest_exact_plateau_pairs_without_new_mana_trace_evidence",
                "collect new low-exposure topdeck cut evidence or a distinct mana trace before structure matrix",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Named Same-Lane Cut Frontier",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Probe rows: `{summary_row.get('probe_row_count')}`",
        f"- Topdeck frontier targets: `{summary_row.get('topdeck_frontier_target_count')}`",
        f"- Topdeck matrix-ready probes: `{summary_row.get('topdeck_matrix_ready_probe_count')}`",
        f"- Mana generic probes: `{summary_row.get('mana_generic_probe_count')}`",
        f"- Mana eligible pairs: `{summary_row.get('mana_eligible_pair_count')}`",
        f"- Mana exact rejected pairs: `{summary_row.get('mana_exact_rejected_pair_count')}`",
        f"- Structure matrix contract allowed now: `{str(summary_row.get('structure_matrix_contract_allowed_now')).lower()}`",
        f"- Candidate deck materialization allowed now: `{str(summary_row.get('candidate_deck_materialization_allowed_now')).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row.get('natural_battle_gate_allowed_now')).lower()}`",
        f"- Promotion allowed now: `{str(summary_row.get('promotion_allowed_now')).lower()}`",
        f"- Recommended next action: `{summary_row.get('recommended_next_action')}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Structure Matrix Requirements", ""])
    for requirement in as_list(payload.get("structure_matrix_requirements")):
        lines.append(f"- `{requirement}`")
    lines.extend(["", "## Topdeck Frontier", ""])
    lines.append("| Add | Status | Non-anchor status | Ready | Lowest-exposure probe cuts |")
    lines.append("| --- | --- | --- | ---: | --- |")
    for row in as_list(payload.get("topdeck_frontier")):
        cuts = ", ".join(
            f"{probe.get('cut_card')} ({probe.get('unique_exposure_count')})"
            for probe in as_list(row.get("lowest_exposure_probe_cuts"))[:3]
        )
        lines.append(
            "| {add} | `{status}` | `{nonanchor}` | `{ready}` | {cuts} |".format(
                add=row.get("add_card") or "",
                status=row.get("frontier_status") or "",
                nonanchor=row.get("nonanchor_model_status") or "",
                ready=row.get("matrix_ready_probe_count") or 0,
                cuts=cuts,
            )
        )
    lines.extend(["", "## Mana Frontier", ""])
    mana = as_dict(payload.get("mana_frontier"))
    lines.append(f"- frontier_status: `{mana.get('frontier_status')}`")
    lines.append(f"- generic_probe_count: `{mana.get('generic_probe_count')}`")
    lines.append(f"- eligible_pair_count: `{mana.get('eligible_pair_count')}`")
    lines.append(f"- exact_rejected_pair_count: `{mana.get('exact_rejected_pair_count')}`")
    if as_list(mana.get("exact_rejected_pairs")):
        lines.append("- exact_rejected_pairs:")
        for pair in as_list(mana.get("exact_rejected_pairs")):
            lines.append(
                f"  - `{pair.get('add')}` over `{pair.get('cut')}`: `{pair.get('decision_status')}`"
            )
    lines.extend(["", "## Blocked Staples", ""])
    for row in as_list(payload.get("blocked_staple_policy")):
        lines.append(
            f"- `{row.get('card')}` in `{row.get('lane')}`: `{row.get('current_policy')}`"
        )
    lines.extend(["", "## Decision", ""])
    lines.append(
        f"- keep_607_as_protected_baseline: `{str(decision.get('keep_607_as_protected_baseline')).lower()}`"
    )
    lines.append(f"- deck_action_allowed: `{str(decision.get('deck_action_allowed')).lower()}`")
    lines.append(
        "- structure_matrix_contract_allowed_now: "
        f"`{str(decision.get('structure_matrix_contract_allowed_now')).lower()}`"
    )
    lines.append(
        "- candidate_deck_materialization_allowed_now: "
        f"`{str(decision.get('candidate_deck_materialization_allowed_now')).lower()}`"
    )
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
    parser.add_argument("--sidecar-contract", type=Path, default=DEFAULT_SIDECAR_CONTRACT)
    parser.add_argument("--probe-evidence", type=Path, default=DEFAULT_PROBE_EVIDENCE)
    parser.add_argument("--nonanchor-cut-model", type=Path, default=DEFAULT_NONANCHOR_CUT_MODEL)
    parser.add_argument("--mana-decision-integrator", type=Path, default=DEFAULT_MANA_DECISION_INTEGRATOR)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "sidecar_contract": args.sidecar_contract,
        "probe_evidence": args.probe_evidence,
        "nonanchor_cut_model": args.nonanchor_cut_model,
        "mana_decision_integrator": args.mana_decision_integrator,
    }
    payload = build_report(
        sidecar_contract=read_json(args.sidecar_contract),
        probe_evidence=read_json(args.probe_evidence),
        nonanchor_cut_model=read_json(args.nonanchor_cut_model),
        mana_decision_integrator=read_json(args.mana_decision_integrator),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
