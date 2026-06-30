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
    REPORT_DIR / "lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json"
)
DEFAULT_MANUAL_REVIEW = (
    REPORT_DIR / "lorehold_manual_cut_review_20260630_goal_learning_deck607_exposure_current.json"
)
DEFAULT_EXPOSURE_PROFILES = [
    REPORT_DIR / "lorehold_card_exposure_profile_20260630_goal_learning_deck607_current.json",
    REPORT_DIR / "lorehold_card_exposure_profile_20260627_v2_role_fix.json",
    REPORT_DIR / "lorehold_cut_exposure_profile_20260628_v1.json",
]
DEFAULT_STRATEGY_AUDIT = (
    REPORT_DIR / "lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json"
)
DEFAULT_HYPOTHESIS_QUEUE = (
    REPORT_DIR / "lorehold_next_hypothesis_queue_20260630_after_profiled_gate.json"
)
DEFAULT_TRACE_AUDIT = (
    REPORT_DIR / "lorehold_failure_targeted_trace_audit_20260630_definitive_learning_v1.json"
)
DEFAULT_TUTOR_CUT_MODEL_REPORTS = [REPORT_DIR / "lorehold_tutor_cut_model_20260630_after_pg269_alhammarret.json"]
DEFAULT_HAND_FILTER_CUT_MODEL_REPORTS = [
    REPORT_DIR / "lorehold_hand_filter_cut_model_20260630_post_pg270_expanded607_search.json"
]
DEFAULT_RECURSION_CUT_MODEL_REPORTS = [
    REPORT_DIR / "lorehold_recursion_cut_model_20260630_after_pg269_alhammarret.json"
]
DEFAULT_MANA_BASE_VALIDATOR_REPORTS = [
    REPORT_DIR / "lorehold_mana_base_validator_20260627_v3_plateau_lane_rejected.json"
]
DEFAULT_PROFILED_CUT_BENCHMARK_REPORTS = [
    REPORT_DIR / "lorehold_profiled_cut_benchmark_generator_20260630_goal_learning_all_lanes_closed.json"
]
DEFAULT_PRIOR_PACKAGE_REPORTS = [
    REPORT_DIR / "lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json",
    REPORT_DIR / "lorehold_mana_base_plateau_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_brass_bounty_recurring_seed_window_20260628_v1_run.json",
    REPORT_DIR / "lorehold_profiled_cut_benchmark_matrix_20260628_v1_20260628_083628.json",
    REPORT_DIR / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v2_20260628_085703.json",
    REPORT_DIR / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v3_20260628_090640.json",
    REPORT_DIR / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v4b_20260628_091321.json",
    REPORT_DIR
    / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v4b_witch_confirm_20260628_091458.json",
    REPORT_DIR / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v5_20260628_092712.json",
    REPORT_DIR / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v6_20260628_093001.json",
    DEFAULT_STRATEGY_AUDIT,
    REPORT_DIR / "lorehold_exposure_decision_contract_20260628_v1_20260628_190000.json",
    REPORT_DIR / "lorehold_exposure_outcome_audit_20260628_actionability_v1.json",
    REPORT_DIR / "lorehold_forced_exposure_probe_decision_20260630.json",
    REPORT_DIR / "lorehold_forced_signal_natural_confirm_decision_20260630.json",
    REPORT_DIR / "lorehold_profiled_cut_benchmark_gate_decision_20260630.json",
    REPORT_DIR / "lorehold_chaos_warp_generous_gift_decision_20260630_goal_learning.json",
    REPORT_DIR / "lorehold_discard_ramp_value_monument_decision_20260630_goal_learning.json",
    REPORT_DIR / "lorehold_possibility_storm_creative_technique_decision_20260630_goal_learning.json",
]
INCONCLUSIVE_EXPOSURE_DECISIONS = {
    "inconclusive_low_exposure",
    "forced_access_inconclusive_low_exposure",
    "insufficient_card_outcome_sample",
    "forced_access_insufficient_card_outcome_sample",
    "insufficient_card_outcome_used_sample",
    "candidate_used_without_cut_comparator",
    "candidate_accessed_without_used_sample",
    "candidate_near_access_without_used_sample",
}
REJECTED_PRIOR_DECISIONS = {
    "reject_or_rework",
    "reject_regresses_critical_matchup",
    "invalid_or_incomplete",
    "forced_access_no_lift_reject_or_rework",
    "tie_watch_strategy_regression",
}
LOW_EXPOSURE_STATUSES = {
    "candidate_added_card_low_access",
    "candidate_added_card_low_exposure",
    "candidate_added_cards_accessed_not_used",
    "candidate_added_cards_near_access_low_use",
}


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


def latest_profiled_cut_benchmark(
    reports: list[tuple[Path, dict[str, Any]]] | None,
) -> tuple[Path, dict[str, Any]] | None:
    if not reports:
        return None
    return reports[-1]


def is_profiled_cut_benchmark_exhausted(payload: dict[str, Any]) -> bool:
    summary = payload.get("summary") or {}
    return (
        summary.get("recommended_next_action") == "no_profiled_cut_benchmark_package_ready"
        or (
            int(summary.get("profiled_cut_count") or 0) > 0
            and int(summary.get("preflight_ready_pair_count") or 0) == 0
            and int(summary.get("selected_package_count") or 0) == 0
        )
    )


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


def exposure_requires_inconclusive(exposure: dict[str, Any]) -> bool:
    if not exposure:
        return False
    if bool(exposure.get("low_candidate_added_card_use")):
        return True
    status = str(exposure.get("status") or "")
    if status in LOW_EXPOSURE_STATUSES:
        return True
    candidate_added = exposure.get("candidate_added_cards") or {}
    if "all_cards_used" in candidate_added:
        return not bool(candidate_added.get("all_cards_used"))
    return False


