#!/usr/bin/env python3
"""Mine cut evidence for the Guttersnipe + Storm-Kiln Lorehold route.

This read-only model starts after the hypothesis contract proves the package
needs two named seed-safe cuts. It classifies current 607 cut slots into
actionable seed-safe cuts, target-lane evidence gaps, cross-lane exclusions, and
hard-stop protected slots. It does not build or mutate a deck.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_CONTRACT = (
    REPORT_DIR / "lorehold_guttersnipe_storm_kiln_hypothesis_contract_20260705_current_relearn.json"
)
DEFAULT_SEED_SAFE = REPORT_DIR / "lorehold_seed_safe_cut_hypothesis_20260704_role_tag_repair.json"
DEFAULT_TRACE_EXPANDER = REPORT_DIR / "lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.json"
DEFAULT_CUT_EXPANSION = REPORT_DIR / "lorehold_pressure_safe_cut_expansion_model_20260705_current.json"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn"
)

TARGET_ROUTE_KEY = "guttersnipe_storm_kiln_engine_preserving_pair"
TARGET_ADDS = ["Guttersnipe", "Storm-Kiln Artist"]
TARGET_CUT_LANES = {"spell_velocity", "contextual", "pressure_absorber", "spell_chain_conversion"}
HARD_STOP_LANES = {
    "commander",
    "mana_base",
    "early_mana",
    "protection",
    "big_spell_value",
    "topdeck_setup",
    "topdeck_miracle_setup",
    "wincon",
}
HARD_STOP_BLOCKERS = {
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
SOFT_EVIDENCE_BLOCKERS = {
    "cut_not_flex_decision",
    "cut_safety_not_seed_safe",
    "manual_review_cut_safety_block",
    "manual_status_not_seed_safe",
    "missing_cut_safety_row",
    "same_lane_only_requires_concrete_same_lane_add",
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


def target_required_cut_count(contract: Mapping[str, Any]) -> int:
    return as_int(summary(contract).get("required_cut_count")) or len(TARGET_ADDS)


def route_status(contract: Mapping[str, Any]) -> str:
    return str(summary(contract).get("router_route_status") or contract.get("status") or "")


def row_index(trace_expander: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    index: dict[str, dict[str, Any]] = {}
    for key in ("all_cut_slots", "hard_blocked_queue", "same_lane_hard_blocked_queue"):
        for row in as_list(trace_expander.get(key)):
            if isinstance(row, Mapping) and row.get("card_name"):
                current = index.setdefault(str(row["card_name"]), {})
                current.update(dict(row))
    return index


def top_near_miss_ranks(trace_expander: Mapping[str, Any]) -> dict[str, int]:
    return {
        str(name): index
        for index, name in enumerate(as_list(summary(trace_expander).get("top_near_miss_cut_cards")), 1)
    }


def classify_cut(row: Mapping[str, Any]) -> str:
    status = str(row.get("status") or "")
    lane = str(row.get("lane") or "")
    blockers = {str(item) for item in as_list(row.get("blockers"))}
    hard_blockers = blockers & HARD_STOP_BLOCKERS
    soft_blockers = blockers & SOFT_EVIDENCE_BLOCKERS
    if status in {"seed_safe_cut_ready", "ready"} and not hard_blockers:
        return "seed_safe_cut_ready"
    if hard_blockers or lane in HARD_STOP_LANES:
        return "closed_hard_stop_current_607"
    if lane and lane not in TARGET_CUT_LANES:
        return "cross_lane_not_current_package_cut"
    if soft_blockers:
        return "target_lane_evidence_gap_not_seed_safe"
    return "blocked_unclassified_current_evidence"


def investigation_action(classification: str) -> str:
    return {
        "seed_safe_cut_ready": "can_feed_hypothesis_contract_after_structure_matrix",
        "target_lane_evidence_gap_not_seed_safe": (
            "collect_named_cut_safety_and_trace_evidence_before_any_package_build"
        ),
        "cross_lane_not_current_package_cut": "requires_separate_shell_contract_not_this_pair",
        "closed_hard_stop_current_607": "do_not_use_as_cut_under_current_607_contract",
        "blocked_unclassified_current_evidence": "audit_before_use_no_deck_action",
    }.get(classification, "audit_before_use_no_deck_action")


def unlock_requirements(classification: str, row: Mapping[str, Any]) -> list[str]:
    blockers = {str(item) for item in as_list(row.get("blockers"))}
    lane = str(row.get("lane") or "")
    requirements = [
        "named cut must be seed-safe under current 607 evidence",
        "cut must be same-lane or covered by explicit package-shell contract",
        "future gate must preserve Winota and other fast-pressure slices",
        "future gate must preserve topdeck, miracle, Lorehold spell-cast, and mana floors",
        "added cards must produce direct Guttersnipe damage and Storm-Kiln Treasure events",
    ]
    if classification == "closed_hard_stop_current_607":
        requirements.insert(
            0,
            "current hard-stop blockers must not be bypassed: "
            + ", ".join(sorted(blockers & HARD_STOP_BLOCKERS) or [f"hard_lane:{lane}"]),
        )
    elif classification == "cross_lane_not_current_package_cut":
        requirements.insert(0, f"lane `{lane}` is not a current package cut lane")
    elif classification == "target_lane_evidence_gap_not_seed_safe":
        requirements.insert(0, "missing cut-safety/manual evidence must be produced first")
    return requirements


def merge_cut_row(
    seed_row: Mapping[str, Any],
    trace_index: Mapping[str, Mapping[str, Any]],
    near_miss_ranks: Mapping[str, int],
) -> dict[str, Any]:
    name = str(seed_row.get("card_name") or "")
    trace_row = trace_index.get(name, {})
    merged = dict(trace_row)
    merged.update(dict(seed_row))
    blockers = sorted(set(as_list(trace_row.get("blockers")) + as_list(seed_row.get("blockers"))))
    merged["blockers"] = blockers
    classification = classify_cut(merged)
    blockers_set = set(blockers)
    return {
        "card_name": name,
        "lane": merged.get("lane") or "",
        "status": merged.get("status") or "",
        "manual_status": merged.get("manual_status") or "",
        "actionability": merged.get("actionability") or "",
        "classification": classification,
        "investigation_action": investigation_action(classification),
        "score": as_int(merged.get("score")),
        "unique_exposure_count": as_int(merged.get("unique_exposure_count")),
        "direct_event_count": as_int(merged.get("direct_event_count")),
        "near_miss_rank": near_miss_ranks.get(name),
        "hard_stop_blockers": sorted(blockers_set & HARD_STOP_BLOCKERS),
        "soft_evidence_blockers": sorted(blockers_set & SOFT_EVIDENCE_BLOCKERS),
        "other_blockers": sorted(blockers_set - HARD_STOP_BLOCKERS - SOFT_EVIDENCE_BLOCKERS),
        "unlock_requirements": unlock_requirements(classification, merged),
    }


def cut_sort_key(row: Mapping[str, Any]) -> tuple[int, int, int, int, str]:
    rank = {
        "seed_safe_cut_ready": 0,
        "target_lane_evidence_gap_not_seed_safe": 1,
        "cross_lane_not_current_package_cut": 2,
        "closed_hard_stop_current_607": 3,
        "blocked_unclassified_current_evidence": 4,
    }.get(str(row.get("classification") or ""), 5)
    near_miss = as_int(row.get("near_miss_rank")) or 999
    hard_count = len(as_list(row.get("hard_stop_blockers")))
    exposure = as_int(row.get("unique_exposure_count"))
    return (rank, near_miss, hard_count, exposure, str(row.get("card_name") or ""))


def build_cut_rows(
    seed_safe_report: Mapping[str, Any], trace_expander: Mapping[str, Any]
) -> list[dict[str, Any]]:
    trace_index = row_index(trace_expander)
    near_miss_ranks = top_near_miss_ranks(trace_expander)
    rows = [
        merge_cut_row(row, trace_index, near_miss_ranks)
        for row in as_list(seed_safe_report.get("cut_slots"))
        if isinstance(row, Mapping) and row.get("card_name")
    ]
    rows.sort(key=cut_sort_key)
    return rows


def build_report(
    *,
    contract: Mapping[str, Any],
    seed_safe_report: Mapping[str, Any],
    trace_expander: Mapping[str, Any],
    cut_expansion: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    rows = build_cut_rows(seed_safe_report, trace_expander)
    required_cut_count = target_required_cut_count(contract)
    seed_ready = [row for row in rows if row["classification"] == "seed_safe_cut_ready"]
    target_lane_gaps = [
        row for row in rows if row["classification"] == "target_lane_evidence_gap_not_seed_safe"
    ]
    cross_lane = [row for row in rows if row["classification"] == "cross_lane_not_current_package_cut"]
    hard_stop = [row for row in rows if row["classification"] == "closed_hard_stop_current_607"]
    class_counts = Counter(row["classification"] for row in rows)
    lane_counts = Counter(str(row.get("lane") or "") for row in rows)
    hard_stop_counts = Counter(
        blocker for row in rows for blocker in as_list(row.get("hard_stop_blockers"))
    )
    cut_shortage = max(0, required_cut_count - len(seed_ready))
    if len(seed_ready) >= required_cut_count:
        decision_status = "cut_evidence_ready_for_structure_matrix"
        next_action = "feed_named_cuts_into_hypothesis_contract_then_structure_matrix"
    elif target_lane_gaps:
        decision_status = "target_lane_cut_evidence_gap_keep_607"
        next_action = "produce_named_cut_safety_evidence_for_target_lane_gaps"
    else:
        decision_status = "no_current_cut_evidence_for_guttersnipe_storm_kiln_keep_607"
        next_action = "do_not_battle_mine_new_nonanchor_trace_or_new_shell_contract"

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_engine_preserving_cut_evidence_miner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "status": decision_status,
        "summary": {
            "decision_status": decision_status,
            "target_route_key": TARGET_ROUTE_KEY,
            "target_adds": TARGET_ADDS,
            "target_required_cut_count": required_cut_count,
            "named_seed_safe_cut_count": len(seed_ready),
            "cut_shortage": cut_shortage,
            "target_lane_evidence_gap_count": len(target_lane_gaps),
            "cross_lane_excluded_count": len(cross_lane),
            "hard_stop_cut_count": len(hard_stop),
            "total_cut_slots_reviewed": len(rows),
            "classification_counts": dict(sorted(class_counts.items())),
            "lane_counts": dict(sorted(lane_counts.items())),
            "hard_stop_blocker_counts": dict(sorted(hard_stop_counts.items())),
            "contract_status": contract.get("status") or "",
            "router_route_status": route_status(contract),
            "cut_expansion_status": cut_expansion.get("status") or "",
            "promotion_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "ready_deck_change_count": 0,
            "recommended_next_action": next_action,
        },
        "ready_seed_safe_cuts": seed_ready,
        "target_lane_evidence_gaps": target_lane_gaps,
        "cross_lane_exclusions": cross_lane[:20],
        "hard_stop_near_misses": hard_stop[:20],
        "all_cut_rows": rows,
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "The Guttersnipe + Storm-Kiln package still needs two named seed-safe "
                "cuts. Current evidence has no seed-safe cuts and no target-lane "
                "evidence gaps that can be promoted into a package now."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_run_natural_battle_for_this_package",
                "mine new low-exposure non-anchor target-lane evidence",
                "or define a separate shell contract if the cut is cross-lane",
                "keep hard-stop anchors closed unless a future contract explicitly changes the role profile",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    lines = [
        "# Lorehold Engine-Preserving Cut Evidence Miner",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Target route: `{summary_row['target_route_key']}`",
        f"- Target adds: `{', '.join(summary_row['target_adds'])}`",
        f"- Required cuts: `{summary_row['target_required_cut_count']}`",
        f"- Named seed-safe cuts: `{summary_row['named_seed_safe_cut_count']}`",
        f"- Cut shortage: `{summary_row['cut_shortage']}`",
        f"- Target-lane evidence gaps: `{summary_row['target_lane_evidence_gap_count']}`",
        f"- Hard-stop cut count: `{summary_row['hard_stop_cut_count']}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Ready Seed-Safe Cuts", ""])
    if payload.get("ready_seed_safe_cuts"):
        for row in as_list(payload.get("ready_seed_safe_cuts")):
            lines.append(f"- `{row.get('card_name')}` lane `{row.get('lane')}`.")
    else:
        lines.append("- None.")
    lines.extend(["", "## Target-Lane Evidence Gaps", ""])
    if payload.get("target_lane_evidence_gaps"):
        for row in as_list(payload.get("target_lane_evidence_gaps")):
            lines.append(
                f"- `{row.get('card_name')}` lane `{row.get('lane')}` blockers "
                f"`{', '.join(as_list(row.get('soft_evidence_blockers'))) or '-'}`."
            )
    else:
        lines.append("- None.")
    lines.extend(
        [
            "",
            "## Hard-Stop Near Misses",
            "",
            "| Card | Lane | Exposure | Hard Stop Blockers | Action |",
            "| --- | --- | ---: | --- | --- |",
        ]
    )
    for row in as_list(payload.get("hard_stop_near_misses"))[:12]:
        lines.append(
            "| {card} | `{lane}` | {exposure} | {blockers} | `{action}` |".format(
                card=row.get("card_name") or "",
                lane=row.get("lane") or "",
                exposure=row.get("unique_exposure_count") or 0,
                blockers=", ".join(as_list(row.get("hard_stop_blockers"))) or "-",
                action=row.get("investigation_action") or "",
            )
        )
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
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--seed-safe", type=Path, default=DEFAULT_SEED_SAFE)
    parser.add_argument("--trace-expander", type=Path, default=DEFAULT_TRACE_EXPANDER)
    parser.add_argument("--cut-expansion", type=Path, default=DEFAULT_CUT_EXPANSION)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "hypothesis_contract": args.contract,
        "seed_safe_cut_report": args.seed_safe,
        "trace_cut_evidence_expander": args.trace_expander,
        "pressure_safe_cut_expansion_model": args.cut_expansion,
    }
    payload = build_report(
        contract=read_json(args.contract),
        seed_safe_report=read_json(args.seed_safe),
        trace_expander=read_json(args.trace_expander),
        cut_expansion=read_json(args.cut_expansion),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
