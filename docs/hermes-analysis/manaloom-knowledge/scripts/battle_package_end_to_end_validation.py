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


def validate_shuffle_self_into_library_if_expected(
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
    before_events: int,
    player,
    card: dict[str, Any],
) -> bool:
    if not scenario.get("expect_shuffle_self"):
        return False
    card_name = str(card.get("name") or "")
    shuffle_event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "spell_shuffled_into_library_on_resolution"
            and data.get("card") == card_name
        ),
        None,
    )
    if shuffle_event is None:
        fail("battle_events", f"missing {card_name} spell_shuffled_into_library_on_resolution event")
    expected_destination = str(scenario.get("expected_spell_destination") or "library")
    for field in ("to_zone", "destination", "zone_after"):
        if shuffle_event.get(field) != expected_destination:
            fail("battle_events", f"{card_name} {field}={shuffle_event.get(field)!r}")
    if not any(
        isinstance(library_card, dict) and library_card.get("name") == card_name
        for library_card in getattr(player, "library", [])
    ):
        fail("battle_execution", f"{card_name} was not shuffled into controller library")
    return True


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
    if bool(expected.get("artifact_only")) and "creature" in str(token.get("type_line") or "").lower():
        return False, f"artifact_only token is creature type_line={token.get('type_line')!r}"
    if bool(token.get("tapped")) != bool(expected.get("tapped")):
        return False, f"tapped={token.get('tapped')}"
    if "cant_block" in expected:
        if bool(battle.creature_cannot_block(token)) != bool(expected.get("cant_block")):
            return False, f"cant_block={token.get('cant_block')}"
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
        if "cant_block" in expected and bool(battle.creature_cannot_block(token)) != bool(expected.get("cant_block")):
            fail("battle_execution", f"{card['name']} {expected_name} cant_block={token.get('cant_block')}")

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
    if "cant_block" in expected and bool(token_event.get("token_cant_block")) != bool(expected.get("cant_block")):
        fail("battle_events", f"{card['name']} event token_cant_block={token_event.get('token_cant_block')}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "tokens_created": len(matches),
        "token_name": expected_name,
        "token_tapped": bool(expected.get("tapped")),
        "token_cant_block": bool(expected.get("cant_block")),
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


def run_damage_each_opponent_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Damage Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent A"), None, [])
    second_opponent = battle.Player(str(scenario.get("second_opponent") or "Opponent B"), None, [])
    opponent.life = int(scenario.get("opponent_life") or 9)
    second_opponent.life = int(scenario.get("second_opponent_life") or 11)
    opponents = [opponent, second_opponent]
    expected_damage = int(scenario.get("expected_damage") or 0)
    starting_life = {player.name: player.life for player in opponents}

    before_events = len(events)
    battle.apply_effect_immediate(
        active,
        opponents,
        card,
        turn=int(scenario.get("turn") or 5),
        rng=random.Random(int(scenario.get("seed") or 6074)),
    )

    for target in opponents:
        expected_life = starting_life[target.name] - expected_damage
        if target.life != expected_life:
            fail(
                "battle_execution",
                f"{card['name']} {target.name} life={target.life}, expected {expected_life}",
            )
    event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "damage_each_opponent_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} damage_each_opponent_resolved event")
    if int(event.get("amount") or 0) != expected_damage:
        fail("battle_events", f"{card['name']} event amount={event.get('amount')}, expected {expected_damage}")
    damaged = list(event.get("damaged_opponents") or [])
    if set(damaged) != {opponent.name, second_opponent.name}:
        fail("battle_events", f"{card['name']} damaged_opponents={damaged!r}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "damage": expected_damage,
        "opponent_life": opponent.life,
        "second_opponent_life": second_opponent.life,
    }


def run_damage_each_opponent_and_their_permanents_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Damage Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent A"), None, [])
    second_opponent = battle.Player(str(scenario.get("second_opponent") or "Opponent B"), None, [])
    opponent.life = int(scenario.get("opponent_life") or 9)
    second_opponent.life = int(scenario.get("second_opponent_life") or 11)
    expected_damage = int(scenario.get("expected_damage") or 0)
    expected_scope = str(scenario.get("expected_damage_scope") or "")
    include_planeswalker = bool(scenario.get("expected_planeswalker_damage"))
    opponent.battlefield.append(
        {
            "name": "E2E Opponent A Small Creature",
            "type_line": "Creature - Fixture",
            "effect": "creature",
            "power": 1,
            "toughness": max(1, expected_damage),
        }
    )
    second_opponent.battlefield.append(
        {
            "name": "E2E Opponent B Small Creature",
            "type_line": "Creature - Fixture",
            "effect": "creature",
            "power": 1,
            "toughness": max(1, expected_damage),
        }
    )
    if include_planeswalker:
        opponent.battlefield.append(
            {
                "name": "E2E Opponent Planeswalker",
                "type_line": "Legendary Planeswalker - Fixture",
                "effect": "planeswalker",
                "loyalty": max(1, expected_damage),
                "starting_loyalty": max(1, expected_damage),
            }
        )
    active.battlefield.append(
        {
            "name": "E2E Controller Creature Should Survive",
            "type_line": "Creature - Fixture",
            "effect": "creature",
            "power": 1,
            "toughness": max(1, expected_damage),
        }
    )
    opponents = [opponent, second_opponent]
    starting_life = {player.name: player.life for player in opponents}

    before_events = len(events)
    battle.apply_effect_immediate(
        active,
        opponents,
        card,
        turn=int(scenario.get("turn") or 5),
        rng=random.Random(int(scenario.get("seed") or 6074)),
    )

    for target in opponents:
        expected_life = starting_life[target.name] - expected_damage
        if target.life != expected_life:
            fail(
                "battle_execution",
                f"{card['name']} {target.name} life={target.life}, expected {expected_life}",
            )
    if any(
        permanent.get("name") == "E2E Controller Creature Should Survive"
        for permanent in active.battlefield
    ) is False:
        fail("battle_execution", f"{card['name']} damaged controller creature")
    remaining_opponent_creatures = [
        permanent
        for target in opponents
        for permanent in target.battlefield
        if "Creature" in str(permanent.get("type_line") or "")
    ]
    if remaining_opponent_creatures:
        fail(
            "battle_execution",
            f"{card['name']} left opponent creatures: {[p.get('name') for p in remaining_opponent_creatures]}",
        )
    if include_planeswalker and any(
        "Planeswalker" in str(permanent.get("type_line") or "")
        for permanent in opponent.battlefield
    ):
        fail("battle_execution", f"{card['name']} left opponent planeswalker")

    player_event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "damage_each_opponent_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if player_event is None:
        fail("battle_events", f"missing {card['name']} damage_each_opponent_resolved event")
    wipe_event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "damage_wipe_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if wipe_event is None:
        fail("battle_events", f"missing {card['name']} damage_wipe_resolved event")
    if wipe_event.get("damage_scope") != expected_scope:
        fail(
            "battle_events",
            f"{card['name']} damage_scope={wipe_event.get('damage_scope')}, expected {expected_scope}",
        )
    if int(wipe_event.get("live_opponent_creatures_destroyed") or 0) != 2:
        fail(
            "battle_events",
            f"{card['name']} live_opponent_creatures_destroyed={wipe_event.get('live_opponent_creatures_destroyed')}",
        )
    expected_planeswalkers_destroyed = 1 if include_planeswalker else 0
    if int(wipe_event.get("planeswalkers_destroyed") or 0) != expected_planeswalkers_destroyed:
        fail(
            "battle_events",
            f"{card['name']} planeswalkers_destroyed={wipe_event.get('planeswalkers_destroyed')}",
        )
    composite_event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "composite_rule_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if composite_event is None:
        fail("battle_events", f"missing {card['name']} composite_rule_resolved event")
    if int(composite_event.get("components_applied") or 0) != 2:
        fail("battle_events", f"{card['name']} components_applied={composite_event.get('components_applied')}")
    if int(composite_event.get("components_skipped") or 0) != 0:
        fail("battle_events", f"{card['name']} skipped composite components")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "damage": expected_damage,
        "damage_scope": expected_scope,
        "opponent_life": opponent.life,
        "second_opponent_life": second_opponent.life,
        "planeswalker_checked": include_planeswalker,
    }


def _nonmatching_damage_gain_life_target(constraints: dict[str, Any]) -> dict[str, Any]:
    if str(constraints.get("tapped_state") or constraints.get("tap_state") or "").lower() == "tapped":
        return {
            "name": "E2E Untapped Damage Decoy",
            "type_line": "Creature - Fixture",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "tapped": False,
        }
    if str(constraints.get("combat_state") or "").lower() == "attacking_or_blocking":
        return {
            "name": "E2E Idle Damage Decoy",
            "type_line": "Creature - Fixture",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "attacking": False,
            "blocking": False,
        }
    excluded_colors = {
        str(color).strip().upper()
        for color in constraints.get("exclude_colors") or []
        if str(color).strip()
    }
    if excluded_colors:
        color = sorted(excluded_colors)[0]
        return {
            "name": "E2E Excluded Color Damage Decoy",
            "type_line": "Creature - Fixture",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "colors": [color],
            "color_identity": [color],
            "mana_cost": f"{{{color}}}",
        }
    card_types = {
        str(value or "").strip().lower()
        for value in constraints.get("card_types") or []
        if str(value or "").strip()
    }
    if "creature" in card_types:
        return {
            "name": "E2E Noncreature Damage Decoy",
            "type_line": "Land",
            "effect": "land",
            "cmc": 0,
        }
    return {
        "name": "E2E Illegal Damage Decoy",
        "type_line": "Land",
        "effect": "land",
        "cmc": 0,
    }


def run_damage_gain_life_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Damage Life Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.life = int(scenario.get("controller_life") or 10)
    opponent.life = int(scenario.get("opponent_life") or 20)
    expected_damage = int(scenario.get("expected_damage") or 0)
    expected_life_gain = int(scenario.get("expected_life_gain") or 0)
    expected_treasure_count = int(scenario.get("expected_treasure_count") or 0)
    constraints = dict(scenario.get("expected_target_constraints") or {})
    active.hand = [battle.enrich_card(dict(card)) for card in (scenario.get("controller_hand") or [])]
    active.battlefield = [
        battle.enrich_card(dict(card))
        for card in (scenario.get("controller_battlefield") or [])
    ]
    target = dict(scenario.get("target") or {})
    nonmatching_target = None
    if target:
        target.setdefault("power", 2)
        target["toughness"] = min(int(target.get("toughness") or 2), max(1, expected_damage))
        target.setdefault("effect", "creature")
        nonmatching_target = dict(
            scenario.get("nonmatching_target")
            or _nonmatching_damage_gain_life_target(constraints)
        )
        opponent.battlefield = [
            battle.enrich_card(dict(nonmatching_target)),
            battle.enrich_card(dict(target)),
        ]

    before_events = len(events)
    controller_life_before = active.life
    controller_treasures_before = int(getattr(active, "treasures", 0) or 0)
    opponent_life_before = opponent.life
    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 5),
        rng=random.Random(int(scenario.get("seed") or 6075)),
    )
    expected_additional_cost = str(scenario.get("expected_additional_cost") or "").strip()
    additional_cost_event = None
    if expected_additional_cost:
        additional_cost_event = next(
            (
                data
                for event_name, data in events[before_events:]
                if event_name == "additional_cost_paid"
                and data.get("card") == card.get("name")
                and data.get("cost") == expected_additional_cost
            ),
            None,
        )
        if additional_cost_event is None:
            fail(
                "battle_events",
                f"missing {card['name']} additional_cost_paid {expected_additional_cost}",
            )
        expected_sacrificed = str(scenario.get("expected_sacrificed_name") or "").strip()
        if expected_sacrificed:
            if additional_cost_event.get("sacrificed") != expected_sacrificed:
                fail(
                    "battle_events",
                    f"{card['name']} sacrificed={additional_cost_event.get('sacrificed')!r}, expected {expected_sacrificed!r}",
                )
            if any(
                isinstance(permanent, dict) and permanent.get("name") == expected_sacrificed
                for permanent in active.battlefield
            ):
                fail("battle_execution", f"{card['name']} did not sacrifice {expected_sacrificed}")
        expected_returned = str(scenario.get("expected_returned_land_name") or "").strip()
        if expected_returned:
            if additional_cost_event.get("returned") != expected_returned:
                fail(
                    "battle_events",
                    f"{card['name']} returned={additional_cost_event.get('returned')!r}, expected {expected_returned!r}",
                )
            if not any(
                isinstance(card, dict) and card.get("name") == expected_returned
                for card in active.hand
            ):
                fail("battle_execution", f"{card['name']} did not return {expected_returned} to hand")
            if any(
                isinstance(permanent, dict) and permanent.get("name") == expected_returned
                for permanent in active.battlefield
            ):
                fail("battle_execution", f"{card['name']} left returned land {expected_returned} on battlefield")

    damage_event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "damage_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if damage_event is None:
        fail("battle_events", f"missing {card['name']} damage_resolved event")
    if int(damage_event.get("amount") or 0) != expected_damage:
        fail("battle_events", f"{card['name']} damage amount={damage_event.get('amount')}, expected {expected_damage}")
    if int(damage_event.get("life_gain_requested") or 0) != expected_life_gain:
        fail(
            "battle_events",
            f"{card['name']} life_gain_requested={damage_event.get('life_gain_requested')}, expected {expected_life_gain}",
        )
    if int(damage_event.get("life_gained") or 0) != expected_life_gain:
        fail("battle_events", f"{card['name']} life_gained={damage_event.get('life_gained')}, expected {expected_life_gain}")
    expected_controller_life = controller_life_before + expected_life_gain
    if active.life != expected_controller_life:
        fail("battle_execution", f"{card['name']} controller life={active.life}, expected {expected_controller_life}")
    treasure_delta = int(getattr(active, "treasures", 0) or 0) - controller_treasures_before
    if treasure_delta != expected_treasure_count:
        fail(
            "battle_execution",
            f"{card['name']} treasure delta={treasure_delta}, expected {expected_treasure_count}",
        )
    if expected_treasure_count:
        treasure_event = next(
            (
                data
                for event_name, data in events[before_events:]
                if event_name == "treasure_created"
                and data.get("card") == card.get("name")
                and data.get("trigger") == "on_resolution_after_damage"
            ),
            None,
        )
        if treasure_event is None:
            fail("battle_events", f"missing {card['name']} post-damage treasure_created event")
        if int(treasure_event.get("treasures_created") or 0) != expected_treasure_count:
            fail(
                "battle_events",
                f"{card['name']} event treasures_created={treasure_event.get('treasures_created')}",
            )

    if target:
        target_name = str(target.get("name") or "")
        if damage_event.get("target") != target_name:
            fail("battle_events", f"{card['name']} target={damage_event.get('target')!r}, expected {target_name!r}")
        if any(
            isinstance(permanent, dict) and permanent.get("name") == target_name
            for permanent in opponent.battlefield
        ):
            fail("battle_execution", f"{card['name']} did not remove damaged target {target_name}")
        if nonmatching_target and not any(
            isinstance(permanent, dict) and permanent.get("name") == nonmatching_target.get("name")
            for permanent in opponent.battlefield
        ):
            fail("battle_execution", f"{card['name']} removed illegal target {nonmatching_target.get('name')}")
    else:
        expected_opponent_life = opponent_life_before - expected_damage
        if opponent.life != expected_opponent_life:
            fail("battle_execution", f"{card['name']} opponent life={opponent.life}, expected {expected_opponent_life}")
        if damage_event.get("target_player") != opponent.name:
            fail("battle_events", f"{card['name']} target_player={damage_event.get('target_player')!r}")

    shuffled_self = validate_shuffle_self_into_library_if_expected(
        scenario,
        events,
        before_events,
        active,
        card,
    )

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "damage": expected_damage,
        "life_gained": expected_life_gain,
        "target": damage_event.get("target") or damage_event.get("target_player"),
        "controller_life": active.life,
        "opponent_life": opponent.life,
        "treasures_created": expected_treasure_count,
        "controller_treasures": int(getattr(active, "treasures", 0) or 0),
        "shuffled_self_into_library": shuffled_self,
        "additional_cost": additional_cost_event.get("cost") if additional_cost_event else None,
    }


def run_fixed_damage_target_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    result = run_damage_gain_life_spell(battle, scenario, events)
    if scenario.get("expected_cant_be_countered"):
        card = dict(scenario["card"])
        active = battle.Player(str(scenario.get("player") or "Damage Controller"), None, [])
        effect_data = battle.get_card_effect(card) or {}
        stack_item = battle.StackItem(card, active, effect_data)
        if not battle.spell_cant_be_countered(card, stack_item=stack_item):
            fail("battle_execution", f"{card['name']} was not visible as cant_be_countered")
        result["cant_be_countered"] = True
    return result


def run_damage_target_create_treasure(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    return run_damage_gain_life_spell(battle, scenario, events)


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


def run_creature_enters_draw(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(
        str(scenario.get("player") or "Draw Trigger Controller"),
        None,
        list(scenario.get("controller_library") or [{"name": "E2E Drawn Card", "type_line": "Sorcery"}]),
    )
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    all_players = [active, opponent]
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

    if bool(scenario.get("source_starts_on_battlefield", True)):
        active.battlefield.append(source)
        entering_card = dict(
            scenario.get("entering_creature")
            or {
                "name": "E2E Entering Creature",
                "type_line": "Creature - Soldier",
                "effect": "creature",
                "power": 3,
                "toughness": 3,
            }
        )
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

    expected_draw_count = int(scenario.get("expected_draw_count") or 0)
    expected_hand_after = int(scenario.get("expected_hand_after") or expected_draw_count)
    if len(active.hand) != expected_hand_after:
        fail(
            "battle_execution",
            f"{card['name']} hand after creature-enter draw={len(active.hand)}, expected {expected_hand_after}",
        )
    event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "trigger_resolved"
            and data.get("card") == card.get("name")
            and data.get("effect") == "draw_cards"
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} creature-enter draw_cards trigger_resolved event")
    if int(event.get("cards_drawn") or 0) != expected_draw_count:
        fail(
            "battle_events",
            f"{card['name']} cards_drawn={event.get('cards_drawn')}, expected {expected_draw_count}",
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
        "cards_drawn": expected_draw_count,
        "hand_after": len(active.hand),
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
        nonmatching_caster = (
            opponent
            if str(scenario.get("nonmatching_spell_controller") or "").lower() == "opponent"
            else active
        )
        battle.trigger_spell_cast_engines(
            nonmatching_caster,
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
    matching_caster = (
        opponent
        if str(scenario.get("matching_spell_controller") or "").lower() == "opponent"
        else active
    )
    battle.trigger_spell_cast_engines(
        matching_caster,
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
    land_event = None
    matching_land = scenario.get("matching_land")
    if isinstance(matching_land, dict):
        nonmatching_land = scenario.get("nonmatching_land")
        if isinstance(nonmatching_land, dict):
            before_life = active.life
            before_events = len(events)
            active.hand.append(dict(nonmatching_land))
            battle.play_land_candidate(
                active,
                [opponent],
                all_players,
                turn,
                None,
                {"card": active.hand[-1], "source_zone": "hand"},
            )
            if active.life != before_life:
                fail(
                    "battle_execution",
                    f"{card['name']} gained life from nonmatching land {nonmatching_land.get('name')}",
                )
            unexpected_land = next(
                (
                    data
                    for event_name, data in events[before_events:]
                    if event_name == "trigger_resolved"
                    and data.get("card") == card.get("name")
                    and data.get("effect") == "gain_life"
                    and data.get("trigger") == "land_enter"
                ),
                None,
            )
            if unexpected_land is not None:
                fail("battle_events", f"{card['name']} triggered from nonmatching land")

        before_events = len(events)
        active.hand.append(dict(matching_land))
        played = battle.play_land_candidate(
            active,
            [opponent],
            all_players,
            turn,
            None,
            {"card": active.hand[-1], "source_zone": "hand"},
        )
        if not played:
            fail("battle_execution", f"{card['name']} matching land was not played")
        expected_land_life_after = int(
            scenario.get("expected_land_life_after")
            or (expected_life_after + expected_life_gain)
        )
        if active.life != expected_land_life_after:
            fail(
                "battle_execution",
                f"{card['name']} life after land-enter gain-life trigger={active.life}, expected {expected_land_life_after}",
            )
        land_event = next(
            (
                data
                for event_name, data in events[before_events:]
                if event_name == "trigger_resolved"
                and data.get("card") == card.get("name")
                and data.get("effect") == "gain_life"
                and data.get("trigger") == "land_enter"
            ),
            None,
        )
        if land_event is None:
            fail("battle_events", f"missing {card['name']} land-enter gain_life trigger_resolved event")
        if int(land_event.get("life_gain_requested") or 0) != expected_life_gain:
            fail(
                "battle_events",
                f"{card['name']} land life_gain_requested={land_event.get('life_gain_requested')}, expected {expected_life_gain}",
            )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "life_after": active.life,
        "life_gained": expected_life_gain,
        "trigger": event.get("trigger"),
        "trigger_spell": event.get("trigger_spell"),
        "trigger_spell_controller": event.get("trigger_spell_controller"),
        "land_trigger": land_event.get("trigger") if land_event else None,
        "trigger_land": land_event.get("trigger_land") if land_event else None,
    }


def run_spell_cast_token_maker(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Spell Token Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    all_players = [active, opponent]
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
        before_token_count = len(
            [
                permanent
                for permanent in active.battlefield
                if isinstance(permanent, dict) and battle.is_token_permanent(permanent)
            ]
        )
        before_events = len(events)
        battle.trigger_spell_cast_engines(
            active,
            all_players,
            dict(nonmatching_spell),
            turn=turn,
            phase="precombat_main",
        )
        after_token_count = len(
            [
                permanent
                for permanent in active.battlefield
                if isinstance(permanent, dict) and battle.is_token_permanent(permanent)
            ]
        )
        if after_token_count != before_token_count:
            fail(
                "battle_execution",
                f"{card['name']} created tokens from nonmatching spell {nonmatching_spell.get('name')}",
            )
        unexpected = next(
            (
                data
                for event_name, data in events[before_events:]
                if event_name == "trigger_resolved"
                and data.get("card") == card.get("name")
                and data.get("effect") == "token_maker"
            ),
            None,
        )
        if unexpected is not None:
            fail("battle_events", f"{card['name']} token trigger resolved from nonmatching spell")

    matching_spell = dict(scenario.get("matching_spell") or {})
    if not matching_spell:
        fail("scenario", f"{card['name']} missing matching_spell")
    before_events = len(events)
    before_tokens = [
        permanent
        for permanent in active.battlefield
        if isinstance(permanent, dict) and battle.is_token_permanent(permanent)
    ]
    battle.trigger_spell_cast_engines(
        active,
        all_players,
        matching_spell,
        turn=turn,
        phase="precombat_main",
    )
    after_tokens = [
        permanent
        for permanent in active.battlefield
        if isinstance(permanent, dict) and battle.is_token_permanent(permanent)
    ]
    created_tokens = after_tokens[len(before_tokens):]
    expected = dict(scenario.get("expected_token") or {})
    expected_tokens = scenario.get("expected_tokens") or [expected]
    expected_total = int(
        scenario.get("expected_tokens_created")
        or sum(int(token.get("count") or 0) for token in expected_tokens)
    )
    if len(created_tokens) != expected_total:
        fail(
            "battle_execution",
            f"{card['name']} created token total={len(created_tokens)}, expected {expected_total}",
        )
    matches = assert_expected_token_multiset(
        battle,
        created_tokens,
        expected_tokens,
        card["name"],
    )
    event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "trigger_resolved"
            and data.get("card") == card.get("name")
            and data.get("effect") == "token_maker"
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} spell-cast token_maker trigger_resolved event")
    if int(event.get("tokens_created") or 0) != expected_total:
        fail(
            "battle_events",
            f"{card['name']} tokens_created={event.get('tokens_created')}, expected {expected_total}",
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
        "tokens_created": len(matches),
        "trigger": event.get("trigger"),
        "trigger_spell": event.get("trigger_spell"),
        "token_names": sorted(token.get("name") for token in matches),
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

    expected = dict(scenario.get("expected_token") or {})
    expected_tokens = scenario.get("expected_tokens") or [expected]
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
    if not scenario.get("expected_tokens") and "cant_block" in expected:
        if bool(token_event.get("token_cant_block")) != bool(expected.get("cant_block")):
            fail("battle_events", f"{card['name']} event token_cant_block={token_event.get('token_cant_block')}")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "tokens_created": len(actual_tokens),
        "token_names": sorted(token.get("name") for token in actual_tokens),
        "token_cant_block": any(bool(token.get("cant_block")) for token in actual_tokens),
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


def run_creature_etb_draw_discard(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "ETB Draw Discard Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.hand = [battle.enrich_card(dict(card)) for card in (scenario.get("controller_hand") or [])]
    active.library = [battle.enrich_card(dict(card)) for card in (scenario.get("controller_library") or [])]
    expected_draw_count = int(scenario.get("expected_draw_count") or 0)
    expected_discard_count = int(scenario.get("expected_discard_count") or 0)
    expected_hand_after = int(
        scenario.get("expected_hand_after")
        if scenario.get("expected_hand_after") is not None
        else max(0, len(active.hand) + expected_draw_count - expected_discard_count)
    )
    expected_graveyard_after = int(
        scenario.get("expected_graveyard_after")
        if scenario.get("expected_graveyard_after") is not None
        else expected_discard_count
    )

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
        random.Random(int(scenario.get("seed") or 6079)),
        all_players=[active, opponent],
    )

    event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "etb_draw_discard_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} etb_draw_discard_resolved event")
    if int(event.get("cards_drawn") or 0) != expected_draw_count:
        fail(
            "battle_events",
            f"{card['name']} cards_drawn={event.get('cards_drawn')}, expected {expected_draw_count}",
        )
    if int(event.get("cards_discarded") or 0) != expected_discard_count:
        fail(
            "battle_events",
            f"{card['name']} cards_discarded={event.get('cards_discarded')}, expected {expected_discard_count}",
        )
    if len(active.hand) != expected_hand_after:
        fail(
            "battle_execution",
            f"{card['name']} hand after ETB draw/discard={len(active.hand)}, expected {expected_hand_after}",
        )
    if len(active.graveyard) != expected_graveyard_after:
        fail(
            "battle_execution",
            f"{card['name']} graveyard after ETB draw/discard={len(active.graveyard)}, expected {expected_graveyard_after}",
        )
    if len(active.library) != library_before - expected_draw_count:
        fail(
            "battle_execution",
            f"{card['name']} library after ETB draw/discard={len(active.library)}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "cards_drawn": expected_draw_count,
        "cards_discarded": expected_discard_count,
        "hand_after": len(active.hand),
        "graveyard_after": len(active.graveyard),
        "validated_keywords": expected_keywords,
    }


def run_creature_etb_target_stat_modifier(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    active = battle.Player(str(scenario.get("player") or "ETB Boost Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    target = battle.enrich_card(
        {
            "name": "E2E Target Creature",
            "type_line": "Creature - Soldier",
            "power": 4,
            "toughness": 4,
            **dict(scenario.get("target") or {}),
        }
    )
    expected_power_delta = int(
        scenario.get("expected_power_delta") or effect.get("power_delta") or effect.get("power_boost") or 0
    )
    expected_toughness_delta = int(
        scenario.get("expected_toughness_delta")
        or effect.get("toughness_delta")
        or effect.get("toughness_boost")
        or 0
    )
    harmful = expected_toughness_delta < 0 or (expected_power_delta < 0 and expected_toughness_delta <= 0)
    if harmful:
        active.battlefield = []
        opponent.battlefield = [target]
    else:
        active.battlefield = [target]
        opponent.battlefield = []
    permanent = battle.prepare_entering_permanent(
        battle.enrich_card({**card, **effect}),
        controller=active,
        all_players=[active, opponent],
        turn=int(scenario.get("turn") or 6),
    )
    active.battlefield.append(permanent)
    before_events = len(events)
    before_power = int(target.get("power") or 0)
    before_toughness = int(target.get("toughness") or 0)
    battle.resolve_generic_permanent_etb(
        active,
        [opponent],
        permanent,
        effect,
        int(scenario.get("turn") or 6),
        random.Random(int(scenario.get("seed") or 6080)),
        all_players=[active, opponent],
    )
    expected_power = before_power + expected_power_delta
    expected_toughness = before_toughness + expected_toughness_delta
    if int(target.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} target power={target.get('power')!r}, expected {expected_power}")
    if int(target.get("toughness") or 0) != expected_toughness:
        fail(
            "battle_execution",
            f"{card['name']} target toughness={target.get('toughness')!r}, expected {expected_toughness}",
        )
    resolved_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "stat_modifier_until_eot_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == target.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} ETB target stat modifier event")
    if int(resolved_event.get("power_delta") or 0) != expected_power_delta:
        fail("battle_events", f"{card['name']} power_delta={resolved_event.get('power_delta')!r}")
    if int(resolved_event.get("toughness_delta") or 0) != expected_toughness_delta:
        fail("battle_events", f"{card['name']} toughness_delta={resolved_event.get('toughness_delta')!r}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "target_power": int(target.get("power") or 0),
        "target_toughness": int(target.get("toughness") or 0),
        "power_delta": expected_power_delta,
        "toughness_delta": expected_toughness_delta,
    }


def run_creature_etb_library_pick(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(
        str(scenario.get("player") or "ETB Library Pick Controller"),
        None,
        [],
    )
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.library = [dict(candidate) for candidate in scenario.get("controller_library") or []]
    expected_picked = [str(name) for name in scenario.get("expected_picked") or []]
    expected_look_count = int(scenario.get("expected_look_count") or 0)
    expected_rest_destination = str(scenario.get("expected_rest_destination") or "graveyard")
    expected_pick_target = str(scenario.get("expected_pick_target") or "any_card")
    if expected_look_count <= 0:
        fail("battle_execution", f"{card['name']} missing expected_look_count")

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

    dig_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "dig_to_hand_resolved" and data.get("card") == card.get("name")
        ),
        None,
    )
    if dig_event is None:
        fail("battle_events", f"missing {card['name']} dig_to_hand_resolved event")
    if int(dig_event.get("looked_count") or 0) != expected_look_count:
        fail("battle_events", f"{card['name']} looked_count={dig_event.get('looked_count')}")
    actual_picked = [str(name) for name in dig_event.get("picked") or []]
    if actual_picked != expected_picked:
        fail("battle_execution", f"{card['name']} picked={actual_picked} expected={expected_picked}")
    if str(dig_event.get("pick_target") or "") != expected_pick_target:
        fail("battle_events", f"{card['name']} pick_target={dig_event.get('pick_target')}")
    if str(dig_event.get("rest_destination") or "") != expected_rest_destination:
        fail("battle_events", f"{card['name']} rest_destination={dig_event.get('rest_destination')}")

    if expected_rest_destination in {"library_bottom", "bottom", "bottom_library"}:
        moved_rest = [str(name) for name in dig_event.get("moved_to_library_bottom") or []]
        bottom_names = [str(candidate.get("name", "?")) for candidate in active.library[-len(moved_rest) :]]
        if moved_rest and bottom_names != moved_rest:
            fail("battle_execution", f"{card['name']} library_bottom={bottom_names} expected={moved_rest}")
    else:
        moved_rest = [str(name) for name in dig_event.get("moved_to_graveyard") or []]
        graveyard_names = [str(candidate.get("name", "?")) for candidate in active.graveyard]
        if moved_rest != graveyard_names:
            fail("battle_execution", f"{card['name']} graveyard={graveyard_names} expected={moved_rest}")

    hand_names = [str(candidate.get("name", "?")) for candidate in active.hand]
    if hand_names != expected_picked:
        fail("battle_execution", f"{card['name']} hand={hand_names} expected={expected_picked}")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "picked": actual_picked,
        "moved_rest": moved_rest,
        "rest_destination": expected_rest_destination,
        "pick_target": expected_pick_target,
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
    if not scenario.get("expected_tokens") and "cant_block" in expected:
        if bool(token_event.get("token_cant_block")) != bool(expected.get("cant_block")):
            fail("battle_events", f"{card['name']} event token_cant_block={token_event.get('token_cant_block')}")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "tokens_created": len(matches),
        "token_name": expected_name or None,
        "token_names": sorted(token.get("name") for token in matches),
        "token_tapped": bool(expected.get("tapped")) if expected else False,
        "token_cant_block": bool(expected.get("cant_block")) if expected else False,
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


def run_creature_dies_add_counters(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Dies Counter Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Dies Counter Opponent"), None, [])
    effect_data = battle.get_card_effect(card)
    permanent = battle.enrich_card({**card, "type_line": "Creature", **effect_data})
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

    target_fixture = dict(scenario.get("target") or {})
    target = battle.enrich_card(
        {
            "name": str(target_fixture.get("name") or f"E2E Dies Counter Target for {card['name']}"),
            "type_line": "Creature - Soldier",
            "effect": "creature",
            "power": int(scenario.get("target_power") or 3),
            "toughness": int(scenario.get("target_toughness") or 3),
            "cmc": int(scenario.get("target_cmc") or 3),
            "tapped": False,
            **target_fixture,
        }
    )
    nonmatching_fixture = scenario.get("nonmatching_target")
    if nonmatching_fixture:
        active.battlefield.append(battle.enrich_card(dict(nonmatching_fixture)))

    expected_counter_type = str(
        scenario.get("expected_counter_type")
        or effect_data.get("dies_add_counters_counter_type")
        or effect_data.get("counter_type")
        or "+1/+1"
    )
    expected_counter_count = int(
        scenario.get("expected_counter_count")
        or effect_data.get("dies_add_counters_count")
        or effect_data.get("counter_count")
        or 1
    )
    target_owner_label = str(scenario.get("target_owner") or "").lower()
    if target_owner_label == "opponent":
        opponent.battlefield.append(target)
        target_owner = opponent
    else:
        active.battlefield.append(target)
        target_owner = active

    before = _counter_value(battle, target, expected_counter_type)
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

    after = _counter_value(battle, target, expected_counter_type)
    if after - before != expected_counter_count:
        fail(
            "battle_execution",
            f"{card['name']} expected {expected_counter_count} {expected_counter_type} counters on {target.get('name')}, got {after - before}",
        )

    resolved_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "dies_add_counters_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == target.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} dies_add_counters_resolved event")
    if int(resolved_event.get("counters_added") or 0) != expected_counter_count:
        fail(
            "battle_events",
            f"{card['name']} event counters_added={resolved_event.get('counters_added')}, expected {expected_counter_count}",
        )
    if str(resolved_event.get("counter_type") or "") != expected_counter_type:
        fail(
            "battle_events",
            f"{card['name']} event counter_type={resolved_event.get('counter_type')!r}, expected {expected_counter_type!r}",
        )
    if resolved_event.get("trigger") != "dies" or resolved_event.get("effect") != "add_counters":
        fail("battle_events", f"{card['name']} event trigger/effect mismatch")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "target_owner": target_owner.name,
        "counter_type": expected_counter_type,
        "counters_added": after - before,
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


def run_single_target_removal(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Active"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    controller_starting_life = int(scenario.get("controller_life") or getattr(active, "life", 20) or 20)
    target_controller_starting_life = int(
        scenario.get("target_controller_life") or getattr(opponent, "life", 20) or 20
    )
    expected_controller_life_gain = int(scenario.get("expected_controller_life_gain") or 0)
    expected_source_controller_life_loss = int(scenario.get("expected_source_controller_life_loss") or 0)
    expected_source_controller_damage = int(scenario.get("expected_source_controller_damage") or 0)
    expected_target_controller_damage = int(scenario.get("expected_target_controller_damage") or 0)
    active.life = controller_starting_life
    for card_fixture in scenario.get("controller_hand") or []:
        if isinstance(card_fixture, dict):
            active.hand.append(dict(card_fixture))
    controller_battlefield = [
        dict(card_fixture)
        for card_fixture in scenario.get("controller_battlefield") or []
        if isinstance(card_fixture, dict)
    ]
    target = dict(scenario["target"])
    nonmatching = dict(
        scenario.get("nonmatching_target")
        or {
            "name": "E2E Illegal Removal Target",
            "type_line": "Land",
            "effect": "land",
            "cmc": 0,
        }
    )
    before_events = len(events)

    effect_data = battle.get_card_effect(card)
    expected_effect = scenario.get("expected_effect")
    if expected_effect and effect_data.get("effect") != expected_effect:
        fail("battle_execution", f"{card['name']} effect={effect_data.get('effect')!r}")
    constraints = dict(
        scenario.get("expected_target_constraints")
        or effect_data.get("target_constraints")
        or {}
    )
    target_controller_scope = str(
        effect_data.get("target_controller")
        or constraints.get("controller_scope")
        or "opponent"
    ).lower()
    if target_controller_scope in {"self", "you", "controller", "controlled"}:
        target_owner = active
        other_owner = opponent
    else:
        target_owner = opponent
        other_owner = active
    if expected_target_controller_damage > 0:
        target_owner.life = target_controller_starting_life
    if target_owner is active:
        target_owner.battlefield = [*controller_battlefield, nonmatching, target]
        other_owner.battlefield = []
    else:
        target_owner.battlefield = [nonmatching, target]
        other_owner.battlefield = controller_battlefield

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 6065)),
    )

    target_name = str(target.get("name") or "")
    nonmatching_name = str(nonmatching.get("name") or "")
    destination = str(scenario.get("expected_destination") or "graveyard").lower()
    destination_zone_name = "exile" if destination == "exile" else "hand" if destination == "hand" else "graveyard"
    destination_zone = getattr(target_owner, destination_zone_name)
    moved_names = [str(item.get("name") or "") for item in destination_zone if isinstance(item, dict)]
    battlefield_names = [str(item.get("name") or "") for item in target_owner.battlefield if isinstance(item, dict)]
    if target_name not in moved_names:
        fail("battle_execution", f"{card['name']} did not move legal target {target_name} to {destination}")
    if nonmatching_name not in battlefield_names:
        fail("battle_execution", f"{card['name']} removed illegal target {nonmatching_name}")

    removal_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "removal_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == target_name
        ),
        None,
    )
    if removal_event is None:
        fail("battle_events", f"missing {card['name']} removal_resolved event for {target_name}")
    if removal_event.get("target_legal") is not True:
        fail("battle_events", f"{card['name']} target_legal={removal_event.get('target_legal')!r}")
    if removal_event.get("target_player") != target_owner.name:
        fail("battle_events", f"{card['name']} target_player={removal_event.get('target_player')!r}")
    if str(removal_event.get("destination") or "").lower() != destination:
        fail("battle_events", f"{card['name']} destination={removal_event.get('destination')!r}")
    expected_additional_cost = str(scenario.get("expected_additional_cost") or "").strip()
    additional_cost_event = None
    if expected_additional_cost:
        additional_cost_event = next(
            (
                data
                for event, data in events[before_events:]
                if event == "additional_cost_paid"
                and data.get("card") == card.get("name")
                and data.get("cost") == expected_additional_cost
            ),
            None,
        )
        if additional_cost_event is None:
            fail(
                "battle_events",
                f"missing {card['name']} additional_cost_paid {expected_additional_cost}",
            )
    expected_pay_life_amount = int(scenario.get("expected_pay_life_amount") or 0)
    if expected_pay_life_amount > 0 and additional_cost_event is not None:
        if int(additional_cost_event.get("pay_life_amount") or 0) != expected_pay_life_amount:
            fail(
                "battle_events",
                f"{card['name']} pay_life_amount={additional_cost_event.get('pay_life_amount')!r}",
            )
    expected_discarded_name = str(scenario.get("expected_discarded_name") or "").strip()
    if expected_discarded_name:
        graveyard_names = [
            str(item.get("name") or "")
            for item in active.graveyard
            if isinstance(item, dict)
        ]
        if expected_discarded_name not in graveyard_names:
            fail(
                "battle_execution",
                f"{card['name']} did not discard {expected_discarded_name}",
            )
    expected_sacrificed_name = str(scenario.get("expected_sacrificed_name") or "").strip()
    if expected_sacrificed_name:
        active_battlefield_names = [
            str(item.get("name") or "")
            for item in active.battlefield
            if isinstance(item, dict)
        ]
        if expected_sacrificed_name in active_battlefield_names:
            fail(
                "battle_execution",
                f"{card['name']} did not sacrifice {expected_sacrificed_name}",
            )
    if expected_controller_life_gain > 0:
        expected_life = controller_starting_life + expected_controller_life_gain
        if active.life != expected_life:
            fail(
                "battle_execution",
                f"{card['name']} controller_life={active.life}, expected={expected_life}",
            )
        for field, expected in (
            ("controller_gains_life", expected_controller_life_gain),
            ("life_gain_requested", expected_controller_life_gain),
            ("life_gained", expected_controller_life_gain),
        ):
            if int(removal_event.get(field) or 0) != expected:
                fail("battle_events", f"{card['name']} {field}={removal_event.get(field)!r}")
        if removal_event.get("life_gain_recipient") != "controller":
            fail(
                "battle_events",
                f"{card['name']} life_gain_recipient={removal_event.get('life_gain_recipient')!r}",
            )
    if expected_source_controller_life_loss > 0:
        expected_life = controller_starting_life - expected_source_controller_life_loss
        if active.life != expected_life:
            fail(
                "battle_execution",
                f"{card['name']} controller_life={active.life}, expected={expected_life}",
            )
        penalty_event = next(
            (
                data
                for event, data in events[before_events:]
                if event == "source_controller_life_loss_on_resolve"
                and data.get("card") == card.get("name")
            ),
            None,
        )
        if penalty_event is None:
            fail("battle_events", f"missing {card['name']} source_controller_life_loss_on_resolve event")
        if int(penalty_event.get("source_controller_life_lost") or 0) != expected_source_controller_life_loss:
            fail(
                "battle_events",
                f"{card['name']} source_controller_life_lost={penalty_event.get('source_controller_life_lost')!r}",
            )
    if expected_source_controller_damage > 0:
        expected_life = controller_starting_life - expected_source_controller_damage
        if active.life != expected_life:
            fail(
                "battle_execution",
                f"{card['name']} controller_life={active.life}, expected={expected_life}",
            )
        damage_event = next(
            (
                data
                for event, data in events[before_events:]
                if event == "source_controller_damage_on_resolve"
                and data.get("card") == card.get("name")
            ),
            None,
        )
        if damage_event is None:
            fail("battle_events", f"missing {card['name']} source_controller_damage_on_resolve event")
        if int(damage_event.get("actual_damage_dealt") or 0) != expected_source_controller_damage:
            fail(
                "battle_events",
                f"{card['name']} actual_damage_dealt={damage_event.get('actual_damage_dealt')!r}",
            )
    if expected_target_controller_damage > 0:
        expected_life = target_controller_starting_life - expected_target_controller_damage
        if target_owner.life != expected_life:
            fail(
                "battle_execution",
                f"{card['name']} target_controller_life={target_owner.life}, expected={expected_life}",
            )
        target_damage_event = next(
            (
                data
                for event, data in events[before_events:]
                if event == "target_controller_damage_on_resolve"
                and data.get("card") == card.get("name")
                and data.get("target") == target_name
            ),
            None,
        )
        if target_damage_event is None:
            fail("battle_events", f"missing {card['name']} target_controller_damage_on_resolve event")
        if target_damage_event.get("target_controller") != target_owner.name:
            fail(
                "battle_events",
                f"{card['name']} target_controller={target_damage_event.get('target_controller')!r}",
            )
        if int(target_damage_event.get("actual_damage_dealt") or 0) != expected_target_controller_damage:
            fail(
                "battle_events",
                f"{card['name']} target actual_damage_dealt={target_damage_event.get('actual_damage_dealt')!r}",
            )

    result = {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target_name,
        "nonmatching_target": nonmatching_name,
        "destination": destination,
        "target_player": target_owner.name,
        "moved_names": moved_names,
        "battlefield_names": battlefield_names,
    }
    if expected_controller_life_gain > 0:
        result["controller_life_before"] = controller_starting_life
        result["controller_life_after"] = active.life
        result["controller_life_gained"] = expected_controller_life_gain
    if expected_source_controller_life_loss > 0:
        result["controller_life_before"] = controller_starting_life
        result["controller_life_after"] = active.life
        result["source_controller_life_lost"] = expected_source_controller_life_loss
    if expected_source_controller_damage > 0:
        result["controller_life_before"] = controller_starting_life
        result["controller_life_after"] = active.life
        result["source_controller_damage_dealt"] = expected_source_controller_damage
    if expected_target_controller_damage > 0:
        result["target_controller_life_before"] = target_controller_starting_life
        result["target_controller_life_after"] = target_owner.life
        result["target_controller_damage_dealt"] = expected_target_controller_damage
    if expected_additional_cost:
        result["additional_cost"] = expected_additional_cost
    if expected_pay_life_amount > 0:
        result["pay_life_amount"] = expected_pay_life_amount
    return result


