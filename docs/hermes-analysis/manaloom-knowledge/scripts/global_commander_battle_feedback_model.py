#!/usr/bin/env python3
"""Build reusable Commander add/cut feedback from battle probe artifacts.

This script does not run battles, mutate decks, or promote candidates. It scans
existing global Commander candidate battle probe/gate audits and consolidates
them by exact add/cut signature so a small positive probe cannot remain queued
after a larger equal gate rejects the same pair.
"""

from __future__ import annotations

import argparse
import glob
import json
from collections import Counter, defaultdict
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_PATTERNS = (
    str(REPORT_DIR / "global_commander_candidate_battle_probe_audit_*.json"),
    str(REPORT_DIR / "global_commander_candidate_battle_gate_audit_*.json"),
    str(REPORT_DIR / "global_commander_larger_battle_gate_audit_*.json"),
)

FAILED_EXERCISED = "failed_exercised_candidate_pair"
FAILED_UNEXERCISED = "failed_unexercised_candidate_pair"
FAILED_UNDERPERFORMED = "failed_underperformed_candidate_pair"
READY_LARGER_GATE = "ready_for_larger_equal_gate"
STALE_TARGET = "stale_replay_target_blocked"
REVIEW_REQUIRED = "review_required"
FAILED_PROTECTED_BASELINE_PACKAGE = "package_failed_protected_baseline_gate"
WEAK_BASE_ONLY_PACKAGE = "package_improved_weak_base_but_failed_protected_baseline"
FAILED_UNEXERCISED_PACKAGE = "package_failed_larger_gate_unexercised_added_cards"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def safe_rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def normalize_list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def resolve_report_path(path: str | Path) -> Path:
    value = Path(path)
    return value if value.is_absolute() else REPO_ROOT / value


def expand_input_paths(paths: Iterable[Path], patterns: Iterable[str]) -> list[Path]:
    found: dict[str, Path] = {}
    for path in paths:
        resolved = path if path.is_absolute() else REPO_ROOT / path
        if resolved.exists():
            found[str(resolved)] = resolved
    for pattern in patterns:
        for raw in glob.glob(str(pattern)):
            path = Path(raw)
            if path.exists():
                found[str(path)] = path
    return [found[key] for key in sorted(found)]


def sample_games(metrics: Mapping[str, Any]) -> int:
    candidate = metrics.get("candidate") or {}
    base = metrics.get("base") or {}
    return int(candidate.get("total_games") or base.get("total_games") or 0)


def classify_observation(payload: Mapping[str, Any]) -> tuple[str, str]:
    blockers = set(normalize_list(payload.get("blocker_reasons")))
    status = str(payload.get("status") or "")
    replay = payload.get("replay") or {}
    exercised = normalize_list(replay.get("added_cards_exercised_in_events"))
    unobserved = normalize_list(replay.get("added_cards_unobserved"))
    decision_only = normalize_list(replay.get("added_cards_decision_only"))
    stale_mentions = int(replay.get("stale_lorehold_mentions") or 0)

    if "replay_contains_stale_lorehold_target_mentions" in blockers or stale_mentions:
        return STALE_TARGET, "rebuild_probe_with_commander_specific_replay_target"
    if "candidate_underperformed_base_probe" in blockers and exercised:
        return FAILED_EXERCISED, "block_pair_until_new_source_lane_or_cut"
    if "added_cards_not_exercised_in_replay_events" in blockers or unobserved or decision_only:
        return FAILED_UNEXERCISED, "run_exposure_replay_or_focused_test_before_candidate_gate"
    if "candidate_underperformed_base_probe" in blockers:
        return FAILED_UNDERPERFORMED, "block_pair_until_new_source_lane_or_cut"
    if status == "battle_probe_ready_for_larger_gate" and not blockers:
        return READY_LARGER_GATE, "run_larger_equal_gate_before_any_promotion"
    return REVIEW_REQUIRED, "manual_review_required_before_requeue"


