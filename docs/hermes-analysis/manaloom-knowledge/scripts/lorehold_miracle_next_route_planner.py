#!/usr/bin/env python3
"""Choose the next Lorehold miracle-access learning route without deck action.

This planner consumes the current candidate queue, runtime contracts, Entreat
same-lane scout, and protected-607 cut evidence. It does not score a candidate
deck, mutate deck 607, run battle, or write PostgreSQL. Its job is to prevent
the learning loop from repeating a blocked route and to name the next concrete
deckbuilding lesson.
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

DEFAULT_POST_IDENTITY = REPORT_DIR / "lorehold_post_identity_queue_split_20260705_post_authorized_full_validation.json"
DEFAULT_RUNTIME_CONTRACT = (
    REPORT_DIR / "lorehold_brain_entreat_haze_runtime_contract_20260705_post_authorized_full_validation.json"
)
DEFAULT_CANDIDATE_QUEUE = (
    REPORT_DIR
    / "lorehold_miracle_access_candidate_row_queue_20260705_post_authorized_full_validation.json"
)
DEFAULT_ENTREAT_SCOUT = (
    REPORT_DIR / "lorehold_entreat_same_lane_cut_scout_20260705_post_authorized_full_validation.json"
)
DEFAULT_CUT_MINER = (
    REPORT_DIR / "lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json"
)
DEFAULT_BRAIN_SAFE_CUT_GAP = (
    REPORT_DIR / "lorehold_brain_safe_cut_gap_audit_20260705_post_authorized_full_validation.json"
)
DEFAULT_BRAIN_UNLOCK_AUDIT = (
    REPORT_DIR / "lorehold_brain_seed_safe_cut_unlock_audit_20260705_post_authorized_full_validation.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_miracle_next_route_planner_20260705_post_authorized_full_validation"
)

ENTREAT = "Entreat the Angels"
BRAIN = "Brain in a Jar"
HAZE = "Haze of Rage"
TARGET_NEXT_SHELL_STATUS = "next_shell_cut_path_closed_route_miracle_access_first_keep_607"
TARGET_MATRIX_CONTRACT = "miracle_access_first_shell_contract"
BRAIN_PACKAGE_ROUTE_STATUS = "brain_safe_cut_gap_no_active_rule_no_seed_safe_cut_keep_607"
BRAIN_UNLOCK_AUDIT_STATUS = "brain_seed_safe_cut_unlock_audit_closed_no_unlockable_cut_keep_607"
BRAIN_ROUTE_PLANNER_STATUS = "miracle_next_route_planner_selected_brain_package_review_keep_607"
BRAIN_ROUTE_PLANNER_ACTION = (
    "review_brain_pg_package_then_request_explicit_apply_or_continue_seed_safe_cut_mining_no_deck_action"
)
BRAIN_FLOOR_PROTECTED_ROUTE_STATE = "brain_floor_traces_protect_all_cut_slots_no_seed_safe_cut"
BRAIN_FLOOR_PROTECTED_ROUTE_PLANNER_STATUS = (
    "miracle_next_route_planner_selected_brain_floor_protected_no_seed_safe_cut_keep_607"
)
BRAIN_FLOOR_PROTECTED_ROUTE_PLANNER_ACTION = (
    "continue_seed_safe_cut_discovery_or_request_explicit_brain_pg_apply_review_no_deck_action"
)

LANE_BASE_SCORE = {
    "miracle_finisher": 96,
    "topdeck_miracle_access": 94,
    "storm_combo_pressure": 88,
    "spell_scry_pressure": 66,
    "rummage_pressure_access": 62,
}

EXTERNAL_EVIDENCE = {
    BRAIN: {
        "source_lane": "official_card_text_and_rulings",
        "links": {
            "scryfall": "https://scryfall.com/card/soi/252/brain-in-a-jar",
            "gatherer": "https://gatherer.wizards.com/SOI/en-us/252/brain-in-a-jar",
        },
        "learning_signal": (
            "charge-counter timing, exact mana-value free casting, and scry form a "
            "single-card runtime lesson for miracle/topdeck access"
        ),
    },
    HAZE: {
        "source_lane": "combo_reference_corpus",
        "links": {
            "scryfall": "https://scryfall.com/card/fut/100/haze-of-rage",
            "gatherer": "https://gatherer.wizards.com/FUT/en-us/100/haze-of-rage",
            "commander_spellbook": "https://commanderspellbook.com/combo/3940-5195/",
        },
        "learning_signal": (
            "Commander Spellbook validates Haze plus Storm-Kiln Artist as a combo "
            "package, but package evidence is not a one-for-one 607 inclusion"
        ),
    },
    ENTREAT: {
        "source_lane": "official_card_text_and_generated_runtime_package",
        "links": {
            "scryfall": "https://scryfall.com/search?as=text&q=%21%22Entreat+the+Angels%22",
            "gatherer": "https://gatherer.wizards.com/search?cardName=Entreat_the_Angels",
        },
        "learning_signal": (
            "X miracle token finishing is aligned with the Lorehold thesis, but the "
            "current gate is named cut safety plus applied rule evidence"
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


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def by_card(rows: list[Any], *name_fields: str) -> dict[str, dict[str, Any]]:
    indexed: dict[str, dict[str, Any]] = {}
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        for field in name_fields:
            name = str(row.get(field) or "")
            if name:
                indexed[name] = dict(row)
                break
    return indexed


def candidate_cards(post_identity: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in as_list(post_identity.get("cards")):
        if not isinstance(row, Mapping):
            continue
        if row.get("in_607"):
            continue
        if row.get("battle_ready_now"):
            continue
        if row.get("lane") in LANE_BASE_SCORE:
            rows.append(dict(row))
    rows.sort(
        key=lambda row: (
            as_int(row.get("priority_rank")) if row.get("priority_rank") is not None else 99,
            str(row.get("card_name") or ""),
        )
    )
    return rows


def candidate_queue_route_governed(candidate_summary: Mapping[str, Any]) -> bool:
    return bool(
        candidate_summary.get("matrix_route_governed") is True
        and candidate_summary.get("matrix_next_shell_status") == TARGET_NEXT_SHELL_STATUS
        and candidate_summary.get("matrix_fallback_route_key") == TARGET_MATRIX_CONTRACT
        and candidate_summary.get("candidate_deck_materialization_allowed_now") is False
        and candidate_summary.get("natural_battle_gate_allowed_now") is False
        and candidate_summary.get("promotion_allowed_now") is False
    )


def brain_unlock_floor_protected(brain_unlock_summary: Mapping[str, Any]) -> bool:
    return bool(
        brain_unlock_summary
        and brain_unlock_summary.get("decision_status") == BRAIN_UNLOCK_AUDIT_STATUS
        and bool(brain_unlock_summary.get("brain_pg_package_route_governed"))
        and as_int(brain_unlock_summary.get("brain_active_rule_count")) == 0
        and as_int(brain_unlock_summary.get("safe_cut_count")) == 0
        and as_int(brain_unlock_summary.get("unlockable_now_count")) == 0
        and as_int(brain_unlock_summary.get("targeted_floor_trace_missing_slot_count")) == 0
        and not bool(brain_unlock_summary.get("matrix_scoring_allowed_now"))
        and not bool(brain_unlock_summary.get("candidate_deck_materialization_allowed_now"))
        and not bool(brain_unlock_summary.get("natural_battle_gate_allowed_now"))
        and not bool(brain_unlock_summary.get("promotion_allowed_now"))
        and not bool(brain_unlock_summary.get("deck_action_allowed_now"))
    )


def route_state(
    *,
    card: Mapping[str, Any],
    contract: Mapping[str, Any],
    candidate_row: Mapping[str, Any],
    entreat_summary: Mapping[str, Any],
    brain_summary: Mapping[str, Any],
    brain_unlock_summary: Mapping[str, Any],
) -> tuple[str, str]:
    name = str(card.get("card_name") or "")
    blockers = {str(item) for item in as_list(card.get("blockers"))}
    blockers.update(str(item) for item in as_list(candidate_row.get("blockers")))
    active_rules = max(
        as_int(contract.get("active_rule_count")),
        as_int(entreat_summary.get("entreat_active_rule_count")),
    )
    if name == ENTREAT:
        if as_int(entreat_summary.get("safe_cut_count")) == 0:
            return (
                "parked_entreat_no_safe_cut",
                "keep Entreat parked until a named same-lane cut is seed-safe",
            )
        if not entreat_summary.get("postgres_writes_executed") or active_rules <= 0:
            return (
                "parked_entreat_rule_not_active",
                "apply Entreat rule only through approved PG package, then refresh queue",
            )
        return (
            "resume_entreat_matrix_refresh",
            "refresh candidate queue and structure matrix before any battle",
        )
    if name == BRAIN:
        if brain_unlock_floor_protected(brain_unlock_summary):
            return (
                BRAIN_FLOOR_PROTECTED_ROUTE_STATE,
                BRAIN_FLOOR_PROTECTED_ROUTE_PLANNER_ACTION,
            )
        if brain_summary:
            if not bool(brain_summary.get("brain_pg_package_route_governed")):
                return (
                    "blocked_brain_package_route_not_governed",
                    "rerun_governed_brain_runtime_package_and_safe_cut_gap",
                )
            if (
                brain_summary.get("decision_status") == BRAIN_PACKAGE_ROUTE_STATUS
                and brain_summary.get("brain_pg_package_status") == "prepared_read_only_pending_apply_approval"
                and bool(brain_summary.get("apply_ready_for_manual_review"))
                and not bool(brain_summary.get("apply_executed_by_this_script"))
                and as_int(brain_summary.get("brain_active_rule_count")) == 0
                and as_int(brain_summary.get("safe_cut_count")) == 0
            ):
                return (
                    "brain_package_prepared_no_active_rule_no_seed_safe_cut",
                    BRAIN_ROUTE_PLANNER_ACTION,
                )
            if as_int(brain_summary.get("brain_active_rule_count")) > 0 and as_int(
                brain_summary.get("safe_cut_count")
            ) == 0:
                return (
                    "brain_rule_active_no_seed_safe_cut",
                    "mine_named_brain_same_lane_seed_safe_cut_no_deck_action",
                )
        return (
            "next_single_card_runtime_lesson",
            "draft Brain in a Jar runtime contract and cut miner, no deck action",
        )
    if name == HAZE:
        return (
            "combo_package_runtime_lesson",
            "draft Haze plus Storm-Kiln Artist combo runtime contract after Brain lane",
        )
    if "named_safe_cut_missing" in blockers or "verified_battle_rule_missing" in blockers:
        return (
            "defer_lower_priority_runtime_review",
            "defer until core miracle-access runtime and cut lanes produce evidence",
        )
    return ("manual_review_required", "review after higher-priority lanes are resolved")


def score_route(
    *,
    card: Mapping[str, Any],
    contract: Mapping[str, Any],
    candidate_row: Mapping[str, Any],
    entreat_summary: Mapping[str, Any],
    cut_summary: Mapping[str, Any],
    brain_summary: Mapping[str, Any],
    brain_unlock_summary: Mapping[str, Any],
) -> int:
    name = str(card.get("card_name") or "")
    lane = str(card.get("lane") or "")
    blockers = {str(item) for item in as_list(card.get("blockers"))}
    blockers.update(str(item) for item in as_list(candidate_row.get("blockers")))
    score = LANE_BASE_SCORE.get(lane, 40)
    score -= as_int(card.get("priority_rank")) * 2
    if contract.get("xmage_class_found"):
        score += 8
    if name in EXTERNAL_EVIDENCE:
        score += 8
    if name == BRAIN:
        score += 14
        if brain_summary.get("decision_status") == BRAIN_PACKAGE_ROUTE_STATUS:
            score += 6
    if name == HAZE:
        score += 12
        score -= 18
    if name == ENTREAT:
        if entreat_summary.get("runtime_primitive_ready"):
            score += 12
        if (
            as_int(entreat_summary.get("safe_cut_count")) > 0
            and entreat_summary.get("postgres_writes_executed")
            and as_int(entreat_summary.get("entreat_active_rule_count")) > 0
        ):
            score += 30
        if as_int(entreat_summary.get("safe_cut_count")) == 0:
            score -= 36
        if not entreat_summary.get("postgres_writes_executed"):
            score -= 18
        score -= 16
    if "verified_battle_rule_missing" in blockers:
        score -= 10
    if "named_safe_cut_missing" in blockers or as_int(cut_summary.get("named_seed_safe_cut_count")) == 0:
        score -= 8
    if "combo_runtime_required" in blockers:
        score -= 10
    return score


def build_route_rows(
    *,
    post_identity: Mapping[str, Any],
    runtime_contract: Mapping[str, Any],
    candidate_queue: Mapping[str, Any],
    entreat_scout: Mapping[str, Any],
    cut_miner: Mapping[str, Any],
    brain_safe_cut_gap: Mapping[str, Any],
    brain_unlock_audit: Mapping[str, Any],
) -> list[dict[str, Any]]:
    contract_index = by_card(as_list(runtime_contract.get("contracts")), "card_name")
    candidate_index = by_card(
        as_list(candidate_queue.get("candidate_rows"))
        + as_list(candidate_queue.get("blocked_candidate_rows")),
        "add_card",
        "card_name",
    )
    entreat_summary = summary(entreat_scout)
    cut_summary = summary(cut_miner)
    brain_summary = summary(brain_safe_cut_gap)
    brain_unlock_summary = summary(brain_unlock_audit)
    rows = []
    for card in candidate_cards(post_identity):
        name = str(card.get("card_name") or "")
        contract = contract_index.get(name, {})
        queue_row = candidate_index.get(name, {})
        state, next_action = route_state(
            card=card,
            contract=contract,
            candidate_row=queue_row,
            entreat_summary=entreat_summary,
            brain_summary=brain_summary,
            brain_unlock_summary=brain_unlock_summary,
        )
        score = score_route(
            card=card,
            contract=contract,
            candidate_row=queue_row,
            entreat_summary=entreat_summary,
            cut_summary=cut_summary,
            brain_summary=brain_summary,
            brain_unlock_summary=brain_unlock_summary,
        )
        blockers = sorted(
            {
                str(item)
                for item in as_list(card.get("blockers")) + as_list(queue_row.get("blockers"))
                if item
            }
        )
        rows.append(
            {
                "card_name": name,
                "lane": card.get("lane") or "",
                "priority_rank": as_int(card.get("priority_rank")),
                "route_class": card.get("route_class") or "",
                "required_contract": card.get("required_contract") or "",
                "route_state": state,
                "learning_score": score,
                "next_action": next_action,
                "blockers": blockers,
                "matrix_cells": as_list(queue_row.get("matrix_cells")),
                "active_rule_count": as_int(contract.get("active_rule_count")),
                "xmage_class_found": bool(contract.get("xmage_class_found")),
                "runtime_readiness": contract.get("readiness") or "missing_runtime_contract",
                "runtime_slice_count": len(as_list(contract.get("required_runtime_slices"))),
                "deckbuilding_value": card.get("deckbuilding_value") or "",
                "external_evidence": EXTERNAL_EVIDENCE.get(name, {}),
            }
        )
    return sorted(rows, key=lambda row: (-as_int(row.get("learning_score")), str(row.get("card_name") or "")))


def selectable(row: Mapping[str, Any]) -> bool:
    return str(row.get("route_state") or "") in {
        "next_single_card_runtime_lesson",
        "brain_package_prepared_no_active_rule_no_seed_safe_cut",
        BRAIN_FLOOR_PROTECTED_ROUTE_STATE,
        "brain_rule_active_no_seed_safe_cut",
        "combo_package_runtime_lesson",
        "resume_entreat_matrix_refresh",
    }


def select_route(rows: list[dict[str, Any]]) -> dict[str, Any]:
    for row in rows:
        if selectable(row):
            return row
    return {}


def decision_status(
    selected: Mapping[str, Any],
    rows: list[Mapping[str, Any]],
    *,
    candidate_queue_governed: bool,
) -> tuple[str, str]:
    if not candidate_queue_governed:
        return (
            "miracle_next_route_planner_blocked_candidate_queue_not_governed_keep_607",
            "rerun_routed_candidate_row_queue_before_route_selection",
        )
    if not rows:
        return (
            "miracle_next_route_planner_blocked_no_candidates_keep_607",
            "refresh post-identity candidate sources before more deckbuilding work",
        )
    if not selected:
        return (
            "miracle_next_route_planner_blocked_no_actionable_route_keep_607",
            "mine named safe cuts or runtime contracts before any deck action",
        )
    if selected.get("card_name") == BRAIN:
        if selected.get("route_state") == BRAIN_FLOOR_PROTECTED_ROUTE_STATE:
            return (
                BRAIN_FLOOR_PROTECTED_ROUTE_PLANNER_STATUS,
                BRAIN_FLOOR_PROTECTED_ROUTE_PLANNER_ACTION,
            )
        if selected.get("route_state") == "brain_package_prepared_no_active_rule_no_seed_safe_cut":
            return (
                BRAIN_ROUTE_PLANNER_STATUS,
                BRAIN_ROUTE_PLANNER_ACTION,
            )
        if selected.get("route_state") == "brain_rule_active_no_seed_safe_cut":
            return (
                "miracle_next_route_planner_selected_brain_seed_cut_mining_keep_607",
                "mine_named_brain_same_lane_seed_safe_cut_no_deck_action",
            )
        return (
            "miracle_next_route_planner_selected_brain_runtime_learning_keep_607",
            "draft_brain_in_a_jar_runtime_contract_and_cut_miner_no_deck_action",
        )
    if selected.get("card_name") == HAZE:
        return (
            "miracle_next_route_planner_selected_haze_combo_learning_keep_607",
            "draft_haze_storm_kiln_combo_contract_no_deck_action",
        )
    return (
        "miracle_next_route_planner_selected_entreat_refresh_keep_607",
        "refresh_entreat_candidate_queue_and_matrix_no_battle",
    )


def build_report(
    *,
    post_identity: Mapping[str, Any],
    runtime_contract: Mapping[str, Any],
    candidate_queue: Mapping[str, Any],
    entreat_scout: Mapping[str, Any],
    cut_miner: Mapping[str, Any],
    brain_safe_cut_gap: Mapping[str, Any],
    brain_unlock_audit: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    candidate_summary = summary(candidate_queue)
    candidate_queue_governed = candidate_queue_route_governed(candidate_summary)
    route_rows = build_route_rows(
        post_identity=post_identity,
        runtime_contract=runtime_contract,
        candidate_queue=candidate_queue,
        entreat_scout=entreat_scout,
        cut_miner=cut_miner,
        brain_safe_cut_gap=brain_safe_cut_gap,
        brain_unlock_audit=brain_unlock_audit,
    )
    selected = select_route(route_rows) if candidate_queue_governed else {}
    status, next_action = decision_status(
        selected,
        route_rows,
        candidate_queue_governed=candidate_queue_governed,
    )
    state_counts = Counter(str(row.get("route_state") or "") for row in route_rows)
    blocker_counts = Counter(blocker for row in route_rows for blocker in as_list(row.get("blockers")))
    brain_summary = summary(brain_safe_cut_gap)
    brain_unlock_summary = summary(brain_unlock_audit)
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_miracle_next_route_planner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "status": status,
        "summary": {
            "decision_status": status,
            "candidate_queue_status": candidate_summary.get("decision_status") or "",
            "candidate_queue_matrix_route_governed": candidate_queue_governed,
            "candidate_queue_matrix_next_shell_status": candidate_summary.get("matrix_next_shell_status") or "",
            "candidate_queue_matrix_fallback_route_key": candidate_summary.get("matrix_fallback_route_key") or "",
            "candidate_queue_scoreable_row_count": as_int(
                candidate_summary.get("scoreable_candidate_row_count")
            ),
            "route_candidate_count": len(route_rows),
            "selected_card": selected.get("card_name") or "",
            "selected_lane": selected.get("lane") or "",
            "selected_route_state": selected.get("route_state") or "",
            "selected_learning_score": as_int(selected.get("learning_score")),
            "entreat_safe_cut_count": as_int(summary(entreat_scout).get("safe_cut_count")),
            "entreat_active_rule_count": as_int(summary(entreat_scout).get("entreat_active_rule_count")),
            "brain_pg_package_status": brain_summary.get("brain_pg_package_status") or "",
            "brain_pg_package_route_governed": bool(brain_summary.get("brain_pg_package_route_governed")),
            "brain_apply_ready_for_manual_review": bool(brain_summary.get("apply_ready_for_manual_review")),
            "brain_apply_executed_by_this_script": bool(brain_summary.get("apply_executed_by_this_script")),
            "brain_active_rule_count": as_int(brain_summary.get("brain_active_rule_count")),
            "brain_safe_cut_count": as_int(brain_summary.get("safe_cut_count")),
            "brain_unlock_audit_status": brain_unlock_summary.get("decision_status") or "",
            "brain_unlockable_now_count": as_int(brain_unlock_summary.get("unlockable_now_count")),
            "brain_targeted_floor_trace_missing_slot_count": as_int(
                brain_unlock_summary.get("targeted_floor_trace_missing_slot_count")
            ),
            "brain_unlock_recommended_next_action": brain_unlock_summary.get("recommended_next_action") or "",
            "named_seed_safe_cut_count": as_int(summary(cut_miner).get("named_seed_safe_cut_count")),
            "candidate_deck_materialization_allowed_now": False,
            "matrix_scoring_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "postgres_writes_allowed_now": False,
            "state_counts": dict(sorted(state_counts.items())),
            "top_blocker_counts": dict(blocker_counts.most_common(12)),
            "recommended_next_action": next_action,
        },
        "selected_route": selected,
        "route_rows": route_rows,
        "source_evidence": {
            "post_identity_summary": summary(post_identity),
            "runtime_contract_summary": summary(runtime_contract),
            "candidate_queue_summary": candidate_summary,
            "entreat_scout_summary": summary(entreat_scout),
            "cut_miner_summary": summary(cut_miner),
            "brain_safe_cut_gap_summary": brain_summary,
            "brain_seed_safe_cut_unlock_summary": brain_unlock_summary,
            "external_sources_consulted": EXTERNAL_EVIDENCE,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "matrix_scoring_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "postgres_writes_allowed": False,
            "reason": (
                "The candidate queue is missing the governed matrix route, so the planner "
                "cannot select a runtime or cut lane."
            )
            if not candidate_queue_governed
            else (
                "Brain in a Jar now has targeted floor trace evidence for every current "
                "607 cut slot. That evidence protects the slots rather than unlocking a "
                "seed-safe cut, so the planner keeps 607 and routes only to continued "
                "learning or explicit PG review."
            )
            if selected.get("card_name") == BRAIN
            and selected.get("route_state") == BRAIN_FLOOR_PROTECTED_ROUTE_STATE
            else (
                "Brain in a Jar is no longer at the draft-runtime step: the current "
                "package is review-ready but still has no active PostgreSQL rule and "
                "no seed-safe cut. Deck 607 stays protected."
            )
            if selected.get("card_name") == BRAIN
            and selected.get("route_state") == "brain_package_prepared_no_active_rule_no_seed_safe_cut"
            else (
                "Entreat remains blocked by named safe-cut and unapplied-rule gates; "
                "Brain in a Jar is the next best learning route because it teaches "
                "charge-counter/free-cast/scry timing for the miracle-access thesis "
                "without mutating deck 607."
            )
            if selected.get("card_name") == BRAIN
            else (
                "A non-Brain route was selected because the current evidence made it "
                "the highest actionable learning path; deck action remains closed."
            )
            if selected
            else (
                "No route is actionable because the queue lacks candidates or every "
                "candidate is blocked before runtime or cut evidence."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_materialize_candidate_deck_from_route_planner_output",
                "do_not_run_natural_battle_from_route_planner_output",
                next_action,
                "rerun deckbuilding contract surface audit after generating the route report",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    lines = [
        "# Lorehold Miracle Next Route Planner",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Candidate queue status: `{summary_row['candidate_queue_status']}`",
        f"- Candidate queue matrix route governed: `{str(summary_row['candidate_queue_matrix_route_governed']).lower()}`",
        f"- Candidate queue matrix next-shell status: `{summary_row['candidate_queue_matrix_next_shell_status'] or '-'}`",
        f"- Route candidates: `{summary_row['route_candidate_count']}`",
        f"- Selected card: `{summary_row['selected_card'] or '-'}`",
        f"- Selected lane: `{summary_row['selected_lane'] or '-'}`",
        f"- Selected route state: `{summary_row['selected_route_state'] or '-'}`",
        f"- Selected learning score: `{summary_row['selected_learning_score']}`",
        f"- Entreat safe cuts: `{summary_row['entreat_safe_cut_count']}`",
        f"- Entreat active rules: `{summary_row['entreat_active_rule_count']}`",
        f"- Brain PG package status: `{summary_row['brain_pg_package_status'] or '-'}`",
        f"- Brain PG package route governed: `{str(summary_row['brain_pg_package_route_governed']).lower()}`",
        f"- Brain apply ready for manual review: `{str(summary_row['brain_apply_ready_for_manual_review']).lower()}`",
        f"- Brain apply executed by this script: `{str(summary_row['brain_apply_executed_by_this_script']).lower()}`",
        f"- Brain active rules: `{summary_row['brain_active_rule_count']}`",
        f"- Brain safe cuts: `{summary_row['brain_safe_cut_count']}`",
        f"- Brain unlock audit status: `{summary_row['brain_unlock_audit_status'] or '-'}`",
        f"- Brain unlockable now: `{summary_row['brain_unlockable_now_count']}`",
        f"- Brain targeted floor trace missing slots: `{summary_row['brain_targeted_floor_trace_missing_slot_count']}`",
        f"- Named seed-safe cuts: `{summary_row['named_seed_safe_cut_count']}`",
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
    lines.extend(["", "## Ranked Routes", ""])
    lines.append("| Card | Lane | State | Score | Runtime | Blockers |")
    lines.append("| --- | --- | --- | ---: | --- | --- |")
    for row in as_list(payload.get("route_rows")):
        lines.append(
            "| {card} | `{lane}` | `{state}` | {score} | `{runtime}` | `{blockers}` |".format(
                card=row.get("card_name") or "",
                lane=row.get("lane") or "",
                state=row.get("route_state") or "",
                score=row.get("learning_score") or 0,
                runtime=row.get("runtime_readiness") or "",
                blockers=", ".join(as_list(row.get("blockers"))) or "-",
            )
        )
    lines.extend(["", "## Selected Route", ""])
    selected = as_dict(payload.get("selected_route"))
    if selected:
        lines.append(f"- Card: `{selected.get('card_name')}`")
        lines.append(f"- Next action: `{selected.get('next_action')}`")
        lines.append(f"- Deckbuilding value: {selected.get('deckbuilding_value') or '-'}")
        evidence = as_dict(selected.get("external_evidence"))
        if evidence:
            lines.append(f"- External source lane: `{evidence.get('source_lane')}`")
            lines.append(f"- External learning signal: {evidence.get('learning_signal')}")
            for key, link in sorted(as_dict(evidence.get("links")).items()):
                lines.append(f"- {key}: {link}")
    else:
        lines.append("- None.")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- matrix_scoring_allowed_now: `{str(decision['matrix_scoring_allowed_now']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- postgres_writes_allowed: `{str(decision['postgres_writes_allowed']).lower()}`")
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
    parser.add_argument("--post-identity", type=Path, default=DEFAULT_POST_IDENTITY)
    parser.add_argument("--runtime-contract", type=Path, default=DEFAULT_RUNTIME_CONTRACT)
    parser.add_argument("--candidate-queue", type=Path, default=DEFAULT_CANDIDATE_QUEUE)
    parser.add_argument("--entreat-scout", type=Path, default=DEFAULT_ENTREAT_SCOUT)
    parser.add_argument("--cut-miner", type=Path, default=DEFAULT_CUT_MINER)
    parser.add_argument("--brain-safe-cut-gap", type=Path, default=DEFAULT_BRAIN_SAFE_CUT_GAP)
    parser.add_argument("--brain-unlock-audit", type=Path, default=DEFAULT_BRAIN_UNLOCK_AUDIT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "post_identity": args.post_identity,
        "runtime_contract": args.runtime_contract,
        "candidate_queue": args.candidate_queue,
        "entreat_scout": args.entreat_scout,
        "cut_miner": args.cut_miner,
        "brain_safe_cut_gap": args.brain_safe_cut_gap,
        "brain_unlock_audit": args.brain_unlock_audit,
    }
    payload = build_report(
        post_identity=read_json(args.post_identity),
        runtime_contract=read_json(args.runtime_contract),
        candidate_queue=read_json(args.candidate_queue),
        entreat_scout=read_json(args.entreat_scout),
        cut_miner=read_json(args.cut_miner),
        brain_safe_cut_gap=read_json(args.brain_safe_cut_gap),
        brain_unlock_audit=read_json(args.brain_unlock_audit),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