def run_modal_damage_or_destroy(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Active"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    destroy_target = battle.enrich_card(dict(scenario["destroy_target"]))
    damage_target = battle.enrich_card(dict(scenario["damage_target"]))
    opponent.battlefield = [damage_target, destroy_target]
    before_events = len(events)

    effect_data = battle.get_card_effect(card)
    if effect_data.get("effect") != "modal_spell":
        fail("battle_execution", f"{card['name']} effect={effect_data.get('effect')!r}")
    if effect_data.get("battle_model_scope") != "xmage_choose_one_damage_or_destroy_target_spell_v1":
        fail("battle_execution", f"{card['name']} scope={effect_data.get('battle_model_scope')!r}")

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 6077)),
    )

    expected_mode = str(scenario.get("expected_selected_mode") or "destroy_target")
    expected_removed = str(scenario.get("expected_removed_target") or destroy_target.get("name") or "")
    expected_damage_survives = str(
        scenario.get("expected_damage_target_survives") or damage_target.get("name") or ""
    )
    destination = str(scenario.get("expected_destination") or "graveyard").lower()
    destination_zone_name = "exile" if destination == "exile" else "hand" if destination == "hand" else "graveyard"
    moved_names = [
        str(item.get("name") or "")
        for item in getattr(opponent, destination_zone_name)
        if isinstance(item, dict)
    ]
    battlefield_names = [
        str(item.get("name") or "")
        for item in opponent.battlefield
        if isinstance(item, dict)
    ]
    if expected_removed not in moved_names:
        fail("battle_execution", f"{card['name']} did not move modal destroy target {expected_removed}")
    if expected_damage_survives not in battlefield_names:
        fail("battle_execution", f"{card['name']} incorrectly removed modal damage target {expected_damage_survives}")

    modal_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "modal_spell_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if modal_event is None:
        fail("battle_events", f"missing {card['name']} modal_spell_resolved event")
    selected_modes = modal_event.get("selected_modes") or []
    selected_mode = selected_modes[0] if selected_modes else {}
    if selected_mode.get("mode") != expected_mode:
        fail("battle_events", f"{card['name']} selected mode={selected_mode.get('mode')!r}")
    if modal_event.get("mode_selection") != "choose_one":
        fail("battle_events", f"{card['name']} mode_selection={modal_event.get('mode_selection')!r}")

    removal_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "removal_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == expected_removed
        ),
        None,
    )
    if removal_event is None:
        fail("battle_events", f"missing {card['name']} modal removal_resolved event")
    if str(removal_event.get("destination") or "").lower() != destination:
        fail("battle_events", f"{card['name']} destination={removal_event.get('destination')!r}")
    damage_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "damage_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == expected_damage_survives
        ),
        None,
    )
    if damage_event is not None:
        fail("battle_events", f"{card['name']} also damaged non-selected modal target")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "selected_mode": expected_mode,
        "removed_target": expected_removed,
        "damage_target_survived": expected_damage_survives,
        "destination": destination,
    }


def run_single_target_removal_and_surveil(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Active"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.battlefield = [dict(permanent) for permanent in scenario.get("player_battlefield") or []]
    active.library = [dict(library_card) for library_card in scenario.get("library") or []]
    target = dict(scenario["target"])
    nonmatching = dict(
        scenario.get("nonmatching_target")
        or {
            "name": "E2E Illegal Removal Target",
            "type_line": "Land",
            "effect": "land",
            "cmc": 0,
        }
    )
    opponent.battlefield = [nonmatching, target]
    before_events = len(events)

    effect_data = battle.get_card_effect(card)
    if effect_data.get("effect") != "composite_resolution":
        fail("battle_execution", f"{card['name']} effect={effect_data.get('effect')!r}")

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 6066)),
    )

    target_name = str(target.get("name") or "")
    nonmatching_name = str(nonmatching.get("name") or "")
    destination = str(scenario.get("expected_destination") or "graveyard").lower()
    destination_zone_name = "exile" if destination == "exile" else "hand" if destination == "hand" else "graveyard"
    destination_zone = getattr(opponent, destination_zone_name)
    moved_names = [str(item.get("name") or "") for item in destination_zone if isinstance(item, dict)]
    battlefield_names = [str(item.get("name") or "") for item in opponent.battlefield if isinstance(item, dict)]
    if target_name not in moved_names:
        fail("battle_execution", f"{card['name']} did not move legal target {target_name} to {destination}")
    if nonmatching_name not in battlefield_names:
        fail("battle_execution", f"{card['name']} removed illegal target {nonmatching_name}")

    removal_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "removal_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == target_name
        ),
        None,
    )
    if removal_event is None:
        fail("battle_events", f"missing {card['name']} removal_resolved event for {target_name}")
    if removal_event.get("target_legal") is not True:
        fail("battle_events", f"{card['name']} target_legal={removal_event.get('target_legal')!r}")

    expected_surveil_count = int(scenario.get("expected_surveil_count") or 1)
    surveil_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "surveil_resolved"
            and data.get("card") == card.get("name")
            and int(data.get("surveil_count") or 0) == expected_surveil_count
        ),
        None,
    )
    if surveil_event is None:
        fail("battle_events", f"missing {card['name']} surveil_resolved event")
    looked_at = list(surveil_event.get("looked_at") or [])
    if len(looked_at) != min(expected_surveil_count, len(scenario.get("library") or [])):
        fail("battle_events", f"{card['name']} surveil looked_at={looked_at!r}")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target_name,
        "nonmatching_target": nonmatching_name,
        "destination": destination,
        "moved_names": moved_names,
        "surveil_count": expected_surveil_count,
        "surveil_looked_at": looked_at,
        "surveil_moved_to_graveyard": list(surveil_event.get("moved_to_graveyard") or []),
        "surveil_top_after": list(surveil_event.get("top_after") or []),
    }


def run_single_target_removal_and_draw(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Active"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.library = [
        battle.enrich_card(dict(library_card))
        for library_card in (scenario.get("controller_library") or [])
        if isinstance(library_card, dict)
    ]
    target = dict(scenario["target"])
    nonmatching = dict(
        scenario.get("nonmatching_target")
        or {
            "name": "E2E Illegal Removal Target",
            "type_line": "Land",
            "effect": "land",
            "cmc": 0,
        }
    )
    target_zone = str(scenario.get("target_zone") or "battlefield").lower()
    if target_zone == "graveyard":
        opponent.battlefield = [nonmatching]
        opponent.graveyard = [target]
    else:
        opponent.battlefield = [nonmatching, target]
    before_events = len(events)
    library_before = len(active.library)

    effect_data = battle.get_card_effect(card)
    if effect_data.get("effect") != "composite_resolution":
        fail("battle_execution", f"{card['name']} effect={effect_data.get('effect')!r}")

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6067),
        rng=random.Random(int(scenario.get("seed") or 6067)),
    )

    target_name = str(target.get("name") or "")
    nonmatching_name = str(nonmatching.get("name") or "")
    destination = str(scenario.get("expected_destination") or "graveyard").lower()
    destination_zone_name = "exile" if destination == "exile" else "hand" if destination == "hand" else "graveyard"
    destination_zone = getattr(opponent, destination_zone_name)
    moved_names = [str(item.get("name") or "") for item in destination_zone if isinstance(item, dict)]
    battlefield_names = [str(item.get("name") or "") for item in opponent.battlefield if isinstance(item, dict)]
    graveyard_names = [str(item.get("name") or "") for item in opponent.graveyard if isinstance(item, dict)]
    if target_name not in moved_names:
        fail("battle_execution", f"{card['name']} did not move legal target {target_name} to {destination}")
    if target_zone == "graveyard" and target_name in graveyard_names:
        fail("battle_execution", f"{card['name']} left graveyard target {target_name} in graveyard")
    if nonmatching_name not in battlefield_names:
        fail("battle_execution", f"{card['name']} removed illegal target {nonmatching_name}")

    expected_draw_count = int(scenario.get("expected_draw_count") or effect_data.get("draw_count") or 1)
    if len(active.hand) != expected_draw_count:
        fail("battle_execution", f"{card['name']} drew {len(active.hand)} cards, expected {expected_draw_count}")
    if len(active.library) != library_before - expected_draw_count:
        fail(
            "battle_execution",
            f"{card['name']} library={len(active.library)}, expected {library_before - expected_draw_count}",
        )

    if target_zone == "graveyard":
        graveyard_exile_event = next(
            (
                data
                for event, data in events[before_events:]
                if event == "graveyard_exile_resolved"
                and data.get("card") == card.get("name")
                and target_name in [str(name or "") for name in data.get("exiled") or []]
            ),
            None,
        )
        if graveyard_exile_event is None:
            fail("battle_events", f"missing {card['name']} graveyard_exile_resolved event for {target_name}")
        if str(graveyard_exile_event.get("destination") or "").lower() != destination:
            fail("battle_events", f"{card['name']} destination={graveyard_exile_event.get('destination')!r}")
    else:
        removal_event = next(
            (
                data
                for event, data in events[before_events:]
                if event == "removal_resolved"
                and data.get("card") == card.get("name")
                and data.get("target") == target_name
            ),
            None,
        )
        if removal_event is None:
            fail("battle_events", f"missing {card['name']} removal_resolved event for {target_name}")
        if str(removal_event.get("destination") or "").lower() != destination:
            fail("battle_events", f"{card['name']} destination={removal_event.get('destination')!r}")

    draw_component_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "composite_rule_component_resolved"
            and data.get("card") == card.get("name")
            and data.get("component_effect") == "draw_cards"
            and data.get("outcome") == "cards_drawn"
        ),
        None,
    )
    if draw_component_event is None:
        fail("battle_events", f"missing {card['name']} composite draw_cards component event")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target_name,
        "nonmatching_target": nonmatching_name,
        "destination": destination,
        "moved_names": moved_names,
        "cards_drawn": expected_draw_count,
        "hand": [item.get("name") for item in active.hand if isinstance(item, dict)],
    }


def run_multi_target_removal(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Active"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    targets = [dict(target) for target in scenario.get("targets") or []]
    if len(targets) <= 1:
        fail("battle_execution", f"{card['name']} multi-target scenario has {len(targets)} targets")
    nonmatching = dict(
        scenario.get("nonmatching_target")
        or {
            "name": "E2E Illegal Removal Target",
            "type_line": "Land",
            "effect": "land",
            "cmc": 0,
        }
    )
    opponent.battlefield = [nonmatching, *targets]
    controller_starting_life = int(scenario.get("controller_life") or getattr(active, "life", 20) or 20)
    expected_source_controller_life_loss = int(scenario.get("expected_source_controller_life_loss") or 0)
    active.life = controller_starting_life
    before_events = len(events)

    effect_data = battle.get_card_effect(card)
    expected_effect = scenario.get("expected_effect")
    if expected_effect and effect_data.get("effect") != expected_effect:
        fail("battle_execution", f"{card['name']} effect={effect_data.get('effect')!r}")

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 6065)),
    )

    target_names = [str(target.get("name") or "") for target in targets]
    nonmatching_name = str(nonmatching.get("name") or "")
    destination = str(scenario.get("expected_destination") or "graveyard").lower()
    destination_zone_name = "exile" if destination == "exile" else "hand" if destination == "hand" else "graveyard"
    destination_zone = getattr(opponent, destination_zone_name)
    moved_names = [str(item.get("name") or "") for item in destination_zone if isinstance(item, dict)]
    battlefield_names = [str(item.get("name") or "") for item in opponent.battlefield if isinstance(item, dict)]
    missing = [name for name in target_names if name not in moved_names]
    if missing:
        fail("battle_execution", f"{card['name']} did not move legal targets {missing} to {destination}")
    if nonmatching_name not in battlefield_names:
        fail("battle_execution", f"{card['name']} removed illegal target {nonmatching_name}")

    resolution_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "multi_target_resolution"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if resolution_event is None:
        fail("battle_events", f"missing {card['name']} multi_target_resolution event")
    resolved_names = [str(name or "") for name in resolution_event.get("resolved") or []]
    for target_name in target_names:
        if target_name not in resolved_names:
            fail("battle_events", f"{card['name']} missing resolved target {target_name}")
    if int(resolution_event.get("declared") or 0) < len(target_names):
        fail("battle_events", f"{card['name']} declared={resolution_event.get('declared')!r}")
    if expected_source_controller_life_loss > 0:
        expected_life = controller_starting_life - expected_source_controller_life_loss
        if active.life != expected_life:
            fail(
                "battle_execution",
                f"{card['name']} controller_life={active.life}, expected={expected_life}",
            )
        penalty_event = next(
            (
                data
                for event, data in events[before_events:]
                if event == "source_controller_life_loss_on_resolve"
                and data.get("card") == card.get("name")
            ),
            None,
        )
        if penalty_event is None:
            fail("battle_events", f"missing {card['name']} source_controller_life_loss_on_resolve event")
        if int(penalty_event.get("source_controller_life_lost") or 0) != expected_source_controller_life_loss:
            fail(
                "battle_events",
                f"{card['name']} source_controller_life_lost={penalty_event.get('source_controller_life_lost')!r}",
            )

    result = {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "targets": target_names,
        "nonmatching_target": nonmatching_name,
        "destination": destination,
        "moved_names": moved_names,
        "battlefield_names": battlefield_names,
        "resolved_names": resolved_names,
    }
    if expected_source_controller_life_loss > 0:
        result["controller_life_before"] = controller_starting_life
        result["controller_life_after"] = active.life
        result["source_controller_life_lost"] = expected_source_controller_life_loss
    return result


def run_multi_target_damage(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Active"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    targets = [dict(target) for target in scenario.get("targets") or []]
    if len(targets) <= 1:
        fail("battle_execution", f"{card['name']} multi-target damage scenario has {len(targets)} targets")
    nonmatching = dict(
        scenario.get("nonmatching_target")
        or {
            "name": "E2E Illegal Damage Target",
            "type_line": "Land",
            "effect": "land",
            "cmc": 0,
        }
    )
    opponent.battlefield = [nonmatching, *targets]
    before_events = len(events)

    effect_data = battle.get_card_effect(card)
    expected_effect = scenario.get("expected_effect")
    if expected_effect and effect_data.get("effect") != expected_effect:
        fail("battle_execution", f"{card['name']} effect={effect_data.get('effect')!r}")

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 6066)),
    )

    target_names = [str(target.get("name") or "") for target in targets]
    nonmatching_name = str(nonmatching.get("name") or "")
    resolution_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "multi_target_damage_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if resolution_event is None:
        fail("battle_events", f"missing {card['name']} multi_target_damage_resolved event")
    assignments = resolution_event.get("assignments") or []
    damaged_names = [str(item.get("target") or "") for item in assignments if isinstance(item, dict)]
    missing = [name for name in target_names if name not in damaged_names]
    if missing:
        fail("battle_execution", f"{card['name']} did not damage legal targets {missing}")
    if nonmatching_name in damaged_names:
        fail("battle_execution", f"{card['name']} damaged illegal target {nonmatching_name}")
    expected_total = int(scenario.get("expected_total_damage") or 0)
    assigned_total = sum(int(item.get("assigned_amount") or 0) for item in assignments if isinstance(item, dict))
    if expected_total and assigned_total != expected_total:
        fail("battle_execution", f"{card['name']} assigned_total={assigned_total}, expected={expected_total}")
    battlefield_names = [str(item.get("name") or "") for item in opponent.battlefield if isinstance(item, dict)]
    if nonmatching_name not in battlefield_names:
        fail("battle_execution", f"{card['name']} moved illegal target {nonmatching_name}")
    damage_markers = {
        str(item.get("name") or ""): int(item.get("damage_marked_this_turn") or 0)
        for item in opponent.battlefield
        if isinstance(item, dict)
    }
    for name in target_names:
        if damage_markers.get(name, 0) <= 0:
            fail("battle_execution", f"{card['name']} target {name} has no damage marker")
    if damage_markers.get(nonmatching_name, 0) > 0:
        fail("battle_execution", f"{card['name']} illegal target {nonmatching_name} has damage marker")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "targets": target_names,
        "nonmatching_target": nonmatching_name,
        "assigned_total": assigned_total,
        "damaged_names": damaged_names,
        "damage_markers": damage_markers,
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


def _sacrifice_fixture_permanent(name: str, card_type: str, *, multicolored: bool = False) -> dict[str, Any]:
    if card_type == "land":
        return {"name": name, "type_line": "Land", "effect": "land", "cmc": 0}
    if card_type == "enchantment":
        return {"name": name, "type_line": "Enchantment", "effect": "passive", "cmc": 2}
    if card_type == "permanent" and multicolored:
        return {
            "name": name,
            "type_line": "Creature - Advisor",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
            "colors": ["W", "U"],
            "color_identity": ["W", "U"],
            "mana_cost": "{W}{U}",
            "cmc": 2,
        }
    if card_type == "permanent":
        return {"name": name, "type_line": "Artifact", "effect": "passive", "cmc": 1}
    return {
        "name": name,
        "type_line": "Creature - Citizen",
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "cmc": 1,
    }


