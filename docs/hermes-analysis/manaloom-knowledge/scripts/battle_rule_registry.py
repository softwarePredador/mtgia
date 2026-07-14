#!/usr/bin/env python3
"""Canonical battle/deckbuilding rule registry for Hermes.

The battle engine can still use heuristic fallbacks, but this table is the
intended source of truth for card semantics that must be trusted by the
optimizer. Rows are keyed by `(normalized_name, logical_rule_key)` so a card can
carry multiple executable semantics without multiplying deck rows.
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

REVIEW_STATUS_PRIORITY = {
    "verified": 0,
    "active": 1,
    "needs_review": 2,
    "deprecated": 8,
    "rejected": 9,
}

EXECUTION_STATUS_PRIORITY = {
    "executable": 0,
    "auto": 1,
    "annotation_only": 2,
    "review_only": 3,
    "disabled": 4,
}

EFFECT_TO_DECK_CATEGORY = {
    "ramp_permanent": "ramp",
    "ramp_ritual": "ramp",
    "ramp_engine": "ramp",
    "land_ramp": "ramp",
    "lander_token_maker": "ramp",
    "treasure_maker": "ramp",
    "static_cost_reduction": "support",
    "cost_reduction": "support",
    "silence_opponents": "protection",
    "silence_spell": "protection",
    "gift_hexproof_indestructible": "protection",
    "indestructible": "protection",
    "phase_out": "protection",
    "phase_creatures": "protection",
    "protect_creature": "protection",
    "cannot_lose_turn": "protection",
    "damage_prevention_shield": "protection",
    "redirect_removal": "protection",
    "counter": "protection",
    "hate_artifact": "protection",
    "attack_limit": "protection",
    "attack_tax": "protection",
    "draw_cards": "draw",
    "composite_resolution": "draw",
    "dig_to_hand": "draw",
    "cantrip_mana_filter_artifact": "draw",
    "draw_engine": "draw",
    "equipment_static_attachment": "protection",
    "aura_static_attachment": "support",
    "static_global_power_toughness_boost": "support",
    "topdeck_manipulation": "draw",
    "loot": "draw",
    "tutor": "tutor",
    "finisher": "wincon",
    "approach": "wincon",
    "token_maker": "wincon",
    "mill_cards": "wincon",
    "overload_recursion": "wincon",
    "steal_all_creatures": "wincon",
    "pump_all": "wincon",
    "extra_turn": "wincon",
    "worldfire_reset": "wincon",
    "airbend_other_creatures": "wipe",
    "board_wipe": "wipe",
    "damage_wipe": "wipe",
    "damage_wipe_treasure": "wipe",
    "exile_artifact_enchantment_creature_convoke_wipe": "wipe",
    "remove_creature": "removal",
    "fated_clash_protect_then_destroy": "wipe",
    "remove_permanent": "removal",
    "graveyard_exile": "removal",
    "remove_artifact_or_3dmg": "removal",
    "damage_player_and_creatures": "removal",
    "deal_damage": "removal",
    "damage_modifier": "wincon",
    "goad_opponents_creatures_cant_block": "wincon",
    "copy_spell": "engine",
    "exile_top_nonland_free_cast": "engine",
    "recursion": "engine",
    "add_counters": "support",
    "untap_target": "ramp",
    "stat_modifier_until_eot": "support",
    "stat_modifier_until_eot_untap_target": "support",
    "graveyard_flashback_grant": "engine",
    "redistribute_life_totals": "wincon",
    "land_recursion": "engine",
    "land_recursion_creature": "engine",
    "topdeck_play": "ramp",
    "life_artifact": "protection",
    "ripple_engine": "engine",
    "passive": "unknown",
    "land": "land",
    "creature": "unknown",
}

_RULE_CACHE: dict[str, tuple[int | None, dict[str, dict[str, Any]]]] = {}
_RULE_LIST_CACHE: dict[str, tuple[int | None, dict[str, list[dict[str, Any]]]]] = {}


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


def _create_battle_card_rules_table(
    conn: sqlite3.Connection,
    table_name: str = "battle_card_rules",
) -> None:
    conn.execute(
        f"""
        CREATE TABLE IF NOT EXISTS {table_name} (
            normalized_name TEXT NOT NULL,
            logical_rule_key TEXT NOT NULL,
            card_name TEXT NOT NULL,
            effect_json TEXT NOT NULL DEFAULT '{{}}',
            deck_role_json TEXT NOT NULL DEFAULT '{{}}',
            source TEXT NOT NULL DEFAULT 'curated',
            confidence REAL NOT NULL DEFAULT 1.0,
            review_status TEXT NOT NULL DEFAULT 'verified',
            execution_status TEXT NOT NULL DEFAULT 'auto',
            rule_version INTEGER NOT NULL DEFAULT 1,
            oracle_hash TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            last_seen_at TEXT,
            PRIMARY KEY (normalized_name, logical_rule_key)
        )
        """
    )


def _battle_rule_table_columns(conn: sqlite3.Connection) -> dict[str, dict[str, Any]]:
    rows = conn.execute("PRAGMA table_info(battle_card_rules)").fetchall()
    return {
        str(row[1]): {
            "cid": row[0],
            "type": row[2],
            "notnull": row[3],
            "default": row[4],
            "pk": row[5],
        }
        for row in rows
    }


def _migrate_battle_card_rules_schema(conn: sqlite3.Connection) -> None:
    if not table_exists(conn, "battle_card_rules"):
        _create_battle_card_rules_table(conn)
        return

    columns = _battle_rule_table_columns(conn)
    if "execution_status" not in columns:
        conn.execute(
            """
            ALTER TABLE battle_card_rules
            ADD COLUMN execution_status TEXT NOT NULL DEFAULT 'auto'
            """
        )
        conn.execute(
            """
            UPDATE battle_card_rules
            SET execution_status = CASE
                WHEN review_status IN ('rejected', 'deprecated') THEN 'disabled'
                WHEN review_status = 'needs_review' THEN 'review_only'
                ELSE 'auto'
            END
            WHERE execution_status IS NULL OR execution_status = ''
            """
        )
        columns = _battle_rule_table_columns(conn)
    pk_columns = [
        name
        for name, meta in sorted(columns.items(), key=lambda item: int(item[1]["pk"] or 0))
        if int(meta["pk"] or 0) > 0
    ]
    if "logical_rule_key" in columns and pk_columns == [
        "normalized_name",
        "logical_rule_key",
    ]:
        return

    conn.execute("DROP TABLE IF EXISTS battle_card_rules_v2_migration")
    _create_battle_card_rules_table(conn, "battle_card_rules_v2_migration")
    existing_rows = conn.execute(
        """
        SELECT normalized_name, card_name, effect_json, deck_role_json, source,
               confidence, review_status, execution_status, rule_version, oracle_hash, notes,
               created_at, updated_at, last_seen_at
        FROM battle_card_rules
        """
    ).fetchall()
    for row in existing_rows:
        effect_json = _safe_json_loads(row[2])
        deck_role_json = _safe_json_loads(row[3])
        logical_key = logical_rule_key(
            {
                "effect_json": effect_json,
                "deck_role_json": deck_role_json,
            }
        )
        conn.execute(
            """
            INSERT OR REPLACE INTO battle_card_rules_v2_migration (
                normalized_name, logical_rule_key, card_name, effect_json,
                deck_role_json, source, confidence, review_status, execution_status, rule_version,
                oracle_hash, notes, created_at, updated_at, last_seen_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                row[0],
                logical_key,
                row[1],
                row[2],
                row[3],
                row[4],
                row[5],
                row[6],
                row[7],
                row[8],
                row[9],
                row[10],
                row[11],
                row[12],
                row[13],
            ),
        )
    conn.execute("DROP TABLE battle_card_rules")
    conn.execute("ALTER TABLE battle_card_rules_v2_migration RENAME TO battle_card_rules")


