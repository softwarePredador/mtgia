#!/usr/bin/env python3
"""Evaluate whether Young Pyromancer has a legal singleton cut path for 607.

This is a read-only deckbuilding-learning artifact. It consumes the current
pressure package router plus the 607 cut evidence and answers a narrow question:
can the best pressure singleton become a real add/cut package now?
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

DEFAULT_PACKAGE_ROUTER = (
    REPORT_DIR / "lorehold_pressure_package_size_router_20260705_current_relearn.json"
)
DEFAULT_PRESSURE_CONTRACT = (
    REPORT_DIR / "lorehold_pressure_safe_spell_payoff_contract_20260705_current_relearn.json"
)
DEFAULT_SEED_SAFE = REPORT_DIR / "lorehold_seed_safe_cut_hypothesis_20260704_role_tag_repair.json"
DEFAULT_TRACE_EXPANDER = (
    REPORT_DIR / "lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_young_pyromancer_singleton_cut_safety_model_20260705_current_relearn"
)

TARGET_CARD = "Young Pyromancer"
TARGET_PACKAGE_KEY = "pressure_1_card_young_pyromancer"

YOUNG_PYROMANCER_COMPATIBLE_LANES = {
    "creature",
    "contextual",
    "pressure_absorber",
    "spell_chain_conversion",
    "token_pressure",
}
SOFT_DIAGNOSTIC_LANES = {
    "graveyard_recursion",
    "hand_filter",
    "misc",
}
NEVER_CUT_LANES = {
    "commander",
    "mana_base",
}
HARD_ANCHOR_BLOCKERS = {
    "commander_never_cut",
    "cut_is_early_mana_floor_support",
    "cut_is_miracle_core_big_spell",
    "cut_is_protection_shell",
    "early_mana_floor_support",
    "mana_base_never_cut",
    "measured_high_cut_exposure",
    "miracle_or_finisher_core",
    "never_cut_lane",
    "never_cut_or_mana_base",
    "prior_rejected_cut",
    "prior_rejected_cut_slot",
    "prior_rejected_signature",
    "protected_cut",
    "protection_shell",
    "structural_dependency",
}

EXTERNAL_SUPPORT = [
    {
        "source": "EDHREC Lorehold core spellslinger",
        "url": "https://edhrec.com/commanders/lorehold-the-historian/core/spellslinger",
        "learning": (
            "Current public Lorehold tags keep the deck in topdeck, spellslinger, "
            "discard, and reanimator lanes; a token-pressure add must not dilute "
            "those axes."
        ),
        "model_effect": "preserve_lorehold_core_axes_before_young_pyromancer_gate",
    },
    {
        "source": "GameTyrant Lorehold deck tech",
        "url": "https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech",
        "learning": (
            "Young Pyromancer and Monastery Mentor are pressure-body conversion "
            "payoffs for spell chains, not generic replacements for ramp, removal, "
            "or miracle engines."
        ),
        "model_effect": "young_pyromancer_requires_pressure_body_cut_or_package_proof",
    },
    {
        "source": "Draftsim spellslinger commander overview",
        "url": "https://draftsim.com/best-spellslinger-commanders/",
        "learning": (
            "Spellslinger decks can be token, burn, or storm oriented. ManaLoom must "
            "choose the pressure-token branch only when the commander shell supports "
            "it without losing its existing plan."
        ),
        "model_effect": "token_pressure_is_a_branch_not_automatic_lorehold_truth",
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


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def list_of_maps(value: Any) -> list[dict[str, Any]]:
    return [dict(row) for row in as_list(value) if isinstance(row, Mapping)]


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    value = payload.get("summary")
    return dict(value) if isinstance(value, Mapping) else {}


def blocker_set(row: Mapping[str, Any]) -> set[str]:
    blockers: set[str] = set()
    for key in (
        "blockers",
        "all_blockers",
        "absolute_blockers",
        "evidence_gap_blockers",
        "unknown_blockers",
    ):
        blockers.update(str(item) for item in as_list(row.get(key)) if item)
    return blockers


def find_target_contract_row(contract_report: Mapping[str, Any]) -> dict[str, Any]:
    for row in list_of_maps(contract_report.get("primary_package_preflight")):
        if row.get("card_name") == TARGET_CARD:
            return row
    return {}


def find_target_package(package_router: Mapping[str, Any]) -> dict[str, Any]:
    for row in list_of_maps(package_router.get("packages")):
        if row.get("package_key") == TARGET_PACKAGE_KEY:
            return row
    return {}


def seed_safe_names(seed_safe_report: Mapping[str, Any]) -> set[str]:
    return {
        str(row["card_name"])
        for row in list_of_maps(seed_safe_report.get("seed_safe_cut_candidates"))
        if row.get("card_name")
    }


def collect_cut_rows(
    seed_safe_report: Mapping[str, Any], trace_expander: Mapping[str, Any]
) -> list[dict[str, Any]]:
    merged: dict[str, dict[str, Any]] = {}
    for source_name, report in (
        ("seed_safe", seed_safe_report),
        ("trace_expander", trace_expander),
    ):
        for key in (
            "seed_safe_cut_candidates",
            "same_lane_only_cut_slots",
            "cut_slots",
            "all_cut_slots",
            "same_lane_hard_blocked_queue",
            "hard_blocked_queue",
            "reviewable_evidence_gap_queue",
            "seed_safe_cut_queue",
        ):
            for row in list_of_maps(report.get(key)):
                name = row.get("card_name")
                if not name:
                    continue
                current = merged.setdefault(str(name), {"card_name": str(name), "source_sections": []})
                current.update(row)
                current.setdefault("source_sections", []).append(f"{source_name}.{key}")
    return list(merged.values())


def lane_group(lane: str) -> str:
    if lane in YOUNG_PYROMANCER_COMPATIBLE_LANES:
        return "pressure_compatible"
    if lane in SOFT_DIAGNOSTIC_LANES:
        return "soft_diagnostic_only"
    if lane in NEVER_CUT_LANES:
        return "never_cut_lane"
    return "lane_mismatch"


def classify_cut_row(row: Mapping[str, Any], seed_safe: set[str]) -> str:
    name = str(row.get("card_name") or "")
    lane = str(row.get("lane") or "")
    blockers = blocker_set(row)
    hard_blockers = blockers & HARD_ANCHOR_BLOCKERS
    group = lane_group(lane)
    if name in seed_safe and group == "pressure_compatible" and not hard_blockers:
        return "gate_candidate_requires_structure_matrix"
    if group == "never_cut_lane":
        return "blocked_never_cut_lane"
    if hard_blockers:
        if group == "pressure_compatible":
            return "blocked_pressure_lane_hard_anchor"
        return "blocked_hard_anchor_or_prior_reject"
    if group == "pressure_compatible":
        return "pressure_lane_evidence_gap_not_seed_safe"
    if group == "soft_diagnostic_only":
        return "diagnostic_only_wrong_cut_lane_for_promotion"
    return "blocked_lane_mismatch_for_young_pyromancer"


def row_priority(row: Mapping[str, Any]) -> tuple[int, int, int, str]:
    status_rank = {
        "gate_candidate_requires_structure_matrix": 0,
        "pressure_lane_evidence_gap_not_seed_safe": 1,
        "blocked_pressure_lane_hard_anchor": 2,
        "diagnostic_only_wrong_cut_lane_for_promotion": 3,
        "blocked_hard_anchor_or_prior_reject": 4,
        "blocked_lane_mismatch_for_young_pyromancer": 5,
        "blocked_never_cut_lane": 6,
    }.get(str(row.get("young_pyromancer_cut_status") or ""), 9)
    exposure = as_int(row.get("unique_exposure_count"))
    event_count = as_int(row.get("direct_event_count"))
    return (status_rank, exposure, event_count, str(row.get("card_name") or ""))


def evaluate_cut_rows(
    seed_safe_report: Mapping[str, Any], trace_expander: Mapping[str, Any]
) -> list[dict[str, Any]]:
    seed_safe = seed_safe_names(seed_safe_report)
    rows: list[dict[str, Any]] = []
    for raw in collect_cut_rows(seed_safe_report, trace_expander):
        lane = str(raw.get("lane") or "")
        blockers = sorted(blocker_set(raw))
        status = classify_cut_row(raw, seed_safe)
        rows.append(
            {
                "card_name": str(raw.get("card_name") or ""),
                "lane": lane,
                "lane_group": lane_group(lane),
                "manual_status": raw.get("manual_status") or "",
                "current_status": raw.get("status") or "",
                "young_pyromancer_cut_status": status,
                "seed_safe_candidate": str(raw.get("card_name") or "") in seed_safe,
                "unique_exposure_count": as_int(raw.get("unique_exposure_count")),
                "direct_event_count": as_int(raw.get("direct_event_count")),
                "blockers": blockers,
                "source_sections": as_list(raw.get("source_sections")),
                "recommended_action": recommended_cut_action(status),
            }
        )
    rows.sort(key=row_priority)
    return rows


def recommended_cut_action(status: str) -> str:
    if status == "gate_candidate_requires_structure_matrix":
        return "run_structure_matrix_before_any_battle"
    if status == "pressure_lane_evidence_gap_not_seed_safe":
        return "mine_trace_or_manual_review_before_deck_variant"
    if status == "blocked_pressure_lane_hard_anchor":
        return "do_not_cut_until_new_evidence_removes_anchor_blocker"
    if status == "diagnostic_only_wrong_cut_lane_for_promotion":
        return "forced_diagnostic_only_not_promotion"
    return "do_not_use_as_young_pyromancer_cut_under_current_contract"


def build_model(
    *,
    package_router: Mapping[str, Any],
    pressure_contract: Mapping[str, Any],
    seed_safe_report: Mapping[str, Any],
    trace_expander: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    router_summary = summary(package_router)
    seed_summary = summary(seed_safe_report)
    trace_summary = summary(trace_expander)
    target_contract = find_target_contract_row(pressure_contract)
    target_package = find_target_package(package_router)
    cut_rows = evaluate_cut_rows(seed_safe_report, trace_expander)
    eligible = [
        row
        for row in cut_rows
        if row["young_pyromancer_cut_status"] == "gate_candidate_requires_structure_matrix"
    ]
    evidence_gaps = [
        row
        for row in cut_rows
        if row["young_pyromancer_cut_status"] == "pressure_lane_evidence_gap_not_seed_safe"
    ]
    pressure_hard_blocked = [
        row
        for row in cut_rows
        if row["young_pyromancer_cut_status"] == "blocked_pressure_lane_hard_anchor"
    ]
    if eligible and target_package.get("status") != "blocked_local_preflight":
        status = "young_pyromancer_singleton_gate_candidate_requires_structure_matrix"
        next_action = "run_structure_matrix_for_named_young_pyromancer_cut_before_any_battle"
    elif evidence_gaps:
        status = "young_pyromancer_singleton_cut_evidence_gap_not_gate_ready"
        next_action = "mine_pressure_lane_trace_evidence_before_any_variant"
    else:
        status = "young_pyromancer_singleton_no_cut_keep_607"
        next_action = "mine_pressure_lane_cut_evidence_or_non_deck_forced_diagnostic"

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_young_pyromancer_singleton_cut_safety_model",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "status": status,
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "target_card": {
            "card_name": TARGET_CARD,
            "package_key": TARGET_PACKAGE_KEY,
            "role": target_contract.get("role") or "",
            "cmc": target_contract.get("cmc"),
            "type_line": target_contract.get("type_line") or "",
            "preflight_status": target_contract.get("preflight_status") or "",
            "commander_legal_status": target_contract.get("commander_legal_status") or "",
            "already_in_607": bool(target_contract.get("already_in_607")),
            "verified_auto_battle_rule_count": as_int(
                target_contract.get("verified_auto_battle_rule_count")
            ),
            "hypothesis_queue_overlay": target_contract.get("hypothesis_queue_overlay") or {},
            "package_status": target_package.get("status") or "",
            "package_blockers": as_list(target_package.get("blockers")),
            "value_test": target_contract.get("value_test") or "",
        },
        "summary": {
            "current_baseline": "deck_607",
            "target_card": TARGET_CARD,
            "package_status": target_package.get("status") or "",
            "package_gate_ready": bool(target_package.get("gate_ready")),
            "package_score": as_int(target_package.get("score")),
            "evaluated_cut_slot_count": len(cut_rows),
            "seed_safe_cut_ready_count": as_int(seed_summary.get("seed_safe_cut_ready_count")),
            "trace_seed_safe_ready_count": as_int(trace_summary.get("seed_safe_ready_count")),
            "reviewable_evidence_gap_count": as_int(
                trace_summary.get("reviewable_evidence_gap_count")
            ),
            "hard_blocked_count": as_int(trace_summary.get("hard_blocked_count")),
            "eligible_cut_count": len(eligible),
            "pressure_lane_evidence_gap_count": len(evidence_gaps),
            "pressure_lane_hard_blocked_count": len(pressure_hard_blocked),
            "ready_deck_change_count": 0,
            "promotion_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "recommended_next_action": next_action,
        },
        "eligible_cut_candidates": eligible,
        "pressure_lane_evidence_gaps": evidence_gaps,
        "pressure_lane_hard_blocked": pressure_hard_blocked,
        "top_cut_safety_rows": cut_rows[:24],
        "external_support": EXTERNAL_SUPPORT,
        "method_notes": [
            "This model does not create, mutate, or battle a decklist.",
            "Young Pyromancer is treated as pressure-token conversion, not as ramp, removal, or draw.",
            "A singleton add still requires one named cut that preserves the 607 miracle/topdeck, protection, and pressure floors.",
            "Forced diagnostics can teach card behavior, but cannot promote 607 without a natural add/cut gate.",
        ],
        "decision": {
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": False,
            "natural_battle_gate_allowed": False,
            "reason": (
                "Young Pyromancer passes local identity/runtime preflight, but current "
                "607 cut evidence has no eligible pressure-compatible cut and the "
                "card is still missing a natural-gate hypothesis row."
            ),
            "next_actions": [
                "do_not_mutate_or_replace_deck_607",
                "do_not_run_natural_battle_without_one_named_pressure_safe_cut",
                "mine pressure-window losses for low-use non-anchor pressure slots",
                "use forced diagnostics only for learning, not promotion",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    target = payload["target_card"]
    lines = [
        "# Lorehold Young Pyromancer Singleton Cut-Safety Model",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Target card: `{summary_row['target_card']}`",
        f"- Package status: `{summary_row['package_status']}`",
        f"- Evaluated cut slots: `{summary_row['evaluated_cut_slot_count']}`",
        f"- Eligible cuts: `{summary_row['eligible_cut_count']}`",
        f"- Pressure-lane evidence gaps: `{summary_row['pressure_lane_evidence_gap_count']}`",
        f"- Pressure-lane hard blocked: `{summary_row['pressure_lane_hard_blocked_count']}`",
        f"- Seed-safe cut count: `{summary_row['seed_safe_cut_ready_count']}`",
        f"- Reviewable evidence gaps: `{summary_row['reviewable_evidence_gap_count']}`",
        f"- Natural battle gate allowed: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- Promotion allowed: `{str(summary_row['promotion_allowed_now']).lower()}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Target Card",
        "",
        f"- Role: `{target['role']}`",
        f"- CMC: `{target['cmc']}`",
        f"- Type line: `{target['type_line']}`",
        f"- Commander legality: `{target['commander_legal_status']}`",
        f"- Preflight: `{target['preflight_status']}`",
        f"- Verified auto battle rules: `{target['verified_auto_battle_rule_count']}`",
        f"- Already in 607: `{str(target['already_in_607']).lower()}`",
        f"- Package blockers: `{json.dumps(target['package_blockers'], sort_keys=True)}`",
        "",
        "## Top Cut-Safety Rows",
        "",
        "| Card | Lane | Young Pyromancer Cut Status | Exposure | Events | Action |",
        "| --- | --- | --- | ---: | ---: | --- |",
    ]
    for row in payload.get("top_cut_safety_rows") or []:
        lines.append(
            "| {card} | `{lane}` | `{status}` | {exposure} | {events} | {action} |".format(
                card=row.get("card_name") or "",
                lane=row.get("lane") or "",
                status=row.get("young_pyromancer_cut_status") or "",
                exposure=row.get("unique_exposure_count") or 0,
                events=row.get("direct_event_count") or 0,
                action=row.get("recommended_action") or "",
            )
        )
    lines.extend(["", "## External Support", ""])
    for row in payload.get("external_support") or []:
        lines.append(f"- `{row.get('source')}`: {row.get('url')} - {row.get('model_effect')}")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- Keep 607 protected: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- Natural battle gate allowed: `{str(decision['natural_battle_gate_allowed']).lower()}`")
    lines.append(f"- Promotion allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- Reason: {decision['reason']}")
    lines.append("- Next actions:")
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
    parser.add_argument("--package-router", type=Path, default=DEFAULT_PACKAGE_ROUTER)
    parser.add_argument("--pressure-contract", type=Path, default=DEFAULT_PRESSURE_CONTRACT)
    parser.add_argument("--seed-safe", type=Path, default=DEFAULT_SEED_SAFE)
    parser.add_argument("--trace-expander", type=Path, default=DEFAULT_TRACE_EXPANDER)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "package_router": args.package_router,
        "pressure_contract": args.pressure_contract,
        "seed_safe_cut_report": args.seed_safe,
        "trace_cut_evidence_expander": args.trace_expander,
    }
    payload = build_model(
        package_router=read_json(args.package_router),
        pressure_contract=read_json(args.pressure_contract),
        seed_safe_report=read_json(args.seed_safe),
        trace_expander=read_json(args.trace_expander),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
