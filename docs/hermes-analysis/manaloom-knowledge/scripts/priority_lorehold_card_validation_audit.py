#!/usr/bin/env python3
"""Focused validation for the current priority Lorehold card/family queue.

This audit checks three distinct contracts:

1. PostgreSQL has a verified/auto battle rule for each prioritized card name.
2. Hermes SQLite and the canonical fallback snapshot mirror the same rule scope.
3. Cards called out for missing functional classification have their required
   card_function_tags in PostgreSQL.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import battle_rule_registry
import external_engine_source_contract as engine_source_contract
from db_helper import connect, sanitized_database_target
from master_optimizer_common import REPORT_DIR, resolve_default_knowledge_db


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_SQLITE_DB = resolve_default_knowledge_db()
DEFAULT_SNAPSHOT = SCRIPT_DIR / "known_cards_canonical_snapshot.json"
DEFAULT_XMAGE_ROOT: Path | None = None


EXPECTED_RULES: dict[str, list[dict[str, str]]] = {
    "Lorehold, the Historian": [
        {"effect": "passive", "scope": "lorehold_opponent_upkeep_miracle_v1"}
    ],
    "Farewell": [
        {
            "effect": "board_wipe",
            "scope": "modal_exile_wipe_creature_runtime_baseline_v1",
        }
    ],
    "Fellwar Stone": [
        {
            "effect": "ramp_permanent",
            "scope": "conditional_opponent_color_mana_rock_v1",
        }
    ],
    "Flawless Maneuver": [
        {
            "effect": "indestructible",
            "scope": "flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1",
        }
    ],
    "Hit the Mother Lode": [
        {
            "effect": "draw_cards",
            "scope": "discover_10_as_one_card_value_component_v1",
        },
        {
            "effect": "treasure_maker",
            "scope": "discover_10_treasure_difference_average_v1",
        },
    ],
    "Improvisation Capstone": [
        {
            "effect": "exile_value",
            "scope": "exile_value_free_casts_paradigm_annotation_v1",
        }
    ],
    "Land Tax": [
        {
            "effect": "land_tax",
            "scope": "land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1",
        }
    ],
    "Library of Leng": [
        {"effect": "passive", "scope": "discard_replacement_to_top_v1"}
    ],
    "Scroll Rack": [
        {
            "effect": "topdeck_manipulation",
            "scope": "scroll_rack_upkeep_single_exchange_v1",
        }
    ],
    "Swords to Plowshares": [
        {
            "effect": "remove_creature",
            "scope": "swords_to_plowshares_creature_exile_life_equal_power_v1",
        }
    ],
    "Talisman of Conviction": [
        {
            "effect": "ramp_permanent",
            "scope": "pain_talisman_color_pair_partial_v1",
        }
    ],
    "Teferi's Protection": [
        {
            "effect": "phase_out",
            "scope": "teferis_protection_life_lock_protection_all_permanents_phase_out_self_exile_v1",
        }
    ],
    "Tibalt's Trickery": [
        {
            "effect": "counter",
            "scope": "counterspell_with_random_replacement_annotation_v1",
        }
    ],
    "Command Tower": [
        {
            "effect": "land",
            "scope": "commander_identity_land_mana_source_v1",
        }
    ],
    "Sol Ring": [
        {"effect": "ramp_permanent", "scope": "two_colorless_mana_rock_v1"}
    ],
    "Thor, God of Thunder": [
        {
            "effect": "creature",
            "scope": "etb_graveyard_impulse_recast_noncreature_spell_damage_any_target_v1",
        }
    ],
    "Furygale Flocking": [
        {
            "effect": "token_maker",
            "scope": "per_opponent_two_3_3_flying_hasty_elementals_graveyard_cost_reduction_runtime_attack_requirement_v1",
        }
    ],
    "Molecule Man": [
        {"effect": "passive", "scope": "nonland_hand_miracle_zero_static_v1"}
    ],
    "Pearl Medallion": [
        {
            "effect": "static_cost_reduction",
            "scope": "static_cost_reduction_for_matching_spells_v1",
        }
    ],
    "Prismari Pianist": [
        {
            "effect": "token_maker",
            "scope": "instant_sorcery_cast_create_1_or_3_1_1_elementals_by_spell_mv_v1",
        }
    ],
    "Redirect Lightning": [
        {
            "effect": "redirect_removal",
            "scope": "single_target_spell_or_ability_redirect_additional_cost_annotation_v1",
        }
    ],
    "The Mind Stone": [
        {
            "effect": "ramp_permanent",
            "scope": "legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1",
        }
    ],
    "The Scarlet Witch": [
        {
            "effect": "static_cost_reduction",
            "scope": "static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1",
        }
    ],
    "Turbulent Steppe": [
        {
            "effect": "land",
            "scope": "land_enters_tapped_unless_opponents_control_lands_count_mana_source_v1",
        }
    ],
}


REQUIRED_FUNCTION_TAGS: dict[str, set[str]] = {
    "Furygale Flocking": {"big_spell", "payoff", "token_maker"},
    "Molecule Man": {"combo_piece", "enabler", "engine"},
    "Pearl Medallion": {"enabler", "ramp"},
    "Prismari Pianist": {"payoff", "spellslinger", "token_maker"},
    "Redirect Lightning": {"protection", "removal"},
    "The Mind Stone": {"artifact_synergy", "blink", "engine", "ramp"},
    "The Scarlet Witch": {"big_spell", "enabler", "engine", "spellslinger"},
    "Thor, God of Thunder": {"payoff", "recursion", "removal", "spellslinger"},
    "Turbulent Steppe": {"land", "ramp"},
}


XMAGE_CLASS_NAMES: dict[str, str] = {
    "Command Tower": "CommandTower",
    "Farewell": "Farewell",
    "Fellwar Stone": "FellwarStone",
    "Flawless Maneuver": "FlawlessManeuver",
    "Furygale Flocking": "FurygaleFlocking",
    "Hit the Mother Lode": "HitTheMotherLode",
    "Improvisation Capstone": "ImprovisationCapstone",
    "Land Tax": "LandTax",
    "Library of Leng": "LibraryOfLeng",
    "Lorehold, the Historian": "LoreholdTheHistorian",
    "Molecule Man": "MoleculeMan",
    "Pearl Medallion": "PearlMedallion",
    "Prismari Pianist": "PrismariPianist",
    "Redirect Lightning": "RedirectLightning",
    "Scroll Rack": "ScrollRack",
    "Sol Ring": "SolRing",
    "Swords to Plowshares": "SwordsToPlowshares",
    "Talisman of Conviction": "TalismanOfConviction",
    "Teferi's Protection": "TeferisProtection",
    "The Mind Stone": "TheMindStone",
    "The Scarlet Witch": "TheScarletWitch",
    "Thor, God of Thunder": "ThorGodOfThunder",
    "Tibalt's Trickery": "TibaltsTrickery",
    "Turbulent Steppe": "TurbulentSteppe",
}


@dataclass
class RuleRow:
    effect: str
    scope: str
    review_status: str
    execution_status: str
    source: str
    logical_rule_key: str


def normalize(name: str) -> str:
    return battle_rule_registry.normalize_card_name(name)


def safe_json_loads(raw: Any) -> dict[str, Any]:
    if isinstance(raw, dict):
        return raw
    if raw is None:
        return {}
    return json.loads(str(raw))


def row_matches_expected(row: RuleRow, expected: dict[str, str]) -> bool:
    return (
        row.review_status == "verified"
        and row.execution_status == "auto"
        and row.effect == expected["effect"]
        and row.scope == expected["scope"]
    )


def missing_expected(rows: list[RuleRow], expected_rules: list[dict[str, str]]) -> list[dict[str, str]]:
    return [expected for expected in expected_rules if not any(row_matches_expected(row, expected) for row in rows)]


def fetch_pg_rules() -> tuple[dict[str, list[RuleRow]], dict[str, set[str]], dict[str, int]]:
    names = list(EXPECTED_RULES)
    normalized_names = [normalize(name) for name in names]
    rules: dict[str, list[RuleRow]] = {name: [] for name in names}
    tags: dict[str, set[str]] = {name: set() for name in names}
    card_counts: dict[str, int] = {name: 0 for name in names}
    by_norm = {normalize(name): name for name in names}

    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT normalized_name, effect_json, review_status, execution_status,
                       source, logical_rule_key
                FROM card_battle_rules
                WHERE normalized_name = ANY(%s)
                ORDER BY normalized_name, review_status, execution_status
                """,
                (normalized_names,),
            )
            for normalized_name, effect_json, review_status, execution_status, source, logical_rule_key in cur.fetchall():
                name = by_norm.get(str(normalized_name))
                if not name:
                    continue
                effect = safe_json_loads(effect_json)
                rules[name].append(
                    RuleRow(
                        effect=str(effect.get("effect") or ""),
                        scope=str(effect.get("battle_model_scope") or ""),
                        review_status=str(review_status or ""),
                        execution_status=str(execution_status or ""),
                        source=str(source or ""),
                        logical_rule_key=str(logical_rule_key or ""),
                    )
                )

            cur.execute(
                """
                SELECT lower(c.name), count(*)::int
                FROM cards c
                WHERE lower(c.name) = ANY(%s)
                GROUP BY lower(c.name)
                """,
                ([name.lower() for name in names],),
            )
            for raw_name, count in cur.fetchall():
                name = by_norm.get(normalize(str(raw_name)))
                if name:
                    card_counts[name] = int(count)

            cur.execute(
                """
                SELECT lower(c.name), lower(ft.tag)
                FROM card_function_tags ft
                JOIN cards c ON c.id = ft.card_id
                WHERE lower(c.name) = ANY(%s)
                """,
                ([name.lower() for name in names],),
            )
            for raw_name, tag in cur.fetchall():
                name = by_norm.get(normalize(str(raw_name)))
                if name and tag:
                    tags[name].add(str(tag))

    return rules, tags, card_counts


