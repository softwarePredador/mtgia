#!/usr/bin/env python3
"""Classify what would unlock a Brain in a Jar cut without touching deck 607.

The safe-cut gap audit already proves that Brain in a Jar has no active
PostgreSQL-backed rule and no seed-safe same-lane cut. This read-only audit
turns that blocker into a learning queue: which current 607 slots are closed
forever, which need topdeck/role-preservation evidence, which need mana-floor
evidence, and which prior-rejected rows can only be diagnostic until new trace
evidence reverses the old decision.
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

DEFAULT_SAFE_CUT_GAP = REPORT_DIR / "lorehold_brain_safe_cut_gap_audit_20260705_current.json"
DEFAULT_FLOOR_TRACE = REPORT_DIR / "lorehold_gap_floor_trace_miner_20260705_current.json"
DEFAULT_CURRENT_BEST = (
    REPORT_DIR / "lorehold_current_best_baseline_synthesis_20260705_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_brain_seed_safe_cut_unlock_audit_20260705_current"
)

HARD_CLOSED_CATEGORIES = {
    "never_cut_commander",
    "never_cut_mana_base",
}

TOPDECK_ANCHOR_CATEGORIES = {
    "protected_core_topdeck_engine",
}

STRUCTURAL_FLOOR_CATEGORIES = {
    "protected_structural_floor",
    "protected_structural_dependency",
}

PRIOR_REJECTED_CATEGORIES = {
    "prior_rejected_protected_slot",
}

EXTERNAL_DECKBUILDING_LESSONS = [
    {
        "source": "EDHREC Lorehold commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "lesson": (
            "Lorehold's public profile is Topdeck, Spellslinger, and Discard; "
            "high-synergy topdeck anchors include Library of Leng, Sensei's "
            "Divining Top, and Scroll Rack."
        ),
        "guardrail": "External adoption discovers lanes; it is not local cut proof.",
    },
    {
        "source": "Wizards Commander Brackets Beta",
        "url": "https://magic.wizards.com/en/news/announcements/introducing-commander-brackets-beta",
        "lesson": (
            "Mana Vault and The One Ring are treated as Game Changers because "
            "fast mana and overwhelming resource advantage can change table power."
        ),
        "guardrail": (
            "A Game Changer label raises review burden; it does not bypass the "
            "607 same-lane cut and battle gates."
        ),
    },
    {
        "source": "Official Commander banned list",
        "url": "https://mtgcommander.net/index.php/banned-list/",
        "lesson": "Legality and bracket pressure are separate checks.",
        "guardrail": "Legal cards still need role fit, cut safety, and trace evidence.",
    },
]

DOWNSTREAM_REQUIREMENTS = {
    "refresh_candidate_queue_and_strategy_matrix",
    "battle_gate_only_after_matrix_candidate",
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


def source_rows(safe_cut_gap: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = as_list(safe_cut_gap.get("same_lane_cut_rows"))
    if not rows:
        rows = (
            as_list(safe_cut_gap.get("safe_same_lane_cut_candidates"))
            + as_list(safe_cut_gap.get("blocked_same_lane_cut_rows"))
        )
    return [dict(row) for row in rows if isinstance(row, Mapping)]


def floor_trace_index(floor_trace: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(row.get("card_name") or ""): dict(row)
        for row in as_list(floor_trace.get("target_floor_summaries"))
        if isinstance(row, Mapping) and row.get("card_name")
    }


def unlock_class(row: Mapping[str, Any]) -> str:
    category = str(row.get("gap_category") or "")
    blockers = {str(item) for item in as_list(row.get("blockers"))}
    if category in HARD_CLOSED_CATEGORIES:
        return "locked_no_unlock_current_607_contract"
    if "commander_never_cut" in blockers or "mana_base_never_cut" in blockers:
        return "locked_no_unlock_current_607_contract"
    if str(row.get("scout_status") or "") == "safe_same_lane_cut_candidate":
        return "seed_safe_cut_candidate_after_rule_review"
    if category in PRIOR_REJECTED_CATEGORIES:
        return "diagnostic_only_prior_reject_requires_new_trace"
    if category in TOPDECK_ANCHOR_CATEGORIES:
        return "protected_topdeck_anchor_requires_role_preservation"
    if category in STRUCTURAL_FLOOR_CATEGORIES:
        return "protected_floor_requires_floor_replacement_trace"
    if bool(row.get("protected_anchor")) or "protected_cut" in blockers:
        return "protected_anchor_requires_equal_or_better_trace"
    return "blocked_same_lane_requires_seed_safe_evidence"


def role_requirement(row: Mapping[str, Any]) -> str:
    category = str(row.get("gap_category") or "")
    lanes = {str(item) for item in as_list(row.get("lanes"))}
    if category in HARD_CLOSED_CATEGORIES:
        return "not_applicable_never_cut_slot"
    if "mana_base" in lanes or "land" in lanes:
        return "preserve_mana_base_slot_and_land_floor"
    if category in TOPDECK_ANCHOR_CATEGORIES or "topdeck_miracle_engine" in lanes:
        return "preserve_topdeck_miracle_access_or_discard_to_top_role"
    if category in STRUCTURAL_FLOOR_CATEGORIES:
        return "preserve_mana_curve_or_package_floor"
    if "draw" in lanes:
        return "preserve_draw_filter_or_card_flow_role"
    if "ramp" in lanes:
        return "preserve_early_mana_floor"
    return "declare_same_lane_role_and_preserve_floor"


def missing_evidence(
    row: Mapping[str, Any],
    *,
    active_rule_count: int,
    apply_ready: bool,
    apply_executed: bool,
    floor_summary: Mapping[str, Any],
) -> list[str]:
    klass = unlock_class(row)
    if klass == "locked_no_unlock_current_607_contract":
        return ["cannot_unlock_under_current_607_contract"]

    missing: list[str] = []
    if active_rule_count <= 0:
        if apply_ready and not apply_executed:
            missing.append("explicit_pg_apply_approval_and_postcheck_active_brain_rule")
        else:
            missing.append("active_verified_brain_rule")
    if str(row.get("scout_status") or "") != "safe_same_lane_cut_candidate":
        missing.append("named_same_lane_seed_safe_cut_evidence")
    if not floor_summary and str(row.get("scout_status") or "") != "safe_same_lane_cut_candidate":
        missing.append("targeted_floor_trace_for_this_cut_slot")
    if klass == "diagnostic_only_prior_reject_requires_new_trace":
        missing.append("new_trace_evidence_reverses_prior_rejected_cut")
    if klass == "protected_topdeck_anchor_requires_role_preservation":
        missing.append("replacement_preserves_topdeck_miracle_anchor_role")
    if klass == "protected_floor_requires_floor_replacement_trace":
        missing.append("replacement_preserves_mana_or_curve_floor")
    if klass == "protected_anchor_requires_equal_or_better_trace":
        missing.append("equal_or_better_same_seed_trace_than_current_slot")
    missing.append("refresh_candidate_queue_and_strategy_matrix")
    missing.append("battle_gate_only_after_matrix_candidate")
    return missing


def learning_action(row: Mapping[str, Any], klass: str) -> str:
    if klass == "locked_no_unlock_current_607_contract":
        return "do_not_use_as_brain_cut_under_current_607_contract"
    if klass == "diagnostic_only_prior_reject_requires_new_trace":
        return "mine_new_trace_evidence_before_reopening_prior_rejected_cut"
    if klass == "protected_topdeck_anchor_requires_role_preservation":
        return "prove_replacement_preserves_topdeck_miracle_anchor_before_matrix"
    if klass == "protected_floor_requires_floor_replacement_trace":
        return "collect_floor_replacement_trace_before_matrix"
    if klass == "seed_safe_cut_candidate_after_rule_review":
        return "review_after_active_brain_rule_then_refresh_matrix_only"
    if "draw" in {str(item) for item in as_list(row.get("lanes"))}:
        return "build_draw_filter_same_lane_cut_model_before_any_candidate"
    return "build_named_same_lane_cut_model_before_any_candidate"


def enriched_rows(
    *,
    safe_cut_gap: Mapping[str, Any],
    floor_trace: Mapping[str, Any],
) -> list[dict[str, Any]]:
    gap_summary = summary(safe_cut_gap)
    active_rule_count = as_int(gap_summary.get("brain_active_rule_count"))
    apply_ready = bool(gap_summary.get("apply_ready_for_manual_review"))
    apply_executed = bool(gap_summary.get("apply_executed_by_this_script"))
    floor_by_name = floor_trace_index(floor_trace)
    rows: list[dict[str, Any]] = []
    for raw in source_rows(safe_cut_gap):
        name = str(raw.get("card_name") or "")
        floor_summary = floor_by_name.get(name, {})
        klass = unlock_class(raw)
        missing = missing_evidence(
            raw,
            active_rule_count=active_rule_count,
            apply_ready=apply_ready,
            apply_executed=apply_executed,
            floor_summary=floor_summary,
        )
        blocking_missing = [
            item for item in missing if item not in DOWNSTREAM_REQUIREMENTS
        ]
        rows.append(
            {
                "card_name": name,
                "gap_category": raw.get("gap_category") or "",
                "unlock_class": klass,
                "role_requirement": role_requirement(raw),
                "scout_status": raw.get("scout_status") or "",
                "cut_lane": raw.get("cut_lane") or "",
                "functional_tag": raw.get("functional_tag") or "",
                "lanes": as_list(raw.get("lanes")),
                "blockers": as_list(raw.get("blockers")),
                "unique_exposure_count": as_int(raw.get("unique_exposure_count")),
                "direct_event_count": as_int(raw.get("direct_event_count")),
                "value_score": as_int(raw.get("value_score")),
                "value_tier": raw.get("value_tier") or "",
                "protected_anchor": bool(raw.get("protected_anchor")),
                "floor_trace_available": bool(floor_summary),
                "floor_trace_status": floor_summary.get("floor_trace_status") or "",
                "floor_trace_count": as_int(
                    floor_summary.get("same_slot_607_win_candidate_loss_trace_count")
                ),
                "positive_floor_delta_trace_count": as_int(
                    floor_summary.get("positive_target_delta_trace_count")
                ),
                "can_unlock_now": not blocking_missing,
                "blocking_missing_evidence": blocking_missing,
                "missing_evidence": missing,
                "learning_action": learning_action(raw, klass),
            }
        )
    rows.sort(
        key=lambda row: (
            0
            if row["unlock_class"] == "diagnostic_only_prior_reject_requires_new_trace"
            else 1
            if row["unlock_class"] == "protected_topdeck_anchor_requires_role_preservation"
            else 2
            if row["unlock_class"] == "protected_floor_requires_floor_replacement_trace"
            else 3
            if row["unlock_class"] == "seed_safe_cut_candidate_after_rule_review"
            else 8
            if row["unlock_class"] == "locked_no_unlock_current_607_contract"
            else 4,
            row["unique_exposure_count"],
            row["card_name"],
        )
    )
    return rows


def choose_diagnostic_focus(rows: list[dict[str, Any]]) -> dict[str, Any]:
    candidates = [
        row
        for row in rows
        if row["unlock_class"] == "diagnostic_only_prior_reject_requires_new_trace"
    ]
    if not candidates:
        return {}
    return min(candidates, key=lambda row: (row["unique_exposure_count"], row["card_name"]))


def decision_status(*, missing_inputs: list[str], unlockable_now_count: int, matrix_allowed: bool) -> str:
    if missing_inputs:
        return "brain_seed_safe_cut_unlock_audit_missing_inputs_keep_607"
    if unlockable_now_count > 0 and matrix_allowed:
        return "brain_seed_safe_cut_unlock_audit_reviewable_cut_exists_matrix_only"
    return "brain_seed_safe_cut_unlock_audit_closed_no_unlockable_cut_keep_607"


def build_report(
    *,
    safe_cut_gap: Mapping[str, Any],
    floor_trace: Mapping[str, Any],
    current_best: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    missing_inputs = [name for name, payload in {
        "safe_cut_gap": safe_cut_gap,
        "floor_trace": floor_trace,
        "current_best": current_best,
    }.items() if not payload]
    gap_summary = summary(safe_cut_gap)
    current_best_summary = summary(current_best)
    rows = enriched_rows(safe_cut_gap=safe_cut_gap, floor_trace=floor_trace)
    class_counts = Counter(row["unlock_class"] for row in rows)
    unlockable_now_count = sum(1 for row in rows if row["can_unlock_now"])
    matrix_allowed = (
        unlockable_now_count > 0
        and as_int(gap_summary.get("brain_active_rule_count")) > 0
        and bool(gap_summary.get("matrix_scoring_allowed_now"))
    )
    status = decision_status(
        missing_inputs=missing_inputs,
        unlockable_now_count=unlockable_now_count,
        matrix_allowed=matrix_allowed,
    )
    diagnostic_focus = choose_diagnostic_focus(rows)
    target_floor_missing_count = sum(
        1 for row in rows if "targeted_floor_trace_for_this_cut_slot" in row["missing_evidence"]
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_brain_seed_safe_cut_unlock_audit",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": status,
            "missing_inputs": missing_inputs,
            "brain_safe_cut_gap_status": gap_summary.get("decision_status") or "",
            "brain_pg_package_status": gap_summary.get("brain_pg_package_status") or "",
            "brain_active_rule_count": as_int(gap_summary.get("brain_active_rule_count")),
            "brain_apply_ready_for_manual_review": bool(
                gap_summary.get("apply_ready_for_manual_review")
            ),
            "brain_apply_executed_by_this_script": bool(
                gap_summary.get("apply_executed_by_this_script")
            ),
            "brain_pg_package_route_governed": bool(
                gap_summary.get("brain_pg_package_route_governed")
            ),
            "safe_cut_count": as_int(gap_summary.get("safe_cut_count")),
            "blocked_same_lane_cut_count": as_int(
                gap_summary.get("blocked_same_lane_cut_count")
            ),
            "slot_count": len(rows),
            "unlockable_now_count": unlockable_now_count,
            "unlock_class_counts": dict(sorted(class_counts.items())),
            "diagnostic_focus_card": diagnostic_focus.get("card_name") or "",
            "diagnostic_focus_unlock_class": diagnostic_focus.get("unlock_class") or "",
            "targeted_floor_trace_missing_slot_count": target_floor_missing_count,
            "current_best_status": current_best_summary.get("decision_status") or "",
            "current_best_top_deck_is_607": bool(current_best_summary.get("top_deck_is_607")),
            "current_best_protected_baseline_rank": as_int(
                current_best_summary.get("protected_baseline_rank")
            ),
            "matrix_scoring_allowed_now": matrix_allowed,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "postgres_writes_allowed_now": False,
            "deck_action_allowed_now": False,
            "recommended_next_action": (
                "mine_targeted_same_lane_cut_traces_or_request_pg_apply_review_separately"
            ),
        },
        "external_deckbuilding_lessons": EXTERNAL_DECKBUILDING_LESSONS,
        "source_summaries": {
            "safe_cut_gap": gap_summary,
            "floor_trace": summary(floor_trace),
            "current_best": current_best_summary,
        },
        "unlock_rows": rows,
        "diagnostic_focus": diagnostic_focus,
        "decision": {
            "keep_607_as_protected_baseline": True,
            "brain_cut_unlocked_now": unlockable_now_count > 0,
            "matrix_scoring_allowed_now": matrix_allowed,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "postgres_writes_allowed": False,
            "deck_action_allowed": False,
            "pg_apply_requires_explicit_approval": (
                as_int(gap_summary.get("brain_active_rule_count")) <= 0
                and bool(gap_summary.get("apply_ready_for_manual_review"))
            ),
            "reason": (
                "No Brain in a Jar seed-safe cut is unlocked. Current slots are "
                "either never-cut, protected anchors/floors, or prior-rejected "
                "diagnostic rows that need new trace evidence before matrix scoring."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_materialize_brain_candidate_deck",
                "do_not_run_natural_battle_from_this_audit",
                "keep_pg_apply_as_explicit_manual_approval_only",
                "mine_targeted_floor_trace_for_brain_cut_slots",
                "reopen_prior_rejected_slots_only_with_new_same_lane_trace_evidence",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    lines = [
        "# Lorehold Brain in a Jar Seed-Safe Cut Unlock Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Brain safe-cut gap status: `{summary_row['brain_safe_cut_gap_status']}`",
        f"- Active Brain rule count: `{summary_row['brain_active_rule_count']}`",
        f"- Brain PG package route governed: `{str(summary_row['brain_pg_package_route_governed']).lower()}`",
        f"- Safe cut count: `{summary_row['safe_cut_count']}`",
        f"- Unlockable now: `{summary_row['unlockable_now_count']}`",
        f"- Diagnostic focus: `{summary_row['diagnostic_focus_card'] or '-'}`",
        f"- Targeted floor trace missing slots: `{summary_row['targeted_floor_trace_missing_slot_count']}`",
        f"- Current best status: `{summary_row['current_best_status']}`",
        f"- Current best top deck is 607: `{str(summary_row['current_best_top_deck_is_607']).lower()}`",
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
    lines.extend(["", "## External Deckbuilding Lessons", ""])
    for lesson in as_list(payload.get("external_deckbuilding_lessons")):
        lines.append(
            "- {source}: {lesson} Guardrail: {guardrail} ({url})".format(
                source=lesson.get("source") or "",
                lesson=lesson.get("lesson") or "",
                guardrail=lesson.get("guardrail") or "",
                url=lesson.get("url") or "",
            )
        )
    lines.extend(["", "## Unlock Classes", ""])
    for klass, count in sorted(as_dict(summary_row.get("unlock_class_counts")).items()):
        lines.append(f"- `{klass}`: `{count}`")
    lines.extend(["", "## Slot Queue", ""])
    lines.append("| Slot | Unlock class | Role requirement | Exposure | Floor trace | Missing evidence | Action |")
    lines.append("| --- | --- | --- | ---: | --- | --- | --- |")
    for row in as_list(payload.get("unlock_rows")):
        missing = ", ".join(as_list(row.get("missing_evidence"))) or "-"
        floor_status = row.get("floor_trace_status") or (
            "available" if row.get("floor_trace_available") else "missing"
        )
        lines.append(
            "| {card} | `{klass}` | {role} | {exposure} | `{floor}` | {missing} | {action} |".format(
                card=row.get("card_name") or "",
                klass=row.get("unlock_class") or "",
                role=row.get("role_requirement") or "",
                exposure=row.get("unique_exposure_count") or 0,
                floor=floor_status,
                missing=missing,
                action=row.get("learning_action") or "",
            )
        )
    lines.extend(["", "## Decision", ""])
    decision = as_dict(payload.get("decision"))
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- brain_cut_unlocked_now: `{str(decision['brain_cut_unlocked_now']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- pg_apply_requires_explicit_approval: `{str(decision['pg_apply_requires_explicit_approval']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append("- next_actions:")
    for action in as_list(decision.get("next_actions")):
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
    parser.add_argument("--safe-cut-gap", type=Path, default=DEFAULT_SAFE_CUT_GAP)
    parser.add_argument("--floor-trace", type=Path, default=DEFAULT_FLOOR_TRACE)
    parser.add_argument("--current-best", type=Path, default=DEFAULT_CURRENT_BEST)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "current_best": args.current_best,
        "floor_trace": args.floor_trace,
        "safe_cut_gap": args.safe_cut_gap,
    }
    payload = build_report(
        safe_cut_gap=read_json(args.safe_cut_gap),
        floor_trace=read_json(args.floor_trace),
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
