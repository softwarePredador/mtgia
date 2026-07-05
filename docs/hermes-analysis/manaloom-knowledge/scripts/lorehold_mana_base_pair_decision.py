#!/usr/bin/env python3
"""Decide a Lorehold mana-base diagnostic pair from current gate evidence."""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_PREFLIGHT = REPORT_DIR / "lorehold_mana_base_candidate_preflight_20260705_plateau_turbulent_current.json"
DEFAULT_NATURAL_GATE = REPORT_DIR / "lorehold_mana_base_plateau_turbulent_steppe_smoke_20260705_current.json"
DEFAULT_FORCED_GATE = REPORT_DIR / "lorehold_mana_base_plateau_turbulent_steppe_forced_opening_20260705_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_mana_base_plateau_turbulent_steppe_decision_20260705_current"

BASELINE_KEY = "deck_607"


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def result_by_key(report: Mapping[str, Any], deck_key: str) -> dict[str, Any]:
    for row in report.get("results") or []:
        if isinstance(row, Mapping) and str(row.get("deck_key")) == deck_key:
            return dict(row)
    return {}


def candidate_result(report: Mapping[str, Any]) -> dict[str, Any]:
    for row in report.get("results") or []:
        if isinstance(row, Mapping) and str(row.get("deck_key")) != BASELINE_KEY:
            return dict(row)
    return {}


def record(row: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "wins": as_int(row.get("wins")),
        "losses": as_int(row.get("losses")),
        "stalls": as_int(row.get("stalls")),
        "games": as_int(row.get("games")),
        "win_rate": row.get("win_rate"),
        "avg_win_turn": row.get("avg_win_turn"),
    }


def strategic_games(row: Mapping[str, Any]) -> dict[str, int]:
    telemetry = row.get("telemetry") if isinstance(row.get("telemetry"), Mapping) else {}
    strategic = telemetry.get("strategic_games") if isinstance(telemetry.get("strategic_games"), Mapping) else {}
    out: dict[str, int] = {}
    for event in (
        "miracle_cast",
        "topdeck_manipulation_activated",
        "lorehold_spell_cast",
        "lorehold_cost_paid",
        "lorehold_upkeep_rummage",
        "discard_to_top_replacement",
    ):
        payload = strategic.get(event) if isinstance(strategic, Mapping) else {}
        out[event] = as_int(payload.get("games")) if isinstance(payload, Mapping) else 0
    return out


def focus_summary(row: Mapping[str, Any], card_name: str) -> dict[str, Any]:
    telemetry = row.get("telemetry") if isinstance(row.get("telemetry"), Mapping) else {}
    focus = (
        telemetry.get("focus_card_access_summary")
        if isinstance(telemetry.get("focus_card_access_summary"), Mapping)
        else {}
    )
    payload = focus.get(card_name) if isinstance(focus, Mapping) else {}
    return dict(payload) if isinstance(payload, Mapping) else {}


def gate_summary(report: Mapping[str, Any], *, add: str, cut: str) -> dict[str, Any]:
    baseline = result_by_key(report, BASELINE_KEY)
    candidate = candidate_result(report)
    return {
        "forced_access_mode": report.get("forced_access_mode") or "none",
        "games_per_opponent": report.get("games_per_opponent"),
        "opponents": report.get("opponents") or [],
        "baseline": {
            "deck_key": BASELINE_KEY,
            "record": record(baseline),
            "strategic_games": strategic_games(baseline),
            "add_access": focus_summary(baseline, add),
            "cut_access": focus_summary(baseline, cut),
        },
        "candidate": {
            "deck_key": str(candidate.get("deck_key") or ""),
            "record": record(candidate),
            "strategic_games": strategic_games(candidate),
            "add_access": focus_summary(candidate, add),
            "cut_access": focus_summary(candidate, cut),
        },
    }


def candidate_tied_or_beat(gate: Mapping[str, Any]) -> bool:
    baseline = ((gate.get("baseline") or {}).get("record") or {})
    candidate = ((gate.get("candidate") or {}).get("record") or {})
    return as_int(candidate.get("wins")) >= as_int(baseline.get("wins")) and as_int(candidate.get("losses")) <= as_int(
        baseline.get("losses")
    )