def classify_package_observation(payload: Mapping[str, Any]) -> tuple[str, str]:
    blockers = set(normalize_list(payload.get("blockers")) + normalize_list(payload.get("blocker_reasons")))
    summary = payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {}
    candidate_vs_immediate = (
        summary.get("candidate_vs_immediate_base")
        if isinstance(summary.get("candidate_vs_immediate_base"), Mapping)
        else {}
    )
    candidate_vs_protected = (
        summary.get("candidate_vs_protected")
        if isinstance(summary.get("candidate_vs_protected"), Mapping)
        else {}
    )
    unexercised = normalize_list(summary.get("larger_gate_unexercised_added_cards"))
    failed_protected = (
        "candidate_did_not_beat_protected_baseline" in blockers
        or candidate_vs_protected.get("candidate_beats_other") is False
    )
    improved_immediate = bool(candidate_vs_immediate.get("candidate_beats_other"))
    if failed_protected and improved_immediate:
        return WEAK_BASE_ONLY_PACKAGE, "block_package_until_new_source_lane_cut_or_strategy"
    if failed_protected:
        return FAILED_PROTECTED_BASELINE_PACKAGE, "block_package_until_new_source_lane_cut_or_strategy"
    if unexercised or any(str(blocker).startswith("larger_gate_unexercised_added_cards") for blocker in blockers):
        return FAILED_UNEXERCISED_PACKAGE, "rerun_package_only_after_all_added_cards_exercised_in_larger_gate"
    return REVIEW_REQUIRED, "manual_review_required_before_requeue"


def observation_from_payload(path: Path, payload: Mapping[str, Any]) -> dict[str, Any] | None:
    deck_diff = payload.get("deck_diff") or {}
    added_cards = sorted(normalize_list(deck_diff.get("added_cards")))
    cut_cards = sorted(normalize_list(deck_diff.get("cut_cards")))
    if not added_cards or not cut_cards:
        return None
    metrics = payload.get("battle_metrics") or {}
    base = metrics.get("base") or {}
    candidate = metrics.get("candidate") or {}
    replay = payload.get("replay") or {}
    classification, recommendation = classify_observation(payload)
    return {
        "artifact_path": safe_rel(path),
        "artifact_type": payload.get("artifact_type"),
        "status": payload.get("status"),
        "deck_id": str(payload.get("deck_id") or deck_diff.get("deck_id") or ""),
        "commander": payload.get("commander"),
        "added_cards": added_cards,
        "cut_cards": cut_cards,
        "base_win_rate": float(base.get("win_rate") or 0.0),
        "candidate_win_rate": float(candidate.get("win_rate") or 0.0),
        "win_rate_delta": float(metrics.get("win_rate_delta") or 0.0),
        "sample_games": sample_games(metrics),
        "same_sample_shape": bool(metrics.get("same_sample_shape")),
        "blocker_reasons": normalize_list(payload.get("blocker_reasons")),
        "added_cards_exercised_in_events": normalize_list(replay.get("added_cards_exercised_in_events")),
        "added_cards_decision_only": normalize_list(replay.get("added_cards_decision_only")),
        "added_cards_unobserved": normalize_list(replay.get("added_cards_unobserved")),
        "stale_lorehold_mentions": int(replay.get("stale_lorehold_mentions") or 0),
        "classification": classification,
        "recommendation": recommendation,
    }


def strategy_summary_from_larger_gate(payload: Mapping[str, Any]) -> dict[str, Any]:
    input_artifacts = payload.get("input_artifacts") if isinstance(payload.get("input_artifacts"), Mapping) else {}
    strategy_path = str(input_artifacts.get("strategy_report") or "")
    if not strategy_path:
        return {}
    resolved = resolve_report_path(strategy_path)
    if not resolved.exists():
        return {}
    return load_json(resolved).get("summary") or {}


