#!/usr/bin/env python3
"""Shared deck role metrics for Hermes report-only scripts.

The SQLite Hermes snapshot is a read model. Deck cardinality must come from
``deck_cards.quantity`` exactly once per card row. Functional roles are
membership overlays: one card can count as ramp and engine without becoming two
deck cards.
"""

from __future__ import annotations

import json
import re
import sqlite3
from collections import defaultdict
from typing import Any, Iterable


ROLE_FIELDS = {
    "land": "lands_tag",
    "ramp": "ramp_tag",
    "draw": "draw_tag",
    "removal": "removal_tag",
    "tutor": "tutor_tag",
    "board_wipe": "board_wipe_tag",
    "protection": "protection_tag",
    "recursion": "recursion_tag",
    "wincon": "wincon_tag",
    "engine": "engine_tag",
    "unknown": "unknown_tag",
}

TAG_ALIASES = {
    "lands": "land",
    "mana_rock": "ramp",
    "artifact_mana": "ramp",
    "ramp_permanent": "ramp",
    "ramp_ritual": "ramp",
    "ramp_engine": "ramp",
    "ramp_fixing": "ramp",
    "ramp_extra_lands": "ramp",
    "ramp_treasure": "ramp",
    "ramp_rocks": "ramp",
    "ramp_any": "ramp",
    "mana_dorks": "ramp",
    "mana_creatures": "ramp",
    "nonland_mana_sources": "ramp",
    "ritual": "ramp",
    "rituals": "ramp",
    "treasure_generation": "ramp",
    "draw_cards": "draw",
    "draw_engine": "draw",
    "draw_value": "draw",
    "supplemental_draw": "draw",
    "card_advantage": "draw",
    "loot": "draw",
    "looting": "draw",
    "rummage": "draw",
    "wheel": "draw",
    "wheels": "draw",
    "exile_value": "draw",
    "spot_removal": "removal",
    "remove_creature": "removal",
    "remove_permanent": "removal",
    "interaction": "removal",
    "interaction_counter": "removal",
    "replayable_interaction": "removal",
    "boardwipe": "board_wipe",
    "wipe": "board_wipe",
    "damage_wipe": "board_wipe",
    "board_wipes_bounce": "board_wipe",
    "tutors": "tutor",
    "counter": "protection",
    "stax": "protection",
    "silence_opponents": "protection",
    "indestructible": "protection",
    "phase_out": "protection",
    "graveyard_protection": "protection",
    "interaction_protection": "protection",
    "graveyard": "recursion",
    "land_recursion_bounce": "recursion",
    "finisher": "wincon",
    "finishers": "wincon",
    "combo": "wincon",
    "combo_finishers": "wincon",
    "storm_combo": "wincon",
    "overload_recursion": "wincon",
    "steal_all_creatures": "wincon",
    "pump_all": "wincon",
    "extra_turn": "wincon",
    "value_engine": "engine",
    "copy": "engine",
    "copy_spell": "engine",
    "counter_payoffs": "engine",
    "proliferate_engines": "engine",
    "planeswalkers_superfriends": "engine",
    "landfall_payoffs": "engine",
    "sacrifice_fodder": "engine",
    "sacrifice_outlets": "engine",
    "aristocrat_payoffs": "engine",
    "self_mill": "engine",
    "exile_casting": "engine",
    "treasure_payoffs": "engine",
    "nonhuman_enablers": "engine",
    "human_hits": "engine",
    "combat_payoffs": "engine",
    "evasive_enablers": "engine",
    "ninjas": "engine",
    "topdeck_manipulation": "engine",
    "high_mv_reveals": "engine",
    "cheap_creature_density": "engine",
    "bounce_loop_pieces": "engine",
    "infinite_mana_pieces": "engine",
}

TYPE_FALLBACK_TAGS = {
    "artifact",
    "creature",
    "enchantment",
    "planeswalker",
    "utility",
}


def normalize_tag(value: Any) -> str:
    tag = re.sub(r"\s+", "_", str(value or "").strip().lower())
    return TAG_ALIASES.get(tag, tag)


def parse_json_list(value: Any) -> list[str]:
    if not value:
        return []
    if isinstance(value, list):
        result: list[str] = []
        for item in value:
            if isinstance(item, dict):
                tag = item.get("tag") or item.get("role") or item.get("category")
                if tag:
                    result.append(str(tag))
            else:
                result.append(str(item))
        return result
    try:
        decoded = json.loads(str(value))
    except Exception:
        return []
    return parse_json_list(decoded)


def row_keys(row: sqlite3.Row) -> set[str]:
    return set(row.keys())


def row_role_memberships(row: sqlite3.Row) -> set[str]:
    keys = row_keys(row)
    raw_tags: list[str] = []
    if "functional_tags_json" in keys:
        raw_tags.extend(parse_json_list(row["functional_tags_json"]))
    if "functional_tag" in keys and row["functional_tag"]:
        raw_tags.append(str(row["functional_tag"]))

    roles = {
        normalize_tag(tag)
        for tag in raw_tags
        if normalize_tag(tag) and normalize_tag(tag) != "unknown"
    }

    type_line = str(row["type_line"] or "") if "type_line" in keys else ""
    if "Land" in type_line:
        roles.add("land")

    roles = {role for role in roles if role in ROLE_FIELDS and role not in TYPE_FALLBACK_TAGS}
    if not roles:
        roles.add("unknown")
    return roles


