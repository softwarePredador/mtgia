#!/usr/bin/env python3
"""Build a conservative Lorehold learning ledger from registry and gate evidence."""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_REGISTRY = REPORT_DIR / "lorehold_candidate_hypothesis_registry_20260626.json"
CRITICAL_MATCHUP_TERMS = ("Winota", "Vivi", "Sisay")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path) -> dict[str, Any] | None:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None
    return payload if isinstance(payload, dict) else None


def corrected_invalid_package_keys(report_path: Path, payload: Mapping[str, Any]) -> dict[str, str]:
    """Return package keys invalidated by corrected package manifests.

    Some historical gate reports were generated from a manifest that was later
    corrected in place. If the corrected manifest has a correction note and no
    longer contains a package that still appears in the old gate output, the
    old package must not remain in the confirmation queue.
    """

    report_keys = {
        str(package.get("package_key") or "")
        for package in payload.get("packages") or []
        if isinstance(package, Mapping) and package.get("package_key")
    }
    if not report_keys:
        return {}

    invalid: dict[str, str] = {}
    for raw_path in payload.get("package_definition_files") or []:
        manifest_path = Path(str(raw_path))
        if not manifest_path.is_absolute():
            manifest_path = report_path.parent / manifest_path
        manifest = load_json(manifest_path)
        if not manifest:
            continue
        correction_note = str(manifest.get("correction_note") or "")
        if not correction_note:
            continue
        lowered_note = correction_note.lower()
        if "removed" not in lowered_note and "invalid" not in lowered_note:
            continue
        valid_keys = {
            str(package.get("package_key") or "")
            for package in manifest.get("packages") or []
            if isinstance(package, Mapping) and package.get("package_key")
        }
        for package_key in sorted(report_keys - valid_keys):
            invalid[package_key] = correction_note
    return invalid


