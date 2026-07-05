#!/usr/bin/env python3
"""Audit Brain in a Jar as a deckbuilding hypothesis, not only runtime work.

Brain in a Jar now has a prepared runtime/package path, but the protected
Lorehold 607 baseline can only be challenged by a named same-lane cut, active
rule evidence, refreshed matrix scoring, and later battle traces. This audit
joins the current Brain preflight, PG package preflight, 607 value model, and
external deckbuilding evidence into one read-only stop/go decision.
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

DEFAULT_BRAIN_PREFLIGHT = (
    REPORT_DIR
    / "lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_post_authorized_full_validation.json"
)
DEFAULT_BRAIN_PG_PACKAGE = (
    REPORT_DIR
    / "lorehold_brain_in_a_jar_pg_package_preflight_20260705_post_authorized_full_validation.json"
)
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_brain_safe_cut_gap_audit_20260705_post_authorized_full_validation"
)

BRAIN = "Brain in a Jar"
TARGET_RUNTIME_PREFLIGHT_STATUS = (
    "brain_in_a_jar_runtime_cut_preflight_blocked_adapter_present_no_active_rule_no_safe_cut_keep_607"
)
TARGET_ACTIVE_RULE_PREFLIGHT_STATUS = (
    "brain_in_a_jar_runtime_cut_preflight_blocked_no_safe_cut_keep_607"
)
LEGACY_TARGET_ROUTE_PLANNER_STATUS = "miracle_next_route_planner_selected_brain_package_review_keep_607"
TARGET_ROUTE_PLANNER_STATUS = (
    "miracle_next_route_planner_selected_brain_floor_protected_no_seed_safe_cut_keep_607"
)
TARGET_ROUTE_PLANNER_STATUSES = {TARGET_ROUTE_PLANNER_STATUS, LEGACY_TARGET_ROUTE_PLANNER_STATUS}
TARGET_NEXT_SHELL_STATUS = "next_shell_cut_path_closed_route_miracle_access_first_keep_607"
TOPDECK_CORE_ANCHORS = {
    "Sensei's Divining Top",
    "Scroll Rack",
    "Library of Leng",
}

EXTERNAL_RESEARCH_SNAPSHOT = {
    "generated_from_current_web_check": "2026-07-05",
    "edhrec_brain_card_page": {
        "url": "https://edhrec.com/cards/brain-in-a-jar",
        "global_inclusion_percent": 0.03,
        "global_deck_count": 2490,
        "global_total_decks": 9280000,
        "lorehold_inclusion_percent": 0.4,
        "lorehold_deck_count": 35,
        "lorehold_total_decks": 9030,
        "interpretation": (
            "External adoption is a low-context signal for Lorehold, not a staple "
            "or auto-include signal."
        ),
    },
    "edhrec_lorehold_article": {
        "url": "https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander",
        "imported_lesson": (
            "Lorehold wants top-library manipulation; Sensei's Divining Top, "
            "Scroll Rack, and Library of Leng are named key cards."
        ),
        "named_anchors": sorted(TOPDECK_CORE_ANCHORS),
    },
    "edhrec_spellslinger_guide": {
        "url": "https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander",
        "imported_lesson": (
            "A streamlined primary plan can add one or two packages only when "
            "they still synergize with Plan A."
        ),
    },
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


def as_float(value: Any) -> float:
    try:
        return float(value or 0)
    except (TypeError, ValueError):
        return 0.0


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def blocker_values(row: Mapping[str, Any]) -> list[str]:
    blockers: list[str] = []
    for key in ("blockers", "hard_stop_blockers", "soft_evidence_blockers", "other_blockers"):
        blockers.extend(str(item) for item in as_list(row.get(key)) if item)
    return sorted(set(blockers))


def external_signal_classification(snapshot: Mapping[str, Any]) -> str:
    brain = as_dict(snapshot.get("edhrec_brain_card_page"))
    global_inclusion = as_float(brain.get("global_inclusion_percent"))
    lorehold_inclusion = as_float(brain.get("lorehold_inclusion_percent"))
    if global_inclusion < 1.0 and lorehold_inclusion < 1.0:
        return "low_context_signal_not_staple"
    if lorehold_inclusion >= 10.0:
        return "commander_specific_high_adoption_signal"
    return "contextual_signal_requires_same_lane_cut"


def cut_category(row: Mapping[str, Any]) -> str:
    name = str(row.get("card_name") or "")
    lanes = {str(lane) for lane in as_list(row.get("lanes"))}
    blockers = set(blocker_values(row))
    if name == "Lorehold, the Historian" or "commander_never_cut" in blockers:
        return "never_cut_commander"
    if (
        "mana_base" in lanes
        or "land" in lanes
        or "never_cut_lane" in blockers
        or "mana_base_never_cut" in blockers
    ):
        return "never_cut_mana_base"
    if name in TOPDECK_CORE_ANCHORS:
        return "protected_core_topdeck_engine"
    if "cut_is_early_mana_floor_support" in blockers or "early_mana_floor_support" in blockers:
        return "protected_structural_floor"
    if "structural_dependency" in blockers:
        return "protected_structural_dependency"
    if "prior_rejected_cut" in blockers or "prior_rejected_cut_slot" in blockers:
        return "prior_rejected_protected_slot"
    if bool(row.get("protected_anchor")) or "protected_cut" in blockers:
        return "protected_high_exposure_anchor"
    if str(row.get("scout_status") or "") == "safe_same_lane_cut_candidate":
        return "seed_safe_same_lane_candidate"
    return "blocked_unclassified_same_lane"


def unlock_requirements(
    row: Mapping[str, Any],
    *,
    active_rule_count: int,
    package_apply_ready: bool,
    package_apply_executed: bool,
) -> list[str]:
    category = cut_category(row)
    if category in {"never_cut_commander", "never_cut_mana_base"}:
        return ["cannot_unlock_under_current_607_contract"]
    requirements: list[str] = []
    if active_rule_count <= 0:
        if package_apply_ready and not package_apply_executed:
            requirements.append("explicit_postgresql_apply_then_postcheck_active_brain_rule")
        else:
            requirements.append("active_verified_brain_battle_rule")
    if str(row.get("scout_status") or "") != "safe_same_lane_cut_candidate":
        requirements.append("named_same_lane_seed_safe_cut_evidence")
    if category == "protected_core_topdeck_engine":
        requirements.append("replacement_preserves_topdeck_miracle_anchor_role")
    if category == "protected_structural_floor":
        requirements.append("replacement_preserves_mana_or_curve_floor")
    if category == "protected_structural_dependency":
        requirements.append("replacement_preserves_dependent_package")
    if category == "prior_rejected_protected_slot":
        requirements.append("new_trace_evidence_reverses_prior_rejected_cut")
    if category == "protected_high_exposure_anchor":
        requirements.append("equal_gate_trace_proves_lower_exposure_than_current_slot")
    requirements.append("refresh_candidate_queue_and_strategy_matrix")
    requirements.append("only_after_matrix_run_materialize_candidate_for_equal_battle_gate")
    return requirements


def enriched_cut_rows(
    *,
    brain_preflight: Mapping[str, Any],
    active_rule_count: int,
    package_apply_ready: bool,
    package_apply_executed: bool,
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    source_rows = as_list(brain_preflight.get("same_lane_cut_rows"))
    if not source_rows:
        source_rows = (
            as_list(brain_preflight.get("blocked_same_lane_cut_rows"))
            + as_list(brain_preflight.get("safe_same_lane_cut_candidates"))
        )
    for raw in source_rows:
        if not isinstance(raw, Mapping):
            continue
        row = dict(raw)
        row["blockers"] = blocker_values(row)
        row["gap_category"] = cut_category(row)
        row["unlock_requirements"] = unlock_requirements(
            row,
            active_rule_count=active_rule_count,
            package_apply_ready=package_apply_ready,
            package_apply_executed=package_apply_executed,
        )
        rows.append(row)
    rows.sort(
        key=lambda row: (
            str(row.get("gap_category") or ""),
            as_int(row.get("unique_exposure_count")),
            str(row.get("card_name") or ""),
        )
    )
    return rows


def lowest_risk_diagnostic_candidate(rows: list[dict[str, Any]]) -> dict[str, Any]:
    excluded = {"never_cut_commander", "never_cut_mana_base"}
    candidates = [
        row
        for row in rows
        if row.get("gap_category") not in excluded
        and str(row.get("scout_status") or "") != "safe_same_lane_cut_candidate"
    ]
    if not candidates:
        return {}
    return min(
        candidates,
        key=lambda row: (
            as_int(row.get("unique_exposure_count")),
            as_int(row.get("direct_event_count")),
            str(row.get("card_name") or ""),
        ),
    )


def decision_status(
    *,
    active_rule_count: int,
    safe_cut_count: int,
    package_apply_ready: bool,
    package_apply_executed: bool,
    package_route_governed: bool,
) -> tuple[str, str, bool]:
    if active_rule_count <= 0 and safe_cut_count == 0:
        if package_apply_ready and not package_route_governed:
            return (
                "brain_safe_cut_gap_pg_package_route_not_governed_keep_607",
                "rerun_governed_brain_runtime_and_package_preflight",
                False,
            )
        if package_apply_ready and not package_apply_executed:
            return (
                "brain_safe_cut_gap_no_active_rule_no_seed_safe_cut_keep_607",
                "review_pg_package_then_request_explicit_apply_and_continue_cut_mining",
                False,
            )
        return (
            "brain_safe_cut_gap_runtime_or_pg_rule_missing_no_seed_safe_cut_keep_607",
            "finish_active_rule_path_and_continue_cut_mining",
            False,
        )
    if safe_cut_count == 0:
        return (
            "brain_safe_cut_gap_no_seed_safe_cut_keep_607",
            "mine_named_topdeck_engine_seed_safe_cut_before_matrix_scoring",
            False,
        )
    if active_rule_count <= 0:
        return (
            "brain_safe_cut_gap_rule_not_active_no_battle",
            "activate_brain_rule_after_explicit_pg_approval_then_refresh_matrix",
            False,
        )
    return (
        "brain_safe_cut_gap_ready_for_candidate_matrix_no_battle",
        "refresh_candidate_queue_and_matrix_no_deck_materialization_yet",
        True,
    )


def package_runtime_preflight_governed(package_summary: Mapping[str, Any]) -> bool:
    return (
        package_summary.get("runtime_preflight_status") == TARGET_RUNTIME_PREFLIGHT_STATUS
        and bool(package_summary.get("runtime_preflight_route_gate_valid"))
        and package_summary.get("runtime_preflight_route_planner_status") in TARGET_ROUTE_PLANNER_STATUSES
        and bool(package_summary.get("runtime_preflight_candidate_queue_governed"))
        and package_summary.get("runtime_preflight_candidate_queue_next_shell_status")
        == TARGET_NEXT_SHELL_STATUS
        and bool(package_summary.get("runtime_preflight_candidate_queue_matrix_route_governed"))
    )


def current_runtime_preflight_governed(preflight_summary: Mapping[str, Any]) -> bool:
    return (
        preflight_summary.get("decision_status") == TARGET_ACTIVE_RULE_PREFLIGHT_STATUS
        and bool(preflight_summary.get("route_gate_valid"))
        and preflight_summary.get("route_planner_status") in TARGET_ROUTE_PLANNER_STATUSES
        and bool(preflight_summary.get("route_planner_candidate_queue_governed"))
        and preflight_summary.get("route_planner_candidate_queue_next_shell_status")
        == TARGET_NEXT_SHELL_STATUS
        and bool(preflight_summary.get("candidate_queue_matrix_route_governed"))
        and bool(preflight_summary.get("brain_exact_adapter_present"))
        and as_int(preflight_summary.get("brain_active_rule_count")) > 0
        and as_int(preflight_summary.get("safe_cut_count")) == 0
        and not bool(preflight_summary.get("postgres_writes_allowed_now"))
        and not bool(preflight_summary.get("deck_action_allowed_now"))
        and not bool(preflight_summary.get("natural_battle_gate_allowed_now"))
        and not bool(preflight_summary.get("promotion_allowed_now"))
    )


def build_report(
    *,
    brain_preflight: Mapping[str, Any],
    brain_pg_package: Mapping[str, Any],
    value_model: Mapping[str, Any],
    external_snapshot: Mapping[str, Any] = EXTERNAL_RESEARCH_SNAPSHOT,
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    preflight_summary = summary(brain_preflight)
    package_summary = summary(brain_pg_package)
    active_rule_count_from_preflight = as_int(preflight_summary.get("brain_active_rule_count"))
    active_rule_count = as_int(
        active_rule_count_from_preflight
        or package_summary.get("brain_active_rule_count_before_apply")
    )
    package_apply_ready = bool(package_summary.get("apply_ready_for_manual_review"))
    package_apply_executed = bool(package_summary.get("apply_executed_by_this_script"))
    postgres_rule_active_confirmed_now = active_rule_count_from_preflight > 0
    package_route_governed = package_runtime_preflight_governed(
        package_summary
    ) or current_runtime_preflight_governed(preflight_summary)
    rows = enriched_cut_rows(
        brain_preflight=brain_preflight,
        active_rule_count=active_rule_count,
        package_apply_ready=package_apply_ready,
        package_apply_executed=package_apply_executed,
    )
    safe_rows = [
        row for row in rows if str(row.get("scout_status") or "") == "safe_same_lane_cut_candidate"
    ]
    blocked_rows = [row for row in rows if row not in safe_rows]
    diagnostic_candidate = lowest_risk_diagnostic_candidate(rows)
    status, next_action, matrix_allowed = decision_status(
        active_rule_count=active_rule_count,
        safe_cut_count=len(safe_rows),
        package_apply_ready=package_apply_ready,
        package_apply_executed=package_apply_executed,
        package_route_governed=package_route_governed,
    )
    category_counts = Counter(str(row.get("gap_category") or "") for row in rows)
    blocker_counts = Counter(blocker for row in rows for blocker in as_list(row.get("blockers")))
    external_class = external_signal_classification(external_snapshot)
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_brain_safe_cut_gap_audit",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": status,
            "brain_pg_package_status": brain_pg_package.get("status") or "",
            "apply_ready_for_manual_review": package_apply_ready,
            "apply_executed_by_this_script": package_apply_executed,
            "postgres_rule_active_confirmed_now": postgres_rule_active_confirmed_now,
            "apply_confirmed_outside_package_script": (
                postgres_rule_active_confirmed_now and not package_apply_executed
            ),
            "brain_pg_package_route_governed": package_route_governed,
            "runtime_preflight_status": preflight_summary.get("decision_status")
            or package_summary.get("runtime_preflight_status")
            or "",
            "runtime_preflight_route_gate_valid": bool(
                preflight_summary.get("route_gate_valid")
                or package_summary.get("runtime_preflight_route_gate_valid")
            ),
            "runtime_preflight_route_planner_status": package_summary.get(
                "runtime_preflight_route_planner_status"
            )
            or preflight_summary.get("route_planner_status")
            or "",
            "runtime_preflight_candidate_queue_governed": bool(
                preflight_summary.get("route_planner_candidate_queue_governed")
                or package_summary.get("runtime_preflight_candidate_queue_governed")
            ),
            "runtime_preflight_candidate_queue_next_shell_status": package_summary.get(
                "runtime_preflight_candidate_queue_next_shell_status"
            )
            or preflight_summary.get("route_planner_candidate_queue_next_shell_status")
            or "",
            "runtime_preflight_candidate_queue_matrix_route_governed": bool(
                preflight_summary.get("candidate_queue_matrix_route_governed")
                or package_summary.get("runtime_preflight_candidate_queue_matrix_route_governed")
            ),
            "brain_active_rule_count": active_rule_count,
            "brain_exact_adapter_present": bool(package_summary.get("brain_exact_adapter_present")),
            "brain_oracle_hash": package_summary.get("oracle_hash") or "",
            "safe_cut_count": len(safe_rows),
            "blocked_same_lane_cut_count": len(blocked_rows),
            "same_lane_candidate_count": len(rows),
            "gap_category_counts": dict(sorted(category_counts.items())),
            "top_blocker_counts": dict(blocker_counts.most_common(12)),
            "external_signal_classification": external_class,
            "external_brain_global_inclusion_percent": as_float(
                as_dict(external_snapshot.get("edhrec_brain_card_page")).get("global_inclusion_percent")
            ),
            "external_brain_lorehold_inclusion_percent": as_float(
                as_dict(external_snapshot.get("edhrec_brain_card_page")).get("lorehold_inclusion_percent")
            ),
            "lowest_risk_diagnostic_cut_candidate": diagnostic_candidate.get("card_name") or "",
            "lowest_risk_diagnostic_cut_category": diagnostic_candidate.get("gap_category") or "",
            "lowest_risk_diagnostic_allowed_now": False,
            "matrix_scoring_allowed_now": matrix_allowed,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "postgres_writes_allowed_now": False,
            "deck_action_allowed_now": False,
            "recommended_next_action": next_action,
        },
        "external_research_snapshot": external_snapshot,
        "brain_preflight_summary": preflight_summary,
        "brain_pg_package_summary": package_summary,
        "value_model_summary": summary(value_model),
        "safe_same_lane_cut_candidates": safe_rows,
        "blocked_same_lane_cut_rows": blocked_rows,
        "same_lane_cut_rows": rows,
        "lowest_risk_diagnostic_candidate": diagnostic_candidate,
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "matrix_scoring_allowed_now": matrix_allowed,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "postgres_writes_allowed": False,
            "external_signal_is_staple_proof": False,
            "named_safe_cut_required_before_scoring": len(safe_rows) == 0,
            "active_rule_required_before_battle": active_rule_count <= 0,
            "pg_apply_requires_explicit_approval": active_rule_count <= 0 and package_apply_ready,
            "lowest_risk_diagnostic_allowed": False,
            "reason": (
                "Brain in a Jar now has an active PostgreSQL-backed runtime rule, "
                "but its current external adoption is low-context and every protected-607 "
                "same-lane slot remains blocked. Deck 607 therefore remains the Lorehold "
                "champion until a named seed-safe cut and matrix score exist."
            )
            if active_rule_count > 0
            else (
                "Brain in a Jar is a useful runtime/deckbuilding lesson, but its current "
                "external adoption is low-context, all protected-607 same-lane slots are "
                "blocked, and no active PostgreSQL-backed Brain rule exists. Deck 607 "
                "therefore remains the Lorehold champion."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_materialize_brain_candidate_deck",
                "do_not_run_natural_battle_for_brain_from_this_audit",
                next_action,
                "find_or_generate_named_same_lane_cut_evidence_before_matrix_scoring",
                "after_rule_and_cut_exist_rerun_brain_preflight_then_candidate_queue",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    lines = [
        "# Lorehold Brain in a Jar Safe-Cut Gap Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Brain PG package status: `{summary_row['brain_pg_package_status'] or '-'}`",
        f"- Apply ready for manual review: `{str(summary_row['apply_ready_for_manual_review']).lower()}`",
        f"- Apply executed by this script: `{str(summary_row['apply_executed_by_this_script']).lower()}`",
        "- PostgreSQL rule active confirmed now: "
        f"`{str(summary_row['postgres_rule_active_confirmed_now']).lower()}`",
        "- Apply confirmed outside package script: "
        f"`{str(summary_row['apply_confirmed_outside_package_script']).lower()}`",
        f"- Brain PG package route governed: `{str(summary_row['brain_pg_package_route_governed']).lower()}`",
        f"- Runtime preflight status: `{summary_row['runtime_preflight_status'] or '-'}`",
        f"- Runtime route gate valid: `{str(summary_row['runtime_preflight_route_gate_valid']).lower()}`",
        f"- Runtime route planner status: `{summary_row['runtime_preflight_route_planner_status'] or '-'}`",
        "- Runtime candidate queue governed: "
        f"`{str(summary_row['runtime_preflight_candidate_queue_governed']).lower()}`",
        "- Runtime candidate queue next-shell status: "
        f"`{summary_row['runtime_preflight_candidate_queue_next_shell_status'] or '-'}`",
        "- Runtime candidate queue matrix-route governed: "
        f"`{str(summary_row['runtime_preflight_candidate_queue_matrix_route_governed']).lower()}`",
        f"- Active Brain rule count: `{summary_row['brain_active_rule_count']}`",
        f"- Safe same-lane cuts: `{summary_row['safe_cut_count']}`",
        f"- Blocked same-lane cuts: `{summary_row['blocked_same_lane_cut_count']}`",
        f"- External signal classification: `{summary_row['external_signal_classification']}`",
        f"- Brain EDHREC global inclusion: `{summary_row['external_brain_global_inclusion_percent']}%`",
        f"- Brain EDHREC Lorehold inclusion: `{summary_row['external_brain_lorehold_inclusion_percent']}%`",
        f"- Lowest-risk diagnostic cut candidate: `{summary_row['lowest_risk_diagnostic_cut_candidate'] or '-'}`",
        f"- Diagnostic cut allowed now: `{str(summary_row['lowest_risk_diagnostic_allowed_now']).lower()}`",
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
    lines.extend(["", "## External Research Snapshot", ""])
    external = as_dict(payload.get("external_research_snapshot"))
    brain = as_dict(external.get("edhrec_brain_card_page"))
    lorehold = as_dict(external.get("edhrec_lorehold_article"))
    spellslinger = as_dict(external.get("edhrec_spellslinger_guide"))
    lines.append(f"- Brain card page: {brain.get('url') or '-'}")
    lines.append(
        "- Brain adoption: `{global_pct}%` global (`{global_count}` / `{global_total}` decks), "
        "`{lorehold_pct}%` in Lorehold (`{lorehold_count}` / `{lorehold_total}` decks).".format(
            global_pct=brain.get("global_inclusion_percent"),
            global_count=brain.get("global_deck_count"),
            global_total=brain.get("global_total_decks"),
            lorehold_pct=brain.get("lorehold_inclusion_percent"),
            lorehold_count=brain.get("lorehold_deck_count"),
            lorehold_total=brain.get("lorehold_total_decks"),
        )
    )
    lines.append(f"- Lorehold article: {lorehold.get('url') or '-'}")
    lines.append(f"- Lorehold topdeck anchors: `{', '.join(as_list(lorehold.get('named_anchors')))}`")
    lines.append(f"- Spellslinger guide: {spellslinger.get('url') or '-'}")
    lines.append(f"- Imported package rule: {spellslinger.get('imported_lesson') or '-'}")
    lines.extend(["", "## Gap Categories", ""])
    for category, count in sorted(as_dict(summary_row.get("gap_category_counts")).items()):
        lines.append(f"- `{category}`: `{count}`")
    lines.extend(["", "## Same-Lane Cut Rows", ""])
    lines.append("| Cut | Category | Exposure | Status | Unlock requirements |")
    lines.append("| --- | --- | ---: | --- | --- |")
    for row in as_list(payload.get("same_lane_cut_rows"))[:18]:
        lines.append(
            "| {card} | `{category}` | {exposure} | `{status}` | {requirements} |".format(
                card=row.get("card_name") or "",
                category=row.get("gap_category") or "",
                exposure=row.get("unique_exposure_count") or 0,
                status=row.get("scout_status") or "",
                requirements=", ".join(as_list(row.get("unlock_requirements"))) or "-",
            )
        )
    lines.extend(["", "## Decision", ""])
    decision = as_dict(payload.get("decision"))
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- external_signal_is_staple_proof: `{str(decision['external_signal_is_staple_proof']).lower()}`")
    lines.append(f"- named_safe_cut_required_before_scoring: `{str(decision['named_safe_cut_required_before_scoring']).lower()}`")
    lines.append(f"- active_rule_required_before_battle: `{str(decision['active_rule_required_before_battle']).lower()}`")
    lines.append(f"- pg_apply_requires_explicit_approval: `{str(decision['pg_apply_requires_explicit_approval']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
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
    parser.add_argument("--brain-preflight", type=Path, default=DEFAULT_BRAIN_PREFLIGHT)
    parser.add_argument("--brain-pg-package", type=Path, default=DEFAULT_BRAIN_PG_PACKAGE)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "brain_preflight": args.brain_preflight,
        "brain_pg_package": args.brain_pg_package,
        "value_model": args.value_model,
    }
    payload = build_report(
        brain_preflight=read_json(args.brain_preflight),
        brain_pg_package=read_json(args.brain_pg_package),
        value_model=read_json(args.value_model),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