def run_each_player_sacrifice(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = scenario["card"]
    active = battle.Player(str(scenario.get("player") or "Lorehold"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    sacrifice_count = max(1, int(scenario.get("sacrifice_count") or 1))
    card_types = list(scenario.get("sacrifice_card_types") or ["creature"])
    primary_type = str(card_types[0] if card_types else "creature")
    multicolored = bool(scenario.get("sacrifice_requires_multicolored"))
    expected_per_player = int(scenario.get("expected_sacrificed_per_player") or sacrifice_count)

    active.battlefield = [
        _sacrifice_fixture_permanent(f"Controller Sacrifice {idx + 1}", primary_type, multicolored=multicolored)
        for idx in range(sacrifice_count + 1)
    ]
    opponent.battlefield = [
        _sacrifice_fixture_permanent(f"Opponent Sacrifice {idx + 1}", primary_type, multicolored=multicolored)
        for idx in range(sacrifice_count + 1)
    ]
    decoy_type = "enchantment" if primary_type != "enchantment" else "land"
    active.battlefield.append(_sacrifice_fixture_permanent("Controller Nonmatching Decoy", decoy_type))
    opponent.battlefield.append(_sacrifice_fixture_permanent("Opponent Nonmatching Decoy", decoy_type))
    if multicolored:
        active.battlefield.append(_sacrifice_fixture_permanent("Controller Monocolored Decoy", "creature"))
        opponent.battlefield.append(_sacrifice_fixture_permanent("Opponent Monocolored Decoy", "creature"))

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 6080)),
    )
    event = next(
        (
            data
            for event_name, data in events
            if event_name == "each_player_sacrifice_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} each_player_sacrifice_resolved event")
    expected_total = expected_per_player * 2
    if int(event.get("sacrificed") or 0) != expected_total:
        fail(
            "battle_events",
            f"{card['name']} sacrificed={event.get('sacrificed')}, expected {expected_total}",
        )
    if int(event.get("own_permanents_sacrificed") or 0) != expected_per_player:
        fail("battle_events", f"{card['name']} own sacrifice count mismatch")
    if int(event.get("opponent_permanents_sacrificed") or 0) != expected_per_player:
        fail("battle_events", f"{card['name']} opponent sacrifice count mismatch")
    source_is_permanent = "creature" in str(card.get("type_line") or "").lower()
    active_sacrificed_graveyard = [
        permanent
        for permanent in active.graveyard
        if source_is_permanent
        or not (isinstance(permanent, dict) and permanent.get("name") == card.get("name"))
    ]
    opponent_sacrificed_graveyard = [
        permanent
        for permanent in opponent.graveyard
        if source_is_permanent
        or not (isinstance(permanent, dict) and permanent.get("name") == card.get("name"))
    ]
    if len(active_sacrificed_graveyard) != expected_per_player or len(opponent_sacrificed_graveyard) != expected_per_player:
        fail(
            "battle_execution",
            f"{card['name']} graveyard counts active={len(active_sacrificed_graveyard)} opponent={len(opponent_sacrificed_graveyard)}",
        )
    if multicolored:
        graveyard_names = [
            permanent.get("name", "")
            for permanent in [*active.graveyard, *opponent.graveyard]
            if isinstance(permanent, dict)
        ]
        if any("Monocolored Decoy" in name for name in graveyard_names):
            fail("battle_execution", f"{card['name']} sacrificed a monocolored decoy")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "sacrificed": int(event.get("sacrificed") or 0),
        "sacrifice_count": sacrifice_count,
        "sacrifice_card_types": card_types,
        "sacrifice_requires_multicolored": multicolored,
    }


def run_creature_dies_each_player_sacrifice(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Dies Sacrifice Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    sacrifice_count = max(1, int(scenario.get("sacrifice_count") or 1))
    card_types = list(scenario.get("sacrifice_card_types") or ["creature"])
    primary_type = str(card_types[0] if card_types else "creature")
    multicolored = bool(scenario.get("sacrifice_requires_multicolored"))
    expected_per_player = int(scenario.get("expected_sacrificed_per_player") or sacrifice_count)
    effect_data = battle.get_card_effect(card)
    source_permanent = battle.enrich_card({**card, **effect_data})

    active.battlefield = [source_permanent] + [
        _sacrifice_fixture_permanent(f"Controller Dies Sacrifice {idx + 1}", primary_type, multicolored=multicolored)
        for idx in range(sacrifice_count + 1)
    ]
    opponent.battlefield = [
        _sacrifice_fixture_permanent(f"Opponent Dies Sacrifice {idx + 1}", primary_type, multicolored=multicolored)
        for idx in range(sacrifice_count + 1)
    ]
    decoy_type = "enchantment" if primary_type != "enchantment" else "land"
    active.battlefield.append(_sacrifice_fixture_permanent("Controller Dies Nonmatching Decoy", decoy_type))
    opponent.battlefield.append(_sacrifice_fixture_permanent("Opponent Dies Nonmatching Decoy", decoy_type))
    if multicolored:
        active.battlefield.append(_sacrifice_fixture_permanent("Controller Dies Monocolored Decoy", "creature"))
        opponent.battlefield.append(_sacrifice_fixture_permanent("Opponent Dies Monocolored Decoy", "creature"))

    before_events = len(events)
    destination = battle.move_creature_from_battlefield(
        active,
        source_permanent,
        reason=str(scenario.get("reason") or "package_e2e_destroy"),
        source=dict(scenario.get("source") or {"name": "Package E2E Removal"}),
        all_players=[active, opponent],
    )
    if destination != "graveyard":
        fail("battle_execution", f"{card['name']} source destination={destination!r}")
    if source_permanent not in active.graveyard:
        fail("battle_execution", f"{card['name']} source not moved to controller graveyard")

    event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "each_player_sacrifice_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} dies each_player_sacrifice_resolved event")
    expected_total = expected_per_player * 2
    if int(event.get("sacrificed") or 0) != expected_total:
        fail(
            "battle_events",
            f"{card['name']} dies sacrificed={event.get('sacrificed')}, expected {expected_total}",
        )
    if int(event.get("own_permanents_sacrificed") or 0) != expected_per_player:
        fail("battle_events", f"{card['name']} own dies sacrifice count mismatch")
    if int(event.get("opponent_permanents_sacrificed") or 0) != expected_per_player:
        fail("battle_events", f"{card['name']} opponent dies sacrifice count mismatch")

    active_trigger_sacrificed = [
        permanent
        for permanent in active.graveyard
        if isinstance(permanent, dict) and permanent is not source_permanent
    ]
    opponent_trigger_sacrificed = [
        permanent
        for permanent in opponent.graveyard
        if isinstance(permanent, dict)
    ]
    if len(active_trigger_sacrificed) != expected_per_player or len(opponent_trigger_sacrificed) != expected_per_player:
        fail(
            "battle_execution",
            f"{card['name']} dies graveyard counts active={len(active_trigger_sacrificed)} opponent={len(opponent_trigger_sacrificed)}",
        )
    if multicolored:
        graveyard_names = [
            permanent.get("name", "")
            for permanent in [*active.graveyard, *opponent.graveyard]
            if isinstance(permanent, dict)
        ]
        if any("Monocolored Decoy" in name for name in graveyard_names):
            fail("battle_execution", f"{card['name']} sacrificed monocolored decoy despite multicolored filter")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "source_died": True,
        "sacrificed": int(event.get("sacrificed") or 0),
        "sacrifice_count": sacrifice_count,
        "sacrifice_card_types": card_types,
        "sacrifice_requires_multicolored": multicolored,
    }


def _board_wipe_type_line(card_type: str, scenario: dict[str, Any], *, matching: bool) -> str:
    normalized = str(card_type or "creature").strip().lower()
    excluded_type_values = {
        str(value or "").strip().lower()
        for value in scenario.get("destroy_exclude_card_types") or []
        if str(value or "").strip()
    }
    generic_permanent_type = "Artifact"
    if normalized == "permanent" and matching:
        for candidate_type, candidate_line in (
            ("artifact", "Artifact"),
            ("enchantment", "Enchantment"),
            ("planeswalker", "Planeswalker - Jace"),
            ("battle", "Battle - Siege"),
            ("creature", "Creature - Soldier"),
            ("land", "Land"),
        ):
            if candidate_type not in excluded_type_values:
                generic_permanent_type = candidate_line
                break
    mapping = {
        "artifact": "Artifact",
        "battle": "Battle - Siege",
        "creature": "Creature - Soldier",
        "enchantment": "Enchantment",
        "land": "Land",
        "permanent": generic_permanent_type,
        "planeswalker": "Planeswalker - Jace",
    }
    type_line = mapping.get(normalized, "Creature - Soldier")
    if matching:
        required_subtypes = [
            str(value or "").replace("_", " ").strip().title()
            for value in scenario.get("destroy_required_subtypes") or []
            if str(value or "").strip()
        ]
        if required_subtypes:
            if " - " in type_line:
                base, subtypes = type_line.split(" - ", 1)
                type_line = f"{base} - {subtypes} {' '.join(required_subtypes)}"
            else:
                type_line = f"{type_line} - {' '.join(required_subtypes)}"
    excluded_types = [
        str(value or "").strip().title()
        for value in excluded_type_values
    ]
    if not matching and excluded_types:
        type_line = f"{type_line} {' '.join(excluded_types)}"
    excluded_subtypes = [
        str(value or "").replace("_", " ").strip().title()
        for value in scenario.get("destroy_excluded_subtypes") or []
        if str(value or "").strip()
    ]
    if not matching and excluded_subtypes:
        if " - " in type_line:
            base, subtypes = type_line.split(" - ", 1)
            type_line = f"{base} - {subtypes} {' '.join(excluded_subtypes)}"
        else:
            type_line = f"{type_line} - {' '.join(excluded_subtypes)}"
    return type_line


def _board_wipe_fixture_permanent(
    name: str,
    card_type: str,
    scenario: dict[str, Any],
    *,
    matching: bool,
) -> dict[str, Any]:
    type_line = _board_wipe_type_line(card_type, scenario, matching=matching)
    mana_value_lte = scenario.get("destroy_mana_value_lte")
    if scenario.get("destroy_mana_value_lte_source") == "x_value":
        mana_value_lte = int(scenario.get("x_value") or mana_value_lte or 3)
    cmc = int(mana_value_lte or 3)
    if not matching and mana_value_lte not in (None, ""):
        cmc = int(mana_value_lte) + 1
    if matching and scenario.get("destroy_mana_value_gte") not in (None, ""):
        cmc = int(scenario.get("destroy_mana_value_gte"))
    if not matching and scenario.get("destroy_mana_value_gte") not in (None, ""):
        cmc = max(0, int(scenario.get("destroy_mana_value_gte")) - 1)
    power = int(scenario.get("destroy_power_gte") or scenario.get("destroy_power_lte") or 2)
    toughness = int(scenario.get("destroy_toughness_gte") or scenario.get("destroy_toughness_lte") or 2)
    if not matching and scenario.get("destroy_power_gte") not in (None, ""):
        power = max(0, int(scenario.get("destroy_power_gte")) - 1)
    if not matching and scenario.get("destroy_power_lte") not in (None, ""):
        power = int(scenario.get("destroy_power_lte")) + 1
    if not matching and scenario.get("destroy_toughness_gte") not in (None, ""):
        toughness = max(0, int(scenario.get("destroy_toughness_gte")) - 1)
    if not matching and scenario.get("destroy_toughness_lte") not in (None, ""):
        toughness = int(scenario.get("destroy_toughness_lte")) + 1
    colors = list(scenario.get("destroy_required_colors") or [])
    if not matching and colors:
        colors = []
    excluded_colors = list(scenario.get("destroy_excluded_colors") or [])
    if not matching and excluded_colors:
        colors = excluded_colors[:1]
    color_count_lt = scenario.get("destroy_color_count_lt")
    if color_count_lt not in (None, ""):
        colors = ["W"] if matching else ["W", "U", "B", "R", "G"]
    tapped_state = str(scenario.get("destroy_tapped_state") or "").strip().lower()
    tapped = tapped_state == "tapped"
    if not matching and tapped_state:
        tapped = not tapped
    permanent = {
        "name": name,
        "type_line": type_line,
        "effect": "creature" if "Creature" in type_line else "land" if "Land" in type_line else "permanent",
        "cmc": cmc,
        "power": power,
        "toughness": toughness,
        "colors": colors,
        "tapped": tapped,
    }
    if "Land" in type_line:
        permanent["basic"] = not bool(matching and scenario.get("destroy_nonbasic_lands"))
    if scenario.get("destroy_counter_state") == "none":
        permanent["counters"] = {} if matching else {"+1/+1": 1}
        permanent["plus_one_counters"] = 0 if matching else 1
    combat_state = str(scenario.get("destroy_combat_state") or "").strip().lower()
    if combat_state == "attacking":
        permanent["attacking"] = bool(matching)
    if combat_state == "blocking_or_blocked":
        permanent["blocking"] = bool(matching)
        permanent["blocked"] = False
    if scenario.get("destroy_dealt_damage_to_you_this_turn"):
        permanent["dealt_damage_to_you_this_turn"] = bool(matching)
    if scenario.get("destroy_exclude_commanders"):
        permanent["commander"] = not bool(matching)
    enchanted_state = str(scenario.get("destroy_enchanted_state") or "").strip().lower()
    if enchanted_state == "not_enchanted":
        permanent["enchanted"] = not bool(matching)
        if not matching:
            permanent["enchanted_by"] = "E2E Aura"
    return permanent


def _board_wipe_nonmatching_type(requested_types: list[str]) -> str | None:
    requested = {str(value or "").strip().lower() for value in requested_types}
    for candidate in ("enchantment", "artifact", "land", "planeswalker", "creature"):
        if candidate not in requested and "permanent" not in requested:
            return candidate
    return None


def run_board_wipe(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    if scenario.get("x_value") is not None:
        card["x_value"] = int(scenario.get("x_value") or 0)
        card["_cast_context"] = {"x_value": int(scenario.get("x_value") or 0)}
    active = battle.Player(str(scenario.get("player") or "Active"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    before_events = len(events)
    effect_data = battle.get_card_effect(card)
    if effect_data.get("effect") != "board_wipe":
        fail("battle_execution", f"{card['name']} effect={effect_data.get('effect')!r}")
    destroy_card_types = list(
        scenario.get("destroy_card_types")
        or effect_data.get("destroy_card_types")
        or ["creature"]
    )
    destroy_controller = str(
        scenario.get("destroy_controller")
        or effect_data.get("destroy_controller")
        or "any"
    ).strip().lower()
    scenario_with_effect = {**effect_data, **scenario}
    target_active = destroy_controller not in {"opponent", "opponents", "opponents_control"}
    target_opponent = destroy_controller not in {"self", "you", "controller"}
    expected_destroyed_names: set[str] = set()
    expected_survivor_names: set[str] = set()

    def add_fixture(owner, owner_label: str, targeted: bool) -> None:
        for card_type in destroy_card_types:
            permanent = _board_wipe_fixture_permanent(
                f"{owner_label} Matching {card_type.title()}",
                card_type,
                scenario_with_effect,
                matching=True,
            )
            owner.battlefield.append(permanent)
            if targeted:
                expected_destroyed_names.add(permanent["name"])
            else:
                expected_survivor_names.add(permanent["name"])
        decoy_type = _board_wipe_nonmatching_type(destroy_card_types)
        if decoy_type:
            decoy = _board_wipe_fixture_permanent(
                f"{owner_label} Nonmatching {decoy_type.title()}",
                decoy_type,
                scenario_with_effect,
                matching=True,
            )
            owner.battlefield.append(decoy)
            expected_survivor_names.add(decoy["name"])
        has_extra_filter = any(
            scenario_with_effect.get(field) not in (None, "", [], False)
            for field in (
                "destroy_required_colors",
                "destroy_excluded_colors",
                "destroy_required_subtypes",
                "destroy_excluded_subtypes",
                "destroy_exclude_card_types",
                "destroy_tapped_state",
                "destroy_nonbasic_lands",
                "destroy_mana_value_lte",
                "destroy_mana_value_lte_source",
                "destroy_mana_value_gte",
                "destroy_power_lte",
                "destroy_power_gte",
                "destroy_toughness_lte",
                "destroy_toughness_gte",
                "destroy_counter_state",
                "destroy_combat_state",
                "destroy_color_count_lt",
                "destroy_dealt_damage_to_you_this_turn",
                "destroy_exclude_commanders",
                "destroy_enchanted_state",
            )
        )
        if has_extra_filter:
            filtered_decoy = _board_wipe_fixture_permanent(
                f"{owner_label} Filtered Decoy",
                destroy_card_types[0],
                scenario_with_effect,
                matching=False,
            )
            owner.battlefield.append(filtered_decoy)
            expected_survivor_names.add(filtered_decoy["name"])

    add_fixture(active, "Active", target_active)
    add_fixture(opponent, "Opponent", target_opponent)

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 6066)),
    )

    graveyard_names = {
        str(item.get("name") or "")
        for owner in (active, opponent)
        for item in owner.graveyard
        if isinstance(item, dict)
    }
    battlefield_names = {
        str(item.get("name") or "")
        for owner in (active, opponent)
        for item in owner.battlefield
        if isinstance(item, dict)
    }
    missing_destroyed = expected_destroyed_names - graveyard_names
    wrongly_destroyed = expected_survivor_names & graveyard_names
    if missing_destroyed:
        fail("battle_execution", f"{card['name']} did not destroy {sorted(missing_destroyed)}")
    if wrongly_destroyed:
        fail("battle_execution", f"{card['name']} wrongly destroyed {sorted(wrongly_destroyed)}")
    if not expected_survivor_names.issubset(battlefield_names):
        fail("battle_execution", f"{card['name']} survivor state mismatch")
    wipe_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "board_wipe_resolved" and data.get("card") == card.get("name")
        ),
        None,
    )
    if wipe_event is None:
        fail("battle_events", f"missing {card['name']} board_wipe_resolved event")
    if int(wipe_event.get("destroyed") or 0) != len(expected_destroyed_names):
        fail(
            "battle_events",
            f"{card['name']} destroyed={wipe_event.get('destroyed')}, expected {len(expected_destroyed_names)}",
        )
    return {
        "card_name": card["name"],
        "destroyed": int(wipe_event.get("destroyed") or 0),
        "expected_destroyed": len(expected_destroyed_names),
        "destroy_card_types": wipe_event.get("destroy_card_types") or destroy_card_types,
        "destroy_controller": wipe_event.get("destroy_controller") or destroy_controller,
    }


def run_damage_wipe(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Active"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.life = int(scenario.get("active_life") or 20)
    opponent.life = int(scenario.get("opponent_life") or 20)
    expected_damage = int(scenario.get("expected_damage") or 1)
    expected_scope = str(scenario.get("expected_damage_scope") or "each_creature")
    expected_damage_players = bool(scenario.get("expected_damage_players"))
    active_creature = {
        "name": "E2E Active Small Creature",
        "type_line": "Creature - Fixture",
        "effect": "creature",
        "power": 1,
        "toughness": max(1, expected_damage),
    }
    opponent_creature = {
        "name": "E2E Opponent Small Creature",
        "type_line": "Creature - Fixture",
        "effect": "creature",
        "power": 1,
        "toughness": max(1, expected_damage),
    }
    active.battlefield.append(active_creature)
    opponent.battlefield.append(opponent_creature)
    starting_life = {active.name: active.life, opponent.name: opponent.life}
    before_events = len(events)

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 6076)),
    )

    if expected_damage_players:
        if active.life != starting_life[active.name] - expected_damage:
            fail("battle_execution", f"{card['name']} active life={active.life}")
        if opponent.life != starting_life[opponent.name] - expected_damage:
            fail("battle_execution", f"{card['name']} opponent life={opponent.life}")
    else:
        if active.life != starting_life[active.name] or opponent.life != starting_life[opponent.name]:
            fail("battle_execution", f"{card['name']} damaged players unexpectedly")
    if active.battlefield or opponent.battlefield:
        fail(
            "battle_execution",
            f"{card['name']} left creatures active={active.battlefield} opponent={opponent.battlefield}",
        )
    graveyard_names = {
        str(item.get("name") or "")
        for owner in (active, opponent)
        for item in owner.graveyard
        if isinstance(item, dict)
    }
    if {active_creature["name"], opponent_creature["name"]} - graveyard_names:
        fail("battle_execution", f"{card['name']} missing destroyed creatures in graveyard")
    wipe_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "damage_wipe_resolved" and data.get("card") == card.get("name")
        ),
        None,
    )
    if wipe_event is None:
        fail("battle_events", f"missing {card['name']} damage_wipe_resolved event")
    if wipe_event.get("damage_scope") != expected_scope:
        fail(
            "battle_events",
            f"{card['name']} damage_scope={wipe_event.get('damage_scope')}, expected {expected_scope}",
        )
    if bool(wipe_event.get("damage_players")) != expected_damage_players:
        fail("battle_events", f"{card['name']} damage_players={wipe_event.get('damage_players')}")
    if expected_damage_players and int(wipe_event.get("players_damaged") or 0) != 2:
        fail("battle_events", f"{card['name']} players_damaged={wipe_event.get('players_damaged')}")
    return {
        "card_name": card["name"],
        "damage": expected_damage,
        "damage_scope": wipe_event.get("damage_scope"),
        "damage_players": bool(wipe_event.get("damage_players")),
        "players_damaged": int(wipe_event.get("players_damaged") or 0),
        "creatures_destroyed": int(wipe_event.get("creatures_destroyed") or 0),
    }


def _mass_return_scenario_as_destroy_filter(scenario: dict[str, Any]) -> dict[str, Any]:
    aliases = dict(scenario)
    for field in (
        "card_types",
        "controller",
        "required_colors",
        "excluded_colors",
        "required_subtypes",
        "excluded_subtypes",
        "exclude_card_types",
        "combat_state",
    ):
        return_field = f"return_{field}"
        destroy_field = f"destroy_{field}"
        if return_field in aliases and destroy_field not in aliases:
            aliases[destroy_field] = aliases[return_field]
    return aliases


