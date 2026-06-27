#!/usr/bin/env python3
"""Run an equal battle gate for registered Lorehold decks.

The gate compares deck 6, Lorehold variants, and the strategy-first candidate
with the same opponent sample and simulation seed. It is read-only: no
PostgreSQL writes, no source SQLite mutation, and no deck swaps.
"""

from __future__ import annotations

import argparse
import copy
import json
import multiprocessing as mp
import os
import random
import signal
import sqlite3
import traceback
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Mapping

import battle_analyst_v9 as battle


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_MATRIX = REPORT_DIR / "lorehold_variant_strategy_matrix_20260626_v1.json"
DEFAULT_CANDIDATE_DB = (
    REPORT_DIR
    / "lorehold_generated_candidate_20260626_pg243_strategy_first_v7"
    / "knowledge_candidate.db"
)
DEFAULT_DECK_IDS = (6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616)


class GameTimeoutError(TimeoutError):
    """Raised when one simulated game exceeds the configured wall-clock budget."""


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_deck_ids(raw: str | None) -> list[int]:
    if not raw:
        return list(DEFAULT_DECK_IDS)
    return [int(part.strip()) for part in raw.split(",") if part.strip()]


def set_battle_db(path: Path) -> None:
    os.environ["MANALOOM_KNOWLEDGE_DB"] = str(path)
    battle.DB = str(path)


def reset_battle_runtime_state() -> None:
    battle.CURRENT_REPLAY_TURN = None
    if hasattr(battle, "clear_pending_triggers"):
        battle.clear_pending_triggers()
    if hasattr(battle, "reset_decision_trace_counter"):
        battle.reset_decision_trace_counter()
    if hasattr(battle, "clear_engine_metrics"):
        battle.clear_engine_metrics()


def load_deck_metadata(db: Path, deck_ids: list[int]) -> dict[str, dict[str, Any]]:
    conn = sqlite3.connect(db)
    conn.row_factory = sqlite3.Row
    placeholders = ",".join("?" for _ in deck_ids)
    rows = conn.execute(
        f"""
        SELECT id, deck_name, archetype, total_cards, notes
        FROM decks
        WHERE id IN ({placeholders})
        ORDER BY id
        """,
        tuple(deck_ids),
    ).fetchall()
    conn.close()
    return {
        f"deck_{row['id']}": {
            "deck_key": f"deck_{row['id']}",
            "deck_id": int(row["id"]),
            "deck_name": row["deck_name"] or f"Deck {row['id']}",
            "archetype": row["archetype"] or "unknown",
            "source_db": str(db),
        }
        for row in rows
    }


def load_matrix_scores(path: Path) -> dict[str, dict[str, Any]]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    ranked = {key: idx + 1 for idx, key in enumerate(payload.get("ranked_deck_keys") or [])}
    result: dict[str, dict[str, Any]] = {}
    for deck in payload.get("decks") or []:
        key = deck.get("deck_key")
        if not key:
            continue
        result[str(key)] = {
            "structural_rank": ranked.get(key),
            "strategy_score": deck.get("strategy_score"),
            "objective": deck.get("objective"),
            "primary_risks": deck.get("primary_risks") or [],
        }
    return result


def deck_specs(
    *,
    db: Path,
    deck_ids: list[int],
    candidate_db: Path | None,
    include_candidate: bool,
    candidate_key: str = "candidate_v7",
    candidate_name: str = "Lorehold strategy-first candidate v7",
    candidate_archetype: str = "strategy-first-candidate",
) -> list[dict[str, Any]]:
    metadata = load_deck_metadata(db, deck_ids)
    specs = []
    for deck_id in deck_ids:
        key = f"deck_{deck_id}"
        if key in metadata:
            specs.append({**metadata[key], "load_deck_id": deck_id})
    if include_candidate and candidate_db and candidate_db.exists():
        specs.append(
            {
                "deck_key": candidate_key,
                "deck_id": None,
                "load_deck_id": 6,
                "deck_name": candidate_name,
                "archetype": candidate_archetype,
                "source_db": str(candidate_db),
            }
        )
    return specs


def load_opponents(db: Path, *, opponent_limit: int, opponent_seed: int) -> tuple[str, list[dict[str, Any]]]:
    set_battle_db(db)
    os.environ["MANALOOM_BATTLE_REAL_OPPONENT_LIMIT"] = str(opponent_limit)
    os.environ["MANALOOM_BATTLE_REAL_OPPONENT_SEED"] = str(opponent_seed)
    opponents = battle.load_learned_opponents()
    if opponents:
        return "real", opponents[:opponent_limit]
    return "generic", list(battle.OPPONENT_ARCHETYPES[:opponent_limit])


def _raise_game_timeout(signum: int, frame: Any) -> None:
    raise GameTimeoutError("battle game exceeded timeout")


