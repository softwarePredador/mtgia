#!/usr/bin/env python3
"""Expand value-aware Commander cut source lanes for synthesized packages.

This read-only gate consumes a synthesized Commander package and scans the
current deck for additional cut candidates. It separates value-safe cuts from
stage-only or blocked cuts by role budgets, protected commander lanes, local
format staples, and cut-risk flags. It does not materialize a deck, run
battles, mutate SQLite/PostgreSQL, or promote any candidate.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_candidate_package_strategy_matrix as strategy_matrix
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_PACKAGE_SYNTHESIS_REPORT = (
    REPORT_DIR / "global_commander_payoff_package_synthesizer_20260705_kaalia_removal_floor_step5.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_cut_source_lane_expander_20260705_kaalia_removal_floor_step5"
)

PROTECTED_PROFILE_ROLES = {
    "lands",
    "angels_demons_dragons_payoffs",
    "spot_interaction",
    "haste_protection_silence",
}
STAPLE_STRUCTURAL_RANK_CEILING = 150
STAPLE_STAGE_RANK_CEILING = 300
GLOBAL_FEEDBACK_STAGE_ONLY_CUTS = {
    normalize_name("Birgi, God of Storytelling // Harnfel, Horn of Bounty"),
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


def resolve_input_reports(package_payload: Mapping[str, Any]) -> tuple[Path, Path]:
    inputs = package_payload.get("input_artifacts") or {}
    profile_report = resolve_repo_path(
        inputs.get("repair_candidate_model_report"),
        REPORT_DIR / "global_commander_profile_repair_candidate_model_20260705_kaalia_removal_floor_step5.json",
    )
    profile_payload = load_json(profile_report) if profile_report.exists() else {}
    profile_inputs = profile_payload.get("input_artifacts") or {}
    strategy_report = resolve_repo_path(
        profile_inputs.get("strategy_matrix_report"),
        REPORT_DIR / "global_commander_candidate_package_strategy_matrix_20260705_kaalia_removal_floor_step5.json",
    )
    return profile_report, strategy_report


def resolve_working_db(
    *,
    package_payload: Mapping[str, Any],
    profile_report: Path,
    strategy_report: Path,
    sqlite_db: Path | None,
) -> tuple[Path, dict[str, Any]]:
    if sqlite_db is not None:
        return sqlite_db, {
            "selected_db": rel(sqlite_db),
            "source": "cli_override",
            "fallback_used": False,
            "selected_db_exists": sqlite_db.exists(),
        }
    profile_payload = load_json(profile_report) if profile_report.exists() else {}
    profile_inputs = profile_payload.get("input_artifacts") or {}
    candidate_db = resolve_repo_path(profile_inputs.get("candidate_db"), DEFAULT_SQLITE_DB)
    if candidate_db.exists():
        return candidate_db, {
            "requested_db": rel(candidate_db),
            "selected_db": rel(candidate_db),
            "source": "repair_candidate_model_candidate_db",
            "fallback_used": False,
            "selected_db_exists": True,
        }
    strategy_payload = load_json(strategy_report) if strategy_report.exists() else {}
    strategy_inputs = strategy_payload.get("input_artifacts") or {}
    base_db = resolve_repo_path(strategy_inputs.get("base_db"), DEFAULT_SQLITE_DB)
    return base_db, {
        "requested_db": rel(candidate_db),
        "selected_db": rel(base_db),
        "source": "strategy_matrix_base_db_fallback",
        "fallback_used": True,
        "selected_db_exists": base_db.exists(),
        "fallback_reason": "candidate_db_missing_local_ignored_artifact",
        "strategy_matrix_report": rel(strategy_report),
    }


def deck_rows(conn: sqlite3.Connection, deck_id: str) -> list[dict[str, Any]]:
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        """
        SELECT card_name, COALESCE(quantity, 1) AS quantity,
               functional_tag, functional_tags_json, type_line, oracle_text,
               cmc, COALESCE(is_commander, 0) AS is_commander
        FROM deck_cards
        WHERE CAST(deck_id AS TEXT)=?
        ORDER BY card_name
        """,
        (str(deck_id),),
    ).fetchall()
    return [dict(row) for row in rows]


def table_exists(conn: sqlite3.Connection, table_name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
        (table_name,),
    ).fetchone()
    return bool(row)


def format_staples_by_name(conn: sqlite3.Connection) -> dict[str, dict[str, Any]]:
    if not table_exists(conn, "format_staples"):
        return {}
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        """
        SELECT card_name, archetype, category, edhrec_rank, is_banned
        FROM format_staples
        WHERE COALESCE(is_banned, 0)=0
        ORDER BY COALESCE(edhrec_rank, 999999), card_name
        """
    ).fetchall()
    result: dict[str, dict[str, Any]] = {}
    for row in rows:
        key = normalize_name(str(row["card_name"] or ""))
        if not key:
            continue
        current = result.get(key)
        rank = int(row["edhrec_rank"] or 999999)
        if current is None or rank < int(current.get("edhrec_rank") or 999999):
            result[key] = {
                "card_name": row["card_name"],
                "archetype": row["archetype"],
                "category": row["category"],
                "edhrec_rank": rank,
            }
    return result


def over_target_budgets(strategy_payload: Mapping[str, Any]) -> dict[str, int]:
    budgets: dict[str, int] = {}
    for row in strategy_payload.get("target_evaluations") or []:
        if not isinstance(row, Mapping):
            continue
        if row.get("candidate_status") != "above_target_review":
            continue
        role = str(row.get("role") or "")
        budget = int(row.get("candidate_count") or 0) - int(row.get("max") or 0)
        if role and budget > 0:
            budgets[role] = budget
    return budgets


def expected_package_anchor_names(strategy_payload: Mapping[str, Any]) -> set[str]:
    anchors: set[str] = set()
    for section_name in ("base_expected_package_presence", "candidate_expected_package_presence"):
        section = strategy_payload.get(section_name) or {}
        if not isinstance(section, Mapping):
            continue
        for payload in section.values():
            if not isinstance(payload, Mapping):
                continue
            for card in payload.get("present_cards") or []:
                key = normalize_name(str(card or ""))
                if key:
                    anchors.add(key)
    return anchors


def selected_add_count(package_payload: Mapping[str, Any]) -> int:
    summary = package_payload.get("summary") or {}
    return int(summary.get("selected_add_count") or len(package_payload.get("selected_add_package") or []))


def package_size_limit(package_payload: Mapping[str, Any]) -> int:
    summary = package_payload.get("summary") or {}
    return int(summary.get("package_size_limit") or 8)


def forced_cut_access_evidence(forced_payload: Mapping[str, Any]) -> dict[str, Any]:
    if not forced_payload:
        return {
            "status": "not_provided",
            "usage_blocked_count": 0,
            "manual_review_count": 0,
            "force_failure_count": 0,
            "focus_cards": [],
        }
    summary = forced_payload.get("summary") or {}
    return {
        "status": str(forced_payload.get("status") or "unknown"),
        "usage_blocked_count": int(summary.get("usage_blocked_count") or 0),
        "manual_review_count": int(summary.get("manual_review_count") or 0),
        "force_failure_count": int(summary.get("force_failure_count") or 0),
        "focus_cards": [str(card) for card in summary.get("focus_cards") or [] if card],
    }


def staple_tier(staple: Mapping[str, Any] | None) -> str:
    if not staple:
        return "not_format_staple"
    rank = int(staple.get("edhrec_rank") or 999999)
    if rank <= STAPLE_STRUCTURAL_RANK_CEILING:
        return "structural_foundation_anchor"
    if rank <= STAPLE_STAGE_RANK_CEILING:
        return "contextual_staple_stage_only"
    return "format_staple_reviewable"


def primary_cut_role(matching_roles: list[str], budgets_remaining: Mapping[str, int]) -> str:
    return max(matching_roles, key=lambda role: (int(budgets_remaining.get(role) or 0), role))


def score_cut_candidate(
    *,
    row: Mapping[str, Any],
    roles: set[str],
    matching_roles: list[str],
    staple: Mapping[str, Any] | None,
) -> tuple[int, list[str]]:
    score = 40 + (10 * len(matching_roles))
    reasons = [f"over_target_{role}" for role in matching_roles]
    cmc = float(row.get("cmc") or 0)
    if cmc >= 3:
        score += 4
        reasons.append("higher_curve_pressure")
    if "mana_acceleration" in matching_roles and cmc >= 3:
        score += 7
        reasons.append("replaceable_slow_ramp_pressure")
    if "tutors_access" in matching_roles:
        score += 5
        reasons.append("tutor_density_above_target_review")
    if "card_draw_selection" in matching_roles:
        score += 4
        reasons.append("card_flow_above_target_review")
    tier = staple_tier(staple)
    if tier == "format_staple_reviewable":
        score -= 8
        reasons.append("format_staple_requires_extra_review")
    return score, reasons


def classify_cut_row(
    *,
    row: Mapping[str, Any],
    over_budgets: Mapping[str, int],
    staples: Mapping[str, Mapping[str, Any]],
    expected_anchors: set[str],
) -> dict[str, Any]:
    card_name = str(row.get("card_name") or "")
    card_key = normalize_name(card_name)
    profile_roles = strategy_matrix.profile_roles_for_card(row)
    risk_flags = strategy_matrix.cut_risk(row)
    staple = staples.get(card_key)
    tier = staple_tier(staple)
    matching_roles = sorted(role for role in profile_roles if int(over_budgets.get(role) or 0) > 0)
    block_reasons: list[str] = []
    stage_reasons: list[str] = []
    if int(row.get("is_commander") or 0):
        block_reasons.append("commander_card")
    protected = sorted(profile_roles & PROTECTED_PROFILE_ROLES)
    if protected:
        block_reasons.append("protected_profile_role_" + ",".join(protected))
    if "attack_window_or_extra_combat_cut" in risk_flags:
        stage_reasons.append("attack_window_cut_requires_same_lane_stage_proof")
    if card_key in expected_anchors:
        stage_reasons.append("commander_expected_package_anchor_requires_stage_proof")
    if card_key in GLOBAL_FEEDBACK_STAGE_ONLY_CUTS:
        stage_reasons.append("global_battle_feedback_requires_new_same_lane_or_gate")
    if tier == "structural_foundation_anchor":
        stage_reasons.append("structural_foundation_staple_requires_same_lane_or_battle_proof")
    elif tier == "contextual_staple_stage_only":
        stage_reasons.append("contextual_staple_requires_stage_review")
    if not matching_roles:
        block_reasons.append("no_above_target_role_budget")
    score, reasons = score_cut_candidate(
        row=row,
        roles=profile_roles,
        matching_roles=matching_roles,
        staple=staple,
    )
    base = {
        "card_name": card_name,
        "score": score,
        "profile_roles": sorted(profile_roles),
        "risk_flags": risk_flags,
        "matching_over_target_roles": matching_roles,
        "cmc": row.get("cmc"),
        "type_line": row.get("type_line") or "",
        "format_staple": staple or {},
        "staple_tier": tier,
        "cut_reasons": reasons,
        "mutation_allowed": False,
    }
    if block_reasons:
        return {
            **base,
            "status": "blocked_commander_cut_source_candidate",
            "block_reasons": block_reasons,
            "stage_reasons": stage_reasons,
        }
    if stage_reasons:
        return {
            **base,
            "status": "stage_only_commander_cut_source_candidate",
            "stage_reasons": stage_reasons,
        }
    return {
        **base,
        "status": "review_only_commander_cut_source_candidate",
    }


def candidate_key(row: Mapping[str, Any]) -> tuple[int, str]:
    return (-int(row.get("score") or 0), str(row.get("card_name") or ""))


def select_ready_cuts(
    *,
    ready_candidates: list[dict[str, Any]],
    over_budgets: Mapping[str, int],
    required_count: int,
) -> tuple[list[dict[str, Any]], dict[str, int]]:
    budgets_remaining = {role: int(count) for role, count in over_budgets.items()}
    selected: list[dict[str, Any]] = []
    for row in sorted(ready_candidates, key=candidate_key):
        matching = [role for role in row.get("matching_over_target_roles") or [] if budgets_remaining.get(role, 0) > 0]
        if not matching:
            continue
        primary_role = primary_cut_role(matching, budgets_remaining)
        selected_row = dict(row)
        selected_row["status"] = "review_only_expanded_cut_source_candidate"
        selected_row["primary_cut_role"] = primary_role
        selected_row["cut_budget_before"] = budgets_remaining[primary_role]
        selected_row["cut_budget_after"] = budgets_remaining[primary_role] - 1
        selected.append(selected_row)
        budgets_remaining[primary_role] -= 1
        if len(selected) >= required_count:
            break
    return selected, budgets_remaining


def build_report(
    *,
    package_synthesis_report: Path,
    sqlite_db: Path | None = None,
    forced_cut_access_report: Path | None = None,
) -> dict[str, Any]:
    package_payload = load_json(package_synthesis_report)
    forced_payload = (
        load_json(forced_cut_access_report)
        if forced_cut_access_report is not None and forced_cut_access_report.exists()
        else {}
    )
    forced_evidence = forced_cut_access_evidence(forced_payload)
    profile_report, strategy_report = resolve_input_reports(package_payload)
    strategy_payload = load_json(strategy_report) if strategy_report.exists() else {}
    db_path, db_resolution = resolve_working_db(
        package_payload=package_payload,
        profile_report=profile_report,
        strategy_report=strategy_report,
        sqlite_db=sqlite_db,
    )
    summary = package_payload.get("summary") or {}
    deck_id = str(summary.get("deck_id") or "")
    required_count = selected_add_count(package_payload)
    limit = package_size_limit(package_payload)
    over_budgets = over_target_budgets(strategy_payload)
    expected_anchors = expected_package_anchor_names(strategy_payload)
    with sqlite3.connect(db_path) as conn:
        rows = deck_rows(conn, deck_id)
        staples = format_staples_by_name(conn)
        classified = [
            classify_cut_row(row=row, over_budgets=over_budgets, staples=staples, expected_anchors=expected_anchors)
            for row in rows
            if not int(row.get("is_commander") or 0)
        ]
    ready_pool = [row for row in classified if row["status"] == "review_only_commander_cut_source_candidate"]
    stage_pool = [row for row in classified if row["status"] == "stage_only_commander_cut_source_candidate"]
    blocked_pool = [row for row in classified if row["status"] == "blocked_commander_cut_source_candidate"]
    selected, remaining_budget = select_ready_cuts(
        ready_candidates=ready_pool,
        over_budgets=over_budgets,
        required_count=required_count,
    )
    if len(selected) >= required_count and required_count <= limit:
        status = "commander_cut_source_lane_ready_for_candidate_copy"
        next_gate = "materialize_value_safe_commander_package_copy"
        candidate_copy_allowed = True
    elif len(selected) >= limit:
        status = "commander_cut_source_lane_expanded_stage_split_required"
        next_gate = "split_synthesized_package_into_value_safe_stages"
        candidate_copy_allowed = False
    else:
        status = "commander_cut_source_lane_still_blocks_full_package"
        next_gate = (
            "backfill_value_safe_cuts_or_reduce_package_scope_after_forced_access_block"
            if forced_evidence["usage_blocked_count"] > 0
            else "backfill_value_safe_cuts_or_reduce_package_scope"
        )
        candidate_copy_allowed = False
    blockers: list[str] = []
    if len(selected) < required_count:
        blockers.append(f"value_safe_cut_shortfall:required_{required_count}_ready_{len(selected)}")
    if required_count > limit:
        blockers.append(f"full_package_size_exceeds_stage_limit:required_{required_count}_limit_{limit}")
    if forced_evidence["usage_blocked_count"] > 0:
        blockers.append(
            "forced_cut_access_blocks_unresolved_cut_reclassification:"
            f"{forced_evidence['usage_blocked_count']}"
        )
    input_artifacts = {
        "package_synthesis_report": rel(package_synthesis_report),
        "repair_candidate_model_report": rel(profile_report),
        "strategy_matrix_report": rel(strategy_report),
        "selected_db": rel(db_path),
    }
    if forced_cut_access_report is not None:
        input_artifacts["forced_cut_access_report"] = rel(forced_cut_access_report)
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_cut_source_lane_expander",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": candidate_copy_allowed,
        "input_artifacts": input_artifacts,
        "db_resolution": db_resolution,
        "summary": {
            "deck_id": deck_id,
            "commander": str(summary.get("commander") or ""),
            "required_cut_count": required_count,
            "package_size_limit": limit,
            "over_target_cut_budgets": over_budgets,
            "expected_package_anchor_count": len(expected_anchors),
            "value_safe_cut_count": len(selected),
            "stage_only_cut_count": len(stage_pool),
            "blocked_cut_count": len(blocked_pool),
            "remaining_cut_budget_after_selection": remaining_budget,
            "candidate_copy_blocker_count": len(blockers),
            "forced_cut_access_status": forced_evidence["status"],
            "forced_usage_blocked_count": forced_evidence["usage_blocked_count"],
            "forced_manual_review_count": forced_evidence["manual_review_count"],
            "forced_focus_cards": forced_evidence["focus_cards"],
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "selected_value_safe_cuts": selected,
        "stage_only_cut_candidates": sorted(stage_pool, key=candidate_key)[:30],
        "blocked_cut_candidates": sorted(blocked_pool, key=lambda row: str(row.get("card_name") or ""))[:40],
        "policy": {
            "cut_boundary": "Expanded cuts are source-lane evidence, not deck changes.",
            "staple_boundary": "Structural staples require same-lane replacement or battle proof before cutting.",
            "protected_role_boundary": "Lands, commander payoffs, spot interaction, and attack-window protection stay protected while below target or strategically required.",
            "forced_access_boundary": "Forced access can block reclassification; it cannot create value-safe cut proof.",
            "battle_boundary": "No battle or promotion opens from cut source-lane expansion alone.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Cut Source Lane Expander",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- required_cut_count: `{summary['required_cut_count']}`",
        f"- value_safe_cut_count: `{summary['value_safe_cut_count']}`",
        f"- stage_only_cut_count: `{summary['stage_only_cut_count']}`",
        f"- blocked_cut_count: `{summary['blocked_cut_count']}`",
        f"- forced_cut_access_status: `{summary['forced_cut_access_status']}`",
        f"- forced_usage_blocked_count: `{summary['forced_usage_blocked_count']}`",
        f"- package_size_limit: `{summary['package_size_limit']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- candidate_copy_blocker_count: `{summary['candidate_copy_blocker_count']}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Cut Budgets",
        "",
        "| Role | Initial Budget | Remaining |",
        "| --- | ---: | ---: |",
    ]
    budgets = summary["over_target_cut_budgets"]
    remaining = summary["remaining_cut_budget_after_selection"]
    for role, count in budgets.items():
        lines.append(f"| `{role}` | {count} | {remaining.get(role, 0)} |")
    lines.extend(["", "## Blockers", ""])
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
            lines.append(f"- `{blocker}`")
    else:
        lines.append("- none")
    lines.extend(
        [
            "",
            "## Selected Value-Safe Cuts",
            "",
            "| Cut | Primary Role | Score | Matching Roles | Reasons |",
            "| --- | --- | ---: | --- | --- |",
        ]
    )
    for row in payload["selected_value_safe_cuts"]:
        lines.append(
            "| `{name}` | `{primary}` | {score} | `{roles}` | {reasons} |".format(
                name=row.get("card_name"),
                primary=row.get("primary_cut_role"),
                score=row.get("score") or 0,
                roles=", ".join(row.get("matching_over_target_roles") or []),
                reasons=", ".join(row.get("cut_reasons") or []),
            )
        )
    lines.extend(["", "## Stage-Only Cuts", ""])
    for row in payload["stage_only_cut_candidates"][:12]:
        lines.append(
            f"- `{row.get('card_name')}`: `{', '.join(row.get('stage_reasons') or [])}`"
        )
    lines.extend(["", "## Blocked Cut Sample", ""])
    for row in payload["blocked_cut_candidates"][:12]:
        lines.append(
            f"- `{row.get('card_name')}`: `{', '.join(row.get('block_reasons') or [])}`"
        )
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
    parser.add_argument("--package-synthesis-report", type=Path, default=DEFAULT_PACKAGE_SYNTHESIS_REPORT)
    parser.add_argument("--db", type=Path)
    parser.add_argument("--forced-cut-access-report", type=Path)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        package_synthesis_report=args.package_synthesis_report,
        sqlite_db=args.db,
        forced_cut_access_report=args.forced_cut_access_report,
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
