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
)

FAILED_EXERCISED = "failed_exercised_candidate_pair"
FAILED_UNEXERCISED = "failed_unexercised_candidate_pair"
FAILED_UNDERPERFORMED = "failed_underperformed_candidate_pair"
READY_LARGER_GATE = "ready_for_larger_equal_gate"
STALE_TARGET = "stale_replay_target_blocked"
REVIEW_REQUIRED = "review_required"


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


def pair_key(row: Mapping[str, Any]) -> tuple[str, str, tuple[str, ...], tuple[str, ...]]:
    return (
        str(row.get("deck_id") or ""),
        str(row.get("commander") or ""),
        tuple(row.get("added_cards") or []),
        tuple(row.get("cut_cards") or []),
    )


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


def build_report(paths: list[Path]) -> dict[str, Any]:
    observations: list[dict[str, Any]] = []
    ignored_artifacts: list[dict[str, Any]] = []
    for path in paths:
        payload = load_json(path)
        observation = observation_from_payload(path, payload)
        if observation is None:
            ignored_artifacts.append({"path": safe_rel(path), "reason": "missing_add_or_cut_diff"})
            continue
        observations.append(observation)

    pair_feedback = aggregate_pair_feedback(observations)
    pair_status_counts = Counter(row["pair_status"] for row in pair_feedback)
    observation_classification_counts = Counter(row["classification"] for row in observations)
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
            "ignored_artifact_count": len(ignored_artifacts),
            "pair_count": len(pair_feedback),
            "pair_status_counts": dict(sorted(pair_status_counts.items())),
            "observation_classification_counts": dict(sorted(observation_classification_counts.items())),
            "blocked_pair_count": pair_status_counts["pair_blocked_by_failed_gate"],
            "ready_pair_count": pair_status_counts["pair_ready_for_larger_equal_gate"],
            "needs_exposure_pair_count": pair_status_counts["pair_needs_exposure_replay_before_gate"],
        },
        "policy": {
            "exact_pair_memory": "An exact add/cut pair rejected by equal battle evidence is blocked until a new source lane, cut, or package hypothesis changes the pair.",
            "small_probe_supersession": "A small positive probe is superseded when a larger equal gate for the same add/cut pair underperforms.",
            "card_exposure": "Added cards must be exercised in replay events before the result can teach card-level value.",
            "review_only": "This model is a learning feedback layer and cannot materialize, battle, mutate, or promote a deck.",
        },
        "pair_feedback": pair_feedback,
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
        f"- blocked_pair_count: `{payload['summary']['blocked_pair_count']}`",
        f"- needs_exposure_pair_count: `{payload['summary']['needs_exposure_pair_count']}`",
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
