#!/usr/bin/env python3
"""Execute one isolated ManaLoom-native battle request."""

from __future__ import annotations

import json
import os
import random
import sqlite3
import sys
import time
from contextlib import closing
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
HERMES_SCRIPTS = REPO_ROOT / "docs" / "hermes-analysis" / "manaloom-knowledge" / "scripts"
if str(HERMES_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(HERMES_SCRIPTS))

import battle_analyst_v9 as battle  # noqa: E402


class NativeBattleInputError(ValueError):
    pass


def _deck_rows(payload: dict[str, Any], deck_key: str) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    deck = payload.get(deck_key)
    if not isinstance(deck, dict):
        raise NativeBattleInputError(f"{deck_key} is required")
    rows = deck.get("cards")
    if not isinstance(rows, list) or not rows:
        raise NativeBattleInputError(f"{deck_key}.cards is required")
    normalized = []
    for row in rows:
        if not isinstance(row, dict) or not str(row.get("name") or "").strip():
            raise NativeBattleInputError(f"{deck_key} contains an invalid card row")
        quantity = max(1, min(99, int(row.get("quantity") or 1)))
        normalized.append({**row, "name": str(row["name"]).strip(), "quantity": quantity})
    return deck, normalized


def _build_deck(
    connection: sqlite3.Connection,
    payload: dict[str, Any],
    deck_key: str,
) -> tuple[dict[str, Any], dict[str, Any], list[dict[str, Any]], dict[str, Any]]:
    deck, rows = _deck_rows(payload, deck_key)
    oracle_cache = battle.load_card_oracle_cache(
        connection,
        [row["name"] for row in rows],
    )
    commanders: list[dict[str, Any]] = []
    main: list[dict[str, Any]] = []
    for row in rows:
        quantity = int(row["quantity"])
        card = battle.build_learned_battle_card(row, oracle_cache)
        card["is_commander"] = bool(row.get("is_commander"))
        target = commanders if card["is_commander"] else main
        target.extend(dict(card) for _ in range(quantity))
    report = battle.build_deck_construction_report(commanders, main)
    if not report["is_valid"]:
        raise NativeBattleInputError(
            f"{deck_key} failed Commander construction: {report['issues']}"
        )
    commander = commanders[0]
    descriptor = {
        "id": str(deck.get("id") or deck_key),
        "name": str(deck.get("name") or deck_key),
    }
    return descriptor, commander, main, report


def _configure_focus_access(payload: dict[str, Any]) -> str:
    focus_cards = [
        str(value).strip()
        for value in payload.get("focus_cards") or []
        if str(value).strip()
    ]
    os.environ["MANALOOM_FOCUS_ACCESS_CARDS"] = json.dumps(focus_cards)
    requested = str(payload.get("force_focus_access_mode") or "none").strip().lower()
    allowed = os.environ.get("MANALOOM_NATIVE_BATTLE_ALLOW_FORCED_FOCUS", "0") == "1"
    actual = requested if allowed else "none"
    os.environ["MANALOOM_FORCE_FOCUS_ACCESS_MODE"] = actual
    return actual


def _configure_runtime_limits(payload: dict[str, Any]) -> int:
    max_turns = max(1, min(100, int(payload.get("max_turns") or 30)))
    os.environ["MANALOOM_BATTLE_MAX_TURNS"] = str(max_turns)
    return max_turns