def simulate_game_with_timeout(
    commander: dict[str, Any],
    deck: list[dict[str, Any]],
    opponents: list[dict[str, Any]],
    rng: random.Random,
    game_index: int,
    *,
    timeout_seconds: float,
) -> tuple[str, int, str]:
    timeout = float(timeout_seconds or 0)
    if timeout <= 0 or not hasattr(signal, "setitimer"):
        return battle.simulate_game_v8(commander, deck, opponents, rng, game_index)

    try:
        previous_handler = signal.getsignal(signal.SIGALRM)
        previous_timer = signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, _raise_game_timeout)
        signal.setitimer(signal.ITIMER_REAL, timeout)
    except (AttributeError, ValueError):
        return battle.simulate_game_v8(commander, deck, opponents, rng, game_index)

    try:
        return battle.simulate_game_v8(commander, deck, opponents, rng, game_index)
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, previous_handler)
        if previous_timer[0] > 0 or previous_timer[1] > 0:
            signal.setitimer(signal.ITIMER_REAL, previous_timer[0], previous_timer[1])


class GateTelemetry:
    def __init__(self) -> None:
        self.current_game = ""
        self.events: Counter[str] = Counter()
        self.strategic_events: Counter[str] = Counter()
        self.games_with: dict[str, set[str]] = {
            "miracle_cast": set(),
            "topdeck_manipulation_activated": set(),
            "lorehold_cost_paid": set(),
            "lorehold_spell_cast": set(),
            "spell_cast_mana_trigger": set(),
            "birgi_spell_cast_mana": set(),
            "lorehold_upkeep_rummage": set(),
            "hand_to_topdeck_activation": set(),
            "lorehold_rummage_discards_squee": set(),
            "lorehold_spell_rummage": set(),
            "lorehold_spell_rummage_discards_squee": set(),
            "squee_to_graveyard": set(),
            "squee_return_after_known_graveyard_entry": set(),
            "squee_return_without_known_graveyard_entry": set(),
            "squee_upkeep_return": set(),
        }
        self.cards: Counter[str] = Counter()
        self.event_counts_by_game: dict[str, Counter[str]] = defaultdict(Counter)
        self.strategic_event_counts_by_game: dict[str, Counter[str]] = defaultdict(Counter)
        self.squee_graveyard_entries_by_game: Counter[str] = Counter()
        self.squee_known_graveyard_balance_by_game: Counter[str] = Counter()
        self.squee_game_traces: dict[str, list[dict[str, Any]]] = {}
        self.squee_anomalies: list[dict[str, Any]] = []
        self.squee_trace_samples: list[dict[str, Any]] = []
        self.event_sequence = 0

    def begin(self, game_id: str) -> None:
        self.current_game = game_id

    def _payload_names(self, data: Mapping[str, Any], keys: tuple[str, ...]) -> list[str]:
        names: list[str] = []
        for key in keys:
            value = data.get(key)
            if isinstance(value, dict):
                names.append(str(value.get("name") or value.get("card") or value.get("card_name") or ""))
            elif isinstance(value, list):
                for item in value:
                    if isinstance(item, dict):
                        names.append(str(item.get("name") or item.get("card") or item.get("card_name") or ""))
                    else:
                        names.append(str(item or ""))
            else:
                names.append(str(value or ""))
        return names

    def _payload_destinations(self, data: Mapping[str, Any]) -> set[str]:
        return {
            str(data.get(key) or "").lower()
            for key in ("destination", "to_zone", "zone_after", "discard_destination", "final_to_zone")
            if data.get(key)
        }

    def _squee_in_graveyard_payload(self, event: str, data: Mapping[str, Any]) -> bool:
        graveyard_list_names = self._payload_names(
            data,
            (
                "discarded_to_graveyard",
                "moved_to_graveyard",
                "to_graveyard",
                "milled",
                "milled_cards",
                "milled_to_graveyard",
                "cards_to_graveyard",
                "land_cards_entered_graveyard",
            ),
        )
        if "Squee, Goblin Nabob" in graveyard_list_names:
            return True
        if event == "turn_end" and "Squee, Goblin Nabob" in self._payload_names(data, ("discarded_cards",)):
            return True
        names = self._payload_names(
            data,
            (
                "card",
                "card_name",
                "discarded",
                "discarded_card",
                "stack_object",
                "permanent",
                "source_card",
                "object",
                "zone_object",
                "creature",
            ),
        )
        return "Squee, Goblin Nabob" in names and "graveyard" in self._payload_destinations(data)

    def _record_squee_graveyard_entry(self, event: str) -> None:
        self.strategic_events["squee_to_graveyard"] += 1
        self.games_with["squee_to_graveyard"].add(self.current_game)
        self.squee_graveyard_entries_by_game[self.current_game] += 1
        self.squee_known_graveyard_balance_by_game[self.current_game] += 1
        self.cards[f"squee_to_graveyard:{event}"] += 1

    def _squee_trace_payload(
        self,
        event: str,
        data: Mapping[str, Any],
        *,
        markers: list[str],
        balance_before: int,
        balance_after: int,
    ) -> dict[str, Any]:
        keep_keys = (
            "player",
            "card",
            "effect",
            "trigger",
            "from_zone",
            "to_zone",
            "destination",
            "discard_destination",
            "discarded",
            "discarded_to_graveyard",
            "discarded_cards",
            "moved_to_graveyard",
            "to_graveyard",
            "milled",
            "milled_cards",
            "milled_to_graveyard",
            "cards_to_graveyard",
            "cards_milled",
            "target_player",
            "reason",
            "source",
            "turn",
        )
        return {
            "seq": self.event_sequence,
            "game_id": self.current_game,
            "event": event,
            "markers": list(markers),
            "squee_known_graveyard_balance_before": balance_before,
            "squee_known_graveyard_balance_after": balance_after,
            "data": {key: data.get(key) for key in keep_keys if key in data},
        }

    def _record_squee_trace(
        self,
        event: str,
        data: Mapping[str, Any],
        *,
        markers: list[str],
        balance_before: int,
        balance_after: int,
    ) -> None:
        trace = self._squee_trace_payload(
            event,
            data,
            markers=markers,
            balance_before=balance_before,
            balance_after=balance_after,
        )
        traces = self.squee_game_traces.setdefault(self.current_game, [])
        if len(traces) < 80:
            traces.append(trace)
        if len(self.squee_trace_samples) >= 20:
            return
        self.squee_trace_samples.append(trace)

    def record(self, event: str, data: Mapping[str, Any]) -> None:
        self.event_sequence += 1
        self.events[event] += 1
        self.event_counts_by_game[self.current_game][event] += 1
        strategic_before = self.strategic_events.copy()
        player = str(data.get("player") or "")
        card = str(data.get("card") or "")
        squee_mentioned = "Squee, Goblin Nabob" in json.dumps(data, sort_keys=True, default=str)
        squee_entry = self._squee_in_graveyard_payload(event, data)
        squee_return = (
            event == "trigger_resolved"
            and player == "Lorehold"
            and data.get("effect") == "graveyard_upkeep_return_self_to_hand"
            and card == "Squee, Goblin Nabob"
        )
        squee_balance_before = self.squee_known_graveyard_balance_by_game[self.current_game]
        squee_markers: list[str] = []
        if event == "miracle_cast" and player == "Lorehold":
            self.strategic_events[event] += 1
            self.games_with[event].add(self.current_game)
            if card:
                self.cards[f"miracle:{card}"] += 1
        elif event == "topdeck_manipulation_activated" and player == "Lorehold":
            self.strategic_events[event] += 1
            self.games_with[event].add(self.current_game)
            if card:
                self.cards[f"topdeck:{card}"] += 1
        elif event == "cost_paid" and player == "Lorehold":
            self.strategic_events["lorehold_cost_paid"] += 1
            self.games_with["lorehold_cost_paid"].add(self.current_game)
            if card:
                self.cards[f"cost_paid:{card}"] += 1
        elif event == "spell_cast" and player == "Lorehold":
            self.strategic_events["lorehold_spell_cast"] += 1
            self.games_with["lorehold_spell_cast"].add(self.current_game)
        elif event == "trigger_resolved" and player == "Lorehold" and data.get("effect") == "add_mana":
            mana_added = max(1, int(data.get("mana_added") or 1))
            self.strategic_events["spell_cast_mana_trigger"] += mana_added
            self.games_with["spell_cast_mana_trigger"].add(self.current_game)
            if card:
                self.cards[f"spell_cast_mana:{card}"] += mana_added
            if card == "Birgi, God of Storytelling // Harnfel, Horn of Bounty":
                self.strategic_events["birgi_spell_cast_mana"] += mana_added
                self.games_with["birgi_spell_cast_mana"].add(self.current_game)
        elif (
            event == "activated_ability"
            and player == "Lorehold"
            and data.get("activation_kind") == "put_card_from_hand_on_top_library_prevent_chosen_source_damage"
        ):
            self.strategic_events["hand_to_topdeck_activation"] += 1
            self.games_with["hand_to_topdeck_activation"].add(self.current_game)
            if card:
                self.cards[f"hand_to_topdeck:{card}"] += 1
        elif event == "lorehold_upkeep_rummage" and player == "Lorehold":
            self.strategic_events["lorehold_upkeep_rummage"] += 1
            self.games_with["lorehold_upkeep_rummage"].add(self.current_game)
            discarded = str(data.get("discarded") or "")
            if discarded == "Squee, Goblin Nabob":
                self.strategic_events["lorehold_rummage_discards_squee"] += 1
                self.games_with["lorehold_rummage_discards_squee"].add(self.current_game)
                self.cards["rummage_discard:Squee, Goblin Nabob"] += 1
        elif event == "trigger_resolved" and player == "Lorehold" and data.get("effect") == "rummage":
            self.strategic_events["lorehold_spell_rummage"] += 1
            self.games_with["lorehold_spell_rummage"].add(self.current_game)
            if "Squee, Goblin Nabob" in self._payload_names(data, ("discarded_to_graveyard", "discarded")):
                self.strategic_events["lorehold_spell_rummage_discards_squee"] += 1
                self.games_with["lorehold_spell_rummage_discards_squee"].add(self.current_game)
                self.cards["spell_rummage_discard:Squee, Goblin Nabob"] += 1
        elif (
            event == "trigger_resolved"
            and player == "Lorehold"
            and data.get("effect") == "graveyard_upkeep_return_self_to_hand"
        ):
            self.strategic_events["graveyard_upkeep_return_self_to_hand"] += 1
            self.games_with.setdefault("graveyard_upkeep_return_self_to_hand", set()).add(self.current_game)
            if card == "Squee, Goblin Nabob":
                self.strategic_events["squee_upkeep_return"] += 1
                self.games_with["squee_upkeep_return"].add(self.current_game)
                self.cards["graveyard_return:Squee, Goblin Nabob"] += 1
                squee_markers.append("upkeep_return")
                if squee_balance_before > 0:
                    self.strategic_events["squee_return_after_known_graveyard_entry"] += 1
                    self.games_with["squee_return_after_known_graveyard_entry"].add(self.current_game)
                    self.squee_known_graveyard_balance_by_game[self.current_game] = max(
                        0,
                        self.squee_known_graveyard_balance_by_game[self.current_game] - 1,
                    )
                else:
                    self.strategic_events["squee_return_without_known_graveyard_entry"] += 1
                    self.games_with["squee_return_without_known_graveyard_entry"].add(self.current_game)
                    self.squee_anomalies.append(
                        {
                            "kind": "squee_return_without_known_graveyard_entry",
                            "game_id": self.current_game,
                            "seq": self.event_sequence,
                            "event": event,
                            "turn": data.get("turn"),
                            "recent_trace": list(self.squee_game_traces.get(self.current_game, [])[-12:]),
                        }
                    )
        if squee_entry:
            self._record_squee_graveyard_entry(event)
            squee_markers.append("graveyard_entry")
        if squee_mentioned or squee_entry or squee_return:
            self._record_squee_trace(
                event,
                data,
                markers=squee_markers or ["mentions_squee"],
                balance_before=squee_balance_before,
                balance_after=self.squee_known_graveyard_balance_by_game[self.current_game],
            )
        for key, count in self.strategic_events.items():
            delta = count - strategic_before.get(key, 0)
            if delta:
                self.strategic_event_counts_by_game[self.current_game][key] += delta

    def game_summary(self, game_id: str) -> dict[str, Any]:
        return {
            "event_counts": dict(self.event_counts_by_game.get(game_id, {})),
            "strategic_event_counts": dict(self.strategic_event_counts_by_game.get(game_id, {})),
            "squee_known_graveyard_balance": int(self.squee_known_graveyard_balance_by_game.get(game_id, 0)),
            "squee_trace_count": len(self.squee_game_traces.get(game_id, [])),
            "squee_anomaly_count": sum(
                1 for item in self.squee_anomalies if item.get("game_id") == game_id
            ),
        }

    def as_json(self, total_games: int) -> dict[str, Any]:
        games = max(1, total_games)
        return {
            "event_counts": dict(self.events),
            "strategic_event_counts": dict(self.strategic_events),
            "event_counts_by_game": {
                key: dict(value)
                for key, value in sorted(self.event_counts_by_game.items())
            },
            "strategic_event_counts_by_game": {
                key: dict(value)
                for key, value in sorted(self.strategic_event_counts_by_game.items())
            },
            "strategic_games": {
                key: {
                    "games": len(value),
                    "rate": round(len(value) / games, 4),
                }
                for key, value in self.games_with.items()
            },
            "top_cards": [
                {"key": key, "count": count}
                for key, count in self.cards.most_common(12)
            ],
            "squee_trace_samples": list(self.squee_trace_samples),
            "squee_game_traces": {
                key: value
                for key, value in sorted(self.squee_game_traces.items())
            },
            "squee_anomalies": list(self.squee_anomalies),
            "squee_known_graveyard_balance_by_game": dict(self.squee_known_graveyard_balance_by_game),
        }