def run_mass_return_to_hand(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Active"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    before_events = len(events)
    effect_data = battle.get_card_effect(card)
    if effect_data.get("effect") != "mass_return_to_hand":
        fail("battle_execution", f"{card['name']} effect={effect_data.get('effect')!r}")
    return_card_types = list(
        scenario.get("return_card_types")
        or effect_data.get("return_card_types")
        or ["creature"]
    )
    return_controller = str(
        scenario.get("return_controller")
        or effect_data.get("return_controller")
        or "any"
    ).strip().lower()
    scenario_with_effect = _mass_return_scenario_as_destroy_filter({**effect_data, **scenario})
    target_active = return_controller not in {"opponent", "opponents", "opponents_control"}
    target_opponent = return_controller not in {"self", "you", "controller"}
    expected_returned_names: set[str] = set()
    expected_survivor_names: set[str] = set()

    def add_fixture(owner, owner_label: str, targeted: bool) -> None:
        for card_type in return_card_types:
            permanent = _board_wipe_fixture_permanent(
                f"{owner_label} Matching {card_type.title()}",
                card_type,
                scenario_with_effect,
                matching=True,
            )
            owner.battlefield.append(permanent)
            if targeted:
                expected_returned_names.add(permanent["name"])
            else:
                expected_survivor_names.add(permanent["name"])
        decoy_type = _board_wipe_nonmatching_type(return_card_types)
        if decoy_type:
            decoy = _board_wipe_fixture_permanent(
                f"{owner_label} Nonmatching {decoy_type.title()}",
                decoy_type,
                scenario_with_effect,
                matching=True,
            )
            owner.battlefield.append(decoy)
            expected_survivor_names.add(decoy["name"])
        has_extra_filter = any(
            scenario_with_effect.get(field) not in (None, "", [], False)
            for field in (
                "destroy_required_colors",
                "destroy_excluded_colors",
                "destroy_required_subtypes",
                "destroy_excluded_subtypes",
                "destroy_exclude_card_types",
                "destroy_combat_state",
            )
        )
        if has_extra_filter:
            filtered_decoy = _board_wipe_fixture_permanent(
                f"{owner_label} Filtered Decoy",
                return_card_types[0],
                scenario_with_effect,
                matching=False,
            )
            owner.battlefield.append(filtered_decoy)
            expected_survivor_names.add(filtered_decoy["name"])

    add_fixture(active, "Active", target_active)
    add_fixture(opponent, "Opponent", target_opponent)

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 6),
        rng=random.Random(int(scenario.get("seed") or 7070)),
    )

    hand_names = {
        str(item.get("name") or "")
        for owner in (active, opponent)
        for item in owner.hand
        if isinstance(item, dict)
    }
    battlefield_names = {
        str(item.get("name") or "")
        for owner in (active, opponent)
        for item in owner.battlefield
        if isinstance(item, dict)
    }
    missing_returned = expected_returned_names - hand_names
    wrongly_returned = expected_survivor_names & hand_names
    if missing_returned:
        fail("battle_execution", f"{card['name']} did not return {sorted(missing_returned)}")
    if wrongly_returned:
        fail("battle_execution", f"{card['name']} wrongly returned {sorted(wrongly_returned)}")
    if not expected_survivor_names.issubset(battlefield_names):
        fail("battle_execution", f"{card['name']} survivor state mismatch")
    return_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "mass_return_to_hand_resolved" and data.get("card") == card.get("name")
        ),
        None,
    )
    if return_event is None:
        fail("battle_events", f"missing {card['name']} mass_return_to_hand_resolved event")
    if int(return_event.get("returned") or 0) != len(expected_returned_names):
        fail(
            "battle_events",
            f"{card['name']} returned={return_event.get('returned')}, expected {len(expected_returned_names)}",
        )
    return {
        "card_name": card["name"],
        "returned": int(return_event.get("returned") or 0),
        "expected_returned": len(expected_returned_names),
        "return_card_types": return_event.get("return_card_types") or return_card_types,
        "return_controller": return_event.get("return_controller") or return_controller,
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


def run_creature_etb_fixed_mana(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "ETB Mana Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    effect_data = battle.get_card_effect(card)
    expected_condition = str(scenario.get("expected_condition") or "")
    actual_condition = str(effect_data.get("etb_mana_condition") or "")
    if expected_condition != actual_condition:
        fail(
            "battle_execution",
            f"{card['name']} etb_mana_condition={actual_condition!r}, expected {expected_condition!r}",
        )
    expected_symbols = list(scenario.get("expected_produced_mana_symbols") or [])
    actual_symbols = list(effect_data.get("etb_produced_mana_symbols") or [])
    if expected_symbols and actual_symbols != expected_symbols:
        fail(
            "battle_execution",
            f"{card['name']} etb_produced_mana_symbols={actual_symbols!r}, expected {expected_symbols!r}",
        )
    permanent = battle.prepare_entering_permanent(
        battle.enrich_card(
            {
                **card,
                **effect_data,
                "was_cast": bool(scenario.get("was_cast", True)),
                "cast_from_zone": str(scenario.get("cast_from_zone") or "hand"),
            }
        ),
        controller=active,
        all_players=[active, opponent],
        turn=int(scenario.get("turn") or 6),
    )
    active.battlefield.append(permanent)
    before_mana = active.mana_pool.total()
    before_events = len(events)
    expected_mana_added = int(scenario.get("expected_mana_added") or 0)

    battle.resolve_generic_permanent_etb(
        active,
        [opponent],
        permanent,
        effect_data,
        int(scenario.get("turn") or 6),
        random.Random(int(scenario.get("seed") or 6065)),
        all_players=[active, opponent],
    )

    mana_delta = active.mana_pool.total() - before_mana
    if mana_delta != expected_mana_added:
        fail(
            "battle_execution",
            f"{card['name']} ETB mana delta={mana_delta}, expected {expected_mana_added}",
        )
    mana_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "trigger_resolved"
            and data.get("card") == card.get("name")
            and data.get("trigger") == "enters_battlefield"
            and data.get("effect") == "add_mana"
        ),
        None,
    )
    if mana_event is None:
        fail("battle_events", f"missing {card['name']} ETB add_mana trigger_resolved event")
    if int(mana_event.get("mana_added") or 0) != expected_mana_added:
        fail(
            "battle_events",
            f"{card['name']} event mana_added={mana_event.get('mana_added')}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "mana_added": mana_delta,
        "cast_from_zone": scenario.get("cast_from_zone"),
        "validated_condition": expected_condition,
        "produced_mana_symbols": expected_symbols,
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
    if scenario.get("starting_life") is not None:
        active.life = int(scenario["starting_life"])
    active.hand = [
        dict(card)
        for card in (scenario.get("controller_hand") or [])
        if isinstance(card, dict)
    ]
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
    expected_restrictions = sorted(
        str(value)
        for value in (scenario.get("expected_conditional_restrictions") or [])
        if str(value)
    )
    if expected_restrictions:
        actual_restrictions = sorted(
            {
                str(mode.get("restriction") or "")
                for conditional_source in getattr(active, "conditional_mana_sources", []) or []
                if isinstance(conditional_source, dict)
                for mode in conditional_source.get("modes") or []
                if isinstance(mode, dict) and str(mode.get("restriction") or "")
            }
        )
        if actual_restrictions != expected_restrictions:
            fail(
                "battle_execution",
                f"{card['name']} conditional restrictions={actual_restrictions}, "
                f"expected {expected_restrictions}",
            )
    payable_card = scenario.get("expected_restricted_mana_payable_card")
    if isinstance(payable_card, dict):
        if not active.can_pay_card(payable_card):
            fail(
                "battle_execution",
                f"{card['name']} restricted mana could not pay allowed card "
                f"{payable_card.get('name')}",
            )
    blocked_card = scenario.get("expected_restricted_mana_blocked_card")
    if isinstance(blocked_card, dict):
        if active.can_pay_card(blocked_card):
            fail(
                "battle_execution",
                f"{card['name']} restricted mana incorrectly paid blocked card "
                f"{blocked_card.get('name')}",
            )
    expected_life_loss_by_color = {
        str(color): int(value)
        for color, value in dict(
            scenario.get("expected_conditional_life_loss_by_color") or {}
        ).items()
    }
    if expected_life_loss_by_color:
        actual_life_loss_by_color: dict[str, int] = {}
        for conditional_source in getattr(active, "conditional_mana_sources", []) or []:
            if not isinstance(conditional_source, dict):
                continue
            for mode in conditional_source.get("modes") or []:
                if not isinstance(mode, dict):
                    continue
                color = str(mode.get("color") or "")
                if not color:
                    continue
                actual_life_loss_by_color[color] = int(mode.get("life_loss_on_spend") or 0)
        if actual_life_loss_by_color != expected_life_loss_by_color:
            fail(
                "battle_execution",
                f"{card['name']} conditional life-loss modes="
                f"{actual_life_loss_by_color}, expected {expected_life_loss_by_color}",
            )
    expected_life_after = scenario.get("expected_life_after_refresh")
    if expected_life_after is not None and active.life != int(expected_life_after):
        fail(
            "battle_execution",
            f"{card['name']} life after refresh={active.life}, expected {expected_life_after}",
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
    available_after_first_refresh = active.available_mana()
    expected_activation_limit = int(scenario.get("expected_activation_limit_per_turn") or 0)
    if expected_activation_limit:
        before_second_refresh_events = len(events)
        active.refresh_mana_sources(turn=turn)
        second_event = next(
            (
                data
                for replay_event, data in events[before_second_refresh_events:]
                if replay_event == "mana_refreshed" and data.get("player") == active.name
            ),
            None,
        )
        if second_event is None:
            fail("battle_events", f"missing {card['name']} second mana_refreshed event")
        if int(second_event.get("sources") or 0) != 0:
            fail(
                "battle_events",
                f"{card['name']} second same-turn mana sources={second_event.get('sources')}, expected 0",
            )
        skipped = [
            data
            for replay_event, data in events[before_second_refresh_events:]
            if replay_event == "mana_source_activation_skipped"
            and data.get("card") == card.get("name")
            and data.get("reason") == "activation_limit_per_turn"
        ]
        if not skipped:
            fail("battle_events", f"missing {card['name']} activation-limit skip event")
    expected_life_paid = int(scenario.get("expected_life_paid") or 0)
    if expected_life_paid:
        life_event = next(
            (
                data
                for replay_event, data in events[before_events:]
                if replay_event == "mana_source_activation_life_cost_paid"
                and data.get("card") == card.get("name")
            ),
            None,
        )
        if life_event is None:
            fail("battle_events", f"missing {card['name']} mana-source life payment event")
        if int(life_event.get("life_paid") or 0) != expected_life_paid:
            fail(
                "battle_events",
                f"{card['name']} life_paid={life_event.get('life_paid')}, expected {expected_life_paid}",
            )
    expected_discard_count = int(scenario.get("expected_discard_count") or 0)
    if expected_discard_count:
        discard_event = next(
            (
                data
                for replay_event, data in events[before_events:]
                if replay_event == "mana_source_activation_discard_cost_paid"
                and data.get("card") == card.get("name")
            ),
            None,
        )
        if discard_event is None:
            fail("battle_events", f"missing {card['name']} mana-source discard payment event")
        if int(discard_event.get("activation_discard_count") or 0) != expected_discard_count:
            fail(
                "battle_events",
                f"{card['name']} activation_discard_count="
                f"{discard_event.get('activation_discard_count')}, expected {expected_discard_count}",
            )
        expected_discard_target = str(scenario.get("expected_discard_target") or "any_card")
        if str(discard_event.get("activation_discard_target") or "any_card") != expected_discard_target:
            fail(
                "battle_events",
                f"{card['name']} activation_discard_target="
                f"{discard_event.get('activation_discard_target')}, expected {expected_discard_target}",
            )
    expected_activation_life_gain = int(scenario.get("expected_mana_activation_life_gain") or 0)
    if expected_activation_life_gain:
        gain_event = next(
            (
                data
                for replay_event, data in events[before_events:]
                if replay_event == "mana_source_activation_life_gain_resolved"
                and data.get("card") == card.get("name")
            ),
            None,
        )
        if gain_event is None:
            fail("battle_events", f"missing {card['name']} mana-source life gain event")
        if int(gain_event.get("life_gained") or 0) != expected_activation_life_gain:
            fail(
                "battle_events",
                f"{card['name']} life_gained={gain_event.get('life_gained')}, "
                f"expected {expected_activation_life_gain}",
            )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "available_mana": available_after_first_refresh,
        "conditional_mana": conditional_total,
        "tapped": bool(source.get("tapped")),
        "sources": int(event.get("sources") or 0),
        "activation_limit_per_turn": expected_activation_limit,
        "life_paid": expected_life_paid,
        "discarded_count": expected_discard_count,
        "mana_activation_life_gain": expected_activation_life_gain,
        "life_after_refresh": active.life,
        "conditional_life_loss_by_color": expected_life_loss_by_color,
    }


def run_sacrifice_mana_source_activation(
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
            "summoning_sick": False,
            "tapped": False,
            **effect,
            **dict(scenario.get("source_overrides") or {}),
        }
    )
    active = battle.Player(str(scenario.get("player") or "Sacrifice Mana Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    unlock_card = dict(
        scenario.get("unlock_card")
        or {
            "name": "E2E Mana Unlock",
            "type_line": "Creature - Fixture",
            "effect": "creature",
            "cmc": 1,
            "mana_cost": "{G}",
        }
    )
    active.hand.append(unlock_card)
    active.battlefield.append(source)
    sacrifice_target = None
    if scenario.get("sacrifice_target"):
        sacrifice_target = battle.enrich_card(dict(scenario["sacrifice_target"]))
        active.battlefield.append(sacrifice_target)
    tap_cost_targets = [
        battle.enrich_card(dict(item))
        for item in (scenario.get("tap_cost_targets") or [])
        if isinstance(item, dict)
    ]
    if tap_cost_targets:
        active.battlefield.extend(tap_cost_targets)
    counter_cost_targets = [
        battle.enrich_card(dict(item))
        for item in (scenario.get("counter_cost_targets") or [])
        if isinstance(item, dict)
    ]
    if counter_cost_targets:
        active.battlefield.extend(counter_cost_targets)
    add_manifest_mana(active, scenario.get("controller_mana") or {})

    before_events = len(events)
    turn = int(scenario.get("turn") or 7)
    activated = battle.activate_self_sacrifice_mana_sources(
        active,
        [opponent],
        [active, opponent],
        turn=turn,
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    if activated != int(scenario.get("expected_activated") or 1):
        fail("battle_execution", f"{card['name']} sacrifice mana activations={activated}")

    expected_available = int(scenario.get("expected_available_mana_after_activation") or 0)
    if active.available_mana() != expected_available:
        fail(
            "battle_execution",
            f"{card['name']} available mana after sacrifice activation={active.available_mana()}, expected {expected_available}",
        )
    if not active.can_pay_card(unlock_card):
        fail("battle_execution", f"{card['name']} sacrifice mana did not unlock {unlock_card.get('name')}")
    if bool(scenario.get("expect_source_sacrificed")):
        if source in active.battlefield or source not in active.graveyard:
            fail("battle_execution", f"{card['name']} source sacrifice state invalid")
    if bool(scenario.get("expect_target_sacrificed")) and sacrifice_target is not None:
        if sacrifice_target in active.battlefield or sacrifice_target not in active.graveyard:
            fail("battle_execution", f"{card['name']} target sacrifice state invalid")
        if source not in active.battlefield:
            fail("battle_execution", f"{card['name']} source left battlefield during target sacrifice")

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
    expected_event = str(scenario.get("expected_event") or "self_sacrifice_mana_source_activated")
    activation_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == expected_event and data.get("card") == card.get("name")
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} {expected_event} event")
    expected_produced = int(scenario.get("expected_produced") or expected_available)
    if int(activation_event.get("produced") or 0) != expected_produced:
        fail("battle_events", f"{card['name']} produced={activation_event.get('produced')!r}")
    if activation_event.get("unlock_target") != unlock_card.get("name"):
        fail("battle_events", f"{card['name']} unlock_target={activation_event.get('unlock_target')!r}")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "available_mana": active.available_mana(),
        "conditional_mana": conditional_total,
        "event": expected_event,
        "source_sacrificed": source in active.graveyard,
        "target_sacrificed": bool(sacrifice_target is not None and sacrifice_target in active.graveyard),
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
    active.life = int(scenario.get("starting_life") or 40)
    opponent.life = int(scenario.get("opponent_life") or 7)
    active.battlefield = [source]
    tap_cost_targets = [
        battle.enrich_card(dict(item))
        for item in (scenario.get("tap_cost_targets") or [])
        if isinstance(item, dict)
    ]
    if tap_cost_targets:
        active.battlefield.extend(tap_cost_targets)
    counter_cost_targets = [
        battle.enrich_card(dict(item))
        for item in (scenario.get("counter_cost_targets") or [])
        if isinstance(item, dict)
    ]
    if counter_cost_targets:
        active.battlefield.extend(counter_cost_targets)
    target = None
    if isinstance(scenario.get("target"), dict):
        target = battle.enrich_card(dict(scenario["target"]))
        opponent.battlefield = [target]
    active.hand = [dict(card) for card in scenario.get("controller_hand", [])]
    active.library = [
        battle.enrich_card(dict(library_card))
        for library_card in (scenario.get("controller_library") or [])
        if isinstance(library_card, dict)
    ]
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    starting_life = opponent.life
    starting_active_life = active.life
    starting_hand_names = [card.get("name", "?") for card in active.hand if isinstance(card, dict)]
    starting_library_count = len(active.library)
    expected_damage = int(scenario.get("expected_damage") or effect.get("activated_damage_amount") or 0)
    expected_discard_count = int(scenario.get("expected_discard_count") or 0)
    expected_discard_target = str(scenario.get("expected_discard_target") or "any_card")
    expected_life_paid = int(scenario.get("expected_life_paid") or 0)
    expected_exiled_top_library_count = int(scenario.get("expected_exiled_top_library_count") or 0)
    expected_remove_counter_cost_count = int(scenario.get("expected_remove_counter_cost_count") or 0)
    expected_remove_counter_type = str(scenario.get("expected_remove_counter_type") or "+1/+1")
    counter_cost_before = {
        item.get("name"): _counter_value(battle, item, expected_remove_counter_type)
        for item in counter_cost_targets
    }

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
    damage_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "damage_resolved"
            and data.get("card") == card.get("name")
            and (target is None or data.get("target") == target.get("name"))
        ),
        None,
    )
    if damage_event is None:
        fail("battle_events", f"missing {card['name']} damage resolved event")
    if int(damage_event.get("amount") or 0) != expected_damage:
        fail(
            "battle_events",
            f"{card['name']} damage amount={damage_event.get('amount')}, expected {expected_damage}",
        )
    if target is None:
        if opponent.life != starting_life - expected_damage:
            fail(
                "battle_execution",
                f"{card['name']} opponent life={opponent.life}, expected {starting_life - expected_damage}",
            )
        if damage_event.get("target_player") != opponent.name:
            fail("battle_events", f"{card['name']} target_player={damage_event.get('target_player')!r}")
    else:
        if damage_event.get("target") != target.get("name"):
            fail("battle_events", f"{card['name']} target={damage_event.get('target')!r}, expected {target.get('name')!r}")
        if int(target.get("damage_marked_this_turn") or 0) < expected_damage and target in opponent.battlefield:
            fail(
                "battle_execution",
                f"{card['name']} target damage={target.get('damage_marked_this_turn')}, expected at least {expected_damage}",
            )
    if active.life != starting_active_life - expected_life_paid:
        fail(
            "battle_execution",
            f"{card['name']} controller life={active.life}, expected {starting_active_life - expected_life_paid}",
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
    expected_tap_cost_count = int(scenario.get("expected_tap_cost_count") or len(tap_cost_targets) or 0)
    if expected_tap_cost_count:
        if len(tap_cost_targets) < expected_tap_cost_count:
            fail("battle_execution", f"{card['name']} expected tap cost target was not configured")
        for tapped_target in tap_cost_targets[:expected_tap_cost_count]:
            if not bool(tapped_target.get("tapped")):
                fail("battle_execution", f"{card['name']} tap cost target was not tapped")
        expected_tapped_names = [item.get("name") for item in tap_cost_targets[:expected_tap_cost_count]]
        event_tapped_names = list(activation_event.get("tapped_cost_targets") or [])
        if expected_tapped_names and not set(expected_tapped_names).issubset(set(event_tapped_names)):
            fail(
                "battle_events",
                f"{card['name']} tapped_cost_targets={event_tapped_names!r}, expected {expected_tapped_names!r}",
            )
    if activation_event.get("discarded_count") != expected_discard_count:
        fail(
            "battle_events",
            f"{card['name']} discarded_count={activation_event.get('discarded_count')}, expected {expected_discard_count}",
        )
    if int(activation_event.get("life_paid") or 0) != expected_life_paid:
        fail(
            "battle_events",
            f"{card['name']} life_paid={activation_event.get('life_paid')}, expected {expected_life_paid}",
        )
    if int(activation_event.get("exiled_top_library_count") or 0) != expected_exiled_top_library_count:
        fail(
            "battle_events",
            f"{card['name']} exiled_top_library_count={activation_event.get('exiled_top_library_count')}, expected {expected_exiled_top_library_count}",
        )
    if expected_exiled_top_library_count and len(active.library) != starting_library_count - expected_exiled_top_library_count:
        fail(
            "battle_execution",
            f"{card['name']} library size={len(active.library)}, expected {starting_library_count - expected_exiled_top_library_count}",
        )
    if expected_remove_counter_cost_count:
        if not counter_cost_targets:
            fail("battle_execution", f"{card['name']} expected counter cost target was not configured")
        expected_counter_names = [item.get("name") for item in counter_cost_targets]
        event_counter_names = list(activation_event.get("removed_counter_cost_targets") or [])
        if not set(expected_counter_names).intersection(set(event_counter_names)):
            fail(
                "battle_events",
                f"{card['name']} removed_counter_cost_targets={event_counter_names!r}, expected one of {expected_counter_names!r}",
            )
        if str(activation_event.get("removed_counter_cost_type") or "") != expected_remove_counter_type:
            fail(
                "battle_events",
                f"{card['name']} removed_counter_cost_type={activation_event.get('removed_counter_cost_type')!r}, expected {expected_remove_counter_type!r}",
            )
        if int(activation_event.get("removed_counter_cost_count") or 0) != expected_remove_counter_cost_count:
            fail(
                "battle_events",
                f"{card['name']} removed_counter_cost_count={activation_event.get('removed_counter_cost_count')}, expected {expected_remove_counter_cost_count}",
            )
        removed_targets = [
            item
            for item in counter_cost_targets
            if item.get("name") in set(event_counter_names)
        ]
        if not removed_targets:
            fail("battle_execution", f"{card['name']} counter cost target not found after activation")
        removed_target = removed_targets[0]
        before = counter_cost_before.get(removed_target.get("name"), 0)
        after = _counter_value(battle, removed_target, expected_remove_counter_type)
        if before - after != expected_remove_counter_cost_count:
            fail(
                "battle_execution",
                f"{card['name']} removed {before - after} {expected_remove_counter_type} counters, expected {expected_remove_counter_cost_count}",
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
        "life_paid": expected_life_paid,
        "controller_life": active.life,
        "discarded_count": expected_discard_count,
        "discard_target": expected_discard_target if expected_discard_count else None,
        "exiled_top_library_count": expected_exiled_top_library_count,
        "removed_counter_cost_count": expected_remove_counter_cost_count,
        "removed_counter_cost_type": expected_remove_counter_type if expected_remove_counter_cost_count else None,
        "target": target.get("name") if target else damage_event.get("target_player"),
        "target_result": damage_event.get("result"),
        "target_destination": damage_event.get("destination"),
        "tapped_cost_targets": [item.get("name") for item in tap_cost_targets if bool(item.get("tapped"))],
        "counter_cost_targets": [item.get("name") for item in counter_cost_targets],
    }


def run_simple_activated_draw(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    permanent_type = str(effect.get("permanent_type") or "artifact")
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
    active = battle.Player(str(scenario.get("player") or "Activated Draw Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Activated Draw Opponent"), None, [])
    active.life = int(scenario.get("starting_life") or 40)
    active.hand = [
        battle.enrich_card(dict(hand_card))
        for hand_card in (scenario.get("controller_hand") or [])
        if isinstance(hand_card, dict)
    ]
    active.library = [
        battle.enrich_card(dict(library_card))
        for library_card in (scenario.get("controller_library") or [])
        if isinstance(library_card, dict)
    ]
    source_zone = str(
        scenario.get("source_zone")
        or effect.get("activation_zone")
        or ("graveyard" if effect.get("activation_requires_exile_source_from_graveyard") else "battlefield")
    ).lower()
    active.battlefield = [] if source_zone == "graveyard" else [source]
    active.graveyard = [source] if source_zone == "graveyard" else []
    sacrifice_target = None
    if scenario.get("sacrifice_target"):
        sacrifice_target = battle.enrich_card(dict(scenario["sacrifice_target"]))
        active.battlefield.append(sacrifice_target)
    tap_cost_targets = [
        battle.enrich_card(dict(item))
        for item in (scenario.get("tap_cost_targets") or [])
        if isinstance(item, dict)
    ]
    if tap_cost_targets:
        active.battlefield.extend(tap_cost_targets)
    counter_cost_targets = [
        battle.enrich_card(dict(item))
        for item in (scenario.get("counter_cost_targets") or [])
        if isinstance(item, dict)
    ]
    if counter_cost_targets:
        active.battlefield.extend(counter_cost_targets)
    add_manifest_mana(active, scenario.get("controller_mana") or {})

    starting_hand_names = [card.get("name", "?") for card in active.hand if isinstance(card, dict)]
    starting_hand_count = len(active.hand)
    starting_library_count = len(active.library)
    starting_life = active.life
    expected_draw_count = int(scenario.get("expected_draw_count") or effect.get("activated_draw_count") or 1)
    expected_discard_count = int(scenario.get("expected_discard_count") or 0)
    expected_life_paid = int(scenario.get("expected_life_paid") or 0)
    expected_tapped_source = bool(scenario.get("expected_tapped_source", effect.get("activation_requires_tap", False)))
    expected_tap_cost_count = int(scenario.get("expected_tap_cost_count") or 0)
    expected_remove_counter_cost_count = int(scenario.get("expected_remove_counter_cost_count") or 0)
    expected_remove_counter_type = str(scenario.get("expected_remove_counter_type") or "+1/+1")
    counter_cost_before = {
        item.get("name"): _counter_value(battle, item, expected_remove_counter_type)
        for item in counter_cost_targets
    }
    expected_sacrificed_source = bool(effect.get("activation_requires_sacrifice"))
    expected_exiled_source = bool(
        scenario.get("expected_exiled_source_from_graveyard")
        or effect.get("activation_requires_exile_source_from_graveyard")
    )
    all_players = [active, opponent]
    before_events = len(events)

    activated = battle.activate_utility_artifacts(
        active,
        [opponent],
        all_players,
        turn=int(scenario.get("turn") or 6151),
        rng=random.Random(int(scenario.get("seed") or 6151)),
        phase=str(scenario.get("phase") or "postcombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated draw activation failed")
    if len(active.library) != starting_library_count - expected_draw_count:
        fail(
            "battle_execution",
            f"{card['name']} library={len(active.library)}, expected {starting_library_count - expected_draw_count}",
        )
    expected_hand_count = starting_hand_count - expected_discard_count + expected_draw_count
    if len(active.hand) != expected_hand_count:
        fail(
            "battle_execution",
            f"{card['name']} hand={len(active.hand)}, expected {expected_hand_count}",
        )
    if bool(source.get("tapped")) != expected_tapped_source:
        fail(
            "battle_execution",
            f"{card['name']} source tapped={bool(source.get('tapped'))}, expected {expected_tapped_source}",
        )
    if expected_tap_cost_count:
        tapped_targets = [item for item in tap_cost_targets if bool(item.get("tapped"))]
        if len(tapped_targets) != expected_tap_cost_count:
            fail(
                "battle_execution",
                f"{card['name']} tapped tap-cost targets={len(tapped_targets)}, expected {expected_tap_cost_count}",
            )
    if expected_life_paid and active.life != starting_life - expected_life_paid:
        fail(
            "battle_execution",
            f"{card['name']} life={active.life}, expected {starting_life - expected_life_paid}",
        )
    if expected_exiled_source:
        if source in active.graveyard:
            fail("battle_execution", f"{card['name']} source remained in graveyard after activation")
        if source not in getattr(active, "exile", []):
            fail("battle_execution", f"{card['name']} source was not exiled from graveyard")
    elif expected_sacrificed_source:
        if source in active.battlefield or source not in active.graveyard:
            fail("battle_execution", f"{card['name']} source sacrifice zone mismatch")
    elif source_zone == "graveyard":
        if source not in active.graveyard:
            fail("battle_execution", f"{card['name']} source left graveyard unexpectedly")
    elif source not in active.battlefield:
        fail("battle_execution", f"{card['name']} source left battlefield unexpectedly")
    if bool(scenario.get("expect_target_sacrificed")):
        if sacrifice_target is None:
            fail("battle_execution", f"{card['name']} expected sacrifice target was not configured")
        if sacrifice_target in active.battlefield:
            fail("battle_execution", f"{card['name']} sacrifice target remained on battlefield")
        if not battle.is_token_permanent(sacrifice_target) and sacrifice_target not in active.graveyard:
            fail("battle_execution", f"{card['name']} sacrifice target zone mismatch")

    expected_activation_kind = (
        "graveyard_self_exile_draw"
        if expected_exiled_source
        else "self_sacrifice_draw"
        if expected_sacrificed_source
        else "simple_activated_draw"
    )
    activation_event = next(
        (
            data
            for event, data in reversed(events[before_events:])
            if event == "utility_artifact_activated"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == expected_activation_kind
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} {expected_activation_kind} event")
    if int(activation_event.get("cards_drawn") or 0) != expected_draw_count:
        fail(
            "battle_events",
            f"{card['name']} cards_drawn={activation_event.get('cards_drawn')}, expected {expected_draw_count}",
        )
    if expected_tap_cost_count:
        expected_tap_names = [item.get("name") for item in tap_cost_targets]
        event_tap_names = list(activation_event.get("tap_cost_targets") or activation_event.get("tapped_cost_targets") or [])
        if len(event_tap_names) != expected_tap_cost_count or not set(expected_tap_names).intersection(event_tap_names):
            fail(
                "battle_events",
                f"{card['name']} tap_cost_targets={event_tap_names!r}, expected {expected_tap_names!r}",
            )
    if expected_remove_counter_cost_count:
        if not counter_cost_targets:
            fail("battle_execution", f"{card['name']} expected counter cost target was not configured")
        expected_counter_names = [item.get("name") for item in counter_cost_targets]
        event_counter_names = list(activation_event.get("removed_counter_cost_targets") or [])
        if not set(expected_counter_names).intersection(set(event_counter_names)):
            fail(
                "battle_events",
                f"{card['name']} removed_counter_cost_targets={event_counter_names!r}, expected one of {expected_counter_names!r}",
            )
        if str(activation_event.get("removed_counter_cost_type") or "") != expected_remove_counter_type:
            fail(
                "battle_events",
                f"{card['name']} removed_counter_cost_type={activation_event.get('removed_counter_cost_type')!r}, expected {expected_remove_counter_type!r}",
            )
        if int(activation_event.get("removed_counter_cost_count") or 0) != expected_remove_counter_cost_count:
            fail(
                "battle_events",
                f"{card['name']} removed_counter_cost_count={activation_event.get('removed_counter_cost_count')}, expected {expected_remove_counter_cost_count}",
            )
        removed_targets = [
            item
            for item in counter_cost_targets
            if item.get("name") in set(event_counter_names)
        ]
        if not removed_targets:
            fail("battle_execution", f"{card['name']} counter cost target not found after activation")
        removed_target = removed_targets[0]
        before = counter_cost_before.get(removed_target.get("name"), 0)
        after = _counter_value(battle, removed_target, expected_remove_counter_type)
        if before - after != expected_remove_counter_cost_count:
            fail(
                "battle_execution",
                f"{card['name']} removed {before - after} {expected_remove_counter_type} counters, expected {expected_remove_counter_cost_count}",
            )
    if expected_exiled_source:
        if not bool(activation_event.get("exiled_source_from_graveyard")):
            fail("battle_events", f"{card['name']} replay did not mark source exile from graveyard")
        if str(activation_event.get("source_zone") or "") != "graveyard":
            fail("battle_events", f"{card['name']} replay source_zone={activation_event.get('source_zone')!r}")
    if not expected_sacrificed_source:
        if int(activation_event.get("discarded_count") or 0) != expected_discard_count:
            fail(
                "battle_events",
                f"{card['name']} discarded_count={activation_event.get('discarded_count')}, expected {expected_discard_count}",
            )
        if int(activation_event.get("life_paid") or 0) != expected_life_paid:
            fail(
                "battle_events",
                f"{card['name']} life_paid={activation_event.get('life_paid')}, expected {expected_life_paid}",
            )
        if expected_discard_count:
            discarded = list(activation_event.get("discarded") or [])
            if len(discarded) != expected_discard_count:
                fail("battle_events", f"{card['name']} discarded={discarded!r}")
            if not set(discarded).issubset(set(starting_hand_names)):
                fail("battle_events", f"{card['name']} discarded cards not from starting hand: {discarded!r}")
        if bool(scenario.get("expect_target_sacrificed")):
            sacrificed = str(activation_event.get("sacrificed") or "")
            if sacrificed != str((sacrifice_target or {}).get("name") or ""):
                fail(
                    "battle_events",
                    f"{card['name']} sacrificed={sacrificed!r}, expected {(sacrifice_target or {}).get('name')!r}",
                )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "cards_drawn": expected_draw_count,
        "discarded_count": expected_discard_count,
        "life_paid": expected_life_paid,
        "source_tapped": bool(source.get("tapped")),
        "tapped_cost_targets": [item.get("name") for item in tap_cost_targets if bool(item.get("tapped"))],
        "removed_counter_cost_count": expected_remove_counter_cost_count,
        "removed_counter_cost_type": expected_remove_counter_type if expected_remove_counter_cost_count else None,
        "sacrificed_source": expected_sacrificed_source,
        "exiled_source_from_graveyard": expected_exiled_source,
        "source_zone": source_zone,
        "target_sacrificed": bool(sacrifice_target is not None and sacrifice_target not in active.battlefield),
    }


def run_simple_activated_draw_discard(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    permanent_type = str(effect.get("permanent_type") or "creature")
    default_type_line = {
        "creature": "Creature - Citizen",
        "artifact": "Artifact",
        "enchantment": "Enchantment",
    }.get(permanent_type, "Creature")
    source = battle.enrich_card(
        {
            **card,
            "type_line": default_type_line,
            "summoning_sick": False,
            **effect,
            **dict(scenario.get("source_overrides") or {}),
        }
    )
    active = battle.Player(str(scenario.get("player") or "Activated Draw Discard Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Activated Draw Discard Opponent"), None, [])
    active.life = int(scenario.get("starting_life") or 40)
    active.hand = [
        battle.enrich_card(dict(hand_card))
        for hand_card in (scenario.get("controller_hand") or [])
        if isinstance(hand_card, dict)
    ]
    active.library = [
        battle.enrich_card(dict(library_card))
        for library_card in (scenario.get("controller_library") or [])
        if isinstance(library_card, dict)
    ]
    source_zone = str(
        scenario.get("source_zone")
        or effect.get("activation_zone")
        or ("graveyard" if effect.get("activation_requires_exile_source_from_graveyard") else "battlefield")
    ).lower()
    active.battlefield = [] if source_zone == "graveyard" else [source]
    active.graveyard = [source] if source_zone == "graveyard" else []
    add_manifest_mana(active, scenario.get("controller_mana") or {})

    starting_hand_count = len(active.hand)
    starting_library_count = len(active.library)
    starting_life = active.life
    expected_draw_count = int(
        scenario.get("expected_draw_count")
        or effect.get("activated_draw_count")
        or effect.get("draw_count")
        or 1
    )
    expected_discard_count = int(
        scenario.get("expected_discard_count")
        or effect.get("activated_discard_count")
        or effect.get("discard_count")
        or 1
    )
    expected_life_paid = int(scenario.get("expected_life_paid") or 0)
    expected_tapped_source = bool(scenario.get("expected_tapped_source", effect.get("activation_requires_tap", False)))
    expected_sacrificed_source = bool(effect.get("activation_requires_sacrifice"))
    expected_exiled_source = bool(
        scenario.get("expected_exiled_source_from_graveyard")
        or effect.get("activation_requires_exile_source_from_graveyard")
    )
    before_events = len(events)
    all_players = [active, opponent]

    activated = battle.activate_utility_artifacts(
        active,
        [opponent],
        all_players,
        turn=int(scenario.get("turn") or 6152),
        rng=random.Random(int(scenario.get("seed") or 6152)),
        phase=str(scenario.get("phase") or "postcombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated draw-discard activation failed")
    if len(active.library) != starting_library_count - expected_draw_count:
        fail(
            "battle_execution",
            f"{card['name']} library={len(active.library)}, expected {starting_library_count - expected_draw_count}",
        )
    expected_hand_count = starting_hand_count + expected_draw_count - expected_discard_count
    if len(active.hand) != expected_hand_count:
        fail(
            "battle_execution",
            f"{card['name']} hand={len(active.hand)}, expected {expected_hand_count}",
        )
    if bool(source.get("tapped")) != expected_tapped_source:
        fail(
            "battle_execution",
            f"{card['name']} source tapped={bool(source.get('tapped'))}, expected {expected_tapped_source}",
        )
    if expected_life_paid and active.life != starting_life - expected_life_paid:
        fail(
            "battle_execution",
            f"{card['name']} life={active.life}, expected {starting_life - expected_life_paid}",
        )
    if expected_exiled_source:
        if source in active.graveyard:
            fail("battle_execution", f"{card['name']} source remained in graveyard after activation")
        if source not in getattr(active, "exile", []):
            fail("battle_execution", f"{card['name']} source was not exiled from graveyard")
    elif expected_sacrificed_source:
        if source in active.battlefield or source not in active.graveyard:
            fail("battle_execution", f"{card['name']} source sacrifice zone mismatch")
    elif source_zone == "graveyard":
        if source not in active.graveyard:
            fail("battle_execution", f"{card['name']} source left graveyard unexpectedly")
    elif source not in active.battlefield:
        fail("battle_execution", f"{card['name']} source left battlefield unexpectedly")

    expected_activation_kind = (
        "graveyard_self_exile_draw_discard"
        if expected_exiled_source
        else "simple_activated_draw_discard"
    )
    activation_event = next(
        (
            data
            for event, data in reversed(events[before_events:])
            if event == "utility_artifact_activated"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == expected_activation_kind
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} {expected_activation_kind} event")
    if int(activation_event.get("cards_drawn") or 0) != expected_draw_count:
        fail(
            "battle_events",
            f"{card['name']} cards_drawn={activation_event.get('cards_drawn')}, expected {expected_draw_count}",
        )
    if int(activation_event.get("cards_discarded") or 0) != expected_discard_count:
        fail(
            "battle_events",
            f"{card['name']} cards_discarded={activation_event.get('cards_discarded')}, expected {expected_discard_count}",
        )
    if expected_exiled_source:
        if not bool(activation_event.get("exiled_source_from_graveyard")):
            fail("battle_events", f"{card['name']} replay did not mark source exile from graveyard")
        if str(activation_event.get("source_zone") or "") != "graveyard":
            fail("battle_events", f"{card['name']} replay source_zone={activation_event.get('source_zone')!r}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "cards_drawn": expected_draw_count,
        "cards_discarded": expected_discard_count,
        "life_paid": expected_life_paid,
        "source_tapped": bool(source.get("tapped")),
        "source_zone": source_zone,
        "exiled_source_from_graveyard": expected_exiled_source,
        "sacrificed_source": expected_sacrificed_source,
    }


def run_tap_target_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Tap Spell Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Tap Spell Opponent"), None, [])
    targets = [
        battle.enrich_card(dict(target))
        for target in (scenario.get("targets") or [scenario.get("target") or {}])
        if target
    ]
    nonmatching = scenario.get("nonmatching_target")
    opponent.battlefield = []
    if nonmatching:
        opponent.battlefield.append(battle.enrich_card(dict(nonmatching)))
    opponent.battlefield.extend(targets)
    expected_count = int(scenario.get("expected_target_count") or len(targets) or 1)
    effect_data = dict(battle.get_card_effect(card) or {})
    if scenario.get("x_value") is not None:
        effect_data["x_value"] = int(scenario.get("x_value") or expected_count)
    before_events = len(events)
    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6074)),
        effect_data_override=effect_data,
    )
    tapped_names = [
        str(target.get("name") or "")
        for target in targets
        if target.get("tapped")
    ]
    if len(tapped_names) != expected_count:
        fail(
            "battle_execution",
            f"{card['name']} tapped {len(tapped_names)} targets, expected {expected_count}",
        )
    if nonmatching:
        nonmatching_name = str(nonmatching.get("name") or "")
        still_untapped = [
            permanent
            for permanent in opponent.battlefield
            if str(permanent.get("name") or "") == nonmatching_name and not permanent.get("tapped")
        ]
        if not still_untapped:
            fail("battle_execution", f"{card['name']} tapped illegal target {nonmatching_name}")
    resolved_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "tap_target_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} tap target spell resolved event")
    if int(resolved_event.get("target_tapped_count") or 0) != expected_count:
        fail(
            "battle_events",
            f"{card['name']} event target_tapped_count={resolved_event.get('target_tapped_count')}, expected {expected_count}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "targets_tapped": tapped_names,
        "target_tapped_count": len(tapped_names),
    }


def run_stat_modifier_until_eot_untap_target(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Boost Untap Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Boost Untap Opponent"), None, [])
    targets = [
        battle.enrich_card(dict(target))
        for target in (scenario.get("targets") or [scenario.get("target") or {}])
        if target
    ]
    if not targets:
        fail("battle_execution", f"{card['name']} boost+untap scenario has no legal targets")
    nonmatching = scenario.get("nonmatching_target")
    active.battlefield = []
    if nonmatching:
        active.battlefield.append(battle.enrich_card(dict(nonmatching)))
    active.battlefield.extend(targets)
    expected_count = int(scenario.get("expected_target_count") or len(targets) or 1)
    effect = battle.get_card_effect(card)
    before_events = len(events)
    before_stats = {
        str(target.get("name") or ""): (
            int(target.get("power") or 0),
            int(target.get("toughness") or 0),
        )
        for target in targets
    }
    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card({**card, **effect}),
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6075)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    power_delta = int(scenario.get("expected_power_delta") or effect.get("power_delta") or 0)
    toughness_delta = int(scenario.get("expected_toughness_delta") or effect.get("toughness_delta") or 0)
    expected_keywords = [
        str(keyword or "").strip().lower().replace(" ", "_")
        for keyword in (scenario.get("expected_keywords") or effect.get("granted_keywords_until_eot") or [])
        if str(keyword or "").strip()
    ]
    affected_names = []
    for target in targets:
        name = str(target.get("name") or "")
        before_power, before_toughness = before_stats[name]
        if bool(target.get("tapped")):
            fail("battle_execution", f"{card['name']} left target {name} tapped")
        if int(target.get("power") or 0) != before_power + power_delta:
            fail("battle_execution", f"{card['name']} target {name} power={target.get('power')!r}")
        if int(target.get("toughness") or 0) != before_toughness + toughness_delta:
            fail("battle_execution", f"{card['name']} target {name} toughness={target.get('toughness')!r}")
        for keyword in expected_keywords:
            if not battle.card_has_keyword(target, keyword):
                fail("battle_execution", f"{card['name']} target {name} missing keyword {keyword}")
        affected_names.append(name)
    if len(affected_names) != expected_count:
        fail(
            "battle_execution",
            f"{card['name']} affected {len(affected_names)} targets, expected {expected_count}",
        )
    if nonmatching:
        nonmatching_name = str(nonmatching.get("name") or "")
        illegal = next(
            (
                permanent
                for permanent in active.battlefield
                if str(permanent.get("name") or "") == nonmatching_name
            ),
            None,
        )
        if illegal is None:
            fail("battle_execution", f"{card['name']} removed illegal target {nonmatching_name}")
        if not illegal.get("tapped"):
            fail("battle_execution", f"{card['name']} untapped illegal target {nonmatching_name}")
    resolved_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "stat_modifier_until_eot_untap_target_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} boost+untap resolved event")
    if int(resolved_event.get("target_count") or 0) != expected_count:
        fail(
            "battle_events",
            f"{card['name']} event target_count={resolved_event.get('target_count')}, expected {expected_count}",
        )
    if int(resolved_event.get("targets_untapped_count") or 0) != expected_count:
        fail(
            "battle_events",
            f"{card['name']} event targets_untapped_count={resolved_event.get('targets_untapped_count')}, expected {expected_count}",
        )
    if list(resolved_event.get("granted_keywords_until_eot") or []) != expected_keywords:
        fail(
            "battle_events",
            f"{card['name']} event keywords={resolved_event.get('granted_keywords_until_eot')!r}, expected {expected_keywords!r}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "targets": affected_names,
        "target_count": len(affected_names),
        "targets_untapped_count": int(resolved_event.get("targets_untapped_count") or 0),
        "granted_keywords": expected_keywords,
    }


def run_gain_control_untap_haste_until_eot(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Temporary Control Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Temporary Control Opponent"), None, [])
    target = battle.enrich_card(dict(scenario.get("target") or {}))
    if not target:
        fail("battle_execution", f"{card['name']} temporary-control scenario has no legal target")
    target.setdefault("controller", opponent.name)
    target["tapped"] = bool(target.get("tapped", True))
    nonmatching = scenario.get("nonmatching_target")
    active.battlefield = []
    opponent.battlefield = [target]
    if nonmatching:
        illegal = battle.enrich_card(dict(nonmatching))
        illegal.setdefault("controller", opponent.name)
        opponent.battlefield.append(illegal)
    effect = battle.get_card_effect(card)
    before_events = len(events)
    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card({**card, **effect}),
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6076)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    if target in opponent.battlefield:
        fail("battle_execution", f"{card['name']} left controlled target under opponent")
    if target not in active.battlefield:
        fail("battle_execution", f"{card['name']} did not move target to active battlefield")
    if bool(target.get("tapped")):
        fail("battle_execution", f"{card['name']} left stolen target tapped")
    if not battle.card_has_keyword(target, "haste"):
        fail("battle_execution", f"{card['name']} did not grant haste")
    if target.get("controller") != active.name:
        fail("battle_execution", f"{card['name']} controller={target.get('controller')!r}")
    resolved_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "gain_control_untap_haste_until_eot_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} temporary-control resolved event")
    if resolved_event.get("result") != "control_gained_until_eot":
        fail("battle_events", f"{card['name']} result={resolved_event.get('result')!r}")
    if resolved_event.get("target") != target.get("name"):
        fail("battle_events", f"{card['name']} event target={resolved_event.get('target')!r}")

    battle.clear_until_eot(active)
    if target in active.battlefield:
        fail("battle_execution", f"{card['name']} did not return target at cleanup")
    if target not in opponent.battlefield:
        fail("battle_execution", f"{card['name']} target missing from original battlefield after cleanup")
    if battle.card_has_keyword(target, "haste"):
        fail("battle_execution", f"{card['name']} haste persisted after cleanup")
    if target.get("controller") != opponent.name:
        fail("battle_execution", f"{card['name']} cleanup controller={target.get('controller')!r}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "original_controller": opponent.name,
        "new_controller": active.name,
        "control_returned": True,
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
    target_fixture = dict(scenario.get("target") or {})
    target = battle.enrich_card(
        {
            "name": str(scenario.get("target_name") or f"E2E Creature Target for {card['name']}"),
            "type_line": "Creature - Warrior",
            "effect": "creature",
            "power": int(scenario.get("target_power") or 3),
            "toughness": int(scenario.get("target_toughness") or 3),
            "cmc": int(scenario.get("target_cmc") or 3),
            "tapped": False,
            **target_fixture,
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


def _counter_value(battle, target: dict[str, Any], counter_type: str) -> int:
    if counter_type == "+1/+1":
        return int(target.get("plus_one_counters") or 0)
    if counter_type == "-1/-1":
        return int(target.get("minus_one_counters") or 0)
    return int(battle.get_named_counter_count(target, counter_type) or 0)


def run_add_counters_target_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Counter Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Counter Opponent"), None, [])
    raw_targets = list(scenario.get("targets") or [])
    if not raw_targets and scenario.get("target"):
        raw_targets = [scenario["target"]]
    targets = [battle.enrich_card(dict(target)) for target in raw_targets]
    if not targets:
        fail("battle_execution", f"{card['name']} add-counters scenario has no legal target")
    nonmatching = scenario.get("nonmatching_target")
    active.battlefield = list(targets)
    if nonmatching:
        active.battlefield.append(battle.enrich_card(dict(nonmatching)))
    effect = battle.get_card_effect(card)
    expected_target_count = int(
        scenario.get("expected_target_count")
        or effect.get("target_count_max")
        or effect.get("target_count")
        or 1
    )
    expected_counter_type = str(
        scenario.get("expected_counter_type")
        or effect.get("counter_type")
        or "+1/+1"
    )
    expected_counter_count = int(
        scenario.get("expected_counter_count")
        or effect.get("counter_count")
        or effect.get("count")
        or 1
    )
    selected_targets = targets[:expected_target_count]
    before = {target.get("name"): _counter_value(battle, target, expected_counter_type) for target in selected_targets}
    before_events = len(events)
    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card({**card, **effect}),
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6077)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    for target in selected_targets:
        target_name = target.get("name")
        after = _counter_value(battle, target, expected_counter_type)
        if after - before[target_name] != expected_counter_count:
            fail(
                "battle_execution",
                f"{card['name']} expected {expected_counter_count} {expected_counter_type} counters on {target_name}, got {after - before[target_name]}",
            )
    resolved_events = [
        data
        for event, data in events[before_events:]
        if event == "add_counters_resolved" and data.get("card") == card.get("name")
    ]
    if len(resolved_events) != expected_target_count:
        fail(
            "battle_events",
            f"{card['name']} expected {expected_target_count} add-counters events, got {len(resolved_events)}",
        )
    for data in resolved_events:
        if int(data.get("counters_added") or 0) != expected_counter_count:
            fail(
                "battle_events",
                f"{card['name']} event counters_added={data.get('counters_added')}, expected {expected_counter_count}",
            )
        if int(data.get("selected_target_count") or 0) != expected_target_count:
            fail(
                "battle_events",
                f"{card['name']} selected_target_count={data.get('selected_target_count')}, expected {expected_target_count}",
            )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target_count": expected_target_count,
        "targets": [target.get("name") for target in selected_targets],
        "counter_type": expected_counter_type,
        "counters_added_each": expected_counter_count,
    }


def run_add_counters_untap_target_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Counter Untap Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Counter Untap Opponent"), None, [])
    raw_targets = list(scenario.get("targets") or [])
    if not raw_targets and scenario.get("target"):
        raw_targets = [scenario["target"]]
    targets = [battle.enrich_card(dict(target)) for target in raw_targets]
    if not targets:
        fail("battle_execution", f"{card['name']} counter+untap scenario has no legal target")
    for target in targets:
        target["tapped"] = bool(target.get("tapped", True))
    nonmatching = scenario.get("nonmatching_target")
    active.battlefield = list(targets)
    if nonmatching:
        active.battlefield.append(battle.enrich_card(dict(nonmatching)))
    effect = battle.get_card_effect(card)
    expected_target_count = int(
        scenario.get("expected_target_count")
        or effect.get("target_count_max")
        or effect.get("target_count")
        or 1
    )
    expected_counter_type = str(
        scenario.get("expected_counter_type")
        or effect.get("counter_type")
        or "+1/+1"
    )
    expected_counter_count = int(
        scenario.get("expected_counter_count")
        or effect.get("counter_count")
        or effect.get("count")
        or 1
    )
    selected_targets = targets[:expected_target_count]
    before = {target.get("name"): _counter_value(battle, target, expected_counter_type) for target in selected_targets}
    before_events = len(events)
    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card({**card, **effect}),
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6077)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    for target in selected_targets:
        target_name = target.get("name")
        after = _counter_value(battle, target, expected_counter_type)
        if after - before[target_name] != expected_counter_count:
            fail(
                "battle_execution",
                f"{card['name']} expected {expected_counter_count} {expected_counter_type} counters on {target_name}, got {after - before[target_name]}",
            )
        if bool(target.get("tapped")):
            fail("battle_execution", f"{card['name']} left target {target_name} tapped")
    resolved_events = [
        data
        for event, data in events[before_events:]
        if event == "add_counters_resolved" and data.get("card") == card.get("name")
    ]
    if len(resolved_events) != expected_target_count:
        fail(
            "battle_events",
            f"{card['name']} expected {expected_target_count} counter+untap events, got {len(resolved_events)}",
        )
    for data in resolved_events:
        if not data.get("target_untapped"):
            fail("battle_events", f"{card['name']} event did not mark target untapped")
        if int(data.get("counters_added") or 0) != expected_counter_count:
            fail(
                "battle_events",
                f"{card['name']} event counters_added={data.get('counters_added')}, expected {expected_counter_count}",
            )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target_count": expected_target_count,
        "targets": [target.get("name") for target in selected_targets],
        "counter_type": expected_counter_type,
        "counters_added_each": expected_counter_count,
        "targets_untapped_count": len(selected_targets),
    }


