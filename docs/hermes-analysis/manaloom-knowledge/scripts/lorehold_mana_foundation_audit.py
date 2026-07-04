#!/usr/bin/env python3
"""Audit the protected Lorehold 607 mana foundation.

This read-only audit turns the current deckbuilding learning into executable
checks: lands, color sources, early mana, burst mana, protected utility lands,
and the current accessibility-vs-fit decision for Mana Vault and The One Ring.
It does not mutate PostgreSQL, SQLite, or deck contents.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

from master_optimizer_common import (
    normalize_name,
    resolve_default_knowledge_db,
    safe_cmc_from_card,
    sqlite_connection_has_table,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_DECK_ID = 607
DEFAULT_EDHREC_CARD_DATA = SCRIPT_DIR / "_edhrec_card_data.json"
DEFAULT_ONE_RING_DECISION = REPORT_DIR / "lorehold_one_ring_cut_decision_20260630.md"
DEFAULT_PROFILED_CUT_REPORT = (
    REPORT_DIR / "lorehold_607_unprotected_profiled_cut_benchmark_generator_20260704_current.md"
)

BOROS_COLORS = {"R", "W"}
ACTIVE_RULE_STATUSES = {"active", "auto", "verified"}
ACTIVE_REVIEW_STATUSES = {"active", "verified", "reviewed"}
EXTERNAL_LEARNING = [
    {
        "source": "Wizards Commander format",
        "url": "https://magic.wizards.com/en/formats/commander",
        "learning": "Commander legality starts with 100 cards, singleton rules, commander count, and color identity.",
    },
    {
        "source": "EDHREC ramp guide",
        "url": "https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander",
        "learning": "Ramp must accelerate the deck at the correct turn; ramp competing with the commander curve is a real cost.",
    },
    {
        "source": "EDHREC Commander deckbuilding guide",
        "url": "https://edhrec.com/articles/how-to-build-a-commander-deck",
        "learning": "Category ratios are a starting point; the list still has to play the intended commander plan.",
    },
    {
        "source": "EDHREC Lorehold commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "learning": "Lorehold-specific adoption protects topdeck, miracle, turn-cycle mana, and spell-value packages over generic staples.",
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def connect(db_path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def as_float(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except Exception:
        return default


def read_json_if_exists(path: Path) -> Any:
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def read_text_if_exists(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


def has_column(conn: sqlite3.Connection, table: str, column: str) -> bool:
    try:
        rows = conn.execute(f"PRAGMA table_info({table})").fetchall()
    except sqlite3.Error:
        return False
    return any(str(row[1]) == column for row in rows)


def normalized_sql_expr(column: str) -> str:
    return f"lower(trim(replace(replace(replace({column}, '''', ''), ',', ''), '-', ' ')))"


def oracle_lookup(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "card_oracle_cache"):
        return {}
    wanted = normalize_name(card_name)
    row = conn.execute(
        f"""
        SELECT name, mana_cost, type_line, oracle_text, cmc, card_id
        FROM card_oracle_cache
        WHERE normalized_name = ?
           OR {normalized_sql_expr("name")} = ?
        LIMIT 1
        """,
        (wanted, wanted),
    ).fetchone()
    return dict(row) if row else {}


def merge_oracle(conn: sqlite3.Connection, row: sqlite3.Row) -> dict[str, Any]:
    card = dict(row)
    oracle = oracle_lookup(conn, str(card.get("card_name") or ""))
    for field in ("type_line", "oracle_text", "cmc", "card_id"):
        if card.get(field) in (None, "") and oracle.get(field) not in (None, ""):
            card[field] = oracle.get(field)
    if oracle.get("mana_cost"):
        card["mana_cost"] = oracle["mana_cost"]
    card["safe_cmc"] = safe_cmc_from_card(card, unknown_nonland_fallback=99.0)
    return card


def load_deck_cards(conn: sqlite3.Connection, deck_id: int) -> list[dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT deck_id, card_name, quantity, functional_tag, functional_tags_json,
               is_commander, cmc, type_line, oracle_text, card_id
        FROM deck_cards
        WHERE deck_id = ?
        ORDER BY is_commander DESC, card_name
        """,
        (deck_id,),
    ).fetchall()
    return [merge_oracle(conn, row) for row in rows]