def ensure_battle_card_rules(conn: sqlite3.Connection) -> None:
    _migrate_battle_card_rules_schema(conn)
    conn.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_battle_card_rules_normalized_name
        ON battle_card_rules(normalized_name)
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
    if effect_json.get("activated_effect") == "untap_target":
        target = str(effect_json.get("activated_untap_target") or effect_json.get("target") or "")
        if target in {"land", "forest_land", "gate_land", "snow_land"}:
            category = "ramp"
            subtype = "land_untap"
        else:
            category = "support"
            subtype = "permanent_untap"
    elif effect == "creature" and effect_json.get("is_mana_source"):
        category = "ramp"
        subtype = "mana_dork"
    elif effect == "creature" and (
        effect_json.get("graveyard_self_return_to_hand")
        or effect_json.get("graveyard_self_return_to_battlefield")
    ):
        category = "engine"
        subtype = "recursive_threat"
    elif (
        effect == "creature"
        and effect_json.get("battle_model_scope")
        == "creature_body_target_permanent_protection_from_white_make_source_white_activation_runtime_v1"
    ):
        category = "protection"
        subtype = "activated_targeted_protection_response"
    elif effect_json.get("activated_effect") == "graveyard_exile":
        category = "removal"
        subtype = "graveyard_hate"
    elif effect == "topdeck_play":
        if effect_json.get("play_lands_from_top_library"):
            category = "ramp"
            subtype = "play_lands_from_library"
        elif effect_json.get("look_top_library_any_time"):
            category = "draw"
            subtype = "topdeck_visibility"
    elif effect == "add_counters":
        counter_type = str(effect_json.get("counter_type") or "")
        if counter_type == "-1/-1":
            category = "removal"
            subtype = "negative_counters"
        elif counter_type == "+1/+1":
            subtype = "plus_one_counters"
    elif effect == "untap_target":
        target = str(effect_json.get("activated_untap_target") or effect_json.get("target") or "")
        if target in {"land", "forest_land", "gate_land", "snow_land"}:
            category = "ramp"
            subtype = "land_untap"
        else:
            category = "support"
            subtype = "permanent_untap"
    elif effect == "mill_cards":
        subtype = "library_mill"
    elif effect in {"stat_modifier_until_eot", "stat_modifier_until_eot_untap_target"}:
        power_delta = int(effect_json.get("power_delta") or effect_json.get("power_boost") or 0)
        toughness_delta = int(effect_json.get("toughness_delta") or effect_json.get("toughness_boost") or 0)
        if toughness_delta < 0 or (power_delta < 0 and toughness_delta <= 0):
            category = "removal"
            subtype = "temporary_debuff"
        else:
            subtype = "temporary_pump_untap" if effect == "stat_modifier_until_eot_untap_target" else "temporary_pump"
    elif effect == "aura_static_attachment":
        power_delta = int(effect_json.get("power_boost") or effect_json.get("static_power_bonus") or 0)
        toughness_delta = int(effect_json.get("toughness_boost") or effect_json.get("static_toughness_bonus") or 0)
        if toughness_delta < 0 or (power_delta < 0 and toughness_delta <= 0):
            category = "removal"
            subtype = "aura_debuff"
        else:
            category = "support"
            subtype = "aura_static_pump"
    elif effect == "equipment_static_attachment":
        category = "support"
        subtype = "equipment_static_pump"
    elif effect == "composite_resolution":
        components = effect_json.get("_composite_rule_components") or []
        component_effects = {
            str(component.get("effect") or "")
            for component in components
            if isinstance(component, dict)
        }
        if component_effects == {"token_maker"}:
            category = "wincon"
            subtype = "token_suite"
        elif component_effects == {"direct_damage", "target_player_discard"}:
            category = "removal"
            subtype = "damage_discard"
        elif "ramp_ritual" in component_effects and component_effects.intersection(
            {"remove_creature", "remove_permanent"}
        ):
            category = "removal"
            subtype = "removal_mana_ritual"
    elif effect == "static_global_power_toughness_boost":
        power_delta = int(effect_json.get("static_power_bonus") or effect_json.get("power_boost") or 0)
        toughness_delta = int(effect_json.get("static_toughness_bonus") or effect_json.get("toughness_boost") or 0)
        if toughness_delta < 0 or (power_delta < 0 and toughness_delta <= 0):
            category = "removal"
            subtype = "static_global_debuff"
        else:
            category = "support"
            subtype = "static_global_pump"
    elif effect == "graveyard_exile":
        subtype = "graveyard_hate"
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


