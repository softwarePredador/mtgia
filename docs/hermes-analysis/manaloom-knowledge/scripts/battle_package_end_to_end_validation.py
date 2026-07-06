#!/usr/bin/env python3
"""Generic end-to-end validation for battle-rule packages.

The manifest drives the same proof chain used by PGC060:

PostgreSQL -> SQLite/Hermes cache -> canonical fallback snapshot ->
runtime lookup -> focused battle execution scenario.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import random
import sqlite3
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import db_helper
from master_optimizer_common import resolve_default_knowledge_db


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_SQLITE_DB = resolve_default_knowledge_db()
DEFAULT_SNAPSHOT = SCRIPT_DIR / "known_cards_canonical_snapshot.json"
DEFAULT_BATTLE = SCRIPT_DIR / "battle_analyst_v9.py"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--sqlite-db", default=str(DEFAULT_SQLITE_DB))
    parser.add_argument("--snapshot", default=str(DEFAULT_SNAPSHOT))
    parser.add_argument("--battle-path", default=str(DEFAULT_BATTLE))
    parser.add_argument("--output-json")
    parser.add_argument("--output-md")
    return parser.parse_args()


def fail(stage: str, detail: str) -> None:
    raise AssertionError(f"{stage}: {detail}")


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def load_battle(path: Path):
    spec = importlib.util.spec_from_file_location("battle_under_test", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load battle module from {path}")
    battle = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(battle)
    return battle


def collect_annotation_fields(value: Any, path: str = "") -> list[str]:
    found: list[str] = []
    if isinstance(value, dict):
        for key, item in value.items():
            child_path = f"{path}.{key}" if path else str(key)
            if item == "annotation_only":
                found.append(child_path)
            found.extend(collect_annotation_fields(item, child_path))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            found.extend(collect_annotation_fields(item, f"{path}[{index}]"))
    return found


def get_path(value: Any, path: str) -> Any:
    current = value
    for part in str(path).split("."):
        if isinstance(current, dict):
            current = current.get(part)
        else:
            return None
    return current


def expected_rule_identity(rule: dict[str, Any]) -> tuple[str, str]:
    logical_key = str(rule.get("logical_rule_key") or "").strip()
    normalized_name = str(rule.get("normalized_name") or "").strip()
    if not normalized_name:
        normalized_name = str(rule.get("card_name") or "").strip().lower()
    if not logical_key:
        fail("manifest", "expected_rules entry missing logical_rule_key")
    if not normalized_name:
        fail("manifest", f"expected rule {logical_key} missing normalized_name/card_name")
    return normalized_name, logical_key


def expected_rules_by_key(manifest: dict[str, Any]) -> dict[tuple[str, str], dict[str, Any]]:
    rules = manifest.get("expected_rules") or []
    by_key: dict[tuple[str, str], dict[str, Any]] = {}
    for rule in rules:
        key = expected_rule_identity(rule)
        if key in by_key:
            fail("manifest", f"duplicate expected rule {key[0]} {key[1]}")
        by_key[key] = dict(rule)
    if not by_key:
        fail("manifest", "expected_rules must not be empty")
    return by_key


def find_expected_rule(
    expected_by_key: dict[tuple[str, str], dict[str, Any]],
    logical_key: str,
    *,
    card_name: str | None = None,
    normalized_name: str | None = None,
) -> dict[str, Any]:
    normalized = str(normalized_name or "").strip()
    if not normalized and card_name:
        normalized = str(card_name).strip().lower()
    if normalized:
        expected = expected_by_key.get((normalized, logical_key))
        if expected is not None:
            return expected
    matches = [
        expected
        for (expected_name, expected_key), expected in expected_by_key.items()
        if expected_key == logical_key
        and (not normalized or expected_name == normalized)
    ]
    if len(matches) == 1:
        return matches[0]
    fail("manifest", f"unable to resolve expected rule for {normalized or card_name} {logical_key}")


def snapshot_check_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any]:
    required = dict(rule.get("required_effect_fields") or {})
    snapshot_required = {}
    if required.get("battle_model_scope") is not None:
        snapshot_required["battle_model_scope"] = required["battle_model_scope"]
    return {
        "card_name": rule["card_name"],
        "normalized_name": rule.get("normalized_name"),
        "logical_rule_key": rule["logical_rule_key"],
        "oracle_hash": rule.get("oracle_hash"),
        "review_status": rule.get("review_status", "verified"),
        "execution_status": rule.get("execution_status", "auto"),
        "min_rule_version": rule.get("min_rule_version", 1),
        "required_effect_fields": snapshot_required,
        "forbid_annotation_only": bool(rule.get("forbid_annotation_only", True)),
    }


def runtime_check_from_expected_rule(rule: dict[str, Any]) -> dict[str, Any]:
    required = dict(rule.get("required_effect_fields") or {})
    check = {
        "card": {"name": rule["card_name"]},
        "card_name": rule["card_name"],
        "normalized_name": rule.get("normalized_name"),
        "logical_rule_key": rule["logical_rule_key"],
        "required_effect_fields": required,
        "forbid_annotation_only": bool(rule.get("forbid_annotation_only", True)),
    }
    if required.get("effect") is not None:
        check["effect"] = required["effect"]
    return check


def resolve_manifest_checks(
    manifest: dict[str, Any],
    field: str,
    expected_by_key: dict[tuple[str, str], dict[str, Any]],
    factory,
) -> list[dict[str, Any]]:
    raw_checks = manifest.get(field)
    if raw_checks is None:
        checks = [factory(rule) for rule in expected_by_key.values()]
    else:
        if not isinstance(raw_checks, list):
            fail("manifest", f"{field} must be a list")
        checks = raw_checks
    if not checks:
        fail("manifest", f"{field} resolved empty; expected_rules must be exercised")
    return checks


def validate_effect_fields(stage: str, logical_key: str, effect_json: dict[str, Any], expected: dict[str, Any]) -> None:
    required = expected.get("required_effect_fields") or expected.get("fields") or {}
    for field, expected_value in required.items():
        actual = get_path(effect_json, field)
        if actual != expected_value:
            fail(stage, f"{logical_key} {field}={actual!r}, expected {expected_value!r}")
    forbidden_annotations = bool(expected.get("forbid_annotation_only", True))
    if forbidden_annotations:
        annotations = collect_annotation_fields(effect_json)
        if annotations:
            fail(stage, f"{logical_key} still has annotation_only fields: {annotations}")


def validate_rule_row(stage: str, logical_key: str, row: dict[str, Any], expected: dict[str, Any]) -> dict[str, Any]:
    effect_json = row.get("effect_json") or {}
    if isinstance(effect_json, str):
        effect_json = json.loads(effect_json)
    if expected.get("normalized_name") and row.get("normalized_name") != expected["normalized_name"]:
        fail(stage, f"{logical_key} normalized_name={row.get('normalized_name')!r}")
    if expected.get("card_name") and row.get("card_name") != expected["card_name"]:
        fail(stage, f"{logical_key} card_name={row.get('card_name')!r}")
    if expected.get("oracle_hash") and row.get("oracle_hash") != expected["oracle_hash"]:
        fail(stage, f"{logical_key} oracle_hash={row.get('oracle_hash')!r}")
    expected_review = expected.get("review_status", "verified")
    if expected_review and row.get("review_status") != expected_review:
        fail(stage, f"{logical_key} review_status={row.get('review_status')!r}")
    expected_execution = expected.get("execution_status", "auto")
    if expected_execution and row.get("execution_status") != expected_execution:
        fail(stage, f"{logical_key} execution_status={row.get('execution_status')!r}")
    min_version = int(expected.get("min_rule_version") or 1)
    if int(row.get("rule_version") or 0) < min_version:
        fail(stage, f"{logical_key} rule_version={row.get('rule_version')!r}")
    validate_effect_fields(stage, logical_key, effect_json, expected)
    return {
        "logical_rule_key": logical_key,
        "card_name": row.get("card_name"),
        "review_status": row.get("review_status"),
        "execution_status": row.get("execution_status"),
        "rule_version": int(row.get("rule_version") or 0),
        "oracle_hash": row.get("oracle_hash"),
        "battle_model_scope": effect_json.get("battle_model_scope"),
        "annotation_fields": collect_annotation_fields(effect_json),
    }


def fetch_postgres_rows(expected_by_key: dict[tuple[str, str], dict[str, Any]]) -> dict[tuple[str, str], dict[str, Any]]:
    logical_keys = sorted({logical_key for _normalized, logical_key in expected_by_key})
    normalized_names = sorted({normalized for normalized, _logical_key in expected_by_key})
    with closing(db_helper.connect()) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT normalized_name, logical_rule_key, card_name, effect_json,
                       source, confidence, review_status, execution_status,
                       rule_version, oracle_hash, reviewed_by
                FROM public.card_battle_rules
                WHERE logical_rule_key IN %s
                  AND normalized_name IN %s
                ORDER BY logical_rule_key
                """,
                (tuple(logical_keys), tuple(normalized_names)),
            )
            columns = [desc[0] for desc in cur.description]
            return {
                (
                    row[columns.index("normalized_name")],
                    row[columns.index("logical_rule_key")],
                ): dict(zip(columns, row))
                for row in cur.fetchall()
            }


def validate_postgres(expected_by_key: dict[tuple[str, str], dict[str, Any]]) -> list[dict[str, Any]]:
    rows = fetch_postgres_rows(expected_by_key)
    missing = sorted(set(expected_by_key) - set(rows))
    if missing:
        fail("postgres", f"missing expected rows: {missing}")
    return [
        validate_rule_row("postgres", key[1], rows[key], expected_by_key[key])
        for key in expected_by_key
    ]


def validate_sqlite(path: Path, expected_by_key: dict[tuple[str, str], dict[str, Any]]) -> list[dict[str, Any]]:
    if not path.exists():
        fail("sqlite", f"missing db {path}")
    logical_keys = sorted({logical_key for _normalized, logical_key in expected_by_key})
    normalized_names = sorted({normalized for normalized, _logical_key in expected_by_key})
    logical_placeholders = ",".join("?" for _ in logical_keys)
    normalized_placeholders = ",".join("?" for _ in normalized_names)
    with closing(sqlite3.connect(path)) as conn:
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            f"""
            SELECT normalized_name, logical_rule_key, card_name, effect_json,
                   source, confidence, review_status, execution_status,
                   rule_version, oracle_hash
            FROM battle_card_rules
            WHERE logical_rule_key IN ({logical_placeholders})
              AND normalized_name IN ({normalized_placeholders})
            ORDER BY logical_rule_key
            """,
            (*logical_keys, *normalized_names),
        ).fetchall()
    by_key = {(row["normalized_name"], row["logical_rule_key"]): dict(row) for row in rows}
    missing = sorted(set(expected_by_key) - set(by_key))
    if missing:
        fail("sqlite", f"missing expected rows: {missing}")
    return [
        validate_rule_row("sqlite", key[1], by_key[key], expected_by_key[key])
        for key in expected_by_key
    ]


def validate_snapshot(path: Path, manifest: dict[str, Any], expected_by_key: dict[tuple[str, str], dict[str, Any]]) -> list[dict[str, Any]]:
    if not path.exists():
        fail("snapshot", f"missing snapshot {path}")
    snapshot = load_json(path)
    checks = resolve_manifest_checks(
        manifest,
        "snapshot_checks",
        expected_by_key,
        snapshot_check_from_expected_rule,
    )
    results: list[dict[str, Any]] = []
    for check in checks:
        card_name = str(check.get("card_name") or "").strip()
        logical_key = str(check.get("logical_rule_key") or "").strip()
        if not card_name or not logical_key:
            fail("snapshot", "snapshot_checks entries require card_name and logical_rule_key")
        entry = snapshot.get(card_name)
        if not isinstance(entry, dict):
            fail("snapshot", f"missing card {card_name}")
        expected = {
            **find_expected_rule(expected_by_key, logical_key, card_name=card_name),
            **check,
        }
        if entry.get("battle_rule_logical_key") != logical_key:
            fail("snapshot", f"{card_name} logical key={entry.get('battle_rule_logical_key')!r}")
        if expected.get("oracle_hash") and entry.get("battle_rule_oracle_hash") != expected["oracle_hash"]:
            fail("snapshot", f"{card_name} oracle hash={entry.get('battle_rule_oracle_hash')!r}")
        expected_review = expected.get("review_status", "verified")
        if expected_review and entry.get("battle_rule_review_status") != expected_review:
            fail("snapshot", f"{card_name} review={entry.get('battle_rule_review_status')!r}")
        expected_execution = expected.get("execution_status", "auto")
        if expected_execution and entry.get("battle_rule_execution_status") != expected_execution:
            fail("snapshot", f"{card_name} execution={entry.get('battle_rule_execution_status')!r}")
        min_version = int(expected.get("min_rule_version") or 1)
        if int(entry.get("battle_rule_version") or 0) < min_version:
            fail("snapshot", f"{card_name} version={entry.get('battle_rule_version')!r}")
        validate_effect_fields("snapshot", logical_key, entry, expected)
        results.append({
            "card_name": card_name,
            "logical_rule_key": logical_key,
            "battle_rule_version": int(entry.get("battle_rule_version") or 0),
            "battle_model_scope": entry.get("battle_model_scope"),
            "annotation_fields": collect_annotation_fields(entry),
        })
    return results


def component_by_key(effect: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(component.get("_rule_logical_key") or ""): component
        for component in effect.get("_composite_rule_components", [])
        if isinstance(component, dict)
    }


def validate_runtime_lookup(battle, manifest: dict[str, Any]) -> list[dict[str, Any]]:
    expected_by_key = expected_rules_by_key(manifest)
    checks = resolve_manifest_checks(
        manifest,
        "runtime_checks",
        expected_by_key,
        runtime_check_from_expected_rule,
    )
    results: list[dict[str, Any]] = []
    for check in checks:
        card = check.get("card") or {}
        card_name = str(card.get("name") or check.get("card_name") or "").strip()
        if not card_name:
            fail("runtime_lookup", "runtime check missing card name")
        effect = battle.get_card_effect(card)
        expected_effect = check.get("effect")
        if expected_effect and effect.get("effect") != expected_effect:
            fail("runtime_lookup", f"{card_name} effect={effect.get('effect')!r}")
        logical_key = check.get("logical_rule_key")
        if logical_key and effect.get("_rule_logical_key") != logical_key:
            fail("runtime_lookup", f"{card_name} logical key={effect.get('_rule_logical_key')!r}")
        validate_effect_fields("runtime_lookup", str(logical_key or card_name), effect, check)
        expected_components = check.get("components") or []
        components = component_by_key(effect)
        for component_check in expected_components:
            component_key = str(component_check.get("logical_rule_key") or "").strip()
            component = components.get(component_key)
            if component is None:
                fail("runtime_lookup", f"{card_name} missing component {component_key}")
            validate_effect_fields("runtime_lookup", component_key, component, component_check)
        results.append({
            "card_name": card_name,
            "effect": effect.get("effect"),
            "logical_rule_key": effect.get("_rule_logical_key"),
            "component_keys": sorted(key for key in components if key),
            "annotation_fields": collect_annotation_fields(effect),
        })
    return results


