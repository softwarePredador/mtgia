#!/usr/bin/env python3
"""Route the next Lorehold shell target from closing-window evidence.

This read-only router combines closing-window gaps, failed from-scratch shell
evidence, and cut evidence. It decides which trace hypothesis can define the
next shell contract and blocks any immediate deck mutation or natural battle.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_CLOSING_TRACE = REPORT_DIR / "lorehold_closing_window_trace_miner_20260704_role_tag_repair.json"
DEFAULT_SHELL_FAILURE = (
    REPORT_DIR / "lorehold_from_scratch_shell_failure_synthesis_20260705_current_relearn.json"
)
DEFAULT_CUT_MINER = (
    REPORT_DIR / "lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json"
)
DEFAULT_MIRACLE_FAILURE = REPORT_DIR / "lorehold_miracle_trace_failure_miner_20260704_current.json"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_closing_window_next_shell_target_router_20260705_current_relearn"
)

HYPOTHESIS_WEIGHTS = {
    "preserve_topdeck_miracle_floor_micro_package": 120,
    "approach_big_spell_conversion_preservation": 102,
    "pressure_survival_without_engine_cuts": 80,
}

BLOCKING_FLAGS_BY_HYPOTHESIS = {
    "preserve_topdeck_miracle_floor_micro_package": {
        "miracle_trace_missing",
        "topdeck_activation_missing",
        "topdeck_anchor_access_regressed",
    },
    "approach_big_spell_conversion_preservation": {
        "miracle_trace_missing",
        "pressure_conversion_unproven",
        "topdeck_anchor_access_regressed",
    },
    "pressure_survival_without_engine_cuts": {
        "pressure_causality_unproven",
        "fast_pressure_slice_not_protected",
    },
}

SHELL_CONTRACTS = {
    "preserve_topdeck_miracle_floor_micro_package": {
        "contract_key": "miracle_access_first_shell_contract",
        "shell_type": "micro_shell_before_full_generation",
        "must_preserve": [
            "Sensei's Divining Top",
            "Scroll Rack",
            "Bender's Waterskin",
            "Victory Chimes",
            "Approach of the Second Sun",
        ],
        "target_metrics": [
            "miracle_cast",
            "topdeck_manipulation_activated",
            "lorehold_spell_cast",
            "lorehold_upkeep_rummage",
            "static_cost_reduction_total",
        ],
        "forbidden_shortcut": (
            "Do not add tutors/recursion/hand-filter density unless the shell "
            "first preserves the topdeck and miracle cadence."
        ),
    },
    "approach_big_spell_conversion_preservation": {
        "contract_key": "approach_spell_volume_conversion_shell_contract",
        "shell_type": "micro_shell_before_full_generation",
        "must_preserve": [
            "Approach of the Second Sun",
            "Mizzix's Mastery",
            "Creative Technique",
            "high-impact spell volume",
        ],
        "target_metrics": [
            "lorehold_spell_cast",
            "miracle_cast",
            "approach_conversion",
            "topdeck_manipulation_activated",
        ],
        "forbidden_shortcut": (
            "Do not treat forced tutor access as proof unless the final spell "
            "volume and Approach conversion window also recover."
        ),
    },
    "pressure_survival_without_engine_cuts": {
        "contract_key": "pressure_survival_without_engine_cuts_contract",
        "shell_type": "diagnostic_only_until_engine_floor_passes",
        "must_preserve": [
            "topdeck_miracle_setup",
            "early_mana_floor",
            "protection_window",
            "Winota fast-pressure slice",
        ],
        "target_metrics": [
            "candidate_died_before_closing_window",
            "Winota record",
            "miracle_cast",
            "topdeck_manipulation_activated",
        ],
        "forbidden_shortcut": (
            "Do not add broad token or pressure payoffs after Young Pyromancer "
            "was observed only in losses without first restoring the engine floor."
        ),
    },
}


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


def as_dict(value: Any) -> dict[str, Any]:
    return dict(value) if isinstance(value, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def gap_counts(closing_trace: Mapping[str, Any]) -> dict[str, int]:
    return {str(k): as_int(v) for k, v in as_dict(summary(closing_trace).get("gap_counts")).items()}


def total_gap_pressure(hypothesis: Mapping[str, Any], gaps: Mapping[str, int]) -> int:
    return sum(as_int(gaps.get(str(tag))) for tag in as_list(hypothesis.get("target_gap_tags")))


def observed_evidence_score(hypothesis: Mapping[str, Any]) -> int:
    return len(as_list(hypothesis.get("evidence_events"))) * 4 + len(
        as_list(hypothesis.get("evidence_cards"))
    )


def hypothesis_blockers(
    *,
    key: str,
    shell_summary: Mapping[str, Any],
    cut_summary: Mapping[str, Any],
    miracle_flags: set[str],
) -> list[str]:
    blockers: list[str] = []
    if not shell_summary.get("can_run_next_battle_gate"):
        blockers.append("from_scratch_shell_gate_not_allowed")
    if as_int(cut_summary.get("named_seed_safe_cut_count")) == 0:
        blockers.append("no_named_seed_safe_cuts_in_current_607")
    for flag in sorted(BLOCKING_FLAGS_BY_HYPOTHESIS.get(key, set()) & miracle_flags):
        blockers.append(flag)
    if key == "pressure_survival_without_engine_cuts":
        blockers.append("pressure_route_must_follow_engine_floor_repair")
    return sorted(set(blockers))


def route_status(key: str, blockers: list[str]) -> tuple[str, str]:
    if not blockers:
        return (
            "closing_window_target_ready_for_shell_contract",
            "write_shell_contract_then_structure_matrix_before_any_battle",
        )
    if key == "preserve_topdeck_miracle_floor_micro_package":
        return (
            "primary_shell_contract_target_blocked_but_actionable_as_design",
            "write_miracle_access_first_shell_contract_no_battle",
        )
    if key == "approach_big_spell_conversion_preservation":
        return (
            "secondary_shell_contract_target_after_miracle_floor",
            "defer_until_miracle_access_contract_exists",
        )
    return (
        "diagnostic_only_after_engine_floor",
        "do_not_run_pressure_shell_until_miracle_access_floor_is_preserved",
    )


def build_hypothesis_row(
    *,
    hypothesis: Mapping[str, Any],
    gaps: Mapping[str, int],
    shell_summary: Mapping[str, Any],
    cut_summary: Mapping[str, Any],
    miracle_flags: set[str],
) -> dict[str, Any]:
    key = str(hypothesis.get("hypothesis_key") or "")
    blockers = hypothesis_blockers(
        key=key,
        shell_summary=shell_summary,
        cut_summary=cut_summary,
        miracle_flags=miracle_flags,
    )
    status, next_action = route_status(key, blockers)
    base_score = HYPOTHESIS_WEIGHTS.get(key, 40)
    gap_pressure = total_gap_pressure(hypothesis, gaps)
    evidence = observed_evidence_score(hypothesis)
    penalty = len(blockers) * 5
    return {
        "hypothesis_key": key,
        "status": status,
        "recommended_next_action": next_action,
        "priority_score": base_score + (gap_pressure * 4) + evidence - penalty,
        "target_gap_tags": as_list(hypothesis.get("target_gap_tags")),
        "target_gap_total": gap_pressure,
        "evidence_events": as_list(hypothesis.get("evidence_events")),
        "evidence_cards": as_list(hypothesis.get("evidence_cards")),
        "requirements": as_list(hypothesis.get("requirements")),
        "blockers": blockers,
        "shell_contract": SHELL_CONTRACTS.get(key, {}),
        "battle_allowed_now": False,
        "deck_mutation_allowed_now": False,
    }


def sort_key(row: Mapping[str, Any]) -> tuple[int, int, str]:
    status_rank = {
        "closing_window_target_ready_for_shell_contract": 0,
        "primary_shell_contract_target_blocked_but_actionable_as_design": 1,
        "secondary_shell_contract_target_after_miracle_floor": 2,
        "diagnostic_only_after_engine_floor": 3,
    }.get(str(row.get("status") or ""), 9)
    return (status_rank, -as_int(row.get("priority_score")), str(row.get("hypothesis_key") or ""))


def build_report(
    *,
    closing_trace: Mapping[str, Any],
    shell_failure: Mapping[str, Any],
    cut_miner: Mapping[str, Any],
    miracle_failure: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    closing_summary = summary(closing_trace)
    shell_summary = summary(shell_failure)
    cut_summary = summary(cut_miner)
    miracle_summary = summary(miracle_failure)
    gaps = gap_counts(closing_trace)
    miracle_flags = {str(flag) for flag in as_list(miracle_summary.get("blocking_failure_flags"))}
    rows = [
        build_hypothesis_row(
            hypothesis=row,
            gaps=gaps,
            shell_summary=shell_summary,
            cut_summary=cut_summary,
            miracle_flags=miracle_flags,
        )
        for row in as_list(closing_trace.get("hypothesis_queue"))
        if isinstance(row, Mapping)
    ]
    rows.sort(key=sort_key)
    top = rows[0] if rows else {}
    if top:
        decision_status = "closing_window_shell_target_selected_no_battle"
        next_action = top.get("recommended_next_action") or ""
    else:
        decision_status = "closing_window_shell_target_missing"
        next_action = "rerun_closing_window_trace_miner_with_game_results"

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_closing_window_next_shell_target_router",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "status": decision_status,
        "summary": {
            "decision_status": decision_status,
            "selected_hypothesis_key": top.get("hypothesis_key") or "",
            "selected_status": top.get("status") or "",
            "candidate_hypothesis_count": len(rows),
            "closing_window_comparison_count": as_int(closing_summary.get("comparison_count")),
            "avg_607_turn_advantage": closing_summary.get("avg_607_turn_advantage") or 0,
            "ready_micro_package_hypothesis_count": as_int(
                closing_summary.get("ready_micro_package_hypothesis_count")
            ),
            "from_scratch_can_run_next_battle_gate": bool(
                shell_summary.get("can_run_next_battle_gate")
            ),
            "from_scratch_promotable_shell_signal_count": as_int(
                shell_summary.get("promotable_shell_signal_count")
            ),
            "named_seed_safe_cut_count": as_int(cut_summary.get("named_seed_safe_cut_count")),
            "cut_shortage": as_int(cut_summary.get("cut_shortage")),
            "miracle_failure_flag_count": len(miracle_flags),
            "promotion_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "ready_deck_change_count": 0,
            "recommended_next_action": next_action,
        },
        "hypothesis_routes": rows,
        "selected_shell_target": top,
        "gap_counts": gaps,
        "top_strategic_deficits": closing_summary.get("top_strategic_deficits") or [],
        "top_anchor_card_deficits": closing_summary.get("top_anchor_card_deficits") or [],
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "Closing-window evidence identifies a miracle/topdeck floor repair target, "
                "but failed shells and zero seed-safe cuts block battle or mutation now."
            ),
            "next_actions": [
                "write_miracle_access_first_shell_contract_no_battle",
                "do_not_start_from_broad_from_scratch_shell",
                "do_not_test_pressure_conversion_until miracle/topdeck floor contract exists",
                "predeclare target metrics before any structure matrix",
                "keep deck_607 protected until same-seed equal battle gate proves replacement",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    lines = [
        "# Lorehold Closing-Window Next Shell Target Router",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Selected hypothesis: `{summary_row['selected_hypothesis_key']}`",
        f"- Selected status: `{summary_row['selected_status']}`",
        f"- Closing-window comparisons: `{summary_row['closing_window_comparison_count']}`",
        f"- Average 607 turn advantage: `{summary_row['avg_607_turn_advantage']}`",
        f"- Named seed-safe cuts: `{summary_row['named_seed_safe_cut_count']}`",
        f"- Natural battle gate allowed now: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Hypothesis Routes",
        "",
        "| Hypothesis | Status | Score | Target Gap Total | Blockers |",
        "| --- | --- | ---: | ---: | --- |",
    ]
    for row in as_list(payload.get("hypothesis_routes")):
        lines.append(
            "| {key} | `{status}` | {score} | {gaps} | {blockers} |".format(
                key=row.get("hypothesis_key") or "",
                status=row.get("status") or "",
                score=row.get("priority_score") or 0,
                gaps=row.get("target_gap_total") or 0,
                blockers=", ".join(as_list(row.get("blockers"))) or "-",
            )
        )
    lines.extend(["", "## Selected Shell Contract", ""])
    selected = as_dict(payload.get("selected_shell_target"))
    contract = as_dict(selected.get("shell_contract"))
    if contract:
        lines.append(f"- Contract key: `{contract.get('contract_key')}`")
        lines.append(f"- Shell type: `{contract.get('shell_type')}`")
        lines.append("- Must preserve:")
        for item in as_list(contract.get("must_preserve")):
            lines.append(f"  - `{item}`")
        lines.append("- Target metrics:")
        for item in as_list(contract.get("target_metrics")):
            lines.append(f"  - `{item}`")
        lines.append(f"- Forbidden shortcut: {contract.get('forbidden_shortcut')}")
    else:
        lines.append("- None.")
    lines.extend(["", "## Top Strategic Deficits", ""])
    for row in as_list(payload.get("top_strategic_deficits")):
        lines.append(f"- `{row.get('event')}`: `{row.get('delta_total')}`")
    lines.extend(["", "## Top Anchor Card Deficits", ""])
    for row in as_list(payload.get("top_anchor_card_deficits")):
        lines.append(f"- `{row.get('event')}`: `{row.get('delta_total')}`")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append("- next_actions:")
    for action in decision["next_actions"]:
        lines.append(f"  - {action}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--closing-trace", type=Path, default=DEFAULT_CLOSING_TRACE)
    parser.add_argument("--shell-failure", type=Path, default=DEFAULT_SHELL_FAILURE)
    parser.add_argument("--cut-miner", type=Path, default=DEFAULT_CUT_MINER)
    parser.add_argument("--miracle-failure", type=Path, default=DEFAULT_MIRACLE_FAILURE)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "closing_trace": args.closing_trace,
        "shell_failure": args.shell_failure,
        "cut_miner": args.cut_miner,
        "miracle_failure": args.miracle_failure,
    }
    payload = build_report(
        closing_trace=read_json(args.closing_trace),
        shell_failure=read_json(args.shell_failure),
        cut_miner=read_json(args.cut_miner),
        miracle_failure=read_json(args.miracle_failure),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
