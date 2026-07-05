#!/usr/bin/env python3
"""Scout Lorehold topdeck and mana trace gaps before any new deck build.

This read-only scout exists after the named same-lane frontier closes with no
safe cut. It does not rank a challenger and it does not materialize a deck. It
only identifies places where the current evidence is insufficient: unprobed
floor-sensitive topdeck/draw/engine/finisher cut slots and mana pairs that are
already rejected or still diagnostic.
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

DEFAULT_FRONTIER = REPORT_DIR / "lorehold_named_same_lane_cut_frontier_20260705_current.json"
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_EXPOSURE_PROFILE = (
    REPORT_DIR / "lorehold_card_exposure_profile_20260704_role_tag_repair_deck607.json"
)
DEFAULT_PROBE_EVIDENCE = (
    REPORT_DIR / "lorehold_topdeck_sidecar_probe_evidence_miner_20260705_current.json"
)
DEFAULT_MANA_SAFE_MODEL = REPORT_DIR / "lorehold_mana_base_safe_cut_model_20260705_current.json"
DEFAULT_MANA_DECISION_INTEGRATOR = (
    REPORT_DIR / "lorehold_mana_base_decision_integrator_20260705_after_plateau_turbulent_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_topdeck_mana_trace_gap_scout_20260705_current"

TRACE_LANES = {
    "draw",
    "engine",
    "miracle_conversion_finisher",
    "topdeck_miracle_engine",
}
PROTECTED_CUT_POLICIES = {
    "no_generic_cut_same_lane_battle_proof_required",
    "protect_floor_same_role_upgrade_and_gate_required",
}
FLOOR_SENSITIVE_LANES = {
    "miracle_conversion_finisher",
    "topdeck_miracle_engine",
    "engine",
    "draw",
}
LOW_EXPOSURE_THRESHOLD = 80

REQUIRED_TRACE = [
    "named_add_and_named_cut_trace_before_structure_matrix",
    "candidate_loss_vs_607_floor_trace_for_cut_slot",
    "same_seed_same_opponent_no_miracle_or_topdeck_regression",
    "same_lane_or_package_equivalence_for_added_card",
    "no_deck_materialization_until_trace_gap_closes",
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


def value_rows(value_model: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [dict(row) for row in as_list(value_model.get("all_card_values")) if isinstance(row, Mapping)]


def exposure_index(exposure_profile: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(row.get("card_name") or ""): dict(row)
        for row in as_list(exposure_profile.get("card_profiles"))
        if isinstance(row, Mapping) and row.get("card_name")
    }


def topdeck_probe_index(
    frontier: Mapping[str, Any],
    probe_evidence: Mapping[str, Any],
) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for target in as_list(frontier.get("topdeck_frontier")):
        if not isinstance(target, Mapping):
            continue
        for probe in as_list(target.get("lowest_exposure_probe_cuts")):
            if not isinstance(probe, Mapping):
                continue
            card = str(probe.get("cut_card") or "")
            if not card:
                continue
            rows.setdefault(
                card,
                {
                    "card_name": card,
                    "probe_statuses": set(),
                    "blockers": set(),
                    "add_cards": set(),
                    "inferred_roles": set(),
                    "unique_exposure_count": as_int(probe.get("unique_exposure_count")),
                },
            )
            rows[card]["probe_statuses"].add(str(probe.get("evidence_status") or ""))
            rows[card]["blockers"].update(str(item) for item in as_list(probe.get("blockers")))
            rows[card]["add_cards"].add(str(target.get("add_card") or ""))
            rows[card]["inferred_roles"].add(str(probe.get("inferred_role") or ""))

    for row in as_list(probe_evidence.get("probe_evidence_rows")):
        if not isinstance(row, Mapping) or row.get("target_tag") != "topdeck_access_sidecar_primary":
            continue
        card = str(row.get("cut_card") or "")
        if not card:
            continue
        exposure = as_dict(row.get("exposure"))
        rows.setdefault(
            card,
            {
                "card_name": card,
                "probe_statuses": set(),
                "blockers": set(),
                "add_cards": set(),
                "inferred_roles": set(),
                "unique_exposure_count": as_int(exposure.get("unique_exposure_count")),
            },
        )
        rows[card]["probe_statuses"].add(str(row.get("evidence_status") or ""))
        rows[card]["blockers"].update(str(item) for item in as_list(row.get("blockers")))
        rows[card]["add_cards"].add(str(row.get("add_card") or ""))
        rows[card]["inferred_roles"].add(str(exposure.get("inferred_role") or ""))

    return {
        card: {
            **row,
            "probe_statuses": sorted(item for item in row["probe_statuses"] if item),
            "blockers": sorted(item for item in row["blockers"] if item),
            "add_cards": sorted(item for item in row["add_cards"] if item),
            "inferred_roles": sorted(item for item in row["inferred_roles"] if item),
        }
        for card, row in sorted(rows.items())
    }


def infer_role(row: Mapping[str, Any], probe: Mapping[str, Any] | None = None) -> str:
    if probe:
        roles = as_list(probe.get("inferred_roles"))
        if roles:
            return str(roles[0])
    lanes = set(str(lane) for lane in as_list(row.get("lanes")))
    if "miracle_conversion_finisher" in lanes:
        return "miracle_conversion_finisher"
    if "topdeck_miracle_engine" in lanes:
        return "topdeck_miracle_engine"
    if str(row.get("functional_tag") or "") == "engine" or "engine" in lanes:
        return "recursion_or_engine_floor"
    if str(row.get("functional_tag") or "") == "draw" or "draw" in lanes:
        return "draw_filter_value"
    return str(row.get("functional_tag") or "unknown")


def is_trace_lane(row: Mapping[str, Any]) -> bool:
    lanes = set(str(lane) for lane in as_list(row.get("lanes")))
    return bool(lanes & TRACE_LANES)


def row_exposure(card_name: str, exposures: Mapping[str, Mapping[str, Any]]) -> dict[str, int]:
    row = exposures.get(card_name, {})
    return {
        "unique_exposure_count": as_int(row.get("unique_exposure_count")),
        "direct_event_count": as_int(row.get("direct_event_count")),
        "source_file_count": as_int(row.get("source_file_count")),
    }


def trace_gap_blockers(
    *,
    row: Mapping[str, Any],
    exposure: Mapping[str, int],
    probed: bool,
) -> list[str]:
    blockers: list[str] = []
    lanes = set(str(lane) for lane in as_list(row.get("lanes")))
    cut_policy = str(row.get("cut_policy") or "")
    if not probed:
        blockers.append("not_in_current_named_probe_frontier")
    if exposure.get("unique_exposure_count", 0) > 0:
        blockers.append("cut_card_has_material_exposure")
    if lanes & FLOOR_SENSITIVE_LANES:
        blockers.append("floor_sensitive_lane_unknown")
    if "miracle_conversion_finisher" in lanes:
        blockers.append("miracle_conversion_finisher_floor_unknown")
    if "topdeck_miracle_engine" in lanes:
        blockers.append("topdeck_engine_floor_unknown")
    if str(row.get("functional_tag") or "") == "draw" or "draw" in lanes:
        blockers.append("draw_filter_floor_unknown")
    if str(row.get("functional_tag") or "") == "engine" or "engine" in lanes:
        blockers.append("engine_or_recursion_floor_unknown")
    if cut_policy:
        blockers.append(cut_policy)
    blockers.append("not_safe_cut_ready")
    return list(dict.fromkeys(blockers))


def topdeck_trace_gap_rows(
    *,
    value_model: Mapping[str, Any],
    exposure_profile: Mapping[str, Any],
    frontier: Mapping[str, Any],
    probe_evidence: Mapping[str, Any],
) -> list[dict[str, Any]]:
    exposures = exposure_index(exposure_profile)
    probes = topdeck_probe_index(frontier, probe_evidence)
    rows: list[dict[str, Any]] = []
    for value_row in value_rows(value_model):
        card_name = str(value_row.get("card_name") or "")
        if not card_name or not is_trace_lane(value_row):
            continue
        exposure = row_exposure(card_name, exposures)
        lanes = [str(lane) for lane in as_list(value_row.get("lanes"))]
        protected_anchor = bool(value_row.get("protected_anchor"))
        cut_policy = str(value_row.get("cut_policy") or "")
        probe = probes.get(card_name)
        probed = bool(probe)
        low_exposure = exposure["unique_exposure_count"] <= LOW_EXPOSURE_THRESHOLD
        floor_sensitive = bool(set(lanes) & FLOOR_SENSITIVE_LANES)
        if protected_anchor or cut_policy in PROTECTED_CUT_POLICIES:
            gap_status = "protected_or_structural_floor_not_a_cut_gap"
        elif probed:
            gap_status = "already_probed_blocked"
        elif low_exposure and floor_sensitive:
            gap_status = "unprobed_low_exposure_floor_sensitive_trace_gap"
        elif floor_sensitive:
            gap_status = "unprobed_floor_sensitive_trace_gap"
        else:
            gap_status = "unprobed_context_gap"
        if gap_status == "protected_or_structural_floor_not_a_cut_gap" and not probed:
            continue
        blockers = list(as_list(probe.get("blockers"))) if probe else trace_gap_blockers(
            row=value_row,
            exposure=exposure,
            probed=probed,
        )
        rows.append(
            {
                "card_name": card_name,
                **exposure,
                "functional_tag": value_row.get("functional_tag") or "",
                "lanes": lanes,
                "value_tier": value_row.get("value_tier") or "",
                "value_score": as_int(value_row.get("value_score")),
                "cut_policy": cut_policy,
                "protected_anchor": protected_anchor,
                "role": infer_role(value_row, probe),
                "gap_status": gap_status,
                "already_probed_against_add_cards": as_list(probe.get("add_cards")) if probe else [],
                "blockers": blockers,
                "required_trace": REQUIRED_TRACE,
            }
        )
    rows.sort(
        key=lambda row: (
            0 if str(row["gap_status"]).startswith("unprobed_low_exposure") else 1,
            as_int(row.get("unique_exposure_count")),
            -as_int(row.get("value_score")),
            str(row.get("card_name")),
        )
    )
    return rows


def mana_gap_report(
    *,
    mana_safe_model: Mapping[str, Any],
    mana_decision_integrator: Mapping[str, Any],
) -> dict[str, Any]:
    ready_pairs = [
        dict(row)
        for row in as_list(mana_safe_model.get("top_model_ready_pairs"))
        if isinstance(row, Mapping)
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
    exact_rejected = [
        row for row in annotated_pairs if row.get("learning_status") == "blocked_exact_tested_decision"
    ]
    rejected_signatures = {(row.get("add"), row.get("cut")) for row in exact_rejected}
    remaining_ready = [
        row for row in ready_pairs if (row.get("add"), row.get("cut")) not in rejected_signatures
    ]
    diagnostic_rows = [
        dict(row)
        for row in as_list(mana_safe_model.get("top_diagnostic_pairs"))[:12]
        if isinstance(row, Mapping)
    ]
    status_counts = Counter(str(row.get("status") or "") for row in diagnostic_rows)
    return {
        "frontier_status": (
            "mana_trace_gap_has_eligible_pair"
            if eligible_pairs
            else (
                "mana_route_closed_by_exact_decisions"
                if exact_rejected and not remaining_ready
                else "mana_route_requires_distinct_trace_evidence"
            )
        ),
        "safe_model_ready_pair_count": len(ready_pairs),
        "remaining_ready_pair_count_after_exact_reject_filter": len(remaining_ready),
        "eligible_pair_count": len(eligible_pairs),
        "exact_rejected_pair_count": len(exact_rejected),
        "exact_rejected_pairs": exact_rejected,
        "remaining_ready_pairs": remaining_ready,
        "diagnostic_pair_count": as_int(summary(mana_safe_model).get("diagnostic_pair_count")),
        "diagnostic_status_counts_sample": dict(sorted(status_counts.items())),
        "diagnostic_pair_examples": diagnostic_rows,
        "required_trace": [
            "distinct_add_cut_pair_not_exact_rejected",
            "same_color_source_count_preserved",
            "typed_fetch_target_or_topdeck_land_utility_preserved",
            "same_seed_no_mana_regression_trace",
            "natural_gate_stays_closed_until_structure_contract_exists",
        ],
    }


def missing_inputs(payloads: Mapping[str, Mapping[str, Any]]) -> list[str]:
    return [key for key, payload in payloads.items() if not payload]


def build_report(
    *,
    frontier: Mapping[str, Any],
    value_model: Mapping[str, Any],
    exposure_profile: Mapping[str, Any],
    probe_evidence: Mapping[str, Any],
    mana_safe_model: Mapping[str, Any],
    mana_decision_integrator: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    payloads = {
        "frontier": frontier,
        "value_model": value_model,
        "exposure_profile": exposure_profile,
        "probe_evidence": probe_evidence,
        "mana_safe_model": mana_safe_model,
        "mana_decision_integrator": mana_decision_integrator,
    }
    missing = missing_inputs(payloads)
    trace_rows = [] if missing else topdeck_trace_gap_rows(
        value_model=value_model,
        exposure_profile=exposure_profile,
        frontier=frontier,
        probe_evidence=probe_evidence,
    )
    mana = (
        {
            "frontier_status": "inputs_missing",
            "safe_model_ready_pair_count": 0,
            "remaining_ready_pair_count_after_exact_reject_filter": 0,
            "eligible_pair_count": 0,
            "exact_rejected_pair_count": 0,
            "exact_rejected_pairs": [],
            "remaining_ready_pairs": [],
            "diagnostic_pair_count": 0,
            "diagnostic_status_counts_sample": {},
            "diagnostic_pair_examples": [],
            "required_trace": [],
        }
        if missing
        else mana_gap_report(
            mana_safe_model=mana_safe_model,
            mana_decision_integrator=mana_decision_integrator,
        )
    )
    unprobed_rows = [row for row in trace_rows if str(row["gap_status"]).startswith("unprobed")]
    floor_sensitive_rows = [
        row
        for row in trace_rows
        if "floor_sensitive_lane_unknown" in as_list(row.get("blockers"))
        or str(row["gap_status"]).startswith("unprobed")
    ]
    already_probed_rows = [row for row in trace_rows if row["gap_status"] == "already_probed_blocked"]
    if missing:
        status = "topdeck_mana_trace_gap_scout_inputs_missing_keep_607"
        next_action = "rerun_missing_trace_gap_inputs"
    elif unprobed_rows:
        status = "topdeck_mana_trace_gap_scout_found_unprobed_floor_sensitive_gaps_keep_607"
        next_action = "collect_targeted_floor_traces_for_unprobed_gap_rows_before_structure_matrix"
    else:
        status = "topdeck_mana_trace_gap_scout_no_new_gap_keep_607"
        next_action = "keep_607_protected_until_new_trace_evidence_arrives"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_mana_trace_gap_scout",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": status,
            "value_model_card_count": len(value_rows(value_model)),
            "trace_gap_row_count": len(trace_rows),
            "unprobed_topdeck_gap_count": len(unprobed_rows),
            "floor_sensitive_gap_count": len(floor_sensitive_rows),
            "already_probed_topdeck_count": len(already_probed_rows),
            "mana_safe_model_ready_pair_count": as_int(mana.get("safe_model_ready_pair_count")),
            "mana_remaining_ready_pair_count_after_exact_reject_filter": as_int(
                mana.get("remaining_ready_pair_count_after_exact_reject_filter")
            ),
            "mana_eligible_pair_count": as_int(mana.get("eligible_pair_count")),
            "mana_exact_rejected_pair_count": as_int(mana.get("exact_rejected_pair_count")),
            "structure_matrix_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "missing_inputs": missing,
            "recommended_next_action": next_action,
        },
        "trace_gap_rows": trace_rows,
        "mana_trace_gap": mana,
        "external_research_context": as_list(value_model.get("external_research")),
        "source_evidence": {
            "frontier_summary": summary(frontier),
            "value_model_summary": summary(value_model),
            "exposure_profile_summary": summary(exposure_profile)
            or as_dict(exposure_profile.get("scan_summary")),
            "probe_evidence_summary": summary(probe_evidence),
            "mana_safe_model_summary": summary(mana_safe_model),
            "mana_decision_integrator_summary": summary(mana_decision_integrator),
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "structure_matrix_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "Unprobed floor-sensitive cut slots exist, so the next work is trace "
                "collection rather than a new deck, structure matrix, or battle gate."
            )
            if unprobed_rows
            else (
                "No unprobed floor-sensitive cut slot is visible in the current inputs, "
                "and mana remains closed unless a distinct pair gets new trace evidence."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_materialize_candidate_deck_from_trace_gap_rows",
                "collect candidate-loss-vs-607 floor traces for unprobed rows",
                "do_not_retest exact Plateau pairs without new mana evidence",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = summary(payload)
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Topdeck Mana Trace Gap Scout",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Trace gap rows: `{summary_row.get('trace_gap_row_count')}`",
        f"- Unprobed topdeck gaps: `{summary_row.get('unprobed_topdeck_gap_count')}`",
        f"- Floor-sensitive gaps: `{summary_row.get('floor_sensitive_gap_count')}`",
        f"- Already probed topdeck rows: `{summary_row.get('already_probed_topdeck_count')}`",
        f"- Mana eligible pairs: `{summary_row.get('mana_eligible_pair_count')}`",
        f"- Mana exact rejected pairs: `{summary_row.get('mana_exact_rejected_pair_count')}`",
        f"- Structure matrix allowed now: `{str(summary_row.get('structure_matrix_allowed_now')).lower()}`",
        "- Candidate deck materialization allowed now: "
        f"`{str(summary_row.get('candidate_deck_materialization_allowed_now')).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row.get('natural_battle_gate_allowed_now')).lower()}`",
        f"- Promotion allowed now: `{str(summary_row.get('promotion_allowed_now')).lower()}`",
        f"- Recommended next action: `{summary_row.get('recommended_next_action')}`",
        "",
        "## Trace Gap Rows",
        "",
        "| Card | Status | Exposure | Role | Value | Blockers |",
        "| --- | --- | ---: | --- | ---: | --- |",
    ]
    for row in as_list(payload.get("trace_gap_rows"))[:20]:
        blockers = ", ".join(str(item) for item in as_list(row.get("blockers"))[:4])
        lines.append(
            "| {card} | `{status}` | {exposure} | `{role}` | {value} | {blockers} |".format(
                card=row.get("card_name") or "",
                status=row.get("gap_status") or "",
                exposure=row.get("unique_exposure_count") or 0,
                role=row.get("role") or "",
                value=row.get("value_score") or 0,
                blockers=blockers,
            )
        )
    lines.extend(["", "## Mana Trace Gap", ""])
    mana = as_dict(payload.get("mana_trace_gap"))
    lines.append(f"- frontier_status: `{mana.get('frontier_status')}`")
    lines.append(f"- safe_model_ready_pair_count: `{mana.get('safe_model_ready_pair_count')}`")
    lines.append(
        "- remaining_ready_pair_count_after_exact_reject_filter: "
        f"`{mana.get('remaining_ready_pair_count_after_exact_reject_filter')}`"
    )
    lines.append(f"- eligible_pair_count: `{mana.get('eligible_pair_count')}`")
    lines.append(f"- exact_rejected_pair_count: `{mana.get('exact_rejected_pair_count')}`")
    if as_list(mana.get("exact_rejected_pairs")):
        lines.append("- exact_rejected_pairs:")
        for pair in as_list(mana.get("exact_rejected_pairs")):
            blockers = ", ".join(str(item) for item in as_list(pair.get("decision_blockers")))
            lines.append(
                f"  - `{pair.get('add')}` over `{pair.get('cut')}`: "
                f"`{pair.get('decision_status')}`; blockers: {blockers}"
            )
    lines.extend(["", "## External Research Context", ""])
    for row in as_list(payload.get("external_research_context")):
        if not isinstance(row, Mapping):
            continue
        lines.append(f"- `{row.get('source')}`: {row.get('learning')} ({row.get('url')})")
    lines.extend(["", "## Decision", ""])
    lines.append(
        f"- keep_607_as_protected_baseline: `{str(decision.get('keep_607_as_protected_baseline')).lower()}`"
    )
    lines.append(f"- deck_action_allowed: `{str(decision.get('deck_action_allowed')).lower()}`")
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
    parser.add_argument("--frontier", type=Path, default=DEFAULT_FRONTIER)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--exposure-profile", type=Path, default=DEFAULT_EXPOSURE_PROFILE)
    parser.add_argument("--probe-evidence", type=Path, default=DEFAULT_PROBE_EVIDENCE)
    parser.add_argument("--mana-safe-model", type=Path, default=DEFAULT_MANA_SAFE_MODEL)
    parser.add_argument("--mana-decision-integrator", type=Path, default=DEFAULT_MANA_DECISION_INTEGRATOR)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "frontier": args.frontier,
        "value_model": args.value_model,
        "exposure_profile": args.exposure_profile,
        "probe_evidence": args.probe_evidence,
        "mana_safe_model": args.mana_safe_model,
        "mana_decision_integrator": args.mana_decision_integrator,
    }
    payload = build_report(
        frontier=read_json(args.frontier),
        value_model=read_json(args.value_model),
        exposure_profile=read_json(args.exposure_profile),
        probe_evidence=read_json(args.probe_evidence),
        mana_safe_model=read_json(args.mana_safe_model),
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
