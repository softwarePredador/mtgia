#!/usr/bin/env python3
"""Write the Lorehold miracle-access-first shell contract.

This read-only artifact turns the current closing-window route, miracle
preflight, failed-shell synthesis, and cut evidence into a concrete pre-deck
contract. It does not generate a deck, mutate deck 607, write PostgreSQL, or
open a natural battle gate.
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

DEFAULT_ROUTER = (
    REPORT_DIR
    / "lorehold_closing_window_next_shell_target_router_20260705_post_authorized_full_validation.json"
)
DEFAULT_PREFLIGHT = REPORT_DIR / "lorehold_miracle_access_first_preflight_20260704_current.json"
DEFAULT_CLOSING_TRACE = REPORT_DIR / "lorehold_closing_window_trace_miner_20260704_role_tag_repair.json"
DEFAULT_SHELL_FAILURE = (
    REPORT_DIR
    / "lorehold_from_scratch_shell_failure_synthesis_20260705_authorized_full_validation.json"
)
DEFAULT_CUT_MINER = (
    REPORT_DIR / "lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json"
)
DEFAULT_MIRACLE_FAILURE = REPORT_DIR / "lorehold_miracle_trace_failure_miner_20260704_current.json"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "lorehold_miracle_access_first_shell_contract_20260705_post_authorized_full_validation"
)

TARGET_HYPOTHESIS = "preserve_topdeck_miracle_floor_micro_package"
TARGET_CONTRACT = "miracle_access_first_shell_contract"

EXTERNAL_RESEARCH_REFRESH = [
    {
        "source": "Wizards Commander format",
        "url": "https://magic.wizards.com/en/formats/commander",
        "contract_use": (
            "Use official Commander shape, singleton, color identity, and bracket "
            "framing as legality and power-context gates only."
        ),
    },
    {
        "source": "EDHREC Lorehold commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "contract_use": (
            "Treat public Lorehold adoption and staple rates as evidence lanes. "
            "They can suggest cards, but cannot override 607 trace floors or cuts."
        ),
    },
    {
        "source": "EDHREC Miracles Every Turn with Lorehold",
        "url": (
            "https://edhrec.com/articles/"
            "miracles-every-turn-with-lorehold-the-historian-in-commander"
        ),
        "contract_use": (
            "Lorehold's opponent-upkeep rummage creates first-draw miracle windows; "
            "top-library control is therefore the engine floor."
        ),
    },
    {
        "source": "EDHREC Boros Miracles on a Budget",
        "url": "https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget",
        "contract_use": (
            "Instant/sorcery density, topdeck manipulation, protection, mana for "
            "opponents' turns, and big spell conversion are the relevant lanes."
        ),
    },
    {
        "source": "Commander Spellbook",
        "url": "https://commanderspellbook.com/",
        "contract_use": (
            "Use combo discovery as package evidence only; it is not full-deck "
            "balance, cut safety, or ManaLoom runtime proof."
        ),
    },
]

INHERITED_PROTECTED_ANCHORS = [
    "Lorehold, the Historian",
    "Sensei's Divining Top",
    "Scroll Rack",
    "Bender's Waterskin",
    "Victory Chimes",
    "Approach of the Second Sun",
    "Mizzix's Mastery",
    "Land Tax",
    "Library of Leng",
    "The Mind Stone",
]

BLOCKED_SHORTCUTS = [
    {
        "shortcut_key": "pressure_conversion_blocked_until_miracle_floor",
        "reason": (
            "Pressure packages such as Guttersnipe or Storm-Kiln cannot be tested "
            "as the next shell until miracle/topdeck floors are preserved."
        ),
    },
    {
        "shortcut_key": "forced_access_not_promotion_evidence",
        "reason": (
            "Forced access can prove visibility or use, but prior forced-access "
            "diagnostics still failed to convert into wins."
        ),
    },
    {
        "shortcut_key": "global_staple_not_cross_lane_cut_proof",
        "reason": (
            "Mana Vault, The One Ring, and similar staples stay hypotheses unless "
            "same-lane cut proof and equal battle evidence beat protected 607."
        ),
    },
    {
        "shortcut_key": "broad_from_scratch_shell_blocked",
        "reason": (
            "The current from-scratch shell synthesis shows broad shells below 607 "
            "and requires a predeclared trace target before another shell."
        ),
    },
]

EVENT_FLOOR_REQUIREMENTS = [
    {
        "requirement_key": "miracle_cast_floor",
        "metric": "miracle_cast",
        "measurement": "meet_or_exceed_current_607_same_seed_floor",
    },
    {
        "requirement_key": "topdeck_manipulation_floor",
        "metric": "topdeck_manipulation_activated",
        "measurement": "meet_or_exceed_current_607_same_seed_floor",
    },
    {
        "requirement_key": "lorehold_spell_volume_floor",
        "metric": "lorehold_spell_cast",
        "measurement": "meet_or_exceed_current_607_same_seed_floor",
    },
    {
        "requirement_key": "upkeep_rummage_floor",
        "metric": "lorehold_upkeep_rummage",
        "measurement": "meet_or_exceed_current_607_same_seed_floor",
    },
    {
        "requirement_key": "static_cost_reduction_floor",
        "metric": "static_cost_reduction_total",
        "measurement": "no_regression_against_607_closing_window_trace",
    },
    {
        "requirement_key": "approach_conversion_floor",
        "metric": "approach_conversion",
        "measurement": "no_missing_approach_conversion_in_candidate_closing_windows",
    },
]

STRUCTURE_MATRIX_ENTRY_REQUIREMENTS = [
    "start from a micro-shell structure matrix, not a broad full-deck rewrite",
    "state adds, same-lane cuts, and protected anchors before materializing any list",
    "keep legal Commander shape, color identity, singleton, and unresolved count gates separate",
    "preserve topdeck, miracle, upkeep-rummage, spell-volume, and cost-reduction floors",
    "preserve natural access to Sensei's Divining Top and Scroll Rack",
    "preserve Bender's Waterskin and Victory Chimes unless same-lane evidence beats 607",
    "carry Approach of the Second Sun conversion as a protected finisher floor",
    "reject pressure, tutor, recursion, or generic value density if the miracle floor regresses",
]

BATTLE_GATE_REQUIREMENTS = [
    "structure_matrix_passes_before_any_battle",
    "copied_deck_or_lab_candidate_only_until_promotion_gate_passes",
    "same_seed_same_opponent_matrix_against_current_deck_607",
    "direct_drawn_cast_used_trace_for_added_cards_and_anchors",
    "candidate_ties_or_beats_607_aggregate",
    "Winota_fast_pressure_slice_ties_or_improves",
    "closing_window_trace_shows_miracle_topdeck_plan_executed",
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


def unique_strings(values: list[Any]) -> list[str]:
    return sorted({str(value) for value in values if str(value)})


def selected_target(router: Mapping[str, Any]) -> dict[str, Any]:
    target = as_dict(router.get("selected_shell_target"))
    if target:
        return target
    for row in as_list(router.get("hypothesis_routes")):
        if isinstance(row, Mapping) and row.get("hypothesis_key") == TARGET_HYPOTHESIS:
            return dict(row)
    return {}


def selected_contract(target: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(target.get("shell_contract"))


def router_ready_for_contract(router_summary: Mapping[str, Any], target: Mapping[str, Any]) -> bool:
    return bool(router_summary.get("selected_hypothesis_key") == TARGET_HYPOTHESIS and target)


def aggregate_blockers(
    *,
    target: Mapping[str, Any],
    preflight: Mapping[str, Any],
    shell_failure: Mapping[str, Any],
    cut_miner: Mapping[str, Any],
    miracle_failure: Mapping[str, Any],
) -> list[str]:
    blockers: list[Any] = []
    blockers.extend(as_list(target.get("blockers")))
    blockers.extend(as_list(summary(preflight).get("blocking_reasons")))
    blockers.extend(as_list(summary(shell_failure).get("blockers")))
    blockers.extend(as_list(summary(miracle_failure).get("blocking_failure_flags")))
    cut_summary = summary(cut_miner)
    if as_int(cut_summary.get("named_seed_safe_cut_count")) == 0:
        blockers.append("no_named_seed_safe_cuts_in_current_607")
    if not summary(shell_failure).get("can_run_next_battle_gate"):
        blockers.append("from_scratch_shell_gate_not_allowed")
    return unique_strings(blockers)


def decision_status(
    *,
    router_summary: Mapping[str, Any],
    target: Mapping[str, Any],
    contract: Mapping[str, Any],
    aggregate_blocker_count: int,
    preflight_summary: Mapping[str, Any],
) -> tuple[str, str, bool]:
    if not target:
        return (
            "miracle_access_contract_blocked_missing_router_target",
            "rerun_closing_window_next_shell_target_router",
            False,
        )
    if router_summary.get("selected_hypothesis_key") != TARGET_HYPOTHESIS:
        return (
            "miracle_access_contract_blocked_wrong_router_target",
            "rerun_router_or_write_contract_for_selected_target",
            False,
        )
    if contract.get("contract_key") != TARGET_CONTRACT:
        return (
            "miracle_access_contract_blocked_missing_contract_key",
            "rebuild_router_with_miracle_access_contract_metadata",
            False,
        )
    if aggregate_blocker_count == 0 and as_int(preflight_summary.get("gate_ready_now_count")) > 0:
        return (
            "miracle_access_first_contract_ready_for_structure_matrix_no_battle",
            "design_miracle_access_structure_matrix_before_battle",
            True,
        )
    return (
        "miracle_access_first_contract_written_no_battle_blocked_before_structure_matrix",
        "design_micro_shell_structure_matrix_contract_no_battle",
        True,
    )


def protected_anchors(contract: Mapping[str, Any], preflight: Mapping[str, Any]) -> list[str]:
    inherited = list(INHERITED_PROTECTED_ANCHORS)
    inherited.extend(as_list(contract.get("must_preserve")))
    inherited.extend(as_list(as_dict(preflight.get("contract")).get("protected_anchors_not_negotiable_without_proof")))
    return unique_strings(inherited)


def build_report(
    *,
    router: Mapping[str, Any],
    preflight: Mapping[str, Any],
    closing_trace: Mapping[str, Any],
    shell_failure: Mapping[str, Any],
    cut_miner: Mapping[str, Any],
    miracle_failure: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    router_summary = summary(router)
    preflight_summary = summary(preflight)
    closing_summary = summary(closing_trace)
    shell_summary = summary(shell_failure)
    cut_summary = summary(cut_miner)
    miracle_summary = summary(miracle_failure)
    target = selected_target(router)
    contract = selected_contract(target)
    blockers = aggregate_blockers(
        target=target,
        preflight=preflight,
        shell_failure=shell_failure,
        cut_miner=cut_miner,
        miracle_failure=miracle_failure,
    )
    status, next_action, contract_written = decision_status(
        router_summary=router_summary,
        target=target,
        contract=contract,
        aggregate_blocker_count=len(blockers),
        preflight_summary=preflight_summary,
    )
    structure_contract_allowed = contract_written
    structure_matrix_allowed = status == "miracle_access_first_contract_ready_for_structure_matrix_no_battle"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_miracle_access_first_shell_contract",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "external_research_refresh": EXTERNAL_RESEARCH_REFRESH,
        "status": status,
        "summary": {
            "decision_status": status,
            "selected_hypothesis_key": router_summary.get("selected_hypothesis_key") or "",
            "selected_contract_key": contract.get("contract_key") or "",
            "contract_written": contract_written,
            "structure_matrix_contract_allowed_now": structure_contract_allowed,
            "structure_matrix_allowed_now": structure_matrix_allowed,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "ready_deck_change_count": 0,
            "closing_window_comparison_count": as_int(closing_summary.get("comparison_count")),
            "avg_607_turn_advantage": closing_summary.get("avg_607_turn_advantage") or 0,
            "preflight_candidate_count": as_int(preflight_summary.get("candidate_count")),
            "preflight_gate_ready_now_count": as_int(preflight_summary.get("gate_ready_now_count")),
            "from_scratch_promotable_shell_signal_count": as_int(
                shell_summary.get("promotable_shell_signal_count")
            ),
            "from_scratch_can_run_next_battle_gate": bool(
                shell_summary.get("can_run_next_battle_gate")
            ),
            "named_seed_safe_cut_count": as_int(cut_summary.get("named_seed_safe_cut_count")),
            "cut_shortage": as_int(cut_summary.get("cut_shortage")),
            "miracle_failure_flag_count": len(as_list(miracle_summary.get("blocking_failure_flags"))),
            "aggregate_blocker_count": len(blockers),
            "recommended_next_action": next_action,
        },
        "contract": {
            "contract_key": TARGET_CONTRACT,
            "shell_type": contract.get("shell_type") or "micro_shell_before_full_generation",
            "strategic_goal": (
                "Build only a miracle/topdeck access micro-shell that preserves the "
                "current 607 engine floors before any pressure, tutor, recursion, "
                "or generic value route can be tested."
            ),
            "protected_anchors": protected_anchors(contract, preflight),
            "event_floor_requirements": EVENT_FLOOR_REQUIREMENTS,
            "target_metrics_from_router": as_list(contract.get("target_metrics")),
            "strategic_floors_from_607": preflight_summary.get("strategic_floors_from_607") or {},
            "anchor_access_floors_from_607": preflight_summary.get("anchor_access_floors_from_607") or {},
            "closing_window_gap_counts": closing_summary.get("gap_counts") or {},
            "top_strategic_deficits": closing_summary.get("top_strategic_deficits") or [],
            "top_anchor_card_deficits": closing_summary.get("top_anchor_card_deficits") or [],
            "structure_matrix_entry_requirements": STRUCTURE_MATRIX_ENTRY_REQUIREMENTS,
            "battle_gate_requirements": BATTLE_GATE_REQUIREMENTS,
            "blocked_shortcuts": BLOCKED_SHORTCUTS,
            "forbidden_shortcut_from_router": contract.get("forbidden_shortcut") or "",
        },
        "source_evidence": {
            "router_summary": router_summary,
            "selected_shell_target": target,
            "preflight_summary": preflight_summary,
            "shell_failure_summary": shell_summary,
            "cut_miner_summary": cut_summary,
            "miracle_failure_summary": miracle_summary,
            "aggregate_blockers": blockers,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "structure_matrix_contract_allowed_now": structure_contract_allowed,
            "structure_matrix_allowed_now": structure_matrix_allowed,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "The next learning target is the miracle/topdeck access floor, but "
                "current evidence still has blocker signals and no ready deck change."
            )
            if blockers
            else (
                "The miracle/topdeck access contract is clean enough to design a "
                "structure matrix, but battle and promotion remain closed."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_write_postgresql_or_sqlite",
                "write_or_run_structure_matrix_only_after this contract",
                "preserve protected anchors unless same-lane proof beats 607",
                "run equal battle gate only after structure matrix and trace floors pass",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    contract = payload["contract"]
    lines = [
        "# Lorehold Miracle Access First Shell Contract",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Selected hypothesis: `{summary_row['selected_hypothesis_key']}`",
        f"- Selected contract: `{summary_row['selected_contract_key']}`",
        f"- Structure matrix contract allowed now: `{str(summary_row['structure_matrix_contract_allowed_now']).lower()}`",
        f"- Structure matrix allowed now: `{str(summary_row['structure_matrix_allowed_now']).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- Promotion allowed now: `{str(summary_row['promotion_allowed_now']).lower()}`",
        f"- Named seed-safe cuts: `{summary_row['named_seed_safe_cut_count']}`",
        f"- Aggregate blockers: `{summary_row['aggregate_blocker_count']}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## External Research Refresh", ""])
    for item in as_list(payload.get("external_research_refresh")):
        lines.append(f"- {item['source']}: {item['url']}")
        lines.append(f"  - {item['contract_use']}")
    lines.extend(["", "## Protected Anchors", ""])
    for item in as_list(contract.get("protected_anchors")):
        lines.append(f"- `{item}`")
    lines.extend(["", "## Event Floor Requirements", ""])
    for item in as_list(contract.get("event_floor_requirements")):
        lines.append(
            f"- `{item.get('requirement_key')}` uses `{item.get('metric')}`: "
            f"{item.get('measurement')}"
        )
    lines.extend(["", "## Current 607 Floors", ""])
    lines.append(
        "- strategic_floors_from_607: "
        f"`{json.dumps(contract.get('strategic_floors_from_607') or {}, sort_keys=True)}`"
    )
    lines.append(
        "- anchor_access_floors_from_607: "
        f"`{json.dumps(contract.get('anchor_access_floors_from_607') or {}, sort_keys=True)}`"
    )
    lines.extend(["", "## Blocked Shortcuts", ""])
    for item in as_list(contract.get("blocked_shortcuts")):
        lines.append(f"- `{item.get('shortcut_key')}`: {item.get('reason')}")
    lines.extend(["", "## Structure Matrix Entry Requirements", ""])
    for item in as_list(contract.get("structure_matrix_entry_requirements")):
        lines.append(f"- {item}")
    lines.extend(["", "## Battle Gate Requirements", ""])
    for item in as_list(contract.get("battle_gate_requirements")):
        lines.append(f"- `{item}`")
    lines.extend(["", "## Aggregate Blockers", ""])
    blockers = as_list(as_dict(payload.get("source_evidence")).get("aggregate_blockers"))
    if blockers:
        for blocker in blockers:
            lines.append(f"- `{blocker}`")
    else:
        lines.append("- None.")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- structure_matrix_allowed_now: `{str(decision['structure_matrix_allowed_now']).lower()}`")
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
    parser.add_argument("--router", type=Path, default=DEFAULT_ROUTER)
    parser.add_argument("--preflight", type=Path, default=DEFAULT_PREFLIGHT)
    parser.add_argument("--closing-trace", type=Path, default=DEFAULT_CLOSING_TRACE)
    parser.add_argument("--shell-failure", type=Path, default=DEFAULT_SHELL_FAILURE)
    parser.add_argument("--cut-miner", type=Path, default=DEFAULT_CUT_MINER)
    parser.add_argument("--miracle-failure", type=Path, default=DEFAULT_MIRACLE_FAILURE)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "router": args.router,
        "preflight": args.preflight,
        "closing_trace": args.closing_trace,
        "shell_failure": args.shell_failure,
        "cut_miner": args.cut_miner,
        "miracle_failure": args.miracle_failure,
    }
    payload = build_report(
        router=read_json(args.router),
        preflight=read_json(args.preflight),
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