def fetch_sqlite_rules(sqlite_db: Path) -> dict[str, list[RuleRow]]:
    names = list(EXPECTED_RULES)
    rules: dict[str, list[RuleRow]] = {name: [] for name in names}
    by_norm = {normalize(name): name for name in names}
    placeholders = ",".join("?" for _ in names)
    with sqlite3.connect(f"file:{sqlite_db}?mode=ro", uri=True) as conn:
        rows = conn.execute(
            f"""
            SELECT normalized_name, effect_json, review_status, execution_status,
                   source, logical_rule_key
            FROM battle_card_rules
            WHERE normalized_name IN ({placeholders})
            ORDER BY normalized_name, review_status, execution_status
            """,
            [normalize(name) for name in names],
        ).fetchall()
    for normalized_name, effect_json, review_status, execution_status, source, logical_rule_key in rows:
        name = by_norm.get(str(normalized_name))
        if not name:
            continue
        effect = safe_json_loads(effect_json)
        rules[name].append(
            RuleRow(
                effect=str(effect.get("effect") or ""),
                scope=str(effect.get("battle_model_scope") or ""),
                review_status=str(review_status or ""),
                execution_status=str(execution_status or ""),
                source=str(source or ""),
                logical_rule_key=str(logical_rule_key or ""),
            )
        )
    return rules


