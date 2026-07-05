#!/usr/bin/env python3
"""Split post-identity Lorehold candidates into runtime, combo, and shell work.

The identity cache simulation proves that the missing Oracle identities can be
inserted cleanly on a temporary copy. This report answers the next planning
question: what each card is worth for deckbuilding, which contract it belongs
to, and why none of the cards can enter a natural 607 battle gate yet.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter, defaultdict
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_optimizer_common import resolve_default_knowledge_db


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_SIMULATION_REPORT = REPORT_DIR / "lorehold_external_identity_cache_simulation_20260705_current.json"
DEFAULT_SCOUT_REPORT = REPORT_DIR / "lorehold_external_material_evidence_scout_20260705_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_post_identity_queue_split_20260705_current"

SHELL_FAMILY_BY_CARD = {
    "anointed procession": "token_multiplier_shell",
    "cathars' crusade": "token_multiplier_shell",
    "blackblade reforged": "voltron_equipment_shell",
    "excalibur, sword of eden": "voltron_equipment_shell",
    "strata scythe": "voltron_equipment_shell",
    "karmic guide": "white_reanimator_shell",
    "late to dinner": "white_reanimator_shell",
    "miraculous recovery": "white_reanimator_shell",
    "storm of souls": "white_reanimator_shell",
}

CARD_VALUE_PROFILE = {
    "brain in a jar": {
        "lane": "topdeck_miracle_access",
        "value_role": "alternate_cost_timing_engine",
        "deckbuilding_value": (
            "Potentially helps cast key spells on constrained turns, but only if "
            "charge-counter timing and spell mana values are modeled correctly."
        ),
        "priority_rank": 1,
        "required_contract": "single_card_runtime_contract_then_cut_safety",
    },
    "entreat the angels": {
        "lane": "miracle_finisher",
        "value_role": "miracle_token_closure",
        "deckbuilding_value": (
            "Fits the Lorehold miracle thesis as a high-ceiling finisher, but "
            "needs miracle/tokens runtime and a named cut before battle."
        ),
        "priority_rank": 1,
        "required_contract": "miracle_token_runtime_contract_then_cut_safety",
    },
    "haze of rage": {
        "lane": "storm_combo_pressure",
        "value_role": "storm_kiln_combo_payoff",
        "deckbuilding_value": (
            "Only meaningful as a Storm-Kiln Artist combo package; by itself it "
            "does not prove a 607 one-for-one replacement."
        ),
        "priority_rank": 2,
        "required_contract": "combo_runtime_contract_with_storm_kiln_artist",
    },
    "burning prophet": {
        "lane": "spell_scry_pressure",
        "value_role": "cheap_spell_velocity_creature",
        "deckbuilding_value": (
            "Adds repeated scry and small pressure from noncreature spell volume, "
            "but current evidence treats it as diagnostic until runtime exists."
        ),
        "priority_rank": 3,
        "required_contract": "spell_trigger_runtime_review_then_diagnostic_cut_check",
    },
    "inti, seneschal of the sun": {
        "lane": "rummage_pressure_access",
        "value_role": "attack_discard_exile_access_engine",
        "deckbuilding_value": (
            "Could align with Lorehold discard/access play, but attack timing, "
            "discard trigger, and temporary exile access all need runtime review."
        ),
        "priority_rank": 3,
        "required_contract": "discard_access_runtime_review_then_shell_or_cut_check",
    },
    "anointed procession": {
        "lane": "token_multiplier",
        "value_role": "token_doubling_shell_payoff",
        "deckbuilding_value": "Raises token output only in a deck that already commits to token density.",
        "priority_rank": 4,
        "required_contract": "token_multiplier_shell_contract",
    },
    "cathars' crusade": {
        "lane": "token_multiplier",
        "value_role": "wide_board_counter_scaler",
        "deckbuilding_value": "Pays off repeated creature/token entries, which is a different shell from current 607.",
        "priority_rank": 4,
        "required_contract": "token_multiplier_shell_contract",
    },
    "blackblade reforged": {
        "lane": "voltron_equipment",
        "value_role": "land_count_power_scaler",
        "deckbuilding_value": "Strong only if the deck becomes a protected commander/equipment damage shell.",
        "priority_rank": 5,
        "required_contract": "voltron_equipment_shell_contract",
    },
    "excalibur, sword of eden": {
        "lane": "voltron_equipment",
        "value_role": "historic_cost_reduction_equipment_finisher",
        "deckbuilding_value": "Needs historic permanent density and a combat finisher plan before it is meaningful.",
        "priority_rank": 5,
        "required_contract": "voltron_equipment_shell_contract",
    },
    "strata scythe": {
        "lane": "voltron_equipment",
        "value_role": "basic_land_scaling_equipment",
        "deckbuilding_value": "Depends on land-name density and equipment combat pressure, not the current 607 lane.",
        "priority_rank": 5,
        "required_contract": "voltron_equipment_shell_contract",
    },
    "karmic guide": {
        "lane": "white_reanimator",
        "value_role": "creature_recursion_bridge",
        "deckbuilding_value": "Rule-known card, but it matters only in a creature/graveyard recursion shell.",
        "priority_rank": 4,
        "required_contract": "white_reanimator_shell_contract",
    },
    "late to dinner": {
        "lane": "white_reanimator",
        "value_role": "creature_reanimation_plus_treasure",
        "deckbuilding_value": "Requires enough creature targets and graveyard setup to justify leaving 607's spell shell.",
        "priority_rank": 4,
        "required_contract": "white_reanimator_shell_contract",
    },
    "miraculous recovery": {
        "lane": "white_reanimator",
        "value_role": "instant_speed_creature_reanimation",
        "deckbuilding_value": "A recursion payoff for a creature-heavy graveyard plan, not a current 607 flex slot.",
        "priority_rank": 4,
        "required_contract": "white_reanimator_shell_contract",
    },
    "storm of souls": {
        "lane": "white_reanimator",
        "value_role": "mass_reanimation_closure",
        "deckbuilding_value": "A full-shell payoff that needs graveyard volume and creature density first.",
        "priority_rank": 4,
        "required_contract": "white_reanimator_shell_contract",
    },
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


def normalize_name(name: str) -> str:
    return " ".join(str(name or "").strip().lower().replace("’", "'").split())


def queue_membership(queues: Mapping[str, Any]) -> dict[str, list[str]]:
    membership: dict[str, list[str]] = defaultdict(list)
    for queue_name, cards in queues.items():
        for card in cards or []:
            membership[normalize_name(str(card))].append(str(queue_name))
    return dict(membership)


def simulated_identity_index(simulation: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows = {}
    for row in simulation.get("postcheck_rows") or []:
        if isinstance(row, Mapping):
            rows[normalize_name(str(row.get("name") or row.get("normalized_name") or ""))] = dict(row)
            rows[normalize_name(str(row.get("normalized_name") or ""))] = dict(row)
    return {key: value for key, value in rows.items() if key}


def scout_index(scout_report: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows = {}
    for row in scout_report.get("candidate_classifications") or []:
        if isinstance(row, Mapping):
            key = normalize_name(str(row.get("card_name") or ""))
            if key:
                rows[key] = dict(row)
    return rows


def placeholders(values: Iterable[Any]) -> str:
    values = list(values)
    if not values:
        raise ValueError("at least one value is required")
    return ",".join("?" for _ in values)


def db_snapshot(db_path: Path, card_names: list[str], deck_id: int) -> dict[str, Any]:
    normalized = [normalize_name(name) for name in card_names]
    lowered = [name.lower() for name in card_names]
    snapshot = {
        "oracle": {},
        "legalities": {},
        "verified_rule_counts": {},
        "deck_ids": {},
    }
    if not db_path.exists():
        return snapshot
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        for row in conn.execute(
            (
                "SELECT normalized_name, name, mana_cost, color_identity_json, "
                "type_line, oracle_text, cmc, scryfall_id, source "
                f"FROM card_oracle_cache WHERE normalized_name IN ({placeholders(normalized)}) "
                f"OR lower(name) IN ({placeholders(lowered)})"
            ),
            [*normalized, *lowered],
        ):
            data = dict(row)
            snapshot["oracle"][normalize_name(data.get("normalized_name") or data.get("name") or "")] = data
            snapshot["oracle"][normalize_name(data.get("name") or "")] = data
        for row in conn.execute(
            (
                "SELECT card_name, format, status "
                f"FROM card_legalities WHERE lower(card_name) IN ({placeholders(lowered)})"
            ),
            lowered,
        ):
            if row["format"] == "commander":
                snapshot["legalities"][normalize_name(row["card_name"])] = row["status"]
        disabled_clause = "AND disabled_at IS NULL" if has_column(conn, "battle_card_rules", "disabled_at") else ""
        for row in conn.execute(
            (
                "SELECT normalized_name, lower(card_name) AS card_key, COUNT(*) AS verified_rule_count "
                "FROM battle_card_rules "
                f"WHERE (normalized_name IN ({placeholders(normalized)}) OR lower(card_name) IN ({placeholders(lowered)})) "
                "AND review_status = 'verified' "
                "AND execution_status IN ('auto', 'trusted') "
                f"{disabled_clause} "
                "GROUP BY normalized_name, lower(card_name)"
            ),
            [*normalized, *lowered],
        ):
            keys = {normalize_name(row["normalized_name"] or ""), normalize_name(row["card_key"] or "")}
            for key in keys:
                if key:
                    snapshot["verified_rule_counts"][key] = int(row["verified_rule_count"] or 0)
        for row in conn.execute(
            (
                "SELECT card_name, GROUP_CONCAT(DISTINCT deck_id) AS deck_ids "
                f"FROM deck_cards WHERE lower(card_name) IN ({placeholders(lowered)}) "
                "GROUP BY card_name"
            ),
            lowered,
        ):
            decks = [int(value) for value in str(row["deck_ids"] or "").split(",") if value]
            snapshot["deck_ids"][normalize_name(row["card_name"])] = sorted(decks)
    snapshot["deck_id"] = deck_id
    return snapshot


def has_column(conn: sqlite3.Connection, table: str, column: str) -> bool:
    return any(row[1] == column for row in conn.execute(f"PRAGMA table_info({table})").fetchall())


def identity_status(
    *,
    key: str,
    db: Mapping[str, Any],
    simulation_identities: Mapping[str, Mapping[str, Any]],
) -> tuple[bool, str, str]:
    oracle = (db.get("oracle") or {}).get(key)
    if oracle:
        return True, "source_db", str(oracle.get("name") or "")
    simulated = simulation_identities.get(key)
    if simulated:
        return True, "temporary_simulation", str(simulated.get("name") or "")
    return False, "missing", ""


def card_row(
    *,
    card_name: str,
    queues: list[str],
    scout: Mapping[str, Any],
    db: Mapping[str, Any],
    simulation_identities: Mapping[str, Mapping[str, Any]],
    deck_id: int,
) -> dict[str, Any]:
    key = normalize_name(card_name)
    profile = CARD_VALUE_PROFILE.get(key, {})
    identity_ready, identity_source, oracle_name = identity_status(
        key=key,
        db=db,
        simulation_identities=simulation_identities,
    )
    simulated = simulation_identities.get(key) or {}
    deck_ids = list((db.get("deck_ids") or {}).get(key) or scout.get("lorehold_variant_deck_ids") or [])
    verified_rules = int((db.get("verified_rule_counts") or {}).get(key) or scout.get("verified_auto_rule_count") or 0)
    commander_status = (
        simulated.get("commander_status")
        or (db.get("legalities") or {}).get(key)
        or "missing"
    )
    route_class = "runtime_or_manual_review"
    if "shell_contract_required" in queues:
        route_class = "full_shell_contract"
    if "combo_runtime_required" in queues:
        route_class = "combo_runtime_contract"
    blockers = []
    if not identity_ready:
        blockers.append("oracle_identity_missing")
    if commander_status != "legal":
        blockers.append("commander_legality_not_confirmed")
    if verified_rules == 0:
        blockers.append("verified_battle_rule_missing")
    if "shell_contract_required" in queues:
        blockers.append("full_shell_contract_required")
    if "combo_runtime_required" in queues:
        blockers.append("combo_runtime_required")
    blockers.append("named_safe_cut_missing")
    return {
        "card_name": card_name,
        "normalized_name": key,
        "queues": queues,
        "route_class": route_class,
        "shell_family": SHELL_FAMILY_BY_CARD.get(key),
        "lane": profile.get("lane") or "external_material_candidate",
        "value_role": profile.get("value_role") or "external_candidate",
        "deckbuilding_value": profile.get("deckbuilding_value") or "",
        "priority_rank": int(profile.get("priority_rank") or 9),
        "required_contract": profile.get("required_contract") or "manual_review_contract",
        "source_keys": list(scout.get("source_keys") or []),
        "route_types": list(scout.get("route_types") or []),
        "source_classification": scout.get("classification"),
        "source_actionability": scout.get("actionability"),
        "identity_ready": identity_ready,
        "identity_source": identity_source,
        "oracle_name": oracle_name,
        "commander_status": commander_status,
        "verified_auto_rule_count": verified_rules,
        "in_607": deck_id in deck_ids,
        "known_deck_ids": deck_ids,
        "battle_ready_now": False,
        "promotion_allowed_now": False,
        "blockers": blockers,
    }


def contract_rows(cards: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, list[Mapping[str, Any]]] = defaultdict(list)
    for row in cards:
        if row.get("shell_family"):
            grouped[str(row["shell_family"])].append(row)
    rows = []
    for family, family_cards in sorted(grouped.items()):
        rows.append(
            {
                "contract_key": family,
                "cards": [str(row["card_name"]) for row in family_cards],
                "verified_auto_rule_count": sum(int(row.get("verified_auto_rule_count") or 0) for row in family_cards),
                "ready_for_battle": False,
                "required_next_step": {
                    "token_multiplier_shell": "define_token_density_engine_and_cuts_before_any_battle",
                    "voltron_equipment_shell": "define_equipment_commander_damage_shell_before_any_battle",
                    "white_reanimator_shell": "define_creature_graveyard_density_shell_before_any_battle",
                }.get(family, "define_shell_contract_before_any_battle"),
                "reason": {
                    "token_multiplier_shell": (
                        "These payoffs need repeated token/creature entries; current 607 is protected "
                        "as miracle/topdeck spell conversion, not token swarm."
                    ),
                    "voltron_equipment_shell": (
                        "These cards require a combat-damage equipment plan and protection package, "
                        "which is a different thesis from current 607."
                    ),
                    "white_reanimator_shell": (
                        "These cards require creature density, graveyard setup, and recursion targets; "
                        "they cannot justify one-for-one cuts from 607."
                    ),
                }.get(family, "Full shell contract is required before battle."),
            }
        )
    rows.append(
        {
            "contract_key": "storm_kiln_haze_combo",
            "cards": ["Storm-Kiln Artist", "Haze of Rage"],
            "verified_auto_rule_count": next(
                (int(row.get("verified_auto_rule_count") or 0) for row in cards if row.get("card_name") == "Haze of Rage"),
                0,
            ),
            "ready_for_battle": False,
            "required_next_step": "define_combo_runtime_and_cut_safety_before_any_battle",
            "reason": (
                "The external combo signal is package-only; Haze of Rage still needs storm/buyback/"
                "combat-buff runtime and a named cut plan."
            ),
        }
    )
    return rows


def build_payload(
    *,
    simulation: Mapping[str, Any],
    simulation_path: Path,
    scout_report: Mapping[str, Any],
    scout_path: Path,
    db_path: Path,
    deck_id: int,
) -> dict[str, Any]:
    queues = queue_membership(simulation.get("post_apply_queues") or {})
    card_names = sorted({card for cards in (simulation.get("post_apply_queues") or {}).values() for card in cards})
    scouts = scout_index(scout_report)
    identities = simulated_identity_index(simulation)
    db = db_snapshot(db_path, card_names, deck_id)
    cards = [
        card_row(
            card_name=name,
            queues=sorted(queues.get(normalize_name(name)) or []),
            scout=scouts.get(normalize_name(name), {}),
            db=db,
            simulation_identities=identities,
            deck_id=deck_id,
        )
        for name in card_names
    ]
    cards.sort(key=lambda row: (row["priority_rank"], row["card_name"]))
    route_counts = Counter(str(row["route_class"]) for row in cards)
    identity_sources = Counter(str(row["identity_source"]) for row in cards)
    payload = {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_post_identity_queue_split",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": {
            "identity_cache_simulation": rel(simulation_path),
            "external_material_scout": rel(scout_path),
        },
        "source_db": str(db_path),
        "status": "post_identity_queue_split_no_battle_ready_keep_607",
        "summary": {
            "current_baseline": f"deck_{deck_id}",
            "queue_card_count": len(cards),
            "identity_import_remaining_count": sum(1 for row in cards if not row["identity_ready"]),
            "temporary_identity_ready_count": identity_sources.get("temporary_simulation", 0),
            "source_identity_ready_count": identity_sources.get("source_db", 0),
            "runtime_or_manual_review_count": route_counts.get("runtime_or_manual_review", 0),
            "combo_runtime_contract_count": route_counts.get("combo_runtime_contract", 0),
            "full_shell_contract_count": route_counts.get("full_shell_contract", 0),
            "verified_auto_rule_ready_count": sum(1 for row in cards if int(row["verified_auto_rule_count"]) > 0),
            "battle_ready_now_count": 0,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "recommended_next_action": "draft_runtime_contracts_for_brain_entreat_haze_before_any_deck_gate",
        },
        "cards": cards,
        "contracts": contract_rows(cards),
        "decision": {
            "keep_607_as_protected_baseline": True,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "Post-identity queues are now clear enough to plan, but every path still "
                "requires runtime, combo, shell, or named safe-cut work before a battle gate."
            ),
        },
    }
    return payload


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Post-Identity Queue Split",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Current baseline: `{summary['current_baseline']}`",
        f"- Source DB mutated: `{payload['source_db_mutated']}`",
        f"- Deck 607 mutated: `{payload['deck_607_mutated']}`",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "| --- | ---: |",
    ]
    for key in [
        "queue_card_count",
        "identity_import_remaining_count",
        "temporary_identity_ready_count",
        "source_identity_ready_count",
        "runtime_or_manual_review_count",
        "combo_runtime_contract_count",
        "full_shell_contract_count",
        "verified_auto_rule_ready_count",
        "battle_ready_now_count",
    ]:
        lines.append(f"| `{key}` | `{summary[key]}` |")
    lines.extend(
        [
            "",
            "## Card Priorities",
            "",
            "| Card | Route | Lane | Contract | Rule Count | Blockers |",
            "| --- | --- | --- | --- | ---: | --- |",
        ]
    )
    for row in payload["cards"]:
        lines.append(
            "| {card} | `{route}` | `{lane}` | `{contract}` | `{rules}` | {blockers} |".format(
                card=row["card_name"],
                route=row["route_class"],
                lane=row["lane"],
                contract=row["required_contract"],
                rules=row["verified_auto_rule_count"],
                blockers=", ".join(row["blockers"]),
            )
        )
    lines.extend(
        [
            "",
            "## Shell And Combo Contracts",
            "",
            "| Contract | Cards | Next Step |",
            "| --- | --- | --- |",
        ]
    )
    for contract in payload["contracts"]:
        lines.append(
            f"| `{contract['contract_key']}` | {', '.join(contract['cards'])} | `{contract['required_next_step']}` |"
        )
    decision = payload["decision"]
    lines.extend(
        [
            "",
            "## Decision",
            "",
            f"- Keep 607 as protected baseline: `{decision['keep_607_as_protected_baseline']}`",
            f"- Natural battle allowed now: `{decision['natural_battle_allowed_now']}`",
            f"- Promotion allowed: `{decision['promotion_allowed']}`",
            f"- Reason: {decision['reason']}",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=607)
    parser.add_argument("--simulation-report", type=Path, default=DEFAULT_SIMULATION_REPORT)
    parser.add_argument("--scout-report", type=Path, default=DEFAULT_SCOUT_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(
        simulation=read_json(args.simulation_report),
        simulation_path=args.simulation_report,
        scout_report=read_json(args.scout_report),
        scout_path=args.scout_report,
        db_path=args.db,
        deck_id=args.deck_id,
    )
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "battle_ready_now_count": payload["summary"]["battle_ready_now_count"],
                "recommended_next_action": payload["summary"]["recommended_next_action"],
            },
            ensure_ascii=True,
        )
    )
    return 0 if payload["status"] == "post_identity_queue_split_no_battle_ready_keep_607" else 1


if __name__ == "__main__":
    raise SystemExit(main())
