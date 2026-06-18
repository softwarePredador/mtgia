#!/usr/bin/env python3
"""Deterministic new-card candidate review for ManaLoom commanders.

This job is report-only. PostgreSQL/backend remains the source of truth; the
local SQLite DB stores only operational review history for Hermes/manaloom-ops.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
DEFAULT_OUTPUT_DIR = REPO_ROOT / "server/test/artifacts/new_card_candidate_review_local"
DEFAULT_KNOWLEDGE_DB = REPO_ROOT / "server/test/artifacts/new_card_candidate_review_local/knowledge.db"
DEFAULT_ROLE_TARGETS = {
    "ramp": 10,
    "draw": 10,
    "removal": 10,
    "protection": 5,
    "tutor": 2,
    "board_wipe": 3,
    "engine": 5,
    "wincon": 3,
    "payoff": 4,
    "enabler": 4,
}
ROLE_ALIASES = {
    "wipe": "board_wipe",
    "boardwipe": "board_wipe",
    "board_wipe": "board_wipe",
    "counterspell": "removal",
    "interaction": "removal",
    "mana_fixing": "ramp",
    "ritual": "ramp",
    "card_draw": "draw",
    "card_advantage": "draw",
    "combo_piece": "combo",
    "token_maker": "token",
}
RELEVANT_ROLES = {
    "ramp",
    "draw",
    "removal",
    "protection",
    "tutor",
    "board_wipe",
    "engine",
    "wincon",
    "payoff",
    "enabler",
    "combo",
    "token",
    "recursion",
}
CONTROL_COMMANDER = "Lorehold, the Historian"


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def normalize_name(value: str | None) -> str:
    if not value:
        return ""
    return re.sub(r"\s+", " ", value.strip().lower())


def front_name(value: str | None) -> str:
    return (value or "").split("//", 1)[0].strip()


def normalize_role(role: str | None) -> str:
    normalized = normalize_name(role).replace(" ", "_").replace("-", "_")
    return ROLE_ALIASES.get(normalized, normalized)


def unique_sorted(values: Iterable[str]) -> list[str]:
    return sorted({value for value in values if value})


def parse_list(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, (list, tuple, set)):
        return [str(item) for item in value if item is not None and str(item) != ""]
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return []
        if text.startswith("["):
            try:
                parsed = json.loads(text)
                return parse_list(parsed)
            except Exception:
                pass
        if text.startswith("{") and text.endswith("}"):
            return [
                item.strip().strip('"')
                for item in text[1:-1].split(",")
                if item.strip().strip('"')
            ]
        return [item.strip() for item in text.split(",") if item.strip()]
    return [str(value)]


def parse_json_value(value: Any, default: Any) -> Any:
    if value is None:
        return default
    if isinstance(value, (dict, list)):
        return value
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return default
        try:
            return json.loads(text)
        except Exception:
            return default
    return default


def safe_float(value: Any, default: float = 0.0) -> float:
    try:
        if value is None or value == "":
            return default
        return float(value)
    except (TypeError, ValueError):
        return default


def json_default(value: Any) -> Any:
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value)


def load_env_file(path: Path) -> None:
    if not path.is_file():
        return
    for raw_line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in raw_line:
            continue
        key, value = raw_line.split("=", 1)
        key = key.strip()
        value = value.strip().strip("\"'")
        if key and key not in os.environ:
            os.environ[key] = value


@dataclass
class CardRecord:
    card_id: str
    oracle_id: str | None
    name: str
    mana_cost: str = ""
    type_line: str = ""
    oracle_text: str = ""
    color_identity: list[str] = field(default_factory=list)
    cmc: float = 0.0
    set_code: str = ""
    set_name: str = ""
    release_date: str | None = None
    legalities: dict[str, str] = field(default_factory=dict)
    function_tags: list[str] = field(default_factory=list)
    semantic_tags_v2: list[dict[str, Any]] = field(default_factory=list)
    scored_roles: list[str] = field(default_factory=list)
    battle_rule_count: int = 0
    verified_battle_rule_count: int = 0
    source_coverage: dict[str, Any] = field(default_factory=dict)

    @property
    def identity_key(self) -> str:
        return self.oracle_id or normalize_name(self.name)


@dataclass
class CommanderTarget:
    name: str
    source: str
    color_identity: list[str] = field(default_factory=list)
    existing_oracle_ids: set[str] = field(default_factory=set)
    existing_names: set[str] = field(default_factory=set)
    role_counts: dict[str, int] = field(default_factory=dict)

    @property
    def normalized_name(self) -> str:
        return normalize_name(self.name)


@dataclass
class CandidateReview:
    commander_name: str
    commander_source: str
    commander_color_identity: list[str]
    card_id: str
    oracle_id: str | None
    card_name: str
    set_code: str
    roles: list[str]
    decision: str
    reasons: list[str]
    risk_flags: list[str]
    score: int
    battle_rule_status: str
    payload: dict[str, Any]


def infer_roles_from_text(type_line: str, oracle_text: str, tags: list[str]) -> list[str]:
    roles = {normalize_role(tag) for tag in tags}
    text = f"{type_line}\n{oracle_text}".lower()

    def add(role: str, *patterns: str) -> None:
        if any(pattern in text for pattern in patterns):
            roles.add(role)

    add("ramp", "add {", "add one mana", "treasure token", "search your library for a land")
    add("draw", "draw a card", "draw two", "draw cards", "investigate", "loot", "discard a card, then draw")
    add("removal", "destroy target", "exile target", "counter target", "deals ", "damage to target")
    add("protection", "hexproof", "indestructible", "protection from", "phase out", "prevent all damage")
    add("tutor", "search your library")
    add("board_wipe", "destroy all", "exile all", "each creature", "all creatures", "each opponent sacrifices")
    add("engine", "whenever you cast", "at the beginning of", "whenever one or more")
    add("payoff", "copy target", "copy that spell", "create a token", "deals damage to each opponent")
    add("wincon", "you win the game", "each opponent loses", "extra turn")
    add("recursion", "return target", "from your graveyard", "escape", "flashback")

    if "legendary" in type_line.lower() and "creature" in type_line.lower():
        roles.add("commander_candidate")
    return sorted(role for role in roles if role in RELEVANT_ROLES or role == "commander_candidate")


def roles_from_semantic_tags(items: list[dict[str, Any]]) -> list[str]:
    roles: set[str] = set()
    for item in items:
        if not isinstance(item, dict):
            continue
        for key in ("combo_piece", "wincon", "engine", "payoff", "enabler"):
            if item.get(key) is True:
                roles.add(normalize_role(key))
        if item.get("protection_type"):
            roles.add("protection")
        if item.get("recursion_type"):
            roles.add("recursion")
        for tag in parse_list(item.get("tags")):
            role = normalize_role(tag)
            if role in RELEVANT_ROLES:
                roles.add(role)
    return sorted(roles)


def commander_legal_status(card: CardRecord) -> str | None:
    status = card.legalities.get("commander")
    if status:
        return normalize_name(status)
    status = card.legalities.get("Commander")
    if status:
        return normalize_name(status)
    return None


def card_within_identity(card: CardRecord, commander_identity: list[str]) -> bool:
    commander_colors = {color.upper() for color in commander_identity}
    card_colors = {color.upper() for color in card.color_identity}
    return card_colors.issubset(commander_colors)


def battle_rule_status(card: CardRecord, roles: list[str]) -> str:
    if card.verified_battle_rule_count > 0:
        return "verified"
    if card.battle_rule_count > 0:
        return "needs_review"
    if any(role in roles for role in ("removal", "board_wipe", "tutor", "engine", "wincon", "combo")):
        return "missing"
    return "not_required"


def score_candidate(card: CardRecord, commander: CommanderTarget, roles: list[str]) -> tuple[int, list[str]]:
    score = 0
    reasons: list[str] = []
    for role in roles:
        target = DEFAULT_ROLE_TARGETS.get(role)
        if target is None:
            continue
        current = commander.role_counts.get(role, 0)
        if current < target:
            boost = min(24, (target - current) * 3)
            score += boost
            reasons.append(f"slot_gap:{role}:{current}/{target}")
        else:
            score += 4
            reasons.append(f"role_present:{role}")
    if card.cmc <= 2 and any(role in roles for role in ("ramp", "draw", "removal", "protection")):
        score += 12
        reasons.append("efficient_low_cmc")
    if card.cmc >= 7 and "wincon" not in roles:
        score -= 16
        reasons.append("high_cmc_without_wincon")
    text = card.oracle_text.lower()
    commander_text = commander.normalized_name
    if commander_text and commander_text.split(",")[0] in text:
        score += 14
        reasons.append("mentions_commander_name_family")
    if {"W", "R"}.issubset({c.upper() for c in commander.color_identity}):
        if any(token in text for token in ("artifact", "graveyard", "spirit", "instant or sorcery")):
            score += 8
            reasons.append("boros_lorehold_adjacent_synergy")
    if card.verified_battle_rule_count > 0:
        score += 8
        reasons.append("verified_battle_rule")
    elif card.battle_rule_count > 0:
        score += 2
        reasons.append("battle_rule_needs_review")
    if not roles:
        score -= 20
        reasons.append("no_relevant_role")
    return max(0, min(100, score)), reasons


def evaluate_card_for_commander(card: CardRecord, commander: CommanderTarget) -> CandidateReview:
    base_tags = [normalize_role(tag) for tag in card.function_tags + card.scored_roles]
    semantic_roles = roles_from_semantic_tags(card.semantic_tags_v2)
    roles = infer_roles_from_text(
        card.type_line,
        card.oracle_text,
        base_tags + semantic_roles,
    )
    reasons: list[str] = []
    risk_flags: list[str] = []

    status = commander_legal_status(card)
    if not card.oracle_text:
        risk_flags.append("missing_oracle_text")
    if not status:
        risk_flags.append("missing_commander_legality")
    if card.identity_key in commander.existing_oracle_ids or normalize_name(card.name) in commander.existing_names:
        decision = "already_present"
        score = 0
        reasons.append("card_already_present_by_oracle_or_name")
    elif not card_within_identity(card, commander.color_identity):
        decision = "ignore"
        score = 0
        reasons.append("outside_commander_color_identity")
    elif status and status != "legal":
        decision = "ignore"
        score = 0
        reasons.append(f"not_commander_legal:{status}")
    elif not card.oracle_id or not status or not card.oracle_text:
        decision = "needs_data"
        score, score_reasons = score_candidate(card, commander, roles)
        reasons.extend(score_reasons)
        reasons.append("missing_required_card_data")
    else:
        score, score_reasons = score_candidate(card, commander, roles)
        reasons.extend(score_reasons)
        rule_status = battle_rule_status(card, roles)
        if rule_status in {"missing", "needs_review"} and score >= 45:
            decision = "needs_rule_review"
            reasons.append(f"battle_rule_status:{rule_status}")
        elif score >= 70:
            decision = "test"
            reasons.append("score_above_test_threshold")
        elif score >= 35:
            decision = "backlog"
            reasons.append("score_above_backlog_threshold")
        else:
            decision = "ignore"
            reasons.append("score_below_backlog_threshold")

    rule_status = battle_rule_status(card, roles)
    payload = {
        "cmc": card.cmc,
        "type_line": card.type_line,
        "mana_cost": card.mana_cost,
        "color_identity": card.color_identity,
        "set_name": card.set_name,
        "release_date": card.release_date,
        "legalities": card.legalities,
        "function_tags": card.function_tags,
        "semantic_roles": semantic_roles,
        "scored_roles": card.scored_roles,
        "battle_rule_count": card.battle_rule_count,
        "verified_battle_rule_count": card.verified_battle_rule_count,
        "source_coverage": card.source_coverage,
    }
    return CandidateReview(
        commander_name=commander.name,
        commander_source=commander.source,
        commander_color_identity=commander.color_identity,
        card_id=card.card_id,
        oracle_id=card.oracle_id,
        card_name=card.name,
        set_code=card.set_code,
        roles=roles,
        decision=decision,
        reasons=unique_sorted(reasons),
        risk_flags=unique_sorted(risk_flags),
        score=score,
        battle_rule_status=rule_status,
        payload=payload,
    )


def load_fixture(path: Path) -> tuple[list[CommanderTarget], list[CardRecord]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    commanders: list[CommanderTarget] = []
    for row in payload.get("commanders", []):
        existing_cards = row.get("existing_cards", [])
        existing_names = {
            normalize_name(item.get("name") if isinstance(item, dict) else str(item))
            for item in existing_cards
        }
        existing_oracles = {
            str(item.get("oracle_id"))
            for item in existing_cards
            if isinstance(item, dict) and item.get("oracle_id")
        }
        commanders.append(
            CommanderTarget(
                name=row["name"],
                source=row.get("source", "fixture"),
                color_identity=parse_list(row.get("color_identity")),
                existing_oracle_ids=existing_oracles,
                existing_names=existing_names,
                role_counts={
                    normalize_role(key): int(value)
                    for key, value in row.get("role_counts", {}).items()
                },
            )
        )
    cards = [card_from_mapping(row) for row in payload.get("cards", [])]
    return commanders, cards


def card_from_mapping(row: dict[str, Any]) -> CardRecord:
    semantic = parse_json_value(row.get("semantic_tags_v2"), [])
    if not isinstance(semantic, list):
        semantic = []
    legalities = parse_json_value(row.get("legalities"), {})
    if not isinstance(legalities, dict):
        legalities = {}
    coverage = parse_json_value(row.get("source_coverage"), {})
    if not isinstance(coverage, dict):
        coverage = {}
    return CardRecord(
        card_id=str(row.get("card_id") or row.get("id") or row.get("name")),
        oracle_id=str(row["oracle_id"]) if row.get("oracle_id") else None,
        name=str(row.get("name") or row.get("card_name") or ""),
        mana_cost=str(row.get("mana_cost") or ""),
        type_line=str(row.get("type_line") or ""),
        oracle_text=str(row.get("oracle_text") or ""),
        color_identity=[value.upper() for value in parse_list(row.get("color_identity"))],
        cmc=safe_float(row.get("cmc")),
        set_code=str(row.get("set_code") or "").lower(),
        set_name=str(row.get("set_name") or ""),
        release_date=str(row["release_date"]) if row.get("release_date") else None,
        legalities={str(k): str(v) for k, v in legalities.items()},
        function_tags=[normalize_role(tag) for tag in parse_list(row.get("function_tags"))],
        semantic_tags_v2=[item for item in semantic if isinstance(item, dict)],
        scored_roles=[normalize_role(tag) for tag in parse_list(row.get("scored_roles"))],
        battle_rule_count=int(row.get("battle_rule_count") or 0),
        verified_battle_rule_count=int(row.get("verified_battle_rule_count") or 0),
        source_coverage=coverage,
    )


def load_psycopg2():
    import psycopg2  # type: ignore
    import psycopg2.extras  # type: ignore

    return psycopg2, psycopg2.extras


class PgSource:
    def __init__(self) -> None:
        self.psycopg2, self.extras = load_psycopg2()
        dsn = os.environ.get("DATABASE_URL")
        kwargs = {"connect_timeout": 12, "cursor_factory": self.extras.RealDictCursor}
        if dsn:
            self.conn = self.psycopg2.connect(dsn=dsn, **kwargs)
        else:
            self.conn = self.psycopg2.connect(
                host=os.environ.get("DB_HOST", ""),
                port=os.environ.get("DB_PORT", "5432"),
                dbname=os.environ.get("DB_NAME", ""),
                user=os.environ.get("DB_USER", ""),
                password=os.environ.get("DB_PASS", ""),
                **kwargs,
            )
        self._tables: set[str] | None = None
        self._columns: dict[str, set[str]] = {}

    def close(self) -> None:
        self.conn.close()

    def table_exists(self, name: str) -> bool:
        if self._tables is None:
            with self.conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT table_name
                    FROM information_schema.tables
                    WHERE table_schema = 'public'
                    """
                )
                self._tables = {str(row["table_name"]) for row in cur.fetchall()}
        return name in self._tables

    def columns(self, table: str) -> set[str]:
        if table not in self._columns:
            with self.conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = %s
                    """,
                    (table,),
                )
                self._columns[table] = {str(row["column_name"]) for row in cur.fetchall()}
        return self._columns[table]

    def fetch_cards(self, sets: list[str], lookback_days: int, card_limit: int) -> list[CardRecord]:
        has_snapshot = self.table_exists("card_intelligence_snapshot")
        has_sets = self.table_exists("sets")
        set_filter = ""
        params: list[Any] = []
        normalized_sets = [item.lower() for item in sets if item]
        if normalized_sets:
            placeholders = ", ".join(["%s"] * len(normalized_sets))
            set_filter = f"WHERE LOWER(c.set_code) IN ({placeholders})"
            params.extend(normalized_sets)
        elif has_sets:
            set_filter = "WHERE s.release_date >= (CURRENT_DATE - (%s || ' days')::interval)"
            params.append(str(lookback_days))
        else:
            set_filter = "WHERE c.created_at >= (NOW() - (%s || ' days')::interval)"
            params.append(str(lookback_days))
        params.append(card_limit)

        if has_snapshot:
            release_select = "s.release_date::text AS release_date" if has_sets else "NULL AS release_date"
            set_join = "LEFT JOIN sets s ON LOWER(s.code) = LOWER(c.set_code)" if has_sets else ""
            order_expr = "COALESCE(s.release_date, CURRENT_DATE)" if has_sets else "CURRENT_DATE"
            query = f"""
                SELECT
                  c.card_id::text AS card_id,
                  c.oracle_id::text AS oracle_id,
                  c.name,
                  c.mana_cost,
                  c.type_line,
                  c.oracle_text,
                  c.color_identity,
                  c.cmc,
                  c.set_code,
                  {release_select},
                  {("s.name AS set_name" if has_sets else "NULL AS set_name")},
                  c.legalities,
                  c.function_tags,
                  c.semantic_tags_v2,
                  c.scored_roles,
                  c.battle_rule_count,
                  c.verified_battle_rule_count,
                  c.source_coverage
                FROM card_intelligence_snapshot c
                {set_join}
                {set_filter}
                ORDER BY {order_expr} DESC NULLS LAST, c.name
                LIMIT %s
            """
        else:
            has_legalities = self.table_exists("card_legalities")
            has_cmc = "cmc" in self.columns("cards")
            has_price_usd = "price_usd" in self.columns("cards")
            release_select = "s.release_date::text AS release_date" if has_sets else "NULL AS release_date"
            set_join = "LEFT JOIN sets s ON LOWER(s.code) = LOWER(c.set_code)" if has_sets else ""
            order_expr = "COALESCE(s.release_date, CURRENT_DATE)" if has_sets else "CURRENT_DATE"
            legal_join = (
                "LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'"
                if has_legalities
                else ""
            )
            legal_select = (
                "jsonb_build_object('commander', cl.status) AS legalities"
                if has_legalities
                else "'{}'::jsonb AS legalities"
            )
            _ = has_price_usd  # kept for future compatibility without selecting missing columns
            query = f"""
                SELECT
                  c.id::text AS card_id,
                  c.oracle_id::text AS oracle_id,
                  c.name,
                  c.mana_cost,
                  c.type_line,
                  c.oracle_text,
                  c.color_identity,
                  {("c.cmc" if has_cmc else "0")} AS cmc,
                  c.set_code,
                  {release_select},
                  {("s.name AS set_name" if has_sets else "NULL AS set_name")},
                  {legal_select},
                  ARRAY[]::text[] AS function_tags,
                  '[]'::jsonb AS semantic_tags_v2,
                  ARRAY[]::text[] AS scored_roles,
                  0 AS battle_rule_count,
                  0 AS verified_battle_rule_count,
                  '{{}}'::jsonb AS source_coverage
                FROM cards c
                {set_join}
                {legal_join}
                {set_filter}
                ORDER BY {order_expr} DESC NULLS LAST, c.name
                LIMIT %s
            """
        with self.conn.cursor() as cur:
            cur.execute(query, params)
            rows = cur.fetchall()
        by_identity: dict[str, CardRecord] = {}
        for row in rows:
            card = card_from_mapping(dict(row))
            previous = by_identity.get(card.identity_key)
            if previous is None or (
                card.verified_battle_rule_count > previous.verified_battle_rule_count
            ):
                by_identity[card.identity_key] = card
        return sorted(by_identity.values(), key=lambda item: (item.set_code, item.name))

    def discover_targets(self, commander_limit: int, force_commanders: list[str]) -> list[CommanderTarget]:
        names: dict[str, str] = {}
        sources: dict[str, list[str]] = {}
        for forced in force_commanders:
            normalized = normalize_name(forced)
            if normalized:
                names[normalized] = forced
                sources.setdefault(normalized, []).append("force_include")
        if self.table_exists("commander_learned_decks"):
            with self.conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT commander_name, commander_name_normalized
                    FROM commander_learned_decks
                    WHERE is_active = TRUE
                    ORDER BY promoted_at DESC NULLS LAST, updated_at DESC NULLS LAST
                    LIMIT %s
                    """,
                    (commander_limit,),
                )
                for row in cur.fetchall():
                    normalized = normalize_name(row["commander_name_normalized"] or row["commander_name"])
                    if normalized:
                        names[normalized] = str(row["commander_name"])
                        sources.setdefault(normalized, []).append("commander_learned_decks")
        if self.table_exists("commander_card_usage"):
            with self.conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT commander_name_normalized, SUM(usage_count)::int AS total_usage
                    FROM commander_card_usage
                    GROUP BY commander_name_normalized
                    HAVING SUM(usage_count) >= 3
                    ORDER BY total_usage DESC
                    LIMIT %s
                    """,
                    (commander_limit,),
                )
                for row in cur.fetchall():
                    normalized = normalize_name(row["commander_name_normalized"])
                    if normalized:
                        names.setdefault(normalized, str(row["commander_name_normalized"]))
                        sources.setdefault(normalized, []).append("commander_card_usage")
        targets: list[CommanderTarget] = []
        for normalized, display_name in list(names.items())[:commander_limit]:
            target = self.resolve_commander(display_name, sources.get(normalized, []))
            if target is not None:
                targets.append(target)
        return targets

    def resolve_commander(self, name: str, sources: list[str]) -> CommanderTarget | None:
        with self.conn.cursor() as cur:
            source_table = "card_intelligence_snapshot" if self.table_exists("card_intelligence_snapshot") else "cards"
            id_col = "card_id" if source_table == "card_intelligence_snapshot" else "id"
            cur.execute(
                f"""
                SELECT {id_col}::text AS card_id, oracle_id::text, name, color_identity
                FROM {source_table}
                WHERE LOWER(name) = LOWER(%s)
                   OR LOWER(split_part(name, ' // ', 1)) = LOWER(%s)
                ORDER BY name
                LIMIT 1
                """,
                (name, front_name(name)),
            )
            row = cur.fetchone()
        if not row:
            return None
        existing_names: set[str] = set()
        existing_oracles: set[str] = set()
        if self.table_exists("commander_learned_decks"):
            with self.conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT card_list
                    FROM commander_learned_decks
                    WHERE commander_name_normalized = %s AND is_active = TRUE
                    ORDER BY promoted_at DESC NULLS LAST, updated_at DESC NULLS LAST
                    LIMIT 1
                    """,
                    (normalize_name(name),),
                )
                learned = cur.fetchone()
            if learned and learned.get("card_list"):
                existing_names.update(parse_card_list_names(str(learned["card_list"])))
        existing_names.add(normalize_name(name))
        if row.get("oracle_id"):
            existing_oracles.add(str(row["oracle_id"]))
        return CommanderTarget(
            name=str(row["name"]),
            source="+".join(unique_sorted(sources)) or "pg_resolved",
            color_identity=[value.upper() for value in parse_list(row["color_identity"])],
            existing_oracle_ids=existing_oracles,
            existing_names=existing_names,
        )