def fetch_snapshot_rules(snapshot_path: Path) -> dict[str, RuleRow | None]:
    snapshot = json.loads(snapshot_path.read_text(encoding="utf-8"))
    rows: dict[str, RuleRow | None] = {}
    for name in EXPECTED_RULES:
        entry = snapshot.get(name)
        if not entry:
            rows[name] = None
            continue
        rows[name] = RuleRow(
            effect=str(entry.get("effect") or ""),
            scope=str(entry.get("battle_model_scope") or ""),
            review_status=str(entry.get("battle_rule_review_status") or ""),
            execution_status=str(entry.get("battle_rule_execution_status") or ""),
            source=str(entry.get("battle_rule_source") or ""),
            logical_rule_key=str(entry.get("battle_rule_logical_key") or ""),
        )
    return rows


def xmage_source_path(name: str, xmage_root: Path) -> str | None:
    class_name = XMAGE_CLASS_NAMES[name]
    card_dir = xmage_root / "Mage.Sets" / "src" / "mage" / "cards" / class_name[0].lower()
    path = card_dir / f"{class_name}.java"
    return str(path) if path.is_file() else None


def rule_row_summary(rows: list[RuleRow]) -> list[dict[str, str]]:
    return [
        {
            "effect": row.effect,
            "scope": row.scope,
            "review_status": row.review_status,
            "execution_status": row.execution_status,
            "source": row.source,
            "logical_rule_key": row.logical_rule_key,
        }
        for row in rows
    ]