def run_deck_gate(
    *,
    spec: Mapping[str, Any],
    opponents: list[dict[str, Any]],
    games_per_opponent: int,
    simulation_seed: int,
    game_timeout_seconds: float = 0,
    progress_callback: Callable[[dict[str, Any]], None] | None = None,
) -> dict[str, Any]:
    source_db = Path(str(spec["source_db"]))
    set_battle_db(source_db)
    reset_battle_runtime_state()
    commander, deck, construction_report = battle.load_deck_with_construction_report(
        int(spec["load_deck_id"])
    )
    if commander is None:
        raise RuntimeError(f"no commander loaded for {spec['deck_key']}")
    rng = random.Random(simulation_seed)
    telemetry = GateTelemetry()
    wins = losses = stalls = 0
    win_turns: list[int] = []
    win_reasons: Counter[str] = Counter()
    opponent_rows: list[dict[str, Any]] = []
    game_rows: list[dict[str, Any]] = []
    total_games = games_per_opponent * len(opponents)
    completed_games = 0

    previous_handler = battle.REPLAY_EVENT_HANDLER

    def event_handler(event: str, data: Mapping[str, Any]) -> None:
        telemetry.record(event, data)

    battle.REPLAY_EVENT_HANDLER = event_handler
    try:
        for profile in opponents:
            profile_wins = profile_losses = profile_stalls = 0
            profile_turns: list[int] = []
            profile_reasons: Counter[str] = Counter()
            for game_index in range(games_per_opponent):
                game_id = f"{spec['deck_key']}:{profile.get('name', '?')}:{game_index}"
                telemetry.begin(game_id)
                reset_battle_runtime_state()
                others = [item for item in opponents if item is not profile]
                picked = [profile] + rng.sample(others, min(2, len(others)))
                try:
                    result, turns, reason = simulate_game_with_timeout(
                        copy.deepcopy(commander),
                        copy.deepcopy(deck),
                        copy.deepcopy(picked),
                        rng,
                        game_index,
                        timeout_seconds=game_timeout_seconds,
                    )
                except GameTimeoutError:
                    result = "stall"
                    turns = int(battle.CURRENT_REPLAY_TURN or 0)
                    reason = f"game_timeout_{float(game_timeout_seconds):.1f}s"
                    telemetry.events["game_timeout"] += 1
                    telemetry.event_counts_by_game[game_id]["game_timeout"] += 1
                if result == "win":
                    wins += 1
                    profile_wins += 1
                    win_turns.append(int(turns))
                    profile_turns.append(int(turns))
                    win_reasons[str(reason)] += 1
                    profile_reasons[str(reason)] += 1
                elif result == "loss":
                    losses += 1
                    profile_losses += 1
                else:
                    stalls += 1
                    profile_stalls += 1
                completed_games += 1
                game_rows.append(
                    {
                        "game_id": game_id,
                        "game_index": game_index,
                        "opponent": profile.get("name", "?"),
                        "opponent_archetype": profile.get("archetype", "?"),
                        "picked_opponents": [item.get("name", "?") for item in picked],
                        "result": result,
                        "turns": int(turns or 0),
                        "reason": str(reason),
                        **telemetry.game_summary(game_id),
                    }
                )
                if progress_callback is not None:
                    progress_callback(
                        {
                            "generated_at": utc_now(),
                            "deck_key": spec["deck_key"],
                            "deck_name": spec.get("deck_name"),
                            "opponent": profile.get("name", "?"),
                            "game_id": game_id,
                            "game_index": game_index,
                            "completed_games": completed_games,
                            "total_games": total_games,
                            "last_result": result,
                            "last_turns": int(turns or 0),
                            "last_reason": str(reason),
                            "wins": wins,
                            "losses": losses,
                            "stalls": stalls,
                            "game_timeout_seconds": float(game_timeout_seconds or 0),
                        }
                    )
            opponent_rows.append(
                {
                    "opponent": profile.get("name", "?"),
                    "archetype": profile.get("archetype", "?"),
                    "wins": profile_wins,
                    "losses": profile_losses,
                    "stalls": profile_stalls,
                    "win_rate": round(profile_wins / max(1, games_per_opponent) * 100, 2),
                    "avg_win_turn": round(sum(profile_turns) / len(profile_turns), 2)
                    if profile_turns
                    else 0,
                    "win_reasons": dict(profile_reasons),
                }
            )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    lands = sum(1 for card in deck if battle.card_has_functional_tag(card, "land") or "Land" in card.get("type_line", ""))
    ramp = sum(1 for card in deck if battle.card_has_functional_tag(card, "ramp", "ritual"))
    removal = sum(1 for card in deck if battle.card_has_functional_tag(card, "removal", "board_wipe"))
    return {
        **dict(spec),
        "status": "pass",
        "commander": commander.get("name", "?"),
        "deck_size": len(deck) + 1,
        "lands": lands,
        "ramp": ramp,
        "removal": removal,
        "construction_report": construction_report,
        "games": total_games,
        "wins": wins,
        "losses": losses,
        "stalls": stalls,
        "win_rate": round(wins / max(1, total_games) * 100, 2),
        "avg_win_turn": round(sum(win_turns) / len(win_turns), 2) if win_turns else 0,
        "win_reasons": dict(win_reasons),
        "opponents": opponent_rows,
        "game_results": game_rows,
        "telemetry": telemetry.as_json(total_games),
    }