def _rule_rank(rule: dict[str, Any]) -> tuple[int, int, int, float, int, str]:
    return (
        REVIEW_STATUS_PRIORITY.get(str(rule.get("review_status") or "").lower(), 7),
        EXECUTION_STATUS_PRIORITY.get(str(rule.get("execution_status") or "").lower(), 9),
        -SOURCE_PRIORITY.get(str(rule.get("source") or "").lower(), 0),
        -float(rule.get("confidence") or 0.0),
        -int(rule.get("rule_version") or 1),
        str(rule.get("logical_rule_key") or ""),
    )


def _is_runtime_safe_rule(rule: dict[str, Any]) -> bool:
    review_status = str(rule.get("review_status") or "").lower()
    execution_status = str(rule.get("execution_status") or "auto").lower()
    return (
        review_status in {"verified", "active"}
        and execution_status in {"auto", "executable"}
    )


def _db_mtime(db_path: Path) -> int | None:
    try:
        return int(db_path.stat().st_mtime_ns)
    except OSError:
        return None


def _invalidate_rule_caches_for_connection(conn: sqlite3.Connection) -> None:
    # Upserts are rare and rule correctness is more important than keeping a
    # small in-process cache warm. SQLite temp paths can differ by spelling
    # between `PRAGMA database_list` and caller-provided paths, so clear both
    # caches globally instead of risking stale multi-rule reads.
    _RULE_CACHE.clear()
    _RULE_LIST_CACHE.clear()