def build_report(sqlite_db: Path, snapshot_path: Path, xmage_root: Path) -> dict[str, Any]:
    generated_at = datetime.now(timezone.utc).isoformat()
    pg_rules, pg_tags, pg_card_counts = fetch_pg_rules()
    sqlite_rules = fetch_sqlite_rules(sqlite_db)
    snapshot_rules = fetch_snapshot_rules(snapshot_path)

    cards: list[dict[str, Any]] = []
    checks: list[dict[str, Any]] = []

    for name, expected_rules in EXPECTED_RULES.items():
        pg_missing = missing_expected(pg_rules[name], expected_rules)
        sqlite_missing = missing_expected(sqlite_rules[name], expected_rules)
        snapshot_rule = snapshot_rules[name]
        snapshot_missing = (
            snapshot_rule is None
            or snapshot_rule.review_status != "verified"
            or snapshot_rule.execution_status != "auto"
            or not any(row_matches_expected(snapshot_rule, expected) for expected in expected_rules)
        )

        required_tags = REQUIRED_FUNCTION_TAGS.get(name, set())
        found_tags = pg_tags.get(name, set())
        missing_tags = sorted(required_tags - found_tags)

        card_checks = {
            "pg_rule": "pass" if not pg_missing else "fail",
            "sqlite_rule": "pass" if not sqlite_missing else "fail",
            "snapshot_rule": "pass" if not snapshot_missing else "fail",
            "functional_tags": "pass" if not missing_tags else "fail",
        }
        if not required_tags:
            card_checks["functional_tags"] = "not_required"

        xmage_path = xmage_source_path(name, xmage_root)
        card_report = {
            "card_name": name,
            "normalized_name": normalize(name),
            "pg_card_rows": pg_card_counts.get(name, 0),
            "expected_rules": expected_rules,
            "pg_rules": rule_row_summary(pg_rules[name]),
            "sqlite_rules": rule_row_summary(sqlite_rules[name]),
            "snapshot_rule": None
            if snapshot_rule is None
            else rule_row_summary([snapshot_rule])[0],
            "required_function_tags": sorted(required_tags),
            "pg_function_tags": sorted(found_tags),
            "missing_function_tags": missing_tags,
            "xmage_source_path": xmage_path,
            "checks": card_checks,
        }
        cards.append(card_report)

        for check_name, status in card_checks.items():
            if status == "not_required":
                continue
            checks.append(
                {
                    "name": f"{check_name}::{name}",
                    "status": status,
                    "detail": {
                        "missing_rules": {
                            "pg": pg_missing,
                            "sqlite": sqlite_missing,
                            "snapshot": snapshot_missing,
                        },
                        "missing_function_tags": missing_tags,
                    },
                }
            )

    fail_count = sum(1 for check in checks if check["status"] == "fail")
    xmage_found_count = sum(1 for card in cards if card["xmage_source_path"])
    report = {
        "generated_at": generated_at,
        "status": "pass" if fail_count == 0 else "fail",
        "postgres_target": sanitized_database_target(),
        "sqlite_db": str(sqlite_db),
        "snapshot_path": str(snapshot_path),
        "xmage_root": str(xmage_root),
        "summary": {
            "target_card_count": len(EXPECTED_RULES),
            "battle_rule_cards_passed": sum(
                1
                for card in cards
                if card["checks"]["pg_rule"] == "pass"
                and card["checks"]["sqlite_rule"] == "pass"
                and card["checks"]["snapshot_rule"] == "pass"
            ),
            "functional_classification_cards_required": len(REQUIRED_FUNCTION_TAGS),
            "functional_classification_cards_passed": sum(
                1
                for card in cards
                if card["checks"]["functional_tags"] in {"pass", "not_required"}
            ),
            "checks_total": len(checks),
            "checks_failed": fail_count,
            "xmage_source_found_count": xmage_found_count,
            "xmage_source_missing_count": len(EXPECTED_RULES) - xmage_found_count,
        },
        "cards": cards,
        "checks": checks,
    }
    return report


def write_markdown(report: dict[str, Any], path: Path) -> None:
    lines = [
        "# Priority Lorehold Card Validation Audit",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- PostgreSQL target: `{report['postgres_target']}`",
        f"- SQLite DB: `{report['sqlite_db']}`",
        f"- Snapshot: `{report['snapshot_path']}`",
        f"- Summary: `{json.dumps(report['summary'], sort_keys=True)}`",
        "",
        "| Card | PG rule | SQLite rule | Snapshot | Functional tags | Battle scope(s) | Missing tags | XMage source |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for card in report["cards"]:
        scopes = ", ".join(rule["scope"] for rule in card["expected_rules"])
        missing_tags = ", ".join(card["missing_function_tags"])
        xmage_source = "found" if card["xmage_source_path"] else "missing"
        lines.append(
            "| `{card}` | `{pg}` | `{sqlite}` | `{snapshot}` | `{tags}` | {scopes} | {missing} | `{xmage}` |".format(
                card=card["card_name"],
                pg=card["checks"]["pg_rule"],
                sqlite=card["checks"]["sqlite_rule"],
                snapshot=card["checks"]["snapshot_rule"],
                tags=card["checks"]["functional_tags"],
                scopes=scopes.replace("|", "\\|"),
                missing=missing_tags.replace("|", "\\|") or "-",
                xmage=xmage_source,
            )
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sqlite-db", type=Path, default=DEFAULT_SQLITE_DB)
    parser.add_argument("--snapshot", type=Path, default=DEFAULT_SNAPSHOT)
    parser.add_argument("--xmage-root", type=Path, default=DEFAULT_XMAGE_ROOT)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "priority_lorehold_card_validation_audit_20260707",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        xmage_root = engine_source_contract.resolve_xmage_source_root(args.xmage_root)
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc
    report = build_report(args.sqlite_db, args.snapshot, xmage_root)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(
        json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    write_markdown(report, md_path)
    print(
        json.dumps(
            {
                "status": report["status"],
                "summary": report["summary"],
                "json": str(json_path),
                "markdown": str(md_path),
            },
            sort_keys=True,
        )
    )
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
