#!/usr/bin/env python3
"""Sync one real PostgreSQL deck into Hermes SQLite `deck_cards`.

Hermes battle tooling expects a local SQLite target deck, traditionally
`deck_id=6`. This script makes a dev/runtime knowledge.db usable by importing a
real ManaLoom deck from Postgres instead of relying on old local artifacts.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from db_helper import connect, sanitized_database_target


DEFAULT_SQLITE_DB = Path(
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
)

ROLE_TO_TAG = {
    "board_wipe": "board_wipe",
    "draw": "draw",
    "engine": "engine",
    "land": "land",
    "protection": "protection",
    "ramp": "ramp",
    "removal": "removal",
    "tutor": "tutor",
    "unknown": "unknown",
    "wincon": "wincon",
    "wipe": "board_wipe",
}

TAG_PRIORITY = {
    "board_wipe": 10,
    "wipe": 10,
    "wincon": 20,
    "combo_piece": 30,
    "engine": 40,
    "draw": 50,
    "removal": 60,
    "ramp": 70,
    "tutor": 80,
    "protection": 90,
    "recursion": 100,
    "token_maker": 110,
    "enabler": 120,
    "stax": 130,
    "payoff": 135,
    "mana_fixing": 140,
    "card_selection": 150,
    "land": 900,
    "creature": 910,
    "artifact": 920,
    "enchantment": 930,
    "planeswalker": 940,
    "utility": 950,
    "unknown": 999,
}

REVIEW_STATUS_PRIORITY = {
    "verified": 0,
    "active": 1,
    "needs_review": 2,
    "rejected": 8,
    "deprecated": 9,
}

SOURCE_PRIORITY = {
    "manual": 0,
    "curated": 1,
    "generated": 4,
    "imported": 5,
    "heuristic": 6,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Cache one PG deck into Hermes SQLite deck_cards."
    )
    parser.add_argument("--sqlite-db", default=str(DEFAULT_SQLITE_DB))
    parser.add_argument("--pg-deck-id", default=os.environ.get("MANALOOM_TARGET_PG_DECK_ID", ""))
    parser.add_argument(
        "--deck-name-like",
        default=os.environ.get("MANALOOM_TARGET_DECK_NAME_LIKE", "%Runtime Lorehold Learned%"),
    )
    parser.add_argument("--target-deck-id", type=int, default=6)
    parser.add_argument("--min-total-cards", type=int, default=90)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--report")
    return parser.parse_args()


def normalize_tag(value: str | None) -> str:
    text = (value or "unknown").strip().lower()
    return ROLE_TO_TAG.get(text, text or "unknown")


def parse_json_value(value: Any, fallback: Any) -> Any:
    if value is None:
        return fallback
    if isinstance(value, (dict, list)):
        return value
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return fallback
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return fallback
    return fallback


def stable_json(value: Any) -> str:
    return json.dumps(
        value,
        ensure_ascii=True,
        separators=(",", ":"),
        sort_keys=True,
    )


def stable_json_text(value: Any, fallback: Any) -> str:
    return stable_json(parse_json_value(value, fallback))


def _first_present(*values: Any) -> Any:
    for value in values:
        if value not in (None, "", [], {}):
            return value
    return None


def logical_rule_key(rule: dict[str, Any]) -> str:
    """Return a stable key for equivalent battle rules.

    The key intentionally excludes provenance/review metadata. Two rows that
    encode the same face/variant/effect/deck role should collapse to the best
    reviewed exemplar while still preserving all unique executable semantics.
    """
    effect = parse_json_value(rule.get("effect"), {})
    deck_role = parse_json_value(rule.get("deck_role"), {})
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


def _rule_rank(rule: dict[str, Any]) -> tuple[Any, ...]:
    review_status = str(rule.get("review_status") or "").lower()
    source = str(rule.get("source") or "").lower()
    confidence = float(rule.get("confidence") or 0.0)
    rule_version = int(rule.get("rule_version") or 0)
    return (
        REVIEW_STATUS_PRIORITY.get(review_status, 7),
        SOURCE_PRIORITY.get(source, 7),
        -confidence,
        -rule_version,
        stable_json(rule),
    )


def normalize_battle_rules(value: Any) -> list[dict[str, Any]]:
    """Normalize and dedupe battle rules without collapsing distinct behavior."""
    raw_rules = parse_json_value(value, [])
    if not isinstance(raw_rules, list):
        return []
    selected: dict[str, dict[str, Any]] = {}
    for item in raw_rules:
        if not isinstance(item, dict):
            continue
        rule = dict(item)
        key = str(rule.get("logical_rule_key") or logical_rule_key(rule))
        rule["logical_rule_key"] = key
        current = selected.get(key)
        if current is None or _rule_rank(rule) < _rule_rank(current):
            selected[key] = rule
    return sorted(
        selected.values(),
        key=lambda rule: (
            REVIEW_STATUS_PRIORITY.get(str(rule.get("review_status") or "").lower(), 7),
            SOURCE_PRIORITY.get(str(rule.get("source") or "").lower(), 7),
            str(rule.get("logical_rule_key") or ""),
        ),
    )


def normalize_functional_tags(value: Any, fallback_tag: str | None = None) -> list[str]:
    raw_tags = parse_json_value(value, [])
    tags: set[str] = set()
    if isinstance(raw_tags, list):
        for item in raw_tags:
            tag: str | None
            if isinstance(item, dict):
                tag = item.get("tag") or item.get("role")
            else:
                tag = str(item)
            normalized = normalize_tag(tag)
            if normalized != "unknown":
                tags.add(normalized)
    fallback = normalize_tag(fallback_tag)
    if not tags and fallback != "unknown":
        tags.add(fallback)
    return sorted(tags, key=lambda tag: (TAG_PRIORITY.get(tag, 500), tag))


def primary_functional_tag(tags: list[str], fallback: str | None = None) -> str:
    if tags:
        return tags[0]
    return normalize_tag(fallback)


def infer_tag(row: dict[str, Any]) -> str:
    role = row.get("battle_role")
    if isinstance(role, dict):
        tag = normalize_tag(role.get("category"))
        if tag != "unknown":
            return tag
    effect = str(row.get("battle_effect") or "").lower()
    if effect in {"remove_creature", "remove_permanent", "remove_artifact_or_3dmg"}:
        return "removal"
    if effect in {"board_wipe", "damage_wipe"}:
        return "board_wipe"
    if effect.startswith("ramp"):
        return "ramp"
    if effect in {"draw_cards", "draw_engine", "loot", "topdeck_manipulation"}:
        return "draw"
    if effect in {"phase_out", "indestructible", "modal_boros_charm", "silence_opponents"}:
        return "protection"
    if effect in {"approach", "finisher", "token_maker", "steal_all_creatures"}:
        return "wincon"
    if effect == "tutor":
        return "tutor"
    type_line = str(row.get("type_line") or "").lower()
    oracle = str(row.get("oracle_text") or "").lower()
    if "land" in type_line:
        return "land"
    if "destroy target" in oracle or "exile target" in oracle:
        return "removal"
    if "draw" in oracle:
        return "draw"
    if "add " in oracle and "mana" in oracle:
        return "ramp"
    if "creature" in type_line:
        return "creature"
    return "unknown"


def ensure_sqlite_schema(cur: sqlite3.Cursor) -> None:
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS decks (
            id INTEGER PRIMARY KEY,
            deck_name TEXT,
            archetype TEXT,
            total_cards INTEGER DEFAULT 100,
            notes TEXT
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS deck_cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER,
            card_id TEXT,
            card_name TEXT NOT NULL,
            quantity INTEGER DEFAULT 1,
            functional_tag TEXT,
            functional_tags_json TEXT DEFAULT '[]',
            semantic_tags_v2_json TEXT DEFAULT '[]',
            battle_rules_json TEXT DEFAULT '[]',
            deck_hash TEXT,
            semantics_hash TEXT,
            ruleset_hash TEXT,
            sync_run_id TEXT,
            tag_confidence REAL,
            is_commander INTEGER DEFAULT 0,
            is_partner INTEGER DEFAULT 0,
            cmc REAL,
            type_line TEXT,
            oracle_text TEXT,
            UNIQUE(deck_id, card_id),
            UNIQUE(deck_id, card_name)
        )
        """
    )
    _ensure_columns(
        cur,
        "deck_cards",
        {
            "card_id": "TEXT",
            "functional_tags_json": "TEXT DEFAULT '[]'",
            "semantic_tags_v2_json": "TEXT DEFAULT '[]'",
            "battle_rules_json": "TEXT DEFAULT '[]'",
            "deck_hash": "TEXT",
            "semantics_hash": "TEXT",
            "ruleset_hash": "TEXT",
            "sync_run_id": "TEXT",
        },
    )


