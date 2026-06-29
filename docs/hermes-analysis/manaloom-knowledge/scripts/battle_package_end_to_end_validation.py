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
import random
import sqlite3
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import db_helper


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_SQLITE_DB = SCRIPT_DIR / "knowledge.db"
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
    checks = manifest.get("snapshot_checks") or []
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
    checks = manifest.get("runtime_checks") or []
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
    if not copied_targets:
        fail("battle_execution", f"{copy_card['name']} copied effect missing declared targets")
    expected_target_name = str(scenario.get("expected_copy_target") or alternate_target.get("name"))
    actual_target = copied_targets[0].get("target") if isinstance(copied_targets[0], dict) else None
    actual_target_name = actual_target.get("name") if isinstance(actual_target, dict) else None
    if actual_target_name != expected_target_name:
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
    if spell_copied.get("copy_spell_target") != expected_target_name:
        fail(
            "battle_events",
            f"{copy_card['name']} event copy_spell_target={spell_copied.get('copy_spell_target')!r}",
        )
    buyback_result = None
    if "expected_buyback_paid" in scenario:
        expected_buyback_paid = bool(scenario.get("expected_buyback_paid"))
        spell_cast = next(
            (
                data
                for event, data in reversed(events)
                if event == "spell_cast" and data.get("card") == copy_card.get("name")
            ),
            None,
        )
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
        **({"buyback": buyback_result} if buyback_result is not None else {}),
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
    return {
        "scenario": scenario.get("name"),
        "card_name": response_card["name"],
        "old_target": protected.get("name"),
        "new_target": actual_target_name,
        "target_change_applied": True,
        "target_change_pipeline": redirect_event.get("target_change_pipeline"),
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


SCENARIO_RUNNERS = {
    "conditional_land_play": run_conditional_land_play,
    "copy_spell_choose_new_targets": run_copy_spell_choose_new_targets,
    "change_single_target_response": run_change_single_target_response,
    "mana_source_life_cost_spend": run_mana_source_life_cost_spend,
    "nonfliers_cant_block_rider": run_nonfliers_cant_block_rider,
    "remove_permanent_basic_land_compensation": run_remove_permanent_basic_land_compensation,
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
                "name": "battle_execution_no_override",
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
