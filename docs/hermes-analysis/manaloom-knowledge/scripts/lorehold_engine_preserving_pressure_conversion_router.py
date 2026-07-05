#!/usr/bin/env python3
"""Route engine-preserving pressure/conversion lessons for Lorehold 607.

This is read-only deckbuilding evidence. It consumes the current pressure,
cut-pool, trace, and Storm-Kiln decision artifacts, then decides whether
Guttersnipe, Storm-Kiln Artist, or the pair is a real next deck action.
External deckbuilding support can raise learning priority, but it cannot
override protected 607 cuts, prior rejects, missing hypothesis rows, or missing
direct battle proof.
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_YOUNG_TRACE = (
    REPORT_DIR / "lorehold_young_pyromancer_pressure_window_trace_synthesis_20260705_current_relearn.json"
)
DEFAULT_PACKAGE_ROUTER = (
    REPORT_DIR / "lorehold_pressure_package_size_router_20260705_current_relearn.json"
)
DEFAULT_PRESSURE_CONTRACT = (
    REPORT_DIR / "lorehold_pressure_safe_spell_payoff_contract_20260705_current_relearn.json"
)
DEFAULT_CUT_POOL = (
    REPORT_DIR / "lorehold_pressure_safe_cut_pool_resolver_20260705_current_relearn.json"
)
DEFAULT_SPELL_PRESSURE_TRACE = REPORT_DIR / "lorehold_spell_pressure_trace_miner_20260704_current.json"
DEFAULT_MIRACLE_TRACE = REPORT_DIR / "lorehold_miracle_trace_failure_miner_20260704_current.json"
DEFAULT_CLOSING_TRACE = REPORT_DIR / "lorehold_closing_window_trace_miner_20260704_role_tag_repair.json"
DEFAULT_STORM_KILN_DECISION = REPORT_DIR / "lorehold_storm_kiln_arcane_runtime_decision_20260630.md"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_engine_preserving_pressure_conversion_router_20260705_current_relearn"
)

ROUTE_DEFINITIONS = [
    {
        "route_key": "guttersnipe_noncombat_spell_pressure",
        "adds": ["Guttersnipe"],
        "lane": "noncombat_spell_pressure",
        "learning_priority": 70,
        "external_value": (
            "Turns each instant/sorcery chain into direct table pressure; useful only "
            "if it preserves topdeck, miracle, and spell-volume floors."
        ),
    },
    {
        "route_key": "storm_kiln_artist_mana_conversion",
        "adds": ["Storm-Kiln Artist"],
        "lane": "spell_chain_mana_conversion",
        "learning_priority": 58,
        "external_value": (
            "Converts instant/sorcery casts and copies into Treasures, extending "
            "large spell turns; prior internal evidence forbids treating it as a "
            "generic Arcane Signet replacement."
        ),
    },
    {
        "route_key": "guttersnipe_storm_kiln_engine_preserving_pair",
        "adds": ["Guttersnipe", "Storm-Kiln Artist"],
        "lane": "engine_preserving_pressure_conversion_pair",
        "learning_priority": 92,
        "external_value": (
            "Combines noncombat damage with mana conversion so spell volume can "
            "become both pressure and follow-up mana without returning to broad "
            "token-pressure shells."
        ),
    },
]

EXTERNAL_SUPPORT = [
    {
        "source": "EDHREC Lorehold core spellslinger",
        "url": "https://edhrec.com/commanders/lorehold-the-historian/core/spellslinger",
        "learning": (
            "Public Lorehold shells remain in topdeck/spellslinger/discard lanes; "
            "pressure additions must preserve those axes."
        ),
    },
    {
        "source": "Commander Spellbook Storm-Kiln Artist + Haze of Rage",
        "url": "https://commanderspellbook.com/combo/3940-5195/",
        "learning": (
            "Storm-Kiln can convert storm/copy chains into Treasure and magecraft "
            "loops, so it is a real conversion card rather than filler ramp."
        ),
    },
    {
        "source": "GameTyrant Lorehold deck tech",
        "url": "https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech",
        "learning": (
            "Guttersnipe provides direct spell damage and Storm-Kiln supports big "
            "spell turns, but both belong behind the core topdeck/miracle engine."
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
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


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


def package_key(adds: Sequence[str]) -> str:
    suffix = "_".join(
        name.lower().replace("'", "").replace(",", "").replace(" ", "_").replace("-", "_")
        for name in adds
    )
    return f"pressure_{len(adds)}_card_{suffix}"


def card_rows(contract_report: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for row in as_list(contract_report.get("primary_package_preflight")):
        if isinstance(row, Mapping) and row.get("card_name"):
            rows[str(row["card_name"])] = dict(row)
    return rows


def package_rows(package_report: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for row in as_list(package_report.get("packages")):
        if isinstance(row, Mapping) and row.get("package_key"):
            rows[str(row["package_key"])] = dict(row)
    return rows


def card_overlay(card: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(card.get("hypothesis_queue_overlay"))


def card_readiness_blockers(card: Mapping[str, Any]) -> list[str]:
    blockers: list[str] = []
    if card.get("preflight_status") != "pass":
        blockers.append("local_preflight_not_pass")
    overlay = card_overlay(card)
    if overlay.get("hypothesis_queue_status") != "present":
        blockers.append("missing_current_hypothesis_queue")
    if overlay.get("readiness_status") == "blocked_prior_reject":
        blockers.append("blocked_prior_reject")
    if not overlay.get("natural_gate_ready"):
        blockers.append("no_card_level_natural_gate_ready")
    return blockers


def storm_decision_status(markdown: str) -> str:
    match = re.search(r"status:\s*`([^`]+)`", markdown)
    return match.group(1) if match else ""


def storm_runtime_signal(markdown: str) -> dict[str, Any]:
    status = storm_decision_status(markdown)
    return {
        "decision_status": status,
        "has_real_positive_signal": "real positive signal" in markdown,
        "arcane_signet_swap_rejected": (
            "rejected_for_deck_promotion_pressure_regression" in status
            or "Do not promote this swap" in markdown
        ),
        "winota_regression_documented": "Winota, Joiner of Forces" in markdown,
        "treasure_events_documented": "treasure_created:Storm-Kiln Artist" in markdown,
    }


def pressure_card_results(spell_summary: Mapping[str, Any]) -> dict[str, set[str]]:
    by_result = as_dict(spell_summary.get("pressure_cards_by_result"))
    results: dict[str, set[str]] = {}
    for result, cards in by_result.items():
        for card in as_list(cards):
            results.setdefault(str(card), set()).add(str(result))
    return results


def route_trace_blockers(
    *,
    adds: Sequence[str],
    spell_summary: Mapping[str, Any],
    storm_signal: Mapping[str, Any],
    miracle_flags: set[str],
) -> list[str]:
    blockers: list[str] = []
    card_results = pressure_card_results(spell_summary)
    tested_cards = {str(card) for card in as_list(spell_summary.get("tested_pressure_cards"))}

    if "Guttersnipe" in adds:
        if "Guttersnipe" in tested_cards and "win" not in card_results.get("Guttersnipe", set()):
            blockers.append("no_current_positive_guttersnipe_trace")
        if "pressure_causality_unproven" in miracle_flags:
            blockers.append("pressure_causality_unproven")

    if "Storm-Kiln Artist" in adds:
        if storm_signal.get("arcane_signet_swap_rejected"):
            blockers.append("storm_kiln_arcane_signet_swap_rejected")
        if "pressure_conversion_unproven" in miracle_flags:
            blockers.append("pressure_conversion_unproven")
        if "fast_pressure_slice_not_protected" in miracle_flags:
            blockers.append("fast_pressure_slice_not_protected")

    return blockers


def route_status(
    *,
    route_key: str,
    adds: Sequence[str],
    package_row: Mapping[str, Any],
    blockers: Sequence[str],
) -> tuple[str, str]:
    blocker_set = set(blockers)
    if package_row.get("gate_ready") and not blocker_set:
        return (
            "engine_preserving_pressure_conversion_gate_candidate_requires_structure_matrix",
            "run_structure_matrix_then_equal_gate_with_direct_guttersnipe_or_storm_kiln_events",
        )
    if package_row.get("diagnostic_only_available") and "blocked_prior_reject" not in blocker_set:
        return (
            "engine_preserving_pressure_conversion_diagnostic_only_no_promotion",
            "run_non_deck_forced_diagnostic_only_preserving_607_engine_metrics",
        )
    if route_key == "guttersnipe_storm_kiln_engine_preserving_pair":
        return (
            "best_next_learning_route_contract_required_no_deck_action",
            "write_hypothesis_contract_and_find_two_seed_safe_same_lane_cuts_before_any_battle",
        )
    if "Storm-Kiln Artist" in adds and (
        "blocked_prior_reject" in blocker_set or "storm_kiln_arcane_signet_swap_rejected" in blocker_set
    ):
        return (
            "blocked_prior_reject_engine_signal_requires_new_package",
            "do_not_retest_as_arcane_signet_swap_only_revisit_with_pressure_safe_package",
        )
    if "Guttersnipe" in adds and "missing_current_hypothesis_queue" in blocker_set:
        return (
            "research_candidate_missing_hypothesis_and_cut",
            "add_only_to_hypothesis_contract_after_named_safe_cut_or_non_deck_diagnostic",
        )
    return (
        "blocked_current_607_protected",
        "preserve_607_and_mine_more_trace_or_cut_evidence",
    )


def build_route_row(
    *,
    definition: Mapping[str, Any],
    cards: Mapping[str, Mapping[str, Any]],
    packages: Mapping[str, Mapping[str, Any]],
    spell_summary: Mapping[str, Any],
    miracle_flags: set[str],
    storm_signal: Mapping[str, Any],
) -> dict[str, Any]:
    adds = [str(card) for card in as_list(definition.get("adds"))]
    pkey = package_key(adds)
    package_row = packages.get(pkey, {})
    card_blockers: list[str] = []
    card_evidence: list[dict[str, Any]] = []
    for name in adds:
        card = cards.get(name, {})
        blockers = card_readiness_blockers(card)
        card_blockers.extend(blockers)
        overlay = card_overlay(card)
        card_evidence.append(
            {
                "card_name": name,
                "preflight_status": card.get("preflight_status") or "missing",
                "role": card.get("role") or "",
                "value_test": card.get("value_test") or "",
                "hypothesis_queue_status": overlay.get("hypothesis_queue_status") or "",
                "readiness_status": overlay.get("readiness_status") or "",
                "natural_gate_ready": bool(overlay.get("natural_gate_ready")),
                "card_blockers": blockers,
            }
        )
    package_blockers = [str(item) for item in as_list(package_row.get("blockers"))]
    trace_blockers = route_trace_blockers(
        adds=adds,
        spell_summary=spell_summary,
        storm_signal=storm_signal,
        miracle_flags=miracle_flags,
    )
    blockers = sorted(set(card_blockers + package_blockers + trace_blockers))
    status, next_action = route_status(
        route_key=str(definition.get("route_key") or ""),
        adds=adds,
        package_row=package_row,
        blockers=blockers,
    )
    return {
        "route_key": definition.get("route_key") or "",
        "adds": adds,
        "lane": definition.get("lane") or "",
        "external_value": definition.get("external_value") or "",
        "learning_priority": as_int(definition.get("learning_priority")),
        "required_cut_count": as_int(package_row.get("required_cut_count")) or len(adds),
        "package_key": pkey,
        "package_status": package_row.get("status") or "missing_package_router_row",
        "available_gate_ready_cut_count": as_int(package_row.get("available_gate_ready_cut_count")),
        "available_diagnostic_cut_count": as_int(package_row.get("available_diagnostic_cut_count")),
        "contract_natural_gate_ready_count": as_int(
            package_row.get("contract_natural_gate_ready_count")
        ),
        "gate_ready": status
        == "engine_preserving_pressure_conversion_gate_candidate_requires_structure_matrix",
        "diagnostic_only_available": status
        == "engine_preserving_pressure_conversion_diagnostic_only_no_promotion",
        "promotion_allowed": False,
        "status": status,
        "recommended_next_action": next_action,
        "blockers": blockers,
        "card_evidence": card_evidence,
        "storm_runtime_signal": storm_signal if "Storm-Kiln Artist" in adds else {},
    }


def route_sort_key(row: Mapping[str, Any]) -> tuple[int, int, str]:
    status_rank = {
        "engine_preserving_pressure_conversion_gate_candidate_requires_structure_matrix": 0,
        "engine_preserving_pressure_conversion_diagnostic_only_no_promotion": 1,
        "best_next_learning_route_contract_required_no_deck_action": 2,
        "research_candidate_missing_hypothesis_and_cut": 3,
        "blocked_prior_reject_engine_signal_requires_new_package": 4,
        "blocked_current_607_protected": 5,
    }.get(str(row.get("status") or ""), 6)
    return (status_rank, -as_int(row.get("learning_priority")), str(row.get("route_key") or ""))


def build_report(
    *,
    young_trace: Mapping[str, Any],
    package_router: Mapping[str, Any],
    pressure_contract: Mapping[str, Any],
    cut_pool: Mapping[str, Any],
    spell_pressure_trace: Mapping[str, Any],
    miracle_trace: Mapping[str, Any],
    closing_trace: Mapping[str, Any],
    storm_decision_markdown: str,
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    cards = card_rows(pressure_contract)
    packages = package_rows(package_router)
    spell_summary = summary(spell_pressure_trace)
    miracle_summary = summary(miracle_trace)
    closing_summary = summary(closing_trace)
    young_summary = summary(young_trace)
    cut_summary = summary(cut_pool)
    miracle_flags = {str(flag) for flag in as_list(miracle_summary.get("blocking_failure_flags"))}
    storm_signal = storm_runtime_signal(storm_decision_markdown)
    routes = [
        build_route_row(
            definition=definition,
            cards=cards,
            packages=packages,
            spell_summary=spell_summary,
            miracle_flags=miracle_flags,
            storm_signal=storm_signal,
        )
        for definition in ROUTE_DEFINITIONS
    ]
    routes.sort(key=route_sort_key)
    gate_ready = [row for row in routes if row["gate_ready"]]
    diagnostic_ready = [row for row in routes if row["diagnostic_only_available"]]
    best_route = routes[0] if routes else {}
    if gate_ready:
        decision_status = "engine_preserving_pressure_conversion_gate_candidate"
        next_action = "run_structure_matrix_before_equal_battle_gate"
    elif diagnostic_ready:
        decision_status = "engine_preserving_pressure_conversion_diagnostic_only"
        next_action = "run_non_deck_forced_diagnostic_no_promotion"
    else:
        decision_status = "engine_preserving_pressure_conversion_not_gate_ready_keep_607"
        next_action = "build_engine_preserving_hypothesis_contract_and_find_named_safe_cuts"

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_engine_preserving_pressure_conversion_router",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "summary": {
            "decision_status": decision_status,
            "route_count": len(routes),
            "gate_ready_route_count": len(gate_ready),
            "diagnostic_ready_route_count": len(diagnostic_ready),
            "promotion_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "ready_deck_change_count": 0,
            "best_next_learning_route": best_route.get("route_key") or "",
            "best_next_learning_status": best_route.get("status") or "",
            "gate_ready_cut_count": as_int(cut_summary.get("gate_ready_cut_count")),
            "diagnostic_cut_count": as_int(
                as_dict(cut_pool.get("diagnostic_tradeoff_cut_plan")).get(
                    "eligible_diagnostic_cut_count"
                )
            ),
            "contract_natural_gate_ready_from_hypothesis_queue": as_int(
                cut_summary.get("contract_natural_gate_ready_from_hypothesis_queue")
            ),
            "young_pyromancer_trace_status": young_trace.get("status") or "",
            "young_pyromancer_seen_only_in_losses": bool(
                young_summary.get("young_pyromancer_seen_only_in_losses")
            ),
            "wins_with_pressure_card_events": as_int(
                spell_summary.get("wins_with_pressure_card_events")
            ),
            "losses_with_pressure_card_events": as_int(
                spell_summary.get("losses_with_pressure_card_events")
            ),
            "miracle_trace_failure_flag_count": len(miracle_flags),
            "closing_window_comparison_count": as_int(closing_summary.get("comparison_count")),
            "avg_607_turn_advantage": closing_summary.get("avg_607_turn_advantage") or 0,
            "storm_kiln_prior_decision_status": storm_signal.get("decision_status") or "",
            "recommended_next_action": next_action,
        },
        "routes": routes,
        "best_next_learning_route": best_route,
        "storm_runtime_signal": storm_signal,
        "external_support": EXTERNAL_SUPPORT,
        "learning_rules": [
            {
                "rule": "external_value_is_priority_not_permission",
                "effect": (
                    "EDHREC, Commander Spellbook, and deck-tech evidence can rank "
                    "cards, but current 607 promotion still requires safe cuts, "
                    "hypothesis readiness, trace proof, and equal battle gates."
                ),
            },
            {
                "rule": "do_not_repeat_storm_kiln_arcane_signet_swap",
                "effect": (
                    "Storm-Kiln has real Treasure-conversion evidence, but its direct "
                    "Arcane Signet swap regressed in the Winota fast-pressure slice."
                ),
            },
            {
                "rule": "guttersnipe_needs_current_trace_contract",
                "effect": (
                    "Guttersnipe is the cleaner noncombat pressure lesson, but it is "
                    "missing the current hypothesis queue and has no positive current "
                    "pressure trace."
                ),
            },
            {
                "rule": "pair_is_learning_route_not_deck_action",
                "effect": (
                    "Guttersnipe plus Storm-Kiln is the next engine-preserving idea to "
                    "formalize, but current cut capacity is zero and 607 remains protected."
                ),
            },
        ],
        "method_notes": [
            "This router does not build, stage, or mutate any decklist.",
            "Deck 607 remains the protected baseline until a route has named safe cuts and passes gates.",
            "The pair route is intentionally ranked as learning priority even while blocked.",
            "A future battle requires direct Guttersnipe damage or Storm-Kiln Treasure events, not only aggregate wins.",
        ],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    lines = [
        "# Lorehold Engine-Preserving Pressure Conversion Router",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Routes evaluated: `{summary_row['route_count']}`",
        f"- Gate-ready routes: `{summary_row['gate_ready_route_count']}`",
        f"- Diagnostic-ready routes: `{summary_row['diagnostic_ready_route_count']}`",
        f"- Gate-ready cut count: `{summary_row['gate_ready_cut_count']}`",
        f"- Hypothesis natural gate-ready count: `{summary_row['contract_natural_gate_ready_from_hypothesis_queue']}`",
        f"- Best next learning route: `{summary_row['best_next_learning_route']}`",
        f"- Best next learning status: `{summary_row['best_next_learning_status']}`",
        f"- Storm-Kiln prior decision: `{summary_row['storm_kiln_prior_decision_status']}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(
        [
            "",
            "## Route Queue",
            "",
            "| Route | Adds | Lane | Required cuts | Status | Blockers | Next action |",
            "| --- | --- | --- | ---: | --- | --- | --- |",
        ]
    )
    for row in as_list(payload.get("routes")):
        lines.append(
            "| {route} | {adds} | {lane} | {cuts} | `{status}` | {blockers} | {action} |".format(
                route=row.get("route_key") or "",
                adds=", ".join(as_list(row.get("adds"))),
                lane=row.get("lane") or "",
                cuts=row.get("required_cut_count") or 0,
                status=row.get("status") or "",
                blockers=", ".join(as_list(row.get("blockers"))) or "-",
                action=row.get("recommended_next_action") or "",
            )
        )
    lines.extend(["", "## Learning Rules", ""])
    for rule in as_list(payload.get("learning_rules")):
        lines.append(f"- `{rule.get('rule')}`: {rule.get('effect')}")
    lines.extend(["", "## External Support", ""])
    for source in as_list(payload.get("external_support")):
        lines.append(f"- `{source.get('source')}`: {source.get('url')} - {source.get('learning')}")
    lines.extend(["", "## Method Notes", ""])
    for note in as_list(payload.get("method_notes")):
        lines.append(f"- {note}")
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
    parser.add_argument("--young-trace", type=Path, default=DEFAULT_YOUNG_TRACE)
    parser.add_argument("--package-router", type=Path, default=DEFAULT_PACKAGE_ROUTER)
    parser.add_argument("--pressure-contract", type=Path, default=DEFAULT_PRESSURE_CONTRACT)
    parser.add_argument("--cut-pool", type=Path, default=DEFAULT_CUT_POOL)
    parser.add_argument("--spell-pressure-trace", type=Path, default=DEFAULT_SPELL_PRESSURE_TRACE)
    parser.add_argument("--miracle-trace", type=Path, default=DEFAULT_MIRACLE_TRACE)
    parser.add_argument("--closing-trace", type=Path, default=DEFAULT_CLOSING_TRACE)
    parser.add_argument("--storm-kiln-decision", type=Path, default=DEFAULT_STORM_KILN_DECISION)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "young_trace": args.young_trace,
        "package_router": args.package_router,
        "pressure_contract": args.pressure_contract,
        "cut_pool": args.cut_pool,
        "spell_pressure_trace": args.spell_pressure_trace,
        "miracle_trace": args.miracle_trace,
        "closing_trace": args.closing_trace,
        "storm_kiln_decision": args.storm_kiln_decision,
    }
    payload = build_report(
        young_trace=read_json(args.young_trace),
        package_router=read_json(args.package_router),
        pressure_contract=read_json(args.pressure_contract),
        cut_pool=read_json(args.cut_pool),
        spell_pressure_trace=read_json(args.spell_pressure_trace),
        miracle_trace=read_json(args.miracle_trace),
        closing_trace=read_json(args.closing_trace),
        storm_decision_markdown=read_text(args.storm_kiln_decision),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