def _run_deck_gate_process_entry(queue: Any, kwargs: dict[str, Any]) -> None:
    try:
        result = run_deck_gate(**kwargs)
        queue.put({"ok": True, "result": result})
    except Exception as exc:
        queue.put(
            {
                "ok": False,
                "error": str(exc),
                "traceback": traceback.format_exc(limit=8),
            }
        )


def run_deck_gate_in_process(
    *,
    spec: Mapping[str, Any],
    opponents: list[dict[str, Any]],
    games_per_opponent: int,
    simulation_seed: int,
    game_timeout_seconds: float,
) -> dict[str, Any]:
    ctx = mp.get_context("spawn")
    queue: Any = ctx.Queue()
    kwargs = {
        "spec": dict(spec),
        "opponents": opponents,
        "games_per_opponent": games_per_opponent,
        "simulation_seed": simulation_seed,
        "game_timeout_seconds": game_timeout_seconds,
        "progress_callback": None,
    }
    process = ctx.Process(target=_run_deck_gate_process_entry, args=(queue, kwargs))
    process.start()
    total_games = max(1, games_per_opponent) * max(1, len(opponents))
    timeout = max(120.0, total_games * max(5.0, float(game_timeout_seconds or 0.0)) + 120.0)
    process.join(timeout)
    if process.is_alive():
        process.terminate()
        process.join(10)
        raise RuntimeError(f"isolated deck process timed out after {timeout:.1f}s")
    if process.exitcode != 0 and queue.empty():
        raise RuntimeError(f"isolated deck process exited with code {process.exitcode}")
    payload = queue.get()
    if not payload.get("ok"):
        raise RuntimeError(payload.get("error") or payload.get("traceback") or "isolated deck process failed")
    result = payload["result"]
    result["process_isolated"] = True
    return result