def event_payloads(events: list[tuple[str, dict[str, Any]]], event_name: str, card_name: str) -> list[dict[str, Any]]:
    return [
        data
        for event, data in events
        if event == event_name and data.get("card") == card_name
    ]


def run_token_maker_attack_each_opponent(battle, scenario: dict[str, Any], events: list[tuple[str, dict[str, Any]]]) -> dict[str, Any]:
    card = scenario["card"]
    turn = int(scenario.get("turn") or 7)
    opponents = [
        battle.Player(str(name), None, [])
        for name in scenario.get("opponents", ["Opponent A", "Opponent B", "Opponent C"])
    ]
    active = battle.Player(str(scenario.get("player") or "Lorehold"), None, [])
    all_players = [active, *opponents]
    battle.apply_effect_immediate(active, opponents, card, turn=turn, rng=random.Random(int(scenario.get("seed") or 6060)))
    token_name = str(scenario.get("token_name") or "Token")
    tokens = [
        permanent
        for permanent in active.battlefield
        if isinstance(permanent, dict) and permanent.get("name") == token_name
    ]
    expected_tokens = int(scenario["expected_tokens"])
    if len(tokens) != expected_tokens:
        fail("battle_execution", f"{card['name']} token count={len(tokens)}, expected {expected_tokens}")
    assigned: dict[str, int] = {}
    for token in tokens:
        if scenario.get("must_attack_if_able", True) and token.get("must_attack_if_able") is not True:
            fail("battle_execution", f"{card['name']} token missing must_attack_if_able: {token}")
        assigned[token.get("must_attack_defender")] = assigned.get(token.get("must_attack_defender"), 0) + 1
    expected_assignment = scenario.get("expected_assignment") or {}
    if assigned != expected_assignment:
        fail("battle_execution", f"{card['name']} attack assignments={assigned}")
    declared = battle.declare_attackers_step(active, opponents, all_players, turn=turn)
    if declared is None:
        fail("battle_execution", "declare_attackers_step returned None")
    attack_groups = {
        defender.name: len(group_attackers)
        for defender, group_attackers in declared[4]
    }
    if attack_groups != expected_assignment:
        fail("battle_execution", f"{card['name']} attack groups={attack_groups}")
    token_events = event_payloads(events, "tokens_created", str(card["name"]))
    if not any(data.get("tokens_created") == expected_tokens for data in token_events):
        fail("battle_events", f"missing {card['name']} tokens_created event")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "tokens_created": len(tokens),
        "attack_assignment_by_opponent": assigned,
        "multi_defender_attack_groups": attack_groups,
    }


def token_matches_expected(battle, token: dict[str, Any], expected: dict[str, Any]) -> tuple[bool, str]:
    expected_name = str(expected.get("name") or "")
    if expected_name and token.get("name") != expected_name:
        return False, f"name={token.get('name')!r}"
    if expected.get("power") is not None and int(token.get("power") or 0) != int(expected["power"]):
        return False, f"power={token.get('power')}"
    if expected.get("toughness") is not None and int(token.get("toughness") or 0) != int(expected["toughness"]):
        return False, f"toughness={token.get('toughness')}"
    expected_subtype = expected.get("subtype")
    if expected_subtype and str(expected_subtype) not in str(token.get("type_line") or ""):
        return False, f"type_line={token.get('type_line')!r}"
    expected_colors = expected.get("colors") or []
    if expected_colors and list(token.get("colors") or []) != list(expected_colors):
        return False, f"colors={token.get('colors')!r}"
    for keyword in expected.get("keywords") or []:
        if not battle.card_has_keyword(token, str(keyword)):
            return False, f"missing keyword {keyword!r}"
    if bool(expected.get("artifact")) and "artifact" not in str(token.get("type_line") or "").lower():
        return False, "artifact token type missing"
    if bool(token.get("tapped")) != bool(expected.get("tapped")):
        return False, f"tapped={token.get('tapped')}"
    if bool(expected.get("sacrifice_for_colorless_mana")):
        if token.get("sacrifice_for_colorless_mana") is not True:
            return False, "missing sacrifice mana ability"
        if int(token.get("mana_produced") or 0) != int(expected.get("mana_produced") or 1):
            return False, f"mana_produced={token.get('mana_produced')}"
        if token.get("produces") != expected.get("produces", "C"):
            return False, f"produces={token.get('produces')!r}"
        expected_symbols = list(expected.get("produced_mana_symbols") or ["C"])
        if list(token.get("produced_mana_symbols") or []) != expected_symbols:
            return False, f"produced_mana_symbols={token.get('produced_mana_symbols')!r}"
    return True, ""


def assert_expected_token_multiset(
    battle,
    actual_tokens: list[dict[str, Any]],
    expected_tokens: list[dict[str, Any]],
    card_name: str,
) -> list[dict[str, Any]]:
    unmatched = list(actual_tokens)
    matched: list[dict[str, Any]] = []
    for expected in expected_tokens:
        expected_count = int(expected.get("count") or 1)
        for _ in range(expected_count):
            match_index = None
            mismatch_reasons: list[str] = []
            for index, token in enumerate(unmatched):
                ok, reason = token_matches_expected(battle, token, expected)
                if ok:
                    match_index = index
                    break
                mismatch_reasons.append(reason)
            if match_index is None:
                fail(
                    "battle_execution",
                    f"{card_name} missing expected token {expected.get('name')!r}: {mismatch_reasons[:5]}",
                )
            matched.append(unmatched.pop(match_index))
    return matched


def run_fixed_create_creature_tokens(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Token Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])

    def add_support_creature(owner, name: str, *, power: int = 1, toughness: int = 1, tapped: bool = False, attacking: bool = False, subtype: str = "Soldier") -> None:
        owner.battlefield.append(
            {
                "name": name,
                "type_line": f"Creature - {subtype}",
                "subtypes": [subtype],
                "power": power,
                "toughness": toughness,
                "effect": "creature",
                "tapped": bool(tapped),
                "attacking": bool(attacking),
            }
        )

    support_subtype = str(scenario.get("controlled_permanent_subtype") or "").strip()
    support_count = int(scenario.get("controlled_permanent_subtype_count") or 0)
    for index in range(max(0, support_count)):
        active.battlefield.append(
            {
                "name": f"{support_subtype or 'Subtype'} Support {index + 1}",
                "type_line": f"Creature - {support_subtype or 'Subtype'}",
                "subtypes": [support_subtype] if support_subtype else [],
                "power": 1,
                "toughness": 1,
                "effect": "creature",
            }
        )
    for index in range(max(0, int(scenario.get("controlled_battlefield_creature_count") or 0))):
        add_support_creature(active, f"Controlled Creature {index + 1}")
    for index in range(max(0, int(scenario.get("opponent_battlefield_creature_count") or 0))):
        add_support_creature(opponent, f"Opponent Creature {index + 1}")
    for index in range(max(0, int(scenario.get("attacking_creature_count") or 0))):
        add_support_creature(active, f"Attacking Creature {index + 1}", attacking=True)
    for index in range(max(0, int(scenario.get("controlled_tapped_creature_count") or 0))):
        add_support_creature(active, f"Tapped Creature {index + 1}", tapped=True)
    for index, power in enumerate(scenario.get("controlled_creature_powers") or []):
        add_support_creature(active, f"Powered Creature {index + 1}", power=int(power or 0), toughness=max(1, int(power or 0)))
    for index in range(max(0, int(scenario.get("controller_hand_card_count") or 0))):
        active.hand.append({"name": f"Hand Support {index + 1}", "type_line": "Sorcery"})
    for subtype in scenario.get("domain_basic_land_subtypes") or []:
        subtype_name = str(subtype or "").strip()
        if subtype_name:
            active.battlefield.append(
                {
                    "name": subtype_name,
                    "type_line": f"Basic Land - {subtype_name}",
                    "subtypes": [subtype_name],
                    "effect": "land",
                }
            )
    for index in range(max(0, int(scenario.get("controller_graveyard_creature_count") or 0))):
        active.graveyard.append({"name": f"Graveyard Creature {index + 1}", "type_line": "Creature - Scout"})
    for index in range(max(0, int(scenario.get("controller_graveyard_instant_sorcery_count") or 0))):
        type_line = "Instant" if index % 2 == 0 else "Sorcery"
        active.graveyard.append({"name": f"Graveyard {type_line} {index + 1}", "type_line": type_line})
    named_graveyard_card = str(scenario.get("controller_graveyard_named_card") or "").strip()
    for index in range(max(0, int(scenario.get("controller_graveyard_named_card_count") or 0))):
        active.graveyard.append({"name": named_graveyard_card or card["name"], "type_line": "Sorcery"})
    before_events = len(events)
    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 6066)),
    )

    expected = dict(scenario.get("expected_token") or {})
    expected_name = str(expected.get("name") or "")
    expected_count = int(expected.get("count") or 1)
    actual_tokens = [
        permanent
        for permanent in active.battlefield
        if isinstance(permanent, dict) and battle.is_token_permanent(permanent)
    ]
    matches = [token for token in actual_tokens if token.get("name") == expected_name]
    if len(matches) != expected_count:
        fail("battle_execution", f"{card['name']} {expected_name} count={len(matches)}, expected {expected_count}")
    for token in matches:
        if expected.get("power") is not None and int(token.get("power") or 0) != int(expected["power"]):
            fail("battle_execution", f"{card['name']} {expected_name} power={token.get('power')}")
        if expected.get("toughness") is not None and int(token.get("toughness") or 0) != int(expected["toughness"]):
            fail("battle_execution", f"{card['name']} {expected_name} toughness={token.get('toughness')}")
        expected_subtype = expected.get("subtype")
        if expected_subtype and str(expected_subtype) not in str(token.get("type_line") or ""):
            fail("battle_execution", f"{card['name']} {expected_name} type_line={token.get('type_line')!r}")
        expected_colors = expected.get("colors") or []
        if expected_colors and list(token.get("colors") or []) != list(expected_colors):
            fail("battle_execution", f"{card['name']} {expected_name} colors={token.get('colors')!r}")
        for keyword in expected.get("keywords") or []:
            if not battle.card_has_keyword(token, str(keyword)):
                fail("battle_execution", f"{card['name']} {expected_name} missing keyword {keyword!r}")
        if bool(expected.get("artifact")) and "artifact" not in str(token.get("type_line") or "").lower():
            fail("battle_execution", f"{card['name']} {expected_name} artifact token type missing")
        if bool(token.get("tapped")) != bool(expected.get("tapped")):
            fail("battle_execution", f"{card['name']} {expected_name} tapped={token.get('tapped')}")

    token_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "tokens_created"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if token_event is None:
        fail("battle_events", f"missing {card['name']} tokens_created event")
    if int(token_event.get("tokens_created") or 0) != expected_count:
        fail("battle_events", f"{card['name']} event tokens_created={token_event.get('tokens_created')}")
    if bool(token_event.get("token_tapped")) != bool(expected.get("tapped")):
        fail("battle_events", f"{card['name']} event token_tapped={token_event.get('token_tapped')}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "tokens_created": len(matches),
        "token_name": expected_name,
        "token_tapped": bool(expected.get("tapped")),
    }


def run_multi_create_creature_tokens(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Token Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    before_events = len(events)
    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 6065)),
    )

    expected_tokens = scenario.get("expected_tokens") or []
    expected_total = int(
        scenario.get("expected_total_tokens")
        or sum(int(token.get("count") or 0) for token in expected_tokens)
    )
    actual_tokens = [
        permanent
        for permanent in active.battlefield
        if isinstance(permanent, dict) and battle.is_token_permanent(permanent)
    ]
    if len(actual_tokens) != expected_total:
        fail("battle_execution", f"{card['name']} token total={len(actual_tokens)}, expected {expected_total}")
    assert_expected_token_multiset(battle, actual_tokens, expected_tokens, card["name"])

    composite_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "composite_rule_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if composite_event is None:
        fail("battle_events", f"missing {card['name']} composite_rule_resolved event")
    expected_component_count = int(scenario.get("expected_component_count") or len(expected_tokens))
    if int(composite_event.get("components_applied") or 0) != expected_component_count:
        fail(
            "battle_events",
            f"{card['name']} components_applied={composite_event.get('components_applied')}",
        )
    if int(composite_event.get("components_skipped") or 0) != 0:
        fail("battle_events", f"{card['name']} skipped composite components")

    component_events = [
        data
        for event, data in events[before_events:]
        if event == "composite_rule_component_resolved"
        and data.get("card") == card.get("name")
        and data.get("component_effect") == "token_maker"
    ]
    if len(component_events) != expected_component_count:
        fail("battle_events", f"{card['name']} component events={len(component_events)}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "tokens_created": len(actual_tokens),
        "component_count": len(component_events),
        "token_names": sorted(token.get("name") for token in actual_tokens),
    }


def run_dynamic_life_gain(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Life Gain Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.life = int(scenario.get("starting_life") or 20)
    active.hand = [dict(item) for item in scenario.get("controller_hand") or []]
    active.battlefield = [dict(item) for item in scenario.get("controller_battlefield") or []]
    active.graveyard = [dict(item) for item in scenario.get("controller_graveyard") or []]
    opponent.battlefield = [dict(item) for item in scenario.get("opponent_battlefield") or []]
    opponent.graveyard = [dict(item) for item in scenario.get("opponent_graveyard") or []]

    before_events = len(events)
    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 5),
        rng=random.Random(int(scenario.get("seed") or 6069)),
    )

    expected_life_after = int(scenario.get("expected_life_after") or active.life)
    expected_life_gain = int(scenario.get("expected_life_gain") or 0)
    if active.life != expected_life_after:
        fail(
            "battle_execution",
            f"{card['name']} life after dynamic gain={active.life}, expected {expected_life_after}",
        )
    life_events = [
        data
        for event, data in events[before_events:]
        if event == "life_total_changed" and data.get("card") == card.get("name")
    ]
    if not life_events:
        fail("battle_events", f"missing {card['name']} life_total_changed event")
    event = life_events[-1]
    if int(event.get("requested_delta") or 0) != expected_life_gain:
        fail(
            "battle_events",
            f"{card['name']} requested_delta={event.get('requested_delta')}, expected {expected_life_gain}",
        )
    expected_source = scenario.get("expected_life_gain_source")
    if expected_source and event.get("life_gain_amount_source") != expected_source:
        fail(
            "battle_events",
            f"{card['name']} life_gain_amount_source={event.get('life_gain_amount_source')!r}",
        )
    expected_count = scenario.get("expected_dynamic_count")
    if expected_count is not None and int(event.get("dynamic_life_gain_count") or 0) != int(expected_count):
        fail(
            "battle_events",
            f"{card['name']} dynamic_life_gain_count={event.get('dynamic_life_gain_count')}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "life_after": active.life,
        "life_gained": expected_life_gain,
        "life_gain_amount_source": event.get("life_gain_amount_source"),
        "dynamic_life_gain_count": event.get("dynamic_life_gain_count"),
    }


