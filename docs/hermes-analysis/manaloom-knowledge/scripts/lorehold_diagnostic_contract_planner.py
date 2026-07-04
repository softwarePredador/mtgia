#!/usr/bin/env python3
"""Plan the next Lorehold learning diagnostics without mutating deck 607.

The external shell synthesis answers whether a whole shell can replace deck
607. This planner answers the next narrower question: which smaller learning
contract should be designed next, and what card-value criteria must it satisfy
before any battle gate is allowed?
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
DEFAULT_EXTERNAL_RECONCILIATION = (
    REPORT_DIR / "lorehold_external_evidence_reconciler_20260704_current.json"
)
DEFAULT_SHELL_SYNTHESIS = (
    REPORT_DIR / "lorehold_external_shell_gate_synthesis_20260704_current.json"
)
DEFAULT_STEM = "lorehold_diagnostic_contract_planner_20260704_current"

EXTERNAL_REFRESH_SOURCES = [
    {
        "source_key": "draftsim_approach_lapse_risk_refresh",
        "url": "https://draftsim.com/lorehold-approach-combo/",
        "learning": (
            "Approach lines are concrete but telegraphed; the second Approach must "
            "resolve, so protection/permission is part of the test contract."
        ),
    },
    {
        "source_key": "edhrec_lorehold_combo_refresh",
        "url": "https://edhrec.com/combos/lorehold-the-historian",
        "learning": (
            "Lorehold combo evidence clusters around Approach, spell-copy, "
            "Storm-Kiln, Birgi, Breach, token/damage payoff, and topdeck packages."
        ),
    },
    {
        "source_key": "draftsim_lorehold_synergy_refresh",
        "url": "https://draftsim.com/lorehold-the-historian-edh-deck/",
        "learning": (
            "Lorehold synergy must either reward discard/rummage or set up miracle "
            "timing; generic value is lower priority."
        ),
    },
    {
        "source_key": "cardkingdom_lorehold_identity_refresh",
        "url": "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/",
        "learning": (
            "The commander identity is cost reduction, miracle timing, and rummage; "
            "candidate value must be measured against that identity."
        ),
    },
]

SIGNAL_CONTRACT_OVERRIDES = {
    "external_spell_pressure_creature_package": {
        "diagnostic_key": "pressure_safe_spell_payoff_micro_shell",
        "tier": "primary_next_contract",
        "contract_type": "separate_micro_shell",
        "why": (
            "Targets the known pressure/closing-window weakness without asking for "
            "a generic one-for-one cut."
        ),
        "predeclared_requirements": [
            "Preserve the 607 mana, topdeck, miracle, protection, and pressure anchors.",
            "Add only a compact spell-payoff pressure package before expanding the shell.",
            "Require structure matrix alignment before any smoke battle.",
            "Promote only if equal gate ties or beats 607 and Winota does not regress.",
            "Require direct card events for the pressure package before card-level claims.",
        ],
    },
    "external_approach_lapse_deterministic_line": {
        "diagnostic_key": "approach_lapse_permission_diagnostic",
        "tier": "diagnostic_only_until_cut_exists",
        "contract_type": "forced_or_trace_diagnostic",
        "why": (
            "Approach is already a 607 finisher; Lapse tests whether protection of "
            "the second Approach is worth a future slot, but no seed-safe cut exists."
        ),
        "predeclared_requirements": [
            "Do not mutate deck 607.",
            "First verify runtime/card-rule support and card access traces.",
            "Treat forced-access results as learning only, not promotion.",
            "Name a seed-safe same-lane cut before natural battle confirmation.",
        ],
    },
    "external_cedh_fast_mana_engine": {
        "diagnostic_key": "declared_high_power_fast_mana_shell",
        "tier": "later_full_shell_contract",
        "contract_type": "power_bracket_shell",
        "why": (
            "Fast mana is externally strong, but Mana Vault over Bender's Waterskin "
            "already lost, so this must be a declared high-power shell instead of a "
            "607 one-card repair."
        ),
        "predeclared_requirements": [
            "Declare bracket/power target before card selection.",
            "Do not cut Bender's Waterskin as generic ramp.",
            "Preserve pressure-survival and miracle cadence targets.",
            "Require a full structure matrix and equal gate before promotion claims.",
        ],
    },
    "external_discard_reanimator_alt_shell": {
        "diagnostic_key": "discard_reanimator_alt_intent_profile",
        "tier": "alternate_archetype_research",
        "contract_type": "new_intent_profile",
        "why": (
            "This is likely a different Lorehold archetype, not an improvement to "
            "the protected 607 miracle shell."
        ),
        "predeclared_requirements": [
            "Create a separate intent profile before any deck generation.",
            "Do not compare as a 607 replacement until the archetype has its own matrix.",
            "Require recursion payoff telemetry, not only graveyard-card density.",
        ],
    },
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def signal_map(rows: list[Mapping[str, Any]]) -> dict[str, Mapping[str, Any]]:
    return {str(row.get("signal_key") or ""): row for row in rows if row.get("signal_key")}


def strength_points(strength: str) -> int:
    return {
        "high": 4,
        "medium": 3,
        "high_global_low_context": 2,
        "low": 1,
    }.get(strength, 0)


def synthesis_points(status: str) -> int:
    return {
        "partial_or_uncovered_full_shell": 4,
        "blocked_no_named_cut": 3,
        "blocked_by_cut_safety": 1,
        "covered_by_existing_nonpromotable_shell": 0,
        "supports_current_607": 0,
    }.get(status, 1)


def mission_fit_points(signal_key: str, lane: str) -> int:
    if signal_key == "external_spell_pressure_creature_package":
        return 5
    if signal_key == "external_approach_lapse_deterministic_line":
        return 4
    if lane == "early_plan":
        return 2
    if lane == "spell_chain_conversion":
        return 2
    if lane == "graveyard_recursion":
        return 1
    return 1


def risk_penalty(
    signal_key: str,
    synthesis_status: str,
    blockers: list[str],
    known_internal_decisions: list[str],
) -> int:
    penalty = 0
    if synthesis_status == "blocked_by_cut_safety":
        penalty += 4
    if synthesis_status == "covered_by_existing_nonpromotable_shell":
        penalty += 4
    if "prior_internal_reject" in blockers:
        penalty += 2
    if known_internal_decisions:
        penalty += 1
    if signal_key == "external_cedh_fast_mana_engine":
        penalty += 2
    if signal_key == "external_one_ring_value_engine":
        penalty += 3
    if signal_key == "external_approach_lapse_deterministic_line":
        penalty += 2
    return penalty


def testability_points(synthesis_status: str, exact_coverage_count: int) -> int:
    if synthesis_status == "partial_or_uncovered_full_shell":
        return 3
    if synthesis_status == "blocked_no_named_cut":
        return 2
    if exact_coverage_count:
        return 1
    return 0


def build_diagnostic(
    synthesis_row: Mapping[str, Any],
    reconciliation_row: Mapping[str, Any],
) -> dict[str, Any]:
    signal_key = str(synthesis_row.get("signal_key") or "")
    lane = str(synthesis_row.get("lane") or reconciliation_row.get("lane") or "")
    synthesis_status = str(synthesis_row.get("synthesis_status") or "")
    blockers = [str(item) for item in as_list(reconciliation_row.get("blockers"))]
    known_decisions = [
        str(item) for item in as_list(reconciliation_row.get("known_internal_decisions"))
    ]
    external_strength = str(reconciliation_row.get("external_strength") or "")
    exact_coverage_count = int(synthesis_row.get("exact_coverage_count") or 0)
    score_components = {
        "external_strength": strength_points(external_strength),
        "synthesis_openness": synthesis_points(synthesis_status),
        "mission_fit": mission_fit_points(signal_key, lane),
        "testability": testability_points(synthesis_status, exact_coverage_count),
        "risk_penalty": risk_penalty(
            signal_key, synthesis_status, blockers, known_decisions
        ),
    }
    score = (
        score_components["external_strength"]
        + score_components["synthesis_openness"]
        + score_components["mission_fit"]
        + score_components["testability"]
        - score_components["risk_penalty"]
    )
    override = SIGNAL_CONTRACT_OVERRIDES.get(signal_key, {})
    if synthesis_status == "supports_current_607":
        readiness = "support_current_607_no_new_test"
    elif synthesis_status == "blocked_no_named_cut":
        readiness = "research_or_diagnostic_only"
    elif score >= 10:
        readiness = "design_next"
    elif score >= 6:
        readiness = "research_or_diagnostic_only"
    elif synthesis_status == "blocked_by_cut_safety":
        readiness = "blocked_until_cut_safety_changes"
    else:
        readiness = "defer"
    return {
        "signal_key": signal_key,
        "diagnostic_key": override.get("diagnostic_key") or f"{signal_key}_diagnostic",
        "tier": override.get("tier") or readiness,
        "contract_type": override.get("contract_type")
        or str(reconciliation_row.get("contract_path") or ""),
        "lane": lane,
        "synthesis_status": synthesis_status,
        "external_strength": external_strength,
        "cards_checked": synthesis_row.get("cards_checked") or [],
        "best_coverages": synthesis_row.get("best_coverages") or [],
        "score_components": score_components,
        "priority_score": score,
        "readiness": readiness,
        "why": override.get("why") or str(reconciliation_row.get("evidence_summary") or ""),
        "predeclared_requirements": override.get("predeclared_requirements") or [],
        "blockers": blockers,
        "known_internal_decisions": known_decisions,
        "recommended_action": synthesis_row.get("recommended_action") or "",
    }


def card_value_framework() -> list[dict[str, Any]]:
    return [
        {
            "axis": "lands_and_mana_base",
            "current_607_rule": "Preserve the 34-land floor unless a full-shell matrix proves a new curve.",
            "value_test": "Color reliability, commander turn target, untapped sources, and spell-window support beat raw land power.",
            "anti_pattern": "Cut lands or source quality to fit more famous spells before proving curve safety.",
        },
        {
            "axis": "ramp_and_artifacts",
            "current_607_rule": "Separate structural floor ramp from burst/high-power ramp.",
            "value_test": "Ramp must improve Lorehold timing without reducing miracle cadence or pressure survival.",
            "anti_pattern": "Treat Mana Vault, Cloud Key, or another artifact as automatically better than Bender's Waterskin or Arcane Signet.",
        },
        {
            "axis": "staples",
            "current_607_rule": "A staple is a role-floor signal, not deck truth.",
            "value_test": "Global power must survive commander-specific role fit, cut safety, direct use, and equal gate evidence.",
            "anti_pattern": "Force The One Ring or another game changer into 607 after tested cuts already lost.",
        },
        {
            "axis": "synergy_and_combo",
            "current_607_rule": "Synergy must support topdeck/miracle setup, rummage, spell-chain conversion, protection, or pressure repair.",
            "value_test": "A combo line is valuable only if the shell can access it, protect it, and still survive fast pressure.",
            "anti_pattern": "Add Approach/Lapse, Breach, Aetherflux, or token payoffs without a protection/pressure contract.",
        },
        {
            "axis": "cuts",
            "current_607_rule": "No current seed-safe one-for-one cuts are available under the protected 607 contract.",
            "value_test": "Each add needs a same-lane cut or a declared separate shell contract before battle promotion.",
            "anti_pattern": "Use Creative Technique, Bender's Waterskin, Molecule Man, or other protected anchors as generic cuts.",
        },
    ]


def build_report(
    *,
    external_reconciliation: Mapping[str, Any],
    shell_synthesis: Mapping[str, Any],
    external_reconciliation_path: Path,
    shell_synthesis_path: Path,
) -> dict[str, Any]:
    reconciliation_by_signal = signal_map(as_list(external_reconciliation.get("signals")))
    diagnostics = []
    for synthesis_row in as_list(shell_synthesis.get("signals")):
        signal_key = str(synthesis_row.get("signal_key") or "")
        reconciliation_row = reconciliation_by_signal.get(signal_key, {})
        diagnostics.append(build_diagnostic(synthesis_row, reconciliation_row))
    diagnostics.sort(
        key=lambda row: (
            row.get("readiness") != "design_next",
            -int(row.get("priority_score") or 0),
            str(row.get("signal_key") or ""),
        )
    )
    actionable = [
        row
        for row in diagnostics
        if row.get("readiness") in {"design_next", "research_or_diagnostic_only"}
    ]
    readiness_counts = Counter(str(row.get("readiness") or "") for row in diagnostics)
    top = diagnostics[0] if diagnostics else {}
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_diagnostic_contract_planner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "external_reconciliation": rel(external_reconciliation_path),
        "shell_synthesis": rel(shell_synthesis_path),
        "current_champion": "deck_607",
        "summary": {
            "diagnostic_count": len(diagnostics),
            "actionable_learning_count": len(actionable),
            "ready_deck_change_count": 0,
            "readiness_counts": dict(sorted(readiness_counts.items())),
            "top_diagnostic_key": top.get("diagnostic_key") or "",
            "recommended_next_action": (
                "build_pressure_safe_spell_payoff_micro_shell_contract"
                if top.get("diagnostic_key") == "pressure_safe_spell_payoff_micro_shell"
                else "continue_diagnostic_contract_planning"
            ),
            "keep_607_protected": True,
        },
        "card_value_framework": card_value_framework(),
        "ranked_diagnostics": diagnostics,
        "external_refresh_sources": EXTERNAL_REFRESH_SOURCES,
        "method_notes": [
            "This planner is read-only and does not mutate PostgreSQL, SQLite, or deck rows.",
            "Priority score ranks learning value, not permission to change deck 607.",
            "Any natural battle gate still requires a named contract, structure matrix, equal opponent/seed window, and direct card-use evidence.",
            "Forced-access diagnostics remain learning-only unless later natural confirmation passes the Lorehold promotion gate.",
        ],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Diagnostic Contract Planner",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        f"- External reconciliation: `{payload['external_reconciliation']}`",
        f"- Shell synthesis: `{payload['shell_synthesis']}`",
        f"- Current champion: `{payload['current_champion']}`",
        f"- Diagnostics ranked: `{summary['diagnostic_count']}`",
        f"- Actionable learning items: `{summary['actionable_learning_count']}`",
        f"- Ready deck changes: `{summary['ready_deck_change_count']}`",
        f"- Top diagnostic: `{summary['top_diagnostic_key']}`",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        f"- Readiness counts: `{json.dumps(summary['readiness_counts'], sort_keys=True)}`",
        "",
        "## Card Value Framework",
        "",
        "| Axis | Current 607 rule | Value test | Anti-pattern |",
        "| --- | --- | --- | --- |",
    ]
    for row in payload.get("card_value_framework") or []:
        lines.append(
            "| {axis} | {rule} | {test} | {anti} |".format(
                axis=row.get("axis") or "",
                rule=row.get("current_607_rule") or "",
                test=row.get("value_test") or "",
                anti=row.get("anti_pattern") or "",
            )
        )
    lines.extend(
        [
            "",
            "## Ranked Diagnostics",
            "",
            "| Rank | Diagnostic | Readiness | Score | Lane | Cards | Why |",
            "| ---: | --- | --- | ---: | --- | --- | --- |",
        ]
    )
    for index, row in enumerate(payload.get("ranked_diagnostics") or [], 1):
        lines.append(
            "| {rank} | `{diag}` | `{readiness}` | {score} | `{lane}` | {cards} | {why} |".format(
                rank=index,
                diag=row.get("diagnostic_key") or "",
                readiness=row.get("readiness") or "",
                score=row.get("priority_score"),
                lane=row.get("lane") or "",
                cards=", ".join(row.get("cards_checked") or []) or "-",
                why=row.get("why") or "",
            )
        )
    lines.extend(["", "## Next Contract Requirements", ""])
    for row in payload.get("ranked_diagnostics") or []:
        requirements = row.get("predeclared_requirements") or []
        if not requirements:
            continue
        lines.append(f"### `{row.get('diagnostic_key')}`")
        lines.append("")
        for requirement in requirements:
            lines.append(f"- {requirement}")
        lines.append("")
    lines.extend(["## External Refresh Sources", ""])
    for source in payload.get("external_refresh_sources") or []:
        lines.append(
            f"- `{source.get('source_key')}`: {source.get('url')} - {source.get('learning')}"
        )
    lines.extend(["", "## Method Notes", ""])
    for note in payload.get("method_notes") or []:
        lines.append(f"- {note}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--external-reconciliation",
        type=Path,
        default=DEFAULT_EXTERNAL_RECONCILIATION,
    )
    parser.add_argument("--shell-synthesis", type=Path, default=DEFAULT_SHELL_SYNTHESIS)
    parser.add_argument("--stem", default=DEFAULT_STEM)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_report(
        external_reconciliation=read_json(args.external_reconciliation),
        shell_synthesis=read_json(args.shell_synthesis),
        external_reconciliation_path=args.external_reconciliation,
        shell_synthesis_path=args.shell_synthesis,
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