def merge_structural_context(
    results: list[dict[str, Any]],
    matrix_scores: Mapping[str, Mapping[str, Any]],
) -> list[dict[str, Any]]:
    for result in results:
        context = matrix_scores.get(str(result.get("deck_key")), {})
        result["structural_rank"] = context.get("structural_rank")
        result["strategy_score"] = context.get("strategy_score")
        result["objective"] = context.get("objective")
        result["primary_risks"] = context.get("primary_risks") or []
    battle_ranked = sorted(
        results,
        key=lambda row: (
            -float(row.get("win_rate") or -1),
            int(row.get("stalls") or 0),
            int(row.get("losses") or 0),
            str(row.get("deck_key")),
        ),
    )
    for idx, row in enumerate(battle_ranked, start=1):
        row["battle_rank"] = idx
    return results


def render_markdown(report: Mapping[str, Any]) -> str:
    rows = sorted(report.get("results") or [], key=lambda row: int(row.get("battle_rank") or 999))
    lines = [
        "# Lorehold Equal Battle Gate",
        "",
        f"- generated_at: `{report['generated_at']}`",
        f"- source_db: `{report['source_db']}`",
        f"- games_per_opponent: `{report['games_per_opponent']}`",
        f"- opponent_kind: `{report['opponent_kind']}`",
        f"- opponent_seed: `{report['opponent_seed']}`",
        f"- simulation_seed: `{report['simulation_seed']}`",
        f"- python_hash_seed: `{report.get('python_hash_seed', 'unset')}`",
        f"- deck_process_isolation: `{report.get('deck_process_isolation', False)}`",
        f"- game_timeout_seconds: `{report.get('game_timeout_seconds', 0)}`",
        f"- game_checkpoint_json: `{report.get('game_checkpoint_json')}`",
        f"- opponents: `{', '.join(report.get('opponents') or [])}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Battle Ranking",
        "",
        "| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Main Risks |",
        "| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |",
    ]
    for row in rows:
        telemetry = row.get("telemetry") or {}
        strategic_games = telemetry.get("strategic_games") or {}
        miracle_games = (strategic_games.get("miracle_cast") or {}).get("games", 0)
        topdeck_games = (strategic_games.get("topdeck_manipulation_activated") or {}).get("games", 0)
        squee_graveyard_games = (strategic_games.get("squee_to_graveyard") or {}).get("games", 0)
        squee_return_games = (strategic_games.get("squee_upkeep_return") or {}).get("games", 0)
        explained_return_games = (
            strategic_games.get("squee_return_after_known_graveyard_entry") or {}
        ).get("games", 0)
        unexplained_return_games = (
            strategic_games.get("squee_return_without_known_graveyard_entry") or {}
        ).get("games", 0)
        rummage_games = (strategic_games.get("lorehold_upkeep_rummage") or {}).get("games", 0)
        risks = ", ".join(row.get("primary_risks") or []) or "none"
        lines.append(
            f"| {row.get('battle_rank')} | {row.get('structural_rank') or ''} | "
            f"{row.get('deck_name')} (`{row.get('deck_key')}`) | {row.get('archetype')} | "
            f"{row.get('games')} | {row.get('wins')} | {row.get('losses')} | {row.get('stalls')} | "
            f"{float(row.get('win_rate') or 0):.2f}% | {float(row.get('avg_win_turn') or 0):.2f} | "
            f"{miracle_games} | {topdeck_games} | {squee_graveyard_games} | {squee_return_games} | "
            f"{explained_return_games} | {unexplained_return_games} | {rummage_games} | {risks} |"
        )

    lines.extend(["", "## Deck Detail", ""])
    for row in rows:
        lines.extend(
            [
                f"### {row.get('battle_rank')}. {row.get('deck_name')} (`{row.get('deck_key')}`)",
                "",
                f"- objective: {row.get('objective') or 'not available in structural matrix'}",
                f"- result: `{row.get('wins')}W/{row.get('losses')}L/{row.get('stalls')}S`, WR `{float(row.get('win_rate') or 0):.2f}%`",
                f"- construction_valid: `{(row.get('construction_report') or {}).get('is_valid')}`",
                f"- deck shape: size `{row.get('deck_size')}`, lands `{row.get('lands')}`, ramp `{row.get('ramp')}`, removal `{row.get('removal')}`",
                "",
                "| Opponent | W | L | S | WR | Avg Win Turn | Reasons |",
                "| --- | ---: | ---: | ---: | ---: | ---: | --- |",
            ]
        )
        for opponent in row.get("opponents") or []:
            reasons = ", ".join(
                f"{key}={value}" for key, value in (opponent.get("win_reasons") or {}).items()
            )
            lines.append(
                f"| {opponent.get('opponent')} | {opponent.get('wins')} | {opponent.get('losses')} | "
                f"{opponent.get('stalls')} | {float(opponent.get('win_rate') or 0):.2f}% | "
                f"{float(opponent.get('avg_win_turn') or 0):.2f} | {reasons} |"
            )
        telemetry = row.get("telemetry") or {}
        lines.extend(
            [
                "",
                "**Strategic event counts:** "
                + (
                    ", ".join(
                        f"{key}={value}"
                        for key, value in (telemetry.get("strategic_event_counts") or {}).items()
                    )
                    or "none"
                ),
                "",
            ]
        )

    failures = [row for row in rows if row.get("status") != "pass"]
    if failures:
        lines.extend(["", "## Runtime Failures", ""])
        for row in failures:
            lines.append(f"- `{row.get('deck_key')}`: {row.get('error')}")
    return "\n".join(lines) + "\n"