def package_observation_from_larger_gate(path: Path, payload: Mapping[str, Any]) -> dict[str, Any] | None:
    summary = payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {}
    strategy_summary = strategy_summary_from_larger_gate(payload)
    added_cards = sorted(normalize_list(strategy_summary.get("package_adds")))
    cut_cards = sorted(normalize_list(strategy_summary.get("package_cuts")))
    if not added_cards or not cut_cards:
        return None
    candidate_vs_protected = (
        summary.get("candidate_vs_protected")
        if isinstance(summary.get("candidate_vs_protected"), Mapping)
        else {}
    )
    candidate_vs_immediate = (
        summary.get("candidate_vs_immediate_base")
        if isinstance(summary.get("candidate_vs_immediate_base"), Mapping)
        else {}
    )
    classification, recommendation = classify_package_observation(payload)
    return {
        "artifact_path": safe_rel(path),
        "artifact_type": payload.get("artifact_type"),
        "status": payload.get("status"),
        "deck_id": str(summary.get("deck_id") or strategy_summary.get("deck_id") or ""),
        "commander": summary.get("commander") or strategy_summary.get("commander"),
        "candidate_key": summary.get("candidate_key"),
        "protected_baseline_key": summary.get("protected_baseline_key"),
        "immediate_base_key": summary.get("immediate_base_key"),
        "added_cards": added_cards,
        "cut_cards": cut_cards,
        "sample_games": int(summary.get("games_per_opponent") or 0) * int(summary.get("opponent_count") or 0),
        "forced_access_mode": summary.get("forced_access_mode"),
        "candidate_vs_protected_win_delta": int(candidate_vs_protected.get("win_delta") or 0),
        "candidate_vs_immediate_base_win_delta": int(candidate_vs_immediate.get("win_delta") or 0),
        "candidate_vs_protected_win_rate_delta": float(candidate_vs_protected.get("win_rate_delta") or 0.0),
        "candidate_vs_immediate_base_win_rate_delta": float(candidate_vs_immediate.get("win_rate_delta") or 0.0),
        "larger_gate_exercised_added_cards": normalize_list(summary.get("larger_gate_exercised_added_cards")),
        "larger_gate_unexercised_added_cards": normalize_list(summary.get("larger_gate_unexercised_added_cards")),
        "blocker_reasons": normalize_list(payload.get("blockers")) + normalize_list(payload.get("blocker_reasons")),
        "classification": classification,
        "recommendation": recommendation,
    }


def pair_key(row: Mapping[str, Any]) -> tuple[str, str, tuple[str, ...], tuple[str, ...]]:
    return (
        str(row.get("deck_id") or ""),
        str(row.get("commander") or ""),
        tuple(row.get("added_cards") or []),
        tuple(row.get("cut_cards") or []),
    )


def package_key(row: Mapping[str, Any]) -> tuple[str, str, tuple[str, ...], tuple[str, ...]]:
    return pair_key(row)


def aggregate_status(classifications: Counter[str]) -> tuple[str, str]:
    if classifications[FAILED_EXERCISED] or classifications[FAILED_UNDERPERFORMED]:
        return "pair_blocked_by_failed_gate", "block_pair_until_new_source_lane_or_cut"
    if classifications[FAILED_UNEXERCISED]:
        return (
            "pair_needs_exposure_replay_before_gate",
            "run_exposure_replay_or_focused_test_before_candidate_gate",
        )
    if classifications[READY_LARGER_GATE]:
        return "pair_ready_for_larger_equal_gate", "run_larger_equal_gate_before_any_promotion"
    if classifications[STALE_TARGET]:
        return "pair_needs_clean_commander_target_probe", "rebuild_probe_with_commander_specific_replay_target"
    return "pair_requires_manual_review", "manual_review_required_before_requeue"


def aggregate_package_status(classifications: Counter[str]) -> tuple[str, str]:
    if classifications[WEAK_BASE_ONLY_PACKAGE] or classifications[FAILED_PROTECTED_BASELINE_PACKAGE]:
        return "package_blocked_by_protected_baseline_gate", "block_package_until_new_source_lane_cut_or_strategy"
    if classifications[FAILED_UNEXERCISED_PACKAGE]:
        return (
            "package_needs_all_added_cards_exercised_before_gate",
            "rerun_package_only_after_all_added_cards_exercised_in_larger_gate",
        )
    return "package_requires_manual_review", "manual_review_required_before_requeue"


