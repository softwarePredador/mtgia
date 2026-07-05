#!/usr/bin/env python3
"""Synthesize pressure-window trace evidence for Young Pyromancer.

This read-only model asks whether the best pressure singleton has evidence that
it repairs a real Lorehold 607 failure mode. It does not build a deck, run a
battle, mutate SQLite, or write PostgreSQL.
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

DEFAULT_YOUNG_MODEL = (
    REPORT_DIR / "lorehold_young_pyromancer_singleton_cut_safety_model_20260705_current_relearn.json"
)
DEFAULT_SPELL_PRESSURE_TRACE = REPORT_DIR / "lorehold_spell_pressure_trace_miner_20260704_current.json"
DEFAULT_CLOSING_TRACE = REPORT_DIR / "lorehold_closing_window_trace_miner_20260704_role_tag_repair.json"
DEFAULT_MIRACLE_TRACE = REPORT_DIR / "lorehold_miracle_trace_failure_miner_20260704_current.json"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_young_pyromancer_pressure_window_trace_synthesis_20260705_current_relearn"
)

TARGET_CARD = "Young Pyromancer"

YOUNG_PYROMANCER_REPAIR_VECTOR = {
    "candidate_died_before_closing_window": "partial_theoretical_pressure_body",
    "candidate_lost_multiple_turns_before_607_finish": "partial_theoretical_pressure_body",
    "lorehold_spell_volume_deficit": "indirect_only_from_more_spell_payoffs",
    "miracle_cast_deficit": "does_not_repair",
    "topdeck_activation_deficit": "does_not_repair",
    "topdeck_engine_card_deficit": "does_not_repair",
    "upkeep_rummage_deficit": "does_not_repair",
    "607_mana_timing_anchor_deficit": "does_not_repair",
    "approach_conversion_missing": "does_not_repair",
    "static_cost_reduction_deficit": "does_not_repair",
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


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def as_dict(value: Any) -> dict[str, Any]:
    return dict(value) if isinstance(value, Mapping) else {}


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def young_seen_only_in_losses(spell_summary: Mapping[str, Any]) -> bool:
    cards_by_result = as_dict(spell_summary.get("pressure_cards_by_result"))
    loss_cards = {str(card) for card in as_list(cards_by_result.get("loss"))}
    win_cards = {str(card) for card in as_list(cards_by_result.get("win"))}
    return TARGET_CARD in loss_cards and TARGET_CARD not in win_cards


def pressure_win_trace_count(spell_summary: Mapping[str, Any]) -> int:
    return as_int(spell_summary.get("wins_with_pressure_card_events"))


def pressure_loss_trace_count(spell_summary: Mapping[str, Any]) -> int:
    return as_int(spell_summary.get("losses_with_pressure_card_events"))


def build_gap_rows(closing_summary: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    gap_counts = as_dict(closing_summary.get("gap_counts"))
    for gap, count in sorted(gap_counts.items(), key=lambda item: (-as_int(item[1]), item[0])):
        repair_status = YOUNG_PYROMANCER_REPAIR_VECTOR.get(str(gap), "unknown_not_targeted")
        if repair_status.startswith("partial"):
            actionability = "diagnostic_only_needs_causal_trace"
        elif repair_status == "indirect_only_from_more_spell_payoffs":
            actionability = "weak_indirect_not_gate_ready"
        elif repair_status == "does_not_repair":
            actionability = "do_not_use_young_pyromancer_for_this_gap"
        else:
            actionability = "not_a_young_pyromancer_gap"
        rows.append(
            {
                "gap": str(gap),
                "comparison_count": as_int(count),
                "young_pyromancer_repair_status": repair_status,
                "actionability": actionability,
            }
        )
    return rows


def trace_status(
    *,
    young_summary: Mapping[str, Any],
    spell_summary: Mapping[str, Any],
    miracle_summary: Mapping[str, Any],
    gap_rows: list[Mapping[str, Any]],
) -> tuple[str, str]:
    eligible_cut_count = as_int(young_summary.get("eligible_cut_count"))
    wins_with_pressure = pressure_win_trace_count(spell_summary)
    loss_only = young_seen_only_in_losses(spell_summary)
    failure_flags = {str(flag) for flag in as_list(miracle_summary.get("blocking_failure_flags"))}
    direct_repairable_gap_count = sum(
        1
        for row in gap_rows
        if str(row.get("young_pyromancer_repair_status") or "").startswith("partial")
    )

    if eligible_cut_count > 0 and wins_with_pressure > 0 and not failure_flags:
        return (
            "young_pyromancer_pressure_window_gate_candidate_requires_structure_matrix",
            "run_structure_matrix_then_equal_gate_with_direct_card_use_requirements",
        )
    if loss_only or wins_with_pressure == 0:
        return (
            "young_pyromancer_pressure_window_refuted_no_deck_action",
            "deprioritize_young_pyromancer_until_new_pressure_cut_or_forced_diagnostic",
        )
    if direct_repairable_gap_count > 0:
        return (
            "young_pyromancer_pressure_window_diagnostic_only",
            "run_non_deck_forced_diagnostic_only_if_it_preserves_607_engine_metrics",
        )
    return (
        "young_pyromancer_pressure_window_not_supported",
        "mine_other_pressure_or_conversion_routes_before_more_token_pressure",
    )


def build_model(
    *,
    young_model: Mapping[str, Any],
    spell_pressure_trace: Mapping[str, Any],
    closing_trace: Mapping[str, Any],
    miracle_trace: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    young_summary = summary(young_model)
    spell_summary = summary(spell_pressure_trace)
    closing_summary = summary(closing_trace)
    miracle_summary = summary(miracle_trace)
    gap_rows = build_gap_rows(closing_summary)
    status, next_action = trace_status(
        young_summary=young_summary,
        spell_summary=spell_summary,
        miracle_summary=miracle_summary,
        gap_rows=gap_rows,
    )
    loss_only = young_seen_only_in_losses(spell_summary)
    tested_cards = [str(card) for card in as_list(spell_summary.get("tested_pressure_cards"))]
    failure_modes = [str(item) for item in as_list(spell_summary.get("failure_modes"))]
    blocking_flags = [str(item) for item in as_list(miracle_summary.get("blocking_failure_flags"))]

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_young_pyromancer_pressure_window_trace_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "status": status,
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "summary": {
            "current_baseline": "deck_607",
            "target_card": TARGET_CARD,
            "target_singleton_status": young_model.get("status") or "",
            "target_package_status": young_summary.get("package_status") or "",
            "eligible_cut_count": as_int(young_summary.get("eligible_cut_count")),
            "seed_safe_cut_ready_count": as_int(young_summary.get("seed_safe_cut_ready_count")),
            "pressure_trace_status": spell_pressure_trace.get("status") or "",
            "tested_pressure_cards": tested_cards,
            "wins_with_pressure_card_events": pressure_win_trace_count(spell_summary),
            "losses_with_pressure_card_events": pressure_loss_trace_count(spell_summary),
            "young_pyromancer_seen_only_in_losses": loss_only,
            "closing_window_comparison_count": as_int(closing_summary.get("comparison_count")),
            "avg_607_turn_advantage": closing_summary.get("avg_607_turn_advantage") or 0,
            "closing_window_ready_hypotheses": as_int(
                closing_summary.get("ready_micro_package_hypothesis_count")
            ),
            "miracle_trace_failure_flag_count": len(blocking_flags),
            "promotion_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "ready_deck_change_count": 0,
            "recommended_next_action": next_action,
        },
        "pressure_trace_evidence": {
            "candidate_record": spell_summary.get("candidate_record") or {},
            "baseline_record": spell_summary.get("baseline_record") or {},
            "pressure_cards_by_result": spell_summary.get("pressure_cards_by_result") or {},
            "failure_modes": failure_modes,
            "decision": spell_pressure_trace.get("decision") or {},
        },
        "closing_window_gap_alignment": gap_rows,
        "top_strategic_deficits": closing_summary.get("top_strategic_deficits") or [],
        "top_anchor_card_deficits": closing_summary.get("top_anchor_card_deficits") or [],
        "miracle_trace_blockers": blocking_flags,
        "learning_rules": [
            {
                "rule": "loss_only_pressure_trace_is_not_card_proof",
                "effect": (
                    "Young Pyromancer appeared in pressure trace only on losses, so it "
                    "cannot be promoted or used as positive 607 evidence."
                ),
            },
            {
                "rule": "token_pressure_does_not_replace_engine_floor",
                "effect": (
                    "Most closing-window gaps are miracle, topdeck, spell-volume, "
                    "mana-timing, or Approach-conversion deficits that Young Pyromancer "
                    "does not directly repair."
                ),
            },
            {
                "rule": "diagnostic_is_not_promotion",
                "effect": (
                    "A forced Young Pyromancer diagnostic may teach whether tokens "
                    "buy time, but it must not create a deck-change claim without a "
                    "named safe cut, structure matrix, natural equal gate, and direct "
                    "card-use proof."
                ),
            },
        ],
        "diagnostic_contract": {
            "allowed_now": status == "young_pyromancer_pressure_window_diagnostic_only",
            "promotion_allowed": False,
            "natural_battle_allowed": False,
            "required_if_run": [
                "copied_db_or_non_deck_harness_only",
                "no_mutation_of_deck_607",
                "track_young_pyromancer_token_creation_and_damage_absorption",
                "track_miracle_cast_topdeck_activation_lorehold_spell_cast_floors",
                "stop_if_pressure_events_appear_only_in_losses_again",
            ],
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": False,
            "natural_battle_gate_allowed": False,
            "reason": (
                "Current trace evidence does not show Young Pyromancer repairing the "
                "607 pressure window. The only existing pressure-shell win was carried "
                "by the core topdeck/miracle engine, while Young Pyromancer was observed "
                "only in losses and still has no eligible cut."
            ),
            "next_actions": [
                "do_not_mutate_or_replace_deck_607",
                "do_not_run_a_natural_young_pyromancer_gate_now",
                "deprioritize_young_pyromancer_until_a_pressure_compatible_cut_exists",
                "if_learning_continues_on_tokens_use_non_deck_forced_diagnostic_only",
                "prioritize engine-preserving pressure or conversion routes over broad token-pressure shells",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    lines = [
        "# Lorehold Young Pyromancer Pressure-Window Trace Synthesis",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Target card: `{summary_row['target_card']}`",
        f"- Target singleton status: `{summary_row['target_singleton_status']}`",
        f"- Target package status: `{summary_row['target_package_status']}`",
        f"- Eligible cuts: `{summary_row['eligible_cut_count']}`",
        f"- Wins with pressure-card events: `{summary_row['wins_with_pressure_card_events']}`",
        f"- Losses with pressure-card events: `{summary_row['losses_with_pressure_card_events']}`",
        f"- Young Pyromancer seen only in losses: `{str(summary_row['young_pyromancer_seen_only_in_losses']).lower()}`",
        f"- Closing-window comparisons: `{summary_row['closing_window_comparison_count']}`",
        f"- Average 607 turn advantage: `{summary_row['avg_607_turn_advantage']}`",
        f"- Miracle trace failure flags: `{summary_row['miracle_trace_failure_flag_count']}`",
        f"- Natural battle gate allowed: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- Promotion allowed: `{str(summary_row['promotion_allowed_now']).lower()}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Gap Alignment",
        "",
        "| Gap | Count | Young Pyromancer Repair Status | Actionability |",
        "| --- | ---: | --- | --- |",
    ]
    for row in payload.get("closing_window_gap_alignment") or []:
        lines.append(
            "| {gap} | {count} | `{status}` | `{action}` |".format(
                gap=row.get("gap") or "",
                count=row.get("comparison_count") or 0,
                status=row.get("young_pyromancer_repair_status") or "",
                action=row.get("actionability") or "",
            )
        )
    lines.extend(["", "## Pressure Trace Evidence", ""])
    evidence = as_dict(payload.get("pressure_trace_evidence"))
    lines.append(f"- candidate_record: `{json.dumps(evidence.get('candidate_record') or {}, sort_keys=True)}`")
    lines.append(f"- baseline_record: `{json.dumps(evidence.get('baseline_record') or {}, sort_keys=True)}`")
    lines.append(
        f"- pressure_cards_by_result: `{json.dumps(evidence.get('pressure_cards_by_result') or {}, sort_keys=True)}`"
    )
    lines.append(f"- failure_modes: `{json.dumps(evidence.get('failure_modes') or [], sort_keys=True)}`")
    lines.extend(["", "## Learning Rules", ""])
    for row in payload.get("learning_rules") or []:
        lines.append(f"- `{row.get('rule')}`: {row.get('effect')}")
    lines.extend(["", "## Diagnostic Contract", ""])
    diagnostic = as_dict(payload.get("diagnostic_contract"))
    lines.append(f"- allowed_now: `{str(diagnostic.get('allowed_now')).lower()}`")
    lines.append(f"- promotion_allowed: `{str(diagnostic.get('promotion_allowed')).lower()}`")
    lines.append(f"- natural_battle_allowed: `{str(diagnostic.get('natural_battle_allowed')).lower()}`")
    lines.append("- required_if_run:")
    for item in as_list(diagnostic.get("required_if_run")):
        lines.append(f"  - {item}")
    lines.extend(["", "## Decision", ""])
    decision = as_dict(payload.get("decision"))
    lines.append(f"- Keep 607 protected: `{str(decision.get('keep_607_as_protected_baseline')).lower()}`")
    lines.append(f"- Natural battle gate allowed: `{str(decision.get('natural_battle_gate_allowed')).lower()}`")
    lines.append(f"- Promotion allowed: `{str(decision.get('promotion_allowed')).lower()}`")
    lines.append(f"- Reason: {decision.get('reason')}")
    lines.append("- Next actions:")
    for action in as_list(decision.get("next_actions")):
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
    parser.add_argument("--young-model", type=Path, default=DEFAULT_YOUNG_MODEL)
    parser.add_argument("--spell-pressure-trace", type=Path, default=DEFAULT_SPELL_PRESSURE_TRACE)
    parser.add_argument("--closing-trace", type=Path, default=DEFAULT_CLOSING_TRACE)
    parser.add_argument("--miracle-trace", type=Path, default=DEFAULT_MIRACLE_TRACE)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "young_model": args.young_model,
        "spell_pressure_trace": args.spell_pressure_trace,
        "closing_trace": args.closing_trace,
        "miracle_trace": args.miracle_trace,
    }
    payload = build_model(
        young_model=read_json(args.young_model),
        spell_pressure_trace=read_json(args.spell_pressure_trace),
        closing_trace=read_json(args.closing_trace),
        miracle_trace=read_json(args.miracle_trace),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