def render_checkpoint_markdown(payload: Mapping[str, Any]) -> str:
    latest = payload.get("latest") or {}
    lines = [
        "# Lorehold Battle Gate Game Checkpoint",
        "",
        f"- generated_at: `{payload.get('generated_at')}`",
        f"- status: `{payload.get('status')}`",
        f"- stem: `{payload.get('stem')}`",
        f"- completed_games: `{payload.get('completed_games')}`",
        f"- total_games: `{payload.get('total_games')}`",
        f"- game_timeout_seconds: `{payload.get('game_timeout_seconds')}`",
        "",
        "## Latest Game",
        "",
        f"- deck: `{latest.get('deck_key')}`",
        f"- opponent: `{latest.get('opponent')}`",
        f"- result: `{latest.get('last_result')}`",
        f"- turns: `{latest.get('last_turns')}`",
        f"- reason: `{latest.get('last_reason')}`",
        "",
        "## Recent Events",
        "",
        "| Completed | Deck | Opponent | Result | Turns | Reason |",
        "| ---: | --- | --- | --- | ---: | --- |",
    ]
    for event in payload.get("events") or []:
        lines.append(
            f"| {event.get('completed_games')} | `{event.get('deck_key')}` | "
            f"{event.get('opponent')} | {event.get('last_result')} | "
            f"{event.get('last_turns')} | {event.get('last_reason')} |"
        )
    return "\n".join(lines) + "\n"


