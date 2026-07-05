#!/usr/bin/env python3
"""Decide the Plateau/Radiant Summit mana-base diagnostic from current gates."""

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

DEFAULT_PREFLIGHT = REPORT_DIR / "lorehold_mana_base_candidate_preflight_20260705_plateau_radiant_current.json"
DEFAULT_NATURAL_GATE = REPORT_DIR / "lorehold_mana_base_plateau_radiant_smoke_20260705_current.json"
DEFAULT_FORCED_GATE = REPORT_DIR / "lorehold_mana_base_plateau_radiant_forced_opening_20260705_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_mana_base_plateau_radiant_decision_20260705_current"

BASELINE_KEY = "deck_607"
CANDIDATE_KEY = "candidate_607_plateau_radiant_mana_base_v1"


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


def gate_summary(report: Mapping[str, Any]) -> dict[str, Any]:
    baseline = result_by_key(report, BASELINE_KEY)
    candidate = result_by_key(report, CANDIDATE_KEY)
    return {
        "forced_access_mode": report.get("forced_access_mode") or "none",
        "games_per_opponent": report.get("games_per_opponent"),
        "opponents": report.get("opponents") or [],
        "baseline": {
            "deck_key": BASELINE_KEY,
            "record": record(baseline),
            "strategic_games": strategic_games(baseline),
            "radiant_summit_access": focus_summary(baseline, "Radiant Summit"),
            "plateau_access": focus_summary(baseline, "Plateau"),
        },
        "candidate": {
            "deck_key": CANDIDATE_KEY,
            "record": record(candidate),
            "strategic_games": strategic_games(candidate),
            "plateau_access": focus_summary(candidate, "Plateau"),
            "radiant_summit_access": focus_summary(candidate, "Radiant Summit"),
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
    natural = gate_summary(read_json(natural_gate_path))
    forced = gate_summary(read_json(forced_gate_path))
    preflight_ready = preflight.get("status") == "battle_smoke_preflight_ready"
    natural_pass = candidate_tied_or_beat(natural)
    forced_pass = candidate_tied_or_beat(forced)
    blockers: list[str] = []
    if not preflight_ready:
        blockers.append("preflight_not_ready")
    if not natural_pass:
        blockers.append("natural_smoke_lost_to_607")
    if not forced_pass:
        blockers.append("forced_opening_hand_diagnostic_lost_to_607")
    natural_candidate_plateau_accessed = as_int(
        ((natural.get("candidate") or {}).get("plateau_access") or {}).get("accessed_games")
    )
    if natural_candidate_plateau_accessed == 0:
        blockers.append("natural_smoke_did_not_access_plateau")

    status = "reject_promotion_keep_607_current_baseline"
    if preflight_ready and natural_pass and forced_pass:
        status = "diagnostic_positive_needs_full_confirmation"

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_mana_base_plateau_radiant_decision",
        "status": status,
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": [rel(preflight_path), rel(natural_gate_path), rel(forced_gate_path)],
        "summary": {
            "candidate": "+Plateau / -Radiant Summit",
            "preflight_ready": preflight_ready,
            "natural_candidate_tied_or_beat_607": natural_pass,
            "forced_candidate_tied_or_beat_607": forced_pass,
            "promotion_allowed": False,
            "full_confirmation_allowed_now": status == "diagnostic_positive_needs_full_confirmation",
            "keep_607_as_protected_baseline": True,
            "blockers": sorted(set(blockers)),
        },
        "preflight_summary": preflight.get("summary") or {},
        "natural_smoke": natural,
        "forced_opening_hand_diagnostic": forced,
        "decision": {
            "current_best_baseline": "deck_607",
            "candidate": "+Plateau / -Radiant Summit",
            "promotion_allowed": False,
            "reason": (
                "The candidate passed structural/preflight checks, but lost both the natural smoke "
                "and the opening-hand forced diagnostic against protected 607. Natural smoke did not "
                "access Plateau, so this is not card-level proof that Plateau is bad; it is enough to "
                "keep promotion and larger confirmation closed for this exact isolated swap."
            ),
            "next_action": "keep_607_and_move_to_next_learning_hypothesis_or_revisit_only_with_new_mana_trace_evidence",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    natural = payload["natural_smoke"]
    forced = payload["forced_opening_hand_diagnostic"]
    lines = [
        "# Lorehold Plateau/Radiant Mana-Base Decision",
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
            f"- natural baseline Radiant Summit: `{json.dumps(natural['baseline']['radiant_summit_access'], sort_keys=True)}`",
            f"- natural candidate Plateau: `{json.dumps(natural['candidate']['plateau_access'], sort_keys=True)}`",
            f"- forced baseline Radiant Summit: `{json.dumps(forced['baseline']['radiant_summit_access'], sort_keys=True)}`",
            f"- forced candidate Plateau: `{json.dumps(forced['candidate']['plateau_access'], sort_keys=True)}`",
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