def run_simple_activated_untap_target(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    permanent_type = str(effect.get("effect") or "permanent")
    default_type_line = {
        "creature": "Creature - Druid",
        "artifact": "Artifact",
        "enchantment": "Enchantment",
    }.get(permanent_type, "Artifact")
    source = battle.enrich_card(
        {
            **card,
            "type_line": default_type_line,
            "summoning_sick": False,
            "tapped": False,
            **effect,
            **dict(scenario.get("source_overrides") or {}),
        }
    )
    active = battle.Player(str(scenario.get("player") or "Untap Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Untap Opponent"), None, [])
    target_fixtures = list(scenario.get("targets") or [])
    if not target_fixtures:
        target_fixtures = [
            {
                "name": str(scenario.get("target_name") or f"E2E Untap Target for {card['name']}"),
                "type_line": "Creature - Druid",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "tapped": True,
            }
        ]
    targets = []
    for index, fixture in enumerate(target_fixtures, start=1):
        target = battle.enrich_card(
            {
                "name": fixture.get("name") or f"E2E Untap Target {index} for {card['name']}",
                "type_line": "Creature - Druid",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "cmc": 2,
                "tapped": True,
                **dict(fixture),
            }
        )
        target["tapped"] = True
        targets.append(target)
    nonmatching_fixture = dict(scenario.get("nonmatching_target") or {})
    nonmatching = battle.enrich_card(
        {
            "name": nonmatching_fixture.get("name") or f"E2E Illegal Untap Target for {card['name']}",
            "type_line": "Creature - Rogue",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
            "cmc": 1,
            "tapped": True,
            **nonmatching_fixture,
        }
    )
    nonmatching["tapped"] = True
    active.battlefield = [source, *targets]
    opponent.battlefield = [nonmatching]
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    expected_tapped_source = bool(scenario.get("expected_tapped_source", effect.get("activation_requires_tap", False)))
    expected_count = int(scenario.get("expected_target_count") or effect.get("target_count") or len(targets) or 1)

    if not battle.can_activate_generic_untap_target_permanent(active, source, [opponent]):
        fail("battle_execution", f"{card['name']} simple activated untap target cannot activate")
    activated = battle.activate_generic_untap_target_permanent(
        active,
        [opponent],
        source,
        turn=int(scenario.get("turn") or 6723),
        rng=random.Random(int(scenario.get("seed") or 6723)),
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated untap target activation failed")
    untapped_count = sum(1 for target in targets if not bool(target.get("tapped")))
    if untapped_count != expected_count:
        fail(
            "battle_execution",
            f"{card['name']} untapped {untapped_count} targets, expected {expected_count}",
        )
    if not bool(nonmatching.get("tapped")):
        fail("battle_execution", f"{card['name']} untapped illegal/nonpreferred target")
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
            and data.get("activation_kind") == "simple_activated_untap_target"
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} simple activated untap target event")
    resolved_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "untap_target_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} untap target resolved event")
    if int(resolved_event.get("target_untapped_count") or 0) != expected_count:
        fail(
            "battle_events",
            f"{card['name']} event target_untapped_count={resolved_event.get('target_untapped_count')}, expected {expected_count}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "targets_untapped": untapped_count,
        "source_tapped": bool(source.get("tapped")),
    }


def run_simple_activated_add_counters_target(
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
    target_fixture = dict(scenario.get("target") or {})
    target = battle.enrich_card(
        {
            "name": str(scenario.get("target_name") or f"E2E Counter Target for {card['name']}"),
            "type_line": "Creature - Warrior",
            "effect": "creature",
            "power": int(scenario.get("target_power") or 3),
            "toughness": int(scenario.get("target_toughness") or 3),
            "cmc": int(scenario.get("target_cmc") or 3),
            "tapped": False,
            **target_fixture,
        }
    )
    expected_counter_type = str(scenario.get("expected_counter_type") or effect.get("counter_type") or "+1/+1")
    sacrifice_targets = [
        battle.enrich_card(dict(card))
        for card in (scenario.get("sacrifice_targets") or [])
        if isinstance(card, dict)
    ]
    if expected_counter_type == "-1/-1":
        active.battlefield = [source, *sacrifice_targets]
        opponent.battlefield = [target]
    else:
        active.battlefield = [source, target, *sacrifice_targets]
        opponent.battlefield = []
    active.hand = [
        battle.enrich_card(dict(card))
        for card in (scenario.get("controller_hand") or [])
        if isinstance(card, dict)
    ]
    active.life = int(scenario.get("starting_life") or active.life)
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    expected_tapped_source = bool(scenario.get("expected_tapped_source", effect.get("activation_requires_tap", False)))
    expected_sacrificed_source = bool(
        scenario.get("expected_sacrificed_source", effect.get("activation_requires_sacrifice", False))
    )
    expected_counter_count = int(scenario.get("expected_counter_count") or effect.get("counter_count") or 1)
    expected_discard_count = int(
        scenario.get("expected_discard_count", effect.get("activation_discard_count") or 0) or 0
    )
    expected_life_paid = int(
        scenario.get("expected_life_paid", effect.get("activation_life_cost") or 0) or 0
    )
    expected_sacrifice_count = int(
        scenario.get(
            "expected_sacrifice_count",
            (effect.get("activation_sacrifice_cost") or {}).get("count")
            if isinstance(effect.get("activation_sacrifice_cost"), dict)
            else 0,
        )
        or 0
    )
    life_before = active.life
    before = (
        int(target.get("plus_one_counters") or 0)
        if expected_counter_type == "+1/+1"
        else int(target.get("minus_one_counters") or 0)
    )

    if not battle.can_activate_generic_add_counters_target_permanent(active, source, [opponent]):
        fail("battle_execution", f"{card['name']} simple activated add counters target cannot activate")
    activated = battle.activate_generic_add_counters_target_permanent(
        active,
        [opponent],
        source,
        turn=int(scenario.get("turn") or 6133),
        rng=random.Random(int(scenario.get("seed") or 6133)),
        phase=str(scenario.get("phase") or "postcombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated add counters target activation failed")
    after = (
        int(target.get("plus_one_counters") or 0)
        if expected_counter_type == "+1/+1"
        else int(target.get("minus_one_counters") or 0)
    )
    if after - before != expected_counter_count:
        fail(
            "battle_execution",
            f"{card['name']} expected {expected_counter_count} {expected_counter_type} counters, got {after - before}",
        )
    if bool(source.get("tapped")) != expected_tapped_source:
        fail(
            "battle_execution",
            f"{card['name']} source tapped={source.get('tapped')} expected {expected_tapped_source}",
        )
    activation_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "activated_ability"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == "simple_activated_add_counters_target"
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} simple activated add counters event")
    if bool(activation_event.get("sacrificed_source")) != expected_sacrificed_source:
        fail(
            "battle_events",
            f"{card['name']} sacrificed_source={activation_event.get('sacrificed_source')} expected {expected_sacrificed_source}",
        )
    if expected_sacrificed_source and source in active.battlefield:
        fail("battle_execution", f"{card['name']} expected source to leave battlefield")
    if int(activation_event.get("discarded_count") or 0) != expected_discard_count:
        fail(
            "battle_events",
            f"{card['name']} discarded_count={activation_event.get('discarded_count')} expected {expected_discard_count}",
        )
    if int(activation_event.get("life_paid") or activation_event.get("activation_life_cost") or 0) != expected_life_paid:
        fail(
            "battle_events",
            f"{card['name']} life_paid={activation_event.get('life_paid')} expected {expected_life_paid}",
        )
    sacrificed_cost_targets = activation_event.get("sacrificed_cost_targets") or []
    if len(sacrificed_cost_targets) != expected_sacrifice_count:
        fail(
            "battle_events",
            f"{card['name']} sacrificed_cost_targets={sacrificed_cost_targets} expected {expected_sacrifice_count}",
        )
    if active.life != life_before - expected_life_paid:
        fail("battle_execution", f"{card['name']} life={active.life} expected {life_before - expected_life_paid}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "counter_type": expected_counter_type,
        "counters_added": after - before,
        "source_tapped": bool(source.get("tapped")),
        "source_sacrificed": expected_sacrificed_source,
        "discarded_count": expected_discard_count,
        "life_paid": expected_life_paid,
        "sacrifice_cost_count": expected_sacrifice_count,
    }


def run_simple_activated_add_counters_self(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    source = battle.enrich_card(
        {
            **card,
            "type_line": str(card.get("type_line") or "Creature - Vampire"),
            "effect": str(effect.get("effect") or "creature"),
            "power": int(card.get("power") or 2),
            "toughness": int(card.get("toughness") or 2),
            "summoning_sick": False,
            **effect,
            **dict(scenario.get("source_overrides") or {}),
        }
    )
    active = battle.Player(str(scenario.get("player") or "Activated Controller"), None, [])
    sacrifice_targets = [
        battle.enrich_card(dict(card))
        for card in (scenario.get("sacrifice_targets") or [])
        if isinstance(card, dict)
    ]
    active.battlefield = [source, *sacrifice_targets]
    active.hand = [
        battle.enrich_card(dict(card))
        for card in (scenario.get("controller_hand") or [])
        if isinstance(card, dict)
    ]
    active.life = int(scenario.get("starting_life") or active.life)
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    expected_tapped_source = bool(scenario.get("expected_tapped_source", effect.get("activation_requires_tap", False)))
    expected_counter_type = str(scenario.get("expected_counter_type") or effect.get("counter_type") or "+1/+1")
    expected_counter_count = int(scenario.get("expected_counter_count") or effect.get("counter_count") or 1)
    expected_discard_count = int(
        scenario.get("expected_discard_count", effect.get("activation_discard_count") or 0) or 0
    )
    expected_life_paid = int(
        scenario.get("expected_life_paid", effect.get("activation_life_cost") or 0) or 0
    )
    expected_sacrifice_count = int(
        scenario.get(
            "expected_sacrifice_count",
            (effect.get("activation_sacrifice_cost") or {}).get("count")
            if isinstance(effect.get("activation_sacrifice_cost"), dict)
            else 0,
        )
        or 0
    )
    life_before = active.life
    before = (
        int(source.get("plus_one_counters") or 0)
        if expected_counter_type == "+1/+1"
        else int(source.get("minus_one_counters") or 0)
        if expected_counter_type == "-1/-1"
        else battle.get_named_counter_count(source, expected_counter_type)
    )

    if not battle.can_activate_generic_add_counters_self_permanent(active, source):
        fail("battle_execution", f"{card['name']} simple activated self add counters cannot activate")
    activated = battle.activate_generic_add_counters_self_permanent(
        active,
        source,
        turn=int(scenario.get("turn") or 6134),
        rng=random.Random(int(scenario.get("seed") or 6134)),
        phase=str(scenario.get("phase") or "postcombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated self add counters activation failed")
    after = (
        int(source.get("plus_one_counters") or 0)
        if expected_counter_type == "+1/+1"
        else int(source.get("minus_one_counters") or 0)
        if expected_counter_type == "-1/-1"
        else battle.get_named_counter_count(source, expected_counter_type)
    )
    if after - before != expected_counter_count:
        fail(
            "battle_execution",
            f"{card['name']} expected {expected_counter_count} {expected_counter_type} counters, got {after - before}",
        )
    if source not in active.battlefield:
        fail("battle_execution", f"{card['name']} source unexpectedly left battlefield")
    if bool(source.get("tapped")) != expected_tapped_source:
        fail(
            "battle_execution",
            f"{card['name']} source tapped={source.get('tapped')} expected {expected_tapped_source}",
        )
    activation_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "activated_ability"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == "simple_activated_add_counters_self"
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} simple activated self add counters event")
    if int(activation_event.get("discarded_count") or 0) != expected_discard_count:
        fail(
            "battle_events",
            f"{card['name']} discarded_count={activation_event.get('discarded_count')} expected {expected_discard_count}",
        )
    if int(activation_event.get("life_paid") or activation_event.get("activation_life_cost") or 0) != expected_life_paid:
        fail(
            "battle_events",
            f"{card['name']} life_paid={activation_event.get('life_paid')} expected {expected_life_paid}",
        )
    sacrificed_cost_targets = activation_event.get("sacrificed_cost_targets") or []
    if len(sacrificed_cost_targets) != expected_sacrifice_count:
        fail(
            "battle_events",
            f"{card['name']} sacrificed_cost_targets={sacrificed_cost_targets} expected {expected_sacrifice_count}",
        )
    if active.life != life_before - expected_life_paid:
        fail("battle_execution", f"{card['name']} life={active.life} expected {life_before - expected_life_paid}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "counter_type": expected_counter_type,
        "counters_added": after - before,
        "source_tapped": bool(source.get("tapped")),
        "discarded_count": expected_discard_count,
        "life_paid": expected_life_paid,
        "sacrifice_cost_count": expected_sacrifice_count,
    }


def run_simple_activated_destroy(
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
    target = battle.enrich_card(dict(scenario.get("target") or {
        "name": f"E2E Artifact Target for {card['name']}",
        "type_line": "Artifact",
        "effect": "artifact",
        "cmc": 2,
    }))
    active = battle.Player(str(scenario.get("player") or "Activated Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Activated Opponent"), None, [])
    active.battlefield = [source]
    tap_cost_targets = [
        battle.enrich_card(dict(item))
        for item in (scenario.get("tap_cost_targets") or [])
        if isinstance(item, dict)
    ]
    if tap_cost_targets:
        active.battlefield.extend(tap_cost_targets)
    controller_hand = [
        battle.enrich_card(dict(item))
        for item in (scenario.get("controller_hand") or [])
        if isinstance(item, dict)
    ]
    active.hand = list(controller_hand)
    sacrifice_targets = []
    sacrifice_target = None
    if isinstance(scenario.get("sacrifice_targets"), list):
        for item in scenario.get("sacrifice_targets") or []:
            if isinstance(item, dict):
                sacrifice_targets.append(battle.enrich_card(dict(item)))
    elif scenario.get("sacrifice_target"):
        sacrifice_target = battle.enrich_card(dict(scenario["sacrifice_target"]))
        sacrifice_targets.append(sacrifice_target)
    if sacrifice_targets:
        sacrifice_target = sacrifice_targets[0]
        active.battlefield.extend(sacrifice_targets)
    opponent.battlefield = [target]
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    all_players = [active, opponent]
    expected_destination = str(scenario.get("expected_destination") or "graveyard").lower()
    expected_tapped_source = bool(scenario.get("expected_tapped_source", effect.get("activation_requires_tap", False)))
    expected_sacrificed_source = bool(
        scenario.get("expected_sacrificed_source", effect.get("activation_requires_sacrifice", False))
    )

    if not battle.can_activate_generic_destroy_permanent(active, source, [opponent]):
        fail("battle_execution", f"{card['name']} simple activated destroy cannot activate")
    activated = battle.activate_generic_destroy_permanent(
        active,
        [opponent],
        all_players,
        source,
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6074)),
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated destroy activation failed")
    if target in opponent.battlefield:
        fail("battle_execution", f"{card['name']} target remained on battlefield")
    expected_zone = opponent.exile if expected_destination == "exile" else opponent.graveyard
    if target not in expected_zone:
        token_ceased = (
            expected_destination == "graveyard"
            and bool(target.get("token") or target.get("is_token") or str(target.get("tag") or "").lower() == "token")
            and any(
                event == "token_ceased_to_exist"
                and data.get("token") == target.get("name")
                and str(data.get("zone") or "").lower() == expected_destination
                for event, data in events
            )
        )
        if not token_ceased:
            fail(
                "battle_execution",
                f"{card['name']} target not in expected {expected_destination}: {target.get('name')}",
            )
    if bool(source.get("tapped")) != expected_tapped_source:
        fail(
            "battle_execution",
            f"{card['name']} source tapped={bool(source.get('tapped'))}, expected {expected_tapped_source}",
        )
    if expected_sacrificed_source:
        if source in active.battlefield or source not in active.graveyard:
            fail("battle_execution", f"{card['name']} source sacrifice zone mismatch")
    elif source not in active.battlefield:
        fail("battle_execution", f"{card['name']} source left battlefield unexpectedly")
    if bool(scenario.get("expect_target_sacrificed")):
        expected_sacrifice_count = int(
            scenario.get("expected_sacrifice_count") or len(sacrifice_targets) or 1
        )
        if len(sacrifice_targets) < expected_sacrifice_count:
            fail("battle_execution", f"{card['name']} expected sacrifice target was not configured")
        for sacrificed_target in sacrifice_targets[:expected_sacrifice_count]:
            if sacrificed_target in active.battlefield or sacrificed_target not in active.graveyard:
                fail("battle_execution", f"{card['name']} sacrifice target zone mismatch")
    activation_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "activated_ability"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == "simple_activated_destroy"
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} simple activated destroy event")
    if bool(activation_event.get("sacrificed_source")) != expected_sacrificed_source:
        fail(
            "battle_events",
            f"{card['name']} sacrificed_source={activation_event.get('sacrificed_source')!r}, expected {expected_sacrificed_source}",
        )
    expected_tap_cost_count = int(scenario.get("expected_tap_cost_count") or len(tap_cost_targets) or 0)
    if expected_tap_cost_count:
        if len(tap_cost_targets) < expected_tap_cost_count:
            fail("battle_execution", f"{card['name']} expected tap cost target was not configured")
        for tapped_target in tap_cost_targets[:expected_tap_cost_count]:
            if not bool(tapped_target.get("tapped")):
                fail("battle_execution", f"{card['name']} tap cost target was not tapped")
        expected_tapped_names = [item.get("name") for item in tap_cost_targets[:expected_tap_cost_count]]
        event_tapped_names = list(activation_event.get("tapped_cost_targets") or [])
        if expected_tapped_names and not set(expected_tapped_names).issubset(set(event_tapped_names)):
            fail(
                "battle_events",
                f"{card['name']} tapped_cost_targets={event_tapped_names!r}, expected {expected_tapped_names!r}",
            )
    if bool(scenario.get("expect_target_sacrificed")):
        expected_sacrificed_names = [item.get("name") for item in sacrifice_targets if isinstance(item, dict)]
        event_sacrificed_names = list(activation_event.get("sacrificed_targets") or [])
        if expected_sacrificed_names and not set(expected_sacrificed_names).issubset(set(event_sacrificed_names)):
            fail(
                "battle_events",
                f"{card['name']} sacrificed_targets={event_sacrificed_names!r}, expected {expected_sacrificed_names!r}",
            )
    expected_discard_count = int(
        scenario.get("expected_discard_count", effect.get("activation_discard_count") or 0) or 0
    )
    if int(activation_event.get("discarded_count") or 0) != expected_discard_count:
        fail(
            "battle_events",
            f"{card['name']} discarded_count={activation_event.get('discarded_count')!r}, expected {expected_discard_count}",
        )
    if expected_discard_count:
        expected_discard_target = str(
            scenario.get("expected_discard_target") or effect.get("activation_discard_target") or "any_card"
        )
        if str(activation_event.get("discard_target") or "") != expected_discard_target:
            fail(
                "battle_events",
                f"{card['name']} discard_target={activation_event.get('discard_target')!r}, expected {expected_discard_target!r}",
            )
        graveyard_names = {item.get("name") for item in active.graveyard if isinstance(item, dict)}
        discarded_names = set(activation_event.get("discarded") or [])
        if len(discarded_names) != expected_discard_count or not discarded_names.issubset(graveyard_names):
            fail(
                "battle_execution",
                f"{card['name']} discarded cards not found in graveyard: {sorted(discarded_names)}",
            )
    resolved_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "removal_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == target.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} removal resolved event")
    if str(resolved_event.get("destination") or "").lower() != expected_destination:
        fail(
            "battle_events",
            f"{card['name']} destination={resolved_event.get('destination')!r}, expected {expected_destination!r}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "destination": expected_destination,
        "source_tapped": bool(source.get("tapped")),
        "sacrificed_source": expected_sacrificed_source,
        "discarded_count": expected_discard_count,
        "target_sacrificed": bool(sacrifice_targets and all(item in active.graveyard for item in sacrifice_targets)),
        "sacrificed_targets": [item.get("name") for item in sacrifice_targets if isinstance(item, dict)],
        "tapped_cost_targets": [item.get("name") for item in tap_cost_targets if bool(item.get("tapped"))],
    }