def is_land(card: Mapping[str, Any]) -> bool:
    return "land" in str(card.get("type_line") or "").lower() or str(
        card.get("functional_tag") or ""
    ).lower() == "land"


def is_basic_land(card: Mapping[str, Any]) -> bool:
    return "basic land" in str(card.get("type_line") or "").lower()


def card_text(card: Mapping[str, Any]) -> str:
    return f"{card.get('type_line') or ''}\n{card.get('oracle_text') or ''}".lower()


def mana_colors_from_text(type_line: str, oracle_text: str) -> set[str]:
    text = f"{type_line}\n{oracle_text}".lower()
    colors: set[str] = set()
    if "mountain" in text or "{r}" in text or " add r" in text or "add {r}" in text:
        colors.add("R")
    if "plains" in text or "{w}" in text or " add w" in text or "add {w}" in text:
        colors.add("W")
    if "any color in your commander's color identity" in text:
        colors.update(BOROS_COLORS)
    if "any color among legendary permanents" in text or "only to cast a legendary spell" in text:
        colors.update(BOROS_COLORS)
    if "any color that a land an opponent controls could produce" in text:
        colors.update(BOROS_COLORS)
    if "add one mana of any color" in text or "add one mana of any one color" in text:
        colors.update(BOROS_COLORS)
    if "treasure token" in text:
        colors.update(BOROS_COLORS)
    if "search your library" in text and (
        "mountain" in text or "plains" in text or "basic land" in text
    ):
        colors.update(BOROS_COLORS)
    if "{c}" in text or "add {c}" in text or "add one colorless" in text:
        colors.add("C")
    return colors


def mana_colors(card: Mapping[str, Any]) -> set[str]:
    return mana_colors_from_text(str(card.get("type_line") or ""), str(card.get("oracle_text") or ""))


def etb_mode(card: Mapping[str, Any]) -> str:
    text = card_text(card)
    if "unless you have two or more opponents" in text:
        return "untapped_commander_multiplayer"
    if "as this land enters, you may pay 2 life" in text:
        return "optional_life_untapped"
    if "enters tapped unless" in text:
        return "conditional_tapped"
    if "if you don't, it enters tapped" in text:
        return "conditional_tapped"
    if "enters tapped" in text or "enters the battlefield tapped" in text:
        return "always_tapped"
    return "untapped"


def land_roles(card: Mapping[str, Any]) -> list[str]:
    text = card_text(card)
    name = str(card.get("card_name") or "")
    roles: set[str] = set()
    if is_basic_land(card):
        roles.add("basic_count_for_land_tax")
    if "search your library" in text and (
        "mountain" in text or "plains" in text or "basic land" in text
    ):
        roles.add("fetch_or_basic_access")
    if "add {c}{c}" in text:
        roles.add("fast_colorless_acceleration")
    if "put your commander into your hand from the command zone" in text:
        roles.add("commander_recast_recovery")
    if "hexproof and indestructible" in text:
        roles.add("legendary_protection")
    if "no maximum hand size" in text:
        roles.add("no_max_hand_size")
    if "draw a card" in text:
        roles.add("land_card_flow")
    if "surveil" in text:
        roles.add("topdeck_or_graveyard_selection")
    if "cycling" in text:
        roles.add("cycling_flood_escape")
    if "urza's saga" in name.lower() or "search your library for an artifact card with mana cost {0} or {1}" in text:
        roles.add("artifact_tutor_land")
    if "deals 2 damage to you" in text or "pay 1 life" in text:
        roles.add("life_cost")
    return sorted(roles)


def direct_mana_source(card: Mapping[str, Any]) -> bool:
    text = card_text(card)
    return (
        "{t}: add" in text
        or "tap: add" in text
        or "{t}, pay" in text and "search your library" in text
        or "treasure token" in text
        or "add {r} for each card" in text
    )


