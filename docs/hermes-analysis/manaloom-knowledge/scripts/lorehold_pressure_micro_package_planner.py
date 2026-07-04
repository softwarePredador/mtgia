#!/usr/bin/env python3
"""Plan the next Lorehold pressure micro-package from current evidence.

The full four-card pressure package is diagnostic-only and regressed the
protected miracle/topdeck cadence. This read-only planner narrows that learning
to the smallest plausible hypotheses while preserving the hard stop: no
natural gate is allowed without seed-safe cuts.
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

DEFAULT_PRESSURE_DECISION = (
    REPORT_DIR / "lorehold_pressure_tradeoff_decision_synthesis_20260704_current.json"
)
DEFAULT_SEED_SAFE = (
    REPORT_DIR / "lorehold_seed_safe_cut_hypothesis_20260704_role_tag_repair.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_pressure_micro_package_planner_20260704_current"

PROTECTED_PRESSURE_ANCHOR_CUTS = {
    "Bender's Waterskin",
    "Creative Technique",
    "Molecule Man",
    "The Mind Stone",
    "The Scarlet Witch",
    "Victory Chimes",
}

EXTERNAL_SUPPORT = [
    {
        "source": "GameTyrant Lorehold deck tech",
        "url": "https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech",
        "learning": (
            "Monastery Mentor, Young Pyromancer, Guttersnipe, and Storm-Kiln Artist "
            "are pressure payoffs for spell-heavy Lorehold shells, but this supports "
            "testing pressure lanes rather than overriding 607's protected miracle engine."
        ),
    },
    {
        "source": "EDHREC Lorehold Commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "learning": (
            "The current public commander page frames Lorehold through topdeck, "
            "spellslinger, discard, and burn tags. Pressure payoffs fit only if "
            "the topdeck and miracle axis is preserved."
        ),
    },
    {
        "source": "EDHREC Boros Miracles budget article",
        "url": "https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget",
        "learning": (
            "Lorehold's miracle plan depends on avoiding too many non-instant/sorcery "
            "duds and protecting topdeck manipulation, which makes creature pressure "
            "packages expensive unless cuts are proven safe."
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


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def card_rows(pressure_decision: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for row in pressure_decision.get("candidate_cards") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            rows[str(row["card_name"])] = dict(row)
    return rows


def seed_safe_names(seed_safe_report: Mapping[str, Any]) -> list[str]:
    names = []
    for row in seed_safe_report.get("seed_safe_cut_candidates") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            names.append(str(row["card_name"]))
    return names


def same_lane_only_names(seed_safe_report: Mapping[str, Any]) -> list[str]:
    names = []
    for row in seed_safe_report.get("same_lane_only_cut_slots") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            names.append(str(row["card_name"]))
    summary = seed_safe_report.get("summary")
    if isinstance(summary, Mapping):
        for name in summary.get("same_lane_only_cut_cards") or []:
            if str(name) not in names:
                names.append(str(name))
    return sorted(names)


def trigger_count(row: Mapping[str, Any]) -> int:
    return as_int(row.get("natural_trigger_count"))


def event_total(row: Mapping[str, Any]) -> int:
    return sum(as_int(value) for value in (row.get("natural_event_counts") or {}).values())


def package_status(required_cuts: int, safe_cut_names: list[str], *, miracle_regressed: bool) -> str:
    if len(safe_cut_names) < required_cuts:
        return "blocked_no_seed_safe_cut"
    if miracle_regressed:
        return "blocked_prior_full_package_regressed_miracle_requires_rebuilt_hypothesis"
    return "gate_ready_requires_strategy_matrix"


def package_row(
    *,
    key: str,
    adds: list[str],
    card_data: Mapping[str, Mapping[str, Any]],
    safe_cut_names: list[str],
    miracle_regressed: bool,
    priority: int,
) -> dict[str, Any]:
    required_cuts = len(adds)
    status = package_status(required_cuts, safe_cut_names, miracle_regressed=miracle_regressed)
    card_evidence = [dict(card_data.get(name) or {"card_name": name}) for name in adds]
    return {
        "package_key": key,
        "adds": adds,
        "required_cut_count": required_cuts,
        "available_seed_safe_cut_count": len(safe_cut_names),
        "available_seed_safe_cuts": safe_cut_names[:required_cuts],
        "status": status,
        "gate_ready": status == "gate_ready_requires_strategy_matrix",
        "priority": priority,
        "natural_trigger_count": sum(trigger_count(row) for row in card_evidence),
        "natural_event_count": sum(event_total(row) for row in card_evidence),
        "card_evidence": card_evidence,
    }


def candidate_card_rows(card_data: Mapping[str, Mapping[str, Any]]) -> list[dict[str, Any]]:
    rows = []
    for name in ("Guttersnipe", "Young Pyromancer", "Monastery Mentor", "Storm-Kiln Artist"):
        source = dict(card_data.get(name) or {"card_name": name})
        if trigger_count(source) > 0:
            decision = "hypothesis_natural_trigger_signal_no_seed_safe_cut"
        elif as_int(source.get("natural_cost_count")) or as_int(source.get("natural_cast_count")):
            decision = "hypothesis_natural_cast_signal_no_seed_safe_cut"
        elif as_int(source.get("natural_near_access_games")):
            decision = "blocked_near_access_only_no_seed_safe_cut"
        else:
            decision = "blocked_no_natural_use_no_seed_safe_cut"
        rows.append(
            {
                "card_name": name,
                "lane": "pressure_payoff",
                "decision": decision,
                "natural_trigger_count": trigger_count(source),
                "natural_event_count": event_total(source),
                "natural_accessed_games": as_int(source.get("natural_accessed_games")),
                "natural_near_access_games": as_int(source.get("natural_near_access_games")),
            }
        )
    return rows


def build_plan(
    *,
    pressure_decision: Mapping[str, Any],
    seed_safe_report: Mapping[str, Any],
    pressure_path: Path,
    seed_safe_path: Path,
) -> dict[str, Any]:
    data = card_rows(pressure_decision)
    safe_cuts = seed_safe_names(seed_safe_report)
    same_lane_only = same_lane_only_names(seed_safe_report)
    natural = pressure_decision.get("natural_smoke_gate")
    miracle_regressed = bool(isinstance(natural, Mapping) and natural.get("miracle_regressed"))
    packages = [
        package_row(
            key="pressure_natural_trigger_pair_guttersnipe_young_pyromancer",
            adds=["Guttersnipe", "Young Pyromancer"],
            card_data=data,
            safe_cut_names=safe_cuts,
            miracle_regressed=miracle_regressed,
            priority=1,
        ),
        package_row(
            key="pressure_single_guttersnipe",
            adds=["Guttersnipe"],
            card_data=data,
            safe_cut_names=safe_cuts,
            miracle_regressed=miracle_regressed,
            priority=2,
        ),
        package_row(
            key="pressure_single_young_pyromancer",
            adds=["Young Pyromancer"],
            card_data=data,
            safe_cut_names=safe_cuts,
            miracle_regressed=miracle_regressed,
            priority=3,
        ),
        package_row(
            key="pressure_single_monastery_mentor_probe_only",
            adds=["Monastery Mentor"],
            card_data=data,
            safe_cut_names=safe_cuts,
            miracle_regressed=miracle_regressed,
            priority=4,
        ),
    ]
    gate_ready_count = sum(1 for row in packages if row["gate_ready"])
    status = (
        "pressure_micro_package_gate_ready"
        if gate_ready_count
        else "pressure_micro_package_no_gate_ready_keep_607"
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_pressure_micro_package_planner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "status": status,
        "source_reports": {
            "pressure_decision": rel(pressure_path),
            "seed_safe_cut_report": rel(seed_safe_path),
        },
        "external_support": EXTERNAL_SUPPORT,
        "summary": {
            "package_count": len(packages),
            "gate_ready_package_count": gate_ready_count,
            "seed_safe_cut_ready_count": len(safe_cuts),
            "same_lane_only_cut_count": len(same_lane_only),
            "promotion_allowed": False,
            "natural_trigger_cards": [
                row["card_name"]
                for row in candidate_card_rows(data)
                if row["natural_trigger_count"] > 0
            ],
        },
        "candidate_cards": candidate_card_rows(data),
        "micro_package_queue": packages,
        "blocked_cut_context": {
            "seed_safe_cuts": safe_cuts,
            "same_lane_only_cut_cards": same_lane_only,
            "protected_anchor_cuts": sorted(PROTECTED_PRESSURE_ANCHOR_CUTS),
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": False,
            "reason": (
                "The natural trigger signal is real for Guttersnipe and Young Pyromancer, "
                "but the active 607 cut model still has zero seed-safe cuts. The next "
                "valid work is cut-safety expansion or a separate full-shell contract, "
                "not a natural battle gate."
            ),
            "next_actions": [
                "do_not_stage_or_battle_the_micro_package_until_seed_safe_cuts_exist",
                "treat Guttersnipe and Young Pyromancer as the current smallest pressure hypothesis",
                "preserve Bender's Waterskin and Creative Technique despite same-lane-only status",
                "mine failed and winning 607 traces for a genuinely low-risk nonpressure cut slot",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Pressure Micro-Package Planner",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- seed_safe_cut_ready_count: `{summary['seed_safe_cut_ready_count']}`",
        f"- gate_ready_package_count: `{summary['gate_ready_package_count']}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        "",
        "## Micro Package Queue",
        "",
        "| Package | Adds | Status | Trigger Count | Required Cuts |",
        "| --- | --- | --- | ---: | ---: |",
    ]
    for row in payload["micro_package_queue"]:
        lines.append(
            "| {key} | {adds} | `{status}` | {triggers} | {cuts} |".format(
                key=row["package_key"],
                adds=", ".join(row["adds"]),
                status=row["status"],
                triggers=row["natural_trigger_count"],
                cuts=row["required_cut_count"],
            )
        )
    lines.extend(["", "## Candidate Cards", "", "| Card | Decision | Trigger Count | Events |", "| --- | --- | ---: | ---: |"])
    for row in payload["candidate_cards"]:
        lines.append(
            f"| {row['card_name']} | `{row['decision']}` | {row['natural_trigger_count']} | {row['natural_event_count']} |"
        )
    lines.extend(["", "## Cut Context", ""])
    context = payload["blocked_cut_context"]
    lines.append(f"- seed_safe_cuts: `{json.dumps(context['seed_safe_cuts'])}`")
    lines.append(f"- same_lane_only_cut_cards: `{json.dumps(context['same_lane_only_cut_cards'])}`")
    lines.append(f"- protected_anchor_cuts: `{json.dumps(context['protected_anchor_cuts'])}`")
    lines.extend(["", "## External Support", ""])
    for source in payload["external_support"]:
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
    parser.add_argument("--pressure-decision", type=Path, default=DEFAULT_PRESSURE_DECISION)
    parser.add_argument("--seed-safe", type=Path, default=DEFAULT_SEED_SAFE)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_plan(
        pressure_decision=read_json(args.pressure_decision),
        seed_safe_report=read_json(args.seed_safe),
        pressure_path=args.pressure_decision,
        seed_safe_path=args.seed_safe,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