def run_simple_activated_target_keyword(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    permanent_type = str(effect.get("effect") or "creature")
    default_type_line = {
        "creature": "Creature - Soldier",
        "artifact": "Artifact",
        "enchantment": "Enchantment",
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
    target = battle.enrich_card(dict(scenario["target"]))
    active = battle.Player(str(scenario.get("player") or "Activated Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Activated Opponent"), None, [])
    active.battlefield = [source]
    target_controller = str(effect.get("target_controller") or scenario.get("target_controller") or "self").lower()
    if target_controller in {"opponent", "opponents"}:
        opponent.battlefield = [target]
    else:
        active.battlefield.append(target)
    sacrifice_target = None
    if scenario.get("sacrifice_target"):
        sacrifice_target = battle.enrich_card(dict(scenario["sacrifice_target"]))
        active.battlefield.append(sacrifice_target)
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    expected_keywords = [
        str(keyword or "").strip().lower().replace(" ", "_")
        for keyword in (scenario.get("expected_keywords") or effect.get("granted_keywords_until_eot") or [])
        if str(keyword or "").strip()
    ]
    expected_tapped_source = bool(scenario.get("expected_tapped_source", effect.get("activation_requires_tap", False)))
    expected_sacrificed_source = bool(
        scenario.get("expected_sacrificed_source", effect.get("activation_requires_sacrifice", False))
    )
    all_players = [active, opponent]

    if not battle.can_activate_generic_target_keyword_permanent(active, [opponent], source):
        fail("battle_execution", f"{card['name']} simple activated target keyword cannot activate")
    activated = battle.activate_generic_target_keyword_permanent(
        active,
        [opponent],
        all_players,
        source,
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6075)),
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated target keyword activation failed")
    for keyword in expected_keywords:
        if not battle.card_has_keyword(target, keyword):
            fail("battle_execution", f"{card['name']} target missing keyword {keyword!r}")
    if bool(source.get("tapped")) != expected_tapped_source:
        fail(
            "battle_execution",
            f"{card['name']} source tapped={bool(source.get('tapped'))}, expected {expected_tapped_source}",
        )
    if expected_sacrificed_source:
        if source in active.battlefield or source not in active.graveyard:
            fail("battle_execution", f"{card['name']} source sacrifice zone mismatch")
    elif source not in active.battlefield:
        fail("battle_execution", f"{card['name']} source left battlefield unexpectedly")
    if bool(scenario.get("expect_target_sacrificed")):
        if sacrifice_target is None:
            fail("battle_execution", f"{card['name']} expected sacrifice target was not configured")
        if sacrifice_target in active.battlefield or sacrifice_target not in active.graveyard:
            fail("battle_execution", f"{card['name']} sacrifice target zone mismatch")
        if target not in active.battlefield and target_controller not in {"opponent", "opponents"}:
            fail("battle_execution", f"{card['name']} effect target was sacrificed")
    activation_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "activated_ability"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == "simple_activated_target_keyword"
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} simple activated target keyword event")
    if bool(activation_event.get("sacrificed_source")) != expected_sacrificed_source:
        fail(
            "battle_events",
            f"{card['name']} sacrificed_source={activation_event.get('sacrificed_source')!r}",
        )
    resolved_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "stat_modifier_until_eot_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == target.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} target keyword resolved event")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "keywords": expected_keywords,
        "source_tapped": bool(source.get("tapped")),
        "sacrificed_source": expected_sacrificed_source,
        "target_sacrificed": bool(sacrifice_target is not None and sacrifice_target in active.graveyard),
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


def run_simple_activated_regenerate_source(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    source = battle.enrich_card(
        {
            **card,
            "type_line": "Creature - Troll",
            "effect": "creature",
            "power": int(scenario.get("source_power") or 2),
            "toughness": int(scenario.get("source_toughness") or 2),
            "summoning_sick": False,
            **effect,
            **dict(scenario.get("source_overrides") or {}),
        }
    )
    active = battle.Player(str(scenario.get("player") or "Activated Controller"), None, [])
    active.life = int(scenario.get("starting_life") or 40)
    active.hand = [
        battle.enrich_card(dict(hand_card))
        for hand_card in (scenario.get("controller_hand") or [])
        if isinstance(hand_card, dict)
    ]
    active.battlefield = [source]
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    starting_hand_names = [card.get("name", "?") for card in active.hand if isinstance(card, dict)]
    starting_life = active.life
    expected_tapped_source = bool(scenario.get("expected_tapped_source", effect.get("activation_requires_tap", False)))
    expected_shields = int(scenario.get("expected_regeneration_shields") or 1)
    expected_discard_count = int(
        scenario.get("expected_discard_count", effect.get("activation_discard_count") or 0) or 0
    )
    expected_discard_target = str(
        scenario.get("expected_discard_target") or effect.get("activation_discard_target") or "any_card"
    )
    expected_life_paid = int(
        scenario.get("expected_life_paid", effect.get("activation_life_cost") or 0) or 0
    )

    if not battle.can_activate_generic_regenerate_source_permanent(active, source):
        fail("battle_execution", f"{card['name']} simple activated regenerate source cannot activate")
    activated = battle.activate_generic_regenerate_source_permanent(
        active,
        [active],
        source,
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6073)),
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated regenerate source activation failed")
    if int(source.get("regeneration_shields") or 0) != expected_shields:
        fail(
            "battle_execution",
            f"{card['name']} regeneration_shields={source.get('regeneration_shields')!r}",
        )
    if bool(source.get("tapped")) != expected_tapped_source:
        fail(
            "battle_execution",
            f"{card['name']} source tapped={bool(source.get('tapped'))}, expected {expected_tapped_source}",
        )
    destination = battle.move_creature_from_battlefield(
        active,
        source,
        reason="destroy",
        source={"name": "E2E Destroy Effect"},
        all_players=[active],
    )
    if destination != "battlefield":
        fail("battle_execution", f"{card['name']} regeneration destination={destination!r}")
    if source not in active.battlefield or source in active.graveyard:
        fail("battle_execution", f"{card['name']} was moved despite regeneration")
    if not source.get("tapped"):
        fail("battle_execution", f"{card['name']} was not tapped by regeneration replacement")
    if int(source.get("regeneration_shields") or 0) != expected_shields - 1:
        fail(
            "battle_execution",
            f"{card['name']} remaining regeneration_shields={source.get('regeneration_shields')!r}",
        )
    activation_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "activated_ability"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == "simple_activated_regenerate_source"
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} simple activated regenerate source event")
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
    if active.life != starting_life - expected_life_paid:
        fail(
            "battle_execution",
            f"{card['name']} life={active.life}, expected {starting_life - expected_life_paid}",
        )
    if expected_discard_count:
        discarded = list(activation_event.get("discarded") or [])
        if len(discarded) != expected_discard_count:
            fail("battle_events", f"{card['name']} discarded={discarded!r}")
        if activation_event.get("activation_discard_target") != expected_discard_target:
            fail(
                "battle_events",
                f"{card['name']} activation_discard_target={activation_event.get('activation_discard_target')!r}",
            )
        if not set(discarded).issubset(set(starting_hand_names)):
            fail("battle_events", f"{card['name']} discarded cards not from starting hand: {discarded!r}")
    shield_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "regeneration_shield_used" and data.get("card") == card.get("name")
        ),
        None,
    )
    if shield_event is None:
        fail("battle_events", f"missing {card['name']} regeneration shield event")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "destination": destination,
        "source_tapped": bool(source.get("tapped")),
        "regeneration_shields_after": int(source.get("regeneration_shields") or 0),
        "discarded_count": expected_discard_count,
        "life_paid": expected_life_paid,
    }


def run_simple_activated_regenerate_target(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    source = battle.enrich_card(
        {
            **card,
            "type_line": card.get("type_line") or "Artifact",
            "effect": card.get("effect") or effect.get("effect") or "artifact",
            "summoning_sick": False,
            **effect,
            **dict(scenario.get("source_overrides") or {}),
        }
    )
    target_card = dict(scenario.get("target") or {})
    target = battle.enrich_card(
        {
            "name": target_card.get("name") or "E2E Protected Creature",
            "type_line": target_card.get("type_line") or "Creature - Bear",
            "effect": "creature",
            "power": int(target_card.get("power") or 2),
            "toughness": int(target_card.get("toughness") or 2),
            "summoning_sick": False,
            **target_card,
        }
    )
    active = battle.Player(str(scenario.get("player") or "Activated Controller"), None, [])
    active.life = int(scenario.get("starting_life") or 40)
    active.hand = [
        battle.enrich_card(dict(hand_card))
        for hand_card in (scenario.get("controller_hand") or [])
        if isinstance(hand_card, dict)
    ]
    active.battlefield = [source, target]
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    starting_hand_names = [card.get("name", "?") for card in active.hand if isinstance(card, dict)]
    starting_life = active.life
    expected_tapped_source = bool(scenario.get("expected_tapped_source", effect.get("activation_requires_tap", False)))
    expected_shields = int(scenario.get("expected_regeneration_shields") or 1)
    expected_discard_count = int(
        scenario.get("expected_discard_count", effect.get("activation_discard_count") or 0) or 0
    )
    expected_discard_target = str(
        scenario.get("expected_discard_target") or effect.get("activation_discard_target") or "any_card"
    )
    expected_life_paid = int(
        scenario.get("expected_life_paid", effect.get("activation_life_cost") or 0) or 0
    )

    if not battle.can_activate_generic_regenerate_target_permanent(active, [], source):
        fail("battle_execution", f"{card['name']} simple activated regenerate target cannot activate")
    activated = battle.activate_generic_regenerate_target_permanent(
        active,
        [],
        [active],
        source,
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6074)),
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated regenerate target activation failed")
    if int(target.get("regeneration_shields") or 0) != expected_shields:
        fail(
            "battle_execution",
            f"{card['name']} target regeneration_shields={target.get('regeneration_shields')!r}",
        )
    if bool(source.get("tapped")) != expected_tapped_source:
        fail(
            "battle_execution",
            f"{card['name']} source tapped={bool(source.get('tapped'))}, expected {expected_tapped_source}",
        )
    destination = battle.move_creature_from_battlefield(
        active,
        target,
        reason="destroy",
        source={"name": "E2E Destroy Effect"},
        all_players=[active],
    )
    if destination != "battlefield":
        fail("battle_execution", f"{card['name']} target regeneration destination={destination!r}")
    if target not in active.battlefield or target in active.graveyard:
        fail("battle_execution", f"{card['name']} target was moved despite regeneration")
    if not target.get("tapped"):
        fail("battle_execution", f"{card['name']} target was not tapped by regeneration replacement")
    if int(target.get("regeneration_shields") or 0) != expected_shields - 1:
        fail(
            "battle_execution",
            f"{card['name']} target remaining regeneration_shields={target.get('regeneration_shields')!r}",
        )
    activation_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "activated_ability"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == "simple_activated_regenerate_target"
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} simple activated regenerate target event")
    if activation_event.get("target") != target.get("name"):
        fail(
            "battle_events",
            f"{card['name']} activated target={activation_event.get('target')!r}, expected {target.get('name')!r}",
        )
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
    if active.life != starting_life - expected_life_paid:
        fail(
            "battle_execution",
            f"{card['name']} life={active.life}, expected {starting_life - expected_life_paid}",
        )
    if expected_discard_count:
        discarded = list(activation_event.get("discarded") or [])
        if len(discarded) != expected_discard_count:
            fail("battle_events", f"{card['name']} discarded={discarded!r}")
        if activation_event.get("activation_discard_target") != expected_discard_target:
            fail(
                "battle_events",
                f"{card['name']} activation_discard_target={activation_event.get('activation_discard_target')!r}",
            )
        if not set(discarded).issubset(set(starting_hand_names)):
            fail("battle_events", f"{card['name']} discarded cards not from starting hand: {discarded!r}")
    shield_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "regeneration_shield_used" and data.get("card") == target.get("name")
        ),
        None,
    )
    if shield_event is None:
        fail("battle_events", f"missing {target.get('name')} regeneration shield event")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target_name": target.get("name"),
        "destination": destination,
        "source_tapped": bool(source.get("tapped")),
        "target_tapped": bool(target.get("tapped")),
        "regeneration_shields_after": int(target.get("regeneration_shields") or 0),
        "discarded_count": expected_discard_count,
        "life_paid": expected_life_paid,
    }


def run_stat_modifier_until_eot(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    active = battle.Player(str(scenario.get("player") or "Spell Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    raw_targets = list(scenario.get("targets") or [])
    if not raw_targets:
        raw_targets = [
            {
                "name": "E2E Target Creature",
                "type_line": "Creature - Soldier",
                "power": 2,
                "toughness": 2,
                **dict(scenario.get("target") or {}),
            }
        ]
    targets = [battle.enrich_card(dict(target)) for target in raw_targets]
    active.battlefield = targets
    expected_keywords = [
        str(keyword or "").strip().lower().replace(" ", "_")
        for keyword in (scenario.get("expected_keywords") or effect.get("granted_keywords_until_eot") or [])
        if str(keyword or "").strip()
    ]
    before_events = len(events)
    before_stats = {
        str(target.get("name") or index): (
            int(target.get("power") or 0),
            int(target.get("toughness") or 0),
        )
        for index, target in enumerate(targets)
    }
    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card({**card, **effect}),
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6073)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    expected_count = int(scenario.get("expected_target_count") or effect.get("target_count_max") or effect.get("target_count") or 1)
    expected_power_delta = int(scenario.get("expected_power_delta") or effect.get("power_delta") or 0)
    expected_toughness_delta = int(scenario.get("expected_toughness_delta") or effect.get("toughness_delta") or 0)
    affected_targets = []
    for target in targets:
        target_name = str(target.get("name") or "")
        before_power, before_toughness = before_stats[target_name]
        expected_power = before_power + expected_power_delta
        expected_toughness = before_toughness + expected_toughness_delta
        if int(target.get("power") or 0) == expected_power and int(target.get("toughness") or 0) == expected_toughness:
            affected_targets.append(target)
            for keyword in expected_keywords:
                if not battle.card_has_keyword(target, keyword):
                    fail("battle_execution", f"{card['name']} target {target_name} missing keyword {keyword!r}")
    if len(affected_targets) != expected_count:
        fail(
            "battle_execution",
            f"{card['name']} affected_targets={len(affected_targets)}, expected {expected_count}",
        )
    resolved_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "stat_modifier_until_eot_resolved"
            and data.get("card") == card.get("name")
            and (
                data.get("target") in {target.get("name") for target in affected_targets}
                or int(data.get("target_count") or 0) == expected_count
            )
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} stat modifier resolved event")
    if list(resolved_event.get("granted_keywords_until_eot") or []) != expected_keywords:
        fail(
            "battle_events",
            f"{card['name']} resolved keywords={resolved_event.get('granted_keywords_until_eot')!r}, expected {expected_keywords!r}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": affected_targets[0].get("name") if affected_targets else None,
        "target_power": int(affected_targets[0].get("power") or 0) if affected_targets else 0,
        "target_toughness": int(affected_targets[0].get("toughness") or 0) if affected_targets else 0,
        "target_count": len(affected_targets),
        "granted_keywords": expected_keywords,
    }


def run_target_keyword_draw_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    if effect.get("effect") != "composite_resolution":
        fail("battle_execution", f"{card['name']} effect={effect.get('effect')!r}")
    active = battle.Player(str(scenario.get("player") or "Spell Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.library = [
        battle.enrich_card(dict(library_card))
        for library_card in (scenario.get("library") or scenario.get("controller_library") or [])
        if isinstance(library_card, dict)
    ]
    target = battle.enrich_card(
        {
            "name": "E2E Target Creature",
            "type_line": "Creature - Soldier",
            "power": 2,
            "toughness": 2,
            **dict(scenario.get("target") or {}),
        }
    )
    nonmatching_target = (
        battle.enrich_card(dict(scenario["nonmatching_target"]))
        if isinstance(scenario.get("nonmatching_target"), dict)
        else None
    )
    active.battlefield = ([nonmatching_target] if nonmatching_target is not None else []) + [target]
    expected_keywords = [
        str(keyword or "").strip().lower().replace(" ", "_")
        for keyword in (scenario.get("expected_keywords") or effect.get("granted_keywords_until_eot") or [])
        if str(keyword or "").strip()
    ]
    expected_draw_count = int(scenario.get("expected_draw_count") or effect.get("draw_count") or 1)
    before_events = len(events)
    before_power = int(target.get("power") or 0)
    before_toughness = int(target.get("toughness") or 0)
    nonmatching_before = (
        int(nonmatching_target.get("power") or 0),
        int(nonmatching_target.get("toughness") or 0),
    ) if nonmatching_target is not None else None
    library_before = len(active.library)
    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card({**card, **effect}),
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6073)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    expected_power = before_power + int(scenario.get("expected_power_delta") or effect.get("power_delta") or 0)
    expected_toughness = before_toughness + int(
        scenario.get("expected_toughness_delta") or effect.get("toughness_delta") or 0
    )
    if int(target.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} target power={target.get('power')!r}, expected {expected_power}")
    if int(target.get("toughness") or 0) != expected_toughness:
        fail(
            "battle_execution",
            f"{card['name']} target toughness={target.get('toughness')!r}, expected {expected_toughness}",
        )
    for keyword in expected_keywords:
        if not battle.card_has_keyword(target, keyword):
            fail("battle_execution", f"{card['name']} target missing keyword {keyword!r}")
        if nonmatching_target is not None and battle.card_has_keyword(nonmatching_target, keyword):
            fail("battle_execution", f"{card['name']} incorrectly granted {keyword!r} to illegal target")
    if nonmatching_target is not None and (
        int(nonmatching_target.get("power") or 0),
        int(nonmatching_target.get("toughness") or 0),
    ) != nonmatching_before:
        fail("battle_execution", f"{card['name']} incorrectly modified illegal target")
    if len(active.hand) != expected_draw_count:
        fail("battle_execution", f"{card['name']} drew {len(active.hand)} cards, expected {expected_draw_count}")
    if len(active.library) != library_before - expected_draw_count:
        fail(
            "battle_execution",
            f"{card['name']} library={len(active.library)}, expected {library_before - expected_draw_count}",
        )

    stat_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "stat_modifier_until_eot_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == target.get("name")
        ),
        None,
    )
    if stat_event is None:
        fail("battle_events", f"missing {card['name']} stat modifier resolved event")
    if list(stat_event.get("granted_keywords_until_eot") or []) != expected_keywords:
        fail(
            "battle_events",
            f"{card['name']} resolved keywords={stat_event.get('granted_keywords_until_eot')!r}, expected {expected_keywords!r}",
        )
    draw_component_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "composite_rule_component_resolved"
            and data.get("card") == card.get("name")
            and data.get("component_effect") == "draw_cards"
            and data.get("outcome") == "cards_drawn"
        ),
        None,
    )
    if draw_component_event is None:
        fail("battle_events", f"missing {card['name']} composite draw_cards component event")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "target_power": int(target.get("power") or 0),
        "target_toughness": int(target.get("toughness") or 0),
        "granted_keywords": expected_keywords,
        "cards_drawn": expected_draw_count,
        "nonmatching_target": nonmatching_target.get("name") if nonmatching_target is not None else None,
        "hand": [item.get("name") for item in active.hand if isinstance(item, dict)],
    }


def run_boost_scry_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    active = battle.Player(str(scenario.get("player") or "Spell Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    target = battle.enrich_card(
        {
            "name": "E2E Target Creature",
            "type_line": "Creature - Soldier",
            "power": 2,
            "toughness": 2,
            **dict(scenario.get("target") or {}),
        }
    )
    active.battlefield = [target]
    active.library = [dict(library_card) for library_card in scenario.get("library") or []]
    before_events = len(events)
    before_power = int(target.get("power") or 0)
    before_toughness = int(target.get("toughness") or 0)
    expected_scry_count = int(scenario.get("expected_scry_count") or effect.get("scry_count") or 1)
    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card({**card, **effect}),
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6074)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    expected_power = before_power + int(scenario.get("expected_power_delta") or effect.get("power_delta") or 0)
    expected_toughness = before_toughness + int(
        scenario.get("expected_toughness_delta") or effect.get("toughness_delta") or 0
    )
    if int(target.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} target power={target.get('power')!r}, expected {expected_power}")
    if int(target.get("toughness") or 0) != expected_toughness:
        fail(
            "battle_execution",
            f"{card['name']} target toughness={target.get('toughness')!r}, expected {expected_toughness}",
        )
    resolved_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "stat_modifier_until_eot_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == target.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} stat modifier resolved event")
    scry_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "scry_resolved"
            and data.get("card") == card.get("name")
            and int(data.get("scry_count") or 0) == expected_scry_count
        ),
        None,
    )
    if scry_event is None:
        fail("battle_events", f"missing {card['name']} scry_resolved event")
    composite_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "composite_rule_resolved"
            and data.get("card") == card.get("name")
            and int(data.get("components_applied") or 0) == 2
            and int(data.get("components_skipped") or 0) == 0
        ),
        None,
    )
    if composite_event is None:
        fail("battle_events", f"missing {card['name']} composite_rule_resolved event")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "target_power": int(target.get("power") or 0),
        "target_toughness": int(target.get("toughness") or 0),
        "scry_count": expected_scry_count,
        "top_after": list(scry_event.get("top_after") or []),
    }


def run_global_stat_modifier_draw_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    active = battle.Player(str(scenario.get("player") or "Spell Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.battlefield = [
        battle.enrich_card(dict(permanent))
        for permanent in scenario.get("controller_battlefield") or []
    ]
    opponent.battlefield = [
        battle.enrich_card(dict(permanent))
        for permanent in scenario.get("opponent_battlefield") or []
    ]
    active.library = [dict(library_card) for library_card in scenario.get("library") or []]
    all_permanents = [*active.battlefield, *opponent.battlefield]
    before_stats = {
        permanent.get("name"): (
            int(permanent.get("power") or 0),
            int(permanent.get("toughness") or 0),
        )
        for permanent in all_permanents
        if isinstance(permanent, dict)
    }
    expected_names = set(str(name) for name in scenario.get("expected_affected_names") or [])
    before_events = len(events)
    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card({**card, **effect}),
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6074)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    power_delta = int(scenario.get("expected_power_delta") or effect.get("power_delta") or 0)
    toughness_delta = int(scenario.get("expected_toughness_delta") or effect.get("toughness_delta") or 0)
    for permanent in all_permanents:
        name = str(permanent.get("name") or "")
        before_power, before_toughness = before_stats.get(name, (0, 0))
        expected_power = before_power + (power_delta if name in expected_names else 0)
        expected_toughness = before_toughness + (toughness_delta if name in expected_names else 0)
        if int(permanent.get("power") or 0) != expected_power:
            fail("battle_execution", f"{card['name']} {name} power={permanent.get('power')!r}, expected {expected_power}")
        if int(permanent.get("toughness") or 0) != expected_toughness:
            fail(
                "battle_execution",
                f"{card['name']} {name} toughness={permanent.get('toughness')!r}, expected {expected_toughness}",
            )
    expected_draw_count = int(scenario.get("expected_draw_count") or effect.get("draw_count") or effect.get("count") or 1)
    if len(active.hand) != expected_draw_count:
        fail("battle_execution", f"{card['name']} drew {len(active.hand)} cards, expected {expected_draw_count}")
    resolved_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "global_stat_modifier_until_eot_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} global stat modifier resolved event")
    expected_affected_count = int(scenario.get("expected_affected_count") or len(expected_names))
    if int(resolved_event.get("affected_count") or 0) != expected_affected_count:
        fail(
            "battle_events",
            f"{card['name']} affected_count={resolved_event.get('affected_count')!r}, expected {expected_affected_count}",
        )
    expected_controller = str(scenario.get("expected_target_controller") or effect.get("target_controller") or "all")
    if str(resolved_event.get("target_controller") or "") != expected_controller:
        fail(
            "battle_events",
            f"{card['name']} target_controller={resolved_event.get('target_controller')!r}, expected {expected_controller!r}",
        )
    expected_filter = scenario.get("expected_creature_filter") or effect.get("creature_filter") or {}
    if dict(resolved_event.get("creature_filter") or {}) != dict(expected_filter or {}):
        fail(
            "battle_events",
            f"{card['name']} creature_filter={resolved_event.get('creature_filter')!r}, expected {expected_filter!r}",
        )
    composite_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "composite_rule_resolved"
            and data.get("card") == card.get("name")
            and int(data.get("components_applied") or 0) == 2
            and int(data.get("components_skipped") or 0) == 0
        ),
        None,
    )
    if composite_event is None:
        fail("battle_events", f"missing {card['name']} composite_rule_resolved event")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "affected_count": expected_affected_count,
        "draw_count": expected_draw_count,
        "target_controller": expected_controller,
        "creature_filter": dict(expected_filter or {}),
    }


def run_proliferate_draw_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    active = battle.Player(str(scenario.get("player") or "Spell Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.battlefield = [
        battle.enrich_card(dict(permanent))
        for permanent in scenario.get("controller_battlefield") or []
    ]
    opponent.battlefield = [
        battle.enrich_card(dict(permanent))
        for permanent in scenario.get("opponent_battlefield") or []
    ]
    opponent.poison = int(scenario.get("opponent_poison_counters") or 0)
    opponent.counters = {"poison": opponent.poison} if opponent.poison > 0 else {}
    active.library = [dict(library_card) for library_card in scenario.get("library") or []]
    before_events = len(events)

    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card({**card, **effect}),
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6075)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )

    expected_draw_count = int(scenario.get("expected_draw_count") or effect.get("draw_count") or effect.get("count") or 1)
    if len(active.hand) != expected_draw_count:
        fail("battle_execution", f"{card['name']} drew {len(active.hand)} cards, expected {expected_draw_count}")

    controller_permanent = active.battlefield[0] if active.battlefield else {}
    opponent_permanent = opponent.battlefield[0] if opponent.battlefield else {}
    expected_plus_one = int(scenario.get("expected_controller_plus_one_counters") or 0)
    if int(controller_permanent.get("plus_one_counters") or 0) != expected_plus_one:
        fail(
            "battle_execution",
            f"{card['name']} +1/+1 counters={controller_permanent.get('plus_one_counters')!r}, expected {expected_plus_one}",
        )
    expected_power = int(scenario.get("expected_controller_power") or 0)
    expected_toughness = int(scenario.get("expected_controller_toughness") or 0)
    if int(controller_permanent.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} power={controller_permanent.get('power')!r}, expected {expected_power}")
    if int(controller_permanent.get("toughness") or 0) != expected_toughness:
        fail(
            "battle_execution",
            f"{card['name']} toughness={controller_permanent.get('toughness')!r}, expected {expected_toughness}",
        )
    expected_charge = int(scenario.get("expected_opponent_charge_counters") or 0)
    if battle.get_named_counter_count(opponent_permanent, "charge") != expected_charge:
        fail(
            "battle_execution",
            f"{card['name']} charge counters={battle.get_named_counter_count(opponent_permanent, 'charge')}, expected {expected_charge}",
        )
    expected_poison = int(scenario.get("expected_opponent_poison_counters") or 0)
    if int(getattr(opponent, "poison", 0) or 0) != expected_poison:
        fail("battle_execution", f"{card['name']} poison={getattr(opponent, 'poison', 0)}, expected {expected_poison}")

    proliferate_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "proliferate_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if proliferate_event is None:
        fail("battle_events", f"missing {card['name']} proliferate_resolved event")
    if int(proliferate_event.get("permanent_count") or 0) < 2:
        fail("battle_events", f"{card['name']} permanent_count={proliferate_event.get('permanent_count')!r}")
    if int(proliferate_event.get("player_count") or 0) < 1:
        fail("battle_events", f"{card['name']} player_count={proliferate_event.get('player_count')!r}")
    composite_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "composite_rule_resolved"
            and data.get("card") == card.get("name")
            and int(data.get("components_applied") or 0) == 2
            and int(data.get("components_skipped") or 0) == 0
        ),
        None,
    )
    if composite_event is None:
        fail("battle_events", f"missing {card['name']} composite_rule_resolved event")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "draw_count": expected_draw_count,
        "controller_plus_one_counters": expected_plus_one,
        "opponent_charge_counters": expected_charge,
        "opponent_poison_counters": expected_poison,
    }