def run_creature_etb_dynamic_life_gain(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "ETB Life Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.life = int(scenario.get("starting_life") or 20)
    active.hand = [dict(item) for item in scenario.get("controller_hand") or []]
    active.battlefield = [dict(item) for item in scenario.get("controller_battlefield") or []]
    active.graveyard = [dict(item) for item in scenario.get("controller_graveyard") or []]
    opponent.battlefield = [dict(item) for item in scenario.get("opponent_battlefield") or []]
    opponent.graveyard = [dict(item) for item in scenario.get("opponent_graveyard") or []]

    effect_data = battle.get_card_effect(card)
    permanent = battle.prepare_entering_permanent(
        battle.enrich_card({**card, **effect_data}),
        controller=active,
        all_players=[active, opponent],
        turn=int(scenario.get("turn") or 6),
    )
    active.battlefield.append(permanent)

    before_events = len(events)
    battle.resolve_generic_permanent_etb(
        active,
        [opponent],
        permanent,
        effect_data,
        int(scenario.get("turn") or 6),
        random.Random(int(scenario.get("seed") or 6070)),
        all_players=[active, opponent],
    )

    expected_life_after = int(scenario.get("expected_life_after") or active.life)
    expected_life_gain = int(scenario.get("expected_life_gain") or 0)
    if active.life != expected_life_after:
        fail(
            "battle_execution",
            f"{card['name']} life after ETB dynamic gain={active.life}, expected {expected_life_after}",
        )
    event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "trigger_resolved"
            and data.get("card") == card.get("name")
            and data.get("effect") == "gain_life"
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} ETB gain_life trigger_resolved event")
    if int(event.get("life_gain_requested") or 0) != expected_life_gain:
        fail(
            "battle_events",
            f"{card['name']} life_gain_requested={event.get('life_gain_requested')}, expected {expected_life_gain}",
        )
    expected_source = scenario.get("expected_life_gain_source")
    if expected_source and event.get("life_gain_amount_source") != expected_source:
        fail(
            "battle_events",
            f"{card['name']} life_gain_amount_source={event.get('life_gain_amount_source')!r}",
        )
    expected_count = scenario.get("expected_dynamic_count")
    if expected_count is not None and int(event.get("dynamic_life_gain_count") or 0) != int(expected_count):
        fail(
            "battle_events",
            f"{card['name']} dynamic_life_gain_count={event.get('dynamic_life_gain_count')}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "life_after": active.life,
        "life_gained": expected_life_gain,
        "life_gain_amount_source": event.get("life_gain_amount_source"),
        "dynamic_life_gain_count": event.get("dynamic_life_gain_count"),
    }


def run_creature_enters_life_gain(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Life Trigger Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    all_players = [active, opponent]
    active.life = int(scenario.get("starting_life") or 20)
    opponent.life = int(scenario.get("opponent_starting_life") or 20)
    turn = int(scenario.get("turn") or 6)
    effect_data = battle.get_card_effect(card)
    source = battle.prepare_entering_permanent(
        battle.enrich_card({**card, **effect_data}),
        controller=active,
        all_players=all_players,
        turn=turn,
    )

    entering_controller_name = str(scenario.get("entering_controller") or "controller")
    if entering_controller_name == "opponent":
        entering_controller = opponent
        entering_opponents = [active]
    else:
        entering_controller = active
        entering_opponents = [opponent]

    if bool(scenario.get("source_starts_on_battlefield")):
        active.battlefield.append(source)
        entering_card = dict(scenario.get("entering_creature") or {
            "name": "E2E Entering Creature",
            "type_line": "Creature - Soldier",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
        })
        entering = battle.prepare_entering_permanent(
            battle.enrich_card(entering_card),
            controller=entering_controller,
            all_players=all_players,
            turn=turn,
        )
    else:
        entering = source

    entering_controller.battlefield.append(entering)
    before_events = len(events)
    battle.process_controlled_creature_enters_triggers(
        entering_controller,
        entering_opponents,
        entering,
        turn,
        all_players=all_players,
    )
    battle.process_opponent_controlled_creature_enters_triggers(
        entering_controller,
        entering,
        turn,
        all_players=all_players,
    )

    expected_life_after = int(scenario.get("expected_life_after") or active.life)
    expected_life_gain = int(scenario.get("expected_life_gain") or 0)
    if active.life != expected_life_after:
        fail(
            "battle_execution",
            f"{card['name']} life after creature-enter trigger={active.life}, expected {expected_life_after}",
        )
    event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "trigger_resolved"
            and data.get("card") == card.get("name")
            and data.get("effect") == "gain_life"
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} creature-enter gain_life trigger_resolved event")
    if int(event.get("life_gain_requested") or event.get("amount") or 0) != expected_life_gain:
        fail(
            "battle_events",
            f"{card['name']} life_gain_requested={event.get('life_gain_requested')}, expected {expected_life_gain}",
        )
    expected_trigger = scenario.get("expected_trigger")
    if expected_trigger and event.get("trigger") != expected_trigger:
        fail(
            "battle_events",
            f"{card['name']} trigger={event.get('trigger')!r}, expected {expected_trigger!r}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "life_after": active.life,
        "life_gained": expected_life_gain,
        "trigger": event.get("trigger"),
        "entering_controller": event.get("entering_controller"),
    }


def run_spell_cast_gain_life(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Spell Life Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    all_players = [active, opponent]
    active.life = int(scenario.get("starting_life") or 20)
    turn = int(scenario.get("turn") or 6)
    effect_data = battle.get_card_effect(card)
    source = battle.prepare_entering_permanent(
        battle.enrich_card({**card, **effect_data}),
        controller=active,
        all_players=all_players,
        turn=turn,
    )
    active.battlefield.append(source)

    nonmatching_spell = scenario.get("nonmatching_spell")
    if isinstance(nonmatching_spell, dict):
        before_life = active.life
        before_events = len(events)
        battle.trigger_spell_cast_engines(
            active,
            all_players,
            dict(nonmatching_spell),
            turn=turn,
            phase="precombat_main",
        )
        if active.life != before_life:
            fail(
                "battle_execution",
                f"{card['name']} gained life from nonmatching spell {nonmatching_spell.get('name')}",
            )
        unexpected = next(
            (
                data
                for event_name, data in events[before_events:]
                if event_name == "trigger_resolved"
                and data.get("card") == card.get("name")
                and data.get("effect") == "gain_life"
            ),
            None,
        )
        if unexpected is not None:
            fail("battle_events", f"{card['name']} triggered from nonmatching spell")

    matching_spell = dict(scenario.get("matching_spell") or {})
    if not matching_spell:
        fail("scenario", f"{card['name']} missing matching_spell")
    before_events = len(events)
    battle.trigger_spell_cast_engines(
        active,
        all_players,
        matching_spell,
        turn=turn,
        phase="precombat_main",
    )

    expected_life_after = int(scenario.get("expected_life_after") or active.life)
    expected_life_gain = int(scenario.get("expected_life_gain") or 0)
    if active.life != expected_life_after:
        fail(
            "battle_execution",
            f"{card['name']} life after spell-cast gain-life trigger={active.life}, expected {expected_life_after}",
        )
    event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "trigger_resolved"
            and data.get("card") == card.get("name")
            and data.get("effect") == "gain_life"
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} spell-cast gain_life trigger_resolved event")
    if int(event.get("life_gain_requested") or 0) != expected_life_gain:
        fail(
            "battle_events",
            f"{card['name']} life_gain_requested={event.get('life_gain_requested')}, expected {expected_life_gain}",
        )
    expected_trigger = scenario.get("expected_trigger")
    if expected_trigger and event.get("trigger") != expected_trigger:
        fail(
            "battle_events",
            f"{card['name']} trigger={event.get('trigger')!r}, expected {expected_trigger!r}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "life_after": active.life,
        "life_gained": expected_life_gain,
        "trigger": event.get("trigger"),
        "trigger_spell": event.get("trigger_spell"),
    }


def run_creature_etb_create_tokens(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "ETB Token Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    effect_data = battle.get_card_effect(card)
    permanent = battle.prepare_entering_permanent(
        battle.enrich_card({**card, **effect_data}),
        controller=active,
        all_players=[active, opponent],
        turn=int(scenario.get("turn") or 6),
    )
    active.battlefield.append(permanent)

    expected_keywords = [str(value) for value in (scenario.get("expected_keywords") or [])]
    missing_keywords = [
        keyword
        for keyword in expected_keywords
        if not battle.card_has_keyword(permanent, keyword)
    ]
    if missing_keywords:
        fail(
            "battle_execution",
            f"{card['name']} missing expected ETB permanent keywords: {missing_keywords}",
        )

    before_events = len(events)
    battle.resolve_generic_permanent_etb(
        active,
        [opponent],
        permanent,
        effect_data,
        int(scenario.get("turn") or 6),
        random.Random(int(scenario.get("seed") or 6067)),
        all_players=[active, opponent],
    )

    expected_tokens = scenario.get("expected_tokens") or [scenario.get("expected_token") or {}]
    expected_total = int(
        scenario.get("expected_total_tokens")
        or sum(int(token.get("count") or 0) for token in expected_tokens)
    )
    actual_tokens = [
        item
        for item in active.battlefield
        if isinstance(item, dict) and battle.is_token_permanent(item)
    ]
    if len(actual_tokens) != expected_total:
        fail("battle_execution", f"{card['name']} ETB token total={len(actual_tokens)}, expected {expected_total}")
    assert_expected_token_multiset(battle, actual_tokens, expected_tokens, card["name"])

    token_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "etb_token_maker_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if token_event is None:
        fail("battle_events", f"missing {card['name']} etb_token_maker_resolved event")
    if int(token_event.get("token_count") or 0) != expected_total:
        fail("battle_events", f"{card['name']} event token_count={token_event.get('token_count')}")
    if "expected_component_count" in scenario and int(token_event.get("token_component_count") or 0) != int(
        scenario.get("expected_component_count") or 0
    ):
        fail("battle_events", f"{card['name']} event token_component_count={token_event.get('token_component_count')}")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "tokens_created": len(actual_tokens),
        "token_names": sorted(token.get("name") for token in actual_tokens),
        "validated_keywords": expected_keywords,
    }


def run_creature_etb_scry(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "ETB Scry Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    library_names = list(
        scenario.get("library_top_names")
        or ["Low Priority Land", "High Priority Spell", "Medium Priority Creature"]
    )
    active.library = [
        {
            "name": str(name),
            "cmc": index + 1,
            "effect": "land" if index == 0 else "draw_cards",
            "type_line": "Land" if index == 0 else "Instant",
        }
        for index, name in enumerate(library_names)
    ]
    expected_scry_count = int(scenario.get("expected_scry_count") or 0)
    if expected_scry_count <= 0:
        fail("battle_execution", f"{card['name']} missing expected_scry_count")

    effect_data = battle.get_card_effect(card)
    permanent = battle.prepare_entering_permanent(
        battle.enrich_card({**card, **effect_data}),
        controller=active,
        all_players=[active, opponent],
        turn=int(scenario.get("turn") or 6),
    )
    active.battlefield.append(permanent)
    expected_keywords = [str(value) for value in (scenario.get("expected_keywords") or [])]
    missing_keywords = [
        keyword
        for keyword in expected_keywords
        if not battle.card_has_keyword(permanent, keyword)
    ]
    if missing_keywords:
        fail(
            "battle_execution",
            f"{card['name']} missing expected ETB permanent keywords: {missing_keywords}",
        )

    before_events = len(events)
    library_before = len(active.library)
    battle.resolve_generic_permanent_etb(
        active,
        [opponent],
        permanent,
        effect_data,
        int(scenario.get("turn") or 6),
        random.Random(int(scenario.get("seed") or 6068)),
        all_players=[active, opponent],
    )

    scry_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "etb_scry_resolved" and data.get("card") == card.get("name")
        ),
        None,
    )
    if scry_event is None:
        fail("battle_events", f"missing {card['name']} etb_scry_resolved event")
    if int(scry_event.get("scry_count") or 0) != expected_scry_count:
        fail("battle_events", f"{card['name']} event scry_count={scry_event.get('scry_count')}")
    expected_looked = min(expected_scry_count, library_before)
    if len(scry_event.get("scry_looked_at") or []) != expected_looked:
        fail("battle_events", f"{card['name']} looked_at={scry_event.get('scry_looked_at')}")
    if len(active.library) != library_before:
        fail("battle_execution", f"{card['name']} scry changed library size")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "scry_count": expected_scry_count,
        "looked_at": scry_event.get("scry_looked_at") or [],
        "top_after": scry_event.get("scry_top_after") or [],
        "validated_keywords": expected_keywords,
    }


