#!/usr/bin/env python3
"""Route the next Lorehold learning step after mana-base diagnostics closed.

This report is deliberately not a deck generator. It consumes the current
internal evidence, folds in a small reviewed external-source snapshot, and
decides which learning work is allowed before any new natural battle gate.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_MANA_BASE = REPORT_DIR / "lorehold_mana_base_decision_integrator_20260705_after_plateau_turbulent_current.json"
DEFAULT_HYPOTHESIS_QUEUE = REPORT_DIR / "lorehold_hypothesis_queue_from_value_model_20260705_current.json"
DEFAULT_DIAGNOSTIC_PLANNER = REPORT_DIR / "lorehold_diagnostic_contract_planner_20260704_current.json"
DEFAULT_PRESSURE_MICRO = REPORT_DIR / "lorehold_pressure_micro_package_planner_20260704_current.json"
DEFAULT_PRESSURE_CUT_POOL = REPORT_DIR / "lorehold_pressure_safe_cut_pool_resolver_20260704_current.json"
DEFAULT_EXTERNAL_SHELL = REPORT_DIR / "lorehold_external_shell_gate_synthesis_20260704_current.json"
DEFAULT_PRESSURE_TRADEOFF = REPORT_DIR / "lorehold_pressure_tradeoff_decision_synthesis_20260704_current.json"
DEFAULT_SPELL_PRESSURE_TOPDECK = REPORT_DIR / "lorehold_spell_pressure_topdeck_decision_20260704_current.json"
DEFAULT_PROMOTION_READINESS = REPORT_DIR / "lorehold_promotion_readiness_synthesis_20260704_pressure_micro_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_post_mana_base_learning_router_20260705_current"


EXTERNAL_SOURCE_SNAPSHOT = [
    {
        "source_key": "edhrec_lorehold_optimized_discard_20260705",
        "url": "https://edhrec.com/commanders/lorehold-the-historian/optimized/discard",
        "learning": (
            "Current EDHREC bracket-filtered Lorehold optimized discard page keeps "
            "the commander framed as spellslinger, topdeck, combo, and discard."
        ),
        "route_effect": "supports_607_plan_and_pressure_package_research",
    },
    {
        "source_key": "edhrec_lorehold_treasure_20260705",
        "url": "https://edhrec.com/commanders/lorehold-the-historian/treasure",
        "learning": (
            "The Treasure page surfaces Scroll Rack, Library of Leng, Storm-Kiln "
            "Artist, Smothering Tithe, Teferi's Protection, and Jeska's Will as "
            "relevant signals, which supports pressure/treasure research without "
            "making any one card automatic."
        ),
        "route_effect": "supports_storm_kiln_pressure_treasure_research",
    },
    {
        "source_key": "edhrec_lorehold_budget_miracles_20260705",
        "url": "https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget",
        "learning": (
            "The budget miracle article emphasizes high instant/sorcery density, "
            "spell-lands/MDFCs, topdeck setup, protection, and Storm-Kiln Artist."
        ),
        "route_effect": "supports_miracle_density_and_topdeck_floor_protection",
    },
    {
        "source_key": "coolstuffinc_lorehold_pressure_closure_20260705",
        "url": "https://www.coolstuffinc.com/a/stephenjohnson-04202026-lorehold-the-historian-commander",
        "learning": (
            "The article flags the need for topdeck manipulation, protection, and "
            "actual closing pressure; it treats token/combat and combo as alternate "
            "directions rather than generic upgrades."
        ),
        "route_effect": "supports_pressure_closure_but_requires_separate_intent_or_safe_cuts",
    },
    {
        "source_key": "commander_spellbook_storm_kiln_haze_20260705",
        "url": "https://commanderspellbook.com/combo/3940-5195/",
        "learning": (
            "Storm-Kiln Artist plus Haze of Rage is a red legal combo lane with "
            "infinite Treasure/storm/magecraft implications, but it is package "
            "research until runtime, cut, and battle evidence exist."
        ),
        "route_effect": "opens_combo_package_research_not_current_607_promotion",
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


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def get_summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    summary = payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {}
    return dict(summary)


def evidence_value(summary: Mapping[str, Any], key: str) -> Any:
    return summary.get(key)


def status_counts(*payloads: Mapping[str, Any]) -> dict[str, int]:
    counter: Counter[str] = Counter()
    for payload in payloads:
        status = str(payload.get("status") or "")
        if status:
            counter[status] += 1
        summary = get_summary(payload)
        decision_status = str(summary.get("decision_status") or "")
        if decision_status:
            counter[decision_status] += 1
    return dict(sorted(counter.items()))


def route_items(
    *,
    mana_base_summary: Mapping[str, Any],
    hypothesis_summary: Mapping[str, Any],
    diagnostic_summary: Mapping[str, Any],
    pressure_micro_summary: Mapping[str, Any],
    pressure_cut_summary: Mapping[str, Any],
    external_shell_summary: Mapping[str, Any],
    pressure_tradeoff_summary: Mapping[str, Any],
    spell_pressure_summary: Mapping[str, Any],
) -> list[dict[str, Any]]:
    mana_base_open = as_int(mana_base_summary.get("eligible_model_ready_pair_count")) > 0
    natural_gate_ready = as_int(hypothesis_summary.get("natural_gate_ready_count")) > 0
    pressure_gate_ready = as_int(pressure_micro_summary.get("gate_ready_package_count")) > 0
    seed_safe_cuts = as_int(pressure_micro_summary.get("seed_safe_cut_ready_count"))
    cut_pool_ready = bool(pressure_cut_summary.get("gate_ready_plan_complete"))
    promotable_shells = as_int(external_shell_summary.get("promotable_shell_count"))
    diagnostic_tradeoff = bool(pressure_cut_summary.get("diagnostic_tradeoff_plan_available"))
    pressure_smoke_positive = as_int(spell_pressure_summary.get("aggregate_delta_wins")) > 0

    routes: list[dict[str, Any]] = []
    routes.append(
        {
            "route_key": "close_simple_mana_base_swaps",
            "priority": "P0_blocked",
            "allowed_now": False,
            "natural_battle_allowed": False,
            "reason": (
                "The current mana-base model-ready queue has no eligible pair left."
                if not mana_base_open
                else "A mana-base pair remains open and must use materialization/preflight before battle."
            ),
            "required_evidence_before_reopen": [
                "new material external or trace evidence changes the safe-cut pool",
                "candidate is materially different from the two rejected Plateau pairs",
                "preflight proves a copied candidate DB, not source DB mutation",
            ],
        }
    )
    routes.append(
        {
            "route_key": "build_pressure_safe_cut_expansion_model",
            "priority": "P1_next",
            "allowed_now": not cut_pool_ready and diagnostic_tradeoff,
            "natural_battle_allowed": False,
            "reason": (
                "External sources and internal traces both support pressure/treasure learning, "
                "but the current resolver has zero seed-safe cuts. The next valid work is "
                "to expand cut evidence, not to battle a new package."
            ),
            "supporting_internal_facts": {
                "seed_safe_cut_ready_count": seed_safe_cuts,
                "gate_ready_package_count": as_int(pressure_micro_summary.get("gate_ready_package_count")),
                "diagnostic_tradeoff_plan_available": diagnostic_tradeoff,
                "natural_trigger_cards": pressure_micro_summary.get("natural_trigger_cards") or [],
            },
            "required_evidence_before_battle": [
                "named same-lane or package-level cut plan",
                "protected 607 anchors unchanged",
                "miracle/topdeck floor preflight",
                "direct pressure card access/cast/trigger evidence",
            ],
        }
    )
    routes.append(
        {
            "route_key": "storm_kiln_haze_combo_research",
            "priority": "P2_research",
            "allowed_now": True,
            "natural_battle_allowed": False,
            "reason": (
                "Current external combo evidence makes Storm-Kiln plus Haze of Rage worth "
                "researching, but it must be treated as a package lane with runtime and cut "
                "checks, not as an automatic add."
            ),
            "required_evidence_before_battle": [
                "Scryfall/backend legality for all package cards",
                "runtime support or focused rule proof for the combo pieces",
                "safe cut plan that does not remove Bender's Waterskin or topdeck/miracle anchors",
                "structure matrix showing the shell still matches Lorehold's plan",
            ],
        }
    )
    routes.append(
        {
            "route_key": "full_shell_smoke_positive_followup",
            "priority": "P2_research",
            "allowed_now": pressure_smoke_positive and promotable_shells == 0,
            "natural_battle_allowed": False,
            "reason": (
                "Some from-scratch pressure shells produced smoke wins when 607 also failed, "
                "but the decision reports block promotion because structural rank, head-to-head, "
                "miracle floor, pressure exposure, or cut safety were insufficient."
            ),
            "supporting_internal_facts": {
                "pressure_tradeoff_promotion_allowed": bool(pressure_tradeoff_summary.get("promotion_allowed")),
                "spell_pressure_aggregate_delta_wins": spell_pressure_summary.get("aggregate_delta_wins"),
                "promotable_shell_count": promotable_shells,
            },
            "required_evidence_before_battle": [
                "new shell must declare archetype contract",
                "compare against 607 with equal opponents and seeds",
                "show pressure package was actually exercised",
                "no regression in miracle/topdeck/Lorehold floor",
            ],
        }
    )
    routes.append(
        {
            "route_key": "natural_gate_any_watchlist_card",
            "priority": "P0_blocked",
            "allowed_now": natural_gate_ready or pressure_gate_ready,
            "natural_battle_allowed": natural_gate_ready or pressure_gate_ready,
            "reason": (
                "No current hypothesis has both safe-cut proof and miracle-access floor proof."
                if not natural_gate_ready and not pressure_gate_ready
                else "A watchlist route reports gate-ready status and should be separately preflighted."
            ),
            "required_evidence_before_battle": [
                "safe-cut model says gate-ready",
                "miracle-access-first preflight passes",
                "exact prior rejects do not block the add/cut signature",
            ],
        }
    )
    return routes


def build_payload(
    *,
    mana_base_path: Path = DEFAULT_MANA_BASE,
    hypothesis_queue_path: Path = DEFAULT_HYPOTHESIS_QUEUE,
    diagnostic_planner_path: Path = DEFAULT_DIAGNOSTIC_PLANNER,
    pressure_micro_path: Path = DEFAULT_PRESSURE_MICRO,
    pressure_cut_pool_path: Path = DEFAULT_PRESSURE_CUT_POOL,
    external_shell_path: Path = DEFAULT_EXTERNAL_SHELL,
    pressure_tradeoff_path: Path = DEFAULT_PRESSURE_TRADEOFF,
    spell_pressure_topdeck_path: Path = DEFAULT_SPELL_PRESSURE_TOPDECK,
    promotion_readiness_path: Path = DEFAULT_PROMOTION_READINESS,
) -> dict[str, Any]:
    mana_base = read_json(mana_base_path)
    hypothesis_queue = read_json(hypothesis_queue_path)
    diagnostic_planner = read_json(diagnostic_planner_path)
    pressure_micro = read_json(pressure_micro_path)
    pressure_cut_pool = read_json(pressure_cut_pool_path)
    external_shell = read_json(external_shell_path)
    pressure_tradeoff = read_json(pressure_tradeoff_path)
    spell_pressure_topdeck = read_json(spell_pressure_topdeck_path)
    promotion_readiness = read_json(promotion_readiness_path)

    mana_base_summary = get_summary(mana_base)
    hypothesis_summary = get_summary(hypothesis_queue)
    diagnostic_summary = get_summary(diagnostic_planner)
    pressure_micro_summary = get_summary(pressure_micro)
    pressure_cut_summary = get_summary(pressure_cut_pool)
    external_shell_summary = get_summary(external_shell)
    pressure_tradeoff_summary = get_summary(pressure_tradeoff)
    spell_pressure_summary = get_summary(spell_pressure_topdeck)
    promotion_summary = get_summary(promotion_readiness)

    routes = route_items(
        mana_base_summary=mana_base_summary,
        hypothesis_summary=hypothesis_summary,
        diagnostic_summary=diagnostic_summary,
        pressure_micro_summary=pressure_micro_summary,
        pressure_cut_summary=pressure_cut_summary,
        external_shell_summary=external_shell_summary,
        pressure_tradeoff_summary=pressure_tradeoff_summary,
        spell_pressure_summary=spell_pressure_summary,
    )
    next_route = next((row for row in routes if row["priority"] == "P1_next" and row["allowed_now"]), None)
    status = (
        "post_mana_base_route_cut_safety_expansion_required"
        if next_route
        else "post_mana_base_no_allowed_next_route"
    )
    natural_gate_allowed = any(bool(row.get("natural_battle_allowed")) for row in routes)
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_post_mana_base_learning_router",
        "status": status,
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": [
            rel(mana_base_path),
            rel(hypothesis_queue_path),
            rel(diagnostic_planner_path),
            rel(pressure_micro_path),
            rel(pressure_cut_pool_path),
            rel(external_shell_path),
            rel(pressure_tradeoff_path),
            rel(spell_pressure_topdeck_path),
            rel(promotion_readiness_path),
        ],
        "external_source_snapshot": EXTERNAL_SOURCE_SNAPSHOT,
        "summary": {
            "current_best_baseline": "deck_607",
            "promotion_allowed": False,
            "natural_battle_allowed_now": natural_gate_allowed,
            "mana_base_eligible_pair_count": as_int(mana_base_summary.get("eligible_model_ready_pair_count")),
            "natural_gate_ready_count": as_int(hypothesis_summary.get("natural_gate_ready_count")),
            "pressure_gate_ready_package_count": as_int(pressure_micro_summary.get("gate_ready_package_count")),
            "seed_safe_cut_ready_count": as_int(pressure_micro_summary.get("seed_safe_cut_ready_count")),
            "promotable_external_shell_count": as_int(external_shell_summary.get("promotable_shell_count")),
            "ready_deck_change_count": as_int(promotion_summary.get("gate_ready_candidate_count")),
            "recommended_next_route": next_route["route_key"] if next_route else None,
            "recommended_next_artifact": "lorehold_pressure_safe_cut_expansion_model",
        },
        "internal_status_counts": status_counts(
            mana_base,
            hypothesis_queue,
            pressure_micro,
            pressure_tradeoff,
            spell_pressure_topdeck,
            promotion_readiness,
        ),
        "routes": routes,
        "decision": {
            "current_best_baseline": "deck_607",
            "promotion_allowed": False,
            "reason": (
                "Current internal evidence has no gate-ready candidate after mana-base closure. "
                "External evidence supports pressure/treasure and combo-package research, but the "
                "active blocker is still cut safety and protected-anchor preservation."
            ),
            "next_action": (
                "build_pressure_safe_cut_expansion_model"
                if next_route
                else "stop_before_battle_until_a_route_has_safe_cuts"
            ),
            "blocked_actions": [
                "do_not_retest_exact_plateau_pairs",
                "do_not_run_natural_gate_without_safe_cut_and_miracle_access_preflight",
                "do_not_promote_full_shell_smoke_results",
                "do_not_cut_protected_607_anchors_for_global_staples",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Post-Mana-Base Learning Router",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- current_best_baseline: `{summary['current_best_baseline']}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- natural_battle_allowed_now: `{str(summary['natural_battle_allowed_now']).lower()}`",
        f"- mana_base_eligible_pair_count: `{summary['mana_base_eligible_pair_count']}`",
        f"- natural_gate_ready_count: `{summary['natural_gate_ready_count']}`",
        f"- seed_safe_cut_ready_count: `{summary['seed_safe_cut_ready_count']}`",
        f"- promotable_external_shell_count: `{summary['promotable_external_shell_count']}`",
        f"- recommended_next_route: `{summary['recommended_next_route']}`",
        f"- recommended_next_artifact: `{summary['recommended_next_artifact']}`",
        "",
        "## Routes",
        "",
        "| Priority | Route | Allowed Now | Natural Battle | Reason |",
        "| --- | --- | --- | --- | --- |",
    ]
    for row in payload.get("routes") or []:
        lines.append(
            "| `{priority}` | `{route}` | `{allowed}` | `{battle}` | {reason} |".format(
                priority=row.get("priority"),
                route=row.get("route_key"),
                allowed=str(row.get("allowed_now")).lower(),
                battle=str(row.get("natural_battle_allowed")).lower(),
                reason=row.get("reason"),
            )
        )
    lines.extend(["", "## External Evidence", ""])
    for row in payload.get("external_source_snapshot") or []:
        lines.append(f"- `{row['source_key']}`: {row['learning']} Source: {row['url']}")
    lines.extend(
        [
            "",
            "## Decision",
            "",
            f"- current_best_baseline: `{payload['decision']['current_best_baseline']}`",
            f"- promotion_allowed: `{str(payload['decision']['promotion_allowed']).lower()}`",
            f"- reason: {payload['decision']['reason']}",
            f"- next_action: `{payload['decision']['next_action']}`",
            f"- blocked_actions: `{json.dumps(payload['decision']['blocked_actions'])}`",
        ]
    )
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
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    parser.add_argument("--mana-base", type=Path, default=DEFAULT_MANA_BASE)
    parser.add_argument("--hypothesis-queue", type=Path, default=DEFAULT_HYPOTHESIS_QUEUE)
    parser.add_argument("--diagnostic-planner", type=Path, default=DEFAULT_DIAGNOSTIC_PLANNER)
    parser.add_argument("--pressure-micro", type=Path, default=DEFAULT_PRESSURE_MICRO)
    parser.add_argument("--pressure-cut-pool", type=Path, default=DEFAULT_PRESSURE_CUT_POOL)
    parser.add_argument("--external-shell", type=Path, default=DEFAULT_EXTERNAL_SHELL)
    parser.add_argument("--pressure-tradeoff", type=Path, default=DEFAULT_PRESSURE_TRADEOFF)
    parser.add_argument("--spell-pressure-topdeck", type=Path, default=DEFAULT_SPELL_PRESSURE_TOPDECK)
    parser.add_argument("--promotion-readiness", type=Path, default=DEFAULT_PROMOTION_READINESS)
    args = parser.parse_args()
    payload = build_payload(
        mana_base_path=args.mana_base,
        hypothesis_queue_path=args.hypothesis_queue,
        diagnostic_planner_path=args.diagnostic_planner,
        pressure_micro_path=args.pressure_micro,
        pressure_cut_pool_path=args.pressure_cut_pool,
        external_shell_path=args.external_shell,
        pressure_tradeoff_path=args.pressure_tradeoff,
        spell_pressure_topdeck_path=args.spell_pressure_topdeck,
        promotion_readiness_path=args.promotion_readiness,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "promotion_allowed": payload["summary"]["promotion_allowed"],
                "recommended_next_route": payload["summary"]["recommended_next_route"],
                "json": rel(json_path),
                "markdown": rel(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
