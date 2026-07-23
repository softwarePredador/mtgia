#!/usr/bin/env python3
"""Run a native diagnostic battle probe for registered Lorehold decks.

The gate compares deck 6, Lorehold variants, and the strategy-first candidate
inside the deterministic Python laboratory. Its schedule seed does not control
XMage or Forge RNG and cannot authorize deck promotion. The probe is read-only:
no PostgreSQL writes, no source SQLite mutation, and no deck swaps.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import multiprocessing as mp
import os
import queue as queue_module
import random
import signal
import sqlite3
import tempfile
import time
import traceback
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Mapping

import battle_analyst_v9 as battle
from master_optimizer_common import resolve_default_knowledge_db, safe_cmc_from_card


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_MATRIX = (
    REPORT_DIR / "lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.json"
)
DEFAULT_CANDIDATE_DB = None
DEFAULT_DECK_IDS = (6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616)
INDEPENDENT_PROMOTION_GATE = "lorehold_independent_battle_statistical_gate.py"
CARD_EXPOSURE_EVENTS = {
    "activated_ability",
    "board_wipe_resolved",
    "cost_paid",
    "draw_cards_resolved",
    "land_played",
    "miracle_cast",
    "recursion_resolved",
    "removal_resolved",
    "spell_cast",
    "spell_resolved",
    "topdeck_manipulation_activated",
    "treasure_created",
    "trigger_resolved",
    "utility_artifact_activated",
    "utility_land_activated",
}
LOREHOLD_RUNTIME_EFFECT_EVENTS = {
    "escape_additional_cost_paid",
    "escape_cast",
    "flashback_cast",
    "flashback_exiled",
    "flashback_permission_expired",
    "flashback_target_permission_granted",
    "flashback_target_permission_not_granted",
    "harnfel_activated",
    "harnfel_discard_cost_paid",
    "harnfel_exiled_card_played",
    "mana_vault_draw_step_damage",
    "mana_vault_mana_activated",
    "mana_vault_upkeep_untap",
    "underworld_breach_end_step_sacrificed",
}
BASE_FOCUS_TRACE_CARDS = {
    "Aetherflux Reservoir",
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
    "Flashback",
    "Urza's Saga",
    "Library of Leng",
    "Mana Vault",
    "Molecule Man",
    "Sensei's Divining Top",
    "Scroll Rack",
    "Squee, Goblin Nabob",
    "The Mind Stone",
    "Land Tax",
    "Lorehold, the Historian",
    "Underworld Breach",
}
FOCUS_TRACE_EVENTS = {
    "activated_ability",
    "cost_paid",
    "focus_card_access_snapshot",
    "forced_focus_access_applied",
    "land_tax_trigger_resolved",
    "land_tax_trigger_skipped",
    "lorehold_upkeep_rummage",
    "replacement_applied",
    "saga_chapter_progressed",
    "saga_chapter_resolved",
    "saga_sacrificed_by_sba",
    "topdeck_manipulation_activated",
    "trigger_resolved",
    "trigger_skipped",
    "utility_artifact_activated",
} | LOREHOLD_RUNTIME_EFFECT_EVENTS
FOCUS_ACCESS_ZONES = {"hand", "battlefield", "graveyard", "exile", "stack"}


def native_probe_safety_contract() -> dict[str, Any]:
    return {
        "engine_scope": "native_python_battle_analyst_v9",
        "evidence_scope": "diagnostic_native_only",
        "seed_schedule_scope": "native_python_simulator_only",
        "external_engine_seed_pairing_claim": False,
        "promotion_allowed": False,
        "automatic_mutation_performed": False,
        "promotion_gate": INDEPENDENT_PROMOTION_GATE,
    }


def focus_trace_cards() -> set[str]:
    cards = set(BASE_FOCUS_TRACE_CARDS)
    raw = os.environ.get("MANALOOM_FOCUS_ACCESS_CARDS", "")
    if not raw:
        return cards
    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError:
        parsed = [part.strip() for part in raw.split("|") if part.strip()]
    if isinstance(parsed, list):
        cards.update(str(item).strip() for item in parsed if str(item).strip())
    return cards


def trace_card_names_from_snapshots(value: Any) -> set[str]:
    names: set[str] = set()
    if not isinstance(value, list):
        return names
    for item in value:
        if isinstance(item, Mapping):
            name = str(item.get("name") or "").strip()
        else:
            name = str(item or "").strip()
        if name:
            names.add(name)
    return names


def focus_card_access_by_game_from_traces(
    traces_by_game: Mapping[str, Any],
) -> dict[str, dict[str, dict[str, Any]]]:
    card_names: set[str] = set()
    for traces in traces_by_game.values():
        if not isinstance(traces, list):
            continue
        for trace in traces:
            if not isinstance(trace, Mapping):
                continue
            data = trace.get("data") or {}
            zones = data.get("focus_card_zones") if isinstance(data, Mapping) else None
            if isinstance(zones, Mapping):
                card_names.update(str(name) for name in zones)

    by_card: dict[str, dict[str, dict[str, Any]]] = {}
    for card_name in sorted(card_names):
        by_game: dict[str, dict[str, Any]] = {}
        for raw_game_id, traces in traces_by_game.items():
            if not isinstance(traces, list):
                continue
            game_id = str(raw_game_id)
            profile: dict[str, Any] = {
                "trace_count": 0,
                "zone_counts": {},
                "accessed": False,
                "near_access": False,
                "drawn": False,
                "opening_hand": False,
                "library_only": False,
                "dominant_zone": None,
            }
            zone_counts: dict[str, int] = {}
            observed = False
            saw_library = False
            for trace in traces:
                if not isinstance(trace, Mapping):
                    continue
                data = trace.get("data") or {}
                if not isinstance(data, Mapping):
                    continue
                zones = data.get("focus_card_zones") or {}
                zone_info = zones.get(card_name) if isinstance(zones, Mapping) else None
                if not isinstance(zone_info, Mapping):
                    continue
                zone = str(zone_info.get("zone") or "").strip()
                if not zone:
                    continue
                profile["trace_count"] = int(profile["trace_count"]) + 1
                zone_counts[zone] = zone_counts.get(zone, 0) + 1
                if zone != "absent":
                    observed = True
                if zone == "library":
                    saw_library = True
                drawn_names = (
                    trace_card_names_from_snapshots(data.get("drawn_for_turn"))
                    | trace_card_names_from_snapshots(data.get("drawn"))
                    | trace_card_names_from_snapshots(data.get("first_draw"))
                )
                if card_name in drawn_names:
                    profile["drawn"] = True
                    profile["accessed"] = True
                if card_name in set(data.get("hand_focus") or []):
                    profile["accessed"] = True
                if zone in FOCUS_ACCESS_ZONES:
                    profile["accessed"] = True
                if (
                    bool(zone_info.get("library_top_7"))
                    or card_name in set(data.get("library_top_focus") or [])
                ):
                    profile["near_access"] = True
                if data.get("phase") == "opening_keep" and zone == "hand":
                    profile["opening_hand"] = True
                    profile["accessed"] = True
            if not observed and not int(profile["trace_count"]):
                continue
            profile["zone_counts"] = dict(sorted(zone_counts.items()))
            if zone_counts:
                profile["dominant_zone"] = max(zone_counts.items(), key=lambda item: item[1])[0]
            profile["library_only"] = bool(
                saw_library and not profile["accessed"] and not profile["near_access"]
            )
            by_game[game_id] = profile
        if by_game:
            by_card[card_name] = by_game
    return by_card


def focus_card_access_summary_from_by_game(
    by_card: Mapping[str, Mapping[str, Mapping[str, Any]]],
) -> dict[str, dict[str, Any]]:
    summary: dict[str, dict[str, Any]] = {}
    for card_name, games in by_card.items():
        zone_counts: dict[str, int] = {}
        accessed_games = near_access_games = drawn_games = opening_hand_games = library_only_games = 0
        trace_count = 0
        for profile in games.values():
            if not isinstance(profile, Mapping):
                continue
            trace_count += int(profile.get("trace_count") or 0)
            for zone, count in (profile.get("zone_counts") or {}).items():
                zone_counts[str(zone)] = zone_counts.get(str(zone), 0) + int(count or 0)
            if profile.get("accessed"):
                accessed_games += 1
            if profile.get("near_access"):
                near_access_games += 1
            if profile.get("drawn"):
                drawn_games += 1
            if profile.get("opening_hand"):
                opening_hand_games += 1
            if profile.get("library_only"):
                library_only_games += 1
        dominant_zone = max(zone_counts.items(), key=lambda item: item[1])[0] if zone_counts else None
        summary[str(card_name)] = {
            "trace_count": trace_count,
            "trace_games": len(games),
            "zone_counts": dict(sorted(zone_counts.items())),
            "accessed_games": accessed_games,
            "near_access_games": near_access_games,
            "drawn_games": drawn_games,
            "opening_hand_games": opening_hand_games,
            "library_only_games": library_only_games,
            "dominant_zone": dominant_zone,
        }
    return summary


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
    candidate_deck_id: int = 607,
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
                "load_deck_id": candidate_deck_id,
                "deck_name": candidate_name,
                "archetype": candidate_archetype,
                "source_db": str(candidate_db),
            }
        )
    return specs


def parse_fixed_opponent_deck_ids(raw: str | None) -> list[int]:
    if not raw:
        return []
    return [int(part.strip()) for part in str(raw).split(",") if part.strip()]


def opponent_seed_key(profile: Mapping[str, Any]) -> str:
    """Return a stable opponent identifier for paired per-game seeds."""

    return str(
        profile.get("learned_deck_id")
        or profile.get("fixed_opponent_deck_id")
        or profile.get("name")
        or "unknown-opponent"
    )


def derive_game_seed(
    simulation_seed: int,
    profile: Mapping[str, Any],
    game_index: int,
) -> int:
    """Derive a process-independent seed shared by every compared deck."""

    material = (
        "manaloom-lorehold-paired-game-seed-v1|"
        f"{int(simulation_seed)}|{opponent_seed_key(profile)}|{int(game_index)}"
    ).encode("utf-8")
    return int.from_bytes(hashlib.sha256(material).digest()[:8], "big")


def fixed_opponent_profile_from_deck(db: Path, deck_id: int) -> dict[str, Any]:
    previous_db = Path(str(getattr(battle, "DB", DEFAULT_DB)))
    set_battle_db(db)
    try:
        commander, deck, construction_report = battle.load_deck_with_construction_report(deck_id)
    finally:
        set_battle_db(previous_db)
    if commander is None:
        raise RuntimeError(f"fixed opponent deck {deck_id} has no commander")
    name = f"Fixed Lorehold deck {deck_id}"
    commander_card = dict(commander)
    commander_card["owner"] = name
    return {
        "name": name,
        "archetype": f"fixed_deck_{deck_id}",
        "source": "fixed_deck",
        "fixed_opponent_deck_id": deck_id,
        "source_card_count": len(deck) + 1,
        "battle_card_count": len(deck),
        "built_deck": [dict(card) for card in deck],
        "commander_name": commander.get("name", f"Deck {deck_id} Commander"),
        "commander_card": commander_card,
        "commander_cmc": commander.get("cmc", 4),
        "commander_metadata_source": "deck_cards",
        "strategy": "spells",
        "life": 40,
        "lands": sum(1 for card in deck if battle.card_has_functional_tag(card, "land") or "Land" in card.get("type_line", "")),
        "ramp": sum(1 for card in deck if battle.card_has_functional_tag(card, "ramp", "ritual")),
        "removal": sum(1 for card in deck if battle.card_has_functional_tag(card, "removal", "board_wipe")),
        "counters": sum(1 for card in deck if battle.card_has_functional_tag(card, "counter", "protection")),
        "creatures": sum(1 for card in deck if "Creature" in card.get("type_line", "")),
        "avg_cmc": sum(safe_cmc_from_card(card, unknown_nonland_fallback=0.0) for card in deck) / max(1, len(deck)),
        "is_real": True,
        "is_fixed_opponent": True,
        "construction_report": construction_report,
    }


def load_opponents(
    db: Path,
    *,
    opponent_limit: int,
    opponent_seed: int,
    fixed_opponent_deck_ids: list[int] | None = None,
) -> tuple[str, list[dict[str, Any]]]:
    fixed_ids = list(fixed_opponent_deck_ids or [])
    fixed_profiles = [fixed_opponent_profile_from_deck(db, deck_id) for deck_id in fixed_ids]
    dynamic_limit = max(0, int(opponent_limit) - len(fixed_profiles))
    set_battle_db(db)
    os.environ["MANALOOM_BATTLE_REAL_OPPONENT_LIMIT"] = str(max(1, dynamic_limit))
    os.environ["MANALOOM_BATTLE_REAL_OPPONENT_SEED"] = str(opponent_seed)
    opponents = battle.load_learned_opponents() if dynamic_limit else []
    if opponents:
        kind = "real"
        selected = opponents[:dynamic_limit]
    else:
        kind = "generic"
        selected = list(battle.OPPONENT_ARCHETYPES[:dynamic_limit])
    if fixed_profiles:
        kind = f"{kind}+fixed_deck"
    return kind, fixed_profiles + selected


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
            "discard_to_top_replacement": set(),
            "lorehold_rummage_discard_to_top": set(),
            "hand_to_topdeck_activation": set(),
            "lorehold_rummage_discards_squee": set(),
            "lorehold_spell_rummage": set(),
            "lorehold_spell_rummage_discard_to_top": set(),
            "lorehold_spell_rummage_discards_squee": set(),
            "squee_to_graveyard": set(),
            "squee_return_after_known_graveyard_entry": set(),
            "squee_return_without_known_graveyard_entry": set(),
            "squee_upkeep_return": set(),
            "static_cost_reduction_casts": set(),
            "static_cost_reduction_total": set(),
            "scarlet_static_cost_reduction_casts": set(),
            "scarlet_static_cost_reduction_total": set(),
            "thor_cost_paid": set(),
            "thor_spell_cast": set(),
            "thor_noncreature_damage": set(),
            "thor_noncreature_damage_amount": set(),
        }
        self.cards: Counter[str] = Counter()
        self.card_event_counts: Counter[str] = Counter()
        self.card_event_counts_by_game: dict[str, Counter[str]] = defaultdict(Counter)
        self.runtime_effect_provenance: Counter[tuple[str, ...]] = Counter()
        self.runtime_effect_provenance_games: dict[tuple[str, ...], set[str]] = defaultdict(set)
        self.event_counts_by_game: dict[str, Counter[str]] = defaultdict(Counter)
        self.strategic_event_counts_by_game: dict[str, Counter[str]] = defaultdict(Counter)
        self.lorehold_attack_restriction_totals: Counter[str] = Counter()
        self.lorehold_attack_restriction_totals_by_game: dict[str, Counter[str]] = defaultdict(Counter)
        self.lorehold_attack_restriction_source_events: Counter[str] = Counter()
        self.lorehold_attack_restriction_source_events_by_game: dict[str, Counter[str]] = defaultdict(Counter)
        self.lorehold_attack_restriction_source_attackers_restricted: Counter[str] = Counter()
        self.lorehold_attack_restriction_source_tax_paid: Counter[str] = Counter()
        self.squee_graveyard_entries_by_game: Counter[str] = Counter()
        self.squee_known_graveyard_balance_by_game: Counter[str] = Counter()
        self.squee_game_traces: dict[str, list[dict[str, Any]]] = {}
        self.squee_anomalies: list[dict[str, Any]] = []
        self.squee_trace_samples: list[dict[str, Any]] = []
        self.focus_card_game_traces: dict[str, list[dict[str, Any]]] = {}
        self.focus_card_trace_samples: list[dict[str, Any]] = []
        self.focus_card_trace_card_counts_by_game: dict[str, Counter[str]] = defaultdict(Counter)
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

    def _static_cost_reduction_payloads(self, data: Mapping[str, Any]) -> list[dict[str, Any]]:
        locked_cost = data.get("locked_cost")
        if not isinstance(locked_cost, Mapping):
            return []
        reductions = locked_cost.get("static_cost_reductions")
        if not isinstance(reductions, list):
            return []
        payloads: list[dict[str, Any]] = []
        for item in reductions:
            if not isinstance(item, Mapping):
                continue
            applied_amount = max(0, int(item.get("applied_amount") or item.get("amount") or 0))
            if applied_amount <= 0:
                continue
            payloads.append(
                {
                    "source": str(item.get("source") or "unknown"),
                    "applied_amount": applied_amount,
                    "scope": str(item.get("scope") or ""),
                    "amount_source": str(item.get("amount_source") or ""),
                }
            )
        return payloads

    def _discard_to_top_names(self, data: Mapping[str, Any]) -> list[str]:
        names = self._payload_names(data, ("discarded_to_top", "to_top", "cards_to_top"))
        destinations = self._payload_destinations(data)
        if destinations & {"library_top", "top_of_library"}:
            names.extend(
                self._payload_names(
                    data,
                    ("discarded", "discarded_card", "card", "card_name"),
                )
            )
        return [name for name in names if name]

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

    def _restriction_sources(self, detail: Mapping[str, Any]) -> list[str]:
        raw_sources = detail.get("attack_restriction_sources") or []
        sources: list[str] = []
        if isinstance(raw_sources, str):
            sources.append(raw_sources)
        elif isinstance(raw_sources, list):
            sources.extend(str(source or "") for source in raw_sources)
        for source in detail.get("attack_tax_sources") or []:
            if isinstance(source, dict):
                sources.append(str(source.get("card") or ""))
        if detail.get("source"):
            sources.append(str(detail.get("source") or ""))
        cleaned = []
        for source in sources:
            source = source.strip()
            if source and source not in cleaned:
                cleaned.append(source)
        return cleaned or ["unattributed"]

    def _record_lorehold_attack_restrictions(self, event: str, data: Mapping[str, Any]) -> None:
        if event != "combat_step" or data.get("target") != "Lorehold":
            return
        for detail in data.get("attack_restrictions") or []:
            if not isinstance(detail, Mapping):
                continue
            attackers_restricted = int(detail.get("attackers_restricted") or 0)
            tax_paid = int(detail.get("tax_paid") or 0)
            attackers_before = int(detail.get("attackers_before") or 0)
            attackers_after = int(detail.get("attackers_after") or 0)
            if attackers_restricted <= 0 and tax_paid <= 0:
                continue
            self.lorehold_attack_restriction_totals["events"] += 1
            self.lorehold_attack_restriction_totals["attackers_before"] += attackers_before
            self.lorehold_attack_restriction_totals["attackers_after"] += attackers_after
            self.lorehold_attack_restriction_totals["attackers_restricted"] += attackers_restricted
            self.lorehold_attack_restriction_totals["tax_paid"] += tax_paid
            game_totals = self.lorehold_attack_restriction_totals_by_game[self.current_game]
            game_totals["events"] += 1
            game_totals["attackers_before"] += attackers_before
            game_totals["attackers_after"] += attackers_after
            game_totals["attackers_restricted"] += attackers_restricted
            game_totals["tax_paid"] += tax_paid
            for source in self._restriction_sources(detail):
                self.lorehold_attack_restriction_source_events[source] += 1
                self.lorehold_attack_restriction_source_events_by_game[self.current_game][source] += 1
                self.lorehold_attack_restriction_source_attackers_restricted[source] += attackers_restricted
                self.lorehold_attack_restriction_source_tax_paid[source] += tax_paid

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

    def _focus_card_matches(self, event: str, data: Mapping[str, Any]) -> list[str]:
        focus_cards = focus_trace_cards()
        if event == "focus_card_access_snapshot":
            zones = data.get("focus_card_zones") or {}
            if isinstance(zones, Mapping):
                return sorted(
                    card
                    for card in focus_cards
                    if card in zones and (zones.get(card) or {}).get("zone") != "absent"
                )
        raw = json.dumps(data, sort_keys=True, default=str)
        matches = {
            card
            for card in focus_cards
            if card in raw or data.get("card") == card
        }
        if event == "lorehold_upkeep_rummage" and data.get("player") == "Lorehold":
            matches.add("Lorehold, the Historian")
            if (
                data.get("replacement_used")
                or data.get("discard_destination") in {"top_of_library", "library_top"}
                or self._discard_to_top_names(data)
            ):
                matches.add("Library of Leng")
        if event == "replacement_applied" and data.get("player") == "Lorehold":
            matches.add("Library of Leng")
        if event == "topdeck_manipulation_activated" and data.get("card") in {
            "Sensei's Divining Top",
            "Scroll Rack",
        }:
            matches.add(str(data.get("card")))
        if event in {"land_tax_trigger_resolved", "land_tax_trigger_skipped"} and data.get("card") == "Land Tax":
            matches.add("Land Tax")
        if event.startswith("saga_") and data.get("card") == "Urza's Saga":
            matches.add("Urza's Saga")
        if data.get("card") == "The Mind Stone" and (
            event == "utility_artifact_activated" or data.get("effect") == "harnessed_blink"
        ):
            matches.add("The Mind Stone")
        if "Squee, Goblin Nabob" in raw:
            matches.add("Squee, Goblin Nabob")
        if "Harnfel, Horn of Bounty" in raw:
            matches.add("Birgi, God of Storytelling // Harnfel, Horn of Bounty")
        return sorted(matches)

    @staticmethod
    def _runtime_effect_card(event: str, data: Mapping[str, Any]) -> str | None:
        if event not in LOREHOLD_RUNTIME_EFFECT_EVENTS:
            return None
        raw = json.dumps(data, sort_keys=True, default=str)
        if "Harnfel, Horn of Bounty" in raw:
            return "Birgi, God of Storytelling // Harnfel, Horn of Bounty"
        if "Underworld Breach" in raw or event.startswith("underworld_breach_"):
            return "Underworld Breach"
        if "Mana Vault" in raw or event.startswith("mana_vault_"):
            return "Mana Vault"
        if event.startswith("flashback_") and (
            "Flashback" in raw
            or data.get("flashback_permission_kind") == "target_grant_exact"
        ):
            return "Flashback"
        return str(data.get("card") or "").strip() or None

    def _focus_trace_payload(
        self,
        event: str,
        data: Mapping[str, Any],
        *,
        cards: list[str],
    ) -> dict[str, Any]:
        keep_keys = (
            "player",
            "card",
            "effect",
            "trigger",
            "activation_kind",
            "activation_after_upkeep_untap",
            "phase",
            "turn",
            "chapter",
            "target_type",
            "target",
            "target_controller",
            "target_legal",
            "found",
            "found_cards",
            "found_count",
            "candidate_count",
            "candidate_names",
            "legal_target_names",
            "legal_target_count",
            "selected_reason",
            "top_before",
            "top_after",
            "hand_to_top",
            "hand_gained",
            "hand_size",
            "battlefield_size",
            "graveyard_size",
            "exile_size",
            "library_size",
            "available_mana",
            "lands_played_this_turn",
            "focus_cards_seen",
            "focus_card_zones",
            "hand_focus",
            "battlefield_focus",
            "graveyard_focus",
            "exile_focus",
            "command_zone_focus",
            "library_focus",
            "library_top_focus",
            "top_library",
            "drawn_for_turn",
            "mulligan_count",
            "opening_reason",
            "opening_keep",
            "opening_risk_flags",
            "cleanup_discarded",
            "first_draw",
            "drawn",
            "putback",
            "discarded",
            "discarded_cards",
            "discarded_to_graveyard",
            "discarded_to_top",
            "discard_destination",
            "replacement_used",
            "blink_target",
            "blink_target_score",
            "blinked",
            "returned",
            "condition",
            "condition_met",
            "player_land_count",
            "opponent_land_counts",
            "max_opponent_land_count",
            "reason",
            "source",
            "rule_logical_key",
            "rule_oracle_hash",
            "rule_review_status",
            "battle_model_scope",
            "oracle_runtime_scope",
            "flashback_cost",
            "flashback_cost_source",
            "flashback_granted_by",
            "flashback_permission_kind",
            "permission_turn",
            "permission_consumed",
            "granted_count",
            "duration",
            "stack_outcome",
            "replacement_reason",
            "result",
            "forced_access_mode",
            "mode",
            "source_zone",
            "destination_zone",
            "played_card",
            "played_kind",
            "response_to",
            "mana_added",
            "mana_color",
            "paid",
            "damage_dealt",
            "final_damage",
            "exiled_cards",
            "exiled_count",
            "replaced_card",
            "test_only",
        )
        return {
            "seq": self.event_sequence,
            "game_id": self.current_game,
            "event": event,
            "cards": list(cards),
            "data": {key: data.get(key) for key in keep_keys if key in data},
        }

    def _record_focus_trace(self, event: str, data: Mapping[str, Any]) -> None:
        if event not in FOCUS_TRACE_EVENTS:
            return
        cards = self._focus_card_matches(event, data)
        if not cards:
            return
        trace = self._focus_trace_payload(event, data, cards=cards)
        traces = self.focus_card_game_traces.setdefault(self.current_game, [])
        # Preserve exact runtime events after the ordinary trace budget. They
        # remain native diagnostic evidence until the independent external
        # engine gate and product promotion contract are satisfied.
        if len(traces) < 160 or event in LOREHOLD_RUNTIME_EFFECT_EVENTS:
            traces.append(trace)
        for card in cards:
            self.focus_card_trace_card_counts_by_game[self.current_game][card] += 1
        if len(self.focus_card_trace_samples) < 30:
            self.focus_card_trace_samples.append(trace)

    def record(self, event: str, data: Mapping[str, Any]) -> None:
        self.event_sequence += 1
        self.events[event] += 1
        self.event_counts_by_game[self.current_game][event] += 1
        strategic_before = self.strategic_events.copy()
        player = str(data.get("player") or "")
        card = str(data.get("card") or "")
        self._record_lorehold_attack_restrictions(event, data)
        if player == "Lorehold" and card and event in CARD_EXPOSURE_EVENTS:
            card_event_key = f"{event}:{card}"
            self.card_event_counts[card_event_key] += 1
            self.card_event_counts_by_game[self.current_game][card_event_key] += 1
        runtime_effect_card = self._runtime_effect_card(event, data) if player == "Lorehold" else None
        if runtime_effect_card:
            card_event_key = f"{event}:{runtime_effect_card}"
            self.card_event_counts[card_event_key] += 1
            self.card_event_counts_by_game[self.current_game][card_event_key] += 1
            provenance_key = (
                event,
                runtime_effect_card,
                str(data.get("rule_logical_key") or ""),
                str(data.get("rule_oracle_hash") or ""),
                str(data.get("battle_model_scope") or ""),
                str(data.get("oracle_runtime_scope") or ""),
            )
            self.runtime_effect_provenance[provenance_key] += 1
            self.runtime_effect_provenance_games[provenance_key].add(self.current_game)
            self.strategic_events[event] += 1
            self.games_with.setdefault(event, set()).add(self.current_game)
            self.cards[card_event_key] += 1
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
            static_reductions = self._static_cost_reduction_payloads(data)
            if static_reductions:
                total_saved = sum(int(item["applied_amount"]) for item in static_reductions)
                self.strategic_events["static_cost_reduction_casts"] += 1
                self.strategic_events["static_cost_reduction_total"] += total_saved
                self.games_with["static_cost_reduction_casts"].add(self.current_game)
                self.games_with["static_cost_reduction_total"].add(self.current_game)
                if card:
                    self.cards[f"static_cost_reduction_on:{card}"] += total_saved
                for reduction in static_reductions:
                    source = str(reduction.get("source") or "unknown")
                    amount = int(reduction.get("applied_amount") or 0)
                    self.cards[f"static_cost_reduction_saved:{source}"] += amount
                    self.cards[f"static_cost_reduction_source_cast:{source}"] += 1
                    if source == "The Scarlet Witch":
                        self.strategic_events["scarlet_static_cost_reduction_casts"] += 1
                        self.strategic_events["scarlet_static_cost_reduction_total"] += amount
                        self.games_with["scarlet_static_cost_reduction_casts"].add(self.current_game)
                        self.games_with["scarlet_static_cost_reduction_total"].add(self.current_game)
            if card == "Thor, God of Thunder":
                self.strategic_events["thor_cost_paid"] += 1
                self.games_with["thor_cost_paid"].add(self.current_game)
        elif event == "spell_cast" and player == "Lorehold":
            self.strategic_events["lorehold_spell_cast"] += 1
            self.games_with["lorehold_spell_cast"].add(self.current_game)
            if card == "Thor, God of Thunder":
                self.strategic_events["thor_spell_cast"] += 1
                self.games_with["thor_spell_cast"].add(self.current_game)
                self.cards["spell_cast:Thor, God of Thunder"] += 1
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
            if self._discard_to_top_names(data) or bool(data.get("replacement_used")):
                self.strategic_events["discard_to_top_replacement"] += 1
                self.strategic_events["lorehold_rummage_discard_to_top"] += 1
                self.games_with["discard_to_top_replacement"].add(self.current_game)
                self.games_with["lorehold_rummage_discard_to_top"].add(self.current_game)
                if discarded:
                    self.cards[f"lorehold_rummage_to_top:{discarded}"] += 1
                    self.cards[f"discard_to_top:{discarded}"] += 1
            if discarded == "Squee, Goblin Nabob":
                self.strategic_events["lorehold_rummage_discards_squee"] += 1
                self.games_with["lorehold_rummage_discards_squee"].add(self.current_game)
                self.cards["rummage_discard:Squee, Goblin Nabob"] += 1
        elif event == "trigger_resolved" and player == "Lorehold" and data.get("effect") == "rummage":
            self.strategic_events["lorehold_spell_rummage"] += 1
            self.games_with["lorehold_spell_rummage"].add(self.current_game)
            top_names = self._discard_to_top_names(data)
            if top_names:
                self.strategic_events["discard_to_top_replacement"] += len(top_names)
                self.strategic_events["lorehold_spell_rummage_discard_to_top"] += len(top_names)
                self.games_with["discard_to_top_replacement"].add(self.current_game)
                self.games_with["lorehold_spell_rummage_discard_to_top"].add(self.current_game)
                for top_name in top_names:
                    self.cards[f"spell_rummage_to_top:{top_name}"] += 1
                    self.cards[f"discard_to_top:{top_name}"] += 1
            if "Squee, Goblin Nabob" in self._payload_names(data, ("discarded_to_graveyard", "discarded")):
                self.strategic_events["lorehold_spell_rummage_discards_squee"] += 1
                self.games_with["lorehold_spell_rummage_discards_squee"].add(self.current_game)
                self.cards["spell_rummage_discard:Squee, Goblin Nabob"] += 1
        elif event == "trigger_resolved" and player == "Lorehold" and card == "Thor, God of Thunder" and data.get("effect") == "damage_any_target":
            amount = max(0, int(data.get("amount") or 0))
            self.strategic_events["thor_noncreature_damage"] += 1
            self.strategic_events["thor_noncreature_damage_amount"] += amount
            self.games_with["thor_noncreature_damage"].add(self.current_game)
            self.games_with["thor_noncreature_damage_amount"].add(self.current_game)
            self.cards["thor_noncreature_damage:Thor, God of Thunder"] += 1
            self.cards["thor_noncreature_damage_amount:Thor, God of Thunder"] += amount
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
        self._record_focus_trace(event, data)
        for key, count in self.strategic_events.items():
            delta = count - strategic_before.get(key, 0)
            if delta:
                self.strategic_event_counts_by_game[self.current_game][key] += delta

    def game_summary(self, game_id: str) -> dict[str, Any]:
        return {
            "event_counts": dict(self.event_counts_by_game.get(game_id, {})),
            "strategic_event_counts": dict(self.strategic_event_counts_by_game.get(game_id, {})),
            "card_event_counts": dict(self.card_event_counts_by_game.get(game_id, {})),
            "lorehold_attack_restrictions": dict(
                self.lorehold_attack_restriction_totals_by_game.get(game_id, {})
            ),
            "lorehold_attack_restriction_source_events": dict(
                self.lorehold_attack_restriction_source_events_by_game.get(game_id, {})
            ),
            "squee_known_graveyard_balance": int(self.squee_known_graveyard_balance_by_game.get(game_id, 0)),
            "squee_trace_count": len(self.squee_game_traces.get(game_id, [])),
            "focus_card_trace_count": len(self.focus_card_game_traces.get(game_id, [])),
            "focus_card_trace_card_counts": dict(
                self.focus_card_trace_card_counts_by_game.get(game_id, {})
            ),
            "squee_anomaly_count": sum(
                1 for item in self.squee_anomalies if item.get("game_id") == game_id
            ),
        }

    def as_json(self, total_games: int) -> dict[str, Any]:
        games = max(1, total_games)
        focus_access_by_game = focus_card_access_by_game_from_traces(self.focus_card_game_traces)
        focus_access_summary = focus_card_access_summary_from_by_game(focus_access_by_game)
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
            "card_event_counts": dict(sorted(self.card_event_counts.items())),
            "card_event_counts_by_game": {
                key: dict(value)
                for key, value in sorted(self.card_event_counts_by_game.items())
            },
            "runtime_effect_provenance": [
                {
                    "event": key[0],
                    "card": key[1],
                    "rule_logical_key": key[2] or None,
                    "rule_oracle_hash": key[3] or None,
                    "battle_model_scope": key[4] or None,
                    "oracle_runtime_scope": key[5] or None,
                    "count": count,
                    "games": len(self.runtime_effect_provenance_games.get(key, set())),
                }
                for key, count in sorted(self.runtime_effect_provenance.items())
            ],
            "lorehold_attack_restrictions": dict(self.lorehold_attack_restriction_totals),
            "lorehold_attack_restrictions_by_game": {
                key: dict(value)
                for key, value in sorted(self.lorehold_attack_restriction_totals_by_game.items())
            },
            "lorehold_attack_restriction_source_events": dict(
                sorted(self.lorehold_attack_restriction_source_events.items())
            ),
            "lorehold_attack_restriction_source_events_by_game": {
                key: dict(value)
                for key, value in sorted(self.lorehold_attack_restriction_source_events_by_game.items())
            },
            "lorehold_attack_restriction_source_attackers_restricted": dict(
                sorted(self.lorehold_attack_restriction_source_attackers_restricted.items())
            ),
            "lorehold_attack_restriction_source_tax_paid": dict(
                sorted(self.lorehold_attack_restriction_source_tax_paid.items())
            ),
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
            "card_strategy_counts": dict(sorted(self.cards.items())),
            "squee_trace_samples": list(self.squee_trace_samples),
            "squee_game_traces": {
                key: value
                for key, value in sorted(self.squee_game_traces.items())
            },
            "squee_anomalies": list(self.squee_anomalies),
            "squee_known_graveyard_balance_by_game": dict(self.squee_known_graveyard_balance_by_game),
            "focus_card_trace_samples": list(self.focus_card_trace_samples),
            "focus_card_game_traces": {
                key: value
                for key, value in sorted(self.focus_card_game_traces.items())
            },
            "focus_card_trace_card_counts_by_game": {
                key: dict(value)
                for key, value in sorted(self.focus_card_trace_card_counts_by_game.items())
            },
            "focus_card_access_summary": focus_access_summary,
            "focus_card_access_by_game": focus_access_by_game,
        }


def run_deck_gate(
    *,
    spec: Mapping[str, Any],
    opponents: list[dict[str, Any]],
    games_per_opponent: int,
    simulation_seed: int,
    game_timeout_seconds: float = 0,
    forced_access_mode: str = "none",
    paired_game_seeds: bool = False,
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
    previous_forced_access_mode = os.environ.get("MANALOOM_FORCE_FOCUS_ACCESS_MODE")
    if forced_access_mode and forced_access_mode != "none":
        os.environ["MANALOOM_FORCE_FOCUS_ACCESS_MODE"] = forced_access_mode
    else:
        os.environ.pop("MANALOOM_FORCE_FOCUS_ACCESS_MODE", None)

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
                game_seed = (
                    derive_game_seed(simulation_seed, profile, game_index)
                    if paired_game_seeds
                    else None
                )
                game_rng = random.Random(game_seed) if game_seed is not None else rng
                others = [item for item in opponents if item is not profile]
                picked = [profile] + game_rng.sample(others, min(2, len(others)))
                try:
                    result, turns, reason = simulate_game_with_timeout(
                        copy.deepcopy(commander),
                        copy.deepcopy(deck),
                        copy.deepcopy(picked),
                        game_rng,
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
                        "game_seed": game_seed,
                        "seed_mode": "paired_per_game_v1" if paired_game_seeds else "stream_v1",
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
                            "game_seed": game_seed,
                            "seed_mode": "paired_per_game_v1" if paired_game_seeds else "stream_v1",
                            "completed_games": completed_games,
                            "total_games": total_games,
                            "last_result": result,
                            "last_turns": int(turns or 0),
                            "last_reason": str(reason),
                            "wins": wins,
                            "losses": losses,
                            "stalls": stalls,
                            "game_timeout_seconds": float(game_timeout_seconds or 0),
                            "forced_access_mode": forced_access_mode,
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
        if previous_forced_access_mode is None:
            os.environ.pop("MANALOOM_FORCE_FOCUS_ACCESS_MODE", None)
        else:
            os.environ["MANALOOM_FORCE_FOCUS_ACCESS_MODE"] = previous_forced_access_mode

    lands = sum(1 for card in deck if battle.card_has_functional_tag(card, "land") or "Land" in card.get("type_line", ""))
    ramp = sum(1 for card in deck if battle.card_has_functional_tag(card, "ramp", "ritual"))
    removal = sum(1 for card in deck if battle.card_has_functional_tag(card, "removal", "board_wipe"))
    return {
        **dict(spec),
        **native_probe_safety_contract(),
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
        "seed_mode": "paired_per_game_v1" if paired_game_seeds else "stream_v1",
        "forced_access_mode": forced_access_mode,
        "telemetry": telemetry.as_json(total_games),
    }


def _run_deck_gate_process_entry(queue: Any, kwargs: dict[str, Any]) -> None:
    try:
        queue_progress = bool(kwargs.pop("_queue_progress", False))
        result_path = kwargs.pop("_result_path", None)
        if queue_progress:
            def child_progress_callback(event: dict[str, Any]) -> None:
                queue.put({"type": "progress", "event": dict(event)})

            kwargs["progress_callback"] = child_progress_callback
        result = run_deck_gate(**kwargs)
        if result_path:
            Path(str(result_path)).write_text(
                json.dumps(result, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            queue.put({"type": "result", "ok": True, "result_path": str(result_path)})
        else:
            queue.put({"type": "result", "ok": True, "result": result})
    except Exception as exc:
        queue.put(
            {
                "type": "result",
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
    forced_access_mode: str = "none",
    paired_game_seeds: bool = False,
    progress_callback: Callable[[dict[str, Any]], None] | None = None,
    process_timeout_seconds: float = 0,
) -> dict[str, Any]:
    ctx = mp.get_context("spawn")
    queue: Any = ctx.Queue()
    result_fd, result_path_raw = tempfile.mkstemp(
        prefix="lorehold_deck_gate_",
        suffix=".json",
        dir=str(REPORT_DIR),
    )
    os.close(result_fd)
    result_path = Path(result_path_raw)
    kwargs = {
        "spec": dict(spec),
        "opponents": opponents,
        "games_per_opponent": games_per_opponent,
        "simulation_seed": simulation_seed,
        "game_timeout_seconds": game_timeout_seconds,
        "forced_access_mode": forced_access_mode,
        "paired_game_seeds": paired_game_seeds,
        "progress_callback": None,
        "_queue_progress": progress_callback is not None,
        "_result_path": str(result_path),
    }
    process = ctx.Process(target=_run_deck_gate_process_entry, args=(queue, kwargs))
    process.start()
    total_games = max(1, games_per_opponent) * max(1, len(opponents))
    default_timeout = max(120.0, total_games * max(5.0, float(game_timeout_seconds or 0.0)) + 120.0)
    timeout = float(process_timeout_seconds or 0.0) or default_timeout
    deadline = time.monotonic() + timeout
    payload: dict[str, Any] | None = None
    while payload is None:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        if result_path.exists() and result_path.stat().st_size > 0:
            payload = {"type": "result", "ok": True, "result_path": str(result_path)}
            break
        try:
            item = queue.get(timeout=min(1.0, max(0.05, remaining)))
        except queue_module.Empty:
            if not process.is_alive():
                break
            continue
        if item.get("type") == "progress":
            if progress_callback is not None:
                progress_callback(dict(item.get("event") or {}))
            continue
        payload = item

    process.join(0 if payload is not None else max(0.0, deadline - time.monotonic()))
    if process.is_alive():
        process.terminate()
        process.join(10)
        if process.is_alive() and hasattr(process, "kill"):
            process.kill()
            process.join(5)
        if payload is None:
            raise RuntimeError(f"isolated deck process timed out after {timeout:.1f}s")
    while payload is None:
        try:
            item = queue.get_nowait()
        except queue_module.Empty:
            break
        if item.get("type") == "progress":
            if progress_callback is not None:
                progress_callback(dict(item.get("event") or {}))
            continue
        payload = item

    if process.exitcode != 0 and payload is None:
        raise RuntimeError(f"isolated deck process exited with code {process.exitcode}")
    if payload is None:
        raise RuntimeError("isolated deck process exited without result payload")
    if not payload.get("ok"):
        raise RuntimeError(payload.get("error") or payload.get("traceback") or "isolated deck process failed")
    if payload.get("result_path"):
        result = json.loads(Path(str(payload["result_path"])).read_text(encoding="utf-8"))
        try:
            Path(str(payload["result_path"])).unlink()
        except FileNotFoundError:
            pass
    else:
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

    def pressure_source_summary(telemetry: Mapping[str, Any]) -> str:
        source_events = telemetry.get("lorehold_attack_restriction_source_events") or {}
        source_restricted = (
            telemetry.get("lorehold_attack_restriction_source_attackers_restricted") or {}
        )
        source_tax = telemetry.get("lorehold_attack_restriction_source_tax_paid") or {}
        if not source_events:
            return "none"
        return ", ".join(
            f"{source}: events={source_events.get(source, 0)}, "
            f"restricted={source_restricted.get(source, 0)}, tax={source_tax.get(source, 0)}"
            for source in sorted(source_events)
        )

    lines = [
        "# Lorehold Equal Battle Gate",
        "",
        f"- generated_at: `{report['generated_at']}`",
        f"- source_db: `{report['source_db']}`",
        f"- games_per_opponent: `{report['games_per_opponent']}`",
        f"- opponent_kind: `{report['opponent_kind']}`",
        f"- opponent_seed: `{report['opponent_seed']}`",
        f"- fixed_opponent_deck_ids: `{', '.join(str(item) for item in report.get('fixed_opponent_deck_ids') or []) or 'none'}`",
        f"- simulation_seed: `{report['simulation_seed']}`",
        f"- python_hash_seed: `{report.get('python_hash_seed', 'unset')}`",
        f"- deck_process_isolation: `{report.get('deck_process_isolation', False)}`",
        f"- game_timeout_seconds: `{report.get('game_timeout_seconds', 0)}`",
        f"- forced_access_mode: `{report.get('forced_access_mode', 'none')}`",
        f"- game_checkpoint_json: `{report.get('game_checkpoint_json')}`",
        f"- opponents: `{', '.join(report.get('opponents') or [])}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Battle Ranking",
        "",
        "| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |",
        "| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |",
    ]
    for row in rows:
        telemetry = row.get("telemetry") or {}
        strategic_games = telemetry.get("strategic_games") or {}
        pressure_totals = telemetry.get("lorehold_attack_restrictions") or {}
        miracle_games = (strategic_games.get("miracle_cast") or {}).get("games", 0)
        topdeck_games = (strategic_games.get("topdeck_manipulation_activated") or {}).get("games", 0)
        discard_to_top_games = (strategic_games.get("discard_to_top_replacement") or {}).get("games", 0)
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
            f"{miracle_games} | {topdeck_games} | {discard_to_top_games} | {squee_graveyard_games} | {squee_return_games} | "
            f"{explained_return_games} | {unexplained_return_games} | {rummage_games} | "
            f"{pressure_totals.get('attackers_restricted', 0)} | "
            f"{pressure_totals.get('tax_paid', 0)} | {pressure_source_summary(telemetry)} | {risks} |"
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
        pressure_totals = telemetry.get("lorehold_attack_restrictions") or {}
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
                "**Lorehold attack restriction telemetry:** "
                f"events={pressure_totals.get('events', 0)}, "
                f"attackers_before={pressure_totals.get('attackers_before', 0)}, "
                f"attackers_after={pressure_totals.get('attackers_after', 0)}, "
                f"attackers_restricted={pressure_totals.get('attackers_restricted', 0)}, "
                f"tax_paid={pressure_totals.get('tax_paid', 0)}, "
                f"sources={pressure_source_summary(telemetry)}",
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
        f"- forced_access_mode: `{payload.get('forced_access_mode', 'none')}`",
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
    parser.add_argument("--candidate-deck-id", type=int, default=607)
    parser.add_argument("--no-candidate", action="store_true")
    parser.add_argument("--matrix", type=Path, default=DEFAULT_MATRIX)
    parser.add_argument("--games", type=int, default=1)
    parser.add_argument("--opponent-limit", type=int, default=3)
    parser.add_argument("--opponent-seed", type=int, default=20260626)
    parser.add_argument(
        "--fixed-opponent-deck-ids",
        default=None,
        help=(
            "Comma-separated local deck ids to inject as fixed real opponents. "
            "Use 607 when testing from-scratch Lorehold challengers against the protected baseline."
        ),
    )
    parser.add_argument("--simulation-seed", type=int, default=42)
    parser.add_argument(
        "--paired-game-seeds",
        action="store_true",
        help=(
            "Derive a deterministic schedule for each opponent/game index inside "
            "the native Python simulator only. It does not pair XMage/Forge outcomes "
            "and never authorizes promotion."
        ),
    )
    parser.add_argument("--game-timeout-seconds", type=float, default=0.0)
    parser.add_argument(
        "--deck-process-timeout-seconds",
        type=float,
        default=0.0,
        help="Optional wall-clock cap for each isolated deck process. Defaults to a game-count based budget.",
    )
    parser.add_argument("--checkpoint-stem", default=None)
    parser.add_argument("--checkpoint-history-limit", type=int, default=200)
    parser.add_argument("--no-game-checkpoint", action="store_true")
    parser.add_argument(
        "--force-focus-access",
        choices=("none", "opening_hand", "library_top"),
        default="none",
        help=(
            "Test-only exposure mode for MANALOOM_FOCUS_ACCESS_CARDS. "
            "opening_hand replaces one non-focus opening card with the focus card; "
            "library_top moves it to the top of the opening library."
        ),
    )
    parser.add_argument(
        "--isolate-deck-process",
        action="store_true",
        help="Run each deck/candidate in a fresh Python process to avoid battle runtime global-state bleed.",
    )
    parser.add_argument("--stem", default="lorehold_variant_battle_gate_20260626_v1")
    args = parser.parse_args()

    deck_ids = parse_deck_ids(args.deck_ids)
    fixed_opponent_deck_ids = parse_fixed_opponent_deck_ids(args.fixed_opponent_deck_ids)
    specs = deck_specs(
        db=args.db,
        deck_ids=deck_ids,
        candidate_db=args.candidate_db,
        include_candidate=not args.no_candidate,
        candidate_key=args.candidate_key,
        candidate_name=args.candidate_name,
        candidate_archetype=args.candidate_archetype,
        candidate_deck_id=args.candidate_deck_id,
    )
    opponent_kind, opponents = load_opponents(
        args.db,
        opponent_limit=args.opponent_limit,
        opponent_seed=args.opponent_seed,
        fixed_opponent_deck_ids=fixed_opponent_deck_ids,
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
            **native_probe_safety_contract(),
            "generated_at": utc_now(),
            "status": "running",
            "stem": checkpoint_stem,
            "source_db": str(args.db),
            "matrix": str(args.matrix),
            "games_per_opponent": max(1, args.games),
            "opponent_kind": opponent_kind,
            "opponent_seed": args.opponent_seed,
            "fixed_opponent_deck_ids": fixed_opponent_deck_ids,
            "simulation_seed": args.simulation_seed,
            "seed_mode": "paired_per_game_v1" if args.paired_game_seeds else "stream_v1",
            "python_hash_seed": os.environ.get("PYTHONHASHSEED", "unset"),
            "game_timeout_seconds": float(args.game_timeout_seconds or 0),
            "forced_access_mode": args.force_focus_access,
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
                    forced_access_mode=args.force_focus_access,
                    paired_game_seeds=bool(args.paired_game_seeds),
                    progress_callback=progress_callback,
                    process_timeout_seconds=max(0.0, float(args.deck_process_timeout_seconds or 0)),
                )
            else:
                result = run_deck_gate(
                    spec=spec,
                    opponents=opponents,
                    games_per_opponent=max(1, args.games),
                    simulation_seed=args.simulation_seed,
                    game_timeout_seconds=max(0.0, float(args.game_timeout_seconds or 0)),
                    forced_access_mode=args.force_focus_access,
                    paired_game_seeds=bool(args.paired_game_seeds),
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
            **native_probe_safety_contract(),
            "generated_at": utc_now(),
            "status": "partial",
            "source_db": str(args.db),
            "matrix": str(args.matrix),
            "games_per_opponent": max(1, args.games),
            "opponent_kind": opponent_kind,
            "opponent_seed": args.opponent_seed,
            "fixed_opponent_deck_ids": fixed_opponent_deck_ids,
            "simulation_seed": args.simulation_seed,
            "seed_mode": "paired_per_game_v1" if args.paired_game_seeds else "stream_v1",
            "python_hash_seed": os.environ.get("PYTHONHASHSEED", "unset"),
            "deck_process_isolation": bool(args.isolate_deck_process),
            "game_timeout_seconds": float(args.game_timeout_seconds or 0),
            "forced_access_mode": args.force_focus_access,
            "game_checkpoint_json": None if args.no_game_checkpoint else str(checkpoint_json),
            "game_checkpoint_markdown": None if args.no_game_checkpoint else str(checkpoint_md),
            "opponents": [opponent.get("name", "?") for opponent in opponents],
            "results": merge_structural_context(results, matrix_scores),
        }
        write_report(partial_report, partial_stem)

    report = {
        **native_probe_safety_contract(),
        "generated_at": utc_now(),
        "status": "ready",
        "source_db": str(args.db),
        "matrix": str(args.matrix),
        "candidate_db": str(args.candidate_db) if args.candidate_db else None,
        "games_per_opponent": max(1, args.games),
        "opponent_kind": opponent_kind,
        "opponent_seed": args.opponent_seed,
        "fixed_opponent_deck_ids": fixed_opponent_deck_ids,
        "simulation_seed": args.simulation_seed,
        "seed_mode": "paired_per_game_v1" if args.paired_game_seeds else "stream_v1",
        "python_hash_seed": os.environ.get("PYTHONHASHSEED", "unset"),
        "deck_process_isolation": bool(args.isolate_deck_process),
        "game_timeout_seconds": float(args.game_timeout_seconds or 0),
        "forced_access_mode": args.force_focus_access,
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
                **native_probe_safety_contract(),
                "generated_at": utc_now(),
                "status": "ready",
                "stem": checkpoint_stem,
                "source_db": str(args.db),
                "matrix": str(args.matrix),
                "games_per_opponent": max(1, args.games),
                "opponent_kind": opponent_kind,
                "opponent_seed": args.opponent_seed,
                "fixed_opponent_deck_ids": fixed_opponent_deck_ids,
                "simulation_seed": args.simulation_seed,
                "seed_mode": "paired_per_game_v1" if args.paired_game_seeds else "stream_v1",
                "python_hash_seed": os.environ.get("PYTHONHASHSEED", "unset"),
                "deck_process_isolation": bool(args.isolate_deck_process),
                "game_timeout_seconds": float(args.game_timeout_seconds or 0),
                "forced_access_mode": args.force_focus_access,
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
