#!/usr/bin/env python3
"""Compare Lorehold deck 615 against protected deck 607 as package groups.

This is a read-only audit. It does not stage deck rows, mutate SQLite, write
PostgreSQL, or promote a challenger. Its job is to explain what package
movement produced a battle signal and what still needs validation.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

from master_optimizer_common import REPORT_DIR, normalize_name, resolve_default_knowledge_db


DEFAULT_BASELINE_DECK_ID = 607
DEFAULT_CHALLENGER_DECK_ID = 615
DEFAULT_BATTLE_REPORT = (
    REPORT_DIR
    / "lorehold_variant_battle_gate_20260705_total_authorization_focused_607_vs_615_g8.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_615_shell_package_delta_20260705_current"

BASIC_LANDS = {"Plains", "Mountain", "Island", "Swamp", "Forest", "Wastes"}

OFFICIAL_POWER_WATCH_REASONS = {
    "Mana Vault": "Wizards Commander Brackets Beta lists it as an extremely powerful fast-mana Game Changer.",
    "The One Ring": "Wizards Commander Brackets Beta lists it as overwhelming resource advantage.",
    "Underworld Breach": "Wizards Commander Brackets Beta lists it as a combo/storm Game Changer.",
    "Farewell": "Wizards Commander Brackets Beta update on 2026-02-09 added it to Game Changers.",
}

OFFICIAL_RESEARCH_SOURCES = [
    "https://magic.wizards.com/en/news/announcements/introducing-commander-brackets-beta",
    "https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026",
    "https://mtgcommander.net/index.php/banned-list/",
]

PACKAGE_LABELS = {
    "fast_mana_burst": "fast mana / burst ramp",
    "spell_chain_conversion": "spell chain conversion",
    "resource_engine_card_advantage": "resource engine / card advantage",
    "protection_window": "protection window",
    "interaction_meta": "interaction / meta answers",
    "deterministic_finisher": "pressure and deterministic finishers",
    "mana_base_power_shift": "mana base power shift",
    "mana_base_quantity_shift": "basic land quantity shift",
    "board_control_shift": "board control shift",
    "topdeck_access_loss": "topdeck access removed from 607",
    "spell_value_loss": "spell value removed from 607",
    "cost_reduction_ramp_loss": "cost reduction/ramp removed from 607",
    "protection_window_loss": "protection window removed from 607",
    "interaction_loss": "interaction removed from 607",
    "finisher_pressure_loss": "finisher pressure removed from 607",
    "mana_base_loss": "mana base removed from 607",
    "uncategorized_add": "uncategorized addition",
    "uncategorized_cut": "uncategorized cut",
}

ADDED_PACKAGE_OVERRIDES = {
    "Mana Vault": "fast_mana_burst",
    "Seething Song": "fast_mana_burst",
    "Goldspan Dragon": "fast_mana_burst",
    "Primal Amulet // Primal Wellspring": "fast_mana_burst",
    "Brass's Bounty": "fast_mana_burst",
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty": "spell_chain_conversion",
    "Double Vision": "spell_chain_conversion",
    "Flare of Duplication": "spell_chain_conversion",
    "Flashback": "spell_chain_conversion",
    "Invoke Calamity": "spell_chain_conversion",
    "Reiterate": "spell_chain_conversion",
    "Underworld Breach": "spell_chain_conversion",
    "Apex of Power": "resource_engine_card_advantage",
    "Faithless Looting": "resource_engine_card_advantage",
    "Galvanoth": "resource_engine_card_advantage",
    "Heroes Remembered": "resource_engine_card_advantage",
    "Ol\u00f3rin's Searing Light": "resource_engine_card_advantage",
    "Single Combat": "resource_engine_card_advantage",
    "Taunt from the Rampart": "resource_engine_card_advantage",
    "The One Ring": "resource_engine_card_advantage",
    "Velomachus Lorehold": "resource_engine_card_advantage",
    "Enlightened Tutor": "resource_engine_card_advantage",
    "Gamble": "resource_engine_card_advantage",
    "Boros Charm": "protection_window",
    "Deflecting Palm": "protection_window",
    "Grand Abolisher": "protection_window",
    "Mithril Coat": "protection_window",
    "Red Elemental Blast": "protection_window",
    "Reprieve": "protection_window",
    "Silence": "protection_window",
    "Chaos Warp": "interaction_meta",
    "Erode": "interaction_meta",
    "Lightning Bolt": "interaction_meta",
    "Vandalblast": "interaction_meta",
    "Beacon of Immortality": "deterministic_finisher",
    "Guttersnipe": "deterministic_finisher",
    "Longshot, Rebel Bowman": "deterministic_finisher",
    "Perch Protection": "deterministic_finisher",
    "Rite of the Dragoncaller": "deterministic_finisher",
    "Twinflame Tyrant": "deterministic_finisher",
    "Goliath Daydreamer": "deterministic_finisher",
    "Boseiju, Who Shelters All": "mana_base_power_shift",
    "Cavern of Souls": "mana_base_power_shift",
    "Clifftop Retreat": "mana_base_power_shift",
    "Myriad Landscape": "mana_base_power_shift",
    "Plateau": "mana_base_power_shift",
    "Sundown Pass": "mana_base_power_shift",
}

REMOVED_PACKAGE_OVERRIDES = {
    "Scroll Rack": "topdeck_access_loss",
    "Bender's Waterskin": "topdeck_access_loss",
    "The Mind Stone": "topdeck_access_loss",
    "Creative Technique": "spell_value_loss",
    "Hit the Mother Lode": "spell_value_loss",
    "Improvisation Capstone": "spell_value_loss",
    "Molecule Man": "spell_value_loss",
    "Artist's Talent": "spell_value_loss",
    "Pinnacle Monk // Mystic Peak": "spell_value_loss",
    "The Scarlet Witch": "cost_reduction_ramp_loss",
    "Boros Signet": "cost_reduction_ramp_loss",
    "Fellwar Stone": "cost_reduction_ramp_loss",
    "Pearl Medallion": "cost_reduction_ramp_loss",
    "Ruby Medallion": "cost_reduction_ramp_loss",
    "Talisman of Conviction": "cost_reduction_ramp_loss",
    "Victory Chimes": "cost_reduction_ramp_loss",
    "Avatar's Wrath": "protection_window_loss",
    "Dawn's Truce": "protection_window_loss",
    "Emeria's Call // Emeria, Shattered Skyclave": "protection_window_loss",
    "Flawless Maneuver": "protection_window_loss",
    "Giver of Runes": "protection_window_loss",
    "Mother of Runes": "protection_window_loss",
    "Redirect Lightning": "protection_window_loss",
    "Swiftfoot Boots": "protection_window_loss",
    "Tibalt's Trickery": "protection_window_loss",
    "Generous Gift": "interaction_loss",
    "High Noon": "interaction_loss",
    "Path to Exile": "interaction_loss",
    "Stroke of Midnight": "interaction_loss",
    "Thor, God of Thunder": "interaction_loss",
    "Winds of Abandon": "interaction_loss",
    "Blasphemous Act": "board_control_shift",
    "Everything Comes to Dust": "board_control_shift",
    "Fated Clash": "board_control_shift",
    "Promise of Loyalty": "board_control_shift",
    "Tragic Arrogance": "board_control_shift",
    "Furygale Flocking": "finisher_pressure_loss",
    "Prismari Pianist": "finisher_pressure_loss",
    "Storm Herd": "finisher_pressure_loss",
    "Surge to Victory": "finisher_pressure_loss",
    "Tempt with Bunnies": "finisher_pressure_loss",
}


def parse_json(value: object, default: Any) -> Any:
    if value in (None, ""):
        return default
    try:
        return json.loads(str(value))
    except json.JSONDecodeError:
        return default


def connect_readonly(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    return conn


def load_deck_cards(conn: sqlite3.Connection, deck_id: int) -> dict[str, dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT card_name, quantity, functional_tag, functional_tags_json, cmc, type_line, oracle_text,
               is_commander, card_id
        FROM deck_cards
        WHERE deck_id=?
        ORDER BY card_name
        """,
        (deck_id,),
    ).fetchall()
    cards: dict[str, dict[str, Any]] = {}
    for row in rows:
        name = str(row["card_name"])
        cards[normalize_name(name)] = {
            "card_name": name,
            "quantity": int(row["quantity"] or 0),
            "functional_tag": row["functional_tag"],
            "functional_tags": parse_json(row["functional_tags_json"], []),
            "cmc": row["cmc"],
            "type_line": row["type_line"],
            "oracle_text": row["oracle_text"],
            "is_commander": bool(row["is_commander"]),
            "card_id": row["card_id"],
        }
    return cards