def aggregate_pair_feedback(observations: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[tuple[str, str, tuple[str, ...], tuple[str, ...]], list[dict[str, Any]]] = defaultdict(list)
    for row in observations:
        grouped[pair_key(row)].append(row)

    pair_feedback: list[dict[str, Any]] = []
    for (deck_id, commander, added_cards, cut_cards), rows in grouped.items():
        classifications = Counter(str(row.get("classification") or "") for row in rows)
        status, recommendation = aggregate_status(classifications)
        worst_delta = min(float(row.get("win_rate_delta") or 0.0) for row in rows)
        best_delta = max(float(row.get("win_rate_delta") or 0.0) for row in rows)
        largest_sample_games = max(int(row.get("sample_games") or 0) for row in rows)
        failed_exercised_rows = [row for row in rows if row.get("classification") == FAILED_EXERCISED]
        primary_evidence = min(
            failed_exercised_rows or rows,
            key=lambda row: (float(row.get("win_rate_delta") or 0.0), -int(row.get("sample_games") or 0)),
        )
        pair_feedback.append(
            {
                "deck_id": deck_id,
                "commander": commander,
                "added_cards": list(added_cards),
                "cut_cards": list(cut_cards),
                "pair_status": status,
                "recommendation": recommendation,
                "observation_count": len(rows),
                "classification_counts": dict(sorted(classifications.items())),
                "largest_sample_games": largest_sample_games,
                "worst_win_rate_delta": worst_delta,
                "best_win_rate_delta": best_delta,
                "superseded_ready_probe_count": (
                    classifications[READY_LARGER_GATE]
                    if status == "pair_blocked_by_failed_gate"
                    else 0
                ),
                "primary_evidence": primary_evidence,
                "observations": sorted(
                    rows,
                    key=lambda row: (
                        -int(row.get("sample_games") or 0),
                        float(row.get("win_rate_delta") or 0.0),
                        str(row.get("artifact_path") or ""),
                    ),
                ),
            }
        )

    status_rank = {
        "pair_blocked_by_failed_gate": 0,
        "pair_needs_exposure_replay_before_gate": 1,
        "pair_needs_clean_commander_target_probe": 2,
        "pair_ready_for_larger_equal_gate": 3,
        "pair_requires_manual_review": 4,
    }
    pair_feedback.sort(
        key=lambda row: (
            status_rank.get(str(row["pair_status"]), 99),
            row["commander"],
            row["deck_id"],
            row["added_cards"],
            row["cut_cards"],
        )
    )
    return pair_feedback


def aggregate_package_feedback(observations: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[tuple[str, str, tuple[str, ...], tuple[str, ...]], list[dict[str, Any]]] = defaultdict(list)
    for row in observations:
        grouped[package_key(row)].append(row)

    package_feedback: list[dict[str, Any]] = []
    for (deck_id, commander, added_cards, cut_cards), rows in grouped.items():
        classifications = Counter(str(row.get("classification") or "") for row in rows)
        status, recommendation = aggregate_package_status(classifications)
        protected_deltas = [int(row.get("candidate_vs_protected_win_delta") or 0) for row in rows]
        immediate_deltas = [int(row.get("candidate_vs_immediate_base_win_delta") or 0) for row in rows]
        largest_sample_games = max(int(row.get("sample_games") or 0) for row in rows)
        primary_evidence = min(
            rows,
            key=lambda row: (
                int(row.get("candidate_vs_protected_win_delta") or 0),
                -int(row.get("sample_games") or 0),
                str(row.get("artifact_path") or ""),
            ),
        )
        package_feedback.append(
            {
                "deck_id": deck_id,
                "commander": commander,
                "added_cards": list(added_cards),
                "cut_cards": list(cut_cards),
                "package_status": status,
                "recommendation": recommendation,
                "observation_count": len(rows),
                "classification_counts": dict(sorted(classifications.items())),
                "largest_sample_games": largest_sample_games,
                "worst_candidate_vs_protected_win_delta": min(protected_deltas or [0]),
                "best_candidate_vs_protected_win_delta": max(protected_deltas or [0]),
                "best_candidate_vs_immediate_base_win_delta": max(immediate_deltas or [0]),
                "unexercised_added_cards": sorted(
                    {
                        card
                        for row in rows
                        for card in normalize_list(row.get("larger_gate_unexercised_added_cards"))
                    }
                ),
                "primary_evidence": primary_evidence,
                "observations": sorted(
                    rows,
                    key=lambda row: (
                        -int(row.get("sample_games") or 0),
                        int(row.get("candidate_vs_protected_win_delta") or 0),
                        str(row.get("artifact_path") or ""),
                    ),
                ),
            }
        )

    status_rank = {
        "package_blocked_by_protected_baseline_gate": 0,
        "package_needs_all_added_cards_exercised_before_gate": 1,
        "package_requires_manual_review": 2,
    }
    package_feedback.sort(
        key=lambda row: (
            status_rank.get(str(row["package_status"]), 99),
            row["commander"],
            row["deck_id"],
            row["added_cards"],
            row["cut_cards"],
        )
    )
    return package_feedback


def build_report(paths: list[Path]) -> dict[str, Any]:
    observations: list[dict[str, Any]] = []
    package_observations: list[dict[str, Any]] = []
    ignored_artifacts: list[dict[str, Any]] = []
    for path in paths:
        payload = load_json(path)
        if payload.get("artifact_type") == "global_commander_larger_battle_gate_audit":
            package_observation = package_observation_from_larger_gate(path, payload)
            if package_observation is None:
                ignored_artifacts.append({"path": safe_rel(path), "reason": "missing_package_add_or_cut_diff"})
                continue
            package_observations.append(package_observation)
            continue
        observation = observation_from_payload(path, payload)
        if observation is None:
            ignored_artifacts.append({"path": safe_rel(path), "reason": "missing_add_or_cut_diff"})
            continue
        observations.append(observation)

    pair_feedback = aggregate_pair_feedback(observations)
    package_feedback = aggregate_package_feedback(package_observations)
    pair_status_counts = Counter(row["pair_status"] for row in pair_feedback)
    package_status_counts = Counter(row["package_status"] for row in package_feedback)
    observation_classification_counts = Counter(row["classification"] for row in observations)
    package_classification_counts = Counter(row["classification"] for row in package_observations)
    return {
        "generated_at": utc_now(),
        "status": "pass",
        "artifact_type": "global_commander_battle_feedback_model",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "input_artifacts": [safe_rel(path) for path in paths],
        "ignored_artifacts": ignored_artifacts,
        "summary": {
            "audit_artifact_count": len(paths),
            "observation_count": len(observations),
            "package_observation_count": len(package_observations),
            "ignored_artifact_count": len(ignored_artifacts),
            "pair_count": len(pair_feedback),
            "package_count": len(package_feedback),
            "pair_status_counts": dict(sorted(pair_status_counts.items())),
            "package_status_counts": dict(sorted(package_status_counts.items())),
            "observation_classification_counts": dict(sorted(observation_classification_counts.items())),
            "package_classification_counts": dict(sorted(package_classification_counts.items())),
            "blocked_pair_count": pair_status_counts["pair_blocked_by_failed_gate"],
            "ready_pair_count": pair_status_counts["pair_ready_for_larger_equal_gate"],
            "needs_exposure_pair_count": pair_status_counts["pair_needs_exposure_replay_before_gate"],
            "blocked_package_count": package_status_counts["package_blocked_by_protected_baseline_gate"],
            "needs_exercise_package_count": package_status_counts["package_needs_all_added_cards_exercised_before_gate"],
        },
        "policy": {
            "exact_pair_memory": "An exact add/cut pair rejected by equal battle evidence is blocked until a new source lane, cut, or package hypothesis changes the pair.",
            "exact_package_memory": "An exact package rejected by a protected-baseline larger gate is blocked until a new source lane, cut set, or strategy hypothesis changes the package.",
            "protected_baseline_supersession": "A candidate package that improves a weak immediate shell but loses to a protected benchmark is negative global learning, not promotion evidence.",
            "small_probe_supersession": "A small positive probe is superseded when a larger equal gate for the same add/cut pair underperforms.",
            "card_exposure": "Added cards must be exercised in replay events before the result can teach card-level value.",
            "review_only": "This model is a learning feedback layer and cannot materialize, battle, mutate, or promote a deck.",
        },
        "pair_feedback": pair_feedback,
        "package_feedback": package_feedback,
    }


def cell(value: Any) -> str:
    return str(value).replace("|", "/")


def render_markdown(payload: Mapping[str, Any]) -> str:
    lines = [
        "# Global Commander Battle Feedback Model",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- battle_or_optimization_performed: `{payload['battle_or_optimization_performed']}`",
        f"- mutation_allowed: `{payload['mutation_allowed']}`",
        f"- promotion_allowed: `{payload['promotion_allowed']}`",
        f"- pair_count: `{payload['summary']['pair_count']}`",
        f"- package_count: `{payload['summary']['package_count']}`",
        f"- blocked_pair_count: `{payload['summary']['blocked_pair_count']}`",
        f"- blocked_package_count: `{payload['summary']['blocked_package_count']}`",
        f"- needs_exposure_pair_count: `{payload['summary']['needs_exposure_pair_count']}`",
        f"- needs_exercise_package_count: `{payload['summary']['needs_exercise_package_count']}`",
        f"- ready_pair_count: `{payload['summary']['ready_pair_count']}`",
        "",
        "## Pair Feedback",
        "",
        "| Status | Commander | Deck | Add | Cut | Worst Delta | Best Delta | Observations | Recommendation |",
        "| --- | --- | --- | --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in payload["pair_feedback"]:
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{cell(row['pair_status'])}`",
                    f"`{cell(row['commander'])}`",
                    f"`{cell(row['deck_id'])}`",
                    f"`{cell(', '.join(row['added_cards']))}`",
                    f"`{cell(', '.join(row['cut_cards']))}`",
                    f"{row['worst_win_rate_delta']:.1f}",
                    f"{row['best_win_rate_delta']:.1f}",
                    str(row["observation_count"]),
                    f"`{cell(row['recommendation'])}`",
                ]
            )
            + " |"
        )

    lines.extend(
        [
            "",
            "## Package Feedback",
            "",
            "| Status | Classification | Commander | Deck | Adds | Cuts | Protected Delta | Immediate Delta | Unexercised Adds | Recommendation |",
            "| --- | --- | --- | --- | --- | --- | ---: | ---: | --- | --- |",
        ]
    )
    for row in payload["package_feedback"]:
        classifications = ", ".join(sorted(row.get("classification_counts") or {}))
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{cell(row['package_status'])}`",
                    f"`{cell(classifications)}`",
                    f"`{cell(row['commander'])}`",
                    f"`{cell(row['deck_id'])}`",
                    f"`{cell(', '.join(row['added_cards']))}`",
                    f"`{cell(', '.join(row['cut_cards']))}`",
                    str(row["worst_candidate_vs_protected_win_delta"]),
                    str(row["best_candidate_vs_immediate_base_win_delta"]),
                    f"`{cell(', '.join(row['unexercised_added_cards']) or '-')}`",
                    f"`{cell(row['recommendation'])}`",
                ]
            )
            + " |"
        )

    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True, ensure_ascii=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit-json", type=Path, action="append", default=[])
    parser.add_argument("--glob", dest="patterns", action="append", default=[])
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "global_commander_battle_feedback_model_20260705_current",
    )
    args = parser.parse_args()
    patterns = args.patterns or list(DEFAULT_PATTERNS)
    paths = expand_input_paths(args.audit_json, patterns)
    payload = build_report(paths)
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