def run_creature_dies_create_tokens(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Dies Token Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    effect_data = battle.get_card_effect(card)
    permanent = battle.enrich_card({**card, **effect_data})
    active.battlefield.append(permanent)

    expected_keywords = [str(value) for value in (scenario.get("expected_keywords") or [])]
    missing_keywords = [
        keyword
        for keyword in expected_keywords
        if not battle.card_has_keyword(permanent, keyword)
    ]
    if missing_keywords:
        fail(
            "battle_execution",
            f"{card['name']} missing expected permanent keywords: {missing_keywords}",
        )

    before_events = len(events)
    destination = battle.move_creature_from_battlefield(
        active,
        permanent,
        reason=str(scenario.get("reason") or "package_e2e_destroy"),
        source=dict(scenario.get("source") or {"name": "Package E2E Removal"}),
        all_players=[active, opponent],
    )
    if destination != "graveyard":
        fail("battle_execution", f"{card['name']} destination={destination!r}")
    if permanent not in active.graveyard:
        fail("battle_execution", f"{card['name']} not moved to controller graveyard")

    expected_tokens = scenario.get("expected_tokens")
    expected = dict(scenario.get("expected_token") or {})
    if expected_tokens:
        expected_total = int(
            scenario.get("expected_total_tokens")
            or sum(int(token.get("count") or 0) for token in expected_tokens)
        )
    else:
        expected_tokens = [expected]
        expected_total = int(expected.get("count") or 1)
    expected_name = str(expected.get("name") or "")
    expected_count = int(expected.get("count") or 1)
    actual_tokens = [
        item
        for item in active.battlefield
        if isinstance(item, dict) and battle.is_token_permanent(item)
    ]
    if len(actual_tokens) != expected_total:
        fail("battle_execution", f"{card['name']} token total={len(actual_tokens)}, expected {expected_total}")
    matches = assert_expected_token_multiset(battle, actual_tokens, expected_tokens, card["name"])

    token_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "dies_token_maker_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if token_event is None:
        fail("battle_events", f"missing {card['name']} dies_token_maker_resolved event")
    if int(token_event.get("token_count") or 0) != expected_total:
        fail("battle_events", f"{card['name']} event token_count={token_event.get('token_count')}")
    if expected_name and token_event.get("token_name") != expected_name:
        fail("battle_events", f"{card['name']} event token_name={token_event.get('token_name')!r}")
    if not scenario.get("expected_tokens") and bool(token_event.get("token_tapped")) != bool(expected.get("tapped")):
        fail("battle_events", f"{card['name']} event token_tapped={token_event.get('token_tapped')}")
    if "expected_component_count" in scenario and int(token_event.get("token_component_count") or 0) != int(
        scenario.get("expected_component_count") or 0
    ):
        fail("battle_events", f"{card['name']} event token_component_count={token_event.get('token_component_count')}")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "tokens_created": len(matches),
        "token_name": expected_name or None,
        "token_names": sorted(token.get("name") for token in matches),
        "token_tapped": bool(expected.get("tapped")) if expected else False,
        "validated_keywords": expected_keywords,
        "sacrifice_for_colorless_mana": bool(expected.get("sacrifice_for_colorless_mana")),
    }


def run_creature_dies_create_treasure(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Dies Treasure Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    effect_data = battle.get_card_effect(card)
    permanent = battle.enrich_card({**card, **effect_data})
    active.battlefield.append(permanent)

    expected_keywords = [str(value) for value in (scenario.get("expected_keywords") or [])]
    missing_keywords = [
        keyword
        for keyword in expected_keywords
        if not battle.card_has_keyword(permanent, keyword)
    ]
    if missing_keywords:
        fail(
            "battle_execution",
            f"{card['name']} missing expected permanent keywords: {missing_keywords}",
        )

    before_treasures = int(getattr(active, "treasures", 0) or 0)
    before_events = len(events)
    expected_treasure_count = int(scenario.get("expected_treasure_count") or 1)
    destination = battle.move_creature_from_battlefield(
        active,
        permanent,
        reason=str(scenario.get("reason") or "package_e2e_destroy"),
        source=dict(scenario.get("source") or {"name": "Package E2E Removal"}),
        all_players=[active, opponent],
    )
    if destination != "graveyard":
        fail("battle_execution", f"{card['name']} destination={destination!r}")
    if permanent not in active.graveyard:
        fail("battle_execution", f"{card['name']} not moved to controller graveyard")

    treasure_delta = int(active.treasures or 0) - before_treasures
    if treasure_delta != expected_treasure_count:
        fail(
            "battle_execution",
            f"{card['name']} dies treasure delta={treasure_delta}, expected {expected_treasure_count}",
        )
    treasure_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "trigger_resolved"
            and data.get("card") == card.get("name")
            and data.get("trigger") == "dies_or_graveyard_from_battlefield"
            and data.get("effect") == "create_treasure"
        ),
        None,
    )
    if treasure_event is None:
        fail("battle_events", f"missing {card['name']} dies create_treasure trigger")
    if int(treasure_event.get("treasures_created") or 0) != expected_treasure_count:
        fail(
            "battle_events",
            f"{card['name']} event treasures_created={treasure_event.get('treasures_created')}",
        )

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "treasures_created": treasure_delta,
        "controller_treasures_after": active.treasures,
        "validated_keywords": expected_keywords,
    }


def run_tempting_offer_decline(battle, scenario: dict[str, Any], events: list[tuple[str, dict[str, Any]]]) -> dict[str, Any]:
    card = scenario["card"]
    active = battle.Player(
        str(scenario.get("player") or "Lorehold"),
        None,
        list(scenario.get("controller_library") or [{"name": "Controller Draw", "type_line": "Sorcery", "cmc": 1}]),
    )
    opponents = [
        battle.Player(str(name), None, list(scenario.get("opponent_library") or [{"name": "Unused", "type_line": "Sorcery"}]))
        for name in scenario.get("opponents", ["Decliner A", "Decliner B"])
    ]
    battle.apply_effect_immediate(
        active,
        opponents,
        card,
        turn=int(scenario.get("turn") or 8),
        rng=random.Random(int(scenario.get("seed") or 6061)),
    )
    token_name = str(scenario.get("token_name") or "Rabbit Token")
    controller_tokens = [
        permanent
        for permanent in active.battlefield
        if isinstance(permanent, dict) and permanent.get("name") == token_name
    ]
    if len(active.hand) != int(scenario.get("expected_controller_hand_size", 1)):
        fail("battle_execution", f"{card['name']} controller hand size={len(active.hand)}")
    if len(controller_tokens) != int(scenario.get("expected_controller_token_count", 1)):
        fail("battle_execution", f"{card['name']} controller token count={len(controller_tokens)}")
    if any(opponent.hand for opponent in opponents):
        fail("battle_execution", f"{card['name']} default decline drew cards for opponents")
    if any(
        any(permanent.get("name") == token_name for permanent in opponent.battlefield)
        for opponent in opponents
    ):
        fail("battle_execution", f"{card['name']} default decline created opponent tokens")
    offer_event = next(
        (
            data
            for data in event_payloads(events, "tempting_offer_resolved", str(card["name"]))
            if data.get("choice_model") == "opponents_decline"
        ),
        None,
    )
    if offer_event is None:
        fail("battle_events", f"missing {card['name']} tempting_offer_resolved decline event")
    if offer_event.get("opponents_accepted") != 0:
        fail("battle_events", f"{card['name']} opponents_accepted={offer_event.get('opponents_accepted')}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "choice_model": offer_event.get("choice_model"),
        "opponents_declined": offer_event.get("opponents_declined"),
        "controller_hand_size_after": len(active.hand),
        "controller_token_count_after": len(controller_tokens),
    }


def run_remove_permanent_basic_land_compensation(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = scenario["card"]
    active = battle.Player(str(scenario.get("player") or "Lorehold"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    target = dict(scenario["target"])
    basic_land = dict(
        scenario.get("basic_land")
        or {
            "name": "Plains",
            "cmc": 0,
            "type_line": "Basic Land - Plains",
            "effect": "land",
        }
    )
    opponent.battlefield = [target]
    opponent.library = [basic_land]

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 6062)),
    )

    if target in opponent.battlefield:
        fail("battle_execution", f"{card['name']} did not remove target {target.get('name')}")
    moved_basics = [
        permanent
        for permanent in opponent.battlefield
        if isinstance(permanent, dict) and permanent.get("name") == basic_land.get("name")
    ]
    expected_moved = int(scenario.get("expected_basic_lands_moved", 1))
    if len(moved_basics) != expected_moved:
        fail(
            "battle_execution",
            f"{card['name']} moved basic count={len(moved_basics)}, expected {expected_moved}",
        )
    if bool(scenario.get("expected_tapped", True)) and any(
        permanent.get("enters_tapped") is not True for permanent in moved_basics
    ):
        fail("battle_execution", f"{card['name']} moved basic land was not tapped")

    compensation_event = next(
        (
            data
            for event, data in events
            if event == "basic_land_compensation_resolved"
            and data.get("source") == card.get("name")
        ),
        None,
    )
    if compensation_event is None:
        fail("battle_events", f"missing {card['name']} basic_land_compensation_resolved event")
    if compensation_event.get("moved_count") != expected_moved:
        fail(
            "battle_events",
            f"{card['name']} moved_count={compensation_event.get('moved_count')}",
        )
    if compensation_event.get("basic_land_compensation_status") != "runtime_executor_v1":
        fail(
            "battle_events",
            f"{card['name']} compensation status={compensation_event.get('basic_land_compensation_status')!r}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target_removed": target.get("name"),
        "basic_lands_moved": len(moved_basics),
        "basic_land_tapped": all(permanent.get("enters_tapped") is True for permanent in moved_basics),
    }


def run_destroy_target_create_treasure(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = scenario["card"]
    active = battle.Player(str(scenario.get("player") or "Lorehold"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    target = dict(scenario["target"])
    opponent.battlefield = [target]
    before_treasures = int(getattr(active, "treasures", 0) or 0)
    opponent_before_treasures = int(getattr(opponent, "treasures", 0) or 0)
    expected_treasure_count = int(scenario.get("expected_treasure_count") or 1)

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 6063)),
    )

    if target in opponent.battlefield:
        fail("battle_execution", f"{card['name']} did not remove target {target.get('name')}")
    if target not in opponent.graveyard:
        fail("battle_execution", f"{card['name']} did not move target to graveyard")
    treasure_delta = int(active.treasures or 0) - before_treasures
    if treasure_delta != expected_treasure_count:
        fail(
            "battle_execution",
            f"{card['name']} treasure delta={treasure_delta}, expected {expected_treasure_count}",
        )
    if int(opponent.treasures or 0) != opponent_before_treasures:
        fail("battle_execution", f"{card['name']} incorrectly gave Treasure to target controller")
    treasure_event = next(
        (
            data
            for event, data in events
            if event == "treasure_created"
            and data.get("card") == card.get("name")
            and data.get("trigger") == "post_removal"
        ),
        None,
    )
    if treasure_event is None:
        fail("battle_events", f"missing {card['name']} post-removal treasure_created event")
    if int(treasure_event.get("treasures_created") or 0) != expected_treasure_count:
        fail(
            "battle_events",
            f"{card['name']} event treasures_created={treasure_event.get('treasures_created')}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "treasures_created": treasure_delta,
        "controller_treasures_after": active.treasures,
        "target_moved_to_graveyard": target in opponent.graveyard,
    }


def run_creature_etb_create_treasure(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Treasure Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    effect_data = battle.get_card_effect(card)
    expected_condition = scenario.get("expected_condition")
    actual_condition = effect_data.get("etb_treasure_condition")
    if expected_condition and actual_condition != expected_condition:
        fail(
            "battle_execution",
            f"{card['name']} condition={actual_condition!r}, expected {expected_condition!r}",
        )
    controller_land_count = int(scenario.get("controller_land_count") or 0)
    opponent_land_count = int(scenario.get("opponent_land_count") or 0)
    active.battlefield.extend(
        {
            "name": f"Controller Test Land {index + 1}",
            "type_line": "Land",
            "controller": active.name,
        }
        for index in range(controller_land_count)
    )
    opponent.battlefield.extend(
        {
            "name": f"Opponent Test Land {index + 1}",
            "type_line": "Land",
            "controller": opponent.name,
        }
        for index in range(opponent_land_count)
    )
    permanent = battle.prepare_entering_permanent(
        battle.enrich_card({**card, **effect_data}),
        controller=active,
        all_players=[active, opponent],
        turn=int(scenario.get("turn") or 6),
    )
    active.battlefield.append(permanent)
    expected_keywords = [str(value) for value in (scenario.get("expected_keywords") or [])]
    permanent_keywords = [str(value) for value in (permanent.get("keywords") or [])]
    missing_keywords = [keyword for keyword in expected_keywords if keyword not in permanent_keywords]
    if missing_keywords:
        fail(
            "battle_execution",
            f"{card['name']} missing expected ETB permanent keywords: {missing_keywords}",
        )
    before_treasures = int(getattr(active, "treasures", 0) or 0)
    before_events = len(events)
    expected_treasure_count = int(scenario.get("expected_treasure_count") or 1)

    battle.resolve_generic_permanent_etb(
        active,
        [opponent],
        permanent,
        effect_data,
        int(scenario.get("turn") or 6),
        random.Random(int(scenario.get("seed") or 6064)),
        all_players=[active, opponent],
    )

    treasure_delta = int(active.treasures or 0) - before_treasures
    if treasure_delta != expected_treasure_count:
        fail(
            "battle_execution",
            f"{card['name']} ETB treasure delta={treasure_delta}, expected {expected_treasure_count}",
        )
    treasure_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "treasure_created"
            and data.get("card") == card.get("name")
            and data.get("trigger") == "enters_battlefield"
        ),
        None,
    )
    if treasure_event is None:
        fail("battle_events", f"missing {card['name']} ETB treasure_created event")
    if int(treasure_event.get("treasures_created") or 0) != expected_treasure_count:
        fail(
            "battle_events",
            f"{card['name']} event treasures_created={treasure_event.get('treasures_created')}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "treasures_created": treasure_delta,
        "controller_treasures_after": active.treasures,
        "validated_condition": expected_condition,
        "validated_keywords": expected_keywords,
    }


def run_conditional_land_play(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Lorehold"), None, [])
    active.hand = [card]
    active.battlefield = [dict(item) for item in scenario.get("battlefield", [])]
    opponents = [
        battle.Player(str(name), None, [])
        for name in scenario.get("opponents", [])
    ]
    all_players = [active, *opponents]
    turn = int(scenario.get("turn") or 1)
    played = battle.play_land_candidate(
        active,
        opponents,
        all_players,
        turn,
        battle.Stack(),
        {"card": card, "source_zone": "hand"},
    )
    if played is not True:
        fail("battle_execution", f"{card['name']} land play returned {played!r}")
    permanent = next(
        (
            item
            for item in active.battlefield
            if isinstance(item, dict) and item.get("name") == card.get("name")
        ),
        None,
    )
    if permanent is None:
        fail("battle_execution", f"{card['name']} not found on battlefield")
    expected_tapped = bool(scenario.get("expected_tapped"))
    if bool(permanent.get("tapped")) != expected_tapped:
        fail("battle_execution", f"{card['name']} tapped={permanent.get('tapped')!r}")
    land_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "land_played" and data.get("card") == card.get("name")
        ),
        None,
    )
    if land_event is None:
        fail("battle_events", f"missing {card['name']} land_played event")
    if bool(land_event.get("enters_tapped")) != expected_tapped:
        fail("battle_events", f"{card['name']} event enters_tapped={land_event.get('enters_tapped')!r}")
    for key in (
        "conditional_enters_tapped_status",
        "conditional_enters_tapped_profile",
        "conditional_enters_tapped_reason",
    ):
        if key in scenario and land_event.get(key) != scenario[key]:
            fail("battle_events", f"{card['name']} {key}={land_event.get(key)!r}")
    if "conditional_enters_tapped_land_count" in scenario:
        if int(land_event.get("conditional_enters_tapped_land_count") or 0) != int(
            scenario["conditional_enters_tapped_land_count"]
        ):
            fail(
                "battle_events",
                f"{card['name']} land count={land_event.get('conditional_enters_tapped_land_count')!r}",
            )
    if "conditional_enters_tapped_condition_met" in scenario:
        if bool(land_event.get("conditional_enters_tapped_condition_met")) != bool(
            scenario["conditional_enters_tapped_condition_met"]
        ):
            fail(
                "battle_events",
                f"{card['name']} condition_met={land_event.get('conditional_enters_tapped_condition_met')!r}",
            )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "expected_tapped": expected_tapped,
        "actual_tapped": bool(permanent.get("tapped")),
        "land_count": land_event.get("conditional_enters_tapped_land_count"),
        "reason": land_event.get("conditional_enters_tapped_reason"),
    }