def write_game_checkpoint(
    payload: Mapping[str, Any],
    stem: str,
    *,
    report_dir: Path = REPORT_DIR,
) -> tuple[Path, Path]:
    report_dir.mkdir(parents=True, exist_ok=True)
    json_path = report_dir / f"{stem}.json"
    md_path = report_dir / f"{stem}.md"
    json_path.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_checkpoint_markdown(payload), encoding="utf-8")
    return json_path, md_path


def write_report(report: Mapping[str, Any], stem: str) -> tuple[Path, Path]:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{stem}.json"
    md_path = REPORT_DIR / f"{stem}.md"
    json_path.write_text(json.dumps(report, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(report), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-ids", default=None)
    parser.add_argument("--candidate-db", type=Path, default=DEFAULT_CANDIDATE_DB)
    parser.add_argument("--candidate-key", default="candidate_v7")
    parser.add_argument("--candidate-name", default="Lorehold strategy-first candidate v7")
    parser.add_argument("--candidate-archetype", default="strategy-first-candidate")
    parser.add_argument("--no-candidate", action="store_true")
    parser.add_argument("--matrix", type=Path, default=DEFAULT_MATRIX)
    parser.add_argument("--games", type=int, default=1)
    parser.add_argument("--opponent-limit", type=int, default=3)
    parser.add_argument("--opponent-seed", type=int, default=20260626)
    parser.add_argument("--simulation-seed", type=int, default=42)
    parser.add_argument("--game-timeout-seconds", type=float, default=0.0)
    parser.add_argument("--checkpoint-stem", default=None)
    parser.add_argument("--checkpoint-history-limit", type=int, default=200)
    parser.add_argument("--no-game-checkpoint", action="store_true")
    parser.add_argument(
        "--isolate-deck-process",
        action="store_true",
        help="Run each deck/candidate in a fresh Python process to avoid battle runtime global-state bleed.",
    )
    parser.add_argument("--stem", default="lorehold_variant_battle_gate_20260626_v1")
    args = parser.parse_args()

    deck_ids = parse_deck_ids(args.deck_ids)
    specs = deck_specs(
        db=args.db,
        deck_ids=deck_ids,
        candidate_db=args.candidate_db,
        include_candidate=not args.no_candidate,
        candidate_key=args.candidate_key,
        candidate_name=args.candidate_name,
        candidate_archetype=args.candidate_archetype,
    )
    opponent_kind, opponents = load_opponents(
        args.db,
        opponent_limit=args.opponent_limit,
        opponent_seed=args.opponent_seed,
    )
    matrix_scores = load_matrix_scores(args.matrix)

    results: list[dict[str, Any]] = []
    partial_stem = f"{args.stem}_partial"
    checkpoint_stem = args.checkpoint_stem or f"{args.stem}_game_checkpoint"
    checkpoint_events: list[dict[str, Any]] = []
    checkpoint_json = REPORT_DIR / f"{checkpoint_stem}.json"
    checkpoint_md = REPORT_DIR / f"{checkpoint_stem}.md"

    def progress_callback(event: dict[str, Any]) -> None:
        if args.no_game_checkpoint:
            return
        checkpoint_events.append(dict(event))
        recent_events = checkpoint_events[-max(1, int(args.checkpoint_history_limit)) :]
        latest = recent_events[-1] if recent_events else {}
        payload = {
            "generated_at": utc_now(),
            "status": "running",
            "stem": checkpoint_stem,
            "source_db": str(args.db),
            "matrix": str(args.matrix),
            "games_per_opponent": max(1, args.games),
            "opponent_kind": opponent_kind,
            "opponent_seed": args.opponent_seed,
            "simulation_seed": args.simulation_seed,
            "python_hash_seed": os.environ.get("PYTHONHASHSEED", "unset"),
            "game_timeout_seconds": float(args.game_timeout_seconds or 0),
            "completed_games": latest.get("completed_games", 0),
            "total_games": latest.get("total_games", 0),
            "latest": latest,
            "events": recent_events,
        }
        write_game_checkpoint(payload, checkpoint_stem)

    for spec in specs:
        print(f"running {spec['deck_key']} games={args.games} opponents={len(opponents)}", flush=True)
        try:
            if args.isolate_deck_process:
                result = run_deck_gate_in_process(
                    spec=spec,
                    opponents=opponents,
                    games_per_opponent=max(1, args.games),
                    simulation_seed=args.simulation_seed,
                    game_timeout_seconds=max(0.0, float(args.game_timeout_seconds or 0)),
                )
            else:
                result = run_deck_gate(
                    spec=spec,
                    opponents=opponents,
                    games_per_opponent=max(1, args.games),
                    simulation_seed=args.simulation_seed,
                    game_timeout_seconds=max(0.0, float(args.game_timeout_seconds or 0)),
                    progress_callback=progress_callback,
                )
        except Exception as exc:
            result = {
                **spec,
                "status": "runtime_error",
                "error": str(exc),
                "traceback": traceback.format_exc(limit=8),
                "games": 0,
                "wins": 0,
                "losses": 0,
                "stalls": 0,
                "win_rate": 0.0,
                "avg_win_turn": 0.0,
                "opponents": [],
                "telemetry": {},
            }
        results.append(result)
        partial_report = {
            "generated_at": utc_now(),
            "status": "partial",
            "source_db": str(args.db),
            "matrix": str(args.matrix),
            "games_per_opponent": max(1, args.games),
            "opponent_kind": opponent_kind,
            "opponent_seed": args.opponent_seed,
            "simulation_seed": args.simulation_seed,
            "python_hash_seed": os.environ.get("PYTHONHASHSEED", "unset"),
            "deck_process_isolation": bool(args.isolate_deck_process),
            "game_timeout_seconds": float(args.game_timeout_seconds or 0),
            "game_checkpoint_json": None if args.no_game_checkpoint else str(checkpoint_json),
            "game_checkpoint_markdown": None if args.no_game_checkpoint else str(checkpoint_md),
            "opponents": [opponent.get("name", "?") for opponent in opponents],
            "results": merge_structural_context(results, matrix_scores),
        }
        write_report(partial_report, partial_stem)

    report = {
        "generated_at": utc_now(),
        "status": "ready",
        "source_db": str(args.db),
        "matrix": str(args.matrix),
        "candidate_db": str(args.candidate_db) if args.candidate_db else None,
        "games_per_opponent": max(1, args.games),
        "opponent_kind": opponent_kind,
        "opponent_seed": args.opponent_seed,
        "simulation_seed": args.simulation_seed,
        "python_hash_seed": os.environ.get("PYTHONHASHSEED", "unset"),
        "deck_process_isolation": bool(args.isolate_deck_process),
        "game_timeout_seconds": float(args.game_timeout_seconds or 0),
        "game_checkpoint_json": None if args.no_game_checkpoint else str(checkpoint_json),
        "game_checkpoint_markdown": None if args.no_game_checkpoint else str(checkpoint_md),
        "opponents": [opponent.get("name", "?") for opponent in opponents],
        "results": merge_structural_context(results, matrix_scores),
    }
    json_path, md_path = write_report(report, args.stem)
    if not args.no_game_checkpoint:
        recent_events = checkpoint_events[-max(1, int(args.checkpoint_history_limit)) :]
        write_game_checkpoint(
            {
                "generated_at": utc_now(),
                "status": "ready",
                "stem": checkpoint_stem,
                "source_db": str(args.db),
                "matrix": str(args.matrix),
                "games_per_opponent": max(1, args.games),
                "opponent_kind": opponent_kind,
                "opponent_seed": args.opponent_seed,
                "simulation_seed": args.simulation_seed,
                "python_hash_seed": os.environ.get("PYTHONHASHSEED", "unset"),
                "deck_process_isolation": bool(args.isolate_deck_process),
                "game_timeout_seconds": float(args.game_timeout_seconds or 0),
                "completed_games": (recent_events[-1].get("completed_games", 0) if recent_events else 0),
                "total_games": (recent_events[-1].get("total_games", 0) if recent_events else 0),
                "latest": recent_events[-1] if recent_events else {},
                "events": recent_events,
                "report_json": str(json_path),
                "report_markdown": str(md_path),
            },
            checkpoint_stem,
        )
    print(json.dumps({"status": "ready", "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