def _ensure_columns(
    cur: sqlite3.Cursor,
    table_name: str,
    columns: dict[str, str],
) -> None:
    existing = {row[1] for row in cur.execute(f"PRAGMA table_info({table_name})")}
    for column, definition in columns.items():
        if column not in existing:
            cur.execute(f"ALTER TABLE {table_name} ADD COLUMN {column} {definition}")


def normalize_snapshot_cards(cards: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Validate and normalize a one-row-per-card semantic snapshot."""
    aggregated: dict[str, dict[str, Any]] = {}
    names: dict[str, str] = {}
    for card in cards:
        card_id = str(card.get("card_id") or "").strip()
        if not card_id:
            raise RuntimeError(
                "Semantic snapshot card is missing card_id. Refusing to write "
                "a Hermes deck snapshot keyed only by card name."
            )
        name = str(card.get("name") or "").strip()
        if not name:
            continue
        key = card_id.lower()
        name_key = name.casefold()
        if key in aggregated:
            raise RuntimeError(
                "Semantic snapshot contains duplicate card_id rows before "
                f"SQLite write: card_id={card_id}. This usually means a join "
                "multiplied deck card rows."
            )
        existing_name_id = names.get(name_key)
        if existing_name_id and existing_name_id != key:
            raise RuntimeError(
                "Semantic snapshot contains duplicate card names with distinct "
                f"card_id values: card_name={name}. Commander singleton "
                "identity must be resolved before syncing Hermes."
            )

        tags = normalize_functional_tags(
            card.get("functional_tags_json"),
            card.get("functional_tag"),
        )
        inferred_tag = infer_tag(card)
        if not tags and inferred_tag != "unknown":
            tags = [inferred_tag]

        normalized = dict(card)
        normalized["card_id"] = card_id
        normalized["name"] = name
        normalized["quantity"] = int(card.get("quantity") or 1)
        normalized["is_commander"] = bool(card.get("is_commander"))
        normalized["functional_tags"] = tags
        normalized["functional_tag"] = primary_functional_tag(tags, inferred_tag)
        normalized["functional_tags_json"] = stable_json(tags)
        normalized["semantic_tags_v2_json"] = stable_json_text(
            card.get("semantic_tags_v2_json"),
            [],
        )
        battle_rules = normalize_battle_rules(card.get("battle_rules_json"))
        normalized["battle_rules"] = battle_rules
        normalized["battle_rules_json"] = stable_json(battle_rules)
        aggregated[key] = normalized
        names[name_key] = key

    return sorted(
        aggregated.values(),
        key=lambda card: (not bool(card.get("is_commander")), str(card.get("name") or "")),
    )


def semantic_deck_cards_sql() -> str:
    """Return one row per card with aggregated semantic arrays.

    Every 1:N semantic source is aggregated before joining back to `deck_cards`.
    This preserves `deck_cards.quantity` as the only deck cardinality source.
    """
    return """
                WITH base_deck AS (
                  SELECT
                    dc.deck_id,
                    c.id AS card_uuid,
                    c.id::text AS card_id,
                    c.name,
                    SUM(dc.quantity)::int AS quantity,
                    BOOL_OR(dc.is_commander) AS is_commander,
                    MAX(c.cmc)::float AS cmc,
                    MAX(c.type_line) AS type_line,
                    MAX(c.oracle_text) AS oracle_text
                  FROM deck_cards dc
                  JOIN cards c ON c.id = dc.card_id
                  WHERE dc.deck_id = %s
                  GROUP BY dc.deck_id, c.id, c.name
                ),
                function_tags_raw AS (
                  SELECT
                    cft.card_id,
                    CASE LOWER(cft.tag)
                      WHEN 'wipe' THEN 'board_wipe'
                      ELSE LOWER(cft.tag)
                    END AS tag,
                    MAX(cft.confidence) AS confidence
                  FROM card_function_tags cft
                  JOIN base_deck bd ON bd.card_uuid = cft.card_id
                  WHERE LOWER(cft.tag) <> 'unknown'
                  GROUP BY cft.card_id, CASE LOWER(cft.tag)
                    WHEN 'wipe' THEN 'board_wipe'
                    ELSE LOWER(cft.tag)
                  END
                ),
                function_tags_agg AS (
                  SELECT
                    ftr.card_id,
                    COALESCE(
                      jsonb_agg(
                        ftr.tag
                        ORDER BY
                          CASE ftr.tag
                            WHEN 'board_wipe' THEN 10
                            WHEN 'wincon' THEN 20
                            WHEN 'combo_piece' THEN 30
                            WHEN 'engine' THEN 40
                            WHEN 'draw' THEN 50
                            WHEN 'removal' THEN 60
                            WHEN 'ramp' THEN 70
                            WHEN 'tutor' THEN 80
                            WHEN 'protection' THEN 90
                            WHEN 'recursion' THEN 100
                            WHEN 'token_maker' THEN 110
                            WHEN 'enabler' THEN 120
                            WHEN 'stax' THEN 130
                            WHEN 'payoff' THEN 135
                            WHEN 'mana_fixing' THEN 140
                            WHEN 'card_selection' THEN 150
                            WHEN 'land' THEN 900
                            WHEN 'creature' THEN 910
                            WHEN 'artifact' THEN 920
                            WHEN 'enchantment' THEN 930
                            WHEN 'planeswalker' THEN 940
                            ELSE 950
                          END,
                          ftr.confidence DESC NULLS LAST,
                          ftr.tag
                      ),
                      '[]'::jsonb
                    ) AS functional_tags_json,
                    (ARRAY_AGG(
                      ftr.tag
                      ORDER BY
                        CASE ftr.tag
                          WHEN 'board_wipe' THEN 10
                          WHEN 'wincon' THEN 20
                          WHEN 'combo_piece' THEN 30
                          WHEN 'engine' THEN 40
                          WHEN 'draw' THEN 50
                          WHEN 'removal' THEN 60
                          WHEN 'ramp' THEN 70
                          WHEN 'tutor' THEN 80
                          WHEN 'protection' THEN 90
                          WHEN 'recursion' THEN 100
                          WHEN 'token_maker' THEN 110
                          WHEN 'enabler' THEN 120
                          WHEN 'stax' THEN 130
                          WHEN 'payoff' THEN 135
                          WHEN 'mana_fixing' THEN 140
                          WHEN 'card_selection' THEN 150
                          WHEN 'land' THEN 900
                          WHEN 'creature' THEN 910
                          WHEN 'artifact' THEN 920
                          WHEN 'enchantment' THEN 930
                          WHEN 'planeswalker' THEN 940
                          ELSE 950
                        END,
                        ftr.confidence DESC NULLS LAST,
                        ftr.tag
                    ))[1] AS functional_tag,
                    MAX(ftr.confidence) AS tag_confidence
                  FROM function_tags_raw ftr
                  GROUP BY ftr.card_id
                ),
                semantic_tags_v2_agg AS (
                  SELECT
                    cstv2.card_id,
                    COALESCE(
                      jsonb_agg(
                        jsonb_strip_nulls(jsonb_build_object(
                          'schema_version', cstv2.schema_version,
                          'speed', cstv2.speed,
                          'mana_efficiency', cstv2.mana_efficiency,
                          'card_advantage_type', cstv2.card_advantage_type,
                          'interaction_scope', cstv2.interaction_scope,
                          'combo_piece', cstv2.combo_piece,
                          'wincon', cstv2.wincon,
                          'engine', cstv2.engine,
                          'payoff', cstv2.payoff,
                          'enabler', cstv2.enabler,
                          'protection_type', cstv2.protection_type,
                          'recursion_type', cstv2.recursion_type,
                          'role_confidence', cstv2.role_confidence,
                          'tags', cstv2.tags,
                          'source', cstv2.source
                        ))
                        ORDER BY
                          cstv2.schema_version,
                          cstv2.source,
                          cstv2.role_confidence DESC NULLS LAST
                      ),
                      '[]'::jsonb
                    ) AS semantic_tags_v2_json
                  FROM card_semantic_tags_v2 cstv2
                  JOIN base_deck bd ON bd.card_uuid = cstv2.card_id
                  GROUP BY cstv2.card_id
                ),
                battle_rules_agg AS (
                  SELECT
                    cbr.card_id,
                    COALESCE(
                      jsonb_agg(
                        jsonb_strip_nulls(jsonb_build_object(
                          'logical_rule_key', cbr.logical_rule_key,
                          'rule_version', cbr.rule_version,
                          'source', cbr.source,
                          'review_status', cbr.review_status,
                          'confidence', cbr.confidence,
                          'effect', cbr.effect_json,
                          'deck_role', cbr.deck_role_json,
                          'oracle_hash', cbr.oracle_hash
                        ))
                        ORDER BY
                          CASE cbr.review_status
                            WHEN 'verified' THEN 1
                            WHEN 'active' THEN 2
                            WHEN 'needs_review' THEN 3
                            ELSE 9
                          END,
                          cbr.confidence DESC NULLS LAST,
                          cbr.rule_version DESC,
                          cbr.source,
                          md5(
                            COALESCE(cbr.effect_json::text, '') ||
                            COALESCE(cbr.deck_role_json::text, '') ||
                            COALESCE(cbr.oracle_hash, '')
                          )
                      ),
                      '[]'::jsonb
                    ) AS battle_rules_json
                  FROM card_battle_rules cbr
                  JOIN base_deck bd ON bd.card_uuid = cbr.card_id
                  WHERE cbr.review_status NOT IN ('rejected', 'deprecated')
                  GROUP BY cbr.card_id
                )
                SELECT
                  bd.name,
                  bd.quantity,
                  bd.is_commander,
                  bd.cmc,
                  bd.type_line,
                  bd.oracle_text,
                  bd.card_id,
                  COALESCE(fta.functional_tags_json, '[]'::jsonb) AS functional_tags_json,
                  fta.functional_tag,
                  COALESCE(fta.tag_confidence, 0.0) AS tag_confidence,
                  COALESCE(stv2.semantic_tags_v2_json, '[]'::jsonb) AS semantic_tags_v2_json,
                  COALESCE(bra.battle_rules_json, '[]'::jsonb) AS battle_rules_json
                FROM base_deck bd
                LEFT JOIN function_tags_agg fta ON fta.card_id = bd.card_uuid
                LEFT JOIN semantic_tags_v2_agg stv2 ON stv2.card_id = bd.card_uuid
                LEFT JOIN battle_rules_agg bra ON bra.card_id = bd.card_uuid
                ORDER BY bd.is_commander DESC, bd.name, bd.card_id
    """


def semantic_deck_cards_snapshot_sql() -> str:
    """Return one row per card from the backend-owned aggregate snapshot."""
    return """
                SELECT
                  cis.name,
                  SUM(dc.quantity)::int AS quantity,
                  BOOL_OR(dc.is_commander) AS is_commander,
                  MAX(cis.cmc)::float AS cmc,
                  MAX(cis.type_line) AS type_line,
                  MAX(cis.oracle_text) AS oracle_text,
                  cis.card_id::text AS card_id,
                  to_jsonb(COALESCE(cis.function_tags, ARRAY[]::TEXT[]))
                    AS functional_tags_json,
                  NULL::text AS functional_tag,
                  COALESCE(cis.max_function_tag_confidence, 0.0)
                    AS tag_confidence,
                  COALESCE(cis.semantic_tags_v2, '[]'::jsonb)
                    AS semantic_tags_v2_json,
                  COALESCE(cis.battle_rules, '[]'::jsonb)
                    AS battle_rules_json
                FROM deck_cards dc
                JOIN card_intelligence_snapshot cis ON cis.id = dc.card_id
                WHERE dc.deck_id = %s
                GROUP BY
                  cis.id,
                  cis.card_id,
                  cis.name,
                  cis.function_tags,
                  cis.max_function_tag_confidence,
                  cis.semantic_tags_v2,
                  cis.battle_rules
                ORDER BY BOOL_OR(dc.is_commander) DESC, cis.name, cis.card_id
    """


def has_pg_relation(cur: Any, relation_name: str) -> bool:
    cur.execute("SELECT to_regclass(%s) IS NOT NULL", (f"public.{relation_name}",))
    row = cur.fetchone()
    return bool(row and row[0])


def selected_deck_sql(args: argparse.Namespace) -> tuple[str, tuple[Any, ...]]:
    if args.pg_deck_id:
        return "WHERE d.id = %s", (args.pg_deck_id,)
    return (
        """
        WHERE d.name ILIKE %s
           OR EXISTS (
             SELECT 1
             FROM deck_cards dc2
             JOIN cards c2 ON c2.id = dc2.card_id
             WHERE dc2.deck_id = d.id
               AND dc2.is_commander = true
               AND c2.name ILIKE '%%Lorehold%%'
           )
        """,
        (args.deck_name_like,),
    )


def fetch_target_deck(args: argparse.Namespace) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    where_sql, params = selected_deck_sql(args)
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                f"""
                SELECT
                  d.id::text,
                  d.name,
                  d.format,
                  d.archetype,
                  d.bracket,
                  d.created_at,
                  count(dc.*) AS rows,
                  COALESCE(sum(dc.quantity), 0) AS total_qty,
                  max(CASE WHEN dc.is_commander THEN c.name ELSE NULL END) AS commander
                FROM decks d
                JOIN deck_cards dc ON dc.deck_id = d.id
                JOIN cards c ON c.id = dc.card_id
                {where_sql}
                GROUP BY d.id, d.name, d.format, d.archetype, d.bracket, d.created_at
                ORDER BY
                  CASE WHEN COALESCE(sum(dc.quantity), 0) = 100 THEN 0 ELSE 1 END,
                  CASE WHEN count(dc.*) >= 80 THEN 0 ELSE 1 END,
                  d.created_at DESC NULLS LAST
                LIMIT 1
                """,
                params,
            )
            deck_row = cur.fetchone()
            if not deck_row:
                raise RuntimeError("No PG target deck found.")
            pg_deck_id = deck_row[0]
            deck = {
                "pg_deck_id": pg_deck_id,
                "name": deck_row[1],
                "format": deck_row[2],
                "archetype": deck_row[3],
                "bracket": deck_row[4],
                "created_at": str(deck_row[5]),
                "rows": int(deck_row[6]),
                "total_qty": int(deck_row[7]),
                "commander": deck_row[8],
            }
            if deck["total_qty"] < args.min_total_cards:
                raise RuntimeError(
                    "Selected PG deck is partial: "
                    f"total_qty={deck['total_qty']}, min_total_cards={args.min_total_cards}, "
                    f"pg_deck_id={pg_deck_id}. Refusing to sync phantom deck."
                )
            if not deck["commander"]:
                raise RuntimeError(
                    f"Selected PG deck has no commander row: pg_deck_id={pg_deck_id}."
                )
            use_snapshot = has_pg_relation(cur, "card_intelligence_snapshot")
            deck["semantic_source"] = (
                "card_intelligence_snapshot"
                if use_snapshot
                else "sync_pg_target_deck_to_hermes_cte_fallback"
            )
            cur.execute(
                semantic_deck_cards_snapshot_sql()
                if use_snapshot
                else semantic_deck_cards_sql(),
                (pg_deck_id,),
            )
            cards = []
            for row in cur.fetchall():
                battle_rules = parse_json_value(row[11], [])
                first_rule = battle_rules[0] if battle_rules and isinstance(battle_rules[0], dict) else {}
                effect_json = first_rule.get("effect") if isinstance(first_rule.get("effect"), dict) else {}
                role_json = first_rule.get("deck_role") if isinstance(first_rule.get("deck_role"), dict) else {}
                card = {
                    "name": row[0],
                    "quantity": int(row[1] or 1),
                    "is_commander": bool(row[2]),
                    "cmc": float(row[3] or 0),
                    "type_line": row[4] or "",
                    "oracle_text": row[5] or "",
                    "card_id": row[6],
                    "functional_tags_json": row[7],
                    "functional_tag": row[8],
                    "tag_confidence": float(row[9] or 0),
                    "semantic_tags_v2_json": row[10],
                    "battle_rules_json": row[11],
                    "battle_effect": effect_json.get("effect"),
                    "battle_role": role_json,
                    "rule_review_status": first_rule.get("review_status"),
                }
                tags = normalize_functional_tags(card["functional_tags_json"], card["functional_tag"])
                inferred_tag = infer_tag(card)
                if not tags and inferred_tag != "unknown":
                    tags = [inferred_tag]
                card["functional_tag"] = primary_functional_tag(tags, inferred_tag)
                card["functional_tags_json"] = stable_json(tags)
                cards.append(card)
            return deck, cards


def snapshot_hashes(cards: list[dict[str, Any]]) -> tuple[str, str, str]:
    deck_payload = []
    semantics_payload = []
    ruleset_payload = []
    for card in cards:
        deck_payload.append(
            {
                "card_id": card["card_id"],
                "card_name": card["name"],
                "quantity": int(card["quantity"]),
                "is_commander": bool(card["is_commander"]),
            }
        )
        semantics_payload.append(
            {
                "card_id": card["card_id"],
                "functional_tags_json": parse_json_value(card["functional_tags_json"], []),
                "semantic_tags_v2_json": parse_json_value(card["semantic_tags_v2_json"], []),
            }
        )
        ruleset_payload.append(
            {
                "card_id": card["card_id"],
                "battle_rules_json": parse_json_value(card["battle_rules_json"], []),
            }
        )
    deck_hash = hashlib.sha256(stable_json(deck_payload).encode("utf-8")).hexdigest()
    semantics_hash = hashlib.sha256(stable_json(semantics_payload).encode("utf-8")).hexdigest()
    ruleset_hash = hashlib.sha256(stable_json(ruleset_payload).encode("utf-8")).hexdigest()
    return deck_hash, semantics_hash, ruleset_hash


def write_sqlite(
    sqlite_db: str,
    target_deck_id: int,
    deck: dict[str, Any],
    cards: list[dict[str, Any]],
    *,
    apply: bool,
) -> dict[str, int]:
    snapshot_cards = normalize_snapshot_cards(cards)
    deck_hash, semantics_hash, ruleset_hash = snapshot_hashes(snapshot_cards)
    sync_run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    deck_total_qty = int(deck.get("total_qty") or 0)
    stats = {
        "cards_seen": len(cards),
        "quantity_seen": sum(int(card["quantity"]) for card in cards),
        "duplicate_rows_collapsed": 0,
        "battle_rules_seen": sum(
            len(parse_json_value(card.get("battle_rules_json"), []))
            for card in cards
            if isinstance(parse_json_value(card.get("battle_rules_json"), []), list)
        ),
        "battle_rules_written": sum(
            len(parse_json_value(card.get("battle_rules_json"), []))
            for card in snapshot_cards
            if isinstance(parse_json_value(card.get("battle_rules_json"), []), list)
        ),
        "cards_written": 0,
        "quantity_written": 0,
        "commanders": sum(1 for card in snapshot_cards if card["is_commander"]),
        "deck_hash": deck_hash,
        "semantics_hash": semantics_hash,
        "ruleset_hash": ruleset_hash,
        "sync_run_id": sync_run_id,
    }
    stats["battle_rules_deduped"] = (
        stats["battle_rules_seen"] - stats["battle_rules_written"]
    )
    if deck_total_qty and stats["quantity_seen"] != deck_total_qty:
        raise RuntimeError(
            "Fetched deck quantity mismatch before SQLite write: "
            f"deck_total_qty={deck_total_qty}, fetched_quantity={stats['quantity_seen']}. "
            "This usually means a join multiplied deck card rows."
        )
    conn = sqlite3.connect(sqlite_db)
    try:
        cur = conn.cursor()
        ensure_sqlite_schema(cur)
        if apply:
            cur.execute("DELETE FROM deck_cards WHERE deck_id=?", (target_deck_id,))
            cur.execute("DELETE FROM decks WHERE id=?", (target_deck_id,))
            cur.execute(
                """
                INSERT INTO decks (id, deck_name, archetype, total_cards, notes)
                VALUES (?, ?, ?, ?, ?)
                """,
                (
                    target_deck_id,
                    deck["name"],
                    deck.get("archetype") or "unknown",
                    deck["total_qty"],
                    f"sync_pg_target_deck_to_hermes.py pg_deck_id={deck['pg_deck_id']}",
                ),
            )
            for card in snapshot_cards:
                cur.execute(
                    """
                    INSERT INTO deck_cards (
                        deck_id,
                        card_id,
                        card_name,
                        quantity,
                        functional_tag,
                        functional_tags_json,
                        semantic_tags_v2_json,
                        battle_rules_json,
                        deck_hash,
                        semantics_hash,
                        ruleset_hash,
                        sync_run_id,
                        tag_confidence,
                        is_commander,
                        is_partner,
                        cmc,
                        type_line,
                        oracle_text
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)
                    """,
                    (
                        target_deck_id,
                        card["card_id"],
                        card["name"],
                        card["quantity"],
                        card["functional_tag"],
                        card["functional_tags_json"],
                        card["semantic_tags_v2_json"],
                        card["battle_rules_json"],
                        deck_hash,
                        semantics_hash,
                        ruleset_hash,
                        sync_run_id,
                        float(card.get("tag_confidence") or 0.55),
                        1 if card["is_commander"] else 0,
                        card["cmc"],
                        card["type_line"],
                        card["oracle_text"],
                    ),
                )
                stats["cards_written"] += 1
                stats["quantity_written"] += int(card["quantity"])
            conn.commit()
        else:
            conn.rollback()
    finally:
        conn.close()
    return stats


def main() -> int:
    args = parse_args()
    sqlite_db = Path(args.sqlite_db)
    sqlite_db.parent.mkdir(parents=True, exist_ok=True)
    deck, cards = fetch_target_deck(args)
    stats = write_sqlite(
        str(sqlite_db),
        args.target_deck_id,
        deck,
        cards,
        apply=args.apply,
    )
    report = {
        "apply": bool(args.apply),
        "database_target": sanitized_database_target(),
        "sqlite_db": str(sqlite_db),
        "target_deck_id": args.target_deck_id,
        "deck": deck,
        "stats": stats,
        "tags": dict(
            sorted(
                {
                    tag: sum(
                        1
                        for card in cards
                        if tag
                        in normalize_functional_tags(
                            card.get("functional_tags_json"),
                            card.get("functional_tag"),
                        )
                    )
                    for tag in {
                        tag
                        for card in cards
                        for tag in normalize_functional_tags(
                            card.get("functional_tags_json"),
                            card.get("functional_tag"),
                        )
                    }
                }.items()
            )
        ),
    }
    output = json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True)
    print(output)
    if args.report:
        Path(args.report).write_text(output + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
