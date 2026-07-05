#!/usr/bin/env python3
"""Plan named cut-model probes for Lorehold sidecar rows.

The sidecar candidate queue found no matrix-eligible rows because every row
lacks a named same-lane cut. This read-only planner proposes review probes from
the current deck 607 value model for the topdeck and mana rows only. A probe is
not a safe cut; it is a named row that tells the next miner which evidence must
be collected before the structure matrix can score a sidecar candidate.
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

DEFAULT_SIDECAR_QUEUE = (
    REPORT_DIR / "lorehold_topdeck_sidecar_candidate_queue_20260705_current.json"
)
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_SAFE_CUT_MINER = REPORT_DIR / "lorehold_topdeck_safe_cut_miner_20260705_current.json"
DEFAULT_GAP_FLOOR_TRACE_MINER = (
    REPORT_DIR / "lorehold_gap_floor_trace_miner_20260705_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_topdeck_sidecar_cut_model_planner_20260705_current"

TARGET_TAGS = {
    "topdeck_access_sidecar_primary",
    "mana_base_safe_cut_model",
}

TAG_CUT_LANES = {
    "topdeck_access_sidecar_primary": {"topdeck_miracle_engine", "draw", "engine"},
    "mana_base_safe_cut_model": {"land", "mana_base"},
}

TARGET_TAG_LIMIT = {
    "topdeck_access_sidecar_primary": 5,
    "mana_base_safe_cut_model": 7,
}


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


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def current_value_rows(value_model: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [dict(row) for row in as_list(value_model.get("all_card_values")) if isinstance(row, Mapping)]
    rows.sort(key=lambda row: (as_int(row.get("value_score")), str(row.get("card_name") or "")))
    return rows


def attempted_package_cuts(safe_cut_miner: Mapping[str, Any]) -> set[str]:
    names: set[str] = set()
    for target in as_list(safe_cut_miner.get("target_cut_assessments")):
        if not isinstance(target, Mapping):
            continue
        for cut in as_list(target.get("attempted_package_cuts")):
            if isinstance(cut, Mapping) and cut.get("cut"):
                names.add(normalize_name(cut["cut"]))
    return names


def compact_floor_trace_summary(row: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "card_name": row.get("card_name") or "",
        "floor_trace_status": row.get("floor_trace_status") or "",
        "cut_decision": row.get("cut_decision") or "",
        "same_slot_607_win_candidate_loss_trace_count": as_int(
            row.get("same_slot_607_win_candidate_loss_trace_count")
        ),
        "positive_target_delta_trace_count": as_int(row.get("positive_target_delta_trace_count")),
        "baseline_target_event_total": as_int(row.get("baseline_target_event_total")),
    }


def floor_trace_cut_blockers(gap_floor_trace_miner: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    blockers: dict[str, dict[str, Any]] = {}
    for row in as_list(gap_floor_trace_miner.get("target_floor_summaries")):
        if not isinstance(row, Mapping):
            continue
        name = normalize_name(row.get("card_name"))
        if not name:
            continue
        if row.get("floor_trace_status") != "floor_trace_found_cut_blocked":
            continue
        if row.get("cut_decision") != "protect_cut_slot_until_same_lane_replacement_preserves_floor":
            continue
        blockers[name] = compact_floor_trace_summary(row)
    return blockers


def target_queue_rows(sidecar_queue: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [dict(row) for row in as_list(sidecar_queue.get("candidate_queue")) if isinstance(row, Mapping)]
    selected: list[dict[str, Any]] = []
    counts: Counter[str] = Counter()
    for row in rows:
        tag = str(row.get("sidecar_tag") or "")
        if tag not in TARGET_TAGS:
            continue
        if counts[tag] >= TARGET_TAG_LIMIT.get(tag, 99):
            continue
        selected.append(row)
        counts[tag] += 1
    selected.sort(key=lambda row: (str(row.get("sidecar_tag") or ""), str(row.get("add_card") or "")))
    return selected


def cut_row_matches_target(cut_row: Mapping[str, Any], target_tag: str) -> bool:
    cut_lanes = {str(lane) for lane in as_list(cut_row.get("lanes"))}
    functional_tag = str(cut_row.get("functional_tag") or "")
    target_lanes = TAG_CUT_LANES.get(target_tag, set())
    if target_tag == "mana_base_safe_cut_model":
        return functional_tag == "land" or bool(cut_lanes & target_lanes)
    if target_tag == "topdeck_access_sidecar_primary":
        return functional_tag in {"draw", "engine"} or bool(cut_lanes & target_lanes)
    return False


def probe_blockers(
    cut_row: Mapping[str, Any],
    target_tag: str,
    attempted_cuts: set[str],
    floor_trace_blockers: Mapping[str, Mapping[str, Any]],
) -> list[str]:
    blockers = [
        "safe_cut_miner_zero_current_ready",
        "requires_exposure_trace_before_safe_cut",
    ]
    name = normalize_name(cut_row.get("card_name"))
    policy = str(cut_row.get("cut_policy") or "")
    tier = str(cut_row.get("value_tier") or "")
    if cut_row.get("protected_anchor"):
        blockers.append("protected_anchor_do_not_cut")
    if name in attempted_cuts:
        blockers.append("prior_attempt_or_blocked_package_cut")
    if name in floor_trace_blockers:
        blockers.append("floor_trace_cut_blocked")
        blockers.append("requires_same_lane_replacement_floor_preservation")
    if policy.startswith("no_generic_cut"):
        blockers.append("no_generic_cut_policy")
    if "protect_floor" in policy or tier == "tier_1_structural_floor":
        blockers.append("structural_floor_equivalence_required")
    if target_tag == "mana_base_safe_cut_model":
        blockers.append("mana_source_floor_equivalence_required")
    if target_tag == "topdeck_access_sidecar_primary":
        blockers.append("miracle_topdeck_floor_equivalence_required")
    if as_int(cut_row.get("value_score")) >= 80:
        blockers.append("high_value_anchor_risk")
    return sorted(set(blockers))


def cut_probe(
    *,
    queue_row: Mapping[str, Any],
    cut_row: Mapping[str, Any],
    attempted_cuts: set[str],
    floor_trace_blockers: Mapping[str, Mapping[str, Any]],
) -> dict[str, Any]:
    target_tag = str(queue_row.get("sidecar_tag") or "")
    normalized_cut = normalize_name(cut_row.get("card_name"))
    floor_trace_summary = as_dict(floor_trace_blockers.get(normalized_cut))
    blockers = probe_blockers(cut_row, target_tag, attempted_cuts, floor_trace_blockers)
    return {
        "add_card": queue_row.get("add_card") or "",
        "cut_card": cut_row.get("card_name") or "",
        "target_tag": target_tag,
        "cut_lanes": as_list(cut_row.get("lanes")),
        "cut_functional_tag": cut_row.get("functional_tag") or "",
        "cut_value_tier": cut_row.get("value_tier") or "",
        "cut_value_score": as_int(cut_row.get("value_score")),
        "cut_policy": cut_row.get("cut_policy") or "",
        "protected_anchor": bool(cut_row.get("protected_anchor")),
        "attempted_or_prior_blocked": normalize_name(cut_row.get("card_name")) in attempted_cuts,
        "floor_trace_blocked": bool(floor_trace_summary),
        "floor_trace_summary": floor_trace_summary,
        "probe_status": "review_only_not_safe",
        "matrix_candidate_row_eligible_now": False,
        "cut_usable_now": False,
        "blockers": blockers,
        "required_evidence": required_evidence(target_tag),
    }


def required_evidence(target_tag: str) -> list[str]:
    if target_tag == "mana_base_safe_cut_model":
        return [
            "same_color_source_count_preserved",
            "untapped_or_fetchable_role_preserved",
            "land_count_floor_preserved",
            "same_seed_no_mana_regression_trace",
        ]
    return [
        "candidate_add_drawn_cast_or_activated",
        "cut_card_low_exposure_or_redundant_trace",
        "miracle_cast_floor_preserved",
        "topdeck_manipulation_floor_preserved",
    ]


def target_probe_row(
    *,
    queue_row: Mapping[str, Any],
    value_rows: list[Mapping[str, Any]],
    attempted_cuts: set[str],
    floor_trace_blockers: Mapping[str, Mapping[str, Any]],
    probes_per_target: int,
) -> dict[str, Any]:
    tag = str(queue_row.get("sidecar_tag") or "")
    matching = [row for row in value_rows if cut_row_matches_target(row, tag)]
    protected_near_misses = [
        {
            "card_name": row.get("card_name") or "",
            "value_score": as_int(row.get("value_score")),
            "reason": "protected_anchor_or_high_value_floor",
        }
        for row in matching
        if row.get("protected_anchor") or as_int(row.get("value_score")) >= 80
    ][:5]
    non_protected = [row for row in matching if not row.get("protected_anchor")]
    non_protected.sort(
        key=lambda row: (
            normalize_name(row.get("card_name")) in attempted_cuts,
            as_int(row.get("value_score")),
            str(row.get("card_name") or ""),
        )
    )
    probes = [
        cut_probe(
            queue_row=queue_row,
            cut_row=row,
            attempted_cuts=attempted_cuts,
            floor_trace_blockers=floor_trace_blockers,
        )
        for row in non_protected[: max(1, probes_per_target)]
    ]
    return {
        "add_card": queue_row.get("add_card") or "",
        "sidecar_tag": tag,
        "candidate_priority": queue_row.get("priority") or "",
        "candidate_readiness_status": queue_row.get("readiness_status") or "",
        "candidate_allowed_next_test": queue_row.get("allowed_next_test") or "",
        "target_cut_lanes": sorted(TAG_CUT_LANES.get(tag, set())),
        "named_cut_probe_count": len(probes),
        "safe_cut_ready_count": 0,
        "matrix_candidate_row_eligible_count": 0,
        "candidate_cut_probes": probes,
        "protected_near_misses": protected_near_misses,
        "next_action": "collect_cut_exposure_and_floor_equivalence_evidence_before_matrix_row",
    }


def input_health(payloads: Mapping[str, Mapping[str, Any]]) -> dict[str, Any]:
    missing = [key for key, payload in payloads.items() if not payload]
    return {
        "missing_inputs": missing,
        "all_required_inputs_present": not missing,
    }


def build_report(
    *,
    sidecar_queue: Mapping[str, Any],
    value_model: Mapping[str, Any],
    safe_cut_miner: Mapping[str, Any],
    gap_floor_trace_miner: Mapping[str, Any],
    paths: Mapping[str, Path],
    probes_per_target: int = 4,
) -> dict[str, Any]:
    payloads = {
        "sidecar_queue": sidecar_queue,
        "value_model": value_model,
        "safe_cut_miner": safe_cut_miner,
        "gap_floor_trace_miner": gap_floor_trace_miner,
    }
    health = input_health(payloads)
    value_rows = current_value_rows(value_model)
    attempted_cuts = attempted_package_cuts(safe_cut_miner)
    floor_trace_blockers = floor_trace_cut_blockers(gap_floor_trace_miner)
    targets = target_queue_rows(sidecar_queue) if not health["missing_inputs"] else []
    probe_rows = [
        target_probe_row(
            queue_row=row,
            value_rows=value_rows,
            attempted_cuts=attempted_cuts,
            floor_trace_blockers=floor_trace_blockers,
            probes_per_target=probes_per_target,
        )
        for row in targets
    ]
    all_probes = [probe for row in probe_rows for probe in as_list(row.get("candidate_cut_probes"))]
    blocker_counts = Counter(blocker for probe in all_probes for blocker in as_list(probe.get("blockers")))
    tag_counts = Counter(str(row.get("sidecar_tag") or "") for row in probe_rows)
    status = (
        "topdeck_sidecar_cut_model_planner_inputs_missing_keep_607"
        if health["missing_inputs"]
        else "topdeck_sidecar_cut_model_planner_review_probes_ready_no_safe_cut_keep_607"
    )
    if not all_probes and not health["missing_inputs"]:
        status = "topdeck_sidecar_cut_model_planner_no_named_probes_keep_607"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_sidecar_cut_model_planner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": status,
            "target_row_count": len(targets),
            "named_cut_probe_count": len(all_probes),
            "safe_cut_ready_count": 0,
            "matrix_candidate_row_eligible_count": 0,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "attempted_package_cut_name_count": len(attempted_cuts),
            "floor_trace_cut_blocker_count": len(floor_trace_blockers),
            "floor_trace_blocked_probe_count": sum(
                1 for probe in all_probes if probe.get("floor_trace_blocked")
            ),
            "floor_trace_cut_blocker_names": sorted(
                str(row.get("card_name") or "") for row in floor_trace_blockers.values()
            ),
            "protected_near_miss_count": sum(len(as_list(row.get("protected_near_misses"))) for row in probe_rows),
            "tag_counts": dict(sorted(tag_counts.items())),
            "blocker_counts": dict(sorted(blocker_counts.items())),
            "missing_inputs": as_list(health.get("missing_inputs")),
            "recommended_next_action": (
                "collect_probe_evidence_for_non_floor_trace_cut_slots_only"
                if floor_trace_blockers
                else "collect_probe_evidence_for_named_topdeck_and_mana_cuts"
            ),
        },
        "cut_model_targets": probe_rows,
        "source_evidence": {
            "sidecar_queue_summary": summary(sidecar_queue),
            "value_model_summary": summary(value_model),
            "safe_cut_summary": summary(safe_cut_miner),
            "gap_floor_trace_miner_summary": summary(gap_floor_trace_miner),
            "floor_trace_cut_blockers": dict(sorted(floor_trace_blockers.items())),
            "attempted_package_cut_names": sorted(attempted_cuts),
            "input_health": health,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "safe_cut_ready_now": False,
            "matrix_candidate_rows_ready": False,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "Named cut probes exist for review, but every probe remains blocked "
                "by safe-cut, exposure-trace, floor-trace, or floor-equivalence requirements."
            )
            if all_probes
            else "No trustworthy named cut probes were available from the current inputs.",
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_turn_review_probes_into_cuts_without trace evidence",
                "exclude floor-trace-blocked cuts from structure matrix inputs",
                "mine exposure and floor-equivalence traces for topdeck and mana probes",
                "feed only safe-cut-ready rows into the structure matrix",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Topdeck Sidecar Cut Model Planner",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Target rows: `{summary_row['target_row_count']}`",
        f"- Named cut probes: `{summary_row['named_cut_probe_count']}`",
        f"- Safe-cut ready count: `{summary_row['safe_cut_ready_count']}`",
        f"- Matrix candidate rows eligible: `{summary_row['matrix_candidate_row_eligible_count']}`",
        f"- Floor trace cut blockers: `{summary_row.get('floor_trace_cut_blocker_count', 0)}`",
        f"- Floor trace blocked probes: `{summary_row.get('floor_trace_blocked_probe_count', 0)}`",
        f"- Candidate deck materialization allowed now: `{str(summary_row['candidate_deck_materialization_allowed_now']).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Probe Summary", ""])
    lines.append(f"- tag_counts: `{json.dumps(summary_row.get('tag_counts') or {}, sort_keys=True)}`")
    lines.append(f"- blocker_counts: `{json.dumps(summary_row.get('blocker_counts') or {}, sort_keys=True)}`")
    lines.append(
        f"- floor_trace_cut_blocker_names: `{json.dumps(summary_row.get('floor_trace_cut_blocker_names') or [], sort_keys=True)}`"
    )
    lines.extend(["", "## Cut Model Targets", ""])
    for row in as_list(payload.get("cut_model_targets")):
        lines.append(f"### {row.get('add_card')}")
        lines.append(f"- sidecar_tag: `{row.get('sidecar_tag')}`")
        lines.append(f"- named_cut_probe_count: `{row.get('named_cut_probe_count')}`")
        lines.append(f"- target_cut_lanes: `{', '.join(as_list(row.get('target_cut_lanes')))}`")
        lines.append("| Probe cut | Score | Tier | Floor trace blocked | Usable now | Blockers |")
        lines.append("| --- | ---: | --- | ---: | ---: | --- |")
        for probe in as_list(row.get("candidate_cut_probes")):
            blockers = ", ".join(as_list(probe.get("blockers"))[:5])
            lines.append(
                "| {cut} | {score} | `{tier}` | `{floor_blocked}` | `{usable}` | `{blockers}` |".format(
                    cut=probe.get("cut_card") or "",
                    score=probe.get("cut_value_score") or 0,
                    tier=probe.get("cut_value_tier") or "",
                    floor_blocked=str(bool(probe.get("floor_trace_blocked"))).lower(),
                    usable=str(bool(probe.get("cut_usable_now"))).lower(),
                    blockers=blockers,
                )
            )
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- safe_cut_ready_now: `{str(decision['safe_cut_ready_now']).lower()}`")
    lines.append(f"- matrix_candidate_rows_ready: `{str(decision['matrix_candidate_rows_ready']).lower()}`")
    lines.append(f"- candidate_deck_materialization_allowed_now: `{str(decision['candidate_deck_materialization_allowed_now']).lower()}`")
    lines.append(f"- forced_access_allowed_now: `{str(decision['forced_access_allowed_now']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
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
    parser.add_argument("--sidecar-queue", type=Path, default=DEFAULT_SIDECAR_QUEUE)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--safe-cut-miner", type=Path, default=DEFAULT_SAFE_CUT_MINER)
    parser.add_argument("--gap-floor-trace-miner", type=Path, default=DEFAULT_GAP_FLOOR_TRACE_MINER)
    parser.add_argument("--probes-per-target", type=int, default=4)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "sidecar_queue": args.sidecar_queue,
        "value_model": args.value_model,
        "safe_cut_miner": args.safe_cut_miner,
        "gap_floor_trace_miner": args.gap_floor_trace_miner,
    }
    payload = build_report(
        sidecar_queue=read_json(args.sidecar_queue),
        value_model=read_json(args.value_model),
        safe_cut_miner=read_json(args.safe_cut_miner),
        gap_floor_trace_miner=read_json(args.gap_floor_trace_miner),
        paths=paths,
        probes_per_target=args.probes_per_target,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