def _rule_cache_key(
    db_path: Path,
    *,
    include_review_only: bool,
    runtime_safe_only: bool,
) -> str:
    return (
        f"{db_path}|include_review_only={int(include_review_only)}|"
        f"runtime_safe_only={int(runtime_safe_only)}"
    )


def _load_active_battle_card_rule_lists_cached(
    db_path: str | Path = DEFAULT_DB,
    *,
    include_review_only: bool = True,
    runtime_safe_only: bool = False,
) -> tuple[int | None, dict[str, list[dict[str, Any]]]]:
    path = Path(db_path)
    mtime = _db_mtime(path)
    cache_key = _rule_cache_key(
        path,
        include_review_only=include_review_only,
        runtime_safe_only=runtime_safe_only,
    )
    cached = _RULE_LIST_CACHE.get(cache_key)
    if cached and cached[0] == mtime:
        return cached
    if not path.exists():
        _RULE_LIST_CACHE[cache_key] = (mtime, {})
        return mtime, {}

    try:
        with closing(sqlite3.connect(path)) as conn:
            conn.row_factory = sqlite3.Row
            if not table_exists(conn, "battle_card_rules"):
                _RULE_LIST_CACHE[cache_key] = (mtime, {})
                return mtime, {}
            rows = conn.execute(
                """
                SELECT normalized_name, logical_rule_key, card_name, effect_json, deck_role_json,
                       source, confidence, review_status, execution_status, rule_version, oracle_hash, notes
                FROM battle_card_rules
                WHERE review_status IN ('verified', 'needs_review', 'active')
                  AND execution_status != 'disabled'
                """
            ).fetchall()
    except sqlite3.Error:
        _RULE_LIST_CACHE[cache_key] = (mtime, {})
        return mtime, {}

    rules: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        effect_json = _safe_json_loads(row["effect_json"])
        deck_role_json = _safe_json_loads(row["deck_role_json"])
        rule = {
            "normalized_name": row["normalized_name"],
            "logical_rule_key": row["logical_rule_key"],
            "card_name": row["card_name"],
            "effect_json": effect_json,
            "deck_role_json": deck_role_json,
            "source": row["source"],
            "confidence": row["confidence"],
            "review_status": row["review_status"],
            "execution_status": row["execution_status"],
            "rule_version": row["rule_version"],
            "oracle_hash": row["oracle_hash"],
            "notes": row["notes"],
        }
        if runtime_safe_only and not _is_runtime_safe_rule(rule):
            continue
        if not include_review_only and not _is_runtime_safe_rule(rule):
            continue
        rules.setdefault(row["normalized_name"], []).append(rule)

    for values in rules.values():
        values.sort(key=_rule_rank)

    _RULE_LIST_CACHE[cache_key] = (mtime, rules)
    return mtime, rules


