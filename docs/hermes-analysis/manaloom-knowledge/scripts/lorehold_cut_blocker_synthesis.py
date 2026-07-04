#!/usr/bin/env python3
"""Synthesize why Lorehold 607 has no seed-safe cut slot yet.

This read-only layer sits after the seed-safe cut hypothesis builder and the
pressure micro-package planner. It does not choose new cards, mutate deck 607,
or run battles. Its purpose is to split the current "no safe cut" result into
actionable buckets: hard blockers, same-lane-only blockers, and evidence gaps.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Mapping, Sequence
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_SEED_SAFE = REPORT_DIR / "lorehold_seed_safe_cut_hypothesis_20260704_role_tag_repair.json"
DEFAULT_PRESSURE_MICRO = REPORT_DIR / "lorehold_pressure_micro_package_planner_20260704_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_cut_blocker_synthesis_20260704_current"

HARD_BLOCKERS = {
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

SAME_LANE_BLOCKERS = {
    "same_lane_only_requires_concrete_same_lane_add",
}

EVIDENCE_GAP_BLOCKERS = {
    "cut_not_flex_decision",
    "cut_safety_not_seed_safe",
    "manual_review_cut_safety_block",
    "manual_status_not_seed_safe",
    "missing_cut_safety_row",
    "missing_manual_cut_evidence",
}

EXTERNAL_LEARNING = [
    {
        "source": "GameTyrant Lorehold deck tech",
        "url": "https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech",
        "learning": (
            "Public pressure payoffs such as Guttersnipe, Young Pyromancer, and "
            "Monastery Mentor support pressure experiments, but they do not name a "
            "safe cut from the protected miracle shell."
        ),
    },
    {
        "source": "EDHREC optimized topdeck page",
        "url": "https://edhrec.com/decks/lorehold-the-historian/optimized/topdeck",
        "learning": (
            "The optimized public lane is tagged around Topdeck, Spellslinger, "
            "Combo, and Discard, so pressure belongs inside the topdeck plan rather "
            "than as a blind cross-lane swap."
        ),
    },
    {
        "source": "Draftsim Lorehold Commander guide",
        "url": "https://draftsim.com/lorehold-the-historian-edh-deck/",
        "learning": (
            "External guide material frames ramp, big instants/sorceries, topdeck "
            "manipulation, and Library of Leng style timing as the deck's engine. "
            "That supports protecting ramp, miracle spells, and topdeck setup."
        ),
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
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return list(value) if isinstance(value, list) else []


def blocker_groups(blockers: Sequence[str]) -> dict[str, list[str]]:
    blocker_set = {str(item) for item in blockers}
    return {
        "hard": sorted(blocker_set & HARD_BLOCKERS),
        "same_lane": sorted(blocker_set & SAME_LANE_BLOCKERS),
        "evidence_gap": sorted(blocker_set & EVIDENCE_GAP_BLOCKERS),
        "other": sorted(blocker_set - HARD_BLOCKERS - SAME_LANE_BLOCKERS - EVIDENCE_GAP_BLOCKERS),
    }


def cut_classification(row: Mapping[str, Any]) -> str:
    if row.get("status") == "seed_safe_cut_ready":
        return "seed_safe_ready"
    groups = blocker_groups(as_list(row.get("blockers")))
    if groups["hard"]:
        return "hard_blocked"
    if groups["same_lane"]:
        return "same_lane_only"
    if groups["evidence_gap"]:
        return "evidence_gap_only"
    return "unclassified_blocked"


def next_action_for_classification(classification: str) -> str:
    if classification == "seed_safe_ready":
        return "build_named_failure_targeted_package_then_run_structure_and_natural_gate"
    if classification == "evidence_gap_only":
        return "expand_cut_safety_manifest_and_manual_review_before_any_battle"
    if classification == "same_lane_only":
        return "only_test_with_concrete_same_lane_add_and_equal_gate"
    if classification == "hard_blocked":
        return "do_not_use_as_generic_cut"
    return "manual_review_required_before_any_gate"


def scored_cut_rows(seed_safe_report: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in as_list(seed_safe_report.get("cut_slots")):
        if not isinstance(row, Mapping):
            continue
        classification = cut_classification(row)
        groups = blocker_groups(as_list(row.get("blockers")))
        rows.append(
            {
                "card_name": str(row.get("card_name") or ""),
                "lane": str(row.get("lane") or ""),
                "status": str(row.get("status") or ""),
                "classification": classification,
                "next_action": next_action_for_classification(classification),
                "score": int(row.get("score") or 0),
                "unique_exposure_count": int(row.get("unique_exposure_count") or 0),
                "direct_event_count": int(row.get("direct_event_count") or 0),
                "manual_status": str(row.get("manual_status") or ""),
                "cut_safety_status": str(row.get("cut_safety_status") or ""),
                "cut_safety_decision": str(row.get("cut_safety_decision") or ""),
                "blockers": sorted(str(item) for item in as_list(row.get("blockers"))),
                "blocker_groups": groups,
            }
        )
    priority = {
        "seed_safe_ready": 0,
        "evidence_gap_only": 1,
        "same_lane_only": 2,
        "unclassified_blocked": 3,
        "hard_blocked": 4,
    }
    rows.sort(
        key=lambda row: (
            priority.get(row["classification"], 9),
            -int(row.get("score") or 0),
            int(row.get("unique_exposure_count") or 0),
            row.get("card_name") or "",
        )
    )
    return rows


def pressure_findings(pressure_report: Mapping[str, Any], cut_rows: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    summary = pressure_report.get("summary") if isinstance(pressure_report.get("summary"), Mapping) else {}
    natural_trigger_cards = list(summary.get("natural_trigger_cards") or [])
    pressure_cut_rows = [
        row
        for row in cut_rows
        if str(row.get("lane") or "") in {"pressure_payoff", "payoffs_finishers", "pressure"}
    ]
    gate_ready_packages = [
        row
        for row in as_list(pressure_report.get("micro_package_queue"))
        if isinstance(row, Mapping) and row.get("gate_ready")
    ]
    if gate_ready_packages:
        status = "pressure_package_has_cut_plan"
    elif natural_trigger_cards:
        status = "pressure_signal_blocked_by_cut_model"
    else:
        status = "no_pressure_signal_ready"
    return {
        "status": status,
        "natural_trigger_cards": natural_trigger_cards,
        "gate_ready_package_count": len(gate_ready_packages),
        "pressure_lane_cut_count": len(pressure_cut_rows),
        "pressure_lane_cut_cards": [row.get("card_name") for row in pressure_cut_rows],
        "interpretation": (
            "Pressure adds have real signal, but 607 currently has no seed-safe or same-lane "
            "pressure-payoff cut. A Guttersnipe/Young Pyromancer package is therefore a "
            "full-shell hypothesis, not a one-for-one promotion gate."
            if status == "pressure_signal_blocked_by_cut_model"
            else "Pressure package status follows the current micro-package planner."
        ),
    }


def build_payload(
    *,
    seed_safe_report: Mapping[str, Any],
    pressure_report: Mapping[str, Any],
    seed_safe_path: Path,
    pressure_path: Path,
) -> dict[str, Any]:
    cut_rows = scored_cut_rows(seed_safe_report)
    classifications = Counter(row["classification"] for row in cut_rows)
    group_counts = Counter(
        group
        for row in cut_rows
        for group, values in row["blocker_groups"].items()
        if values
    )
    blocker_counts = Counter(blocker for row in cut_rows for blocker in row.get("blockers") or [])
    evidence_gap_rows = [row for row in cut_rows if row["classification"] == "evidence_gap_only"]
    same_lane_rows = [row for row in cut_rows if row["classification"] == "same_lane_only"]
    same_lane_constraint_rows = [
        row for row in cut_rows if row.get("blocker_groups", {}).get("same_lane")
    ]
    hard_rows = [row for row in cut_rows if row["classification"] == "hard_blocked"]
    pressure = pressure_findings(pressure_report, cut_rows)
    seed_safe_count = classifications.get("seed_safe_ready", 0)
    if seed_safe_count:
        status = "cut_blocker_seed_safe_ready"
    elif evidence_gap_rows:
        status = "cut_blocker_evidence_gap_queue_ready"
    else:
        status = "cut_blocker_no_seed_safe_pressure_requires_full_shell"
    next_actions = []
    if evidence_gap_rows:
        next_actions.append("expand_cut_safety_rows_for_evidence_gap_only_cards")
    if same_lane_constraint_rows:
        next_actions.append("build_same_lane_only_microbenchmarks_without_cross_lane_promotion")
    next_actions.append("keep_607_protected_until_equal_gate_and_card_use_proof")
    if pressure["status"] == "pressure_signal_blocked_by_cut_model":
        next_actions.append("model_pressure_as_full_shell_or_find_true_pressure_lane_cut")
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_cut_blocker_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": {
            "seed_safe_cut_report": rel(seed_safe_path),
            "pressure_micro_package_report": rel(pressure_path),
        },
        "external_learning": EXTERNAL_LEARNING,
        "status": status,
        "summary": {
            "cut_slot_count": len(cut_rows),
            "seed_safe_ready_count": seed_safe_count,
            "evidence_gap_only_count": len(evidence_gap_rows),
            "same_lane_only_count": len(same_lane_rows),
            "same_lane_constraint_count": len(same_lane_constraint_rows),
            "hard_blocked_count": len(hard_rows),
            "classification_counts": dict(sorted(classifications.items())),
            "blocker_group_counts": dict(sorted(group_counts.items())),
            "top_blocker_counts": dict(blocker_counts.most_common(15)),
            "promotion_allowed": False,
        },
        "pressure_findings": pressure,
        "evidence_gap_queue": evidence_gap_rows[:20],
        "same_lane_only_queue": same_lane_constraint_rows[:20],
        "hard_blocked_top": hard_rows[:30],
        "cut_blocker_rows": cut_rows,
        "decision": {
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": False,
            "reason": (
                "No current cut slot is seed-safe. Public Lorehold pressure evidence supports "
                "further pressure modeling, but the active 607 evidence classifies the available "
                "slots as hard-blocked, same-lane-only, or requiring more cut-safety evidence."
            ),
            "next_actions": next_actions,
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Cut Blocker Synthesis",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- seed_safe_ready_count: `{summary['seed_safe_ready_count']}`",
        f"- evidence_gap_only_count: `{summary['evidence_gap_only_count']}`",
        f"- same_lane_only_count: `{summary['same_lane_only_count']}`",
        f"- same_lane_constraint_count: `{summary['same_lane_constraint_count']}`",
        f"- hard_blocked_count: `{summary['hard_blocked_count']}`",
        f"- classification_counts: `{json.dumps(summary['classification_counts'], sort_keys=True)}`",
        "",
        "## Pressure Finding",
        "",
        f"- status: `{payload['pressure_findings']['status']}`",
        f"- natural_trigger_cards: `{json.dumps(payload['pressure_findings']['natural_trigger_cards'])}`",
        f"- interpretation: {payload['pressure_findings']['interpretation']}",
        "",
        "## Evidence Gap Queue",
        "",
    ]
    if not payload.get("evidence_gap_queue"):
        lines.append("- None.")
    else:
        lines.extend(["| Card | Lane | Score | Exposure | Next Action |", "| --- | --- | ---: | ---: | --- |"])
        for row in payload["evidence_gap_queue"]:
            lines.append(
                f"| `{row['card_name']}` | `{row['lane']}` | {row['score']} | "
                f"{row['unique_exposure_count']} | `{row['next_action']}` |"
            )
    lines.extend(["", "## Same-Lane Only Queue", ""])
    if not payload.get("same_lane_only_queue"):
        lines.append("- None.")
    else:
        for row in payload["same_lane_only_queue"]:
            lines.append(
                f"- `{row['card_name']}` lane `{row['lane']}` requires concrete same-lane add; "
                f"blockers `{', '.join(row.get('blockers') or [])}`."
            )
    lines.extend(["", "## Hard-Blocked Top", ""])
    for row in payload.get("hard_blocked_top") or []:
        lines.append(
            f"- `{row['card_name']}` lane `{row['lane']}` blockers "
            f"`{', '.join(row.get('blockers') or [])}`."
        )
    lines.extend(["", "## External Learning", ""])
    for source in payload.get("external_learning") or []:
        lines.append(f"- {source['source']}: {source['url']}")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(payload['decision']['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(payload['decision']['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {payload['decision']['reason']}")
    lines.append("- next_actions:")
    for action in payload["decision"]["next_actions"]:
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
    parser.add_argument("--seed-safe", type=Path, default=DEFAULT_SEED_SAFE)
    parser.add_argument("--pressure-micro", type=Path, default=DEFAULT_PRESSURE_MICRO)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(
        seed_safe_report=read_json(args.seed_safe),
        pressure_report=read_json(args.pressure_micro),
        seed_safe_path=args.seed_safe,
        pressure_path=args.pressure_micro,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