def is_ramp_card(card: Mapping[str, Any]) -> bool:
    return str(card.get("functional_tag") or "").lower() == "ramp"


def ramp_kind(card: Mapping[str, Any]) -> str:
    text = card_text(card)
    cmc = as_float(card.get("safe_cmc"), as_float(card.get("cmc")))
    colors = mana_colors(card)
    if "cost {1} less" in text or "costs {1} less" in text:
        return "early_cost_reducer"
    if "untap this artifact during each other player's untap step" in text:
        return "turn_cycle_miracle_mana"
    if "whenever an opponent draws" in text and "treasure token" in text:
        return "table_tax_treasure_engine"
    if "treasure token" in text or "add {r} for each card" in text:
        return "burst_or_treasure_ramp"
    if cmc <= 2 and colors & BOROS_COLORS:
        return "early_recurring_colored_mana"
    if cmc <= 1 and colors <= {"C"} and "add {c}" in text:
        return "early_colorless_acceleration"
    if direct_mana_source(card):
        return "recurring_or_contextual_mana"
    return "tagged_ramp_needs_manual_role_review"


def ramp_profile(card: Mapping[str, Any]) -> dict[str, Any]:
    colors = mana_colors(card)
    kind = ramp_kind(card)
    text = card_text(card)
    risk_flags: list[str] = []
    if colors and not (colors & BOROS_COLORS):
        risk_flags.append("colorless_only")
    if "doesn't untap during your untap step" in text:
        risk_flags.append("nonstandard_untap")
    if "deals 1 damage to you" in text:
        risk_flags.append("life_loss")
    if kind == "tagged_ramp_needs_manual_role_review":
        risk_flags.append("manual_role_review")
    return {
        "card_name": card.get("card_name"),
        "quantity": as_int(card.get("quantity"), 1),
        "cmc": as_float(card.get("safe_cmc"), as_float(card.get("cmc"))),
        "kind": kind,
        "colors": sorted(colors),
        "early_foundation": kind
        in {
            "early_recurring_colored_mana",
            "early_colorless_acceleration",
            "early_cost_reducer",
        },
        "true_early_mana": kind
        in {
            "early_recurring_colored_mana",
            "early_colorless_acceleration",
        },
        "risk_flags": risk_flags,
    }


def summarize_lands(cards: Iterable[Mapping[str, Any]]) -> dict[str, Any]:
    lands = [card for card in cards if is_land(card)]
    color_source_counts = Counter()
    colorless_only: list[str] = []
    tapped_modes = Counter()
    role_counts = Counter()
    land_rows = []
    for card in lands:
        qty = as_int(card.get("quantity"), 1)
        colors = mana_colors(card)
        for color in colors:
            color_source_counts[color] += qty
        if colors and colors <= {"C"}:
            colorless_only.append(str(card.get("card_name")))
        mode = etb_mode(card)
        tapped_modes[mode] += qty
        roles = land_roles(card)
        for role in roles:
            role_counts[role] += qty
        land_rows.append(
            {
                "card_name": card.get("card_name"),
                "quantity": qty,
                "colors": sorted(colors),
                "etb_mode": mode,
                "roles": roles,
            }
        )
    return {
        "land_count": sum(as_int(card.get("quantity"), 1) for card in lands),
        "basic_land_count": sum(as_int(card.get("quantity"), 1) for card in lands if is_basic_land(card)),
        "red_source_count": color_source_counts["R"],
        "white_source_count": color_source_counts["W"],
        "colorless_source_count": color_source_counts["C"],
        "colorless_only_lands": sorted(colorless_only),
        "tapped_mode_counts": dict(sorted(tapped_modes.items())),
        "land_role_counts": dict(sorted(role_counts.items())),
        "lands": sorted(land_rows, key=lambda row: str(row["card_name"]).lower()),
    }


