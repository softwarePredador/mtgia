#!/usr/bin/env python3
"""Canonical battle/deckbuilding rule registry for Hermes.

The battle engine can still use heuristic fallbacks, but this table is the
intended source of truth for card semantics that must be trusted by the
optimizer. One row represents what Hermes currently believes a card does in
battle and how deckbuilding should categorize it.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import sqlite3
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_DB = Path(os.environ.get("MANALOOM_KNOWLEDGE_DB", SCRIPT_DIR / "knowledge.db"))

SOURCE_PRIORITY = {
    "manual": 100,
    "curated": 90,
    "generated": 40,
    "imported": 30,
    "heuristic": 20,
}

EFFECT_TO_DECK_CATEGORY = {
    "ramp_permanent": "ramp",
    "ramp_ritual": "ramp",
    "ramp_engine": "ramp",
    "land_ramp": "ramp",
    "lander_token_maker": "ramp",
    "treasure_maker": "ramp",
    "silence_opponents": "protection",
    "silence_spell": "protection",
    "indestructible": "protection",
    "phase_out": "protection",
    "phase_creatures": "protection",
    "protect_creature": "protection",
    "cannot_lose_turn": "protection",
    "redirect_removal": "protection",
    "counter": "protection",
    "hate_artifact": "protection",
    "draw_cards": "draw",
    "cantrip_mana_filter_artifact": "draw",
    "draw_engine": "draw",
    "topdeck_manipulation": "draw",
    "loot": "draw",
    "tutor": "tutor",
    "finisher": "wincon",
    "approach": "wincon",
    "token_maker": "wincon",
    "overload_recursion": "wincon",
    "steal_all_creatures": "wincon",
    "pump_all": "wincon",
    "extra_turn": "wincon",
    "board_wipe": "wipe",
    "damage_wipe": "wipe",
    "remove_creature": "removal",
    "remove_permanent": "removal",
    "remove_artifact_or_3dmg": "removal",
    "deal_damage": "removal",
    "copy_spell": "engine",
    "recursion": "engine",
    "land_recursion": "engine",
    "land_recursion_creature": "engine",
    "life_artifact": "protection",
    "ripple_engine": "engine",
    "passive": "unknown",
    "land": "land",
    "creature": "unknown",
}

_RULE_CACHE: dict[str, tuple[int | None, dict[str, dict[str, Any]]]] = {}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_card_name(name: str) -> str:
    return re.sub(r"\s+", " ", str(name or "").strip().lower())


def table_exists(conn: sqlite3.Connection, table: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        (table,),
    ).fetchone()
    return bool(row)


def ensure_battle_card_rules(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS battle_card_rules (
            normalized_name TEXT PRIMARY KEY,
            card_name TEXT NOT NULL,
            effect_json TEXT NOT NULL DEFAULT '{}',
            deck_role_json TEXT NOT NULL DEFAULT '{}',
            source TEXT NOT NULL DEFAULT 'manual',
            confidence REAL NOT NULL DEFAULT 1.0,
            review_status TEXT NOT NULL DEFAULT 'verified',
            rule_version INTEGER NOT NULL DEFAULT 1,
            oracle_hash TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            last_seen_at TEXT
        )
        """
    )
    conn.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_battle_card_rules_source_status
        ON battle_card_rules(source, review_status)
        """
    )
    conn.commit()


def deck_role_from_effect(effect_json: dict[str, Any]) -> dict[str, Any]:
    effect = str(effect_json.get("effect") or "unknown")
    category = EFFECT_TO_DECK_CATEGORY.get(effect, "unknown")
    subtype = None
    if effect == "creature" and effect_json.get("is_mana_source"):
        category = "ramp"
        subtype = "mana_dork"
    role = {
        "category": category,
        "effect": effect,
    }
    if subtype:
        role["subtype"] = subtype
    if effect_json.get("instant"):
        role["timing"] = "instant"
    if effect_json.get("target"):
        role["target"] = effect_json["target"]
    return role


def _safe_json_loads(value: str | None) -> dict[str, Any]:
    if not value:
        return {}
    try:
        decoded = json.loads(value)
    except Exception:
        return {}
    return decoded if isinstance(decoded, dict) else {}


def stable_json(value: Any) -> str:
    return json.dumps(
        value,
        ensure_ascii=True,
        separators=(",", ":"),
        sort_keys=True,
    )


def _first_present(*values: Any) -> Any:
    for value in values:
        if value not in (None, "", [], {}):
            return value
    return None


def logical_rule_key(rule: dict[str, Any]) -> str:
    """Return a stable key for equivalent battle-rule semantics.

    Provenance/review metadata is intentionally excluded. Cards can still keep
    multiple rules: only duplicate rows with the same face/variant/effect/deck
    role collapse to the same key for replay/audit evidence.
    """
    effect = rule.get("effect_json") or rule.get("effect") or {}
    deck_role = rule.get("deck_role_json") or rule.get("deck_role") or {}
    if isinstance(effect, str):
        effect = _safe_json_loads(effect)
    if isinstance(deck_role, str):
        deck_role = _safe_json_loads(deck_role)
    if not isinstance(effect, dict):
        effect = {}
    if not isinstance(deck_role, dict):
        deck_role = {}
    payload = {
        "effect": effect,
        "deck_role": deck_role,
        "face_name": _first_present(
            rule.get("face_name"),
            effect.get("face_name"),
            deck_role.get("face_name"),
        ),
        "face_index": _first_present(
            rule.get("face_index"),
            effect.get("face_index"),
            deck_role.get("face_index"),
        ),
        "variant_kind": _first_present(
            rule.get("variant_kind"),
            effect.get("variant_kind"),
            deck_role.get("variant_kind"),
        ),
        "ability_kind": _first_present(
            rule.get("ability_kind"),
            effect.get("ability_kind"),
            deck_role.get("ability_kind"),
        ),
        "timing_window": _first_present(
            rule.get("timing_window"),
            effect.get("timing_window"),
            deck_role.get("timing_window"),
        ),
        "source_zone": _first_present(
            rule.get("source_zone"),
            effect.get("source_zone"),
            deck_role.get("source_zone"),
        ),
    }
    digest = hashlib.sha256(stable_json(payload).encode("utf-8")).hexdigest()
    return f"battle_rule_v1:{digest[:32]}"


def _db_mtime(db_path: Path) -> int | None:
    try:
        return int(db_path.stat().st_mtime_ns)
    except OSError:
        return None


def load_active_battle_card_rules(db_path: str | Path = DEFAULT_DB) -> dict[str, dict[str, Any]]:
    path = Path(db_path)
    mtime = _db_mtime(path)
    cache_key = str(path)
    cached = _RULE_CACHE.get(cache_key)
    if cached and cached[0] == mtime:
        return {key: dict(value) for key, value in cached[1].items()}
    if not path.exists():
        _RULE_CACHE[cache_key] = (mtime, {})
        return {}

    try:
        with closing(sqlite3.connect(path)) as conn:
            conn.row_factory = sqlite3.Row
            if not table_exists(conn, "battle_card_rules"):
                _RULE_CACHE[cache_key] = (mtime, {})
                return {}
            rows = conn.execute(
                """
                SELECT normalized_name, card_name, effect_json, deck_role_json,
                       source, confidence, review_status, rule_version, oracle_hash, notes
                FROM battle_card_rules
                WHERE review_status IN ('verified', 'needs_review', 'active')
                """
            ).fetchall()
    except sqlite3.Error:
        _RULE_CACHE[cache_key] = (mtime, {})
        return {}

    rules: dict[str, dict[str, Any]] = {}
    for row in rows:
        effect_json = _safe_json_loads(row["effect_json"])
        deck_role_json = _safe_json_loads(row["deck_role_json"])
        rule = {
            "normalized_name": row["normalized_name"],
            "card_name": row["card_name"],
            "effect_json": effect_json,
            "deck_role_json": deck_role_json,
            "source": row["source"],
            "confidence": row["confidence"],
            "review_status": row["review_status"],
            "rule_version": row["rule_version"],
            "oracle_hash": row["oracle_hash"],
            "notes": row["notes"],
        }
        rule["logical_rule_key"] = logical_rule_key(rule)
        rules[row["normalized_name"]] = rule
    _RULE_CACHE[cache_key] = (mtime, rules)
    return {key: dict(value) for key, value in rules.items()}


def lookup_battle_card_rule(
    db_path: str | Path,
    card_name: str,
) -> dict[str, Any] | None:
    rules = load_active_battle_card_rules(db_path)
    normalized = normalize_card_name(card_name)
    rule = rules.get(normalized)
    if rule:
        return dict(rule)
    face_prefix = f"{normalized} //"
    rule = next(
        (value for key, value in rules.items() if key.startswith(face_prefix)),
        None,
    )
    return dict(rule) if rule else None


def upsert_battle_card_rule(
    conn: sqlite3.Connection,
    card_name: str,
    effect_json: dict[str, Any],
    *,
    source: str,
    confidence: float,
    review_status: str,
    deck_role_json: dict[str, Any] | None = None,
    notes: str = "",
    oracle_hash: str | None = None,
) -> bool:
    ensure_battle_card_rules(conn)
    normalized = normalize_card_name(card_name)
    now = utc_now()
    current = conn.execute(
        """
        SELECT source FROM battle_card_rules WHERE normalized_name=?
        """,
        (normalized,),
    ).fetchone()
    if current:
        incoming_priority = SOURCE_PRIORITY.get(source, 0)
        current_priority = SOURCE_PRIORITY.get(str(current[0]), 0)
        if incoming_priority < current_priority:
            conn.execute(
                """
                UPDATE battle_card_rules
                SET last_seen_at=?
                WHERE normalized_name=?
                """,
                (now, normalized),
            )
            return False

    role = deck_role_json or deck_role_from_effect(effect_json)
    conn.execute(
        """
        INSERT INTO battle_card_rules (
            normalized_name, card_name, effect_json, deck_role_json, source,
            confidence, review_status, rule_version, oracle_hash, notes,
            created_at, updated_at, last_seen_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?)
        ON CONFLICT(normalized_name) DO UPDATE SET
            card_name=excluded.card_name,
            effect_json=excluded.effect_json,
            deck_role_json=excluded.deck_role_json,
            source=excluded.source,
            confidence=excluded.confidence,
            review_status=excluded.review_status,
            oracle_hash=excluded.oracle_hash,
            notes=excluded.notes,
            updated_at=excluded.updated_at,
            last_seen_at=excluded.last_seen_at
        """,
        (
            normalized,
            card_name,
            json.dumps(effect_json, ensure_ascii=True, sort_keys=True),
            json.dumps(role, ensure_ascii=True, sort_keys=True),
            source,
            confidence,
            review_status,
            oracle_hash,
            notes,
            now,
            now,
            now,
        ),
    )
    return True