def numeric(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except Exception:
        return default


def has_numeric(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def integer(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def gate_decision(delta_pp: float, baseline: Mapping[str, Any], candidate: Mapping[str, Any]) -> str:
    baseline_wins = integer(baseline.get("wins"))
    candidate_wins = integer(candidate.get("wins"))
    baseline_losses = integer(baseline.get("losses"))
    candidate_losses = integer(candidate.get("losses"))
    if delta_pp > 0:
        return "positive_needs_scope_check"
    if delta_pp == 0 and candidate_wins == baseline_wins and candidate_losses <= baseline_losses:
        return "tie_watch_strategy"
    return "reject_or_rework"


def observation_from_package_report(path: Path, payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    observations: list[dict[str, Any]] = []
    invalid_packages = corrected_invalid_package_keys(path, payload)
    for package in payload.get("packages") or []:
        if not isinstance(package, dict):
            continue
        package_key = str(package.get("package_key") or "")
        invalid_reason = invalid_packages.get(package_key)
        gate = package.get("gate_summary") or {}
        baseline = gate.get("baseline") or {}
        candidate = gate.get("candidate") or {}
        if not baseline or not candidate:
            package_status = str(package.get("status") or "")
            if package_status not in {
                "skipped_cut_safety",
                "skipped_prior_evidence",
                "skipped_candidate_apply_error",
                "preflight_ready",
                "apply_ready",
            }:
                continue
            observations.append(
                {
                    "source_path": str(path),
                    "source_file": path.name,
                    "source_mtime": path.stat().st_mtime,
                    "generated_at": payload.get("generated_at"),
                    "source_kind": "package_preflight",
                    "package_key": package_key,
                    "family": package.get("family"),
                    "adds": list(package.get("adds") or []),
                    "cuts": list(package.get("cuts") or []),
                    "status": package.get("status"),
                    "cut_safety": package.get("cut_safety") or {},
                    "prior_evidence": package.get("prior_evidence") or {},
                    "baseline": {},
                    "candidate": {},
                    "delta_pp": None,
                    "decision": "invalid_corrected_package_definition"
                    if invalid_reason
                    else preflight_decision(package),
                    "invalid_reason": invalid_reason,
                    "games_per_opponent": payload.get("games_per_opponent"),
                    "opponent_limit": payload.get("opponent_limit"),
                    "opponent_seed": payload.get("opponent_seed"),
                    "simulation_seed": payload.get("simulation_seed"),
                    "source_db": payload.get("source_db"),
                    "runtime_package_proposal_reports": payload.get("runtime_package_proposal_reports") or [],
                }
            )
            continue
        delta_pp = numeric(gate.get("delta_pp"), numeric(candidate.get("win_rate")) - numeric(baseline.get("win_rate")))
        observations.append(
                {
                    "source_path": str(path),
                    "source_file": path.name,
                    "source_mtime": path.stat().st_mtime,
                    "generated_at": payload.get("generated_at"),
                    "source_kind": "package_gate",
                    "package_key": package_key,
                    "family": package.get("family"),
                    "adds": list(package.get("adds") or []),
                    "cuts": list(package.get("cuts") or []),
                    "status": package.get("status"),
                    "baseline": compact_result(baseline),
                    "candidate": compact_result(candidate),
                    "delta_pp": round(delta_pp, 2),
                    "decision": "invalid_corrected_package_definition"
                    if invalid_reason
                    else gate_decision(delta_pp, baseline, candidate),
                    "invalid_reason": invalid_reason,
                    "games_per_opponent": payload.get("games_per_opponent"),
                    "opponent_limit": payload.get("opponent_limit"),
                    "opponent_seed": payload.get("opponent_seed"),
                    "simulation_seed": payload.get("simulation_seed"),
                "source_db": payload.get("source_db"),
                "runtime_package_proposal_reports": payload.get("runtime_package_proposal_reports") or [],
            }
        )
    return observations


def preflight_decision(package: Mapping[str, Any]) -> str:
    status = str(package.get("status") or "")
    cut_status = str((package.get("cut_safety") or {}).get("status") or "")
    prior_status = str((package.get("prior_evidence") or {}).get("status") or "")
    if status == "skipped_cut_safety" or cut_status == "blocked_cut_safety":
        return "preflight_blocked_protected_cut"
    if status == "skipped_prior_evidence" or prior_status == "blocked_prior_reject":
        return "blocked_prior_evidence"
    if status == "skipped_candidate_apply_error":
        return "candidate_apply_error"
    if status in {"preflight_ready", "apply_ready"}:
        return status
    return status or "preflight_observed"


def compact_result(row: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "status": row.get("status"),
        "games": integer(row.get("games")),
        "wins": integer(row.get("wins")),
        "losses": integer(row.get("losses")),
        "stalls": integer(row.get("stalls")),
        "win_rate": numeric(row.get("win_rate")),
        "miracle_cast": strategic_metric(row, "miracle_cast"),
        "topdeck_manipulation_activated": strategic_metric(row, "topdeck_manipulation_activated"),
        "hand_to_topdeck_activation": strategic_metric(row, "hand_to_topdeck_activation"),
        "damage_prevention_shield_created": strategic_metric(row, "damage_prevention_shield_created"),
        "squee_to_graveyard": strategic_metric(row, "squee_to_graveyard"),
        "squee_upkeep_return": strategic_metric(row, "squee_upkeep_return"),
    }


def strategic_metric(row: Mapping[str, Any], metric: str) -> int:
    telemetry = row.get("telemetry") or {}
    strategic_counts = telemetry.get("strategic_event_counts") or {}
    event_counts = telemetry.get("event_counts") or {}
    return integer(strategic_counts.get(metric) if metric in strategic_counts else event_counts.get(metric))


def compact_opponent_result(row: Mapping[str, Any]) -> dict[str, Any]:
    wins = integer(row.get("wins"))
    losses = integer(row.get("losses"))
    stalls = integer(row.get("stalls"))
    return {
        "wins": wins,
        "losses": losses,
        "stalls": stalls,
        "games": wins + losses + stalls,
        "win_rate": numeric(row.get("win_rate")),
        "avg_win_turn": numeric(row.get("avg_win_turn")),
        "win_reasons": row.get("win_reasons") or {},
    }


def critical_terms_for_opponent(opponent: str) -> list[str]:
    return [term for term in CRITICAL_MATCHUP_TERMS if term.lower() in opponent.lower()]


def observation_from_result_report(path: Path, payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    results = payload.get("results") or []
    if not isinstance(results, list):
        return []
    baseline = next((row for row in results if isinstance(row, dict) and row.get("deck_key") == "deck_6"), None)
    if not isinstance(baseline, dict):
        return []
    observations: list[dict[str, Any]] = []
    for row in results:
        if not isinstance(row, dict):
            continue
        deck_key = str(row.get("deck_key") or "")
        if deck_key == "deck_6" or not deck_key.startswith("candidate_"):
            continue
        delta_pp = numeric(row.get("win_rate")) - numeric(baseline.get("win_rate"))
        observations.append(
            {
                "source_path": str(path),
                "source_file": path.name,
                "source_mtime": path.stat().st_mtime,
                "generated_at": payload.get("generated_at"),
                "source_kind": "candidate_gate",
                "package_key": deck_key,
                "family": row.get("archetype"),
                "adds": [],
                "cuts": [],
                "status": row.get("status"),
                "baseline": compact_result(baseline),
                "candidate": compact_result(row),
                "delta_pp": round(delta_pp, 2),
                "decision": gate_decision(delta_pp, baseline, row),
                "games_per_opponent": payload.get("games_per_opponent"),
                "opponent_limit": len(payload.get("opponents") or []),
                "opponent_seed": payload.get("opponent_seed"),
                "simulation_seed": payload.get("simulation_seed"),
                "source_db": payload.get("source_db"),
                "runtime_package_proposal_reports": [],
            }
        )
    return observations


def iter_gate_reports(reports_dir: Path) -> Iterable[Path]:
    paths = set(reports_dir.glob("lorehold_*gate*.json"))
    paths.update(reports_dir.glob("lorehold_*preflight*.json"))
    for path in sorted(paths):
        name = path.name
        if "_partial" in name or "_game_checkpoint" in name:
            continue
        yield path


def collect_observations(reports_dir: Path) -> list[dict[str, Any]]:
    observations: list[dict[str, Any]] = []
    for path in iter_gate_reports(reports_dir):
        payload = load_json(path)
        if not payload:
            continue
        if isinstance(payload.get("packages"), list):
            observations.extend(observation_from_package_report(path, payload))
        elif isinstance(payload.get("results"), list):
            observations.extend(observation_from_result_report(path, payload))
    return observations


def collect_synergy_critical_matchups(reports_dir: Path) -> dict[str, list[dict[str, Any]]]:
    matchups_by_package: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for path in iter_gate_reports(reports_dir):
        payload = load_json(path)
        if not payload:
            continue
        results = payload.get("results") or []
        if not isinstance(results, list):
            continue
        baseline = next((row for row in results if isinstance(row, dict) and row.get("deck_key") == "deck_6"), None)
        if not isinstance(baseline, dict):
            continue
        baseline_opponents = {
            str(row.get("opponent") or ""): row
            for row in baseline.get("opponents") or []
            if isinstance(row, dict) and row.get("opponent")
        }
        for row in results:
            if not isinstance(row, dict):
                continue
            deck_key = str(row.get("deck_key") or "")
            if not deck_key.startswith("synergy_"):
                continue
            package_key = deck_key.removeprefix("synergy_")
            for candidate_opp in row.get("opponents") or []:
                if not isinstance(candidate_opp, dict):
                    continue
                opponent = str(candidate_opp.get("opponent") or "")
                terms = critical_terms_for_opponent(opponent)
                if not terms:
                    continue
                baseline_opp = baseline_opponents.get(opponent) or {}
                baseline_compact = compact_opponent_result(baseline_opp)
                candidate_compact = compact_opponent_result(candidate_opp)
                delta_win_rate = candidate_compact["win_rate"] - baseline_compact["win_rate"]
                delta_wins = candidate_compact["wins"] - baseline_compact["wins"]
                if delta_win_rate > 0:
                    result = "improved"
                elif delta_win_rate < 0:
                    result = "regressed"
                else:
                    result = "tied"
                matchups_by_package[package_key].append(
                    {
                        "source_path": str(path),
                        "source_file": path.name,
                        "source_mtime": path.stat().st_mtime,
                        "generated_at": payload.get("generated_at"),
                        "package_key": package_key,
                        "deck_key": deck_key,
                        "opponent": opponent,
                        "critical_terms": terms,
                        "baseline": baseline_compact,
                        "candidate": candidate_compact,
                        "delta_win_rate_pp": round(delta_win_rate, 2),
                        "delta_wins": delta_wins,
                        "result": result,
                        "games_per_opponent": payload.get("games_per_opponent"),
                        "opponent_seed": payload.get("opponent_seed"),
                        "simulation_seed": payload.get("simulation_seed"),
                    }
                )
    return matchups_by_package


def canonical_package_key(package_key: str, current_leader: str) -> str:
    if current_leader.startswith("candidate_607_squee") and package_key.startswith("candidate_607_squee"):
        return current_leader
    return package_key


def registry_statuses(registry: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    statuses: dict[str, dict[str, Any]] = {}
    for section in ("tested", "leader_follow_up_probes", "leader_watchlist_probes"):
        for row in registry.get(section) or []:
            if not isinstance(row, dict):
                continue
            key = str(row.get("key") or row.get("phase") or "").strip()
            if not key:
                continue
            statuses[key] = {
                "section": section,
                "status": row.get("status"),
                "result": row.get("result"),
                "learning": row.get("learning"),
                "swap_or_scope": row.get("swap_or_scope"),
            }
    return statuses


def summarize_group(
    package_key: str,
    observations: list[dict[str, Any]],
    registry: Mapping[str, Any],
    critical_matchups: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    critical_matchups = sorted(
        critical_matchups or [],
        key=lambda row: (
            str(row.get("generated_at") or ""),
            numeric(row.get("source_mtime")),
            str(row.get("source_file") or ""),
            str(row.get("opponent") or ""),
        ),
    )
    delta_rows = [row for row in observations if has_numeric(row.get("delta_pp"))]
    deltas = [numeric(row.get("delta_pp")) for row in delta_rows]
    positive = [row for row in delta_rows if numeric(row.get("delta_pp")) > 0]
    negative = [row for row in delta_rows if numeric(row.get("delta_pp")) < 0]
    ties = [row for row in delta_rows if numeric(row.get("delta_pp")) == 0]
    critical_improvements = [row for row in critical_matchups if row.get("result") == "improved"]
    critical_regressions = [row for row in critical_matchups if row.get("result") == "regressed"]
    critical_ties = [row for row in critical_matchups if row.get("result") == "tied"]
    winota_rows = [row for row in critical_matchups if "Winota" in (row.get("critical_terms") or [])]
    winota_improvements = [row for row in winota_rows if row.get("result") == "improved"]
    winota_regressions = [row for row in winota_rows if row.get("result") == "regressed"]
    latest = sorted(
        observations,
        key=lambda row: (
            str(row.get("generated_at") or ""),
            numeric(row.get("source_mtime")),
            str(row.get("source_file") or ""),
        ),
    )[-1]
    registry_row = registry.get(package_key) or {}
    registry_status = str(registry_row.get("status") or "")
    classification = classify_group(
        registry_status=registry_status,
        positive_count=len(positive),
        negative_count=len(negative),
        tie_count=len(ties),
        latest_delta=numeric(latest.get("delta_pp")),
        latest_decision=str(latest.get("decision") or ""),
        critical_regression_count=len(critical_regressions),
    )
    return {
        "package_key": package_key,
        "classification": classification,
        "registry": registry_row,
        "observation_count": len(observations),
        "positive_count": len(positive),
        "negative_count": len(negative),
        "tie_count": len(ties),
        "critical_matchup_count": len(critical_matchups),
        "critical_improvement_count": len(critical_improvements),
        "critical_regression_count": len(critical_regressions),
        "critical_tie_count": len(critical_ties),
        "winota_coverage_count": len(winota_rows),
        "winota_improvement_count": len(winota_improvements),
        "winota_regression_count": len(winota_regressions),
        "critical_matchups": critical_matchups[-12:],
        "best_delta_pp": round(max(deltas), 2) if deltas else None,
        "worst_delta_pp": round(min(deltas), 2) if deltas else None,
        "latest_delta_pp": round(numeric(latest.get("delta_pp")), 2) if has_numeric(latest.get("delta_pp")) else None,
        "latest_source_file": latest.get("source_file"),
        "latest_baseline": latest.get("baseline"),
        "latest_candidate": latest.get("candidate"),
        "latest_decision": latest.get("decision"),
        "latest_status": latest.get("status"),
        "latest_cut_safety": latest.get("cut_safety") or {},
        "latest_prior_evidence": latest.get("prior_evidence") or {},
        "latest_invalid_reason": latest.get("invalid_reason"),
        "latest_adds": latest.get("adds") or [],
        "latest_cuts": latest.get("cuts") or [],
        "families": sorted({str(row.get("family")) for row in observations if row.get("family")}),
        "sources": [row.get("source_file") for row in observations[-8:]],
    }


def classify_group(
    *,
    registry_status: str,
    positive_count: int,
    negative_count: int,
    tie_count: int,
    latest_delta: float,
    latest_decision: str,
    critical_regression_count: int = 0,
) -> str:
    if registry_status == "promoted_current_champion":
        return "current_champion"
    if latest_decision == "preflight_blocked_protected_cut":
        return "preflight_blocked_protected_cut"
    if latest_decision == "blocked_prior_evidence":
        return "blocked_prior_evidence"
    if latest_decision == "candidate_apply_error":
        return "candidate_apply_error"
    if latest_decision == "invalid_corrected_package_definition":
        return "invalid_corrected_package_definition"
    if latest_decision in {"preflight_ready", "apply_ready"}:
        if positive_count:
            return "preflight_ready_needs_gate"
        if negative_count:
            return "preflight_ready_negative_history"
        return "preflight_ready_needs_gate"
    if registry_status.startswith("rejected") or registry_status == "rejected":
        return "registry_rejected"
    if critical_regression_count > 0 and positive_count:
        return "critical_matchup_regression_needs_rework"
    if latest_delta < 0 and negative_count:
        return "latest_rejected"
    if positive_count and negative_count:
        return "conflicting_signal_needs_champion_gate"
    if positive_count:
        return "positive_signal_needs_confirmation"
    if tie_count:
        return "tie_signal_watch"
    return "insufficient_evidence"


def build_ledger(reports_dir: Path, registry_path: Path) -> dict[str, Any]:
    registry_payload = load_json(registry_path) or {}
    observations = collect_observations(reports_dir)
    critical_matchups = collect_synergy_critical_matchups(reports_dir)
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    current_leader = str(registry_payload.get("current_leader") or "")
    for observation in observations:
        key = canonical_package_key(str(observation.get("package_key") or ""), current_leader)
        if key:
            observation["canonical_package_key"] = key
            grouped[key].append(observation)
    statuses = registry_statuses(registry_payload)
    groups = [
        summarize_group(package_key, rows, statuses, critical_matchups.get(package_key, []))
        for package_key, rows in sorted(grouped.items())
    ]
    classification_counts: dict[str, int] = {}
    for group in groups:
        key = str(group.get("classification") or "unknown")
        classification_counts[key] = classification_counts.get(key, 0) + 1
    hidden_retreat = next(
        (group for group in groups if group.get("package_key") == "hidden_retreat_stack_damage_topdeck_cut_promise"),
        None,
    )
    actionable = [
        group
        for group in groups
        if group["classification"] in {
            "positive_signal_needs_confirmation",
            "conflicting_signal_needs_champion_gate",
            "preflight_ready_needs_gate",
        }
    ]
    actionable.sort(key=lambda row: (row["classification"] != "conflicting_signal_needs_champion_gate", -numeric(row["best_delta_pp"])))
    return {
        "generated_at": utc_now(),
        "reports_dir": str(reports_dir),
        "registry_path": str(registry_path),
        "postgres_writes": False,
        "source_db_mutated": False,
        "registry_summary": {
            "protected_baseline": registry_payload.get("protected_baseline"),
            "current_leader": current_leader,
            "current_leader_priority_residual": registry_payload.get("current_leader_priority_residual"),
            "acceptance_rule": registry_payload.get("acceptance_rule") or [],
            "protected_cards_until_same_function_replacement_wins": (
                registry_payload.get("protected_cards_until_same_function_replacement_wins") or []
            ),
            "untested_queue_count": len(registry_payload.get("untested_queue") or []),
        },
        "summary": {
            "observation_count": len(observations),
            "critical_matchup_observation_count": sum(len(rows) for rows in critical_matchups.values()),
            "package_group_count": len(groups),
            "classification_counts": dict(sorted(classification_counts.items())),
            "current_leader": current_leader,
            "hidden_retreat_classification": (hidden_retreat or {}).get("classification"),
            "actionable_confirmation_count": len(actionable),
        },
        "hidden_retreat": hidden_retreat,
        "actionable_confirmation_queue": actionable[:20],
        "package_groups": sorted(
            groups,
            key=lambda row: (
                row["classification"] != "current_champion",
                row["classification"] != "preflight_blocked_protected_cut",
                row["classification"] != "latest_rejected",
                -numeric(row["best_delta_pp"], -9999.0),
                str(row["package_key"]),
            ),
        ),
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload.get("summary") or {}
    registry = payload.get("registry_summary") or {}
    lines = [
        "# Lorehold Learning Evidence Ledger",
        "",
        f"- generated_at: `{payload.get('generated_at')}`",
        f"- postgres_writes: `{payload.get('postgres_writes')}`",
        f"- source_db_mutated: `{payload.get('source_db_mutated')}`",
        f"- current_leader: `{registry.get('current_leader') or '-'}`",
        f"- protected_baseline: `{registry.get('protected_baseline') or '-'}`",
        f"- untested_queue_count: `{registry.get('untested_queue_count')}`",
        f"- observation_count: `{summary.get('observation_count')}`",
        f"- critical_matchup_observation_count: `{summary.get('critical_matchup_observation_count')}`",
        f"- package_group_count: `{summary.get('package_group_count')}`",
        f"- classification_counts: `{json.dumps(summary.get('classification_counts') or {}, sort_keys=True)}`",
        f"- hidden_retreat_classification: `{summary.get('hidden_retreat_classification') or '-'}`",
        "",
        "## Decision Guardrails",
        "",
    ]
    for rule in registry.get("acceptance_rule") or []:
        lines.append(f"- {rule}")
    lines.extend(
        [
            "",
            "## Current Read",
            "",
            "- The registry remains the authority for promotion status; raw positive gates below are treated as hypotheses until they clear the current-leader/equal-gate rule.",
            "- Critical matchup rows track Winota, Vivi, and Sisay from detailed synergy gates; a positive aggregate gate with critical regression is held for rework.",
            "- Hidden Retreat is classified from the latest local overlay gate and is not promoted unless a later same-function gate reverses the result.",
            "",
            "## Actionable Confirmation Queue",
            "",
        ]
    )
    actionable = payload.get("actionable_confirmation_queue") or []
    if not actionable:
        lines.append("- None.")
    else:
        lines.extend(
            [
                "| Package | Class | Best Delta | Latest Delta | Critical +/-/0 | Winota +/- | Latest Source |",
                "| --- | --- | ---: | ---: | --- | --- | --- |",
            ]
        )
        for row in actionable[:20]:
            lines.append(
                "| {package} | `{classification}` | {best:+.2f} | {latest:+.2f} | {crit_pos}/{crit_neg}/{crit_tie} | {winota_pos}/{winota_neg} | `{source}` |".format(
                    package=row.get("package_key"),
                    classification=row.get("classification"),
                    best=numeric(row.get("best_delta_pp")),
                    latest=numeric(row.get("latest_delta_pp")),
                    crit_pos=row.get("critical_improvement_count") or 0,
                    crit_neg=row.get("critical_regression_count") or 0,
                    crit_tie=row.get("critical_tie_count") or 0,
                    winota_pos=row.get("winota_improvement_count") or 0,
                    winota_neg=row.get("winota_regression_count") or 0,
                    source=row.get("latest_source_file"),
                )
            )
    lines.extend(["", "## Key Package Groups", ""])
    lines.extend(
        [
            "| Package | Class | Obs | +/-/0 | Critical +/-/0 | Best | Latest | Latest Source |",
            "| --- | --- | ---: | --- | --- | ---: | ---: | --- |",
        ]
    )
    for row in (payload.get("package_groups") or [])[:40]:
        lines.append(
            "| {package} | `{classification}` | {obs} | {pos}/{neg}/{tie} | {crit_pos}/{crit_neg}/{crit_tie} | {best:+.2f} | {latest:+.2f} | `{source}` |".format(
                package=row.get("package_key"),
                classification=row.get("classification"),
                obs=row.get("observation_count"),
                pos=row.get("positive_count"),
                neg=row.get("negative_count"),
                tie=row.get("tie_count"),
                crit_pos=row.get("critical_improvement_count") or 0,
                crit_neg=row.get("critical_regression_count") or 0,
                crit_tie=row.get("critical_tie_count") or 0,
                best=numeric(row.get("best_delta_pp")),
                latest=numeric(row.get("latest_delta_pp")),
                source=row.get("latest_source_file"),
            )
        )
    protected = registry.get("protected_cards_until_same_function_replacement_wins") or []
    lines.extend(["", "## Protected Cards", ""])
    lines.append(", ".join(f"`{card}`" for card in protected) if protected else "- None.")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], stem: str) -> tuple[Path, Path]:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{stem}.json"
    md_path = REPORT_DIR / f"{stem}.md"
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reports-dir", type=Path, default=REPORT_DIR)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--stem", default="lorehold_learning_evidence_ledger_20260628_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_ledger(args.reports_dir.resolve(), args.registry.resolve())
    json_path, md_path = write_outputs(payload, args.stem)
    print(json.dumps({"status": "ready", "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
