#!/usr/bin/env python3
"""Audit failure-targeted Lorehold traces for the current hypothesis queue.

This read-only helper consumes the synthesis report plus existing seed gates.
It does not promote a deck or invent a card swap. Its job is narrower: state
what trace evidence exists for the failing/strong seeds, what is only aggregate,
and which runtime trace gaps block the next credible test.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_SYNTHESIS = REPORT_DIR / "lorehold_failure_targeted_synergy_hypotheses_20260628_v1.json"
CANDIDATE_KEY = "candidate_607_squee_hashseed0_isolated_cached_timeout_v3"

DEFAULT_GATE_PATHS = [
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed7_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260625_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed42_20260627_v1.json",
]

DEFAULT_DIAGNOSTIC_GATE_PATHS = [
    REPORT_DIR / "lorehold_focus_access_diag_seed7_candidate_only_20260628_v1.json",
    REPORT_DIR / "lorehold_focus_access_diag_seed20260625_candidate_only_20260628_v1.json",
    REPORT_DIR / "lorehold_focus_access_diag_seed42_candidate_only_20260628_v1.json",
]

DEFAULT_FOCUS_CARDS = [
    "Urza's Saga",
    "Library of Leng",
    "Sensei's Divining Top",
    "Scroll Rack",
    "Squee, Goblin Nabob",
    "The Mind Stone",
    "Land Tax",
]

CORE_EVENTS = [
    "lorehold_cost_paid",
    "lorehold_spell_cast",
    "lorehold_spell_rummage",
    "lorehold_rummage_discards_squee",
    "lorehold_spell_rummage_discards_squee",
    "lorehold_upkeep_rummage",
    "miracle_cast",
    "topdeck_manipulation_activated",
    "squee_to_graveyard",
    "squee_upkeep_return",
    "squee_return_after_known_graveyard_entry",
    "squee_return_without_known_graveyard_entry",
    "graveyard_upkeep_return_self_to_hand",
    "saga_chapter_progressed",
    "saga_chapter_resolved",
    "saga_sacrificed_by_sba",
    "land_tax_trigger_resolved",
    "land_tax_trigger_skipped",
    "replacement_applied",
    "utility_artifact_activated",
    "utility_land_activated",
    "tutor_resolved",
    "random_discard_after_tutor",
]

CARD_EVENT_KEYS = {
    "Urza's Saga": [
        "saga_chapter_progressed",
        "saga_chapter_resolved",
        "saga_sacrificed_by_sba",
        "tutor_resolved",
    ],
    "Library of Leng": [
        "replacement_applied",
        "lorehold_rummage_discard_to_top",
        "lorehold_spell_rummage_discard_to_top",
    ],
    "Sensei's Divining Top": ["topdeck_manipulation_activated"],
    "Scroll Rack": ["topdeck_manipulation_activated"],
    "Squee, Goblin Nabob": [
        "squee_to_graveyard",
        "squee_upkeep_return",
        "squee_return_after_known_graveyard_entry",
        "squee_return_without_known_graveyard_entry",
        "graveyard_upkeep_return_self_to_hand",
        "lorehold_rummage_discards_squee",
        "lorehold_spell_rummage_discards_squee",
    ],
    "The Mind Stone": ["utility_artifact_activated"],
    "Land Tax": ["land_tax_trigger_resolved", "land_tax_trigger_skipped"],
}

CARD_TRACE_REQUIRED_FIELDS = {
    "trace_seed7_engine_access_sequence": [
        "opening/early-turn hand or battlefield presence",
        "card-specific topdeck activation source per game",
        "Squee hand to graveyard route",
    ],
    "trace_seed20260625_conversion_window": [
        "discard-to-top target identity",
        "The Mind Stone blink target identity",
        "Land Tax trigger payload and resulting hand quality",
    ],
    "audit_urzas_saga_artifact_tutor_scope": [
        "Saga chapter payload",
        "artifact tutor target identity",
        "whether Top or Library are legal/reachable Saga targets",
    ],
    "audit_squee_graveyard_entry_route": [
        "Squee zone move reason",
        "whether Lorehold rummage discards Squee",
        "whether Library replacement conflicts with graveyard entry",
    ],
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def seed_label(payload: Mapping[str, Any], path: Path) -> str:
    if payload.get("simulation_seed") is not None:
        return str(payload["simulation_seed"])
    match = re.search(r"seed(\d+)", path.name)
    return match.group(1) if match else "unknown"


def focus_cards_from_synthesis(payload: Mapping[str, Any]) -> list[str]:
    cards: list[str] = []
    for row in payload.get("hypotheses") or []:
        for card in row.get("focus_cards") or []:
            if str(card).strip() and card not in cards:
                cards.append(str(card))
    return cards or list(DEFAULT_FOCUS_CARDS)


def split_metric_key(value: object) -> tuple[str, str]:
    raw = str(value or "")
    if ":" not in raw:
        return raw, ""
    prefix, card = raw.split(":", 1)
    return prefix, card


def candidate_result(payload: Mapping[str, Any], candidate_key: str) -> dict[str, Any]:
    for result in payload.get("results") or []:
        if result.get("deck_key") == candidate_key:
            return dict(result)
    return {}


def subset_counts(counts: Mapping[str, Any], keys: Iterable[str] = CORE_EVENTS) -> dict[str, int]:
    out: dict[str, int] = {}
    for key in keys:
        value = int(counts.get(key) or 0)
        if value:
            out[key] = value
    return out


def summarize_strategic_games(games: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for event in CORE_EVENTS:
        row = games.get(event) or {}
        if not isinstance(row, Mapping):
            continue
        game_count = int(row.get("games") or 0)
        rate = float(row.get("rate") or 0.0)
        if game_count or rate:
            out[event] = {"games": game_count, "rate": round(rate, 4)}
    return out


def top_card_metrics_by_card(result: Mapping[str, Any], focus_cards: Iterable[str]) -> dict[str, list[dict[str, Any]]]:
    lookup = {normalize_key(card): card for card in focus_cards}
    metrics: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in (result.get("telemetry") or {}).get("top_cards") or []:
        prefix, card = split_metric_key(row.get("key"))
        normalized = normalize_key(card)
        if normalized not in lookup:
            continue
        metrics[lookup[normalized]].append(
            {
                "metric": row.get("key"),
                "metric_type": prefix,
                "count": int(row.get("count") or 0),
            }
        )
    return dict(sorted(metrics.items()))


def summarize_game_results(result: Mapping[str, Any]) -> dict[str, Any]:
    rows = []
    games_with: Counter[str] = Counter()
    event_totals: Counter[str] = Counter()
    strategic_totals: Counter[str] = Counter()
    outcome_counts: Counter[str] = Counter()
    for game in result.get("game_results") or []:
        event_counts = subset_counts(game.get("event_counts") or {})
        strategic_counts = subset_counts(game.get("strategic_event_counts") or {})
        outcome = str(game.get("result") or "unknown")
        outcome_counts[outcome] += 1
        for key, value in event_counts.items():
            event_totals[key] += value
            games_with[key] += 1
        for key, value in strategic_counts.items():
            strategic_totals[key] += value
            games_with[key] += 1
        rows.append(
            {
                "game_id": game.get("game_id"),
                "game_index": game.get("game_index"),
                "opponent": game.get("opponent"),
                "result": outcome,
                "reason": game.get("reason"),
                "turns": int(game.get("turns") or 0),
                "squee_trace_count": int(game.get("squee_trace_count") or 0),
                "squee_known_graveyard_balance": int(game.get("squee_known_graveyard_balance") or 0),
                "event_counts": event_counts,
                "strategic_event_counts": strategic_counts,
            }
        )
    return {
        "game_count": len(rows),
        "outcome_counts": dict(sorted(outcome_counts.items())),
        "event_totals": dict(sorted(event_totals.items())),
        "strategic_event_totals": dict(sorted(strategic_totals.items())),
        "games_with": dict(sorted(games_with.items())),
        "games": rows,
    }


def trace_payload(row: Mapping[str, Any]) -> dict[str, Any]:
    payload = dict(row)
    data = row.get("data")
    if isinstance(data, Mapping):
        payload.update(data)
    return payload


def summarize_squee_traces(result: Mapping[str, Any], focus_cards: Iterable[str]) -> dict[str, Any]:
    telemetry = result.get("telemetry") or {}
    traces = telemetry.get("squee_game_traces") or {}
    focus_lookup = {normalize_key(card): card for card in focus_cards}
    event_counts: Counter[str] = Counter()
    reason_counts: Counter[str] = Counter()
    matched_cards: dict[str, Counter[str]] = defaultdict(Counter)
    game_counts: dict[str, Counter[str]] = defaultdict(Counter)
    lorehold_squee_discards = 0
    samples: list[dict[str, Any]] = []

    for game_id, events in traces.items():
        for row in events or []:
            payload = trace_payload(row)
            event = str(payload.get("event") or "")
            event_counts[event] += 1
            game_counts[str(game_id)][event] += 1
            card = payload.get("card")
            if card and normalize_key(card) in focus_lookup:
                matched_cards[focus_lookup[normalize_key(card)]][event] += 1
            if isinstance(payload.get("discarded_cards"), list):
                for discarded in payload["discarded_cards"]:
                    if normalize_key(discarded) == normalize_key("Squee, Goblin Nabob"):
                        lorehold_squee_discards += 1
                        matched_cards["Squee, Goblin Nabob"]["discarded_cards"] += 1
            if normalize_key(card) == normalize_key("Squee, Goblin Nabob") and payload.get("reason"):
                reason_counts[str(payload.get("reason"))] += 1
            if len(samples) < 20 and (
                normalize_key(card) in focus_lookup
                or "squee" in event.lower()
                or "graveyard" in event.lower()
            ):
                samples.append(
                    {
                        "game_id": game_id,
                        "seq": payload.get("seq"),
                        "event": event,
                        "card": card,
                        "turn": payload.get("turn"),
                        "reason": payload.get("reason"),
                        "source": payload.get("source"),
                        "markers": payload.get("markers"),
                    }
                )

    return {
        "trace_game_count": len(traces),
        "trace_row_count": sum(event_counts.values()),
        "event_counts": dict(sorted(event_counts.items())),
        "matched_cards": {card: dict(sorted(counts.items())) for card, counts in sorted(matched_cards.items())},
        "squee_known_graveyard_balance_by_game": dict(
            sorted((telemetry.get("squee_known_graveyard_balance_by_game") or {}).items())
        ),
        "squee_anomaly_count": len(telemetry.get("squee_anomalies") or []),
        "squee_graveyard_reason_counts": dict(sorted(reason_counts.items())),
        "lorehold_squee_discard_count": lorehold_squee_discards,
        "game_event_counts": {game_id: dict(sorted(counts.items())) for game_id, counts in sorted(game_counts.items())},
        "samples": samples,
    }


def summarize_focus_traces(result: Mapping[str, Any], focus_cards: Iterable[str]) -> dict[str, Any]:
    telemetry = result.get("telemetry") or {}
    traces = telemetry.get("focus_card_game_traces") or {}
    focus_lookup = {normalize_key(card): card for card in focus_cards}
    event_counts: Counter[str] = Counter()
    matched_cards: dict[str, Counter[str]] = defaultdict(Counter)
    payload_field_counts: dict[str, Counter[str]] = defaultdict(Counter)
    game_counts: dict[str, Counter[str]] = defaultdict(Counter)
    samples: list[dict[str, Any]] = []

    for game_id, rows in traces.items():
        for row in rows or []:
            event = str(row.get("event") or "")
            event_counts[event] += 1
            game_counts[str(game_id)][event] += 1
            cards = [
                focus_lookup.get(normalize_key(card), str(card))
                for card in row.get("cards") or []
                if str(card).strip()
            ]
            data = row.get("data") or {}
            if not isinstance(data, Mapping):
                data = {}
            for card in cards:
                matched_cards[card][event] += 1
                for field, value in data.items():
                    if value not in (None, "", [], {}):
                        payload_field_counts[card][str(field)] += 1
            if len(samples) < 30:
                samples.append(
                    {
                        "game_id": game_id,
                        "seq": row.get("seq"),
                        "event": event,
                        "cards": cards,
                        "data": {
                            key: data.get(key)
                            for key in (
                                "card",
                                "activation_kind",
                                "chapter",
                                "target_type",
                                "found",
                                "found_cards",
                                "candidate_count",
                                "candidate_names",
                                "legal_target_names",
                                "selected_reason",
                                "top_before",
                                "top_after",
                                "hand_to_top",
                                "discarded",
                                "discard_destination",
                                "blink_target",
                                "blinked",
                                "condition_met",
                                "reason",
                                "turn",
                            )
                            if data.get(key) not in (None, "", [], {})
                        },
                    }
                )

    return {
        "trace_game_count": len(traces),
        "trace_row_count": sum(event_counts.values()),
        "event_counts": dict(sorted(event_counts.items())),
        "matched_cards": {card: dict(sorted(counts.items())) for card, counts in sorted(matched_cards.items())},
        "payload_field_counts": {
            card: dict(sorted(counts.items()))
            for card, counts in sorted(payload_field_counts.items())
        },
        "game_event_counts": {game_id: dict(sorted(counts.items())) for game_id, counts in sorted(game_counts.items())},
        "samples": samples,
    }


def summarize_focus_access(result: Mapping[str, Any], focus_cards: Iterable[str]) -> dict[str, Any]:
    telemetry = result.get("telemetry") or {}
    traces = telemetry.get("focus_card_game_traces") or {}
    focus = [str(card) for card in focus_cards]
    zone_counts: dict[str, Counter[str]] = defaultdict(Counter)
    phase_counts: dict[str, Counter[str]] = defaultdict(Counter)
    games_by_card_zone: dict[str, dict[str, set[str]]] = {
        card: defaultdict(set) for card in focus
    }
    first_seen: dict[str, dict[str, Any]] = {}
    first_hand_or_battlefield: dict[str, dict[str, Any]] = {}
    opening_zones: dict[str, Counter[str]] = defaultdict(Counter)
    early_zones: dict[str, Counter[str]] = defaultdict(Counter)
    min_library_position: dict[str, int] = {}
    snapshot_count = 0
    game_count = 0

    for game_id, rows in traces.items():
        game_has_snapshot = False
        for row in rows or []:
            if row.get("event") != "focus_card_access_snapshot":
                continue
            data = row.get("data") or {}
            if not isinstance(data, Mapping):
                continue
            zones = data.get("focus_card_zones") or {}
            if not isinstance(zones, Mapping):
                continue
            snapshot_count += 1
            game_has_snapshot = True
            phase = str(data.get("phase") or "")
            try:
                turn = int(data.get("turn") or 0)
            except (TypeError, ValueError):
                turn = 0
            for card in focus:
                entry = zones.get(card) or {}
                if not isinstance(entry, Mapping):
                    entry = {}
                zone = str(entry.get("zone") or "absent")
                zone_counts[card][zone] += 1
                phase_counts[card][phase] += 1
                games_by_card_zone[card][zone].add(str(game_id))
                if card not in first_seen and zone != "absent":
                    first_seen[card] = {
                        "game_id": game_id,
                        "turn": turn,
                        "phase": phase,
                        "zone": zone,
                        "library_position": entry.get("library_position"),
                    }
                if zone in {"hand", "battlefield"} and card not in first_hand_or_battlefield:
                    first_hand_or_battlefield[card] = {
                        "game_id": game_id,
                        "turn": turn,
                        "phase": phase,
                        "zone": zone,
                    }
                if phase == "opening_keep":
                    opening_zones[card][zone] += 1
                if turn <= 3:
                    early_zones[card][zone] += 1
                if zone == "library" and entry.get("library_position") is not None:
                    try:
                        position = int(entry.get("library_position"))
                    except (TypeError, ValueError):
                        position = 0
                    if position > 0:
                        previous = min_library_position.get(card)
                        if previous is None or position < previous:
                            min_library_position[card] = position
        if game_has_snapshot:
            game_count += 1

    by_card = {}
    for card in focus:
        by_card[card] = {
            "zone_counts": dict(sorted(zone_counts.get(card, {}).items())),
            "phase_counts": dict(sorted(phase_counts.get(card, {}).items())),
            "opening_zones": dict(sorted(opening_zones.get(card, {}).items())),
            "early_zones": dict(sorted(early_zones.get(card, {}).items())),
            "games_by_zone": {
                zone: len(games)
                for zone, games in sorted(games_by_card_zone.get(card, {}).items())
            },
            "first_seen": first_seen.get(card),
            "first_hand_or_battlefield": first_hand_or_battlefield.get(card),
            "min_library_position": min_library_position.get(card),
        }
    return {
        "snapshot_count": snapshot_count,
        "snapshot_game_count": game_count,
        "by_card": by_card,
    }


def card_observation(
    *,
    card: str,
    top_metrics: Mapping[str, list[dict[str, Any]]],
    aggregate_events: Mapping[str, int],
    strategic_events: Mapping[str, int],
    strategic_games: Mapping[str, dict[str, Any]],
    per_game: Mapping[str, Any],
    squee_trace: Mapping[str, Any],
    focus_trace: Mapping[str, Any],
    focus_access: Mapping[str, Any],
) -> dict[str, Any]:
    card_events = CARD_EVENT_KEYS.get(card, [])
    aggregate_event_counts: dict[str, int] = {}
    for key in card_events:
        value = int(aggregate_events.get(key) or strategic_events.get(key) or 0)
        if value:
            aggregate_event_counts[key] = value

    games_with = {
        key: int((strategic_games.get(key) or {}).get("games") or (per_game.get("games_with") or {}).get(key) or 0)
        for key in card_events
    }
    games_with = {key: value for key, value in games_with.items() if value}

    trace_matches = (squee_trace.get("matched_cards") or {}).get(card) or {}
    focus_trace_matches = (focus_trace.get("matched_cards") or {}).get(card) or {}
    access_summary = (focus_access.get("by_card") or {}).get(card) or {}
    metrics = list(top_metrics.get(card) or [])
    has_game_results = int(per_game.get("game_count") or 0) > 0
    has_squee_trace = int(squee_trace.get("trace_game_count") or 0) > 0

    if access_summary and int(focus_access.get("snapshot_count") or 0) > 0:
        evidence_level = "focus_access_trace_available"
    elif focus_trace_matches:
        evidence_level = "focus_card_trace_available"
    elif trace_matches:
        evidence_level = "partial_game_trace_available"
    elif has_game_results and (games_with or aggregate_event_counts):
        evidence_level = "per_game_event_counts_indirect"
    elif metrics and has_game_results:
        evidence_level = "aggregate_card_metric_plus_per_game_family_counts"
    elif metrics:
        evidence_level = "aggregate_card_metric_only"
    elif aggregate_event_counts:
        evidence_level = "aggregate_event_only"
    elif has_squee_trace and card == "Squee, Goblin Nabob":
        evidence_level = "squee_trace_empty_for_card"
    else:
        evidence_level = "not_observed"

    return {
        "card_name": card,
        "evidence_level": evidence_level,
        "top_card_metrics": metrics,
        "aggregate_event_counts": dict(sorted(aggregate_event_counts.items())),
        "games_with": dict(sorted(games_with.items())),
        "squee_trace_matches": dict(sorted(trace_matches.items())),
        "focus_trace_matches": dict(sorted(focus_trace_matches.items())),
        "focus_trace_payload_fields": dict(
            sorted(((focus_trace.get("payload_field_counts") or {}).get(card) or {}).items())
        ),
        "focus_access": access_summary,
    }


def compact_seed_source(
    *,
    path: Path,
    payload: Mapping[str, Any],
    source_type: str,
    candidate_key: str,
    focus_cards: Iterable[str],
) -> dict[str, Any]:
    result = candidate_result(payload, candidate_key)
    telemetry = result.get("telemetry") or {}
    per_game = summarize_game_results(result)
    strategic_games = summarize_strategic_games(telemetry.get("strategic_games") or {})
    aggregate_events = subset_counts(telemetry.get("event_counts") or {})
    strategic_events = subset_counts(telemetry.get("strategic_event_counts") or {})
    top_metrics = top_card_metrics_by_card(result, focus_cards)
    squee_trace = summarize_squee_traces(result, focus_cards)
    focus_trace = summarize_focus_traces(result, focus_cards)
    focus_access = summarize_focus_access(result, focus_cards)

    if per_game["game_count"]:
        trace_data_level = "per_game_event_counts"
    elif squee_trace["trace_game_count"]:
        trace_data_level = "squee_window_trace"
    elif result:
        trace_data_level = "aggregate_only"
    else:
        trace_data_level = "candidate_missing"

    observations = [
        card_observation(
            card=card,
            top_metrics=top_metrics,
            aggregate_events=aggregate_events,
            strategic_events=strategic_events,
            strategic_games=strategic_games,
            per_game=per_game,
            squee_trace=squee_trace,
            focus_trace=focus_trace,
            focus_access=focus_access,
        )
        for card in focus_cards
    ]

    return {
        "seed": seed_label(payload, path),
        "source_type": source_type,
        "source": display_path(path),
        "status": payload.get("status"),
        "candidate_key": candidate_key,
        "candidate_found": bool(result),
        "trace_data_level": trace_data_level,
        "record": {
            "games": int(result.get("games") or 0),
            "wins": int(result.get("wins") or 0),
            "losses": int(result.get("losses") or 0),
            "stalls": int(result.get("stalls") or 0),
            "win_rate": float(result.get("win_rate") or 0.0),
        },
        "aggregate_event_counts": aggregate_events,
        "strategic_event_counts": strategic_events,
        "strategic_games": strategic_games,
        "top_card_metrics_by_card": top_metrics,
        "per_game_summary": {
            key: value for key, value in per_game.items() if key != "games"
        },
        "per_game_samples": per_game["games"][:9],
        "squee_trace_summary": squee_trace,
        "focus_trace_summary": focus_trace,
        "focus_access_summary": focus_access,
        "card_observations": observations,
    }


def load_seed_sources(
    *,
    gate_paths: Iterable[Path],
    diagnostic_gate_paths: Iterable[Path],
    candidate_key: str,
    focus_cards: Iterable[str],
) -> list[dict[str, Any]]:
    rows = []
    for source_type, paths in (("gate", gate_paths), ("diagnostic_gate", diagnostic_gate_paths)):
        for path in paths:
            if not path.exists():
                rows.append(
                    {
                        "seed": "unknown",
                        "source_type": source_type,
                        "source": display_path(path),
                        "status": "missing",
                        "candidate_found": False,
                        "trace_data_level": "missing_report",
                    }
                )
                continue
            payload = read_json(path)
            rows.append(
                compact_seed_source(
                    path=path,
                    payload=payload,
                    source_type=source_type,
                    candidate_key=candidate_key,
                    focus_cards=focus_cards,
                )
            )
    return sorted(
        rows,
        key=lambda row: (
            seed_sort_key(str(row.get("seed"))),
            0 if row.get("source_type") == "diagnostic_gate" else 1,
            str(row.get("source")),
        ),
    )


def seed_sort_key(value: str) -> tuple[int, int | str]:
    if value.isdigit():
        return (0, int(value))
    return (1, value)


def primary_by_seed(seed_sources: Iterable[Mapping[str, Any]]) -> dict[str, dict[str, Any]]:
    grouped: dict[str, list[Mapping[str, Any]]] = defaultdict(list)
    for row in seed_sources:
        grouped[str(row.get("seed"))].append(row)
    out: dict[str, dict[str, Any]] = {}
    for seed, rows in grouped.items():
        candidates = sorted(
            rows,
            key=lambda row: (
                trace_level_rank(str(row.get("trace_data_level"))),
                0 if row.get("source_type") == "diagnostic_gate" else 1,
            ),
        )
        out[seed] = dict(candidates[0])
        out[seed]["available_sources"] = [
            {
                "source_type": item.get("source_type"),
                "source": item.get("source"),
                "trace_data_level": item.get("trace_data_level"),
            }
            for item in rows
        ]
    return out


def trace_level_rank(level: str) -> int:
    order = {
        "per_game_event_counts": 0,
        "squee_window_trace": 1,
        "aggregate_only": 2,
        "candidate_missing": 3,
        "missing_report": 4,
    }
    return order.get(level, 5)


def hypothesis_status(
    hypothesis: Mapping[str, Any],
    seed_records: Mapping[str, dict[str, Any]],
) -> tuple[str, list[str]]:
    key = str(hypothesis.get("hypothesis_key") or "")
    seeds = [str(seed) for seed in hypothesis.get("target_seeds") or []]
    focus_cards = [str(card) for card in hypothesis.get("focus_cards") or []]
    missing_seeds = [seed for seed in seeds if seed not in seed_records]
    if missing_seeds:
        return "trace_source_missing", [f"missing seed reports: {', '.join(missing_seeds)}"]

    reasons: list[str] = []
    per_game_seeds = [
        seed
        for seed in seeds
        if seed_records.get(seed, {}).get("trace_data_level") == "per_game_event_counts"
    ]
    aggregate_only = [
        seed
        for seed in seeds
        if seed_records.get(seed, {}).get("trace_data_level") in {"aggregate_only", "squee_window_trace"}
    ]
    if aggregate_only:
        reasons.append(f"aggregate-only or partial-window seed sources: {', '.join(aggregate_only)}")
    if per_game_seeds:
        reasons.append(f"per-game event counts available for seeds: {', '.join(per_game_seeds)}")

    observed_levels: Counter[str] = Counter()
    not_observed: list[str] = []
    for seed in seeds:
        observations = {
            row.get("card_name"): row
            for row in seed_records.get(seed, {}).get("card_observations") or []
        }
        for card in focus_cards:
            level = str((observations.get(card) or {}).get("evidence_level") or "not_observed")
            observed_levels[level] += 1
            if level == "not_observed":
                not_observed.append(f"{card}@seed{seed}")
    if not_observed:
        reasons.append("not observed in current artifact: " + ", ".join(not_observed[:10]))

    if key == "audit_squee_graveyard_entry_route":
        squee_discards = 0
        squee_trace_games = 0
        for seed in seeds:
            trace = seed_records.get(seed, {}).get("squee_trace_summary") or {}
            squee_discards += int(trace.get("lorehold_squee_discard_count") or 0)
            squee_trace_games += int(trace.get("trace_game_count") or 0)
        if squee_trace_games and squee_discards == 0:
            return "trace_evidence_supports_sequencing_gap", reasons

    if key == "audit_urzas_saga_artifact_tutor_scope":
        if focus_payload_available(
            seed_records,
            seeds,
            "Urza's Saga",
            {"target_type", "candidate_names", "legal_target_names", "selected_reason"},
        ):
            reasons.append(
                "Saga focus trace includes target_type, candidate_names, legal_target_names, and selected_reason"
            )
            return "runtime_trace_payload_available_review_model_scope", reasons
        required = CARD_TRACE_REQUIRED_FIELDS.get(key) or []
        if required:
            reasons.append("missing required payload fields: " + "; ".join(required))
        return "runtime_trace_partial_missing_tutor_payload", reasons

    if key == "trace_seed7_engine_access_sequence" and focus_access_available(seed_records, seeds):
        reasons.extend(focus_access_brief(seed_records, seeds, focus_cards))
        return "focus_access_trace_available_review_sequence", reasons

    if key == "trace_seed20260625_conversion_window" and focus_access_available(seed_records, seeds):
        reasons.extend(focus_access_brief(seed_records, seeds, focus_cards))
        return "focus_access_trace_available_review_conversion", reasons

    required = CARD_TRACE_REQUIRED_FIELDS.get(key) or []
    if required:
        reasons.append("missing required payload fields: " + "; ".join(required))

    if not_observed or required:
        return "trace_partial_missing_payload", reasons
    if observed_levels["partial_game_trace_available"] or observed_levels["per_game_event_counts_indirect"]:
        return "trace_partial_per_game_events", reasons
    return "trace_partial_aggregate_only", reasons


def focus_payload_available(
    seed_records: Mapping[str, dict[str, Any]],
    seeds: Iterable[str],
    card_name: str,
    required_fields: set[str],
) -> bool:
    for seed in seeds:
        observations = {
            row.get("card_name"): row
            for row in seed_records.get(str(seed), {}).get("card_observations") or []
        }
        fields = set((observations.get(card_name) or {}).get("focus_trace_payload_fields") or {})
        if required_fields <= fields:
            return True
    return False


def focus_access_available(
    seed_records: Mapping[str, dict[str, Any]],
    seeds: Iterable[str],
) -> bool:
    for seed in seeds:
        summary = seed_records.get(str(seed), {}).get("focus_access_summary") or {}
        if int(summary.get("snapshot_count") or 0) <= 0:
            return False
    return True


def focus_access_brief(
    seed_records: Mapping[str, dict[str, Any]],
    seeds: Iterable[str],
    focus_cards: Iterable[str],
) -> list[str]:
    reasons = []
    for seed in seeds:
        summary = seed_records.get(str(seed), {}).get("focus_access_summary") or {}
        by_card = summary.get("by_card") or {}
        details = []
        for card in focus_cards:
            row = by_card.get(card) or {}
            opening = row.get("opening_zones") or {}
            early = row.get("early_zones") or {}
            first_hand = row.get("first_hand_or_battlefield") or {}
            min_library = row.get("min_library_position")
            detail = (
                f"{card}:opening={opening or '-'};"
                f"early={early or '-'};"
                f"first_hand_or_battlefield={first_hand or '-'}"
            )
            if min_library is not None:
                detail += f";min_library_position={min_library}"
            details.append(detail)
        if details:
            reasons.append(f"focus access seed {seed}: " + " | ".join(details[:5]))
    return reasons


def build_hypothesis_assessments(
    synthesis: Mapping[str, Any],
    seed_records: Mapping[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    rows = []
    for hypothesis in synthesis.get("hypotheses") or []:
        status, reasons = hypothesis_status(hypothesis, seed_records)
        seeds = [str(seed) for seed in hypothesis.get("target_seeds") or []]
        focus_cards = [str(card) for card in hypothesis.get("focus_cards") or []]
        seed_summaries = []
        for seed in seeds:
            record = seed_records.get(seed) or {}
            observations = {
                row.get("card_name"): row
                for row in record.get("card_observations") or []
                if row.get("card_name") in focus_cards
            }
            seed_summaries.append(
                {
                    "seed": seed,
                    "trace_data_level": record.get("trace_data_level", "missing_report"),
                    "record": record.get("record", {}),
                    "card_observations": observations,
                    "source": record.get("source"),
                }
            )
        rows.append(
            {
                "hypothesis_key": hypothesis.get("hypothesis_key"),
                "source_status": hypothesis.get("status"),
                "trace_status": status,
                "target_failure": hypothesis.get("target_failure"),
                "target_seeds": seeds,
                "focus_cards": focus_cards,
                "current_limitations": reasons,
                "seed_summaries": seed_summaries,
                "next_action": next_action_for_status(status),
            }
        )
    return rows


def next_action_for_status(status: str) -> str:
    if status == "focus_access_trace_available_review_sequence":
        return "review weak-seed access sequence and decide whether tutor/draw density or runtime sequencing is the blocker"
    if status == "focus_access_trace_available_review_conversion":
        return "review conversion-window access trace before changing The Mind Stone, Land Tax, or discard-to-top package"
    if status == "trace_evidence_supports_sequencing_gap":
        return "add sequencing/runtime probe for Squee graveyard entry before testing another card swap"
    if status == "runtime_trace_payload_available_review_model_scope":
        return "review Saga target scope against trace payload before changing cards"
    if status == "runtime_trace_partial_missing_tutor_payload":
        return "extend Urza's Saga trace payload with chapter, tutor target, and legal target set"
    if status == "trace_partial_missing_payload":
        return "rerun targeted diagnostic gate with per-turn hand/battlefield/card-source payload"
    if status == "trace_source_missing":
        return "regenerate missing seed diagnostic report"
    return "keep as evidence only; do not promote a new package from this trace alone"


def build_report(
    *,
    synthesis: Mapping[str, Any],
    gate_paths: Iterable[Path],
    diagnostic_gate_paths: Iterable[Path],
    candidate_key: str = CANDIDATE_KEY,
) -> dict[str, Any]:
    focus_cards = focus_cards_from_synthesis(synthesis)
    seed_sources = load_seed_sources(
        gate_paths=gate_paths,
        diagnostic_gate_paths=diagnostic_gate_paths,
        candidate_key=candidate_key,
        focus_cards=focus_cards,
    )
    seed_records = primary_by_seed(seed_sources)
    hypotheses = build_hypothesis_assessments(synthesis, seed_records)
    status_counts = Counter(str(row["trace_status"]) for row in hypotheses)
    trace_level_counts = Counter(str(row.get("trace_data_level")) for row in seed_records.values())
    return {
        "generated_at": utc_now(),
        "synthesis_report": str(DEFAULT_SYNTHESIS),
        "candidate_key": candidate_key,
        "postgres_writes": False,
        "source_db_mutated": False,
        "summary": {
            "focus_card_count": len(focus_cards),
            "seed_count": len(seed_records),
            "seed_source_count": len(seed_sources),
            "hypothesis_count": len(hypotheses),
            "trace_status_counts": dict(sorted(status_counts.items())),
            "primary_trace_level_counts": dict(sorted(trace_level_counts.items())),
            "recommended_next_action": recommended_next_action(status_counts),
        },
        "focus_cards": focus_cards,
        "seed_sources": seed_sources,
        "primary_seed_records": seed_records,
        "hypothesis_assessments": hypotheses,
        "guardrails": [
            "Do not count aggregate event presence as proof of the intended card sequence.",
            "Do not test another blind swap until weak seeds have per-game focus-card payload.",
            "Treat Urza's Saga target choice and The Mind Stone blink target as runtime trace requirements.",
            "Keep seed 42 as the regression anchor for miracle/topdeck conversion.",
        ],
    }


def recommended_next_action(status_counts: Mapping[str, int]) -> str:
    if status_counts.get("focus_access_trace_available_review_sequence") or status_counts.get(
        "focus_access_trace_available_review_conversion"
    ):
        return "review_focus_access_trace_then_define_next_deck_or_runtime_package"
    if status_counts.get("runtime_trace_partial_missing_tutor_payload"):
        return "extend_focus_card_trace_payload_then_rerun_seed_diagnostics"
    if status_counts.get("runtime_trace_payload_available_review_model_scope"):
        return "review_focus_trace_payload_then_define_next_runtime_or_package_test"
    if status_counts.get("trace_partial_missing_payload"):
        return "rerun_failure_seed_diagnostics_with_focus_card_payload"
    if status_counts.get("trace_source_missing"):
        return "regenerate_missing_seed_reports"
    return "use_trace_findings_to_define_next_targeted_package"


def render_markdown(payload: Mapping[str, Any]) -> str:
    lines = [
        "# Lorehold Failure-Targeted Trace Audit - 2026-06-28",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Candidate key: `{payload['candidate_key']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Recommended next action: `{payload['summary']['recommended_next_action']}`",
        f"- Focus cards: `{payload['summary']['focus_card_count']}`",
        f"- Primary seed records: `{payload['summary']['seed_count']}`",
        f"- Seed source reports: `{payload['summary']['seed_source_count']}`",
        f"- Hypotheses: `{payload['summary']['hypothesis_count']}`",
        f"- Trace statuses: `{json.dumps(payload['summary']['trace_status_counts'], sort_keys=True)}`",
        f"- Primary trace levels: `{json.dumps(payload['summary']['primary_trace_level_counts'], sort_keys=True)}`",
        "",
        "## Seed Records",
        "",
        "| Seed | Trace Level | W | L | S | WR | Miracle | Topdeck | Lorehold Rummage | Squee GY | Squee Return | Squee Trace Games | Source |",
        "| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |",
    ]
    for seed, row in sorted((payload.get("primary_seed_records") or {}).items(), key=lambda item: seed_sort_key(item[0])):
        record = row.get("record") or {}
        strategic = row.get("strategic_event_counts") or {}
        trace = row.get("squee_trace_summary") or {}
        lines.append(
            "| {seed} | `{level}` | {wins} | {losses} | {stalls} | {wr:.2f}% | {miracle} | {topdeck} | {rummage} | {squee_gy} | {squee_return} | {trace_games} | `{source}` |".format(
                seed=seed,
                level=row.get("trace_data_level"),
                wins=int(record.get("wins") or 0),
                losses=int(record.get("losses") or 0),
                stalls=int(record.get("stalls") or 0),
                wr=float(record.get("win_rate") or 0.0),
                miracle=int(strategic.get("miracle_cast") or 0),
                topdeck=int(strategic.get("topdeck_manipulation_activated") or 0),
                rummage=int(strategic.get("lorehold_upkeep_rummage") or 0),
                squee_gy=int(strategic.get("squee_to_graveyard") or 0),
                squee_return=int(strategic.get("squee_upkeep_return") or 0),
                trace_games=int(trace.get("trace_game_count") or 0),
                source=row.get("source"),
            )
        )

    lines.extend(["", "## Focus Card Evidence", ""])
    for seed, row in sorted((payload.get("primary_seed_records") or {}).items(), key=lambda item: seed_sort_key(item[0])):
        lines.append(f"### Seed {seed}")
        lines.append("")
        for obs in row.get("card_observations") or []:
            metric_bits = [
                f"{metric['metric']}={metric['count']}"
                for metric in obs.get("top_card_metrics") or []
            ]
            event_bits = [
                f"{key}={value}"
                for key, value in (obs.get("aggregate_event_counts") or {}).items()
            ]
            game_bits = [
                f"{key}={value}"
                for key, value in (obs.get("games_with") or {}).items()
            ]
            trace_bits = [
                f"{key}={value}"
                for key, value in (obs.get("squee_trace_matches") or {}).items()
            ]
            focus_bits = [
                f"{key}={value}"
                for key, value in (obs.get("focus_trace_matches") or {}).items()
            ]
            field_bits = sorted((obs.get("focus_trace_payload_fields") or {}).keys())
            access = obs.get("focus_access") or {}
            access_bits = []
            if access:
                access_bits.append(f"opening={access.get('opening_zones') or '-'}")
                access_bits.append(f"early={access.get('early_zones') or '-'}")
                access_bits.append(
                    f"first_hand_or_battlefield={access.get('first_hand_or_battlefield') or '-'}"
                )
                if access.get("min_library_position") is not None:
                    access_bits.append(f"min_library_position={access.get('min_library_position')}")
            lines.append(
                "- `{card}`: level=`{level}`, metrics=`{metrics}`, events=`{events}`, games_with=`{games}`, trace=`{trace}`, focus_trace=`{focus}`, focus_fields=`{fields}`, access=`{access}`".format(
                    card=obs["card_name"],
                    level=obs["evidence_level"],
                    metrics=", ".join(metric_bits) or "-",
                    events=", ".join(event_bits) or "-",
                    games=", ".join(game_bits) or "-",
                    trace=", ".join(trace_bits) or "-",
                    focus=", ".join(focus_bits) or "-",
                    fields=", ".join(field_bits) or "-",
                    access="; ".join(access_bits) or "-",
                )
            )
        lines.append("")

    lines.extend(["## Hypothesis Assessments", ""])
    for row in payload.get("hypothesis_assessments") or []:
        lines.append(f"### {row['hypothesis_key']}")
        lines.append("")
        lines.append(f"- Trace status: `{row['trace_status']}`")
        lines.append(f"- Source status: `{row.get('source_status')}`")
        lines.append(f"- Target failure: {row.get('target_failure')}")
        lines.append(f"- Target seeds: `{', '.join(row.get('target_seeds') or [])}`")
        lines.append(f"- Focus cards: {', '.join(row.get('focus_cards') or [])}")
        for limitation in row.get("current_limitations") or []:
            lines.append(f"- Limitation: {limitation}")
        lines.append(f"- Next action: {row['next_action']}")
        lines.append("")

    lines.extend(["## Guardrails", ""])
    for guardrail in payload.get("guardrails") or []:
        lines.append(f"- {guardrail}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--synthesis", type=Path, default=DEFAULT_SYNTHESIS)
    parser.add_argument("--gate", dest="gate_paths", type=Path, action="append")
    parser.add_argument("--diagnostic-gate", dest="diagnostic_gate_paths", type=Path, action="append")
    parser.add_argument("--candidate-key", default=CANDIDATE_KEY)
    parser.add_argument("--stem", default="lorehold_failure_targeted_trace_audit_20260628_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    synthesis = read_json(args.synthesis)
    gate_paths = args.gate_paths or list(DEFAULT_GATE_PATHS)
    diagnostic_gate_paths = args.diagnostic_gate_paths or list(DEFAULT_DIAGNOSTIC_GATE_PATHS)
    payload = build_report(
        synthesis=synthesis,
        gate_paths=gate_paths,
        diagnostic_gate_paths=diagnostic_gate_paths,
        candidate_key=args.candidate_key,
    )
    payload["synthesis_report"] = str(args.synthesis)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
