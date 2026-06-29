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


def expected_rules_by_key(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    rules = manifest.get("expected_rules") or []
    by_key: dict[str, dict[str, Any]] = {}
    for rule in rules:
        logical_key = str(rule.get("logical_rule_key") or "").strip()
        if not logical_key:
            fail("manifest", "expected_rules entry missing logical_rule_key")
        if logical_key in by_key:
            fail("manifest", f"duplicate expected rule {logical_key}")
        by_key[logical_key] = dict(rule)
    if not by_key:
        fail("manifest", "expected_rules must not be empty")
    return by_key


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


def fetch_postgres_rows(logical_keys: list[str]) -> dict[str, dict[str, Any]]:
    with closing(db_helper.connect()) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT normalized_name, logical_rule_key, card_name, effect_json,
                       source, confidence, review_status, execution_status,
                       rule_version, oracle_hash, reviewed_by
                FROM public.card_battle_rules
                WHERE logical_rule_key IN %s
                ORDER BY logical_rule_key
                """,
                (tuple(logical_keys),),
            )
            columns = [desc[0] for desc in cur.description]
            return {
                row[columns.index("logical_rule_key")]: dict(zip(columns, row))
                for row in cur.fetchall()
            }


def validate_postgres(expected_by_key: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    rows = fetch_postgres_rows(list(expected_by_key))
    missing = sorted(set(expected_by_key) - set(rows))
    if missing:
        fail("postgres", f"missing expected rows: {missing}")
    return [
        validate_rule_row("postgres", key, rows[key], expected_by_key[key])
        for key in expected_by_key
    ]


def validate_sqlite(path: Path, expected_by_key: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    if not path.exists():
        fail("sqlite", f"missing db {path}")
    placeholders = ",".join("?" for _ in expected_by_key)
    with closing(sqlite3.connect(path)) as conn:
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            f"""
            SELECT normalized_name, logical_rule_key, card_name, effect_json,
                   source, confidence, review_status, execution_status,
                   rule_version, oracle_hash
            FROM battle_card_rules
            WHERE logical_rule_key IN ({placeholders})
            ORDER BY logical_rule_key
            """,
            tuple(expected_by_key),
        ).fetchall()
    by_key = {row["logical_rule_key"]: dict(row) for row in rows}
    missing = sorted(set(expected_by_key) - set(by_key))
    if missing:
        fail("sqlite", f"missing expected rows: {missing}")
    return [
        validate_rule_row("sqlite", key, by_key[key], expected_by_key[key])
        for key in expected_by_key
    ]


def validate_snapshot(path: Path, manifest: dict[str, Any], expected_by_key: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
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
        expected = {**expected_by_key.get(logical_key, {}), **check}
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


SCENARIO_RUNNERS = {
    "remove_permanent_basic_land_compensation": run_remove_permanent_basic_land_compensation,
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