def summarize_ramp(cards: Iterable[Mapping[str, Any]]) -> dict[str, Any]:
    ramp_cards = [card for card in cards if is_ramp_card(card)]
    profiles = [ramp_profile(card) for card in ramp_cards]
    kind_counts = Counter()
    risk_counts = Counter()
    for profile in profiles:
        kind_counts[profile["kind"]] += as_int(profile["quantity"], 1)
        for flag in profile["risk_flags"]:
            risk_counts[flag] += as_int(profile["quantity"], 1)
    return {
        "ramp_count": sum(as_int(card.get("quantity"), 1) for card in ramp_cards),
        "early_foundation_count": sum(
            as_int(profile["quantity"], 1) for profile in profiles if profile["early_foundation"]
        ),
        "true_early_mana_count": sum(
            as_int(profile["quantity"], 1) for profile in profiles if profile["true_early_mana"]
        ),
        "turn_cycle_miracle_mana_count": kind_counts["turn_cycle_miracle_mana"],
        "burst_or_treasure_count": kind_counts["burst_or_treasure_ramp"]
        + kind_counts["table_tax_treasure_engine"],
        "kind_counts": dict(sorted(kind_counts.items())),
        "risk_counts": dict(sorted(risk_counts.items())),
        "ramp_profiles": sorted(profiles, key=lambda row: (row["cmc"], str(row["card_name"]).lower())),
    }


def role_counts(cards: Iterable[Mapping[str, Any]]) -> dict[str, int]:
    counts = Counter()
    for card in cards:
        qty = as_int(card.get("quantity"), 1)
        if as_int(card.get("is_commander")):
            counts["commander"] += qty
        elif is_land(card):
            counts["land"] += qty
        else:
            counts[str(card.get("functional_tag") or "unknown")] += qty
    return dict(sorted(counts.items()))


