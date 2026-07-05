#!/usr/bin/env python3
"""Resolve cut-pool readiness for the Lorehold pressure payoff micro-shell.

The pressure payoff contract proved that the add cards are locally known and
runtime-ready. This resolver answers the next blocker: whether the current 607
evidence contains enough seed-safe cuts to build a legal promotion candidate.
If it does not, it may still name a diagnostic-only tradeoff plan, but that plan
is explicitly ineligible for natural battle promotion.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence

import lorehold_pressure_safe_spell_payoff_contract as payoff_contract


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_CONTRACT = (
    REPORT_DIR / "lorehold_pressure_safe_spell_payoff_contract_20260705_current_relearn.json"
)
DEFAULT_SEED_SAFE = (
    REPORT_DIR / "lorehold_seed_safe_cut_hypothesis_20260704_role_tag_repair.json"
)
DEFAULT_STEM = "lorehold_pressure_safe_cut_pool_resolver_20260705_current_relearn"

HARD_EXCLUDE_LANES = {"commander", "mana_base", "early_mana", "protection"}
PROMOTION_BLOCKERS = {
    "commander_never_cut",
    "cut_is_early_mana_floor_support",
    "cut_is_protection_shell",
    "early_mana_floor_support",
    "mana_base_never_cut",
    "measured_high_cut_exposure",
    "never_cut_lane",
    "never_cut_or_mana_base",
    "prior_rejected_cut",
    "prior_rejected_cut_slot",
    "prior_rejected_signature",
    "protected_cut",
    "protection_shell",
}
DIAGNOSTIC_EXCLUDE_BLOCKERS = {
    "commander_never_cut",
    "cut_is_miracle_core_big_spell",
    "cut_is_early_mana_floor_support",
    "cut_is_protection_shell",
    "early_mana_floor_support",
    "mana_base_never_cut",
    "manual_review_cut_safety_block",
    "measured_high_cut_exposure",
    "miracle_or_finisher_core",
    "never_cut_lane",
    "never_cut_or_mana_base",
    "prior_rejected_cut",
    "prior_rejected_cut_slot",
    "prior_rejected_signature",
    "protected_cut",
    "protection_shell",
    "same_lane_only_requires_concrete_same_lane_add",
    "structural_dependency",
}
DIAGNOSTIC_ALLOWED_LANES = {"spell_velocity", "wincon", "removal", "contextual", "misc"}
DIAGNOSTIC_ALLOWED_STATUSES = {
    "diagnostic_candidate",
    "reviewable_evidence_gap",
    "low_exposure_noncore",
    "flex_review",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def primary_adds(contract: Mapping[str, Any]) -> list[str]:
    return [
        str(row.get("card_name") or "")
        for row in as_list(contract.get("primary_package_preflight"))
        if row.get("card_name")
    ]


def cut_name(row: Mapping[str, Any]) -> str:
    return str(row.get("card_name") or "")


def blockers(row: Mapping[str, Any]) -> set[str]:
    return {str(item) for item in as_list(row.get("blockers")) if str(item)}


def promotion_cut_blockers(row: Mapping[str, Any]) -> list[str]:
    reasons = set(blockers(row)) & PROMOTION_BLOCKERS
    lane = str(row.get("lane") or "")
    if lane in HARD_EXCLUDE_LANES:
        reasons.add(f"hard_excluded_lane:{lane}")
    if row.get("status") not in {"seed_safe_cut_ready", "ready"}:
        reasons.add("not_seed_safe_cut_ready")
    return sorted(reasons)


def diagnostic_cut_blockers(row: Mapping[str, Any]) -> list[str]:
    reasons = set(blockers(row)) & DIAGNOSTIC_EXCLUDE_BLOCKERS
    lane = str(row.get("lane") or "")
    if lane not in DIAGNOSTIC_ALLOWED_LANES:
        reasons.add(f"diagnostic_lane_excluded:{lane}")
    manual_status = str(row.get("manual_status") or "")
    status = str(row.get("status") or "")
    if (
        manual_status not in DIAGNOSTIC_ALLOWED_STATUSES
        and status not in DIAGNOSTIC_ALLOWED_STATUSES
    ):
        reasons.add(f"diagnostic_status_excluded:{manual_status or status or 'unknown'}")
    return sorted(reasons)


def score_diagnostic_cut(row: Mapping[str, Any]) -> tuple[int, int, int, str]:
    score = int(row.get("score") or 0)
    exposure = int(row.get("unique_exposure_count") or 0)
    direct = int(row.get("direct_event_count") or 0)
    return (-score, exposure, direct, cut_name(row))


def build_gate_ready_plan(
    seed_safe_rows: Sequence[Mapping[str, Any]],
    add_count: int,
) -> dict[str, Any]:
    ready: list[dict[str, Any]] = []
    blocked: list[dict[str, Any]] = []
    for row in seed_safe_rows:
        row_blockers = promotion_cut_blockers(row)
        payload = {
            "card_name": cut_name(row),
            "lane": row.get("lane") or "",
            "status": row.get("status") or "",
            "score": row.get("score"),
            "unique_exposure_count": row.get("unique_exposure_count"),
            "blockers": row_blockers,
        }
        if row_blockers:
            blocked.append(payload)
        else:
            ready.append(payload)
    selected = ready[:add_count]
    validation = payoff_contract.validate_cut_plan(
        [row["card_name"] for row in selected], add_count=add_count
    )
    plan_ready = len(selected) == add_count and validation["safe"]
    return {
        "status": "ready" if plan_ready else "not_ready",
        "selected_cuts": selected,
        "ready_cut_count": len(ready),
        "required_cut_count": add_count,
        "cut_plan_validation": validation,
        "blocked_seed_safe_rows": blocked[:20],
    }


def build_diagnostic_tradeoff_plan(
    cut_slots: Sequence[Mapping[str, Any]],
    add_count: int,
) -> dict[str, Any]:
    eligible: list[dict[str, Any]] = []
    blocked_counts: Counter[str] = Counter()
    for row in cut_slots:
        row_blockers = diagnostic_cut_blockers(row)
        for blocker in row_blockers:
            blocked_counts[blocker] += 1
        if row_blockers:
            continue
        eligible.append(
            {
                "card_name": cut_name(row),
                "lane": row.get("lane") or "",
                "manual_status": row.get("manual_status") or "",
                "status": row.get("status") or "",
                "score": row.get("score"),
                "unique_exposure_count": row.get("unique_exposure_count"),
                "direct_event_count": row.get("direct_event_count"),
                "diagnostic_reason": (
                    "Reviewable non-mana, non-protection pressure tradeoff slot; "
                    "diagnostic-only because active seed-safe evidence still says blocked."
                ),
            }
        )
    eligible.sort(key=score_diagnostic_cut)
    selected = eligible[:add_count]
    validation = payoff_contract.validate_cut_plan(
        [row["card_name"] for row in selected], add_count=add_count
    )
    complete = len(selected) == add_count and validation["safe"]
    return {
        "status": "diagnostic_plan_available" if complete else "not_available",
        "selected_cuts": selected,
        "required_cut_count": add_count,
        "eligible_diagnostic_cut_count": len(eligible),
        "cut_plan_validation": validation,
        "blocked_reason_counts": dict(sorted(blocked_counts.items())),
        "promotion_eligible": False,
        "natural_battle_gate_allowed": False,
    }


def build_report(
    *,
    contract_report: Mapping[str, Any],
    seed_safe_report: Mapping[str, Any],
    contract_path: Path,
    seed_safe_path: Path,
) -> dict[str, Any]:
    adds = primary_adds(contract_report)
    add_count = len(adds)
    gate_plan = build_gate_ready_plan(
        as_list(seed_safe_report.get("seed_safe_cut_candidates")),
        add_count=add_count,
    )
    diagnostic_plan = build_diagnostic_tradeoff_plan(
        as_list(seed_safe_report.get("cut_slots")),
        add_count=add_count,
    )
    gate_ready = gate_plan["status"] == "ready"
    diagnostic_available = diagnostic_plan["status"] == "diagnostic_plan_available"
    contract_summary = contract_report.get("summary") or {}
    contract_blocks_natural_gate = bool(
        contract_summary.get("natural_gate_blocked_by_hypothesis_queue")
    )
    natural_gate_ready_from_hypothesis_queue = int(
        contract_summary.get("natural_gate_ready_from_hypothesis_queue") or 0
    )
    if gate_ready:
        decision_status = "seed_safe_cut_plan_ready"
        next_action = "generate_legal_pressure_variant_and_structure_matrix"
    elif diagnostic_available:
        decision_status = "no_seed_safe_cut_plan_diagnostic_only_tradeoff_available"
        next_action = "stage_diagnostic_only_pressure_tradeoff_copy_if_learning_needs_it"
    else:
        decision_status = "no_seed_safe_cut_plan_no_diagnostic_tradeoff_current_607"
        next_action = "build_smaller_pressure_package_or_new_cut_safety_model_before_any_battle"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_pressure_safe_cut_pool_resolver",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "contract_report": rel(contract_path),
        "seed_safe_cut_report": rel(seed_safe_path),
        "current_champion": "deck_607",
        "summary": {
            "decision_status": decision_status,
            "primary_add_count": add_count,
            "gate_ready_cut_count": gate_plan["ready_cut_count"],
            "gate_ready_plan_complete": gate_ready,
            "diagnostic_tradeoff_plan_available": diagnostic_available,
            "ready_deck_change_count": 0,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "contract_natural_gate_ready_from_hypothesis_queue": natural_gate_ready_from_hypothesis_queue,
            "contract_blocks_natural_gate": contract_blocks_natural_gate,
            "recommended_next_action": next_action,
        },
        "primary_adds": adds,
        "contract_gate_context": {
            "contract_decision_status": contract_summary.get("decision_status") or "",
            "contract_diagnostic_status": contract_summary.get("diagnostic_contract_status") or "",
            "contract_diagnostic_only": bool(contract_summary.get("diagnostic_only")),
            "contract_natural_gate_ready_from_hypothesis_queue": natural_gate_ready_from_hypothesis_queue,
            "contract_blocks_natural_gate": contract_blocks_natural_gate,
            "primary_package_missing_from_hypothesis_queue": contract_summary.get(
                "primary_package_missing_from_hypothesis_queue"
            ),
            "primary_package_matched_in_hypothesis_queue": contract_summary.get(
                "primary_package_matched_in_hypothesis_queue"
            ),
        },
        "gate_ready_cut_plan": gate_plan,
        "diagnostic_tradeoff_cut_plan": diagnostic_plan,
        "hard_stop_rules": contract_report.get("hard_stop_rules") or [],
        "method_notes": [
            "Gate-ready cuts require the seed-safe report to provide four unblocked cut slots.",
            "Diagnostic tradeoff cuts are not promotion evidence; they require reviewable noncore cut status and cannot use structural dependencies or protected anchors.",
            "Deck 607 remains unchanged. Any diagnostic deck must be a separate copy and must not be promoted from forced or diagnostic evidence alone.",
            "If the pressure contract reports zero natural gate-ready hypotheses, this resolver cannot open a natural battle gate.",
        ],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Pressure-Safe Cut-Pool Resolver",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Contract report: `{payload['contract_report']}`",
        f"- Seed-safe cut report: `{payload['seed_safe_cut_report']}`",
        f"- Decision status: `{summary['decision_status']}`",
        f"- Gate-ready cut count: `{summary['gate_ready_cut_count']}`",
        f"- Gate-ready plan complete: `{str(summary['gate_ready_plan_complete']).lower()}`",
        f"- Diagnostic tradeoff plan available: `{str(summary['diagnostic_tradeoff_plan_available']).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary['natural_battle_gate_allowed_now']).lower()}`",
        f"- Contract natural gate-ready from hypothesis queue: `{summary['contract_natural_gate_ready_from_hypothesis_queue']}`",
        f"- Contract blocks natural gate: `{str(summary['contract_blocks_natural_gate']).lower()}`",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        "",
        "## Primary Adds",
        "",
    ]
    for name in payload.get("primary_adds") or []:
        lines.append(f"- {name}")
    lines.extend(["", "## Gate-Ready Cut Plan", ""])
    gate = payload["gate_ready_cut_plan"]
    if not gate.get("selected_cuts"):
        lines.append("- None.")
    else:
        for row in gate.get("selected_cuts") or []:
            lines.append(f"- `{row['card_name']}` lane `{row['lane']}`")
    lines.extend(["", "## Diagnostic-Only Tradeoff Plan", ""])
    diagnostic = payload["diagnostic_tradeoff_cut_plan"]
    if not diagnostic.get("selected_cuts"):
        lines.append("- None.")
    else:
        lines.extend(["| Cut | Lane | Score | Exposure | Reason |", "| --- | --- | ---: | ---: | --- |"])
        for row in diagnostic.get("selected_cuts") or []:
            lines.append(
                "| {card} | `{lane}` | {score} | {exposure} | {reason} |".format(
                    card=row.get("card_name") or "",
                    lane=row.get("lane") or "",
                    score=row.get("score") or 0,
                    exposure=row.get("unique_exposure_count") or 0,
                    reason=row.get("diagnostic_reason") or "",
                )
            )
    lines.extend(["", "## Diagnostic Blocker Counts", ""])
    lines.append(
        f"`{json.dumps(diagnostic.get('blocked_reason_counts') or {}, sort_keys=True)}`"
    )
    lines.extend(["", "## Contract Gate Context", ""])
    lines.append(
        f"`{json.dumps(payload.get('contract_gate_context') or {}, sort_keys=True)}`"
    )
    lines.extend(["", "## Hard Stop Rules", ""])
    if not payload.get("hard_stop_rules"):
        lines.append("- None loaded.")
    else:
        for item in payload.get("hard_stop_rules") or []:
            lines.append(
                "- `{rule}`: if {condition}, {action}.".format(
                    rule=item.get("rule") or "",
                    condition=item.get("condition") or "",
                    action=item.get("action") or "",
                )
            )
    lines.extend(["", "## Method Notes", ""])
    for note in payload.get("method_notes") or []:
        lines.append(f"- {note}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--seed-safe", type=Path, default=DEFAULT_SEED_SAFE)
    parser.add_argument("--stem", default=DEFAULT_STEM)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_report(
        contract_report=read_json(args.contract),
        seed_safe_report=read_json(args.seed_safe),
        contract_path=args.contract,
        seed_safe_path=args.seed_safe,
    )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