def load_active_battle_card_rule_lists(
    db_path: str | Path = DEFAULT_DB,
    *,
    include_review_only: bool = True,
    runtime_safe_only: bool = False,
) -> dict[str, list[dict[str, Any]]]:
    _mtime, rules = _load_active_battle_card_rule_lists_cached(
        db_path,
        include_review_only=include_review_only,
        runtime_safe_only=runtime_safe_only,
    )
    return {
        key: [dict(rule) for rule in value]
        for key, value in rules.items()
    }


def load_active_battle_card_rules(
    db_path: str | Path = DEFAULT_DB,
    *,
    include_review_only: bool = True,
    runtime_safe_only: bool = False,
) -> dict[str, dict[str, Any]]:
    path = Path(db_path)
    mtime = _db_mtime(path)
    cache_key = _rule_cache_key(
        path,
        include_review_only=include_review_only,
        runtime_safe_only=runtime_safe_only,
    )
    cached = _RULE_CACHE.get(cache_key)
    if cached and cached[0] == mtime:
        return {key: dict(value) for key, value in cached[1].items()}

    _mtime, rule_lists = _load_active_battle_card_rule_lists_cached(
        path,
        include_review_only=include_review_only,
        runtime_safe_only=runtime_safe_only,
    )
    rules = {
        normalized_name: values[0]
        for normalized_name, values in rule_lists.items()
        if values
    }
    _RULE_CACHE[cache_key] = (mtime, rules)
    return {key: dict(value) for key, value in rules.items()}


def lookup_battle_card_rule(
    db_path: str | Path,
    card_name: str,
    *,
    include_review_only: bool = True,
    runtime_safe_only: bool = False,
) -> dict[str, Any] | None:
    path = Path(db_path)
    mtime = _db_mtime(path)
    cache_key = _rule_cache_key(
        path,
        include_review_only=include_review_only,
        runtime_safe_only=runtime_safe_only,
    )
    cached = _RULE_CACHE.get(cache_key)
    if not cached or cached[0] != mtime:
        load_active_battle_card_rules(
            path,
            include_review_only=include_review_only,
            runtime_safe_only=runtime_safe_only,
        )
        cached = _RULE_CACHE.get(cache_key)
    rules = cached[1] if cached else {}
    normalized_names = [normalize_card_name(card_name)]
    if " // " in str(card_name):
        front_face = normalize_card_name(str(card_name).split(" // ", 1)[0])
        if front_face and front_face not in normalized_names:
            normalized_names.append(front_face)
    for normalized in normalized_names:
        rule = rules.get(normalized)
        if rule:
            return dict(rule)
    rule = None
    for normalized in normalized_names:
        face_prefix = f"{normalized} //"
        rule = next(
            (value for key, value in rules.items() if key.startswith(face_prefix)),
            None,
        )
        if rule:
            break
    return dict(rule) if rule else None


