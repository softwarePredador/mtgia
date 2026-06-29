#!/usr/bin/env python3
"""End-to-end validation for the PGC060 runtime annotation promotion.

This gate proves the package across the real source chain:

PostgreSQL -> SQLite/Hermes cache -> canonical fallback snapshot ->
battle runtime lookup -> execution events.
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

FURYGALE_KEY = "battle_rule_v1:63b66f50aad09aa5669ac693b2fca7e5"
TEMPT_TOKEN_KEY = "battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86"
TEMPT_DRAW_KEY = "battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80"

EXPECTED_RULES: dict[str, dict[str, Any]] = {
    FURYGALE_KEY: {
        "card_name": "Furygale Flocking",
        "normalized_name": "furygale flocking",
        "oracle_hash": "8946b0e85c8430c6105ea70c7fb2724a",
        "min_rule_version": 4,
        "fields": {
            "effect": "token_maker",
            "attack_each_opponent_this_turn_status": "runtime_executor_v1",
            "cost_reduction_status": "runtime_executor_v1",
            "token_count_per_opponent": 2,
            "battle_model_scope": (
                "per_opponent_two_3_3_flying_hasty_elementals_"
                "graveyard_cost_reduction_runtime_attack_requirement_v1"
            ),
            "oracle_runtime_scope": (
                "graveyard_instant_sorcery_cost_reduction_runtime_"
                "per_opponent_tokens_attack_requirement_v1"
            ),
        },
    },
    TEMPT_TOKEN_KEY: {
        "card_name": "Tempt with Bunnies",
        "normalized_name": "tempt with bunnies",
        "oracle_hash": "201f6c7234bfef550f3d497e736f0d7a",
        "min_rule_version": 3,
        "fields": {
            "effect": "token_maker",
            "tempting_offer_opponent_choice_status": "runtime_executor_v1",
            "battle_model_scope": "tempting_offer_base_create_1_1_white_rabbit_component_runtime_v1",
            "oracle_runtime_scope": "tempting_offer_base_create_1_1_white_rabbit_opponent_choice_runtime_v1",
            "token_name": "Rabbit Token",
            "token_count": 1,
        },
    },
    TEMPT_DRAW_KEY: {
        "card_name": "Tempt with Bunnies",
        "normalized_name": "tempt with bunnies",
        "oracle_hash": "201f6c7234bfef550f3d497e736f0d7a",
        "min_rule_version": 3,
        "fields": {
            "effect": "draw_cards",
            "tempting_offer_opponent_choice_status": "runtime_executor_v1",
            "battle_model_scope": "tempting_offer_base_draw_one_component_runtime_v1",
            "oracle_runtime_scope": "tempting_offer_base_draw_one_opponent_choice_runtime_v1",
            "count": 1,
        },
    },
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sqlite-db", default=str(DEFAULT_SQLITE_DB))
    parser.add_argument("--snapshot", default=str(DEFAULT_SNAPSHOT))
    parser.add_argument("--battle-path", default=str(DEFAULT_BATTLE))
    parser.add_argument("--output-json")
    parser.add_argument("--output-md")
    return parser.parse_args()


def fail(stage: str, detail: str) -> None:
    raise AssertionError(f"{stage}: {detail}")


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


def validate_rule_row(stage: str, logical_key: str, row: dict[str, Any]) -> dict[str, Any]:
    expected = EXPECTED_RULES[logical_key]
    effect_json = row.get("effect_json") or {}
    if isinstance(effect_json, str):
        effect_json = json.loads(effect_json)
    if row.get("normalized_name") != expected["normalized_name"]:
        fail(stage, f"{logical_key} normalized_name={row.get('normalized_name')!r}")
    if row.get("oracle_hash") != expected["oracle_hash"]:
        fail(stage, f"{logical_key} oracle_hash={row.get('oracle_hash')!r}")
    if row.get("review_status") != "verified":
        fail(stage, f"{logical_key} review_status={row.get('review_status')!r}")
    if row.get("execution_status") != "auto":
        fail(stage, f"{logical_key} execution_status={row.get('execution_status')!r}")
    if int(row.get("rule_version") or 0) < int(expected["min_rule_version"]):
        fail(stage, f"{logical_key} rule_version={row.get('rule_version')!r}")
    for field, expected_value in expected["fields"].items():
        if effect_json.get(field) != expected_value:
            fail(
                stage,
                f"{logical_key} {field}={effect_json.get(field)!r}, expected {expected_value!r}",
            )
    annotations = collect_annotation_fields(effect_json)
    if annotations:
        fail(stage, f"{logical_key} still has annotation_only fields: {annotations}")
    return {
        "logical_rule_key": logical_key,
        "card_name": row.get("card_name"),
        "review_status": row.get("review_status"),
        "execution_status": row.get("execution_status"),
        "rule_version": int(row.get("rule_version") or 0),
        "oracle_hash": row.get("oracle_hash"),
        "battle_model_scope": effect_json.get("battle_model_scope"),
        "annotation_fields": annotations,
    }


def fetch_postgres_rows() -> dict[str, dict[str, Any]]:
    logical_keys = tuple(EXPECTED_RULES)
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
                (logical_keys,),
            )
            columns = [desc[0] for desc in cur.description]
            return {
                row[columns.index("logical_rule_key")]: dict(zip(columns, row))
                for row in cur.fetchall()
            }


def validate_postgres() -> list[dict[str, Any]]:
    rows = fetch_postgres_rows()
    missing = sorted(set(EXPECTED_RULES) - set(rows))
    if missing:
        fail("postgres", f"missing expected rows: {missing}")
    return [validate_rule_row("postgres", key, rows[key]) for key in EXPECTED_RULES]


def validate_sqlite(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        fail("sqlite", f"missing db {path}")
    with closing(sqlite3.connect(path)) as conn:
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            """
            SELECT normalized_name, logical_rule_key, card_name, effect_json,
                   source, confidence, review_status, execution_status,
                   rule_version, oracle_hash
            FROM battle_card_rules
            WHERE logical_rule_key IN (?, ?, ?)
            ORDER BY logical_rule_key
            """,
            tuple(EXPECTED_RULES),
        ).fetchall()
    by_key = {row["logical_rule_key"]: dict(row) for row in rows}
    missing = sorted(set(EXPECTED_RULES) - set(by_key))
    if missing:
        fail("sqlite", f"missing expected rows: {missing}")
    return [validate_rule_row("sqlite", key, by_key[key]) for key in EXPECTED_RULES]


def validate_snapshot(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        fail("snapshot", f"missing snapshot {path}")
    snapshot = json.loads(path.read_text(encoding="utf-8"))
    checks = {
        "Furygale Flocking": FURYGALE_KEY,
        "Tempt with Bunnies": TEMPT_DRAW_KEY,
    }
    results: list[dict[str, Any]] = []
    for card_name, logical_key in checks.items():
        entry = snapshot.get(card_name)
        if not isinstance(entry, dict):
            fail("snapshot", f"missing card {card_name}")
        expected = EXPECTED_RULES[logical_key]
        if entry.get("battle_rule_logical_key") != logical_key:
            fail("snapshot", f"{card_name} logical key={entry.get('battle_rule_logical_key')!r}")
        if entry.get("battle_rule_oracle_hash") != expected["oracle_hash"]:
            fail("snapshot", f"{card_name} oracle hash={entry.get('battle_rule_oracle_hash')!r}")
        if entry.get("battle_rule_review_status") != "verified":
            fail("snapshot", f"{card_name} review={entry.get('battle_rule_review_status')!r}")
        if entry.get("battle_rule_execution_status") != "auto":
            fail("snapshot", f"{card_name} execution={entry.get('battle_rule_execution_status')!r}")
        if int(entry.get("battle_rule_version") or 0) < int(expected["min_rule_version"]):
            fail("snapshot", f"{card_name} version={entry.get('battle_rule_version')!r}")
        for field, expected_value in expected["fields"].items():
            if entry.get(field) != expected_value:
                fail("snapshot", f"{card_name} {field}={entry.get(field)!r}")
        annotations = collect_annotation_fields(entry)
        if annotations:
            fail("snapshot", f"{card_name} still has annotation_only fields: {annotations}")
        results.append({
            "card_name": card_name,
            "logical_rule_key": logical_key,
            "battle_rule_version": int(entry.get("battle_rule_version") or 0),
            "battle_model_scope": entry.get("battle_model_scope"),
            "annotation_fields": annotations,
        })
    return results


def event_payloads(events: list[tuple[str, dict[str, Any]]], event_name: str, card_name: str) -> list[dict[str, Any]]:
    return [
        data
        for event, data in events
        if event == event_name and data.get("card") == card_name
    ]


def validate_runtime_lookup(battle) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    furygale = battle.get_card_effect({"name": "Furygale Flocking", "type_line": "Sorcery", "cmc": 10})
    if furygale.get("_rule_logical_key") != FURYGALE_KEY:
        fail("runtime_lookup", f"Furygale key={furygale.get('_rule_logical_key')!r}")
    for field, expected_value in EXPECTED_RULES[FURYGALE_KEY]["fields"].items():
        if furygale.get(field) != expected_value:
            fail("runtime_lookup", f"Furygale {field}={furygale.get(field)!r}")
    annotations = collect_annotation_fields(furygale)
    if annotations:
        fail("runtime_lookup", f"Furygale annotation fields: {annotations}")
    results.append({
        "card_name": "Furygale Flocking",
        "effect": furygale.get("effect"),
        "logical_rule_key": furygale.get("_rule_logical_key"),
        "runtime_executor_present": True,
        "annotation_fields": annotations,
    })

    tempt = battle.get_card_effect({"name": "Tempt with Bunnies", "type_line": "Sorcery", "cmc": 3})
    if tempt.get("effect") != "composite_resolution":
        fail("runtime_lookup", f"Tempt effect={tempt.get('effect')!r}")
    components = {
        component.get("_rule_logical_key"): component
        for component in tempt.get("_composite_rule_components", [])
        if isinstance(component, dict)
    }
    for logical_key in (TEMPT_TOKEN_KEY, TEMPT_DRAW_KEY):
        component = components.get(logical_key)
        if component is None:
            fail("runtime_lookup", f"Tempt missing component {logical_key}")
        for field, expected_value in EXPECTED_RULES[logical_key]["fields"].items():
            if component.get(field) != expected_value:
                fail("runtime_lookup", f"Tempt {logical_key} {field}={component.get(field)!r}")
    annotations = collect_annotation_fields(tempt)
    if annotations:
        fail("runtime_lookup", f"Tempt annotation fields: {annotations}")
    results.append({
        "card_name": "Tempt with Bunnies",
        "effect": tempt.get("effect"),
        "logical_rule_key": tempt.get("_rule_logical_key"),
        "component_keys": sorted(components),
        "runtime_executor_present": True,
        "annotation_fields": annotations,
    })
    return results


def validate_battle_execution(battle) -> dict[str, Any]:
    events: list[tuple[str, dict[str, Any]]] = []
    previous_handler = getattr(battle, "REPLAY_EVENT_HANDLER", None)
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [])
        opponents = [
            battle.Player("Opponent A", None, []),
            battle.Player("Opponent B", None, []),
            battle.Player("Opponent C", None, []),
        ]
        all_players = [active, *opponents]
        battle.apply_effect_immediate(
            active,
            opponents,
            {"name": "Furygale Flocking", "type_line": "Sorcery", "cmc": 10},
            turn=7,
            rng=random.Random(6060),
        )
        furygale_tokens = [
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("name") == "Elemental Token"
        ]
        if len(furygale_tokens) != 6:
            fail("battle_execution", f"Furygale token count={len(furygale_tokens)}")
        assigned: dict[str, int] = {}
        for token in furygale_tokens:
            if token.get("must_attack_if_able") is not True:
                fail("battle_execution", f"Furygale token missing must_attack_if_able: {token}")
            if token.get("summoning_sick") is not False:
                fail("battle_execution", f"Furygale token still summoning sick: {token}")
            assigned[token.get("must_attack_defender")] = assigned.get(token.get("must_attack_defender"), 0) + 1
        expected_assigned = {"Opponent A": 2, "Opponent B": 2, "Opponent C": 2}
        if assigned != expected_assigned:
            fail("battle_execution", f"Furygale attack assignments={assigned}")
        declared = battle.declare_attackers_step(active, opponents, all_players, turn=7)
        if declared is None:
            fail("battle_execution", "declare_attackers_step returned None")
        attack_groups = {
            defender.name: len(group_attackers)
            for defender, group_attackers in declared[4]
        }
        if attack_groups != expected_assigned:
            fail("battle_execution", f"Furygale attack groups={attack_groups}")

        tempting_active = battle.Player(
            "Tempt Lorehold",
            None,
            [{"name": "Controller Draw", "type_line": "Sorcery", "cmc": 1}],
        )
        tempting_opponents = [
            battle.Player("Decliner A", None, [{"name": "Unused A", "type_line": "Sorcery"}]),
            battle.Player("Decliner B", None, [{"name": "Unused B", "type_line": "Sorcery"}]),
        ]
        battle.apply_effect_immediate(
            tempting_active,
            tempting_opponents,
            {"name": "Tempt with Bunnies", "type_line": "Sorcery", "cmc": 3},
            turn=8,
            rng=random.Random(6061),
        )
        rabbits = [
            permanent
            for permanent in tempting_active.battlefield
            if isinstance(permanent, dict) and permanent.get("name") == "Rabbit Token"
        ]
        if len(tempting_active.hand) != 1:
            fail("battle_execution", f"Tempt controller hand size={len(tempting_active.hand)}")
        if len(rabbits) != 1:
            fail("battle_execution", f"Tempt controller rabbit count={len(rabbits)}")
        if any(opponent.hand for opponent in tempting_opponents):
            fail("battle_execution", "Tempt default decline drew cards for opponents")
        if any(
            any(permanent.get("name") == "Rabbit Token" for permanent in opponent.battlefield)
            for opponent in tempting_opponents
        ):
            fail("battle_execution", "Tempt default decline created opponent rabbits")
        tempt_state = {
            "controller_hand_size_after": len(tempting_active.hand),
            "controller_rabbit_count_after": len(rabbits),
            "opponent_hand_sizes_after": {
                opponent.name: len(opponent.hand)
                for opponent in tempting_opponents
            },
            "opponent_rabbit_counts_after": {
                opponent.name: sum(
                    1
                    for permanent in opponent.battlefield
                    if isinstance(permanent, dict) and permanent.get("name") == "Rabbit Token"
                )
                for opponent in tempting_opponents
            },
        }
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    furygale_event = next(
        (
            data
            for data in event_payloads(events, "tokens_created", "Furygale Flocking")
            if data.get("tokens_created") == 6
        ),
        None,
    )
    if furygale_event is None:
        fail("battle_events", "missing Furygale tokens_created event")
    if furygale_event.get("attack_each_opponent_this_turn_status") != "runtime_executor_v1":
        fail("battle_events", "Furygale event missing runtime attack status")
    multi_attack = next(
        (
            data
            for event, data in events
            if event == "multi_defender_attack"
            and {
                group["target"]: len(group["attackers"])
                for group in data.get("groups", [])
            } == {"Opponent A": 2, "Opponent B": 2, "Opponent C": 2}
        ),
        None,
    )
    if multi_attack is None:
        fail("battle_events", "missing Furygale multi_defender_attack event")
    tempt_event = next(
        (
            data
            for data in event_payloads(events, "tempting_offer_resolved", "Tempt with Bunnies")
            if data.get("choice_model") == "opponents_decline"
        ),
        None,
    )
    if tempt_event is None:
        fail("battle_events", "missing Tempt tempting_offer_resolved decline event")
    if tempt_event.get("opponents_accepted") != 0 or tempt_event.get("opponents_declined") != 2:
        fail("battle_events", f"Tempt decline counts wrong: {tempt_event}")

    return {
        "event_count": len(events),
        "furygale": {
            "tokens_created": furygale_event.get("tokens_created"),
            "attack_assignment_by_opponent": furygale_event.get("attack_assignment_by_opponent"),
            "multi_defender_attack_groups": {
                group["target"]: len(group["attackers"])
                for group in multi_attack.get("groups", [])
            },
        },
        "tempt_with_bunnies": {
            "controller_base_cards_drawn": 1,
            "controller_base_tokens_created": 1,
            "controller_bonus_cards_drawn": tempt_event.get("controller_bonus_cards_drawn"),
            "controller_bonus_tokens_created": tempt_event.get("controller_bonus_tokens_created"),
            "opponents_accepted": tempt_event.get("opponents_accepted"),
            "opponents_declined": tempt_event.get("opponents_declined"),
            "choice_model": tempt_event.get("choice_model"),
            **tempt_state,
        },
    }


def write_markdown(path: Path, report: dict[str, Any]) -> None:
    lines = [
        "# PGC060 End-to-End Runtime Validation",
        "",
        f"- Generated UTC: `{report['generated_at_utc']}`",
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
        evidence = stage.get("evidence")
        if not isinstance(evidence, str):
            evidence = json.dumps(evidence, sort_keys=True)
        lines.append(f"| {stage['name']} | `{stage['status']}` | `{evidence}` |")
    lines.extend(
        [
            "",
            "## Runtime Execution",
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
    sqlite_db = Path(args.sqlite_db)
    snapshot = Path(args.snapshot)
    battle_path = Path(args.battle_path)
    battle = load_battle(battle_path)

    pg_results = validate_postgres()
    sqlite_results = validate_sqlite(sqlite_db)
    snapshot_results = validate_snapshot(snapshot)
    runtime_results = validate_runtime_lookup(battle)
    battle_execution = validate_battle_execution(battle)

    report = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "database_target": db_helper.sanitized_database_target(),
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
                    "furygale_tokens": battle_execution["furygale"]["tokens_created"],
                    "tempt_choice_model": battle_execution["tempt_with_bunnies"]["choice_model"],
                },
            },
        ],
        "battle_execution": battle_execution,
    }

    if args.output_json:
        Path(args.output_json).write_text(
            json.dumps(report, indent=2, sort_keys=True),
            encoding="utf-8",
        )
    if args.output_md:
        write_markdown(Path(args.output_md), report)
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
