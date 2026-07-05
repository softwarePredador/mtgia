#!/usr/bin/env python3
"""Synthesize current same-lane microbenchmark evidence for Lorehold 607.

The profiled cut benchmark generator can find static same-lane candidates. This
script adds the missing decision layer: if a static-ready pair has already lost
natural battle evidence, it must not be rerun as a fresh promotion route.
"""

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

DEFAULT_BENCHMARK = REPORT_DIR / "lorehold_same_lane_diagnostic_microbenchmarks_20260705_current.json"
DEFAULT_PRIOR_GATES = [
    REPORT_DIR
    / "lorehold_big_spell_value_creative_technique_gate_20260630_goal_learning_smoke_20260630_213730_possibility_storm_same_lane_benchmark_cut_creative_technique.json",
    REPORT_DIR
    / "lorehold_607_unprotected_staple_relearn_gate_20260704_possibility_storm_smoke_possibility_storm_same_lane_benchmark_cut_creative_technique.json",
    REPORT_DIR
    / "lorehold_607_unprotected_staple_relearn_gate_20260704_possibility_storm_forced_opening_possibility_storm_same_lane_benchmark_cut_creative_technique.json",
]
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_same_lane_microbenchmark_decision_synthesis_20260705_current"

EXTERNAL_RULE_CONTEXT = [
    {
        "source": "Scryfall Possibility Storm",
        "url": "https://scryfall.com/card/dgm/34/possibility-storm",
        "learning": "Possibility Storm is Commander legal and red, so it passes the Lorehold color/legal entry gate.",
    },
    {
        "source": "Gatherer Possibility Storm",
        "url": "https://gatherer.wizards.com/DGM/en-us/34/possibility-storm",
        "learning": "Official card text/rulings support treating it as a cast-from-hand replacement/free-cast chaos engine.",
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def result_counts(deck_result: Mapping[str, Any]) -> dict[str, int]:
    games = [game for game in as_list(deck_result.get("game_results")) if isinstance(game, Mapping)]
    wins = sum(1 for game in games if game.get("result") == "win")
    losses = sum(1 for game in games if game.get("result") == "loss")
    return {"wins": wins, "losses": losses, "draws": len(games) - wins - losses, "games": len(games)}


def win_rate(counts: Mapping[str, int]) -> float:
    games = int(counts.get("games") or 0)
    return round(100.0 * int(counts.get("wins") or 0) / games, 2) if games else 0.0


def focus_card_count(deck_result: Mapping[str, Any], card_name: str) -> int:
    total = 0
    for game in as_list(deck_result.get("game_results")):
        if not isinstance(game, Mapping):
            continue
        total += int((game.get("focus_card_trace_card_counts") or {}).get(card_name) or 0)
    return total


def card_event_count(deck_result: Mapping[str, Any], card_name: str) -> int:
    total = 0
    suffix = f":{card_name}"
    for game in as_list(deck_result.get("game_results")):
        if not isinstance(game, Mapping):
            continue
        for key, value in (game.get("card_event_counts") or {}).items():
            if str(key).endswith(suffix):
                total += int(value or 0)
    return total


def prior_gate_summary(path: Path, payload: Mapping[str, Any], *, candidate_card: str, cut_card: str) -> dict[str, Any]:
    results = [dict(row) for row in as_list(payload.get("results")) if isinstance(row, Mapping)]
    baseline = next((row for row in results if row.get("deck_key") == "deck_607"), {})
    candidate = next((row for row in results if row.get("deck_key") != "deck_607"), {})
    baseline_counts = result_counts(baseline)
    candidate_counts = result_counts(candidate)
    baseline_wr = win_rate(baseline_counts)
    candidate_wr = win_rate(candidate_counts)
    forced_access_mode = str(candidate.get("forced_access_mode") or baseline.get("forced_access_mode") or payload.get("forced_access_mode") or "none")
    delta_pp = round(candidate_wr - baseline_wr, 2)
    if forced_access_mode == "none" and candidate_counts["games"] and delta_pp < 0:
        decision = "prior_natural_reject"
    elif forced_access_mode != "none" and candidate_counts["games"] and delta_pp > 0:
        decision = "forced_access_signal_only"
    elif candidate_counts["games"] and delta_pp >= 0:
        decision = "nonnegative_but_not_promotion_without_contract"
    else:
        decision = "insufficient_prior_gate_data"
    return {
        "path": rel(path),
        "status": payload.get("status"),
        "forced_access_mode": forced_access_mode,
        "baseline": {
            "deck_key": baseline.get("deck_key"),
            **baseline_counts,
            "win_rate": baseline_wr,
            "focus_cut_trace_count": focus_card_count(baseline, cut_card),
            "candidate_card_event_count": card_event_count(baseline, candidate_card),
        },
        "candidate": {
            "deck_key": candidate.get("deck_key"),
            **candidate_counts,
            "win_rate": candidate_wr,
            "focus_candidate_trace_count": focus_card_count(candidate, candidate_card),
            "candidate_card_event_count": card_event_count(candidate, candidate_card),
        },
        "delta_win_rate_pp": delta_pp,
        "decision": decision,
    }


def top_blocked_for_cut(benchmark: Mapping[str, Any], cut_name: str, limit: int = 12) -> list[dict[str, Any]]:
    rows = []
    for row in as_list(benchmark.get("top_pair_evaluations")):
        if not isinstance(row, Mapping) or row.get("cut") != cut_name or row.get("status") == "preflight_ready":
            continue
        rows.append(
            {
                "candidate": row.get("candidate"),
                "package_key": row.get("package_key"),
                "score": row.get("score"),
                "candidate_role": row.get("candidate_role"),
                "cut_role": row.get("cut_role"),
                "blockers": as_list(row.get("blockers")),
            }
        )
    return rows[:limit]


def selected_decisions(
    benchmark: Mapping[str, Any],
    prior_gate_rows: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    rows = []
    natural_rejects = [row for row in prior_gate_rows if row["decision"] == "prior_natural_reject"]
    forced_signals = [row for row in prior_gate_rows if row["decision"] == "forced_access_signal_only"]
    for row in as_list(benchmark.get("selected_pairs")):
        if not isinstance(row, Mapping):
            continue
        if natural_rejects:
            decision = "static_ready_but_prior_natural_rejected"
            next_action = "do_not_rerun_natural_gate_without_new_material_evidence"
        else:
            decision = "static_ready_needs_preflight"
            next_action = "run_profiled_cut_benchmark_preflight"
        rows.append(
            {
                "package_key": row.get("package_key"),
                "candidate": row.get("candidate"),
                "cut": row.get("cut"),
                "candidate_role": row.get("candidate_role"),
                "cut_role": row.get("cut_role"),
                "static_status": row.get("status"),
                "score": row.get("score"),
                "prior_natural_reject_count": len(natural_rejects),
                "forced_access_signal_count": len(forced_signals),
                "decision": decision,
                "next_action": next_action,
            }
        )
    return rows


def build_payload(
    *,
    benchmark: Mapping[str, Any],
    benchmark_path: Path,
    prior_gate_payloads: list[tuple[Path, Mapping[str, Any]]],
) -> dict[str, Any]:
    selected = [dict(row) for row in as_list(benchmark.get("selected_pairs")) if isinstance(row, Mapping)]
    candidate_card = str(selected[0].get("candidate") if selected else "Possibility Storm")
    cut_card = str(selected[0].get("cut") if selected else "Creative Technique")
    prior_gate_rows = [
        prior_gate_summary(path, payload, candidate_card=candidate_card, cut_card=cut_card)
        for path, payload in prior_gate_payloads
        if payload
    ]
    candidate_rows = selected_decisions(benchmark, prior_gate_rows)
    natural_reject_count = sum(1 for row in prior_gate_rows if row["decision"] == "prior_natural_reject")
    forced_signal_count = sum(1 for row in prior_gate_rows if row["decision"] == "forced_access_signal_only")
    static_ready_count = int((benchmark.get("summary") or {}).get("preflight_ready_pair_count") or 0)
    if static_ready_count and natural_reject_count:
        status = "same_lane_static_ready_prior_natural_rejected_keep_607"
        recommended_next_action = "record_possibility_storm_as_diagnostic_only_and_do_not_rerun_gate"
    elif static_ready_count:
        status = "same_lane_static_ready_requires_preflight"
        recommended_next_action = "run_profiled_cut_benchmark_preflight"
    else:
        status = "same_lane_microbenchmark_queue_exhausted_keep_607"
        recommended_next_action = "expand_reference_pool_or_trace_mining"
    bender_blocked = top_blocked_for_cut(benchmark, "Bender's Waterskin")
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_same_lane_microbenchmark_decision_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": {
            "benchmark": rel(benchmark_path),
            "prior_gates": [rel(path) for path, _payload in prior_gate_payloads],
        },
        "external_rule_context": EXTERNAL_RULE_CONTEXT,
        "status": status,
        "summary": {
            "current_baseline": "deck_607",
            "profiled_cut_count": int((benchmark.get("summary") or {}).get("profiled_cut_count") or 0),
            "supported_cut_count": int((benchmark.get("summary") or {}).get("supported_cut_count") or 0),
            "pair_evaluation_count": int((benchmark.get("summary") or {}).get("pair_evaluation_count") or 0),
            "static_preflight_ready_pair_count": static_ready_count,
            "selected_package_count": int((benchmark.get("summary") or {}).get("selected_package_count") or 0),
            "prior_natural_reject_count": natural_reject_count,
            "forced_access_signal_count": forced_signal_count,
            "bender_waterskin_ready_pair_count": 0,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "recommended_next_action": recommended_next_action,
        },
        "candidate_decisions": candidate_rows,
        "prior_gate_evidence": prior_gate_rows,
        "bender_waterskin_blocked_queue": bender_blocked,
        "decision": {
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": False,
            "natural_battle_allowed_now": False,
            "reason": (
                "The current static same-lane scan finds Possibility Storm over Creative Technique, "
                "but prior natural gates already lost to protected 607. Forced-access improvement is "
                "diagnostic only and cannot override natural evidence."
                if natural_reject_count
                else "No promotion decision is possible without equal natural battle evidence."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_promote_possibility_storm_over_creative_technique",
                "do_not_retest_bender_waterskin_fast_mana_pairs already blocked by prior_exact_reject",
                "only reopen this lane with new material evidence, a changed runtime adapter, or a new same-lane candidate not in the exhausted queue",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Same-Lane Microbenchmark Decision Synthesis",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- static_preflight_ready_pair_count: `{summary['static_preflight_ready_pair_count']}`",
        f"- prior_natural_reject_count: `{summary['prior_natural_reject_count']}`",
        f"- forced_access_signal_count: `{summary['forced_access_signal_count']}`",
        f"- natural_battle_allowed_now: `{str(summary['natural_battle_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        "",
        "## Candidate Decisions",
        "",
        "| Package | Candidate | Cut | Decision | Next Action |",
        "| --- | --- | --- | --- | --- |",
    ]
    for row in payload["candidate_decisions"]:
        lines.append(
            f"| {row['package_key']} | {row['candidate']} | {row['cut']} | `{row['decision']}` | `{row['next_action']}` |"
        )
    lines.extend(
        [
            "",
            "## Prior Gate Evidence",
            "",
            "| Gate | Mode | Baseline | Candidate | Delta pp | Decision |",
            "| --- | --- | ---: | ---: | ---: | --- |",
        ]
    )
    for row in payload["prior_gate_evidence"]:
        baseline = f"{row['baseline']['wins']}/{row['baseline']['games']}"
        candidate = f"{row['candidate']['wins']}/{row['candidate']['games']}"
        lines.append(
            f"| {Path(row['path']).name} | `{row['forced_access_mode']}` | {baseline} | {candidate} | {row['delta_win_rate_pp']} | `{row['decision']}` |"
        )
    lines.extend(
        [
            "",
            "## Bender's Waterskin Queue",
            "",
            "| Candidate | Score | Blockers |",
            "| --- | ---: | --- |",
        ]
    )
    for row in payload["bender_waterskin_blocked_queue"][:12]:
        lines.append(f"| {row['candidate']} | {row['score']} | {', '.join(row['blockers']) or '-'} |")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append("- next_actions:")
    for action in decision["next_actions"]:
        lines.append(f"  - {action}")
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
    parser.add_argument("--benchmark", type=Path, default=DEFAULT_BENCHMARK)
    parser.add_argument("--prior-gate", type=Path, action="append", default=[])
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    prior_paths = args.prior_gate or DEFAULT_PRIOR_GATES
    payload = build_payload(
        benchmark=read_json(args.benchmark),
        benchmark_path=args.benchmark,
        prior_gate_payloads=[(path, read_json(path)) for path in prior_paths],
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