def low_exposure_decision(
    exposure: dict[str, Any],
    forced_access_mode: str = "none",
) -> str | None:
    if not exposure_requires_inconclusive(exposure):
        return None
    if forced_access_mode and forced_access_mode != "none":
        return "forced_access_inconclusive_low_exposure"
    return "inconclusive_low_exposure"


def infer_package_decision(result: dict[str, Any]) -> str:
    exposure = result.get("exposure_summary") or {}
    forced_access_mode = str(result.get("forced_access_mode") or "none")
    exposure_decision = low_exposure_decision(exposure, forced_access_mode)
    if result.get("decision"):
        decision = str(result["decision"])
        if decision in INCONCLUSIVE_EXPOSURE_DECISIONS:
            return decision
        if exposure_decision:
            return exposure_decision
        if decision in REJECTED_PRIOR_DECISIONS:
            return decision
        return "reject_or_rework" if decision.startswith("reject") else decision
    aggregate = result.get("aggregate") or {}
    aggregate_decision = str(aggregate.get("decision") or "")
    if aggregate_decision:
        if exposure_decision:
            return exposure_decision
        return "reject_or_rework" if aggregate_decision.startswith("reject") else aggregate_decision
    gate = result.get("gate_summary") or {}
    baseline = gate.get("baseline") or {}
    candidate = gate.get("candidate") or {}
    baseline_wins = int(baseline.get("wins") or 0)
    candidate_wins = int(candidate.get("wins") or 0)
    delta = float(gate.get("delta_pp") or 0.0)
    if delta < 0 or candidate_wins < baseline_wins:
        if exposure_decision:
            return exposure_decision
        return "reject_or_rework"
    if delta > 0 or candidate_wins > baseline_wins:
        return "promote_to_deeper_gate"
    return "tie_or_unknown"


def side_from_record_string(raw: Any) -> dict[str, Any]:
    if not isinstance(raw, str):
        return {}
    match = re.match(r"^\s*(\d+)-(\d+)(?:-(\d+))?\s*$", raw)
    if not match:
        return {}
    wins = int(match.group(1))
    losses = int(match.group(2))
    stalls = int(match.group(3) or 0)
    games = max(1, wins + losses + stalls)
    return {
        "wins": wins,
        "losses": losses,
        "stalls": stalls,
        "win_rate": round(wins / games * 100, 2),
    }


def side_from_flat_result(result: dict[str, Any], prefix: str) -> dict[str, Any]:
    side = side_from_record_string(result.get(prefix))
    wins_key = f"{prefix}_wins"
    losses_key = f"{prefix}_losses"
    if result.get(wins_key) is not None and result.get(losses_key) is not None:
        wins = int(result.get(wins_key) or 0)
        losses = int(result.get(losses_key) or 0)
        games = max(1, wins + losses)
        side.update(
            {
                "wins": wins,
                "losses": losses,
                "stalls": side.get("stalls", 0),
                "win_rate": round(wins / games * 100, 2),
            }
        )
    return side


def gate_summary_from_flat_result(result: dict[str, Any]) -> dict[str, Any]:
    baseline = side_from_flat_result(result, "baseline")
    candidate = side_from_flat_result(result, "candidate")
    if not baseline and not candidate and result.get("delta_pp") is None:
        return {}
    return {
        "baseline": baseline,
        "candidate": candidate,
        "delta_pp": result.get("delta_pp"),
    }


def package_rows_from_prior_payload(payload: Any) -> list[dict[str, Any]]:
    if not isinstance(payload, dict):
        return []
    rows: list[dict[str, Any]] = []
    rollups = payload.get("package_rollups")
    if isinstance(rollups, list):
        decision_by_status = {
            "natural_deeper_gate_candidate": "promote_to_deeper_gate",
            "natural_reject_current_pair": "reject_or_rework",
            "forced_access_requires_natural_confirmation": (
                "forced_access_signal_requires_natural_confirmation"
            ),
            "forced_access_no_lift_reject_or_rework": "forced_access_no_lift_reject_or_rework",
            "used_without_cut_comparator": "candidate_used_without_cut_comparator",
            "insufficient_card_outcome_sample": "insufficient_card_outcome_used_sample",
            "accessed_without_use_conversion_review": "candidate_accessed_without_used_sample",
            "near_access_without_use_access_window_review": (
                "candidate_near_access_without_used_sample"
            ),
            "inconclusive_low_candidate_use": "inconclusive_low_exposure",
            "missing_per_card_data": "missing_per_card_outcome_data",
        }
        for row in rollups:
            if not isinstance(row, dict):
                continue
            copied = dict(row)
            copied.setdefault("source_section", "package_rollups")
            copied["decision"] = decision_by_status.get(
                str(row.get("status") or ""),
                str(row.get("status") or "unknown"),
            )
            if "gate_summary" not in copied:
                copied["gate_summary"] = {
                    "delta_pp": row.get("worst_aggregate_delta_pp")
                }
            rows.append(copied)
        return rows
    packages = payload.get("packages")
    if isinstance(packages, list):
        rows.extend(row for row in packages if isinstance(row, dict))
    for section_name in ("post_squee_package_gates", "safe_package_gates"):
        section = payload.get(section_name)
        section_rows = section.get("rows") if isinstance(section, dict) else None
        if isinstance(section_rows, list):
            for row in section_rows:
                if isinstance(row, dict):
                    copied = dict(row)
                    copied.setdefault("source_section", section_name)
                    rows.append(copied)
    manifest = payload.get("cut_safety_manifest")
    cuts = manifest.get("cuts") if isinstance(manifest, dict) else None
    if isinstance(cuts, list):
        for cut in cuts:
            if not isinstance(cut, dict):
                continue
            cut_card = str(cut.get("card_name") or "").strip()
            observations = cut.get("observations")
            if not isinstance(observations, list):
                continue
            for observation in observations:
                if not isinstance(observation, dict):
                    continue
                row = dict(observation)
                if cut_card and not row.get("cuts"):
                    row["cuts"] = [cut_card]
                row.setdefault("source_section", "cut_safety_manifest")
                if "gate_summary" not in row:
                    row["gate_summary"] = gate_summary_from_flat_result(row)
                rows.append(row)
    return rows