def run_mana_source_life_cost_spend(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    source = battle.enrich_card({**card, **effect, **dict(scenario.get("source_overrides") or {})})
    active = battle.Player(str(scenario.get("player") or "Lorehold"), None, [])
    active.life = int(scenario.get("starting_life") or 40)
    active.battlefield = [source]
    turn = int(scenario.get("turn") or 1)
    cost = scenario.get("cost")
    if not cost:
        fail("battle_execution", f"{card['name']} scenario missing cost")

    active.refresh_mana_sources(turn=turn)
    expected_life_after_refresh = int(
        scenario.get("expected_life_after_refresh", active.life)
    )
    if active.life != expected_life_after_refresh:
        fail(
            "battle_execution",
            f"{card['name']} life after refresh={active.life}, expected {expected_life_after_refresh}",
        )
    available_mana_after_refresh = active.available_mana()
    if "expected_available_mana_after_refresh" in scenario:
        expected_available = int(scenario["expected_available_mana_after_refresh"])
        if available_mana_after_refresh != expected_available:
            fail(
                "battle_execution",
                f"{card['name']} available mana={available_mana_after_refresh}, expected {expected_available}",
            )

    can_pay = active.can_pay(cost)
    if bool(can_pay) != bool(scenario.get("expected_can_pay", True)):
        fail("battle_execution", f"{card['name']} can_pay({cost})={can_pay}")
    if active.life != expected_life_after_refresh:
        fail("battle_execution", f"{card['name']} can_pay mutated life to {active.life}")

    spent = active.spend_mana(cost)
    if bool(spent) != bool(scenario.get("expected_spent", True)):
        fail("battle_execution", f"{card['name']} spend_mana({cost})={spent}")
    expected_life_after_spend = int(scenario.get("expected_life_after_spend", active.life))
    if active.life != expected_life_after_spend:
        fail(
            "battle_execution",
            f"{card['name']} life after spend={active.life}, expected {expected_life_after_spend}",
        )
    expected_event = scenario.get("expected_life_cost_event")
    matching_events = [
        data
        for event, data in events
        if event == "conditional_mana_life_cost_paid"
        and data.get("source") == card.get("name")
    ]
    if expected_event is None:
        if matching_events:
            fail("battle_events", f"{card['name']} unexpected life-cost event")
    else:
        if not matching_events:
            fail("battle_events", f"{card['name']} missing conditional_mana_life_cost_paid")
        event = matching_events[-1]
        for key, expected_value in expected_event.items():
            if event.get(key) != expected_value:
                fail(
                    "battle_events",
                    f"{card['name']} {key}={event.get(key)!r}, expected {expected_value!r}",
                )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "cost": cost,
        "available_mana_after_refresh": available_mana_after_refresh,
        "available_mana_after_spend": active.available_mana(),
        "life_after_spend": active.life,
        "life_cost_events": len(matching_events),
    }


def add_manifest_mana(player, mana: dict[str, Any]) -> None:
    for color, amount in (mana or {}).items():
        count = int(amount or 0)
        if count <= 0:
            continue
        normalized = str(color).lower()
        if normalized == "generic":
            player.mana_pool.add_generic(count)
        else:
            player.mana_pool.add(normalized, count)


def support_mana_sources_from_manifest(mana: dict[str, Any]) -> list[dict[str, Any]]:
    sources: list[dict[str, Any]] = []
    color_symbols = {
        "white": "W",
        "blue": "U",
        "black": "B",
        "red": "R",
        "green": "G",
        "generic": "C",
    }
    for color, symbol in color_symbols.items():
        count = int((mana or {}).get(color) or 0)
        for index in range(max(0, count)):
            sources.append(
                {
                    "name": f"E2E {color.title()} Support Source {index + 1}",
                    "type_line": "Artifact",
                    "effect": "ramp_permanent",
                    "battle_model_scope": "e2e_support_mana_source_v1",
                    "is_mana_source": True,
                    "mana_produced": 1,
                    "produces": symbol,
                    "produced_mana_symbols": [symbol],
                    "mana_activation_requires_tap": True,
                }
            )
    return sources


def run_simple_mana_source_refresh(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    source = battle.enrich_card(
        {
            **card,
            "type_line": scenario.get("type_line") or "Artifact",
            **effect,
            **dict(scenario.get("source_overrides") or {}),
        }
    )
    active = battle.Player(str(scenario.get("player") or "Mana Source Controller"), None, [])
    support_sources = [
        battle.enrich_card(dict(support))
        for support in (
            scenario.get("support_mana_sources")
            or support_mana_sources_from_manifest(scenario.get("controller_mana") or {})
        )
        if isinstance(support, dict)
    ]
    active.battlefield = [*support_sources, source]
    turn = int(scenario.get("turn") or 5)
    before_events = len(events)

    active.refresh_mana_sources(turn=turn)

    expected_available = int(scenario.get("expected_available_mana_after_refresh") or 0)
    if active.available_mana() != expected_available:
        fail(
            "battle_execution",
            f"{card['name']} available mana={active.available_mana()}, expected {expected_available}",
        )
    expected_tapped = bool(scenario.get("expected_tapped"))
    if bool(source.get("tapped")) != expected_tapped:
        fail("battle_execution", f"{card['name']} tapped={source.get('tapped')!r}")
    expected_conditional = int(scenario.get("expected_conditional_mana") or 0)
    conditional_total = sum(
        int(item.get("amount") or 0)
        for item in getattr(active, "conditional_mana_sources", []) or []
        if isinstance(item, dict)
    )
    if conditional_total != expected_conditional:
        fail(
            "battle_execution",
            f"{card['name']} conditional mana={conditional_total}, expected {expected_conditional}",
        )
    event = next(
        (
            data
            for replay_event, data in events[before_events:]
            if replay_event == "mana_refreshed" and data.get("player") == active.name
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} mana_refreshed event")
    expected_sources = int(scenario.get("expected_sources") or 0)
    if int(event.get("sources") or 0) != expected_sources:
        fail(
            "battle_events",
            f"{card['name']} mana sources={event.get('sources')}, expected {expected_sources}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "available_mana": active.available_mana(),
        "conditional_mana": conditional_total,
        "tapped": bool(source.get("tapped")),
        "sources": int(event.get("sources") or 0),
    }


def run_simple_activated_create_token(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    permanent_type = str(effect.get("effect") or "permanent")
    default_type_line = {
        "creature": "Creature - Human",
        "artifact": "Artifact",
        "enchantment": "Enchantment",
    }.get(permanent_type, "Permanent")
    source = battle.enrich_card(
        {
            **card,
            "type_line": default_type_line,
            "summoning_sick": False,
            **effect,
            **dict(scenario.get("source_overrides") or {}),
        }
    )
    active = battle.Player(str(scenario.get("player") or "Activated Token Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Activated Token Opponent"), None, [])
    source_zone = str(scenario.get("source_zone") or "battlefield")
    if source_zone == "graveyard":
        active.graveyard = [source]
    else:
        active.battlefield = [source]
    active.hand = [dict(card) for card in scenario.get("controller_hand", [])]
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    starting_hand_names = [card.get("name", "?") for card in active.hand if isinstance(card, dict)]
    expected = dict(scenario.get("expected_token") or {})
    expected_name = str(expected.get("name") or "")
    expected_count = int(expected.get("count") or 1)
    expected_discard_count = int(scenario.get("expected_discard_count") or 0)
    expected_discard_target = str(scenario.get("expected_discard_target") or "any_card")

    if not battle.can_activate_generic_token_maker_permanent(active, source):
        fail("battle_execution", f"{card['name']} simple activated token ability cannot activate")
    activated = battle.activate_generic_token_maker_permanent(
        active,
        [opponent],
        [active, opponent],
        source,
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6073)),
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated token ability activation failed")
    if bool(source.get("tapped")) != bool(scenario.get("expected_tapped_source")):
        fail("battle_execution", f"{card['name']} source tapped={source.get('tapped')}")
    expected_exiled_source = bool(scenario.get("expected_exiled_source_from_graveyard"))
    if expected_exiled_source:
        if source in active.graveyard:
            fail("battle_execution", f"{card['name']} source remained in graveyard after activation")
        if source not in active.exile:
            fail("battle_execution", f"{card['name']} source was not exiled from graveyard")

    actual_tokens = [
        permanent
        for permanent in active.battlefield
        if isinstance(permanent, dict) and battle.is_token_permanent(permanent)
    ]
    matches = [token for token in actual_tokens if token.get("name") == expected_name]
    if len(matches) != expected_count:
        fail("battle_execution", f"{card['name']} {expected_name} count={len(matches)}, expected {expected_count}")
    for token in matches:
        if expected.get("power") is not None and int(token.get("power") or 0) != int(expected["power"]):
            fail("battle_execution", f"{card['name']} {expected_name} power={token.get('power')}")
        if expected.get("toughness") is not None and int(token.get("toughness") or 0) != int(expected["toughness"]):
            fail("battle_execution", f"{card['name']} {expected_name} toughness={token.get('toughness')}")
        expected_subtype = expected.get("subtype")
        if expected_subtype and str(expected_subtype) not in str(token.get("type_line") or ""):
            fail("battle_execution", f"{card['name']} {expected_name} type_line={token.get('type_line')!r}")
        expected_colors = expected.get("colors") or []
        if expected_colors and list(token.get("colors") or []) != list(expected_colors):
            fail("battle_execution", f"{card['name']} {expected_name} colors={token.get('colors')!r}")
        for keyword in expected.get("keywords") or []:
            if not battle.card_has_keyword(token, str(keyword)):
                fail("battle_execution", f"{card['name']} {expected_name} missing keyword {keyword!r}")
        if bool(expected.get("artifact")) and "artifact" not in str(token.get("type_line") or "").lower():
            fail("battle_execution", f"{card['name']} {expected_name} artifact token type missing")
        if bool(token.get("tapped")) != bool(expected.get("tapped")):
            fail("battle_execution", f"{card['name']} {expected_name} tapped={token.get('tapped')}")

    activation_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "activated_ability"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == "simple_activated_create_token"
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} simple activated token event")
    if int(activation_event.get("tokens_created") or 0) != expected_count:
        fail("battle_events", f"{card['name']} event tokens_created={activation_event.get('tokens_created')}")
    if activation_event.get("discarded_count") != expected_discard_count:
        fail(
            "battle_events",
            f"{card['name']} discarded_count={activation_event.get('discarded_count')}, expected {expected_discard_count}",
        )
    if bool(activation_event.get("exiled_source_from_graveyard")) != expected_exiled_source:
        fail(
            "battle_events",
            f"{card['name']} exiled_source_from_graveyard={activation_event.get('exiled_source_from_graveyard')}",
        )
    if expected_discard_count:
        discarded = list(activation_event.get("discarded") or [])
        if len(discarded) != expected_discard_count:
            fail("battle_events", f"{card['name']} discarded={discarded!r}")
        if not set(discarded).issubset(set(starting_hand_names)):
            fail("battle_events", f"{card['name']} discarded cards not from starting hand: {discarded!r}")
        if activation_event.get("discard_target") != expected_discard_target:
            fail(
                "battle_events",
                f"{card['name']} discard_target={activation_event.get('discard_target')!r}, expected {expected_discard_target!r}",
            )
        if expected_discard_target == "land_card":
            discarded_cards = [
                card
                for card in active.graveyard
                if isinstance(card, dict) and card.get("name") in set(discarded)
            ]
            if not discarded_cards or not all(battle.is_land(card) for card in discarded_cards):
                fail("battle_events", f"{card['name']} discarded non-land for land discard cost")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "tokens_created": len(matches),
        "token_name": expected_name,
        "discarded_count": expected_discard_count,
        "discard_target": expected_discard_target if expected_discard_count else None,
        "exiled_source_from_graveyard": expected_exiled_source,
    }


def run_simple_activated_damage(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    permanent_type = str(effect.get("effect") or "permanent")
    default_type_line = {
        "creature": "Creature - Wizard",
        "artifact": "Artifact",
        "enchantment": "Enchantment",
    }.get(permanent_type, "Artifact")
    source = battle.enrich_card(
        {
            **card,
            "type_line": default_type_line,
            "summoning_sick": False,
            **effect,
            **dict(scenario.get("source_overrides") or {}),
        }
    )
    active = battle.Player(str(scenario.get("player") or "Activated Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Activated Opponent"), None, [])
    opponent.life = int(scenario.get("opponent_life") or 7)
    active.battlefield = [source]
    active.hand = [dict(card) for card in scenario.get("controller_hand", [])]
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    starting_life = opponent.life
    starting_hand_names = [card.get("name", "?") for card in active.hand if isinstance(card, dict)]
    expected_damage = int(scenario.get("expected_damage") or effect.get("activated_damage_amount") or 0)
    expected_discard_count = int(scenario.get("expected_discard_count") or 0)
    expected_discard_target = str(scenario.get("expected_discard_target") or "any_card")

    if not battle.can_activate_generic_tap_damage_permanent(active, source, [opponent]):
        fail("battle_execution", f"{card['name']} simple activated damage cannot activate")
    activated = battle.activate_generic_tap_damage_permanent(
        active,
        [opponent],
        source,
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6072)),
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated damage activation failed")
    if opponent.life != starting_life - expected_damage:
        fail(
            "battle_execution",
            f"{card['name']} opponent life={opponent.life}, expected {starting_life - expected_damage}",
        )
    activation_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "activated_ability"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == "simple_activated_damage"
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} simple activated damage event")
    if activation_event.get("discarded_count") != expected_discard_count:
        fail(
            "battle_events",
            f"{card['name']} discarded_count={activation_event.get('discarded_count')}, expected {expected_discard_count}",
        )
    if expected_discard_count:
        discarded = list(activation_event.get("discarded") or [])
        if len(discarded) != expected_discard_count:
            fail("battle_events", f"{card['name']} discarded={discarded!r}")
        if not set(discarded).issubset(set(starting_hand_names)):
            fail("battle_events", f"{card['name']} discarded cards not from starting hand: {discarded!r}")
        if activation_event.get("discard_target") != expected_discard_target:
            fail(
                "battle_events",
                f"{card['name']} discard_target={activation_event.get('discard_target')!r}, expected {expected_discard_target!r}",
            )
        if expected_discard_target == "land_card":
            discarded_cards = [
                card
                for card in active.graveyard
                if isinstance(card, dict) and card.get("name") in set(discarded)
            ]
            if not discarded_cards or not all(battle.is_land(card) for card in discarded_cards):
                fail("battle_events", f"{card['name']} discarded non-land for land discard cost")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "damage": expected_damage,
        "opponent_life": opponent.life,
        "discarded_count": expected_discard_count,
        "discard_target": expected_discard_target if expected_discard_count else None,
    }