def classify_add(row: dict[str, Any]) -> str:
    name = str(row["card_name"])
    if name in BASIC_LANDS:
        return "mana_base_quantity_shift"
    if name in ADDED_PACKAGE_OVERRIDES:
        return ADDED_PACKAGE_OVERRIDES[name]
    tag = str(row.get("functional_tag") or "")
    type_line = str(row.get("type_line") or "")
    if "Land" in type_line or tag == "land":
        return "mana_base_power_shift"
    if tag == "ramp":
        return "fast_mana_burst"
    if tag in {"engine", "tutor"}:
        return "spell_chain_conversion"
    if tag == "draw":
        return "resource_engine_card_advantage"
    if tag == "protection":
        return "protection_window"
    if tag in {"removal", "board_wipe"}:
        return "interaction_meta"
    if tag in {"wincon", "creature"}:
        return "deterministic_finisher"
    return "uncategorized_add"


def classify_cut(row: dict[str, Any]) -> str:
    name = str(row["card_name"])
    if name in BASIC_LANDS:
        return "mana_base_quantity_shift"
    if name in REMOVED_PACKAGE_OVERRIDES:
        return REMOVED_PACKAGE_OVERRIDES[name]
    tag = str(row.get("functional_tag") or "")
    type_line = str(row.get("type_line") or "")
    if "Land" in type_line or tag == "land":
        return "mana_base_loss"
    if tag == "ramp":
        return "cost_reduction_ramp_loss"
    if tag in {"draw", "engine", "creature"}:
        return "spell_value_loss"
    if tag == "protection":
        return "protection_window_loss"
    if tag in {"removal", "board_wipe"}:
        return "interaction_loss"
    if tag == "wincon":
        return "finisher_pressure_loss"
    return "uncategorized_cut"


