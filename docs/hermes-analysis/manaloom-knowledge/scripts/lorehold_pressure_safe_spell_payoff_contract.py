#!/usr/bin/env python3
"""Build the Lorehold pressure-safe spell-payoff micro-shell contract.

This is a read-only learning artifact. It turns the diagnostic planner's top
next action into a concrete preflight contract: which pressure payoffs are
known locally, whether they are Commander-legal, whether battle rules exist,
and why deck 607 is still protected until named cuts and a structure matrix
exist.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_KNOWLEDGE_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_DIAGNOSTIC_PLANNER = (
    REPORT_DIR / "lorehold_diagnostic_contract_planner_20260704_current.json"
)
DEFAULT_STEM = "lorehold_pressure_safe_spell_payoff_contract_20260704_current"

PRIMARY_PACKAGE = [
    {
        "card_name": "Monastery Mentor",
        "role": "token_pressure_spell_payoff",
        "value_test": (
            "Converts noncreature spell density into board pressure and blockers; "
            "valuable only if the shell keeps enough cheap spell velocity."
        ),
    },
    {
        "card_name": "Young Pyromancer",
        "role": "low_curve_token_pressure_payoff",
        "value_test": (
            "Adds low-cost pressure absorption and chip pressure from instants and "
            "sorceries without asking the deck to become creature-heavy."
        ),
    },
    {
        "card_name": "Guttersnipe",
        "role": "noncombat_spell_pressure_payoff",
        "value_test": (
            "Turns spell chaining into direct table pressure, but must be measured "
            "against protection and closing-window timing."
        ),
    },
    {
        "card_name": "Storm-Kiln Artist",
        "role": "spell_payoff_mana_extension",
        "value_test": (
            "Extends spell-chain turns through treasure production; prior internal "
            "evidence forbids treating it as a generic Arcane Signet replacement."
        ),
    },
]

SECONDARY_RESEARCH_QUEUE = [
    {
        "card_name": "Goldspan Dragon",
        "reason": "Higher-curve treasure pressure candidate; not part of the first compact package.",
    },
    {
        "card_name": "Dragon's Rage Channeler",
        "reason": "Cheap selection/pressure candidate; requires delirium and topdeck-risk review.",
    },
    {
        "card_name": "Burning Prophet",
        "reason": "Low-curve spell-scry pressure candidate; likely diagnostic only until proven.",
    },
    {
        "card_name": "Velomachus Lorehold",
        "reason": "High-curve spell access threat; likely too slow unless a separate shell proves it.",
    },
]

PROTECTED_607_ANCHORS = [
    "Bender's Waterskin",
    "Victory Chimes",
    "Molecule Man",
    "The Scarlet Witch",
    "The Mind Stone",
    "Insurrection",
    "Storm Herd",
    "Creative Technique",
    "Sensei's Divining Top",
    "Scroll Rack",
    "Land Tax",
    "Approach of the Second Sun",
]

EXTERNAL_PRESSURE_SOURCES = [
    {
        "source_key": "gametyrant_lorehold_deck_tech_pressure_payoffs",
        "url": "https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech",
        "learning": (
            "Public Lorehold pressure advice specifically calls out token and damage "
            "spell payoffs such as Monastery Mentor, Young Pyromancer, Guttersnipe, "
            "and Storm-Kiln Artist."
        ),
    },
    {
        "source_key": "edhrec_core_lorehold_spellslinger",
        "url": "https://edhrec.com/commanders/lorehold-the-historian/core/spellslinger",
        "learning": (
            "The public core page frames Lorehold in Topdeck, Spellslinger, Discard, "
            "and Reanimator lanes, which matches the internal role gates."
        ),
    },
    {
        "source_key": "coolstuffinc_lorehold_2026",
        "url": "https://www.coolstuffinc.com/a/stephenjohnson-04202026-lorehold-the-historian-commander",
        "learning": (
            "Recent public analysis reinforces Lorehold's flying, haste, miracle, "
            "rummage, and possible token-swarm pressure identity."
        ),
    },
    {
        "source_key": "edhrec_miracles_every_turn",
        "url": "https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander",
        "learning": (
            "The commander identity remains miracle timing plus rummage; pressure "
            "cards must not dilute the topdeck/miracle floor."
        ),
    },
]


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


def normalize_name(name: str) -> str:
    return re.sub(r"\s+", " ", name.strip().lower())


def placeholders(values: Sequence[Any]) -> str:
    if not values:
        raise ValueError("at least one value is required")
    return ",".join("?" for _ in values)


def fetch_dicts(
    conn: sqlite3.Connection, sql: str, params: Sequence[Any] = ()
) -> list[dict[str, Any]]:
    conn.row_factory = sqlite3.Row
    return [dict(row) for row in conn.execute(sql, params)]


def candidate_names() -> list[str]:
    names = [str(row["card_name"]) for row in PRIMARY_PACKAGE]
    names.extend(str(row["card_name"]) for row in SECONDARY_RESEARCH_QUEUE)
    return names


def load_db_snapshot(db_path: Path, names: Sequence[str], deck_id: int) -> dict[str, Any]:
    normalized = [normalize_name(name) for name in names]
    lowered = [name.lower() for name in names]
    with sqlite3.connect(db_path) as conn:
        oracle = fetch_dicts(
            conn,
            (
                "SELECT normalized_name, name, mana_cost, color_identity_json, "
                "type_line, oracle_text, cmc, scryfall_id, source, updated_at "
                f"FROM card_oracle_cache WHERE normalized_name IN ({placeholders(normalized)})"
            ),
            normalized,
        )
        legalities = fetch_dicts(
            conn,
            (
                "SELECT card_name, format, status, scryfall_id, synced_at "
                f"FROM card_legalities WHERE lower(card_name) IN ({placeholders(lowered)})"
            ),
            lowered,
        )
        rules = fetch_dicts(
            conn,
            (
                "SELECT normalized_name, logical_rule_key, card_name, source, confidence, "
                "review_status, execution_status, updated_at "
                f"FROM battle_card_rules WHERE normalized_name IN ({placeholders(normalized)})"
            ),
            normalized,
        )
        deck_cards = fetch_dicts(
            conn,
            (
                "SELECT card_name, quantity, functional_tag, type_line, is_commander "
                "FROM deck_cards WHERE deck_id = ?"
            ),
            [deck_id],
        )
    return {
        "knowledge_db": str(db_path),
        "deck_id": deck_id,
        "oracle": oracle,
        "legalities": legalities,
        "battle_rules": rules,
        "deck_cards": deck_cards,
    }


def index_by_normalized(rows: Iterable[Mapping[str, Any]]) -> dict[str, Mapping[str, Any]]:
    return {
        normalize_name(str(row.get("normalized_name") or row.get("name") or row.get("card_name") or "")): row
        for row in rows
        if row.get("normalized_name") or row.get("name") or row.get("card_name")
    }


def legal_status_for(
    legalities: Iterable[Mapping[str, Any]], card_name: str, fmt: str = "commander"
) -> str:
    wanted = card_name.lower()
    for row in legalities:
        if str(row.get("card_name") or "").lower() == wanted and row.get("format") == fmt:
            return str(row.get("status") or "")
    return "missing"


def rules_for(
    battle_rules: Iterable[Mapping[str, Any]], card_name: str
) -> list[Mapping[str, Any]]:
    normalized = normalize_name(card_name)
    return [
        row
        for row in battle_rules
        if normalize_name(str(row.get("normalized_name") or row.get("card_name") or ""))
        == normalized
    ]


def deck_contains(deck_cards: Iterable[Mapping[str, Any]], card_name: str) -> bool:
    wanted = card_name.lower()
    return any(str(row.get("card_name") or "").lower() == wanted for row in deck_cards)


def deck_role_counts(deck_cards: Iterable[Mapping[str, Any]]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in deck_cards:
        tag = str(row.get("functional_tag") or "unknown")
        try:
            quantity = int(row.get("quantity") or 0)
        except (TypeError, ValueError):
            quantity = 0
        counts[tag] += quantity
    return dict(sorted(counts.items()))


def executable_verified_rule_count(rows: Iterable[Mapping[str, Any]]) -> int:
    count = 0
    for row in rows:
        if (
            row.get("review_status") == "verified"
            and row.get("execution_status") == "auto"
        ):
            count += 1
    return count


def build_candidate_preflight(
    package_rows: Sequence[Mapping[str, Any]],
    snapshot: Mapping[str, Any],
) -> list[dict[str, Any]]:
    oracle_by_name = index_by_normalized(as_list(snapshot.get("oracle")))
    legalities = as_list(snapshot.get("legalities"))
    battle_rules = as_list(snapshot.get("battle_rules"))
    deck_cards = as_list(snapshot.get("deck_cards"))
    result: list[dict[str, Any]] = []
    for row in package_rows:
        card_name = str(row.get("card_name") or "")
        oracle = oracle_by_name.get(normalize_name(card_name), {})
        rules = rules_for(battle_rules, card_name)
        verified_auto_count = executable_verified_rule_count(rules)
        commander_status = legal_status_for(legalities, card_name)
        status = "pass"
        blockers: list[str] = []
        if not oracle:
            status = "blocked"
            blockers.append("missing_oracle_cache")
        if commander_status != "legal":
            status = "blocked"
            blockers.append("missing_or_nonlegal_commander_status")
        if verified_auto_count < 1:
            status = "blocked"
            blockers.append("missing_verified_auto_battle_rule")
        result.append(
            {
                "card_name": card_name,
                "role": row.get("role") or "research_queue",
                "value_test": row.get("value_test") or row.get("reason") or "",
                "oracle_cache_status": "present" if oracle else "missing",
                "oracle_name": oracle.get("name") or "",
                "type_line": oracle.get("type_line") or "",
                "cmc": oracle.get("cmc"),
                "color_identity_json": oracle.get("color_identity_json") or "[]",
                "commander_legal_status": commander_status,
                "battle_rule_count": len(rules),
                "verified_auto_battle_rule_count": verified_auto_count,
                "already_in_607": deck_contains(deck_cards, card_name),
                "preflight_status": status,
                "blockers": blockers,
            }
        )
    return result


def package_preflight_summary(rows: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    primary_count = len(rows)
    present = sum(1 for row in rows if row.get("oracle_cache_status") == "present")
    legal = sum(1 for row in rows if row.get("commander_legal_status") == "legal")
    executable = sum(
        1 for row in rows if int(row.get("verified_auto_battle_rule_count") or 0) >= 1
    )
    already_in_607 = sum(1 for row in rows if row.get("already_in_607"))
    all_pass = all(row.get("preflight_status") == "pass" for row in rows)
    return {
        "primary_package_size": primary_count,
        "oracle_cache_present_count": present,
        "commander_legal_count": legal,
        "verified_auto_battle_rule_count": executable,
        "already_in_607_count": already_in_607,
        "all_primary_preflight_pass": all_pass,
    }


def find_pressure_diagnostic(planner_report: Mapping[str, Any]) -> Mapping[str, Any]:
    for row in as_list(planner_report.get("ranked_diagnostics")):
        if row.get("diagnostic_key") == "pressure_safe_spell_payoff_micro_shell":
            return row
    return {}


def validate_cut_plan(cut_names: Sequence[str], add_count: int) -> dict[str, Any]:
    protected = {name.lower(): name for name in PROTECTED_607_ANCHORS}
    violations: list[dict[str, str]] = []
    for name in cut_names:
        protected_name = protected.get(name.lower())
        if protected_name:
            violations.append(
                {
                    "card_name": name,
                    "violation": "protected_607_anchor_cut_forbidden",
                    "protected_anchor": protected_name,
                }
            )
    if len(cut_names) != add_count:
        violations.append(
            {
                "card_name": "",
                "violation": "cut_count_must_match_add_count_before_legal_deck_generation",
                "protected_anchor": "",
            }
        )
    return {
        "named_cut_count": len(cut_names),
        "required_cut_count": add_count,
        "safe": not violations,
        "violations": violations,
    }


def build_report(
    *,
    planner_report: Mapping[str, Any],
    db_snapshot: Mapping[str, Any],
    diagnostic_planner_path: Path,
    knowledge_db_path: Path,
    cut_plan: Sequence[str] = (),
) -> dict[str, Any]:
    pressure_diagnostic = find_pressure_diagnostic(planner_report)
    primary_preflight = build_candidate_preflight(PRIMARY_PACKAGE, db_snapshot)
    secondary_preflight = build_candidate_preflight(SECONDARY_RESEARCH_QUEUE, db_snapshot)
    preflight_summary = package_preflight_summary(primary_preflight)
    current_role_counts = deck_role_counts(as_list(db_snapshot.get("deck_cards")))
    cut_validation = validate_cut_plan(cut_plan, len(PRIMARY_PACKAGE))
    ready_for_cut_pool_resolver = bool(preflight_summary["all_primary_preflight_pass"])
    legal_variant_generation_allowed = ready_for_cut_pool_resolver and cut_validation["safe"]
    natural_battle_gate_allowed = legal_variant_generation_allowed and False
    next_action = (
        "build_pressure_safe_cut_pool_resolver_before_variant_battle"
        if ready_for_cut_pool_resolver and not cut_validation["safe"]
        else "generate_legal_pressure_safe_variant_and_structure_matrix"
        if legal_variant_generation_allowed
        else "repair_candidate_data_preflight_before_cut_search"
    )
    decision_status = (
        "preflight_pass_cut_pool_required"
        if ready_for_cut_pool_resolver and not cut_validation["safe"]
        else "legal_variant_ready_for_structure_matrix"
        if legal_variant_generation_allowed
        else "blocked_by_local_preflight"
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_pressure_safe_spell_payoff_contract",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "diagnostic_planner": rel(diagnostic_planner_path),
        "knowledge_db": rel(knowledge_db_path),
        "current_champion": "deck_607",
        "contract_key": "pressure_safe_spell_payoff_micro_shell",
        "summary": {
            "decision_status": decision_status,
            "ready_deck_change_count": 0,
            "ready_for_cut_pool_resolver": ready_for_cut_pool_resolver,
            "legal_variant_generation_allowed_now": legal_variant_generation_allowed,
            "natural_battle_gate_allowed_now": natural_battle_gate_allowed,
            "recommended_next_action": next_action,
            "primary_package_size": len(PRIMARY_PACKAGE),
            "required_cut_count_before_legal_variant": len(PRIMARY_PACKAGE),
            "protected_607_anchor_count": len(PROTECTED_607_ANCHORS),
        },
        "source_diagnostic": {
            "diagnostic_key": pressure_diagnostic.get("diagnostic_key") or "",
            "readiness": pressure_diagnostic.get("readiness") or "",
            "priority_score": pressure_diagnostic.get("priority_score"),
            "why": pressure_diagnostic.get("why") or "",
            "predeclared_requirements": pressure_diagnostic.get(
                "predeclared_requirements"
            )
            or [],
        },
        "deck_607_current_role_counts": current_role_counts,
        "primary_package_preflight_summary": preflight_summary,
        "primary_package_preflight": primary_preflight,
        "secondary_research_queue_preflight": secondary_preflight,
        "cut_plan_validation": cut_validation,
        "cut_policy": [
            "No protected 607 anchor can be used as a generic cut.",
            "Do not cut below the current 607 land floor before a full-shell matrix proves curve safety.",
            "Do not cut core ramp, topdeck/miracle setup, or protection to add pressure unless the cut is same-lane and trace-supported.",
            "The first legal variant needs exactly four named cuts for the four-card primary pressure package.",
            "A cut is not safe because a replacement is famous; it is safe only after role, source, and battle trace evidence align.",
        ],
        "protected_607_anchors": PROTECTED_607_ANCHORS,
        "battle_gate_contract": [
            "Create a legal decklist copy; deck 607 itself remains unchanged.",
            "Run structure matrix first; reject variants that regress lands, ramp, miracle/topdeck, or pressure-survival floors.",
            "Only after the matrix passes, run an equal opponent and seed gate against 607.",
            "Promotion requires tying or beating 607 overall and no Winota/fast-pressure regression.",
            "Card-level claims require direct draw/cast/trigger/use events for each included pressure payoff.",
        ],
        "external_pressure_sources": EXTERNAL_PRESSURE_SOURCES,
        "method_notes": [
            "This contract reads SQLite and existing reports only; it does not write PostgreSQL, SQLite, deck rows, or decklists.",
            "The local card preflight passing does not mean the deck should change; it only means the cut-pool resolver is the next real blocker.",
            "The One Ring and Mana Vault remain outside this contract because prior internal testing did not prove seed-safe cuts for the protected 607 shell.",
        ],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Pressure-Safe Spell-Payoff Contract",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Diagnostic planner: `{payload['diagnostic_planner']}`",
        f"- Knowledge DB: `{payload['knowledge_db']}`",
        f"- Current champion: `{payload['current_champion']}`",
        f"- Decision status: `{summary['decision_status']}`",
        f"- Ready deck changes: `{summary['ready_deck_change_count']}`",
        f"- Ready for cut-pool resolver: `{str(summary['ready_for_cut_pool_resolver']).lower()}`",
        f"- Legal variant generation allowed now: `{str(summary['legal_variant_generation_allowed_now']).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary['natural_battle_gate_allowed_now']).lower()}`",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        "",
        "## Primary Package Preflight",
        "",
        "| Card | Role | Oracle | Commander | Battle rules | In 607 | Status |",
        "| --- | --- | --- | --- | ---: | --- | --- |",
    ]
    for row in payload.get("primary_package_preflight") or []:
        lines.append(
            "| {card} | `{role}` | `{oracle}` | `{legal}` | {rules} | `{in_607}` | `{status}` |".format(
                card=row.get("card_name") or "",
                role=row.get("role") or "",
                oracle=row.get("oracle_cache_status") or "",
                legal=row.get("commander_legal_status") or "",
                rules=row.get("verified_auto_battle_rule_count") or 0,
                in_607=str(bool(row.get("already_in_607"))).lower(),
                status=row.get("preflight_status") or "",
            )
        )
    lines.extend(
        [
            "",
            "## Cut Status",
            "",
            f"- Named cuts: `{payload['cut_plan_validation']['named_cut_count']}`",
            f"- Required cuts: `{payload['cut_plan_validation']['required_cut_count']}`",
            f"- Cut plan safe: `{str(payload['cut_plan_validation']['safe']).lower()}`",
            "",
            "## Current 607 Role Counts",
            "",
            f"`{json.dumps(payload.get('deck_607_current_role_counts') or {}, sort_keys=True)}`",
            "",
            "## Protected 607 Anchors",
            "",
        ]
    )
    for name in payload.get("protected_607_anchors") or []:
        lines.append(f"- {name}")
    lines.extend(["", "## Cut Policy", ""])
    for item in payload.get("cut_policy") or []:
        lines.append(f"- {item}")
    lines.extend(["", "## Battle Gate Contract", ""])
    for item in payload.get("battle_gate_contract") or []:
        lines.append(f"- {item}")
    lines.extend(["", "## Secondary Research Queue", ""])
    for row in payload.get("secondary_research_queue_preflight") or []:
        lines.append(
            "- {card}: `{status}`, commander `{legal}`, verified auto rules `{rules}`".format(
                card=row.get("card_name") or "",
                status=row.get("preflight_status") or "",
                legal=row.get("commander_legal_status") or "",
                rules=row.get("verified_auto_battle_rule_count") or 0,
            )
        )
    lines.extend(["", "## External Pressure Sources", ""])
    for source in payload.get("external_pressure_sources") or []:
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
    parser.add_argument("--diagnostic-planner", type=Path, default=DEFAULT_DIAGNOSTIC_PLANNER)
    parser.add_argument("--knowledge-db", type=Path, default=DEFAULT_KNOWLEDGE_DB)
    parser.add_argument("--deck-id", type=int, default=607)
    parser.add_argument("--stem", default=DEFAULT_STEM)
    parser.add_argument(
        "--cut",
        action="append",
        default=[],
        help="Optional named cut to validate against the protected 607 contract.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    names = candidate_names()
    snapshot = load_db_snapshot(args.knowledge_db, names, args.deck_id)
    payload = build_report(
        planner_report=read_json(args.diagnostic_planner),
        db_snapshot=snapshot,
        diagnostic_planner_path=args.diagnostic_planner,
        knowledge_db_path=args.knowledge_db,
        cut_plan=args.cut,
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