def run_simple_activated_tap_target(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    permanent_type = str(effect.get("effect") or "permanent")
    default_type_line = {
        "creature": "Creature - Soldier",
        "artifact": "Artifact",
        "enchantment": "Enchantment",
    }.get(permanent_type, "Artifact")
    source = battle.enrich_card(
        {
            **card,
            "type_line": default_type_line,
            "summoning_sick": False,
            **effect,
            **dict(scenario.get("source_overrides") or {}),
        }
    )
    active = battle.Player(str(scenario.get("player") or "Activated Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Activated Opponent"), None, [])
    target = battle.enrich_card(
        {
            "name": str(scenario.get("target_name") or f"E2E Creature Target for {card['name']}"),
            "type_line": "Creature - Warrior",
            "effect": "creature",
            "power": int(scenario.get("target_power") or 3),
            "toughness": int(scenario.get("target_toughness") or 3),
            "cmc": int(scenario.get("target_cmc") or 3),
            "tapped": False,
        }
    )
    active.battlefield = [source]
    opponent.battlefield = [target]
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    expected_tapped_source = bool(scenario.get("expected_tapped_source", effect.get("activation_requires_tap", False)))

    if not battle.can_activate_generic_tap_target_permanent(active, source, [opponent]):
        fail("battle_execution", f"{card['name']} simple activated tap target cannot activate")
    activated = battle.activate_generic_tap_target_permanent(
        active,
        [opponent],
        source,
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6073)),
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated tap target activation failed")
    if not target.get("tapped"):
        fail("battle_execution", f"{card['name']} target was not tapped")
    if bool(source.get("tapped")) != expected_tapped_source:
        fail(
            "battle_execution",
            f"{card['name']} source tapped={bool(source.get('tapped'))}, expected {expected_tapped_source}",
        )
    activation_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "activated_ability"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == "simple_activated_tap_target"
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} simple activated tap target event")
    resolved_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "tap_target_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == target.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} tap target resolved event")
    if not resolved_event.get("target_tapped"):
        fail("battle_events", f"{card['name']} resolved event target_tapped={resolved_event.get('target_tapped')!r}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "target_tapped": bool(target.get("tapped")),
        "source_tapped": bool(source.get("tapped")),
    }


def run_simple_activated_self_keyword(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    permanent_type = str(effect.get("effect") or "creature")
    default_type_line = {
        "creature": "Creature - Soldier",
        "artifact": "Artifact Creature - Golem",
        "enchantment": "Enchantment Creature",
    }.get(permanent_type, "Creature - Soldier")
    source = battle.enrich_card(
        {
            **card,
            "type_line": default_type_line,
            "effect": permanent_type,
            "power": int(scenario.get("source_power") or 2),
            "toughness": int(scenario.get("source_toughness") or 2),
            "summoning_sick": False,
            **effect,
            **dict(scenario.get("source_overrides") or {}),
        }
    )
    active = battle.Player(str(scenario.get("player") or "Activated Controller"), None, [])
    active.battlefield = [source]
    active.hand = [battle.enrich_card(dict(card)) for card in (scenario.get("controller_hand") or [])]
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    expected_keywords = [
        str(keyword or "").strip().lower().replace(" ", "_")
        for keyword in (scenario.get("expected_keywords") or effect.get("granted_keywords_until_eot") or [])
        if str(keyword or "").strip()
    ]
    expected_tapped_source = bool(scenario.get("expected_tapped_source", effect.get("activation_requires_tap", False)))

    if not battle.can_activate_generic_self_keyword_permanent(active, source):
        fail("battle_execution", f"{card['name']} simple activated self keyword cannot activate")
    activated = battle.activate_generic_self_keyword_permanent(
        active,
        [active],
        source,
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6073)),
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated self keyword activation failed")
    for keyword in expected_keywords:
        if not battle.card_has_keyword(source, keyword):
            fail("battle_execution", f"{card['name']} source missing keyword {keyword!r}")
    if bool(source.get("tapped")) != expected_tapped_source:
        fail(
            "battle_execution",
            f"{card['name']} source tapped={bool(source.get('tapped'))}, expected {expected_tapped_source}",
        )
    expected_discard_count = int(scenario.get("expected_discard_count") or 0)
    expected_life_paid = int(scenario.get("expected_life_paid") or 0)
    activation_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "activated_ability"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == "simple_activated_self_keyword"
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} simple activated self keyword event")
    if int(activation_event.get("activation_discard_count") or 0) != expected_discard_count:
        fail(
            "battle_events",
            f"{card['name']} activation_discard_count={activation_event.get('activation_discard_count')!r}",
        )
    if int(activation_event.get("activation_life_cost") or 0) != expected_life_paid:
        fail(
            "battle_events",
            f"{card['name']} activation_life_cost={activation_event.get('activation_life_cost')!r}",
        )
    resolved_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "stat_modifier_until_eot_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == source.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} self keyword resolved event")
    if list(resolved_event.get("granted_keywords_until_eot") or []) != expected_keywords:
        fail(
            "battle_events",
            f"{card['name']} resolved keywords={resolved_event.get('granted_keywords_until_eot')!r}, expected {expected_keywords!r}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "source_keywords": list(source.get("keywords") or []),
        "granted_keywords": expected_keywords,
        "source_tapped": bool(source.get("tapped")),
        "discarded_count": int(activation_event.get("activation_discard_count") or 0),
        "life_paid": int(activation_event.get("activation_life_cost") or 0),
    }


def assert_expected_event_fields(stage: str, card_name: str, event_data: dict[str, Any], expected: dict[str, Any]) -> None:
    for key, expected_value in expected.items():
        if event_data.get(key) != expected_value:
            fail(stage, f"{card_name} {key}={event_data.get(key)!r}, expected {expected_value!r}")


def validate_expected_locked_cost(stage: str, card_name: str, event_data: dict[str, Any], expected_cost: dict[str, Any] | None) -> None:
    if not expected_cost:
        return
    actual_cost = event_data.get("locked_cost") or {}
    if "generic" in expected_cost and int(actual_cost.get("generic") or 0) != int(expected_cost["generic"]):
        fail(stage, f"{card_name} locked_cost.generic={actual_cost.get('generic')!r}")
    expected_colored = expected_cost.get("colored") or {}
    actual_colored = actual_cost.get("colored") or {}
    for color, amount in expected_colored.items():
        if int(actual_colored.get(color) or 0) != int(amount or 0):
            fail(stage, f"{card_name} locked_cost.colored.{color}={actual_colored.get(color)!r}")


def validate_expected_spree_fields(stage: str, card_name: str, event_data: dict[str, Any], scenario: dict[str, Any]) -> dict[str, Any] | None:
    if "expected_spree_additional_cost_paid" not in scenario:
        return None
    expected_paid = bool(scenario.get("expected_spree_additional_cost_paid"))
    if bool(event_data.get("spree_additional_cost_paid")) != expected_paid:
        fail(
            stage,
            f"{card_name} spree_additional_cost_paid={event_data.get('spree_additional_cost_paid')!r}",
        )
    expected_status = scenario.get("expected_spree_status")
    if expected_status and event_data.get("spree_additional_cost_status") != expected_status:
        fail(stage, f"{card_name} spree_additional_cost_status={event_data.get('spree_additional_cost_status')!r}")
    if "expected_spree_selected_modes" in scenario:
        expected_modes = list(scenario.get("expected_spree_selected_modes") or [])
        if list(event_data.get("spree_selected_modes") or []) != expected_modes:
            fail(stage, f"{card_name} spree_selected_modes={event_data.get('spree_selected_modes')!r}")
    if "expected_spree_additional_costs" in scenario:
        expected_costs = list(scenario.get("expected_spree_additional_costs") or [])
        if list(event_data.get("spree_additional_costs") or []) != expected_costs:
            fail(stage, f"{card_name} spree_additional_costs={event_data.get('spree_additional_costs')!r}")
    return {
        "spree_additional_cost_paid": bool(event_data.get("spree_additional_cost_paid")),
        "spree_additional_cost_status": event_data.get("spree_additional_cost_status"),
        "spree_selected_modes": list(event_data.get("spree_selected_modes") or []),
        "spree_additional_costs": list(event_data.get("spree_additional_costs") or []),
    }