def run_controlled_stat_modifier_until_eot(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    active = battle.Player(str(scenario.get("player") or "Spell Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    matching_target = battle.enrich_card(
        {
            "name": "E2E Matching Controlled Creature",
            "type_line": "Creature - Soldier",
            "power": 2,
            "toughness": 2,
            **dict(scenario.get("matching_target") or {}),
        }
    )
    nonmatching_target = battle.enrich_card(
        {
            "name": "E2E Nonmatching Controlled Creature",
            "type_line": "Creature - Soldier",
            "power": 2,
            "toughness": 2,
            **dict(scenario.get("nonmatching_target") or {}),
        }
    )
    opponent_target = battle.enrich_card(
        {
            "name": "E2E Opponent Matching Creature",
            "type_line": "Creature - Soldier",
            "power": 2,
            "toughness": 2,
            **dict(scenario.get("opponent_target") or {}),
        }
    )
    active.battlefield = [matching_target, nonmatching_target]
    opponent.battlefield = [opponent_target]
    before_events = len(events)
    matching_before = (int(matching_target.get("power") or 0), int(matching_target.get("toughness") or 0))
    nonmatching_before = (
        int(nonmatching_target.get("power") or 0),
        int(nonmatching_target.get("toughness") or 0),
    )
    opponent_before = (int(opponent_target.get("power") or 0), int(opponent_target.get("toughness") or 0))
    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card({**card, **effect}),
        turn=int(scenario.get("turn") or 7),
        rng=random.Random(int(scenario.get("seed") or 6074)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    expected_power = matching_before[0] + int(scenario.get("expected_power_delta") or effect.get("power_delta") or 0)
    expected_toughness = matching_before[1] + int(
        scenario.get("expected_toughness_delta") or effect.get("toughness_delta") or 0
    )
    if int(matching_target.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} matching power={matching_target.get('power')!r}, expected {expected_power}")
    if int(matching_target.get("toughness") or 0) != expected_toughness:
        fail(
            "battle_execution",
            f"{card['name']} matching toughness={matching_target.get('toughness')!r}, expected {expected_toughness}",
        )
    if (int(nonmatching_target.get("power") or 0), int(nonmatching_target.get("toughness") or 0)) != nonmatching_before:
        fail("battle_execution", f"{card['name']} incorrectly affected controlled nonmatching creature")
    if (int(opponent_target.get("power") or 0), int(opponent_target.get("toughness") or 0)) != opponent_before:
        fail("battle_execution", f"{card['name']} incorrectly affected opponent creature")
    resolved_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "controlled_stat_modifier_until_eot_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} controlled stat modifier resolved event")
    if int(resolved_event.get("affected_count") or 0) != 1:
        fail("battle_events", f"{card['name']} affected_count={resolved_event.get('affected_count')!r}, expected 1")
    expected_filter = scenario.get("expected_creature_filter") or effect.get("creature_filter") or {}
    if dict(resolved_event.get("creature_filter") or {}) != dict(expected_filter or {}):
        fail(
            "battle_events",
            f"{card['name']} creature_filter={resolved_event.get('creature_filter')!r}, expected {expected_filter!r}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "matching_target": matching_target.get("name"),
        "matching_power": int(matching_target.get("power") or 0),
        "matching_toughness": int(matching_target.get("toughness") or 0),
        "affected_count": int(resolved_event.get("affected_count") or 0),
        "creature_filter": dict(expected_filter or {}),
    }


def run_simple_activated_self_boost(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    source = battle.enrich_card(
        {
            **card,
            "type_line": card.get("type_line") or "Creature - Soldier",
            "effect": "creature",
            "power": int(card.get("power") or scenario.get("source_power") or 2),
            "toughness": int(card.get("toughness") or scenario.get("source_toughness") or 2),
            "summoning_sick": False,
            **effect,
            **dict(scenario.get("source_overrides") or {}),
        }
    )
    active = battle.Player(str(scenario.get("player") or "Activated Controller"), None, [])
    active.battlefield = [source]
    active.hand = [dict(card) for card in (scenario.get("controller_hand") or []) if isinstance(card, dict)]
    add_manifest_mana(active, scenario.get("controller_mana") or {})
    expected_power_delta = int(
        scenario.get("expected_power_delta") or effect.get("power_delta") or effect.get("power_boost") or 0
    )
    expected_toughness_delta = int(
        scenario.get("expected_toughness_delta")
        or effect.get("toughness_delta")
        or effect.get("toughness_boost")
        or 0
    )
    expected_tapped_source = bool(scenario.get("expected_tapped_source", effect.get("activation_requires_tap", False)))
    expected_limit = int(
        scenario.get("expected_activation_limit_per_turn")
        or effect.get("activation_limit_per_turn")
        or 0
    )
    expected_discard_count = int(
        scenario.get("expected_discard_count")
        or effect.get("activation_discard_count")
        or 0
    )
    expected_life_paid = int(
        scenario.get("expected_life_paid")
        or effect.get("activation_life_cost")
        or 0
    )
    turn = int(scenario.get("turn") or 7)
    before_events = len(events)
    before_power = int(source.get("power") or 0)
    before_toughness = int(source.get("toughness") or 0)
    life_before = active.life
    if not battle.can_activate_generic_self_boost_permanent(active, source):
        fail("battle_execution", f"{card['name']} simple activated self boost cannot activate")
    activated = battle.activate_generic_self_boost_permanent(
        active,
        [active],
        source,
        turn=turn,
        rng=random.Random(int(scenario.get("seed") or 6073)),
        phase=str(scenario.get("phase") or "precombat_main"),
    )
    if not activated:
        fail("battle_execution", f"{card['name']} simple activated self boost activation failed")
    expected_power = before_power + expected_power_delta
    expected_toughness = before_toughness + expected_toughness_delta
    if int(source.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} source power={source.get('power')!r}, expected {expected_power}")
    if int(source.get("toughness") or 0) != expected_toughness:
        fail(
            "battle_execution",
            f"{card['name']} source toughness={source.get('toughness')!r}, expected {expected_toughness}",
        )
    if bool(source.get("tapped")) != expected_tapped_source:
        fail(
            "battle_execution",
            f"{card['name']} source tapped={bool(source.get('tapped'))}, expected {expected_tapped_source}",
        )
    activation_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "activated_ability"
            and data.get("card") == card.get("name")
            and data.get("activation_kind") == "simple_activated_self_boost"
        ),
        None,
    )
    if activation_event is None:
        fail("battle_events", f"missing {card['name']} simple activated self boost event")
    if int(activation_event.get("power_delta") or 0) != expected_power_delta:
        fail("battle_events", f"{card['name']} power_delta={activation_event.get('power_delta')!r}")
    if int(activation_event.get("toughness_delta") or 0) != expected_toughness_delta:
        fail("battle_events", f"{card['name']} toughness_delta={activation_event.get('toughness_delta')!r}")
    if expected_limit and int(activation_event.get("activation_limit_per_turn") or 0) != expected_limit:
        fail(
            "battle_events",
            f"{card['name']} activation_limit_per_turn={activation_event.get('activation_limit_per_turn')!r}",
        )
    discarded = list(activation_event.get("discarded") or [])
    if len(discarded) != expected_discard_count:
        fail(
            "battle_events",
            f"{card['name']} discarded_count={len(discarded)}, expected {expected_discard_count}",
        )
    life_paid = int(activation_event.get("activation_life_cost") or 0)
    if life_paid != expected_life_paid:
        fail(
            "battle_events",
            f"{card['name']} activation_life_cost={life_paid}, expected {expected_life_paid}",
        )
    if active.life != life_before - expected_life_paid:
        fail(
            "battle_execution",
            f"{card['name']} life_after={active.life}, expected {life_before - expected_life_paid}",
        )
    resolved_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "stat_modifier_until_eot_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == source.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} simple activated self boost resolved event")
    extra_activations = 0
    if expected_limit:
        for activation_index in range(2, expected_limit + 1):
            add_manifest_mana(active, scenario.get("controller_mana") or {})
            allowed_activation = battle.activate_generic_self_boost_permanent(
                active,
                [active],
                source,
                turn=turn,
                rng=random.Random(int(scenario.get("seed") or 6073) + activation_index),
                phase=str(scenario.get("phase") or "precombat_main"),
            )
            if not allowed_activation:
                fail(
                    "battle_execution",
                    f"{card['name']} activated self boost failed before per-turn limit {expected_limit}",
                )
            extra_activations += 1
        add_manifest_mana(active, scenario.get("controller_mana") or {})
        exceeded_activation = battle.activate_generic_self_boost_permanent(
            active,
            [active],
            source,
            turn=turn,
            rng=random.Random(int(scenario.get("seed") or 6073) + expected_limit + 1),
            phase=str(scenario.get("phase") or "precombat_main"),
        )
        if exceeded_activation:
            fail("battle_execution", f"{card['name']} activated self boost exceeded per-turn limit")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "source_power": int(source.get("power") or 0),
        "source_toughness": int(source.get("toughness") or 0),
        "power_delta": expected_power_delta,
        "toughness_delta": expected_toughness_delta,
        "activation_limit_per_turn": expected_limit,
        "extra_activations": extra_activations,
        "discarded_count": len(discarded),
        "life_paid": expected_life_paid,
    }


def run_attack_self_boost(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    source = battle.enrich_card(
        {
            **card,
            "type_line": card.get("type_line") or "Creature - Soldier",
            "effect": "creature",
            "power": int(card.get("power") or scenario.get("source_power") or 2),
            "toughness": int(card.get("toughness") or scenario.get("source_toughness") or 2),
            "attacking": True,
            "summoning_sick": False,
            **effect,
        }
    )
    active = battle.Player(str(scenario.get("player") or "Attack Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.battlefield = [source]
    before_events = len(events)
    before_power = int(source.get("power") or 0)
    before_toughness = int(source.get("toughness") or 0)
    expected_power_delta = int(
        scenario.get("expected_power_delta") or effect.get("power_delta") or effect.get("power_boost") or 0
    )
    expected_toughness_delta = int(
        scenario.get("expected_toughness_delta")
        or effect.get("toughness_delta")
        or effect.get("toughness_boost")
        or 0
    )
    resolved = battle.resolve_attack_self_boost_triggers(
        active,
        [source],
        [active, opponent],
        turn=int(scenario.get("turn") or 7),
        phase=str(scenario.get("phase") or "combat"),
    )
    if resolved != 1:
        fail("battle_execution", f"{card['name']} attack self-boost resolved={resolved}, expected 1")
    expected_power = before_power + expected_power_delta
    expected_toughness = before_toughness + expected_toughness_delta
    if int(source.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} source power={source.get('power')!r}, expected {expected_power}")
    if int(source.get("toughness") or 0) != expected_toughness:
        fail(
            "battle_execution",
            f"{card['name']} source toughness={source.get('toughness')!r}, expected {expected_toughness}",
        )
    trigger_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "trigger_resolved"
            and data.get("card") == card.get("name")
            and data.get("effect") == "self_stat_modifier_until_eot"
        ),
        None,
    )
    if trigger_event is None:
        fail("battle_events", f"missing {card['name']} attack self-boost trigger event")
    resolved_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "stat_modifier_until_eot_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == source.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} attack self-boost resolved event")
    if int(resolved_event.get("power_delta") or 0) != expected_power_delta:
        fail("battle_events", f"{card['name']} power_delta={resolved_event.get('power_delta')!r}")
    if int(resolved_event.get("toughness_delta") or 0) != expected_toughness_delta:
        fail("battle_events", f"{card['name']} toughness_delta={resolved_event.get('toughness_delta')!r}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "source_power": int(source.get("power") or 0),
        "source_toughness": int(source.get("toughness") or 0),
        "power_delta": expected_power_delta,
        "toughness_delta": expected_toughness_delta,
    }


def run_becomes_blocked_self_boost(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    source = battle.enrich_card(
        {
            **card,
            "type_line": card.get("type_line") or "Creature - Soldier",
            "effect": "creature",
            "power": int(card.get("power") or scenario.get("source_power") or 2),
            "toughness": int(card.get("toughness") or scenario.get("source_toughness") or 2),
            "attacking": True,
            "summoning_sick": False,
            **effect,
        }
    )
    active = battle.Player(str(scenario.get("player") or "Attack Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    blocker_count = max(1, int(scenario.get("blocker_count") or 1))
    blockers = [
        battle.enrich_card(
            {
                "name": f"E2E Blocker {index + 1}",
                "type_line": "Creature - Soldier",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "blocking": True,
            }
        )
        for index in range(blocker_count)
    ]
    active.battlefield = [source]
    opponent.battlefield = blockers
    before_events = len(events)
    before_power = int(source.get("power") or 0)
    before_toughness = int(source.get("toughness") or 0)
    base_power_delta = int(
        scenario.get("expected_base_power_delta")
        or effect.get("power_delta")
        or effect.get("power_boost")
        or 0
    )
    base_toughness_delta = int(
        scenario.get("expected_base_toughness_delta")
        or effect.get("toughness_delta")
        or effect.get("toughness_boost")
        or 0
    )
    mode = str(
        scenario.get("expected_blocker_count_mode")
        or effect.get("blocker_count_mode")
        or "fixed"
    )
    if mode == "fixed":
        multiplier = 1
    elif mode == "per_blocker":
        multiplier = blocker_count
    elif mode == "beyond_first":
        multiplier = max(0, blocker_count - 1)
    else:
        fail("battle_execution", f"{card['name']} unsupported blocker_count_mode={mode!r}")
    expected_power_delta = base_power_delta * multiplier
    expected_toughness_delta = base_toughness_delta * multiplier
    resolved = battle.resolve_becomes_blocked_self_boost_triggers(
        active,
        [(source, blockers)],
        [active, opponent],
        turn=int(scenario.get("turn") or 7),
        phase=str(scenario.get("phase") or "declare_blockers"),
    )
    if resolved != 1:
        fail("battle_execution", f"{card['name']} becomes-blocked self-boost resolved={resolved}, expected 1")
    expected_power = before_power + expected_power_delta
    expected_toughness = before_toughness + expected_toughness_delta
    if int(source.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} source power={source.get('power')!r}, expected {expected_power}")
    if int(source.get("toughness") or 0) != expected_toughness:
        fail(
            "battle_execution",
            f"{card['name']} source toughness={source.get('toughness')!r}, expected {expected_toughness}",
        )
    trigger_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "trigger_resolved"
            and data.get("card") == card.get("name")
            and data.get("trigger") == "becomes_blocked"
            and data.get("effect") == "self_stat_modifier_until_eot"
        ),
        None,
    )
    if trigger_event is None:
        fail("battle_events", f"missing {card['name']} becomes-blocked self-boost trigger event")
    resolved_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "stat_modifier_until_eot_resolved"
            and data.get("card") == card.get("name")
            and data.get("target") == source.get("name")
        ),
        None,
    )
    if resolved_event is None:
        fail("battle_events", f"missing {card['name']} becomes-blocked self-boost resolved event")
    if int(resolved_event.get("blocker_count") or 0) != blocker_count:
        fail("battle_events", f"{card['name']} blocker_count={resolved_event.get('blocker_count')!r}")
    if resolved_event.get("blocker_count_mode") != mode:
        fail("battle_events", f"{card['name']} blocker_count_mode={resolved_event.get('blocker_count_mode')!r}")
    if int(resolved_event.get("power_delta") or 0) != expected_power_delta:
        fail("battle_events", f"{card['name']} power_delta={resolved_event.get('power_delta')!r}")
    if int(resolved_event.get("toughness_delta") or 0) != expected_toughness_delta:
        fail("battle_events", f"{card['name']} toughness_delta={resolved_event.get('toughness_delta')!r}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "source_power": int(source.get("power") or 0),
        "source_toughness": int(source.get("toughness") or 0),
        "blocker_count": blocker_count,
        "blocker_count_mode": mode,
        "power_delta": expected_power_delta,
        "toughness_delta": expected_toughness_delta,
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


def run_counter_unless_pays_response(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    response_card = dict(scenario["card"])
    turn = int(scenario.get("turn") or 7)
    phase = str(scenario.get("phase") or "precombat_main")
    active = battle.Player(str(scenario.get("active_player") or "Active"), None, [])
    responder = battle.Player(str(scenario.get("responder") or "Responder"), None, [])
    active.battlefield = [dict(item) for item in scenario.get("active_battlefield") or []]
    responder.battlefield = [dict(item) for item in scenario.get("responder_battlefield") or []]
    add_manifest_mana(active, scenario.get("active_mana") or {})
    add_manifest_mana(responder, scenario.get("responder_mana") or {"blue": 1})
    expected_cards_drawn = int(scenario.get("expected_cards_drawn") or response_card.get("draw_on_counter") or 0)
    if expected_cards_drawn and not getattr(responder, "library", []):
        responder.library = [
            {"name": f"E2E Counter Unless Draw {index + 1}", "type_line": "Instant", "cmc": 1}
            for index in range(expected_cards_drawn)
        ]
    responder.hand = [response_card]
    target_spell = dict(scenario.get("target_spell") or {
        "name": "Counter Target Fixture",
        "cmc": 7,
        "mana_cost": "{5}{R}{R}",
        "type_line": "Creature - Dragon",
        "effect": "finisher",
    })
    target_effect = dict(scenario.get("target_stack_effect") or {"effect": "finisher"})
    stack = battle.Stack()
    stack.push(target_spell, active, target_effect)

    if not battle.priority_round(
        active,
        [active, responder],
        stack,
        turn,
        random.Random(int(scenario.get("seed") or 6072)),
        phase=phase,
    ):
        fail("battle_execution", f"{response_card['name']} was not cast as counter response")

    expected_countered = bool(scenario.get("expected_countered", True))
    actual_countered = bool(stack.items and getattr(stack.items[-1], "countered", False))
    if actual_countered != expected_countered:
        fail("battle_execution", f"{response_card['name']} countered={actual_countered}, expected={expected_countered}")

    counter_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "spell_countered" and data.get("counter") == response_card.get("name")
        ),
        None,
    )
    if counter_event is None:
        fail("battle_events", f"missing {response_card['name']} spell_countered event")

    expected_tax = scenario.get("expected_counter_unless_pays_generic")
    if expected_tax is not None and counter_event.get("counter_unless_pays_generic") != int(expected_tax):
        fail(
            "battle_events",
            f"{response_card['name']} tax={counter_event.get('counter_unless_pays_generic')}, expected={expected_tax}",
        )
    expected_source = scenario.get("expected_counter_unless_pays_amount_source")
    if expected_source is not None and counter_event.get("counter_unless_pays_amount_source") != expected_source:
        fail(
            "battle_events",
            f"{response_card['name']} tax_source={counter_event.get('counter_unless_pays_amount_source')!r}",
        )
    expected_count = scenario.get("expected_counter_unless_pays_count")
    if expected_count is not None and counter_event.get("counter_unless_pays_count") != int(expected_count):
        fail(
            "battle_events",
            f"{response_card['name']} tax_count={counter_event.get('counter_unless_pays_count')}, expected={expected_count}",
        )
    expected_paid = bool(scenario.get("expected_counter_tax_paid", False))
    if bool(counter_event.get("counter_tax_paid")) != expected_paid:
        fail("battle_events", f"{response_card['name']} counter_tax_paid={counter_event.get('counter_tax_paid')}")
    if expected_cards_drawn:
        if int(counter_event.get("cards_drawn") or 0) != expected_cards_drawn:
            fail(
                "battle_events",
                f"{response_card['name']} expected to draw {expected_cards_drawn}; event={counter_event.get('cards_drawn')}",
            )
        drawn_names = [card.get("name") for card in responder.hand if isinstance(card, dict)]
        expected_drawn_names = [
            f"E2E Counter Unless Draw {index + 1}"
            for index in range(expected_cards_drawn)
        ]
        if drawn_names != expected_drawn_names:
            fail(
                "battle_execution",
                f"{response_card['name']} drawn hand={drawn_names}, expected={expected_drawn_names}",
            )
    expected_exile = bool(scenario.get("expected_countered_spell_to_exile"))
    if bool(counter_event.get("countered_spell_to_exile")) != expected_exile:
        fail("battle_events", f"{response_card['name']} countered_spell_to_exile={counter_event.get('countered_spell_to_exile')}")
    if expected_exile and expected_countered:
        if not target_spell.get("_exile_on_resolution"):
            fail("battle_execution", f"{response_card['name']} did not mark countered spell for exile")
        stack.resolve_top()
        if not any(card.get("name") == target_spell.get("name") for card in active.exile if isinstance(card, dict)):
            fail("battle_execution", f"{response_card['name']} did not move countered spell to exile")

    return {
        "scenario": scenario.get("name"),
        "card_name": response_card["name"],
        "target": target_spell.get("name"),
        "countered": actual_countered,
        "counter_unless_pays_generic": counter_event.get("counter_unless_pays_generic"),
        "counter_unless_pays_amount_source": counter_event.get("counter_unless_pays_amount_source"),
        "counter_unless_pays_count": counter_event.get("counter_unless_pays_count"),
        "counter_tax_paid": counter_event.get("counter_tax_paid"),
        "countered_spell_to_exile": counter_event.get("countered_spell_to_exile"),
        "cards_drawn": int(counter_event.get("cards_drawn") or 0),
    }


