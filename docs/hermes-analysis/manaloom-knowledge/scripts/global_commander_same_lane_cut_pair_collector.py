#!/usr/bin/env python3
"""Collect value-safe same-lane cut pairs for a synthesized Commander package.

This gate consumes the same-lane source package and scans the current
evaluation deck for cuts that compete in the exact required role lane. It can
produce review-only add/cut pairs for a later scope reducer, but it does not
copy a deck, mutate SQLite/PostgreSQL, run battle, reclassify stage-only cuts,
or promote anything.
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

import global_commander_candidate_package_strategy_matrix as strategy_matrix
import global_commander_cut_source_lane_expander as cut_expander
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_PACKAGE_SOURCE_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_same_lane_cut_pair_collector_20260705_kaalia_value_safe_stage1_repair_scope1"
)

TARGET_RISK_BY_ROLE = {
    "haste_protection_silence": {"haste_or_protection_cut", "attack_window_or_extra_combat_cut"},
    "mana_acceleration": {"mana_acceleration_cut"},
    "tutors_access": {"tutor_access_cut"},
}


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


def resolve_repo_path(value: object, fallback: Path) -> Path:
    text = str(value or "").strip()
    if not text:
        return fallback
    path = Path(text)
    return path if path.is_absolute() else REPO_ROOT / path


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def selected_add_rows(package_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in package_payload.get("selected_add_package") or []:
        if isinstance(row, Mapping) and row.get("card_name") and row.get("replaces_cut_role"):
            rows.append(dict(row))
    rows.sort(key=lambda row: (-as_int(row.get("score")), str(row.get("card_name") or "")))
    return rows


def selected_source_lane_report(package_payload: Mapping[str, Any]) -> Path:
    inputs = package_payload.get("input_artifacts") or {}
    return resolve_repo_path(
        inputs.get("source_lane_report"),
        REPORT_DIR
        / "global_commander_same_lane_add_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.json",
    )


def resolve_working_db(
    *,
    source_lane_payload: Mapping[str, Any],
    sqlite_db: Path | None,
) -> tuple[Path, dict[str, Any]]:
    if sqlite_db is not None:
        return sqlite_db, {
            "selected_db": rel(sqlite_db),
            "source": "cli_override",
            "selected_db_exists": sqlite_db.exists(),
        }
    inputs = source_lane_payload.get("input_artifacts") or {}
    selected_db = resolve_repo_path(inputs.get("selected_db"), DEFAULT_SQLITE_DB)
    if selected_db.exists():
        return selected_db, {
            "selected_db": rel(selected_db),
            "source": "same_lane_source_lane_report",
            "selected_db_exists": True,
        }
    return DEFAULT_SQLITE_DB, {
        "requested_db": rel(selected_db),
        "selected_db": rel(DEFAULT_SQLITE_DB),
        "source": "default_sqlite_fallback",
        "selected_db_exists": DEFAULT_SQLITE_DB.exists(),
    }


def resolve_strategy_report(source_lane_payload: Mapping[str, Any]) -> Path:
    inputs = source_lane_payload.get("input_artifacts") or {}
    profile_report = resolve_repo_path(
        inputs.get("profile_repair_report"),
        REPORT_DIR / "global_commander_profile_repair_candidate_model_20260705_kaalia_value_safe_stage1_repair_scope1.json",
    )
    profile_payload = load_json(profile_report) if profile_report.exists() else {}
    profile_inputs = profile_payload.get("input_artifacts") or {}
    return resolve_repo_path(
        profile_inputs.get("strategy_matrix_report"),
        REPORT_DIR
        / "global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1_repair_scope1.json",
    )


def role_requirements(package_payload: Mapping[str, Any]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in selected_add_rows(package_payload):
        role = str(row.get("replaces_cut_role") or "")
        if role:
            counts[role] += 1
    return dict(counts)


def source_lane_target_counts(package_payload: Mapping[str, Any]) -> dict[str, int]:
    target_counts: dict[str, int] = {}
    for row in package_payload.get("source_lane_diagnostics") or []:
        if not isinstance(row, Mapping):
            continue
        role = str(row.get("cut_role") or "")
        if role:
            target_counts[role] = as_int(row.get("target_cut_count"))
    return target_counts


def staple_tier_for_name(
    *,
    card_name: str,
    staples: Mapping[str, Mapping[str, Any]],
) -> tuple[str, Mapping[str, Any] | None]:
    staple = staples.get(normalize_name(card_name))
    return cut_expander.staple_tier(staple), staple


def score_cut_for_role(
    *,
    row: Mapping[str, Any],
    target_role: str,
    profile_roles: set[str],
    staple_tier: str,
) -> tuple[int, list[str]]:
    score = 45
    reasons = [f"same_lane_{target_role}"]
    if len(profile_roles) == 1:
        score += 12
        reasons.append("single_profile_role_slot")
    cmc = float(row.get("cmc") or 0)
    if cmc >= 4:
        score += 6
        reasons.append("higher_curve_cut_pressure")
    if target_role == "mana_acceleration" and cmc >= 3:
        score += 7
        reasons.append("slower_ramp_replacement_pressure")
    if target_role == "tutors_access" and cmc >= 3:
        score += 5
        reasons.append("high_curve_tutor_replacement_pressure")
    if staple_tier == "format_staple_reviewable":
        score -= 8
        reasons.append("format_staple_requires_extra_review")
    return score, reasons


def classify_cut_for_role(
    *,
    row: Mapping[str, Any],
    target_role: str,
    selected_add_names: set[str],
    staples: Mapping[str, Mapping[str, Any]],
    expected_anchors: set[str],
) -> dict[str, Any]:
    card_name = str(row.get("card_name") or "")
    card_key = normalize_name(card_name)
    profile_roles = strategy_matrix.profile_roles_for_card(row)
    risk_flags = strategy_matrix.cut_risk(row)
    staple_tier, staple = staple_tier_for_name(card_name=card_name, staples=staples)
    block_reasons: list[str] = []
    stage_reasons: list[str] = []

    if int(row.get("is_commander") or 0):
        block_reasons.append("commander_card")
    if card_key in selected_add_names:
        block_reasons.append("same_card_selected_as_add")
    if target_role not in profile_roles:
        block_reasons.append("missing_required_same_lane_profile_role")
    protected = sorted((profile_roles & cut_expander.PROTECTED_PROFILE_ROLES) - {target_role})
    if "lands" in protected:
        block_reasons.append("land_slot_not_cut_by_nonland_same_lane_pair")
        protected = [role for role in protected if role != "lands"]
    if "angels_demons_dragons_payoffs" in protected:
        block_reasons.append("commander_payoff_slot_protected")
        protected = [role for role in protected if role != "angels_demons_dragons_payoffs"]
    if protected:
        stage_reasons.append("other_protected_profile_role_" + ",".join(protected))
    if target_role in cut_expander.PROTECTED_PROFILE_ROLES:
        stage_reasons.append("target_role_is_protected_profile_lane_requires_trace_or_equal_gate")
    non_target_risks = sorted(set(risk_flags) - TARGET_RISK_BY_ROLE.get(target_role, set()))
    if non_target_risks:
        stage_reasons.append("non_target_cut_risk:" + ",".join(non_target_risks))
    if card_key in expected_anchors:
        stage_reasons.append("commander_expected_package_anchor_requires_stage_proof")
    if card_key in cut_expander.GLOBAL_FEEDBACK_STAGE_ONLY_CUTS:
        stage_reasons.append("global_battle_feedback_requires_new_same_lane_or_gate")
    if staple_tier == "structural_foundation_anchor":
        stage_reasons.append("structural_foundation_staple_requires_same_lane_or_battle_proof")
    elif staple_tier == "contextual_staple_stage_only":
        stage_reasons.append("contextual_staple_requires_stage_review")

    score, reasons = score_cut_for_role(
        row=row,
        target_role=target_role,
        profile_roles=profile_roles,
        staple_tier=staple_tier,
    )
    base = {
        "card_name": card_name,
        "target_cut_role": target_role,
        "score": score,
        "profile_roles": sorted(profile_roles),
        "risk_flags": risk_flags,
        "cmc": row.get("cmc"),
        "type_line": row.get("type_line") or "",
        "staple_tier": staple_tier,
        "format_staple": staple or {},
        "cut_reasons": reasons,
        "mutation_allowed": False,
        "candidate_copy_allowed": False,
    }
    if block_reasons:
        return {
            **base,
            "status": "blocked_same_lane_cut_candidate",
            "block_reasons": block_reasons,
            "stage_reasons": stage_reasons,
        }
    if stage_reasons:
        return {
            **base,
            "status": "stage_only_same_lane_cut_candidate",
            "stage_reasons": stage_reasons,
        }
    return {
        **base,
        "status": "review_only_value_safe_same_lane_cut_candidate",
    }


def candidate_sort_key(row: Mapping[str, Any]) -> tuple[int, str]:
    return (-as_int(row.get("score")), str(row.get("card_name") or ""))


def classify_deck_cuts(
    *,
    deck_rows: list[dict[str, Any]],
    target_roles: set[str],
    selected_add_names: set[str],
    staples: Mapping[str, Mapping[str, Any]],
    expected_anchors: set[str],
) -> list[dict[str, Any]]:
    rows = []
    for deck_row in deck_rows:
        if int(deck_row.get("is_commander") or 0):
            continue
        profile_roles = strategy_matrix.profile_roles_for_card(deck_row)
        for target_role in sorted(target_roles):
            if target_role in profile_roles:
                rows.append(
                    classify_cut_for_role(
                        row=deck_row,
                        target_role=target_role,
                        selected_add_names=selected_add_names,
                        staples=staples,
                        expected_anchors=expected_anchors,
                    )
                )
    rows.sort(key=candidate_sort_key)
    return rows


def pair_adds_with_cuts(
    *,
    adds: list[dict[str, Any]],
    ready_cuts: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    cuts_by_role: dict[str, list[dict[str, Any]]] = {}
    for cut in ready_cuts:
        cuts_by_role.setdefault(str(cut.get("target_cut_role") or ""), []).append(cut)
    for role in cuts_by_role:
        cuts_by_role[role].sort(key=candidate_sort_key)

    used_cuts: set[str] = set()
    pairs: list[dict[str, Any]] = []
    unpaired: list[dict[str, Any]] = []
    for add in adds:
        role = str(add.get("replaces_cut_role") or "")
        chosen = None
        for cut in cuts_by_role.get(role, []):
            key = normalize_name(str(cut.get("card_name") or ""))
            if key and key not in used_cuts:
                chosen = cut
                used_cuts.add(key)
                break
        if not chosen:
            unpaired.append(
                {
                    "card_name": add.get("card_name"),
                    "selected_for_axis": add.get("selected_for_axis"),
                    "replaces_cut_role": role,
                    "score": as_int(add.get("score")),
                    "status": "unpaired_same_lane_add_needs_value_safe_cut",
                }
            )
            continue
        pairs.append(
            {
                "pair_index": len(pairs) + 1,
                "add": add.get("card_name"),
                "cut": chosen.get("card_name"),
                "same_lane_role": role,
                "add_axis": add.get("selected_for_axis"),
                "add_score": as_int(add.get("score")),
                "cut_score": as_int(chosen.get("score")),
                "pair_score": as_int(add.get("score")) + as_int(chosen.get("score")),
                "cut_profile_roles": chosen.get("profile_roles") or [],
                "cut_risk_flags": chosen.get("risk_flags") or [],
                "cut_reasons": chosen.get("cut_reasons") or [],
                "status": "review_only_value_safe_same_lane_pair",
                "candidate_copy_allowed": False,
                "required_gates": [
                    "same_lane_package_scope_reducer",
                    "isolated_candidate_copy",
                    "commander_strategy_matrix",
                    "battle_gate_with_added_card_and_cut_lane_exercised",
                ],
            }
        )
    return pairs, unpaired


def role_counts(rows: list[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        value = str(row.get(field) or "")
        if value:
            counts[value] += 1
    return dict(counts)


def choose_status_and_next_gate(ready_pair_count: int, selected_add_count: int) -> tuple[str, str]:
    if ready_pair_count == 0:
        return (
            "same_lane_cut_pair_collection_blocks_candidate_copy",
            "collect_more_same_lane_cut_evidence_or_broaden_cut_source_lanes",
        )
    if ready_pair_count < selected_add_count:
        return (
            "same_lane_cut_pair_collection_partial_scope_reducer_required",
            "reduce_same_lane_package_scope_to_ready_pairs_before_candidate_copy",
        )
    return (
        "same_lane_cut_pairs_ready_for_scope_reducer",
        "run_same_lane_package_scope_reducer_before_candidate_copy",
    )


def build_report(
    *,
    package_source_report: Path,
    sqlite_db: Path | None = None,
) -> dict[str, Any]:
    package_payload = load_json(package_source_report)
    package_summary = package_payload.get("summary") or {}
    source_lane_report = selected_source_lane_report(package_payload)
    source_lane_payload = load_json(source_lane_report) if source_lane_report.exists() else {}
    strategy_report = resolve_strategy_report(source_lane_payload)
    strategy_payload = load_json(strategy_report) if strategy_report.exists() else {}
    db_path, db_resolution = resolve_working_db(
        source_lane_payload=source_lane_payload,
        sqlite_db=sqlite_db,
    )
    deck_id = str(package_summary.get("deck_id") or "")
    adds = selected_add_rows(package_payload)
    requirements = role_requirements(package_payload)
    source_targets = source_lane_target_counts(package_payload)
    selected_add_names = {normalize_name(str(row.get("card_name") or "")) for row in adds}
    expected_anchors = cut_expander.expected_package_anchor_names(strategy_payload)
    with sqlite3.connect(db_path) as conn:
        deck_rows = cut_expander.deck_rows(conn, deck_id)
        staples = cut_expander.format_staples_by_name(conn)
    classified = classify_deck_cuts(
        deck_rows=deck_rows,
        target_roles=set(requirements),
        selected_add_names=selected_add_names,
        staples=staples,
        expected_anchors=expected_anchors,
    )
    ready_cuts = [
        row for row in classified if row["status"] == "review_only_value_safe_same_lane_cut_candidate"
    ]
    stage_only = [row for row in classified if row["status"] == "stage_only_same_lane_cut_candidate"]
    blocked = [row for row in classified if row["status"] == "blocked_same_lane_cut_candidate"]
    pairs, unpaired = pair_adds_with_cuts(adds=adds, ready_cuts=ready_cuts)
    status, next_gate = choose_status_and_next_gate(len(pairs), len(adds))
    blockers: list[str] = ["candidate_copy_closed_until_same_lane_scope_reducer_runs"]
    if unpaired:
        blockers.append(f"same_lane_value_safe_pair_shortfall:required_{len(adds)}_ready_{len(pairs)}")
    if not pairs:
        blockers.append("no_review_only_value_safe_same_lane_pairs")
    if stage_only:
        blockers.append(f"stage_only_same_lane_cuts_need_evidence:{len(stage_only)}")
    blockers.append("strategy_matrix_and_replay_gate_not_run_for_same_lane_package")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_same_lane_cut_pair_collector",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "battle_replay_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "input_artifacts": {
            "package_source_report": rel(package_source_report),
            "source_lane_report": rel(source_lane_report),
            "strategy_matrix_report": rel(strategy_report),
            "selected_db": rel(db_path),
        },
        "db_resolution": db_resolution,
        "summary": {
            "deck_id": deck_id,
            "commander": str(package_summary.get("commander") or ""),
            "selected_add_count": len(adds),
            "required_pair_count": len(adds),
            "ready_pair_count": len(pairs),
            "unpaired_add_count": len(unpaired),
            "ready_cut_candidate_count": len(ready_cuts),
            "stage_only_cut_candidate_count": len(stage_only),
            "blocked_cut_candidate_count": len(blocked),
            "required_pair_count_by_role": requirements,
            "ready_pair_count_by_role": role_counts(pairs, "same_lane_role"),
            "source_lane_target_cut_count_by_role": source_targets,
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "review_only_same_lane_pairs": pairs,
        "unpaired_adds": unpaired,
        "ready_cut_candidates": sorted(ready_cuts, key=candidate_sort_key)[:30],
        "stage_only_cut_candidates": sorted(stage_only, key=candidate_sort_key)[:40],
        "blocked_cut_candidates": sorted(blocked, key=lambda row: str(row.get("card_name") or ""))[:40],
        "policy": {
            "same_lane_boundary": "An add can pair only with a cut whose profile role matches the add's explicit replaces_cut_role.",
            "stage_only_boundary": "Protected lanes, expected package anchors, structural staples, and non-target risk remain stage-only or blocked.",
            "scope_boundary": "This collector only creates review-only pairs; a later scope reducer must choose any copied-DB scope.",
            "battle_boundary": "No battle or promotion opens before copied candidate structure, strategy matrix, and replay evidence.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Same-Lane Cut Pair Collector",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- selected_add_count: `{summary['selected_add_count']}`",
        f"- required_pair_count: `{summary['required_pair_count']}`",
        f"- ready_pair_count: `{summary['ready_pair_count']}`",
        f"- unpaired_add_count: `{summary['unpaired_add_count']}`",
        f"- ready_cut_candidate_count: `{summary['ready_cut_candidate_count']}`",
        f"- stage_only_cut_candidate_count: `{summary['stage_only_cut_candidate_count']}`",
        f"- blocked_cut_candidate_count: `{summary['blocked_cut_candidate_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Pair Counts By Role",
        "",
        "| Role | Required | Ready | Source Target |",
        "| --- | ---: | ---: | ---: |",
    ]
    for role, required in summary["required_pair_count_by_role"].items():
        lines.append(
            "| `{role}` | {required} | {ready} | {target} |".format(
                role=role,
                required=required,
                ready=summary["ready_pair_count_by_role"].get(role, 0),
                target=summary["source_lane_target_cut_count_by_role"].get(role, 0),
            )
        )
    lines.extend(
        [
            "",
            "## Review-Only Same-Lane Pairs",
            "",
            "| Step | Add | Cut | Role | Pair Score |",
            "| ---: | --- | --- | --- | ---: |",
        ]
    )
    for row in payload["review_only_same_lane_pairs"]:
        lines.append(
            "| {step} | `{add}` | `{cut}` | `{role}` | {score} |".format(
                step=row["pair_index"],
                add=row["add"],
                cut=row["cut"],
                role=row["same_lane_role"],
                score=row["pair_score"],
            )
        )
    if not payload["review_only_same_lane_pairs"]:
        lines.append("| 0 | none | none | `-` | 0 |")
    lines.extend(["", "## Unpaired Adds", ""])
    if payload["unpaired_adds"]:
        for row in payload["unpaired_adds"]:
            lines.append(
                "- `{card}` needs `{role}` cut evidence".format(
                    card=row.get("card_name"),
                    role=row.get("replaces_cut_role"),
                )
            )
    else:
        lines.append("- none")
    lines.extend(["", "## Stage-Only Cut Sample", ""])
    for row in payload["stage_only_cut_candidates"][:12]:
        lines.append(
            "- `{card}` ({role}): `{reasons}`".format(
                card=row.get("card_name"),
                role=row.get("target_cut_role"),
                reasons=", ".join(row.get("stage_reasons") or []),
            )
        )
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
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
    parser.add_argument("--package-source-report", type=Path, default=DEFAULT_PACKAGE_SOURCE_REPORT)
    parser.add_argument("--db", type=Path)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(package_source_report=args.package_source_report, sqlite_db=args.db)
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