def run_copy_spell_choose_new_targets(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    copy_card = dict(scenario["card"])
    turn = int(scenario.get("turn") or 7)
    phase = str(scenario.get("phase") or "precombat_main")
    active = battle.Player(str(scenario.get("active_player") or "Active"), None, [])
    responder = battle.Player(str(scenario.get("responder") or "Responder"), None, [])
    original_target = dict(scenario.get("original_target") or {
        "name": "Original Target",
        "cmc": 1,
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "type_line": "Creature",
    })
    alternate_target = dict(scenario.get("alternate_target") or {
        "name": "Better Target",
        "cmc": 4,
        "effect": "draw_engine",
        "power": 3,
        "toughness": 4,
        "type_line": "Creature",
    })
    active.battlefield = [original_target, alternate_target]
    target_spell = dict(scenario.get("target_spell") or {
        "name": "Targeted Removal",
        "cmc": 1,
        "mana_cost": "{W}",
        "type_line": "Instant",
    })
    target_effect = dict(scenario.get("target_effect") or {
        "effect": "remove_creature",
        "target": "creature",
        "exile_target": True,
    })
    if not bool(scenario.get("omit_declared_targets")):
        target_effect["declared_targets"] = [
            {
                "target": original_target,
                "controller": active,
                "target_type": str(scenario.get("target_type") or target_effect.get("target") or "creature"),
                "declared_by": active,
            }
        ]
    battle.store_cast_context_fields(target_effect, {"phase": phase, "role": "target_spell_fixture"})
    stack = battle.Stack()
    stack.push(target_spell, active, target_effect)

    all_players = [active, responder]
    copy_path = str(scenario.get("copy_path") or "response")
    if copy_path == "response":
        responder.hand = [copy_card]
        add_manifest_mana(responder, scenario.get("responder_mana") or {"red": 2})
        if not battle.priority_round(
            active,
            all_players,
            stack,
            turn,
            random.Random(int(scenario.get("seed") or 6064)),
            phase=phase,
        ):
            fail("battle_execution", f"{copy_card['name']} was not cast as response")
    elif copy_path == "etb":
        copy_effect = battle.get_card_effect(copy_card)
        battle.apply_effect_immediate(
            responder,
            [active],
            copy_card,
            turn,
            random.Random(int(scenario.get("seed") or 6064)),
            effect_data_override=copy_effect,
            stack=stack,
            phase=phase,
        )
    else:
        fail("battle_execution", f"unsupported copy_path {copy_path!r}")

    copied_item = stack.items[-1] if getattr(stack, "items", None) else None
    if copied_item is None or not getattr(copied_item, "card", {}).get("is_copy"):
        fail("battle_execution", f"{copy_card['name']} did not create stack copy")
    selection = getattr(copied_item, "effect_data", {}).get("_copy_target_selection") or {}
    expected_status = str(scenario.get("expected_copy_target_selection_status") or "runtime_executor_v1")
    if selection.get("copy_target_selection_status") != expected_status:
        fail(
            "battle_execution",
            f"{copy_card['name']} selection status={selection.get('copy_target_selection_status')!r}",
        )
    if selection.get("copy_target_selection_pipeline") != "copy_spell_runtime_choose_new_targets_v1":
        fail("battle_execution", f"{copy_card['name']} missing copy target selection pipeline")
    expected_reassigned = bool(scenario.get("expected_target_reassignment_performed", True))
    if bool(selection.get("target_reassignment_performed")) != expected_reassigned:
        fail(
            "battle_execution",
            f"{copy_card['name']} reassigned={selection.get('target_reassignment_performed')!r}",
        )
    copied_targets = getattr(copied_item, "effect_data", {}).get("declared_targets") or []
    expected_target_name = scenario.get("expected_copy_target")
    if not copied_targets and expected_target_name:
        fail("battle_execution", f"{copy_card['name']} copied effect missing declared targets")
    if expected_target_name is None and not bool(scenario.get("omit_declared_targets")):
        expected_target_name = alternate_target.get("name")
    expected_target_name = str(expected_target_name) if expected_target_name is not None else None
    actual_target = copied_targets[0].get("target") if copied_targets and isinstance(copied_targets[0], dict) else None
    actual_target_name = actual_target.get("name") if isinstance(actual_target, dict) else None
    if expected_target_name is not None and actual_target_name != expected_target_name:
        fail("battle_execution", f"{copy_card['name']} target={actual_target_name!r}")

    spell_copied = next(
        (
            data
            for event, data in reversed(events)
            if event == "spell_copied" and data.get("card") == copy_card.get("name")
        ),
        None,
    )
    if spell_copied is None:
        fail("battle_events", f"missing {copy_card['name']} spell_copied event")
    if spell_copied.get("copy_target_selection_status") != expected_status:
        fail(
            "battle_events",
            f"{copy_card['name']} event target status={spell_copied.get('copy_target_selection_status')!r}",
        )
    if expected_target_name is not None and spell_copied.get("copy_spell_target") != expected_target_name:
        fail(
            "battle_events",
            f"{copy_card['name']} event copy_spell_target={spell_copied.get('copy_spell_target')!r}",
        )
    expected_copy_event_fields = scenario.get("expected_copy_event_fields") or {}
    assert_expected_event_fields("battle_events", copy_card["name"], spell_copied, expected_copy_event_fields)
    spell_cast = next(
        (
            data
            for event, data in reversed(events)
            if event == "spell_cast" and data.get("card") == copy_card.get("name")
        ),
        None,
    )
    locked_cost_result = None
    spree_result = None
    if scenario.get("expected_locked_cost") or "expected_spree_additional_cost_paid" in scenario:
        if spell_cast is None:
            fail("battle_events", f"missing {copy_card['name']} spell_cast event")
        validate_expected_locked_cost("battle_events", copy_card["name"], spell_cast, scenario.get("expected_locked_cost"))
        locked_cost_result = spell_cast.get("locked_cost")
        spree_result = validate_expected_spree_fields("battle_events", copy_card["name"], spell_cast, scenario)
    buyback_result = None
    if "expected_buyback_paid" in scenario:
        expected_buyback_paid = bool(scenario.get("expected_buyback_paid"))
        if spell_cast is None:
            fail("battle_events", f"missing {copy_card['name']} spell_cast event")
        if bool(spell_cast.get("buyback_paid")) != expected_buyback_paid:
            fail(
                "battle_events",
                f"{copy_card['name']} buyback_paid={spell_cast.get('buyback_paid')!r}",
            )
        expected_buyback_status = scenario.get("expected_buyback_status")
        if expected_buyback_status and spell_cast.get("buyback_status") != expected_buyback_status:
            fail(
                "battle_events",
                f"{copy_card['name']} buyback_status={spell_cast.get('buyback_status')!r}",
            )
        expected_buyback_cost = scenario.get("expected_buyback_cost")
        if expected_buyback_cost and spell_cast.get("buyback_cost") != expected_buyback_cost:
            fail(
                "battle_events",
                f"{copy_card['name']} buyback_cost={spell_cast.get('buyback_cost')!r}",
            )
        spell_resolved = next(
            (
                data
                for event, data in reversed(events)
                if event == "spell_resolved" and data.get("card") == copy_card.get("name")
            ),
            None,
        )
        if spell_resolved is None:
            fail("battle_events", f"missing {copy_card['name']} spell_resolved event")
        expected_destination = scenario.get("expected_resolution_destination")
        if expected_destination and spell_resolved.get("destination") != expected_destination:
            fail(
                "battle_events",
                f"{copy_card['name']} destination={spell_resolved.get('destination')!r}",
            )
        returned_to_hand = any(
            event == "buyback_returned_to_hand"
            and data.get("card") == copy_card.get("name")
            for event, data in events
        )
        if returned_to_hand != expected_buyback_paid:
            fail(
                "battle_events",
                f"{copy_card['name']} buyback_returned_to_hand={returned_to_hand!r}",
            )
        if expected_buyback_paid and not any(card.get("name") == copy_card.get("name") for card in responder.hand):
            fail("battle_execution", f"{copy_card['name']} did not return to hand after buyback")
        if not expected_buyback_paid and not any(card.get("name") == copy_card.get("name") for card in responder.graveyard):
            fail("battle_execution", f"{copy_card['name']} did not move to graveyard without buyback")
        buyback_result = {
            "buyback_paid": expected_buyback_paid,
            "buyback_status": spell_cast.get("buyback_status"),
            "buyback_cost": spell_cast.get("buyback_cost"),
            "destination": spell_resolved.get("destination"),
        }
    return {
        "scenario": scenario.get("name"),
        "card_name": copy_card["name"],
        "copy_path": copy_path,
        "copied_spell": target_spell.get("name"),
        "copy_target_selection_status": selection.get("copy_target_selection_status"),
        "target_reassignment_performed": bool(selection.get("target_reassignment_performed")),
        "copy_spell_target": actual_target_name,
        **({"locked_cost": locked_cost_result} if locked_cost_result is not None else {}),
        **({"spree": spree_result} if spree_result is not None else {}),
        **({"buyback": buyback_result} if buyback_result is not None else {}),
    }


def run_copy_stack_ability_response(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    response_card = dict(scenario["card"])
    turn = int(scenario.get("turn") or 7)
    phase = str(scenario.get("phase") or "precombat_main")
    active = battle.Player(str(scenario.get("active_player") or "Active"), None, [])
    responder = battle.Player(str(scenario.get("responder") or "Responder"), None, [])
    responder.hand = [response_card]
    add_manifest_mana(responder, scenario.get("responder_mana") or {"generic": 1, "red": 2})
    resolved: list[str] = []
    ability_card = dict(
        scenario.get("ability_card")
        or {
            "name": "Triggered Ability Fixture",
            "type_line": "Triggered Ability",
            "is_triggered_ability": True,
        }
    )
    ability_effect = dict(
        scenario.get("ability_effect")
        or {
            "effect": "triggered_ability",
        }
    )
    ability_effect["resolver"] = lambda: resolved.append("resolved")
    stack = battle.Stack()
    stack.push(ability_card, active, ability_effect)

    if not battle.priority_round(
        active,
        [active, responder],
        stack,
        turn,
        random.Random(int(scenario.get("seed") or 6070)),
        phase=phase,
    ):
        fail("battle_execution", f"{response_card['name']} was not cast as ability-copy response")
    copied_item = stack.items[-1] if getattr(stack, "items", None) else None
    if copied_item is None or not getattr(copied_item, "card", {}).get("is_copy"):
        fail("battle_execution", f"{response_card['name']} did not create ability copy")
    if getattr(copied_item, "effect_data", {}).get("effect") != "triggered_ability":
        fail("battle_execution", f"{response_card['name']} copied effect={getattr(copied_item, 'effect_data', {}).get('effect')!r}")

    spell_cast = next(
        (
            data
            for event, data in reversed(events)
            if event == "spell_cast" and data.get("card") == response_card.get("name")
        ),
        None,
    )
    if spell_cast is None:
        fail("battle_events", f"missing {response_card['name']} spell_cast event")
    validate_expected_locked_cost("battle_events", response_card["name"], spell_cast, scenario.get("expected_locked_cost"))
    spree_result = validate_expected_spree_fields("battle_events", response_card["name"], spell_cast, scenario)

    spell_copied = next(
        (
            data
            for event, data in reversed(events)
            if event == "spell_copied" and data.get("card") == response_card.get("name")
        ),
        None,
    )
    if spell_copied is None:
        fail("battle_events", f"missing {response_card['name']} spell_copied event")
    expected_target_type = scenario.get("expected_target_type", "activated_or_triggered_ability_on_stack")
    if spell_copied.get("target_type") != expected_target_type:
        fail("battle_events", f"{response_card['name']} target_type={spell_copied.get('target_type')!r}")
    expected_copy_status = scenario.get("expected_copy_ability_status", "runtime_executor_v1")
    if spell_copied.get("copy_activated_triggered_ability_status") != expected_copy_status:
        fail(
            "battle_events",
            f"{response_card['name']} copy_activated_triggered_ability_status={spell_copied.get('copy_activated_triggered_ability_status')!r}",
        )

    if not battle.priority_round(
        active,
        [active, responder],
        stack,
        turn + 1,
        random.Random(int(scenario.get("resolve_seed") or 6071)),
        phase=phase,
    ):
        fail("battle_execution", f"{response_card['name']} copied ability did not resolve")
    expected_resolutions = int(scenario.get("expected_copy_resolutions") or 1)
    if len(resolved) != expected_resolutions:
        fail("battle_execution", f"{response_card['name']} copied ability resolutions={len(resolved)}")
    return {
        "scenario": scenario.get("name"),
        "card_name": response_card["name"],
        "copied_stack_object": ability_card.get("name"),
        "target_type": spell_copied.get("target_type"),
        "copy_activated_triggered_ability_status": spell_copied.get("copy_activated_triggered_ability_status"),
        "locked_cost": spell_cast.get("locked_cost"),
        "spree": spree_result,
        "copy_resolutions": len(resolved),
    }


def run_change_single_target_response(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    response_card = dict(scenario["card"])
    turn = int(scenario.get("turn") or 7)
    phase = str(scenario.get("phase") or "combat")
    caster = battle.Player(str(scenario.get("caster") or "Caster"), None, [])
    responder = battle.Player(str(scenario.get("responder") or "Responder"), None, [])
    protected = dict(scenario.get("protected_target") or {
        "name": "Protected Creature",
        "cmc": 2,
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "type_line": "Creature",
    })
    redirect_target = dict(scenario.get("redirect_target") or {
        "name": "Opponent Threat",
        "cmc": 5,
        "effect": "creature",
        "power": 5,
        "toughness": 5,
        "type_line": "Creature",
    })
    responder.battlefield = [protected]
    caster.battlefield = [redirect_target]
    target_spell = dict(scenario.get("target_spell") or {
        "name": "Targeted Removal",
        "cmc": 2,
        "mana_cost": "{1}{B}",
        "type_line": "Instant",
    })
    target_effect = dict(scenario.get("target_effect") or {
        "effect": "remove_creature",
        "target": "creature",
        "instant": True,
    })
    target_effect["declared_targets"] = [
        {
            "target": protected,
            "controller": responder,
            "target_type": str(scenario.get("target_type") or target_effect.get("target") or "creature"),
            "declared_by": caster,
        }
    ]
    stack = battle.Stack()
    stack.push(target_spell, caster, target_effect)
    responder.hand = [response_card]
    add_manifest_mana(responder, scenario.get("responder_mana") or {"generic": 1, "red": 1})
    if not battle.priority_round(
        caster,
        [caster, responder],
        stack,
        turn,
        random.Random(int(scenario.get("seed") or 6065)),
        phase=phase,
    ):
        fail("battle_execution", f"{response_card['name']} was not cast as target-change response")

    changed_entry = stack.items[-1].effect_data["declared_targets"][0]
    actual_target = changed_entry.get("target")
    actual_target_name = actual_target.get("name") if isinstance(actual_target, dict) else None
    expected_target_name = str(scenario.get("expected_new_target") or redirect_target.get("name"))
    if actual_target_name != expected_target_name:
        fail("battle_execution", f"{response_card['name']} new target={actual_target_name!r}")

    redirect_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "redirect_removal_resolved" and data.get("card") == response_card.get("name")
        ),
        None,
    )
    if redirect_event is None:
        fail("battle_events", f"missing {response_card['name']} redirect_removal_resolved event")
    if redirect_event.get("target_change_applied") is not True:
        fail("battle_events", f"{response_card['name']} target_change_applied={redirect_event.get('target_change_applied')!r}")
    if redirect_event.get("old_target") != protected.get("name"):
        fail("battle_events", f"{response_card['name']} old_target={redirect_event.get('old_target')!r}")
    if redirect_event.get("new_target") != expected_target_name:
        fail("battle_events", f"{response_card['name']} new_target={redirect_event.get('new_target')!r}")
    expected_status_key = scenario.get("expected_status_key")
    expected_status_value = scenario.get("expected_status_value", "runtime_executor_v1")
    if expected_status_key and redirect_event.get(expected_status_key) != expected_status_value:
        fail(
            "battle_events",
            f"{response_card['name']} {expected_status_key}={redirect_event.get(expected_status_key)!r}",
        )
    if redirect_event.get("target_change_pipeline") != "single_target_stack_object_redirect_runtime_v1":
        fail("battle_events", f"{response_card['name']} missing target_change_pipeline")
    spell_cast = next(
        (
            data
            for event, data in reversed(events)
            if event == "spell_cast" and data.get("card") == response_card.get("name")
        ),
        None,
    )
    locked_cost_result = None
    spree_result = None
    if scenario.get("expected_locked_cost") or "expected_spree_additional_cost_paid" in scenario:
        if spell_cast is None:
            fail("battle_events", f"missing {response_card['name']} spell_cast event")
        validate_expected_locked_cost("battle_events", response_card["name"], spell_cast, scenario.get("expected_locked_cost"))
        locked_cost_result = spell_cast.get("locked_cost")
        spree_result = validate_expected_spree_fields("battle_events", response_card["name"], spell_cast, scenario)
        if "expected_spree_additional_cost_paid" in scenario:
            validate_expected_spree_fields("battle_events", response_card["name"], redirect_event, scenario)
    return {
        "scenario": scenario.get("name"),
        "card_name": response_card["name"],
        "old_target": protected.get("name"),
        "new_target": actual_target_name,
        "target_change_applied": True,
        "target_change_pipeline": redirect_event.get("target_change_pipeline"),
        **({"locked_cost": locked_cost_result} if locked_cost_result is not None else {}),
        **({"spree": spree_result} if spree_result is not None else {}),
    }


def _default_cant_block_attacker() -> dict[str, Any]:
    return {
        "name": "Lorehold Attacker",
        "effect": "creature",
        "type_line": "Creature",
        "power": 4,
        "toughness": 4,
    }


def _block_assignment_names(assignments: list[tuple[dict[str, Any], list[dict[str, Any]]]]) -> list[str]:
    names: list[str] = []
    for _attacker, blockers in assignments:
        names.extend(blocker.get("name", "?") for blocker in blockers)
    return names


def run_target_creature_cant_block(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    turn = int(scenario.get("turn") or 8)
    active = battle.Player(str(scenario.get("player") or "Lorehold"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    attacker = dict(scenario.get("attacker") or _default_cant_block_attacker())
    active.battlefield = [attacker]
    blockers = [
        dict(blocker)
        for blocker in scenario.get(
            "blockers",
            [
                {
                    "name": "Large Ground Blocker",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 6,
                    "toughness": 6,
                },
                {
                    "name": "Small Ground Blocker",
                    "effect": "creature",
                    "type_line": "Creature",
                    "power": 1,
                    "toughness": 1,
                },
            ],
        )
    ]
    opponent.battlefield = blockers
    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=turn,
        rng=random.Random(int(scenario.get("seed") or 6066)),
    )
    expected_affected = set(scenario.get("expected_affected") or ["Large Ground Blocker"])
    affected = {
        permanent.get("name")
        for permanent in opponent.battlefield
        if permanent.get("cant_block")
    }
    if affected != expected_affected:
        fail("battle_execution", f"{card['name']} cant_block affected={sorted(affected)}")
    if any(permanent.get("name") in expected_affected for permanent in opponent.graveyard):
        fail("battle_execution", f"{card['name']} destroyed cant-block target instead of applying restriction")
    opponent.life = int(scenario.get("defender_life") or attacker.get("power") or 4)
    attacker["attacking"] = True
    assignments = battle.declare_blockers_step(
        opponent,
        [attacker],
        turn,
        random.Random(int(scenario.get("block_seed") or 6067)),
    )
    blocker_names = _block_assignment_names(assignments)
    expected_blockers = list(scenario.get("expected_blockers") or ["Small Ground Blocker"])
    if blocker_names != expected_blockers:
        fail("battle_execution", f"{card['name']} blockers={blocker_names}, expected {expected_blockers}")
    event = next(
        (
            data
            for replay_event, data in events
            if replay_event == "cant_block_until_eot_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} cant_block_until_eot_resolved event")
    if event.get("cant_block_mode_status") != "runtime_executor_v1":
        fail("battle_events", f"{card['name']} cant_block status={event.get('cant_block_mode_status')!r}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card.get("name"),
        "affected": sorted(affected),
        "blockers": blocker_names,
        "cant_block_mode_status": event.get("cant_block_mode_status"),
    }


def run_nonfliers_cant_block_rider(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    turn = int(scenario.get("turn") or 8)
    active = battle.Player(str(scenario.get("player") or "Lorehold"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    attacker = dict(scenario.get("attacker") or _default_cant_block_attacker())
    active.battlefield = [attacker]
    target_land = dict(scenario.get("target_land") or {"name": "Target Land", "type_line": "Land", "effect": "land"})
    ground_blocker = dict(
        scenario.get("ground_blocker")
        or {
            "name": "Ground Blocker",
            "effect": "creature",
            "type_line": "Creature",
            "power": 5,
            "toughness": 5,
        }
    )
    flying_blocker = dict(
        scenario.get("flying_blocker")
        or {
            "name": "Flying Blocker",
            "effect": "creature",
            "type_line": "Creature",
            "flying": True,
            "power": 4,
            "toughness": 4,
        }
    )
    opponent.battlefield = [target_land, ground_blocker, flying_blocker]
    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=turn,
        rng=random.Random(int(scenario.get("seed") or 6068)),
    )
    if any(permanent.get("name") == target_land.get("name") for permanent in opponent.battlefield):
        fail("battle_execution", f"{card['name']} did not remove target land")
    if ground_blocker.get("cant_block") is not True:
        fail("battle_execution", f"{card['name']} did not mark ground blocker cant_block")
    if flying_blocker.get("cant_block") is True:
        fail("battle_execution", f"{card['name']} marked flying blocker cant_block")
    opponent.life = int(scenario.get("defender_life") or attacker.get("power") or 4)
    attacker["attacking"] = True
    assignments = battle.declare_blockers_step(
        opponent,
        [attacker],
        turn,
        random.Random(int(scenario.get("block_seed") or 6069)),
    )
    blocker_names = _block_assignment_names(assignments)
    expected_blockers = list(scenario.get("expected_blockers") or [flying_blocker.get("name")])
    if blocker_names != expected_blockers:
        fail("battle_execution", f"{card['name']} blockers={blocker_names}, expected {expected_blockers}")
    event = next(
        (
            data
            for replay_event, data in events
            if replay_event == "cant_block_until_eot_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} cant_block_until_eot_resolved event")
    if event.get("cant_block_mode_status") != "runtime_executor_v1":
        fail("battle_events", f"{card['name']} cant_block status={event.get('cant_block_mode_status')!r}")
    if event.get("cant_block_target_restriction") != "creatures_without_flying":
        fail("battle_events", f"{card['name']} restriction={event.get('cant_block_target_restriction')!r}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card.get("name"),
        "target_removed": target_land.get("name"),
        "blockers": blocker_names,
        "cant_block_mode_status": event.get("cant_block_mode_status"),
        "cant_block_target_restriction": event.get("cant_block_target_restriction"),
    }


def run_static_global_power_toughness_boost(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    source = battle.enrich_card({**card, **battle.get_card_effect(card)})
    active = battle.Player(str(scenario.get("player") or "Static Source Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Static Target Opponent"), None, [])
    target = dict(scenario["target"])
    target_owner = str(scenario.get("target_owner") or "controller")
    target_controller = opponent if target_owner == "opponent" else active
    active.battlefield = [source]
    target_controller.battlefield.append(target)
    participants = [active, opponent]
    refreshed = battle.refresh_all_global_static_power_toughness_bonuses(
        participants,
        turn=int(scenario.get("turn") or 3),
        phase=str(scenario.get("phase") or "main"),
        emit_events=True,
    )
    expected_moved = bool(scenario.get("expected_moved_to_graveyard"))
    moved = target not in target_controller.battlefield and target in getattr(target_controller, "graveyard", [])
    if moved != expected_moved:
        fail("battle_execution", f"{card['name']} moved_to_graveyard={moved}, expected {expected_moved}")
    expected_power = int(scenario["expected_power"])
    expected_toughness = int(scenario["expected_toughness"])
    if int(target.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} target power={target.get('power')}, expected {expected_power}")
    if int(target.get("toughness") or 0) != expected_toughness:
        fail("battle_execution", f"{card['name']} target toughness={target.get('toughness')}, expected {expected_toughness}")
    source_name = str(scenario.get("expected_source") or card.get("name"))
    changed_event = next(
        (
            data
            for event, data in events
            if event == "static_global_power_toughness_boost_changed"
            and data.get("card") == target.get("name")
            and source_name in (data.get("source_cards") or [])
        ),
        None,
    )
    if changed_event is None:
        fail("battle_events", f"missing {card['name']} static_global_power_toughness_boost_changed event")
    if expected_moved:
        zero_event = next(
            (
                data
                for event, data in events
                if event == "state_based_action_zero_toughness"
                and data.get("card") == target.get("name")
            ),
            None,
        )
        if zero_event is None:
            fail("battle_events", f"missing {card['name']} state_based_action_zero_toughness event")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "target_power": target.get("power"),
        "target_toughness": target.get("toughness"),
        "moved_to_graveyard": moved,
        "refreshed_count": len(refreshed),
        "source_cards": changed_event.get("source_cards"),
    }


def run_aura_static_power_toughness_attachment(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    source = battle.enrich_card({**card, **battle.get_card_effect(card)})
    active = battle.Player(str(scenario.get("player") or "Aura Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Aura Target Opponent"), None, [])
    target = dict(scenario["target"])
    target_owner = str(scenario.get("target_owner") or "controller")
    target_controller = opponent if target_owner == "opponent" else active
    target_controller.battlefield.append(target)
    before_events = len(events)
    battle.apply_aura_static_attachment(
        active,
        [opponent],
        source,
        battle.get_card_effect(card),
        turn=int(scenario.get("turn") or 3),
        rng=random.Random(int(scenario.get("seed") or 17)),
    )
    expected_moved = bool(scenario.get("expected_moved_to_graveyard"))
    moved = target not in target_controller.battlefield and target in getattr(target_controller, "graveyard", [])
    if moved != expected_moved:
        fail("battle_execution", f"{card['name']} moved_to_graveyard={moved}, expected {expected_moved}")
    expected_power = int(scenario["expected_power"])
    expected_toughness = int(scenario["expected_toughness"])
    if int(target.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} target power={target.get('power')}, expected {expected_power}")
    if int(target.get("toughness") or 0) != expected_toughness:
        fail("battle_execution", f"{card['name']} target toughness={target.get('toughness')}, expected {expected_toughness}")
    attached_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "aura_attached_static_pt"
            and data.get("card") == card.get("name")
            and data.get("target") == target.get("name")
        ),
        None,
    )
    if attached_event is None:
        fail("battle_events", f"missing {card['name']} aura_attached_static_pt event")
    source_name = str(scenario.get("expected_source") or card.get("name"))
    if attached_event.get("card") != source_name:
        fail("battle_events", f"{card['name']} attached event source={attached_event.get('card')!r}")
    if expected_moved:
        target_move_event = next(
            (
                data
                for event, data in events[before_events:]
                if event == "permanent_moved_from_battlefield"
                and data.get("card") == target.get("name")
                and data.get("reason") == "zero_toughness"
                and data.get("destination") == "graveyard"
            ),
            None,
        )
        if target_move_event is None:
            fail("battle_events", f"missing {card['name']} zero-toughness graveyard move event")
        aura_move_event = next(
            (
                data
                for event, data in events[before_events:]
                if event == "permanent_moved_from_battlefield"
                and data.get("card") == source_name
                and data.get("reason") == "attached_target_left_battlefield"
                and data.get("destination") == "graveyard"
            ),
            None,
        )
        if aura_move_event is None:
            fail("battle_events", f"missing {card['name']} attached Aura graveyard move event")
        aura_in_graveyard = any(
            item.get("name") == source_name
            for item in getattr(active, "graveyard", []) or []
            if isinstance(item, dict)
        )
        if not aura_in_graveyard:
            fail("battle_execution", f"{card['name']} aura was not moved after target left battlefield")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "target_owner": target_owner,
        "target_power": target.get("power"),
        "target_toughness": target.get("toughness"),
        "moved_to_graveyard": moved,
        "attached_event": {
            "power_boost": attached_event.get("power_boost"),
            "toughness_boost": attached_event.get("toughness_boost"),
            "target_player": attached_event.get("target_player"),
        },
    }


SCENARIO_RUNNERS = {
    "aura_static_power_toughness_attachment": run_aura_static_power_toughness_attachment,
    "conditional_land_play": run_conditional_land_play,
    "copy_stack_ability_response": run_copy_stack_ability_response,
    "copy_spell_choose_new_targets": run_copy_spell_choose_new_targets,
    "change_single_target_response": run_change_single_target_response,
    "creature_dies_create_treasure": run_creature_dies_create_treasure,
    "creature_dies_create_tokens": run_creature_dies_create_tokens,
    "creature_etb_create_treasure": run_creature_etb_create_treasure,
    "creature_etb_create_tokens": run_creature_etb_create_tokens,
    "creature_etb_dynamic_life_gain": run_creature_etb_dynamic_life_gain,
    "creature_enters_life_gain": run_creature_enters_life_gain,
    "creature_etb_scry": run_creature_etb_scry,
    "destroy_target_create_treasure": run_destroy_target_create_treasure,
    "dynamic_life_gain": run_dynamic_life_gain,
    "fixed_create_creature_tokens": run_fixed_create_creature_tokens,
    "mana_source_life_cost_spend": run_mana_source_life_cost_spend,
    "multi_create_creature_tokens": run_multi_create_creature_tokens,
    "nonfliers_cant_block_rider": run_nonfliers_cant_block_rider,
    "remove_permanent_basic_land_compensation": run_remove_permanent_basic_land_compensation,
    "simple_mana_source_refresh": run_simple_mana_source_refresh,
    "simple_activated_damage": run_simple_activated_damage,
    "simple_activated_tap_target": run_simple_activated_tap_target,
    "simple_activated_self_keyword": run_simple_activated_self_keyword,
    "simple_activated_create_token": run_simple_activated_create_token,
    "spell_cast_gain_life": run_spell_cast_gain_life,
    "static_global_power_toughness_boost": run_static_global_power_toughness_boost,
    "target_creature_cant_block": run_target_creature_cant_block,
    "token_maker_attack_each_opponent": run_token_maker_attack_each_opponent,
    "tempting_offer_decline": run_tempting_offer_decline,
}


def validate_battle_execution(battle, manifest: dict[str, Any]) -> dict[str, Any]:
    scenarios = manifest.get("execution_scenarios") or []
    results: list[dict[str, Any]] = []
    events: list[tuple[str, dict[str, Any]]] = []
    previous_handler = getattr(battle, "REPLAY_EVENT_HANDLER", None)
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        for scenario in scenarios:
            scenario_type = str(scenario.get("type") or "").strip()
            runner = SCENARIO_RUNNERS.get(scenario_type)
            if runner is None:
                fail("battle_execution", f"unsupported scenario type {scenario_type!r}")
            results.append(runner(battle, scenario, events))
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
    return {
        "event_count": len(events),
        "scenario_count": len(scenarios),
        "results": results,
    }


def write_markdown(path: Path, report: dict[str, Any]) -> None:
    lines = [
        f"# {report['title']}",
        "",
        f"- Generated UTC: `{report['generated_at_utc']}`",
        f"- Package ID: `{report['package_id']}`",
        f"- Status: `{report['status']}`",
        f"- Database target: `{report['database_target']}`",
        f"- SQLite DB: `{report['sqlite_db']}`",
        f"- Snapshot: `{report['snapshot']}`",
        "",
        "## Stage Results",
        "",
        "| Stage | Status | Evidence |",
        "| --- | --- | --- |",
    ]
    for stage in report["stages"]:
        lines.append(
            "| {name} | `{status}` | `{evidence}` |".format(
                name=stage["name"],
                status=stage["status"],
                evidence=json.dumps(stage.get("evidence") or {}, sort_keys=True),
            )
        )
    lines.extend(
        [
            "",
            "## Battle Execution",
            "",
            "```json",
            json.dumps(report["battle_execution"], indent=2, sort_keys=True),
            "```",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    args = parse_args()
    manifest_path = Path(args.manifest)
    manifest = load_json(manifest_path)
    expected_by_key = expected_rules_by_key(manifest)
    sqlite_db = Path(args.sqlite_db)
    snapshot = Path(args.snapshot)
    battle_path = Path(args.battle_path)
    os.environ["MANALOOM_KNOWLEDGE_DB"] = str(sqlite_db.resolve())
    os.environ["MANALOOM_CANONICAL_KNOWN_CARDS_JSON"] = str(snapshot.resolve())
    battle = load_battle(battle_path)

    pg_results = validate_postgres(expected_by_key)
    sqlite_results = validate_sqlite(sqlite_db, expected_by_key)
    snapshot_results = validate_snapshot(snapshot, manifest, expected_by_key)
    runtime_results = validate_runtime_lookup(battle, manifest)
    battle_execution = validate_battle_execution(battle, manifest)

    report = {
        "title": str(manifest.get("title") or "Battle Package End-to-End Validation"),
        "package_id": str(manifest.get("package_id") or manifest_path.stem),
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "database_target": db_helper.sanitized_database_target(),
        "manifest": str(manifest_path),
        "sqlite_db": str(sqlite_db),
        "snapshot": str(snapshot),
        "battle_path": str(battle_path),
        "stages": [
            {
                "name": "postgres_source_of_truth",
                "status": "pass",
                "evidence": {"validated_rows": len(pg_results)},
                "rows": pg_results,
            },
            {
                "name": "sqlite_hermes_cache",
                "status": "pass",
                "evidence": {"validated_rows": len(sqlite_results)},
                "rows": sqlite_results,
            },
            {
                "name": "canonical_snapshot_fallback",
                "status": "pass",
                "evidence": {"validated_cards": len(snapshot_results)},
                "rows": snapshot_results,
            },
            {
                "name": "runtime_get_card_effect",
                "status": "pass",
                "evidence": {"validated_cards": len(runtime_results)},
                "rows": runtime_results,
            },
            {
                "name": "battle_execution" if battle_execution["scenario_count"] else "battle_execution_no_override",
                "status": "pass",
                "evidence": {
                    "events": battle_execution["event_count"],
                    "scenarios": battle_execution["scenario_count"],
                },
            },
        ],
        "battle_execution": battle_execution,
    }
    if args.output_json:
        Path(args.output_json).write_text(
            json.dumps(report, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    if args.output_md:
        write_markdown(Path(args.output_md), report)
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
