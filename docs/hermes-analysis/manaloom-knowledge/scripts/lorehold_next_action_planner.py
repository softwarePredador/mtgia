#!/usr/bin/env python3
"""Plan the next Lorehold deck-learning actions from current evidence.

This script is read-only. It consumes the variant gap miner, manual cut review,
and one or more exposure profiles, then emits a concise action queue. The goal
is to prevent slow card-by-card guessing: every next move must be a gate-ready
package, a cut-modeling task, a runtime-rule task, or an explicit no-retest
guardrail backed by existing evidence.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_MINER_REPORT = (
    REPORT_DIR / "lorehold_variant_gap_miner_20260627_v3_post_austere_tradeoff.json"
)
DEFAULT_MANUAL_REVIEW = REPORT_DIR / "lorehold_manual_cut_review_20260627_v2.json"
DEFAULT_EXPOSURE_PROFILES = [REPORT_DIR / "lorehold_card_exposure_profile_20260627_v1.json"]
DEFAULT_TUTOR_CUT_MODEL_REPORTS = [REPORT_DIR / "lorehold_tutor_cut_model_20260627_v1.json"]
DEFAULT_HAND_FILTER_CUT_MODEL_REPORTS = [
    REPORT_DIR / "lorehold_hand_filter_cut_model_20260627_v3_big_score_rejected.json"
]
DEFAULT_PRIOR_PACKAGE_REPORTS = [
    REPORT_DIR / "lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def read_existing_json(paths: Iterable[Path]) -> list[tuple[Path, dict[str, Any]]]:
    loaded: list[tuple[Path, dict[str, Any]]] = []
    for path in paths:
        if path.exists():
            loaded.append((path, read_json(path)))
    return loaded


def exposure_lookup(exposure_profiles: list[tuple[Path, dict[str, Any]]]) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for path, payload in exposure_profiles:
        for row in payload.get("card_profiles") or []:
            if not row.get("card_name"):
                continue
            key = normalize_key(row["card_name"])
            current = out.get(key)
            candidate = {**row, "exposure_profile": str(path)}
            if current is None or int(candidate.get("unique_exposure_count") or 0) >= int(
                current.get("unique_exposure_count") or 0
            ):
                out[key] = candidate
    return out


def top_candidates(
    miner_report: dict[str, Any],
    *,
    lane: str | None = None,
    status_in: set[str] | None = None,
    limit: int = 6,
) -> list[dict[str, Any]]:
    rows = []
    for row in miner_report.get("top_variant_candidates") or []:
        if lane and row.get("lane") != lane:
            continue
        if status_in and row.get("status") not in status_in:
            continue
        rows.append(row)
    rows.sort(key=lambda row: (-int(row.get("score") or 0), row.get("card_name") or ""))
    return rows[:limit]


def pairing_rows(
    miner_report: dict[str, Any],
    *,
    status: str | None = None,
    lane: str | None = None,
) -> list[dict[str, Any]]:
    rows = []
    for row in miner_report.get("pairing_hypotheses") or []:
        if status and row.get("status") != status:
            continue
        if lane and row.get("lane") != lane:
            continue
        rows.append(row)
    rows.sort(key=lambda row: (-int(row.get("candidate_score") or 0), row.get("candidate") or ""))
    return rows


def card_exposure_summary(
    card_names: Iterable[str],
    exposures: dict[str, dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    summary: dict[str, dict[str, Any]] = {}
    for name in card_names:
        row = exposures.get(normalize_key(name)) or {}
        summary[name] = {
            "unique_exposure_count": int(row.get("unique_exposure_count") or 0),
            "inferred_role": row.get("inferred_role") or "unmeasured",
            "decision_status": (row.get("decision") or {}).get("status") or "unmeasured",
            "next_action": (row.get("decision") or {}).get("next_action") or "",
            "exposure_profile": row.get("exposure_profile") or "",
        }
    return summary


def manual_context_by_candidate(manual_review: dict[str, Any]) -> dict[str, dict[str, Any]]:
    rows = {}
    for row in manual_review.get("contextual_lane_reviews") or []:
        if row.get("candidate"):
            rows[normalize_key(row["candidate"])] = row
    return rows


def manual_cut_by_candidate(manual_review: dict[str, Any]) -> dict[str, dict[str, Any]]:
    rows = {}
    for row in manual_review.get("manual_cut_reviews") or []:
        if row.get("candidate"):
            rows[normalize_key(row["candidate"])] = row
    return rows


def summarize_cut_options(pairings: list[dict[str, Any]], limit: int = 5) -> list[dict[str, Any]]:
    cards: list[dict[str, Any]] = []
    seen: set[str] = set()
    for pairing in pairings:
        for cut in pairing.get("cut_options") or []:
            key = normalize_key(cut.get("card_name"))
            if not key or key in seen:
                continue
            seen.add(key)
            cards.append(
                {
                    "card_name": cut.get("card_name"),
                    "gate_readiness": cut.get("gate_readiness"),
                    "status": cut.get("status"),
                    "lane": cut.get("lane"),
                    "readiness_reason": cut.get("readiness_reason"),
                }
            )
            if len(cards) >= limit:
                return cards
    return cards


def infer_package_decision(result: dict[str, Any]) -> str:
    if result.get("decision"):
        return str(result["decision"])
    gate = result.get("gate_summary") or {}
    baseline = gate.get("baseline") or {}
    candidate = gate.get("candidate") or {}
    baseline_wins = int(baseline.get("wins") or 0)
    candidate_wins = int(candidate.get("wins") or 0)
    delta = float(gate.get("delta_pp") or 0.0)
    if delta < 0 or candidate_wins < baseline_wins:
        return "reject_or_rework"
    if delta > 0 or candidate_wins > baseline_wins:
        return "promote_to_deeper_gate"
    return "tie_or_unknown"


def rejected_package_evidence(
    prior_package_reports: list[tuple[Path, dict[str, Any]]],
) -> dict[str, dict[str, Any]]:
    rejected: dict[str, dict[str, Any]] = {}
    for path, payload in prior_package_reports:
        packages = payload.get("packages") or []
        if not isinstance(packages, list):
            continue
        for result in packages:
            if not isinstance(result, dict):
                continue
            key = str(result.get("package_key") or "")
            if not key:
                continue
            decision = infer_package_decision(result)
            if decision != "reject_or_rework":
                continue
            gate = result.get("gate_summary") or {}
            rejected[key] = {
                "package_key": key,
                "source_report": str(path),
                "adds": result.get("adds") or [],
                "cuts": result.get("cuts") or [],
                "decision": decision,
                "delta_pp": gate.get("delta_pp"),
                "baseline": gate.get("baseline") or {},
                "candidate": gate.get("candidate") or {},
            }
    return rejected


def latest_tutor_cut_model(
    tutor_cut_model_reports: list[tuple[Path, dict[str, Any]]],
) -> tuple[Path, dict[str, Any]] | None:
    if not tutor_cut_model_reports:
        return None
    return tutor_cut_model_reports[-1]


def latest_hand_filter_cut_model(
    hand_filter_cut_model_reports: list[tuple[Path, dict[str, Any]]],
) -> tuple[Path, dict[str, Any]] | None:
    if not hand_filter_cut_model_reports:
        return None
    return hand_filter_cut_model_reports[-1]


def build_tutor_action(
    miner_report: dict[str, Any],
    manual_review: dict[str, Any],
    exposures: dict[str, dict[str, Any]],
    tutor_cut_model_reports: list[tuple[Path, dict[str, Any]]] | None = None,
    prior_package_reports: list[tuple[Path, dict[str, Any]]] | None = None,
) -> dict[str, Any] | None:
    context = manual_context_by_candidate(manual_review)
    candidates = []
    for pairing in pairing_rows(miner_report, status="needs_lane_model_before_gate"):
        key = normalize_key(pairing.get("candidate"))
        manual = context.get(key, {})
        if "tutor" not in str(manual.get("decision") or pairing.get("candidate")).lower() and key not in {
            normalize_key("Gamble"),
            normalize_key("Enlightened Tutor"),
        }:
            continue
        candidates.append(pairing)
    if not candidates:
        return None
    names = [str(row["candidate"]) for row in candidates]
    tutor_model = latest_tutor_cut_model(tutor_cut_model_reports or [])
    rejected_packages = rejected_package_evidence(prior_package_reports or [])
    land_tax_package_keys = {
        "gamble_access_benchmark_cut_land_tax",
        "enlightened_access_benchmark_cut_land_tax",
    }
    land_tax_rejections = {
        key: rejected_packages[key]
        for key in land_tax_package_keys
        if key in rejected_packages
    }
    if tutor_model:
        model_path, model_payload = tutor_model
        model_summary = model_payload.get("summary") or {}
        land_tax_benchmarks = [
            row
            for row in model_payload.get("top_manual_benchmarks") or []
            if normalize_key(row.get("cut")) == normalize_key("Land Tax")
            and normalize_key(row.get("candidate")) in {normalize_key("Gamble"), normalize_key("Enlightened Tutor")}
        ]
        if (
            int(model_summary.get("direct_gate_ready_count") or 0) == 0
            and land_tax_package_keys.issubset(land_tax_rejections)
        ):
            return {
                "priority": 90,
                "action_key": "avoid_rejected_tutor_land_tax_swaps",
                "status": "tutor_land_tax_benchmarks_rejected",
                "lane": "tutor_access",
                "candidate_cards": names,
                "cut_cards": ["Land Tax"],
                "why_now": (
                    "The tutor cut model found no direct seed-safe swap, and the highest "
                    "same-access Land Tax benchmarks already lost the equal gate."
                ),
                "blockers": [
                    "Gamble over Land Tax was rejected by prior gate evidence",
                    "Enlightened Tutor over Land Tax was rejected by prior gate evidence",
                    "Thor and Creative Technique tutor cuts already have prior regression evidence",
                ],
                "next_steps": [
                    "Do not rerun exact tutor-over-Land-Tax packages without a changed shell or explicit override.",
                    "Search for an additive tutor/access package or a different low-exposure non-access cut.",
                    "Rerun the tutor cut model after any new shell change before another tutor gate.",
                ],
                "candidate_exposure": card_exposure_summary(names, exposures),
                "tutor_cut_model_report": str(model_path),
                "land_tax_benchmark_rejections": land_tax_rejections,
            }
        if int(model_summary.get("direct_gate_ready_count") or 0) == 0 and land_tax_benchmarks:
            return {
                "priority": 1,
                "action_key": "run_tutor_land_tax_benchmark_gate",
                "status": "same_access_benchmark_required_before_next_tutor_attempt",
                "lane": "tutor_access",
                "candidate_cards": names,
                "cut_cards": ["Land Tax"],
                "why_now": (
                    "The tutor cut model is built and ranks Land Tax as the highest same-access "
                    "benchmark, but that benchmark has not been resolved in prior package evidence."
                ),
                "blockers": [
                    "no direct gate-ready tutor pair exists",
                    "Land Tax is protected support until the same-access benchmark resolves",
                ],
                "next_steps": [
                    "Run the explicit Gamble/Enlightened Tutor over Land Tax benchmark packages.",
                    "Promote only if the package beats baseline without seed regression.",
                    "If rejected, mark exact packages as prior-negative and move to additive access modeling.",
                ],
                "candidate_exposure": card_exposure_summary(names, exposures),
                "tutor_cut_model_report": str(model_path),
            }
    manual_notes = {
        str(row["candidate"]): {
            "decision": (context.get(normalize_key(row["candidate"])) or {}).get("decision"),
            "recommended_cut_search": (
                context.get(normalize_key(row["candidate"])) or {}
            ).get("recommended_cut_search"),
            "prior_evidence_count": len(
                (context.get(normalize_key(row["candidate"])) or {}).get("prior_evidence") or []
            ),
        }
        for row in candidates
    }
    return {
        "priority": 1,
        "action_key": "build_tutor_seed_safe_cut_model",
        "status": "cut_model_required_before_gate",
        "lane": "tutor_access",
        "candidate_cards": names,
        "cut_cards": [],
        "why_now": (
            "Tutor cards are runtime-ready, exposed in local evidence, and high-frequency in Lorehold "
            "variants, but prior tests regressed the protected strong seed when the cut was wrong."
        ),
        "blockers": [
            "no seed-safe cut model is proven",
            "do not repeat Thor or blind Creative Technique cuts",
            "gate only after preflight proves no prior-negative exact package",
        ],
        "next_steps": [
            "Mine current champion cards that overlap tutor access without touching locked win/protection engines.",
            "Require cut_safety status not locked/core and no prior negative cut evidence.",
            "Create one explicit package, run preflight, then run a small equal gate only if preflight is clean.",
        ],
        "candidate_exposure": card_exposure_summary(names, exposures),
        "manual_notes": manual_notes,
    }


def build_hand_filter_action(
    miner_report: dict[str, Any],
    exposures: dict[str, dict[str, Any]],
    hand_filter_cut_model_reports: list[tuple[Path, dict[str, Any]]] | None = None,
) -> dict[str, Any] | None:
    pairings = pairing_rows(
        miner_report,
        status="blocked_no_safe_cut_in_lane",
        lane="hand_filter",
    )
    if not pairings:
        return None
    hand_filter_model = latest_hand_filter_cut_model(hand_filter_cut_model_reports or [])
    if hand_filter_model:
        model_path, model_payload = hand_filter_model
        preflight_rows = [
            row
            for row in model_payload.get("preflight_benchmark_candidates") or []
            if row.get("status") == "preflight_benchmark_ready"
        ]
        blocked_prior = [
            row
            for row in model_payload.get("pair_evaluations") or []
            if row.get("status") == "blocked_prior_reject"
        ]
        if preflight_rows:
            top = preflight_rows[0]
            return {
                "priority": 2,
                "action_key": "run_hand_filter_benchmark_gate",
                "status": "same_lane_benchmark_ready",
                "lane": "hand_filter",
                "candidate_cards": [str(top.get("candidate") or "")],
                "cut_cards": [str(top.get("cut") or "")],
                "why_now": (
                    "The hand-filter cut model has exposure evidence and has skipped prior exact rejects; "
                    "the next pair needs package preflight plus a small equal gate."
                ),
                "blockers": [
                    "the proposed cut is still a benchmark, not a promotion",
                    "Big Score provides ramp, discard, draw, and Treasure, so a win-rate gate must prove the tradeoff",
                ],
                "next_steps": [
                    "Run the exact package preflight to check prior-negative evidence.",
                    "Run the smallest equal gate only if preflight is clear.",
                    "If rejected, add the exact report to prior package defaults and rerun this model.",
                ],
                "hand_filter_cut_model_report": str(model_path),
                "preflight_benchmark_candidates": preflight_rows[:5],
                "blocked_prior_rejections": blocked_prior[:5],
            }
        return {
            "priority": 90,
            "action_key": "avoid_hand_filter_without_new_cut",
            "status": "no_hand_filter_benchmark_ready",
            "lane": "hand_filter",
            "candidate_cards": [],
            "cut_cards": [],
            "why_now": (
                "The hand-filter cut model found no clean benchmark after prior rejects and protected cuts."
            ),
            "blockers": ["no preflight_benchmark_ready hand-filter pair remains"],
            "next_steps": [
                "Search for a different non-core cut or a multi-card package before another hand-filter gate.",
            ],
            "hand_filter_cut_model_report": str(model_path),
            "blocked_prior_rejections": blocked_prior[:5],
        }
    candidates = [str(row["candidate"]) for row in pairings[:5]]
    cuts = summarize_cut_options(pairings, limit=6)
    cut_names = [str(row["card_name"]) for row in cuts if row.get("card_name")]
    unprofiled_cards = [
        name for name in candidates + cut_names if normalize_key(name) not in exposures
    ]
    zero_exposure_cards = [
        name
        for name in candidates + cut_names
        if normalize_key(name) in exposures
        and int((exposures.get(normalize_key(name)) or {}).get("unique_exposure_count") or 0) == 0
    ]
    status = (
        "exposure_profile_required_before_gate"
        if unprofiled_cards
        else "cut_benchmark_required_before_gate"
    )
    return {
        "priority": 2,
        "action_key": "profile_hand_filter_cut_benchmarks",
        "status": status,
        "lane": "hand_filter",
        "candidate_cards": candidates,
        "cut_cards": cut_names,
        "why_now": (
            "Apex/Valakut/Wheel-style cards are high-frequency runtime-ready candidates, "
            "but every visible cut is protected same-lane support. This lane needs measured cut value first."
        ),
        "blockers": [
            "all current cut options are protected_same_lane_benchmark_required",
            "blindly cutting draw/filter support can reduce miracle setup density",
            "unprofiled or zero-exposure cards cannot justify a blind cut",
        ],
        "next_steps": [
            "Run the exposure profiler for the candidate and protected cut cards in this lane.",
            "Choose at most one explicit same-lane tradeoff with measured low exposure or low strategic dependence.",
            "Reject the lane for now if every cut card has higher exposure or a locked role.",
        ],
        "candidate_exposure": card_exposure_summary(candidates, exposures),
        "cut_exposure": card_exposure_summary(cut_names, exposures),
        "missing_exposure_cards": unprofiled_cards,
        "zero_exposure_cards": zero_exposure_cards,
    }


def build_recursion_action(
    miner_report: dict[str, Any],
    manual_review: dict[str, Any],
    exposures: dict[str, dict[str, Any]],
) -> dict[str, Any] | None:
    pairings = pairing_rows(miner_report, lane="graveyard_recursion")
    manual = manual_cut_by_candidate(manual_review)
    protected = []
    for row in pairings:
        note = manual.get(normalize_key(row.get("candidate")))
        if note and note.get("gate_action") == "blocked":
            protected.append(row)
    if not pairings:
        return None
    candidates = [str(row["candidate"]) for row in pairings[:5]]
    cuts = summarize_cut_options(pairings, limit=5)
    cut_names = [str(row["card_name"]) for row in cuts if row.get("card_name")]
    return {
        "priority": 3,
        "action_key": "preserve_squee_build_recursion_package",
        "status": "multi_card_or_non_squee_cut_required",
        "lane": "graveyard_recursion",
        "candidate_cards": candidates,
        "cut_cards": cut_names,
        "why_now": (
            "Recursion variants are frequent and runtime-ready, but the obvious cut is Squee, "
            "which has direct exposure as the current recursion engine."
        ),
        "blockers": [
            "Squee is protected as the current champion recursion engine",
            "single-card Volcanic/Restoration over Squee is blocked",
            "same-lane non-Squee cuts require stronger role evidence",
        ],
        "next_steps": [
            "Keep Squee in the champion shell while testing any recursion expansion.",
            "Search for a non-Squee cut or a multi-card package that preserves the current recursion engine.",
            "Do not gate Volcanic Vision or Restoration Seminar over Squee.",
        ],
        "candidate_exposure": card_exposure_summary(candidates, exposures),
        "cut_exposure": card_exposure_summary(cut_names, exposures),
        "manual_blocked_candidates": [
            {
                "candidate": row["candidate"],
                "decision": (manual.get(normalize_key(row["candidate"])) or {}).get("decision"),
                "reasons": (manual.get(normalize_key(row["candidate"])) or {}).get("reasons") or [],
            }
            for row in protected
        ],
    }


def build_mana_action(miner_report: dict[str, Any]) -> dict[str, Any] | None:
    pairings = pairing_rows(
        miner_report,
        status="blocked_no_safe_cut_in_lane",
        lane="mana_base",
    )
    if not pairings:
        return None
    candidates = [str(row["candidate"]) for row in pairings[:6]]
    cuts = summarize_cut_options(pairings, limit=6)
    return {
        "priority": 4,
        "action_key": "use_mana_base_validator_not_battle_gate",
        "status": "mana_model_required_before_gate",
        "lane": "mana_base",
        "candidate_cards": candidates,
        "cut_cards": [str(row["card_name"]) for row in cuts if row.get("card_name")],
        "why_now": (
            "Mana-base variants are frequent, but lands are blocked as core cuts. "
            "A battle equal gate is too noisy until color-source odds and utility-land value are modeled."
        ),
        "blockers": [
            "current land cuts are blocked_core_cut",
            "battle gate cannot isolate mana consistency from game variance",
        ],
        "next_steps": [
            "Run or extend the mana-base validator for color sources, untapped timing, and utility-land cost.",
            "Only produce a land package if the odds model improves without cutting required colored sources.",
        ],
    }


def build_runtime_action(miner_report: dict[str, Any]) -> dict[str, Any] | None:
    summary = miner_report.get("summary") or {}
    count = int(summary.get("blocked_runtime_rule_gap_count") or 0)
    if count <= 0:
        return None
    candidates = top_candidates(
        miner_report,
        status_in={"blocked_runtime_rule_gap"},
        limit=8,
    )
    return {
        "priority": 5,
        "action_key": "batch_xmage_runtime_rule_gaps",
        "status": "runtime_required_before_strategy_gate",
        "lane": "runtime_rules",
        "candidate_cards": [str(row["card_name"]) for row in candidates],
        "candidate_count": count,
        "cut_cards": [],
        "why_now": (
            f"{count} variant-only cards still cannot be trusted in battle because the local runtime "
            "does not have an active rule for them."
        ),
        "blockers": ["missing active battle rule"],
        "next_steps": [
            "Group the blocked cards by XMage semantic family.",
            "Implement the runtime mapper once per family, then rerun the miner before choosing gates.",
        ],
    }


def build_guardrails(
    miner_report: dict[str, Any],
    manual_review: dict[str, Any],
) -> list[dict[str, Any]]:
    negative = miner_report.get("negative_exact_packages") or []
    guardrails = [
        {
            "guardrail_key": "no_automatic_gate_without_safe_cut",
            "reason": (
                "The current miner reports zero gate-ready pairings; a new gate must come from a "
                "fresh cut model or explicit preflight, not from the raw candidate list."
            ),
        },
        {
            "guardrail_key": "do_not_repeat_negative_exact_packages",
            "negative_package_count": len(negative),
            "reason": "Prior negative add/cut evidence must demote exact retests until the cut model changes.",
        },
    ]
    if "Austere" in json.dumps(negative) or "Emeria" in json.dumps(negative):
        guardrails.append(
            {
                "guardrail_key": "austere_emeria_tradeoff_rejected",
                "reason": "Austere over Emeria already lost its gate and must not be rerun as the same tradeoff.",
            }
        )
    if manual_review.get("summary", {}).get("automatic_gate_ready_count") == 0:
        guardrails.append(
            {
                "guardrail_key": "manual_review_has_no_auto_gate",
                "reason": "Manual review confirms the current unresolved candidates require modeling before battle.",
            }
        )
    return guardrails


def build_plan(
    *,
    miner_report: dict[str, Any],
    manual_review: dict[str, Any],
    exposure_profiles: list[tuple[Path, dict[str, Any]]],
    tutor_cut_model_reports: list[tuple[Path, dict[str, Any]]] | None = None,
    hand_filter_cut_model_reports: list[tuple[Path, dict[str, Any]]] | None = None,
    prior_package_reports: list[tuple[Path, dict[str, Any]]] | None = None,
    miner_path: Path = DEFAULT_MINER_REPORT,
    manual_path: Path = DEFAULT_MANUAL_REVIEW,
) -> dict[str, Any]:
    exposures = exposure_lookup(exposure_profiles)
    gate_ready = pairing_rows(miner_report, status="gate_ready_safe_same_lane")
    actions = []
    if gate_ready:
        actions.append(
            {
                "priority": 0,
                "action_key": "preflight_gate_ready_pairings",
                "status": "ready_for_preflight",
                "lane": "battle_gate",
                "candidate_cards": [str(row["candidate"]) for row in gate_ready[:5]],
                "cut_cards": [
                    str(cut["card_name"])
                    for row in gate_ready[:5]
                    for cut in (row.get("cut_options") or [])[:1]
                    if cut.get("card_name")
                ],
                "why_now": "The miner found safe same-lane pairings.",
                "blockers": [],
                "next_steps": [
                    "Run preflight for exact prior-negative checks.",
                    "Run the smallest equal gate only after preflight passes.",
                ],
            }
        )
    for action in (
        build_tutor_action(
            miner_report,
            manual_review,
            exposures,
            tutor_cut_model_reports=tutor_cut_model_reports,
            prior_package_reports=prior_package_reports,
        ),
        build_hand_filter_action(
            miner_report,
            exposures,
            hand_filter_cut_model_reports=hand_filter_cut_model_reports,
        ),
        build_recursion_action(miner_report, manual_review, exposures),
        build_mana_action(miner_report),
        build_runtime_action(miner_report),
    ):
        if action:
            actions.append(action)
    actions.sort(key=lambda row: (int(row.get("priority") or 0), row.get("action_key") or ""))
    status_counts = Counter(str(row.get("status") or "") for row in actions)
    recommended = actions[0]["action_key"] if actions else "rerun_variant_gap_miner"
    return {
        "generated_at": utc_now(),
        "miner_report": str(miner_path),
        "manual_review": str(manual_path),
        "exposure_profiles": [str(path) for path, _payload in exposure_profiles],
        "tutor_cut_model_reports": [
            str(path) for path, _payload in (tutor_cut_model_reports or [])
        ],
        "hand_filter_cut_model_reports": [
            str(path) for path, _payload in (hand_filter_cut_model_reports or [])
        ],
        "prior_package_reports": [str(path) for path, _payload in (prior_package_reports or [])],
        "postgres_writes": False,
        "source_db_mutated": False,
        "summary": {
            "gate_ready_now_count": len(gate_ready),
            "action_count": len(actions),
            "action_status_counts": dict(sorted(status_counts.items())),
            "recommended_next_action": recommended,
            "miner_candidate_status_counts": (miner_report.get("summary") or {}).get(
                "candidate_status_counts",
                {},
            ),
            "miner_pairing_status_counts": (miner_report.get("summary") or {}).get(
                "pairing_status_counts",
                {},
            ),
        },
        "action_queue": actions,
        "guardrails": build_guardrails(miner_report, manual_review),
        "method_notes": [
            "This planner is a decision layer, not a promotion engine.",
            "A runtime-ready card is not gate-ready unless a safe cut model exists.",
            "Exposure evidence is used to protect proven roles and to decide which lane needs profiling next.",
            "PostgreSQL and SQLite are not mutated by this script.",
        ],
    }


def render_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Next Action Planner - 2026-06-27",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Miner report: `{payload['miner_report']}`",
        f"- Manual review: `{payload['manual_review']}`",
        f"- Exposure profiles: `{', '.join(payload['exposure_profiles'])}`",
        f"- Tutor cut model reports: `{', '.join(payload.get('tutor_cut_model_reports') or []) or '-'}`",
        f"- Hand-filter cut model reports: `{', '.join(payload.get('hand_filter_cut_model_reports') or []) or '-'}`",
        f"- Prior package reports: `{', '.join(payload.get('prior_package_reports') or []) or '-'}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Gate-ready now: `{payload['summary']['gate_ready_now_count']}`",
        f"- Action count: `{payload['summary']['action_count']}`",
        f"- Action statuses: `{json.dumps(payload['summary']['action_status_counts'], sort_keys=True)}`",
        f"- Recommended next action: `{payload['summary']['recommended_next_action']}`",
        f"- Miner candidate statuses: `{json.dumps(payload['summary']['miner_candidate_status_counts'], sort_keys=True)}`",
        f"- Miner pairing statuses: `{json.dumps(payload['summary']['miner_pairing_status_counts'], sort_keys=True)}`",
        "",
        "## Action Queue",
        "",
        "| Priority | Action | Status | Lane | Candidates | Cuts | Why |",
        "| ---: | --- | --- | --- | --- | --- | --- |",
    ]
    for row in payload["action_queue"]:
        candidates = ", ".join(row.get("candidate_cards") or []) or (
            f"{row.get('candidate_count')} candidates"
            if row.get("candidate_count")
            else "none"
        )
        lines.append(
            "| {priority} | `{action}` | `{status}` | `{lane}` | {candidates} | {cuts} | {why} |".format(
                priority=row["priority"],
                action=row["action_key"],
                status=row["status"],
                lane=row.get("lane") or "",
                candidates=candidates,
                cuts=", ".join(row.get("cut_cards") or []) or "none",
                why=row.get("why_now") or "",
            )
        )
    lines.extend(["", "## Action Details", ""])
    for row in payload["action_queue"]:
        lines.append(f"### P{row['priority']} {row['action_key']}")
        lines.append("")
        lines.append(f"- Status: `{row['status']}`")
        lines.append(f"- Lane: `{row.get('lane') or ''}`")
        for blocker in row.get("blockers") or []:
            lines.append(f"- Blocker: {blocker}")
        for step in row.get("next_steps") or []:
            lines.append(f"- Next step: {step}")
        if row.get("missing_exposure_cards"):
            lines.append(
                "- Missing exposure cards: "
                + ", ".join(str(card) for card in row["missing_exposure_cards"])
            )
        if row.get("zero_exposure_cards"):
            lines.append(
                "- Zero natural exposure cards: "
                + ", ".join(str(card) for card in row["zero_exposure_cards"])
            )
        lines.append("")
    lines.extend(["## Guardrails", ""])
    for row in payload["guardrails"]:
        lines.append(f"- `{row['guardrail_key']}`: {row['reason']}")
    lines.extend(["", "## Method Notes", ""])
    for note in payload["method_notes"]:
        lines.append(f"- {note}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--miner-report", type=Path, default=DEFAULT_MINER_REPORT)
    parser.add_argument("--manual-review", type=Path, default=DEFAULT_MANUAL_REVIEW)
    parser.add_argument("--exposure-profile", type=Path, action="append")
    parser.add_argument("--tutor-cut-model-report", type=Path, action="append")
    parser.add_argument("--hand-filter-cut-model-report", type=Path, action="append")
    parser.add_argument("--prior-package-report", type=Path, action="append")
    parser.add_argument("--stem", default="lorehold_next_action_planner_20260627_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    miner_report = read_json(args.miner_report)
    manual_review = read_json(args.manual_review)
    exposure_paths = args.exposure_profile or DEFAULT_EXPOSURE_PROFILES
    exposure_profiles = read_existing_json(exposure_paths)
    tutor_cut_model_reports = read_existing_json(
        args.tutor_cut_model_report or DEFAULT_TUTOR_CUT_MODEL_REPORTS
    )
    hand_filter_cut_model_reports = read_existing_json(
        args.hand_filter_cut_model_report or DEFAULT_HAND_FILTER_CUT_MODEL_REPORTS
    )
    prior_package_reports = read_existing_json(
        args.prior_package_report or DEFAULT_PRIOR_PACKAGE_REPORTS
    )
    payload = build_plan(
        miner_report=miner_report,
        manual_review=manual_review,
        exposure_profiles=exposure_profiles,
        tutor_cut_model_reports=tutor_cut_model_reports,
        hand_filter_cut_model_reports=hand_filter_cut_model_reports,
        prior_package_reports=prior_package_reports,
        miner_path=args.miner_report,
        manual_path=args.manual_review,
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