def rejected_package_evidence(
    prior_package_reports: list[tuple[Path, dict[str, Any]]],
) -> dict[str, dict[str, Any]]:
    rejected: dict[str, dict[str, Any]] = {}
    for path, payload in prior_package_reports:
        for result in package_rows_from_prior_payload(payload):
            if not isinstance(result, dict):
                continue
            key = str(result.get("package_key") or "")
            if not key:
                continue
            if "gate_summary" not in result:
                flat_gate = gate_summary_from_flat_result(result)
                if flat_gate:
                    result = {**result, "gate_summary": flat_gate}
            decision = infer_package_decision(result)
            if decision not in REJECTED_PRIOR_DECISIONS:
                if decision in INCONCLUSIVE_EXPOSURE_DECISIONS:
                    rejected.pop(key, None)
                continue
            gate = result.get("gate_summary") or {}
            aggregate = result.get("aggregate") or {}
            rejected[key] = {
                "package_key": key,
                "source_report": str(path),
                "source_section": result.get("source_section"),
                "adds": result.get("adds") or [],
                "cuts": result.get("cuts") or [],
                "decision": decision,
                "delta_pp": gate.get(
                    "delta_pp",
                    aggregate.get("delta_pp_total", result.get("delta_pp")),
                ),
                "baseline": gate.get("baseline") or {},
                "candidate": gate.get("candidate") or {},
                "aggregate": aggregate,
            }
    return rejected


def inconclusive_package_evidence(
    prior_package_reports: list[tuple[Path, dict[str, Any]]],
) -> dict[str, dict[str, Any]]:
    inconclusive: dict[str, dict[str, Any]] = {}
    for path, payload in prior_package_reports:
        payload_has_cut_safety = bool(payload.get("cut_safety_report"))
        payload_has_prior_reports = bool(payload.get("prior_package_reports"))
        evidence_scope = (
            "strategy_gate"
            if payload_has_cut_safety and payload_has_prior_reports
            else "diagnostic_or_contract"
        )
        for result in package_rows_from_prior_payload(payload):
            if not isinstance(result, dict):
                continue
            key = str(result.get("package_key") or "")
            if not key:
                continue
            if "gate_summary" not in result:
                flat_gate = gate_summary_from_flat_result(result)
                if flat_gate:
                    result = {**result, "gate_summary": flat_gate}
            decision = infer_package_decision(result)
            if decision not in INCONCLUSIVE_EXPOSURE_DECISIONS:
                if decision in REJECTED_PRIOR_DECISIONS:
                    inconclusive.pop(key, None)
                continue
            gate = result.get("gate_summary") or {}
            aggregate = result.get("aggregate") or {}
            exposure = result.get("exposure_summary") or {}
            candidate_added = exposure.get("candidate_added_cards") or {}
            cards = candidate_added.get("cards") or []
            inconclusive[key] = {
                "package_key": key,
                "source_report": str(path),
                "source_section": result.get("source_section"),
                "evidence_scope": evidence_scope,
                "adds": result.get("adds") or [],
                "cuts": result.get("cuts") or [],
                "decision": decision,
                "delta_pp": gate.get(
                    "delta_pp",
                    aggregate.get("delta_pp_total", result.get("delta_pp")),
                ),
                "baseline": gate.get("baseline") or {},
                "candidate": gate.get("candidate") or {},
                "exposure_status": exposure.get("status"),
                "exposure_next_step": exposure.get("next_step"),
                "candidate_added_card_statuses": [
                    {
                        "card_name": row.get("card_name"),
                        "status": row.get("status"),
                        "recorded_use_count": row.get("recorded_use_count"),
                        "used_games": ((row.get("outcome_summary") or {}).get("used_games") or {}).get("games"),
                        "accessed_games": (row.get("access_profile") or {}).get("accessed_games"),
                        "near_access_games": (row.get("access_profile") or {}).get("near_access_games"),
                        "library_only_games": (row.get("access_profile") or {}).get("library_only_games"),
                    }
                    for row in cards
                    if isinstance(row, dict)
                ],
            }
    return inconclusive


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


def latest_recursion_cut_model(
    recursion_cut_model_reports: list[tuple[Path, dict[str, Any]]],
) -> tuple[Path, dict[str, Any]] | None:
    if not recursion_cut_model_reports:
        return None
    return recursion_cut_model_reports[-1]


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
    recursion_cut_model_reports: list[tuple[Path, dict[str, Any]]] | None = None,
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
    recursion_model = latest_recursion_cut_model(recursion_cut_model_reports or [])
    if recursion_model:
        model_path, model_payload = recursion_model
        preflight_rows = [
            row
            for row in model_payload.get("preflight_benchmark_candidates") or []
            if row.get("status") == "preflight_benchmark_ready"
        ]
        blocked_prior = [
            row
            for row in model_payload.get("pair_evaluations") or []
            if row.get("status") in {"blocked_prior_reject", "blocked_cut_prior_reject"}
        ]
        if preflight_rows:
            top = preflight_rows[0]
            return {
                "priority": 3,
                "action_key": "run_recursion_benchmark_gate",
                "status": "same_lane_benchmark_ready",
                "lane": "graveyard_recursion",
                "candidate_cards": [str(top.get("candidate") or "")],
                "cut_cards": [str(top.get("cut") or "")],
                "why_now": (
                    "The recursion cut model has protected Squee and found a non-Squee same-lane benchmark."
                ),
                "blockers": [
                    "the proposed cut is a benchmark, not a promotion",
                    "the gate must prove that added recursion beats the lost current engine slot",
                ],
                "next_steps": [
                    "Run package preflight for prior-negative evidence.",
                    "Run the smallest equal gate only if preflight is clear.",
                    "If rejected, add the exact report to prior package defaults and rerun this model.",
                ],
                "recursion_cut_model_report": str(model_path),
                "preflight_benchmark_candidates": preflight_rows[:5],
                "blocked_prior_rejections": blocked_prior[:5],
            }
        return {
            "priority": 90,
            "action_key": "avoid_recursion_without_non_squee_cut",
            "status": "no_recursion_benchmark_ready",
            "lane": "graveyard_recursion",
            "candidate_cards": [],
            "cut_cards": [],
            "why_now": (
                "The recursion cut model found no safe non-Squee benchmark after protected cuts and prior rejects."
            ),
            "blockers": ["no preflight_benchmark_ready recursion pair remains"],
            "next_steps": [
                "Do not cut Squee, Farewell, Furygale Flocking, Mizzix's Mastery, or Pinnacle Monk for current recursion candidates.",
                "Return to this lane only with a different cut or a multi-card package that preserves the current engine.",
            ],
            "recursion_cut_model_report": str(model_path),
            "blocked_prior_rejections": blocked_prior[:5],
        }
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


