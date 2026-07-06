#!/usr/bin/env python3
"""Apply global ramp-axis policy to nonland cut pressure.

This read-only gate follows ``global_commander_role_axis_policy_builder`` after
engine-axis exhaustion. It rechecks ramp cards previously blocked as cross-lane
cuts and turns only safe ramp/excess rows into review-only cut pressure. It does
not choose a final cut, copy a deck, run battles, mutate databases, or promote
packages.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_core_role_audit as core_roles
import global_commander_engine_axis_nonland_cut_policy_model as engine_axis_model
import global_commander_land_cut_candidate_model as land_cuts
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT, rel


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_ROLE_AXIS_POLICY_REPORT = (
    REPORT_DIR / "global_commander_role_axis_policy_builder_20260706_post_engine_axis_exhaustion_current.json"
)
DEFAULT_NONLAND_MODEL_REPORT = (
    REPORT_DIR / "global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only.json"
)
DEFAULT_CORE_ROLE_REPORT = REPORT_DIR / "global_commander_core_role_audit_20260705_global_goal_hermes_only.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_ramp_axis_nonland_cut_policy_model_20260706_current"

RAMP_POLICY_ACTIONS = {
    "treat_ramp_above_range_as_cut_pressure_not_add_lane",
    "protect_ramp_cards_that_cover_missing_floor_roles",
    "block_more_same_deck_source_expansion_until_axis_policy_is_applied",
}
PAIR_PROOF_GATE = "collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def artifact_rel(path: Path) -> str:
    candidate = path if path.is_absolute() else REPO_ROOT / path
    try:
        return rel(candidate)
    except ValueError:
        return str(path)


def as_int(value: object) -> int:
    return land_cuts.as_int(value)


def normalize_name(value: object) -> str:
    return land_cuts.normalize_name(value)


def core_deck_by_id(core_payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(row.get("deck_id")): dict(row)
        for row in core_payload.get("decks", [])
        if isinstance(row, Mapping)
    }


def policy_row_by_role(policy_payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(row.get("role") or ""): dict(row)
        for row in policy_payload.get("axis_policy_rows", [])
        if isinstance(row, Mapping) and row.get("role")
    }


def source_cycle_decks(ramp_policy: Mapping[str, Any]) -> list[str]:
    out: list[str] = []
    for deck_id in ramp_policy.get("source_cycle_blocked_decks") or []:
        if str(deck_id) not in out:
            out.append(str(deck_id))
    return out


def deck_row_by_name(conn: sqlite3.Connection, deck_id: str) -> dict[str, dict[str, Any]]:
    rows = land_cuts.deck_rows(conn, deck_id)
    return {normalize_name(row.get("card_name")): row for row in rows}


def candidate_roles(cut: Mapping[str, Any], deck_row: Mapping[str, Any]) -> tuple[set[str], str]:
    roles = {str(role) for role in cut.get("roles") or []}
    if roles and roles != {"unknown"}:
        return roles, str(cut.get("classification_source") or "candidate_payload")
    inferred_roles, source = core_roles.card_roles(deck_row)
    return inferred_roles, source


def classify_ramp_cut(
    *,
    cut: Mapping[str, Any],
    deck_row: Mapping[str, Any],
    commander: str,
    missing_roles: set[str],
    excess_roles: set[str],
) -> dict[str, Any]:
    roles, classification_source = candidate_roles(cut, deck_row)
    matching_excess = roles & excess_roles
    missing_overlap = roles & missing_roles
    non_excess_overlap = roles - excess_roles
    plan_signals = engine_axis_model.commander_plan_signals(commander, deck_row)
    policy_blockers: list[str] = []
    if not deck_row:
        policy_blockers.append("deck_row_missing_for_cut_candidate")
    if missing_overlap:
        policy_blockers.append("ramp_card_covers_missing_floor_roles:" + ",".join(sorted(missing_overlap)))
    if plan_signals:
        policy_blockers.append("ramp_card_has_commander_plan_signal:" + ",".join(plan_signals))

    if "ramp" not in roles:
        bucket = "non_ramp_cut_outside_ramp_axis_policy"
        status = "ramp_axis_policy_not_applicable_to_cut"
        policy_blockers.append("cut_does_not_carry_ramp_role")
    elif missing_overlap or plan_signals:
        bucket = "protected_ramp_cut_pressure"
        status = "ramp_axis_policy_blocks_cut_until_source_lane_review"
    elif roles <= {"ramp"}:
        bucket = "ramp_only_excess_cut_pressure"
        status = "ramp_axis_policy_review_cut_pressure_ready"
    elif roles <= excess_roles and matching_excess:
        bucket = "ramp_overlap_excess_cut_pressure"
        status = "ramp_axis_policy_review_cut_pressure_ready"
    else:
        bucket = "ramp_overlap_non_excess_requires_review"
        status = "ramp_axis_policy_blocks_non_excess_overlap"
        if non_excess_overlap:
            policy_blockers.append("ramp_card_also_carries_non_excess_roles:" + ",".join(sorted(non_excess_overlap)))

    cut_pressure_ready = status == "ramp_axis_policy_review_cut_pressure_ready"
    original_reasons = list(cut.get("cut_reasons") or []) + list(cut.get("block_reasons") or [])
    return {
        "card_name": cut.get("card_name"),
        "original_score": as_int(cut.get("score")),
        "policy_bucket": bucket,
        "policy_status": status,
        "roles": sorted(roles),
        "matching_excess_roles": sorted(matching_excess),
        "missing_role_overlap": sorted(missing_overlap),
        "non_excess_overlap": sorted(non_excess_overlap),
        "commander_plan_signals": plan_signals,
        "classification_source": classification_source,
        "cmc": cut.get("cmc") if cut.get("cmc") is not None else deck_row.get("cmc"),
        "original_cut_reasons": original_reasons,
        "policy_reasons": [
            "ramp_is_capacity_ceiling_not_missing_role",
            "cut_pressure_is_review_only_not_card_level_permission",
            "protect_missing_floor_and_commander_plan_before_cut",
        ],
        "policy_blockers": policy_blockers,
        "cut_pressure_ready": cut_pressure_ready,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "promotion_allowed": False,
        "mutation_allowed": False,
    }


def combined_cut_candidates(pool: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    rows: list[Mapping[str, Any]] = []
    seen: set[str] = set()
    for source_key in ("blocked_cut_candidates", "top_cut_candidates"):
        for cut in pool.get(source_key) or []:
            if not isinstance(cut, Mapping):
                continue
            key = normalize_name(cut.get("card_name"))
            if key and key not in seen:
                rows.append(cut)
                seen.add(key)
    return rows


def evaluate_pool(
    *,
    pool: Mapping[str, Any],
    core_row: Mapping[str, Any],
    deck_rows_by_name: Mapping[str, Mapping[str, Any]],
) -> dict[str, Any]:
    deck_id = str(pool.get("deck_id") or "")
    commander = str(pool.get("commander") or "")
    missing = land_cuts.missing_roles(dict(core_row))
    excess = set(land_cuts.excess_roles(dict(core_row)))
    rows: list[dict[str, Any]] = []
    for cut in combined_cut_candidates(pool):
        card_name = str(cut.get("card_name") or "")
        deck_row = deck_rows_by_name.get(normalize_name(card_name), {})
        rows.append(
            classify_ramp_cut(
                cut=cut,
                deck_row=deck_row,
                commander=commander,
                missing_roles=missing,
                excess_roles=excess,
            )
        )

    bucket_counts = Counter(str(row.get("policy_bucket")) for row in rows)
    status_counts = Counter(str(row.get("policy_status")) for row in rows)
    ready = [row for row in rows if row.get("cut_pressure_ready")]
    protected = [row for row in rows if row.get("policy_bucket") == "protected_ramp_cut_pressure"]
    pair_rows: list[dict[str, Any]] = []
    for add in list(pool.get("top_candidates") or [])[:3]:
        for cut in ready[:3]:
            pair_rows.append(
                {
                    "add": add.get("card_name"),
                    "cut": cut.get("card_name"),
                    "status": "ramp_policy_pair_needs_card_level_usage_and_same_lane_proof",
                    "required_gate": PAIR_PROOF_GATE,
                    "candidate_copy_allowed": False,
                    "battle_gate_allowed": False,
                    "promotion_allowed": False,
                    "mutation_allowed": False,
                }
            )

    return {
        "deck_id": deck_id,
        "deck_name": pool.get("deck_name"),
        "commander": commander,
        "role": pool.get("role"),
        "missing_roles": sorted(missing),
        "excess_roles": sorted(excess),
        "evaluated_cut_count": len(rows),
        "ramp_cut_pressure_ready_count": len(ready),
        "protected_ramp_cut_count": len(protected),
        "policy_bucket_counts": dict(sorted(bucket_counts.items())),
        "policy_status_counts": dict(sorted(status_counts.items())),
        "policy_cut_rows": sorted(
            rows,
            key=lambda row: (
                row.get("policy_status") != "ramp_axis_policy_review_cut_pressure_ready",
                -as_int(row.get("original_score")),
                str(row.get("card_name")),
            ),
        ),
        "pair_rows": pair_rows,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "promotion_allowed": False,
        "mutation_allowed": False,
    }


def choose_status(*, ramp_policy: Mapping[str, Any], pool_rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    actions = set(ramp_policy.get("policy_actions") or [])
    if not RAMP_POLICY_ACTIONS <= actions:
        return (
            "ramp_axis_nonland_cut_policy_blocks_missing_policy_actions",
            "rebuild_role_axis_policy_before_ramp_nonland_cut_model",
        )
    if not pool_rows:
        return (
            "ramp_axis_nonland_cut_policy_blocks_no_source_cycle_pool",
            "rebuild_nonland_cut_model_for_source_cycle_decks",
        )
    ready_count = sum(as_int(row.get("ramp_cut_pressure_ready_count")) for row in pool_rows)
    if ready_count:
        return ("ramp_axis_nonland_cut_policy_applied_review_only", PAIR_PROOF_GATE)
    return (
        "ramp_axis_nonland_cut_policy_applied_blocks_no_ready_cut_pressure",
        "expand_ramp_axis_cut_source_lane_before_same_deck_source_research",
    )


def build_report(
    *,
    role_axis_policy_payload: Mapping[str, Any],
    nonland_model_payload: Mapping[str, Any],
    core_role_payload: Mapping[str, Any],
    sqlite_db: Path,
    role_axis_policy_report_path: Path = DEFAULT_ROLE_AXIS_POLICY_REPORT,
    nonland_model_report_path: Path = DEFAULT_NONLAND_MODEL_REPORT,
    core_role_report_path: Path = DEFAULT_CORE_ROLE_REPORT,
) -> dict[str, Any]:
    policy_rows = policy_row_by_role(role_axis_policy_payload)
    ramp_policy = policy_rows.get("ramp", {})
    cycle_decks = set(source_cycle_decks(ramp_policy))
    core_by_id = core_deck_by_id(core_role_payload)
    pools = [
        row
        for row in nonland_model_payload.get("nonland_pools") or []
        if isinstance(row, Mapping) and (not cycle_decks or str(row.get("deck_id")) in cycle_decks)
    ]

    with sqlite3.connect(sqlite_db) as conn:
        deck_cache = {deck_id: deck_row_by_name(conn, deck_id) for deck_id in cycle_decks}
        pool_rows = [
            evaluate_pool(
                pool=pool,
                core_row=core_by_id.get(str(pool.get("deck_id")), {}),
                deck_rows_by_name=deck_cache.get(str(pool.get("deck_id")), {}),
            )
            for pool in pools
        ]

    status, next_gate = choose_status(ramp_policy=ramp_policy, pool_rows=pool_rows)
    bucket_counts = Counter()
    status_counts = Counter()
    for row in pool_rows:
        bucket_counts.update(row.get("policy_bucket_counts") or {})
        status_counts.update(row.get("policy_status_counts") or {})

    candidate_pair_count = sum(len(row.get("pair_rows") or []) for row in pool_rows)
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_ramp_axis_nonland_cut_policy_model",
        "contract": rel(REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"),
        "source_role_axis_policy_report": artifact_rel(role_axis_policy_report_path),
        "source_nonland_model_report": artifact_rel(nonland_model_report_path),
        "source_core_role_report": artifact_rel(core_role_report_path),
        "source_db": artifact_rel(sqlite_db),
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "summary": {
            "source_cycle_deck_count": len(cycle_decks),
            "evaluated_pool_count": len(pool_rows),
            "evaluated_cut_count": sum(as_int(row.get("evaluated_cut_count")) for row in pool_rows),
            "ramp_cut_pressure_ready_count": sum(
                as_int(row.get("ramp_cut_pressure_ready_count")) for row in pool_rows
            ),
            "protected_ramp_cut_count": sum(as_int(row.get("protected_ramp_cut_count")) for row in pool_rows),
            "candidate_pair_count": candidate_pair_count,
            "policy_bucket_counts": dict(sorted(bucket_counts.items())),
            "policy_status_counts": dict(sorted(status_counts.items())),
            "next_gate": next_gate,
        },
        "ramp_policy": ramp_policy,
        "pool_policy_rows": pool_rows,
        "blockers": [
            "ramp_policy_cut_pressure_is_not_card_level_cut_permission",
            "candidate_copy_closed_until_usage_same_lane_and_battle_feedback_memory_exist",
            "battle_gate_closed_until_candidate_copy_strategy_matrix_and_replay_trace",
        ],
        "policy": {
            "ramp_boundary": "Ramp is capacity pressure when above range; it is not an add lane.",
            "cut_boundary": "Only ramp-only or excess-overlap cards become review cut pressure, and still need card-level proof.",
            "protection_boundary": "Ramp cards with missing-floor overlap or commander-plan signals are protected until source-lane review.",
            "mutation_boundary": "This model does not choose cards, copy decks, run battle, mutate DBs, or promote packages.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Ramp Axis Nonland Cut Policy Model",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- source_cycle_deck_count: `{summary['source_cycle_deck_count']}`",
        f"- evaluated_pool_count: `{summary['evaluated_pool_count']}`",
        f"- evaluated_cut_count: `{summary['evaluated_cut_count']}`",
        f"- ramp_cut_pressure_ready_count: `{summary['ramp_cut_pressure_ready_count']}`",
        f"- protected_ramp_cut_count: `{summary['protected_ramp_cut_count']}`",
        f"- candidate_pair_count: `{summary['candidate_pair_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Pool Policy Rows",
        "",
    ]
    for pool in payload["pool_policy_rows"]:
        lines.extend(
            [
                f"### Deck {pool['deck_id']} - {pool['commander']} - {pool['role']}",
                "",
                f"- missing_roles: `{','.join(pool['missing_roles']) or '-'}`",
                f"- excess_roles: `{','.join(pool['excess_roles']) or '-'}`",
                f"- ramp_cut_pressure_ready_count: `{pool['ramp_cut_pressure_ready_count']}`",
                f"- protected_ramp_cut_count: `{pool['protected_ramp_cut_count']}`",
                "",
                "| Card | Status | Bucket | Roles | Signals/Blockers |",
                "| --- | --- | --- | --- | --- |",
            ]
        )
        for row in pool["policy_cut_rows"]:
            signals = list(row.get("commander_plan_signals") or []) + list(row.get("policy_blockers") or [])
            lines.append(
                "| `{card}` | `{status}` | `{bucket}` | `{roles}` | {signals} |".format(
                    card=row.get("card_name"),
                    status=row.get("policy_status"),
                    bucket=row.get("policy_bucket"),
                    roles=",".join(row.get("roles") or []),
                    signals=", ".join(signals) or "-",
                )
            )
        if not pool["policy_cut_rows"]:
            lines.append("| none |  |  |  |  |")
        if pool.get("pair_rows"):
            lines.extend(["", "| Pair | Status | Required Gate |", "| --- | --- | --- |"])
            for row in pool["pair_rows"]:
                lines.append(
                    f"| `+{row['add']} / -{row['cut']}` | `{row['status']}` | `{row['required_gate']}` |"
                )
        lines.append("")
    lines.extend(["## Blockers", ""])
    for blocker in payload["blockers"]:
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
    parser.add_argument("--role-axis-policy-report", type=Path, default=DEFAULT_ROLE_AXIS_POLICY_REPORT)
    parser.add_argument("--nonland-model-report", type=Path, default=DEFAULT_NONLAND_MODEL_REPORT)
    parser.add_argument("--core-role-report", type=Path, default=DEFAULT_CORE_ROLE_REPORT)
    parser.add_argument("--db", type=Path, default=DEFAULT_SQLITE_DB)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        role_axis_policy_payload=load_json(args.role_axis_policy_report),
        nonland_model_payload=load_json(args.nonland_model_report),
        core_role_payload=load_json(args.core_role_report),
        sqlite_db=args.db,
        role_axis_policy_report_path=args.role_axis_policy_report,
        nonland_model_report_path=args.nonland_model_report,
        core_role_report_path=args.core_role_report,
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