def build_payload(
    *,
    preflight_path: Path = DEFAULT_PREFLIGHT,
    natural_gate_path: Path = DEFAULT_NATURAL_GATE,
    forced_gate_path: Path = DEFAULT_FORCED_GATE,
) -> dict[str, Any]:
    preflight = read_json(preflight_path)
    preflight_summary = preflight.get("summary") if isinstance(preflight.get("summary"), Mapping) else {}
    add = str(preflight_summary.get("add") or "")
    cut = str(preflight_summary.get("cut") or "")
    candidate_label = f"+{add} / -{cut}"
    natural = gate_summary(read_json(natural_gate_path), add=add, cut=cut)
    forced = gate_summary(read_json(forced_gate_path), add=add, cut=cut)
    preflight_ready = preflight.get("status") == "battle_smoke_preflight_ready"
    natural_pass = candidate_tied_or_beat(natural)
    forced_pass = candidate_tied_or_beat(forced)
    natural_candidate_add_accessed = as_int(((natural.get("candidate") or {}).get("add_access") or {}).get("accessed_games"))
    forced_candidate_add_accessed = as_int(((forced.get("candidate") or {}).get("add_access") or {}).get("accessed_games"))

    blockers: list[str] = []
    if not preflight_ready:
        blockers.append("preflight_not_ready")
    if not natural_pass:
        blockers.append("natural_smoke_lost_to_607")
    if natural_candidate_add_accessed == 0:
        blockers.append("natural_smoke_did_not_access_added_land")
    if not forced_pass:
        blockers.append("forced_opening_hand_diagnostic_lost_to_607")
    if forced_candidate_add_accessed == 0:
        blockers.append("forced_opening_hand_did_not_access_added_land")

    status = "reject_promotion_keep_607_current_baseline"
    if preflight_ready and natural_pass and forced_pass and forced_candidate_add_accessed > 0:
        status = "diagnostic_positive_needs_full_confirmation"

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_mana_base_pair_decision",
        "status": status,
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": [rel(preflight_path), rel(natural_gate_path), rel(forced_gate_path)],
        "summary": {
            "candidate": candidate_label,
            "add": add,
            "cut": cut,
            "preflight_ready": preflight_ready,
            "natural_candidate_tied_or_beat_607": natural_pass,
            "forced_candidate_tied_or_beat_607": forced_pass,
            "natural_candidate_add_accessed_games": natural_candidate_add_accessed,
            "forced_candidate_add_accessed_games": forced_candidate_add_accessed,
            "promotion_allowed": False,
            "full_confirmation_allowed_now": status == "diagnostic_positive_needs_full_confirmation",
            "keep_607_as_protected_baseline": True,
            "blockers": sorted(set(blockers)),
        },
        "preflight_summary": preflight_summary,
        "natural_smoke": natural,
        "forced_opening_hand_diagnostic": forced,
        "decision": {
            "current_best_baseline": "deck_607",
            "candidate": candidate_label,
            "promotion_allowed": False,
            "reason": (
                "The candidate passed structural/preflight checks, but cannot be promoted unless it ties "
                "or beats protected 607 in natural and focused access diagnostics with actual added-card access."
            ),
            "next_action": (
                "allow_full_confirmation_gate"
                if status == "diagnostic_positive_needs_full_confirmation"
                else "block_exact_pair_and_keep_607_until_new_material_evidence"
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    natural = payload["natural_smoke"]
    forced = payload["forced_opening_hand_diagnostic"]
    add = str(summary["add"])
    cut = str(summary["cut"])
    lines = [
        "# Lorehold Mana-Base Pair Decision",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- candidate: `{summary['candidate']}`",
        f"- preflight_ready: `{str(summary['preflight_ready']).lower()}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- full_confirmation_allowed_now: `{str(summary['full_confirmation_allowed_now']).lower()}`",
        f"- keep_607_as_protected_baseline: `{str(summary['keep_607_as_protected_baseline']).lower()}`",
        f"- blockers: `{json.dumps(summary['blockers'])}`",
        "",
        "## Gate Results",
        "",
        "| Gate | Forced Access | Baseline 607 | Candidate | Candidate Pass |",
        "| --- | --- | ---: | ---: | --- |",
    ]
    for label, gate, passed in (
        ("natural_smoke", natural, summary["natural_candidate_tied_or_beat_607"]),
        ("forced_opening_hand", forced, summary["forced_candidate_tied_or_beat_607"]),
    ):
        baseline = gate["baseline"]["record"]
        candidate = gate["candidate"]["record"]
        lines.append(
            "| {label} | `{forced}` | `{bw}W/{bl}L/{bs}S` | `{cw}W/{cl}L/{cs}S` | `{passed}` |".format(
                label=label,
                forced=gate["forced_access_mode"],
                bw=baseline["wins"],
                bl=baseline["losses"],
                bs=baseline["stalls"],
                cw=candidate["wins"],
                cl=candidate["losses"],
                cs=candidate["stalls"],
                passed=str(passed).lower(),
            )
        )
    lines.extend(
        [
            "",
            "## Focus Access",
            "",
            f"- natural baseline {cut}: `{json.dumps(natural['baseline']['cut_access'], sort_keys=True)}`",
            f"- natural candidate {add}: `{json.dumps(natural['candidate']['add_access'], sort_keys=True)}`",
            f"- forced baseline {cut}: `{json.dumps(forced['baseline']['cut_access'], sort_keys=True)}`",
            f"- forced candidate {add}: `{json.dumps(forced['candidate']['add_access'], sort_keys=True)}`",
            "",
            "## Decision",
            "",
            f"- current_best_baseline: `{payload['decision']['current_best_baseline']}`",
            f"- candidate: `{payload['decision']['candidate']}`",
            f"- promotion_allowed: `{str(payload['decision']['promotion_allowed']).lower()}`",
            f"- reason: {payload['decision']['reason']}",
            f"- next_action: `{payload['decision']['next_action']}`",
        ]
    )
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preflight", type=Path, default=DEFAULT_PREFLIGHT)
    parser.add_argument("--natural-gate", type=Path, default=DEFAULT_NATURAL_GATE)
    parser.add_argument("--forced-gate", type=Path, default=DEFAULT_FORCED_GATE)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(
        preflight_path=args.preflight,
        natural_gate_path=args.natural_gate,
        forced_gate_path=args.forced_gate,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "promotion_allowed": payload["summary"]["promotion_allowed"],
                "json": rel(json_path),
                "markdown": rel(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
