#!/usr/bin/env python3
"""Compare ManaLoom replay events against a 17Lands replay profile.

This is a read-only calibration gate. It does not decide that 17Lands behavior
is correct for Commander. It highlights when a ManaLoom battle replay is far
outside a real Arena cadence for land drops, spell actions, combat damage, and
positive mana spend. It can also report whether candidate cards were actually
observed before deckbuilder scoring.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
from typing import Any, Mapping


DEFAULT_PRIOR_JSON = Path(
    "docs/hermes-analysis/master_optimizer_reports/"
    "seventeenlands_replay_profile_lci_premierdraft_sample_20260628.json"
)


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True)


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def iter_jsonl(path: Path) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        text = line.strip()
        if not text:
            continue
        try:
            payload = json.loads(text)
        except json.JSONDecodeError as exc:
            raise ValueError(f"{path}:{line_number}: invalid JSONL event") from exc
        if isinstance(payload, dict):
            events.append(payload)
    return events


def normalize_text(value: Any) -> str:
    return " ".join(str(value or "").strip().lower().split())


def parse_int(value: Any) -> int | None:
    if value is None or value == "":
        return None
    try:
        return int(float(str(value)))
    except ValueError:
        return None


def parse_float(value: Any) -> float | None:
    if value is None or value == "":
        return None
    try:
        return float(str(value))
    except ValueError:
        return None


def event_type(event: dict[str, Any]) -> str:
    for key in ("event_type", "type", "event", "kind", "action"):
        value = event.get(key)
        if value:
            return normalize_text(value).replace(" ", "_")
    return "unknown"


def event_turn(event: dict[str, Any]) -> int | None:
    for key in ("turn", "turn_number", "game_turn"):
        value = parse_int(event.get(key))
        if value is not None:
            return value
    return None


def event_value(event: dict[str, Any]) -> float | None:
    mana_before = parse_float(event.get("mana_before"))
    mana_after = parse_float(event.get("mana_after"))
    if mana_before is not None and mana_after is not None:
        return max(0.0, mana_before - mana_after)
    for key in ("value", "amount", "damage", "mana_spent"):
        value = parse_float(event.get(key))
        if value is not None:
            return value
    return None


def event_card_tokens(event: dict[str, Any]) -> set[str]:
    tokens: set[str] = set()
    for key in ("card_name", "name", "card", "source_card", "target_card"):
        value = normalize_text(event.get(key))
        if value:
            tokens.add(value)
    for key in ("arena_id", "card_id", "source_arena_id", "target_arena_id"):
        value = str(event.get(key) or "").strip()
        if value:
            tokens.add(value)
    return tokens


def classify_event(kind: str) -> str | None:
    if kind in {"play_land", "land_played"} or ("land" in kind and "play" in kind):
        return "land_play_entries"
    if "combat_damage" in kind:
        return "total_combat_damage"
    if kind == "cost_paid" or kind == "mana_spent" or "mana_spent" in kind:
        return "active_mana_spent"
    if "cast" in kind and "creature" in kind and "noncreature" not in kind:
        return "creature_cast_entries"
    if "cast" in kind:
        return "noncreature_cast_entries"
    return None


def infer_game_count(events: list[dict[str, Any]], explicit_game_count: int | None) -> int:
    if explicit_game_count is not None:
        return max(1, explicit_game_count)
    game_ids: set[str] = set()
    for event in events:
        for key in ("game_id", "battle_id", "match_id", "replay_id"):
            value = event.get(key)
            if value:
                game_ids.add(str(value))
                break
    return max(1, len(game_ids) if game_ids else (1 if events else 0))


def infer_player_slots(events: list[dict[str, Any]], explicit_player_slots: int | None) -> int:
    if explicit_player_slots is not None:
        return max(1, explicit_player_slots)
    players: set[str] = set()
    for event in events:
        for key in ("player", "active_player"):
            value = normalize_text(event.get(key))
            if value:
                players.add(value)
                break
    return max(1, len(players) if players else 1)


def summarize_events(
    events: list[dict[str, Any]],
    *,
    candidate_cards: list[str],
    game_count: int,
    player_slots: int,
) -> dict[str, Any]:
    per_turn: dict[str, Counter[str]] = {}
    mana_sum: Counter[str] = Counter()
    mana_observations: Counter[str] = Counter()
    candidate_keys = {normalize_text(card): card for card in candidate_cards}
    candidate_report = {
        original: {
            "by_event_type": {},
            "first_turn": None,
            "observed": False,
            "total_events": 0,
        }
        for original in candidate_cards
    }

    for event in events:
        turn = event_turn(event)
        if turn is None or turn < 1:
            continue
        kind = event_type(event)
        metric = classify_event(kind)
        bucket = per_turn.setdefault(str(turn), Counter())
        if metric == "active_mana_spent":
            value = event_value(event)
            if value is not None and value > 0:
                mana_sum[str(turn)] += value
                mana_observations[str(turn)] += 1
        elif metric == "total_combat_damage":
            bucket[metric] += event_value(event) or 0.0
        elif metric is not None:
            bucket[metric] += 1
            if metric in {"creature_cast_entries", "noncreature_cast_entries"}:
                bucket["spell_action_entries"] += 1

        tokens = event_card_tokens(event)
        for normalized, original in candidate_keys.items():
            if normalized not in tokens:
                continue
            row = candidate_report[original]
            row["observed"] = True
            row["total_events"] += 1
            row["by_event_type"][kind] = row["by_event_type"].get(kind, 0) + 1
            if row["first_turn"] is None or turn < row["first_turn"]:
                row["first_turn"] = turn

    turn_summary: dict[str, dict[str, Any]] = {}
    for turn, counts in sorted(per_turn.items(), key=lambda item: int(item[0])):
        observations = int(mana_observations[turn])
        turn_summary[turn] = {
            "active_mana_spent_avg_positive": round(mana_sum[turn] / observations, 3)
            if observations
            else None,
            "active_mana_spent_positive_observations": observations,
            "creature_cast_entries": int(counts["creature_cast_entries"]),
            "land_play_entries": int(counts["land_play_entries"]),
            "noncreature_cast_entries": int(counts["noncreature_cast_entries"]),
            "spell_action_entries": int(counts["spell_action_entries"]),
            "total_combat_damage": float(counts["total_combat_damage"]),
        }

    return {
        "candidate_observations": candidate_report,
        "event_count": len(events),
        "game_count": game_count,
        "player_slots": player_slots,
        "turn_behavior_metrics": turn_summary,
    }


def per_player_slot(value: float | int | None, denominator: int) -> float | None:
    if value is None:
        return None
    return round(float(value) / max(1, denominator), 4)


def ratio(observed: float | None, prior: float | None) -> float | None:
    if observed is None or prior is None or prior == 0:
        return None
    return round(observed / prior, 4)


def compare_to_prior(prior: dict[str, Any], observed: dict[str, Any]) -> dict[str, Any]:
    prior_rows = int(prior.get("rows_sampled") or 1)
    observed_games = int(observed["game_count"] or 1)
    prior_player_slots = 2
    observed_player_slots = int(observed.get("player_slots") or 1)
    prior_denominator = prior_rows * prior_player_slots
    observed_denominator = observed_games * observed_player_slots
    prior_metrics = prior["sample_summary"]["turn_behavior_metrics"]
    observed_metrics = observed["turn_behavior_metrics"]
    keys = [
        "land_play_entries",
        "spell_action_entries",
        "creature_cast_entries",
        "noncreature_cast_entries",
        "total_combat_damage",
    ]
    comparison: dict[str, Any] = {}
    flags: list[dict[str, Any]] = []
    all_turns = sorted(
        {int(turn) for turn in prior_metrics} | {int(turn) for turn in observed_metrics}
    )
    for turn_number in all_turns:
        turn = str(turn_number)
        prior_turn = prior_metrics.get(turn, {})
        observed_turn = observed_metrics.get(turn, {})
        row: dict[str, Any] = {}
        for key in keys:
            prior_per_slot = per_player_slot(prior_turn.get(key), prior_denominator)
            observed_per_slot = per_player_slot(observed_turn.get(key), observed_denominator)
            metric_ratio = ratio(observed_per_slot, prior_per_slot)
            row[key] = {
                "observed_per_player_slot": observed_per_slot,
                "prior_per_player_slot": prior_per_slot,
                "ratio": metric_ratio,
            }
            if metric_ratio is not None and (metric_ratio >= 2.0 or metric_ratio <= 0.5):
                flags.append(
                    {
                        "metric": key,
                        "observed_per_player_slot": observed_per_slot,
                        "prior_per_player_slot": prior_per_slot,
                        "ratio": metric_ratio,
                        "turn": turn_number,
                    }
                )
        prior_mana = prior_turn.get("active_mana_spent_avg_positive")
        observed_mana = observed_turn.get("active_mana_spent_avg_positive")
        row["active_mana_spent_avg_positive"] = {
            "observed": observed_mana,
            "prior": prior_mana,
            "ratio": ratio(observed_mana, prior_mana),
        }
        comparison[turn] = row

    for card, card_report in observed["candidate_observations"].items():
        if not card_report["observed"]:
            flags.append(
                {
                    "card": card,
                    "metric": "candidate_observation",
                    "reason": "candidate_card_never_observed",
                }
            )

    return {
        "comparison_by_turn": comparison,
        "flags": flags,
        "prior_rows_sampled": prior_rows,
        "prior_player_slots": prior_player_slots,
        "observed_game_count": observed_games,
        "observed_player_slots": observed_player_slots,
    }


def numeric_count(value: Any) -> float:
    parsed = parse_float(value)
    return float(parsed or 0.0)


def classify_gate_event(kind: str) -> str | None:
    normalized = normalize_text(kind).replace(" ", "_")
    if normalized in {"play_land", "land_play", "land_played"}:
        return "land_play_entries"
    if "combat_damage" in normalized:
        return "total_combat_damage"
    if "creature" in normalized and "cast" in normalized and "noncreature" not in normalized:
        return "creature_cast_entries"
    if "cast" in normalized or normalized in {"spell_resolved", "miracle_cast"}:
        return "noncreature_cast_entries"
    return None


def gate_whole_game_metrics(telemetry: Mapping[str, Any]) -> dict[str, Any]:
    counts = telemetry.get("event_counts") or {}
    metrics = Counter()
    if isinstance(counts, Mapping):
        for raw_kind, count in counts.items():
            metric = classify_gate_event(str(raw_kind))
            if metric is None:
                continue
            metrics[metric] += numeric_count(count)
            if metric in {"creature_cast_entries", "noncreature_cast_entries"}:
                metrics["spell_action_entries"] += numeric_count(count)
    return {
        "active_mana_spent_avg_positive": None,
        "creature_cast_entries": int(metrics["creature_cast_entries"]),
        "land_play_entries": int(metrics["land_play_entries"]),
        "noncreature_cast_entries": int(metrics["noncreature_cast_entries"]),
        "spell_action_entries": int(metrics["spell_action_entries"]),
        "total_combat_damage": float(metrics["total_combat_damage"]),
    }


def direct_card_event_count(telemetry: Mapping[str, Any], card_name: str) -> int:
    normalized = normalize_text(card_name)
    total = 0
    for field in ("card_strategy_counts", "card_event_counts"):
        counts = telemetry.get(field) or {}
        if not isinstance(counts, Mapping):
            continue
        for key, count in counts.items():
            if normalized and normalized in normalize_text(key):
                total += int(numeric_count(count))
    return total


def focus_payload_for_card(
    focus_summary: Mapping[str, Any],
    card_name: str,
) -> tuple[str | None, Mapping[str, Any]]:
    normalized = normalize_text(card_name)
    for key, payload in focus_summary.items():
        if normalize_text(key) == normalized and isinstance(payload, Mapping):
            return str(key), payload
    return None, {}


def summarize_gate_candidate_observations(
    telemetry: Mapping[str, Any],
    candidate_cards: list[str],
) -> dict[str, dict[str, Any]]:
    focus_summary = telemetry.get("focus_card_access_summary") or {}
    if not isinstance(focus_summary, Mapping):
        focus_summary = {}
    observations: dict[str, dict[str, Any]] = {}
    for card in candidate_cards:
        matched_focus_name, focus = focus_payload_for_card(focus_summary, card)
        direct_events = direct_card_event_count(telemetry, card)
        trace_count = int(numeric_count(focus.get("trace_count") if focus else 0))
        accessed_games = int(numeric_count(focus.get("accessed_games") if focus else 0))
        near_access_games = int(numeric_count(focus.get("near_access_games") if focus else 0))
        drawn_games = int(numeric_count(focus.get("drawn_games") if focus else 0))
        opening_hand_games = int(numeric_count(focus.get("opening_hand_games") if focus else 0))
        library_only_games = int(numeric_count(focus.get("library_only_games") if focus else 0))
        observed = any(
            value > 0
            for value in (
                accessed_games,
                near_access_games,
                drawn_games,
                opening_hand_games,
                direct_events,
            )
        )
        if accessed_games or drawn_games or opening_hand_games:
            evidence_level = "accessed"
        elif near_access_games:
            evidence_level = "near_access"
        elif direct_events:
            evidence_level = "direct_event"
        elif library_only_games:
            evidence_level = "library_only"
        elif trace_count:
            evidence_level = "trace_only"
        else:
            evidence_level = "not_observed"
        observations[card] = {
            "accessed_games": accessed_games,
            "direct_card_events": direct_events,
            "drawn_games": drawn_games,
            "evidence_level": evidence_level,
            "first_turn": None,
            "focus_summary_card_name": matched_focus_name,
            "library_only_games": library_only_games,
            "near_access_games": near_access_games,
            "observed": observed,
            "opening_hand_games": opening_hand_games,
            "total_events": direct_events + trace_count,
            "trace_count": trace_count,
        }
    return observations


def find_gate_result(
    gate_report: Mapping[str, Any],
    candidate_key: str | None,
) -> dict[str, Any]:
    results = gate_report.get("results") or []
    if not isinstance(results, list):
        return {}
    rows = [row for row in results if isinstance(row, dict)]
    if candidate_key:
        for row in rows:
            if str(row.get("deck_key") or row.get("key") or "") == candidate_key:
                return dict(row)
    for row in rows:
        deck_key = str(row.get("deck_key") or row.get("key") or "")
        if deck_key.startswith("candidate"):
            return dict(row)
    return dict(rows[-1]) if rows else {}


def summarize_gate_result(
    gate_result: Mapping[str, Any],
    *,
    candidate_cards: list[str],
    player_slots: int | None,
) -> dict[str, Any]:
    telemetry = gate_result.get("telemetry") or {}
    if not isinstance(telemetry, Mapping):
        telemetry = {}
    game_count = max(1, int(gate_result.get("games") or 1))
    inferred_player_slots = max(1, int(player_slots or 2))
    event_counts = telemetry.get("event_counts") or {}
    event_count = int(sum(numeric_count(value) for value in event_counts.values())) if isinstance(event_counts, Mapping) else 0
    return {
        "candidate_observations": summarize_gate_candidate_observations(
            telemetry,
            candidate_cards,
        ),
        "event_count": event_count,
        "game_count": game_count,
        "gate_deck_key": gate_result.get("deck_key"),
        "player_slots": inferred_player_slots,
        "turn_behavior_metrics": {},
        "whole_game_behavior_metrics": gate_whole_game_metrics(telemetry),
    }


def summed_prior_metrics(prior: Mapping[str, Any]) -> dict[str, Any]:
    prior_metrics = (
        prior.get("sample_summary", {}).get("turn_behavior_metrics", {})
        if isinstance(prior.get("sample_summary"), Mapping)
        else {}
    )
    totals = Counter()
    for payload in prior_metrics.values():
        if not isinstance(payload, Mapping):
            continue
        for key in (
            "creature_cast_entries",
            "land_play_entries",
            "noncreature_cast_entries",
            "spell_action_entries",
            "total_combat_damage",
        ):
            totals[key] += numeric_count(payload.get(key))
    return {
        "active_mana_spent_avg_positive": None,
        "creature_cast_entries": int(totals["creature_cast_entries"]),
        "land_play_entries": int(totals["land_play_entries"]),
        "noncreature_cast_entries": int(totals["noncreature_cast_entries"]),
        "spell_action_entries": int(totals["spell_action_entries"]),
        "total_combat_damage": float(totals["total_combat_damage"]),
    }


def compare_gate_to_prior(prior: dict[str, Any], observed: dict[str, Any]) -> dict[str, Any]:
    prior_rows = int(prior.get("rows_sampled") or 1)
    observed_games = int(observed["game_count"] or 1)
    prior_player_slots = 2
    observed_player_slots = int(observed.get("player_slots") or 1)
    prior_denominator = prior_rows * prior_player_slots
    observed_denominator = observed_games * observed_player_slots
    prior_totals = summed_prior_metrics(prior)
    observed_totals = observed["whole_game_behavior_metrics"]
    keys = [
        "land_play_entries",
        "spell_action_entries",
        "creature_cast_entries",
        "noncreature_cast_entries",
        "total_combat_damage",
    ]
    comparison: dict[str, Any] = {}
    flags: list[dict[str, Any]] = []
    for key in keys:
        prior_per_slot = per_player_slot(prior_totals.get(key), prior_denominator)
        observed_per_slot = per_player_slot(observed_totals.get(key), observed_denominator)
        metric_ratio = ratio(observed_per_slot, prior_per_slot)
        comparison[key] = {
            "observed_per_player_slot": observed_per_slot,
            "prior_per_player_slot": prior_per_slot,
            "ratio": metric_ratio,
        }
        if metric_ratio is not None and (metric_ratio >= 2.0 or metric_ratio <= 0.5):
            flags.append(
                {
                    "metric": key,
                    "observed_per_player_slot": observed_per_slot,
                    "prior_per_player_slot": prior_per_slot,
                    "ratio": metric_ratio,
                    "scope": "whole_game",
                }
            )

    for card, card_report in observed["candidate_observations"].items():
        if not card_report["observed"]:
            flags.append(
                {
                    "card": card,
                    "evidence_level": card_report.get("evidence_level"),
                    "metric": "candidate_observation",
                    "reason": "candidate_card_never_accessed_or_near_accessed",
                }
            )

    return {
        "comparison_whole_game": comparison,
        "flags": flags,
        "prior_rows_sampled": prior_rows,
        "prior_player_slots": prior_player_slots,
        "observed_game_count": observed_games,
        "observed_player_slots": observed_player_slots,
    }


def candidate_scoreability(
    observed: Mapping[str, Any],
    *,
    min_accessed_games: int = 1,
    min_used_events: int = 1,
    min_trace_count: int = 1,
) -> dict[str, Any]:
    thresholds = {
        "min_accessed_games": max(0, min_accessed_games),
        "min_trace_count": max(0, min_trace_count),
        "min_used_events": max(1, min_used_events),
    }
    observations = observed.get("candidate_observations") or {}
    if not isinstance(observations, Mapping) or not observations:
        return {
            "candidate_count": 0,
            "candidate_accessed_not_used_cards": [],
            "candidate_insufficient_sample_cards": [],
            "candidate_near_access_only_cards": [],
            "candidate_unobserved_cards": [],
            "candidate_used_cards": [],
            "recommended_next_action": "inspect_battle_prior_rhythm_only",
            "scoring_allowed": True,
            "status": "not_applicable",
            "thresholds": thresholds,
        }

    cards: dict[str, dict[str, Any]] = {}
    used_cards: list[str] = []
    accessed_not_used_cards: list[str] = []
    insufficient_sample_cards: list[str] = []
    near_access_only_cards: list[str] = []
    unobserved_cards: list[str] = []

    for card, payload in observations.items():
        if not isinstance(payload, Mapping):
            continue
        direct_events = int(numeric_count(payload.get("direct_card_events")))
        if "direct_card_events" not in payload:
            direct_events = int(numeric_count(payload.get("total_events")))
        accessed_games = int(numeric_count(payload.get("accessed_games")))
        drawn_games = int(numeric_count(payload.get("drawn_games")))
        opening_hand_games = int(numeric_count(payload.get("opening_hand_games")))
        near_access_games = int(numeric_count(payload.get("near_access_games")))
        trace_count = int(numeric_count(payload.get("trace_count")))
        observed_flag = bool(payload.get("observed"))
        accessed_total = accessed_games + drawn_games + opening_hand_games
        has_access_fields = any(
            key in payload
            for key in ("accessed_games", "drawn_games", "opening_hand_games")
        )
        accessed = accessed_total > 0
        if not has_access_fields and observed_flag:
            accessed = True

        if direct_events > 0:
            if direct_events < thresholds["min_used_events"]:
                evidence_status = "used_insufficient_sample"
                insufficient_sample_cards.append(str(card))
            elif (
                has_access_fields
                and thresholds["min_accessed_games"] > 0
                and accessed_total < thresholds["min_accessed_games"]
            ):
                evidence_status = "access_insufficient_sample"
                insufficient_sample_cards.append(str(card))
            else:
                evidence_status = "used"
                used_cards.append(str(card))
        elif accessed:
            if (
                has_access_fields
                and thresholds["min_accessed_games"] > 0
                and accessed_total < thresholds["min_accessed_games"]
            ):
                evidence_status = "access_insufficient_sample"
                insufficient_sample_cards.append(str(card))
            else:
                evidence_status = "accessed_not_used"
                accessed_not_used_cards.append(str(card))
        elif near_access_games > 0:
            evidence_status = "near_access_not_used"
            near_access_only_cards.append(str(card))
        elif trace_count < thresholds["min_trace_count"]:
            evidence_status = "trace_insufficient_sample"
            insufficient_sample_cards.append(str(card))
        else:
            evidence_status = "unobserved"
            unobserved_cards.append(str(card))

        cards[str(card)] = {
            "accessed_games": accessed_games,
            "accessed_total_games": accessed_total,
            "direct_card_events": direct_events,
            "drawn_games": drawn_games,
            "evidence_status": evidence_status,
            "near_access_games": near_access_games,
            "observed": observed_flag,
            "opening_hand_games": opening_hand_games,
            "trace_count": trace_count,
        }

    if not cards:
        return {
            "candidate_count": 0,
            "candidate_accessed_not_used_cards": [],
            "candidate_insufficient_sample_cards": [],
            "candidate_near_access_only_cards": [],
            "candidate_unobserved_cards": [],
            "candidate_used_cards": [],
            "recommended_next_action": "inspect_battle_prior_rhythm_only",
            "scoring_allowed": True,
            "status": "not_applicable",
            "thresholds": thresholds,
        }

    if insufficient_sample_cards:
        status = "candidate_insufficient_sample"
        next_action = "increase_gate_sample_or_lower_thresholds_before_scoring"
    elif unobserved_cards:
        status = "candidate_unobserved"
        next_action = "rerun_with_forced_focus_access_or_larger_natural_sample_until_candidate_accessed"
    elif accessed_not_used_cards or near_access_only_cards:
        status = "candidate_not_used"
        next_action = "rerun_with_forced_focus_access_and_usage_or_inspect_play_heuristic"
    else:
        status = "candidate_used"
        next_action = "eligible_for_strategy_scoring_subject_to_rhythm_flags"

    return {
        "candidate_count": len(cards),
        "candidate_accessed_not_used_cards": accessed_not_used_cards,
        "candidate_insufficient_sample_cards": insufficient_sample_cards,
        "candidate_near_access_only_cards": near_access_only_cards,
        "candidate_unobserved_cards": unobserved_cards,
        "candidate_used_cards": used_cards,
        "cards": cards,
        "recommended_next_action": next_action,
        "scoring_allowed": status == "candidate_used",
        "status": status,
        "thresholds": thresholds,
    }


def battle_prior_status(
    comparison: Mapping[str, Any],
    observed: Mapping[str, Any] | None = None,
    *,
    min_accessed_games: int = 1,
    min_used_events: int = 1,
    min_trace_count: int = 1,
) -> str:
    if observed is not None:
        scoreability = candidate_scoreability(
            observed,
            min_accessed_games=min_accessed_games,
            min_used_events=min_used_events,
            min_trace_count=min_trace_count,
        )
        if scoreability["candidate_insufficient_sample_cards"]:
            return "inconclusive_candidate_insufficient_sample"
        if scoreability["candidate_unobserved_cards"]:
            return "inconclusive_candidate_unobserved"
        if (
            scoreability["candidate_accessed_not_used_cards"]
            or scoreability["candidate_near_access_only_cards"]
        ):
            return "inconclusive_candidate_not_used"
    flags = comparison.get("flags") or []
    if any(isinstance(flag, Mapping) and flag.get("metric") == "candidate_observation" for flag in flags):
        return "inconclusive_candidate_unobserved"
    if flags:
        return "battle_prior_warning"
    return "battle_prior_passed"


def render_markdown(report: dict[str, Any]) -> str:
    source_label = "Events"
    source_value = report.get("events_path")
    if report.get("gate_report_path"):
        source_label = "Gate report"
        source_value = report.get("gate_report_path")
    lines = [
        "# 17Lands Battle Prior Comparison",
        "",
        f"- Prior: `{report['prior_path']}`",
        f"- {source_label}: `{source_value}`",
        f"- Status: `{report.get('status')}`",
        f"- Event count: `{report['observed_summary']['event_count']}`",
        f"- Game count: `{report['observed_summary']['game_count']}`",
        f"- Player slots: `{report['observed_summary']['player_slots']}`",
        f"- PostgreSQL writes: `{report['postgres_writes']}`",
        "",
        "## Flags",
        "",
    ]
    if report["comparison"]["flags"]:
        for flag in report["comparison"]["flags"][:40]:
            lines.append(f"- `{flag}`")
    else:
        lines.append("- No ratio or candidate-observation flags.")
    lines.extend(["", "## Candidate Observations", ""])
    for card, payload in report["observed_summary"]["candidate_observations"].items():
        lines.append(f"- {card}: `{payload}`")
    scoreability = report.get("candidate_scoreability") or {}
    if scoreability:
        lines.extend(["", "## Candidate Scoreability", ""])
        lines.append(f"- status: `{scoreability.get('status')}`")
        lines.append(f"- scoring_allowed: `{scoreability.get('scoring_allowed')}`")
        lines.append(f"- next_action: `{scoreability.get('recommended_next_action')}`")
        lines.append(f"- thresholds: `{scoreability.get('thresholds')}`")
        lines.append(
            f"- accessed_not_used: `{scoreability.get('candidate_accessed_not_used_cards')}`"
        )
        lines.append(
            f"- insufficient_sample: `{scoreability.get('candidate_insufficient_sample_cards')}`"
        )
        lines.append(f"- unobserved: `{scoreability.get('candidate_unobserved_cards')}`")
        lines.append(f"- used: `{scoreability.get('candidate_used_cards')}`")
    lines.extend(["", "## Turn Comparison", ""])
    if report["comparison"].get("comparison_by_turn"):
        for turn, payload in list(report["comparison"]["comparison_by_turn"].items())[:12]:
            lines.append(f"- Turn {turn}: `{payload}`")
    if report["comparison"].get("comparison_whole_game"):
        lines.append(f"- Whole game: `{report['comparison']['comparison_whole_game']}`")
    lines.append("")
    return "\n".join(lines)


def run(
    *,
    prior_path: Path,
    events_path: Path,
    candidate_cards: list[str],
    game_count: int | None,
    player_slots: int | None,
    min_accessed_games: int = 1,
    min_used_events: int = 1,
    min_trace_count: int = 1,
) -> dict[str, Any]:
    prior = load_json(prior_path)
    events = iter_jsonl(events_path)
    inferred_game_count = infer_game_count(events, game_count)
    inferred_player_slots = infer_player_slots(events, player_slots)
    observed = summarize_events(
        events,
        candidate_cards=candidate_cards,
        game_count=inferred_game_count,
        player_slots=inferred_player_slots,
    )
    comparison = compare_to_prior(prior, observed)
    scoreability = candidate_scoreability(
        observed,
        min_accessed_games=min_accessed_games,
        min_used_events=min_used_events,
        min_trace_count=min_trace_count,
    )
    return {
        "candidate_scoreability": scoreability,
        "comparison": comparison,
        "events_path": str(events_path),
        "observed_summary": observed,
        "postgres_writes": False,
        "prior_path": str(prior_path),
        "status": battle_prior_status(
            comparison,
            observed,
            min_accessed_games=min_accessed_games,
            min_used_events=min_used_events,
            min_trace_count=min_trace_count,
        ),
        "source_db_mutated": False,
    }


def run_gate_report(
    *,
    prior_path: Path,
    gate_report_path: Path,
    candidate_key: str | None,
    candidate_cards: list[str],
    player_slots: int | None,
    min_accessed_games: int = 1,
    min_used_events: int = 1,
    min_trace_count: int = 1,
) -> dict[str, Any]:
    prior = load_json(prior_path)
    gate_report = load_json(gate_report_path)
    gate_result = find_gate_result(gate_report, candidate_key)
    observed = summarize_gate_result(
        gate_result,
        candidate_cards=candidate_cards,
        player_slots=player_slots,
    )
    comparison = compare_gate_to_prior(prior, observed)
    scoreability = candidate_scoreability(
        observed,
        min_accessed_games=min_accessed_games,
        min_used_events=min_used_events,
        min_trace_count=min_trace_count,
    )
    return {
        "candidate_scoreability": scoreability,
        "candidate_key": candidate_key,
        "comparison": comparison,
        "gate_report_path": str(gate_report_path),
        "observed_summary": observed,
        "postgres_writes": False,
        "prior_path": str(prior_path),
        "status": battle_prior_status(
            comparison,
            observed,
            min_accessed_games=min_accessed_games,
            min_used_events=min_used_events,
            min_trace_count=min_trace_count,
        ),
        "source_db_mutated": False,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prior-json", type=Path, default=DEFAULT_PRIOR_JSON)
    parser.add_argument("--events-jsonl", type=Path)
    parser.add_argument("--gate-report-json", type=Path)
    parser.add_argument("--candidate-key")
    parser.add_argument("--candidate-card", action="append", default=[])
    parser.add_argument("--game-count", type=int)
    parser.add_argument("--player-slots", type=int)
    parser.add_argument("--min-accessed-games", type=int, default=1)
    parser.add_argument("--min-used-events", type=int, default=1)
    parser.add_argument("--min-trace-count", type=int, default=1)
    parser.add_argument("--output-json", type=Path)
    parser.add_argument("--output-md", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if bool(args.events_jsonl) == bool(args.gate_report_json):
        raise SystemExit("provide exactly one of --events-jsonl or --gate-report-json")
    if args.events_jsonl:
        report = run(
            prior_path=args.prior_json,
            events_path=args.events_jsonl,
            candidate_cards=args.candidate_card,
            game_count=args.game_count,
            player_slots=args.player_slots,
            min_accessed_games=args.min_accessed_games,
            min_used_events=args.min_used_events,
            min_trace_count=args.min_trace_count,
        )
    else:
        report = run_gate_report(
            prior_path=args.prior_json,
            gate_report_path=args.gate_report_json,
            candidate_key=args.candidate_key,
            candidate_cards=args.candidate_card,
            player_slots=args.player_slots,
            min_accessed_games=args.min_accessed_games,
            min_used_events=args.min_used_events,
            min_trace_count=args.min_trace_count,
        )
    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(stable_json(report) + "\n", encoding="utf-8")
    if args.output_md:
        args.output_md.parent.mkdir(parents=True, exist_ok=True)
        args.output_md.write_text(render_markdown(report), encoding="utf-8")
    if not args.output_json and not args.output_md:
        print(stable_json(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