def parse_card_list_names(value: str) -> set[str]:
    text = value.strip()
    if not text:
        return set()
    names: set[str] = set()
    try:
        parsed = json.loads(text)
        if isinstance(parsed, list):
            for item in parsed:
                if isinstance(item, dict):
                    name = item.get("name") or item.get("card_name")
                    if name:
                        names.add(normalize_name(str(name)))
                elif isinstance(item, str):
                    names.add(normalize_name(item))
            return names
    except Exception:
        pass
    for line in text.splitlines():
        cleaned = re.sub(r"^\s*\d+\s+x?\s+", "", line).strip()
        if cleaned:
            names.add(normalize_name(cleaned))
    return names


def ensure_sqlite_schema(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS new_card_candidate_review_runs (
            run_id TEXT PRIMARY KEY,
            generated_at TEXT NOT NULL,
            dry_run INTEGER NOT NULL,
            cards_scanned INTEGER NOT NULL,
            commanders_scanned INTEGER NOT NULL,
            review_count INTEGER NOT NULL,
            summary_json TEXT NOT NULL
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS new_card_candidate_reviews (
            run_id TEXT NOT NULL,
            commander_name TEXT NOT NULL,
            card_name TEXT NOT NULL,
            oracle_id TEXT,
            set_code TEXT,
            decision TEXT NOT NULL,
            score INTEGER NOT NULL,
            roles_json TEXT NOT NULL,
            reasons_json TEXT NOT NULL,
            risk_flags_json TEXT NOT NULL,
            battle_rule_status TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            PRIMARY KEY (run_id, commander_name, card_name, set_code)
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS new_card_battle_rule_review_queue (
            commander_name TEXT NOT NULL,
            card_name TEXT NOT NULL,
            oracle_id TEXT,
            set_code TEXT,
            roles_json TEXT NOT NULL,
            reason TEXT NOT NULL,
            first_seen_at TEXT NOT NULL,
            last_seen_at TEXT NOT NULL,
            latest_run_id TEXT NOT NULL,
            PRIMARY KEY (commander_name, card_name, set_code)
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS new_card_candidate_review_checkpoints (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
        """
    )
    conn.commit()


def persist_sqlite(
    db_path: Path,
    run_id: str,
    dry_run: bool,
    reviews: list[CandidateReview],
    cards_scanned: int,
    commanders_scanned: int,
    summary: dict[str, Any],
) -> None:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    try:
        ensure_sqlite_schema(conn)
        generated_at = summary["generated_at"]
        conn.execute(
            """
            INSERT OR REPLACE INTO new_card_candidate_review_runs (
                run_id, generated_at, dry_run, cards_scanned,
                commanders_scanned, review_count, summary_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                run_id,
                generated_at,
                1 if dry_run else 0,
                cards_scanned,
                commanders_scanned,
                len(reviews),
                json.dumps(summary, sort_keys=True, default=json_default),
            ),
        )
        for review in reviews:
            conn.execute(
                """
                INSERT OR REPLACE INTO new_card_candidate_reviews (
                    run_id, commander_name, card_name, oracle_id, set_code,
                    decision, score, roles_json, reasons_json, risk_flags_json,
                    battle_rule_status, payload_json, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    run_id,
                    review.commander_name,
                    review.card_name,
                    review.oracle_id,
                    review.set_code,
                    review.decision,
                    review.score,
                    json.dumps(review.roles, sort_keys=True),
                    json.dumps(review.reasons, sort_keys=True),
                    json.dumps(review.risk_flags, sort_keys=True),
                    review.battle_rule_status,
                    json.dumps(review.payload, sort_keys=True, default=json_default),
                    generated_at,
                ),
            )
            if review.decision == "needs_rule_review":
                conn.execute(
                    """
                    INSERT INTO new_card_battle_rule_review_queue (
                        commander_name, card_name, oracle_id, set_code,
                        roles_json, reason, first_seen_at, last_seen_at,
                        latest_run_id
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(commander_name, card_name, set_code) DO UPDATE SET
                        roles_json = excluded.roles_json,
                        reason = excluded.reason,
                        last_seen_at = excluded.last_seen_at,
                        latest_run_id = excluded.latest_run_id
                    """,
                    (
                        review.commander_name,
                        review.card_name,
                        review.oracle_id,
                        review.set_code,
                        json.dumps(review.roles, sort_keys=True),
                        "; ".join(review.reasons[:4]),
                        generated_at,
                        generated_at,
                        run_id,
                    ),
                )
        conn.execute(
            """
            INSERT OR REPLACE INTO new_card_candidate_review_checkpoints (
                key, value, updated_at
            ) VALUES (?, ?, ?)
            """,
            ("last_successful_run_at", generated_at, generated_at),
        )
        conn.commit()
    finally:
        conn.close()


def summarize_reviews(
    run_id: str,
    generated_at: str,
    cards: list[CardRecord],
    commanders: list[CommanderTarget],
    reviews: list[CandidateReview],
    args: argparse.Namespace,
) -> dict[str, Any]:
    decisions: dict[str, int] = {}
    by_commander: dict[str, dict[str, Any]] = {}
    hermes_wake_reasons: list[str] = []
    for review in reviews:
        decisions[review.decision] = decisions.get(review.decision, 0) + 1
        row = by_commander.setdefault(
            review.commander_name,
            {
                "source": review.commander_source,
                "color_identity": review.commander_color_identity,
                "decisions": {},
                "top_candidates": [],
            },
        )
        row["decisions"][review.decision] = row["decisions"].get(review.decision, 0) + 1
        if review.decision in {"test", "needs_rule_review", "backlog"}:
            row["top_candidates"].append(
                {
                    "card_name": review.card_name,
                    "set_code": review.set_code,
                    "decision": review.decision,
                    "score": review.score,
                    "roles": review.roles,
                    "reasons": review.reasons[:5],
                }
            )
    for row in by_commander.values():
        row["top_candidates"] = sorted(
            row["top_candidates"],
            key=lambda item: (-int(item["score"]), item["card_name"]),
        )[:10]
    if decisions.get("test", 0):
        hermes_wake_reasons.append("new_test_candidates")
    if decisions.get("needs_rule_review", 0) >= args.hermes_rule_review_threshold:
        hermes_wake_reasons.append("rule_review_threshold")
    if any(review.risk_flags for review in reviews if review.decision in {"test", "backlog"}):
        hermes_wake_reasons.append("candidate_data_risk")
    return {
        "run_id": run_id,
        "generated_at": generated_at,
        "mode": "fixture" if args.fixture else "postgres",
        "dry_run": True,
        "sets": args.sets,
        "lookback_days": args.lookback_days,
        "cards_scanned": len(cards),
        "commanders_scanned": len(commanders),
        "review_count": len(reviews),
        "decisions": decisions,
        "by_commander": by_commander,
        "hermes_lab_should_wake": bool(hermes_wake_reasons),
        "hermes_wake_reasons": unique_sorted(hermes_wake_reasons),
        "notes": [
            "report_only_no_pg_writes",
            "postgres_backend_source_of_truth",
            "sqlite_operational_cache_only",
            "no_llm_used",
        ],
    }


def render_markdown(summary: dict[str, Any], reviews: list[CandidateReview]) -> str:
    lines = [
        "# New Card Candidate Review",
        "",
        f"- Run: `{summary['run_id']}`",
        f"- Generated at: `{summary['generated_at']}`",
        f"- Mode: `{summary['mode']}`",
        f"- Cards scanned: `{summary['cards_scanned']}`",
        f"- Commanders scanned: `{summary['commanders_scanned']}`",
        f"- Hermes wake: `{summary['hermes_lab_should_wake']}` {summary['hermes_wake_reasons']}",
        "",
        "## Decision Counts",
        "",
    ]
    for decision, count in sorted(summary["decisions"].items()):
        lines.append(f"- `{decision}`: {count}")
    lines.extend(["", "## Commander Summaries", ""])
    for commander, row in sorted(summary["by_commander"].items()):
        lines.append(f"### {commander}")
        lines.append("")
        lines.append(f"- Source: `{row['source']}`")
        lines.append(f"- Identity: `{''.join(row['color_identity']) or 'colorless'}`")
        lines.append(f"- Decisions: `{json.dumps(row['decisions'], sort_keys=True)}`")
        if row["top_candidates"]:
            lines.append("")
            lines.append("| Card | Set | Decision | Score | Roles | Reasons |")
            lines.append("| --- | --- | --- | ---: | --- | --- |")
            for item in row["top_candidates"]:
                lines.append(
                    "| {card} | {set_code} | `{decision}` | {score} | {roles} | {reasons} |".format(
                        card=item["card_name"].replace("|", "\\|"),
                        set_code=item["set_code"],
                        decision=item["decision"],
                        score=item["score"],
                        roles=", ".join(item["roles"]),
                        reasons=", ".join(item["reasons"]).replace("|", "\\|"),
                    )
                )
        lines.append("")
    lines.extend(["## Rule/Data Review Queue", ""])
    queue = [review for review in reviews if review.decision in {"needs_rule_review", "needs_data"}]
    if not queue:
        lines.append("No rule/data blockers in this run.")
    else:
        lines.append("| Commander | Card | Decision | Roles | Reasons |")
        lines.append("| --- | --- | --- | --- | --- |")
        for review in sorted(queue, key=lambda item: (item.commander_name, item.card_name)):
            lines.append(
                "| {commander} | {card} | `{decision}` | {roles} | {reasons} |".format(
                    commander=review.commander_name.replace("|", "\\|"),
                    card=review.card_name.replace("|", "\\|"),
                    decision=review.decision,
                    roles=", ".join(review.roles),
                    reasons=", ".join(review.reasons[:5]).replace("|", "\\|"),
                )
            )
    lines.extend(
        [
            "",
            "## Safety Contract",
            "",
            "- No PostgreSQL writes.",
            "- No automatic deck changes.",
            "- No LLM calls.",
            "- Hermes SQLite is an operational cache and audit history only.",
            "- Multi-role cards keep arrays of roles/tags; one-card/one-role collapse is not allowed.",
            "",
        ]
    )
    return "\n".join(lines)


def write_artifacts(
    output_dir: Path,
    run_id: str,
    summary: dict[str, Any],
    reviews: list[CandidateReview],
) -> None:
    run_dir = output_dir / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    serializable_reviews = [
        {
            "commander_name": review.commander_name,
            "commander_source": review.commander_source,
            "commander_color_identity": review.commander_color_identity,
            "card_id": review.card_id,
            "oracle_id": review.oracle_id,
            "card_name": review.card_name,
            "set_code": review.set_code,
            "roles": review.roles,
            "decision": review.decision,
            "reasons": review.reasons,
            "risk_flags": review.risk_flags,
            "score": review.score,
            "battle_rule_status": review.battle_rule_status,
            "payload": review.payload,
        }
        for review in reviews
    ]
    summary_path = run_dir / "summary.json"
    report_path = run_dir / "report.md"
    reviews_path = run_dir / "reviews.json"
    summary_path.write_text(
        json.dumps(summary, indent=2, sort_keys=True, default=json_default) + "\n",
        encoding="utf-8",
    )
    reviews_path.write_text(
        json.dumps(serializable_reviews, indent=2, sort_keys=True, default=json_default) + "\n",
        encoding="utf-8",
    )
    report_path.write_text(render_markdown(summary, reviews), encoding="utf-8")
    (output_dir / "latest_summary.json").write_text(summary_path.read_text(encoding="utf-8"), encoding="utf-8")
    (output_dir / "latest_reviews.json").write_text(reviews_path.read_text(encoding="utf-8"), encoding="utf-8")
    (output_dir / "latest_report.md").write_text(report_path.read_text(encoding="utf-8"), encoding="utf-8")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Report-only new card candidate review")
    parser.add_argument("--fixture", help="JSON fixture for deterministic tests")
    parser.add_argument("--sets", default=os.environ.get("MANALOOM_NEW_CARD_REVIEW_SETS", "msh,msc,mar"))
    parser.add_argument("--lookback-days", type=int, default=int(os.environ.get("MANALOOM_NEW_CARD_REVIEW_LOOKBACK_DAYS", "45")))
    parser.add_argument("--commander-limit", type=int, default=int(os.environ.get("MANALOOM_NEW_CARD_REVIEW_COMMANDER_LIMIT", "24")))
    parser.add_argument("--card-limit", type=int, default=int(os.environ.get("MANALOOM_NEW_CARD_REVIEW_CARD_LIMIT", "800")))
    parser.add_argument("--force-commander", action="append", default=[])
    parser.add_argument("--no-lorehold-control", action="store_true")
    parser.add_argument("--output-dir", default=os.environ.get("MANALOOM_NEW_CARD_CANDIDATE_REVIEW_DIR"))
    parser.add_argument("--knowledge-db", default=os.environ.get("MANALOOM_KNOWLEDGE_DB") or os.environ.get("HERMES_KNOWLEDGE_DB"))
    parser.add_argument("--env-file", default=os.environ.get("MTGIA_ENV_FILE", str(REPO_ROOT / "server/.env")))
    parser.add_argument("--hermes-rule-review-threshold", type=int, default=int(os.environ.get("MANALOOM_NEW_CARD_REVIEW_HERMES_RULE_REVIEW_THRESHOLD", "3")))
    return parser.parse_args(argv)


def run(args: argparse.Namespace) -> dict[str, Any]:
    sets = [item.strip().lower() for item in args.sets.split(",") if item.strip()]
    args.sets = sets
    force_commanders = list(args.force_commander or [])
    if not args.no_lorehold_control and CONTROL_COMMANDER not in force_commanders:
        force_commanders.append(CONTROL_COMMANDER)

    if args.fixture:
        commanders, cards = load_fixture(Path(args.fixture))
    else:
        load_env_file(Path(args.env_file))
        source = PgSource()
        try:
            cards = source.fetch_cards(sets, args.lookback_days, args.card_limit)
            commanders = source.discover_targets(args.commander_limit, force_commanders)
        finally:
            source.close()

    reviews = [
        evaluate_card_for_commander(card, commander)
        for commander in commanders
        for card in cards
    ]
    generated_at = utc_now().isoformat(timespec="seconds")
    run_id = "new_card_candidate_review_" + utc_now().strftime("%Y%m%d_%H%M%S")
    summary = summarize_reviews(run_id, generated_at, cards, commanders, reviews, args)

    output_dir = Path(
        args.output_dir
        or os.environ.get("MANALOOM_OPS_ARTIFACT_DIR", "")
        or DEFAULT_OUTPUT_DIR
    )
    if output_dir.name != "new_card_candidate_review":
        output_dir = output_dir / "new_card_candidate_review"
    knowledge_db = Path(args.knowledge_db or DEFAULT_KNOWLEDGE_DB)
    write_artifacts(output_dir, run_id, summary, reviews)
    persist_sqlite(knowledge_db, run_id, True, reviews, len(cards), len(commanders), summary)
    print(
        "MANALOOM_NEW_CARD_CANDIDATE_REVIEW "
        + json.dumps(
            {
                "run_id": run_id,
                "output_dir": str(output_dir),
                "knowledge_db": str(knowledge_db),
                "cards_scanned": len(cards),
                "commanders_scanned": len(commanders),
                "decisions": summary["decisions"],
                "hermes_lab_should_wake": summary["hermes_lab_should_wake"],
                "hermes_wake_reasons": summary["hermes_wake_reasons"],
            },
            sort_keys=True,
        )
    )
    return summary


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        run(args)
    except Exception as exc:
        print(f"MANALOOM_NEW_CARD_CANDIDATE_REVIEW_FAILED {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