def lookup_battle_card_rule_list(
    db_path: str | Path,
    card_name: str,
    *,
    include_review_only: bool = True,
    runtime_safe_only: bool = False,
) -> list[dict[str, Any]]:
    _mtime, rules = _load_active_battle_card_rule_lists_cached(
        db_path,
        include_review_only=include_review_only,
        runtime_safe_only=runtime_safe_only,
    )
    normalized_names = [normalize_card_name(card_name)]
    if " // " in str(card_name):
        front_face = normalize_card_name(str(card_name).split(" // ", 1)[0])
        if front_face and front_face not in normalized_names:
            normalized_names.append(front_face)
    for normalized in normalized_names:
        values = rules.get(normalized)
        if values:
            return [dict(rule) for rule in values]
    matches: list[dict[str, Any]] = []
    for normalized in normalized_names:
        face_prefix = f"{normalized} //"
        for key, value in rules.items():
            if key.startswith(face_prefix):
                matches.extend(dict(rule) for rule in value)
    matches.sort(key=_rule_rank)
    return matches


def upsert_battle_card_rule(
    conn: sqlite3.Connection,
    card_name: str,
    effect_json: dict[str, Any],
    *,
    normalized_name_value: str | None = None,
    source: str,
    confidence: float,
    review_status: str,
    execution_status: str = "auto",
    deck_role_json: dict[str, Any] | None = None,
    notes: str = "",
    oracle_hash: str | None = None,
    logical_rule_key_value: str | None = None,
    rule_version: int = 1,
) -> bool:
    ensure_battle_card_rules(conn)
    normalized = normalize_card_name(normalized_name_value or card_name)
    now = utc_now()
    role = deck_role_json or deck_role_from_effect(effect_json)
    normalized_rule_version = max(1, int(rule_version or 1))
    rule_key = str(logical_rule_key_value or "") or logical_rule_key(
        {
            "effect_json": effect_json,
            "deck_role_json": role,
        }
    )
    current = conn.execute(
        """
        SELECT source FROM battle_card_rules
        WHERE normalized_name=? AND logical_rule_key=?
        """,
        (normalized, rule_key),
    ).fetchone()
    if current:
        incoming_priority = SOURCE_PRIORITY.get(source, 0)
        current_priority = SOURCE_PRIORITY.get(str(current[0]), 0)
        if incoming_priority < current_priority:
            conn.execute(
                """
                UPDATE battle_card_rules
                SET
                    oracle_hash=COALESCE(
                        NULLIF(oracle_hash, ''),
                        NULLIF(?, '')
                    ),
                    last_seen_at=?
                WHERE normalized_name=? AND logical_rule_key=?
                """,
                (oracle_hash, now, normalized, rule_key),
            )
            _invalidate_rule_caches_for_connection(conn)
            return False

    conn.execute(
        """
        INSERT INTO battle_card_rules (
            normalized_name, logical_rule_key, card_name, effect_json,
            deck_role_json, source, confidence, review_status, execution_status, rule_version,
            oracle_hash, notes,
            created_at, updated_at, last_seen_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(normalized_name, logical_rule_key) DO UPDATE SET
            card_name=excluded.card_name,
            effect_json=excluded.effect_json,
            deck_role_json=excluded.deck_role_json,
            source=excluded.source,
            confidence=excluded.confidence,
            review_status=excluded.review_status,
            execution_status=excluded.execution_status,
            rule_version=excluded.rule_version,
            oracle_hash=COALESCE(
                NULLIF(excluded.oracle_hash, ''),
                battle_card_rules.oracle_hash
            ),
            notes=excluded.notes,
            updated_at=excluded.updated_at,
            last_seen_at=excluded.last_seen_at
        """,
        (
            normalized,
            rule_key,
            card_name,
            json.dumps(effect_json, ensure_ascii=True, sort_keys=True),
            json.dumps(role, ensure_ascii=True, sort_keys=True),
            source,
            confidence,
            review_status,
            execution_status,
            normalized_rule_version,
            oracle_hash,
            notes,
            now,
            now,
            now,
        ),
    )
    _invalidate_rule_caches_for_connection(conn)
    return True