def mana_swap_summary(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [
        {
            "candidate": row.get("candidate"),
            "cut": row.get("cut"),
            "score": row.get("score"),
            "deltas": row.get("deltas") or {},
            "gained_roles": row.get("gained_roles") or [],
            "lost_roles": row.get("lost_roles") or [],
        }
        for row in rows
    ]


def build_mana_action(
    miner_report: dict[str, Any],
    *,
    mana_base_validator_reports: list[tuple[Path, dict[str, Any]]] | None = None,
) -> dict[str, Any] | None:
    pairings = pairing_rows(
        miner_report,
        status="blocked_no_safe_cut_in_lane",
        lane="mana_base",
    )
    if not pairings:
        return None
    candidates = [str(row["candidate"]) for row in pairings[:6]]
    cuts = summarize_cut_options(pairings, limit=6)
    if mana_base_validator_reports:
        validator_path, validator_payload = mana_base_validator_reports[-1]
        ready = list(validator_payload.get("ready_swaps") or [])
        ready.sort(key=lambda row: (-int(row.get("score") or 0), row.get("candidate") or ""))
        if ready:
            top = ready[:5]
            return {
                "priority": 4,
                "action_key": "run_mana_base_validated_preflight",
                "status": "mana_base_preflight_ready",
                "lane": "mana_base",
                "candidate_cards": sorted({str(row["candidate"]) for row in top}),
                "cut_cards": [str(row["cut"]) for row in top if row.get("cut")],
                "why_now": (
                    "The mana-base validator found deterministic land upgrades that preserve "
                    "Boros color access and avoid protected utility cuts."
                ),
                "blockers": [],
                "next_steps": [
                    "Build the smallest exact land package from the top validator swap.",
                    "Use package preflight rather than a noisy battle gate; only battle-test if the deterministic model is disputed.",
                    "Do not cut fetches, Ancient Tomb, Command Beacon, or prior negative land-gate cuts.",
                ],
                "mana_base_validator_report": str(validator_path),
                "ready_swap_count": int(
                    (validator_payload.get("summary") or {}).get("ready_swap_count") or len(ready)
                ),
                "top_ready_swaps": mana_swap_summary(top),
            }
        return {
            "priority": 90,
            "action_key": "avoid_mana_base_without_safe_color_swap",
            "status": "no_mana_base_preflight_ready",
            "lane": "mana_base",
            "candidate_cards": candidates,
            "cut_cards": [str(row["card_name"]) for row in cuts if row.get("card_name")],
            "why_now": (
                "The mana-base validator found no deterministic swap that preserves color sources "
                "and protected utility roles."
            ),
            "blockers": [
                "no validator-ready land swap",
                "battle gate cannot isolate mana consistency from game variance",
            ],
            "next_steps": [
                "Move to runtime/XMage rule-gap batching before another land test.",
                "Reopen mana base only with a new candidate or a cut that the validator marks preflight-ready.",
            ],
            "mana_base_validator_report": str(validator_path),
        }
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


def build_cut_exposure_action(
    manual_review: dict[str, Any],
    profiled_cut_benchmark_reports: list[tuple[Path, dict[str, Any]]] | None = None,
) -> dict[str, Any] | None:
    expansion = manual_review.get("cut_evidence_expansion") or {}
    summary = expansion.get("summary") or {}
    top_rows = list(expansion.get("top_exposure_candidates") or [])
    if int(summary.get("model_cut_exposure_count") or 0) > 0 and top_rows:
        top = top_rows[:8]
        return {
            "priority": -3,
            "action_key": "model_low_exposure_cut_slots_before_gate",
            "status": "cut_safety_expansion_required",
            "lane": "cut_modeling",
            "candidate_cards": [],
            "cut_cards": [str(row.get("card_name") or "") for row in top],
            "why_now": (
                "The safe-cut replanner found zero gate-ready packages because current cuts lack "
                "explicit safety evidence or hit protected structure. The next useful work is to "
                "model the lowest-risk cut slots before another card package gate."
            ),
            "blockers": [
                "safe-cut manifest_ready_count is zero",
                "current proposed cuts are blocked by structure, prior rejection, or missing cut-safety rows",
                "battle gates without cut exposure would retest blind cuts",
            ],
            "next_steps": [
                "Build an exposure profile for the top cut slots from current replays and deck comparison.",
                "Only promote a cut to package preflight if exposure shows low strategic dependency and no prior rejection.",
                "Prefer same-lane replacement gates after cut exposure, not cross-lane swaps.",
            ],
            "cut_evidence_summary": summary,
            "top_cut_exposure_candidates": top,
        }
    same_lane_rows = list(expansion.get("top_same_lane_candidates") or [])
    if int(summary.get("manual_same_lane_only_count") or 0) > 0 and same_lane_rows:
        top = same_lane_rows[:8]
        protected = list(expansion.get("top_protected_exposure_slots") or [])[:8]
        latest_benchmark = latest_profiled_cut_benchmark(profiled_cut_benchmark_reports)
        if latest_benchmark and is_profiled_cut_benchmark_exhausted(latest_benchmark[1]):
            benchmark_summary = latest_benchmark[1].get("summary") or {}
            return {
                "priority": 3,
                "action_key": "record_profiled_same_lane_benchmarks_exhausted",
                "status": "profiled_same_lane_benchmark_queue_exhausted",
                "lane": "cut_modeling",
                "candidate_cards": [],
                "cut_cards": [str(row.get("card_name") or "") for row in top],
                "why_now": (
                    "The profiled same-lane benchmark generator found no remaining preflight-ready "
                    "packages after loading prior negative evidence."
                ),
                "blockers": [
                    "same-lane candidate queue is exhausted for the currently profiled cuts",
                    "all evaluated same-lane packages either regressed strong seed 42 or are blocked by prior evidence",
                ],
                "next_steps": [
                    "Do not keep rerunning the profiled cut benchmark generator until the shell, corpus, or runtime rules change.",
                    "Move to focus-access trace review and failure-targeted package synthesis.",
                    "Reopen these cuts only if new variant cards become runtime-ready or the cut model changes.",
                ],
                "cut_evidence_summary": summary,
                "top_same_lane_cut_candidates": top,
                "protected_high_exposure_cut_slots": protected,
                "profiled_cut_benchmark_report": str(latest_benchmark[0]),
                "profiled_cut_benchmark_summary": benchmark_summary,
            }
        return {
            "priority": -3,
            "action_key": "build_same_lane_benchmarks_from_profiled_cut_slots",
            "status": "cut_exposure_profiled_requires_same_lane_package",
            "lane": "cut_modeling",
            "candidate_cards": [],
            "cut_cards": [str(row.get("card_name") or "") for row in top],
            "why_now": (
                "Cut exposure has been measured. High-exposure slots are protected, and the "
                "remaining cut candidates require same-lane benchmark packages before any battle gate."
            ),
            "blockers": [
                "profiled cuts still are not automatic promotions",
                "same-lane replacement package is required before preflight",
                "high-exposure cut slots must remain protected unless a direct replacement wins",
            ],
            "next_steps": [
                "Build candidate packages only against the profiled same-lane cut slots.",
                "Reject cross-lane swaps that reduce miracle density, protection, or engine access.",
                "Run package preflight first; run a small equal gate only after preflight finds no prior-negative exact package.",
            ],
            "cut_evidence_summary": summary,
            "top_same_lane_cut_candidates": top,
            "protected_high_exposure_cut_slots": protected,
        }
    return None


def build_inconclusive_exposure_action(
    inconclusive_packages: dict[str, dict[str, Any]],
) -> dict[str, Any] | None:
    if not inconclusive_packages:
        return None
    rows = sorted(
        inconclusive_packages.values(),
        key=lambda row: (
            row.get("evidence_scope") != "strategy_gate",
            row.get("package_key") or "",
        ),
    )
    strategy_rows = [row for row in rows if row.get("evidence_scope") == "strategy_gate"]
    diagnostic_rows = [row for row in rows if row.get("evidence_scope") != "strategy_gate"]
    priority = -4 if strategy_rows else 6
    status = (
        "resolve_strategy_gate_low_exposure_before_next_swap"
        if strategy_rows
        else "diagnostic_low_exposure_recorded_no_strategy_block"
    )
    return {
        "priority": priority,
        "action_key": "resolve_inconclusive_package_exposures",
        "status": status,
        "lane": "battle_gate_evidence_quality",
        "candidate_cards": sorted(
            {
                str(card)
                for row in rows
                for card in (row.get("adds") or [])
                if str(card).strip()
            }
        ),
        "cut_cards": sorted(
            {
                str(card)
                for row in rows
                for card in (row.get("cuts") or [])
                if str(card).strip()
            }
        ),
        "why_now": (
            "Some package gates reached deck-level results without proving that the added card "
            "was actually drawn, accessed, cast, activated, or otherwise used."
        ),
        "blockers": [
            "deck-level win rate is not card-level proof when the added card has low exposure",
            "inconclusive packages must not be promoted or treated as rejected exact packages",
        ],
        "next_steps": [
            "For strategy-gate rows, rerun with a larger natural sample or a forced-access diagnostic followed by natural confirmation.",
            "For diagnostic/contract rows, keep them as evidence-quality examples and do not let them outrank current strategy actions.",
            "Only count a future result as card evidence when recorded_use_count or accessed_games confirms exposure.",
        ],
        "strategy_gate_inconclusive_count": len(strategy_rows),
        "diagnostic_or_contract_inconclusive_count": len(diagnostic_rows),
        "packages": rows[:12],
    }


def deck_contains(strategy_audit: dict[str, Any], card_name: str) -> bool:
    wanted = normalize_key(card_name)
    for summary in (strategy_audit.get("deck_summaries") or {}).values():
        for row in summary.get("cards") or []:
            if normalize_key(row.get("card_name")) == wanted:
                return True
    return False


def current_engine_audit_targets(strategy_audit: dict[str, Any]) -> list[str]:
    target_names = [
        "Urza's Saga",
        "Library of Leng",
        "Sensei's Divining Top",
        "Scroll Rack",
        "Squee, Goblin Nabob",
        "The Mind Stone",
        "Land Tax",
    ]
    return [name for name in target_names if deck_contains(strategy_audit, name)]


def build_strategy_synthesis_action(
    strategy_audit: dict[str, Any] | None,
    hypothesis_queue: dict[str, Any] | None,
) -> dict[str, Any] | None:
    if not strategy_audit or not hypothesis_queue:
        return None
    queue_summary = hypothesis_queue.get("summary") or {}
    if int(queue_summary.get("gate_ready_count") or 0) > 0:
        return None
    tested_negative = int(queue_summary.get("tested_negative_count") or 0)
    if tested_negative <= 0:
        return None

    dependency_map = strategy_audit.get("strategy_dependency_map") or {}
    contract = dependency_map.get("next_hypothesis_contract") or {}
    benchmark = (dependency_map.get("current_benchmark") or {}).get("champion") or {}
    pillars = dependency_map.get("dependency_pillars") or []
    runtime_summary = (strategy_audit.get("runtime_package_readiness") or {}).get("summary") or {}
    focus_cards = current_engine_audit_targets(strategy_audit)
    external_sources = [
        {"name": row.get("name"), "url": row.get("url"), "use": row.get("use")}
        for row in strategy_audit.get("external_method_sources") or []
        if row.get("name") and row.get("url")
    ]
    return {
        "priority": -1,
        "action_key": "build_failure_targeted_synergy_hypotheses",
        "status": "hypothesis_queue_exhausted_requires_new_synthesis",
        "lane": "strategy_learning",
        "candidate_cards": focus_cards,
        "cut_cards": [],
        "why_now": (
            f"The current hypothesis queue has 0 gate-ready packages and {tested_negative} tested negatives. "
            "The next move must explain the failed seeds and existing-engine sequencing before another card swap."
        ),
        "blockers": [
            "all current package hypotheses are prior-negative",
            "protected cuts cannot be repeated without same-lane proof",
            "seed 7 and seed 20260625 still show missing-engine or conversion failures",
        ],
        "next_steps": [
            "Mine seed 7 and seed 20260625 traces for missing-engine versus engine-failed-to-convert patterns.",
            "Audit utilization of existing engine pieces before adding cards: Urza's Saga, Library of Leng, Top, Rack, Squee, The Mind Stone, and Land Tax when present.",
            "Generate a fresh candidate package queue that suppresses exact prior negatives and rejects locked cuts before battle.",
            "Only register a new package when it targets a named failure mode and preserves seed-42 miracle/topdeck telemetry.",
        ],
        "evidence": {
            "queue_summary": queue_summary,
            "current_champion_key": strategy_audit.get("current_champion_key"),
            "champion_record": {
                "record": benchmark.get("record"),
                "games": benchmark.get("games"),
                "win_rate": benchmark.get("win_rate"),
                "wins": benchmark.get("wins"),
                "losses": benchmark.get("losses"),
            },
            "must_target": contract.get("must_target") or [],
            "required_telemetry": contract.get("required_telemetry") or [],
            "focus_pillars": [
                {
                    "pillar": row.get("pillar"),
                    "risk": row.get("risk"),
                    "next_requirement": row.get("next_requirement"),
                    "depends_on": row.get("depends_on") or [],
                }
                for row in pillars
            ],
            "runtime_package_readiness": runtime_summary,
            "external_method_sources": external_sources,
        },
    }


def build_focus_access_trace_action(trace_audit: dict[str, Any] | None) -> dict[str, Any] | None:
    if not trace_audit:
        return None
    summary = trace_audit.get("summary") or {}
    recommended = str(summary.get("recommended_next_action") or "")
    status_counts = summary.get("trace_status_counts") or {}
    if recommended != "review_focus_access_trace_then_define_next_deck_or_runtime_package":
        return None
    if not (
        status_counts.get("focus_access_trace_available_review_sequence")
        or status_counts.get("focus_access_trace_available_review_conversion")
    ):
        return None
    assessments = []
    focus_cards = set()
    for row in trace_audit.get("hypothesis_assessments") or []:
        status = str(row.get("trace_status") or "")
        if status not in {
            "focus_access_trace_available_review_sequence",
            "focus_access_trace_available_review_conversion",
            "trace_evidence_supports_sequencing_gap",
            "runtime_trace_payload_available_review_model_scope",
        }:
            continue
        cards = [str(card) for card in row.get("focus_cards") or []]
        focus_cards.update(cards)
        assessments.append(
            {
                "hypothesis_key": row.get("hypothesis_key"),
                "trace_status": status,
                "target_seeds": row.get("target_seeds") or [],
                "focus_cards": cards,
                "next_action": row.get("next_action"),
                "current_limitations": (row.get("current_limitations") or [])[:3],
            }
        )
    return {
        "priority": -2,
        "action_key": "review_focus_access_trace_then_define_next_deck_or_runtime_package",
        "status": "focus_access_trace_ready_for_package_design",
        "lane": "strategy_learning",
        "candidate_cards": sorted(focus_cards),
        "cut_cards": [],
        "why_now": (
            "The latest failure-targeted audit has per-game access snapshots for the weak seeds. "
            "The blocker moved from missing telemetry to deciding whether access density, conversion timing, "
            "or runtime sequencing should be tested next."
        ),
        "blockers": [
            "seed 7 and seed 20260625 still lose 0-9 in the candidate-only access diagnostics",
            "Squee and Land Tax are not naturally accessible in the weak seeds even though seed 42 wins when access appears early",
            "prior exact tutor-over-Land-Tax benchmarks are negative, so the next package must preserve protected engine pieces unless a same-lane cut model proves otherwise",
        ],
        "next_steps": [
            "Build a small access package that increases early Top/Rack/Library/Squee reach without repeating rejected Land Tax cuts.",
            "Prefer cards already in local oracle/rule scope, then gate only the package that preserves seed-42 miracle/topdeck telemetry.",
            "If the package cannot be evaluated because a card lacks runtime behavior, route that card to XMage/runtime implementation before battle.",
        ],
        "evidence": {
            "trace_summary": summary,
            "candidate_key": trace_audit.get("candidate_key"),
            "hypothesis_assessments": assessments,
        },
    }


def build_guardrails(
    miner_report: dict[str, Any],
    manual_review: dict[str, Any],
    hypothesis_queue: dict[str, Any] | None = None,
    prior_package_reports: list[tuple[Path, dict[str, Any]]] | None = None,
    inconclusive_packages: dict[str, dict[str, Any]] | None = None,
    profiled_cut_benchmark_reports: list[tuple[Path, dict[str, Any]]] | None = None,
) -> list[dict[str, Any]]:
    negative = miner_report.get("negative_exact_packages") or []
    prior_rejections = rejected_package_evidence(prior_package_reports or [])
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
    if prior_rejections:
        guardrails.append(
            {
                "guardrail_key": "prior_package_reports_have_rejections",
                "rejected_package_count": len(prior_rejections),
                "rejected_package_keys": sorted(prior_rejections),
                "reason": (
                    "Loaded prior package reports include explicit rejected package evidence; "
                    "the planner must not recommend those exact add/cut packages as fresh gates."
                ),
            }
        )
    if inconclusive_packages:
        guardrails.append(
            {
                "guardrail_key": "inconclusive_low_exposure_is_not_card_proof",
                "inconclusive_package_count": len(inconclusive_packages),
                "inconclusive_package_keys": sorted(inconclusive_packages),
                "reason": (
                    "A package with low added-card exposure or too few used-card games cannot "
                    "be promoted or rejected as card-level evidence until the card sample is real."
                ),
            }
        )
    latest_benchmark = latest_profiled_cut_benchmark(profiled_cut_benchmark_reports)
    if latest_benchmark and is_profiled_cut_benchmark_exhausted(latest_benchmark[1]):
        guardrails.append(
            {
                "guardrail_key": "profiled_same_lane_benchmark_queue_exhausted",
                "source_report": str(latest_benchmark[0]),
                "reason": (
                    "The latest profiled cut benchmark generator has no remaining preflight-ready "
                    "same-lane package, so the planner must advance to trace or runtime work."
                ),
            }
        )
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
    if hypothesis_queue:
        queue_summary = hypothesis_queue.get("summary") or {}
        if (
            int(queue_summary.get("gate_ready_count") or 0) == 0
            and int(queue_summary.get("tested_negative_count") or 0) > 0
        ):
            guardrails.append(
                {
                    "guardrail_key": "current_hypothesis_queue_exhausted",
                    "reason": (
                        "The latest hypothesis queue has no gate-ready package; generate new failure-targeted "
                        "hypotheses instead of rerunning prior-negative swaps."
                    ),
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
    recursion_cut_model_reports: list[tuple[Path, dict[str, Any]]] | None = None,
    mana_base_validator_reports: list[tuple[Path, dict[str, Any]]] | None = None,
    profiled_cut_benchmark_reports: list[tuple[Path, dict[str, Any]]] | None = None,
    prior_package_reports: list[tuple[Path, dict[str, Any]]] | None = None,
    strategy_audit: dict[str, Any] | None = None,
    hypothesis_queue: dict[str, Any] | None = None,
    trace_audit: dict[str, Any] | None = None,
    miner_path: Path = DEFAULT_MINER_REPORT,
    manual_path: Path = DEFAULT_MANUAL_REVIEW,
    strategy_path: Path = DEFAULT_STRATEGY_AUDIT,
    hypothesis_queue_path: Path = DEFAULT_HYPOTHESIS_QUEUE,
    trace_audit_path: Path = DEFAULT_TRACE_AUDIT,
) -> dict[str, Any]:
    exposures = exposure_lookup(exposure_profiles)
    gate_ready = pairing_rows(miner_report, status="gate_ready_safe_same_lane")
    actions = []
    prior_rejections = rejected_package_evidence(prior_package_reports or [])
    inconclusive_packages = inconclusive_package_evidence(prior_package_reports or [])
    cut_exposure_action = build_cut_exposure_action(
        manual_review,
        profiled_cut_benchmark_reports=profiled_cut_benchmark_reports,
    )
    if cut_exposure_action:
        actions.append(cut_exposure_action)
    inconclusive_action = build_inconclusive_exposure_action(inconclusive_packages)
    if inconclusive_action:
        actions.append(inconclusive_action)
    trace_action = build_focus_access_trace_action(trace_audit)
    if trace_action:
        actions.append(trace_action)
    strategy_action = build_strategy_synthesis_action(strategy_audit, hypothesis_queue)
    if strategy_action:
        actions.append(strategy_action)
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
        build_recursion_action(
            miner_report,
            manual_review,
            exposures,
            recursion_cut_model_reports=recursion_cut_model_reports,
        ),
        build_mana_action(
            miner_report,
            mana_base_validator_reports=mana_base_validator_reports,
        ),
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
        "strategy_audit": str(strategy_path) if strategy_audit else "",
        "hypothesis_queue": str(hypothesis_queue_path) if hypothesis_queue else "",
        "trace_audit": str(trace_audit_path) if trace_audit else "",
        "exposure_profiles": [str(path) for path, _payload in exposure_profiles],
        "tutor_cut_model_reports": [
            str(path) for path, _payload in (tutor_cut_model_reports or [])
        ],
        "hand_filter_cut_model_reports": [
            str(path) for path, _payload in (hand_filter_cut_model_reports or [])
        ],
        "recursion_cut_model_reports": [
            str(path) for path, _payload in (recursion_cut_model_reports or [])
        ],
        "mana_base_validator_reports": [
            str(path) for path, _payload in (mana_base_validator_reports or [])
        ],
        "profiled_cut_benchmark_reports": [
            str(path) for path, _payload in (profiled_cut_benchmark_reports or [])
        ],
        "prior_package_reports": [str(path) for path, _payload in (prior_package_reports or [])],
        "postgres_writes": False,
        "source_db_mutated": False,
        "summary": {
            "gate_ready_now_count": len(gate_ready),
            "action_count": len(actions),
            "action_status_counts": dict(sorted(status_counts.items())),
            "recommended_next_action": recommended,
            "prior_rejected_package_count": len(prior_rejections),
            "prior_rejected_package_keys": sorted(prior_rejections),
            "prior_inconclusive_low_exposure_count": len(inconclusive_packages),
            "prior_inconclusive_low_exposure_keys": sorted(inconclusive_packages),
            "miner_candidate_status_counts": (miner_report.get("summary") or {}).get(
                "candidate_status_counts",
                {},
            ),
            "miner_pairing_status_counts": (miner_report.get("summary") or {}).get(
                "pairing_status_counts",
                {},
            ),
            "hypothesis_queue_status_counts": (
                (hypothesis_queue or {}).get("summary") or {}
            ).get("status_counts", {}),
            "trace_audit_status_counts": (
                (trace_audit or {}).get("summary") or {}
            ).get("trace_status_counts", {}),
        },
        "action_queue": actions,
        "guardrails": build_guardrails(
            miner_report,
            manual_review,
            hypothesis_queue,
            prior_package_reports,
            inconclusive_packages,
            profiled_cut_benchmark_reports,
        ),
        "method_notes": [
            "This planner is a decision layer, not a promotion engine.",
            "A runtime-ready card is not gate-ready unless a safe cut model exists.",
            "Exposure evidence is used to protect proven roles and to decide which lane needs profiling next.",
            "An exhausted hypothesis queue routes back to failure-targeted strategy synthesis before any new gate.",
            "A completed focus-access trace routes to package design; do not regenerate the same payload unless the deck list changes.",
            "An exhausted profiled cut benchmark queue routes to trace/runtime synthesis instead of repeated same-lane generators.",
            "PostgreSQL and SQLite are not mutated by this script.",
        ],
    }


def render_markdown(payload: dict[str, Any]) -> str:
    generated_date = str(payload.get("generated_at") or "")[:10] or "unknown-date"
    lines = [
        f"# Lorehold Next Action Planner - {generated_date}",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Miner report: `{payload['miner_report']}`",
        f"- Manual review: `{payload['manual_review']}`",
        f"- Strategy audit: `{payload.get('strategy_audit') or '-'}`",
        f"- Hypothesis queue: `{payload.get('hypothesis_queue') or '-'}`",
        f"- Trace audit: `{payload.get('trace_audit') or '-'}`",
        f"- Exposure profiles: `{', '.join(payload['exposure_profiles'])}`",
        f"- Tutor cut model reports: `{', '.join(payload.get('tutor_cut_model_reports') or []) or '-'}`",
        f"- Hand-filter cut model reports: `{', '.join(payload.get('hand_filter_cut_model_reports') or []) or '-'}`",
        f"- Recursion cut model reports: `{', '.join(payload.get('recursion_cut_model_reports') or []) or '-'}`",
        f"- Mana-base validator reports: `{', '.join(payload.get('mana_base_validator_reports') or []) or '-'}`",
        f"- Profiled cut benchmark reports: `{', '.join(payload.get('profiled_cut_benchmark_reports') or []) or '-'}`",
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
        f"- Prior rejected packages loaded: `{payload['summary']['prior_rejected_package_count']}`",
        f"- Prior rejected package keys: `{', '.join(payload['summary']['prior_rejected_package_keys']) or '-'}`",
        f"- Prior inconclusive low-exposure packages loaded: `{payload['summary']['prior_inconclusive_low_exposure_count']}`",
        f"- Prior inconclusive low-exposure package keys: `{', '.join(payload['summary']['prior_inconclusive_low_exposure_keys']) or '-'}`",
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
    parser.add_argument("--strategy-audit", type=Path, default=DEFAULT_STRATEGY_AUDIT)
    parser.add_argument("--hypothesis-queue", type=Path, default=DEFAULT_HYPOTHESIS_QUEUE)
    parser.add_argument("--trace-audit", type=Path, default=DEFAULT_TRACE_AUDIT)
    parser.add_argument("--exposure-profile", type=Path, action="append")
    parser.add_argument("--tutor-cut-model-report", type=Path, action="append")
    parser.add_argument("--hand-filter-cut-model-report", type=Path, action="append")
    parser.add_argument("--recursion-cut-model-report", type=Path, action="append")
    parser.add_argument("--mana-base-validator-report", type=Path, action="append")
    parser.add_argument("--profiled-cut-benchmark-report", type=Path, action="append")
    parser.add_argument("--prior-package-report", type=Path, action="append")
    parser.add_argument("--stem", default="lorehold_next_action_planner_20260630_current")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    miner_report = read_json(args.miner_report)
    manual_review = read_json(args.manual_review)
    strategy_audit = read_json(args.strategy_audit) if args.strategy_audit.exists() else None
    hypothesis_queue = read_json(args.hypothesis_queue) if args.hypothesis_queue.exists() else None
    trace_audit = read_json(args.trace_audit) if args.trace_audit.exists() else None
    exposure_paths = args.exposure_profile or DEFAULT_EXPOSURE_PROFILES
    exposure_profiles = read_existing_json(exposure_paths)
    tutor_cut_model_reports = read_existing_json(
        args.tutor_cut_model_report or DEFAULT_TUTOR_CUT_MODEL_REPORTS
    )
    hand_filter_cut_model_reports = read_existing_json(
        args.hand_filter_cut_model_report or DEFAULT_HAND_FILTER_CUT_MODEL_REPORTS
    )
    recursion_cut_model_reports = read_existing_json(
        args.recursion_cut_model_report or DEFAULT_RECURSION_CUT_MODEL_REPORTS
    )
    mana_base_validator_reports = read_existing_json(
        args.mana_base_validator_report or DEFAULT_MANA_BASE_VALIDATOR_REPORTS
    )
    profiled_cut_benchmark_reports = read_existing_json(
        args.profiled_cut_benchmark_report or DEFAULT_PROFILED_CUT_BENCHMARK_REPORTS
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
        recursion_cut_model_reports=recursion_cut_model_reports,
        mana_base_validator_reports=mana_base_validator_reports,
        profiled_cut_benchmark_reports=profiled_cut_benchmark_reports,
        prior_package_reports=prior_package_reports,
        strategy_audit=strategy_audit,
        hypothesis_queue=hypothesis_queue,
        trace_audit=trace_audit,
        miner_path=args.miner_report,
        manual_path=args.manual_review,
        strategy_path=args.strategy_audit,
        hypothesis_queue_path=args.hypothesis_queue,
        trace_audit_path=args.trace_audit,
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