def quantity_delta(
    baseline: dict[str, dict[str, Any]],
    challenger: dict[str, dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    additions: list[dict[str, Any]] = []
    removals: list[dict[str, Any]] = []
    shared: list[dict[str, Any]] = []
    for key in sorted(set(baseline) | set(challenger)):
        base_qty = int((baseline.get(key) or {}).get("quantity") or 0)
        challenger_qty = int((challenger.get(key) or {}).get("quantity") or 0)
        if challenger_qty > base_qty:
            row = dict(challenger[key])
            row["delta_quantity"] = challenger_qty - base_qty
            row["package_group"] = classify_add(row)
            additions.append(row)
        elif base_qty > challenger_qty:
            row = dict(baseline[key])
            row["delta_quantity"] = base_qty - challenger_qty
            row["package_group"] = classify_cut(row)
            removals.append(row)
        elif base_qty and challenger_qty:
            row = dict(baseline[key])
            row["shared_quantity"] = base_qty
            shared.append(row)
    return additions, removals, shared


def event_key_parts(key: str) -> tuple[str, str] | None:
    if ":" not in key:
        return None
    event, card = key.split(":", 1)
    event = event.strip()
    card = card.strip()
    if not event or not card:
        return None
    return event, card


def aggregate_card_events(result: dict[str, Any], target_cards: Iterable[str]) -> dict[str, Any]:
    target_norms = {normalize_name(name) for name in target_cards}
    raw_counts = dict((result.get("telemetry") or {}).get("card_event_counts") or {})
    if not raw_counts:
        for game in result.get("game_results") or []:
            raw_counts.update((game or {}).get("card_event_counts") or {})

    by_card: dict[str, Counter[str]] = defaultdict(Counter)
    for raw_key, raw_count in raw_counts.items():
        parts = event_key_parts(str(raw_key))
        if parts is None:
            continue
        event, card_name = parts
        if normalize_name(card_name) not in target_norms:
            continue
        by_card[card_name][event] += int(raw_count or 0)

    cards: list[dict[str, Any]] = []
    for card_name, events in sorted(by_card.items()):
        cards.append(
            {
                "card_name": card_name,
                "event_total": sum(events.values()),
                "events": dict(sorted(events.items())),
            }
        )
    return {
        "observed_card_count": sum(1 for card in cards if int(card["event_total"]) > 0),
        "event_total": sum(int(card["event_total"]) for card in cards),
        "cards": sorted(cards, key=lambda item: (-int(item["event_total"]), item["card_name"])),
    }


def group_delta_rows(rows: list[dict[str, Any]], event_summary: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    events_by_norm = {
        normalize_name(card["card_name"]): card
        for card in (event_summary or {}).get("cards", [])
    }
    grouped: dict[str, dict[str, Any]] = {}
    for row in rows:
        group = str(row["package_group"])
        bucket = grouped.setdefault(
            group,
            {
                "package_group": group,
                "label": PACKAGE_LABELS.get(group, group),
                "quantity_delta": 0,
                "card_count": 0,
                "cards": [],
                "observed_event_total": 0,
                "observed_cards": [],
            },
        )
        qty = int(row.get("delta_quantity") or 0)
        name = str(row["card_name"])
        bucket["quantity_delta"] += qty
        bucket["card_count"] += 1
        bucket["cards"].append(name if qty == 1 else f"{name} x{qty}")
        event_row = events_by_norm.get(normalize_name(name))
        if event_row:
            bucket["observed_event_total"] += int(event_row.get("event_total") or 0)
            bucket["observed_cards"].append(name)
    return sorted(
        grouped.values(),
        key=lambda item: (-int(item["quantity_delta"]), str(item["package_group"])),
    )


def load_battle(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def result_for_deck(report: dict[str, Any], deck_id: int) -> dict[str, Any]:
    for result in report.get("results") or []:
        if int(result.get("deck_id") or result.get("load_deck_id") or -1) == deck_id:
            return result
    raise ValueError(f"Deck {deck_id} not found in battle report")


def battle_summary(report: dict[str, Any], baseline_result: dict[str, Any], challenger_result: dict[str, Any]) -> dict[str, Any]:
    baseline_wins = int(baseline_result.get("wins") or 0)
    challenger_wins = int(challenger_result.get("wins") or 0)
    baseline_losses = int(baseline_result.get("losses") or 0)
    challenger_losses = int(challenger_result.get("losses") or 0)
    baseline_avg = float(baseline_result.get("avg_win_turn") or 0)
    challenger_avg = float(challenger_result.get("avg_win_turn") or 0)
    return {
        "report_status": report.get("status"),
        "generated_at": report.get("generated_at"),
        "opponent_seed": report.get("opponent_seed"),
        "simulation_seed": report.get("simulation_seed"),
        "games_per_opponent": report.get("games_per_opponent"),
        "opponents": report.get("opponents") or [],
        "baseline": {
            "deck_key": baseline_result.get("deck_key"),
            "wins": baseline_wins,
            "losses": baseline_losses,
            "games": baseline_wins + baseline_losses + int(baseline_result.get("stalls") or 0),
            "win_rate": baseline_result.get("win_rate"),
            "avg_win_turn": baseline_result.get("avg_win_turn"),
            "strategy_score": baseline_result.get("strategy_score"),
            "primary_risks": baseline_result.get("primary_risks") or [],
        },
        "challenger": {
            "deck_key": challenger_result.get("deck_key"),
            "wins": challenger_wins,
            "losses": challenger_losses,
            "games": challenger_wins + challenger_losses + int(challenger_result.get("stalls") or 0),
            "win_rate": challenger_result.get("win_rate"),
            "avg_win_turn": challenger_result.get("avg_win_turn"),
            "strategy_score": challenger_result.get("strategy_score"),
            "primary_risks": challenger_result.get("primary_risks") or [],
        },
        "deltas": {
            "challenger_minus_baseline_wins": challenger_wins - baseline_wins,
            "challenger_minus_baseline_losses": challenger_losses - baseline_losses,
            "challenger_minus_baseline_avg_win_turn": round(challenger_avg - baseline_avg, 2),
        },
    }


def strategic_delta(baseline_result: dict[str, Any], challenger_result: dict[str, Any]) -> list[dict[str, Any]]:
    baseline_counts = Counter((baseline_result.get("telemetry") or {}).get("strategic_event_counts") or {})
    challenger_counts = Counter((challenger_result.get("telemetry") or {}).get("strategic_event_counts") or {})
    rows: list[dict[str, Any]] = []
    for key in sorted(set(baseline_counts) | set(challenger_counts)):
        base_count = int(baseline_counts.get(key) or 0)
        challenger_count = int(challenger_counts.get(key) or 0)
        rows.append(
            {
                "event": key,
                "baseline_count": base_count,
                "challenger_count": challenger_count,
                "delta": challenger_count - base_count,
            }
        )
    return sorted(rows, key=lambda item: (-abs(int(item["delta"])), item["event"]))


def power_watch_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for row in rows:
        reason = OFFICIAL_POWER_WATCH_REASONS.get(str(row["card_name"]))
        if reason:
            out.append(
                {
                    "card_name": row["card_name"],
                    "quantity": row.get("delta_quantity") or row.get("shared_quantity") or 1,
                    "package_group": row.get("package_group"),
                    "reason": reason,
                }
            )
    return out


def decision_status(battle: dict[str, Any], power_watch_added_count: int) -> str:
    win_delta = int((battle.get("deltas") or {}).get("challenger_minus_baseline_wins") or 0)
    if win_delta <= 0:
        return "keep_607_protected_baseline"
    if power_watch_added_count:
        return "615_positive_battle_signal_requires_power_bracket_review_and_repeat_gate"
    return "615_positive_battle_signal_requires_repeat_gate"


def build_payload(
    *,
    source_db: Path,
    battle_report: Path,
    baseline_deck_id: int,
    challenger_deck_id: int,
) -> dict[str, Any]:
    with connect_readonly(source_db) as conn:
        baseline_cards = load_deck_cards(conn, baseline_deck_id)
        challenger_cards = load_deck_cards(conn, challenger_deck_id)
    additions, removals, shared = quantity_delta(baseline_cards, challenger_cards)

    report = load_battle(battle_report)
    baseline_result = result_for_deck(report, baseline_deck_id)
    challenger_result = result_for_deck(report, challenger_deck_id)
    add_events = aggregate_card_events(challenger_result, [row["card_name"] for row in additions])
    cut_events = aggregate_card_events(baseline_result, [row["card_name"] for row in removals])
    battle = battle_summary(report, baseline_result, challenger_result)
    added_power_watch = power_watch_rows(additions)
    shared_power_watch = power_watch_rows(shared)

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_db": str(source_db),
        "battle_report": str(battle_report),
        "baseline_deck_id": baseline_deck_id,
        "challenger_deck_id": challenger_deck_id,
        "official_research_sources": OFFICIAL_RESEARCH_SOURCES,
        "deck_delta_summary": {
            "baseline_unique_rows": len(baseline_cards),
            "challenger_unique_rows": len(challenger_cards),
            "baseline_total_quantity": sum(int(row["quantity"]) for row in baseline_cards.values()),
            "challenger_total_quantity": sum(int(row["quantity"]) for row in challenger_cards.values()),
            "added_unique_cards_or_quantity_shifts": len(additions),
            "removed_unique_cards_or_quantity_shifts": len(removals),
            "added_quantity": sum(int(row["delta_quantity"]) for row in additions),
            "removed_quantity": sum(int(row["delta_quantity"]) for row in removals),
            "shared_unique_cards": len(shared),
            "official_power_watch_added_count": len(added_power_watch),
            "official_power_watch_shared_count": len(shared_power_watch),
        },
        "battle_summary": battle,
        "official_power_watch_added": added_power_watch,
        "official_power_watch_shared": shared_power_watch,
        "added_package_groups": group_delta_rows(additions, add_events),
        "removed_package_groups": group_delta_rows(removals, cut_events),
        "added_card_events": add_events,
        "removed_card_events": cut_events,
        "strategic_event_delta": strategic_delta(baseline_result, challenger_result),
        "decision": {
            "status": decision_status(battle, len(added_power_watch)),
            "promotion_ready_from_this_report": False,
            "reason": (
                "The report explains a battle-positive shell delta, but whole-shell "
                "replacement still needs repeat/opponent-rotated evidence and power-bracket review."
            ),
        },
        "mutation_flags": {
            "baseline_607_modified": False,
            "challenger_615_modified": False,
            "sqlite_source_mutated": False,
            "postgres_writes_performed": False,
            "deck_materialization_performed": False,
        },
    }


def markdown_table(headers: list[str], rows: Iterable[list[Any]]) -> list[str]:
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join("---" for _ in headers) + " |",
    ]
    for row in rows:
        lines.append("| " + " | ".join(str(value) for value in row) + " |")
    return lines


def short_cards(cards: list[str], limit: int = 8) -> str:
    if len(cards) <= limit:
        return ", ".join(cards)
    return ", ".join(cards[:limit]) + f", +{len(cards) - limit} more"


def render_markdown(payload: dict[str, Any]) -> str:
    battle = payload["battle_summary"]
    summary = payload["deck_delta_summary"]
    lines = [
        "# Lorehold 615 Shell Package Delta",
        "",
        f"Generated at: `{payload['generated_at']}`",
        f"Source DB: `{payload['source_db']}`",
        f"Battle report: `{payload['battle_report']}`",
        "",
        "## Decision",
        "",
        f"- Status: `{payload['decision']['status']}`.",
        f"- Promotion ready from this report: `{payload['decision']['promotion_ready_from_this_report']}`.",
        f"- Baseline 607 modified: `{payload['mutation_flags']['baseline_607_modified']}`.",
        f"- PostgreSQL writes performed: `{payload['mutation_flags']['postgres_writes_performed']}`.",
        f"- Deck materialization performed: `{payload['mutation_flags']['deck_materialization_performed']}`.",
        "",
        "## Battle Signal",
        "",
    ]
    lines.extend(
        markdown_table(
            ["deck", "wins", "losses", "win_rate", "avg_win_turn", "strategy_score", "primary_risks"],
            [
                [
                    "607",
                    battle["baseline"]["wins"],
                    battle["baseline"]["losses"],
                    battle["baseline"]["win_rate"],
                    battle["baseline"]["avg_win_turn"],
                    battle["baseline"]["strategy_score"],
                    ", ".join(battle["baseline"]["primary_risks"]),
                ],
                [
                    "615",
                    battle["challenger"]["wins"],
                    battle["challenger"]["losses"],
                    battle["challenger"]["win_rate"],
                    battle["challenger"]["avg_win_turn"],
                    battle["challenger"]["strategy_score"],
                    ", ".join(battle["challenger"]["primary_risks"]),
                ],
            ],
        )
    )
    lines.extend(
        [
            "",
            f"Win delta 615 minus 607: `{battle['deltas']['challenger_minus_baseline_wins']}`.",
            f"Average win-turn delta 615 minus 607: `{battle['deltas']['challenger_minus_baseline_avg_win_turn']}`.",
            f"Opponent seed: `{battle.get('opponent_seed')}`. Simulation seed: `{battle.get('simulation_seed')}`.",
            "",
            "## Deck Delta",
            "",
            f"- 607 unique rows/quantity: `{summary['baseline_unique_rows']}` / `{summary['baseline_total_quantity']}`.",
            f"- 615 unique rows/quantity: `{summary['challenger_unique_rows']}` / `{summary['challenger_total_quantity']}`.",
            f"- Added quantity into 615: `{summary['added_quantity']}` across `{summary['added_unique_cards_or_quantity_shifts']}` cards or quantity shifts.",
            f"- Removed quantity from 607: `{summary['removed_quantity']}` across `{summary['removed_unique_cards_or_quantity_shifts']}` cards or quantity shifts.",
            "",
            "## Official Power Watch",
            "",
        ]
    )
    if payload["official_power_watch_added"]:
        lines.extend(
            markdown_table(
                ["card", "quantity", "package", "reason"],
                [
                    [row["card_name"], row["quantity"], row["package_group"], row["reason"]]
                    for row in payload["official_power_watch_added"]
                ],
            )
        )
    else:
        lines.append("No official power-watch card was newly added by 615 versus 607.")
    if payload["official_power_watch_shared"]:
        lines.extend(["", "Shared power-watch cards already present in both shells:"])
        lines.extend(
            markdown_table(
                ["card", "quantity", "reason"],
                [
                    [row["card_name"], row["quantity"], row["reason"]]
                    for row in payload["official_power_watch_shared"]
                ],
            )
        )
    lines.extend(
        [
            "",
            "Research sources:",
            "",
        ]
    )
    lines.extend(f"- {url}" for url in payload["official_research_sources"])
    lines.extend(["", "## 615 Added Package Groups", ""])
    lines.extend(
        markdown_table(
            ["package", "quantity", "cards", "observed_event_total", "observed_cards"],
            [
                [
                    row["label"],
                    row["quantity_delta"],
                    short_cards(row["cards"]),
                    row["observed_event_total"],
                    short_cards(row["observed_cards"]),
                ]
                for row in payload["added_package_groups"]
            ],
        )
    )
    lines.extend(["", "## 607 Removed Package Groups", ""])
    lines.extend(
        markdown_table(
            ["package", "quantity", "cards", "607_observed_event_total", "607_observed_cards"],
            [
                [
                    row["label"],
                    row["quantity_delta"],
                    short_cards(row["cards"]),
                    row["observed_event_total"],
                    short_cards(row["observed_cards"]),
                ]
                for row in payload["removed_package_groups"]
            ],
        )
    )
    lines.extend(["", "## Top Observed 615 Added Cards", ""])
    observed_added = payload["added_card_events"]["cards"][:12]
    if observed_added:
        lines.extend(
            markdown_table(
                ["card", "event_total", "events"],
                [
                    [
                        row["card_name"],
                        row["event_total"],
                        ", ".join(f"{event}:{count}" for event, count in row["events"].items()),
                    ]
                    for row in observed_added
                ],
            )
        )
    else:
        lines.append("No added 615 card had a recorded event in this battle report.")
    lines.extend(["", "## Strategic Event Deltas", ""])
    lines.extend(
        markdown_table(
            ["event", "607", "615", "delta"],
            [
                [row["event"], row["baseline_count"], row["challenger_count"], row["delta"]]
                for row in payload["strategic_event_delta"][:18]
            ],
        )
    )
    lines.extend(
        [
            "",
            "## Guardrail",
            "",
            "This report treats 615 as a whole-shell learning signal, not as an automatic replacement for protected deck 607. A promotion still needs repeat/opponent-rotated battle evidence plus explicit review of the official power-watch cards introduced by the 615 shell.",
            "",
        ]
    )
    return "\n".join(lines)


def write_outputs(payload: dict[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-db", type=Path, default=resolve_default_knowledge_db())
    parser.add_argument("--battle-report", type=Path, default=DEFAULT_BATTLE_REPORT)
    parser.add_argument("--baseline-deck-id", type=int, default=DEFAULT_BASELINE_DECK_ID)
    parser.add_argument("--challenger-deck-id", type=int, default=DEFAULT_CHALLENGER_DECK_ID)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_payload(
        source_db=args.source_db,
        battle_report=args.battle_report,
        baseline_deck_id=args.baseline_deck_id,
        challenger_deck_id=args.challenger_deck_id,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote_json={json_path}")
    print(f"wrote_markdown={md_path}")
    print(f"decision_status={payload['decision']['status']}")
    print(
        "win_delta_615_minus_607="
        f"{payload['battle_summary']['deltas']['challenger_minus_baseline_wins']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