def variant_role_comparison(conn: sqlite3.Connection, deck_ids: Iterable[int]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for deck_id in deck_ids:
        cards = load_deck_cards(conn, deck_id)
        nonlands = [card for card in cards if not is_land(card)]
        total_nonland_cmc = sum(
            as_int(card.get("quantity"), 1) * as_float(card.get("safe_cmc"), as_float(card.get("cmc")))
            for card in nonlands
        )
        nonland_count = sum(as_int(card.get("quantity"), 1) for card in nonlands)
        counts = role_counts(cards)
        out.append(
            {
                "deck_id": deck_id,
                "total_cards": sum(as_int(card.get("quantity"), 1) for card in cards),
                "lands": counts.get("land", 0),
                "ramp": counts.get("ramp", 0),
                "draw": counts.get("draw", 0),
                "removal": counts.get("removal", 0),
                "protection": counts.get("protection", 0),
                "avg_nonland_cmc": round(total_nonland_cmc / nonland_count, 2)
                if nonland_count
                else 0.0,
            }
        )
    return out


def commander_legality(conn: sqlite3.Connection, card_name: str) -> str | None:
    if not sqlite_connection_has_table(conn, "card_legalities"):
        return None
    row = conn.execute(
        """
        SELECT status
        FROM card_legalities
        WHERE lower(card_name) = lower(?) AND lower(format) = 'commander'
        LIMIT 1
        """,
        (card_name,),
    ).fetchone()
    return str(row["status"]) if row else None


def format_staple(conn: sqlite3.Connection, card_name: str) -> dict[str, Any] | None:
    if not sqlite_connection_has_table(conn, "format_staples"):
        return None
    row = conn.execute(
        """
        SELECT card_name, archetype, category, color_identity, edhrec_rank, is_banned
        FROM format_staples
        WHERE lower(card_name) = lower(?) AND lower(format) = 'commander'
        ORDER BY edhrec_rank
        LIMIT 1
        """,
        (card_name,),
    ).fetchone()
    return dict(row) if row else None


def battle_rule_summary(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "battle_card_rules"):
        return {"rule_count": 0, "active_rule_count": 0, "scopes": []}
    rows = conn.execute(
        """
        SELECT execution_status, review_status, effect_json
        FROM battle_card_rules
        WHERE lower(card_name) = lower(?)
           OR normalized_name = ?
        """,
        (card_name, normalize_name(card_name)),
    ).fetchall()
    scopes: set[str] = set()
    active = 0
    for row in rows:
        if str(row["execution_status"] or "") in ACTIVE_RULE_STATUSES and str(
            row["review_status"] or ""
        ) in ACTIVE_REVIEW_STATUSES:
            active += 1
        try:
            effect = json.loads(row["effect_json"] or "{}")
        except Exception:
            effect = {}
        if isinstance(effect, Mapping) and effect.get("battle_model_scope"):
            scopes.add(str(effect["battle_model_scope"]))
    return {"rule_count": len(rows), "active_rule_count": active, "scopes": sorted(scopes)}


def load_edhrec_stats(path: Path, card_names: Iterable[str]) -> dict[str, dict[str, Any]]:
    wanted = {normalize_name(name): name for name in card_names}
    out: dict[str, dict[str, Any]] = {}
    payload = read_json_if_exists(path)
    rows = payload if isinstance(payload, list) else []
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        key = normalize_name(str(row.get("name") or ""))
        if key not in wanted:
            continue
        potential = as_float(row.get("potential_decks"))
        inclusion = as_float(row.get("inclusion"))
        pct = as_float(row.get("pct"), (100.0 * inclusion / potential) if potential else 0.0)
        out[wanted[key]] = {
            "inclusion": as_int(row.get("inclusion")),
            "potential_decks": as_int(row.get("potential_decks")),
            "pct": round(pct, 2),
            "synergy": row.get("synergy"),
            "trend_zscore": row.get("trend_zscore"),
            "source": rel(path),
        }
    return out


def parse_mana_vault_arcane_synthesis(path: Path) -> dict[str, Any]:
    payload = read_json_if_exists(path)
    if not isinstance(payload, Mapping):
        return {}
    summary = payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {}
    return {
        "source": rel(path),
        "decision": summary.get("decision"),
        "promotion_allowed": summary.get("promotion_allowed"),
        "latest_natural_delta_pp": summary.get("latest_natural_delta_pp"),
        "next_action": summary.get("next_action"),
    }


def parse_profiled_cut_block(path: Path, card_name: str, cut_name: str) -> dict[str, Any]:
    text = read_text_if_exists(path)
    if not text:
        return {}
    pattern = re.compile(
        r"\|\s*"
        + re.escape(card_name)
        + r"\s*\|\s*"
        + re.escape(cut_name)
        + r"\s*\|\s*`(?P<status>[^`]+)`\s*\|\s*(?P<score>[^|]+)\|\s*(?P<blockers>[^|]+)\|",
        re.IGNORECASE,
    )
    match = pattern.search(text)
    if not match:
        return {}
    return {
        "source": rel(path),
        "status": match.group("status").strip(),
        "score": as_int(match.group("score").strip()),
        "blockers": [item.strip() for item in match.group("blockers").split(",") if item.strip()],
    }


def parse_one_ring_decision(path: Path) -> dict[str, Any]:
    text = read_text_if_exists(path)
    if not text:
        return {}
    status = None
    status_match = re.search(r"- Status: `([^`]+)`", text)
    if status_match:
        status = status_match.group(1)
    aggregate_match = re.search(
        r"\| `deck_607` \| `(?P<base_wins>\d+)` \| `(?P<base_games>\d+)`.*?\n"
        r"\| `candidate_607_one_ring_creative_technique_v1` \| `(?P<cand_wins>\d+)` \| `(?P<cand_games>\d+)`",
        text,
        re.DOTALL,
    )
    card_use: dict[str, Any] = {}
    for label, field in [
        ("`The One Ring` accessed games", "accessed_games"),
        ("`The One Ring` cost paid", "cost_paid"),
        ("`The One Ring` spell cast", "spell_cast"),
        ("`The One Ring` resolved", "resolved"),
        ("`The One Ring` utility activations", "utility_activations"),
    ]:
        match = re.search(re.escape(label) + r"\s*\|\s*`0`\s*\|\s*`(?P<value>\d+)`", text)
        if match:
            card_use[field] = as_int(match.group("value"))
    return {
        "source": rel(path),
        "status": status,
        "aggregate": {
            "baseline_wins": as_int(aggregate_match.group("base_wins")) if aggregate_match else None,
            "baseline_games": as_int(aggregate_match.group("base_games")) if aggregate_match else None,
            "candidate_wins": as_int(aggregate_match.group("cand_wins")) if aggregate_match else None,
            "candidate_games": as_int(aggregate_match.group("cand_games")) if aggregate_match else None,
        },
        "card_use": card_use,
        "decision": "reject_current_607_shell" if status == "rejected_keep_607_baseline" else status,
    }


def candidate_staple_profile(
    conn: sqlite3.Connection,
    cards: list[Mapping[str, Any]],
    card_name: str,
    edhrec_stats: Mapping[str, Mapping[str, Any]],
    *,
    mana_vault_arcane: Mapping[str, Any] | None = None,
    profiled_cut_report: Path = DEFAULT_PROFILED_CUT_REPORT,
    one_ring_decision: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    in_deck = any(normalize_name(str(card.get("card_name") or "")) == normalize_name(card_name) for card in cards)
    oracle = oracle_lookup(conn, card_name)
    staple = format_staple(conn, card_name)
    profile: dict[str, Any] = {
        "card_name": card_name,
        "in_protected_607": in_deck,
        "commander_legality": commander_legality(conn, card_name),
        "oracle": {
            "cmc": oracle.get("cmc"),
            "type_line": oracle.get("type_line"),
            "oracle_text": oracle.get("oracle_text"),
        },
        "format_staple": staple,
        "edhrec_lorehold": dict(edhrec_stats.get(card_name) or {}),
        "battle_rule_summary": battle_rule_summary(conn, card_name),
    }
    if card_name == "Mana Vault":
        profile["role_interpretation"] = "fast_colorless_burst_not_colored_fixing"
        profile["current_decision"] = "blocked_for_current_known_cuts"
        profile["decision_reasons"] = [
            "legal_and_accessible_but_colorless_only",
            "arcane_signet_cut_loses_boros_fixing_and_recurring_source",
            "benders_waterskin_cut_has_prior_exact_reject",
        ]
        if mana_vault_arcane:
            profile["mana_vault_over_arcane_signet"] = dict(mana_vault_arcane)
        profile["mana_vault_over_benders_waterskin"] = parse_profiled_cut_block(
            profiled_cut_report, "Mana Vault", "Bender's Waterskin"
        )
    elif card_name == "The One Ring":
        profile["role_interpretation"] = "draw_protection_value_not_miracle_or_mana_foundation"
        profile["current_decision"] = "blocked_for_current_607_shell"
        profile["decision_reasons"] = [
            "legal_and_accessible_but_low_lorehold_specific_synergy",
            "four_mana_non_instant_non_sorcery_value_piece_competes_with_big_spell_slots",
            "confirmed_value_lane_retest_lost_to_607",
        ]
        if one_ring_decision:
            profile["one_ring_current_shell_decision"] = dict(one_ring_decision)
    return profile


def structural_assessment(lands: Mapping[str, Any], ramp: Mapping[str, Any], cards: list[Mapping[str, Any]]) -> dict[str, Any]:
    land_count = as_int(lands.get("land_count"))
    ramp_count = as_int(ramp.get("ramp_count"))
    land_tax_present = any(normalize_name(str(card.get("card_name") or "")) == "land tax" for card in cards)
    total_mana_package = land_count + ramp_count + (1 if land_tax_present else 0)
    watch_items: list[str] = []
    blockers: list[str] = []
    if land_count < 33:
        blockers.append("land_count_below_lorehold_floor")
    if total_mana_package < 48:
        blockers.append("total_mana_package_below_commander_mv5_floor")
    if as_int(ramp.get("early_foundation_count")) < 8:
        blockers.append("early_foundation_below_commander_mv5_target")
    if as_int(lands.get("red_source_count")) < 20:
        blockers.append("red_sources_below_boros_target")
    if as_int(lands.get("white_source_count")) < 20:
        blockers.append("white_sources_below_boros_target")
    if len(lands.get("colorless_only_lands") or []) >= 5:
        watch_items.append("colorless_utility_land_pressure")
    tapped = lands.get("tapped_mode_counts") or {}
    if as_int(tapped.get("always_tapped")) + as_int(tapped.get("conditional_tapped")) >= 4:
        watch_items.append("tapped_land_tempo_pressure")
    if as_int(ramp.get("burst_or_treasure_count")) >= 4:
        watch_items.append("late_or_contextual_ramp_should_not_be_counted_as_opening_fixing")
    status = "blocked_mana_foundation" if blockers else "mana_foundation_pass_with_watch_items"
    return {
        "status": status,
        "blockers": blockers,
        "watch_items": watch_items,
        "land_tax_present": land_tax_present,
        "total_mana_package_including_land_tax": total_mana_package,
        "heuristics": {
            "lorehold_commander_cmc": 5,
            "target_land_floor_with_high_ramp": 33,
            "target_total_mana_package": "48-50",
            "target_early_foundation_for_mv5_commander": 8,
            "target_boros_color_sources_each": 20,
        },
    }


def build_audit(
    *,
    conn: sqlite3.Connection,
    db_path: Path,
    deck_id: int = DEFAULT_DECK_ID,
    edhrec_card_data: Path = DEFAULT_EDHREC_CARD_DATA,
    one_ring_decision_path: Path = DEFAULT_ONE_RING_DECISION,
    profiled_cut_report: Path = DEFAULT_PROFILED_CUT_REPORT,
    mana_vault_arcane_synthesis_path: Path | None = None,
) -> dict[str, Any]:
    cards = load_deck_cards(conn, deck_id)
    lands = summarize_lands(cards)
    ramp = summarize_ramp(cards)
    assessment = structural_assessment(lands, ramp, cards)
    edhrec_stats = load_edhrec_stats(edhrec_card_data, ["Mana Vault", "The One Ring", "Arcane Signet", "Sol Ring", "Bender's Waterskin"])
    one_ring_decision = parse_one_ring_decision(one_ring_decision_path)
    mana_vault_arcane = (
        parse_mana_vault_arcane_synthesis(mana_vault_arcane_synthesis_path)
        if mana_vault_arcane_synthesis_path
        else {}
    )
    candidates = [
        candidate_staple_profile(
            conn,
            cards,
            "Mana Vault",
            edhrec_stats,
            mana_vault_arcane=mana_vault_arcane,
            profiled_cut_report=profiled_cut_report,
        ),
        candidate_staple_profile(
            conn,
            cards,
            "The One Ring",
            edhrec_stats,
            one_ring_decision=one_ring_decision,
        ),
    ]
    comparison = variant_role_comparison(conn, range(606, 617))
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_mana_foundation_audit",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_id": deck_id,
        "source_db": rel(db_path),
        "status": assessment["status"],
        "summary": {
            "deck_id": deck_id,
            "total_cards": sum(as_int(card.get("quantity"), 1) for card in cards),
            "role_counts": role_counts(cards),
            "land_count": lands["land_count"],
            "ramp_count": ramp["ramp_count"],
            "land_tax_present": assessment["land_tax_present"],
            "total_mana_package_including_land_tax": assessment[
                "total_mana_package_including_land_tax"
            ],
            "early_foundation_count": ramp["early_foundation_count"],
            "true_early_mana_count": ramp["true_early_mana_count"],
            "red_source_count": lands["red_source_count"],
            "white_source_count": lands["white_source_count"],
            "colorless_only_land_count": len(lands["colorless_only_lands"]),
            "watch_item_count": len(assessment["watch_items"]),
            "blocker_count": len(assessment["blockers"]),
            "mana_vault_decision": candidates[0]["current_decision"],
            "one_ring_decision": candidates[1]["current_decision"],
        },
        "external_learning": EXTERNAL_LEARNING,
        "structural_assessment": assessment,
        "lands": lands,
        "ramp": ramp,
        "candidate_staples": candidates,
        "variant_role_comparison": comparison,
        "next_learning_actions": [
            "Do not repeat Mana Vault over Arcane Signet or Bender's Waterskin without a new cut hypothesis.",
            "Do not retest The One Ring in protected 607 unless a new shell changes draw/protection pressure.",
            "Next mana work should test only named same-lane changes that preserve Boros fixing and miracle cadence.",
        ],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    assessment = payload["structural_assessment"]
    lines = [
        "# Lorehold Mana Foundation Audit",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- status: `{payload['status']}`",
        f"- postgres_writes: `{str(payload['postgres_writes']).lower()}`",
        f"- source_db_mutated: `{str(payload['source_db_mutated']).lower()}`",
        "",
        "## Summary",
        "",
        f"- lands: `{summary['land_count']}`",
        f"- ramp: `{summary['ramp_count']}`",
        f"- total mana package including Land Tax: `{summary['total_mana_package_including_land_tax']}`",
        f"- early foundation pieces: `{summary['early_foundation_count']}`",
        f"- true early mana pieces: `{summary['true_early_mana_count']}`",
        f"- red sources: `{summary['red_source_count']}`",
        f"- white sources: `{summary['white_source_count']}`",
        f"- blockers: `{', '.join(assessment['blockers']) if assessment['blockers'] else 'none'}`",
        f"- watch items: `{', '.join(assessment['watch_items']) if assessment['watch_items'] else 'none'}`",
        "",
        "## Ramp Classes",
        "",
        "| Class | Count |",
        "| --- | ---: |",
    ]
    for kind, count in (payload["ramp"].get("kind_counts") or {}).items():
        lines.append(f"| `{kind}` | {count} |")
    lines.extend(
        [
            "",
            "## Candidate Staples",
            "",
            "| Card | Legal | In 607 | EDHREC Lorehold | Local decision |",
            "| --- | --- | --- | ---: | --- |",
        ]
    )
    for candidate in payload["candidate_staples"]:
        stats = candidate.get("edhrec_lorehold") or {}
        pct = stats.get("pct")
        pct_text = f"{pct}%" if pct is not None else "-"
        lines.append(
            "| {card} | `{legal}` | `{in_deck}` | {pct} | `{decision}` |".format(
                card=candidate["card_name"],
                legal=candidate.get("commander_legality") or "unknown",
                in_deck=str(candidate.get("in_protected_607")).lower(),
                pct=pct_text,
                decision=candidate.get("current_decision"),
            )
        )
    lines.extend(
        [
            "",
            "## Variant Comparison",
            "",
            "| Deck | Lands | Ramp | Draw | Removal | Protection | Avg nonland CMC |",
            "| ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in payload["variant_role_comparison"]:
        lines.append(
            f"| {row['deck_id']} | {row['lands']} | {row['ramp']} | {row['draw']} | "
            f"{row['removal']} | {row['protection']} | {row['avg_nonland_cmc']} |"
        )
    lines.extend(
        [
            "",
            "## Learning Sources",
            "",
        ]
    )
    for source in payload["external_learning"]:
        lines.append(f"- {source['source']}: {source['url']}")
    lines.extend(["", "## Next Actions", ""])
    for action in payload["next_learning_actions"]:
        lines.append(f"- {action}")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_DECK_ID)
    parser.add_argument("--edhrec-card-data", type=Path, default=DEFAULT_EDHREC_CARD_DATA)
    parser.add_argument("--one-ring-decision", type=Path, default=DEFAULT_ONE_RING_DECISION)
    parser.add_argument("--profiled-cut-report", type=Path, default=DEFAULT_PROFILED_CUT_REPORT)
    parser.add_argument("--mana-vault-arcane-synthesis", type=Path, default=None)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_mana_foundation_audit",
    )
    args = parser.parse_args()

    with connect(args.db) as conn:
        payload = build_audit(
            conn=conn,
            db_path=args.db,
            deck_id=args.deck_id,
            edhrec_card_data=args.edhrec_card_data,
            one_ring_decision_path=args.one_ring_decision,
            profiled_cut_report=args.profiled_cut_report,
            mana_vault_arcane_synthesis_path=args.mana_vault_arcane_synthesis,
        )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