def simulate(payload: dict[str, Any]) -> dict[str, Any]:
    started = time.monotonic()
    db_path = Path(os.environ.get("MANALOOM_KNOWLEDGE_DB", battle.DB))
    if not db_path.is_file():
        raise NativeBattleInputError(f"knowledge DB not found: {db_path}")

    with closing(sqlite3.connect(db_path)) as connection:
        connection.row_factory = sqlite3.Row
        deck_a, commander_a, cards_a, report_a = _build_deck(connection, payload, "deck_a")
        deck_b, commander_b, cards_b, report_b = _build_deck(connection, payload, "deck_b")

    forced_access_mode = _configure_focus_access(payload)
    max_turns = _configure_runtime_limits(payload)
    events: list[dict[str, Any]] = []
    decisions: list[dict[str, Any]] = []
    previous_event_handler = battle.REPLAY_EVENT_HANDLER
    previous_decision_handler = battle.DECISION_TRACE_HANDLER
    previous_target = os.environ.get(battle.EVALUATION_TARGET_ENV)
    try:
        os.environ[battle.EVALUATION_TARGET_ENV] = battle.target_player_name_for_commander(
            commander_a
        )
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append(
            {"event_type": event, **dict(data)}
        )
        battle.DECISION_TRACE_HANDLER = lambda row: decisions.append(dict(row))
        battle.reset_decision_trace_counter()
        result, turns, reason = battle.simulate_game_v8(
            commander_a,
            cards_a,
            [
                {
                    "name": deck_b["name"],
                    "archetype": "submitted_deck",
                    "strategy": "midrange",
                    "is_real": True,
                    "built_deck": cards_b,
                    "commander_card": commander_b,
                    "commander_name": commander_b.get("name"),
                }
            ],
            random.Random(int(payload.get("seed") or 0)),
            str(payload.get("request_id") or "native-battle"),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_event_handler
        battle.DECISION_TRACE_HANDLER = previous_decision_handler
        if previous_target is None:
            os.environ.pop(battle.EVALUATION_TARGET_ENV, None)
        else:
            os.environ[battle.EVALUATION_TARGET_ENV] = previous_target

    winner_deck_id = None
    winner = "Draw"
    if result == "win":
        winner_deck_id = deck_a["id"]
        winner = "Deck A"
    elif result == "loss":
        winner_deck_id = deck_b["id"]
        winner = "Deck B"
    duration_ms = int((time.monotonic() - started) * 1000)
    max_events = max(100, min(50000, int(os.environ.get("MANALOOM_NATIVE_MAX_EVENTS", "20000"))))
    max_decisions = max(100, min(20000, int(os.environ.get("MANALOOM_NATIVE_MAX_DECISIONS", "5000"))))
    return {
        "status": "completed",
        "engine": "manaloom_native_reviewed",
        "engine_contract": "native_reviewed_rules_execution",
        "seed": int(payload.get("seed") or 0),
        "winner": winner,
        "winner_deck_id": winner_deck_id,
        "turns": turns,
        "max_turns": max_turns,
        "win_condition": reason,
        "duration_ms": duration_ms,
        "forced_access_mode": forced_access_mode,
        "events": events[:max_events],
        "game_log": events[:max_events],
        "decision_trace": decisions[:max_decisions],
        "visual_snapshots": [],
        "deck_construction": {"deck_a": report_a, "deck_b": report_b},
        "learning_contract": {
            "schema_version": "native_battle_learning_v1",
            "absence_proves_nonuse": False,
            "event_stream_is_lower_bound": False,
            "decision_trace_available": True,
            "strategy_or_swap_proof": False,
            "forced_access_diagnostic": forced_access_mode != "none",
        },
        "metrics": {
            "event_count": min(len(events), max_events),
            "decision_count": min(len(decisions), max_decisions),
            "events_truncated": len(events) > max_events,
            "decisions_truncated": len(decisions) > max_decisions,
        },
    }


def main() -> int:
    try:
        payload = json.load(sys.stdin)
        if not isinstance(payload, dict):
            raise NativeBattleInputError("request body must be an object")
        print(json.dumps(simulate(payload), ensure_ascii=True, separators=(",", ":")))
        return 0
    except NativeBattleInputError as error:
        print(json.dumps({"error": "invalid_request", "message": str(error)}))
        return 2
    except Exception as error:
        print(json.dumps({"error": "native_runtime_failed", "message": str(error)}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
