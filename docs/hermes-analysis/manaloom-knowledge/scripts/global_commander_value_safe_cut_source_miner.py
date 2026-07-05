#!/usr/bin/env python3
"""Mine fresh Commander cut-source hypotheses after post-forced recovery.

The miner looks for non-protected, non-stage-only current-deck cards that can
become value-safe cut candidates only after trace or same-lane proof. It is
read-only and never authorizes deck mutation, candidate copy, battle, or
promotion by itself.
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
import global_commander_cut_source_lane_expander as cut_expander
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_RECOVERY_REPORT = (
    REPORT_DIR / "global_commander_post_forced_recovery_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_CUT_SOURCE_REPORT = (
    REPORT_DIR / "global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.json"
)
DEFAULT_EXTERNAL_CUT_POLICY_REPORT = (
    REPORT_DIR / "global_commander_external_corpus_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1"
)


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


def selected_db_from_cut_payload(cut_payload: Mapping[str, Any], override: Path | None) -> tuple[Path, dict[str, Any]]:
    if override is not None:
        return override, {"selected_db": rel(override), "source": "cli_override", "selected_db_exists": override.exists()}
    inputs = cut_payload.get("input_artifacts") or {}
    db_path = resolve_repo_path(inputs.get("selected_db"), DEFAULT_SQLITE_DB)
    if db_path.exists():
        return db_path, {"selected_db": rel(db_path), "source": "cut_source_report", "selected_db_exists": True}
    return DEFAULT_SQLITE_DB, {
        "requested_db": rel(db_path),
        "selected_db": rel(DEFAULT_SQLITE_DB),
        "source": "default_sqlite_fallback",
        "selected_db_exists": DEFAULT_SQLITE_DB.exists(),
    }


def known_names(rows: list[Mapping[str, Any]], field: str = "card_name") -> set[str]:
    return {
        normalize_name(str(row.get(field) or ""))
        for row in rows
        if isinstance(row, Mapping) and row.get(field)
    }


def recovery_target_roles(recovery_payload: Mapping[str, Any], cut_payload: Mapping[str, Any]) -> dict[str, int]:
    summary = recovery_payload.get("summary") or {}
    target = summary.get("target_cut_roles") or {}
    if target:
        return {str(role): int(count or 0) for role, count in target.items() if int(count or 0) > 0}
    cut_summary = cut_payload.get("summary") or {}
    budgets = cut_summary.get("remaining_cut_budget_after_selection") or cut_summary.get("over_target_cut_budgets") or {}
    return {str(role): int(count or 0) for role, count in budgets.items() if int(count or 0) > 0}


def external_policy_blocks(policy_payload: Mapping[str, Any]) -> dict[str, list[str]]:
    blocks: dict[str, list[str]] = {}
    for row in policy_payload.get("cut_policy_rows") or []:
        if not isinstance(row, Mapping) or not row.get("cut_card"):
            continue
        if row.get("rerun_miner_allowed_for_card") is True:
            continue
        key = normalize_name(str(row.get("cut_card") or ""))
        policy = str(row.get("cut_policy") or "external_corpus_policy_blocks_rerun_hypothesis")
        if key:
            blocks.setdefault(key, []).append(policy)
    for field in ("excluded_from_rerun_miner", "held_for_negative_review"):
        for card in policy_payload.get(field) or []:
            key = normalize_name(str(card or ""))
            if key:
                blocks.setdefault(key, []).append("external_corpus_policy_blocks_rerun_hypothesis")
    return {key: sorted(set(reasons)) for key, reasons in blocks.items()}


def score_hypothesis(
    *,
    row: Mapping[str, Any],
    profile_roles: set[str],
    risk_flags: list[str],
    target_roles: Mapping[str, int],
    staple_tier: str,
) -> tuple[int, list[str]]:
    score = 30
    reasons: list[str] = []
    matching = sorted(role for role in profile_roles if int(target_roles.get(role) or 0) > 0)
    if matching:
        score += 8 * len(matching)
        reasons.append("matches_post_forced_target_cut_role:" + ",".join(matching))
    if not profile_roles:
        score += 16
        reasons.append("off_profile_or_unclassified_slot")
    if not risk_flags:
        score += 8
        reasons.append("no_runtime_cut_risk_flag")
    cmc = float(row.get("cmc") or 0)
    if cmc >= 4:
        score += 6
        reasons.append("higher_curve_cut_pressure")
    if staple_tier == "format_staple_reviewable":
        score -= 6
        reasons.append("format_staple_reviewable_needs_extra_trace")
    return score, reasons


def classify_row(
    *,
    row: Mapping[str, Any],
    staples: Mapping[str, Mapping[str, Any]],
    stage_only_names: set[str],
    forced_focus_names: set[str],
    target_roles: Mapping[str, int],
    external_policy_blocks_by_name: Mapping[str, list[str]] | None = None,
) -> dict[str, Any]:
    name = str(row.get("card_name") or "")
    key = normalize_name(name)
    profile_roles = strategy_matrix.profile_roles_for_card(row)
    risk_flags = strategy_matrix.cut_risk(row)
    staple = staples.get(key)
    tier = cut_expander.staple_tier(staple)
    block_reasons: list[str] = []
    if int(row.get("is_commander") or 0):
        block_reasons.append("commander_card")
    if key in stage_only_names:
        block_reasons.append("already_stage_only_cut_source_requires_proof")
    if key in forced_focus_names:
        block_reasons.append("forced_access_used_cut_blocks_reclassification")
    policy_reasons = (external_policy_blocks_by_name or {}).get(key) or []
    for reason in policy_reasons:
        block_reasons.append("external_corpus_policy:" + reason)
    protected = sorted(profile_roles & cut_expander.PROTECTED_PROFILE_ROLES)
    if protected:
        block_reasons.append("protected_profile_role_" + ",".join(protected))
    if tier == "structural_foundation_anchor":
        block_reasons.append("structural_foundation_staple_requires_same_lane_or_battle_proof")
    elif tier == "contextual_staple_stage_only":
        block_reasons.append("contextual_staple_requires_stage_review")
    if "attack_window_or_extra_combat_cut" in risk_flags:
        block_reasons.append("attack_window_cut_requires_same_lane_stage_proof")
    score, reasons = score_hypothesis(
        row=row,
        profile_roles=profile_roles,
        risk_flags=risk_flags,
        target_roles=target_roles,
        staple_tier=tier,
    )
    base = {
        "card_name": name,
        "score": score,
        "profile_roles": sorted(profile_roles),
        "risk_flags": risk_flags,
        "staple_tier": tier,
        "format_staple": staple or {},
        "type_line": row.get("type_line") or "",
        "cmc": row.get("cmc"),
        "reasons": reasons,
        "candidate_copy_allowed": False,
    }
    if block_reasons:
        return {**base, "status": "fresh_cut_source_hypothesis_blocked", "block_reasons": block_reasons}
    return {
        **base,
        "status": "fresh_cut_source_hypothesis_needs_trace",
        "next_gate": "collect_usage_trace_for_new_cut_source_hypothesis",
    }


def candidate_sort_key(row: Mapping[str, Any]) -> tuple[int, str]:
    return (-int(row.get("score") or 0), str(row.get("card_name") or ""))


def build_report(
    *,
    recovery_report: Path,
    cut_source_report: Path,
    sqlite_db: Path | None = None,
    external_cut_policy_report: Path | None = None,
) -> dict[str, Any]:
    recovery_payload = load_json(recovery_report)
    cut_payload = load_json(cut_source_report)
    policy_payload = load_json(external_cut_policy_report) if external_cut_policy_report else {}
    recovery_summary = recovery_payload.get("summary") or {}
    cut_summary = cut_payload.get("summary") or {}
    deck_id = str(recovery_summary.get("deck_id") or cut_summary.get("deck_id") or "")
    db_path, db_resolution = selected_db_from_cut_payload(cut_payload, sqlite_db)
    target_roles = recovery_target_roles(recovery_payload, cut_payload)
    stage_only_names = known_names(cut_payload.get("stage_only_cut_candidates") or [])
    forced_focus_names = {
        normalize_name(str(card))
        for card in (cut_summary.get("forced_focus_cards") or recovery_summary.get("forced_focus_cards") or [])
        if card
    }
    external_policy_blocks_by_name = external_policy_blocks(policy_payload)
    with sqlite3.connect(db_path) as conn:
        rows = cut_expander.deck_rows(conn, deck_id)
        staples = cut_expander.format_staples_by_name(conn)
    classified = [
        classify_row(
            row=row,
            staples=staples,
            stage_only_names=stage_only_names,
            forced_focus_names=forced_focus_names,
            target_roles=target_roles,
            external_policy_blocks_by_name=external_policy_blocks_by_name,
        )
        for row in rows
        if not int(row.get("is_commander") or 0)
    ]
    hypotheses = sorted(
        [row for row in classified if row["status"] == "fresh_cut_source_hypothesis_needs_trace"],
        key=candidate_sort_key,
    )
    blocked = sorted(
        [row for row in classified if row["status"] == "fresh_cut_source_hypothesis_blocked"],
        key=lambda row: str(row.get("card_name") or ""),
    )
    status = (
        "value_safe_cut_source_hypotheses_ready_for_trace"
        if hypotheses
        else "value_safe_cut_source_mining_blocks_package_resynthesis"
    )
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_value_safe_cut_source_miner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "input_artifacts": {
            "recovery_report": rel(recovery_report),
            "cut_source_report": rel(cut_source_report),
            "selected_db": rel(db_path),
            **(
                {"external_cut_policy_report": rel(external_cut_policy_report)}
                if external_cut_policy_report
                else {}
            ),
        },
        "db_resolution": db_resolution,
        "summary": {
            "deck_id": deck_id,
            "commander": str(recovery_summary.get("commander") or cut_summary.get("commander") or ""),
            "target_cut_roles": target_roles,
            "deck_card_count": len(rows),
            "hypothesis_count": len(hypotheses),
            "blocked_hypothesis_count": len(blocked),
            "stage_only_cut_count": len(stage_only_names),
            "forced_focus_count": len(forced_focus_names),
            "external_policy_exclusion_count": len(external_policy_blocks_by_name),
            "next_gate": (
                "collect_usage_trace_for_new_cut_source_hypotheses"
                if hypotheses
                else "broaden_commander_package_axis_or_external_cut_research"
            ),
        },
        "candidate_copy_blockers": [
            "hypotheses_require_trace_before_value_safe_reclassification",
            "candidate_copy_closed_until_value_safe_cut_pair_exists",
            *(
                ["external_policy_exclusions_consumed:" + str(len(external_policy_blocks_by_name))]
                if external_policy_blocks_by_name
                else []
            ),
        ],
        "fresh_cut_source_hypotheses": hypotheses[:20],
        "blocked_hypothesis_sample": blocked[:40],
        "policy": {
            "miner_boundary": "Fresh hypotheses are not value-safe cuts until trace or same-lane proof is collected.",
            "protected_role_boundary": "Protected commander lanes, lands, structural staples, contextual staples, and stage-only cuts remain blocked.",
            "external_policy_boundary": "When provided, external corpus policy exclusions block reusing current cards as fresh hypotheses.",
            "battle_boundary": "This miner does not run battle or open promotion.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Value-Safe Cut Source Miner",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- hypothesis_count: `{summary['hypothesis_count']}`",
        f"- blocked_hypothesis_count: `{summary['blocked_hypothesis_count']}`",
        f"- external_policy_exclusion_count: `{summary['external_policy_exclusion_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Target Cut Roles",
        "",
    ]
    for role, count in summary["target_cut_roles"].items():
        lines.append(f"- `{role}`: `{count}`")
    lines.extend(
        [
            "",
            "## Fresh Cut-Source Hypotheses",
            "",
            "| Card | Score | Roles | Reasons | Next Gate |",
            "| --- | ---: | --- | --- | --- |",
        ]
    )
    for row in payload["fresh_cut_source_hypotheses"]:
        lines.append(
            "| `{card}` | {score} | `{roles}` | {reasons} | `{next}` |".format(
                card=row.get("card_name"),
                score=row.get("score") or 0,
                roles=", ".join(row.get("profile_roles") or []),
                reasons=", ".join(row.get("reasons") or []),
                next=row.get("next_gate"),
            )
        )
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
    lines.extend(["", "## Blocked Hypothesis Sample", ""])
    for row in payload["blocked_hypothesis_sample"][:12]:
        lines.append(f"- `{row.get('card_name')}`: `{', '.join(row.get('block_reasons') or [])}`")
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
    parser.add_argument("--recovery-report", type=Path, default=DEFAULT_RECOVERY_REPORT)
    parser.add_argument("--cut-source-report", type=Path, default=DEFAULT_CUT_SOURCE_REPORT)
    parser.add_argument("--external-cut-policy-report", type=Path)
    parser.add_argument("--db", type=Path)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        recovery_report=args.recovery_report,
        cut_source_report=args.cut_source_report,
        sqlite_db=args.db,
        external_cut_policy_report=args.external_cut_policy_report,
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
