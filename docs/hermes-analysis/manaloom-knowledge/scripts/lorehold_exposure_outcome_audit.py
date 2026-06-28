#!/usr/bin/env python3
"""Audit Lorehold package gates by per-card exposure outcome.

This read-only report turns the package gate's ``outcome_summary`` into an
operational signal: the aggregate deck record is still shown, but the decision
focuses on the games where the added card was actually used.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

import lorehold_synergy_package_gate as package_gate


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_EXTRA_REPORTS = [
    REPORT_DIR / "lorehold_exposure_by_game_gate_20260628_v1_20260628_101737.json",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def numeric(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except Exception:
        return default


def integer(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def unique_paths(paths: Iterable[Path]) -> list[Path]:
    seen: set[str] = set()
    ordered: list[Path] = []
    for path in paths:
        key = str(path)
        if key in seen:
            continue
        seen.add(key)
        ordered.append(path)
    return ordered


def default_source_reports() -> list[Path]:
    return unique_paths([*package_gate.DEFAULT_PRIOR_PACKAGE_REPORTS, *DEFAULT_EXTRA_REPORTS])


def package_rows_from_variant_gate_results(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    results = payload.get("results") or []
    if not isinstance(results, list):
        return []
    rows: list[dict[str, Any]] = []
    definitions = package_gate.PACKAGE_DEFINITIONS
    for result in results:
        if not isinstance(result, Mapping):
            continue
        deck_key = str(result.get("deck_key") or "")
        if not deck_key.startswith("synergy_"):
            continue
        package_key = deck_key.removeprefix("synergy_")
        definition = definitions.get(package_key) or {}
        adds = list(definition.get("adds") or [])
        cuts = list(definition.get("cuts") or [])
        gate = package_gate.summarize_gate(dict(payload), deck_key)
        if not (gate.get("baseline") and gate.get("candidate")):
            continue
        exposure = (
            package_gate.package_exposure_summary(gate, adds=adds, cuts=cuts)
            if adds
            else {}
        )
        forced_access_mode = (
            result.get("forced_access_mode")
            or payload.get("forced_access_mode")
            or "none"
        )
        decision = (
            package_gate.gate_decision(
                gate,
                exposure,
                forced_access_mode=str(forced_access_mode),
            )
            if exposure
            else "missing_package_definition_for_variant_gate"
        )
        rows.append(
            {
                "package_key": package_key,
                "source_section": "variant_gate_results",
                "family": definition.get("family") or "misc",
                "adds": adds,
                "cuts": cuts,
                "forced_access_mode": forced_access_mode,
                "decision": decision,
                "gate_summary": gate,
                "exposure_summary": exposure,
            }
        )
    return rows


def package_rows_from_payload(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = payload.get("packages") or []
    package_rows = [row for row in rows if isinstance(row, dict) and row.get("package_key")]
    if package_rows:
        return package_rows
    return package_rows_from_variant_gate_results(payload)



def load_detailed_gate(result: Mapping[str, Any]) -> dict[str, Any]:
    gate_json = result.get("gate_json")
    if not gate_json:
        return {}
    path = Path(str(gate_json))
    if not path.exists():
        return {}
    try:
        return package_gate.summarize_gate(
            package_gate.load_gate_result(path),
            f"synergy_{result.get('package_key')}",
        )
    except Exception:
        return {}


def best_gate_summary(result: Mapping[str, Any]) -> dict[str, Any]:
    detailed = load_detailed_gate(result)
    if detailed:
        return detailed
    gate = result.get("gate_summary") or {}
    return dict(gate) if isinstance(gate, Mapping) else {}


def best_exposure_summary(result: Mapping[str, Any], gate: Mapping[str, Any]) -> dict[str, Any]:
    adds = list(result.get("adds") or [])
    cuts = list(result.get("cuts") or [])
    baseline = gate.get("baseline") or {}
    candidate = gate.get("candidate") or {}
    has_game_grain = bool(
        (isinstance(baseline, Mapping) and baseline.get("game_results"))
        or (isinstance(candidate, Mapping) and candidate.get("game_results"))
        or (
            isinstance(candidate, Mapping)
            and isinstance(candidate.get("telemetry"), Mapping)
            and (candidate.get("telemetry") or {}).get("card_event_counts_by_game")
        )
    )
    if gate and adds and has_game_grain:
        exposure = package_gate.package_exposure_summary(dict(gate), adds=adds, cuts=cuts)
        if any(
            (card.get("outcome_summary") or {}).get("all_games")
            for card in (exposure.get("candidate_added_cards") or {}).get("cards") or []
            if isinstance(card, Mapping)
        ):
            return exposure
    exposure = result.get("exposure_summary") or {}
    return dict(exposure) if isinstance(exposure, Mapping) else {}


def side_record(side: Mapping[str, Any]) -> dict[str, Any]:
    wins = integer(side.get("wins"))
    losses = integer(side.get("losses"))
    stalls = integer(side.get("stalls"))
    games = wins + losses + stalls
    win_rate = side.get("win_rate")
    if win_rate is None:
        win_rate = round(wins / max(1, games) * 100, 2) if games else 0.0
    return {
        "games": games,
        "wins": wins,
        "losses": losses,
        "stalls": stalls,
        "win_rate": numeric(win_rate),
    }


def card_outcome_rows(group: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for card in group.get("cards") or []:
        if not isinstance(card, Mapping):
            continue
        outcome = card.get("outcome_summary") or {}
        used = outcome.get("used_games") or {}
        accessed = outcome.get("accessed_or_used_games") or {}
        rows.append(
            {
                "card_name": card.get("card_name"),
                "status": card.get("status"),
                "recorded_use_count": integer(card.get("recorded_use_count")),
                "used_games": side_record(used),
                "accessed_or_used_games": side_record(accessed),
                "sample_quality": outcome.get("sample_quality") or "missing_outcome",
                "status_counts": outcome.get("status_counts") or {},
            }
        )
    return rows


def primary_card_outcome(rows: list[dict[str, Any]]) -> dict[str, Any]:
    if not rows:
        return {
            "card_name": None,
            "used_games": side_record({}),
            "accessed_or_used_games": side_record({}),
            "sample_quality": "missing_card",
        }
    return rows[0]


def classify_outcome(
    *,
    aggregate_delta_pp: float | None,
    added_card: Mapping[str, Any],
    cut_card: Mapping[str, Any],
    exposure: Mapping[str, Any],
    multi_card_package: bool,
    forced_access_mode: str = "none",
) -> dict[str, Any]:
    if not added_card.get("card_name") or not cut_card.get("card_name"):
        return {
            "decision": "missing_per_card_outcome_data",
            "promotion_allowed": False,
            "next_action": "rerun_with_current_exposure_outcome_gate_or_recover_detailed_gate_json",
            "used_delta_pp": None,
            "reason": "source report does not expose candidate and cut card outcome rows",
        }
    if multi_card_package:
        return {
            "decision": "multi_card_outcome_review_required",
            "promotion_allowed": False,
            "next_action": "split_or_review_multi_card_package_before_card_outcome_decision",
            "used_delta_pp": None,
            "reason": "per-card outcome cannot safely collapse multiple added or cut cards",
        }

    added_used = added_card.get("used_games") or {}
    cut_used = cut_card.get("used_games") or {}
    added_used_games = integer(added_used.get("games"))
    cut_used_games = integer(cut_used.get("games"))
    if bool(exposure.get("low_candidate_added_card_use")) or added_used_games == 0:
        return {
            "decision": "inconclusive_no_candidate_used_sample",
            "promotion_allowed": False,
            "next_action": "rerun_larger_or_forced_access_then_natural_confirmation",
            "used_delta_pp": None,
            "reason": "candidate card did not produce a used-game sample",
        }
    if cut_used_games == 0:
        return {
            "decision": "candidate_used_without_cut_comparator",
            "promotion_allowed": False,
            "next_action": "rerun_or_compare_against_a_cut_with_observed_use",
            "used_delta_pp": None,
            "reason": "baseline cut card did not produce a used-game comparator",
        }

    used_delta = round(numeric(added_used.get("win_rate")) - numeric(cut_used.get("win_rate")), 2)
    aggregate_delta = numeric(aggregate_delta_pp) if aggregate_delta_pp is not None else 0.0
    if forced_access_mode and forced_access_mode != "none":
        if aggregate_delta > 0 and used_delta > 0:
            return {
                "decision": "forced_access_card_outcome_signal_requires_natural_confirmation",
                "promotion_allowed": False,
                "next_action": "run_natural_gate_without_forced_access_before_promoting",
                "used_delta_pp": used_delta,
                "reason": "forced-access probes can diagnose potential but cannot promote a deck swap",
            }
        return {
            "decision": "forced_access_card_outcome_no_lift_reject_or_rework",
            "promotion_allowed": False,
            "next_action": "do_not_promote_from_forced_access_probe",
            "used_delta_pp": used_delta,
            "reason": "forced-access probe did not produce a positive card-outcome signal",
        }

    if aggregate_delta > 0 and used_delta > 0:
        decision = "card_outcome_supports_deeper_gate"
        next_action = "confirm_with_larger_natural_gate_and_critical_matchups"
        promotion_allowed = True
    elif aggregate_delta < 0 and used_delta <= 0:
        decision = "card_outcome_rejects_current_pair"
        next_action = "do_not_repeat_exact_pair_without_new_failure_target_or_cut"
        promotion_allowed = False
    elif aggregate_delta > 0 and used_delta <= 0:
        decision = "aggregate_positive_but_card_outcome_not_supportive"
        next_action = "inspect_non_card_driver_before_promoting"
        promotion_allowed = False
    elif aggregate_delta < 0 and used_delta > 0:
        decision = "card_used_positive_but_deck_regressed"
        next_action = "inspect_cut_or_shell_regression_before_retesting"
        promotion_allowed = False
    elif used_delta == 0:
        decision = "card_outcome_tie_needs_larger_sample"
        next_action = "increase_natural_sample_only_if_strategy_lane_still_needed"
        promotion_allowed = False
    else:
        decision = "card_outcome_mixed_rework"
        next_action = "rework_package_before_more_gate_time"
        promotion_allowed = False

    return {
        "decision": decision,
        "promotion_allowed": promotion_allowed,
        "next_action": next_action,
        "used_delta_pp": used_delta,
        "reason": "compared candidate used-game record against baseline cut used-game record",
    }


def audit_package(path: Path, payload: Mapping[str, Any], result: Mapping[str, Any]) -> dict[str, Any]:
    gate = best_gate_summary(result)
    exposure = best_exposure_summary(result, gate)
    baseline = side_record((gate.get("baseline") or {}) if isinstance(gate, Mapping) else {})
    candidate = side_record((gate.get("candidate") or {}) if isinstance(gate, Mapping) else {})
    aggregate_delta = None
    if baseline["games"] or candidate["games"] or gate.get("delta_pp") is not None:
        aggregate_delta = round(
            numeric(gate.get("delta_pp"), candidate["win_rate"] - baseline["win_rate"]),
            2,
        )
    added_cards = card_outcome_rows(exposure.get("candidate_added_cards") or {})
    cut_cards = card_outcome_rows(exposure.get("baseline_cut_cards") or {})
    added_primary = primary_card_outcome(added_cards)
    cut_primary = primary_card_outcome(cut_cards)
    outcome_decision = classify_outcome(
        aggregate_delta_pp=aggregate_delta,
        added_card=added_primary,
        cut_card=cut_primary,
        exposure=exposure,
        multi_card_package=len(added_cards) != 1 or len(cut_cards) != 1,
        forced_access_mode=str(result.get("forced_access_mode") or "none"),
    )
    return {
        "source_report": str(path),
        "source_file": path.name,
        "package_key": result.get("package_key"),
        "family": result.get("family") or "misc",
        "adds": list(result.get("adds") or []),
        "cuts": list(result.get("cuts") or []),
        "forced_access_mode": result.get("forced_access_mode") or "none",
        "raw_decision": result.get("decision"),
        "aggregate": {
            "baseline": baseline,
            "candidate": candidate,
            "delta_pp": aggregate_delta,
        },
        "exposure_status": exposure.get("status"),
        "candidate_added_cards": added_cards,
        "baseline_cut_cards": cut_cards,
        "outcome_decision": outcome_decision,
    }


def collect_audits(paths: Iterable[Path]) -> tuple[list[dict[str, Any]], list[str]]:
    rows: list[dict[str, Any]] = []
    missing: list[str] = []
    for path in paths:
        if not path.exists():
            missing.append(str(path))
            continue
        payload = read_json(path)
        for result in package_rows_from_payload(payload):
            rows.append(audit_package(path, payload, result))
    rows.sort(
        key=lambda row: (
            str(row.get("package_key") or ""),
            str(row.get("source_file") or ""),
        )
    )
    return rows, missing


def build_report(paths: Iterable[Path]) -> dict[str, Any]:
    source_paths = list(paths)
    packages, missing = collect_audits(source_paths)
    decision_counts = Counter(
        str((row.get("outcome_decision") or {}).get("decision") or "unknown")
        for row in packages
    )
    promoted = [
        row
        for row in packages
        if (row.get("outcome_decision") or {}).get("decision") == "card_outcome_supports_deeper_gate"
    ]
    rejected = [
        row
        for row in packages
        if (row.get("outcome_decision") or {}).get("decision") == "card_outcome_rejects_current_pair"
    ]
    inconclusive = [
        row
        for row in packages
        if str((row.get("outcome_decision") or {}).get("decision") or "").startswith("inconclusive")
    ]
    forced_signals = [
        row
        for row in packages
        if (row.get("outcome_decision") or {}).get("decision")
        == "forced_access_card_outcome_signal_requires_natural_confirmation"
    ]
    return {
        "generated_at": utc_now(),
        "postgres_writes": False,
        "source_db_mutated": False,
        "source_reports": [str(path) for path in source_paths],
        "missing_reports": missing,
        "summary": {
            "source_report_count": len(source_paths),
            "loaded_package_observation_count": len(packages),
            "missing_report_count": len(missing),
            "decision_counts": dict(sorted(decision_counts.items())),
            "deeper_gate_candidate_count": len(promoted),
            "forced_access_signal_count": len(forced_signals),
            "rejected_current_pair_count": len(rejected),
            "inconclusive_no_used_sample_count": len(inconclusive),
            "recommended_next_action": (
                "run_best_card_outcome_supported_deeper_gate"
                if promoted
                else "run_natural_confirmation_for_forced_access_signal"
                if forced_signals and not rejected
                else "avoid_repeating_rejected_pairs_and_generate_new_trace_targeted_package"
                if rejected
                else "increase_exposure_before_more_card_swap_decisions"
            ),
        },
        "decision_rules": [
            "aggregate deck record is not card-level proof by itself",
            "candidate card must have a used-game sample before a package can be promoted",
            "used-game comparison is candidate-added card record versus baseline-cut card record",
            "forced-access probes can diagnose access but require natural confirmation before promotion",
            "multi-card packages require split or manual review before per-card outcome promotion",
            "Hermes gate evidence is lab evidence; PostgreSQL state is not mutated by this report",
        ],
        "packages": packages,
    }


def record_text(record: Mapping[str, Any]) -> str:
    return "{wins}-{losses}-{stalls} ({wr:.2f}%)".format(
        wins=integer(record.get("wins")),
        losses=integer(record.get("losses")),
        stalls=integer(record.get("stalls")),
        wr=numeric(record.get("win_rate")),
    )


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload.get("summary") or {}
    lines = [
        "# Lorehold Exposure Outcome Audit - 2026-06-28",
        "",
        f"- generated_at: `{payload.get('generated_at')}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        f"- loaded_package_observation_count: `{summary.get('loaded_package_observation_count')}`",
        f"- missing_report_count: `{summary.get('missing_report_count')}`",
        f"- decision_counts: `{json.dumps(summary.get('decision_counts') or {}, sort_keys=True)}`",
        f"- recommended_next_action: `{summary.get('recommended_next_action')}`",
        "",
        "## Decision Rules",
        "",
    ]
    lines.extend(f"- {rule}" for rule in payload.get("decision_rules") or [])
    lines.extend(
        [
            "",
            "## Package Outcomes",
            "",
            "| Package | Source | Adds | Cuts | Aggregate | Added Used | Cut Used | Used Delta | Decision | Next Action |",
            "| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |",
        ]
    )
    for row in payload.get("packages") or []:
        aggregate = row.get("aggregate") or {}
        added = (row.get("candidate_added_cards") or [{}])[0] if row.get("candidate_added_cards") else {}
        cut = (row.get("baseline_cut_cards") or [{}])[0] if row.get("baseline_cut_cards") else {}
        decision = row.get("outcome_decision") or {}
        aggregate_text = "-"
        if aggregate.get("delta_pp") is not None:
            aggregate_text = "{base} -> {cand} ({delta:+.2f})".format(
                base=record_text((aggregate.get("baseline") or {})),
                cand=record_text((aggregate.get("candidate") or {})),
                delta=numeric(aggregate.get("delta_pp")),
            )
        used_delta = decision.get("used_delta_pp")
        used_delta_text = f"{numeric(used_delta):+.2f}" if used_delta is not None else "-"
        lines.append(
            "| `{package}` | `{source}` | {adds} | {cuts} | {aggregate} | {added} | {cut} | {used_delta} | `{decision}` | `{next_action}` |".format(
                package=row.get("package_key"),
                source=row.get("source_file"),
                adds=", ".join(f"`{card}`" for card in row.get("adds") or []),
                cuts=", ".join(f"`{card}`" for card in row.get("cuts") or []),
                aggregate=aggregate_text,
                added=record_text((added.get("used_games") or {})) if added else "-",
                cut=record_text((cut.get("used_games") or {})) if cut else "-",
                used_delta=used_delta_text,
                decision=decision.get("decision"),
                next_action=decision.get("next_action"),
            )
        )
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], stem: str) -> tuple[Path, Path]:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{stem}.json"
    md_path = REPORT_DIR / f"{stem}.md"
    json_path.write_text(json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-report", type=Path, action="append", default=[])
    parser.add_argument("--stem", default="lorehold_exposure_outcome_audit_20260628_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = [path.resolve() for path in args.source_report] or default_source_reports()
    payload = build_report(paths)
    json_path, md_path = write_outputs(payload, args.stem)
    print(
        json.dumps(
            {
                "status": "ready",
                "json": str(json_path),
                "markdown": str(md_path),
                "recommended_next_action": payload["summary"]["recommended_next_action"],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
