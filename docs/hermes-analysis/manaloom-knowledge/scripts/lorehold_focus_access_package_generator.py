#!/usr/bin/env python3
"""Generate failure-targeted Lorehold focus-access package candidates.

This read-only helper converts the current planner, focus trace audit, and
variant gap miner into an explicit package queue. It is intentionally
conservative: an add/cut pair is gate-ready only when it targets a named failure
mode, avoids protected engine cards, skips exact prior negatives, has active or
materialized runtime support, and can be checked against the seed-42 anchor.
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_PLANNER = REPORT_DIR / "lorehold_next_action_planner_20260630_after_profiled_gate.json"
DEFAULT_TRACE_AUDIT = REPORT_DIR / "lorehold_failure_targeted_trace_audit_20260628_v3_focus_access.json"
DEFAULT_MINER_REPORT = REPORT_DIR / "lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json"
DEFAULT_DESIGN_REPORT = REPORT_DIR / "lorehold_focus_access_package_design_20260628_v1.md"
DEFAULT_SQUEE_PROBE = REPORT_DIR / "lorehold_squee_graveyard_entry_probe_20260628_v1.json"
DEFAULT_ACCESS_MODEL = REPORT_DIR / "lorehold_access_cut_model_20260630_post_pg276_assemble_the_players_squee_access_density.json"
DEFAULT_RUNTIME_GAP_QUEUE = (
    REPORT_DIR / "lorehold_runtime_gap_family_queue_20260630_post_pg276_assemble_the_players.json"
)
DEFAULT_HAND_FILTER_CUT_MODEL = (
    REPORT_DIR / "lorehold_hand_filter_cut_model_20260630_post_pg270_expanded607_search.json"
)

PROTECTED_CARDS = {
    "Urza's Saga",
    "Library of Leng",
    "Sensei's Divining Top",
    "Scroll Rack",
    "Squee, Goblin Nabob",
    "The Mind Stone",
    "Land Tax",
    "Boros Signet",
}

RUNTIME_READY_CANDIDATE_STATUSES = {
    "runtime_ready_unexplored",
    "high_frequency_runtime_ready_unexplored",
    "tested_negative_add_requires_new_cut",
}
READY_CUT_STATUSES = {
    "gate_ready",
    "gate_ready_cut",
    "preflight_ready",
    "preflight_benchmark_ready",
    "untested_flex_candidate",
}
READY_CUT_READINESS = {
    "gate_ready",
    "preflight_ready",
    "preflight_benchmark_ready",
    "safe_cut_ready",
}

FAILURE_MODE_BY_HYPOTHESIS = {
    "trace_seed7_engine_access_sequence": "seed7_missing_engine_access",
    "trace_seed20260625_conversion_window": "seed20260625_conversion_under_pressure",
    "audit_urzas_saga_artifact_tutor_scope": "saga_runtime_scope_review",
    "audit_squee_graveyard_entry_route": "squee_graveyard_entry_route",
}

FAILURE_MODE_BY_LANE = {
    "contextual": "seed7_missing_engine_access",
    "tutor_access": "seed7_missing_engine_access",
    "hand_filter": "seed20260625_conversion_under_pressure",
    "graveyard_recursion": "squee_graveyard_entry_route",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def ascii_fold(value: object) -> str:
    text = str(value or "")
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", ascii_fold(value).lower()).strip()


def card_key(value: object) -> str:
    return normalize_key(value)


def slug(value: object) -> str:
    return normalize_key(value).replace(" ", "_")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def package_key(add_card: str, cut_card: str) -> str:
    return f"{slug(add_card)}_cut_{slug(cut_card)}"


def protected_card_keys() -> set[str]:
    return {card_key(card) for card in PROTECTED_CARDS}


def prior_rejected_keys(planner_payload: dict[str, Any]) -> set[str]:
    summary = planner_payload.get("summary") or {}
    return {str(key) for key in summary.get("prior_rejected_package_keys") or [] if str(key).strip()}


def prior_negative_pairs(
    *,
    planner_payload: dict[str, Any],
    miner_report: dict[str, Any],
) -> tuple[set[str], dict[tuple[str, str], dict[str, Any]]]:
    rejected_keys = prior_rejected_keys(planner_payload)
    pairs: dict[tuple[str, str], dict[str, Any]] = {}

    def add_pair_evidence(row: dict[str, Any], source: object = None) -> None:
        package = str(row.get("package_key") or "")
        if package:
            rejected_keys.add(package)
        adds = [str(card) for card in row.get("adds") or [] if str(card).strip()]
        cuts = [str(card) for card in row.get("cuts") or [] if str(card).strip()]
        for add in adds:
            for cut in cuts:
                pairs[(card_key(add), card_key(cut))] = {
                    "package_key": package,
                    "source": source or row.get("source"),
                    "status": row.get("status"),
                    "delta_pp": row.get("delta_pp"),
                }

    for row in miner_report.get("negative_exact_packages") or []:
        add_pair_evidence(row)
    for source in planner_payload.get("prior_package_reports") or []:
        path = Path(str(source))
        if not path.exists():
            continue
        try:
            payload = read_json(path)
        except (OSError, json.JSONDecodeError):
            continue
        for row in payload.get("packages") or []:
            if not isinstance(row, dict):
                continue
            package = str(row.get("package_key") or "")
            if package not in rejected_keys and not package_decision_is_reject(row):
                continue
            add_pair_evidence(row, source=source)
    return rejected_keys, pairs


def package_decision_is_reject(row: dict[str, Any]) -> bool:
    decision = str(row.get("decision") or "")
    if decision.startswith("reject"):
        return True
    aggregate = row.get("aggregate") or {}
    aggregate_decision = str(aggregate.get("decision") or "")
    if aggregate_decision.startswith("reject"):
        return True
    gate = row.get("gate_summary") or {}
    baseline = gate.get("baseline") or {}
    candidate = gate.get("candidate") or {}
    delta = float(gate.get("delta_pp") or aggregate.get("delta_pp_total") or 0.0)
    baseline_wins = int(baseline.get("wins") or 0)
    candidate_wins = int(candidate.get("wins") or 0)
    return delta < 0 or candidate_wins < baseline_wins


def focus_failure_modes(trace_audit: dict[str, Any]) -> dict[str, dict[str, Any]]:
    modes: dict[str, dict[str, Any]] = {}
    for row in trace_audit.get("hypothesis_assessments") or []:
        hypothesis_key = str(row.get("hypothesis_key") or "")
        failure_mode = FAILURE_MODE_BY_HYPOTHESIS.get(hypothesis_key)
        if not failure_mode:
            continue
        modes[failure_mode] = {
            "failure_mode": failure_mode,
            "hypothesis_key": hypothesis_key,
            "trace_status": row.get("trace_status"),
            "target_seeds": [str(seed) for seed in row.get("target_seeds") or []],
            "focus_cards": [str(card) for card in row.get("focus_cards") or []],
            "next_action": row.get("next_action"),
            "current_limitations": row.get("current_limitations") or [],
        }
    return modes


def seed_42_anchor_available(trace_audit: dict[str, Any]) -> bool:
    records = trace_audit.get("primary_seed_records") or {}
    return "42" in records or 42 in records


def runtime_status(candidate_status: str) -> str:
    if candidate_status in RUNTIME_READY_CANDIDATE_STATUSES:
        return "active_or_materialized"
    if candidate_status == "blocked_runtime_rule_gap":
        return "blocked_runtime_rule_gap"
    return "unknown"


def target_failure_for_pairing(pairing: dict[str, Any], modes: dict[str, dict[str, Any]]) -> str | None:
    lane = str(pairing.get("lane") or "")
    candidate = normalize_key(pairing.get("candidate"))
    if candidate in {normalize_key("Gamble"), normalize_key("Enlightened Tutor")}:
        key = "seed7_missing_engine_access"
    else:
        key = FAILURE_MODE_BY_LANE.get(lane)
    if key and key in modes:
        return key
    return None


def is_cut_ready(cut_option: dict[str, Any]) -> bool:
    return (
        str(cut_option.get("status") or "") in READY_CUT_STATUSES
        or str(cut_option.get("gate_readiness") or "") in READY_CUT_READINESS
    )


def status_from_blockers(blockers: list[str]) -> str:
    if not blockers:
        return "gate_ready_focus_access_package"
    priority = [
        ("blocked_prior_negative_exact", "prior_negative_exact_match"),
        ("blocked_protected_cut", "protected_cut"),
        ("blocked_runtime_rule_gap", "runtime_status_not_active_or_materialized"),
        ("blocked_no_target_failure_mode", "missing_target_failure_mode"),
        ("blocked_seed42_anchor_missing", "missing_seed42_anchor"),
        ("blocked_no_safe_cut", "cut_not_gate_ready"),
    ]
    for status, blocker in priority:
        if blocker in blockers:
            return status
    return "trace_or_runtime_probe_required"


def evaluate_cut_option(
    *,
    pairing: dict[str, Any],
    cut_option: dict[str, Any],
    modes: dict[str, dict[str, Any]],
    rejected_keys: set[str],
    rejected_pairs: dict[tuple[str, str], dict[str, Any]],
    seed_42_available: bool,
) -> dict[str, Any]:
    add_card = str(pairing.get("candidate") or "")
    cut_card = str(cut_option.get("card_name") or "")
    key = package_key(add_card, cut_card)
    pair_key = (card_key(add_card), card_key(cut_card))
    prior_negative = key in rejected_keys or pair_key in rejected_pairs
    protected_cut = card_key(cut_card) in protected_card_keys()
    candidate_runtime_status = runtime_status(str(pairing.get("candidate_status") or ""))
    target_failure = target_failure_for_pairing(pairing, modes)
    blockers: list[str] = []
    if not target_failure:
        blockers.append("missing_target_failure_mode")
    if protected_cut:
        blockers.append("protected_cut")
    if prior_negative:
        blockers.append("prior_negative_exact_match")
    if candidate_runtime_status != "active_or_materialized":
        blockers.append("runtime_status_not_active_or_materialized")
    if not seed_42_available:
        blockers.append("missing_seed42_anchor")
    if not is_cut_ready(cut_option):
        blockers.append("cut_not_gate_ready")
    status = status_from_blockers(blockers)
    return {
        "package_key": key,
        "status": status,
        "add_card": add_card,
        "cut_card": cut_card,
        "lane": pairing.get("lane"),
        "candidate_score": pairing.get("candidate_score"),
        "candidate_status": pairing.get("candidate_status"),
        "runtime_status": candidate_runtime_status,
        "cut_status": cut_option.get("status"),
        "cut_gate_readiness": cut_option.get("gate_readiness"),
        "cut_readiness_reason": cut_option.get("readiness_reason"),
        "target_failure_mode": target_failure,
        "target_failure_evidence": modes.get(target_failure or "", {}),
        "protected_cards_avoided": not protected_cut,
        "prior_negative_exact_match": prior_negative,
        "prior_negative_evidence": rejected_pairs.get(pair_key),
        "seed_42_anchor_requirement": {
            "required": True,
            "available": seed_42_available,
            "pass_conditions": [
                "candidate must not regress the seed-42 record versus baseline",
                "miracle/topdeck telemetry must stay within the current seed-42 engine band",
                "any strong-seed regression rejects the package before broader gates",
            ],
        },
        "blockers": blockers,
    }


def evaluate_pairing_without_cut(
    *,
    pairing: dict[str, Any],
    modes: dict[str, dict[str, Any]],
    seed_42_available: bool,
) -> dict[str, Any]:
    candidate_runtime_status = runtime_status(str(pairing.get("candidate_status") or ""))
    target_failure = target_failure_for_pairing(pairing, modes)
    blockers = ["no_cut_option_from_miner"]
    if not target_failure:
        blockers.append("missing_target_failure_mode")
    if candidate_runtime_status != "active_or_materialized":
        blockers.append("runtime_status_not_active_or_materialized")
    if not seed_42_available:
        blockers.append("missing_seed42_anchor")
    return {
        "package_key": "",
        "status": "trace_or_runtime_probe_required",
        "add_card": pairing.get("candidate"),
        "cut_card": "",
        "lane": pairing.get("lane"),
        "candidate_score": pairing.get("candidate_score"),
        "candidate_status": pairing.get("candidate_status"),
        "runtime_status": candidate_runtime_status,
        "target_failure_mode": target_failure,
        "target_failure_evidence": modes.get(target_failure or "", {}),
        "protected_cards_avoided": True,
        "prior_negative_exact_match": False,
        "seed_42_anchor_requirement": {
            "required": True,
            "available": seed_42_available,
            "pass_conditions": [
                "candidate must not regress the seed-42 record versus baseline",
                "miracle/topdeck telemetry must stay within the current seed-42 engine band",
            ],
        },
        "blockers": blockers,
        "recommended_action": pairing.get("recommended_action"),
    }


def evaluate_pairings(
    *,
    miner_report: dict[str, Any],
    trace_audit: dict[str, Any],
    planner_payload: dict[str, Any],
) -> list[dict[str, Any]]:
    modes = focus_failure_modes(trace_audit)
    seed_42_available = seed_42_anchor_available(trace_audit)
    rejected_keys, rejected_pairs = prior_negative_pairs(
        planner_payload=planner_payload,
        miner_report=miner_report,
    )
    rows: list[dict[str, Any]] = []
    for pairing in miner_report.get("pairing_hypotheses") or []:
        cut_options = pairing.get("cut_options") or []
        if not cut_options:
            rows.append(
                evaluate_pairing_without_cut(
                    pairing=pairing,
                    modes=modes,
                    seed_42_available=seed_42_available,
                )
            )
            continue
        for cut_option in cut_options:
            rows.append(
                evaluate_cut_option(
                    pairing=pairing,
                    cut_option=cut_option,
                    modes=modes,
                    rejected_keys=rejected_keys,
                    rejected_pairs=rejected_pairs,
                    seed_42_available=seed_42_available,
                )
            )
    rows.sort(
        key=lambda row: (
            0 if row["status"] == "gate_ready_focus_access_package" else 1,
            str(row.get("status") or ""),
            -int(row.get("candidate_score") or 0),
            str(row.get("add_card") or ""),
            str(row.get("cut_card") or ""),
        )
    )
    return rows


def planner_runtime_action(planner_payload: dict[str, Any]) -> dict[str, Any] | None:
    for row in planner_payload.get("action_queue") or []:
        if row.get("action_key") == "batch_xmage_runtime_rule_gaps":
            return row
    return None


def squee_route_modeled(squee_probe: dict[str, Any] | None) -> bool:
    if not squee_probe:
        return False
    summary = squee_probe.get("summary") or {}
    return (
        summary.get("status") == "squee_route_modeled_but_access_gap_remains"
        and bool(summary.get("modeled_when_accessed"))
    )


def squee_work_item(
    *,
    squee_probe: dict[str, Any] | None,
    access_model: dict[str, Any] | None,
    modes: dict[str, dict[str, Any]],
    squee_probe_path: Path | None = None,
    access_model_path: Path | None = None,
) -> dict[str, Any]:
    mode = modes.get("squee_graveyard_entry_route") or {}
    if squee_route_modeled(squee_probe):
        summary = (squee_probe or {}).get("summary") or {}
        access_summary = (access_model or {}).get("summary") or {}
        weak_seeds = summary.get("weak_material_missing_squee_seeds") or []
        if access_summary:
            ready_count = int(access_summary.get("preflight_access_candidate_ready_count") or 0)
            hidden_runtime_status = str(
                access_summary.get("hidden_retreat_runtime_model_status") or ""
            )
            hidden_package_status = str(access_summary.get("hidden_retreat_package_status") or "")
            if hidden_runtime_status == "runtime_proposal_overlay_active" and ready_count == 0:
                reason = (
                    "Squee discard/return is modeled when accessed; Hidden Retreat is modeled "
                    "and PG271-synced, but access model found 0 preflight-ready access swaps. "
                    "Remaining blocker is a seed-safe cut model."
                )
                if hidden_package_status and hidden_package_status != "prepared_read_only_pending_apply_approval":
                    reason += f" Hidden Retreat package status: {hidden_package_status}."
            else:
                reason = (
                    "Squee discard/return is modeled when accessed; access model found "
                    f"{ready_count} preflight-ready access swaps and requires a new seed-safe "
                    "cut or runtime upgrade."
                )
        else:
            reason = (
                "Squee discard/return is modeled when accessed; the remaining blocker is access "
                f"or conversion in weak seeds: {', '.join(weak_seeds) or '-'}."
            )
        return {
            "work_key": "squee_access_density_model",
            "failure_mode": "squee_graveyard_entry_route",
            "reason": reason,
            "target_seeds": weak_seeds or mode.get("target_seeds", []),
            "evidence_report": str(squee_probe_path or ""),
            "access_model_report": str(access_model_path or "") if access_summary else "",
            "access_model_status": access_summary.get("access_density_status", ""),
            "preflight_access_candidate_ready_count": int(
                access_summary.get("preflight_access_candidate_ready_count") or 0
            ),
            "status": summary.get("status"),
        }
    return {
        "work_key": "squee_graveyard_entry_probe",
        "failure_mode": "squee_graveyard_entry_route",
        "reason": mode.get("next_action"),
        "target_seeds": mode.get("target_seeds", []),
    }


def instrumentation_route(
    *,
    package_candidates: list[dict[str, Any]],
    planner_payload: dict[str, Any],
    trace_audit: dict[str, Any],
    squee_probe: dict[str, Any] | None = None,
    access_model: dict[str, Any] | None = None,
    squee_probe_path: Path | None = None,
    access_model_path: Path | None = None,
) -> dict[str, Any]:
    gate_ready = [row for row in package_candidates if row["status"] == "gate_ready_focus_access_package"]
    if gate_ready:
        return {
            "status": "gate_ready_package_available",
            "next_action": "run_package_preflight_then_seed42_anchor_gate",
            "packages": [row["package_key"] for row in gate_ready],
        }
    modes = focus_failure_modes(trace_audit)
    runtime_action = planner_runtime_action(planner_payload)
    return {
        "status": "trace_or_runtime_probe_required",
        "next_action": "do_not_create_blind_swap; run focused trace/runtime/cut-model work first",
        "required_work": [
            squee_work_item(
                squee_probe=squee_probe,
                access_model=access_model,
                modes=modes,
                squee_probe_path=squee_probe_path,
                access_model_path=access_model_path,
            ),
            {
                "work_key": "contextual_tutor_cut_model",
                "failure_mode": "seed7_missing_engine_access",
                "reason": "Enlightened Tutor and Gamble have runtime support but no safe cut option.",
                "target_seeds": (modes.get("seed7_missing_engine_access") or {}).get("target_seeds", []),
            },
            {
                "work_key": "hand_filter_non_core_cut_search",
                "failure_mode": "seed20260625_conversion_under_pressure",
                "reason": "Hand-filter candidates only pair with protected same-lane support cuts.",
                "target_seeds": (modes.get("seed20260625_conversion_under_pressure") or {}).get(
                    "target_seeds", []
                ),
            },
            {
                "work_key": "runtime_rule_gap_batch",
                "failure_mode": "blocked_runtime_rule_gap",
                "reason": (runtime_action or {}).get("why_now"),
                "target_seeds": [],
            },
        ],
    }


def runtime_gap_context(runtime_gap_queue: dict[str, Any] | None) -> dict[str, Any]:
    if not runtime_gap_queue:
        return {}
    summary = runtime_gap_queue.get("summary") or {}
    validity = summary.get("validity_summary") or {}
    top_families = []
    for family in (runtime_gap_queue.get("family_queue") or [])[:5]:
        top_families.append(
            {
                "family_id": family.get("family_id"),
                "card_count": int(family.get("card_count") or 0),
                "support_status": family.get("support_status"),
                "batch_strategy": family.get("batch_strategy"),
                "candidate_lane_counts": family.get("candidate_lane_counts") or {},
                "promotion_lane_counts": family.get("promotion_lane_counts") or {},
                "sample_cards": [
                    card.get("card_name")
                    for card in (family.get("cards") or [])[:6]
                    if card.get("card_name")
                ],
            }
        )
    return {
        "blocked_runtime_rule_gap_count": int(summary.get("blocked_runtime_rule_gap_count") or 0),
        "ready_for_structured_pull_count": int(validity.get("ready_for_structured_pull_count") or 0),
        "exact_xmage_found_count": int(validity.get("exact_xmage_found_count") or 0),
        "family_count": int(summary.get("family_count") or 0),
        "promotion_lane_counts": summary.get("promotion_lane_counts") or {},
        "top_families": top_families,
    }


def blocked_rows_for_work(work_key: str, package_candidates: list[dict[str, Any]]) -> list[dict[str, Any]]:
    if work_key == "hand_filter_non_core_cut_search":
        return [
            row
            for row in package_candidates
            if row.get("target_failure_mode") == "seed20260625_conversion_under_pressure"
            and row.get("status") == "blocked_no_safe_cut"
            and "cut_not_gate_ready" in (row.get("blockers") or [])
        ]
    if work_key == "contextual_tutor_cut_model":
        return [
            row
            for row in package_candidates
            if row.get("target_failure_mode") == "seed7_missing_engine_access"
            and row.get("status") == "trace_or_runtime_probe_required"
        ]
    if work_key == "squee_access_density_model":
        return [
            row
            for row in package_candidates
            if row.get("target_failure_mode") == "squee_graveyard_entry_route"
            and row.get("status") in {"blocked_no_safe_cut", "blocked_protected_cut"}
        ]
    return []


def next_command_for_work(work_key: str) -> str:
    commands = {
        "squee_access_density_model": (
            "python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_access_cut_model.py "
            "--stem lorehold_access_cut_model_20260630_after_profiled_gate"
        ),
        "contextual_tutor_cut_model": (
            "python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_tutor_cut_model.py "
            "--stem lorehold_tutor_cut_model_20260630_after_profiled_gate"
        ),
        "hand_filter_non_core_cut_search": (
            "python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_hand_filter_cut_model.py "
            "--stem lorehold_hand_filter_cut_model_20260630_after_profiled_gate"
        ),
        "runtime_rule_gap_batch": (
            "python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_runtime_gap_family_queue.py "
            "--output-prefix docs/hermes-analysis/master_optimizer_reports/"
            "lorehold_runtime_gap_family_queue_20260630_post_pg276_assemble_the_players"
        ),
    }
    return commands.get(work_key, "")


def promotion_criteria_for_work(work_key: str) -> list[str]:
    criteria = {
        "squee_access_density_model": [
            "Find a non-protected access package that improves Squee/Top/Rack/Library reach.",
            "Preserve seed-42 Squee, miracle, and topdeck telemetry before broader gates.",
            "Use Hidden Retreat as PG271-synced if selected; do not rerun its PostgreSQL apply.",
        ],
        "contextual_tutor_cut_model": [
            "Find a tutor package that does not cut Land Tax, Thor, Creative Technique, or protected topdeck engines.",
            "Pass seed-7 access sequence review before any broader battle gate.",
            "Reject exact pairs with prior strong-seed regression.",
        ],
        "hand_filter_non_core_cut_search": [
            "Find a non-core hand-filter cut outside protected support slots.",
            "Reject Big Score, Esper Sentinel, Monument, Rise, and Artist's Talent cuts unless a same-lane benchmark proves safety.",
            "Target the seed-20260625 conversion-under-pressure failure explicitly.",
        ],
        "runtime_rule_gap_batch": [
            "Group blocked cards by XMage semantic family.",
            "Promote only cards with valid XMage source and a ManaLoom mapper/test scenario.",
            "Rerun the variant gap miner before using newly modeled cards in deck gates.",
        ],
    }
    return criteria.get(work_key, [])


def evidence_inputs_for_work(
    *,
    work_item: dict[str, Any],
    runtime_gap_path: Path | None,
    runtime_gap_summary: dict[str, Any],
    hand_filter_cut_model_path: Path | None,
    hand_filter_cut_model: dict[str, Any] | None,
) -> list[str]:
    inputs = [
        str(value)
        for value in (
            work_item.get("evidence_report"),
            work_item.get("access_model_report"),
        )
        if value
    ]
    work_key = str(work_item.get("work_key") or "")
    if work_key == "runtime_rule_gap_batch" and runtime_gap_summary and runtime_gap_path:
        inputs.append(str(runtime_gap_path))
    if work_key == "hand_filter_non_core_cut_search" and hand_filter_cut_model and hand_filter_cut_model_path:
        inputs.append(str(hand_filter_cut_model_path))
    return sorted(set(inputs))


def hand_filter_model_exhausted(hand_filter_cut_model: dict[str, Any] | None) -> bool:
    if not hand_filter_cut_model:
        return False
    summary = hand_filter_cut_model.get("summary") or {}
    return (
        summary.get("recommended_next_action")
        == "do_not_gate_hand_filter_without_new_cut_or_runtime_evidence"
        and int(summary.get("preflight_benchmark_ready_count") or 0) == 0
        and int(summary.get("expanded_preflight_benchmark_ready_count") or 0) == 0
    )


def build_operational_work_queue(
    *,
    instrumentation: dict[str, Any],
    package_candidates: list[dict[str, Any]],
    planner_payload: dict[str, Any],
    runtime_gap_queue: dict[str, Any] | None = None,
    runtime_gap_path: Path | None = DEFAULT_RUNTIME_GAP_QUEUE,
    hand_filter_cut_model: dict[str, Any] | None = None,
    hand_filter_cut_model_path: Path | None = DEFAULT_HAND_FILTER_CUT_MODEL,
) -> list[dict[str, Any]]:
    runtime_action = planner_runtime_action(planner_payload) or {}
    runtime_context = runtime_gap_context(runtime_gap_queue)
    rows: list[dict[str, Any]] = []
    for work_item in instrumentation.get("required_work") or []:
        work_key = str(work_item.get("work_key") or "")
        blocked_rows = blocked_rows_for_work(work_key, package_candidates)
        status_counts = Counter(row.get("status") for row in blocked_rows)
        runtime_card_count = 0
        runtime_ready_count = 0
        if work_key == "runtime_rule_gap_batch":
            runtime_card_count = int(
                runtime_context.get("blocked_runtime_rule_gap_count")
                or runtime_action.get("candidate_count")
                or 0
            )
            runtime_ready_count = int(runtime_context.get("ready_for_structured_pull_count") or 0)
        requires_pg_to_promote = (
            work_key == "squee_access_density_model"
            and "approved PG apply/sync" in str(work_item.get("reason") or "")
        )
        hand_filter_exhausted = work_key == "hand_filter_non_core_cut_search" and hand_filter_model_exhausted(
            hand_filter_cut_model
        )
        impact_score = len(blocked_rows) * 2
        if work_key == "runtime_rule_gap_batch":
            impact_score += runtime_card_count + runtime_ready_count * 5
        elif work_key == "hand_filter_non_core_cut_search":
            impact_score += 0 if hand_filter_exhausted else 20
        elif work_key == "contextual_tutor_cut_model":
            impact_score += 35
        elif work_key == "squee_access_density_model":
            impact_score += 25
        if requires_pg_to_promote:
            impact_score -= 8
        rows.append(
            {
                "work_key": work_key,
                "failure_mode": work_item.get("failure_mode"),
                "target_seeds": work_item.get("target_seeds") or [],
                "reason": work_item.get("reason") or "",
                "blocked_package_count": len(blocked_rows),
                "blocked_package_status_counts": dict(sorted(status_counts.items())),
                "blocked_package_samples": [
                    {
                        "package_key": row.get("package_key"),
                        "add_card": row.get("add_card"),
                        "cut_card": row.get("cut_card"),
                        "status": row.get("status"),
                    }
                    for row in blocked_rows[:5]
                ],
                "blocked_runtime_rule_gap_count": runtime_card_count,
                "runtime_ready_for_structured_pull_count": runtime_ready_count,
                "runtime_gap_context": runtime_context if work_key == "runtime_rule_gap_batch" else {},
                "postgres_write_required_to_run": False,
                "postgres_write_required_to_promote": requires_pg_to_promote,
                "next_command": (
                    "do_not_repeat_without_new_cut_or_runtime_evidence"
                    if hand_filter_exhausted
                    else next_command_for_work(work_key)
                ),
                "evidence_inputs": evidence_inputs_for_work(
                    work_item=work_item,
                    runtime_gap_path=runtime_gap_path,
                    runtime_gap_summary=runtime_context,
                    hand_filter_cut_model_path=hand_filter_cut_model_path,
                    hand_filter_cut_model=hand_filter_cut_model,
                ),
                "promotion_criteria": promotion_criteria_for_work(work_key),
                "impact_score": -1 if hand_filter_exhausted else impact_score,
                "status": (
                    "model_exhausted_do_not_repeat_without_new_evidence"
                    if hand_filter_exhausted
                    else (
                        "read_only_modeling_ready_pg_promotion_blocked"
                        if requires_pg_to_promote
                        else "actionable_modeling_required"
                    )
                ),
            }
        )
    rows.sort(
        key=lambda row: (
            -int(row.get("impact_score") or 0),
            str(row.get("work_key") or ""),
        )
    )
    for index, row in enumerate(rows, start=1):
        row["priority_rank"] = index
    return rows


def build_report(
    *,
    planner_payload: dict[str, Any],
    trace_audit: dict[str, Any],
    miner_report: dict[str, Any],
    squee_probe: dict[str, Any] | None = None,
    access_model: dict[str, Any] | None = None,
    runtime_gap_queue: dict[str, Any] | None = None,
    hand_filter_cut_model: dict[str, Any] | None = None,
    planner_path: Path = DEFAULT_PLANNER,
    trace_path: Path = DEFAULT_TRACE_AUDIT,
    miner_path: Path = DEFAULT_MINER_REPORT,
    design_path: Path = DEFAULT_DESIGN_REPORT,
    squee_probe_path: Path = DEFAULT_SQUEE_PROBE,
    access_model_path: Path = DEFAULT_ACCESS_MODEL,
    runtime_gap_path: Path = DEFAULT_RUNTIME_GAP_QUEUE,
    hand_filter_cut_model_path: Path = DEFAULT_HAND_FILTER_CUT_MODEL,
) -> dict[str, Any]:
    modes = focus_failure_modes(trace_audit)
    package_candidates = evaluate_pairings(
        miner_report=miner_report,
        trace_audit=trace_audit,
        planner_payload=planner_payload,
    )
    status_counts = Counter(row["status"] for row in package_candidates)
    gate_ready = [
        row for row in package_candidates if row["status"] == "gate_ready_focus_access_package"
    ]
    instrumentation = instrumentation_route(
        package_candidates=package_candidates,
        planner_payload=planner_payload,
        trace_audit=trace_audit,
        squee_probe=squee_probe,
        access_model=access_model,
        squee_probe_path=squee_probe_path,
        access_model_path=access_model_path,
    )
    operational_queue = build_operational_work_queue(
        instrumentation=instrumentation,
        package_candidates=package_candidates,
        planner_payload=planner_payload,
        runtime_gap_queue=runtime_gap_queue,
        runtime_gap_path=runtime_gap_path,
        hand_filter_cut_model=hand_filter_cut_model,
        hand_filter_cut_model_path=hand_filter_cut_model_path,
    )
    return {
        "generated_at": utc_now(),
        "planner": str(planner_path),
        "trace_audit": str(trace_path),
        "miner_report": str(miner_path),
        "design_contract": str(design_path),
        "squee_probe": str(squee_probe_path) if squee_probe else "",
        "access_model": str(access_model_path) if access_model else "",
        "runtime_gap_queue": str(runtime_gap_path) if runtime_gap_queue else "",
        "hand_filter_cut_model": str(hand_filter_cut_model_path) if hand_filter_cut_model else "",
        "postgres_writes": False,
        "source_db_mutated": False,
        "summary": {
            "focus_failure_mode_count": len(modes),
            "package_candidate_count": len(package_candidates),
            "gate_ready_package_count": len(gate_ready),
            "package_status_counts": dict(sorted(status_counts.items())),
            "protected_card_count": len(PROTECTED_CARDS),
            "prior_rejected_package_count": int(
                (planner_payload.get("summary") or {}).get("prior_rejected_package_count") or 0
            ),
            "seed_42_anchor_available": seed_42_anchor_available(trace_audit),
            "squee_probe_status": ((squee_probe or {}).get("summary") or {}).get("status", ""),
            "access_model_status": ((access_model or {}).get("summary") or {}).get(
                "access_density_status", ""
            ),
            "operational_work_count": len(operational_queue),
            "top_operational_work_key": (
                operational_queue[0]["work_key"] if operational_queue else ""
            ),
            "recommended_next_action": (
                "run_package_preflight_then_seed42_anchor_gate"
                if gate_ready
                else "do_not_create_blind_swap; run focused trace/runtime/cut-model work first"
            ),
        },
        "guardrail_contract": {
            "target_failure_mode_required": True,
            "protected_cards": sorted(PROTECTED_CARDS),
            "prior_negative_exact_match_must_be_false": True,
            "runtime_status_required": "active_or_materialized",
            "seed_42_anchor_requirement": {
                "required": True,
                "source": str(trace_path),
            },
        },
        "focus_failure_modes": list(modes.values()),
        "package_candidates": package_candidates,
        "gate_ready_packages": gate_ready,
        "instrumentation_route": instrumentation,
        "operational_work_queue": operational_queue,
    }


def render_markdown(payload: dict[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Focus-Access Package Generator - 2026-06-30",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Planner: `{payload['planner']}`",
        f"- Trace audit: `{payload['trace_audit']}`",
        f"- Miner report: `{payload['miner_report']}`",
        f"- Design contract: `{payload['design_contract']}`",
        f"- Squee probe: `{payload['squee_probe'] or '-'}`",
        f"- Access model: `{payload['access_model'] or '-'}`",
        f"- Runtime gap queue: `{payload['runtime_gap_queue'] or '-'}`",
        f"- Hand-filter cut model: `{payload['hand_filter_cut_model'] or '-'}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        f"- Package candidates evaluated: `{summary['package_candidate_count']}`",
        f"- Gate-ready packages: `{summary['gate_ready_package_count']}`",
        f"- Package statuses: `{json.dumps(summary['package_status_counts'], sort_keys=True)}`",
        f"- Seed-42 anchor available: `{str(summary['seed_42_anchor_available']).lower()}`",
        f"- Squee probe status: `{summary.get('squee_probe_status') or '-'}`",
        f"- Access model status: `{summary.get('access_model_status') or '-'}`",
        f"- Operational work items: `{summary.get('operational_work_count') or 0}`",
        f"- Top operational work: `{summary.get('top_operational_work_key') or '-'}`",
        "",
        "## Gate-Ready Packages",
        "",
    ]
    if payload["gate_ready_packages"]:
        for row in payload["gate_ready_packages"]:
            lines.append(
                f"- `{row['package_key']}`: add `{row['add_card']}`, cut `{row['cut_card']}`, "
                f"failure `{row['target_failure_mode']}`"
            )
    else:
        lines.append("- None. The generator refused to create a blind swap.")
    lines.extend(
        [
            "",
            "## Blocked Package Review",
            "",
            "| Status | Add | Cut | Lane | Failure Mode | Main Blockers |",
            "| --- | --- | --- | --- | --- | --- |",
        ]
    )
    for row in payload["package_candidates"][:40]:
        blockers = ", ".join(row.get("blockers") or []) or "-"
        lines.append(
            "| `{status}` | `{add}` | `{cut}` | `{lane}` | `{failure}` | {blockers} |".format(
                status=row.get("status") or "",
                add=row.get("add_card") or "",
                cut=row.get("cut_card") or "",
                lane=row.get("lane") or "",
                failure=row.get("target_failure_mode") or "",
                blockers=blockers,
            )
        )
    if len(payload["package_candidates"]) > 40:
        lines.append(f"| ... | ... | ... | ... | ... | {len(payload['package_candidates']) - 40} more rows omitted |")
    route = payload["instrumentation_route"]
    lines.extend(["", "## Instrumentation Route", ""])
    lines.append(f"- Status: `{route['status']}`")
    lines.append(f"- Next action: `{route['next_action']}`")
    for row in route.get("required_work") or []:
        lines.append(
            f"- `{row['work_key']}`: failure `{row['failure_mode']}`, seeds `{', '.join(row.get('target_seeds') or []) or '-'}`; {row.get('reason') or ''}"
        )
    lines.extend(
        [
            "",
            "## Operational Work Queue",
            "",
            "| Rank | Work | Impact | Blocks | Runtime Gaps | PG To Promote | Next Command |",
            "| ---: | --- | ---: | ---: | ---: | --- | --- |",
        ]
    )
    for row in payload.get("operational_work_queue") or []:
        lines.append(
            "| {rank} | `{work}` | {impact} | {blocks} | {runtime} | `{pg}` | `{command}` |".format(
                rank=row.get("priority_rank"),
                work=row.get("work_key"),
                impact=row.get("impact_score"),
                blocks=row.get("blocked_package_count"),
                runtime=row.get("blocked_runtime_rule_gap_count"),
                pg=str(bool(row.get("postgres_write_required_to_promote"))).lower(),
                command=row.get("next_command") or "",
            )
        )
    for row in payload.get("operational_work_queue") or []:
        lines.extend(
            [
                "",
                f"### {row.get('priority_rank')}. {row.get('work_key')}",
                "",
                f"- Failure mode: `{row.get('failure_mode')}`",
                f"- Target seeds: `{', '.join(row.get('target_seeds') or []) or '-'}`",
                f"- Reason: {row.get('reason') or '-'}",
                f"- Evidence inputs: `{', '.join(row.get('evidence_inputs') or []) or '-'}`",
                f"- Blocked package statuses: `{json.dumps(row.get('blocked_package_status_counts'), sort_keys=True)}`",
                f"- Promotion criteria: {'; '.join(row.get('promotion_criteria') or []) or '-'}",
            ]
        )
        runtime_context = row.get("runtime_gap_context") or {}
        if runtime_context.get("top_families"):
            lines.append("- Runtime families:")
            for family in runtime_context["top_families"]:
                lines.append(
                    "  - `{family}`: {count} cards, support `{support}`, samples `{samples}`".format(
                        family=family.get("family_id"),
                        count=family.get("card_count"),
                        support=family.get("support_status"),
                        samples=", ".join(str(card) for card in family.get("sample_cards") or []),
                    )
                )
    lines.extend(["", "## Guardrails", ""])
    guardrails = payload["guardrail_contract"]
    lines.append("- Target failure mode required before any package.")
    lines.append("- Protected cards cannot be cut: " + ", ".join(f"`{card}`" for card in guardrails["protected_cards"]))
    lines.append("- Prior negative exact matches are blocked.")
    lines.append("- Runtime status must be `active_or_materialized`.")
    lines.append("- Seed 42 is the first anchor gate before broader testing.")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--planner", type=Path, default=DEFAULT_PLANNER)
    parser.add_argument("--trace-audit", type=Path, default=DEFAULT_TRACE_AUDIT)
    parser.add_argument("--miner-report", type=Path, default=DEFAULT_MINER_REPORT)
    parser.add_argument("--design-report", type=Path, default=DEFAULT_DESIGN_REPORT)
    parser.add_argument("--squee-probe", type=Path, default=DEFAULT_SQUEE_PROBE)
    parser.add_argument("--access-model", type=Path, default=DEFAULT_ACCESS_MODEL)
    parser.add_argument("--runtime-gap-queue", type=Path, default=DEFAULT_RUNTIME_GAP_QUEUE)
    parser.add_argument("--hand-filter-cut-model", type=Path, default=DEFAULT_HAND_FILTER_CUT_MODEL)
    parser.add_argument("--stem", default="lorehold_focus_access_package_generator_20260628_v3")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_report(
        planner_payload=read_json(args.planner),
        trace_audit=read_json(args.trace_audit),
        miner_report=read_json(args.miner_report),
        squee_probe=read_json(args.squee_probe) if args.squee_probe.exists() else None,
        access_model=read_json(args.access_model) if args.access_model.exists() else None,
        runtime_gap_queue=read_json(args.runtime_gap_queue) if args.runtime_gap_queue.exists() else None,
        hand_filter_cut_model=(
            read_json(args.hand_filter_cut_model) if args.hand_filter_cut_model.exists() else None
        ),
        planner_path=args.planner,
        trace_path=args.trace_audit,
        miner_path=args.miner_report,
        design_path=args.design_report,
        squee_probe_path=args.squee_probe,
        access_model_path=args.access_model,
        runtime_gap_path=args.runtime_gap_queue,
        hand_filter_cut_model_path=args.hand_filter_cut_model,
    )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