def run_counter_target_response(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    response_card = dict(scenario["card"])
    turn = int(scenario.get("turn") or 7)
    phase = str(scenario.get("phase") or "precombat_main")
    active = battle.Player(str(scenario.get("active_player") or "Active"), None, [])
    responder = battle.Player(str(scenario.get("responder") or "Responder"), None, [])
    add_manifest_mana(responder, scenario.get("responder_mana") or {"generic": 3, "blue": 2})
    expected_cards_drawn = int(scenario.get("expected_cards_drawn") or response_card.get("draw_on_counter") or 0)
    if expected_cards_drawn and not getattr(responder, "library", []):
        responder.library = [
            {"name": f"E2E Counter Draw {index + 1}", "type_line": "Instant", "cmc": 1}
            for index in range(expected_cards_drawn)
        ]
    responder.hand = [response_card]
    target_stack_object = dict(
        scenario.get("target_stack_object")
        or scenario.get("target_spell")
        or {
            "name": "Counter Target Fixture",
            "cmc": 7,
            "mana_cost": "{5}{R}{R}",
            "type_line": "Creature - Dragon",
            "effect": "finisher",
        }
    )
    target_stack_effect = dict(scenario.get("target_stack_effect") or {"effect": "finisher"})
    target_stack_item = battle.StackItem(target_stack_object, active, target_stack_effect)
    if not battle.counter_can_target(
        response_card,
        response_card,
        target_stack_object,
        stack_item=target_stack_item,
        counter_controller=responder,
    ):
        fail("battle_execution", f"{response_card['name']} cannot target legal stack fixture")

    nonmatching_stack_object = scenario.get("nonmatching_stack_object")
    if isinstance(nonmatching_stack_object, dict):
        nonmatching_stack_effect = dict(scenario.get("nonmatching_stack_effect") or {"effect": "mana_ability"})
        nonmatching_stack_item = battle.StackItem(
            dict(nonmatching_stack_object),
            active,
            nonmatching_stack_effect,
        )
        if battle.counter_can_target(
            response_card,
            response_card,
            dict(nonmatching_stack_object),
            stack_item=nonmatching_stack_item,
            counter_controller=responder,
        ):
            fail("battle_execution", f"{response_card['name']} can target illegal stack fixture")

    stack = battle.Stack()
    stack.push(target_stack_object, active, target_stack_effect)

    if not battle.priority_round(
        active,
        [active, responder],
        stack,
        turn,
        random.Random(int(scenario.get("seed") or 6072)),
        phase=phase,
    ):
        fail("battle_execution", f"{response_card['name']} was not cast as counter response")

    actual_countered = bool(stack.items and getattr(stack.items[-1], "countered", False))
    if not actual_countered:
        fail("battle_execution", f"{response_card['name']} did not counter legal stack object")

    counter_event = next(
        (
            data
            for event, data in reversed(events)
            if event == "spell_countered" and data.get("counter") == response_card.get("name")
        ),
        None,
    )
    if counter_event is None:
        fail("battle_events", f"missing {response_card['name']} spell_countered event")
    if expected_cards_drawn and int(counter_event.get("cards_drawn") or 0) != expected_cards_drawn:
        fail(
            "battle_events",
            f"{response_card['name']} expected to draw {expected_cards_drawn} on counter; event={counter_event.get('cards_drawn')}",
        )
    expected_exile = bool(
        scenario.get("expected_countered_spell_to_exile")
        or response_card.get("countered_spell_to_exile")
    )
    expected_top_library = bool(
        scenario.get("expected_countered_spell_to_top_library")
        or response_card.get("countered_spell_to_top_library")
    )
    if bool(counter_event.get("countered_spell_to_top_library")) != expected_top_library:
        fail(
            "battle_events",
            f"{response_card['name']} countered_spell_to_top_library={counter_event.get('countered_spell_to_top_library')}",
        )
    if bool(counter_event.get("countered_spell_to_exile")) != expected_exile:
        fail(
            "battle_events",
            f"{response_card['name']} countered_spell_to_exile={counter_event.get('countered_spell_to_exile')}",
        )
    if expected_top_library:
        if not target_stack_object.get("_countered_to_top_library"):
            fail(
                "battle_execution",
                f"{response_card['name']} did not mark countered stack object for library top",
            )
        stack.resolve_top()
        if not active.library or active.library[0].get("name") != target_stack_object.get("name"):
            fail(
                "battle_execution",
                f"{response_card['name']} did not move countered stack object to library top",
            )
    if expected_exile:
        if not target_stack_object.get("_exile_on_resolution"):
            fail("battle_execution", f"{response_card['name']} did not mark countered stack object for exile")
        stack.resolve_top()
        if not any(
            card.get("name") == target_stack_object.get("name")
            for card in active.exile
            if isinstance(card, dict)
        ):
            fail("battle_execution", f"{response_card['name']} did not move countered stack object to exile")

    return {
        "scenario": scenario.get("name"),
        "card_name": response_card["name"],
        "target": target_stack_object.get("name"),
        "target_stack_effect": target_stack_effect.get("effect"),
        "countered": actual_countered,
        "cards_drawn": int(counter_event.get("cards_drawn") or 0),
        "countered_spell_to_top_library": bool(
            counter_event.get("countered_spell_to_top_library")
        ),
        "countered_spell_to_exile": bool(counter_event.get("countered_spell_to_exile")),
        "nonmatching_target": (
            nonmatching_stack_object.get("name")
            if isinstance(nonmatching_stack_object, dict)
            else None
        ),
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


def run_static_controlled_power_toughness_boost(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    source = battle.enrich_card({**card, **battle.get_card_effect(card)})
    active = battle.Player(str(scenario.get("player") or "Static P/T Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Static P/T Opponent"), None, [])
    matching_target = dict(scenario["matching_target"])
    nonmatching_target = (
        dict(scenario["nonmatching_target"])
        if isinstance(scenario.get("nonmatching_target"), dict)
        else None
    )
    opponent_target = dict(scenario["opponent_target"])
    active.battlefield = [source, matching_target]
    if nonmatching_target is not None:
        active.battlefield.append(nonmatching_target)
    opponent.battlefield = [opponent_target]
    refreshed = battle.refresh_controlled_static_power_toughness_bonuses(
        active,
        turn=int(scenario.get("turn") or 3),
        phase=str(scenario.get("phase") or "main"),
        emit_events=True,
    )
    expected_power = int(scenario["expected_power"])
    expected_toughness = int(scenario["expected_toughness"])
    if int(matching_target.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} matching power={matching_target.get('power')}, expected {expected_power}")
    if int(matching_target.get("toughness") or 0) != expected_toughness:
        fail(
            "battle_execution",
            f"{card['name']} matching toughness={matching_target.get('toughness')}, expected {expected_toughness}",
        )
    if nonmatching_target is not None:
        if int(nonmatching_target.get("power") or 0) != int(nonmatching_target.get("base_power") or 0):
            fail("battle_execution", f"{card['name']} incorrectly boosted nonmatching target power")
        if int(nonmatching_target.get("toughness") or 0) != int(nonmatching_target.get("base_toughness") or 0):
            fail("battle_execution", f"{card['name']} incorrectly boosted nonmatching target toughness")
    if int(opponent_target.get("power") or 0) != int(opponent_target.get("base_power") or 0):
        fail("battle_execution", f"{card['name']} incorrectly boosted opponent target power")
    if int(opponent_target.get("toughness") or 0) != int(opponent_target.get("base_toughness") or 0):
        fail("battle_execution", f"{card['name']} incorrectly boosted opponent target toughness")
    source_name = str(scenario.get("expected_source") or card.get("name"))
    changed_event = next(
        (
            data
            for event, data in events
            if event == "static_power_toughness_boost_changed"
            and data.get("card") == matching_target.get("name")
            and source_name in (data.get("source_cards") or [])
        ),
        None,
    )
    if changed_event is None:
        fail("battle_events", f"missing {card['name']} static_power_toughness_boost_changed event")
    active.battlefield.remove(source)
    battle.refresh_controlled_static_power_toughness_bonuses(
        active,
        turn=int(scenario.get("turn") or 3),
        phase="source_left_battlefield",
        emit_events=True,
    )
    if int(matching_target.get("power") or 0) != int(matching_target.get("base_power") or 0):
        fail("battle_execution", f"{card['name']} did not revoke power bonus after source left")
    if int(matching_target.get("toughness") or 0) != int(matching_target.get("base_toughness") or 0):
        fail("battle_execution", f"{card['name']} did not revoke toughness bonus after source left")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "matching_target": matching_target.get("name"),
        "target_power": expected_power,
        "target_toughness": expected_toughness,
        "refreshed_count": len(refreshed),
        "source_cards": changed_event.get("source_cards"),
    }


def run_static_controlled_keyword(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    source = battle.enrich_card({**card, **battle.get_card_effect(card)})
    active = battle.Player(str(scenario.get("player") or "Static Keyword Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Static Keyword Opponent"), None, [])
    matching_target = dict(scenario["matching_target"])
    nonmatching_target = (
        dict(scenario["nonmatching_target"])
        if isinstance(scenario.get("nonmatching_target"), dict)
        else None
    )
    opponent_target = dict(scenario["opponent_target"])
    active.battlefield = [source, matching_target]
    if nonmatching_target is not None:
        active.battlefield.append(nonmatching_target)
    opponent.battlefield = [opponent_target]
    keyword = str(scenario["expected_keyword"]).strip().lower().replace(" ", "_")
    refreshed = battle.refresh_controlled_static_keywords(
        active,
        turn=int(scenario.get("turn") or 3),
        phase=str(scenario.get("phase") or "main"),
        emit_events=True,
    )
    if not battle.card_has_keyword(matching_target, keyword):
        fail("battle_execution", f"{card['name']} did not grant {keyword} to matching target")
    if nonmatching_target is not None and battle.card_has_keyword(nonmatching_target, keyword):
        fail("battle_execution", f"{card['name']} incorrectly granted {keyword} to nonmatching target")
    if battle.card_has_keyword(opponent_target, keyword):
        fail("battle_execution", f"{card['name']} incorrectly granted {keyword} to opponent target")
    source_name = str(scenario.get("expected_source") or card.get("name"))
    changed_event = next(
        (
            data
            for event, data in events
            if event == "static_controlled_keyword_changed"
            and data.get("card") == matching_target.get("name")
            and keyword in (data.get("granted_keywords") or [])
            and source_name in (data.get("source_cards") or [])
        ),
        None,
    )
    if changed_event is None:
        fail("battle_events", f"missing {card['name']} static_controlled_keyword_changed event")
    active.battlefield.remove(source)
    battle.refresh_controlled_static_keywords(
        active,
        turn=int(scenario.get("turn") or 3),
        phase="source_left_battlefield",
        emit_events=True,
    )
    if battle.card_has_keyword(matching_target, keyword):
        fail("battle_execution", f"{card['name']} did not revoke {keyword} after source left")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "matching_target": matching_target.get("name"),
        "keyword": keyword,
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


def run_equipment_static_power_toughness_attachment(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    source = battle.enrich_card({**card, **battle.get_card_effect(card)})
    active = battle.Player(str(scenario.get("player") or "Equipment Controller"), None, [])
    target = dict(scenario["target"])
    active.battlefield.append(target)
    before_events = len(events)
    battle.apply_equipment_static_attachment(
        active,
        source,
        battle.get_card_effect(card),
        turn=int(scenario.get("turn") or 3),
    )
    expected_power = int(scenario["expected_power"])
    expected_toughness = int(scenario["expected_toughness"])
    if int(target.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} target power={target.get('power')}, expected {expected_power}")
    if int(target.get("toughness") or 0) != expected_toughness:
        fail("battle_execution", f"{card['name']} target toughness={target.get('toughness')}, expected {expected_toughness}")
    expected_keywords = [
        str(keyword).strip().lower().replace(" ", "_")
        for keyword in scenario.get("expected_keywords", []) or []
        if str(keyword).strip()
    ]
    missing_keywords = [
        keyword
        for keyword in expected_keywords
        if not battle.card_has_keyword(target, keyword)
    ]
    if missing_keywords:
        fail("battle_execution", f"{card['name']} target missing keywords {missing_keywords}")
    attached_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "equipment_attached"
            and data.get("card") == card.get("name")
            and data.get("target") == target.get("name")
        ),
        None,
    )
    if attached_event is None:
        fail("battle_events", f"missing {card['name']} equipment_attached event")
    source_name = str(scenario.get("expected_source") or card.get("name"))
    if attached_event.get("card") != source_name:
        fail("battle_events", f"{card['name']} attached event source={attached_event.get('card')!r}")
    grants = [str(value) for value in attached_event.get("grants", []) or []]
    for keyword in expected_keywords:
        if keyword not in grants:
            fail("battle_events", f"{card['name']} event missing grant {keyword!r}: {grants}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target": target.get("name"),
        "target_power": target.get("power"),
        "target_toughness": target.get("toughness"),
        "validated_keywords": expected_keywords,
        "attached_event": {
            "power_boost": attached_event.get("power_boost"),
            "toughness_boost": attached_event.get("toughness_boost"),
            "grants": grants,
        },
    }


def run_static_count_power_toughness(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    source = battle.enrich_card({**card, **battle.get_card_effect(card)})
    active = battle.Player(str(scenario.get("player") or "Static Count Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Static Count Opponent"), None, [])
    active.battlefield.extend(dict(card) for card in scenario.get("controller_battlefield") or [])
    active.battlefield.append(source)
    opponent.battlefield.extend(dict(card) for card in scenario.get("opponent_battlefield") or [])
    active.hand = [dict(card) for card in scenario.get("controller_hand") or []]
    opponent.hand = [dict(card) for card in scenario.get("opponent_hand") or []]
    before_events = len(events)
    battle.refresh_graveyard_count_creature_statics_for_player(
        active,
        turn=int(scenario.get("turn") or 3),
        phase="e2e_static_count_pt",
        emit_events=True,
        all_players=[active, opponent],
    )
    expected_power = int(scenario["expected_power"])
    expected_toughness = int(scenario["expected_toughness"])
    if int(source.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} power={source.get('power')}, expected {expected_power}")
    if int(source.get("toughness") or 0) != expected_toughness:
        fail("battle_execution", f"{card['name']} toughness={source.get('toughness')}, expected {expected_toughness}")
    changed_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "static_count_power_toughness_changed"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if changed_event is None:
        fail("battle_events", f"missing {card['name']} static_count_power_toughness_changed event")
    expected_count = int(scenario["expected_count"])
    if int(changed_event.get("static_count_power_toughness_count") or 0) != expected_count:
        fail(
            "battle_events",
            f"{card['name']} count={changed_event.get('static_count_power_toughness_count')}, expected {expected_count}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "power": source.get("power"),
        "toughness": source.get("toughness"),
        "count": changed_event.get("static_count_power_toughness_count"),
    }


def run_static_graveyard_threshold_source_boost(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    source = battle.enrich_card({**card, **battle.get_card_effect(card)})
    active = battle.Player(str(scenario.get("player") or "Graveyard Threshold Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Graveyard Threshold Opponent"), None, [])
    active.battlefield = [source]
    active.graveyard = [dict(card) for card in scenario.get("controller_graveyard") or []]
    opponent.graveyard = [dict(card) for card in scenario.get("opponent_graveyard") or []]
    before_events = len(events)
    battle.refresh_graveyard_count_creature_statics_for_player(
        active,
        turn=int(scenario.get("turn") or 3),
        phase="e2e_static_graveyard_threshold",
        emit_events=True,
        all_players=[active, opponent],
    )
    expected_power = int(scenario["expected_power"])
    expected_toughness = int(scenario["expected_toughness"])
    if int(source.get("power") or 0) != expected_power:
        fail("battle_execution", f"{card['name']} power={source.get('power')}, expected {expected_power}")
    if int(source.get("toughness") or 0) != expected_toughness:
        fail("battle_execution", f"{card['name']} toughness={source.get('toughness')}, expected {expected_toughness}")
    expected_active = bool(scenario.get("expected_active"))
    if bool(source.get("_static_graveyard_threshold_active")) != expected_active:
        fail(
            "battle_execution",
            f"{card['name']} active={source.get('_static_graveyard_threshold_active')}, expected {expected_active}",
        )
    changed_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "static_graveyard_threshold_source_boost_changed"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if changed_event is None:
        fail("battle_events", f"missing {card['name']} static_graveyard_threshold_source_boost_changed event")
    expected_count = int(scenario["expected_count"])
    if int(changed_event.get("graveyard_count") or 0) != expected_count:
        fail(
            "battle_events",
            f"{card['name']} graveyard_count={changed_event.get('graveyard_count')}, expected {expected_count}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "power": source.get("power"),
        "toughness": source.get("toughness"),
        "graveyard_count": changed_event.get("graveyard_count"),
        "active": source.get("_static_graveyard_threshold_active"),
    }


def run_static_cost_increase_spell_cost(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    source = battle.enrich_card(
        {
            **card,
            "type_line": scenario.get("source_type_line") or "Creature - Fixture",
            **effect,
        }
    )
    active = battle.Player(str(scenario.get("player") or "Tax Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Tax Opponent"), None, [])
    battle.bind_table_context([active, opponent])
    active.battlefield = [source]
    spell = battle.enrich_card(dict(scenario["target_spell"]))
    cost = battle.card_cost_for_player_state(active, spell)
    expected_generic = int(scenario.get("expected_generic") or 0)
    if int(cost.get("generic") or 0) != expected_generic:
        fail(
            "battle_execution",
            f"{card['name']} generic cost={cost.get('generic')}, expected {expected_generic}",
        )
    expected_colored = dict(scenario.get("expected_colored") or {})
    colored_cost = dict(cost.get("colored") or {})
    for color, expected in expected_colored.items():
        if int(colored_cost.get(color) or 0) != int(expected):
            fail(
                "battle_execution",
                f"{card['name']} {color} cost={colored_cost.get(color)}, expected {expected}",
            )
    expected_total = int(scenario.get("expected_static_cost_increase_total") or 0)
    if int(cost.get("static_cost_increase_total") or 0) != expected_total:
        fail(
            "battle_execution",
            f"{card['name']} static increase={cost.get('static_cost_increase_total')}, expected {expected_total}",
        )
    expected_symbols = list(scenario.get("expected_static_cost_increase_color_symbols") or [])
    if expected_symbols and list(cost.get("static_cost_increase_color_symbols") or []) != expected_symbols:
        fail(
            "battle_execution",
            f"{card['name']} color tax={cost.get('static_cost_increase_color_symbols')}, expected {expected_symbols}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target_spell": spell.get("name"),
        "generic": cost.get("generic"),
        "colored": colored_cost,
        "static_cost_increase_total": cost.get("static_cost_increase_total"),
        "static_cost_increase_color_symbols": cost.get("static_cost_increase_color_symbols", []),
    }


def run_static_cost_reduction_spell_cost(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    source = battle.enrich_card(
        {
            **card,
            "type_line": scenario.get("source_type_line") or "Creature - Fixture",
            **effect,
        }
    )
    active = battle.Player(str(scenario.get("player") or "Reduction Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Reduction Opponent"), None, [])
    battle.bind_table_context([active, opponent])
    active.battlefield = [source]
    spell = battle.enrich_card(dict(scenario["target_spell"]))
    cost = battle.card_cost_for_player_state(active, spell)
    expected_generic = int(scenario.get("expected_generic") or 0)
    if int(cost.get("generic") or 0) != expected_generic:
        fail(
            "battle_execution",
            f"{card['name']} generic cost={cost.get('generic')}, expected {expected_generic}",
        )
    expected_colored = dict(scenario.get("expected_colored") or {})
    colored_cost = dict(cost.get("colored") or {})
    for color, expected in expected_colored.items():
        if int(colored_cost.get(color) or 0) != int(expected):
            fail(
                "battle_execution",
                f"{card['name']} {color} cost={colored_cost.get(color)}, expected {expected}",
            )
    expected_total = int(scenario.get("expected_static_cost_reduction_total") or 0)
    if int(cost.get("static_cost_reduction_total") or 0) != expected_total:
        fail(
            "battle_execution",
            f"{card['name']} static reduction={cost.get('static_cost_reduction_total')}, expected {expected_total}",
        )
    expected_symbols = list(scenario.get("expected_static_cost_reduction_color_symbols") or [])
    if expected_symbols and list(cost.get("static_cost_reduction_color_symbols") or []) != expected_symbols:
        fail(
            "battle_execution",
            f"{card['name']} color reduction={cost.get('static_cost_reduction_color_symbols')}, expected {expected_symbols}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target_spell": spell.get("name"),
        "generic": cost.get("generic"),
        "colored": colored_cost,
        "static_cost_reduction_total": cost.get("static_cost_reduction_total"),
        "static_cost_reduction_color_symbols": cost.get("static_cost_reduction_color_symbols", []),
    }


def _controller_for_damage_source(source: dict[str, Any], active, opponent):
    return active if source.get("_controller_role") == "self" else opponent


def run_damage_prevention(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    active = battle.Player(str(scenario.get("player") or "Prevention Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    turn = int(scenario.get("turn") or 7)
    seed = int(scenario.get("seed") or 6090)
    before_events = len(events)
    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=turn,
        rng=random.Random(seed),
        effect_data_override=card,
        phase="combat_damage",
    )
    if not any(
        event == "combat_damage_prevention_created"
        and data.get("card") == card.get("name")
        for event, data in events[before_events:]
    ):
        fail("battle_events", f"missing {card['name']} combat_damage_prevention_created event")

    kind = str(scenario.get("expected_prevent_damage_kind") or "combat_damage")
    matching_source = dict(scenario["matching_source"])
    nonmatching_source = dict(scenario.get("nonmatching_source") or {})

    if kind == "all_damage":
        matching_controller = _controller_for_damage_source(matching_source, active, opponent)
        matching_source["controller"] = matching_controller.name
        life_before = active.life
        dealt, final_amount, did_deal = battle.deal_damage_to_player_with_static_replacements(
            matching_controller,
            active,
            matching_source,
            int(scenario.get("matching_damage") or 5),
            turn=turn,
            phase="postcombat_main",
            damage_event_type="player",
        )
        if (dealt, final_amount, did_deal) != (0, 0, False) or active.life != life_before:
            fail(
                "battle_execution",
                f"{card['name']} matching all-damage source was not prevented: dealt={dealt} final={final_amount} life={active.life}",
            )
        if nonmatching_source:
            nonmatching_controller = _controller_for_damage_source(nonmatching_source, active, opponent)
            nonmatching_source["controller"] = nonmatching_controller.name
            target_player = active if nonmatching_controller is opponent else opponent
            nonmatching_life_before = target_player.life
            dealt, final_amount, did_deal = battle.deal_damage_to_player_with_static_replacements(
                nonmatching_controller,
                target_player,
                nonmatching_source,
                int(scenario.get("nonmatching_damage") or 3),
                turn=turn,
                phase="postcombat_main",
                damage_event_type="player",
            )
            if not did_deal or final_amount <= 0 or target_player.life >= nonmatching_life_before:
                fail(
                    "battle_execution",
                    f"{card['name']} nonmatching all-damage source was incorrectly prevented",
                )
        replacement = next(
            (
                data
                for event, data in events[before_events:]
                if event == "static_damage_replacement_applied"
                and data.get("source") == matching_source.get("name")
                and data.get("final_amount") == 0
            ),
            None,
        )
        if replacement is None:
            fail("battle_events", f"missing {card['name']} static damage prevention event")
        return {
            "scenario": scenario.get("name"),
            "card_name": card["name"],
            "prevent_damage_kind": kind,
            "matching_source": matching_source.get("name"),
            "nonmatching_source": nonmatching_source.get("name"),
            "matching_damage_prevented": True,
        }

    if kind != "combat_damage":
        fail("battle_execution", f"{card['name']} unsupported prevention kind {kind!r}")

    matching_source.setdefault("controller", opponent.name)
    matching_source.pop("_controller_role", None)
    nonmatching_source.setdefault("controller", opponent.name)
    if nonmatching_source.get("_combat_role") == "blocking":
        opponent.battlefield = [matching_source]
        active.battlefield = [nonmatching_source]
        battle.combat_damage_steps(
            opponent,
            [active],
            active,
            [matching_source],
            [(matching_source, [nonmatching_source])],
            turn=turn,
            rng=random.Random(seed),
            all_players=[opponent, active],
        )
        if int(nonmatching_source.get("damage_marked_this_turn") or 0) != 0:
            fail("battle_execution", f"{card['name']} attacking-source damage was not prevented")
        if int(matching_source.get("damage_marked_this_turn") or 0) <= 0:
            fail("battle_execution", f"{card['name']} blocking-source damage was incorrectly prevented")
        nonmatching_result = "blocking_damage_allowed"
    else:
        combat_sources = [matching_source]
        if nonmatching_source and "creature" in str(nonmatching_source.get("type_line") or "").lower():
            combat_sources.append(nonmatching_source)
        opponent.battlefield = combat_sources
        battle.combat_damage_steps(
            opponent,
            [active],
            active,
            combat_sources,
            [(source, []) for source in combat_sources],
            turn=turn,
            rng=random.Random(seed),
            all_players=[opponent, active],
        )
        expected_nonmatching_damage = (
            int(nonmatching_source.get("power") or 0)
            if len(combat_sources) > 1 and combat_sources[1] is nonmatching_source
            else 0
        )
        expected_life = 40 - expected_nonmatching_damage
        if active.life != expected_life:
            fail(
                "battle_execution",
                f"{card['name']} combat prevention life={active.life}, expected {expected_life}",
            )
        nonmatching_result = "nonmatching_combat_damage_allowed" if expected_nonmatching_damage else "no_combat_nonmatch"

    prevented_event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "combat_damage_prevented"
            and data.get("source") == matching_source.get("name")
        ),
        None,
    )
    if prevented_event is None:
        fail("battle_events", f"missing {card['name']} combat_damage_prevented event")

    life_before_noncombat = active.life
    dealt, final_amount, did_deal = battle.deal_damage_to_player_with_static_replacements(
        opponent,
        active,
        matching_source,
        int(scenario.get("noncombat_probe_damage") or 2),
        turn=turn,
        phase="postcombat_main",
        damage_event_type="player",
    )
    if not did_deal or final_amount <= 0 or active.life >= life_before_noncombat:
        fail("battle_execution", f"{card['name']} combat-only prevention stopped noncombat damage")

    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "prevent_damage_kind": kind,
        "matching_source": matching_source.get("name"),
        "nonmatching_source": nonmatching_source.get("name"),
        "matching_combat_damage_prevented": True,
        "nonmatching_result": nonmatching_result,
    }


def run_combat_damage_draw(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = battle.get_card_effect(card)
    source = battle.enrich_card(
        {
            **card,
            "type_line": card.get("type_line") or "Creature - E2E Fixture",
            "summoning_sick": False,
            **effect,
        }
    )
    active = battle.Player(str(scenario.get("player") or "Combat Draw Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Combat Draw Opponent"), None, [])
    active.hand = [
        battle.enrich_card(dict(hand_card))
        for hand_card in (scenario.get("controller_hand") or [])
        if isinstance(hand_card, dict)
    ]
    active.library = [
        battle.enrich_card(dict(library_card))
        for library_card in (scenario.get("controller_library") or [])
        if isinstance(library_card, dict)
    ]
    active.battlefield.append(source)
    starting_hand_count = len(active.hand)
    starting_library_count = len(active.library)
    expected_draw_count = int(scenario.get("expected_draw_count") or effect.get("combat_damage_draw_count") or 1)
    expected_discard_count = int(scenario.get("expected_discard_count") or 0)
    expected_source_sacrificed = bool(scenario.get("expected_source_sacrificed"))
    expected_optional_cost = scenario.get("expected_optional_cost")
    before_events = len(events)

    resolved = battle.resolve_combat_damage_draw_triggers(
        active,
        [source],
        opponent,
        turn=int(scenario.get("turn") or 6160),
        phase=str(scenario.get("phase") or "combat_damage"),
        rng=random.Random(int(scenario.get("seed") or 6160)),
        all_players=[active, opponent],
    )

    if len(resolved) != 1:
        fail("battle_execution", f"{card['name']} combat damage draw did not resolve")
    if len(active.library) != starting_library_count - expected_draw_count:
        fail(
            "battle_execution",
            f"{card['name']} library={len(active.library)}, expected {starting_library_count - expected_draw_count}",
        )
    expected_hand_count = starting_hand_count - expected_discard_count + expected_draw_count
    if len(active.hand) != expected_hand_count:
        fail("battle_execution", f"{card['name']} hand={len(active.hand)}, expected {expected_hand_count}")
    if expected_discard_count:
        discarded_names = [entry.get("name", "?") for entry in active.graveyard if isinstance(entry, dict)]
        if len(discarded_names) < expected_discard_count:
            fail("battle_execution", f"{card['name']} did not move discard cost to graveyard")
    if expected_source_sacrificed:
        if source in active.battlefield:
            fail("battle_execution", f"{card['name']} source was not sacrificed")
        if not any(entry is source for entry in active.graveyard):
            fail("battle_execution", f"{card['name']} sacrificed source not in graveyard")

    event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "combat_damage_draw_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} combat_damage_draw_resolved event")
    if int(event.get("cards_drawn") or 0) != expected_draw_count:
        fail("battle_events", f"{card['name']} cards_drawn={event.get('cards_drawn')}")
    if expected_optional_cost and event.get("optional_cost") != expected_optional_cost:
        fail("battle_events", f"{card['name']} optional_cost={event.get('optional_cost')!r}")
    if expected_optional_cost and event.get("optional_cost_paid") is not True:
        fail("battle_events", f"{card['name']} optional cost was not marked paid")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "cards_drawn": expected_draw_count,
        "optional_cost": expected_optional_cost,
        "source_sacrificed": expected_source_sacrificed,
    }


def run_target_player_draw_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = dict(battle.get_card_effect(card))
    if effect.get("effect") != "draw_cards":
        fail("battle_execution", f"{card['name']} effect={effect.get('effect')!r}")
    if effect.get("target_player_draw") is not True:
        fail("battle_execution", f"{card['name']} is not marked target_player_draw")
    x_value = scenario.get("x_value")
    if x_value is not None:
        x_value = int(x_value)
        effect["x_value"] = x_value
        effect["_cast_context"] = {"x_value": x_value}
        card["x_value"] = x_value
        card["_cast_context"] = {"x_value": x_value}
    active = battle.Player(str(scenario.get("player") or "Spell Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.library = [
        battle.enrich_card(dict(library_card))
        for library_card in (scenario.get("controller_library") or scenario.get("library") or [])
        if isinstance(library_card, dict)
    ]
    active.hand = [
        battle.enrich_card(dict(hand_card))
        for hand_card in (scenario.get("controller_hand") or [])
        if isinstance(hand_card, dict)
    ]
    starting_hand_count = len(active.hand)
    starting_library_count = len(active.library)
    expected_draw_count = int(scenario.get("expected_draw_count") or effect.get("draw_count") or effect.get("count") or 1)
    expected_target_player = str(scenario.get("expected_target_player") or active.name)
    before_events = len(events)

    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card(card),
        turn=int(scenario.get("turn") or 6170),
        rng=random.Random(int(scenario.get("seed") or 6170)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )

    shuffled_self = validate_shuffle_self_into_library_if_expected(
        scenario,
        events,
        before_events,
        active,
        card,
    )
    expected_library_count = starting_library_count - expected_draw_count + (1 if shuffled_self else 0)
    if len(active.library) != expected_library_count:
        fail(
            "battle_execution",
            f"{card['name']} library={len(active.library)}, expected {expected_library_count}",
        )
    expected_hand_count = starting_hand_count + expected_draw_count
    if len(active.hand) != expected_hand_count:
        fail("battle_execution", f"{card['name']} hand={len(active.hand)}, expected {expected_hand_count}")
    event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "draw_cards_resolved"
            and data.get("card") == card.get("name")
            and data.get("target_player_draw") is True
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} draw_cards_resolved event")
    if event.get("target_player") != expected_target_player:
        fail("battle_events", f"{card['name']} target_player={event.get('target_player')!r}")
    if int(event.get("cards_drawn") or 0) != expected_draw_count:
        fail("battle_events", f"{card['name']} cards_drawn={event.get('cards_drawn')}")
    if int(event.get("requested_draw_count") or 0) != expected_draw_count:
        fail("battle_events", f"{card['name']} requested_draw_count={event.get('requested_draw_count')}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "target_player": expected_target_player,
        "cards_drawn": expected_draw_count,
        "x_value": x_value,
        "shuffled_self_into_library": shuffled_self,
    }


def run_fixed_draw_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = dict(battle.get_card_effect(card))
    if effect.get("effect") != "draw_cards":
        fail("battle_execution", f"{card['name']} effect={effect.get('effect')!r}")
    active = battle.Player(str(scenario.get("player") or "Spell Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.library = [
        battle.enrich_card(dict(library_card))
        for library_card in (scenario.get("controller_library") or scenario.get("library") or [])
        if isinstance(library_card, dict)
    ]
    active.hand = [
        battle.enrich_card(dict(hand_card))
        for hand_card in (scenario.get("controller_hand") or [])
        if isinstance(hand_card, dict)
    ]
    active.battlefield = [
        battle.enrich_card(dict(permanent))
        for permanent in (scenario.get("controller_battlefield") or [])
        if isinstance(permanent, dict)
    ]
    starting_hand_count = len(active.hand)
    starting_library_count = len(active.library)
    expected_draw_count = int(scenario.get("expected_draw_count") or effect.get("draw_count") or effect.get("count") or 1)
    expected_sacrificed_names = [
        str(name)
        for name in (scenario.get("expected_sacrificed_names") or [])
        if str(name)
    ]
    before_events = len(events)

    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card(card),
        turn=int(scenario.get("turn") or 6171),
        rng=random.Random(int(scenario.get("seed") or 6171)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )

    if len(active.library) != starting_library_count - expected_draw_count:
        fail(
            "battle_execution",
            f"{card['name']} library={len(active.library)}, expected {starting_library_count - expected_draw_count}",
        )
    expected_hand_count = starting_hand_count + expected_draw_count
    if len(active.hand) != expected_hand_count:
        fail("battle_execution", f"{card['name']} hand={len(active.hand)}, expected {expected_hand_count}")
    event = next(
        (
            data
            for event, data in events[before_events:]
            if event == "draw_cards_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} draw_cards_resolved event")
    if int(event.get("cards_drawn") or 0) != expected_draw_count:
        fail("battle_events", f"{card['name']} cards_drawn={event.get('cards_drawn')}")
    if int(event.get("requested_draw_count") or 0) != expected_draw_count:
        fail("battle_events", f"{card['name']} requested_draw_count={event.get('requested_draw_count')}")
    expected_additional_cost = str(scenario.get("expected_additional_cost") or "").strip()
    if expected_additional_cost:
        additional_cost_event = next(
            (
                data
                for event, data in events[before_events:]
                if event == "additional_cost_paid"
                and data.get("card") == card.get("name")
                and data.get("cost") == expected_additional_cost
            ),
            None,
        )
        if additional_cost_event is None:
            fail(
                "battle_events",
                f"missing {card['name']} additional_cost_paid {expected_additional_cost}",
            )
    if expected_sacrificed_names:
        battlefield_names = [
            str(permanent.get("name") or "")
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        ]
        graveyard_names = [
            str(permanent.get("name") or "")
            for permanent in active.graveyard
            if isinstance(permanent, dict)
        ]
        for expected_name in expected_sacrificed_names:
            if expected_name in battlefield_names or expected_name not in graveyard_names:
                fail("battle_execution", f"{card['name']} did not sacrifice {expected_name}")
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "cards_drawn": expected_draw_count,
        "additional_cost": expected_additional_cost or None,
        "sacrificed": expected_sacrificed_names,
    }


def run_fixed_draw_discard_spell(
    battle,
    scenario: dict[str, Any],
    events: list[tuple[str, dict[str, Any]]],
) -> dict[str, Any]:
    card = dict(scenario["card"])
    effect = dict(battle.get_card_effect(card))
    if effect.get("effect") != "draw_cards" or not effect.get("draw_discard_spell"):
        fail("battle_execution", f"{card['name']} draw_discard_spell={effect.get('draw_discard_spell')!r}")
    active = battle.Player(str(scenario.get("player") or "Spell Controller"), None, [])
    opponent = battle.Player(str(scenario.get("opponent") or "Opponent"), None, [])
    active.library = [
        battle.enrich_card(dict(library_card))
        for library_card in (scenario.get("controller_library") or scenario.get("library") or [])
        if isinstance(library_card, dict)
    ]
    active.hand = [
        battle.enrich_card(dict(hand_card))
        for hand_card in (scenario.get("controller_hand") or [])
        if isinstance(hand_card, dict)
    ]
    starting_hand_count = len(active.hand)
    starting_library_count = len(active.library)
    expected_draw_count = int(
        scenario.get("expected_draw_count") or effect.get("draw_count") or effect.get("count") or 0
    )
    expected_discard_count = int(scenario.get("expected_discard_count") or effect.get("discard_count") or 0)
    expected_order = str(scenario.get("expected_draw_discard_order") or effect.get("draw_discard_order") or "draw_then_discard")
    expected_discard_random = bool(scenario.get("expected_discard_random", effect.get("discard_random")))
    before_events = len(events)

    battle.apply_effect_immediate(
        active,
        [opponent],
        battle.enrich_card(card),
        turn=int(scenario.get("turn") or 7140),
        rng=random.Random(int(scenario.get("seed") or 7140)),
        effect_data_override=effect,
        phase=str(scenario.get("phase") or "precombat_main"),
    )

    if len(active.library) != starting_library_count - expected_draw_count:
        fail(
            "battle_execution",
            f"{card['name']} library={len(active.library)}, expected {starting_library_count - expected_draw_count}",
        )
    expected_hand_count = starting_hand_count + expected_draw_count - expected_discard_count
    if len(active.hand) != expected_hand_count:
        fail("battle_execution", f"{card['name']} hand={len(active.hand)}, expected {expected_hand_count}")
    event = next(
        (
            data
            for event_name, data in events[before_events:]
            if event_name == "draw_discard_spell_resolved"
            and data.get("card") == card.get("name")
        ),
        None,
    )
    if event is None:
        fail("battle_events", f"missing {card['name']} draw_discard_spell_resolved event")
    if int(event.get("cards_drawn") or 0) != expected_draw_count:
        fail("battle_events", f"{card['name']} cards_drawn={event.get('cards_drawn')}")
    if int(event.get("requested_draw_count") or 0) != expected_draw_count:
        fail("battle_events", f"{card['name']} requested_draw_count={event.get('requested_draw_count')}")
    if int(event.get("cards_discarded") or 0) != expected_discard_count:
        fail("battle_events", f"{card['name']} cards_discarded={event.get('cards_discarded')}")
    if int(event.get("requested_discard_count") or 0) != expected_discard_count:
        fail("battle_events", f"{card['name']} requested_discard_count={event.get('requested_discard_count')}")
    if str(event.get("order") or "") != expected_order:
        fail("battle_events", f"{card['name']} order={event.get('order')!r}, expected {expected_order!r}")
    if bool(event.get("discard_random")) != expected_discard_random:
        fail(
            "battle_events",
            f"{card['name']} discard_random={event.get('discard_random')!r}, expected {expected_discard_random!r}",
        )
    return {
        "scenario": scenario.get("name"),
        "card_name": card["name"],
        "cards_drawn": expected_draw_count,
        "cards_discarded": expected_discard_count,
        "discard_random": expected_discard_random,
        "order": expected_order,
    }


SCENARIO_RUNNERS = {
    "attack_self_boost": run_attack_self_boost,
    "aura_static_power_toughness_attachment": run_aura_static_power_toughness_attachment,
    "equipment_static_power_toughness_attachment": run_equipment_static_power_toughness_attachment,
    "becomes_blocked_self_boost": run_becomes_blocked_self_boost,
    "board_wipe": run_board_wipe,
    "combat_damage_draw": run_combat_damage_draw,
    "mass_return_to_hand": run_mass_return_to_hand,
    "conditional_land_play": run_conditional_land_play,
    "counter_unless_pays_response": run_counter_unless_pays_response,
    "copy_stack_ability_response": run_copy_stack_ability_response,
    "copy_spell_choose_new_targets": run_copy_spell_choose_new_targets,
    "change_single_target_response": run_change_single_target_response,
    "damage_wipe": run_damage_wipe,
    "creature_dies_create_treasure": run_creature_dies_create_treasure,
    "creature_dies_add_counters": run_creature_dies_add_counters,
    "creature_dies_create_tokens": run_creature_dies_create_tokens,
    "creature_dies_each_player_sacrifice": run_creature_dies_each_player_sacrifice,
    "creature_etb_fixed_mana": run_creature_etb_fixed_mana,
    "creature_etb_create_treasure": run_creature_etb_create_treasure,
    "creature_etb_create_tokens": run_creature_etb_create_tokens,
    "creature_etb_dynamic_life_gain": run_creature_etb_dynamic_life_gain,
    "creature_etb_draw_discard": run_creature_etb_draw_discard,
    "creature_etb_target_stat_modifier": run_creature_etb_target_stat_modifier,
    "creature_etb_library_pick": run_creature_etb_library_pick,
    "creature_enters_draw": run_creature_enters_draw,
    "creature_enters_life_gain": run_creature_enters_life_gain,
    "creature_etb_scry": run_creature_etb_scry,
    "destroy_target_create_treasure": run_destroy_target_create_treasure,
    "damage_target_create_treasure": run_damage_target_create_treasure,
    "damage_prevention": run_damage_prevention,
    "fixed_draw_spell": run_fixed_draw_spell,
    "fixed_draw_discard_spell": run_fixed_draw_discard_spell,
    "fixed_damage_target_spell": run_fixed_damage_target_spell,
    "dynamic_life_gain": run_dynamic_life_gain,
    "each_player_sacrifice": run_each_player_sacrifice,
    "fixed_create_creature_tokens": run_fixed_create_creature_tokens,
    "mana_source_life_cost_spend": run_mana_source_life_cost_spend,
    "modal_damage_or_destroy": run_modal_damage_or_destroy,
    "multi_create_creature_tokens": run_multi_create_creature_tokens,
    "multi_target_damage": run_multi_target_damage,
    "nonfliers_cant_block_rider": run_nonfliers_cant_block_rider,
    "remove_permanent_basic_land_compensation": run_remove_permanent_basic_land_compensation,
    "single_target_removal": run_single_target_removal,
    "single_target_removal_and_draw": run_single_target_removal_and_draw,
    "single_target_removal_and_surveil": run_single_target_removal_and_surveil,
    "multi_target_removal": run_multi_target_removal,
    "simple_mana_source_refresh": run_simple_mana_source_refresh,
    "sacrifice_mana_source_activation": run_sacrifice_mana_source_activation,
    "simple_activated_draw": run_simple_activated_draw,
    "simple_activated_draw_discard": run_simple_activated_draw_discard,
    "simple_activated_damage": run_simple_activated_damage,
    "simple_activated_tap_target": run_simple_activated_tap_target,
    "simple_activated_untap_target": run_simple_activated_untap_target,
    "tap_target_spell": run_tap_target_spell,
    "gain_control_untap_haste_until_eot": run_gain_control_untap_haste_until_eot,
    "stat_modifier_until_eot_untap_target": run_stat_modifier_until_eot_untap_target,
    "add_counters_target_spell": run_add_counters_target_spell,
    "add_counters_untap_target_spell": run_add_counters_untap_target_spell,
    "target_player_draw_spell": run_target_player_draw_spell,
    "target_keyword_draw_spell": run_target_keyword_draw_spell,
    "simple_activated_add_counters_target": run_simple_activated_add_counters_target,
    "simple_activated_add_counters_self": run_simple_activated_add_counters_self,
    "simple_activated_destroy": run_simple_activated_destroy,
    "simple_activated_target_keyword": run_simple_activated_target_keyword,
    "simple_activated_self_boost": run_simple_activated_self_boost,
    "simple_activated_self_keyword": run_simple_activated_self_keyword,
    "simple_activated_regenerate_source": run_simple_activated_regenerate_source,
    "simple_activated_regenerate_target": run_simple_activated_regenerate_target,
    "damage_each_opponent_spell": run_damage_each_opponent_spell,
    "damage_each_opponent_and_their_permanents_spell": run_damage_each_opponent_and_their_permanents_spell,
    "damage_gain_life_spell": run_damage_gain_life_spell,
    "simple_activated_create_token": run_simple_activated_create_token,
    "spell_cast_gain_life": run_spell_cast_gain_life,
    "spell_cast_token_maker": run_spell_cast_token_maker,
    "controlled_stat_modifier_until_eot": run_controlled_stat_modifier_until_eot,
    "counter_target_response": run_counter_target_response,
    "stat_modifier_until_eot": run_stat_modifier_until_eot,
    "boost_scry_spell": run_boost_scry_spell,
    "global_stat_modifier_draw_spell": run_global_stat_modifier_draw_spell,
    "proliferate_draw_spell": run_proliferate_draw_spell,
    "static_controlled_power_toughness_boost": run_static_controlled_power_toughness_boost,
    "static_controlled_keyword": run_static_controlled_keyword,
    "static_graveyard_threshold_source_boost": run_static_graveyard_threshold_source_boost,
    "static_cost_increase_spell_cost": run_static_cost_increase_spell_cost,
    "static_cost_reduction_spell_cost": run_static_cost_reduction_spell_cost,
    "static_count_power_toughness": run_static_count_power_toughness,
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
