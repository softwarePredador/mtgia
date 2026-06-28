#!/usr/bin/env python3
"""Synthesize the Lorehold Mana Vault package evidence into one decision."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
PACKAGE_KEY = "mana_vault_fast_mana_cut_arcane_signet"
DEFAULT_SOURCE_REPORTS = [
    REPORT_DIR / "lorehold_mana_vault_preflight_20260628_v1_20260628_091000.json",
    REPORT_DIR / "lorehold_mana_vault_preflight_20260628_v2_20260628_093000.json",
    REPORT_DIR / "lorehold_mana_vault_gate_20260628_v1_20260628_092000.json",
    REPORT_DIR / "lorehold_mana_vault_gate_after_ramp_runtime_fix_20260628_v1_20260628_102000.json",
    REPORT_DIR / "lorehold_mana_vault_exposure_gate_20260628_v1_20260628_111500.json",
    REPORT_DIR / "lorehold_mana_vault_natural_confirmation_20260628_v2_20260628_162000.json",
    REPORT_DIR / "lorehold_mana_vault_natural_confirmation_after_forced_20260628_v1_20260628_100237.json",
]
STRATEGIC_METRICS = (
    "lorehold_spell_cast",
    "miracle_cast",
    "topdeck_manipulation_activated",
    "mana_rock_activated",
    "artifact_mana_added",
    "mana_vault_activated",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


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


def has_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def event_count(result: Mapping[str, Any], metric: str) -> int:
    telemetry = result.get("telemetry") or {}
    strategic = telemetry.get("strategic_event_counts") or {}
    events = telemetry.get("event_counts") or {}
    if metric in strategic:
        return integer(strategic.get(metric))
    return integer(events.get(metric))


def compact_result(result: Mapping[str, Any]) -> dict[str, Any]:
    compact = {
        "status": result.get("status"),
        "games": integer(result.get("games")),
        "wins": integer(result.get("wins")),
        "losses": integer(result.get("losses")),
        "stalls": integer(result.get("stalls")),
        "win_rate": numeric(result.get("win_rate")),
    }
    compact["strategic_event_counts"] = {
        metric: event_count(result, metric) for metric in STRATEGIC_METRICS
    }
    return compact


def exposure_status(package: Mapping[str, Any]) -> dict[str, Any]:
    exposure = package.get("exposure_summary") or {}
    candidate = exposure.get("candidate_added_cards") or {}
    cards = candidate.get("cards") or []
    used_cards = [
        {
            "card_name": card.get("card_name"),
            "status": card.get("status"),
            "recorded_use_count": integer(card.get("recorded_use_count")),
            "event_breakdown": card.get("event_breakdown") or {},
        }
        for card in cards
        if isinstance(card, Mapping)
    ]
    return {
        "status": exposure.get("status"),
        "candidate_added_cards_used": bool(candidate.get("all_cards_used")),
        "candidate_added_cards_accessed": bool(candidate.get("all_cards_accessed")),
        "candidate_added_cards_near_access": bool(candidate.get("all_cards_near_access")),
        "candidate_total_recorded_use_count": integer(candidate.get("total_recorded_use_count")),
        "candidate_cards": used_cards,
        "low_candidate_added_card_use": bool(exposure.get("low_candidate_added_card_use")),
    }


def is_natural_confirmation(source_file: str, forced_access_mode: Any) -> bool:
    mode = str(forced_access_mode or "none")
    return "natural_confirmation" in source_file and mode == "none"


def package_observation(path: Path, payload: Mapping[str, Any], package: Mapping[str, Any]) -> dict[str, Any]:
    gate = package.get("gate_summary") or {}
    baseline = gate.get("baseline") or {}
    candidate = gate.get("candidate") or {}
    forced_access_mode = package.get("forced_access_mode")
    row: dict[str, Any] = {
        "source_file": path.name,
        "source_path": str(path),
        "source_mtime": path.stat().st_mtime if path.exists() else 0,
        "generated_at": payload.get("generated_at"),
        "source_db_mutated": bool(payload.get("source_db_mutated")),
        "package_key": package.get("package_key"),
        "family": package.get("family"),
        "adds": list(package.get("adds") or []),
        "cuts": list(package.get("cuts") or []),
        "status": package.get("status"),
        "decision": package.get("decision"),
        "forced_access_mode": forced_access_mode or "none",
        "is_natural_confirmation": is_natural_confirmation(path.name, forced_access_mode),
        "games_per_opponent": payload.get("games_per_opponent"),
        "opponent_limit": payload.get("opponent_limit"),
        "opponent_seed": payload.get("opponent_seed"),
        "simulation_seed": payload.get("simulation_seed"),
        "exposure": exposure_status(package),
    }
    if baseline and candidate:
        delta_pp = numeric(gate.get("delta_pp"), numeric(candidate.get("win_rate")) - numeric(baseline.get("win_rate")))
        baseline_compact = compact_result(baseline)
        candidate_compact = compact_result(candidate)
        row.update(
            {
                "source_kind": "performance_gate",
                "baseline": baseline_compact,
                "candidate": candidate_compact,
                "delta_pp": round(delta_pp, 2),
                "strategic_delta": {
                    metric: (
                        candidate_compact["strategic_event_counts"].get(metric, 0)
                        - baseline_compact["strategic_event_counts"].get(metric, 0)
                    )
                    for metric in STRATEGIC_METRICS
                },
            }
        )
    else:
        row.update(
            {
                "source_kind": "preflight_or_skip",
                "baseline": {},
                "candidate": {},
                "delta_pp": None,
                "strategic_delta": {},
            }
        )
    return row


def observations_from_report(path: Path, package_key: str) -> list[dict[str, Any]]:
    payload = read_json(path)
    observations: list[dict[str, Any]] = []
    for package in payload.get("packages") or []:
        if not isinstance(package, Mapping):
            continue
        if str(package.get("package_key") or "") != package_key:
            continue
        observations.append(package_observation(path, payload, package))
    return observations


def collect_observations(paths: Iterable[Path], package_key: str = PACKAGE_KEY) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in paths:
        if not path.exists():
            rows.append(
                {
                    "source_file": path.name,
                    "source_path": str(path),
                    "source_kind": "missing_report",
                    "package_key": package_key,
                    "status": "missing_report",
                    "delta_pp": None,
                    "is_natural_confirmation": False,
                }
            )
            continue
        rows.extend(observations_from_report(path, package_key))
    return sorted(
        rows,
        key=lambda row: (
            str(row.get("generated_at") or ""),
            numeric(row.get("source_mtime")),
            str(row.get("source_file") or ""),
        ),
    )


def classify(observations: list[dict[str, Any]]) -> dict[str, Any]:
    gates = [row for row in observations if has_number(row.get("delta_pp"))]
    natural_gates = [row for row in gates if row.get("is_natural_confirmation")]
    latest_gate = gates[-1] if gates else {}
    latest_natural = natural_gates[-1] if natural_gates else {}
    exposure_confirmed = any(
        (row.get("exposure") or {}).get("candidate_added_cards_used") for row in observations
    )
    positive_gates = [row for row in gates if numeric(row.get("delta_pp")) > 0]
    negative_gates = [row for row in gates if numeric(row.get("delta_pp")) < 0]
    natural_positive = [row for row in natural_gates if numeric(row.get("delta_pp")) > 0]
    natural_negative = [row for row in natural_gates if numeric(row.get("delta_pp")) < 0]

    if not gates:
        decision = "needs_performance_gate"
        promotion_allowed = False
        next_action = "run_natural_gate_after_runtime_readiness"
    elif natural_negative and not natural_positive:
        decision = "reject_current_pair"
        promotion_allowed = False
        next_action = "do_not_repeat_mana_vault_cut_arcane_signet_without_new_cut_or_failure_target"
    elif natural_positive and not natural_negative:
        decision = "positive_needs_current_leader_confirmation"
        promotion_allowed = True
        next_action = "confirm_against_current_leader_and_critical_matchups"
    elif positive_gates and negative_gates:
        decision = "conflicting_signal_rework_or_expand_sample"
        promotion_allowed = False
        next_action = "expand_sample_only_if_new_hypothesis_explains_conflict"
    elif positive_gates and not natural_gates:
        decision = "diagnostic_positive_needs_natural_confirmation"
        promotion_allowed = False
        next_action = "run_natural_confirmation_before_promotion"
    else:
        decision = "reject_or_rework"
        promotion_allowed = False
        next_action = "rework_package_before_more_gate_time"

    strategic_delta_total = Counter()
    for row in gates:
        strategic_delta_total.update(row.get("strategic_delta") or {})

    return {
        "decision": decision,
        "promotion_allowed": promotion_allowed,
        "next_action": next_action,
        "exposure_confirmed": exposure_confirmed,
        "performance_gate_count": len(gates),
        "natural_gate_count": len(natural_gates),
        "positive_gate_count": len(positive_gates),
        "negative_gate_count": len(negative_gates),
        "natural_positive_count": len(natural_positive),
        "natural_negative_count": len(natural_negative),
        "latest_gate_source": latest_gate.get("source_file"),
        "latest_gate_delta_pp": latest_gate.get("delta_pp"),
        "latest_natural_source": latest_natural.get("source_file"),
        "latest_natural_delta_pp": latest_natural.get("delta_pp"),
        "latest_natural_baseline": latest_natural.get("baseline") or {},
        "latest_natural_candidate": latest_natural.get("candidate") or {},
        "strategic_delta_total": dict(sorted(strategic_delta_total.items())),
        "sample_caveat": "Repeated gates share small opponent/seed scopes; use them as consistency evidence, not as independent large-sample proof.",
    }


def build_synthesis(paths: Iterable[Path], package_key: str = PACKAGE_KEY) -> dict[str, Any]:
    source_paths = list(paths)
    observations = collect_observations(source_paths, package_key=package_key)
    status_counts = Counter(str(row.get("status") or "unknown") for row in observations)
    kind_counts = Counter(str(row.get("source_kind") or "unknown") for row in observations)
    decision = classify(observations)
    adds = next((row.get("adds") for row in observations if row.get("adds")), [])
    cuts = next((row.get("cuts") for row in observations if row.get("cuts")), [])
    return {
        "generated_at": utc_now(),
        "postgres_writes": False,
        "source_db_mutated": False,
        "package_key": package_key,
        "adds": adds,
        "cuts": cuts,
        "summary": {
            "source_report_count": len(source_paths),
            "observation_count": len(observations),
            "status_counts": dict(sorted(status_counts.items())),
            "source_kind_counts": dict(sorted(kind_counts.items())),
            **decision,
        },
        "decision_rules": [
            "preflight_or_skip reports are readiness signals, not performance evidence",
            "forced/exposure diagnostics can prove card access, but do not promote by themselves",
            "natural promotion requires a positive natural confirmation without unresolved critical regression",
            "negative natural confirmations reject the exact add/cut pair until the cut or failure target changes",
        ],
        "observations": observations,
    }


def format_delta(value: Any) -> str:
    if has_number(value):
        return f"{numeric(value):+.2f}"
    return "-"


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload.get("summary") or {}
    lines = [
        "# Lorehold Mana Vault Evidence Synthesis - 2026-06-28",
        "",
        f"- generated_at: `{payload.get('generated_at')}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        f"- package_key: `{payload.get('package_key')}`",
        f"- adds: {', '.join(f'`{card}`' for card in payload.get('adds') or [])}",
        f"- cuts: {', '.join(f'`{card}`' for card in payload.get('cuts') or [])}",
        f"- decision: `{summary.get('decision')}`",
        f"- promotion_allowed: `{str(bool(summary.get('promotion_allowed'))).lower()}`",
        f"- next_action: `{summary.get('next_action')}`",
        f"- sample_caveat: {summary.get('sample_caveat')}",
        "",
        "## Summary",
        "",
        f"- source_report_count: `{summary.get('source_report_count')}`",
        f"- observation_count: `{summary.get('observation_count')}`",
        f"- performance_gate_count: `{summary.get('performance_gate_count')}`",
        f"- natural_gate_count: `{summary.get('natural_gate_count')}`",
        f"- positive_gate_count: `{summary.get('positive_gate_count')}`",
        f"- negative_gate_count: `{summary.get('negative_gate_count')}`",
        f"- latest_natural_source: `{summary.get('latest_natural_source') or '-'}`",
        f"- latest_natural_delta_pp: `{format_delta(summary.get('latest_natural_delta_pp'))}`",
        f"- exposure_confirmed: `{str(bool(summary.get('exposure_confirmed'))).lower()}`",
        f"- strategic_delta_total: `{json.dumps(summary.get('strategic_delta_total') or {}, sort_keys=True)}`",
        "",
        "## Decision Rules",
        "",
    ]
    lines.extend(f"- {rule}" for rule in payload.get("decision_rules") or [])
    lines.extend(
        [
            "",
            "## Evidence",
            "",
            "| Source | Kind | Status | Natural | Baseline | Candidate | Delta | Strategic Delta |",
            "| --- | --- | --- | --- | --- | --- | ---: | --- |",
        ]
    )
    for row in payload.get("observations") or []:
        baseline = row.get("baseline") or {}
        candidate = row.get("candidate") or {}
        baseline_record = "-"
        candidate_record = "-"
        if baseline:
            baseline_record = "{wins}-{losses}-{stalls} ({rate:.2f}%)".format(
                wins=baseline.get("wins"),
                losses=baseline.get("losses"),
                stalls=baseline.get("stalls"),
                rate=numeric(baseline.get("win_rate")),
            )
        if candidate:
            candidate_record = "{wins}-{losses}-{stalls} ({rate:.2f}%)".format(
                wins=candidate.get("wins"),
                losses=candidate.get("losses"),
                stalls=candidate.get("stalls"),
                rate=numeric(candidate.get("win_rate")),
            )
        lines.append(
            "| `{source}` | `{kind}` | `{status}` | `{natural}` | {baseline} | {candidate} | {delta} | `{strategic}` |".format(
                source=row.get("source_file"),
                kind=row.get("source_kind"),
                status=row.get("status"),
                natural=str(bool(row.get("is_natural_confirmation"))).lower(),
                baseline=baseline_record,
                candidate=candidate_record,
                delta=format_delta(row.get("delta_pp")),
                strategic=json.dumps(row.get("strategic_delta") or {}, sort_keys=True),
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
    parser.add_argument("--package-key", default=PACKAGE_KEY)
    parser.add_argument("--source-report", type=Path, action="append", default=[])
    parser.add_argument("--stem", default="lorehold_mana_vault_evidence_synthesis_20260628_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source_reports = [path.resolve() for path in args.source_report] or DEFAULT_SOURCE_REPORTS
    payload = build_synthesis(source_reports, package_key=args.package_key)
    json_path, md_path = write_outputs(payload, args.stem)
    print(json.dumps({"status": "ready", "json": str(json_path), "markdown": str(md_path), "decision": payload["summary"]["decision"]}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
