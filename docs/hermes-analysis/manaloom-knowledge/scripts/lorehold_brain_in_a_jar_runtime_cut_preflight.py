#!/usr/bin/env python3
"""Preflight Brain in a Jar runtime and same-lane cut evidence.

The route planner selected Brain in a Jar as the next Lorehold learning route.
This auditor does the next conservative step: verify the local runtime contract
evidence, mine protected-607 same-lane cuts, and state whether Brain can enter
candidate-row scoring. It never mutates deck 607, runs battle, or writes
PostgreSQL.
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

DEFAULT_ROUTE_PLANNER = REPORT_DIR / "lorehold_miracle_next_route_planner_20260705_current.json"
DEFAULT_RUNTIME_CONTRACT = (
    REPORT_DIR / "lorehold_brain_entreat_haze_runtime_contract_20260705_current.json"
)
DEFAULT_CANDIDATE_QUEUE = (
    REPORT_DIR / "lorehold_miracle_access_candidate_row_queue_20260705_current_relearn.json"
)
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_CUT_MINER = (
    REPORT_DIR / "lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_current"
)

BRAIN = "Brain in a Jar"
BRAIN_LANE = "topdeck_miracle_engine"
BRAIN_SAME_LANE_PRIORITY = {
    "Scroll Rack": 1,
    "Sensei's Divining Top": 2,
    "Library of Leng": 3,
    "Molecule Man": 4,
    "The Scarlet Witch": 5,
    "The Mind Stone": 6,
    "Land Tax": 7,
    "Urza's Saga": 8,
    "Lorehold, the Historian": 9,
}
SAFE_CLASSIFICATIONS = {"seed_safe_cut_ready", "gate_ready_safe_same_lane"}
SAFE_STATUSES = {"ready", "seed_safe_cut_ready", "gate_ready_safe_same_lane"}
BLOCKER_FIELDS = ("hard_stop_blockers", "soft_evidence_blockers", "other_blockers")

EXTERNAL_EVIDENCE = {
    "source_lane": "official_card_text_and_rulings",
    "links": {
        "scryfall": "https://scryfall.com/card/soi/252/brain-in-a-jar",
        "gatherer": "https://gatherer.wizards.com/SOI/en-us/252/brain-in-a-jar",
    },
    "learning_signal": (
        "Brain is not generic ramp; its value depends on modeling charge counters, "
        "exact mana-value spell selection from hand, free casting, and X-counter scry."
    ),
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


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def normalize(value: str) -> str:
    return " ".join(str(value or "").strip().lower().replace("’", "'").split())


def find_named(rows: list[Any], target: str, *fields: str) -> dict[str, Any]:
    wanted = normalize(target)
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        if any(normalize(str(row.get(field) or "")) == wanted for field in fields):
            return dict(row)
    return {}


def brain_contract(runtime_contract: Mapping[str, Any]) -> dict[str, Any]:
    return find_named(as_list(runtime_contract.get("contracts")), BRAIN, "card_name")


def brain_candidate_row(candidate_queue: Mapping[str, Any]) -> dict[str, Any]:
    return find_named(
        as_list(candidate_queue.get("candidate_rows")) + as_list(candidate_queue.get("blocked_candidate_rows")),
        BRAIN,
        "add_card",
        "card_name",
    )


def brain_route_row(route_planner: Mapping[str, Any]) -> dict[str, Any]:
    selected = as_dict(route_planner.get("selected_route"))
    if normalize(str(selected.get("card_name") or "")) == normalize(BRAIN):
        return selected
    return find_named(as_list(route_planner.get("route_rows")), BRAIN, "card_name")


def same_lane_value_rows(value_model: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in as_list(value_model.get("all_card_values")):
        if not isinstance(row, Mapping):
            continue
        name = str(row.get("card_name") or "")
        lanes = {str(lane) for lane in as_list(row.get("lanes"))}
        if BRAIN_LANE in lanes or name in BRAIN_SAME_LANE_PRIORITY:
            rows.append(dict(row))
    rows.sort(
        key=lambda row: (
            BRAIN_SAME_LANE_PRIORITY.get(str(row.get("card_name") or ""), 99),
            -as_int(row.get("value_score")),
            str(row.get("card_name") or ""),
        )
    )
    return rows


def cut_index(cut_miner: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    indexed: dict[str, dict[str, Any]] = {}
    for row in as_list(cut_miner.get("all_cut_rows")):
        if isinstance(row, Mapping) and row.get("card_name"):
            indexed[str(row["card_name"])] = dict(row)
    return indexed


def blocker_values(row: Mapping[str, Any]) -> list[str]:
    blockers: list[str] = []
    for field in BLOCKER_FIELDS:
        blockers.extend(str(item) for item in as_list(row.get(field)) if item)
    blockers.extend(str(item) for item in as_list(row.get("blockers")) if item)
    return sorted(set(blockers))


def cut_status(cut_row: Mapping[str, Any]) -> str:
    if not cut_row:
        return "blocked_missing_cut_evidence_row"
    classification = str(cut_row.get("classification") or "")
    status = str(cut_row.get("status") or "")
    blockers = blocker_values(cut_row)
    if classification in SAFE_CLASSIFICATIONS and status in SAFE_STATUSES and not blockers:
        return "safe_same_lane_cut_candidate"
    if classification == "closed_hard_stop_current_607":
        return "blocked_current_607_hard_stop"
    if status == "same_lane_only_not_seed_safe":
        return "blocked_same_lane_only_not_seed_safe"
    if blockers:
        return "blocked_cut_evidence_not_seed_safe"
    return "blocked_cut_not_seed_safe"


def investigation_action(status: str) -> str:
    return {
        "safe_same_lane_cut_candidate": "can_feed_brain_candidate_queue_after_active_rule_exists",
        "blocked_missing_cut_evidence_row": "produce_cut_evidence_before_any_brain_score",
        "blocked_current_607_hard_stop": "do_not_use_as_brain_cut_under_current_607_contract",
        "blocked_same_lane_only_not_seed_safe": "benchmark_only_not_seed_safe_for_brain",
        "blocked_cut_evidence_not_seed_safe": "mine_or_retest_cut_safety_before_matrix_scoring",
        "blocked_cut_not_seed_safe": "audit_cut_before_use_no_deck_action",
    }.get(status, "audit_cut_before_use_no_deck_action")


def build_same_lane_rows(value_model: Mapping[str, Any], cut_miner: Mapping[str, Any]) -> list[dict[str, Any]]:
    cuts = cut_index(cut_miner)
    rows: list[dict[str, Any]] = []
    for value_row in same_lane_value_rows(value_model):
        name = str(value_row.get("card_name") or "")
        cut_row = cuts.get(name, {})
        status = cut_status(cut_row)
        rows.append(
            {
                "card_name": name,
                "functional_tag": value_row.get("functional_tag") or "",
                "lanes": as_list(value_row.get("lanes")),
                "value_tier": value_row.get("value_tier") or "",
                "value_score": as_int(value_row.get("value_score")),
                "cut_policy": value_row.get("cut_policy") or "",
                "protected_anchor": bool(value_row.get("protected_anchor")),
                "runtime_ready": bool(value_row.get("runtime_ready")),
                "cut_lane": cut_row.get("lane") or "",
                "cut_status": cut_row.get("status") or "",
                "cut_classification": cut_row.get("classification") or "",
                "unique_exposure_count": as_int(cut_row.get("unique_exposure_count")),
                "direct_event_count": as_int(cut_row.get("direct_event_count")),
                "blockers": blocker_values(cut_row),
                "scout_status": status,
                "investigation_action": investigation_action(status),
            }
        )
    return rows


def runtime_state(contract: Mapping[str, Any]) -> dict[str, Any]:
    signal_hits = as_dict(contract.get("xmage_signal_hits"))
    required_slices = as_list(contract.get("required_runtime_slices"))
    active_rule_count = as_int(contract.get("active_rule_count"))
    return {
        "contract_found": bool(contract),
        "xmage_class_found": bool(contract.get("xmage_class_found")),
        "xmage_signal_hit_count": sum(1 for present in signal_hits.values() if bool(present)),
        "xmage_signal_miss_count": sum(1 for present in signal_hits.values() if not bool(present)),
        "xmage_signal_hits": signal_hits,
        "required_runtime_slices": required_slices,
        "required_runtime_slice_count": len(required_slices),
        "active_rule_count": active_rule_count,
        "runtime_family_ready": active_rule_count > 0,
        "readiness": contract.get("readiness") or "",
        "manaloom_foundation": contract.get("manaloom_foundation") or "",
        "xmage_path": contract.get("xmage_path") or "",
    }


def decision_status(
    *,
    state: Mapping[str, Any],
    safe_cut_count: int,
    matrix_blocker_count: int,
) -> tuple[str, str, bool]:
    if not state.get("contract_found"):
        return (
            "brain_in_a_jar_runtime_cut_preflight_blocked_missing_runtime_contract",
            "rerun_brain_entreat_haze_runtime_contract",
            False,
        )
    no_rule = as_int(state.get("active_rule_count")) <= 0
    no_cut = safe_cut_count == 0
    if no_rule and no_cut:
        return (
            "brain_in_a_jar_runtime_cut_preflight_blocked_no_active_rule_no_safe_cut_keep_607",
            "draft_exact_mana_value_free_cast_runtime_family_before_any_brain_deck_action",
            False,
        )
    if no_rule:
        return (
            "brain_in_a_jar_runtime_cut_preflight_blocked_no_active_rule_keep_607",
            "draft_exact_mana_value_free_cast_runtime_family_before_candidate_queue_refresh",
            False,
        )
    if no_cut:
        return (
            "brain_in_a_jar_runtime_cut_preflight_blocked_no_safe_cut_keep_607",
            "mine_named_topdeck_miracle_engine_cut_before_matrix_scoring",
            False,
        )
    if matrix_blocker_count > 0:
        return (
            "brain_in_a_jar_runtime_cut_preflight_ready_for_queue_refresh_no_battle",
            "rerun_candidate_queue_and_structure_matrix_before_any_battle",
            False,
        )
    return (
        "brain_in_a_jar_runtime_cut_preflight_ready_for_matrix_scoring_no_battle",
        "feed_brain_and_named_cut_into_matrix_scoring_no_battle",
        True,
    )


def build_report(
    *,
    route_planner: Mapping[str, Any],
    runtime_contract: Mapping[str, Any],
    candidate_queue: Mapping[str, Any],
    value_model: Mapping[str, Any],
    cut_miner: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    contract = brain_contract(runtime_contract)
    candidate_row = brain_candidate_row(candidate_queue)
    route_row = brain_route_row(route_planner)
    state = runtime_state(contract)
    same_lane_rows = build_same_lane_rows(value_model, cut_miner)
    safe_rows = [row for row in same_lane_rows if row["scout_status"] == "safe_same_lane_cut_candidate"]
    blocked_rows = [row for row in same_lane_rows if row["scout_status"] != "safe_same_lane_cut_candidate"]
    matrix_blocker_count = as_int(summary(candidate_queue).get("matrix_contract_blocker_count"))
    status, next_action, matrix_allowed = decision_status(
        state=state,
        safe_cut_count=len(safe_rows),
        matrix_blocker_count=matrix_blocker_count,
    )
    status_counts = Counter(row["scout_status"] for row in same_lane_rows)
    blocker_counts = Counter(blocker for row in same_lane_rows for blocker in as_list(row.get("blockers")))
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_brain_in_a_jar_runtime_cut_preflight",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "summary": {
            "decision_status": status,
            "route_planner_selected_brain": normalize(str(route_row.get("card_name") or "")) == normalize(BRAIN),
            "brain_candidate_row_found": bool(candidate_row),
            "brain_contract_found": bool(contract),
            "xmage_class_found": bool(state.get("xmage_class_found")),
            "xmage_signal_hit_count": as_int(state.get("xmage_signal_hit_count")),
            "required_runtime_slice_count": as_int(state.get("required_runtime_slice_count")),
            "brain_active_rule_count": as_int(state.get("active_rule_count")),
            "same_lane_candidate_count": len(same_lane_rows),
            "safe_cut_count": len(safe_rows),
            "blocked_same_lane_cut_count": len(blocked_rows),
            "matrix_contract_blocker_count": matrix_blocker_count,
            "matrix_scoring_allowed_now": matrix_allowed,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "postgres_writes_allowed_now": False,
            "deck_action_allowed_now": False,
            "status_counts": dict(sorted(status_counts.items())),
            "top_blocker_counts": dict(blocker_counts.most_common(12)),
            "recommended_next_action": next_action,
        },
        "brain_route_row": route_row,
        "brain_candidate_row": candidate_row,
        "brain_runtime_state": state,
        "safe_same_lane_cut_candidates": safe_rows,
        "blocked_same_lane_cut_rows": blocked_rows,
        "same_lane_cut_rows": same_lane_rows,
        "source_evidence": {
            "route_planner_summary": summary(route_planner),
            "runtime_contract_summary": summary(runtime_contract),
            "candidate_queue_summary": summary(candidate_queue),
            "value_model_summary": summary(value_model),
            "cut_miner_summary": summary(cut_miner),
            "external_confirmation": EXTERNAL_EVIDENCE,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "matrix_scoring_allowed_now": matrix_allowed,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "postgres_writes_allowed": False,
            "runtime_family_required_before_battle": as_int(state.get("active_rule_count")) <= 0,
            "named_safe_cut_required_before_scoring": len(safe_rows) == 0,
            "reason": (
                "Brain in a Jar has strong XMage/source evidence for the miracle-access thesis, "
                "but ManaLoom has no active card rule and protected 607 has no seed-safe "
                "same-lane cut. Brain therefore remains a runtime learning route, not a deck card."
            )
            if as_int(state.get("active_rule_count")) <= 0 or len(safe_rows) == 0
            else (
                "Brain has runtime and at least one synthetic same-lane cut candidate, but deck "
                "materialization and natural battle remain closed until refreshed matrix scoring."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_materialize_brain_candidate_deck",
                "do_not_run_natural_battle_for_brain_from_this_preflight",
                next_action,
                "after_runtime_family_exists_rerun_this_preflight_before_candidate_queue_refresh",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    lines = [
        "# Lorehold Brain in a Jar Runtime/Cut Preflight",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Route planner selected Brain: `{str(summary_row['route_planner_selected_brain']).lower()}`",
        f"- Brain candidate row found: `{str(summary_row['brain_candidate_row_found']).lower()}`",
        f"- Brain contract found: `{str(summary_row['brain_contract_found']).lower()}`",
        f"- XMage class found: `{str(summary_row['xmage_class_found']).lower()}`",
        f"- XMage signal hits: `{summary_row['xmage_signal_hit_count']}`",
        f"- Required runtime slices: `{summary_row['required_runtime_slice_count']}`",
        f"- Active Brain rule count: `{summary_row['brain_active_rule_count']}`",
        f"- Same-lane candidates reviewed: `{summary_row['same_lane_candidate_count']}`",
        f"- Safe same-lane cuts: `{summary_row['safe_cut_count']}`",
        f"- Blocked same-lane cuts: `{summary_row['blocked_same_lane_cut_count']}`",
        f"- Matrix scoring allowed now: `{str(summary_row['matrix_scoring_allowed_now']).lower()}`",
        f"- Candidate deck materialization allowed now: `{str(summary_row['candidate_deck_materialization_allowed_now']).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    runtime = as_dict(payload.get("brain_runtime_state"))
    lines.extend(["", "## Runtime State", ""])
    lines.append(f"- readiness: `{runtime.get('readiness') or '-'}`")
    lines.append(f"- manaloom_foundation: `{runtime.get('manaloom_foundation') or '-'}`")
    lines.append(f"- xmage_path: `{runtime.get('xmage_path') or '-'}`")
    lines.append(f"- required slices: `{', '.join(as_list(runtime.get('required_runtime_slices')))}`")
    lines.extend(["", "## Safe Same-Lane Cut Candidates", ""])
    if payload.get("safe_same_lane_cut_candidates"):
        lines.append("| Cut | Lane | Value | Exposure | Action |")
        lines.append("| --- | --- | ---: | ---: | --- |")
        for row in as_list(payload.get("safe_same_lane_cut_candidates")):
            lines.append(
                f"| {row.get('card_name') or ''} | `{row.get('cut_lane') or ''}` | "
                f"{row.get('value_score') or 0} | {row.get('unique_exposure_count') or 0} | "
                f"`{row.get('investigation_action') or ''}` |"
            )
    else:
        lines.append("- None.")
    lines.extend(["", "## Blocked Same-Lane Rows", ""])
    lines.append("| Cut | Value Lanes | Cut Lane | Classification | Exposure | Blockers |")
    lines.append("| --- | --- | --- | --- | ---: | --- |")
    for row in as_list(payload.get("blocked_same_lane_cut_rows"))[:16]:
        lines.append(
            "| {card} | `{lanes}` | `{cut_lane}` | `{classification}` | {exposure} | {blockers} |".format(
                card=row.get("card_name") or "",
                lanes=", ".join(as_list(row.get("lanes"))),
                cut_lane=row.get("cut_lane") or "",
                classification=row.get("scout_status") or "",
                exposure=row.get("unique_exposure_count") or 0,
                blockers=", ".join(as_list(row.get("blockers"))) or "-",
            )
        )
    lines.extend(["", "## External Confirmation", ""])
    external = as_dict(as_dict(payload.get("source_evidence")).get("external_confirmation"))
    lines.append(f"- source_lane: `{external.get('source_lane') or '-'}`")
    lines.append(f"- learning_signal: {external.get('learning_signal') or '-'}")
    for key, link in sorted(as_dict(external.get("links")).items()):
        lines.append(f"- {key}: {link}")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- matrix_scoring_allowed_now: `{str(decision['matrix_scoring_allowed_now']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- postgres_writes_allowed: `{str(decision['postgres_writes_allowed']).lower()}`")
    lines.append(f"- runtime_family_required_before_battle: `{str(decision['runtime_family_required_before_battle']).lower()}`")
    lines.append(f"- named_safe_cut_required_before_scoring: `{str(decision['named_safe_cut_required_before_scoring']).lower()}`")
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
    parser.add_argument("--route-planner", type=Path, default=DEFAULT_ROUTE_PLANNER)
    parser.add_argument("--runtime-contract", type=Path, default=DEFAULT_RUNTIME_CONTRACT)
    parser.add_argument("--candidate-queue", type=Path, default=DEFAULT_CANDIDATE_QUEUE)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--cut-miner", type=Path, default=DEFAULT_CUT_MINER)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "route_planner": args.route_planner,
        "runtime_contract": args.runtime_contract,
        "candidate_queue": args.candidate_queue,
        "value_model": args.value_model,
        "cut_miner": args.cut_miner,
    }
    payload = build_report(
        route_planner=read_json(args.route_planner),
        runtime_contract=read_json(args.runtime_contract),
        candidate_queue=read_json(args.candidate_queue),
        value_model=read_json(args.value_model),
        cut_miner=read_json(args.cut_miner),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