def deck_table_columns(conn: sqlite3.Connection) -> set[str]:
    return {row[1] for row in conn.execute("PRAGMA table_info(deck_cards)")}


def table_columns(conn: sqlite3.Connection, table: str) -> set[str]:
    return {row[1] for row in conn.execute(f"PRAGMA table_info({table})")}


def select_column(columns: set[str], name: str, default_sql: str) -> str:
    return f"d.{name} AS {name}" if name in columns else f"{default_sql} AS {name}"


def load_deck_metric_rows(conn: sqlite3.Connection) -> list[dict[str, Any]]:
    """Return deck rows with role metrics from multi-tag membership overlays."""

    conn.row_factory = sqlite3.Row
    columns = deck_table_columns(conn)
    deck_columns = table_columns(conn, "decks")
    commander_id_expr = select_column(deck_columns, "commander_id", "NULL")
    archetype_expr = select_column(deck_columns, "archetype", "''")
    notes_expr = select_column(deck_columns, "notes", "''")
    total_lands_expr = (
        "d.total_lands AS col_lands" if "total_lands" in deck_columns else "NULL AS col_lands"
    )
    db_total_cards_expr = (
        "d.total_cards AS db_total_cards" if "total_cards" in deck_columns else "NULL AS db_total_cards"
    )
    ramp_count_expr = (
        "d.ramp_count AS col_ramp" if "ramp_count" in deck_columns else "NULL AS col_ramp"
    )
    draw_count_expr = (
        "d.draw_count AS col_draw" if "draw_count" in deck_columns else "NULL AS col_draw"
    )
    removal_count_expr = (
        "d.removal_count AS col_removal" if "removal_count" in deck_columns else "NULL AS col_removal"
    )
    protection_count_expr = (
        "d.protection_count AS col_protection" if "protection_count" in deck_columns else "NULL AS col_protection"
    )
    wincon_count_expr = (
        "d.wincon_count AS col_wincon" if "wincon_count" in deck_columns else "NULL AS col_wincon"
    )
    deck_rows = [
        dict(row)
        for row in conn.execute(
            f"""
            SELECT d.id, d.deck_name, {commander_id_expr}, {archetype_expr}, {notes_expr},
                   COALESCE(SUM(dc.quantity), 0) AS total_cards,
                   {total_lands_expr},
                   {db_total_cards_expr},
                   {ramp_count_expr},
                   {draw_count_expr},
                   {removal_count_expr},
                   {protection_count_expr},
                   {wincon_count_expr},
                   ROUND(AVG(dc.cmc), 2) AS avg_cmc
            FROM decks d
            LEFT JOIN deck_cards dc ON dc.deck_id = d.id
            GROUP BY d.id
            ORDER BY d.id
            """
        ).fetchall()
    ]

    metrics: dict[int, dict[str, int]] = defaultdict(lambda: {field: 0 for field in ROLE_FIELDS.values()})
    functional_tags_expr = (
        "functional_tags_json"
        if "functional_tags_json" in columns
        else "'[]' AS functional_tags_json"
    )
    for row in conn.execute(
        f"""
        SELECT deck_id, quantity, functional_tag, {functional_tags_expr}, type_line
        FROM deck_cards
        ORDER BY deck_id, card_name
        """
    ).fetchall():
        qty = int(row["quantity"] or 0)
        for role in row_role_memberships(row):
            field = ROLE_FIELDS.get(role)
            if field:
                metrics[int(row["deck_id"])][field] += qty

    result: list[dict[str, Any]] = []
    for deck in deck_rows:
        deck_id = int(deck["id"])
        for field in ROLE_FIELDS.values():
            deck[field] = metrics[deck_id][field]
        deck["role_metric_source"] = (
            "functional_tags_json_with_functional_tag_fallback"
            if "functional_tags_json" in columns
            else "functional_tag_legacy"
        )
        result.append(deck)
    return result


def tag_metrics_from_deck(deck: dict[str, Any]) -> dict[str, Any]:
    return {
        "lands": deck["lands_tag"],
        "ramp": deck["ramp_tag"],
        "draw": deck["draw_tag"],
        "removal": deck["removal_tag"],
        "interaction": deck["removal_tag"],
        "tutor": deck["tutor_tag"],
        "board_wipe": deck["board_wipe_tag"],
        "wipe": deck["board_wipe_tag"],
        "protection": deck["protection_tag"],
        "wincon": deck["wincon_tag"],
        "finishers": deck["wincon_tag"],
        "recursion": deck["recursion_tag"],
        "engine": deck["engine_tag"],
    }


def role_sum(deck: dict[str, Any]) -> int:
    return sum(int(deck.get(field) or 0) for field in ROLE_FIELDS.values() if field != "unknown_tag")
